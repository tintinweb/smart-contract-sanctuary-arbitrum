// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface Clip {
    function mintClips() external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BatchMintClips {
    address public owner;
    bool public mintStart = true;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _address) public onlyOwner {
        owner = _address;
    }

    function changeMintStart(bool _mintStart) public onlyOwner {
        mintStart = _mintStart;
    }

    function batchMint(uint count) public {
        require(mintStart == true, "mint has stopped");
        for (uint i = 0; i < count; i++) {
            new claimer(msg.sender);
        }
    }
}

contract claimer {
    address clipAddress = 0xFAF95b3eec710f19DDd7b96f259e97E28e6A91d5; // Arbitrum Goerli Testnet
    constructor (address receiver) {
        Clip clip = Clip(clipAddress);
        clip.mintClips();
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}