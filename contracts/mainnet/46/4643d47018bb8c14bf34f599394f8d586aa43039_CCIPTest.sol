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
        uint256 vanilla;
        uint256 gasInfo;
        uint256 arbSys;
    }

    event GasesLeft(GasLeft indexed initial, GasLeft indexed end);

    string someShit = "fasfsafasfasf";

    function testGasThing()
        external
        returns (GasLeft memory initialGas, GasLeft memory endGas)
    {
        bool success;
        bytes memory res;

        (success, res) = ArbGasInfo.staticcall(
            abi.encodeWithSignature("getCurrentTxL1GasFees()")
        );

        require(success, "Initial ArbGasInfo Revert");

        uint256 arbGasInfoInitial = abi.decode(res, (uint256));

        (success, res) = ArbSys.staticcall(
            abi.encodeWithSignature("getStorageGasAvailable()")
        );

        require(success, "Initial ArbSys Revert");

        uint256 arbSysInitial = abi.decode(res, (uint256));

        initialGas = GasLeft({
            vanilla: gasleft(),
            gasInfo: arbGasInfoInitial,
            arbSys: arbSysInitial
        });

        someShit = "fmiaofsafioasfmio24j0291mfsa";
        string memory poo = someShit;
        someShit = string.concat(poo, "Pooo");

        someShit = "4e412421124";
        someShit = "41afsa24";
        someShit = "412ada4";
        someShit = "41ff2fasfsaaaaaaaafsa4";
        someShit = "41dfasfasfsa4";

        (success, res) = ArbGasInfo.staticcall(
            abi.encodeWithSignature("getCurrentTxL1GasFees()")
        );

        require(success, "Initial ArbGasInfo Revert");

        uint256 arbGasInfoEnd = abi.decode(res, (uint256));

        (success, res) = ArbSys.staticcall(
            abi.encodeWithSignature("getStorageGasAvailable()")
        );

        require(success, "Initial ArbSys Revert");

        uint256 arbSysEnd = abi.decode(res, (uint256));

        endGas = GasLeft({
            vanilla: gasleft(),
            gasInfo: arbGasInfoEnd,
            arbSys: arbSysEnd
        });

        emit GasesLeft(initialGas, endGas);
    }
}