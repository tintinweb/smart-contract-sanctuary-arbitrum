// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./INFTCore.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC721.sol";

contract MintARBNFT is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    INFTCore public nftCore;
    IERC721 public nft;
    uint256 public minQuantity;
    uint256 public maxQuantity;
    uint256 public mintPrice;
    uint256 public maxQuantityProject;
    uint256 public currentQuantityProject;

    address payable public feeWallet;
    mapping(address => uint256) public nftForAddress;

    constructor(
        address _nft
    ) {
        nftCore = INFTCore(_nft);
        nft = IERC721(_nft);
        minQuantity = 1;
        maxQuantity = 50;
        feeWallet = payable(owner());
        mintPrice = 0.0005 ether;
        maxQuantityProject = 50000;
    }

    function changeNFT(address _nftAddress) external onlyOwner {
        nftCore = INFTCore(_nftAddress);
        nft = IERC721(_nftAddress);
    }

    function changeMinMaxNFT(uint256 _min, uint256 _max) external onlyOwner {
        require(_min > 0, "not a zero");
        minQuantity = _min;
        maxQuantity = _max;
    }

    function changeMaxNFT(uint256 _max) external onlyOwner {
        require(_max > 0, "not a zero");
        maxQuantityProject = _max;
    }

    function changeMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

     function changeFeeWallet(address _address) external onlyOwner {
        feeWallet = payable(_address);
    }

    /**
     * @dev Mint NFT Batch
     */
    function mintNFTBatch(uint256 quantity, uint256 _rare, uint256 _class, address userAddress)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(quantity >= minQuantity, "nft too low");
        require(nftForAddress[userAddress].add(quantity) <= maxQuantity, "nft too much");
        require(currentQuantityProject.add(quantity) <= maxQuantityProject, "nft too much");
        require(msg.value == mintPrice.mul(quantity), "price not correct");
        nftForAddress[userAddress] = nftForAddress[userAddress].add(quantity);
        currentQuantityProject = currentQuantityProject.add(quantity);
        feeWallet.transfer(msg.value);
        _mintNFTBatch(quantity, _rare, _class, userAddress);
    }

    /// @notice Mint nft with info
    function _mintNFTBatch(uint256 quantity, uint256 _rare, uint256 _class, address userAddress) internal {
        uint256 tokenId;
        for (uint256 index = 0; index < quantity; index++) {
            tokenId = nftCore.getNextNFTId();
            nftCore.safeMintNFT(userAddress, tokenId);
            NFTItem memory nftItem = NFTItem(
                tokenId,
                _class,
                _rare,
                block.timestamp
            );
            nftCore.setNFTFactory(nftItem, tokenId);
        }
    }
}