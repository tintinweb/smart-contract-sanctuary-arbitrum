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
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IHATClaimsManager.sol";

contract HATGovernanceArbitrator is Ownable {

    function approveClaim(IHATClaimsManager _vault, bytes32 _claimId) external onlyOwner {
        _vault.challengeClaim(_claimId);
        _vault.approveClaim(_claimId, 0, address(0));
    }

    function dismissClaim(IHATClaimsManager _vault, bytes32 _claimId) external onlyOwner {
        _vault.challengeClaim(_claimId);
        _vault.dismissClaim(_claimId);
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