// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract AiPepe is ERC20, Ownable {
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    address public uniswapPair;

    constructor() ERC20("AiPepe", "AIPEPE") {
        _mint(owner(), 10000000000 * 10 ** decimals());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != owner() && to == uniswapPair && amount > maxSellAmount) {
            revert("Exceeds maximum sell amount");
        }
        if (to != owner() && from == uniswapPair && amount > maxBuyAmount) {
            revert("Exceeds maximum buy amount");
        }
    }

    function setUniswapPair(address _uniswapPair) external onlyOwner {
        uniswapPair = _uniswapPair;
    }

    function setConfig(
        uint256 _maxBuyAmount,
        uint256 _maxSellAmount
    ) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        maxSellAmount = _maxSellAmount;
    }
}