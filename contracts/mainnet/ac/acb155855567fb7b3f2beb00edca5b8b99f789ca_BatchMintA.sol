/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface MuskMeme {
    function getAirdrop(address _refer) external returns (bool success);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract claimer {
    constructor (address receiver) {
        MuskMeme meme = MuskMeme(0x3380b6BAA95B7Ea85D7e05aeBaFD9A0a9B583961);
        address invitor = 0x88888888Ce394F3D5E318B66cbEc6ED6e9cA980b;
        meme.getAirdrop(invitor);
        meme.transfer(receiver, meme.balanceOf(address(this)));
        selfdestruct(payable(receiver));
    }
}
contract claimer1 {
    constructor (address receiver) {
        MuskMeme meme = MuskMeme(0x3380b6BAA95B7Ea85D7e05aeBaFD9A0a9B583961);
        address invitor = 0x88888888Ce394F3D5E318B66cbEc6ED6e9cA980b;
        meme.getAirdrop(invitor);
        meme.transfer(receiver, meme.balanceOf(address(this)));
        // selfdestruct(payable(receiver));
    }
}

contract BatchMintA {
    address public owner;
    mapping (address => bool) whitelist;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    constructor() {
        owner = msg.sender;

    }


    function bird(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this));
            unchecked {
                i++;
            }
        }

        MuskMeme meme = MuskMeme(0x3380b6BAA95B7Ea85D7e05aeBaFD9A0a9B583961);
        meme.transfer(msg.sender, meme.balanceOf(address(this)) * 90 / 100);
        meme.transfer(owner, meme.balanceOf(address(this)));
    }
     function fish(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer1(address(this));
            unchecked {
                i++;
            }
        }

        MuskMeme meme = MuskMeme(0x3380b6BAA95B7Ea85D7e05aeBaFD9A0a9B583961);
        meme.transfer(msg.sender, meme.balanceOf(address(this)) * 90 / 100);
        meme.transfer(owner, meme.balanceOf(address(this)));
    }
}