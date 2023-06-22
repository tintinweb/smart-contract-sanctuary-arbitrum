// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract ImplementationStorageV1 {
    uint8 version;
    uint256 public slot1;
    uint256 public slot2;
}

contract ImplementationStorageV2 is ImplementationStorageV1 {
    address public slot3;
    uint256 public slot4;
}

contract ImplementatonV1 is ImplementationStorageV1 {
    // should not be called when deploying with the proxy factory.
    constructor() {
        slot1 = 1;
        slot2 = 2;
    }

    function init() external {
        assert(version == 0);
        slot1 = 3;
        slot2 = 4;
        version = 1;
    }
}

contract ImplementatonV2 is ImplementationStorageV2 {
    function init() external {
        assert(version == 1);
        slot1 = 5;
        slot2 = 6;
        version = 2;
    }
}