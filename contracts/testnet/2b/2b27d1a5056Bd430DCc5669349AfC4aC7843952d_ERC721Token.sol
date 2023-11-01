/**
 *Submitted for verification at Arbiscan.io on 2023-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ERC721Token {
    address public owner;
    IERC20 public erc20Token;
    uint256 public tokenPrice;

    mapping(uint256 => address) public tokenOwners;
    uint256 public tokenCount;

    event TokenMinted(address indexed owner, uint256 tokenId);
    event TokenPriceChanged(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _erc20TokenAddress, uint256 _initialTokenPrice) {
        owner = msg.sender;
        erc20Token = IERC20(_erc20TokenAddress);
        tokenPrice = _initialTokenPrice;
    }

    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
        emit TokenPriceChanged(_newPrice);
    }

    function mint() external {
        require(erc20Token.balanceOf(msg.sender) >= tokenPrice, "Insufficient ERC20 balance");

        // Transfer ERC20 tokens from buyer to contract
        require(erc20Token.transferFrom(msg.sender, address(this), tokenPrice), "ERC20 transfer failed");

        // Mint new ERC721 token to the buyer
        uint256 tokenId = tokenCount;
        tokenOwners[tokenId] = msg.sender;
        tokenCount++;

        emit TokenMinted(msg.sender, tokenId);
    }
}