/**
 *Submitted for verification at Arbiscan.io on 2024-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IErc20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract HelixDaoPayout {
    address public owner;
    mapping(string=>address) public receivers;

    event Payout(address sender, address receiver, address token, uint256 amount, string reason);

    constructor() {
        owner = msg.sender;
    }

    function payout(address token, uint256 amount, string calldata receiver, string calldata reason) external payable {
        address receiveAddress = receivers[receiver];
        require(receiveAddress != address(0), "invalid receiver");
        if (token == address(0)) {
            require(msg.value == amount, "invalid amount");
            (bool success,) = payable(receiveAddress).call{value: amount}("");
            require(success, "helix:transfer native token failed");
        } else {
            IErc20(token).transferFrom(msg.sender, receiveAddress, amount);
        }
        emit Payout(msg.sender, receiveAddress, token, amount, reason);
    }

    function setReceiver(string calldata _name, address _receiver) external {
        require(msg.sender == owner, "invalid owner");
        receivers[_name] = _receiver;
    }

    function rescue(address token, uint256 amount) external {
        require(msg.sender == owner, "invalid caller");
        if (token == address(0)) {
            (bool success,) =  payable(msg.sender).call{value: amount}("");
            require(success, "helix:transfer native token failed");
        } else {
            IErc20(token).transfer(msg.sender, amount);
        }
    }
}