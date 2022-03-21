pragma solidity ^0.5.16;

import "../interfaces/IController.sol";


contract Storage {

  event GovernanceChanged(address newGovernance);
  event GovernanceQueued(address newGovernance, uint implementationTimestamp);
  event ControllerChanged(address newController);
  event ControllerQueued(address newController, uint implementationTimestamp);

  address public governance;
  address public controller;

  address public nextGovernance;
  uint256 public nextGovernanceTimestamp;

  address public nextController;
  uint256 public nextControllerTimestamp;

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor () public {
    governance = msg.sender;
    emit GovernanceChanged(msg.sender);
  }

  function setInitialController(address _controller) public onlyGovernance {
    require(
      controller == address(0),
      "controller already set"
    );
    require(
      IController(_controller).nextImplementationDelay() >= 0,
      "new controller doesn't get delay properly"
    );

    controller = _controller;
    emit ControllerChanged(_controller);
  }

  function nextImplementationDelay() public view returns (uint) {
    return IController(controller).nextImplementationDelay();
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    nextGovernance = _governance;
    nextGovernanceTimestamp = block.timestamp + nextImplementationDelay();
    emit GovernanceQueued(nextGovernance, nextGovernanceTimestamp);
  }

  function confirmGovernance() public onlyGovernance {
    require(
      nextGovernance != address(0) && nextGovernanceTimestamp != 0,
      "no governance queued"
    );
    require(
      block.timestamp >= nextGovernanceTimestamp,
      "governance not yet ready"
    );
    governance = nextGovernance;
    emit GovernanceChanged(governance);

    nextGovernance = address(0);
    nextGovernanceTimestamp = 0;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    require(IController(_controller).nextImplementationDelay() >= 0, "new controller doesn't get delay properly");

    nextController = _controller;
    nextControllerTimestamp = block.timestamp + nextImplementationDelay();
    emit ControllerQueued(nextController, nextControllerTimestamp);
  }

  function confirmController() public onlyGovernance {
    require(
      nextController != address(0) && nextControllerTimestamp != 0,
      "no controller queued"
    );
    require(
      block.timestamp >= nextControllerTimestamp,
      "controller not yet ready"
    );
    controller = nextController;
    emit ControllerChanged(controller);

    nextController = address(0);
    nextControllerTimestamp = 0;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity ^0.5.16;

interface IController {

    // ==================== Events ====================

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    // ==================== Functions ====================

    /**
     * An EOA can safely interact with the system no matter what. If you're using Metamask, you're using an EOA. Only
     * smart contracts may be affected by this grey list. This contract will not be able to ban any EOA from the system
     * even if an EOA is being added to the greyList, he/she will still be able to interact with the whole system as if
     * nothing happened. Only smart contracts will be affected by being added to the greyList. This grey list is only
     * used in VaultV3.sol, see the code there for reference
     */
    function greyList(address _target) external view returns (bool);

    function stakingWhiteList(address _target) external view returns (bool);

    function store() external view returns (address);

    function governance() external view returns (address);

    function hasVault(address _vault) external view returns (bool);

    function hasStrategy(address _strategy) external view returns (bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function addVaultsAndStrategies(address[] calldata _vaults, address[] calldata _strategies) external;

    function doHardWork(
        address _vault,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    ) external;

    function addHardWorker(address _worker) external;

    function removeHardWorker(address _worker) external;

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    /**
     * @return The targeted profit token to convert all-non-compounding rewards to. Defaults to WETH.
     */
    function targetToken() external view returns (address);

    function setTargetToken(address _targetToken) external;

    function rewardForwarder() external view returns (address);

    function setRewardForwarder(address _rewardForwarder) external;

    function setUniversalLiquidator(address _universalLiquidator) external;

    function universalLiquidator() external view returns (address);

    function dolomiteYieldFarmingRouter() external view returns (address);

    function setDolomiteYieldFarmingRouter(address _value) external;

    function nextImplementationDelay() external view returns (uint256);

    function profitSharingNumerator() external view returns (uint256);

    function strategistFeeNumerator() external view returns (uint256);

    function platformFeeNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);

    function strategistFeeDenominator() external view returns (uint256);

    function platformFeeDenominator() external view returns (uint256);

    function setProfitSharingNumerator(uint _profitSharingNumerator) external;

    function confirmSetProfitSharingNumerator() external;

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) external;

    function confirmSetStrategistFeeNumerator() external;

    function setPlatformFeeNumerator(uint _platformFeeNumerator) external;

    function confirmSetPlatformFeeNumerator() external;

    function nextProfitSharingNumerator() external view returns (uint256);

    function nextProfitSharingNumeratorTimestamp() external view returns (uint256);

    function nextStrategistFeeNumerator() external view returns (uint256);

    function nextStrategistFeeNumeratorTimestamp() external view returns (uint256);

    function nextPlatformFeeNumerator() external view returns (uint256);

    function nextPlatformFeeNumeratorTimestamp() external view returns (uint256);
}