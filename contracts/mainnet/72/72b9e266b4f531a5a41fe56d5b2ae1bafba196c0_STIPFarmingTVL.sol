// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestor {
    function strategies(uint256) external view returns (address);
}

interface IStrategy {
    function totalShares() external view returns (uint256);
    function rate(uint256) external view returns (uint256);
}

contract STIPFarmingTVL {
    IInvestor investor = IInvestor(0x8accf43Dd31DfCd4919cc7d65912A475BfA60369);

    function tvl() external view returns (uint256) {
        IStrategy s;
        uint256 total;
        for (uint256 i = 43; i <= 48; i++) {
            s = IStrategy(investor.strategies(i));
            total += s.rate(s.totalShares());
        }
        return total;
    }
}