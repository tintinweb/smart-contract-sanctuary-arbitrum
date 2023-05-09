/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MeritBox {
    address public _owner; // 紀錄是哪個地址部署這份合約
    uint256 public _maxValue; // 紀錄捐款最多者
    address public _maxDonor; // 紀錄捐款最多的數量

    constructor() { // 部署合約時會
        _owner = msg.sender; // 將呼叫函數者（在 constructor 內即為部署合約者）的地址存為 _owner
    }

    function withdraw() public { // withdraw 函數
        require(msg.sender == _owner); // 僅有 _owner 可以呼叫此函數
        payable(_owner).transfer(address(this).balance); // 將此合約地址的餘額通通轉帳予 _owner
    }

    receive() external payable { // 若非呼叫函數，僅是將 eth 送至合約地址，會執行 receive
        if (msg.value > _maxValue) { // 如果這次的金額大於最大值
            _maxValue = msg.value; // 設定 _maxValue 為這次的金額
            _maxDonor = msg.sender; // 設定 _maxDonor 為這次的發送者
        }
    }
}