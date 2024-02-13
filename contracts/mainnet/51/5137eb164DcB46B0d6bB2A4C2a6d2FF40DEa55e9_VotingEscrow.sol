/**
 *Submitted for verification at Arbiscan.io on 2024-02-09
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IVeArtProxy {
    /// @dev Art configuration
    struct Config {
        // NFT metadata variables
        int256 _tokenId;
        int256 _balanceOf;
        int256 _lockedEnd;
        int256 _lockedAmount;
        // Line art variables
        int256 shape;
        uint256 palette;
        int256 maxLines;
        int256 dash;
        // Randomness variables
        int256 seed1;
        int256 seed2;
        int256 seed3;
    }

    /// @dev Individual line art path variables.
    struct lineConfig {
        bytes8 color;
        uint256 stroke;
        uint256 offset;
        uint256 offsetHalf;
        uint256 offsetDashSum;
        uint256 pathLength;
    }

    /// @dev Represents an (x,y) coordinate in a line.
    struct Point {
        int256 x;
        int256 y;
    }

    /// @notice Generate a SVG based on veNFT metadata
    /// @param _tokenId Unique veNFT identifier
    /// @return output SVG metadata as HTML tag
    function tokenURI(uint256 _tokenId) external view returns (string memory output);

    /// @notice Generate only the foreground <path> elements of the line art for an NFT (excluding SVG header), for flexibility purposes.
    /// @param _tokenId Unique veNFT identifier
    /// @return output Encoded output of generateShape()
    function lineArtPathsOnly(uint256 _tokenId) external view returns (bytes memory output);

    /// @notice Generate the master art config metadata for a veNFT
    /// @param _tokenId Unique veNFT identifier
    /// @return cfg Config struct
    function generateConfig(uint256 _tokenId) external view returns (Config memory cfg);

    /// @notice Generate the points for two stripe lines based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of line drawn
    /// @return Line (x, y) coordinates of the drawn stripes
    function twoStripes(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of circles drawn
    /// @return Line (x, y) coordinates of the drawn circles
    function circles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for interlocking circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of interlocking circles drawn
    /// @return Line (x, y) coordinates of the drawn interlocking circles
    function interlockingCircles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for corners based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of corners drawn
    /// @return Line (x, y) coordinates of the drawn corners
    function corners(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a curve based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of curve drawn
    /// @return Line (x, y) coordinates of the drawn curve
    function curves(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a spiral based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of spiral drawn
    /// @return Line (x, y) coordinates of the drawn spiral
    function spiral(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for an explosion based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of explosion drawn
    /// @return Line (x, y) coordinates of the drawn explosion
    function explosion(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a wormhole based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of wormhole drawn
    /// @return Line (x, y) coordinates of the drawn wormhole
    function wormhole(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts (interfaces/IERC6372.sol)

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

/// Modified IVotes interface for tokenId based voting
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the amount of votes that `tokenId` had at a specific moment in the past.
     *      If the account passed in is not the owner, returns 0.
     */
    function getPastVotes(address account, uint256 tokenId, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `tokenId` has chosen. Can never be equal to the delegator's `tokenId`.
     *      Returns 0 if not delegated.
     */
    function delegates(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(uint256 delegator, uint256 delegatee) external;

    /**
     * @dev Delegates votes from `delegator` to `delegatee`. Signer must own `delegator`.
     */
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IVotingEscrow is IVotes, IERC4906, IERC6372, IERC721Metadata {
    struct LockedBalance {
        int128 amount;
        uint256 end;
        bool isPermanent;
    }

    struct UserPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanent;
    }

    struct GlobalPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanentLockBalance;
    }

    /// @notice A checkpoint for recorded delegated voting weights at a certain timestamp
    struct Checkpoint {
        uint256 fromTimestamp;
        address owner;
        uint256 delegatedBalance;
        uint256 delegatee;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    /// @dev Different types of veNFTs:
    /// NORMAL  - typical veNFT
    /// LOCKED  - veNFT which is locked into a MANAGED veNFT
    /// MANAGED - veNFT which can accept the deposit of NORMAL veNFTs
    enum EscrowType {
        NORMAL,
        LOCKED,
        MANAGED
    }

    error AlreadyVoted();
    error AmountTooBig();
    error ERC721ReceiverRejectedTokens();
    error ERC721TransferToNonERC721ReceiverImplementer();
    error InvalidNonce();
    error InvalidSignature();
    error InvalidSignatureS();
    error InvalidManagedNFTId();
    error LockDurationNotInFuture();
    error LockDurationTooLong();
    error LockExpired();
    error LockNotExpired();
    error NoLockFound();
    error NonExistentToken();
    error NotApprovedOrOwner();
    error NotDistributor();
    error NotEmergencyCouncilOrGovernor();
    error NotGovernor();
    error NotGovernorOrManager();
    error NotManagedNFT();
    error NotManagedOrNormalNFT();
    error NotLockedNFT();
    error NotNormalNFT();
    error NotPermanentLock();
    error NotOwner();
    error NotTeam();
    error NotVoter();
    error OwnershipChange();
    error PermanentLock();
    error SameAddress();
    error SameNFT();
    error SameState();
    error SplitNoOwner();
    error SplitNotAllowed();
    error SignatureExpired();
    error TooManyTokenIDs();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroBalance();

    event Deposit(
        address indexed provider,
        uint256 indexed tokenId,
        DepositType indexed depositType,
        uint256 value,
        uint256 locktime,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 indexed tokenId, uint256 value, uint256 ts);
    event LockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event UnlockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Merge(
        address indexed _sender,
        uint256 indexed _from,
        uint256 indexed _to,
        uint256 _amountFrom,
        uint256 _amountTo,
        uint256 _amountFinal,
        uint256 _locktime,
        uint256 _ts
    );
    event Split(
        uint256 indexed _from,
        uint256 indexed _tokenId1,
        uint256 indexed _tokenId2,
        address _sender,
        uint256 _splitAmount1,
        uint256 _splitAmount2,
        uint256 _locktime,
        uint256 _ts
    );
    event CreateManaged(
        address indexed _to,
        uint256 indexed _mTokenId,
        address indexed _from,
        address _lockedManagedReward,
        address _freeManagedReward
    );
    event DepositManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event WithdrawManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event SetAllowedManager(address indexed _allowedManager);

    // State variables
    /// @notice Address of Meta-tx Forwarder
    function forwarder() external view returns (address);

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of token (PRFCT) used to create a veNFT
    function token() external view returns (address);

    /// @notice Address of RewardsDistributor.sol
    function distributor() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of Protocol Team multisig
    function team() external view returns (address);

    /// @notice Address of art proxy used for on-chain art generation
    function artProxy() external view returns (address);

    /// @dev address which can create managed NFTs
    function allowedManager() external view returns (address);

    /// @dev Current count of token
    function tokenId() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping of token id to escrow type
    ///      Takes advantage of the fact default value is EscrowType.NORMAL
    function escrowType(uint256 tokenId) external view returns (EscrowType);

    /// @dev Mapping of token id to managed id
    function idToManaged(uint256 tokenId) external view returns (uint256 managedTokenId);

    /// @dev Mapping of user token id to managed token id to weight of token id
    function weights(uint256 tokenId, uint256 managedTokenId) external view returns (uint256 weight);

    /// @dev Mapping of managed id to deactivated state
    function deactivated(uint256 tokenId) external view returns (bool inactive);

    /// @dev Mapping from managed nft id to locked managed rewards
    ///      `token` denominated rewards (rebases/rewards) stored in locked managed rewards contract
    ///      to prevent co-mingling of assets
    function managedToLocked(uint256 tokenId) external view returns (address);

    /// @dev Mapping from managed nft id to free managed rewards contract
    ///      these rewards can be freely withdrawn by users
    function managedToFree(uint256 tokenId) external view returns (address);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create managed NFT (a permanent lock) for use within ecosystem.
    /// @dev Throws if address already owns a managed NFT.
    /// @return _mTokenId managed token id.
    function createManagedLockFor(address _to) external returns (uint256 _mTokenId);

    /// @notice Delegates balance to managed nft
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    ///         Permanent locks that are deposited will automatically unlock.
    /// @dev Managed nft will remain max-locked as long as there is at least one
    ///      deposit or withdrawal per week.
    ///      Throws if deposit nft is managed.
    ///      Throws if recipient nft is not managed.
    ///      Throws if deposit nft is already locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited
    /// @param _mTokenId tokenId of managed NFT that will receive the deposit
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Retrieves locked rewards and withdraws balance from managed nft.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    /// @dev Throws if NFT not locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Permit one address to call createManagedLockFor() that is not Voter.governor()
    function setAllowedManager(address _allowedManager) external;

    /// @notice Set Managed NFT state. Inactive NFTs cannot be deposited into.
    /// @param _mTokenId managed nft state to set
    /// @param _state true => inactive, false => active
    function setManagedState(uint256 _mTokenId, bool _state) external;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function setTeam(address _team) external;

    function setArtProxy(address _proxy) external;

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from owner address to mapping of index to tokenId
    function ownerToNFTokenIdList(address _owner, uint256 _index) external view returns (uint256 _tokenId);

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function getApproved(uint256 _tokenId) external view returns (address operator);

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Check whether spender is owner or an approved user for a given veNFT
    /// @param _spender .
    /// @param _tokenId .
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external;

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total count of epochs witnessed since contract creation
    function epoch() external view returns (uint256);

    /// @notice Total amount of token() deposited
    function supply() external view returns (uint256);

    /// @notice Aggregate permanent locked balances
    function permanentLockBalance() external view returns (uint256);

    function userPointEpoch(uint256 _tokenId) external view returns (uint256 _epoch);

    /// @notice time -> signed slope change
    function slopeChanges(uint256 _timestamp) external view returns (int128);

    /// @notice account -> can split
    function canSplit(address _account) external view returns (bool);

    /// @notice Global point history at a given index
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory);

    /// @notice Get the LockedBalance (amount, end) of a _tokenId
    /// @param _tokenId .
    /// @return LockedBalance of _tokenId
    function locked(uint256 _tokenId) external view returns (LockedBalance memory);

    /// @notice User -> UserPoint[userEpoch]
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory);

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global data to checkpoint
    function checkpoint() external;

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function depositFor(uint256 _tokenId, uint256 _value) external;

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @return TokenId of created veNFT
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256);

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    /// @return TokenId of created veNFT
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external returns (uint256);

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 _tokenId, uint256 _value) external;

    /// @notice Extend the unlock time for `_tokenId`
    ///         Cannot extend lock time of permanent locks
    /// @param _lockDuration New number of seconds until tokens unlock
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock is both expired and not permanent
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    function withdraw(uint256 _tokenId) external;

    /// @notice Merges `_from` into `_to`.
    /// @dev Cannot merge `_from` locks that are permanent or have already voted this epoch.
    ///      Cannot merge `_to` locks that have already expired.
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to merge from.
    /// @param _to VeNFT to merge into.
    function merge(uint256 _from, uint256 _to) external;

    /// @notice Splits veNFT into two new veNFTS - one with oldLocked.amount - `_amount`, and the second with `_amount`
    /// @dev    This burns the tokenId of the target veNFT
    ///         Callable by approved or owner
    ///         If this is called by approved, approved will not have permissions to manipulate the newly created veNFTs
    ///         Returns the two new split veNFTs to owner
    ///         If `from` is permanent, will automatically dedelegate.
    ///         This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///         will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to split.
    /// @param _amount Amount to split from veNFT.
    /// @return _tokenId1 Return tokenId of veNFT with oldLocked.amount - `_amount`.
    /// @return _tokenId2 Return tokenId of veNFT with `_amount`.
    function split(uint256 _from, uint256 _amount) external returns (uint256 _tokenId1, uint256 _tokenId2);

    /// @notice Toggle split for a specific address.
    /// @dev Toggle split for address(0) to enable or disable for all.
    /// @param _account Address to toggle split permissions
    /// @param _bool True to allow, false to disallow
    function toggleSplit(address _account, bool _bool) external;

    /// @notice Permanently lock a veNFT. Voting power will be equal to
    ///         `LockedBalance.amount` with no decay. Required to delegate.
    /// @dev Only callable by unlocked normal veNFTs.
    /// @param _tokenId tokenId to lock.
    function lockPermanent(uint256 _tokenId) external;

    /// @notice Unlock a permanently locked veNFT. Voting power will decay.
    ///         Will automatically dedelegate if delegated.
    /// @dev Only callable by permanently locked veNFTs.
    ///      Cannot unlock if already voted this epoch.
    /// @param _tokenId tokenId to unlock.
    function unlockPermanent(uint256 _tokenId) external;

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the voting power for _tokenId at the current timestamp
    /// @dev Returns 0 if called in the same block as a transfer.
    /// @param _tokenId .
    /// @return Voting power
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    /// @notice Get the voting power for _tokenId at a given timestamp
    /// @param _tokenId .
    /// @param _t Timestamp to query voting power
    /// @return Voting power
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    /// @notice Calculate total voting power at current timestamp
    /// @return Total voting power at current timestamp
    function totalSupply() external view returns (uint256);

    /// @notice Calculate total voting power at a given timestamp
    /// @param _t Timestamp to query total voting power
    /// @return Total voting power at given timestamp
    function totalSupplyAt(uint256 _t) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice See if a queried _tokenId has actively voted
    /// @param _tokenId .
    /// @return True if voted, else false
    function voted(uint256 _tokenId) external view returns (bool);

    /// @notice Set the global state voter and distributor
    /// @dev This is only called once, at setup
    function setVoterAndDistributor(address _voter, address _distributor) external;

    /// @notice Set `voted` for _tokenId to true or false
    /// @dev Only callable by voter
    /// @param _tokenId .
    /// @param _voted .
    function voting(uint256 _tokenId, bool _voted) external;

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of checkpoints for each tokenId
    function numCheckpoints(uint256 tokenId) external view returns (uint48);

    /// @notice A record of states for signing / validating signatures
    function nonces(address account) external view returns (uint256);

    /// @inheritdoc IVotes
    function delegates(uint256 delegator) external view returns (uint256);

    /// @notice A record of delegated token checkpoints for each account, by index
    /// @param tokenId .
    /// @param index .
    /// @return Checkpoint
    function checkpoints(uint256 tokenId, uint48 index) external view returns (Checkpoint memory);

    /// @inheritdoc IVotes
    function getPastVotes(address account, uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @inheritdoc IVotes
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotes
    function delegate(uint256 delegator, uint256 delegatee) external;

    /// @inheritdoc IVotes
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC6372
    function clock() external view returns (uint48);

    /// @inheritdoc IERC6372
    function CLOCK_MODE() external view returns (string memory);
}

