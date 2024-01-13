/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;

interface IBlockATMPayout {

    function getOwnerAddressFlag(address ownerAddress) external view returns(bool);   
}

contract BlockATMPayoutBusiness {

    address public onwer;

    mapping(address => address) private payoutMap;

    constructor() {
        onwer = msg.sender;
    }

    event SetSettleAddress(address settleAddress);

    modifier onlyOwner() {
        require(onwer == msg.sender, "Not the owner");
        _;
    }

    modifier onlyPayout(address payoutContract) {
        require(IBlockATMPayout(payoutContract).getOwnerAddressFlag(msg.sender), "Not the payout owner");
        _;
    }


    function getPayout(address autoAddress) public view returns(address)  {
        return payoutMap[autoAddress];
    }

    function setPayout(address autoAddress,address payoutContract) public onlyPayout(payoutContract) returns(bool)  {
        payoutMap[autoAddress] = payoutContract;
        payoutMap[payoutContract] = autoAddress;
        return true;
    }

    function deletePayout(address payoutContract) public onlyPayout(payoutContract) returns(bool)  {
        payoutMap[payoutContract] = address(0);
        return true;
    }

    function checkPayout(address autoAddress) public view returns (address) {
        address payoutAddress = payoutMap[autoAddress];
        require(payoutAddress != address(0), "payout address is null");
        require(payoutMap[payoutAddress] == autoAddress, "payout address is error");
        return payoutAddress;
    }

}