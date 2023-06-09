// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function mint(uint256 amount) external;
}

interface IERC721 {
    function mint() external;

    function balanceOf(address owner) external returns (uint);
}

contract Faucet {
    address public erc20;
    address public nft;

    constructor(address _erc20, address _nft) {
        erc20 = _erc20;
        nft = _nft;
    }

    function mint() public {
        if (IERC721(nft).balanceOf(msg.sender) == 0) {
            IERC721(nft).mint();
        }
        IERC20(erc20).mint(1000 ether);
    }
}