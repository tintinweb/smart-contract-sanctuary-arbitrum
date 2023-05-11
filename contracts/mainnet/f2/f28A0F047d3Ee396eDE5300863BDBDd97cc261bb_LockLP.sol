/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract LockLP {
    //ERC721 nft = ERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    struct LOCK{
        address NFT_address;
        address nft_owner;
        uint tokenId;
        uint lock_time;
        bool flags;
    }
    mapping (address => mapping(uint =>LOCK)) public Lock; 
    mapping (address => uint ) public NftCount;
    uint public LockCount;

    bool is_me_function = false;
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        if(interfaceID == 0xffffffff)return false;
        else return is_me_function;
    }

    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) public  returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function Input_NFT_to_me(address nft_address,uint tokenId,uint lock_day)public{
        is_me_function = true;
        ERC721 nft = ERC721(nft_address);
        nft.safeTransferFrom(msg.sender,address(this),tokenId);
        LockCount++;
        NftCount[msg.sender]++;
        LOCK memory l;
        l.NFT_address = nft_address;
        l.nft_owner = msg.sender;
        l.tokenId = tokenId;
        l.lock_time = (block.timestamp/86400)*86400 + lock_day * 86400;
        l.flags = true;
        Lock[msg.sender][NftCount[msg.sender]]=l;
    }
    function Take_Out_of_NFT(uint lock_index)public {
        require(Lock[msg.sender][lock_index].nft_owner ==msg.sender );
        require(block.timestamp >= Lock[msg.sender][lock_index].lock_time);
        require(Lock[msg.sender][lock_index].flags == true);
        ERC721 nft = ERC721(Lock[msg.sender][lock_index].NFT_address);
        nft.safeTransferFrom(address(this), msg.sender, Lock[msg.sender][lock_index].tokenId ) ;

        
        Lock[msg.sender][NftCount[msg.sender]].flags = false;
    }
    
}