// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity 0.8.17;

import {ITimeLock} from "@gearbox-protocol/governance/contracts/interfaces/ITimeLock.sol";
import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

contract BatchesChain {
    uint256 public constant version = 3_00;
    address public immutable timelock;

    constructor(address _timelock) {
        timelock = _timelock;
    }

    function revertIfQueued(bytes32 txHash) external view returns (bool) {
        if (ITimeLock(timelock).queuedTransactions(txHash)) {
            revert("BatchesChain: transaction isn't executed yet");
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

/// @title Timelock interface
interface ITimeLock {
    function admin() external view returns (address);

    function delay() external view returns (uint256);

    function queuedTransactions(bytes32 txHash) external view returns (bool);

    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes32 txHash);

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        payable
        returns (bytes memory result);

    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external;

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}