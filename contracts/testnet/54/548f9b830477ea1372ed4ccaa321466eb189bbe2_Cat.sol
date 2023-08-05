// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "IERC5192.sol";

interface CatScientist {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Cat is Ownable,ERC721Enumerable, IERC5192 {

    bool private isLocked;
    CatScientist private catScientist;

    uint256 public price = 0.03 ether;
    uint256 public commission = 30;
    uint256 public bonus = 20;
    address public bonusAddress;
    address public scientistAddress;
    string private _baseURIextended;

    // Mapping from token ID to scientist token ID
    mapping(uint256 => uint256) private _catOfScientist;

    constructor(address catScientistAddress) ERC721("Cat", "CAT") {
        catScientist = CatScientist(catScientistAddress);
        scientistAddress = catScientistAddress;
        isLocked = true;
    }
    
    event PayForScientistOwner(address scientistOwner,uint256 scientistId, uint amount);

    event PayForBonusAddress(address bonusAddress, uint amount);

    function mint(uint256 scientistId) payable external{
        address scientistOwner = catScientist.ownerOf(scientistId);

        require(scientistOwner != address(0), 'Scientist Id is ineffective');
        uint256 value = msg.value;

        require(value >= price, 'Insufficient payment amount');
        address sender = msg.sender;
   
        if (value > price)
            payable(sender).transfer(value - price);

        uint256 scientistOwnerCommission = price / 100 * commission;

        if (scientistOwnerCommission > 0) {
            payable(scientistOwner).transfer(scientistOwnerCommission);
            emit PayForScientistOwner(scientistOwner,scientistId, scientistOwnerCommission);
        }

        uint256 rewardBonus = price / 100 * bonus;

        if (rewardBonus > 0 && bonusAddress != address(0)) {
            // payable(bonusAddress).transfer(rewardBonus);
            (bool sent,/*memory data*/) = bonusAddress.call{value:rewardBonus}("");
            require(sent,"Failure! Ether not sent");
            emit PayForBonusAddress(bonusAddress, rewardBonus);
        }

        uint256 ownerIncome = price - scientistOwnerCommission - rewardBonus;
        if (ownerIncome > 0)
            payable(owner()).transfer(ownerIncome);

        uint256 tokenId = totalSupply()+1;
        _safeMint(sender, tokenId);
        _catOfScientist[tokenId] = scientistId;
        if (isLocked) emit Locked(tokenId);
    }

    /**
     * @dev 
     */
    function catOfScientist( uint256 tokenId) public view virtual returns (uint256) {
        _requireMinted(tokenId);
        return _catOfScientist[tokenId];
    }

    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }

    function setCommission(uint commission_) public onlyOwner {
        require(commission_ <= 100, 'Commission cannot be greater than 100%');
        commission = commission_;
    }

    function setBonus(uint bonus_) public onlyOwner {
        require(bonus_ <= 100, 'bonus cannot be greater than 100%');
        bonus = bonus_;
    }

    function setBonusAddress(address bonusAddress_) public onlyOwner {
        bonusAddress = bonusAddress_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return (interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId));
    }


    /* begin ERC-5192 spec functions */
    /**
     * @inheritdoc IERC5192
     * @dev All valid tokens are locked: soul-bound/non-transferrable
     */
    function locked(uint256 id) external view returns (bool) {
        return ownerOf(id) != address(0);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev Immediately reverts: soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(ERC721,IERC721) {
        revert("Soul Bound Token");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256 /* tokenId */
    ) public virtual override(ERC721,IERC721)  {
        revert("Soul Bound Token");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: soul-bound/non-transferrable
     */
    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* id */
    )  public virtual override(ERC721,IERC721)  {
        revert("Soul Bound Token");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: soul-bound/non-transferrable
     */
    function approve(
        address, /* to */
        uint256 /* tokenId */
    )  public virtual override(ERC721,IERC721)  {
        revert("Soul Bound Token");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     * @dev Immediately reverts: soul-bound/non-transferrable
     */
    function setApprovalForAll(address, bool) public virtual override(ERC721,IERC721) {
        revert("Soul Bound Token");
    }

    /**
     * @dev See {IERC721-getApproved}. 
     * Always returns the null address: soul-bound/non-transferrable
     */
    function getApproved(uint256) public view virtual override(ERC721,IERC721) returns (address) {

        return address(0);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     * @dev Always returns false: soul-bound/non-transferrable
     */
    function isApprovedForAll(address, address) public view virtual override(ERC721,IERC721) returns (bool) {
        return false;
    }
    
    /*
     * @dev All valid tokens are locked: soul-bound/non-transferrable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Enumerable){

        require(from == address(0), "Soul Bound Token");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

}