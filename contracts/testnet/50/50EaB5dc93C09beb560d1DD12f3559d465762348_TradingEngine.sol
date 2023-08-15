// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
pragma solidity >=0.8.0;

library Constants {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1e6;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant LIQUIDATION_FEE_DIVISOR = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;

    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant PRICE_PRECISION = 1e12;
    uint256 public constant LP_DECIMALS = 18;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // init set to 1$
    uint256 public constant USD_VALUE_PRECISION = 1e18;

    uint256 public constant TOKEN_PRECISION = 1e18;
    uint256 public constant FEE_PRECISION = 1e6;

    uint8 public constant ORACLE_PRICE_DECIMALS = 18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library Errors {
    string constant ZERO_AMOUNT = "0 amount";
    string constant ZERO_ADDRESS = "0xaddr";
    string constant UNAUTHORIZED = "UNAUTHORIZED";

    string constant MARKET_NOT_LISTED = "TE:Market not listed";
    string constant INVALID_COLLATERAL_TOKEN = "TE:Invalid collateral token";
    string constant INVALID_POSITION_SIZE = "TE:Invalid size";
    string constant EXCEED_LIQUIDITY = "TE:Exceed liquidity";
    string constant POSITION_NOT_EXIST = "TE:Position not exists";
    string constant INVALID_COLLATERAL_DELTA = "TE:Invalid collateralDelta";
    string constant POSITION_NOT_LIQUIDATABLE = "TE:Position not liquidatable";
    string constant EXCEED_MAX_OI = "TE:Exceed max OI";

    string constant INVALID_COLLATERAL_AMOUNT = "Exchange:Invalid collateral amount";
    string constant TRIGGER_PRICE_NOT_PASS = "Exchange:Trigger price not pass";
    string constant TP_SL_NOT_PASS = "Exchange:TP/SL price not pass";
    string constant LOW_EXECUTION_FEE = "Exchange:Low execution fee";
    string constant ORDER_NOT_FOUND = "Exchange:Order not found";
    string constant NOT_ORDER_OWNER = "Exchange:Not order owner";
    string constant INVALID_TP_SL_PRICE = "Exchange:Invalid TP/SL price";

    error InvalidPositionSize();
    error InsufficientCollateral();
    error PriceFeedInActive();
    error PositionNotExist();
    error InvalidCollateralAmount();
    error MarginRatioNotMet();
    error ZeroAddress();
    // Orderbook

    error OrderNotFound(uint256 orderId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library InternalMath {
    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function subMinZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }

    // SPDX-License-Identifier: MIT
    // OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
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
            require(denominator > prod1, "Math: mulDiv overflow");

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Index, FundingMode, IFundingRateModel, PrevFundingState, FundingConfiguration} from "../interfaces/IFundingManager.sol";
import {ITradingEngine} from "../interfaces/ITradingEngine.sol";
import {InternalMath} from "../common/InternalMath.sol";
import {Storage} from "./Storage.sol";

contract FundingManager is Storage {
    using InternalMath for int256;

    uint256 public constant DEFAULT_FUNDING_INTERVAL = 8 hours;

    event UpdateIndex(
        bytes32 indexed marketId,
        uint256 longFunding,
        uint256 shortFunding,
        uint256 longPayout,
        uint256 shortPayout,
        uint256 nInterval
    );
    event FundingPayout(bytes32 indexed marketId, address indexed account, uint256 value);
    event FundingDebtPaid(bytes32 indexed marketId, address indexed account, uint256 value);

    function _updatePayoutIndex(
        Index memory index,
        uint256 fundingRate,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 nInterval,
        FundingMode mode
    ) internal pure {
        if (mode == FundingMode.BothSide) {
            return;
        }
        // TODO : handle initial funding rate for one side get stuck if there is no otherside (longOpenInterest == 0 || shortOpenInterest == 0)

        if (fundingRate > 0 && shortOpenInterest > 0) {
            index.shortPayout += (nInterval * fundingRate * longOpenInterest) / shortOpenInterest;
        } else if (fundingRate < 0 && longOpenInterest > 0) {
            index.longPayout += (nInterval * fundingRate * shortOpenInterest) / longOpenInterest;
        }
    }

    function _updateIndex(
        bytes32 marketId,
        Index memory index,
        uint256 fundingRate,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 nInterval,
        FundingMode mode
    ) internal {
        if (fundingRate > 0) {
            index.longFunding += nInterval * fundingRate;
        } else if (fundingRate < 0) {
            index.shortFunding += nInterval * fundingRate;
        }

        _updatePayoutIndex(
            index,
            fundingRate,
            longOpenInterest,
            shortOpenInterest,
            nInterval,
            mode
        );

        emit UpdateIndex(
            marketId,
            index.longFunding,
            index.shortFunding,
            index.longPayout,
            index.shortPayout,
            nInterval
        );
    }

    function updateIndex(bytes32 marketId) internal returns (Index memory) {
        PrevFundingState memory state = prevFundingStates[marketId];
        Index memory index = _indexes[marketId];
        uint256 longOpenInterest = _markets[marketId].longOpenInterest;
        uint256 shortOpenInterest = _markets[marketId].shortOpenInterest;

        FundingConfiguration memory config = _fundingConfigs[marketId];

        uint256 _now = block.timestamp;

        if (state.timestamp == 0) {
            prevFundingStates[marketId].timestamp = (_now / config.interval) * config.interval;
        } else {
            uint256 nInterval = (_now - state.timestamp) / config.interval;
            if (nInterval == 0) {
                return index;
            }

            int256 nextFundingRate = config.model.getNextFundingRate(
                state,
                longOpenInterest,
                shortOpenInterest
            ); // return fundingRate;
            FundingMode mode = config.model.getFundingMode();

            if (nInterval > 1) {
                // accumulate funding and payout of previous intervals but skip for the current one
                _updateIndex(
                    marketId,
                    index,
                    uint256(state.fundingRate.abs()),
                    state.longOpenInterest,
                    state.shortOpenInterest,
                    nInterval - 1,
                    mode
                );
            }

            _updateIndex(
                marketId,
                index,
                uint256(nextFundingRate.abs()),
                longOpenInterest,
                shortOpenInterest,
                1,
                mode
            );

            // set new state for prevState
            state.fundingRate = nextFundingRate;
            state.timestamp += nInterval * config.interval;
            state.longOpenInterest = longOpenInterest;
            state.shortOpenInterest = shortOpenInterest;

            _indexes[marketId] = index;
            prevFundingStates[marketId] = state;

            return index;
        }

        return index;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketParams, MarketAddresses, Market, PriceFeedType} from "../interfaces/IMarket.sol";
import {Index, FundingMode, IFundingRateModel, PrevFundingState, FundingConfiguration} from "../interfaces/IFundingManager.sol";
import {VaultState} from "../interfaces/ITradingEngine.sol";
import {Position} from "./position/Position.sol";

contract Storage {
    mapping(bytes32 => MarketParams) public marketParams;
    mapping(bytes32 => MarketAddresses) public marketAddresses;
    mapping(bytes32 => address[]) public extraCollaterals;
    mapping(bytes32 => PrevFundingState) public prevFundingStates;
    mapping(bytes32 => bool) public isListed;

    mapping(bytes32 => Index) internal _indexes;
    mapping(address => VaultState) internal _vaultStates;
    mapping(address => bool) internal _allowedVault;

    // Fundings
    mapping(bytes32 => FundingConfiguration) internal _fundingConfigs;

    mapping(bytes32 => Market) internal _markets;
    mapping(bytes32 => Position) internal _positions;
    // map priceFeed => types
    mapping(bytes32 => address) internal _priceFeeds;
    mapping(address => PriceFeedType) internal _priceFeedTypes;

    // marketId -> token -> amount
    mapping(bytes32 => mapping(address => uint256)) internal _feeReserves;
    mapping(address => uint8) internal _decimals;
    mapping(uint8 => bytes32) internal _marketCategories;
    mapping(address => address) internal _stablecoinPriceFeeds;

    address public exchange;
    address public gov;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-LicenseiIdentifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ITradingEngine, IncreasePositionParams, DecreasePositionParams, LiquidatePositionParams} from "../interfaces/ITradingEngine.sol";
import {Index, FundingConfiguration} from "../interfaces/IFundingManager.sol";
import {MarketParams, MarketAddresses, MarketType, PriceFeedType, Market} from "../interfaces/IMarket.sol";
import {FeeLib} from "./fee/Fee.sol";
import {IStandardPriceFeed, INoSpreadPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Storage} from "./Storage.sol";
import {MarketManager} from "./market/MarketManager.sol";
import {FundingManager} from "./FundingManager.sol";
import {Validator} from "./Validator.sol";
import {Position, PositionLib, IncreasePositionRequest, IncreasePositionResult, DecreasePositionRequest, DecreasePositionResult} from "./position/Position.sol";
import {PositionUtils} from "./position/PositionUtils.sol";
import {Errors} from "../common/Errors.sol";
import {Constants} from "../common/Constants.sol";
import {InternalMath} from "../common/InternalMath.sol";

contract TradingEngine is Storage, Validator, FundingManager, ReentrancyGuard {
    using InternalMath for uint256;
    using MarketManager for Market;
    using PositionLib for Position;

    constructor() {
        gov = msg.sender;
    }

    event ExchangeSet(address indexed exchange);

    modifier onlyGov() {
        require(msg.sender == gov, "TE: onlygov");
        _;
    }

    modifier onlyExchange() {
        require(msg.sender == exchange, "TE: onlyexchange");
        _;
    }

    function setExchange(address _exchange) external onlyGov {
        exchange = _exchange;
        emit ExchangeSet(_exchange);
    }

    function setMarketListed(bytes32 marketId, bool flag) external onlyGov {
        isListed[marketId] = flag;
        emit SetMarketListed(marketId, flag);
    }

    function setPriceFeed(
        bytes32 marketId,
        PriceFeedType feedType,
        address priceFeed
    ) external onlyGov {
        _priceFeeds[marketId] = priceFeed;
        _priceFeedTypes[priceFeed] = feedType;

        emit SetPriceFeed(marketId, priceFeed, feedType);
    }

    function _addMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) internal returns (bytes32) {
        bytes32 marketId = MarketManager.addMarket(
            marketParams,
            marketAddresses,
            addresses,
            params
        );

        isListed[marketId] = true;

        _fundingConfigs[marketId] = FundingConfiguration({
            model: addresses.fundingRateModel,
            interval: params.fundingInterval
        });

        _allowedVault[addresses.vault] = addresses.vault != address(0);
        _allowedVault[addresses.quoteVault] = addresses.quoteVault != address(0);

        _priceFeeds[marketId] = addresses.priceFeed;
        _priceFeedTypes[addresses.priceFeed] = params.priceFeedType;

        if (params.marketType == MarketType.Standard && _decimals[addresses.indexToken] == 0) {
            uint8 tokenDecimals = IERC20Metadata(addresses.indexToken).decimals();
            _decimals[addresses.indexToken] = tokenDecimals;
        }

        if (params.marketType == MarketType.Standard && _decimals[addresses.quoteToken] == 0) {
            uint8 tokenDecimals = IERC20Metadata(addresses.quoteToken).decimals();
            _decimals[addresses.quoteToken] = tokenDecimals;
        }

        return marketId;
    }

    function getVault(bytes32 marketId, address collateralToken) external view returns (address) {
        return _getVault(marketId, collateralToken);
    }

    // this function might be reused
    function validatePositionSize(
        bytes32 marketId,
        address collateralToken,
        uint256 size
    ) public view {
        require(isListed[marketId], Errors.MARKET_NOT_LISTED);
        // check if position size doesnt surpass liquidity
        address vault = _getVault(marketId, collateralToken);
        uint256 reserveDelta = _usdToTokenAmountMax(marketId, collateralToken, size);
        // convert to size to token amount
        require(
            _vaultStates[vault].reserveAmount + reserveDelta <= _vaultStates[vault].vaultBalance,
            Errors.EXCEED_LIQUIDITY
        );
        // check doesnt exceed max open interest
    }

    function _getPositionFee(
        bytes32 marketId,
        bool open,
        uint256 sizeDelta
    ) internal view returns (uint256) {
        uint256 feeRate = open ? marketParams[marketId].openFee : marketParams[marketId].closeFee;
        uint256 feeUsd = FeeLib.calculateFee(sizeDelta, feeRate);
        return feeUsd;
    }

    function getVaultAndPositionFee(
        bytes32 marketId,
        address collateralToken,
        bool open,
        uint256 sizeDelta
    ) external view returns (address, uint256, uint256) {
        uint256 feeUsd = _getPositionFee(marketId, open, sizeDelta);

        return (
            _getVault(marketId, collateralToken),
            feeUsd,
            _usdToTokenAmountMax(marketId, collateralToken, feeUsd)
        );
    }

    function _getVault(
        bytes32 marketId,
        address collateralToken
    ) internal view returns (address vault) {
        MarketAddresses memory addresses = marketAddresses[marketId];
        MarketType marketType = marketParams[marketId].marketType;
        // require(collateralToken != address(0), Errors.ZERO_ADDRESS);

        if (marketType == MarketType.Standard) {
            require(
                collateralToken == addresses.indexToken || collateralToken == addresses.quoteToken,
                Errors.INVALID_COLLATERAL_TOKEN
            );
            return collateralToken == addresses.indexToken ? addresses.vault : addresses.quoteVault;
        } else {
            require(collateralToken == addresses.quoteToken, Errors.INVALID_COLLATERAL_TOKEN);
            return addresses.quoteVault;
        }
    }

    function increasePosition(IncreasePositionParams calldata params) external onlyExchange {
        require(isListed[params.marketId], Errors.MARKET_NOT_LISTED);
        Index memory index = updateIndex(params.marketId);

        bytes32 key = PositionUtils.getPositionKey(
            params.marketId,
            params.account,
            params.collateralToken,
            params.isLong
        );

        Position storage position = _positions[key];

        address vault = _getVault(params.marketId, params.collateralToken);

        uint256 vaultBalanceInUsd = _tokenAmountToUsdMin(
            params.marketId,
            params.collateralToken,
            _vaultStates[vault].vaultBalance
        );

        validateIncreaseSizeDelta(
            params.marketId,
            vaultBalanceInUsd,
            params.isLong,
            params.sizeDelta
        );

        IncreasePositionResult memory result = _increasePosition(key, index, params, vault);

        validateLeverage(
            true,
            position.size,
            position.collateralValue,
            marketParams[params.marketId].maxLeverage
        );

        validateExceedMaxOpenInterest(params.marketId, true, position.size, vaultBalanceInUsd);
        // other validation like openinterest, reserve

        emit FeeAndFundings(
            params.marketId,
            key,
            params.openFee,
            result.fundingDebt,
            result.fundingPayout
        );
        emit UpdatePosition(
            params.marketId,
            params.account,
            key,
            params.collateralToken,
            position.size,
            position.collateralValue,
            position.entryPrice,
            position.entryFundingIndex,
            position.entryPayoutIndex
        );
    }

    function decreasePosition(DecreasePositionParams calldata params) external onlyExchange {
        require(isListed[params.marketId], Errors.MARKET_NOT_LISTED);
        Index memory index = updateIndex(params.marketId);

        bytes32 key = PositionUtils.getPositionKey(
            params.marketId,
            params.account,
            params.collateralToken,
            params.isLong
        );

        Position storage position = _positions[key];
        bool isFullyClosed = params.sizeDelta == position.size;
        // if (isFullyClosed) {
        //     require(
        //         params.collateralDelta == position.collateralValue,
        //         Errors.INVALID_COLLATERAL_DELTA
        //     );
        // }

        address vault = _getVault(params.marketId, params.collateralToken);
        require(position.size > 0, Errors.POSITION_NOT_EXIST);

        DecreasePositionResult memory result = _decreasePosition(key, index, params, vault, false);

        if (!isFullyClosed) {
            validateLeverage(
                false,
                position.size,
                position.collateralValue,
                marketParams[params.marketId].maxLeverage
            );
            validateLiquidationPostDecrease(
                position.size,
                position.collateralValue,
                marketParams[params.marketId].maintenanceMarginBps,
                marketParams[params.marketId].liquidationFee
            );
        }

        uint256 payoutAmount = _usdToTokenAmountMin(
            params.marketId,
            params.collateralToken,
            result.payoutValue
        );

        {
            uint256 feeAmount = _usdToTokenAmountMin(
                params.marketId,
                params.collateralToken,
                result.totalFee + result.fundingDebt
            );

            if (result.payoutValue > 0) {
                uint256 collateralAmount = position.collateralAmount;
                uint256 total = feeAmount + payoutAmount;
                bool exceeds = total > collateralAmount;
                uint256 vaultDelta = exceeds ? total - collateralAmount : 0;
                uint256 collateralAmountDelta = exceeds ? collateralAmount : total;

                // if total exceeds collateralAmount, this means this is a loss to the vault
                IVault(vault).updateVault(!exceeds, vaultDelta, feeAmount);
                position.collateralAmount -= collateralAmountDelta;
            } else {
                // payout = 0, means this is a loss to the trader and profit to the vault
                // @suppress-overflow-check
                // feeAmount can > collateralAmountReduced if this is not a full close
                uint256 remain = InternalMath.subMinZero(result.collateralAmountReduced, feeAmount);
                IVault(vault).updateVault(true, remain, feeAmount);
                // @suppress-overflow-check
                // collateralReduced is calculated based on collateralAmount so not possible to verflow
                position.collateralAmount -= result.collateralAmountReduced;
                // result payout value = 0, this means there trader cut loss
            }
        }

        _doTransferOut(vault, params.account, payoutAmount);

        emit FeeAndFundings(
            params.marketId,
            key,
            result.totalFee,
            result.fundingDebt,
            result.fundingPayout
        );

        if (position.size == 0) {
            emit ClosePosition(
                key,
                position.size,
                position.collateralValue,
                params.isLong ? index.longFunding : index.shortFunding,
                params.isLong ? index.longPayout : index.shortPayout
            );

            delete _positions[key];
        } else {
            emit UpdatePosition(
                params.marketId,
                params.account,
                key,
                params.collateralToken,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.entryFundingIndex,
                position.entryPayoutIndex
            );
        }
    }

    function _getUpdateCollateralValue(
        bytes32 marketId,
        address collateralToken,
        bool increase,
        uint256 amount
    ) internal returns (uint256) {
        uint256 price = increase
            ? _getPrice(_getCollateralPriceFeed(collateralToken, marketId), collateralToken, false) // min price
            : _getPrice(_getCollateralPriceFeed(collateralToken, marketId), collateralToken, true); // max price
        uint256 value = _tokenAmountToUsd(collateralToken, price, amount);
        return value;
    }

    function claimFundingPayout(
        bytes32 marketId,
        address collateralToken,
        bool isLong
    ) external nonReentrant {
        address vault = _getVault(marketId, collateralToken);
        bytes32 key = PositionUtils.getPositionKey(marketId, msg.sender, collateralToken, isLong);
        Index memory index = updateIndex(marketId);
        Position storage position = _positions[key];
        if (position.size == 0) {
            revert Errors.PositionNotExist();
        }

        MarketParams memory marketParams = marketParams[marketId];

        uint256 fundingRatePrecision = _fundingConfigs[marketId].model.getFundingRatePrecision();

        (uint256 fundingPayout, ) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            position.size,
            position.isLong,
            fundingRatePrecision
        );

        validateLeverage(true, position.size, position.collateralValue, marketParams.maxLeverage);

        // check is liquidatable instead of validateLiquidation

        uint256 indexPrice = _getPrice(
            _priceFeeds[marketId],
            marketAddresses[marketId].indexToken,
            !position.isLong
        );

        {
            uint256 totalFee = _getTotalFeeDecreasePosition(
                position.collateralValue,
                position.size,
                marketParams.closeFee,
                marketParams.liquidationFee
            );

            if (
                isLiquidatable(
                    position,
                    index,
                    indexPrice,
                    totalFee,
                    marketParams.maintenanceMarginBps,
                    fundingRatePrecision
                )
            ) {
                revert Errors.InsufficientCollateral();
            }
        }

        // update entry payout index
        position.entryPayoutIndex = isLong ? index.longPayout : index.shortPayout;
        uint256 amount = _usdToTokenAmountMin(marketId, collateralToken, fundingPayout);

        uint256 remain = position.collateralAmount;
        if (remain < amount) {
            uint256 delta = amount - remain;
            position.collateralAmount = 0;
            IVault(vault).updateVault(false, delta, 0);
        } else {
            position.collateralAmount -= amount;
        }

        _doTransferOut(vault, msg.sender, amount);

        emit ClaimedFundingPayout(marketId, msg.sender, key, amount);
    }

    function updateCollateral(
        address account,
        bytes32 marketId,
        address collateralToken,
        bool isLong,
        bool increase,
        uint256 amount
    ) external onlyExchange {
        address vault = _getVault(marketId, collateralToken);
        MarketParams memory marketParams = marketParams[marketId];
        if (increase) {
            uint256 collateralAmount = _requireAmount(
                IVault(vault).getAmountInAndUpdateVaultBalance()
            );
            if (collateralAmount < amount) {
                revert Errors.InvalidCollateralAmount();
            }
        }
        Index memory index = updateIndex(marketId);

        uint256 value = _getUpdateCollateralValue(marketId, collateralToken, increase, amount);

        bytes32 key = PositionUtils.getPositionKey(marketId, account, collateralToken, isLong);

        Position storage position = _positions[key];
        if (position.size == 0) {
            revert Errors.PositionNotExist();
        }

        if (increase) {
            position.collateralValue += value;
            position.collateralAmount += amount;
        } else {
            require(position.collateralValue >= value, Errors.INVALID_COLLATERAL_DELTA);
            position.collateralValue -= value;

            uint256 remain = position.collateralAmount;
            if (remain < amount) {
                uint256 delta = amount - remain;
                position.collateralAmount = 0;
                IVault(vault).updateVault(false, delta, 0);
            } else {
                position.collateralAmount -= amount;
            }
        }

        validateLeverage(true, position.size, position.collateralValue, marketParams.maxLeverage);

        {
            uint256 indexPrice = _getPrice(
                _priceFeeds[marketId],
                marketAddresses[marketId].indexToken,
                !position.isLong
            );

            uint256 fundingRatePrecision = _fundingConfigs[marketId]
                .model
                .getFundingRatePrecision();
            uint256 totalFee = _getTotalFeeDecreasePosition(
                position.collateralValue,
                position.size,
                marketParams.closeFee,
                marketParams.liquidationFee
            );

            if (
                isLiquidatable(
                    position,
                    index,
                    indexPrice,
                    totalFee,
                    marketParams.maintenanceMarginBps,
                    fundingRatePrecision
                )
            ) {
                revert Errors.InsufficientCollateral();
            }
        }

        if (!increase) {
            _doTransferOut(vault, account, amount);
        }

        emit UpdateCollateral(marketId, account, key, increase, amount);
    }

    function liquidatePosition(LiquidatePositionParams calldata params) external nonReentrant {
        require(isListed[params.marketId], Errors.MARKET_NOT_LISTED);
        Index memory index = updateIndex(params.marketId);
        bytes32 key = PositionUtils.getPositionKey(
            params.marketId,
            params.account,
            params.collateralToken,
            params.isLong
        );

        Position storage position = _positions[key];
        if (position.size == 0) {
            revert Errors.PositionNotExist();
        }

        DecreasePositionParams memory decreaseParams = DecreasePositionParams({
            marketId: params.marketId,
            account: params.account,
            collateralToken: params.collateralToken,
            sizeDelta: position.size,
            isLong: position.isLong
        });

        address vault = _getVault(params.marketId, params.collateralToken);
        DecreasePositionResult memory result = _decreasePosition(
            key,
            index,
            decreaseParams,
            vault,
            true
        );

        uint256 indexPrice = _getPrice(
            _priceFeeds[params.marketId],
            marketAddresses[params.marketId].indexToken,
            position.isLong
        );

        if (result.fundingDebt > 0) {
            emit FundingDebtPaid(params.marketId, params.account, result.fundingDebt);
        }

        if (result.fundingPayout > 0) {
            emit FundingPayout(params.marketId, params.account, result.fundingPayout);
        }

        (, uint256 liquidationFeeTokens) = calcLiquidationFees(
            params.marketId,
            params.collateralToken,
            result.collateralReduced
        );

        {
            uint256 feeAmount = _usdToTokenAmountMin(
                params.marketId,
                params.collateralToken,
                result.totalFee + result.fundingDebt
            );

            uint256 remain = result.collateralAmountReduced - feeAmount;

            // need to subtract liquidation fee tokens from feeAmount because liquidationFeeTokens will be sent to liquidator
            IVault(vault).updateVault(true, remain, feeAmount - liquidationFeeTokens);
        }

        _doTransferOut(vault, params.feeTo, liquidationFeeTokens);

        emit LiquidatePosition(key, params.account, indexPrice);

        // send funding payout for liquidator
        emit FeeAndFundings(
            params.marketId,
            key,
            result.totalFee,
            result.fundingDebt,
            result.fundingPayout
        );

        delete _positions[key];
    }

    function calcLiquidationFees(
        bytes32 marketId,
        address token,
        uint256 collateralReduced
    ) internal view returns (uint256 inUsd, uint256 inTokens) {
        uint256 liquidationFee = marketParams[marketId].liquidationFee;
        inUsd = FeeLib.calculateFee(collateralReduced, liquidationFee);
        inTokens = _usdToTokenAmountMin(marketId, token, inUsd);
    }

    function _getRealizedPnl(
        int256 _realizedPnl
    ) internal pure returns (bool hasProfit, uint256 amount) {
        if (_realizedPnl > 0) {
            hasProfit = true;
            amount = uint256(_realizedPnl);
        } else {
            hasProfit = false;
            amount = uint256(-_realizedPnl);
        }
    }

    function _doTransferOut(address vault, address to, uint256 amount) internal {
        if (amount > 0) {
            IVault(vault).payout(amount, to);
        }
    }

    function _getTotalFeeDecreasePosition(
        uint256 collateralValue,
        uint256 positionSize,
        uint256 closeFee,
        uint256 liquidationFee
    ) internal pure returns (uint256) {
        uint256 closeFeeUsd = FeeLib.calculateFee(positionSize, closeFee);

        uint256 liquidationFeeUsd = liquidationFee > 0
            ? FeeLib.calculateFee(collateralValue, liquidationFee)
            : 0;

        return liquidationFeeUsd + closeFeeUsd;
    }

    function _decreasePosition(
        bytes32 positionKey,
        Index memory index,
        DecreasePositionParams memory params,
        address vault,
        bool isLiquidate
    ) internal returns (DecreasePositionResult memory result) {
        address priceFeed = _priceFeeds[params.marketId];
        Position storage position = _positions[positionKey];

        uint256 indexPrice = _getPrice(
            priceFeed,
            marketAddresses[params.marketId].indexToken,
            // TODO: check if we should reverse this for close position
            position.isLong
        );

        uint256 totalFee = _getTotalFeeDecreasePosition(
            position.collateralValue,
            // fees over size delta
            params.sizeDelta,
            marketParams[params.marketId].closeFee,
            isLiquidate ? marketParams[params.marketId].liquidationFee : 0
        );

        uint256 fundingRatePrecision = _fundingConfigs[params.marketId]
            .model
            .getFundingRatePrecision();

        if (isLiquidate == true) {
            // validate liquidation
            require(
                isLiquidatable(
                    position,
                    index,
                    indexPrice,
                    totalFee,
                    marketParams[params.marketId].maintenanceMarginBps,
                    fundingRatePrecision
                ),
                Errors.POSITION_NOT_LIQUIDATABLE
            );
        }

        DecreasePositionRequest memory request = DecreasePositionRequest({
            sizeDelta: params.sizeDelta,
            indexPrice: indexPrice,
            totalFee: totalFee,
            fundingRatePrecision: fundingRatePrecision
        });

        result = position.decrease(request, index);

        // increase vault reserve
        _vaultStates[vault].reserveAmount -= result.reserveDelta;
        _markets[params.marketId].updateMarketDecrease(
            result.collateralReduced,
            params.sizeDelta,
            position.isLong
        );

        emit DecreasePosition(params.marketId, params.account, positionKey, params, result);

        // emit LiquidatePosition(key, account, marketAddresses[marketId].indexToken);
    }

    function _getCollateral(
        address collateralToken,
        address vault,
        uint256 price
    ) internal returns (uint256, uint256) {
        uint256 collateralAmount = _requireAmount(IVault(vault).getAmountInAndUpdateVaultBalance());
        uint256 value = _tokenAmountToUsd(collateralToken, price, collateralAmount);
        return (value, collateralAmount);
    }

    function _increasePosition(
        bytes32 positionKey,
        Index memory index,
        IncreasePositionParams calldata params,
        address vault
    ) internal returns (IncreasePositionResult memory result) {
        uint256 minPrice = _getPrice(
            _getCollateralPriceFeed(params.collateralToken, params.marketId),
            params.collateralToken,
            false
        );

        (uint256 collateralValue, uint256 collateralAmount) = _getCollateral(
            params.collateralToken,
            vault,
            minPrice
        );

        {
            uint256 reserveDelta = _usdToTokenAmount(
                params.collateralToken,
                minPrice,
                params.sizeDelta
            );

            IncreasePositionRequest memory args = IncreasePositionRequest({
                // price is the price of index token
                price: _getPrice(
                    _priceFeeds[params.marketId],
                    marketAddresses[params.marketId].indexToken,
                    params.isLong
                ),
                sizeDelta: params.sizeDelta,
                collateralValue: collateralValue,
                collateralAmount: collateralAmount,
                reserveDelta: reserveDelta,
                fundingRatePrecision: _fundingConfigs[params.marketId]
                    .model
                    .getFundingRatePrecision(),
                isLong: params.isLong
            });

            result = _positions[positionKey].increase(args, index);

            // increase vault reserve
            _vaultStates[vault].reserveAmount += reserveDelta;
            _markets[params.marketId].updateMarketIncrease(
                collateralValue,
                params.sizeDelta,
                params.isLong
            );

            emit VaultUpdated(params.marketId, vault, collateralAmount, reserveDelta);
        }

        emit IncreasePosition(
            params.marketId,
            params.account,
            positionKey,
            _tokenAmountToUsd(params.collateralToken, minPrice, params.initialCollateralAmount),
            _getPositionFee(params.marketId, true, params.sizeDelta),
            params,
            result
        );
    }

    // return protocol price feed for stable coins
    function _getCollateralPriceFeed(
        address collateralToken,
        bytes32 marketId
    ) internal view returns (address) {
        address priceFeed = _stablecoinPriceFeeds[collateralToken] != address(0)
            ? _stablecoinPriceFeeds[collateralToken]
            : _priceFeeds[marketId];

        return priceFeed;
    }

    function _getDecimals(address token) internal view returns (uint8) {
        return _decimals[token];
    }

    function _getDecimalsOrCache(address token) internal returns (uint8) {
        uint8 decimals = _decimals[token];
        if (decimals != 0) {
            return decimals;
        }

        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        _decimals[token] = tokenDecimals;
        return tokenDecimals;
    }

    function _requireAmount(uint256 amount) internal pure returns (uint256) {
        require(amount > 0, Errors.ZERO_AMOUNT);
        return amount;
    }

    function updateVaultBalance(address vault, uint256 delta, bool isIncrease) external {
        require(msg.sender == vault, Errors.UNAUTHORIZED);
        require(_allowedVault[vault], Errors.UNAUTHORIZED);
        // require vault is allowed
        if (isIncrease) {
            _vaultStates[vault].vaultBalance += delta;
        } else {
            _vaultStates[vault].vaultBalance -= delta;
        }
    }

    function _usdToTokenAmountMin(
        bytes32 marketId,
        address collateralToken,
        uint256 usd
    ) internal view returns (uint256) {
        address priceFeed = _getCollateralPriceFeed(collateralToken, marketId);
        // get minimum price of collateralToken
        // min price means more usd value
        uint256 maxPrice = _getPrice(priceFeed, collateralToken, false);
        return _usdToTokenAmount(collateralToken, maxPrice, usd);
        // convert scaled amount back to normailized amount
    }

    // Convert USD to token amount
    // if max price => minimum tokens
    // if min price => maximum tokens
    function _usdToTokenAmount(
        address collateralToken,
        uint256 price,
        uint256 usd
    ) internal view returns (uint256) {
        uint8 decimals = _getDecimals(collateralToken);
        return usd.mulDiv(10 ** decimals, price);
        // convert scaled amount back to normailized amount
    }

    function _usdToTokenAmountMax(
        bytes32 marketId,
        address token,
        uint256 usd
    ) internal view returns (uint256) {
        address priceFeed = _getCollateralPriceFeed(token, marketId);
        // get minimum price of collateralToken
        // min price means more usd value
        uint256 minPrice = _getPrice(priceFeed, token, false);
        return _usdToTokenAmount(token, minPrice, usd);
    }

    function _tokenAmountToUsdMin(
        bytes32 marketId,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        address priceFeed = _getCollateralPriceFeed(token, marketId);
        // get maxPrice price of token
        uint256 maxPrice = _getPrice(priceFeed, token, true);
        return _tokenAmountToUsd(token, maxPrice, amount);
    }

    // OK
    function _tokenAmountToUsd(
        address token,
        uint256 price,
        uint256 amount
    ) internal returns (uint256) {
        // scale amount to 18 decimals
        uint256 scaledAmount = amount.mulDiv(price, 10 ** _getDecimalsOrCache(token));
        return scaledAmount;
    }

    // OK
    function _getPrice(
        address priceFeed,
        address token,
        bool isMax
    ) internal view returns (uint256) {
        PriceFeedType priceFeedType = _priceFeedTypes[priceFeed];
        uint256 price;
        if (priceFeedType == PriceFeedType.Standard) {
            price = IStandardPriceFeed(priceFeed).getPrice(token, isMax);
        } else if (priceFeedType == PriceFeedType.StandardNoSpread) {
            price = INoSpreadPriceFeed(priceFeed).getPrice(token);
        }

        require(price > 0, "TradingEngine::INVALID_PRICE");
        return price;
    }

    function getIndexToken(bytes32 marketId) external view returns (address) {
        return marketAddresses[marketId].indexToken;
    }

    function getPriceFeed(
        bytes32 marketId
    ) external view returns (PriceFeedType feedType, address priceFeed) {
        priceFeed = _priceFeeds[marketId];
        feedType = _priceFeedTypes[priceFeed];
    }

    function addMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) external returns (bytes32) {
        if (params.isGoverned) {
            require(msg.sender == gov, "TE:onlyGov");
        }
        return _addMarket(addresses, params);
    }

    function addStableCoinPriceFeed(
        address stablecoin,
        PriceFeedType feedType,
        address priceFeed
    ) external onlyGov {
        _stablecoinPriceFeeds[stablecoin] = priceFeed;
        _priceFeedTypes[priceFeed] = feedType;
    }

    // ================================= Could have but not vital =================================

    function getIndex(bytes32 marketKey) external view returns (Index memory) {
        return _indexes[marketKey];
    }

    function getPosition(bytes32 key) external view returns (Position memory) {
        return _positions[key];
    }

    function getPositionSize(bytes32 key) external view returns (uint256) {
        return _positions[key].size;
    }

    // ================================= Uncessary functions =================================

    function getFundingInterval(bytes32 marketId) external view returns (uint256) {
        return marketParams[marketId].fundingInterval;
    }

    // _usdToTokenAmountMin
    // _usdToTokenAmount
    // _usdToTokenAmountMax
    // _tokenAmountToUsdMin
    // _tokenAmountToUsd
    // _getPriceWithSpread
    // _getPrice(

    // function getFundingInfo(
    //     bytes32 marketId,
    //     bytes32 key
    // ) external view returns (uint256 fundingPayout, uint256 fundingDebt) {
    //     Position memory position = _positions[key];
    //     Index memory index = _indexes[marketId];
    //     (fundingPayout, fundingDebt) = FeeLib.getFunding(
    //         index,
    //         position.entryPayoutIndex,
    //         position.entryFundingIndex,
    //         position.size,
    //         position.isLong,
    //         _fundingConfigs[marketId].model.getFundingRatePrecision()
    //     );
    // }

    // function getPositionKey(
    //     bytes32 marketId,
    //     address account,
    //     address collateralToken,
    //     bool isLong
    // ) external pure returns (bytes32) {
    //     return PositionUtils.getPositionKey(marketId, account, collateralToken, isLong);
    // }

    event UpdatePosition(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        address collateralToken,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryFundingIndex,
        uint256 entryPayoutIndex
    );

    event IncreasePosition(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        uint256 initialCollateralValue,
        uint256 feeUsd,
        IncreasePositionParams params,
        IncreasePositionResult result
    );

    // add realized pnl everytime decreased position
    event DecreasePosition(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        DecreasePositionParams params,
        DecreasePositionResult result
    );

    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 exitFundingIndex,
        uint256 exitPayoutIndex
    );

    event LiquidatePosition(bytes32 key, address account, uint256 indexPrice);
    event VaultUpdated(
        bytes32 marketId,
        address vault,
        uint256 collateralAmount, // TODO: write subgraph, borrowedAmount = reserveDelta - collateralAmount
        uint256 reserveDelta
    );

    event FeeAndFundings(
        bytes32 indexed marketId,
        bytes32 indexed key,
        uint256 fee,
        uint256 fundingDebt,
        uint256 fundingPayout
    );

    event UpdateCollateral(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        bool increase,
        uint256 amount
    );

    event ClaimedFundingPayout(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        uint256 amount
    );

    event SetMarketListed(bytes32 indexed marketId, bool isListed);
    event SetPriceFeed(bytes32 indexed marketId, address priceFeed, PriceFeedType priceFeedType);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Errors} from "../common/Errors.sol";
