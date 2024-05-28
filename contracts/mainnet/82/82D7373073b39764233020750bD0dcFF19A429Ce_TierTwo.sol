// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TierOne {
    uint256 public immutable startTime = 1716924949;
    uint256 public remainingTokens;
    
    uint256 public salePrice = 1e18;
    uint256 public publicAllocation;

    constructor(uint256 _remainingTokens) {
        remainingTokens = _remainingTokens * 1e18;
        publicAllocation = _remainingTokens * 1e18;
    }

    modifier onlyDuringSale {
        require(startTime <= block.timestamp, 'sale has not begun');
        _;
    }

    function purchase(uint256 _amount) public onlyDuringSale {
        require(_amount <= remainingTokens, "execution reverted: purchase is halted");
        remainingTokens -= _amount;
    }

    function whitelistedPurchaseWithCode(
        uint256 paymentAmount,
        bytes32[] calldata merkleProof,
        uint256 _allocation,
        string calldata code
    ) public {
        purchase(paymentAmount);
    }
}

contract TierTwo is TierOne {
    constructor(uint256 _remainingTokens) TierOne(_remainingTokens) { }
}