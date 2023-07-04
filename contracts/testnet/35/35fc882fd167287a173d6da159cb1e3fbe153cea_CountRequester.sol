// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Counter} from "src/example/Counter.sol";
import {IStateQueryGateway, StateQuery} from "src/query/interfaces/IStateQueryGateway.sol";

contract CountRequester {
    address public immutable stateQueryGateway;
    uint256 public lastReceivedCount;

    event CountReceived(uint256 count, address requestSender);
    event BatchCountReceived(uint64 blockNumber, uint256 count, address requestSender);

    error NotFromStateQueryGateway(address sender);

    constructor(address _stateQueryGateway) {
        stateQueryGateway = _stateQueryGateway;
    }

    function requestCount(uint32 _counterChainId, uint64 _blockNumber, address _counterAddress)
        public
        returns (bytes32, uint256)
    {
        return IStateQueryGateway(stateQueryGateway).requestStateQuery(
            StateQuery({
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

    function batchRequestCount(
        uint32 _counterChainId,
        uint64[] memory _blockNumbers,
        address _counterAddress
    ) public returns (bytes32, uint256) {
        StateQuery[] memory stateQueries = new StateQuery[](_blockNumbers.length);
        for (uint256 i = 0; i < _blockNumbers.length; i++) {
            stateQueries[i] = StateQuery({
                chainId: _counterChainId,
                blockNumber: _blockNumbers[i],
                fromAddress: address(0),
                toAddress: _counterAddress,
                toCalldata: abi.encodeWithSelector(Counter.getCount.selector)
            });
        }

        return IStateQueryGateway(stateQueryGateway).requestBatchStateQuery(
            stateQueries,
            CountRequester.handleBatchRequest.selector,
            abi.encode(msg.sender, _blockNumbers)
        );
    }

    function handleRequest(bytes calldata _requestResult, bytes calldata _callbackExtraData)
        external
    {
        if (msg.sender != stateQueryGateway) {
            revert NotFromStateQueryGateway(msg.sender);
        }
        uint256 count = abi.decode(_requestResult, (uint256));
        address requestSender = abi.decode(_callbackExtraData, (address));

        lastReceivedCount = count;

        emit CountReceived(count, requestSender);
    }

    function handleBatchRequest(bytes[] calldata _requestResults, bytes calldata _callbackExtraData)
        external
    {
        if (msg.sender != address(stateQueryGateway)) {
            revert NotFromStateQueryGateway(msg.sender);
        }
        (address requestSender, uint64[] memory blockNumbers) =
            abi.decode(_callbackExtraData, (address, uint64[]));
        for (uint256 i = 0; i < _requestResults.length; i++) {
            uint256 count = abi.decode(_requestResults[i], (uint256));
            lastReceivedCount = count;
            emit BatchCountReceived(blockNumbers[i], count, requestSender);
        }
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

/// @notice Struct for StateQuery request information.
/// @dev Setting these corresponse to the `CallMsg` fields of StateQuery:
///      https://github.com/ethereum/go-ethereum/blob/fd5d2ef0a6d9eac7542ead4bfbc9b5f0f399eb10/interfaces.go#L134
/// @param chainId The chain ID of the chain where the StateQuery will be made.
/// @param blockNumber The block number of the chain where the StateQuery is made.
///        If blockNumber is 0, then the StateQuery is made at the latest avaliable
///        block.
/// @param fromAddress The address that is used as the 'from' StateQuery argument
///        (influencing msg.sender & tx.origin). If set to address(0) then the
///        call is made from address(0).
/// @param toAddress The address that is used as the 'to' StateQuery argument.
/// @param toCalldata The calldata that is used as the 'data' StateQuery argument.
struct StateQuery {
    uint32 chainId;
    uint64 blockNumber;
    address fromAddress;
    address toAddress;
    bytes toCalldata;
}

/// @notice Struct for StateQuery request information wrapped with the attested result.
/// @param result The result from executing the StateQuery.
struct StateQueryResponse {
    uint32 chainId;
    uint64 blockNumber;
    address fromAddress;
    address toAddress;
    bytes toCalldata;
    bytes result;
}

/// @notice Struct for managing StateQueryResponse callback information.
/// @dev The callback contract should be able to handle a call to it with the
///      data bytes as:
///         callbackSelector + request + callbackExtraData
///       where 'request' is the StateQueryResponse bytes.
/// @param stateQueryHash The hash of the StateQuery that was requested.
/// @param callbackAddress The address of the contract that will be called back
///        after the StateQueryResponse is processed. Setting the callback address
///        to 0x0 indicates that no callback contract will be called.
/// @param callbackSelector The selector of the function that will be called
///        back after the StateQueryResponse is processed.
/// @param callbackExtraData The extra data that will be passed to the callback
///        function after the StateQueryResponse is processed. This will be inserted
///        after the request.
struct StateQueryResponseCallback {
    bytes32 stateQueryHash;
    address callbackAddress;
    bytes4 callbackSelector;
    bytes callbackExtraData;
}

interface IStateQueryGateway {
    function nonce() external view returns (uint256);

    function requestStateQuery(
        uint32 chainId,
        uint64 blockNumber,
        address fromAddress,
        address toAddress,
        bytes memory toCalldata,
        bytes4 callbackSelector,
        bytes memory callbackExtraData
    ) external returns (bytes32, uint256);

    function requestStateQuery(
        StateQuery memory stateQuery,
        bytes4 callbackSelector,
        bytes memory callbackExtraData
    ) external returns (bytes32, uint256);

    function requestBatchStateQuery(
        StateQuery[] memory _stateQueries,
        bytes4 _callbackSelector,
        bytes calldata _callbackExtraData
    ) external returns (bytes32, uint256);

    function currentResponse() external view returns (StateQueryResponse memory);
}