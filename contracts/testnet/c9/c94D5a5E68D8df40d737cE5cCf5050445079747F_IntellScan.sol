// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./interface/IShareERC721.sol";
import "./interface/IIntellModelNFT.sol";
import "./interface/IFactory.sol";
import "./interface/IIntellSetting.sol";

pragma experimental ABIEncoderV2;

interface IShareERC721InDetail is IERC721Enumerable, IShareERC721 {}
interface IIntellModelNFTInDetail is IERC721Enumerable, IIntellModelNFT {}

contract IntellScan is Ownable {
    using SafeMath for uint256;

    IIntellSetting private _intellSetting;

    constructor(IIntellSetting _intellSetting_) {
        _intellSetting = _intellSetting_;
    }

    function intellSetting() public view returns (IIntellSetting) {
        return _intellSetting;
    }

    function setIntelliSetting(
        IIntellSetting _intellSetting_
    ) external onlyOwner {
        _intellSetting = _intellSetting_;
    }

    function creatorNFT() public view returns (IIntellModelNFTInDetail) {
        return
            IIntellModelNFTInDetail(
                _intellSetting.intellModelNFTContractAddr()
            );
    }

    function factory() public view returns (IFactory) {
        return IFactory(_intellSetting.factoryContractAddr());
    }

    struct ModelMetadata {
        uint256 tokenId;
        uint256 modelId;
        string shareName;
        string shareSymbol;
        uint256 totalSupply;
        uint256 maxTotalSupply;
        uint256 mnpw;
        uint256 mnpt;
        uint256 sharePrice;
        address tokenAddr;
        uint256 withdrawAmount;
        address shareNFTAddr; // Share NFT Contract Address for the investors
        bool hasShareLaunched; // whether sNFT was launched or not
        bool forOnlyUS; // for only us investor
        uint256 endTime;
        bool finished;
        uint256 countdown;
        bool withdrawn;
        bool blocked;
    }

    struct ShareMetadata {
        uint256 shareId;
        uint256 tokenId;
        uint256 modelId;
        string shareName;
        string shareSymbol;
        uint256 totalSupply;
        uint256 maxTotalSupply;
        uint256 mnpw;
        uint256 mnpt;
        uint256 sharePrice;
        address tokenAddr;
        uint256 withdrawAmount;
        address shareNFTAddr; // Share NFT Contract Address for the investors
        bool hasShareLaunched; // whether sNFT was launched or not
        bool forOnlyUS; // for only us investor
        uint256 endTime;
        bool finished;
        uint256 countdown;
        bool withdrawn;
        bool blocked;
    }

    function creatorNFTCollectionDetail(
        address _owner
    ) external view returns (ModelMetadata[] memory) {
        uint256 tokenCount = creatorNFT().balanceOf(_owner);
        uint256[] memory tokenIds = creatorNFT().walletOfOwner(_owner);

        ModelMetadata[] memory creatorNFTCollections = new ModelMetadata[](
            tokenCount
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            if (factory().getShareNFTAddr(tokenIds[i]) != address(0)) {
                address _shareNFTAddr = factory().getShareNFTAddr(tokenIds[i]);

                IShareERC721InDetail _shareNFT = IShareERC721InDetail(
                    _shareNFTAddr
                );
                IERC721Metadata _shareMetadataNFT = IERC721Metadata(
                    _shareNFTAddr
                );

                uint256 _endTime = _shareNFT.LAUNCH_END_TIME();

                creatorNFTCollections[i] = ModelMetadata(
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
                    _shareNFT.FOR_ONLY_US_INVESTOR(), // for only us investor
                    _endTime,
                    _endTime < block.timestamp,
                    _endTime < block.timestamp ? 0 : _endTime - block.timestamp,
                    _shareNFT.WITHDRAWN(),
                    _shareNFT.BLOCKED()
                );
            } else {
                creatorNFTCollections[i] = ModelMetadata(
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
                    false, // for only us investor
                    0,
                    true,
                    0,
                    false,
                    true
                );
            }
        }

        return creatorNFTCollections;
    }

    function singleCreatorNFTDetail(
        uint256 _tokenId
    ) external view returns (ModelMetadata memory) {

        if (factory().getShareNFTAddr(_tokenId) != address(0)) {
            address _shareNFTAddr = factory().getShareNFTAddr(_tokenId);
            IShareERC721InDetail _shareNFT = IShareERC721InDetail(
                _shareNFTAddr
            );
            IERC721Metadata _shareMetadataNFT = IERC721Metadata(_shareNFTAddr);

            uint256 _endTime = _shareNFT.LAUNCH_END_TIME();

            return
                ModelMetadata(
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
                    _shareNFT.FOR_ONLY_US_INVESTOR(), // for only us investor
                    _endTime,
                    _endTime < block.timestamp,
                    _endTime < block.timestamp ? 0 : _endTime - block.timestamp,
                    _shareNFT.WITHDRAWN(),
                    _shareNFT.BLOCKED()
                );
        } else {
            return
                ModelMetadata(
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
                    false, // for only us investor
                    0,
                    true,
                    0,
                    false,
                    true
                );
        }
    }

    function singleInvestmentChance(
        uint256 _index
    ) external view returns (ModelMetadata memory) {
        address _shareNFTAddr = factory().allShareNFTAddrs(_index);
        IShareERC721InDetail _shareNFT = IShareERC721InDetail(_shareNFTAddr);
        IERC721Metadata _shareMetadataNFT = IERC721Metadata(_shareNFTAddr);

        uint256 _tokenId = _shareNFT.INTELL_MODEL_NFT_TOKEN_ID();
        uint256 _endTime = _shareNFT.LAUNCH_END_TIME();

        return
            ModelMetadata(
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
                _shareNFT.FOR_ONLY_US_INVESTOR(), // for only us investor
                _endTime,
                _endTime < block.timestamp,
                _endTime < block.timestamp ? 0 : _endTime - block.timestamp,
                _shareNFT.WITHDRAWN(),
                _shareNFT.BLOCKED()
            );
    }

    function shareNFTCollectionDetail(
        address _owner,
        uint256 _index
    ) external view returns (ShareMetadata[] memory) {
        address _shareNFTAddr = factory().allShareNFTAddrs(_index);

        IShareERC721InDetail _shareNFT = IShareERC721InDetail(_shareNFTAddr);
        IERC721Metadata _shareMetadataNFT = IERC721Metadata(_shareNFTAddr);

        uint256 tokenCount = _shareNFT.balanceOf(_owner);
        ShareMetadata[] memory shareNFTCollections = new ShareMetadata[](
            tokenCount
        );

        uint256 tokenId = _shareNFT.INTELL_MODEL_NFT_TOKEN_ID();
        uint256 _endTime = _shareNFT.LAUNCH_END_TIME();

        for (uint256 i = 0; i < tokenCount; i++) {
            shareNFTCollections[i] = ShareMetadata(
                _shareNFT.tokenOfOwnerByIndex(_owner, i), // share id
                tokenId, // token id
                creatorNFT().modelIdByTokenId(tokenId), // model id
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
                _shareNFT.FOR_ONLY_US_INVESTOR(), // for only us investor
                _endTime,
                _endTime < block.timestamp,
                _endTime < block.timestamp ? 0 : _endTime - block.timestamp,
                _shareNFT.WITHDRAWN(),
                _shareNFT.BLOCKED()
            );
        }

        return shareNFTCollections;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IShareERC721 {
    function MAX_TOTAL_SUPPLY() external view returns (uint256);

    function MAX_MINT_PER_ADDR() external view returns (uint256);

    function MAX_MINT_PER_TX() external view returns (uint256);

    function INTELL_MODEL_NFT_TOKEN_ID() external view returns (uint256);

    function INTELL_MODEL_NFT_CONTRACT_ADDR() external view returns (address);

    function MINT_PRICE() external view returns (uint256);

    function PAYMENT_TOKEN_ADDR() external view returns (address);

    function LAUNCH_END_TIME() external view returns (uint256);

    function FOR_ONLY_US_INVESTOR() external view returns(bool);
    
    function WITHDRAWN() external view returns(bool);

    function BLOCKED() external view returns(bool);

    function launch(bytes calldata _data, uint256 _INTELL_MODEL_NFT_TOKEN_ID) external;

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
    function shareNFTLaunchPrice() external view returns(uint256);
    function intellTokenAddr() external view returns(address);
    function factoryContractAddr() external view returns(address);
    function intellModelNFTContractAddr() external view returns(address);
    function modelLaunchPrice() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIntellModelNFT {
    function modelNFTMintedHistory(uint256 _modelId) external view returns(uint256);
    function modelIdByTokenId(uint256 _tokenId) external view returns(uint256);
    function tokenIdByModelId(uint256 _modelId) external view returns(uint256);
    function getPause() external view returns (bool);
    function paymentToken() external view returns (IERC20);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
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
        bytes memory shareMessage,
        uint256 _INTELL_MODEL_NFT_TOKEN_ID
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}