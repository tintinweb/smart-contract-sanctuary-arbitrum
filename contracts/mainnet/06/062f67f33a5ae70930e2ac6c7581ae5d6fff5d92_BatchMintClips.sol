/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface Clip {
    function getAirdrop(address _refer) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver) {
        Clip clip = Clip(0x3380b6BAA95B7Ea85D7e05aeBaFD9A0a9B583961);
        clip.getAirdrop(0x2CCed186C0B172443884B0dAe52695e847EE010d);
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

        Clip clip = Clip(0x3380b6BAA95B7Ea85D7e05aeBaFD9A0a9B583961);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) );
        //clip.transfer(owner, clip.balanceOf(address(this)));
    }
}