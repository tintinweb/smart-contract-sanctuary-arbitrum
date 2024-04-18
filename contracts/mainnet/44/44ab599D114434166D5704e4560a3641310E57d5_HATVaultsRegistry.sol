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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./tokenlock/TokenLockFactory.sol";
import "./interfaces/IHATVaultsRegistry.sol";
import "./interfaces/IHATVault.sol";

/** @title Registry to deploy Hats.finance vaults and manage shared parameters
 * @author Hats.finance
 * @notice Hats.finance is a proactive bounty protocol for white hat hackers and
 * security experts, where projects, community members, and stakeholders
 * incentivize protocol security and responsible disclosure.
 * Hats create scalable vaults using the project’s own token. The value of the
 * bounty increases with the success of the token and project.
 *
 * The owner of the registry has the permission to set time limits and bounty
 * parameters and change vaults' info, and to set the other registry roles -
 * fee setter and arbitrator.
 * The arbitrator can challenge submitted claims for bounty payouts made by
 * vaults' committees, approve them with a different bounty percentage or
 * dismiss them.
 * The fee setter can set the fee on withdrawals on all vaults.
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 *
 * @dev New hats.finance vaults should be created through a call to {createVault}
 * so that they are linked to the registry
 */
contract HATVaultsRegistry is IHATVaultsRegistry, Ownable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Used in {swapAndSend} to avoid a "stack too deep" error
    struct SwapData {
        uint256 amount;
        uint256 amountUnused;
        uint256 hatsReceived;
        uint256 totalHackerReward;
        uint256 governanceAmountSwapped;
        uint256[] hackerRewards;
        uint256 governanceHatReward;
        uint256 usedPart;
    }

    uint16 public constant HUNDRED_PERCENT = 10000;
    // the maximum percentage of the bounty that will be converted in HATs
    uint16 public constant MAX_HAT_SPLIT = 3500;

    address public hatVaultImplementation;
    address public hatClaimsManagerImplementation;
    address[] public hatVaults;
    
    // vault address => is visible
    mapping(address => bool) public isVaultVisible;
    // asset => hacker address => amount
    mapping(address => mapping(address => uint256)) public hackersHatReward;
    // asset => amount
    mapping(address => uint256) public governanceHatReward;

    // PARAMETERS FOR ALL VAULTS
    IHATVaultsRegistry.GeneralParameters public generalParameters;
    ITokenLockFactory public immutable tokenLockFactory;

    // the token into which a part of the the bounty will be swapped into
    IERC20 public HAT;
    
    // feeSetter sets the withdrawal fee
    address public feeSetter;

    // How the bountyGovernanceHAT and bountyHackerHATVested set how to divide the hats 
    // bounties of the vault, in percentages (out of `HUNDRED_PERCENT`)
    // The precentages are taken from the total bounty
 
    // the default percentage of the total bounty to be swapped to HATs and sent to governance
    uint16 public defaultBountyGovernanceHAT;
    // the default percentage of the total bounty to be swapped to HATs and sent to the hacker via vesting contract
    uint16 public defaultBountyHackerHATVested;

    address public defaultArbitrator;

    bool public isEmergencyPaused;
    uint32 public defaultChallengePeriod;
    uint32 public defaultChallengeTimeOutPeriod;

    /**
    * @notice initialize -
    * @param _hatVaultImplementation The hat vault implementation address.
    * @param _hatClaimsManagerImplementation The hat claims manager implementation address.
    * @param _hatGovernance The governance address.
    * @param _HAT the HAT token address
    * @param _bountyGovernanceHAT The default percentage of a claim's total
    * bounty to be swapped for HAT and sent to the governance
    * @param _bountyHackerHATVested The default percentage of a claim's total
    * bounty to be swapped for HAT and sent to a vesting contract for the hacker
    *   _bountyGovernanceHAT + _bountyHackerHATVested must be less
    *    than `HUNDRED_PERCENT`.
    * @param _tokenLockFactory Address of the token lock factory to be used
    * to create a vesting contract for the approved claim reporter.
    */
    constructor(
        address _hatVaultImplementation,
        address _hatClaimsManagerImplementation,
        address _hatGovernance,
        address _defaultArbitrator,
        address _HAT,
        uint16 _bountyGovernanceHAT,
        uint16 _bountyHackerHATVested,
        ITokenLockFactory _tokenLockFactory
    ) {
        _transferOwnership(_hatGovernance);
        hatVaultImplementation = _hatVaultImplementation;
        hatClaimsManagerImplementation = _hatClaimsManagerImplementation;
        HAT = IERC20(_HAT);

        validateHATSplit(_bountyGovernanceHAT, _bountyHackerHATVested);
        tokenLockFactory = _tokenLockFactory;
        generalParameters = IHATVaultsRegistry.GeneralParameters({
            hatVestingDuration: 90 days,
            hatVestingPeriods: 90,
            withdrawPeriod: 11 hours,
            safetyPeriod: 1 hours,
            setMaxBountyDelay: 2 days,
            withdrawRequestEnablePeriod: 7 days,
            withdrawRequestPendingPeriod: 7 days,
            claimFee: 0
        });

        defaultBountyGovernanceHAT = _bountyGovernanceHAT;
        defaultBountyHackerHATVested = _bountyHackerHATVested;
        defaultArbitrator = _defaultArbitrator;
        defaultChallengePeriod = 3 days;
        defaultChallengeTimeOutPeriod = 125 days;
        emit RegistryCreated(
            _hatVaultImplementation,
            _hatClaimsManagerImplementation,
            _HAT,
            address(_tokenLockFactory),
            generalParameters,
            _bountyGovernanceHAT,
            _bountyHackerHATVested,
            _hatGovernance,
            _defaultArbitrator,
            defaultChallengePeriod,
            defaultChallengeTimeOutPeriod
        );
    }

    /** @notice See {IHATVaultsRegistry-setVaultImplementations}. */
    function setVaultImplementations(
        address _hatVaultImplementation,
        address _hatClaimsManagerImplementation
    ) external onlyOwner {
        hatVaultImplementation = _hatVaultImplementation;
        hatClaimsManagerImplementation = _hatClaimsManagerImplementation;

        emit SetHATVaultImplementation(_hatVaultImplementation);
        emit SetHATClaimsManagerImplementation(_hatClaimsManagerImplementation);
    }

    /** @notice See {IHATVaultsRegistry-setSwapToken}. */
    function setSwapToken(address _swapToken) external onlyOwner {
        HAT = IERC20(_swapToken);
        emit SetSwapToken(_swapToken);
    }

    /** @notice See {IHATVaultsRegistry-setEmergencyPaused}. */
    function setEmergencyPaused(bool _isEmergencyPaused) external onlyOwner {
        isEmergencyPaused = _isEmergencyPaused;
        emit SetEmergencyPaused(_isEmergencyPaused);
    }

    /** @notice See {IHATVaultsRegistry-logClaim}. */
    function logClaim(string calldata _descriptionHash) external payable {
        uint256 _claimFee = generalParameters.claimFee;
        if (_claimFee > 0) {
            if (msg.value < _claimFee)
                revert NotEnoughFeePaid();
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = payable(owner()).call{value: msg.value}("");
            if (!success) revert ClaimFeeTransferFailed();
        }
        emit LogClaim(msg.sender, _descriptionHash);
    }

    /** @notice See {IHATVaultsRegistry-setDefaultHATBountySplit}. */
    function setDefaultHATBountySplit(
        uint16 _defaultBountyGovernanceHAT,
        uint16 _defaultBountyHackerHATVested
    ) external onlyOwner {
        validateHATSplit(_defaultBountyGovernanceHAT, _defaultBountyHackerHATVested);
        defaultBountyGovernanceHAT = _defaultBountyGovernanceHAT;
        defaultBountyHackerHATVested = _defaultBountyHackerHATVested;
        emit SetDefaultHATBountySplit(_defaultBountyGovernanceHAT, _defaultBountyHackerHATVested);

    }
   
    /** @notice See {IHATVaultsRegistry-setDefaultArbitrator}. */
    function setDefaultArbitrator(address _defaultArbitrator) external onlyOwner {
        defaultArbitrator = _defaultArbitrator;
        emit SetDefaultArbitrator(_defaultArbitrator);
    }

    /** @notice See {IHATVaultsRegistry-setDefaultChallengePeriod}. */
    function setDefaultChallengePeriod(uint32 _defaultChallengePeriod) external onlyOwner {
        validateChallengePeriod(_defaultChallengePeriod);
        defaultChallengePeriod = _defaultChallengePeriod;
        emit SetDefaultChallengePeriod(_defaultChallengePeriod);
    }

    /** @notice See {IHATVaultsRegistry-setDefaultChallengeTimeOutPeriod}. */
    function setDefaultChallengeTimeOutPeriod(uint32 _defaultChallengeTimeOutPeriod) external onlyOwner {
        validateChallengeTimeOutPeriod(_defaultChallengeTimeOutPeriod);
        defaultChallengeTimeOutPeriod = _defaultChallengeTimeOutPeriod;
        emit SetDefaultChallengeTimeOutPeriod(_defaultChallengeTimeOutPeriod);
    }

    /** @notice See {IHATVaultsRegistry-setFeeSetter}. */
    function setFeeSetter(address _feeSetter) external onlyOwner {
        feeSetter = _feeSetter;
        emit SetFeeSetter(_feeSetter);
    }

    /** @notice See {IHATVaultsRegistry-setWithdrawRequestParams}. */
    function setWithdrawRequestParams(uint32 _withdrawRequestPendingPeriod, uint32  _withdrawRequestEnablePeriod)
        external 
        onlyOwner
    {
        if (_withdrawRequestPendingPeriod > 90 days)
            revert WithdrawRequestPendingPeriodTooLong();
        if (_withdrawRequestEnablePeriod < 6 hours)
            revert WithdrawRequestEnabledPeriodTooShort();
        if (_withdrawRequestEnablePeriod > 100 days)
            revert WithdrawRequestEnabledPeriodTooLong();
        generalParameters.withdrawRequestPendingPeriod = _withdrawRequestPendingPeriod;
        generalParameters.withdrawRequestEnablePeriod = _withdrawRequestEnablePeriod;
        emit SetWithdrawRequestParams(_withdrawRequestPendingPeriod, _withdrawRequestEnablePeriod);
    }

    /** @notice See {IHATVaultsRegistry-setClaimFee}. */
    function setClaimFee(uint256 _fee) external onlyOwner {
        generalParameters.claimFee = _fee;
        emit SetClaimFee(_fee);
    }

    /** @notice See {IHATVaultsRegistry-setWithdrawSafetyPeriod}. */
    function setWithdrawSafetyPeriod(uint32 _withdrawPeriod, uint32 _safetyPeriod) external onlyOwner { 
        if (_withdrawPeriod < 1 hours) revert WithdrawPeriodTooShort();
        if (_safetyPeriod > 6 hours) revert SafetyPeriodTooLong();
        generalParameters.withdrawPeriod = _withdrawPeriod;
        generalParameters.safetyPeriod = _safetyPeriod;
        emit SetWithdrawSafetyPeriod(_withdrawPeriod, _safetyPeriod);
    }

    /** @notice See {IHATVaultsRegistry-setHatVestingParams}. */
    function setHatVestingParams(uint32 _duration, uint32 _periods) external onlyOwner {
        if (_duration >= 180 days) revert HatVestingDurationTooLong();
        if (_periods == 0) revert HatVestingPeriodsCannotBeZero();
        if (_duration < _periods) revert HatVestingDurationSmallerThanPeriods();
        generalParameters.hatVestingDuration = _duration;
        generalParameters.hatVestingPeriods = _periods;
        emit SetHatVestingParams(_duration, _periods);
    }

    /** @notice See {IHATVaultsRegistry-setMaxBountyDelay}. */
    function setMaxBountyDelay(uint32 _delay) external onlyOwner {
        if (_delay < 2 days) revert DelayTooShort();
        generalParameters.setMaxBountyDelay = _delay;
        emit SetMaxBountyDelay(_delay);
    }

    /** @notice See {IHATVaultsRegistry-createVault}. */
    function createVault(
        IHATVault.VaultInitParams calldata _vaultParams,
        IHATClaimsManager.ClaimsManagerInitParams calldata _claimsManagerParams
    ) external returns(address vault, address vaultClaimsManager) {
        vault = Clones.clone(hatVaultImplementation);
        vaultClaimsManager = Clones.clone(hatClaimsManagerImplementation);

        IHATVault(vault).initialize(vaultClaimsManager, _vaultParams);
        IHATClaimsManager(vaultClaimsManager).initialize(IHATVault(vault), _claimsManagerParams);

        hatVaults.push(vault);

        emit VaultCreated(vault, vaultClaimsManager, _vaultParams, _claimsManagerParams);
    }

    /** @notice See {IHATVaultsRegistry-setVaultVisibility}. */
    function setVaultVisibility(address _vault, bool _visible) external onlyOwner {
        isVaultVisible[_vault] = _visible;
        emit SetVaultVisibility(_vault, _visible);
    }

    /** @notice See {IHATVaultsRegistry-addTokensToSwap}. */
    function addTokensToSwap(
        IERC20 _asset,
        address _hacker,
        uint256 _hackersHatReward,
        uint256 _governanceHatReward
    ) external {
        hackersHatReward[address(_asset)][_hacker] += _hackersHatReward;
        governanceHatReward[address(_asset)] += _governanceHatReward;
        _asset.safeTransferFrom(msg.sender, address(this), _hackersHatReward + _governanceHatReward);
    }

    /** @notice See {IHATVaultsRegistry-swapAndSend}. */
    function swapAndSend(
        address _asset,
        address[] calldata _beneficiaries,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload
    ) external onlyOwner {
        // Needed to avoid a "stack too deep" error
        SwapData memory _swapData;
        _swapData.hackerRewards = new uint256[](_beneficiaries.length);
        _swapData.governanceHatReward = governanceHatReward[_asset];
        _swapData.amount = _swapData.governanceHatReward;
        for (uint256 i = 0; i < _beneficiaries.length;) { 
            _swapData.hackerRewards[i] = hackersHatReward[_asset][_beneficiaries[i]];
            hackersHatReward[_asset][_beneficiaries[i]] = 0;
            _swapData.amount += _swapData.hackerRewards[i]; 
            unchecked { ++i; }
        }
        if (_swapData.amount == 0) revert AmountToSwapIsZero();
        IERC20 _HAT = HAT;
        (_swapData.hatsReceived, _swapData.amountUnused) = _swapTokenForHAT(IERC20(_asset), _swapData.amount, _amountOutMinimum, _routingContract, _routingPayload);
        
        _swapData.usedPart = (_swapData.amount - _swapData.amountUnused);
        _swapData.governanceAmountSwapped = _swapData.usedPart.mulDiv(_swapData.governanceHatReward, _swapData.amount);
        governanceHatReward[_asset]  = _swapData.amountUnused.mulDiv(_swapData.governanceHatReward, _swapData.amount);

        for (uint256 i = 0; i < _beneficiaries.length;) {
            uint256 _hackerReward = _swapData.hatsReceived.mulDiv(_swapData.hackerRewards[i], _swapData.amount);
            uint256 _hackerAmountSwapped = _swapData.usedPart.mulDiv(_swapData.hackerRewards[i], _swapData.amount);
            _swapData.totalHackerReward += _hackerReward;
            hackersHatReward[_asset][_beneficiaries[i]] = _swapData.amountUnused.mulDiv(_swapData.hackerRewards[i], _swapData.amount);
            address _tokenLock;
            if (_hackerReward > 0) {
                // hacker gets her reward via vesting contract
                _tokenLock = tokenLockFactory.createTokenLock(
                    address(_HAT),
                    0x0000000000000000000000000000000000000000, //this address as owner, so it can do nothing.
                    _beneficiaries[i],
                    _hackerReward,
                    // solhint-disable-next-line not-rely-on-time
                    block.timestamp, //start
                    // solhint-disable-next-line not-rely-on-time
                    block.timestamp + generalParameters.hatVestingDuration, //end
                    generalParameters.hatVestingPeriods,
                    0, // no release start
                    0, // no cliff
                    false, // not revocable
                    true
                );
                _HAT.safeTransfer(_tokenLock, _hackerReward);
            }
            emit SwapAndSend(_beneficiaries[i], _hackerAmountSwapped, _hackerReward, _tokenLock);
            unchecked { ++i; }
        }
        address _owner = owner(); 
        uint256 _amountToOwner = _swapData.hatsReceived - _swapData.totalHackerReward;
        _HAT.safeTransfer(_owner, _amountToOwner);
        emit SwapAndSend(_owner, _swapData.governanceAmountSwapped, _amountToOwner, address(0));
    }

    /** @notice See {IHATVaultsRegistry-getWithdrawPeriod}. */   
      function getWithdrawPeriod() external view returns (uint256) {
        return generalParameters.withdrawPeriod;
    }

    /** @notice See {IHATVaultsRegistry-getSafetyPeriod}. */   
    function getSafetyPeriod() external view returns (uint256) {
        return generalParameters.safetyPeriod;
    }

    /** @notice See {IHATVaultsRegistry-getWithdrawRequestEnablePeriod}. */   
    function getWithdrawRequestEnablePeriod() external view returns (uint256) {
        return generalParameters.withdrawRequestEnablePeriod;
    }

    /** @notice See {IHATVaultsRegistry-getWithdrawRequestPendingPeriod}. */   
    function getWithdrawRequestPendingPeriod() external view returns (uint256) {
        return generalParameters.withdrawRequestPendingPeriod;
    }

    /** @notice See {IHATVaultsRegistry-getSetMaxBountyDelay}. */   
    function getSetMaxBountyDelay() external view returns (uint256) {
        return generalParameters.setMaxBountyDelay;
    }

    /** @notice See {IHATVaultsRegistry-getNumberOfVaults}. */
    function getNumberOfVaults() external view returns(uint256) {
        return hatVaults.length;
    }

    function owner() public view override(IHATVaultsRegistry, Ownable) virtual returns (address) {
        return Ownable.owner();
    }

    /** @notice See {IHATVaultsRegistry-validateHATSplit}. */
    function validateHATSplit(uint16 _bountyGovernanceHAT, uint16 _bountyHackerHATVested) public pure {
        if (_bountyGovernanceHAT + _bountyHackerHATVested > MAX_HAT_SPLIT)
            revert TotalHatsSplitPercentageShouldBeUpToMaxHATSplit();
    }

    /** @notice See {IHATVaultsRegistry-validateChallengePeriod}. */
    function validateChallengePeriod(uint32 _challengePeriod) public pure {
        if (_challengePeriod < 1 days) revert ChallengePeriodTooShort();
        if (_challengePeriod > 5 days) revert ChallengePeriodTooLong();
    }

    /** @notice See {IHATVaultsRegistry-validateChallengeTimeOutPeriod}. */
    function validateChallengeTimeOutPeriod(uint32 _challengeTimeOutPeriod) public pure {
        if (_challengeTimeOutPeriod < 2 days) revert ChallengeTimeOutPeriodTooShort();
        if (_challengeTimeOutPeriod > 125 days) revert ChallengeTimeOutPeriodTooLong();
    }
    
    /**
    * @dev Use the given routing contract to swap the given token to HAT token
    * @param _asset The token to swap
    * @param _amount Amount of token to swap
    * @param _amountOutMinimum Minimum amount of HAT tokens at swap
    * @param _routingContract Routing contract to call for the swap
    * @param _routingPayload Payload to send to the _routingContract for the 
    * swap
    */
    function _swapTokenForHAT(
        IERC20 _asset,
        uint256 _amount,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload)
    internal
    returns (uint256 hatsReceived, uint256 amountUnused)
    {
        IERC20 _HAT = HAT;
        if (_asset == _HAT) {
            return (_amount, 0);
        }

        IERC20(_asset).safeApprove(_routingContract, _amount);
        uint256 _balanceBefore = _HAT.balanceOf(address(this));
        uint256 _assetBalanceBefore = _asset.balanceOf(address(this));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = _routingContract.call(_routingPayload);
        if (!success) revert SwapFailed();
        hatsReceived = _HAT.balanceOf(address(this)) - _balanceBefore;
        amountUnused = _amount - (_assetBalanceBefore - _asset.balanceOf(address(this)));
        if (hatsReceived < _amountOutMinimum)
            revert AmountSwappedLessThanMinimum();

        IERC20(_asset).safeApprove(address(_routingContract), 0);
    }
}

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewardController.sol";
import "./IHATVault.sol";
import "./IHATVaultsRegistry.sol";

