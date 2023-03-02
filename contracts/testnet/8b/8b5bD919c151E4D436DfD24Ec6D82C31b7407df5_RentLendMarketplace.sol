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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
pragma solidity ^0.8.9;

interface IRentLendMarketplace {
    enum NFTStandard {
        E721,
        E1155
    }
    enum LendStatus {
        LISTED,
        DELISTED
    }
    enum RentStatus {
        RENTED,
        RETURNED
    }
    enum NFTType {
        SAME_CHAIN,
        CROSS_CHAIN
    }

    struct Lending {
        uint256 lendingId;
        NFTStandard nftStandard;
        address nftAddress;
        uint256 tokenId;
        address payable lenderAddress;
        uint256 tokenQuantity; //listed qty of NFT //7
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenQuantityAlreadyRented; //Already rented
        uint256[] renterKeyArray;
        LendStatus lendStatus;
        NFTType nftType;
        string chain;
    }

    struct Renting {
        uint256 rentingId;
        uint256 lendingId; //associated lending Id
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 startTimeStamp;
        uint256 rentedDuration;
        RentStatus rentStatus;
    }
    // native
    error PriceNotMet(uint256 lendingId, uint256 price);
    error PriceMustBeAboveZero();
    error RentDurationNotAcceptable(uint256 maxRentDuration);

    error InvalidOrderIdInput(uint256 lendingId);
    error InvalidCaller(address expectedAddress, address callerAddress);
    error InvalidNFTStandard(address nftAddress);
    error InvalidInputs(
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    );

    // native
    event Lent(
        uint256 indexed lendingId,
        NFTStandard nftStandard,
        address nftAddress,
        uint256 tokenId,
        address indexed lenderAddress,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration,
        LendStatus lendStatus,
        NFTType indexed nftType
    );

