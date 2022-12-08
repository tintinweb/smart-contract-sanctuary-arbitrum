// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/IMimCauldronDistributor.sol";

interface IGlpWrapperHarvestor {
    function claimable() external view returns (uint256);

    function distributor() external view returns (IMimCauldronDistributor);

    function lastExecution() external view returns (uint64);

    function operators(address) external view returns (bool);

    function outputToken() external view returns (address);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function rewardRouterV2() external view returns (address);

    function rewardToken() external view returns (address);

    function run(uint256 amountOutMin, bytes memory data) external;

    function setDistributor(address _distributor) external;

    function setOperator(address operator, bool status) external;

    function setOutputToken(address _outputToken) external;

    function setRewardRouterV2(address _rewardRouterV2) external;

    function setRewardToken(address _rewardToken) external;

    function totalRewardsBalanceAfterClaiming() external view returns (uint256);

    function wrapper() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMimCauldronDistributor {
    function cauldronInfos(uint256)
        external
        view
        returns (
            address cauldron,
            uint256 targetApyPerSecond,
            uint64 lastDistribution,
            address oracle,
            bytes memory oracleData,
            address degenBox,
            address collateral,
            uint256 minTotalBorrowElastic
        );

    function distribute() external;

    function feeCollector() external view returns (address);

    function feePercent() external view returns (uint8);

    function getCauldronInfoCount() external view returns (uint256);

    function paused() external view returns (bool);

    function setCauldronParameters(
        address _cauldron,
        uint256 _targetApyBips,
        uint256 _minTotalBorrowElastic
    ) external;

    function setFeeParameters(address _feeCollector, uint8 _feePercent) external;

    function setPaused(bool _paused) external;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/IGlpWrapperHarvestor.sol";
import "interfaces/IMimCauldronDistributor.sol";

contract MimCauldronDistributorLens {
    error ErrCauldronNotFound(address);

    IGlpWrapperHarvestor public immutable harvestor;

    constructor(IGlpWrapperHarvestor _harvestor) {
        harvestor = _harvestor;
    }

    function getCaulronTargetApy(address _cauldron) external view returns (uint256) {
        IMimCauldronDistributor distributor = harvestor.distributor();
        uint256 cauldronInfoCount = distributor.getCauldronInfoCount();

        for (uint256 i = 0; i < cauldronInfoCount; ) {
            (address cauldron, uint256 targetApyPerSecond, , , , , , ) = distributor.cauldronInfos(i);

            if (cauldron == _cauldron) {
                return (targetApyPerSecond * 365 days) / 1e18;
            }

            // for the meme.
            unchecked {
                ++i;
            }
        }

        revert ErrCauldronNotFound(_cauldron);
    }
}