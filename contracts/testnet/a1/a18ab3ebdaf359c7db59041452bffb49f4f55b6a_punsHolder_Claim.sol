/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract punsHolder_Claim is Ownable {

    bool public IsCanClaim = true;
  
    address public puns = 0xcd13e425870B3beb4fb2B19C6dee42F5D07B5f7C;
  

    uint256 public SingleZKUserDropAmount = 10_875 * 1_000_000_000_000_000_000;
    uint256 public MaxZKUserDropAmount = 250_000 * 1_000_000_000_000_000_000;

    uint256 public ZkCumSalePrice = 0.0006 ether;
    uint256 public freeAmount = 1;
    mapping(address => uint256) public usermint;

    constructor() {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function claimZkCum(uint256 _quantity) external payable callerIsUser {
        require(IsCanClaim, "Not in the claim stage.");
        require(MaxZKUserDropAmount > 0, "The total share for airdrop  has been received.");
        require(_quantity <= 100, "Invalid quantity");
        uint256 _remainFreeQuantity = 0;
        if (freeAmount > usermint[msg.sender]) {
            _remainFreeQuantity = freeAmount - usermint[msg.sender];
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * ZkCumSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        usermint[msg.sender] += _quantity;
        IERC20(puns).transfer(msg.sender, _quantity * SingleZKUserDropAmount);
        MaxZKUserDropAmount -= _quantity * SingleZKUserDropAmount;
    }
  

    function setFreeAmount(uint256 _freeAmount) external onlyOwner {
        freeAmount = _freeAmount;
    }

    function seIsCanClaim(bool _IsCanClaim) external onlyOwner {
        IsCanClaim = _IsCanClaim;
    }

   
    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}