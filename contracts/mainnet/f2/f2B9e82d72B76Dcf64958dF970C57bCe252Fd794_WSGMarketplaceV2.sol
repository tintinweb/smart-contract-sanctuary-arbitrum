// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
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
     * @dev Returns the value of tokens of token type `id` owned by `account`.
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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WSGMarketplaceV2 is ReentrancyGuard, Ownable {
    enum TokenType {ERC1155, ERC721} // 0 = ERC1155, 1 = ERC721

    address public constant WallStreetGamesNFT = 0x560713dB31F8FF66AA58E8BF93c93e136D85e168;

    struct Listing {
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 noOfTokensToSell;
        uint256 pricePerToken;
        address paymentToken;
        TokenType tokenType;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings;
    uint256 private _nextListingId = 1000;
    mapping(address => bool) public whitelistedTokens;

    // Royalty fee
    uint256 public royaltyFeePercentage = 5;
    address public feeWallet = 0x67A9F299f5EB939c6F02063f660A252A81Dd62c9;

    // Events
    event List(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address paymentToken, TokenType tokenType);
    event Buy(uint256 indexed listingId, address indexed buyer, address indexed seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address paymentToken, TokenType tokenType);
    event ListingRemoved(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address paymentToken, TokenType tokenType);
    event ListingFulfilled(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address paymentToken, TokenType tokenType);
    event ListingDeactivated(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 amount, uint256 price, TokenType tokenType);

    // Errors
    error IncorrectValue(uint256 expected, uint256 provided);
    error QuantityMustBeOneForERC721();
    error PaymentTransferFailed();
    error RoyaltyPaymentTransferFailed();
    error TokenNotWhitelisted();
    error InsufficientBalance();
    error TransferError();
    error ListingDoesNotExist();
    error ApprovalRequired();
    error NotListingOwner();

    constructor() Ownable(msg.sender) {
        whitelistedTokens[WallStreetGamesNFT] = true;
    }

    // List an NFT
    function listNFT(address tokenAddress, uint256 tokenId, uint256 noOfTokensToSell, uint256 pricePerToken, address paymentToken, TokenType tokenType) external {
        if (!whitelistedTokens[tokenAddress]) revert TokenNotWhitelisted();

        // ERC1155
        if (tokenType == TokenType.ERC1155 && IERC1155(tokenAddress).balanceOf(msg.sender, tokenId) < noOfTokensToSell) revert InsufficientBalance();
        if (tokenType == TokenType.ERC1155 && !IERC1155(tokenAddress).isApprovedForAll(msg.sender, address(this))) revert ApprovalRequired();
        // ERC721
        if (tokenType == TokenType.ERC721 && IERC721(tokenAddress).ownerOf(tokenId) != msg.sender) revert InsufficientBalance();
        if (tokenType == TokenType.ERC721 && !IERC721(tokenAddress).isApprovedForAll(msg.sender, address(this))) revert ApprovalRequired();

        // Add listing
        uint256 listingId = _nextListingId++;
        listings[listingId] = Listing(msg.sender, tokenAddress, tokenId, noOfTokensToSell, pricePerToken, paymentToken, tokenType, true);

        emit List(listingId, msg.sender, tokenAddress, tokenId, noOfTokensToSell, pricePerToken, paymentToken, tokenType);
    }

    // Buy an NFT
    function buyNFT(uint256 listingId, uint256 noOfTokensToBuy) external payable nonReentrant returns (bool) {
        Listing storage listing = listings[listingId];
        if (!listing.isActive) revert ListingDoesNotExist();
        if (listing.noOfTokensToSell < noOfTokensToBuy) revert InsufficientBalance();

        // Check seller's balance for ERC1155 or ERC721
        bool hasEnoughTokens;
        if (listing.tokenType == TokenType.ERC1155) {
            hasEnoughTokens = IERC1155(listing.tokenAddress).balanceOf(listing.seller, listing.tokenId) >= noOfTokensToBuy;
        } else if (listing.tokenType == TokenType.ERC721) {
            hasEnoughTokens = IERC721(listing.tokenAddress).ownerOf(listing.tokenId) == listing.seller;
            if (noOfTokensToBuy != 1) hasEnoughTokens = false; // Ensure ERC721 quantity is 1
        }

        if (!hasEnoughTokens) {
            listing.isActive = false;
            emit ListingDeactivated(listingId, listing.seller, listing.tokenAddress, listing.tokenId, listing.noOfTokensToSell, listing.pricePerToken, listing.tokenType);

            // Refund the buyer if the payment was in native ETH
            if (listing.paymentToken == address(0)) {
                (bool refundSuccess,) = msg.sender.call{value: msg.value}("");
                require(refundSuccess, "Refund failed");
            }
            return false; // Listing deactivated due to insufficient seller balance
        }

        uint256 totalCost = listing.pricePerToken * noOfTokensToBuy;
        uint256 royaltyFee = (totalCost * royaltyFeePercentage) / 100;
        uint256 sellerProceeds = totalCost - royaltyFee;

        // Handle payment
        if (listing.paymentToken == address(0)) {
            // Payment in native ETH
            if (msg.value != totalCost) revert IncorrectValue(totalCost, msg.value);

            // Transfer funds
            (bool sellerTransferSuccess,) = listing.seller.call{value: sellerProceeds}("");
            (bool feeWalletTransferSuccess,) = feeWallet.call{value: royaltyFee}("");

            // Revert if transfer failed
            if (!sellerTransferSuccess) revert PaymentTransferFailed();
            if (!feeWalletTransferSuccess) revert RoyaltyPaymentTransferFailed();
        } else {
            // Payment in ERC20 token
            IERC20 paymentToken = IERC20(listing.paymentToken);
            if (paymentToken.allowance(msg.sender, address(this)) < totalCost) revert InsufficientBalance();

            // Transfer funds
            bool sellerTransferSuccess = paymentToken.transferFrom(msg.sender, listing.seller, sellerProceeds);
            bool feeWalletTransferSuccess = paymentToken.transferFrom(msg.sender, feeWallet, royaltyFee);

            // Revert if transfer failed
            if (!sellerTransferSuccess) revert PaymentTransferFailed();
            if (!feeWalletTransferSuccess) revert RoyaltyPaymentTransferFailed();
        }

        // Remove listing if all tokens are sold
        if (listing.noOfTokensToSell == noOfTokensToBuy) {
            listing.isActive = false;
            emit ListingFulfilled(listingId, listing.seller, listing.tokenAddress, listing.tokenId, listing.noOfTokensToSell, listing.pricePerToken, listing.paymentToken, listing.tokenType);
        } else {
            // Update listing
            listing.noOfTokensToSell -= noOfTokensToBuy;
        }

        // Transfer NFT
        _transferNFT(listing.seller, msg.sender, listing.tokenAddress, listing.tokenId, noOfTokensToBuy, listing.tokenType);

        emit Buy(listingId, msg.sender, listing.seller, listing.tokenAddress, listing.tokenId, noOfTokensToBuy, listing.pricePerToken, listing.paymentToken, listing.tokenType);
        return true;
    }

    // Remove Listing
    function removeListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        // Check if the sender is the listing owner or the marketplace owner
        if (!(listing.seller == msg.sender || owner() == msg.sender)) revert NotListingOwner();
        if (!listing.isActive) revert ListingDoesNotExist();

        listing.isActive = false;
        emit ListingRemoved(listingId, listing.seller, listing.tokenAddress, listing.tokenId, listing.noOfTokensToSell, listing.pricePerToken, listing.paymentToken, listing.tokenType);
    }

    // Admin functions
    function whitelistToken(address tokenAddress) external onlyOwner {
        whitelistedTokens[tokenAddress] = true;
    }

    function removeTokenFromWhitelist(address tokenAddress) external onlyOwner {
        whitelistedTokens[tokenAddress] = false;
    }

    function setRoyaltyFeePercentage(uint256 _royaltyFeePercentage) external onlyOwner {
        royaltyFeePercentage = _royaltyFeePercentage;
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }

    // Withdraw stuck ETH
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    function _transferNFT(address from, address to, address tokenAddress, uint256 tokenId, uint256 noOfTokensToSell, TokenType tokenType) private {
        if (tokenType == TokenType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, noOfTokensToSell, "");
        } else if (tokenType == TokenType.ERC721) {
            if (noOfTokensToSell != 1) revert QuantityMustBeOneForERC721();
            IERC721(tokenAddress).safeTransferFrom(from, to, tokenId);
        }
    }
}