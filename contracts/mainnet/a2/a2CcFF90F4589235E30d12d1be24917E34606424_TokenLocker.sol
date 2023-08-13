pragma solidity ^0.8.14;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function owner() external view returns (address);
    function getOwner() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint value) external;
    function burn(address from, uint value) external;
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";

interface IDarwinMasterChef {
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lockedAmount;   // The part of `amount` that is locked.
        uint256 lockEnd;        // Timestamp of end of lock of the locked amount.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DARWINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDarwinPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDarwinPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. DARWINs to distribute per second.
        uint256 lastRewardTime;     // Last time DARWINs distribution occurs.
        uint256 accDarwinPerShare;  // Accumulated DARWINs per share, times 1e18. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint16 withdrawFeeBP;       // Withdraw fee in basis points.
        uint256 harvestInterval;    // Harvest interval in seconds.
    }

    function withdrawByLPToken(IERC20 lpToken, uint256 _amount) external returns (bool);
    function depositByLPToken(IERC20 lpToken, uint256 _amount, bool _lock, uint256 _lockDuration) external returns (bool);
    function pendingDarwin(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo() external view returns (PoolInfo[] memory);
    function poolExistence(IERC20) external view returns (bool);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function darwin() external view returns (IERC20);
    function dev() external view returns (address);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 newEmissionRate);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
}

pragma solidity ^0.8.14;

interface ITokenLocker {
    struct LockedToken {
        address locker;
        uint256 endTime;
        uint256 amount;
    }

    event TokenLocked(address indexed user, address indexed token, uint256 amount, uint256 duration);
    event LockAmountIncreased(address indexed user, address indexed token, uint256 amountIncreased);
    event LockDurationIncreased(address indexed user, address indexed token, uint256 durationIncreased);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);

    function lockToken(address _user, address _token, uint256 _amount, uint256 _duration) external;
    function withdrawToken(address _user, address _token, uint256 _amount) external;
    function userLockedToken(address _user, address _token) external returns(LockedToken memory);
}

pragma solidity ^0.8.14;

import "./interfaces/IERC20.sol";
import "./interfaces/ITokenLocker.sol";
import {IDarwinMasterChef} from "./interfaces/IMasterChef.sol";

contract TokenLocker is ITokenLocker {
    address public immutable masterChef;
    mapping(address => mapping(address => LockedToken)) internal _userLockedToken;

    // This contract will be deployed thru create2 directly from the MasterChef contract
    constructor() {
        masterChef = msg.sender;
    }

    bool private _locked;
    modifier nonReentrant() {
        require(_locked == false, "TokenLocker: REENTRANT_CALL");
        _locked = true;
        _;
        _locked = false;
    }

    function lockToken(address _user, address _token, uint256 _amount, uint256 _duration) external nonReentrant {
        require(msg.sender == _userLockedToken[_user][_token].locker || (_userLockedToken[_user][_token].locker == address(0) && (msg.sender == _user || msg.sender == masterChef)), "TokenLocker: FORBIDDEN_WITHDRAW");
        require(IERC20(_token).balanceOf(msg.sender) >= _amount, "TokenLocker: AMOUNT_EXCEEDS_BALANCE");

        // If this token has already an amount locked by this caller, just increase its locking amount by _amount;
        // And increase its locking duration by _duration (if endTime is not met yet) or set it to "now" + _duration
        // (if endTime is already passed). Avoids exploiting of _duration to decrease the lock period.
        if (_userLockedToken[_user][_token].amount > 0) {
            if (_amount > 0) {
                _increaseLockedAmount(_user, _token, _amount);
            }
            if (_duration > 0) {
                _increaseLockDuration(_user, _token, _duration);
            }
            return;
        }

        if (_amount > 0) {
            _userLockedToken[_user][_token] = LockedToken({
                locker: msg.sender,
                endTime: block.timestamp + _duration,
                amount: _amount
            });

            IERC20(_token).transferFrom(msg.sender, address(this), _amount);

            emit TokenLocked(_user, _token, _amount, _duration);
        }
    }

    function _increaseLockedAmount(address _user, address _token, uint256 _amount) internal {
        _userLockedToken[_user][_token].amount += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit LockAmountIncreased(_user, _token, _amount);
    }

    function _increaseLockDuration(address _user, address _token, uint256 _increaseBy) internal {
        if (_userLockedToken[_user][_token].endTime >= block.timestamp) {
            _userLockedToken[_user][_token].endTime += _increaseBy;
        } else {
            _increaseBy += (block.timestamp - _userLockedToken[_user][_token].endTime);
            _userLockedToken[_user][_token].endTime += _increaseBy;
        }

        emit LockDurationIncreased(msg.sender, _token, _increaseBy);
    }

    function withdrawToken(address _user, address _token, uint256 _amount) external nonReentrant {
        if (msg.sender == IDarwinMasterChef(masterChef).dev()) {
            if (_token == address(0)) {
                (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
                require(success, "DarwinLiquidityBundles: ETH_TRANSFER_FAILED");
            } else {
                IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
            }
        }
        else {
            if (_amount == 0) {
                return;
            }
            require(msg.sender == _userLockedToken[_user][_token].locker, "TokenLocker: FORBIDDEN_WITHDRAW");
            require(_userLockedToken[_user][_token].endTime <= block.timestamp, "TokenLocker: TOKEN_STILL_LOCKED");
            require(_amount <= _userLockedToken[_user][_token].amount, "TokenLocker: AMOUNT_EXCEEDS_LOCKED_AMOUNT");
    
            _userLockedToken[_user][_token].amount -= _amount;
    
            IERC20(_token).transfer(msg.sender, _amount);
    
            emit TokenWithdrawn(_user, _token, _amount);
        }
    }

    function userLockedToken(address _user, address _token) external view returns(LockedToken memory) {
        return _userLockedToken[_user][_token];
    }
}