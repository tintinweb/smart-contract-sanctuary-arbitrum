//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
pragma abicoder v2;

interface ISettingsManager{
    function setDeductFeePercentForUser(address _account, uint256 _deductFee) external ;
}

ISettingsManager constant SettingsManager = ISettingsManager(0x6F2c6010A438546242cAb29Bb755c1F0AfaCa5AA); //mainnet
contract DeductFee_Forwarder{
    address operator;
    constructor(){
        operator = msg.sender;
    }
    function setDeductFeePercentForUser(address _account, uint256 _deductFee) external{
        require(msg.sender == operator, "onlyOwner");
        SettingsManager.setDeductFeePercentForUser(_account, _deductFee);
    }
}