/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NFTInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address to) external returns (uint256);
}

interface MarioInterface {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MarioAirdrop {
    address public admin;
    address public nftAddress;
    address public marioAddress;
    uint256 public marioReward;

    constructor(address _admin, address _nftAddress, address _marioAddress, uint256 _marioReward) {
        admin = _admin;
        nftAddress = _nftAddress;
        marioAddress = _marioAddress;
        marioReward = _marioReward;
    }

    function setMarioReward(uint256 _marioReward) external onlyAdmin {
        marioReward = _marioReward;
    }

    function mintNFT() external {
        NFTInterface nftContract = NFTInterface(nftAddress);
        MarioInterface marioContract = MarioInterface(marioAddress);
        uint256 tokenId = nftContract.mint(address(this));
        address owner = nftContract.ownerOf(tokenId);
        if (marioContract.transfer(owner, marioReward)) {
            emit Airdrop(owner, marioReward);
        }
    }

    function withdrawETH(address payable _to, uint256 _amount) external onlyAdmin {
        require(_to != address(0), "Invalid address");
        require(_amount > 0 && _amount <= address(this).balance, "Invalid amount");
        _to.transfer(_amount);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized");
        _;
    }

    event Airdrop(address indexed recipient, uint256 amount);
}