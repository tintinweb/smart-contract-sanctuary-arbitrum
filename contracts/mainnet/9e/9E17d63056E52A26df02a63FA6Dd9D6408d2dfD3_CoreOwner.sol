// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "contracts/dependencies/Addresses.sol";
import "contracts/interfaces/ICoreOwner.sol";

/**
    @title Core Owner
    @author Prisma Finance
    @notice Single source of truth for system-wide values and contract ownership.

            Ownership of this contract should be the DAO via `AdminVoting`.
            Other ownable contracts inherit their ownership from this contract
            using `CoreOwnable`.
 */
contract CoreOwner is ICoreOwner {
    address public owner;
    address public pendingOwner;
    uint256 public ownershipTransferDeadline;

    // We enforce a three day delay between committing and accepting
    // an ownership change, as a sanity check on a proposed new owner
    // and to give users time to react in case the act is malicious.
    uint256 public constant OWNERSHIP_TRANSFER_DELAY = 86400 * 3;

    // System-wide start time. Contracts that require this must inherit `SystemStart`.
    uint256 public immutable START_TIME;

    mapping(bytes32 identifier => address account) private addressRegistry;

    event NewOwnerCommitted(address owner, address pendingOwner, uint256 deadline);
    event NewOwnerAccepted(address oldOwner, address owner);
    event NewOwnerRevoked(address owner, address revokedOwner);

    /**
        @param startOffset Seconds to subtract when calculating `START_TIME`. With 0
                           offset, the new weekly epoch starts Thursday at 00:00:00 UTC.
                           With an offset of 302400 (3 days, 12 hours) the epoch starts
                           Sunday at 12:00:00 UTC.
     */
    constructor(address _owner, address _feeReceiver, uint256 startOffset) {
        owner = _owner;

        uint256 start = (block.timestamp / 7 days) * 7 days - startOffset;
        if (start + 7 days < block.timestamp) start += 7 days;
        START_TIME = start;

        addressRegistry[Addresses.FEE_RECEIVER] = _feeReceiver;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function feeReceiver() external view returns (address) {
        return addressRegistry[Addresses.FEE_RECEIVER];
    }

    function getAddress(bytes32 identifier) external view returns (address) {
        address account = addressRegistry[identifier];
        require(account != address(0), "No address for identifier");
        return account;
    }

    function setAddress(bytes32 identifier, address account) external onlyOwner {
        addressRegistry[identifier] = account;
    }

    function commitTransferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
        ownershipTransferDeadline = block.timestamp + OWNERSHIP_TRANSFER_DELAY;

        emit NewOwnerCommitted(msg.sender, newOwner, block.timestamp + OWNERSHIP_TRANSFER_DELAY);
    }

    function acceptTransferOwnership() external {
        require(msg.sender == pendingOwner, "Only new owner");
        require(block.timestamp >= ownershipTransferDeadline, "Deadline not passed");

        emit NewOwnerAccepted(owner, msg.sender);

        owner = pendingOwner;
        pendingOwner = address(0);
        ownershipTransferDeadline = 0;
    }

    function revokeTransferOwnership() external onlyOwner {
        emit NewOwnerRevoked(msg.sender, pendingOwner);

        pendingOwner = address(0);
        ownershipTransferDeadline = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library Addresses {
    bytes32 internal constant BRIDGE_RELAY = bytes32("BRIDGE_RELAY");
    bytes32 internal constant FEE_RECEIVER = bytes32("FEE_RECEIVER");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICoreOwner {
    function owner() external view returns (address);

    function START_TIME() external view returns (uint256);

    function getAddress(bytes32 identifier) external view returns (address);

    function feeReceiver() external view returns (address);
}