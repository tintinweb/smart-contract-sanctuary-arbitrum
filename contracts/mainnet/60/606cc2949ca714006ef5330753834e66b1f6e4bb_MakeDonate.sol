/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract MakeDonate {

    address public ownPay;
    mapping (address => uint) public mapswall;

   

    constructor() {
        ownPay = msg.sender;
    }

    struct DiffWallet {

        uint256 di2;
        uint256 mu3;
    }

     struct LoWallet {
        int128 amount2;
        uint256 end2;
        uint256 end3;
        uint256 end44;
        uint256 end22;
    }

    function donatePays() public payable {
        mapswall[msg.sender] = msg.value;
    }

    function returnM() public {
        address payable _to = payable(ownPay
);
        address _contracte = address(this);
        _to.transfer(_contracte.balance);
    }
}