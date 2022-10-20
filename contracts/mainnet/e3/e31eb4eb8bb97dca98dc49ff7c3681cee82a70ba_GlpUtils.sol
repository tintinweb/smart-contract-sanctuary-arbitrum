// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGlpUtils} from "src/IGlpUtils.sol";
import {IVaultReader} from "gmx/IVaultReader.sol";
import {TokenExposure} from "src/TokenExposure.sol";
import {GlpTokenAllocation} from "src/GlpTokenAllocation.sol";

contract GlpUtils is IGlpUtils {
    IVaultReader private vaultReader;
    address private vaultAddress;
    address private positionManagerAddress;
    address private wethAddress;

    uint256 private constant GLP_DIVISOR = 1 * 10**18;
    uint256 private constant VAULT_PROPS_LENGTH = 14;
    uint256 private constant PERCENT_MULTIPLIER = 10000;

    constructor(
        address _vaultReaderAddress,
        address _vaultAddress,
        address _positionManagerAddress,
        address _wethAddress
    ) {
        vaultReader = IVaultReader(_vaultReaderAddress);
        vaultAddress = _vaultAddress;
        positionManagerAddress = _positionManagerAddress;
        wethAddress = _wethAddress;
    }

    function getGlpTokenAllocations(address[] memory tokens)
        public
        view
        returns (GlpTokenAllocation[] memory)
    {
        uint256[] memory tokenInfo = vaultReader.getVaultTokenInfoV3(
            vaultAddress,
            positionManagerAddress,
            wethAddress,
            GLP_DIVISOR,
            tokens
        );

        GlpTokenAllocation[]
            memory glpTokenAllocations = new GlpTokenAllocation[](
               tokens.length 
            );

        uint256 totalSupply = 0;
        for (uint256 index = 0; index < tokens.length; index++) {
            totalSupply += tokenInfo[index * VAULT_PROPS_LENGTH + 2];
        }

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 poolAmount = tokenInfo[index * VAULT_PROPS_LENGTH];
            uint256 usdgAmount = tokenInfo[index * VAULT_PROPS_LENGTH + 2];
            uint256 weight = tokenInfo[index * VAULT_PROPS_LENGTH + 4];
            uint256 allocation = (usdgAmount * PERCENT_MULTIPLIER) /
                totalSupply;

            glpTokenAllocations[index] = GlpTokenAllocation({
                tokenAddress: tokens[index],
                poolAmount: poolAmount,
                usdgAmount: usdgAmount,
                weight: weight,
                allocation: allocation
            });
        }

        return glpTokenAllocations;
    }

    function getGlpTokenExposure(
        uint256 glpPositionWorth,
        address[] memory tokens
    ) external view returns (TokenExposure[] memory) {
        GlpTokenAllocation[] memory tokenAllocations = getGlpTokenAllocations(
            tokens
        );
        TokenExposure[] memory tokenExposures = new TokenExposure[](
            tokenAllocations.length
        );

        for (uint256 i = 0; i < tokenAllocations.length; i++) {
            tokenExposures[i] = TokenExposure({
                amount: int256((glpPositionWorth * tokenAllocations[i].allocation) /
                    PERCENT_MULTIPLIER),
                token: tokenAllocations[i].tokenAddress
            });
        }

        return tokenExposures;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenExposure} from "src/TokenExposure.sol";
import {GlpTokenAllocation} from "src/GlpTokenAllocation.sol";

interface IGlpUtils {
    function getGlpTokenAllocations(address[] memory tokens)
        external
        view
        returns (GlpTokenAllocation[] memory);

    function getGlpTokenExposure(
        uint256 glpPositionWorth,
        address[] memory tokens
    ) external view returns (TokenExposure[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVaultReader {
  function getVaultTokenInfoV3(address _vault, address _positionManager, address _weth, uint256 _usdgAmount, address[] memory _tokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPositionManager} from "src/IPositionManager.sol";

struct TokenExposure {
  int256 amount;
  address token; 
}

struct NetTokenExposure {
  int256 amount;
  address token; 
  uint32 amountOfPositions;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct GlpTokenAllocation {
  address tokenAddress;
  uint256 poolAmount;
  uint256 usdgAmount;
  uint256 weight;
  uint256 allocation;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenExposure,NetTokenExposure} from "src/TokenExposure.sol";
import {TokenAllocation} from "src/TokenAllocation.sol";
import {RebalanceAction} from "src/RebalanceAction.sol";

abstract contract IPositionManager {
  function positionWorth() virtual external view returns (uint256);
  function costBasis() virtual external view returns (uint256);
  function pnl() virtual external view returns (int256);
  function exposures() virtual external view returns (TokenExposure[] memory);
  function allocation() virtual external view returns (TokenAllocation[] memory );
  function buy(uint256) virtual external returns (uint256);
  function sell(uint256) virtual external returns (uint256);
  function price() virtual external view returns (uint256);
  function canRebalance() virtual external view returns (bool);
  function rebalance(uint256 usdcAmountToHave) virtual external returns (bool) {
    RebalanceAction rebalanceAction = this.getRebalanceAction(usdcAmountToHave);
    uint256 worth = this.positionWorth();
    if (rebalanceAction == RebalanceAction.Buy) {
      this.buy(usdcAmountToHave - worth);
    } else if (rebalanceAction == RebalanceAction.Sell) {
      this.sell(worth - usdcAmountToHave);
    }

    return true;
  }

  function allocationByToken(address tokenAddress) external view returns (TokenAllocation memory) {
    TokenAllocation[] memory tokenAllocations = this.allocation();
    for (uint256 i = 0; i < tokenAllocations.length; i++) {
        if (tokenAllocations[i].tokenAddress == tokenAddress) {
          return tokenAllocations[i];
        }
    } 

    revert("Token not found");
  }

  function getRebalanceAction(uint256 usdcAmountToHave) external view returns (RebalanceAction) {
    uint256 worth = this.positionWorth();
    if (usdcAmountToHave > worth) return RebalanceAction.Buy;
    if (usdcAmountToHave < worth) return RebalanceAction.Sell;
    return RebalanceAction.Nothing; 
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

uint32 constant PERCENTAGE_DIVISOR = 1000;

struct TokenAllocation {
  uint256 percentage;
  address tokenAddress;
  uint256 leverage;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

enum RebalanceAction {
  Nothing,
  Buy,
  Sell
}