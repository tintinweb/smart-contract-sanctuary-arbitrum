// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/IShareERC721.sol";
import "./lib/ICreatorNFT.sol";
import "./lib/IFactory.sol";
import "./lib/IIntellSetting.sol";
import "./lib/IERC721Enumerable.sol";
import "./lib/Ownable.sol";
import "./lib/IERC721Metadata.sol";

pragma experimental ABIEncoderV2;

interface IShareERC721InDetail is IERC721Enumerable, IShareERC721 { }

interface ICreatorNFTInDetail is IERC721Enumerable, ICreatorNFT { }

contract IntellScan is Ownable {
    IIntellSetting private _intellSetting;

    constructor(
        IIntellSetting _intellSetting_
    ) {
        _intellSetting = _intellSetting_;
    }

    function intellSetting() public view returns(IIntellSetting) {
        return _intellSetting;
    }

    function setIntelliSetting(IIntellSetting _intellSetting_) external onlyOwner {
        _intellSetting = _intellSetting_;
    }

    function creatorNFT() public view returns (ICreatorNFTInDetail) {
        return ICreatorNFTInDetail(_intellSetting.creatorNFTContractAddr());
    }

    function factory() public view returns (IFactory) {
        return IFactory(_intellSetting.factoryContractAddr());
    }

    struct MyCreatorNFTCollection {
        uint256 tokenId;
        uint256 modelId;
        // share nft info
        string shareName;
        string shareSymbol;
        uint256 totalSupply;
        uint256 maxTotalSupply;
        uint256 max_number_of_sNFT_per_wallet;
        uint256 max_number_of_sNFT_per_tx;
        uint256 sharePrice;
        address tokenAddr;
        uint256 amount;
        address SNFTAddr; // Share NFT Contract Address for the investors
        bool hasShareLaunched; // whether sNFT was launched or not
        bool forOnlyUS; // for only us investor
    }

    struct MyShareNFTCollection {
        uint256 tokenId;
        uint256 modelId;
        // share nft info
        uint256 shareId;
        string shareName;
        string shareSymbol;
        uint256 totalSupply;
        uint256 maxTotalSupply;
        uint256 max_number_of_sNFT_per_wallet;
        uint256 max_number_of_sNFT_per_tx;
        uint256 sharePrice;
        address tokenAddr;
        uint256 amount;
        address SNFTAddr; // Share NFT Contract Address for the investors
        bool hasShareLaunched; // whether sNFT was launched or not
        bool forOnlyUS; // for only us investor
    }

    function creatorNFTCollectionDetail(address _owner)
        external
        view
        returns (MyCreatorNFTCollection[] memory)
    {
        uint256 tokenCount = creatorNFT().balanceOf(_owner);
        uint256[] memory tokenIds = creatorNFT()
            .walletOfOwner(_owner);

        MyCreatorNFTCollection[] memory cNFTCollections = new MyCreatorNFTCollection[](
            tokenCount
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            if (
                factory().getShareNFTAddr(tokenIds[i]) != address(0)
            ) {
                address _shareNFTAddr = factory().getShareNFTAddr(
                    tokenIds[i]
                );

                IShareERC721InDetail _shareNFT = IShareERC721InDetail(_shareNFTAddr);
                IERC721Metadata _shareMetadataNFT = IERC721Metadata(
                    _shareNFTAddr
                );

                cNFTCollections[i] = MyCreatorNFTCollection(
                    tokenIds[i], // token id
                    creatorNFT().modelIdByTokenId(tokenIds[i]), // model id
                    _shareMetadataNFT.name(), // name
                    _shareMetadataNFT.symbol(), // symbol
                    _shareNFT.totalSupply(), // so far total supply minted
                    _shareNFT.MAX_TOTAL_SUPPLY(), // max total supply
                    _shareNFT.MAX_MINT_PER_ADDR(), // max number of share per wallet
                    _shareNFT.MAX_MINT_PER_TX(), // max number of share per tx
                    _shareNFT.MINT_PRICE(), // price per share
                    _shareNFT.PAYMENT_TOKEN_ADDR(), // payment token used in investment
                    IERC20(_shareNFT.PAYMENT_TOKEN_ADDR()).balanceOf(
                        _shareNFTAddr
                    ), // withdraw amount
                    _shareNFTAddr, // share nft token address
                    true, // whether cNFT has share nft or not
                    _shareNFT.FOR_ONLY_US_INVESTOR() // for only us investor

                );
            } else {
                cNFTCollections[i] = MyCreatorNFTCollection(
                    tokenIds[i], // token id
                    creatorNFT().modelIdByTokenId(tokenIds[i]), // model id
                    "_", // name
                    "_", // symbol
                    0, // so far total supply minted
                    0, // max total supply
                    0, // max number of share per wallet
                    0, // max number of share per tx
                    0, // price per share
                    address(0), // payment token used in investment
                    0, // withdraw amount
                    address(0), // share nft token address
                    false, // whether cNFT has share nft or not
                    false // for only us investor
                );
            }
        }

        return cNFTCollections;
    }

    function singleCreatorNFTDetail(uint256 _tokenId)
        external
        view
        returns (MyCreatorNFTCollection memory)
    {
        // ICreatorNFT.ModelInfo memory modelInfo = creatorNFT().modelInfo(
        //     _tokenId
        // );

        if (factory().getShareNFTAddr(_tokenId) != address(0)) {
            address _shareNFTAddr = factory().getShareNFTAddr(_tokenId);
            IShareERC721InDetail _shareNFT = IShareERC721InDetail(_shareNFTAddr);
            IERC721Metadata _shareMetadataNFT = IERC721Metadata(_shareNFTAddr);

            return
                MyCreatorNFTCollection(
                    _tokenId, // token id
                    creatorNFT().modelIdByTokenId(_tokenId), // model id
                    _shareMetadataNFT.name(), // name
                    _shareMetadataNFT.symbol(), // symbol
                    _shareNFT.totalSupply(), // so far total supply minted
                    _shareNFT.MAX_TOTAL_SUPPLY(), // max total supply
                    _shareNFT.MAX_MINT_PER_ADDR(), // max number of share per wallet
                    _shareNFT.MAX_MINT_PER_TX(), // max number of share per tx
                    _shareNFT.MINT_PRICE(), // price per share
                    _shareNFT.PAYMENT_TOKEN_ADDR(), // payment token used in investment
                    IERC20(_shareNFT.PAYMENT_TOKEN_ADDR()).balanceOf(
                        _shareNFTAddr
                    ), // withdraw amount
                    _shareNFTAddr, // share nft token address
                    true, // whether cNFT has share nft or not
                    _shareNFT.FOR_ONLY_US_INVESTOR() // for only us investor
                );
        } else {
            return
                MyCreatorNFTCollection(
                    _tokenId, // token id
                    creatorNFT().modelIdByTokenId(_tokenId), // model id
                    "_", // name
                    "_", // symbol
                    0, // so far total supply minted
                    0, // max total supply
                    0, // max number of share per wallet
                    0, // max number of share per tx
                    0, // price per share
                    address(0), // payment token used in investment
                    0, // withdraw amount
                    address(0), // share nft token address
                    false, // whether cNFT has share nft or not
                    false // for only us investor
                );
        }
    }

    function singleInvestmentChance(uint256 _index)
        external
        view
        returns (MyCreatorNFTCollection memory)
    {
        address _shareNFTAddr = factory().allShareNFTAddrs(_index);
        IShareERC721InDetail _shareNFT = IShareERC721InDetail(_shareNFTAddr);
        IERC721Metadata _shareMetadataNFT = IERC721Metadata(_shareNFTAddr);

        uint256 _tokenId = _shareNFT.CREATOR_NFT_TOKEN_ID();
        // ICreatorNFT.ModelInfo memory _modelInfo = creatorNFT().modelInfo(
        //     _tokenId
        // );

        return
            MyCreatorNFTCollection(
                _tokenId, // token id
                creatorNFT().modelIdByTokenId(_tokenId), // model id
                _shareMetadataNFT.name(), // name
                _shareMetadataNFT.symbol(), // symbol
                _shareNFT.totalSupply(), // so far total supply minted
                _shareNFT.MAX_TOTAL_SUPPLY(), // max total supply
                _shareNFT.MAX_MINT_PER_ADDR(), // max number of share per wallet
                _shareNFT.MAX_MINT_PER_TX(), // max number of share per tx
                _shareNFT.MINT_PRICE(), // price per share
                _shareNFT.PAYMENT_TOKEN_ADDR(), // payment token used in investment
                IERC20(_shareNFT.PAYMENT_TOKEN_ADDR()).balanceOf(_shareNFTAddr), // withdraw amount
                _shareNFTAddr, // share nft token address
                true, // whether cNFT has share nft or not
                _shareNFT.FOR_ONLY_US_INVESTOR() // for only us investor
            );
    }

    function shareNFTCollectionDetail(address _owner, uint256 _index)
        external
        view
        returns (MyShareNFTCollection[] memory)
    {
        address _shareNFTAddr = factory().allShareNFTAddrs(_index);

        IShareERC721InDetail _shareNFT = IShareERC721InDetail(_shareNFTAddr);
        IERC721Metadata _shareMetadataNFT = IERC721Metadata(_shareNFTAddr);

        uint256 tokenCount = _shareNFT.balanceOf(_owner);
        MyShareNFTCollection[] memory sNFTCollections = new MyShareNFTCollection[](
            tokenCount
        );

        uint256 tokenId = _shareNFT.CREATOR_NFT_TOKEN_ID();

        for (uint256 i = 0; i < tokenCount; i++) {
            sNFTCollections[i] = MyShareNFTCollection(
                tokenId, // token id
                creatorNFT().modelIdByTokenId(tokenId), // model id
                _shareNFT.tokenOfOwnerByIndex(_owner, i), // share id
                _shareMetadataNFT.name(), // name
                _shareMetadataNFT.symbol(), // symbol
                _shareNFT.totalSupply(), // so far total supply minted
                _shareNFT.MAX_TOTAL_SUPPLY(), // max total supply
                _shareNFT.MAX_MINT_PER_ADDR(), // max number of share per wallet
                _shareNFT.MAX_MINT_PER_TX(), // max number of share per tx
                _shareNFT.MINT_PRICE(), // price per share
                _shareNFT.PAYMENT_TOKEN_ADDR(), // payment token used in investment
                IERC20(_shareNFT.PAYMENT_TOKEN_ADDR()).balanceOf(_shareNFTAddr), // withdraw amount
                _shareNFTAddr, // share nft token address
                true, // whether cNFT has share nft or not
                _shareNFT.FOR_ONLY_US_INVESTOR() // for only us investor
            );
        }

        return sNFTCollections;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IIntellSetting.sol";

interface IShareERC721 {
    function MAX_TOTAL_SUPPLY() external view returns (uint256);

    function MAX_MINT_PER_ADDR() external view returns (uint256);

    function MAX_MINT_PER_TX() external view returns (uint256);

    function CREATOR_NFT_TOKEN_ID() external view returns (uint256);

    function CREATOR_NFT_CONTRACT_ADDR() external view returns (address);

    function MINT_PRICE() external view returns (uint256);

    function PAYMENT_TOKEN_ADDR() external view returns (address);

    function LAUNCH_END_TIME() external view returns (uint256);

    function FOR_ONLY_US_INVESTOR() external view returns(bool);

    function launch(bytes calldata _data, IIntellSetting _intellSetting) external;

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIntellSetting {
    function admin() external view returns(address);
    function truthHolder() external view returns(address);
    function creatorNFTMintPrice() external view returns(uint256);
    function shareNFTLaunchPrice() external view returns(uint256);
    function intellTokenAddr() external view returns(address);
    function factoryContractAddr() external view returns(address);
    function creatorNFTContractAddr() external view returns(address);
    function commissionForCreator() external view returns(uint256);
    function commissionForCreatorAndInvestor() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    event InvestorNFTCreated(uint256 indexed tokenId, address investorNFT);

    function getShareNFTAddr(uint256 _tokenId)
        external
        view
        returns (address investorNFT);

    function allShareNFTAddrs(uint256) external view returns (address);

    function allShareNFTAddrsLength() external view returns (uint256);

    function createShareNFTContract(
        bytes calldata _modelStatusMessasge,
        bytes calldata _modelStatusSignature,
        bytes calldata _launchMessage,
        bytes calldata _launchSignature
    ) external returns (address investorNFT);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ICreatorNFT {
    function creatorNFTMintedHistory(uint256 _modelId) external view returns(uint256);
    function modelIdByTokenId(uint256 _tokenId) external view returns(uint256);
    function tokenIdByModelId(uint256 _modelId) external view returns(uint256);
    function getPause() external view returns (bool);
    function paymentToken() external view returns (IERC20);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}