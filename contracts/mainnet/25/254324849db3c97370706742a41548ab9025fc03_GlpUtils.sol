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

  uint256 private constant GLP_DIVISOR = 1*10**18;
  uint256 private constant VAULT_PROPS_LENGTH = 14;
  uint256 private constant PERCENT_MULTIPLIER = 10000;

  constructor(address _vaultReaderAddress, address _vaultAddress, address _positionManagerAddress, address _wethAddress) {
    vaultReader = IVaultReader(_vaultReaderAddress);
    vaultAddress = _vaultAddress;
    positionManagerAddress = _positionManagerAddress;
    wethAddress = _wethAddress;
  }

	function getGlpTokenAllocations(address[] memory tokens) external view returns (GlpTokenAllocation[] memory) {
    uint256[] memory tokenInfo = vaultReader.getVaultTokenInfoV3(vaultAddress, positionManagerAddress, wethAddress, GLP_DIVISOR, tokens);
    GlpTokenAllocation[] memory glpTokenAllocations = new GlpTokenAllocation[](tokenInfo.length);

    uint256 totalSupply = 0;
    for (uint256 index = 0; index < tokens.length; index++) {
      totalSupply += tokenInfo[index*VAULT_PROPS_LENGTH+2];
    }

    for (uint256 index = 0; index < tokens.length; index++) {
      uint256 poolAmount = tokenInfo[index*VAULT_PROPS_LENGTH];
      uint256 usdgAmount = tokenInfo[index*VAULT_PROPS_LENGTH+2];
      uint256 weight = tokenInfo[index*VAULT_PROPS_LENGTH+4];
      uint256 allocation = (usdgAmount * PERCENT_MULTIPLIER) / totalSupply;

      glpTokenAllocations[index] = GlpTokenAllocation({
        tokenAddress: tokens[index],
        poolAmount:   poolAmount,
        usdgAmount:   usdgAmount,
        weight:       weight,
        allocation:   allocation
      });
     }

     return glpTokenAllocations;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenExposure} from "src/TokenExposure.sol";
import {GlpTokenAllocation} from "src/GlpTokenAllocation.sol";

interface IGlpUtils {
	function getGlpTokenAllocations(address[] memory tokens) external view returns (GlpTokenAllocation[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVaultReader {
  function getVaultTokenInfoV3(address _vault, address _positionManager, address _weth, uint256 _usdgAmount, address[] memory _tokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct TokenExposure {
  uint256 amount;
  address token; 
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