    event LendingUpdated(
        uint256 indexed lendingId,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event Rented(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityRented,
        uint256 startTimeStamp,
        uint256 rentedDuration,
        RentStatus rentStatus
    );

    event Returned(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityReturned,
        RentStatus rentStatus
    );

    event DeListed(uint256 indexed lendingId, LendStatus lendStatus);

    // function setAutomationAddress(address _automation) external;

    // function setFeesForAdmin(uint256 _percentFees) external;

    function isERC721(address nftAddress) external view returns (bool output);

    function isERC1155(address nftAddress) external view returns (bool output);

    function withdrawFunds() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IRentLendMarketplace.sol";

contract RentLendMarketplace is Ownable, ReentrancyGuard, IRentLendMarketplace {
    using ERC165Checker for address;

    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;

    address payable public adminAddress;
    uint256 public lendingCtr;
    uint256 public rentingCtr;

    uint256 percentFeesAdmin = 4;
    uint256 public minRentDueSeconds = 86400;
    address public automationAddress;

    // keeps a check whether user has listed a particular NFT previously or not
    // NFTAddress => TokenID => UserAddress = Bool
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public userListedNFTBeforeSameChain;

    uint256[] public activeLendingsKeys;
    mapping(uint256 => Lending) lendings;

    uint256[] public activeRentingsKeys;
    mapping(uint256 => Renting) public rentings;

    modifier onlyAdmin() {
        if (msg.sender != adminAddress) {
            revert InvalidCaller(adminAddress, msg.sender);
        }
        _;
    }

    constructor() {
        lendingCtr = 0;
        rentingCtr = 0;
        adminAddress = payable(msg.sender);
    }

    //Changes days
    function lend(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external {
        bool listed = userListedNFTBeforeSameChain[_nftAddress][_tokenId][
            msg.sender
        ];

        require(
            listed == false,
            "Token already listed, Kindly Modify the listing!"
        );

        if (_nftStandard == NFTStandard.E721) {
            if (!isERC721(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            require(
                _tokenQuantity == 1,
                "This NFT standard supports only 1 listing"
            );

            address ownerOf = IERC721(_nftAddress).ownerOf(_tokenId);
            require(ownerOf == msg.sender, "You Do not own the NFT");
        } else if (_nftStandard == NFTStandard.E1155) {
            if (!isERC1155(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }

            uint256 ownerAmount = IERC1155(_nftAddress).balanceOf(
                msg.sender,
                _tokenId
            );
            require(
                ownerAmount >= _tokenQuantity,
                "Not enough tokens owned by Address or Tokens already listed"
            );
        }

        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (_maxRentDuration < minRentDueSeconds) {
            revert RentDurationNotAcceptable(_maxRentDuration);
        }
        _createNewOrder(
            _nftStandard,
            _nftAddress,
            _tokenId,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            NFTType.SAME_CHAIN,
            msg.sender
        );
        emit Lent(
            lendingCtr,
            _nftStandard,
            _nftAddress,
            _tokenId,
            msg.sender,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            LendStatus.LISTED,
            NFTType.SAME_CHAIN
        );
    }

    function _createNewOrder(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration,
        NFTType _nftType,
        address _lenderAddress
    ) internal {
        lendingCtr++;

        Lending memory lendingCache;
        lendingCache.lendingId = lendingCtr;
        lendingCache.nftStandard = _nftStandard;
        lendingCache.nftAddress = _nftAddress;
        lendingCache.tokenId = _tokenId;
        lendingCache.lenderAddress = payable(_lenderAddress);
        lendingCache.tokenQuantity = _tokenQuantity;
        lendingCache.pricePerDay = _price;
        lendingCache.maxRentDuration = _maxRentDuration;
        lendingCache.tokenQuantityAlreadyRented = 0;
        lendingCache.lendStatus = LendStatus.LISTED;
        lendingCache.nftType = _nftType;
        lendings[lendingCtr] = lendingCache;

        activeLendingsKeys.push(lendingCtr);
        userListedNFTBeforeSameChain[_nftAddress][_tokenId][
            _lenderAddress
        ] = true;
    }

    function modifyLending(
        uint256 _lendingId,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.lenderAddress != msg.sender) {
            revert InvalidCaller(lendingStorage.lenderAddress, msg.sender);
        }
        uint256 ownerHas = 1;
        if (lendingStorage.nftStandard == NFTStandard.E1155) {
            IERC1155 nft = IERC1155(lendingStorage.nftAddress);
            ownerHas = nft.balanceOf(msg.sender, lendingStorage.tokenId);
        }
        require(
            lendingStorage.nftType == NFTType.SAME_CHAIN,
            "Not a same chain NFT!"
        );
        require(
            lendingStorage.lendStatus == LendStatus.LISTED,
            "Item delisted!"
        );
        if (_tokenQtyToAdd > 0) {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
                lendingStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
            }
            require(
                ownerHas >=
                    lendingStorage.tokenQuantityAlreadyRented +
                        lendingStorage.tokenQuantity +
                        _tokenQtyToAdd,
                "Not Enough tokens owned by address"
            );
            lendingStorage.tokenQuantity += _tokenQtyToAdd;
        } else {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
                lendingStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                } else {
                    revert InvalidInputs(
                        _tokenQtyToAdd,
                        _newPrice,
                        _newMaxRentDuration
                    );
                }
            }
        }

        emit LendingUpdated(
            _lendingId,
            lendingStorage.tokenQuantity,
            lendingStorage.pricePerDay,
            lendingStorage.maxRentDuration
        );
    }

    function cancelLending(uint256 _lendingId) external {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.lenderAddress != msg.sender) {
            revert InvalidCaller(lendingStorage.lenderAddress, msg.sender);
        }

        if (lendingStorage.nftStandard == NFTStandard.E721) {
            require(
                lendingStorage.tokenQuantityAlreadyRented == 0,
                "Items cannot be delisted as they are currently rented"
            );
        }
        require(
            lendingStorage.lendStatus != LendStatus.DELISTED,
            "Item with listing Id ia already delisted"
        );

        lendingStorage.tokenQuantity = 0;

        lendingStorage.lendStatus = LendStatus.DELISTED;
        _removeEntryFromArray(activeLendingsKeys, _lendingId);

        userListedNFTBeforeSameChain[lendingStorage.nftAddress][
            lendingStorage.tokenId
        ][msg.sender] = false;

        emit DeListed(_lendingId, lendingStorage.lendStatus);
    }

    function rent(
        uint256 _lendingId,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];

        require(
            msg.sender != lendingStorage.lenderAddress,
            "Owned NFTs cannot be rented"
        );

        require(
            lendingStorage.lendStatus != LendStatus.DELISTED,
            "This order is delisted"
        );

        if (lendingStorage.nftStandard == NFTStandard.E721) {
            require(
                _tokenQuantity == 1,
                "Token Quantity cannot be greater than 1 for ERC721 Standard"
            );
        }
        require(
            lendingStorage.tokenQuantity >= _tokenQuantity,
            "Not Enough token available to rent"
        );

        if (_duration > lendingStorage.maxRentDuration) {
            revert RentDurationNotAcceptable(_duration);
        }
        if (
            msg.value !=
            calculateCost(lendingStorage.pricePerDay, _duration, _tokenQuantity)
        ) {
            revert PriceNotMet(_lendingId, lendingStorage.pricePerDay);
        }

        _updateRenting(lendingStorage, _tokenQuantity, _duration);

        _splitFunds(msg.value, lendingStorage.lenderAddress);

        emit Rented(
            rentingCtr,
            _lendingId,
            msg.sender,
            _tokenQuantity,
            block.timestamp,
            _duration,
            RentStatus.RENTED
        );
    }

