// https://solidity-by-example.org/hashing/
pragma solidity ^0.8.0;

contract Keccak {
    function getEncodeWithUint(uint256 a, uint256 b)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(a, b);
    }

    function getEncodeWithString(string memory a, string memory b)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(a, b);
    }

    function getEncodePackedWithUint(uint256 a, uint256 b)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(a, b);
    }

    function getEncodePackedWithString(string memory a, string memory b)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(a, b);
    }
}