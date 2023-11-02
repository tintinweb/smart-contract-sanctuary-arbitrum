/**
 *Submitted for verification at Arbiscan.io on 2023-11-02
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/dao.sol

//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;


contract DPODAO {
    address public admin;
    IERC20 AcessToken;
    IERC20 GovernanceToken;

    uint256 public pollDurationInDays = 7 days;
    uint256 public pollCount;
  

    struct Poll {
        uint256 pollId;
        string pollTopic;
        uint256 pollCreattionTimestamp;
        string Outcome;
        bool ended;
        bool active;
        uint256 yesVotes;
        uint256 noVotes;
    }

    Poll[] public allPolls;

    mapping(uint256 => Poll) public PollPerId;

    mapping(uint256 => mapping(address => bool)) internal ifAddressHasCastVote;
    

    constructor(address _AccessToken, address _GovernanceToken) {
        admin = msg.sender;
        AcessToken = IERC20(_AccessToken);
        GovernanceToken = IERC20(_GovernanceToken);
    }

    modifier canPoll() {
        require(msg.sender == admin, "Only admin can create a poll");
        _;
    }


    function changeAdmin(address _admin) external {
        require(msg.sender == admin, "only current admin can change admin");
        admin =_admin;
    }

    function createPoll(string memory _topic) external canPoll returns (uint256) {
        Poll storage poll = PollPerId[pollCount];
        poll.pollId = pollCount;
        poll.pollTopic = _topic;
        poll.pollCreattionTimestamp = block.timestamp;
        poll.Outcome = "Undecided";
        poll.ended = false;
        poll.active=true;
        pollCount += 1;
        allPolls.push(poll);
        return poll.pollId;
    }

    function Vote(uint256 _pollId, bool _vote) external  {
             require(
            AcessToken.balanceOf(msg.sender) > 0,
            "must have access token to participate"
        );
        require(
            block.timestamp <
                PollPerId[_pollId].pollCreattionTimestamp + pollDurationInDays,
            "Voting time is up"
        );
        require(PollPerId[_pollId].ended == false, "Poll id concluded");
        require(
            ifAddressHasCastVote[_pollId][msg.sender] == false,
            "Has already voted on this poll"
        );
        require(
            GovernanceToken.balanceOf(msg.sender) >= 1 ether,
            "insufficient amount of governance token requires atleast 1 DPO token"
        );
        if (_vote) {
            PollPerId[_pollId].yesVotes += 1;
        } else {
            PollPerId[_pollId].noVotes += 1;
        }
        ifAddressHasCastVote[_pollId][msg.sender] = true;
    }

    function unfreezeToken(uint256 _pollId) external{
        require(ifAddressHasCastVote[_pollId][msg.sender],"This address did not vote");
        require(PollPerId[_pollId].ended,"The poll is not yet concluded");
        GovernanceToken.transfer(msg.sender,1 ether);
        ifAddressHasCastVote[_pollId][msg.sender] = false;
    }


    function concludePoll(uint256 _pollId) external canPoll {
        require(
            block.timestamp >
                PollPerId[_pollId].pollCreattionTimestamp + pollDurationInDays,
            "voting time is not yet up"
        );
        
        uint256 yes = PollPerId[_pollId].yesVotes;
        uint256 no = PollPerId[_pollId].noVotes;
        if (yes == 0 && no == 0) {
            PollPerId[_pollId].Outcome = "Undecided";
            return;
        }
        if (yes > no) {
            PollPerId[_pollId].Outcome = "Yes";
        } else if (no > yes) {
            PollPerId[_pollId].Outcome = "No";
        } else {
            PollPerId[_pollId].Outcome ="Tie";
        }
        PollPerId[_pollId].active = false;
        PollPerId[_pollId].ended = true;
        allPolls.push(PollPerId[_pollId]);
    }
}