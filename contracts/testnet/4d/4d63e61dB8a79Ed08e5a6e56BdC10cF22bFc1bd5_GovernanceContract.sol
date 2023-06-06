/**
 *Submitted for verification at Arbiscan on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract GovernanceContract {
    address public owner;

    struct Proposal {
        uint256 lockingPeriodEnd;
        uint256 votingPeriodStart;
        uint256 votingPeriodEnd;
        uint256 totalLocked;
        uint256 votes;
        bytes description;
        bytes title;
        bytes[] options;
        mapping(uint256 => uint256) voteCounts;
        bool cancelled;
    }

    struct ProposalVoted {
        bytes32 proposalId;
        uint256 vote;
        uint256 lockAmount;
        uint256 voteDate;
        bool hasVoted;
        bool hasWithdrawn;
    }

    struct Voter {
        uint256 totalLockedTokens;
        uint256 totalVotes;
        uint256[] proposalsVotedIds;
        mapping(bytes32 => ProposalVoted) proposalsVoted;
    }

    mapping(address => Voter) private voters;
    mapping(bytes32 => Proposal) private proposals;
    mapping(address => bool) public isProposer;

    bytes32[] private proposalIds;

    uint256 public votingDuration; // Duration in seconds
    uint256 public proposalCount;
    uint256 public votingEndOffset; // Number of days after voting ends before unlocking is allowed

    IERC20 public GovernanceToken;
    // Events
    event ProposalCreated(
        bytes32 proposalId,
        uint256 votingStart,
        bytes title,
        bytes description
    );
    event VoteCasted(bytes32 proposalId, address voter, uint256 vote);
    event TokensWithdrawn(bytes32 proposalId, address voter, uint256 amount);

    // Modifier to check if the sender is the proposer
    modifier onlyProposer() {
        require(
            isProposer[msg.sender],
            "Only the proposer can perform this action"
        );
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Modifier to check if the voting period has ended
    modifier votingPeriodEnded(bytes32 proposalId) {
        require(
            block.timestamp >= proposals[proposalId].votingPeriodEnd ||
                proposals[proposalId].cancelled,
            "Voting period has not ended"
        );
        _;
    }

    /**
     * @dev Constructor
     * @param _votingDuration Duration of the voting period in seconds.
     * @param _votingEndOffset Number of days after voting ends before unlocking is allowed.
     * @param _governanceToken Address of the ERC20 token used for governance.
     */
    constructor(
        uint256 _votingDuration,
        uint256 _votingEndOffset,
        address _governanceToken
    ) {
        require(_governanceToken != address(0), "Token address cannot be 0x0");
        votingDuration = _votingDuration;
        votingEndOffset = _votingEndOffset;
        GovernanceToken = IERC20(_governanceToken);
        owner = msg.sender;
    }

    function hashProposal(
        uint256 _votingStartTime,
        bytes memory descriptionHash
    ) public pure returns (bytes32) {
        return
            bytes32(keccak256(abi.encode(_votingStartTime, descriptionHash)));
    }

    /**
     * @dev Creates a new proposal.
     * @param _votingStartTime Time at which voting will start.
     * @param _description Description of the proposal.
     * @param _options Array of bytess representing the available voting options.
     */
    function createProposal(
        uint256 _votingStartTime,
        bytes memory _title,
        bytes memory _description,
        bytes[] memory _options
    ) external onlyProposer returns (bytes32) {
        bytes32 proposalId = bytes32(
            keccak256(abi.encode(_votingStartTime, _description))
        );
        Proposal storage newProposal = proposals[proposalId];
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.options = _options;
        newProposal.votingPeriodStart = _votingStartTime;
        newProposal.votingPeriodEnd = _votingStartTime + votingDuration;
        newProposal.lockingPeriodEnd =
            _votingStartTime +
            votingDuration +
            votingEndOffset;

        proposalIds.push(proposalId);
        proposalCount++;

        emit ProposalCreated(proposalId, _votingStartTime,_title, _description);

        return proposalId;
    }

    /**
     * @dev Casts a vote for a proposal.
     * @param _proposalId ID of the proposal.
     * @param _vote The index of the voting option selected.
     * @param weightAmount Amount of tokens to be locked for voting.
     */
    function vote(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 weightAmount
    ) external {
        Proposal storage proposal = proposals[_proposalId];

        require(_vote < proposal.options.length, "Invalid vote");
        require(weightAmount > 0, "Weight cannot be zero");
        require(
            GovernanceToken.allowance(msg.sender, address(this)) >=
                weightAmount,
            "Insufficient allowance"
        );
        require(
            GovernanceToken.balanceOf(msg.sender) >= weightAmount,
            "Insufficient balance"
        );

        Voter storage voter = voters[msg.sender];

        require(
            block.timestamp >= proposal.votingPeriodStart,
            "Voting period has not started"
        );
        require(
            block.timestamp <= proposal.votingPeriodEnd,
            "Voting period has ended"
        );
        require(
            !voter.proposalsVoted[_proposalId].hasVoted,
            "Already voted for this proposal"
        );
        require(!proposal.cancelled, "Proposal has been cancelled");

        // Update vote count
        proposal.voteCounts[_vote] += weightAmount;
        proposal.totalLocked += weightAmount;
        proposal.votes++;

        voter.proposalsVoted[_proposalId].vote = _vote;
        voter.proposalsVoted[_proposalId] = ProposalVoted({
            proposalId: _proposalId,
            vote: _vote,
            lockAmount: weightAmount,
            voteDate: block.timestamp,
            hasVoted: true,
            hasWithdrawn: false
        });
        voter.totalLockedTokens += weightAmount;
        voter.totalVotes++;

        GovernanceToken.transferFrom(msg.sender, address(this), weightAmount);

        emit VoteCasted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Withdraws tokens after the locking period ends.
     * @param _proposalId ID of the proposal for which the tokens were locked.
     */

    function withdrawTokens(
        bytes32 _proposalId
    ) external votingPeriodEnded(_proposalId) {
        Voter storage voter = voters[msg.sender];
        Proposal storage proposal = proposals[_proposalId];
        require(
            voter.proposalsVoted[_proposalId].lockAmount > 0,
            "No locked tokens"
        );
        require(
            !voter.proposalsVoted[_proposalId].hasWithdrawn,
            "Tokens already withdrawn"
        );
        //allow insta withdraw if proposal was cancelled
        require(
            (block.timestamp > proposal.lockingPeriodEnd) || proposal.cancelled,
            "Cannot withdraw before lock time"
        );

        uint256 amountToWithdraw = voter.proposalsVoted[_proposalId].lockAmount;

        // Transfer locked tokens back to the sender
        GovernanceToken.transfer(msg.sender, amountToWithdraw);

        voter.totalLockedTokens -= amountToWithdraw;
        voter.proposalsVoted[_proposalId].hasWithdrawn = true;

        emit TokensWithdrawn(_proposalId,msg.sender, amountToWithdraw);
    }

    /**
     * @dev Cancels a proposal.
     * @param _proposalId ID of the proposal to be cancelled.
     */
    function cancelProposal(bytes32 _proposalId) external onlyProposer {
        Proposal storage proposal = proposals[_proposalId];
        require(
            block.timestamp <= proposals[_proposalId].votingPeriodEnd,
            "Voting already ended!"
        );

        proposal.cancelled = true;
    }

    /**
     * @dev Sets the address of the  governance token.
     * @param _token Address of the new token .
     */
    function setGovernanceToken(address _token) external onlyOwner {
        GovernanceToken = IERC20(_token);
    }

    /**
     * @dev Adds a new proposer.
     * @param _proposer Address of the proposer to be added.
     */
    function setProposer(address _proposer) external onlyOwner {
        isProposer[_proposer] = !isProposer[_proposer];
    }

    /**
     * @dev Sets the time after vote end after which withdraw is available.
     * @param _offset new offset.
     */
    function setVotingEndOffset(uint256 _offset) external onlyOwner {
        require(_offset != 0, "Offset cannot be zero");
        votingEndOffset = _offset;
    }

    /**
     * @dev Adds another option to a proposal.
     * @param _proposalId ID of the proposal.
     * @param _option option to be added
     */
    function addOption(
        bytes32 _proposalId,
        bytes memory _option
    ) external onlyProposer {
        Proposal storage proposal = proposals[_proposalId];
        require(
            block.timestamp <= proposals[_proposalId].votingPeriodEnd,
            "Voting already ended!"
        );

        proposal.options.push(_option);
    }

    function getState(bytes32 _proposalId) public view returns (bool) {
        return
            block.timestamp > proposals[_proposalId].votingPeriodEnd ||
            proposals[_proposalId].cancelled;
    }

    /**
     * @dev Gets the IDs of all proposals.
     * @return Array of proposal IDs.
     */
    function getProposals() public view returns (bytes32[] memory) {
        return proposalIds;
    }

    /**
     * @dev Gets the details of a proposal.
     * @param _proposalId ID of the proposal.
     */
    function getProposal(
        bytes32 _proposalId
    )
        public
        view
        returns (
            uint256 lockingPeriodEnd,
            uint256 votingPeriodStart,
            uint256 votingPeriodEnd,
            uint256 totalLocked,
            bytes memory description,
            bytes[] memory options,
            uint256[] memory voteCounts,
            bool cancelled
        )
    {
        Proposal storage proposal = proposals[_proposalId];

        uint256 optionsLength = proposal.options.length;
        voteCounts = new uint256[](optionsLength);

        for (uint256 i = 0; i < optionsLength; i++) {
            voteCounts[i] = proposal.voteCounts[i];
        }

        return (
            proposal.lockingPeriodEnd,
            proposal.votingPeriodStart,
            proposal.votingPeriodEnd,
            proposal.totalLocked,
            proposal.description,
            proposal.options,
            voteCounts,
            proposal.cancelled
        );
    }

    /**
     * @dev Gets the details of a voter.
     * @param _voter address of the voter.
     */
    function getVoter(
        address _voter
    )
        public
        view
        returns (
            uint256 totalLockedTokens,
            uint256 totalVotes,
            uint256[] memory proposalsVotedIds
        )
    {
        Voter storage voter = voters[_voter];

        return (
            voter.totalLockedTokens,
            voter.totalVotes,
            voter.proposalsVotedIds
        );
    }

    /**
     * @dev Gets the details of a proposal voted by a voter.
     * @param _proposalId ID of the proposal.
     * @param _voter address of the voter
     */
    function getVotedProposlForVoter(
        address _voter,
        bytes32 _proposalId
    ) public view returns (ProposalVoted memory proposalVoted) {
        return voters[_voter].proposalsVoted[_proposalId];
    }

    /**
     * @dev Gets the percents of votes of a proposal.
     * @param _proposalId ID of the proposal.
     */
    function getPercent(
        bytes32 _proposalId
    )
        public
        view
        returns (uint256[] memory voteCounts, uint256 totalVoteCount)
    {
        Proposal storage proposal = proposals[_proposalId];

        uint256 optionsLength = proposal.options.length;
        voteCounts = new uint256[](optionsLength);

        for (uint256 i = 0; i < optionsLength; i++) {
            voteCounts[i] = proposal.voteCounts[i];
        }

        return (voteCounts, proposal.totalLocked);
    }

    //test function
    function convertString(
        string memory _string
    ) public pure returns (bytes memory) {
        return bytes(_string);
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (bytes memory);

    function symbol() external view returns (bytes memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}