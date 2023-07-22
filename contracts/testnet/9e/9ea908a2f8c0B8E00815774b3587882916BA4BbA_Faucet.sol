// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IToken {
    function mint(address _minter) external;

    function burn(address _burner, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IToken.sol";

contract Faucet {
    function mintToken(address _token) public {
        IToken token = IToken(_token);
        token.mint(msg.sender);
    }

    function burnToken(address _token, uint256 _amount) public {
        IToken token = IToken(_token);
        token.burn(msg.sender, _amount);
    }
}