    function calculateCost(
        uint256 _pricePerDay,
        uint256 _duration,
        uint256 qty
    ) public pure returns (uint256 cost) {
        cost = ((_pricePerDay * _duration * qty) / 86400);
    }

    //Supporting the rentItem function
    function _updateRenting(
        Lending storage lendingStorage,
        uint256 _tokenQuantity,
        uint256 _duration
    ) internal {
        rentingCtr++;
        lendingStorage.tokenQuantity =
            lendingStorage.tokenQuantity -
            _tokenQuantity;

        lendingStorage.tokenQuantityAlreadyRented =
            lendingStorage.tokenQuantityAlreadyRented +
            _tokenQuantity;

        Renting memory rentingCache;
        rentingCache.rentingId = rentingCtr;
        rentingCache.lendingId = lendingStorage.lendingId;
        rentingCache.rentStatus = RentStatus.RENTED;

        rentingCache.renterAddress = msg.sender;
        rentingCache.rentedDuration = _duration;
        rentingCache.tokenQuantityRented += _tokenQuantity;
        rentingCache.startTimeStamp = block.timestamp;

        rentings[rentingCtr] = rentingCache;

        lendingStorage.renterKeyArray.push(rentingCtr);
        activeRentingsKeys.push(rentingCtr);
    }

    function returnRented(uint256 _rentingID, uint256 _tokenQuantity) external {
        Renting storage rentingStorage = rentings[_rentingID];
        uint256 _lendingId = rentingStorage.lendingId;
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.nftStandard == NFTStandard.E721) {
            require(
                _tokenQuantity == 1,
                "Token Quantity cannot be greater than 1 for ERC721 Standard"
            );
        }
        require(
            rentingStorage.renterAddress == msg.sender,
            "Unverified caller, only renter can return the NFT"
        );

        require(
            rentingStorage.tokenQuantityRented >= _tokenQuantity,
            "Not enough tokens rented"
        );

        lendingStorage.tokenQuantity =
            lendingStorage.tokenQuantity +
            _tokenQuantity;

        lendingStorage.tokenQuantityAlreadyRented =
            lendingStorage.tokenQuantityAlreadyRented -
            _tokenQuantity;

        rentingStorage.tokenQuantityRented =
            rentingStorage.tokenQuantityRented -
            _tokenQuantity;

        if (rentingStorage.tokenQuantityRented == 0) {
            rentingStorage.rentStatus = RentStatus.RETURNED;
            _removeEntryFromArray(lendingStorage.renterKeyArray, _rentingID);
            _removeEntryFromArray(activeRentingsKeys, _rentingID);
        }

