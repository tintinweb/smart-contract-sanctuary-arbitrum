// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPriceRouter {
    function getTokenPrice(address token, address itoken, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface iTokenDForce {
    /**
     * @dev Calculates the exchange rate without accruing interest.
     */
    function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface iTokenLodestar {
    /**
     * @dev Calculates the exchange rate without accruing interest.
     */
    function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface iTokenWePiggy {
    /**
     * @dev Calculates the exchange rate without accruing interest.
     */
    function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "contracts/interfaces/IPriceRouter.sol";
import "./interfaces/iTokenDForce.sol";
import "./interfaces/iTokenWePiggy.sol";
import "./interfaces/iTokenLodestar.sol";

//need to make the contract upgredable
contract PriceRouter is IPriceRouter {
    uint256 public routerDecimals = 18;

    address public usdt;
    address public usdc_e;
    address public wbtc;
    address public weth;
    address public arb;

    constructor(address _usdt, address _usdc_e, address _wbtc, address _weth, address _arb) {
        usdt = _usdt;
        usdc_e = _usdc_e;
        wbtc = _wbtc;
        weth = _weth;
        arb = _arb;
    }

    function getTokenPrice(address token, address itoken, uint256 amount) public view returns (uint256) {
        if (token == usdt) {
            //radiant V2
            if (itoken == address(0xd69D402D1bDB9A2b8c3d88D98b9CEaf9e4Cd72d9)) {
                return amount;
            }
            //granary
            if (itoken == address(0x66ddD8F3A0C4CEB6a324376EA6C00B4c8c1BB3d9)) {
                return amount;
            }
            //AAVE V3
            if (itoken == address(0x6ab707Aca953eDAeFBc4fD23bA73294241490620)) {
                return amount;
            }
            //dForce
            if (itoken == address(0xf52f079Af080C9FB5AFCA57DDE0f8B83d49692a9)) {
                return ((amount * iTokenDForce(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
            //wepiggy
            if (itoken == address(0xB65Ab7e1c6c1Ba202baed82d6FB71975D56F007C)) {
                return ((amount * iTokenWePiggy(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
            //lodestar
            if (itoken == address(0x9365181A7df82a1cC578eAE443EFd89f00dbb643)) {
                return ((amount * iTokenLodestar(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
        } else if (token == usdc_e) {
            //radiant V2
            if (itoken == address(0x48a29E756CC1C097388f3B2f3b570ED270423b3d)) {
                return amount;
            }
            //granary
            if (itoken == address(0x6C4CB1115927D50E495E554d38b83f2973F05361)) {
                return amount;
            }
            //AAVE V3
            if (itoken == address(0x625E7708f30cA75bfd92586e17077590C60eb4cD)) {
                return amount;
            }
            //dForce
            if (itoken == address(0x8dc3312c68125a94916d62B97bb5D925f84d4aE0)) {
                return ((amount * iTokenDForce(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
            //wepiggy
            if (itoken == address(0x2Bf852e22C92Fd790f4AE54A76536c8C4217786b)) {
                return ((amount * iTokenWePiggy(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
            //compound V3
            if (itoken == address(0xA5EDBDD9646f8dFF606d7448e414884C7d905dCA)) {
                return amount;
            }
            //lodestar
            if (itoken == address(0x1ca530f02DD0487cef4943c674342c5aEa08922F)) {
                return ((amount * iTokenLodestar(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
        } else if (token == wbtc) {
            //radiant V2
            if (itoken == address(0x727354712BDFcd8596a3852Fd2065b3C34F4F770)) {
                return amount;
            }
            //granary V2
            if (itoken == address(0x731e2246A0c67b1B19188C7019094bA9F107404f)) {
                return amount;
            }
            //AAVE V3
            if (itoken == address(0x078f358208685046a11C85e8ad32895DED33A249)) {
                return amount;
            }
            //dForce
            if (itoken == address(0xD3204E4189BEcD9cD957046A8e4A643437eE0aCC)) {
                return ((amount * iTokenDForce(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
            //wepiggy
            if (itoken == address(0x3393cD223f59F32CC0cC845DE938472595cA48a1)) {
                return ((amount * iTokenWePiggy(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
            //lodestar
            if (itoken == address(0xC37896BF3EE5a2c62Cdbd674035069776f721668)) {
                return ((amount * iTokenLodestar(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
        } else if (token == weth) {
            //radiant V2
            if (itoken == address(0x0dF5dfd95966753f01cb80E76dc20EA958238C46)) {
                return amount;
            }
            //AAVE V3
            if (itoken == address(0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8)) {
                return amount;
            }
        } else if (token == arb) {
            //radiant V2
            if (itoken == address(0x2dADe5b7df9DA3a7e1c9748d169Cd6dFf77e3d01)) {
                return amount;
            }
            //AAVE V3
            if (itoken == address(0x6533afac2E7BCCB20dca161449A13A32D391fb00)) {
                return amount;
            }
            //granary
            if (itoken == address(0x8B9a4ded05ad8C3AB959980538437b0562dBb129)) {
                return amount;
            }
            //lodestar
            if (itoken == address(0x8991d64fe388fA79A4f7Aa7826E8dA09F0c3C96a)) {
                return ((amount * iTokenLodestar(itoken).exchangeRateStored()) / (10 ** routerDecimals));
            }
        }

        revert("Not supported token");
    }
}