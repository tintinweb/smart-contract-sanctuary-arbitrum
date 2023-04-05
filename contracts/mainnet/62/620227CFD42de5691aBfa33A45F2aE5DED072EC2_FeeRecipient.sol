//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

interface INFT {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract FeeRecipient {

    address public dev0 = 0xFF96f3Be084178F1E2b27dbaA8F849326b6F6C4E;
    address public dev1 = 0x82D55e9d2307a6E7F7318963661779eA8Dce87bf;
    address public dev2 = 0xe78Cd640646674D4fDFd156339190e2b96FB8Cc4;
    address public dev3 = 0x70fDFC034f2AB7Ab8E279f1A30d4Af2905F8C06D;

    address public contractBNFT = 0x5Dc5695Cc991f277f47EcEF73f5A016d8a938B94;
    IERC20 public constant artemis = IERC20(0xCe4bba29C0d4407C38eA549c4f22b3e426E58bf7);
    address[] private path;

    function trigger() external {
        require(msg.sender == dev0 || msg.sender == dev1 || msg.sender == dev2 || msg.sender == dev3, "Not owner");

        uint256 balance = artemis.balanceOf(address(this));
        if (balance <= 100) {
            return;
        }

        // split into fourths
        uint dev = balance / 16;
        artemis.transfer(dev0, dev);
        artemis.transfer(dev1, dev);
        artemis.transfer(dev2, dev);
        artemis.transfer(dev3, dev);

        distributeBalance();
    }

    function distributeBalance() internal {
        INFT nftContract = INFT(contractBNFT);
        uint256 totalSupply = nftContract.totalSupply();
        if (totalSupply == 0) {
            return;
        }

        uint256 balance = artemis.balanceOf(address(this));
        uint256 balancePerNFT = balance / totalSupply;

        for (uint256 i = 0; i < totalSupply; i++) {
            address nftHolder = nftContract.ownerOf(i);
            artemis.transfer(nftHolder, balancePerNFT);
        }
    }

    function withdraw(address token) external {
        require(
            msg.sender == dev0, 'Only Dev'
        );
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setDev0(address newDev0) external {
        require(msg.sender == dev0, 'Only Dev');
        dev0 = newDev0;
    }

    function setDev1(address newDev1) external {
        require(msg.sender == dev1, 'Only Dev');
        dev1 = newDev1;
    }

    function setDev2(address newDev2) external {
        require(msg.sender == dev2, 'Only Dev');
        dev2 = newDev2;
    }

    function setDev3(address newDev3) external {
        require(msg.sender == dev3, 'Only Dev');
        dev3 = newDev3;
    }

}