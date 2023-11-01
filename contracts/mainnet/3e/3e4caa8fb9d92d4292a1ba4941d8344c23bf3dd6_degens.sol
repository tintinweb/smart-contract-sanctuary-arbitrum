/**
 *Submitted for verification at Arbiscan.io on 2023-10-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;



interface IDegenMain{
    struct PositionInfo {
        bool isLong;
        bool isOpen;
        address marginAsset;
        address player;
        uint32 timestampOpened;
        uint96 priceOpened;
        uint96 positionSizeUsd; // in the asset (ETH or BTC)
        uint32 fundingRateOpen;
        uint32 orderIndex;
        uint96 marginAmountUsd; // amount of margin in USD
        uint96 maxPositionProfitUsd;
        uint96 positionSizeInTargetAsset;
    }
    
    function getOpenPositionsInfo() external view returns (PositionInfo[] memory _positions);
    function getOpenPositionKeys() external view returns (bytes32[] memory _positionKeys);
    function positions(bytes32 _positionKey) external view returns (PositionInfo memory);
}


contract degens {

    address degenMainBTC = 0x2C9b5ab11e7a8255e310E57475B8E13FFaA9e92d;
    address degenMainETH = 0xe604f8Db1B98639CC3f04c0aC1a51951C3018e07;
    address degenPoolManagerBTC = 0x905C53D24f285B925cB1aFf5CEa2F5702d6295C0;
    address degenPoolManagerETH = 0xeC3737DF91E39647d56C4f7e07138EB4CDDf4cc6;
    address degenRouterBTC = 0x162309511d386e28015Fd0a9a33D3dF50F4e5C8C;
    address degenRouterETH = 0xe7703c5c264cDF7B86Bee65582759cd37ed3EFAc;
    
    bytes32 assetBTC = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;
    bytes32 assetETH = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    
    address tokenBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address tokenETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function getOrdersKeysBTC() public view returns (bytes32[] memory _positionKeys){
        return IDegenMain(degenMainBTC).getOpenPositionKeys();
    }

    function getOrdersKeysETH() public view returns (bytes32[] memory _positionKeys){
        return IDegenMain(degenMainETH).getOpenPositionKeys();
    }


    function getPositionInfoFromKeyBTC(bytes32 _key) public view returns (IDegenMain.PositionInfo memory){
        return IDegenMain(degenMainBTC).positions(_key);
    }

    function getPositionInfoFromKeyETH(bytes32 _key) public view returns (IDegenMain.PositionInfo memory){
        return IDegenMain(degenMainETH).positions(_key);
    }

    function getPositionInfoFromKey(bytes32 _key) public view returns (IDegenMain.PositionInfo memory){
        if(IDegenMain(degenMainBTC).positions(_key).isOpen = true){
            return IDegenMain(degenMainBTC).positions(_key);
        }
        else if(IDegenMain(degenMainETH).positions(_key).isOpen = true){
            return IDegenMain(degenMainETH).positions(_key);
        }
        else{
            revert();
        }
    }


}