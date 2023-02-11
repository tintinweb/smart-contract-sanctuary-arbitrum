// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;
import "./shared/Structs.sol";

struct AppStorage {
    // Re-entrancy guard for functions that make external calls
    uint8 _status;
    uint256 latestRequestId;
    // Protocol addresses
    address sequencer;
    address proposedSequencer;
    address treasury;
    address[] beacons;
    // Reserve uint space for additional future config kv stores
    uint256[48] configUints;
    uint256[16] gasEstimates;
    // Client Deposits & Reserved Amounts
    mapping(address client => uint256 value) ethDeposit;
    mapping(address client => uint256 reserved) ethReserved;
    // Beacon Stores
    mapping(address beacon => uint256 index) beaconIndex;
    mapping(address beacon => Beacon data) beacon;
    // Request Stores
    mapping(uint256 id => bytes32 result) results;
    mapping(uint256 id => bytes32 dataHash) requestToHash; // The hash of the request data
    mapping(uint256 id => bytes10[2] vrfHashes) requestToVrfHashes; // The submitted hashes from beacons
    mapping(uint256 id => uint256 feePaid) requestToFeePaid;
    mapping(uint256 id => uint256 feeRefunded) requestToFeeRefunded;
    // Collateral
    mapping(address beacon => uint256 value) ethCollateral;
}

// SPDX-License-Identifier: BSL 1.1
/// @title Randomizer Beacon Service
/// @author Dean van Dugteren (https://github.com/deanpress)
/// @notice Beacon management functions (registration, staking, submitting random values etc)

pragma solidity ^0.8.18;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../libraries/LibVRF.sol";
import "../libraries/LibBeacon.sol";
import "../shared/Structs.sol";
import "../shared/Utils.sol";
import "../libraries/Constants.sol";
import "../AppStorage.sol";

