// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./PolicyBase.sol";
import {IGmxHelper} from "../Interfaces/IGmxHelper.sol";
import {IAlgoTradeManager} from "../Interfaces/IAlgoTradeManager.sol";
import {IFundManagerFactory} from "../Interfaces/IFundManagerFactory.sol";

/// @title TradeFactorPolicy Contract
/// @notice A policy that restricts the collateral and size of the position to be copied
contract TradeFactorPolicy is PolicyBase {
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    IGmxHelper private gmxHelper;

    mapping(address => uint256) private fundManagerToTradeFactor;

    event TradeSettingsSet(address fundManager, uint256 tradeFactor);

    constructor(
        address _policyManager,
        address _gmxHelper
    )
        // address _gmxHelper
        PolicyBase(_policyManager)
    {
        gmxHelper = IGmxHelper(_gmxHelper);
    }

    function setGmxHelper(address _gmxHelper) external {
        require(
            msg.sender ==
                IFundManagerFactory(
                    IPolicyManager(POLICY_MANAGER).fundManagerFactory()
                ).owner(),
            "setGmxHelper: invalid caller"
        );
        gmxHelper = IGmxHelper(_gmxHelper);
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    function canDisable()
        external
        pure
        virtual
        override
        returns (bool canDisable_)
    {
        return true;
    }

    function addTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external {
        __setTradeSettings(_fundManager, _encodedSettings);
    }

    /** @notice Updates the policy settings for a fund
        @param _fundManager The fund's address address
        @param _encodedSettings Encoded settings to apply to a fund
    */
    function updateTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
        __setTradeSettings(_fundManager, _encodedSettings);
    }

    /// @dev Helper to set the policy settings for a fund
    /// @param _fundManager The fund's address address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function __setTradeSettings(
        address _fundManager,
        bytes memory _encodedSettings
    ) private {
        uint256 tradeFactor = abi.decode(_encodedSettings, (uint256));

        fundManagerToTradeFactor[_fundManager] = tradeFactor;

        emit TradeSettingsSet(_fundManager, tradeFactor);
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier()
        external
        pure
        override
        returns (string memory identifier_)
    {
        return "TRADE_FACTOR";
    }

    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.TradeFactor;

        return implementedHooks_;
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _fundManager The fund manager address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    /// @dev onlyPolicyManager validation not necessary, as state is not updated and no events are fired
    function validateRule(
        address _fundManager,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external view override returns (bool isValid_, bytes memory message) {
        return passesRule(_fundManager, _encodedArgs);
    }

    // / @notice Checks whether a particular condition passes the rule for a particular fund
    // / @param actionId action id
    // / @param _fundManager The fund's address address
    // / @param data validation data
    // / @return isValid_ True if the rule passes
    function passesRule(
        address _fundManager,
        bytes memory data
    ) public view returns (bool isValid_, bytes memory) {
        (uint256 sizeDelta, uint256 collateralDelta) = abi.decode(
            data,
            (uint256, uint256)
        );

        uint256 positionFactor = fundManagerToTradeFactor[_fundManager];

        if (positionFactor != 0) {
            sizeDelta = (sizeDelta * positionFactor) / BASIS_POINTS_DIVISOR;
            collateralDelta =
                (collateralDelta * positionFactor) /
                BASIS_POINTS_DIVISOR;
            return (true, abi.encode(sizeDelta, collateralDelta));
        } else return (false, "");
    }

    function getTradeSettings(
        address _fundManager
    ) external view override returns (bytes memory) {
        return abi.encode(fundManagerToTradeFactor[_fundManager]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPolicyManager} from "../Interfaces/IPolicyManager.sol";

import {IPolicy} from "./IPolicy.sol";

/// @title PolicyBase Contract
/// @notice Abstract base contract for all policies
abstract contract PolicyBase is IPolicy {
    address internal immutable POLICY_MANAGER;

    modifier onlyPolicyManager() {
        require(
            msg.sender == POLICY_MANAGER,
            "Only the PolicyManager can make this call"
        );
        _;
    }

    constructor(address _policyManager) {
        POLICY_MANAGER = _policyManager;
    }

    /// @notice Validates and initializes a policy as necessary prior to fund activation
    /// @dev Unimplemented by default, can be overridden by the policy
    function activateForTradeManager(address) external virtual {
        return;
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    /// @dev False by default, can be overridden by the policy
    function canDisable()
        external
        pure
        virtual
        override
        returns (bool canDisable_)
    {
        return false;
    }

    /// @notice Updates the policy settings for a fund
    /// @dev Disallowed by default, can be overridden by the policy
    function updateTradeSettings(address, bytes calldata) external virtual {
        revert("updateTradeSettings: Updates not allowed for this policy");
    }

    //////////////////////////////
    // VALIDATION DATA DECODING //
    //////////////////////////////

    /// @dev Helper to parse validation arguments from encoded data for min-max leverage policy hook
    function __decodeMinMaxLeverageValidationData(
        bytes memory _validationData
    ) internal pure returns (uint256) {
        return abi.decode(_validationData, (uint256));
    }

    /// @dev Helper to parse validation arguments from encoded data for pre trade policy hook
    function __decodePreTradeValidationData(
        bytes memory _validationData
    )
        internal
        pure
        returns (uint256 typeId_, bytes memory initializationData_)
    {
        return abi.decode(_validationData, (uint256, bytes));
    }

    /// @dev Helper to parse validation arguments from encoded data for max open positions policy hook
    function __decodeOpenPositionsValidationData(
        bytes memory _validationData
    ) internal pure returns (address externalPosition_) {
        return abi.decode(_validationData, (address));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `POLICY_MANAGER` variable value
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() external view returns (address policyManager_) {
        return POLICY_MANAGER;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IGmxVault} from "./IGmxVault.sol";

interface IGmxHelper {
    function tokenDecimals(address) external returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function usdToTokenMin(address, uint256) external returns (uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external returns (bytes32);

    function tokenToUsdMin(address, uint256) external returns (uint256);

    function getMaxPrice(address) external returns (uint256);

    function getMinPrice(address) external returns (uint256);

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function getWethToken() external view returns (address);

    function getGmxDecimals() external view returns (uint256);

    function calculateCollateralDelta(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta
    ) external returns (uint256 collateral);

    function validateLongIncreaseExecution(
        uint256 collateralSize,
        uint256 positionSize,
        address collateralToken,
        address indexToken
    ) external view returns (bool);

    function validateShortIncreaseExecution(
        uint256 collateralSize,
        uint256 positionSize,
        address indexToken
    ) external view returns (bool);

    function gmxVault() external view returns (IGmxVault);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;
import "../Base/AlgoTradingStorage.sol";

interface IAlgoTradeManager {
    function init(address[] memory, address, uint256, uint256) external;

    function fundDeploy(
        string memory _fundName,
        string memory _fundSymbol,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData,
        uint256 _amount,
        AlgoTradingStorage.ExtensionArgs[] memory _swapArgs,
        AlgoTradingStorage.ExtensionArgs[] memory _positionArgs,
        address[] memory _followingTraders
        // bytes memory _gelatoFeeData
    ) external;

    // function setTraderConfigData(
    //     AlgoTradingStorage.MasterTraderConfig memory traderConfigData
    // ) external;

    // function setGelatoTaskFee(uint256) external;

    function vaultProxy() external view returns (address);

    function getPolicyManager() external returns (address);

    function strategyCreator() external returns (address);

    function shouldFollow(address, address, address) external returns (bool);

    function shouldStartCopy(address, bytes memory) external returns (bool);

    function getFundManagerFactory() external view returns (address);

    function followedTrader() external view returns (address);

    // function isFollowedTrader(address) external view returns (bool);

    function getTraderPositionInfo(
        address,
        bytes32
    ) external view returns (AlgoTradingStorage.PositionInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IFundManagerFactory {
    function getProtocolLibForType(uint256) external view returns (address);

    function owner() external view returns (address);

    function isSigner(address) external view returns (bool);

    function isGelatoFeeCollector(address) external view returns (bool);

    function addStrategy() external;

    function removeStrategy() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/** @title PolicyManager Interface
    @notice Interface for the PolicyManager
*/
interface IPolicyManager {
    // When updating PolicyHook, also update these functions in PolicyManager:
    // 1. __getAllPolicyHooks()
    // 2. __policyHookRestrictsCurrentInvestorActions()
    enum PolicyHook {
        MinMaxLeverage,
        MaxOpenPositions,
        PreExecuteTrade,
        TradeFactor,
        MaxAmountPerTrade,
        MinAssetBalances,
        TrailingStopLoss,
        PostExecuteTrade
    }

    function validatePolicies(
        address,
        PolicyHook,
        bytes calldata
    ) external returns (bool, bytes memory);

    function setConfigForFund(
        address _fundManager,
        bytes calldata _configData
    ) external;

    function getEnabledPoliciesForFund(
        address
    ) external view returns (address[] memory);

    function fundManagerFactory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPolicyManager} from "../Interfaces/IPolicyManager.sol";

interface IPolicy {
    function addTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external;

    function canDisable() external pure returns (bool canDisable_);

    function implementedHooks()
        external
        pure
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_);

    function updateTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external;

    function validateRule(
        address _fundManagers,
        IPolicyManager.PolicyHook _hook,
        bytes calldata _encodedArgs
    ) external returns (bool isValid_, bytes memory message);

    function getTradeSettings(
        address _fundManager
    ) external view returns (bytes memory);

    function identifier() external view returns (string memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGmxVault {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    function updateCumulativeFundingRate(address _indexToken) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function positions(bytes32) external view returns (Position memory);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionFee(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address /* _account */,
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BaseStorage.sol";
import {IGmxHelper} from "../Interfaces/IGmxHelper.sol";

/**
 * @title AlgoTradingStorage Base Contract for containing all storage variables
 */
abstract contract AlgoTradingStorage is BaseStorage {
    struct PositionInfo {
        uint256 size;
        uint256 collateral;
    }

    struct TransactionMetaData {
        bytes4 selector;
        bytes32 txHash;
        bool isLong;
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 sizeDelta;
        uint256 executionFee;
        uint256 nonce;
        uint256 deadline;
    }

    struct TransactionMetaDataV2 {
        uint8 orderType;
        bytes32 txHash;
        bool isLong;
        address account;
        address[] addresses; // array of collateralToken, marketAddress
        uint256 amountIn;
        uint256 sizeDelta;
        uint256 executionFee;
        bytes numbers; //abi.encode(sizeInUsd, Collateral,executionPrice, priceMin, priceMax)
        uint256 nonce;
        uint256 deadline;
    }

    struct TradeExecutionInfo {
        bool status;
        uint256 retryCount;
    }

    address public strategyCreator;

    IGmxHelper internal gmxHelper;

    address internal policyManager;

    /**
     * @notice a list of traders whose trades will be copied for the user
     */
    address public followedTrader;

    /**
     * @notice pendingTxHash indicates a transaction of the master trader that is to be copied 
    */
    bytes32 public pendingTxHash;

    mapping(address => mapping(bytes32 => PositionInfo)) public traderPositions;

    /**
     * @dev stores the hashes of relayed txns to avoid replay transaction.
     */
    mapping(bytes32 => TradeExecutionInfo) public relayedTxns;

    mapping(address => uint256) internal _nonces;
    /**
     * @dev This variable becomes true when the master trader takes a position after squaring off
     * for first-time copy trade
     */
    mapping(address => mapping(address => mapping(address => bool)))
        public shouldFollow;

    mapping(address => mapping(bytes => bool)) public shouldStartCopy; //This for v2 trades

    /**
     * @notice Emits after add external addition
     *  @dev emits after successful requesting GMX positions
     *  @param externalPosition external position proxy addres
     *  @param followedTrader  trader address
     *  @param isLong position type
     *  @param indexToken position token
     *  @param selector position direction type (increase or decrease position)
     */
    event LeveragePositionUpdated(
        address externalPosition,
        address followedTrader,
        bool isLong,
        address indexToken,
        bytes4 selector
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../Interfaces/IComptroller.sol";
import "../Interfaces/IVault.sol";
import "../Interfaces/IFundDeployer.sol";
import {IExternalPositionProxy} from "../Interfaces/IExternalPositionProxy.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSProxiable} from "../upgradability/UUPSProxiable.sol";

/**
 * @title BaseStorage Base Contract for containing all storage variables
 */
abstract contract BaseStorage is
    Initializable,
    UUPSProxiable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev struct for callOnExtension methods
     */
    struct ExtensionArgs {
        address _extension;
        uint256 _actionId;
        bytes _callArgs;
    }

    /**
     * @notice address of denomination Asset
     * @dev is set at initializer
     */
    address internal denominationAsset;

    /**
     * @notice address of enzyme fund deployer contract
     * @dev is set at initializer
     */
    address public FUND_DEPLOYER;

    /**
     * @notice address of vault
     */
    address public vaultProxy;

    /**
     * @notice address of the alfred factory
     * @dev is set at initializer
     */
    address internal ALFRED_FACTORY;

    /**
     * @notice share action time lock
     * @dev is set at initializer
     */
    uint256 public shareActionTimeLock;

    /**
     * @notice share action block number difference
     * @dev is set at initializer
     */
    uint256 public shareActionBlockNumberLock;

    /**
    A blockNumber after the last time shares were bought for an account
        that must expire before that account transfers or redeems their shares
    */
    mapping(address => uint256) internal acctToLastSharesBought;

    /**
     * @notice Emits after fund investment
     *  @dev emits after successful asset deposition, shares miniting and creation of LP position
     *  @custom:emittedby addFund function
     *  @param _user the end user interacting with Alfred wrapper
     *  @param _investmentAmount the amount of USDC being deposited
     *  @param _sharesReceived The actual amount of shares received
     */
    event FundsAdded(
        address _user,
        uint256 _investmentAmount,
        uint256 _sharesReceived
    );

    /**
     * @notice Emits at vault creation
     * @custom:emitted by createNewFund function
     * @param _user the end user interacting with Alfred wrapper
     * @param _comptrollerProxy The address of the comptroller deployed for this user
     * @param _vaultProxy The address of the vault deployed for this user
     */
    event VaultCreated(
        address _user,
        address _fundOwner,
        address _comptrollerProxy,
        address _vaultProxy
    );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.*/

pragma solidity 0.8.19;

// import "../vault/IVault.sol";

/// @title IComptroller Interface
/// @author Enzyme Council <[email protected]>
interface IComptroller {
    function activate(bool) external;

    function calcGav() external returns (uint256);

    function calcGrossShareValue() external returns (uint256);

    function callOnExtension(address, uint256, bytes calldata) external;

    function destructActivated(uint256, uint256) external;

    function destructUnactivated() external;

    function getDenominationAsset() external view returns (address);

    function getExternalPositionManager() external view returns (address);

    function vaultCallOnContract(
        address,
        bytes4,
        bytes memory
    ) external returns (bytes memory);

    function getFeeManager() external view returns (address);

    function getFundDeployer() external view returns (address);

    function getGasRelayPaymaster() external view returns (address);

    function getIntegrationManager() external view returns (address);

    function getPolicyManager() external view returns (address);

    function getVaultProxy() external view returns (address);

    function getValueInterpreter() external view returns (address);

    function init(address, uint256) external;

    // function permissionedVaultAction(IVault.VaultAction, bytes calldata) external;

    function preTransferSharesHook(address, address, uint256) external;

    function preTransferSharesHookFreelyTransferable(address) external view;

    function setGasRelayPaymaster(address) external;

    function setVaultProxy(address) external;

    function buySharesOnBehalf(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function redeemSharesOnBehalf(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _payoutAssets,
        uint256[] calldata _payoutAssetPercentages
    ) external returns (uint256[] memory payoutAmounts_);

    function redeemSharesInKindOnBehalf(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _additionalAssets,
        address[] calldata _assetsToSkip
    )
        external
        returns (
            address[] memory payoutAssets_,
            uint256[] memory payoutAmounts_
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.*/

pragma solidity 0.8.19;

// import "../../../../persistent/vault/interfaces/IExternalPositionVault.sol";
// import "../../../../persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
// import "../../../../persistent/vault/interfaces/IMigratableVault.sol";

/// @title IVault Interface
/// @author Enzyme Council <[email protected]>
interface IVault {
    enum VaultAction {
        None,
        // Shares management
        BurnShares,
        MintShares,
        TransferShares,
        // Asset management
        AddTrackedAsset,
        ApproveAssetSpender,
        RemoveTrackedAsset,
        WithdrawAssetTo,
        // External position management
        AddExternalPosition,
        CallOnExternalPosition,
        RemoveExternalPosition
    }

    function addTrackedAsset(address) external;

    function burnShares(address, uint256) external;

    function buyBackProtocolFeeShares(uint256, uint256, uint256) external;

    function callOnContract(
        address,
        bytes calldata
    ) external returns (bytes memory);

    function canManageAssets(address) external view returns (bool);

    function canRelayCalls(address) external view returns (bool);

    function getAccessor() external view returns (address);

    function getOwner() external view returns (address);

    function getWethToken() external view returns (address);

    function getActiveExternalPositions()
        external
        view
        returns (address[] memory);

    function getTrackedAssets() external view returns (address[] memory);

    function isActiveExternalPosition(address) external view returns (bool);

    function isTrackedAsset(address) external view returns (bool);

    function mintShares(address, uint256) external;

    function payProtocolFee() external;

    function receiveValidatedVaultAction(VaultAction, bytes calldata) external;

    function setAccessorForFundReconfiguration(address) external;

    function setSymbol(string calldata) external;

    function transferShares(address, address, uint256) external;

    function withdrawAssetTo(address, address, uint256) external;

    function setNominatedOwner(address) external;

    function setFreelyTransferableShares() external;

    function withdrawAsset(
        address _asset,
        address _target,
        uint256 _amount
    ) external;

    function totalSupply() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

interface IFundDeployer {
    function createNewFund(
        address,
        string memory,
        string memory,
        address,
        uint256,
        bytes memory,
        bytes memory
    ) external returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IExternalPositionProxy {
    function getExternalPositionType() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUtils} from "./UUPSUtils.sol";

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxiable contract.
 */
abstract contract UUPSProxiable {
    /**
     * @dev Get current implementation code address.
     */
    function getCodeAddress() public view returns (address codeAddress) {
        return UUPSUtils.implementation();
    }

    function updateCode(address newAddress) external virtual;

    /**
     * @dev Proxiable UUID marker function, this would help to avoid wrong logic
     *      contract to be used for upgrading.
     *
     * NOTE: The semantics of the UUID deviates from the actual UUPS standard,
     *       where it is equivalent of _IMPLEMENTATION_SLOT.
     */
    function proxiableUUID() public view virtual returns (bytes32);

    /**
     * @dev Update code address function.
     *      It is internal, so the derived contract could setup its own permission logic.
     */
    function _updateCodeAddress(address newAddress) internal {
        // require UUPSProxy.initializeProxy first
        require(
            UUPSUtils.implementation() != address(0),
            "UUPSProxiable: not upgradable"
        );
        require(
            proxiableUUID() == UUPSProxiable(newAddress).proxiableUUID(),
            "UUPSProxiable: not compatible logic"
        );
        require(address(this) != newAddress, "UUPSProxiable: proxy loop");
        UUPSUtils.setImplementation(newAddress);
        emit CodeUpdated(proxiableUUID(), newAddress);
    }

    event CodeUpdated(bytes32 uuid, address codeAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Shared Library
 */
library UUPSUtils {
    /**
     * @dev Implementation slot constant.
     * Using https://eips.ethereum.org/EIPS/eip-1967 standard
     * Storage slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     * (obtained as bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)).
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Get implementation address.
    function implementation() internal view returns (address impl) {
        assembly {
            // solium-disable-line
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address.
    function setImplementation(address codeAddress) internal {
        assembly {
            // solium-disable-line
            sstore(_IMPLEMENTATION_SLOT, codeAddress)
        }
    }
}