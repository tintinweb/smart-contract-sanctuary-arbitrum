// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {IFeeManager} from "../interfaces/IFeeManager.sol";

contract FeeManager is IFeeManager {
    address public exchange;
    address public gov;

    event FeesCollected(bytes32 indexed marketId, address indexed token, uint256 amount);

    constructor(address _exchange) {
        exchange = _exchange;
        gov = msg.sender;
    }

    modifier onlyExchange() {
        require(msg.sender == exchange, "FeeManager: onlyExchange");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "FeeManager: onlyGov");
        _;
    }

    function setExchange(address _exchange) external onlyGov {
        exchange = _exchange;
    }

    // marketId -> token -> fee
    mapping(bytes32 => mapping(address => uint256)) public fees;

    // mapping fees to vault
    mapping(bytes32 => mapping(address => address)) public vaults;

    function updateFee(bytes32 marketId, address token, uint256 amount) external onlyExchange {
        fees[marketId][token] += amount;
        emit FeesCollected(marketId, token, amount);
    }

    function distributeFee() external onlyGov {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IFeeManager {
    function updateFee(bytes32 marketId, address token, uint256 amount) external;
}