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

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    IGlpWrapperHarvestor public immutable harvestor;

    constructor(IGlpWrapperHarvestor _harvestor) {
        harvestor = _harvestor;
    }

    // Source: https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    // returns the apy in bips scaled by 1e18
    function getCaulronTargetApy(address _cauldron) external view returns (uint256) {
        IMimCauldronDistributor distributor = harvestor.distributor();
        uint256 cauldronInfoCount = distributor.getCauldronInfoCount();

        for (uint256 i = 0; i < cauldronInfoCount; ) {
            (address cauldron, uint256 targetApyPerSecond, , , , , , ) = distributor.cauldronInfos(i);

            if (cauldron == _cauldron) {
                return mulWadUp(targetApyPerSecond, 365 days);
            }

            // for the meme.
            unchecked {
                ++i;
            }
        }

        revert ErrCauldronNotFound(_cauldron);
    }
}