/** @title Interface for Hats.finance Vaults
 * @author Hats.finance
 * @notice A HATVault holds the funds for a specific project's bug bounties.
 * Anyone can permissionlessly deposit into the HATVault using
 * the vault’s native token. When a bug is submitted and approved, the bounty 
 * is paid out using the funds in the vault. Bounties are paid out as a
 * percentage of the vault. The percentage is set according to the severity of
 * the bug. Vaults have regular safety periods (typically for an hour twice a
 * day) which are time for the committee to make decisions.
 *
 * In addition to the roles defined in the IHATVaultsRegistry, every HATVault 
 * has the roles:
 * Committee - The only address which can submit a claim for a bounty payout
 * and set the maximum bounty.
 * User - Anyone can deposit the vault's native token into the vault and 
 * recieve shares for it. Shares represent the user's relative part in the
 * vault, and when a bounty is paid out, users lose part of their deposits
 * (based on percentage paid), but keep their share of the vault.
 * Users also receive rewards for their deposits, which can be claimed at any
 *  time.
 * To withdraw previously deposited tokens, a user must first send a withdraw
 * request, and the withdrawal will be made available after a pending period.
 * Withdrawals are not permitted during safety periods or while there is an 
 * active claim for a bounty payout.
 *
 * Bounties are payed out distributed between a few channels, and that 
 * distribution is set upon creation (the hacker gets part in direct transfer,
 * part in vested reward and part in vested HAT token, part gets rewarded to
 * the committee, part gets swapped to HAT token and burned and/or sent to Hats
 * governance).
 *
 * NOTE: Vaults should not use tokens which do not guarantee that the amount
 * specified is the amount transferred
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 */
interface IHATClaimsManager {