interface IVoter {
    error AlreadyVotedOrDeposited();
    error DistributeWindow();
    error FactoryPathNotApproved();
    error GaugeAlreadyKilled();
    error GaugeAlreadyRevived();
    error GaugeExists();
    error GaugeDoesNotExist(address _pool);
    error GaugeNotAlive(address _gauge);
    error InactiveManagedNFT();
    error MaximumVotingNumberTooLow();
    error NonZeroVotes();
    error NotAPool();
    error NotApprovedOrOwner();
    error NotGovernor();
    error NotEmergencyCouncil();
    error NotMinter();
    error NotWhitelistedNFT();
    error NotWhitelistedToken();
    error SameValue();
    error SpecialVotingWindow();
    error TooManyPools();
    error UnequalLengths();
    error ZeroBalance();
    error ZeroAddress();

    event GaugeCreated(
        address indexed poolFactory,
        address indexed votingRewardsFactory,
        address indexed gaugeFactory,
        address pool,
        address bribeVotingReward,
        address feeVotingReward,
        address gauge,
        address creator
    );
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(
        address indexed voter,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 weight,
        uint256 totalWeight,
        uint256 timestamp
    );
    event Abstained(
        address indexed voter,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 weight,
        uint256 totalWeight,
        uint256 timestamp
    );
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event WhitelistToken(address indexed whitelister, address indexed token, bool indexed _bool);
    event WhitelistNFT(address indexed whitelister, uint256 indexed tokenId, bool indexed _bool);

    /// @notice Store trusted forwarder address to pass into factories
    function forwarder() external view returns (address);

    /// @notice The ve token that governs these contracts
    function ve() external view returns (address);

    /// @notice Factory registry for valid pool / gauge / rewards factories
    function factoryRegistry() external view returns (address);

    /// @notice Address of Minter.sol
    function minter() external view returns (address);

    /// @notice Standard OZ IGovernor using ve for vote weights.
    function governor() external view returns (address);

    /// @notice Custom Epoch Governor using ve for vote weights.
    function epochGovernor() external view returns (address);

    /// @notice credibly neutral party similar to Curve's Emergency DAO
    function emergencyCouncil() external view returns (address);

    /// @dev Total Voting Weights
    function totalWeight() external view returns (uint256);

    /// @dev Most number of pools one voter can vote for at once
    function maxVotingNum() external view returns (uint256);

    // mappings
    /// @dev Pool => Gauge
    function gauges(address pool) external view returns (address);

    /// @dev Gauge => Pool
    function poolForGauge(address gauge) external view returns (address);

    /// @dev Gauge => Fees Voting Reward
    function gaugeToFees(address gauge) external view returns (address);

    /// @dev Gauge => Bribes Voting Reward
    function gaugeToBribe(address gauge) external view returns (address);

    /// @dev Pool => Weights
    function weights(address pool) external view returns (uint256);

    /// @dev NFT => Pool => Votes
    function votes(uint256 tokenId, address pool) external view returns (uint256);

    /// @dev NFT => Total voting weight of NFT
    function usedWeights(uint256 tokenId) external view returns (uint256);

    /// @dev Nft => Timestamp of last vote (ensures single vote per epoch)
    function lastVoted(uint256 tokenId) external view returns (uint256);

    /// @dev Address => Gauge
    function isGauge(address) external view returns (bool);

    /// @dev Token => Whitelisted status
    function isWhitelistedToken(address token) external view returns (bool);

    /// @dev TokenId => Whitelisted status
    function isWhitelistedNFT(uint256 tokenId) external view returns (bool);

    /// @dev Gauge => Liveness status
    function isAlive(address gauge) external view returns (bool);

    /// @dev Gauge => Amount claimable
    function claimable(address gauge) external view returns (uint256);

    /// @notice Number of pools with a Gauge
    function length() external view returns (uint256);

    /// @notice Called by Minter to distribute weekly emissions rewards for disbursement amongst gauges.
    /// @dev Assumes totalWeight != 0 (Will never be zero as long as users are voting).
    ///      Throws if not called by minter.
    /// @param _amount Amount of rewards to distribute.
    function notifyRewardAmount(uint256 _amount) external;

    /// @dev Utility to distribute to gauges of pools in range _start to _finish.
    /// @param _start   Starting index of gauges to distribute to.
    /// @param _finish  Ending index of gauges to distribute to.
    function distribute(uint256 _start, uint256 _finish) external;

    /// @dev Utility to distribute to gauges of pools in array.
    /// @param _gauges Array of gauges to distribute to.
    function distribute(address[] memory _gauges) external;

    /// @notice Called by users to update voting balances in voting rewards contracts.
    /// @param _tokenId Id of veNFT whose balance you wish to update.
    function poke(uint256 _tokenId) external;

