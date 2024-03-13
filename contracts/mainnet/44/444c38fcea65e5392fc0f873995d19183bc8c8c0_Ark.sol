// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC5192.sol";
import "./Merkle.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
contract Ark is Ownable,ERC721Enumerable, IERC5192 ,ReentrancyGuard {

    using Strings for uint256;

    bool private isLocked;

    bool private isStart = false;

    bool private isWhitelistActive = false;

    uint256 public price = 0.03 ether;

    uint256 public MAX_SUPPLY = 3333;

    uint256 public MINT_LIMIT = 1;

    uint256 public WHITE_MINT_LIMIT = 1;

    bytes32 public root ; 

    string private baseURIExt ;

    mapping(address => uint256) public buyedCount;

    mapping(address => uint256) public whiteBuyedCount;

    address private receiverAddr0 = 0xd20e105D208BDbF04729256f0E8efA736F34eD1c;

    address private receiverAddr1 = 0x36E7D5f29cbEdb3211ee30eC33415705741C4BC3;

    address private receiverAddr2 = 0x0b45dD316f7C04E5e5a5A0a4BbB98E96DFFDD770;

    mapping(address => bool) lockedAddrs;

    constructor() ERC721("Ark", "ARK") {
        isLocked = true;
    }

    function mint() payable external nonReentrant{
        require(isStart, 'Mint Not Active');
        uint256 total = totalSupply();
        require(total < MAX_SUPPLY, 'Mint Amount Exceeds Total Allowed Mints');
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

    event whitelistMintEvent(bytes32 leaf,bytes32 root,address addr);

    function whitelistMint(bytes32[] calldata _proof) payable external  nonReentrant {
        require(totalSupply() < MAX_SUPPLY , "Mint Amount Exceeds Total Allowed Mints");
        require(isWhitelistActive, "Whitelist Mint Not Active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        address sender = msg.sender;
        emit whitelistMintEvent(leaf,root,sender);
        require(Merkle.verifyCalldata(_proof,root,leaf), "Address does not exist in list");
        require(whiteBuyedCount[msg.sender] < WHITE_MINT_LIMIT , 'WHITE Mint Amount Limit');
        uint256 value = msg.value;
        require(value >= price, 'Insufficient payment amount');
        
        if (value > price)
            payable(sender).transfer(value - price);

        uint256 ownerIncome = price ;
        uint256 tokenId = totalSupply()+1;
        if (ownerIncome > 0){
            payable(getReceiver(tokenId)).transfer(ownerIncome);
        }
       
        _safeMint(sender, tokenId);
        whiteBuyedCount[msg.sender] += 1;
        if (isLocked) emit Locked(tokenId);
    }

    function removeLock(address _addr) public onlyOwner {
        lockedAddrs[_addr]=false;
    }
    function addLock(address _addr) public onlyOwner {
        require(_addr!=msg.sender);
        lockedAddrs[_addr]=true;
    }
    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }

    function setIsStart(bool flag) public onlyOwner {
        isStart = flag;
    }
     function setIsWhitelistActive(bool flag) public onlyOwner {
        isWhitelistActive = flag;
    }

     function setMintLimit(uint mintLimit) public onlyOwner {
        MINT_LIMIT = mintLimit;
    }

     function setWhiteMintLimit(uint whiteMintLimit) public onlyOwner {
        WHITE_MINT_LIMIT = whiteMintLimit;
    }

      function plantNewRoot(bytes32 _root) external onlyOwner {
        require(!isWhitelistActive, "Whitelist Minting Not Disabled");
        root = _root;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed.");
    }

    function getBalance()  public onlyOwner view virtual returns (uint256) {
        return address(this).balance;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return (interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function setReceiver0(address addr) public onlyOwner {
        receiverAddr0 = addr;
    }
    function setReceiver1(address addr) public onlyOwner {
        receiverAddr1 = addr;
    }
    function setReceiver2(address addr) public onlyOwner {
        receiverAddr2 = addr;
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

        return bytes(baseURIExt).length > 0 ? string.concat(baseURIExt,tokenId.toString(),".json") : "";
    }


     function setBaseUriExt(string memory _baseURIExt) public onlyOwner {
        baseURIExt = _baseURIExt;
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(lockedAddrs[from] != true,"Prohibited Transactions");
       _safeTransfer(from, to, tokenId, data);
    }

     function safeTransferFrom(
        address from,
        address to ,
        uint256 tokenId
    ) public virtual override(ERC721,IERC721)  {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(lockedAddrs[from] !=  true,"Prohibited Transactions");
       _safeTransfer(from, to, tokenId,"");
    }

     function transferFrom(
        address from,
        address to ,
        uint256 tokenId
    ) public virtual override(ERC721,IERC721)  {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(lockedAddrs[from] !=  true,"Prohibited Transactions");
       _transfer(from, to, tokenId);(from, to, tokenId,"");
    }
}