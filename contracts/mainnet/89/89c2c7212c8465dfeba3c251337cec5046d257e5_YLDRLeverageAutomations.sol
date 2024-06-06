pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IYLDROracle} from "@yldr-lending/core/src/interfaces/IYLDROracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPoolAddressesProvider} from "@yldr-lending/core/src/interfaces/IPoolAddressesProvider.sol";
import {ERC1155CLWrapper} from "@yldr-lending/core/src/protocol/concentrated-liquidity/ERC1155CLWrapper.sol";
import {IAssetConverter} from "../AssetConverter.sol";
import {
    CLLeveragedPosition, BaseCLAdapter, IERC3156FlashBorrower, IERC3156FlashLender
} from "./CLLeveragedPosition.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract YLDRLeverageAutomations is OwnableUpgradeable {
    address public immutable operator;
    uint256 public immutable rebalanceFee;
    uint256 public immutable deleverageFee;
    uint256 public immutable maxSwapSlippage;
    IAssetConverter public immutable assetConverter;
    IPoolAddressesProvider public immutable addressesProvider;
    mapping(IERC3156FlashLender => bool whitelisted) whitelistedFlashloanProviders;

    event NewCompound(address position);
    event CanceledCompound(address position);
    event NewRebalance(address position);
    event CanceledRebalance(address position);
    event NewDeleverage(address position);
    event CanceledDeleverage(address position);

    constructor(
        uint256 _rebalanceFee,
        uint256 _deleverageFee,
        uint256 _maxSwapSlippage,
        IAssetConverter _assetConverter,
        IPoolAddressesProvider _addressesProvider
    ) {
        rebalanceFee = _rebalanceFee;
        maxSwapSlippage = _maxSwapSlippage;
        deleverageFee = _deleverageFee;
        addressesProvider = _addressesProvider;
        assetConverter = _assetConverter;
        operator = msg.sender;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    enum RangeConfigType {
        TICKS,
        PRICE,
        RANGE
    }

    struct RangeConfig {
        RangeConfigType rangeConfigType;
        // For TICKS, ticksDown and ticksUp to count from new position opening tick.
        int24 ticksDown;
        int24 ticksUp;
        // For PRICE sqrtPriceX96Down and sqrtPriceX96Up to count from new position opening price.
        uint160 sqrtPriceX96Down;
        uint160 sqrtPriceX96Up;
    }

    enum EndTriggerType {
        COUNT,
        TIMESTAMP
    }

    struct EndConfig {
        EndTriggerType triggerType;
        uint256 count;
        uint256 timestamp;
    }

    struct RecurringRebalanceConfig {
        RangeConfig rangeConfig;
        EndConfig endConfig;
        bool active;
    }

    struct ScheduledRebalance {
        bool initialized;
        // Trigger ticks for the next rebalance
        int24 triggerLower;
        int24 triggerUpper;
        // Ticks to count down and up when opening new position
        int24 newTicksDown;
        int24 newTicksUp;
        RecurringRebalanceConfig recurring;
        GasFeeConfig gasFeeConfig;
    }

    struct ScheduledCompound {
        bool initialized;
        // Max percent of flashloan fee + gas fee relative to position fees value
        uint256 maxTotalFeePercent;
    }

    struct ScheduledDeleverage {
        bool initialized;
        int24 triggerLower;
        int24 triggerUpper;
        bool withdrawLiquidity;
        GasFeeConfig gasFeeConfig;
    }

    struct GasFeeConfig {
        uint256 maxUsd;
        uint256 maxPositionPercent;
    }

    mapping(address => ScheduledRebalance) public scheduledRebalances;
    mapping(address => ScheduledDeleverage) public scheduledDeleverages;
    mapping(address => ScheduledCompound) public scheduledCompounds;

    function whitelistFlashloanProviders(IERC3156FlashLender[] memory providers) public {
        _checkOwner();

        for (uint256 i = 0; i < providers.length; i++) {
            whitelistedFlashloanProviders[providers[i]] = true;
        }
    }

    function _checkOperator() internal view {
        require(msg.sender == operator, "Only operator can call this function");
    }

    function _checkPositionOwner(address position) internal view {
        require(CLLeveragedPosition(position).owner() == msg.sender, "Only owner can setup rebalance");
    }

    function _checkWhitelistedFlashloanProvider(IERC3156FlashLender provider) internal view {
        require(whitelistedFlashloanProviders[provider], "Flashloan provider not whitelisted");
    }

    function setupRebalance(
        address position,
        int24 triggerLower,
        int24 triggerUpper,
        int24 newTicksDown,
        int24 newTicksUp,
        RecurringRebalanceConfig memory recurring,
        GasFeeConfig memory gasFeeConfig
    ) public {
        _checkPositionOwner(position);

        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);
        address pool = adapter.getPool(data);
        (, int24 currentTick) = adapter.getPoolState(pool);

        require((triggerLower < currentTick) && (triggerUpper > currentTick), "Invalid tick range");

        scheduledRebalances[position] = ScheduledRebalance({
            triggerLower: triggerLower,
            triggerUpper: triggerUpper,
            newTicksDown: newTicksDown,
            newTicksUp: newTicksUp,
            initialized: true,
            recurring: recurring,
            gasFeeConfig: gasFeeConfig
        });

        emit NewRebalance(position);
    }

    function cancelRebalance(address position) public {
        _checkPositionOwner(position);
        delete scheduledRebalances[position];

        emit CanceledRebalance(position);
    }

    function _canRebalance(ScheduledRebalance memory scheduledRebalance, int24 currentTick)
        internal
        pure
        returns (bool)
    {
        if (!scheduledRebalance.initialized) {
            return false;
        }
        return (scheduledRebalance.triggerLower >= currentTick) || (scheduledRebalance.triggerUpper <= currentTick);
    }

    function canRebalance(address position) public view returns (bool) {
        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);
        address pool = adapter.getPool(data);
        (, int24 currentTick) = adapter.getPoolState(pool);

        return _canRebalance(scheduledRebalances[position], currentTick);
    }

    function _getNextRebalanceTriggers(
        RecurringRebalanceConfig memory recurring,
        int24 currentTick,
        int24 newTickLower,
        int24 newTickUpper
    ) internal view returns (bool ended, int24 triggerLower, int24 triggerUpper) {
        if (!recurring.active) {
            return (true, 0, 0);
        }

        if (recurring.endConfig.triggerType == EndTriggerType.COUNT) {
            recurring.endConfig.count -= 1;
            if (recurring.endConfig.count == 0) {
                return (true, 0, 0);
            }
        } else if (recurring.endConfig.triggerType == EndTriggerType.TIMESTAMP) {
            if (block.timestamp >= recurring.endConfig.timestamp) {
                return (true, 0, 0);
            }
        }

        if (recurring.rangeConfig.rangeConfigType == RangeConfigType.TICKS) {
            return (false, currentTick - recurring.rangeConfig.ticksDown, currentTick + recurring.rangeConfig.ticksUp);
        } else if (recurring.rangeConfig.rangeConfigType == RangeConfigType.PRICE) {
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);
            uint160 sqrtPriceX96Down = (
                recurring.rangeConfig.sqrtPriceX96Down <= (sqrtPriceX96 - TickMath.MIN_SQRT_RATIO)
            ) ? sqrtPriceX96 - recurring.rangeConfig.sqrtPriceX96Down : TickMath.MIN_SQRT_RATIO;
            uint160 sqrtPriceX96Up = (recurring.rangeConfig.sqrtPriceX96Up <= (TickMath.MAX_SQRT_RATIO - sqrtPriceX96))
                ? sqrtPriceX96 + recurring.rangeConfig.sqrtPriceX96Up
                : TickMath.MAX_SQRT_RATIO;

            return (false, TickMath.getTickAtSqrtRatio(sqrtPriceX96Down), TickMath.getTickAtSqrtRatio(sqrtPriceX96Up));
        } else if (recurring.rangeConfig.rangeConfigType == RangeConfigType.RANGE) {
            return (false, newTickLower, newTickUpper);
        }

        return (true, 0, 0);
    }

    function executeRebalance(address position, IERC3156FlashLender flashloanProvider, uint256 usdGasFee) public {
        _checkOperator();
        _checkWhitelistedFlashloanProvider(flashloanProvider);
        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);
        ScheduledRebalance memory scheduledRebalance = scheduledRebalances[position];

        int24 newTickLower;
        int24 newTickUpper;
        int24 currentTick;
        {
            address pool = adapter.getPool(data);
            (, currentTick) = adapter.getPoolState(pool);

            int24 tickSpacing = adapter.getTickSpacing(pool);

            newTickLower = currentTick - scheduledRebalance.newTicksDown;
            newTickUpper = currentTick + scheduledRebalance.newTicksUp;

            newTickLower -= (tickSpacing + newTickLower % tickSpacing) % tickSpacing;
            newTickUpper += (tickSpacing - newTickUpper % tickSpacing) % tickSpacing;
        }

        require(_canRebalance(scheduledRebalance, currentTick), "Rebalance not allowed");
        uint256 fee = _calculateAndValidateFee({
            position: position,
            adapter: adapter,
            positionData: data,
            config: scheduledRebalance.gasFeeConfig,
            usdGasFee: usdGasFee,
            percentFee: rebalanceFee
        });

        CLLeveragedPosition(position).rebalanceAutomation(
            flashloanProvider,
            CLLeveragedPosition.RebalanceParams({
                assetConverter: assetConverter,
                maxSwapSlippage: maxSwapSlippage,
                newTickLower: newTickLower,
                newTickUpper: newTickUpper
            }),
            fee
        );

        (bool shouldDelete, int24 nextTriggerLower, int24 nextTriggerUpper) =
            _getNextRebalanceTriggers(scheduledRebalance.recurring, currentTick, newTickLower, newTickUpper);

        if (shouldDelete) {
            delete scheduledRebalances[position];
        } else {
            scheduledRebalances[position].triggerLower = nextTriggerLower;
            scheduledRebalances[position].triggerUpper = nextTriggerUpper;
            // update as we might alter counter in _getNextRebalanceTriggers
            scheduledRebalances[position].recurring = scheduledRebalance.recurring;
        }
    }

    function setupDeleverage(
        address position,
        int24 triggerLower,
        int24 triggerUpper,
        bool withdrawLiquidity,
        GasFeeConfig memory gasFeeConfig
    ) public {
        _checkPositionOwner(position);

        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);
        address pool = adapter.getPool(data);
        (, int24 currentTick) = adapter.getPoolState(pool);
        require((triggerLower < currentTick) && (triggerUpper > currentTick), "Invalid tick range");

        scheduledDeleverages[position] = ScheduledDeleverage({
            triggerLower: triggerLower,
            triggerUpper: triggerUpper,
            withdrawLiquidity: withdrawLiquidity,
            initialized: true,
            gasFeeConfig: gasFeeConfig
        });

        emit NewDeleverage(position);
    }

    function cancelDeleverage(address position) public {
        _checkPositionOwner(position);
        delete scheduledDeleverages[position];

        emit CanceledDeleverage(position);
    }

    function _canDeleverage(ScheduledDeleverage memory scheduledDeleverage, int24 currentTick)
        internal
        pure
        returns (bool)
    {
        if (!scheduledDeleverage.initialized) {
            return false;
        }
        return (scheduledDeleverage.triggerLower >= currentTick) || (scheduledDeleverage.triggerUpper <= currentTick);
    }

    function canDeleverage(address position) external view returns (bool) {
        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);
        address pool = adapter.getPool(data);
        (, int24 currentTick) = adapter.getPoolState(pool);

        return _canDeleverage(scheduledDeleverages[position], currentTick);
    }

    function executeDeleverage(address position, IERC3156FlashLender flashloanProvider, uint256 usdGasFee) public {
        _checkOperator();
        _checkWhitelistedFlashloanProvider(flashloanProvider);
        ScheduledDeleverage memory scheduledDeleverage = scheduledDeleverages[position];

        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);
        address pool = adapter.getPool(data);
        (, int24 currentTick) = adapter.getPoolState(pool);
        require(_canDeleverage(scheduledDeleverage, currentTick), "Deleverage not allowed");

        uint256 fee = _calculateAndValidateFee({
            position: position,
            adapter: adapter,
            positionData: data,
            config: scheduledDeleverage.gasFeeConfig,
            usdGasFee: usdGasFee,
            percentFee: deleverageFee
        });

        CLLeveragedPosition(position).deleverageAutomation(
            flashloanProvider,
            CLLeveragedPosition.DeleverageParams({
                assetConverter: assetConverter,
                maxSwapSlippage: maxSwapSlippage,
                receiver: CLLeveragedPosition(position).owner(),
                withdrawLiquidity: scheduledDeleverage.withdrawLiquidity
            }),
            fee
        );

        delete scheduledDeleverages[position];
    }

    function setupCompound(address position, uint256 maxTotalFeePercent) public {
        _checkPositionOwner(position);
        scheduledCompounds[position] = ScheduledCompound({initialized: true, maxTotalFeePercent: maxTotalFeePercent});

        emit NewCompound(position);
    }

    function cancelCompound(address position) public {
        _checkPositionOwner(position);
        delete scheduledCompounds[position];

        emit CanceledCompound(position);
    }

    function canCompound(address position, IERC3156FlashLender flashloanProvider, uint256 usdGasFee)
        public
        view
        returns (bool)
    {
        ScheduledCompound memory scheduledCompound = scheduledCompounds[position];
        if (!scheduledCompound.initialized) {
            return false;
        }
        (, uint256 percent) = _calculateCompoundFeeAndPercent(position, flashloanProvider, usdGasFee);
        return percent <= scheduledCompound.maxTotalFeePercent;
    }

    function executeCompound(address position, IERC3156FlashLender flashloanProvider, uint256 usdGasFee) public {
        _checkOperator();
        _checkWhitelistedFlashloanProvider(flashloanProvider);
        ScheduledCompound memory scheduledCompound = scheduledCompounds[position];

        require(scheduledCompound.initialized, "Compound not allowed");

        (uint256 fee, uint256 percent) = _calculateCompoundFeeAndPercent(position, flashloanProvider, usdGasFee);

        require(percent <= scheduledCompounds[position].maxTotalFeePercent, "Fee too high");

        CLLeveragedPosition(position).compoundAutomation(
            flashloanProvider,
            CLLeveragedPosition.CompoundParams({assetConverter: assetConverter, maxSwapSlippage: maxSwapSlippage}),
            fee
        );
    }

    function _calculateCompoundFeeAndPercent(address position, IERC3156FlashLender flashLoanProvider, uint256 usdGasFee)
        internal
        view
        returns (uint256 gasFee, uint256 percent)
    {
        IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());

        address debtToken = CLLeveragedPosition(position).borrowedToken();

        (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory data) = _getPositionCLAdapterAndData(position);

        uint256 pendingFeesUsd;
        {
            (uint256 fee0, uint256 fee1) = adapter.getPendingFees(data);
            uint256 fee0Usd = fee0 * oracle.getAssetPrice(data.token0) / 10 ** IERC20Metadata(data.token0).decimals();
            uint256 fee1Usd = fee1 * oracle.getAssetPrice(data.token1) / 10 ** IERC20Metadata(data.token1).decimals();

            pendingFeesUsd = fee0Usd + fee1Usd;
        }

        gasFee = usdGasFee * 10 ** IERC20Metadata(debtToken).decimals() / oracle.getAssetPrice(debtToken);
        uint256 flashFee = flashLoanProvider.flashFee(debtToken, CLLeveragedPosition(position).getDebt() + gasFee);
        uint256 flashFeeUsd = flashFee * oracle.getAssetPrice(debtToken) / 10 ** IERC20Metadata(debtToken).decimals();
        percent = (pendingFeesUsd == 0) ? 1e4 : (flashFeeUsd + usdGasFee) * 1e4 / pendingFeesUsd;

        return (gasFee, percent);
    }

    function _getPositionCLAdapterAndData(address position)
        internal
        view
        returns (BaseCLAdapter adapter, BaseCLAdapter.PositionData memory positionData)
    {
        adapter = CLLeveragedPosition(position).positionWrapper().adapter();
        uint256 tokenId = CLLeveragedPosition(position).positionTokenId();
        positionData = adapter.getPositionData(tokenId);
    }

    struct CalcFeeVars {
        IYLDROracle oracle;
        address debtToken;
        uint256 debtTokenPrice;
        uint8 debtTokenDecimals;
        uint256 debt;
        uint256 maxGasFeeUsd;
        address pool;
        uint160 sqrtPriceX96;
        uint256 amount0;
        uint256 amount1;
    }

    function _calculateAndValidateFee(
        address position,
        BaseCLAdapter adapter,
        BaseCLAdapter.PositionData memory positionData,
        GasFeeConfig memory config,
        uint256 usdGasFee,
        uint256 percentFee
    ) internal view returns (uint256) {
        CalcFeeVars memory vars;
        vars.oracle = IYLDROracle(addressesProvider.getPriceOracle());
        vars.debtToken = CLLeveragedPosition(position).borrowedToken();
        vars.debtTokenPrice = vars.oracle.getAssetPrice(vars.debtToken);
        vars.debtTokenDecimals = IERC20Metadata(vars.debtToken).decimals();
        vars.debt = CLLeveragedPosition(position).getDebt();

        uint256 maxGasFeeUsd;
        if (config.maxUsd > 0) {
            maxGasFeeUsd = config.maxUsd;
        } else {
            vars.pool = adapter.getPool(positionData);
            (vars.sqrtPriceX96,) = adapter.getPoolState(vars.pool);
            (vars.amount0, vars.amount1) = LiquidityAmounts.getAmountsForLiquidity(
                vars.sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionData.tickLower),
                TickMath.getSqrtRatioAtTick(positionData.tickUpper),
                positionData.liquidity
            );
            (uint256 fee0, uint256 fee1) = adapter.getPendingFees(positionData);
            vars.amount0 += fee0;
            vars.amount1 += fee1;

            uint256 token0Price = vars.oracle.getAssetPrice(positionData.token0);
            uint256 token1Price = vars.oracle.getAssetPrice(positionData.token1);

            uint256 usdValue = vars.amount0 * token0Price / (10 ** IERC20Metadata(positionData.token0).decimals())
                + vars.amount1 * token1Price / (10 ** IERC20Metadata(positionData.token1).decimals())
                - vars.debt * vars.debtTokenPrice / (10 ** vars.debtTokenDecimals);

            maxGasFeeUsd = usdValue * config.maxPositionPercent / 1e4;
        }

        require(usdGasFee <= maxGasFeeUsd, "Gas fee too high");

        return (10 ** vars.debtTokenDecimals) * usdGasFee / vars.debtTokenPrice + percentFee * vars.debt / 1e4;
    }

    function getConfiguredAutomations(address[] memory positions)
        public
        view
        returns (
            ScheduledRebalance[] memory rebalances,
            ScheduledDeleverage[] memory deleverages,
            ScheduledCompound[] memory compounds
        )
    {
        rebalances = new ScheduledRebalance[](positions.length);
        deleverages = new ScheduledDeleverage[](positions.length);
        compounds = new ScheduledCompound[](positions.length);

        for (uint256 i = 0; i < positions.length; i++) {
            rebalances[i] = scheduledRebalances[positions[i]];
            deleverages[i] = scheduledDeleverages[positions[i]];
            compounds[i] = scheduledCompounds[positions[i]];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPriceOracleGetter} from "./IPriceOracleGetter.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IYLDROracle
 *
 * @notice Defines the basic interface for the YLDR Oracle
 */
interface IYLDROracle is IPriceOracleGetter {
    /**
     * @dev Emitted after the base currency is set
     * @param baseCurrency The base currency of used for price quotes
     * @param baseCurrencyUnit The unit of the base currency
     */
    event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

    /**
     * @dev Emitted after the price source of an asset is updated
     * @param asset The address of the asset
     * @param source The price source of the asset
     */
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the price source of an ERC1155 asset is updated
     * @param asset The address of the asset
     * @param source The price source of the asset
     */
    event ERC1155AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the address of fallback oracle is updated
     * @param fallbackOracle The address of the fallback oracle
     */
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;

    /**
     * @notice Sets or replaces price sources of ERC1155 assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setERC1155AssetSources(address[] calldata assets, address[] calldata sources) external;

    /**
     * @notice Sets the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function setFallbackOracle(address fallbackOracle) external;

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return The prices of the given assets
     */
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns a list of prices from a list of assets addresses and ids
     * @param assets The addresses of the asseta
     * @param ids The tokenIds of the asseta
     * @return The price of the asset
     */
    function getERC1155AssetsPrices(address[] calldata assets, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Returns the address of the source for an ERC1155 asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfERC1155Asset(address asset) external view returns (address);

    /**
     * @notice Returns the address of the fallback oracle
     * @return The address of the fallback oracle
     */
    function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(bytes32 indexed id, address indexed proxyAddress, address indexed newImplementationAddress);

    /**
     * @notice Returns the id of the YLDR market to which this contract points to.
     * @return The market id
     */
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple YLDR markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     */
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BaseCLAdapter} from "./adapters/BaseCLAdapter.sol";
import {ERC1155SupplyUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {CLAdapterWrapper} from "./CLAdapterWrapper.sol";

contract ERC1155CLWrapper is ERC1155SupplyUpgradeable, IERC721Receiver {
    using CLAdapterWrapper for BaseCLAdapter;

    BaseCLAdapter public immutable adapter;

    constructor(BaseCLAdapter _adapter) {
        adapter = _adapter;

        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init("");
    }

    error OnlyPositionManager();

    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        if (_msgSender() != adapter.getPositionManager()) revert OnlyPositionManager();
        _mint(operator, tokenId, 10 ** 18, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function burn(address account, uint256 tokenId, uint256 value, address recipient)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        uint256 _totalSupply = totalSupply(tokenId);

        _burn(account, tokenId, value);

        BaseCLAdapter.PositionData memory position = adapter.getPositionData(tokenId);
        (uint256 fees0, uint256 fees1) = adapter.getPendingFees(position);

        (amount0, amount1) = adapter.delegateDecreaseLiquidity({
            tokenId: tokenId,
            liquidity: uint128(position.liquidity * value / _totalSupply)
        });

        amount0 += fees0 * value / _totalSupply;
        amount1 += fees1 * value / _totalSupply;

        return adapter.delegateCollectFees(position.tokenId, uint128(amount0), uint128(amount1), recipient);
    }

    function unwrap(address account, uint256 tokenId, address recipient) public {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burn(account, tokenId, totalSupply(tokenId));

        IERC721(adapter.getPositionManager()).safeTransferFrom(address(this), recipient, tokenId, "");
    }

    /// @inheritdoc ERC1155SupplyUpgradeable
    function totalSupply(uint256 id) public view override(ERC1155SupplyUpgradeable) returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply(id);
    }

    /// @inheritdoc ERC1155SupplyUpgradeable
    function totalSupply() public view override(ERC1155SupplyUpgradeable) returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply();
    }

    /// @inheritdoc ERC1155SupplyUpgradeable
    function exists(uint256 id) public view override(ERC1155SupplyUpgradeable) returns (bool) {
        return ERC1155SupplyUpgradeable.exists(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IYLDROracle} from "@yldr-lending/core/src/interfaces/IYLDROracle.sol";
import {IPoolAddressesProvider} from "@yldr-lending/core/src/interfaces/IPoolAddressesProvider.sol";
import {IAssetConverter} from "./interfaces/IAssetConverter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConverter} from "./interfaces/IConverter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @author YLDR <[email protected]>
contract AssetConverter is IAssetConverter, Ownable {
    using SafeERC20 for IERC20;

    IPoolAddressesProvider private immutable addressesProvider;
    mapping(address => mapping(address => IConverter)) private _routes;
    mapping(address => mapping(address => address[])) private _complexRoutes;

    constructor(IPoolAddressesProvider _addressesProvider) Ownable(msg.sender) {
        addressesProvider = _addressesProvider;
    }

    function routes(address source, address destination) public view returns (IConverter) {
        return _routes[source][destination];
    }

    function complexRoutes(address source, address destination) public view returns (address[] memory) {
        return _complexRoutes[source][destination];
    }

    function updateRoutes(RouteConverterUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            _routes[updates[i].source][updates[i].destination] = updates[i].converter;
        }
    }

    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            _complexRoutes[updates[i].source][updates[i].destination] = updates[i].complexRoutes;
        }
    }

    function _checkSlippage(
        address source,
        address destination,
        uint256 amountIn,
        uint256 amountOut,
        uint256 maxSlippage
    ) internal view returns (bool) {
        // If amountIn is low enough, than fee substraction may substract 1
        // And in case in low amountIn this can make big difference
        amountIn -= 1;

        IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());
        uint256 sourceUSDPrice = oracle.getAssetPrice(source);
        uint256 destinationUSDPrice = oracle.getAssetPrice(destination);

        uint256 sourceUSDValue = (amountIn * sourceUSDPrice) / (10 ** IERC20Metadata(source).decimals());
        uint256 expected = (sourceUSDValue * (10 ** IERC20Metadata(destination).decimals())) / destinationUSDPrice;
        return (amountOut >= (expected * (10000 - maxSlippage)) / 10000);
    }

    function _getRoute(address source, address destination)
        internal
        view
        returns (address[] memory tokens, IConverter[] memory converters)
    {
        uint256 complexRoutesLength = _complexRoutes[source][destination].length;
        tokens = new address[](2 + complexRoutesLength);
        converters = new IConverter[](tokens.length - 1);
        tokens[0] = source;
        for (uint256 i = 0; i < complexRoutesLength; i++) {
            tokens[i + 1] = _complexRoutes[source][destination][i];
        }
        tokens[tokens.length - 1] = destination;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            converters[i] = _routes[tokens[i]][tokens[i + 1]];
            require(address(converters[i]) != address(0), "AssetConverter: No converter specified for the route");
        }
    }

    function swap(address source, address destination, uint256 amountIn, uint256 maxSlippage)
        external
        returns (uint256)
    {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        IERC20(source).safeTransferFrom(msg.sender, address(converters[0]), amountIn);
        uint256 currentAmount = amountIn;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            if (currentAmount == 0) {
                break;
            }

            address to = i < tokens.length - 2 ? address(converters[i + 1]) : msg.sender;
            currentAmount = converters[i].swap(tokens[i], tokens[i + 1], currentAmount, to);
        }

        uint256 amountOut = currentAmount;

        if (!_checkSlippage(source, destination, amountIn, amountOut, maxSlippage)) {
            revert SlippageTooBig(amountIn, amountOut);
        }

        return amountOut;
    }

    function previewSwap(address source, address destination, uint256 value) external returns (uint256) {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        for (uint256 i = 0; i < tokens.length - 1; i++) {
            IConverter converter = converters[i];
            value = converter.previewSwap(tokens[i], tokens[i + 1], value);
        }
        return value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IPool} from "@yldr-lending/core/src/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@yldr-lending/core/src/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IYLDROracle} from "@yldr-lending/core/src/interfaces/IYLDROracle.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import {IAssetConverter} from "src/interfaces/IAssetConverter.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BaseCLAdapter} from "@yldr-lending/core/src/protocol/concentrated-liquidity/adapters/BaseCLAdapter.sol";
