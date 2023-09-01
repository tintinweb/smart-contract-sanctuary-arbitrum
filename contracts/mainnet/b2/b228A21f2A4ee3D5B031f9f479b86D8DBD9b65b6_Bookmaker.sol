/**
 *Submitted for verification at Arbiscan.io on 2023-08-28
*/

// SPDX-License-Identifier: MIT
//
//      Welcome To Matched Betz
// Where Skill Enters The Betting Arena
//
// https://www.mbetz.io/
// https://twitter.com/matchedbetz
// https://t.me/matchedbetz
//
//
// @Author:  Bum
// @Version: 4.3


pragma solidity 0.8.19;

contract Oracular {
    address payable oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle can run this method");
        _;
    }

    constructor(address _oracle) {
        oracle = payable(_oracle);
    }
}
struct Player {
    address payable addr;
    uint balance;
    bool position; // 0 - Under, 1 - Over
}

enum BetStatus {
    Initialized,
    Accepted,
    Reverted,
    Canceled,
    RewardAssigned
}

struct Bet {
    uint betId;
    uint betValue;
    uint contestantTimestamp;
    uint16 assetId;
    uint assetPrice;
    BetStatus status;
    Player creator;
    Player contestant;
    address winner;
    uint winnerReward;
}


struct PlayerBet {
    uint16 assetId;
    uint betId;
}

