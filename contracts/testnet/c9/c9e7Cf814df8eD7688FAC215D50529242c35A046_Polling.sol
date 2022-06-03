/**
 *Submitted for verification at Arbiscan on 2022-06-02
*/

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
        bytes signature,
        string comments
    );
}

contract Polling is PollingEvents {
    uint256 public npoll = 1000;

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

    function vote(uint256[] calldata pollIds, uint256[] calldata optionIds, bytes calldata signature, string calldata comments)
        external
    {
        require(pollIds.length == optionIds.length, "non-matching-length");
        emit Votes(msg.sender, pollIds, optionIds, signature, comments);
    }
}