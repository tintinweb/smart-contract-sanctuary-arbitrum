/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// SPDX-License-Identifier: UNLICENSED


// File: IDelegateRegistry.sol

pragma solidity >=0.8.13;

/**
 * @title IDelegateRegistry
 * @custom:version 2.0
 * @custom:author foobar (0xfoobar)
 * @notice A standalone immutable registry storing delegated permissions from one address to another
 */
interface IDelegateRegistry {
    /// @notice Delegation type, NONE is used when a delegation does not exist or is revoked
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        ERC721,
        ERC20,
        ERC1155
    }

    /// @notice Struct for returning delegations
    struct Delegation {
        DelegationType type_;
        address to;
        address from;
        bytes32 rights;
        address contract_;
        uint256 tokenId;
        uint256 amount;
    }

    /// @notice Emitted when an address delegates or revokes rights for their entire wallet
    event DelegateAll(address indexed from, address indexed to, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for a contract address
    event DelegateContract(address indexed from, address indexed to, address indexed contract_, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for an ERC721 tokenId
    event DelegateERC721(address indexed from, address indexed to, address indexed contract_, uint256 tokenId, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for an amount of ERC20 tokens
    event DelegateERC20(address indexed from, address indexed to, address indexed contract_, bytes32 rights, uint256 amount);

    /// @notice Emitted when an address delegates or revokes rights for an amount of an ERC1155 tokenId
    event DelegateERC1155(address indexed from, address indexed to, address indexed contract_, uint256 tokenId, bytes32 rights, uint256 amount);

    /// @notice Thrown if multicall calldata is malformed
    error MulticallFailed();

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for all contracts
     * @param to The address to act as delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateAll(address to, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific contract
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateContract(address to, address contract_, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific ERC721 token
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC721(address to, address contract_, uint256 tokenId, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific amount of ERC20 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address for the fungible token contract
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC20(address to, address contract_, bytes32 rights, uint256 amount) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific amount of ERC1155 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address of the contract that holds the token
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount of that token id to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC1155(address to, address contract_, uint256 tokenId, bytes32 rights, uint256 amount) external payable returns (bytes32 delegationHash);

    /**
     * ----------- CHECKS -----------
     */

    /**
     * @notice Check if "to" is a delegate of "from" for the entire wallet
     * @param to The potential delegate address
     * @param from The potential address who delegated rights
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on the from's behalf
     */
    function checkDelegateForAll(address to, address from, bytes32 rights) external view returns (bool);

    /**
     * @notice Check if "to" is a delegate of "from" for the specified "contract_" or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet or that specific contract
     */
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights) external view returns (bool);

    /**
     * @notice Check if "to" is a delegate of "from" for the specific "contract" and "tokenId", the entire "contract_", or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param tokenId The token id for the token to delegating
     * @param from The wallet that issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet, that contract, or that specific tokenId
     */
    function checkDelegateForERC721(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view returns (bool);

    /**
     * @notice Returns the amount of ERC20 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights) external view returns (uint256);

    /**
     * @notice Returns the amount of a ERC1155 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param tokenId The token id to check the delegated amount of
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view returns (uint256);

    /**
     * ----------- ENUMERATIONS -----------
     */

    /**
     * @notice Returns all enabled delegations a given delegate has received
     * @param to The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getIncomingDelegations(address to) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all enabled delegations an address has given out
     * @param from The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getOutgoingDelegations(address from) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has received
     * @param to The address to retrieve incoming delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getIncomingDelegationHashes(address to) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has given out
     * @param from The address to retrieve outgoing delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getOutgoingDelegationHashes(address from) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns the delegations for a given array of delegation hashes
     * @param delegationHashes is an array of hashes that correspond to delegations
     * @return delegations Array of Delegation structs, return empty structs for nonexistent or revoked delegations
     */
    function getDelegationsFromHashes(bytes32[] calldata delegationHashes) external view returns (Delegation[] memory delegations);

    /**
     * ----------- STORAGE ACCESS -----------
     */

    /**
     * @notice Allows external contracts to read arbitrary storage slots
     */
    function readSlot(bytes32 location) external view returns (bytes32);

    /**
     * @notice Allows external contracts to read an arbitrary array of storage slots
     */
    function readSlots(bytes32[] calldata locations) external view returns (bytes32[] memory);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when "value" tokens are moved from one account ("from") to
     * another ("to").
     *
     * Note that "value" may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a "spender" for an "owner" is set by
     * a call to {approve}. "value" is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by "account".
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a "value" amount of tokens from the caller's account to "to".
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that "spender" will be
     * allowed to spend on behalf of "owner" through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a "value" amount of tokens as the allowance of "spender" over the
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
     * @dev Moves a "value" amount of tokens from "from" to "to" using the
     * allowance mechanism. "value" is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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
     * "interfaceId". See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * """solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * """
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/token/common/ERC2981.sol
// OpenZeppelin Contracts (last updated v5.0.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.20;



/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 tokenId => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev The default royalty set is invalid (eg. (numerator / denominator) >= 1).
     */
    error ERC2981InvalidDefaultRoyalty(uint256 numerator, uint256 denominator);

    /**
     * @dev The default royalty receiver is invalid.
     */
    error ERC2981InvalidDefaultRoyaltyReceiver(address receiver);

    /**
     * @dev The royalty set for an specific "tokenId" is invalid (eg. (numerator / denominator) >= 1).
     */
    error ERC2981InvalidTokenRoyalty(uint256 tokenId, uint256 numerator, uint256 denominator);

    /**
     * @dev The royalty receiver for "tokenId" is invalid.
     */
    error ERC2981InvalidTokenRoyaltyReceiver(uint256 tokenId, address receiver);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - "receiver" cannot be the zero address.
     * - "feeNumerator" cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        uint256 denominator = _feeDenominator();
        if (feeNumerator > denominator) {
            // Royalty fee will exceed the sale price
            revert ERC2981InvalidDefaultRoyalty(feeNumerator, denominator);
        }
        if (receiver == address(0)) {
            revert ERC2981InvalidDefaultRoyaltyReceiver(address(0));
        }

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - "receiver" cannot be the zero address.
     * - "feeNumerator" cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual {
        uint256 denominator = _feeDenominator();
        if (feeNumerator > denominator) {
            // Royalty fee will exceed the sale price
            revert ERC2981InvalidTokenRoyalty(tokenId, feeNumerator, denominator);
        }
        if (receiver == address(0)) {
            revert ERC2981InvalidTokenRoyaltyReceiver(tokenId, address(0));
        }

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}


// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * "onlyOwner", which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. "address(0)")
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
     * "onlyOwner" functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account ("newOwner").
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account ("newOwner").
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by "from".
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The "quantity" minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The "extraData" cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to "startTimestamp" that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * "interfaceId". See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when "tokenId" token is transferred from "from" to "to".
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when "owner" enables "approved" to manage the "tokenId" token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when "owner" enables or disables
     * ("approved") "operator" to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in "owner"'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers "tokenId" token from "from" to "to",
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must exist and be owned by "from".
     * - If the caller is not "from", it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If "to" refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to "safeTransferFrom(from, to, tokenId, '')".
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers "tokenId" from "from" to "to".
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must be owned by "from".
     * - If the caller is not "from", it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to "to" to transfer "tokenId" token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - "tokenId" must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove "operator" as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The "operator" cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the "operator" is allowed to manage all of the assets of "owner".
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for "tokenId" token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in "fromTokenId" to "toTokenId"
     * (inclusive) is transferred from "from" to "to", as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// File: ERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from "_startTokenId()".
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a "--via-ir" bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of "numberMinted" in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of "numberBurned" in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of "aux" in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for "aux".
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of "startTimestamp" in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the "burned" bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the "nextInitialized" bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the "nextInitialized" bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of "extraData" in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for "extraData".
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum "quantity" that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The "Transfer" event signature is given by:
    // "keccak256(bytes("Transfer(address,address,uint256)"))".
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   "addr"
    // - [160..223] "startTimestamp"
    // - [224]      "burned"
    // - [225]      "nextInitialized"
    // - [232..255] "extraData"
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    "balance"
    // - [64..127]  "numberMinted"
    // - [128..191] "numberBurned"
    // - [192..255] "aux"
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than "_currentIndex - _startTokenId()" times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as "_currentIndex" does not decrement,
        // and it is initialized to "_startTokenId()".
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in "owner"'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by "owner".
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of "owner".
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for "owner". (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for "owner". (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast "aux" with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * "interfaceId". See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. "bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)")
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for "tokenId" token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the "baseURI" and the "tokenId". Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked "TokenOwnership" struct at "index".
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at "index" for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of "tokenId".
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. "ownership.addr != address(0) && ownership.burned == false")
                        // before an unintialized ownership slot
                        // (i.e. "ownership.addr == address(0) && ownership.burned == false")
                        // Hence, "curr" will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked "TokenOwnership" struct from "packed".
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask "owner" to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // "owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags".
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the "nextInitialized" flag set if "quantity" equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the "nextInitialized" flag.
        assembly {
            // "(quantity == 1) << _BITPOS_NEXT_INITIALIZED".
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to "to" to transfer "tokenId" token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - "tokenId" must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove "operator" as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The "operator" cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the "operator" is allowed to manage all of the assets of "owner".
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether "tokenId" exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether "msgSender" is equal to "approvedAddress" or "owner".
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask "owner" to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask "msgSender" to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // "msgSender == owner || msgSender == approvedAddress".
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of "tokenId".
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to "approvedAddress = _tokenApprovals[tokenId].value".
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers "tokenId" from "from" to "to".
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must be owned by "from".
     * - If the caller is not "from", it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to "delete _tokenApprovals[tokenId]".
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as "tokenId" would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: "balance -= 1".
            ++_packedAddressData[to]; // Updates: "balance += 1".

            // Updates:
            // - "address" to the next owner.
            // - "startTimestamp" to the timestamp of transfering.
            // - "burned" to "false".
            // - "nextInitialized" to "true".
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. "nextInitialized == false") .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for "ownerOf(tokenId + 1)".
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to "safeTransferFrom(from, to, tokenId, '')".
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers "tokenId" token from "from" to "to".
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must exist and be owned by "from".
     * - If the caller is not "from", it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If "to" refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * "startTokenId" - the first token ID to be transferred.
     * "quantity" - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When "from" and "to" are both non-zero, "from"'s "tokenId" will be
     * transferred to "to".
     * - When "from" is zero, "tokenId" will be minted for "to".
     * - When "to" is zero, "tokenId" will be burned by "from".
     * - "from" and "to" are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * "startTokenId" - the first token ID to be transferred.
     * "quantity" - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When "from" and "to" are both non-zero, "from"'s "tokenId" has been
     * transferred to "to".
     * - When "from" is zero, "tokenId" has been minted for "to".
     * - When "to" is zero, "tokenId" has been burned by "from".
     * - "from" and "to" are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * "from" - Previous owner of the given token ID.
     * "to" - Target address that will receive the token.
     * "tokenId" - Token ID to be transferred.
     * "_data" - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints "quantity" tokens and transfers them to "to".
     *
     * Requirements:
     *
     * - "to" cannot be the zero address.
     * - "quantity" must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // "balance" and "numberMinted" have a maximum limit of 2**64.
        // "tokenId" has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - "balance += quantity".
            // - "numberMinted += quantity".
            //
            // We can directly add to the "balance" and "numberMinted".
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - "address" to the owner.
            // - "startTimestamp" to the timestamp of minting.
            // - "burned" to "false".
            // - "nextInitialized" to "quantity == 1".
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the "Transfer" event for gas savings.
            // The duplicated "log4" removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask "to" to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the "Transfer" event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // "address(0)".
                    toMasked, // "to".
                    startTokenId // "tokenId".
                )

                // The "iszero(eq(,))" check ensures that large values of "quantity"
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the "iszero" away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the "Transfer" event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints "quantity" tokens and transfers them to "to".
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - "to" cannot be the zero address.
     * - "quantity" must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for "quantity" to be below the limit.
        unchecked {
            // Updates:
            // - "balance += quantity".
            // - "numberMinted += quantity".
            //
            // We can directly add to the "balance" and "numberMinted".
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - "address" to the owner.
            // - "startTimestamp" to the timestamp of minting.
            // - "burned" to "false".
            // - "nextInitialized" to "quantity == 1".
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints "quantity" tokens and transfers them to "to".
     *
     * Requirements:
     *
     * - If "to" refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - "quantity" must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to "_safeMint(to, quantity, '')".
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to "_burn(tokenId, false)".
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys "tokenId".
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to "delete _tokenApprovals[tokenId]".
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as "tokenId" would have to be 2**256.
        unchecked {
            // Updates:
            // - "balance -= 1".
            // - "numberBurned += 1".
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to "packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;".
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - "address" to the last owner.
            // - "startTimestamp" to the timestamp of burning.
            // - "burned" to "true".
            // - "nextInitialized" to "true".
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. "nextInitialized == false") .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for "ownerOf(tokenId + 1)".
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data "index".
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast "extraData" with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit "extraData" field.
     * Intended to be overridden by the cosumer contract.
     *
     * "previousExtraData" - the value of "extraData" before transfer.
     *
     * Calling conditions:
     *
     * - When "from" and "to" are both non-zero, "from"'s "tokenId" will be
     * transferred to "to".
     * - When "from" is zero, "tokenId" will be minted for "to".
     * - When "to" is zero, "tokenId" will be burned by "from".
     * - "from" and "to" are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to "msg.sender").
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the "str" to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing "temp" until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// File: MasterV2.sol
 
pragma solidity ^0.8.24;

// Define custom errors at the contract level
error MintInactive();
error Unauthorized(address caller);
error InvalidOperation(string reason);
error ExceedsMaxSupply(uint256 requested, uint256 available);
error InsufficientEther(uint256 required, uint256 provided);
error ExceedsMaxPerWallet(uint256 requested, uint256 allowed); 
 
error ExceedsMaxMintGroupSupply(uint256 requested, uint256 available); // Remove when allowlist is off
error PresaleInactive(uint256 mintId); // Remove when allowlist is off
error NotInPresale(address caller, uint256 mintId); // Remove when allowlist is off
error MintGroupDoesNotExist(uint256 mintId); // Remove when allowlist is off
error ArrayLengthMismatch(); // Remove when allowlist is off 
 

contract WAGMIPA_Whitelist_Ticket is ERC721A, Ownable , ERC2981 {
    event BatchMetadataUpdate(
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId
    );
    event TokensMinted(
        address indexed recipient,
        uint256 amount,
        uint256 mintId
        , address affiliate 
    );
    
    event TokensDelegateMinted(
        address indexed vault,
        address indexed hotWallet,
        uint256 amount,
        uint256 mintId
        , address affiliate 
    );
    
    event SalePriceChanged(uint256 indexed mintId, uint256 newPrice);

    //Base variables
    mapping(address => uint256) private pendingBalances;
    uint256 public maxSupply;
    uint256 public threeDollarsEth;
    bool public mintLive = false;
    string public baseURI;
    address public feeAddress;
    address public ownerPayoutAddress;

    
    //Affiliates variables
    uint256 public affiliatePercentage;
    
  
    //Map pairings.
    mapping(uint256 => uint256) public maxMintPerWallet;  
    mapping(uint256 => uint256) public mintPrice; 
    mapping(uint256 => uint256) public maxSupplyPerMintGroup; 
    mapping(uint256 => uint256) public mintGroupMints;  
    mapping(uint256 => mapping(address => bool)) public presale; 
    mapping(uint256 => bool) public presaleActive; 
    uint256 public presaleCount = 0; //Counter to get total whitelists. Remove when allowlist is off
    uint256[] public activeMintGroups; //Array to get all active mint groups. Remove when allowlist is off

    constructor(
        //Base variables
        string memory name,
        string memory symbol,
        address _ownerPayoutAddress,
        string memory _initialBaseURI,
        uint256 _maxSupply,
        uint256 _threeDollarsEth,
        //Allowlist variables
        uint256[] memory _maxMintPerWallet, // Turn into uint256 if allowlist is off
        uint256[] memory _maxSupplyPerMintGroup, // Remove if allowlist is off
        uint256[] memory _mintPrice // Turn into uint256 if allowlist is off
         
        //Royalties variables
        ,uint96 _royaltyPercentage // Remove if royalties is off
        
        
        
    ) ERC721A(name, symbol) Ownable(msg.sender) {
        //Error handler to check if map pairs each other. Remove if allowlist is off
        if (
            _maxMintPerWallet.length != _maxSupplyPerMintGroup.length &&
            _maxMintPerWallet.length != _mintPrice.length 
            
        ) {
            revert ArrayLengthMismatch();
        }

        //Remove if allowlist is off
        uint256 totalMaxSupplyPerMintGroup = 0;
        for (uint256 i = 0; i < _maxSupplyPerMintGroup.length; i++) {
            totalMaxSupplyPerMintGroup += _maxSupplyPerMintGroup[i];
            maxSupplyPerMintGroup[i] = _maxSupplyPerMintGroup[i];
            maxMintPerWallet[i] = _maxMintPerWallet[i];
            mintPrice[i] = _mintPrice[i];
            mintGroupMints[i] = 0;
            activeMintGroups.push(i); 
             
        }

        //Checker if max supply per mint group exceeds total max supply. Remove if allowlist is off
        if (totalMaxSupplyPerMintGroup > _maxSupply) {
            revert InvalidOperation({
                reason: "Max supply per mint group exceeds total max supply"
            });
        }
        
        //Base variables
        maxSupply = _maxSupply;
        threeDollarsEth = _threeDollarsEth;
        baseURI = _initialBaseURI;
        ownerPayoutAddress = _ownerPayoutAddress;
        feeAddress = 0x428Deb81A93BeD820068724eb1fCc7503d71e417;

        
        // Setting up royalties and affiliate percentage
        _setDefaultRoyalty(_ownerPayoutAddress, _royaltyPercentage);
        
        
        affiliatePercentage = 0; // Adjusting this calculation as needed
        
    }


    //===================================START Allowlist Functions===================================//
    // Initializer for new mint groups for all maps
    function initializeNewMintGroup(uint256 mintId) internal {
        mintPrice[mintId] = 0;
        maxMintPerWallet[mintId] = 0;
        maxSupplyPerMintGroup[mintId] = 0;
        mintGroupMints[mintId] = 0;
        activeMintGroups.push(mintId);
        
    }

    function isMintGroupActive(uint256 mintId) private view returns (bool) {
        for (uint256 i = 0; i < activeMintGroups.length; i++) {
            if (activeMintGroups[i] == mintId) {
                return true;
            }
        }
        return false;
    }

    // Changes the max mint per mint group. Only the contract owner can call this function. Remove this function if allowlist is off
    function setNewMaxPerMintGroup(uint256 mintId, uint256 newMax)
        public
        onlyOwner
    {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }

        // Checker if new max exceeds total supply
        uint256 totalMaxMintPerMG = 0;
        for (uint256 i = 0; i < activeMintGroups.length; i++) {
            if (activeMintGroups[i] == mintId) {
                totalMaxMintPerMG += newMax; // Use the new max for the specified mintId
            } else {
                totalMaxMintPerMG += maxSupplyPerMintGroup[activeMintGroups[i]];
            }
        }

        if (totalMaxMintPerMG > maxSupply) {
            revert InvalidOperation({
                reason: "New supply per mint group exceeds total supply."
            });
        }

        maxSupplyPerMintGroup[mintId] = newMax;
    }

    // Add to presale
    function addTopresale(address[] memory newPresale, uint256 mintId)
        external
        onlyOwner
    {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }

        for (uint256 i = 0; i < newPresale.length; i++) {
            presale[mintId][newPresale[i]] = true;
            presaleCount = presaleCount + 1;
        }
    }

    // Remove from presale
    function removeFrompresale(address[] memory removePresale, uint256 mintId)
        external
        onlyOwner
    {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }

        for (uint256 i = 0; i < removePresale.length; i++) {
            presale[mintId][removePresale[i]] = false;
            if (presaleCount > 0) {
                presaleCount = presaleCount - 1;
            }
        }
    }

    // Control the presale status
    function stopOrStartpresaleMint(bool presaleStatus, uint256 mintId)
        public
        onlyOwner
    {
        //Checks if mintId already exists inside activeMintGroups.
        if (!isMintGroupActive(mintId)) {
            revert MintGroupDoesNotExist({mintId: mintId});
        }
        presaleActive[mintId] = presaleStatus;
    }
    //===================================END Allowlist Functions===================================//

    // Sets the maximum number of tokens that can be minted in a batch. Only the contract owner can call this function.
    function setMaxMintPerWallet(
        uint256 newMaxMintPerWallet, uint256 mintGroupId
    ) public onlyOwner {
       maxMintPerWallet[mintGroupId] = newMaxMintPerWallet;
    }

    // Changes the price to mint a token. Only the contract owner can call this function.
    function changeSalePrice(uint256 newMintPrice, uint256 mintId)
        public
        onlyOwner
    {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }
        mintPrice[mintId] = newMintPrice;
        emit SalePriceChanged(mintId, newMintPrice);
    }

    
    
    
    //===================================START Affiliate Functions===================================//
    // Changes the affiliate percentage. Only the contract owner can call this function. Note: 1000% = 10%
    function setAffiliatePercentage(uint256 _percentageOfMint)
        public
        onlyOwner
    {
        affiliatePercentage = _percentageOfMint;
    }

    // Allows the affiliate to withdraw their portion of the mint funds in ETH.
    function withdrawAffiliateMintFunds() public {
        uint256 affiliateBalance = pendingBalances[msg.sender];
        if (affiliateBalance < 0) {
            revert InvalidOperation({reason: "No funds to withdraw"});
        }

        // Reset the pending balance for the affiliate to zero
        pendingBalances[msg.sender] = 0;

        // Transfer the funds
        (bool success, ) = payable(msg.sender).call{value: affiliateBalance}(
            ""
        );

        if (!success) {
            revert InvalidOperation({reason: "Withdraw Transfer Failed"});
        }
    }

    //===================================END Affiliate Functions===================================//
    
    //===================================START Mint Functions===================================//
    // Cleaner and more efficient batchMint function
    function batchMint(
        uint256 amount,
        uint256 mintId // Remove if allowlist is off
        , address affiliate // Remove if affilaites is off
    ) external payable {
        // Pre-conditions checks
        if (!mintLive) {
            revert MintInactive();
        }

         
        if (mintLive && !presaleActive[mintId]) {
            revert PresaleInactive({mintId: mintId});
        }
        
        if (mintId != 0) {
            if (presale[mintId][msg.sender] == false) {
                revert NotInPresale({caller: msg.sender, mintId: mintId});
            }
            if (
                mintGroupMints[mintId] + amount > maxSupplyPerMintGroup[mintId]
            ) {
                revert ExceedsMaxMintGroupSupply({
                    requested: amount,
                    available: maxSupplyPerMintGroup[mintId] -
                        mintGroupMints[mintId]
                });
            }
        }
       

        if (amount + _numberMinted(msg.sender) > maxMintPerWallet[mintId]) {
            revert ExceedsMaxPerWallet({
                requested: amount,
                allowed: maxMintPerWallet[mintId] - _numberMinted(msg.sender)
            });
        }

        if (totalSupply() + amount > maxSupply) {
            revert ExceedsMaxSupply({
                requested: amount,
                available: maxSupply - totalSupply()
            });
        }

        // Adjusted for a 3% fee
        uint256 totalCost = mintPrice[mintId] * amount;
        uint256 feeAmount = ((totalCost * 3) / 100) +
            (threeDollarsEth * amount); // 3% + 3$ fee
        uint256 totalCostWithFee = totalCost + feeAmount;

        if (msg.value < totalCostWithFee) {
            revert InsufficientEther({
                required: totalCostWithFee,
                provided: msg.value
            });
        }

                
        // Affiliate handling
        if (affiliate != address(0) && affiliate != msg.sender) {
            uint256 affiliateAmount = (totalCost * affiliatePercentage) / 100;
            pendingBalances[affiliate] += affiliateAmount;
            totalCost -= affiliateAmount; // Adjust total cost after affiliate share
        }

        // Update balances
        pendingBalances[ownerPayoutAddress] += totalCost; // To owner
        pendingBalances[feeAddress] += feeAmount; // Fee portion

        
        

        // Finalize minting
        mintGroupMints[mintId] += amount;
        _safeMint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount, mintId, affiliate);

        // Refund excess Ether, if any
        uint256 excess = msg.value - totalCostWithFee;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    //==================START Delegate Functions==================//
    address constant DELEGATE_REGISTRY =
        0x00000000000000447e69651d841bD8D104Bed493;

    mapping(address => uint256) private delegatedContractMints;

    function delegatedMint(
        uint256 amount,
        uint256 mintId
      , address affiliate
        , address vault
    ) external payable {
        if (
            !IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForContract(
                msg.sender,
                vault,
                address(this),
                ""
            )
        ) {
            revert Unauthorized(vault);
        }

        // Pre-conditions checks
        if (!mintLive) {
            revert MintInactive();
        }

            
        if (mintLive && !presaleActive[mintId]) {
            revert PresaleInactive({mintId: mintId});
        } 
        if (mintId != 0) {
            if (presale[mintId][vault] == false) {
                revert NotInPresale({caller: vault, mintId: mintId});
            }
            if (
                mintGroupMints[mintId] + amount > maxSupplyPerMintGroup[mintId]
            ) {
                revert ExceedsMaxMintGroupSupply({
                    requested: amount,
                    available: maxSupplyPerMintGroup[mintId] -
                        mintGroupMints[mintId]
                });
            }
        }

        // Checker for connected wallet
        if (amount + _numberMinted(msg.sender) > maxMintPerWallet[mintId]) {
            revert ExceedsMaxPerWallet({
                requested: amount,
                allowed: maxMintPerWallet[mintId] - _numberMinted(msg.sender)
            });
        }
        
        // Checker for vault wallet
        if (amount + delegatedContractMints[vault] > maxMintPerWallet[mintId]) {
            revert ExceedsMaxPerWallet({
                requested: amount,
                allowed: maxMintPerWallet[mintId] - delegatedContractMints[vault]
            });
        }

        if (totalSupply() + amount > maxSupply) {
            revert ExceedsMaxSupply({
                requested: amount,
                available: maxSupply - totalSupply()
            });
        }

         // Adjusted for a 3% fee
        uint256 totalCost = mintPrice[mintId] * amount;
        uint256 feeAmount = ((totalCost * 3) / 100) +
            (threeDollarsEth * amount); // 3% + 3$ fee
        uint256 totalCostWithFee = totalCost + feeAmount;

        if (msg.value < totalCostWithFee) {
            revert InsufficientEther({
                required: totalCostWithFee,
                provided: msg.value
            });
        }

                
                // Affiliate handling
                if (affiliate != address(0) && affiliate != msg.sender && affiliate != vault) {
                    uint256 affiliateAmount = (totalCost * affiliatePercentage) / 100;
                    pendingBalances[affiliate] += affiliateAmount;
                    totalCost -= affiliateAmount; // Adjust total cost after affiliate share
                } 

        // Update balances
        pendingBalances[ownerPayoutAddress] += totalCost; // To owner
        pendingBalances[feeAddress] += feeAmount; // Fee portion

        
        
        // Finalize minting
        mintGroupMints[mintId] += amount;
        delegatedContractMints[vault] += amount;
        _safeMint(msg.sender, amount);
        emit TokensDelegateMinted(vault, msg.sender, amount, mintId, affiliate);

        // Refund excess Ether, if any
        uint256 excess = msg.value - totalCostWithFee;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    //==================END Delegate Functions==================//
    
    //===================================END Mint Functions===================================//
    //===================================START Base Functions===================================//

    // Changes the minting status. Only the contract owner can call this function.
    function changeMintStatus(bool status) public onlyOwner {
        if (mintLive == status) {
            revert InvalidOperation({
                reason: "Mint status is already the one you entered"
            });
        }
        mintLive = status;
    }

    // Sets the base URI for the token metadata. Only the contract owner can call this function.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BatchMetadataUpdate(1, type(uint256).max); // Signal that all token metadata has been updated
    }


    // Allows the contract owner to withdraw the funds that have been paid into the contract.
    function withdrawMintFunds() public onlyOwner {
        if (pendingBalances[ownerPayoutAddress] <= 0) {
            revert InvalidOperation({reason: "There is nothing to withdraw"});
        }
        uint256 ownerPayout = pendingBalances[ownerPayoutAddress];
        uint256 fee = pendingBalances[feeAddress];

        pendingBalances[ownerPayoutAddress] = 0;
        pendingBalances[feeAddress] = 0;

        (bool success1, ) = payable(ownerPayoutAddress).call{
            value: ownerPayout
        }("");
        (bool success2, ) = payable(feeAddress).call{value: fee}("");

        if (!success1 && !success2) {
            revert InvalidOperation({reason: "Withdraw Transfer Failed"});
        }
    }

    // Allows the fee address to withdraw their portion of the funds.
    function withdrawFeeFunds() public {
        if (msg.sender != feeAddress) {
            revert Unauthorized({caller: msg.sender});
        }
        if (pendingBalances[feeAddress] <= 0) {
            revert InvalidOperation({reason: "There is nothing to withdraw"});
        }

        uint256 fee = pendingBalances[feeAddress];
        pendingBalances[feeAddress] = 0;

        (bool success, ) = payable(feeAddress).call{value: fee}("");
        if (!success) {
            revert InvalidOperation({reason: "Withdraw Transfer Failed"});
        }
    }

    // Returns the base URI for the token metadata.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Checks the balance pending withdrawal for the sender.
    function checkPendingBalance() public view returns (uint256) {
        return pendingBalances[msg.sender];
    }

    // Overrides the start token ID function from the ERC721A contract.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Overrides the supports interface function to add support for the ERC721A interface.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    //===================================END Base Functions===================================//
}