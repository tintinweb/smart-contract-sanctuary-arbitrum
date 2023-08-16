/**
 *Submitted for verification at Arbiscan on 2023-08-15
*/

// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File lib/openzeppelin-contracts/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT AND BUSL-1.1
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

// File lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
}

// File lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol

// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

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
    function convertToShares(
        uint256 assets
    ) external view returns (uint256 shares);

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
    function convertToAssets(
        uint256 shares
    ) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets);

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
    function previewDeposit(
        uint256 assets
    ) external view returns (uint256 shares);

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
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(
        address receiver
    ) external view returns (uint256 maxShares);

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
    function mint(
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(
        address owner
    ) external view returns (uint256 maxAssets);

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
    function previewWithdraw(
        uint256 assets
    ) external view returns (uint256 shares);

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
    function previewRedeem(
        uint256 shares
    ) external view returns (uint256 assets);

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

// File lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

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

// File lib/openzeppelin-contracts/contracts/utils/Address.sol

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

// File lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                oldAllowance + value
            )
        );
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    oldAllowance - value
                )
            );
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeWithSelector(
            token.approve.selector,
            spender,
            value
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, 0)
            );
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
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            Address.isContract(address(token));
    }
}

// File src/types/RiskParam.sol

pragma solidity ^0.8.17;

library RiskParam {
    /// -----------------------------------------------------------------------
    /// Storage Structure
    /// -----------------------------------------------------------------------

    struct CollateralParam {
        uint128 collateralWeightRatio; // express in WAD
    }

    struct PortfolioParam {
        uint128 minPortfolioCollateralRatio; // express in WAD. Ex 120%
        // warningPortfolioCollateralRatio > minPortfolioCollateralRatio
        uint128 warningPortfolioCollateralRatio; // express in WAD. Ex 150%
    }
}

// File src/configuration/SystemConfiguration.sol

pragma solidity ^0.8.17;

contract SystemConfiguration is Ownable {
    // TODO: Consider move all param into one Configuration
    RiskParam.CollateralParam private _collateralParam;
    RiskParam.PortfolioParam private _portfolioParam;

    constructor(
        RiskParam.CollateralParam memory collateralParam_,
        RiskParam.PortfolioParam memory portfolioParam_
    ) {
        _collateralParam = collateralParam_;
        _portfolioParam = portfolioParam_;
    }

    function updatePortfolioCollateral(
        RiskParam.PortfolioParam memory portfolioParam_
    ) external onlyOwner {
        _portfolioParam = portfolioParam_;
    }

    function updateCollateralParam(
        RiskParam.CollateralParam memory collateralParam_
    ) external onlyOwner {
        _collateralParam = collateralParam_;
    }

    function getWarningPortfolioCollateralRatio()
        external
        view
        returns (uint128)
    {
        return _portfolioParam.warningPortfolioCollateralRatio;
    }

    function getMinPortfolioCollateralRatio() external view returns (uint128) {
        return _portfolioParam.minPortfolioCollateralRatio;
    }

    function getCollateralWeightRatio() external view returns (uint128) {
        return _collateralParam.collateralWeightRatio;
    }
}

// File src/interface/IChainlinkAggregatorV3.sol

pragma solidity ^0.8.0;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
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

// File src/interface/IPool.sol

pragma solidity ^0.8.15;

interface IPool {
    event VaultCreated(
        address indexed asset,
        address indexed vault,
        address indexed creator,
        uint256 index
    );

    event PortfolioManagerCreated(address indexed seller);

    event AssetSupplied(
        address indexed asset,
        address indexed owner,
        address receiver,
        uint256 assetAmount
    );

    event AssetWithdrawed(
        address indexed asset,
        address indexed owner,
        address receiver,
        uint256 assetAmount
    );

    function isAssetAllowed(address asset) external view returns (bool);

    function getPriceFeed(
        address cToken
    ) external view returns (IChainlinkAggregatorV3);

    function getVaultDecimals() external pure returns (uint8);

    function verifyDecimals(
        address asset_,
        uint8 decimalOffset_
    ) external view returns (bool);

    function getCVaultList() external view returns (address[] memory);