    // How to divide the bounty - after deducting the part that is swapped to
    // HAT tokens (and then sent to governance and vested to the hacker)
    // values are in percentages and should add up to 100% (defined as 10000)
    struct BountySplit {
        // the percentage of reward sent to the hacker via vesting contract
        uint16 hackerVested;
        // the percentage of tokens that are sent directly to the hacker
        uint16 hacker;
        // the percentage sent to the committee
        uint16 committee;
    }

    // How to divide a bounty for a claim that has been approved
    // used to keep track of payouts, amounts are in vault's native token
    struct ClaimBounty {
        uint256 hacker;
        uint256 hackerVested;
        uint256 committee;
        uint256 hackerHatVested;
        uint256 governanceHat;
    }

    struct Claim {
        bytes32 claimId;
        address beneficiary;
        uint16 bountyPercentage;
        // the address of the committee at the time of the submission, so that this committee will
        // be paid their share of the bounty in case the committee changes before claim approval
        address committee;
        uint32 createdAt;
        uint32 challengedAt;
        uint256 bountyGovernanceHAT;
        uint256 bountyHackerHATVested;
        address arbitrator;
        uint32 challengePeriod;
        uint32 challengeTimeOutPeriod;
        bool arbitratorCanChangeBounty;
        bool arbitratorCanChangeBeneficiary;
    }

    struct PendingMaxBounty {
        uint16 maxBounty;
        uint32 timestamp;
    }

    /**
    * @notice Initialization parameters for the vault
    * @param name The vault's name (concatenated as "Hats Vault " + name)
    * @param symbol The vault's symbol (concatenated as "HAT" + symbol)
    * @param rewardController The reward controller for the vault
    * @param vestingDuration Duration of the vesting period of the vault's
    * token vested part of the bounty
    * @param vestingPeriods The number of vesting periods of the vault's token
    * vested part of the bounty
    * @param maxBounty The maximum percentage of the vault that can be paid
    * out as a bounty
    * @param bountySplit The way to split the bounty between the hacker, 
    * hacker vested, and committee.
    *   Each entry is a number between 0 and `HUNDRED_PERCENT`.
    *   Total splits should be equal to `HUNDRED_PERCENT`.
    * @param bountyGovernanceHAT The HAT bounty for governance
    * @param bountyHackerHATVested The HAT bounty vested for the hacker
    * @param asset The vault's native token
    * @param owner The address of the vault's owner 
    * @param committee The address of the vault's committee 
    * @param arbitrator The address of the vault's arbitrator
    * @param arbitratorCanChangeBounty Can the arbitrator change a claim's bounty
    * @param arbitratorCanChangeBeneficiary Can the arbitrator change a claim's beneficiary
    * @param arbitratorCanSubmitClaims Can the arbitrator submit a claim
    * @param isTokenLockRevocable can the committee revoke the token lock
    * @dev Needed to avoid a "stack too deep" error
    */
    struct ClaimsManagerInitParams {
        uint32 vestingDuration;
        uint32 vestingPeriods;
        uint16 maxBounty;
        BountySplit bountySplit;
        uint16 bountyGovernanceHAT;
        uint16 bountyHackerHATVested;
        address owner;
        address committee;
        address arbitrator;
        bool arbitratorCanChangeBounty;
        bool arbitratorCanChangeBeneficiary;
        bool arbitratorCanSubmitClaims;
        bool isTokenLockRevocable;
    }

    // Only committee
    error OnlyCommittee();
    // Active claim exists
    error ActiveClaimExists();
    // Safety period
    error SafetyPeriod();
    // Not safety period
    error NotSafetyPeriod();
    // Bounty percentage is higher than the max bounty
    error BountyPercentageHigherThanMaxBounty();
    // Only callable by arbitrator or after challenge timeout period
    error OnlyCallableByArbitratorOrAfterChallengeTimeOutPeriod();
    // No active claim exists
    error NoActiveClaimExists();
    // Claim Id specified is not the active claim Id
    error ClaimIdIsNotActive();
    // Not enough fee paid
    error NotEnoughFeePaid();
    // No pending max bounty
    error NoPendingMaxBounty();
    // Delay period for setting max bounty had not passed
    error DelayPeriodForSettingMaxBountyHadNotPassed();
    // Committee already checked in
    error CommitteeAlreadyCheckedIn();
    // Total bounty split % should be `HUNDRED_PERCENT`
    error TotalSplitPercentageShouldBeHundredPercent();
    // Vesting duration is too long
    error VestingDurationTooLong();
    // Vesting periods cannot be zero
    error VestingPeriodsCannotBeZero();
    // Vesting duration smaller than periods
    error VestingDurationSmallerThanPeriods();
    // Max bounty cannot be more than `MAX_BOUNTY_LIMIT` (unless if it is 100%)
    error MaxBountyCannotBeMoreThanMaxBountyLimit();
    // Committee bounty split cannot be more than `MAX_COMMITTEE_BOUNTY`
    error CommitteeBountyCannotBeMoreThanMax();
    // Only registry owner
    error OnlyRegistryOwner();
    // Set shares arrays must have same length
    error SetSharesArraysMustHaveSameLength();
    // Not enough user balance
    error NotEnoughUserBalance();
    // Only arbitrator or registry owner
    error OnlyArbitratorOrRegistryOwner();
    // Unchallenged claim can only be approved if challenge period is over
    error UnchallengedClaimCanOnlyBeApprovedAfterChallengePeriod();
    // Challenged claim can only be approved by arbitrator before the challenge timeout period
    error ChallengedClaimCanOnlyBeApprovedByArbitratorUntilChallengeTimeoutPeriod();
    // Claim has expired
    error ClaimExpired();
    // Challenge period is over
    error ChallengePeriodEnded();
    // Claim can be challenged only once
    error ClaimAlreadyChallenged();
    // Only callable if challenged
    error OnlyCallableIfChallenged();
    // System is in an emergency pause
    error SystemInEmergencyPause();
    // Cannot set a reward controller that was already used in the past
    error CannotSetToPerviousRewardController();
    // Payout must either be 100%, or up to the MAX_BOUNTY_LIMIT
    error PayoutMustBeUpToMaxBountyLimitOrHundredPercent();