contract BeaconFacet is Utils {
    /* Errors */

    error BeaconAlreadyRegistered();
    error BeaconNotSelected();
    error BeaconHasPending(uint256 pending);
    error NotABeacon();
    error VRFProofInvalid();
    error BeaconValueExists();
    error NotOwnerOrBeacon();
    error BeaconStakedEthTooLow(uint256 staked, uint256 minimum);
    error SequencerSubmissionTooEarly(
        uint256 currentBlock,
        uint256 minBlock,
        uint256 currentTime,
        uint256 minTime
    );
    error SenderNotBeaconOrSequencer();
    error BlockhashUnavailable(uint256 blockNumber);
    error MinHeightNotYetReached(uint256 blockNumber, uint256 minBlockNumber);

    /* Events */

    /// @notice Emits an event when a beacon submits a VRF value for a request
    /// @param id request id
    /// @param beacon address of the beacon that submitted the random value
    /// @param value the submitted random value
    event SubmitRandom(uint256 indexed id, address indexed beacon, bytes10 value);

    /// @notice Emits an event when a beacon is registered
    /// @param beacon address of the registered beacon
    event RegisterBeacon(address indexed beacon);

    /* Functions */

    /// @notice Returns a list of active beacon addresses
    function beacons() external view returns (address[] memory) {
        return s.beacons;
    }

    /// @notice Returns beacon details (VRF keys, registered, strikes, consecutive successful submissions, pending requests, stake, index in beacons list)
    function beacon(address _beacon)
        external
        view
        returns (
            uint256[2] memory publicKey,
            bool registered,
            uint8 strikes,
            uint8 consecutiveSubmissions,
            uint64 pending,
            uint256 ethStake,
            uint256 index
        )
    {
        return (
            s.beacon[_beacon].publicKey,
            s.beacon[_beacon].registered,
            s.beacon[_beacon].strikes,
            s.beacon[_beacon].consecutiveSubmissions,
            s.beacon[_beacon].pending,
            s.ethCollateral[_beacon],
            s.beaconIndex[_beacon]
        );
    }

    /// @notice Returns request data (result, data hash, fees paid and refunded, submitted vrf hashes)
    function getRequest(uint256 _request)
        external
        view
        returns (
            bytes32 result,
            bytes32 dataHash,
            uint256 ethPaid,
            uint256 ethRefunded,
            bytes10[2] memory vrfHashes
        )
    {
        return (
            s.results[_request],
            s.requestToHash[_request],
            s.requestToFeePaid[_request],
            s.requestToFeeRefunded[_request],
            s.requestToVrfHashes[_request]
        );
    }

    /// @notice Registers a new beacon
    /// @dev Beacons are responsible for generating VRF proofs and participating in request finalization
    /// @param _beacon address of the beacon to register
    /// @param _vrfPublicKeyData VRF public key x and y components
    function registerBeacon(address _beacon, uint256[2] calldata _vrfPublicKeyData) external {
        // Check if the caller is the contract owner
        LibDiamond.enforceIsContractOwner();

        // Get the minimum required amount of ETH collateral for a beacon
        uint256 minStakeEth = s.configUints[Constants.CKEY_MIN_STAKE_ETH];

        // Check if the beacon is already registered
        if (s.beacon[_beacon].registered) revert BeaconAlreadyRegistered();

        // Check if the beacon has staked enough ETH
        if (s.ethCollateral[_beacon] < minStakeEth)
            revert BeaconStakedEthTooLow(s.ethCollateral[_beacon], minStakeEth);

        // Don't reset beacon pending so that it can pick up where it left off in case it still has pending requests.
        uint64 pending = s.beacon[_beacon].pending;

        // Add the beacon to the contract
        s.beacon[_beacon] = Beacon(_vrfPublicKeyData, true, 0, 0, pending);
        s.beaconIndex[_beacon] = s.beacons.length;
        s.beacons.push(_beacon);

        // Emit an event to log the registration of the beacon
        emit RegisterBeacon(_beacon);
    }

    /// @notice Stake ETH for a beacon
    function beaconStakeEth(address _beacon) external payable {
        // Increase the beacon's ETH collateral by the value of the transaction
        s.ethCollateral[_beacon] += msg.value;

        // Emit an event to log the deposit of ETH by the beacon
        emit Events.BeaconDepositEth(_beacon, msg.value);
    }

    /// @notice Unstake ETH from sender's beacon
    function beaconUnstakeEth(uint256 _amount) external {
        // Decrease the beacon's ETH collateral by the specified amount
        s.ethCollateral[msg.sender] -= _amount;

        // Check if the beacon's collateral is below the minimum required amount
        if (
            s.ethCollateral[msg.sender] < s.configUints[Constants.CKEY_MIN_STAKE_ETH] &&
            s.beaconIndex[msg.sender] != 0
        ) {
            // Check if the beacon has any pending transactions
            if (s.beacon[msg.sender].pending != 0) revert BeaconHasPending(s.beacon[msg.sender].pending);

            // Remove the beacon from the contract
            _removeBeacon(msg.sender);
            emit Events.UnregisterBeacon(msg.sender, false, s.beacon[msg.sender].strikes);
        }

        // Transfer the specified amount of ETH to the beacon
        _transferEth(msg.sender, _amount);
    }

    /// @notice Unregisters the beacon (callable by beacon or owner). Returns staked ETH to beacon.
    function unregisterBeacon(address _beacon) external {
        // Check if the caller is the beacon or the contract owner
        if (msg.sender != _beacon && msg.sender != LibDiamond.contractOwner()) revert NotOwnerOrBeacon();

        // Check if the beacon is registered
        Beacon memory beacon_ = s.beacon[_beacon];
        if (!beacon_.registered) revert NotABeacon();

        // Check if the beacon has any pending transactions
        if (beacon_.pending != 0) revert BeaconHasPending(beacon_.pending);

        // Get the beacon's collateral
        uint256 collateral = s.ethCollateral[_beacon];

        // Remove the beacon from the contract
        _removeBeacon(_beacon);
        emit Events.UnregisterBeacon(_beacon, false, beacon_.strikes);

        // If the beacon had any collateral, refund it
        if (collateral > 0) {
            // Remove the beacon's collateral
            s.ethCollateral[_beacon] = 0;

            // Refund ETH to the beacon
            _transferEth(_beacon, collateral);
        }
    }

    /// @notice Submit VRF data as a beacon
    /// @param beaconPos The position of the beacon submitting the request
    /// @param _addressData An array of addresses containing the request beacons and the client
    /// @param _uintData An array of uint256 values containing request data
    /// @param seed The seed used to generate the VRF output
    function submitRandom(
        uint256 beaconPos,
        address[4] calldata _addressData,
        uint256[19] calldata _uintData,
        bytes32 seed
    ) external {
        uint256 gasAtStart = gasleft();

        (SAccounts memory accounts, SPackedSubmitData memory packed) = LibBeacon._getAccountsAndPackedData(
            _addressData,
            _uintData
        );

        _submissionStep(msg.sender, beaconPos, seed, gasAtStart, packed, accounts);
    }

    /// @notice Submit VRF data for a request on behalf of a beacon using signatures
    /// @param beaconPos The position in the request of the beacon
    /// @param _addressData An array of addresses containing the request beacons and the client
    /// @param _uintData An array of uint256 values containing request data
    /// @param _rsAndSeed An array of bytes32 values containing the request's seed and signature data
    /// @param _v The recovery byte for the signature
    function submitRandom(
        uint256 beaconPos,
        address[4] calldata _addressData,
        uint256[19] calldata _uintData,
        bytes32[3] calldata _rsAndSeed,
        uint8 _v
    ) external {
        // Save the gas remaining at the start of the function execution
        uint256 gasAtStart = gasleft();

        // Retrieve the accounts and packed data for the given address and uint data
        (SAccounts memory accounts, SPackedSubmitData memory packed) = LibBeacon._getAccountsAndPackedData(
            _addressData,
            _uintData
        );

        // Verify the beacon's signature using the ECDSA recovery algorithm
        address _beacon = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(
                            address(this),
                            accounts.client,
                            _rsAndSeed[2],
                            packed.id,
                            packed.vrf.proof,
                            packed.vrf.uPoint,
                            packed.vrf.vComponents,
                            block.chainid
                        )
                    )
                )
            ),
            _v,
            _rsAndSeed[0],
            _rsAndSeed[1]
        );

        // Process the submission for the given beacon
        _submissionStep(_beacon, beaconPos, _rsAndSeed[2], gasAtStart, packed, accounts);
    }

    function _submissionStep(
        address _beacon,
        uint256 beaconPos,
        bytes32 seed,
        uint256 gasAtStart,
        SPackedSubmitData memory packed,
        SAccounts memory accounts
    ) private {
        _validateRequestData(packed.id, seed, accounts, packed.data);
        bytes10[2] memory reqValues = s.requestToVrfHashes[packed.id];

        // Check if beacon or sequencer can submit the result
        _checkCanSubmit(_beacon, accounts.beacons, beaconPos, reqValues, packed.data);

        // Verify with the seed
        if (
            !LibVRF.fastVerify(
                s.beacon[_beacon].publicKey,
                packed.vrf.proof,
                abi.encodePacked(seed),
                packed.vrf.uPoint,
                packed.vrf.vComponents
            )
        ) revert VRFProofInvalid();

        bytes10 vrfHash = bytes10(keccak256(abi.encodePacked(packed.vrf.proof[0], packed.vrf.proof[1])));

        // Every 100 consecutive submissions, strikes are reset to 0
        _updateBeaconSubmissionCount(_beacon);
        emit SubmitRandom(packed.id, _beacon, vrfHash);

        if (beaconPos < 2) {
            s.requestToVrfHashes[packed.id][beaconPos] = vrfHash;
            reqValues[beaconPos] = vrfHash;
            _processRandomSubmission(accounts, packed, gasAtStart, reqValues);
        } else {
            _processFinalSubmission(reqValues, vrfHash, accounts, packed, gasAtStart);
        }
    }

    function _processFinalSubmission(
        bytes10[2] memory reqValues,
        bytes10 vrfHash,
        SAccounts memory accounts,
        SPackedSubmitData memory packed,
        uint256 gasAtStart
    ) private {
        // Protect against reentrancy attacks
        if (s._status == Constants.STATUS_ENTERED) revert ReentrancyGuard();
        s._status = Constants.STATUS_ENTERED;

        // Process the final beacon submission
        _processResult(
            packed.id,
            accounts.client,
            [reqValues[0], reqValues[1], vrfHash],
            packed.data.callbackGasLimit,
            packed.data.ethReserved
        );

        // Calculate and charge the beacon fee
        uint256 submitFee = LibBeacon._getFeeCharge(
            gasAtStart,
            packed.data.beaconFee,
            s.gasEstimates[Constants.GKEY_OFFSET_FINAL_SUBMIT]
        );

        _finalSoftChargeClient(packed.id, accounts.client, submitFee, packed.data.beaconFee);

        // Clean up the mapping for the request
        delete s.requestToHash[packed.id];
        delete s.requestToVrfHashes[packed.id];

        // Reset the reentrancy guard status
        s._status = Constants.STATUS_NOT_ENTERED;
    }

    function _updateBeaconSubmissionCount(address _beacon) private {
        // Retrieve the Beacon struct for the given beacon address
        Beacon memory memBeacon = s.beacon[_beacon];

        // If the consecutive submissions count is greater than or equal to the maximum allowed, reset it to 0
        // and set the number of strikes to 0
        if (memBeacon.consecutiveSubmissions >= Constants.CKEY_MAX_CONSECUTIVE_SUBMISSIONS) {
            memBeacon.consecutiveSubmissions = 0;
            memBeacon.strikes = 0;
        } else {
            // If the consecutive submissions count is less than the maximum allowed, increment it
            unchecked {
                memBeacon.consecutiveSubmissions++;
            }
        }

        // Decrement the pending count for the beacon
        if (memBeacon.pending > 0) memBeacon.pending--;

        // Save the updated Beacon struct
        s.beacon[_beacon] = memBeacon;
    }

    /// @notice Processes a random submission by checking the request's first two VRF hashes
    /// and generating a new seed value using these hashes and the request's blockhash.
    /// It also charges the client a fee based on the gas used and the beacon fee.
    function _processRandomSubmission(
        SAccounts memory accounts, // A struct containing beacons and client addresses
        SPackedSubmitData memory packed, // Data about the request/submission
        uint256 gasAtStart, // The amount of gas at the start of the function call
        bytes10[2] memory reqValues // The first two VRF values submitted for this request
    ) private {
        // Check if the second to last request is valid and non-zero
        if (reqValues[0] != bytes10(0) && reqValues[1] != bytes10(0)) {
            bytes10 memBlockhash = bytes10(LibNetwork._blockHash(packed.data.height));
            if (memBlockhash == bytes10(0)) revert BlockhashUnavailable(packed.data.height);
            // Generate a new seed value using the values of the last two requests + the request's blockhash
            bytes32 newSeed = keccak256(abi.encodePacked(reqValues[0], reqValues[1], memBlockhash));
            // Request the final beacon with the generated seed value
            _requestBeacon(packed.id, 2, newSeed, accounts, packed.data);
        }

        // Calculate the fee to charge the client
        uint256 fee = LibBeacon._getFeeCharge(
            gasAtStart,
            packed.data.beaconFee,
            s.gasEstimates[Constants.GKEY_OFFSET_SUBMIT]
        );

        // Charge the client the calculated fee
        _softChargeClient(packed.id, accounts.client, fee);
    }

    /// @notice Checks if a beacon can submit a random value. It checks the request's
    /// selected beacon, the sender of the message, and the timestamp/height of the
    /// request. If any of these checks fail, the function reverts with an error.
    function _checkCanSubmit(
        address _beacon, // The address of the selected beacon
        address[3] memory _beacons, // The array of selected beacon addresses
        uint256 beaconPos, // The position of the selected beacon in the array
        bytes10[2] memory reqValues, // The last two beacon values for the request
        SRandomUintData memory data // Data about the request
    ) private view {
        // Check if the selected beacon is in the correct position in the beacon array
        if (_beacons[beaconPos] != _beacon) revert BeaconNotSelected();

        // Checks for non-final beacons
        if (beaconPos < 2) {
            // Check if the first two requests are not zero
            if (reqValues[beaconPos] != bytes10(0)) revert BeaconValueExists();

            // Check if minConfirmations has passed for non-final beacons only.
            // Final submitter does not need a minConfirmations check because
            // it's only needed to secure the blockhash of the request height
            // used to generate the seed for the final beacon.
            if (LibNetwork._blockNumber() < data.height + data.minConfirmations)
                revert MinHeightNotYetReached(LibNetwork._blockNumber(), data.height + data.minConfirmations);
        }

        if (msg.sender != _beacon) {
            // If not a beacon, the only other permitted sender is the sequencer
            if (msg.sender != s.sequencer) revert SenderNotBeaconOrSequencer();
            // Calculate the earliest time that the sequencer can submit on behalf of the beacon
            uint256 sequencerSubmitTime = data.timestamp + (data.expirationSeconds / 2);

            // Calculate the earliest block number that the sequencer can submit on behalf of the beacon
            uint256 sequencerSubmitBlock = data.height + (data.expirationBlocks / 2) + data.minConfirmations;

            // Check if the sequencer is submitting too early
            if (block.timestamp < sequencerSubmitTime || LibNetwork._blockNumber() < sequencerSubmitBlock)
                // If the sequencer is submitting too early, revert with an error
                revert SequencerSubmissionTooEarly(
                    LibNetwork._blockNumber(),
                    sequencerSubmitBlock,
                    block.timestamp,
                    sequencerSubmitTime
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

library Constants {
    // Config keys for configUints
    uint256 constant CKEY_MIN_STAKE_ETH = 0;
    uint256 constant CKEY_EXPIRATION_BLOCKS = 1;
    uint256 constant CKEY_EXPIRATION_SECONDS = 2;
    uint256 constant CKEY_REQUEST_MIN_GAS_LIMIT = 3;
    uint256 constant CKEY_REQUEST_MAX_GAS_LIMIT = 4;
    uint256 constant CKEY_BEACON_FEE = 5;
    uint256 constant CKEY_MAX_STRIKES = 6;
    uint256 constant CKEY_MAX_CONSECUTIVE_SUBMISSIONS = 7;
    uint256 constant CKEY_MIN_CONFIRMATIONS = 8;
    uint256 constant CKEY_MAX_CONFIRMATIONS = 9;

    // Gas keys for estimateGas
    uint256 constant GKEY_OFFSET_SUBMIT = 0;
    uint256 constant GKEY_OFFSET_FINAL_SUBMIT = 1;
    uint256 constant GKEY_OFFSET_RENEW = 2;
    uint256 constant GKEY_TOTAL_SUBMIT = 3;
    uint256 constant GKEY_GAS_PER_BEACON_SELECT = 4;

    // Re-entrancy statuses
    uint8 constant STATUS_NOT_ENTERED = 1;
    uint8 constant STATUS_ENTERED = 2;

    // ChargeEth event types
    uint8 constant CHARGE_TYPE_CLIENT_TO_BEACON = 0;
    uint8 constant CHARGE_TYPE_BEACON_TO_CLIENT = 1;
    uint8 constant CHARGE_TYPE_BEACON_TO_BEACON = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * Modified for Randomizer by deanpress
 * @author Witnet Foundation
 */
library EllipticCurve {
    // Pre-computed constant for 2 ** 255
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // Constant `a` of EC equation
    uint256 public constant AA = 0;
    // Constant `b` of EC equation
    uint256 public constant BB = 7;
    // Prime number of the curve
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    /// @dev Modular euclidean inverse of a number (mod p).
    /// @param _x The number
    /// @return q such that x*q = 1 (mod PP)
    function invMod(uint256 _x) internal pure returns (uint256) {
        require(_x != 0 && _x != PP, "Invalid number");
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = PP;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (newT, addmod(q, (PP - mulmod(t, newT, PP)), PP));
            (r, _x) = (_x, r - t * _x);
        }

        return q;
    }

    /// @dev Modular exponentiation, b^e % PP.
    /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
    /// @param _base base
    /// @param _exp exponent
    /// @return r such that r = b**e (mod PP)
    function expMod(uint256 _base, uint256 _exp) internal pure returns (uint256) {
        require(PP != 0, "Modulus is zero");

        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = U255_MAX_PLUS_1;
        assembly {
            for {

            } gt(bit, 0) {

            } {
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, bit)))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), PP)
                bit := div(bit, 16)
            }
        }

        return r;
    }

    /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
    /// @param _x coordinate x
    /// @param _y coordinate y
    /// @param _z coordinate z
    /// @return (x', y') affine coordinates
    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z);
        uint256 zInv2 = mulmod(zInv, zInv, PP);
        uint256 x2 = mulmod(_x, zInv2, PP);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, PP), PP);

        return (x2, y2);
    }

    /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
    /// @param _prefix parity byte (0x02 even, 0x03 odd)
    /// @param _x coordinate x
    /// @return y coordinate y
    function deriveY(uint8 _prefix, uint256 _x) internal pure returns (uint256) {
        require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

        // x^3 + ax + b
        uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, PP), PP), addmod(mulmod(_x, AA, PP), BB, PP), PP);
        y2 = expMod(y2, (PP + 1) / 4);
        // uint256 cmp = yBit ^ y_ & 1;
        uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : PP - y2;

        return y;
    }

    /// @dev Check whether point (x,y) is on curve defined by a, b, and PP.
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @return true if x,y in the curve, false else
    function isOnCurve(uint256 _x, uint256 _y) internal pure returns (bool) {
        if (0 == _x || _x >= PP || 0 == _y || _y >= PP) {
            return false;
        }
        // y^2
        uint256 lhs = mulmod(_y, _y, PP);
        // x^3
        uint256 rhs = mulmod(mulmod(_x, _x, PP), _x, PP);
        if (AA != 0) {
            // x^3 + a*x
            rhs = addmod(rhs, mulmod(_x, AA, PP), PP);
        }
        if (BB != 0) {
            // x^3 + a*x + b
            rhs = addmod(rhs, BB, PP);
        }

        return lhs == rhs;
    }

    /// @dev Calculate inverse (x, -y) of point (x, y).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @return (x, -y)
    function ecInv(uint256 _x, uint256 _y) internal pure returns (uint256, uint256) {
        return (_x, (PP - _y) % PP);
    }

    /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @return (qx, qy) = P1+P2 in affine coordinates
    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2
    ) internal pure returns (uint256, uint256) {
        uint256 x = 0;
        uint256 y = 0;
        uint256 z = 0;

        // Double if x1==x2 else add
        if (_x1 == _x2) {
            // y1 = -y2 mod p
            if (addmod(_y1, _y2, PP) == 0) {
                return (0, 0);
            } else {
                // P1 = P2
                (x, y, z) = jacDouble(_x1, _y1, 1);
            }
        } else {
            (x, y, z) = jacAdd(_x1, _y1, 1, _x2, _y2, 1);
        }
        // Get back to affine
        return toAffine(x, y, z);
    }

    /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @return (qx, qy) = P1-P2 in affine coordinates
    function ecSub(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2
    ) internal pure returns (uint256, uint256) {
        // invert square
        (uint256 x, uint256 y) = ecInv(_x2, _y2);
        // P1-square
        return ecAdd(_x1, _y1, x, y);
    }

    /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
    /// @param _k scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @return (qx, qy) = d*P in affine coordinates
    function ecMul(
        uint256 _k,
        uint256 _x,
        uint256 _y
    ) internal pure returns (uint256, uint256) {
        // Jacobian multiplication
        (uint256 x1, uint256 y1, uint256 z1) = jacMul(_k, _x, _y, 1);
        // Get back to affine
        return toAffine(x1, y1, z1);
    }

    /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _z1 coordinate z of P1
    /// @param _x2 coordinate x of square
    /// @param _y2 coordinate y of square
    /// @param _z2 coordinate z of square
    /// @return (qx, qy, qz) P1+square in Jacobian
    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_x1 == 0 && _y1 == 0) return (_x2, _y2, _z2);
        if (_x2 == 0 && _y2 == 0) return (_x1, _y1, _z1);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        uint256[4] memory zs;
        // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(_z1, _z1, PP);
        zs[1] = mulmod(_z1, zs[0], PP);
        zs[2] = mulmod(_z2, _z2, PP);
        zs[3] = mulmod(_z2, zs[2], PP);

        // u1, s1, u2, s2
        zs = [mulmod(_x1, zs[2], PP), mulmod(_y1, zs[3], PP), mulmod(_x2, zs[0], PP), mulmod(_y2, zs[1], PP)];

        // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
        require(zs[0] != zs[2] || zs[1] != zs[3], "Use jacDouble function instead");

        uint256[4] memory hr;
        //h
        hr[0] = addmod(zs[2], PP - zs[0], PP);
        //r
        hr[1] = addmod(zs[3], PP - zs[1], PP);
        //h^2
        hr[2] = mulmod(hr[0], hr[0], PP);
        // h^3
        hr[3] = mulmod(hr[2], hr[0], PP);
        // qx = -h^3  -2u1h^2+r^2
        uint256 qx = addmod(mulmod(hr[1], hr[1], PP), PP - hr[3], PP);
        qx = addmod(qx, PP - mulmod(2, mulmod(zs[0], hr[2], PP), PP), PP);
        // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
        uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], PP), PP - qx, PP), PP);
        qy = addmod(qy, PP - mulmod(zs[1], hr[3], PP), PP);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, PP), PP);
        return (qx, qy, qz);
    }

    /// @dev Doubles a points (x, y, z).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @return (qx, qy, qz) 2P in Jacobian
    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_z == 0) return (_x, _y, _z);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
        // x, y, z at this point represent the squares of _x, _y, _z
        uint256 x = mulmod(_x, _x, PP);
        //x1^2
        uint256 y = mulmod(_y, _y, PP);
        //y1^2
        uint256 z = mulmod(_z, _z, PP);
        //z1^2

        // s
        uint256 s = mulmod(4, mulmod(_x, y, PP), PP);
        // m
        uint256 m = addmod(mulmod(3, x, PP), mulmod(AA, mulmod(z, z, PP), PP), PP);

        // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
        // This allows to reduce the gas cost and stack footprint of the algorithm
        // qx
        x = addmod(mulmod(m, m, PP), PP - addmod(s, s, PP), PP);
        // qy = -8*y1^4 + M(S-T)
        y = addmod(mulmod(m, addmod(s, PP - x, PP), PP), PP - mulmod(8, mulmod(y, y, PP), PP), PP);
        // qz = 2*y1*z1
        z = mulmod(2, mulmod(_y, _z, PP), PP);

        return (x, y, z);
    }

    /// @dev Multiply point (x, y, z) times d.
    /// @param _d scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @return (qx, qy, qz) d*P1 in Jacobian
    function jacMul(
        uint256 _d,
        uint256 _x,
        uint256 _y,
        uint256 _z
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Early return in case that `_d == 0`
        if (_d == 0) {
            return (_x, _y, _z);
        }

        uint256 remaining = _d;
        uint256 qx = 0;
        uint256 qy = 0;
        uint256 qz = 1;

        // Double and add algorithm
        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (qx, qy, qz) = jacAdd(qx, qy, qz, _x, _y, _z);
            }
            remaining = remaining / 2;
            (_x, _y, _z) = jacDouble(_x, _y, _z);
        }
        return (qx, qy, qz);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// Events that are shared across Randomizer facets
