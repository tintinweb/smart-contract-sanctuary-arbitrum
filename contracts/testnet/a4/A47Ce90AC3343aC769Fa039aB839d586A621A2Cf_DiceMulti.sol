// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Basic {
    address public owner;
    mapping(address => bool) isMod;
    bool public isPause = false;
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }
    modifier onlyMod() {
        require(isMod[msg.sender] || msg.sender == owner, "Must be mod");
        _;
    }

    modifier notPause() {
        require(!isPause, "Must be not pause");
        _;
    }

    function addMod(address _mod) public onlyOwner {
        if (_mod != address(0x0)) {
            isMod[_mod] = true;
        }
    }

    function removeMod(address _mod) public onlyOwner {
        isMod[_mod] = false;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        if (_newOwner != address(0x0)) {
            owner = _newOwner;
        }
    }

    function changePause(uint256 _change) public onlyOwner {
        isPause = _change == 1;
    }

    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./BasicAuth.sol";

interface ERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external;

    function transfer(address _to, uint256 _value) external;
}

interface Member {
    function addMember(address _member, address _sponsor) external;

    function sponsor(address _member) external view returns (address);

    function getParent(address _child) external view returns (address);
}

contract DiceMulti is Basic {
    string public version = "1.2.2";

    //Currency: 0:TRX
    //Type: 0:Player 1:Tie 2:Banker
    //Value: Bet value
    //Save
    //Data: %10 => type ;%1000/10 => number; %10**13/1000 => blocknumber ;/10**23 => value; %10**23/10**13 => blocktime

    event Bet(uint256 roundId, address user, uint256 data);
    event BetSettle(bytes32 chunkId);
    event ChangeBettingBlocks(uint256 _blocks);
    event ChangeMaxBlocksInRound(uint256 _blocks);

    mapping(bytes32 => bool) public isSent;
    uint256 public minBet = 1e7;
    uint256 public maxBet = 1e9;

    ERC20 public token;
    Member public member;

    uint256 public initBlock = 0;
    uint256 public bettingBlocks = 8;
    uint256 public maxBlocksInRound = 10;

    constructor(address _token, address _member) {
        owner = msg.sender;
        token = ERC20(_token);
        member = Member(_member);
        initBlock = block.number;
    }

    function setMax(uint256 _min, uint256 _max) public onlyOwner {
        minBet = _min;
        maxBet = _max;
    }

    function changeMemberContract(address _newMember) public onlyOwner {
        member = Member(_newMember);
    }

    function changeBettingBlocks(uint256 _blocks) public onlyOwner {
        require(
            _blocks <= maxBlocksInRound,
            "must be less than maxBlocksInRound"
        );
        bettingBlocks = _blocks;
        emit ChangeBettingBlocks(_blocks);
    }

    function changeMaxBlocksInRound(uint256 _blocks) public onlyOwner {
        require(_blocks >= bettingBlocks, "must be greater than bettingBlocks");
        maxBlocksInRound = _blocks;
        emit ChangeMaxBlocksInRound(_blocks);
    }

    function getCurrentRound()
        public
        view
        returns (
            uint256 roundId,
            uint256 startBlock,
            uint256 drawingBlock,
            uint256 toBlock
        )
    {
        uint256 currentBlock = block.number;
        roundId = (currentBlock - initBlock) / maxBlocksInRound;
        startBlock = initBlock + maxBlocksInRound * (roundId);
        drawingBlock = startBlock + bettingBlocks;
        toBlock = startBlock + maxBlocksInRound;
    }

    function makeBet(
        uint256 _roundId,
        uint8 _direction,
        uint256 _value,
        address _ref
    ) public notPause {
        (
            uint256 roundId,
            uint256 startBlock,
            uint256 drawingBlock,
            uint256 toBlock
        ) = getCurrentRound();

        uint256 currentBlock = block.number;

        require(roundId == _roundId, "roundId not match");

        require(
            startBlock <= currentBlock &&
                currentBlock <= drawingBlock &&
                currentBlock <= toBlock,
            "round must be active"
        );

        require(
            (_direction == 0) || (_direction == 1) || (_direction == 2),
            "Wrong bet!"
        );
        require(_value >= minBet && _value <= maxBet, "Limit bet");
        if (member.sponsor(msg.sender) == address(0x0)) {
            member.addMember(msg.sender, _ref);
        }
        token.transferFrom(msg.sender, address(this), _value);
        uint256 dataBet = _value *
            1e23 +
            block.number *
            1e3 +
            uint256(_direction);
        emit Bet(_roundId, msg.sender, dataBet);
    }

    // deprecated
    /* function settle(
        address _user,
        uint256 _payout,
        bytes32 _txid
    ) public onlyMod returns (uint256 payout) {
        require(!isSent[_txid], "Must be not sent");
        isSent[_txid] = true;
        token.transfer(_user, _payout);
        emit BetSettle(_user, _payout);
        return _payout;
    } */

    function multiSettle(
        address[] memory _users,
        uint256[] memory _payouts,
        bytes32 _chunkId
    ) public onlyMod returns (bool) {
        require(!isSent[_chunkId], "Must be not sent");

        uint256 usersLength = _users.length;
        uint256 payoutLength = _payouts.length;

        require(
            usersLength == payoutLength,
            "array length of users and payouts not match"
        );

        for (uint256 i = 0; i < usersLength; i++) {
            token.transfer(_users[i], _payouts[i]);
        }

        isSent[_chunkId] = true;

        emit BetSettle(_chunkId);

        return true;
    }

    function funds(uint256 a) public onlyOwner {
        token.transfer(owner, a);
    }
}