/**
 *Submitted for verification at Arbiscan on 2022-06-19
*/

// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity >= 0.5;


contract tool {

    ExecuteDataContext public context;
    int public i;
    event ADD(uint256 price, uint256 bid);
    // bytes4 internal constant CALLID_DEFAULT_CONTEXT = bytes4(bytes32(type(uint256).max));
    // address internal constant ADDRESS_DEFAULT_CONTEXT = address(type(uint160).max);

    struct ExecuteDataContext {
        bytes4 callId; 
        address token;
        address to;
        address receiver; 
    }

    function set(ExecuteDataContext[] calldata arr) public payable {
        i++;
    }
    function get() pure public returns(bytes4) {
        return bytes4(keccak256("buyItem()"));
    }



    function combine1(bytes4 callId,
        address token,
        address to,
        address receiver, 
        bytes memory data) public pure returns(bytes memory) {
        return abi.encode(callId, token, to, receiver, data);
    }

    function tryD(bytes memory data) public view returns(bytes4,
        address,
        address,
        address,bytes memory) {
        bytes memory callHookdata;
        bytes4 callId; 
        address token;
        address to;
        address receiver; 
        (callId, token, to, receiver, callHookdata) = abi.decode(data, (bytes4, address, address, address, bytes));
        return (callId, token, to, receiver, callHookdata);
    }
}