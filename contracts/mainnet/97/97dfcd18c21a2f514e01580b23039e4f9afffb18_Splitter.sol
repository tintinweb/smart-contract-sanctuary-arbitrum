/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

//SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.8.4;
 
contract Splitter {
    address fiftyWallet;
    address quarterWallet;
    address eigthWallet1;
    address eigthWallet2;
 
    receive() external payable {
        splitUpEth();
    }
 
    constructor(
        address _fiftyWallet,
        address _quarterWallet,
        address _eigthWallet1,
        address _eigthWallet2
    ){
        fiftyWallet = payable(_fiftyWallet);
        quarterWallet = payable(_quarterWallet);
        eigthWallet1 = payable(_eigthWallet1);
        eigthWallet2 = payable(_eigthWallet2);
    }
 
 
    function splitUpEth() public payable{
        uint256 half = msg.value / 2;
        uint256 quarter = msg.value / 4;
        uint256 eigth = msg.value / 8;
 
        (bool success1,) = fiftyWallet.call{value: half}("");
        (bool success2,) = quarterWallet.call{value: quarter}("");
        (bool success3,) = eigthWallet1.call{value: eigth}("");
        (bool success4,) = eigthWallet2.call{value: eigth}("");
 
        require(success1 && success2 && success3 && success4);
    }
 
}