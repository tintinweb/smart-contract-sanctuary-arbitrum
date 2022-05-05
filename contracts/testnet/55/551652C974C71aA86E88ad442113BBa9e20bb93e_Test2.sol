/**
 *Submitted for verification at Arbiscan on 2022-05-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Test2 {

    address public user;
    address public userToken;
    string public phrase; 
    uint public num; 
    uint public num2;
    uint public balance1;
    uint public balance2;

    bool flag;

    struct userConfig {
        address user;
        address userToken;
        uint userSlippage; 
    }



    function exchangeToUserToken2(userConfig memory userDetails_) external payable {
        address x = 0x0E743a1E37D691D8e52F7036375F3D148B4116ba;
        (bool success, ) = x.call{value: address(this).balance}(""); //msg.value
        require(success, 'ETH sent failed');

        user = userDetails_.user;
    } 

    function exchangeToUserToken(address user_) external {
        address x = 0x0E743a1E37D691D8e52F7036375F3D148B4116ba;
        (bool success, ) = x.call{value: address(this).balance}(""); //msg.value
        require(success, 'ETH sent failed');

        user = user_;
    }


    receive() external payable {}


    function deposit(address _user, address _userToken) external payable {
        address x = 0x0E743a1E37D691D8e52F7036375F3D148B4116ba;
        (bool success, ) = x.call{value: address(this).balance}(""); //msg.value
        require(success, 'ETH sent failed');


        user = _user;
        userToken = _userToken;
        num = msg.value; //address(this).balance
    }


}