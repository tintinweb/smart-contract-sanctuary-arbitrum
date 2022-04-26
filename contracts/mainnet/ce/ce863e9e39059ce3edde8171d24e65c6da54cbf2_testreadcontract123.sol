/**
 *Submitted for verification at Arbiscan on 2022-04-26
*/

pragma solidity ^0.8.0;

    contract testreadcontract123 {

        function gimmeastring(uint256 a) public pure returns (string memory) {
            if(a == 1) {
                return "Result 1";
            } else {
                return "Result 2";
            }
        }

    }