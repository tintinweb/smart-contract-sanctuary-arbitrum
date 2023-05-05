// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGLPManager {
    function getPrice(bool) external view returns(uint); // 1e10
}

interface IChainlinkPriceFeed {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
	function decimals() external view returns (uint8);
}

contract GLPOracle is IChainlinkPriceFeed {
    
    IGLPManager public glpManager;

    constructor(address glpManager_) {
		glpManager = IGLPManager(glpManager_);
    } 

	function latestRoundData() external view override returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        uint256 price = glpManager.getPrice(false);
        return (0, int256(price), 0, 0, 0);
    }

    function decimals() external pure override returns (uint8) {
        return 30;
    }
}