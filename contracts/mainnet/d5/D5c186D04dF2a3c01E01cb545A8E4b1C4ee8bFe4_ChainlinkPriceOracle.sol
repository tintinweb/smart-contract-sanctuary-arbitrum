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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
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
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
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
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
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
   **/
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
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title IAccessManager - Interface for the contract that handles roles for the PolicyPool and components
 * @dev Interface for the contract that handles roles for the PolicyPool and components
 * @author Ensuro
 */
interface IAccessManager is IAccessControlUpgradeable {
  /**
   * @dev Enum with the different governance actions supported in the protocol.
   *      It's good to keep actions of the same component consecutive, parts of the code relay on that,
   *      so we put some fillers in case new actions are added.
   */
  enum GovernanceActions {
    none,
    setTreasury, // Changes PolicyPool treasury address
    setAssetManager, // Change in the asset manager strategy of a reserve
    setAssetManagerForced, // Change in the asset manager strategy of a reserve, forced (deinvest failed)
    setBaseURI, // Change in the base URI for policy NFTs
    ppFiller2, // Reserve space for future PolicyPool or AccessManager actions
    ppFiller3, // Reserve space for future PolicyPool or AccessManager actions
    ppFiller4, // Reserve space for future PolicyPool or AccessManager actions
    // RiskModule Governance Actions
    setMoc,
    setJrCollRatio,
    setCollRatio,
    setEnsuroPpFee,
    setEnsuroCocFee,
    setJrRoc,
    setSrRoc,
    setMaxPayoutPerPolicy,
    setExposureLimit,
    setMaxDuration,
    setWallet,
    rmFiller1, // Reserve space for future RM actions
    rmFiller2, // Reserve space for future RM actions
    rmFiller3, // Reserve space for future RM actions
    rmFiller4, // Reserve space for future RM actions
    // EToken Governance Actions
    setLPWhitelist, // Changes EToken Liquidity Providers Whitelist
    setLiquidityRequirement,
    setMinUtilizationRate,
    setMaxUtilizationRate,
    setInternalLoanInterestRate,
    etkFiller1, // Reserve space for future EToken actions
    etkFiller2, // Reserve space for future EToken actions
    etkFiller3, // Reserve space for future EToken actions
    etkFiller4, // Reserve space for future EToken actions
    // PremiumsAccount Governance Actions
    setDeficitRatio,
    setDeficitRatioWithAdjustment,
    setJrLoanLimit,
    setSrLoanLimit,
    paFiller3, // Reserve space for future PremiumsAccount actions
    paFiller4, // Reserve space for future PremiumsAccount actions
    // AssetManager Governance Actions
    setLiquidityMin,
    setLiquidityMiddle,
    setLiquidityMax,
    amFiller1, // Reserve space for future Asset Manager actions
    amFiller2, // Reserve space for future Asset Manager actions
    amFiller3, // Reserve space for future Asset Manager actions
    amFiller4, // Reserve space for future Asset Manager actions
    last
  }

  /**
   * @dev Gets a role identifier mixing the hash of the global role and the address of the component
   *
   * @param component The component where this role will apply
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @return A new role, mixing (XOR) the component address and the role.
   */
  function getComponentRole(address component, bytes32 role) external view returns (bytes32);

  /**
   * @dev Tells if a user has been granted a given role for a component
   *
   * @param component The component where this role will apply
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   * @param alsoGlobal If true, it will return if the users has either the component role, or the role itself.
   *                   If false, only the component role is accepted
   * @return Whether the user has or not any of the roles
   */
  function hasComponentRole(
    address component,
    bytes32 role,
    address account,
    bool alsoGlobal
  ) external view returns (bool);

  /**
   * @dev Checks if a user has been granted a given role and reverts if it doesn't
   *
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   */
  function checkRole(bytes32 role, address account) external view;

  /**
   * @dev Checks if a user has been granted any of the two roles specified and reverts if it doesn't
   *
   * @param role1 A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param role2 Another role such as `keccak256("GUARDIAN_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   */
  function checkRole2(
    bytes32 role1,
    bytes32 role2,
    address account
  ) external view;

  /**
   * @dev Checks if a user has been granted a given component role and reverts if it doesn't
   *
   * @param role A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   * @param alsoGlobal If true, it will accept not only the component role, but also the (global) `role` itself.
   *                   If false, only the component role is accepted
   */
  function checkComponentRole(
    address component,
    bytes32 role,
    address account,
    bool alsoGlobal
  ) external view;

  /**
   * @dev Checks if a user has been granted any of the two component roles specified and reverts if it doesn't
   *
   * @param role1 A role such as `keccak256("LEVEL1_ROLE")` that's global
   * @param role2 Another role such as `keccak256("GUARDIAN_ROLE")` that's global
   * @param account The user address for who we want to verify the permission
   * @param alsoGlobal If true, it will accept not only the component roles, but also the global ones.
   *                   If false, only the component roles are accepted
   */
  function checkComponentRole2(
    address component,
    bytes32 role1,
    bytes32 role2,
    address account,
    bool alsoGlobal
  ) external view;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IEToken interface
 * @dev Interface for EToken smart contracts, these are the capital pools.
 * @author Ensuro
 */
interface IEToken is IERC20 {
  /**
   * @dev Enum of the different parameters that are configurable in an EToken.
   */
  enum Parameter {
    liquidityRequirement,
    minUtilizationRate,
    maxUtilizationRate,
    internalLoanInterestRate
  }

  /**
   * @dev Event emitted when part of the funds of the eToken are locked as solvency capital.
   * @param interestRate The annualized interestRate paid for the capital (wad)
   * @param value The amount locked
   */
  event SCRLocked(uint256 interestRate, uint256 value);

  /**
   * @dev Event emitted when the locked funds are unlocked and no longer used as solvency capital.
   * @param interestRate The annualized interestRate that was paid for the capital (wad)
   * @param value The amount unlocked
   */
  event SCRUnlocked(uint256 interestRate, uint256 value);

  /**
   * @dev Returns the amount of capital that's locked as solvency capital for active policies.
   */
  function scr() external view returns (uint256);

  /**
   * @dev Locks part of the liquidity of the EToken as solvency capital.
   *
   * Requirements:
   * - Must be called by a _borrower_ previously added with `addBorrower`.
   * - `scrAmount` <= `fundsAvailableToLock()`
   *
   * Events:
   * - Emits {SCRLocked}
   *
   * @param scrAmount The amount to lock
   * @param policyInterestRate The annualized interest rate (wad) to be paid for the `scrAmount`
   */
  function lockScr(uint256 scrAmount, uint256 policyInterestRate) external;

  /**
   * @dev Unlocks solvency capital previously locked with `lockScr`. The capital no longer needed as solvency.
   *
   * Requirements:
   * - Must be called by a _borrower_ previously added with `addBorrower`.
   * - `scrAmount` <= `scr()`
   *
   * Events:
   * - Emits {SCRUnlocked}
   *
   * @param scrAmount The amount to unlock
   * @param policyInterestRate The annualized interest rate that was paid for the `scrAmount`, must be the same that was
   * sent in `lockScr` call.
   */
  function unlockScr(
    uint256 scrAmount,
    uint256 policyInterestRate,
    int256 adjustment
  ) external;

