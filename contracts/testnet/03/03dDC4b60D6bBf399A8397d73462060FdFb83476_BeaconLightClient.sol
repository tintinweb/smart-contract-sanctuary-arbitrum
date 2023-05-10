// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BeaconLightClientUpdate.sol";
import "./LightClientVerifier.sol";
import "./BLS12381.sol";

contract BeaconLightClient is LightClientVerifier, BeaconLightClientUpdate, BLS12381,Initializable {
    // Beacon block header that is finalized
    BeaconBlockHeader public finalizedHeader;

    // slot=>BeaconBlockHeader
    mapping(uint64 => BeaconBlockHeader) public headers;

    // Sync committees corresponding to the header
    // sync_committee_perid => sync_committee_root
    mapping(uint64 => bytes32) public syncCommitteeRoots;

    bytes32 public GENESIS_VALIDATORS_ROOT;

    uint64 constant private NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint64 constant private NEXT_SYNC_COMMITTEE_DEPTH = 5;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_INDEX = 105;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_DEPTH = 6;
    uint64 constant private SLOTS_PER_EPOCH = 32;
    uint64 constant private EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
    bytes4 constant private DOMAIN_SYNC_COMMITTEE = 0x07000000;

    event FinalizedHeaderImported(BeaconBlockHeader finalized_header);
    event NextSyncCommitteeImported(uint64 indexed period, bytes32 indexed next_sync_committee_root);

    function initialize(
        uint64 slot,
        uint64 proposerIndex,
        bytes32 parentRoot,
        bytes32 stateRoot,
        bytes32 bodyRoot,
        bytes32 currentSyncCommitteeHash,
        bytes32 nextSyncCommitteeHash,
        bytes32 genesisValidatorsRoot) public initializer {
        finalizedHeader = BeaconBlockHeader(slot, proposerIndex, parentRoot, stateRoot, bodyRoot);
        syncCommitteeRoots[computeSyncCommitteePeriod(slot)] = currentSyncCommitteeHash;
        syncCommitteeRoots[computeSyncCommitteePeriod(slot) + 1] = nextSyncCommitteeHash;
        GENESIS_VALIDATORS_ROOT = genesisValidatorsRoot;
    }

    function getCurrentPeriod() public view returns (uint64) {
        return computeSyncCommitteePeriod(finalizedHeader.slot);
    }

    function getCommitteeRoot(uint64 slot) public view returns (bytes32) {
        return syncCommitteeRoots[computeSyncCommitteePeriod(slot)];
    }

    // follow beacon api: /beacon/light_client/updates/?start_period={period}&count={count}
    function importNextSyncCommittee(
        FinalizedHeaderUpdate calldata headerUpdate,
        SyncCommitteePeriodUpdate calldata scUpdate
    ) external {
        require(isSuperMajority(headerUpdate.syncAggregate.participation), "!supermajor");

        require(headerUpdate.signatureSlot > headerUpdate.attestedHeader.slot &&
            headerUpdate.attestedHeader.slot >= headerUpdate.finalizedHeader.slot,
            "!skip");

        require(verifyFinalizedHeader(
                headerUpdate.finalizedHeader,
                headerUpdate.finalityBranch,
                headerUpdate.attestedHeader.stateRoot),
            "!finalized header"
        );

        uint64 finalizedPeriod = computeSyncCommitteePeriod(headerUpdate.finalizedHeader.slot);
        uint64 signaturePeriod = computeSyncCommitteePeriod(headerUpdate.signatureSlot);
        require(signaturePeriod == finalizedPeriod, "!period");

        bytes32 signatureSyncCommitteeRoot = syncCommitteeRoots[signaturePeriod];
        require(signatureSyncCommitteeRoot != bytes32(0), "!missing");
        require(signatureSyncCommitteeRoot == headerUpdate.syncCommitteeRoot, "!sync_committee");


        bytes32 domain = computeDomain(DOMAIN_SYNC_COMMITTEE, headerUpdate.forkVersion, GENESIS_VALIDATORS_ROOT);
        bytes32 signingRoot = computeSigningRoot(headerUpdate.attestedHeader, domain);

        uint256[28] memory fieldElement = hashToField(signingRoot);
        uint256[31] memory verifyInputs;
        for (uint256 i = 0; i < fieldElement.length; i++) {
            verifyInputs[i] = fieldElement[i];
        }
        verifyInputs[28] = headerUpdate.syncAggregate.proof.input[0];
        verifyInputs[29] = headerUpdate.syncAggregate.proof.input[1];
        verifyInputs[30] = headerUpdate.syncAggregate.proof.input[2];

        require(verifyProof(
                headerUpdate.syncAggregate.proof.a,
                headerUpdate.syncAggregate.proof.b,
                headerUpdate.syncAggregate.proof.c,
                verifyInputs), "invalid proof");

        bytes32 syncCommitteeRoot = bytes32((headerUpdate.syncAggregate.proof.input[1] << 128) | headerUpdate.syncAggregate.proof.input[0]);
        uint64 slot = uint64(headerUpdate.syncAggregate.proof.input[2]);
        require(syncCommitteeRoot == signatureSyncCommitteeRoot, "invalid syncCommitteeRoot");
//        require(slot == headerUpdate.signatureSlot, "invalid slot");

        if (headerUpdate.finalizedHeader.slot > finalizedHeader.slot) {
            finalizedHeader = headerUpdate.finalizedHeader;
            headers[finalizedHeader.slot] = finalizedHeader;
            emit FinalizedHeaderImported(headerUpdate.finalizedHeader);
        }

        require(verifyNextSyncCommittee(
                scUpdate.nextSyncCommitteeRoot,
                scUpdate.nextSyncCommitteeBranch,
                headerUpdate.attestedHeader.stateRoot),
            "!next_sync_committee"
        );

        uint64 nextPeriod = signaturePeriod + 1;
        require(syncCommitteeRoots[nextPeriod] == bytes32(0), "imported");
        bytes32 nextSyncCommitteeRoot = scUpdate.nextSyncCommitteeRoot;
        syncCommitteeRoots[nextPeriod] = nextSyncCommitteeRoot;
        emit NextSyncCommitteeImported(nextPeriod, nextSyncCommitteeRoot);
    }

    function verifyFinalizedHeader(
        BeaconBlockHeader calldata header,
        bytes32[] calldata finalityBranch,
        bytes32 attestedHeaderRoot
    ) internal pure returns (bool) {
        require(finalityBranch.length == FINALIZED_CHECKPOINT_ROOT_DEPTH, "!finality_branch");
        bytes32 headerRoot = hashTreeRoot(header);
        return isValidMerkleBranch(
            headerRoot,
            finalityBranch,
            FINALIZED_CHECKPOINT_ROOT_DEPTH,
            FINALIZED_CHECKPOINT_ROOT_INDEX,
            attestedHeaderRoot
        );
    }

    function verifyNextSyncCommittee(
        bytes32 nextSyncCommitteeRoot,
        bytes32[] calldata nextSyncCommitteeBranch,
        bytes32 headerStateRoot
    ) internal pure returns (bool) {
        require(nextSyncCommitteeBranch.length == NEXT_SYNC_COMMITTEE_DEPTH, "!next_sync_committee_branch");
        return isValidMerkleBranch(
            nextSyncCommitteeRoot,
            nextSyncCommitteeBranch,
            NEXT_SYNC_COMMITTEE_DEPTH,
            NEXT_SYNC_COMMITTEE_INDEX,
            headerStateRoot
        );
    }

    function isSuperMajority(uint256 participation) internal pure returns (bool) {
        return participation * 3 >= SYNC_COMMITTEE_SIZE * 2;
    }

    function computeSyncCommitteePeriod(uint64 slot) internal pure returns (uint64) {
        return slot / SLOTS_PER_EPOCH / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./BeaconChain.sol";

contract BeaconLightClientUpdate is BeaconChain {

    struct SyncAggregate {
        uint64 participation;
        Groth16Proof proof;
    }

    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[3] input;
    }

    struct FinalizedHeaderUpdate {
        // The beacon block header that is attested to by the sync committee
        BeaconBlockHeader attestedHeader;

        // Sync committee corresponding to sign attested header
        bytes32 syncCommitteeRoot;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalizedHeader;
        bytes32[] finalityBranch;

        // Fork version for the aggregate signature
        bytes4 forkVersion;

        // Slot at which the aggregate signature was created (untrusted)
        uint64 signatureSlot;

        // Sync committee aggregate signature
        SyncAggregate syncAggregate;
    }

    struct SyncCommitteePeriodUpdate {
        // Next sync committee corresponding to the finalized header
        bytes32 nextSyncCommitteeRoot;
        bytes32[] nextSyncCommitteeBranch;
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract LightClientVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[32] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(1130662485405941043498817162299874418550022442965249285023228559820695891187), uint256(1063164716183610997770619568893534465400791517654187366890717081480611899145));
        vk.beta2 = Pairing.G2Point([uint256(11650762016426022654800308167748256447622892934793200922269390355367587600404), uint256(21328850445110584716894542726790518660153566549520693431087421362988778436912)], [uint256(14792142873431128711464519300495356462226359694718621225205439848965401289171), uint256(13376056434127050269780747280172262367742158868103731884790527567802255915837)]);
        vk.gamma2 = Pairing.G2Point([uint256(5315735453386471184299098124666043270538141105082675315468988444453999564368), uint256(13512755412422015369215612173103806233739636701228728690666401319062970812648)], [uint256(14957881173640582209767281589673250727729101805743378838674975273434823719223), uint256(12308940291662577423905028140163036995133581776941948106429468782270048366288)]);
        vk.delta2 = Pairing.G2Point([uint256(8627204693407460014596157070841093869166477259214815539590048839155019500112), uint256(13424176520426465893015223604687129533710666994214249300257479496931560640243)], [uint256(2867577408763054644768182332455495693155150317869055943934033064158278103202), uint256(2404222053654733840225689784730104119985650297168653926827479740838853942168)]);
        vk.IC[0] = Pairing.G1Point(uint256(14475854867287042520234026445747319090671448457416890921154975709820937491609), uint256(11744221140032454035576325390900950089659362213885507511994095606151858417903));
        vk.IC[1] = Pairing.G1Point(uint256(13855237524652065953821604547869506567232663629673266155564920171652143437863), uint256(18152215215647537306922009926951405667913925236025268987084918895643884664842));
        vk.IC[2] = Pairing.G1Point(uint256(9364736318729622218136909249549623745346146107132241094351124458836379626228), uint256(4197647346506878124723119746391518821614881195462376741224123477128337512507));
        vk.IC[3] = Pairing.G1Point(uint256(1084406638307691240239241434983523156138458692563039779407672231608483230694), uint256(11828420303274944327708753153317462319847509454613703457098967538685333773284));
        vk.IC[4] = Pairing.G1Point(uint256(4075091574819191500046140892293353455993291968087041630447964559527487367530), uint256(19644027862529451483302255351389661385483743601576604670652242030294065076338));
        vk.IC[5] = Pairing.G1Point(uint256(6010325225903558331067436033812562159216000644439316318634681775608203018249), uint256(3062011671518518208045924275701227748603158187376200417823496723046583098619));
        vk.IC[6] = Pairing.G1Point(uint256(691764375884737978723429913846392014086690516674901958412888980404471433979), uint256(10363458425284719688011383624863200066442527777467809803117119390944532370082));
        vk.IC[7] = Pairing.G1Point(uint256(16772256466510429671335348048996506233368186619681722363742876650131441399439), uint256(3940687675139088818846424784821386401041007812713310495028827562832094612133));
        vk.IC[8] = Pairing.G1Point(uint256(14490063187774747289862871967583823877989146790709316411591353643101786845663), uint256(19713995281670400465572068439014841018751989799246657619836045191439967583712));
        vk.IC[9] = Pairing.G1Point(uint256(13949614895806786613689365659205598847777547900149539048636531296846327404647), uint256(6426592206708134867417665785006404370484695918677754358584446053767784430287));
        vk.IC[10] = Pairing.G1Point(uint256(10945887803381815156233333636717016805658278514916263198822964865021405200316), uint256(3322369320257469061525455781391208590052905655891673326445321641712001570733));
        vk.IC[11] = Pairing.G1Point(uint256(10358643026169888910813606611622068239811706294429010810846390353721581408036), uint256(9986919238363553050350349214208941644892880369801839648695776348100165566632));
        vk.IC[12] = Pairing.G1Point(uint256(3135559963650380971168629439962434662700127503234650275209200185928171342230), uint256(18940320137847724785590663762515830475404471543897505210351658809836312428251));
        vk.IC[13] = Pairing.G1Point(uint256(15498253910620925324863096539356282472967431835918836981588827746993534417924), uint256(13985635466043756984259572873560957661104616664436107316131295159780357264950));
        vk.IC[14] = Pairing.G1Point(uint256(14551342607101319724013038236633327632503014333697614701395848632075511172774), uint256(9503829110631770699364287040704322526633077895071265639981568557975454008710));
        vk.IC[15] = Pairing.G1Point(uint256(18571982854431347910414146109845279799219595890448554777785855303926342500021), uint256(488819844743313386898554258679596785435483306818900986751022585890384175412));
        vk.IC[16] = Pairing.G1Point(uint256(6110156114151677616568373664371352764858746249752384265755188164509961433362), uint256(14431302441833784435515687790837921212926528737677580657910004897823308935374));
        vk.IC[17] = Pairing.G1Point(uint256(985748017715146423122914249072998950581543380934351459350915025215900171871), uint256(1631168349822506015011044780529931409453435506814546705323770289550462518046));
        vk.IC[18] = Pairing.G1Point(uint256(262243211950762322473518543087251537334479731961203757262948376023456724874), uint256(9761869498559283483828333667183825866688862297341138400468710507597405822848));
        vk.IC[19] = Pairing.G1Point(uint256(10364138647106213752770316862382107002992305090700867371382456228010461502089), uint256(6000405531784984725804648414802692403340133604540589616614382773957285728715));
        vk.IC[20] = Pairing.G1Point(uint256(9121559780990487900956482387496277253809373221466305255620096006195912879312), uint256(8454978462398573968004214277633922476151277163187336685016519772362797441887));
        vk.IC[21] = Pairing.G1Point(uint256(2326930698938671342213220685058432264881280803484929696850030854893380209444), uint256(2168696866643140629301410275419050634262270831344804420570424038907631118710));
        vk.IC[22] = Pairing.G1Point(uint256(14270011576894950143165708690816892910793007294426565327067371314936006497430), uint256(19705975772604904267624847724881874657183787964036701430127405471516922602307));
        vk.IC[23] = Pairing.G1Point(uint256(5486280221043422652323408484337801502144388342833338236298977618427546657575), uint256(17551578610959473109748058276281106905062188486140944541569423830223572804167));
        vk.IC[24] = Pairing.G1Point(uint256(9243487838057998300141806597329245206673569963376057257575583520699114115260), uint256(8026467957827895349367442144121723833548701462458159655351279563920225779783));
        vk.IC[25] = Pairing.G1Point(uint256(14045375458826533794046365450108937644487651326710919617694453532642594321860), uint256(19954989574856288171093226813445872472864231102245773380738718246353050038856));
        vk.IC[26] = Pairing.G1Point(uint256(10236105313585401677786221837695872195364371525208115190344783948180308359648), uint256(4115000184702886933558399362905135375101754589946872511094579461125352109350));
        vk.IC[27] = Pairing.G1Point(uint256(11669001122418208984860794794166784553381694633292459429460067091407232328762), uint256(16676861628373019175151882891836902504926285399704596084945634533318255751965));
        vk.IC[28] = Pairing.G1Point(uint256(6111561049773864903583957091696196118439926274057763492928920678707950100068), uint256(18100162971895056038090624301190592028961560627374956205036372296508217479781));
        vk.IC[29] = Pairing.G1Point(uint256(2922484978614035058647919841225612561447186724441229007912840584295262804016), uint256(6686795201880458944945020198695732999014255177050870766690573706869130735005));
        vk.IC[30] = Pairing.G1Point(uint256(7824302847526777364179427874295692251029223860369844312370075032337229569591), uint256(5041297875455106282050505866262621425764521202785860904780142183199110327712));
        vk.IC[31] = Pairing.G1Point(uint256(16828037706565425848235194268024502720024463500776819837822822487857909297813), uint256(10226975960701984315785801886770602458335336524627936551098870958817038399662));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[31] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BLS12381 {
    struct Fp {
        uint256 a;
        uint256 b;
    }

    uint8 constant MOD_EXP_PRECOMPILE_ADDRESS = 0x5;


    // Reduce the number encoded as the big-endian slice of data[start:end] modulo the BLS12-381 field modulus.
    // Copying of the base is cribbed from the following:
    // https://github.com/ethereum/solidity-examples/blob/f44fe3b3b4cca94afe9c2a2d5b7840ff0fafb72e/src/unsafe/Memory.sol#L57-L74
    function reduceModulo(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (bytes memory) {
        uint256 length = end - start;
        assert(length <= data.length);

        bytes memory result = new bytes(48);

        bool success;
        assembly {
            let p := mload(0x40)
        // length of base
            mstore(p, length)
        // length of exponent
            mstore(add(p, 0x20), 0x20)
        // length of modulus
            mstore(add(p, 0x40), 48)
        // base
        // first, copy slice by chunks of EVM words
            let ctr := length
            let src := add(add(data, 0x20), start)
            let dst := add(p, 0x60)
            for {

            } or(gt(ctr, 0x20), eq(ctr, 0x20)) {
                ctr := sub(ctr, 0x20)
            } {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
        // next, copy remaining bytes in last partial word
            let mask := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dst), mask)
            mstore(dst, or(destpart, srcpart))
        // exponent
            mstore(add(p, add(0x60, length)), 1)
        // modulus
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            mstore(
            modulusAddr,
            or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7)
            ) // pt 1
            mstore(
            add(p, add(0x90, length)),
            0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            ) // pt 2
            success := staticcall(
            sub(gas(), 2000),
            MOD_EXP_PRECOMPILE_ADDRESS,
            p,
            add(0xB0, length),
            add(result, 0x20),
            48
            )
        // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'call to modular exponentiation precompile failed');
        return result;
    }

    function sliceToUint(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private pure returns (uint256 result) {
        uint256 length = end - start;
        require(length <= 32, "Invalid slice length");

        assembly {
            let dataPtr := add(add(data, 0x20), start)
            let dataEnd := add(dataPtr, length)

            for {
                let i := dataPtr
            } lt(i, dataEnd) {
                i := add(i, 1)
            } {
                result := shl(8, result)
                result := or(result, byte(0, mload(i)))
            }
        }
    }


    function convertSliceToFp(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (Fp memory) {
        bytes memory fieldElement = reduceModulo(data, start, end);
        uint256 a = sliceToUint(fieldElement, 0, 16);
        uint256 b = sliceToUint(fieldElement, 16, 48);
        return Fp(a, b);
    }

    function expandMessage(bytes32 message) private pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        bytes memory BLS_SIG_DST = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+';
        //0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f504f505f2b

        //   for (uint256 i; i < 32; ) {
        //       b0Input[i + 64] = message[i];
        //   unchecked {
        //       ++i;
        //   }
        //   }
        //   b0Input[96] = 0x01;
        //   for (uint256 i; i < 44; ) {
        //       b0Input[i + 99] = bytes(BLS_SIG_DST)[i];
        //   unchecked {
        //       ++i;
        //   }
        //   }
        assembly {
            mstore(add(b0Input, 0x60), message)
            mstore8(add(b0Input, 0x80), 0x01)
        // Load BLS_SIG_DST
            mstore(add(b0Input, 0x83), 0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f53)
            mstore8(add(b0Input, 0xa3), 0x53)
            mstore8(add(b0Input, 0xa4), 0x57)
            mstore8(add(b0Input, 0xa5), 0x55)
            mstore8(add(b0Input, 0xa6), 0x5f)
            mstore8(add(b0Input, 0xa7), 0x52)
            mstore8(add(b0Input, 0xa8), 0x4f)
            mstore8(add(b0Input, 0xa9), 0x5f)
            mstore8(add(b0Input, 0xaa), 0x50)
            mstore8(add(b0Input, 0xab), 0x4f)
            mstore8(add(b0Input, 0xac), 0x50)
            mstore8(add(b0Input, 0xad), 0x5f)
            mstore8(add(b0Input, 0xae), 0x2b)
        }


        bytes32 b0 = sha256(b0Input);

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(
            abi.encodePacked(b0, bytes1(0x01), bytes(BLS_SIG_DST))
        );
        assembly {
            mstore(add(output, 0x20), chunk)
        }

        for (uint256 i = 2; i < 9;) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(
                abi.encodePacked(input, bytes1(uint8(i)), bytes(BLS_SIG_DST))
            );
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        unchecked {
            ++i;
        }
        }

        return output;
    }

    function FpToArray55_7(Fp memory fp) private pure returns (uint256[7] memory) {
        uint256[7] memory result;
        uint256 mask = ((1 << 55) - 1);
        result[0] = (fp.b & mask);
        result[1] = ((fp.b >> 55) & mask);
        result[2] = ((fp.b >> 110) & mask);
        result[3] = ((fp.b >> 165) & mask);
        result[4] = ((fp.b >> 220) & mask);
        uint256 newMask = (1 << 19) - 1;
        result[4] = result[4] | ((fp.a & newMask) << 36);
        result[5] = (fp.a & (mask << 19)) >> 19;
        result[6] = (fp.a & (mask << (55 + 19))) >> (55 + 19);

        return result;
    }

    function hashToField(bytes32 message)
    internal
    view
    returns (uint256[28] memory input)
    {
        bytes memory some_bytes = expandMessage(message);
        uint256[7][2][2] memory result;
        result[0][0] = FpToArray55_7(convertSliceToFp(some_bytes, 0, 64));
        result[0][1] = FpToArray55_7(convertSliceToFp(some_bytes, 64, 128));
        result[1][0] = FpToArray55_7(convertSliceToFp(some_bytes, 128, 192));
        result[1][1] = FpToArray55_7(convertSliceToFp(some_bytes, 192, 256));
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2; j++) {
                for (uint256 k = 0; k < 7; k++) {
                    input[i * 14 + j * 7 + k] = result[i][j][k];
                }
            }
        }
        return input;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./MerkleProof.sol";
import "./ScaleCodec.sol";

contract BeaconChain is MerkleProof {
    uint64 constant internal SYNC_COMMITTEE_SIZE = 512;

    struct ForkData {
        bytes4 currentVersion;
        bytes32 genesisValidatorsRoot;
    }

    struct SigningData {
        bytes32 objectRoot;
        bytes32 domain;
    }

    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposerIndex;
        bytes32 parentRoot;
        bytes32 stateRoot;
        bytes32 bodyRoot;
    }

    // Return the signing root for the corresponding signing data.
    function computeSigningRoot(BeaconBlockHeader memory beaconHeader, bytes32 domain) internal pure returns (bytes32){
        return hashTreeRoot(SigningData({
                objectRoot: hashTreeRoot(beaconHeader),
                domain: domain
            })
        );
    }

    // Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
    // This is used primarily in signature domains to avoid collisions across forks/chains.
    function computeForkDataRoot(bytes4 currentVersion, bytes32 genesisValidatorsRoot) internal pure returns (bytes32){
        return hashTreeRoot(ForkData({
                currentVersion: currentVersion,
                genesisValidatorsRoot: genesisValidatorsRoot
            })
        );
    }

    //  Return the domain for the ``domain_type`` and ``fork_version``.
    function computeDomain(bytes4 domainType, bytes4 forkVersion, bytes32 genesisValidatorsRoot) internal pure returns (bytes32){
        bytes32 forkDataRoot = computeForkDataRoot(forkVersion, genesisValidatorsRoot);
        return bytes32(domainType) | forkDataRoot >> 32;
    }

    function hashTreeRoot(ForkData memory fork_data) internal pure returns (bytes32) {
        return hashNode(bytes32(fork_data.currentVersion), fork_data.genesisValidatorsRoot);
    }

    function hashTreeRoot(SigningData memory signingData) internal pure returns (bytes32) {
        return hashNode(signingData.objectRoot, signingData.domain);
    }

    function hashTreeRoot(BeaconBlockHeader memory beaconHeader) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = bytes32(toLittleEndian64(beaconHeader.slot));
        leaves[1] = bytes32(toLittleEndian64(beaconHeader.proposerIndex));
        leaves[2] = beaconHeader.parentRoot;
        leaves[3] = beaconHeader.stateRoot;
        leaves[4] = beaconHeader.bodyRoot;
        return merkleRoot(leaves);
    }

    function toLittleEndian64(uint64 value) internal pure returns (bytes8) {
        return ScaleCodec.encode64(value);
    }

    function toLittleEndian256(uint256 value) internal pure returns (bytes32) {
        return ScaleCodec.encode256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";

contract MerkleProof is Math {
    // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    function isValidMerkleBranch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint64 depth,
        uint64 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ++i) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = hashNode(branch[i], value);
            } else {
                value = hashNode(value, branch[i]);
            }
        }
        return value == root;
    }

    function isValidMerkleBranch(
        bytes32[] memory branch,
        bytes32 leaf,
        bytes32 root,
        uint64 index,
        uint64 depth
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ++i) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = hashNode(branch[i], value);
            } else {
                value = hashNode(value, branch[i]);
            }
        }
        return value == root;
    }


    function merkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return hash(abi.encodePacked(leaves[0]));
        else if (len == 2) return hashNode(leaves[0], leaves[1]);
        uint bottomLength = getPowerOfTwoCeil(len);
        bytes32[] memory o = new bytes32[](bottomLength * 2);
        for (uint i = 0; i < len; ++i) {
            o[bottomLength + i] = leaves[i];
        }
        for (uint i = bottomLength - 1; i > 0; --i) {
            o[i] = hashNode(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
    }


    function hashNode(bytes32 left, bytes32 right)
    internal
    pure
    returns (bytes32)
    {
        return hash(abi.encodePacked(left, right));
    }

    function hash(bytes memory value) internal pure returns (bytes32) {
        return sha256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = data.length; i > 0; i--) {
            number = number + uint256(uint8(data[i - 1])) * (2**(8 * (i - 1)));
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data)
        internal
        pure
        returns (uint256 v)
    {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        if (mode == 0) {
            // [0, 63]
            return b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            return r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            return uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            // solhint-disable-next-line
            uint8 l = b >> 2; // remove mode bits
            require(
                l > 32,
                "Not supported: number cannot be greater than 32 bytes"
            );
        } else {
            revert("Code should be unreachable");
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index)
        internal
        pure
        returns (uint8)
    {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) |
            ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) internal pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) internal pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) internal pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) internal pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) internal pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encode8(uint8 input) internal pure returns (bytes1) {
        return bytes1(input);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Math {
    /// Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    /// Commonly used for "how many nodes do I need for a bottom tree layer fitting x elements?"
    /// Example: 0->1, 1->1, 2->2, 3->4, 4->4, 5->8, 6->8, 7->8, 8->8, 9->16.
    function getPowerOfTwoCeil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * getPowerOfTwoCeil((x + 1) >> 1);
    }

    function log_2(uint256 x) internal pure returns (uint256 pow) {
        require(0 < x && x < 0x8000000000000000000000000000000000000000000000000000000000000001, "invalid");
        uint256 a = 1;
        while (a < x) {
            a <<= 1;
            pow++;
        }
    }

    function _max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}