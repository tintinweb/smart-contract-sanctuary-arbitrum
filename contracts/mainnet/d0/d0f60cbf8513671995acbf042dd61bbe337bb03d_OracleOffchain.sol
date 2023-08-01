// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract OracleOffchain {
    error Unauthorized();

    int256 public lastPrice;
    uint256 public lastUpdate;
    mapping(address => bool) public exec;

    event File(bytes32 indexed what, address data);
    event Updated(int256 price);

    constructor() {
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit File(what, data);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
        require(block.timestamp < lastUpdate + 30 minutes, "stale price");
        require(lastPrice != 0, "zero price");
        return lastPrice;
    }

    function update(int256 price) external auth {
        lastPrice = price;
        lastUpdate = block.timestamp;
        emit Updated(price);
    }
}