  /**
   * @dev Registers a deposit of liquidity in the pool. Called from the PolicyPool, assumes the amount has already been
   * transferred. `amount` of eToken are minted and given to the provider in exchange of the liquidity provided.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   * - The amount was transferred
   * - `utilizationRate()` after the deposit is >= `minUtilizationRate()`
   *
   * Events:
   * - Emits {Transfer} with `from` = 0x0 and to = `provider`
   *
   * @param provider The address of the liquidity provider
   * @param amount The amount deposited.
   * @return The actual balance of the provider
   */
  function deposit(address provider, uint256 amount) external returns (uint256);

  /**
   * @dev Withdraws an amount from an eToken. `withdrawn` eTokens are be burned and the user receives the same amount
   * in `currency()`. If the asked `amount` can't be withdrawn, it withdraws as much as possible
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - Emits {Transfer} with `from` = `provider` and to = `0x0`
   *
   * @param provider The address of the liquidity provider
   * @param amount The amount to withdraw. If `amount` == `type(uint256).max`, then tries to withdraw all the balance.
   * @return withdrawn The actual amount that withdrawn. `withdrawn <= amount && withdrawn <= balanceOf(provider)`
   */
  function withdraw(address provider, uint256 amount) external returns (uint256 withdrawn);

  /**
   * @dev Returns the total amount that can be withdrawn
   */
  function totalWithdrawable() external view returns (uint256);

  /**
   * @dev Adds an authorized _borrower_ to the eToken. This _borrower_ will be allowed to lock/unlock funds and to take
   * loans.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - Emits {InternalBorrowerAdded}
   *
   * @param borrower The address of the _borrower_, a PremiumsAccount that has this eToken as senior or junior eToken.
   */
  function addBorrower(address borrower) external;

  /**
   * @dev Removes an authorized _borrower_ to the eToken. The _borrower_ can't no longer lock funds or take loans.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - Emits {InternalBorrowerRemoved} with the defaulted debt
   *
   * @param borrower The address of the _borrower_, a PremiumsAccount that has this eToken as senior or junior eToken.
   */
  function removeBorrower(address borrower) external;

  /**
   * @dev Lends `amount` to the borrower (msg.sender), transferring the money to `receiver`. This reduces the
   * `totalSupply()` of the eToken, and stores a debt that will be repaid (hopefully) with `repayLoan`.
   *
   * Requirements:
   * - Must be called by a _borrower_ previously added with `addBorrower`.
   *
   * Events:
   * - Emits {InternalLoan}
   * - Emits {ERC20-Transfer} transferring `lent` to `receiver`
   *
   * @param amount The amount required
   * @param receiver The received of the funds lent. This is usually the policyholder if the loan is used for a payout.
   * @return Returns the amount that wasn't able to fulfil. `amount - lent`
   */
  function internalLoan(uint256 amount, address receiver) external returns (uint256);

  /**
   * @dev Repays a loan taken with `internalLoan`.
   *
   * Requirements:
   * - `msg.sender` approved the spending of `currency()` for at least `amount`

   * Events:
   * - Emits {InternalLoanRepaid}
   * - Emits {ERC20-Transfer} transferring `amount` from `msg.sender` to `this`
   *
   * @param amount The amount to repaid, that will be transferred from `msg.sender` balance.
   * @param onBehalfOf The address of the borrower that took the loan. Usually `onBehalfOf == msg.sender` but we keep it
   * open because in some cases with might need someone else pays the debt.
   */
  function repayLoan(uint256 amount, address onBehalfOf) external;

  /**
   * @dev Returns the updated debt (principal + interest) of the `borrower`.
   */
  function getLoan(address borrower) external view returns (uint256);

  /**
   * @dev The annualized interest rate at which the `totalSupply()` grows
   */
  function tokenInterestRate() external view returns (uint256);

  /**
   * @dev The weighted average annualized interest rate paid by the currently locked `scr()`.
   */
  function scrInterestRate() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Policy} from "../Policy.sol";
import {IEToken} from "./IEToken.sol";
import {IAccessManager} from "./IAccessManager.sol";

interface IPolicyPool {
  /**
   * @dev Reference to the main currency (ERC20) used in the protocol
   * @return The address of the currency (e.g. USDC) token used in the protocol
   */
  function currency() external view returns (IERC20Metadata);

  /**
   * @dev Reference to the {AccessManager} contract, this contract manages the access controls.
   * @return The address of the AccessManager contract
   */
  function access() external view returns (IAccessManager);

  /**
   * @dev Address of the treasury, that receives protocol fees.
   * @return The address of the treasury
   */
  function treasury() external view returns (address);

  /**
   * @dev Creates a new Policy. Must be called from an active RiskModule
   *
   * Requirements:
   * - `msg.sender` must be an active RiskModule
   * - `caller` approved the spending of `currency()` for at least `policy.premium`
   * - `internalId` must be unique within `policy.riskModule` and not used before
   *
   * Events:
   * - {PolicyPool-NewPolicy}: with all the details about the policy
   * - {ERC20-Transfer}: does several transfers from caller address to the different receivers of the premium
   * (see Premium Split in the docs)
   *
   * @param policy A policy created with {Policy-initialize}
   * @param caller The pricer that's creating the policy and will pay for the premium
   * @param policyHolder The address of the policy holder and the payer of the premiums
   * @param internalId A unique id within the RiskModule, that will be used to compute the policy id
   * @return The policy id, identifying the NFT and the policy
   */
  function newPolicy(
    Policy.PolicyData memory policy,
    address caller,
    address policyHolder,
    uint96 internalId
  ) external returns (uint256);

  /**
   * @dev Resolves a policy with a payout. Must be called from an active RiskModule
   *
   * Requirements:
   * - `policy`: must be a Policy previously created with `newPolicy` (checked with `policy.hash()`) and not
   *   resolved before and not expired (if payout > 0).
   * - `payout`: must be less than equal to `policy.payout`.
   *
   * Events:
   * - {PolicyPool-PolicyResolved}: with the payout
   * - {ERC20-Transfer}: to the policyholder with the payout
   *
   * @param policy A policy previously created with `newPolicy`
   * @param payout The amount to paid to the policyholder
   */
  function resolvePolicy(Policy.PolicyData calldata policy, uint256 payout) external;

  /**
   * @dev Resolves a policy with a payout that can be either 0 or the maximum payout of the policy
   *
   * Requirements:
   * - `policy`: must be a Policy previously created with `newPolicy` (checked with `policy.hash()`) and not
   *   resolved before and not expired (if customerWon).
   *
   * Events:
   * - {PolicyPool-PolicyResolved}: with the payout
   * - {ERC20-Transfer}: to the policyholder with the payout
   *
   * @param policy A policy previously created with `newPolicy`
   * @param customerWon Indicated if the payout is zero or the maximum payout
   */
  function resolvePolicyFullPayout(Policy.PolicyData calldata policy, bool customerWon) external;

