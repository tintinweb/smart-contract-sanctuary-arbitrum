// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

// @dev unable to inherit ERC20 because the OFTAdapter needs to use this interface as well
interface IOFT {
    struct SendParam {
        bytes32 to;
        uint amountLD;
        uint minAmountLD;
        uint32 dstEid;
    }

    error LDMinusSD();
    error AmountSlippage(uint _amountLDSend, uint256 _minAmountLD);

    event SetInspector(address _inspector);
    event SendOFT(bytes32 indexed _guid, address indexed _fromAddress, uint _amountLD, bytes _composeMsg);
    event ReceiveOFT(bytes32 indexed _guid, address indexed _toAddress, uint _amountLD);

    function token() external view returns (address);

    function quoteSendFee(
        SendParam calldata _send,
        bytes calldata _options,
        bool _useLZToken,
        bytes calldata _composeMsg
    ) external view returns (uint nativeFee, uint lzTokenFee);

    function send(
        SendParam calldata _send,
        bytes calldata _options,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable returns (MessagingReceipt memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

struct PacketForQuote {
    address sender;
    uint32 dstEid;
    bytes message;
}

struct Packet {
    uint64 nonce;
    uint32 srcEid;
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    bytes32 guid;
    bytes message;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IMessageLibManager.sol";
import "./IMessagingComposer.sol";
import "./IMessagingChannel.sol";
import "./IMessagingContext.sol";
import {Origin} from "../MessagingStructs.sol";

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint nativeFee;
    uint lzTokenFee;
}

interface ILayerZeroEndpointV2 is IMessageLibManager, IMessagingComposer, IMessagingChannel, IMessagingContext {
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketDelivered(Origin origin, address receiver, bytes32 payloadHash);

    event PacketReceived(Origin origin, address receiver);

    event LzReceiveFailed(Origin origin, address receiver, bytes reason);

    event LayerZeroTokenSet(address token);

    function quote(
        address _sender,
        uint32 _dstEid,
        bytes calldata _message,
        bool _payInLzToken,
        bytes calldata _options
    ) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        uint _lzTokenFee,
        address payable _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function sendWithAlt(
        MessagingParams calldata _params,
        uint _lzTokenFee,
        uint _altTokenFee
    ) external returns (MessagingReceipt memory);

    function deliver(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function deliverable(Origin calldata _origin, address _receiveLib, address _receiver) external view returns (bool);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable returns (bool, bytes memory);

    // oapp can burn messages partially by calling this function with its own business logic if messages are delivered in order
    function clear(Origin calldata _origin, bytes32 _guid, bytes calldata _message) external;

    function setLayerZeroToken(address _layerZeroToken) external;

    function layerZeroToken() external view returns (address);

    function altFeeToken() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address oldLib, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address oldLib, address newLib);
    event ReceiveLibraryTimoutSet(address receiver, uint32 eid, address oldLib, uint timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint _timeout) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint expiry);

    function defaultConfig(address _lib, uint32 _eid, uint32 _configType) external view returns (bytes memory);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(uint32 _eid, address _newLib, uint _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(uint32 _eid, address _lib, uint _gracePeriod) external;

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint expiry);

    function setConfig(address _lib, uint32 _eid, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config, bool isDefault);

    function snapshotConfig(address _lib, uint32[] calldata _eids) external;

    function resetConfig(address _lib, uint32[] calldata _eids) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingChannel {
    event InboundNonceSkipped(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce);

    function eid() external view returns (uint32);

    // this is an emergency function if a message can not be delivered for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(uint32 _srcEid, bytes32 _sender, uint64 _nonce) external;

    function nextGuid(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (bytes32);

    function inboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);

    function outboundNonce(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (uint64);

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    function hasPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingComposer {
    event ComposedMessageDelivered(address receiver, address composer, bytes32 guid, bytes message);
    event ComposedMessageReceived(address receiver, address composer, bytes32 guid);
    event LzComposeFailed(address receiver, address composer, bytes32 guid, bytes reason);

    function deliverComposedMessage(address _composer, bytes32 _guid, bytes calldata _message) external;

    function lzCompose(
        address _receiver,
        address _composer,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable returns (bool, bytes memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32, address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

// lp contract for converting other stable coins to USDV
interface IToUSDVLp {
    function getSupportedTokens() external view returns (address[] memory tokens);

    function swapToUSDV(
        address _fromToken,
        uint _fromTokenAmount,
        uint64 _minUSDVOut,
        address _receiver
    ) external returns (uint usdvOut);

    function getUSDVOut(address _fromToken, uint _fromTokenAmount) external view returns (uint usdvOut);

    function getUSDVOutVerbose(
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint requestedOut, uint rewardOut);
}

// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../mm/interfaces/IToUSDVLp.sol";

import "./SwapRecolor.sol";

// 1/ this contract swaps X stable coin to USDV and send it to recolorHelper
// 2/ then use the recolorHelper to send out the usdv
// 3/ it assert the color to be bridge color
contract BridgeRecolor is SwapRecolor, Ownable {
    using SafeERC20 for IERC20;

    uint8 internal constant USDV_DECIMALS = 6;

    IToUSDVLp public lp;
    uint32 public color; // the target color for recoloring
    uint16 public userRewardBps;
    uint16 public toleranceBps;

    constructor(
        address _lp,
        uint32 _color,
        address _recolorHelper,
        address _usdv,
        uint16 _userRewardBps,
        uint16 _toleranceBps
    ) SwapRecolor(_recolorHelper, _usdv) {
        lp = IToUSDVLp(_lp);
        color = _color;
        userRewardBps = _userRewardBps;
        toleranceBps = _toleranceBps;
    }

    // owner sets lp address
    function setLpAddress(address _lp) external onlyOwner {
        lp = IToUSDVLp(_lp);
    }

    function setUserRewardBps(uint16 _userRewardBps) external onlyOwner {
        userRewardBps = _userRewardBps;
    }

    function setColor(uint32 _color) external onlyOwner {
        color = _color;
    }

    function setToleranceBps(uint16 _toleranceBps) external onlyOwner {
        toleranceBps = _toleranceBps;
    }

    function withdrawUSDV(address _to, uint _amount) external onlyOwner {
        usdv.safeTransfer(_to, _amount);
    }

    /// @dev only can recolor to the color set by the owner
    function swapRecolorTransfer(
        SwapParam calldata _swapParam,
        address _receiver,
        uint32 /*_toColor*/
    ) public override returns (uint usdvOut) {
        usdvOut = super.swapRecolorTransfer(_swapParam, _receiver, color);
    }

    /// @dev only can recolor to the color set by the owner
    function swapRecolorSend(
        SwapParam calldata _swapParam,
        uint32 /*_toColor*/,
        IOFT.SendParam memory _param, // need to change the amountLD
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) public payable override returns (uint usdvOut, MessagingReceipt memory msgReceipt) {
        (usdvOut, msgReceipt) = super.swapRecolorSend(
            _swapParam,
            color,
            _param,
            _extraOptions,
            _msgFee,
            _refundAddress,
            _composeMsg
        );
    }

    function _swap(SwapParam calldata _param) internal override returns (uint usdvOut) {
        // approve the lp to spend the token
        IERC20(_param._fromToken).forceApprove(address(lp), _param._fromTokenAmount);
        uint beforeUSDVBalance = usdv.balanceOf(address(this));
        uint usdvSwapped = lp.swapToUSDV(_param._fromToken, _param._fromTokenAmount, _param._minUSDVOut, address(this));

        // cross-check with balance to make sure that lp is behaving as expected
        uint afterUSDVBalance = usdv.balanceOf(address(this));
        require(afterUSDVBalance - beforeUSDVBalance == usdvSwapped, "BridgeRecolor: swap amount too low");

        usdvOut = _getUSDVOut(_param._fromToken, _param._fromTokenAmount);
        require(afterUSDVBalance >= usdvOut, "BridgeRecolor: not enough usdv");
        if (usdvOut > usdvSwapped) {
            require(usdvOut - usdvSwapped <= (usdvOut * toleranceBps) / 10000, "BridgeRecolor: exceeds tolerance");
        }
        // slippage assertion
        require(usdvOut >= _param._minUSDVOut, "BridgeRecolor: swap amount too low");
    }

    // view function for supported tokens of the lp
    function getSupportedTokens() external view returns (address[] memory tokens) {
        return lp.getSupportedTokens();
    }

    // view function for estimating output
    function getUSDVOut(address _fromToken, uint _fromTokenAmount) external view returns (uint usdvOut) {
        usdvOut = _getUSDVOut(_fromToken, _fromTokenAmount);
        uint usdvFromLp = lp.getUSDVOut(_fromToken, _fromTokenAmount);
        require(usdv.balanceOf(address(this)) + usdvFromLp >= usdvOut, "BridgeRecolor: not enough usdv");
        if (usdvOut > usdvFromLp) {
            require(usdvOut - usdvFromLp <= (usdvOut * toleranceBps) / 10000, "BridgeRecolor: exceeds tolerance");
        }
    }

    function getUSDVOutVerbose(
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint usdvOut, uint fee, uint reward) {
        uint8 tokenDecimals = IERC20Metadata(_fromToken).decimals();
        require(tokenDecimals >= USDV_DECIMALS, "BridgeRecolor: token decimals must >= 6");
        uint usdvRequested = _fromTokenAmount / (10 ** (tokenDecimals - USDV_DECIMALS));

        fee = 0;
        reward = (usdvRequested * userRewardBps) / 10000;
        usdvOut = usdvRequested + reward;

        uint usdvFromLp = lp.getUSDVOut(_fromToken, _fromTokenAmount);
        require(usdv.balanceOf(address(this)) + usdvFromLp >= usdvOut, "BridgeRecolor: not enough usdv");
        if (usdvOut > usdvFromLp) {
            require(usdvOut - usdvFromLp <= (usdvOut * toleranceBps) / 10000, "BridgeRecolor: exceeds tolerance");
        }
    }

    function _getUSDVOut(address _fromToken, uint _fromTokenAmount) internal view returns (uint usdvOut) {
        uint8 tokenDecimals = IERC20Metadata(_fromToken).decimals();
        require(tokenDecimals >= USDV_DECIMALS, "BridgeRecolor: token decimals must >= 6");
        uint usdvRequested = _fromTokenAmount / (10 ** (tokenDecimals - USDV_DECIMALS));
        usdvOut = usdvRequested + (usdvRequested * userRewardBps) / 10000;
    }
}

// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IRecolorHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// this contract is generic for partner to perform stable coin swap into USDV and use recolorHelper to send out
// example 1: deploy as a generic help built on recolor helper for any protocols to swap into the provided color
// example 2: inherited by a specific protocol and only swap into the preconfigured color by asserting the toColor == myColor
abstract contract SwapRecolor is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct SwapParam {
        address _fromToken;
        uint _fromTokenAmount;
        uint64 _minUSDVOut;
    }

    IRecolorHelper public immutable recolorHelper;
    IERC20 public immutable usdv;

    constructor(address _recolorHelper, address _usdv) {
        recolorHelper = IRecolorHelper(_recolorHelper);
        usdv = IERC20(_usdv);
    }

    /// @dev do swap and then transfer out with color through recolorHelper
    function swapRecolorTransfer(
        SwapParam calldata _swapParam,
        address _receiver,
        uint32 _toColor
    ) public virtual nonReentrant returns (uint usdvOut) {
        // get the token from msg.sender
        IERC20(_swapParam._fromToken).safeTransferFrom(msg.sender, address(this), _swapParam._fromTokenAmount);
        // do the swap and send the token to recolorHelper
        usdvOut = _swap(_swapParam);
        // send out through recolorHelper
        usdv.approve(address(recolorHelper), usdvOut);
        recolorHelper.approvedTransferWithColor(_receiver, usdvOut, _toColor);
    }

    /// @dev do swap and then transfer out with color through recolorHelper
    function swapRecolorSend(
        SwapParam calldata _swapParam,
        uint32 _toColor,
        IOFT.SendParam memory _param, // need to change the amountLD
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) public payable virtual nonReentrant returns (uint usdvOut, MessagingReceipt memory msgReceipt) {
        // get the token from msg.sender
        IERC20(_swapParam._fromToken).safeTransferFrom(msg.sender, address(this), _swapParam._fromTokenAmount);
        // do the swap and send the token to recolorHelper
        usdvOut = _swap(_swapParam);
        // override this with the swap output
        _param.amountLD = usdvOut;
        // send out through recolorHelper
        usdv.approve(address(recolorHelper), usdvOut);
        msgReceipt = recolorHelper.approvedSendWithColor{value: msg.value}(
            _param,
            _toColor,
            _extraOptions,
            _msgFee,
            _refundAddress,
            _composeMsg
        );
    }

    // can override this function on different chains to connect to different dex
    function _swap(SwapParam calldata _param) internal virtual returns (uint usdvOut);
}

// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/oft/interfaces/IOFT.sol";

interface IRecolorHelper {
    /// ------ local transfer function -----

    /// @dev send USDV into this account and then ATOMICALLY transfer out with color
    function transferWithColor(address _receiver, uint256 _amount, uint32 _toColor) external;

    /// @dev it requires the caller to approve this contract to spend their USDV
    function approvedTransferWithColor(address _receiver, uint256 _amount, uint32 _toColor) external;

    /// ------ crosschain transfer function transfer function -----

    /// @dev send USDV into this account and then ATOMICALLY send across-chain
    function sendWithColor(
        IOFT.SendParam calldata _param,
        uint32 _toColor,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable returns (MessagingReceipt memory);

    /// @dev it requires the caller to approve this contract to spend their USDV
    function approvedSendWithColor(
        IOFT.SendParam calldata _param,
        uint32 _toColor,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable returns (MessagingReceipt memory);
}