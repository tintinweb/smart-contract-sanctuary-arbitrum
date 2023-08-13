/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

/**
 *Submitted for verification at Arbiscan on 2023-08-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Transfer {
    address public owner;
    mapping(address => bool) private verifiedTokens;
    address[] public verifiedTokenList;

    struct Transaction {
        address sender;
        address receiver;
        address tokenAddress;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    event TransactionCompleted(
        address indexed sender,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "ERC20Transfer: caller is not the owner");
        _;
    }

    modifier onlyVerifiedToken(address _token) {
        require(verifiedTokens[_token] == true, "ERC20Transfer: token is not verified");
        _;
    }

    function addVerifiedToken(address _token) public onlyOwner {
        verifiedTokens[_token] = true;
        verifiedTokenList.push(_token);
    }

    function removeVerifiedToken(address _token) public onlyOwner {
        require(verifiedTokens[_token] == true, "ERC20Transfer: token is not in the list");
        verifiedTokens[_token] = false;

        for (uint256 i = 0; i < verifiedTokenList.length; i++) {
            if (verifiedTokenList[i] == _token) {
                verifiedTokenList[i] = verifiedTokenList[verifiedTokenList.length - 1];
                verifiedTokenList.pop();
                break;
            }
        }
    }

    function getVerifiedTokens() public view returns (address[] memory) {
        return verifiedTokenList;
    }

    function isUserOwnsToken(address user, IERC20Interface token) public view returns (bool) {
        return token.balanceOf(user) > 0;
    }

    function transfer(IERC20Interface token, address to, uint256 amount, string memory message) public onlyVerifiedToken(address(token)) returns (bool) {
        if (!isUserOwnsToken(msg.sender, token)) {
            return false;
        }

        uint256 senderBalance = token.balanceOf(msg.sender);
        if (senderBalance < amount) {
            return false;
        }

        bool success = token.transferFrom(msg.sender, to, amount);
        if (!success) {
            return false;
        }

        uint256 timestamp = block.timestamp;

        Transaction memory transaction = Transaction({
            sender: msg.sender,
            receiver: to,
            tokenAddress: address(token),
            amount: amount,
            message: message,
            timestamp: timestamp
        });

        emit TransactionCompleted(transaction.sender, transaction.receiver, transaction.tokenAddress, transaction.amount, transaction.message, transaction.timestamp);

        return true;
    }

}