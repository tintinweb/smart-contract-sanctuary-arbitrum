// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Counter} from "src/example/Counter.sol";
import {IEthCallGateway, EthCall} from "src/query/interfaces/IEthCallGateway.sol";

contract CountRequester {
    address public immutable ethCallGateway;
    uint256 public lastReceivedCount;

    event CountReceived(uint256 count, address requestSender);

    error NotFromEthCallGateway(address sender);

    constructor(address _ethCallGateway) {
        ethCallGateway = _ethCallGateway;
    }

    function requestCount(uint32 _counterChainId, uint64 _blockNumber, address _counterAddress)
        public
        returns (bytes32, uint256)
    {
        return IEthCallGateway(ethCallGateway).requestEthCall(
            EthCall({
                chainId: _counterChainId,
                blockNumber: _blockNumber,
                fromAddress: address(0),
                toAddress: _counterAddress,
                toCalldata: abi.encodeWithSelector(Counter.getCount.selector)
            }),
            CountRequester.handleRequest.selector,
            abi.encode(msg.sender)
        );
    }

    function handleRequest(bytes calldata _requestResult, bytes calldata _callbackExtraData)
        external
    {
        if (msg.sender != ethCallGateway) {
            revert NotFromEthCallGateway(msg.sender);
        }
        uint256 count = abi.decode(_requestResult, (uint256));
        address requestSender = abi.decode(_callbackExtraData, (address));

        lastReceivedCount = count;

        emit CountReceived(count, requestSender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Counter {
    uint256 private count;

    function increment() public {
        count++;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @notice Struct for eth_call request information.
/// @dev Setting these corresponse to the `CallMsg` fields of eth_call:
///      https://github.com/ethereum/go-ethereum/blob/fd5d2ef0a6d9eac7542ead4bfbc9b5f0f399eb10/interfaces.go#L134
/// @param chainId The chain ID of the chain where the eth_call will be made.
/// @param blockNumber The block number of the chain where the eth_call is made.
///        If blockNumber is 0, then the eth_call is made at the latest avaliable
///        block.
/// @param fromAddress The address that is used as the 'from' eth_call argument
///        (influencing msg.sender & tx.origin). If set to address(0) then the
///        call is made from address(0).
/// @param toAddress The address that is used as the 'to' eth_call argument.
/// @param toCalldata The calldata that is used as the 'data' eth_call argument.
struct EthCall {
    uint32 chainId;
    uint64 blockNumber;
    address fromAddress;
    address toAddress;
    bytes toCalldata;
}

/// @notice Struct for eth_call request information wrapped with the attested result.
/// @param result The result from executing the eth_call.
struct EthCallResponse {
    uint32 chainId;
    uint64 blockNumber;
    address fromAddress;
    address toAddress;
    bytes toCalldata;
    bytes result;
}

/// @notice Struct for managing EthCallResponse callback information.
/// @dev The callback contract should be able to handle a call to it with the
///      data bytes as:
///         callbackSelector + request + callbackExtraData
///       where 'request' is the EthCallResponse bytes.
/// @param ethCallHash The hash of the EthCall that was requested.
/// @param callbackAddress The address of the contract that will be called back
///        after the EthCallResponse is processed. Setting the callback address
///        to 0x0 indicates that no callback contract will be called.
/// @param callbackSelector The selector of the function that will be called
///        back after the EthCallResponse is processed.
/// @param callbackExtraData The extra data that will be passed to the callback
///        function after the EthCallResponse is processed. This will be inserted
///        after the request.
struct EthCallResponseCallback {
    bytes32 ethCallHash;
    address callbackAddress;
    bytes4 callbackSelector;
    bytes callbackExtraData;
}

interface IEthCallGateway {
    function nonce() external view returns (uint256);

    function requestEthCall(
        uint32 chainId,
        uint64 blockNumber,
        address fromAddress,
        address toAddress,
        bytes memory toCalldata,
        bytes4 callbackSelector,
        bytes memory callbackExtraData
    ) external returns (bytes32, uint256);

    function requestEthCall(
        EthCall memory ethCall,
        bytes4 callbackSelector,
        bytes memory callbackExtraData
    ) external returns (bytes32, uint256);

    function currentResponse() external view returns (EthCallResponse memory);
}