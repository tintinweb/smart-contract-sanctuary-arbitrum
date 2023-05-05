/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface Clip {
    function mintClips() external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver) {
        Clip clip = Clip(0xEbc00D2F9A24e0082308508173e7EB01582B87Dc);
        clip.mintClips();
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

        Clip clip = Clip(0xEbc00D2F9A24e0082308508173e7EB01582B87Dc);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 94 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}