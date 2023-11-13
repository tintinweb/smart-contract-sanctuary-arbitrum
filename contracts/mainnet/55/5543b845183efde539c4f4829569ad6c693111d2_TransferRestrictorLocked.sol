// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

import {ITransferRestrictor} from "./ITransferRestrictor.sol";

/// @notice Locks all transfers
/// @author Dinari (https://github.com/dinaricrypto/sbt-contracts/blob/main/src/TransferRestrictorLocked.sol)
contract TransferRestrictorLocked is ITransferRestrictor {
    /// @inheritdoc ITransferRestrictor
    function isBlacklisted(address) external pure returns (bool) {
        return true;
    }

    /// @inheritdoc ITransferRestrictor
    function requireNotRestricted(address, address) external view virtual {
        // Always revert
        revert AccountRestricted();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

/// @notice Enforces transfer restrictions
/// @author Dinari (https://github.com/dinaricrypto/sbt-contracts/blob/main/src/ITransferRestrictor.sol)
interface ITransferRestrictor {
    /// @dev Account is restricted
    error AccountRestricted();

    /// @notice Checks if the transfer is allowed
    /// @param from The address of the sender
    /// @param to The address of the recipient
    function requireNotRestricted(address from, address to) external view;

    /// @notice Checks if the transfer is allowed
    /// @param account The address of the account
    function isBlacklisted(address account) external view returns (bool);
}