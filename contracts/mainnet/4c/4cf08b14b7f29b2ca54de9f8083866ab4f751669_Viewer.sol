// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.7.6;
pragma abicoder v2;

import {MulDivMathLib} from "src/libraries/MulDivMathLib.sol";
import {IViewer} from "src/interfaces/IViewer.sol";
import {IFactory} from "src/interfaces/management/IFactory.sol";
import {IManager} from "src/interfaces/manager/IManager.sol";
import {IPriceHelper} from "src/interfaces/swap/IPriceHelper.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ICompounder} from "src/interfaces/rewards/ICompounder.sol";
import {IRewardTracker} from "src/interfaces/rewards/IRewardTracker.sol";
import {ISingleRewardTracker} from "src/interfaces/rewards/ISingleRewardTracker.sol";
import {SafeMath} from "@openzeppelin/math/SafeMath.sol";
import {UpgradeableGovernable} from "src/governance/UpgradeableGovernable.sol";

contract Viewer is IViewer, UpgradeableGovernable {
    using SafeMath for uint256;
    using MulDivMathLib for uint256;

    address[] public override factory;
    mapping(address => bool) public override isFactory;
    mapping(string => address) public factoryByStartegy;

    // Math Precision
    uint256 public constant PRECISION = 1e30;

    struct Vars {
        uint256 position0;
        uint256 position1;
        uint256 price0;
        uint256 price1;
        uint256 amount0;
        uint256 amount1;
        uint256 supply;
        uint256 assets;
        uint256 newAssets;
        uint256 length;
        IManager.Range[] ranges;
        uint128 liquidity;
        uint128 liquidityToRemove;
        uint256 amount0Received;
        uint256 amount1Received;
    }

    /**
     * @notice Initialize Viewer contract.
     */
    function initialize() external initializer {
        __Governable_init(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONTRACTS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get All Factories.
     */
    function getFactories() external view override returns (address[] memory) {
        address[] memory factories = factory;
        return factories;
    }

    /**
     * @notice Get Factory by strategy.
     */
    function getFactory(string memory _strategy) external view override returns (address) {
        return factoryByStartegy[_strategy];
    }

    /**
     * @notice Get LP Manager Contracts.
     * @param _factory Factory address.
     * @param _pool Token address.
     */
    function getContracts(address _factory, address _pool)
        external
        view
        override
        returns (IFactory.LPContracts memory)
    {
        return IFactory(_factory).getLPManagerContracts(_pool);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   PREVIEW                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get Preview Deposit.
     * @param _factory Factory address.
     * @param _pool Token address.
     * @param _amount0 amount of tokens.
     * @param _amount1 amount of tokens.
     * @param _compound amount of tokens.
     */
    function previewDeposit(address _factory, address _pool, uint256 _amount0, uint256 _amount1, bool _compound)
        external
        view
        override
        returns (uint256 position, uint256 shares)
    {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        Vars memory vars;

        (vars.position0, vars.position1) = IManager(lpContracts.lpManager).aumWithoutCollect();
        (vars.price0, vars.price1) = IPriceHelper(lpContracts.priceHelper).getPrices(_pool);

        if (_compound) {
            (vars.amount0, vars.amount1) = IRewardTracker(lpContracts.doubleTracker).claimable(lpContracts.compounder);
            (vars.amount0, vars.amount1) =
                ICompounder(lpContracts.compounder).previewCompoundRetention(vars.amount0, vars.amount1);

            vars.position0 = vars.position0.add(vars.amount0);
            vars.position1 = vars.position1.add(vars.amount1);

            vars.supply = ICompounder(lpContracts.compounder).totalSupply();
            vars.assets = ICompounder(lpContracts.compounder).totalAssets();

            if (vars.amount0 > 0 || vars.amount1 > 0) {
                // Add new assets
                vars.assets = vars.assets
                    + IRouter(lpContracts.router).previewPosition(
                        vars.price0, vars.price1, vars.amount0, vars.amount1, vars.position0, vars.position1
                    );
            }

            position = IRouter(lpContracts.router).previewPosition(
                vars.price0, vars.price1, _amount0, _amount1, vars.position0, vars.position1
            );
            shares = (vars.supply == 0) ? position : position.mulDivDown(vars.supply, vars.assets);
        } else {
            position = IRouter(lpContracts.router).previewPosition(
                vars.price0, vars.price1, _amount0, _amount1, vars.position0, vars.position1
            );
        }
    }

    /**
     * @notice Get Preview Withdraw.
     * @param _factory Factory address.
     * @param _pool pool address.
     * @param _position User position.
     * @param _compound amount of tokens.
     */
    function previewWithdraw(address _factory, address _pool, uint256 _position, bool _compound)
        external
        view
        override
        returns (uint256, uint256, uint256, uint256)
    {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        Vars memory vars;

        (vars.position0, vars.position1) = IManager(lpContracts.lpManager).aumWithoutCollect();

        (vars.price0, vars.price1) = IPriceHelper(lpContracts.priceHelper).getPrices(_pool);

        if (_compound) {
            (vars.amount0, vars.amount1) = IRewardTracker(lpContracts.doubleTracker).claimable(lpContracts.compounder);
            (vars.amount0, vars.amount1) =
                ICompounder(lpContracts.compounder).previewCompoundRetention(vars.amount0, vars.amount1);

            vars.supply = ICompounder(lpContracts.compounder).totalSupply();
            vars.assets = ICompounder(lpContracts.compounder).totalAssets();

            if (vars.amount0 > 0 || vars.amount1 > 0) {
                vars.newAssets = IRouter(lpContracts.router).previewPosition(
                    vars.price0, vars.price1, vars.amount0, vars.amount1, vars.position0, vars.position1
                );
                // Add new assets
                vars.assets = vars.assets + vars.newAssets;
            }

            _position = (vars.supply == 0) ? _position : _position.mulDivDown(vars.assets, vars.supply);
        }

        vars.supply = IManager(lpContracts.lpManager).totalSupply() + vars.newAssets;

        vars.amount0 = (vars.amount0 + IManager(lpContracts.lpManager).token0().balanceOf(lpContracts.lpManager))
            .mulDivDown(_position, vars.supply);
        vars.amount1 = (vars.amount1 + IManager(lpContracts.lpManager).token1().balanceOf(lpContracts.lpManager))
            .mulDivDown(_position, vars.supply);

        vars.ranges = IManager(lpContracts.lpManager).getRanges();

        vars.length = vars.ranges.length;

        for (uint256 i; i < vars.length;) {
            (vars.liquidity,,) =
                IManager(lpContracts.lpManager).lpPosition(vars.ranges[i].tickLower, vars.ranges[i].tickUpper);
            vars.liquidityToRemove = uint128(uint256(vars.liquidity).mulDivDown(_position, vars.supply));

            (vars.amount0Received, vars.amount1Received) = IPriceHelper(lpContracts.priceHelper).amountsForLiquidity(
                _pool, vars.ranges[i].tickLower, vars.ranges[i].tickUpper, vars.liquidityToRemove
            );

            vars.amount0 = vars.amount0.add(vars.amount0Received);
            vars.amount1 = vars.amount1.add(vars.amount1Received);

            ++i;
        }

        vars.amount0Received = vars.amount0;
        vars.amount1Received = vars.amount1;

        if (IManager(lpContracts.lpManager).chargeWithdrawalRate()) {
            if (IManager(lpContracts.lpManager).incentiveReceiver() != address(0)) {
                if (vars.amount0 > 0) {
                    vars.amount0Received = vars.amount0.sub(
                        vars.amount0.mulDivDown(IManager(lpContracts.lpManager).withdrawalRate(), PRECISION)
                    );
                }

                if (vars.amount1 > 0) {
                    vars.amount1Received = vars.amount1.sub(
                        vars.amount1.mulDivDown(IManager(lpContracts.lpManager).withdrawalRate(), PRECISION)
                    );
                }
            }
        }

        return (vars.amount0, vars.amount1, vars.amount0Received, vars.amount1Received);
    }

    /**
     * @notice Get pending Rewards.
     * @param _factory Factory address.
     * @param _pool pool address.
     * @param _user user address.
     * @param _rewardOption Type of reward.
     * @return amount0 amount of tokens 0.
     * @return amount1 amount of tokens 1.
     */
    function pendingRewards(address _factory, address _pool, address _user, uint8 _rewardOption)
        external
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        if (_rewardOption == 0) {
            (amount0, amount1) = IRewardTracker(lpContracts.doubleTracker).claimable(_user);
        } else if (_rewardOption == 1) {
            amount0 = ISingleRewardTracker(lpContracts.singleTrackerZero).claimable(_user);
        } else {
            amount1 = ISingleRewardTracker(lpContracts.singleTrackerOne).claimable(_user);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   AMOUNTS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the amounts needed in deposits of the given amount0.
     * @param _factory Factory address.
     * @param _pool Token address.
     * @param _amount0 The amount of token0
     * @return Amount of token0
     * @return Amount of token1
     */
    function amountsForAmount0(address _factory, address _pool, uint256 _amount0)
        external
        view
        override
        returns (uint256, uint256)
    {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        (int24 tickLower, int24 tickUpper) = IManager(lpContracts.lpManager).defaultRange();

        return IPriceHelper(lpContracts.priceHelper).amountsForAmount0(_pool, tickLower, tickUpper, _amount0);
    }

    /**
     * @notice Get the amounts needed in deposits of the given amount1.
     * @param _factory Factory address.
     * @param _pool Token address.
     * @param _amount1 The amount of token1
     * @return Amount of token0
     * @return Amount of token1
     */
    function amountsForAmount1(address _factory, address _pool, uint256 _amount1)
        external
        view
        override
        returns (uint256, uint256)
    {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        (int24 tickLower, int24 tickUpper) = IManager(lpContracts.lpManager).defaultRange();

        return IPriceHelper(lpContracts.priceHelper).amountsForAmount1(_pool, tickLower, tickUpper, _amount1);
    }

    /**
     * @notice Get the amounts of the given numbers of liquidity tokens
     * @param _factory Factory address.
     * @param pool Algebra liquidity pool contract
     * @param tickLower The lower tick of the position
     * @param tickUpper The upper tick of the position
     * @param liquidity The amount of liquidity tokens
     * @return Amount of token0 and token1
     */
    function amountsForLiquidity(address _factory, address pool, int24 tickLower, int24 tickUpper, uint128 liquidity)
        external
        view
        override
        returns (uint256, uint256)
    {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(pool);
        require(lpContracts.lp == pool, "LP Manager Not Found");

        return IPriceHelper(lpContracts.priceHelper).amountsForLiquidity(pool, tickLower, tickUpper, liquidity);
    }

    /**
     * @notice Get the liquidity amount of the given numbers of token0 and token1
     * @param _factory Factory address.
     * @param pool Algebra liquidity pool contract
     * @param tickLower The lower tick of the position
     * @param tickUpper The upper tick of the position
     * @param amount0 The amount of token0
     * @param amount1 The amount of token1
     * @return Amount of liquidity tokens
     */
    function liquidityForAmounts(
        address _factory,
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external view override returns (uint128) {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(pool);
        require(lpContracts.lp == pool, "LP Manager Not Found");

        return IPriceHelper(lpContracts.priceHelper).liquidityForAmounts(pool, tickLower, tickUpper, amount0, amount1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   TVL                                      */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Return TVL; 18 decimals.
     * @param _factory Factory address.
     * @param _pool Token address.
     * @return Total USD Value of AUM(ASSETS UNDER MANAGEMENT); 18 decimals.
     */
    function TVL(address _factory, address _pool) external view override returns (uint256) {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        (uint256 position0, uint256 position1) = IManager(lpContracts.lpManager).aumWithoutCollect();
        (uint256 price0, uint256 price1) = IPriceHelper(lpContracts.priceHelper).getPrices(_pool);

        position0 = IPriceHelper(lpContracts.priceHelper).normalise(
            address(IManager(lpContracts.lpManager).token0()), position0
        );
        position1 = IPriceHelper(lpContracts.priceHelper).normalise(
            address(IManager(lpContracts.lpManager).token1()), position1
        );

        return price0.mul(position0).add(price1.mul(position1)).div(1e18);
    }

    /**
     * @notice Assets Under Management; 18 decimals.
     * @param _factory Factory address.
     * @param _pool Token address.
     * @return amount0 amount under management of token0.
     * @return amount1 amount under management of token1.
     */
    function AUM(address _factory, address _pool) external view override returns (uint256 amount0, uint256 amount1) {
        IFactory.LPContracts memory lpContracts = IFactory(_factory).getLPManagerContracts(_pool);
        require(lpContracts.lp == _pool, "LP Manager Not Found");

        (amount0, amount1) = IManager(lpContracts.lpManager).aumWithoutCollect();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GOVERNOR                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Update Factory address.
     * @param _factory new factory.
     */
    function addFactory(address _factory) external override onlyGovernor {
        if (!isFactory[_factory]) {
            factory.push(_factory);
            isFactory[_factory] = true;
            factoryByStartegy[IFactory(_factory).strategy()] = _factory;
        }
    }

    /**
     * @notice Remove Factory address.
     * @param _index index of factory.
     */
    function removeFactory(uint256 _index) external override onlyGovernor {
        address[] storage _factories = factory;

        uint256 length = _factories.length;
        require(length > 0, "No Factories");

        uint256 lastElement = length.sub(1);

        isFactory[_factories[_index]] = false;
        factoryByStartegy[IFactory(_factories[_index]).strategy()] = address(0);

        if (length != 1 && (lastElement != _index)) {
            _factories[_index] = _factories[lastElement];
        }
        _factories.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library MulDivMathLib {
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) { revert(0, 0) }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) { revert(0, 0) }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IFactory} from "src/interfaces/management/IFactory.sol";

interface IViewer {
    function factory(uint256 _index) external view returns (address);
    function getFactory(string memory _strategy) external view returns (address);
    function getFactories() external view returns (address[] memory);
    function isFactory(address _factory) external view returns (bool);

    function getContracts(address _factory, address _pool) external view returns (IFactory.LPContracts memory);

    function previewDeposit(address _factory, address _pool, uint256 _amount0, uint256 _amount1, bool _compound)
        external
        view
        returns (uint256 position, uint256 shares);

    function previewWithdraw(address _factory, address _pool, uint256 _position, bool _compound)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 amount0AfterRetention, uint256 amount1AfterRetention);

    function pendingRewards(address _factory, address _pool, address _user, uint8 _rewardOption)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function amountsForAmount0(address _factory, address _pool, uint256 _amount0)
        external
        view
        returns (uint256, uint256);

    function amountsForAmount1(address _factory, address _pool, uint256 _amount1)
        external
        view
        returns (uint256, uint256);

    function amountsForLiquidity(address _factory, address _pool, int24 tickLower, int24 tickUpper, uint128 liquidity)
        external
        view
        returns (uint256, uint256);

    function liquidityForAmounts(
        address _factory,
        address _pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint128);

    function TVL(address _factory, address _pool) external view returns (uint256);

    function AUM(address _factory, address _pool) external view returns (uint256 amount0, uint256 amount1);

    function addFactory(address _factory) external;
    function removeFactory(uint256 _index) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IPriceHelper} from "src/interfaces/swap/IPriceHelper.sol";

interface IFactory {
    enum Stage {
        NON_CREATED,
        CREATED,
        OBSOLETE
    }

    struct InitParams {
        address creator;
        address viewer;
        address swapper;
        address rewardReceiver;
        address merkleDistributor;
        address keeper;
    }

    struct LPContracts {
        address lp;
        address viewer;
        address swapper;
        address receiver;
        address priceHelper;
        address lpManager;
        address doubleTracker;
        address singleTrackerZero;
        address singleTrackerOne;
        address compounder;
        address router;
    }

    struct CreateParams {
        address _pool;
        uint256 _type;
        bytes _paths;
        uint8 _routes;
        string _positionName;
        string _positionSymbol;
        string _compoundName;
        string _compoundSymbol;
        int24 _defaultLower;
        int24 _defaultUpper;
    }

    function strategy() external view returns (string calldata);

    // External
    function create(CreateParams memory createParams, IPriceHelper.PoolInput memory poolInput)
        external
        returns (uint256 nonce, LPContracts memory contracts);

    // View
    function getLPManagerContracts(uint256 _nonce) external view returns (LPContracts memory);
    function getLPManagerContracts(address _pool) external view returns (LPContracts memory);

    // Only Gov
    function changeStage(address underlyingAddress, Stage _stage) external;
    function updateLPGov(address _lpGov) external;
    function updateInternalContracts(InitParams memory init) external;
    function updateKeeper(address _keeper) external;
    function updateIncentiveReceiver(address _incentiveReceiver) external;
    function updateRetentionIncentives(uint256 _mantentionRate, uint256 _withdrawRate, uint256 _compoundRate)
        external;
    function updateContractsByType(uint256 _type, address _priceHelper, address _lpManager, address _swapper)
        external;
    function updateLPManagerContracts(LPContracts memory contracts) external;
    function pressToggle() external;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Toggle(bool toggle);
    event LPManagerCreated(uint256 nonce, address indexed lp, Stage stage, LPContracts);
    event UpdateStage(address indexed lp, Stage oldStage, Stage newStage);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {IERC20Upgradeable} from "@openzeppelin-upgrades/token/ERC20/IERC20Upgradeable.sol";

interface IManager is IERC20Upgradeable {
    //Concentarte liquidity range
    struct Range {
        int24 tickLower;
        int24 tickUpper;
    }

    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    struct NewRange {
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0;
        uint256 amount1;
    }

    struct ExistingRange {
        uint256 index;
        bool burn;
        bool remove;
        uint256 amount0;
        uint256 amount1;
    }

    function aumWithoutCollect() external view returns (uint256 amount0, uint256 amount1);

    function aum() external returns (uint256 amount0, uint256 amount1);

    function getRanges() external view returns (Range[] memory);

    function mintLiquidity(address _user, uint256 _index, uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 amount0, uint256 amount1);

    function redeemLiquidity(uint256 _position, address _receiver)
        external
        returns (uint256 amount0, uint256 amount1, uint256 amount0AfterRetention, uint256 amount1AfterRetention);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;

    function transferAssets(address from, uint256 amount0, uint256 amount1) external;

    function defaultRange() external view returns (int24, int24);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function getPool() external view returns (address);

    function burnLiquidity(uint128 _liquidity, uint256 _index, bool _notional)
        external
        returns (uint256 amount0, uint256 amount1);

    function rebalance(Swap memory _swap, ExistingRange[] calldata _existingRanges, NewRange[] calldata _newRange)
        external;

    function lpPosition(int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint128 liquidity, uint128 rewards0, uint128 rewards1);

    function swapDefaultRange(uint256 _index) external;

    function toggleWithdrawalRate() external;

    function emergencyTransfer(address _to, address _asset) external;

    function setIncentives(address _incentiveReceiver, uint256 _yieldRate, uint256 _withdrawalRate) external;

    function withdrawalRate() external view returns (uint256);
    function chargeWithdrawalRate() external view returns (bool);
    function incentiveReceiver() external view returns (address);

    event Rewards(uint256 rewards0, uint256 rewards1);
    event RewardsPerRange(Range indexed, uint256 rewards0, uint256 rewards1);
    event Position(uint256 amount0, uint256 amount1);
    event Retention(
        address indexed receiver,
        uint256 amount0AfterRetention,
        uint256 amount1AfterRetention,
        uint256 retention0,
        uint256 retention1,
        string typeOf
    );
    event ExistingRangesRebalance(ExistingRange[]);
    event NewRangesRebalance(NewRange[]);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IAggregatorV3} from "src/interfaces/swap/IAggregatorV3.sol";

interface IPriceHelper {
    // Pool Data needed for get safe price
    struct PoolData {
        IAggregatorV3 feed;
        address referenceToken;
        int24 secondsAgo;
        uint256 threshold;
        uint256 stalePeriod;
    }
    // 1e30 100%

    struct PoolInput {
        address referenceToken;
        int24 secondsAgo;
        uint256 threshold;
        uint256 stalePeriod;
    }

    function normalise(address _token, uint256 _amount) external view returns (uint256 normalised);
    function getPrices(address pool) external view returns (uint256 price0, uint256 price1);
    function checkManipulation(address pool) external view returns (uint256 spot);
    function updatePoolData(address pool, PoolInput calldata _input) external;

    function amountsForLiquidity(address pool, int24 tickLower, int24 tickUpper, uint128 liquidity)
        external
        view
        returns (uint256, uint256);
    function liquidityForAmounts(address pool, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1)
        external
        view
        returns (uint128);
    function amountsForAmount0(address pool, int24 tickLower, int24 tickUpper, uint256 amount0)
        external
        view
        returns (uint256, uint256);
    function amountsForAmount1(address pool, int24 tickLower, int24 tickUpper, uint256 amount1)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IPriceHelper} from "src/interfaces/swap/IPriceHelper.sol";

interface IRouter {
    /**
     * @notice Deposit Input Params
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _amount0Min Minimum amount of token0 to be minted
     * @param _amount1Min Minimum amount of token1 to be minted
     * @param _minPosition Minimum amount of position to be received to the user
     * @param _minShares Minimum amount of shares to be received to the user
     * @param _receiver Who will receive the shares
     * @param _compound True if user choose autocompounding shares.
     * @param _rewardOption Type of reward.
     *
     */
    struct DepositInput {
        uint256 amount0;
        uint256 amount1;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 minPosition;
        uint256 minShares;
        address receiver;
        bool compound;
        uint8 rewardOption;
    }

    // stage:
    // 1 -> creted;
    // 2 -> executed;
    // 3 -> removed
    struct ExitOrder {
        address receiver;
        uint256 blockNumber;
        uint256 amount;
        uint256 price;
        bool compound;
        uint8 rewardOption;
        uint256 stage;
    }

    struct ExecuteOrder {
        address user;
        uint256[] blockNumbers;
        uint256[] minAmount0;
        uint256[] minAmount1;
    }

    function price() external returns (IPriceHelper);

    function deposit(DepositInput calldata _deposit)
        external
        returns (uint256, /*amount0*/ uint256, /*amount1*/ uint256, /*position*/ uint256); /*shares*/

    function withdraw(
        uint256 _position,
        address _receiver,
        uint256 _amount0Min,
        uint256 _amount1Min,
        bool _compound,
        uint8 _rewardOption
    ) external returns (uint256 amount0, uint256 amount1);

    function compoundDeposit(uint256 _amount0, uint256 _amount1) external;

    function claim(address _receiver, uint8 _rewardOption) external returns (uint256, uint256);

    function previewPosition(
        uint256 price0,
        uint256 price1,
        uint256 amountIn0,
        uint256 amountIn1,
        uint256 position0,
        uint256 position1
    ) external view returns (uint256);

    event Deposit(
        address indexed caller,
        address indexed receiver,
        uint256 amount0,
        uint256 amount1,
        uint256 position,
        uint256 shares,
        uint8 rewardOption
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        uint256 shares,
        uint256 position,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0AfterRetention,
        uint256 amount1AfterRetention,
        uint8 rewardOption
    );
    event CompoundDeposit(address indexed caller, uint256 amount0, uint256 amount1, uint256 position);
    event Claim(address indexed caller, uint256 rewards0, uint256 rewards1, address indexed target, uint8 rewardOption);
    event Compound(address indexed caller, uint256 amount, uint256 shares, uint8 _rewardOption);
    event UnCompound(address indexed caller, uint256 shares, uint256 position, uint8 _rewardOption);
    event NewExitOrder(address indexed user, ExitOrder order);
    event OrderExecuted(
        address indexed user,
        uint256 blockNumber,
        uint256 price0,
        uint256 position,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event UpdateOrder(address indexed user, uint256 blockNumber, ExitOrder order);

    event OrderRemoved(address indexed user, ExitOrder order);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICompounder {
    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    function keeperSwap(Swap calldata _swap) external;

    function compound() external;
    function deposit(uint256 _assets, address _receiver) external returns (uint256);
    function redeem(uint256 _shares, address _receiver) external returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewCompoundRetention(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint256 amount0AfterRetention, uint256 amount1AfterRetention);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Compound(uint256 amount0, uint256 amount1, uint256 totalAssets);
    event Deposit(address caller, address receiver, uint256 assets, uint256 shares);
    event Withdraw(address caller, address receiver, uint256, uint256 shares);
    event Retention(
        address indexed receiver,
        uint256 amount0AfterRetention,
        uint256 amount1AfterRetention,
        uint256 retention0,
        uint256 retention1,
        string typeOf
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IRewardTracker {
    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    /**
     * @notice Stake into this contract assets to start earning rewards
     * @param _account Owner of the stake and future rewards
     * @param _amount Assets to be staked
     * @return Amount of assets staked
     */
    function stake(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Withdraw the staked assets
     * @param _account Owner of the assets to be withdrawn
     * @param _amount Assets to be withdrawn
     * @return Amount of assets witdrawed
     */
    function withdraw(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Claim _account cumulative rewards
     * @dev Reward token will be transfer to the _account
     * @param _account Owner of the rewards
     * @return Amount of reward tokens0 transferred
     * @return Amount of reward tokens1 transferred
     */
    function claim(address _account) external returns (uint256, uint256);

    /**
     * @notice Return _account claimable rewards
     * @dev No reward token are transferred
     * @param _account Owner of the rewards
     * @return Amount of reward tokens that can be claim
     */
    function claimable(address _account) external view returns (uint256, uint256);

    /**
     * @notice Return _account staked amount
     * @param _account Owner of the staking
     * @return Staked amount
     */
    function stakedAmount(address _account) external view returns (uint256);

    /**
     * @notice Update global cumulative reward
     * @dev No reward token are transferred
     */
    function updateRewards() external;

    /**
     * @notice Deposit rewards
     * @dev Transfer from called here
     * @param _rewards0 Amount of reward asset0 transferer
     * @param _rewards1 Amount of reward asset1 transferer
     */
    function depositRewards(uint256 _rewards0, uint256 _rewards1) external;

    /**
     * @notice Swap and Process rewards
     * @param _swap Swap data array.
     */
    function swapAndProcess(Swap[] calldata _swap) external;

    event Stake(address indexed depositor, uint256 amount);
    event Withdraw(address indexed _account, uint256 _amount);
    event Claim0(address indexed receiver, uint256 amount);
    event Claim1(address indexed receiver, uint256 amount);
    event MerkleClaim(address[] users, address[] tokens, uint256[] amounts);
    event UpdateRewards0(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);
    event UpdateRewards1(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ISingleRewardTracker {
    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    /**
     * @notice Stake into this contract assets to start earning rewards
     * @param _account Owner of the stake and future rewards
     * @param _amount Assets to be staked
     * @return Amount of assets staked
     */
    function stake(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Withdraw the staked assets
     * @param _account Owner of the assets to be withdrawn
     * @param _amount Assets to be withdrawn
     * @return Amount of assets witdrawed
     */
    function withdraw(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Claim _account cumulative rewards
     * @dev Reward token will be transfer to the _account
     * @param _account Owner of the rewards
     * @return Amount of reward transferred
     */
    function claim(address _account) external returns (uint256);

    /**
     * @notice Return _account claimable rewards
     * @dev No reward token are transferred
     * @param _account Owner of the rewards
     * @return Amount of reward tokens that can be claim
     */
    function claimable(address _account) external view returns (uint256);

    /**
     * @notice Return _account staked amount
     * @param _account Owner of the staking
     * @return Staked amount
     */
    function stakedAmount(address _account) external view returns (uint256);

    /**
     * @notice Update global cumulative reward
     * @dev No reward token are transferred
     */
    function updateRewards() external;

    /**
     * @notice Deposit rewards
     * @dev Transfer from called here
     * @param _rewards Amount of reward asset transfered
     */
    function depositRewards(uint256 _rewards) external;

    /**
     * @notice Swap and Process rewards
     * @param _swap Swap data array.
     */
    function swapAndProcess(Swap[] calldata _swap) external;

    event Stake(address indexed depositor, uint256 amount);
    event Withdraw(address indexed _account, uint256 _amount);
    event Claim(address indexed receiver, uint256 amount);
    event MerkleClaim(address[] users, address[] tokens, uint256[] amounts);
    event UpdateRewards(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.7.6;
pragma abicoder v2;

import {AccessControlUpgradeable} from "@openzeppelin-upgrades/access/AccessControlUpgradeable.sol";

abstract contract UpgradeableGovernable is AccessControlUpgradeable {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    /**
     * @notice Keeper role
     */
    bytes32 public constant KEEPER = bytes32("KEEPER");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal initializer {
        __AccessControl_init();
        _setupRole(GOVERNOR, _governor);

        _setRoleAdmin(GOVERNOR, GOVERNOR);
        _setRoleAdmin(OPERATOR, GOVERNOR);
        _setRoleAdmin(KEEPER, GOVERNOR);
    }

    /**
     * @notice Modifier if msg.sender has not Governor role revert.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @notice Update Governor Role
     */
    function updateGovernor(address _newGovernor) external virtual onlyGovernor {
        renounceRole(GOVERNOR, msg.sender);
        _setupRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        require(hasRole(GOVERNOR, msg.sender), "Caller Not Gov");
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}