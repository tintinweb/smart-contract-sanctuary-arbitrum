/**
 *Submitted for verification at Arbiscan on 2023-05-03
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: arbgmUSD.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokensSimple(uint256 amountIn, uint256 amountOutMin, address tokenFrom,
    address tokenTo,
    bool stable, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

// From https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol
interface IUniswapV3Router {
     struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

interface gmUSD is IERC20 {
  function mint(uint256 _amount, IERC20 _token) external;
 function redeem(uint256 _amount, IERC20 _token) external;
}

struct PathDATA {
  address from;
  address to;
  bool stable; 
}

contract gmUSDArb is Ownable {

  address [] public routers;
  address [] public univ3routers;
  address [] public tokens;
  address [] public stables;
  gmUSD public _gmUSD = gmUSD(0xEC13336bbd50790a00CDc0fEddF11287eaF92529);
  IERC20 public gmdUSDC = IERC20(0x3DB4B7DA67dd5aF61Cb9b3C70501B1BdB24b2C22);
  IERC20 public gDAI = IERC20(0xd85E038593d7A098614721EaE955EC2022B9B91B);

  address public router = 0xF26515D5482e2C2FD237149bF6A653dA4794b3D0;
  address public univ3router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

  // See https://docs.uniswap.org/contracts/v3/reference/periphery/interfaces/ISwapRouter#parameter-structs 
  // and https://uniswap.fish/?network=ethereum
   uint24 constant public fee01 = 100;    // 0.01% - Best for very stable pairs
   uint24 constant public fee05 = 500;    // 0.05% - Best for stable pairs
   uint24 constant public fee30 = 3000;   // 0.30% - Best for most pairs
   uint24 constant public fee100 = 10000; // 1.00% - Best for exotic pairs

  function addRouters(address[] calldata _routers) external onlyOwner {
    for (uint i=0; i<_routers.length; i++) {
      routers.push(_routers[i]);
    }
  }

  function addUniv3Routers(address[] calldata _routers) external onlyOwner {
    for (uint i=0; i<_routers.length; i++) {
      univ3routers.push(_routers[i]);
    }
  }

  function addTokens(address[] calldata _tokens) external onlyOwner {
    for (uint i=0; i<_tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
  }

  function addStables(address[] calldata _stables) external onlyOwner {
    for (uint i=0; i<_stables.length; i++) {
      stables.push(_stables[i]);
    }
  }

  function swap(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _routerID) public onlyOwner {
    uint deadline = block.timestamp + 3000;
    IERC20(_tokenIn).approve(routers[_routerID], _amount);
    IUniswapV2Router(routers[_routerID]).swapExactTokensForTokensSimple(_amount, 0, _tokenIn,_tokenOut, true, address(this), deadline);
  }

function swap2(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _routerID) public onlyOwner {
    uint deadline = block.timestamp + 3000;
    IERC20(_tokenIn).approve(routers[_routerID], _amount);
    IUniswapV2Router(routers[_routerID]).swapExactTokensForTokensSimple(_amount, 0, _tokenIn,_tokenOut, false, address(this), deadline);
  }

function univ3swap(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _routerID) public onlyOwner {
    uint deadline = block.timestamp + 3000;
    IERC20(_tokenIn).approve(univ3routers[_routerID], _amount);
    
    IUniswapV3Router(univ3routers[_routerID]).exactInputSingle(
        IUniswapV3Router.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: fee05,
            recipient: address(this),
            deadline: deadline,
            amountIn: _amount,
            amountOutMinimum: _amount, //Note:  technically we can probably do 0 b/c afterwards we revert if not profitable.  This just assumes 1:1 as a mininum
            sqrtPriceLimitX96: 0  //  We set this to zero - which makes this parameter inactive. In production, this value can be used to set the limit for the price the swap will push the pool to, which can help protect against price impact or for setting up logic in a variety of price-relevant mechanisms. (from https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps)
        })
    );

  }

  function mintGMUSD(uint256 _amount, IERC20 token) private {
     token.approve(address(_gmUSD), _amount);
    _gmUSD.mint(_amount, token);
  }

  function redeemGMUSD(uint256 _amount, IERC20 token) private {
    _gmUSD.approve(address(_gmUSD), _amount);
    _gmUSD.redeem(_amount, token);
  }


  function approveT(uint256 amount) external onlyOwner {
        _gmUSD.approve(address(_gmUSD), amount);
        gmdUSDC.approve(address(_gmUSD), amount);
        gDAI.approve(address(_gmUSD), amount);
  }

  
  function MintAndSellWithGMDUSDC(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(gmdUSDC).balanceOf(address(this));
    mintGMUSD(_amount, gmdUSDC);
    swap(address(_gmUSD) , address(gmdUSDC), _amount, _routerID);
    uint endBalance = IERC20(gmdUSDC).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

  function MintAndSellWithGDAI(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(gDAI).balanceOf(address(this));
    mintGMUSD(_amount, gDAI);
    swap(address(_gmUSD) , address(gDAI), _amount, _routerID);
    uint endBalance = IERC20(gDAI).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

// non stable pool 

    function MintAndSellWithGMDUSDC2(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(gmdUSDC).balanceOf(address(this));
    mintGMUSD(_amount, gmdUSDC);
    swap2(address(_gmUSD) , address(gmdUSDC), _amount, _routerID);
    uint endBalance = IERC20(gmdUSDC).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

  function MintAndSellWithGDAI2(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(gDAI).balanceOf(address(this));
    mintGMUSD(_amount, gDAI);
    swap2(address(_gmUSD) , address(gDAI), _amount, _routerID);
    uint endBalance = IERC20(gDAI).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

//univ3

  function MintAndSellWithGMDUSDCuniv3(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(gmdUSDC).balanceOf(address(this));
    mintGMUSD(_amount, gmdUSDC);
    univ3swap(address(_gmUSD) , address(gmdUSDC), _amount, _routerID);
    uint endBalance = IERC20(gmdUSDC).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

  function MintAndSellWithGDAIuniv3(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(gDAI).balanceOf(address(this));
    mintGMUSD(_amount, gDAI);
    univ3swap(address(_gmUSD) , address(gDAI), _amount, _routerID);
    uint endBalance = IERC20(gDAI).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

//buy solidly 
  function BuyAndRedeemWithGMDUSDC(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(_gmUSD).balanceOf(address(this));
    swap(address(gmdUSDC), address(_gmUSD) ,  _amount, _routerID);
    redeemGMUSD(_amount, gmdUSDC);
    
    uint endBalance = IERC20(_gmUSD).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

  function BuyAndRedeemWithGDAI(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(_gmUSD).balanceOf(address(this));
    swap(address(gDAI), address(_gmUSD) ,  _amount, _routerID);
    redeemGMUSD(_amount, gDAI);
    uint endBalance = IERC20(_gmUSD).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

  //buy univ3
  function BuyAndRedeemWithGMDUSDCuniv3(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(_gmUSD).balanceOf(address(this));
    univ3swap(address(gmdUSDC), address(_gmUSD) ,  _amount, _routerID);
    redeemGMUSD(_amount, gmdUSDC);
    
    uint endBalance = IERC20(_gmUSD).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 

  function BuyAndRedeemWithGDAIuniv3(uint256 _amount, uint256 _routerID) external onlyOwner {
    
    uint startBalance = IERC20(_gmUSD).balanceOf(address(this));
    univ3swap(address(gDAI), address(_gmUSD) ,  _amount, _routerID);
    redeemGMUSD(_amount, gDAI);
    uint endBalance = IERC20(_gmUSD).balanceOf(address(this));

    require(endBalance > (startBalance+1e18), "Trade Reverted, No Profit Made");
  } 
  function getBalance (address _tokenContractAddress) external view  returns (uint256) {
    uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
    return balance;
  }
  
  function recoverEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function recoverTokens(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

}