/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface fERC20 {
    function mint(address _recipient) payable external;
}

contract GET{
    fERC20 private f ;
    address owner;

    function mint(address _recipient) payable public {
       f.mint(_recipient);
       selfdestruct(payable(owner));
    }

    function set_f(address token) public{
        owner = tx.origin;
		f = fERC20(token);
	}
}

contract fERC20Minter {
    function bulkPaidMint(address token, uint256 count) external payable{
        for (uint256 i = 0; i < count; i ++) {
            GET get = new GET();
            get.set_f(token);
            get.mint{value: msg.value/count}(msg.sender);
        }
    }
}