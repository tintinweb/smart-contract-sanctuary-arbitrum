// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

// Used for calculating decimal-point percentages (10000 = 100%)
uint256 constant PERCENTAGE_RANGE = 10000;

// Pauser Role - Can pause the game
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

// Minter Role - Can mint items, NFTs, and ERC20 currency
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

// Manager Role - Can manage the shop, loot tables, and other game data
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

// Game Logic Contract - Contract that executes game logic and accesses other systems
bytes32 constant GAME_LOGIC_CONTRACT_ROLE = keccak256(
    "GAME_LOGIC_CONTRACT_ROLE"
);

// Game Currency Contract - Allowlisted currency ERC20 contract
bytes32 constant GAME_CURRENCY_CONTRACT_ROLE = keccak256(
    "GAME_CURRENCY_CONTRACT_ROLE"
);

// Game NFT Contract - Allowlisted game NFT ERC721 contract
bytes32 constant GAME_NFT_CONTRACT_ROLE = keccak256("GAME_NFT_CONTRACT_ROLE");

// Game Items Contract - Allowlist game items ERC1155 contract
bytes32 constant GAME_ITEMS_CONTRACT_ROLE = keccak256(
    "GAME_ITEMS_CONTRACT_ROLE"
);

// Depositor role - used by Polygon bridge to mint on child chain
bytes32 constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

// Randomizer role - Used by the randomizer contract to callback
bytes32 constant RANDOMIZER_ROLE = keccak256("RANDOMIZER_ROLE");

// Trusted forwarder role - Used by meta transactions to verify trusted forwader(s)
bytes32 constant TRUSTED_FORWARDER_ROLE = keccak256("TRUSTED_FORWARDER_ROLE");

// =====
// All of the possible traits in the system
// =====

/// @dev Trait that points to another token/template id
uint256 constant TEMPLATE_ID_TRAIT_ID = uint256(keccak256("template_id"));

// Generation of a token
uint256 constant GENERATION_TRAIT_ID = uint256(keccak256("generation"));

// XP for a token
uint256 constant XP_TRAIT_ID = uint256(keccak256("xp"));

// Current level of a token
uint256 constant LEVEL_TRAIT_ID = uint256(keccak256("level"));

// Whether or not a token is a pirate
uint256 constant IS_PIRATE_TRAIT_ID = uint256(keccak256("is_pirate"));

// Whether or not a token is a ship
uint256 constant IS_SHIP_TRAIT_ID = uint256(keccak256("is_ship"));

// Whether or not an item is equippable on ships
uint256 constant EQUIPMENT_TYPE_TRAIT_ID = uint256(keccak256("equipment_type"));

// Combat modifiers for items and tokens
uint256 constant COMBAT_MODIFIERS_TRAIT_ID = uint256(
    keccak256("combat_modifiers")
);

// Animation URL for the token
uint256 constant ANIMATION_URL_TRAIT_ID = uint256(keccak256("animation_url"));

// Item slots
uint256 constant ITEM_SLOTS_TRAIT_ID = uint256(keccak256("item_slots"));

// Rank of the ship
uint256 constant SHIP_RANK_TRAIT_ID = uint256(keccak256("ship_rank"));

// Current Health trait
uint256 constant CURRENT_HEALTH_TRAIT_ID = uint256(keccak256("current_health"));

// Health trait
uint256 constant HEALTH_TRAIT_ID = uint256(keccak256("health"));

// Damage trait
uint256 constant DAMAGE_TRAIT_ID = uint256(keccak256("damage"));

// Speed trait
uint256 constant SPEED_TRAIT_ID = uint256(keccak256("speed"));

// Accuracy trait
uint256 constant ACCURACY_TRAIT_ID = uint256(keccak256("accuracy"));

// Evasion trait
uint256 constant EVASION_TRAIT_ID = uint256(keccak256("evasion"));

// Image hash of token's image, used for verifiable / fair drops
uint256 constant IMAGE_HASH_TRAIT_ID = uint256(keccak256("image_hash"));

// Name of a token
uint256 constant NAME_TRAIT_ID = uint256(keccak256("name_trait"));

// Description of a token
uint256 constant DESCRIPTION_TRAIT_ID = uint256(keccak256("description_trait"));

// General rarity for a token (corresponds to IGameRarity)
uint256 constant RARITY_TRAIT_ID = uint256(keccak256("rarity"));

// The character's affinity for a specific element
uint256 constant ELEMENTAL_AFFINITY_TRAIT_ID = uint256(
    keccak256("affinity_id")
);

// The character's expertise value
uint256 constant EXPERTISE_TRAIT_ID = uint256(keccak256("expertise_id"));

