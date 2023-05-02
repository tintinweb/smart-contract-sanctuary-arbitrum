// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

struct Escrow {
  /// @notice The escrowed token
  IERC20 token;
  /// @notice Timestamp of the start of the unlock
  uint32 start;
  /// @notice The timestamp the unlock ends at
  uint32 end;
  /// @notice The timestamp the index was last updated at
  uint32 lastUpdateTime;
  /// @notice Initial balance of the escrow
  uint256 initialBalance;
  /// @notice Current balance of the escrow
  uint256 balance;
  /// @notice Owner of the escrow
  address account;
}

struct Fee {
  /// @notice Accrued fee amount
  uint256 accrued;
  /// @notice Fee percentage in 1e18 for 100% (1 BPS = 1e14)
  uint256 feePerc;
}

interface IMultiRewardEscrow {
  function lock(
    IERC20 token,
    address account,
    uint256 amount,
    uint32 duration,
    uint32 offset
  ) external;

  function setFees(IERC20[] memory tokens, uint256[] memory tokenFees) external;

  function fees(IERC20 token) external view returns (Fee memory);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IERC4626Upgradeable as IERC4626, IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import { IOwned } from "./IOwned.sol";
import { IPermit } from "./IPermit.sol";
import { IPausable } from "./IPausable.sol";
import { IMultiRewardEscrow } from "./IMultiRewardEscrow.sol";

/// @notice The whole reward and accrual logic is heavily based on the Fei Protocol's Flywheel contracts.
/// https://github.com/fei-protocol/flywheel-v2/blob/main/src/rewards/FlywheelStaticRewards.sol
/// https://github.com/fei-protocol/flywheel-v2/blob/main/src/FlywheelCore.sol
struct RewardInfo {
  /// @notice scalar for the rewardToken
  uint64 ONE;
  /// @notice Rewards per second
  uint160 rewardsPerSecond;
  /// @notice The timestamp the rewards end at
  /// @dev use 0 to specify no end
  uint32 rewardsEndTimestamp;
  /// @notice The strategy's last updated index
  uint224 index;
  /// @notice The timestamp the index was last updated at
  uint32 lastUpdatedTimestamp;
}

struct EscrowInfo {
  /// @notice Percentage of reward that gets escrowed in 1e18 (1e18 = 100%, 1e14 = 1 BPS)
  uint192 escrowPercentage;
  /// @notice Duration of the escrow in seconds
  uint32 escrowDuration;
  /// @notice A cliff before the escrow starts in seconds
  uint32 offset;
}

interface IMultiRewardStaking is IERC4626, IOwned, IPermit, IPausable {
  function addRewardToken(
    IERC20 rewardToken,
    uint160 rewardsPerSecond,
    uint256 amount,
    bool useEscrow,
    uint192 escrowPercentage,
    uint32 escrowDuration,
    uint32 offset
  ) external;

  function changeRewardSpeed(IERC20 rewardToken, uint160 rewardsPerSecond) external;

  function fundReward(IERC20 rewardToken, uint256 amount) external;

  function initialize(
    IERC20 _stakingToken,
    IMultiRewardEscrow _escrow,
    address _owner
  ) external;

  function rewardInfos(IERC20 rewardToken) external view returns (RewardInfo memory);

