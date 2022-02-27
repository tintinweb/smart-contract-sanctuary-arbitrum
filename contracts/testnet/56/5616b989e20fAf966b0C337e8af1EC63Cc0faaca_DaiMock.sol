// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;
import "./ERC20Permit.sol";


contract DaiMock is ERC20Permit {

    constructor() ERC20Permit("Dai Stablecoin", "DAI", 18) {  }

    function version() public pure override returns(string memory) { return "2"; }

    /// @dev Give tokens to whoever asks for them.
    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}