    /// @notice Called by users to vote for pools. Votes distributed proportionally based on weights.
    ///         Can only vote or deposit into a managed NFT once per epoch.
    ///         Can only vote for gauges that have not been killed.
    /// @dev Weights are distributed proportional to the sum of the weights in the array.
    ///      Throws if length of _poolVote and _weights do not match.
    /// @param _tokenId     Id of veNFT you are voting with.
    /// @param _poolVote    Array of pools you are voting for.
    /// @param _weights     Weights of pools.
    function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) external;

    /// @notice Called by users to reset voting state. Required if you wish to make changes to
    ///         veNFT state (e.g. merge, split, deposit into managed etc).
    ///         Cannot reset in the same epoch that you voted in.
    ///         Can vote or deposit into a managed NFT again after reset.
    /// @param _tokenId Id of veNFT you are reseting.
    function reset(uint256 _tokenId) external;

    /// @notice Called by users to deposit into a managed NFT.
    ///         Can only vote or deposit into a managed NFT once per epoch.
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    /// @dev Throws if not approved or owner.
    ///      Throws if managed NFT is inactive.
    ///      Throws if depositing within privileged window (one hour prior to epoch flip).
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Called by users to withdraw from a managed NFT.
    ///         Cannot do it in the same epoch that you deposited into a managed NFT.
    ///         Can vote or deposit into a managed NFT again after withdrawing.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Claim emissions from gauges.
    /// @param _gauges Array of gauges to collect emissions from.
    function claimRewards(address[] memory _gauges) external;

    /// @notice Claim bribes for a given NFT.
    /// @dev Utility to help batch bribe claims.
    /// @param _bribes  Array of BribeVotingReward contracts to collect from.
    /// @param _tokens  Array of tokens that are used as bribes.
    /// @param _tokenId Id of veNFT that you wish to claim bribes for.
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external;

    /// @notice Claim fees for a given NFT.
    /// @dev Utility to help batch fee claims.
    /// @param _fees    Array of FeesVotingReward contracts to collect from.
    /// @param _tokens  Array of tokens that are used as fees.
    /// @param _tokenId Id of veNFT that you wish to claim fees for.
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external;

    /// @notice Set new governor.
    /// @dev Throws if not called by governor.
    /// @param _governor .
    function setGovernor(address _governor) external;

    /// @notice Set new epoch based governor.
    /// @dev Throws if not called by governor.
    /// @param _epochGovernor .
    function setEpochGovernor(address _epochGovernor) external;

    /// @notice Set new emergency council.
    /// @dev Throws if not called by emergency council.
    /// @param _emergencyCouncil .
    function setEmergencyCouncil(address _emergencyCouncil) external;

    /// @notice Set maximum number of gauges that can be voted for.
    /// @dev Throws if not called by governor.
    ///      Throws if _maxVotingNum is too low.
    ///      Throws if the values are the same.
    /// @param _maxVotingNum .
    function setMaxVotingNum(uint256 _maxVotingNum) external;

    /// @notice Whitelist (or unwhitelist) token for use in bribes.
    /// @dev Throws if not called by governor.
    /// @param _token .
    /// @param _bool .
    function whitelistToken(address _token, bool _bool) external;

    /// @notice Whitelist (or unwhitelist) token id for voting in last hour prior to epoch flip.
    /// @dev Throws if not called by governor.
    ///      Throws if already whitelisted.
    /// @param _tokenId .
    /// @param _bool .
    function whitelistNFT(uint256 _tokenId, bool _bool) external;

    /// @notice Create a new gauge (unpermissioned).
    /// @dev Governor can create a new gauge for a pool with any address.
    /// @param _poolFactory .
    /// @param _pool .
    function createGauge(address _poolFactory, address _pool) external returns (address);

    /// @notice Kills a gauge. The gauge will not receive any new emissions and cannot be deposited into.
    ///         Can still withdraw from gauge.
    /// @dev Throws if not called by emergency council.
    ///      Throws if gauge already killed.
    /// @param _gauge .
    function killGauge(address _gauge) external;

    /// @notice Revives a killed gauge. Gauge will can receive emissions and deposits again.
    /// @dev Throws if not called by emergency council.
    ///      Throws if gauge is not killed.
    /// @param _gauge .
    function reviveGauge(address _gauge) external;

    /// @dev Update claims to emissions for an array of gauges.
    /// @param _gauges Array of gauges to update emissions for.
    function updateFor(address[] memory _gauges) external;

    /// @dev Update claims to emissions for gauges based on their pool id as stored in Voter.
    /// @param _start   Starting index of pools.
    /// @param _end     Ending index of pools.
    function updateFor(uint256 _start, uint256 _end) external;

    /// @dev Update claims to emissions for single gauge
    /// @param _gauge .
    function updateFor(address _gauge) external;
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IReward {
    error InvalidReward();
    error NotAuthorized();
    error NotGauge();
    error NotEscrowToken();
    error NotSingleToken();
    error NotVotingEscrow();
    error NotWhitelisted();
    error ZeroAmount();

    event Deposit(address indexed from, uint256 indexed tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 indexed tokenId, uint256 amount);
    event NotifyReward(address indexed from, address indexed reward, uint256 indexed epoch, uint256 amount);
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    /// @notice Epoch duration constant (7 days)
    function DURATION() external view returns (uint256);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of VotingEscrow.sol
    function ve() external view returns (address);

    /// @dev Address which has permission to externally call _deposit() & _withdraw()
    function authorized() external view returns (address);

    /// @notice Total amount currently deposited via _deposit()
    function totalSupply() external view returns (uint256);

    /// @notice Current amount deposited by tokenId
    function balanceOf(uint256 tokenId) external view returns (uint256);

    /// @notice Amount of tokens to reward depositors for a given epoch
    /// @param token Address of token to reward
    /// @param epochStart Startime of rewards epoch
    /// @return Amount of token
    function tokenRewardsPerEpoch(address token, uint256 epochStart) external view returns (uint256);

    /// @notice Most recent timestamp a veNFT has claimed their rewards
    /// @param  token Address of token rewarded
    /// @param tokenId veNFT unique identifier
    /// @return Timestamp
    function lastEarn(address token, uint256 tokenId) external view returns (uint256);

    /// @notice True if a token is or has been an active reward token, else false
    function isReward(address token) external view returns (bool);

    /// @notice The number of checkpoints for each tokenId deposited
    function numCheckpoints(uint256 tokenId) external view returns (uint256);

    /// @notice The total number of checkpoints
    function supplyNumCheckpoints() external view returns (uint256);

    /// @notice Deposit an amount into the rewards contract to earn future rewards associated to a veNFT
    /// @dev Internal notation used as only callable internally by `authorized`.
    /// @param amount   Amount deposited for the veNFT
    /// @param tokenId  Unique identifier of the veNFT
    function _deposit(uint256 amount, uint256 tokenId) external;

    /// @notice Withdraw an amount from the rewards contract associated to a veNFT
    /// @dev Internal notation used as only callable internally by `authorized`.
    /// @param amount   Amount deposited for the veNFT
    /// @param tokenId  Unique identifier of the veNFT
    function _withdraw(uint256 amount, uint256 tokenId) external;

    /// @notice Claim the rewards earned by a veNFT staker
    /// @param tokenId  Unique identifier of the veNFT
    /// @param tokens   Array of tokens to claim rewards of
    function getReward(uint256 tokenId, address[] memory tokens) external;

    /// @notice Add rewards for stakers to earn
    /// @param token    Address of token to reward
    /// @param amount   Amount of token to transfer to rewards
    function notifyRewardAmount(address token, uint256 amount) external;

    /// @notice Determine the prior balance for an account as of a block number
    /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    /// @param tokenId      The token of the NFT to check
    /// @param timestamp    The timestamp to get the balance at
    /// @return The balance the account had as of the given block
    function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @notice Determine the prior index of supply staked by of a timestamp
    /// @dev Timestamp must be <= current timestamp
    /// @param timestamp The timestamp to get the index at
    /// @return Index of supply checkpoint
    function getPriorSupplyIndex(uint256 timestamp) external view returns (uint256);

    /// @notice Get number of rewards tokens
    function rewardsListLength() external view returns (uint256);

    /// @notice Calculate how much in rewards are earned for a specific token and veNFT
    /// @param token Address of token to fetch rewards of
    /// @param tokenId Unique identifier of the veNFT
    /// @return Amount of token earned in rewards
    function earned(address token, uint256 tokenId) external view returns (uint256);
}

interface IFactoryRegistry {
    error FallbackFactory();
    error InvalidFactoriesToPoolFactory();
    error PathAlreadyApproved();
    error PathNotApproved();
    error SameAddress();
    error ZeroAddress();

    event Approve(address indexed poolFactory, address indexed votingRewardsFactory, address indexed gaugeFactory);
    event Unapprove(address indexed poolFactory, address indexed votingRewardsFactory, address indexed gaugeFactory);
    event SetManagedRewardsFactory(address indexed _newRewardsFactory);

    /// @notice Approve a set of factories used in the Protocol.
    ///         Router.sol is able to swap any poolFactories currently approved.
    ///         Cannot approve address(0) factories.
    ///         Cannot aprove path that is already approved.
    ///         Each poolFactory has one unique set and maintains state.  In the case a poolFactory is unapproved
    ///             and then re-approved, the same set of factories must be used.  In other words, you cannot overwrite
    ///             the factories tied to a poolFactory address.
    ///         VotingRewardsFactories and GaugeFactories may use the same address across multiple poolFactories.
    /// @dev Callable by onlyOwner
    /// @param poolFactory .
    /// @param votingRewardsFactory .
    /// @param gaugeFactory .
    function approve(address poolFactory, address votingRewardsFactory, address gaugeFactory) external;

    /// @notice Unapprove a set of factories used in the Protocol.
    ///         While a poolFactory is unapproved, Router.sol cannot swap with pools made from the corresponding factory
    ///         Can only unapprove an approved path.
    ///         Cannot unapprove the fallback path (core v2 factories).
    /// @dev Callable by onlyOwner
    /// @param poolFactory .
    function unapprove(address poolFactory) external;

    /// @notice Factory to create free and locked rewards for a managed veNFT
    function managedRewardsFactory() external view returns (address);

