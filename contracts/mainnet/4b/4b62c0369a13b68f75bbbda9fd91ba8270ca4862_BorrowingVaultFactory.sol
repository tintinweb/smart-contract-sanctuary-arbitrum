// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title VaultDeployer
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract to be inherited by vault deployers
 * for whitelisted template factories.
 * This contract provides methods that facilitate information for
 * front-end applications.
 */

import {IChief} from "../interfaces/IChief.sol";

abstract contract VaultDeployer {
  /// @dev Custom Errors
  error VaultDeployer__onlyChief_notAuthorized();
  error VaultDeployer__onlyTimelock_notAuthorized();
  error VaultDeployer__zeroAddress();

  /**
   * @dev Emit when a vault is registered.
   *
   * @param vault address
   * @param asset address
   * @param salt used for address generation
   */
  event VaultRegistered(address vault, address asset, bytes32 salt);

  address public immutable chief;

  address[] public allVaults;
  mapping(address => address[]) public vaultsByAsset;
  mapping(bytes32 => address) public configAddress;

  modifier onlyChief() {
    if (msg.sender != chief) {
      revert VaultDeployer__onlyChief_notAuthorized();
    }
    _;
  }

  modifier onlyTimelock() {
    if (msg.sender != IChief(chief).timelock()) {
      revert VaultDeployer__onlyTimelock_notAuthorized();
    }
    _;
  }

  /**
   * @notice Abstract constructor of a new {VaultDeployer}.
   *
   * @param chief_ address
   *
   * @dev Requirements:
   * - Must pass non-zero {Chief} address, that could be checked at child contract.
   */
  constructor(address chief_) {
    if (chief_ == address(0)) {
      revert VaultDeployer__zeroAddress();
    }
    chief = chief_;
  }

  /**
   * @notice Returns the historic number of vaults of an `asset` type
   * deployed by this deployer.
   *
   * @param asset address
   */
  function vaultsCount(address asset) external view returns (uint256 count) {
    count = vaultsByAsset[asset].length;
  }

  /**
   * @notice Returns an array of vaults based on their `asset` type.
   *
   * @param asset address
   * @param startIndex number to start loop in vaults[] array
   * @param count number to end loop in vaults[] array
   */
  function getVaults(
    address asset,
    uint256 startIndex,
    uint256 count
  )
    external
    view
    returns (address[] memory vaults)
  {
    vaults = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      vaults[i] = vaultsByAsset[asset][startIndex + i];
    }
  }

  /**
   * @dev Registers a record of `vault` based on vault's `asset`.
   *
   * @param vault address
   * @param asset address of the vault
   */
  function _registerVault(address vault, address asset, bytes32 salt) internal onlyChief {
    // Store the address of the deployed contract.
    configAddress[salt] = vault;
    vaultsByAsset[asset].push(vault);
    allVaults.push(vault);
    emit VaultRegistered(vault, asset, salt);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IChief
 *
 * @author Fujidao Labs
 *
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  /// @notice Returns the timelock address of the FujiV2 system.
  function timelock() external view returns (address);

  /// @notice Returns the address mapper contract address of the FujiV2 system.
  function addrMapper() external view returns (address);

  /**
   * @notice Returns true if `flasher` is an allowed {IFlasher}.
   *
   * @param flasher address to check
   */
  function allowedFlasher(address flasher) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFujiOracle
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface of the {FujiOracle}.
 */

interface IFujiOracle {
  /**
   * @dev Emit when a change in price feed address is done for an `asset`.
   *
   * @param asset address
   * @param newPriceFeedAddress that returns USD price from Chainlink
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  /**
   * @notice Returns the exchange rate between two assets, with price oracle given in
   * specified `decimals`.
   *
   * @param currencyAsset to be used, zero-address for USD
   * @param commodityAsset to be used, zero-address for USD
   * @param decimals  of the desired price output
   *
   * @dev Price format is defined as: (currencyAsset per unit of commodityAsset Exchange Rate).
   * Requirements:
   * - Must check that both `currencyAsset` and `commodityAsset` are set in
   *   usdPriceFeeds, otherwise return zero.
   */
  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IVault} from "./IVault.sol";

/**
 * @title ILendingProvider
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 *
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface ILendingProvider {
  function providerName() external view returns (string memory);
  /**
   * @notice Returns the operator address that requires ERC20-approval for vault operations.
   *
   * @param keyAsset address to inquiry operator
   * @param asset address of the calling vault
   * @param debtAsset address of the calling vault. Note: if {YieldVault} this will be address(0).
   *
   * @dev Provider implementations may or not require all 3 inputs.
   */
  function approvedOperator(
    address keyAsset,
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
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf vault.
   *
   * @param amount amount to borrow
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function borrow(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount to withdraw
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IVault vault) external returns (bool success);

  /**
   *
   * @notice Performs payback operation at lending provider on behalf vault.
   *
   * @param amount amount to payback
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   * - Check there is erc20-approval to `approvedOperator` by the `vault` prior to call.
   */
  function payback(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getDepositBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getBorrowBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getDepositRateFor(IVault vault) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getBorrowRateFor(IVault vault) external view returns (uint256 rate);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVault
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for vaults extending from IERC4326.
 */

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {ILendingProvider} from "./ILendingProvider.sol";
import {IFujiOracle} from "./IFujiOracle.sol";

interface IVault is IERC4626 {
  /**
   * @dev Emit when borrow action occurs.
   *
   * @param sender who calls {IVault-borrow}
   * @param receiver of the borrowed 'debt' amount
   * @param owner who will incur the debt
   * @param debt amount
   * @param shares amount of 'debtShares' received
   */
  event Borrow(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 debt,
    uint256 shares
  );

  /**
   * @dev Emit when payback action occurs.
   *
   * @param sender address who calls {IVault-payback}
   * @param owner address whose debt will be reduced
   * @param debt amount
   * @param shares amound of 'debtShares' burned
   */
  event Payback(address indexed sender, address indexed owner, uint256 debt, uint256 shares);

  /**
   * @dev Emit when the oracle address is changed.
   *
   * @param newOracle the new oracle address
   */
  event OracleChanged(IFujiOracle newOracle);

  /**
   * @dev Emit when the available providers for the vault change.
   *
   * @param newProviders the new providers available
   */
  event ProvidersChanged(ILendingProvider[] newProviders);

  /**
   * @dev Emit when the active provider is changed.
   *
   * @param newActiveProvider the new active provider
   */
  event ActiveProviderChanged(ILendingProvider newActiveProvider);

  /**
   * @dev Emit when the vault is rebalanced.
   *
   * @param assets amount to be rebalanced
   * @param debt amount to be rebalanced
   * @param from provider
   * @param to provider
   */
  event VaultRebalance(uint256 assets, uint256 debt, address indexed from, address indexed to);

  /**
   * @dev Emit when the max LTV is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newMaxLtv the new max LTV
   */
  event MaxLtvChanged(uint256 newMaxLtv);

  /**
   * @dev Emit when the liquidation ratio is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newLiqRatio the new liquidation ratio
   */
  event LiqRatioChanged(uint256 newLiqRatio);

  /**
   * @dev Emit when the minumum amount is changed.
   *
   * @param newMinAmount the new minimum amount
   */
  event MinAmountChanged(uint256 newMinAmount);

  /**
   * @dev Emit when the deposit cap is changed.
   *
   * @param newDepositCap the new deposit cap of this vault
   */
  event DepositCapChanged(uint256 newDepositCap);

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

  /*///////////////////////////
    Debt management functions
  //////////////////////////*/

  /**
   * @notice Returns the decimals for 'debtAsset' of this vault.
   *
   * @dev Requirements:
   * - Must match the 'debtAsset' decimals in ERC20 token.
   * - Must return zero in a {YieldVault}.
   */
  function debtDecimals() external view returns (uint8);

  /**
   * @notice Returns the address of the underlying token used as debt in functions
   * `borrow()`, and `payback()`. Based on {IERC4626-asset}.
   *
   * @dev Requirements:
   * - Must be an ERC-20 token contract.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function debtAsset() external view returns (address);

  /**
   * @notice Returns the amount of debt owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebt(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the amount of `debtShares` owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebtShares(address owner) external view returns (uint256 debtShares);

  /**
   * @notice Returns the total amount of the underlying debt asset
   * that is “managed” by this vault. Based on {IERC4626-totalAssets}.
   *
   * @dev Requirements:
   * - Must account for any compounding occuring from yield or interest accrual.
   * - Must be inclusive of any fees that are charged against assets in the Vault.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function totalDebt() external view returns (uint256);

  /**
   * @notice Returns the amount of shares this vault would exchange for the amount
   * of debt assets provided. Based on {IERC4626-convertToShares}.
   *
   * @param debt to convert into `debtShares`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead Must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertDebtToShares(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt assets that this vault would exchange for the amount
   * of shares provided. Based on {IERC4626-convertToAssets}.
   *
   * @param shares amount to convert into `debt`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertToDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of the debt asset that can be borrowed for the `owner`,
   * through a borrow call. Based on {IERC4626-maxDeposit}.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must return a limited value if receiver is subject to some borrow limit.
   * - Must return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be borrowed.
   * - Must not revert.
   */
  function maxBorrow(address owner) external view returns (uint256);

  /**
   * @notice Perform a borrow action. Function inspired on {IERC4626-deposit}.
   *
   * @param debt amount
   * @param receiver of the `debt` amount
   * @param owner who will incur the `debt` amount
   *
   * * @dev Mints debtShares to owner by taking a loan of exact amount of underlying tokens.
   * Requirements:
   * - Must emit the Borrow event.
   * - Must revert if owner does not own sufficient collateral to back debt.
   * - Must revert if caller is not owner or permissioned operator to act on owner behalf.
   */
  function borrow(uint256 debt, address receiver, address owner) external returns (uint256);

  /**
   * @notice Burns `debtShares` to `receiver` by paying back loan with exact amount of underlying tokens.
   *
   * @param debt amount to payback
   * @param receiver to whom debt amount is being paid back
   *
   * @dev Implementations will require pre-erc20-approval of the underlying asset token.
   * Requirements:
   * - Must emit a Payback event.
   */
  function payback(uint256 debt, address receiver) external returns (uint256);

  /*///////////////////
    General functions
  ///////////////////*/

  /**
   * @notice Returns the active provider of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory);
  /**
   * @notice Returns the active provider of this vault.
   */
  function activeProvider() external view returns (ILendingProvider);

  /*/////////////////////////
     Rebalancing Function
  ////////////////////////*/

  /**
   * @notice Performs rebalancing of vault by moving funds across providers.
   *
   * @param assets amount of this vault to be rebalanced
   * @param debt amount of this vault to be rebalanced (Note: pass zero if this is a {YieldVault})
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
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    returns (bool);

  /*/////////////////////////
     Liquidation Functions
  /////////////////////////*/

  /**
   * @notice Returns the current health factor of 'owner'.
   *
   * @param owner to get health factor
   *
   * @dev Requirements:
   * - Must return type(uint254).max when 'owner' has no debt.
   * - Must revert in {YieldVault}.
   *
   * 'healthFactor' is scaled up by 1e18. A value below 1e18 means 'owner' is eligable for liquidation.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   */
  function getHealthFactor(address owner) external returns (uint256 healthFactor);

  /**
   * @notice Returns the liquidation close factor based on 'owner's' health factor.
   *
   * @param owner of debt position
   *
   * @dev Requirements:
   * - Must return zero if `owner` is not liquidatable.
   * - Must revert in {YieldVault}.
   */
  function getLiquidationFactor(address owner) external returns (uint256 liquidationFactor);

  /**
   * @notice Performs liquidation of an unhealthy position, meaning a 'healthFactor' below 100.
   *
   * @param owner to be liquidated
   * @param receiver of the collateral shares of liquidation
   *
   * @dev Requirements:
   * - Must revert if caller is not an approved liquidator.
   * - Must revert if 'owner' is not liquidatable.
   * - Must emit the Liquidation event.
   * - Must liquidate 50% of 'owner' debt when: 100 >= 'healthFactor' > 95.
   * - Must liquidate 100% of 'owner' debt when: 95 > 'healthFactor'.
   * - Must revert in {YieldVault}.
   *
   * WARNING! It is liquidator's responsability to check if liquidation is profitable.
   */
  function liquidate(address owner, address receiver) external returns (uint256 gainedShares);

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
  function setProviders(ILendingProvider[] memory providers) external;

  /**
   * @notice Sets the active provider for this vault.
   *
   * @param activeProvider address
   *
   * @dev Requirements:
   * - Must be a provider previously set by `setProviders()`.
   * - Must be called from a timelock contract.
   *
   * WARNING! Changing active provider without a `rebalance()` call
   * can result in denial of service for vault users.
   */
  function setActiveProvider(ILendingProvider activeProvider) external;

  /**
   * @notice Sets the minimum amount for: `deposit()`, `mint()` and borrow()`.
   *
   * @param amount to be as minimum.
   */
  function setMinAmount(uint256 amount) external;

  /**
   * @notice Sets the deposit cap amount of this vault.
   *
   * @param newCap amount to be set
   *
   * @dev Requirements:
   * - Must be greater than zero.
   */
  function setDepositCap(uint256 newCap) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/*
 * @title LibBytes

 * @author Gonçalo Sá <[email protected]>
 *
 * @notice Utility library for ethereum contracts written in Solidity.
 * The library lets you concatenate, slice and type cast bytes arrays 
 * both in memory and storage. Taken from:
 * https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol.
 */
library LibBytes {
  function concat(
    bytes memory _preBytes,
    bytes memory _postBytes
  )
    internal
    pure
    returns (bytes memory)
  {
    bytes memory tempBytes;

    assembly {
      /**
       * @dev Get a location of some free memory and store it in tempBytes as
       * Solidity does for memory variables.
       */
      tempBytes := mload(0x40)

      /**
       * @dev Store the length of the first bytes array at the beginning of
       * the memory for tempBytes.
       */
      let length := mload(_preBytes)
      mstore(tempBytes, length)

      /**
       * @dev Maintain a memory counter for the current write location in the
       * temp bytes array by adding the 32 bytes for the array length to
       * the starting location.
       */
      let mc := add(tempBytes, 0x20)
      // Stop copying when the memory counter reaches the length of the first bytes array.
      let end := add(mc, length)

      for {
        // Initialize a copy counter to the start of the _preBytes data, 32 bytes into its memory.
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
        // Increase both counters by 32 bytes each iteration.
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        // Write the _preBytes data into the tempBytes memory 32 bytes at a time.
        mstore(mc, mload(cc))
      }

      /**
       * @dev Add the length of _postBytes to the current length of tempBytes
       * and store it as the new length in the first 32 bytes of the
       * tempBytes memory.
       */
      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

      // Move the memory counter back from a multiple of 0x20 to the  actual end of the _preBytes data.
      mc := end
      // Stop copying when the memory counter reaches the new combined length of the arrays.
      end := add(mc, length)

      for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } { mstore(mc, mload(cc)) }

      /**
       * @dev Update the free-memory pointer by padding our last write location
       * to 32 bytes: add 31 bytes to the end of tempBytes to move to the
       * next 32 byte block, then round down to the nearest multiple of
       * 32. If the sum of the length of the two arrays is zero then add
       * one before rounding down to leave a blank 32 bytes (the length block with 0).
       */
      mstore(
        0x40,
        and(
          add(add(end, iszero(add(length, mload(_preBytes)))), 31),
          // Round down to the nearest 32 bytes.
          not(31)
        )
      )
    }

    return tempBytes;
  }

  function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
    assembly {
      /**
       * @dev Read the first 32 bytes of _preBytes storage, which is the length
       * of the array. (We don't need to use the offset into the slot
       * because arrays use the entire slot.)
       */
      let fslot := sload(_preBytes.slot)
      /**
       * @dev Arrays of 31 bytes or less have an even value in their slot,
       * while longer arrays have an odd value. The actual length is
       * the slot divided by two for odd values, and the lowest order
       * byte divided by two for even values.
       * If the slot is even, bitwise and the slot with 255 and divide by
       * two to get the length. If the slot is odd, bitwise and the slot
       * with -1 and divide by two.
       */
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)
      let newlength := add(slength, mlength)

      /**
       * @dev // slength can contain both the length and contents of the array
       * if length < 32 bytes so let's prepare for that
       * v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
       */
      switch add(lt(slength, 32), lt(newlength, 32))
      case 2 {
        /**
         * @dev Since the new array still fits in the slot, we just need to
         * update the contents of the slot.
         * uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
         */
        sstore(
          _preBytes.slot,
          // All the modifications to the slot are inside this next block
          add(
            // we can just add to the slot contents because the bytes we want to change are the LSBs
            fslot,
            add(
              mul(
                div(
                  // load the bytes from memory.
                  mload(add(_postBytes, 0x20)),
                  // Zero all bytes to the right.
                  exp(0x100, sub(32, mlength))
                ),
                // Now shift left the number of bytes to leave space for the length in the slot.
                exp(0x100, sub(32, newlength))
              ),
              // Increase length by the double of the memory bytes length.
              mul(mlength, 2)
            )
          )
        )
      }
      case 1 {
        /**
         * @dev The stored value fits in the slot, but the combined value
         * will exceed it. Get the keccak hash to get the contents of the array.
         */
        mstore(0x0, _preBytes.slot)
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // Save new length.
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        /**
         * @dev The contents of the _postBytes array start 32 bytes into
         * the structure. Our first read should obtain the `submod`
         * bytes that can fit into the unused space in the last word
         * of the stored array. To get this, we read 32 bytes starting
         * from `submod`, so the data we read overlaps with the array
         * contents by `submod` bytes. Masking the lowest-order
         * `submod` bytes allows us to add that value directly to the
         * stored value.
         */
        let submod := sub(32, slength)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(
          sc,
          add(
            and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
            and(mload(mc), mask)
          )
        )

        for {
          mc := add(mc, 0x20)
          sc := add(sc, 1)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } { sstore(sc, mload(mc)) }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
      default {
        // Get the keccak hash to get the contents of the array.
        mstore(0x0, _preBytes.slot)
        // Start copying to the last used word of the stored array.
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // Save new length.
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // Copy over the first `submod` bytes of the new data as in case 1 above.
        let slengthmod := mod(slength, 32)
        let mlengthmod := mod(mlength, 32)
        let submod := sub(32, slengthmod)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(sc, add(sload(sc), and(mload(mc), mask)))

        for {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } { sstore(sc, mload(mc)) }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
    }
  }

  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  )
    internal
    pure
    returns (bytes memory)
  {
    require(_length + 31 >= _length, "slice_overflow");
    require(_bytes.length >= _start + _length, "slice_outOfBounds");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as Solidity does for memory variables.
        tempBytes := mload(0x40)

        /**
         * @dev The first word of the slice result is potentially a partial
         * word read from the original array. To read it, we calculate
         * the length of that partial word and start copying that many
         * bytes into the array. The first word we copy will start with
         * data we don't care about, but the last `lengthmod` bytes will
         * land at the beginning of the contents of the new array. When
         * we're done copying, we overwrite the full first word with
         * the actual length of the slice.
         */
        let lengthmod := and(_length, 31)

        /**
         * @dev The multiplication in the next line is necessary
         * because when slicing multiples of 32 bytes (lengthmod == 0)
         * the following copy loop was copying the origin's length
         * and then ending prematurely not copying everything it should.
         */
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } { mstore(mc, mload(cc)) }

        mstore(tempBytes, _length)

        // Update free-memory pointer allocating the array padded to 32 bytes like the compiler does now.
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      // If we want a zero-length slice let's just return a zero-length array.
      default {
        tempBytes := mload(0x40)
        // Zero out the 32 bytes slice we are about to return we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
    require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
    uint8 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x1), _start))
    }

    return tempUint;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }

    return tempUint;
  }

  function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
    require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
    uint32 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x4), _start))
    }

    return tempUint;
  }

  function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
    require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
    uint64 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x8), _start))
    }

    return tempUint;
  }

  function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
    require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
    uint96 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0xc), _start))
    }

    return tempUint;
  }

  function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
    require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
    uint128 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x10), _start))
    }

    return tempUint;
  }

  function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
    require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
    require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
    bytes32 tempBytes32;

    assembly {
      tempBytes32 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes32;
  }

  function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
    bool success = true;

    assembly {
      let length := mload(_preBytes)

      // If lengths don't match the arrays are not equal
      switch eq(length, mload(_postBytes))
      case 1 {
        /**
         * @dev cb is a circuit breaker in the for loop since there's
         * no said feature for inline assembly loops
         * cb = 1 - don't breaker
         * cb = 0 - break
         */
        let cb := 1

        let mc := add(_preBytes, 0x20)
        let end := add(mc, length)

        for { let cc := add(_postBytes, 0x20) }
        // The next line is the loop condition: while(uint256(mc < end) + cb == 2).
        eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          // If any of these checks fails then arrays are not equal.
          if iszero(eq(mload(mc), mload(cc))) {
            // Unsuccess:
            success := 0
            cb := 0
          }
        }
      }
      default {
        // Unsuccess:
        success := 0
      }
    }

    return success;
  }

  function equalStorage(
    bytes storage _preBytes,
    bytes memory _postBytes
  )
    internal
    view
    returns (bool)
  {
    bool success = true;

    assembly {
      // We know _preBytes_offset is 0.
      let fslot := sload(_preBytes.slot)
      // Decode the length of the stored array like in concatStorage().
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)

      // If lengths don't match the arrays are not equal.
      switch eq(slength, mlength)
      case 1 {
        /**
         * @dev Slength can contain both the length and contents of the array
         * if length < 32 bytes so let's prepare for that
         * v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
         */
        if iszero(iszero(slength)) {
          switch lt(slength, 32)
          case 1 {
            // Blank the last byte which is the length.
            fslot := mul(div(fslot, 0x100), 0x100)

            if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
              // Unsuccess:
              success := 0
            }
          }
          default {
            /**
             * @dev cb is a circuit breaker in the for loop since there's
             * no said feature for inline assembly loops
             * cb = 1 - don't breaker
             * cb = 0 - break
             */
            let cb := 1

            // Get the keccak hash to get the contents of the array.
            mstore(0x0, _preBytes.slot)
            let sc := keccak256(0x0, 0x20)

            let mc := add(_postBytes, 0x20)
            let end := add(mc, mlength)

            // The next line is the loop condition: while(uint256(mc < end) + cb == 2)
            for {} eq(add(lt(mc, end), cb), 2) {
              sc := add(sc, 1)
              mc := add(mc, 0x20)
            } {
              if iszero(eq(sload(sc), mload(mc))) {
                // Unsuccess:
                success := 0
                cb := 0
              }
            }
          }
        }
      }
      default {
        // Unsuccess:
        success := 0
      }
    }

    return success;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title LibSSTORE2
 *
 * @author Solmate, modified from 0xSequence
 *
 * @notice Read and write to persistent storage at a fraction of the cost.
 * Refer to (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol),
 * and (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol).
 */

