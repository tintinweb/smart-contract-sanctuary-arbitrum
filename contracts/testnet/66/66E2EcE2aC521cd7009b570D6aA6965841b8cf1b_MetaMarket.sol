// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721Cloneable is IERC721Upgradeable {

  function mintMMT(address minter, uint256 numberOfTokens) external;

  function getMintStats() external view returns ( uint256 currentTotalSupply, uint256 maxSupply );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PublicDrop} from "../structs/MetamarketStructs.sol";

interface IMetamarket {
    // error
    error CreatorPayoutAddressCannotBeZeroAddress();

    error MintQuantityExceedsMaxSupply(
        uint256 total,
        uint256 maxSupply
    );

    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    error InsufficientMintPrice(
        uint256 mintPrice,
        uint256 paidPrice
    );

    // event
    event UpdatePlatform(address account, uint256 feePercentage);

    event EmergencyStopSet(bool enabled); // 紧急停机状态变更事件
    
    event CreatorPayoutAddressUpdated(
        address indexed nftContract,
        address indexed newPayoutAddress
    );
    
    event MetamarketMint(
        address indexed nftContract,
        address indexed minter,
        uint256 quantityMinted,
        uint256 mintIndex
    );

    event PublicDropUpdated(
        address indexed nftContract,
        PublicDrop publicDrop
    );

    // function
    function mintMMT(address nftContract, uint256 numberOfTokens, uint256 rate) external payable;

    function updateCreatorPayoutAddress(address payoutAddress) external;

    function updatePublicDrop(PublicDrop calldata publicDrop) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721Cloneable } from "./interfaces/IERC721Cloneable.sol";
import { IMetamarket } from "./interfaces/IMetamarket.sol";
import { PublicDrop, Platform } from "./structs/MetamarketStructs.sol";

contract MetaMarket is IMetamarket, Ownable, ReentrancyGuard {
    mapping(address => address) private _creatorPayoutAddresses;
    mapping(address => PublicDrop) private _publicDrops;
    Platform private _platform;

    bool public emergencyStop; // 紧急停机开关

    modifier notInEmergencyStop() {
        require(!emergencyStop, "Contract is in emergency stop");
        _; 
    }

    constructor() {
        _platform = Platform({
            account: 0x850effAbF4f2c027c8De872AdE55D2a284A62247,
            feePercentage: 150
        });
    }

    function updatePlatform(
        address account,
        uint256 feePercentage 
    ) public onlyOwner nonReentrant notInEmergencyStop {
        _platform.account = account;
        _platform.feePercentage = feePercentage;

        emit UpdatePlatform(account, feePercentage);
    }

    function setEmergencyStop(bool enabled) public onlyOwner {
        emergencyStop = enabled;
        emit EmergencyStopSet(enabled);
    }

    function _name() internal pure returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x4d6574614d61726b6574)
            return(0x20, 0x60)
        }
    }

    function _nameString() internal pure returns (string memory) {
        // Return the name of the contract.
        return "MetaMarket";
    }

    function mintMMT(address nftContract, uint256 numberOfTokens, uint256 rate) public payable nonReentrant notInEmergencyStop {
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        if (block.timestamp < publicDrop.startTime || block.timestamp > publicDrop.endTime) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, publicDrop.startTime, publicDrop.endTime);
        }

        (
            uint256 currentTotalSupply,
            uint256 maxSupply
        ) = IERC721Cloneable(nftContract).getMintStats();

        if (numberOfTokens + currentTotalSupply > maxSupply) {
            revert MintQuantityExceedsMaxSupply(
                numberOfTokens + currentTotalSupply,
                maxSupply
            );
        }

        IERC721Cloneable(nftContract).mintMMT(msg.sender, numberOfTokens);

        uint256 mintPrice = (publicDrop.mintPrice / rate / 1e16) * numberOfTokens;
        if (mintPrice > msg.value){
            revert InsufficientMintPrice(mintPrice, msg.value);
        }

        uint256 fee = ((mintPrice * _platform.feePercentage / 10000) / rate / 1e16) * numberOfTokens;
        payable(nftContract).transfer(mintPrice - fee);

        payable(_platform.account).transfer(fee);

        emit MetamarketMint(
            nftContract,
            msg.sender,
            numberOfTokens,
            currentTotalSupply
        );
    }

    function getMintPublicDrop(address nftContract)
        external
        view
        returns (
            uint256 current,
            uint80 mintPrice,
            uint48 start,
            uint48 end,
            address platform,
            uint256 feePercentage
        )
    {
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        current = block.timestamp;
        mintPrice = publicDrop.mintPrice;
        start = publicDrop.startTime;
        end = publicDrop.endTime;
        platform = _platform.account;
        feePercentage = _platform.feePercentage;
    }

    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
        notInEmergencyStop
    {
        _publicDrops[msg.sender] = publicDrop;

        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    function updateCreatorPayoutAddress(address _payoutAddress)
        external
        notInEmergencyStop
    {
        if (_payoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }
        
        _creatorPayoutAddresses[msg.sender] = _payoutAddress;

        emit CreatorPayoutAddressUpdated(msg.sender, _payoutAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PublicDrop {
    uint80 mintPrice; // 80/256 bits
    uint48 startTime; // 128/256 bits
    uint48 endTime; // 176/256 bits
}

struct Platform {
    address account;
    uint256 feePercentage; // 手续费百分比（乘以 10^4，例如：2% = 2000, 1.5% = 150）
}