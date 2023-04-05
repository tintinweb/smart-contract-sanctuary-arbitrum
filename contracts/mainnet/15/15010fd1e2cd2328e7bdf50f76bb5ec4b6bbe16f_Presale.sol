// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


contract Presale is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public rate;
    uint256 public hardCap;
    uint256 public weiRaised;

    
    
    mapping(address => uint256) public purchasedAmount;
    
    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor(address _token, uint256 _rate) {
        require(_token != address(0), "Invalid token address");
        require(_rate > 0, "Invalid rate");
        
        token = IERC20(_token);
        rate = _rate;
        hardCap = 20 ether;
    }

    receive() external payable {
        buyTokens(msg.value);
    }

    function buyTokens(uint256 weiAmount) public payable {
        require(weiAmount > 0, "Invalid purchase amount");
        require(weiRaised + weiAmount <= hardCap, "Hard cap exceeded");

        uint256 tokens = weiAmount * rate;
        weiRaised += weiAmount;

        purchasedAmount[msg.sender] += tokens;
        
        emit TokensPurchased(msg.sender, tokens);
    }

    function getPurchasedAmount(address buyer) public view returns (uint256) {
        return purchasedAmount[buyer];
    }

    function claimTokens () public {
        require (purchasedAmount[msg.sender] > 0, "No Tokens to withdraw" );
        uint256 tokens = purchasedAmount[msg.sender];
        token.safeTransfer(msg.sender, tokens);
    }
    

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner()).transfer(balance);
    }

    function updateRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Invalid rate");
        rate = _newRate;
    }
}