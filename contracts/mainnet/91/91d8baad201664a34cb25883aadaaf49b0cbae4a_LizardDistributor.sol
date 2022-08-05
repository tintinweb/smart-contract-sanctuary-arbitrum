// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ILizardToken {
    function awardTokens(address to, uint256 amount) external;
}

contract LizardDistributor {
    ILizardToken public immutable token;
    address public owner;
    mapping(string => bool) public claims;

    /// Errors ///
    error Unauthorized();
    error AlreadyClaimed(string nonce);

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
    /// @param amounts array of amounts to send to receivers
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

    /// @notice Allows a user to claim tokens with a valid signature
    /// @param amount number of tokens to send to caller
    /// @param nonce the unique claim id
    function claim(
        uint256 amount,
        string calldata nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Check if already claimed
        if (claims[nonce]) revert AlreadyClaimed(nonce);

        // Check for valid signature
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount, nonce));
        address signer = ecrecover(hash, v, r, s);
        if (signer != owner) revert Unauthorized();

        // Register claim and award tokens
        claims[nonce] = true;
        token.awardTokens(msg.sender, amount);
    }

    /// @notice transfers ownership of the contract to a new address
    /// @param newOwner the address to transfer ownership to
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert Unauthorized();
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}