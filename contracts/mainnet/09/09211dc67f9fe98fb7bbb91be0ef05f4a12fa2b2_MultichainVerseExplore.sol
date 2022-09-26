// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AnyCallV6App.sol";
import "./ERC721EnumerableUpgradeable.sol";

contract MultichainVerseExplore is ERC721EnumerableUpgradeable, AnyCallApp {
    function initialize(address anyCallProxy, address admin) public initializer {
        __ERC721_init_unchained("MultichainVerse Explore", "MVE");
        __initiateAnyCallApp(anyCallProxy, 2);
        setAdmin(admin);
        MaxTokenIdId = 1000000;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return "ipfs://QmRsQzm69ipBMeEYBAbXD2tSTiKb1Rh8CDAnriRM8zEXgX";
    }

    mapping(uint256 => uint256) public generationOf;

    uint256 public nextTokenId;
    address public minter;

    uint256 public MaxTokenIdId;

    uint256 public swapoutSeq = 0;

    event Mint(address to, uint256 tokenId);
    event SetMinter(address minter);
    event Outbound(uint256 tokenId, address receiver, uint256 toChainID);
    event Inbound(uint256 tokenId, address receiver, uint256 fromChainID);

    function setMinter(address minter_) public onlyAdmin {
        minter = minter_;
        emit SetMinter(minter);
    }

    function mint(address to) public {
        require(msg.sender == minter);
        require(nextTokenId < MaxTokenIdId);
        uint256 tokenId = block.chainid * MaxTokenIdId + nextTokenId;
        _mint(to, tokenId);
        generationOf[tokenId] = 1;
        nextTokenId += 1;
        emit Mint(to, tokenId);
    }

    function Swapout_no_fallback(
        uint256 tokenId,
        address receiver,
        uint256 destChainID
    ) external payable returns (uint256) {
        bytes memory extraMsg = abi.encode(generationOf[tokenId]);
        _burn(tokenId);
        swapoutSeq++;
        bytes memory data = abi.encode(
            tokenId,
            msg.sender,
            receiver,
            swapoutSeq,
            extraMsg
        );
        _anyCall(peer[destChainID], data, address(0), destChainID);
        emit Outbound(tokenId, receiver, destChainID);
        return swapoutSeq;
    }

    function _anyExecute(uint256 fromChainID, bytes calldata data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (uint256 tokenId, , address receiver, , bytes memory extraMsg) = abi
            .decode(data, (uint256, address, address, uint256, bytes));
        uint256 generation = abi.decode(extraMsg, (uint256));
        _mint(receiver, tokenId);
        generationOf[tokenId] = generation + 1;
        emit Inbound(tokenId, receiver, fromChainID);
    }
}