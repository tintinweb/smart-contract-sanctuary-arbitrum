// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title AaveEModeHelper
 *
 * @author Fujidao Labs
 *
 * @notice Helper contract that aids to determine config Ids if a collateral
 * debt pair is eligible for Aave-v3 efficiency mode (e-mode).
 *
 * @dev This helper contract needs to be set-up.
 * To find the existing emode configuration Ids use
 * query schema:
 * {
 *  emodeCategories{
 *    id
 *      label
 *   }
 * }
 *
 * Refer to each chain subgraphs site at:
 * https://github.com/aave/protocol-subgraphs#production-networks
 */

import {IV3Pool} from "../interfaces/aaveV3/IV3Pool.sol";
import {SystemAccessControl, IChief} from "../access/SystemAccessControl.sol";

contract AaveEModeHelper is SystemAccessControl {
  // Events
  event EmodeConfigSet(address indexed asset, address indexed debt, uint8 configId);

  // Custom errors
  error AaveEModeHelper_constructor_addressZero();
  error AaveEModeHelper_setEModeConfig_arrayDiscrepancy();

  // collateral asset => debt asset => configId
  mapping(address => mapping(address => uint8)) internal _eModeConfigIds;

  constructor(address chief_) {
    if (chief_ == address(0)) revert AaveEModeHelper_constructor_addressZero();
    __SystemAccessControl_init(chief_);
  }

  /**
   * @notice Returns de config Id if any for asset-debt pair in AaveV3 pool.
   * It none, returns zero.
   *
   * @param asset erc-20 address of collateral
   * @param debt erc-20 address of debt asset
   */
  function getEModeConfigIds(address asset, address debt) external view returns (uint8 id) {
    return _eModeConfigIds[asset][debt];
  }

  /**
   * @notice Sets the configIds for an array of `assets` and `debts`
   *
   * @param assets erc-20 address array to set e-mode config
   * @param debts erc-20 address array corresponding asset in mapping
   * @param configIds from aaveV3 (refer to this contract title block)
   */
  function setEModeConfig(
    address[] calldata assets,
    address[] calldata debts,
    uint8[] calldata configIds
  )
    external
    onlyTimelock
  {
    uint256 len = assets.length;
    if (len != debts.length || len != configIds.length) {
      revert AaveEModeHelper_setEModeConfig_arrayDiscrepancy();
    }

    for (uint256 i = 0; i < len;) {
      if (configIds[i] != 0 && assets[i] != address(0) && debts[i] != address(0)) {
        _eModeConfigIds[assets[i]][debts[i]] = configIds[i];

        emit EmodeConfigSet(assets[i], debts[i], configIds[i]);
      }
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IV3Pool
 *
 * @author Aave
 *
 * @notice Defines the interface for AaveV3 main
 * pool contract.
 */
interface IV3Pool {
  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused
    uint256 data;
  }

  struct ReserveData {
    // Stores the reserve configuration
    ReserveConfigurationMap configuration;
    // The liquidity index. Expressed in ray.
    uint128 liquidityIndex;
    // The current supply rate. Expressed in ray.
    uint128 currentLiquidityRate;
    // Variable borrow index. Expressed in ray.
    uint128 variableBorrowIndex;
    // The current variable borrow rate. Expressed in ray.
    uint128 currentVariableBorrowRate;
    // The current stable borrow rate. Expressed in ray.
    uint128 currentStableBorrowRate;
    // Timestamp of last update.
    uint40 lastUpdateTimestamp;
    // The id of the reserve. Represents the position in the list of the active reserves.
    uint16 id;
    // aToken address.
    address aTokenAddress;
    // StableDebtToken address.
    address stableDebtTokenAddress;
    // VariableDebtToken address.
    address variableDebtTokenAddress;
    // Address of the interest rate strategy.
    address interestRateStrategyAddress;
    // The current treasury balance, scaled.
    uint128 accruedToTreasury;
    // The outstanding unbacked aTokens minted through the bridging feature.
    uint128 unbacked;
    // The outstanding debt borrowed against this asset in isolation mode.
    uint128 isolationModeTotalDebt;
  }

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   */
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   */
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  )
    external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   */
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  )
    external
    returns (uint256);

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   */
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://docs.aave.com/developers/
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  )
    external;

  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (ReserveData memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SystemAccessControl
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract that should be inherited by contract implementations that
 * call the {Chief} contract for access control checks.
 */

import {IChief} from "../interfaces/IChief.sol";
import {CoreRoles} from "./CoreRoles.sol";

contract SystemAccessControl is CoreRoles {
  /// @dev Custom Errors
  error SystemAccessControl__hasRole_missingRole(address caller, bytes32 role);
  error SystemAccessControl__onlyTimelock_callerIsNotTimelock();
  error SystemAccessControl__onlyHouseKeeper_notHouseKeeper();

  IChief public chief;

  /**
   * @dev Modifier that checks `caller` has `role`.
   */
  modifier hasRole(address caller, bytes32 role) {
    if (!chief.hasRole(role, caller)) {
      revert SystemAccessControl__hasRole_missingRole(caller, role);
    }
    _;
  }

  /**
   * @dev Modifier that checks `msg.sender` has HOUSE_KEEPER_ROLE.
   */
  modifier onlyHouseKeeper() {
    if (!chief.hasRole(HOUSE_KEEPER_ROLE, msg.sender)) {
      revert SystemAccessControl__onlyHouseKeeper_notHouseKeeper();
    }
    _;
  }

  /**
   * @dev Modifier that checks `msg.sender` is the defined `timelock` in {Chief}
   * contract.
   */
  modifier onlyTimelock() {
    if (msg.sender != chief.timelock()) {
      revert SystemAccessControl__onlyTimelock_callerIsNotTimelock();
    }
    _;
  }

  /**
   * @notice Init of a new {SystemAccessControl}.
   *
   * @param chief_ address
   *
   * @dev Requirements:
   * - Must pass non-zero {Chief} address, that could be checked at child contract.
   */
  function __SystemAccessControl_init(address chief_) internal {
    chief = IChief(chief_);
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
   * @notice Returns true if `vault` is active.
   *
   * @param vault to check status
   */
  function isVaultActive(address vault) external view returns (bool);

  /**
   * @notice Returns true if `flasher` is an allowed {IFlasher}.
   *
   * @param flasher address to check
   */
  function allowedFlasher(address flasher) external view returns (bool);

  /**
   * @notice Returns true if `swapper` is an allowed {ISwapper}.
   *
   * @param swapper address to check
   */
  function allowedSwapper(address swapper) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title CoreRoles
 *
 * @author Fujidao Labs
 *
 * @notice System definition of roles used across FujiV2 contracts.
 */

contract CoreRoles {
  bytes32 public constant HOUSE_KEEPER_ROLE = keccak256("HOUSE_KEEPER_ROLE");

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}

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