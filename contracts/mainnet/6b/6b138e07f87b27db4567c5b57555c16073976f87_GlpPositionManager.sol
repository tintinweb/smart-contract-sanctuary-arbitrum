// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPositionManager} from "src/IPositionManager.sol";
import {IPurchaser, Purchase} from "src/IPurchaser.sol";
import {IPriceUtils} from "src/IPriceUtils.sol";
import {TokenExposure} from "src/TokenExposure.sol";
import {IVaultReader} from "gmx/IVaultReader.sol";
import {IGlpUtils} from "src/IGlpUtils.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract GlpPositionManager is IPositionManager, Ownable {
  uint256 private constant USDC_MULTIPLIER = 1*10**6;
  uint256 private constant GLP_MULTIPLIER = 1*10**18;

  uint256 private costBasis;
  uint256 private tokenAmount;

  IPurchaser private glpPurchaser;
  IPriceUtils private priceUtils;
  IGlpUtils private glpUtils;
  address[] private glpTokens;

  constructor(address _glpPurchaserAddress, address _priceUtilsAddress, address _glpUtilsAddress) {
    glpPurchaser = IPurchaser(_glpPurchaserAddress);
    priceUtils = IPriceUtils(_priceUtilsAddress);
    glpUtils = IGlpUtils(_glpUtilsAddress);
  }

  function PositionWorth() public view returns (uint256) {
    uint256 glpPrice = priceUtils.glpPrice();
    return tokenAmount * glpPrice / GLP_MULTIPLIER;
  }

  function CostBasis() public view returns (uint256) {
    return costBasis;
  }

  function BuyPosition(uint256 usdcAmount) external returns (uint256) {
    Purchase memory purchase = glpPurchaser.Purchase(usdcAmount);
    costBasis += purchase.usdcAmount;
    tokenAmount += purchase.tokenAmount;  
    return purchase.tokenAmount;
  }

  function Pnl() external view returns (int256) {
    return int256(PositionWorth()) - int256(CostBasis());
  }

  function Exposures() external view returns (TokenExposure[] memory) {
    return glpUtils.getGlpTokenExposure(PositionWorth(), glpTokens);
  }

  function setGlpTokens(address[] memory _glpTokens) external onlyOwner() {
    glpTokens = _glpTokens;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenExposure} from "src/TokenExposure.sol";

interface IPositionManager {
  function PositionWorth() external view returns (uint256);
  function CostBasis() external view returns (uint256);
  function Pnl() external view returns (int256);
  function Exposures() external view returns (TokenExposure[] memory);

  function BuyPosition(uint256) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Purchase {
    uint256 usdcAmount;
    uint256 tokenAmount;
}

interface IPurchaser {
  function Purchase(uint256 usdcAmount) external returns (Purchase memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPriceUtils {
  function glpPrice() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct TokenExposure {
  uint256 amount;
  address token; 
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVaultReader {
  function getVaultTokenInfoV3(address _vault, address _positionManager, address _weth, uint256 _usdgAmount, address[] memory _tokens) external view returns (uint256[] memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}