// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {LPPriceFeed} from "../LPPriceFeed.sol";
import {PriceFeedParams} from "../PriceFeedParams.sol";
import {ICurvePool} from "../../interfaces/curve/ICurvePool.sol";
import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";
import {WAD} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

/// @title Curve stable LP price feed
/// @dev For stableswap pools, aggregate is simply the minimum of underlying tokens prices
/// @dev Older pools may be decoupled from their LP token, so constructor accepts both token and pool
contract CurveStableLPPriceFeed is LPPriceFeed {
    uint256 public constant override version = 3_00;
    PriceFeedType public immutable override priceFeedType;

    uint16 public immutable nCoins;

    address public immutable priceFeed0;
    uint32 public immutable stalenessPeriod0;
    bool public immutable skipCheck0;

    address public immutable priceFeed1;
    uint32 public immutable stalenessPeriod1;
    bool public immutable skipCheck1;

    address public immutable priceFeed2;
    uint32 public immutable stalenessPeriod2;
    bool public immutable skipCheck2;

    address public immutable priceFeed3;
    uint32 public immutable stalenessPeriod3;
    bool public immutable skipCheck3;

    constructor(
        address addressProvider,
        uint256 lowerBound,
        address _token,
        address _pool,
        PriceFeedParams[4] memory priceFeeds
    )
        LPPriceFeed(addressProvider, _token, _pool) // U:[CRV-S-1]
        nonZeroAddress(priceFeeds[0].priceFeed) // U:[CRV-S-2]
        nonZeroAddress(priceFeeds[1].priceFeed) // U:[CRV-S-2]
    {
        priceFeed0 = priceFeeds[0].priceFeed;
        priceFeed1 = priceFeeds[1].priceFeed;
        priceFeed2 = priceFeeds[2].priceFeed;
        priceFeed3 = priceFeeds[3].priceFeed;

        stalenessPeriod0 = priceFeeds[0].stalenessPeriod;
        stalenessPeriod1 = priceFeeds[1].stalenessPeriod;
        stalenessPeriod2 = priceFeeds[2].stalenessPeriod;
        stalenessPeriod3 = priceFeeds[3].stalenessPeriod;

        nCoins = priceFeed2 == address(0) ? 2 : (priceFeed3 == address(0) ? 3 : 4); // U:[CRV-S-2]

        skipCheck0 = _validatePriceFeed(priceFeed0, stalenessPeriod0);
        skipCheck1 = _validatePriceFeed(priceFeed1, stalenessPeriod1);
        skipCheck2 = nCoins > 2 ? _validatePriceFeed(priceFeed2, stalenessPeriod2) : false;
        skipCheck3 = nCoins > 3 ? _validatePriceFeed(priceFeed3, stalenessPeriod3) : false;

        priceFeedType = nCoins == 2
            ? PriceFeedType.CURVE_2LP_ORACLE
            : (nCoins == 3 ? PriceFeedType.CURVE_3LP_ORACLE : PriceFeedType.CURVE_4LP_ORACLE);

        _setLimiter(lowerBound); // U:[CRV-S-1]
    }

    function getAggregatePrice() public view override returns (int256 answer) {
        answer = _getValidatedPrice(priceFeed0, stalenessPeriod0, skipCheck0); // U:[CRV-S-2]

        int256 answer2 = _getValidatedPrice(priceFeed1, stalenessPeriod1, skipCheck1);
        if (answer2 < answer) answer = answer2; // U:[CRV-S-2]

        if (nCoins > 2) {
            answer2 = _getValidatedPrice(priceFeed2, stalenessPeriod2, skipCheck2);
            if (answer2 < answer) answer = answer2; // U:[CRV-S-2]

            if (nCoins > 3) {
                answer2 = _getValidatedPrice(priceFeed3, stalenessPeriod3, skipCheck3);
                if (answer2 < answer) answer = answer2; // U:[CRV-S-2]
            }
        }
    }

    function getLPExchangeRate() public view override returns (uint256) {
        return uint256(ICurvePool(lpContract).get_virtual_price()); // U:[CRV-S-1]
    }

    function getScale() public pure override returns (uint256) {
        return WAD; // U:[CRV-S-1]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ILPPriceFeed} from "../interfaces/ILPPriceFeed.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import {ACLNonReentrantTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLNonReentrantTrait.sol";
import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";
import {
    IAddressProviderV3, AP_PRICE_ORACLE
} from "@gearbox-protocol/core-v3/contracts/interfaces/IAddressProviderV3.sol";

/// @dev Window size in bps, used to compute upper bound given lower bound
uint256 constant WINDOW_SIZE = 200;

/// @dev Buffer size in bps, used to compute new lower bound given current exchange rate
uint256 constant BUFFER_SIZE = 100;

/// @dev Minimum interval between two permissionless bounds updates
uint256 constant UPDATE_BOUNDS_COOLDOWN = 1 days;

/// @title LP price feed
/// @notice Abstract contract for LP token price feeds.
///         It is assumed that the price of an LP token is the product of its exchange rate and some aggregate function
///         of underlying tokens prices. This contract simplifies creation of such price feeds and provides standard
///         validation of the LP token exchange rate that protects against price manipulation.
abstract contract LPPriceFeed is ILPPriceFeed, ACLNonReentrantTrait, PriceFeedValidationTrait {
    /// @notice Answer precision (always 8 decimals for USD price feeds)
    uint8 public constant override decimals = 8; // U:[LPPF-2]

    /// @notice Indicates that price oracle can skip checks for this price feed's answers
    bool public constant override skipPriceCheck = true; // U:[LPPF-2]

    /// @notice Price oracle contract
    address public immutable override priceOracle;

    /// @notice LP token for which the prices are computed
    address public immutable override lpToken;

    /// @notice LP contract (can be different from LP token)
    address public immutable override lpContract;

    /// @notice Lower bound for the LP token exchange rate
    uint256 public override lowerBound;

    /// @notice Whether permissionless bounds update is allowed
    bool public override updateBoundsAllowed;

    /// @notice Timestamp of the last bounds update
    uint40 public override lastBoundsUpdate;

    /// @notice Constructor
    /// @param _addressProvider Address provider contract address
    /// @param _lpToken  LP token for which the prices are computed
    /// @param _lpContract LP contract (can be different from LP token)
    /// @dev Derived price feeds must call `_setLimiter` in their constructor after
    ///      initializing all state variables needed for exchange rate calculation
    constructor(address _addressProvider, address _lpToken, address _lpContract)
        ACLNonReentrantTrait(_addressProvider) // U:[LPPF-1]
        nonZeroAddress(_lpToken) // U:[LPPF-1]
        nonZeroAddress(_lpContract) // U:[LPPF-1]
    {
        priceOracle = IAddressProviderV3(_addressProvider).getAddressOrRevert(AP_PRICE_ORACLE, 3_00); // U:[LPPF-1]
        lpToken = _lpToken; // U:[LPPF-1]
        lpContract = _lpContract; // U:[LPPF-1]
    }

    /// @notice Price feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked(ERC20(lpToken).symbol(), " / USD price feed")); // U:[LPPF-2]
    }

    /// @notice Returns USD price of the LP token with 8 decimals
    function latestRoundData() external view override returns (uint80, int256 answer, uint256, uint256, uint80) {
        uint256 exchangeRate = getLPExchangeRate();
        uint256 lb = lowerBound;
        if (exchangeRate < lb) revert ExchangeRateOutOfBoundsException(); // U:[LPPF-3]

        uint256 ub = _calcUpperBound(lb);
        if (exchangeRate > ub) exchangeRate = ub; // U:[LPPF-3]

        answer = int256((exchangeRate * uint256(getAggregatePrice())) / getScale()); // U:[LPPF-3]
        return (0, answer, 0, 0, 0);
    }

    /// @notice Upper bound for the LP token exchange rate
    function upperBound() external view returns (uint256) {
        return _calcUpperBound(lowerBound); // U:[LPPF-4]
    }

    /// @notice Returns aggregate price of underlying tokens with 8 decimals
    /// @dev Must be implemented by derived price feeds
    function getAggregatePrice() public view virtual override returns (int256 answer);

    /// @notice Returns LP token exchange rate
    /// @dev Must be implemented by derived price feeds
    function getLPExchangeRate() public view virtual override returns (uint256 exchangeRate);

    /// @notice Returns LP token exchange rate scale
    /// @dev Must be implemented by derived price feeds
    function getScale() public view virtual override returns (uint256 scale);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Allows permissionless bounds update
    function allowBoundsUpdate()
        external
        override
        configuratorOnly // U:[LPPF-5]
    {
        if (updateBoundsAllowed) return;
        updateBoundsAllowed = true; // U:[LPPF-5]
        emit SetUpdateBoundsAllowed(true); // U:[LPPF-5]
    }

    /// @notice Forbids permissionless bounds update
    function forbidBoundsUpdate()
        external
        override
        controllerOnly // U:[LPPF-5]
    {
        if (!updateBoundsAllowed) return;
        updateBoundsAllowed = false; // U:[LPPF-5]
        emit SetUpdateBoundsAllowed(false); // U:[LPPF-5]
    }

    /// @notice Sets new lower and upper bounds for the LP token exchange rate
    /// @param newLowerBound New lower bound value
    function setLimiter(uint256 newLowerBound)
        external
        override
        controllerOnly // U:[LPPF-6]
    {
        _setLimiter(newLowerBound); // U:[LPPF-6]
    }

    /// @notice Permissionlessly updates LP token's exchange rate bounds using answer from the reserve price feed.
    ///         Lower bound is set to the induced reserve exchange rate (with small buffer for downside movement).
    /// @param updateData Data to update the reserve price feed with before querying its answer if it is updatable
    function updateBounds(bytes calldata updateData) external override {
        if (!updateBoundsAllowed) revert UpdateBoundsNotAllowedException(); // U:[LPPF-7]

        if (block.timestamp < lastBoundsUpdate + UPDATE_BOUNDS_COOLDOWN) revert UpdateBoundsBeforeCooldownException(); // U:[LPPF-7]
        lastBoundsUpdate = uint40(block.timestamp); // U:[LPPF-7]

        address reserveFeed = IPriceOracleV3(priceOracle).priceFeedsRaw({token: lpToken, reserve: true}); // U:[LPPF-7]
        if (reserveFeed == address(this)) revert ReserveFeedMustNotBeSelfException(); // U:[LPPF-7]
        try IUpdatablePriceFeed(reserveFeed).updatable() returns (bool updatable) {
            if (updatable) IUpdatablePriceFeed(reserveFeed).updatePrice(updateData); // U:[LPPF-7]
        } catch {}

        uint256 reserveAnswer = IPriceOracleV3(priceOracle).getPriceRaw({token: lpToken, reserve: true}); // U:[LPPF-7]
        uint256 reserveExchangeRate = uint256(reserveAnswer * getScale() / uint256(getAggregatePrice())); // U:[LPPF-7]

        _ensureValueInBounds(reserveExchangeRate, lowerBound); // U:[LPPF-7]
        _setLimiter(_calcLowerBound(reserveExchangeRate)); // U:[LPPF-7]
    }

    /// @dev `setLimiter` implementation: sets new bounds, ensures that current value is within them, emits event
    function _setLimiter(uint256 lower) internal {
        if (lower == 0) revert LowerBoundCantBeZeroException(); // U:[LPPF-6]
        uint256 upper = _ensureValueInBounds(getLPExchangeRate(), lower); // U:[LPPF-6]
        lowerBound = lower; // U:[LPPF-6]
        emit SetBounds(lower, upper); // U:[LPPF-6]
    }

    /// @dev Computes upper bound as `_lowerBound * (1 + WINDOW_SIZE)`
    function _calcUpperBound(uint256 _lowerBound) internal pure returns (uint256) {
        return _lowerBound * (PERCENTAGE_FACTOR + WINDOW_SIZE) / PERCENTAGE_FACTOR; // U:[LPPF-4]
    }

    /// @dev Computes lower bound as `exchangeRate * (1 - BUFFER_SIZE)`
    function _calcLowerBound(uint256 exchangeRate) internal pure returns (uint256) {
        return exchangeRate * (PERCENTAGE_FACTOR - BUFFER_SIZE) / PERCENTAGE_FACTOR; // U:[LPPF-6]
    }

    /// @dev Ensures that value is in bounds, returns upper bound computed from lower bound
    function _ensureValueInBounds(uint256 value, uint256 lower) internal pure returns (uint256 upper) {
        if (value < lower) revert ExchangeRateOutOfBoundsException();
        upper = _calcUpperBound(lower);
        if (value > upper) revert ExchangeRateOutOfBoundsException();
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

struct PriceFeedParams {
    address priceFeed;
    uint32 stalenessPeriod;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function price_oracle() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE,
    WSTETH_ORACLE,
    BOUNDED_ORACLE,
    COMPOSITE_ORACLE,
    WRAPPED_AAVE_V2_ORACLE,
    COMPOUND_V2_ORACLE,
    BALANCER_STABLE_LP_ORACLE,
    BALANCER_WEIGHTED_LP_ORACLE,
    CURVE_CRYPTO_ORACLE,
    THE_SAME_AS,
    REDSTONE_ORACLE,
    ERC4626_VAULT_ORACLE,
    NETWORK_DEPENDENT,
    CURVE_USD_ORACLE,
    PYTH_ORACLE
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// Denominations

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 50%
uint16 constant DEFAULT_FEE_INTEREST = 50_00; // 50%

// LIQUIDATION_FEE 1.5%
uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50; // 1.5%

// LIQUIDATION PREMIUM 4%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00; // 4%

// LIQUIDATION_FEE_EXPIRED 2%
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00; // 2%

// LIQUIDATION PREMIUM EXPIRED 2%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00; // 2%

// DEFAULT PROPORTION OF MAX BORROWED PER BLOCK TO MAX BORROWED PER ACCOUNT
uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Leverage decimals - 100 is equal to 2x leverage (100% * collateral amount + 100% * borrowed amount)
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in PERCENTAGE_FACTOR format
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IPriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";

interface ILPPriceFeedEvents {
    /// @notice Emitted when new LP token exchange rate bounds are set
    event SetBounds(uint256 lowerBound, uint256 upperBound);

    /// @notice Emitted when permissionless bounds update is allowed or forbidden
    event SetUpdateBoundsAllowed(bool allowed);
}

interface ILPPriceFeedExceptions {
    /// @notice Thrown when trying to set exchange rate lower bound to zero
    error LowerBoundCantBeZeroException();

    /// @notice Thrown when exchange rate falls below lower bound during price calculation
    ///         or new boudns don't contain exchange rate during bounds update
    error ExchangeRateOutOfBoundsException();

    /// @notice Thrown when trying to call `updateBounds` while it's not allowed
    error UpdateBoundsNotAllowedException();

    /// @notice Thrown when trying to call `updateBounds` before cooldown since the last update has passed
    error UpdateBoundsBeforeCooldownException();

    /// @notice Thrown when price oracle's reserve price feed is the LP price feed itself
    error ReserveFeedMustNotBeSelfException();
}

/// @title LP price feed interface
interface ILPPriceFeed is IPriceFeed, ILPPriceFeedEvents, ILPPriceFeedExceptions {
    function priceOracle() external view returns (address);

    function lpToken() external view returns (address);
    function lpContract() external view returns (address);

    function lowerBound() external view returns (uint256);
    function upperBound() external view returns (uint256);
    function updateBoundsAllowed() external view returns (bool);
    function lastBoundsUpdate() external view returns (uint40);

    function getAggregatePrice() external view returns (int256 answer);
    function getLPExchangeRate() external view returns (uint256 exchangeRate);
    function getScale() external view returns (uint256 scale);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function allowBoundsUpdate() external;
    function forbidBoundsUpdate() external;
    function setLimiter(uint256 newLowerBound) external;
    function updateBounds(bytes calldata updateData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";
import {
    CallerNotControllerException,
    CallerNotPausableAdminException,
    CallerNotUnpausableAdminException
} from "../interfaces/IExceptions.sol";

import {ACLTrait} from "./ACLTrait.sol";
import {ReentrancyGuardTrait} from "./ReentrancyGuardTrait.sol";

/// @title ACL non-reentrant trait
/// @notice Extended version of `ACLTrait` that implements pausable functionality,
///         reentrancy protection and external controller role
abstract contract ACLNonReentrantTrait is ACLTrait, Pausable, ReentrancyGuardTrait {
    /// @notice Emitted when new external controller is set
    event NewController(address indexed newController);

    /// @notice External controller address
    address public controller;

    /// @dev Ensures that function caller is external controller or configurator
    modifier controllerOnly() {
        _ensureCallerIsControllerOrConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not controller or configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsControllerOrConfigurator() internal view {
        if (msg.sender != controller && !_isConfigurator({account: msg.sender})) {
            revert CallerNotControllerException();
        }
    }

    /// @dev Ensures that function caller has pausable admin role
    modifier pausableAdminsOnly() {
        _ensureCallerIsPausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not pausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsPausableAdmin() internal view {
        if (!_isPausableAdmin({account: msg.sender})) {
            revert CallerNotPausableAdminException();
        }
    }

    /// @dev Ensures that function caller has unpausable admin role
    modifier unpausableAdminsOnly() {
        _ensureCallerIsUnpausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not unpausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsUnpausableAdmin() internal view {
        if (!_isUnpausableAdmin({account: msg.sender})) {
            revert CallerNotUnpausableAdminException();
        }
    }

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) ACLTrait(addressProvider) {
        controller = IACL(acl).owner();
    }

    /// @notice Pauses contract, can only be called by an account with pausable admin role
    function pause() external virtual pausableAdminsOnly {
        _pause();
    }

    /// @notice Unpauses contract, can only be called by an account with unpausable admin role
    function unpause() external virtual unpausableAdminsOnly {
        _unpause();
    }

    /// @notice Sets new external controller, can only be called by configurator
    function setController(address newController) external configuratorOnly {
        if (controller == newController) return;
        controller = newController;
        emit NewController(newController);
    }

    /// @dev Checks whether given account has pausable admin role
    function _isPausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isPausableAdmin(account);
    }

    /// @dev Checks whether given account has unpausable admin role
    function _isUnpausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isUnpausableAdmin(account);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {
    AddressIsNotContractException,
    IncorrectParameterException,
    IncorrectPriceException,
    IncorrectPriceFeedException,
    PriceFeedDoesNotExistException,
    StalePriceException
} from "../interfaces/IExceptions.sol";
import {IPriceFeed, IUpdatablePriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";

/// @title Price feed validation trait
abstract contract PriceFeedValidationTrait {
    using Address for address;

    /// @dev Ensures that price is positive and not stale
    function _checkAnswer(int256 price, uint256 updatedAt, uint32 stalenessPeriod) internal view {
        if (price <= 0) revert IncorrectPriceException();
        if (block.timestamp >= updatedAt + stalenessPeriod) revert StalePriceException();
    }

    /// @dev Valites that `priceFeed` is a contract that adheres to Chainlink interface and passes sanity checks
    /// @dev Some price feeds return stale prices unless updated right before querying their answer, which causes
    ///      issues during deployment and configuration, so for such price feeds staleness check is skipped, and
    ///      special care must be taken to ensure all parameters are in tune.
    function _validatePriceFeed(address priceFeed, uint32 stalenessPeriod) internal view returns (bool skipCheck) {
        if (!priceFeed.isContract()) revert AddressIsNotContractException(priceFeed); // U:[PO-5]

        try IPriceFeed(priceFeed).decimals() returns (uint8 _decimals) {
            if (_decimals != 8) revert IncorrectPriceFeedException(); // U:[PO-5]
        } catch {
            revert IncorrectPriceFeedException(); // U:[PO-5]
        }

        try IPriceFeed(priceFeed).skipPriceCheck() returns (bool _skipCheck) {
            skipCheck = _skipCheck; // U:[PO-5]
        } catch {}

        try IPriceFeed(priceFeed).latestRoundData() returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80)
        {
            if (skipCheck) {
                if (stalenessPeriod != 0) revert IncorrectParameterException(); // U:[PO-5]
            } else {
                if (stalenessPeriod == 0) revert IncorrectParameterException(); // U:[PO-5]

                bool updatable;
                try IUpdatablePriceFeed(priceFeed).updatable() returns (bool _updatable) {
                    updatable = _updatable;
                } catch {}
                if (!updatable) _checkAnswer(answer, updatedAt, stalenessPeriod); // U:[PO-5]
            }
        } catch {
            revert IncorrectPriceFeedException(); // U:[PO-5]
        }
    }

    /// @dev Returns answer from a price feed with optional sanity and staleness checks
    function _getValidatedPrice(address priceFeed, uint32 stalenessPeriod, bool skipCheck)
        internal
        view
        returns (int256 answer)
    {
        uint256 updatedAt;
        (, answer,, updatedAt,) = IPriceFeed(priceFeed).latestRoundData(); // U:[PO-1]
        if (!skipCheck) _checkAnswer(answer, updatedAt, stalenessPeriod); // U:[PO-1]
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IPriceOracleBase} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceOracleBase.sol";

struct PriceFeedParams {
    address priceFeed;
    uint32 stalenessPeriod;
    bool skipCheck;
    uint8 decimals;
    bool useReserve;
    bool trusted;
}

interface IPriceOracleV3Events {
    /// @notice Emitted when new price feed is set for token
    event SetPriceFeed(
        address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck, bool trusted
    );

    /// @notice Emitted when new reserve price feed is set for token
    event SetReservePriceFeed(address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck);

    /// @notice Emitted when new reserve price feed status is set for a token
    event SetReservePriceFeedStatus(address indexed token, bool active);
}

/// @title Price oracle V3 interface
interface IPriceOracleV3 is IPriceOracleBase, IPriceOracleV3Events {
    function getPriceSafe(address token) external view returns (uint256);

    function getPriceRaw(address token, bool reserve) external view returns (uint256);

    function priceFeedsRaw(address token, bool reserve) external view returns (address);

    function priceFeedParams(address token)
        external
        view
        returns (address priceFeed, uint32 stalenessPeriod, bool skipCheck, uint8 decimals, bool trusted);

    function safeConvertToUSD(uint256 amount, address token) external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setPriceFeed(address token, address priceFeed, uint32 stalenessPeriod, bool trusted) external;

    function setReservePriceFeed(address token, address priceFeed, uint32 stalenessPeriod) external;

    function setReservePriceFeedStatus(address token, bool active) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

import { PriceFeedType } from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

/// @title Price feed interface
interface IPriceFeed {
    function priceFeedType() external view returns (PriceFeedType);

    function version() external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function skipPriceCheck() external view returns (bool);

    function latestRoundData()
        external
        view
        returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80);
}

/// @title Updatable price feed interface
interface IUpdatablePriceFeed is IPriceFeed {
    function updatable() external view returns (bool);

    function updatePrice(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint256 constant NO_VERSION_CONTROL = 0;

bytes32 constant AP_CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant AP_ACL = "ACL";
bytes32 constant AP_PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant AP_ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant AP_DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant AP_TREASURY = "TREASURY";
bytes32 constant AP_GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant AP_WETH_TOKEN = "WETH_TOKEN";
bytes32 constant AP_WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant AP_ROUTER = "ROUTER";
bytes32 constant AP_BOT_LIST = "BOT_LIST";
bytes32 constant AP_GEAR_STAKING = "GEAR_STAKING";
bytes32 constant AP_ZAPPER_REGISTER = "ZAPPER_REGISTER";

interface IAddressProviderV3Events {
    /// @notice Emitted when an address is set for a contract key
    event SetAddress(bytes32 indexed key, address indexed value, uint256 indexed version);
}

/// @title Address provider V3 interface
interface IAddressProviderV3 is IAddressProviderV3Events, IVersion {
    function addresses(bytes32 key, uint256 _version) external view returns (address);

    function getAddressOrRevert(bytes32 key, uint256 _version) external view returns (address result);

    function setAddress(bytes32 key, address value, bool saveVersion) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";

import {AP_ACL, IAddressProviderV3, NO_VERSION_CONTROL} from "../interfaces/IAddressProviderV3.sol";
import {CallerNotConfiguratorException} from "../interfaces/IExceptions.sol";

import {SanityCheckTrait} from "./SanityCheckTrait.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is SanityCheckTrait {
    /// @notice ACL contract address
    address public immutable acl;

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) nonZeroAddress(addressProvider) {
        acl = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_ACL, NO_VERSION_CONTROL);
    }

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator({account: msg.sender})) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/// @title Reentrancy guard trait
/// @notice Same as OpenZeppelin's `ReentrancyGuard` but only uses 1 byte of storage instead of 32
abstract contract ReentrancyGuardTrait {
    uint8 internal _reentrancyStatus = NOT_ENTERED;

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        _ensureNotEntered();

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = NOT_ENTERED;
    }

    /// @dev Reverts if the contract is currently entered
    /// @dev Used to cut contract size on modifiers
    function _ensureNotEntered() internal view {
        require(_reentrancyStatus != ENTERED, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IVersion } from "./IVersion.sol";

/// @title Price oracle base interface
/// @notice Functions shared accross newer and older versions
interface IPriceOracleBase is IVersion {
    function getPrice(address token) external view returns (uint256);

    function convertToUSD(
        uint256 amount,
        address token
    ) external view returns (uint256);

    function convertFromUSD(
        uint256 amount,
        address token
    ) external view returns (uint256);

    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    function priceFeeds(
        address token
    ) external view returns (address priceFeed);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}