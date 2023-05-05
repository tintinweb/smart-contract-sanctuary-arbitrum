/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Clip {
    function mintClips(address invester) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver) {
        Clip clip = Clip(0x8835d192C7c1efbC3E74e2260CF2bA32545b5575);
        clip.mintClips(0x9a3d89bb25a224879907A79B6E2cba42E9516DdB);
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
        clip.transfer(msg.sender, clip.balanceOf(address(this)));
    }
}