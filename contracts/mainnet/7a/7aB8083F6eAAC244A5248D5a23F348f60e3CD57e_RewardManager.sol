// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

contract RewardManager is Governable {
    bool public isInitialized;

    ITimelock public timelock;
    address public rewardRouter;

    address public mlpManager;

    address public stakedMycTracker;
    address public bonusMycTracker;
    address public feeMycTracker;

    address public feeMlpTracker;
    address public stakedMlpTracker;

    address public stakedMycDistributor;
    address public stakedMlpDistributor;

    address public esMyc;
    address public bnMyc;

    address public mycVester;
    address public mlpVester;

    function initialize(
        ITimelock _timelock,
        address _rewardRouter,
        address _mlpManager,
        address _stakedMycTracker,
        address _bonusMycTracker,
        address _feeMycTracker,
        address _feeMlpTracker,
        address _stakedMlpTracker,
        address _stakedMycDistributor,
        address _stakedMlpDistributor,
        address _esMyc,
        address _bnMyc,
        address _mycVester,
        address _mlpVester
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        mlpManager = _mlpManager;

        stakedMycTracker = _stakedMycTracker;
        bonusMycTracker = _bonusMycTracker;
        feeMycTracker = _feeMycTracker;

        feeMlpTracker = _feeMlpTracker;
        stakedMlpTracker = _stakedMlpTracker;

        stakedMycDistributor = _stakedMycDistributor;
        stakedMlpDistributor = _stakedMlpDistributor;

        esMyc = _esMyc;
        bnMyc = _bnMyc;

        mycVester = _mycVester;
        mlpVester = _mlpVester;
    }

    function updateEsMycHandlers() external onlyGov {
        timelock.managedSetHandler(esMyc, rewardRouter, true);

        timelock.managedSetHandler(esMyc, stakedMycDistributor, true);
        timelock.managedSetHandler(esMyc, stakedMlpDistributor, true);

        timelock.managedSetHandler(esMyc, stakedMycTracker, true);
        timelock.managedSetHandler(esMyc, stakedMlpTracker, true);

        timelock.managedSetHandler(esMyc, mycVester, true);
        timelock.managedSetHandler(esMyc, mlpVester, true);
    }

    /**
     * @notice set the rewardRouter as the handler for esMyc, stakedMycTracker, feeMycTracker, bnMyc, esMyc, mycVester, feeMycTracker,
     *         mlpManager, feeMlpTracker, stakedMlpTracker, mlpVester, stakedMlpTracker
     */
    function enableRewardRouter() external onlyGov {
        if (
            esMyc != address(0) &&
            stakedMycTracker != address(0) &&
            feeMycTracker != address(0) &&
            bonusMycTracker != address(0) &&
            bnMyc != address(0) &&
            esMyc != address(0) &&
            mycVester != address(0) &&
            feeMycTracker != address(0)
        ) {
            timelock.managedSetHandler(esMyc, rewardRouter, true);
            timelock.managedSetHandler(stakedMycTracker, rewardRouter, true);
            timelock.managedSetHandler(feeMycTracker, rewardRouter, true);
            timelock.managedSetHandler(bonusMycTracker, rewardRouter, true);
            timelock.managedSetMinter(bnMyc, rewardRouter, true);
            timelock.managedSetMinter(esMyc, mycVester, true);
            timelock.managedSetHandler(mycVester, rewardRouter, true);
            timelock.managedSetHandler(feeMycTracker, mycVester, true);
            timelock.managedSetMinter(esMyc, mlpVester, true);
        }
        timelock.managedSetHandler(mlpManager, rewardRouter, true);

        timelock.managedSetHandler(feeMlpTracker, rewardRouter, true);
        timelock.managedSetHandler(stakedMlpTracker, rewardRouter, true);

        timelock.managedSetHandler(mlpVester, rewardRouter, true);

        timelock.managedSetHandler(stakedMlpTracker, mlpVester, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelock {
    function setAdmin(address _admin) external;

    function enableLeverage(address _vault) external;

    function disableLeverage(address _vault) external;

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;

    function signalSetGov(address _target, address _gov) external;

    function managedSetHandler(
        address _target,
        address _handler,
        bool _isActive
    ) external;

    function managedSetMinter(
        address _target,
        address _minter,
        bool _isActive
    ) external;
}