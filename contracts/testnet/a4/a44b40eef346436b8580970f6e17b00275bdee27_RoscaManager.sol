// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IRoscaGroup.sol";
import "./RoscaGroup.sol";

contract RoscaManager is Ownable {
    uint256 _nextGroupId;
    mapping(uint256 => address) _groups;

    address public immutable baseImplementation;
    address public STABLECOIN_ADDRESS;

    event GroupCreated(address groupAddress, address creator);

    constructor(
        address initialOwner,
        address stablecoinAddress
    ) Ownable(initialOwner) {
        STABLECOIN_ADDRESS = stablecoinAddress;
        baseImplementation = address(new RoscaGroup());
    }

    function setStablecoinAddress(address stablecoinAddress) external onlyOwner {
        STABLECOIN_ADDRESS = stablecoinAddress;
    }

    function withdrawStablecoin() external onlyOwner {
        IERC20(STABLECOIN_ADDRESS).transfer(
            owner(), 
            IERC20(STABLECOIN_ADDRESS).balanceOf(address(this))
        );
    }

    function createGroup(uint256 amount, uint256 members) public {
        uint256 groupId = _nextGroupId++;
        address clone = Clones.clone(baseImplementation);
        IRoscaGroup(clone).initialize(
            groupId,
            amount,
            members,
            address(this),
            STABLECOIN_ADDRESS,
            owner()
        );
        _groups[groupId] = clone;
        emit GroupCreated(clone, msg.sender);
    }

    function numberOfGroups() public view returns (uint256) {
        return _nextGroupId;
    }

    function getGroup(uint256 groupId) public view returns (address) {
        return _groups[groupId];
    }

    function getOpenGroups() public view returns (IRoscaGroup.GroupDetails[] memory) {
        uint256 openGroupsCount = 0;
        for (uint256 i = 0; i < _nextGroupId; i++) {
            IRoscaGroup group = IRoscaGroup(_groups[i]);
            (IRoscaGroup.GroupDetails memory groupDetails) = group.getGroupDetails();
            if (groupDetails.startTime == 0) {
                openGroupsCount++;
            }
        }

        IRoscaGroup.GroupDetails[] memory openGroups = new IRoscaGroup.GroupDetails[](openGroupsCount);
        uint256 openGroupsIndex = 0;
        for (uint256 i = 0; i < _nextGroupId; i++) {
            IRoscaGroup group = IRoscaGroup(_groups[i]);
            (IRoscaGroup.GroupDetails memory groupDetails) = group.getGroupDetails();
            if (groupDetails.startTime == 0) {
                openGroups[openGroupsIndex] = groupDetails;
                openGroupsIndex++;
            }
        }
        return openGroups;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

pragma solidity ^0.8.20;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRoscaGroup {
    struct GroupDetails {
        uint256 id;
        uint256 amount;
        uint256 members;
        uint256 currentMembers;
        uint256 currentRound;
        uint256 createdAt;
        uint256 startTime;
        uint256 endTime;
        address groupAddress;
    }

    enum GroupStage {
        INITIALIZED,
        ONGOING,
        ENDED,
        CANCELLED
    }

    enum RoundStage {
        UNINITIALIZED,
        COLLECTION,
        BIDDING,
        ENDED
    }

    function initialize(
        uint256 id,
        uint256 amount,
        uint256 members,
        address manager,
        address stablecoin,
        address owner
    ) external;

    function getGroupDetails() external view returns (GroupDetails memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRoscaGroup.sol";

contract RoscaGroup is IRoscaGroup, Initializable {
    address[] _members;
    GroupDetails _groupDetails;
    mapping(uint256 => mapping(address => bool)) _memberContributed;
    mapping(uint256 => bytes) proofs;

    uint8 public constant PLATFORM_FEE = 5;
    uint16 public constant MIN_CREDIT_SCORE = 400;
    address public STABLECOIN_ADDRESS;
    address public MANAGER_ADDRESS;
    address public MULTI_SIG_ADDRESS;
    address public owner;
    address public oracle;

    mapping(address => bool) public isMember;
    mapping(address => bool) public isWinner;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public unclaimedAmount;

    GroupStage public groupStage = GroupStage.INITIALIZED;
    mapping(uint256 => RoundStage) public roundStage;

    event GroupStarted(uint256 startTime);
    event GroupEnded(uint256 endTime);
    event GroupCancelled(uint256 endTime);

    event RoundStarted(uint256 round, uint256 startTime);
    event RoundEnded(uint256 round, uint256 endTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only member");
        _;
    }

    modifier onlyMultiSigOrOwner() {
        require(
            msg.sender == MULTI_SIG_ADDRESS || msg.sender == owner,
            "Only multisig or owner"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 id_,
        uint256 amount_,
        uint256 members_,
        address manager_,
        address stablecoin_,
        address owner_
    ) 
        initializer 
        external 
    {
        _groupDetails.id = id_;
        _groupDetails.amount = amount_;
        _groupDetails.members = members_;
        _groupDetails.currentMembers = 0;
        _groupDetails.createdAt = block.timestamp;
        _groupDetails.groupAddress = address(this);
        MANAGER_ADDRESS = manager_;
        STABLECOIN_ADDRESS = stablecoin_;
        owner = owner_;
    }

    function joinGroup() external {
        require(!isMember[msg.sender], "Already joined");
        require(_members.length < _groupDetails.members, "Group is full");
        require(groupStage == GroupStage.INITIALIZED, "Group started");

        address newMember = msg.sender;
        _members.push(newMember);
        isMember[newMember] = true;
        _groupDetails.currentMembers++;
        if (_members.length == _groupDetails.members) {
            groupStage = GroupStage.ONGOING;
            _groupDetails.startTime = block.timestamp;
            _groupDetails.currentRound = 1;
            roundStage[_groupDetails.currentRound] = RoundStage.COLLECTION;
            emit GroupStarted(block.timestamp);
            emit RoundStarted(_groupDetails.currentRound, block.timestamp);
        }
    }

    function contribute() external onlyMember {
        require(groupStage == GroupStage.ONGOING, "Group not ongoing");
        uint256 round = _groupDetails.currentRound;
        require(roundStage[round] == RoundStage.COLLECTION, "Not in collection stage");
        require(!_memberContributed[round][msg.sender], "Already contributed");
        
        address vault = MULTI_SIG_ADDRESS != address(0) ? MULTI_SIG_ADDRESS : owner;
        IERC20(STABLECOIN_ADDRESS).transferFrom(
            msg.sender,
            vault,
            _groupDetails.amount
        );
        _memberContributed[round][msg.sender] = true;
        if (allMembersContributed()) {
            roundStage[round] = RoundStage.BIDDING;
        }
    }

    function distribute(uint256 winningBid, address winner) external onlyMultiSigOrOwner {
        require(groupStage == GroupStage.ONGOING, "Group not ongoing");
        uint256 round = _groupDetails.currentRound;
        require(roundStage[round] == RoundStage.BIDDING, "Not in bidding stage");
        require(isMember[winner], "Not a member");
        require(!isWinner[winner], "Already won");
        require(winningBid > 0, "Bid cannot be zero");

        uint256 poolFund = _groupDetails.amount * _groupDetails.members;
        IERC20(STABLECOIN_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            poolFund
        );
        uint256 fee = (poolFund * PLATFORM_FEE) / 100;
        uint256 totalDividend = poolFund - fee - winningBid;

        if (totalDividend > 0) {
            uint256 dividend = totalDividend / (_groupDetails.members - 1);
            for (uint256 i = 0; i < _members.length; i++) {
                if (_members[i] != winner) {
                    unclaimedAmount[_members[i]] += dividend;
                } else {
                    unclaimedAmount[_members[i]] += winningBid;
                }
            }
        } else {
            unclaimedAmount[winner] += winningBid;
        }
        IERC20(STABLECOIN_ADDRESS).transferFrom(
            address(this),
            MANAGER_ADDRESS,
            fee
        );
        isWinner[winner] = true;
        roundStage[round] = RoundStage.ENDED;
        emit RoundEnded(round, block.timestamp);

        if (round != _groupDetails.members) {
            _groupDetails.currentRound++;
            roundStage[_groupDetails.currentRound] = RoundStage.COLLECTION;
            emit RoundStarted(_groupDetails.currentRound, block.timestamp);
        } else {
            groupStage = GroupStage.ENDED;
            _groupDetails.endTime = block.timestamp;
            emit GroupEnded(block.timestamp);
        }
    }

    function claim() external onlyMember {
        require(!isBlacklisted[msg.sender], "Blacklisted");
        require(unclaimedAmount[msg.sender] > 0, "Nothing to claim");
        IERC20(STABLECOIN_ADDRESS).transfer(
            msg.sender,
            unclaimedAmount[msg.sender]
        );
        unclaimedAmount[msg.sender] = 0;
    }

    function cancelGroup() external onlyOwner {
        require(
            groupStage != GroupStage.ENDED &&
            groupStage != GroupStage.CANCELLED,
            "Group already ended or cancelled"
        );
        groupStage = GroupStage.CANCELLED;
        _groupDetails.endTime = block.timestamp;
        emit GroupCancelled(block.timestamp);
    }

    function setMultiSigAddress(address multiSigAddress) external onlyOwner {
        MULTI_SIG_ADDRESS = multiSigAddress;
    }

    function setOracleAddress(address oracleAddress) external onlyOwner {
        oracle = oracleAddress;
    }

    function setMemberReputation(address member, uint256 score) external onlyOracle {
        if (score <= MIN_CREDIT_SCORE) {
            isBlacklisted[member] = true;
        }
    }

    function publishProof(uint256 round, bytes memory proof) external onlyMultiSigOrOwner {
        require(round <= _groupDetails.members, "Invalid round");
        require(roundStage[round] == RoundStage.ENDED, "Round not ended");
        require(proofs[round].length == 0, "Proof already published");
        proofs[round] = proof;
    }

    function getProof(uint256 round) public view returns (bytes memory) {
        return proofs[round];
    }

    function getGroupDetails() public view returns (GroupDetails memory) {
        return _groupDetails;
    }

    function getMembers() public view returns (address[] memory) {
        return _members;
    }

    function getCurrentRound() public view returns (uint256) {
        return _groupDetails.currentRound;
    }

    function getCurrentRoundStage() public view returns (RoundStage) {
        return roundStage[_groupDetails.currentRound];
    }

    function hasMemberContributed(address member) public view returns (bool) {
        return _memberContributed[_groupDetails.currentRound][member];
    }

    function allMembersContributed() public view returns (bool) {
        uint256 round = _groupDetails.currentRound;
        for (uint256 i = 0; i < _members.length; i++) {
            if (!_memberContributed[round][_members[i]]) {
                return false;
            }
        }
        return true;
    }

    function getNonPrizedMembers() public view returns (address[] memory) {
        uint256 nonPrizedMembersCount = 0;
        for (uint256 i = 0; i < _members.length; i++) {
            if (!isWinner[_members[i]]) {
                nonPrizedMembersCount++;
            }
        }

        address[] memory nonPrizedMembers = new address[](nonPrizedMembersCount);
        uint256 nonPrizedMembersIndex = 0;
        for (uint256 i = 0; i < _members.length; i++) {
            if (!isWinner[_members[i]]) {
                nonPrizedMembers[nonPrizedMembersIndex] = _members[i];
                nonPrizedMembersIndex++;
            }
        }
        return nonPrizedMembers;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}