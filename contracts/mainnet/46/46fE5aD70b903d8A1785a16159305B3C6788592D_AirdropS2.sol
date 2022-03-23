// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/Counters.sol";
import "./utils/RandomNumberForAirdrop.sol";
import "./interfaces/IOpenBlox.sol";

struct BatchBlox {
    address recipient;
    uint8 amount;
    uint8 raceId;
}

contract AirdropS2 is Ownable, RandomNumberForAirdrop {
    uint256 private constant CIRCULATION = 5000;
    uint256 private constant TOKEN_ID_START = 2548;
    uint256 private constant TOKEN_ID_END = 7547;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address public nftAddress;

    constructor(address _nftAddress) {
        require(_nftAddress != address(0), "Presale: invalid nft address");
        nftAddress = _nftAddress;
        _tokenIdTracker.set(TOKEN_ID_START, TOKEN_ID_END);
    }

    function mint(BatchBlox[] calldata bloxes) external onlyOwner {
        _mint(bloxes);
    }

    function _mint(BatchBlox[] calldata bloxes) internal {
        for (uint8 i = 0; i < bloxes.length; ++i) {
            require(bloxes[i].raceId < 6, "Presale: invalid raceId");
            for (uint8 j = 0; j < bloxes[i].amount; ++j) {
                uint256 tokenId = _tokenIdTracker.current();
                uint256 genes = _generateRandomGenes(tokenId, uint16(i) * 37, bloxes[i].raceId);
                uint256 ancestorCode = _geneerateAncestorCode(tokenId);
                IOpenBlox(nftAddress).mintBlox(
                    tokenId, // tokenId
                    bloxes[i].recipient, // receiver
                    genes, // genes
                    block.timestamp, // bornAt
                    0, // generation
                    0, // parent0Id
                    0, // parent1Id
                    ancestorCode, // ancestorCode
                    0 // reproduction
                );
                _tokenIdTracker.increment();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1
// modified from @openzeppelin/contracts/utils/Counters.sol

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
        uint256 _max;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        require(counter._value <= counter._max, "Counter: reached max value");
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }

    function set(
        Counter storage counter,
        uint256 from,
        uint256 to
    ) internal {
        require(from < to, "Counter: from must less than to");
        counter._value = from;
        counter._max = to;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RandomNumberForAirdrop {
    function _generateRandomMystricId(uint256 tokenId, uint16 sequence) internal view returns (uint8) {
        uint16[3] memory weight = [9989, 9999, 10000];
        uint256 random1 = uint256(keccak256(abi.encodePacked(msg.sender, tokenId, sequence, blockhash(block.number - 1), block.coinbase, block.difficulty)));
        uint16 random2 = uint16(random1 % (10000));
        for (uint8 i = 0; i < 3; ++i) {
            if (random2 < weight[i]) return i;
        }
        return 2;
    }

    function _generateRandomPartsId(uint256 tokenId, uint16 sequence) internal view returns (uint8) {
        uint16[6] memory weight = [1990, 3980, 5970, 7960, 9950, 10000];
        uint256 random1 = uint256(keccak256(abi.encodePacked(msg.sender, tokenId, sequence, blockhash(block.number - 1), block.coinbase, block.difficulty)));
        uint16 random2 = uint16(random1 % 10000);
        for (uint8 i = 0; i < 6; ++i) {
            if (random2 < weight[i]) return i;
        }
        return 5;
    }

    function _generateRandomParts(
        uint256 tokenId,
        uint16 sequence,
        uint8 raceId
    ) internal view returns (uint8[13] memory) {
        uint8[13] memory randoms = [uint8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // randoms:
        //   0, 1: head
        //   2, 3: body
        //   4, 5: horn
        //   6, 7: back
        //   8, 9: arms
        //   10, 11: legs
        //   12: race

        // random from [0,1,2,3,4,5]
        randoms[12] = raceId;
        for (uint8 i = 0; i < 6; ++i) {
            // race: range = [0,1,2], rate = [9989,10,1], weight = [9989,9999,10000]
            randoms[i * 2] = _generateRandomMystricId(tokenId, sequence + i * 6 + 1);
            // range = [0,1,2,3,4,5], rate = [1990,1990,1990,1990,1990,50], weight = [1990,3980,5970,7960,9950,10000]
            randoms[i * 2 + 1] = _generateRandomPartsId(tokenId, sequence + i * 6 + 5);
        }
        return randoms;
    }

    function _generateRandomGenes(
        uint256 tokenId,
        uint16 sequence,
        uint8 raceId
    ) internal view returns (uint256 genes) {
        uint8[13] memory randoms = _generateRandomParts(tokenId, sequence, raceId);
        for (uint8 i = 0; i < 6; ++i) {
            genes = genes * 0x100000000;
            uint256 unit = randoms[12] * 0x20 + randoms[i * 2 + 1];
            uint256 gene = randoms[i * 2] * 0x40000000 + unit * 0x100401;
            genes = genes + gene;
        }
        genes = genes * 0x10000000000000000;
        return genes;
    }

    function _geneerateAncestorCode(uint256 tokenId) internal pure returns (uint256 ancestorCode) {
        return tokenId * 0x1000100010001000100010001000100010001000100010001000100010001;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOpenBlox is IERC721Upgradeable {
    struct Blox {
        uint256 genes;
        uint256 bornAt;
        uint16 generation;
        uint256 parent0Id;
        uint256 parent1Id;
        uint256 ancestorCode;
        uint8 reproduction;
    }

    function getBlox(uint256 tokenId)
        external
        view
        returns (
            uint256 genes,
            uint256 bornAt,
            uint16 generation,
            uint256 parent0Id,
            uint256 parent1Id,
            uint256 ancestorCode,
            uint8 reproduction
        );

    function mintBlox(
        uint256 tokenId,
        address receiver,
        uint256 genes,
        uint256 bornAt,
        uint16 generation,
        uint256 parent0Id,
        uint256 parent1Id,
        uint256 ancestorCode,
        uint8 reproduction
    ) external;

    function burnBlox(uint256 tokenId) external;

    function increaseReproduction(uint256 tokenId) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
interface IERC165Upgradeable {
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