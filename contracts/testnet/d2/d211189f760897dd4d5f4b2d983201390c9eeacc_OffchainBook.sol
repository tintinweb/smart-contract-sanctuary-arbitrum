// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {EndpointGatedUpgradeable} from "../endpoint/EndpointGatedUpgradeable.sol";
import {Constants} from "../lib/Constants.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {IFeeCalculator} from "../interfaces/IFeeCalculator.sol";
import "../interfaces/IOffchainBook.sol";

contract OffchainBook is IOffchainBook, Initializable, EndpointGatedUpgradeable {
    using SafeCast for uint256;
    using SafeCast for int256;

    IPerpEngine public engine;

    Market private market;
    RiskStore private riskStore;
    FeeStore private feeStore;

    /// @dev total of marker fees and taker fees.
    int256 tradeFeeCollected;
    /// @dev total of execution fees of trader.
    int256 executionFeeCollected;

    mapping(bytes32 orderDigest => int256) public filledAmounts;

    function initialize(
        address _owner,
        address _endpoint,
        IPerpEngine _engine,
        address _indexToken,
        address _quoteToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external initializer {
        if (_owner == address(0)) revert ZeroAddress();
        if (address(_engine) == address(0)) revert ZeroAddress();
        if (_indexToken == address(0)) revert ZeroAddress();
        if (_quoteToken == address(0)) revert ZeroAddress();
        if (_maxLeverage <= 0 || _minSize <= 0 || _tickSize <= 0 || _stepSize <= 0) revert BadMarketConfig();
        if (_maxLeverage > Constants.MAX_LEVERAGE) revert MaxLeverageTooHigh();

        __Ownable_init(address(_engine));
        setEndpoint(address(_endpoint));
        transferOwnership(_owner);

        engine = _engine;

        market = Market({
            indexToken: _indexToken,
            indexDecimals: IERC20Metadata(_indexToken).decimals(),
            quoteToken: _quoteToken,
            quoteDecimals: IERC20Metadata(_quoteToken).decimals(),
            maxLeverage: _maxLeverage,
            minSize: _minSize,
            tickSize: _tickSize,
            stepSize: _stepSize
        });
    }

    // =============== VIEWS FUNCTIONS ===============
    function getRiskStore() external view returns (RiskStore memory) {
        return riskStore;
    }

    function getFeeStore() external view returns (FeeStore memory) {
        return feeStore;
    }

    function getMarket() external view returns (Market memory) {
        return market;
    }

    function getIndexToken() external view returns (address) {
        return market.indexToken;
    }

    function getQuoteToken() external view returns (address) {
        return market.quoteToken;
    }

    function getMaxLeverage() external view returns (int128) {
        return market.maxLeverage;
    }

    function getFees() external view returns (uint256, uint256) {
        return (tradeFeeCollected.toUint256(), executionFeeCollected.toUint256());
    }

    // =============== USER FUNCTIONS ===============
    function matchOrders(IEndpoint.MatchOrders calldata _params) external onlyEndpoint {
        IEndpoint _endpoint = getEndpoint();
        Market memory _market = market;
        IEndpoint.Order memory _taker = _params.taker;
        IEndpoint.Order memory _maker = _params.maker;

        OrderDigest memory _orderDigest =
            OrderDigest({taker: _endpoint.getOrderDigest(_taker), maker: _endpoint.getOrderDigest(_maker)});

        int256 _takerAmount = _taker.amount;
        int256 _makerAmount = _maker.amount;

        /// @dev validate order amount and price
        _validateOrder(_market, _taker, _orderDigest.taker);
        _validateOrder(_market, _maker, _orderDigest.maker);

        /// @dev validate maker and taker condition
        if ((_maker.amount > 0) == (_taker.amount > 0)) revert OrderCannotBeMatched();
        if (_maker.amount > 0) {
            if (_maker.price < _taker.price) revert OrderCannotBeMatched();
        } else {
            if (_maker.price > _taker.price) revert OrderCannotBeMatched();
        }

        /// @dev update position
        _markOrder(_market, _taker, _maker, _orderDigest);

        /// @dev revalidate after position updated
        if (!_isHealthy(_taker.account)) revert NotHealthy();
        if (!_isHealthy(_maker.account)) revert NotHealthy();

        /// @dev update filled amount use to calculate fee
        filledAmounts[_orderDigest.taker] = _takerAmount - _taker.amount;
        filledAmounts[_orderDigest.maker] = _makerAmount - _maker.amount;
    }

    function claimTradeFees() external returns (int256 _feeAmount) {
        (address _bank,,,) = engine.getConfig();
        if (msg.sender != _bank) revert Unauthorized();
        _feeAmount = tradeFeeCollected;
        tradeFeeCollected = 0;

        emit TradeFeeClaimed(_feeAmount);
    }

    function claimExecutionFees() external onlyEndpoint returns (int256 _feeAmount) {
        _feeAmount = executionFeeCollected;
        executionFeeCollected = 0;

        emit ExecutionFeeClaimed(_feeAmount);
    }

    // =============== RESTRICTED ===============
    function modifyMarket(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize) external {
        if (msg.sender != owner() && msg.sender != address(engine)) revert Unauthorized();
        if (_maxLeverage <= 0 || _minSize <= 0 || _tickSize <= 0 || _stepSize <= 0) revert BadMarketConfig();
        if (_maxLeverage > Constants.MAX_LEVERAGE) revert MaxLeverageTooHigh();
        market.maxLeverage = _maxLeverage;
        market.minSize = _minSize;
        market.tickSize = _tickSize;
        market.stepSize = _stepSize;

        emit MarketModified(_maxLeverage, _minSize, _tickSize, _stepSize);
    }

    function modifyRiskStore(RiskStore calldata _riskStore) external {
        if (msg.sender != owner() && msg.sender != address(engine)) revert Unauthorized();
        if (
            _riskStore.longWeightInitial >= _riskStore.longWeightMaintenance
                && _riskStore.shortWeightInitial <= _riskStore.shortWeightMaintenance
        ) revert BadRiskStoreConfig();
        riskStore = _riskStore;
        emit RiskStoreModified(_riskStore);
    }

    function modifyFeeStore(FeeStore calldata _feeStore) external {
        if (msg.sender != owner() && msg.sender != address(engine)) revert Unauthorized();
        if (_feeStore.makerFees < 0 || _feeStore.talkerFees < 0) revert BadFeeStoreConfig();
        feeStore = _feeStore;
        emit FeeStoreModified(_feeStore);
    }

    // =============== INTERNAL FUNCTIONS ===============
    function _markOrder(
        Market memory _market,
        IEndpoint.Order memory _taker,
        IEndpoint.Order memory _maker,
        OrderDigest memory _orderDigest
    ) internal {
        if (_taker.amount == 0) {
            return;
        }

        int256 _takerAmountDelta;
        if (_taker.amount < 0) {
            _takerAmountDelta = _max(_taker.amount, -_maker.amount);
        } else {
            _takerAmountDelta = _min(_taker.amount, -_maker.amount);
        }

        int256 _makerQuoteDelta = _takerAmountDelta * (10 ** Constants.QUOTE_TOKEN_DECIMALS).toInt256() * _maker.price
            / Constants.VALUE_PRECISION.toInt256();
        int256 _takerQuoteDelta = -_makerQuoteDelta;

        _taker.amount -= _takerAmountDelta;
        _maker.amount += _takerAmountDelta;

        IPerpEngine.MarketDelta[] memory _deltas = new IPerpEngine.MarketDelta[](2);
        /// @dev maker maker state
        {
            (int256 _makerFee, int256 _quoteDelta) = _collectFees(_maker.account, _makerQuoteDelta, false, false);
            _deltas[0] = IPerpEngine.MarketDelta({
                market: market.indexToken,
                account: _maker.account,
                amountDelta: -_takerAmountDelta,
                quoteDelta: _quoteDelta
            });
            emit FillOrder(
                _orderDigest.maker,
                _maker.account,
                _maker.price,
                _maker.amount,
                false,
                _makerFee,
                -_takerAmountDelta,
                _quoteDelta
            );
        }
        /// @dev update taker state
        {
            (int256 _takerFee, int256 _quoteDelta) =
                _collectFees(_taker.account, _takerQuoteDelta, true, _isTakerFirst(_orderDigest.taker));
            _deltas[1] = IPerpEngine.MarketDelta({
                market: market.indexToken,
                account: _taker.account,
                amountDelta: _takerAmountDelta,
                quoteDelta: _quoteDelta
            });
            emit FillOrder(
                _orderDigest.taker,
                _taker.account,
                _taker.price,
                _taker.amount,
                true,
                _takerFee,
                _takerAmountDelta,
                _quoteDelta
            );
        }
        engine.applyDeltas(_deltas);
    }

    function _validateOrder(Market memory _market, IEndpoint.Order memory _order, bytes32 _digest) internal view {
        int256 _filledAmount = filledAmounts[_digest];
        _order.amount -= _filledAmount;
        if (_order.reduceOnly) {
            int256 _balance = engine.getBalanceAmount(_market.indexToken, _order.account);
            if ((_order.amount > 0) == (_balance > 0)) {
                _order.amount = 0;
            } else if (_order.amount > 0) {
                _order.amount = _min(_order.amount, -_balance);
            } else if (_order.amount < 0) {
                _order.amount = _max(_order.amount, -_balance);
            }
        }
        if (_order.price <= 0 || _order.price % _market.stepSize != 0) revert InvalidOrderPrice();
        if (_order.amount == 0 || _order.amount % _market.tickSize != 0) revert InvalidOrderAmount();
    }

    function _collectFees(address _account, int256 _amount, bool _isTaker, bool _takerFirst)
        internal
        returns (int256, int256)
    {
        int256 _feeRate = Constants.FEE_PRECISION - _getFeeRate(_account, _isTaker);
        int256 _newAmount =
            (_amount > 0) ? _amount * _feeRate / Constants.FEE_PRECISION : _amount * Constants.FEE_PRECISION / _feeRate;
        int256 _feeAmount = _amount - _newAmount;
        tradeFeeCollected += _feeAmount;
        if (_isTaker && _takerFirst) {
            _newAmount -= Constants.TAKER_SEQUENCER_FEE;
            executionFeeCollected += Constants.TAKER_SEQUENCER_FEE;
        }
        return (_feeAmount, _newAmount);
    }

    function _getFeeRate(address _account, bool _isTaker) internal view returns (int256) {
        (,,, address _feeCalculator) = engine.getConfig();
        if (_feeCalculator != address(0)) {
            return IFeeCalculator(_feeCalculator).getFeeRate(market.indexToken, _account, _isTaker).toInt256();
        }
        return _isTaker ? feeStore.talkerFees : feeStore.makerFees;
    }

    /// @dev ignore, trust endpoint
    function _isHealthy(address /* _account */ ) internal pure returns (bool) {
        return true;
    }

    function _isTakerFirst(bytes32 _digest) internal view returns (bool) {
        return filledAmounts[_digest] == 0;
    }

    function _max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function _min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IEndpoint} from "../interfaces/IEndpoint.sol";

contract EndpointGatedUpgradeable is OwnableUpgradeable {
    IEndpoint private endpoint;

    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) revert Unauthorized();
        _;
    }

    // =============== VIEWS FUNCTIONS ===============
    function getEndpoint() public view returns (IEndpoint) {
        return endpoint;
    }

    // =============== USER FUNCTIONS ===============
    function setEndpoint(address _endpoint) public onlyOwner {
        if (_endpoint == address(0)) revert ZeroAddress();
        endpoint = IEndpoint(_endpoint);
        emit EndpointSet(_endpoint);
    }

    // =============== ERRORS ===============
    error ZeroAddress();
    error Unauthorized();

    // =============== EVENTS ===============
    event EndpointSet(address _endpoint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library Constants {
    uint256 constant VALUE_DECIMALS = 30;
    uint256 constant QUOTE_TOKEN_DECIMALS = 6;

    int256 constant TAKER_SEQUENCER_FEE = 1e5; // 0.1 USDC
    int128 constant MAX_LEVERAGE = 50; // 50x

    uint256 constant VALUE_PRECISION = 10 ** VALUE_DECIMALS;
    int256 constant FEE_PRECISION = 1e10;
    int256 constant PRECISION = 1e18;
    int256 constant QUOTE_PRECISION = 1e18;
}

pragma solidity >=0.8.0;

library SafeCast {
    error Overflow();

    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert Overflow();
        }
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert Overflow();
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFeeCalculator {
    function getFeeRate(address _market, address _account, bool _isTaker) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IEndpoint} from "./IEndpoint.sol";
import {IPerpEngine} from "./IPerpEngine.sol";

interface IOffchainBook {
    struct OrderDigest {
        bytes32 taker;
        bytes32 maker;
    }

    struct Market {
        address indexToken;
        uint8 indexDecimals;
        address quoteToken;
        uint8 quoteDecimals;
        /// @dev max leverage of market, default 20x.
        int128 maxLeverage;
        /// @dev min size of position, ex 0.01 btc-usdc perp.
        int128 minSize;
        /// @dev min price increment of order, ex 1 usdc.
        int128 tickSize;
        /// @dev min size increment of order, ex 0.001 btc-usdc perp.
        int128 stepSize;
    }

    struct RiskStore {
        int64 longWeightInitial;
        int64 shortWeightInitial;
        int64 longWeightMaintenance;
        int64 shortWeightMaintenance;
    }

    struct FeeStore {
        int256 makerFees;
        int256 talkerFees;
    }

    // =============== FUNCTIONS ===============
    function initialize(
        address _owner,
        address _endpoint,
        IPerpEngine _engine,
        address _indexToken,
        address _quoteToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function claimTradeFees() external returns (int256 _feeAmount);
    function claimExecutionFees() external returns (int256 _feeAmount);
    function modifyMarket(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize) external;
    function modifyRiskStore(RiskStore calldata _risk) external;
    function modifyFeeStore(FeeStore calldata _fee) external;
    function matchOrders(IEndpoint.MatchOrders calldata _params) external;

    // =============== VIEWS ===============
    function getRiskStore() external view returns (RiskStore memory);
    function getFeeStore() external view returns (FeeStore memory);
    function getMarket() external view returns (Market memory);
    function getIndexToken() external view returns (address);
    function getQuoteToken() external view returns (address);
    function getMaxLeverage() external view returns (int128);
    function getFees() external view returns (uint256, uint256);

    // =============== ERRORS ===============
    error NotHealthy();
    error InvalidSignature();
    error InvalidOrderPrice();
    error InvalidOrderAmount();
    error OrderCannotBeMatched();
    error BadRiskStoreConfig();
    error BadFeeStoreConfig();
    error BadMarketConfig();
    error MaxLeverageTooHigh();

    // =============== EVENTS ===============
    event TradeFeeClaimed(int256 _feeAmount);
    event ExecutionFeeClaimed(int256 _feeAmount);
    event MarketModified(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize);
    event RiskStoreModified(RiskStore _risk);
    event FeeStoreModified(FeeStore _fee);
    event FillOrder(
        bytes32 indexed _digest,
        address indexed _account,
        int256 _price,
        int256 _amount,
        // whether this order is taking or making
        bool _isTaker,
        // amount paid in fees (in quote)
        int256 _feeAmount,
        // change in this account's base balance from this fill
        int256 _amountDelta,
        // change in this account's quote balance from this fill
        int256 _quoteAmountDelta
    );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IOffchainBook} from "./IOffchainBook.sol";

interface IEndpoint {
    enum TransactionType {
        ExecuteSlowMode,
        UpdateFundingRate,
        WithdrawCollateral,
        MatchOrders,
        SettlePnl,
        ClaimExecutionFees,
        ClaimTradeFees,
        Liquidate
    }

    struct WithdrawCollateral {
        address account;
        uint64 nonce;
        address token;
        uint256 amount;
    }

    struct SignedWithdrawCollateral {
        WithdrawCollateral tx;
        bytes signature;
    }

    struct Liquidate {
        bytes[] priceData;
        address account;
        address market;
        uint64 nonce;
    }

    struct UpdateFundingRate {
        address[] markets;
        int256[] values;
    }

    struct Order {
        address account;
        int256 price;
        int256 amount;
        bool reduceOnly;
        uint64 nonce;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    struct SignedMatchOrders {
        address market;
        SignedOrder taker;
        SignedOrder maker;
    }

    struct MatchOrders {
        address market;
        Order taker;
        Order maker;
    }

    struct SettlePnl {
        address[] markets;
        address account;
    }

    // =============== FUNCTIONS ===============
    function depositCollateral(address _account, uint256 _amount) external;
    function submitTransactions(bytes[] calldata _txs) external;
    function setMarginBank(address _marginBank) external;
    function setPerpEngine(address _perpEngine) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function setPriceFeed(address _priceFeed) external;
    function setSequencer(address _sequencer) external;

    // =============== VIEWS ===============
    function getNonce(address account) external view returns (uint64);
    function getOrderDigest(Order memory _order) external view returns (bytes32);
    function getAllMarkets()
        external
        view
        returns (
            IOffchainBook.Market[] memory _markets,
            IOffchainBook.FeeStore[] memory _fees,
            IOffchainBook.RiskStore[] memory _risks
        );

    // =============== EVENTS ===============
    event MarginBankSet(address indexed _marginBank);
    event SequencerSet(address indexed _sequencer);
    event PerpEngineSet(address indexed _perpEngine);
    event FundingRateManagerSet(address indexed _fundingRateManager);
    event PriceFeedSet(address indexed _fundingRateManager);
    event SubmitTransactions();

    // =============== ERRORS ===============
    error Unauthorized();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidNonce();
    error InvalidSignature();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IOffchainBook} from "./IOffchainBook.sol";
import {IMarginBank} from "./IMarginBank.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IFundingRateManager} from "./IFundingRateManager.sol";
import {IFeeCalculator} from "./IFeeCalculator.sol";

interface IPerpEngine {
    /// @dev data of market.
    struct State {
        int256 availableSettle;
        int256 fundingIndex;
        int256 lastAccrualFundingTime;
    }

    /// @dev balance of user in market
    struct Balance {
        int256 amount;
        int256 quoteAmount;
        int256 fundingIndex;
    }

    struct MarketDelta {
        address market;
        address account;
        int256 amountDelta;
        int256 quoteDelta;
    }

    struct UpdateMarketTx {
        address market;
        int128 maxLeverage;
        int128 minSize;
        int128 tickSize;
        int128 stepSize;
        IOffchainBook.RiskStore riskStore;
        IOffchainBook.FeeStore feeStore;
    }

    // =============== FUNCTIONS ===============
    function addMarket(
        IOffchainBook _book,
        IOffchainBook.RiskStore memory _risk,
        IOffchainBook.FeeStore memory _fee,
        address _indexToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function updateMarket(bytes calldata _params) external;
    function applyDeltas(MarketDelta[] calldata _deltas) external;
    function settlePnl(address[] memory _markets, address _account) external returns (int256 _totalSettled);
    function socializeAccount(address _account, int256 _insurance) external returns (int256);
    function accrueFunding(address _market) external returns (int256);

    // =============== VIEWS ===============
    function getMarketIds() external view returns (address[] memory);
    function getConfig()
        external
        view
        returns (address _bank, address _priceFeed, address _fundingManager, address _feeCalculator);
    function getOffchainBook(address _market) external view returns (address);
    function getBalance(address _market, address _account) external view returns (Balance memory);
    function getBalanceAmount(address _market, address _account) external view returns (int256);
    function getUnRealizedPnl(address[] calldata _markets, address _account)
        external
        view
        returns (int256 _unRealizedPnl);
    function getUnRealizedPnl(address _account) external view returns (int256 _unRealizedPnl);

    // =============== ERRORS ===============
    error DuplicateMarket();
    error InvalidOffchainBook();
    error InvalidDecimals();

    // =============== EVENTS ===============
    event BankSet(address indexed _bank);
    event PriceFeedSet(address indexed _priceFeed);
    event FundingRateManagerSet(address indexed _fundingManager);
    event FeeCalculatorSet(address indexed _fundingManager);
    event MarketAdded(address indexed _indexToken, address indexed _book);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IEndpoint.sol";

interface IMarginBank {
    function handleDepositTransfer(address _account, uint256 _amount) external;

    function withdrawCollateral(IEndpoint.WithdrawCollateral memory _txn) external;

    function liquidate(IEndpoint.Liquidate calldata _txn) external;

    function claimTradeFees() external;

    // EVENTS
    event Deposited(address indexed account, uint256 amount);
    event EndpointSet(address indexed endpoint);
    event Withdrawn(address indexed account, uint256 amount);

    // ERRORS
    error UnknownToken();
    error ZeroAddress();
    error InsufficientFunds();
    error NotUnderMaintenance();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAggregatorV3Interface} from "./IAggregatorV3Interface.sol";

interface IPriceFeed {
    enum PriceSource {
        Pyth,
        Chainlink
    }

    struct MarketConfig {
        /// @dev precision of base token
        uint256 baseUnits;
        /// @dev use chainlink or pyth oracle
        PriceSource priceSource;
        /// @dev chainlink price feed
        IAggregatorV3Interface chainlinkPriceFeed;
        /// @dev market id of pyth
        bytes32 pythId;
    }

    function configMarket(
        address _market,
        PriceSource _priceSource,
        IAggregatorV3Interface _chainlinkPriceFeed,
        bytes32 _pythId
    ) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function updatePrice(bytes[] calldata _data) external payable;

    // =============== VIEW FUNCTIONS ===============
    function getIndexPrice(address _market) external view returns (uint256);
    function getMarkPrice(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error InvalidPythId();
    error UnknownMarket();

    // =============== EVENTS ===============
    event MarketAdded(address indexed _market);
    event FundingRateManagerSet(address indexed _fundingRateManager);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFundingRateManager {
    // =============== FUNCTIONS ===============
    function addMarket(address _market, uint256 _startTime) external;
    function update(address[] calldata _markets, int256[] calldata _values) external;

    // =============== VIEWS ===============
    function PRECISION() external view returns (uint256);
    function FUNDING_INTERVAL() external view returns (uint256);

    function lastFundingRate(address _market) external view returns (int256);
    function nextFundingTime(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error Outdated();
    error OutOfRange();

    error DuplicateMarket();
    error MarketNotExits();
    error InvalidUpdateData();

    // =============== EVENTS ===============
    event MarketAdded(address indexed _market, uint256 _startTime);
    event ValueUpdated(address indexed _market, int256 _value);
    event FundingRateUpdated(address indexed _market, int256 _value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}