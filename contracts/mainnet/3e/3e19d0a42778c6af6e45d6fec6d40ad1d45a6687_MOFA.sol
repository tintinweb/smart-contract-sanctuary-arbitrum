/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

//The original Make Orwell Fiction Again design. Let us go back in time to an era when George Orwell’s iconoclastic magnum opus was still a work of fiction. In modern times, the futuristic negative utopian //society imagined in Orwell’s novel has been far surpassed. The elite’s ability to establish system-supportive doctrines, news, and information is uncanny. So is their ability to dispel wrongthink and punish the //heretics.  
//As technology evolves, freedom as we know it may continue to suffer. Let us keep the benefits of these modern technologies but always be fighting for our eternal liberty!  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MOFA {
    string public constant name = "Make Orwell Fiction Again";
    string public constant symbol = "MOFA";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000 * 10 ** decimals;
    address public constant commissionWallet = 0xF83A29c2341648513d85b3d63Da87D1324FfE4aF;
    uint256 public constant commissionRateForSell = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public allowedWallets;

    bool public ownershipRenounced;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    modifier onlyBeforeOwnershipRenounced() {
        require(!ownershipRenounced, "Ownership has already been renounced.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == address(this), "Only contract owner can perform this action.");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        allowedWallets[msg.sender] = true;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[msg.sender], "Insufficient balance.");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[_from], "Insufficient balance.");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance.");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function sell(uint256 _value) external onlyOwner returns (bool success) {
        require(_value <= balanceOf[address(this)], "Insufficient balance.");

        balanceOf[address(this)] -= _value;
        balanceOf[msg.sender] += _value;

        emit Transfer(address(this), msg.sender, _value);

        return true;
    }

    function allowWallet(address _wallet) external onlyBeforeOwnershipRenounced() {
        allowedWallets[_wallet] = true;
    }

    function disallowWallet(address _wallet) external onlyBeforeOwnershipRenounced() {
        allowedWallets[_wallet] = false;
    }

    function renounceOwnership() external onlyBeforeOwnershipRenounced() {
        ownershipRenounced = true;

        emit OwnershipRenounced(msg.sender);
    }
}