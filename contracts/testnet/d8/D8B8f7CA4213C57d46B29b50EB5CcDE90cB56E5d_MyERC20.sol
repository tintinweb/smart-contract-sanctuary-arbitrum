/**
 *Submitted for verification at Arbiscan on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyERC20 {
    address public immutable _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint8 public immutable percentBurn = 5;
    uint8 public immutable percentFee = 5;

    event Transfer (address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        _owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount ) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount);
        _allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function mint(uint256 amount) external onlyOwner {
        _balances[_owner] += amount;
        _totalSupply += amount;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
 
        uint256 burnAmount = amount*percentBurn/100;
        uint256 feeAmount = amount*percentFee/100;

        _balances[from] -= amount - burnAmount;
        _balances[to] += amount - burnAmount - feeAmount;
        _balances[_owner] += feeAmount;

        _burn(from, burnAmount);

        emit Transfer(from, to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(_balances[from] >= amount, "ERC20: burn amount exceeds balance");
        _balances[from] -= amount;
        _totalSupply -= amount;
    }

}