// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC20.sol';
/**
 * @title ERC20Decimals
 * @dev Implementation of the ERC20Decimals. Extension of {ERC20} that adds decimals storage slot.
*/
contract XXAX is ERC20 {
    uint8 private immutable _decimals = 18;
    uint256 private _totalSupply = 200 * 10**18;

    /**
     * @dev Sets the value of the `decimals`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor() ERC20("XXAX", "XXAX") {
        _mint(_msgSender(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

}