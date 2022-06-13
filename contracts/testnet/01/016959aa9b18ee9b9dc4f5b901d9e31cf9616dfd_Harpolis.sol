/**
 *Submitted for verification at Arbiscan on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract NonTransferrableERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    function transfer(address to, uint256 amount) external pure returns (bool) {
        return false;
    }

    function allowance(address owner, address spender) external pure returns (uint256) {
        return 0;
    }

    function approve(address spender, uint256 amount) external pure returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external pure returns (bool) {
        return false;
    }
}

function sqrt(uint256 x) pure returns (uint256 y) {
    uint256 z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}

enum Vote {
    NONE,
    ACCEPTED,
    REJECTED
}

struct Property {
    address owner; // owner of property
    uint256 valuation; // valuation of property given by owner
}

struct Citizen {
    uint256 balance; // balance of citizen to pay for taxes
    uint256 pendingTax; // total pending tax that needs to be paid
    uint256 startTimestamp; // timestamp when citizen started acquired first property
    uint256 totalPropertyWorth; // sum of all properties valuations for calculating tax
    uint256 lastPropertyUpdateTimestamp; // timestamp when citizen last changed total worth
    uint256 periodsOnLastUpdate; // tax periods collected
    uint256 lifetimeTaxesPaid; // total taxes paid by citizen
    uint256 numberOfProperties; // number of properties citizen owns
    mapping(uint256 => bool) properties; // properties owned by citizen
}

struct Proposal {
    address creator; // creator of proposal
    address target; // the address the governence call is sent to; can be itself
    bool resolved; // whether the proposal has been marked as resolved
    uint256 value; // funds to be used; can be zero
    uint256 creationTime; // time when proposal was created
    uint256 acceptVotes; // accepted proposal votes
    uint256 rejectVotes; // rejected proposal votes
    uint256 votingClosingTime; // time when voting finishes
    uint256 lastProcessedVoteIdx; // last processed vote index
    bytes data; // data to be sent in the call
    address[] voters; // list of voters who voted on the proposal
    mapping(address => Vote) votes; // mapping of voters to votes
}

contract Harpolis is NonTransferrableERC20 {
    // ===-===-=== DATA LAYOUT ===-===-===

    string public constant name = "Harpolis";

    string public constant symbol = "HAR";

    uint256 public constant TAX_COLLECTION_TIMEFRAME = 1 weeks;

    address public governor;

    uint256 public taxRate;

    uint256 public worthToContributionRatio;

    uint256 public votingDuration;

    uint256 public executionDuration;

    mapping(address => Citizen) public citizens;

    mapping(uint256 => Property) public properties;

    uint256 public tokenReserve;

    uint256 public override totalSupply;

    mapping(uint256 => Proposal) public proposals;

    uint256 public proposalsCount;

    // ===-===-=== EVENTS ===-===-===

    event GovernanceTransferred(address indexed previousGovernor, address indexed newGovernor);

    event VoteCasted(address voter, uint256 proposalId, Vote vote);

    event ProposalCreated(address creator, uint256 proposalId, uint256 votingClosingTime, string description);

    event PropertyMinted(uint256 propertyId, string info);

    event PropertyBurned(uint256 propertyId);

    event PropertyTransferred(uint256 propertyId, address newOwner, uint256 newValuation);

    // ===-===-=== MODIFIER ===-===-===

    modifier onlyGovernance() {
        require(msg.sender == governor, "call must be through governance");
        _;
    }

    modifier onlyPropertyOwner(uint256 _propertyId) {
        require(properties[_propertyId].owner == msg.sender, "caller must be owner of the property");
        _;
    }

    modifier onlyCitizen(address _citizen) {
        require(citizens[_citizen].totalPropertyWorth > 0, "caller must be citizen");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalsCount, "proposal must be valid");
        _;
    }

    // ===-===-=== CONSTRUCTOR ===-===-===

    constructor(
        uint256 _taxRate,
        uint256 _worthToContributionRatio,
        uint256 _votingDuration,
        uint256 _executionDuration,
        uint256 _startingSupply
    ) payable {
        _transferGovernance(msg.sender);
        mintTokens(_startingSupply);

        taxRate = _taxRate;
        worthToContributionRatio = _worthToContributionRatio;
        votingDuration = _votingDuration;
        executionDuration = _executionDuration;
    }

    // ===-===-=== GOVERNANCE ===-===-===

    function completeAnarchy() public onlyGovernance {
        _transferGovernance(address(0));
    }

    function transferGovernance(address newGovernor) public onlyGovernance {
        require(newGovernor != address(0), "new Governor is the zero address");
        _transferGovernance(newGovernor);
    }

    function _transferGovernance(address newGovernor) internal {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernanceTransferred(oldGovernor, newGovernor);
    }

    function changeTaxRate(uint256 _taxRate) public onlyGovernance {
        require(_taxRate < 100);
        taxRate = _taxRate;
    }

    function mintProperty(
        uint256 _propertyId,
        uint256 _valuation,
        address _owner,
        string calldata info
    ) external onlyGovernance {
        Property storage property = properties[_propertyId];
        require(property.owner == address(0x0), "property already minted");

        Citizen storage citizen = citizens[_owner];

        if (citizen.numberOfProperties == 0) citizen.startTimestamp = block.timestamp;
        else updatePendingTaxes(_owner);

        citizen.properties[_propertyId] = true;
        citizen.numberOfProperties += 1;
        citizen.totalPropertyWorth += _valuation;

        property.owner = _owner;
        property.valuation = _valuation;

        emit PropertyMinted(_propertyId, info);
        emit PropertyTransferred(_propertyId, _owner, _valuation);
    }

    function burnProperty(uint256 _propertyId) external onlyGovernance {
        address owner = ownerOf(_propertyId);

        updatePendingTaxes(owner);

        Citizen storage citizen = citizens[owner];
        citizen.properties[_propertyId] = false;
        citizen.numberOfProperties -= 1;
        citizen.totalPropertyWorth -= properties[_propertyId].valuation;

        delete properties[_propertyId];

        emit PropertyBurned(_propertyId);
    }

    function mintTokens(uint256 _amount) public onlyGovernance {
        totalSupply += _amount;
        tokenReserve += _amount;
    }

    function changeWorthToContributionRatio(uint256 _worthToContributionRatio) public onlyGovernance {
        worthToContributionRatio = _worthToContributionRatio;
    }

    function changeVotingDuration(uint256 _votingDuration) public onlyGovernance {
        votingDuration = _votingDuration;
    }

    function changeExecutionDuration(uint256 _executionDuration) public onlyGovernance {
        executionDuration = _executionDuration;
    }

    // ===-===-=== STATE CHANGES ===-===-===

    function buyProperty(uint256 _propertyId, uint256 _newValuation) external {
        address prevOwner = ownerOf(_propertyId);
        require(prevOwner != msg.sender, "can't buy own property");

        Citizen storage citizen = citizens[msg.sender];

        if (citizen.numberOfProperties == 0) citizen.startTimestamp = block.timestamp;
        else require(payTaxes(msg.sender), "must have no pending taxes");

        updatePendingTaxes(prevOwner);

        Property storage property = properties[_propertyId];

        _tokenToEthSwap(property.valuation, prevOwner);

        citizens[prevOwner].properties[_propertyId] = false;
        citizens[prevOwner].totalPropertyWorth -= property.valuation;
        citizens[prevOwner].numberOfProperties -= 1;

        citizen.properties[_propertyId] = true;
        citizen.totalPropertyWorth += _newValuation;
        citizen.numberOfProperties += 1;

        property.owner = msg.sender;
        property.valuation = _newValuation;

        emit PropertyTransferred(_propertyId, msg.sender, _newValuation);
    }

    function updateValuation(uint256 _propertyId, uint256 _valuation) external onlyPropertyOwner(_propertyId) {
        require(payTaxes(msg.sender), "must have no pending taxes");
        Citizen storage citizen = citizens[msg.sender];
        Property storage property = properties[_propertyId];

        citizen.totalPropertyWorth += _valuation - property.valuation;

        property.valuation = _valuation;
    }

    function payTaxes(address _citizen) public returns (bool fullyPaid) {
        uint256 taxesDue = updatePendingTaxes(_citizen);
        if (taxesDue == 0) return true;
        Citizen storage citizen = citizens[_citizen];

        uint256 toBePaid;
        if (citizen.balance >= taxesDue) {
            toBePaid = taxesDue;
            fullyPaid = true;
        } else toBePaid = citizen.balance;

        citizen.balance -= toBePaid;
        citizen.lifetimeTaxesPaid += toBePaid;
        tokenReserve += toBePaid;
    }

    function updatePendingTaxes(address _citizen) public returns (uint256 newPendingTaxes) {
        newPendingTaxes = currentPendingTaxes(_citizen);
        Citizen storage citizen = citizens[_citizen];
        citizen.pendingTax += newPendingTaxes;
        citizen.periodsOnLastUpdate = _periodsSinceCitizenshipStarted(_citizen);
    }

    function createProposal(
        address _target,
        uint256 _value,
        bytes calldata _data,
        string calldata description
    ) external onlyCitizen(msg.sender) {
        Proposal storage proposal = proposals[++proposalsCount];

        proposal.creator = msg.sender;
        proposal.creationTime = block.timestamp;

        proposal.data = _data;
        proposal.target = _target;
        proposal.value = _value;

        uint256 votingClosingTime = block.timestamp + votingDuration;
        proposal.votingClosingTime = votingClosingTime;

        emit ProposalCreated(msg.sender, proposalsCount, votingClosingTime, description);
    }

    function castVote(uint256 _proposalId, Vote _vote) external validProposal(_proposalId) onlyCitizen(msg.sender) {
        require(_vote != Vote.NONE, "vote cannot be none");
        require(payTaxes(msg.sender), "must have no pending taxes");

        Citizen storage citizen = citizens[msg.sender];
        require(
            citizen.totalPropertyWorth / citizen.lifetimeTaxesPaid < worthToContributionRatio,
            "citizen must have paid enough tax to vote"
        );

        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp <= proposal.votingClosingTime, "voting time passed");
        require(proposal.votes[msg.sender] == Vote.NONE, "user already voted on this proposal");

        proposal.votes[msg.sender] = _vote;
        proposal.voters.push(msg.sender);

        emit VoteCasted(msg.sender, _proposalId, _vote);
    }

    function countVotes(uint256 _proposalId, uint256 _iterations) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.votingClosingTime, "voting time has not passed");

        uint256 endIndex = proposal.lastProcessedVoteIdx + _iterations;
        uint256 numberOfVotes = proposal.voters.length;
        if (endIndex > numberOfVotes) endIndex = numberOfVotes;

        (uint256 acceptVotes, uint256 rejectVotes) = (0, 0);
        for (uint256 i = 0; i < endIndex; i++) {
            address voter = proposal.voters[i];
            Vote vote = proposal.votes[voter];

            uint256 weight = sqrt(citizens[voter].totalPropertyWorth);

            if (vote == Vote.ACCEPTED) acceptVotes += weight;
            else rejectVotes += weight;
        }

        proposal.acceptVotes += acceptVotes;
        proposal.rejectVotes += rejectVotes;
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.votingClosingTime, "voting time has not passed");
        require(proposal.lastProcessedVoteIdx >= proposal.voters.length, "not all votes counted");
        require(proposal.creationTime < block.timestamp + executionDuration, "proposal has expired");
        require(!proposal.resolved, "proposal already resolved");

        proposal.resolved = true;

        if (proposal.acceptVotes <= proposal.rejectVotes) return;

        (bool success, ) = proposal.target.call{ value: proposal.value }(proposal.data);
        require(success);
    }

    function ethToToken() internal returns (uint256 tokensBought) {
        tokensBought = _getAmount(msg.value, _ethReserve() - msg.value, tokenReserve);

        citizens[msg.sender].balance += tokensBought;
        tokenReserve -= tokensBought;
    }

    function _tokenToEthSwap(uint256 _tokensSold, address _receiver) internal returns (uint256 ethBought) {
        ethBought = _getAmount(_tokensSold, tokenReserve, _ethReserve());

        payable(_receiver).transfer(ethBought);
        citizens[msg.sender].balance -= _tokensSold;
        tokenReserve += _tokensSold;
    }

    // ===-===-=== VIEWS ===-===-===

    function isPublicProperty(uint256 _propertyId) public view returns (bool) {
        return properties[_propertyId].owner == msg.sender;
    }

    function currentPendingTaxes(address _citizen) public view returns (uint256) {
        Citizen storage citizen = citizens[_citizen];
        return
            citizen.totalPropertyWorth *
            (_periodsSinceCitizenshipStarted(_citizen) - citizen.periodsOnLastUpdate) *
            (taxRate / 100);
    }

    function _periodsSinceCitizenshipStarted(address _citizen) internal view onlyCitizen(_citizen) returns (uint256) {
        return (block.timestamp - citizens[_citizen].startTimestamp) / TAX_COLLECTION_TIMEFRAME;
    }

    function balanceOf(address _citizen) public view override returns (uint256) {
        uint256 pendingTaxes = currentPendingTaxes(_citizen);
        return pendingTaxes < citizens[_citizen].balance ? citizens[_citizen].balance - pendingTaxes : 0;
    }

    function ownerOf(uint256 propertyId) public view returns (address owner) {
        owner = properties[propertyId].owner;
        require(owner != address(0), "invalid property ID");
    }

    function _getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) internal pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        // (inputAmount * outputReserve) / (inputReserve + inputAmount);
        return numerator / denominator;
    }

    function getTokenAmount(uint256 _eth) external view returns (uint256) {
        require(_eth > 0, "eth cannot be zero");
        return _getAmount(_eth, _ethReserve(), tokenReserve);
    }

    function getEthAmount(uint256 _tokens) external view returns (uint256) {
        require(_tokens > 0, "token cannot be zero");
        return _getAmount(_tokens, tokenReserve, _ethReserve());
    }

    function _ethReserve() internal view returns (uint256) {
        return address(this).balance;
    }
}