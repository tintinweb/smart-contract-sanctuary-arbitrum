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

    event GasFees(uint256 gasLeft, uint256 l1gasLeft);

    address ArbGasInfo = 0x000000000000000000000000000000000000006C;

    address ArbSys = 0x0000000000000000000000000000000000000064;

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

    struct GasLeft {
        uint256 local;
        uint256 l1;
    }

    event CurrentGasLeft(
        uint256 indexed vanillaGasLeft,
        uint256 indexed l1GasCost,
        uint256 indexed vanillaGasLeftAfterExec
    );

    string someShit = "fasfsafasfasf";

    function testGasThing() external {
        bool success;
        bytes memory res;

        uint256 gasLeft = gasleft() * tx.gasprice;
        uint256 l1Cost;

        (success, res) = ArbGasInfo.staticcall(
            abi.encodeWithSignature("getPricesInWei()")
        );

        require(success, "Getting ARbGasInfo prices in wei failed");

        (, uint256 perCalldataUnit, , , , ) = abi.decode(
            res,
            (uint256, uint256, uint256, uint256, uint256, uint256)
        );

        l1Cost = msg.data.length * perCalldataUnit;

        emit CurrentGasLeft(gasLeft, l1Cost, gasleft() * tx.gasprice);

        someShit = "fmiaofsafioasfmio24j0291mfsa";
        string memory poo = someShit;
        someShit = string.concat(poo, "Pooo");

        someShit = "4e412421124";
        someShit = "41afsa24";
        someShit = "412ada4";
        someShit = "41ff2fasfsaaaaaaaafsa4";
        someShit = "41dfasfasfsa4";

        gasLeft = gasleft() * tx.gasprice;

        (success, res) = ArbGasInfo.staticcall(
            abi.encodeWithSignature("getPricesInWei()")
        );

        require(success, "Getting ARbGasInfo prices in wei failed");

        (, perCalldataUnit, , , , ) = abi.decode(
            res,
            (uint256, uint256, uint256, uint256, uint256, uint256)
        );

        l1Cost = msg.data.length * perCalldataUnit;

        emit CurrentGasLeft(gasLeft, l1Cost, gasleft() * tx.gasprice);
    }
}