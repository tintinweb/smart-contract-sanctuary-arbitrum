/**
 *Submitted for verification at Arbiscan.io on 2023-11-28
*/

pragma solidity ^0.8.0;

    contract testreadcontract123456 {

        uint256 public aNumber;

        function gimmeastring(uint256 a) public pure returns (string memory) {
            if(a == 1) {
                return "Result 3";
            } else {
                return "Result 4";
            }
        }

        function storeMeANumber(uint256 a) public {
            aNumber = a;
        }

    }