import {ERC1155CLWrapper} from "@yldr-lending/core/src/protocol/concentrated-liquidity/ERC1155CLWrapper.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CLAdapterWrapper} from "@yldr-lending/core/src/protocol/concentrated-liquidity/CLAdapterWrapper.sol";

/// @author YLDR <[email protected]>
/// @notice This contract represents single leveraged position linked to a specific user
/// This contract's funds mainly stored in yldr protocol and consist of wrapped into ERC1155 Uniswap LP Position
/// and debt.
contract CLLeveragedPosition is OwnableUpgradeable, ERC1155Holder, ERC721Holder, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;
    using CLAdapterWrapper for BaseCLAdapter;

    event Deleverage();
    event Rebalance();
    event Compound();
    event DeleverageWithdrawLiquidity();

    error TooBigPoolPriceDeviation();
    error InvalidCaller();
    error InvalidInitiator();

    struct Cache {
        IYLDROracle oracle;
        address token0;
        address token1;
        address borrowedToken;
        uint256 positionTokenId;
        uint24 fee;
        address liquidityPool;
        uint8 token0Decimals;
        uint8 token1Decimals;
        uint256 token0Price;
        uint256 token1Price;
        uint256 revenueFee;
    }

    enum FlashloanPurpose {
        Deleverage,
        Compound,
        Rebalance
    }

    /// @notice Id of leveraged position. The safe Id is used in Uniswap V3 position manager and yldr's ERC1155 Uniswap wrapper
    uint256 public positionTokenId;

    address public liquidityPool;
    address token0;
    address token1;
    /// @notice Address of token which was borrowed to leverage position
    address public borrowedToken;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;

    /// @dev Temporary variable used only to store flash loan provider address during flashloans
    /// Different providers may be used for deposits and withdrawals
    IERC3156FlashLender private flashLoanProvider;

    uint256 public revenueFee;
    uint128 public lastFees0;
    uint128 public lastFees1;

    IPoolAddressesProvider public immutable addressesProvider;
    ERC1155CLWrapper public immutable positionWrapper;
    IPool public immutable pool;
    uint256 public immutable revenueFeePercent;
    address immutable feeTreasury;
    address immutable automationsManager;
    BaseCLAdapter immutable adapter;

    /// @notice Params which are used to initialize position
    /// @param tokenId ID of position token
    /// @param tokenToBorrow Token which has to be borrowed to leverage position
    /// @param amountToBorrow Amount of token to borrow
    /// @param flashLoanProvider IERC3156-flashloan provider chosen by user which will be used to aquire funds for leveraging
    /// @param assetConverter Converter chosen by user which will be used to swap borrowed token into token0 and token1
    /// @param owner Owner of the position
    /// @param maxSwapSlippage Max slippage for swaps
    struct PositionInitParams {
        uint256 tokenId;
        address tokenToBorrow;
        uint256 amountToBorrow;
        // field not used but kept for backwards compatibility
        IERC3156FlashLender flashLoanProvider;
        IAssetConverter assetConverter;
        address owner;
        uint256 maxSwapSlippage;
    }

    /// @notice Params which are used to deleverage position
    /// @param assetConverter Converter chosen by user which will be used to swap token0 and token1 into borrowed token
    /// @param maxSwapSlippage Max slippage for swaps
    /// @param receiver Address which will receive leftover tokens after deleveraging
    struct DeleverageParams {
        IAssetConverter assetConverter;
        uint256 maxSwapSlippage;
        address receiver;
        bool withdrawLiquidity;
    }

    /// @notice Params which are used to compound fees
    /// @param assetConverter Converter chosen by user which will be used to swap fees to token0 and token1 in needed proportions
    /// @param maxSwapSlippage Max slippage for swaps
    struct CompoundParams {
        IAssetConverter assetConverter;
        uint256 maxSwapSlippage;
    }

    /// @notice Params which are used to rebalance position
    /// @param assetConverter Converter chosen by user which will be used to swap fees to token0 and token1 in needed proportions
    /// @param maxSwapSlippage Max slippage for swaps
    /// @param newTickLower New lower tick for position
    /// @param newTickUpper New upper tick for position
    struct RebalanceParams {
        IAssetConverter assetConverter;
        uint256 maxSwapSlippage;
        int24 newTickLower;
        int24 newTickUpper;
    }

    constructor(
        IPoolAddressesProvider _addressesProvider,
        ERC1155CLWrapper _positionWrapper,
        uint256 _revenueFeePercent,
        address _feeTreasury,
        address _automationsManager
    ) {
        addressesProvider = _addressesProvider;
        pool = IPool(addressesProvider.getPool());
        positionWrapper = _positionWrapper;
        revenueFeePercent = _revenueFeePercent;
        feeTreasury = _feeTreasury;
        automationsManager = _automationsManager;
        adapter = _positionWrapper.adapter();
    }

    /// @notice Initializer of the contract. Sets storage variables and performs leveraging operations
    /// 1. Take flashloan
    /// 2. Swap borrowed token into token0 and token1
    /// 3. Increase liquidity of position
    /// 4. Take normal debt at yldr
    /// 5. Repay flashloan with borrowed tokens
    function initialize(PositionInitParams calldata params) public initializer {
        __Ownable_init(params.owner);
        positionTokenId = params.tokenId;
        borrowedToken = params.tokenToBorrow;

        {
            BaseCLAdapter.PositionData memory position = adapter.getPositionData(params.tokenId);
            token0 = position.token0;
            token1 = position.token1;
            fee = position.fee;
            tickLower = position.tickLower;
            tickUpper = position.tickUpper;

            liquidityPool = adapter.getPool(position);
        }

        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        bool[] memory createPosition = new bool[](1);

        assets[0] = params.tokenToBorrow;
        amounts[0] = params.amountToBorrow;
        createPosition[0] = true;

        pool.flashLoan(address(this), assets, amounts, createPosition, address(this), abi.encode(params), 0);
    }

    function _getCache() internal view returns (Cache memory cache) {
        IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());

        return Cache({
            oracle: oracle,
            token0: token0,
            token1: token1,
            borrowedToken: borrowedToken,
            positionTokenId: positionTokenId,
            fee: fee,
            liquidityPool: liquidityPool,
            token0Decimals: _getDecimals(token0),
            token1Decimals: _getDecimals(token1),
            token0Price: oracle.getAssetPrice(token0),
            token1Price: oracle.getAssetPrice(token1),
            revenueFee: revenueFee
        });
    }

    /// @notice Helper function for flashloans. Sets temporary flashLoanProvider storage variable to authorize flashloan
    function _takeFlashloan(
        IERC3156FlashLender _flashLoanProvider,
        address token,
        uint256 amount,
        FlashloanPurpose purpose,
        bytes memory params
    ) internal {
        flashLoanProvider = _flashLoanProvider;
        flashLoanProvider.flashLoan(this, token, amount, abi.encode(purpose, params));
        flashLoanProvider = IERC3156FlashLender(address(0));
    }

    function _checkAutomations() internal view {
        if (msg.sender != automationsManager) revert InvalidCaller();
    }

    /// @notice Function to perform swaps through user-supplied assetConverter.
    /// @param assetConverter Converter which will be used to perform swaps
    /// @param source Token to swap from
    /// @param destination Token to swap to
    /// @param amount Amount to swap
    /// @param maxSlippage Max slippage for swaps
    function _swap(
        IAssetConverter assetConverter,
        address source,
        address destination,
        uint256 amount,
        uint256 maxSlippage
    ) internal returns (uint256 amountOut) {
        if (source == destination) {
            return amount;
        }
        if (amount == 0) {
            return 0;
        }
        if (IERC20(source).allowance(address(this), address(assetConverter)) < amount) {
            IERC20(source).forceApprove(address(assetConverter), type(uint256).max);
        }
        return assetConverter.swap(source, destination, amount, maxSlippage);
    }

    /// @notice Function which uses current pool price and oracle prices to find distribution in which funds should
    /// be divided to supply liquidity in position with as less leftovers as possible.
    function _divideAmountForSwap(Cache memory cache, uint256 amount)
        internal
        view
        returns (uint256 amountToSwapFor0, uint256 amountToSwapFor1)
    {
        uint128 liquidity = adapter.getPositionData(cache.positionTokenId).liquidity;
        (uint160 sqrtPriceX96,) = adapter.getPoolState(cache.liquidityPool);
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), liquidity
        );

        uint256 amount0USD = amount0 * cache.token0Price / (10 ** cache.token0Decimals);
        uint256 amount1USD = amount1 * cache.token1Price / (10 ** cache.token1Decimals);

        amountToSwapFor0 = amount * amount0USD / (amount0USD + amount1USD);
        amountToSwapFor1 = amount - amountToSwapFor0;
    }

    struct DetermineSwapVars {
        uint160 sqrtPriceX96;
        uint256 amount0Current;
        uint256 amount1Current;
        uint256 amount0CurrentUSD;
        uint256 amount1CurrentUSD;
    }

    /// @notice Function which uses current pool price and oracle prices to find distribution in which funds should
    /// be divided to supply liquidity in position with as less leftovers as possible.
    function _determineNeededSwap(
        Cache memory cache,
        uint256 amount0,
        uint256 amount1,
        int24 positionTickLower,
        int24 positionTickUpper
    ) internal view returns (bool zeroForOne, uint256 amount) {
        DetermineSwapVars memory vars;

        (vars.sqrtPriceX96,) = adapter.getPoolState(cache.liquidityPool);
        (vars.amount0Current, vars.amount1Current) = LiquidityAmounts.getAmountsForLiquidity(
            vars.sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(positionTickLower),
            TickMath.getSqrtRatioAtTick(positionTickUpper),
            adapter.getPoolLiquidity(cache.liquidityPool) // can be any value basically
        );

        vars.amount0CurrentUSD = vars.amount0Current * cache.token0Price / (10 ** cache.token0Decimals);
        vars.amount1CurrentUSD = vars.amount1Current * cache.token1Price / (10 ** cache.token1Decimals);
        uint256 amountCurrentTotalUSD = vars.amount0CurrentUSD + vars.amount1CurrentUSD;

        uint256 amount0USD = amount0 * cache.token0Price / (10 ** cache.token0Decimals);
        uint256 amount1USD = amount1 * cache.token1Price / (10 ** cache.token1Decimals);
        uint256 amountTotalUSD = amount0USD + amount1USD;

        // If (amount1USD / amountTotalUSD) < (amount1CurrentUSD / amountCurrentTotalUSD) => zeroForOne = true
        if (amount1USD * amountCurrentTotalUSD < vars.amount1CurrentUSD * amountTotalUSD) {
            uint256 targetAmountUSD = amountTotalUSD * vars.amount1CurrentUSD / amountCurrentTotalUSD;
            return (true, (targetAmountUSD - amount1USD) * (10 ** cache.token0Decimals) / cache.token0Price);
        } else {
            uint256 targetAmountUSD = amountTotalUSD * vars.amount0CurrentUSD / amountCurrentTotalUSD;
            return (false, (targetAmountUSD - amount0USD) * (10 ** cache.token1Decimals) / cache.token1Price);
        }
    }

    function _checkPoolPrice(Cache memory cache, uint256 maxSlippage) internal view {
        (uint160 sqrtPriceX96,) = adapter.getPoolState(cache.liquidityPool);
        uint256 expectedSqrtPriceX96 = _calculateOracleSqrtPriceX96(cache);
        uint256 _delta = Math.mulDiv(sqrtPriceX96, 1e4, expectedSqrtPriceX96) ** 2 / 1e4;
        uint256 delta = _delta > 1e4 ? _delta - 1e4 : 1e4 - _delta;

        if (delta > maxSlippage) revert TooBigPoolPriceDeviation();
    }

    function _calculateOracleSqrtPriceX96(Cache memory cache) internal pure returns (uint160 sqrtPriceX96) {
        // price = (10 ** token1Decimals) * token0Rate / ((10 ** token0Decimals) * token1Rate)
        // sqrtPriceX96 = sqrt(price * 2^192)

        // overflows only if token0 is 2**160 times more expensive than token1 (considered non-likely)
        uint256 factor1 = Math.mulDiv(cache.token0Price, 2 ** 96, cache.token1Price);

        // Cannot overflow if token1Decimals <= 18 and token0Decimals <= 18
        uint256 factor2 = Math.mulDiv(10 ** cache.token1Decimals, 2 ** 96, 10 ** cache.token0Decimals);

        uint128 factor1Sqrt = uint128(Math.sqrt(factor1));
        uint128 factor2Sqrt = uint128(Math.sqrt(factor2));

        sqrtPriceX96 = factor1Sqrt * factor2Sqrt;
    }

    // helps avoid stack too deep
    struct InitPositionVars {
        uint256 amountToSwapFor0;
        uint256 amountToSwapFor1;
        uint256 amount0;
        uint256 amount1;
        uint256 amount0Resulted;
        uint256 amount1Resulted;
    }

    /// @notice Function which initializes leveraged position
    function _initPositionInsideFlashloan(PositionInitParams memory params) internal {
        Cache memory cache = _getCache();

        _checkPoolPrice(cache, params.maxSwapSlippage);

        InitPositionVars memory vars;

        // Calculate amounts to swap for token0 and token1
        (vars.amountToSwapFor0, vars.amountToSwapFor1) = _divideAmountForSwap(cache, params.amountToBorrow);

        // Do swaps
        vars.amount0 = _swap(
            params.assetConverter, params.tokenToBorrow, cache.token0, vars.amountToSwapFor0, params.maxSwapSlippage
        );
        vars.amount1 = _swap(
            params.assetConverter, params.tokenToBorrow, cache.token1, vars.amountToSwapFor1, params.maxSwapSlippage
        );

        // Add liquidity
        (vars.amount0Resulted, vars.amount1Resulted) = _increaseLiquidity(cache, vars.amount0, vars.amount1);

        // Send leftovers to user
        _transferTokens(cache, params.owner, vars.amount0 - vars.amount0Resulted, vars.amount1 - vars.amount1Resulted);

        if (revenueFeePercent > 0) {
            uint256 debtValue = params.amountToBorrow * cache.oracle.getAssetPrice(params.tokenToBorrow)
                / (10 ** _getDecimals(params.tokenToBorrow));
            uint256 positionValue = cache.oracle.getERC1155AssetPrice(address(positionWrapper), cache.positionTokenId);

            // Only take revenue fee from borrowed funds
            revenueFee = revenueFeePercent * debtValue / positionValue;

            _updateLastPendingFees(cache);
        }
    }

    function _getPositionUSDValues(Cache memory cache) internal view returns (uint256 usdLiquidity, uint256 usdFees) {
        BaseCLAdapter.PositionData memory position = adapter.getPositionData(cache.positionTokenId);
        (uint160 sqrtPriceX96,) = adapter.getPoolState(cache.liquidityPool);

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(position.tickLower),
            TickMath.getSqrtRatioAtTick(position.tickUpper),
            position.liquidity
        );

        uint256 amount0USD = amount0 * cache.token0Price / (10 ** cache.token0Decimals);
        uint256 amount1USD = amount1 * cache.token1Price / (10 ** cache.token1Decimals);

        usdLiquidity = amount0USD + amount1USD;

        (uint256 fees0, uint256 fees1) = adapter.getPendingFees(position);

        uint256 fees0USD = fees0 * cache.token0Price / (10 ** cache.token0Decimals);
        uint256 fees1USD = fees1 * cache.token1Price / (10 ** cache.token1Decimals);

        usdFees = fees0USD + fees1USD;
    }

    /// @notice Helper function for deleveraging position which burns position partly and sends the rest to receiver
    /// It is called when we need to withdraw position, but keep part of it to swap into debt token and repay debt
    ///
    /// In case when we are the only owner of the position, we can just unwrap it and decrease liquidity via position manager
    ///
    /// In case when we are not the only owner of the position (this can happen when position was liquidated), we can't unwrap it,
    /// so we burn all shares, receive token0 and token1 amounts and send part of it to receiver
    function _burnPartAndWithdrawRest(
        Cache memory cache,
        DeleverageAmounts memory amounts,
        address receiver,
        bool withdrawLiquidity
    ) internal returns (uint256 amount0ForRepayment, uint256 amount1ForRepayment) {
        if (amounts.wrappedBalance == amounts.wrappedTotalSupply) {
            // If we are the only owner of the position, we can just unwrap it and withdraw liquidity via position manager
            positionWrapper.unwrap(address(this), cache.positionTokenId, address(this));

            (uint256 liquidityToBurn, uint256 liquidityForRepayment, uint256 feesPercentForRepayment) =
                _getAmountsForOwned(cache, amounts, withdrawLiquidity);

            {
                // Those amounts contain amounts returned in exchange for redeemed liquidity, without fees.
                (uint256 amount0FromLiquidity, uint256 amount1FromLiquidity) =
                    _decreaseLiquidity(cache.positionTokenId, uint128(liquidityToBurn));

                // Only take liquidityForRepayment part of the returned amounts.
                amount0ForRepayment = Math.mulDiv(amount0FromLiquidity, liquidityForRepayment, liquidityToBurn);
                amount1ForRepayment = Math.mulDiv(amount1FromLiquidity, liquidityForRepayment, liquidityToBurn);
            }

            if (feesPercentForRepayment > 0) {
                amount0ForRepayment += Math.mulDiv(amounts.fees0, feesPercentForRepayment, 1e4);
                amount1ForRepayment += Math.mulDiv(amounts.fees1, feesPercentForRepayment, 1e4);
            }
            (uint256 amount0Total, uint256 amount1Total) = _collectFees({
                tokenId: cache.positionTokenId,
                // Collect everything if we are withdrawing liquidity, otherwise only amounts for repayment and revenue fees.
                amount0Max: withdrawLiquidity ? type(uint128).max : uint128(amount0ForRepayment + amounts.revenueFee0),
                amount1Max: withdrawLiquidity ? type(uint128).max : uint128(amount1ForRepayment + amounts.revenueFee1)
            });

            _transferTokens(cache, feeTreasury, amounts.revenueFee0, amounts.revenueFee1);

            if (withdrawLiquidity) {
                _transferTokens(
                    cache,
                    receiver,
                    amount0Total - amount0ForRepayment - amounts.revenueFee0,
                    amount1Total - amount1ForRepayment - amounts.revenueFee1
                );
            } else {
                // Send NFT to owner, we don't need it anymore
                IERC721(adapter.getPositionManager()).safeTransferFrom(
                    address(this), receiver, cache.positionTokenId, ""
                );
            }
        } else {
            // If we are not the only owner of LP, we can't unwrap it, so we need to burn our shares
            (uint256 amount0Total, uint256 amount1Total) =
                positionWrapper.burn(address(this), positionTokenId, amounts.wrappedBalance, address(this));

            uint256 usdAmountNeeded = amounts.usdRepayment + amounts.usdRevenueFee;
            uint256 amount0Needed = Math.mulDiv(usdAmountNeeded, amount0Total, amounts.usdPositionValue);
            uint256 amount1Needed = Math.mulDiv(usdAmountNeeded, amount1Total, amounts.usdPositionValue);

            _transferTokens(cache, receiver, amount0Total - amount0Needed, amount1Total - amount1Needed);

            if (usdAmountNeeded > 0) {
                amount0ForRepayment = amount0Needed * amounts.usdRepayment / usdAmountNeeded;
                amount1ForRepayment = amount1Needed * amounts.usdRepayment / usdAmountNeeded;

                uint256 amount0ToTreasury = amount0Needed - amount0ForRepayment;
                uint256 amount1ToTreasury = amount1Needed - amount1ForRepayment;

                _transferTokens(cache, feeTreasury, amount0ToTreasury, amount1ToTreasury);
            }
        }
    }

    /// @notice Returns amounts which should be used for deleveraging position in cases when we are operating on an owned position.
    /// @return liquidityToBurn Total amount of liquidity to burn. 100% if withdrawLiquidity is true,
    /// otherwise only as much as we need for debt repayment
    /// @return liquidityForRepayment Amount of liquidity to burn for debt repayment.
    /// @return feePercentForRepayment Fee percent to be used for debt repayment.
    /// We are trying to avoid touching user fees if possible, so this is set if liquidity is not enough for full debt repayment.
    function _getAmountsForOwned(Cache memory cache, DeleverageAmounts memory amounts, bool withdrawLiquidity)
        internal
        view
        returns (uint256 liquidityToBurn, uint256 liquidityForRepayment, uint256 feePercentForRepayment)
    {
        uint128 liquidity = adapter.getPositionData(cache.positionTokenId).liquidity;

        // We want to avoid touching user fees during repayment if possible.
        if (amounts.usdRepayment <= amounts.usdLiquidityValue) {
            liquidityForRepayment = Math.mulDiv(liquidity, amounts.usdRepayment, amounts.usdLiquidityValue);
        } else {
            liquidityForRepayment = liquidity;
            feePercentForRepayment =
                Math.mulDiv(amounts.usdRepayment - amounts.usdLiquidityValue, 1e4, amounts.usdFeesValue);
        }

        if (withdrawLiquidity) {
            liquidityToBurn = liquidity;
        } else {
            liquidityToBurn = liquidityForRepayment;
        }
    }

    /// @param usdPositionValue value of position liquidity + fees in USD
    /// @param usdLiquidityValue value of position liquidity in USD
    /// @param usdFeesValue value of position fees in USD
    /// @param usdRepayment value needed for debt repayment in USD, including potential slippage costs
    /// @param usdRevenueFee value of revenue fee in USD
    /// @param fees0 amount of token0 fees
    /// @param fees1 amount of token1 fees
    /// @param revenueFee0 amount of token0 revenue fee
    /// @param revenueFee1 amount of token1 revenue fee
    /// @param wrappedBalance balance of wrapped position tokens
    /// @param wrappedTotalSupply total supply of wrapped position tokens
    struct DeleverageAmounts {
        uint256 usdPositionValue;
        uint256 usdLiquidityValue;
        uint256 usdFeesValue;
        uint256 usdRepayment;
        uint256 usdRevenueFee;
        uint256 fees0;
        uint256 fees1;
        uint256 revenueFee0;
        uint256 revenueFee1;
        uint256 wrappedBalance;
        uint256 wrappedTotalSupply;
    }

    function _calculateDeleverageAmounts(
        Cache memory cache,
        uint256 debtAmount,
        uint256 maxSwapSlippage,
        uint256 balance,
        uint256 wrappedTotalSupply
    ) internal view returns (DeleverageAmounts memory amounts) {
        amounts.wrappedBalance = balance;
        amounts.wrappedTotalSupply = wrappedTotalSupply;
        (amounts.usdLiquidityValue, amounts.usdFeesValue) = _getPositionUSDValues(cache);
        amounts.usdPositionValue = balance * (amounts.usdLiquidityValue + amounts.usdFeesValue) / wrappedTotalSupply;
        uint256 debtValue =
            debtAmount * cache.oracle.getAssetPrice(borrowedToken) / (10 ** _getDecimals(cache.borrowedToken));

        // Consider slippage, if we will end up with more than needed, rest will be sent to receiver as well
        amounts.usdRepayment = Math.min(amounts.usdPositionValue, Math.mulDiv(debtValue, (1e4 + maxSwapSlippage), 1e4));
        (amounts.fees0, amounts.fees1) = _getPendingFees(cache);
        if (cache.revenueFee > 0) {
            (amounts.revenueFee0, amounts.revenueFee1) = _calculateRevenueFee(amounts.fees0, amounts.fees1);

            amounts.usdRevenueFee = amounts.revenueFee0 * cache.token0Price / (10 ** cache.token0Decimals)
                + amounts.revenueFee1 * cache.token1Price / (10 ** cache.token1Decimals);

            uint256 maxUSDRevenueFee = amounts.usdPositionValue - amounts.usdRepayment;
            if (amounts.usdRevenueFee > maxUSDRevenueFee) {
                amounts.revenueFee0 = amounts.revenueFee0 * maxUSDRevenueFee / amounts.usdRevenueFee;
                amounts.revenueFee1 = amounts.revenueFee1 * maxUSDRevenueFee / amounts.usdRevenueFee;
                amounts.usdRevenueFee = maxUSDRevenueFee;
            }
        }
    }

    /// @notice Function which deleverages position
    /// @param params Params which are used to deleverage position
    /// @param flashAmount Amount of flashloan
    /// @param flashFee Fee of flashloan
    function _deleverageInsideFlashloan(DeleverageParams memory params, uint256 flashAmount, uint256 flashFee)
        internal
    {
        Cache memory cache = _getCache();
        _repayFullDebtAndPayAutomations(cache, flashAmount);

        // Withdraw LP
        uint256 balance =
            pool.withdrawERC1155(address(positionWrapper), cache.positionTokenId, type(uint256).max, address(this));
        uint256 wrappedTotalSupply = positionWrapper.totalSupply(cache.positionTokenId);

        DeleverageAmounts memory amounts = _calculateDeleverageAmounts({
            cache: cache,
            debtAmount: flashAmount + flashFee,
            maxSwapSlippage: params.maxSwapSlippage,
            balance: balance,
            wrappedTotalSupply: wrappedTotalSupply
        });

        // Aquire amounts to swap into borrowed token
        (uint256 amount0ForRepayment, uint256 amount1ForRepayment) =
            _burnPartAndWithdrawRest(cache, amounts, params.receiver, params.withdrawLiquidity);

        // Swap tokens to repay debt
        uint256 amountForRepayment = _swap(
            params.assetConverter, cache.token0, cache.borrowedToken, amount0ForRepayment, params.maxSwapSlippage
        ) + _swap(params.assetConverter, cache.token1, cache.borrowedToken, amount1ForRepayment, params.maxSwapSlippage);

        if (amountForRepayment > flashAmount + flashFee) {
            // If we have leftovers, send them to user
            IERC20(cache.borrowedToken).safeTransfer(params.receiver, amountForRepayment - flashAmount - flashFee);
        }
    }

    function _repayAndUnwrap(Cache memory cache, uint256 flashAmount) internal {
        // Repay debt with flashloaned funds
        _repayFullDebtAndPayAutomations(cache, flashAmount);

        // Withdraw LP
        pool.withdrawERC1155(address(positionWrapper), cache.positionTokenId, type(uint256).max, address(this));
        positionWrapper.unwrap(address(this), cache.positionTokenId, address(this));
    }

    function _wrapAndBorrow(Cache memory cache, uint256 amount) internal {
        // Wrap LP
        IERC721(adapter.getPositionManager()).safeTransferFrom(
            address(this), address(positionWrapper), cache.positionTokenId
        );

        if (!positionWrapper.isApprovedForAll(address(this), address(pool))) {
            positionWrapper.setApprovalForAll(address(pool), true);
        }

        pool.supplyERC1155(
            address(positionWrapper),
            cache.positionTokenId,
            positionWrapper.balanceOf(address(this), cache.positionTokenId),
            address(this),
            0
        );

        pool.borrow(cache.borrowedToken, amount, 0, address(this));
    }

    function _compoundInsideFlashloan(CompoundParams memory params, uint256 flashAmount, uint256 flashFee) internal {
        Cache memory cache = _getCache();
        _checkPoolPrice(cache, params.maxSwapSlippage);

        _repayAndUnwrap(cache, flashAmount);

        (uint256 amount0, uint256 amount1) = _collectFees(cache.positionTokenId, type(uint128).max, type(uint128).max);

        if (cache.revenueFee > 0) {
            (uint256 fees0ToTreasury, uint256 fees1ToTreasury) = _calculateRevenueFee(amount0, amount1);

            amount0 -= fees0ToTreasury;
            amount1 -= fees1ToTreasury;

            _transferTokens(cache, feeTreasury, fees0ToTreasury, fees1ToTreasury);
        }

        // Divide and swap rewards
        (bool zeroForOne, uint256 amount) = _determineNeededSwap(cache, amount0, amount1, tickLower, tickUpper);

        if (zeroForOne) {
            amount0 -= amount;
            amount1 += _swap(params.assetConverter, cache.token0, cache.token1, amount, params.maxSwapSlippage);
        } else {
            amount1 -= amount;
            amount0 += _swap(params.assetConverter, cache.token1, cache.token0, amount, params.maxSwapSlippage);
        }

        // Add liquidity
        (uint256 amount0Resulted, uint256 amount1Resulted) = _increaseLiquidity(cache, amount0, amount1);

        _transferTokens(
            cache,
            owner(),
            amount0 > amount0Resulted ? amount0 - amount0Resulted : 0,
            amount1 > amount1Resulted ? amount1 - amount1Resulted : 0
        );

        _wrapAndBorrow(cache, flashAmount + flashFee);

        if (revenueFee > 0) {
            _updateLastPendingFees(cache);
        }
    }

    function _transferTokens(Cache memory cache, address to, uint256 amount0, uint256 amount1) internal {
        if (amount0 > 0) {
            IERC20(cache.token0).safeTransfer(to, amount0);
        }
        if (amount1 > 0) {
            IERC20(cache.token1).safeTransfer(to, amount1);
        }
    }

    function _rebalanceInsideFlashloan(RebalanceParams memory params, uint256 flashAmount, uint256 flashFee) internal {
        Cache memory cache = _getCache();
        _checkPoolPrice(cache, params.maxSwapSlippage);

        _repayAndUnwrap(cache, flashAmount);

        // Decrease liquidity and collect all funds
        uint128 liquidity = adapter.getPositionData(cache.positionTokenId).liquidity;
        (uint256 amount0FromLiquidity, uint256 amount1FromLiquidity) =
            _decreaseLiquidity(cache.positionTokenId, liquidity);
        (uint256 amount0, uint256 amount1) = _collectFees(cache.positionTokenId, type(uint128).max, type(uint128).max);

        if (revenueFee > 0) {
            uint256 fees0 = amount0 - amount0FromLiquidity;
            uint256 fees1 = amount1 - amount1FromLiquidity;
            (uint256 fees0ToTreasury, uint256 fees1ToTreasury) = _calculateRevenueFee(fees0, fees1);

            amount0 -= fees0ToTreasury;
            amount1 -= fees1ToTreasury;

            _transferTokens(cache, feeTreasury, fees0ToTreasury, fees1ToTreasury);
        }

        {
            (bool zeroForOne, uint256 amount) =
                _determineNeededSwap(cache, amount0, amount1, params.newTickLower, params.newTickUpper);

            if (zeroForOne) {
                amount0 -= amount;
                amount1 += _swap(params.assetConverter, cache.token0, cache.token1, amount, params.maxSwapSlippage);
            } else {
                amount1 -= amount;
                amount0 += _swap(params.assetConverter, cache.token1, cache.token0, amount, params.maxSwapSlippage);
            }
        }

        IERC20(cache.token0).forceApprove(adapter.getPositionManager(), amount0);
        IERC20(cache.token1).forceApprove(adapter.getPositionManager(), amount1);

        // Mint new position
        (uint256 tokenId,, uint256 amount0Resulted, uint256 amount1Resulted) = adapter.delegateMintPosition(
            BaseCLAdapter.MintParams({
                token0: cache.token0,
                token1: cache.token1,
                fee: cache.fee,
                tickLower: params.newTickLower,
                tickUpper: params.newTickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: type(uint256).max
            })
        );

        cache.positionTokenId = positionTokenId = tokenId;
        tickLower = params.newTickLower;
        tickUpper = params.newTickUpper;

        // Send leftovers to user
        _transferTokens(
            cache,
            owner(),
            amount0 > amount0Resulted ? amount0 - amount0Resulted : 0,
            amount1 > amount1Resulted ? amount1 - amount1Resulted : 0
        );

        _wrapAndBorrow(cache, flashAmount + flashFee);

        if (revenueFee > 0) {
            _updateLastPendingFees(cache);
        }
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        if (msg.sender != address(pool)) revert InvalidCaller();
        if (initiator != address(this)) revert InvalidInitiator();

        _initPositionInsideFlashloan(abi.decode(params, (PositionInitParams)));

        return true;
    }

    /// @notice Function which is called by flashloan provider
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 flashFee, bytes calldata data)
        external
        returns (bytes32)
    {
        if (msg.sender != address(flashLoanProvider)) revert InvalidCaller();
        if (initiator != address(this)) revert InvalidInitiator();

        (FlashloanPurpose purpose, bytes memory params) = abi.decode(data, (FlashloanPurpose, bytes));

        if (purpose == FlashloanPurpose.Deleverage) {
            _deleverageInsideFlashloan(abi.decode(params, (DeleverageParams)), amount, flashFee);
        } else if (purpose == FlashloanPurpose.Compound) {
            _compoundInsideFlashloan(abi.decode(params, (CompoundParams)), amount, flashFee);
        } else if (purpose == FlashloanPurpose.Rebalance) {
            _rebalanceInsideFlashloan(abi.decode(params, (RebalanceParams)), amount, flashFee);
        }

        IERC20(token).forceApprove(msg.sender, amount + flashFee);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function _deleverage(IERC3156FlashLender flashloanProvider, DeleverageParams memory params, uint256 automationFee)
        internal
    {
        _takeFlashloan(
            flashloanProvider, borrowedToken, getDebt() + automationFee, FlashloanPurpose.Deleverage, abi.encode(params)
        );
        emit Deleverage();
        if (params.withdrawLiquidity) {
            emit DeleverageWithdrawLiquidity();
        }
    }

    /// @notice Function only callable by position owner to deleverage position
    /// It performs following steps:
    /// 1. Take flashloan
    /// 2. Repay debt with flashloaned funds
    /// 3. Withdraw position
    /// 4. Use part of position's funds to swap token0 and token1 into debt token
    /// 5. Send the rest of position funds to receiver
    /// 6. Repay flashloan with tokens taken from position
    function deleverage(IERC3156FlashLender flashloanProvider, DeleverageParams memory params) external {
        _checkOwner();
        _deleverage(flashloanProvider, params, 0);
    }

    function deleverageAutomation(
        IERC3156FlashLender flashloanProvider,
        DeleverageParams memory params,
        uint256 automationFee
    ) external {
        _checkAutomations();
        _deleverage(flashloanProvider, params, automationFee);
    }

    function _compound(IERC3156FlashLender flashloanProvider, CompoundParams memory params, uint256 automationFee)
        internal
    {
        _takeFlashloan(
            flashloanProvider, borrowedToken, getDebt() + automationFee, FlashloanPurpose.Compound, abi.encode(params)
        );
    }

    /// @notice Function only callable by position owner to compound fees
    /// It performs following steps:
    /// 1. Take flashloan
    /// 2. Repay debt with flashloaned funds
    /// 3. Withdraw and unwrap position
    /// 5. collect, divide, swap and reinvest fees
    /// 6. Supply position
    /// 7. Borrow flashloaned amount against the position
    /// 8. Repay flashloan with borrowed tokens
    function compound(IERC3156FlashLender flashloanProvider, CompoundParams memory params) external {
        _checkOwner();
        _compound(flashloanProvider, params, 0);

        emit Compound();
    }

    function compoundAutomation(
        IERC3156FlashLender flashloanProvider,
        CompoundParams memory params,
        uint256 automationFee
    ) external {
        _checkAutomations();
        _compound(flashloanProvider, params, automationFee);
    }

    function _rebalance(IERC3156FlashLender flashloanProvider, RebalanceParams memory params, uint256 automationFee)
        internal
    {
        _takeFlashloan(
            flashloanProvider, borrowedToken, getDebt() + automationFee, FlashloanPurpose.Rebalance, abi.encode(params)
        );
    }

    /// @notice Function only callable by position owner to rebalance position
    function rebalance(IERC3156FlashLender flashloanProvider, RebalanceParams memory params) external {
        _checkOwner();
        _rebalance(flashloanProvider, params, 0);

        emit Rebalance();
    }

    function rebalanceAutomation(
        IERC3156FlashLender flashloanProvider,
        RebalanceParams memory params,
        uint256 automationFee
    ) external {
        _checkAutomations();
        _rebalance(flashloanProvider, params, automationFee);
    }

    function _updateLastPendingFees(Cache memory cache) internal {
        (uint256 fees0, uint256 fees1) = _getPendingFees(cache);
        lastFees0 = uint128(fees0);
        lastFees1 = uint128(fees1);
    }

    // Repays debt with flashloaned funds and treats leftovers as automations fee.
    function _repayFullDebtAndPayAutomations(Cache memory cache, uint256 flashAmount) internal {
        uint256 debt = getDebt();
        IERC20(cache.borrowedToken).safeTransfer(feeTreasury, flashAmount - debt);
        IERC20(cache.borrowedToken).forceApprove(address(pool), debt);
        if (debt > 0) pool.repay(cache.borrowedToken, debt, address(this));
    }

    function getDebt() public view returns (uint256) {
        return IERC20(IPool(addressesProvider.getPool()).getReserveData(borrowedToken).variableDebtTokenAddress)
            .balanceOf(address(this));
    }

    function _getPendingFees(Cache memory cache) internal view returns (uint256 fees0, uint256 fees1) {
        BaseCLAdapter.PositionData memory position = adapter.getPositionData(cache.positionTokenId);
        return adapter.getPendingFees(position);
    }

    function _increaseLiquidity(Cache memory cache, uint256 amount0, uint256 amount1)
        internal
        returns (uint256, uint256)
    {
        IERC20(cache.token0).forceApprove(adapter.getPositionManager(), amount0);
        IERC20(cache.token1).forceApprove(adapter.getPositionManager(), amount1);

        return adapter.delegateIncreaseLiquidity(cache.positionTokenId, amount0, amount1);
    }

    function _decreaseLiquidity(uint256 tokenId, uint128 liquidity) internal returns (uint256, uint256) {
        return adapter.delegateDecreaseLiquidity(tokenId, liquidity);
    }

    function _collectFees(uint256 tokenId, uint128 amount0Max, uint128 amount1Max)
        internal
        returns (uint256, uint256)
    {
        return adapter.delegateCollectFees({
            tokenId: tokenId,
            amount0Max: amount0Max,
            amount1Max: amount1Max,
            recipient: address(this)
        });
    }

    function _getDecimals(address token) internal view returns (uint8) {
        return IERC20Metadata(token).decimals();
    }

    function _calculateRevenueFee(uint256 currentFees0, uint256 currentFees1)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 accrued0 = (currentFees0 > lastFees0) ? currentFees0 - lastFees0 : 0;
        uint256 accrued1 = (currentFees1 > lastFees1) ? currentFees1 - lastFees1 : 0;

        return (accrued0 * revenueFee / 1e4, accrued1 * revenueFee / 1e4);
    }

    // kept for backwards compatibility
    function uniswapV3Pool() external view returns (address) {
        return liquidityPool;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the YLDR price oracle.
 */
interface IPriceOracleGetter {
    /**
     * @notice Returns the base currency address
     * @dev Address 0x0 is reserved for USD as base currency.
     * @return Returns the base currency address.
     */
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Returns the base currency unit
     * @dev 1 ether for ETH, 1e8 for USD.
     * @return Returns the base currency unit.
     */
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Returns the ERC1155 asset price in the base currency
     * It returns the price of totalSupply of given tokenId. To calculate partial amount, use price * shares / totalSupply
     * @param asset The address of the asset
     * @param tokenId The tokenId of the asset
     * @return The price of the asset
     */
    function getERC1155AssetPrice(address asset, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReserveConfiguration} from "../../libraries/configuration/ReserveConfiguration.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {FixedPoint128} from "@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";

/// Generic adapter to UniV3-like concentrated liquidity DEX. Currently oriented
/// and has implementations mainly for Uniswap V3 and Algebra contracts, but can
/// also be extended to support other DEXs with similar semantics.
abstract contract BaseCLAdapter {
    struct PositionData {
        uint256 tokenId;
        address token0;
        address token1;
        // Kept for compatibility, should be set to 0 for protocol with variable pool fees (e.g. Algebra)
        uint24 fee;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
    }

    struct MintParams {
        address token0;
        address token1;
        // Kept for compatibility, should be set to 0 for protocol with variable pool fees (e.g. Algebra)
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function getPositionData(uint256 tokenId) public view virtual returns (PositionData memory);

    function collectFees(uint256 tokenId, uint128 amount0Max, uint128 amount1Max, address receiver)
        public
        virtual
        returns (uint256 amount0, uint256 amount1);

    function increaseLiquidity(uint256 tokenId, uint256 amount0, uint256 amount1)
        public
        virtual
        returns (uint256 amount0Resulted, uint256 amount1Resulted);

    function decreaseLiquidity(uint256 tokenId, uint128 liquidity)
        public
        virtual
        returns (uint256 amount0, uint256 amount1);

    function getPool(PositionData memory position) public view virtual returns (address);

    function getPositionManager() public view virtual returns (address);

    function _getFeeGrowths(address pool, int24 tick)
        internal
        view
        virtual
        returns (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128);

    function getPoolState(address pool) public view virtual returns (uint160 sqrtPriceX96, int24 tick);

    function getPoolLiquidity(address pool) public view virtual returns (uint128 liquidity);

    function _getGlobalFeeGrowths(address pool)
        internal
        view
        virtual
        returns (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128);

    function mintPosition(MintParams memory params)
        public
        virtual
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @dev Logic is taken from uniswap-v3/core/contracts/libraries/Tick.sol
    function _getFeeGrowthInside(address pool, int24 tickLower, int24 tickUpper)
        private
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        unchecked {
            (, int24 tickCurrent) = getPoolState(pool);

            (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = _getGlobalFeeGrowths(pool);

            (uint256 feeGrowthOutsideLower0X128, uint256 feeGrowthOutsideLower1X128) = _getFeeGrowths(pool, tickLower);
            (uint256 feeGrowthOutsideUpper0X128, uint256 feeGrowthOutsideUpper1X128) = _getFeeGrowths(pool, tickUpper);

            // calculate fee growth below
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tickCurrent >= tickLower) {
                feeGrowthBelow0X128 = feeGrowthOutsideLower0X128;
                feeGrowthBelow1X128 = feeGrowthOutsideLower1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthOutsideLower0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthOutsideLower1X128;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tickCurrent < tickUpper) {
                feeGrowthAbove0X128 = feeGrowthOutsideUpper0X128;
                feeGrowthAbove1X128 = feeGrowthOutsideUpper1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthOutsideUpper0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthOutsideUpper1X128;
            }

            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }

    function getPendingFees(PositionData memory position) public view returns (uint256 amount0, uint256 amount1) {
        // Non-zero positions can't have unclaimed fees by design of position manager
        if (position.liquidity == 0) {
            return (position.tokensOwed0, position.tokensOwed1);
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            _getFeeGrowthInside(getPool(position), position.tickLower, position.tickUpper);
        unchecked {
            // overflow in fee growth subtraction is expected
            amount0 = position.tokensOwed0
                + uint128(
                    Math.mulDiv(
                        feeGrowthInside0X128 - position.feeGrowthInside0LastX128, position.liquidity, FixedPoint128.Q128
                    )
                );
            amount1 = position.tokensOwed1
                + uint128(
                    Math.mulDiv(
                        feeGrowthInside1X128 - position.feeGrowthInside1LastX128, position.liquidity, FixedPoint128.Q128
                    )
                );
        }
    }

    function getTickSpacing(address pool) public view virtual returns (int24);

    function getLowLevelPositionData(address pool, address owner, int24 tickLower, int24 tickUpper)
        public
        view
        virtual
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.20;

import {ERC1155Upgradeable} from "../ERC1155Upgradeable.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 *
 * NOTE: This contract implies a global limit of 2**256 - 1 to the number of tokens
 * that can be minted.
 *
 * CAUTION: This extension should not be added in an upgrade to an already deployed contract.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.ERC1155Supply
    struct ERC1155SupplyStorage {
        mapping(uint256 id => uint256) _totalSupply;
        uint256 _totalSupplyAll;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC1155Supply")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC1155SupplyStorageLocation = 0x4a593662ee04d27b6a00ebb31be7fe0c102c2ade82a7c5d764f2df05dc4e2800;

    function _getERC1155SupplyStorage() private pure returns (ERC1155SupplyStorage storage $) {
        assembly {
            $.slot := ERC1155SupplyStorageLocation
        }
    }

    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Total value of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        ERC1155SupplyStorage storage $ = _getERC1155SupplyStorage();
        return $._totalSupply[id];
    }

    /**
     * @dev Total value of tokens.
     */
    function totalSupply() public view virtual returns (uint256) {
        ERC1155SupplyStorage storage $ = _getERC1155SupplyStorage();
        return $._totalSupplyAll;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_update}.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        ERC1155SupplyStorage storage $ = _getERC1155SupplyStorage();
        super._update(from, to, ids, values);

        if (from == address(0)) {
            uint256 totalMintValue = 0;
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 value = values[i];
                // Overflow check required: The rest of the code assumes that totalSupply never overflows
                $._totalSupply[ids[i]] += value;
                totalMintValue += value;
            }
            // Overflow check required: The rest of the code assumes that totalSupplyAll never overflows
            $._totalSupplyAll += totalMintValue;
        }

        if (to == address(0)) {
            uint256 totalBurnValue = 0;
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 value = values[i];

                unchecked {
                    // Overflow not possible: values[i] <= balanceOf(from, ids[i]) <= totalSupply(ids[i])
                    $._totalSupply[ids[i]] -= value;
                    // Overflow not possible: sum_i(values[i]) <= sum_i(totalSupply(ids[i])) <= totalSupplyAll
                    totalBurnValue += value;
                }
            }
            unchecked {
                // Overflow not possible: totalBurnValue = sum_i(values[i]) <= sum_i(totalSupply(ids[i])) <= totalSupplyAll
                $._totalSupplyAll -= totalBurnValue;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BaseCLAdapter} from "./adapters/BaseCLAdapter.sol";

/// @notice A library to delegate calls to a BaseCLAdapter contract
library CLAdapterWrapper {
    function delegateIncreaseLiquidity(BaseCLAdapter adapter, uint256 tokenId, uint256 amount0, uint256 amount1)
        internal
        returns (uint256 amount0Resulted, uint256 amount1Resulted)
    {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(abi.encodeCall(adapter.increaseLiquidity, (tokenId, amount0, amount1)));
        require(success);
        return abi.decode(result, (uint256, uint256));
    }

    function delegateDecreaseLiquidity(BaseCLAdapter adapter, uint256 tokenId, uint128 liquidity)
        internal
        returns (uint256 amount0Resulted, uint256 amount1Resulted)
    {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(abi.encodeCall(adapter.decreaseLiquidity, (tokenId, liquidity)));
        require(success);
        return abi.decode(result, (uint256, uint256));
    }

    function delegateCollectFees(
        BaseCLAdapter adapter,
        uint256 tokenId,
        uint128 amount0Max,
        uint128 amount1Max,
        address recipient
    ) internal returns (uint256 amount0Resulted, uint256 amount1Resulted) {
        (bool success, bytes memory result) = address(adapter).delegatecall(
            abi.encodeCall(adapter.collectFees, (tokenId, amount0Max, amount1Max, recipient))
        );
        require(success);
        return abi.decode(result, (uint256, uint256));
    }

    function delegateMintPosition(BaseCLAdapter adapter, BaseCLAdapter.MintParams memory params)
        internal
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(abi.encodeCall(adapter.mintPosition, (params)));
        require(success);
        return abi.decode(result, (uint256, uint128, uint256, uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IConverter} from "./IConverter.sol";

interface IAssetConverter {
    error SlippageTooBig(uint256 amountIn, uint256 amountOut);

    struct RouteConverterUpdate {
        address source;
        address destination;
        IConverter converter;
    }

    struct ComplexRouteUpdate {
        address source;
        address destination;
        address[] complexRoutes;
    }

    function routes(address, address) external view returns (IConverter);
    function complexRoutes(address source, address destination) external view returns (address[] memory);

    function updateRoutes(RouteConverterUpdate[] calldata updates) external;
    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) external;

    function swap(address source, address destination, uint256 amountIn, uint256 maxSlippage)
        external
        returns (uint256);

    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IConverter {
    function swap(address source, address destination, uint256 value, address beneficiary) external returns (uint256);

    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.20;

import {IERC3156FlashBorrower} from "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an YLDR Pool.
 */
interface IPool {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the yTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );

    /**
     * @dev Emitted on supplyERC1155()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the yTokens
     * @param tokenId The tokenId supplied
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event SupplyERC1155(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 tokenId,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of yTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on withdrawERC1155()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the withdrawal
     * @param to The beneficiary of the withdrawal, receiving the yTokens
     * @param tokenId The tokenId withdrawn
     * @param amount The amount withdrawn
     */
    event WithdrawERC1155(address indexed reserve, address user, address indexed to, uint256 tokenId, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useYTokens True if the repayment is done using yTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useYTokens
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseERC1155ReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param tokenId The tokenId of token being enabled as collateral
     * @param user The address of the user enabling the usage as collateral
     */
    event ERC1155ReserveUsedAsCollateralEnabled(address indexed reserve, uint256 indexed tokenId, address indexed user);

    /**
     * @dev Emitted on setUserUseERC1155ReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param tokenId The tokenId of token being disabled as collateral
     * @param user The address of the user disabling the usage as collateral
     */
    event ERC1155ReserveUsedAsCollateralDisabled(
        address indexed reserve, uint256 indexed tokenId, address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param openPosition Whether a new borrow position was opened
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        bool openPosition,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveYToken True if the liquidators wants to receive the collateral yTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveYToken
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param collateralTokenId The tokenId of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveNToken True if the liquidators wants to receive the collateral nTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event ERC1155LiquidationCall(
        address indexed collateralAsset,
        uint256 collateralTokenId,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted yTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying yTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the yTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of yTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supplies an `tokenId` of underlying asset into the reserve, receiving in return overlying nTokens.
     * @param asset The address of the underlying asset to supply
     * @param tokenId The tokenId to be supplied
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the nTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of nTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supplyERC1155(address asset, uint256 tokenId, uint256 amount, address onBehalfOf, uint16 referralCode)
        external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the yTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of yTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent yTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole yToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Withdraws an `amount` of underlying asset with `tokenId` from the reserve, burning the equivalent nTokens owned
     * @param asset The address of the underlying asset to withdraw
     * @param tokenId The tokenId to be withdrawn
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole nToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdrawERC1155(address asset, uint256 tokenId, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 variable debt tokens
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     */
    function borrow(address asset, uint256 amount, uint16 referralCode, address onBehalfOf) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     */
    function repay(address asset, uint256 amount, address onBehalfOf) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve yTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual yToken dust balance, if the user yToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @return The final amount repaid
     */
    function repayWithYTokens(address asset, uint256 amount) external returns (uint256);

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveYToken True if the liquidators wants to receive the collateral yTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveYToken
    ) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param collateralTokenId The tokenId of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveNToken True if the liquidators wants to receive the collateral nTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function erc1155LiquidationCall(
        address collateralAsset,
        uint256 collateralTokenId,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveNToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param createPosition Array of boolean values:
     *   false -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   true -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        bool[] calldata createPosition,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an yToken and debt token and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param yTokenAddress The address of the yToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address yTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Initializes a reserve, activating it, assigning an nToken and configuration provider
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param nTokenAddress The address of the nToken that will be assigned to the reserve
     * @param configurationProvider The address of the provider of configuration for the reserve
     */
    function initERC1155Reserve(address asset, address nTokenAddress, address configurationProvider) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice Drop a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropERC1155Reserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     */
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    /**
     * @notice Updates the address of the configuration provider for a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configurationProvider The address of the new configuration provider
     */
    function setERC1155ReserveConfigurationProvider(address asset, address configurationProvider) external;

    /**
     * @notice Updates the liquidation protocol fee for a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param liquidationProtocolFee New liquidation protocol fee
     */
    function setERC1155ReserveLiquidationProtocolFee(address asset, uint256 liquidationProtocolFee) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the list of ERC1155 reserves used by a user
     * @param user The user address
     * @return The list of ERC1155 reserves used as a collateral by a user
     */
    function getUserUsedERC1155Reserves(address user)
        external
        view
        returns (DataTypes.ERC1155ReserveUsageData[] memory);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
     * "dynamic" variable index based on time, current stored index and virtual rate at the current
     * moment (approx. a borrower would get if opening a position). This means that is always used in
     * combination with variable debt supply/balances.
     * If using this function externally, consider that is possible to have an increasing normalized
     * variable debt that is not equivalent to how the variable debt index would be updated in storage
     * (e.g. only updates with non-zero variable debt supply)
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Returns the state and configuration of the ERC1155 reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getERC1155ReserveData(address asset) external view returns (DataTypes.ERC1155ReserveData memory);

    /**
     * @notice Validates and finalizes an yToken transfer
     * @dev Only callable by the overlying yToken of the `asset`
     * @param asset The address of the underlying asset of the yToken
     * @param from The user from which the yTokens are transferred
     * @param to The user receiving the yTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The yToken balance of the `from` user before the transfer
     * @param balanceToBefore The yToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Validates and finalizes an nToken transfer
     * @dev Only callable by the overlying nToken of the `asset`
     * @param asset The address of the underlying asset of the nToken
     * @param from The user from which the nToken are transferred
     * @param to The user receiving the nToken
     * @param ids The ids of tokens being transferred/withdrawn
     * @param amounts The amounts being transferred/withdrawn
     */
    function finalizeERC1155Transfer(
        address asset,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to yToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    /**
     * @notice Updates max amount of ERC1155 collaterals user may have.
     * @dev Only callable by the PoolConfigurator contract
     * @param maxERC1155CollateralReservesNumber The new value
     */
    function updateMaxERC1155CollateralReserves(uint256 maxERC1155CollateralReservesNumber) external;

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Returns the maximum number of ERC1155 collateral reserves which can be used by a single user
     * @return The maximum number of ERC1155 collateral reserves supported
     */
    function MAX_ERC1155_COLLATERAL_RESERVES() external view returns (uint256);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of yTokens
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.20;

import {IERC165, ERC165} from "../../../utils/introspection/ERC165.sol";
import {IERC1155Receiver} from "../IERC1155Receiver.sol";

/**
 * @dev Simple implementation of `IERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.20;

import {IERC721Receiver} from "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or
 * {IERC721-setApprovalForAll}.
 */
abstract contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 internal constant LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FLASHLOAN_ENABLED_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint16 public constant MAX_RESERVES_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv The new ltv
     */
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     */
    function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     */
    function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
        require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

        self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     */
    function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     */
    function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     */
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     */
    function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     */
    function getDecimals(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     */
    function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
        self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     */
    function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     */
    function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
        self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     */
    function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the reserve
     * @param self The reserve configuration
     * @param paused The paused state
     */
    function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
        self.data = (self.data & PAUSED_MASK) | (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the reserve
     * @param self The reserve configuration
     * @return The paused state
     */
    function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     */
    function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
        self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     */
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @notice Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     */
    function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
        require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

        self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @notice Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     */
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCap The borrow cap
     */
    function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap) internal pure {
        require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     */
    function getBorrowCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     */
    function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     */
    function getSupplyCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation protocol fee of the reserve
     * @param self The reserve configuration
     * @param liquidationProtocolFee The liquidation protocol fee
     */
    function setLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self, uint256 liquidationProtocolFee)
        internal
        pure
    {
        require(liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE, Errors.INVALID_LIQUIDATION_PROTOCOL_FEE);

        self.data = (self.data & LIQUIDATION_PROTOCOL_FEE_MASK)
            | (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation protocol fee
     * @param self The reserve configuration
     * @return The liquidation protocol fee
     */
    function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Sets the flashloanable flag for the reserve
     * @param self The reserve configuration
     * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
     */
    function setFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self, bool flashLoanEnabled) internal pure {
        self.data = (self.data & FLASHLOAN_ENABLED_MASK)
            | (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the flashloanable flag for the reserve
     * @param self The reserve configuration
     * @return The flashloanable flag
     */
    function getFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
    }

    /**
     * @notice Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing borrowing enabled
     * @return The state flag representing paused
     */
    function getFlags(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool, bool, bool, bool) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~PAUSED_MASK) != 0
        );
    }

    /**
     * @notice Gets the configuration parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing reserve decimals
     * @return The state param representing reserve factor
     */
    function getParams(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @notice Gets the caps parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing borrow cap
     * @return The state param representing supply cap.
     */
    function getCaps(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256, uint256) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.20;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "../../utils/introspection/ERC165Upgradeable.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
abstract contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155, IERC1155MetadataURI, IERC1155Errors {
    using Arrays for uint256[];
    using Arrays for address[];

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC1155
    struct ERC1155Storage {
        mapping(uint256 id => mapping(address account => uint256)) _balances;

        mapping(address account => mapping(address operator => bool)) _operatorApprovals;

        // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
        string _uri;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC1155")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC1155StorageLocation = 0x88be536d5240c274a3b1d3a1be54482fd9caa294f08c62a7cde569f49a3c4500;

    function _getERC1155Storage() private pure returns (ERC1155Storage storage $) {
        assembly {
            $.slot := ERC1155StorageLocation
        }
    }

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 /* id */) public view virtual returns (string memory) {
        ERC1155Storage storage $ = _getERC1155Storage();
        return $._uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        ERC1155Storage storage $ = _getERC1155Storage();
        return $._balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts.unsafeMemoryAccess(i), ids.unsafeMemoryAccess(i));
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        ERC1155Storage storage $ = _getERC1155Storage();
        return $._operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`. Will mint (or burn) if `from`
     * (or `to`) is the zero address.
     *
     * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement either {IERC1155Receiver-onERC1155Received}
     *   or {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     * - `ids` and `values` must have the same length.
     *
     * NOTE: The ERC-1155 acceptance check is not performed in this function. See {_updateWithAcceptanceCheck} instead.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual {
        ERC1155Storage storage $ = _getERC1155Storage();
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids.unsafeMemoryAccess(i);
            uint256 value = values.unsafeMemoryAccess(i);

            if (from != address(0)) {
                uint256 fromBalance = $._balances[id][from];
                if (fromBalance < value) {
                    revert ERC1155InsufficientBalance(from, fromBalance, value, id);
                }
                unchecked {
                    // Overflow not possible: value <= fromBalance
                    $._balances[id][from] = fromBalance - value;
                }
            }

            if (to != address(0)) {
                $._balances[id][to] += value;
            }
        }

        if (ids.length == 1) {
            uint256 id = ids.unsafeMemoryAccess(0);
            uint256 value = values.unsafeMemoryAccess(0);
            emit TransferSingle(operator, from, to, id, value);
        } else {
            emit TransferBatch(operator, from, to, ids, values);
        }
    }

    /**
     * @dev Version of {_update} that performs the token acceptance check by calling
     * {IERC1155Receiver-onERC1155Received} or {IERC1155Receiver-onERC1155BatchReceived} on the receiver address if it
     * contains code (eg. is a smart contract at the moment of execution).
     *
     * IMPORTANT: Overriding this function is discouraged because it poses a reentrancy risk from the receiver. So any
     * update to the contract state after this function would break the check-effect-interaction pattern. Consider
     * overriding {_update} instead.
     */
    function _updateWithAcceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        _update(from, to, ids, values);
        if (to != address(0)) {
            address operator = _msgSender();
            if (ids.length == 1) {
                uint256 id = ids.unsafeMemoryAccess(0);
                uint256 value = values.unsafeMemoryAccess(0);
                _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
            } else {
                _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, values, data);
            }
        }
    }

    /**
     * @dev Transfers a `value` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     * - `ids` and `values` must have the same length.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the values in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        ERC1155Storage storage $ = _getERC1155Storage();
        $._uri = newuri;
    }

    /**
     * @dev Creates a `value` amount of tokens of type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    /**
     * @dev Destroys a `value` amount of tokens of type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `value` amount of tokens of type `id`.
     */
    function _burn(address from, uint256 id, uint256 value) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `value` amount of tokens of type `id`.
     * - `ids` and `values` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        ERC1155Storage storage $ = _getERC1155Storage();
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        $._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Performs an acceptance check by calling {IERC1155-onERC1155Received} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Performs a batch acceptance check by calling {IERC1155-onERC1155BatchReceived} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Creates an array in memory with only one value for each of the elements provided.
     */
    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //yToken address
        address yTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62: siloed borrowing enabled
        //bit 63: flashloaning enabled
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused
        uint256 data;
    }

    struct ERC1155ReserveData {
        address nTokenAddress;
        address configurationProvider;
        uint256 liquidationProtocolFee;
    }

    struct ERC1155ReserveConfiguration {
        bool isActive;
        bool isFrozen;
        bool isPaused;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct ERC1155ReserveUsageData {
        address asset;
        uint256 tokenId;
    }

    struct UserERC1155ConfigurationMap {
        // List of ERC1155 reserves used by user
        ERC1155ReserveUsageData[] usedERC1155Reserves;
        // Mapping matching given asset and tokenId to index in usedERC1155Reserves array + 1
        // Index 0 is used for not used reserves
        mapping(address asset => mapping(uint256 tokenId => uint256 indexPlus1)) usedERC1155ReservesMap;
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address yTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveYToken;
        address priceOracle;
        address priceOracleSentinel;
    }

    struct ExecuteERC1155LiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        uint256 collateralTokenId;
        address debtAsset;
        address user;
        bool receiveNToken;
        address priceOracle;
        address priceOracleSentinel;
        uint256 maxERC1155CollateralReserves;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteSupplyERC1155Params {
        address asset;
        uint256 tokenId;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
        uint256 maxERC1155CollateralReserves;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        bool useYTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteWithdrawERC1155Params {
        address asset;
        uint256 tokenId;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeERC1155TransferParams {
        address asset;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
        uint256 reservesCount;
        address oracle;
        uint256 maxERC1155CollateralReserves;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        bool[] createPosition;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 reservesCount;
        address addressesProvider;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct ValidateERC1155LiquidationCallParams {
        address collateralReserveAddress;
        uint256 collateralReserveTokenId;
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct ValidateHealthFactorParams {
        UserConfigurationMap userConfig;
        address user;
        uint256 reservesCount;
        address oracle;
    }

    struct CalculateInterestRatesParams {
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalVariableDebt;
        uint256 reserveFactor;
        address reserve;
        address yToken;
    }

    struct InitReserveParams {
        address asset;
        address yTokenAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct InitERC1155ReserveParams {
        address asset;
        address nTokenAddress;
        address configurationProvider;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the YLDR protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_YTOKEN = "11"; // 'The caller of the function is not an YToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = "13"; // 'Invalid return value of the flashloan executor function'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant FLASHLOAN_PREMIUM_INVALID = "19"; // 'Invalid flashloan premium'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant NO_DEBT = "39"; // 'For repayment of debt, the user needs to have debt'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "46"; // 'The collateral chosen cannot be liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant INCONSISTENT_FLASHLOAN_PARAMS = "49"; // 'Inconsistent flashloan parameters'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant DEBT_CEILING_EXCEEDED = "53"; // 'Debt ceiling is exceeded'
    string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = "54"; // 'Claimable rights over underlying not zero (yToken supply or accruedToTreasury)'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant LTV_ZERO = "62"; // 'LTV is zero'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant DEBT_CEILING_NOT_ZERO = "81"; // 'Debt ceiling is not zero'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant FLASHLOAN_DISABLED = "91"; // FlashLoaning for this asset is disabled
    string public constant CALLER_NOT_NTOKEN = "92"; // 'The caller of the function is not an NToken'
    string public constant ERC1155_RESERVE_CANNOT_BE_USED_AS_COLLATERAL = "93"; // ERC1155 reserve can only be supplied if it can be enabled as collateral
    string public constant ERC1155_RESERVE_NOT_USED_AS_COLLATERAL = "94"; // ERC1155 reserve is not used as collateral.
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.20;

import {IERC1155} from "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Arrays.sol)

pragma solidity ^0.8.20;

import {StorageSlot} from "./StorageSlot.sol";
import {Math} from "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}