// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import 'lib/v3-core/contracts/libraries/FullMath.sol';
import 'lib/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "lib/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";
import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "./libraries/DataType.sol";
import "./libraries/VaultLib.sol";
import "./libraries/AssetGroupLib.sol";
import "./libraries/PositionCalculator.sol";
import "./libraries/Perp.sol";
import "./libraries/ScaledAsset.sol";
import "./libraries/SwapLib.sol";
import "./libraries/InterestRateModel.sol";
import "./libraries/logic/ApplyInterestLogic.sol";
import "./libraries/logic/LiquidationLogic.sol";
import "./libraries/logic/ReaderLogic.sol";
import "./libraries/logic/SettleUserFeeLogic.sol";
import "./libraries/logic/SupplyLogic.sol";
import "./libraries/logic/TradeLogic.sol";
import "./libraries/logic/UpdateMarginLogic.sol";
import "./interfaces/IStrategyVault.sol";

/**
 * Error Codes
 * C0: invalid asset group id
 * C1: margin must be greater than 0
 * C2: vault must be safe
 * C3: token0 or token1 must be registered stable token
 * C4: asset group id must be greater than 1
 * C5: invalid vault creation
 */
contract Controller is Initializable, IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using AssetGroupLib for AssetGroupLib.AssetGroup;
    using ScaledAsset for ScaledAsset.TokenStatus;

    mapping(uint256 => DataType.AssetStatus) public assets;

    mapping(uint256 => AssetGroupLib.AssetGroup) public assetGroups;

    mapping(uint256 => DataType.Vault) private vaults;

    mapping(address => uint256) public mainVaults;

    uint256 assetGroupsCount;

    uint256 assetsCount;

    uint256 public vaultCount;

    address public operator;

    mapping(address => bool) public allowedUniswapPools;

    event OperatorUpdated(address operator);
    event PairAdded(uint256 assetGroupId, uint256 tokenId, address _uniswapPool);
    event AssetGroupAdded(uint256 assetGroupId, uint256 stableTokenId);
    event VaultCreated(uint256 vaultId, address owner, uint256 assetGroupId, bool isMainVault);
    event ProtocolRevenueWithdrawn(uint256 withdrawnProtocolFee);

    modifier onlyOperator() {
        require(operator == msg.sender, "P3");
        _;
    }

    constructor() {
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(allowedUniswapPools[msg.sender]);
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(msg.sender);
        if (amount0 > 0) {
            TransferHelper.safeTransfer(uniswapPool.token0(), msg.sender, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(uniswapPool.token1(), msg.sender, amount1);
        }
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        require(allowedUniswapPools[msg.sender]);
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(msg.sender);
        if (amount0Delta > 0) {
            TransferHelper.safeTransfer(uniswapPool.token0(), msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            TransferHelper.safeTransfer(uniswapPool.token1(), msg.sender, uint256(amount1Delta));
        }
    }

    function initialize() public initializer {
        assetGroupsCount = 1;
        assetsCount = 1;
        vaultCount = 1;

        operator = msg.sender;
    }

    /**
     * @notice Sets new operator
     * @dev Only operator can call this function.
     * @param _newOperator The address of new operator
     */
    function setOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0));
        operator = _newOperator;

        emit OperatorUpdated(_newOperator);
    }

    /**
     * @notice Withdraws accumulated protocol revenue.
     * @dev Only operator can call this function.
     * @param _amount amount of stable token to withdraw
     */
    function withdrawProtocolRevenue(uint256 _tokenId, uint256 _amount) external onlyOperator {
        require(_amount > 0 && assets[_tokenId].accumulatedProtocolRevenue >= _amount, "C8");

        assets[_tokenId].accumulatedProtocolRevenue -= _amount;

        if (_amount > 0) {
            TransferHelper.safeTransfer(assets[_tokenId].token, msg.sender, _amount);
        }

        emit ProtocolRevenueWithdrawn(_amount);
    }

    /**
     * @notice add asset group
     */
    function addAssetGroup(
        address _stableTokenAddress,
        InterestRateModel.IRMParams memory _irmParams,
        DataType.AddAssetParams[] memory _addAssetParams
    ) external onlyOperator returns (uint256 assetGroupId, uint256 stableTokenId, uint256[] memory tokenIds) {
        assetGroupId = assetGroupsCount++;

        // add stable token
        stableTokenId = _addPair(
            _stableTokenAddress,
            false,
            address(0),
            DataType.AssetRiskParams(0, 0, 0),
            _irmParams,
            InterestRateModel.IRMParams(0, 0, 0, 0)
        );

        assetGroups[assetGroupId].setStableTokenId(stableTokenId);

        tokenIds = new uint256[](_addAssetParams.length);

        for (uint256 i; i < _addAssetParams.length; i++) {
            tokenIds[i] = addPair(assetGroupId, _addAssetParams[i]);
        }

        emit AssetGroupAdded(assetGroupId, stableTokenId);
    }

    function updateAssetParams(uint256 _tokenId, int24 _rangeSize, int24 _rebalanceThreshold) external onlyOperator {
        assets[_tokenId].riskParams.rangeSize = _rangeSize;
        assets[_tokenId].riskParams.rebalanceThreshold = _rebalanceThreshold;
    }

    function supplyToken(uint256 _vaultId, DataType.AssetParams memory _assetParams, uint256 _amount)
        external
        returns (uint256 vaultId)
    {
        applyInterest(vaults[_vaultId], _assetParams);

        vaultId = createVaultIfNeeded(_vaultId, _assetParams.assetGroupId, msg.sender, true);

        SupplyLogic.supply(assetGroups, assets, vaults[vaultId], _assetParams, _amount);
    }

    function withdrawToken(uint256 _vaultId, DataType.AssetParams memory _assetParams, uint256 _amount)
        external
        returns (uint256 finalWithdrawalAmount)
    {
        applyInterest(vaults[_vaultId]);

        finalWithdrawalAmount = SupplyLogic.withdraw(assetGroups, assets, vaults[_vaultId], _assetParams, _amount);
    }

    function updateMargin(uint256 _vaultId, uint256 _allowListId, int256 _marginAmount)
        external
        returns (uint256 vaultId)
    {
        vaultId = createVaultIfNeeded(_vaultId, _allowListId, msg.sender, true);

        DataType.Vault storage vault = vaults[vaultId];

        UpdateMarginLogic.updateMargin(assetGroups, assets, vault, _allowListId, _marginAmount);
    }

    function openIsolatedVault(
        uint256 _vaultId,
        uint256 _depositAmount,
        DataType.AssetParams memory _assetParams,
        TradeLogic.TradeParams memory _tradeParams
    ) external returns (uint256 isolatedVaultId, DataType.TradeResult memory tradeResult) {
        DataType.Vault storage vault = vaults[_vaultId];

        applyInterest(vault, _assetParams);
        settleUserFee(vault);

        require(vault.owner == msg.sender, "OWNER");

        isolatedVaultId = createVaultIfNeeded(0, _assetParams.assetGroupId, msg.sender, false);

        tradeResult = TradeLogic.openIsolatedVault(
            assetGroups, assets, vault, vaults[isolatedVaultId], _depositAmount, _assetParams, _tradeParams
        );
    }

    function closeIsolatedVault(
        uint256 _vaultId,
        uint256 _isolatedVaultId,
        DataType.AssetParams memory _assetParams,
        TradeLogic.CloseParams memory _closeParams
    ) external returns (DataType.TradeResult memory) {
        applyInterest(vaults[_isolatedVaultId], _assetParams);
        settleUserFee(vaults[_isolatedVaultId]);

        return TradeLogic.closeIsolatedVault(
            assetGroups, assets, vaults[_vaultId], vaults[_isolatedVaultId], _assetParams, _closeParams
        );
    }

    function tradePerp(
        uint256 _vaultId,
        DataType.AssetParams memory _assetParams,
        TradeLogic.TradeParams memory _tradeParams
    ) external returns (DataType.TradeResult memory) {
        applyInterest(vaults[_vaultId], _assetParams);

        DataType.UserStatus storage perpUserStatus = VaultLib.getUserStatus(assetGroups, vaults[_vaultId], _assetParams);

        return TradeLogic.execTrade(
            assets,
            vaults[_vaultId],
            assets[_assetParams.tokenId],
            assets[assetGroups[_assetParams.assetGroupId].stableTokenId],
            perpUserStatus,
            _tradeParams
        );
    }

    function liquidationCall(uint256 _vaultId, uint256 _closeRatio) external {
        applyInterest(vaults[_vaultId]);

        uint256 stableTokenId = assetGroups[vaults[_vaultId].assetGroupId].stableTokenId;

        uint256 penaltyAmount =
            LiquidationLogic.execLiquidationCall(assets, vaults[_vaultId], assets[stableTokenId], _closeRatio);

        if (penaltyAmount > 0) {
            TransferHelper.safeTransfer(assets[stableTokenId].token, msg.sender, penaltyAmount);
        }
    }

    // private functions

    /**
     * @notice add token pair
     */
    function addPair(uint256 _assetGroupId, DataType.AddAssetParams memory _addAssetParam)
        internal
        returns (uint256 tokenId)
    {
        require(_assetGroupId > 0, "C0");

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(_addAssetParam.uniswapPool);

        AssetGroupLib.AssetGroup storage assetGroup = assetGroups[_assetGroupId];
        address stableTokenAddress = assets[assetGroup.stableTokenId].token;

        require(uniswapPool.token0() == stableTokenAddress || uniswapPool.token1() == stableTokenAddress, "C3");

        bool isMarginZero = uniswapPool.token0() == stableTokenAddress;

        tokenId = _addPair(
            isMarginZero ? uniswapPool.token1() : uniswapPool.token0(),
            isMarginZero,
            _addAssetParam.uniswapPool,
            _addAssetParam.assetRiskParams,
            _addAssetParam.irmParams,
            _addAssetParam.premiumParams
        );

        assetGroup.appendTokenId(tokenId);

        emit PairAdded(_assetGroupId, tokenId, _addAssetParam.uniswapPool);
    }

    function _addPair(
        address _tokenAddress,
        bool _isMarginZero,
        address _uniswapPool,
        DataType.AssetRiskParams memory _assetRiskParams,
        InterestRateModel.IRMParams memory _irmParams,
        InterestRateModel.IRMParams memory _premiumParams
    ) internal returns (uint256 tokenId) {
        tokenId = assetsCount++;

        assets[tokenId] = DataType.AssetStatus(
            tokenId,
            _tokenAddress,
            _uniswapPool,
            _assetRiskParams,
            ScaledAsset.createTokenStatus(),
            Perp.createAssetStatus(_uniswapPool, -Constants.RANGE_SIZE, Constants.RANGE_SIZE),
            _isMarginZero,
            _irmParams,
            _premiumParams,
            block.timestamp,
            0
        );

        if (_uniswapPool != address(0)) {
            allowedUniswapPools[_uniswapPool] = true;
        }
    }

    function applyInterest(DataType.Vault memory _vault, DataType.AssetParams memory _assetParams) internal {
        validateAssetParams(_assetParams);

        uint256 stableTokenId = assetGroups[_assetParams.assetGroupId].stableTokenId;

        ApplyInterestLogic.applyInterestForToken(assets, _assetParams.tokenId, stableTokenId);
        ApplyInterestLogic.applyInterestForVault(assetGroups, assets, _vault);
    }

    function applyInterest(DataType.Vault memory _vault) internal {
        ApplyInterestLogic.applyInterestForVault(assetGroups, assets, _vault);
    }

    function settleUserFee(DataType.Vault storage _vault) internal returns (int256[] memory latestFees) {
        return SettleUserFeeLogic.settleUserFee(assetGroups, assets, _vault);
    }

    function createVaultIfNeeded(uint256 _vaultId, uint256 _allowListId, address _caller, bool _isMainVault)
        internal
        returns (uint256 vaultId)
    {
        if (_vaultId == 0) {
            vaultId = vaultCount++;

            require(_allowListId > 0 && _caller != address(0), "C5");

            vaults[vaultId].id = vaultId;
            vaults[vaultId].owner = _caller;
            vaults[vaultId].assetGroupId = _allowListId;

            if (_isMainVault) {
                require(mainVaults[_caller] == 0);
                mainVaults[_caller] = vaultId;
            }

            emit VaultCreated(vaultId, msg.sender, _allowListId, _isMainVault);

            return vaultId;
        } else {
            return _vaultId;
        }
    }

    // Getter functions

    /**
     * Gets square root of current underlying token price by quote token.
     */
    function getSqrtPrice(uint256 _tokenId) public view returns (uint160) {
        return UniHelper.getSqrtPrice(assets[_tokenId].uniswapPool);
    }

    function getSqrtIndexPrice(uint256 _tokenId) public view returns (uint160) {
        return UniHelper.getSqrtTWAP(assets[_tokenId].uniswapPool);
    }

    function getVault(uint256 _id) external view returns (DataType.Vault memory) {
        return vaults[_id];
    }

    function getVaultStatus(uint256 _id) external returns (DataType.VaultStatusResult memory) {
        applyInterest(vaults[_id]);

        return ReaderLogic.getVaultStatus(assetGroups, assets, vaults[_id]);
    }

    function getUtilizationRatio(uint256 _tokenId) external view returns (uint256, uint256) {
        return ReaderLogic.getUtilizationRatio(assets[_tokenId]);
    }

    // getInterest

    function validateAssetParams(DataType.AssetParams memory _assetParams) internal pure {
        require(_assetParams.assetGroupId > 0, "C0");
        require(_assetParams.tokenId > 0, "C4");
    }

    function getStableToken(uint256 _assetGroupId) internal view returns (address) {
        return assets[assetGroups[_assetGroupId].stableTokenId].token;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../libraries/DataType.sol";
import "../libraries/Perp.sol";
import "../libraries/logic/TradeLogic.sol";

interface IController {
    function tradePerp(
        uint256 _vaultId,
        DataType.AssetParams memory _assetParams,
        TradeLogic.TradeParams memory _tradeParams
    ) external returns (DataType.TradeResult memory);

    function updateMargin(uint256 _vaultId, uint256 _allowListId, int256 _marginAmount)
        external
        returns (uint256 vaultId);

    function getVault(uint256 _id) external view returns (DataType.Vault memory);
    function getDelta(uint256 _tokenId, uint256 _id) external view returns (int256 _delta);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStrategyVault {
    function vaultId() external view returns (uint256);
    function deposit(uint256, address) external returns (uint256, uint256);
    function withdraw(uint256, address) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ScaledAsset.sol";
import "./DataType.sol";

library AssetGroupLib {
    struct AssetGroup {
        uint256 stableTokenId;
        uint256[] tokenIds;
    }

    function setStableTokenId(AssetGroup storage _assetGroup, uint256 _stableTokenId) internal {
        _assetGroup.stableTokenId = _stableTokenId;
        appendTokenId(_assetGroup, _stableTokenId);
    }

    function appendTokenId(AssetGroup storage _assetGroup, uint256 _tokenId) internal {
        _assetGroup.tokenIds.push(_tokenId);
    }

    function isAllow(AssetGroup memory _assetGroup, uint256 _tokenId) internal pure returns (bool) {
        for (uint256 i = 0; i < _assetGroup.tokenIds.length; i++) {
            if (_assetGroup.tokenIds[i] == _tokenId) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Constants {
    uint256 internal constant ONE = 1e18;

    // Reserve factor is 10%
    uint256 internal constant RESERVE_FACTOR = 10 * 1e16;

    // Reserve factor of LPToken is 5%
    uint256 internal constant LPT_RESERVE_FACTOR = 5 * 1e16;

    // Margin option
    int256 internal constant MIN_MARGIN_AMOUNT = 1e6;
    uint256 internal constant MARGIN_ROUNDED_DECIMALS = 1e4;

    uint256 internal constant MIN_PENALTY = 2 * 1e5;

    uint256 internal constant MIN_SQRT_PRICE = 79228162514264337593;
    uint256 internal constant MAX_SQRT_PRICE = 79228162514264337593543950336000000000;

    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    // 10%
    int24 internal constant RANGE_SIZE = 1000;
    // 5%
    int24 internal constant REBALANCE_THRESHOLD = 500;

    // 2%
    uint256 internal constant BASE_MIN_COLLATERAL_WITH_DEBT = 20000;
    // 0.00005
    uint256 internal constant MIN_COLLATERAL_WITH_DEBT_SLOPE = 50;
    // 2.5% scaled by 1e6
    uint256 internal constant BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE = 12422;
    // 0.000022
    uint256 internal constant LIQ_SLIPPAGE_SQRT_SLOPE = 22;
    // 0.001
    uint256 internal constant LIQ_SLIPPAGE_SQRT_BASE = 1000;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ScaledAsset.sol";
import "./Perp.sol";
import "./InterestRateModel.sol";

library DataType {
    struct AddAssetParams {
        address uniswapPool;
        DataType.AssetRiskParams assetRiskParams;
        InterestRateModel.IRMParams irmParams;
        InterestRateModel.IRMParams premiumParams;
    }

    struct AssetRiskParams {
        uint256 riskRatio;
        int24 rangeSize;
        int24 rebalanceThreshold;
    }

    struct AssetStatus {
        uint256 id;
        address token;
        // if it is stable then uniswapPool is address(0)
        address uniswapPool;
        AssetRiskParams riskParams;
        ScaledAsset.TokenStatus tokenStatus;
        Perp.SqrtPerpAssetStatus sqrtAssetStatus;
        bool isMarginZero;
        InterestRateModel.IRMParams irmParams;
        InterestRateModel.IRMParams premiumParams;
        uint256 lastUpdateTimestamp;
        uint256 accumulatedProtocolRevenue;
    }

    struct Vault {
        uint256 id;
        address owner;
        uint256 assetGroupId;
        int256 margin;
        UserStatus[] openPositions;
    }

    struct UserStatus {
        uint256 tokenId;
        ScaledAsset.UserStatus lending;
        Perp.UserStatus perpTrade;
    }

    struct AssetParams {
        uint256 assetGroupId;
        uint256 tokenId;
    }

    struct TradeResult {
        Perp.Payoff payoff;
        int256 fee;
        int256 withdrawnAmount;
        int256 minDeposit;
    }

    struct SubVaultStatusResult {
        uint256 tokenId;
        int256 stableAmount;
        int256 underlyingamount;
        int256 sqrtAmount;
        int256 delta;
        int256 fee;
    }

    struct VaultStatusResult {
        int256 vaultValue;
        int256 available;
        int256 minDeposit;
        int256 positionValue;
        SubVaultStatusResult[] subVaults;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library InterestRateModel {
    struct IRMParams {
        uint256 baseRate;
        uint256 kinkRate;
        uint256 slope1;
        uint256 slope2;
    }

    uint256 private constant ONE = 1e18;

    function calculateInterestRate(IRMParams memory _irmParams, uint256 _utilizationRatio)
        internal
        pure
        returns (uint256)
    {
        uint256 ir = _irmParams.baseRate;

        if (_utilizationRatio <= _irmParams.kinkRate) {
            ir += (_utilizationRatio * _irmParams.slope1) / ONE;
        } else {
            ir += (_irmParams.kinkRate * _irmParams.slope1) / ONE;
            ir += (_irmParams.slope2 * (_utilizationRatio - _irmParams.kinkRate)) / ONE;
        }

        return ir;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../AssetGroupLib.sol";
import "../Perp.sol";
import "../ScaledAsset.sol";

library ApplyInterestLogic {
    using ScaledAsset for ScaledAsset.TokenStatus;

    event InterestGrowthUpdated(
        uint256 tokenId,
        uint256 assetGrowth,
        uint256 debtGrowth,
        uint256 supplyPremiumGrowth,
        uint256 borrowPremiumGrowth,
        uint256 fee0Growth,
        uint256 fee1Growth,
        uint256 accumulatedProtocolRevenue
    );

    function applyInterestForVault(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault memory _vault
    ) external {
        if (_vault.assetGroupId == 0) {
            // if vault is not initialized
            return;
        }

        uint256 stableTokenId = _assetGroups[_vault.assetGroupId].stableTokenId;

        for (uint256 i = 0; i < _vault.openPositions.length; i++) {
            applyInterestForToken(_assets, _vault.openPositions[i].tokenId, stableTokenId);
        }
    }

    function applyInterestForToken(
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        uint256 _tokenId,
        uint256 _stableTokenId
    ) public {
        DataType.AssetStatus storage assetStatus = _assets[_tokenId];

        if (_tokenId != _stableTokenId) {
            _assets[_stableTokenId].accumulatedProtocolRevenue += Perp.updateFeeAndPremiumGrowth(
                assetStatus.sqrtAssetStatus, assetStatus.premiumParams, assetStatus.isMarginZero
            );
        }

        // Gets utilization ratio
        uint256 utilizationRatio = assetStatus.tokenStatus.getUtilizationRatio();

        if (utilizationRatio == 0) {
            return;
        }

        if (block.timestamp == assetStatus.lastUpdateTimestamp) {
            return;
        }

        // Calculates interest rate
        uint256 interestRate = InterestRateModel.calculateInterestRate(assetStatus.irmParams, utilizationRatio)
            * (block.timestamp - assetStatus.lastUpdateTimestamp) / 365 days;

        // Update scaler
        assetStatus.accumulatedProtocolRevenue += assetStatus.tokenStatus.updateScaler(interestRate);

        // Update last update timestamp
        assetStatus.lastUpdateTimestamp = block.timestamp;

        emitInterestGrowthEvent(assetStatus);
    }

    function emitInterestGrowthEvent(DataType.AssetStatus memory _assetStatus) internal {
        emit InterestGrowthUpdated(
            _assetStatus.id,
            _assetStatus.tokenStatus.assetGrowth,
            _assetStatus.tokenStatus.debtGrowth,
            _assetStatus.sqrtAssetStatus.supplyPremiumGrowth,
            _assetStatus.sqrtAssetStatus.borrowPremiumGrowth,
            _assetStatus.sqrtAssetStatus.fee0Growth,
            _assetStatus.sqrtAssetStatus.fee1Growth,
            _assetStatus.accumulatedProtocolRevenue
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "../DataType.sol";
import "../Perp.sol";
import "../PositionCalculator.sol";
import "../Trade.sol";
import "../ScaledAsset.sol";

/*
 * Error Codes
 * L1: vault must be danger before liquidation
 * L2: vault must be (safe if there are positions) or (margin is negative if there are no positions) after liquidation
 * L3: too much slippage
 * L4: close ratio must be between 0 and 1e18
 */
library LiquidationLogic {
    using ScaledAsset for ScaledAsset.TokenStatus;

    event TokenSupplyLiquidated(uint256 vaultId, uint256 tokenId, uint256 finalWithdrawnAmount);
    event PositionLiquidated(
        uint256 vaultId, uint256 tokenId, int256 tradeAmount, int256 tradeSqrtAmount, Perp.Payoff payoff, int256 fee
    );
    event VaultLiquidated(uint256 vaultId, address liquidator, uint256 totalPenaltyAmount);

    function execLiquidationCall(
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.AssetStatus storage _stableAssetStatus,
        uint256 _closeRatio
    ) external returns (uint256 totalPenaltyAmount) {
        require(0 < _closeRatio && _closeRatio <= Constants.ONE, "L4");
        PositionCalculator.isDanger(_assets, _vault);

        for (uint256 i = 0; i < _vault.openPositions.length; i++) {
            DataType.UserStatus storage userStatus = _vault.openPositions[i];

            uint256 withdrawnAmount = closeSupply(_vault.id, _assets[userStatus.tokenId], userStatus, _closeRatio);

            if (userStatus.tokenId == _stableAssetStatus.id) {
                _vault.margin += int256(withdrawnAmount);

                continue;
            }

            (int256 totalPayoff, uint256 penaltyAmount) = closePerp(
                _vault.id,
                _assets[userStatus.tokenId],
                _stableAssetStatus,
                userStatus.perpTrade,
                _closeRatio,
                int256(withdrawnAmount)
            );

            _vault.margin += totalPayoff;
            totalPenaltyAmount += penaltyAmount;
        }

        (_vault.margin, totalPenaltyAmount) = subReward(_vault.margin, totalPenaltyAmount);

        PositionCalculator.isSafe(_assets, _vault);

        emit VaultLiquidated(_vault.id, msg.sender, totalPenaltyAmount);
    }

    function subReward(int256 a, uint256 b) internal pure returns (int256, uint256) {
        if (a >= int256(b)) {
            return (a - int256(b), b);
        } else if (a >= 0) {
            return (0, uint256(a));
        } else {
            return (a, 0);
        }
    }

    function closeSupply(
        uint256 _vaultId,
        DataType.AssetStatus storage _assetStatus,
        DataType.UserStatus storage _userStatus,
        uint256 _closeRatio
    ) internal returns (uint256 finalWithdrawalAmount) {
        uint256 assetValue = _assetStatus.tokenStatus.getAssetValue(_userStatus.lending);

        finalWithdrawalAmount = Trade.withdrawToken(_assetStatus, _userStatus, assetValue * _closeRatio / Constants.ONE);

        emit TokenSupplyLiquidated(_vaultId, _assetStatus.id, finalWithdrawalAmount);
    }

    function closePerp(
        uint256 _vaultId,
        DataType.AssetStatus storage _underlyingAssetStatus,
        DataType.AssetStatus storage _stableAssetStatus,
        Perp.UserStatus storage _perpUserStatus,
        uint256 _closeRatio,
        int256 _supplyAmount
    ) internal returns (int256 totalPayoff, uint256 penaltyAmount) {
        int256 tradeAmount = -_perpUserStatus.perp.amount * int256(_closeRatio) / int256(Constants.ONE);
        int256 tradeAmountSqrt = -_perpUserStatus.sqrtPerp.amount * int256(_closeRatio) / int256(Constants.ONE);

        DataType.TradeResult memory tradeResult = Trade.trade(
            _underlyingAssetStatus, _stableAssetStatus, _perpUserStatus, tradeAmount, tradeAmountSqrt, _supplyAmount
        );

        emit PositionLiquidated(
            _vaultId, _underlyingAssetStatus.id, tradeAmount, tradeAmountSqrt, tradeResult.payoff, tradeResult.fee
            );

        totalPayoff = tradeResult.fee + tradeResult.payoff.perpPayoff + tradeResult.payoff.sqrtPayoff
            + tradeResult.withdrawnAmount;

        {
            // reverts if price is out of slippage threshold
            uint256 sqrtPrice = UniHelper.getSqrtPrice(_underlyingAssetStatus.uniswapPool);
            uint256 sqrtTwap = UniHelper.getSqrtTWAP(_underlyingAssetStatus.uniswapPool);
            uint256 liquidationSlippageSqrtTolerance;

            {
                uint256 debtValue = PositionCalculator.calculateDebtValue(sqrtTwap, _perpUserStatus);
                liquidationSlippageSqrtTolerance = calculateLiquidationSlippageTolerance(debtValue);

                penaltyAmount += calculatePenaltyAmount(debtValue);
            }

            require(
                sqrtTwap * 1e6 / (1e6 + liquidationSlippageSqrtTolerance) <= sqrtPrice
                    && sqrtPrice <= sqrtTwap * (1e6 + liquidationSlippageSqrtTolerance) / 1e6,
                "L3"
            );
        }
    }

    function calculateLiquidationSlippageTolerance(uint256 _debtValue) internal pure returns (uint256) {
        uint256 liquidationSlippageSqrtTolerance = Math.max(
            Constants.LIQ_SLIPPAGE_SQRT_SLOPE * (FixedPointMathLib.sqrt(_debtValue * 1e6)) / 1e6
                + Constants.LIQ_SLIPPAGE_SQRT_BASE,
            Constants.BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE
        );

        if (liquidationSlippageSqrtTolerance > 1e6) {
            return 1e6;
        }

        return liquidationSlippageSqrtTolerance;
    }

    function calculatePenaltyAmount(uint256 _debtValue) internal pure returns (uint256) {
        // penalty amount is 0.4% of debt value
        return Math.max(
            ((_debtValue / 250) / Constants.MARGIN_ROUNDED_DECIMALS) * Constants.MARGIN_ROUNDED_DECIMALS,
            Constants.MIN_PENALTY
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../DataType.sol";
import "../Perp.sol";
import "../PositionCalculator.sol";
import "../ScaledAsset.sol";
import "./SettleUserFeeLogic.sol";

library ReaderLogic {
    using Perp for Perp.SqrtPerpAssetStatus;
    using ScaledAsset for ScaledAsset.TokenStatus;

    function getVaultStatus(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault
    ) external returns (DataType.VaultStatusResult memory) {
        int256[] memory latestFees = SettleUserFeeLogic.settleUserFee(_assetGroups, _assets, _vault);

        (int256 minDeposit, int256 vaultValue,) = PositionCalculator.calculateMinDeposit(_assets, _vault);

        DataType.SubVaultStatusResult[] memory subVaults =
            new DataType.SubVaultStatusResult[](_vault.openPositions.length);

        for (uint256 i; i < _vault.openPositions.length; i++) {
            DataType.UserStatus memory userStatus = _vault.openPositions[i];

            bool isMarginZero = _assets[userStatus.tokenId].isMarginZero;
            uint160 sqrtPrice =
                UniHelper.convertSqrtPrice(UniHelper.getSqrtTWAP(_assets[userStatus.tokenId].uniswapPool), isMarginZero);

            (int256 amount0, int256 amount1) = Perp.getAmounts(
                _assets[userStatus.tokenId].sqrtAssetStatus, userStatus.perpTrade, isMarginZero, sqrtPrice
            );

            subVaults[i].tokenId = userStatus.tokenId;
            subVaults[i].stableAmount = userStatus.perpTrade.stable.positionAmount;
            subVaults[i].underlyingamount = userStatus.perpTrade.underlying.positionAmount;
            subVaults[i].sqrtAmount = userStatus.perpTrade.sqrtPerp.amount;
            if (_assets[userStatus.tokenId].isMarginZero) {
                subVaults[i].delta = amount1;
            } else {
                subVaults[i].delta = amount0;
            }
            subVaults[i].fee = latestFees[i];
        }

        return DataType.VaultStatusResult(vaultValue, _vault.margin, vaultValue - _vault.margin, minDeposit, subVaults);
    }

    /**
     * @notice Gets utilization ratio
     */
    function getUtilizationRatio(DataType.AssetStatus memory _assetStatus) external pure returns (uint256, uint256) {
        return (_assetStatus.sqrtAssetStatus.getUtilizationRatio(), _assetStatus.tokenStatus.getUtilizationRatio());
    }

    // getInterest

    function getDelta(
        uint256 _tokenId,
        Perp.SqrtPerpAssetStatus memory _sqrtAssetStatus,
        bool _isMarginZero,
        DataType.Vault memory _vault,
        uint160 _sqrtPrice
    )
        internal
        pure
        returns (int256 _delta)
    {
        for (uint256 i; i < _vault.openPositions.length; i++) {
            if (_tokenId != _vault.openPositions[i].tokenId) {
                continue;
            }

            (int256 amount0, int256 amount1) = Perp.getAmounts(
                _sqrtAssetStatus, _vault.openPositions[i].perpTrade, _isMarginZero, _sqrtPrice
            );

            if (_isMarginZero) {
                _delta += amount1;
            } else {
                _delta += amount0;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../AssetGroupLib.sol";
import "../Trade.sol";
import "../ScaledAsset.sol";

library SettleUserFeeLogic {
    function settleUserFee(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault
    ) external returns (int256[] memory latestFees) {
        latestFees = new int256[](_vault.openPositions.length);

        for (uint256 i = 0; i < _vault.openPositions.length; i++) {
            uint256 stableTokenId = _assetGroups[_vault.assetGroupId].stableTokenId;

            if (_vault.openPositions[i].tokenId == stableTokenId) {
                continue;
            }

            int256 fee = Trade.settleFee(
                _assets[_vault.openPositions[i].tokenId], _assets[stableTokenId], _vault.openPositions[i].perpTrade
            );

            latestFees[i] = fee;

            _vault.margin += fee;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../AssetGroupLib.sol";
import "../DataType.sol";
import "../PositionCalculator.sol";
import "../ScaledAsset.sol";
import "../VaultLib.sol";

library SupplyLogic {
    using ScaledAsset for ScaledAsset.TokenStatus;

    event TokenSupplied(uint256 vaultId, DataType.AssetParams assetParams, uint256 suppliedAmount);
    event TokenWithdrawn(uint256 vaultId, DataType.AssetParams assetParams, uint256 finalWithdrawnAmount);

    function supply(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.AssetParams memory _assetParams,
        uint256 _amount
    ) external {
        DataType.UserStatus storage openPosition;

        openPosition = VaultLib.getUserStatus(_assetGroups, _vault, _assetParams);

        _assets[_assetParams.tokenId].tokenStatus.addAsset(openPosition.lending, _amount);

        TransferHelper.safeTransferFrom(_assets[_assetParams.tokenId].token, msg.sender, address(this), _amount);

        emit TokenSupplied(_vault.id, _assetParams, _amount);
    }

    function withdraw(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.AssetParams memory _assetParams,
        uint256 _amount
    ) external returns (uint256 finalWithdrawalAmount) {
        DataType.UserStatus storage openPosition = VaultLib.getUserStatus(_assetGroups, _vault, _assetParams);

        finalWithdrawalAmount = _assets[_assetParams.tokenId].tokenStatus.removeAsset(openPosition.lending, _amount);

        PositionCalculator.isSafe(_assets, _vault);

        TransferHelper.safeTransfer(_assets[_assetParams.tokenId].token, _vault.owner, finalWithdrawalAmount);

        emit TokenWithdrawn(_vault.id, _assetParams, finalWithdrawalAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../DataType.sol";
import "../Perp.sol";
import "../PositionCalculator.sol";
import "../Trade.sol";
import "../VaultLib.sol";

/*
 * Error Codes
 * T1: vault is not safe
 * T2: tx too old
 * T3: too much slippage
 */
library TradeLogic {
    struct TradeParams {
        int256 tradeAmount;
        int256 tradeAmountSqrt;
        uint256 lowerSqrtPrice;
        uint256 upperSqrtPrice;
        uint256 deadline;
    }

    struct CloseParams {
        uint256 lowerSqrtPrice;
        uint256 upperSqrtPrice;
        uint256 deadline;
    }

    event PositionUpdated(
        uint256 vaultId, uint256 tokenId, int256 tradeAmount, int256 tradeSqrtAmount, Perp.Payoff payoff, int256 fee
    );

    function openIsolatedVault(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.Vault storage _isolatedVault,
        uint256 _depositAmount,
        DataType.AssetParams memory _assetParams,
        TradeLogic.TradeParams memory _tradeParams
    ) external returns (DataType.TradeResult memory) {
        DataType.UserStatus storage perpUserStatus = VaultLib.getUserStatus(_assetGroups, _isolatedVault, _assetParams);

        _vault.margin -= int256(_depositAmount);
        _isolatedVault.margin += int256(_depositAmount);

        // if debt is 0 we should check margin is greater than 0 directly
        require(_vault.margin >= 0, "C1");
        PositionCalculator.isSafe(_assets, _vault);

        return execTrade(
            _assets,
            _isolatedVault,
            _assets[_assetParams.tokenId],
            _assets[_assetGroups[_assetParams.assetGroupId].stableTokenId],
            perpUserStatus,
            _tradeParams
        );
    }

    function closeIsolatedVault(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.Vault storage _isolatedVault,
        DataType.AssetParams memory _assetParams,
        TradeLogic.CloseParams memory _closeParams
    ) external returns (DataType.TradeResult memory tradeResult) {
        DataType.UserStatus storage perpUserStatus = VaultLib.getUserStatus(_assetGroups, _isolatedVault, _assetParams);

        tradeResult = closeVault(
            _assets,
            _isolatedVault,
            _assets[_assetParams.tokenId],
            _assets[_assetGroups[_assetParams.assetGroupId].stableTokenId],
            perpUserStatus,
            _closeParams
        );

        _vault.margin += _isolatedVault.margin;

        _isolatedVault.margin = 0;
    }

    function closeVault(
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.AssetStatus storage _underlyingAssetStatus,
        DataType.AssetStatus storage _stableAssetStatus,
        DataType.UserStatus storage _userStatus,
        CloseParams memory _closeParams
    ) internal returns (DataType.TradeResult memory tradeResult) {
        int256 tradeAmount = -_userStatus.perpTrade.perp.amount;
        int256 tradeAmountSqrt = -_userStatus.perpTrade.sqrtPerp.amount;

        return execTrade(
            _assets,
            _vault,
            _underlyingAssetStatus,
            _stableAssetStatus,
            _userStatus,
            TradeParams(
                tradeAmount,
                tradeAmountSqrt,
                _closeParams.lowerSqrtPrice,
                _closeParams.upperSqrtPrice,
                _closeParams.deadline
            )
        );
    }

    function execTrade(
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        DataType.AssetStatus storage _underlyingAssetStatus,
        DataType.AssetStatus storage _stableAssetStatus,
        DataType.UserStatus storage _userStatus,
        TradeParams memory _tradeParams
    ) public returns (DataType.TradeResult memory tradeResult) {
        checkDeadline(_tradeParams.deadline);

        tradeResult = Trade.trade(
            _underlyingAssetStatus,
            _stableAssetStatus,
            _userStatus.perpTrade,
            _tradeParams.tradeAmount,
            _tradeParams.tradeAmountSqrt,
            0
        );

        _vault.margin += tradeResult.fee + tradeResult.payoff.perpPayoff + tradeResult.payoff.sqrtPayoff;

        tradeResult.minDeposit = PositionCalculator.isSafe(_assets, _vault);

        checkPrice(_underlyingAssetStatus.uniswapPool, _tradeParams.lowerSqrtPrice, _tradeParams.upperSqrtPrice);

        emit PositionUpdated(
            _vault.id,
            _underlyingAssetStatus.id,
            _tradeParams.tradeAmount,
            _tradeParams.tradeAmountSqrt,
            tradeResult.payoff,
            tradeResult.fee
            );
    }

    function checkDeadline(uint256 _deadline) internal view {
        require(block.timestamp <= _deadline, "T2");
    }

    function checkPrice(address _uniswapPool, uint256 _lowerSqrtPrice, uint256 _upperSqrtPrice) internal view {
        uint256 sqrtPrice = UniHelper.getSqrtPrice(_uniswapPool);

        require(_lowerSqrtPrice <= sqrtPrice && sqrtPrice <= _upperSqrtPrice, "T3");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../AssetGroupLib.sol";
import "../DataType.sol";
import "../PositionCalculator.sol";
import "../ScaledAsset.sol";
import "../VaultLib.sol";
import "./SettleUserFeeLogic.sol";

library UpdateMarginLogic {
    using ScaledAsset for ScaledAsset.TokenStatus;

    event MarginUpdated(uint256 vaultId, int256 marginAmount);

    function updateMargin(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        DataType.Vault storage _vault,
        uint256 _assetGroupId,
        int256 _marginAmount
    ) external {
        VaultLib.checkVault(_vault, _assetGroupId, msg.sender);

        // settle user fee and balance
        SettleUserFeeLogic.settleUserFee(_assetGroups, _assets, _vault);

        _vault.margin += _marginAmount;

        // if debt is 0 we should check margin is greater than 0 directly
        require(_vault.margin >= 0, "M1");
        PositionCalculator.isSafe(_assets, _vault);

        if (_marginAmount > 0) {
            TransferHelper.safeTransferFrom(
                getStableToken(_assetGroups, _assets, _assetGroupId), msg.sender, address(this), uint256(_marginAmount)
            );
        } else if (_marginAmount < 0) {
            TransferHelper.safeTransfer(
                getStableToken(_assetGroups, _assets, _assetGroupId), _vault.owner, uint256(-_marginAmount)
            );
        }

        emit MarginUpdated(_vault.id, _marginAmount);
    }

    function getStableToken(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        mapping(uint256 => DataType.AssetStatus) storage _assets,
        uint256 _assetGroupId
    ) internal view returns (address) {
        return _assets[_assetGroups[_assetGroupId].stableTokenId].token;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v3-core/contracts/libraries/FullMath.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-core/contracts/libraries/FixedPoint96.sol";
import "lib/v3-core/contracts/libraries/UnsafeMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

library LPMath {
    function calculateAmount0ForLiquidityWithTicks(
        int24 _tickA,
        int24 _tickB,
        uint256 _liquidityAmount,
        bool _isRoundUp
    ) internal pure returns (int256) {
        return calculateAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(_tickA), TickMath.getSqrtRatioAtTick(_tickB), _liquidityAmount, _isRoundUp
        );
    }

    function calculateAmount1ForLiquidityWithTicks(
        int24 _tickA,
        int24 _tickB,
        uint256 _liquidityAmount,
        bool _isRoundUp
    ) internal pure returns (int256) {
        return calculateAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(_tickA), TickMath.getSqrtRatioAtTick(_tickB), _liquidityAmount, _isRoundUp
        );
    }

    function calculateAmount0ForLiquidity(
        uint160 _sqrtRatioA,
        uint160 _sqrtRatioB,
        uint256 _liquidityAmount,
        bool _isRoundUp
    ) internal pure returns (int256) {
        bool swaped = _sqrtRatioA > _sqrtRatioB;

        if (_sqrtRatioA > _sqrtRatioB) (_sqrtRatioA, _sqrtRatioB) = (_sqrtRatioB, _sqrtRatioA);

        int256 r;

        bool isRoundUp = swaped ? !_isRoundUp : _isRoundUp;

        if (isRoundUp) {
            uint256 r0 = UnsafeMath.divRoundingUp(
                FullMath.mulDivRoundingUp(_liquidityAmount << FixedPoint96.RESOLUTION, _sqrtRatioB, _sqrtRatioB),
                _sqrtRatioA
            );
            uint256 r1 =
                FullMath.mulDiv(_liquidityAmount << FixedPoint96.RESOLUTION, _sqrtRatioA, _sqrtRatioB) / _sqrtRatioA;

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        } else {
            uint256 r0 =
                FullMath.mulDiv(_liquidityAmount << FixedPoint96.RESOLUTION, _sqrtRatioB, _sqrtRatioB) / _sqrtRatioA;
            uint256 r1 = UnsafeMath.divRoundingUp(
                FullMath.mulDivRoundingUp(_liquidityAmount << FixedPoint96.RESOLUTION, _sqrtRatioA, _sqrtRatioB),
                _sqrtRatioA
            );

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        }

        if (swaped) {
            return -r;
        } else {
            return r;
        }
    }

    function calculateAmount1ForLiquidity(
        uint160 _sqrtRatioA,
        uint160 _sqrtRatioB,
        uint256 _liquidityAmount,
        bool _isRoundUp
    ) internal pure returns (int256) {
        bool swaped = _sqrtRatioA < _sqrtRatioB;

        if (_sqrtRatioA < _sqrtRatioB) (_sqrtRatioA, _sqrtRatioB) = (_sqrtRatioB, _sqrtRatioA);

        int256 r;

        bool isRoundUp = swaped ? !_isRoundUp : _isRoundUp;

        if (isRoundUp) {
            uint256 r0 = FullMath.mulDivRoundingUp(_liquidityAmount, _sqrtRatioA, FixedPoint96.Q96);
            uint256 r1 = FullMath.mulDiv(_liquidityAmount, _sqrtRatioB, FixedPoint96.Q96);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        } else {
            uint256 r0 = FullMath.mulDiv(_liquidityAmount, _sqrtRatioA, FixedPoint96.Q96);
            uint256 r1 = FullMath.mulDivRoundingUp(_liquidityAmount, _sqrtRatioB, FixedPoint96.Q96);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        }

        if (swaped) {
            return -r;
        } else {
            return r;
        }
    }

    /**
     * @notice Calculates L / (1.0001)^(b/2)
     */
    function calculateAmount0OffsetWithTick(int24 _upper, uint256 _liquidityAmount, bool _isRoundUp)
        internal
        pure
        returns (int256)
    {
        return
            SafeCast.toInt256(calculateAmount0Offset(TickMath.getSqrtRatioAtTick(_upper), _liquidityAmount, _isRoundUp));
    }

    /**
     * @notice Calculates L / sqrt{p_b}
     */
    function calculateAmount0Offset(uint160 _sqrtRatio, uint256 _liquidityAmount, bool _isRoundUp)
        internal
        pure
        returns (uint256)
    {
        if (_isRoundUp) {
            return FullMath.mulDivRoundingUp(_liquidityAmount, FixedPoint96.Q96, _sqrtRatio);
        } else {
            return FullMath.mulDiv(_liquidityAmount, FixedPoint96.Q96, _sqrtRatio);
        }
    }

    /**
     * @notice Calculates L * (1.0001)^(a/2)
     */
    function calculateAmount1OffsetWithTick(int24 _lower, uint256 _liquidityAmount, bool _isRoundUp)
        internal
        pure
        returns (int256)
    {
        return
            SafeCast.toInt256(calculateAmount1Offset(TickMath.getSqrtRatioAtTick(_lower), _liquidityAmount, _isRoundUp));
    }

    /**
     * @notice Calculates L * sqrt{p_a}
     */
    function calculateAmount1Offset(uint160 _sqrtRatio, uint256 _liquidityAmount, bool _isRoundUp)
        internal
        pure
        returns (uint256)
    {
        if (_isRoundUp) {
            return FullMath.mulDivRoundingUp(_liquidityAmount, _sqrtRatio, FixedPoint96.Q96);
        } else {
            return FullMath.mulDiv(_liquidityAmount, _sqrtRatio, FixedPoint96.Q96);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Math {
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-periphery/contracts/libraries/PositionKey.sol";
import "lib/v3-core/contracts/libraries/FixedPoint96.sol";
import {LiquidityAmounts} from "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/solmate/src/utils/SafeCastLib.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "./DataType.sol";
import "./ScaledAsset.sol";
import "./InterestRateModel.sol";
import "./Constants.sol";
import "./UniHelper.sol";
import "./math/LPMath.sol";
import "./math/Math.sol";

/*
 * Error Codes
 * P1: There is no enough SQRT liquidity.
 */
library Perp {
    using ScaledAsset for ScaledAsset.TokenStatus;
    using SafeCastLib for uint256;
    using Math for int256;

    struct PositionStatus {
        int256 amount;
        int256 entryValue;
    }

    struct SqrtPositionStatus {
        int256 amount;
        int256 entryValue;
        int256 stableRebalanceEntryValue;
        int256 underlyingRebalanceEntryValue;
        uint256 entryTradeFee0;
        uint256 entryTradeFee1;
        uint256 entryPremium;
    }

    struct UpdatePerpParams {
        int256 tradeAmount;
        int256 stableAmount;
    }

    struct UpdateSqrtPerpParams {
        int256 tradeSqrtAmount;
        int256 stableAmount;
    }

    struct Payoff {
        int256 perpEntryUpdate;
        int256 sqrtEntryUpdate;
        int256 sqrtRebalanceEntryUpdateUnderlying;
        int256 sqrtRebalanceEntryUpdateStable;
        int256 perpPayoff;
        int256 sqrtPayoff;
    }

    struct SqrtPerpAssetStatus {
        address uniswapPool;
        int24 tickLower;
        int24 tickUpper;
        uint256 totalAmount;
        uint256 borrowedAmount;
        uint256 supplyPremiumGrowth;
        uint256 borrowPremiumGrowth;
        uint256 fee0Growth;
        uint256 fee1Growth;
        uint256 lastUpdateTimestamp;
        ScaledAsset.UserStatus rebalancePositionUnderlying;
        ScaledAsset.UserStatus rebalancePositionStable;
        int256 rebalanceFeeGrowthUnderlying;
        int256 rebalanceFeeGrowthStable;
    }

    struct UserStatus {
        PositionStatus perp;
        SqrtPositionStatus sqrtPerp;
        ScaledAsset.UserStatus underlying;
        ScaledAsset.UserStatus stable;
        int24 rebalanceLastTickLower;
        int24 rebalanceLastTickUpper;
        int256 rebalanceEntryFeeUnderlying;
        int256 rebalanceEntryFeeStable;
    }

    event Rebalanced(uint256 tokenId, int24 tickLower, int24 tickUpper);

    function createAssetStatus(address uniswapPool, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (SqrtPerpAssetStatus memory)
    {
        return SqrtPerpAssetStatus(
            uniswapPool,
            tickLower,
            tickUpper,
            0,
            0,
            0,
            0,
            0,
            0,
            block.timestamp,
            ScaledAsset.createUserStatus(),
            ScaledAsset.createUserStatus(),
            0,
            0
        );
    }

    function createPerpUserStatus() internal pure returns (UserStatus memory) {
        return UserStatus(
            PositionStatus(0, 0),
            SqrtPositionStatus(0, 0, 0, 0, 0, 0, 0),
            ScaledAsset.createUserStatus(),
            ScaledAsset.createUserStatus(),
            0,
            0,
            0,
            0
        );
    }

    /**
     * @notice Updates LP position to be in range.
     * In case of in-range
     *   token0
     *     1/sqrt(x) - 1/sqrt(b1) -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(b2) - 1/sqrt(b1)
     *   token1
     *     sqrt(x) - sqrt(a1) -> sqrt(x) - sqrt(a2)
     *       sqrt(a2) - sqrt(a1)
     *
     * In case of out-of-range (tick high b1 < x)
     *   token0
     *     0 -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(b2) - 1/sqrt(x)
     *   token1
     *     sqrt(b1) - sqrt(a1) -> sqrt(x) - sqrt(a2)
     *       sqrt(b1) - sqrt(a1) - (sqrt(x) - sqrt(a2))
     *
     * In case of out-of-range (tick low x < a1)
     *   token0
     *     1/sqrt(a1) - 1/sqrt(b1) -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(a1) - 1/sqrt(b1) - (1/sqrt(x) - 1/sqrt(b2))
     *   token1
     *     0 -> sqrt(x) - sqrt(a2)
     *       sqrt(a2) - sqrt(x)
     */
    function rebalance(
        DataType.AssetStatus storage _assetStatusUnderlying,
        ScaledAsset.TokenStatus storage _assetStatusStable,
        SqrtPerpAssetStatus storage _sqrtAssetStatus
    ) internal {
        (uint160 currentSqrtPrice, int24 currentTick,,,,,) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).slot0();

        if (
            _sqrtAssetStatus.tickLower + Constants.REBALANCE_THRESHOLD < currentTick
                && currentTick < _sqrtAssetStatus.tickUpper - Constants.REBALANCE_THRESHOLD
        ) {
            return;
        }

        int24 tick;

        if (_sqrtAssetStatus.tickLower > currentTick) {
            tick = _sqrtAssetStatus.tickLower;
        }
        if (_sqrtAssetStatus.tickUpper <= currentTick) {
            tick = _sqrtAssetStatus.tickUpper;
        }

        uint128 totalLiquidityAmount = getAvailableLiquidityAmount(
            address(this), _sqrtAssetStatus.uniswapPool, _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper
        );

        if (totalLiquidityAmount == 0) {
            _sqrtAssetStatus.tickLower = (currentTick / 10) * 10 - Constants.RANGE_SIZE;
            _sqrtAssetStatus.tickUpper = (currentTick / 10) * 10 + Constants.RANGE_SIZE;
            return;
        }

        (uint256 receivedAmount0, uint256 receivedAmount1) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).burn(
            _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, totalLiquidityAmount
        );

        IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).collect(
            address(this),
            _sqrtAssetStatus.tickLower,
            _sqrtAssetStatus.tickUpper,
            receivedAmount0.safeCastTo128(),
            receivedAmount1.safeCastTo128()
        );

        // TODO: In case of out of range

        _sqrtAssetStatus.tickLower = (currentTick / 10) * 10 - Constants.RANGE_SIZE;
        _sqrtAssetStatus.tickUpper = (currentTick / 10) * 10 + Constants.RANGE_SIZE;

        (uint256 requiredAmount0, uint256 requiredAmount1) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).mint(
            address(this), _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, totalLiquidityAmount, ""
        );

        {
            // settle fee for rebalance position
            _sqrtAssetStatus.rebalanceFeeGrowthUnderlying += _assetStatusUnderlying.tokenStatus.settleUserFee(
                _sqrtAssetStatus.rebalancePositionUnderlying
            ) * 1e18 / int256(_sqrtAssetStatus.totalAmount);

            _sqrtAssetStatus.rebalanceFeeGrowthStable += _assetStatusStable.settleUserFee(
                _sqrtAssetStatus.rebalancePositionStable
            ) * 1e18 / int256(uint256(_sqrtAssetStatus.totalAmount));
        }

        updateRebalancePosition(
            _assetStatusUnderlying,
            _assetStatusStable,
            int256(receivedAmount0) - int256(requiredAmount0),
            int256(receivedAmount1) - int256(requiredAmount1)
        );

        if (tick != 0) {
            swapForOutOfRange(
                _sqrtAssetStatus.uniswapPool,
                _assetStatusUnderlying,
                _assetStatusStable,
                _sqrtAssetStatus,
                currentSqrtPrice,
                tick,
                totalLiquidityAmount
            );
        }

        emit Rebalanced(_assetStatusUnderlying.id, _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper);
    }

    /**
     * @notice Swaps additional token amounts for rebalance.
     * In case of out-of-range (tick high b1 < x)
     *   token0
     *       1/sqrt(x)　- 1/sqrt(b1)
     *   token1
     *       sqrt(x) - sqrt(b1)
     *
     * In case of out-of-range (tick low x < a1)
     *   token0
     *       1/sqrt(x) - 1/sqrt(a1)
     *   token1
     *       sqrt(x) - sqrt(a1)
     */
    function swapForOutOfRange(
        address _uniswapPool,
        DataType.AssetStatus storage _assetStatusUnderlying,
        ScaledAsset.TokenStatus storage _assetStatusStable,
        SqrtPerpAssetStatus storage _sqrtAssetStatus,
        uint160 _currentSqrtPrice,
        int24 _tick,
        uint128 _totalLiquidityAmount
    ) internal {
        uint160 tickSqrtPrice = TickMath.getSqrtRatioAtTick(_tick);

        // 1/tickSqrtPrice - 1/_currentSqrtPrice

        int256 deltaPosition0 =
            LPMath.calculateAmount0ForLiquidity(tickSqrtPrice, _currentSqrtPrice, _totalLiquidityAmount, false);

        // tickSqrtPrice - _currentSqrtPrice
        int256 deltaPosition1 =
            LPMath.calculateAmount1ForLiquidity(tickSqrtPrice, _currentSqrtPrice, _totalLiquidityAmount, false);

        (, int256 amount1) = IUniswapV3Pool(_uniswapPool).swap(
            address(this),
            deltaPosition0 > deltaPosition1,
            // + means exactIn, - means exactOut
            deltaPosition0,
            (deltaPosition0 > deltaPosition1 ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            ""
        );

        // TODO: amount1 - deltaPosition
        uint256 profit;

        if (deltaPosition0 > 0) {
            require(amount1 <= deltaPosition1, "CANTREBAL");
            profit = uint256(deltaPosition1 - amount1);
        } else {
            require(amount1 >= deltaPosition1, "CANTREBAL");
            profit = uint256(amount1 - deltaPosition1);
        }

        _sqrtAssetStatus.fee1Growth += profit * Constants.ONE / _sqrtAssetStatus.totalAmount;

        updateRebalancePosition(_assetStatusUnderlying, _assetStatusStable, -deltaPosition0, -deltaPosition1);
    }

    function getAvailableLiquidityAmount(
        address _controllerAddress,
        address _uniswapPool,
        int24 _tickLower,
        int24 _tickUpper
    ) internal view returns (uint128) {
        bytes32 positionKey = PositionKey.compute(_controllerAddress, _tickLower, _tickUpper);

        (uint128 liquidity,,,,) = IUniswapV3Pool(_uniswapPool).positions(positionKey);

        return liquidity;
    }

    function settleUserBalanceAndFee(
        DataType.AssetStatus storage _underlyingAssetStatus,
        ScaledAsset.TokenStatus storage _stableAssetStatus,
        UserStatus storage _userStatus
    ) internal returns (int256 underlyingFee, int256 stableFee) {
        (int256 underlyingInterestFee, int256 stableInterestFee) =
            settleUserFee(_underlyingAssetStatus, _stableAssetStatus, _userStatus);

        (underlyingFee, stableFee) = settleUserBalance(_underlyingAssetStatus, _stableAssetStatus, _userStatus);

        underlyingFee += underlyingInterestFee;
        stableFee += stableInterestFee;
    }

    function settleUserBalance(
        DataType.AssetStatus storage _underlyingAssetStatus,
        ScaledAsset.TokenStatus storage _stableAssetStatus,
        UserStatus storage _userStatus
    ) internal returns (int256 underlyingInterestFee, int256 stableInterestFee) {
        (int256 deltaPositionUnderlying, int256 deltaPositionStable) = updateRebalanceEntry(
            _underlyingAssetStatus.sqrtAssetStatus, _userStatus, _underlyingAssetStatus.isMarginZero
        );

        _userStatus.sqrtPerp.underlyingRebalanceEntryValue += deltaPositionUnderlying;
        _userStatus.sqrtPerp.stableRebalanceEntryValue += deltaPositionStable;

        // already settled fee

        _underlyingAssetStatus.tokenStatus.updatePosition(_userStatus.underlying, deltaPositionUnderlying);
        _stableAssetStatus.updatePosition(_userStatus.stable, deltaPositionStable);

        _underlyingAssetStatus.tokenStatus.updatePosition(
            _underlyingAssetStatus.sqrtAssetStatus.rebalancePositionUnderlying, -deltaPositionUnderlying
        );
        _stableAssetStatus.updatePosition(
            _underlyingAssetStatus.sqrtAssetStatus.rebalancePositionStable, -deltaPositionStable
        );

        (underlyingInterestFee, stableInterestFee) =
            updateRebalanceEntryFee(_underlyingAssetStatus.sqrtAssetStatus, _userStatus);
    }

    function settleUserFee(
        DataType.AssetStatus memory _underlyingAssetStatus,
        ScaledAsset.TokenStatus memory _stableAssetStatus,
        UserStatus storage _userStatus
    ) internal returns (int256 underlyingInterestFee, int256 stableInterestFee) {
        underlyingInterestFee = _underlyingAssetStatus.tokenStatus.settleUserFee(_userStatus.underlying);
        stableInterestFee = _stableAssetStatus.settleUserFee(_userStatus.stable);

        // settle premium
        int256 premium;

        if (_userStatus.sqrtPerp.amount > 0) {
            premium = mulDivToInt256(
                _underlyingAssetStatus.sqrtAssetStatus.supplyPremiumGrowth - _userStatus.sqrtPerp.entryPremium,
                _userStatus.sqrtPerp.amount
            );

            _userStatus.sqrtPerp.entryPremium = _underlyingAssetStatus.sqrtAssetStatus.supplyPremiumGrowth;
        } else if (_userStatus.sqrtPerp.amount < 0) {
            premium = mulDivToInt256(
                _underlyingAssetStatus.sqrtAssetStatus.borrowPremiumGrowth - _userStatus.sqrtPerp.entryPremium,
                _userStatus.sqrtPerp.amount
            );

            _userStatus.sqrtPerp.entryPremium = _underlyingAssetStatus.sqrtAssetStatus.borrowPremiumGrowth;
        }

        // settle trade fee
        int256 fee0;
        int256 fee1;

        if (_userStatus.sqrtPerp.amount > 0) {
            fee0 = mulDivToInt256(
                _underlyingAssetStatus.sqrtAssetStatus.fee0Growth - _userStatus.sqrtPerp.entryTradeFee0,
                _userStatus.sqrtPerp.amount
            );
            fee1 = mulDivToInt256(
                _underlyingAssetStatus.sqrtAssetStatus.fee1Growth - _userStatus.sqrtPerp.entryTradeFee1,
                _userStatus.sqrtPerp.amount
            );
        }

        _userStatus.sqrtPerp.entryTradeFee0 = _underlyingAssetStatus.sqrtAssetStatus.fee0Growth;
        _userStatus.sqrtPerp.entryTradeFee1 = _underlyingAssetStatus.sqrtAssetStatus.fee1Growth;

        if (_underlyingAssetStatus.isMarginZero) {
            stableInterestFee += fee0 + premium;
            underlyingInterestFee += fee1;
        } else {
            underlyingInterestFee += fee0;
            stableInterestFee += fee1 + premium;
        }
    }

    function updateFeeAndPremiumGrowth(
        SqrtPerpAssetStatus storage _assetStatus,
        InterestRateModel.IRMParams memory _premiumParams,
        bool _isMarginZero
    ) internal returns (uint256) {
        if (_assetStatus.lastUpdateTimestamp == block.timestamp) {
            return 0;
        }

        updateFeeGrowth(_assetStatus);

        return updatePremiumGrowth(_assetStatus, _premiumParams, _isMarginZero);
    }

    function updateFeeGrowth(SqrtPerpAssetStatus storage _assetStatus) internal {
        uint128 totalLiquidityAmount = getAvailableLiquidityAmount(
            address(this), _assetStatus.uniswapPool, _assetStatus.tickLower, _assetStatus.tickUpper
        );

        if (totalLiquidityAmount == 0) {
            return;
        }

        // collect trade fee
        IUniswapV3Pool(_assetStatus.uniswapPool).burn(_assetStatus.tickLower, _assetStatus.tickUpper, 0);

        (uint256 tradeFeeAmount0, uint256 tradeFeeAmount1) = IUniswapV3Pool(_assetStatus.uniswapPool).collect(
            address(this), _assetStatus.tickLower, _assetStatus.tickUpper, type(uint128).max, type(uint128).max
        );

        _assetStatus.fee0Growth += tradeFeeAmount0 * Constants.ONE / _assetStatus.totalAmount;
        _assetStatus.fee1Growth += tradeFeeAmount1 * Constants.ONE / _assetStatus.totalAmount;
    }

    function updatePremiumGrowth(
        SqrtPerpAssetStatus storage _assetStatus,
        InterestRateModel.IRMParams memory _premiumParams,
        bool _isMarginZero
    ) internal returns (uint256) {
        uint256 utilization = getUtilizationRatio(_assetStatus);

        if (utilization == 0) {
            return 0;
        }

        uint256 interestRate = computePremium(
            _premiumParams,
            utilization,
            UniHelper.convertSqrtPrice(UniHelper.getSqrtPrice(_assetStatus.uniswapPool), _isMarginZero)
        ) * (block.timestamp - _assetStatus.lastUpdateTimestamp) / 365 days;

        uint256 borrowPremiumGrowth;
        uint256 supplyPremiumGrowth;

        borrowPremiumGrowth = interestRate;

        uint256 protocolFeePerLiquidity = borrowPremiumGrowth * Constants.LPT_RESERVE_FACTOR / Constants.ONE;

        supplyPremiumGrowth = (borrowPremiumGrowth - protocolFeePerLiquidity) * utilization / Constants.ONE;

        _assetStatus.borrowPremiumGrowth += borrowPremiumGrowth;
        _assetStatus.supplyPremiumGrowth += supplyPremiumGrowth;

        _assetStatus.lastUpdateTimestamp = block.timestamp;

        return protocolFeePerLiquidity * _assetStatus.borrowedAmount / Constants.ONE;
    }

    function computePremium(InterestRateModel.IRMParams memory _premiumParams, uint256 _utilization, uint256 _sqrtPrice)
        internal
        pure
        returns (uint256 interestRate)
    {
        uint256 variance = InterestRateModel.calculateInterestRate(_premiumParams, _utilization);

        return (_sqrtPrice * variance) >> FixedPoint96.RESOLUTION;
    }

    /**
     * @notice Computes reuired amounts to increase or decrease sqrt positions.
     * (L/sqrt{x}, L * sqrt{x})
     */
    function computeRequiredAmounts(
        DataType.AssetStatus storage _underlyingAssetStatus,
        UserStatus storage _userStatus,
        int256 _tradeSqrtAmount
    ) internal returns (int256 requiredAmountUnderlying, int256 requiredAmountStable) {
        if (_tradeSqrtAmount == 0) {
            return (0, 0);
        }

        int256 requiredAmount0;
        int256 requiredAmount1;

        if (_tradeSqrtAmount > 0) {
            (requiredAmount0, requiredAmount1) =
                increase(_underlyingAssetStatus.sqrtAssetStatus, uint256(_tradeSqrtAmount));
        } else if (_tradeSqrtAmount < 0) {
            (requiredAmount0, requiredAmount1) =
                decrease(_underlyingAssetStatus.sqrtAssetStatus, uint256(-_tradeSqrtAmount));
        }

        if (_underlyingAssetStatus.isMarginZero) {
            requiredAmountStable = requiredAmount0;
            requiredAmountUnderlying = requiredAmount1;
        } else {
            requiredAmountStable = requiredAmount1;
            requiredAmountUnderlying = requiredAmount0;
        }

        (int256 offsetUnderlying, int256 offsetStable) = calculateSqrtPerpOffset(
            _userStatus,
            _underlyingAssetStatus.sqrtAssetStatus.tickLower,
            _underlyingAssetStatus.sqrtAssetStatus.tickUpper,
            _tradeSqrtAmount,
            _underlyingAssetStatus.isMarginZero
        );

        requiredAmountUnderlying -= offsetUnderlying;
        requiredAmountStable -= offsetStable;
    }

    function updatePosition(
        DataType.AssetStatus storage _underlyingAssetStatus,
        ScaledAsset.TokenStatus storage _stableAssetStatus,
        UserStatus storage _userStatus,
        UpdatePerpParams memory _updatePerpParams,
        UpdateSqrtPerpParams memory _updateSqrtPerpParams
    ) internal returns (Payoff memory payoff) {
        (payoff.perpEntryUpdate, payoff.perpPayoff) = calculateEntry(
            _userStatus.perp.amount,
            _userStatus.perp.entryValue,
            _updatePerpParams.tradeAmount,
            _updatePerpParams.stableAmount
        );

        (payoff.sqrtRebalanceEntryUpdateUnderlying, payoff.sqrtRebalanceEntryUpdateStable) = calculateSqrtPerpOffset(
            _userStatus,
            _underlyingAssetStatus.sqrtAssetStatus.tickLower,
            _underlyingAssetStatus.sqrtAssetStatus.tickUpper,
            _updateSqrtPerpParams.tradeSqrtAmount,
            _underlyingAssetStatus.isMarginZero
        );

        (payoff.sqrtEntryUpdate, payoff.sqrtPayoff) = calculateEntry(
            _userStatus.sqrtPerp.amount,
            _userStatus.sqrtPerp.entryValue,
            _updateSqrtPerpParams.tradeSqrtAmount,
            _updateSqrtPerpParams.stableAmount
        );

        _userStatus.perp.amount += _updatePerpParams.tradeAmount;

        // Update entry value
        _userStatus.perp.entryValue += payoff.perpEntryUpdate;
        _userStatus.sqrtPerp.entryValue += payoff.sqrtEntryUpdate;
        _userStatus.sqrtPerp.stableRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateStable;
        _userStatus.sqrtPerp.underlyingRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateUnderlying;

        // Update fee entry
        _userStatus.sqrtPerp.entryTradeFee0 = _underlyingAssetStatus.sqrtAssetStatus.fee0Growth;
        _userStatus.sqrtPerp.entryTradeFee1 = _underlyingAssetStatus.sqrtAssetStatus.fee1Growth;

        // Update sqrt position
        updateSqrtPosition(_underlyingAssetStatus.sqrtAssetStatus, _userStatus, _updateSqrtPerpParams.tradeSqrtAmount);

        _underlyingAssetStatus.tokenStatus.updatePosition(
            _userStatus.underlying, _updatePerpParams.tradeAmount + payoff.sqrtRebalanceEntryUpdateUnderlying
        );

        _stableAssetStatus.updatePosition(
            _userStatus.stable, payoff.perpEntryUpdate + payoff.sqrtEntryUpdate + payoff.sqrtRebalanceEntryUpdateStable
        );
    }

    function updateSqrtPosition(
        SqrtPerpAssetStatus storage _assetStatus,
        UserStatus storage _userStatus,
        int256 _amount
    ) internal {
        int256 openAmount;
        int256 closeAmount;

        if (_userStatus.sqrtPerp.amount * _amount >= 0) {
            openAmount = _amount;
        } else {
            if (_userStatus.sqrtPerp.amount.abs() >= _amount.abs()) {
                closeAmount = _amount;
            } else {
                openAmount = _userStatus.sqrtPerp.amount + _amount;
                closeAmount = -_userStatus.sqrtPerp.amount;
            }
        }

        if (closeAmount > 0) {
            _assetStatus.borrowedAmount -= uint256(closeAmount);
        } else if (closeAmount < 0) {
            require(getAvailableSqrtAmount(_assetStatus) >= uint256(-closeAmount), "S0");
            _assetStatus.totalAmount -= uint256(-closeAmount);
        }

        if (openAmount > 0) {
            _assetStatus.totalAmount += uint256(openAmount);

            // TODO: collect fee before update position
            _userStatus.sqrtPerp.entryPremium = _assetStatus.supplyPremiumGrowth;
        } else if (openAmount < 0) {
            require(getAvailableSqrtAmount(_assetStatus) >= uint256(-openAmount), "S0");

            _assetStatus.borrowedAmount += uint256(-openAmount);

            // TODO: pay fee before update position
            _userStatus.sqrtPerp.entryPremium = _assetStatus.borrowPremiumGrowth;
        }

        _userStatus.sqrtPerp.amount += _amount;
    }

    function getAvailableSqrtAmount(SqrtPerpAssetStatus memory _assetStatus) internal pure returns (uint256) {
        return _assetStatus.totalAmount - _assetStatus.borrowedAmount;
    }

    function getUtilizationRatio(SqrtPerpAssetStatus memory _assetStatus) internal pure returns (uint256) {
        if (_assetStatus.totalAmount == 0) {
            return 0;
        }

        uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

        if (utilization > 1e18) {
            return 1e18;
        }

        return utilization;
    }

    function updateRebalanceEntry(
        SqrtPerpAssetStatus storage _assetStatus,
        UserStatus storage _userStatus,
        bool _isMarginZero
    ) internal returns (int256 rebalancePositionUpdateUnderlying, int256 rebalancePositionUpdateStable) {
        // Rebalance position should be over repayed or deposited.
        // rebalancePositionUpdate values must be rounded down to a smaller value.

        if (_userStatus.sqrtPerp.amount == 0) {
            _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
            _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

            return (0, 0);
        }

        int256 deltaPosition0 = LPMath.calculateAmount0ForLiquidityWithTicks(
            _assetStatus.tickUpper,
            _userStatus.rebalanceLastTickUpper,
            _userStatus.sqrtPerp.amount.abs(),
            _userStatus.sqrtPerp.amount < 0
        );

        int256 deltaPosition1 = LPMath.calculateAmount1ForLiquidityWithTicks(
            _assetStatus.tickLower,
            _userStatus.rebalanceLastTickLower,
            _userStatus.sqrtPerp.amount.abs(),
            _userStatus.sqrtPerp.amount < 0
        );

        _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
        _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

        if (_userStatus.sqrtPerp.amount < 0) {
            deltaPosition0 = -deltaPosition0;
            deltaPosition1 = -deltaPosition1;
        }

        if (_isMarginZero) {
            rebalancePositionUpdateUnderlying = deltaPosition1;
            rebalancePositionUpdateStable = deltaPosition0;
        } else {
            rebalancePositionUpdateUnderlying = deltaPosition0;
            rebalancePositionUpdateStable = deltaPosition1;
        }
    }

    function updateRebalanceEntryFee(SqrtPerpAssetStatus storage _assetStatus, UserStatus storage _userStatus)
        internal
        returns (int256 rebalanceFeeUnderlying, int256 rebalanceFeeStable)
    {
        rebalanceFeeUnderlying = (_assetStatus.rebalanceFeeGrowthUnderlying - _userStatus.rebalanceEntryFeeUnderlying)
            * _userStatus.sqrtPerp.amount / int256(Constants.ONE);

        rebalanceFeeStable = (_assetStatus.rebalanceFeeGrowthStable - _userStatus.rebalanceEntryFeeStable)
            * _userStatus.sqrtPerp.amount / int256(Constants.ONE);

        _userStatus.rebalanceEntryFeeUnderlying = _assetStatus.rebalanceFeeGrowthUnderlying;
        _userStatus.rebalanceEntryFeeStable = _assetStatus.rebalanceFeeGrowthStable;
    }

    function calculateEntry(int256 _positionAmount, int256 _entryValue, int256 _tradeAmount, int256 _valueUpdate)
        internal
        pure
        returns (int256 deltaEntry, int256 payoff)
    {
        if (_tradeAmount == 0) {
            return (0, 0);
        }

        if (_positionAmount * _tradeAmount >= 0) {
            // open position
            deltaEntry = _valueUpdate;
        } else {
            if (_positionAmount.abs() >= _tradeAmount.abs()) {
                // close position

                int256 closeStableAmount = _entryValue * _tradeAmount / _positionAmount;

                deltaEntry = closeStableAmount;
                payoff = _valueUpdate - closeStableAmount;
            } else {
                // close full and open position

                int256 closeStableAmount = -_entryValue;
                int256 openStableAmount = _valueUpdate * (_positionAmount + _tradeAmount) / _tradeAmount;

                deltaEntry = closeStableAmount + openStableAmount;
                payoff = _valueUpdate - closeStableAmount - openStableAmount;
            }
        }
    }

    // private functions

    function increase(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)
        internal
        returns (int256 requiredAmount0, int256 requiredAmount1)
    {
        (uint256 amount0, uint256 amount1) = IUniswapV3Pool(_assetStatus.uniswapPool).mint(
            address(this), _assetStatus.tickLower, _assetStatus.tickUpper, _liquidityAmount.safeCastTo128(), ""
        );

        requiredAmount0 = -SafeCast.toInt256(amount0);
        requiredAmount1 = -SafeCast.toInt256(amount1);
    }

    function decrease(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)
        internal
        returns (int256 receivedAmount0, int256 receivedAmount1)
    {
        require(_assetStatus.totalAmount - _assetStatus.borrowedAmount >= _liquidityAmount, "P1");

        (uint256 amount0, uint256 amount1) = IUniswapV3Pool(_assetStatus.uniswapPool).burn(
            _assetStatus.tickLower, _assetStatus.tickUpper, _liquidityAmount.safeCastTo128()
        );

        // collect burned token amounts
        IUniswapV3Pool(_assetStatus.uniswapPool).collect(
            address(this),
            _assetStatus.tickLower,
            _assetStatus.tickUpper,
            amount0.safeCastTo128(),
            amount1.safeCastTo128()
        );

        receivedAmount0 = SafeCast.toInt256(amount0);
        receivedAmount1 = SafeCast.toInt256(amount1);
    }

    function getAmounts(
        SqrtPerpAssetStatus memory _assetStatus,
        UserStatus memory _userStatus,
        bool _isMarginZero,
        uint160 _sqrtPrice
    ) internal pure returns (int256 amount0, int256 amount1) {
        (uint256 amount0InUniswap, uint256 amount1InUniswap) = LiquidityAmounts.getAmountsForLiquidity(
            _sqrtPrice,
            TickMath.getSqrtRatioAtTick(_assetStatus.tickLower),
            TickMath.getSqrtRatioAtTick(_assetStatus.tickUpper),
            _userStatus.sqrtPerp.amount.abs().safeCastTo128()
        );

        if (_userStatus.sqrtPerp.amount > 0) {
            amount0 += int256(amount0InUniswap);
            amount1 += int256(amount1InUniswap);
        } else {
            amount0 -= int256(amount0InUniswap);
            amount1 -= int256(amount1InUniswap);
        }

        if (_isMarginZero) {
            amount0 += _userStatus.stable.positionAmount;
            amount1 += _userStatus.underlying.positionAmount;
        } else {
            amount0 += _userStatus.underlying.positionAmount;
            amount1 += _userStatus.stable.positionAmount;
        }
    }

    /**
     * @notice Calculates sqrt perp offset
     * open: (L/sqrt{b}, L * sqrt{a})
     * close: (-L * e0, -L * e1)
     */
    function calculateSqrtPerpOffset(
        UserStatus memory _userStatus,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _tradeSqrtAmount,
        bool _isMarginZero
    ) internal pure returns (int256 offsetUnderlying, int256 offsetStable) {
        int256 openAmount;
        int256 closeAmount;

        if (_userStatus.sqrtPerp.amount * _tradeSqrtAmount >= 0) {
            openAmount = _tradeSqrtAmount;
        } else {
            if (_userStatus.sqrtPerp.amount.abs() >= _tradeSqrtAmount.abs()) {
                closeAmount = _tradeSqrtAmount;
            } else {
                openAmount = _userStatus.sqrtPerp.amount + _tradeSqrtAmount;
                closeAmount = -_userStatus.sqrtPerp.amount;
            }
        }

        if (openAmount != 0) {
            // L / sqrt(b)
            offsetUnderlying = LPMath.calculateAmount0OffsetWithTick(_tickUpper, openAmount.abs(), openAmount < 0);

            // L * sqrt(a)
            offsetStable = LPMath.calculateAmount1OffsetWithTick(_tickLower, openAmount.abs(), openAmount < 0);

            if (openAmount < 0) {
                offsetUnderlying = -offsetUnderlying;
                offsetStable = -offsetStable;
            }

            if (_isMarginZero) {
                // Swap if the pool is Stable-Underlying pair
                (offsetUnderlying, offsetStable) = (offsetStable, offsetUnderlying);
            }
        }

        if (closeAmount != 0) {
            offsetStable += closeAmount * _userStatus.sqrtPerp.stableRebalanceEntryValue / _userStatus.sqrtPerp.amount;
            offsetUnderlying +=
                closeAmount * _userStatus.sqrtPerp.underlyingRebalanceEntryValue / _userStatus.sqrtPerp.amount;
        }
    }

    function updateRebalancePosition(
        DataType.AssetStatus storage _assetStatusUnderlying,
        ScaledAsset.TokenStatus storage _assetStatusStable,
        int256 _updateAmount0,
        int256 _updateAmount1
    ) internal {
        SqrtPerpAssetStatus storage sqrtAsset = _assetStatusUnderlying.sqrtAssetStatus;

        if (_assetStatusUnderlying.isMarginZero) {
            _assetStatusStable.updatePosition(sqrtAsset.rebalancePositionStable, _updateAmount0);
            _assetStatusUnderlying.tokenStatus.updatePosition(sqrtAsset.rebalancePositionUnderlying, _updateAmount1);
        } else {
            _assetStatusUnderlying.tokenStatus.updatePosition(sqrtAsset.rebalancePositionUnderlying, _updateAmount0);
            _assetStatusStable.updatePosition(sqrtAsset.rebalancePositionStable, _updateAmount1);
        }
    }

    function mulDivToInt256(uint256 x, int256 y) internal pure returns (int256) {
        return SafeCast.toInt256(x) * y / int256(Constants.ONE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "./UniHelper.sol";
import "./DataType.sol";
import "./Constants.sol";
import "./math/Math.sol";

library PositionCalculator {
    using ScaledAsset for ScaledAsset.TokenStatus;

    struct SqrtPrice {
        uint256 tokenId;
        uint256 sqrtPrice;
    }

    struct PositionParams {
        // x^0
        int256 amountStable;
        // x^0.5
        int256 amountSqrt;
        // x^1
        int256 amountUnderlying;
    }

    function isDanger(mapping(uint256 => DataType.AssetStatus) storage _assets, DataType.Vault memory _vault)
        internal
        view
    {
        (int256 minDeposit, int256 vaultValue, uint256 debtValue) = calculateMinDeposit(_assets, _vault);

        if (debtValue == 0) {
            revert("ND");
        }

        require(vaultValue < minDeposit || _vault.margin < 0, "ND");
    }

    function isSafe(mapping(uint256 => DataType.AssetStatus) storage _assets, DataType.Vault memory _vault)
        internal
        view
        returns (int256 minDeposit)
    {
        int256 vaultValue;
        uint256 debtValue;

        (minDeposit, vaultValue, debtValue) = calculateMinDeposit(_assets, _vault);

        if (debtValue == 0) {
            return 0;
        }

        require(vaultValue >= minDeposit && _vault.margin >= 0, "NS");
    }

    function calculateMinDeposit(mapping(uint256 => DataType.AssetStatus) storage _assets, DataType.Vault memory _vault)
        internal
        view
        returns (int256 minDeposit, int256 vaultValue, uint256 debtValue)
    {
        int256 minValue;

        (minValue, vaultValue, debtValue) = calculateMinValue(_assets, _vault);

        int256 minMinValue = SafeCast.toInt256(calculateRequiredCollateralWithDebt(debtValue) * debtValue / 1e6);

        minDeposit = vaultValue - minValue + minMinValue;
    }

    function calculateRequiredCollateralWithDebt(uint256 _debtValue) internal pure returns (uint256) {
        return Math.max(
            Constants.MIN_COLLATERAL_WITH_DEBT_SLOPE * FixedPointMathLib.sqrt(_debtValue * 1e6) / 1e6,
            Constants.BASE_MIN_COLLATERAL_WITH_DEBT
        );
    }

    function calculateMinValue(mapping(uint256 => DataType.AssetStatus) storage _assets, DataType.Vault memory _vault)
        internal
        view
        returns (int256 minValue, int256 vaultValue, uint256 debtValue)
    {
        for (uint256 i = 0; i < _vault.openPositions.length; i++) {
            DataType.UserStatus memory userStatus = _vault.openPositions[i];

            uint256 tokenId = userStatus.tokenId;

            if (_assets[tokenId].uniswapPool == address(0)) {
                // stable token
                minValue += int256(_assets[tokenId].tokenStatus.getAssetValue(userStatus.lending));
            } else {
                uint256 sqrtPrice = getSqrtPrice(_assets[tokenId].uniswapPool, _assets[tokenId].isMarginZero);

                PositionParams memory positionParams =
                    getPosition(userStatus, int256(_assets[tokenId].tokenStatus.getAssetValue(userStatus.lending)));

                minValue += calculateMinValue(
                    sqrtPrice,
                    getPosition(userStatus, int256(_assets[tokenId].tokenStatus.getAssetValue(userStatus.lending))),
                    _assets[tokenId].riskParams.riskRatio
                );

                vaultValue += calculateValue(sqrtPrice, positionParams);

                debtValue += calculateDebtValue(sqrtPrice, userStatus.perpTrade);
            }
        }

        minValue += int256(_vault.margin);
        vaultValue += int256(_vault.margin);
    }

    function getSqrtPrice(address _uniswapPool, bool _isMarginZero) internal view returns (uint160 sqrtPriceX96) {
        return UniHelper.convertSqrtPrice(UniHelper.getSqrtTWAP(_uniswapPool), _isMarginZero);
    }

    function getPosition(DataType.UserStatus memory _perpUserStatus, int256 _supplyUnderlyingAmount)
        internal
        pure
        returns (PositionParams memory positionParams)
    {
        return PositionParams(
            _perpUserStatus.perpTrade.stable.positionAmount,
            _perpUserStatus.perpTrade.sqrtPerp.amount,
            _perpUserStatus.perpTrade.underlying.positionAmount + _supplyUnderlyingAmount
        );
    }

    /**
     * @notice Calculates min position value in the range `p/r` to `rp`.
     * MinValue := Min(v(rp), v(p/r), v((b/a)^2))
     * where `a` is underlying asset amount, `b` is Sqrt perp amount
     * and `c` is Stable asset amount.
     * r is risk parameter.
     */
    function calculateMinValue(uint256 _sqrtPrice, PositionParams memory _positionParams, uint256 _riskRatio)
        internal
        pure
        returns (int256 minValue)
    {
        minValue = type(int256).max;

        {
            int256 v = calculateValue(_sqrtPrice * _riskRatio / 1e8, _positionParams);
            if (v < minValue) {
                minValue = v;
            }
        }

        {
            int256 v = calculateValue(_sqrtPrice * 1e8 / _riskRatio, _positionParams);
            if (v < minValue) {
                minValue = v;
            }
        }

        if (_positionParams.amountSqrt < 0 && _positionParams.amountUnderlying > 0) {
            uint256 minSqrtPrice = (uint256(-_positionParams.amountSqrt) << Constants.RESOLUTION)
                / uint256(_positionParams.amountUnderlying);

            int256 v = calculateValue(minSqrtPrice, _positionParams);

            if (v < minValue) {
                minValue = v;
            }
        }
    }

    /**
     * @notice Calculates position value.
     * PositionValue = a * x+b * sqrt(x) + c.
     * where `a` is underlying asset amount, `b` is Sqrt perp amount
     * and `c` is Stable asset amount
     */
    function calculateValue(uint256 _sqrtPrice, PositionParams memory _positionParams) internal pure returns (int256) {
        int256 price = int256(_sqrtPrice * _sqrtPrice) >> Constants.RESOLUTION;

        return ((_positionParams.amountUnderlying * price) >> Constants.RESOLUTION)
            + (2 * (_positionParams.amountSqrt * int256(_sqrtPrice)) >> Constants.RESOLUTION) + _positionParams.amountStable;
    }

    function calculateDebtValue(uint256 _sqrtPrice, Perp.UserStatus memory _perpUserStatus)
        internal
        pure
        returns (uint256)
    {
        uint256 price = (_sqrtPrice * _sqrtPrice) >> Constants.RESOLUTION;

        uint256 amountStable =
            _perpUserStatus.stable.positionAmount < 0 ? uint256(-_perpUserStatus.stable.positionAmount) : 0;
        uint256 amountUnderlying =
            _perpUserStatus.underlying.positionAmount < 0 ? uint256(-_perpUserStatus.underlying.positionAmount) : 0;
        uint256 amountSqrt = _perpUserStatus.sqrtPerp.amount < 0 ? uint256(-_perpUserStatus.sqrtPerp.amount) : 0;

        return ((amountUnderlying * price) >> Constants.RESOLUTION)
            + (2 * (amountSqrt * _sqrtPrice) >> Constants.RESOLUTION) + amountSqrt + amountStable;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "./Constants.sol";
import "./math/Math.sol";

library ScaledAsset {
    using Math for int256;

    enum InterestType {
        EMPTY,
        COMPOUND,
        NORMAL
    }

    struct TokenStatus {
        uint256 totalCompoundDeposited;
        uint256 totalCompoundBorrowed;
        uint256 totalNormalDeposited;
        uint256 totalNormalBorrowed;
        uint256 assetScaler;
        uint256 debtScaler;
        uint256 assetGrowth;
        uint256 debtGrowth;
    }

    struct UserStatus {
        InterestType interestType;
        int256 positionAmount;
        uint256 lastFeeGrowth;
    }

    uint256 constant MAX_AMOUNT = type(uint128).max;

    function createTokenStatus() internal pure returns (TokenStatus memory) {
        return TokenStatus(0, 0, 0, 0, Constants.ONE, Constants.ONE, 0, 0);
    }

    function createUserStatus() internal pure returns (UserStatus memory) {
        return UserStatus(InterestType.EMPTY, 0, 0);
    }

    function addAsset(TokenStatus storage tokenState, UserStatus storage accountState, uint256 _amount)
        internal
        returns (uint256 claimAmount)
    {
        if (_amount == 0) {
            return 0;
        }

        require(accountState.interestType != InterestType.NORMAL, "S1");
        require(accountState.positionAmount >= 0, "S3");

        claimAmount = FixedPointMathLib.mulDivDown(_amount, Constants.ONE, tokenState.assetScaler);

        accountState.positionAmount += int256(claimAmount);
        tokenState.totalCompoundDeposited += claimAmount;

        accountState.interestType = InterestType.COMPOUND;
    }

    function addDebt(TokenStatus storage tokenState, UserStatus storage accountState, uint256 _amount)
        internal
        returns (uint256 debtAmount)
    {
        if (_amount == 0) {
            return 0;
        }

        require(getAvailableCollateralValue(tokenState) >= _amount, "S0");
        require(accountState.interestType != InterestType.NORMAL, "S1");
        require(accountState.positionAmount <= 0, "S3");

        debtAmount = FixedPointMathLib.mulDivDown(_amount, Constants.ONE, tokenState.debtScaler);

        accountState.positionAmount -= int256(debtAmount);
        tokenState.totalCompoundBorrowed += debtAmount;

        accountState.interestType = InterestType.COMPOUND;
    }

    function removeAsset(TokenStatus storage tokenState, UserStatus storage accountState, uint256 _amount)
        internal
        returns (uint256 finalWithdrawAmount)
    {
        if (_amount == 0) {
            return 0;
        }

        require(accountState.positionAmount > 0, "S3");

        uint256 finalBurnAmount;

        if (accountState.interestType == InterestType.COMPOUND) {
            uint256 burnAmount = FixedPointMathLib.mulDivDown(_amount, Constants.ONE, tokenState.assetScaler);

            if (accountState.positionAmount < int256(burnAmount)) {
                finalBurnAmount = uint256(accountState.positionAmount);
                accountState.positionAmount = 0;
            } else {
                finalBurnAmount = burnAmount;
                accountState.positionAmount -= int256(burnAmount);
            }

            finalWithdrawAmount = FixedPointMathLib.mulDivDown(finalBurnAmount, tokenState.assetScaler, Constants.ONE);

            require(getAvailableCollateralValue(tokenState) >= finalWithdrawAmount, "S0");

            tokenState.totalCompoundDeposited -= finalBurnAmount;
        }
    }

    function removeDebt(TokenStatus storage tokenState, UserStatus storage accountState, uint256 _amount)
        internal
        returns (uint256 finalBurnAmount)
    {
        if (_amount == 0) {
            return 0;
        }

        require(accountState.positionAmount < 0, "S3");

        if (accountState.interestType == InterestType.COMPOUND) {
            uint256 burnAmount = FixedPointMathLib.mulDivDown(_amount, Constants.ONE, tokenState.debtScaler);

            if (-accountState.positionAmount < int256(burnAmount)) {
                finalBurnAmount = uint256(-accountState.positionAmount);
                accountState.positionAmount = 0;
            } else {
                finalBurnAmount = burnAmount;
                accountState.positionAmount += int256(burnAmount);
            }

            tokenState.totalCompoundBorrowed -= finalBurnAmount;

            finalBurnAmount = FixedPointMathLib.mulDivDown(finalBurnAmount, tokenState.debtScaler, Constants.ONE);
        }
    }

    function updatePosition(
        ScaledAsset.TokenStatus storage tokenStatus,
        ScaledAsset.UserStatus storage userStatus,
        int256 _amount
    ) internal {
        require(userStatus.interestType != ScaledAsset.InterestType.COMPOUND, "S2");

        int256 openAmount;
        int256 closeAmount;

        if (userStatus.positionAmount * _amount >= 0) {
            openAmount = _amount;
        } else {
            if (userStatus.positionAmount.abs() >= _amount.abs()) {
                closeAmount = _amount;
            } else {
                openAmount = userStatus.positionAmount + _amount;
                closeAmount = -userStatus.positionAmount;
            }
        }

        if (closeAmount > 0) {
            tokenStatus.totalNormalBorrowed -= uint256(closeAmount);
        } else if (closeAmount < 0) {
            require(getAvailableCollateralValue(tokenStatus) >= uint256(-closeAmount), "S0");
            tokenStatus.totalNormalDeposited -= uint256(-closeAmount);
        }

        if (openAmount > 0) {
            tokenStatus.totalNormalDeposited += uint256(openAmount);

            // TODO: collect fee before update position
            userStatus.lastFeeGrowth = tokenStatus.assetGrowth;
        } else if (openAmount < 0) {
            require(getAvailableCollateralValue(tokenStatus) >= uint256(-openAmount), "S0");

            tokenStatus.totalNormalBorrowed += uint256(-openAmount);

            // TODO: pay fee before update position
            userStatus.lastFeeGrowth = tokenStatus.debtGrowth;
        }

        userStatus.positionAmount += _amount;
        userStatus.interestType = ScaledAsset.InterestType.NORMAL;
    }

    function settleUserFee(ScaledAsset.TokenStatus memory _assetStatus, ScaledAsset.UserStatus storage _userStatus)
        internal
        returns (int256 interestFee)
    {
        if (_userStatus.positionAmount > 0) {
            interestFee = int256(getAssetFee(_assetStatus, _userStatus));

            _userStatus.lastFeeGrowth = _assetStatus.assetGrowth;
        } else {
            interestFee = -int256(getDebtFee(_assetStatus, _userStatus));

            _userStatus.lastFeeGrowth = _assetStatus.debtGrowth;
        }
    }

    function getAssetFee(TokenStatus memory tokenState, UserStatus memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType != InterestType.NORMAL) {
            return 0;
        }

        return FixedPointMathLib.mulDivDown(
            tokenState.assetGrowth - accountState.lastFeeGrowth,
            // TODO: overflow
            uint256(accountState.positionAmount),
            Constants.ONE
        );
    }

    function getDebtFee(TokenStatus memory tokenState, UserStatus memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType != InterestType.NORMAL) {
            return 0;
        }

        return FixedPointMathLib.mulDivDown(
            tokenState.debtGrowth - accountState.lastFeeGrowth,
            // TODO: overflow
            uint256(-accountState.positionAmount),
            Constants.ONE
        );
    }

    // get collateral value
    function getAssetValue(TokenStatus memory tokenState, UserStatus memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType == InterestType.COMPOUND) {
            return FixedPointMathLib.mulDivDown(
                uint256(accountState.positionAmount), tokenState.assetScaler, Constants.ONE
            );
        } else {
            return uint256(accountState.positionAmount);
        }
    }

    // get debt value
    function getDebtValue(TokenStatus memory tokenState, UserStatus memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType == InterestType.COMPOUND) {
            return FixedPointMathLib.mulDivDown(
                uint256(-accountState.positionAmount), tokenState.debtScaler, Constants.ONE
            );
        } else {
            return uint256(-accountState.positionAmount);
        }
    }

    // update scaler
    function updateScaler(TokenStatus storage tokenState, uint256 _interestRate) internal returns (uint256) {
        if (tokenState.totalCompoundDeposited == 0 && tokenState.totalNormalDeposited == 0) {
            return 0;
        }

        uint256 protocolFee = FixedPointMathLib.mulDivDown(
            FixedPointMathLib.mulDivDown(_interestRate, getTotalDebtValue(tokenState), Constants.ONE),
            Constants.RESERVE_FACTOR,
            Constants.ONE
        );

        // supply interest rate is InterestRate * Utilization * (1 - ReserveFactor)
        uint256 supplyInterestRate = FixedPointMathLib.mulDivDown(
            FixedPointMathLib.mulDivDown(
                _interestRate, getTotalDebtValue(tokenState), getTotalCollateralValue(tokenState)
            ),
            Constants.ONE - Constants.RESERVE_FACTOR,
            Constants.ONE
        );

        // round up
        tokenState.debtScaler =
            FixedPointMathLib.mulDivUp(tokenState.debtScaler, (Constants.ONE + _interestRate), Constants.ONE);
        tokenState.debtGrowth += _interestRate;
        tokenState.assetScaler =
            FixedPointMathLib.mulDivDown(tokenState.assetScaler, Constants.ONE + supplyInterestRate, Constants.ONE);
        tokenState.assetGrowth += supplyInterestRate;

        return protocolFee;
    }

    function getTotalCollateralValue(TokenStatus memory tokenState) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivDown(tokenState.totalCompoundDeposited, tokenState.assetScaler, Constants.ONE)
            + tokenState.totalNormalDeposited;
    }

    function getTotalDebtValue(TokenStatus memory tokenState) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivDown(tokenState.totalCompoundBorrowed, tokenState.debtScaler, Constants.ONE)
            + tokenState.totalNormalBorrowed;
    }

    function getAvailableCollateralValue(TokenStatus memory tokenState) internal pure returns (uint256) {
        return getTotalCollateralValue(tokenState) - getTotalDebtValue(tokenState);
    }

    function getUtilizationRatio(TokenStatus memory tokenState) internal pure returns (uint256) {
        if (tokenState.totalCompoundDeposited == 0 && tokenState.totalNormalDeposited == 0) {
            return 0;
        }

        uint256 utilization = FixedPointMathLib.mulDivDown(
            getTotalDebtValue(tokenState), Constants.ONE, getTotalCollateralValue(tokenState)
        );

        if (utilization > 1e18) {
            return 1e18;
        }

        return utilization;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "./Constants.sol";
import "lib/forge-std/src/console.sol";

library SwapLib {
    struct SwapUnderlyingParams {
        int256 amountPerp;
        int256 amountSqrtPerp;
        int256 fee;
        int256 lending;
    }

    struct SwapStableResult {
        int256 amountPerp;
        int256 amountSqrtPerp;
        int256 fee;
        int256 lending;
    }

    uint256 constant UNDERLYING_ONE = 1e18;

    /**
     * @notice
     * @param _swapParams Plus means In, Minus means Out
     * @return swapResult Plus means Out, Minus means In
     */
    function swap(address _uniswapPool, SwapUnderlyingParams memory _swapParams, bool _isMarginZero)
        internal
        returns (SwapStableResult memory swapResult)
    {
        int256 amountUnderlying =
            _swapParams.amountPerp + _swapParams.amountSqrtPerp + _swapParams.fee + _swapParams.lending;

        if (
            _swapParams.amountPerp == 0 && _swapParams.amountSqrtPerp == 0 && _swapParams.fee == 0
                && _swapParams.lending == 0
        ) {
            return SwapStableResult(0, 0, 0, 0);
        }

        if (amountUnderlying == 0) {
            (uint160 currentSqrtPrice,,,,,,) = IUniswapV3Pool(_uniswapPool).slot0();

            int256 amountStable = int256(calculateStableAmount(currentSqrtPrice, UNDERLYING_ONE, _isMarginZero));

            return divToStable(_swapParams, int256(UNDERLYING_ONE), amountStable, 0);
        } else {
            bool zeroForOne;

            if (amountUnderlying > 0) {
                // exactIn
                zeroForOne = !_isMarginZero;
            } else {
                zeroForOne = _isMarginZero;
            }

            (int256 amount0, int256 amount1) = IUniswapV3Pool(_uniswapPool).swap(
                address(this),
                zeroForOne,
                // + means exactIn, - means exactOut
                amountUnderlying,
                (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
                ""
            );

            int256 amountStable;
            if (_isMarginZero) {
                amountStable = -amount0;
            } else {
                amountStable = -amount1;
            }

            return divToStable(_swapParams, amountUnderlying, amountStable, amountStable);
        }
    }

    function calculateStableAmount(uint160 _currentSqrtPrice, uint256 _underlyingAmount, bool _isMarginZero)
        internal
        pure
        returns (uint256)
    {
        if (_isMarginZero) {
            uint256 price = (_currentSqrtPrice * _currentSqrtPrice) >> Constants.RESOLUTION;

            return (price * _underlyingAmount) >> Constants.RESOLUTION;
        } else {
            uint256 stableAmount = (_underlyingAmount << (2 * Constants.RESOLUTION)) / _currentSqrtPrice;

            return stableAmount / _currentSqrtPrice;
        }
    }

    function divToStable(
        SwapUnderlyingParams memory _swapParams,
        int256 _amountUnderlying,
        int256 _amountStable,
        int256 _totalAmountStable
    ) internal pure returns (SwapStableResult memory swapResult) {
        // TODO: calculate trade price
        swapResult.amountPerp = _amountStable * _swapParams.amountPerp / _amountUnderlying;
        swapResult.amountSqrtPerp = _amountStable * _swapParams.amountSqrtPerp / _amountUnderlying;
        swapResult.lending = _amountStable * _swapParams.lending / _amountUnderlying;
        swapResult.fee = _totalAmountStable - swapResult.amountPerp - swapResult.amountSqrtPerp - swapResult.lending;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "./DataType.sol";
import "./Perp.sol";
import "./SwapLib.sol";
import "./ScaledAsset.sol";

library Trade {
    using ScaledAsset for ScaledAsset.TokenStatus;

    function withdrawToken(
        DataType.AssetStatus storage _assetStatus,
        DataType.UserStatus storage _userStatus,
        uint256 _assetValue
    ) internal returns (uint256 finalWithdrawalAmount) {
        finalWithdrawalAmount = _assetStatus.tokenStatus.removeAsset(_userStatus.lending, _assetValue);

        // TODO: swap

        finalWithdrawalAmount = SafeCast.toUint256(roundAndAddProtocolFee(_assetStatus, int256(finalWithdrawalAmount)));
    }

    function settleFee(
        DataType.AssetStatus storage _underlyingAssetStatus,
        DataType.AssetStatus storage _stableAssetStatus,
        Perp.UserStatus storage _perpUserStatus
    ) internal returns (int256 fee) {
        Perp.rebalance(_underlyingAssetStatus, _stableAssetStatus.tokenStatus, _underlyingAssetStatus.sqrtAssetStatus);

        (int256 underlyingFee, int256 stableFee) =
            Perp.settleUserBalanceAndFee(_underlyingAssetStatus, _stableAssetStatus.tokenStatus, _perpUserStatus);

        // swap
        SwapLib.SwapStableResult memory swapResult = SwapLib.swap(
            _underlyingAssetStatus.uniswapPool,
            SwapLib.SwapUnderlyingParams(0, 0, underlyingFee, 0),
            _underlyingAssetStatus.isMarginZero
        );

        fee = roundAndAddProtocolFee(_stableAssetStatus, stableFee + swapResult.fee);
    }

    function trade(
        DataType.AssetStatus storage _underlyingAssetStatus,
        DataType.AssetStatus storage _stableAssetStatus,
        Perp.UserStatus storage _perpUserStatus,
        int256 _tradeAmount,
        int256 _tradeAmountSqrt,
        int256 _supplyAmount
    ) internal returns (DataType.TradeResult memory tradeResult) {
        Perp.rebalance(_underlyingAssetStatus, _stableAssetStatus.tokenStatus, _underlyingAssetStatus.sqrtAssetStatus);

        (int256 underlyingFee, int256 stableFee) =
            Perp.settleUserBalanceAndFee(_underlyingAssetStatus, _stableAssetStatus.tokenStatus, _perpUserStatus);

        (int256 underlyingAmountForSqrt, int256 stableAmountForSqrt) =
            Perp.computeRequiredAmounts(_underlyingAssetStatus, _perpUserStatus, _tradeAmountSqrt);

        // swap
        SwapLib.SwapStableResult memory swapResult = SwapLib.swap(
            _underlyingAssetStatus.uniswapPool,
            SwapLib.SwapUnderlyingParams(-_tradeAmount, underlyingAmountForSqrt, underlyingFee, _supplyAmount),
            _underlyingAssetStatus.isMarginZero
        );

        // update position
        tradeResult.payoff = Perp.updatePosition(
            _underlyingAssetStatus,
            _stableAssetStatus.tokenStatus,
            _perpUserStatus,
            Perp.UpdatePerpParams(_tradeAmount, swapResult.amountPerp),
            Perp.UpdateSqrtPerpParams(_tradeAmountSqrt, swapResult.amountSqrtPerp + stableAmountForSqrt)
        );

        tradeResult.payoff.perpPayoff = roundAndAddProtocolFee(_stableAssetStatus, tradeResult.payoff.perpPayoff);
        tradeResult.payoff.sqrtPayoff = roundAndAddProtocolFee(_stableAssetStatus, tradeResult.payoff.sqrtPayoff);

        tradeResult.fee = roundAndAddProtocolFee(_stableAssetStatus, stableFee + swapResult.fee);

        tradeResult.withdrawnAmount = swapResult.lending;
    }

    function roundAndAddProtocolFee(DataType.AssetStatus storage _stableAssetStatus, int256 _amount)
        internal
        returns (int256)
    {
        int256 rounded = roundMargin(_amount, Constants.MARGIN_ROUNDED_DECIMALS);
        if (_amount > rounded) {
            _stableAssetStatus.accumulatedProtocolRevenue += uint256(_amount - rounded);
        }
        return rounded;
    }

    function roundMargin(int256 _amount, uint256 _roundedDecimals) internal pure returns (int256) {
        if (_amount > 0) {
            return int256(FixedPointMathLib.mulDivDown(uint256(_amount), 1, _roundedDecimals) * _roundedDecimals);
        } else {
            return -int256(FixedPointMathLib.mulDivUp(uint256(-_amount), 1, _roundedDecimals) * _roundedDecimals);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "../vendors/IUniswapV3PoolOracle.sol";
import "./DataType.sol";
import "./Constants.sol";

library UniHelper {
    uint256 internal constant ORACLE_PERIOD = 30 minutes;

    function getSqrtPrice(address _uniswapPool) internal view returns (uint160 sqrtPrice) {
        (sqrtPrice,,,,,,) = IUniswapV3Pool(_uniswapPool).slot0();
    }

    /**
     * Gets square root of time weighted average price.
     */
    function getSqrtTWAP(address _uniswapPool) internal view returns (uint160 sqrtTwapX96) {
        (sqrtTwapX96,) = callUniswapObserve(IUniswapV3Pool(_uniswapPool), ORACLE_PERIOD);
    }

    /**
     * sqrt price in stable token
     */
    function convertSqrtPrice(uint160 _sqrtPriceX96, bool _isMarginZero) internal pure returns (uint160) {
        if (_isMarginZero) {
            return uint160((Constants.Q96 << Constants.RESOLUTION) / _sqrtPriceX96);
        } else {
            return _sqrtPriceX96;
        }
    }

    function callUniswapObserve(IUniswapV3Pool uniswapPool, uint256 ago) internal view returns (uint160, uint256) {
        uint32[] memory secondsAgos = new uint32[](2);

        secondsAgos[0] = uint32(ago);
        secondsAgos[1] = 0;

        (bool success, bytes memory data) =
            address(uniswapPool).staticcall(abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos));

        if (!success) {
            if (keccak256(data) != keccak256(abi.encodeWithSignature("Error(string)", "OLD"))) {
                revertBytes(data);
            }

            (,, uint16 index, uint16 cardinality,,,) = uniswapPool.slot0();

            (uint32 oldestAvailableAge,,, bool initialized) = uniswapPool.observations((index + 1) % cardinality);

            if (!initialized) {
                (oldestAvailableAge,,,) = uniswapPool.observations(0);
            }

            ago = block.timestamp - oldestAvailableAge;
            secondsAgos[0] = uint32(ago);

            (success, data) = address(uniswapPool).staticcall(
                abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos)
            );
            if (!success) {
                revertBytes(data);
            }
        }

        int56[] memory tickCumulatives = abi.decode(data, (int56[]));

        int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int256(ago)));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        return (sqrtPriceX96, ago);
    }

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("e/empty-error");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AssetGroupLib.sol";
import "./DataType.sol";
import "./ScaledAsset.sol";

library VaultLib {
    using AssetGroupLib for AssetGroupLib.AssetGroup;

    function getUserStatus(
        mapping(uint256 => AssetGroupLib.AssetGroup) storage _assetGroups,
        DataType.Vault storage _vault,
        DataType.AssetParams memory _assetParams
    ) internal returns (DataType.UserStatus storage userStatus) {
        checkVault(_vault, _assetParams.assetGroupId, msg.sender);

        require(_assetGroups[_assetParams.assetGroupId].isAllow(_assetParams.tokenId));

        userStatus = createOrGetUserStatus(_vault, _assetParams.tokenId);
    }

    function checkVault(DataType.Vault memory _vault, uint256 _allowListId, address _caller) internal pure {
        require(_vault.id > 0, "V1");
        require(_vault.owner == _caller, "V2");
        require(_vault.assetGroupId == _allowListId, "V3");
    }

    function createOrGetUserStatus(DataType.Vault storage _vault, uint256 _tokenId)
        internal
        returns (DataType.UserStatus storage)
    {
        for (uint256 i = 0; i < _vault.openPositions.length; i++) {
            if (_vault.openPositions[i].tokenId == _tokenId) {
                return _vault.openPositions[i];
            }
        }

        _vault.openPositions.push(
            DataType.UserStatus(_tokenId, ScaledAsset.createUserStatus(), Perp.createPerpUserStatus())
        );

        return _vault.openPositions[_vault.openPositions.length - 1];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./Controller.sol";
import "./libraries/DataType.sol";
import "./libraries/logic/ReaderLogic.sol";

/**
 * @title Reader contract
 * @notice Reader contract with an controller
 */
contract Reader {
    Controller public controller;

    /**
     * @notice Reader constructor
     * @param _controller controller address
     */
    constructor(Controller _controller) {
        controller = _controller;
    }

    function getDelta(uint256 _tokenId, uint256 _vaultId) external view returns (int256 _delta) {
        (uint256 tokenId, , , , , Perp.SqrtPerpAssetStatus memory sqrtAssetStatus, bool isMarginZero, , , , ) = controller.assets(_tokenId);

        return ReaderLogic.getDelta(
            tokenId,
            sqrtAssetStatus,
            isMarginZero,
            controller.getVault(_vaultId),
            controller.getSqrtPrice(_tokenId)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IController.sol";

contract BaseStrategy is ERC20 {
    event OperatorUpdated(address operator);

    IController internal controller;

    uint256 public vaultId;

    address usdc;

    uint256 assetGroupId;

    uint256 tokenId;

    address public operator;

    modifier onlyOperator() {
        require(operator == msg.sender, "BS0");
        _;
    }

    constructor(
        address _controller,
        uint256 _assetGroupId,
        uint256 _tokenId,
        address _usdc,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        controller = IController(_controller);

        assetGroupId = _assetGroupId;
        tokenId = _tokenId;
        usdc = _usdc;

        operator = msg.sender;

        ERC20(usdc).approve(address(controller), type(uint256).max);
    }

    /**
     * @notice Sets new operator
     * @dev Only operator can call this function.
     * @param _newOperator The address of new operator
     */
    function setOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0));
        operator = _newOperator;

        emit OperatorUpdated(_newOperator);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "./base/BaseStrategy.sol";
import "../libraries/Constants.sol";
import "../Reader.sol";

// TODO: trade params
contract GammaShortStrategy is BaseStrategy {
    Reader reader;

    constructor(
        address _controller,
        address _reader,
        uint256 _assetGroupId,
        uint256 _tokenId,
        address _usdc,
        string memory _name,
        string memory _symbol
    ) BaseStrategy(_controller, _assetGroupId, _tokenId, _usdc, _name, _symbol) {
        reader = Reader(_reader);
    }

    function initialize(uint256 _initialMarginAmount, int256 _initialPerpAmount, int256 _initialSqrtAmount)
        external
        onlyOperator
    {
        ERC20(usdc).transferFrom(msg.sender, address(this), _initialMarginAmount);

        vaultId = controller.updateMargin(vaultId, assetGroupId, int256(_initialMarginAmount));

        controller.tradePerp(
            vaultId,
            DataType.AssetParams(assetGroupId, tokenId),
            TradeLogic.TradeParams(_initialPerpAmount, _initialSqrtAmount, 0, type(uint160).max, block.timestamp)
        );

        _mint(msg.sender, _initialMarginAmount);
    }

    function deposit(uint256 _strategyTokenAmount, address _recepient, uint256 _maxMarginAmount)
        external
        returns (uint256 finalDepositMargin)
    {
        require(totalSupply() > 0);

        uint256 share = calMintToShare(_strategyTokenAmount, totalSupply());

        DataType.Vault memory vault = controller.getVault(vaultId);

        int256 tradePerp = calShareToMint(share, vault.openPositions[0].perpTrade.perp.amount);
        int256 tradeSqrt = calShareToMint(share, vault.openPositions[0].perpTrade.sqrtPerp.amount);

        DataType.TradeResult memory tradeResult = controller.tradePerp(
            vaultId,
            DataType.AssetParams(assetGroupId, tokenId),
            TradeLogic.TradeParams(tradePerp, tradeSqrt, 0, type(uint160).max, block.timestamp)
        );

        (int256 entryUpdate, int256 entryValue, uint256 totalMargin) = calEntryValue(tradeResult.payoff);

        finalDepositMargin = calShareToMargin(entryUpdate, entryValue, share, totalMargin);

        finalDepositMargin = roundUpMargin(finalDepositMargin, Constants.MARGIN_ROUNDED_DECIMALS);

        require(finalDepositMargin <= _maxMarginAmount, "M");

        ERC20(usdc).transferFrom(msg.sender, address(this), finalDepositMargin);

        controller.updateMargin(vaultId, assetGroupId, int256(finalDepositMargin));

        _mint(_recepient, _strategyTokenAmount);
    }

    function calEntryValue(Perp.Payoff memory payoff)
        internal
        view
        returns (int256 entryUpdate, int256 entryValue, uint256 totalMargin)
    {
        DataType.Vault memory vault = controller.getVault(vaultId);

        DataType.UserStatus memory userStatus = vault.openPositions[0];

        entryUpdate = payoff.perpEntryUpdate + payoff.sqrtEntryUpdate + payoff.sqrtRebalanceEntryUpdateStable;

        entryValue = userStatus.perpTrade.perp.entryValue + userStatus.perpTrade.sqrtPerp.entryValue
            + userStatus.perpTrade.sqrtPerp.stableRebalanceEntryValue;

        totalMargin = uint256(vault.margin);
    }

    function calMintToShare(uint256 _mint, uint256 _total) internal pure returns (uint256) {
        return _mint * 1e18 / (_total + _mint);
    }

    function calShareToMint(uint256 _share, int256 _total) internal pure returns (int256) {
        return _total * int256(_share) / int256(1e18 - _share);
    }

    function calShareToMargin(int256 _entryUpdate, int256 _entryValue, uint256 _share, uint256 _totalMarginBefore)
        internal
        pure
        returns (uint256)
    {
        uint256 t = uint256(int256(_share) * (int256(_totalMarginBefore) + _entryValue) / 1e18 - _entryUpdate);

        return t * 1e18 / (1e18 - _share);
    }

    function withdraw(uint256 _withdrawStrategyAmount, address _recepient)
        external
        returns (uint256 finalWithdrawAmount)
    {
        uint256 strategyShare = _withdrawStrategyAmount * 1e18 / totalSupply();

        DataType.Vault memory vault = controller.getVault(vaultId);

        DataType.TradeResult memory tradeResult = controller.tradePerp(
            vaultId,
            DataType.AssetParams(assetGroupId, tokenId),
            TradeLogic.TradeParams(
                -int256(strategyShare) * vault.openPositions[0].perpTrade.perp.amount / int256(1e18),
                -int256(strategyShare) * vault.openPositions[0].perpTrade.sqrtPerp.amount / int256(1e18),
                0,
                type(uint160).max,
                block.timestamp
            )
        );

        // Calculates realized and unrealized PnL.
        int256 withdrawMarginAmount = -(vault.margin + tradeResult.fee) * int256(strategyShare) / int256(1e18)
            - tradeResult.payoff.perpPayoff - tradeResult.payoff.sqrtPayoff;

        _burn(msg.sender, _withdrawStrategyAmount);

        finalWithdrawAmount = roundDownMargin(uint256(-withdrawMarginAmount), Constants.MARGIN_ROUNDED_DECIMALS);

        controller.updateMargin(vaultId, assetGroupId, -int256(finalWithdrawAmount));

        ERC20(usdc).transfer(_recepient, finalWithdrawAmount);
    }

    function execDeltaHedge() external onlyOperator {
        int256 delta = reader.getDelta(tokenId, vaultId);

        controller.tradePerp(
            vaultId,
            DataType.AssetParams(assetGroupId, tokenId),
            TradeLogic.TradeParams(-delta, 0, 0, type(uint160).max, block.timestamp)
        );
    }

    function roundUpMargin(uint256 _amount, uint256 _roundedDecimals) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivUp(_amount, 1, _roundedDecimals) * _roundedDecimals;
    }

    function roundDownMargin(uint256 _amount, uint256 _roundedDecimals) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivDown(_amount, 1, _roundedDecimals) * _roundedDecimals;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IUniswapV3PoolOracle {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function liquidity() external view returns (uint128);

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);

    function observations(uint256 index)
        external
        view
        returns (uint32 blockTimestamp, int56 tickCumulative, uint160 liquidityCumulative, bool initialized);

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}