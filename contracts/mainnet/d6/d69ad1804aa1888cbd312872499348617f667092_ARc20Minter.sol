// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface fERC20 {
    function mint(address ref) payable external;
}

contract ARc20Minter {

    function bulkPaidMint(fERC20 token, address ref, uint256 price, uint256 count) external payable returns (bool) {
        require(msg.value == price * count, "invilid eth sent");
        for (uint256 i = 0; i < count; i ++) {
            token.mint{value: price}(ref);
        }
        return true;
    }
}