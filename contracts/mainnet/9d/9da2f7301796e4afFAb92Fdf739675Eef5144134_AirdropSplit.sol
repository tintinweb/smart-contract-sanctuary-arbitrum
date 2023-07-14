// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

contract AirdropSplit {
    address public owner;
    address public immutable tokenAddress;
    uint256 public totalShares = 2000 ether;
    uint256 public ticketPrice = 1 ether;

    uint256 public totalReleased;
    uint256 public endAt;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public released;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);

    constructor(address _tokenAddress, uint256 _endAt) {
        tokenAddress = _tokenAddress;
        endAt = _endAt;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "AirdropSplit: only owner can call");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setEndAt(uint256 _endAt) external onlyOwner {
        endAt = _endAt;
    }

    function setTotalShares(uint256 _totalShares) external onlyOwner {
        totalShares = _totalShares;
    }

    function join() external {
        require(endAt > block.timestamp, "AirdropSplit: already ended");
        require(shares[msg.sender] == 0, "AirdropSplit: already joined");
        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            ticketPrice
        );

        totalReleased += ticketPrice;
        shares[msg.sender] = ticketPrice;
        emit PayeeAdded(msg.sender, ticketPrice);
    }

    function release() public {
        require(block.timestamp >= endAt, "AirdropSplit: not yet ended");
        require(shares[msg.sender] > 0, "AirdropSplit: account has no shares");
        require(
            released[msg.sender] == 0,
            "AirdropSplit: account has already released"
        );

        uint256 payment = releasable(msg.sender);
        require(payment != 0, "AirdropSplit: account is not due payment");
        released[msg.sender] = payment;
        TransferHelper.safeTransfer(
            tokenAddress,
            msg.sender,
            payment + ticketPrice
        );

        emit PaymentReleased(msg.sender, payment);
    }

    function releasable(address _account) public view returns (uint256) {
        return (totalShares * shares[_account]) / totalReleased;
    }
}