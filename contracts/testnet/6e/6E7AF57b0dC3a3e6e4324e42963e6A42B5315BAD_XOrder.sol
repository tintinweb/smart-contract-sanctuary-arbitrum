// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity 0.8.6;

contract XOrder {

    mapping(bytes32 => address) public requestToTokens;
    mapping(bytes32 => bool) public history;

    event RequestPrice(bytes32 indexed requestId, address indexed token);
    event PriceUpdated(
        address indexed feeder, bytes32 indexed requestId,
        address indexed token, uint64 price
    );
    event PriceRejected(
        address indexed feeder, bytes32 indexed requestId, address indexed token,
        uint64 price, uint64 beforePrice, uint40 updatedAt
    );
    error DuplicatedRequest();

    function requestPriceCallback(bytes32 requestId, uint64 price) external {
        if(history[requestId] == true) {
            revert DuplicatedRequest();
        }
        if(block.number%2 == 0) {
            history[requestId] = true;
            emit PriceUpdated(msg.sender, requestId, requestToTokens[requestId], price);
        } else {
            emit PriceRejected(
                msg.sender, requestId, requestToTokens[requestId], price, 333333333333, 12345
            );
        }
    }

    function triggerRequestPrice(bytes32 requestId, address token) external {
        emit RequestPrice(requestId, token);
        requestToTokens[requestId] = token;
    }

}