import {Position, PositionLib} from "./position/Position.sol";
import {Index} from "../interfaces/IFundingManager.sol";
import {FeeLib} from "./fee/Fee.sol";
import {Constants} from "../common/Constants.sol";
import {Storage} from "./Storage.sol";
import {Market} from "../interfaces/IMarket.sol";
import {InternalMath} from "../common/InternalMath.sol";

contract Validator is Storage {
    using InternalMath for uint256;

    function validateIncreaseSizeDelta(
        bytes32 marketId,
        uint256 vaultBalanceInUsd,
        bool isLong,
        uint256 sizeDelta
    ) internal view {
        if (isLong) {
            uint256 maxLongOI = (marketParams[marketId].maxExposureMultiplier *
                vaultBalanceInUsd *
                marketParams[marketId].maxLongShortSkew[0]) / 100;

            require(
                _markets[marketId].longOpenInterest + sizeDelta <= maxLongOI,
                Errors.EXCEED_MAX_OI
            );
        } else {
            uint256 maxShortOI = (marketParams[marketId].maxExposureMultiplier *
                vaultBalanceInUsd *
                marketParams[marketId].maxLongShortSkew[1]) / 100;

            require(
                _markets[marketId].shortOpenInterest + sizeDelta <= maxShortOI,
                Errors.EXCEED_MAX_OI
            );
        }
    }

    function validateExceedMaxOpenInterest(
        bytes32 marketId,
        bool isIncrease,
        uint256 size,
        uint256 vaultBalanceInUsd
    ) internal view {
        if (isIncrease && size == 0) {
            revert Errors.InvalidPositionSize();
        }
        require(
            size <=
                (marketParams[marketId].maxPostionSizeOverVault * vaultBalanceInUsd) /
                    Constants.BASIS_POINTS_DIVISOR,
            "Validator::size exceeds max"
        );
    }

    function validateLeverage(
        bool isIncrease,
        uint256 size,
        uint256 collateralValue,
        uint256 maxLeverage
    ) internal pure {
        if (isIncrease && size == 0) {
            revert Errors.InvalidPositionSize();
        }
        // Drop this condition: Will it affect anything
        // require(size >= collateralValue, "RiskManagement:: invalid leverage");

        require(size <= collateralValue * maxLeverage, "RiskManagement: max leverage exceeded");
    }

    function validateLiquidationPostDecrease(
        uint256 size,
        uint256 collateralValue,
        uint256 maintenanceMarginBps,
        uint256 liquidationFeeBps
    ) internal pure {
        uint256 liquidationFee = FeeLib.calculateFee(collateralValue, liquidationFeeBps);
        uint256 maintenanceMargin = (size * maintenanceMarginBps) / Constants.BASIS_POINTS_DIVISOR;
        int256 remain = collateralValue.toInt256() - liquidationFee.toInt256();

        if (remain < maintenanceMargin.toInt256()) {
            revert Errors.InsufficientCollateral();
        }
    }

    function isLiquidatable(
        Position memory position,
        Index memory index,
        uint256 indexPrice,
        uint256 totalFee,
        uint256 maintenanceMarginBps,
        uint256 fundingRatePrecision
    ) internal pure returns (bool) {
        if (position.size == 0) {
            return false;
        }

        (uint256 fundingPayout, uint256 fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            position.size,
            position.isLong,
            fundingRatePrecision
        );

        int256 pnl = PositionLib.calcPnl(
            position.isLong,
            position.size,
            position.entryPrice,
            indexPrice
        );

        int256 fee = fundingPayout.toInt256() - fundingDebt.toInt256() - totalFee.toInt256();

        uint256 maintenanceMargin = (position.size * maintenanceMarginBps) /
            Constants.BASIS_POINTS_DIVISOR;

        int256 remain = position.collateralValue.toInt256() + pnl + fee;
        return remain < maintenanceMargin.toInt256();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {InternalMath} from "../../common/InternalMath.sol";
import {Index} from "../../interfaces/IFundingManager.sol";
import {Constants} from "../../common/Constants.sol";

library FeeLib {
    using InternalMath for uint256;

    function calculateFee(uint256 size, uint256 rate) internal pure returns (uint256) {
        return size.mulDiv(rate, Constants.FEE_PRECISION);
    }

    function getFundingPayout(
        Index memory index,
        uint256 entryPayoutIndex,
        uint256 positionSize,
        bool isLong,
        uint256 precision
    ) internal pure returns (uint256) {
        uint256 payoutIndex = isLong ? index.longPayout : index.shortPayout;
        require(entryPayoutIndex <= payoutIndex, "FundingManager: invalid entry payout index");
        uint256 diff = payoutIndex - entryPayoutIndex;
        return diff.mulDiv(positionSize, precision);
    }

    function getFundingDebt(
        Index memory index,
        uint256 entryFundingIndex,
        uint256 positionSize,
        bool isLong,
        uint256 precision
    ) internal pure returns (uint256) {
        uint256 fundingIndex = isLong ? index.longFunding : index.shortFunding;
        require(entryFundingIndex <= fundingIndex, "FundingManager: invalid entry funding index");
        uint256 diff = fundingIndex - entryFundingIndex;
        return diff.mulDiv(positionSize, precision);
    }

    function getFunding(
        Index memory index,
        uint256 entryPayoutIndex,
        uint256 entryFundingIndex,
        uint256 positionSize,
        bool isLong,
        uint256 precision
    ) internal pure returns (uint256 payout, uint256 debt) {
        uint256 payoutIndex = isLong ? index.longPayout : index.shortPayout;
        uint256 fundingIndex = isLong ? index.longFunding : index.shortFunding;

        require(entryPayoutIndex <= payoutIndex, "FundingManager: invalid entry payout index");
        require(entryFundingIndex <= fundingIndex, "FundingManager: invalid entry funding index");

        uint256 diffPayoutIndex = payoutIndex - entryPayoutIndex;
        payout = diffPayoutIndex.mulDiv(positionSize, precision);

        uint256 diffFundingIndex = fundingIndex - entryFundingIndex;
        debt = diffFundingIndex.mulDiv(positionSize, precision);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketType, MarketParams, MarketAddresses, Market} from "../../interfaces/IMarket.sol";
import {MarketUtils} from "./MarketUtils.sol";
import {Errors} from "../../common/Errors.sol";
import {console} from "forge-std/console.sol";

library MarketManager {
    event MarketCreated(
        MarketType indexed marketType,
        bytes32 indexed marketId,
        address indexed owner,
        address indexToken,
        address quoteToken,
        bytes32 name,
        bool isGoverned,
        uint8 category,
        uint8 maxLeverage
    );
    event CategoriesUpdated(uint8[] categories, bytes32[] values);

    function _validateMarketAddresses(
        MarketAddresses memory addresses,
        MarketType marketType
    ) internal pure {
        if (marketType == MarketType.Standard) {
            require(addresses.vault != address(0), Errors.ZERO_ADDRESS);
        }

        if (marketType != MarketType.SyntheticNoIndex) {
            require(addresses.indexToken != address(0), Errors.ZERO_ADDRESS);
        }

        require(addresses.quoteToken != address(0), Errors.ZERO_ADDRESS);
        require(addresses.quoteVault != address(0), Errors.ZERO_ADDRESS);
        require(addresses.priceFeed != address(0), Errors.ZERO_ADDRESS);
        require(address(addresses.fundingRateModel) != address(0), Errors.ZERO_ADDRESS);
    }

    function updateMarketIncrease(
        Market storage market,
        uint256 collateralValue,
        uint256 sizeDelta,
        bool isLong
    ) internal {
        if (isLong) {
            market.longOpenInterest += sizeDelta;
        } else {
            market.shortOpenInterest += sizeDelta;
        }

        market.totalCollateralValue += collateralValue;
        market.totalBorrowedValue += (sizeDelta - collateralValue);
    }

    function updateMarketDecrease(
        Market storage market,
        uint256 collateralReduced,
        uint256 sizeDelta,
        bool isLong
    ) internal {
        if (isLong) {
            market.longOpenInterest -= sizeDelta;
        } else {
            market.shortOpenInterest -= sizeDelta;
        }

        market.totalCollateralValue -= collateralReduced;
        market.totalBorrowedValue = market.totalBorrowedValue + collateralReduced - sizeDelta;
    }

    function addMarket(
        mapping(bytes32 => MarketParams) storage marketParams,
        mapping(bytes32 => MarketAddresses) storage marketAddresses,
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) internal returns (bytes32 marketId) {
        require(marketAddresses[marketId].owner == address(0), "MarketManager: market exists");
        _validateMarketAddresses(addresses, params.marketType);

        // Check msg.sender is vault owner
        // we shouldn't allow a user to use protocol's vault for their market

        if (params.maxLongShortSkew[0] > 0 || params.maxLongShortSkew[1] > 0) {
            require(
                params.maxLongShortSkew[0] + params.maxLongShortSkew[1] == 100,
                "MarketManager:invalid long/short skew"
            );
        }

        marketId = MarketUtils.getMarketKey(
            params.marketType,
            addresses.owner,
            addresses.indexToken,
            addresses.quoteToken
        );

        marketParams[marketId] = params;
        marketAddresses[marketId] = addresses;

        emit MarketCreated(
            params.marketType,
            marketId,
            addresses.owner,
            addresses.indexToken,
            addresses.quoteToken,
            params.name,
            params.isGoverned,
            params.category,
            params.maxLeverage
        );
    }

    function setMarketCategories(
        mapping(uint8 => bytes32) storage marketCategories,
        uint8[] calldata categories,
        bytes32[] calldata values
    ) internal {
        for (uint256 i = 0; i < categories.length; i++) {
            marketCategories[categories[i]] = values[i];
        }

        emit CategoriesUpdated(categories, values);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketType} from "../../interfaces/IMarket.sol";

library MarketUtils {
    function getMarketKey(
        MarketType marketType,
        address account,
        address indexToken,
        address stablecoin
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(marketType, account, indexToken, stablecoin));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Index} from "../../interfaces/IFundingManager.sol";
import {Constants} from "../../common/Constants.sol";
import {FundingManager} from "../FundingManager.sol";
import {FeeLib} from "../fee/Fee.sol";
import {InternalMath} from "../../common/InternalMath.sol";

struct Position {
    /// @dev side of the position, long or short
    bool isLong;
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    uint256 collateralAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 entryFundingIndex;
    uint256 entryPayoutIndex;
    uint256 reserveAmount;
}

struct IncreasePositionRequest {
    uint256 price;
    uint256 sizeDelta;
    uint256 collateralValue;
    uint256 collateralAmount;
    uint256 fundingRatePrecision;
    uint256 reserveDelta;
    bool isLong;
}

struct DecreasePositionRequest {
    uint256 sizeDelta;
    uint256 indexPrice;
    uint256 totalFee; // 1e18
    uint256 fundingRatePrecision;
}

struct IncreasePositionResult {
    uint256 fundingPayout;
    uint256 fundingDebt;
    uint256 executedPrice;
}

struct DecreasePositionResult {
    int256 realizedPnl;
    uint256 reserveDelta;
    uint256 payoutValue;
    uint256 collateralReduced;
    uint256 collateralAmountReduced;
    uint256 totalFee;
    uint256 fundingPayout;
    uint256 fundingDebt;
    uint256 executedPrice;
}

library PositionLib {
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    function increase(
        Position storage position,
        IncreasePositionRequest memory params,
        Index memory index
    ) internal returns (IncreasePositionResult memory result) {
        uint256 size = position.size;
        // set entry price
        if (size == 0) {
            position.entryPrice = params.price;
        } else {
            position.entryPrice = getNextAveragePrice(
                size,
                position.entryPrice,
                params.isLong,
                params.price,
                params.sizeDelta
            );
        }
        (uint256 fundingPayout, uint256 fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            size,
            position.isLong,
            params.fundingRatePrecision
        );

        uint256 nextCollateralValue = InternalMath.subMinZero(
            position.collateralValue + params.collateralValue + fundingPayout,
            fundingDebt
        );

        position.collateralValue = nextCollateralValue;
        position.size += params.sizeDelta;
        position.entryFundingIndex = params.isLong ? index.longFunding : index.shortFunding;
        position.entryPayoutIndex = params.isLong ? index.longPayout : index.shortPayout;
        position.isLong = params.isLong;
        position.reserveAmount += params.reserveDelta;

        position.collateralAmount += params.collateralAmount;

        result.fundingPayout = fundingPayout;
        result.fundingDebt = fundingDebt;
        result.executedPrice = params.price;
    }

    function decrease(
        Position storage position,
        DecreasePositionRequest memory params,
        Index memory index
    ) internal returns (DecreasePositionResult memory result) {
        require(position.size >= params.sizeDelta, "Position:decrease: insufficient position size");
        // require(
        //     position.collateralValue >= params.collateralDelta,
        //     "Position:decrease: insufficient collateral"
        // );

        uint256 size = position.size;

        int256 pnl = calcPnl(
            position.isLong,
            position.size,
            position.entryPrice,
            params.indexPrice
        );

        result.realizedPnl = (pnl * toInt256(params.sizeDelta)) / toInt256(position.size);

        (result.fundingPayout, result.fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            size,
            position.isLong,
            params.fundingRatePrecision
        );

        uint256 collateralDelta = params.sizeDelta == size ? position.collateralValue : 0;
        uint256 nextCollateralValue = position.collateralValue - collateralDelta;

        int256 payoutValueInt = result.realizedPnl +
            toInt256(collateralDelta) +
            toInt256(result.fundingPayout) -
            toInt256(result.fundingDebt) -
            toInt256(params.totalFee);

        if (payoutValueInt < 0) {
            // if payoutValue is negative, deduct uncovered lost from collateral
            // set a cap zero for the substraction to avoid underflow
            nextCollateralValue = InternalMath.subMinZero(
                nextCollateralValue,
                uint256(InternalMath.abs(payoutValueInt))
            );
        }

        result.reserveDelta = (position.reserveAmount * params.sizeDelta) / position.size;
        result.payoutValue = payoutValueInt > 0 ? uint256(payoutValueInt) : 0;
        result.collateralReduced = position.collateralValue - nextCollateralValue;
        result.totalFee = params.totalFee;
        result.executedPrice = params.indexPrice;
        bool isLong = position.isLong;
        if (result.collateralReduced > 0) {
            result.collateralAmountReduced =
                (position.collateralAmount * result.collateralReduced) /
                position.collateralValue;
            // position.collateralAmount -= result.collateralAmountReduced;
        }

        position.entryFundingIndex = isLong ? index.longFunding : index.shortFunding;
        position.entryPayoutIndex = isLong ? index.longPayout : index.shortPayout;
        position.size -= params.sizeDelta;
        position.collateralValue = nextCollateralValue;
        position.reserveAmount = position.reserveAmount - result.reserveDelta;
    }

    function getFundingFeeValue(
        uint256 _entryFundingIndex,
        uint256 _nextFundingIndex,
        uint256 _positionSize,
        uint256 _precision
    ) internal pure returns (uint256) {
        return (_positionSize * (_nextFundingIndex - _entryFundingIndex)) / _precision;
    }

    function calcMarginFees(
        Position memory position,
        uint256 _positionFee,
        uint256 _sizeDelta,
        uint256 _nextFundingIndex,
        uint256 _fundingRatePrecision
    ) internal pure returns (uint256) {
        uint256 positionFee = (_sizeDelta * _positionFee) / Constants.FEE_PRECISION;
        uint256 fundingFee = getFundingFeeValue(
            position.entryFundingIndex,
            _nextFundingIndex,
            position.size,
            _fundingRatePrecision
        );

        return positionFee + fundingFee;
    }

    function calcPnl(
        bool _isLong,
        uint256 _positionSize,
        uint256 _entryPrice,
        uint256 _nextPrice
    ) internal pure returns (int256) {
        if (_positionSize == 0) {
            return 0;
        }

        if (_isLong) {
            int256 priceDelta = int256(_nextPrice) - int256(_entryPrice);

            return (priceDelta * int256(_positionSize)) / int256(_entryPrice);
        }

        int256 priceDeltaShort = int256(_entryPrice) - int256(_nextPrice);
        return (priceDeltaShort * int256(_positionSize)) / int256(_entryPrice);

        // TODO: GMX handle front running bot
        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        // uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_indexToken];
        // if (hasProfit && delta.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)) {
        //     delta = 0;
        // }
    }

    function getNextAveragePrice(
        uint256 _size,
        uint256 _entryPrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) internal pure returns (uint256) {
        if (_sizeDelta == 0) {
            return _entryPrice;
        }

        int256 pnl = calcPnl(_isLong, _size, _entryPrice, _nextPrice);

        uint256 nextSize = _size + _sizeDelta;
        int256 divisor = int256(nextSize) + pnl; // always > 0
        return (_nextPrice * nextSize) / uint256(divisor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library PositionUtils {
    function getPositionKey(
        bytes32 marketId,
        address account,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(marketId, account, collateralToken, isLong));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

enum FundingMode {
    SingleSide,
    BothSide
}

struct Index {
    uint256 longPayout;
    uint256 shortPayout;
    uint256 longFunding;
    uint256 shortFunding;
}

struct FundingConfiguration {
    IFundingRateModel model;
    uint256 interval;
}

// state of previous funding interval
struct PrevFundingState {
    uint256 timestamp;
    uint256 longOpenInterest;
    uint256 shortOpenInterest;
    int256 fundingRate;
}

interface IFundingRateModel {
    function getNextFundingRate(
        PrevFundingState memory prevState,
        uint256 longOpenInterest,
        uint256 shortOpenInterest
    ) external view returns (int256);

    function getFundingMode() external view returns (FundingMode mode);

    function getFundingRatePrecision() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IFundingRateModel} from "./IFundingManager.sol";

enum MarketType {
    Standard,
    Synthetic,
    SyntheticNoIndex // synthetic market without index token. For example: commodities/ Forex
}

enum PriceFeedType {
    Standard,
    StandardNoSpread,
    Chainlink
}

struct MarketAddresses {
    address owner;
    address indexToken;
    // vault is address 0 for synthetic markets
    address vault;
    address quoteToken;
    address quoteVault;
    address priceFeed;
    IFundingRateModel fundingRateModel;
}

struct MarketParams {
    bytes32 name;
    // list of two number, the first for index token liquidity providers, the second is for stablecoinVault liquidity providers
    uint8[2] feeDistributionWeights; // 20 , 30
    uint8[2] maxLongShortSkew; // Don'' set item[0] + item[1] should equal 100
    uint16 maintenanceMarginBps;
    uint16 liquidationFee; // liquidationFee rate over collateralValue
    uint16 maxPostionSizeOverVault; // 1% // bps
    uint16 openFee; // rate - over size, bps
    uint16 closeFee; // rate - over size, bps
    uint32 fundingInterval; // default 8 hours
    uint8 maxLeverage;
    uint8 maxExposureMultiplier; // 1 - 3 // max OI is 3x of the total collateral, default: 1
    uint8 category;
    MarketType marketType;
    PriceFeedType priceFeedType;
    bool isGoverned;
}

struct Market {
    uint256 totalBorrowedValue;
    uint256 totalCollateralValue;
    uint256 longOpenInterest;
    uint256 shortOpenInterest;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IStandardPriceFeed {
    function getPrice(address token, bool isMax) external view returns (uint256);

    function setPrices(address[] calldata tokens, uint256[] calldata prices) external;
}

interface INoSpreadPriceFeed {
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketParams, MarketAddresses, MarketType, PriceFeedType, Market} from "../interfaces/IMarket.sol";

struct IncreasePositionParams {
    bytes32 marketId;
    uint256 sizeDelta;
    uint256 openFee;
    uint256 initialCollateralAmount;
    address account;
    address collateralToken;
    bool isLong;
}

struct DecreasePositionParams {
    bytes32 marketId;
    address account;
    address collateralToken;
    uint256 sizeDelta;
    bool isLong;
}

struct LiquidatePositionParams {
    bytes32 marketId;
    address account;
    address collateralToken;
    bool isLong;
    address feeTo;
}

struct VaultState {
    /// @notice amount of token deposited (via adding liquidity or increasing long position)
    uint256 vaultBalance;
    /// @notice amount of token reserved for paying out when user takes profit, is the amount of tokens borrowed plus long position collateral
    uint256 reserveAmount;
}

interface ITradingEngine {
    function updateVaultBalance(address token, uint256 delta, bool isIncrease) external;

    function getPositionSize(bytes32 key) external view returns (uint256);

    function increasePosition(IncreasePositionParams calldata params) external;

    function decreasePosition(DecreasePositionParams calldata params) external;

    function getVault(bytes32 marketId, address collateralToken) external view returns (address);

    function getPriceFeed(
        bytes32 marketId
    ) external view returns (PriceFeedType feedType, address priceFeed);

    function getVaultAndPositionFee(
        bytes32 marketId,
        address collateralToken,
        bool open,
        uint256 sizeDelta
    ) external view returns (address vault, uint256 feesInUsd, uint256 feesInTokens);

    function getIndexToken(bytes32 marketId) external view returns (address);

    function validatePositionSize(
        bytes32 marketId,
        address collateralToken,
        uint256 size
    ) external view;

    function getPositionKey(
        bytes32 marketId,
        address account,
        address collateralToken,
        bool isLong
    ) external returns (bytes32);

    function addMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) external returns (bytes32);

    function setExchange(address exchange) external;

    function updateCollateral(
        address account,
        bytes32 marketId,
        address collateralToken,
        bool isLong,
        bool increase,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IVault {
    function getAmountInAndUpdateVaultBalance() external returns (uint256);

    function payout(uint256 amount, address receiver) external;

    function updateVault(bool hasProfit, uint256 pnl, uint256 fee) external;

    function deposit(uint256 amount, address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}