  function escrowInfos(IERC20 rewardToken) external view returns (EscrowInfo memory);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IOwned {
  function owner() external view returns (address);

  function nominatedOwner() external view returns (address);

  function nominateNewOwner(address owner) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IPausable {
  function paused() external view returns (bool);

  function pause() external;

  function unpause() external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IPermit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function nonces(address caller) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {IOwned} from "../IOwned.sol";
import {IERC4626Upgradeable as IERC4626} from "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import {IPermit} from "../IPermit.sol";
import {IPausable} from "../IPausable.sol";

interface IAdapter is IERC4626, IOwned, IPermit, IPausable {
    function strategy() external view returns (address);

    function strategyConfig() external view returns (bytes memory);

    function strategyDeposit(uint256 assets, uint256 shares) external;

    function strategyWithdraw(uint256 assets, uint256 shares) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function setPerformanceFee(uint256 fee) external;

    function performanceFee() external view returns (uint256);

    function highWaterMark() external view returns (uint256);

    function accruedPerformanceFee() external view returns (uint256);

    function harvest() external;

    function lastHarvest() external view returns (uint256);

    function harvestCooldown() external view returns (uint256);

    function setHarvestCooldown(uint256 harvestCooldown) external;

    function initialize(
        bytes memory adapterBaseData,
        address externalRegistry,
        bytes memory adapterData
    ) external;

    function decimals() external view returns (uint8);

    function decimalOffset() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

interface IAdminProxy is IOwned {
  function execute(address target, bytes memory callData) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";
import { Template } from "./ITemplateRegistry.sol";

interface ICloneFactory is IOwned {
  function deploy(Template memory template, bytes memory data) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

interface ICloneRegistry is IOwned {
  function cloneExists(address clone) external view returns (bool);

  function addClone(
    bytes32 templateCategory,
    bytes32 templateId,
    address clone
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ICloneFactory } from "./ICloneFactory.sol";
import { ICloneRegistry } from "./ICloneRegistry.sol";
import { IPermissionRegistry } from "./IPermissionRegistry.sol";
import { ITemplateRegistry, Template } from "./ITemplateRegistry.sol";

interface IDeploymentController is ICloneFactory, ICloneRegistry {
  function templateCategoryExists(bytes32 templateCategory) external view returns (bool);

  function templateExists(bytes32 templateId) external view returns (bool);

  function addTemplate(
    bytes32 templateCategory,
    bytes32 templateId,
    Template memory template
  ) external;

  function addTemplateCategory(bytes32 templateCategory) external;

  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external;

  function getTemplate(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory);

  function nominateNewDependencyOwner(address _owner) external;

  function acceptDependencyOwnership() external;

  function cloneFactory() external view returns (ICloneFactory);

  function cloneRegistry() external view returns (ICloneRegistry);

  function templateRegistry() external view returns (ITemplateRegistry);

  function PermissionRegistry() external view returns (IPermissionRegistry);

  function addClone(address clone) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

struct Permission {
  bool endorsed;
  bool rejected;
}

interface IPermissionRegistry is IOwned {
  function setPermissions(address[] calldata targets, Permission[] calldata newPermissions) external;

  function endorsed(address target) external view returns (bool);

  function rejected(address target) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IStrategy {
  function harvest() external;

  function verifyAdapterSelectorCompatibility(bytes4[8] memory sigs) external;

  function verifyAdapterCompatibility(bytes memory data) external;

  function setUp(bytes memory data) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

/// @notice Template used for creating new clones
struct Template {
  /// @Notice Cloneable implementation address
  address implementation;
  /// @Notice implementations can only be cloned if endorsed
  bool endorsed;
  /// @Notice Optional - Metadata CID which can be used by the frontend to add informations to a vault/adapter...
  string metadataCid;
  /// @Notice If true, the implementation will require an init data to be passed to the clone function
  bool requiresInitData;
  /// @Notice Optional - Address of an registry which can be used in an adapter initialization
  address registry;
  /// @Notice Optional - Only used by Strategies. EIP-165 Signatures of an adapter required by a strategy
  bytes4[8] requiredSigs;
}

interface ITemplateRegistry is IOwned {
  function templates(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory);

  function templateCategoryExists(bytes32 templateCategory) external view returns (bool);

  function templateExists(bytes32 templateId) external view returns (bool);

  function getTemplateCategories() external view returns (bytes32[] memory);

  function getTemplate(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory);

  function getTemplateIds(bytes32 templateCategory) external view returns (bytes32[] memory);

  function addTemplate(
    bytes32 templateType,
    bytes32 templateId,
    Template memory template
  ) external;

  function addTemplateCategory(bytes32 templateCategory) external;

  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IERC4626Upgradeable as IERC4626, IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

// Fees are set in 1e18 for 100% (1 BPS = 1e14)
struct VaultFees {
  uint64 deposit;
  uint64 withdrawal;
  uint64 management;
  uint64 performance;
}

/// @notice Init data for a Vault
struct VaultInitParams {
  /// @Notice Address of the deposit asset
  IERC20 asset;
  /// @Notice Address of the adapter used by the vault
  IERC4626 adapter;
  /// @Notice Fees used by the vault
  VaultFees fees;
  /// @Notice Address of the recipient of the fees
  address feeRecipient;
  /// @Notice Maximum amount of assets that can be deposited
  uint256 depositLimit;
  /// @Notice Owner of the vault (Usually the submitter)
  address owner;
}

interface IVault is IERC4626 {
  // FEE VIEWS

  function accruedManagementFee() external view returns (uint256);

  function accruedPerformanceFee() external view returns (uint256);

  function highWaterMark() external view returns (uint256);

  function assetsCheckpoint() external view returns (uint256);

  function feesUpdatedAt() external view returns (uint256);

  function feeRecipient() external view returns (address);

  // USER INTERACTIONS

  function deposit(uint256 assets) external returns (uint256);

  function mint(uint256 shares) external returns (uint256);

  function withdraw(uint256 assets) external returns (uint256);

  function redeem(uint256 shares) external returns (uint256);

  function takeManagementAndPerformanceFees() external;

  // MANAGEMENT FUNCTIONS - STRATEGY

  function adapter() external view returns (address);

  function proposedAdapter() external view returns (address);

  function proposedAdapterTime() external view returns (uint256);

  function proposeAdapter(IERC4626 newAdapter) external;

  function changeAdapter() external;

  // MANAGEMENT FUNCTIONS - FEES

  function fees() external view returns (VaultFees memory);

  function proposedFees() external view returns (VaultFees memory);

  function proposedFeeTime() external view returns (uint256);

  function proposeFees(VaultFees memory) external;

  function changeFees() external;

  function setFeeRecipient(address feeRecipient) external;

  // MANAGEMENT FUNCTIONS - OTHER

  function quitPeriod() external view returns (uint256);

  function setQuitPeriod(uint256 _quitPeriod) external;

  function depositLimit() external view returns (uint256);

  function setDepositLimit(uint256 _depositLimit) external;

  // INITIALIZE

  function initialize(
    IERC20 asset_,
    IERC4626 adapter_,
    VaultFees memory fees_,
    address feeRecipient_,
    uint256 depositLimit_,
    address owner
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { VaultInitParams, VaultFees, IERC4626, IERC20 } from "./IVault.sol";
import { VaultMetadata } from "./IVaultRegistry.sol";
import { IDeploymentController } from "./IDeploymentController.sol";

struct DeploymentArgs {
  /// @Notice templateId
  bytes32 id;
  /// @Notice encoded init params
  bytes data;
}

interface IVaultController {
  function deployVault(
    VaultInitParams memory vaultData,
    DeploymentArgs memory adapterData,
    DeploymentArgs memory strategyData,
    bool deployStaking,
    bytes memory rewardsData,
    VaultMetadata memory metadata,
    uint256 initialDeposit
  ) external returns (address);

  function deployAdapter(
    IERC20 asset,
    DeploymentArgs memory adapterData,
    DeploymentArgs memory strategyData,
    uint256 initialDeposit
  ) external returns (address);

  function deployStaking(IERC20 asset) external returns (address);

  function proposeVaultAdapters(address[] calldata vaults, IERC4626[] calldata newAdapter) external;

  function changeVaultAdapters(address[] calldata vaults) external;

  function proposeVaultFees(address[] calldata vaults, VaultFees[] calldata newFees) external;

  function changeVaultFees(address[] calldata vaults) external;

  function setVaultQuitPeriods(address[] calldata vaults, uint256[] calldata quitPeriods) external;

  function setVaultFeeRecipients(address[] calldata vaults, address[] calldata feeRecipients) external;

  function registerVaults(address[] calldata vaults, VaultMetadata[] calldata metadata) external;

  function addClones(address[] calldata clones) external;

  function toggleEndorsements(address[] calldata targets) external;

  function toggleRejections(address[] calldata targets) external;

  function addStakingRewardsTokens(address[] calldata vaults, bytes[] calldata rewardsTokenData) external;

  function changeStakingRewardsSpeeds(
    address[] calldata vaults,
    IERC20[] calldata rewardTokens,
    uint160[] calldata rewardsSpeeds
  ) external;

  function fundStakingRewards(
    address[] calldata vaults,
    IERC20[] calldata rewardTokens,
    uint256[] calldata amounts
  ) external;

  function setEscrowTokenFees(IERC20[] calldata tokens, uint256[] calldata fees) external;

  function addTemplateCategories(bytes32[] calldata templateCategories) external;

  function toggleTemplateEndorsements(bytes32[] calldata templateCategories, bytes32[] calldata templateIds) external;

  function pauseAdapters(address[] calldata vaults) external;

  function pauseVaults(address[] calldata vaults) external;

  function unpauseAdapters(address[] calldata vaults) external;

  function unpauseVaults(address[] calldata vaults) external;

  function nominateNewAdminProxyOwner(address newOwner) external;

  function acceptAdminProxyOwnership() external;

  function setPerformanceFee(uint256 newFee) external;

  function setAdapterPerformanceFees(address[] calldata adapters) external;

  function performanceFee() external view returns (uint256);

  function setHarvestCooldown(uint256 newCooldown) external;

  function setAdapterHarvestCooldowns(address[] calldata adapters) external;

  function harvestCooldown() external view returns (uint256);

  function setDeploymentController(IDeploymentController _deploymentController) external;

  function setActiveTemplateId(bytes32 templateCategory, bytes32 templateId) external;

  function activeTemplateId(bytes32 templateCategory) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

struct VaultMetadata {
  /// @notice Vault address
  address vault;
  /// @notice Staking contract for the vault
  address staking;
  /// @notice Owner and Vault creator
  address creator;
  /// @notice IPFS CID of vault metadata
  string metadataCID;
  /// @notice OPTIONAL - If the asset is an Lp Token these are its underlying assets
  address[8] swapTokenAddresses;
  /// @notice OPTIONAL - If the asset is an Lp Token its the pool address
  address swapAddress;
  /// @notice OPTIONAL - If the asset is an Lp Token this is the identifier of the exchange (1 = curve)
  uint256 exchange;
}

interface IVaultRegistry is IOwned {
  function getVault(address vault) external view returns (VaultMetadata memory);

  function getSubmitter(address vault) external view returns (address);

  function registerVault(VaultMetadata memory metadata) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
  address public owner;
  address public nominatedOwner;

  constructor(address _owner) {
    require(_owner != address(0), "Owner address cannot be 0");
    owner = _owner;
    emit OwnerChanged(address(0), _owner);
  }

  function nominateNewOwner(address _owner) external virtual onlyOwner {
    nominatedOwner = _owner;
    emit OwnerNominated(_owner);
  }

  function acceptOwnership() external virtual {
    require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
    emit OwnerChanged(owner, nominatedOwner);
    owner = nominatedOwner;
    nominatedOwner = address(0);
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  function _onlyOwner() private view {
    require(msg.sender == owner, "Only the contract owner may perform this action");
  }

  event OwnerNominated(address newOwner);
  event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import {SafeERC20Upgradeable as SafeERC20} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Owned} from "../utils/Owned.sol";
import {IVault, VaultInitParams, VaultFees, IERC4626, IERC20} from "../interfaces/vault/IVault.sol";
import {IMultiRewardStaking} from "../interfaces/IMultiRewardStaking.sol";
import {IMultiRewardEscrow} from "../interfaces/IMultiRewardEscrow.sol";
import {IDeploymentController, ICloneRegistry} from "../interfaces/vault/IDeploymentController.sol";
import {ITemplateRegistry, Template} from "../interfaces/vault/ITemplateRegistry.sol";
import {IPermissionRegistry, Permission} from "../interfaces/vault/IPermissionRegistry.sol";
import {IVaultRegistry, VaultMetadata} from "../interfaces/vault/IVaultRegistry.sol";
import {IAdminProxy} from "../interfaces/vault/IAdminProxy.sol";
import {IStrategy} from "../interfaces/vault/IStrategy.sol";
import {IAdapter} from "../interfaces/vault/IAdapter.sol";
import {IPausable} from "../interfaces/IPausable.sol";
import {DeploymentArgs} from "../interfaces/vault/IVaultController.sol";

/**
 * @title   VaultController
 * @author  RedVeil
 * @notice  Admin contract for the vault ecosystem.
 *
 * Deploys Vaults, Adapter, Strategies and Staking contracts.
 * Calls admin functions on deployed contracts.
 */
contract VaultController is Owned {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public immutable VAULT = "Vault";
    bytes32 public immutable ADAPTER = "Adapter";
    bytes32 public immutable STRATEGY = "Strategy";
    bytes32 public immutable STAKING = "Staking";
    bytes4 internal immutable DEPLOY_SIG =
        bytes4(keccak256("deploy(bytes32,bytes32,bytes)"));

    /**
     * @notice Constructor of this contract.
     * @param _owner Owner of the contract. Controls management functions.
     * @param _adminProxy `AdminProxy` ownes contracts in the vault ecosystem.
     * @param _deploymentController `DeploymentController` with auxiliary deployment contracts.
     * @param _vaultRegistry `VaultRegistry` to safe vault metadata.
     * @param _permissionRegistry `permissionRegistry` to add endorsements and rejections.
     * @param _escrow `MultiRewardEscrow` To escrow rewards of staking contracts.
     */
    constructor(
        address _owner,
        IAdminProxy _adminProxy,
        IDeploymentController _deploymentController,
        IVaultRegistry _vaultRegistry,
        IPermissionRegistry _permissionRegistry,
        IMultiRewardEscrow _escrow
    ) Owned(_owner) {
        adminProxy = _adminProxy;
        vaultRegistry = _vaultRegistry;
        permissionRegistry = _permissionRegistry;
        escrow = _escrow;

        _setDeploymentController(_deploymentController);

        activeTemplateId[STAKING] = "MultiRewardStaking";
        activeTemplateId[VAULT] = "V1";
    }

    /*//////////////////////////////////////////////////////////////
                          VAULT DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    event VaultDeployed(
        address indexed vault,
        address indexed staking,
        address indexed adapter
    );

    error InvalidConfig();

    /**
     * @notice Deploy a new Vault. Optionally with an Adapter and Staking. Caller must be owner.
     * @param vaultData Vault init params.
     * @param adapterData Encoded adapter init data.
     * @param strategyData Encoded strategy init data.
     * @param deployStaking Should we deploy a staking contract for the vault?
     * @param rewardsData Encoded data to add a rewards to the staking contract
     * @param metadata Vault metadata for the `VaultRegistry` (Will be used by the frontend for additional informations)
     * @param initialDeposit Initial deposit to the vault. If 0, no deposit will be made.
     * @dev This function is the one stop solution to create a new vault with all necessary admin functions or auxiliery contracts.
     * @dev If `rewardsData` is not empty `deployStaking` must be true
     */
    function deployVault(
        VaultInitParams memory vaultData,
        DeploymentArgs memory adapterData,
        DeploymentArgs memory strategyData,
        bool deployStaking,
        bytes memory rewardsData,
        VaultMetadata memory metadata,
        uint256 initialDeposit
    ) external canCreate returns (address vault) {
        IDeploymentController _deploymentController = deploymentController;

        _verifyToken(address(vaultData.asset));
        if (
            address(vaultData.adapter) != address(0) &&
            (adapterData.id > 0 ||
                !cloneRegistry.cloneExists(address(vaultData.adapter)))
        ) revert InvalidConfig();

        if (adapterData.id > 0)
            vaultData.adapter = IERC4626(
                _deployAdapter(
                    vaultData.asset,
                    adapterData,
                    strategyData,
                    _deploymentController
                )
            );

        vault = _deployVault(vaultData, _deploymentController);

        address staking;
        if (deployStaking)
            staking = _deployStaking(
                IERC20(address(vault)),
                _deploymentController
            );

        _registerCreatedVault(vault, staking, metadata);

        if (rewardsData.length > 0) {
            if (!deployStaking) revert InvalidConfig();
            _handleVaultStakingRewards(vault, rewardsData);
        }

        emit VaultDeployed(vault, staking, address(vaultData.adapter));

        _handleInitialDeposit(
            initialDeposit,
            IERC20(vaultData.asset),
            IERC4626(vault)
        );
    }

    /// @notice Deploys a new vault contract using the `activeTemplateId`.
    function _deployVault(
        VaultInitParams memory vaultData,
        IDeploymentController _deploymentController
    ) internal returns (address vault) {
        vaultData.owner = address(adminProxy);

        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(
                DEPLOY_SIG,
                VAULT,
                activeTemplateId[VAULT],
                abi.encodeWithSelector(IVault.initialize.selector, vaultData)
            )
        );

        vault = abi.decode(returnData, (address));
    }

    /// @notice Registers newly created vault metadata.
    function _registerCreatedVault(
        address vault,
        address staking,
        VaultMetadata memory metadata
    ) internal {
        metadata.vault = vault;
        metadata.staking = staking;
        metadata.creator = msg.sender;

        _registerVault(vault, metadata);
    }

    /// @notice Prepares and calls `addStakingRewardsTokens` for the newly created staking contract.
    function _handleVaultStakingRewards(
        address vault,
        bytes memory rewardsData
    ) internal {
        address[] memory vaultContracts = new address[](1);
        bytes[] memory rewardsDatas = new bytes[](1);

        vaultContracts[0] = vault;
        rewardsDatas[0] = rewardsData;

        addStakingRewardsTokens(vaultContracts, rewardsDatas);
    }

    function _handleInitialDeposit(
        uint256 initialDeposit,
        IERC20 asset,
        IERC4626 target
    ) internal {
        if (initialDeposit > 0) {
            asset.safeTransferFrom(msg.sender, address(this), initialDeposit);
            asset.approve(address(target), initialDeposit);
            target.deposit(initialDeposit, msg.sender);
        }
    }

    /*//////////////////////////////////////////////////////////////
                      ADAPTER DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploy a new Adapter with our without a strategy. Caller must be owner.
     * @param asset Asset which will be used by the adapter.
     * @param adapterData Encoded adapter init data.
     * @param strategyData Encoded strategy init data.
     */
    function deployAdapter(
        IERC20 asset,
        DeploymentArgs memory adapterData,
        DeploymentArgs memory strategyData,
        uint256 initialDeposit
    ) external canCreate returns (address adapter) {
        _verifyToken(address(asset));

        adapter = _deployAdapter(
            asset,
            adapterData,
            strategyData,
            deploymentController
        );

        _handleInitialDeposit(initialDeposit, asset, IERC4626(adapter));
    }

    /**
     * @notice Deploys an adapter and optionally a strategy.
     * @dev Adds the newly deployed strategy to the adapter.
     */
    function _deployAdapter(
        IERC20 asset,
        DeploymentArgs memory adapterData,
        DeploymentArgs memory strategyData,
        IDeploymentController _deploymentController
    ) internal returns (address) {
        address strategy;
        bytes4[8] memory requiredSigs;
        if (strategyData.id > 0) {
            strategy = _deployStrategy(strategyData, _deploymentController);
            requiredSigs = templateRegistry
                .getTemplate(STRATEGY, strategyData.id)
                .requiredSigs;
        }

        return
            __deployAdapter(
                adapterData,
                abi.encode(
                    asset,
                    address(adminProxy),
                    IStrategy(strategy),
                    harvestCooldown,
                    requiredSigs,
                    strategyData.data
                ),
                _deploymentController
            );
    }

    /// @notice Deploys an adapter and sets the management fee via `AdminProxy`
    function __deployAdapter(
        DeploymentArgs memory adapterData,
        bytes memory baseAdapterData,
        IDeploymentController _deploymentController
    ) internal returns (address adapter) {
        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(
                DEPLOY_SIG,
                ADAPTER,
                adapterData.id,
                _encodeAdapterData(adapterData, baseAdapterData)
            )
        );

        adapter = abi.decode(returnData, (address));

        adminProxy.execute(
            adapter,
            abi.encodeWithSelector(
                IAdapter.setPerformanceFee.selector,
                performanceFee
            )
        );
    }

    /// @notice Encodes adapter init call. Was moved into its own function to fix "stack too deep" error.
    function _encodeAdapterData(
        DeploymentArgs memory adapterData,
        bytes memory baseAdapterData
    ) internal returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IAdapter.initialize.selector,
                baseAdapterData,
                templateRegistry.getTemplate(ADAPTER, adapterData.id).registry,
                adapterData.data
            );
    }

    /// @notice Deploys a new strategy contract.
    function _deployStrategy(
        DeploymentArgs memory strategyData,
        IDeploymentController _deploymentController
    ) internal returns (address strategy) {
        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(DEPLOY_SIG, STRATEGY, strategyData.id, "")
        );

        strategy = abi.decode(returnData, (address));
    }

    /*//////////////////////////////////////////////////////////////
                    STAKING DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploy a new staking contract. Caller must be owner.
     * @param asset The staking token for the new contract.
     * @dev Deploys `MultiRewardsStaking` based on the latest templateTemplateKey.
     */
    function deployStaking(IERC20 asset) external canCreate returns (address) {
        _verifyToken(address(asset));
        return _deployStaking(asset, deploymentController);
    }

    /// @notice Deploys a new staking contract using the activeTemplateId.
    function _deployStaking(
        IERC20 asset,
        IDeploymentController _deploymentController
    ) internal returns (address staking) {
        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(
                DEPLOY_SIG,
                STAKING,
                activeTemplateId[STAKING],
                abi.encodeWithSelector(
                    IMultiRewardStaking.initialize.selector,
                    asset,
                    escrow,
                    adminProxy
                )
            )
        );

        staking = abi.decode(returnData, (address));
    }

    /*//////////////////////////////////////////////////////////////
                    VAULT MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    error DoesntExist(address adapter);

    /**
     * @notice Propose a new Adapter. Caller must be creator of the vaults.
     * @param vaults Vaults to propose the new adapter for.
     * @param newAdapter New adapters to propose.
     */
    function proposeVaultAdapters(
        address[] calldata vaults,
        IERC4626[] calldata newAdapter
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, newAdapter.length);

        ICloneRegistry _cloneRegistry = cloneRegistry;
        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);
            if (!_cloneRegistry.cloneExists(address(newAdapter[i])))
                revert DoesntExist(address(newAdapter[i]));

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.proposeAdapter.selector,
                    newAdapter[i]
                )
            );
        }
    }

    /**
     * @notice Change adapter of a vault to the previously proposed adapter.
     * @param vaults Addresses of the vaults to change
     */
    function changeVaultAdapters(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint8 i = 0; i < len; i++) {
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IVault.changeAdapter.selector)
            );
        }
    }

    /**
     * @notice Sets new fees per vault. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param fees New fee structures for these vaults
     * @dev Value is in 1e18, e.g. 100% = 1e18 - 1 BPS = 1e12
     */
    function proposeVaultFees(
        address[] calldata vaults,
        VaultFees[] calldata fees
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, fees.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IVault.proposeFees.selector, fees[i])
            );
        }
    }

    /**
     * @notice Change adapter of a vault to the previously proposed adapter.
     * @param vaults Addresses of the vaults
     */
    function changeVaultFees(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint8 i = 0; i < len; i++) {
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IVault.changeFees.selector)
            );
        }
    }

    /**
     * @notice Sets new Quit Periods for Vaults. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param quitPeriods QuitPeriod in seconds
     * @dev Minimum value is 1 day max is 7 days.
     * @dev Cant be called if recently a new fee or adapter has been proposed
     */
    function setVaultQuitPeriods(
        address[] calldata vaults,
        uint256[] calldata quitPeriods
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, quitPeriods.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.setQuitPeriod.selector,
                    quitPeriods[i]
                )
            );
        }
    }

    /**
     * @notice Sets new Fee Recipients for Vaults. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param feeRecipients fee recipient for this vault
     * @dev address must not be 0
     */
    function setVaultFeeRecipients(
        address[] calldata vaults,
        address[] calldata feeRecipients
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, feeRecipients.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.setFeeRecipient.selector,
                    feeRecipients[i]
                )
            );
        }
    }

    /**
     * @notice Sets new DepositLimit for Vaults. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param depositLimits Maximum amount of assets that can be deposited.
     */
    function setVaultDepositLimits(
        address[] calldata vaults,
        uint256[] calldata depositLimits
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, depositLimits.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.setDepositLimit.selector,
                    depositLimits[i]
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          REGISTER VAULT
    //////////////////////////////////////////////////////////////*/

    IVaultRegistry public vaultRegistry;

    /// @notice Call the `VaultRegistry` to register a vault via `AdminProxy`
    function _registerVault(
        address vault,
        VaultMetadata memory metadata
    ) internal {
        adminProxy.execute(
            address(vaultRegistry),
            abi.encodeWithSelector(
                IVaultRegistry.registerVault.selector,
                metadata
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                    ENDORSEMENT / REJECTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set permissions for an array of target. Caller must be owner.
     * @param targets `AdminProxy`
     * @param newPermissions An array of permissions to set for the targets.
     * @dev See `PermissionRegistry` for more details
     */
    function setPermissions(
        address[] calldata targets,
        Permission[] calldata newPermissions
    ) external onlyOwner {
        // No need to check matching array length since its already done in the permissionRegistry
        adminProxy.execute(
            address(permissionRegistry),
            abi.encodeWithSelector(
                IPermissionRegistry.setPermissions.selector,
                targets,
                newPermissions
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                      STAKING MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Adds a new rewardToken which can be earned via staking. Caller must be creator of the Vault or owner.
     * @param vaults Vaults of which the staking contracts should be targeted
     * @param rewardTokenData Token that can be earned by staking.
     * @dev `rewardToken` - Token that can be earned by staking.
     * @dev `rewardsPerSecond` - The rate in which `rewardToken` will be accrued.
     * @dev `amount` - Initial funding amount for this reward.
     * @dev `useEscrow Bool` - if the rewards should be escrowed on claim.
     * @dev `escrowPercentage` - The percentage of the reward that gets escrowed in 1e18. (1e18 = 100%, 1e14 = 1 BPS)
     * @dev `escrowDuration` - The duration of the escrow.
     * @dev `offset` - A cliff after claim before the escrow starts.
     * @dev See `MultiRewardsStaking` for more details.
     */
    function addStakingRewardsTokens(
        address[] memory vaults,
        bytes[] memory rewardTokenData
    ) public {
        _verifyEqualArrayLength(vaults.length, rewardTokenData.length);
        address staking;
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            (
                address rewardsToken,
                uint160 rewardsPerSecond,
                uint256 amount,
                bool useEscrow,
                uint224 escrowDuration,
                uint24 escrowPercentage,
                uint256 offset
            ) = abi.decode(
                    rewardTokenData[i],
                    (address, uint160, uint256, bool, uint224, uint24, uint256)
                );
            _verifyToken(rewardsToken);
            staking = _verifyCreatorOrOwner(vaults[i]).staking;

            adminProxy.execute(
                rewardsToken,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    staking,
                    type(uint256).max
                )
            );

            IERC20(rewardsToken).approve(staking, type(uint256).max);
            IERC20(rewardsToken).transferFrom(
                msg.sender,
                address(adminProxy),
                amount
            );

            adminProxy.execute(
                staking,
                abi.encodeWithSelector(
                    IMultiRewardStaking.addRewardToken.selector,
                    rewardsToken,
                    rewardsPerSecond,
                    amount,
                    useEscrow,
                    escrowDuration,
                    escrowPercentage,
                    offset
                )
            );
        }
    }

    /**
     * @notice Changes rewards speed for a rewardToken. This works only for rewards that accrue over time. Caller must be creator of the Vault.
     * @param vaults Vaults of which the staking contracts should be targeted
     * @param rewardTokens Token that can be earned by staking.
     * @param rewardsSpeeds The rate in which `rewardToken` will be accrued.
     * @dev See `MultiRewardsStaking` for more details.
     */
    function changeStakingRewardsSpeeds(
        address[] calldata vaults,
        IERC20[] calldata rewardTokens,
        uint160[] calldata rewardsSpeeds
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, rewardTokens.length);
        _verifyEqualArrayLength(len, rewardsSpeeds.length);

        address staking;
        for (uint256 i = 0; i < len; i++) {
            staking = _verifyCreator(vaults[i]).staking;

            adminProxy.execute(
                staking,
                abi.encodeWithSelector(
                    IMultiRewardStaking.changeRewardSpeed.selector,
                    rewardTokens[i],
                    rewardsSpeeds[i]
                )
            );
        }
    }

    /**
     * @notice Funds rewards for a rewardToken.
     * @param vaults Vaults of which the staking contracts should be targeted
     * @param rewardTokens Token that can be earned by staking.
     * @param amounts The amount of rewardToken that will fund this reward.
     * @dev See `MultiRewardStaking` for more details.
     */
    function fundStakingRewards(
        address[] calldata vaults,
        IERC20[] calldata rewardTokens,
        uint256[] calldata amounts
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, rewardTokens.length);
        _verifyEqualArrayLength(len, amounts.length);

        address staking;
        for (uint256 i = 0; i < len; i++) {
            staking = vaultRegistry.getVault(vaults[i]).staking;

            rewardTokens[i].transferFrom(msg.sender, address(this), amounts[i]);
            IMultiRewardStaking(staking).fundReward(
                rewardTokens[i],
                amounts[i]
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                      ESCROW MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    IMultiRewardEscrow public escrow;

    /**
     * @notice Set fees for multiple tokens. Caller must be the owner.
     * @param tokens Array of tokens.
     * @param fees Array of fees for `tokens` in 1e18. (1e18 = 100%, 1e14 = 1 BPS)
     * @dev See `MultiRewardEscrow` for more details.
     * @dev We dont need to verify array length here since its done already in `MultiRewardEscrow`
     */
    function setEscrowTokenFees(
        IERC20[] calldata tokens,
        uint256[] calldata fees
    ) external onlyOwner {
        adminProxy.execute(
            address(escrow),
            abi.encodeWithSelector(
                IMultiRewardEscrow.setFees.selector,
                tokens,
                fees
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                          TEMPLATE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new templateCategory to the registry. Caller must be owner.
     * @param templateCategories A new category of templates.
     * @dev See `TemplateRegistry` for more details.
     */
    function addTemplateCategories(
        bytes32[] calldata templateCategories
    ) external onlyOwner {
        address _deploymentController = address(deploymentController);
        uint8 len = uint8(templateCategories.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                _deploymentController,
                abi.encodeWithSelector(
                    IDeploymentController.addTemplateCategory.selector,
                    templateCategories[i]
                )
            );
        }
    }

    /**
     * @notice Toggles the endorsement of a templates. Caller must be owner.
     * @param templateCategories TemplateCategory of the template to endorse.
     * @param templateIds TemplateId of the template to endorse.
     * @dev See `TemplateRegistry` for more details.
     */
    function toggleTemplateEndorsements(
        bytes32[] calldata templateCategories,
        bytes32[] calldata templateIds
    ) external onlyOwner {
        uint8 len = uint8(templateCategories.length);
        _verifyEqualArrayLength(len, templateIds.length);

        address _deploymentController = address(deploymentController);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                address(_deploymentController),
                abi.encodeWithSelector(
                    ITemplateRegistry.toggleTemplateEndorsement.selector,
                    templateCategories[i],
                    templateIds[i]
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          PAUSING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Pause Deposits and withdraw all funds from the underlying protocol. Caller must be owner.
    function pauseAdapters(address[] calldata vaults) external onlyOwner {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                IVault(vaults[i]).adapter(),
                abi.encodeWithSelector(IPausable.pause.selector)
            );
        }
    }

    /// @notice Unpause Deposits and deposit all funds into the underlying protocol. Caller must be owner.
    function unpauseAdapters(address[] calldata vaults) external onlyOwner {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                IVault(vaults[i]).adapter(),
                abi.encodeWithSelector(IPausable.unpause.selector)
            );
        }
    }

    /// @notice Pause deposits. Caller must be owner or creator of the Vault.
    function pauseVaults(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IPausable.pause.selector)
            );
        }
    }

    /// @notice Unpause deposits. Caller must be owner or creator of the Vault.
    function unpauseVaults(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IPausable.unpause.selector)
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                       VERIFICATION LOGIC
    //////////////////////////////////////////////////////////////*/

    error NotSubmitterNorOwner(address caller);
    error NotSubmitter(address caller);
    error NotAllowed(address subject);
    error ArrayLengthMismatch();

    /// @notice Verify that the caller is the creator of the vault or owner of `VaultController` (admin rights).
    function _verifyCreatorOrOwner(
        address vault
    ) internal returns (VaultMetadata memory metadata) {
        metadata = vaultRegistry.getVault(vault);
        if (msg.sender != metadata.creator && msg.sender != owner)
            revert NotSubmitterNorOwner(msg.sender);
    }

    /// @notice Verify that the caller is the creator of the vault.
    function _verifyCreator(
        address vault
    ) internal view returns (VaultMetadata memory metadata) {
        metadata = vaultRegistry.getVault(vault);
        if (msg.sender != metadata.creator) revert NotSubmitter(msg.sender);
    }

    /// @notice Verify that the token is not rejected nor a clone.
    function _verifyToken(address token) internal view {
        if (
            (
                permissionRegistry.endorsed(address(0))
                    ? !permissionRegistry.endorsed(token)
                    : permissionRegistry.rejected(token)
            ) ||
            cloneRegistry.cloneExists(token) ||
            token == address(0)
        ) revert NotAllowed(token);
    }

    /// @notice Verify that the array lengths are equal.
    function _verifyEqualArrayLength(
        uint256 length1,
        uint256 length2
    ) internal pure {
        if (length1 != length2) revert ArrayLengthMismatch();
    }

    modifier canCreate() {
        if (
            permissionRegistry.endorsed(address(1))
                ? !permissionRegistry.endorsed(msg.sender)
                : permissionRegistry.rejected(msg.sender)
        ) revert NotAllowed(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    IAdminProxy public adminProxy;

    /**
     * @notice Nominates a new owner of `AdminProxy`. Caller must be owner.
     * @dev Must be called if the `VaultController` gets swapped out or upgraded
     */
    function nominateNewAdminProxyOwner(address newOwner) external onlyOwner {
        adminProxy.nominateNewOwner(newOwner);
    }

    /**
     * @notice Accepts ownership of `AdminProxy`. Caller must be nominated owner.
     * @dev Must be called after construction
     */
    function acceptAdminProxyOwnership() external {
        adminProxy.acceptOwnership();
    }

    /*//////////////////////////////////////////////////////////////
                          MANAGEMENT FEE LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 public performanceFee;

    event PerformanceFeeChanged(uint256 oldFee, uint256 newFee);

    error InvalidPerformanceFee(uint256 fee);

    /**
     * @notice Set a new performanceFee for all new adapters. Caller must be owner.
     * @param newFee performance fee in 1e18.
     * @dev Fees can be 0 but never more than 2e17 (1e18 = 100%, 1e14 = 1 BPS)
     * @dev Can be retroactively applied to existing adapters.
     */
    function setPerformanceFee(uint256 newFee) external onlyOwner {
        // Dont take more than 20% performanceFee
        if (newFee > 2e17) revert InvalidPerformanceFee(newFee);

        emit PerformanceFeeChanged(performanceFee, newFee);

        performanceFee = newFee;
    }

    /**
     * @notice Set a new performanceFee for existing adapters. Caller must be owner.
     * @param adapters array of adapters to set the management fee for.
     */
    function setAdapterPerformanceFees(
        address[] calldata adapters
    ) external onlyOwner {
        uint8 len = uint8(adapters.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                adapters[i],
                abi.encodeWithSelector(
                    IAdapter.setPerformanceFee.selector,
                    performanceFee
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          HARVEST COOLDOWN LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 public harvestCooldown;

    event HarvestCooldownChanged(uint256 oldCooldown, uint256 newCooldown);

    error InvalidHarvestCooldown(uint256 cooldown);

    /**
     * @notice Set a new harvestCooldown for all new adapters. Caller must be owner.
     * @param newCooldown Time in seconds that must pass before a harvest can be called again.
     * @dev Cant be longer than 1 day.
     * @dev Can be retroactively applied to existing adapters.
     */
    function setHarvestCooldown(uint256 newCooldown) external onlyOwner {
        // Dont wait more than X seconds
        if (newCooldown > 1 days) revert InvalidHarvestCooldown(newCooldown);

        emit HarvestCooldownChanged(harvestCooldown, newCooldown);

        harvestCooldown = newCooldown;
    }

    /**
     * @notice Set a new harvestCooldown for existing adapters. Caller must be owner.
     * @param adapters Array of adapters to set the cooldown for.
     */
    function setAdapterHarvestCooldowns(
        address[] calldata adapters
    ) external onlyOwner {
        uint8 len = uint8(adapters.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                adapters[i],
                abi.encodeWithSelector(
                    IAdapter.setHarvestCooldown.selector,
                    harvestCooldown
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                      DEPLYOMENT CONTROLLER LOGIC
    //////////////////////////////////////////////////////////////*/

    IDeploymentController public deploymentController;
    ICloneRegistry public cloneRegistry;
    ITemplateRegistry public templateRegistry;
    IPermissionRegistry public permissionRegistry;

    event DeploymentControllerChanged(
        address oldController,
        address newController
    );

    error InvalidDeploymentController(address deploymentController);

    /**
     * @notice Sets a new `DeploymentController` and saves its auxilary contracts. Caller must be owner.
     * @param _deploymentController New DeploymentController.
     */
    function setDeploymentController(
        IDeploymentController _deploymentController
    ) external onlyOwner {
        _setDeploymentController(_deploymentController);
    }

    function _setDeploymentController(
        IDeploymentController _deploymentController
    ) internal {
        if (
            address(_deploymentController) == address(0) ||
            address(deploymentController) == address(_deploymentController)
        ) revert InvalidDeploymentController(address(_deploymentController));

        emit DeploymentControllerChanged(
            address(deploymentController),
            address(_deploymentController)
        );

        // Dont try to change ownership on construction
        if (address(deploymentController) != address(0))
            _transferDependencyOwnership(address(_deploymentController));

        deploymentController = _deploymentController;
        cloneRegistry = _deploymentController.cloneRegistry();
        templateRegistry = _deploymentController.templateRegistry();
    }

    function _transferDependencyOwnership(
        address _deploymentController
    ) internal {
        adminProxy.execute(
            address(deploymentController),
            abi.encodeWithSelector(
                IDeploymentController.nominateNewDependencyOwner.selector,
                _deploymentController
            )
        );

        adminProxy.execute(
            _deploymentController,
            abi.encodeWithSelector(
                IDeploymentController.acceptDependencyOwnership.selector,
                ""
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                      TEMPLATE KEY LOGIC
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => bytes32) public activeTemplateId;

    event ActiveTemplateIdChanged(bytes32 oldKey, bytes32 newKey);

    error SameKey(bytes32 templateKey);

    /**
     * @notice Set a templateId which shall be used for deploying certain contracts. Caller must be owner.
     * @param templateCategory TemplateCategory to set an active key for.
     * @param templateId TemplateId that should be used when creating a new contract of `templateCategory`
     * @dev Currently `Vault` and `Staking` use a template set via `activeTemplateId`.
     * @dev If this contract should deploy Vaults of a second generation this can be set via the `activeTemplateId`.
     */
    function setActiveTemplateId(
        bytes32 templateCategory,
        bytes32 templateId
    ) external onlyOwner {
        bytes32 oldTemplateId = activeTemplateId[templateCategory];
        if (oldTemplateId == templateId) revert SameKey(templateId);

        emit ActiveTemplateIdChanged(oldTemplateId, templateId);

        activeTemplateId[templateCategory] = templateId;
    }
}