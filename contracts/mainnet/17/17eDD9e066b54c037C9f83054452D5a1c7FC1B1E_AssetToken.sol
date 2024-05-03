// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";

/**
 * @title IACLManager
 * @author Amorphous (cloned from AAVE core v3 commit d5fafce)
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
    /**
     * @notice Returns the contract address of the GuildAddressesProvider
     * @return The address of the GuildAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IGuildAddressesProvider);

    /**
     * @notice Returns the identifier of the GuildAdmin role
     * @return The id of the GuildAdmin role
     */
    function GUILD_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as GuildAdmin
     * @param admin The address of the new admin
     */
    function addGuildAdmin(address admin) external;

    /**
     * @notice Removes an admin as GuildAdmin
     * @param admin The address of the admin to remove
     */
    function removeGuildAdmin(address admin) external;

    /**
     * @notice Returns true if the address is GuildAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is GuildAdmin, false otherwise
     */
    function isGuildAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IGuild} from "./IGuild.sol";
import {INotionalERC20} from "./INotionalERC20.sol";
import {IInitializableAssetToken} from "./IInitializableAssetToken.sol";

interface IAssetToken is IERC20, INotionalERC20, IInitializableAssetToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function updateNotionalFactor(uint256 multFactor) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title ICreditDelegation
 * @author Amorphous, inspired by AAVE v3
 * @notice Defines the basic interface for a token supporting credit delegation.
 **/
interface ICreditDelegation {
    /**
     * @dev Emitted on `approveDelegation` and `borrowAllowance
     * @param fromUser The address of the delegator
     * @param toUser The address of the delegatee
     * @param amount The amount being delegated
     */
    event BorrowAllowanceDelegated(address indexed fromUser, address indexed toUser, uint256 amount);

    /**
     * @notice Increases the allowance of delegatee to mint _msgSender() tokens
     * @param delegatee The delegatee allowed to mint on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     **/
    function increaseDelegation(address delegatee, uint256 addedValue) external;

    /**
     * @notice Decreases the borrow allowance of a user on the specific debt token.
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The amount to subtract from the current allowance
     */
    function decreaseDelegation(address delegatee, uint256 amount) external;

    /**
     * @notice Delegates borrowing power to a user on the specific debt token.
     * Delegation will still respect the liquidation constraints (even if delegated, a
     * delegatee cannot force a delegator HF to go below 1)
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The maximum amount being delegated.
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @notice Returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return The current allowance of `toUser`
     **/
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";
import {IAssetToken} from "./IAssetToken.sol";
import {ILiabilityToken} from "./ILiabilityToken.sol";
import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @title IGuild
 * @author Amorphous
 * @notice Defines the basic interface for a Guild.
 **/
interface IGuild {
    /**
     * @dev Emitted on deposit()
     * @param collateral The address of the collateral asset
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit
     * @param amount The amount supplied
     **/
    event Deposit(address indexed collateral, address user, address indexed onBehalfOf, uint256 amount);

    /**
     * @dev Emitted on withdraw()
     * @param collateral The address of the collateral asset
     * @param user The address initiating the withdrawal
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed collateral, address indexed user, address indexed to, uint256 amount);

    /**
     * @notice Returns the GuildAddressesProvider connected to this contract
     * @return The address of the GuildAddressesProvider
     **/
    function ADDRESSES_PROVIDER() external view returns (IGuildAddressesProvider);

    /**
     * @notice Refinances perpetual debt.
     * @dev Makes uniswap DEX call, and calculates TWAP price vs last time refinance was called.
     * Uses TWAP price to calculate interest rate in that period.
     **/
    function refinance() external;

    /**
     * @notice Supplies an `amount` of collateral into the Guild.
     * @param asset The address of the ERC20 asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that receives the collateral 'credit', same as msg.sender if the user
     *   wants it to account to their own wallet, or a different address if the beneficiary is someone else
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external;

    /**
     * @notice Withdraw an `amount` of underlying asset from the Guild.
     * @param asset The addres of the ERC20 asset to withdraw
     * @param amount The amount to be withdraw (in WADs if that's the collateral's precision)
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Initializes a perpetual debt.
     * @param assetTokenProxyAddress The proxy address of the underlying asset token contract (zToken)
     * @param liabilityTokenProxyAddress The proxy address of the underlying liability token contract (dToken)
     * @param moneyAddress The address of the money token on which the debt is denominated in
     * @param duration The duration, in seconds, of the perpetual debt
     * @param notionalPriceLimitMax Maximum price used for refinance purposes
     * @param notionalPriceLimitMin Minimum price used for refinance purposes
     * @param dexFactory Uniswap v3 Factory address
     * @param dexFee Uniswap v3 pool fee (to identify pool used for refinance oracle purposes)
     **/
    function initPerpetualDebt(
        address assetTokenProxyAddress,
        address liabilityTokenProxyAddress,
        address moneyAddress,
        uint256 duration,
        uint256 notionalPriceLimitMax,
        uint256 notionalPriceLimitMin,
        address dexFactory,
        uint24 dexFee
    ) external;

    /**
     * @notice Initializes a collateral, activating it, and configuring it's parameters
     * @dev Only callable by the GuildConfigurator contract
     * @param asset The address of the ERC20 collateral
     **/
    function initCollateral(address asset) external;

    /**
     * @notice Drop a collateral
     * @dev Only callable by the GuildConfigurator contract
     * @param asset The address of the ERC20 to drop as an acceptable collateral
     **/
    function dropCollateral(address asset) external;

    /**
     * @notice Sets the configuration bitmap of the collateral as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the ERC20 collateral
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(address asset, DataTypes.CollateralConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the collateral
     * @param asset The address of the ERC20 collateral
     * @return The configuration of the collateral
     **/
    function getCollateralConfiguration(address asset)
        external
        view
        returns (DataTypes.CollateralConfigurationMap memory);

