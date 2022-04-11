pragma solidity ^0.8.10;

import "../shared/interfaces/ICurvePool.sol";
import "../shared/interfaces/IERC20.sol";
import "../shared/interfaces/ITrigger.sol";

/**
 * @notice Defines a trigger for a Curve base pool that is toggled if any of the following conditions occur:
 *   1. Curve LP token balances are significantly lower than what the pool expects them to be
 *   2. Curve pool virtual price drops significantly
 */
contract CurveThreeTokenBasePool is ITrigger {
  // --- Tokens ---
  // Underlying token addresses
  IERC20 internal immutable token0;
  IERC20 internal immutable token1;
  IERC20 internal immutable token2;

  // --- Tolerances ---
  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev Consider trigger toggled if Curve virtual price drops by this percentage.
  /// per share, the virtual price is expected to decrease during normal operation, but it should never decrease by
  /// more than 50% during normal operation. Therefore we check for a 50% drop
  uint256 public constant virtualPriceTol = scale - 500; // 50% drop

  /// @dev Consider trigger toggled if Curve internal balances are lower than true balances by this percentage
  uint256 public constant balanceTol = scale - 500; // 50% drop

  // --- Trigger Data ---

  /// @notice Curve pool
  ICurvePool public immutable curve;

  /// @notice Last read curve virtual price
  uint256 public lastVirtualPrice;

  // --- Constructor ---

  /**
   * @param _curve Address of the Curve pool
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _curve
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    curve = ICurvePool(_curve);

    token0 = IERC20(curve.coins(0));
    token1 = IERC20(curve.coins(1));
    token2 = IERC20(curve.coins(2));

    // Save current virtual price, to be compared during checks
    lastVirtualPrice = curve.get_virtual_price();
  }

  // --- Trigger condition ---

  /**
   * @dev Checks the Curve LP token balances and virtual price
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Internal balance vs. true balance check
    if (checkCurveBalances()) return true;

    // Pool virtual price check
    try curve.get_virtual_price() returns (uint256 _newVirtualPrice) {
      bool _triggerVpPool = _newVirtualPrice < ((lastVirtualPrice * virtualPriceTol) / scale);
      if (_triggerVpPool) return true;
      lastVirtualPrice = _newVirtualPrice; // if not triggered, save off the virtual price for the next call
    } catch {
      return true;
    }

    // Trigger condition has not occured
    return false;
  }

  /**
   * @dev Checks if the Curve internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkCurveBalances() internal view returns (bool) {
    return
      (token0.balanceOf(address(curve)) < ((curve.balances(0) * balanceTol) / scale)) ||
      (token1.balanceOf(address(curve)) < ((curve.balances(1) * balanceTol) / scale)) ||
      (token2.balanceOf(address(curve)) < ((curve.balances(2) * balanceTol) / scale));
  }
}

pragma solidity ^0.8.5;

interface ICurvePool {
  /// @notice Computes current virtual price
  function get_virtual_price() external view returns (uint256);

  /// @notice Cached virtual price, used internally
  function virtual_price() external view returns (uint256);

  /// @notice Current full profit
  function xcp_profit() external view returns (uint256);

  /// @notice Full profit at last claim of admin fees
  function xcp_profit_a() external view returns (uint256);

  /// @notice Pool admin fee
  function admin_fee() external view returns (uint256);

  /// @notice Returns balance for the token defined by the provided index
  function balances(uint256 index) external view returns (uint256);

  /// @notice Returns the address of the token for the provided index
  function coins(uint256 index) external view returns (address);
}

pragma solidity ^0.8.5;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.5;

/**
 * @notice Abstract contract for creating or interacting with a Trigger contract
 * @dev All trigger contracts created must inerit from this contract and conform to this interface
 */
abstract contract ITrigger {
  /// @notice Trigger name, analgous to an ERC-20 token's name
  string public name;

  /// @notice Trigger symbol, analgous to an ERC-20 token's symbol
  string public symbol;

  /// @notice Trigger description
  string public description;

  /// @notice Array of IDs of platforms covered by this trigger
  uint256[] public platformIds;

  /// @notice Returns address of recipient who receives subsidies for creating a protection market using this trigger
  address public immutable recipient;

  /// @notice Returns true if trigger condition has been met
  bool public isTriggered;

  /// @notice Emitted when the trigger is activated
  event TriggerActivated();

  /**
   * @notice Returns array of IDs, where each ID corresponds to a platform covered by this trigger
   * @dev See documentation for mapping of ID numbers to platforms
   */
  function getPlatformIds() external view returns (uint256[] memory) {
    return platformIds;
  }

  /**
   * @dev Executes trigger-specific logic to check if market has been triggered
   * @return True if trigger condition occured, false otherwise
   */
  function checkTriggerCondition() internal virtual returns (bool);

  /**
   * @notice Checks trigger condition, sets isTriggered flag to true if condition is met, and returns the trigger status
   * @return True if trigger condition occured, false otherwise
   */
  function checkAndToggleTrigger() external returns (bool) {
    // Return true if trigger already toggled
    if (isTriggered) return true;

    // Return false if market has not been triggered
    if (!checkTriggerCondition()) return false;

    // Otherwise, market has been triggered
    emit TriggerActivated();
    isTriggered = true;
    return isTriggered;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient
  ) {
    name = _name;
    description = _description;
    symbol = _symbol;
    platformIds = _platformIds;
    recipient = _recipient;
  }
}