    event SubmitClaim(
        bytes32 indexed _claimId,
        address _committee,
        address indexed _submitter,
        address indexed _beneficiary,
        uint256 _bountyPercentage,
        string _descriptionHash
    );
    event ChallengeClaim(bytes32 indexed _claimId);
    event ApproveClaim(
        bytes32 indexed _claimId,
        address _committee,
        address indexed _approver,
        address indexed _beneficiary,
        uint256 _bountyPercentage,
        address _tokenLock,
        ClaimBounty _claimBounty
    );
    event DismissClaim(bytes32 indexed _claimId);
    event SetCommittee(address indexed _committee);
    event SetVestingParams(
        uint256 _duration,
        uint256 _periods
    );
    event SetBountySplit(BountySplit _bountySplit);
    event CommitteeCheckedIn();
    event SetPendingMaxBounty(uint256 _maxBounty);
    event SetMaxBounty(uint256 _maxBounty);
    event SetHATBountySplit(uint256 _bountyGovernanceHAT, uint256 _bountyHackerHATVested);
    event SetArbitrator(address indexed _arbitrator);
    event SetChallengePeriod(uint256 _challengePeriod);
    event SetChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod);
    event SetArbitratorOptions(bool _arbitratorCanChangeBounty, bool _arbitratorCanChangeBeneficiary, bool _arbitratorCanSubmitClaims);

    /**
    * @notice Initialize a claims manager instance
    * @param _vault The vault instance
    * @param _params The claim manager's initialization parameters
    * @dev See {IHATClaimsManager-ClaimsManagerInitParams} for more details
    * @dev Called when the vault is created in {IHATVaultsRegistry-createVault}
    */
    function initialize(IHATVault _vault, ClaimsManagerInitParams calldata _params) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Claim --------------------------------------- */

    /**
     * @notice Called by the committee to submit a claim for a bounty payout.
     * This function should be called only on a safety period, when withdrawals
     * are disabled, and while there's no other active claim. Cannot be called
     * when the registry is in an emergency pause.
     * Upon a call to this function by the committee the vault's withdrawals
     * will be disabled until the claim is approved or dismissed. Also from the
     * time of this call the arbitrator will have a period of 
     * {IHATVaultsRegistry.challengePeriod} to challenge the claim.
     * @param _beneficiary The submitted claim's beneficiary
     * @param _bountyPercentage The submitted claim's bug requested reward percentage
     */
    function submitClaim(
        address _beneficiary, 
        uint16 _bountyPercentage, 
        string calldata _descriptionHash
    )
        external
        returns (bytes32 claimId);

   
    /**
    * @notice Called by the arbitrator or governance to challenge a claim for a bounty
    * payout that had been previously submitted by the committee.
    * Can only be called during the challenge period after submission of the
    * claim.
    * @param _claimId The claim ID
    */
    function challengeClaim(bytes32 _claimId) external;

    /**
    * @notice Approve a claim for a bounty submitted by a committee, and
    * pay out bounty to hacker and committee. Also transfer to the 
    * IHATVaultsRegistry the part of the bounty that will be swapped to HAT 
    * tokens.
    * If the claim had been previously challenged, this is only callable by
    * the arbitrator. Otherwise, callable by anyone after challengePeriod had
    * passed.
    * @param _claimId The claim ID
    * @param _bountyPercentage The percentage of the vault's balance that will
    * be sent as a bounty. This value will be ignored if the caller is not the
    * arbitrator.
    * @param _beneficiary where the bounty will be sent to. This value will be 
    * ignored if the caller is not the arbitrator.
    */
    function approveClaim(bytes32 _claimId, uint16 _bountyPercentage, address _beneficiary)
        external;

    /**
    * @notice Dismiss the active claim for bounty payout submitted by the
    * committee.
    * Called either by the arbitrator, or by anyone if the claim has timed out.
    * @param _claimId The claim ID
    */
    function dismissClaim(bytes32 _claimId) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Params -------------------------------------- */

    /**
    * @notice Set new committee address. Can be called by existing committee,
    * or by the the vault's owner in the case that the committee hadn't checked in
    * yet.
    * @param _committee The address of the new committee 
    */
    function setCommittee(address _committee) external;

    /**
    * @notice Called by the vault's owner to set the vesting params for the
    * part of the bounty that the hacker gets vested in the vault's native
    * token
    * @param _duration Duration of the vesting period. Must be smaller than
    * 120 days and bigger than `_periods`
    * @param _periods Number of vesting periods. Cannot be 0.
    */
    function setVestingParams(uint32 _duration, uint32 _periods) external;

    /**
    * @notice Called by the vault's owner to set the vault token bounty split
    * upon an approval.
    * Can only be called if is no active claim and not during safety periods.
    * @param _bountySplit The bounty split
    */
    function setBountySplit(BountySplit calldata _bountySplit) external;

    /**
    * @notice Called by the vault's committee to claim it's role.
    * Deposits are enabled only after committee check in.
    */
    function committeeCheckIn() external;

    /**
    * @notice Called by the vault's owner to set a pending request for the
    * maximum percentage of the vault that can be paid out as a bounty.
    * Cannot be called if there is an active claim that has been submitted.
    * Max bounty should be less than or equal to 90% (defined as 9000).
    * It can also be set to 100%, but in this mode the vault will only allow
    * payouts of the 100%, and the vault will become inactive forever afterwards.
    * The pending value can be set by the owner after the time delay (of 
    * {IHATVaultsRegistry.generalParameters.setMaxBountyDelay}) had passed.
    * @param _maxBounty The maximum bounty percentage that can be paid out
    */
    function setPendingMaxBounty(uint16 _maxBounty) external;

    /**
    * @notice Called by the vault's owner to set the vault's max bounty to
    * the already pending max bounty.
    * Cannot be called if there are active claims that have been submitted.
    * Can only be called if there is a max bounty pending approval, and the
    * time delay since setting the pending max bounty had passed.
    */
    function setMaxBounty() external;

    /**
    * @notice Called by the registry's owner to set the vault HAT token bounty 
    * split upon an approval.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _bountyGovernanceHAT The HAT bounty for governance
    * @param _bountyHackerHATVested The HAT bounty vested for the hacker
    */
    function setHATBountySplit(
        uint16 _bountyGovernanceHAT,
        uint16 _bountyHackerHATVested
    ) 
        external;

    /**
    * @notice Called by the registry's owner to set the vault arbitrator
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _arbitrator The address of vault's arbitrator
    */
    function setArbitrator(address _arbitrator) external;

    /**
    * @notice Called by the registry's owner to set the period of time after
    * a claim for a bounty payout has been submitted that it can be challenged
    * by the arbitrator.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _challengePeriod The vault's challenge period
    */
    function setChallengePeriod(uint32 _challengePeriod) external;

    /**
    * @notice Called by the registry's owner to set the period of time after
    * which a claim for a bounty payout can be dismissed by anyone.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _challengeTimeOutPeriod The vault's challenge timeout period
    */
    function setChallengeTimeOutPeriod(uint32 _challengeTimeOutPeriod)
        external;

    /**
    * @notice Called by the registry's owner to set whether the arbitrator
    * can change a claim bounty percentage and/ or beneficiary
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _arbitratorCanChangeBounty Whether the arbitrator can change a claim bounty percentage
    * @param _arbitratorCanChangeBeneficiary Whether the arbitrator can change a claim beneficiary
    */
    function setArbitratorOptions(
        bool _arbitratorCanChangeBounty,
        bool _arbitratorCanChangeBeneficiary,
        bool _arbitratorCanSubmitClaims
    )
        external;

    /* -------------------------------------------------------------------------------- */

    /* --------------------------------- Getters -------------------------------------- */

    /** 
    * @notice Returns the max bounty that can be paid from the vault in percentages out of HUNDRED_PERCENT
    * @return The max bounty
    */
    function maxBounty() external view returns(uint16);

    /** 
    * @notice Returns the vault's registry
    * @return The registry's address
    */
    function registry() external view returns(IHATVaultsRegistry);

    /** 
    * @notice Returns whether the committee has checked in
    * @return Whether the committee has checked in
    */
    function committeeCheckedIn() external view returns(bool);

    /** 
    * @notice Returns the current active claim
    * @return The current active claim
    */
    function getActiveClaim() external view returns(Claim memory);

    /** 
    * @notice Returns the vault HAT bounty split part that goes to the governance
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's HAT bounty split part that goes to the governance
    */
    function getBountyGovernanceHAT() external view returns(uint16);
    
    /** 
    * @notice Returns the vault HAT bounty split part that is vested for the hacker
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's HAT bounty split part that is vested for the hacker
    */
    function getBountyHackerHATVested() external view returns(uint16);

    /** 
    * @notice Returns the address of the vault's arbitrator
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The address of the vault's arbitrator
    */
    function getArbitrator() external view returns(address);

    /** 
    * @notice Returns the period of time after a claim for a bounty payout has
    * been submitted that it can be challenged by the arbitrator.
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's challenge period
    */
    function getChallengePeriod() external view returns(uint32);

    /** 
    * @notice Returns the period of time after which a claim for a bounty
    * payout can be dismissed by anyone.
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's challenge timeout period
    */
    function getChallengeTimeOutPeriod() external view returns(uint32);

    /** 
    * @notice Returns the claims manager's version
    * @return The claims manager's version
    */
    function VERSION() external view returns(string calldata);
}

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewardController.sol";
import "./IHATVaultsRegistry.sol";
import "./IHATClaimsManager.sol";

/** @title Interface for Hats.finance Vaults
 * @author Hats.finance
 * @notice A HATVault holds the funds for a specific project's bug bounties.
 * Anyone can permissionlessly deposit into the HATVault using
 * the vault’s native token. When a bug is submitted and approved, the bounty 
 * is paid out using the funds in the vault. Bounties are paid out as a
 * percentage of the vault. The percentage is set according to the severity of
 * the bug. Vaults have regular safety periods (typically for an hour twice a
 * day) which are time for the committee to make decisions.
 *
 * In addition to the roles defined in the HATVaultsRegistry, every HATVault 
 * has the roles:
 * Committee - The only address which can submit a claim for a bounty payout
 * and set the maximum bounty.
 * User - Anyone can deposit the vault's native token into the vault and 
 * recieve shares for it. Shares represent the user's relative part in the
 * vault, and when a bounty is paid out, users lose part of their deposits
 * (based on percentage paid), but keep their share of the vault.
 * Users also receive rewards for their deposits, which can be claimed at any
 *  time.
 * To withdraw previously deposited tokens, a user must first send a withdraw
 * request, and the withdrawal will be made available after a pending period.
 * Withdrawals are not permitted during safety periods or while there is an 
 * active claim for a bounty payout.
 *
 * Bounties are payed out distributed between a few channels, and that 
 * distribution is set upon creation (the hacker gets part in direct transfer,
 * part in vested reward and part in vested HAT token, part gets rewarded to
 * the committee, part gets swapped to HAT token and burned and/or sent to Hats
 * governance).
 *
 * NOTE: Vaults should not use tokens which do not guarantee that the amount
 * specified is the amount transferred
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 */
interface IHATVault is IERC4626Upgradeable {

