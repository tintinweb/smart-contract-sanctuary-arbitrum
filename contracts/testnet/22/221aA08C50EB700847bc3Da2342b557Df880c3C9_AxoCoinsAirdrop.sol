// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AxoCoinsAirdrop {
    address public owner;
    address public token;

    event Airdrop(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    constructor(address _token) {
        owner = msg.sender;
        token = _token;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length > 0, "Recipient list is empty.");
        require(
            recipients.length == amounts.length,
            "Recipient and amount arrays must have the same length."
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                IERC20(token).transferFrom(
                    msg.sender,
                    recipients[i],
                    amounts[i]
                ),
                "Failed to transfer tokens to a recipient."
            );
            emit Airdrop(msg.sender, recipients[i], amounts[i]);
        }
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw.");

        require(
            IERC20(token).transfer(owner, balance),
            "Failed to transfer tokens to the owner."
        );
    }
}