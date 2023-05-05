// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IVOLTGLP {
    function price() external view returns(uint);
}

interface IGLPPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

contract VoltGLPPriceSource {
    
    IVOLTGLP public voltGLPPriceProvider;
    IGLPPrice public glpPriceSource;

    constructor(address voltGLP_, address glp_) {
        voltGLPPriceProvider = IVOLTGLP(voltGLP_);
        glpPriceSource = IGLPPrice(glp_);
    } 

	function getPrice() external view returns(uint) {
        return getPriceWithoutCompound();
    }

    function getPriceWithoutCompound() public view returns(uint) {
        return voltGLPPriceProvider.price() * uint(getGLPPrice()) / 10 ** glpPriceSource.decimals();
    }

    function getGLPPrice() public view returns(int256) { // 30 dec
        (,int256 glpPrice,,,) = glpPriceSource.latestRoundData();

        if(glpPrice != 0) {
            return glpPrice;
        }
        revert();
    }
}