    /**
    * @notice Initialization parameters for the vault token
    * @param name The vault's name (concatenated as "Hats Vault " + name)
    * @param symbol The vault's symbol (concatenated as "HAT" + symbol)
    * @param rewardController The reward controller for the vault
    * @param asset The vault's native token
    * @param owner The address of the vault's owner 
    * @param isPaused Whether to initialize the vault with deposits disabled
    * @param descriptionHash The hash of the vault's description
    */
    struct VaultInitParams {
        string name;
        string symbol;
        IRewardController[] rewardControllers;
        IERC20 asset;
        address owner;
        bool isPaused;
        string descriptionHash;
    }

    // Only claims manager can make this call
    error OnlyClaimsManager();
    // Only registry owner
    error OnlyRegistryOwner();
    // Vault not started yet
    error VaultNotStartedYet();
    // First deposit must return at least MINIMAL_AMOUNT_OF_SHARES
    error AmountOfSharesMustBeMoreThanMinimalAmount();
    // Withdraw amount must be greater than zero
    error WithdrawMustBeGreaterThanZero();
    // Cannot mint burn or transfer 0 amount of shares
    error AmountCannotBeZero();
    // Cannot transfer shares to self
    error CannotTransferToSelf();
    // Cannot deposit to another user with withdraw request
    error CannotTransferToAnotherUserWithActiveWithdrawRequest();
    // Redeem amount cannot be more than maximum for user
    error RedeemMoreThanMax();
    // Deposit passed max slippage
    error DepositSlippageProtection();
    // Mint passed max slippage
    error MintSlippageProtection();
    // Withdraw passed max slippage
    error WithdrawSlippageProtection();
    // Redeem passed max slippage
    error RedeemSlippageProtection();
    // Cannot add the same reward controller more than once
    error DuplicatedRewardController();
    // Fee must be less than or equal to 2%
    error WithdrawalFeeTooBig();
    // System is in an emergency pause
    error SystemInEmergencyPause();
    // Only fee setter
    error OnlyFeeSetter();
    // Cannot unpasue deposits for a vault that was destroyed
    error CannotUnpauseDestroyedVault();

    event AddRewardController(IRewardController indexed _newRewardController);
    event SetWithdrawalFee(uint256 _newFee);
    event VaultPayout(uint256 _amount);
    event SetDepositPause(bool _depositPause);
    event SetWithdrawPaused(bool _withdrawPaused);
    event VaultStarted();
    event VaultDestroyed();
    event SetVaultDescription(string _descriptionHash);
    event WithdrawRequest(
        address indexed _beneficiary,
        uint256 _withdrawEnableTime
    );

    /**
    * @notice Initialize a vault token instance
    * @param _claimsManager The vault's claims manager
    * @param _params The vault token initialization parameters
    * @dev See {IHATVault-VaultInitParams} for more details
    * @dev Called when the vault token is created in {IHATVaultsRegistry-createVault}
    */
    function initialize(address _claimsManager, VaultInitParams calldata _params) external;

    /**
    * @notice Adds a reward controller to the reward controllers list
    * @param _rewardController The reward controller to add
    */
    function addRewardController(IRewardController _rewardController) external;

    /**
    * @notice Called by the vault's owner to disable all deposits to the vault
    * @param _depositPause Are deposits paused
    */
    function setDepositPause(bool _depositPause) external;

    /**
    * @notice Called by the registry's fee setter to set the fee for 
    * withdrawals from the vault.
    * @param _fee The new fee. Must be smaller than or equal to `MAX_WITHDRAWAL_FEE`
    */
    function setWithdrawalFee(uint256 _fee) external;

    /**
    * @notice Make a payout out of the vault
    * @param _amount The amount to send out for the payout
    */
    function makePayout(uint256 _amount) external;

    /**
    * @notice Called by the vault's claims manager to disable all withdrawals from the vault
    * @param _withdrawPaused Are withdraws paused
    */
    function setWithdrawPaused(bool _withdrawPaused) external;

    /**
    * @notice Start the vault, deposits are disabled until the vault is first started
    */
    function startVault() external;


    /**
    * @notice Permanently disables deposits to the vault
    */
    function destroyVault() external;

    /**
    * @notice Called by the registry's owner to change the description of the
    * vault in the Hats.finance UI
    * @param _descriptionHash the hash of the vault's description
    */
    function setVaultDescription(string calldata _descriptionHash) external;
    
    /** 
    * @notice Returns the vault's version
    * @return The vault's version
    */
    function VERSION() external view returns(string calldata);

    /** 
    * @notice Returns the vault's registry
    * @return The registry's address
    */
    function registry() external view returns(IHATVaultsRegistry);

    /** 
    * @notice Returns the vault's registry
    * @return The registry's address
    */
    function claimsManager() external view returns(address);

    /**
    * @notice Submit a request to withdraw funds from the vault.
    * The request will only be approved if there is no previous active
    * withdraw request.
    * The request will be pending for a period of
    * {HATVaultsRegistry.generalParameters.withdrawRequestPendingPeriod},
    * after which a withdraw will be possible for a duration of
    * {HATVaultsRegistry.generalParameters.withdrawRequestEnablePeriod}
    */
    function withdrawRequest() external;

    /** 
    * @notice Withdraw previously deposited funds from the vault and claim
    * the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds
    * @param owner Address of owner of the funds
    * @dev See {IERC4626-withdraw}.
    */
    function withdrawAndClaim(uint256 assets, address receiver, address owner)
        external 
        returns (uint256 shares);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets and claim the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-redeem}.
    */
    function redeemAndClaim(uint256 shares, address receiver, address owner)
        external 
        returns (uint256 assets);

    /** 
    * @notice Redeem all of the user's shares in the vault for the respective amount
    * of underlying assets without calling the reward controller, meaning user renounces
    * their uncommited part of the reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param receiver Address of receiver of the funds 
    */
    function emergencyWithdraw(address receiver) external returns (uint256 assets);

    /** 
    * @notice Withdraw previously deposited funds from the vault, without
    * transferring the accumulated rewards.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-withdraw}.
    */
    function withdraw(uint256 assets, address receiver, address owner)
        external 
        returns (uint256);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets, without transferring the accumulated reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-redeem}.
    */
    function redeem(uint256 shares, address receiver, address owner)
        external  
        returns (uint256);

    /**
    * @dev Deposit funds to the vault. Can only be called if the committee had
    * checked in and deposits are not paused, and the registry is not in an emergency pause.
    * @param receiver Reciever of the shares from the deposit
    * @param assets Amount of vault's native token to deposit
    * @dev See {IERC4626-deposit}.
    */
    function deposit(uint256 assets, address receiver) 
        external
        returns (uint256);

    /**
    * @dev Deposit funds to the vault. Can only be called if the committee had
    * checked in and deposits are not paused, and the registry is not in an emergency pause.
    * Allows to specify minimum shares to be minted for slippage protection.
    * @param receiver Reciever of the shares from the deposit
    * @param assets Amount of vault's native token to deposit
    * @param minShares Minimum amount of shares to minted for the assets
    */
    function deposit(uint256 assets, address receiver, uint256 minShares) 
        external
        returns (uint256);

    /**
    * @dev Deposit funds to the vault based on the amount of shares to mint specified.
    * Can only be called if the committee had checked in and deposits are not paused,
    * and the registry is not in an emergency pause.
    * Allows to specify maximum assets to be deposited for slippage protection.
    * @param receiver Reciever of the shares from the deposit
    * @param shares Amount of vault's shares to mint
    * @param maxAssets Maximum amount of assets to deposit for the shares
    */
    function mint(uint256 shares, address receiver, uint256 maxAssets) 
        external
        returns (uint256);

    /** 
    * @notice Withdraw previously deposited funds from the vault, without
    * transferring the accumulated HAT reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify maximum shares to be burnt for slippage protection.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds
    * @param maxShares Maximum amount of shares to burn for the assets
    */
    function withdraw(uint256 assets, address receiver, address owner, uint256 maxShares)
        external 
        returns (uint256);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets, without transferring the accumulated reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify minimum assets to be received for slippage protection.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds
    * @param minAssets Minimum amount of assets to receive for the shares
    */
    function redeem(uint256 shares, address receiver, address owner, uint256 minAssets)
        external  
        returns (uint256);

    /** 
    * @notice Withdraw previously deposited funds from the vault and claim
    * the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify maximum shares to be burnt for slippage protection.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds
    * @param owner Address of owner of the funds
    * @param maxShares Maximum amount of shares to burn for the assets
    * @dev See {IERC4626-withdraw}.
    */
    function withdrawAndClaim(uint256 assets, address receiver, address owner, uint256 maxShares)
        external 
        returns (uint256 shares);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets and claim the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify minimum assets to be received for slippage protection.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds
    * @param minAssets Minimum amount of assets to receive for the shares
    * @dev See {IERC4626-redeem}.
    */
    function redeemAndClaim(uint256 shares, address receiver, address owner, uint256 minAssets)
        external 
        returns (uint256 assets);

    /** 
    * @notice Returns the amount of shares to be burned to give the user the exact
    * amount of assets requested plus cover for the fee. Also returns the amount assets
    * to be paid as fee.
    * @return shares The amount of shares to be burned to get the requested amount of assets
    * @return fee The amount of assets that will be paid as fee
    */
    function previewWithdrawAndFee(uint256 assets) external view returns (uint256 shares, uint256 fee);


    /** 
    * @notice Returns the amount of assets to be sent to the user for the exact
    * amount of shares to redeem. Also returns the amount assets to be paid as fee.
    * @return assets amount of assets to be sent in exchange for the amount of shares specified
    * @return fee The amount of assets that will be paid as fee
    */
    function previewRedeemAndFee(uint256 shares) external view returns (uint256 assets, uint256 fee);
}

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "./IHATVault.sol";
import "./IHATClaimsManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title Interface for the Hats.finance Vault Registry
 * @author hats.finance
 * @notice The Hats.finance Vault Registry is used to deploy Hats.finance
 * vaults and manage shared parameters.
 *
 * Hats.finance is a proactive bounty protocol for white hat hackers and
 * security experts, where projects, community members, and stakeholders
 * incentivize protocol security and responsible disclosure.
 * Hats create scalable vaults using the project’s own token. The value of the
 * bounty increases with the success of the token and project.
 *
 * The owner of the registry has the permission to set time limits and bounty
 * parameters and change vaults' info, and to set the other registry roles -
 * fee setter and arbitrator.
 * The arbitrator can challenge submitted claims for bounty payouts made by
 * vaults' committees, approve them with a different bounty percentage or
 * dismiss them.
 * The fee setter can set the fee on withdrawals on all vaults.
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 *
 * @dev New hats.finance vaults should be created through a call to {createVault}
 * so that they are linked to the registry
 */
