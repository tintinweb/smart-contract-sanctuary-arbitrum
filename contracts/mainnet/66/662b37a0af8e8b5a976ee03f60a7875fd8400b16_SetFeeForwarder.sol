/**
 *Submitted for verification at Arbiscan.io on 2024-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ISettingsManager {
    function setMarketOrderGasFee(uint256 _fee) external;
    function setTriggerGasFee(uint256 _fee) external;
}

contract SetFeeForwarder{
    ISettingsManager public constant settingsManager = ISettingsManager(0x6F2c6010A438546242cAb29Bb755c1F0AfaCa5AA); //arbitrum

    function setMarketOrderGasFee(uint256 _fee) external{
        require(msg.sender == 0x628D6d1345D281c405b700a2766385ecC83195e1, "!owner");
        settingsManager.setMarketOrderGasFee(_fee);
    }

    function setTriggerGasFee(uint256 _fee) external{
        require(msg.sender == 0x628D6d1345D281c405b700a2766385ecC83195e1, "!owner");
        settingsManager.setTriggerGasFee(_fee);
    }

    function setBoth(uint256 _marketOrderFee, uint256 _triggerOrderFee) external{
        require(msg.sender == 0x628D6d1345D281c405b700a2766385ecC83195e1, "!owner");
        settingsManager.setMarketOrderGasFee(_marketOrderFee);
        settingsManager.setTriggerGasFee(_triggerOrderFee);
    }
}