import "../shared/Structs.sol";

library Events {
    /// @notice Emits when ETH is charged between accounts
    /// @param chargeType 0: client to beacon, 1: beacon to client, 2: beacon to beacon
    /// @param from address of the sender
    /// @param to address of the recipient
    /// @param amount amount of ETH charged
    event ChargeEth(address indexed from, address indexed to, uint256 amount, uint8 chargeType);
    /// @notice Emits when a client deposits ETH
    /// @param account address of the client
    /// @param amount amount of ETH deposited
    event ClientDepositEth(address indexed account, uint256 amount);
    /// @notice Emits when a beacon stakes ETH
    /// @param account address of the beacon
    /// @param amount amount of ETH deposited
    event BeaconDepositEth(address indexed account, uint256 amount);
    /// @notice Emits when a beacon is unregistered
    /// @param beacon address of the unregistered beacon
    /// @param kicked boolean indicating if the beacon was kicked or voluntarily unregistered
    /// @param strikes number of strikes the beacon had before being unregistered
    event UnregisterBeacon(address indexed beacon, bool indexed kicked, uint8 strikes);
    /// @notice Emits when a final beacon is selected for a request
    /// @param id request id
    /// @param beacon address of the beacon added
    /// @param seed seed used for the random value generation
    /// @param timestamp new timestamp of the request
    event RequestBeacon(uint256 indexed id, address indexed beacon, bytes32 seed, uint256 timestamp);
    /// @notice Emits an event with the final random value
    /// @param id request id
    /// @param result result value
    event Result(uint256 indexed id, bytes32 result);
    /// @notice Emits when ETH is withdrawn
    /// @param to address of the recipient
    /// @param amount amount of ETH withdrawn
    event WithdrawEth(address indexed to, uint256 amount);
    /// @notice Emits if a request is retried (has new beacons)
    /// @param id request id
    /// @param request SRequestEventData struct containing request data
    /// @param chargedBeacon address of the beacon that was charged
    /// @param renewer address of the renewer
    /// @param ethToClient amount of ETH returned to the client
    /// @param ethToRenewer amount of ETH returned to the caller
    event Retry(
        uint256 indexed id,
        SRequestEventData request,
        address indexed chargedBeacon,
        address indexed renewer,
        uint256 ethToClient,
        uint256 ethToRenewer
    );
    /// @notice Emits when the sequencer is transferred from one address to another
    /// @param previousSequencer address of the previous sequencer
    /// @param newSequencer address of the new sequencer
    event TransferSequencer(address indexed previousSequencer, address indexed newSequencer);
    /// @notice Emits when the treasury address is set
    /// @param previousTreasury address of the previous treasury
    /// @param newTreasury address of the new treasury
    event SetTreasury(address indexed previousTreasury, address indexed newTreasury);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "../AppStorage.sol";
import "../libraries/LibNetwork.sol";
import "../shared/Structs.sol";

interface IRandomReceiver {
    /// @notice Callback function that is called when a random value is generated
    /// @param _id request id
    /// @param value generated random value
    function randomizerCallback(uint256 _id, bytes32 value) external;
}

library LibBeacon {
    /// @notice Emits when the callback function fails
    /// @param client address of the client that requested the random value
    /// @param id request id
    /// @param result generated random value
    /// @param txData data of the callback transaction
    event CallbackFailed(address indexed client, uint256 indexed id, bytes32 result, bytes txData);

    /// @notice Hashes the request data for validation
    /// @param id request id
    /// @param accounts struct containing client and beacon addresses
    /// @param data struct containing request data
    /// @param seed seed for the random value generation
    /// @return bytes32 hash of the request data
    function _generateRequestHash(
        uint256 id,
        SAccounts memory accounts,
        SRandomUintData memory data,
        bytes32 seed
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    id,
                    seed,
                    accounts.client,
                    accounts.beacons,
                    data.ethReserved,
                    data.beaconFee,
                    [data.height, data.timestamp],
                    data.expirationBlocks,
                    data.expirationSeconds,
                    data.callbackGasLimit,
                    data.minConfirmations
                )
            );
    }

    /// @notice Calculates the fee charge for the request
    /// @param gasAtStart gas used at the start of the function call
    /// @param _beaconFee beacon fee
    /// @param offset gas offset
    /// @return uint256 fee to be charged
    function _getFeeCharge(
        uint256 gasAtStart,
        uint256 _beaconFee,
        uint256 offset
    ) internal view returns (uint256) {
        return _beaconFee + (LibNetwork._gasPrice() * (gasAtStart + offset - gasleft()));
    }

    /// @notice Unpacks the address and request data from calldata
    /// @param _accounts address array containing client and beacon addresses
    /// @param _data uint256 array containing request data
    /// @return SAccounts struct and SPackedSubmitData struct
    function _getAccountsAndPackedData(address[4] calldata _accounts, uint256[19] calldata _data)
        internal
        pure
        returns (SAccounts memory, SPackedSubmitData memory)
    {
        return (_resolveAddressCalldata(_accounts), _resolveUintVrfData(_data));
    }

    /// @notice Unpacks the address data from calldata
    /// @param _data address array containing client and beacon addresses
    /// @return SAccounts struct
    function _resolveAddressCalldata(address[4] calldata _data) internal pure returns (SAccounts memory) {
        return SAccounts(_data[0], [_data[1], _data[2], _data[3]]);
    }

    /// @notice Unpacks the packed request and VRF data from calldata
    /// @param _data uint256 array containing packed request data
    /// @return SPackedSubmitData struct
    function _resolveUintVrfData(uint256[19] calldata _data)
        internal
        pure
        returns (SPackedSubmitData memory)
    {
        return
            SPackedSubmitData(
                uint256(_data[0]),
                SRandomUintData(
                    _data[1],
                    _data[2],
                    _data[3],
                    _data[4],
                    _data[5],
                    _data[6],
                    _data[7],
                    _data[8]
                ),
                SFastVerifyData(
                    [_data[9], _data[10], _data[11], _data[12]],
                    [_data[13], _data[14]],
                    [_data[15], _data[16], _data[17], _data[18]]
                )
            );
    }

    /// @notice Unpacks the request data from calldata
    /// @param _data uint256 array containing request data
    /// @return SPackedUintData struct
    function _resolveUintData(uint256[9] calldata _data) internal pure returns (SPackedUintData memory) {
        return
            SPackedUintData(
                uint256(_data[0]),
                SRandomUintData(
                    _data[1],
                    _data[2],
                    _data[3],
                    _data[4],
                    _data[5],
                    _data[6],
                    _data[7],
                    _data[8]
                )
            );
    }

    /// @notice Calls the callback function on the client contract
    /// @param _to address of the client contract
    /// @param _gasLimit gas limit for the callback transaction
    /// @param _id request id
    /// @param _result generated random value
    function _callback(
        address _to,
        uint256 _gasLimit,
        uint256 _id,
        bytes32 _result
    ) internal {
        // Call the `randomizerCallback` function on the specified contract address with the given parameters
        (bool success, bytes memory callbackTxData) = _to.call{gas: _gasLimit}(
            abi.encodeWithSelector(IRandomReceiver.randomizerCallback.selector, _id, _result)
        );

        // If the call to `randomizerCallback` failed, emit a CallbackFailed event
        if (!success) emit CallbackFailed(_to, _id, _result, callbackTxData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Owner of the contract
        address contractOwner;
        // Proposed owner of the contract
        address proposedOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed previousOwner, address indexed newOwner);
    event ProposeOwnershipCanceled(address indexed proposedOwner, address indexed currentOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function setProposedContractOwner(address _proposedOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.proposedOwner = _proposedOwner;
        emit OwnershipProposed(ds.contractOwner, _proposedOwner);
    }

    function acceptProposedContractOwner() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = ds.proposedOwner;
        ds.proposedOwner = address(0);
        emit OwnershipTransferred(previousOwner, ds.contractOwner);
    }

    function cancelProposedContractOwner() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousProposedOwner = ds.proposedOwner;
        ds.proposedOwner = address(0);
        emit ProposeOwnershipCanceled(previousProposedOwner, ds.contractOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function proposedOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().proposedOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "Unauthorized: Must be contract owner");
    }

    function enforceIsProposedContractOwner() internal view {
        require(
            msg.sender == diamondStorage().proposedOwner,
            "Unauthorized: Must be proposed contract owner"
        );
    }

    function enforceIsCurrentOrProposedContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == diamondStorage().proposedOwner,
            "Unauthorized: Must be current or proposed contract owner"
        );
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                lastSelectorPosition
            ];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);

    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);
}

