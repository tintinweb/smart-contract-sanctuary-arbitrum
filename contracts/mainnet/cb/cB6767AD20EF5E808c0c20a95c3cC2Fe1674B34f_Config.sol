/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Config {
    address public owner;

    function getConfig(bytes32 slot) public view returns (bytes32 res) {
        assembly {
            res := sload(slot)
        }
    }

    function getAddress(bytes32 slot) public view returns(address res)  {
        assembly {
            res := sload(slot)
        }
    }

    function getUint(bytes32 slot) public view returns(uint256 res) {
        assembly {
            res := sload(slot)
        }
    }

    function addConfig(bytes32 slot, bytes32 value) public {
        require (msg.sender == owner);
        require (slot != 0x0);  // Don't allow to set owner using addConfig function to avoid not intendet behaviour.
        assembly {
            sstore(slot, value)
        }
    }

    function setOwner(address _owner) public {
        require (msg.sender == owner || owner == address(0x0));
        owner = _owner;
    }
}