contract Bookmaker is Oracular {
    uint256 constant maxQueryLimit = 20;

    mapping(uint16 => Bet[]) assetBets;
    mapping(address => PlayerBet[]) playerBets;

    uint public minBetValue = 0.05 ether;
    uint public maxBetFee = 1;
    uint public cutOffTime = 3 hours;
    uint public resultTimeOut = 1 hours;

    event BetInitialization(uint16 assetId, uint betId, address indexed creator);
    event BetAcceptance(uint16 assetId, uint betId, address indexed creator, address indexed contestant, uint contestantTimestamp);
    event BetReversion(uint16 assetId, uint betId, address indexed creator, address indexed contestant);
    event BetCancellation(uint16 assetId, uint betId, address indexed creator);
    event RewardAssignment(uint16 assetId, uint betId,  address indexed winner, uint reward);

    constructor(address _oracle) Oracular(_oracle) {}

    function initializeBet(uint16 _asset, uint _betValue, uint _contestantTimestamp, uint _assetPrice, bool _position) public payable {
        require(_betValue == msg.value, "transaction value must be equal to entry");
        require(_betValue >= minBetValue, "entry must be greater or equal than min entry value");
        require(block.timestamp + cutOffTime < _contestantTimestamp, "cannot create a bet, that ends sooner than 4 hours from now");

        // betId starts from 1
        Bet[] storage bets = assetBets[_asset];
        uint betId = bets.length + 1;
        bets.push(Bet({
            betId: betId,
            betValue: _betValue,
            contestantTimestamp: _contestantTimestamp,
            assetId: _asset,
            assetPrice: _assetPrice,
            status: BetStatus.Initialized,
            creator: Player({
                addr: payable(msg.sender),
                balance: msg.value,
                position: _position
            }),
            contestant: Player({
                addr: payable(address(0x0)),
                balance: 0,
                position: !_position
            }),
            winner: address(0x0),
            winnerReward: 0
        }));

        playerBets[msg.sender].push(PlayerBet({assetId: _asset, betId: betId}));

        emit BetInitialization(_asset, betId, msg.sender);
    }

    function acceptBet(uint16 _asset, uint _betId) public payable {
        Bet storage bet = assetBets[_asset][_betId - 1];

        require(bet.creator.addr != msg.sender, "you cannot join to bet with yourself");
        require(bet.status == BetStatus.Initialized, "the bet has been already accepted");
        require(block.timestamp < bet.contestantTimestamp - cutOffTime, "bet comes to the end, you cannot accept");


        require(bet.creator.balance == msg.value, "value sent in transaction must be the same as entry");

        bet.contestant.addr = payable(msg.sender);
        bet.contestant.balance = msg.value;
        bet.status = BetStatus.Accepted;

        playerBets[msg.sender].push(PlayerBet({assetId: _asset, betId: _betId}));

        emit BetAcceptance(_asset, bet.betId, bet.creator.addr, bet.contestant.addr, bet.contestantTimestamp);
    }

    function cancelBet(uint16 _asset, uint _betId) public {
        Bet storage bet = assetBets[_asset][_betId - 1];

        require(bet.creator.addr == msg.sender, "you are not the creator of the bet");
        require(bet.status == BetStatus.Initialized, "only initialized bet can be canceled");
        require(block.timestamp > bet.contestantTimestamp - cutOffTime, "cut off time has not been reached");
        require(bet.creator.balance > 0, "You have already paid out your money");

        uint balance = bet.creator.balance;
        bet.creator.balance = 0;
        bet.status = BetStatus.Canceled;

        payable(msg.sender).transfer(balance);
        emit BetCancellation(_asset, bet.betId, bet.creator.addr);
    }

    function revertBet(uint16 _asset, uint _betId) public {
        Bet storage bet = assetBets[_asset][_betId - 1];
        require(block.timestamp > bet.contestantTimestamp + resultTimeOut, "it's too early to revert the bet");
        require(bet.status == BetStatus.Accepted || bet.status == BetStatus.Reverted, "you can only revert accepted or already reverted bet");
        require(bet.creator.addr == msg.sender || bet.contestant.addr == msg.sender, "you are not listed in bet");

        if (msg.sender == bet.creator.addr) {
            require(bet.creator.balance > 0, "You have already paid out your money");
        } else {
            require(bet.contestant.balance > 0, "You have already paid out your money");
        }

        uint balance;
        if (msg.sender == bet.creator.addr) {
            balance = bet.creator.balance;
            bet.creator.balance = 0;
        } else {
            balance = bet.contestant.balance;
            bet.contestant.balance = 0;
        }

        bet.status = BetStatus.Reverted;
        payable(msg.sender).transfer(balance);

        emit BetReversion(_asset, bet.betId, bet.creator.addr, bet.contestant.addr);
    }

    function getBets(uint16 _asset, uint _limit, uint _offset) public view returns (Bet[] memory results){
        require(_offset <= assetBets[_asset].length, "offset out of bounds");

        uint256 size = assetBets[_asset].length - _offset;
        size = size < _limit ? size : _limit;
        size = size < maxQueryLimit ? size : maxQueryLimit;
        results = new Bet[](size);

        for (uint256 i = 0; i < size; i++) {
            results[i] = assetBets[_asset][_offset + i];
        }

        return results;
    }

    function getStatusBets(uint16 _asset, uint _limit, uint _offset, BetStatus _status) public view returns (Bet[] memory results){
        // TODO: simplify this function
        uint256 length = 0;
        for (uint256 i = 0; i < assetBets[_asset].length; i++) {
            if (assetBets[_asset][i].status == _status) {
                length ++;
            }
        }

        if (_offset > length) {
            results = new Bet[](0);
            return results;
        }

        uint256 size = length - _offset;
        size = size < _limit ? size : _limit;
        size = size < maxQueryLimit ? size : maxQueryLimit;
        results = new Bet[](size);

        uint256 added = 0;
        for (uint256 i = 0; i < assetBets[_asset].length; i++) {
            if (assetBets[_asset][i].status == _status) {
                if (_offset != 0) {
                    _offset--;
                } else {
                    results[added] = assetBets[_asset][i];
                    added++;
                    if (added >= size) {
                        break;
                    }
                }
            }
        }

        return results;
    }

    function getPlayerBets(address playerAddress) public view returns (Bet[] memory results){
        // TODO Add _limit & _offset
        results = new Bet[](playerBets[playerAddress].length);

        for (uint i = 0; i < playerBets[playerAddress].length; i++) {
            PlayerBet memory playerBet = playerBets[playerAddress][i];
            results[i] = assetBets[playerBet.assetId][playerBet.betId - 1];
        }

        return results;
    }

    function getBet(uint16 _asset, uint _betId) public view returns (Bet memory bet) {
        bet = assetBets[_asset][_betId - 1];
        return bet;
    }

    function assignReward(uint16 _asset, uint32 _betId, address _winner, uint _oracleFee) public onlyOracle {
        canAssignReward(_asset, _betId, _winner, _oracleFee);

        Bet storage bet = assetBets[_asset][_betId - 1];

        uint balanceA = bet.creator.balance;
        uint balanceB = bet.contestant.balance;

        bet.creator.balance = 0;
        bet.contestant.balance = 0;
        bet.status = BetStatus.RewardAssigned;
        bet.winner = _winner;
        bet.winnerReward = balanceA + balanceB;


        if (_winner == bet.creator.addr) {
            oracle.transfer(_oracleFee);
            bet.creator.addr.transfer(balanceA + balanceB - _oracleFee);
        } else {
            oracle.transfer(_oracleFee);
            bet.contestant.addr.transfer(balanceA + balanceB - _oracleFee);
        }
        emit RewardAssignment(_asset, bet.betId, _winner, balanceA + balanceB);
    }

    function canAssignReward(uint16 _asset, uint32 _betId, address _winner, uint _oracleFee) public onlyOracle view {
        Bet memory bet = assetBets[_asset][_betId - 1];

        require(block.timestamp > bet.contestantTimestamp && block.timestamp < bet.contestantTimestamp + resultTimeOut, "It's not a time to set reward");
        require(bet.status == BetStatus.Accepted, "We can assign reward only to accepted bets");
        require(bet.creator.addr == _winner || bet.contestant.addr == _winner, "Winner is not valid");
        require(bet.creator.balance > 0 && bet.contestant.balance > 0, "Reward has been already assigned");

        require(_oracleFee < (bet.creator.balance + bet.contestant.balance) * maxBetFee / 100, "Oracle fee exceeds 1% of final reward - cannot by execute");
    }

    function setMinBetValue(uint _newMinBetValue) public onlyOracle {
        minBetValue = _newMinBetValue;
    }

    function setMaxBetFee(uint _newMaxBetFee) public onlyOracle {
        require(_newMaxBetFee >= 0, "New fee threshold must be gte than 0");
        // It must be
        require(_newMaxBetFee <= 5, "New fee threshold must be lte than 5");
        maxBetFee = _newMaxBetFee;
    }

    function setCutOffTime(uint _newCutOffTime) public onlyOracle {
        cutOffTime = _newCutOffTime;
    }

    function setResultTimeOut(uint _newResultTimeOut) public onlyOracle {
        resultTimeOut = _newResultTimeOut;
    }
}