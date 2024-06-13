// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

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
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
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
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract LockAndMsgSender {
    error ContractLocked();

    /// @dev Used as a flag for identifying that msg.sender should be used, saves gas by sending more 0 bytes
    address internal constant MSG_SENDER = address(1);

    /// @dev Used as a flag for identifying address(this) should be used, saves gas by sending more 0 bytes
    address internal constant ADDRESS_THIS = address(2);

    address internal constant NOT_LOCKED_FLAG = address(1);
    address internal lockedBy;

    modifier isNotLocked() {
        if (msg.sender != address(this)) {
            if (lockedBy != NOT_LOCKED_FLAG) revert ContractLocked();
            lockedBy = msg.sender;
            _;
            lockedBy = NOT_LOCKED_FLAG;
        } else {
            _;
        }
    }

    function _initLockedBy() internal {
        lockedBy = NOT_LOCKED_FLAG;
    }

    /// @notice Calculates the recipient address for a command
    /// @param recipient The recipient or recipient-flag for the command
    /// @return output The resultant recipient for the command
    function map(address recipient) internal view returns (address) {
        if (recipient == MSG_SENDER) {
            return lockedBy;
        } else if (recipient == ADDRESS_THIS) {
            return address(this);
        } else {
            return recipient;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

interface ISwapRouter02 {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISyncSwap {
    struct SwapStep {
        address pool; // The pool of the step.
        bytes data; // The data to execute swap with the pool.
        address callback;
        bytes callbackData;
    }

    struct SwapPath {
        SwapStep[] steps; // Steps of the path.
        address tokenIn; // The input token of the path.
        uint amountIn; // The input token amount of the path.
    }

    function swap(
        SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline
    ) external payable returns (uint amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IZookeyRouter {
    error ExecutionFailed(uint256 commandIndex, bytes message);

    error TransactionDeadlinePassed();

    function execute(
        address fromToken,
        address toToken,
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline
    ) external payable;

    event SwapLog(
        uint256 commandType,
        uint256 amountIn,
        uint256 amountOut
    );
}

// SPDX-License-Identifier: MIT

/// @title Library for Bytes Manipulation
pragma solidity ^0.8.0;

library BytesLib {
    error SliceOutOfBounds();

    /// @dev The length of the bytes encoded address
    uint256 internal constant ADDR_SIZE = 20;

    /// @notice Decode the `_arg`-th element in `_bytes` as a dynamic array
    /// @dev The decoding of `length` and `offset` is universal,
    /// whereas the type declaration of `res` instructs the compiler how to read it.
    /// @param _bytes The input bytes string to slice
    /// @param _arg The index of the argument to extract
    /// @return length Length of the array
    /// @return offset Pointer to the data part of the array
    function toLengthOffset(
        bytes calldata _bytes,
        uint256 _arg
    ) internal pure returns (uint256 length, uint256 offset) {
        uint256 relativeOffset;
        assembly {
            // The offset of the `_arg`-th element is `32 * arg`, which stores the offset of the length pointer.
            // shl(5, x) is equivalent to mul(32, x)
            let lengthPtr := add(
                _bytes.offset,
                calldataload(add(_bytes.offset, shl(5, _arg)))
            )
            length := calldataload(lengthPtr)
            offset := add(lengthPtr, 0x20)
            relativeOffset := sub(offset, _bytes.offset)
        }
        if (_bytes.length < length + relativeOffset) revert SliceOutOfBounds();
    }

    /// @notice Decode the `_arg`-th element in `_bytes` as `bytes`
    /// @param _bytes The input bytes string to extract a bytes string from
    /// @param _arg The index of the argument to extract
    function toBytes(
        bytes calldata _bytes,
        uint256 _arg
    ) internal pure returns (bytes calldata res) {
        (uint256 length, uint256 offset) = toLengthOffset(_bytes, _arg);
        assembly {
            res.length := length
            res.offset := offset
        }
    }
    /// @notice Decode the `_arg`-th element in `_bytes` as `address[]`
    /// @param _bytes The input bytes string to extract an address array from
    /// @param _arg The index of the argument to extract
    function toAddressArray(
        bytes calldata _bytes,
        uint256 _arg
    ) internal pure returns (address[] calldata res) {
        (uint256 length, uint256 offset) = toLengthOffset(_bytes, _arg);
        assembly {
            res.length := length
            res.offset := offset
        }
    }

    // @notice Returns the address starting at byte 0
    /// @dev length and overflow checks must be carried out before calling
    /// @param _bytes The input bytes string to slice
    /// @return _address The address starting at byte 0
    function toAddress(
        bytes calldata _bytes
    ) internal pure returns (address _address) {
        if (_bytes.length < ADDR_SIZE) revert SliceOutOfBounds();
        assembly {
            _address := shr(96, calldataload(_bytes.offset))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Commands
/// @notice Command Flags used to decode commands
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    uint8 constant SWAP_IF_BOUNDARY = 0x09;
    uint8 constant BRIDGE_IF_BOUNDARY = 0x13;
    // swap 0x00 => 0x09

    uint8 constant V3_SWAP_EXACT_IN = 0x00;
    uint8 constant V2_SWAP_EXACT_IN = 0x01;
    uint8 constant SYNC_SWAP = 0x03;
    uint8 constant ONEINCH_SWAP = 0x04;

    // bridge 0x0a => 0x13
    uint8 constant BRIDGE_ORBITER = 0x0a;
    uint8 constant STARGATE_SWAP = 0x0b;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ZookeyConstants {
    /// @dev WNATIVE_TOKEN address is network-specific and needs to be changed before deployment.
    /// It can not be moved to immutable as immutables are not supported in assembly
    // ETH:     0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // Sepolia  0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14
    // ARB:     0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    // OP:      0x4200000000000000000000000000000000000006
    // POLYGON [WMATIC]: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
    // ZK:      0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91
    // Scroll   0x5300000000000000000000000000000000000004
    // BASE     0x4200000000000000000000000000000000000006
    address internal constant WNATIVE_TOKEN =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // ETH 0x0000000000000000000000000000000000000000
    // Sepolia 0x0000000000000000000000000000000000000000
    // ARB 0x0000000000000000000000000000000000000000
    // OP 0x0000000000000000000000000000000000000000
    // BASE 0x0000000000000000000000000000000000000000
    // POLYGON 0x0000000000000000000000000000000000001010
    // ZK 0x0000000000000000000000000000000000000000
    // SCROLL 0x0000000000000000000000000000000000000000
    address internal constant NATIVE_TOKEN =
        0x0000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ZookeyRouterConstants {
    /// @dev Used for identifying cases when this contract's balance of a token is to be used as an input
    /// This value is equivalent to 1<<255, i.e. a singular 1 in the most significant bit.
    uint256 internal constant CONTRACT_BALANCE =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    // Mainnet 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Sepolia 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
    // Arbitrum 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Optimism 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Polygon 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Base 0x2626664c2603336E57B271c5C0b26F421741e481
    // Scroll 0xfc30937f5cDe93Df8d48aCAF7e6f5D8D8A31F636
    address internal constant UNI_SWAP_ROUTER_V3 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // Mainnet 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Sepolia 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
    // Arbitrum 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Optimism 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Polygon 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Base 0x2626664c2603336E57B271c5C0b26F421741e481
    // Scroll 0xfc30937f5cDe93Df8d48aCAF7e6f5D8D8A31F636
    address internal constant UNI_SWAP_ROUTER_V2 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // ZK 0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295
    // Scroll 0x80e38291e06339d10AAB483C65695D004dBD5C69
    address internal constant SYNCSWAP_ROUTER =
        0x80e38291e06339d10AAB483C65695D004dBD5C69;

    // Mainnet 0x111111125421ca6dc452d289314280a0f8842a65
    // Arbitrum 0x111111125421cA6dc452d289314280a0f8842A65
    // Optimism 0x111111125421cA6dc452d289314280a0f8842A65
    // Polygon 0x111111125421cA6dc452d289314280a0f8842A65
    // Base 0x111111125421cA6dc452d289314280a0f8842A65
    // ZK 0x6fd4383cb451173d5f9304f041c7bcbf27d561ff
    address internal constant ONEINCH_SWAP_ROUTER =
        0x111111125421cA6dc452d289314280a0f8842A65;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ZookeyRouterErrors {
    string internal constant SWAP_INPUTS_ERR = "swap inputs err";
    string internal constant SWAP_COMMANDS_ERR = "swap commands err";
    string internal constant TRANSACTION_DEADLINE = "trans Deadline Passed";
    string internal constant EXECUTE_LENGTH_ERR = "Execute Length Mismatch";
    string internal constant V3_TRANSFER_ERROR = "v3 transfer err";
    string internal constant FROM_TOKEN_ADDR_ERR = "ETH should use WETH";
    string internal constant SYNC_SWAP_AMOUNT_OUT_ERR =
        "swap amount out should gt 0";
    string internal constant ONEINCH_SWAP_AMOUNT_OUT_ERR =
        "swap amount out should gt 0";
    string internal constant ONEINCH_SWAP_RECEIVER_ZERO =
        "1inch receiver be zero";
    string internal constant ONEINCH_SWAP_TRANSFER_ERR =
        "1inch transfer failed";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Commands} from "./libraries/Commands.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ZookeyConstants} from "./libraries/constants/Common.sol";
import {ZookeyRouterConstants} from "./libraries/constants/ZookeyRouterConstants.sol";
import {BytesLib} from "./libraries/BytesLib.sol";
import {ZookeyRouterErrors} from "./libraries/errors/ZookeyRouterErrors.sol";
import "./interface/IWETH.sol";
import {ISwapRouter02} from "./interface/ISwapRouter02.sol";
import {IZookeyRouter} from "./interface/IZookeyRouter.sol";
import {ISyncSwap} from "./interface/ISyncSwap.sol";
import "./base/LockAndMsgSender.sol";

contract ZookeyRouter is IZookeyRouter, OwnableUpgradeable, LockAndMsgSender {
    using BytesLib for bytes;

    event DEXSwapResult(
        uint8 command,
        address fromToken,
        address toToken,
        uint256 fromTokenIn,
        uint256 amountOut
    );

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    /**
     * @dev sets initials supply and the owner
     */
    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
        _initLockedBy();
    }

    function _getBalanceOf(
        address _token,
        address _who
    ) internal view returns (uint256) {
        return
            _token == ZookeyConstants.NATIVE_TOKEN
                ? _who.balance
                : IERC20(_token).balanceOf(_who);
    }

    function execute(
        address fromToken,
        address toToken,
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline
    ) external payable isNotLocked {
        require(commands.length > 0, ZookeyRouterErrors.SWAP_COMMANDS_ERR);
        require(inputs.length > 0, ZookeyRouterErrors.SWAP_INPUTS_ERR);
        require(
            block.timestamp <= deadline,
            ZookeyRouterErrors.TRANSACTION_DEADLINE
        );
        _execute(fromToken, toToken, commands, inputs, deadline);
    }

    function _execute(
        address _fromToken,
        address _toToken,
        bytes calldata _commands,
        bytes[] calldata _inputs,
        uint256 _deadline
    ) internal {
        bool success;
        uint256 numCommands = _commands.length;

        require(
            _inputs.length == numCommands,
            ZookeyRouterErrors.EXECUTE_LENGTH_ERR
        );

        // loop through all given _commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
            bytes1 command = _commands[commandIndex];

            bytes calldata input = _inputs[commandIndex];

            success = _dispatch(
                _fromToken,
                _toToken,
                command,
                input,
                _deadline
            );

            if (!success) {
                revert ExecutionFailed({
                    commandIndex: commandIndex,
                    message: "dispatch err"
                });
            }

            unchecked {
                commandIndex++;
            }
        }
    }

    function _dispatch(
        address _fromToken,
        address _toToken,
        bytes1 _commandType,
        bytes calldata _input,
        uint256 _deadline
    ) internal checkDeadline(_deadline) returns (bool success) {
        uint256 command = uint8(_commandType & Commands.COMMAND_TYPE_MASK);
        success = true;
        if (command <= Commands.BRIDGE_IF_BOUNDARY) {
            if (command <= Commands.SWAP_IF_BOUNDARY) {
                if (command == Commands.V3_SWAP_EXACT_IN) {
                    _swapV3ExactIn(_fromToken, _toToken, _input);
                }
                if (command == Commands.V2_SWAP_EXACT_IN) {
                    _swapV2ExactIn(_fromToken, _toToken, _input);
                }
                if (command == Commands.SYNC_SWAP) {
                    _syncSwap(_fromToken, _input);
                }
                if (command == Commands.ONEINCH_SWAP) {
                    _oneinchSwap(_fromToken, _toToken, _input);
                }
            }
        } else {
            success = false;
        }
    }

    function _swapV3ExactIn(
        address _fromToken,
        address _toToken,
        bytes calldata _input
    ) internal {
        address recipient;
        uint256 fromTokenAmount;
        uint256 amountOutMin;
        bool onlyApprove;
        // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes))
        assembly {
            recipient := calldataload(_input.offset)
            fromTokenAmount := calldataload(add(_input.offset, 0x20))
            amountOutMin := calldataload(add(_input.offset, 0x40))
            // 0x60 offset is the path, decoded below
        }
        bytes calldata path = _input.toBytes(3);

        if (fromTokenAmount == ZookeyRouterConstants.CONTRACT_BALANCE) {
            _fromToken = path.toAddress();
            fromTokenAmount = IERC20(_fromToken).balanceOf(address(this));
            onlyApprove = true;
        }

        if (_fromToken == ZookeyConstants.NATIVE_TOKEN) {
            IWETH(ZookeyConstants.WNATIVE_TOKEN).deposit{value: msg.value}();
            onlyApprove = true;
            _fromToken = ZookeyConstants.WNATIVE_TOKEN;
        }
        address lastTokenBytes = address(
            bytes20(path[path.length - 20:path.length])
        );
        bool needToETH = lastTokenBytes == ZookeyConstants.WNATIVE_TOKEN &&
            _toToken == ZookeyConstants.NATIVE_TOKEN;
        ISwapRouter02.ExactInputParams memory params = ISwapRouter02
            .ExactInputParams({
                path: path,
                recipient: needToETH ? address(this) : map(recipient),
                amountIn: fromTokenAmount,
                amountOutMinimum: amountOutMin
            });
        _tokenRelayer(
            _fromToken,
            fromTokenAmount,
            ZookeyRouterConstants.UNI_SWAP_ROUTER_V3,
            onlyApprove
        );
        ISwapRouter02(ZookeyRouterConstants.UNI_SWAP_ROUTER_V3).exactInput(
            params
        );
        if (needToETH) {
            uint256 amount = IWETH(ZookeyConstants.WNATIVE_TOKEN).balanceOf(
                address(this)
            );
            IWETH(ZookeyConstants.WNATIVE_TOKEN).withdraw(amount);
            if (map(recipient) != address(this)) {
                (bool success, ) = payable(map(recipient)).call{value: amount}(
                    ""
                );
                require(success, ZookeyRouterErrors.V3_TRANSFER_ERROR);
            }
        }
    }

    function _swapV2ExactIn(
        address _fromToken,
        address _toToken,
        bytes calldata _input
    ) internal {
        address recipient;
        uint256 fromTokenAmount;
        uint256 amountOutMin;
        bool onlyApprove;
        assembly {
            recipient := calldataload(_input.offset)
            fromTokenAmount := calldataload(add(_input.offset, 0x20))
            amountOutMin := calldataload(add(_input.offset, 0x40))
            // 0x60 offset is the path, decoded below
        }
        address[] calldata path = _input.toAddressArray(3);
        if (fromTokenAmount == ZookeyRouterConstants.CONTRACT_BALANCE) {
            _fromToken = path[0];
            fromTokenAmount = IERC20(_fromToken).balanceOf(address(this));
            onlyApprove = true;
        }

        if (_fromToken == ZookeyConstants.NATIVE_TOKEN) {
            IWETH(ZookeyConstants.WNATIVE_TOKEN).deposit{value: msg.value}();
            onlyApprove = true;
            _fromToken = ZookeyConstants.WNATIVE_TOKEN;
        }

        address lastTokenBytes = address(path[path.length - 1]);

        bool needToETH = lastTokenBytes == ZookeyConstants.WNATIVE_TOKEN &&
            _toToken == ZookeyConstants.NATIVE_TOKEN;

        _tokenRelayer(
            _fromToken,
            fromTokenAmount,
            ZookeyRouterConstants.UNI_SWAP_ROUTER_V2,
            onlyApprove
        );
        ISwapRouter02(ZookeyRouterConstants.UNI_SWAP_ROUTER_V2)
            .swapExactTokensForTokens(
                fromTokenAmount,
                amountOutMin,
                path,
                needToETH ? address(this) : map(recipient)
            );
        if (needToETH) {
            uint256 amount = IWETH(ZookeyConstants.WNATIVE_TOKEN).balanceOf(
                address(this)
            );
            IWETH(ZookeyConstants.WNATIVE_TOKEN).withdraw(amount);
            if (map(recipient) != address(this)) {
                (bool success, ) = payable(map(recipient)).call{value: amount}(
                    ""
                );
                require(success, ZookeyRouterErrors.V3_TRANSFER_ERROR);
            }
        }
    }

    function _syncSwap(address _fromToken, bytes calldata _input) internal {
        (
            ISyncSwap.SwapPath[] memory paths,
            uint256 fromTokenIn,
            uint256 amountOutMin,
            uint256 deadline
        ) = abi.decode(
                _input,
                (ISyncSwap.SwapPath[], uint256, uint256, uint256)
            );
        if (_fromToken != ZookeyConstants.NATIVE_TOKEN) {
            _tokenRelayer(
                _fromToken,
                fromTokenIn,
                ZookeyRouterConstants.SYNCSWAP_ROUTER,
                false
            );
        }
        uint256 amountOut = ISyncSwap(ZookeyRouterConstants.SYNCSWAP_ROUTER)
            .swap{value: msg.value}(paths, amountOutMin, deadline);
        require(amountOut > 0, ZookeyRouterErrors.SYNC_SWAP_AMOUNT_OUT_ERR);
    }

    function _oneinchSwap(
        address _fromToken,
        address _toToken,
        bytes memory _input
    ) internal {
        (bytes memory callData, uint256 fromTokenIn, address receiver) = abi
            .decode(_input, (bytes, uint256, address));
        require(
            map(receiver) != address(0),
            ZookeyRouterErrors.ONEINCH_SWAP_RECEIVER_ZERO
        );
        if (_fromToken != ZookeyConstants.NATIVE_TOKEN) {
            _tokenRelayer(
                _fromToken,
                fromTokenIn,
                ZookeyRouterConstants.ONEINCH_SWAP_ROUTER,
                false
            );
        }
        uint256 beforeSwapTokenBalance = _getBalanceOf(_toToken, address(this));
        (bool success, bytes memory returnData) = ZookeyRouterConstants
            .ONEINCH_SWAP_ROUTER
            .call{value: msg.value}(callData);
        uint256 amountOut = abi.decode(returnData, (uint256));
        uint256 afterSwapTokenBalance = _getBalanceOf(_toToken, address(this));
        require(
            success && returnData.length > 0,
            ZookeyRouterErrors.ONEINCH_SWAP_AMOUNT_OUT_ERR
        );
        if (afterSwapTokenBalance > beforeSwapTokenBalance) {
            if (_toToken == ZookeyConstants.NATIVE_TOKEN) {
                (bool right, ) = payable(map(receiver)).call{value: amountOut}(
                    ""
                );
                require(right, ZookeyRouterErrors.ONEINCH_SWAP_TRANSFER_ERR);
            } else {
                TransferHelper.safeTransfer(_toToken, map(receiver), amountOut);
            }
        }
        emit DEXSwapResult(
            Commands.ONEINCH_SWAP,
            _fromToken,
            _toToken,
            fromTokenIn,
            amountOut
        );
    }

    function _tokenRelayer(
        address _fromToken,
        uint256 _fromTokenAmount,
        address _approveTo,
        bool _onlyApprove
    ) internal {
        if (!_onlyApprove) {
            TransferHelper.safeTransferFrom(
                _fromToken,
                msg.sender,
                address(this),
                _fromTokenAmount
            );
        }
        TransferHelper.safeApprove(_fromToken, _approveTo, _fromTokenAmount);
    }

    /// @notice To receive ETH from WETH and refund
    receive() external payable {}

    uint256[50] internal reserve;
}