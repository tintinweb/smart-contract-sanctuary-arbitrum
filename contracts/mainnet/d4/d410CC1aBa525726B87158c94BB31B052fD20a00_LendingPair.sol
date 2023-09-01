// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

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
 *
 * _Available since v3.4._
 */
library Clones {
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
        require(instance != address(0), "ERC1167: create failed");
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
        require(instance != address(0), "ERC1167: create2 failed");
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICallee {
    function wildCall(bytes calldata _data) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./IOwnable.sol";
import "./IUnifiedOracleAggregator.sol";

interface ILendingController is IOwnable {
    function oracleAggregator()
        external
        view
        returns (IUnifiedOracleAggregator);

    function liqFeeSystem(address _token) external view returns (uint256);

    function liqFeeCaller(address _token) external view returns (uint256);

    function colFactor(address _token) external view returns (uint256);

    function defaultColFactor() external view returns (uint256);

    function depositLimit(
        address _lendingPair,
        address _token
    ) external view returns (uint256);

    function borrowLimit(
        address _lendingPair,
        address _token
    ) external view returns (uint256);

    function tokenPrice(address _token) external view returns (uint256);

    function minBorrow(address _token) external view returns (uint256);

    function tokenPrices(
        address _tokenA,
        address _tokenB
    ) external view returns (uint256, uint256);

    function tokenSupported(address _token) external view returns (bool);

    function hasChainlinkOracle(address _token) external view returns (bool);

    function isBaseAsset(address _token) external view returns (bool);

    function minObservationCardinalityNext() external view returns (uint16);

    function preparePool(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface ILendingPair {
    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function lpToken(address _token) external view returns (address);

    function transferLp(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function supplySharesOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function totalSupplyShares(address _token) external view returns (uint256);

    function totalSupplyAmount(address _token) external view returns (uint256);

    function totalDebtShares(address _token) external view returns (uint256);

    function totalDebtAmount(address _token) external view returns (uint256);

    function debtOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function supplyOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function pendingSystemFees(address _token) external view returns (uint256);

    function supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken
    ) external view returns (uint256);

    function initialize(
        address _lpTokenMaster,
        address _lendingController,
        address _feeRecipient,
        address _tokenA,
        address _tokenB
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./IOwnable.sol";

interface ILPTokenMaster is IOwnable, IERC20Metadata {
    function initialize(
        address _underlying,
        address _lendingController
    ) external;

    function underlying() external view returns (address);

    function lendingPair() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
interface IUnifiedOracleAggregator {
    function linkOracles(address) external view returns (address);

    function setOracle(address, AggregatorV3Interface) external;

    function preparePool(address, address, uint16) external;

    function tokenSupported(address) external view returns (bool);

    function tokenPrice(address) external view returns (uint256);

    function tokenPrices(
        address,
        address
    ) external view returns (uint256, uint256);

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IWETH is IERC20Metadata {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import "./LPTokenMaster.sol";
import "./TransferHelper.sol";
import "./LendingPairEvents.sol";

import "./interfaces/ICallee.sol";
import "./interfaces/ILendingPair.sol";
import "./interfaces/ILPTokenMaster.sol";
import "./interfaces/ILendingController.sol";

/// @title Lending Pair Contract
/// @author 0xdev and flora.loans
/// @notice This contract contains all functionality of an effective LendingPair, including deposit, borrow, withdraw and the liquidation mechanism

contract LendingPair is
    ILendingPair,
    LendingPairEvents,
    ReentrancyGuard,
    TransferHelper
{
    using Address for address;
    using Clones for address;

    struct InterestRateModel {
        uint256 lpRate;
        uint256 minRate;
        uint256 lowRate;
        uint256 highRate;
        uint256 targetUtilization;
    }

    struct AccountingData {
        uint256 totalSupplyShares;
        uint256 totalSupplyAmount;
        uint256 totalDebtShares;
        uint256 totalDebtAmount;
        mapping(address token => uint256) supplySharesOf;
        mapping(address token => uint256) debtSharesOf;
    }

    /// CONSTANTS
    uint256 public constant LIQ_MIN_HEALTH = 1e18;
    uint256 private constant MIN_DECIMALS = 6;
    address public feeRecipient;
    ILendingController public lendingController;

    /// Token related
    address public override tokenA;
    address public override tokenB;
    mapping(address token => uint256) private _decimals;
    mapping(address token => uint256) public colFactor;
    mapping(address token => address) public override lpToken;
    mapping(address token => uint256) public override pendingSystemFees;
    mapping(address token => uint256) public lastBlockAccrued;

    /// Protocol
    InterestRateModel public irm;
    mapping(address token => AccountingData) internal _accounting;

    /// Modifier
    modifier onlyLpToken() {
        require(
            lpToken[tokenA] == msg.sender || lpToken[tokenB] == msg.sender,
            "LendingController: caller must be LP token"
        );
        _;
    }
    modifier onlyOwner() {
        require(
            msg.sender == lendingController.owner(),
            "LendingPair: caller is not the owner"
        );
        _;
    }

    constructor(IWETH _WETH) TransferHelper(_WETH) {}

    /// =======================================================================
    /// ======================= INIT ==========================================
    /// =======================================================================

    /// @notice called once by the PairFactory after the creation of a new Pair
    /// @param _lpTokenMaster address to the implementation
    /// @param _lendingController LendingController
    /// @param _feeRecipient receiver of protocol fees
    /// @param _tokenA first pair token (base asset)
    /// @param _tokenB second pair token (user asset)
    function initialize(
        address _lpTokenMaster,
        address _lendingController,
        address _feeRecipient,
        address _tokenA,
        address _tokenB
    ) external override {
        require(tokenA == address(0), "LendingPair: already initialized");

        lendingController = ILendingController(_lendingController);

        feeRecipient = _feeRecipient;
        tokenA = _tokenA;
        tokenB = _tokenB;
        lastBlockAccrued[tokenA] = block.number;
        lastBlockAccrued[tokenB] = block.number;

        _decimals[tokenA] = IERC20Metadata(tokenA).decimals();
        _decimals[tokenB] = IERC20Metadata(tokenB).decimals();

        require(
            _decimals[tokenA] >= MIN_DECIMALS &&
                _decimals[tokenB] >= MIN_DECIMALS,
            "LendingPair: MIN_DECIMALS"
        );

        lpToken[tokenA] = _createLpToken(_lpTokenMaster, tokenA);
        lpToken[tokenB] = _createLpToken(_lpTokenMaster, tokenB);

        // Setting the collateral factor
        uint256 colFactorTokenA = lendingController.colFactor(_tokenA);
        uint256 colFactorTokenB = lendingController.colFactor(_tokenB);
        uint256 defaultCollateralFactor = lendingController.defaultColFactor();

        colFactor[_tokenA] = colFactorTokenA != 0
            ? colFactorTokenA
            : defaultCollateralFactor;
        colFactor[_tokenB] = colFactorTokenB != 0
            ? colFactorTokenB
            : defaultCollateralFactor;

        // Initialize Interest rate model
        // Need to check then if calculations still match with new units
        irm.lpRate = 70e18; // Percentage of debt-interest received by the suppliers
        irm.minRate = 0;
        irm.lowRate = 7_642_059_868_087; // 20%
        irm.highRate = 382_102_993_404_363; // 1,000%
        irm.targetUtilization = 90e18; // Must be < 100e18;
    }

    ///
    ///
    /// =======================================================================
    /// ======================= USER CORE ACTIONS =============================
    /// =======================================================================
    ///
    ///

    /// @notice deposit either tokenA or tokenB
    /// @param _account address of the account to credit the deposit to
    /// @param _token token to deposit
    /// @param _amount amount to deposit
    function deposit(
        address _account,
        address _token,
        uint256 _amount
    ) external payable nonReentrant {
        if (msg.value > 0) {
            _depositWeth();
            _safeTransfer(address(WETH), msg.sender, msg.value);
        }
        _deposit(_account, _token, _amount);
    }

    /// @notice withdraw either tokenA or tokenB
    /// @param _recipient address of the account receiving the tokens
    /// @param _token token to withdraw
    /// @param _amount amount to withdraw
    function withdraw(
        address _recipient,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        _withdraw(_recipient, _token, _amount);
        _checkAccountHealth(msg.sender);
        _checkReserve(_token);
    }

    /// @notice withdraw the whole amount of either tokenA or tokenB
    /// @param _recipient address of the account to transfer the tokens to
    /// @param _token token to withdraw
    function withdrawAll(
        address _recipient,
        address _token
    ) external nonReentrant {
        _withdrawAll(_recipient, _token);
        _checkAccountHealth(msg.sender);
        _checkReserve(_token);
    }

    /// @notice borrow either tokenA or tokenB
    /// @param _recipient address of the account to transfer the tokens to
    /// @param _token token to borrow
    /// @param _amount amount to borrow
    function borrow(
        address _recipient,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        _borrow(_recipient, _token, _amount);
        _checkAccountHealth(msg.sender);
        _checkReserve(_token);
    }

    /// @notice repay either tokenA or tokenB
    /// @param _account address of the account to reduce the debt for
    /// @param _token token to repay
    /// @param _maxAmount maximum amount willing to repay
    /// @dev debt can increase due to accrued interest
    function repay(
        address _account,
        address _token,
        uint256 _maxAmount
    ) external payable nonReentrant {
        if (msg.value > 0) {
            _depositWeth();
            _safeTransfer(address(WETH), msg.sender, msg.value);
        }
        _repay(_account, _token, _maxAmount);
    }

    ///
    ///
    /// =======================================================================
    /// ======================= USER ADVANCED ACTIONS =========================
    /// =======================================================================
    ///
    ///

    /// @notice transfers tokens _from -> _to
    /// @dev Non erc20 compliant, but can be wrapped by an erc20 interface
    function transferLp(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyLpToken {
        require(
            _accounting[_token].debtSharesOf[_to] == 0,
            "LendingPair: cannot receive borrowed token"
        );
        _accounting[_token].supplySharesOf[_from] -= _amount;
        _accounting[_token].supplySharesOf[_to] += _amount;
        _checkAccountHealth(_from);
    }

    /// @notice Liquidate an account to help maintain the protocol's healthy debt position.
    /// @param _account The user account to be liquidated.
    /// @param _repayToken The token which was borrowed by the user and is now in debt
    /// @param _repayAmount The amount of debt to be repaid.
    /// @param _amountOutMin The minimum amount of collateral expected to be received by the liquidator.
    function liquidateAccount(
        address _account,
        address _repayToken,
        uint256 _repayAmount,
        uint256 _amountOutMin
    ) external nonReentrant {
        _liquidateAccount(_account, _repayToken, _repayAmount, _amountOutMin);
        _checkAccountHealth(msg.sender);
        _checkReserve(tokenA);
        _checkReserve(tokenB);
    }

    ///
    ///
    /// =======================================================================
    /// ======================= ADMIN & PROTOCOL ACTIONS ======================
    /// =======================================================================
    ///
    ///

    /// @notice transfer the current pending fees (protocol fees) to the feeRecipient
    /// @param _token token to collect fees
    /// @param _amount fee amount to collect
    function collectSystemFee(
        address _token,
        uint256 _amount
    ) external nonReentrant {
        _validateToken(_token);
        _amount = pendingSystemFees[_token] > _amount
            ? pendingSystemFees[_token]
            : _amount;
        pendingSystemFees[_token] -= _amount;
        _safeTransfer(_token, feeRecipient, _amount);
        _checkReserve(_token);
        emit CollectSystemFee(_token, _amount);
    }

    /// @notice charge interest on debt and add interest to supply
    /// @dev first accrueDebt, then credit a proportion of the newDebt to the totalSupply
    /// @dev the other part of newDebt is credited to pendingSystemFees
    /// @param _token token to be accrued
    function accrue(address _token) public {
        if (lastBlockAccrued[_token] < block.number) {
            uint256 newDebt = _accrueDebt(_token);
            uint256 newSupply = (newDebt * irm.lpRate) / 100e18;
            _accounting[_token].totalSupplyAmount += newSupply;

            // @Note rounding errors should not exsits anymore, but leave it here to be save
            // '-1' helps prevent _checkReserve fails due to rounding errors
            uint256 newFees = (newDebt - newSupply) == 0
                ? 0
                : (newDebt - newSupply - 1);
            pendingSystemFees[_token] += newFees;

            lastBlockAccrued[_token] = block.number;
        }
    }

    ///
    /// =======================================================================
    /// ======================= SETTER functions ==============================
    /// =======================================================================
    ///

    /// @notice change the collateral factor for a token
    /// @param _token token
    /// @param _value newColFactor
    function setColFactor(address _token, uint256 _value) external onlyOwner {
        require(_value <= 99e18, "LendingPair: _value <= 99e18");
        uint256 oldValue = colFactor[_token];
        _validateToken(_token);
        colFactor[_token] = _value;
        emit ColFactorSet(_token, oldValue, _value);
    }

    /// @notice sets the lpRate
    /// @notice lpRate defines the amount of interest going to the lendingPair -> liquidity providers
    /// @dev remaining percent goes to the feeRecipient -> protocol
    /// @dev 1e18 = 1%
    /// @param _lpRate new lpRate
    function setlpRate(uint256 _lpRate) external onlyOwner {
        uint256 oldLpRate = irm.lpRate;
        require(_lpRate != 0, "LendingPair: LP rate cannot be zero");
        require(_lpRate <= 100e18, "LendingPair: LP rate cannot be gt 100");
        irm.lpRate = _lpRate;
        emit LpRateSet(oldLpRate, _lpRate);
    }

    /// @notice Set the parameters of the interest rate model
    /// @dev The target utilization must be less than 100e18
    /// @param _minRate The minimum interest rate for the model, usually when utilization is 0
    /// @param _lowRate The interest rate at the low utilization boundary
    /// @param _highRate The interest rate at the high utilization boundary
    /// @param _targetUtilization The target utilization rate as a percentage, represented as a number between 0 and 100e18
    function setInterestRateModel(
        uint256 _minRate,
        uint256 _lowRate,
        uint256 _highRate,
        uint256 _targetUtilization
    ) external onlyOwner {
        require(
            _targetUtilization < 100e18,
            "Target Utilization must be < 100e18"
        );
        InterestRateModel memory oldIrm = irm;
        irm.minRate = _minRate;
        irm.lowRate = _lowRate;
        irm.highRate = _highRate;
        irm.targetUtilization = _targetUtilization;

        emit InterestRateParametersSet(
            oldIrm.minRate,
            oldIrm.lowRate,
            oldIrm.highRate,
            oldIrm.targetUtilization,
            irm.minRate,
            irm.lowRate,
            irm.highRate,
            irm.targetUtilization
        );
    }

    ///
    ///
    /// =======================================================================
    /// ======================= ADVANCED GETTER ===============================
    /// =======================================================================
    ///
    ///

    /// @notice Unit conversion. Get the amount of borrowed tokens and convert it to the same value of _returnToken
    /// @param _account The address of the account for which the borrowed balance will be retrieved and converted
    /// @param _borrowedToken The address of the token that has been borrowed
    /// @param _returnToken The address of the token to which the borrowed balance will be converted
    /// @return The borrowed balance represented in the units of _returnToken
    function borrowBalanceConverted(
        address _account,
        address _borrowedToken,
        address _returnToken
    ) external view returns (uint256) {
        _validateToken(_borrowedToken);
        _validateToken(_returnToken);

        (uint256 borrowPrice, uint256 returnPrice) = tokenPrices(
            _borrowedToken,
            _returnToken
        );
        return
            _borrowBalanceConverted(
                _account,
                _borrowedToken,
                _returnToken,
                borrowPrice,
                returnPrice
            );
    }

    /// @notice Unit conversion. Get the amount of supplied tokens and convert it to the same value of _returnToken
    /// @param _account The address of the account for which the supplied balance will be retrieved and converted
    /// @param _suppliedToken The address of the token that has been supplied
    /// @param _returnToken The address of the token to which the supplied balance will be converted
    /// @return The supplied balance represented in the units of _returnToken
    function supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken
    ) external view override returns (uint256) {
        _validateToken(_suppliedToken);
        _validateToken(_returnToken);

        (uint256 supplyPrice, uint256 returnPrice) = tokenPrices(
            _suppliedToken,
            _returnToken
        );
        return
            _supplyBalanceConverted(
                _account,
                _suppliedToken,
                _returnToken,
                supplyPrice,
                returnPrice
            );
    }

    /// @notice Calculate the interest rate for supplying a specific token for the current block
    /// @dev This function determines the interest received on supplied tokens based on the current interest rate model
    /// @dev The interest rate is influenced by factors like utilization, and the return value may be zero if there is no supply or debt for the token
    /// @param _token The address of the token for which the supply interest rate is queried
    /// @return interestRate The interest received on supplied tokens for the current block, represented as a proportion between 0 and 100e18
    function supplyRatePerBlock(
        address _token
    ) external view returns (uint256) {
        _validateToken(_token);
        if (
            _accounting[_token].totalSupplyAmount == 0 ||
            _accounting[_token].totalDebtAmount == 0
        ) {
            return 0;
        }
        return
            (((_interestRatePerBlock(_token) * utilizationRate(_token)) /
                100e18) * irm.lpRate) / 100e18; // 1e18: annual interest split into interest per Block // 0e18 - 100e18 // e18
    }

    /// @notice Calculate the interest rate for borrowing a specific token for the current block
    /// @dev This function returns the borrow interest rate as calculated by the interest rate model
    /// @dev The return value is based on the current state of the market and the token's utilization rate
    /// @param _token The address of the token for which the borrow interest rate is queried
    /// @return interestRate The interest paid on borrowed tokens for the current block, as a proportion
    function borrowRatePerBlock(
        address _token
    ) external view returns (uint256) {
        _validateToken(_token);
        return _interestRatePerBlock(_token);
    }

    /// @notice Perform a unit conversion to convert a specified amount of one token to the equivalent value in another token
    /// @dev This function takes an input amount of `_fromToken` and returns the equivalent value in `_toToken` based on their respective prices
    /// @param _fromToken The address of the token to convert from
    /// @param _toToken The address of the token to convert to
    /// @param _inputAmount The amount of `_fromToken` to be converted to `_toToken`
    /// @return convertedAmount The amount of `_toToken` having the same value as `_inputAmount` of `_fromToken`
    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _inputAmount
    ) external view returns (uint256) {
        _validateToken(_fromToken);
        _validateToken(_toToken);

        (uint256 fromPrice, uint256 toPrice) = tokenPrices(
            _fromToken,
            _toToken
        );
        return
            _convertTokenValues(
                _fromToken,
                _toToken,
                _inputAmount,
                fromPrice,
                toPrice
            );
    }

    /// @notice Calculate the proportion of borrowed tokens to supplied tokens for a given token
    /// @dev This function returns the utilization rate, which is the ratio of total borrowed amount to the total supplied amount for the given token
    /// @dev If there is no total supply or total debt for the token, the utilization rate will be 0
    /// @dev The return value is represented as a proportion and is bounded within the range 0 to 100e18
    /// @param _token The address of the token for which the utilization rate is queried
    /// @return utilizationRate The proportion of borrowed tokens to supplied tokens, represented as a number between 0 and 100e18
    function utilizationRate(address _token) public view returns (uint256) {
        uint256 totalSupply = _accounting[_token].totalSupplyAmount; //e18
        uint256 totalDebt = _accounting[_token].totalDebtAmount; //e18
        if (totalSupply == 0 || totalDebt == 0) {
            return 0;
        }
        return Math.min((totalDebt * 100e18) / totalSupply, 100e18); // e20
    }

    ///
    /// =======================================================================
    /// ======================= GETTER functions ==============================
    /// =======================================================================
    ///

    /// @notice Check the current health of an account, represented by the ratio of collateral to debt
    /// @dev The account health is calculated based on the prices of the collateral and debt tokens (tokenA and tokenB) and represents the overall stability of an account in the lending protocol
    /// @dev A healthy account typically has a health ratio greater than 1, meaning that the collateral value is greater than the debt value
    /// @param _account The address of the account for which the health is being checked
    /// @return health The ratio of collateral to debt for the specified account, represented as a proportion. Health should typically be greater than 1
    function accountHealth(address _account) external view returns (uint256) {
        (uint256 priceA, uint256 priceB) = tokenPrices(tokenA, tokenB);
        return _accountHealth(_account, priceA, priceB);
    }

    /// @notice Fetches the current token price
    /// @dev For the native asset: uses the oracle set in the controller
    /// @dev For the permissionless asset: uses the uniswap TWAP oracle
    /// @param _token token for which the Oracle price should be received
    /// @return quote for 1 unit of the token, priced in ETH
    function tokenPrice(address _token) public view returns (uint256) {
        return lendingController.tokenPrice(_token);
    }

    /// @notice Fetches the current token prices for both assets
    /// @dev calls tokenPrice() for each asset
    /// @param _tokenA first token for which the Oracle price should be received
    /// @param _tokenB second token for which the Oracle price should be received
    /// @return oracle price of each asset priced in 1 unit swapped for eth
    function tokenPrices(
        address _tokenA,
        address _tokenB
    ) public view returns (uint256, uint256) {
        return lendingController.tokenPrices(_tokenA, _tokenB);
    }

    /// ======================================================================
    /// =============== Accounting for tokens and shares =====================
    /// ======================================================================

    /// @notice Check the debt of an account for a specific token
    /// @param _token The address of the token for which the debt is being checked
    /// @param _account The address of the account for which the debt is being checked
    /// @return debtAmount The number of `_token` owed by the `_account`
    function debtOf(
        address _token,
        address _account
    ) external view override returns (uint256) {
        _validateToken(_token);
        return _debtOf(_token, _account);
    }

    /// @notice Check the balance of an account for a specific token
    /// @param _token The address of the token for which the supply balance is being checked
    /// @param _account The address of the account for which the supply balance is being checked
    /// @return supplyAmount The balance of `_token` that has been supplied by the `_account`
    function supplyOf(
        address _token,
        address _account
    ) external view override returns (uint256) {
        _validateToken(_token);
        return _supplyOf(_token, _account);
    }

    /// @notice Returns the debt shares of a user for a specific token
    /// @param token The address of the token
    /// @param user The address of the user
    /// @return The amount of debt shares for the user and token
    function debtSharesOf(
        address token,
        address user
    ) public view returns (uint256) {
        return _accounting[token].debtSharesOf[user];
    }

    /// @notice Returns the supply shares of a user for a specific token
    /// @param token The address of the token
    /// @param user The address of the user
    /// @return The amount of supply shares for the user and token
    function supplySharesOf(
        address token,
        address user
    ) public view returns (uint256) {
        return _accounting[token].supplySharesOf[user];
    }

    /// @notice Returns the total supply shares of a specific token
    /// @param token The address of the token
    /// @return The total supply shares for the token
    function totalSupplyShares(address token) public view returns (uint256) {
        return _accounting[token].totalSupplyShares;
    }

    /// @notice Returns the total supply amount of a specific token
    /// @param token The address of the token
    /// @return The total supply amount for the token
    function totalSupplyAmount(address token) public view returns (uint256) {
        return _accounting[token].totalSupplyAmount;
    }

    /// @notice Returns the total debt shares of a specific token
    /// @param token The address of the token
    /// @return The total debt shares for the token
    function totalDebtShares(address token) public view returns (uint256) {
        return _accounting[token].totalDebtShares;
    }

    /// @notice Returns the total debt amount of a specific token
    /// @param token The address of the token
    /// @return The total debt amount for the token
    function totalDebtAmount(address token) public view returns (uint256) {
        return _accounting[token].totalDebtAmount;
    }

    ///
    ///
    /// =======================================================================
    /// ======================= INTERNAL functions ============================
    /// =======================================================================
    ///
    ///

    /// @notice deposit a token into the pair (as collateral)
    /// @dev mints new supply shares
    /// @dev folding is prohibited (deposit and borrow the same token)
    function _deposit(
        address _account,
        address _token,
        uint256 _amount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        require(
            _accounting[_token].debtSharesOf[_account] == 0,
            "LendingPair: cannot deposit borrowed token"
        );

        _mintSupplyAmount(_token, _account, _amount);
        _safeTransferFrom(_token, msg.sender, _amount);

        emit Deposit(_account, _token, _amount);
    }

    /// @notice withdraw a specified amount of collateral to a recipient
    /// @dev health and credit are not checked
    /// @dev accrues interest and calls _withdrawShares with updated supply
    function _withdraw(
        address _recipient,
        address _token,
        uint256 _amount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        // Fix rounding error:
        uint256 _shares = _supplyToShares(_token, _amount);
        if (_sharesToSupply(_token, _shares) < _amount) {
            ++_shares;
        }

        _withdrawShares(_token, _shares);
        _transferAsset(_token, _recipient, _amount);
    }

    /// @notice borrow a specified amount and check pair related boundary conditions.
    /// @dev the health/collateral is not checked. Calling this can borrow any amount available
    function _borrow(
        address _recipient,
        address _token,
        uint256 _amount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        require(
            _accounting[_token].supplySharesOf[msg.sender] == 0,
            "LendingPair: cannot borrow supplied token"
        );

        _mintDebtAmount(_token, msg.sender, _amount);
        _transferAsset(_token, _recipient, _amount);

        emit Borrow(msg.sender, _token, _amount);
    }

    /// @notice withdraw all collateral of _token to a recipient
    function _withdrawAll(address _recipient, address _token) internal {
        _validateToken(_token);
        accrue(_token);

        uint256 shares = _accounting[_token].supplySharesOf[msg.sender];
        uint256 amount = _sharesToSupply(_token, shares);
        _withdrawShares(_token, shares);
        _transferAsset(_token, _recipient, amount);
    }

    /// @notice repays a specified _maxAmount of _token debt
    /// @dev if _maxAmount > debt defaults to repaying all debt of selected token
    function _repay(
        address _account,
        address _token,
        uint256 _maxAmount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        uint256 maxShares = _debtToShares(_token, _maxAmount);

        uint256 sharesAmount = Math.min(
            _accounting[_token].debtSharesOf[_account],
            maxShares
        );
        uint256 repayAmount = _repayShares(_account, _token, sharesAmount);

        _safeTransferFrom(_token, msg.sender, repayAmount);
    }

    /// @notice checks the current account health is greater than required min health (based on provided collateral, debt and token prices)
    /// @dev reverts if health is below liquidation limit
    function _checkAccountHealth(address _account) internal view {
        (uint256 priceA, uint256 priceB) = tokenPrices(tokenA, tokenB);
        uint256 health = _accountHealth(_account, priceA, priceB);
        require(
            health >= LIQ_MIN_HEALTH,
            "LendingPair: insufficient accountHealth"
        );
    }

    /// @notice liquidation: Sell collateral to reduce debt and increase accountHealth
    /// @notice the liquidator needs to provide enought tokens to repay debt and receives supply tokens
    /// @dev Set _repayAmount to type(uint).max to repay all debt, inc. pending interest
    function _liquidateAccount(
        address _account,
        address _repayToken,
        uint256 _repayAmount,
        uint256 _amountOutMin
    ) internal {
        // Input validation and adjustments

        _validateToken(_repayToken);

        address supplyToken = _repayToken == tokenA ? tokenB : tokenA;

        // Check account is underwater after interest

        accrue(supplyToken);
        accrue(_repayToken);

        (uint256 priceA, uint256 priceB) = tokenPrices(tokenA, tokenB);

        uint256 health = _accountHealth(_account, priceA, priceB);
        require(
            health < LIQ_MIN_HEALTH,
            "LendingPair: account health < LIQ_MIN_HEALTH"
        );

        // Calculate balance adjustments

        _repayAmount = Math.min(_repayAmount, _debtOf(_repayToken, _account));

        // Calculates the amount of collateral to liquidate for _repayAmount
        // Avoiding stack too deep error
        uint256 supplyDebt = _convertTokenValues(
            _repayToken,
            supplyToken,
            _repayAmount,
            _repayToken == tokenA ? priceA : priceB, // repayPrice
            supplyToken == tokenA ? priceA : priceB // supplyPrice
        );

        // Adding fees
        uint256 callerFee = (supplyDebt *
            lendingController.liqFeeCaller(_repayToken)) / 100e18;
        uint256 systemFee = (supplyDebt *
            lendingController.liqFeeSystem(_repayToken)) / 100e18;
        uint256 supplyBurn = supplyDebt + callerFee + systemFee;
        uint256 supplyOutput = supplyDebt + callerFee;

        // Ensure that the tokens received by the liquidator meet or exceed the desired minimum amount
        require(
            supplyOutput >= _amountOutMin,
            "LendingPair: Liquidation output below minimium desired amount"
        );

        // Adjust balances
        _burnSupplyShares(
            supplyToken,
            _account,
            _supplyToShares(supplyToken, supplyBurn)
        );
        pendingSystemFees[supplyToken] += systemFee;
        _burnDebtShares(
            _repayToken,
            _account,
            _debtToShares(_repayToken, _repayAmount)
        );

        // Transfer collateral from liquidator
        _safeTransferFrom(_repayToken, msg.sender, _repayAmount);

        // Mint liquidator
        _mintSupplyAmount(supplyToken, msg.sender, supplyOutput);

        emit Liquidation(
            _account,
            _repayToken,
            supplyToken,
            _repayAmount,
            supplyOutput
        );
    }

    /// @notice calls the function wildCall of any contract
    /// @param _callee contract to call
    /// @param _data calldata
    function _call(address _callee, bytes memory _data) internal {
        ICallee(_callee).wildCall(_data);
    }

    /// @notice Supply tokens.
    /// @dev Mint new supply shares (corresponding to supply _amount) and credit them to _account.
    /// @dev increase total supply amount and shares
    /// @return shares | number of supply shares newly minted
    function _mintSupplyAmount(
        address _token,
        address _account,
        uint256 _amount
    ) internal returns (uint256 shares) {
        if (_amount > 0) {
            shares = _supplyToShares(_token, _amount);
            _accounting[_token].supplySharesOf[_account] += shares;
            _accounting[_token].totalSupplyShares += shares;
            _accounting[_token].totalSupplyAmount += _amount;
        }
    }

    /// @notice Withdraw Tokens.
    /// @dev burns supply shares credited to _account by the number of _shares specified
    /// @dev reduces totalSupplyShares. Reduces totalSupplyAmount by the corresponding amount
    /// @return amount of tokens corresponding to _shares
    function _burnSupplyShares(
        address _token,
        address _account,
        uint256 _shares
    ) internal returns (uint256 amount) {
        if (_shares > 0) {
            // Fix rounding error which can make issues during depositRepay / withdrawBorrow
            if (_accounting[_token].supplySharesOf[_account] - _shares == 1) {
                _shares += 1;
            }

            amount = _sharesToSupply(_token, _shares);
            _accounting[_token].supplySharesOf[_account] -= _shares;
            _accounting[_token].totalSupplyShares -= _shares;
            _accounting[_token].totalSupplyAmount -= amount;
        }
    }

    /// @notice Make debt.
    /// @dev Mint new debt shares (corresponding to debt _amount) and credit them to _account.
    /// @dev increase total debt amount and shares
    /// @return shares | number of debt shares newly minted
    function _mintDebtAmount(
        address _token,
        address _account,
        uint256 _amount
    ) internal returns (uint256 shares) {
        if (_amount > 0) {
            shares = _debtToShares(_token, _amount);
            // Borrowing costs 1 share to account for later underpayment
            ++shares;

            _accounting[_token].debtSharesOf[_account] += shares;
            _accounting[_token].totalDebtShares += shares;
            _accounting[_token].totalDebtAmount += _amount;
        }
    }

    /// @notice Repay Debt.
    /// @dev burns debt shares credited to _account by the number of _shares specified
    /// @dev reduces totalDebtShares. Reduces totalDebtAmount by the corresponding amount
    /// @return amount of tokens corresponding to _shares
    function _burnDebtShares(
        address _token,
        address _account,
        uint256 _shares
    ) internal returns (uint256 amount) {
        if (_shares > 0) {
            // Fix rounding error which can make issues during depositRepay / withdrawBorrow
            if (_accounting[_token].debtSharesOf[_account] - _shares == 1) {
                _shares += 1;
            }
            amount = _sharesToDebt(_token, _shares);
            _accounting[_token].debtSharesOf[_account] -= _shares;
            _accounting[_token].totalDebtShares -= _shares;
            _accounting[_token].totalDebtAmount -= amount;
        }
    }

    /// @notice accrue interest on debt, by adding newDebt since last accrue to totalDebtAmount.
    /// @dev done by: applying the interest per Block on the oustanding debt times blocks elapsed
    /// @dev using _interestRatePerBlock() interest rate Model
    /// @return newDebt
    function _accrueDebt(address _token) internal returns (uint256 newDebt) {
        // If borrowed or existing Debt, else skip
        if (_accounting[_token].totalDebtAmount > 0) {
            uint256 blocksElapsed = block.number - lastBlockAccrued[_token];
            uint256 pendingInterestRate = _interestRatePerBlock(_token) *
                blocksElapsed;
            newDebt =
                (_accounting[_token].totalDebtAmount * pendingInterestRate) /
                100e18;
            _accounting[_token].totalDebtAmount += newDebt;
        }
    }

    /// @notice reduces the SupplyShare of msg.sender by the defined amount, emits Withdraw event
    function _withdrawShares(address _token, uint256 _shares) internal {
        uint256 amount = _burnSupplyShares(_token, msg.sender, _shares);
        emit Withdraw(msg.sender, _token, amount);
    }

    /// @notice repay debt shares
    /// @return amount of tokens repayed for _shares
    function _repayShares(
        address _account,
        address _token,
        uint256 _shares
    ) internal returns (uint256 amount) {
        amount = _burnDebtShares(_token, _account, _shares);
        emit Repay(_account, _token, amount);
    }

    /// @notice Safe withdraw of ERC-20 tokens (revert on failure)
    function _transferAsset(
        address _asset,
        address _to,
        uint256 _amount
    ) internal {
        if (_asset == address(WETH)) {
            //Withdraw as ETH
            _wethWithdrawTo(_to, _amount);
        } else {
            _safeTransfer(_asset, _to, _amount);
        }
    }

    /// @notice creates a new ERC-20 token representing collateral amounts within this pair
    /// @dev called during pair initialization
    /// @dev acts as an interface to the information stored in this contract
    function _createLpToken(
        address _lpTokenMaster,
        address _underlying
    ) internal returns (address) {
        ILPTokenMaster newLPToken = ILPTokenMaster(_lpTokenMaster.clone());
        newLPToken.initialize(_underlying, address(lendingController));
        return address(newLPToken);
    }

    /// @notice checks the current health of an _account, the health represents the ratio of collateral to debt
    /// @dev Query all supply & borrow balances and convert the amounts into the the same token (tokenA)
    /// @dev then calculates the ratio
    function _accountHealth(
        address _account,
        uint256 _priceA,
        uint256 _priceB
    ) internal view returns (uint256) {
        // No Debt:
        if (
            _accounting[tokenA].debtSharesOf[_account] == 0 &&
            _accounting[tokenB].debtSharesOf[_account] == 0
        ) {
            return LIQ_MIN_HEALTH;
        }

        uint256 colFactorA = colFactor[tokenA];
        uint256 colFactorB = colFactor[tokenB];

        uint256 creditA = (_supplyOf(tokenA, _account) * colFactorA) / 100e18;
        uint256 creditB = (_supplyBalanceConverted(
            _account,
            tokenB,
            tokenA,
            _priceB,
            _priceA
        ) * colFactorB) / 100e18;

        uint256 totalAccountBorrow = _debtOf(tokenA, _account) +
            _borrowBalanceConverted(_account, tokenB, tokenA, _priceB, _priceA);

        return ((creditA + creditB) * 1e18) / totalAccountBorrow;
    }

    /// @notice returns the amount of shares representing X tokens (_inputSupply)
    /// @param _totalShares total shares in circulation
    /// @param _totalAmount total amount of token X deposited in the pair
    /// @param _inputSupply amount of tokens to find the proportional amount of shares for
    /// @return shares representing _inputSupply
    function _amountToShares(
        uint256 _totalShares,
        uint256 _totalAmount,
        uint256 _inputSupply
    ) internal pure returns (uint256) {
        if (_totalShares > 0 && _totalAmount > 0) {
            return (_inputSupply * _totalShares) / _totalAmount;
        } else {
            return _inputSupply;
        }
    }

    /// @notice returns the amount of tokens representing X shares (_inputShares)
    /// @param _totalShares total shares in circulation
    /// @param _totalAmount total amount of token X deposited in the pair
    /// @param _inputShares amount of shares to find the proportional amount of tokens for
    /// @return the underlying amount of tokens for _inputShares
    function _sharesToAmount(
        uint256 _totalShares,
        uint256 _totalAmount,
        uint256 _inputShares
    ) internal pure returns (uint256) {
        if (_totalShares > 0 && _totalAmount > 0) {
            return (_inputShares * _totalAmount) / _totalShares;
        } else {
            return _inputShares;
        }
    }

    /// @notice converts an input debt amount to the corresponding number of DebtShares representing it
    /// @dev calls _amountToShares with the arguments of totalDebtShares, totalDebtAmount, and debt amount to convert to DebtShares
    function _debtToShares(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        return
            _amountToShares(
                _accounting[_token].totalDebtShares,
                _accounting[_token].totalDebtAmount,
                _amount
            );
    }

    /// @notice converts a number of DebtShares to the underlying amount of token debt
    /// @dev calls _sharesToAmount with the arguments of totalDebtShares, totalDebtAmount, and the number of shares to convert to the underlying debt amount
    function _sharesToDebt(
        address _token,
        uint256 _shares
    ) internal view returns (uint256) {
        return
            _sharesToAmount(
                _accounting[_token].totalDebtShares,
                _accounting[_token].totalDebtAmount,
                _shares
            );
    }

    /// @notice converts an input amount to the corresponding number of shares representing it
    /// @dev calls _amountToShares with the arguments of totalSupplyShares, totalSupplyAmount, and amount to convert to shares
    function _supplyToShares(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        return
            _amountToShares(
                _accounting[_token].totalSupplyShares,
                _accounting[_token].totalSupplyAmount,
                _amount
            );
    }

    /// @notice converts a number of shares to the underlying amount of tokens
    /// @dev calls _sharesToAmount with the arguments of totalSupplyShares, totalSupplyAmount, and the number of shares to convert to the underlying amount
    function _sharesToSupply(
        address _token,
        uint256 _shares
    ) internal view returns (uint256) {
        return
            _sharesToAmount(
                _accounting[_token].totalSupplyShares,
                _accounting[_token].totalSupplyAmount,
                _shares
            );
    }

    /// @return amount of tokens (including interest) borrowed by _account
    /// @dev gets the number of debtShares owed by _account and converts it into the amount of underlying tokens (_sharesToDebt)
    function _debtOf(
        address _token,
        address _account
    ) internal view returns (uint256) {
        return
            _sharesToDebt(_token, _accounting[_token].debtSharesOf[_account]);
    }

    /// @return amount of tokens (including interest) supplied by _account
    /// @dev gets the number of shares credited to _account and converts it into the amount of underlying tokens (_sharesToSupply)
    function _supplyOf(
        address _token,
        address _account
    ) internal view returns (uint256) {
        return
            _sharesToSupply(
                _token,
                _accounting[_token].supplySharesOf[_account]
            );
    }

    /// @notice Unit conversion. Get the amount of borrowed tokens and convert it to the same value of _returnToken
    /// @return amount borrowed converted to _returnToken
    function _borrowBalanceConverted(
        address _account,
        address _borrowedToken,
        address _returnToken,
        uint256 _borrowPrice,
        uint256 _returnPrice
    ) internal view returns (uint256) {
        return
            _convertTokenValues(
                _borrowedToken,
                _returnToken,
                _debtOf(_borrowedToken, _account),
                _borrowPrice,
                _returnPrice
            );
    }

    /// @notice Unit conversion. Get the amount of supplied tokens and convert it to the same value of _returnToken
    /// @return amount supplied converted to _returnToken
    function _supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken,
        uint256 _supplyPrice,
        uint256 _returnPrice
    ) internal view returns (uint256) {
        return
            _convertTokenValues(
                _suppliedToken,
                _returnToken,
                _supplyOf(_suppliedToken, _account), //input amount
                _supplyPrice,
                _returnPrice
            );
    }

    /// @notice converts an _inputAmount (_fromToken) to the same value of _toToken
    /// @notice like a price quote of _fromToken -> _toToken with an amount of _inputAmout
    /// @dev  Not calling priceOracle.convertTokenValues() to save gas by reusing already fetched prices
    function _convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _inputAmount,
        uint256 _fromPrice,
        uint256 _toPrice
    ) internal view returns (uint256) {
        uint256 fromPrice = (_fromPrice * 1e18) / 10 ** _decimals[_fromToken];
        uint256 toPrice = (_toPrice * 1e18) / 10 ** _decimals[_toToken];

        return (_inputAmount * fromPrice) / toPrice;
    }

    /// @notice calculates the interest rate per block based on current supply+borrow amounts and limits
    /// @dev we have two interest rate curves in place:
    /// @dev                     1) 0%->loweRate               : if ultilization < targetUtilization
    /// @dev                     2) lowerRate + 0%->higherRate : if ultilization >= targetUtilization
    /// @dev
    /// @dev To convert time rate to block rate, use this formula:
    /// @dev RATE FORMULAR: annualRate [0-100] * BLOCK_TIME [s] * 1e18 / (365 * 86400); BLOCK_TIME_MAIN_OLD=13.2s
    /// @dev where annualRate is in format: 1e18 = 1%
    /// @dev Arbitrum uses ethereum blocknumbers. block.number is updated every ~1min
    /// @dev Ethereum PoS-blocktime is 12.05s
    /// @dev Ethereum Blocks per year: ~2617095
    function _interestRatePerBlock(
        address _token
    ) internal view returns (uint256) {
        uint256 totalSupply = _accounting[_token].totalSupplyAmount;
        uint256 totalDebt = _accounting[_token].totalDebtAmount;

        if (totalSupply == 0 || totalDebt == 0) {
            return irm.minRate;
        }

        uint256 utilization = (((totalDebt * 100e18) / totalSupply) * 100e18) /
            irm.targetUtilization;

        // If current utilization is below targetUtilization
        if (utilization < 100e18) {
            uint256 rate = (irm.lowRate * utilization) / 100e18; //[e2-e0] with lowRate
            return Math.max(rate, irm.minRate);
        } else {
            // This "utilization" represents the utilization of funds between target-utilization and totalSupply
            // E.g. totalSupply=100 totalDebt=95 taget=90 -> utilization=50%
            uint256 targetSupplyUtilization = (totalSupply *
                irm.targetUtilization) / 100e18;
            uint256 excessUtilization = ((totalDebt - targetSupplyUtilization));
            uint256 maxExcessUtiization = totalSupply *
                (100e18 - irm.targetUtilization);

            utilization =
                (excessUtilization * 100e18) /
                (maxExcessUtiization / 100e18);

            utilization = Math.min(utilization, 100e18);
            return
                irm.lowRate +
                ((irm.highRate - irm.lowRate) * utilization) /
                100e18;
        }
    }

    /// @notice _accounting! Makes sure balances, debt, supply, and fees add up.
    function _checkReserve(address _token) internal view {
        IERC20Metadata token = IERC20Metadata(_token);

        uint256 balance = token.balanceOf(address(this));
        uint256 debt = _accounting[_token].totalDebtAmount;
        uint256 supply = _accounting[_token].totalSupplyAmount;
        uint256 fees = pendingSystemFees[_token];

        require(
            int256(balance) + int256(debt) - int256(supply) - int256(fees) >= 0,
            "LendingPair: reserve check failed"
        );
    }

    /// @notice validates that the input token is one of the pair Tokens (tokenA or tokenB).
    function _validateToken(address _token) internal view {
        require(
            _token == tokenA || _token == tokenB,
            "LendingPair: invalid token"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

contract LendingPairEvents {
    event Liquidation(
        address indexed account,
        address indexed repayToken,
        address indexed supplyToken,
        uint256 repayAmount,
        uint256 supplyAmount
    );
    event Deposit(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Withdraw(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Borrow(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Repay(address indexed account, address indexed token, uint256 amount);
    event CollectSystemFee(address indexed token, uint256 amount);
    event ColFactorSet(
        address indexed token,
        uint256 oldValue,
        uint256 newValue
    );
    event LpRateSet(uint256 oldLpRate, uint256 newLpRate);
    event InterestRateParametersSet(
        uint256 oldMinRate,
        uint256 oldLowRate,
        uint256 oldHighRate,
        uint256 oldTargetUtilization,
        uint256 minRate,
        uint256 lowRate,
        uint256 highRate,
        uint256 targetUtilization
    );
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

// This contract is a wrapper around the LendingPair contract
// Each new LendingPair implementation delegates its calls to this contract
// It enables ERC20 functionality around the postion tokens

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/ILPTokenMaster.sol";
import "./interfaces/ILendingPair.sol";
import "./interfaces/ILendingController.sol";

/// @title LendingPairTokenMaster: An ERC20-like Master contract for Flora Loans
/// @author 0xdev & flora.loans
/// @notice This contract serves as a fungible token and is a wrapper around the LendingPair contract
/// @dev Each new LendingPair implementation delegates its calls to this contract, enabling ERC20 functionality around the position tokens
/// @dev Implements the ERC20 standard and serves as the master contract for managing tokens in lending pairs

contract LPTokenMaster is ILPTokenMaster, Ownable2Step {
    mapping(address account => mapping(address spender => uint256 amount))
        public
        override allowance;

    address public override underlying;
    address public lendingController;
    string public constant name = "Flora-Lendingpair";
    string public constant symbol = "FLORA-LP";
    uint8 public constant override decimals = 18;
    bool private _initialized;

    modifier onlyOperator() {
        require(
            msg.sender == ILendingController(lendingController).owner(),
            "LPToken: caller is not an operator"
        );
        _;
    }

    /// @notice Initialize the contract, called by the LendingPair during creation at PairFactory
    /// @param _underlying Address of the underlying token (e.g. WETH address if the token is WETH)
    /// @param _lendingController Address of the lending controller
    function initialize(
        address _underlying,
        address _lendingController
    ) external override {
        require(_initialized != true, "LPToken: already intialized");
        underlying = _underlying;
        lendingController = _lendingController;
        _initialized = true;
    }

    /// @notice Transfer tokens to a specified address
    /// @param _recipient The address to transfer to
    /// @param _amount The amount to be transferred
    /// @return A boolean value indicating whether the operation succeeded
    function transfer(
        address _recipient,
        uint256 _amount
    ) external override returns (bool /* transferSuccessful */) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /// @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
    /// @param _spender The address which will spend the funds
    /// @param _amount The amount of tokens to be spent
    /// @return A boolean value indicating whether the operation succeeded
    /// @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
    /// and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    /// race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(
        address _spender,
        uint256 _amount
    ) external override returns (bool /* approvalSuccesful */) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice Transfer tokens from one address to another.
    /// @param _sender The address which you want to send tokens from
    /// @param _recipient The address which you want to transfer to
    /// @param _amount The amount of tokens to be transferred
    /// @return A boolean value indicating whether the operation succeeded
    /// @dev Note that while this function emits an Approval event, this is not required as per the specification and other compliant implementations may not emit the event.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool /* transferFromsuccessful */) {
        _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /// @notice Returns the associated LendingPair Contract
    /// @return The address of the associated LendingPair Contract
    function lendingPair()
        external
        view
        override
        returns (address /* LendingPair address */)
    {
        return owner();
    }

    /// @notice Gets the balance of the specified address
    /// @param _account The address to query the balance of
    /// @return A uint256 representing the shares credited to `account`
    function balanceOf(
        address _account
    ) external view override returns (uint256 /* supply shares of `account`*/) {
        return ILendingPair(owner()).supplySharesOf(underlying, _account);
    }

    /// @notice Get the total number of tokens in existence
    /// @return A uint256 representing the total supply of the token
    function totalSupply()
        external
        view
        override
        returns (uint256 /* totalSupplyShares*/)
    {
        return ILendingPair(owner()).totalSupplyShares(underlying);
    }

    /// @notice Returns the current owner of the contract.
    /// @return The address of the current owner. Should be the LendingPair
    function owner()
        public
        view
        override(IOwnable, Ownable)
        returns (address /* owner address */)
    {
        return Ownable.owner();
    }

    /// @notice Allows the pending owner to become the new owner.
    function acceptOwnership() public override(IOwnable, Ownable2Step) {
        return Ownable2Step.acceptOwnership();
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(
        address newOwner
    ) public override(IOwnable, Ownable2Step) {
        return Ownable2Step.transferOwnership(newOwner);
    }

    /// @notice Internal function to transfer tokens between two addresses
    /// @dev Called by the external transfer and transferFrom functions
    /// @param _sender The address from which to transfer tokens
    /// @param _recipient The address to which to transfer tokens
    /// @param _amount The amount of tokens to transfer
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        ILendingPair(owner()).transferLp(
            underlying,
            _sender,
            _recipient,
            _amount
        );

        emit Transfer(_sender, _recipient, _amount);
    }

    /// @notice Internal function to approve an address to spend a specified amount of tokens on behalf of an owner
    /// @dev Called by the external approve function
    /// @param _owner The address of the token owner
    /// @param _spender The address to grant spending rights to
    /// @param _amount The amount of tokens to approve for spending
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IWETH.sol";

contract TransferHelper {
    using SafeERC20 for IERC20;

    IWETH internal immutable WETH;

    constructor(IWETH _WETH) {
        WETH = _WETH;
    }

    function _safeTransferFrom(
        address _token,
        address _sender,
        uint256 _amount
    ) internal {
        require(_amount > 0, "TransferHelper: amount must be > 0");
        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
    }

    function _safeTransfer(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_amount > 0, "TransferHelper: amount must be > 0");
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    function _wethWithdrawTo(address _to, uint256 _amount) internal {
        require(_amount > 0, "TransferHelper: amount must be > 0");
        require(_to != address(0), "TransferHelper: invalid recipient");

        WETH.withdraw(_amount);
        (bool success, ) = _to.call{value: _amount}(new bytes(0));
        require(success, "TransferHelper: ETH transfer failed");
    }

    function _depositWeth() internal {
        require(msg.value > 0, "TransferHelper: amount must be > 0");
        WETH.deposit{value: msg.value}();
    }
}