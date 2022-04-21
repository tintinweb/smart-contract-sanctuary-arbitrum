/**
 *Submitted for verification at Arbiscan on 2022-04-21
*/

pragma solidity ^0.8.0;

contract amoguscontract {

    bool public redsus = true;
    bool public bluesus = false;

    function isbluesus(bool newinfo) external {

        bluesus = newinfo;
    }
}