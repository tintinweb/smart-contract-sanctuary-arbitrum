// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface CourseCompletedNFT {
    function mintNft(address, bytes4) external returns (uint256);
}

contract GetCourseCompleteNFT {
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;
    address courseCompletedNFTAddress =
        0x9E9a4e58dDc9483d241AfC9a028E89BD9b9fa683;
    address immutable Owner;

    constructor() {
        Owner = msg.sender;
    }

    function doSomething() public {
        s_variable = 123;
    }

    function doSomething2() public {
        CourseCompletedNFT courseCompletedNFT = CourseCompletedNFT(
            courseCompletedNFTAddress
        );
        // courseCompletedNFT.mintNft(address(this), getSelector());
    }

    function getSelector() public pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes("doSomething()")));
    }

    function getSelector2() public pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes("doSomething2()")));
    }

    function getOwner() public view returns (address owner) {
        owner = Owner;
    }
}