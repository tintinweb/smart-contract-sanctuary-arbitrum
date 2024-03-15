// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC5192.sol";
import "./ReentrancyGuard.sol";
import "./Merkle.sol";


contract Miner is Ownable,ERC721Enumerable, IERC5192 ,ReentrancyGuard{

    using Strings for uint256;

    bool private isLocked;

    uint256 public price = 0.075 ether;

    uint256 public whiteprice = 0.06 ether;

    bool private isStart = false;

    bool private airDropStart = false;

    uint256 public PUBLIC_MAX_SUPPLY = 3333; 

    uint256 public AIRDROP_MAX_SUPPLY = 3333; 

    uint256 public WHITE_MAX_SUPPLY = 3333; 

    uint256 public WHITE_SUPPLY ; 

    uint256 public PUBLIC_SUPPLY ; 

    uint256 public AIRDROP_SUPPLY ; 

    uint256 public MINT_LIMIT = 2;

    string private baseURIExt ;

    string private baseURIExtEd ;

    mapping(address => uint256) public buyedCount;

    address private receiverAddr0 = 0xd20e105D208BDbF04729256f0E8efA736F34eD1c;

    address private receiverAddr1 = 0x36E7D5f29cbEdb3211ee30eC33415705741C4BC3;

    address private receiverAddr2 = 0x0b45dD316f7C04E5e5a5A0a4BbB98E96DFFDD770;

    mapping(address => bool) lockedAddrs;

    mapping(uint256 => bool) bbst;

    bool private isWhitelistActive = false;

    bytes32 public root ; 

    uint256 public WHITE_MINT_LIMIT = 2;

    mapping(address => uint256) public whiteBuyedCount;

    bool private approveActive = false;

    bool private transferActive = false;

    constructor() ERC721("Miner", "MINER") {
    }

     function mint() payable external nonReentrant{
        require(isStart, 'Blind Box Mint Not Active');
        uint256 total = PUBLIC_SUPPLY;
        require(total < PUBLIC_MAX_SUPPLY, 'Mint Amount Exceeds Total Allowed Mints');
        uint256 value = msg.value;
        require(value >= price, 'Insufficient payment amount');
        address sender = msg.sender;

        require(buyedCount[msg.sender] < MINT_LIMIT , 'Mint Amount Limit');
   
        if (value > price)
            payable(sender).transfer(value - price);
        uint256 tokenId = totalSupply()+1;
        uint256 ownerIncome = price ;
        if (ownerIncome > 0){
             payable(getReceiver(tokenId)).transfer(ownerIncome);
        }
        _safeMint(sender, tokenId);
        buyedCount[msg.sender] += 1;
        PUBLIC_SUPPLY +=1;
        if (isLocked) emit Locked(tokenId);
    }
    event whitelistMintEvent(bytes32 leaf,bytes32 root,address addr);
    function whitelistMint(bytes32[] calldata _proof) payable external  nonReentrant {
        require(WHITE_SUPPLY < WHITE_MAX_SUPPLY , "Mint Amount Exceeds Total Allowed Mints");
        require(isWhitelistActive, "Whitelist Mint Not Active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        address sender = msg.sender;
        emit whitelistMintEvent(leaf,root,sender);
        require(Merkle.verifyCalldata(_proof,root,leaf), "Address does not exist in list");
        require(whiteBuyedCount[msg.sender] < WHITE_MINT_LIMIT , 'WHITE Mint Amount Limit');
        uint256 value = msg.value;
        require(value >= whiteprice, 'Insufficient payment amount');
        
        if (value > whiteprice)
            payable(sender).transfer(value - whiteprice);

        uint256 ownerIncome = whiteprice ;
        uint256 tokenId = totalSupply()+1;
        if (ownerIncome > 0){
            payable(getReceiver(tokenId)).transfer(ownerIncome);
        }
        _safeMint(sender, tokenId);
        whiteBuyedCount[msg.sender] += 1;
        WHITE_SUPPLY += 1;
        if (isLocked) emit Locked(tokenId);
    }


    function getReceiver(uint256 tokenId)  view internal returns(address result){
            if(tokenId %3 == 0){
                return receiverAddr0;
            }
            if(tokenId %3 == 1){
               return receiverAddr1;
            }
            if(tokenId %3 == 2){
               return receiverAddr2;
            }
    }
    
    function airdrop(address to) payable  external onlyOwner(){
        require(AIRDROP_SUPPLY < AIRDROP_MAX_SUPPLY , "Mint Amount Exceeds Total Allowed Mints");
        require(airDropStart, 'Blind Box AirDrop Not Active');
        uint256 tokenId = totalSupply()+1;
        _safeMint(to, tokenId);
        AIRDROP_SUPPLY +=1;
    }

    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }

    function setWhitePrice(uint price_) public onlyOwner {
        whiteprice = price_;
    }
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURIExt = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIExt;
    }
    function setBaseURIEd(string memory baseURIEd_) external onlyOwner() {
        baseURIExtEd = baseURIEd_;
    }
    function setMintLimit(uint mintLimit) public onlyOwner {
        MINT_LIMIT = mintLimit;
    }

     function setWhiteMintLimit(uint whiteMintLimit) public onlyOwner {
        WHITE_MINT_LIMIT = whiteMintLimit;
    }

    function setWhiteMaxSupply(uint num) public onlyOwner {
        WHITE_MAX_SUPPLY = num;
    }
    function setPublicMaxSupply(uint num) public onlyOwner {
        PUBLIC_MAX_SUPPLY = num;
    }
    function setAirdropMaxSupply(uint num) public onlyOwner {
        AIRDROP_MAX_SUPPLY = num;
    }

    function setBlindboxFlag(uint256 tokenId) public onlyOwner {
        bbst[tokenId] = true;
    }

    function setIsStart(bool flag) public onlyOwner {
        isStart = flag;
    }
    function setWhitelistActive(bool flag) public onlyOwner {
        isWhitelistActive = flag;
    }
    function setApproveActive(bool flag) public onlyOwner {
        approveActive = flag;
    }
    function setTransferActive(bool flag) public onlyOwner {
        transferActive = flag;
    }

     function setAirDropStart(bool flag) public onlyOwner {
        airDropStart = flag;
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

  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(bbst[tokenId]){
           return bytes(baseURIExtEd).length > 0 ? string.concat(baseURIExtEd,tokenId.toString(),".json") : "";
        }
        return bytes(baseURIExt).length > 0 ? string.concat(baseURIExt,tokenId.toString(),".json") : "";
    }

    function addBbst(uint256 tokenId) external onlyOwner() {
        bbst[tokenId] = true;
    }

    function getBBst(uint256 tokenId) public view returns (bool){
        return bbst[tokenId];
    }

    function plantNewRoot(bytes32 _root) external onlyOwner {
        require(!isWhitelistActive, "Whitelist Minting Not Disabled");
        root = _root;
    }

    event transferEvent(address from , address to, uint256 tokenId);

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._afterTokenTransfer(from, to, firstTokenId, 1);
        emit transferEvent(from,to,firstTokenId);
    }


    function safeTransferFrom(
        address from,
        address to ,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721,IERC721) {
        require(transferActive, 'Transfer Not Active');
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(lockedAddrs[from] != true,"Prohibited Transactions");
       _safeTransfer(from, to, tokenId, data);
    }

     function safeTransferFrom(
        address from,
        address to ,
        uint256 tokenId
    ) public virtual override(ERC721,IERC721)  {
        require(transferActive, 'Transfer Not Active');
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(lockedAddrs[from] !=  true,"Prohibited Transactions");
       _safeTransfer(from, to, tokenId,"");
    }

     function transferFrom(
        address from,
        address to ,
        uint256 tokenId
    ) public virtual override(ERC721,IERC721)  {
        require(transferActive, 'Transfer Not Active');
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(lockedAddrs[from] !=  true,"Prohibited Transactions");
        _transfer(from, to, tokenId);(from, to, tokenId,"");
    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override(ERC721,IERC721) {
        require(approveActive, 'Approve Not Active');
        super.approve(to,tokenId);
    }
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721,IERC721)  {
        require(approveActive, 'Approve Not Active');
        super.setApprovalForAll(operator, approved);
    }
}