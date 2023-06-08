/**
 *Submitted for verification at Arbiscan on 2023-06-08
*/

/**
 *Submitted for verification at Arbiscan on 2023-06-07
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (bytes memory);

    function symbol() external view returns (bytes memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract GovernanceContract {
    string public name = "BullBear AI: Governance";
    address public owner;

    struct Proposal {
        uint256 lockingPeriodEnd;
        uint256 votingPeriodStart;
        uint256 votingPeriodEnd;
        uint256 totalLocked;
        uint256 votes;
        uint256 optionsCount;
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
        bytes32[] proposalsVotedIds;
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
    event ProposalCreated(bytes32 proposalId, uint256 votingStart);

    event ProposalCancelled(bytes32 proposalId, uint256 cancelledOn);

    event VoteCasted(
        bytes32 indexed proposalId,
        address indexed voter,
        uint256 vote,
        uint256 amount,
        uint256 date
    );
    event TokensWithdrawn(
        bytes32 indexed proposalId,
        address voter,
        uint256 amount
    );

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
        isProposer[msg.sender] = true;
    }

    /**
     * @dev Creates a new proposal.
     * @param _votingStartTime Time at which voting will start.
     * @param _options count of options
     */
    function createProposal(uint256 _votingStartTime, uint256 _options)
        external
        onlyProposer
        returns (bytes32)
    {
        bytes32 proposalId = bytes32(
            keccak256(abi.encode(_votingStartTime, _options, msg.sender))
        );
        Proposal storage newProposal = proposals[proposalId];
        newProposal.optionsCount = _options;
        newProposal.votingPeriodStart = _votingStartTime;
        newProposal.votingPeriodEnd = _votingStartTime + votingDuration;
        newProposal.lockingPeriodEnd =
            _votingStartTime +
            votingDuration +
            votingEndOffset;

        proposalIds.push(proposalId);
        proposalCount++;

        emit ProposalCreated(proposalId, _votingStartTime);

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

        require(_vote < proposal.optionsCount, "Invalid vote");
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
        require(!proposal.cancelled, "Proposal has been cancelled");

        GovernanceToken.transferFrom(msg.sender, address(this), weightAmount);

        proposal.voteCounts[_vote] += weightAmount;
        proposal.totalLocked += weightAmount;

        if (voter.proposalsVoted[_proposalId].hasVoted) {
            require(
                voter.proposalsVoted[_proposalId].vote == _vote,
                "Cannot change option."
            );
            voter.proposalsVoted[_proposalId].lockAmount += weightAmount;
        } else {
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
            voter.proposalsVotedIds.push(_proposalId);
            voter.totalVotes++;
        }

        voter.totalLockedTokens += weightAmount;

        emit VoteCasted(
            _proposalId,
            msg.sender,
            _vote,
            weightAmount,
            block.timestamp
        );
    }

    /**
     * @dev Withdraws tokens after the locking period ends.
     * @param _proposalId ID of the proposal for which the tokens were locked.
     */

    function withdrawTokens(bytes32 _proposalId)
        external
        votingPeriodEnded(_proposalId)
    {
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

        emit TokensWithdrawn(_proposalId, msg.sender, amountToWithdraw);
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

        emit ProposalCancelled(_proposalId, block.timestamp);
    }

    /**
     * @dev Sets the address of the  governance token.
     * @param _token Address of the new token .
     */
    function setGovernanceToken(address _token) external onlyOwner {
        GovernanceToken = IERC20(_token);
    }

    /**
     * @dev Adds a new owner.
     * @param _owner Address of the proposer to be added.
     */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     * @dev Adds a new proposer.
     * @param _proposer Address of the proposer to be added.
     */
    function setProposer(address _proposer) external onlyOwner {
        isProposer[_proposer] = !isProposer[_proposer];
    }

    /**
     * @dev Sets the duration of voting.
     * @param _duration new offset.
     */
    function setVotingDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Duration cannot be zero");
        votingDuration = _duration;
    }

    /**
     * @dev Sets the time after vote end after which withdraw is available.
     * @param _offset new offset.
     */
    function setVotingEndOffset(uint256 _offset) external onlyOwner {
        require(_offset > 0, "Offset cannot be zero");
        votingEndOffset = _offset;
    }

    /**
     * @dev Adds another option to a proposal.
     * @param _proposalId ID of the proposal.
     */
    function addOption(bytes32 _proposalId) external onlyProposer {
        Proposal storage proposal = proposals[_proposalId];
        require(
            block.timestamp <= proposals[_proposalId].votingPeriodEnd,
            "Voting already ended!"
        );
        require(!proposal.cancelled, "Voting Cancelled");

        proposal.optionsCount++;
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
    function getProposal(bytes32 _proposalId)
        public
        view
        returns (
            uint256 lockingPeriodEnd,
            uint256 votingPeriodStart,
            uint256 votingPeriodEnd,
            uint256 totalLocked,
            uint256 optionsCount,
            uint256[] memory voteCounts,
            bool cancelled
        )
    {
        Proposal storage proposal = proposals[_proposalId];

        uint256 optionsLength = proposal.optionsCount;
        voteCounts = new uint256[](optionsLength);

        for (uint256 i = 0; i < optionsLength; i++) {
            voteCounts[i] = proposal.voteCounts[i];
        }

        return (
            proposal.lockingPeriodEnd,
            proposal.votingPeriodStart,
            proposal.votingPeriodEnd,
            proposal.totalLocked,
            proposal.optionsCount,
            voteCounts,
            proposal.cancelled
        );
    }

    /**
     * @dev Gets the details of a voter.
     * @param _voter address of the voter.
     */
    function getVoter(address _voter)
        public
        view
        returns (
            uint256 totalLockedTokens,
            uint256 totalVotes,
            bytes32[] memory proposalsVotedIds
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
    function getVotedProposlForVoter(address _voter, bytes32 _proposalId)
        public
        view
        returns (ProposalVoted memory proposalVoted)
    {
        return voters[_voter].proposalsVoted[_proposalId];
    }

    /**
     * @dev Gets the percents of votes of a proposal.
     * @param _proposalId ID of the proposal.
     */
    function getPercent(bytes32 _proposalId)
        public
        view
        returns (uint256[] memory voteCounts, uint256 totalVoteCount)
    {
        Proposal storage proposal = proposals[_proposalId];

        uint256 optionsLength = proposal.optionsCount;
        voteCounts = new uint256[](optionsLength);

        for (uint256 i = 0; i < optionsLength; i++) {
            voteCounts[i] = proposal.voteCounts[i];
        }

        return (voteCounts, proposal.totalLocked);
    }

    function rescueToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function clearStuckEthBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).call{value: amountETH}(new bytes(0));
    }

    function updateBeginTime(bytes32 _proposalId, uint256 _beginTime)
        external
        onlyProposer
    {
        Proposal storage proposal = proposals[_proposalId];
        require(
            block.timestamp <= proposal.votingPeriodEnd,
            "Voting period has ended"
        );
        require(!proposal.cancelled, "Proposal has been cancelled");

        proposal.votingPeriodStart = _beginTime;
    }

    function updateEndTime(bytes32 _proposalId, uint256 _endTime)
        external
        onlyProposer
    {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.cancelled, "Proposal has been cancelled");

        proposal.votingPeriodEnd = _endTime;
    }

    receive() external payable {}
}