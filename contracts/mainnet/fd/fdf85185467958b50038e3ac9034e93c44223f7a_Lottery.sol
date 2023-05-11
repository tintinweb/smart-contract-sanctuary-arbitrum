/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// LabraLOL Lottery

contract Lottery {
    address public manager;
    IERC20 public budToken;
    address[] public players;

    constructor() {
        manager = 0xD956554DD19296C82977CD0484af1e2300AaC5de;
        budToken = IERC20(0x7bB3D78fAB159137e535157dF2Dc59f22aDaA1a9);
    }

function enter(uint256 amount) public {
    require(
        budToken.transferFrom(msg.sender, address(this), amount),
        "Token transfer failed."
    );
    players.push(msg.sender);
}

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == manager, "Only manager can pick the winner.");
        require(players.length > 0, "No players joined the lottery.");

        uint256 index = random() % players.length;
        address winner = players[index];

        uint256 contractBalance = budToken.balanceOf(address(this));
        require(
            budToken.transfer(winner, contractBalance),
            "Token transfer failed."
        );

        players = new address[](0);
    }

    function pot() public view returns (uint256) {
        return budToken.balanceOf(address(this));
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}