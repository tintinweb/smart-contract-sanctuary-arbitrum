// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.0;

interface ITokenToUsdcOracle {
    function usdcAmount(uint256 tokenAmount) external view returns (uint256 usdcAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.0;

interface IVaultStrategy {
    function getBalance(address strategist) external view returns (uint256);
}

pragma solidity ^0.8.19;

interface ISiloIncentivesController {
    function getRewardsBalance(
        address[] calldata _assets,
        address _user
    )
    external
    view
    returns (uint256);
}

pragma solidity ^0.8.19;

interface ISiloLens {
    function collateralBalanceOfUnderlying(
        address _silo,
        address _asset,
        address _user
    )
    external
    view
    returns (uint256);
}

pragma solidity ^0.8.19;

import "../../interfaces/IVaultStrategy.sol";

interface ISiloStrategy is IVaultStrategy {}

pragma solidity ^0.8.19;

import "./interfaces/ISiloStrategy.sol";
import "./interfaces/ISiloLens.sol";
import "./interfaces/ISiloIncentivesController.sol";

import "../interfaces/ITokenToUsdcOracle.sol";

contract SiloStrategy is ISiloStrategy {
    ISiloLens siloLens;
    ISiloIncentivesController siloIncentivesController;
    ITokenToUsdcOracle tokenTokUsdcOracle;
    address silo;
    address collateralAsset;
    address siloAsset;

    constructor(address _siloLens, address _siloIncentivesController, address _oracle, address _silo, address _collateralAsset, address _siloAsset) {
        siloLens = ISiloLens(_siloLens);
        siloIncentivesController = ISiloIncentivesController(_siloIncentivesController);
        tokenTokUsdcOracle = ITokenToUsdcOracle(_oracle);
        silo = _silo;
        collateralAsset = _collateralAsset;
        siloAsset = _siloAsset;
    }

    function getBalance(address strategist) external view returns(uint256) {
        uint256 usdcBalance = siloLens.collateralBalanceOfUnderlying(silo, collateralAsset, strategist);

        address[] memory assets = new address[](1);
        assets[0] = siloAsset;

        uint256 rewards = siloIncentivesController.getRewardsBalance(assets, strategist);

        usdcBalance += tokenTokUsdcOracle.usdcAmount(rewards);
        return usdcBalance;
    }
}