  /**
   * @dev Resolves a policy with a payout 0, unlocking the solvency. Can be called by anyone, but only after
   * `Policy.expiration`.
   *
   * Requirements:
   * - `policy`: must be a Policy previously created with `newPolicy` (checked with `policy.hash()`) and not resolved
   * before
   * - Policy expired: `Policy.expiration` <= block.timestamp
   *
   * Events:
   * - {PolicyPool-PolicyResolved}: with payout == 0
   *
   * @param policy A policy previously created with `newPolicy`
   */
  function expirePolicy(Policy.PolicyData calldata policy) external;

  /**
   * @dev Returns whether a policy is active, i.e., it's still in the PolicyPool, not yet resolved or expired.
   *      Be aware that a policy might be active but the `block.timestamp` might be after the expiration date, so it
   *      can't be triggered with a payout.
   *
   * @param policyId The id of the policy queried
   * @return Whether the policy is active or not
   */
  function isActive(uint256 policyId) external view returns (bool);

  /**
   * @dev Returns the stored hash of the policy. It's `bytes32(0)` is the policy isn't active.
   *
   * @param policyId The id of the policy queried
   * @return Returns the hash of a given policy id
   */
  function getPolicyHash(uint256 policyId) external view returns (bytes32);

  /**
   * @dev Deposits liquidity into an eToken. Forwards the call to {EToken-deposit}, after transferring the funds.
   * The user will receive etokens for the same amount deposited.
   *
   * Requirements:
   * - `msg.sender` approved the spending of `currency()` for at least `amount`
   * - `eToken` is an active eToken installed in the pool.
   *
   * Events:
   * - {EToken-Transfer}: from 0x0 to `msg.sender`, reflects the eTokens minted.
   * - {ERC20-Transfer}: from `msg.sender` to address(eToken)
   *
   * @param eToken The address of the eToken to which the user wants to provide liquidity
   * @param amount The amount to deposit
   */
  function deposit(IEToken eToken, uint256 amount) external;

  /**
   * @dev Withdraws an amount from an eToken. Forwards the call to {EToken-withdraw}.
   * `amount` of eTokens will be burned and the user will receive the same amount in `currency()`.
   *
   * Requirements:
   * - `eToken` is an active (or deprecated) eToken installed in the pool.
   *
   * Events:
   * - {EToken-Transfer}: from `msg.sender` to `0x0`, reflects the eTokens burned.
   * - {ERC20-Transfer}: from address(eToken) to `msg.sender`
   *
   * @param eToken The address of the eToken from where the user wants to withdraw liquidity
   * @param amount The amount to withdraw. If equal to type(uint256).max, means full withdrawal.
   *               If the balance is not enough or can't be withdrawn (locked as SCR), it withdraws
   *               as much as it can, but doesn't fails.
   * @return Returns the actual amount withdrawn.
   */
  function withdraw(IEToken eToken, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IPolicyPool} from "./IPolicyPool.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IPolicyPoolComponent interface
 * @dev Interface for Contracts linked (owned) by a PolicyPool. Useful to avoid cyclic dependencies
 * @author Ensuro
 */
interface IPolicyPoolComponent is IERC165 {
  /**
   * @dev Returns the address of the PolicyPool (see {PolicyPool}) where this component belongs.
   */
  function policyPool() external view returns (IPolicyPool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IEToken} from "./IEToken.sol";
import {Policy} from "../Policy.sol";

/**
 * @title IPremiumsAccount interface
 * @dev Interface for Premiums Account contracts.
 * @author Ensuro
 */
interface IPremiumsAccount {
  /**
   * @dev Adds a policy to the PremiumsAccount. Stores the pure premiums and locks the aditional funds from junior and
   * senior eTokens.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - {EToken-SCRLocked}
   *
   * @param policy The policy to add (created in this transaction)
   */
  function policyCreated(Policy.PolicyData memory policy) external;

  /**
   * @dev The PremiumsAccount is notified that the policy was resolved and issues the payout to the policyHolder.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - {ERC20-Transfer}: `to == policyHolder`, `amount == payout`
   * - {EToken-InternalLoan}: optional, if a loan needs to be taken
   * - {EToken-SCRUnlocked}
   *
   * @param policyHolder The one that will receive the payout
   * @param policy The policy that was resolved
   * @param payout The amount that has to be transferred to `policyHolder`
   */
  function policyResolvedWithPayout(
    address policyHolder,
    Policy.PolicyData memory policy,
    uint256 payout
  ) external;

  /**
   * @dev The PremiumsAccount is notified that the policy has expired, unlocks the SCR and earns the pure premium.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * Events:
   * - {ERC20-Transfer}: `to == policyHolder`, `amount == payout`
   * - {EToken-InternalLoanRepaid}: optional, if a loan was taken before
   *
   * @param policy The policy that has expired
   */
  function policyExpired(Policy.PolicyData memory policy) external;

  /**
   * @dev The senior eToken, the secondary source of solvency, used if the premiums account is exhausted and junior too
   */
  function seniorEtk() external view returns (IEToken);

  /**
   * @dev The junior eToken, the primary source of solvency, used if the premiums account is exhausted.
   */
  function juniorEtk() external view returns (IEToken);

  /**
   * @dev The total amount of premiums hold by this PremiumsAccount
   */
  function purePremiums() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IPremiumsAccount} from "./IPremiumsAccount.sol";

/**
 * @title IRiskModule interface
 * @dev Interface for RiskModule smart contracts. Gives access to RiskModule configuration parameters
 * @author Ensuro
 */
interface IRiskModule {
  /**
   * @dev Enum with the different parameters of the risk module, used in {RiskModule-setParam}.
   */
  enum Parameter {
    moc,
    jrCollRatio,
    collRatio,
    ensuroPpFee,
    ensuroCocFee,
    jrRoc,
    srRoc,
    maxPayoutPerPolicy,
    exposureLimit,
    maxDuration
  }

  /**
   * Struct of the parameters of the risk module that are used to calculate the different Policy fields (see
   * {Policy-PolicyData}.
   */
  struct Params {
    /**
     * @dev MoC (Margin of Conservativism) is a factor that multiplies the lossProb to increase or decrease the pure
     * premium.
     */
    uint256 moc;
    /**
     * @dev Junior Collateralization Ratio is the percentage of policy exposure (payout) that will be covered with the
     * purePremium and the Junior EToken
     */
    uint256 jrCollRatio;
    /**
     * @dev Collateralization Ratio is the percentage of policy exposure (payout) that will be covered by the
     * purePremium and the Junior and Senior EToken. Usually is calculated as the relation between VAR99.5% and VAR100
     * (full collateralization).
     */
    uint256 collRatio;
    /**
     * @dev Ensuro PurePremium Fee is the percentage that will be multiplied by the pure premium to obtain the part of
     * the Ensuro Fee that's proportional to the pure premium.
     */
    uint256 ensuroPpFee;
    /**
     * @dev Ensuro Cost of Capital Fee is the percentage that will be multiplied by the cost of capital (CoC) to
     * obtain the part of the Ensuro Fee that's proportional to the CoC.
     */
    uint256 ensuroCocFee;
    /**
     * @dev Junior Return on Capital is the annualized interest rate that's charged for the capital locked in the Junior
     * EToken.
     */
    uint256 jrRoc;
    /**
     * @dev Senior Return on Capital is the annualized interest rate that's charged for the capital locked in the Senior
     * EToken.
     */
    uint256 srRoc;
  }

