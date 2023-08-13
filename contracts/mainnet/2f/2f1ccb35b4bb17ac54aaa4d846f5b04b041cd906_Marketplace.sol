/**
 *Submitted for verification at Arbiscan on 2023-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Marketplace {
    mapping(address => bytes) private contents;
    uint256 baseEth;
    uint256 baseFerc;
    uint256 baseCash;

    function getContent() public view returns (string memory) {
        bytes memory bytesData = contents[msg.sender];
        return string(bytesData);
    }
    event OrderCreated(address sender, bool content);
    address private dev;
    address private ferc;
    address private cash;

    constructor() {
        dev = msg.sender;
        baseEth = 1 * 10 ** 14;
        baseFerc = 10;
        baseCash = 100;
        ferc = 0xC365B8Cbde40cB902CaE1BDDf425a4c9E1f60d3f;
        cash = 0xC365B8Cbde40cB902CaE1BDDf425a4c9E1f60d3f;
    }

    function setBase(uint256 baseEth, uint256 baseFerc,address ferc) public {
        require(msg.sender == dev,"not dev");
        baseEth = baseEth;
        baseFerc = baseFerc;
        ferc = ferc;
    }

    function createEth(string memory content) external payable {
        require(msg.value >= baseEth);
        bytes memory bytesData = bytes(content);
        contents[msg.sender] = bytesData;
        payable(dev).transfer(msg.value);
        emit OrderCreated(msg.sender, true);
    }

    function createFerc(string memory content) external {
        IERC20(ferc).transferFrom(msg.sender, dev, baseFerc * 10 ** 18);
        bytes memory bytesData = bytes(content);
        contents[msg.sender] = bytesData;
        emit OrderCreated(msg.sender, true);
    }

    function createCash(string memory content) external {
        IERC20(cash).transferFrom(msg.sender, dev, baseCash * 10 ** 18);
        bytes memory bytesData = bytes(content);
        contents[msg.sender] = bytesData;
        emit OrderCreated(msg.sender, true);
    }
}