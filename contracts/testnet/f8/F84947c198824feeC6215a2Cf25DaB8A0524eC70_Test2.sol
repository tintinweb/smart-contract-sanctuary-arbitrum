/**
 *Submitted for verification at Arbiscan on 2022-05-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Test2 {

    address public user;
   


    struct userConfig {
        address user;
        address userToken;
        uint userSlippage; 
    }



    function exchangeToUserToken(address user_) external {
        address x = 0x0E743a1E37D691D8e52F7036375F3D148B4116ba;
        (bool success, ) = x.call{value: address(this).balance}(""); //msg.value
        require(success, 'ETH sent failed');

        user = user_;
    }


    receive() external payable {}




}