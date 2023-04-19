/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

// SPDX-License-Identifier: MIT
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

contract Ownable is Context {
    address private _owner;
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
        emit OwnershipTransferred(_owner, address(0xdead));
        _owner = address(0xdead);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract Airdrop is Ownable {

    address public token = 0xDF6632E04DF47F17820699EC50FEaef558E65201;
    uint256 public claimBalance = 50735000000000;
    uint256 public totalClaim = 0;
    address[] public claimUserList;

    bool public isStartClaim = true;

    mapping (address => bool) public isClaim;
    address[] public userList;

    function ownerSetStartClaim(bool can) public onlyOwner {
        isStartClaim = can;
    }

    function getUsersList() public view returns(address[] memory) {
        return userList;
    }

    function ownerSetClaimBalance(uint256 balance) public onlyOwner {
        claimBalance = balance;
    }

    function claim() public {
        require(!isClaim[msg.sender], "not can claim token");
        require(isStartClaim, "not open yet");
        IERC20(token).transfer(msg.sender, claimBalance);
        isClaim[msg.sender] = true;
        totalClaim += claimBalance;
        claimUserList.push(msg.sender);
    }

    function getTotalClaimUserLength() public view returns(uint256 number) {
        number = claimUserList.length;
    }

    function ownerClaimToken(address to) public onlyOwner {
        IERC20(to).transfer(msg.sender, IERC20(to).balanceOf(address(this)));
    }

}