/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TuyulMultiSend {
    address payable owner;
    
    constructor() {
        owner = payable(msg.sender);
    }
    function kirimKeTuyul(address payable[] memory _recipients, uint256[] memory _amounts) payable public {
        require(_recipients.length == _amounts.length, "Address penerima harus sama dengan total jumlah");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount += _amounts[i];
        }
        require(msg.value >= totalAmount, "Jumlah yang dikirim harus sama dengan total jumlah yang ingin dikirim");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(_amounts[i]);
        }
    }

    function withdraw() public {
        require(msg.sender == owner, "Hanya pembuat/deployer yang bisa withdraw!");
        uint balanceBeforeWithdraw = address(this).balance;
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send");
        require(address(this).balance == balanceBeforeWithdraw - address(this).balance, "Balance mismatch after withdraw");
    }
}