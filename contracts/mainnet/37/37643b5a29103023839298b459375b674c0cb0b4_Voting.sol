/**
 *Submitted for verification at Arbiscan.io on 2024-05-11
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

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


// File @openzeppelin/contracts/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC721.sol)

pragma solidity ^0.8.20;


// File contracts/voting.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

struct VoteResult {
    uint256 voteOption;
    uint256 voteCount;
}

struct VotingS {
        uint256 votingId;
        uint256 startTime;
        uint256 endTime;
        uint256 voteCount;
}

struct VotingStatus {
        VotingS properties;
        string[] uris;
        VoteResult[] result;
        address nftContract;
}

/// @title A voting contract with IERC721 gated voting
/// @author glbkst
/// @notice URIs are app dependent, therefore rather generic.
/// If voting makes sense on-chain will depend probably.
/// One point is, that there could be more than one UI which is
/// using then the decentralized feature of an EVM contract.
/// There is no protection against transfers of tokens during
/// the voting, because this can probably detected after the voting
/// in a more reliable way and keeps it simpler.
contract Voting is Ownable {

    /// @notice if enableVoting() isn't called before vote
    error VotingNotEnabled();
    /// @notice if no URI(s) are set before vote
    error VotingNFTIsNotSet();
    /// @notice if user has no NFT to vote NFT contract address is returned
    error NotPermittedToVote(address votingNFT);
    /// @notice if msg.sender already voted
    error AlreadyVoted();
    /// @notice option must in range of set URIs
    error UnexistingVoteOption(uint256 numberOfOptions); 
    /// @notice range too large
    error OverRangeLimit();


    event VotingStart(uint256 votingId);
    event VotingEnd(uint256 votingId);
    event Voted(uint256 votingId, address voter);
   
    VotingS private _votingStatus = VotingS(0,0,0,0);
    mapping (uint256 => string) private _votingUris;
    uint256 private _numberOfVotingOptions = 0;
    IERC721 private _allowed4votingNFT = IERC721(address(0));
    bool private _votingIsEnabled = false;
    struct Vote {
        uint256 voteOptionNumber;
        uint256 votingId;
    }
    mapping (uint256 => Vote) private _votes;
    mapping (address => uint256) private _voted;

    constructor(address initialOwner) Ownable(initialOwner) {
    }

    /// @param uris metadata uri to display for voting options
    ///     the metadata structure can be app dependent or simply
    ///     an image link.
    function setVotingUris(string[] memory uris) external onlyOwner {
        cleanupVotingUris();
        for(uint256 i=0;i < uris.length;++i){
            _votingUris[i] = uris[i];
        }
        _numberOfVotingOptions = uris.length;
    }

    /// @notice return the set URIs
    function getVotingUris() private view returns(string[] memory uris) {
        uris = new string[](_numberOfVotingOptions);
        for (uint256 i = 0; i < _numberOfVotingOptions; i++) {
            uris[i] = _votingUris[i];
        }
    }

    function getVotingStatus() external view returns(VotingStatus memory status) {
        status = VotingStatus( _votingStatus, getVotingUris(), votingResult(), address(_allowed4votingNFT));
    }

    function cleanupVotingUris() private {
        if(_numberOfVotingOptions == 0) {
            return;
        }
        for(uint256 i=0;i < _numberOfVotingOptions;++i){
            delete _votingUris[i];
        }
    }

    /// @param contractAddress address of NFT contract which owners are
    /// allowed to vote
    function setVotingNFT(address contractAddress) external onlyOwner {
        _allowed4votingNFT = IERC721(contractAddress);
    }

    function getNFTOwners(uint256 startId, uint256 endId, address cont) external view returns (address[] memory nftOwners, uint256 lengthInfo) {
        if( endId == 0) endId = startId + 25;
        if(endId - startId > 25) revert OverRangeLimit();
        uint256 i;
        uint256 count = 0;        
        for(i=startId;i <= endId;++i) {
            (, bool isErr) = tryOwnerOf(i, cont);
            if(!isErr) {
                ++count;
            }else if(i==startId) {
                return (new address[](0), 0);
            }else {
                break;
            }
        }
        address[] memory owners = new address[](count);
        for(uint256 j=startId;j < count+startId;++j) {
            (address o, bool isErr) = tryOwnerOf(j, cont);
            if(!isErr) {
                owners[j-startId] = o;
            }
        }
        return (owners, count);
    }

    function tryOwnerOf(uint256 tokenId, address cont) private view returns (address ow, bool isErr) {

        try IERC721(cont).ownerOf(tokenId) returns (address a) {
            return( a, false );
        }catch { 
            return( address(0), true);
        }
    }

    /// @notice start a new vote, initial state is disabled
    function enableVoting() external onlyOwner {
        _votingStatus.startTime = block.timestamp;
        _votingStatus.endTime = 0;
        _votingIsEnabled = true;
        ++_votingStatus.votingId;
        _votingStatus.voteCount = 0;
        emit VotingStart(_votingStatus.votingId);
    }

    /// @notice end a vote
    function disableVoting() external onlyOwner {
        _votingStatus.endTime = block.timestamp;
        _votingIsEnabled = false;
        emit VotingEnd(_votingStatus.votingId);
    }

    function checkNFTIsSet() private view returns(bool) {
        if(_allowed4votingNFT != IERC721(address(0))) {
            return true;
        }
        return false;
    }

    /// @notice public vote API
    /// @param voteOption option to vote on, the range is 1-n with n = number of URIs
    function vote(uint256 voteOption) external {
        if(!_votingIsEnabled) revert VotingNotEnabled();
        if(voteOption < 1 || voteOption > _numberOfVotingOptions) revert UnexistingVoteOption(_numberOfVotingOptions);
        if(!checkNFTIsSet()) revert VotingNFTIsNotSet();
        address sender = msg.sender;
        if(_allowed4votingNFT.balanceOf(sender) == 0) revert NotPermittedToVote(address(_allowed4votingNFT));
        if(_voted[sender] == _votingStatus.votingId) revert AlreadyVoted();

        Vote memory newVote = Vote(voteOption-1, _votingStatus.votingId);
        
        _votes[++_votingStatus.voteCount] = newVote;
        _voted[sender] = _votingStatus.votingId;
        emit Voted(_votingStatus.votingId, sender);
    }

    /// @notice get array of vote results the lenght of the array is always equal to the 
    /// number of URIs regardless of their votes, the order is intended to match the URI ordering.
    /// The contract does not check or match URIs and option number obviously the intention is
    /// that these match ofc by any UI.
    function votingResult() private view returns (VoteResult[] memory voteResults) {
        voteResults = new VoteResult[](_numberOfVotingOptions);
        for(uint256 j=0;j < _numberOfVotingOptions;j++){
            voteResults[j] = VoteResult(j+1, 0);
        }

        for(uint256 i=1;i <= _votingStatus.voteCount;i++) {
            Vote memory aVote = _votes[i];
            voteResults[aVote.voteOptionNumber].voteCount++;
        }
    }

}