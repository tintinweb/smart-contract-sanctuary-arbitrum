/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;


interface IBlockATMPayoutBusiness {

    function checkPayout(address autoAddress) external view returns(address);
}

interface IBlockATMPayout {


    struct Payout{
        address tokenAddress;
        uint256 amount;
        address toAddress;
    }

    function autoPayoutToken(bool safeFlag,Payout[] memory payoutList,string[] memory business) external returns (bool);

    function autoPayoutToken(bool safeFlag,address[] memory tokenList,uint256[] memory amountList,address[] memory toAddressList,string[] memory business) external returns (bool);


}
contract BlockATMPayoutGateway {

    address public businessAddress;

    address public onwer;

    constructor(address newBusinessAddress) {
        businessAddress = newBusinessAddress;
        onwer = msg.sender;
    }

    event SetBusinessAddress(address businessAddress);

    modifier onlyOwner() {
        require(onwer == msg.sender, "Not the owner");
        _;
    }

    function setBusinessAddress(address newBusinessAddress) public onlyOwner {
        businessAddress = newBusinessAddress;
        emit SetBusinessAddress(businessAddress);
    }


    function getBusinessAddress() public view returns(address)  {
        return businessAddress;
    }


    function payoutToken(bool safeFlag,IBlockATMPayout.Payout[] memory payoutList,string[] memory business) public returns (bool) {
        address payoutAddress = IBlockATMPayoutBusiness(businessAddress).checkPayout(msg.sender);
        return IBlockATMPayout(payoutAddress).autoPayoutToken(safeFlag,payoutList,business);
    }

    function payoutToken(bool safeFlag,address[] memory tokenList,uint256[] memory amountList,address[] memory toAddressList,string[] memory business) public returns (bool) {
        address payoutAddress = IBlockATMPayoutBusiness(businessAddress).checkPayout(msg.sender);
        return IBlockATMPayout(payoutAddress).autoPayoutToken(safeFlag,tokenList,amountList,toAddressList,business);
    }

}