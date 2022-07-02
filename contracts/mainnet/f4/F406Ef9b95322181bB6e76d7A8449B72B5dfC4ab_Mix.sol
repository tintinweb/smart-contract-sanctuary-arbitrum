/**
 *Submitted for verification at Arbiscan on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Mix {
    mapping (address => uint256) public USSA;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { 
        revert();
    }

    function asciiToInteger(bytes32 x) public pure returns (uint256) {
        return uint256(x);
    }

    function rescure(IERC20 token, uint amount) public {
        token.transfer(owner, amount);
    }

    function alpha() public {
        USSA[msg.sender] = asciiToInteger(keccak256("alpha"));
    }

    function bravo() public {
        USSA[msg.sender] = asciiToInteger(keccak256("bravo"));
    }

    function charlie() public {
        USSA[msg.sender] = asciiToInteger(keccak256("charlie"));
    }

    function delta() public {
        USSA[msg.sender] = asciiToInteger(keccak256("delta"));
    }

    function echo() public {
        USSA[msg.sender] = asciiToInteger(keccak256("echo"));
    }

    function foxtrot() public {
        USSA[msg.sender] = asciiToInteger(keccak256("foxtrot"));
    }

    function golf() public {
        USSA[msg.sender] = asciiToInteger(keccak256("golf"));
    }

    function hotel() public {
        USSA[msg.sender] = asciiToInteger(keccak256("hotel"));
    }

    function india() public {
        USSA[msg.sender] = asciiToInteger(keccak256("india"));
    }

    function juliett() public {
        USSA[msg.sender] = asciiToInteger(keccak256("juliett"));
    }
    
}