// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IDeflationManager.sol";
import "./libraries/access/Governable.sol";

contract DeflationManager is IDeflationManager,  Governable{
    mapping (address => bool) public isDeflationRewardTracker;
    mapping (address => mapping(address => uint256)) public override cumulativeRewards;
    mapping (address => mapping(address => uint256)) public override averageStakedAmounts;

    function setDeflationRewardTracker(address _deflationRewardTracker, bool _isActive) public onlyGov {
        isDeflationRewardTracker[_deflationRewardTracker] = _isActive;
    }

    function updateStatus(
        address _account, 
        address _rewardToken,
        uint256 _cumulativeReward,
        uint256 _averageStakedAmount
    ) public override {
        require(isDeflationRewardTracker[msg.sender], "DeflationManager: only UTPRewardTracker");
        cumulativeRewards[_account][_rewardToken] = _cumulativeReward;
        averageStakedAmounts[_account][_rewardToken] = _averageStakedAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDeflationManager {

    function cumulativeRewards(address _account, address _depositToken) external returns(uint256);
    function averageStakedAmounts(address _account, address _depositToken) external returns(uint256);

    function updateStatus(
        address _account, 
        address _rewardToken,
        uint256 _cumulativeReward,
        uint256 _averageStakedAmount
    ) external;
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