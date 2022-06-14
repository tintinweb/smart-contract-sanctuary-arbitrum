/**
 *Submitted for verification at Arbiscan on 2022-06-14
*/

pragma solidity ^0.6.6;

contract PollingEvents {
    event PollCreated(
        address indexed creator,
        uint256 blockCreated,
        uint256 indexed pollId,
        uint256 startDate,
        uint256 endDate,
        string multiHash,
        string url
    );

    event PollWithdrawn(
        address indexed creator,
        uint256 blockWithdrawn,
        uint256 pollId
    );

    event Votes(
        address voter,
        uint256[] pollId,
        uint256[] optionId,
        bytes signature
    );
}

contract Polling is PollingEvents {
    uint256 public npoll = 1000;

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function createPoll(uint256 startDate, uint256 endDate, string calldata multiHash, string calldata url)
        external
    {
        uint256 startDate_ = startDate > now ? startDate : now;
        require(endDate > startDate_, "polling-invalid-poll-window");
        emit PollCreated(
            msg.sender,
            block.number,
            npoll,
            startDate_,
            endDate,
            multiHash,
            url
        );
        require(npoll < uint(-1), "polling-too-many-polls");
        npoll++;
    }

    function withdrawPoll(uint256 pollId)
        external
    {
        emit PollWithdrawn(msg.sender, block.number, pollId);
    }

    function increasePollNumber(uint256 amount) external {
        require(amount <= 30);
        npoll = add(npoll, amount);
    }

    function vote(uint256[] calldata pollIds, uint256[] calldata optionIds, bytes calldata signature)
        external
    {
        require(pollIds.length == optionIds.length, "non-matching-length");
        emit Votes(msg.sender, pollIds, optionIds, signature);
    }
}