// Expertise damage mod ID from SoT
uint256 constant EXPERTISE_DAMAGE_ID = uint256(
    keccak256("expertise.levelmultiplier.damage")
);

// Expertise evasion mod ID from SoT
uint256 constant EXPERTISE_EVASION_ID = uint256(
    keccak256("expertise.levelmultiplier.evasion")
);

// Expertise speed mod ID from SoT
uint256 constant EXPERTISE_SPEED_ID = uint256(
    keccak256("expertise.levelmultiplier.speed")
);

// Expertise accuracy mod ID from SoT
uint256 constant EXPERTISE_ACCURACY_ID = uint256(
    keccak256("expertise.levelmultiplier.accuracy")
);

// Expertise health mod ID from SoT
uint256 constant EXPERTISE_HEALTH_ID = uint256(
    keccak256("expertise.levelmultiplier.health")
);

// Boss start time trait
uint256 constant BOSS_START_TIME_TRAIT_ID = uint256(
    keccak256("boss_start_time")
);

// Boss end time trait
uint256 constant BOSS_END_TIME_TRAIT_ID = uint256(keccak256("boss_end_time"));

// Boss type trait
uint256 constant BOSS_TYPE_TRAIT_ID = uint256(keccak256("boss_type"));

// The character's dice rolls
uint256 constant DICE_ROLL_1_TRAIT_ID = uint256(keccak256("dice_roll_1"));
uint256 constant DICE_ROLL_2_TRAIT_ID = uint256(keccak256("dice_roll_2"));

// The character's star sign (astrology)
uint256 constant STAR_SIGN_TRAIT_ID = uint256(keccak256("star_sign"));

// Image for the token
uint256 constant IMAGE_TRAIT_ID = uint256(keccak256("image_trait"));

// How much energy the token provides if used
uint256 constant ENERGY_PROVIDED_TRAIT_ID = uint256(
    keccak256("energy_provided")
);

// Whether a given token is soulbound, meaning it is unable to be transferred
uint256 constant SOULBOUND_TRAIT_ID = uint256(keccak256("soulbound"));

// ------
// Avatar Profile Picture related traits

// If an avatar is a 1 of 1, this is their only trait
uint256 constant PROFILE_IS_LEGENDARY_TRAIT_ID = uint256(
    keccak256("profile_is_legendary")
);

// Avatar's archetype -- possible values: Human (including Druid, Mage, Berserker, Crusty), Robot, Animal, Zombie, Vampire, Ghost
uint256 constant PROFILE_CHARACTER_TYPE = uint256(
    keccak256("profile_character_type")
);

// Avatar's profile picture's background image
uint256 constant PROFILE_BACKGROUND_TRAIT_ID = uint256(
    keccak256("profile_background")
);

// Avatar's eye style
uint256 constant PROFILE_EYES_TRAIT_ID = uint256(keccak256("profile_eyes"));

// Avatar's facial hair type
uint256 constant PROFILE_FACIAL_HAIR_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's hair style
uint256 constant PROFILE_HAIR_TRAIT_ID = uint256(keccak256("profile_hair"));

// Avatar's skin color
uint256 constant PROFILE_SKIN_TRAIT_ID = uint256(keccak256("profile_skin"));

// Avatar's coat color
uint256 constant PROFILE_COAT_TRAIT_ID = uint256(keccak256("profile_coat"));

// Avatar's earring(s) type
uint256 constant PROFILE_EARRING_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's eye covering
uint256 constant PROFILE_EYE_COVERING_TRAIT_ID = uint256(
    keccak256("profile_eye_covering")
);

// Avatar's headwear
uint256 constant PROFILE_HEADWEAR_TRAIT_ID = uint256(
    keccak256("profile_headwear")
);

// Avatar's (Mages only) gem color
uint256 constant PROFILE_MAGE_GEM_TRAIT_ID = uint256(
    keccak256("profile_mage_gem")
);

// ------
// Dungeon traits

// Whether this token template is a dungeon trigger
uint256 constant IS_DUNGEON_TRIGGER_TRAIT_ID = uint256(
    keccak256("is_dungeon_trigger")
);

// Dungeon start time trait
uint256 constant DUNGEON_START_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.start_time")
);

// Dungeon end time trait
uint256 constant DUNGEON_END_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.end_time")
);

// Dungeon SoT map id trait
uint256 constant DUNGEON_MAP_TRAIT_ID = uint256(keccak256("dungeon.map_id"));

// Whether this token template is a mob
uint256 constant IS_MOB_TRAIT_ID = uint256(keccak256("is_mob"));

