// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, 'Governable: forbidden');
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IPriceFeed {
    function getPrice(bytes32 productId) external view returns (FixedPoint.Unsigned);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC4626.sol';

interface IPerpetual {
    struct Position {
        address owner;
        bytes32 productId;
        uint256 margin; // collateral provided for this position
        FixedPoint.Unsigned leverage;
        FixedPoint.Unsigned price; // price when position was increased. weighted average by size
        FixedPoint.Unsigned oraclePrice;
        FixedPoint.Signed funding;
        bytes16 ownerPositionId;
        uint64 timestamp; // last position increase
        bool isLong;
        bool isNextPrice;
    }

    struct ProductParams {
        bytes32 productId;
        FixedPoint.Unsigned maxLeverage;
        FixedPoint.Unsigned fee;
        bool isActive;
        FixedPoint.Unsigned minPriceChange; // min oracle increase % for trader to close with profit
        FixedPoint.Unsigned weight; // share of the max exposure
        uint256 reserve; // Virtual reserve used to calculate slippage
    }

    struct Product {
        bytes32 productId;
        FixedPoint.Unsigned maxLeverage;
        FixedPoint.Unsigned fee;
        bool isActive;
        FixedPoint.Unsigned openInterestLong;
        FixedPoint.Unsigned openInterestShort;
        FixedPoint.Unsigned minPriceChange; // min oracle increase % for trader to close with profit
        FixedPoint.Unsigned weight; // share of the max exposure
        uint256 reserve; // Virtual reserve used to calculate slippage
    }

    struct OpenPositionParams {
        address user;
        bytes16 userPositionId;
        bytes32 productId;
        uint256 margin;
        bool isLong;
        FixedPoint.Unsigned leverage;
    }

    struct ClosePositionParams {
        address user;
        bytes16 userPositionId;
        uint256 margin;
    }

    function distributeVaultReward() external returns (uint256);

    function getPendingVaultReward() external view returns (uint256);

    function openPositions(
        OpenPositionParams[] calldata params
    ) external;

    function closePositions(
        ClosePositionParams[] calldata params
    ) external;

    function getProduct(bytes32 productId) external view returns (Product memory);

    function getPosition(address account, bytes16 accountPositionId) external view returns (Position memory);

    function getMaxExposure(FixedPoint.Unsigned productWeight)
        external
        view
        returns (FixedPoint.Unsigned);
}

interface IDomFiPerp is IPerpetual, IERC20, IERC4626 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFeeCalculator {
    function getFee(
        FixedPoint.Unsigned productFee,
        address user,
        address sender
    ) external view returns (FixedPoint.Unsigned);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFundingManager {
    function updateFunding(bytes32) external;

    function getFunding(bytes32) external view returns (FixedPoint.Signed);

    function getFundingRate(bytes32) external view returns (FixedPoint.Signed);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.8;

/**
 * @title Library for fixed point arithmetic on (u)ints
 */
library FixedPoint {
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_DECIMALS = 18;
    uint256 private constant FP_SCALING_FACTOR = 10**FP_DECIMALS;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    type Unsigned is uint256;

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned) {
        return Unsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) <= Unsigned.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) + Unsigned.unwrap(b));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) - Unsigned.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned.wrap(Unsigned.unwrap(a) * Unsigned.unwrap(b) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 mulRaw = Unsigned.unwrap(a) * Unsigned.unwrap(b);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw % FP_SCALING_FACTOR;
        if (mod != 0) {
            return Unsigned.wrap(mulFloor + 1);
        } else {
            return Unsigned.wrap(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned.wrap(Unsigned.unwrap(a) * FP_SCALING_FACTOR / Unsigned.unwrap(b));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) / b);
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 aScaled = Unsigned.unwrap(a) * FP_SCALING_FACTOR;
        uint256 divFloor = aScaled / Unsigned.unwrap(b);
        uint256 mod = aScaled % Unsigned.unwrap(b);
        if (mod != 0) {
            return Unsigned.wrap(divFloor + 1);
        } else {
            return Unsigned.wrap(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(Unsigned.unwrap(a).div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned a, uint256 b) internal pure returns (Unsigned output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    type Signed is int256;

    function fromSigned(Signed a) internal pure returns (Unsigned) {
        require(Signed.unwrap(a) >= 0, 'Negative value provided');
        return Unsigned.wrap(uint256(Signed.unwrap(a)));
    }

    function fromUnsigned(Unsigned a) internal pure returns (Signed) {
        require(Unsigned.unwrap(a) <= uint256(type(int256).max), 'Unsigned too large');
        return Signed.wrap(int256(Unsigned.unwrap(a)));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed) {
        return Signed.wrap(a * SFP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) <= Signed.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) < Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) > Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) + Signed.unwrap(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, int256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Adds a `Signed` to an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an Unsigned.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Unsigned b) internal pure returns (Signed) {
        return add(a, fromUnsigned(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, uint256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) - Signed.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, int256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Unsigned b) internal pure returns (Signed) {
        return sub(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, uint256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts a `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed b) internal pure returns (Signed) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed.wrap(Signed.unwrap(a) * Signed.unwrap(b) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Multiplies a `Signed` and `Unsigned`, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Unsigned b) internal pure returns (Signed) {
        return mul(a, fromUnsigned(b));
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, uint256 b) internal pure returns (Signed) {
        return mul(a, fromUnscaledUint(b));
    }

    function neg(Signed a) internal pure returns (Signed) {
        return mul(a, -1);
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 mulRaw = Signed.unwrap(a) * Signed.unwrap(b);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(mulTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed.wrap(Signed.unwrap(a) * SFP_SCALING_FACTOR / Signed.unwrap(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) / b);
    }

    /**
     * @notice Divides one `Signed` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint.Signed numerator.
     * @param b a FixedPoint.Unsigned denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Unsigned b) internal pure returns (Signed) {
        return div(a, fromUnsigned(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, uint256 b) internal pure returns (Signed) {
        return div(a, fromUnscaledUint(b));
    }

    /**
     * @notice Divides one unscaled int256 by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed b) internal pure returns (Signed) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 aScaled = Signed.unwrap(a) * SFP_SCALING_FACTOR;
        int256 divTowardsZero = aScaled / Signed.unwrap(b);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % Signed.unwrap(b);
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(divTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(Signed.unwrap(a).div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises a `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed a, uint256 b) internal pure returns (Signed output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    /**
     * @notice Absolute value of a FixedPoint.Signed
     */
    function abs(Signed value) internal pure returns (Unsigned) {
        int256 x = Signed.unwrap(value);
        uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
        return Unsigned.wrap(raw);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return Unsigned.unwrap(value) / FP_SCALING_FACTOR;
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Signed value) internal pure returns (int256) {
        return Signed.unwrap(value) / SFP_SCALING_FACTOR;
    }

    /**
     * @notice Rounding a FixedPoint.Unsigned down to the nearest integer.
     */
    function floor(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        return FixedPoint.fromUnscaledUint(trunc(value));
    }

    /**
     * @notice Round a FixedPoint.Unsigned up to the nearest integer.
     */
    function ceil(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        FixedPoint.Unsigned iPart = floor(value);
        FixedPoint.Unsigned fPart = sub(value, iPart);
        if (Unsigned.unwrap(fPart) > 0) {
            return add(iPart, fromUnscaledUint(1));
        } else {
            return iPart;
        }
    }

    /**
     * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
     * @param value uint256, e.g. 10000000 wei USDC
     * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
     * @return output FixedPoint.Unsigned, e.g. (10.000000)
     */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FixedPoint.Unsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, rounding up any decimal portion.
     */
    function roundUp(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return trunc(ceil(value));
    }

    /**
     * @notice Round a trader's PnL in favor of liquidity providers
     */
    function roundTraderPnl(FixedPoint.Signed value) internal pure returns (FixedPoint.Signed) {
        if (Signed.unwrap(value) >= 0) {
            // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
            FixedPoint.Unsigned pnl = fromSigned(value);
            return fromUnsigned(floor(pnl));
        } else {
            // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
            return neg(fromUnsigned(ceil(abs(value))));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './FixedPoint.sol';

import '../interfaces/perp/IFeeCalculator.sol';
import '../interfaces/perp/IFundingManager.sol';

library PerpLib {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        FixedPoint.Unsigned positionOraclePrice,
        FixedPoint.Unsigned oraclePrice,
        FixedPoint.Unsigned minPriceChange,
        uint256 minProfitTime
    ) internal view returns (bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        } else if (isLong && oraclePrice.isGreaterThan(positionOraclePrice.mul(minPriceChange.add(1)))) {
            return true;
        } else if (
            !isLong &&
            oraclePrice.isLessThan(positionOraclePrice.mul(FixedPoint.fromUnscaledUint(1).sub(minPriceChange)))
        ) {
            return true;
        }
        return false;
    }

    function _getPnl(
        bool isLong,
        FixedPoint.Unsigned positionPrice,
        FixedPoint.Unsigned positionLeverage,
        uint256 margin,
        FixedPoint.Unsigned price
    ) internal pure returns (FixedPoint.Signed pnl) {
        pnl = (isLong
            ? FixedPoint.fromUnsigned(price).sub(positionPrice)
            : FixedPoint.fromUnsigned(positionPrice).sub(price)
            ).mul(margin).mul(positionLeverage).div(positionPrice);
    }

    function _getFundingPayment(
        bool isLong,
        FixedPoint.Unsigned positionLeverage,
        uint256 margin,
        FixedPoint.Signed funding,
        FixedPoint.Signed cumulativeFunding
    ) internal pure returns (FixedPoint.Signed) {
        FixedPoint.Signed actualMargin = FixedPoint.fromUnscaledUint(margin).fromUnsigned();
        return
            actualMargin.mul(positionLeverage).mul(
                isLong ? (cumulativeFunding.sub(funding)) : (funding.sub(cumulativeFunding))
            );
    }

    function _getTradeFee(
        uint256 margin,
        FixedPoint.Unsigned leverage,
        FixedPoint.Unsigned productFee,
        address user,
        address sender,
        IFeeCalculator feeCalculator
    ) internal view returns (uint256) {
        FixedPoint.Unsigned fee = feeCalculator.getFee(productFee, user, sender);
        return FixedPoint.fromUnscaledUint(margin).mul(leverage).mul(fee).roundUp();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interfaces/oracle/IPriceFeed.sol';
import '../interfaces/perp/IDomFiPerp.sol';
import '../interfaces/perp/IFeeCalculator.sol';
import '../access/Governable.sol';
import '../lib/FixedPoint.sol';
import '../lib/PerpLib.sol';

/**
* @title Order book for Domination Finance. Manage orders that can be executed
         based on price triggers.
*/
contract OrderBook is Governable, ReentrancyGuard {
    using FixedPoint for FixedPoint.Unsigned;

    using SafeERC20 for IERC20;
    using Address for address payable;

    struct Ticket {
        address account;
        bytes16 accountPositionId;
        bytes32 productId;
        uint256 executionFee; // gas reimbursement to order executor
        FixedPoint.Unsigned triggerPrice;
        bool isLong;
        bool triggerAboveThreshold;
        uint64 submittedAt;
        uint64 canceledAt; // 0 unless the ticket has been canceled
        uint64 executedAt; // 0 unless the ticket has been executed
        uint64 executionDeadline; // time after which order can only be canceled
        bytes userData;
    }

    struct IncreaseOrder {
        uint256 margin;
        FixedPoint.Unsigned leverage;
        uint256 tradeFee;
        Ticket ticket;
    }

    struct DecreaseOrder {
        FixedPoint.Unsigned size;
        Ticket ticket;
    }

    mapping(address => mapping(uint256 => IncreaseOrder)) public increaseOrders;
    mapping(address => mapping(uint256 => DecreaseOrder)) public decreaseOrders;
    mapping(address => uint256) public lastOrderNumber;
    mapping(address => bool) public isKeeper;

    IDomFiPerp public immutable domFiPerp;
    IERC20 public immutable collateralToken;

    address public admin;
    IPriceFeed public oracle;
    IFeeCalculator public feeCalculator;

    uint256 public minExecutionFee;
    uint64 public minTimeExecuteDelay;
    uint64 public minTimeCancelDelay;
    bool public allowPublicKeeper = false;
    bool public isKeeperCall = false;

    event CreateIncreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        IncreaseOrder order
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        IncreaseOrder order
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        IncreaseOrder order
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        FixedPoint.Unsigned executionPrice,
        IncreaseOrder order
    );
    event ExecuteIncreaseOrderError(address indexed account, uint256 indexed orderNumber, string executionError);
    event ExecuteIncreaseOrderFailure(address indexed account, uint256 indexed orderNumber, bytes lowLevelData);

    //

    event CreateDecreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        DecreaseOrder order
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        DecreaseOrder order
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        DecreaseOrder order
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        FixedPoint.Unsigned executionPrice,
        uint256 decreaseMargin,
        DecreaseOrder order
    );
    event ExecuteDecreaseOrderError(address indexed account, uint256 indexed orderNumber, string executionError);
    event ExecuteDecreaseOrderFailure(address indexed account, uint256 indexed orderNumber, bytes lowLevelData);

    //

    event UpdateMinTimeExecuteDelay(uint64 minTimeExecuteDelay);
    event UpdateMinTimeCancelDelay(uint64 minTimeCancelDelay);
    event UpdateAllowPublicKeeper(bool allowPublicKeeper);
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateKeeper(address keeper, bool isAlive);
    event UpdateAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == admin, 'OrderBook: !admin');
        _;
    }

    modifier onlyKeeper() {
        require(isKeeper[msg.sender], 'OrderBook: !keeper');
        _;
    }

    constructor(
        IDomFiPerp _domFiPerp,
        IPriceFeed _oracle,
        uint256 _minExecutionFee,
        IFeeCalculator _feeCalculator
    ) {
        admin = msg.sender;
        domFiPerp = _domFiPerp;
        oracle = _oracle;
        collateralToken = IERC20Metadata(_domFiPerp.asset());
        minExecutionFee = _minExecutionFee;
        feeCalculator = _feeCalculator;
    }

    function setOracle(IPriceFeed _oracle) external onlyAdmin {
        oracle = _oracle;
    }

    function setFeeCalculator(IFeeCalculator _feeCalculator) external onlyAdmin {
        feeCalculator = _feeCalculator;
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyAdmin {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinTimeExecuteDelay(uint64 _minTimeExecuteDelay) external onlyAdmin {
        minTimeExecuteDelay = _minTimeExecuteDelay;
        emit UpdateMinTimeExecuteDelay(_minTimeExecuteDelay);
    }

    function setMinTimeCancelDelay(uint64 _minTimeCancelDelay) external onlyAdmin {
        minTimeCancelDelay = _minTimeCancelDelay;
        emit UpdateMinTimeCancelDelay(_minTimeCancelDelay);
    }

    function setAllowPublicKeeper(bool _allowPublicKeeper) external onlyAdmin {
        allowPublicKeeper = _allowPublicKeeper;
        emit UpdateAllowPublicKeeper(_allowPublicKeeper);
    }

    function setKeeper(address _account, bool _isActive) external onlyAdmin {
        isKeeper[_account] = _isActive;
        emit UpdateKeeper(_account, _isActive);
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
        emit UpdateAdmin(_admin);
    }

    function executeOrders(
        address[] memory _openAddresses,
        uint256[] memory _openOrderIndexes,
        address[] memory _closeAddresses,
        uint256[] memory _closeOrderIndexes,
        address payable _feeReceiver
    ) public {
        require(
            _openAddresses.length == _openOrderIndexes.length && _closeAddresses.length == _closeOrderIndexes.length,
            'OrderBook: not same length'
        );
        isKeeperCall = isKeeper[msg.sender];
        for (uint256 i = 0; i < _openAddresses.length; i++) {
            try this.executeIncreaseOrder(_openAddresses[i], _openOrderIndexes[i], _feeReceiver) {}
            catch Error(string memory executionError) {
                emit ExecuteIncreaseOrderError(_openAddresses[i], _openOrderIndexes[i], executionError);
            }
            catch (bytes memory lowLevelData) {
                emit ExecuteIncreaseOrderFailure(_openAddresses[i], _openOrderIndexes[i], lowLevelData);
            }
        }
        for (uint256 i = 0; i < _closeAddresses.length; i++) {
            try this.executeDecreaseOrder(_closeAddresses[i], _closeOrderIndexes[i], _feeReceiver) {}
            catch Error(string memory executionError) {
                emit ExecuteDecreaseOrderError(_closeAddresses[i], _closeOrderIndexes[i], executionError);
            }
            catch (bytes memory lowLevelData) {
                emit ExecuteDecreaseOrderFailure(_closeAddresses[i], _closeOrderIndexes[i], lowLevelData);
            }
        }
        isKeeperCall = false;
    }

    function cancelMultiple(
        address payable _address,
        uint256[] memory _openOrderIndexes,
        uint256[] memory _closeOrderIndexes
    ) external {
        for (uint256 i = 0; i < _openOrderIndexes.length; i++) {
            cancelIncreaseOrder(_address, _openOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _closeOrderIndexes.length; i++) {
            cancelDecreaseOrder(_address, _closeOrderIndexes[i]);
        }
    }

    struct IncreaseOrderParams {
        bytes16 accountPositionId;
        bytes32 productId;
        uint256 margin;
        FixedPoint.Unsigned leverage;
        bool isLong;
        FixedPoint.Unsigned triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
        uint64 executionDeadline;
        bytes userData;
    }

    function createOrders(
        DecreaseOrderParams[] calldata decreaseOrderParams,
        IncreaseOrderParams[] calldata increaseOrderParams
    ) external payable {
        uint256 unspentExecutionFees = msg.value;

        for (uint256 i = 0; i < increaseOrderParams.length; i++) {
            IncreaseOrderParams calldata order = increaseOrderParams[i];
            require(order.executionFee >= minExecutionFee, 'OrderBook: not enough executionFee');
            require(unspentExecutionFees >= order.executionFee, "OrderBook: executionFee not sent");
            unchecked { unspentExecutionFees -= order.executionFee; }

            uint256 tradeFee = getTradeFeeRate(order.productId, msg.sender)
                .mul(order.margin)
                .mul(order.leverage)
                .roundUp();

            collateralToken.safeTransferFrom(msg.sender, address(this), order.margin + tradeFee);
            _createIncreaseOrder(msg.sender, tradeFee, order);
        }

        for (uint256 i = 0; i < decreaseOrderParams.length; i++) {
            DecreaseOrderParams calldata order = decreaseOrderParams[i];
            require(order.executionFee >= minExecutionFee, 'OrderBook: not enough executionFee');
            require(unspentExecutionFees >= order.executionFee, "OrderBook: executionFee not sent");
            unchecked { unspentExecutionFees -= order.executionFee; }
            _createDecreaseOrder(msg.sender, order);
        }

        if (unspentExecutionFees > 0) {
            payable(msg.sender).transfer(unspentExecutionFees);
        }
    }

    /**
     * Before editing an order, must check that
     * - it belongs to the owner (i.e. not uninitialized)
     * - it hasn't been marked executed/canceled/expired
     */
    function checkValidUnresolved(Ticket storage ticket, address owner) internal view {
        require(ticket.account == owner, 'OrderBook: !ticket_account');
        require(ticket.canceledAt == 0, 'OrderBook: order deleted');
        require(ticket.executedAt == 0, 'OrderBook: order already executed');
    }

    /**
     * Before executing an order, must also check that
     * - it is after order delay but before expiration
     * - price is past the trigger
     */
    function checkExecutable(Ticket storage ticket) internal view returns (FixedPoint.Unsigned currentPrice) {
        require(block.timestamp < uint64(ticket.executionDeadline), 'OrderBook: execution deadline expired');
        require(
            (msg.sender == address(this) && isKeeperCall) ||
                isKeeper[msg.sender] ||
                (allowPublicKeeper && uint64(ticket.submittedAt) + minTimeExecuteDelay < block.timestamp),
            'OrderBook: min time execute delay'
        );

        IDomFiPerp.Product memory product = domFiPerp.getProduct(ticket.productId);
        currentPrice = oracle.getPrice(product.productId);

        bool priceTriggered = ticket.triggerAboveThreshold
            ? currentPrice.isGreaterThanOrEqual(ticket.triggerPrice)
            : currentPrice.isLessThanOrEqual(ticket.triggerPrice);

        require(priceTriggered, 'OrderBook: ticket price cond');
    }

    function _createIncreaseOrder(
        address _account,
        uint256 _tradeFee,
        IncreaseOrderParams memory _params
    ) private {
        require(_account != address(0), 'OrderBook: !account');
        require(_params.executionDeadline > block.timestamp, 'OrderBook: !executionDeadline');

        uint256 _orderNumber = lastOrderNumber[msg.sender] + 1;
        lastOrderNumber[_account] = _orderNumber;

        Ticket memory ticket = Ticket({
            account: _account,
            accountPositionId: _params.accountPositionId,
            productId: _params.productId,
            executionFee: _params.executionFee,
            isLong: _params.isLong,
            triggerPrice: _params.triggerPrice,
            triggerAboveThreshold: _params.triggerAboveThreshold,
            submittedAt: uint64(block.timestamp),
            canceledAt: 0,
            executedAt: 0,
            executionDeadline: _params.executionDeadline,
            userData: _params.userData
        });
            
        IncreaseOrder memory order = IncreaseOrder({
            ticket: ticket,
            margin: _params.margin,
            leverage: _params.leverage,
            tradeFee: _tradeFee
        });

        increaseOrders[_account][_orderNumber] = order;

        emit CreateIncreaseOrder(_account, _orderNumber, order.ticket.productId, order.ticket.accountPositionId, order);
    }

    function updateIncreaseOrder(
        uint256 _orderNumber,
        FixedPoint.Unsigned _leverage,
        FixedPoint.Unsigned _triggerPrice,
        bool _triggerAboveThreshold,
        bytes calldata _userData
    ) external nonReentrant {
        address _address = msg.sender;
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber > 0, 'OrderBook: !orderNumber');

        IncreaseOrder storage order = increaseOrders[_address][_orderNumber];
        checkValidUnresolved(order.ticket, _address);

        if (!order.leverage.isEqual(_leverage)) {
            FixedPoint.Unsigned feeRate = getTradeFeeRate(order.ticket.productId, order.ticket.account);

            uint256 margin = FixedPoint
                .fromUnscaledUint(order.margin + order.tradeFee)
                .div((feeRate.mul(_leverage)).add(1))
                .trunc();

            uint256 tradeFee = order.tradeFee + order.margin - margin;
            order.margin = margin;
            order.tradeFee = tradeFee;
            order.leverage = _leverage;
        }
        order.ticket.triggerPrice = _triggerPrice;
        order.ticket.triggerAboveThreshold = _triggerAboveThreshold;
        order.ticket.submittedAt = uint64(block.timestamp);
        order.ticket.userData = _userData;

        increaseOrders[_address][_orderNumber] = order;

        emit UpdateIncreaseOrder(
            order.ticket.account,
            _orderNumber,
            order.ticket.productId,
            order.ticket.accountPositionId,
            order
        );
    }

    function cancelIncreaseOrder(address payable _address, uint256 _orderNumber) public nonReentrant {
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber > 0, 'OrderBook: !orderNumber');

        IncreaseOrder storage order = increaseOrders[_address][_orderNumber];

        checkValidUnresolved(order.ticket, _address);
        require(
            order.ticket.submittedAt + minTimeCancelDelay < uint64(block.timestamp),
            'OrderBook: min time cancel delay'
        );
        require(
            _address == msg.sender || block.timestamp > order.ticket.executionDeadline,
            'OrderBook: unexpired'
        );

        order.ticket.canceledAt = uint64(block.timestamp);
        increaseOrders[_address][_orderNumber] = order;

        collateralToken.safeTransfer(_address, order.margin + order.tradeFee);
        _address.sendValue(order.ticket.executionFee);

        emit CancelIncreaseOrder(
            order.ticket.account,
            _orderNumber,
            order.ticket.productId,
            order.ticket.accountPositionId,
            order
        );
    }

    function executeIncreaseOrder(
        address _address,
        uint256 _orderNumber,
        address payable _feeReceiver
    ) public nonReentrant {
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber > 0, 'OrderBook: !orderNumber');

        IncreaseOrder storage order = increaseOrders[_address][_orderNumber];

        checkValidUnresolved(order.ticket, _address);
        FixedPoint.Unsigned currentPrice = checkExecutable(order.ticket);

        order.ticket.executedAt = uint64(block.timestamp);
        increaseOrders[_address][_orderNumber] = order;

        collateralToken.safeApprove(address(domFiPerp), order.margin + order.tradeFee);

        IPerpetual.OpenPositionParams[] memory params = new IPerpetual.OpenPositionParams[](1);
        params[0] = IPerpetual.OpenPositionParams({
            user: order.ticket.account,
            userPositionId: order.ticket.accountPositionId,
            productId: order.ticket.productId,
            margin: order.margin,
            isLong: order.ticket.isLong,
            leverage: order.leverage
        });
        domFiPerp.openPositions(params);

        // pay executor
        _feeReceiver.sendValue(order.ticket.executionFee);

        emit ExecuteIncreaseOrder(
            order.ticket.account,
            _orderNumber,
            order.ticket.productId,
            order.ticket.accountPositionId,
            currentPrice,
            order
        );
    }

    struct DecreaseOrderParams {
        bytes16 accountPositionId;
        bytes32 productId;
        FixedPoint.Unsigned size;
        bool isLong;
        FixedPoint.Unsigned triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
        uint64 executionDeadline;
        bytes userData;
    }

    function _createDecreaseOrder(
        address _account,
        DecreaseOrderParams memory _params
    ) private {
        require(_account != address(0), 'OrderBook: !account');
        require(_params.accountPositionId != 0, 'OrderBook: !postionNumber');
        require(_params.executionDeadline > block.timestamp, 'OrderBook: !executionDeadline');

        uint256 _orderNumber = lastOrderNumber[_account] + 1;
        lastOrderNumber[_account] = _orderNumber;

        Ticket memory ticket = Ticket({
            account: _account,
            productId: _params.productId,
            accountPositionId: _params.accountPositionId,
            executionFee: _params.executionFee,
            isLong: _params.isLong,
            triggerAboveThreshold: _params.triggerAboveThreshold,
            triggerPrice: _params.triggerPrice,
            submittedAt: uint64(block.timestamp),
            canceledAt: 0,
            executedAt: 0,
            executionDeadline: _params.executionDeadline,
            userData: _params.userData
        });

        DecreaseOrder memory order = DecreaseOrder({
            ticket: ticket,
            size: _params.size
        });

        decreaseOrders[_account][_orderNumber] = order;

        emit CreateDecreaseOrder(
            _account,
            _orderNumber,
            _params.productId,
            _params.accountPositionId,
            order
        );
    }

    function executeDecreaseOrder(
        address _address,
        uint256 _orderNumber,
        address payable _feeReceiver
    ) public nonReentrant {
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber != 0, 'OrderBook: !orderNumber');

        DecreaseOrder storage order = decreaseOrders[_address][_orderNumber];
        checkValidUnresolved(order.ticket, _address);
        FixedPoint.Unsigned currentPrice = checkExecutable(order.ticket);
        IDomFiPerp.Position memory position = domFiPerp.getPosition(_address, order.ticket.accountPositionId);
        order.ticket.executedAt = uint64(block.timestamp);

        decreaseOrders[_address][_orderNumber] = order;

        uint256 closeMargin = order.size.div(position.leverage).roundUp();
        if (closeMargin > position.margin) {
            closeMargin = position.margin;
        }

        IPerpetual.ClosePositionParams[] memory params = new IPerpetual.ClosePositionParams[](1);
        params[0] = IPerpetual.ClosePositionParams({
            user: _address,
            userPositionId: order.ticket.accountPositionId,
            margin: closeMargin
        });
        domFiPerp.closePositions(params);

        // pay executor
        _feeReceiver.sendValue(order.ticket.executionFee);

        emit ExecuteDecreaseOrder(
            order.ticket.account,
            _orderNumber,
            order.ticket.productId,
            order.ticket.accountPositionId,
            currentPrice,
            closeMargin,
            order
        );
    }

    function cancelDecreaseOrder(address payable _address, uint256 _orderNumber) public nonReentrant {
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber != 0, 'OrderBook: !orderNumber');

        DecreaseOrder storage order = decreaseOrders[_address][_orderNumber];
        checkValidUnresolved(order.ticket, _address);

        require(
            order.ticket.submittedAt + minTimeCancelDelay < block.timestamp,
            'OrderBook: min time cancel delay'
        );
        require(
            _address == msg.sender || block.timestamp > order.ticket.executionDeadline,
            'OrderBook: unexpired'
        );

        order.ticket.canceledAt = uint64(block.timestamp);
        decreaseOrders[_address][_orderNumber] = order;

        _address.sendValue(order.ticket.executionFee);

        emit CancelDecreaseOrder(
            order.ticket.account,
            _orderNumber,
            order.ticket.productId,
            order.ticket.accountPositionId,
            order
        );
    }

    function updateDecreaseOrder(
        uint256 _orderNumber,
        FixedPoint.Unsigned _size,
        FixedPoint.Unsigned _triggerPrice,
        bool _triggerAboveThreshold,
        bytes calldata _userData
    ) external nonReentrant {
        address _address = msg.sender;
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber != 0, 'OrderBook: !orderNumber');

        DecreaseOrder storage order = decreaseOrders[_address][_orderNumber];
        checkValidUnresolved(order.ticket, _address);

        order.size = _size;
        order.ticket.triggerPrice = _triggerPrice;
        order.ticket.triggerAboveThreshold = _triggerAboveThreshold;
        order.ticket.submittedAt = uint64(block.timestamp);
        order.ticket.userData = _userData;

        decreaseOrders[_address][_orderNumber] = order;

        emit UpdateDecreaseOrder(_address, _orderNumber, order.ticket.productId, order.ticket.accountPositionId, order);
    }

    function getTradeFeeRate(bytes32 _productId, address _account) private view returns (FixedPoint.Unsigned) {
        IDomFiPerp.Product memory product = domFiPerp.getProduct(_productId);
        return feeCalculator.getFee(product.fee, _account, msg.sender);
    }

    receive() external payable {}
}