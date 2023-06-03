// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint value) internal {
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
        uint value
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

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract XSWAP {
    address public owner;
    address public immutable tokenAddress;
    address public immutable depositToken;

    uint256 public totalFees;
    uint256 public minWithdrawRatio = 5; // 0.5%
    uint256 public maxWithdrawRatio = 500; // 50%
    uint256 public minWithdrawDuration = 15 days;
    uint256 public maxWithdrawDuration = 180 days;
    bool public isEmergencyRefund;

    mapping(address => uint256) public userRedeemAmount;
    mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances

    struct RedeemInfo {
        uint256 fairAmount;
        uint256 xFairAmount;
        uint256 endTime;
        uint256 duration;
        uint256 ratio;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    constructor(address fair, address xfair) {
        owner = msg.sender;
        tokenAddress = xfair;
        depositToken = fair;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setEmergencyRefund(bool value) external onlyOwner {
        isEmergencyRefund = value;
    }

    function setWithdrawRatio(uint256 min, uint256 max) external onlyOwner {
        require(min < max, "min must be less than max");
        require(max < 1000, "max must be less than 1000");
        minWithdrawRatio = min;
        maxWithdrawRatio = max;
    }

    function setWithdrawDuration(uint256 min, uint256 max) external onlyOwner {
        require(min < max, "min must be less than max");
        minWithdrawDuration = min;
        maxWithdrawDuration = max;
    }

    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        TransferHelper.safeTransfer(token_, to_, amount_);
    }

    function withdrawFees(address to_, uint256 amount_) external onlyOwner {
        totalFees -= amount_;
        TransferHelper.safeTransfer(depositToken, to_, amount_);
    }

    function deposit(uint256 amount_) external {
        TransferHelper.safeTransferFrom(
            depositToken,
            msg.sender,
            address(this),
            amount_
        );

        TransferHelper.safeTransfer(tokenAddress, msg.sender, amount_);
    }

    function userRedeemsLength(address user) external view returns (uint256) {
        return userRedeems[user].length;
    }

    function _deleteRedeemEntry(address user, uint256 index) internal {
        userRedeems[user][index] = userRedeems[user][
            userRedeems[user].length - 1
        ];
        userRedeems[user].pop();
    }

    function getWithdrawFairByDuration(
        uint256 xfarAmount,
        uint256 duration
    ) public view returns (uint256, uint256) {
        if (duration < minWithdrawDuration) {
            return (0, 1000);
        }

        uint256 ratio;
        if (duration < maxWithdrawDuration) {
            ratio =
                maxWithdrawRatio -
                (duration * maxWithdrawRatio) /
                maxWithdrawDuration;
        }

        if (ratio < minWithdrawRatio) {
            ratio = minWithdrawRatio;
        }
        return (xfarAmount - (xfarAmount * ratio) / 1000, ratio);
    }

    function withdraw(uint256 amount_, uint256 duration) external {
        require(amount_ > 0, "amount_ cannot be null");
        require(duration >= minWithdrawDuration, "duration too low");

        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            amount_
        );

        (uint256 fairAmount, uint256 ratio) = getWithdrawFairByDuration(
            amount_,
            duration
        );
        userRedeemAmount[msg.sender] += amount_;

        userRedeems[msg.sender].push(
            RedeemInfo({
                fairAmount: fairAmount,
                xFairAmount: amount_,
                endTime: block.timestamp + duration,
                duration: duration,
                ratio: ratio
            })
        );
    }

    function cancelWithdraw(uint256 redeemId) external {
        RedeemInfo memory info = userRedeems[msg.sender][redeemId];
        require(
            info.xFairAmount > 0 && info.fairAmount > 0,
            "invalid redeem amount"
        );
        userRedeemAmount[msg.sender] -= info.xFairAmount;
        _deleteRedeemEntry(msg.sender, redeemId);
        TransferHelper.safeTransfer(tokenAddress, msg.sender, info.xFairAmount);
    }

    function confirmWithdraw(uint256 redeemId) external {
        RedeemInfo memory info = userRedeems[msg.sender][redeemId];
        require(
            info.xFairAmount > 0 && info.fairAmount > 0,
            "invalid redeem amount"
        );

        if (!isEmergencyRefund) {
            require(block.timestamp >= info.endTime, "too early");
        }

        userRedeemAmount[msg.sender] -= info.xFairAmount;
        totalFees += info.xFairAmount - info.fairAmount;
        _deleteRedeemEntry(msg.sender, redeemId);
        TransferHelper.safeTransfer(depositToken, msg.sender, info.fairAmount);
    }
}