  /**
   * @dev A readable name of this risk module. Never changes.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns different parameters of the risk module (see {Params})
   */
  function params() external view returns (Params memory);

  /**
   * @dev Returns the maximum duration (in hours) of the policies of this risk module.
   *      The `expiration` of the policies has to be `<= (block.timestamp + 3600 * maxDuration())`
   */
  function maxDuration() external view returns (uint256);

  /**
   * @dev Returns the maximum payout accepted for new policies.
   */
  function maxPayoutPerPolicy() external view returns (uint256);

  /**
   * @dev Returns sum of the (maximum) payout of the active policies of this risk module, i.e. the maximum possible
   * amount of money that's exposed for this risk module.
   */
  function activeExposure() external view returns (uint256);

  /**
   * @dev Returns maximum exposure (sum of the (maximum) payout of the active policies) of this risk module.
   * `activeExposure() <= exposureLimit()` always
   */
  function exposureLimit() external view returns (uint256);

  /**
   * @dev Returns the address of the partner that receives the partnerCommission
   */
  function wallet() external view returns (address);

  /**
   * @dev Called when a policy expires or is resolved to update the exposure.
   *
   * Requirements:
   * - Must be called by `policyPool()`
   *
   * @param payout The exposure (maximum payout) of the policy
   */
  function releaseExposure(uint256 payout) external;

