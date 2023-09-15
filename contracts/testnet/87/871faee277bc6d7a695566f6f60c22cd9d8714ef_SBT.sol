// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ISBT} from "./ISBT.sol";

contract SBT is ISBT {
    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISBT {
    function merkleRoot() external returns (bytes32);
}