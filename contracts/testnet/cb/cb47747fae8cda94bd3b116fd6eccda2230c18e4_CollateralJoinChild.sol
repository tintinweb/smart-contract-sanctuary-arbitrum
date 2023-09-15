// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ICollateralJoinChild} from '@interfaces/factories/ICollateralJoinChild.sol';

import {CollateralJoin} from '@contracts/utils/CollateralJoin.sol';

import {DisableableChild, Disableable} from '@contracts/factories/DisableableChild.sol';

/**
 * @title  CollateralJoinChild
 * @notice This contract inherits all the functionality of CollateralJoin to be factory deployed
 */
contract CollateralJoinChild is CollateralJoin, DisableableChild, ICollateralJoinChild {
  // --- Init ---

  /**
   * @param  _safeEngine Address of the SafeEngine contract
   * @param  _cType      Bytes32 representation of the collateral type
   * @param  _collateral Address of the ERC20 collateral token
   */
  constructor(
    address _safeEngine,
    bytes32 _cType,
    address _collateral
  ) CollateralJoin(_safeEngine, _cType, _collateral) {}

  // --- Overrides ---

  /// @inheritdoc DisableableChild
  function _isEnabled() internal view override(DisableableChild, Disableable) returns (bool _enabled) {
    return super._isEnabled();
  }

  /// @inheritdoc DisableableChild
  function _onContractDisable() internal override(DisableableChild, Disableable) {
    super._onContractDisable();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ICollateralJoin} from '@interfaces/utils/ICollateralJoin.sol';

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

interface ICollateralJoinChild is ICollateralJoin, IFactoryChild {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ICollateralJoin} from '@interfaces/utils/ICollateralJoin.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {IERC20Metadata} from '@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';
import {Disableable} from '@contracts/utils/Disableable.sol';

import {Math} from '@libraries/Math.sol';
import {SafeERC20} from '@openzeppelin/token/ERC20/utils/SafeERC20.sol';

import {Assertions} from '@libraries/Assertions.sol';

/**
 * @title  CollateralJoin
 * @notice This contract allows to connect the SAFEEngine to arbitrary external token implementations
 * @dev    For well behaved ERC20 tokens with less than 18 decimals.
 *         All Join adapters need to implement two basic methods: `join` and `exit`
 */
contract CollateralJoin is Disableable, ICollateralJoin {
  using Math for uint256;
  using SafeERC20 for IERC20Metadata;
  using Assertions for address;

  // --- Registry ---

  /// @inheritdoc ICollateralJoin
  ISAFEEngine public safeEngine;
  /// @inheritdoc ICollateralJoin
  IERC20Metadata public collateral;

  // --- Data ---

  /// @inheritdoc ICollateralJoin
  bytes32 public collateralType;
  /// @inheritdoc ICollateralJoin
  uint256 public decimals;
  /// @inheritdoc ICollateralJoin
  uint256 public multiplier;

  // --- Init ---

  /**
   *
   * @param  _safeEngine Address of the SAFEEngine contract
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _collateral Address of the ERC20 collateral token
   */
  constructor(address _safeEngine, bytes32 _cType, address _collateral) Authorizable(msg.sender) {
    safeEngine = ISAFEEngine(_safeEngine.assertNonNull());
    collateralType = _cType;
    collateral = IERC20Metadata(_collateral);
    decimals = collateral.decimals();
    // NOTE: assumes collateral token has <= 18 decimals
    multiplier = 18 - decimals;
  }

  // --- Methods ---

  /**
   * @dev This function locks collateral in the adapter and creates a representation of
   *      the locked collateral inside the system. The representation uses 18 decimals.
   * @inheritdoc ICollateralJoin
   */
  function join(address _account, uint256 _wei) external whenEnabled {
    collateral.safeTransferFrom(msg.sender, address(this), _wei);
    uint256 _wad = _wei * 10 ** multiplier; // convert to 18 decimals [wad]
    safeEngine.modifyCollateralBalance(collateralType, _account, _wad.toInt());
    emit Join(msg.sender, _account, _wad);
  }

  /**
   * @dev This function destroys the collateral representation from inside the system
   *      and exits the collateral from this adapter. The transferred collateral uses
   *      the same decimals as the original collateral token.
   * @inheritdoc ICollateralJoin
   */
  function exit(address _account, uint256 _wei) external {
    collateral.safeTransfer(_account, _wei);
    uint256 _wad = _wei * 10 ** multiplier; // convert to 18 decimals [wad]
    safeEngine.modifyCollateralBalance(collateralType, msg.sender, -_wad.toInt());
    emit Exit(msg.sender, _account, _wad);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDisableableChild} from '@interfaces/factories/IDisableableChild.sol';

import {Disableable, IDisableable} from '@contracts/utils/Disableable.sol';

import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

/**
 * @title  DisableableChild
 * @notice This abstract contract is used to disable Disableable children contracts through a parent factory
 */
abstract contract DisableableChild is Disableable, FactoryChild, IDisableableChild {
  // --- Overrides ---

  /**
   * @dev    Method override to check for contract enablement also in the parent factory
   * @return _enabled Whether the contract and the factory are enabled or not
   * @inheritdoc Disableable
   */
  function _isEnabled() internal view virtual override returns (bool _enabled) {
    return super._isEnabled() && IDisableable(factory).contractEnabled();
  }

  /**
   * @dev    Method override to allow disabling contract only through the parent factory
   * @inheritdoc Disableable
   */
  function _onContractDisable() internal virtual override onlyFactory {
    super._onContractDisable();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {IERC20Metadata} from '@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface ICollateralJoin is IAuthorizable, IDisableable {
  // --- Events ---

  /**
   * @notice Emitted when an account joins collateral tokens into the system
   * @param _sender Address of the account that called the function (sent the ERC20 collateral tokens)
   * @param _account Address of the account that received the collateral tokens
   * @param _wad Amount of collateral tokens joined [wad]
   */
  event Join(address _sender, address _account, uint256 _wad);

  /**
   * @notice Emitted when an account exits collateral tokens from the system
   * @param _sender Address of the account that called the function (sent the internal collateral tokens)
   * @param _account Address of the account that received the ERC20 collateral tokens
   * @param _wad Amount of collateral tokens exited [wad]
   */
  event Exit(address _sender, address _account, uint256 _wad);

  // --- Registry ---

  /// @notice Address of the SAFEEngine contract
  function safeEngine() external view returns (ISAFEEngine _safeEngine);

  /// @notice Address of the ERC20 collateral token contract
  function collateral() external view returns (IERC20Metadata _collateral);

  // --- Data ---

  /**
   * @notice The collateral type that this contract handles
   * @return _cType Bytes32 representation of the collateralType
   */
  function collateralType() external view returns (bytes32 _cType);

  /// @notice Number of decimals of the collateral token
  function decimals() external view returns (uint256 _decimals);

  /// @notice Multiplier used to transform collateral into 18 decimals within the system
  function multiplier() external view returns (uint256 _multiplier);

  // --- Methods ---

  /**
   * @notice Join collateral in the system
   * @param _account Account to which we add collateral into the system
   * @param _wei Amount of collateral to transfer in the system (represented as a number with token decimals)
   */
  function join(address _account, uint256 _wei) external;

  /**
   * @notice Exit collateral from the system
   * @param _account Account to which we transfer the collateral out of the system
   * @param _wei Amount of collateral to transfer to account (represented as a number with token decimals)
   */
  function exit(address _account, uint256 _wei) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IFactoryChild {
  // --- Errors ---

  /// @dev Throws when the contract is being deployed by a non-contract address
  error NotFactoryDeployment();
  /// @dev Throws when trying to call an onlyFactory function from a non-factory address
  error CallerNotFactory();

  // --- Registry ---

  /**
   * @notice Getter for the address of the factory that deployed the inheriting contract
   * @return _factory Factory address
   */
  function factory() external view returns (address _factory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface ISAFEEngine is IAuthorizable, IModifiable, IDisableable {
  // --- Events ---

  /**
   * @notice Emitted when an address authorizes another address to modify its SAFE
   * @param _sender Address that sent the authorization
   * @param _account Address that is authorized to modify the SAFE
   */
  event ApproveSAFEModification(address _sender, address _account);

  /**
   * @notice Emitted when an address denies another address to modify its SAFE
   * @param _sender Address that sent the denial
   * @param _account Address that is denied to modify the SAFE
   */
  event DenySAFEModification(address _sender, address _account);

  /**
   * @notice Emitted when a new collateral type is registered
   * @param _cType Bytes32 representation of the collateral type
   */
  event InitializeCollateralType(bytes32 _cType);

  /**
   * @notice Emitted when collateral is transferred between accounts
   * @param _cType Bytes32 representation of the collateral type
   * @param _src Address that sent the collateral
   * @param _dst Address that received the collateral
   * @param _wad Amount of collateral transferred
   */
  event TransferCollateral(bytes32 indexed _cType, address indexed _src, address indexed _dst, uint256 _wad);

  /**
   * @notice Emitted when internal coins are transferred between accounts
   * @param _src Address that sent the coins
   * @param _dst Address that received the coins
   * @param _rad Amount of coins transferred
   */
  event TransferInternalCoins(address indexed _src, address indexed _dst, uint256 _rad);

  /**
   * @notice Emitted when the SAFE state is modified by the owner or authorized accounts
   * @param _cType Bytes32 representation of the collateral type
   * @param _safe Address of the SAFE
   * @param _collateralSource Address that sent/receives the collateral
   * @param _debtDestination Address that sent/receives the debt
   * @param _deltaCollateral Amount of collateral added/extracted from the SAFE [wad]
   * @param _deltaDebt Amount of debt to generate/repay [wad]
   */
  event ModifySAFECollateralization(
    bytes32 indexed _cType,
    address indexed _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  );

  /**
   * @notice Emitted when collateral and/or debt is transferred between SAFEs
   * @param _cType Bytes32 representation of the collateral type
   * @param _src Address that sent the collateral
   * @param _dst Address that received the collateral
   * @param _deltaCollateral Amount of collateral to take/add into src and give/take from dst [wad]
   * @param _deltaDebt Amount of debt to take/add into src and give/take from dst [wad]
   */
  event TransferSAFECollateralAndDebt(
    bytes32 indexed _cType, address indexed _src, address indexed _dst, int256 _deltaCollateral, int256 _deltaDebt
  );

  /**
   * @notice Emitted when collateral and debt is confiscated from a SAFE
   * @param _cType Bytes32 representation of the collateral type
   * @param _safe Address of the SAFE
   * @param _collateralSource Address that sent/receives the collateral
   * @param _debtDestination Address that sent/receives the debt
   * @param _deltaCollateral Amount of collateral added/extracted from the SAFE [wad]
   * @param _deltaDebt Amount of debt to generate/repay [wad]
   */
  event ConfiscateSAFECollateralAndDebt(
    bytes32 indexed _cType,
    address indexed _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  );

  /**
   * @notice Emitted when an account's debt is settled with coins
   * @dev    Accounts (not SAFEs) can only settle unbacked debt
   * @param _account Address of the account
   * @param _rad Amount of debt & coins to destroy
   */
  event SettleDebt(address indexed _account, uint256 _rad);

  /**
   * @notice Emitted when an unbacked debt is created to an account
   * @param _debtDestination Address that received the newly created debt
   * @param _coinDestination Address that received the newly created coins
   * @param _rad Amount of debt to create
   */
  event CreateUnbackedDebt(address indexed _debtDestination, address indexed _coinDestination, uint256 _rad);

  /**
   * @notice Emit when the accumulated rate of a collateral type is updated
   * @param _cType Bytes32 representation of the collateral type
   * @param _surplusDst Address that received the newly created surplus
   * @param _rateMultiplier Delta of the accumulated rate [ray]
   */
  event UpdateAccumulatedRate(bytes32 indexed _cType, address _surplusDst, int256 _rateMultiplier);

  /**
   * @notice Emitted when the safety price and liquidation price of a collateral type is updated
   * @param _cType Bytes32 representation of the collateral type
   * @param _safetyPrice New price at which a SAFE is allowed to generate debt [ray]
   * @param _liquidationPrice New price at which a SAFE gets liquidated [ray]
   */
  event UpdateCollateralPrice(bytes32 indexed _cType, uint256 _safetyPrice, uint256 _liquidationPrice);

  // --- Errors ---

  /// @notice Throws when trying to initialize a collateral type that already exists
  error SAFEEng_CollateralTypeAlreadyExists();
  /// @notice Throws when trying to modify parameters of an uninitialized collateral type
  error SAFEEng_CollateralTypeNotInitialized();
  /// @notice Throws when trying to modify a SAFE into an unsafe state
  error SAFEEng_SAFENotSafe();
  /// @notice Throws when trying to modify a SAFE into a dusty safe (debt non-zero and below `debtFloor`)
  error SAFEEng_DustySAFE();
  /// @notice Throws when trying to generate debt that would put the system over the global debt ceiling
  error SAFEEng_GlobalDebtCeilingHit();
  /// @notice Throws when trying to generate debt that would put the system over the collateral debt ceiling
  error SAFEEng_CollateralDebtCeilingHit();
  /// @notice Throws when trying to generate debt that would put the SAFE over the SAFE debt ceiling
  error SAFEEng_SAFEDebtCeilingHit();
  /// @notice Throws when an account tries to modify a SAFE without the proper permissions
  error SAFEEng_NotSAFEAllowed();
  /// @notice Throws when an account tries to pull collateral from a SAFE without the proper permissions
  error SAFEEng_NotCollateralSrcAllowed();
  /// @notice Throws when an account tries to push debt to a SAFE without the proper permissions
  error SAFEEng_NotDebtDstAllowed();

  // --- Structs ---

  struct SAFE {
    // Total amount of collateral locked in a SAFE
    uint256 /* WAD */ lockedCollateral;
    // Total amount of debt generated by a SAFE
    uint256 /* WAD */ generatedDebt;
  }

  struct SAFEEngineParams {
    // Total amount of debt that a single safe can generate
    uint256 /* WAD */ safeDebtCeiling;
    // Maximum amount of debt that can be issued across all safes
    uint256 /* RAD */ globalDebtCeiling;
  }

  struct SAFEEngineCollateralData {
    // Total amount of debt issued by the collateral type
    uint256 /* WAD */ debtAmount;
    // Total amount of collateral locked in SAFEs using the collateral type
    uint256 /* WAD */ lockedAmount;
    // Accumulated rate of the collateral type
    uint256 /* RAY */ accumulatedRate;
    // Floor price at which a SAFE is allowed to generate debt
    uint256 /* RAY */ safetyPrice;
    // Price at which a SAFE gets liquidated
    uint256 /* RAY */ liquidationPrice;
  }

  struct SAFEEngineCollateralParams {
    // Maximum amount of debt that can be generated with the collateral type
    uint256 /* RAD */ debtCeiling;
    // Minimum amount of debt that must be generated by a SAFE using the collateral
    uint256 /* RAD */ debtFloor;
  }

  // --- Data ---

  /**
   * @notice Getter for the contract parameters struct
   * @dev    Returns a SAFEEngineParams struct
   */
  function params() external view returns (SAFEEngineParams memory _safeEngineParams);

  /**
   * @notice Getter for the unpacked contract parameters struct
   * @return _safeDebtCeiling Total amount of debt that a single safe can generate [wad]
   * @return _globalDebtCeiling Maximum amount of debt that can be issued [rad]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _params() external view returns (uint256 _safeDebtCeiling, uint256 _globalDebtCeiling);

  /**
   * @notice Getter for the collateral parameters struct
   * @param  _cType Bytes32 representation of the collateral type
   * @dev    Returns a SAFEEngineCollateralParams struct
   */
  function cParams(bytes32 _cType) external view returns (SAFEEngineCollateralParams memory _safeEngineCParams);

  /**
   * @notice Getter for the unpacked collateral parameters struct
   * @param  _cType Bytes32 representation of the collateral type
   * @return _debtCeiling Maximum amount of debt that can be generated with this collateral type
   * @return _debtFloor Minimum amount of debt that must be generated by a SAFE using this collateral
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _cParams(bytes32 _cType) external view returns (uint256 _debtCeiling, uint256 _debtFloor);

  /**
   * @notice Getter for the collateral data struct
   * @param  _cType Bytes32 representation of the collateral type
   * @dev    Returns a SAFEEngineCollateralData struct
   */
  function cData(bytes32 _cType) external view returns (SAFEEngineCollateralData memory _safeEngineCData);

  /**
   * @notice Getter for the unpacked collateral data struct
   * @param  _cType Bytes32 representation of the collateral type
   * @return _debtAmount Total amount of debt issued by a collateral type [wad]
   * @return _lockedAmount Total amount of collateral locked in a SAFE [wad]
   * @return _accumulatedRate Accumulated rate of a collateral type [ray]
   * @return _safetyPrice Floor price at which a SAFE is allowed to generate debt [ray]
   * @return _liquidationPrice Price at which a SAFE gets liquidated [ray]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _cData(bytes32 _cType)
    external
    view
    returns (
      uint256 _debtAmount,
      uint256 _lockedAmount,
      uint256 _accumulatedRate,
      uint256 _safetyPrice,
      uint256 _liquidationPrice
    );

  /**
   * @notice Data about each SAFE
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _safeAddress Address of the SAFE
   * @dev    Returns a SAFE struct
   */
  function safes(bytes32 _cType, address _safeAddress) external view returns (SAFE memory _safeData);

  /**
   * @notice Unpacked data about each SAFE
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _safeAddress Address of the SAFE
   * @return _lockedCollateral Total amount of collateral locked in a SAFE [wad]
   * @return _generatedDebt Total amount of debt generated by a SAFE [wad]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _safes(
    bytes32 _cType,
    address _safeAddress
  ) external view returns (uint256 _lockedCollateral, uint256 _generatedDebt);

  /**
   * @notice Who can transfer collateral & debt in/out of a SAFE
   * @param  _caller Address to check for SAFE permissions for
   * @param  _account Account to check if caller has permissions for
   * @return _safeRights Numerical representation of the SAFE rights (0/1)
   */
  function safeRights(address _caller, address _account) external view returns (uint256 _safeRights);

  // --- Balances ---

  /**
   * @notice Balance of each collateral type
   * @param  _cType Bytes32 representation of the collateral type to check balance for
   * @param  _account Account to check balance for
   * @return _collateralBalance Collateral balance of the account [wad]
   */
  function tokenCollateral(bytes32 _cType, address _account) external view returns (uint256 _collateralBalance);

  /**
   * @notice Internal balance of system coins held by an account
   * @param  _account Account to check balance for
   * @return _balance Internal coin balance of the account [rad]
   */
  function coinBalance(address _account) external view returns (uint256 _balance);

  /**
   * @notice Amount of debt held by an account
   * @param  _account Account to check balance for
   * @return _debtBalance Debt balance of the account [rad]
   */
  function debtBalance(address _account) external view returns (uint256 _debtBalance);

  /**
   * @notice Total amount of debt (coins) currently issued
   * @dev    Returns the global debt [rad]
   */
  function globalDebt() external returns (uint256 _globalDebt);

  /**
   * @notice 'Bad' debt that's not covered by collateral
   * @dev    Returns the global unbacked debt [rad]
   */
  function globalUnbackedDebt() external view returns (uint256 _globalUnbackedDebt);

  // --- Init ---

  /**
   * @notice Register a new collateral type in the SAFEEngine
   * @param _cType Collateral type to register
   * @param _collateralParams Collateral parameters
   */
  function initializeCollateralType(bytes32 _cType, SAFEEngineCollateralParams memory _collateralParams) external;

  // --- Fungibility ---

  /**
   * @notice Transfer collateral between accounts
   * @param _cType Collateral type transferred
   * @param _source Collateral source
   * @param _destination Collateral destination
   * @param _wad Amount of collateral transferred
   */
  function transferCollateral(bytes32 _cType, address _source, address _destination, uint256 _wad) external;

  /**
   * @notice Transfer internal coins (does not affect external balances from Coin.sol)
   * @param  _source Coins source
   * @param  _destination Coins destination
   * @param  _rad Amount of coins transferred
   */
  function transferInternalCoins(address _source, address _destination, uint256 _rad) external;

  /**
   * @notice Join/exit collateral into and and out of the system
   * @param _cType Collateral type to join/exit
   * @param _account Account that gets credited/debited
   * @param _wad Amount of collateral
   */
  function modifyCollateralBalance(bytes32 _cType, address _account, int256 _wad) external;

  // --- SAFE Manipulation ---

  /**
   * @notice Add/remove collateral or put back/generate more debt in a SAFE
   * @param _cType Type of collateral to withdraw/deposit in and from the SAFE
   * @param _safe Target SAFE
   * @param _collateralSource Account we take collateral from/put collateral into
   * @param _debtDestination Account from which we credit/debit coins and debt
   * @param _deltaCollateral Amount of collateral added/extracted from the SAFE [wad]
   * @param _deltaDebt Amount of debt to generate/repay [wad]
   */
  function modifySAFECollateralization(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 /* WAD */ _deltaCollateral,
    int256 /* WAD */ _deltaDebt
  ) external;

  // --- SAFE Fungibility ---

  /**
   * @notice Transfer collateral and/or debt between SAFEs
   * @param _cType Collateral type transferred between SAFEs
   * @param _src Source SAFE
   * @param _dst Destination SAFE
   * @param _deltaCollateral Amount of collateral to take/add into src and give/take from dst [wad]
   * @param _deltaDebt Amount of debt to take/add into src and give/take from dst [wad]
   */
  function transferSAFECollateralAndDebt(
    bytes32 _cType,
    address _src,
    address _dst,
    int256 /* WAD */ _deltaCollateral,
    int256 /* WAD */ _deltaDebt
  ) external;

  // --- SAFE Confiscation ---

  /**
   * @notice Normally used by the LiquidationEngine in order to confiscate collateral and
   *      debt from a SAFE and give them to someone else
   * @param _cType Collateral type the SAFE has locked inside
   * @param _safe Target SAFE
   * @param _collateralSource Who we take/give collateral to
   * @param _debtDestination Who we take/give debt to
   * @param _deltaCollateral Amount of collateral taken/added into the SAFE [wad]
   * @param _deltaDebt Amount of debt taken/added into the SAFE [wad]
   */
  function confiscateSAFECollateralAndDebt(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) external;

  // --- Settlement ---

  /**
   * @notice Nullify an amount of coins with an equal amount of debt
   * @dev    Coins & debt are like matter and antimatter, they nullify each other
   * @param  _rad Amount of debt & coins to destroy
   */
  function settleDebt(uint256 _rad) external;

  /**
   * @notice Allows an authorized contract to create debt without collateral
   * @param _debtDestination The account that will receive the newly created debt
   * @param _coinDestination The account that will receive the newly created coins
   * @param _rad Amount of debt to create
   * @dev   Usually called by DebtAuctionHouse in order to terminate auctions prematurely post settlement
   */
  function createUnbackedDebt(address _debtDestination, address _coinDestination, uint256 _rad) external;

  // --- Update ---

  /**
   * @notice Allows an authorized contract to accrue interest on a specific collateral type
   * @param _cType Collateral type we accrue interest for
   * @param _surplusDst Destination for the newly created surplus
   * @param _rateMultiplier Multiplier applied to the debtAmount in order to calculate the surplus [ray]
   * @dev   The rateMultiplier is usually calculated by the TaxCollector contract
   */
  function updateAccumulatedRate(bytes32 _cType, address _surplusDst, int256 _rateMultiplier) external;

  /**
   * @notice Allows an authorized contract to update the safety price and liquidation price of a collateral type
   * @param _cType Collateral type we update the prices for
   * @param _safetyPrice New safety price [ray]
   * @param _liquidationPrice New liquidation price [ray]
   */
  function updateCollateralPrice(bytes32 _cType, uint256 _safetyPrice, uint256 _liquidationPrice) external;

  // --- Authorization ---

  /**
   * @notice Allow an address to modify your SAFE
   * @param _account Account to give SAFE permissions to
   */
  function approveSAFEModification(address _account) external;

  /**
   * @notice Deny an address the rights to modify your SAFE
   * @param _account Account that is denied SAFE permissions
   */
  function denySAFEModification(address _account) external;

  /**
   * @notice Checks whether msg.sender has the right to modify a SAFE
   */
  function canModifySAFE(address _safe, address _account) external view returns (bool _allowed);

  // --- Views ---

  /**
   * @notice List all collateral types registered in the SAFEEngine
   */
  function collateralList() external view returns (bytes32[] memory __collateralList);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

/**
 * @title  Authorizable
 * @notice Implements authorization control for contracts
 * @dev    Authorization control is boolean and handled by `onlyAuthorized` modifier
 */
abstract contract Authorizable is IAuthorizable {
  using EnumerableSet for EnumerableSet.AddressSet;

  // --- Data ---

  /// @notice EnumerableSet of authorized accounts
  EnumerableSet.AddressSet internal _authorizedAccounts;

  // --- Init ---

  /**
   * @param  _account Initial account to add authorization to
   */
  constructor(address _account) {
    _addAuthorization(_account);
  }

  // --- Views ---

  /**
   * @notice Checks whether an account is authorized
   * @return _authorized Whether the account is authorized or not
   */
  function authorizedAccounts(address _account) external view returns (bool _authorized) {
    return _isAuthorized(_account);
  }

  /**
   * @notice Getter for the authorized accounts
   * @return _accounts Array of authorized accounts
   */
  function authorizedAccounts() external view returns (address[] memory _accounts) {
    return _authorizedAccounts.values();
  }

  // --- Methods ---

  /**
   * @notice Add auth to an account
   * @param  _account Account to add auth to
   */
  function addAuthorization(address _account) external virtual isAuthorized {
    _addAuthorization(_account);
  }

  /**
   * @notice Remove auth from an account
   * @param  _account Account to remove auth from
   */
  function removeAuthorization(address _account) external virtual isAuthorized {
    _removeAuthorization(_account);
  }

  // --- Internal methods ---
  function _addAuthorization(address _account) internal {
    if (_authorizedAccounts.add(_account)) {
      emit AddAuthorization(_account);
    } else {
      revert AlreadyAuthorized();
    }
  }

  function _removeAuthorization(address _account) internal {
    if (_authorizedAccounts.remove(_account)) {
      emit RemoveAuthorization(_account);
    } else {
      revert NotAuthorized();
    }
  }

  function _isAuthorized(address _account) internal view virtual returns (bool _authorized) {
    return _authorizedAccounts.contains(_account);
  }

  // --- Modifiers ---

  /**
   * @notice Checks whether msg.sender can call an authed function
   * @dev    Will revert with `Unauthorized` if the sender is not authorized
   */
  modifier isAuthorized() {
    if (!_isAuthorized(msg.sender)) revert Unauthorized();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDisableable} from '@interfaces/utils/IDisableable.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';

/**
 * @title  Disableable
 * @notice This abstract contract provides the ability to disable the inheriting contract,
 *         triggering (if implemented) an on-disable routine hook.
 * @dev    This contract also implements `whenEnabled` and `whenDisabled` modifiers to restrict
 *         the methods that can be called on each state.
 */
abstract contract Disableable is IDisableable, Authorizable {
  // --- Data ---

  /// @inheritdoc IDisableable
  bool public contractEnabled = true;

  // --- External methods ---

  /// @inheritdoc IDisableable
  function disableContract() external isAuthorized whenEnabled {
    contractEnabled = false;
    _onContractDisable();
    emit DisableContract();
  }

  // --- Internal virtual methods ---

  /**
   * @notice Internal virtual method to be called when the contract is disabled
   * @dev    This method is virtual and should be overriden to implement
   */
  function _onContractDisable() internal virtual {}

  /**
   * @notice Internal virtual view to check if the contract is enabled
   * @dev    This method is virtual and could be overriden for non-standard implementations
   */
  function _isEnabled() internal view virtual returns (bool _enabled) {
    return contractEnabled;
  }

  // --- Modifiers ---

  /// @notice Allows method calls only when the contract is enabled
  modifier whenEnabled() {
    if (!_isEnabled()) revert ContractIsDisabled();
    _;
  }

  /// @notice Allows method calls only when the contract is disabled
  modifier whenDisabled() {
    if (_isEnabled()) revert ContractIsEnabled();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/// @dev Max uint256 value that a RAD can represent without overflowing
uint256 constant MAX_RAD = type(uint256).max / RAY;
/// @dev Uint256 representation of 1 RAD
uint256 constant RAD = 10 ** 45;
/// @dev Uint256 representation of 1 RAY
uint256 constant RAY = 10 ** 27;
/// @dev Uint256 representation of 1 WAD
uint256 constant WAD = 10 ** 18;
/// @dev Uint256 representation of 1 year in seconds
uint256 constant YEAR = 365 days;
/// @dev Uint256 representation of 1 hour in seconds
uint256 constant HOUR = 3600;

/**
 * @title Math
 * @notice This library contains common math functions
 */
library Math {
  // --- Errors ---

  /// @dev Throws when trying to cast a uint256 to an int256 that overflows
  error IntOverflow();

  // --- Math ---

  /**
   * @notice Calculates the sum of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _add Unsigned sum of `_x` and `_y`
   */
  function add(uint256 _x, int256 _y) internal pure returns (uint256 _add) {
    if (_y >= 0) {
      return _x + uint256(_y);
    } else {
      return _x - uint256(-_y);
    }
  }

  /**
   * @notice Calculates the substraction of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _sub Unsigned substraction of `_x` and `_y`
   */
  function sub(uint256 _x, int256 _y) internal pure returns (uint256 _sub) {
    if (_y >= 0) {
      return _x - uint256(_y);
    } else {
      return _x + uint256(-_y);
    }
  }

  /**
   * @notice Calculates the substraction of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _sub Signed substraction of `_x` and `_y`
   */
  function sub(uint256 _x, uint256 _y) internal pure returns (int256 _sub) {
    return toInt(_x) - toInt(_y);
  }

  /**
   * @notice Calculates the multiplication of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _mul Signed multiplication of `_x` and `_y`
   */
  function mul(uint256 _x, int256 _y) internal pure returns (int256 _mul) {
    return toInt(_x) * _y;
  }

  /**
   * @notice Calculates the multiplication of two unsigned RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Unsigned RAY integer
   * @return _rmul Unsigned multiplication of `_x` and `_y` in RAY precision
   */
  function rmul(uint256 _x, uint256 _y) internal pure returns (uint256 _rmul) {
    return (_x * _y) / RAY;
  }

  /**
   * @notice Calculates the multiplication of an unsigned and a signed RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Signed RAY integer
   * @return _rmul Signed multiplication of `_x` and `_y` in RAY precision
   */
  function rmul(uint256 _x, int256 _y) internal pure returns (int256 _rmul) {
    return (toInt(_x) * _y) / int256(RAY);
  }

  /**
   * @notice Calculates the multiplication of two unsigned WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Unsigned WAD integer
   * @return _wmul Unsigned multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(uint256 _x, uint256 _y) internal pure returns (uint256 _wmul) {
    return (_x * _y) / WAD;
  }

  /**
   * @notice Calculates the multiplication of an unsigned and a signed WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Signed WAD integer
   * @return _wmul Signed multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(uint256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (toInt(_x) * _y) / int256(WAD);
  }

  /**
   * @notice Calculates the multiplication of two signed WAD integers
   * @param  _x Signed WAD integer
   * @param  _y Signed WAD integer
   * @return _wmul Signed multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(int256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (_x * _y) / int256(WAD);
  }

  /**
   * @notice Calculates the division of two unsigned RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Unsigned RAY integer
   * @return _rdiv Unsigned division of `_x` by `_y` in RAY precision
   */
  function rdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _rdiv) {
    return (_x * RAY) / _y;
  }

  /**
   * @notice Calculates the division of two signed RAY integers
   * @param  _x Signed RAY integer
   * @param  _y Signed RAY integer
   * @return _rdiv Signed division of `_x` by `_y` in RAY precision
   */
  function rdiv(int256 _x, int256 _y) internal pure returns (int256 _rdiv) {
    return (_x * int256(RAY)) / _y;
  }

  /**
   * @notice Calculates the division of two unsigned WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Unsigned WAD integer
   * @return _wdiv Unsigned division of `_x` by `_y` in WAD precision
   */
  function wdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _wdiv) {
    return (_x * WAD) / _y;
  }

  /**
   * @notice Calculates the power of an unsigned RAY integer to an unsigned integer
   * @param  _x Unsigned RAY integer
   * @param  _n Unsigned integer exponent
   * @return _rpow Unsigned `_x` to the power of `_n` in RAY precision
   */
  function rpow(uint256 _x, uint256 _n) internal pure returns (uint256 _rpow) {
    assembly {
      switch _x
      case 0 {
        switch _n
        case 0 { _rpow := RAY }
        default { _rpow := 0 }
      }
      default {
        switch mod(_n, 2)
        case 0 { _rpow := RAY }
        default { _rpow := _x }
        let half := div(RAY, 2) // for rounding.
        for { _n := div(_n, 2) } _n { _n := div(_n, 2) } {
          let _xx := mul(_x, _x)
          if iszero(eq(div(_xx, _x), _x)) { revert(0, 0) }
          let _xxRound := add(_xx, half)
          if lt(_xxRound, _xx) { revert(0, 0) }
          _x := div(_xxRound, RAY)
          if mod(_n, 2) {
            let _zx := mul(_rpow, _x)
            if and(iszero(iszero(_x)), iszero(eq(div(_zx, _x), _rpow))) { revert(0, 0) }
            let _zxRound := add(_zx, half)
            if lt(_zxRound, _zx) { revert(0, 0) }
            _rpow := div(_zxRound, RAY)
          }
        }
      }
    }
  }

  /**
   * @notice Calculates the maximum of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _max Unsigned maximum of `_x` and `_y`
   */
  function max(uint256 _x, uint256 _y) internal pure returns (uint256 _max) {
    _max = (_x >= _y) ? _x : _y;
  }

  /**
   * @notice Calculates the minimum of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _min Unsigned minimum of `_x` and `_y`
   */
  function min(uint256 _x, uint256 _y) internal pure returns (uint256 _min) {
    _min = (_x <= _y) ? _x : _y;
  }

  /**
   * @notice Casts an unsigned integer to a signed integer
   * @param  _x Unsigned integer
   * @return _int Signed integer
   * @dev    Throws if `_x` is too large to fit in an int256
   */
  function toInt(uint256 _x) internal pure returns (int256 _int) {
    _int = int256(_x);
    if (_int < 0) revert IntOverflow();
  }

  // --- PI Specific Math ---

  /**
   * @notice Calculates the Riemann sum of two signed integers
   * @param  _x Signed integer
   * @param  _y Signed integer
   * @return _riemannSum Riemann sum of `_x` and `_y`
   */
  function riemannSum(int256 _x, int256 _y) internal pure returns (int256 _riemannSum) {
    return (_x + _y) / 2;
  }

  /**
   * @notice Calculates the absolute value of a signed integer
   * @param  _x Signed integer
   * @return _z Unsigned absolute value of `_x`
   */
  function absolute(int256 _x) internal pure returns (uint256 _z) {
    _z = (_x < 0) ? uint256(-_x) : uint256(_x);
  }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Assertions
 * @notice This library contains assertions for common requirement checks
 */
library Assertions {
  // --- Errors ---

  /// @dev Throws if `_x` is not greater than `_y`
  error NotGreaterThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not lesser than `_y`
  error NotLesserThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not greater than or equal to `_y`
  error NotGreaterOrEqualThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not lesser than or equal to `_y`
  error NotLesserOrEqualThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not greater than `_y`
  error IntNotGreaterThan(int256 _x, int256 _y);
  /// @dev Throws if `_x` is not lesser than `_y`
  error IntNotLesserThan(int256 _x, int256 _y);
  /// @dev Throws if `_x` is not greater than or equal to `_y`
  error IntNotGreaterOrEqualThan(int256 _x, int256 _y);
  /// @dev Throws if `_x` is not lesser than or equal to `_y`
  error IntNotLesserOrEqualThan(int256 _x, int256 _y);
  /// @dev Throws if checked amount is null
  error NullAmount();
  /// @dev Throws if checked address is null
  error NullAddress();

  // --- Assertions ---

  /// @dev Asserts that `_x` is greater than `_y` and returns `_x`
  function assertGt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x <= _y) revert NotGreaterThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is greater than `_y` and returns `_x`
  function assertGt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x <= _y) revert IntNotGreaterThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is greater than or equal to `_y` and returns `_x`
  function assertGtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x < _y) revert NotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is greater than or equal to `_y` and returns `_x`
  function assertGtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x < _y) revert IntNotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than `_y` and returns `_x`
  function assertLt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x >= _y) revert NotLesserThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than `_y` and returns `_x`
  function assertLt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x >= _y) revert IntNotLesserThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than or equal to `_y` and returns `_x`
  function assertLtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x > _y) revert NotLesserOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than or equal to `_y` and returns `_x`
  function assertLtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x > _y) revert IntNotLesserOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is not null and returns `_x`
  function assertNonNull(uint256 _x) internal pure returns (uint256 __x) {
    if (_x == 0) revert NullAmount();
    return _x;
  }

  /// @dev Asserts that `_address` is not null and returns `_address`
  function assertNonNull(address _address) internal pure returns (address __address) {
    if (_address == address(0)) revert NullAddress();
    return _address;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDisableable} from '@interfaces/utils/IDisableable.sol';

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

interface IDisableableChild is IDisableable, IFactoryChild {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

/**
 * @title  FactoryChild
 * @notice This abstract contract adds a factory address and modifier to the inheriting contract
 */
abstract contract FactoryChild is IFactoryChild {
  // --- Registry ---

  /// @inheritdoc IFactoryChild
  address public factory;

  // --- Init ---

  /// @dev Verifies that the contract is being deployed by a contract address
  constructor() {
    factory = msg.sender;
    if (factory.code.length == 0) revert NotFactoryDeployment();
  }

  // --- Modifiers ---

  /// @notice Verifies that the caller is the factory
  modifier onlyFactory() {
    if (msg.sender != factory) revert CallerNotFactory();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IAuthorizable {
  // --- Events ---

  /**
   * @notice Emitted when an account is authorized
   * @param _account Account that is authorized
   */
  event AddAuthorization(address _account);

  /**
   * @notice Emitted when an account is unauthorized
   * @param _account Account that is unauthorized
   */
  event RemoveAuthorization(address _account);

  // --- Errors ---
  /// @notice Throws if the account is already authorized on `addAuthorization`
  error AlreadyAuthorized();
  /// @notice Throws if the account is not authorized on `removeAuthorization`
  error NotAuthorized();
  /// @notice Throws if the account is not authorized and tries to call an `onlyAuthorized` method
  error Unauthorized();

  // --- Data ---

  /**
   * @notice Checks whether an account is authorized on the contract
   * @param  _account Account to check
   * @return _authorized Whether the account is authorized or not
   */
  function authorizedAccounts(address _account) external view returns (bool _authorized);

  /**
   * @notice Getter for the authorized accounts
   * @return _accounts Array of authorized accounts
   */
  function authorizedAccounts() external view returns (address[] memory _accounts);

  // --- Administration ---

  /**
   * @notice Add authorization to an account
   * @param  _account Account to add authorization to
   * @dev    Method will revert if the account is already authorized
   */
  function addAuthorization(address _account) external;

  /**
   * @notice Remove authorization from an account
   * @param  _account Account to remove authorization from
   * @dev    Method will revert if the account is not authorized
   */
  function removeAuthorization(address _account) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface IDisableable is IAuthorizable {
  // --- Events ---

  /// @notice Emitted when the inheriting contract is disabled
  event DisableContract();

  // --- Errors ---

  /// @notice Throws when trying to call a `whenDisabled` method when the contract is enabled
  error ContractIsEnabled();
  /// @notice Throws when trying to call a `whenEnabled` method when the contract is disabled
  error ContractIsDisabled();
  /// @notice Throws when trying to disable a contract that cannot be disabled
  error NonDisableable();

  // --- Data ---

  /**
   * @notice Check if the contract is enabled
   * @return _contractEnabled True if the contract is enabled
   */
  function contractEnabled() external view returns (bool _contractEnabled);

  // --- Methods ---

  /**
   * @notice External method to trigger the contract disablement
   * @dev    Triggers an internal call to `_onContractDisable` virtual method
   */
  function disableContract() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface IModifiable is IAuthorizable {
  // --- Events ---
  /// @dev Event topic 1 is always a parameter, topic 2 can be empty (global params)
  event ModifyParameters(bytes32 indexed _param, bytes32 indexed _cType, bytes _data);

  // --- Errors ---
  error UnrecognizedParam();
  error UnrecognizedCType();

  // --- Administration ---
  /**
   * @notice Set a new value for a global specific parameter
   * @param _param String identifier of the parameter to modify
   * @param _data Encoded data to modify the parameter
   */
  function modifyParameters(bytes32 _param, bytes memory _data) external;

  /**
   * @notice Set a new value for a collateral specific parameter
   * @param _cType String identifier of the collateral to modify
   * @param _param String identifier of the parameter to modify
   * @param _data Encoded data to modify the parameter
   */
  function modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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