interface IHATVaultsRegistry {

    // a struct with parameters for all vaults
    struct GeneralParameters {
        // vesting duration for the part of the bounty given to the hacker in HAT tokens
        uint32 hatVestingDuration;
        // vesting periods for the part of the bounty given to the hacker in HAT tokens
        uint32 hatVestingPeriods;
        // withdraw enable period. safetyPeriod starts when finished.
        uint32 withdrawPeriod;
        // withdraw disable period - time for the committee to gather and decide on actions,
        // withdrawals are not possible in this time. withdrawPeriod starts when finished.
        uint32 safetyPeriod;
        // period of time after withdrawRequestPendingPeriod where it is possible to withdraw
        // (after which withdrawals are not possible)
        uint32 withdrawRequestEnablePeriod;
        // period of time that has to pass after withdraw request until withdraw is possible
        uint32 withdrawRequestPendingPeriod;
        // period of time that has to pass after setting a pending max
        // bounty before it can be set as the new max bounty
        uint32 setMaxBountyDelay;
        // fee in ETH to be transferred with every logging of a claim
        uint256 claimFee;
    }

    /**
     * @notice Raised on {setWithdrawSafetyPeriod} if the withdraw period to
     * be set is shorter than 1 hour
     */
    error WithdrawPeriodTooShort();

    /**
     * @notice Raised on {setWithdrawSafetyPeriod} if the safety period to
     * be set is longer than 6 hours
     */
    error SafetyPeriodTooLong();

    /**
     * @notice Raised on {setWithdrawRequestParams} if the withdraw request
     * pending period to be set is shorter than 3 months
     */
    error WithdrawRequestPendingPeriodTooLong();

    /**
     * @notice Raised on {setWithdrawRequestParams} if the withdraw request
     * enabled period to be set is shorter than 6 hours
     */
    error WithdrawRequestEnabledPeriodTooShort();

    /**
     * @notice Raised on {setWithdrawRequestParams} if the withdraw request
     * enabled period to be set is longer than 100 days
     */
    error WithdrawRequestEnabledPeriodTooLong();

    /**
     * @notice Raised on {setHatVestingParams} if the vesting duration to be
     * set is longer than 180 days
     */
    error HatVestingDurationTooLong();

    /**
     * @notice Raised on {setHatVestingParams} if the vesting periods to be
     * set is 0
     */
    error HatVestingPeriodsCannotBeZero();
    
    /**
     * @notice Raised on {setHatVestingParams} if the vesting duration is 
     * smaller than the vesting periods
     */
    error HatVestingDurationSmallerThanPeriods();

    /**
     * @notice Raised on {setMaxBountyDelay} if the max bounty to be set is
     * shorter than 2 days
     */
    error DelayTooShort();

    /**
     * @notice Raised on {swapAndSend} if the amount to swap is zero
     */
    error AmountToSwapIsZero();

    /**
     * @notice Raised on {swapAndSend} if the swap was not successful
     */
    error SwapFailed();
    // Wrong amount received

    /**
     * @notice Raised on {swapAndSend} if the amount that was recieved in
     * the swap was less than the minimum amount specified
     */
    error AmountSwappedLessThanMinimum();

    /**
     * @notice Raised on {setDefaultHATBountySplit} if the split to be set is
     * greater than 20% (defined as 2000)
     */
    error TotalHatsSplitPercentageShouldBeUpToMaxHATSplit();

    /**
     * @notice Raised on {setDefaultChallengePeriod} if the challenge period
     *  to be set is shorter than 1 day
     */
    error ChallengePeriodTooShort();

    /**
     * @notice Raised on {setDefaultChallengePeriod} if the challenge period
     *  to be set is longer than 5 days
     */
    error ChallengePeriodTooLong();
        
    /**
     * @notice Raised on {setDefaultChallengeTimeOutPeriod} if the challenge
     * timeout period to be set is shorter than 1 day
     */
    error ChallengeTimeOutPeriodTooShort();

    /**
     * @notice Raised on {setDefaultChallengeTimeOutPeriod} if the challenge
     * timeout period to be set is longer than 125 days
     */
    error ChallengeTimeOutPeriodTooLong();
    
    /**
     * @notice Raised on {LogClaim} if the transaction was not sent with the
     * amount of ETH specified as {generalParameters.claimFee}
     */
    error NotEnoughFeePaid();

    /**
     * @notice Raised on {LogClaim} if the transfer of the claim fee failed
     */
    error ClaimFeeTransferFailed();

    /**
     * @notice Emitted on deployment of the registry
     * @param _hatVaultImplementation The HATVault implementation address
     * @param _hatClaimsManagerImplementation The HATClaimsManager implementation address
     * @param _HAT The HAT token address
     * @param _tokenLockFactory The token lock factory address
     * @param _generalParameters The registry's general parameters
     * @param _bountyGovernanceHAT The HAT bounty for governance
     * @param _bountyHackerHATVested The HAT bounty vested for the hacker
     * @param _hatGovernance The registry's governance
     * @param _defaultChallengePeriod The new default challenge period
     * @param _defaultChallengeTimeOutPeriod The new default challenge timeout
     */
    event RegistryCreated(
        address _hatVaultImplementation,
        address _hatClaimsManagerImplementation,
        address _HAT,
        address _tokenLockFactory,
        GeneralParameters _generalParameters,
        uint256 _bountyGovernanceHAT,
        uint256 _bountyHackerHATVested,
        address _hatGovernance,
        address _defaultArbitrator,
        uint256 _defaultChallengePeriod,
        uint256 _defaultChallengeTimeOutPeriod
    );

    /**
     * @notice Emitted when a claim is logged
     * @param _claimer The address of the claimer
     * @param _descriptionHash - a hash of an ipfs encrypted file which
     * describes the claim.
     */
    event LogClaim(address indexed _claimer, string _descriptionHash);

    /**
     * @notice Emitted when a new fee setter is set
     * @param _feeSetter The address of the new fee setter
     */
    event SetFeeSetter(address indexed _feeSetter);

    /**
     * @notice Emitted when new withdraw request time limits are set
     * @param _withdrawRequestPendingPeriod Time period where the withdraw
     * request is pending
     * @param _withdrawRequestEnablePeriod Time period after the peding period
     * has ended during which withdrawal is enabled
     */
    event SetWithdrawRequestParams(
        uint256 _withdrawRequestPendingPeriod,
        uint256 _withdrawRequestEnablePeriod
    );

    /**
     * @notice Emitted when a new fee for logging a claim for a bounty is set
     * @param _fee Claim fee in ETH to be transferred on any call of {logClaim}
     */
    event SetClaimFee(uint256 _fee);

    /**
     * @notice Emitted when new durations are set for withdraw period and
     * safety period
     * @param _withdrawPeriod Amount of time during which withdrawals are
     * enabled, and the bounty split can be changed by the governance
     * @param _safetyPeriod Amount of time during which claims for bounties 
     * can be submitted and withdrawals are disabled
     */
    event SetWithdrawSafetyPeriod(
        uint256 _withdrawPeriod,
        uint256 _safetyPeriod
    );

    /**
     * @notice Emitted when new HAT vesting parameters are set
     * @param _duration The duration of the vesting period
     * @param _periods The number of vesting periods
     */
    event SetHatVestingParams(uint256 _duration, uint256 _periods);

    /**
     * @notice Emitted when a new timelock delay for setting the
     * max bounty is set
     * @param _delay The time period for the delay
     */
    event SetMaxBountyDelay(uint256 _delay);

    /**
     * @notice Emitted when the UI visibility of a vault is changed
     * @param _vault The address of the vault to update
     * @param _visible Is this vault visible in the UI
     */
    event SetVaultVisibility(address indexed _vault, bool indexed _visible);

    /** @dev Emitted when a new vault is created
     * @param _vault The address of the vault to add to the registry
     * @param _claimsManager The address of the vault's claims manager
     * @param _vaultParams The vault initialization parameters
     * @param _claimsManagerParams The vault's claims manager initialization parameters
     */
    event VaultCreated(
        address indexed _vault,
        address indexed _claimsManager,
        IHATVault.VaultInitParams _vaultParams,
        IHATClaimsManager.ClaimsManagerInitParams _claimsManagerParams
    );
    
    /** @notice Emitted when a swap of vault tokens to HAT tokens is done and
     * the HATS tokens are sent to beneficiary through vesting contract
     * @param _beneficiary Address of beneficiary
     * @param _amountSwapped Amount of vault's native tokens that was swapped
     * @param _amountSent Amount of HAT tokens sent to beneficiary
     * @param _tokenLock Address of the token lock contract that holds the HAT
     * tokens (address(0) if no token lock is used)
     */
    event SwapAndSend(
        address indexed _beneficiary,
        uint256 _amountSwapped,
        uint256 _amountSent,
        address indexed _tokenLock
    );

    /**
     * @notice Emitted when a new default HAT bounty split is set
     * @param _defaultBountyGovernanceHAT The new default HAT bounty part sent to governance
     * @param _defaultBountyHackerHATVested The new default HAT bounty part vseted for the hacker
     */
    event SetDefaultHATBountySplit(uint256 _defaultBountyGovernanceHAT, uint256 _defaultBountyHackerHATVested);

    /**
     * @notice Emitted when a new default arbitrator is set
     * @param _defaultArbitrator The address of the new arbitrator
     */
    event SetDefaultArbitrator(address indexed _defaultArbitrator);

