/**
 *Submitted for verification at Arbiscan on 2022-12-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract balance{

    address public wallet;

    function getWallet(address _wallet) public{
        wallet=_wallet;
    }
    function Balance() public view returns(uint){
        return wallet.balance/1000000000000000000;
    }

}