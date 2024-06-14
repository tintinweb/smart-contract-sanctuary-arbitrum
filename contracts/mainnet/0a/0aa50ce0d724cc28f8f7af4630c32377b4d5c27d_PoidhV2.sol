/**
 *Submitted for verification at Arbiscan.io on 2024-06-14
*/

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// File: poidh.sol


pragma solidity 0.8.19;

// import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
// import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

// remix requires version to be specified



interface IPoidhV2Nft is IERC721, IERC721Receiver {
    function mint(address to, uint256 claimCounter, string memory uri) external;
    function safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;
}

contract PoidhV2 {
    /** Data structures */
    struct Bounty {
        uint256 id;
        address issuer;
        string name;
        string description;
        uint256 amount;
        address claimer;
        uint256 createdAt;
        uint256 claimId;
    }

    struct Claim {
        uint256 id;
        address issuer;
        uint256 bountyId;
        address bountyIssuer;
        string name;
        string description;
        uint256 createdAt;
        bool accepted;
    }

    struct Votes {
        uint256 yes;
        uint256 no;
        uint256 deadline;
    }

    /** State variables */
    Bounty[] public bounties;
    Claim[] public claims;

    address public immutable treasury;

    uint256 public bountyCounter;
    uint256 public claimCounter;

    uint256 public votingPeriod = 2 days;
    bool public poidhV2NftSet = false;
    IPoidhV2Nft public immutable poidhV2Nft;

    /** mappings */
    mapping(address => uint256[]) public userBounties;
    mapping(address => uint256[]) public userClaims;
    mapping(uint256 => uint256[]) public bountyClaims;
    mapping(uint256 => address[]) public participants;
    mapping(uint256 => uint256[]) public participantAmounts;
    mapping(uint256 => uint256) public bountyCurrentVotingClaim;
    mapping(uint256 => Votes) public bountyVotingTracker;
    mapping(uint256 => mapping(address => bool)) private hasVoted;

    /** Events */
    event BountyCreated(
        uint256 id,
        address issuer,
        string name,
        string description,
        uint256 amount,
        uint256 createdAt
    );
    event ClaimCreated(
        uint256 id,
        address issuer,
        uint256 bountyId,
        address bountyIssuer,
        string name,
        string description,
        uint256 createdAt
    );
    event ClaimAccepted(
        uint256 bountyId,
        uint256 claimId,
        address claimIssuer,
        address bountyIssuer,
        uint256 fee
    );
    event BountyJoined(uint256 bountyId, address participant, uint256 amount);
    event ClaimSubmittedForVote(uint256 bountyId, uint256 claimId);
    event BountyCancelled(uint256 bountyId, address issuer);
    event ResetVotingPeriod(uint256 bountyId);
    event VoteClaim(address voter, uint256 bountyId, uint256 claimId);
    event WithdrawFromOpenBounty(
        uint256 bountyId,
        address participant,
        uint256 amount
    );

    /** Errors */
    error NoEther();
    error BountyNotFound();
    error ClaimNotFound();
    error VotingOngoing();
    error BountyClaimed();
    error NotOpenBounty();
    error NotSoloBounty();
    error WrongCaller();
    error BountyClosed();
    error transferFailed();
    error IssuerCannotClaim();
    error NoVotingPeriodSet();
    error NotActiveParticipant();
    error BountyAmountTooHigh();
    error IssuerCannotWithdraw();
    error AlreadyVoted();

    /** modifiers */
    /** @dev
     * Checks if the bounty exists
     * Checks if the bounty is claimed
     * Checks if the bounty is open
     * Checks if the bounty is currently being voted on
     */

    modifier bountyChecks(uint256 bountyId) {
        if (bountyId >= bountyCounter) revert BountyNotFound();
        Bounty memory bounty = bounties[bountyId];
        if (bounty.claimer == bounty.issuer) revert BountyClosed();
        if (bounty.claimer != address(0)) revert BountyClaimed();
        _;
    }

    modifier openBountyChecks(uint256 bountyId) {
        if (bountyCurrentVotingClaim[bountyId] > 0) revert VotingOngoing();
        address[] memory p = participants[bountyId];
        if (p.length == 0) revert NotOpenBounty();
        _;
    }

    constructor(
        address _poidhV2Nft,
        address _treasury,
        uint256 _startClaimIndex
    ) {
        poidhV2Nft = IPoidhV2Nft(_poidhV2Nft);
        treasury = _treasury;
        claimCounter = _startClaimIndex;

        for (uint256 i = 0; i < claimCounter; i++) {
            claims.push();
        }
    }

    /**
     * @dev Internal function to create a bounty
     * @param name the name of the bounty
     * @param description the description of the bounty
     * @return bountyId the id of the created bounty
     */
    function _createBounty(
        string calldata name,
        string calldata description
    ) internal returns (uint256 bountyId) {
        bountyId = bountyCounter;
        Bounty memory bounty = Bounty(
            bountyId,
            msg.sender,
            name,
            description,
            msg.value,
            address(0),
            block.timestamp,
            0
        );
        bounties.push(bounty);
        userBounties[msg.sender].push(bountyId);
        ++bountyCounter;

        emit BountyCreated(
            bountyId,
            msg.sender,
            name,
            description,
            msg.value,
            block.timestamp
        );
    }

    /** Create Solo Bounty */
    /**
     * @dev Allows the sender to create a bounty with a given name and description
     * @param name the name of the bounty
     * @param description the description of the bounty
     */
    function createSoloBounty(
        string calldata name,
        string calldata description
    ) external payable {
        if (msg.value == 0) revert NoEther();

        _createBounty(name, description);
    }

    /** Create Open Participation Bounty */
    function createOpenBounty(
        string calldata name,
        string calldata description
    ) external payable {
        if (msg.value == 0) revert NoEther();

        uint256 bountyId = _createBounty(name, description);

        participants[bountyId].push(msg.sender);
        participantAmounts[bountyId].push(msg.value);
    }

    /** Join Open Bounty
     * @dev Allows the sender join an open bounty as a participant with msg.value shares
     * @param bountyId the id of the bounty to be joined
     */
    function joinOpenBounty(
        uint256 bountyId
    ) external payable bountyChecks(bountyId) openBountyChecks(bountyId) {
        if (msg.value == 0) revert NoEther();

        address[] memory p = participants[bountyId];

        uint256 i;
        do {
            if (msg.sender == p[i]) {
                revert WrongCaller();
            }
            ++i;
        } while (p.length > i);

        Bounty memory bounty = bounties[bountyId];

        participants[bountyId].push(msg.sender);
        participantAmounts[bountyId].push(msg.value);

        bounties[bountyId].amount = bounty.amount + msg.value;

        emit BountyJoined(bountyId, msg.sender, msg.value);
    }

    /** Cancel Solo Bounty
     * @dev Allows the sender to cancel a bounty with a given id
     * @param bountyId the id of the bounty to be canceled
     */
    function cancelSoloBounty(uint bountyId) external bountyChecks(bountyId) {
        Bounty memory bounty = bounties[bountyId];
        if (msg.sender != bounty.issuer) revert WrongCaller();

        address[] memory p = participants[bountyId];
        if (p.length > 0) revert NotSoloBounty();

        uint refundAmount = bounty.amount;
        bounties[bountyId].claimer = msg.sender;

        (bool success, ) = bounty.issuer.call{value: refundAmount}('');
        if (!success) revert transferFailed();

        emit BountyCancelled(bountyId, bounty.issuer);
    }

    /** Cancel Open Bounty */
    function cancelOpenBounty(
        uint256 bountyId
    ) external bountyChecks(bountyId) openBountyChecks(bountyId) {
        Bounty memory bounty = bounties[bountyId];
        if (msg.sender != bounty.issuer) revert WrongCaller();

        address[] memory p = participants[bountyId];
        uint256[] memory amounts = participantAmounts[bountyId];
        uint256 i;

        do {
            address participant = p[i];
            uint256 amount = amounts[i];

            if (participant == address(0)) {
                ++i;
                continue;
            }

            (bool success, ) = participant.call{value: amount}('');
            if (!success) revert transferFailed();

            ++i;
        } while (i < p.length);

        bounties[bountyId].claimer = msg.sender;

        emit BountyCancelled(bountyId, bounty.issuer);
    }

    /**
     * @dev Allows the sender to create a claim on a given bounty
     * @param bountyId the id of the bounty being claimed
     * @param name the name of the claim
     * @param uri the URI of the claim
     * @param description the description of the claim
     */
    function createClaim(
        uint256 bountyId,
        string calldata name,
        string calldata uri,
        string calldata description
    ) external bountyChecks(bountyId) {
        Bounty memory bounty = bounties[bountyId];
        if (bounty.issuer == msg.sender) revert IssuerCannotClaim();

        uint256 claimId = claimCounter;

        Claim memory claim = Claim(
            claimId,
            msg.sender,
            bountyId,
            bounty.issuer,
            name,
            description, // new field
            block.timestamp,
            false
        );

        claims.push(claim);
        userClaims[msg.sender].push(claimId);
        bountyClaims[bountyId].push(claimId);

        poidhV2Nft.mint(address(this), claimId, uri);

        claimCounter++;

        emit ClaimCreated(
            claimId,
            msg.sender,
            bountyId,
            bounty.issuer,
            name,
            description,
            block.timestamp
        );
    }

    /**
     * @dev Bounty issuer submits claim for voting and casts their vote
     * @param bountyId the id of the bounty being claimed
     */
    function submitClaimForVote(
        uint256 bountyId,
        uint256 claimId
    ) external bountyChecks(bountyId) openBountyChecks(bountyId) {
        if (claimId >= claimCounter) revert ClaimNotFound();
        if (hasVoted[bountyId][msg.sender] == true) revert AlreadyVoted();

        hasVoted[bountyId][msg.sender] = true;

        uint256[] memory amounts = participantAmounts[bountyId];

        Votes storage votingTracker = bountyVotingTracker[bountyId];
        votingTracker.yes += amounts[0];
        votingTracker.deadline = block.timestamp + votingPeriod;
        bountyCurrentVotingClaim[bountyId] = claimId;

        emit ClaimSubmittedForVote(bountyId, claimId);
    }

    /**
     * @dev Vote on an open bounty
     * @param bountyId the id of the bounty to vote for
     */
    function voteClaim(
        uint256 bountyId,
        bool vote
    ) external bountyChecks(bountyId) {
        if (hasVoted[bountyId][msg.sender] == true) revert AlreadyVoted();
        hasVoted[bountyId][msg.sender] = true;

        address[] memory p = participants[bountyId];
        if (p.length == 0) revert NotOpenBounty();

        uint256 currentClaim = bountyCurrentVotingClaim[bountyId];
        if (currentClaim == 0) revert NoVotingPeriodSet();

        uint256[] memory amounts = participantAmounts[bountyId];
        uint256 i;
        uint256 participantAmount;

        do {
            if (msg.sender == p[i]) {
                participantAmount = amounts[i];
                break;
            }

            ++i;
        } while (i < p.length);

        if (participantAmount == 0) revert NotActiveParticipant();

        Votes storage votingTracker = bountyVotingTracker[bountyId];
        vote
            ? votingTracker.yes += participantAmount
            : votingTracker.no += participantAmount;

        emit VoteClaim(msg.sender, bountyId, currentClaim);
    }

    function resolveVote(uint256 bountyId) external {
        address[] memory p = participants[bountyId];
        if (p.length == 0) revert NotOpenBounty();

        uint256 currentClaim = bountyCurrentVotingClaim[bountyId];
        if (currentClaim == 0) revert NoVotingPeriodSet();

        Votes memory votingTracker = bountyVotingTracker[bountyId];
        if (block.timestamp < votingTracker.deadline) revert VotingOngoing();

        if (votingTracker.yes > ((votingTracker.no + votingTracker.yes) / 2)) {
            // Accept the claim and close out the bounty
            _acceptClaim(bountyId, currentClaim);
        } else {
            bountyCurrentVotingClaim[bountyId] = 0;
            delete bountyVotingTracker[bountyId];

            for (uint256 i = 0; i < p.length; i++) {
                hasVoted[bountyId][p[i]] = false;
            }
            emit ResetVotingPeriod(bountyId);
        }
    }

    /**
     * @dev Reset the voting period for an open bounty
     * @param bountyId the id of the bounty being claimed
     */
    function resetVotingPeriod(
        uint256 bountyId
    ) external bountyChecks(bountyId) {
        if (participants[bountyId].length == 0) revert NotOpenBounty();

        uint256 currentClaim = bountyCurrentVotingClaim[bountyId];
        if (currentClaim == 0) revert NoVotingPeriodSet();

        Votes storage votingTracker = bountyVotingTracker[bountyId];
        if (block.timestamp < votingTracker.deadline) revert VotingOngoing();

        bountyCurrentVotingClaim[bountyId] = 0;
        delete bountyVotingTracker[bountyId];

        emit ResetVotingPeriod(bountyId);
    }

    /**
     * @dev Allow bounty participants to withdraw from a bounty that is not currently being voted on
     * @param bountyId the id of the bounty to withdraw from
     */
    function withdrawFromOpenBounty(
        uint256 bountyId
    ) external bountyChecks(bountyId) openBountyChecks(bountyId) {
        Bounty memory bounty = bounties[bountyId];
        if (bounty.issuer == msg.sender) revert IssuerCannotWithdraw();
        address[] memory p = participants[bountyId];
        uint256[] memory amounts = participantAmounts[bountyId];
        uint256 i;

        do {
            if (msg.sender == p[i]) {
                uint256 amount = amounts[i];
                participants[bountyId][i] = address(0);
                participantAmounts[bountyId][i] = 0;
                bounties[bountyId].amount -= amount;

                (bool success, ) = p[i].call{value: amount}('');
                if (!success) revert transferFailed();

                emit WithdrawFromOpenBounty(bountyId, msg.sender, amount);

                break;
            }

            ++i;
        } while (i < p.length);
    }

    /**
     * @dev Allows the sender to accept a claim on their bounty
     * @param bountyId the id of the bounty being claimed
     * @param claimId the id of the claim being accepted
     */
    function acceptClaim(
        uint256 bountyId,
        uint256 claimId
    ) external bountyChecks(bountyId) {
        if (claimId >= claimCounter) revert ClaimNotFound();

        Bounty storage bounty = bounties[bountyId];
        /**
         * @dev note: if the bounty has more than one participant, it is considered truly open, and the issuer cannot accept the claim without a vote.
         */
        address[] memory p = participants[bountyId];
        if (p.length > 1) {
            uint256 i = 1; // Start from index 1 since the first participant is always non-zero
            do {
                if (p[i] != address(0)) {
                    revert NotSoloBounty();
                }
                i++;
            } while (i < p.length);
        } else {
            if (msg.sender != bounty.issuer) revert WrongCaller();
        }

        _acceptClaim(bountyId, claimId);
    }

    /**
     * @dev Internal function to accept a claim
     * @param bountyId the id of the bounty being claimed
     * @param claimId the id of the claim being accepted
     */
    function _acceptClaim(uint256 bountyId, uint256 claimId) internal {
        if (claimId >= claimCounter) revert ClaimNotFound();
        Bounty storage bounty = bounties[bountyId];
        if (bounty.amount > address(this).balance) revert BountyAmountTooHigh();

        Claim memory claim = claims[claimId];
        if (claim.bountyId != bountyId) revert ClaimNotFound();

        address claimIssuer = claim.issuer;
        uint256 bountyAmount = bounty.amount;

        // Close out the bounty
        bounty.claimer = claimIssuer;
        bounty.claimId = claimId;
        claims[claimId].accepted = true;

        // Calculate the fee (2.5% of bountyAmount)
        uint256 fee = (bountyAmount * 25) / 1000;

        // Subtract the fee from the bountyAmount
        uint256 payout = bountyAmount - fee;

        // Transfer the claim NFT to the bounty issuer
        poidhV2Nft.safeTransfer(address(this), bounty.issuer, claimId, '');

        // Transfer the bounty amount to the claim issuer
        (bool success, ) = claimIssuer.call{value: payout}('');
        if (!success) revert transferFailed();

        // Transfer the fee to the treasury
        (bool feeSuccess, ) = treasury.call{value: fee}('');
        if (!feeSuccess) revert transferFailed();

        emit ClaimAccepted(bountyId, claimId, claimIssuer, bounty.issuer, fee);
    }

    /** Getter for the length of the bounties array */
    function getBountiesLength() public view returns (uint256) {
        return bounties.length;
    }

    /**
     * @dev Returns an array of Bounties from start to end index
     * @param offset the index to start fetching bounties from
     * @return result an array of Bounties from start to end index
     */
    function getBounties(
        uint offset
    ) public view returns (Bounty[10] memory result) {
        uint256 length = bounties.length;
        uint256 remaining = length - offset;
        uint256 numBounties = remaining < 10 ? remaining : 10;

        for (uint i = 0; i < numBounties; i++) {
            Bounty storage bounty = bounties[offset + i];

            result[i] = bounty;
        }
    }

    /** get claims by bountyId*/
    /** 
        @dev Returns all claims associated with a bounty
        @param bountyId the id of the bounty to fetch claims for 
    */
    function getClaimsByBountyId(
        uint256 bountyId
    ) public view returns (Claim[] memory) {
        uint256[] memory bountyClaimIndexes = bountyClaims[bountyId];
        Claim[] memory bountyClaimsArray = new Claim[](
            bountyClaimIndexes.length
        );

        for (uint256 i = 0; i < bountyClaimIndexes.length; i++) {
            bountyClaimsArray[i] = claims[bountyClaimIndexes[i]];
        }

        return bountyClaimsArray;
    }

    /** get bounties by user */
    /** 
        @dev Returns all bounties for a given user 
        @param user the address of the user to fetch bounties for
    */
    function getBountiesByUser(
        address user,
        uint256 offset
    ) public view returns (Bounty[10] memory result) {
        uint256[] memory bountyIds = userBounties[user];
        uint256 length = bountyIds.length;
        uint256 remaining = length - offset;
        uint256 numBounties = remaining < 10 ? remaining : 10;

        for (uint i = 0; i < numBounties; i++) {
            result[i] = bounties[bountyIds[offset + i]];
        }
    }

    /** get claims by user */
    /** 
        @dev Returns all claims for a given user 
        @param user the address of the user to fetch claims for
    */
    function getClaimsByUser(
        address user
    ) public view returns (Claim[] memory) {
        uint256[] storage userClaimIndexes = userClaims[user];
        Claim[] memory userClaimsArray = new Claim[](userClaimIndexes.length);

        for (uint256 i = 0; i < userClaimIndexes.length; i++) {
            userClaimsArray[i] = claims[userClaimIndexes[i]];
        }

        return userClaimsArray;
    }

    /** get bounty participants */
    /** 
        @dev Returns all participants for a given bounty 
        @param bountyId the id of the bounty to fetch participants for
    */
    function getParticipants(
        uint256 bountyId
    ) public view returns (address[] memory, uint256[] memory) {
        address[] memory p = participants[bountyId];
        uint256[] memory a = participantAmounts[bountyId];
        uint256 pLength = p.length;

        address[] memory result = new address[](pLength);
        uint256[] memory amounts = new uint256[](pLength);

        for (uint256 i = 0; i < pLength; i++) {
            result[i] = p[i];
            amounts[i] = a[i];
        }

        return (result, amounts);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}