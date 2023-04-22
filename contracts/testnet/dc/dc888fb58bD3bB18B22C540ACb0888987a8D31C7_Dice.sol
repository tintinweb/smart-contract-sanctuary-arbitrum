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

contract Dice is Basic {
    //Currency: 0:TRX
    //Type: 0:Under 1:Over
    //Modulo: Number compare
    //Value: Bet value
    //Save
    //Data: %10 => type ;%1000/10 => number; %10**13/1000 => blocknumber ;/10**23 => value; %10**23/10**13 => blocktime
    event Bet(address user, uint256 data);
    event BetSettle(address user, uint256 payout);
    mapping(bytes32 => bool) public isSent;
    uint256 minBet = 1e7;
    uint256 maxBet = 1e9;
    ERC20 public token;
    Member public member;

    constructor(address _token, address _member) {
        token = ERC20(_token);
        member = Member(_member);
    }

    function setMax(uint256 _min, uint256 _max) public onlyOwner {
        minBet = _min;
        maxBet = _max;
    }

    function changeMemberContract(address _newMember) public onlyOwner {
        member = Member(_newMember);
    }

    function makeBet(
        uint8 _direction,
        uint8 _modulo,
        uint256 _value,
        address _ref
    ) public notPause {
        require(
            (_direction == 0 && _modulo > 0 && _modulo < 97) ||
                (_direction == 1 && _modulo > 4 && _modulo < 99),
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
            uint256(_modulo) *
            10 +
            uint256(_direction);
        emit Bet(msg.sender, dataBet);
    }

    function settle(
        address _user,
        uint256 _payout,
        bytes32 _txid
    ) public onlyMod returns (uint256 payout) {
        require(!isSent[_txid], "Must be not sent");
        isSent[_txid] = true;
        token.transfer(_user, _payout);
        emit BetSettle(_user, _payout);
        return _payout;
    }

    function funds(uint256 a) public onlyOwner {
        token.transfer(owner, a);
    }
}