        emit Returned(
            _rentingID,
            _lendingId,
            msg.sender,
            _tokenQuantity,
            rentingStorage.rentStatus
        );
    }

    function _removeEntryFromArray(
        uint256[] storage arrayStorage,
        uint256 _entry
    ) internal {
        // uint256 _index;
        for (uint256 i = 0; i < arrayStorage.length; i++) {
            if (arrayStorage[i] == _entry) {
                // _index = i;
                arrayStorage[i] = arrayStorage[arrayStorage.length - 1];
                arrayStorage.pop();
                break;
            }
        }
    }

    //@dev functions gives us the data for listing data for
    function getLendingData(uint256 _lendingId)
        public
        view
        returns (Lending memory)
    {
        Lending memory listing = lendings[_lendingId];
        return listing;
    }

    //@dev Fucntion calculates admin fees to be deducted from total amount
    //and split the totalamout according to fees structure
    function _splitFunds(uint256 _totalAmount, address _lenderAddress)
        internal
    {
        require(_totalAmount != 0, "_totalAmount must be greater than 0");
        uint256 amountToSeller = (_totalAmount * (100 - percentFeesAdmin)) /
            100;

        payable(_lenderAddress).transfer(amountToSeller);
    }

    //@dev this fucntion is used to set percent fees for every transaction
    // on the marketpalce
    function setFeesForAdmin(uint256 _percentFees) external onlyOwner {
        require(_percentFees < 100, "Fees cannot exceed 100 %");
        percentFeesAdmin = _percentFees;
    }

    function setMinRentDueSecods(uint256 _minDuration) external onlyOwner {
        require(_minDuration > 1, "Duration should be greater than 1 sec");
        minRentDueSeconds = _minDuration;
    }

    function isERC721(address nftAddress) public view returns (bool output) {
        output = nftAddress.supportsInterface(IID_IERC721);
    }

    function isERC1155(address nftAddress) public view returns (bool output) {
        output = nftAddress.supportsInterface(IID_IERC1155);
    }

    function withdrawFunds() external override onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {
        // React to receiving ether
    }

    // ------------------------------ Automation functions -------------------------------- //
    function setAutomationAddress(address _automation) external onlyOwner {
        require(_automation != address(0), "The caller address cannot be zero");
        automationAddress = _automation;
    }

    function checkAndReturnRentedNfts() external {
        //UNCOMMENT IT LATER

        require(automationAddress != address(0), "Caller cannot be null!");
        require(
            msg.sender == automationAddress,
            "Only Authorised address can call this fucntion!"
        );
        (
            uint256[] memory getExpired,
            uint256 toupdate
        ) = checkRentingDurationExp();
        if (toupdate > 0) {
            _updateRentersDetails(getExpired);
        }
    }

    function checkRentingDurationExp()
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arrLength = activeRentingsKeys.length;

        // Renting[] memory tempArray = new Renting[](
        //     arrLength
        // );
        uint256[] memory tempArray = new uint256[](arrLength);
        // uint256[] memory tempArray = new uint256[](arrLength);
        uint256 k = 0;
        for (uint256 i = 0; i < activeRentingsKeys.length; i++) {
            if (
                block.timestamp >=
                rentings[i].startTimeStamp + rentings[i].rentedDuration
            ) {
                tempArray[k] = i;
                k++;
            }
        }
        return (tempArray, k);
    }

    function _updateRentersDetails(uint256[] memory _rentingIDs) internal {
        //require(msg.sender == _owner, "onlyOwner can call this function");

        require(_rentingIDs.length != 0, "The renters Array is Empty");

        for (uint256 i = 0; i < _rentingIDs.length; i++) {
            Renting storage rentersArrayStruct = rentings[_rentingIDs[i]];

            Lending storage lendingStorage = lendings[
                rentersArrayStruct.lendingId
            ];

            lendingStorage.tokenQuantity += lendingStorage
                .tokenQuantityAlreadyRented;
            lendingStorage.tokenQuantityAlreadyRented = 0;

            emit Returned(
                _rentingIDs[i],
                rentersArrayStruct.lendingId,
                rentersArrayStruct.renterAddress,
                rentersArrayStruct.tokenQuantityRented,
                RentStatus.RETURNED
            );

            //remove renter IDs from the renterKeyArray in order
            _removeEntryFromArray(
                lendingStorage.renterKeyArray,
                _rentingIDs[i]
            );

            //remove from activeRentingsKeys
            _removeEntryFromArray(activeRentingsKeys, _rentingIDs[i]);
        }
    }

    function checkAndDelistOrders() internal {
        require(automationAddress != address(0), " caller cannot be null");
        require(
            msg.sender == automationAddress,
            "Only Authorised address can call this fucntion"
        );
        uint256 arrLength = activeLendingsKeys.length;
        uint256[] memory tempArray = new uint256[](arrLength);
        uint256 k = 0;
        for (uint256 i = 0; i > arrLength; i++) {
            Lending storage lendingStorage = lendings[i];
            address ownerOf;
            if (lendingStorage.nftStandard == NFTStandard.E721) {
                ownerOf = IERC721(lendingStorage.nftAddress).ownerOf(
                    lendingStorage.tokenId
                );
                if (ownerOf != lendingStorage.lenderAddress) {
                    lendingStorage.lendStatus = LendStatus.DELISTED;
                    tempArray[k] = i;
                    emit DeListed(
                        lendingStorage.lendingId,
                        lendingStorage.lendStatus
                    );
                }
            } else {
                uint256 ownerAmount = IERC1155(lendingStorage.nftAddress)
                    .balanceOf(msg.sender, lendingStorage.tokenId);

                if (ownerAmount < lendingStorage.tokenQuantity) {
                    lendingStorage.lendStatus = LendStatus.DELISTED;
                    tempArray[k] = i;
                    emit DeListed(
                        lendingStorage.lendingId,
                        lendingStorage.lendStatus
                    );
                }
            }
        }

        for (uint256 i = 0; i < tempArray.length; i++) {
            activeLendingsKeys[tempArray[i]] = activeLendingsKeys[
                activeLendingsKeys.length - 1
            ];
            activeLendingsKeys.pop();
        }
    }
}