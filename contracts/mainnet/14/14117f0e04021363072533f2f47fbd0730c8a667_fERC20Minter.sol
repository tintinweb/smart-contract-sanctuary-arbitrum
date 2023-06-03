/**
 *Submitted for verification at Arbiscan on 2023-06-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface fERC20 {
    function mint(address _to) payable external;
}

contract GET{
    fERC20 private f ;

    function mint(address _to) payable public {
       f.mint(_to);
       selfdestruct(payable(tx.origin));
    }

    function set_f(address token) public{
		f = fERC20(token);
	}
}

contract fERC20Minter {
    function bulkPaidMint(address token, uint256 price, uint256 count) external payable{
        for (uint256 i = 0; i < count; i ++) {
            GET get = new GET();
            get.set_f(token);
            get.mint{value: price}(msg.sender);
        }
    }
}