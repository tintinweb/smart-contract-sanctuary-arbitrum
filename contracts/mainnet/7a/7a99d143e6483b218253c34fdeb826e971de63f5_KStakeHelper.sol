// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IStorage {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function stakeFor(address _from, address _to,uint _value) external returns (uint);
    function withdraw(address account, uint _index) external;
    function getUserStakeLength(address _addr) external view returns (uint256);
}

interface IStake {
    function updateRewardByHelper(address director) external;
    function getRewardByHelper(address _sender) external returns(uint);
}

contract KStakeHelper is Ownable {
    IStorage public stor;

    address public stakeETH;
    address public stakeUSDT;

    constructor(address _stor, address _stake, address _stakeu) {
        stor = IStorage(_stor);
        stakeETH = _stake;
        stakeUSDT = _stakeu;
    }

    function stakeFor(address _to, uint _value) public returns (uint){
        IStake(stakeETH).updateRewardByHelper(_to);
        IStake(stakeUSDT).updateRewardByHelper(_to);
        require(_value > 0, 'Cannot stake 0');
        stor.stakeFor(msg.sender, _to, _value);
        return _value;
    }

    function stake(uint _value) public returns (uint){
        return stakeFor(msg.sender, _value);
    }

    function withdraw(uint _index) public {
        IStake(stakeETH).updateRewardByHelper(msg.sender);
        IStake(stakeUSDT).updateRewardByHelper(msg.sender);
        stor.withdraw(msg.sender, _index);
    }

    function withdrawAll() public {
        IStake(stakeETH).updateRewardByHelper(msg.sender);
        IStake(stakeUSDT).updateRewardByHelper(msg.sender);
        uint len = stor.getUserStakeLength(msg.sender);
        for(uint i = 0; i < len; i++){
            stor.withdraw(msg.sender, 0);
        }
    }

    function getReward() public returns (uint, uint) {
        uint eth_amt = IStake(stakeETH).getRewardByHelper(msg.sender);
        uint usdt_amt = IStake(stakeUSDT).getRewardByHelper(msg.sender);
        return (eth_amt, usdt_amt);
    }

    function withdrawForeignTokens(address token, address to, uint256 amount) onlyOwner public returns (bool) {
        return IERC20(token).transfer(to, amount);
    }
}