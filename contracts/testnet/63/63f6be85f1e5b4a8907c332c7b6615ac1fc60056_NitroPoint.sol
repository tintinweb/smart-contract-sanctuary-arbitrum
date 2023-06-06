// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { INitroPoint } from "./interfaces/INitroPoint.sol";

contract NitroPoint is INitroPoint {
    mapping(address => uint256) pointBalance;
    mapping(address => mapping(address => bool)) approval;

    function givePoint(address to, uint256 amount) external override {
        pointBalance[to] += amount;
        emit PointTransfer(to, amount);
    }

    function getPointBalance(address to) external view override returns (uint256 balance) {
        balance = pointBalance[to];
    }

    function burnPoint(address from, uint256 amount) external override {
        if (msg.sender != from && !approval[from][msg.sender]) revert NitroPoint__NotApproved(from, msg.sender);
        if (amount > pointBalance[from]) revert NitroPoint__InsuffientBalance();
        pointBalance[from] -= amount;
        emit PointTransfer(address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface INitroPoint {
    error NitroPoint__NotApproved(address owner, address spender);
    error NitroPoint__InsuffientBalance();

    event PointTransfer(address indexed to, uint256 indexed amount);

    function givePoint(address to, uint256 amount) external;
    function getPointBalance(address to) external view returns (uint256 balance);
    function burnPoint(address from, uint256 amount) external;
}