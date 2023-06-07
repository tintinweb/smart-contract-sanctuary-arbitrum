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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
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

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155Mintable is IERC1155Upgradeable {

    function mint(
        address _to,
        uint256 _itemId,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterOfInflation {
    function tryMintFromPool(
        MintFromPoolParams calldata _params
    ) external returns (bool _didMintItem);

    function itemRatePerSecond(uint64 _poolId) external view returns (uint256);
}

struct MintFromPoolParams {
    // Slot 1 (160/256)
    uint64 poolId;
    uint64 amount;
    // Extra odds (out of 100,000) of pulling the item. Will be multiplied against the base odds
    // (1 + bonus) * dynamicBaseOdds
    uint32 bonus;
    // Slot 2
    uint256 itemId;
    // Slot 3
    uint256 randomNumber;
    // Slot 4 (192/256)
    address user;
    uint32 negativeBonus;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolConfigProvider {
    // Returns the numerator in the dynamic rate formula.
    //
    function getN(uint64 _poolId) external view returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../external/IERC1155Mintable.sol";

import "./MasterOfInflationSettings.sol";

contract MasterOfInflation is Initializable, MasterOfInflationSettings {

    function initialize() external initializer {
        MasterOfInflationSettings.__MasterOfInflationSettings_init();
    }

    function tryMintFromPool(
        MintFromPoolParams calldata _params)
    external
    validPool(_params.poolId)
    onlyPoolAccessor(_params.poolId)
    returns(bool _didMintItem)
    {
        require(poolIdToItemIdToMintable[_params.poolId][_params.itemId], "Item not mintable");

        // 1. Calculate odds of getting the item
        uint256 _chanceOfItem = chanceOfItemFromPool(_params.poolId, _params.amount, _params.bonus, _params.negativeBonus);

        // 2. Roll dice
        if(_chanceOfItem > 0) {
            uint256 _rollResult = _params.randomNumber % 100000;
            if(_rollResult < _chanceOfItem) {
                _didMintItem = true;
            }
        }

        // 3. Mint if needed
        if(_didMintItem) {
            IERC1155Mintable(poolIdToInfo[_params.poolId].poolCollection).mint(
                _params.user,
                _params.itemId,
                _params.amount
            );

            poolIdToInfo[_params.poolId].itemsClaimed += (_params.amount * 1 ether);

            emit ItemMintedFromPool(
                _params.poolId,
                _params.user,
                _params.itemId,
                _params.amount);
        }
    }

    // Returns a number of 100,000 indicating the chance of pulling an item from this pool
    //
    function chanceOfItemFromPool(uint64 _poolId, uint64 _amount, uint32 _bonus, uint32 _negativeBonus) public view returns(uint256) {
        uint256 _itemsInPool = itemsInPool(_poolId);

        // Don't have enough to give this amount
        //
        if(_itemsInPool < _amount * 1 ether) {
            return 0;
        }

        IPoolConfigProvider _configProvider = IPoolConfigProvider(poolIdToInfo[_poolId].poolConfigProvider);

        uint256 _n = _configProvider.getN(_poolId);

        // Function is 1/(1 + (N/k * s)^2). Because solidity has no decimals, we need
        // to use `ether` to indicate decimals.

        uint256 _baseOdds = 10**25 / (10**20 + (((_n * 10**28) / _itemsInPool) * ((poolIdToInfo[_poolId].sModifier * 10**5) / 100000))**2);

        if(_bonus >= _negativeBonus) {
            return (_baseOdds * (1 ether + (10**13 * uint256(_bonus - _negativeBonus)))) / 1 ether;
        } else {
            require(_negativeBonus - _bonus <= 100000, "Negative bonus too high");
            return (_baseOdds * (1 ether - (10**13 * uint256(_negativeBonus - _bonus)))) / 1 ether;
        }
    }

    function chanceOfItemFromPools(ChanceOfItemFromPoolParams[] calldata _params) external view returns(uint256[] memory) {
        require(_params.length > 0, "Bad params length");

        uint256[] memory _chances = new uint256[](_params.length);

        for(uint256 i = 0; i < _params.length; i++) {
            _chances[i] = chanceOfItemFromPool(_params[i].poolId, _params[i].amount, _params[i].bonus, _params[i].negativeBonus);
        }

        return _chances;
    }

    function itemsInPool(uint64 _poolId) public view returns(uint256) {
        PoolInfo storage _poolInfo = poolIdToInfo[_poolId];

        return _poolInfo.totalItemsAtLastRateChange
            + _itemsSinceTime(_poolInfo.itemRatePerSecond, _poolInfo.timeRateLastChanged)
            - _poolInfo.itemsClaimed;
    }

    function hasAccessToPool(uint64 _poolId, address _address) external view returns(bool) {
        return poolIdToInfo[_poolId].addressToAccess[_address];
    }
}

struct ChanceOfItemFromPoolParams {
    uint64 poolId;
    uint64 amount;
    uint32 bonus;
    uint32 negativeBonus;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MasterOfInflationState.sol";

abstract contract MasterOfInflationContracts is Initializable, MasterOfInflationState {

    function __MasterOfInflationContracts_init() internal initializer {
        MasterOfInflationState.__MasterOfInflationState_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MasterOfInflationContracts.sol";

abstract contract MasterOfInflationSettings is Initializable, MasterOfInflationContracts {

    function __MasterOfInflationSettings_init() internal initializer {
        MasterOfInflationContracts.__MasterOfInflationContracts_init();
    }

    function createPool(
        CreatePoolParams calldata _params)
    external
    onlyAdminOrOwner {
        uint64 _poolId = poolId;
        poolId++;

        poolIdToInfo[_poolId].isEnabled = true;
        poolIdToInfo[_poolId].startTime = uint128(block.timestamp);
        poolIdToInfo[_poolId].timeRateLastChanged = poolIdToInfo[_poolId].startTime;
        poolIdToInfo[_poolId].poolCollection = _params.collection;
        poolIdToInfo[_poolId].totalItemsAtLastRateChange = _params.initialItemsInPool;

        emit PoolCreated(_poolId, _params.collection);

        _setItemRatePerSecond(_poolId, _params.itemRatePerSecond, false);
        _setSModifier(_poolId, _params.sModifier);
        _setAdmin(_poolId, _params.admin);
        _setConfigProvider(_poolId, _params.configProvider);
    }

    function setPoolAccess(
        uint64 _poolId,
        SetPoolAccessParams[] calldata _setPoolParams)
    external
    whenNotPaused
    onlyPoolAdmin(_poolId)
    {

        PoolInfo storage _poolInfo = poolIdToInfo[_poolId];

        for(uint256 i = 0; i < _setPoolParams.length; i++) {

            SetPoolAccessParams calldata _params = _setPoolParams[i];

            _poolInfo.addressToAccess[_params.user] = _params.canAccess;

            emit PoolAccessChanged(_poolId, _params.user, _params.canAccess);
        }
    }

    function setItemMintable(
        uint64 _poolId,
        uint256[] calldata _itemIds,
        bool[] calldata _mintables)
    external
    whenNotPaused
    onlyPoolAdmin(_poolId)
    {
        require(_itemIds.length == _mintables.length && _itemIds.length > 0, "Bad array lengths");

        for(uint256 i = 0; i < _itemIds.length; i++) {
            uint256 _itemId = _itemIds[i];
            bool _mintable = _mintables[i];
            poolIdToItemIdToMintable[_poolId][_itemId] = _mintable;

            emit PoolItemMintableChanged(_poolId, _itemId, _mintable);
        }
    }

    function disablePool(
        uint64 _poolId)
    external
    onlyPoolAdmin(_poolId)
    {
        poolIdToInfo[_poolId].isEnabled = false;

        emit PoolDisabled(_poolId);
    }

    function setItemRatePerSecond(
        uint64 _poolId,
        uint256 _itemRate)
    external
    onlyPoolAdmin(_poolId)
    {
        _setItemRatePerSecond(_poolId, _itemRate, true);
    }

    function _setItemRatePerSecond(
        uint64 _poolId,
        uint256 _itemRate,
        bool _updateLastChanged)
    private
    {
        uint256 _oldRate = poolIdToInfo[_poolId].itemRatePerSecond;

        if(_updateLastChanged) {
            uint256 _itemsSinceLastChange = _itemsSinceTime(_oldRate, poolIdToInfo[_poolId].timeRateLastChanged);

            poolIdToInfo[_poolId].totalItemsAtLastRateChange += _itemsSinceLastChange;
            poolIdToInfo[_poolId].timeRateLastChanged = uint128(block.timestamp);
        }

        poolIdToInfo[_poolId].itemRatePerSecond = _itemRate;

        emit PoolRateChanged(_poolId, _oldRate, _itemRate);
    }

    function setSModifier(
        uint64 _poolId,
        uint256 _sModifier)
    external
    onlyPoolAdmin(_poolId)
    {
        _setSModifier(_poolId, _sModifier);
    }

    function _setSModifier(uint64 _poolId, uint256 _sModifier) private {
        uint256 _oldSModifier = poolIdToInfo[_poolId].sModifier;
        poolIdToInfo[_poolId].sModifier = _sModifier;

        emit PoolSModifierChanged(_poolId, _oldSModifier, _sModifier);
    }

    function setAdmin(
        uint64 _poolId,
        address _admin)
    external
    onlyPoolAdmin(_poolId)
    {
        _setAdmin(_poolId, _admin);
    }

    function _setAdmin(uint64 _poolId, address _admin) private {
        require(_admin != address(0), "Cannot set admin to 0");
        address _oldAdmin = poolIdToInfo[_poolId].poolAdmin;
        poolIdToInfo[_poolId].poolAdmin = _admin;

        emit PoolAdminChanged(_poolId, _oldAdmin, _admin);
    }

    function setConfigProvider(
        uint64 _poolId,
        address _configProvider)
    external
    onlyPoolAdmin(_poolId)
    {
        _setConfigProvider(_poolId, _configProvider);
    }

    function _setConfigProvider(uint64 _poolId, address _configProvider) private {
        address _oldConfigProvider = poolIdToInfo[_poolId].poolConfigProvider;
        poolIdToInfo[_poolId].poolConfigProvider = _configProvider;

        emit PoolConfigProviderChanged(_poolId, _oldConfigProvider, _configProvider);
    }

    function configProvider(uint64 _poolId)
    external
    view
    validPool(_poolId)
    returns(address)
    {
        return poolIdToInfo[_poolId].poolConfigProvider;
    }

    function itemRatePerSecond(uint64 _poolId)
    external
    view
    validPool(_poolId)
    returns(uint256)
    {
        return poolIdToInfo[_poolId].itemRatePerSecond;
    }

    function _itemsSinceTime(
        uint256 _rate,
        uint128 _timestamp)
    internal
    view
    returns(uint256)
    {
        return ((block.timestamp - _timestamp) * _rate);
    }

    modifier onlyPoolAdmin(uint64 _poolId) {
        require(msg.sender == poolIdToInfo[_poolId].poolAdmin, "Not pool admin");

        _;
    }

    modifier validPool(uint64 _poolId) {
        require(poolIdToInfo[_poolId].isEnabled, "Pool is disabled or does not exist");

        _;
    }

    modifier onlyPoolAccessor(uint64 _poolId) {
        require(poolIdToInfo[_poolId].addressToAccess[msg.sender], "Cannot access pool");

        _;
    }
}

struct CreatePoolParams {
    // Slot 1
    uint256 itemRatePerSecond;
    // Slot 2
    // Should be in ether.
    uint256 initialItemsInPool;
    // Slot 3
    uint256 sModifier;
    // Slot 4 (160/256)
    address admin;
    // Slot 5 (160/256)
    address collection;
    // Slot 6 (160/256)
    address configProvider;
}

struct SetPoolAccessParams {
    // Slot 1 (168/256)
    address user;
    bool canAccess;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "./IMasterOfInflation.sol";
import "./IPoolConfigProvider.sol";

abstract contract MasterOfInflationState is Initializable, IMasterOfInflation, AdminableUpgradeable {

    event PoolCreated(uint64 poolId, address poolCollection);
    event PoolAdminChanged(uint64 poolId, address oldAdmin, address newAdmin);
    event PoolRateChanged(uint64 poolId, uint256 oldItemRate, uint256 newItemRate);
    event PoolAccessChanged(uint64 poolId, address accessor, bool canAccess);
    event PoolConfigProviderChanged(uint64 poolId, address oldProvider, address newProvider);
    event PoolSModifierChanged(uint64 poolId, uint256 oldModifier, uint256 newModifier);
    event PoolDisabled(uint64 poolId);
    event PoolItemMintableChanged(uint64 poolId, uint256 itemId, bool mintable);

    event ItemMintedFromPool(uint64 poolId, address user, uint256 itemId, uint64 amount);

    uint64 public poolId;

    mapping(uint64 => PoolInfo) public poolIdToInfo;
    mapping(uint64 => mapping(uint256 => bool)) public poolIdToItemIdToMintable;

    function __MasterOfInflationState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();

        poolId = 1;
    }
}

struct PoolInfo {
    // Slot 1 (168/256)
    // Indicates if this pool is enabled.
    bool isEnabled;
    // The owner of the pool. Typically EOA. Allowed to disable or change the rate.
    address poolAdmin;
    uint88 emptySpace1;

    // Slot 2
    // The time this pool was created.
    uint128 startTime;
    // The time the pool last changed.
    uint128 timeRateLastChanged;

    // Slot 3
    // The rate at which the pool is gaining items. The rate is in `ether` aka 10^18.
    uint256 itemRatePerSecond;

    // Slot 4
    // The number of items that are in the pool at the time of the last rate change. This is to preserve any accumulated items at the old rate.
    // Number is in `ether`.
    uint256 totalItemsAtLastRateChange;

    // Slot 5
    // The total number of items claimed from this pool. In `ether`.
    uint256 itemsClaimed;

    // Slot 6
    // Contains a mapping of address to whether the address can access/draw from this pool
    mapping(address => bool) addressToAccess;

    // Slot 7
    // A modifier that can be applied to the formula per pool.
    uint256 sModifier;

    // Slot 8 (160/256)
    // The 1155 collection that this pool gives items for.
    address poolCollection;
    uint96 emptySpace2;

    // Slot 9 (160/256)
    // The provider of the config. When dealing with dynamic rates, the N in the formula is defined
    // by the config provider.
    address poolConfigProvider;
    uint96 emptySpace3;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}