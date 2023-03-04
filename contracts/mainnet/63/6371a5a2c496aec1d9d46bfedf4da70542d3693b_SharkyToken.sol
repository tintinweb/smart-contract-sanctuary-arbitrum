// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract SharkyToken is ERC20 {
    using SafeMath for uint256;
    uint256 public constant maxSupply = 1_000_000_000e18;

    constructor() ERC20("SharkySwap", "SHARKY") {
        _mint(msg.sender, 100_000e18);
    }

    /// @notice Creates `_amount` token to token address. Must only be called by the owner (MasterChef).
    function mint(uint256 _amount) public override onlyOwner returns (bool) {
        return mintFor(address(this), _amount);
    }

    function mintFor(
        address _address,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        _mint(_address, _amount);
        require(totalSupply() <= maxSupply, "reach max supply");
        return true;
    }

    // Safe sharky transfer function, just in case if rounding error causes pool to not have enough SHARKY.
    function safeSharkyTransfer(address _to, uint256 _amount) public onlyOwner {
        uint256 sharkBal = balanceOf(address(this));
        if (_amount > sharkBal) {
            _transfer(address(this), _to, sharkBal);
        } else {
            _transfer(address(this), _to, _amount);
        }
    }
}