/**
 *Submitted for verification at Arbiscan.io on 2023-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Proof-of-Work Messenger
/// @notice A contract that allows users to send messages to each other with a linearly decreasing incentive
contract PoWMessenger {
    struct Conversation {
        uint128 rewardPerMessage;
        uint64 patience;
        uint64 deadline;
    }

    event Deposit(address indexed sender, uint256 value);
    event Withdrawal(address indexed sender, uint256 value);
    event IncentiveSet(address indexed sender, address indexed receiver, uint128 rewardPerMessage, uint64 patience);
    event MessageSent(address indexed sender, address indexed receiver, string message);
    event Response(address indexed sender, address indexed receiver, string message);

    mapping(address sender => uint256 balance) internal _balanceOf;
    mapping(address sender => mapping(address receiver => Conversation convo)) internal _conversations;

    receive() external payable {
        deposit();
    }

    /// @notice Increases the balance of the sender
    function deposit() public payable {
        if (msg.value != 0) {
            unchecked {
                _balanceOf[msg.sender] += msg.value;
            }
            emit Deposit(msg.sender, msg.value);
        }
    }

    /// @notice Withdraws unused balance of the sender
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external {
        uint256 balance = _balanceOf[msg.sender];
        require(balance >= amount, "insufficient balance");
        unchecked {
            _balanceOf[msg.sender] = balance - amount;
        }
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "withdraw failed");
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Sets the incentive for the receiver to respond to the sender
    /// @param receiver The receiver of the message
    /// @param rewardPerMessage The reward per message
    /// @param patience The patience of the sender in seconds
    function setIncentive(address receiver, uint128 rewardPerMessage, uint64 patience) external payable {
        deposit();
        _conversations[msg.sender][receiver] =
            Conversation({rewardPerMessage: rewardPerMessage, patience: patience, deadline: 0});
        emit IncentiveSet(msg.sender, receiver, rewardPerMessage, patience);
    }

    /// @notice Sends a message to the receiver
    /// @param receiver The receiver of the message
    /// @param message The message to send
    function sendMessage(address receiver, string calldata message) external payable {
        deposit();
        Conversation storage _convo = _conversations[msg.sender][receiver];
        Conversation memory convo = _convo;
        uint128 rewardPerMessage = convo.rewardPerMessage;
        require(rewardPerMessage != 0, "no incentive");
        require(_balanceOf[msg.sender] >= rewardPerMessage, "insufficient balance");
        unchecked {
            uint64 deadline = uint64(block.timestamp + convo.patience);
            require(deadline > block.timestamp, "overflow");
            _convo.deadline = deadline;
        }
        emit MessageSent(msg.sender, receiver, message);
    }

    /// @notice Responds to the sender and claims the reward
    /// @param sender The sender of the message
    /// @param message The response message
    function respond(address sender, string calldata message) external {
        Conversation storage _convo = _conversations[sender][msg.sender];
        Conversation memory convo = _convo;
        unchecked {
            uint64 deadline = convo.deadline;
            require(deadline > block.timestamp, "patience exhausted");
            _convo.deadline = 0;
            uint256 reward = uint256(convo.rewardPerMessage) * (deadline - block.timestamp) / convo.patience;
            uint256 balance = _balanceOf[sender];
            require(balance >= reward, "insufficient balance");
            _balanceOf[sender] = balance - reward;
            (bool success,) = msg.sender.call{value: reward}("");
            require(success, "reward failed");
        }
        emit Response(sender, msg.sender, message);
    }

    /// @notice Returns the remaining balance of the sender
    /// @param sender The sender of the message
    /// @return The remaining balance of the sender
    function balanceOf(address sender) external view returns (uint256) {
        return _balanceOf[sender];
    }

    /// @notice Returns the conversation configuration between the sender and receiver
    /// @param sender The sender of the message
    /// @param receiver The receiver of the message
    /// @return The conversation configuration between the sender and receiver
    function conversations(address sender, address receiver) external view returns (Conversation memory) {
        return _conversations[sender][receiver];
    }

    /// @notice Returns the reward that the receiver can claim from the sender for the current message
    /// @param sender The sender of the message
    /// @return The reward that the receiver can claim from the sender for the current message
    function estimateReward(address sender) external view returns (uint256) {
        Conversation memory convo = _conversations[sender][msg.sender];
        if (convo.rewardPerMessage == 0 || convo.deadline <= block.timestamp) {
            return 0;
        }
        unchecked {
            uint256 reward = uint256(convo.rewardPerMessage) * (convo.deadline - block.timestamp) / convo.patience;
            return _balanceOf[sender] >= reward ? reward : 0;
        }
    }
}