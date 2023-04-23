/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************************
 *                    Ownable
 **************************************************/
contract Ownable {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    constructor() {
        owner = msg.sender;
    }
}

/**************************************************
 *                    Interfaces
 **************************************************/
interface IPair {
    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256);
}

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256 answer);
}

/**************************************************
 *               Deus Solidly Oracle
 **************************************************/
contract DeusSolidlyOracle is Ownable {
    /**************************************************
     *                 Initialization
     **************************************************/
    IPair constant wethDeusPair =
        IPair(0x93D98B4Caac02385a0ae7caaeADC805F48553F76);
    IChainLinkOracle constant ethUsdOracle =
        IChainLinkOracle(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    address public constant deus = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;
    uint256 public points = 4; // 2 hours

    function wethPrice() public view returns (uint256) {
        return ethUsdOracle.latestAnswer(); // 8 decimals
    }

    function wethPerDeus() public view returns (uint256) {
        return wethDeusPair.quote(deus, 1 * 10 ** 18, points); // 18 decimals
    }

    function deusPriceUsdc() public view returns (uint256) {
        return (wethPrice() * wethPerDeus()) / 10 ** (18 + 8 - 6); // 18 weth decimals, 8 chainlink oracle decimals, denominated in 6 decimal places (usdc)
    }

    function setPoints(uint256 _points) external onlyOwner {
        points = _points;
    }
}