    /// @notice Set the rewards factory address
    /// @dev Callable by onlyOwner
    /// @param _newManagedRewardsFactory address of new managedRewardsFactory
    function setManagedRewardsFactory(address _newManagedRewardsFactory) external;

    /// @notice Get the factories correlated to a poolFactory.
    ///         Once set, this can never be modified.
    ///         Returns the correlated factories even after an approved poolFactory is unapproved.
    function factoriesToPoolFactory(
        address poolFactory
    ) external view returns (address votingRewardsFactory, address gaugeFactory);

    /// @notice Get all PoolFactories approved by the registry
    /// @dev The same PoolFactory address cannot be used twice
    /// @return Array of PoolFactory addresses
    function poolFactories() external view returns (address[] memory);

    /// @notice Check if a PoolFactory is approved within the factory registry.  Router uses this method to
    ///         ensure a pool swapped from is approved.
    /// @param poolFactory .
    /// @return True if PoolFactory is approved, else false
    function isPoolFactoryApproved(address poolFactory) external view returns (bool);

    /// @notice Get the length of the poolFactories array
    function poolFactoriesLength() external view returns (uint256);
}

interface IManagedRewardsFactory {
    event ManagedRewardCreated(
        address indexed voter,
        address indexed lockedManagedReward,
        address indexed freeManagedReward
    );

    /// @notice creates a LockedManagedReward and a FreeManagedReward contract for a managed veNFT
    /// @param _forwarder Address of trusted forwarder
    /// @param _voter Address of Voter.sol
    /// @return lockedManagedReward Address of LockedManagedReward contract created
    /// @return freeManagedReward   Address of FreeManagedReward contract created
    function createRewards(
        address _forwarder,
        address _voter
    ) external returns (address lockedManagedReward, address freeManagedReward);
}

// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

/// @title SafeCast Library
/// @author perfectswap.io
/// @notice Safely convert unsigned and signed integers without overflow / underflow
library SafeCastLibrary {
    error SafeCastOverflow();
    error SafeCastUnderflow();

    /// @dev Safely convert uint256 to int128
    function toInt128(uint256 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max)) revert SafeCastOverflow();
        return int128(uint128(value));
    }

    /// @dev Safely convert int128 to uint256
    function toUint256(int128 value) internal pure returns (uint256) {
        if (value < 0) revert SafeCastUnderflow();
        return uint256(int256(value));
    }
}

