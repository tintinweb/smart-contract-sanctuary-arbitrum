// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ILizardToken {
    function awardTokens(address to, uint256 amount) external;
}

contract LizardDistributor {
    ILizardToken public immutable token;
    address public owner;

    /// Errors ///
    error Unauthorized();

    /// Events ///
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /// Constructor ///
    constructor(ILizardToken _token) {
        token = _token;
        owner = msg.sender;
    }

    /// @notice batch distributes tokens
    /// @param receivers array of addresses to recveive tokens
    /// @param amounts array of ammounts to send to receivers
    function distribute(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external {
        if (msg.sender != owner) revert Unauthorized();

        uint256 length = receivers.length;

        for (uint256 i = 0; i < length; ++i) {
            token.awardTokens(receivers[i], amounts[i]);
        }
    }

    /// @notice transfers ownership of the contract to a new address
    /// @param newOwner the address to transfer ownership to
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert Unauthorized();
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}