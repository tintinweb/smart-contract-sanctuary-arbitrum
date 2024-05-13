// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Create2.sol)

pragma solidity ^0.8.20;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Not enough balance for performing a CREATE2 deploy.
     */
    error Create2InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev There's no code to deploy.
     */
    error Create2EmptyBytecode();

    /**
     * @dev The deployment failed.
     */
    error Create2FailedDeployment();

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        if (address(this).balance < amount) {
            revert Create2InsufficientBalance(address(this).balance, amount);
        }
        if (bytecode.length == 0) {
            revert Create2EmptyBytecode();
        }
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert Create2FailedDeployment();
        }
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./interfaces/v0.8.x/IAdminACLV0.sol";
import {IAdminACLV0_Extended} from "./interfaces/v0.8.x/IAdminACLV0_Extended.sol";
import "@openzeppelin-4.7/contracts/access/Ownable.sol";
import "@openzeppelin-4.7/contracts/utils/introspection/ERC165.sol";

/**
 * @title Admin ACL contract, V0.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract has a single superAdmin that passes all ACL checks. All checks
 * for any other address will return false.
 * The superAdmin can be changed by the current superAdmin.
 * Care must be taken to ensure that the admin ACL contract is secure behind a
 * multi-sig or other secure access control mechanism.
 */
