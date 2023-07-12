// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMerkleFunderDepository {
    error SenderNotMerkleFunder();

    error TransferUnsuccessful();

    function merkleFunder() external view returns (address);

    function owner() external view returns (address);

    function root() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IMerkleFunderDepository.sol";

/// @title Contract that is deployed through MerkleFunder and keeps the funds
/// that can be transferred within the limitations specified by the respective
/// Merkle tree
/// @notice As noted above, this contract should only be deployed by a
/// MerkleFunder contract. Since the owner address and the Merkle tree root are
/// immutable, the only way to update these is to deploy a new
/// MerkleFunderDepository with the desired parameters and have the owner of
/// the previous MerkleFunderDepository withdraw the funds to the new one.
contract MerkleFunderDepository is IMerkleFunderDepository {
    /// @notice Address of the MerkleFunder that deployed this contract
    address public immutable override merkleFunder;

    /// @notice Owner address
    address public immutable override owner;

    /// @notice Merkle tree root
    bytes32 public immutable override root;

    /// @dev Argument validation is done in MerkleFunder to reduce the
    /// bytecode of this contract
    /// @param _owner Owner address
    /// @param _root Merkle tree root
    constructor(address _owner, bytes32 _root) {
        merkleFunder = msg.sender;
        owner = _owner;
        root = _root;
    }

    /// @dev Funds transferred to this contract can be transferred by anyone
    /// within the limitations of the respective Merkle tree
    receive() external payable {}

    /// @notice Called by the MerkleFunder that has deployed this contract to
    /// transfer its funds within the limitations of the respective Merkle tree
    /// or to allow the owner to withdraw funds
    /// @dev Argument validation is done in MerkleFunder to reduce the bytecode
    /// of this contract.
    /// This function is omitted in the interface because it is intended to
    /// only be called by MerkleFunder.
    /// @param recipient Recipient address
    /// @param amount Amount
    function transfer(address recipient, uint256 amount) external {
        if (msg.sender != merkleFunder) revert SenderNotMerkleFunder();
        // MerkleFunder checks for balance so MerkleFunderDepository does not
        // need to
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferUnsuccessful();
        // MerkleFunder emits the event so MerkleFunderDepository does not need
        // to
    }
}