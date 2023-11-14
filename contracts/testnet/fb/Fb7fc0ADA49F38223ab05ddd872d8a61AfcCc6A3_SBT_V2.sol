// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC5192.sol"; 
//https://github.com/Bisonai/sbt-contracts/blob/master/contracts/interfaces/IERC5192.sol
import "./Strings.sol";
import "./Context.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./BitMaps.sol";


contract SBT_V2 is ERC721, Ownable /*, ERC721Enumerable*/{

    using Strings for uint256;

    // BitMaps 
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _isConsumed;

    mapping(uint256 => uint256) session; // Every Session supply
    //mapping(uint256 => uint256) session_supply;
    mapping(uint256 => uint256) session_firstId;
    mapping(uint256 => uint256) session_count;
    mapping(uint256 => string) base_uri;
    
    /*
    *======================================================*
    *====SBT event & mapping by using lock(minimal SBT)====*
    *======================================================*
    */

    // Mapping from token ID to locked status
    mapping(uint256 => bool) _locked;

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @notice currently SBT Contract does not emit Unlocked event
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool) {
        require(ownerOf(tokenId) != address(0));
        return _locked[tokenId];
    }
   
    uint256 public price = 0.0001 ether;

    // merkle tree for using whitelist address verfication 
    bytes32 public merkle_root;

     /*
    *================================*
    *====Switch setting & modifer====*
    *================================*
    */
    uint256 public total_session;
    uint256 public cur_session_id = 1;

    uint256 immutable ADMIN_SWITCH = 1;
    uint256 immutable AIRDROP_SWITCH = 2;
    uint256 immutable WHITELIST_SWITCH = 3;
    uint256 immutable PUBLIC_SWITCH = 4;
    uint256 public cur_switch;

    modifier onlyAdminSwitchOpen() {
        require(cur_switch == ADMIN_SWITCH, "admin switch closed");
        _;
    }

    modifier onlyAirdroopSwitchOpen() {
        require(cur_switch == AIRDROP_SWITCH, "airdrop switch closed");
        _;
    }

    modifier onlyWhitelistSwitchOpen() {
        require(cur_switch == WHITELIST_SWITCH, "whitelist switch closed");
        _;
    }

    modifier onlyPublicSwitchOpen() {
        require(cur_switch == PUBLIC_SWITCH, "public switch closed");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function setBaseURI(
        string memory _base_uri,
        uint256 _session_id
    ) external onlyOwner {
        base_uri[_session_id] = _base_uri;
    }

    // Switch = 1
    function adminMint(
        address _to,
        uint256 _tokenId
    ) external onlyAdminSwitchOpen onlyOwner {
        _SBT_mint(_to, _tokenId);
        Mint_countSessionNo(1, cur_session_id);
    }

    // Switch = 2
    function airdropMint(
        address[] calldata _to,
        uint256[] calldata _tokenId
    ) external onlyAirdroopSwitchOpen onlyOwner {
        uint256 len = _to.length;
        require(len == _tokenId.length);

        for (uint256 i = 0; i < len; ) {
            _SBT_mint(_to[i], _tokenId[i]);
            ++i;
        }
        Mint_countSessionNo(1, cur_session_id);
    }

   // WhiteListMint stage which WHITELIST_SWITCH = 3
    function whitelistMint(
        uint256 _tokenId,
        bytes32[] calldata proof
    ) external payable onlyWhitelistSwitchOpen {
        address _account = msg.sender;

        // When setup leaf from JS, need to packed as [address, cur_session_id] to generate the root
        bytes32 leaf = keccak256(abi.encodePacked(_account, cur_session_id));

        // One address only redeem once at every session of WhiteList Regeristion and mint
        require(!_isConsumed.get(uint256(leaf)), "You have already redeemed the whitelist rights at this season! (consumed)");
        _isConsumed.set(uint256(leaf));

        // Merkle Proof
        require(MerkleProof.verify(proof, merkle_root, leaf), "Invalid proof");

        // Send equivalent Ethereum to contract 
        require(msg.value == price, "Please enter the enough ethereum to mint! (no enough ether)");
        _SBT_mint(_account, _tokenId);
        Mint_countSessionNo(1, cur_session_id);
    }

    // Switch = 4
    function publictMint(uint256 _tokenId) external payable onlyPublicSwitchOpen {
        require(_ownerOf(_tokenId) == address(0),"ERROR_PMINT_1:");
        require(msg.value == price, "Please enter the enough ethereum to mint! (not enough ether)");
        _SBT_mint(msg.sender, _tokenId);
        Mint_countSessionNo(1, cur_session_id);
    }

    // Internal calling _safemint function from 1-4 Mint
    function _SBT_mint(
        address _to, 
        uint256 _tokenId
        ) internal {
        uint256 sessionMaxId = session[cur_session_id] + session_firstId[cur_session_id] - 1;
        require(_ownerOf(_tokenId) == address(0),"MNT01");
        require(_locked[_tokenId] != true, "MNT02");
        require(_tokenId <= sessionMaxId,"ERROR_MINT_MAX: PLease Select other token!");
        require(session_firstId[cur_session_id] <= _tokenId, "ERROR_MINT_MIN: Please Select other token!");
        
        _locked[_tokenId] = true;
        emit Locked(_tokenId);
        
        _safeMint(_to, _tokenId);
    }


    function Set_countSessionNo(
        uint256 _count, 
        uint256 _session_id
        ) external onlyOwner{
        session_count[_session_id] = _count;
    }

    function Mint_countSessionNo(
        uint256 _count, 
        uint256 _session_id
        )private{
        session_count[_session_id] += _count; 
    }

    function countSessonNo(
        uint256 _session_id
        )external view returns (uint256){
        return session_count[_session_id];
    }

    function setSession(
        uint256 _session_id,
        uint256 _amount
    ) external onlyOwner {
        session[_session_id] = _session_id == 1
            ? _amount
            : session[_session_id - 1] + _amount;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        //if (!_exists(tokenId)) revert ();
        if(ownerOf(tokenId)==address(0)) revert();

        uint256 i = 1;
        for ( ; i < total_session; ) {
            if (tokenId + 1 > session[i]) {
                ++i;
            } else {
                break;
            }
        }
        string memory baseURI = base_uri[i];

        return
            bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
            : "";
           
                
    }

    function setSessionFirstID(
        uint256 _session_first_id, 
        uint256 _session_id
        )external onlyOwner{
        session_firstId[_session_id] = _session_first_id; 
    }

   // Switch of based on what session(season) we are
    function setCurSession(
        uint256 _cur_session_id
        ) external onlyOwner {
        cur_session_id = _cur_session_id;
    }

    // Switch of based on what mint stage we are
    function setCurSwitch(
        uint256 _cur_switch
        ) external onlyOwner {
        cur_switch = _cur_switch;
    }

    // Swicth of Session Numbers
    function setTotalSession(
        uint256 _total_session
        )external onlyOwner {
        total_session = _total_session;
    }

        receive() external payable {}

    function withdraw(
        uint _amount
        ) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /*
    *====================================================*
    *====Inspired by /sbt-contracts/contracts/SBT.sol====*
    *====================================================*
    */

    

    function burn(
        uint256 tokenId
        ) public {
        require(msg.sender == ownerOf(tokenId), "BRN01");
        _burn(tokenId);
    }

    modifier IsTransferAllowed(
        uint256 tokenId) {
        require(!_locked[tokenId]);
        _;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721/*,IERC721*/) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721/*,IERC721*/) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /*function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721/*, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }*/

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721/*, ERC721Enumerable*/)
        returns (bool)
    {
        return _interfaceId == type(IERC5192).interfaceId || super.supportsInterface(_interfaceId);
    }

}