// ------
// Island traits

// Whether a game item is placeable on an island
uint256 constant IS_PLACEABLE_TRAIT_ID = uint256(keccak256("is_placeable"));

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {PERCENTAGE_RANGE, TRUSTED_FORWARDER_ROLE} from "./Constants.sol";

import {ISystem} from "./core/ISystem.sol";
import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "./interfaces/ITraitsProvider.sol";
import {ILockingSystem, ID as LOCKING_SYSTEM_ID} from "./locking/ILockingSystem.sol";
import {IRandomizer, IRandomizerCallback, ID as RANDOMIZER_ID} from "./randomizer/IRandomizer.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "./loot/ILootSystem.sol";
import {IGameRegistry, IERC165} from "./core/IGameRegistry.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumerUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC2771Recipient,
    IRandomizerCallback,
    ISystem
{
    /// @notice Whether or not the contract is paused
    bool private _paused;

    /// @notice Reference to the game registry that this contract belongs to
    IGameRegistry internal _gameRegistry;

    /// @notice Id for the system/component
    uint256 private _id;

    /** EVENTS **/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    /// @notice Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /** ERRORS **/

    /// @notice Error if the game registry specified is invalid
    error InvalidGameRegistry();

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     * @param id                  Id of the system/component
     */
    function __GameRegistryConsumer_init(
        address gameRegistryAddress,
        uint256 id
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();

        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }

        _paused = true;
        _id = id;
    }

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Pause/Unpause the contract
     *
     * @param shouldPause Whether or pause or unpause
     */
    function setPaused(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns true if the contract OR the GameRegistry is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused || _gameRegistry.paused();
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override(IERC2771Recipient) returns (bool) {
        return
            address(_gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /** INTERNAL **/

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /** @return Returns the traits provider for this contract */
    function _traitsProvider() internal view returns (ITraitsProvider) {
        return ITraitsProvider(_getSystem(TRAITS_PROVIDER_ID));
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return ILockingSystem(_gameRegistry.getSystem(LOCKING_SYSTEM_ID));
    }

    /** @return Interface to the LootSystem */
    function _lootSystem() internal view returns (ILootSystem) {
        return ILootSystem(_gameRegistry.getSystem(LOOT_SYSTEM_ID));
    }

    /** @return Interface to the Randomizer */
    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(_gameRegistry.getSystem(RANDOMIZER_ID));
    }

    /** @return Address for a given system */
    function _getSystem(uint256 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _randomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /** PAUSABLE **/

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        require(_paused == false, "Pausable: not paused");
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
    function _unpause() internal virtual {
        require(_paused == true, "Pausable: not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// @title Interface the game's ACL / Management Layer
interface IGameRegistry is IERC165 {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasAccessRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /** @return Whether or not the registry is paused */
    function paused() external view returns (bool);

    /**
     * Registers a system by id
     *
     * @param systemId          Id of the system
     * @param systemAddress     Address of the system contract
     */
    function registerSystem(uint256 systemId, address systemAddress) external;

    /** @return System based on an id */
    function getSystem(uint256 systemId) external view returns (address);

    /**
     * Registers a component using an id and contract address
     * @param componentId Id of the component to register
     * @param componentAddress Address of the component contract
     */
    function registerComponent(
        uint256 componentId,
        address componentAddress
    ) external;

    /** @return A component's contract address given its ID */
    function getComponent(uint256 componentId) external view returns (address);

    /** @return A component's id given its contract address */
    function getComponentIdFromAddress(
        address componentAddr
    ) external view returns (uint256);

    /**
     * Register a component value update.
     * Emits the `ComponentValueSet` event for clients to reconstruct the state.
     */
    function registerComponentValueSet(
        uint256 entity,
        bytes calldata data
    ) external;

    /**
     * Register a component batch value update.
     * Emits the `ComponentBatchValuesSet` event for clients to reconstruct the state.
     */
    function batchRegisterComponentValueSet(
        uint256[] calldata entities,
        bytes[] calldata data
    ) external;

    /**
     * Register a component value removal.
     * Emits the `ComponentValueRemoved` event for clients to reconstruct the state.
     */
    function registerComponentValueRemoved(uint256 entity) external;

    /**
     * Register a component batch value removal.
     * Emits the `ComponentBatchValuesRemoved` event for clients to reconstruct the state.
     */
    function batchRegisterComponentValueRemoved(
        uint256[] calldata entities
    ) external;

    /**
     * Generate a new general-purpose entity GUID
     */
    function generateGUID() external returns (uint256);

    /** @return Authorized Player account for an address
     * @param operatorAddress   Address of the Operator account
     */
    function getPlayerAccount(
        address operatorAddress
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Defines a system the game engine
 */
interface ISystem {
    /** @return The ID for the system. Ex: a uint256 casted keccak256 hash */
    function getId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.traitsprovider"));

// Enum describing how the trait can be modified
enum TraitBehavior {
    NOT_INITIALIZED, // Trait has not been initialized
    UNRESTRICTED, // Trait can be changed unrestricted
    IMMUTABLE, // Trait can only be set once and then never changed
    INCREMENT_ONLY, // Trait can only be incremented
    DECREMENT_ONLY // Trait can only be decremented
}

// Type of data to allow in the trait
enum TraitDataType {
    NOT_INITIALIZED, // Trait has not been initialized
    INT, // int256 data type
    UINT, // uint256 data type
    BOOL, // bool data type
    STRING, // string data type
    INT_ARRAY, // int256 array data type
    UINT_ARRAY // uint256 array data type
}

// Holds metadata for a given trait type
struct TraitMetadata {
    // Name of the trait, used in tokenURIs
    string name;
    // How the trait can be modified
    TraitBehavior behavior;
    // Trait type
    TraitDataType dataType;
    // Whether or not the trait is a top-level property and should not be in the attribute array
    bool isTopLevelProperty;
    // Whether or not the trait should be hidden from end-users
    bool hidden;
}

// Used to pass traits around for URI generation
struct TokenURITrait {
    string name;
    bytes value;
    TraitDataType dataType;
    bool isTopLevelProperty;
    bool hidden;
}

/** @title Provides a set of traits to a set of ERC721/ERC1155 contracts */
interface ITraitsProvider is IERC165 {
    /**
     * Sets the value for the string trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        string calldata value
    ) external;

    /**
     * Sets several string traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitString(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the uint256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 value
    ) external;

    /**
     * Sets several uint256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitUint256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        uint256[] calldata values
    ) external;

    /**
     * Sets the value for the int256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256 value
    ) external;

    /**
     * Sets several int256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitInt256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        int256[] calldata values
    ) external;

    /**
     * Sets the value for the int256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256[] calldata value
    ) external;

    /**
     * Sets the value for the uint256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256[] calldata value
    ) external;

    /**
     * Sets the value for the bool trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        bool value
    ) external;

    /**
     * Sets several bool traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitBool(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        bool[] calldata values
    ) external;

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Returns the trait data for a given token
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     *
     * @return A struct containing all traits for the token
     */
    function getTraitIds(
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a raw abi-encoded byte data for the given trait
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBytes(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bytes memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256);

    /**
     * Retrieves a int256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256[] memory);

    /**
     * Retrieves a uint256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256);

    /**
     * Retrieves a uint256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a bool trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * @param traitId  Id of the trait to get metadata for
     * @return Metadata for the given trait
     */
    function getTraitMetadata(
        uint256 traitId
    ) external view returns (TraitMetadata memory);

    /**
     * Generate a tokenURI based on a set of global properties and traits
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lockingsystem"));

/// @title Interface for the LockingSystem that allows tokens to be locked by the game to prevent transfer
interface ILockingSystem is IERC165 {
    /**
     * Whether or not an NFT is locked
     *
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     */
    function isNFTLocked(address tokenContract, uint256 tokenId)
        external
        view
        returns (bool);

    /**
     * Amount of token locked in the system by a given owner
     *
     * @param account   	  Token owner
     * @param tokenContract	Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountLocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Amount of tokens available for unlock
     *
     * @param account       Token owner
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountUnlocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Whether or not the given items can be transferred
     *
     * @param account   	    Token owner
     * @param tokenContract	    Token contract address
     * @param ids               Ids of the tokens
     * @param amounts           Amounts of the tokens
     *
     * @return Whether or not the given items can be transferred
     */
    function canTransferItems(
        address account,
        address tokenContract,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external view returns (bool);

    /**
     * Lets the game add a reservation to a given NFT, this prevents the NFT from being unlocked
     *
     * @param tokenContract   Token contract address
     * @param tokenId         Token id to reserve
     * @param exclusive       Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addNFTReservation(
        address tokenContract,
        uint256 tokenId,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param tokenContract Token contract
     * @param tokenId       Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeNFTReservation(
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;

    /**
     * Lets the game add a reservation to a given token, this prevents the token from being unlocked
     *
     * @param account  			    Owner of the token to reserver
     * @param tokenContract   Token contract address
     * @param tokenId  				Token id to reserve
     * @param amount 					Number of tokens to reserve (1 for NFTs, >=1 for ERC1155)
     * @param exclusive				Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint256 amount,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param account   			Owner to remove reservation from
     * @param tokenContract	Token contract
     * @param tokenId  			Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lootsystem"));

/// @title Interface for the LootSystem that gives player loot (tokens, XP, etc) for playing the game
interface ILootSystem is IERC165 {
    // Type of loot
    enum LootType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155,
        LOOT_TABLE,
        CALLBACK
    }

    // Individual loot to grant
    struct Loot {
        // Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
        LootType lootType;
        // Contract to grant tokens from
        address tokenContract;
        // Id of the token to grant (ERC1155/LOOT TABLE/CALLBACK types only)
        uint256 lootId;
        // Amount of token to grant (XP, ERC20, ERC1155)
        uint256 amount;
    }

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     */
    function grantLoot(address to, Loot[] calldata loots) external;

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param randomWord  Optional random word to skip VRF callback if we already have words generated / are in a VRF callback
     */
    function grantLootWithRandomWord(
        address to,
        Loot[] calldata loots,
        uint256 randomWord
    ) external;

    /**
     * Grants the given user loot(s) in batches. Presumes no randomness or loot tables
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param amount      Amount of each loot to grant
     */
    function batchGrantLootWithoutRandomness(
        address to,
        Loot[] calldata loots,
        uint8 amount
    ) external;

    /**
     * Validate that loots are properly formed. Reverts if the loots are not valid
     *
     * @param loots Loots to validate
     * @return needsVRF Whether or not the loots specified require VRF to generate
     */
    function validateLoots(
        Loot[] calldata loots
    ) external view returns (bool needsVRF);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRandomizerCallback} from "./IRandomizerCallback.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.randomizer"));

interface IRandomizer is IERC165 {
    /**
     * Starts a VRF random number request
     *
     * @param callbackAddress Address to callback with the random numbers
     * @param numWords        Number of words to request from VRF
     *
     * @return requestId for the random number, will be passed to the callback contract
     */
    function requestRandomWords(
        IRandomizerCallback callbackAddress,
        uint32 numWords
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRandomizerCallback {
    /**
     * Callback for when the Chainlink request returns
     *
     * @param requestId     Id of the random word request
     * @param randomWords   Random words that were generated by the VRF
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IERC721BeforeTokenTransferHandler {
    /**
     * Before transfer hook for NFTs. Performs any trait checks needed before transfer
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     * @param from              From address
     * @param to                To address
     * @param operator          Operator address
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

import {IERC721BeforeTokenTransferHandler} from "../IERC721BeforeTokenTransferHandler.sol";
import {GameRegistryConsumerUpgradeable, ILockingSystem, ITraitsProvider} from "../../GameRegistryConsumerUpgradeable.sol";
import {SOULBOUND_TRAIT_ID} from "../../Constants.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.gamenftbeforetokentransferhandler")
);

contract GameNFTBeforeTokenTransferHandler is
    GameRegistryConsumerUpgradeable,
    IERC721BeforeTokenTransferHandler
{
    /** ERRORS **/

    /// @notice Token is locked and cannot be transferred
    error IsLocked();

    /// @notice Token type is soulbound to current owner and cannot be transfered
    error TokenIsSoulbound();

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /** EXTERNAL **/

    /**
     * Before transfer hook for NFTs. Performs any trait checks needed before transfer
     *
     * @param tokenContract     Address of the token contract
     * @param firstTokenId      Id of the token to generate traits for
     * @param from              From address
     * @param batchSize         Size of the batch transfer
     */
    function beforeTokenTransfer(
        address tokenContract,
        address, // operator
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) external view {
        // Locked check if not minting
        if (from != address(0)) {
            ILockingSystem lockingSystem = _lockingSystem();
            for (uint256 idx = 0; idx < batchSize; idx++) {
                if (
                    lockingSystem.isNFTLocked(
                        tokenContract,
                        firstTokenId + idx
                    ) == true
                ) {
                    revert IsLocked();
                }
            }

            // Soulbound check if not minting
            // Can burn soulbound items
            if (to != address(0)) {
                ITraitsProvider traitsProvider = _traitsProvider();
                for (uint256 idx = 0; idx < batchSize; idx++) {
                    uint256 tokenId = firstTokenId + idx;
                    if (
                        traitsProvider.hasTrait(
                            tokenContract,
                            tokenId,
                            SOULBOUND_TRAIT_ID
                        ) &&
                        traitsProvider.getTraitBool(
                            tokenContract,
                            tokenId,
                            SOULBOUND_TRAIT_ID
                        ) ==
                        true
                    ) {
                        revert TokenIsSoulbound();
                    }
                }
            }
        }
    }
}