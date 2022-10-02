// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@opengsn/contracts/src/BaseRelayRecipient.sol";


import "../interfaces/ICaskSubscriptionPlans.sol";

contract CaskSubscriptionPlans is
ICaskSubscriptionPlans,
BaseRelayRecipient,
OwnableUpgradeable,
PausableUpgradeable
{
    /** @dev Address of subscription manager. */
    address public subscriptionManager;

    /** @dev Map for provider to profile info. */
    mapping(address => Provider) internal providerProfiles;

    /** @dev Map for current plan status. */
    // provider->planId => Plan
    mapping(address => mapping(uint32 => PlanStatus)) internal planStatus;
    mapping(address => mapping(uint32 => uint32)) internal planEol;

    /** @dev Maps for discounts. */
    mapping(address => mapping(uint32 => mapping(bytes32 => uint256))) internal discountRedemptions;

    /** @dev Address of subscriptions contract. */
    address public subscriptions;

    modifier onlyManager() {
        require(_msgSender() == subscriptionManager, "!AUTH");
        _;
    }

    modifier onlySubscriptions() {
        require(_msgSender() == subscriptions, "!AUTH");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();

        subscriptions = address(0);
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function versionRecipient() public pure override returns(string memory) { return "2.2.0"; }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    function setProviderProfile(
        address _paymentAddress,
        string calldata _cid,
        uint256 _nonce
    ) external override {
        Provider storage profile = providerProfiles[_msgSender()];
        if (profile.nonce > 0) {
            require(_nonce > profile.nonce, "!NONCE");
        }
        profile.paymentAddress = _paymentAddress;
        profile.cid = _cid;
        profile.nonce = _nonce;

        emit ProviderSetProfile(_msgSender(), _paymentAddress, _nonce, _cid);
    }

    function getProviderProfile(
        address _provider
    ) external override view returns(Provider memory) {
        return providerProfiles[_provider];
    }

    function verifyPlan(
        bytes32 _planData,
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof
    ) external override pure returns(bool) {
        return MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encode(_planData)));
    }

    function getDiscountRedemptions(
        address _provider,
        uint32 _planId,
        bytes32 _discountId
    ) external view override returns(uint256) {
        return discountRedemptions[_provider][_planId][_discountId];
    }

    function verifyDiscount(
        address _consumer,
        address _provider,
        uint32 _planId,
        bytes32[] calldata _discountProof // [discountValidator, discountData, merkleRoot, merkleProof...]
    ) public view override returns(bytes32) {
        if (_discountProof.length < 3 || _discountProof[0] == 0) {
            return 0;
        }

        DiscountType discountType = _parseDiscountType(_discountProof[1]);

        if (discountType == DiscountType.Code) {
            return _verifyCodeDiscount(_provider, _planId, _discountProof);
        } else if (discountType == DiscountType.ERC20) {
            return _verifyErc20Discount(_consumer, _provider, _planId, _discountProof);
        } else {
            return 0;
        }
    }

    function verifyAndConsumeDiscount(
        address _consumer,
        address _provider,
        uint32 _planId,
        bytes32[] calldata _discountProof // [discountValidator, discountData, merkleRoot, merkleProof...]
    ) external override onlySubscriptions returns(bytes32) {
        bytes32 discountId = verifyDiscount(_consumer, _provider, _planId, _discountProof);
        if (discountId > 0) {
            Discount memory discountInfo = _parseDiscountData(_discountProof[1]);
            discountRedemptions[_provider][discountInfo.planId][discountId] += 1;
        }
        return discountId;
    }

    function _verifyCodeDiscount(
        address _provider,
        uint32 _planId,
        bytes32[] calldata _discountProof // [discountValidator, discountData, merkleRoot, merkleProof...]
    ) internal view returns(bytes32) {
        if (_discountProof.length < 3 || _discountProof[0] == 0) {
            return 0;
        }

        bytes32 discountId = keccak256(abi.encode(_discountProof[0]));

        if (_verifyDiscountProof(discountId, _discountProof) &&
            _verifyDiscountData(discountId, _provider, _planId, _discountProof[1]))
        {
            return discountId;
        }
        return 0;
    }

    function _verifyErc20Discount(
        address _consumer,
        address _provider,
        uint32 _planId,
        bytes32[] calldata _discountProof // [discountValidator, discountData, merkleRoot, merkleProof...]
    ) internal view returns(bytes32) {
        if (_discountProof.length < 3 || _discountProof[0] == 0) {
            return 0;
        }

        bytes32 discountId = _discountProof[0];

        if (_verifyDiscountProof(discountId, _discountProof) &&
            erc20DiscountCurrentlyApplies(_consumer, discountId) &&
            _verifyDiscountData(discountId, _provider, _planId, _discountProof[1]))
        {
            return discountId;
        }
        return 0;
    }

    function _verifyDiscountProof(
        bytes32 _discountId,
        bytes32[] calldata _discountProof // [discountValidator, discountData, merkleRoot, merkleProof...]
    ) internal pure returns(bool) {
        if (_discountProof.length < 3 || _discountProof[0] == 0) {
            return false;
        }

        // its possible to have an empty merkleProof if the merkleRoot IS the leaf
        bytes32[] memory merkleProof = new bytes32[](0);
        if (_discountProof.length >= 4) {
            merkleProof = _discountProof[3:];
        }

        return MerkleProof.verify(merkleProof, _discountProof[2],
            keccak256(abi.encode(_discountId, _discountProof[1])));
    }

    function _verifyDiscountData(
        bytes32 _discountId,
        address _provider,
        uint32 _planId,
        bytes32 _discountData
    ) internal view returns(bool) {
        Discount memory discountInfo = _parseDiscountData(_discountData);

        return
            (discountInfo.planId == 0 || discountInfo.planId == _planId) &&
            (discountInfo.maxRedemptions == 0 ||
                discountRedemptions[_provider][discountInfo.planId][_discountId] < discountInfo.maxRedemptions) &&
            (discountInfo.validAfter == 0 || discountInfo.validAfter <= uint32(block.timestamp)) &&
            (discountInfo.expiresAt == 0 || discountInfo.expiresAt > uint32(block.timestamp));
    }

    function erc20DiscountCurrentlyApplies(
        address _consumer,
        bytes32 _discountValidator
    ) public view override returns(bool) {
        address token = address(bytes20(_discountValidator));
        uint8 decimals = uint8(bytes1(_discountValidator << 160));

        if (decimals == 255) {
            try IERC20Metadata(token).decimals() returns (uint8 detectedDecimals) {
                decimals = detectedDecimals;
            } catch (bytes memory) {
                return false;
            }
        }

        try IERC20Metadata(token).balanceOf(_consumer) returns (uint256 balance) {
            if (decimals > 0) {
                balance = balance / uint256(10 ** decimals);
            }
            uint64 minBalance = uint64(bytes8(_discountValidator << 192));

            return balance >= minBalance;
        } catch (bytes memory) {
            return false;
        }
    }

    function getPlanStatus(
        address _provider,
        uint32 _planId
    ) external view returns (PlanStatus) {
        return planStatus[_provider][_planId];
    }

    function getPlanEOL(
        address _provider,
        uint32 _planId
    ) external view returns (uint32) {
        return planEol[_provider][_planId];
    }

    function disablePlan(
        uint32 _planId
    ) external override {
        require(planStatus[_msgSender()][_planId] == PlanStatus.Enabled, "!NOT_ENABLED");

        planStatus[_msgSender()][_planId] = PlanStatus.Disabled;

        emit PlanDisabled(_msgSender(), _planId);
    }

    function enablePlan(
        uint32 _planId
    ) external override {
        require(planStatus[_msgSender()][_planId] == PlanStatus.Disabled, "!NOT_DISABLED");

        planStatus[_msgSender()][_planId] = PlanStatus.Enabled;

        emit PlanEnabled(_msgSender(), _planId);
    }

    function retirePlan(
        uint32 _planId,
        uint32 _retireAt
    ) external override {
        planStatus[_msgSender()][_planId] = PlanStatus.EndOfLife;
        planEol[_msgSender()][_planId] = _retireAt;

        emit PlanRetired(_msgSender(), _planId, _retireAt);
    }

    function _parseDiscountType(
        bytes32 _discountData
    ) internal pure returns(DiscountType) {
        return DiscountType(uint8(bytes1(_discountData << 248)));
    }

    function _parseDiscountData(
        bytes32 _discountData
    ) internal pure returns(Discount memory) {
        bytes1 options = bytes1(_discountData << 240);
        return Discount({
        value: uint256(_discountData >> 160),
        validAfter: uint32(bytes4(_discountData << 96)),
        expiresAt: uint32(bytes4(_discountData << 128)),
        maxRedemptions: uint32(bytes4(_discountData << 160)),
        planId: uint32(bytes4(_discountData << 192)),
        applyPeriods: uint16(bytes2(_discountData << 224)),
        discountType: DiscountType(uint8(bytes1(_discountData << 248))),
        isFixed: options & 0x01 == 0x01
        });
    }


    /************************** ADMIN FUNCTIONS **************************/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setManager(
        address _subscriptionManager
    ) external onlyOwner {
        subscriptionManager = _subscriptionManager;
    }

    function setSubscriptions(
        address _subscriptions
    ) external onlyOwner {
        subscriptions = _subscriptions;
    }

    function setTrustedForwarder(
        address _forwarder
    ) external onlyOwner {
        _setTrustedForwarder(_forwarder);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskSubscriptionPlans {

    enum PlanStatus {
        Enabled,
        Disabled,
        EndOfLife
    }

    enum DiscountType {
        None,
        Code,
        ERC20
    }

    struct Discount {
        uint256 value;
        uint32 validAfter;
        uint32 expiresAt;
        uint32 maxRedemptions;
        uint32 planId;
        uint16 applyPeriods;
        DiscountType discountType;
        bool isFixed;
    }

    struct Provider {
        address paymentAddress;
        uint256 nonce;
        string cid;
    }

    function setProviderProfile(address _paymentAddress, string calldata _cid, uint256 _nonce) external;

    function getProviderProfile(address _provider) external view returns(Provider memory);

    function getPlanStatus(address _provider, uint32 _planId) external view returns (PlanStatus);

    function getPlanEOL(address _provider, uint32 _planId) external view returns (uint32);

    function disablePlan(uint32 _planId) external;

    function enablePlan(uint32 _planId) external;

    function retirePlan(uint32 _planId, uint32 _retireAt) external;

    function verifyPlan(bytes32 _planData, bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof) external view returns(bool);

    function getDiscountRedemptions(address _provider, uint32 _planId,
        bytes32 _discountId) external view returns(uint256);

    function verifyAndConsumeDiscount(address _consumer, address _provider, uint32 _planId,
        bytes32[] calldata _discountProof) external returns(bytes32);

    function verifyDiscount(address _consumer, address _provider, uint32 _planId,
        bytes32[] calldata _discountProof) external returns(bytes32);

    function erc20DiscountCurrentlyApplies(address _consumer, bytes32 _discountValidator) external returns(bool);


    /** @dev Emitted when `provider` sets their profile info */
    event ProviderSetProfile(address indexed provider, address indexed paymentAddress, uint256 nonce, string cid);

    /** @dev Emitted when `provider` disables a subscription plan */
    event PlanDisabled(address indexed provider, uint32 indexed planId);

    /** @dev Emitted when `provider` enables a subscription plan */
    event PlanEnabled(address indexed provider, uint32 indexed planId);

    /** @dev Emitted when `provider` end-of-lifes a subscription plan */
    event PlanRetired(address indexed provider, uint32 indexed planId, uint32 retireAt);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}