/**
 *Submitted for verification at Arbiscan.io on 2024-01-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
interface ISettingsManager{
    function setMaxFundingRate(uint256 _maxFundingRate) external;
    function setVolatilityFactor(uint256 _tokenId, uint256 _volatilityFactor) external;
    function setLongBiasFactor(uint256 _tokenId, uint256 _longBiasFactor) external;
    function setFundingRateVelocityFactor(
        uint256 _tokenId,
        uint256 _fundingRateVelocityFactor
    ) external;
    function setTempMaxFundingRateFactor(uint256 _tokenId, uint256 _tempMaxFundingRateFactor) external;
}

contract Vela_FundingFee_Upgrade_OP3 {
    ISettingsManager constant SettingsManager = ISettingsManager(0x6F2c6010A438546242cAb29Bb755c1F0AfaCa5AA); //arbitrum
    //ISettingsManager constant SettingsManager = ISettingsManager(0xe8aeE3EeAdeCF8Ee0150B2368d40a076BF36624a); //base
    bool upgraded;
    function run() external{
        require(!upgraded, "already upgraded");
        SettingsManager.setMaxFundingRate(300000000000); //0.03%
        // 1 BTC/USD Crypto
        SettingsManager.setVolatilityFactor(1, 4750);
        SettingsManager.setTempMaxFundingRateFactor(1, 500);
        SettingsManager.setFundingRateVelocityFactor(1, 2_400_000);
        SettingsManager.setLongBiasFactor(1, 2500);
        // 2 ETH/USD Crypto
        SettingsManager.setVolatilityFactor(2, 5028);
        SettingsManager.setTempMaxFundingRateFactor(2, 500);
        SettingsManager.setFundingRateVelocityFactor(2, 2_400_000);
        SettingsManager.setLongBiasFactor(2, 2500);
        // 3 LTC/USD Crypto
        SettingsManager.setVolatilityFactor(3, 5931);
        SettingsManager.setTempMaxFundingRateFactor(3, 500);
        SettingsManager.setFundingRateVelocityFactor(3, 2_400_000);
        SettingsManager.setLongBiasFactor(3, 2500);
        // 4 ADA/USD Crypto
        SettingsManager.setVolatilityFactor(4, 8774);
        SettingsManager.setTempMaxFundingRateFactor(4, 500);
        SettingsManager.setFundingRateVelocityFactor(4, 2_400_000);
        SettingsManager.setLongBiasFactor(4, 2500);
        // 5 DOGE/USD Crypto
        SettingsManager.setVolatilityFactor(5, 6188);
        SettingsManager.setTempMaxFundingRateFactor(5, 500);
        SettingsManager.setFundingRateVelocityFactor(5, 2_400_000);
        SettingsManager.setLongBiasFactor(5, 2500);
        // 6 SHIB/USD Crypto
        SettingsManager.setVolatilityFactor(6, 7143);
        SettingsManager.setTempMaxFundingRateFactor(6, 500);
        SettingsManager.setFundingRateVelocityFactor(6, 2_400_000);
        SettingsManager.setLongBiasFactor(6, 2500);
        // 7 ARB/USD Crypto
        SettingsManager.setVolatilityFactor(7, 12818);
        SettingsManager.setTempMaxFundingRateFactor(7, 500);
        SettingsManager.setFundingRateVelocityFactor(7, 2_400_000);
        SettingsManager.setLongBiasFactor(7, 2500);
        // 8 SOL/USD Crypto
        SettingsManager.setVolatilityFactor(8, 10980);
        SettingsManager.setTempMaxFundingRateFactor(8, 500);
        SettingsManager.setFundingRateVelocityFactor(8, 2_400_000);
        SettingsManager.setLongBiasFactor(8, 2500);
        // 9 MATIC/USD Crypto
        SettingsManager.setVolatilityFactor(9, 9220);
        SettingsManager.setTempMaxFundingRateFactor(9, 500);
        SettingsManager.setFundingRateVelocityFactor(9, 2_400_000);
        SettingsManager.setLongBiasFactor(9, 2500);
        // 10 AVAX/USD Crypto
        SettingsManager.setVolatilityFactor(10, 10190);
        SettingsManager.setTempMaxFundingRateFactor(10, 500);
        SettingsManager.setFundingRateVelocityFactor(10, 2_400_000);
        SettingsManager.setLongBiasFactor(10, 2500);
        // 11 GBP/USD Forex
        SettingsManager.setVolatilityFactor(11, 578);
        SettingsManager.setTempMaxFundingRateFactor(11, 500);
        SettingsManager.setFundingRateVelocityFactor(11, 2_400_000);
        // 12 EUR/USD Forex
        SettingsManager.setVolatilityFactor(12, 542);
        SettingsManager.setTempMaxFundingRateFactor(12, 500);
        SettingsManager.setFundingRateVelocityFactor(12, 2_400_000);
        // 13 USD/JPY Forex
        SettingsManager.setVolatilityFactor(13, 820);
        SettingsManager.setTempMaxFundingRateFactor(13, 500);
        SettingsManager.setFundingRateVelocityFactor(13, 2_400_000);
        // 14 AUD/USD Forex
        SettingsManager.setVolatilityFactor(14, 779);
        SettingsManager.setTempMaxFundingRateFactor(14, 500);
        SettingsManager.setFundingRateVelocityFactor(14, 2_400_000);
        // 15 USD/CAD Forex
        SettingsManager.setVolatilityFactor(15, 466);
        SettingsManager.setTempMaxFundingRateFactor(15, 500);
        SettingsManager.setFundingRateVelocityFactor(15, 2_400_000);
        // 24 XAG/USD Metal
        SettingsManager.setVolatilityFactor(24, 2000);
        SettingsManager.setTempMaxFundingRateFactor(24, 500);
        SettingsManager.setFundingRateVelocityFactor(24, 2_400_000);
        // 25 XAU/USD Metal
        SettingsManager.setVolatilityFactor(25, 979);
        SettingsManager.setTempMaxFundingRateFactor(25, 500);
        SettingsManager.setFundingRateVelocityFactor(25, 2_400_000);
        // 28 USD/MXN Forex
        SettingsManager.setVolatilityFactor(28, 582);
        SettingsManager.setTempMaxFundingRateFactor(28, 500);
        SettingsManager.setFundingRateVelocityFactor(28, 2_400_000);
        // 30 USDT/USD Crypto
        SettingsManager.setVolatilityFactor(30, 119);
        SettingsManager.setTempMaxFundingRateFactor(30, 500);
        SettingsManager.setFundingRateVelocityFactor(30, 2_400_000);
        SettingsManager.setLongBiasFactor(30, 2500);
        // 31 ATOM/USD Crypto
        SettingsManager.setVolatilityFactor(31, 8401);
        SettingsManager.setTempMaxFundingRateFactor(31, 500);
        SettingsManager.setFundingRateVelocityFactor(31, 2_400_000);
        SettingsManager.setLongBiasFactor(31, 2500);
        // 32 DOT/USD Crypto
        SettingsManager.setVolatilityFactor(32, 9378);
        SettingsManager.setTempMaxFundingRateFactor(32, 500);
        SettingsManager.setFundingRateVelocityFactor(32, 2_400_000);
        SettingsManager.setLongBiasFactor(32, 2500);
        // 33 BNB/USD Crypto
        SettingsManager.setVolatilityFactor(33, 5709);
        SettingsManager.setTempMaxFundingRateFactor(33, 500);
        SettingsManager.setFundingRateVelocityFactor(33, 2_400_000);
        SettingsManager.setLongBiasFactor(33, 2500);
        // 34 PEPE/USD Crypto
        SettingsManager.setVolatilityFactor(34, 11706);
        SettingsManager.setTempMaxFundingRateFactor(34, 500);
        SettingsManager.setFundingRateVelocityFactor(34, 2_400_000);
        SettingsManager.setLongBiasFactor(34, 2500);
        // 35 XRP/USD Crypto
        SettingsManager.setVolatilityFactor(35, 5836);
        SettingsManager.setTempMaxFundingRateFactor(35, 500);
        SettingsManager.setFundingRateVelocityFactor(35, 2_400_000);
        SettingsManager.setLongBiasFactor(35, 2500);
        // 36 CRV/USD Crypto
        SettingsManager.setVolatilityFactor(36, 9200);
        SettingsManager.setTempMaxFundingRateFactor(36, 500);
        SettingsManager.setFundingRateVelocityFactor(36, 2_400_000);
        SettingsManager.setLongBiasFactor(36, 2500);
        // 37 MKR/USD Crypto
        SettingsManager.setVolatilityFactor(37, 9073);
        SettingsManager.setTempMaxFundingRateFactor(37, 500);
        SettingsManager.setFundingRateVelocityFactor(37, 2_400_000);
        SettingsManager.setLongBiasFactor(37, 2500);
        // 38 OP/USD Crypto
        SettingsManager.setVolatilityFactor(38, 13837);
        SettingsManager.setTempMaxFundingRateFactor(38, 500);
        SettingsManager.setFundingRateVelocityFactor(38, 2_400_000);
        SettingsManager.setLongBiasFactor(38, 2500);
        // 39 LINK/USD Crypto
        SettingsManager.setVolatilityFactor(39, 8065);
        SettingsManager.setTempMaxFundingRateFactor(39, 500);
        SettingsManager.setFundingRateVelocityFactor(39, 2_400_000);
        SettingsManager.setLongBiasFactor(39, 2500);
        // 40 INJ/USD Crypto
        SettingsManager.setVolatilityFactor(40, 13106);
        SettingsManager.setTempMaxFundingRateFactor(40, 500);
        SettingsManager.setFundingRateVelocityFactor(40, 2_400_000);
        SettingsManager.setLongBiasFactor(40, 2500);
        // 41 PYTH/USD Crypto
        SettingsManager.setVolatilityFactor(41, 12835);
        SettingsManager.setTempMaxFundingRateFactor(41, 500);
        SettingsManager.setFundingRateVelocityFactor(41, 2_400_000);
        SettingsManager.setLongBiasFactor(41, 2500);
        // 42 BONK/USD Crypto
        SettingsManager.setVolatilityFactor(42, 17249);
        SettingsManager.setTempMaxFundingRateFactor(42, 500);
        SettingsManager.setFundingRateVelocityFactor(42, 2_400_000);
        SettingsManager.setLongBiasFactor(42, 2500);
        // 43 TIA/USD Crypto
        SettingsManager.setVolatilityFactor(43, 14805);
        SettingsManager.setTempMaxFundingRateFactor(43, 500);
        SettingsManager.setFundingRateVelocityFactor(43, 2_400_000);
        SettingsManager.setLongBiasFactor(43, 2500);
        // 44 SEI/USD Crypto
        SettingsManager.setVolatilityFactor(44, 18299);
        SettingsManager.setTempMaxFundingRateFactor(44, 500);
        SettingsManager.setFundingRateVelocityFactor(44, 2_400_000);
        SettingsManager.setLongBiasFactor(44, 2500);
        // 45 SUI/USD Crypto
        SettingsManager.setVolatilityFactor(45, 12847);
        SettingsManager.setTempMaxFundingRateFactor(45, 500);
        SettingsManager.setFundingRateVelocityFactor(45, 2_400_000);
        SettingsManager.setLongBiasFactor(45, 2500);
        upgraded = true;
    }
}