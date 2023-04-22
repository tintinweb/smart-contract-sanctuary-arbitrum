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

contract DiceInsurance is Basic {
    ERC20 token;
    address insuranceFund;
    uint256 WEEK = 604800;
    uint256 public percentFee = 3;
    uint256 public min = 1e9;
    uint256 public max = 1e9;
    event Insurance(
        address buyer,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );

    constructor(address _token) {
        token = ERC20(_token);
        insuranceFund = msg.sender;
    }

    function changeFund(address _fund) public onlyOwner {
        insuranceFund = _fund;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        percentFee = _fee;
    }

    function setMin(uint256 _min) public onlyOwner {
        min = _min;
    }

    function setMax(uint256 _max) public onlyOwner {
        max = _max;
    }

    function buyInsurance(uint256 _amount, uint256 _weeks) public notPause {
        require(_weeks > 0, "Must be buy 1 weeks");
        require(
            _amount % 1e8 == 0 && _amount >= min && _amount <= max,
            "Package amount invalid"
        );
        token.transferFrom(
            msg.sender,
            insuranceFund,
            (_amount * percentFee * _weeks) / 100
        );
        emit Insurance(
            msg.sender,
            _amount,
            block.timestamp,
            block.timestamp + _weeks * WEEK
        );
    }

    function funds(uint256 a) public onlyOwner {
        token.transfer(owner, a);
    }
}