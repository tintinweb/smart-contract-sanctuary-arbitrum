/**
 *Submitted for verification at Arbiscan on 2022-08-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract SuicideTo {
    constructor(address payable _to) payable{
        selfdestruct(_to);
    }
}

contract CreateTwo {
    function create2(bytes32 _salt) external{
        address payable _to = payable(address(this));
        SuicideTo newContract = new SuicideTo{salt: _salt}(_to);
        bytes memory bytecode = abi.encodePacked(type(SuicideTo).creationCode, abi.encode(_to));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );
        require(address(newContract) == address(uint160(uint(hash))), "address unexpected");
    }
}