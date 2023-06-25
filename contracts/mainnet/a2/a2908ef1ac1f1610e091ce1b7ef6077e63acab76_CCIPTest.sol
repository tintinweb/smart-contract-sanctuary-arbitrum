// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CCIPTest {
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    string public constant URL = "https://api.yieldchain.io/ccip-test/{data}";

    function testCCIPRequest(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes memory retValue) {
        if (bytes32(response) != bytes32(0)) {
            return bytes.concat(response, extraData);
        }

        string[] memory urls = new string[](1);
        urls[0] = URL;

        revert OffchainLookup(
            address(this),
            urls,
            extraData,
            CCIPTest.testCCIPRequest.selector,
            new bytes(0)
        );
    }

    string something = "sfasfsa";

    function testGas() public returns (bool success, bytes memory res) {
        something = "dasdsadsa";
        something = "dasdsfsfadsa";
        something = "dasdsaaadsa";
        something = "dasdsahqdsa";
        something = "dasdsadasdsa";

        (success, res) = 0x000000000000000000000000000000000000006C.staticcall(
            abi.encodeWithSignature("getCurrentTxL1GasFees()")
        );
    }
}