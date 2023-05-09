/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract BrcdogeAirDrop {
    address public Brcdoge_addr;
    uint256 public amount =  2100000000000000000000000000;
    address public owner; // owner address
    mapping(address => bool) public claimed; // mapping of users who have claimed

    constructor() {
        Brcdoge_addr = 0xC480fc35b441Cb6A274f0565427959E05CDe7e12;
        owner = msg.sender; // set owner address to contract deployer
    }

    // modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function claim() public {
        require(Brcdoge_addr != address(0), "TokenA address not set");
        require(!claimed[msg.sender], "You have already claimed the airdrop");
        IERC20 Brcdoge = IERC20(Brcdoge_addr);
        require(Brcdoge.transfer(msg.sender, amount), "Transfer failed");
        claimed[msg.sender] = true;
    }

    // function to change the tokenA address, restricted to the owner
    function setBrcdoge(address _Brcdoge) public onlyOwner() {
        Brcdoge_addr = _Brcdoge;
    }

    // function to change the amount value, restricted to the owner
    function setAmount(uint256 _amount) public onlyOwner() {
        amount = _amount;
    }

    function getBrcdogeBalance() public view returns (uint256) {
        IERC20 Brcdoge = IERC20(Brcdoge_addr);
        return Brcdoge.balanceOf(address(this));
    }


    // allow only the owner to transfer ownership to a new address
    function transferOwner(address newOwner) public onlyOwner() {
        require(newOwner != address(0), "New owner address cannot be zero");
        owner = newOwner;
    }

    function withdraw(uint256 _withdrawAmount) public onlyOwner() {
        IERC20 Brcdoge = IERC20(Brcdoge_addr);
        require(Brcdoge.transfer(owner, _withdrawAmount), "Transfer failed");
    }

}