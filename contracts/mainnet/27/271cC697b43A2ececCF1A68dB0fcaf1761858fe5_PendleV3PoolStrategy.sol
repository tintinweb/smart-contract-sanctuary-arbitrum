pragma solidity 0.8.24;

interface IBeefyVaultV7 {
    //  uint256 r = (balance() * _shares) / totalSupply();

    function balance() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function want() external view returns (address);
}

pragma solidity 0.8.24;

interface IPendleLptOracle {
    function getLpToAssetRate(
        address market,
        uint32 duration
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../interfaces/IUniversalOracle.sol";
import "./interfaces/IPendleLptOracle.sol";
import "../interfaces/IBeefyVaultV7.sol";

contract PendleV3PoolStrategy {
    IUniversalOracle public universalOracle;
    IPendleLptOracle public pendleLptOracle;
    IBeefyVaultV7 public beefyVault;
    address pendleMarket;
    address usdc;
    address marketAsset;
    uint256 decimals;

    constructor(
        address _beefyVault,
        address _marketAsset,
        address _pendleLptOracle,
        address _universalOracle,
        address _usdc,
        uint256 _decimals
    ) {
        beefyVault = IBeefyVaultV7(_beefyVault);
        pendleMarket = IBeefyVaultV7(_beefyVault).want();
        universalOracle = IUniversalOracle(_universalOracle);
        pendleLptOracle = IPendleLptOracle(_pendleLptOracle);
        marketAsset = _marketAsset;
        usdc = _usdc;
        decimals = _decimals;
    }

    function getBalance(address strategist) external view returns (uint256) {
        uint256 strategistVaultSharesBalance = beefyVault.balanceOf(strategist);
        uint256 vaultLpBalance = beefyVault.balance();
        uint256 vaultSharesTotalSupply = beefyVault.totalSupply();

        uint256 strategistLpBalance = (vaultLpBalance *
            strategistVaultSharesBalance) / vaultSharesTotalSupply;

        uint256 pednleLptToAssetRate = pendleLptOracle.getLpToAssetRate(
            pendleMarket,
            3600
        );
        uint256 lptInAsset = (strategistLpBalance * pednleLptToAssetRate) /
            decimals;

        return universalOracle.getValue(marketAsset, lptInAsset, usdc);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

interface IUniversalOracle {
    function getValue(
        address baseAsset,
        uint256 amount,
        address quoteAsset
    ) external view returns (uint256 value);

    function getValues(
        address[] calldata baseAssets,
        uint256[] calldata amounts,
        address quoteAsset
    ) external view returns (uint256);

    function WETH() external view returns (address);

    function isSupported(address asset) external view returns (bool);

    function getPriceInUSD(address asset) external view returns (uint256);
}