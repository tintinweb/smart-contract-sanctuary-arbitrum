/**
 *Submitted for verification at Arbiscan on 2022-06-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct swapMetadata {
    address inputToken;
    uint256 amount;
    address outputToken;
    uint256 chainId;
}

interface IERC20 {
    function approve(address addr, uint256 amount) external;
}

interface HopL2Bridge {
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}

contract L2Receiver {
    address owner;
    address inchAggregator;
    mapping(address => HopL2Bridge) HopL2Bridges;

    constructor(address _inchAggregator) {
        owner = msg.sender;
        inchAggregator = _inchAggregator;
        HopL2Bridges[0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = HopL2Bridge(0xe22D2beDb3Eca35E6397e0C6D62857094aA26F52);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addHopBridge(
        address[] calldata tokens,
        HopL2Bridge[] calldata bridges
    ) external onlyOwner {
        require(tokens.length == bridges.length);
        for (uint256 i = 0; i < tokens.length; ) {
            HopL2Bridges[tokens[i]] = bridges[i];
            unchecked {
                i++;
            }
        }
    }

    function _sendToL2Addr(
        address l2Recipient,
        address token,
        uint256 chainId,
        uint256 amount
    ) private {
        uint256 deadline = block.timestamp + 86400;
        if (token != address(0)) {
            IERC20(token).approve(address(HopL2Bridges[token]), amount);
            HopL2Bridges[token].swapAndSend(
                chainId,
                l2Recipient,
                amount,
                amount * 25 / 10000,
                0,
                deadline,
                0,
                deadline
            );
        } else {
            HopL2Bridges[token].swapAndSend{value: amount}(
                chainId,
                l2Recipient,
                amount,
                amount * 25 / 10000,
                0,
                deadline,
                0,
                deadline
            );
        }
    }

    function _swap(
        address inputToken,
        uint256 inputAmount,
        bytes memory inchData
    ) private returns (uint256) {
        bool status = false;
        bytes memory data;
        if (inputToken == address(0)) {
            (status, data) = inchAggregator.call{value: inputAmount}(inchData);
        } else {
            IERC20(inputToken).approve(inchAggregator, inputAmount);
            (status, data) = inchAggregator.call(inchData);
        }
        require(status);
        (uint256 returnAmount, ) = abi.decode(data, (uint256, uint256));
        return returnAmount;
    }

    function swapAndBridge(address l2Recipient, swapMetadata calldata swapData, bytes calldata inchData)
        external
        onlyOwner
    {
        uint256 outputAmount = _swap(
            swapData.inputToken,
            swapData.amount,
            inchData
        );
        _sendToL2Addr(
            l2Recipient,
            swapData.outputToken,
            swapData.chainId,
            outputAmount
        );
    }
}