contract AdminACLV0 is IAdminACLV0, IAdminACLV0_Extended, ERC165 {
    string public AdminACLType = "AdminACLV0";

    /// superAdmin is the only address that passes any and all ACL checks
    address public superAdmin;

    constructor() {
        superAdmin = msg.sender;
    }

    /**
     * @notice Allows superAdmin change the superAdmin address.
     * @param _newSuperAdmin The new superAdmin address.
     * @param _genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     * @dev this function is gated to only superAdmin address.
     */
    function changeSuperAdmin(
        address _newSuperAdmin,
        address[] calldata _genArt721CoreAddressesToUpdate
    ) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        address previousSuperAdmin = superAdmin;
        superAdmin = _newSuperAdmin;
        emit SuperAdminTransferred(
            previousSuperAdmin,
            _newSuperAdmin,
            _genArt721CoreAddressesToUpdate
        );
    }

    /**
     * Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function is gated to only superAdmin address.
     * @dev This implementation requires that the new AdminACL contract
     * broadcasts support of IAdminACLV0 via ERC165 interface detection.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        // ensure new AdminACL contract supports IAdminACLV0
        require(
            ERC165(_newAdminACL).supportsInterface(
                type(IAdminACLV0).interfaceId
            ),
            "AdminACLV0: new admin ACL does not support IAdminACLV0"
        );
        Ownable(_contract).transferOwnership(_newAdminACL);
    }

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function is gated to only superAdmin address.
     */
    function renounceOwnershipOn(address _contract) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        Ownable(_contract).renounceOwnership();
    }

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`. Returns true if sender is superAdmin.
     */
    function allowed(
        address _sender,
        address /*_contract*/,
        bytes4 /*_selector*/
    ) external view returns (bool) {
        return superAdmin == _sender;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IAdminACLV0).interfaceId ||
            // @dev IAdminACLV0_Extended added after original deployments, so do not rely on it
            // being present in all AdminACLV0 contracts.
            interfaceId == type(IAdminACLV0_Extended).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

// @dev fixed to specific solidity version for clarity and for more clear
// source code verification purposes.
pragma solidity 0.8.22;

import {AdminACLV0} from "../../AdminACLV0.sol";
import {IGenArt721CoreContractV3_Engine, EngineConfiguration} from "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Engine.sol";
import {ICoreRegistryV1} from "../../interfaces/v0.8.x/ICoreRegistryV1.sol";
import {IEngineFactoryV0} from "../../interfaces/v0.8.x/IEngineFactoryV0.sol";
import {IAdminACLV0_Extended} from "../../interfaces/v0.8.x/IAdminACLV0_Extended.sol";

import "@openzeppelin-5.0/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin-5.0/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin-5.0/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-5.0/contracts/token/ERC20/utils/SafeERC20.sol";
import {Create2} from "@openzeppelin-5.0/contracts/utils/Create2.sol";

/**
 * @title EngineFactoryV0
 * @author Art Blocks Inc.
 * @notice Factory contract for creating new Engine and Engine Flex Core contracts.
 * @dev This contract is deployed once, and then used to create new Engine and Engine
 * Flex Core contracts. The contract may be abandoned once it is no longer needed.
 * Once abandoned, the contract can no longer be used to create new Engine and Engine
 * Flex Core contracts.
 * The contract is initialized with a required contract type.
 * The contract is initialized with an Engine and Engine Flex implementation contract, which is cloned
 * when creating new Engine and Engine Flex Core contracts.
 */
contract EngineFactoryV0 is Ownable, IEngineFactoryV0 {
    // public type
    bytes32 public constant type_ = "EngineFactoryV0";

    /**
     * The implementation contract that is cloned when creating new Engine
     * contracts.
     */
    address public immutable engineImplementation;
    /**
     * The implementation contract that is cloned when creating new Engine
     * Flex contracts.
     */
    address public immutable engineFlexImplementation;

    // Address of core registry contract.
    address public immutable coreRegistry;

    /// version and type of Engine implementation contract
    string public engineCoreType;
    string public engineCoreVersion;

    /// version and type of Engine Flex implementation contract
    string public flexCoreType;
    string public flexCoreVersion;

    /**
     * Indicates whether the contract is abandoned.
     * Once abandoned, the contract can no longer be used to create new Engine
     * and Engine Flex contracts.
     */
    bool public isAbandoned; // default false

    // pseudorandom salt nonce to prevent collisions for multiple contract deployments in single block
    uint256 private _pseudorandomSaltNonce;

    /**
     * Represents a generic call operation.
     */
    struct Call {
        address to;
        bytes data;
    }

    /**
     * @notice validates and assigns immutable configuration variables and
     * sets state variables
     * @param engineImplementation_ address of the Engine
     * implementation contract
     * @param engineFlexImplementation_ address of the Engine Flex
     * implementation contract
     * @param coreRegistry_ address of the core registry contract
     * @param owner_ address of the initial owner
     */
    constructor(
        address engineImplementation_,
        address engineFlexImplementation_,
        address coreRegistry_,
        address owner_
    ) Ownable(owner_) {
        _onlyNonZeroAddress(engineImplementation_);
        _onlyNonZeroAddress(engineFlexImplementation_);
        _onlyNonZeroAddress(coreRegistry_);
        _onlyNonZeroAddress(owner_);

        engineImplementation = engineImplementation_;
        engineFlexImplementation = engineFlexImplementation_;
        coreRegistry = coreRegistry_;

        engineCoreType = IGenArt721CoreContractV3_Engine(engineImplementation)
            .coreType();
        engineCoreVersion = IGenArt721CoreContractV3_Engine(
            engineImplementation
        ).coreVersion();
        flexCoreType = IGenArt721CoreContractV3_Engine(engineFlexImplementation)
            .coreType();
        flexCoreVersion = IGenArt721CoreContractV3_Engine(
            engineFlexImplementation
        ).coreVersion();

        // emit event
        emit Deployed({
            engineImplementation: engineImplementation_,
            engineFlexImplementation: engineFlexImplementation_,
            type_: type_
        });
    }

    /**
     * @notice Creates a new Engine or Engine Flex contract with the provided
     * `engineConfiguration`, depending on the `engineCoreContractType`.
     * Reverts if invalid configuration is provided, or if in an invalid deployment
     * state (e.g. if the contract is abandoned or does not own the core registry).
     * @param engineCoreContractType Type of Engine Core contract.
     * @param engineConfiguration EngineConfiguration data to configure the
     * contract with.
     * @param adminACLContract Address of admin access control contract, to be
     * set as contract owner. A new contract will be deployed if address is null.
     * @param salt Salt used to deterministically deploy the clone. If null, a
     * pseudorandom salt is generated.
     * @return engineContract The address of the newly created Engine or Engine Flex
     * contract. The address is also emitted in the `EngineContractCreated` event.
     */
    function createEngineContract(
        IEngineFactoryV0.EngineCoreType engineCoreContractType,
        EngineConfiguration calldata engineConfiguration,
        address adminACLContract,
        bytes32 salt
    ) external onlyOwner returns (address engineContract) {
        require(!isAbandoned, "factory is abandoned");
        // validate engine contract configuration
        _onlyNonZeroAddress(engineConfiguration.renderProviderAddress);
        _onlyNonZeroAddress(engineConfiguration.randomizerContract);

        // check if salt is empty and generate a pseudorandom one if so
        if (salt == bytes32(0)) {
            salt = _generatePseudorandomSalt();
        }

        if (adminACLContract == address(0)) {
            _onlyNonZeroAddress(engineConfiguration.newSuperAdminAddress);
            // deploy new AdminACLV0 contract and update super admin
            adminACLContract = Create2.deploy({
                amount: 0,
                salt: _generatePseudorandomSalt(),
                bytecode: type(AdminACLV0).creationCode
            });
            address[] memory tmpEmptyArray = new address[](0);

            IAdminACLV0_Extended(adminACLContract).changeSuperAdmin(
                engineConfiguration.newSuperAdminAddress,
                tmpEmptyArray
            );
        } else {
            // Use existing Admin ACL Contract, newSuperAdminAddress should not be populated
            require(
                engineConfiguration.newSuperAdminAddress == address(0),
                "AdminACL already exists"
            );
        }

        address implementation = engineCoreContractType ==
            IEngineFactoryV0.EngineCoreType.Engine
            ? engineImplementation
            : engineFlexImplementation;

        engineContract = Clones.cloneDeterministic({
            implementation: implementation,
            salt: salt
        });

        IGenArt721CoreContractV3_Engine(engineContract).initialize(
            engineConfiguration,
            adminACLContract
        );

        (
            string memory coreContractType,
            string memory coreContractVersion
        ) = engineCoreContractType == IEngineFactoryV0.EngineCoreType.Engine
                ? (engineCoreType, engineCoreVersion)
                : (flexCoreType, flexCoreVersion);

        // register the new Engine contract
        ICoreRegistryV1(coreRegistry).registerContract(
            engineContract,
            _stringToBytes32(coreContractVersion),
            _stringToBytes32(coreContractType)
        );
        // emit event
        emit EngineContractCreated(engineContract);
    }

    /**
     * @notice Calls transferOwnership on the core registry.
     * Useful for updating the owner of the core registry contract.
     * @param _owner address of the new owner
     */
    function transferCoreRegistryOwnership(address _owner) external onlyOwner {
        Ownable(coreRegistry).transferOwnership(_owner);
    }

    /**
     * @notice Registers multiple contracts with the core registry.
     * @param contractAddresses An array of contract addresses to register.
     * @param coreVersions An array of versions corresponding to the contract addresses.
     * @param coreTypes An array of types corresponding to the contract addresses.
     */
    function registerMultipleContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external onlyOwner {
        // @dev pure forwarding - input validation is done in the core registry
        ICoreRegistryV1(coreRegistry).registerContracts({
            contractAddresses: contractAddresses,
            coreVersions: coreVersions,
            coreTypes: coreTypes
        });
    }

    /**
     * @notice Unregisters multiple contracts from the core registry.
     * @param contractAddresses An array of contract addresses to unregister.
     */
    function unregisterMultipleContracts(
        address[] calldata contractAddresses
    ) external onlyOwner {
        // @dev pure forwarding - input validation is done in the core registry
        ICoreRegistryV1(coreRegistry).unregisterContracts(contractAddresses);
    }

    /**
     * @notice Abandons the contract, preventing it from being used to create
     * new Engine and Engine Flex contracts.
     * Only callable by the owner, and only once; reverts otherwise.
     */
    function abandon() external onlyOwner {
        require(!isAbandoned, "factory is abandoned");
        // set isAbandoned to true
        isAbandoned = true;
        // emit event
        emit Abandoned();
    }

    /**
     * @dev This contract is not intended to hold funds. This function,
     * `drainETH`, and `drainERC20` are implemented to prevent the loss
     * of funds that might be sent to this contract inadvertently.
     */
    receive() external payable {}

    /**
     * @notice Drains the contract's balance to the `recipient`.
     * @param recipient The address to send funds to.
     * Only callable by the owner.
     */
    function drainETH(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = recipient.call{value: balance}("");
            require(success, "Payment failed");
        }
    }

    /**
     * @notice Drains the contract's balance of an input ERC20 token to
     * the `recipient`.
     * @param ERC20TokenAddress The address of the ERC20 token to withdraw.
     * @param recipient The address to send ERC20 tokens to.
     * Only callable by the owner.
     */
    function drainERC20(
        address ERC20TokenAddress,
        address recipient
    ) external onlyOwner {
        IERC20 token = IERC20(ERC20TokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            SafeERC20.safeTransfer({
                token: token,
                to: recipient,
                value: balance
            });
        }
    }

    /**
     * @notice Execute a batch of calls.
     * @dev The calls are executed in order, reverting if any of them fails. Can
     * only be called by the owner. It is safe to check ownership only once here
     * because the owner status is only used to gate access to the function, not
     * to validate each individual call. Even if ownership is transferred during
     * the sequence of calls, it does not affect the execution logic or security,
     * as ownership is solely used to prevent unauthorized use of this batch
     * execution capability. This is particularly useful to safely interact
     * with contracts or addresses that might deem this contract eligible for
     * airdrops, thereby avoiding loss of funds.
     * @param _calls The calls to execute
     */
    function execCalls(
        Call[] calldata _calls
    )
        external
        onlyOwner
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = _calls.length;
        returnData = new bytes[](length);

        for (uint256 i = 0; i < length; ++i) {
            Call calldata calli = _calls[i];

            // check for existence of code at the target address
            if (calli.to.code.length == 0) {
                // when the call is to an EOA, the calldata must be empty.
                require(calli.data.length == 0, "Invalid call data");
            }

            (bool success, bytes memory data) = calli.to.call(calli.data);
            require(success, string(data));
            returnData[i] = data;
        }
    }

    /**
     * @dev Predict the deterministic address for a new core contract of type
     * `engineCoreContractType` and salt `salt`, deployed using the function
     * `createEngineContract`.
     * Reverts if `salt` is null, because the factory generates a pseudorandom
     * salt in that case.
     * @param engineCoreContractType Type of Engine Core contract.
     * @param salt Salt used to deterministically deploy the clone.
     */
    function predictDeterministicAddress(
        IEngineFactoryV0.EngineCoreType engineCoreContractType,
        bytes32 salt
    ) external view returns (address predicted) {
        // cannot predict if salt is null, because factory generates pseudorandom salt
        if (salt == bytes32(0)) {
            revert("null salt = pseudorandom addr");
        }
        return
            Clones.predictDeterministicAddress({
                implementation: engineCoreContractType ==
                    IEngineFactoryV0.EngineCoreType.Engine
                    ? engineImplementation
                    : engineFlexImplementation,
                salt: salt
            });
    }

    /**
     * @notice helper function to generate a pseudorandom salt
     * @return result pseudorandom salt
     */
    function _generatePseudorandomSalt() internal returns (bytes32 result) {
        // get and increment nonce to prevent same-block collisions
        uint256 nonce = _pseudorandomSaltNonce++;
        return
            keccak256(
                abi.encodePacked(
                    nonce,
                    block.timestamp,
                    block.number,
                    address(this)
                )
            );
    }

    /**
     * @notice helper function to convert a string to a bytes32.
     * Caution: This function only works properly for short strings.
     * @param source string to convert
     * @return result bytes32 representation of the string
     */
    function _stringToBytes32(
        string memory source
    ) internal pure returns (bytes32 result) {
        bytes memory tempString = bytes(source);
        if (tempString.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @notice helper function to validate that an address is non-zero.
     * Reverts if the address is zero.
     * @param address_ address to validate
     */
    function _onlyNonZeroAddress(address address_) internal pure {
        require(address_ != address(0), "Must input non-zero address");
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";

interface IAdminACLV0_Extended is IAdminACLV0 {
    /**
     * @notice Allows superAdmin change the superAdmin address.
     * @param _newSuperAdmin The new superAdmin address.
     * @param _genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     * @dev this function is gated to only superAdmin address.
     */
    function changeSuperAdmin(
        address _newSuperAdmin,
        address[] calldata _genArt721CoreAddressesToUpdate
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

import "./IEngineRegistryV0.sol";

interface ICoreRegistryV1 is IEngineRegistryV0 {
    function registerContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external;

    function unregisterContracts(address[] calldata contractAddresses) external;

    function getNumRegisteredContracts() external view returns (uint256);

    function getRegisteredContractAt(
        uint256 index
    ) external view returns (address);

    function isRegisteredContract(
        address contractAddress
    ) external view returns (bool isRegistered);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {EngineConfiguration} from "./IGenArt721CoreContractV3_Engine.sol";

interface IEngineFactoryV0 {
    /// @notice Engine Core type
    enum EngineCoreType {
        Engine, // GenArt721CoreV3_Engine Contract
        EngineFlex // GenArt721CoreV3_Engine_Flex Contract
    }
    /**
     * @notice This contract was deployed.
     * @param engineImplementation address with the implementation of the Engine contract
     * @param engineFlexImplementation address with the implementation of the Engine Flex contract
     * @param type_ type of this contract
     */
    event Deployed(
        address indexed engineImplementation,
        address indexed engineFlexImplementation,
        bytes32 indexed type_
    );
    /**
     * @notice New Engine or Engine Flex contract was created.
     * @param engineContract address of the newly created Engine contract
     */
    event EngineContractCreated(address indexed engineContract);
    /**
     * @notice This contract was abandoned and no longer can be used to create
     * new Engine or Engine Flex contracts.
     */
    event Abandoned();

    /**
     * @notice Creates a new Engine or Engine Flex contract with the provided
     * `engineConfiguration`, depending on the `engineCoreContractType`.
     * @param engineCoreContractType Type of Engine Core contract.
     * @param engineConfiguration EngineConfiguration data to configure the
     * contract with.
     * @param adminACLContract Address of admin access control contract, to be
     * set as contract owner. A new contract will be deployed if address is null.
     * @param salt Salt used to deterministically deploy the clone.
     * @return engineContract The address of the newly created Engine or Engine Flex
     * contract. The address is also emitted in both the `EngineCreated` and
     * `EngineFlexCreated` events.
     */
    function createEngineContract(
        EngineCoreType engineCoreContractType,
        EngineConfiguration calldata engineConfiguration,
        address adminACLContract,
        bytes32 salt
    ) external returns (address engineContract);

    /**
     * @notice Drains the contract's balance to the `recipient`.
     * @param recipient The address to send funds to.
     * Only callable by the owner.
     */
    function drainETH(address payable recipient) external;

    /**
     * @notice Drains the contract's balance of an input ERC20 token to
     * the `recipient`.
     * @param ERC20TokenAddress The address of the ERC20 token to withdraw.
     * @param recipient The address to send ERC20 tokens to.
     * Only callable by the owner.
     */
    function drainERC20(address ERC20TokenAddress, address recipient) external;

    /**
     * @notice Calls transferOwnership on the core registry.
     * Useful for updating the owner of the core registry contract.
     * @param _owner address of the new owner
     */
    function transferCoreRegistryOwnership(address _owner) external;

    /**
     * @notice Registers multiple contracts with the core registry.
     * @param contractAddresses An array of contract addresses to register.
     * @param coreVersions An array of versions corresponding to the contract addresses.
     * @param coreTypes An array of types corresponding to the contract addresses.
     */
    function registerMultipleContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external;

    /**
     * @notice Unregisters multiple contracts from the core registry.
     * @param contractAddresses An array of contract addresses to unregister.
     */
    function unregisterMultipleContracts(
        address[] calldata contractAddresses
    ) external;

    /**
     * @notice The implementation contract that is cloned when creating new
     * Engine Core contracts.
     */
    function engineImplementation() external view returns (address);

    /**
     * @notice The implementation contract that is cloned when creating new
     * Engine Flex Core contracts.
     */
    function engineFlexImplementation() external view returns (address);

    /**
     * @notice Indicates whether the contract is abandoned.
     * Once abandoned, the contract can no longer be used to create new Engine
     * or Engine Flex contracts.
     * @return bool True if the contract is abandoned, false otherwise.
     */
    function isAbandoned() external view returns (bool);

    /**
     * @notice Indicates the type of the contract, e.g. `EngineFactoryV0`.
     * @return type_ The type of the contract.
     */
    function type_() external pure returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

interface IEngineRegistryV0 {
    /// ADDRESS
    /**
     * @notice contract has been registered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractRegistered(
        address indexed _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    );

    /// ADDRESS
    /**
     * @notice contract has been unregistered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractUnregistered(address indexed _contractAddress);

    /**
     * @notice Emits a `ContractRegistered` event with the provided information.
     * @dev this function should be gated to only deployer addresses.
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external;

    /**
     * @notice Emits a `ContractUnregistered` event with the provided information, validating that the provided
     *         address was indeed previously registered.
     * @dev this function should be gated to only deployer addresses.
     */
    function unregisterContract(address _contractAddress) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base {
    // This interface emits generic events that contain fields that indicate
    // which parameter has been updated. This is sufficient for application
    // state management, while also simplifying the contract and indexing code.
    // This was done as an alternative to having custom events that emit what
    // field-values have changed for each event, given that changed values can
    // be introspected by indexers due to the design of this smart contract
    // exposing these state changes via publicly viewable fields.

    /**
     * @notice Project's royalty splitter was updated to `_splitter`.
     * @dev New event in v3.2
     * @param projectId The project ID.
     * @param royaltySplitter The new splitter address to receive royalties.
     */
    event ProjectRoyaltySplitterUpdated(
        uint256 indexed projectId,
        address indexed royaltySplitter
    );

    // The following fields are used to indicate which contract-level parameter
    // has been updated in the `PlatformUpdated` event:
    // @dev only append to the end of this enum in the case of future updates
    enum PlatformUpdatedFields {
        FIELD_NEXT_PROJECT_ID, // 0
        FIELD_NEW_PROJECTS_FORBIDDEN, // 1
        FIELD_DEFAULT_BASE_URI, // 2
        FIELD_RANDOMIZER_ADDRESS, // 3
        FIELD_NEXT_CORE_CONTRACT, // 4
        FIELD_ARTBLOCKS_DEPENDENCY_REGISTRY_ADDRESS, // 5
        FIELD_ARTBLOCKS_ON_CHAIN_GENERATOR_ADDRESS, // 6
        FIELD_PROVIDER_SALES_ADDRESSES, // 7
        FIELD_PROVIDER_PRIMARY_SALES_PERCENTAGES, // 8
        FIELD_PROVIDER_SECONDARY_SALES_BPS, // 9
        FIELD_SPLIT_PROVIDER // 10
    }

    // The following fields are used to indicate which project-level parameter
    // has been updated in the `ProjectUpdated` event:
    // @dev only append to the end of this enum in the case of future updates
    enum ProjectUpdatedFields {
        FIELD_PROJECT_COMPLETED, // 0
        FIELD_PROJECT_ACTIVE, // 1
        FIELD_PROJECT_ARTIST_ADDRESS, // 2
        FIELD_PROJECT_PAUSED, // 3
        FIELD_PROJECT_CREATED, // 4
        FIELD_PROJECT_NAME, // 5
        FIELD_PROJECT_ARTIST_NAME, // 6
        FIELD_PROJECT_SECONDARY_MARKET_ROYALTY_PERCENTAGE, // 7
        FIELD_PROJECT_DESCRIPTION, // 8
        FIELD_PROJECT_WEBSITE, // 9
        FIELD_PROJECT_LICENSE, // 10
        FIELD_PROJECT_MAX_INVOCATIONS, // 11
        FIELD_PROJECT_SCRIPT, // 12
        FIELD_PROJECT_SCRIPT_TYPE, // 13
        FIELD_PROJECT_ASPECT_RATIO, // 14
        FIELD_PROJECT_BASE_URI, // 15
        FIELD_PROJECT_PROVIDER_SECONDARY_FINANCIALS // 16
    }

    /**
     * @notice Error codes for the GenArt721 contract. Used by the GenArt721Error
     * custom error.
     * @dev only append to the end of this enum in the case of future updates
     */
    enum ErrorCodes {
        OnlyNonZeroAddress, // 0
        OnlyNonEmptyString, // 1
        OnlyNonEmptyBytes, // 2
        TokenDoesNotExist, // 3
        ProjectDoesNotExist, // 4
        OnlyUnlockedProjects, // 5
        OnlyAdminACL, // 6
        OnlyArtist, // 7
        OnlyArtistOrAdminACL, // 8
        OnlyAdminACLOrRenouncedArtist, // 9
        OnlyMinterContract, // 10
        MaxInvocationsReached, // 11
        ProjectMustExistAndBeActive, // 12
        PurchasesPaused, // 13
        OnlyRandomizer, // 14
        TokenHashAlreadySet, // 15
        NoZeroHashSeed, // 16
        OverMaxSumOfPercentages, // 17
        IndexOutOfBounds, // 18
        OverMaxSumOfBPS, // 19
        MaxOf100Percent, // 20
        PrimaryPayeeIsZeroAddress, // 21
        SecondaryPayeeIsZeroAddress, // 22
        MustMatchArtistProposal, // 23
        NewProjectsForbidden, // 24
        NewProjectsAlreadyForbidden, // 25
        OnlyArtistOrAdminIfLocked, // 26
        OverMaxSecondaryRoyaltyPercentage, // 27
        OnlyMaxInvocationsDecrease, // 28
        OnlyGteInvocations, // 29
        ScriptIdOutOfRange, // 30
        NoScriptsToRemove, // 31
        ScriptTypeAndVersionFormat, // 32
        AspectRatioTooLong, // 33
        AspectRatioNoNumbers, // 34
        AspectRatioImproperFormat, // 35
        OnlyNullPlatformProvider, // 36
        ContractInitialized // 37
    }

    /**
     * @notice Emits an error code `_errorCode` in the GenArt721Error event.
     * @dev Emitting error codes instead of error strings saves significant
     * contract bytecode size, allowing for more contract functionality within
     * the 24KB contract size limit.
     * @param _errorCode The error code to emit. See ErrorCodes enum.
     */
    error GenArt721Error(ErrorCodes _errorCode);

    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    /// getter function of public variable
    function startingProjectId() external view returns (uint256);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );

    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

/**
 * @notice Struct representing Engine contract configuration.
 * @param tokenName Name of token.
 * @param tokenSymbol Token symbol.
 * @param renderProviderAddress address to send render provider revenue to
 * @param randomizerContract Randomizer contract.
 * @param splitProviderAddress Address to use as royalty splitter provider for the contract.
 * @param minterFilterAddress Address of the Minter Filter to set as the Minter
 * on the contract.
 * @param startingProjectId The initial next project ID.
 * @param autoApproveArtistSplitProposals Whether or not to always
 * auto-approve proposed artist split updates.
 * @param nullPlatformProvider Enforce always setting zero platform provider fees and addresses.
 * @param allowArtistProjectActivation Allow artist to activate their own projects.
 * @dev _startingProjectId should be set to a value much, much less than
 * max(uint248), but an explicit input type of `uint248` is used as it is
 * safer to cast up to `uint256` than it is to cast down for the purposes
 * of setting `_nextProjectId`.
 */
struct EngineConfiguration {
    string tokenName;
    string tokenSymbol;
    address renderProviderAddress;
    address platformProviderAddress;
    address newSuperAdminAddress;
    address randomizerContract;
    address splitProviderAddress;
    address minterFilterAddress;
    uint248 startingProjectId;
    bool autoApproveArtistSplitProposals;
    bool nullPlatformProvider;
    bool allowArtistProjectActivation;
}

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3.2
    /**
     * @notice Initializes the contract with the provided `engineConfiguration`.
     * This function should be called atomically, immediately after deployment.
     * Only callable once. Validation on `engineConfiguration` is performed by caller.
     * @param engineConfiguration EngineConfiguration to configure the contract with.
     * @param adminACLContract_ Address of admin access control contract, to be
     * set as contract owner.
     */
    function initialize(
        EngineConfiguration calldata engineConfiguration,
        address adminACLContract_
    ) external;

    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    /** @notice The default render provider payment address for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default render provider payment address for secondary sales royalties.
     */
    function defaultRenderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    /** @notice The default platform provider payment address for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default platform provider payment address for secondary sales royalties.
     */
    function defaultPlatformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    /** @notice The default render provider payment basis points for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default render provider payment basis points for secondary sales royalties.
     */
    function defaultRenderProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    /** @notice The default platform provider payment basis points for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default platform provider payment basis points for secondary sales royalties.
     */
    function defaultPlatformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);
}