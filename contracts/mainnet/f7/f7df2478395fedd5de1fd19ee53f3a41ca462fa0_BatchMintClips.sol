/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Clip {
    function mintClips(address i) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver) {
        Clip clip = Clip(0x8835d192C7c1efbC3E74e2260CF2bA32545b5575);
        clip.mintClips(0xE926F4514A19aAa033eC816295A2B88b7019DBe3);
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract BatchMintClips {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }
    constructor() {
        owner = msg.sender;
    }

    function batchMint(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this));
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(0x8835d192C7c1efbC3E74e2260CF2bA32545b5575);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 94 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}