interface ArbGasInfo {
    function getMinimumGasPrice() external view returns (uint256);
}

library LibNetwork {
    function _seed(uint256 id) internal view returns (bytes32) {
        uint256 blockNum = _blockNumber();
        return
            keccak256(
                abi.encode(
                    address(this),
                    id,
                    block.prevrandao,
                    _blockHash(blockNum - 1),
                    blockNum,
                    block.timestamp,
                    block.chainid
                )
            );
    }

    function _maxGasPriceAfterConfirmations(uint256 _confirmations)
        internal
        view
        returns (uint256 maxGasPrice)
    {
        uint256 minPrice = ArbGasInfo(address(108)).getMinimumGasPrice();
        uint256 maxFee = minPrice + (minPrice / 4) + 1;
        maxGasPrice = tx.gasprice < maxFee ? tx.gasprice : maxFee;
        // maxFee can go up by 12.5% per confirmation, calculate the max fee for the number of confirmations
        if (_confirmations > 1) {
            uint256 i = 0;
            do {
                maxGasPrice += (maxGasPrice / 8) + 1;
                unchecked {
                    ++i;
                }
            } while (i < _confirmations);
        }
    }

    function _maxGasPriceAfterConfirmations(uint256 _price, uint256 _confirmations)
        internal
        pure
        returns (uint256 maxGasPrice)
    {
        maxGasPrice = _price + (_price / 4) + 1;
        // maxFee goes up by 12.5% per confirmation, calculate the max fee for the number of confirmations
        if (_confirmations > 1) {
            uint256 i = 0;
            do {
                maxGasPrice += (maxGasPrice / 8) + 1;
                unchecked {
                    ++i;
                }
            } while (i < _confirmations);
        }
    }

    function _gasPrice() internal view returns (uint256) {
        uint256 minPrice = ArbGasInfo(address(108)).getMinimumGasPrice();
        uint256 maxFee = minPrice + (minPrice / 4) + 1;
        return tx.gasprice < maxFee ? tx.gasprice : maxFee;
    }

    function _blockHash(uint256 blockNumber) internal view returns (bytes32) {
        return ArbSys(address(100)).arbBlockHash(blockNumber);
    }

    function _blockNumber() internal view returns (uint256) {
        return ArbSys(address(100)).arbBlockNumber();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../libraries/EllipticCurve.sol";

/**
 * @title Verifiable Random Functions (VRF)
 * @notice Library verifying VRF proofs using the `Secp256k1` curve and the `SHA256` hash function.
 * @dev This library follows the algorithms described in [VRF-draft-04](https://tools.ietf.org/pdf/draft-irtf-cfrg-vrf-04) and [RFC6979](https://tools.ietf.org/html/rfc6979).
 * It supports the _SECP256K1_SHA256_TAI_ cipher suite, i.e. the aforementioned algorithms using `SHA256` and the `Secp256k1` curve.
 * @author Witnet Foundation (with changes by @deanpress)
 */

library LibVRF {
    /**
     * Secp256k1 parameters
     */

    // Generator coordinate `x` of the EC curve
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    // Generator coordinate `y` of the EC curve
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    // Order of the curve
    uint256 public constant NN = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    /// @dev Public key derivation from private key.
    /// Warning: this function should not be used to derive your public key as it would expose the private key.
    /// @param _d The scalar
    /// @param _x The coordinate x
    /// @param _y The coordinate y
    /// @return (qx, qy) The derived point
    function derivePoint(
        uint256 _d,
        uint256 _x,
        uint256 _y
    ) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecMul(_d, _x, _y);
    }

    /// @dev Function to derive the `y` coordinate given the `x` coordinate and the parity byte (`0x03` for odd `y` and `0x04` for even `y`).
    /// @param _yByte The parity byte following the ec point compressed format
    /// @param _x The coordinate `x` of the point
    /// @return The coordinate `y` of the point
    function deriveY(uint8 _yByte, uint256 _x) internal pure returns (uint256) {
        return EllipticCurve.deriveY(_yByte, _x);
    }

    /// @dev Computes the VRF hash output as result of the digest of a ciphersuite-dependent prefix
    /// concatenated with the gamma point
    /// @param _gammaX The x-coordinate of the gamma EC point
    /// @param _gammaY The y-coordinate of the gamma EC point
    /// @return The VRF hash ouput as shas256 digest
    function gammaToHash(uint256 _gammaX, uint256 _gammaY) internal pure returns (bytes32) {
        bytes memory c = abi.encodePacked(
            // Cipher suite code (SECP256K1-SHA256-TAI is 0xFE)
            uint8(0xFE),
            // 0x03
            uint8(0x03),
            // Compressed Gamma Point
            encodePoint(_gammaX, _gammaY)
        );

        return sha256(c);
    }

    /// @dev VRF verification by providing the public key, the message and the VRF proof.
    /// This function computes several elliptic curve operations which may lead to extensive gas consumption.
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    /// @param _message The message (in bytes) used for computing the VRF
    /// @return true, if VRF proof is valid
    function verify(
        uint256[2] memory _publicKey,
        uint256[4] memory _proof, //pi
        bytes memory _message //alpha
    ) internal pure returns (bool) {
        // Step 2: Hash to try and increment (outputs a hashed value, a finite EC point in G)
        (uint256 hPointX, uint256 hPointY) = hashToTryAndIncrement(_publicKey, _message);

        // Step 3: U = s*B - c*Y (where B is the generator)
        (uint256 uPointX, uint256 uPointY) = ecMulSubMul(
            _proof[3],
            GX,
            GY,
            _proof[2],
            _publicKey[0],
            _publicKey[1]
        );

        // Step 4: V = s*H - c*Gamma
        (uint256 vPointX, uint256 vPointY) = ecMulSubMul(
            _proof[3],
            hPointX,
            hPointY,
            _proof[2],
            _proof[0],
            _proof[1]
        );

        // Step 5: derived c from hash points(...)
        bytes16 derivedC = hashPoints(
            hPointX,
            hPointY,
            _proof[0],
            _proof[1],
            uPointX,
            uPointY,
            vPointX,
            vPointY
        );

        // Step 6: Check validity c == c'
        return uint128(derivedC) == _proof[2];
    }

    /// @dev VRF fast verification by providing the public key, the message, the VRF proof and several intermediate elliptic curve points that enable the verification shortcut.
    /// This function leverages the EVM's `ecrecover` precompile to verify elliptic curve multiplications by decreasing the security from 32 to 20 bytes.
    /// Based on the original idea of Vitalik Buterin: https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    /// @param _message The message (in bytes) used for computing the VRF
    /// @param _uPoint The `u` EC point defined as `U = s*B - c*Y`
    /// @param _vComponents The components required to compute `v` as `V = s*H - c*Gamma`
    /// @return true, if VRF proof is valid
    function fastVerify(
        uint256[2] memory _publicKey, //Y-x, Y-y
        uint256[4] memory _proof, //pi, which is D, a.k.a. gamma-x, gamma-y, c, s
        bytes memory _message, //alpha string
        uint256[2] memory _uPoint, //U-x, U-y
        uint256[4] memory _vComponents //s*H -x, s*H -y, c*Gamma -x, c*Gamma -y
    ) internal pure returns (bool) {
        // Step 2: Hash to try and increment -> hashed value, a finite EC point in G
        (uint256 hPointX, uint256 hPointY) = hashToTryAndIncrement(_publicKey, _message);

        // Step 3 & Step 4:
        // U = s*B - c*Y (where B is the generator)
        // V = s*H - c*Gamma
        if (
            !ecMulSubMulVerify(
                _proof[3], //s
                _proof[2], //c
                _publicKey[0], //Y-x
                _publicKey[1], //Y-y
                _uPoint[0], //U-x
                _uPoint[1]
            ) || //U-y
            !ecMulVerify(
                _proof[3], //s
                hPointX, //H-x
                hPointY, //H-y
                _vComponents[0], //s*H -x
                _vComponents[1]
            ) || //s*H -y
            !ecMulVerify(
                _proof[2], //c
                _proof[0], //gamma-x
                _proof[1], //gamma-y
                _vComponents[2], //c*Gamma -x
                _vComponents[3]
            ) //c*Gamma -y
        ) {
            return false;
        }

        (uint256 vPointX, uint256 vPointY) = EllipticCurve.ecSub(
            _vComponents[0], //s*H -x
            _vComponents[1], //s*H -y
            _vComponents[2], //c*Gamma -x
            _vComponents[3] //c*Gamma -y
        );

        // Step 5: derived c from hash points(...)
        bytes16 derivedC = hashPoints(
            hPointX,
            hPointY,
            _proof[0],
            _proof[1],
            _uPoint[0],
            _uPoint[1],
            vPointX,
            vPointY
        );

        // Step 6: Check validity c == c'
        return uint128(derivedC) == _proof[2];
    }

    /// @dev Decode VRF proof from bytes
    /// @param _proof The VRF proof as bytes
    /// @return The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    function decodeProof(bytes memory _proof) internal pure returns (uint256[4] memory) {
        require(_proof.length == 81, "Malformed VRF proof");
        uint8 gammaSign;
        uint256 gammaX;
        uint128 c;
        uint256 s;
        assembly {
            gammaSign := mload(add(_proof, 1))
            gammaX := mload(add(_proof, 33))
            c := mload(add(_proof, 49))
            s := mload(add(_proof, 81))
        }
        uint256 gammaY = deriveY(gammaSign, gammaX);

        return [gammaX, gammaY, c, s];
    }

    /// @dev Decode EC point from bytes
    /// @param _point The EC point as bytes
    /// @return The point as `[point-x, point-y]`
    function decodePoint(bytes memory _point) internal pure returns (uint256[2] memory) {
        require(_point.length == 33, "Malformed compressed EC point");
        uint8 sign;
        uint256 x;
        assembly {
            sign := mload(add(_point, 1))
            x := mload(add(_point, 33))
        }
        uint256 y = deriveY(sign, x);

        return [x, y];
    }

    /// @dev Compute the parameters (EC points) required for the VRF fast verification function.
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    /// @param _message The message (in bytes) used for computing the VRF
    /// @return The fast verify required parameters as the tuple `([uPointX, uPointY], [sHX, sHY, cGammaX, cGammaY])`
    function computeFastVerifyParams(
        uint256[2] memory _publicKey,
        uint256[4] memory _proof,
        bytes memory _message
    ) internal pure returns (uint256[2] memory, uint256[4] memory) {
        // Requirements for Step 3: U = s*B - c*Y (where B is the generator)
        (uint256 hPointX, uint256 hPointY) = hashToTryAndIncrement(_publicKey, _message);
        (uint256 uPointX, uint256 uPointY) = ecMulSubMul(
            _proof[3],
            GX,
            GY,
            _proof[2],
            _publicKey[0],
            _publicKey[1]
        );
        // Requirements for Step 4: V = s*H - c*Gamma
        (uint256 sHX, uint256 sHY) = derivePoint(_proof[3], hPointX, hPointY);
        (uint256 cGammaX, uint256 cGammaY) = derivePoint(_proof[2], _proof[0], _proof[1]);

        return ([uPointX, uPointY], [sHX, sHY, cGammaX, cGammaY]);
    }

    /// @dev Function to convert a `Hash(PK|DATA)` to a point in the curve as defined in [VRF-draft-04](https://tools.ietf.org/pdf/draft-irtf-cfrg-vrf-04).
    /// Used in Step 2 of VRF verification function.
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _message The message used for computing the VRF
    /// @return The hash point in affine cooridnates
    function hashToTryAndIncrement(uint256[2] memory _publicKey, bytes memory _message)
        internal
        pure
        returns (uint256, uint256)
    {
        // Step 1: public key to bytes
        // Step 2: V = cipher_suite | 0x01 | public_key_bytes | message | ctr
        bytes memory c = abi.encodePacked(
            // Cipher suite code (SECP256K1-SHA256-TAI is 0xFE)
            uint8(254),
            // 0x01
            uint8(1),
            // Public Key
            encodePoint(_publicKey[0], _publicKey[1]),
            // Message
            _message
        );

        // Step 3: find a valid EC point
        // Loop over counter ctr starting at 0x00 and do hash
        uint8 ctr = 0;
        do {
            // Counter update
            // c[cLength-1] = byte(ctr);
            bytes32 sha = sha256(abi.encodePacked(c, ctr));
            // Step 4: arbitraty string to point and check if it is on curve
            uint256 hPointX = uint256(sha);
            uint256 hPointY = deriveY(2, hPointX);
            if (EllipticCurve.isOnCurve(hPointX, hPointY)) {
                // Step 5 (omitted): calculate H (cofactor is 1 on secp256k1)
                // If H is not "INVALID" and cofactor > 1, set H = cofactor * H
                return (hPointX, hPointY);
            }
            unchecked {
                ++ctr;
            }
        } while (ctr < 256);
        revert("No valid point was found");
    }

    /// @dev Function to hash a certain set of points as specified in [VRF-draft-04](https://tools.ietf.org/pdf/draft-irtf-cfrg-vrf-04).
    /// Used in Step 5 of VRF verification function.
    /// @param _hPointX The coordinate `x` of point `H`
    /// @param _hPointY The coordinate `y` of point `H`
    /// @param _gammaX The coordinate `x` of the point `Gamma`
    /// @param _gammaX The coordinate `y` of the point `Gamma`
    /// @param _uPointX The coordinate `x` of point `U`
    /// @param _uPointY The coordinate `y` of point `U`
    /// @param _vPointX The coordinate `x` of point `V`
    /// @param _vPointY The coordinate `y` of point `V`
    /// @return The first half of the digest of the points using SHA256
    function hashPoints(
        uint256 _hPointX,
        uint256 _hPointY,
        uint256 _gammaX,
        uint256 _gammaY,
        uint256 _uPointX,
        uint256 _uPointY,
        uint256 _vPointX,
        uint256 _vPointY
    ) internal pure returns (bytes16) {
        bytes memory c = abi.encodePacked(
            // Ciphersuite 0xFE
            uint8(254),
            // Prefix 0x02
            uint8(2),
            // Points to Bytes
            encodePoint(_hPointX, _hPointY),
            encodePoint(_gammaX, _gammaY),
            encodePoint(_uPointX, _uPointY),
            encodePoint(_vPointX, _vPointY)
        );
        // Hash bytes and truncate
        bytes32 sha = sha256(c);
        bytes16 half1;
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer, 0x00), sha)
            half1 := mload(add(freemem_pointer, 0x00))
        }

        return half1;
    }

    /// @dev Encode an EC point to bytes
    /// @param _x The coordinate `x` of the point
    /// @param _y The coordinate `y` of the point
    /// @return The point coordinates as bytes
    function encodePoint(uint256 _x, uint256 _y) internal pure returns (bytes memory) {
        uint8 prefix = uint8(2 + (_y % 2));

        return abi.encodePacked(prefix, _x);
    }

    /// @dev Substracts two key derivation functionsas `s1*A - s2*B`.
    /// @param _scalar1 The scalar `s1`
    /// @param _a1 The `x` coordinate of point `A`
    /// @param _a2 The `y` coordinate of point `A`
    /// @param _scalar2 The scalar `s2`
    /// @param _b1 The `x` coordinate of point `B`
    /// @param _b2 The `y` coordinate of point `B`
    /// @return The derived point in affine cooridnates
    function ecMulSubMul(
        uint256 _scalar1,
        uint256 _a1,
        uint256 _a2,
        uint256 _scalar2,
        uint256 _b1,
        uint256 _b2
    ) internal pure returns (uint256, uint256) {
        (uint256 m1, uint256 m2) = derivePoint(_scalar1, _a1, _a2);
        (uint256 n1, uint256 n2) = derivePoint(_scalar2, _b1, _b2);
        (uint256 r1, uint256 r2) = EllipticCurve.ecSub(m1, m2, n1, n2);

        return (r1, r2);
    }

    /// @dev Verify an Elliptic Curve multiplication of the form `(qx,qy) = scalar*(x,y)` by using the precompiled `ecrecover` function.
    /// The usage of the precompiled `ecrecover` function decreases the security from 32 to 20 bytes.
    /// Based on the original idea of Vitalik Buterin: https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    /// @param _scalar The scalar of the point multiplication
    /// @param _x The coordinate `x` of the point
    /// @param _y The coordinate `y` of the point
    /// @param _qx The coordinate `x` of the multiplication result
    /// @param _qy The coordinate `y` of the multiplication result
    /// @return true, if first 20 bytes match
    function ecMulVerify(
        uint256 _scalar,
        uint256 _x,
        uint256 _y,
        uint256 _qx,
        uint256 _qy
    ) internal pure returns (bool) {
        address result = ecrecover(0, _y % 2 != 0 ? 28 : 27, bytes32(_x), bytes32(mulmod(_scalar, _x, NN)));

        return pointToAddress(_qx, _qy) == result;
    }

    /// @dev Verify an Elliptic Curve operation of the form `Q = scalar1*(gx,gy) - scalar2*(x,y)` by using the precompiled `ecrecover` function, where `(gx,gy)` is the generator of the EC.
    /// The usage of the precompiled `ecrecover` function decreases the security from 32 to 20 bytes.
    /// Based on SolCrypto library: https://github.com/HarryR/solcrypto
    /// @param _scalar1 The scalar of the multiplication of `(gx,gy)`
    /// @param _scalar2 The scalar of the multiplication of `(x,y)`
    /// @param _x The coordinate `x` of the point to be mutiply by `scalar2`
    /// @param _y The coordinate `y` of the point to be mutiply by `scalar2`
    /// @param _qx The coordinate `x` of the equation result
    /// @param _qy The coordinate `y` of the equation result
    /// @return true, if first 20 bytes match
    function ecMulSubMulVerify(
        uint256 _scalar1,
        uint256 _scalar2,
        uint256 _x,
        uint256 _y,
        uint256 _qx,
        uint256 _qy
    ) internal pure returns (bool) {
        uint256 scalar1 = (NN - _scalar1) % NN;
        scalar1 = mulmod(scalar1, _x, NN);
        uint256 scalar2 = (NN - _scalar2) % NN;

        address result = ecrecover(
            bytes32(scalar1),
            _y % 2 != 0 ? 28 : 27,
            bytes32(_x),
            bytes32(mulmod(scalar2, _x, NN))
        );

        return pointToAddress(_qx, _qy) == result;
    }

    /// @dev Gets the address corresponding to the EC point digest (keccak256), i.e. the first 20 bytes of the digest.
    /// This function is used for performing a fast EC multiplication verification.
    /// @param _x The coordinate `x` of the point
    /// @param _y The coordinate `y` of the point
    /// @return The address of the EC point digest (keccak256)
    function pointToAddress(uint256 _x, uint256 _y) internal pure returns (address) {
        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(_x, _y)))) &
                    0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

