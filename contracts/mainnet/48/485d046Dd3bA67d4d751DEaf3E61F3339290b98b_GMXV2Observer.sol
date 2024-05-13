// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

// @title DataStore
// @dev DataStore for all general state values
interface IGmxV2DataStore {
    // @dev get the length of the set
    // @param setKey the key of the set
    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

import "./IGmxV2Price.sol";

interface IGmxV2Market {
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    // @dev struct to store the prices of tokens of a market
    // @param indexTokenPrice price of the market's index token
    // @param longTokenPrice price of the market's long token
    // @param shortTokenPrice price of the market's short token
    struct MarketPrices {
        IGmxV2Price.Props indexTokenPrice;
        IGmxV2Price.Props longTokenPrice;
        IGmxV2Price.Props shortTokenPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxV2Oracle {
    function getRealtimeFeedMultiplier(address dataStore, address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxV2Order {
    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be cancelled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account of the order
    // @param receiver the receiver for any token transfers
    // this field is meant to allow the output of an order to be
    // received by an address that is different from the creator of the
    // order whether this is for swaps or whether the account is the owner
    // of a position
    // for funding fees and claimable collateral, the funds are still
    // credited to the owner of the position indicated by order.account
    // @param callbackContract the contract to call for callbacks
    // @param uiFeeReceiver the ui fee receiver
    // @param market the trading market
    // @param initialCollateralToken for increase orders, initialCollateralToken
    // is the token sent in by the user, the token will be swapped through the
    // specified swapPath, before being deposited into the position as collateral
    // for decrease orders, initialCollateralToken is the collateral token of the position
    // withdrawn collateral from the decrease of the position will be swapped
    // through the specified swapPath
    // for swaps, initialCollateralToken is the initial token sent for the swap
    // @param swapPath an array of market addresses to swap through
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd the requested change in position size
    // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
    // is the amount of the initialCollateralToken sent in by the user
    // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
    // collateralToken to withdraw
    // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
    // in for the swap
    // @param orderType the order type
    // @param triggerPrice the trigger price for non-market orders
    // @param acceptablePrice the acceptable execution price for increase / decrease orders
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    // @param minOutputAmount the minimum output amount for decrease orders and swaps
    // note that for decrease orders, multiple tokens could be received, for this reason, the
    // minOutputAmount value is treated as a USD value for validation in decrease orders
    // @param updatedAtBlock the block at which the order was last updated
    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    // @param isLong whether the order is for a long or short
    // @param shouldUnwrapNativeToken whether to unwrap native tokens before
    // transferring to the user
    // @param isFrozen whether the order is frozen
    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IGmxV2Price.sol";


interface IGmxV2Position {
    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the position's account
    // @param market the position's market
    // @param collateralToken the position's collateralToken
    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    // @param sizeInUsd the position's size in USD
    // @param sizeInTokens the position's size in tokens
    // @param collateralAmount the amount of collateralToken for collateral
    // @param borrowingFactor the position's borrowing factor
    // @param fundingFeeAmountPerSize the position's funding fee per size
    // @param longTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.longToken
    // @param shortTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.shortToken
    // @param increasedAtBlock the block at which the position was last increased
    // @param decreasedAtBlock the block at which the position was last decreased
    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    // @param isLong whether the position is a long or short
    struct Flags {
        bool isLong;
    }

    /** Position Fees */
    // @param affiliate the referral affiliate of the trader
    // @param traderDiscountAmount the discount amount for the trader
    // @param affiliateRewardAmount the affiliate reward amount
    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    // @param fundingFeeAmount the position's funding fee amount
    // @param claimableLongTokenAmount the negative funding fee in long token that is claimable
    // @param claimableShortTokenAmount the negative funding fee in short token that is claimable
    // @param latestLongTokenFundingAmountPerSize the latest long token funding
    // amount per size for the market
    // @param latestShortTokenFundingAmountPerSize the latest short token funding
    // amount per size for the market
    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        IGmxV2Price.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }

    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }


    struct PositionInfo {
        Props position;
        PositionFees fees;
        ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

// @title Price
// @dev Struct for prices
library IGmxV2Price {
    // @param min the min price
    // @param max the max price
    struct Props {
        uint256 min;
        uint256 max;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IGmxV2Position} from "./IGmxV2Position.sol";

import {IGmxV2Market} from "./IGmxV2Market.sol";

import {IGmxV2Order} from "./IGmxV2Order.sol";

interface IGmxV2Reader {
    function getMarket(address dataStore, address key) external view returns (IGmxV2Market.Props memory);

    function getPosition(address dataStore, bytes32 key) external view returns (IGmxV2Position.Props memory);

    function getPositionPnlUsd(
        address dataStore,
        IGmxV2Market.Props memory market,
        IGmxV2Market.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);

    function getAccountPositions(
        address dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2Position.Props[] calldata);

    function getAccountOrders(
        address dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2Order.Props[] memory);

    function getPositionInfo(
        address dataStore,
        address referralStorage,
        bytes32 positionKey,
        IGmxV2Market.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (IGmxV2Position.PositionInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAdapter {
    struct AdapterOperation {
        // id to identify what type of operation the adapter should do
        // this is a generic operation
        uint8 operationId;
        // signature of the funcion
        // abi.encodeWithSignature
        bytes data;
    }

    // receives the operation to perform in the adapter and the ratio to scale whatever needed
    // answers if the operation was successfull
    function executeOperation(
        bool,
        address,
        address,
        uint256,
        AdapterOperation memory
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBaseVault {
    function underlyingTokenAddress() external view returns (address);

    function contractsFactoryAddress() external view returns (address);

    function currentRound() external view returns (uint256);

    function afterRoundBalance() external view returns (uint256);

    function getGmxShortCollaterals() external view returns (address[] memory);

    function getGmxShortIndexTokens() external view returns (address[] memory);

    function getAllowedTradeTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IChainlinkPriceFeed {
    function latestAnswer() external view returns(uint256);

    function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IDynamicValuation {
    struct OracleData {
        address dataFeed;
        uint8 dataFeedDecimals;
        uint32 heartbeat;
        uint8 tokenDecimals;
    }

    error WrongAddress();
    error NotUniqiueValues();

    error BadPrice();
    error TooOldPrice();
    error NoOracleForToken(address token);

    error NoObserver();

    error SequencerDown();
    error GracePeriodNotOver();

    event SetChainlinkOracle(address indexed token, OracleData oracleData);

    event SetGmxObserver(address indexed newGmxObserver);
    event SetGmxV2Observer(address indexed newGmxV2Observer);

    function factory() external view returns (address);

    function decimals() external view returns (uint8);

    function sequencerUptimeFeed() external view returns (address);

    function gmxObserver() external view returns (address);

    function gmxV2Observer() external view returns (address);

    function initialize(
        address _factory,
        address _sequencerUptimeFeed,
        address _gmxObserver
    ) external;

    function setChainlinkPriceFeed(
        address token,
        address priceFeed,
        uint32 heartbeat
    ) external;

    function setGmxObserver(address newValue) external;

    function setGmxV2Observer(address newValue) external;

    function chainlinkOracles(
        address token
    ) external view returns (OracleData memory);

    function getOraclePrice(
        address token,
        uint256 amount
    ) external view returns (uint256);

    function getDynamicValuation(
        address addr
    ) external view returns (uint256 valuation);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IObserver {
    function decimals() external view returns (uint8);

    function getValue(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IBaseVault} from "./IBaseVault.sol";
import {IAdapter} from "./IAdapter.sol";

interface ITraderWallet is IBaseVault {
    function vaultAddress() external view returns (address);

    function traderAddress() external view returns (address);

    function cumulativePendingDeposits() external view returns (uint256);

    function cumulativePendingWithdrawals() external view returns (uint256);

    function lastRolloverTimestamp() external view returns (uint256);

    function gmxShortPairs(address, address) external view returns (bool);

    function gmxShortCollaterals(uint256) external view returns (address);

    function gmxShortIndexTokens(uint256) external view returns (address);

    function initialize(
        address underlyingTokenAddress,
        address traderAddress,
        address ownerAddress
    ) external;

    function setVaultAddress(address vaultAddress) external;

    function setTraderAddress(address traderAddress) external;

    function addGmxShortPairs(
        address[] calldata collateralTokens,
        address[] calldata indexTokens
    ) external;

    function addAllowedTradeTokens(address[] calldata tokens) external;

    function removeAllowedTradeToken(address token) external;

    function removeAllowedTradeTokens(address[] calldata tokens) external;

    function addProtocolToUse(uint256 protocolId) external;

    function removeProtocolToUse(uint256 protocolId) external;

    function traderDeposit(uint256 amount) external;

    function withdrawRequest(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function rollover() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        bool replicate
    ) external;

    function getAdapterAddressPerProtocol(
        uint256 protocolId
    ) external view returns (address);

    function isAllowedTradeToken(address token) external view returns (bool);

    function allowedTradeTokensLength() external view returns (uint256);

    function allowedTradeTokensAt(
        uint256 index
    ) external view returns (address);

    function isTraderSelectedProtocol(
        uint256 protocolId
    ) external view returns (bool);

    function traderSelectedProtocolIdsLength() external view returns (uint256);

    function traderSelectedProtocolIdsAt(
        uint256 index
    ) external view returns (uint256);

    function getTraderSelectedProtocolIds()
        external
        view
        returns (uint256[] memory);

    function getContractValuation() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IGmxV2Oracle} from "../adapters/gmx/interfaces/v2/IGmxV2Oracle.sol";
import {IGmxV2Market} from "../adapters/gmx/interfaces/v2/IGmxV2Market.sol";
import {ITraderWallet} from "../interfaces/ITraderWallet.sol";
import {IDynamicValuation} from "../interfaces/IDynamicValuation.sol";
import {IObserver} from "../interfaces/IObserver.sol";
import {IChainlinkPriceFeed} from "../interfaces/IChainlinkPriceFeed.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGmxV2Reader, IGmxV2Position, IGmxV2Order} from "../adapters/gmx/interfaces/v2/IGmxV2Reader.sol";
import {IGmxV2DataStore} from "../adapters/gmx/interfaces/v2/IGmxV2DataStore.sol";
import {IGmxV2Price} from "../adapters/gmx/interfaces/v2/IGmxV2Price.sol";

contract GMXV2Observer is IObserver, Ownable {
    event SetDynamicValuation(address indexed sender, address newDynamicValuationAddress);
    address public constant gmxV2DataStore =
        0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
    address public constant gmxV2Reader =
        0xf60becbba223EEA9495Da3f606753867eC10d139;
    address public constant gmxV2Oracle =
        0xa11B501c2dd83Acd29F6727570f2502FAaa617F2;
    address public constant gmxV2ReferralStorage =
        0xe6fab3F0c7199b0d34d7FbE83394fc0e0D06e99d;


    /// @notice The decimals amount of current observer for returned USD value
    uint8 public constant override decimals = 30;
    uint8 public constant underlyingTokenDecimals = 6;

    IDynamicValuation public dynamicValuation;

    constructor(address _dynamicValuation) {
        setDynamicValuationAddress(_dynamicValuation);
    }

    function setDynamicValuationAddress(address _newDynamicValuation) public onlyOwner {
        require(_newDynamicValuation != address(0));
        dynamicValuation = IDynamicValuation(_newDynamicValuation);

        emit SetDynamicValuation(msg.sender, _newDynamicValuation);
    }

    /// @notice Evaluates all account positions on GMX along allowed tokens
    /// @param account The account address whose positions will be evaluated
    /// @return Returns positions value in USD scaled to 1e30
    function getValue(
        address account
    ) external view override returns (uint256) {
        uint256 positionsValueUSD = _evaluatePosition(account);
        uint256 increaseOrdersUSD = _evaluateIncreaseOrders(account);
        return
            positionsValueUSD + increaseOrdersUSD;
    }

    function _evaluatePosition(
        address account
    ) internal view returns (uint256) {
        bytes32 accountPositionListKey = getAccountPositionListKey(account);
        IGmxV2Position.Props[] memory positions = IGmxV2Reader(gmxV2Reader).getAccountPositions(
            gmxV2DataStore,
            account,
            0,
            IGmxV2DataStore(gmxV2DataStore).getBytes32Count(accountPositionListKey) // totalPositions
        );

        int256 overallPositionsValueUSD;

        for (uint256 i; i < positions.length; ) {
            IGmxV2Market.Props memory marketData = IGmxV2Reader(gmxV2Reader).getMarket(gmxV2DataStore, positions[i].addresses.market);
            uint256 indexTokenPrice = getTokenPrice(marketData.indexToken);
            uint256 longTokenPrice = getTokenPrice(marketData.longToken);
            uint256 shortTokenPrice = getTokenPrice(marketData.shortToken);

            IGmxV2Market.MarketPrices memory marketPrices = IGmxV2Market.MarketPrices({
                indexTokenPrice: IGmxV2Price.Props({
                    min: indexTokenPrice,
                    max: indexTokenPrice
                }),
                longTokenPrice: IGmxV2Price.Props({
                    min: longTokenPrice,
                    max: longTokenPrice
                }),
                shortTokenPrice: IGmxV2Price.Props({
                    min: shortTokenPrice,
                    max: shortTokenPrice
                })
            });

            bytes32 positionKey =  getPositionKey(account, marketData.marketToken, positions[i].addresses.collateralToken, positions[i].flags.isLong);

            (int256 positionPnlUsd,,) = IGmxV2Reader(gmxV2Reader).getPositionPnlUsd(
                gmxV2DataStore,
                marketData,
                marketPrices,
                positionKey,
                positions[i].numbers.sizeInUsd
            );

            IGmxV2Position.PositionInfo memory positionInfo = IGmxV2Reader(gmxV2Reader).getPositionInfo(
                gmxV2DataStore,
                gmxV2ReferralStorage,
                positionKey,
                marketPrices,
                0,
                address(0),
                true
            );

            /** Collateral + positionPnlUsd - borrowing fee - funding fee */
            overallPositionsValueUSD = overallPositionsValueUSD + int256(positions[i].numbers.collateralAmount * (10**(decimals - underlyingTokenDecimals))) + positionPnlUsd - int256(positionInfo.fees.borrowing.borrowingFeeUsd) - int256(positionInfo.fees.funding.fundingFeeAmount * (10**(decimals - underlyingTokenDecimals)));

            unchecked {
                ++i;
            }
        }

        overallPositionsValueUSD = overallPositionsValueUSD < int256(0) ? int256(0) : overallPositionsValueUSD; 

        return uint256(overallPositionsValueUSD); // scaled 1e30
    }

    function _evaluateIncreaseOrders(
        address account
    ) internal view returns (uint256 increaseOrdersUSD) {
        uint256 maxOrders = 50;
        IGmxV2Order.Props[] memory orders = IGmxV2Reader(gmxV2Reader).getAccountOrders(gmxV2DataStore, account, 0, maxOrders);
        
        for(uint256 i = 0; i < orders.length; i++) {
            increaseOrdersUSD = increaseOrdersUSD + (orders[i].numbers.initialCollateralDeltaAmount * (10**(decimals-underlyingTokenDecimals)));
        }
    }

    function getPositionKey(address _account, address _market, address _colateralToken, bool _isLong) public view returns(bytes32) {
        return keccak256(abi.encode(_account, _market, _colateralToken, _isLong));
    }

    function getAccountPositionListKey(address _account) public view returns(bytes32) {
        return keccak256(abi.encode(keccak256(abi.encode("ACCOUNT_POSITION_LIST")), _account));
    }

    function getTokenPrice(address _indexTokenAddress) private view returns(uint256) {
        IDynamicValuation.OracleData memory oracleData = dynamicValuation.chainlinkOracles(_indexTokenAddress);
        
        uint256 chainlinkPrice = IChainlinkPriceFeed(oracleData.dataFeed).latestAnswer();
        uint256 gmxPricefeedMultiplier = IGmxV2Oracle(gmxV2Oracle).getRealtimeFeedMultiplier(gmxV2DataStore, _indexTokenAddress);

        return chainlinkPrice * gmxPricefeedMultiplier / 1e30;
    }
}