    /**
     * @notice Emitted when a new default challenge period is set
     * @param _defaultChallengePeriod The new default challenge period
     */ 
    event SetDefaultChallengePeriod(uint256 _defaultChallengePeriod);

    /**
     * @notice Emitted when a new default challenge timeout period is set
     * @param _defaultChallengeTimeOutPeriod The new default challenge timeout
     * period
     */
    event SetDefaultChallengeTimeOutPeriod(uint256 _defaultChallengeTimeOutPeriod);

    /** @notice Emitted when the system is put into emergency pause/unpause
     * @param _isEmergencyPaused Is the system in an emergency pause
     */
    event SetEmergencyPaused(bool _isEmergencyPaused);

    /**
     * @notice Emitted when a new swap token is set
     * @param _swapToken The new swap token address
     */
    event SetSwapToken(address indexed _swapToken);

    /**
     * @notice Emitted when a new HATVault implementation is set
     * @param _hatVaultImplementation The address of the new HATVault implementation
     */
    event SetHATVaultImplementation(address indexed _hatVaultImplementation);

    /**
     * @notice Emitted when a new HATClaimsManager implementation is set
     * @param _hatClaimsManagerImplementation The address of the new HATClaimsManager implementation
     */
    event SetHATClaimsManagerImplementation(address indexed _hatClaimsManagerImplementation);

    /**
     * @notice Called by governance to pause/unpause the system in case of an
     * emergency
     * @param _isEmergencyPaused Is the system in an emergency pause
     */
    function setEmergencyPaused(bool _isEmergencyPaused) external;

    /**
     * @notice Called by governance to set a new swap token
     * @param _swapToken the new swap token address
     */
    function setSwapToken(address _swapToken) external;

    /**
     * @notice Called by governance to set a new HATVault and HATVault implementation to be
     * used by the registry for creating new vaults
     * @param _hatVaultImplementation The address of the HATVault implementation
     * @param _hatClaimsManagerImplementation The address of the HATClaimsManager implementation
     */
    function setVaultImplementations(address _hatVaultImplementation, address _hatClaimsManagerImplementation) external;

    /**
     * @notice Emit an event that includes the given _descriptionHash
     * This can be used by the claimer as evidence that she had access to the
     * information at the time of the call
     * if a {generalParameters.claimFee} > 0, the caller must send that amount
     * of ETH for the claim to succeed
     * @param _descriptionHash - a hash of an IPFS encrypted file which 
     * describes the claim.
     */
    function logClaim(string calldata _descriptionHash) external payable;

    /**
     * @notice Called by governance to set the default percentage of each claim bounty
     * that will be swapped for hats and sent to the governance or vested for the hacker
     * @param _defaultBountyGovernanceHAT The HAT bounty for governance
     * @param _defaultBountyHackerHATVested The HAT bounty vested for the hacker
     */
    function setDefaultHATBountySplit(
        uint16 _defaultBountyGovernanceHAT,
        uint16 _defaultBountyHackerHATVested
    ) 
        external;

    /** 
     * @dev Check that a given hats bounty split is legal, meaning that:
     *   Each entry is a number between 0 and less than `MAX_HAT_SPLIT`.
     *   Total splits should be less than `MAX_HAT_SPLIT`.
     * function will revert in case the bounty split is not legal.
     * @param _bountyGovernanceHAT The HAT bounty for governance
     * @param _bountyHackerHATVested The HAT bounty vested for the hacker
     */
    function validateHATSplit(uint16 _bountyGovernanceHAT, uint16 _bountyHackerHATVested)
         external
         pure;

    /**
     * @notice Called by governance to set the default arbitrator.
     * @param _defaultArbitrator The default arbitrator address
     */
    function setDefaultArbitrator(address _defaultArbitrator) external;

    /**
     * @notice Called by governance to set the default challenge period
     * @param _defaultChallengePeriod The default challenge period
     */
    function setDefaultChallengePeriod(uint32 _defaultChallengePeriod) 
        external;

    /**
     * @notice Called by governance to set the default challenge timeout
     * @param _defaultChallengeTimeOutPeriod The Default challenge timeout
     */
    function setDefaultChallengeTimeOutPeriod(
        uint32 _defaultChallengeTimeOutPeriod
    ) 
        external;

    /**
     * @notice Check that the given challenge period is legal, meaning that it
     * is greater than 1 day and less than 5 days.
     * @param _challengePeriod The challenge period to check
     */
    function validateChallengePeriod(uint32 _challengePeriod) external pure;

    /**
     * @notice Check that the given challenge timeout period is legal, meaning
     * that it is greater than 2 days and less than 125 days.
     * @param _challengeTimeOutPeriod The challenge timeout period to check
     */
    function validateChallengeTimeOutPeriod(uint32 _challengeTimeOutPeriod) external pure;
   
    /**
     * @notice Called by governance to set the fee setter role
     * @param _feeSetter Address of new fee setter
     */
    function setFeeSetter(address _feeSetter) external;

    /**
     * @notice Called by governance to set time limits for withdraw requests
     * @param _withdrawRequestPendingPeriod Time period where the withdraw
     * request is pending
     * @param _withdrawRequestEnablePeriod Time period after the peding period
     * has ended during which withdrawal is enabled
     */
    function setWithdrawRequestParams(
        uint32 _withdrawRequestPendingPeriod,
        uint32  _withdrawRequestEnablePeriod
    )
        external;

    /**
     * @notice Called by governance to set the fee for logging a claim for a
     * bounty in any vault.
     * @param _fee Claim fee in ETH to be transferred on any call of
     * {logClaim}
     */
    function setClaimFee(uint256 _fee) external;

    /**
     * @notice Called by governance to set the withdraw period and safety
     * period, which are always interchanging.
     * The safety period is time that the committee can submit claims for 
     * bounty payouts, and during which withdrawals are disabled and the
     * bounty split cannot be changed.
     * @param _withdrawPeriod Amount of time during which withdrawals are
     * enabled, and the bounty split can be changed by the governance. Must be
     * at least 1 hour.
     * @param _safetyPeriod Amount of time during which claims for bounties 
     * can be submitted and withdrawals are disabled. Must be at most 6 hours.
     */
    function setWithdrawSafetyPeriod(
        uint32 _withdrawPeriod,
        uint32 _safetyPeriod
    ) 
        external;

    /**
     * @notice Called by governance to set vesting params for rewarding hackers
     * with rewardToken, for all vaults
     * @param _duration Duration of the vesting period. Must be less than 180
     * days.
     * @param _periods The number of vesting periods. Must be more than 0 and 
     * less then the vesting duration.
     */
    function setHatVestingParams(uint32 _duration, uint32 _periods) external;

    /**
     * @notice Called by governance to set the timelock delay for setting the
     * max bounty (the time between setPendingMaxBounty and setMaxBounty)
     * @param _delay The time period for the delay. Must be at least 2 days.
     */
    function setMaxBountyDelay(uint32 _delay) external;

    /**
     * @notice Create a new vault
     * NOTE: Vaults should not use tokens which do not guarantee that the 
     * amount specified is the amount transferred
     * @param _vaultParams The vault initialization parameters
     * @param _vaultParams The vault token initialization parameters
     * @return vault The address of the new vault
     */
    function createVault(
        IHATVault.VaultInitParams calldata _vaultParams,
        IHATClaimsManager.ClaimsManagerInitParams calldata _claimsManagerParams
    ) external returns(address vault, address vaultClaimsManager);

    /**
     * @notice Called by governance to change the UI visibility of a vault
     * @param _vault The address of the vault to update
     * @param _visible Is this vault visible in the UI
     * This parameter can be used by the UI to include or exclude the vault
     */
    function setVaultVisibility(address _vault, bool _visible) external;

    /**
     * @notice Transfer the part of the bounty that is supposed to be swapped
     * into HAT tokens from the HATVault to the registry, and keep track of
     * the amounts to be swapped and sent/burnt in a later transaction
     * @param _asset The vault's native token
     * @param _hacker The address of the beneficiary of the bounty
     * @param _hackersHatReward The amount of the vault's native token to be
     * swapped to HAT tokens and sent to the hacker via a vesting contract
     * @param _governanceHatReward The amount of the vault's native token to
     * be swapped to HAT tokens and sent to governance
     */
    function addTokensToSwap(
        IERC20 _asset,
        address _hacker,
        uint256 _hackersHatReward,
        uint256 _governanceHatReward
    ) external;

    /**
     * @notice Called by governance to swap the given asset to HAT tokens and 
     * distribute the HAT tokens: Send to governance their share and send to
     * beneficiaries their share through a vesting contract.
     * @param _asset The address of the token to be swapped to HAT tokens
     * @param _beneficiaries Addresses of beneficiaries
     * @param _amountOutMinimum Minimum amount of HAT tokens at swap
     * @param _routingContract Routing contract to call for the swap
     * @param _routingPayload Payload to send to the _routingContract for the
     * swap
     */
    function swapAndSend(
        address _asset,
        address[] calldata _beneficiaries,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload
    ) external;
  
    /**
     * @notice Returns the withdraw enable period for all vaults. The safety
     * period starts when finished.
     * @return Withdraw enable period for all vaults
     */
    function getWithdrawPeriod() external view returns (uint256);

    /**
     * @notice Returns the withdraw disable period - time for the committee to
     * gather and decide on actions, withdrawals are not possible in this
     * time. The withdraw period starts when finished.
     * @return Safety period for all vaults
     */
    function getSafetyPeriod() external view returns (uint256);

    /**
     * @notice Returns the withdraw request enable period for all vaults -
     * period of time after withdrawRequestPendingPeriod where it is possible
     * to withdraw, and after which withdrawals are not possible.
     * @return Withdraw request enable period for all vaults
     */
    function getWithdrawRequestEnablePeriod() external view returns (uint256);

    /**
     * @notice Returns the withdraw request pending period for all vaults -
     * period of time that has to pass after withdraw request until withdraw
     * is possible
     * @return Withdraw request pending period for all vaults
     */
    function getWithdrawRequestPendingPeriod() external view returns (uint256);