    function supply(address asset, uint256 amount, address receiver) external;

    function supplyWithPermit(
        address asset,
        uint256 amount,
        address receiver,
        uint256 dealine,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(address asset, uint256 amount, address receiver) external;

    function withdrawWithPermit(
        address asset,
        uint256 amount,
        address receiver,
        uint256 dealine,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(
        address asset,
        address owner
    ) external view returns (uint256);
}

// File src/interface/IPortfolio.sol

pragma solidity ^0.8.15;

interface IPortfolio {
    event ExecutedBorrow(
        address indexed owner,
        address indexed portfolio,
        uint256 borrowAmount,
        uint256 newAmount
    );

    event ExecutedDeposit(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 addedAmount,
        uint256 newAmount
    );

    event ExecutedWithdraw(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 withdrawAmount,
        uint256 newAmount
    );

    event ExecutedRepay(
        address indexed owner,
        address indexed portfolio,
        uint256 repayAmount,
        uint256 newAmount
    );

    event ExecutedTransferCollateral(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        address receiver,
        uint256 amount
    );

    function getPortfolioId() external view returns (uint256);

    function getSeller() external view returns (address);

    function getPool() external view returns (address);

    function getTDSContractFactory() external view returns (address);

    function getRemainBorrowAmount() external view returns (uint128);

    function getBorrowAmount() external view returns (uint128);

    function getAllCollateralAmount()
        external
        view
        returns (uint256[] memory vaultAmountList);

    function getMaxBorrowAmount() external view returns (uint128);

    function validateExecuteBorrow(
        uint128 addBorrowAmount
    ) external returns (uint128);

    function portfolioLeverageRatio() external view returns (uint128);

    function executeBorrow(uint128 addBorrowAmount) external returns (bool);

    function executeDeposit(
        address from,
        address vault,
        uint256 amount
    ) external;

    function executeWithdraw(
        address vault,
        uint256 amount,
        address receiver
    ) external;

    function executeRepay(uint128 repayAmount) external returns (bool);

    function executeTransferCollateralAsset(
        address vault,
        address receiver,
        uint256 amount
    ) external returns (bool);
}

// File src/interface/IPortfolioFactory.sol

pragma solidity ^0.8.17;

interface IPortfolioFactory {
    event PortfolioCreated(
        address indexed seller,
        address indexed portfolio,
        uint256 indexed portfolioId,
        uint8 portfolioType
    );
    event PortfolioManagerCreated(address indexed seller);

    event ExecutedDeposit(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 depositAmount
    );

    event ExecutedWithdraw(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 withdrawAmount,
        address receiver
    );

    function getPortfolioListBySeller(
        address seller
    ) external view returns (address[] memory);

    function getPortfolioById(
        address seller,
        uint256 portfolioId
    ) external view returns (address);

    function createIsolatedProtfolio() external;

    function depositWithPermit(
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount
    ) external;

    function withdraw(
        uint256 portfolioId,
        address vault,
        uint256 amount,
        address receiver
    ) external;
}

// File lib/solady/utils/SafeCastLib.sol

pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8) {
        int8 y = int8(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt16(int256 x) internal pure returns (int16) {
        int16 y = int16(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt24(int256 x) internal pure returns (int24) {
        int24 y = int24(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt32(int256 x) internal pure returns (int32) {
        int32 y = int32(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt40(int256 x) internal pure returns (int40) {
        int40 y = int40(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt48(int256 x) internal pure returns (int48) {
        int48 y = int48(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt56(int256 x) internal pure returns (int56) {
        int56 y = int56(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt64(int256 x) internal pure returns (int64) {
        int64 y = int64(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt72(int256 x) internal pure returns (int72) {
        int72 y = int72(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt80(int256 x) internal pure returns (int80) {
        int80 y = int80(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt88(int256 x) internal pure returns (int88) {
        int88 y = int88(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt96(int256 x) internal pure returns (int96) {
        int96 y = int96(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt104(int256 x) internal pure returns (int104) {
        int104 y = int104(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt112(int256 x) internal pure returns (int112) {
        int112 y = int112(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt120(int256 x) internal pure returns (int120) {
        int120 y = int120(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt128(int256 x) internal pure returns (int128) {
        int128 y = int128(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt136(int256 x) internal pure returns (int136) {
        int136 y = int136(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt144(int256 x) internal pure returns (int144) {
        int144 y = int144(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt152(int256 x) internal pure returns (int152) {
        int152 y = int152(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt160(int256 x) internal pure returns (int160) {
        int160 y = int160(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt168(int256 x) internal pure returns (int168) {
        int168 y = int168(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt176(int256 x) internal pure returns (int176) {
        int176 y = int176(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt184(int256 x) internal pure returns (int184) {
        int184 y = int184(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt192(int256 x) internal pure returns (int192) {
        int192 y = int192(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt200(int256 x) internal pure returns (int200) {
        int200 y = int200(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt208(int256 x) internal pure returns (int208) {
        int208 y = int208(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt216(int256 x) internal pure returns (int216) {
        int216 y = int216(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt224(int256 x) internal pure returns (int224) {
        int224 y = int224(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt232(int256 x) internal pure returns (int232) {
        int232 y = int232(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt240(int256 x) internal pure returns (int240) {
        int240 y = int240(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt248(int256 x) internal pure returns (int248) {
        int248 y = int248(x);
        if (x != y) _revertOverflow();
        return y;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

// File src/error/sol

pragma solidity ^0.8.17;

/// -----------------------------------------------------------------------
/// Pool Custom Errors
/// -----------------------------------------------------------------------

error CVaultNotExist();
error GivenAssetNotMatchUnderlyingAsset();
error UnderlyingAssetExisted(address);
error InvalidVaultDeicmals(uint8);

/// -----------------------------------------------------------------------
/// Portfolio Custom Errors
/// -----------------------------------------------------------------------

error SellerExisted();
error SellerNotExisted();
error PortfolioNotExisted();
error IsolatedPortfolioAlreadyOpenTDSContract();
error TransferCollateralAssetError(string);
error PermissionDenied();
error AmountTooSmall();
error ExceedWarningRatio(uint256);
error VaultNotAllowed(address);
error InsufficientWithdrawAmount(uint256);
error InsufficientRepayAmount(uint256);

/// -----------------------------------------------------------------------
/// SignatureChecker Custom Errors
/// -----------------------------------------------------------------------

error InvalidSignatureLength(uint256);
error InvalidSignature();

/// -----------------------------------------------------------------------
/// TDSContract Custom Errors
/// -----------------------------------------------------------------------

error RequestExpire();
error InvalidPaymentInterval(uint256, uint256);
error BuyerInsufficientBalance(uint256);
error InvalidTDSContractCaller(address);
error ExecuteBorrowError(string);
error ExecuteRepayError(string);
error InvalidDecimal(uint8);
error TDSContractNotOpen(uint256);
error AlreadyPayAllPremium(uint256);
error NotReachPaymentDateYet(uint256);
error TDSContractNotDefault(uint256);
error EventDefaultValidatioError(string);
error ClaimPaymentWhenDefaultError(string);
error InvalidProof();
error InvalidPriceOracleRoundId(string);
error InvalidPriceOracleTime();

/// -----------------------------------------------------------------------
/// Nonce Custom Errors
/// -----------------------------------------------------------------------

error InvalidSellerNonce();
error InvalidBuyerNonce();
error InvalidReferenceEvent(uint256);
error InvalidDefaultTrigger();
error InvalidMinNonce();
error InvalidSender();

/// -----------------------------------------------------------------------
/// Oracle Custom Errors
/// -----------------------------------------------------------------------

error AssetNotSupported(address);
error ReportNotFound();
error TDSContractIsDefault();
error TDSContractUnderReporting();
error TDSContractReportTimeout();
error TDSContractAlreadyReported();

/// -----------------------------------------------------------------------
/// Reference Event Custom Errors
/// -----------------------------------------------------------------------

error InvalidEventType();

// File src/libraries/WadRayMath.sol

pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    // solhint-disable-next-line
    uint256 internal constant WAD = 1e18;
    // solhint-disable-next-line
    uint256 internal constant HALF_WAD = 0.5e18;
    // solhint-disable-next-line
    uint256 internal constant RAY = 1e27;
    // solhint-disable-next-line
    uint256 internal constant HALF_RAY = 0.5e27;
    // solhint-disable-next-line
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return c = a * b, in wad
     */
    function wadMul128(uint128 a, uint128 b) internal pure returns (uint128 c) {
        // solhint-disable-next-line
        uint128 MAX_UINT128 = type(uint128).max;
        assembly {
            let result := div(add(mul(a, b), HALF_WAD), WAD)
            if gt(result, MAX_UINT128) {
                revert(0, 0)
            } // Check for overflow
            c := result
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv128(uint128 a, uint128 b) internal pure returns (uint128 c) {
        // solhint-disable-next-line
        uint128 MAX_UINT128 = type(uint128).max;
        assembly {
            if iszero(b) {
                revert(0, 0)
            }

            let result := div(add(mul(a, WAD), div(b, 2)), b)
            if gt(result, MAX_UINT128) {
                revert(0, 0)
            } // Check for overflow
            c := result
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Return result is express in ray
    /// @notice round down is not a problem
    function calculateTotal(
        uint256 collateralRayAmount,
        uint256 price,
        uint8 decimal
    ) external pure returns (uint256 total) {
        if (decimal > 27) {
            assembly {
                price := div(price, exp(10, sub(decimal, 27)))
            }
        } else {
            assembly {
                price := mul(price, exp(10, sub(27, decimal)))
            }
        }
        total = rayMul(collateralRayAmount, price);
    }
}

// File src/types/PortfolioTypes.sol

pragma solidity ^0.8.17;

library PortfolioTypes {
    // solhint-disable-next-line
    uint8 constant PORTFOLIO_TYPE_CROSS_MARGIN = 1;
    // solhint-disable-next-line
    uint8 constant PORTFOLIO_TYPE_ISOLATED = 2;
}

// File src/portfolio/Portfolio.sol

pragma solidity ^0.8.17;

/// @title  Portfolio
/// @notice Contract holding collateral asset, provide leverage for seller
contract Portfolio is IPortfolio {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;

    using WadRayMath for uint256;

    using WadRayMath for uint128;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    uint128 internal immutable MAX_RATIO = 999 * 1e18;

    uint8 internal immutable _marginType;

    uint256 internal immutable _portfolioId;

    address internal immutable _owner;

    IPool internal immutable _pool;

    address internal immutable _tdsContractFactory;

    address internal immutable _portfolioFactory;

    SystemConfiguration internal immutable _configuration;

    /// -----------------------------------------------------------------------
    /// Muttable Storage
    /// -----------------------------------------------------------------------

    address[] internal _vaultList; // cUSDC, cWETH, cWBTC,...
    uint128 internal _borrowedAmount; // ConcordUSD, type of USD-Denomination, Express in Wad

    constructor(
        uint256 portfolioId_,
        uint8 marginType_,
        address owner_,
        address pool_,
        address tdsContractFactory_,
        address configuration_,
        address portfolioFactory_
    ) {
        _portfolioId = portfolioId_;
        _marginType = marginType_;
        _owner = owner_;
        _pool = IPool(pool_);
        _tdsContractFactory = tdsContractFactory_;
        _borrowedAmount = 0;
        _configuration = SystemConfiguration(configuration_);
        _portfolioFactory = portfolioFactory_;
    }

    /// -----------------------------------------------------------------------
    /// Modifier
    /// -----------------------------------------------------------------------

    modifier onlyPool() {
        if (msg.sender != address(_pool)) revert PermissionDenied();
        _;
    }

    modifier onlyPortfolioFactory() {
        if (msg.sender != address(_portfolioFactory)) revert PermissionDenied();
        _;
    }

    modifier onlyTDSContractFactory() {
        if (msg.sender != _tdsContractFactory) revert PermissionDenied();
        _;
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function getPortfolioId() external view override returns (uint256) {
        return _portfolioId;
    }

    function getSeller() external view override returns (address) {
        return _owner;
    }

    function getPool() external view override returns (address) {
        return address(_pool);
    }

    function getTDSContractFactory() external view override returns (address) {
        return _tdsContractFactory;
    }

    function getAllCollateralAmount()
        public
        view
        override
        returns (uint256[] memory vaultAmountList)
    {
        vaultAmountList = new uint256[](_vaultList.length);
        for (uint256 i = 0; i < _vaultList.length; i++) {
            vaultAmountList[i] = IERC20(_vaultList[i]).balanceOf(address(this));
        }
    }

    /// @dev calculate the remain borrow amount
    /// @notice if maxBorrowAmount() call external data there will be a chance
    ///         maxBorrowAmount can be change in one transaction without add/remove any collateral asset
    ///         this could happened due to external data change
    function getRemainBorrowAmount() public view override returns (uint128) {
        return getMaxBorrowAmount() - _borrowedAmount;
    }

    function getBorrowAmount() public view override returns (uint128) {
        return _borrowedAmount;
    }

    /// @dev calculate max borrow concordUSD value
    /// @notice the total borrow amount of each collateral will have different decimal
    function getMaxBorrowAmount()
        public
        view
        override
        returns (uint128 maxBorrow)
    {
        //TODO: optimize for one loop
        uint256[] memory vaultAmountList = getAllCollateralAmount();
        maxBorrow = _maxBorrowAmount(vaultAmountList);
    }

    function portfolioLeverageRatio() public view override returns (uint128) {
        return
            _calculatePortfolioLeverageRatio(
                _borrowedAmount,
                getMaxBorrowAmount()
            );
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function _calculatePortfolioLeverageRatio(
        uint128 borrowAmount,
        uint128 maxBorrowAmount_
    ) internal pure returns (uint128) {
        // Return max ratio in case of no borrow
        if (borrowAmount == 0) {
            return uint128(MAX_RATIO);
        }
        return maxBorrowAmount_.wadDiv128(borrowAmount);
    }

    /// @notice max borrow amount can't preceed warning ratio
    function _maxBorrowAmount(
        uint256[] memory vaultAmountList
    ) internal view returns (uint128 maxBorrow) {
        for (uint256 i = 0; i < _vaultList.length; i++) {
            address collateralAsset = _vaultList[i];
            uint256 collateralAmount = vaultAmountList[i];
            if (collateralAmount > 0) {
                (, int256 answer, , , ) = _pool
                    .getPriceFeed(collateralAsset)
                    .latestRoundData();
                uint256 price = answer > 0 ? uint256(answer) : 0;
                uint8 priceDecimal = _pool
                    .getPriceFeed(collateralAsset)
                    .decimals();

                // calculate total value, express in wad
                uint256 total = collateralAmount
                    .calculateTotal(price, priceDecimal)
                    .rayToWad();

                // adjust total value with collateral weight ratio
                uint128 totalAdjustedValue = total
                    .wadMul(_configuration.getCollateralWeightRatio())
                    .toUint128();

                // add to sum
                maxBorrow += totalAdjustedValue;
            }
        }

        // max borrow must maintain in warning ratio
        maxBorrow = maxBorrow.wadDiv128(
            _configuration.getWarningPortfolioCollateralRatio()
        );
    }

    /// @notice only tdsContractFactory can call to borrow concordUSD
    function executeBorrow(
        uint128 addBorrowAmount
    ) external onlyTDSContractFactory returns (bool) {
        _executeBorrow(addBorrowAmount);
        return true;
    }

    function _executeBorrow(uint128 addBorrowAmount) internal {
        validateExecuteBorrow(addBorrowAmount);
        _borrowedAmount += addBorrowAmount;

        emit ExecutedBorrow(
            _owner,
            address(this),
            addBorrowAmount,
            _borrowedAmount
        );
    }

    function validateExecuteBorrow(
        uint128 addBorrowAmount
    ) public view override returns (uint128) {
        // TODO: verify with zuff
        // Verify isolated portfolio can't provide leverage for two contract at the same time
        if (
            _marginType == PortfolioTypes.PORTFOLIO_TYPE_ISOLATED &&
            _borrowedAmount > 0
        ) revert IsolatedPortfolioAlreadyOpenTDSContract();
        uint128 newBorrowAmount = _borrowedAmount + addBorrowAmount;
        uint128 newRatioWad = _calculatePortfolioLeverageRatio(
            newBorrowAmount,
            getMaxBorrowAmount()
        );

        // Verify new leverage against warning ratio
        if (newRatioWad < _configuration.getWarningPortfolioCollateralRatio())
            revert ExceedWarningRatio(newRatioWad);

        return newRatioWad;
    }

    function executeDeposit(
        address from,
        address vault,
        uint256 amount
    ) external override onlyPortfolioFactory {
        // add new vault if it do not exist
        _tryAddNewVault(vault);

        SafeERC20.safeTransferFrom(IERC20(vault), from, address(this), amount);

        emit ExecutedDeposit(
            _owner,
            address(this),
            vault,
            amount,
            IERC20(vault).balanceOf(address(this))
        );
    }

    function _tryAddNewVault(address vault) internal {
        for (uint256 i = 0; i < _vaultList.length; i++) {
            if (_vaultList[i] == vault) {
                return;
            }
        }
        _vaultList.push(vault);
    }

    /// @notice only withdraw by calling from PortfolioFactory
    function executeWithdraw(
        address vault,
        uint256 amount,
        address receiver
    ) external override onlyPortfolioFactory {
        uint256 previousAmount = IERC20(vault).balanceOf(address(this));
        validateExecuteWithdraw(vault, amount);

        SafeERC20.safeTransfer(IERC20(vault), receiver, amount);

        emit ExecutedWithdraw(
            _owner,
            address(this),
            vault,
            amount,
            previousAmount - amount
        );
    }

    function validateExecuteWithdraw(
        address asset,
        uint256 amount
    ) public view returns (uint128) {
        uint256[] memory vaultAmountList = new uint256[](_vaultList.length);
        for (uint256 i = 0; i < _vaultList.length; i++) {
            vaultAmountList[i] = IERC20(_vaultList[i]).balanceOf(address(this));
            if (_vaultList[i] == asset) {
                if (vaultAmountList[i] < amount)
                    revert InsufficientWithdrawAmount(amount);
                vaultAmountList[i] -= amount;
            }
        }
        uint128 newMaxBorrowAmount = _maxBorrowAmount(vaultAmountList);
        uint128 newRatioWad = _calculatePortfolioLeverageRatio(
            _borrowedAmount,
            newMaxBorrowAmount
        );
        if (newRatioWad < _configuration.getWarningPortfolioCollateralRatio())
            revert ExceedWarningRatio(newRatioWad);
        return newRatioWad;
    }

    /// @notice only repay by calling from TDSContractFactory
    function executeRepay(
        uint128 repayAmount
    ) external onlyTDSContractFactory returns (bool) {
        _executeRepay(repayAmount);
        return true;
    }

    function _executeRepay(uint128 repayAmount) internal {
        validateExecuteRepay(repayAmount);
        _borrowedAmount -= repayAmount;

        emit ExecutedRepay(_owner, address(this), repayAmount, _borrowedAmount);
    }

    function validateExecuteRepay(uint128 repayAmount) public view {
        // Verify if repay more than current borrow
        if (_borrowedAmount < repayAmount)
            revert InsufficientRepayAmount(repayAmount);
    }

    /// @notice only transfer by calling from TDSContractFactory
    /// @notice collateral asset will be transfer to buyer in case of contract default
    function executeTransferCollateralAsset(
        address vault,
        address receiver,
        uint256 amount
    ) external override onlyTDSContractFactory returns (bool) {
        SafeERC20.safeTransfer(IERC20(vault), receiver, amount);

        emit ExecutedTransferCollateral(
            _owner,
            address(this),
            vault,
            receiver,
            amount
        );
        return true;
    }
}

// File src/portfolio/PortfolioFactory.sol

pragma solidity ^0.8.17;

/// @title  PortfolioFactory
/// @notice Contract create, manage, interact with portfolio
contract PortfolioFactory is IPortfolioFactory, Ownable {
    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    IPool private immutable _pool;

    address private immutable _tdsContractFactory;

    address private _configuration;

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice last portfolio id will always be 0, isolatedPortfolio start from 1
    mapping(address => address[]) private _portfolioManager;

    constructor(
        address pool_,
        address tdsContractFactory_,
        address configuration_
    ) {
        _pool = IPool(pool_);
        _tdsContractFactory = tdsContractFactory_;
        _configuration = configuration_;
    }

    /// -----------------------------------------------------------------------
    /// Modifier
    /// -----------------------------------------------------------------------
    modifier sellerExisted() {
        if (_portfolioManager[msg.sender].length == 0)
            revert SellerNotExisted();
        _;
    }

    modifier sellerNotExisted() {
        if (_portfolioManager[msg.sender].length != 0) revert SellerExisted();
        _;
    }

    modifier portfolioExisted(address seller, uint256 portfolioId) {
        if (_portfolioManager[seller].length <= portfolioId)
            revert PortfolioNotExisted();
        _;
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function getPortfolioListBySeller(
        address seller
    ) external view override returns (address[] memory) {
        return _portfolioManager[seller];
    }

    function getPortfolioById(
        address seller,
        uint256 portfolioId
    ) external view override returns (address) {
        address[] memory portfolios = _portfolioManager[seller];
        if (portfolios.length < portfolioId) {
            return address(0);
        }

        return portfolios[portfolioId];
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    /// @dev create new portfolio manager (PM) if not exist
    ///      new PM will have an empty CrossMargin portfolio by default
    function createPortfolioManager() external sellerNotExisted {
        address[] storage portfolios = _portfolioManager[msg.sender];

        Portfolio cmPortfolio = new Portfolio(
            0,
            PortfolioTypes.PORTFOLIO_TYPE_CROSS_MARGIN,
            msg.sender,
            address(_pool),
            _tdsContractFactory,
            _configuration,
            address(this)
        );
        portfolios.push(address(cmPortfolio));

        emit PortfolioCreated(
            msg.sender,
            address(cmPortfolio),
            0,
            PortfolioTypes.PORTFOLIO_TYPE_CROSS_MARGIN
        );

        _portfolioManager[msg.sender] = portfolios;

        emit PortfolioManagerCreated(msg.sender);
    }

    function createIsolatedProtfolio() external override sellerExisted {
        address[] storage portfolios = _portfolioManager[msg.sender];
        Portfolio isolatedPortfolio = new Portfolio(
            portfolios.length,
            PortfolioTypes.PORTFOLIO_TYPE_ISOLATED,
            msg.sender,
            address(_pool),
            _tdsContractFactory,
            _configuration,
            address(this)
        );
        portfolios.push(address(isolatedPortfolio));

        emit PortfolioCreated(
            msg.sender,
            address(isolatedPortfolio),
            portfolios.length - 1,
            PortfolioTypes.PORTFOLIO_TYPE_ISOLATED
        );
    }

    function deposit(
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount
    ) external override portfolioExisted(msg.sender, portfolioId) {
        _deposit(msg.sender, portfolioId, supplier, vault, amount);
    }

    function depositWithPermit(
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override portfolioExisted(msg.sender, portfolioId) {
        IERC20Permit(vault).permit(
            supplier,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        _deposit(msg.sender, portfolioId, supplier, vault, amount);
    }

    function _deposit(
        address seller,
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount
    ) internal {
        // Verify asset permission
        if (!_pool.isAssetAllowed(vault)) revert VaultNotAllowed(vault);

        IPortfolio portfolio = IPortfolio(
            _portfolioManager[seller][portfolioId]
        );
        portfolio.executeDeposit(supplier, vault, amount);

        emit ExecutedDeposit(msg.sender, address(portfolio), vault, amount);
    }

    function withdraw(
        uint256 portfolioId,
        address vault,
        uint256 amount,
        address receiver
    ) external override portfolioExisted(msg.sender, portfolioId) {
        // Verify asset permission
        if (!_pool.isAssetAllowed(vault)) revert VaultNotAllowed(vault);

        IPortfolio portfolio = IPortfolio(
            _portfolioManager[msg.sender][portfolioId]
        );
        portfolio.executeWithdraw(vault, amount, receiver);

        emit ExecutedWithdraw(
            msg.sender,
            address(portfolio),
            vault,
            amount,
            receiver
        );
    }
}