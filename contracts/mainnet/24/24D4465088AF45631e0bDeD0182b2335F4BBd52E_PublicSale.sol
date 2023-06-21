// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
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
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

contract PublicSale {
    address public daoAddress;
    address public owner;

    uint256 public totalBuyAmount;
    uint256 public totalUnlock;
    uint256 public totalUser;

    uint256 public sharesStartTime;
    uint256 public sharesEndTime;
    uint256 public sharesUnlockTime;

    address public tokenAddress;
    uint256 public baseTokenUint = 1 ether;
    address public constant usdtToken =
        0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    uint256 public sharesPrice = 350000;
    uint256 public sharesAmount = 300000 ether;
    uint256 public userMaxQuota = 5000 * 1e6;
    uint256 public inviteRewardRate = 50; // 50/1000 5%
    bool public isEmergencyRefund;
    bool public isDone;

    uint256 public unlockEpoch = 1 days;
    uint256 private _unlockTimes = 1;
    bool public isDayUnlock = true;

    uint256[] public unlockTime;
    uint256[] public unlockRate;

    mapping(address => address) public inviter;
    mapping(address => uint256) public inviteCount;
    mapping(address => uint256) public lastUnlockAt;
    mapping(address => uint256) public inviteRewardOf;
    mapping(address => uint256) public friendBuyOf;
    mapping(address => uint256) private giveFriendBuyOf;
    mapping(address => uint256) public userBuyOf;
    mapping(address => uint256) private _userQuota;
    mapping(address => uint256) public freezeQuota;
    mapping(address => uint256) public userUnlockOf;

    event EmitBuy(address indexed account, uint256 amount);
    event EmitEmergencyRefund(address indexed account, uint256 amount);
    event EmitUnlock(address indexed account, uint256 amount);
    event EmitBindInviter(address indexed inviter, address indexed account);
    event EmitSharesDone(address indexed dao, uint256 amount);

    constructor(
        address dao,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _unlockTime
    ) {
        owner = msg.sender;
        daoAddress = dao;
        setSharesTime(_startTime, _endTime, _unlockTime);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setDaoAddr(address newAddr) external onlyOwner {
        daoAddress = newAddr;
    }

    function setTokenAddr(address newAddr) external onlyOwner {
        require(newAddr != usdtToken, "invalid token address");
        tokenAddress = newAddr;
        baseTokenUint = 10 ** IERC20(tokenAddress).decimals();
    }

    function setIsEmergencyRefund() external onlyOwner {
        require(!isEmergencyRefund, "already refund");
        isEmergencyRefund = !isEmergencyRefund;
    }

    function setSharesAmount(uint256 _amounts) external onlyOwner {
        sharesAmount = _amounts;
    }

    function setSharesPrice(uint256 _price) external onlyOwner {
        sharesPrice = _price;
    }

    function setUserMaxQuota(uint256 _num) external onlyOwner {
        userMaxQuota = _num;
    }

    function setSharesTime(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _unlockTime
    ) public onlyOwner {
        require(
            _endTime > _startTime && _unlockTime >= _endTime,
            "end time error"
        );
        sharesStartTime = _startTime;
        sharesEndTime = _endTime;
        sharesUnlockTime = _unlockTime;
    }

    function setDayUnlock(uint256 _times, uint256 _epoch) public onlyOwner {
        isDayUnlock = true;
        _unlockTimes = _times;
        unlockEpoch = _epoch;
    }

    function setEpochUnlock(
        uint256[] memory _time,
        uint256[] memory _rates
    ) public onlyOwner {
        require(_time.length > 0 && _time.length == _rates.length, "set error");
        isDayUnlock = false;

        uint256 prev = sharesEndTime;
        uint256 rate = 0;
        for (uint256 i = 0; i < _time.length; i++) {
            require(_time[i] > prev, "time error");
            prev = _time[i];
            rate += _rates[i];
        }
        require(rate == 1000, "rate error");

        unlockTime = _time;
        unlockRate = _rates;
    }

    function unlockTimes() public view returns (uint256) {
        return isDayUnlock ? _unlockTimes : unlockTime.length;
    }

    function setInviteRewardRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1000, "rate error");
        inviteRewardRate = _rate;
    }

    function bindInviter(address _inviter) external {
        require(inviter[msg.sender] == address(0), "Error: Repeat binding");
        require(_inviter != msg.sender, "Error: Binding self");
        require(
            _inviter != address(0),
            "Error: Binding inviter is zero address"
        );
        _bindInviter(_inviter, msg.sender);
    }

    function _bindInviter(address _inviter, address _account) private {
        if (
            _inviter != address(0) &&
            _inviter != _account &&
            inviter[_account] == address(0) &&
            inviter[_inviter] != _account
        ) {
            inviter[_account] = _inviter;
            inviteCount[_inviter] += 1;
            emit EmitBindInviter(_inviter, _account);
        }
    }

    function buy(address _inviter, uint256 _amount) external returns (bool) {
        require(!isEmergencyRefund, "refund");
        require(
            block.timestamp > sharesStartTime &&
                block.timestamp < sharesEndTime,
            "Time error"
        );
        require(_amount > 0, "shareAmount error");
        require(usdtToken != address(0), "token error");

        require(
            userMaxQuota >= _amount + userBuyOf[msg.sender],
            "userQuota amount error"
        );

        _bindInviter(_inviter, msg.sender);

        TransferHelper.safeTransferFrom(
            usdtToken,
            msg.sender,
            address(this),
            _amount
        );

        if (userBuyOf[msg.sender] == 0) {
            totalUser += 1;
        }

        totalBuyAmount += _amount;
        userBuyOf[msg.sender] += _amount;

        if (inviter[msg.sender] != address(0)) {
            friendBuyOf[inviter[msg.sender]] +=
                userBuyOf[msg.sender] -
                giveFriendBuyOf[msg.sender];
            giveFriendBuyOf[msg.sender] = userBuyOf[msg.sender];
        }

        emit EmitBuy(msg.sender, _amount);
        return true;
    }

    function getUserQuota(address account_) public view returns (uint256) {
        if (userBuyOf[account_] == 0) {
            return 0;
        }

        if (_userQuota[account_] > 0) {
            return _userQuota[account_];
        }

        uint256 tokenAmount = (userBuyOf[account_] * sharesAmount) /
            totalBuyAmount;
        uint256 maxBuyAmount = (userBuyOf[account_] * baseTokenUint) /
            sharesPrice;

        if (tokenAmount < maxBuyAmount) {
            return tokenAmount;
        } else {
            return maxBuyAmount;
        }
    }

    function getUnlockAmount(
        address account_
    ) public view returns (uint256, uint256) {
        return
            isDayUnlock
                ? _getDayUnlockAmount(account_)
                : _getEpochUnlockAmount(account_);
    }

    function _getEpochUnlockAmount(
        address account_
    ) private view returns (uint256, uint256) {
        uint256 userQuota = getUserQuota(account_);
        uint256 rate;
        for (uint256 i = 0; i < unlockTime.length; i++) {
            if (block.timestamp >= unlockTime[i]) {
                rate += unlockRate[i];
            }
        }
        if (userQuota > 0 && rate > 0) {
            return (
                (userQuota * rate) / 1000 - userUnlockOf[account_],
                userQuota
            );
        } else {
            return (0, userQuota);
        }
    }

    function _getDayUnlockAmount(
        address account_
    ) private view returns (uint256, uint256) {
        uint256 userQuota = getUserQuota(account_);
        if (userQuota > 0 && block.timestamp > sharesUnlockTime) {
            uint256 avgUnlockAmount = userQuota / _unlockTimes;
            uint256 _days = (block.timestamp - sharesUnlockTime) /
                unlockEpoch +
                1;
            uint256 unlockAmount = avgUnlockAmount * _days;

            if (unlockAmount + userUnlockOf[account_] > userQuota) {
                unlockAmount = userQuota - userUnlockOf[account_];
            } else {
                unlockAmount -= userUnlockOf[account_];
            }

            return (unlockAmount, userQuota);
        } else {
            return (0, userQuota);
        }
    }

    function nextUnlockTime() external view returns (uint256) {
        uint256 nextTime;
        if (isDayUnlock) {
            if (lastUnlockAt[msg.sender] == 0) {
                return sharesUnlockTime;
            } else {
                return lastUnlockAt[msg.sender] + unlockEpoch;
            }
        } else {
            for (uint256 i = 0; i < unlockTime.length; i++) {
                nextTime = unlockTime[i];
                if (block.timestamp < unlockTime[i]) {
                    return nextTime;
                }
            }
        }

        return nextTime;
    }

    function unlock() external {
        require(!isEmergencyRefund, "refund");
        require(block.timestamp >= sharesUnlockTime, "Time error");
        require(tokenAddress != address(0), "Error: token address is zero");
        (uint256 unlockAmount, uint256 userQuota) = getUnlockAmount(msg.sender);
        require(userQuota > 0, "Error: user quota is zero");
        require(unlockAmount > 0, "Error: unlock time not reached");

        _userQuota[msg.sender] = userQuota;
        userUnlockOf[msg.sender] += unlockAmount;
        require(
            userUnlockOf[msg.sender] <= userQuota,
            "Error: unlock amount overflow error"
        );

        if (lastUnlockAt[msg.sender] == 0) {
            uint256 usedUsdt = (userQuota * sharesPrice) / baseTokenUint;
            uint256 diff = userBuyOf[msg.sender] - usedUsdt;

            transferUsdt(msg.sender, diff);

            if (inviter[msg.sender] != address(0) && usedUsdt > 0) {
                uint256 _reward = (usedUsdt * inviteRewardRate) / 1000;
                inviteRewardOf[inviter[msg.sender]] += _reward;
                transferUsdt(inviter[msg.sender], _reward);
            }
        }

        lastUnlockAt[msg.sender] = block.timestamp;
        totalUnlock += unlockAmount;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, unlockAmount);

        emit EmitUnlock(msg.sender, unlockAmount);
    }

    function emergencyRefund() external returns (bool) {
        require(isEmergencyRefund, "is emergency refund error");
        require(userBuyOf[msg.sender] > 0, "shareAmount error");
        freezeQuota[msg.sender] += getUserQuota(msg.sender);

        uint256 _amount = userBuyOf[msg.sender];
        userBuyOf[msg.sender] = 0;
        TransferHelper.safeTransfer(usdtToken, msg.sender, _amount);
        emit EmitEmergencyRefund(msg.sender, _amount);
        return true;
    }

    function sharesDone() external onlyOwner {
        require(block.timestamp > sharesEndTime, "Time error");
        require(!isDone, "Already got");

        uint256 sharesAmountValue = (sharesAmount * sharesPrice) /
            baseTokenUint;

        isDone = true;
        uint256 pendingAmount = totalBuyAmount;
        if (totalBuyAmount > sharesAmountValue) {
            uint256 balance = IERC20(usdtToken).balanceOf(address(this));

            if (balance < sharesAmountValue) {
                pendingAmount = balance;
            } else {
                pendingAmount = sharesAmountValue;
            }
        }

        pendingAmount = ((1000 - inviteRewardRate) * pendingAmount) / 1000;
        TransferHelper.safeTransfer(usdtToken, daoAddress, pendingAmount);
        emit EmitSharesDone(daoAddress, pendingAmount);
    }

    function transferUsdt(address _account, uint256 amount) private {
        if (amount > 0) {
            uint256 balance = IERC20(usdtToken).balanceOf(address(this));
            if (balance < amount) {
                TransferHelper.safeTransfer(usdtToken, _account, balance);
            } else {
                TransferHelper.safeTransfer(usdtToken, _account, amount);
            }
        }
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(tokenAddress, daoAddress, amount);
    }
}