  /**
   * @dev Returns the {PremiumsAccount} where the premiums of this risk module are collected. Never changes.
   */
  function premiumsAccount() external view returns (IPremiumsAccount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;
import {WadRayMath} from "./dependencies/WadRayMath.sol";
import {IRiskModule} from "./interfaces/IRiskModule.sol";

/**
 * @title Policy library
 * @dev Library for PolicyData struct. This struct represents an active policy, how the premium is
 *      distributed, the probability of payout, duration and how the capital is locked.
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
library Policy {
  using WadRayMath for uint256;

  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  // Active Policies
  struct PolicyData {
    uint256 id;
    uint256 payout;
    uint256 premium;
    uint256 jrScr;
    uint256 srScr;
    uint256 lossProb; // original loss probability (in wad)
    uint256 purePremium; // share of the premium that covers expected losses
    // equal to payout * lossProb * riskModule.moc
    uint256 ensuroCommission; // share of the premium that goes for Ensuro
    uint256 partnerCommission; // share of the premium that goes for the RM
    uint256 jrCoc; // share of the premium that goes to junior liquidity providers (won or not)
    uint256 srCoc; // share of the premium that goes to senior liquidity providers (won or not)
    IRiskModule riskModule;
    uint40 start;
    uint40 expiration;
  }

  function initialize(
    IRiskModule riskModule,
    IRiskModule.Params memory rmParams,
    uint256 premium,
    uint256 payout,
    uint256 lossProb,
    uint40 expiration
  ) internal view returns (PolicyData memory newPolicy) {
    require(premium <= payout, "Premium cannot be more than payout");
    PolicyData memory policy;

    policy.riskModule = riskModule;
    policy.premium = premium;
    policy.payout = payout;
    policy.lossProb = lossProb;
    policy.start = uint40(block.timestamp);
    policy.expiration = expiration;
    policy.purePremium = payout.wadMul(lossProb.wadMul(rmParams.moc));
    // Calculate Junior and Senior SCR
    policy.jrScr = payout.wadMul(rmParams.jrCollRatio);
    if (policy.jrScr > policy.purePremium) {
      policy.jrScr -= policy.purePremium;
    } else {
      policy.jrScr = 0;
    }
    policy.srScr = payout.wadMul(rmParams.collRatio);
    if (policy.srScr > (policy.purePremium + policy.jrScr)) {
      policy.srScr -= policy.purePremium + policy.jrScr;
    } else {
      policy.srScr = 0;
    }
    // Calculate CoCs
    policy.jrCoc = policy.jrScr.wadMul(
      (rmParams.jrRoc * (policy.expiration - policy.start)) / SECONDS_PER_YEAR
    );
    policy.srCoc = policy.srScr.wadMul(
      (rmParams.srRoc * (policy.expiration - policy.start)) / SECONDS_PER_YEAR
    );
    uint256 coc = policy.jrCoc + policy.srCoc;
    policy.ensuroCommission =
      policy.purePremium.wadMul(rmParams.ensuroPpFee) +
      coc.wadMul(rmParams.ensuroCocFee);
    require(
      (policy.purePremium + policy.ensuroCommission + coc) <= premium,
      "Premium less than minimum"
    );
    policy.partnerCommission = premium - policy.purePremium - coc - policy.ensuroCommission;
    return policy;
  }

  function jrInterestRate(PolicyData memory policy) internal pure returns (uint256) {
    return
      ((policy.jrCoc * SECONDS_PER_YEAR) / (policy.expiration - policy.start)).wadDiv(policy.jrScr);
  }

  function jrAccruedInterest(PolicyData memory policy) internal view returns (uint256) {
    return (policy.jrCoc * (block.timestamp - policy.start)) / (policy.expiration - policy.start);
  }

  function srInterestRate(PolicyData memory policy) internal pure returns (uint256) {
    return
      ((policy.srCoc * SECONDS_PER_YEAR) / (policy.expiration - policy.start)).wadDiv(policy.srScr);
  }

  function srAccruedInterest(PolicyData memory policy) internal view returns (uint256) {
    return (policy.srCoc * (block.timestamp - policy.start)) / (policy.expiration - policy.start);
  }

  function hash(PolicyData memory policy) internal pure returns (bytes32 retHash) {
    retHash = keccak256(abi.encode(policy));
    require(retHash != bytes32(0), "Policy: hash cannot be 0");
    return retHash;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IPolicyPool} from "./interfaces/IPolicyPool.sol";
import {IPolicyPoolComponent} from "./interfaces/IPolicyPoolComponent.sol";
import {IAccessManager} from "./interfaces/IAccessManager.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {WadRayMath} from "./dependencies/WadRayMath.sol";

/**
 * @title Base class for PolicyPool components
 * @dev This is the base class of all the components of the protocol that are linked to the PolicyPool and created
 *      after it.
 *      Holds the reference to _policyPool as immutable, also provides access to common admin roles:
 *      - LEVEL1_ROLE: High impact changes like upgrades, adding or removing components or other critical operations
 *      - LEVEL2_ROLE: Mid-impact changes like changing some parameters
 *      - LEVEL3_ROLE: Low-impact changes like changing some parameters up to given percentage (tweaks)
 *      - GUARDIAN_ROLE: For emergency operations oriented to protect the protocol in case of attacks or hacking.
 *
 *      This contract also keeps track of the tweaks to avoid two tweaks of the same type are done in a short period.
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
abstract contract PolicyPoolComponent is
  UUPSUpgradeable,
  PausableUpgradeable,
  IPolicyPoolComponent
{
  using WadRayMath for uint256;

  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant LEVEL1_ROLE = keccak256("LEVEL1_ROLE");
  bytes32 public constant LEVEL2_ROLE = keccak256("LEVEL2_ROLE");
  bytes32 public constant LEVEL3_ROLE = keccak256("LEVEL3_ROLE");

  uint40 public constant TWEAK_EXPIRATION = 1 days;

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  IPolicyPool internal immutable _policyPool;
  uint40 internal _lastTweakTimestamp;
  uint56 internal _lastTweakActions; // bitwise map of applied actions

  event GovernanceAction(IAccessManager.GovernanceActions indexed action, uint256 value);
  event ComponentChanged(IAccessManager.GovernanceActions indexed action, address value);

  modifier onlyPolicyPool() {
    require(_msgSender() == address(_policyPool), "The caller must be the PolicyPool");
    _;
  }

  modifier onlyComponentRole(bytes32 role) {
    _policyPool.access().checkComponentRole(address(this), role, _msgSender(), false);
    _;
  }

  modifier onlyGlobalOrComponentRole(bytes32 role) {
    _policyPool.access().checkComponentRole(address(this), role, _msgSender(), true);
    _;
  }

  modifier onlyGlobalOrComponentRole2(bytes32 role1, bytes32 role2) {
    _policyPool.access().checkComponentRole2(address(this), role1, role2, _msgSender(), true);
    _;
  }

  modifier onlyGlobalOrComponentRole3(
    bytes32 role1,
    bytes32 role2,
    bytes32 role3
  ) {
    IAccessManager access = _policyPool.access();
    if (!access.hasComponentRole(address(this), role1, _msgSender(), true)) {
      _policyPool.access().checkComponentRole2(address(this), role2, role3, _msgSender(), true);
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(IPolicyPool policyPool_) {
    require(
      address(policyPool_) != address(0),
      "PolicyPoolComponent: policyPool cannot be zero address"
    );
    _disableInitializers();
    _policyPool = policyPool_;
  }

  // solhint-disable-next-line func-name-mixedcase
  function __PolicyPoolComponent_init() internal onlyInitializing {
    __UUPSUpgradeable_init();
    __Pausable_init();
  }

  function _authorizeUpgrade(address newImpl)
    internal
    view
    override
    onlyGlobalOrComponentRole2(GUARDIAN_ROLE, LEVEL1_ROLE)
  {
    _upgradeValidations(newImpl);
  }

  function _upgradeValidations(address newImpl) internal view virtual {
    require(
      IPolicyPoolComponent(newImpl).policyPool() == _policyPool,
      "Can't upgrade changing the PolicyPool!"
    );
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IPolicyPoolComponent).interfaceId;
  }

  function pause() public onlyGlobalOrComponentRole(GUARDIAN_ROLE) {
    _pause();
  }

  function unpause() public onlyGlobalOrComponentRole2(GUARDIAN_ROLE, LEVEL1_ROLE) {
    _unpause();
  }

  function policyPool() public view override returns (IPolicyPool) {
    return _policyPool;
  }

  function currency() public view returns (IERC20Metadata) {
    return _policyPool.currency();
  }

  function hasPoolRole(bytes32 role) internal view returns (bool) {
    return _policyPool.access().hasComponentRole(address(this), role, _msgSender(), true);
  }

  function _isTweakWad(
    uint256 oldValue,
    uint256 newValue,
    uint256 maxTweak
  ) internal pure returns (bool) {
    if (oldValue == newValue) return true;
    if (oldValue == 0) return maxTweak >= WadRayMath.WAD;
    if (newValue == 0) return false;
    if (oldValue < newValue) {
      return (newValue.wadDiv(oldValue) - WadRayMath.WAD) <= maxTweak;
    } else {
      return (WadRayMath.WAD - newValue.wadDiv(oldValue)) <= maxTweak;
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function _validateParameters() internal view virtual {} // Must be reimplemented with specific validations

  function _parameterChanged(
    IAccessManager.GovernanceActions action,
    uint256 value,
    bool tweak
  ) internal {
    _validateParameters();
    if (tweak) _registerTweak(action);
    emit GovernanceAction(action, value);
  }

  function _componentChanged(IAccessManager.GovernanceActions action, address value) internal {
    _validateParameters();
    emit ComponentChanged(action, value);
  }

  function lastTweak() external view returns (uint40, uint56) {
    return (_lastTweakTimestamp, _lastTweakActions);
  }

  function _registerTweak(IAccessManager.GovernanceActions action) internal {
    uint56 actionBitMap = uint56(1 << (uint8(action) - 1));
    if ((uint40(block.timestamp) - _lastTweakTimestamp) > TWEAK_EXPIRATION) {
      _lastTweakTimestamp = uint40(block.timestamp);
      _lastTweakActions = actionBitMap;
    } else {
      if ((actionBitMap & _lastTweakActions) == 0) {
        _lastTweakActions |= actionBitMap;
        _lastTweakTimestamp = uint40(block.timestamp); // Updates the expiration
      } else {
        revert("You already tweaked this parameter recently. Wait before tweaking again");
      }
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {WadRayMath} from "./dependencies/WadRayMath.sol";
import {IPolicyPool} from "./interfaces/IPolicyPool.sol";
import {PolicyPoolComponent} from "./PolicyPoolComponent.sol";
import {IRiskModule} from "./interfaces/IRiskModule.sol";
import {IPremiumsAccount} from "./interfaces/IPremiumsAccount.sol";
import {IAccessManager} from "./interfaces/IAccessManager.sol";
import {Policy} from "./Policy.sol";

/**
 * @title Ensuro Risk Module base contract
 * @dev Risk Module that keeps the configuration and is responsible for pricing and policy resolution
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
abstract contract RiskModule is IRiskModule, PolicyPoolComponent {
  using Policy for Policy.PolicyData;
  using WadRayMath for uint256;
  using SafeCast for uint256;

  uint256 internal constant SECONDS_IN_YEAR_WAD = 31536000e18; /* 365 * 24 * 3600 * 10e18 */
  uint16 internal constant HOURS_PER_YEAR = 8760; /* 24 * 365 */

  uint256 internal constant FOUR_DECIMAL_TO_WAD = 1e14;
  uint16 internal constant HUNDRED_PERCENT = 1e4;
  uint16 internal constant MIN_MOC = 5e3; // 50%
  uint16 internal constant MAX_MOC = 4e4; // 400%

  // For parameters that can be changed by the risk module provider
  bytes32 public constant RM_PROVIDER_ROLE = keccak256("RM_PROVIDER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  IPremiumsAccount internal immutable _premiumsAccount;

  string private _name;

  struct PackedParams {
    uint16 moc; // Margin Of Conservativism - factor that multiplies lossProb - 4 decimals
    uint16 jrCollRatio; // Collateralization Ratio to compute Junior solvency as % of payout - 4 decimals
    uint16 collRatio; // Collateralization Ratio to compute solvency requirement as % of payout - 4 decimals
    uint16 ensuroPpFee; // % of pure premium that will go for Ensuro treasury - 4 decimals
    uint16 ensuroCocFee; // % of CoC that will go for Ensuro treasury - 4 decimals
    uint16 jrRoc; // Return on Capital paid to Junior LPs - Annualized Percentage - 4 decimals
    uint16 srRoc; // Return on Capital paid to Senior LPs - Annualized Percentage - 4 decimals
    uint32 maxPayoutPerPolicy; // Max Payout per Policy - 2 decimals
    uint32 exposureLimit; // Max exposure (sum of payouts) to be allocated to this module - 0 decimals
    uint16 maxDuration; // Max policy duration (in hours)
  }

  PackedParams internal _params;

  uint256 internal _activeExposure; // in wad - Current exposure of active policies

  address internal _wallet; // Address of the RiskModule provider

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(IPolicyPool policyPool_, IPremiumsAccount premiumsAccount_)
    PolicyPoolComponent(policyPool_)
  {
    require(
      PolicyPoolComponent(address(premiumsAccount_)).policyPool() == policyPool_,
      "The PremiumsAccount must be part of the Pool"
    );
    _premiumsAccount = premiumsAccount_;
  }

  /**
   * @dev Initializes the RiskModule
   * @param name_ Name of the Risk Module
   * @param collRatio_ Collateralization ratio to compute solvency requirement as % of payout (in wad)
   * @param ensuroPpFee_ % of pure premium that will go for Ensuro treasury (in wad)
   * @param srRoc_ return on capital paid to LPs (annualized percentage - in wad)
   * @param maxPayoutPerPolicy_ Maximum payout per policy (in wad)
   * @param exposureLimit_ Max exposure (sum of payouts) to be allocated to this module (in wad)
   * @param wallet_ Address of the RiskModule provider
   */
  // solhint-disable-next-line func-name-mixedcase
  function __RiskModule_init(
    string memory name_,
    uint256 collRatio_,
    uint256 ensuroPpFee_,
    uint256 srRoc_,
    uint256 maxPayoutPerPolicy_,
    uint256 exposureLimit_,
    address wallet_
  ) internal onlyInitializing {
    __PolicyPoolComponent_init();
    __RiskModule_init_unchained(
      name_,
      collRatio_,
      ensuroPpFee_,
      srRoc_,
      maxPayoutPerPolicy_,
      exposureLimit_,
      wallet_
    );
  }

  // solhint-disable-next-line func-name-mixedcase
  function __RiskModule_init_unchained(
    string memory name_,
    uint256 collRatio_,
    uint256 ensuroPpFee_,
    uint256 srRoc_,
    uint256 maxPayoutPerPolicy_,
    uint256 exposureLimit_,
    address wallet_
  ) internal onlyInitializing {
    _name = name_;
    _params = PackedParams({
      moc: HUNDRED_PERCENT,
      jrCollRatio: 0,
      collRatio: _wadTo4(collRatio_),
      ensuroPpFee: _wadTo4(ensuroPpFee_),
      ensuroCocFee: 0,
      jrRoc: 0,
      srRoc: _wadTo4(srRoc_),
      maxPayoutPerPolicy: _amountToX(2, maxPayoutPerPolicy_),
      exposureLimit: _amountToX(0, exposureLimit_),
      maxDuration: HOURS_PER_YEAR
    });
    _activeExposure = 0;
    _wallet = wallet_;
    _validateParameters();
  }

  function _upgradeValidations(address newImpl) internal view virtual override {
    super._upgradeValidations(newImpl);
    IRiskModule newRM = IRiskModule(newImpl);
    require(
      newRM.premiumsAccount() == _premiumsAccount,
      "Can't upgrade changing the PremiumsAccount"
    );
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId) || interfaceId == type(IRiskModule).interfaceId;
  }

  // runs validation on RiskModule parameters
  function _validateParameters() internal view virtual override {
    // _maxPayoutPerPolicy no limits
    require(
      exposureLimit() >= _activeExposure,
      "Validation: exposureLimit can't be less than actual activeExposure"
    );
    require(_wallet != address(0), "Validation: Wallet can't be zero address");
    _validatePackedParams(_params);
  }

  function _validatePackedParams(PackedParams storage params_) internal view {
    require(params_.jrCollRatio <= HUNDRED_PERCENT, "Validation: jrCollRatio must be <=1");
    require(
      params_.collRatio <= HUNDRED_PERCENT && params_.collRatio > 0,
      "Validation: collRatio must be <=1"
    );
    require(params_.collRatio >= params_.jrCollRatio, "Validation: collRatio >= jrCollRatio");
    require(params_.moc <= MAX_MOC && params_.moc >= MIN_MOC, "Validation: moc must be [0.5, 4]");
    require(params_.ensuroPpFee <= HUNDRED_PERCENT, "Validation: ensuroPpFee must be <= 1");
    require(params_.ensuroCocFee <= HUNDRED_PERCENT, "Validation: ensuroCocFee must be <= 1");
    require(params_.srRoc <= HUNDRED_PERCENT, "Validation: srRoc must be <= 1 (100%)");
    require(params_.jrRoc <= HUNDRED_PERCENT, "Validation: jrRoc must be <= 1 (100%)");
    require(
      params_.exposureLimit > 0 && params_.maxPayoutPerPolicy > 0,
      "Exposure and MaxPayout must be >0"
    );
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  // solhint-disable-next-line func-name-mixedcase
  function _4toWad(uint16 value) internal pure returns (uint256) {
    // 4 decimals to Wad (18 decimals)
    return uint256(value) * FOUR_DECIMAL_TO_WAD;
  }

  function _wadTo4(uint256 value) internal pure returns (uint16) {
    // Wad to 4 decimals
    return (value / FOUR_DECIMAL_TO_WAD).toUint16();
  }

  // solhint-disable-next-line func-name-mixedcase
  function _XtoAmount(uint8 decimals, uint32 value) internal view returns (uint256) {
    // X decimals to currency decimals (6 for USDC)
    return uint256(value) * 10**(currency().decimals() - decimals);
  }

  function _amountToX(uint8 decimals, uint256 value) internal view returns (uint32) {
    // currency decimals to X decimals (assuming X < currency decimals)
    return (value / 10**(currency().decimals() - decimals)).toUint32();
  }

  function maxPayoutPerPolicy() public view override returns (uint256) {
    return _XtoAmount(2, _params.maxPayoutPerPolicy);
  }

  function exposureLimit() public view override returns (uint256) {
    return _XtoAmount(0, _params.exposureLimit);
  }

  function maxDuration() public view override returns (uint256) {
    return _params.maxDuration;
  }

  function activeExposure() public view override returns (uint256) {
    return _activeExposure;
  }

  function wallet() public view override returns (address) {
    return _wallet;
  }

  function setParam(Parameter param, uint256 newValue)
    external
    onlyGlobalOrComponentRole3(LEVEL1_ROLE, LEVEL2_ROLE, LEVEL3_ROLE)
  {
    bool tweak = !hasPoolRole(LEVEL2_ROLE) && !hasPoolRole(LEVEL1_ROLE);
    if (param == Parameter.moc) {
      require(!tweak || _isTweakWad(_4toWad(_params.moc), newValue, 1e17), "Tweak exceeded");
      _params.moc = _wadTo4(newValue);
    } else if (param == Parameter.jrCollRatio) {
      require(
        !tweak || _isTweakWad(_4toWad(_params.jrCollRatio), newValue, 1e17),
        "Tweak exceeded"
      );
      _params.jrCollRatio = _wadTo4(newValue);
    } else if (param == Parameter.collRatio) {
      require(!tweak || _isTweakWad(_4toWad(_params.collRatio), newValue, 1e17), "Tweak exceeded");
      _params.collRatio = _wadTo4(newValue);
    } else if (param == Parameter.ensuroPpFee) {
      require(
        !tweak || _isTweakWad(_4toWad(_params.ensuroPpFee), newValue, 1e17),
        "Tweak exceeded"
      );
      _params.ensuroPpFee = _wadTo4(newValue);
    } else if (param == Parameter.ensuroCocFee) {
      require(
        !tweak || _isTweakWad(_4toWad(_params.ensuroCocFee), newValue, 1e17),
        "Tweak exceeded"
      );
      _params.ensuroCocFee = _wadTo4(newValue);
    } else if (param == Parameter.jrRoc) {
      require(!tweak || _isTweakWad(_4toWad(_params.jrRoc), newValue, 1e17), "Tweak exceeded");
      _params.jrRoc = _wadTo4(newValue);
    } else if (param == Parameter.srRoc) {
      require(!tweak || _isTweakWad(_4toWad(_params.srRoc), newValue, 1e17), "Tweak exceeded");
      _params.srRoc = _wadTo4(newValue);
    } else if (param == Parameter.maxPayoutPerPolicy) {
      require(!tweak || _isTweakWad(maxPayoutPerPolicy(), newValue, 1e17), "Tweak exceeded");
      _params.maxPayoutPerPolicy = _amountToX(2, newValue);
    } else if (param == Parameter.exposureLimit) {
      require(newValue >= _activeExposure, "Can't set exposureLimit less than active exposure");
      require(!tweak || _isTweakWad(exposureLimit(), newValue, 1e17), "Tweak exceeded");
      require(
        newValue <= exposureLimit() || hasPoolRole(LEVEL1_ROLE),
        "Tweak exceeded: Increase requires LEVEL1_ROLE"
      );
      _params.exposureLimit = _amountToX(0, newValue);
    } else if (param == Parameter.maxDuration) {
      require(!tweak, "Tweak exceeded");
      _params.maxDuration = newValue.toUint16();
    }
    _parameterChanged(
      IAccessManager.GovernanceActions(
        uint256(IAccessManager.GovernanceActions.setMoc) + uint256(param)
      ),
      newValue,
      tweak
    );
  }

  function params() public view virtual override returns (Params memory ret) {
    return _unpackParams(_params);
  }

  function _unpackParams(PackedParams storage params_) internal view returns (Params memory ret) {
    return
      Params({
        moc: _4toWad(params_.moc),
        jrCollRatio: _4toWad(params_.jrCollRatio),
        collRatio: _4toWad(params_.collRatio),
        ensuroPpFee: _4toWad(params_.ensuroPpFee),
        ensuroCocFee: _4toWad(params_.ensuroCocFee),
        jrRoc: _4toWad(params_.jrRoc),
        srRoc: _4toWad(params_.srRoc)
      });
  }

  function setWallet(address wallet_) external onlyComponentRole(RM_PROVIDER_ROLE) {
    require(wallet_ != address(0), "RiskModule: wallet cannot be the zero address");
    _wallet = wallet_;
    _parameterChanged(IAccessManager.GovernanceActions.setWallet, uint256(uint160(wallet_)), false);
  }

  function getMinimumPremium(
    uint256 payout,
    uint256 lossProb,
    uint40 expiration
  ) public view virtual returns (uint256) {
    return _getMinimumPremium(payout, lossProb, expiration, params());
  }

  function _getMinimumPremium(
    uint256 payout,
    uint256 lossProb,
    uint40 expiration,
    Params memory p
  ) internal view returns (uint256) {
    uint256 purePremium = payout.wadMul(lossProb.wadMul(p.moc));
    uint256 jrScr = payout.wadMul(p.jrCollRatio);
    if (jrScr > purePremium) {
      jrScr -= purePremium;
    } else {
      jrScr = 0;
    }
    uint256 srScr = payout.wadMul(p.collRatio);
    if (srScr > (purePremium + jrScr)) {
      srScr -= purePremium + jrScr;
    } else {
      srScr = 0;
    }
    uint256 jrCoc = jrScr.wadMul(
      (p.jrRoc * (expiration - block.timestamp)).wadDiv(SECONDS_IN_YEAR_WAD)
    );
    uint256 srCoc = srScr.wadMul(
      (p.srRoc * (expiration - block.timestamp)).wadDiv(SECONDS_IN_YEAR_WAD)
    );
    uint256 ensuroCommission = purePremium.wadMul(p.ensuroPpFee) +
      (jrCoc + srCoc).wadMul(p.ensuroCocFee);
    return purePremium + ensuroCommission + (jrCoc + srCoc);
  }

  /**
   * @dev Called from child contracts to create policies (after they validated the pricing).
   *      whenNotPaused validation must be done in the external method.
   *
   * @param payout The exposure (maximum payout) of the policy
   * @param premium The premium that will be paid by the policyHolder
   * @param lossProb The probability of having to pay the maximum payout (wad)
   * @param payer The account that pays for the premium
   * @param expiration The expiration of the policy (timestamp)
   * @param onBehalfOf The policy holder
   * @param internalId An id that's unique within this module and it will be used to identify the policy
   */
  function _newPolicy(
    uint256 payout,
    uint256 premium,
    uint256 lossProb,
    uint40 expiration,
    address payer,
    address onBehalfOf,
    uint96 internalId
  ) internal virtual returns (Policy.PolicyData memory) {
    return
      _newPolicyWithParams(
        payout,
        premium,
        lossProb,
        expiration,
        payer,
        onBehalfOf,
        internalId,
        params()
      );
  }

  /**
   * @dev Internal method without whenNotPaused, MUST be called from other function that has this modifier
   */
  function _newPolicyWithParams(
    uint256 payout,
    uint256 premium,
    uint256 lossProb,
    uint40 expiration,
    address payer,
    address onBehalfOf,
    uint96 internalId,
    Params memory params_
  ) internal returns (Policy.PolicyData memory) {
    if (premium == type(uint256).max) {
      premium = _getMinimumPremium(payout, lossProb, expiration, params_);
    }
    require(premium < payout, "Premium must be less than payout");
    uint40 now_ = uint40(block.timestamp);
    require(expiration > now_, "Expiration must be in the future");
    require(((expiration - now_) / 3600) < _params.maxDuration, "Policy exceeds max duration");
    require(onBehalfOf != address(0), "Customer can't be zero address");
    require(
      _policyPool.currency().allowance(payer, address(_policyPool)) >= premium,
      "You must allow ENSURO to transfer the premium"
    );
    require(
      payer == _msgSender() || _policyPool.currency().allowance(payer, _msgSender()) >= premium,
      "Payer must allow caller to transfer the premium"
    );
    require(payout <= maxPayoutPerPolicy(), "RiskModule: Payout is more than maximum per policy");
    Policy.PolicyData memory policy = Policy.initialize(
      this,
      params_,
      premium,
      payout,
      lossProb,
      expiration
    );
    _activeExposure += policy.payout;
    require(_activeExposure <= exposureLimit(), "RiskModule: Exposure limit exceeded");
    uint256 policyId = _policyPool.newPolicy(policy, payer, onBehalfOf, internalId);
    policy.id = policyId;
    return policy;
  }

  function releaseExposure(uint256 payout) external override onlyPolicyPool {
    // In the Python protype this function is called `remove_policy` and receives
    // all the policy. Since we just need the amount, for performance reasons
    // we just send the amount and the method is called releaseExposure
    _activeExposure -= payout;
  }

  function premiumsAccount() external view override returns (IPremiumsAccount) {
    return _premiumsAccount;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[46] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPolicyPool} from "@ensuro/core/contracts/interfaces/IPolicyPool.sol";
import {IPremiumsAccount} from "@ensuro/core/contracts/interfaces/IPremiumsAccount.sol";
import {RiskModule} from "@ensuro/core/contracts/RiskModule.sol";
import {Policy} from "@ensuro/core/contracts/Policy.sol";
import {WadRayMath} from "@ensuro/core/contracts/dependencies/WadRayMath.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

/**
 * @title ChainlinkPriceOracle
 * @dev Implementation of IPriceOracle using two underlying chainlink oracles. One with the price of the asset and
 *      other (referenceOracle - optional) with the price of the asset you want to denominate the asset price.
 * @custom:security-contact [email protected]
 * @author Ensuro
 */
contract ChainlinkPriceOracle is IPriceOracle {
  using WadRayMath for uint256;

  uint8 internal constant WAD_DECIMALS = 18;

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  AggregatorV3Interface internal immutable _assetOracle;
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  AggregatorV3Interface internal immutable _referenceOracle;
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  uint256 internal immutable _oracleTolerance;

  /**
   * @dev Constructs the PriceRiskModule.
   *      Note that, although it's supported that assetOracle_ and  referenceOracle_ have different number
   *      of decimals, they're assumed to be in the same denomination. For instance, assetOracle_ could be
   *      WMATIC/ETH and referenceOracle_ could be for USDC/ETH.
   *      This cannot be validated by the contract, so be careful when constructing.
   *
   * @param assetOracle_ Address of the price feed oracle for the asset
   * @param referenceOracle_ Address of the price feed oracle for the reference currency. If it's
   *                         the zero address the asset price will be considered directly.
   * @param oracleTolerance_ Max acceptable age of price data, in seconds
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(
    AggregatorV3Interface assetOracle_,
    AggregatorV3Interface referenceOracle_,
    uint256 oracleTolerance_
  ) {
    require(
      address(assetOracle_) != address(0),
      "PriceRiskModule: assetOracle_ cannot be the zero address"
    );
    _assetOracle = assetOracle_;
    _referenceOracle = referenceOracle_;
    _oracleTolerance = oracleTolerance_;
  }

  /**
   * @dev Returns the price of the asset
   *
   * Requirements:
   * - The oracle(s) are functional, returning non zero values and updated after (block.timestamp - oracleTolerance())
   *
   * @return If referenceOracle() != address(0), returns the price of the asset expressed in terms of the reference
   *         asset, in Wad (18 decimals)
   *         If referenceOracle() == address(0), returns the price of the asset expressed in the denomination of
   *         assetOracle(), in Wad (18 decimals)
   */
  function getCurrentPrice() public view virtual override returns (uint256) {
    if (address(_referenceOracle) == address(0)) {
      return _scalePrice(_getLatestPrice(_assetOracle), _assetOracle.decimals(), WAD_DECIMALS);
    } else {
      return _getExchangeRate(_assetOracle, _referenceOracle);
    }
  }

  /**
   * @dev Calculates the exchange rate between the prices returned by the two aggregators
   *      Assumes that both aggregators are returning prices using the same quote.
   *      Although it's usual that the aggregators return prices with the same number of
   *      decimals, this is not required. Both prices will be scaled to Wad before calculating the
   *      rate.
   * @param base the aggregator for the base
   * @param quote the aggregator for the quote asset.
   * @return The exchange rate from/to in Wad
   */
  function _getExchangeRate(AggregatorV3Interface base, AggregatorV3Interface quote)
    internal
    view
    returns (uint256)
  {
    uint256 basePrice = _scalePrice(_getLatestPrice(base), base.decimals(), WAD_DECIMALS);
    require(basePrice != 0, "Price from not available");

    uint256 quotePrice = _scalePrice(_getLatestPrice(quote), quote.decimals(), WAD_DECIMALS);
    require(quotePrice != 0, "Price to not available");

    return basePrice.wadDiv(quotePrice);
  }

  function _getLatestPrice(AggregatorV3Interface oracle) internal view returns (uint256) {
    (, int256 price, , uint256 updatedAt, ) = oracle.latestRoundData();
    require(updatedAt > block.timestamp - _oracleTolerance, "Price is older than tolerable");

    return SafeCast.toUint256(price);
  }

  function _scalePrice(
    uint256 price,
    uint8 priceDecimals,
    uint8 decimals
  ) internal pure returns (uint256) {
    if (priceDecimals < decimals) return price * 10**(decimals - priceDecimals);
    else return price / 10**(priceDecimals - decimals);
  }

  function referenceOracle() external view returns (AggregatorV3Interface) {
    return _referenceOracle;
  }

  function assetOracle() external view returns (AggregatorV3Interface) {
    return _assetOracle;
  }

  function oracleTolerance() external view returns (uint256) {
    return _oracleTolerance;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IRiskModule} from "@ensuro/core/contracts/interfaces/IRiskModule.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title IPriceOracle interface
 * @dev Interface for price oracles that returns the price (in Wad) for a given asset.
 *      It encapsulates the complexities of the underlying oracle, the validations and the reference currency used
 *      to express the price. That reference currency is implicit.
 * @author Ensuro
 */
interface IPriceOracle {
  /**
   * @dev Returns the price of the asset (the reference whether it's another crypto asset or USD is implicit)
   *
   * Requirements:
   * - The underlying oracle(s) are functional. It NEVER returns zero.
   *
   * @return The price of the asset in Wad (18 decimals)
   */
  function getCurrentPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}