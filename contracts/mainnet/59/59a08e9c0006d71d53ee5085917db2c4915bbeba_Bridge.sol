// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IZKBridgeReceiver.sol";
import "./interfaces/IZKBridgeEndpoint.sol";
import "./interfaces/IL1Bridge.sol";

import {Pool} from "./Pool.sol";

contract Bridge is IZKBridgeReceiver, Initializable, ReentrancyGuardUpgradeable, Pool {
    using SafeERC20 for IERC20;

    IZKBridgeEndpoint public immutable zkBridgeEndpoint;
    IL1Bridge public immutable l1Bridge;

    // chainId -> bridge address, mapping of token bridge contracts on other chains
    mapping(uint16 => address) public bridgeLookup;

    // For two-step bridge management
    bool public pendingBridge;
    uint16 public pendingDstChainId;
    address public pendingBridgeAddress;

    event TransferToken(
        uint64 indexed sequence,
        uint16 indexed dstChainId,
        uint256 indexed poolId,
        address sender,
        address recipient,
        uint256 amount
    );

    event ReceiveToken(
        uint64 indexed sequence, uint16 indexed srcChainId, uint256 indexed poolId, address recipient, uint256 amount
    );

    event NewPendingBridge(uint16 chainId, address bridge);
    event NewBridge(uint16 chainId, address bridge);

    /// @dev l1Bridge_ could be address(0) when Mux functions are not needed
    constructor(IZKBridgeEndpoint zkBridgeEndpoint_, IL1Bridge l1Bridge_, uint256 NATIVE_TOKEN_POOL_ID_)
        Pool(NATIVE_TOKEN_POOL_ID_)
    {
        require(address(zkBridgeEndpoint_) != address(0), "Bridge: zkBridgeEndpoint is the zero address");
        zkBridgeEndpoint = zkBridgeEndpoint_;
        l1Bridge = l1Bridge_;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Admin_init();
    }

    function estimateFee(uint256 poolId, uint16 dstChainId) public view returns (uint256) {
        _checkDstChain(poolId, dstChainId);
        uint256 uaFee = getFee(poolId, dstChainId);
        uint256 zkBridgeFee = zkBridgeEndpoint.estimateFee(dstChainId);
        return uaFee + zkBridgeFee;
    }

    function _transfer(uint16 dstChainId, uint256 poolId, uint256 amount, address recipient, uint256 fee)
        internal
        returns (uint256)
    {
        address dstBridge = bridgeLookup[dstChainId];
        require(dstBridge != address(0), "Bridge: dstChainId does not exist");

        uint256 uaFee = getFee(poolId, dstChainId);
        uint256 zkBridgeFee = zkBridgeEndpoint.estimateFee(dstChainId);
        require(fee >= uaFee + zkBridgeFee, "Bridge: Insufficient Fee");

        uint256 amountSD = _deposit(poolId, dstChainId, amount);

        bytes memory payload = abi.encode(poolId, amountSD, recipient);
        uint64 sequence = zkBridgeEndpoint.send{value: zkBridgeFee}(dstChainId, dstBridge, payload);

        emit TransferToken(sequence, dstChainId, poolId, msg.sender, recipient, amountSD);

        // Returns the actual amount of fees used
        return uaFee + zkBridgeFee;
    }

    /// @notice The main function for sending native token through bridge
    function transferETH(uint16 dstChainId, uint256 amount, address recipient) external payable nonReentrant {
        require(msg.value >= amount, "Bridge: Insufficient ETH");
        _transfer(dstChainId, NATIVE_TOKEN_POOL_ID, amount, recipient, msg.value - amount);
    }

    /// @notice The main function for sending ERC20 tokens through bridge
    function transferToken(uint16 dstChainId, uint256 poolId, uint256 amount, address recipient)
        external
        payable
        nonReentrant
    {
        require(poolId != NATIVE_TOKEN_POOL_ID, "Bridge: Can't transfer token using native token pool ID");
        IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
        _transfer(dstChainId, poolId, amount, recipient, msg.value);
    }

    /// @notice The main function for receiving tokens. Should only be called by zkBridge
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload)
        external
        nonReentrant
    {
        require(msg.sender == address(zkBridgeEndpoint), "Bridge: Not from zkBridgeEndpoint");
        require(srcAddress != address(0) && srcAddress == bridgeLookup[srcChainId], "Bridge: Invalid emitter");

        (uint256 poolId, uint256 amountSD, address recipient) = abi.decode(payload, (uint256, uint256, address));

        uint256 amount = _withdraw(poolId, srcChainId, amountSD);

        if (poolId == NATIVE_TOKEN_POOL_ID) {
            Address.sendValue(payable(recipient), amount);
        } else {
            IERC20(_poolInfo[poolId].token).safeTransfer(recipient, amount);
        }

        emit ReceiveToken(sequence, srcChainId, poolId, recipient, amountSD);
    }

    /// @notice Sending native token through bridge, fallback to l1bridge when limits are triggered
    function transferETHMux(uint16 dstChainId, uint256 amount, address recipient) external payable nonReentrant {
        require(address(l1Bridge) != address(0), "Bridge: l1Bridge not available");
        uint256 refundAmount;
        if (
            _poolInfo[NATIVE_TOKEN_POOL_ID].balance + amount <= _poolInfo[NATIVE_TOKEN_POOL_ID].maxLiquidity
                && amount <= _dstChains[NATIVE_TOKEN_POOL_ID][dstChainId].maxTransferLimit
        ) {
            require(msg.value >= amount, "Bridge: Insufficient ETH");
            uint256 fee = _transfer(dstChainId, NATIVE_TOKEN_POOL_ID, amount, recipient, msg.value - amount);
            refundAmount = msg.value - amount - fee;
        } else {
            uint256 fee = l1Bridge.fees(dstChainId);
            require(msg.value >= amount + fee, "Bridge: Insufficient ETH");
            l1Bridge.transferETH{value: amount + fee}(dstChainId, amount, recipient);
            refundAmount = msg.value - amount - fee;
        }

        if (refundAmount > 0) {
            Address.sendValue(payable(msg.sender), refundAmount);
        }
    }

    /// @notice Sending ERC20 tokens through bridge, fallback to l1bridge when limits are triggered
    function transferTokenMux(uint16 dstChainId, uint256 poolId, uint256 amount, address recipient)
        external
        payable
        nonReentrant
    {
        require(address(l1Bridge) != address(0), "Bridge: l1Bridge not available");
        require(poolId != NATIVE_TOKEN_POOL_ID, "Bridge: Can't transfer token using native token pool ID");
        address token = _poolInfo[poolId].token;
        require(token != address(0), "Bridge: pool not found");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 refundAmount;
        if (
            _poolInfo[poolId].balance + amount <= _poolInfo[poolId].maxLiquidity
                && amount <= _dstChains[poolId][dstChainId].maxTransferLimit
        ) {
            uint256 fee = _transfer(dstChainId, poolId, amount, recipient, msg.value);
            refundAmount = msg.value - fee;
        } else {
            uint256 fee = l1Bridge.fees(dstChainId);
            require(msg.value >= fee, "Bridge: Insufficient fee");
            IERC20(token).safeApprove(address(l1Bridge), amount);
            l1Bridge.transferERC20{value: fee}(dstChainId, token, amount, recipient);
            IERC20(token).safeApprove(address(l1Bridge), 0);
            refundAmount = msg.value - fee;
        }

        if (refundAmount > 0) {
            Address.sendValue(payable(msg.sender), refundAmount);
        }
    }

    function estimateFeeMux(uint256 poolId, uint16 dstChainId) external view returns (uint256) {
        require(address(l1Bridge) != address(0), "Bridge: l1Bridge not available");
        uint256 fee = estimateFee(poolId, dstChainId);
        uint256 l1Fee = l1Bridge.fees(dstChainId);
        return fee > l1Fee ? fee : l1Fee;
    }

    /// @notice adding a new dstChain bridge address
    /// @param bridge could be address(0) when deleting a bridge
    function setBridge(uint16 dstChainId, address bridge) external onlyBridgeManager nonReentrant {
        if (bridgeManager != bridgeReviewer) {
            // Two-step bridge management needed
            pendingDstChainId = dstChainId;
            pendingBridgeAddress = bridge;
            pendingBridge = true;
            emit NewPendingBridge(dstChainId, bridge);
        } else {
            // bridgeManager is the same as bridgeReviewer, two-step bridge management not needed
            bridgeLookup[dstChainId] = bridge;
            if (pendingBridge) {
                pendingBridge = false;
            }
            emit NewBridge(dstChainId, bridge);
        }
    }

    /// @notice approve a new dstChain bridge address
    /// @dev The dstChainId and bridge params are required to prevent front-running attacks
    function approveSetBridge(uint16 dstChainId, address bridge) external onlyBridgeReviewer nonReentrant {
        require(pendingBridge, "Bridge: no pending bridge");
        require(
            dstChainId == pendingDstChainId && bridge == pendingBridgeAddress,
            "Bridge: dstChainId or bridge does not match"
        );
        bridgeLookup[dstChainId] = bridge;
        pendingBridge = false;
        emit NewBridge(dstChainId, bridge);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

interface IZKBridgeReceiver {
    // @notice ZKBridge endpoint will invoke this function to deliver the message on the destination
    // @param srcChainId - the source endpoint identifier
    // @param srcAddress - the source sending contract address from the source chain
    // @param sequence - the ordered message nonce
    // @param payload - the signed payload is the UA bytes has encoded to be sent
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEndpoint {
    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64);

    function estimateFee(uint16 dstChainId) external view returns (uint256 fee);

    function chainId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1Bridge {
    function transferETH(uint16 dstChainId_, uint256 amount_, address recipient_) external payable;

    function transferETHFromVault(uint16 dstChainId_, address recipient_) external payable;

    function transferERC20(uint16 dstChainId_, address l1Token_, uint256 amount_, address recipient_)
        external
        payable;

    function transferERC20FromVault(uint16 dstChainId_, address l1Token_, uint256 amount_, address recipient_)
        external;

    function fees(uint16 dstChainId_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {Admin} from "./Admin.sol";

abstract contract Pool is ReentrancyGuardUpgradeable, Admin {
    using SafeERC20 for IERC20;

    struct DstChainInfo {
        bool enabled; // Whether dstChain is enabled for this pool
        uint128 staticFee; // Static fee when sending tokens to dstChain
        uint256 maxTransferLimit; // Limit of a single transfer
    }

    struct PoolInfo {
        // Whether this pool is enabled
        bool enabled;
        // Should be (local decimals - shared decimals)
        // e.g. If local decimals is 18 and shared decimals is 6, this number should be 12
        // Local decimals is the decimals of the underlying ERC20 token
        // Shared decimals is the common decimals across all chains
        uint8 convertRateDecimals;
        // ERC20 token address. Should be address(0) for native token pool
        address token;
        // Token balance of this pool
        // This should be tracked via a variable because this contract also hold fees
        // Also, an attacker may force transfer tokens to this contract to reach maxLiquidity
        uint256 balance;
        // The liquidity of this pool when the remote pool is exhausted
        // Only works when there are two chains
        // When there are >= 3 chains, this does not work and should be set to type(uint256).max
        uint256 maxLiquidity;
    }

    // poolId -> dstChainId -> DstChainInfo
    mapping(uint256 => mapping(uint16 => DstChainInfo)) internal _dstChains;

    // Native token pool ID
    uint256 public immutable NATIVE_TOKEN_POOL_ID;

    // poolId -> PoolInfo
    // poolId needs to be the same across different chains for the same token
    mapping(uint256 => PoolInfo) internal _poolInfo;

    event AddLiquidity(uint256 indexed poolId, uint256 amount);
    event RemoveLiquidity(uint256 indexed poolId, uint256 amount);
    event DstChainStatusChanged(uint256 indexed poolId, uint16 indexed dstChainId, bool indexed enabled);
    event NewMaxTransferLimit(uint256 indexed poolId, uint16 indexed dstChainId, uint256 maxTransferLimit);
    event NewMaxLiquidity(uint256 indexed poolId, uint256 maxLiquidity);
    event NewStaticFee(uint256 indexed poolId, uint16 indexed dstChainId, uint256 staticFee);
    event ClaimedFees(address to, uint256 amount);

    constructor(uint256 NATIVE_TOKEN_POOL_ID_) {
        NATIVE_TOKEN_POOL_ID = NATIVE_TOKEN_POOL_ID_;
    }

    function poolInfo(uint256 poolId) public view returns (PoolInfo memory) {
        return _poolInfo[poolId];
    }

    function dstChains(uint256 poolId, uint16 dstChainId) public view returns (DstChainInfo memory) {
        return _dstChains[poolId][dstChainId];
    }

    function convertRate(uint256 poolId) public view returns (uint256) {
        return 10 ** _poolInfo[poolId].convertRateDecimals;
    }

    /// @dev ensure amount is a multiple of convertRate
    function _checkConvertRate(uint256 poolId, uint256 amount) internal view {
        require(amount % convertRate(poolId) == 0, "Pool: amount is not a multiple of convert rate");
    }

    function _checkPool(uint256 poolId) internal view {
        require(_poolInfo[poolId].enabled, "Pool: pool ID not enabled");
    }

    function _checkDstChain(uint256 poolId, uint16 dstChainId) internal view {
        _checkPool(poolId);
        require(_dstChains[poolId][dstChainId].enabled, "Pool: pool ID or dst chain ID not enabled");
    }

    function getFee(uint256 poolId, uint16 dstChainId) public view returns (uint256) {
        return uint256(_dstChains[poolId][dstChainId].staticFee);
    }

    /// @notice The main function for adding liquidity of ERC20 tokens
    function addLiquidity(uint256 poolId, uint256 amount) public onlyPoolManager nonReentrant {
        _checkPool(poolId);
        _checkConvertRate(poolId, amount);
        IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
        _poolInfo[poolId].balance += amount;
        emit AddLiquidity(poolId, amount);
    }

    /// @notice The main function for adding liquidity of native token
    function addLiquidityETH() public payable onlyPoolManager nonReentrant {
        uint256 poolId = NATIVE_TOKEN_POOL_ID;
        _checkPool(poolId);
        _checkConvertRate(poolId, msg.value);
        _poolInfo[poolId].balance += msg.value;
        emit AddLiquidity(poolId, msg.value);
    }

    /// @notice The main function for adding liquidity of ERC20 tokens without permission
    /// @dev When there are >= 3 chains, maxLiquidity is not enforced so everyone can add liquidity without any problem
    function addLiquidityPublic(uint256 poolId, uint256 amount) external nonReentrant {
        _checkPool(poolId);
        require(
            _poolInfo[poolId].maxLiquidity == type(uint256).max,
            "Pool: addLiquidityPublic only work when maxLiquidity is not limited"
        );
        _checkConvertRate(poolId, amount);
        IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
        _poolInfo[poolId].balance += amount;
        emit AddLiquidity(poolId, amount);
    }

    /// @notice The main function for adding liquidity of native token without permission
    /// @dev When there are >= 3 chains, maxLiquidity is not enforced so everyone can add liquidity without any problem
    function addLiquidityETHPublic() external payable nonReentrant {
        uint256 poolId = NATIVE_TOKEN_POOL_ID;
        _checkPool(poolId);
        require(
            _poolInfo[poolId].maxLiquidity == type(uint256).max,
            "Pool: addLiquidityPublic only work when maxLiquidity is not limited"
        );
        _checkConvertRate(poolId, msg.value);
        _poolInfo[poolId].balance += msg.value;
        emit AddLiquidity(poolId, msg.value);
    }

    /// @notice The main function for removing liquidity
    function removeLiquidity(uint256 poolId, uint256 amount) external onlyPoolManager nonReentrant {
        _checkPool(poolId);
        _checkConvertRate(poolId, amount);
        require(amount <= _poolInfo[poolId].balance);
        if (poolId == NATIVE_TOKEN_POOL_ID) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            IERC20(_poolInfo[poolId].token).safeTransfer(msg.sender, amount);
        }
        _poolInfo[poolId].balance -= amount;
        emit RemoveLiquidity(poolId, amount);
    }

    /// @notice Enable or disable a dstChain for a pool
    function setDstChain(uint256 poolId, uint16 dstChainId, bool enabled) external onlyPoolManager nonReentrant {
        _checkPool(poolId);
        require(_dstChains[poolId][dstChainId].enabled != enabled, "Pool: dst chain already enabled/disabled");
        _dstChains[poolId][dstChainId].enabled = enabled;
        emit DstChainStatusChanged(poolId, dstChainId, enabled);
    }

    /// @notice Set maxLiquidity. See the comments of PoolInfo.maxLiquidity
    function setMaxLiquidity(uint256 poolId, uint256 maxLiquidity) public onlyPoolManager nonReentrant {
        _checkPool(poolId);
        _poolInfo[poolId].maxLiquidity = maxLiquidity;
        emit NewMaxLiquidity(poolId, maxLiquidity);
    }

    /// @notice Adding liquidity and setting maxLiquidity in a single tx
    /// If you add liquidity first and then set maxLiquidity, the maxLiquidity may be reached between the two transactions, making the bridge unusable.
    /// If you raise maxLiquidity first and then add liquidity, a large number of users may use it between the two transactions, resulting in insufficient liquidity.
    /// Therefore, this function is provided to ensure atomicity.
    function addLiquidityAndSetMaxLiquidity(uint256 poolId, uint256 amount, uint256 maxLiquidity) external {
        addLiquidity(poolId, amount);
        setMaxLiquidity(poolId, maxLiquidity);
    }

    function addLiquidityETHAndSetMaxLiquidity(uint256 maxLiquidity) external payable {
        addLiquidityETH();
        setMaxLiquidity(NATIVE_TOKEN_POOL_ID, maxLiquidity);
    }

    function setMaxTransferLimit(uint256 poolId, uint16 dstChainId, uint256 maxTransferLimit)
        external
        onlyPoolManager
        nonReentrant
    {
        _checkDstChain(poolId, dstChainId);
        _dstChains[poolId][dstChainId].maxTransferLimit = maxTransferLimit;
        emit NewMaxTransferLimit(poolId, dstChainId, maxTransferLimit);
    }

    function setStaticFee(uint256 poolId, uint16 dstChainId, uint256 staticFee) external onlyPoolManager nonReentrant {
        _checkDstChain(poolId, dstChainId);
        _dstChains[poolId][dstChainId].staticFee = uint128(staticFee);
        emit NewStaticFee(poolId, dstChainId, staticFee);
    }

    function _deposit(uint256 poolId, uint16 dstChainId, uint256 amount) internal returns (uint256) {
        _checkDstChain(poolId, dstChainId);
        _checkConvertRate(poolId, amount);
        require(
            _poolInfo[poolId].balance + amount <= _poolInfo[poolId].maxLiquidity,
            "Pool: Insufficient liquidity on the target chain"
        );
        require(
            amount <= _dstChains[poolId][dstChainId].maxTransferLimit,
            "Pool: Exceeding the maximum limit of a single transfer"
        );
        _poolInfo[poolId].balance += amount;
        return amount / convertRate(poolId);
    }

    function _withdraw(uint256 poolId, uint16 srcChainId, uint256 amountSD) internal returns (uint256) {
        _checkDstChain(poolId, srcChainId);
        uint256 amount = amountSD * convertRate(poolId);
        require(amount <= _poolInfo[poolId].balance, "Pool: Liquidity shortage");
        _poolInfo[poolId].balance -= amount;
        return amount;
    }

    function accumulatedFees() public view returns (uint256) {
        return address(this).balance - _poolInfo[NATIVE_TOKEN_POOL_ID].balance;
    }

    function claimFees() external onlyPoolManager nonReentrant {
        uint256 fee = accumulatedFees();
        Address.sendValue(payable(msg.sender), fee);
        emit ClaimedFees(msg.sender, fee);
    }

    /// @notice Create a new pool
    /// @param poolId is the new pool ID. It should be NATIVE_TOKEN_POOL_ID for native token and other values for ERC20 tokens
    /// poolId needs to be the same across different chains for the same token
    /// @param token ERC20 token address. Should be address(0) for native token pool
    /// @param convertRateDecimals Should be (local decimals - shared decimals). See the comments of PoolInfo.convertRateDecimals
    function createPool(uint256 poolId, address token, uint8 convertRateDecimals)
        external
        onlyBridgeManager
        nonReentrant
    {
        require(!_poolInfo[poolId].enabled, "Pool: pool already created");
        if (poolId == NATIVE_TOKEN_POOL_ID) {
            require(token == address(0), "Pool: native token pool should not have token address");
        } else {
            require(token != address(0), "Pool: token address should not be zero");
        }
        _poolInfo[poolId].enabled = true;
        _poolInfo[poolId].convertRateDecimals = convertRateDecimals;
        _poolInfo[poolId].token = token;
        _poolInfo[poolId].maxLiquidity = type(uint256).max;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Admin is Initializable {
    address public poolManager;
    address public bridgeManager;
    address public bridgeReviewer; // When bridgeReviewer == bridgeManager, the reviewing step will be skipped.

    // Two-step ownership management design, similar to Ownable2Step in OpenZeppelin Contracts.
    address public pendingPoolManager;
    address public pendingBridgeManager;
    address public pendingBridgeReviewer;

    event PoolManagerTransferStarted(address indexed previousOwner, address indexed newOwner);
    event PoolManagerTransferred(address indexed previousOwner, address indexed newOwner);

    event BridgeManagerTransferStarted(address indexed previousOwner, address indexed newOwner);
    event BridgeManagerTransferred(address indexed previousOwner, address indexed newOwner);

    event BridgeReviewerTransferStarted(address indexed previousOwner, address indexed newOwner);
    event BridgeReviewerTransferred(address indexed previousOwner, address indexed newOwner);

    function __Admin_init() internal onlyInitializing {
        poolManager = msg.sender;
        bridgeManager = msg.sender;
        bridgeReviewer = msg.sender;
    }

    modifier onlyPoolManager() {
        require(msg.sender == poolManager, "Admin: caller is not poolManager");
        _;
    }

    modifier onlyBridgeManager() {
        require(msg.sender == bridgeManager, "Admin: caller is not bridgeManager");
        _;
    }

    modifier onlyBridgeReviewer() {
        require(msg.sender == bridgeReviewer, "Admin: caller is not bridgeReviewer");
        _;
    }

    function transferPoolManager(address newOwner) external onlyPoolManager {
        pendingPoolManager = newOwner;
        emit PoolManagerTransferStarted(msg.sender, newOwner);
    }

    function acceptPoolManager() external {
        require(msg.sender == pendingPoolManager, "Admin: caller is not the new owner");
        delete pendingPoolManager;
        address oldOwner = poolManager;
        poolManager = msg.sender;
        emit PoolManagerTransferred(oldOwner, msg.sender);
    }

    function transferBridgeManager(address newOwner) external onlyBridgeManager {
        pendingBridgeManager = newOwner;
        emit BridgeManagerTransferStarted(msg.sender, newOwner);
    }

    function acceptBridgeManager() external {
        require(msg.sender == pendingBridgeManager, "Admin: caller is not the new owner");
        delete pendingBridgeManager;
        address oldOwner = bridgeManager;
        bridgeManager = msg.sender;
        emit BridgeManagerTransferred(oldOwner, msg.sender);
    }

    function transferBridgeReviewer(address newOwner) external onlyBridgeReviewer {
        pendingBridgeReviewer = newOwner;
        emit BridgeReviewerTransferStarted(msg.sender, newOwner);
    }

    function acceptBridgeReviewer() external {
        require(msg.sender == pendingBridgeReviewer, "Admin: caller is not the new owner");
        delete pendingBridgeReviewer;
        address oldOwner = bridgeReviewer;
        bridgeReviewer = msg.sender;
        emit BridgeReviewerTransferred(oldOwner, msg.sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}