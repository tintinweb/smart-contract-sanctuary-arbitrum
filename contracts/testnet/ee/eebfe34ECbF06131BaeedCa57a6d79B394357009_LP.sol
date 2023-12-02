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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IOwnable.sol";

interface IAccess is IOwnable {
    struct RoleData {
        address target; // target contract address
        bytes4 selector; // target function selector
        uint8 roleId; // ID of the role associated with contract-function combination
    }

    event RoleAdded(bytes32 indexed role, uint256 indexed roleId);
    event RoleRenamed(bytes32 indexed role, uint8 indexed roleId);
    event RoleBound(bytes32 indexed funcId, uint8 indexed roleId);
    event RoleUnbound(bytes32 indexed funcId, uint8 indexed roleId);
    event RoleGranted(address indexed user, uint8 indexed roleId);
    event RoleRevoked(address indexed user, uint8 indexed roleId);

    error NotTokenOwner();
    error MaxRolesReached();
    error AccessNotGranted();
    error RoleAlreadyGranted();

    function initialize() external;

    function checkAccess(
        address sender,
        address _contract,
        bytes4 selector
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IBet {
    struct BetData {
        address affiliate; // address indicated as an affiliate when placing bet
        uint64 minOdds;
        bytes data; // core-specific customized bet data
    }

    error BetNotExists();
    error SmallOdds();

    /**
     * @notice Register new bet.
     * @param  bettor wallet for emitting bet token
     * @param  amount amount of tokens to bet
     * @param  betData customized bet data
     */
    function putBet(
        address bettor,
        uint128 amount,
        BetData calldata betData
    ) external returns (uint256 tokenId);

    function resolvePayout(
        uint256 tokenId
    ) external returns (address account, uint128 payout);

    function viewPayout(uint256 tokenId) external view returns (uint128 payout);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ILiquidityManager {
    /**
     * @notice The hook that is called after the withdrawal of liquidity.
     * @param  depositId The ID of the liquidity deposit.
     * @param  balance The remaining balance of the liquidity deposit.
     */
    function afterWithdrawLiquidity(uint48 depositId, uint128 balance) external;

    /**
     * @notice The hook that is called before adding liquidity.
     * @param  account The address of the liquidity provider.
     * @param  depositId The ID of the liquidity deposit.
     * @param  balance The amount of the liquidity deposit.
     * @param  data The additional data to process.
     */
    function beforeAddLiquidity(
        address account,
        uint48 depositId,
        uint128 balance,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ILiquidityTree {
    function nodeWithdrawView(
        uint48 leaf
    ) external view returns (uint128 withdrawAmount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface ILP is IOwnable {
    enum FeeType {
        DAO,
        DATA_PROVIDER,
        AFFILIATES
    }

    enum CoreState {
        UNKNOWN,
        ACTIVE,
        INACTIVE
    }

    struct Condition {
        address core;
        uint256 conditionId;
    }

    struct CoreData {
        CoreState state;
        uint64 reinforcementAbility;
        uint128 minBet;
        uint128 lockedLiquidity;
    }

    struct Game {
        bytes32 unusedVariable;
        uint128 lockedLiquidity;
        uint64 startsAt;
        bool canceled;
    }

    struct Reward {
        int128 amount;
        uint64 claimedAt;
    }

    event CoreSettingsUpdated(
        address indexed core,
        CoreState state,
        uint64 reinforcementAbility,
        uint128 minBet
    );

    event AffiliateChanged(address newAffilaite);
    event BettorWin(
        address indexed core,
        address indexed bettor,
        uint256 tokenId,
        uint256 amount
    );
    event ClaimTimeoutChanged(uint64 newClaimTimeout);
    event DataProviderChanged(address newDataProvider);
    event FeeChanged(FeeType feeType, uint64 fee);
    event GameCanceled(uint256 indexed gameId);
    event GameShifted(uint256 indexed gameId, uint64 newStart);
    event LiquidityAdded(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityDonated(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityManagerChanged(address newLiquidityManager);
    event LiquidityRemoved(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event MinDepoChanged(uint128 newMinDepo);
    event NewGame(uint256 indexed gameId, uint64 startsAt, bytes data);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);

    error OnlyFactory();

    error SmallDepo();

    error BetExpired();
    error CoreNotActive();
    error ClaimTimeout(uint64 waitTime);
    error GameAlreadyCanceled();
    error GameAlreadyCreated();
    error GameCanceled_();
    error GameNotExists();
    error IncorrectCoreState();
    error IncorrectDonation();
    error IncorrectFee();
    error IncorrectGameId();
    error IncorrectMinBet();
    error IncorrectMinDepo();
    error IncorrectReinforcementAbility();
    error IncorrectTimestamp();
    error LiquidityNotOwned();
    error LockedLiquidityLimitReached();
    error SmallBet();
    error UnknownCore();
    error WithdrawalTimeout(uint64 waitTime);

    function initialize(
        address access,
        address vault,
        address dataProvider,
        address affiliate,
        uint128 minDepo,
        uint64 daoFee,
        uint64 dataProviderFee,
        uint64 affiliateFee
    ) external;

    function addCore(address core) external;

    function addDeposit(
        uint128 amount,
        bytes calldata data
    ) external returns (uint48);

    function addDepositFor(
        address account,
        uint128 amount,
        bytes calldata data
    ) external returns (uint48);

    function withdrawDeposit(
        uint48 depositId,
        uint40 percent
    ) external returns (uint128);

    function viewPayout(
        address core,
        uint256 tokenId
    ) external view returns (uint128 payout);

    function betFor(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    /**
     * @notice Make new bet.
     * @notice Emits bet token to `msg.sender`.
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function bet(
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    function changeDataProvider(address newDataProvider) external;

    function claimReward() external returns (uint128);

    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 profitReserve,
        uint48 depositId
    ) external;

    function addCondition(uint256 gameId) external view returns (uint64);

    function withdrawPayout(
        address core,
        uint256 tokenId
    ) external returns (uint128);

    function changeLockedLiquidity(
        uint256 gameId,
        int128 deltaReserve
    ) external;

    /**
     * @notice Indicate the game `gameId` as canceled.
     * @param  gameId the game ID
     */
    function cancelGame(uint256 gameId) external;

    /**
     * @notice Create new game.
     * @param  gameId the match or condition ID according to oracle's internal numbering
     * @param  startsAt timestamp when the game starts
     * @param  data the additional data to emit in the `NewGame` event
     */
    function createGame(
        uint256 gameId,
        uint64 startsAt,
        bytes calldata data
    ) external;

    /**
     * @notice Set `startsAt` as new game `gameId` start time.
     * @param  gameId the game ID
     * @param  startsAt new timestamp when the game starts
     */
    function shiftGame(uint256 gameId, uint64 startsAt) external;

    function getGameInfo(
        uint256 gameId
    ) external view returns (uint64 startsAt, bool canceled);

    function getLockedLiquidityLimit(
        address core
    ) external view returns (uint128);

    function isGameCanceled(
        uint256 gameId
    ) external view returns (bool canceled);

    function checkAccess(
        address account,
        address target,
        bytes4 selector
    ) external;

    function checkCore(address core) external view;

    function getLastDepositId() external view returns (uint48 depositId);

    function isDepositExists(uint256 depositId) external view returns (bool);

    function token() external view returns (address);

    function fees(uint256) external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function checkOwner(address account) external view;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./ILiquidityTree.sol";
import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 * @title Azuro Liquidity Vault Interface
 */
interface IVault is ILiquidityTree, IOwnable, IERC721EnumerableUpgradeable {
    event AdminChanged(address newAdmin);

    error DepositDoesNotExist();
    error IncorrectDeposit();
    error LiquidityIsLocked();
    error NotEnoughLiquidity();
    error NotEnoughLockedLiquidity();
    error OnlyAdmin();

    function initialize(address token_) external;

    function changeAdmin(address newAdmin) external;

    function addDeposit(
        address depositor,
        uint128 amount
    ) external returns (uint48);

    function addLiquidity(uint128 amount, uint48 depositId) external;

    function lockLiquidity(uint128 amount) external;

    function unlockLiquidity(uint128 amount) external;

    function withdrawDeposit(
        uint48 depositId,
        uint40 percent
    ) external returns (uint128 withdrawnAmount);

    function withdrawLiquidity(uint128 amount, uint48 depositId) external;

    function getReserve() external view returns (uint128);

    function getLastDepositId() external view returns (uint48 depositId);

    function isDepositExists(uint256 depositId) external view returns (bool);

    function token() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Fixed-point math tools
library FixedMath {
    uint256 constant ONE = 1e12;

    /**
     * @notice Get the ratio of `self` and `other` that is larger than 'ONE'.
     */
    function ratio(
        uint256 self,
        uint256 other
    ) internal pure returns (uint256) {
        return self > other ? div(self, other) : div(other, self);
    }

    function mul(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * other) / ONE;
    }

    function div(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * ONE) / other;
    }

    /**
     * @notice Implementation of the sigmoid function.
     * @notice The sigmoid function is commonly used in machine learning to limit output values within a range of 0 to 1.
     */
    function sigmoid(uint256 self) internal pure returns (uint256) {
        return (self * ONE) / (self + ONE);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library SafeCast {
    enum Type {
        BYTES32,
        INT128,
        UINT64,
        UINT128
    }
    error SafeCastError(Type to);

    function toBytes32(string calldata value) internal pure returns (bytes32) {
        bytes memory value_ = bytes(value);
        if (value_.length > 32) revert SafeCastError(Type.BYTES32);
        return bytes32(value_);
    }

    function toInt128(uint128 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max))
            revert SafeCastError(Type.INT128);
        return int128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert SafeCastError(Type.UINT64);
        return uint64(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert SafeCastError(Type.UINT128);
        return uint128(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./interface/IAccess.sol";
import "./interface/ILP.sol";
import "./interface/IOwnable.sol";
import "./interface/IBet.sol";
import "./interface/ILiquidityManager.sol";
import "./interface/IVault.sol";
import "./libraries/FixedMath.sol";
import "./libraries/SafeCast.sol";
import "./utils/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/// @title Azuro Liquidity Pool managing
contract LP is OwnableUpgradeable, ILP {
    using FixedMath for *;
    using SafeCast for uint256;
    using SafeCast for uint128;

    IOwnable public factory;
    IAccess public access;
    IVault public vault;

    address public token;
    address public dataProvider;

    uint128 public minDepo; // Minimum amount of liquidity deposit

    uint64 public claimTimeout; // Withdraw reward timeout
    uint64 public withdrawTimeout; // Deposit-withdraw liquidity timeout

    mapping(address => CoreData) public cores;

    mapping(uint256 => Game) public games;

    uint64[3] public fees;

    mapping(address => Reward) public rewards;
    // withdrawAfter[depositId] = timestamp indicating when the liquidity deposit withdrawal will be available.
    mapping(uint48 => uint64) public withdrawAfter;

    ILiquidityManager public liquidityManager;

    address public affiliate;

    /**
     * @notice Check if Core `core` belongs to this Liquidity Pool and is active.
     */
    modifier isActive(address core) {
        _checkCoreActive(core);
        _;
    }

    /**
     * @notice Check if Core `core` belongs to this Liquidity Pool.
     */
    modifier isCore(address core) {
        checkCore(core);
        _;
    }

    /**
     * @notice Throw if caller is not the Pool Factory.
     */
    modifier onlyFactory() {
        if (msg.sender != address(factory)) revert OnlyFactory();
        _;
    }

    /**
     * @notice Throw if caller have no access to function with selector `selector`.
     */
    modifier restricted(bytes4 selector) {
        checkAccess(msg.sender, address(this), selector);
        _;
    }

    receive() external payable {
        revert("This contract does not accept payments");
    }

    function initialize(
        address access_,
        address vault_,
        address dataProvider_,
        address affiliate_,
        uint128 minDepo_,
        uint64 daoFee,
        uint64 dataProviderFee,
        uint64 affiliateFee
    ) external virtual override initializer {
        if (minDepo_ == 0) revert IncorrectMinDepo();

        __Ownable_init();
        factory = IOwnable(msg.sender);
        access = IAccess(access_);
        vault = IVault(vault_);
        dataProvider = dataProvider_;
        affiliate = affiliate_;
        minDepo = minDepo_;
        fees[0] = daoFee;
        fees[1] = dataProviderFee;
        fees[2] = affiliateFee;

        address token_ = IVault(vault_).token();
        token = token_;
        // Max approve Vault spending
        TransferHelper.safeApprove(token_, vault_, type(uint256).max);

        _checkFee();
    }

    /**
     * @notice Owner: Set `newAffiliate` as Affiliate.
     */
    function changeAffiliate(address newAffiliate) external onlyOwner {
        affiliate = newAffiliate;
        emit AffiliateChanged(newAffiliate);
    }

    /**
     * @notice Owner: Set `newClaimTimeout` as claim timeout.
     */
    function changeClaimTimeout(uint64 newClaimTimeout) external onlyOwner {
        claimTimeout = newClaimTimeout;
        emit ClaimTimeoutChanged(newClaimTimeout);
    }

    /**
     * @notice Owner: Set `newDataProvider` as Data Provider.
     */
    function changeDataProvider(address newDataProvider) external onlyOwner {
        dataProvider = newDataProvider;
        emit DataProviderChanged(newDataProvider);
    }

    /**
     * @notice Owner: Set `newFee` as type `feeType` fee.
     * @param  newFee fee share where `FixedMath.ONE` is 100% of the Liquidity Pool profit
     */
    function changeFee(FeeType feeType, uint64 newFee) external onlyOwner {
        fees[uint256(feeType)] = newFee;
        _checkFee();
        emit FeeChanged(feeType, newFee);
    }

    /**
     * @notice Owner: Set `newLiquidityManager` as liquidity manager contract address.
     */
    function changeLiquidityManager(
        address newLiquidityManager
    ) external onlyOwner {
        liquidityManager = ILiquidityManager(newLiquidityManager);
        emit LiquidityManagerChanged(newLiquidityManager);
    }

    /**
     * @notice Owner: Set `newMinDepo` as minimum liquidity deposit.
     */
    function changeMinDepo(uint128 newMinDepo) external onlyOwner {
        if (newMinDepo == 0) revert IncorrectMinDepo();
        minDepo = newMinDepo;
        emit MinDepoChanged(newMinDepo);
    }

    /**
     * @notice Owner: Set `withdrawTimeout` as liquidity deposit withdrawal timeout.
     */
    function changeWithdrawTimeout(
        uint64 newWithdrawTimeout
    ) external onlyOwner {
        withdrawTimeout = newWithdrawTimeout;
        emit WithdrawTimeoutChanged(newWithdrawTimeout);
    }

    /**
     * @notice Owner: Update Core `core` settings.
     */
    function updateCoreSettings(
        address core,
        CoreState state,
        uint64 reinforcementAbility,
        uint128 minBet
    ) external onlyOwner isCore(core) {
        if (minBet == 0) revert IncorrectMinBet();
        if (reinforcementAbility > FixedMath.ONE)
            revert IncorrectReinforcementAbility();
        if (state == CoreState.UNKNOWN) revert IncorrectCoreState();

        CoreData storage coreData = cores[core];
        coreData.minBet = minBet;
        coreData.reinforcementAbility = reinforcementAbility;
        coreData.state = state;

        emit CoreSettingsUpdated(core, state, reinforcementAbility, minBet);
    }

    /**
     * @notice See {ILP-cancelGame}.
     */
    function cancelGame(
        uint256 gameId
    ) external restricted(this.cancelGame.selector) {
        Game storage game = _getGame(gameId);
        if (game.canceled) revert GameAlreadyCanceled();

        vault.unlockLiquidity(game.lockedLiquidity);
        game.canceled = true;
        emit GameCanceled(gameId);
    }

    /**
     * @notice See {ILP-createGame}.
     */
    function createGame(
        uint256 gameId,
        uint64 startsAt,
        bytes calldata data
    ) external restricted(this.createGame.selector) {
        Game storage game = games[gameId];
        if (game.startsAt > 0) revert GameAlreadyCreated();
        if (gameId == 0) revert IncorrectGameId();
        if (startsAt < block.timestamp) revert IncorrectTimestamp();

        game.startsAt = startsAt;

        emit NewGame(gameId, startsAt, data);
    }

    /**
     * @notice See {ILP-shiftGame}.
     */
    function shiftGame(
        uint256 gameId,
        uint64 startsAt
    ) external restricted(this.shiftGame.selector) {
        if (startsAt == 0) revert IncorrectTimestamp();
        _getGame(gameId).startsAt = startsAt;
        emit GameShifted(gameId, startsAt);
    }

    /**
     * @notice Deposit liquidity in the Liquidity Pool.
     * @notice Emits deposit token to `msg.sender`.
     * @param  amount The token's amount to deposit.
     * @param  data The additional data for processing in the Liquidity Manager contract.
     * @return depositId The deposit ID.
     */
    function addDeposit(
        uint128 amount,
        bytes calldata data
    ) external returns (uint48 depositId) {
        return _addDeposit(msg.sender, amount, data);
    }

    /**
     * @notice Deposit liquidity in the Liquidity Pool for another account balance.
     * @notice Emits deposit token to `msg.sender`.
     * @param  account The account that will become the owner of the deposit.
     * @param  amount The token's amount to deposit.
     * @param  data The additional data for processing in the Liquidity Manager contract.
     * @return depositId The deposit ID.
     */
    function addDepositFor(
        address account,
        uint128 amount,
        bytes calldata data
    ) external returns (uint48 depositId) {
        return _addDeposit(account, amount, data);
    }

    /**
     * @notice Donate and share liquidity between liquidity deposits.
     * @param  amount The amount of liquidity to share between deposits.
     * @param  depositId The ID of the last deposit that shares the donation.
     */
    function donateLiquidity(uint128 amount, uint48 depositId) external {
        if (amount == 0) revert IncorrectDonation();

        _deposit(amount);
        vault.addLiquidity(amount, depositId);

        emit LiquidityDonated(msg.sender, depositId, amount);
    }

    /**
     * @notice Withdraw payout for liquidity deposit.
     * @param  depositId The ID of the liquidity deposit.
     * @param  percent The payout share to withdraw, where `FixedMath.ONE` is 100% of the deposit balance.
     * @return withdrawnAmount The amount of withdrawn liquidity.
     */
    function withdrawDeposit(
        uint48 depositId,
        uint40 percent
    ) external returns (uint128 withdrawnAmount) {
        uint64 time = uint64(block.timestamp);
        uint64 _withdrawAfter = withdrawAfter[depositId];
        if (time < _withdrawAfter)
            revert WithdrawalTimeout(_withdrawAfter - time);
        if (msg.sender != vault.ownerOf(depositId)) revert LiquidityNotOwned();

        withdrawAfter[depositId] = time + withdrawTimeout;
        withdrawnAmount = vault.withdrawDeposit(depositId, percent);

        if (address(liquidityManager) != address(0))
            liquidityManager.afterWithdrawLiquidity(
                depositId,
                vault.nodeWithdrawView(depositId)
            );

        emit LiquidityRemoved(msg.sender, depositId, withdrawnAmount);
    }

    /**
     * @notice Reward the Factory owner (DAO) or Data Provider with total amount of charged fees.
     * @return claimedAmount claimed reward amount
     */
    function claimReward() external returns (uint128 claimedAmount) {
        Reward storage reward = rewards[msg.sender];
        if ((block.timestamp - reward.claimedAt) < claimTimeout)
            revert ClaimTimeout(reward.claimedAt + claimTimeout);

        int128 rewardAmount = reward.amount;
        if (rewardAmount > 0) {
            reward.amount = 0;
            reward.claimedAt = uint64(block.timestamp);

            claimedAmount = uint128(rewardAmount);
            _withdraw(msg.sender, claimedAmount);
        }
    }

    /**
     * @notice Make new bet.
     * @notice Emits bet token to `msg.sender`.
     * @notice See {ILP-bet}.
     */
    function bet(
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external override returns (uint256) {
        _deposit(amount);
        return _bet(msg.sender, core, amount, expiresAt, betData);
    }

    /**
     * @notice Make new bet for `bettor`.
     * @notice Emits bet token to `bettor`.
     * @param  bettor wallet for emitting bet token
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function betFor(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external override returns (uint256) {
        _deposit(amount);
        return _bet(bettor, core, amount, expiresAt, betData);
    }

    /**
     * @notice Core: Withdraw payout for bet token `tokenId` from the Core `core`.
     * @return amount The amount of withdrawn payout.
     */
    function withdrawPayout(
        address core,
        uint256 tokenId
    ) external override isCore(core) returns (uint128 amount) {
        address account;
        (account, amount) = IBet(core).resolvePayout(tokenId);
        if (amount > 0) _withdraw(account, amount);

        emit BettorWin(core, account, tokenId, amount);
    }

    /**
     * @notice Active Core: Check if Core `msg.sender` can create condition for game `gameId`.
     */
    function addCondition(
        uint256 gameId
    ) external view override isActive(msg.sender) returns (uint64) {
        Game storage game = _getGame(gameId);
        if (game.canceled) revert GameCanceled_();

        return game.startsAt;
    }

    /**
     * @notice Active Core: Change amount of liquidity reserved by the game `gameId`.
     * @param  gameId the game ID
     * @param  deltaReserve value of the change in the amount of liquidity used by the game as a reinforcement
     */
    function changeLockedLiquidity(
        uint256 gameId,
        int128 deltaReserve
    ) external override isActive(msg.sender) {
        if (deltaReserve > 0) {
            uint128 _deltaReserve = uint128(deltaReserve);
            if (gameId > 0) {
                games[gameId].lockedLiquidity += _deltaReserve;
            }

            CoreData storage coreData = _getCore(msg.sender);
            coreData.lockedLiquidity += _deltaReserve;

            vault.lockLiquidity(_deltaReserve);

            if (coreData.lockedLiquidity > getLockedLiquidityLimit(msg.sender))
                revert LockedLiquidityLimitReached();
        } else
            _reduceLockedLiquidity(msg.sender, gameId, uint128(-deltaReserve));
    }

    /**
     * @notice Factory: Indicate `core` as new active Core.
     */
    function addCore(address core) external override onlyFactory {
        CoreData storage coreData = _getCore(core);
        coreData.minBet = 1;
        coreData.reinforcementAbility = uint64(FixedMath.ONE);
        coreData.state = CoreState.ACTIVE;

        emit CoreSettingsUpdated(
            core,
            CoreState.ACTIVE,
            uint64(FixedMath.ONE),
            1
        );
    }

    /**
     * @notice Core: Finalize changes in the balance of Liquidity Pool
     *         after the game `gameId` condition's resolve.
     * @param  gameId the game ID
     * @param  lockedReserve amount of liquidity reserved by condition
     * @param  finalReserve amount of liquidity that was not demand according to the condition result
     * @param  depositId The ID of the last deposit that shares the income. In case of loss, all deposits bear the loss
     *         collectively.
     */
    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 finalReserve,
        uint48 depositId
    ) external override isCore(msg.sender) {
        Reward storage daoReward = rewards[factory.owner()];
        Reward storage dataProviderReward = rewards[dataProvider];
        Reward storage affiliateReward = rewards[affiliate];

        if (finalReserve > lockedReserve) {
            uint128 profit = finalReserve - lockedReserve;
            // add profit to liquidity (reduced by dao/data provider/affiliates rewards)
            profit -= (_chargeReward(daoReward, profit, FeeType.DAO) +
                _chargeReward(
                    dataProviderReward,
                    profit,
                    FeeType.DATA_PROVIDER
                ) +
                _chargeReward(affiliateReward, profit, FeeType.AFFILIATES));

            vault.addLiquidity(profit, depositId);
        } else {
            // remove loss from liquidityTree excluding canceled conditions (when finalReserve = lockedReserve)
            if (lockedReserve - finalReserve > 0) {
                uint128 loss = lockedReserve - finalReserve;
                // remove all loss (reduced by data dao/data provider/affiliates losses) from liquidity
                loss -= (_chargeFine(daoReward, loss, FeeType.DAO) +
                    _chargeFine(
                        dataProviderReward,
                        loss,
                        FeeType.DATA_PROVIDER
                    ) +
                    _chargeFine(affiliateReward, loss, FeeType.AFFILIATES));
                vault.withdrawLiquidity(loss, depositId);
            }
        }
        if (lockedReserve > 0)
            _reduceLockedLiquidity(msg.sender, gameId, lockedReserve);
    }

    /**
     * @notice Checks if the deposit token exists (not burned) in the Vault.
     */
    function isDepositExists(
        uint256 depositId
    ) external view override returns (bool) {
        return vault.isDepositExists(depositId);
    }

    /**
     * @notice Get the start time of the game `gameId` and whether it was canceled.
     */
    function getGameInfo(
        uint256 gameId
    ) external view override returns (uint64, bool) {
        Game storage game = games[gameId];
        return (game.startsAt, game.canceled);
    }

    /**
     * @notice Get the ID of the most recently made deposit int he Vault.
     */
    function getLastDepositId()
        external
        view
        override
        returns (uint48 depositId)
    {
        return vault.getLastDepositId();
    }

    /**
     * @notice Check if game `gameId` is canceled.
     */
    function isGameCanceled(
        uint256 gameId
    ) external view override returns (bool) {
        return games[gameId].canceled;
    }

    /**
     * @notice Get bet token `tokenId` payout.
     * @param  core address of the Core where bet was placed
     * @param  tokenId bet token ID
     * @return payout winnings of the token owner
     */
    function viewPayout(
        address core,
        uint256 tokenId
    ) external view isCore(core) returns (uint128) {
        return IBet(core).viewPayout(tokenId);
    }

    /**
     * @notice Throw if `account` have no access to function with selector `selector` of `target`.
     */
    function checkAccess(
        address account,
        address target,
        bytes4 selector
    ) public {
        access.checkAccess(account, target, selector);
    }

    /**
     * @notice Throw if `core` not belongs to the Liquidity Pool's Cores.
     */
    function checkCore(address core) public view {
        if (_getCore(core).state == CoreState.UNKNOWN) revert UnknownCore();
    }

    /**
     * @notice Get the max amount of liquidity that can be locked by Core `core` conditions.
     */
    function getLockedLiquidityLimit(
        address core
    ) public view returns (uint128) {
        return
            uint128(
                _getCore(core).reinforcementAbility.mul(vault.getReserve())
            );
    }

    /**
     * @notice Deposit liquidity in the Liquidity Pool.
     * @notice Emits deposit token to `depositor`.
     * @param  account The account that will become the owner of the deposit.
     * @param  amount The token's amount to deposit.
     * @param  data The additional data for processing in the Liquidity Manager contract.
     * @return depositId The deposit ID.
     */
    function _addDeposit(
        address account,
        uint128 amount,
        bytes calldata data
    ) internal returns (uint48 depositId) {
        if (amount < minDepo) revert SmallDepo();

        _deposit(amount);
        depositId = vault.addDeposit(account, amount);

        if (address(liquidityManager) != address(0))
            liquidityManager.beforeAddLiquidity(
                account,
                depositId,
                amount,
                data
            );

        withdrawAfter[depositId] = uint64(block.timestamp) + withdrawTimeout;

        emit LiquidityAdded(account, depositId, amount);
    }

    /**
     * @notice Make new bet.
     * @param  bettor wallet for emitting bet token
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function _bet(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData memory betData
    ) internal isActive(core) returns (uint256) {
        if (block.timestamp >= expiresAt) revert BetExpired();
        if (amount < _getCore(core).minBet) revert SmallBet();
        // owner is default affiliate
        if (betData.affiliate == address(0)) betData.affiliate = owner();
        return IBet(core).putBet(bettor, amount, betData);
    }

    /**
     * @dev Deduct a fine from a reward balance.
     * @param reward The reward from which the fine is deducted.
     * @param loss The loss used for calculating the fine.
     * @param feeType The fee type for calculating the fine.
     * @return _reduceDelta(reward.amount, _getShare(loss, feeType)) before reward balance changing.
     */
    function _chargeFine(
        Reward storage reward,
        uint128 loss,
        FeeType feeType
    ) internal returns (uint128) {
        int128 share = _getShare(loss, feeType);
        uint128 reduceDelta = _reduceDelta(reward.amount, share);
        reward.amount -= share;

        return reduceDelta;
    }

    /**
     * @notice Charge a reward to a reward balance.
     * @param reward The reward balance to which the reward is added.
     * @param profit The profit used for calculating the reward.
     * @param feeType The fee type for calculating the reward.
     * @return _addDelta(reward.amount, _getShare(loss, feeType)) before reward balance changing.
     */
    function _chargeReward(
        Reward storage reward,
        uint128 profit,
        FeeType feeType
    ) internal returns (uint128) {
        int128 share = _getShare(profit, feeType);
        uint128 addDelta = _addDelta(reward.amount, share);
        reward.amount += share;

        return addDelta;
    }

    /**
     * @notice Deposit `amount` of `token` tokens from `msg.sender` balance to the contract.
     */
    function _deposit(uint128 amount) internal {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
    }

    function _reduceLockedLiquidity(
        address core,
        uint256 gameId,
        uint128 deltaReserve
    ) internal {
        if (gameId > 0) {
            games[gameId].lockedLiquidity -= deltaReserve;
        }
        _getCore(core).lockedLiquidity -= deltaReserve;
        vault.unlockLiquidity(deltaReserve);
    }

    /**
     * @notice Withdraw `amount` of tokens to `to` balance.
     */
    function _withdraw(address to, uint128 amount) internal {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /**
     * @notice Throw if `core` not belongs to the Liquidity Pool's active Cores.
     */
    function _checkCoreActive(address core) internal view {
        if (_getCore(core).state != CoreState.ACTIVE) revert CoreNotActive();
    }

    /**
     * @notice Throw if set fees are incorrect.
     */
    function _checkFee() internal view {
        if (
            _getFee(FeeType.DAO) +
                _getFee(FeeType.DATA_PROVIDER) +
                _getFee(FeeType.AFFILIATES) >
            FixedMath.ONE
        ) revert IncorrectFee();
    }

    function _getCore(address core) internal view returns (CoreData storage) {
        return cores[core];
    }

    /**
     * @notice Get current fee type `feeType` profit share.
     */
    function _getFee(FeeType feeType) internal view returns (uint64) {
        return fees[uint256(feeType)];
    }

    /**
     * @notice Get game by it's ID.
     */
    function _getGame(uint256 gameId) internal view returns (Game storage) {
        Game storage game = games[gameId];
        if (game.startsAt == 0) revert GameNotExists();

        return game;
    }

    function _getShare(
        uint128 amount,
        FeeType feeType
    ) internal view returns (int128) {
        return _getFee(feeType).mul(amount).toUint128().toInt128();
    }

    /**
     * @notice Calculate the positive delta between `a` and `a + b`.
     */
    function _addDelta(int128 a, int128 b) internal pure returns (uint128) {
        if (a < 0) {
            int128 c = a + b;
            return (c > 0) ? uint128(c) : 0;
        } else return uint128(b);
    }

    /**
     * @notice Calculate the positive delta between `a - b` and `a`.
     */
    function _reduceDelta(int128 a, int128 b) internal pure returns (uint128) {
        return (a < 0 ? 0 : uint128(a > b ? b : a));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interface/IOwnable.sol";

/**
 * @dev Forked from OpenZeppelin contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/ae03ee04ae226526abad6731cf4024134f46ae28/contracts/access/OwnableUpgradeable.sol
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
abstract contract OwnableUpgradeable is
    IOwnable,
    Initializable,
    ContextUpgradeable
{
    address private _owner;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the account is not the owner.
     */
    function checkOwner(address account) public view virtual override {
        require(owner() == account, "Ownable: account is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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