struct SPackedSubmitData {
    uint256 id;
    SRandomUintData data;
    SFastVerifyData vrf;
}

// publicKey: [pubKey-x, pubKey-y]
// proof: [gamma-x, gamma-y, c, s]
// uPoint: [uPointX, uPointY]
// vComponents: [sHX, sHY, cGammaX, cGammaY]
struct SFastVerifyData {
    uint256[4] proof;
    uint256[2] uPoint;
    uint256[4] vComponents;
}

struct SPackedUintData {
    uint256 id;
    SRandomUintData data;
}

struct SRandomUintData {
    uint256 ethReserved;
    uint256 beaconFee;
    uint256 height;
    uint256 timestamp;
    uint256 expirationBlocks;
    uint256 expirationSeconds;
    uint256 callbackGasLimit;
    uint256 minConfirmations;
}

struct SRequestEventData {
    uint256 ethReserved;
    uint256 beaconFee;
    uint256 timestamp;
    uint256 expirationBlocks;
    uint256 expirationSeconds;
    uint256 callbackGasLimit;
    uint256 minConfirmations;
    address client;
    address[3] beacons;
    bytes32 seed;
}

struct SAccounts {
    address client;
    address[3] beacons;
}

struct Beacon {
    uint256[2] publicKey;
    bool registered;
    uint8 strikes;
    uint8 consecutiveSubmissions;
    uint64 pending;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "../AppStorage.sol";
import "../libraries/LibNetwork.sol";
import "../libraries/Constants.sol";
import "../libraries/LibBeacon.sol";
import "../libraries/Events.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract Utils {
    AppStorage internal s;

