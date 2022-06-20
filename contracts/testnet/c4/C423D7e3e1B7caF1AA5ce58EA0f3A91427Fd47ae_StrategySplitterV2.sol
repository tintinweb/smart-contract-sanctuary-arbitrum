// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/ReentrancyGuard.sol";
import "../openzeppelin/Math.sol";
import "../openzeppelin/SafeERC20.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/IStrategyV2.sol";
import "../interfaces/ISplitter.sol";
import "../proxy/ControllableV3.sol";

/// @title Proxy solution for connection a vault with multiple strategies
///        Version 2 has auto-rebalance logic adopted to strategies with fees.
/// @author belbix
contract StrategySplitterV2 is ControllableV3, ReentrancyGuard, ISplitter {
  using SafeERC20 for IERC20;

  // *********************************************
  //                  CONSTANTS
  // *********************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant SPLITTER_VERSION = "2.0.0";
  /// @dev APR denominator. Represent 100% APR.
  uint public constant APR_DENOMINATOR = 100_000;
  /// @dev Delay between hardwork calls for a strategy.
  uint public constant HARDWORK_DELAY = 12 hours;
  /// @dev How much APR history elements will be counted in average APR calculation.
  uint public constant HISTORY_DEEP = 3;
  /// @dev Time lock for adding new strategies.
  uint public constant TIME_LOCK = 18 hours;


  // *********************************************
  //                 VARIABLES
  // *********************************************

  /// @dev Underlying asset
  address public override asset;
  /// @dev Connected vault
  address public override vault;
  /// @dev Array of strategies under control
  address[] public strategies;
  /// @dev Paused strategies
  mapping(address => bool) public pausedStrategies;
  /// @dev Current strategies average APRs. Uses for deposit/withdraw ordering.
  mapping(address => uint) public strategiesAPR;
  /// @dev Strategies APR history. Uses for calculate average APR.
  mapping(address => uint[]) public strategiesAPRHistory;
  /// @dev Last strategies doHardWork call timestamp. Uses for calls delay.
  mapping(address => uint) public lastHardWorks;
  /// @dev Flag represents doHardWork call. Need for not call HW on deposit again in connected vault.
  bool public override isHardWorking;
  /// @dev Strategy => timestamp. Strategies scheduled for adding.
  mapping(address => uint) scheduledStrategies;
  /// @dev Changed to true after a strategy adding
  bool inited;

  // *********************************************
  //                  EVENTS
  // *********************************************

  event StrategyAdded(address strategy, uint apr);
  event StrategyRemoved(address strategy);
  event StrategyRatioChanged(address strategy, uint ratio);
  event Rebalance(
    address topStrategy,
    address lowStrategy,
    uint percent,
    uint slippageTolerance,
    uint slippage,
    uint lowStrategyBalance
  );
  event HardWork(
    address sender,
    address strategy,
    uint tvl,
    uint earned,
    uint lost,
    uint apr,
    uint avgApr
  );
  event StrategyScheduled(address strategy, uint startTime, uint timeLock);
  event ManualAprChanged(address sender, address strategy, uint newApr, uint oldApr);
  event Paused(address strategy, address sender);
  event ContinueInvesting(address strategy, uint apr, address sender);

  // *********************************************
  //                 INIT
  // *********************************************

  /// @dev Initialize contract after setup it as proxy implementation
  function init(address controller_, address _asset, address _vault) external initializer override {
    __Controllable_init(controller_);
    asset = _asset;
    vault = _vault;
  }

  // *********************************************
  //                 RESTRICTIONS
  // *********************************************

  /// @dev Restrict access only for governance
  function _onlyGov() internal view {
    require(isGovernance(msg.sender), "SS: Denied");
  }

  /// @dev Restrict access only for operators
  function _onlyOperators() internal view {
    require(IController(controller()).isOperator(msg.sender), "SS: Denied");
  }

  /// @dev Restrict access only for vault
  function _onlyVault() internal view {
    require(msg.sender == vault, "SS: Denied");
  }

  /// @dev Restrict access only for operators or vault
  function _onlyOperatorsOrVault() internal view {
    require(msg.sender == vault || IController(controller()).isOperator(msg.sender), "SS: Denied");
  }

  // *********************************************
  //                    VIEWS
  // *********************************************

  /// @dev Amount of underlying assets under control of splitter.
  function totalAssets() public view override returns (uint256){
    address _asset = asset;
    uint balance = IERC20(_asset).balanceOf(address(this));
    uint length = strategies.length;
    for (uint i = 0; i < length; i++) {
      balance += IStrategyV2(strategies[i]).totalAssets();
    }
    return balance;
  }

  /// @dev Return maximum available balance to withdraw without calling more than 1 strategy
  function maxCheapWithdraw() external view returns (uint) {
    address _asset = asset;
    uint strategyBalance;
    if (strategies.length != 0) {
      strategyBalance = IStrategyV2(strategies[0]).totalAssets();
    }
    return strategyBalance + IERC20(_asset).balanceOf(address(this));
  }

  /// @dev Length of strategy array
  function strategiesLength() external view returns (uint) {
    return strategies.length;
  }

  /// @dev Returns strategy array
  function allStrategies() external view returns (address[] memory) {
    return strategies;
  }

  /// @dev Length of APR history for given strategy
  function strategyAPRHistoryLength(address strategy) external view returns (uint) {
    return strategiesAPRHistory[strategy].length;
  }

  // *********************************************
  //                GOV ACTIONS
  // *********************************************

  function scheduleStrategies(address[] memory _strategies) external {
    _onlyGov();

    for (uint i; i < _strategies.length; i++) {
      scheduledStrategies[_strategies[i]] = block.timestamp;
      emit StrategyScheduled(_strategies[i], block.timestamp, TIME_LOCK);
    }
  }

  /// @dev Add new managed strategy. Should be an uniq address.
  ///      Strategy should have the same underlying asset with current contract.
  function addStrategies(address[] memory _strategies, uint[] memory expectedAPR) external {
    // only initial action will require strict access
    // already scheduled strategies can be added by anyone

    bool _inited = inited;
    address[] memory existStrategies = strategies;
    address[] memory addedStrategies = new address[](_strategies.length);
    for (uint i = 0; i < _strategies.length; i++) {
      address strategy = _strategies[i];
      uint apr = expectedAPR[i];

      // --- restrictions ----------

      require(IStrategyV2(strategy).asset() == asset, "SS: Wrong asset");
      require(IStrategyV2(strategy).splitter() == address(this), "SS: Wrong splitter");
      require(IControllable(strategy).isController(controller()), "SS: Wrong controller");
      require(!_contains(existStrategies, strategy), "SS: Already exist");
      require(!_contains(addedStrategies, strategy), "SS: Duplicate");
      // allow add strategies without time lock only for the fist call (assume the splitter is new)
      if (_inited) {
        uint startTime = scheduledStrategies[strategy];
        require(startTime != 0 && startTime + TIME_LOCK < block.timestamp, "SS: Time lock");
        scheduledStrategies[strategy] = 0;
      } else {
        // only initial action requires strict access
        _onlyGov();
      }
      // ----------------------------

      strategies.push(strategy);
      _setStrategyAPR(strategy, apr);
      addedStrategies[i] = strategy;
      lastHardWorks[strategy] = block.timestamp;
      emit StrategyAdded(strategy, apr);
    }
    _sortStrategiesByAPR();
    if (!_inited) {
      inited = true;
    }
  }

  /// @dev Remove given strategy, reset APR and withdraw all underlying to this contract
  function removeStrategies(address[] memory strategies_) external {
    _onlyGov();

    for (uint i = 0; i < strategies_.length; i++) {
      _removeStrategy(strategies_[i]);
    }
    _sortStrategiesByAPR();
  }

  function _removeStrategy(address strategy) internal {
    uint length = strategies.length;
    require(length > 0, "SS: Empty strategies");
    uint idx;
    bool found;
    for (uint256 i = 0; i < length; i++) {
      if (strategies[i] == strategy) {
        idx = i;
        found = true;
        break;
      }
    }
    require(found, "SS: Strategy not found");
    if (length > 1) {
      strategies[idx] = strategies[length - 1];
    }
    strategies.pop();

    _setStrategyAPR(strategy, 0);

    // for expensive strategies should be called before removing
    IStrategyV2(strategy).withdrawAllToSplitter();
    emit StrategyRemoved(strategy);
  }

  /// @dev Withdraw some percent from strategy with lowest APR and deposit to strategy with highest APR.
  ///      Strict access because possible losses during deposit/withdraw.
  /// @param percent Range of 1-100
  /// @param slippageTolerance Range of 0-100_000
  function rebalance(uint percent, uint slippageTolerance) external {
    _onlyGov();

    uint balance = totalAssets();

    uint length = strategies.length;
    require(length > 1, "SS: Length");
    require(percent <= 100, "SS: Percent");

    address topStrategy = strategies[0];
    require(!pausedStrategies[topStrategy], "SS: Paused");
    address lowStrategy;

    uint lowStrategyBalance;
    for (uint i = length; i > 1; i--) {
      lowStrategy = strategies[i - 1];
      lowStrategyBalance = IStrategyV2(lowStrategy).totalAssets();
    }
    require(lowStrategyBalance != 0, "SS: No strategies");

    if (percent == 100) {
      IStrategyV2(lowStrategy).withdrawAllToSplitter();
    } else {
      IStrategyV2(lowStrategy).withdrawToSplitter(lowStrategyBalance * percent / 100);
    }

    address _asset = asset;
    IERC20(_asset).safeTransfer(topStrategy, IERC20(_asset).balanceOf(address(this)));
    IStrategyV2(topStrategy).investAll();

    uint balanceAfter = totalAssets();
    uint slippage;
    // for some reason we can have profit during rebalance
    if (balanceAfter < balance) {
      uint loss = balance - balanceAfter;
      ITetuVaultV2(vault).coverLoss(loss);
      slippage = loss * 100_000 / balance;
      require(slippage <= slippageTolerance, "SS: Slippage");
    }

    emit Rebalance(
      topStrategy,
      lowStrategy,
      percent,
      slippageTolerance,
      slippage,
      lowStrategyBalance
    );
  }

  // *********************************************
  //                OPERATOR ACTIONS
  // *********************************************

  function setAPRs(address[] memory _strategies, uint[] memory aprs) external {
    _onlyOperators();
    for (uint i; i < aprs.length; i++) {
      address strategy = _strategies[i];
      require(!pausedStrategies[strategy], "SS: Paused");
      uint oldAPR = strategiesAPR[strategy];
      _setStrategyAPR(strategy, aprs[i]);
      emit ManualAprChanged(msg.sender, strategy, aprs[i], oldAPR);
    }
    _sortStrategiesByAPR();
  }

  /// @dev Pause investing. For withdraw need to call emergencyExit() on the strategy.
  function pauseInvesting(address strategy) external {
    _onlyOperators();

    pausedStrategies[strategy] = true;
    uint oldAPR = strategiesAPR[strategy];
    _setStrategyAPR(strategy, 0);
    _sortStrategiesByAPR();
    emit ManualAprChanged(msg.sender, strategy, 0, oldAPR);
    emit Paused(strategy, msg.sender);
  }

  /// @dev Resumes the ability to invest for given strategy.
  function continueInvesting(address strategy, uint apr) external {
    _onlyOperators();
    require(pausedStrategies[strategy], "SS: Not paused");

    pausedStrategies[strategy] = false;
    _setStrategyAPR(strategy, apr);
    _sortStrategiesByAPR();
    emit ManualAprChanged(msg.sender, strategy, apr, 0);
    emit ContinueInvesting(strategy, apr, msg.sender);
  }

  // *********************************************
  //                VAULT ACTIONS
  // *********************************************

  /// @dev Invest to the first strategy in the array. Assume this strategy has highest APR.
  function investAll() external override {
    _onlyVault();

    if (strategies.length != 0) {
      uint totalAssetsBefore = totalAssets();

      address _asset = asset;
      uint balance = IERC20(_asset).balanceOf(address(this));
      address strategy = strategies[0];
      require(!pausedStrategies[strategy], "SS: Paused");
      IERC20(_asset).safeTransfer(strategy, balance);
      IStrategyV2(strategy).investAll();

      uint totalAssetsAfter = totalAssets();
      if (totalAssetsAfter < totalAssetsBefore) {
        ITetuVaultV2(msg.sender).coverLoss(totalAssetsBefore - totalAssetsAfter);
      }
    }
  }

  /// @dev Try to withdraw all from all strategies. May be too expensive to handle in one tx.
  function withdrawAllToVault() external override {
    _onlyVault();

    address _asset = asset;
    uint balance = totalAssets();

    uint length = strategies.length;
    for (uint i = 0; i < length; i++) {
      IStrategyV2(strategies[i]).withdrawAllToSplitter();
    }

    uint balanceAfter = IERC20(_asset).balanceOf(address(this));

    address _vault = vault;
    // if we withdrew not enough try to cover loss from vault insurance
    if (balanceAfter < balance) {
      ITetuVaultV2(_vault).coverLoss(balance - balanceAfter);
    }

    if (balanceAfter > 0) {
      IERC20(_asset).safeTransfer(_vault, balanceAfter);
    }
  }

  /// @dev Cascade withdraw from strategies start from lower APR until reach the target amount.
  ///      For large amounts with multiple strategies may not be possible to process this function.
  function withdrawToVault(uint256 amount) external override {
    _onlyVault();

    address _asset = asset;
    uint balance = IERC20(_asset).balanceOf(address(this));
    if (balance < amount) {
      uint length = strategies.length;
      for (uint i = length; i > 0; i--) {
        IStrategyV2 strategy = IStrategyV2(strategies[i - 1]);
        uint strategyBalance = strategy.totalAssets();
        if (strategyBalance <= amount) {
          strategy.withdrawAllToSplitter();
        } else {
          strategy.withdrawToSplitter(amount);
        }
        balance = IERC20(_asset).balanceOf(address(this));
        if (balance >= amount) {
          break;
        }
      }
    }

    address _vault = vault;
    // if we withdrew not enough try to cover loss from vault insurance
    if (amount > balance) {
      ITetuVaultV2(_vault).coverLoss(amount - balance);
    }

    if (balance != 0) {
      IERC20(_asset).safeTransfer(_vault, Math.min(amount, balance));
    }
  }

  // *********************************************
  //                HARD WORKS
  // *********************************************

  /// @dev Call hard works for all strategies.
  function doHardWork() external override {
    _onlyOperatorsOrVault();

    // prevent recursion
    isHardWorking = true;
    uint length = strategies.length;
    bool needReorder;
    for (uint i = 0; i < length; i++) {
      bool result = _doHardWorkForStrategy(strategies[i], false);
      if (result) {
        needReorder = true;
      }
    }
    if (needReorder) {
      _sortStrategiesByAPR();
    }
    isHardWorking = false;
  }

  /// @dev Call hard work for given strategy.
  function doHardWorkForStrategy(address strategy, bool push) external {
    _onlyOperators();

    // prevent recursion
    isHardWorking = true;
    bool result = _doHardWorkForStrategy(strategy, push);
    if (result) {
      _sortStrategiesByAPR();
    }
    isHardWorking = false;
  }

  function _doHardWorkForStrategy(address strategy, bool push) internal returns (bool) {
    uint lastHardWork = lastHardWorks[strategy];

    if (
      (
      lastHardWork + HARDWORK_DELAY < block.timestamp
      && IStrategyV2(strategy).isReadyToHardWork()
      && !pausedStrategies[strategy]
      )
      || push
    ) {
      uint sinceLastHardWork = block.timestamp - lastHardWork;
      uint tvl = IStrategyV2(strategy).totalAssets();
      if (tvl != 0) {
        (uint earned, uint lost) = IStrategyV2(strategy).doHardWork();
        uint apr;
        if (earned > lost) {
          apr = computeApr(tvl, earned - lost, sinceLastHardWork);
        }
        if (lost > 0) {
          ITetuVaultV2(vault).coverLoss(lost);
        }

        strategiesAPRHistory[strategy].push(apr);
        uint avgApr = averageApr(strategy);
        strategiesAPR[strategy] = avgApr;
        lastHardWorks[strategy] = block.timestamp;

        emit HardWork(
          msg.sender,
          strategy,
          tvl,
          earned,
          lost,
          apr,
          avgApr
        );
        return true;
      }
    }
    return false;
  }

  function averageApr(address strategy) public view returns (uint) {
    uint[] storage history = strategiesAPRHistory[strategy];
    uint aprSum;
    uint length = history.length;
    uint count = Math.min(HISTORY_DEEP, length);
    if (count != 0) {
      for (uint i; i < count; i++) {
        aprSum += history[length - i - 1];
      }
      return aprSum / count;
    }
    return 0;
  }

  /// @dev https://www.investopedia.com/terms/a/apr.asp
  ///      TVL and rewards should be in the same currency and with the same decimals
  function computeApr(uint tvl, uint earned, uint duration) public pure returns (uint) {
    if (tvl == 0 || duration == 0) {
      return 0;
    }
    return earned * 1e18 * APR_DENOMINATOR * uint(365) / tvl / (duration * 1e18 / 1 days);
  }

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements.
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  ///      Sort strategies array by APR values from strategiesAPR map. Highest to lowest.
  function _sortStrategiesByAPR() internal {
  unchecked {
    uint length = strategies.length;
    for (uint i = 1; i < length; i++) {
      address key = strategies[i];
      uint j = i - 1;
      while ((int(j) >= 0) && strategiesAPR[strategies[j]] < strategiesAPR[key]) {
        strategies[j + 1] = strategies[j];
        j--;
      }
      strategies[j + 1] = key;
    }
  }
  }

  /// @dev Return true if given item found in address array
  function _contains(address[] memory array, address _item) internal pure returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        return true;
      }
    }
    return false;
  }

  function _setStrategyAPR(address strategy, uint apr) internal {
    strategiesAPR[strategy] = apr;
    // need to override last values of history for properly calculate average apr
    for (uint i; i < HISTORY_DEEP; i++) {
      strategiesAPRHistory[strategy].push(apr);
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
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
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/token/ERC20/utils/SafeERC20.sol
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
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
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
    uint value
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
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
  unchecked {
    uint oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IVaultInsurance.sol";
import "./IERC20.sol";

interface ITetuVaultV2 {

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStrategyV2 {

  function NAME() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function splitter() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  function withdrawAllToSplitter() external;

  function withdrawToSplitter(uint amount) external;

  function investAll() external;

  function doHardWork() external returns (uint earned, uint lost);

  function setCompoundRatio(uint value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/Initializable.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

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
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/utils/AddressUpgradeable.sol
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
  function sendValue(address payable recipient, uint amount) internal {
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
    return functionCall(target, data, "Address: low-level call failed");
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
    uint value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
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
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./Address.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
  modifier initializer() {
    bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
  modifier reinitializer(uint8 version) {
    bool isTopLevelCall = _setInitializedVersion(version);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(version);
    }
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
     */
  function _disableInitializers() internal virtual {
    _setInitializedVersion(type(uint8).max);
  }

  function _setInitializedVersion(uint8 version) private returns (bool) {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
    // of initializers, because in other contexts the contract may have been reentered.
    if (_initializing) {
      require(
        version == 1 && !Address.isContract(address(this)),
        "Initializable: contract is already initialized"
      );
      return false;
    } else {
      require(_initialized < version, "Initializable: contract is already initialized");
      _initialized = version;
      return true;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function vaultController() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}