    /**
     * @notice Returns the collateral balance of a user in the Guild
     * @param user The address of the user
     * @param asset The address of the collateral asset
     * @return The collateral amount deposited in the Guild
     **/
    function getCollateralBalanceOf(address user, address asset) external view returns (uint256);

    /**
     * @notice Returns the total collateral balance in the Guild
     * @param asset The address of the collateral asset
     * @return The total collateral amount deposited in the Guild
     **/
    function getCollateralTotalBalance(address asset) external view returns (uint256);

    /**
     * @notice Returns the list of all initialized collaterals
     * @dev It does not include dropped collaterals
     * @return The addresses of the initialized collaterals
     **/
    function getCollateralsList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying collateral by collateral id as stored in the DataTypes.CollateralData struct
     * @param id The id of the collateral as stored in the DataTypes.CollateralData struct
     * @return The address of the collateral associated with id
     **/
    function getCollateralAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the maximum number of collaterals supported by this Guild
     * @return The maximum number of collaterals supported
     */
    function maxNumberCollaterals() external view returns (uint16);

    /**
     * @notice Sets the configuration bitmap of the perpetual debt
     * @dev Only callable by the GuildConfigurator contract
     * @param configuration The new configuration bitmap
     **/
    function setPerpDebtConfiguration(DataTypes.PerpDebtConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the perpetual debt
     * @return The configuration of the perpetual debt
     **/
    function getPerpDebtConfiguration() external view returns (DataTypes.PerpDebtConfigurationMap memory);

    /**
     * @dev Emitted on borrow() when debt needs to be opened
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The zToken amount borrowed out
     * @param amountNotional The notional amount borrowed out (in Notional)
     **/
    event Borrow(address indexed user, address indexed onBehalfOf, uint256 amount, uint256 amountNotional);

    /**
     * @dev Emitted on repay()
     * @param user The address of the account whose zTokens are used to pay back the debt
     * @param onBehalfOf The address that will be getting the debt paid back
     * @param amount The zToken amount repaid
     * @param amountNotional The notional amount repaid (in Notional)
     **/
    event Repay(address indexed user, address indexed onBehalfOf, uint256 amount, uint256 amountNotional);

    /**
     * @dev Emitted on swapMoneyForZToken()
     * @param user The address of the account who is swapping money for ZToken (at 1:1 faceprice)
     * @param moneyIn The money amount swapped
     * @param zTokenOut The zToken amount received (including swap fees paid)
     **/
    event MoneyForZTokenSwap(address indexed user, uint256 moneyIn, uint256 zTokenOut);

    /**
     * @dev Emitted on swapZTokenForMoney()
     * @param user The address of the user who is swapping zToken for money (at 1:1 faceprice)
     * @param zTokenIn The zToken amount swapped
     * @param moneyOut The money amount received (including disribution fees)
     **/
    event ZTokenForMoneySwap(address indexed user, uint256 zTokenIn, uint256 moneyOut);

    /**
     * @notice Get money token
     **/
    function getMoney() external view returns (IERC20);

    /**
     * @notice Get asset token
     **/
    function getAsset() external view returns (IAssetToken);

    /**
     * @notice get liability token
     **/
    function getLiability() external view returns (ILiabilityToken);

    /**
     * @notice get perpetual debt data
     **/
    function getPerpetualDebt() external view returns (DataTypes.PerpetualDebtData memory);

    /**
     * @notice get DEX address from which the Guild derives refinance prices
     **/
    function getDex() external view returns (address);

    /**
     * @notice Updates notional price limits used during refinancing.
     * @dev Perpetual debt interest rates are proportional to 1/notionalPrice.
     * @param priceMin Minimum notional price to use for refinancing.
     * @param priceMax Maximum notional price to use for refinancing.
     **/
    function setPerpDebtNotionalPriceLimits(uint256 priceMax, uint256 priceMin) external;

    /**
     * @notice Updates the protocol service fee address where service fees are deposited
     * @param newAddress new protocol service fee address
     **/
    function setProtocolServiceFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol mint fee address where mint fees are deposited
     * @param newAddress new protocol mint fee address
     **/
    function setProtocolMintFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol distribution fee address where distribution fees are deposited
     * @param newAddress new protocol distribution fee address
     **/
    function setProtocolDistributionFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol swap fee address where distribution fees are deposited
     * @param newAddress new protocol swap fee address
     **/
    function setProtocolSwapFeeAddress(address newAddress) external;

    /**
     * @notice Allows users to borrow a specific `amount` of the zTokens, provided that the borrower
     * already supplied enough collateral.
     * @param amount The zToken amount to be borrowed
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance to msg.sender
     **/
    function borrow(uint256 amount, address onBehalfOf) external;

    /**
     * @notice Payback specific borrowed `amount`, which in turn burns the equivalent amount of dTokens
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param amount The zToken amount to be paid back
     * @return The final notional amount repaid
     **/
    function repay(uint256 amount, address onBehalfOf) external returns (uint256);

    /**
     * @notice Return structure for getUserAccountData function
     * @return totalCollateralInBaseCurrency The total collateral of the user in the base currency used by the price feed with a BORROW context
     * @return totalDebtNotionalInBaseCurrency The total debt of the user in the base currency used by the price feed with a BORROW context
     * @return availableBorrowsInBaseCurrency The borrowing power left of the user in the base currency used by the price feed
     * @return totalCollateralInBaseCurrencyForLiquidationTrigger The total collateral of the user in the base currency used by the price feed with a LIQUIDATION_TRIGGER context
     * @return currentLiquidationThreshold The liquidation threshold of the user with a price feed in the Liquidation Trigger Context
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     * @return totalDebt The total base debt of the user in the native dToken decimal unit
     * @return availableBorrowsInZTokens The total zTokens that can be minted given borrowing capacity
     * @return availableNotionalBorrows The total notional that can be minted given borrowing capacity
     * @return zTokensToRepayDebt The total zTokens required to repay the accounts totalDebtNotional (in native zToken decimal unit)
     **/
    struct UserAccountDataStruct {
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtNotionalInBaseCurrency;
        uint256 availableBorrowsInBaseCurrency;
        uint256 totalCollateralInBaseCurrencyForLiquidationTrigger;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 availableBorrowsInZTokens;
        uint256 availableNotionalBorrows;
        uint256 zTokensToRepayDebt;
    }

    /**
     * @notice Returns the user account data across all the collaterals
     * @param user The address of the user
     * @return userData User variables as per UserAccountDataStruct structure
     **/
    function getUserAccountData(address user) external view returns (UserAccountDataStruct memory userData);

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtNotionalToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset`in their wallet plus a bonus to cover market risk
     * @param collateralAsset The address of the collateral asset, to receive as result of the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt base amount the liquidator wants to cover (in dToken units)
     **/
    function liquidationCall(
        address collateralAsset,
        address user,
        uint256 debtToCover
    ) external;

    /**
     * @notice Executes validation of deposit() function, and reverts with same validation logic
     * @dev does not update on-chain state
     * @param asset The address of the ERC20 asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that receives the collateral 'credit', same as msg.sender if the user
     *   wants it to account to their own wallet, or a different address if the beneficiary is someone else
     **/
    function validateDeposit(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external view;

    /**
     * @notice Executes validation of withdraw() function, and reverts with same validation logic
     * @dev does not update on-chain state
     * @param asset The address of the ERC20 asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that receives the collateral 'withdrawal', same as msg.sender if the user
     *   wants it to account to their own wallet, or a different address if the beneficiary is someone else
     **/
    function validateWithdraw(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external view;

    /**
     * @notice Executes validation of borrow() function, and reverts with same validation logic
     * @param amount The zToken amount to be borrowed
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance to msg.sender
     **/
    function validateBorrow(uint256 amount, address onBehalfOf) external view;

    /**
     * @notice Executes validation of repay() function, and reverts with same validation logic
     * @param amount The zToken amount  to be paid back
     **/
    function validateRepay(uint256 amount) external view;

    /**
     * @notice Executes money for zToken swap at price = Notional Factor
     * @param moneyIn The money amount to swap in
     **/
    function swapMoneyForZToken(uint256 moneyIn) external returns (uint256);

    /**
     * @notice Executes zToken for money swap at price = Notional Factor
     * @param zTokenIn The money amount to swap in
     **/
    function swapZTokenForMoney(uint256 zTokenIn) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title IGuildAddressesProvider
 * @author Amorphous (cloned from AAVE core v3 commit d5fafce)
 * @notice Defines the basic interface for a Guild Addresses Provider.
 **/
interface IGuildAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldGuildId The old id of the market
     * @param newGuildId The new id of the market
     */
    event GuildIdSet(string indexed oldGuildId, string indexed newGuildId);

    /**
     * @dev Emitted when the Guild is updated.
     * @param oldAddress The old address of the Guild
     * @param newAddress The new address of the Guild
     */
    event GuildUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the Guild configurator is updated.
     * @param oldAddress The old address of the GuildConfigurator
     * @param newAddress The new address of the GuildConfigurator
     */
    event GuildConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the Guild data provider is updated.
     * @param oldAddress The old address of the GuildDataProvider
     * @param newAddress The new address of the GuildDataProvider
     */
    event GuildDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the GuildRoleManager is updated.
     * @param oldAddress The old address of the GuildRoleManager
     * @param newAddress The new address of the GuildRoleManager
     */
    event GuildRoleManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     **/
    function getGuildId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific GuildAddressesProvider.
     * @dev This can be used to create an onchain registry of GuildAddressesProviders to
     * identify and validate multiple Guilds.
     * @param newGuildId The market id
     */
    function setGuildId(string calldata newGuildId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Guild proxy.
     * @return The Guild proxy address
     **/
    function getGuild() external view returns (address);

    /**
     * @notice Updates the implementation of the Guild, or creates a proxy
     * setting the new `Guild` implementation when the function is called for the first time.
     * @param newGuildImpl The new Guild implementation
     **/
    function setGuildImpl(address newGuildImpl) external;

    /**
     * @notice Returns the address of the GuildConfigurator proxy.
     * @return The GuildConfigurator proxy address
     **/
    function getGuildConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the GuildConfigurator, or creates a proxy
     * setting the new `GuildConfigurator` implementation when the function is called for the first time.
     * @param newGuildConfiguratorImpl The new GuildConfigurator implementation
     **/
    function setGuildConfiguratorImpl(address newGuildConfiguratorImpl) external;

    /**
     * @notice Returns the address of the GuildRoleManager proxy.
     * @return The GuildRoleManager proxy address
     **/
    function getGuildRoleManager() external view returns (address);

    /**
     * @notice Updates the implementation of the GuildRoleManager, or creates a proxy
     * setting the new `GuildRoleManager` implementation when the function is called for the first time.
     * @param newGuildRoleManagerImpl The new GuildRoleManager implementation
     **/
    function setGuildRoleManagerImpl(address newGuildRoleManagerImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getGuildDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setGuildDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuild} from "./IGuild.sol";

/**
 * @title IInitializableAssetToken
 * @author Amorphous
 * @notice Interface for the initialize function on zToken
 **/
interface IInitializableAssetToken {
    /**
     * @dev Emitted when an aToken is initialized
     * @param guild The address of the associated guild
     * @param zTokenDecimals The decimals of the underlying
     * @param zTokenName The name of the zToken
     * @param zTokenSymbol The symbol of the zToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed guild,
        uint8 zTokenDecimals,
        string zTokenName,
        string zTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the zToken
     * @param guild The guild contract that is initializing this contract
     * @param zTokenDecimals The decimals of the zToken, same as the underlying asset's
     * @param zTokenName The name of the zToken
     * @param zTokenSymbol The symbol of the zToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IGuild guild,
        uint8 zTokenDecimals,
        string calldata zTokenName,
        string calldata zTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuild} from "./IGuild.sol";

/**
 * @title IInitializableLiabilityToken
 * @author Amorphous
 * @notice Interface for the initialize function on dToken
 **/
interface IInitializableLiabilityToken {
    /**
     * @dev Emitted when an aToken is initialized
     * @param guild The address of the associated guild
     * @param dTokenDecimals The decimals of the underlying
     * @param dTokenName The name of the dToken
     * @param dTokenSymbol The symbol of the dToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed guild,
        uint8 dTokenDecimals,
        string dTokenName,
        string dTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the dToken
     * @param guild The guild contract that is initializing this contract
     * @param dTokenDecimals The decimals of the zToken, same as the underlying asset's
     * @param dTokenName The name of the zToken
     * @param dTokenSymbol The symbol of the zToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IGuild guild,
        uint8 dTokenDecimals,
        string calldata dTokenName,
        string calldata dTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {INotionalERC20} from "./INotionalERC20.sol";
import {IInitializableLiabilityToken} from "./IInitializableLiabilityToken.sol";
import {ICreditDelegation} from "./ICreditDelegation.sol";

interface ILiabilityToken is IERC20, INotionalERC20, IInitializableLiabilityToken, ICreditDelegation {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param onBehalfOf The recipient of stable debt tokens
     * @param amount The amount minted
     **/
    event Mint(address indexed user, address indexed onBehalfOf, uint256 amount);

    /**
     * @notice Mints liability token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount
    ) external;

    function burn(address account, uint256 amount) external;

    function updateNotionalFactor(uint256 multFactor) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @dev Implementation of notional rebase functionality.
 *
 * Forms the basis of a notional ERC20 token, where the ERC20 interface is non-rebasing,
 * (ie, the quantities tracked by the ERC20 token are normalized), and here we create
 * functions that access the full 'rebased' quantities as a 'Notional' amount
 *
 **/
interface INotionalERC20 is IERC20 {
    event UpdateNotionalFactor(uint256 _value);

    function getNotionalFactor() external view returns (uint256); // @dev gets the Notional factor [ray]

    function totalNotionalSupply() external view returns (uint256);

    function balanceNotionalOf(address account) external view returns (uint256);

    function notionalToBase(uint256 amount) external view returns (uint256);

    function baseToNotional(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @author Covenant Labs
 * @notice Defines the error messages emitted by the different contracts of the Covenant protocol
 */
library Errors {
    string public constant LOCKED = "0"; // 'Guild is locked'
    string public constant NOT_CONTRACT = "1"; // 'Address is not a contract'
    string public constant AMOUNT_NEED_TO_BE_GREATER = "2"; // 'A greater amount needed for action'
    string public constant TRANSFER_FAIL = "3"; // 'Failed to transfer'
    string public constant NOT_APPROVED = "4"; // 'Not approved'
    string public constant NOT_ENOUGH_BALANCE = "5"; // 'Not enough balance'
    string public constant ASSET_NEEDS_TO_BE_APPROVED = "6"; // 'Asset needs to be whitelisted'
    string public constant OPERATION_NOT_SUPPORTED = "7"; // 'Operation not supported'
    string public constant OPERATION_NOT_AUTHORIZED = "8"; // 'Operation not authorized, not enough permissions for the operation'
    string public constant REFINANCE_INVALID_TIMESTAMP = "9"; // 'The current block has a timestamp that is older vs that last refinance'
    string public constant NOT_ENOUGH_COLLATERAL = "10"; // 'Not enough collateral'
    string public constant AMOUNT_NEED_TO_MORE_THAN_ZERO = "11"; // '"Your asset amount must be greater then you are trying to deposit"'
    string public constant CANNOT_BURN_MORE_THAN_CURRENT_DEBT = "12"; // "Amount exceeds current debt level"
    string public constant UNHEALTHY_POSITION = "13"; // Users position is currently higher than liquidation threshold
    string public constant CANNOT_LIQUIDATE_HEALTHY = "14"; // Cannot liqudate healthy users position
    string public constant WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE = "15"; // Amount exceeds max withdrawable amount
    string public constant HELPER_INSUFFICIENT_FUNDS = "16"; // Internal error, insufficient funds to place on dex as requested
    string public constant AMOUNT_NEEDS_TO_EQUAL_COLLATERAL_VALUE = "17"; // Amount needs to be the same to exchange money for collateral
    string public constant AMOUNT_NEEDS_TO_LOWER_THAN_DEBT = "18"; // Amount needs to be lower than current debt level
    string public constant NOT_ENOUGH_Z_TOKENS = "19"; // "Not enough zTokens in account"
    string public constant PRICE_LIMIT_OUT_OF_BOUNDS = "20"; // "PerpetualDebt.sol - price limit initialization out of bounds"
    string public constant PRICE_LIMIT_ERROR = "21"; // "PerpetualDebt.sol - price limit min larger than max"
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "22"; // "ACLManager.sol - cannot set a 0x0 address as admin"
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "23"; // "GuildAddressesProviderRegistry.sol - cannot set ID 0"
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "24"; // 'GuildAddressesProviderRegistry.sol - Guild addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER = "25"; // 'The address of the guild addresses provider is invalid'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "26"; // 'GuildAddressesProviderRegistry.sol - Reserve has already been added to collateral list'
    string public constant CALLER_NOT_GUILD_ADMIN = "27"; // 'The caller of the function is not a guild admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "28"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_GUILD_OR_EMERGENCY_ADMIN = "29"; // 'The caller of the function is not a guild or emergency admin'
    string public constant CALLER_NOT_RISK_OR_GUILD_ADMIN = "30"; // 'The caller of the function is not a risk or guild admin'
    string public constant TRANSFER_INVALID_SENDER = "31"; // 'ERC20: Cannot send from address 0'
    string public constant TRANSFER_INVALID_RECEIVER = "32"; // 'ERC20: Cannot send to address 0'
    string public constant CALLER_MUST_BE_GUILD = "33"; // 'The caller of the function must be the guild'
    string public constant GUILD_ADDRESSES_DO_NOT_MATCH = "34"; // 'Incorrect Guild address when initializing token'
    string public constant PERPETUAL_DEBT_ALREADY_INITIALIZED = "35"; // 'Perpetual Debt structure already initialized'
    string public constant DEX_ORACLE_ALREADY_INITIALIZED = "36"; // 'Dex Oracle structure already initialized'
    string public constant DEX_ORACLE_POOL_NOT_INITIALIZED = "37"; // 'Dex pool should be initialized before Dex oracle'
    string public constant CALLER_NOT_GUILD_CONFIGURATOR = "38"; // 'The caller of the function is not the guild configurator contract'
    string public constant COLLATERAL_ALREADY_ADDED = "39"; // 'Collateral has already been added to collateral list'
    string public constant NO_MORE_COLLATERALS_ALLOWED = "40"; // 'Maximum amount of collaterals in the guild reached'
    string public constant INVALID_LTV = "41"; // 'Invalid ltv parameter for the collateral'
    string public constant INVALID_LIQ_THRESHOLD = "42"; // 'Invalid liquidity threshold parameter for the collateral'
    string public constant INVALID_LIQ_BONUS = "43"; // 'Invalid liquidity bonus parameter for the collateral'
    string public constant INVALID_DECIMALS = "44"; // 'Invalid decimals parameter of the underlying asset of the collateral'
    string public constant INVALID_SUPPLY_CAP = "45"; // 'Invalid supply cap for the collateral'
    string public constant INVALID_PROTOCOL_DISTRIBUTION_FEE = "46"; // 'Invalid protocol distribution fee for the perpetual debt'
    string public constant ZERO_ADDRESS_NOT_VALID = "47"; // 'Zero address not valid'
    string public constant COLLATERAL_NOT_LISTED = "48"; // 'Collateral is not listed (not initialized or has been dropped)'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "49"; // 'The collateral balance is 0'
    string public constant LTV_VALIDATION_FAILED = "50"; // 'Ltv validation failed'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "51"; // 'Health factor is lower than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "52"; // 'There is not enough collateral to cover a new borrow'
    string public constant INVALID_COLLATERAL_PARAMS = "53"; //'Invalid risk parameters for the collateral'
    string public constant INVALID_AMOUNT = "54"; // 'Amount must be greater than 0'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "55"; //'User cannot withdraw more than the available balance'
    string public constant COLLATERAL_INACTIVE = "56"; //'Action requires an active collateral'
    string public constant SUPPLY_CAP_EXCEEDED = "57"; // 'Supply cap is exceeded'
    string public constant ACL_MANAGER_NOT_SET = "58"; // 'The ACL Manager has not been set for the addresses provider'
    string public constant ARRAY_SIZE_MISMATCH = "59"; // 'The arrays are of different sizes'
    string public constant DEX_POOL_DOES_NOT_CONTAIN_ASSET_PAIR = "60"; // 'The dex pool does not contain pricing info for token pair'
    string public constant ASSET_NOT_TRACKED_IN_ORACLE = "61"; // 'The asset is not tracked by the pricing oracle'
    string public constant INVALID_MINT_CAP = "62"; //  'Invalid mint cap for the perpetual debt'
    string public constant DEBT_PAUSED = "63"; //  'Action requires a non-paused debt'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "64"; // 'Action requires health factor to be below liquidation threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "65"; // 'The collateral chosen cannot be liquidated'
    string public constant USER_HAS_NO_DEBT = "66"; // 'User has no debt to be liquidated'
    string public constant INSUFFICIENT_CREDIT_DELEGATION = "67"; //  'Insufficient credit delegation to 3rd party borrower'
    string public constant INSUFFICIENT_TOKENIN_FOR_TARGET_TOKENOUT = "68"; //  'Insufficient tokenIn to swap for target tokenOut value'
    string public constant COLLATERAL_FROZEN = "69"; // 'Action cannot be performed because the collateral is frozen'
    string public constant COLLATERAL_PAUSED = "70"; // 'Action cannot be performed because the collateral is paused'
    string public constant PERPETUAL_DEBT_FROZEN = "71"; // 'Action cannot be performed because the perpetual debt is frozen'
    string public constant PERPETUAL_DEBT_PAUSED = "72"; // 'Action cannot be performed because the perpetual debt is paused'
    string public constant TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE = "73"; // 'Account does not have sufficient allowance to transfer on behalf of other account'
    string public constant NEGATIVE_ALLOWANCE_NOT_ALLOWED = "74"; // 'Cannot allocate negative value for allowances'
    string public constant INSUFFICIENT_BALANCE_TO_BURN = "75"; // 'Cannot burn more than amount in balance'
    string public constant TRANSFER_EXCEEDS_BALANCE = "76"; // 'ERC20: Transfer amount exceeds balance'
    string public constant PERPETUAL_DEBT_CAP_EXCEEDED = "77"; // 'Perpetual debt cap is exceeded'
    string public constant NEGATIVE_DELEGATION_NOT_ALLOWED = "78"; // 'Cannot allocate negative value for delegation allowances'
    string public constant ORACLE_LOOKBACKPERIOD_IS_ZERO = "79"; // 'Collateral oracle should have lookback period greater than 0'
    string public constant ORACLE_CARDINALITY_IS_ZERO = "80"; // 'Collateral oracle should have pool cardinality greater than 0'
    string public constant ORACLE_CARDINALITY_MONOTONICALLY_INCREASES = "81"; // The cardinality of the oracle is monotonically increasing and cannot bet lowered
    string public constant ORACLE_ASSET_MISMATCH = "82"; // Asset in oracle does not match proxy asset address
    string public constant ORACLE_BASE_CURRENCY_MISMATCH = "83"; // Base currency in oracle does not match proxy base currency address
    string public constant NO_ORACLE_PROXY_PRICE_SOURCE = "84"; // Oracle proxy does not have a price source
    string public constant CANNOT_BE_ZERO = "85"; // The value cannot be 0
    string public constant REQUIRES_OVERRIDE = "86"; // Function requires override
    string public constant GUILD_MISMATCH = "87"; // Function requires override
    string public constant ORACLE_PROXY_TOKENS_NOT_SET_PROPERLY = "88"; // Function requires override
    string public constant POSITIVE_COLLATERAL_BALANCE = "89"; // Cannot only perform action if guild balance is positive
    string public constant INVALID_ROLE = "90"; // Role exceeds MAX_LIMIT
    string public constant MAX_NUM_ROLES_EXCEEDED = "91"; // Role can't exceed MAX_NUM_OF_ROLES
    string public constant INVALID_PROTOCOL_SERVICE_FEE = "92"; // Protocol service fee larger than max allowed
    string public constant INVALID_PROTOCOL_MINT_FEE = "93"; // Protocol mint fee larger than max allowed
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "94"; // PriceOracleSentinel check failed
    string public constant LOOKBACK_PERIOD_IS_NOT_ZERO = "95"; // lookback period must be 0
    string public constant LOOKBACK_PERIOD_END_LT_START = "96"; // lookbackPeriodEnd can't be less than lookbackPeriodStart
    string public constant PRICE_CANNOT_BE_ZERO = "97"; // Oracle price cannot be zero
    string public constant INVALID_PROTOCOL_SWAP_FEE = "98"; // Protocol swap fee larger than max allowed
    string public constant COLLATERAL_CANNOT_COVER_EXISTING_BORROW = "99"; // 'Collateral remaining after withdrawal would not cover existing borrow'
    string public constant CALLER_NOT_GUILD_OR_GUILD_ADMIN = "A0"; // 'The caller of the function is not the guild or guild admin'
    string public constant NOT_ENOUGH_MONEY_IN_GUILD_TO_SWAP = "A1"; // 'There is not enough money in the Guild treasury for a successfull swap and debt burn'
    string public constant MONEY_DOES_NOT_MATCH = "A2"; // 'Guild or Oracle cannot be initialized with a Money token that differs from the other.
    string public constant ORACLE_ADDRESS_CANNOT_BE_ZERO = "A3"; // 'A valid address needs to be used when updating the Oracle
    string public constant ORACLE_NOT_SET = "A4"; // 'An oracle has not been registered with guildAddressProvider

    string public constant OWNABLE_ONLY_OWNER = "Ownable: caller is not the owner";
}

// SPDX-License-Identifier: MIT
// Notice: license change Jan 27, 2023
pragma solidity 0.8.17;

/**
 * @title WadRayMath library
 * @author Aave (not rayPow)
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return HALF_RAY;
    }

    function halfWad() internal pure returns (uint256) {
        return HALF_WAD;
    }

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
     */
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
     */
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
     */
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

    /**
     * @dev Calculates x to the power of n (x^n)
     * @dev Power calculated through a loop of binary powers.  Not optimized.
     * @param x ray
     * @param n unsigned integer
     * @return z x^n
     **/
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {ILiabilityToken} from "../../../interfaces/ILiabilityToken.sol";
import {IAssetToken} from "../../../interfaces/IAssetToken.sol";

library DataTypes {
    //@dev Uniswap requires the address of token0 < token1.
    //@dev All oracle prices by uniswap are given as a ratio of token0/token1.
    struct DexPoolData {
        address token0;
        address token1;
        uint24 fee;
        bool moneyIsToken0; //indicates whether token0 is the money token
        address poolAddress;
    }

    struct DexOracleData {
        address dexFactory; // Uniswap v3 factory
        DexPoolData dex; // Dex pool details
        uint256 currentPrice;
        uint256 twapPrice;
        uint256 lastTWAPObservationTime; // Timestamp of last oracle consult for TWAP price
        uint256 lastCurrentObservationTime; // Timestamp of last oracle consult for current price
        int56 lastTWAPTickCumulative; //For Uniswap v3.0 TWAP calculation
        uint256 lastTWAPTimeDelta; //recording of last time delta
    }

    struct PerpetualDebtData {
        //stores the perpetual debt configuration
        PerpDebtConfigurationMap configuration;
        //Token addresses
        IAssetToken zToken;
        ILiabilityToken dToken;
        IERC20 money;
        uint256 beta; //beta multiplier, indicating duration of debt instrument
        DexOracleData dexOracle; //Dex Oracle
        uint256 lastRefinance; //last refinance block number
        //Price limit variables when refinancing
        uint256 notionalPriceMax; //[ray]
        uint256 notionalPriceMin; //[ray]
        //protocol fees
        address protocolServiceFeeAddress; //protocol service fee address (address in which to mint debt service fee)
        address protocolMintFeeAddress; //protocol mint fee address (address in which to mint debt mint fee)
        address protocolDistributionFeeAddress; //protocol distribution fee address (address in which to mint debt service fee)
        address protocolSwapFeeAddress; //protocol swap fee address (address in which to mint debt service fee)
    }

    struct CollateralData {
        //stores the collateral configuration
        CollateralConfigurationMap configuration;
        //the id of the collateral. Represents the position in the list of the active ERC20 collaterals
        uint16 id;
        //map of user balances (for a given collateral)
        mapping(address => uint256) balances;
        //total collateral balance held by the Guild
        uint256 totalBalance;
        //map of user collateral prices at the time debt was last minted
        //@dev - only used if collateral configured as non-MTM
        mapping(address => uint256) lastMintPrice;
    }

    struct GuildTreasuryData {
        //stores the amount of money owned by the Guild Treasury
        uint256 moneyAmount;
    }

    struct CollateralConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: collateral is active
        //bit 57: collateral is frozen
        //bit 58: is non-MTM liquidation (collateral liquidation uses last mint price)
        //bit 59: unused
        //bit 60: collateral is paused
        //bit 61-115: unused
        //bit 81-151: user supply cap in 1/100 tokens, usersupplyCap == 0 => no cap
        //bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-255: unused

        uint256 data;
    }

    struct PerpDebtConfigurationMap {
        //bit 0: perpetual debt is paused (no mint, no burn/distribute, no liquidate, no refinance)
        //bit 1: perpetual debt is frozen (no mint, yes burn/distribute, yes liquidate, no refinance)
        //bit 2-37: mint cap in whole tokens, borrowCap ==0 => no cap
        //bit 38-47: unused
        //bit 48-63: protocol service fee (bps)
        //bit 64-79: protocol mint fee (bps)
        //bit 80-95: protocol distribution fee (bps)
        //bit 96-111: protocol swap fee (bps)
        //bit 112-255: unused

        uint256 data;
    }

    struct ExecuteDepositParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ExecuteSupplyParams {
        address collateral;
        uint256 amount;
        address user;
    }

    struct ExecuteBorrowParams {
        address user;
        address onBehalfOf;
        uint256 amount;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ExecuteRepayParams {
        address onBehalfOf;
        uint256 amount;
    }

    struct GetUserAccountDataParams {
        uint256 collateralsCount;
        address user;
        address oracle;
    }

    struct ExecuteInitPerpetualDebtParams {
        address assetTokenAddress;
        address liabilityTokenAddress;
        address moneyAddress;
        uint256 duration;
        uint256 notionalPriceLimitMax;
        uint256 notionalPriceLimitMin;
        address dexFactory;
        uint24 dexFee;
        address oracle;
    }

    struct CalculateUserAccountDataParams {
        uint256 collateralsCount;
        address user;
        address oracle;
        PriceContext priceContext;
    }

    struct ValidateBorrowParams {
        address user;
        uint256 amount;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        address eModePriceSource;
        address siloedBorrowingAddress;
    }

    struct ExecuteLiquidationCallParams {
        uint256 collateralsCount;
        uint256 debtToCover;
        address collateralAsset;
        address user;
        address priceOracle;
        address oracleSentinel;
    }

    struct ValidateLiquidationCallParams {
        uint256 totalDebt;
        uint256 healthFactor;
        address oracleSentinel;
    }

    struct ProxyStep {
        address assetToken;
        address baseToken;
        address proxySource;
    }

    struct PriceSourceData {
        address tokenA;
        address tokenB;
        address priceSource;
    }

    enum Roles {
        DEPOSITOR,
        WITHDRAWER,
        BORROWER,
        REPAYER
    }

    struct UserRolesData {
        // An array of mappings of user -> roles
        mapping(address => uint256) roles;
    }

    //@dev - not more than 255 price contexts to be used (8 bit encoding)
    enum PriceContext {
        BORROW,
        LIQUIDATION_TRIGGER,
        LIQUIDATION,
        FRONTEND
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing || isConstructor() || revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     **/
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {NotionalERC20} from "./base/NotionalERC20.sol";
import {IAssetToken} from "../../interfaces/IAssetToken.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../libraries/upgradeability/VersionedInitializable.sol";
import {IGuild} from "../../interfaces/IGuild.sol";
import {IInitializableAssetToken} from "../../interfaces/IInitializableAssetToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

/**
 * @title Covenant ERC20 AssetToken
 * @author Covenant Labs
 * @notice Implementation of the perpetual debt asset token
 */
contract AssetToken is VersionedInitializable, NotionalERC20, IAssetToken {
    uint256 public constant ASSET_TOKEN_REVISION = 0x1;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return ASSET_TOKEN_REVISION;
    }

    /**
     * @dev Constructor.
     * @param guild_ The address of the Guild contract
     **/
    constructor(IGuild guild_) NotionalERC20(guild_, "ZTOKEN_IMPL", "ZTOKEN_IMPL", 0) {
        // Intentionally left blank
    }

    /// @inheritdoc IInitializableAssetToken
    function initialize(
        IGuild initializingGuild,
        uint8 zTokenDecimals,
        string calldata zTokenName,
        string calldata zTokenSymbol,
        bytes calldata params
    ) external override initializer {
        require(initializingGuild == GUILD, Errors.GUILD_ADDRESSES_DO_NOT_MATCH);
        _name = string.concat("z", zTokenName);
        _symbol = string.concat("z", zTokenSymbol);
        _decimals = zTokenDecimals;
        _nFactor = WadRayMath.RAY;

        emit Initialized(address(GUILD), zTokenDecimals, zTokenName, zTokenSymbol, params);
    }

    function mint(address account, uint256 amount) external virtual override onlyGuild {
        return _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyGuild {
        return _burn(account, amount);
    }

    function updateNotionalFactor(uint256 multFactor) external onlyGuild returns (uint256) {
        return _updateNotionalFactor(multFactor);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title ERC20Storage
 * @author Covenant Labs
 * @notice Contract used as storage of the ERC20 contracts (both Asset and Liability Tokens).
 * @dev It defines the storage layout of the ERC20 contract.
 */
contract ERC20Storage {
    // Map of user balances
    mapping(address => uint256) internal _balances;

    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    // Reserved storage space to allow for layout changes in the future.
    uint256[10] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IGuild} from "../../../interfaces/IGuild.sol";
import {UpgradeableERC20} from "./UpgradeableERC20.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title MintableUpgradeableERC20
 * @author Covenant Labs, inspired by AAVE MintableIncentivizedERC20
 * @notice Implements mint and burn functions for UpgradeableERC20
 **/
abstract contract MintableUpgradeableERC20 is UpgradeableERC20 {
    /**
     * @dev Constructor.
     * @param guild The reference to the main Guild contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    constructor(
        IGuild guild,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) UpgradeableERC20(guild, name, symbol, decimals) {
        // Intentionally left blank
    }

    /**
     * @notice Mints tokens to an account
     * @param account The address receiving tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Burns tokens from an account
     * @param account The account whose tokens are burnt
     * @param amount The amount of tokens to burn
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(_balances[account] >= amount, Errors.INSUFFICIENT_BALANCE_TO_BURN);
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Covenant Contracts (last updated v0.2.0)

pragma solidity 0.8.17;

import {IGuild} from "../../../interfaces/IGuild.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {INotionalERC20} from "../../../interfaces/INotionalERC20.sol";
import {MintableUpgradeableERC20} from "./MintableUpgradeableERC20.sol";

/**
 * @dev Implementation of notional rebase functionality.
 * @author Covenant Labs
 * Forms the basis of a notional ERC20 token, where the ERC20 interface is non-rebasing,
 * (ie, the quantities tracked by the ERC20 token are normalized), and here we create
 * functions that access the full 'rebased' quantities as a 'Notional' amount
 *
 **/
contract NotionalERC20 is MintableUpgradeableERC20, INotionalERC20 {
    using WadRayMath for uint256;

    //Scale factor (used for Notional calculation)
    uint256 internal _nFactor;

    // Reserved storage space to allow for layout changes in the future.
    uint256[10] private ______gapNotionalERC20;

    /**
     * @dev Constructor.
     * @dev Initializes rebase factor to 1 (in RAY)
     * @param guild The reference to the main Guild contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    constructor(
        IGuild guild,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) MintableUpgradeableERC20(guild, name, symbol, decimals) {
        _nFactor = WadRayMath.RAY;
    }

    /**
     * @dev gets the Notional factor
     */
    function getNotionalFactor() public view virtual override returns (uint256) {
        return _nFactor;
    }

    /**
     * @dev updates the Notional factor through a multiplicative variable
     * @param multFactor  multiplicative factor
     * @return updatedFactor returns the new updated Notional factor
     */
    function _updateNotionalFactor(uint256 multFactor) internal virtual returns (uint256 updatedFactor) {
        _nFactor = _nFactor.rayMul(multFactor);
        emit UpdateNotionalFactor(_nFactor);
        return _nFactor;
    }

    /**
     * @dev convert from Base (normalized) amount to a Notional amount
     */
    function baseToNotional(uint256 amount) public view virtual returns (uint256) {
        return _baseToNotional(amount);
    }

    /**
     * @dev convert from Notional amount to Base (normalized) amount
     */
    function notionalToBase(uint256 amount) public view virtual returns (uint256) {
        return _notionalToBase(amount);
    }

    /**
     * @dev Returns the amount of tokens in existence, expressed in Notional units
     */
    function totalNotionalSupply() public view virtual override returns (uint256) {
        return _baseToNotional(_totalSupply);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`, expressed in Notional units
     */
    function balanceNotionalOf(address account) public view virtual override returns (uint256) {
        return _baseToNotional(_balances[account]);
    }

    /**
     * @dev convert from Base (normalized) amount to a Notional amount
     */
    function _baseToNotional(uint256 amount) internal view virtual returns (uint256) {
        return amount.rayMul(_nFactor);
    }

    /**
     * @dev convert from Notional amount to Base (normalized) amount
     */
    function _notionalToBase(uint256 amount) internal view virtual returns (uint256) {
        return amount.rayDiv(_nFactor);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Context} from "../../../dependencies/openzeppelin/contracts/Context.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20Detailed} from "../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IGuildAddressesProvider} from "../../../interfaces/IGuildAddressesProvider.sol";
import {IGuild} from "../../../interfaces/IGuild.sol";
import {IACLManager} from "../../../interfaces/IACLManager.sol";
import {ERC20Storage} from "./ERC20Storage.sol";

/**
 * @title UpgradeableERC20
 * @author Covenant Labs, inspired by the Openzeppelin ERC20, and AAVE IncentivizedERC20 implementation
 * @notice Basic ERC20 implementation
 **/
abstract contract UpgradeableERC20 is ERC20Storage, Context, IERC20Detailed {
    //Upgradeability and ownership variables (not stored in proxy given immutable)
    IGuildAddressesProvider internal immutable ADDRESSES_PROVIDER;
    IGuild public immutable GUILD;

    /**
     * @dev Only guild can call functions marked by this modifier.
     **/
    modifier onlyGuild() {
        require(_msgSender() == address(GUILD), Errors.CALLER_MUST_BE_GUILD);
        _;
    }

    /**
     * @dev Constructor.
     * @param guild The reference to the main Guild contract
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param decimals_ The number of decimals of the token
     */
    constructor(
        IGuild guild,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        ADDRESSES_PROVIDER = guild.ADDRESSES_PROVIDER();
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        GUILD = guild;
    }

    /// @inheritdoc IERC20Detailed
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Detailed
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Detailed
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, Errors.TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     **/
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @notice Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, Errors.NEGATIVE_ALLOWANCE_NOT_ALLOWED);
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /**
     * @notice Transfers tokens between two users.
     * @param sender The source address
     * @param recipient The destination address
     * @param amount The amount getting transferred
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(_balances[sender] >= amount, Errors.TRANSFER_EXCEEDS_BALANCE);
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Approve `spender` to use `amount` of `owner`s balance
     * @param owner The address owning the tokens
     * @param spender The address approved for spending
     * @param amount The amount of tokens to approve spending of
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}