    // Errors
    error BeaconNotFound();
    error NotEnoughBeaconsAvailable(uint256 availableBeacons, uint256 requiredBeacons);
    error ReentrancyGuard();
    error FailedToSendEth(address to, uint256 amount);
    error RequestDataMismatch(bytes32 givenHash, bytes32 expectedHash);
    error RequestNotFound(uint256 id);

    /// @notice Emits an event on a new request that contains all data needed for a beacon to process it
    /// @param request request data
    event Request(uint256 indexed id, SRequestEventData request);

    /// @dev Removes a beacon from the list of beacons
    function _removeBeacon(address _beacon) internal {
        uint256 index = s.beaconIndex[_beacon];
        if (index == 0) revert BeaconNotFound();
        uint256 lastBeaconIndex = s.beacons.length - 1;
        s.beacon[_beacon].registered = false;
        if (index == lastBeaconIndex) {
            s.beaconIndex[_beacon] = 0;
            s.beacons.pop();
            return;
        }
        s.beacons[index] = s.beacons[lastBeaconIndex];
        address newBeacon = s.beacons[lastBeaconIndex];
        s.beaconIndex[_beacon] = 0;
        // The replacing beacon gets assigned the replaced beacon's index
        s.beaconIndex[newBeacon] = index;
        s.beacons.pop();
    }