library DelegationLogicLibrary {
    using SafeCastLibrary for int128;

    /// @notice Used by `_mint`, `_transferFrom`, `_burn` and `delegate`
    ///         to update delegator voting checkpoints.
    ///         Automatically dedelegates, then updates checkpoint.
    /// @dev This function depends on `_locked` and must be called prior to token state changes.
    ///      If you wish to dedelegate only, use `_delegate(tokenId, 0)` instead.
    /// @param _locked State of all locked balances
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _delegates State of all user delegatees
    /// @param _delegator The delegator to update checkpoints for
    /// @param _delegatee The new delegatee for the delegator. Cannot be equal to `_delegator` (use 0 instead).
    /// @param _owner The new (or current) owner for the delegator
    function checkpointDelegator(
        mapping(uint256 => IVotingEscrow.LockedBalance) storage _locked,
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        mapping(uint256 => uint256) storage _delegates,
        uint256 _delegator,
        uint256 _delegatee,
        address _owner
    ) external {
        uint256 delegatedBalance = _locked[_delegator].amount.toUint256();
        uint48 numCheckpoint = _numCheckpoints[_delegator];
        IVotingEscrow.Checkpoint storage cpOld = numCheckpoint > 0
            ? _checkpoints[_delegator][numCheckpoint - 1]
            : _checkpoints[_delegator][0];
        // Dedelegate from delegatee if delegated
        checkpointDelegatee(_numCheckpoints, _checkpoints, cpOld.delegatee, delegatedBalance, false);
        IVotingEscrow.Checkpoint storage cp = _checkpoints[_delegator][numCheckpoint];
        cp.fromTimestamp = block.timestamp;
        cp.delegatedBalance = cpOld.delegatedBalance;
        cp.delegatee = _delegatee;
        cp.owner = _owner;

        if (_isCheckpointInNewBlock(_numCheckpoints, _checkpoints, _delegator)) {
            _numCheckpoints[_delegator]++;
        } else {
            _checkpoints[_delegator][numCheckpoint - 1] = cp;
            delete _checkpoints[_delegator][numCheckpoint];
        }

        _delegates[_delegator] = _delegatee;
    }

    /// @notice Update delegatee's `delegatedBalance` by `balance`.
    ///         Only updates if delegating to a new delegatee.
    /// @dev If used with `balance` == `_locked[_tokenId].amount`, then this is the same as
    ///      delegating or dedelegating from `_tokenId`
    ///      If used with `balance` < `_locked[_tokenId].amount`, then this is used to adjust
    ///      `delegatedBalance` when a user's balance is modified (e.g. `increaseAmount`, `merge` etc).
    ///      If `delegatee` is 0 (i.e. user is not delegating), then do nothing.
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _delegatee The delegatee's tokenId
    /// @param balance_ The delta in balance change
    /// @param _increase True if balance is increasing, false if decreasing
    function checkpointDelegatee(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        uint256 _delegatee,
        uint256 balance_,
        bool _increase
    ) public {
        if (_delegatee == 0) return;
        uint48 numCheckpoint = _numCheckpoints[_delegatee];
        IVotingEscrow.Checkpoint storage cpOld = numCheckpoint > 0
            ? _checkpoints[_delegatee][numCheckpoint - 1]
            : _checkpoints[_delegatee][0];
        IVotingEscrow.Checkpoint storage cp = _checkpoints[_delegatee][numCheckpoint];
        cp.fromTimestamp = block.timestamp;
        cp.owner = cpOld.owner;
        // do not expect balance_ > cpOld.delegatedBalance when decrementing but just in case
        cp.delegatedBalance = _increase
            ? cpOld.delegatedBalance + balance_
            : (balance_ < cpOld.delegatedBalance ? cpOld.delegatedBalance - balance_ : 0);
        cp.delegatee = cpOld.delegatee;

        if (_isCheckpointInNewBlock(_numCheckpoints, _checkpoints, _delegatee)) {
            _numCheckpoints[_delegatee]++;
        } else {
            _checkpoints[_delegatee][numCheckpoint - 1] = cp;
            delete _checkpoints[_delegatee][numCheckpoint];
        }
    }

    function _isCheckpointInNewBlock(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint48 _nCheckPoints = _numCheckpoints[_tokenId];

        if (_nCheckPoints > 0 && _checkpoints[_tokenId][_nCheckPoints - 1].fromTimestamp == block.timestamp) {
            return false;
        } else {
            return true;
        }
    }

    /// @notice Binary search to get the voting checkpoint for a token id at or prior to a given timestamp.
    /// @dev If a checkpoint does not exist prior to the timestamp, this will return 0.
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _tokenId .
    /// @param _timestamp .
    /// @return The index of the checkpoint.
    function getPastVotesIndex(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        uint256 _tokenId,
        uint256 _timestamp
    ) internal view returns (uint48) {
        uint48 nCheckpoints = _numCheckpoints[_tokenId];
        if (nCheckpoints == 0) return 0;
        // First check most recent balance
        if (_checkpoints[_tokenId][nCheckpoints - 1].fromTimestamp <= _timestamp) return (nCheckpoints - 1);
        // Next check implicit zero balance
        if (_checkpoints[_tokenId][0].fromTimestamp > _timestamp) return 0;

        uint48 lower = 0;
        uint48 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint48 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            IVotingEscrow.Checkpoint storage cp = _checkpoints[_tokenId][center];
            if (cp.fromTimestamp == _timestamp) {
                return center;
            } else if (cp.fromTimestamp < _timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Retrieves historical voting balance for a token id at a given timestamp.
    /// @dev If a checkpoint does not exist prior to the timestamp, this will return 0.
    ///      The user must also own the token at the time in order to receive a voting balance.
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _account .
    /// @param _tokenId .
    /// @param _timestamp .
    /// @return Total voting balance including delegations at a given timestamp.
    function getPastVotes(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        address _account,
        uint256 _tokenId,
        uint256 _timestamp
    ) external view returns (uint256) {
        uint48 _checkIndex = getPastVotesIndex(_numCheckpoints, _checkpoints, _tokenId, _timestamp);
        IVotingEscrow.Checkpoint memory lastCheckpoint = _checkpoints[_tokenId][_checkIndex];
        // If no point exists prior to the given timestamp, return 0
        if (lastCheckpoint.fromTimestamp > _timestamp) return 0;
        // Check ownership
        if (_account != lastCheckpoint.owner) return 0;
        uint256 votes = lastCheckpoint.delegatedBalance;
        return
            lastCheckpoint.delegatee == 0
                ? votes + IVotingEscrow(address(this)).balanceOfNFTAt(_tokenId, _timestamp)
                : votes;
    }
}

library BalanceLogicLibrary {
    using SafeCastLibrary for uint256;
    using SafeCastLibrary for int128;

    uint256 internal constant WEEK = 1 weeks;

    /// @notice Binary search to get the user point index for a token id at or prior to a given timestamp
    /// @dev If a user point does not exist prior to the timestamp, this will return 0.
    /// @param _userPointEpoch State of all user point epochs
    /// @param _userPointHistory State of all user point history
    /// @param _tokenId .
    /// @param _timestamp .
    /// @return User point index
    function getPastUserPointIndex(
        mapping(uint256 => uint256) storage _userPointEpoch,
        mapping(uint256 => IVotingEscrow.UserPoint[1000000000]) storage _userPointHistory,
        uint256 _tokenId,
        uint256 _timestamp
    ) internal view returns (uint256) {
        uint256 _userEpoch = _userPointEpoch[_tokenId];
        if (_userEpoch == 0) return 0;
        // First check most recent balance
        if (_userPointHistory[_tokenId][_userEpoch].ts <= _timestamp) return (_userEpoch);
        // Next check implicit zero balance
        if (_userPointHistory[_tokenId][1].ts > _timestamp) return 0;

        uint256 lower = 0;
        uint256 upper = _userEpoch;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            IVotingEscrow.UserPoint storage userPoint = _userPointHistory[_tokenId][center];
            if (userPoint.ts == _timestamp) {
                return center;
            } else if (userPoint.ts < _timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Binary search to get the global point index at or prior to a given timestamp
    /// @dev If a checkpoint does not exist prior to the timestamp, this will return 0.
    /// @param _epoch Current global point epoch
    /// @param _pointHistory State of all global point history
    /// @param _timestamp .
    /// @return Global point index
    function getPastGlobalPointIndex(
        uint256 _epoch,
        mapping(uint256 => IVotingEscrow.GlobalPoint) storage _pointHistory,
        uint256 _timestamp
    ) internal view returns (uint256) {
        if (_epoch == 0) return 0;
        // First check most recent balance
        if (_pointHistory[_epoch].ts <= _timestamp) return (_epoch);
        // Next check implicit zero balance
        if (_pointHistory[1].ts > _timestamp) return 0;

        uint256 lower = 0;
        uint256 upper = _epoch;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            IVotingEscrow.GlobalPoint storage globalPoint = _pointHistory[center];
            if (globalPoint.ts == _timestamp) {
                return center;
            } else if (globalPoint.ts < _timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    ///      Fetches last user point prior to a certain timestamp, then walks forward to timestamp.
    /// @param _userPointEpoch State of all user point epochs
    /// @param _userPointHistory State of all user point history
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function balanceOfNFTAt(
        mapping(uint256 => uint256) storage _userPointEpoch,
        mapping(uint256 => IVotingEscrow.UserPoint[1000000000]) storage _userPointHistory,
        uint256 _tokenId,
        uint256 _t
    ) external view returns (uint256) {
        uint256 _epoch = getPastUserPointIndex(_userPointEpoch, _userPointHistory, _tokenId, _t);
        // epoch 0 is an empty point
        if (_epoch == 0) return 0;
        IVotingEscrow.UserPoint memory lastPoint = _userPointHistory[_tokenId][_epoch];
        if (lastPoint.permanent != 0) {
            return lastPoint.permanent;
        } else {
            lastPoint.bias -= lastPoint.slope * (_t - lastPoint.ts).toInt128();
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return lastPoint.bias.toUint256();
        }
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _slopeChanges State of all slopeChanges
    /// @param _pointHistory State of all global point history
    /// @param _epoch The epoch to start search from
    /// @param _t Time to calculate the total voting power at
    /// @return Total voting power at that time
    function supplyAt(
        mapping(uint256 => int128) storage _slopeChanges,
        mapping(uint256 => IVotingEscrow.GlobalPoint) storage _pointHistory,
        uint256 _epoch,
        uint256 _t
    ) external view returns (uint256) {
        uint256 epoch_ = getPastGlobalPointIndex(_epoch, _pointHistory, _t);
        // epoch 0 is an empty point
        if (epoch_ == 0) return 0;
        IVotingEscrow.GlobalPoint memory _point = _pointHistory[epoch_];
        int128 bias = _point.bias;
        int128 slope = _point.slope;
        uint256 ts = _point.ts;
        uint256 t_i = (ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 dSlope = 0;
            if (t_i > _t) {
                t_i = _t;
            } else {
                dSlope = _slopeChanges[t_i];
            }
            bias -= slope * (t_i - ts).toInt128();
            if (t_i == _t) {
                break;
            }
            slope += dSlope;
            ts = t_i;
        }

        if (bias < 0) {
            bias = 0;
        }
        return bias.toUint256() + _point.permanentLockBalance;
    }
}

/// @title Voting Escrow
/// @notice veNFT implementation that escrows ERC-20 tokens in the form of an ERC-721 NFT
/// @notice Votes have a weight depending on time, so that users are committed to the future of (whatever they are voting for)
/// @author Modified from Solidly (https://github.com/solidlyexchange/solidly/blob/master/contracts/ve.sol)
/// @author Modified from Curve (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
/// @dev Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (4 years).
contract VotingEscrow is IVotingEscrow, ERC2771Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCastLibrary for uint256;
    using SafeCastLibrary for int128;
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    address public immutable forwarder;
    /// @inheritdoc IVotingEscrow
    address public immutable factoryRegistry;
    /// @inheritdoc IVotingEscrow
    address public immutable token;
    /// @inheritdoc IVotingEscrow
    address public distributor;
    /// @inheritdoc IVotingEscrow
    address public voter;
    /// @inheritdoc IVotingEscrow
    address public team;
    /// @inheritdoc IVotingEscrow
    address public artProxy;
    /// @inheritdoc IVotingEscrow
    address public allowedManager;

    mapping(uint256 => GlobalPoint) internal _pointHistory; // epoch -> unsigned global point

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @dev ERC165 interface ID of ERC4906
    bytes4 internal constant ERC4906_INTERFACE_ID = 0x49064906;

    /// @dev ERC165 interface ID of ERC6372
    bytes4 internal constant ERC6372_INTERFACE_ID = 0xda287a1d;

    /// @inheritdoc IVotingEscrow
    uint256 public tokenId;

    /// @param _forwarder address of trusted forwarder
    /// @param _token `PRFCT` token address
    /// @param _factoryRegistry Factory Registry address
    constructor(address _forwarder, address _token, address _factoryRegistry) ERC2771Context(_forwarder) {
        forwarder = _forwarder;
        token = _token;
        factoryRegistry = _factoryRegistry;
        team = _msgSender();
        voter = _msgSender();

        _pointHistory[0].blk = block.number;
        _pointHistory[0].ts = block.timestamp;

        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
        supportedInterfaces[ERC4906_INTERFACE_ID] = true;
        supportedInterfaces[ERC6372_INTERFACE_ID] = true;

        // mint-ish
        emit Transfer(address(0), address(this), tokenId);
        // burn-ish
        emit Transfer(address(this), address(0), tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => EscrowType) public escrowType;

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => uint256) public idToManaged;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => mapping(uint256 => uint256)) public weights;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => bool) public deactivated;

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => address) public managedToLocked;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => address) public managedToFree;

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function createManagedLockFor(address _to) external nonReentrant returns (uint256 _mTokenId) {
        address sender = _msgSender();
        if (sender != allowedManager && sender != IVoter(voter).governor()) revert NotGovernorOrManager();

        _mTokenId = ++tokenId;
        _mint(_to, _mTokenId);
        _depositFor(_mTokenId, 0, 0, LockedBalance(0, 0, true), DepositType.CREATE_LOCK_TYPE);

        escrowType[_mTokenId] = EscrowType.MANAGED;

        (address _lockedManagedReward, address _freeManagedReward) = IManagedRewardsFactory(
            IFactoryRegistry(factoryRegistry).managedRewardsFactory()
        ).createRewards(forwarder, voter);
        managedToLocked[_mTokenId] = _lockedManagedReward;
        managedToFree[_mTokenId] = _freeManagedReward;

        emit CreateManaged(_to, _mTokenId, sender, _lockedManagedReward, _freeManagedReward);
    }

    /// @inheritdoc IVotingEscrow
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external nonReentrant {
        if (_msgSender() != voter) revert NotVoter();
        if (escrowType[_mTokenId] != EscrowType.MANAGED) revert NotManagedNFT();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();
        if (_balanceOfNFTAt(_tokenId, block.timestamp) == 0) revert ZeroBalance();

        // adjust user nft
        int128 _amount = _locked[_tokenId].amount;
        if (_locked[_tokenId].isPermanent) {
            permanentLockBalance -= _amount.toUint256();
            _delegate(_tokenId, 0);
        }
        _checkpoint(_tokenId, _locked[_tokenId], LockedBalance(0, 0, false));
        _locked[_tokenId] = LockedBalance(0, 0, false);

        // adjust managed nft
        uint256 _weight = _amount.toUint256();
        permanentLockBalance += _weight;
        LockedBalance memory newLocked = _locked[_mTokenId];
        newLocked.amount += _amount;
        _checkpointDelegatee(_delegates[_mTokenId], _weight, true);
        _checkpoint(_mTokenId, _locked[_mTokenId], newLocked);
        _locked[_mTokenId] = newLocked;

        weights[_tokenId][_mTokenId] = _weight;
        idToManaged[_tokenId] = _mTokenId;
        escrowType[_tokenId] = EscrowType.LOCKED;

        address _lockedManagedReward = managedToLocked[_mTokenId];
        IReward(_lockedManagedReward)._deposit(_weight, _tokenId);
        address _freeManagedReward = managedToFree[_mTokenId];
        IReward(_freeManagedReward)._deposit(_weight, _tokenId);

        emit DepositManaged(_ownerOf(_tokenId), _tokenId, _mTokenId, _weight, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function withdrawManaged(uint256 _tokenId) external nonReentrant {
        uint256 _mTokenId = idToManaged[_tokenId];
        if (_msgSender() != voter) revert NotVoter();
        if (_mTokenId == 0) revert InvalidManagedNFTId();
        if (escrowType[_tokenId] != EscrowType.LOCKED) revert NotLockedNFT();

        // update accrued rewards
        address _lockedManagedReward = managedToLocked[_mTokenId];
        address _freeManagedReward = managedToFree[_mTokenId];
        uint256 _weight = weights[_tokenId][_mTokenId];
        uint256 _reward = IReward(_lockedManagedReward).earned(address(token), _tokenId);
        uint256 _total = _weight + _reward;
        uint256 _unlockTime = ((block.timestamp + MAXTIME) / WEEK) * WEEK;

        // claim locked rewards (rebases + compounded reward)
        address[] memory rewards = new address[](1);
        rewards[0] = address(token);
        IReward(_lockedManagedReward).getReward(_tokenId, rewards);

        // adjust user nft
        LockedBalance memory newLockedNormal = LockedBalance(_total.toInt128(), _unlockTime, false);
        _checkpoint(_tokenId, _locked[_tokenId], newLockedNormal);
        _locked[_tokenId] = newLockedNormal;

        // adjust managed nft
        LockedBalance memory newLockedManaged = _locked[_mTokenId];
        // do not expect _total > locked.amount / permanentLockBalance but just in case
        newLockedManaged.amount -= (
            _total.toInt128() < newLockedManaged.amount ? _total.toInt128() : newLockedManaged.amount
        );
        permanentLockBalance -= (_total < permanentLockBalance ? _total : permanentLockBalance);
        _checkpointDelegatee(_delegates[_mTokenId], _total, false);
        _checkpoint(_mTokenId, _locked[_mTokenId], newLockedManaged);
        _locked[_mTokenId] = newLockedManaged;

        IReward(_lockedManagedReward)._withdraw(_weight, _tokenId);
        IReward(_freeManagedReward)._withdraw(_weight, _tokenId);

        delete idToManaged[_tokenId];
        delete weights[_tokenId][_mTokenId];
        delete escrowType[_tokenId];

        emit WithdrawManaged(_ownerOf(_tokenId), _tokenId, _mTokenId, _total, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function setAllowedManager(address _allowedManager) external {
        if (_msgSender() != IVoter(voter).governor()) revert NotGovernor();
        if (_allowedManager == allowedManager) revert SameAddress();
        if (_allowedManager == address(0)) revert ZeroAddress();
        allowedManager = _allowedManager;
        emit SetAllowedManager(_allowedManager);
    }

    /// @inheritdoc IVotingEscrow
    function setManagedState(uint256 _mTokenId, bool _state) external {
        if (_msgSender() != IVoter(voter).emergencyCouncil() && _msgSender() != IVoter(voter).governor())
            revert NotEmergencyCouncilOrGovernor();
        if (escrowType[_mTokenId] != EscrowType.MANAGED) revert NotManagedNFT();
        if (deactivated[_mTokenId] == _state) revert SameState();
        deactivated[_mTokenId] = _state;
    }

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public constant name = "veNFT";
    string public constant symbol = "veNFT";
    string public constant version = "2.0.0";
    uint8 public constant decimals = 18;

    function setTeam(address _team) external {
        if (_msgSender() != team) revert NotTeam();
        if (_team == address(0)) revert ZeroAddress();
        team = _team;
    }

    function setArtProxy(address _proxy) external {
        if (_msgSender() != team) revert NotTeam();
        artProxy = _proxy;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /// @inheritdoc IVotingEscrow
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        if (_ownerOf(_tokenId) == address(0)) revert NonExistentToken();
        return IVeArtProxy(artProxy).tokenURI(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint256 => address) internal idToOwner;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint256) internal ownerToNFTokenCount;

    function _ownerOf(uint256 _tokenId) internal view returns (address) {
        return idToOwner[_tokenId];
    }

    /// @inheritdoc IVotingEscrow
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return _ownerOf(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function balanceOf(address _owner) external view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint256 => address) internal idToApprovals;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    mapping(uint256 => uint256) internal ownershipChange;

    /// @inheritdoc IVotingEscrow
    function getApproved(uint256 _tokenId) external view returns (address) {
        return idToApprovals[_tokenId];
    }

    /// @inheritdoc IVotingEscrow
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }

    /// @inheritdoc IVotingEscrow
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = _ownerOf(_tokenId);
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function approve(address _approved, uint256 _tokenId) external {
        address sender = _msgSender();
        address owner = _ownerOf(_tokenId);
        // Throws if `_tokenId` is not a valid NFT
        if (owner == address(0)) revert ZeroAddress();
        // Throws if `_approved` is the current owner
        if (owner == _approved) revert SameAddress();
        // Check requirements
        bool senderIsOwner = (_ownerOf(_tokenId) == sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[sender];
        if (!senderIsOwner && !senderIsApprovedForAll) revert NotApprovedOrOwner();
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function setApprovalForAll(address _operator, bool _approved) external {
        address sender = _msgSender();
        // Throws if `_operator` is the `msg.sender`
        if (_operator == sender) revert SameAddress();
        ownerToOperators[sender][_operator] = _approved;
        emit ApprovalForAll(sender, _operator, _approved);
    }

    /* TRANSFER FUNCTIONS */

    function _transferFrom(address _from, address _to, uint256 _tokenId, address _sender) internal {
        if (escrowType[_tokenId] == EscrowType.LOCKED) revert NotManagedOrNormalNFT();
        // Check requirements
        if (!_isApprovedOrOwner(_sender, _tokenId)) revert NotApprovedOrOwner();
        // Clear approval. Throws if `_from` is not the current owner
        if (_ownerOf(_tokenId) != _from) revert NotOwner();
        delete idToApprovals[_tokenId];
        // Remove NFT. Throws if `_tokenId` is not a valid NFT
        _removeTokenFrom(_from, _tokenId);
        // Update voting checkpoints
        _checkpointDelegator(_tokenId, 0, _to);
        // Add NFT
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownershipChange[_tokenId] = block.number;
        // Log the transfer
        emit Transfer(_from, _to, _tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId, _msgSender());
    }

    /// @inheritdoc IVotingEscrow
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @inheritdoc IVotingEscrow
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        address sender = _msgSender();
        _transferFrom(_from, _to, _tokenId, sender);

        if (_isContract(_to)) {
            // Throws if transfer destination is a contract which does not implement 'onERC721Received'
            try IERC721Receiver(_to).onERC721Received(sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != IERC721Receiver(_to).onERC721Received.selector) {
                    revert ERC721ReceiverRejectedTokens();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonERC721ReceiverImplementer();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    mapping(address => mapping(uint256 => uint256)) public ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint256 => uint256) internal tokenToOwnerIndex;

    /// @dev Add a NFT to an index mapping to a given address
    /// @param _to address of the receiver
    /// @param _tokenId uint ID Of the token to be added
    function _addTokenToOwnerList(address _to, uint256 _tokenId) internal {
        uint256 currentCount = ownerToNFTokenCount[_to];

        ownerToNFTokenIdList[_to][currentCount] = _tokenId;
        tokenToOwnerIndex[_tokenId] = currentCount;
    }

    /// @dev Add a NFT to a given address
    ///      Throws if `_tokenId` is owned by someone.
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        assert(_ownerOf(_tokenId) == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_to] += 1;
    }

    /// @dev Function to mint tokens
    ///      Throws if `_to` is zero address.
    ///      Throws if `_tokenId` is owned by someone.
    /// @param _to The address that will receive the minted tokens.
    /// @param _tokenId The token id to mint.
    /// @return A boolean that indicates if the operation was successful.
    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // Add NFT. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        // Update voting checkpoints
        _checkpointDelegator(_tokenId, 0, _to);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    /// @dev Remove a NFT from an index mapping to a given address
    /// @param _from address of the sender
    /// @param _tokenId uint ID Of the token to be removed
    function _removeTokenFromOwnerList(address _from, uint256 _tokenId) internal {
        // Delete
        uint256 currentCount = ownerToNFTokenCount[_from] - 1;
        uint256 currentIndex = tokenToOwnerIndex[_tokenId];

        if (currentCount == currentIndex) {
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint256 lastTokenId = ownerToNFTokenIdList[_from][currentCount];

            // Add
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = currentIndex;

            // Delete
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /// @dev Remove a NFT from a given address
    ///      Throws if `_from` is not the current owner.
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        // Throws if `_from` is not the current owner
        assert(_ownerOf(_tokenId) == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_from] -= 1;
    }

    /// @dev Must be called prior to updating `LockedBalance`
    function _burn(uint256 _tokenId) internal {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        address owner = _ownerOf(_tokenId);

        // Clear approval
        delete idToApprovals[_tokenId];
        // Update voting checkpoints
        _checkpointDelegator(_tokenId, 0, address(0));
        // Remove token
        _removeTokenFrom(owner, _tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint256 internal constant MULTIPLIER = 1 ether;

    /// @inheritdoc IVotingEscrow
    uint256 public epoch;
    /// @inheritdoc IVotingEscrow
    uint256 public supply;

    mapping(uint256 => LockedBalance) internal _locked;
    mapping(uint256 => UserPoint[1000000000]) internal _userPointHistory;
    mapping(uint256 => uint256) public userPointEpoch;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => int128) public slopeChanges;
    /// @inheritdoc IVotingEscrow
    mapping(address => bool) public canSplit;
    /// @inheritdoc IVotingEscrow
    uint256 public permanentLockBalance;

    /// @inheritdoc IVotingEscrow
    function locked(uint256 _tokenId) external view returns (LockedBalance memory) {
        return _locked[_tokenId];
    }

    /// @inheritdoc IVotingEscrow
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory) {
        return _userPointHistory[_tokenId][_loc];
    }

    /// @inheritdoc IVotingEscrow
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory) {
        return _pointHistory[_loc];
    }

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global and per-user data to checkpoints. Used by VotingEscrow system.
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param _oldLocked Pevious locked amount / end lock time for the user
    /// @param _newLocked New locked amount / end lock time for the user
    function _checkpoint(uint256 _tokenId, LockedBalance memory _oldLocked, LockedBalance memory _newLocked) internal {
        UserPoint memory uOld;
        UserPoint memory uNew;
        int128 oldDslope = 0;
        int128 newDslope = 0;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            uNew.permanent = _newLocked.isPermanent ? _newLocked.amount.toUint256() : 0;
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                uOld.slope = _oldLocked.amount / iMAXTIME;
                uOld.bias = uOld.slope * (_oldLocked.end - block.timestamp).toInt128();
            }
            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                uNew.slope = _newLocked.amount / iMAXTIME;
                uNew.bias = uNew.slope * (_newLocked.end - block.timestamp).toInt128();
            }

            // Read values of scheduled changes in the slope
            // _oldLocked.end can be in the past and in the future
            // _newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
            oldDslope = slopeChanges[_oldLocked.end];
            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    newDslope = oldDslope;
                } else {
                    newDslope = slopeChanges[_newLocked.end];
                }
            }
        }

        GlobalPoint memory lastPoint = GlobalPoint({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number,
            permanentLockBalance: 0
        });
        if (_epoch > 0) {
            lastPoint = _pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;
        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        GlobalPoint memory initialLastPoint = GlobalPoint({
            bias: lastPoint.bias,
            slope: lastPoint.slope,
            ts: lastPoint.ts,
            blk: lastPoint.blk,
            permanentLockBalance: lastPoint.permanentLockBalance
        });
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 t_i = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK; // Initial value of t_i is always larger than the ts of the last point
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slopeChanges[t_i];
                }
                lastPoint.bias -= lastPoint.slope * (t_i - lastCheckpoint).toInt128();
                lastPoint.slope += d_slope;
                if (lastPoint.bias < 0) {
                    // This can happen
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    // This cannot happen - just in case
                    lastPoint.slope = 0;
                }
                lastCheckpoint = t_i;
                lastPoint.ts = t_i;
                lastPoint.blk = initialLastPoint.blk + (blockSlope * (t_i - initialLastPoint.ts)) / MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    lastPoint.blk = block.number;
                    break;
                } else {
                    _pointHistory[_epoch] = lastPoint;
                }
            }
        }

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            lastPoint.permanentLockBalance = permanentLockBalance;
        }

        // If timestamp of last global point is the same, overwrite the last global point
        // Else record the new global point into history
        // Exclude epoch 0 (note: _epoch is always >= 1, see above)
        // Two possible outcomes:
        // Missing global checkpoints in prior weeks. In this case, _epoch = epoch + x, where x > 1
        // No missing global checkpoints, but timestamp != block.timestamp. Create new checkpoint.
        // No missing global checkpoints, but timestamp == block.timestamp. Overwrite last checkpoint.
        if (_epoch != 1 && _pointHistory[_epoch - 1].ts == block.timestamp) {
            // _epoch = epoch + 1, so we do not increment epoch
            _pointHistory[_epoch - 1] = lastPoint;
        } else {
            // more than one global point may have been written, so we update epoch
            epoch = _epoch;
            _pointHistory[_epoch] = lastPoint;
        }

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_newLocked.end]
            // and add old_user_slope to [_oldLocked.end]
            if (_oldLocked.end > block.timestamp) {
                // oldDslope was <something> - uOld.slope, so we cancel that
                oldDslope += uOld.slope;
                if (_newLocked.end == _oldLocked.end) {
                    oldDslope -= uNew.slope; // It was a new deposit, not extension
                }
                slopeChanges[_oldLocked.end] = oldDslope;
            }

            if (_newLocked.end > block.timestamp) {
                // update slope if new lock is greater than old lock and is not permanent or if old lock is permanent
                if ((_newLocked.end > _oldLocked.end)) {
                    newDslope -= uNew.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = newDslope;
                }
                // else: we recorded it already in oldDslope
            }
            // If timestamp of last user point is the same, overwrite the last user point
            // Else record the new user point into history
            // Exclude epoch 0
            uNew.ts = block.timestamp;
            uNew.blk = block.number;
            uint256 userEpoch = userPointEpoch[_tokenId];
            if (userEpoch != 0 && _userPointHistory[_tokenId][userEpoch].ts == block.timestamp) {
                _userPointHistory[_tokenId][userEpoch] = uNew;
            } else {
                userPointEpoch[_tokenId] = ++userEpoch;
                _userPointHistory[_tokenId][userEpoch] = uNew;
            }
        }
    }

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param _unlockTime New time when to unlock the tokens, or 0 if unchanged
    /// @param _oldLocked Previous locked amount / timestamp
    /// @param _depositType The type of deposit
    function _depositFor(
        uint256 _tokenId,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _oldLocked,
        DepositType _depositType
    ) internal {
        uint256 supplyBefore = supply;
        supply = supplyBefore + _value;

        // Set newLocked to _oldLocked without mangling memory
        LockedBalance memory newLocked;
        (newLocked.amount, newLocked.end, newLocked.isPermanent) = (
            _oldLocked.amount,
            _oldLocked.end,
            _oldLocked.isPermanent
        );

        // Adding to existing lock, or if a lock is expired - creating a new one
        newLocked.amount += _value.toInt128();
        if (_unlockTime != 0) {
            newLocked.end = _unlockTime;
        }
        _locked[_tokenId] = newLocked;

        // Possibilities:
        // Both _oldLocked.end could be current or expired (>/< block.timestamp)
        // or if the lock is a permanent lock, then _oldLocked.end == 0
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // newLocked.end > block.timestamp (always)
        _checkpoint(_tokenId, _oldLocked, newLocked);

        address from = _msgSender();
        if (_value != 0) {
            IERC20(token).safeTransferFrom(from, address(this), _value);
        }

        emit Deposit(from, _tokenId, _depositType, _value, newLocked.end, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    /// @inheritdoc IVotingEscrow
    function checkpoint() external nonReentrant {
        _checkpoint(0, LockedBalance(0, 0, false), LockedBalance(0, 0, false));
    }

    /// @inheritdoc IVotingEscrow
    function depositFor(uint256 _tokenId, uint256 _value) external nonReentrant {
        if (escrowType[_tokenId] == EscrowType.MANAGED && _msgSender() != distributor) revert NotDistributor();
        _increaseAmountFor(_tokenId, _value, DepositType.DEPOSIT_FOR_TYPE);
    }

    /// @dev Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function _createLock(uint256 _value, uint256 _lockDuration, address _to) internal returns (uint256) {
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        if (_value == 0) revert ZeroAmount();
        if (unlockTime <= block.timestamp) revert LockDurationNotInFuture();
        if (unlockTime > block.timestamp + MAXTIME) revert LockDurationTooLong();

        uint256 _tokenId = ++tokenId;
        _mint(_to, _tokenId);

        _depositFor(_tokenId, _value, unlockTime, _locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }

    /// @inheritdoc IVotingEscrow
    function createLock(uint256 _value, uint256 _lockDuration) external nonReentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _msgSender());
    }

    /// @inheritdoc IVotingEscrow
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external nonReentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _to);
    }

    function _increaseAmountFor(uint256 _tokenId, uint256 _value, DepositType _depositType) internal {
        EscrowType _escrowType = escrowType[_tokenId];
        if (_escrowType == EscrowType.LOCKED) revert NotManagedOrNormalNFT();

        LockedBalance memory oldLocked = _locked[_tokenId];

        if (_value == 0) revert ZeroAmount();
        if (oldLocked.amount <= 0) revert NoLockFound();
        if (oldLocked.end <= block.timestamp && !oldLocked.isPermanent) revert LockExpired();

        if (oldLocked.isPermanent) permanentLockBalance += _value;
        _checkpointDelegatee(_delegates[_tokenId], _value, true);
        _depositFor(_tokenId, _value, 0, oldLocked, _depositType);

        if (_escrowType == EscrowType.MANAGED) {
            // increaseAmount called on managed tokens are treated as locked rewards
            address _lockedManagedReward = managedToLocked[_tokenId];
            address _token = token;
            IERC20(_token).safeApprove(_lockedManagedReward, _value);
            IReward(_lockedManagedReward).notifyRewardAmount(_token, _value);
            IERC20(_token).safeApprove(_lockedManagedReward, 0);
        }

        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function increaseAmount(uint256 _tokenId, uint256 _value) external nonReentrant {
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        _increaseAmountFor(_tokenId, _value, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @inheritdoc IVotingEscrow
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external nonReentrant {
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();

        LockedBalance memory oldLocked = _locked[_tokenId];
        if (oldLocked.isPermanent) revert PermanentLock();
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        if (oldLocked.end <= block.timestamp) revert LockExpired();
        if (oldLocked.amount <= 0) revert NoLockFound();
        if (unlockTime <= oldLocked.end) revert LockDurationNotInFuture();
        if (unlockTime > block.timestamp + MAXTIME) revert LockDurationTooLong();

        _depositFor(_tokenId, 0, unlockTime, oldLocked, DepositType.INCREASE_UNLOCK_TIME);

        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function withdraw(uint256 _tokenId) external nonReentrant {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        if (voted[_tokenId]) revert AlreadyVoted();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();

        LockedBalance memory oldLocked = _locked[_tokenId];
        if (oldLocked.isPermanent) revert PermanentLock();
        if (block.timestamp < oldLocked.end) revert LockNotExpired();
        uint256 value = oldLocked.amount.toUint256();

        // Burn the NFT
        _burn(_tokenId);
        _locked[_tokenId] = LockedBalance(0, 0, false);
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // oldLocked can have either expired <= timestamp or zero end
        // oldLocked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, oldLocked, LockedBalance(0, 0, false));

        IERC20(token).safeTransfer(sender, value);

        emit Withdraw(sender, _tokenId, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    /// @inheritdoc IVotingEscrow
    function merge(uint256 _from, uint256 _to) external nonReentrant {
        address sender = _msgSender();
        if (voted[_from]) revert AlreadyVoted();
        if (escrowType[_from] != EscrowType.NORMAL) revert NotNormalNFT();
        if (escrowType[_to] != EscrowType.NORMAL) revert NotNormalNFT();
        if (_from == _to) revert SameNFT();
        if (!_isApprovedOrOwner(sender, _from)) revert NotApprovedOrOwner();
        if (!_isApprovedOrOwner(sender, _to)) revert NotApprovedOrOwner();
        LockedBalance memory oldLockedTo = _locked[_to];
        if (oldLockedTo.end <= block.timestamp && !oldLockedTo.isPermanent) revert LockExpired();

        LockedBalance memory oldLockedFrom = _locked[_from];
        if (oldLockedFrom.isPermanent) revert PermanentLock();
        uint256 end = oldLockedFrom.end >= oldLockedTo.end ? oldLockedFrom.end : oldLockedTo.end;

        _burn(_from);
        _locked[_from] = LockedBalance(0, 0, false);
        _checkpoint(_from, oldLockedFrom, LockedBalance(0, 0, false));

        LockedBalance memory newLockedTo;
        newLockedTo.amount = oldLockedTo.amount + oldLockedFrom.amount;
        newLockedTo.isPermanent = oldLockedTo.isPermanent;
        if (newLockedTo.isPermanent) {
            permanentLockBalance += oldLockedFrom.amount.toUint256();
        } else {
            newLockedTo.end = end;
        }
        _checkpointDelegatee(_delegates[_to], oldLockedFrom.amount.toUint256(), true);
        _checkpoint(_to, oldLockedTo, newLockedTo);
        _locked[_to] = newLockedTo;

        emit Merge(
            sender,
            _from,
            _to,
            oldLockedFrom.amount.toUint256(),
            oldLockedTo.amount.toUint256(),
            newLockedTo.amount.toUint256(),
            newLockedTo.end,
            block.timestamp
        );
        emit MetadataUpdate(_to);
    }

    /// @inheritdoc IVotingEscrow
    function split(
        uint256 _from,
        uint256 _amount
    ) external nonReentrant returns (uint256 _tokenId1, uint256 _tokenId2) {
        address sender = _msgSender();
        address owner = _ownerOf(_from);
        if (owner == address(0)) revert SplitNoOwner();
        if (!canSplit[owner] && !canSplit[address(0)]) revert SplitNotAllowed();
        if (escrowType[_from] != EscrowType.NORMAL) revert NotNormalNFT();
        if (voted[_from]) revert AlreadyVoted();
        if (!_isApprovedOrOwner(sender, _from)) revert NotApprovedOrOwner();
        LockedBalance memory newLocked = _locked[_from];
        if (newLocked.end <= block.timestamp && !newLocked.isPermanent) revert LockExpired();
        int128 _splitAmount = _amount.toInt128();
        if (_splitAmount == 0) revert ZeroAmount();
        if (newLocked.amount <= _splitAmount) revert AmountTooBig();

        // Zero out and burn old veNFT
        _burn(_from);
        _locked[_from] = LockedBalance(0, 0, false);
        _checkpoint(_from, newLocked, LockedBalance(0, 0, false));

        // Create new veNFT using old balance - amount
        newLocked.amount -= _splitAmount;
        _tokenId1 = _createSplitNFT(owner, newLocked);

        // Create new veNFT using amount
        newLocked.amount = _splitAmount;
        _tokenId2 = _createSplitNFT(owner, newLocked);

        emit Split(
            _from,
            _tokenId1,
            _tokenId2,
            sender,
            _locked[_tokenId1].amount.toUint256(),
            _splitAmount.toUint256(),
            newLocked.end,
            block.timestamp
        );
    }

    function _createSplitNFT(address _to, LockedBalance memory _newLocked) private returns (uint256 _tokenId) {
        _tokenId = ++tokenId;
        _locked[_tokenId] = _newLocked;
        _checkpoint(_tokenId, LockedBalance(0, 0, false), _newLocked);
        _mint(_to, _tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function toggleSplit(address _account, bool _bool) external {
        if (_msgSender() != team) revert NotTeam();
        canSplit[_account] = _bool;
    }

    /// @inheritdoc IVotingEscrow
    function lockPermanent(uint256 _tokenId) external {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();
        LockedBalance memory _newLocked = _locked[_tokenId];
        if (_newLocked.isPermanent) revert PermanentLock();
        if (_newLocked.end <= block.timestamp) revert LockExpired();
        if (_newLocked.amount <= 0) revert NoLockFound();

        uint256 _amount = _newLocked.amount.toUint256();
        permanentLockBalance += _amount;
        _newLocked.end = 0;
        _newLocked.isPermanent = true;
        _checkpoint(_tokenId, _locked[_tokenId], _newLocked);
        _locked[_tokenId] = _newLocked;

        emit LockPermanent(sender, _tokenId, _amount, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function unlockPermanent(uint256 _tokenId) external {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();
        if (voted[_tokenId]) revert AlreadyVoted();
        LockedBalance memory _newLocked = _locked[_tokenId];
        if (!_newLocked.isPermanent) revert NotPermanentLock();

        uint256 _amount = _newLocked.amount.toUint256();
        permanentLockBalance -= _amount;
        _newLocked.end = ((block.timestamp + MAXTIME) / WEEK) * WEEK;
        _newLocked.isPermanent = false;
        _delegate(_tokenId, 0);
        _checkpoint(_tokenId, _locked[_tokenId], _newLocked);
        _locked[_tokenId] = _newLocked;

        emit UnlockPermanent(sender, _tokenId, _amount, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    function _balanceOfNFTAt(uint256 _tokenId, uint256 _t) internal view returns (uint256) {
        return BalanceLogicLibrary.balanceOfNFTAt(userPointEpoch, _userPointHistory, _tokenId, _t);
    }

    function _supplyAt(uint256 _timestamp) internal view returns (uint256) {
        return BalanceLogicLibrary.supplyAt(slopeChanges, _pointHistory, epoch, _timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function balanceOfNFT(uint256 _tokenId) public view returns (uint256) {
        if (ownershipChange[_tokenId] == block.number) return 0;
        return _balanceOfNFTAt(_tokenId, block.timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256) {
        return _balanceOfNFTAt(_tokenId, _t);
    }

    /// @inheritdoc IVotingEscrow
    function totalSupply() external view returns (uint256) {
        return _supplyAt(block.timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function totalSupplyAt(uint256 _timestamp) external view returns (uint256) {
        return _supplyAt(_timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => bool) public voted;

    /// @inheritdoc IVotingEscrow
    function setVoterAndDistributor(address _voter, address _distributor) external {
        if (_msgSender() != voter) revert NotVoter();
        voter = _voter;
        distributor = _distributor;
    }

    /// @inheritdoc IVotingEscrow
    function voting(uint256 _tokenId, bool _voted) external {
        if (_msgSender() != voter) revert NotVoter();
        voted[_tokenId] = _voted;
    }

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(uint256 delegator,uint256 delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of each accounts delegate
    mapping(uint256 => uint256) private _delegates;

    /// @notice A record of delegated token checkpoints for each tokenId, by index
    mapping(uint256 => mapping(uint48 => Checkpoint)) private _checkpoints;

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => uint48) public numCheckpoints;

    /// @inheritdoc IVotingEscrow
    mapping(address => uint256) public nonces;

    /// @inheritdoc IVotingEscrow
    function delegates(uint256 delegator) external view returns (uint256) {
        return _delegates[delegator];
    }

    /// @inheritdoc IVotingEscrow
    function checkpoints(uint256 _tokenId, uint48 _index) external view returns (Checkpoint memory) {
        return _checkpoints[_tokenId][_index];
    }

    /// @inheritdoc IVotingEscrow
    function getPastVotes(address _account, uint256 _tokenId, uint256 _timestamp) external view returns (uint256) {
        return DelegationLogicLibrary.getPastVotes(numCheckpoints, _checkpoints, _account, _tokenId, _timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function getPastTotalSupply(uint256 _timestamp) external view returns (uint256) {
        return _supplyAt(_timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function _checkpointDelegator(uint256 _delegator, uint256 _delegatee, address _owner) internal {
        DelegationLogicLibrary.checkpointDelegator(
            _locked,
            numCheckpoints,
            _checkpoints,
            _delegates,
            _delegator,
            _delegatee,
            _owner
        );
    }

    function _checkpointDelegatee(uint256 _delegatee, uint256 balance_, bool _increase) internal {
        DelegationLogicLibrary.checkpointDelegatee(numCheckpoints, _checkpoints, _delegatee, balance_, _increase);
    }

    /// @notice Record user delegation checkpoints. Used by voting system.
    /// @dev Skips delegation if already delegated to `delegatee`.
    function _delegate(uint256 _delegator, uint256 _delegatee) internal {
        LockedBalance memory delegateLocked = _locked[_delegator];
        if (!delegateLocked.isPermanent) revert NotPermanentLock();
        if (_delegatee != 0 && _ownerOf(_delegatee) == address(0)) revert NonExistentToken();
        if (ownershipChange[_delegator] == block.number) revert OwnershipChange();
        if (_delegatee == _delegator) _delegatee = 0;
        uint256 currentDelegate = _delegates[_delegator];
        if (currentDelegate == _delegatee) return;

        uint256 delegatedBalance = delegateLocked.amount.toUint256();
        _checkpointDelegator(_delegator, _delegatee, _ownerOf(_delegator));
        _checkpointDelegatee(_delegatee, delegatedBalance, true);

        emit DelegateChanged(_msgSender(), currentDelegate, _delegatee);
    }

    /// @inheritdoc IVotingEscrow
    function delegate(uint256 delegator, uint256 delegatee) external {
        if (!_isApprovedOrOwner(_msgSender(), delegator)) revert NotApprovedOrOwner();
        return _delegate(delegator, delegatee);
    }

    /// @inheritdoc IVotingEscrow
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidSignatureS();
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegator, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        if (!_isApprovedOrOwner(signatory, delegator)) revert NotApprovedOrOwner();
        if (signatory == address(0)) revert InvalidSignature();
        if (nonce != nonces[signatory]++) revert InvalidNonce();
        if (block.timestamp > expiry) revert SignatureExpired();
        return _delegate(delegator, delegatee);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function clock() external view returns (uint48) {
        return uint48(block.timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function CLOCK_MODE() external pure returns (string memory) {
        return "mode=timestamp";
    }
}