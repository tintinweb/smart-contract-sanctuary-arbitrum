// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";

contract PoolCreateEvent is Ownable {

    constructor() {
        owner = msg.sender;
    }

    event PoolCreated(address indexed factory, bool indexed isApeXPool, uint256 initTimestamp, uint256 endTimestamp);

    function PoolCreate(address factory, bool isApeXPool, uint256 initTimestamp, uint256 endTimestamp) external onlyOwner {
        emit PoolCreated(factory, isApeXPool, initTimestamp, endTimestamp);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}