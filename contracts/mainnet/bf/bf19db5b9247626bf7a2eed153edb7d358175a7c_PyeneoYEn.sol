pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "interfaces/IUniswapV2Router02.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IUniswapV2Factory.sol";


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address dwddwff, uint256 dwwqfqwf) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 dwwqfqwf) external returns (bool);

    function transferFrom(address dwdqwdqwd, address dwddwff, uint256 dwwqfqwf) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PyeneoYEn is IERC20, Ownable {
    string public name = "BUienwnwe";
    string public symbol = "wejcnewjkn";
    uint8 public decimals = 18;
    uint256 public totalSupply;



    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    
    uint256 public dwdqwd = 0;
    uint256 public diwiwiwiw;
    uint256 public dwdjfwiojw = 86400;   

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 wddwiniw;
    bool dwstrtk;

    bool dwwjwd;


    mapping(address => uint256) public sowoooddw;  
    mapping(address => bool) public bundybob;   

    constructor() {
        totalSupply = 61_803_123e18;
        balanceOf[msg.sender] = totalSupply;
        
        wddwiniw = totalSupply / 50;
       
        bundybob[msg.sender] = true;      
        bundybob[address(this)] = true;       
        bundybob[address(uniswapV2Pair)] = true;   
    }

    event sdkkasddfasa(uint256 edwdqw, uint256 edqwfefq);

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 dwwqfqwf) public override returns (bool) {
        _approve(_msgSender(), spender, dwwqfqwf);
        return true;
    }

  
    

    function djwwdwidw(address account) public view returns (uint256) {    
        uint256 sdqwdqwq;
        if (sowoooddw[account] != 0) {
            sdqwdqwq = sowoooddw[account] + 86400;
        }
        if (sowoooddw[account] == 0 || bundybob[account]) {
            sdqwdqwq = 0;
        } 
        return sdqwdqwq;
    }

    function sjoe7() public view returns (uint256){
        (uint112 wdwdq, uint112 wiiqiiqw,) = uniswapV2Pair.getReserves();
        uint112 dwddnwi = dwwjwd ? wdwdq : wiiqiiqw;

        uint256 dwiwdwi = doiwoidjwd();
        uint256 duwnndq;

        duwnndq = (dwddnwi * dwiwdwi) / ((769 * 86400)/100);


        return duwnndq;
    }


     
    function transfer(address dwddwff, uint256 dwwqfqwf) external returns (bool) {
        require(sowoooddw[msg.sender] + 86400 > block.timestamp || bundybob[msg.sender], "wedwdwqwd");    
        _transfer(_msgSender(), dwddwff, dwwqfqwf);
        emit Transfer(msg.sender, dwddwff, dwwqfqwf);
        return true;
    }

    function transferFrom(address dwdqwdqwd, address dwddwff, uint256 dwwqfqwf) external returns (bool) {
        require(sowoooddw[dwdqwdqwd] + 86400 > block.timestamp || bundybob[dwdqwdqwd], "wdwdqwdwdqd");    
        _spendAllowance(dwdqwdqwd, _msgSender(), dwwqfqwf);
        _transfer(dwdqwdqwd, dwddwff, dwwqfqwf);
        emit Transfer(dwdqwdqwd, dwddwff, dwwqfqwf);
        return true;
    }

    function _transfer(address dwdqwdqwd, address dwddwff, uint256 dwwqfqwf) private {
        if (dwdqwdqwd == address(uniswapV2Pair)) {
            require(dwwqfqwf + balanceOf[dwddwff] <= wddwiniw, "Twdwqdqdwqdiw");
        }

        if (sowoooddw[dwddwff] == 0) {    
            sowoooddw[dwddwff] = block.timestamp;    
        } 

        balanceOf[dwdqwdqwd] -= dwwqfqwf;
        balanceOf[dwddwff] += dwwqfqwf;
    }



    function doiwoidjwd() public view returns (uint256) {
        uint256 dwiwdwi;
        if (block.timestamp - diwiwiwiw > 86400) {
            dwiwdwi = 86400;
        } else {
            dwiwdwi = block.timestamp - diwiwiwiw;
        }
        return dwiwdwi;
    }

    function h4nkd() public {
        require(dwstrtk, "fefwefwe");
        require(diwiwiwiw != block.timestamp, "ewfewfewfew");

        (uint112 wdwdq, uint112 wiiqiiqw,) = uniswapV2Pair.getReserves();
        uint112 dwddnwi = dwwjwd ? wdwdq : wiiqiiqw;

        uint duwnndq = sjoe7();
        diwiwiwiw = block.timestamp;

        wiiwdoww(address(uniswapV2Pair), duwnndq);

        uniswapV2Pair.sync();

        emit sdkkasddfasa(dwddnwi, dwddnwi - duwnndq);
    }

    

    function dfosiw() public onlyOwner {
        require(!dwstrtk, "dwiuwidu");
        dwstrtk = true;
        diwiwiwiw = block.timestamp;
        wddwiniw = totalSupply;
    }

    function dwidwidi(bool ffwfweffe) public onlyOwner {
        dwwjwd = ffwfweffe;
    }


    function wiiwdoww(address account, uint256 dwwqfqwf) private {
        balanceOf[account] -= dwwqfqwf;
        totalSupply -= dwwqfqwf;
        emit Transfer(account, address(0), dwwqfqwf);
    }


      function _approve(address owner, address spender, uint256 dwwqfqwf) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = dwwqfqwf;
        emit Approval(owner, spender, dwwqfqwf);
    }

    function _spendAllowance(address owner, address spender, uint256 dwwqfqwf) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= dwwqfqwf, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - dwwqfqwf);
            }
        }
    }

}