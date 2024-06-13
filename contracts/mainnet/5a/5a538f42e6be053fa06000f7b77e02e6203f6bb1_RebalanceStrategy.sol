// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AutomationCompatibleInterface} from "chainlink/v0.8/automation/AutomationCompatible.sol";
import {IProvider} from "./interfaces/IProvider.sol";
import {IInterestVault} from "./interfaces/IInterestVault.sol";
import {IRebalancerManager} from "./interfaces/IRebalancerManager.sol";

// This contract implements a rebalancing strategy for an interest vault.
// It is designed to be integrated with Chainlink Automation.
contract RebalanceStrategy is AutomationCompatibleInterface {
    // The interest vault to manage
    IInterestVault public vault;
    // The rebalancer manager responsible for the rebalancing process
    IRebalancerManager public rebalancerManager;
    // The address of Chainlink's Forwarder contract that will be used to trigger performUpkeep()
    address public forwarder;

    // Event emitted when rebalance is performed
    event UpkeepPerformed(IProvider newProvider);

    constructor(IInterestVault _vault, IRebalancerManager _rebalancerManager) {
        vault = _vault;
        rebalancerManager = _rebalancerManager;
    }

    // Called only once when Chainlink Upkeep is set up
    function setForwarder(address _forwarder) external {
        require(forwarder == address(0), "Forwarder already set");
        forwarder = _forwarder;
    }

    // Function called by Chainlink to perform the upkeep, i.e. rebalance the vault
    function performUpkeep(bytes calldata performData) external override {
        require(msg.sender == forwarder, "Only the forwarder can call this function");
        IProvider newProvider = abi.decode(performData, (IProvider));
        rebalancerManager.rebalanceVault(vault, type(uint256).max, vault.activeProvider(), newProvider, 0, true);
        emit UpkeepPerformed(newProvider);
    }

    // Function called by Chainlink to check whether it needs to perform the upkeep (rebalance)
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        IProvider newProvider;
        (upkeepNeeded, newProvider) = shouldRebalance();
        if (upkeepNeeded) {
            performData = abi.encode(newProvider);
        }
    }

    // Function to check whether a rebalancing is needed
    // It aims to rebalance to another provider as soon as its deposit rate is the highest
    function shouldRebalance() public view returns (bool should, IProvider newProvider) {
        IProvider[] memory providers = vault.getProviders();
        uint256[] memory rates = depositRates();
        IProvider activeProvider = vault.activeProvider();
        uint256 activeRate = activeProvider.getDepositRateFor(vault);
        uint256 highestRate = 0;
        IProvider bestProvider;
        for (uint256 i = 0; i < rates.length; i++) {
            if (rates[i] > highestRate) {
                highestRate = rates[i];
                bestProvider = providers[i];
            }
        }
        if (activeRate != highestRate) {
            should = true;
            newProvider = bestProvider;
        } else {
            should = false;
            newProvider = activeProvider;
        }
    }

    // Get deposit rates for each provider, in the same order as getProviders()
    function depositRates() public view returns (uint256[] memory rates) {
        IProvider[] memory providers = vault.getProviders();
        rates = new uint256[](providers.length);
        for (uint256 i = 0; i < providers.length; i++) {
            rates[i] = providers[i].getDepositRateFor(vault);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IInterestVault} from "./IInterestVault.sol";

/**
 * @title IProvider
 *
 * @notice Defines the interface for core engine to perform operations at lending providers.
 *
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface IProvider {
  function getProviderName() external view returns (string memory);

  /**
   * @notice Returns the operator address that requires ERC20-approval for vault operations.
   *
   * @param key address to inquiry operator
   * @param asset address of the asset
   * @param debtAsset address of the debt asset
   *
   * @dev Provider implementations may or not require all inputs.
   */
  function getOperator(
    address key,
    address asset,
    address debtAsset
  )
    external
    view
    returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf vault.
   *
   * @param amount amount to deposit
   * @param vault IInterestVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IInterestVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount to withdraw
   * @param vault IInterestVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IInterestVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IInterestVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getDepositBalance(address user, IInterestVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   *
   * @param vault IInterestVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getDepositRateFor(IInterestVault vault) external view returns (uint256 rate);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title IInterestVault
 *
 * @notice Defines the interface for vaults extending from IERC4626.
 */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IProvider} from "./IProvider.sol";

interface IInterestVault is IERC4626 {

  /**
   * @dev Emit when the vault is initialized
   *
   * @param initializer of this vault
   *
   */
  event VaultInitialized(address initializer);

  /**
   * @dev Emit when the fees are charged
   *
   * @param treasury of this vault
   * @param fee amount
   *
   */
  event FeesCharged(address treasury, uint256 fee);

  /**
   * @dev Emit when the available providers for the vault change.
   *
   * @param newProviders the new providers available
   */
  event ProvidersChanged(IProvider[] newProviders);

  /**
   * @dev Emit when the active provider is changed.
   *
   * @param newActiveProvider the new active provider
   */
  event ActiveProviderChanged(IProvider newActiveProvider);

  /**
   * @dev Emit when the deposit limits are changed.
   *
   * @param newUserDepositLimit the new user deposit limit
   * @param newVaultDepositLimit the new vault deposit limit
   */
  event DepositLimitsChanged(uint256 newUserDepositLimit, uint256 newVaultDepositLimit);

  /**
   * @dev Emit when the vault is rebalanced.
   *
   * @param assetsFrom amount to be rebalanced
   * @param assetsTo amount to be rebalanced
   * @param from provider
   * @param to provider
   */
  event VaultRebalance(uint256 assetsFrom, uint256 assetsTo, address indexed from, address indexed to);

  /**
   * @dev Emit when the fees are changed.
   *
   * @param newWithdrawFee the new withdraw fee
   */
  event FeesChanged(uint256 newWithdrawFee);
  
  /**
   * @dev Emit when the treasury address is changed.
   *
   * @param newTreasury the new treasury address
   */
  event TreasuryChanged(address newTreasury);

  /**
   * @dev Emit when the minumum amount is changed.
   *
   * @param newMinAmount the new minimum amount
   */
  event MinAmountChanged(uint256 newMinAmount);

  /*///////////////////////////
    Asset management functions
  //////////////////////////*/

  /**
   * @notice Returns the amount of assets owned by `owner`.
   *
   * @param owner to check balance
   *
   * @dev This method avoids having to do external conversions from shares to
   * assets, since {IERC4626-balanceOf} returns shares.
   */
  function balanceOfAsset(address owner) external view returns (uint256 assets);

  
  /*///////////////////
    General functions
  ///////////////////*/

  /**
   * @notice Returns the active provider of this vault.
   */
  function getProviders() external view returns (IProvider[] memory);
  /**
   * @notice Returns the active provider of this vault.
   */
  function activeProvider() external view returns (IProvider);


  /*/////////////////////////
     Rebalancing Function
  ////////////////////////*/

  /**
   * @notice Performs rebalancing of vault by moving funds across providers.
   *
   * @param assets amount of this vault to be rebalanced
   * @param from provider
   * @param to provider
   * @param fee expected from rebalancing operation
   * @param setToAsActiveProvider boolean
   *
   * @dev Requirements:
   * - Must check providers `from` and `to` are valid.
   * - Must be called from a {RebalancerManager} contract that makes all proper checks.
   * - Must revert if caller is not an approved rebalancer.
   * - Must emit the VaultRebalance event.
   * - Must check `fee` is a reasonable amount.
   */
  function rebalance(
    uint256 assets,
    IProvider from,
    IProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    returns (bool);

  /*/////////////////////
     Setter functions 
  ////////////////////*/

  /**
   * @notice Sets the lists of providers of this vault.
   *
   * @param providers address array
   *
   * @dev Requirements:
   * - Must not contain zero addresses.
   */
  function setProviders(IProvider[] memory providers) external;

  /**
   * @notice Sets the active provider for this vault.
   *
   * @param activeProvider address
   *
   * @dev Requirements:
   * - Must be a provider previously set by `setProviders()`.
   * - Must be called from the admin.
   *
   * WARNING! Changing active provider without a `rebalance()` call
   * can result in denial of service for vault users.
   */
  function setActiveProvider(IProvider activeProvider) external;

  /**
   * @notice Sets the deposit limits for this vault.
   *
   * @param userDepositLimit_ new user deposit limit
   * @param vaultDepositLimit_ new vault deposit limit
   *
   * @dev Requirements:
   * - Must not be 0.
   * - Must be called from the admin.
   */
  function setDepositLimits(uint256 userDepositLimit_, uint256 vaultDepositLimit_) external;

  /**
   * @notice Sets the treasury address for this vault.
   *
   * @param treasury address
   *
   * @dev Requirements:
   * - Must be called from admin
   */

  function setTreasury(address treasury) external;

  /**
   * @notice Sets fee percents for this vault.
   *
   * @param withdrawFeePercent new withdraw fee percent
   *
   * @dev Requirements:
   * - Must be called from admin
   */

  function setFees(uint256 withdrawFeePercent) external;

  /**
   * @notice Sets the minimum amount for: `deposit()`, `mint()`.
   *
   * @param amount to be as minimum.
   */
  function setMinAmount(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title IRebalancerManager
 *
 * @notice Defines the interface of {RebalancerManager}.
 */

import {IInterestVault} from "./IInterestVault.sol";
import {IProvider} from "./IProvider.sol";

interface IRebalancerManager {
  /**
   * @dev Emit when `executor`'s `allowed` state changes.
   *
   * @param executor whose permission is changing
   * @param allowed boolean for new state
   */
  event AllowExecutor(address indexed executor, bool allowed);

  /**
   * @notice Rebalance funds of a vault between providers.
   *
   * @param vault that will be rebalanced
   * @param assets amount to be rebalanced
   * @param from provider address
   * @param to provider address
   * @param fee amount to be charged
   * @param setToAsActiveProvider boolean if `activeProvider` should change
   *
   * @dev Requirements:
   * - Must only be called by a valid executor.
   * - Must check `assets` amount is less than `vault`'s managed amount.
   *
   * NOTE: For argument `assets` you can pass `type(uint256).max` in solidity
   * to effectively rebalance 100% of assets from one provider to another.
   * Hints:
   *  - In ethers.js use `ethers.constants.MaxUint256` to return equivalent BigNumber.
   *  - In Foundry using console use $(cast max-uint).
   */
  function rebalanceVault(
    IInterestVault vault,
    uint256 assets,
    IProvider from,
    IProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    returns (bool success);

  /**
   * @notice Set `executor` as an authorized address for calling rebalancer operations
   * or remove authorization.
   *
   * @param executor address
   * @param allowed boolean
   *
   * @dev Requirement:
   * - Must be called from the admin.
   * - Must emit a `AllowExecutor` event.
   */
  function allowExecutor(address executor, bool allowed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0) && tx.origin != address(0x1111111111111111111111111111111111111111)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC-4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
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
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

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
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
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