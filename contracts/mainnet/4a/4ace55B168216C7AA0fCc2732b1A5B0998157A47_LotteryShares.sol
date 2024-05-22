// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/Ownable.sol";


/// @title Handles Winning Shares for the Lottery System.
contract LotteryShares is Ownable {
    /// @dev Winning shares per ticket size and matching numbers.
    uint256[7][8][7] public WINNING_SHARES;

    event WinningSharesUpdated(uint256[7][8][7] winningShares);

    // Ownership will be renounced after addresses updated.
    constructor() 
    {
        ownerAddress = msg.sender;
    }

    /// @dev Allows owner to update winning shares per ticket size.
    function SetupWinningShares(uint256 ticketSize, uint256[7][8] memory winningShare)
    external onlyOwner {
        WINNING_SHARES[ticketSize - 6] = winningShare;
        emit WinningSharesUpdated(WINNING_SHARES);
    }

    /// @dev Returns the number of winning shares based on ticket size and number of matches.
    function getWinningTiers(uint256 ticketSize, uint256 winningMatches, bool isAdditionalMatch)
    external view returns (uint256[7] memory winningTiers) {
        uint256 ticketIndex = ticketSize - 6; // 6 -> index 0, 12 -> index 6

        if (winningMatches >= 3) {
            uint256 rewardIndex = (winningMatches - 3) * 2;
            winningTiers = WINNING_SHARES[ticketIndex][rewardIndex + (isAdditionalMatch ? 1 : 0)];
        }
    }

    function GetWinningShares() 
    external view returns (uint256[7][8][7] memory winningShares) {
        return WINNING_SHARES;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Handles Access Control for a single Owner/multiple Admins.
/// @dev Facilitates ACL via onlyOwner modifiers.
contract Ownable {
    /// @notice Address with Owner privileges.
    address public ownerAddress;
    address public potentialOwner;

    event OwnershipTransferred(address oldOwner, address newOwner);
    event OwnerNominated(address potentialOwner);
    
    /// @dev Throws if the sender is not the owner.
    function _onlyOwner() private view {
        require(msg.sender == ownerAddress, "Not Owner");
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @dev Transfers ownership to (`newOwner`).
    function TransferOwnership(address pendingOwner) external onlyOwner {
        require(pendingOwner != address(0), "Invalid owner");
        potentialOwner = pendingOwner;
        emit OwnerNominated(potentialOwner);
    }

    /// @dev Allows nominated owner to accept ownership.
    function AcceptOwnership() external {
        require(msg.sender == potentialOwner, 'Not nominated');
        emit OwnershipTransferred(ownerAddress, potentialOwner);
        ownerAddress = potentialOwner;
        potentialOwner = address(0); 
    }

    /// @dev Revoke ownership.
    /// Transfer to zero address to renounce ownership to disable `onlyOwner` functionality.
    function RevokeOwnership() external onlyOwner {
        emit OwnershipTransferred(ownerAddress, address(0));
        ownerAddress = address(0);
        potentialOwner = address(0);
    }
}