    /**
     * @notice Returns the set max bounty delay for all vaults - period of
     * time that has to pass after setting a pending max bounty before it can
     * be set as the new max bounty
     * @return Set max bounty delay for all vaults
     */
    function getSetMaxBountyDelay() external view returns (uint256);

    /**
     * @notice Returns the number of vaults that have been previously created
     * @return The number of vaults in the registry
     */
    function getNumberOfVaults() external view returns(uint256);

    /**
     * @notice Get the fee setter address
     * @return The address of the fee setter
     */
    function feeSetter() external view returns(address);

    /**
     * @notice Get whether the system is in an emergency pause
     * @return Whether the system is in an emergency pause
     */
    function isEmergencyPaused() external view returns(bool);

    /**
     * @notice Get the owner address
     * @return The address of the owner
     */
    function owner() external view returns(address);

    /**
     * @notice Get the default percentage of the total bounty to be swapped to HATs and sent to governance
     * @return The default percentage of the total bounty to be swapped to HATs and sent to governance
     */
    function defaultBountyGovernanceHAT() external view returns(uint16);

    /**
     * @notice Get the default percentage of the total bounty to be swapped to HATs and sent to the hacker via vesting contract
     * @return The default percentage of the total bounty to be swapped to HATs and sent to the hacker via vesting contract
     */
    function defaultBountyHackerHATVested() external view returns(uint16);

    /**
     * @notice Get the default arbitrator address
     * @return The default arbitrator address
     */
    function defaultArbitrator() external view returns(address);

    /**
     * @notice Get the default challenge period
     * @return The default challenge period
     */
    function defaultChallengePeriod() external view returns(uint32);

    /**
     * @notice Get the default challenge time out period
     * @return The default challenge time out period
     */
    function defaultChallengeTimeOutPeriod() external view returns(uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardController {
    
    error EpochLengthZero();
    // Not enough rewards to transfer to user
    error NotEnoughRewardsToTransferToUser();

    event RewardControllerCreated(
        address _rewardToken,
        address _governance,
        uint256 _startBlock,
        uint256 _epochLength,
        uint256[24] _epochRewardPerBlock
    );
    event SetEpochRewardPerBlock(uint256[24] _epochRewardPerBlock);
    event SetAllocPoint(address indexed _vault, uint256 _prevAllocPoint, uint256 _allocPoint);
    event VaultUpdated(address indexed _vault, uint256 _rewardPerShare, uint256 _lastProcessedVaultUpdate);
    event UserBalanceCommitted(address indexed _vault, address indexed _user, uint256 _unclaimedReward, uint256 _rewardDebt);
    event ClaimReward(address indexed _vault, address indexed _user, uint256 _amount);

    /**
     * @notice Initializes the reward controller
     * @param _rewardToken The address of the ERC20 token to be distributed as rewards
     * @param _governance The hats governance address, to be given ownership of the reward controller
     * @param _startRewardingBlock The block number from which to start rewarding
     * @param _epochLength The length of a rewarding epoch
     * @param _epochRewardPerBlock The reward per block for each of the 24 epochs
     */
    function initialize(
        address _rewardToken,
        address _governance,
        uint256 _startRewardingBlock,
        uint256 _epochLength,
        uint256[24] calldata _epochRewardPerBlock
    ) external;

    /**
     * @notice Called by the owner to set the allocation points for a vault, meaning the
     * vault's relative share of the total rewards
     * @param _vault The address of the vault
     * @param _allocPoint The allocation points for the vault
     */
    function setAllocPoint(address _vault, uint256 _allocPoint) external;

    /**
    * @notice Update the vault's reward per share, not more then once per block
    * @param _vault The vault's address
    */
    function updateVault(address _vault) external;

    /**
    * @notice Called by the owner to set reward per epoch
    * Reward can only be set for epochs which have not yet started
    * @param _epochRewardPerBlock reward per block for each epoch
    */
    function setEpochRewardPerBlock(uint256[24] calldata _epochRewardPerBlock) external;

    /**
    * @notice Called by the vault to update a user claimable reward after deposit or withdraw.
    * This call should never revert.
    * @param _user The user address to updare rewards for
    * @param _sharesChange The user of shared the user deposited or withdrew
    * @param _isDeposit Whether user deposited or withdrew
    */
    function commitUserBalance(address _user, uint256 _sharesChange, bool _isDeposit) external;
    /**
    * @notice Transfer to the specified user their pending share of rewards.
    * @param _vault The vault address
    * @param _user The user address to claim for
    */
    function claimReward(address _vault, address _user) external;

    /**
    * @notice Calculate rewards for a vault by iterating over the history of totalAllocPoints updates,
    * and sum up all rewards periods from vault.lastRewardBlock until current block number.
    * @param _vault The vault address
    * @param _fromBlock The block from which to start calculation
    * @return reward The amount of rewards for the vault
    */
    function getVaultReward(address _vault, uint256 _fromBlock) external view returns(uint256 reward);

    /**
    * @notice Calculate the amount of rewards a user can claim for having contributed to a specific vault
    * @param _vault The vault address
    * @param _user The user for which the reward is calculated
    */
    function getPendingReward(address _vault, address _user) external view returns (uint256);

    /**
    * @notice Called by the owner to transfer any tokens held in this contract to the owner
    * @param _token The token to sweep
    * @param _amount The amount of token to sweep
    */
    function sweepToken(IERC20Upgradeable _token, uint256 _amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenLock {

    // -- Value Transfer --

    function release() external;

    function withdrawSurplus(uint256 _amount) external;

    function sweepToken(IERC20 _token) external;

    function revoke() external;

    // -- Balances --

    function currentBalance() external view returns (uint256);

    // -- Time & Periods --

    function currentTime() external view returns (uint256);

    function duration() external view returns (uint256);

    function sinceStartTime() external view returns (uint256);

    function amountPerPeriod() external view returns (uint256);

    function periodDuration() external view returns (uint256);

    function currentPeriod() external view returns (uint256);

    function passedPeriods() external view returns (uint256);

    // -- Locking & Release Schedule --

    function availableAmount() external view returns (uint256);

    function vestedAmount() external view returns (uint256);

    function releasableAmount() external view returns (uint256);

    function totalOutstandingAmount() external view returns (uint256);

    function surplusAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ITokenLock.sol";

interface ITokenLockFactory {
    // -- Factory --
    function setMasterCopy(address _masterCopy) external;

    function createTokenLock(
        address _token,
        address _owner,
        address _beneficiary,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        bool _revocable,
        bool _canDelegate
    ) external returns(address contractAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ITokenLockFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title TokenLockFactory
 *  a factory of TokenLock contracts.
 *
 * This contract receives funds to make the process of creating TokenLock contracts
 * easier by distributing them the initial tokens to be managed.
 */
contract TokenLockFactory is ITokenLockFactory, Ownable {
    // -- Errors --

    error MasterCopyCannotBeZero();

    // -- State --

    address public masterCopy;
    mapping(address => uint256) public nonce;

    // -- Events --

    event MasterCopyUpdated(address indexed masterCopy);

    event TokenLockCreated(
        address indexed contractAddress,
        bytes32 indexed initHash,
        address indexed beneficiary,
        address token,
        uint256 managedAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 periods,
        uint256 releaseStartTime,
        uint256 vestingCliffTime,
        bool revocable,
        bool canDelegate
    );

    /**
     * Constructor.
     * @param _masterCopy Address of the master copy to use to clone proxies
     * @param _governance Owner of the factory
     */
    constructor(address _masterCopy, address _governance) {
        _setMasterCopy(_masterCopy);
        _transferOwnership(_governance);
    }

    // -- Factory --
    /**
     * @notice Creates and fund a new token lock wallet using a minimum proxy
     * @param _token token to time lock
     * @param _owner Address of the contract owner
     * @param _beneficiary Address of the beneficiary of locked tokens
     * @param _managedAmount Amount of tokens to be managed by the lock contract
     * @param _startTime Start time of the release schedule
     * @param _endTime End time of the release schedule
     * @param _periods Number of periods between start time and end time
     * @param _releaseStartTime Override time for when the releases start
     * @param _revocable Whether the contract is revocable
     * @param _canDelegate Whether the contract should call delegate
     */
    function createTokenLock(
        address _token,
        address _owner,
        address _beneficiary,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        bool _revocable,
        bool _canDelegate
    ) external override returns(address contractAddress) {
        // Create contract using a minimal proxy and call initializer
        bytes memory initializer = abi.encodeWithSignature(
            "initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool)",
            _owner,
            _beneficiary,
            _token,
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable,
            _canDelegate
        );

        contractAddress = _deployProxyPrivate(initializer,
        _beneficiary,
        _token,
        _managedAmount,
        _startTime,
        _endTime,
        _periods,
        _releaseStartTime,
        _vestingCliffTime,
        _revocable,
        _canDelegate);
    }

    /**
     * @notice Sets the masterCopy bytecode to use to create clones of TokenLock contracts
     * @param _masterCopy Address of contract bytecode to factory clone
     */
    function setMasterCopy(address _masterCopy) external override onlyOwner {
        _setMasterCopy(_masterCopy);
    }

    function _setMasterCopy(address _masterCopy) internal {
        if (_masterCopy == address(0))
            revert MasterCopyCannotBeZero();
        masterCopy = _masterCopy;
        emit MasterCopyUpdated(_masterCopy);
    }

    // This private function is to handle stack too deep issue
    function _deployProxyPrivate(
        bytes memory _initializer,
        address _beneficiary,
        address _token,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        bool _revocable,
        bool _canDelegate
    ) private returns (address contractAddress) {

        contractAddress = Clones.cloneDeterministic(masterCopy, keccak256(abi.encodePacked(msg.sender, nonce[msg.sender]++, _initializer)));

        Address.functionCall(contractAddress, _initializer);

        emit TokenLockCreated(
            contractAddress,
            keccak256(_initializer),
            _beneficiary,
            _token,
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable,
            _canDelegate
        );
    }
}