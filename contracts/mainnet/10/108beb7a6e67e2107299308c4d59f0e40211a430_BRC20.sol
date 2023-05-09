// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20.sol";

contract BRC20 is ERC20 {
    uint256 maxSupply = 10_000_000_000 * 1e18;
    uint256 public startTime = 1683637200;
    mapping (address => bool) minted;

    constructor(
    ) ERC20("BRC-20", "BRC-20") {
    }

    function mint() external returns(bool) {
        require(msg.sender == tx.origin, "This function can only be called by an externally-owned account.");
        require(!minted[msg.sender], "The address has already minted.");
        require(totalSupply() <= maxSupply - 1_000_000 * 1e18, "exceeding the maximum supply quantity.");
        require(address(msg.sender).balance > 0.0001 ether, "The address balance must be greater than 0.0001 ether.");
        _mint(msg.sender, 1_000_000 * 1e18);
        minted[msg.sender] = true;
        return true;
    }
}