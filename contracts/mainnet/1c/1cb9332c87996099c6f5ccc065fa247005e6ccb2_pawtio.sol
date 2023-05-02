// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC20.sol";

contract pawtio is Context, ERC20 {

	constructor(uint256 _supply) ERC20("LAUNCH_SOON_PAWT.IO", "LAUNCH_SOON_PAWT.IO") {
		_mint(msg.sender, _supply);
	}

	function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}