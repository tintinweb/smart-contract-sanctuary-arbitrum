/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

pragma solidity ^0.8.19;

// SPDX-License-Identifier: MIT
// @Author EVMlord (Follow me on Twitter: https://twitter.com/EVMlord )
// https://EVMlord.dev

contract BYTES160 {
    function stringToBytes32(string memory str)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory temp = bytes(str);
        if (temp.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(temp, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(32);
        for (i = 0; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function keccak256label(string calldata _name)
        public
        pure
        returns (bytes32)
    {
        return keccak256(bytes(_name));
    }

    function addressToUint160(address _addr) public pure returns (uint160) {
        return uint160(_addr);
    }

    function uint160ToAddress(uint160 _key) public pure returns (address) {
        return address(_key);
    }

    function bytesToAddress(bytes memory b)
        public
        pure
        returns (address payable a)
    {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) public pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    function stringToBytes(string memory abiJson)
        public
        pure
        returns (bytes memory)
    {
        bytes memory abiBytes = bytes(abiJson);
        return abiBytes;
    }

    function contractHash(address addr) public view returns (bytes32) {
        bytes32 hashX;
        assembly {
            hashX := extcodehash(addr)
        }
        return hashX;
    }

    function sameCode(address addr1, address addr2) public view returns (bool) {
        bytes32 hash1;
        bytes32 hash2;
        assembly {
            hash1 := extcodehash(addr1)
            hash2 := extcodehash(addr2)
        }
        return hash1 == hash2;
    }
}