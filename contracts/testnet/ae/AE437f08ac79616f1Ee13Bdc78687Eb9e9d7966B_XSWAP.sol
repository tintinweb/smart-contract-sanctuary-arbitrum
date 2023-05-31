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

    uint256 public minWithdrawRatio = 5; // 0.5%
    uint256 public maxWithdrawRatio = 500; // 50%
    uint256 public minWithdrawDuration = 0 days; // 1296000s
    uint256 public maxWithdrawDuration = 180 days; // 7776000s
    mapping(address => uint256) public lastDepositAt;

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

    function deposit(uint256 amount_) external {
        TransferHelper.safeTransferFrom(
            depositToken,
            msg.sender,
            address(this),
            amount_
        );

        TransferHelper.safeTransfer(tokenAddress, msg.sender, amount_);
        lastDepositAt[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amount_) external {
        uint256 _days = (block.timestamp - lastDepositAt[msg.sender]) / 1 days;
        require(_days >= minWithdrawDuration, "too early to withdraw");

        uint256 ratio;
        if (_days < maxWithdrawDuration) {
            ratio =
                maxWithdrawRatio -
                (_days * maxWithdrawRatio) /
                maxWithdrawDuration;
        }

        if (ratio < minWithdrawRatio) {
            ratio = minWithdrawRatio;
        }

        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            amount_
        );

        amount_ -= (amount_ * ratio) / 1000;
        TransferHelper.safeTransfer(depositToken, msg.sender, amount_);
    }
}