// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Errors {
    struct Foo {
        address sender;
        uint256 bar;
    }

    error SimpleError(string message);
    error ComplexError(Foo foo, string message, uint256 number);

    enum Enum {
        VALUE_ONE,
        VALUE_TWO,
        VALUE_THREE
    }

    uint[] public emptyArray;
    uint[] public nonEmptyArray = [1, 2, 3, 4, 5];

    mapping(address => bytes) private dataMap;

    // Read Functions

    function overflowRead() public pure returns (uint256) {
        uint256 a = 2 ** 256 - 1;
        uint256 b = 1;
        uint256 c = a + b;
        return c;
    }

    function divideByZeroRead() public pure returns (uint256) {
        uint256 a = 69;
        uint256 b = 0;
        uint256 c = a / b;
        return c;
    }

    function wrongConvertToEnumRead(uint256 value) public pure returns (Enum) {
        return Enum(value);
    }

    function tooMuchMemoryAllocatedRead(uint256 _size) public pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](_size);
        return array;
    }

    function zeroInitializedVariableRead() public pure returns (int) {
        function(int, int) internal pure returns (int) functionPointer;

        return functionPointer(0, 1);
    }

    function assertRead() public pure {
        assert(false);
    }

    function requireRead() public pure {
        require(false, "Requirement Not Met");
    }

    function revertRead() public pure {
        revert("This is a revert message");
    }

    function simpleCustomRead() public pure {
        revert SimpleError("bugger");
    }

    function complexCustomRead() public pure {
        revert ComplexError(
            Foo({ sender: 0x0000000000000000000000000000000000000000, bar: 69 }),
            "bugger",
            69
        );
    }

    function infiniteLoopRead() public pure {
        uint256 i = 0;
        while (true) {
            i++;
        }
    }

    // Write Functions

    function overflowWrite() public returns (uint256) {
        uint256 a = 2 ** 256 - 1;
        uint256 b = 1;
        uint256 c = a + b;
        return c;
    }

    function divideByZeroWrite() public returns (uint256) {
        uint256 a = 69;
        uint256 b = 0;
        uint256 c = a / b;
        return c;
    }

    function wrongConvertToEnumWrite(uint256 value) public returns (Enum) {
        return Enum(value);
    }

    function popEmptyArrayWrite() public {
        emptyArray.pop();
    }

    function outOfBoundsArrayAccessWrite() public returns (uint) {
        return nonEmptyArray[10];
    }

    function tooMuchMemoryAllocatedWrite(uint256 _size) public returns (uint256[] memory) {
        uint256[] memory array = new uint256[](_size);
        return array;
    }

    function zeroInitializedVariableWrite() public returns (int) {
        function(int, int) internal pure returns (int) functionPointer;

        return functionPointer(0, 1);
    }

    function assertWrite() public {
        assert(false);
    }

    function requireWrite() public {
        require(false);
    }

    function revertWrite() public {
        revert("This is a revert message");
    }

    function simpleCustomWrite() public {
        revert SimpleError("bugger");
    }

    function complexCustomWrite() public {
        revert ComplexError(
            Foo({ sender: 0x0000000000000000000000000000000000000000, bar: 69 }),
            "bugger",
            69
        );
    }

    function infiniteLoopWrite() public {
        uint256 i = 0;
        while (true) {
            i++;
        }
    }

    // Payable Functions

    function errorNonPayable() public pure returns (uint256) {
        return 69;
    }

    function assertPayable() public payable {
        assert(false);
    }

    function requirePayable() public payable {
        require(false);
    }

    function revertPayable() public payable {
        revert("This is a revert message");
    }

    function simpleCustomPayable() public payable {
        revert SimpleError("bugger");
    }

    function complexCustomPayable() public payable {
        revert ComplexError(
            Foo({ sender: 0x0000000000000000000000000000000000000000, bar: 69 }),
            "bugger",
            69
        );
    }

    function infiniteLoopPayable() public payable {
        uint256 i = 0;
        while (true) {
            i++;
        }
    }
}