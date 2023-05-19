// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {UpdateAction, Operator, OperatorUpdate} from "src/validator/interfaces/IOperator.sol";
import {IRegistryHandler} from "src/validator/interfaces/IRegistryHandler.sol";

contract MockRegistryHandler is IRegistryHandler {
    uint32 public registrySourceChainId;
    address public registrySourceAddress;
    uint256 public version;
    Operator[] public operators;
    mapping(address => uint256) public operatorIndex;
    uint256 public totalShares;

    error OperatorNotFound();

    constructor(uint32 _registrySourceChainId, address _registrySourceAddress) {
        registrySourceChainId = _registrySourceChainId;
        registrySourceAddress = _registrySourceAddress;
    }

    function setVersion(uint256 _version) external {
        version = _version;
    }

    function addOperator(address _operator, uint256 _shares) external {
        operators.push(Operator(_operator, _shares));
        operatorIndex[_operator] = operators.length - 1;
    }

    function setShares(address _operator, uint256 _shares) external {
        uint256 index = operatorIndex[_operator];
        if (operators[index].operator != _operator) {
            return;
        }
        operators[index].shares = _shares;
    }

    function setTotalShares(uint256 _totalShares) external {
        totalShares = _totalShares;
    }

    function getOperators() external view returns (Operator[] memory) {
        return operators;
    }

    function getOperatorsLength() external view returns (uint256) {
        return operators.length;
    }

    function getShares(address _operator) external view returns (uint256) {
        uint256 index = operatorIndex[_operator];
        if (operators[index].operator != _operator) {
            return 0;
        }
        return operators[index].shares;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

enum UpdateAction {
    INSERT,
    DELETE,
    MODIFY
}

struct Operator {
    address operator;
    uint256 shares;
}

struct OperatorUpdate {
    UpdateAction action;
    address operator;
    uint256 shares;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Operator} from "src/validator/interfaces/IOperator.sol";

interface IRegistryHandler {
    function registrySourceChainId() external view returns (uint32);
    function registrySourceAddress() external view returns (address);
    function version() external view returns (uint256);
    function operators(uint256 index) external view returns (address, uint256);
    function operatorIndex(address operator) external view returns (uint256);
    function getOperators() external view returns (Operator[] memory);
    function getOperatorsLength() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function getShares(address _operator) external view returns (uint256);
}