library LibSSTORE2 {
  // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.
  uint256 internal constant DATA_OFFSET = 1;

  /*////////////////
     WRITE LOGIC
  ////////////////*/

  function write(bytes memory data) internal returns (address pointer) {
    // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
    bytes memory runtimeCode = abi.encodePacked(hex"00", data);

    bytes memory creationCode = abi.encodePacked(
      /**
       * @dev
       * //---------------------------------------------------------------------------------------------------------------//
       * // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
       * //---------------------------------------------------------------------------------------------------------------//
       * // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
       * // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
       * // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
       * // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
       * // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
       * // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
       * // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
       * // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
       * // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
       * // 0xf3    |  0xf3               | RETURN       |                                                                //
       * //---------------------------------------------------------------------------------------------------------------//
       */
      hex"600B5981380380925939F3",
      // Returns all code in the contract except for the first 11 (0B in hex) bytes.
      runtimeCode
    );

    /// @solidity memory-safe-assembly
    assembly {
      // Deploy a new contract with the generated creation code. We start 32 bytes into the code to avoid copying the byte length.
      pointer := create(0, add(creationCode, 32), mload(creationCode))
    }

    require(pointer != address(0), "DEPLOYMENT_FAILED");
  }

  /*////////////////
     READ LOGIC
  ////////////////*/

  function read(address pointer) internal view returns (bytes memory) {
    return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
  }

  function read(address pointer, uint256 start) internal view returns (bytes memory) {
    start += DATA_OFFSET;

    return readBytecode(pointer, start, pointer.code.length - start);
  }

  function read(address pointer, uint256 start, uint256 end) internal view returns (bytes memory) {
    start += DATA_OFFSET;
    end += DATA_OFFSET;

    require(pointer.code.length >= end, "OUT_OF_BOUNDS");

    return readBytecode(pointer, start, end - start);
  }

  /*//////////////////////////
     INTERNAL HELPER LOGIC
  //////////////////////////*/

  function readBytecode(
    address pointer,
    uint256 start,
    uint256 size
  )
    private
    view
    returns (bytes memory data)
  {
    /// @solidity memory-safe-assembly
    assembly {
      // Get a pointer to some free memory.
      data := mload(0x40)

      /**
       * @dev Update the free memory pointer to prevent overriding our data.
       * We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
       * Adding 31 to size and running the result through the logic above ensures
       * he memory pointer remains word-aligned, following the Solidity convention.
       */
      mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

      // Store the size of the data in the first 32 byte chunk of free memory.
      mstore(data, size)

      // Copy the code into memory right after the 32 bytes we used to store the size.
      extcodecopy(pointer, add(data, 32), start, size)
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BorrowingVaultFactory
 *
 * @author Fujidao Labs
 *
 * @notice A factory contract through which new borrowing vaults are created.
 * The BorrowingVault contract is quite big in size. Creating new instances of it with
 * `new BorrowingVault()` makes the factory contract exceed the 24K limit. That's why
 * we use an approach found at Fraxlend. We split and store the BorrowingVault bytecode
 * in two different locations and when used they get concatanated and deployed by using assembly.
 * ref: https://github.com/FraxFinance/fraxlend/blob/main/src/contracts/FraxlendPairDeployer.sol
 */

import {VaultDeployer} from "../../abstracts/VaultDeployer.sol";
import {LibSSTORE2} from "../../libraries/LibSSTORE2.sol";
import {LibBytes} from "../../libraries/LibBytes.sol";
import {IERC20Metadata} from
  "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";

contract BorrowingVaultFactory is VaultDeployer {
  /// @dev Custom Errors
  error BorrowingVaultFactory__deployVault_failed();

  event DeployBorrowingVault(
    address indexed vault,
    address indexed asset,
    address indexed debtAsset,
    string name,
    string symbol,
    bytes32 salt
  );

  uint256 public nonce;

  address private _creationAddress1;
  address private _creationAddress2;

  /**
   * @notice Constructor of a new {BorrowingVaultFactory}.
   *
   * @param chief_ address of {Chief}
   *
   * @dev Requirements:
   * - Must comply with {VaultDeployer} requirements.
   */
  constructor(address chief_) VaultDeployer(chief_) {}

  /**
   * @notice Deploys a new {BorrowingVault}.
   *
   * @param deployData The encoded data containing asset, debtAsset, oracle and providers
   *
   * @dev Requirements:
   * - Must be called from {Chief} contract only.
   */
  function deployVault(bytes memory deployData) external onlyChief returns (address vault) {
    (address asset, address debtAsset, address oracle, ILendingProvider[] memory providers) =
      abi.decode(deployData, (address, address, address, ILendingProvider[]));

    string memory assetSymbol = IERC20Metadata(asset).symbol();
    string memory debtSymbol = IERC20Metadata(debtAsset).symbol();

    // Example of `name_`: "Fuji-V2 WETH-DAI BorrowingVault".
    string memory name =
      string(abi.encodePacked("Fuji-V2 ", assetSymbol, "-", debtSymbol, " BorrowingVault"));
    // Example of `symbol_`: "fbvWETHDAI".
    string memory symbol = string(abi.encodePacked("fbv", assetSymbol, debtSymbol));

    bytes32 salt = keccak256(abi.encode(deployData, nonce));
    nonce++;

    bytes memory creationCode =
      LibBytes.concat(LibSSTORE2.read(_creationAddress1), LibSSTORE2.read(_creationAddress2));

    bytes memory bytecode = abi.encodePacked(
      creationCode, abi.encode(asset, debtAsset, oracle, chief, name, symbol, providers)
    );

    assembly {
      vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    if (vault == address(0)) revert BorrowingVaultFactory__deployVault_failed();

    _registerVault(vault, asset, salt);

    emit DeployBorrowingVault(vault, asset, debtAsset, name, symbol, salt);
  }

  /**
   * @notice Sets the bytecode for the BorrowingVault.
   *
   * @param creationCode The creationCode for the vault contracts
   *
   * @dev Requirements:
   * - Must be called from a timelock.
   */
  function setContractCode(bytes calldata creationCode) external onlyTimelock {
    bytes memory firstHalf = LibBytes.slice(creationCode, 0, 13000);
    _creationAddress1 = LibSSTORE2.write(firstHalf);
    if (creationCode.length > 13000) {
      bytes memory secondHalf = LibBytes.slice(creationCode, 13000, creationCode.length - 13000);
      _creationAddress2 = LibSSTORE2.write(secondHalf);
    }
  }
}