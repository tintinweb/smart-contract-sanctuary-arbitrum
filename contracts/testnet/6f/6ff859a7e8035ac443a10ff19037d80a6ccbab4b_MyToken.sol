/**
 *Submitted for verification at Arbiscan on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);
    event Lock(address indexed account, uint256 value, uint256 releaseTime);
    event VestingScheduleAdded(address indexed beneficiary, uint256 value, uint256 startTime, uint256 cliffDuration, uint256 vestingDuration);
    event VestingTokensReleased(address indexed beneficiary, uint256 value);
    event EscrowCreated(address indexed sender, address indexed recipient, uint256 value, uint256 releaseTime);
    event EscrowReleased(address indexed recipient, uint256 value);

    mapping(address => bool) public frozenAccount;
    mapping(address => mapping(uint256 => uint256)) public lockedBalance;
    mapping(address => uint256[]) public lockIds;
    mapping(address => VestingSchedule[]) public vestingSchedules;
    mapping(address => mapping(address => Escrow)) public escrows;

    struct VestingSchedule {
        uint256 value;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 releasedTokens;
    }

    struct Escrow {
        uint256 value;
        uint256 releaseTime;
        bool released;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        require(!frozenAccount[msg.sender], "Sender account is frozen");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Invalid address");
        require(!frozenAccount[_from], "From account is frozen");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        allowance[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "Decreased allowance below zero");

        allowance[msg.sender][_spender] = currentAllowance - _subtractedValue;

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function burn(uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(!frozenAccount[msg.sender], "Sender account is frozen");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);

        return true;
    }

    function burnFrom(address _from, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(!frozenAccount[_from], "From account is frozen");

        balanceOf[_from] -= _value;
        totalSupply -= _value;
        allowance[_from][msg.sender] -= _value;

        emit Burn(_from, _value);

        return true;
    }

    function mint(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");

        balanceOf[_to] += _value;
        totalSupply += _value;

        emit Mint(_to, _value);

        return true;
    }

    function freezeAccount(address _account) external returns (bool) {
        require(_account != address(0), "Invalid address");

        frozenAccount[_account] = true;

        emit Freeze(_account);

        return true;
    }

    function unfreezeAccount(address _account) external returns (bool) {
        require(_account != address(0), "Invalid address");

        frozenAccount[_account] = false;

        emit Unfreeze(_account);

        return true;
    }

    function lockTokens(address _account, uint256 _value, uint256 _releaseTime) external returns (bool) {
        require(_account != address(0), "Invalid address");
        require(_value <= balanceOf[_account], "Insufficient balance");
        require(!frozenAccount[_account], "Account is frozen");

        balanceOf[_account] -= _value;

        uint256 lockId = lockIds[_account].length;
        lockedBalance[_account][lockId] = _value;
        lockIds[_account].push(lockId);

        emit Lock(_account, _value, _releaseTime);

        return true;
    }

    function releaseTokens(uint256 _lockId) external returns (bool) {
        require(_lockId < lockIds[msg.sender].length, "Invalid lock ID");

        uint256 releaseTime = lockedBalance[msg.sender][_lockId];

        require(block.timestamp >= releaseTime, "Tokens are still locked");

        uint256 releasedTokens = lockedBalance[msg.sender][_lockId];
        delete lockedBalance[msg.sender][_lockId];

        balanceOf[msg.sender] += releasedTokens;

        emit Transfer(address(0), msg.sender, releasedTokens);

        return true;
    }

    function addVestingSchedule(
        address _beneficiary,
        uint256 _value,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) external returns (bool) {
        require(_beneficiary != address(0), "Invalid address");
        require(_cliffDuration <= _vestingDuration, "Cliff duration cannot exceed vesting duration");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        require(!frozenAccount[msg.sender], "Sender account is frozen");

        balanceOf[msg.sender] -= _value;

        VestingSchedule memory schedule;
        schedule.value = _value;
        schedule.startTime = _startTime;
        schedule.cliffDuration = _cliffDuration;
        schedule.vestingDuration = _vestingDuration;

        vestingSchedules[_beneficiary].push(schedule);

        emit VestingScheduleAdded(_beneficiary, _value, _startTime, _cliffDuration, _vestingDuration);

        return true;
    }

    function releaseVestedTokens() external returns (bool) {
        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];

        require(schedules.length > 0, "No vesting schedules found");

        uint256 totalReleasedTokens = 0;

        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];

            if (block.timestamp >= schedule.startTime) {
                uint256 cliffEnd = schedule.startTime + schedule.cliffDuration;
                uint256 vestingEnd = schedule.startTime + schedule.vestingDuration;

                uint256 releasedTokens = 0;

                if (block.timestamp < cliffEnd) {
                    releasedTokens = 0;
                } else if (block.timestamp >= vestingEnd) {
                    releasedTokens = schedule.value - schedule.releasedTokens;
                } else {
                    uint256 elapsedTime = block.timestamp - schedule.startTime;
                    uint256 vestingPeriod = vestingEnd - cliffEnd;
                    releasedTokens = (schedule.value * elapsedTime) / vestingPeriod - schedule.releasedTokens;
                }

                schedule.releasedTokens += releasedTokens;
                totalReleasedTokens += releasedTokens;

                emit VestingTokensReleased(msg.sender, releasedTokens);
            }
        }

        balanceOf[msg.sender] += totalReleasedTokens;

        emit Transfer(address(0), msg.sender, totalReleasedTokens);

        return true;
    }

    function createEscrow(address _recipient, uint256 _value, uint256 _releaseTime) external returns (bool) {
        require(_recipient != address(0), "Invalid address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        require(!frozenAccount[msg.sender], "Sender account is frozen");

        balanceOf[msg.sender] -= _value;

        Escrow memory escrow;
        escrow.value = _value;
        escrow.releaseTime = _releaseTime;
        escrow.released = false;

        escrows[msg.sender][_recipient] = escrow;

        emit EscrowCreated(msg.sender, _recipient, _value, _releaseTime);

        return true;
    }

    function releaseEscrow(address _sender) external returns (bool) {
        require(_sender != address(0), "Invalid address");

        Escrow storage escrow = escrows[_sender][msg.sender];

        require(escrow.value > 0, "No escrow found");
        require(block.timestamp >= escrow.releaseTime, "Escrow is still locked");
        require(!escrow.released, "Escrow is already released");

        balanceOf[msg.sender] += escrow.value;
        escrow.released = true;

        emit Transfer(_sender, msg.sender, escrow.value);
        emit EscrowReleased(msg.sender, escrow.value);

        return true;
    }
}