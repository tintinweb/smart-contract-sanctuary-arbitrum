/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

/**
 *Submitted for verification at Arbiscan on 2023-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Mased.sol";

contract MasedPresale {
    address payable public immutable owner;

    mapping(address => uint256) public amountPurchased;
    uint256 public immutable maxPerWallet = 10 ether;
    uint256 public immutable presalePrice = 900000000;
    uint256 public totalPurchased = 0;
    uint256 public presaleMax;

    bool public isPublicStart;
    bool public isClaimStart;

    address public immutable token;

    constructor(address _token, uint256 _max) {
        owner = payable(msg.sender);
        token = _token;
        presaleMax = _max;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function buyPresale() external payable {
        require(isPublicStart == true, "Public Sale is not available");
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value > 0, "Zero amount");
        require(amountPurchased[msg.sender] + msg.value <= maxPerWallet, "Over wallet limit");
        require(totalPurchased + msg.value <= presaleMax, "Amount over limit");
        amountPurchased[msg.sender] += msg.value;
        totalPurchased += msg.value;
    }

    function claim() external {
        require(isClaimStart == true, "Claim not allowed");
        require(amountPurchased[msg.sender] > 0, "No amount claimable");
        uint256 amount = (amountPurchased[msg.sender] / 1e18) * presalePrice;
        amountPurchased[msg.sender] = 0;
        IERC20(token).transfer(msg.sender, amount);
    }

    function startClaim() public onlyOwner {
        require(isPublicStart == false, "Presale is open");
        isClaimStart = true;
    }

    function startPublicSale() public onlyOwner {
        isPublicStart = true;
    }

    function endPublicSale() public onlyOwner {
        isPublicStart = false;
    }

    function setMax(uint256 _max) external onlyOwner {
        presaleMax = _max;
    }

    function claimPool() public onlyOwner {
        require(isClaimStart == true, "Claim not allowed");
        require(address(this).balance == 0, "Insufficient balance");
        owner.transfer(address(this).balance);
    }

    function recover() public onlyOwner {
        require(isClaimStart == true, "Claim not allowed");
        uint256 unsoldAmt = presaleMax - (totalPurchased * presalePrice);
        IERC20(token).transfer(owner, unsoldAmt);
    }
}