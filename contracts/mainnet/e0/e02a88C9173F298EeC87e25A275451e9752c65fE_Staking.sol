// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

interface StakeInfo {
    struct UserInfo {
        uint256 stakedOf;
        uint256 rewardOf;
        uint256 duration;
        uint256 lastDepositAt;
        uint256 lastRewardAt;
        uint256 userReward;
    }

    struct PoolInfo {
        uint256 totalStaked;
        address lpToken;
        uint256 duration;
        uint256 allocPoint;
        uint256 accPerShare;
    }
}

contract Staking is StakeInfo {
    address public immutable tokenAddress;
    address public owner;

    uint256 public perBlockReward = 1e15;
    uint256 public inviteRewardRatio = 30; // 30/ 1000
    uint256 public inviteRewardRatio2 = 20;

    bool public isStaking = true;
    bool public isBonus;
    uint256 public totalAllocPoint;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) private _userInfo;
    mapping(address => address) public inviter;
    mapping(address => uint256) public inviterCount;
    mapping(address => uint256) public inviteRewardOf;
    mapping(uint256 => uint256) public totalBoostedShare;
    mapping(uint256 => mapping(address => uint256)) public userBoostedShare;

    uint256 public lastBonusBlock;

    event Staked(
        address indexed from,
        address indexed lpToken,
        uint256 _duration,
        uint256 amount
    );

    event Unstaked(
        address indexed to,
        address indexed lpToken,
        uint256 _duration,
        uint256 amount
    );

    event Reward(address indexed to, uint256 amount);

    event BindInviter(address indexed inviter, address indexed account);

    constructor(address _vtoken, address _reward) {
        require(_vtoken != _reward, "invalid token address");
        tokenAddress = _reward;
        owner = msg.sender;

        totalAllocPoint += 100;
        poolInfo.push(
            PoolInfo({
                totalStaked: 0,
                lpToken: _vtoken,
                duration: 0,
                allocPoint: 100,
                accPerShare: 0
            })
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function userInfo(
        uint256 pid,
        address _account
    ) public view returns (UserInfo memory _user) {
        return _userInfo[pid][_account];
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setPerBlockReward(uint256 amount) external onlyOwner {
        _bonusReward();
        perBlockReward = amount;
    }

    function setInviteRewardRatio(
        uint256 _ratio,
        uint256 _ratio2
    ) external onlyOwner {
        require(_ratio <= 1000 && _ratio2 <= 1000, "ratio error");
        inviteRewardRatio = _ratio;
        inviteRewardRatio2 = _ratio2;
    }

    function setStaking(bool _isStaking) external onlyOwner {
        isStaking = _isStaking;
    }

    function setIsBonus(bool value) external onlyOwner {
        isBonus = value;
        if (isBonus) {
            lastBonusBlock = block.number;
        }
    }

    function getPool(
        uint256 pid
    ) external view returns (PoolInfo memory _pool) {
        return poolInfo[pid];
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPendingBlock() public view returns (uint256) {
        if (isBonus && block.number > lastBonusBlock) {
            return block.number - lastBonusBlock;
        }
        return 0;
    }

    function getPendingReward() public view returns (uint256) {
        return getPendingBlock() * perBlockReward;
    }

    function bonusReward() external {
        require(isBonus, "Bonus is not enabled");
        require(totalAllocPoint > 0, "No pool");
        require(block.number > lastBonusBlock, "Error: lastBonusBlock");

        _bonusReward();
    }

    function _bonusReward() internal {
        if (isBonus) {
            _updatePool(0);
            lastBonusBlock = block.number;
        }
    }

    function _updatePool(uint256 pid) internal {
        if (poolInfo[pid].allocPoint > 0 && poolInfo[pid].totalStaked > 0) {
            uint256 _reward = (getPendingReward() * poolInfo[pid].allocPoint) /
                totalAllocPoint;

            poolInfo[pid].accPerShare +=
                (_reward * 1e12) /
                totalBoostedShare[pid];
        }
    }

    function bindInviter(address _inviter) external {
        require(inviter[msg.sender] == address(0), "Error: Repeat binding");
        require(_inviter != msg.sender, "Error: Binding self");
        require(
            _inviter != address(0),
            "Error: Binding inviter is zero address"
        );
        if (_inviter != owner) {
            require(
                inviter[_inviter] != address(0),
                "Error: The inviter wasn't ready"
            );
        }

        require(
            inviter[_inviter] != msg.sender,
            "Error: Binding inviter is self"
        );
        inviter[msg.sender] = _inviter;
        inviterCount[_inviter] += 1;
        emit BindInviter(_inviter, msg.sender);
    }

    // 100/100
    function getBoostMultiplier(
        address _user,
        uint256 _pid
    ) public view returns (uint256) {
        uint256 stakedOf = _userInfo[_pid][_user].stakedOf;
        if (stakedOf <= 100 ether) {
            return 100;
        } else if (stakedOf <= 500 ether) {
            return 150;
        } else {
            return 200;
        }
    }

    function stake(uint256 pid, uint256 amount) external returns (bool) {
        require(isStaking, "Staking is not enabled");
        require(amount > 0, "stake must be integer multiple of 1 token.");
        require(poolInfo[pid].allocPoint > 0, "stake pool is closed");

        _bonusReward();
        UserInfo storage user = _userInfo[pid][msg.sender];
        if (user.stakedOf > 0) {
            _takeReward(pid, msg.sender);
        }

        uint balanceBefore = IERC20(poolInfo[pid].lpToken).balanceOf(
            address(this)
        );

        TransferHelper.safeTransferFrom(
            poolInfo[pid].lpToken,
            msg.sender,
            address(this),
            amount
        );
        uint balanceAdd = IERC20(poolInfo[pid].lpToken).balanceOf(
            address(this)
        ) - balanceBefore;

        user.duration = poolInfo[pid].duration;
        user.lastDepositAt = block.timestamp;

        user.stakedOf += balanceAdd;
        totalBoostedShare[pid] -= userBoostedShare[pid][msg.sender];
        userBoostedShare[pid][msg.sender] =
            getBoostMultiplier(msg.sender, pid) *
            user.stakedOf;
        user.rewardOf =
            (userBoostedShare[pid][msg.sender] * poolInfo[pid].accPerShare) /
            1e12;

        totalBoostedShare[pid] += userBoostedShare[pid][msg.sender];
        poolInfo[pid].totalStaked += balanceAdd;

        emit Staked(
            msg.sender,
            poolInfo[pid].lpToken,
            poolInfo[pid].duration,
            balanceAdd
        );

        return true;
    }

    function unstake(
        uint256 pid,
        uint256 _amount
    ) external virtual returns (bool) {
        _bonusReward();

        UserInfo storage user = _userInfo[pid][msg.sender];
        require(user.stakedOf >= _amount, "unstake: Insufficient");
        if (user.stakedOf > 0) {
            _takeReward(pid, msg.sender);
        }

        if (_amount > 0) {
            poolInfo[pid].totalStaked -= _amount;
            user.stakedOf -= _amount;

            totalBoostedShare[pid] -= userBoostedShare[pid][msg.sender];
            userBoostedShare[pid][msg.sender] =
                getBoostMultiplier(msg.sender, pid) *
                user.stakedOf;
            totalBoostedShare[pid] += userBoostedShare[pid][msg.sender];
            TransferHelper.safeTransfer(
                poolInfo[pid].lpToken,
                msg.sender,
                _amount
            );
        }

        user.rewardOf =
            (userBoostedShare[pid][msg.sender] * poolInfo[pid].accPerShare) /
            1e12;

        emit Unstaked(
            msg.sender,
            poolInfo[pid].lpToken,
            poolInfo[pid].duration,
            _amount
        );
        return true;
    }

    function rewardAmount(
        address _account,
        uint256 pid
    ) external view returns (uint256) {
        uint256 pending;
        UserInfo memory _user = userInfo(pid, _account);
        if (_user.stakedOf > 0) {
            uint256 _accPerShare = poolInfo[pid].accPerShare;

            if (
                isBonus &&
                block.number > lastBonusBlock &&
                poolInfo[pid].allocPoint > 0
            ) {
                uint256 _reward = (getPendingReward() *
                    poolInfo[pid].allocPoint) / totalAllocPoint;
                _accPerShare += (_reward * 1e12) / totalBoostedShare[pid];
            }
            pending =
                ((userBoostedShare[pid][_account] * _accPerShare) / 1e12) -
                _user.rewardOf;
        }

        return pending;
    }

    function _takeReward(uint256 _pid, address _user) internal {
        UserInfo storage user = _userInfo[_pid][_user];
        uint256 pending = ((userBoostedShare[_pid][_user] *
            poolInfo[_pid].accPerShare) / 1e12) - user.rewardOf;
        user.userReward += _safeTransfer(_user, pending);
        _takeInviteReward(inviter[_user], (pending * inviteRewardRatio) / 1000);
        _takeInviteReward(
            inviter[inviter[_user]],
            (pending * inviteRewardRatio2) / 1000
        );
    }

    function takeReward(uint256 pid) external {
        _bonusReward();

        UserInfo storage user = _userInfo[pid][msg.sender];
        require(user.stakedOf > 0, "Staking: out of staked");
        uint256 pending = ((userBoostedShare[pid][msg.sender] *
            poolInfo[pid].accPerShare) / 1e12) - user.rewardOf;
        require(pending > 0, "Staking: no pending reward");

        _takeReward(pid, msg.sender);
        user.rewardOf =
            (userBoostedShare[pid][msg.sender] * poolInfo[pid].accPerShare) /
            1e12;
    }

    function _safeTransfer(
        address _account,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (_amount > 0 && balance > 0) {
            if (balance < _amount) {
                _amount = balance;
            }
            TransferHelper.safeTransfer(tokenAddress, _account, _amount);
            emit Reward(_account, _amount);
            return _amount;
        }
        return 0;
    }

    function _takeInviteReward(address _account, uint256 _amount) internal {
        if (_account != address(0)) {
            uint256 _reward = _safeTransfer(_account, _amount);
            inviteRewardOf[_account] += _reward;
        }
    }

    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        TransferHelper.safeTransfer(token_, to_, amount_);
    }
}