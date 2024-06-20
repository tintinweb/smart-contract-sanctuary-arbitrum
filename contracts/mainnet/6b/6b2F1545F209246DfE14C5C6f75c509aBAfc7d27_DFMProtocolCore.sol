// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Addresses } from "contracts/base/dependencies/Addresses.sol";
import { IProtocolCore } from "contracts/interfaces/IProtocolCore.sol";

/**
    @title Defi.money Protocol Core
    @author defidotmoney (based on CoreOwner by Prisma Finance)
    @notice Single source of truth for system-wide values and contract ownership.
            Other ownable contracts inherit ownership from this contract via `CoreOwnable`.
 */
contract DFMProtocolCore is IProtocolCore {
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

        ownershipTransferDeadline = type(uint256).max;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "DFM: Only owner");
        _;
    }

    // ---- Address getters -----
    // Unique getters are provided for privledged roles that are commonly
    // required by the core protocol. For future flexibility we also include
    // a more generic `getAddress`.

    /**
        @notice Address that receives protocol fees
     */
    function feeReceiver() external view returns (address) {
        return addressRegistry[Addresses.FEE_RECEIVER];
    }

    /**
        @notice Address of the bridge relay
        @dev * Not set within the constructor. Bridging functionality should
               verify that the relay is set before attempting an action.
             * The relay contract must adhere to the `IBridgeRelay` interface.
     */
    function bridgeRelay() external view returns (address) {
        return addressRegistry[Addresses.BRIDGE_RELAY];
    }

    /**
        @notice Address with capability to quickly pause certain elements
                of the protocol in the event of an exploit
        @dev * Not set within the constructor. If using a guardian, it must be
               set after deployment.
             * It is critical that the guardian is not able to block an admin
               action to change or remove the guardian.
     */
    function guardian() external view returns (address) {
        return addressRegistry[Addresses.GUARDIAN];
    }

    function getAddress(bytes32 identifier) external view returns (address) {
        address account = addressRegistry[identifier];
        require(account != address(0), "DFM: No address for identifier");
        return account;
    }

    // ----- Non-payable external methods -----

    function setAddress(bytes32 identifier, address account) external onlyOwner {
        addressRegistry[identifier] = account;
    }

    function commitTransferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;

        uint256 deadline;
        if (ownershipTransferDeadline == type(uint256).max) {
            // We do not enforce a transfer delay on the first ownership transfer,
            // because it is from the deployer EOA to the intended protocol owner.
            deadline = block.timestamp;
        } else {
            deadline = block.timestamp + OWNERSHIP_TRANSFER_DELAY;
        }
        ownershipTransferDeadline = deadline;

        emit NewOwnerCommitted(msg.sender, newOwner, deadline);
    }

    function acceptTransferOwnership() external {
        require(msg.sender == pendingOwner, "DFM: Only new owner");
        require(block.timestamp >= ownershipTransferDeadline, "DFM: Deadline not passed");

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

pragma solidity ^0.8.0;

library Addresses {
    bytes32 internal constant BRIDGE_RELAY = bytes32("BRIDGE_RELAY");
    bytes32 internal constant FEE_RECEIVER = bytes32("FEE_RECEIVER");
    bytes32 internal constant GUARDIAN = bytes32("GUARDIAN");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProtocolCore {
    function owner() external view returns (address);

    function START_TIME() external view returns (uint256);

    function getAddress(bytes32 identifier) external view returns (address);

    function bridgeRelay() external view returns (address);

    function feeReceiver() external view returns (address);

    function guardian() external view returns (address);
}