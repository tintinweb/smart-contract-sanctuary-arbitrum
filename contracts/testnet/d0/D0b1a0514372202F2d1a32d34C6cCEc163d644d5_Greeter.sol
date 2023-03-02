/**
 *Submitted for verification at Arbiscan on 2023-02-27
*/

// File: contracts/Greeter.sol



pragma solidity >=0.8.13;

contract Greeter {
    /* Main function */

    uint8 number;

    address ArbSys = 0x0000000000000000000000000000000000000064;

    function changeNumber(uint8 n) public {
        number = n;
    }

    function getNumber() public view returns (uint8) {
        return number;
    }

    function changeCalldata(bytes4 selector, uint8 n) public pure returns (bytes memory){
       return abi.encodeWithSelector(selector, n);
    }

    function getSelector(string calldata _func) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func)));
    }

    function callL2ToL1MessagePasser(address portal, address to, uint256 gasFee, bytes calldata calld) public returns (bool){
        (bool success, bytes memory data) = portal.call(abi.encodeWithSignature(
            "initiateWithdrawal(address, uint256, bytes)", 
            to, gasFee, calld));
        return success;
    }

    function callSendTxToL1(address destination, bytes calldata calld) public returns (bool) {
        (bool success, bytes memory data) = 
                ArbSys.call{gas: 100000}(abi.encodeWithSignature(
                    "sendTxToL1(address,bytes)",
                    destination, 
                    calld));

        return success;
    }
}