    function _requestBeacon(
        uint256 _id,
        uint256 _beaconPos,
        bytes32 _seed,
        SAccounts memory _accounts,
        SRandomUintData memory _data
    ) internal {
        if (s.beacons.length < 5) revert NotEnoughBeaconsAvailable(s.beacons.length, 5);
        _data.height = LibNetwork._blockNumber();
        _data.timestamp = block.timestamp;
        address randomBeacon = _selectOneBeacon(_seed, [_accounts.beacons[0], _accounts.beacons[1]]);
        s.beacon[randomBeacon].pending++;
        _accounts.beacons[_beaconPos] = randomBeacon;
        s.requestToHash[_id] = LibBeacon._generateRequestHash(_id, _accounts, _data, _seed);
        emit Events.RequestBeacon(_id, randomBeacon, _seed, _data.timestamp);
    }

    function _selectTwoBeacons(bytes32 _random) internal returns (address, address) {
        // Create a new array that contains only the items that are not in the exclude array
        address[] memory selectedItems = s.beacons;

        // Shuffle the selectedItems array using the Fisher-Yates shuffle algorithm
        uint256 i = 1;
        do {
            // Generate a random index j such that i <= j <= selectedItems.length - 1
            uint256 j = (uint256(keccak256(abi.encodePacked(_random, i))) % (selectedItems.length - i)) + i;
            // Swap the items at indices i and j
            address temp = selectedItems[i];
            selectedItems[i] = selectedItems[j];
            selectedItems[j] = temp;
            s.beacon[selectedItems[i]].pending++;
            unchecked {
                ++i;
            }
        } while (i < 3);
        // Return the first two items from the shuffled array
        return (selectedItems[1], selectedItems[2]);
    }

