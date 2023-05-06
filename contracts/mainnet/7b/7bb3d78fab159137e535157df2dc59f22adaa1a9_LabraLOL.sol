/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// SPDX-License-Identifier: MIT
// LOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOL
// LOL      LOLLOLLOLLOLLOLLOLLOLLOL      LOLLOLLOLLOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOLLOLLOL   LOLLOL   LOLLOLLOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL   LOLLOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOL   LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOL   LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOL   LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOL   LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOL   LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOL   LOLLOLLOLLOLLOLLOL   LOLLOLLOLLOL      LOLLOLLOL   LOL
// LOL      LOLLOLLOLLOLLOLOL    LOLLOLLOLLOL    LOLLOLLOLLOLLO      LLOLLOLLOLLOLOL
// LOL           LLOLLOLLOLLOLLOL   LOLLOL   LOLLOLLOLLOLLOLLOL            LOL   LOL
// LOL           LLOLLOLLOLLOLLOLLOL      LOLLOLLOLLOLLOLLOLLOL            LOL   LOL
// LOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOL
// LOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOLLOL
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract LabraLOL is Context, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = "LabraLOL";
        _symbol = "BUD";
        _totalSupply = 100_000_000_000 * 10**18;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        renounceOwnership();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}