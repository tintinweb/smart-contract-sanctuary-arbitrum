/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract GreatDonate {

    address public payswallet;
    mapping (address => uint) public mapswall;
    uint256 constant WEEKS = 7 * 86400; // all future times are rounded by week
    uint256 constant MAXTIMES = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIERW = 10**18;

   

    constructor() {
        payswallet = msg.sender;
    }

    struct DiffWallet {

        uint256 di2;
        uint256 mu3;
    }

    

    function payme() public payable {
        mapswall[msg.sender] = msg.value;
    }

    function returnbalance() public {
        address payable _to = payable(payswallet);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }
}