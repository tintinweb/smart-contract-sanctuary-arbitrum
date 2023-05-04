// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

contract DPepe is ERC20, Ownable {

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 420000000000000000000000 * (10 ** _decimals);

    bool public noTrading;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;    

    mapping(address => bool) public blacklists;

    constructor() ERC20("DP", "DiamondPepe") {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _noTrading, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        noTrading = _noTrading;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted, sorry brah");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading hasnt started yet daddy, chill");
            return;
        }

        if (noTrading && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid, soon");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}