// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";

interface ITokenStaking {
    function mintAndAllocate(uint256 index, uint256 amount, address to) external;
}

contract VesterPluginXrdo {
    ITokenStaking public xrdo;

    constructor(address _xrdo) {
        xrdo = ITokenStaking(_xrdo);
    }

    function onClaim(address from, uint256, address token, uint256 amount) external {
       IERC20(token).approve(address(xrdo), amount);
       xrdo.mintAndAllocate(0, amount, from);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}