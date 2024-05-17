// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.0;

interface ITokenToUsdcOracle {
    function usdcAmount(uint256 tokenAmount) external view returns (uint256 usdcAmount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISiloIncentivesController {
    function getRewardsBalance(
        address[] calldata _assets,
        address _user
    ) external view returns (uint256);

    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISiloLens {
    function collateralBalanceOfUnderlying(
        address _silo,
        address _asset,
        address _user
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/ISiloLens.sol";
import "./interfaces/ISiloIncentivesController.sol";
import "../interfaces/ITokenToUsdcOracle.sol";
import "../interfaces/IUniversalOracle.sol";

contract SiloStrategyV2 {
    ISiloLens public siloLens;
    ISiloIncentivesController private siloIncentivesController;
    IUniversalOracle public universalOracle;

    address public silo;
    address public collateralAsset;
    address public usdc;
    address public siloAsset;
    address public rewardsToken;

    constructor(
        address _siloLens, /// @notice SiloLens contract address
        address _siloIncentivesController, /// @notice SiloIncentivesController contract address
        address _universalOracle, /// @notice Oracle contract address SILO/USDC
        address _silo, /// @notice Silo contract address
        address _usdc, /// @notice Collateral asset address (USDC)
        address _collateralAsset, /// @notice Collateral asset address
        address _siloAsset /// @notice Silo asset address
    ) {
        siloLens = ISiloLens(_siloLens);
        siloIncentivesController = ISiloIncentivesController(
            _siloIncentivesController
        );
        universalOracle = IUniversalOracle(_universalOracle);

        silo = _silo;
        usdc = _usdc;
        siloAsset = _siloAsset;
        collateralAsset = _collateralAsset;
        rewardsToken = ISiloIncentivesController(_siloIncentivesController)
            .REWARD_TOKEN();
    }

    function getBalance(address strategist) external view returns (uint256) {
        uint256 collateralAssetBalance = siloLens.collateralBalanceOfUnderlying(
            silo,
            collateralAsset,
            strategist
        );

        address[] memory assets = new address[](1);
        assets[0] = siloAsset;
        uint256 collateralAssetInUsdc = collateralAsset == usdc
            ? collateralAssetBalance
            : universalOracle.getValue(
                collateralAsset,
                collateralAssetBalance,
                usdc
            );
        uint256 rewardsInSilo = siloIncentivesController.getRewardsBalance(
            assets,
            strategist
        );
        if (rewardsInSilo == 0) return collateralAssetInUsdc;

        collateralAssetInUsdc += universalOracle.getValue(
            rewardsToken,
            rewardsInSilo,
            usdc
        );

        return collateralAssetInUsdc;
    }
}