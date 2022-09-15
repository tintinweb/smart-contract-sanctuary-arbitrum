/**
 *Submitted for verification at Arbiscan on 2022-09-15
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

    event Voted(
        address indexed voter,
        uint256 indexed pollId,
        uint256 indexed optionId
    );
}

contract Polling is PollingEvents {

    string public constant name = "MakerDAO Polling";
    string public constant version = "Arbitrum.1";
    uint256 public constant chainId = 1; //votes are counted towards mainnet polls

    uint256 public npoll = 1500;
    mapping (address => uint) public nonces;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant VOTE_TYPEHASH = keccak256("Vote(address voter,uint256 nonce,uint256 expiry,uint256[] pollIds,uint256[] optionIds)");
    bytes32 public constant VOTE_TYPEHASH = 0x017323f802fc67a11561f00703f58a9ee72807fab7bac8f581da97c5d13d0e96;

    constructor() public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        ));
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

    function vote(uint256[] calldata pollIds, uint256[] calldata optionIds)
        external
    {
        require(pollIds.length == optionIds.length, "non-matching-length");
        for (uint i = 0; i < pollIds.length; i++) {
            emit Voted(msg.sender, pollIds[i], optionIds[i]);
        }
    }

    function vote(address voter, uint256 nonce, uint256 expiry, uint256[] calldata pollIds, uint256[] calldata optionIds, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(pollIds.length == optionIds.length, "non-matching-length");
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(VOTE_TYPEHASH,
                                     voter,
                                     nonce,
                                     expiry,
                                     keccak256(abi.encodePacked(pollIds)),
                                     keccak256(abi.encodePacked(optionIds))))
        ));
        require(voter != address(0), "Polling/invalid-address");
        require(expiry == 0 || now <= expiry, "Polling/signature-expired");
        require(nonce == nonces[voter]++, "Polling/invalid-nonce");
        require(voter == ecrecover(digest, v, r, s), "Polling/invalid-signature");

        for (uint i = 0; i < pollIds.length; i++) {
            emit Voted(voter, pollIds[i], optionIds[i]);
        }
    }
}