    function _selectOneBeacon(bytes32 _random, address[2] memory _exclude) internal view returns (address) {
        // Create a new array that contains only the items that are not in the exclude array
        (address[] memory selectedItems, uint256 count) = _beaconsWithoutExcluded(_exclude);

        // Generate a random index j such that j <= count
        uint256 j = uint256(_random) % count;

        return selectedItems[j];
    }

    /*
     * Below we have 3 _beaconsWithoutExcluded views that have identical logic, except they accept different length arrays for the input.
     * The only alternative is to have a dynamic array input, which would require a memory allocation, which is more expensive.
     */

    function _beaconsWithoutExcluded(address[2] memory _excluded)
        internal
        view
        returns (address[] memory, uint256 count)
    {
        uint256 beaconsLen = s.beacons.length;
        address[] memory selectedItems = new address[](beaconsLen - 2);

        uint256 i = 1;
        do {
            bool found = false;
            uint256 j = 0;
            while (j < _excluded.length) {
                if (s.beacons[i] == _excluded[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                selectedItems[count] = s.beacons[i];
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        } while (i < beaconsLen);

        return (selectedItems, count);
    }

    function _beaconsWithoutExcluded(address[3] memory _excluded)
        internal
        view
        returns (address[] memory, uint256 count)
    {
        uint256 beaconsLen = s.beacons.length;
        address[] memory selectedItems = new address[](beaconsLen - 3);

        uint256 i = 1;
        do {
            bool found = false;
            uint256 j = 0;
            while (j < _excluded.length) {
                if (s.beacons[i] == _excluded[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                selectedItems[count] = s.beacons[i];
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        } while (i < beaconsLen);

        return (selectedItems, count);
    }

    function _beaconsWithoutExcluded(address[5] memory _excluded, uint256 excludeLen)
        internal
        view
        returns (address[] memory, uint256 count)
    {
        uint256 beaconsLen = s.beacons.length;
        address[] memory selectedItems = new address[](beaconsLen - excludeLen);

        uint256 i = 1;
        do {
            bool found = false;
            uint256 j = 0;
            while (j < _excluded.length) {
                if (s.beacons[i] == _excluded[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                selectedItems[count] = s.beacons[i];
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        } while (i < beaconsLen);

        return (selectedItems, count);
    }

    function _processResult(
        uint256 id,
        address client,
        bytes10[3] memory hashes,
        uint256 callbackGasLimit,
        uint256 _ethReserved
    ) internal {
        bytes32 result = keccak256(abi.encodePacked(hashes[0], hashes[1], hashes[2]));

        // Callback to requesting contract
        LibBeacon._callback(client, callbackGasLimit, id, result);
        s.ethReserved[client] -= _ethReserved;

        s.results[id] = result;
        emit Events.Result(id, result);
    }

    function _finalSoftChargeClient(
        uint256 id,
        address client,
        uint256 fee,
        uint256 beaconFee
    ) internal {
        uint256 daoFee;
        uint256 seqFee;
        uint256 deposit = s.ethDeposit[client];
        if (deposit > 0) {
            if (deposit > fee) {
                // If this is the final charge for the request,
                // add fee for configured treasury and sequencer
                daoFee = deposit >= fee + beaconFee ? beaconFee : deposit - fee;
                _chargeClient(client, s.treasury, daoFee);
                // Only add sequencer fee if the deposit has enough subtracting sender and treasury fee
                if (deposit > fee + daoFee) {
                    seqFee = deposit >= fee + daoFee + beaconFee ? beaconFee : deposit - daoFee - fee;
                    _chargeClient(client, s.sequencer, seqFee);
                }
            } else {
                fee = deposit;
            }
            s.requestToFeePaid[id] += fee + seqFee + daoFee;
            _chargeClient(client, msg.sender, fee);
        }
    }

    function _softChargeClient(
        uint256 id,
        address client,
        uint256 fee
    ) internal {
        uint256 deposit = s.ethDeposit[client];
        if (deposit > 0) {
            if (deposit < fee) {
                fee = deposit;
            }
            s.requestToFeePaid[id] += fee;
            _chargeClient(client, msg.sender, fee);
        }
    }

    function _transferEth(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        if (sent) {
            emit Events.WithdrawEth(_to, _amount);
        } else {
            revert FailedToSendEth(_to, _amount);
        }
    }

    function _chargeClient(
        address _from,
        address _to,
        uint256 _value
    ) private {
        s.ethDeposit[_from] -= _value;
        s.ethCollateral[_to] += _value;
        emit Events.ChargeEth(_from, _to, _value, Constants.CHARGE_TYPE_CLIENT_TO_BEACON);
    }

    function _validateRequestData(
        uint256 id,
        bytes32 seed,
        SAccounts memory accounts,
        SRandomUintData memory data
    ) internal view {
        bytes32 generatedHash = LibBeacon._generateRequestHash(id, accounts, data, seed);

        /* No need to require(requestToResult[packed.id] == bytes(0))
         * because requestToHash will already be bytes(0) if it's fulfilled
         * and wouldn't match the generated hash.
         * generatedHash can never be bytes(0) because packed.data.height must be greater than 0 */

        if (s.requestToHash[id] != generatedHash)
            revert RequestDataMismatch(generatedHash, s.requestToHash[id]);

        if (data.height == 0) revert RequestNotFound(id);
    }

    function _generateRequest(
        uint256 id,
        address client,
        SRandomUintData memory data
    ) internal {
        if (s.beacons.length < 5) revert NotEnoughBeaconsAvailable(s.beacons.length, 5);

        bytes32 seed = LibNetwork._seed(id);

        (address beaconOne, address beaconTwo) = _selectTwoBeacons(seed);
        address[3] memory selectedBeacons = [beaconOne, beaconTwo, address(0)];

        SAccounts memory accounts = SAccounts(client, selectedBeacons);

        bytes32 generatedHash = LibBeacon._generateRequestHash(id, accounts, data, seed);

        s.requestToHash[id] = generatedHash;

        // Emit event with new request data
        emit Request(
            id,
            SRequestEventData(
                data.ethReserved,
                data.beaconFee,
                block.timestamp,
                data.expirationBlocks,
                data.expirationSeconds,
                data.callbackGasLimit,
                data.minConfirmations,
                client,
                selectedBeacons,
                seed
            )
        );
    }
}