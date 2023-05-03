// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

abstract contract CoverPoolEvents {
    event Mint(
        address indexed to,
        int24 lower,
        int24 upper,
        bool zeroForOne,
        uint32 epochLast,
        uint128 amountIn,
        uint128 liquidityMinted,
        uint128 amountInDeltaMaxMinted,
        uint128 amountOutDeltaMaxMinted
    );

    event Burn(
        address indexed to,
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityBurned,
        uint128 tokenInClaimed,
        uint128 tokenOutClaimed,
        uint128 tokenOutBurned,
        uint128 amountInDeltaMaxStashedBurned,
        uint128 amountOutDeltaMaxStashedBurned,
        uint128 amountInDeltaMaxBurned,
        uint128 amountOutDeltaMaxBurned,
        uint160 claimPriceLast
    );

    event Swap(
        address indexed recipient,
        uint128 amountIn,
        uint128 amountOut,
        uint160 priceLimit,
        uint160 newPrice,
        bool zeroForOne
    );

    event Initialize(
        int24 minTick,
        int24 maxTick,
        int24 latestTick,
        uint32 genesisTime,
        uint32 auctionStart,
        uint160 pool0Price,
        uint160 pool1Price
    );

    event Sync(
        uint160 pool0Price,
        uint160 pool1Price,
        uint128 pool0Liquidity,
        uint128 pool1Liquidity,
        uint32 auctionStart,
        uint32 accumEpoch,
        int24 oldLatestTick,
        int24 newLatestTick
    );

    event FinalDeltasAccumulated(
        uint128 amountInDelta,
        uint128 amountOutDelta,
        uint32 accumEpoch,
        int24 accumTick,
        bool isPool0
    );

    event StashDeltasCleared(
        int24 stashTick,
        bool isPool0
    );

    event StashDeltasAccumulated(
        uint128 amountInDelta,
        uint128 amountOutDelta,
        uint128 amountInDeltaMaxStashed,
        uint128 amountOutDeltaMaxStashed,
        uint32 accumEpoch,
        int24 stashTick,
        bool isPool0
    );

    event SyncFeesCollected(
        address indexed collector,
        uint128 token0Amount,
        uint128 token1Amount
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

abstract contract CoverPoolFactoryEvents {
    event PoolCreated(
        address pool,
        address twapSource,
        address inputPool,
        address indexed token0,
        address indexed token1,
        uint16 fee,
        int16 indexed tickSpread,
        uint16 twapLength
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract CoverPoolFactoryStorage {
    mapping(bytes32 => address) public coverPools;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../../interfaces/ICoverPoolStructs.sol';
import '../../interfaces/ICoverPoolFactory.sol';
import '../../utils/CoverPoolErrors.sol';

abstract contract CoverPoolStorage is ICoverPoolStructs, CoverPoolErrors {
    GlobalState public globalState;
    PoolState public pool0; /// @dev State for token0 as output
    PoolState public pool1; /// @dev State for token1 as output
    TickMap public tickMap;
    address public feeTo;
    mapping(int24 => Tick) public ticks0; /// @dev Ticks containing token0 as output
    mapping(int24 => Tick) public ticks1; /// @dev Ticks containing token1 as output
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions0; //positions with token0 deposited
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions1; //positions with token1 deposited
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './CoverPoolManagerStructs.sol';

abstract contract CoverPoolFactoryStructs is CoverPoolManagerStructs {
    struct CoverPoolParams {
        VolatilityTier config;
        address twapSource;
        address curveMath;
        address inputPool;
        address owner;
        address token0;
        address token1;
        int16   tickSpread;
        uint16  twapLength;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../../interfaces/modules/sources/ITwapSource.sol';

interface CoverPoolManagerStructs {
    struct VolatilityTier {
        uint128 minAmountPerAuction; // based on 18 decimals and then converted based on token decimals
        uint16  auctionLength;
        uint16  blockTime; // average block time where 1e3 is 1 second
        uint16  syncFee;
        uint16  fillFee;
        int16   minPositionWidth;
        bool    minAmountLowerPriced;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../../interfaces/modules/sources/ITwapSource.sol';

interface CurveMathStructs {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './interfaces/ICoverPool.sol';
import './interfaces/ICoverPoolManager.sol';
import './base/events/CoverPoolEvents.sol';
import './base/storage/CoverPoolStorage.sol';
import './base/structs/CoverPoolFactoryStructs.sol';
import './utils/SafeTransfers.sol';
import './utils/CoverPoolErrors.sol';
import './libraries/Positions.sol';
import './libraries/Epochs.sol';

/// @notice Poolshark Cover Pool Implementation
contract CoverPool is
    ICoverPool,
    CoverPoolEvents,
    CoverPoolFactoryStructs,
    CoverPoolStorage,
    SafeTransfers
{
    address public immutable owner;
    address public immutable token0;
    address public immutable token1;
    address public immutable twapSource;
    address public immutable curveMath;
    address public immutable inputPool; 
    uint160 public immutable minPrice;
    uint160 public immutable maxPrice;
    uint128 public immutable minAmountPerAuction;
    uint32  public immutable genesisTime;
    int16   public immutable minPositionWidth;
    int16   public immutable tickSpread;
    uint16  public immutable twapLength;
    uint16  public immutable auctionLength;
    uint16  public immutable blockTime;
    uint8   internal immutable token0Decimals;
    uint8   internal immutable token1Decimals;
    bool    public immutable minAmountLowerPriced;

    modifier ownerOnly() {
        _onlyOwner();
        _;
    }

    modifier lock() {
        _prelock();
        _;
        _postlock();
    }

    constructor(
        CoverPoolParams memory params
    ) {
        // set addresses
        owner      = params.owner;
        twapSource = params.twapSource;
        curveMath  = params.curveMath;
        inputPool  = params.inputPool;
        token0     = params.token0;
        token1     = params.token1;
        
        // set token decimals
        token0Decimals = ERC20(token0).decimals();
        token1Decimals = ERC20(token1).decimals();
        if (token0Decimals > 18 || token1Decimals > 18
          || token0Decimals < 6 || token1Decimals < 6) {
            revert InvalidTokenDecimals();
        }

        // set other immutables
        auctionLength = params.config.auctionLength;
        blockTime = params.config.blockTime;
        minPositionWidth = params.config.minPositionWidth;
        tickSpread    = params.tickSpread;
        twapLength    = params.twapLength;
        genesisTime   = uint32(block.timestamp);
        minAmountPerAuction = params.config.minAmountPerAuction;
        minAmountLowerPriced = params.config.minAmountLowerPriced;

        // set price boundaries
        ICurveMath curve = ICurveMath(curveMath);
        minPrice = curve.minPrice(tickSpread);
        maxPrice = curve.maxPrice(tickSpread);
    }

    function mint(
        MintParams memory params
    ) external lock {
        MintCache memory cache = MintCache({
            state: globalState,
            position: params.zeroForOne ? positions0[msg.sender][params.lower][params.upper]
                                        : positions1[msg.sender][params.lower][params.upper],
            constants: _immutables(),
            syncFees: SyncFees(0,0),
            liquidityMinted: 0
        });
        (
            cache.state,
            cache.syncFees,
            pool0, 
            pool1
        ) = Epochs.syncLatest(
            ticks0,
            ticks1,
            tickMap,
            pool0,
            pool1,
            cache.state,
            cache.constants
        );
        // resize position if necessary
        (params, cache.liquidityMinted) = Positions.resize(
            cache.position,
            params, 
            cache.state,
            cache.constants
        );
        // params.amount must be > 0 here
        _transferIn(params.zeroForOne ? token0 : token1, params.amount);
        // recreates position if required
        (cache.state,) = Positions.update(
            params.zeroForOne ? positions0 : positions1, //TODO: start and end; one mapping
            params.zeroForOne ? ticks0 : ticks1, //TODO: mappings of mappings; pass params.zeroForOne
            tickMap,
            cache.state,
            params.zeroForOne ? pool0 : pool1, //TODO: mapping and pass params.zeroForOne
            UpdateParams(
                msg.sender,
                params.to,
                0,
                params.lower,
                params.upper,
                params.claim,
                params.zeroForOne
            ),
            cache.constants
        );
        cache.state = Positions.add(
            params.zeroForOne ? positions0 : positions1,
            params.zeroForOne ? ticks0 : ticks1,
            tickMap,
            cache.state,
            AddParams(
                params.to,
                uint128(cache.liquidityMinted),
                params.amount,
                params.lower,
                params.claim,
                params.upper,
                params.zeroForOne
            ),
            _immutables()
        );
        globalState = cache.state;
        _collect(
            CollectParams(
                cache.syncFees,
                params.to, //address(0) goes to msg.sender
                params.lower,
                params.claim,
                params.upper,
                params.zeroForOne
            )
        );
    }

    function burn(
        BurnParams memory params
    ) external lock {
        if (params.to == address(0)) revert CollectToZeroAddress();
        BurnCache memory cache = BurnCache({
            state: globalState,
            position: params.zeroForOne ? positions0[msg.sender][params.lower][params.upper]
                                        : positions1[msg.sender][params.lower][params.upper],
            constants: _immutables(),
            syncFees: SyncFees(0,0)
        });
        if (params.sync)
            (cache.state, cache.syncFees, pool0, pool1) = Epochs.syncLatest(
                ticks0,
                ticks1,
                tickMap,
                pool0,
                pool1,
                cache.state,
                cache.constants
        );
        if (cache.position.claimPriceLast > 0
            || params.claim != (params.zeroForOne ? params.upper : params.lower) 
            || params.claim == cache.state.latestTick)
        {
            // if position has been crossed into
            (cache.state, params.claim) = Positions.update(
                params.zeroForOne ? positions0 : positions1,
                params.zeroForOne ? ticks0 : ticks1,
                tickMap,
                cache.state,
                params.zeroForOne ? pool0 : pool1,
                UpdateParams(
                    msg.sender,
                    params.to,
                    params.burnPercent,
                    params.lower,
                    params.upper,
                    params.claim,
                    params.zeroForOne
                ),
                _immutables()
            );
        } else {
            // if position hasn't been crossed into
            (, cache.state) = Positions.remove(
                params.zeroForOne ? positions0 : positions1,
                params.zeroForOne ? ticks0 : ticks1,
                tickMap,
                cache.state,
                RemoveParams(
                    msg.sender,
                    params.to,
                    params.burnPercent,
                    params.lower,
                    params.upper,
                    params.zeroForOne
                ),
                _immutables()
            );
        }
        globalState = cache.state;
        _collect(
            CollectParams(
                cache.syncFees,
                params.to, //address(0) goes to msg.sender
                params.lower,
                params.claim,
                params.upper,
                params.zeroForOne
            )
        );
    }

    function swap(
        address recipient,
        bool zeroForOne,
        uint128 amountIn,
        uint160 priceLimit
    ) external override lock returns (
        int256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    ) 
    {
        ICurveMath(curveMath).checkPrice(
            priceLimit,
            ITickMath.PriceBounds(minPrice, maxPrice));
        SwapCache memory cache;
        cache.state = globalState;
        cache.constants = _immutables();
        (
            cache.state,
            cache.syncFees,
            pool0,
            pool1
        ) = Epochs.syncLatest(
            ticks0,
            ticks1,
            tickMap,
            pool0,
            pool1,
            cache.state,
            _immutables()
        );
        PoolState memory pool = zeroForOne ? pool1 : pool0;
        cache = SwapCache({
            state: cache.state,
            syncFees: cache.syncFees,
            constants: cache.constants,
            price: pool.price,
            liquidity: pool.liquidity,
            amountIn: amountIn,
            auctionDepth: block.timestamp - genesisTime - cache.state.auctionStart,
            auctionBoost: 0,
            input: amountIn,
            output: 0,
            inputBoosted: 0,
            amountInDelta: 0
        });

        _transferIn(zeroForOne ? token0 : token1, amountIn);

        /// @dev - liquidity range is limited to one tick
        cache = Ticks.quote(zeroForOne, priceLimit, cache.state, cache, _immutables());

        if (zeroForOne) {
            pool1.price = uint160(cache.price);
            pool1.amountInDelta += uint128(cache.amountInDelta);
        } else {
            pool0.price = uint160(cache.price);
            pool0.amountInDelta += uint128(cache.amountInDelta);
        }

        globalState = cache.state;

        if (zeroForOne) {
            if (cache.input + cache.syncFees.token0 > 0) {
                _transferOut(recipient, token0, cache.input + cache.syncFees.token0);
            }
            if (cache.output + cache.syncFees.token1 > 0) {
                _transferOut(recipient, token1, cache.output + cache.syncFees.token1);
                emit Swap(recipient, uint128(amountIn - cache.input), uint128(cache.output), uint160(cache.price), priceLimit, zeroForOne);
            }
            return (
                int128(amountIn) - int256(cache.input) - int128(cache.syncFees.token0),
                cache.output + cache.syncFees.token1,
                cache.price 
            );
        } else {
            if (cache.input + cache.syncFees.token1 > 0) {
                _transferOut(recipient, token1, cache.input + cache.syncFees.token1);
            }
            if (cache.output + cache.syncFees.token0 > 0) {
                _transferOut(recipient, token0, cache.output + cache.syncFees.token0);
                emit Swap(recipient, uint128(amountIn - cache.input), uint128(cache.output), uint160(cache.price), priceLimit, zeroForOne);
            }
            return (
                int128(amountIn) - int256(cache.input) - int128(cache.syncFees.token1),
                cache.output + cache.syncFees.token0,
                cache.price 
            );
        }
    }

    function quote(
        bool zeroForOne,
        uint128 amountIn,
        uint160 priceLimit
    ) external view override returns (
        int256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    ) {
        PoolState memory pool0State;
        PoolState memory pool1State;
        SwapCache memory cache;
        cache.state = globalState;
        cache.constants = _immutables();
        (
            cache.state,
            cache.syncFees,
            pool0State,
            pool1State
        ) = Epochs.simulateSync(
            ticks0,
            ticks1,
            tickMap,
            pool0,
            pool1,
            cache.state,
            cache.constants
        );
        cache = SwapCache({
            state: cache.state,
            syncFees: cache.syncFees,
            constants: cache.constants,
            price: zeroForOne ? pool1State.price : pool0State.price,
            liquidity: zeroForOne ? pool1State.liquidity : pool0State.liquidity,
            amountIn: amountIn,
            auctionDepth: block.timestamp - genesisTime - cache.state.auctionStart,
            auctionBoost: 0,
            input: amountIn,
            output: 0,
            inputBoosted: 0,
            amountInDelta: 0
        });
        cache = Ticks.quote(zeroForOne, priceLimit, cache.state, cache, _immutables());
        if (zeroForOne) {
            return (
                int128(amountIn) - int256(cache.input) - int128(cache.syncFees.token0),
                cache.output + cache.syncFees.token1,
                cache.price 
            );
        } else {
            return (
                int128(amountIn) - int256(cache.input) - int128(cache.syncFees.token1),
                cache.output + cache.syncFees.token0,
                cache.price 
            );
        }
    }

    function snapshot(
       SnapshotParams memory params 
    ) external view returns (
        Position memory
    ) {
        return Positions.snapshot(
            params.zeroForOne ? positions0 : positions1,
            params.zeroForOne ? ticks0 : ticks1,
            tickMap,
            globalState,
            params.zeroForOne ? pool0 : pool1,
            UpdateParams(
                params.owner,
                params.owner,
                params.burnPercent,
                params.lower,
                params.upper,
                params.claim,
                params.zeroForOne
            ),
            _immutables()
        );
    }

    function protocolFees(
        uint16 syncFee,
        uint16 fillFee,
        bool setFees
    ) external ownerOnly returns (
        uint128 token0Fees,
        uint128 token1Fees
    ) {
        if (setFees) {
            globalState.syncFee = syncFee;
            globalState.fillFee = fillFee;
        }
        token0Fees = globalState.protocolFees.token0;
        token1Fees = globalState.protocolFees.token1;
        address feeTo = ICoverPoolManager(owner).feeTo();
        globalState.protocolFees.token0 = 0;
        globalState.protocolFees.token1 = 0;
        _transferOut(feeTo, token0, token0Fees);
        _transferOut(feeTo, token1, token1Fees);
    }

    function _collect(
        CollectParams memory params
    ) internal {
        mapping(address => mapping(int24 => mapping(int24 => Position))) storage positions = params.zeroForOne ? positions0 : positions1;
        params.zeroForOne ? params.upper = params.claim : params.lower = params.claim;

        // store amounts for transferOut
        uint128 amountIn  = positions[msg.sender][params.lower][params.upper].amountIn;
        uint128 amountOut = positions[msg.sender][params.lower][params.upper].amountOut;

        // factor in sync fees
        if (params.zeroForOne) {
            amountIn  += params.syncFees.token1;
            amountOut += params.syncFees.token0;
        } else {
            amountIn  += params.syncFees.token0;
            amountOut += params.syncFees.token1;
        }

        /// zero out balances and transfer out
        if (amountIn > 0) {
            positions[msg.sender][params.lower][params.upper].amountIn = 0;
            _transferOut(params.to, params.zeroForOne ? token1 : token0, amountIn);
        } 
        if (amountOut > 0) {
            positions[msg.sender][params.lower][params.upper].amountOut = 0;
            _transferOut(params.to, params.zeroForOne ? token0 : token1, amountOut);
        }
    }

    function _immutables() private view returns (
        Immutables memory
    ) {
        return Immutables(
            ICurveMath(curveMath),
            ITwapSource(twapSource),
            ITickMath.PriceBounds(minPrice, maxPrice),
            inputPool,
            minAmountPerAuction,
            genesisTime,
            minPositionWidth,
            tickSpread,
            twapLength,
            auctionLength,
            blockTime,
            token0Decimals,
            token1Decimals,
            minAmountLowerPriced
        );
    }

    function _prelock() private {
        if (globalState.unlocked == 0) {
            globalState = Ticks.initialize(tickMap, pool0, pool1, globalState, _immutables());
        }
        if (globalState.unlocked == 0) revert WaitUntilEnoughObservations();
        if (globalState.unlocked == 2) revert Locked();
        globalState.unlocked = 2;
    }

    function _postlock() private {
        globalState.unlocked = 1;
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert OwnerOnly();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './CoverPool.sol';
import './interfaces/ICoverPoolFactory.sol';
import './base/events/CoverPoolFactoryEvents.sol';
import './base/structs/CoverPoolFactoryStructs.sol';
import './base/structs/CoverPoolManagerStructs.sol';
import './utils/CoverPoolErrors.sol';

contract CoverPoolFactory is 
    ICoverPoolFactory,
    CoverPoolFactoryStructs,
    CoverPoolFactoryEvents,
    CoverPoolFactoryErrors
{
    address immutable public owner;

    constructor(
        address _owner
    ) {
        owner = _owner;
    }

    function createCoverPool(
        bytes32 sourceName,
        address tokenIn,
        address tokenOut,
        uint16 feeTier,
        int16  tickSpread,
        uint16 twapLength
    ) external override returns (address pool) {
        CoverPoolParams memory params;
        // sort tokens by address
        params.token0 = tokenIn < tokenOut ? tokenIn : tokenOut;
        params.token1 = tokenIn < tokenOut ? tokenOut : tokenIn;
        // generate key for pool
        bytes32 key = keccak256(abi.encode(
                                            params.token0,
                                            params.token1,
                                            sourceName,
                                            feeTier,
                                            tickSpread,
                                            twapLength
                                ));
        if (coverPools[key] != address(0)) {
            revert PoolAlreadyExists();
        }
        // get twap source
        (params.twapSource, params.curveMath) = ICoverPoolManager(owner).twapSources(sourceName);
        if (params.twapSource == address(0)) revert TwapSourceNotFound();
        // get volatility tier config
        params.owner = owner;
        params.config = ICoverPoolManager(owner).volatilityTiers(sourceName, feeTier, tickSpread, twapLength);
        if (params.config.auctionLength == 0) revert VolatilityTierNotSupported();
        params.tickSpread = tickSpread;
        params.twapLength = twapLength;
        // get reference pool
        params.inputPool  = ITwapSource(params.twapSource).getPool(params.token0, params.token1, feeTier);

        // launch pool and save address
        pool = address(new CoverPool(params));

        coverPools[key] = pool;

        emit PoolCreated(
            pool,
            params.twapSource,
            params.inputPool,
            params.token0,
            params.token1,
            feeTier,
            tickSpread,
            twapLength
        );
    }

    function getCoverPool(
        bytes32 sourceName,
        address tokenIn,
        address tokenOut,
        uint16 feeTier,
        int16  tickSpread,
        uint16 twapLength
    ) public view override returns (address) {
        // set lexographical token address ordering
        address token0 = tokenIn < tokenOut ? tokenIn : tokenOut;
        address token1 = tokenIn < tokenOut ? tokenOut : tokenIn;

        // get pool address from mapping
        bytes32 key = keccak256(abi.encode(token0, token1, sourceName, feeTier, tickSpread, twapLength));

        return coverPools[key];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICoverPoolStructs.sol';

//TODO: combine everything into one interface
interface ICoverPool is ICoverPoolStructs {
    function mint(
        MintParams memory mintParams
    ) external;

    function burn(
        BurnParams calldata burnParams
    ) external;

    function swap(
        address recipient,
        bool zeroForOne,
        uint128 amountIn,
        uint160 priceLimit
    ) external returns (
        int256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    );

    function quote(
        bool zeroForOne,
        uint128 amountIn,
        uint160 priceLimit
    ) external view returns (
        int256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    );

    function protocolFees(
        uint16 syncFee,
        uint16 fillFee,
        bool setFees
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import '../base/storage/CoverPoolFactoryStorage.sol';

abstract contract ICoverPoolFactory is CoverPoolFactoryStorage {
    function createCoverPool(
        bytes32 sourceName,
        address tokenIn,
        address tokenOut,
        uint16 fee,
        int16  tickSpread,
        uint16 twapLength
    ) external virtual returns (address book);

    function getCoverPool(
        bytes32 sourceName,
        address tokenIn,
        address tokenOut,
        uint16 fee,
        int16 tickSpread,
        uint16 twapLength
    ) external view virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../base/structs/CoverPoolManagerStructs.sol';

/// @notice CoverPoolManager interface
interface ICoverPoolManager is CoverPoolManagerStructs {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function twapSources(
        bytes32 sourceName
    ) external view returns (
        address sourceAddress,
        address curveAddress
    );
    function volatilityTiers(
        bytes32 sourceName,
        uint16 feeTier,
        int16  tickSpread,
        uint16 twapLength
    ) external view returns (
        VolatilityTier memory
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './modules/curves/ICurveMath.sol';
import './modules/sources/ITwapSource.sol';

interface ICoverPoolStructs {
    struct GlobalState {
        ProtocolFees protocolFees;
        uint160  latestPrice;      /// @dev price of latestTick
        uint128  liquidityGlobal;
        //uint32   genesisTime;      /// @dev reference time for which auctionStart is an offset of
        uint32   lastTime;         /// @dev last block checked
        uint32   auctionStart;     /// @dev last block price reference was updated
        uint32   accumEpoch;       /// @dev number of times this pool has been synced
        int24    latestTick;       /// @dev latest updated inputPool price tick
        uint16   syncFee;
        uint16   fillFee;
        //int16    tickSpread;       /// @dev this is a integer multiple of the inputPool tickSpacing
        //uint16   twapLength;       /// @dev number of blocks used for TWAP sampling
        //uint16   auctionLength;    /// @dev number of seconds to improve price by tickSpread
        uint8    unlocked;
    }

    struct PoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 amountInDelta; /// @dev Delta for the current tick auction
        uint128 amountInDeltaMaxClaimed;  /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint128 amountOutDeltaMaxClaimed; /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs; /// @dev - ticks to epochs
    }

    struct Tick {
        Deltas deltas;
        int128  liquidityDelta;
        uint128 amountInDeltaMaxMinus;
        uint128 amountOutDeltaMaxMinus;
        uint128 amountInDeltaMaxStashed;
        uint128 amountOutDeltaMaxStashed;
    }

    struct Deltas {
        uint128 amountInDelta;     // amt unfilled
        uint128 amountOutDelta;    // amt unfilled
        uint128 amountInDeltaMax;  // max unfilled 
        uint128 amountOutDeltaMax; // max unfilled
    }

    struct Position {
        uint160 claimPriceLast; // highest price claimed at
        uint128 liquidity; // expected amount to be used not actual
        uint128 amountIn; // token amount already claimed; balance
        uint128 amountOut; // necessary for non-custodial positions
        uint32  accumEpochLast;  // last epoch this position was updated at
    }

    struct Immutables {
        ICurveMath  curve;
        ITwapSource source;
        ICurveMath.PriceBounds bounds;
        address inputPool;
        uint256 minAmountPerAuction;
        uint32 genesisTime;
        int16  minPositionWidth;
        int16  tickSpread;
        uint16 twapLength;
        uint16 auctionLength;
        uint16 blockTime;
        uint8 token0Decimals;
        uint8 token1Decimals;
        bool minAmountLowerPriced;
    }

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct SyncFees {
        uint128 token0;
        uint128 token1;
    }

    struct MintParams {
        address to;
        uint128 amount;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
    }

    struct BurnParams {
        address to;
        uint128 burnPercent;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
        bool sync;
    }

    struct SnapshotParams {
        address owner;
        uint128 burnPercent;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
    }

    struct CollectParams {
        SyncFees syncFees;
        address to;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
    }

    struct SizeParams {
        uint256 priceLower;
        uint256 priceUpper;
        uint128 liquidityAmount;
        bool zeroForOne;
        int24 latestTick;
        uint24 auctionCount;
    }

    struct AddParams {
        address to;
        uint128 amount;
        uint128 amountIn;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
    }

    struct RemoveParams {
        address owner;
        address to;
        uint128 amount;
        int24 lower;
        int24 upper;
        bool zeroForOne;
    }

    struct UpdateParams {
        address owner;
        address to;
        uint128 amount;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
    }

    struct MintCache {
        GlobalState state;
        Position position;
        Immutables constants;
        SyncFees syncFees;
        uint256 liquidityMinted;
    }

    struct BurnCache {
        GlobalState state;
        Position position;
        Immutables constants;
        SyncFees syncFees;
    }

    struct SwapCache {
        GlobalState state;
        SyncFees syncFees;
        Immutables constants;
        uint256 price;
        uint256 liquidity;
        uint256 amountIn;
        uint256 input;
        uint256 output;
        uint256 inputBoosted;
        uint256 auctionDepth;
        uint256 auctionBoost;
        uint256 amountInDelta;
    }

    struct PositionCache {
        Position position;
        Deltas deltas;
        uint160 priceLower;
        uint160 priceUpper;
        uint256 priceAverage;
        uint256 liquidityMinted;
        int24 requiredStart;
        uint24 auctionCount;
        bool denomTokenIn;
    }

    struct UpdatePositionCache {
        Deltas deltas;
        Deltas finalDeltas;
        PoolState pool;
        uint256 amountInFilledMax;    // considers the range covered by each update
        uint256 amountOutUnfilledMax; // considers the range covered by each update
        Tick claimTick;
        Tick finalTick;
        Position position;
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint160 priceSpread;
        bool earlyReturn;
        bool removeLower;
        bool removeUpper;
    }

    struct AccumulateCache {
        Deltas deltas0;
        Deltas deltas1;
        SyncFees syncFees;
        int24 newLatestTick;
        int24 nextTickToCross0;
        int24 nextTickToCross1;
        int24 nextTickToAccum0;
        int24 nextTickToAccum1;
        int24 stopTick0;
        int24 stopTick1;
    }

    struct AccumulateParams {
        Deltas deltas;
        Tick crossTick;
        Tick accumTick;
        bool updateAccumDeltas;
        bool isPool0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IDyDxMath.sol';
import './ITickMath.sol';

interface ICurveMath is 
    IDyDxMath,
    ITickMath
{}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../../interfaces/ICoverPoolStructs.sol';
import '../../../base/structs/CurveMathStructs.sol';

interface IDyDxMath {
    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (
        uint256 dy
    );

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (
        uint256 dx
    );

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (
        uint256 liquidity
    );

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 price,
        uint256 liquidity,
        bool roundUp
    ) external pure returns (
        uint128 token0amount,
        uint128 token1amount
    );

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 input,
        bool zeroForOne
    ) external pure returns (
        uint256 newPrice
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../../interfaces/ICoverPoolStructs.sol';
import '../../../base/structs/CurveMathStructs.sol';

interface ITickMath {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    function getPriceAtTick(
        int24 tick,
        ICoverPoolStructs.Immutables memory
    ) external pure returns (
        uint160 price
    );

    function getTickAtPrice(
        uint160 price,
        ICoverPoolStructs.Immutables memory
    ) external view returns (
        int24 tick
    );

    function minTick(
        int16 tickSpacing
    ) external pure returns (
        int24 tick
    );

    function maxTick(
        int16 tickSpacing
    ) external pure returns (
        int24 tick
    );

    function minPrice(
        int16 tickSpacing
    ) external pure returns (
        uint160 minPrice
    );

    function maxPrice(
        int16 tickSpacing
    ) external pure returns (
        uint160 maxPrice
    );

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) external pure;

    function checkPrice(
        uint160 price,
        PriceBounds memory bounds
    ) external pure;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../ICoverPoolStructs.sol';

interface ITwapSource {
    function initialize(
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
        uint8 initializable,
        int24 startingTick
    );

    function calculateAverageTick(
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        int24 averageTick
    );

    function getPool(
        address tokenA,
        address tokenB,
        uint16 feeTier
    ) external view returns (
        address pool
    );

    function feeTierTickSpacing(
        uint16 feeTier
    ) external view returns (
        int24 tickSpacing
    );

    function factory()
    external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import './EpochMap.sol';
import './TickMap.sol';
import './utils/String.sol';

library Claims {
    /////////// DEBUG FLAGS ///////////
    bool constant debugDeltas = true;

    function validate(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // validate position liquidity
        if (params.amount > cache.position.liquidity) require (false, 'NotEnoughPositionLiquidity()');
        if (cache.position.liquidity == 0) {
            cache.earlyReturn = true;
            return cache;
        }
        // if the position has not been crossed into at all
        else if (params.zeroForOne ? params.claim == params.upper 
                                        && EpochMap.get(params.upper, tickMap, constants) <= cache.position.accumEpochLast
                                     : params.claim == params.lower 
                                        && EpochMap.get(params.lower, tickMap, constants) <= cache.position.accumEpochLast
        ) {
            cache.earlyReturn = true;
            return cache;
        }
        // early return if no update and amount burned is 0
        if (
            (
                params.zeroForOne
                    ? params.claim == params.upper && cache.priceUpper != pool.price
                    : params.claim == params.lower && cache.priceLower != pool.price /// @dev - if pool price is start tick, set claimPriceLast to next tick crossed
            ) && params.claim == state.latestTick
        ) { if (params.amount == 0 && cache.position.claimPriceLast == pool.price) {
                cache.earlyReturn = true;
                return cache;
            } 
        } /// @dev - nothing to update if pool price hasn't moved
        
        // claim tick sanity checks
        else if (
            // claim tick is on a prior tick
            cache.position.claimPriceLast > 0 &&
            (params.zeroForOne
                    ? cache.position.claimPriceLast < cache.priceClaim
                    : cache.position.claimPriceLast > cache.priceClaim
            ) && params.claim != state.latestTick
        ) require (false, 'InvalidClaimTick()'); /// @dev - wrong claim tick
        if (params.claim < params.lower || params.claim > params.upper) require (false, 'InvalidClaimTick()');

        uint32 claimTickEpoch = EpochMap.get(params.claim, tickMap, constants);

        // validate claim tick
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
             if (claimTickEpoch <= cache.position.accumEpochLast)
                require (false, 'WrongTickClaimedAt()');
        } else {
            // zero fill or partial fill
            uint32 claimTickNextAccumEpoch = params.zeroForOne
                ? EpochMap.get(TickMap.previous(params.claim, tickMap, constants), tickMap, constants)
                : EpochMap.get(TickMap.next(params.claim, tickMap, constants), tickMap, constants);
            ///@dev - next accumEpoch should not be greater
            if (claimTickNextAccumEpoch > cache.position.accumEpochLast) {
                //TODO: search for claim tick if necessary
                //TODO: limit search to within 1 closest word
                require (false, 'WrongTickClaimedAt()');
            }
        }
        if (params.claim != params.upper && params.claim != params.lower) {
            // check accumEpochLast on claim tick
            if (claimTickEpoch <= cache.position.accumEpochLast)
                require (false, 'WrongTickClaimedAt()');
            // prevent position overwriting at claim tick
            if (params.zeroForOne) {
                if (positions[params.owner][params.lower][params.claim].liquidity > 0) {
                    require (false, string.concat('UpdatePositionFirstAt(', String.from(params.lower), ', ', String.from(params.claim), ')'));
                }
            } else {
                if (positions[params.owner][params.claim][params.upper].liquidity > 0) {
                    require (false, string.concat('UpdatePositionFirstAt(', String.from(params.lower), ', ', String.from(params.claim), ')'));
                }
            }
            /// @dev - user cannot add liquidity if auction is active; checked for in Positions.validate()
        }
        return cache;
    }

    function getDeltas(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // transfer deltas into cache
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
            (cache.claimTick, cache.deltas) = Deltas.from(cache.claimTick, cache.deltas);
        } else {
            /// @dev - deltas are applied once per each tick claimed at
            /// @dev - deltas should never be applied if position is not crossed into
            // check if tick already claimed at
            bool transferDeltas = (cache.position.claimPriceLast == 0
                               && (params.claim != (params.zeroForOne ? params.upper : params.lower)))
                               || (params.zeroForOne ? cache.position.claimPriceLast > cache.priceClaim
                                                     : cache.position.claimPriceLast < cache.priceClaim && cache.position.claimPriceLast != 0);
            if (transferDeltas) {
                (cache.claimTick, cache.deltas) = Deltas.unstash(cache.claimTick, cache.deltas);
            }
        } /// @dev - deltas transfer from claim tick are replaced after applying changes
        return cache;
    }

    function applyDeltas(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        uint256 percentInDelta; uint256 percentOutDelta;
        if(cache.deltas.amountInDeltaMax > 0) { //TODO: if this is zero for some reason we can just give 100% of amountInDelta
            percentInDelta = uint256(cache.amountInFilledMax) * 1e38 / uint256(cache.deltas.amountInDeltaMax);
            percentInDelta = percentInDelta > 1e38 ? 1e38 : percentInDelta;
            if (cache.deltas.amountOutDeltaMax > 0) {
                percentOutDelta = uint256(cache.amountOutUnfilledMax) * 1e38 / uint256(cache.deltas.amountOutDeltaMax);
                percentOutDelta = percentOutDelta > 1e38 ? 1e38 : percentOutDelta;
            }
        }
        (cache.deltas, cache.finalDeltas) = Deltas.transfer(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);
        (cache.deltas, cache.finalDeltas) = Deltas.transferMax(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);

        uint128 fillFeeAmount = cache.finalDeltas.amountInDelta * state.fillFee / 1e6;
        if (params.zeroForOne) {
            state.protocolFees.token1 += fillFeeAmount;
        } else {
            state.protocolFees.token0 += fillFeeAmount;
        }
        cache.finalDeltas.amountInDelta -= fillFeeAmount;
        cache.position.amountIn  += cache.finalDeltas.amountInDelta;
        cache.position.amountOut += cache.finalDeltas.amountOutDelta;

        if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            // burn deltas on final tick of position
            cache.finalTick = Deltas.burnMaxMinus(cache.finalTick, cache.finalDeltas);
            if (params.claim == (params.zeroForOne ? params.upper : params.lower)) {
                (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
            } else {
                (cache.deltas, cache.claimTick) = Deltas.stash(cache.deltas, cache.claimTick);
            }
        } else {
            (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
        }
        return cache;
    }

    /// @dev - calculate claim portion of partially claimed previous auction
    function section1(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // delta check complete - update CPL for new position
        if(cache.position.claimPriceLast == 0) {
            cache.position.claimPriceLast = (params.zeroForOne ? cache.priceUpper 
                                                               : cache.priceLower);
        } else if (params.zeroForOne ? (cache.position.claimPriceLast != cache.priceUpper
                                        && cache.position.claimPriceLast > cache.priceClaim)
                                     : (cache.position.claimPriceLast != cache.priceLower
                                        && cache.position.claimPriceLast < cache.priceClaim))
        {
            // section 1 - complete previous auction claim
            {
                // amounts claimed on this update
                uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity,
                    cache.position.claimPriceLast,
                    params.zeroForOne ? cache.priceUpper
                                      : cache.priceLower,
                    params.zeroForOne,
                    constants.curve
                );
                //TODO: modify delta max on claim tick and lower : upper tick
                cache.amountInFilledMax    += amountInFilledMax;
                cache.amountOutUnfilledMax += amountOutUnfilledMax;
            }
            // move price to next tick in sequence for section 2
            cache.position.claimPriceLast  = params.zeroForOne ? constants.curve.getPriceAtTick(params.upper - constants.tickSpread, constants)
                                                               : constants.curve.getPriceAtTick(params.lower + constants.tickSpread, constants);
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section2(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 2 - position start up to claim tick
        if (params.zeroForOne ? cache.priceClaim < cache.position.claimPriceLast 
                              : cache.priceClaim > cache.position.claimPriceLast) {
            // calculate if we at least cover one full tick
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.maxRoundUp(
                cache.position.liquidity,
                cache.position.claimPriceLast,
                cache.priceClaim,
                params.zeroForOne,
                curve
            );
            cache.amountInFilledMax += amountInFilledMax;
            cache.amountOutUnfilledMax += amountOutUnfilledMax;
        }
        return cache;
    }

    /// @dev - calculate claim from current auction unfilled section
    function section3(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState memory pool,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 3 - current auction unfilled section
        if (params.amount > 0) {
            // remove if burn
            uint128 amountOutRemoved = uint128(
                params.zeroForOne
                    ? curve.getDx(params.amount, pool.price, cache.priceClaim, false)
                    : curve.getDy(params.amount, cache.priceClaim, pool.price, false)
            );
            uint128 amountInOmitted = uint128(
                params.zeroForOne
                    ? curve.getDy(params.amount, pool.price, cache.priceClaim, false)
                    : curve.getDx(params.amount, cache.priceClaim, pool.price, false)
            );
            // add to position
            cache.position.amountOut += amountOutRemoved;
            // modify max deltas to be burned
            cache.finalDeltas.amountInDeltaMax  += amountInOmitted;
            cache.finalDeltas.amountOutDeltaMax += amountOutRemoved;
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section4(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState memory pool,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 4 - current auction filled section
        {
            // amounts claimed on this update
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.maxAuction(
                cache.position.liquidity,
                (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim) 
                                        ? cache.position.claimPriceLast 
                                        : cache.priceSpread,
                pool.price,
                params.zeroForOne,
                curve
            );
            uint256 poolAmountInDeltaChange = uint256(cache.position.liquidity) * 1e38 
                                                / uint256(pool.liquidity) * uint256(pool.amountInDelta) / 1e38;   
            
            cache.position.amountIn += uint128(poolAmountInDeltaChange);
            pool.amountInDelta -= uint128(poolAmountInDeltaChange); //CHANGE POOL TO MEMORY
            cache.finalDeltas.amountInDeltaMax += amountInFilledMax;
            cache.finalDeltas.amountOutDeltaMax += amountOutUnfilledMax;
            /// @dev - record how much delta max was claimed
            if (params.amount < cache.position.liquidity) {
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity - params.amount,
                    (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim) 
                                            ? cache.position.claimPriceLast 
                                            : cache.priceSpread,
                    pool.price,
                    params.zeroForOne,
                    curve
                );
                pool.amountInDeltaMaxClaimed  += amountInFilledMax;
                pool.amountOutDeltaMaxClaimed += amountOutUnfilledMax;
            }
        }
        if (params.amount > 0 /// @ dev - if removing L and second claim on same tick
            && (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim)) {
                // reduce delta max claimed based on liquidity removed
                pool = Deltas.burnMaxPool(pool, cache, params, curve);
        }
        // modify claim price for section 5
        cache.priceClaim = cache.priceSpread;
        // save pool changes to cache
        cache.pool = pool;
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section5(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 5 - burned liquidity past claim tick
        {
            uint160 endPrice = params.zeroForOne ? cache.priceLower
                                                 : cache.priceUpper;
            if (params.amount > 0 && cache.priceClaim != endPrice) {
                // update max deltas based on liquidity removed
                uint128 amountInOmitted; uint128 amountOutRemoved;
                (
                    amountInOmitted,
                    amountOutRemoved
                ) = Deltas.max(
                    params.amount,
                    cache.priceClaim,
                    endPrice,
                    params.zeroForOne,
                    curve
                );
                cache.position.amountOut += amountOutRemoved;
                /// @auditor - we don't add to cache.amountInFilledMax and cache.amountOutUnfilledMax 
                ///            since this section of the curve is not reflected in the deltas
                if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
                    cache.finalDeltas.amountInDeltaMax += amountInOmitted;
                    cache.finalDeltas.amountOutDeltaMax += amountOutRemoved;
                }      
            }
        }
        return cache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';

library Deltas {

    function max(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0,
        ICurveMath curve
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? curve.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : curve.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? curve.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : curve.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
    }

    function maxRoundUp(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0,
        ICurveMath curve
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? curve.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : curve.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? curve.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : curve.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
    }

    function maxAuction(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool isPool0,
        ICurveMath curve
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? curve.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
                : curve.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? curve.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
                : curve.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
        );
    }

    function transfer(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaChange = uint128(uint256(fromDeltas.amountInDelta) * percentInTransfer / 1e38);
            if (amountInDeltaChange < fromDeltas.amountInDelta ) {
                fromDeltas.amountInDelta -= amountInDeltaChange;
                toDeltas.amountInDelta += amountInDeltaChange;
            } else {
                toDeltas.amountInDelta += fromDeltas.amountInDelta;
                fromDeltas.amountInDelta = 0;
            }
        }
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromDeltas.amountOutDelta) * percentOutTransfer / 1e38);
            if (amountOutDeltaChange < fromDeltas.amountOutDelta ) {
                fromDeltas.amountOutDelta -= amountOutDeltaChange;
                toDeltas.amountOutDelta += amountOutDeltaChange;
            } else {
                toDeltas.amountOutDelta += fromDeltas.amountOutDelta;
                fromDeltas.amountOutDelta = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function transferMax(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaMaxChange = uint128(uint256(fromDeltas.amountInDeltaMax) * percentInTransfer / 1e38);
            if (fromDeltas.amountInDeltaMax > amountInDeltaMaxChange) {
                fromDeltas.amountInDeltaMax -= amountInDeltaMaxChange;
                toDeltas.amountInDeltaMax += amountInDeltaMaxChange;
            } else {
                toDeltas.amountInDeltaMax += fromDeltas.amountInDeltaMax;
                fromDeltas.amountInDeltaMax = 0;
            }
        }
        {
            uint128 amountOutDeltaMaxChange = uint128(uint256(fromDeltas.amountOutDeltaMax) * percentOutTransfer / 1e38);
            if (fromDeltas.amountOutDeltaMax > amountOutDeltaMaxChange) {
                fromDeltas.amountOutDeltaMax -= amountOutDeltaMaxChange;
                toDeltas.amountOutDeltaMax   += amountOutDeltaMaxChange;
            } else {
                toDeltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
                fromDeltas.amountOutDeltaMax = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function burnMaxCache(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory burnTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory
    ) {
        fromDeltas.amountInDeltaMax -= (fromDeltas.amountInDeltaMax 
                                         < burnTick.amountInDeltaMaxMinus) ? fromDeltas.amountInDeltaMax
                                                                           : burnTick.amountInDeltaMaxMinus;
        if (fromDeltas.amountInDeltaMax == 1) {
            fromDeltas.amountInDeltaMax = 0; // handle rounding issues
        }
        fromDeltas.amountOutDeltaMax -= (fromDeltas.amountOutDeltaMax 
                                          < burnTick.amountOutDeltaMaxMinus) ? fromDeltas.amountOutDeltaMax
                                                                             : burnTick.amountOutDeltaMaxMinus;
        return fromDeltas;
    }

    function burnMaxMinus(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory burnDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory
    ) {
        fromTick.amountInDeltaMaxMinus -= (fromTick.amountInDeltaMaxMinus
                                            < burnDeltas.amountInDeltaMax) ? fromTick.amountInDeltaMaxMinus
                                                                           : burnDeltas.amountInDeltaMax;
        if (fromTick.amountInDeltaMaxMinus == 1) {
            fromTick.amountInDeltaMaxMinus = 0; // handle rounding issues
        }
        fromTick.amountOutDeltaMaxMinus -= (fromTick.amountOutDeltaMaxMinus 
                                             < burnDeltas.amountOutDeltaMax) ? fromTick.amountOutDeltaMaxMinus
                                                                                  : burnDeltas.amountOutDeltaMax;
        return fromTick;
    }

    function burnMaxPool(
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.PoolState memory
    )
    {
        uint128 amountInMaxClaimedBefore; uint128 amountOutMaxClaimedBefore;
        (
            amountInMaxClaimedBefore,
            amountOutMaxClaimedBefore
        ) = maxAuction(
            params.amount,
            cache.priceSpread,
            cache.position.claimPriceLast,
            params.zeroForOne,
            curve
        );
        pool.amountInDeltaMaxClaimed  -= pool.amountInDeltaMaxClaimed > amountInMaxClaimedBefore ? amountInMaxClaimedBefore
                                                                                                 : pool.amountInDeltaMaxClaimed;
        pool.amountOutDeltaMaxClaimed -= pool.amountOutDeltaMaxClaimed > amountOutMaxClaimedBefore ? amountOutMaxClaimedBefore
                                                                                                   : pool.amountOutDeltaMaxClaimed;
        return pool;
    }

    function from(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        uint256 percentOnTick = uint256(fromTick.deltas.amountInDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountInDeltaMax) + uint256(fromTick.amountInDeltaMaxStashed));
        {
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
            toDeltas.amountInDeltaMax += fromTick.deltas.amountInDeltaMax;
            fromTick.deltas.amountInDeltaMax = 0;
        }
        percentOnTick = uint256(fromTick.deltas.amountOutDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountOutDeltaMax) + uint256(fromTick.amountOutDeltaMaxStashed));
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
            toDeltas.amountOutDeltaMax += fromTick.deltas.amountOutDeltaMax;
            fromTick.deltas.amountOutDeltaMax = 0;
        }
        return (fromTick, toDeltas);
    }

    function to(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.deltas.amountInDeltaMax  += fromDeltas.amountInDeltaMax;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDelta;
        toTick.deltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function stash(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        // store deltas on tick
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDelta;
        // store delta maxes on stashed deltas
        toTick.amountInDeltaMaxStashed  += fromDeltas.amountInDeltaMax;
        toTick.amountOutDeltaMaxStashed += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function unstash(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        toDeltas.amountInDeltaMax  += fromTick.amountInDeltaMaxStashed;
        toDeltas.amountOutDeltaMax += fromTick.amountOutDeltaMaxStashed;
        
        uint256 totalDeltaMax = uint256(fromTick.amountInDeltaMaxStashed) + uint256(fromTick.deltas.amountInDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountInDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentStashed / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
        }
        
        totalDeltaMax = uint256(fromTick.amountOutDeltaMaxStashed) + uint256(fromTick.deltas.amountOutDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountOutDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentStashed / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
        }

        fromTick.amountInDeltaMaxStashed = 0;
        fromTick.amountOutDeltaMaxStashed = 0;
        return (fromTick, toDeltas);
    }

    function update(
        ICoverPoolStructs.Tick memory tick,
        uint128 amount,
        uint160 priceLower,
        uint160 priceUpper,
        bool   isPool0,
        bool   isAdded,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        // update max deltas
        uint128 amountInDeltaMax; uint128 amountOutDeltaMax;
        if (isPool0) {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceUpper, priceLower, true, curve);
        } else {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceLower, priceUpper, false, curve);
        }
        if (isAdded) {
            tick.amountInDeltaMaxMinus  += amountInDeltaMax;
            tick.amountOutDeltaMaxMinus += amountOutDeltaMax;
        } else {
            tick.amountInDeltaMaxMinus  -= tick.amountInDeltaMaxMinus  > amountInDeltaMax ? amountInDeltaMax
                                                                                          : tick.amountInDeltaMaxMinus;
            tick.amountOutDeltaMaxMinus -= tick.amountOutDeltaMaxMinus > amountOutDeltaMax ? amountOutDeltaMax                                                                           : tick.amountOutDeltaMaxMinus;
        }
        return (tick, ICoverPoolStructs.Deltas(0,0,amountInDeltaMax, amountOutDeltaMax));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';

library EpochMap {
    function set(
        int24  tick,
        uint256 epoch,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);
        // assert epoch isn't bigger than max uint32
        uint256 epochValue = tickMap.epochs[volumeIndex][blockIndex][wordIndex];
        // clear previous value
        epochValue &=  ~(((1 << 9) - 1) << ((tickIndex & 0x7) * 32));
        // add new value to word
        epochValue |= epoch << ((tickIndex & 0x7) * 32);
        // store word in map
        tickMap.epochs[volumeIndex][blockIndex][wordIndex] = epochValue;
    }

    function unset(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);

        uint256 epochValue = tickMap.epochs[volumeIndex][blockIndex][wordIndex];
        // clear previous value
        epochValue &= ~(1 << (tickIndex & 0x7 * 32) - 1);
        // store word in map
        tickMap.epochs[volumeIndex][blockIndex][wordIndex] = epochValue;
    }

    function get(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        uint32 epoch
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);

        uint256 epochValue = tickMap.epochs[volumeIndex][blockIndex][wordIndex];
        // right shift so first 8 bits are epoch value
        epochValue >>= ((tickIndex & 0x7) * 32);
        // clear other bits
        epochValue &= ((1 << 32) - 1);
        return uint32(epochValue);
    }

    function getIndices(
        int24 tick,
        ICoverPoolStructs.Immutables memory constants
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        )
    {
        unchecked {
            if (tick > constants.curve.maxTick(constants.tickSpread)) require (false, 'TickIndexOverflow()');
            if (tick < constants.curve.minTick(constants.tickSpread)) require (false, 'TickIndexUnderflow()');
            if (tick % constants.tickSpread != 0) require (false, 'TickIndexInvalid()');
            tickIndex = uint256(int256((tick - constants.curve.minTick(constants.tickSpread))) / constants.tickSpread);
            wordIndex = tickIndex >> 3;        // 2^3 epochs per word
            blockIndex = tickIndex >> 11;      // 2^8 words per block
            volumeIndex = tickIndex >> 19;     // 2^8 blocks per volume
            if (blockIndex > 1023) require (false, 'BlockIndexOverflow()');
        }
    }

    function _tick (
        uint256 tickIndex,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(constants.curve.maxTick(constants.tickSpread) * 2)) require (false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * int256(constants.tickSpread) + constants.curve.maxTick(constants.tickSpread));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/modules/sources/ITwapSource.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './Deltas.sol';
import './TickMap.sol';
import './EpochMap.sol';

library Epochs {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    event Sync(
        uint160 pool0Price,
        uint160 pool1Price,
        uint128 pool0Liquidity,
        uint128 pool1Liquidity,
        uint32 auctionStart,
        uint32 accumEpoch,
        int24 oldLatestTick,
        int24 newLatestTick
    );

    event FinalDeltasAccumulated(
        uint128 amountInDelta,
        uint128 amountOutDelta,
        uint32 accumEpoch,
        int24 accumTick,
        bool isPool0
    );

    event StashDeltasCleared(
        int24 stashTick,
        bool isPool0
    );

    event StashDeltasAccumulated(
        uint128 amountInDelta,
        uint128 amountOutDelta,
        uint128 amountInDeltaMaxStashed,
        uint128 amountOutDeltaMaxStashed,
        uint32 accumEpoch,
        int24 stashTick,
        bool isPool0
    );

    event SyncFeesCollected(
        address collector,
        uint128 token0Amount,
        uint128 token1Amount
    );

    function simulateSync(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks0,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks1,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.PoolState memory pool0,
        ICoverPoolStructs.PoolState memory pool1,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        ICoverPoolStructs.GlobalState memory,
        ICoverPoolStructs.SyncFees memory,
        ICoverPoolStructs.PoolState memory,
        ICoverPoolStructs.PoolState memory
    ) {
        ICoverPoolStructs.AccumulateCache memory cache;
        {
            bool earlyReturn;
            (cache.newLatestTick, earlyReturn) = _syncTick(state, constants);
            if (earlyReturn) {
                return (state, ICoverPoolStructs.SyncFees(0, 0), pool0, pool1);
            }
            // else we have a TWAP update
        }

        // setup cache
        cache = ICoverPoolStructs.AccumulateCache({
            deltas0: ICoverPoolStructs.Deltas(0, 0, 0, 0), // deltas for pool0
            deltas1: ICoverPoolStructs.Deltas(0, 0, 0, 0),  // deltas for pool1
            syncFees: ICoverPoolStructs.SyncFees(0, 0),
            newLatestTick: cache.newLatestTick,
            nextTickToCross0: state.latestTick, // above
            nextTickToCross1: state.latestTick, // below
            nextTickToAccum0: TickMap.previous(state.latestTick, tickMap, constants), // below
            nextTickToAccum1: TickMap.next(state.latestTick, tickMap, constants),     // above
            stopTick0: (cache.newLatestTick > state.latestTick) // where we do stop for pool0 sync
                ? state.latestTick - constants.tickSpread
                : cache.newLatestTick, 
            stopTick1: (cache.newLatestTick > state.latestTick) // where we do stop for pool1 sync
                ? cache.newLatestTick
                : state.latestTick + constants.tickSpread
        });

        while (true) {
            // rollover and calculate sync fees
            (cache, pool0) = _rollover(state, cache, pool0, constants, true);
            // keep looping until accumulation reaches stopTick0 
            if (cache.nextTickToAccum0 >= cache.stopTick0) {
                (pool0.liquidity, cache.nextTickToCross0, cache.nextTickToAccum0) = _cross(
                    ticks0[cache.nextTickToAccum0].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    true
                );
            } else break;
        }

        while (true) {
            (cache, pool1) = _rollover(state, cache, pool1, constants, false);
            // keep looping until accumulation reaches stopTick1 
            if (cache.nextTickToAccum1 <= cache.stopTick1) {
                (pool1.liquidity, cache.nextTickToCross1, cache.nextTickToAccum1) = _cross(
                    ticks1[cache.nextTickToAccum1].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    false
                );
            } else break;
        }

        // update ending pool price for fully filled auction
        state.latestPrice = constants.curve.getPriceAtTick(cache.newLatestTick, constants);
        
        // set pool price and liquidity
        if (cache.newLatestTick > state.latestTick) {
            pool0.liquidity = 0;
            pool0.price = state.latestPrice;
            pool1.price = constants.curve.getPriceAtTick(cache.newLatestTick + constants.tickSpread, constants);
        } else {
            pool1.liquidity = 0;
            pool0.price = constants.curve.getPriceAtTick(cache.newLatestTick - constants.tickSpread, constants);
            pool1.price = state.latestPrice;
        }
        
        // set auction start as an offset of the pool genesis block
        state.auctionStart = uint32(block.timestamp) - constants.genesisTime;
        state.latestTick = cache.newLatestTick;
    
        return (state, cache.syncFees, pool0, pool1);
    }

    function syncLatest(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks0,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks1,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.PoolState memory pool0,
        ICoverPoolStructs.PoolState memory pool1,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
        ICoverPoolStructs.GlobalState memory,
        ICoverPoolStructs.SyncFees memory,
        ICoverPoolStructs.PoolState memory,
        ICoverPoolStructs.PoolState memory
    )
    {
        ICoverPoolStructs.AccumulateCache memory cache;
        {
            bool earlyReturn;
            (cache.newLatestTick, earlyReturn) = _syncTick(state, constants);
            if (earlyReturn) {
                return (state, ICoverPoolStructs.SyncFees(0,0), pool0, pool1);
            }
            // else we have a TWAP update
        }

        // increase epoch counter
        state.accumEpoch += 1;

        // setup cache
        cache = ICoverPoolStructs.AccumulateCache({
            deltas0: ICoverPoolStructs.Deltas(0, 0, 0, 0), // deltas for pool0
            deltas1: ICoverPoolStructs.Deltas(0, 0, 0, 0),  // deltas for pool1
            syncFees: ICoverPoolStructs.SyncFees(0,0),
                newLatestTick: cache.newLatestTick,
            nextTickToCross0: state.latestTick, // above
            nextTickToCross1: state.latestTick, // below
            nextTickToAccum0: TickMap.previous(state.latestTick, tickMap, constants), // below
            nextTickToAccum1: TickMap.next(state.latestTick, tickMap, constants),     // above
            stopTick0: (cache.newLatestTick > state.latestTick) // where we do stop for pool0 sync
                ? state.latestTick - constants.tickSpread
                : cache.newLatestTick, 
            stopTick1: (cache.newLatestTick > state.latestTick) // where we do stop for pool1 sync
                ? cache.newLatestTick
                : state.latestTick + constants.tickSpread
        });

        while (true) {
            // get values from current auction
            (cache, pool0) = _rollover(state, cache, pool0, constants, true);
            if (cache.nextTickToAccum0 > cache.stopTick0 
                 && ticks0[cache.nextTickToAccum0].amountInDeltaMaxMinus > 0) {
                EpochMap.set(cache.nextTickToAccum0, state.accumEpoch, tickMap, constants);
            }
            // accumulate to next tick
            ICoverPoolStructs.AccumulateParams memory params = ICoverPoolStructs.AccumulateParams({
                deltas: cache.deltas0,
                crossTick: ticks0[cache.nextTickToCross0],
                accumTick: ticks0[cache.nextTickToAccum0],
                updateAccumDeltas: cache.newLatestTick > state.latestTick
                                            ? cache.nextTickToAccum0 == cache.stopTick0
                                            : cache.nextTickToAccum0 >= cache.stopTick0,
                isPool0: true
            });
            params = _accumulate(
                cache,
                params,
                state
            );
            /// @dev - deltas in cache updated after _accumulate
            cache.deltas0 = params.deltas;
            ticks0[cache.nextTickToCross0] = params.crossTick;
            ticks0[cache.nextTickToAccum0] = params.accumTick;
            
            // keep looping until accumulation reaches stopTick0 
            if (cache.nextTickToAccum0 >= cache.stopTick0) {
                (pool0.liquidity, cache.nextTickToCross0, cache.nextTickToAccum0) = _cross(
                    ticks0[cache.nextTickToAccum0].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    true
                );
            } else break;
        }
        // pool0 checkpoint
        {
            // create stopTick0 if necessary
            if (cache.nextTickToAccum0 != cache.stopTick0) {
                TickMap.set(cache.stopTick0, tickMap, constants);
            }
            ICoverPoolStructs.Tick memory stopTick0 = ticks0[cache.stopTick0];
            // checkpoint at stopTick0
            (stopTick0) = _stash(
                stopTick0,
                cache,
                state,
                pool0.liquidity,
                true
            );
            EpochMap.set(cache.stopTick0, state.accumEpoch, tickMap, constants);
            ticks0[cache.stopTick0] = stopTick0;
        }

        while (true) {
            // rollover deltas pool1
            (cache, pool1) = _rollover(state, cache, pool1, constants, false);
            // accumulate deltas pool1
            if (cache.nextTickToAccum1 < cache.stopTick1 
                 && ticks1[cache.nextTickToAccum1].amountInDeltaMaxMinus > 0) {
                EpochMap.set(cache.nextTickToAccum1, state.accumEpoch, tickMap, constants);
            }
            {
                ICoverPoolStructs.AccumulateParams memory params = ICoverPoolStructs.AccumulateParams({
                    deltas: cache.deltas1,
                    crossTick: ticks1[cache.nextTickToCross1],
                    accumTick: ticks1[cache.nextTickToAccum1],
                    updateAccumDeltas: cache.newLatestTick > state.latestTick
                                                ? cache.nextTickToAccum1 <= cache.stopTick1
                                                : cache.nextTickToAccum1 == cache.stopTick1,
                    isPool0: false
                });
                params = _accumulate(
                    cache,
                    params,
                    state
                );
                /// @dev - deltas in cache updated after _accumulate
                cache.deltas1 = params.deltas;
                ticks1[cache.nextTickToCross1] = params.crossTick;
                ticks1[cache.nextTickToAccum1] = params.accumTick;
            }
            // keep looping until accumulation reaches stopTick1 
            if (cache.nextTickToAccum1 <= cache.stopTick1) {
                (pool1.liquidity, cache.nextTickToCross1, cache.nextTickToAccum1) = _cross(
                    ticks1[cache.nextTickToAccum1].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    false
                );
            } else break;
        }
        // pool1 checkpoint
        {
            // create stopTick1 if necessary
            if (cache.nextTickToAccum1 != cache.stopTick1) {
                TickMap.set(cache.stopTick1, tickMap, constants);
            }
            ICoverPoolStructs.Tick memory stopTick1 = ticks1[cache.stopTick1];
            // update deltas on stopTick
            (stopTick1) = _stash(
                stopTick1,
                cache,
                state,
                pool1.liquidity,
                false
            );
            ticks1[cache.stopTick1] = stopTick1;
            EpochMap.set(cache.stopTick1, state.accumEpoch, tickMap, constants);
        }
        // update ending pool price for fully filled auction
        state.latestPrice = constants.curve.getPriceAtTick(cache.newLatestTick, constants);
        
        // set pool price and liquidity
        if (cache.newLatestTick > state.latestTick) {
            pool0.liquidity = 0;
            pool0.price = state.latestPrice;
            pool1.price = constants.curve.getPriceAtTick(cache.newLatestTick + constants.tickSpread, constants);
        } else {
            pool1.liquidity = 0;
            pool0.price = constants.curve.getPriceAtTick(cache.newLatestTick - constants.tickSpread, constants);
            pool1.price = state.latestPrice;
        }
        
        // set auction start as an offset of the pool genesis block
        state.auctionStart = uint32(block.timestamp) - constants.genesisTime;

        // emit sync event
        emit Sync(pool0.price, pool1.price, pool0.liquidity, pool1.liquidity, state.auctionStart, state.accumEpoch, state.latestTick, cache.newLatestTick);
        
        // update latestTick
        state.latestTick = cache.newLatestTick;

        if (cache.syncFees.token0 > 0 || cache.syncFees.token1 > 0) {
            emit SyncFeesCollected(msg.sender, cache.syncFees.token0, cache.syncFees.token1);
        }
    
        return (state, cache.syncFees, pool0, pool1);
    }

    function _syncTick(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) internal view returns(
        int24 newLatestTick,
        bool
    ) {
        // update last block checked
        if(state.lastTime == uint32(block.timestamp) - constants.genesisTime) {
            return (state.latestTick, true);
        }
        state.lastTime = uint32(block.timestamp) - constants.genesisTime;
        // check auctions elapsed
        uint32 timeElapsed = state.lastTime - state.auctionStart;
        int32 auctionsElapsed = int32(timeElapsed / constants.twapLength) - 1; /// @dev - subtract 1 for 3/4 twapLength check
        // if 3/4 of twapLength has passed allow for latestTick move
        if (timeElapsed > 3 * constants.twapLength / 4) auctionsElapsed += 1;

        if (auctionsElapsed < 1) {
            return (state.latestTick, true);
        }
        newLatestTick = constants.source.calculateAverageTick(constants);
        /// @dev - shift up/down one quartile to put pool ahead of TWAP
        if (newLatestTick > state.latestTick)
             newLatestTick += constants.tickSpread / 4;
        else if (newLatestTick <= state.latestTick - 3 * constants.tickSpread / 4)
             newLatestTick -= constants.tickSpread / 4;
        newLatestTick = newLatestTick / constants.tickSpread * constants.tickSpread; // even multiple of tickSpread
        if (newLatestTick == state.latestTick) {
            return (state.latestTick, true);
        }

        // rate-limiting tick move
        int24 maxLatestTickMove = int24(constants.tickSpread * auctionsElapsed);

        /// @dev - latestTick can only move based on auctionsElapsed 
        if (newLatestTick > state.latestTick) {
            if (newLatestTick - state.latestTick > maxLatestTickMove)
                newLatestTick = state.latestTick + maxLatestTickMove;
        } else {
            if (state.latestTick - newLatestTick > maxLatestTickMove)
                newLatestTick = state.latestTick - maxLatestTickMove;
        }

        return (newLatestTick, false);
    }

    function _rollover(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.Immutables memory constants,
        bool isPool0
    ) internal pure returns (
        ICoverPoolStructs.AccumulateCache memory,
        ICoverPoolStructs.PoolState memory
    ) {
        //TODO: add syncing fee
        if (pool.liquidity == 0) {
            return (cache, pool);
        }
        uint160 crossPrice; uint160 accumPrice; uint160 currentPrice;
        if (isPool0) {
            crossPrice = constants.curve.getPriceAtTick(cache.nextTickToCross0, constants);
            int24 nextTickToAccum = (cache.nextTickToAccum0 < cache.stopTick0)
                                        ? cache.stopTick0
                                        : cache.nextTickToAccum0;
            accumPrice = constants.curve.getPriceAtTick(nextTickToAccum, constants);
            // check for multiple auction skips
            if (cache.nextTickToCross0 == state.latestTick && cache.nextTickToCross0 - nextTickToAccum > constants.tickSpread) {
                uint160 spreadPrice = constants.curve.getPriceAtTick(cache.nextTickToCross0 - constants.tickSpread, constants);
                /// @dev - amountOutDeltaMax accounted for down below
                cache.deltas0.amountOutDelta += uint128(constants.curve.getDx(pool.liquidity, accumPrice, spreadPrice, false));
            }
            currentPrice = pool.price;
            // if pool.price the bounds set currentPrice to start of auction
            if (!(pool.price > accumPrice && pool.price < crossPrice)) currentPrice = accumPrice;
            // if auction is current and fully filled => set currentPrice to crossPrice
            if (state.latestTick == cache.nextTickToCross0 && crossPrice == pool.price) currentPrice = crossPrice;
        } else {
            crossPrice = constants.curve.getPriceAtTick(cache.nextTickToCross1, constants);
            int24 nextTickToAccum = (cache.nextTickToAccum1 > cache.stopTick1)
                                        ? cache.stopTick1
                                        : cache.nextTickToAccum1;
            accumPrice = constants.curve.getPriceAtTick(nextTickToAccum, constants);
            // check for multiple auction skips
            if (cache.nextTickToCross1 == state.latestTick && nextTickToAccum - cache.nextTickToCross1 > constants.tickSpread) {
                uint160 spreadPrice = constants.curve.getPriceAtTick(cache.nextTickToCross1 + constants.tickSpread, constants);
                /// @dev - DeltaMax values accounted for down below
                cache.deltas1.amountOutDelta += uint128(constants.curve.getDy(pool.liquidity, spreadPrice, accumPrice, false));
            }
            currentPrice = pool.price;
            if (!(pool.price < accumPrice && pool.price > crossPrice)) currentPrice = accumPrice;
            if (state.latestTick == cache.nextTickToCross1 && crossPrice == pool.price) currentPrice = crossPrice;
        }

        //handle liquidity rollover
        if (isPool0) {
            {
                // amountIn pool did not receive
                uint128 amountInDelta;
                uint128 amountInDeltaMax  = uint128(constants.curve.getDy(pool.liquidity, accumPrice, crossPrice, false));
                amountInDelta       = pool.amountInDelta;
                amountInDeltaMax   -= (amountInDeltaMax < pool.amountInDeltaMaxClaimed) ? amountInDeltaMax 
                                                                                        : pool.amountInDeltaMaxClaimed;
                pool.amountInDelta  = 0;
                pool.amountInDeltaMaxClaimed = 0;

                // update cache in deltas
                cache.deltas0.amountInDelta     += amountInDelta;
                cache.deltas0.amountInDeltaMax  += amountInDeltaMax;
            }
            {
                // amountOut pool has leftover
                uint128 amountOutDelta    = uint128(constants.curve.getDx(pool.liquidity, currentPrice, crossPrice, false));
                uint128 amountOutDeltaMax = uint128(constants.curve.getDx(pool.liquidity, accumPrice, crossPrice, false));
                amountOutDeltaMax -= (amountOutDeltaMax < pool.amountOutDeltaMaxClaimed) ? amountOutDeltaMax
                                                                                        : pool.amountOutDeltaMaxClaimed;
                pool.amountOutDeltaMaxClaimed = 0;

                // calculate sync fee
                uint128 syncFeeAmount = state.syncFee * amountOutDelta / 1e6;
                cache.syncFees.token0 += syncFeeAmount;
                amountOutDelta -= syncFeeAmount;

                // update cache out deltas
                cache.deltas0.amountOutDelta    += amountOutDelta;
                cache.deltas0.amountOutDeltaMax += amountOutDeltaMax;
            }
        } else {
            {
                // amountIn pool did not receive
                uint128 amountInDelta;
                uint128 amountInDeltaMax = uint128(constants.curve.getDx(pool.liquidity, crossPrice, accumPrice, false));
                amountInDelta       = pool.amountInDelta;
                amountInDeltaMax   -= (amountInDeltaMax < pool.amountInDeltaMaxClaimed) ? amountInDeltaMax 
                                                                                        : pool.amountInDeltaMaxClaimed;
                pool.amountInDelta  = 0;
                pool.amountInDeltaMaxClaimed = 0;

                // update cache in deltas
                cache.deltas1.amountInDelta     += amountInDelta;
                cache.deltas1.amountInDeltaMax  += amountInDeltaMax;
            }
            {
                // amountOut pool has leftover
                uint128 amountOutDelta    = uint128(constants.curve.getDy(pool.liquidity, crossPrice, currentPrice, false));
                uint128 amountOutDeltaMax = uint128(constants.curve.getDy(pool.liquidity, crossPrice, accumPrice, false));
                amountOutDeltaMax -= (amountOutDeltaMax < pool.amountOutDeltaMaxClaimed) ? amountOutDeltaMax
                                                                                        : pool.amountOutDeltaMaxClaimed;
                pool.amountOutDeltaMaxClaimed = 0;

                // calculate sync fee
                uint128 syncFeeAmount = state.syncFee * amountOutDelta / 1e6;
                cache.syncFees.token1 += syncFeeAmount;
                amountOutDelta -= syncFeeAmount;    

                // update cache out deltas
                cache.deltas1.amountOutDelta    += amountOutDelta;
                cache.deltas1.amountOutDeltaMax += amountOutDeltaMax;
            }
        }
        return (cache, pool);
    }

    function _accumulate(
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.AccumulateParams memory params,
        ICoverPoolStructs.GlobalState memory state
    ) internal returns (
        ICoverPoolStructs.AccumulateParams memory
    ) {
        if (params.crossTick.amountInDeltaMaxStashed > 0) {
            /// @dev - else we migrate carry deltas onto cache
            // add carry amounts to cache
            (params.crossTick, params.deltas) = Deltas.unstash(params.crossTick, params.deltas);
            // clear out stash
            params.crossTick.amountInDeltaMaxStashed  = 0;
            params.crossTick.amountOutDeltaMaxStashed = 0;
            emit StashDeltasCleared(
                params.isPool0 ? cache.nextTickToCross0 : cache.nextTickToCross1,
                params.isPool0
            );
        }
        if (params.updateAccumDeltas) {
            // migrate carry deltas from cache to accum tick
            ICoverPoolStructs.Deltas memory accumDeltas;
            if (params.accumTick.amountInDeltaMaxMinus > 0) {
                // calculate percent of deltas left on tick
                uint256 percentInOnTick  = uint256(params.accumTick.amountInDeltaMaxMinus)  * 1e38 / (params.deltas.amountInDeltaMax);
                uint256 percentOutOnTick = uint256(params.accumTick.amountOutDeltaMaxMinus) * 1e38 / (params.deltas.amountOutDeltaMax);
                // transfer deltas to the accum tick
                (params.deltas, accumDeltas) = Deltas.transfer(params.deltas, accumDeltas, percentInOnTick, percentOutOnTick);
                
                // burn tick deltas maxes from cache
                params.deltas = Deltas.burnMaxCache(params.deltas, params.accumTick);
                
                // empty delta max minuses into delta max
                accumDeltas.amountInDeltaMax  += params.accumTick.amountInDeltaMaxMinus;
                accumDeltas.amountOutDeltaMax += params.accumTick.amountOutDeltaMaxMinus;

                // clear out delta max minus and save on tick
                params.accumTick.amountInDeltaMaxMinus  = 0;
                params.accumTick.amountOutDeltaMaxMinus = 0;
                params.accumTick.deltas = accumDeltas;

                emit FinalDeltasAccumulated(
                    accumDeltas.amountInDelta,
                    accumDeltas.amountOutDelta,
                    state.accumEpoch,
                    params.isPool0 ? cache.nextTickToAccum0 : cache.nextTickToAccum1,
                    params.isPool0
                );
            }
        }
        // remove all liquidity
        params.crossTick.liquidityDelta = 0;

        return params;
    }

    //maybe call ticks on msg.sender to get tick
    function _cross(
        int128 liquidityDelta,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants,
        int24 nextTickToCross,
        int24 nextTickToAccum,
        uint128 currentLiquidity,
        bool zeroForOne
    ) internal view returns (
        uint128,
        int24,
        int24
    )
    {
        nextTickToCross = nextTickToAccum;

        if (liquidityDelta > 0) {
            currentLiquidity += uint128(liquidityDelta);
        } else {
            currentLiquidity -= uint128(-liquidityDelta);
        }
        if (zeroForOne) {
            nextTickToAccum = TickMap.previous(nextTickToAccum, tickMap, constants);
        } else {
            nextTickToAccum = TickMap.next(nextTickToAccum, tickMap, constants);
        }
        return (currentLiquidity, nextTickToCross, nextTickToAccum);
    }

    function _stash(
        ICoverPoolStructs.Tick memory stashTick,
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.GlobalState memory state,
        uint128 currentLiquidity,
        bool isPool0
    ) internal returns (ICoverPoolStructs.Tick memory) {
        // return since there is nothing to update
        if (currentLiquidity == 0) return (stashTick);
        // handle deltas
        ICoverPoolStructs.Deltas memory deltas = isPool0 ? cache.deltas0 : cache.deltas1;
        emit StashDeltasAccumulated(
            deltas.amountInDelta,
            deltas.amountOutDelta,
            deltas.amountInDeltaMax,
            deltas.amountOutDeltaMax,
            state.accumEpoch,
            isPool0 ? cache.stopTick0 : cache.stopTick1,
            isPool0
        );
        if (deltas.amountInDeltaMax > 0) {
            (deltas, stashTick) = Deltas.stash(deltas, stashTick);
        }
        stashTick.liquidityDelta += int128(currentLiquidity);
        return (stashTick);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library FullPrecisionMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDiv(a, b, denominator);
    }

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) external pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDivRoundingUp(a, b, denominator);
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b.
            // Compute the product mod 2**256 and mod 2**256 - 1,
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product.
            uint256 prod1; // Most significant 256 bits of the product.
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }
            // Make sure the result is less than 2**256 -
            // also prevents denominator == 0.
            require(denominator > prod1);
            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////
            // Make division exact by subtracting the remainder from [prod1 prod0] -
            // compute remainder using mulmod.
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number.
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            // Factor powers of two out of denominator -
            // compute largest power of two divisor of denominator
            // (always >= 1).
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two.
            assembly {
                denominator := div(denominator, twos)
            }
            // Divide [prod1 prod0] by the factors of two.
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos -
            // if twos is zero, then it becomes one.
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            // Invert denominator mod 2**256 -
            // now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // for four bits. That is, denominator * inv = 1 mod 2**4.
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // Inverse mod 2**8.
            inv *= 2 - denominator * inv; // Inverse mod 2**16.
            inv *= 2 - denominator * inv; // Inverse mod 2**32.
            inv *= 2 - denominator * inv; // Inverse mod 2**64.
            inv *= 2 - denominator * inv; // Inverse mod 2**128.
            inv *= 2 - denominator * inv; // Inverse mod 2**256.
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    function _mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = _mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                if (result >= type(uint256).max) require (false, 'MaxUintExceeded()');
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import './Ticks.sol';
import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './math/FullPrecisionMath.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import './Claims.sol';
import './EpochMap.sol';

/// @notice Position management library for ranged liquidity.
library Positions {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    event Mint(
        address indexed to,
        int24 lower,
        int24 upper,
        bool zeroForOne,
        uint32 epochLast,
        uint128 amountIn,
        uint128 liquidityMinted,
        uint128 amountInDeltaMaxMinted,
        uint128 amountOutDeltaMaxMinted
    );

    event Burn(
        address indexed to,
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityBurned,
        uint128 tokenInClaimed,
        uint128 tokenOutClaimed,
        uint128 tokenOutBurned,
        uint128 amountInDeltaMaxStashedBurned,
        uint128 amountOutDeltaMaxStashedBurned,
        uint128 amountInDeltaMaxBurned,
        uint128 amountOutDeltaMaxBurned,
        uint160 claimPriceLast
    );

    function resize(
        ICoverPoolStructs.Position memory position,
        ICoverPoolStructs.MintParams memory params,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) external pure returns (
        ICoverPoolStructs.MintParams memory,
        uint256
    )
    {
        constants.curve.checkTicks(params.lower, params.upper, constants.tickSpread);

        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: position,
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            requiredStart: params.zeroForOne ? state.latestTick - int24(constants.tickSpread) * constants.minPositionWidth
                                             : state.latestTick + int24(constants.tickSpread) * constants.minPositionWidth,
            auctionCount: uint24((params.upper - params.lower) / constants.tickSpread),
            priceLower: constants.curve.getPriceAtTick(params.lower, constants),
            priceUpper: constants.curve.getPriceAtTick(params.upper, constants),
            priceAverage: 0,
            liquidityMinted: 0,
            denomTokenIn: true
        });

        // cannot mint empty position
        if (params.amount == 0) require (false, 'PositionAmountZero()');

        // enforce safety window
        if (params.zeroForOne) {    
            if (params.lower >= cache.requiredStart) require (false, 'PositionInsideSafetyWindow()'); 
        } else {
            if (params.upper <= cache.requiredStart) require (false, 'PositionInsideSafetyWindow()');
        }

        cache.liquidityMinted = constants.curve.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            params.zeroForOne ? cache.priceLower : cache.priceUpper,
            params.zeroForOne ? 0 : uint256(params.amount),
            params.zeroForOne ? uint256(params.amount) : 0
        );

        // handle partial mints
        if (params.zeroForOne) {
            if (params.upper > cache.requiredStart) {
                params.upper = cache.requiredStart;
                uint256 priceNewUpper = constants.curve.getPriceAtTick(params.upper, constants);
                params.amount -= uint128(
                    constants.curve.getDx(cache.liquidityMinted, priceNewUpper, cache.priceUpper, false)
                );
                cache.priceUpper = uint160(priceNewUpper);
            }
            // update auction count
            cache.auctionCount = uint24((params.upper - params.lower) / constants.tickSpread);
            if (cache.auctionCount == 0) require (false, 'InvalidPositionWidth()');
        } else {
            if (params.lower < cache.requiredStart) {
                params.lower = cache.requiredStart;
                uint256 priceNewLower = constants.curve.getPriceAtTick(params.lower, constants);
                params.amount -= uint128(
                    constants.curve.getDy(cache.liquidityMinted, cache.priceLower, priceNewLower, false)
                );
                cache.priceLower = uint160(priceNewLower);
            }
            // update auction count
            cache.auctionCount = uint24((params.upper - params.lower) / constants.tickSpread);
            if (cache.auctionCount == 0) require (false, 'InvalidPositionWidth()');
        }
        // enforce minimum position width
        if (cache.auctionCount < uint16(constants.minPositionWidth)) require (false, 'InvalidPositionWidth()');
        if (cache.liquidityMinted > uint128(type(int128).max)) require (false, 'LiquidityOverflow()');

        // enforce minimum amount per auction
        _size(
            ICoverPoolStructs.SizeParams(
                cache.priceLower,
                cache.priceUpper,
                uint128(position.liquidity + cache.liquidityMinted),
                params.zeroForOne,
                state.latestTick,
                cache.auctionCount
            ),
            constants
        );
 
        return (
            params,
            cache.liquidityMinted
        );
    }

    function add(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.AddParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
        ICoverPoolStructs.GlobalState memory
    )    
    {
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.to][params.lower][params.upper],
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            requiredStart: 0,
            auctionCount: 0,
            priceLower: constants.curve.getPriceAtTick(params.lower, constants),
            priceUpper: constants.curve.getPriceAtTick(params.upper, constants),
            priceAverage: 0,
            liquidityMinted: 0,
            denomTokenIn: true
        });
        /// call if claim != lower and liquidity being added
        /// initialize new position
        if (params.amount == 0) return state;
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = state.accumEpoch;
        } else {
            // safety check in case we somehow get here
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        EpochMap.get(TickMap.previous(params.upper, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        EpochMap.get(TickMap.next(params.lower, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
            ) {
                require (false, 'WrongTickClaimedAt()');
            }
        }
        
        // add liquidity to ticks
        Ticks.insert(
            ticks,
            tickMap,
            state,
            constants,
            params.lower,
            params.upper,
            uint128(params.amount),
            params.zeroForOne
        );

        // update liquidity global
        state.liquidityGlobal += params.amount;

        {
            // update max deltas
            ICoverPoolStructs.Tick memory finalTick = ticks[params.zeroForOne ? params.lower : params.upper];
            (finalTick, cache.deltas) = Deltas.update(finalTick, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, true, constants.curve);
            ticks[params.zeroForOne ? params.lower : params.upper] = finalTick;
        }

        cache.position.liquidity += uint128(params.amount);

        positions[params.to][params.lower][params.upper] = cache.position;

        emit Mint(
                params.to,
                params.lower,
                params.upper,
                params.zeroForOne,
                state.accumEpoch,
                uint128(params.amountIn),
                uint128(params.amount),
                cache.deltas.amountInDeltaMax,
                cache.deltas.amountOutDeltaMax
        );

        return state;
    }

    function remove(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.RemoveParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external returns (uint128, ICoverPoolStructs.GlobalState memory) {
        // validate burn percentage
        if (params.amount > 1e38) require (false, 'InvalidBurnPercentage()');
        // initialize cache
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            requiredStart: params.zeroForOne ? state.latestTick - int24(constants.tickSpread) * constants.minPositionWidth
                                             : state.latestTick + int24(constants.tickSpread) * constants.minPositionWidth,
            auctionCount: uint24((params.upper - params.lower) / constants.tickSpread),
            priceLower: constants.curve.getPriceAtTick(params.lower, constants),
            priceUpper: constants.curve.getPriceAtTick(params.upper, constants),
            priceAverage: 0,
            liquidityMinted: 0,
            denomTokenIn: true
        });
        // convert percentage to liquidity amount
        params.amount = _convert(cache.position.liquidity, params.amount);
        // early return if no liquidity to remove
        if (params.amount == 0) return (0, state);
        if (params.amount > cache.position.liquidity) {
            require (false, 'NotEnoughPositionLiquidity()');
        } else {
            _size(
                ICoverPoolStructs.SizeParams(
                    cache.priceLower,
                    cache.priceUpper,
                    cache.position.liquidity - params.amount,
                    params.zeroForOne,
                    state.latestTick,
                    cache.auctionCount
                ),
                constants
            );
            /// @dev - validate needed in case user passes in wrong tick
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        EpochMap.get(TickMap.previous(params.upper, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        EpochMap.get(TickMap.next(params.lower, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
            ) {
                require (false, 'WrongTickClaimedAt()');
            }
        }

        Ticks.remove(
            ticks,
            tickMap,
            constants,
            params.lower,
            params.upper,
            params.amount,
            params.zeroForOne,
            true,
            true
        );

        // update liquidity global
        state.liquidityGlobal -= params.amount;

        {
            // update max deltas
            ICoverPoolStructs.Tick memory finalTick = ticks[params.zeroForOne ? params.lower : params.upper];
            (finalTick, cache.deltas) = Deltas.update(finalTick, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, false, constants.curve);
            ticks[params.zeroForOne ? params.lower : params.upper] = finalTick;
        }

        cache.position.amountOut += uint128(
            params.zeroForOne
                ? constants.curve.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                : constants.curve.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
        );

        cache.position.liquidity -= uint128(params.amount);
        positions[params.owner][params.lower][params.upper] = cache.position;

        if (params.amount > 0) {
            emit Burn(
                    params.to,
                    params.lower,
                    params.upper,
                    params.zeroForOne ? params.upper : params.lower,
                    params.zeroForOne,
                    params.amount,
                    0, 0,
                    cache.position.amountOut,
                    0, 0,
                    cache.deltas.amountInDeltaMax,
                    cache.deltas.amountOutDeltaMax,
                    cache.position.claimPriceLast
            );
        }
        return (params.amount, state);
    }

    function update(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState storage pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
            ICoverPoolStructs.GlobalState memory,
            int24
        )
    {
        ICoverPoolStructs.UpdatePositionCache memory cache;
        (
            cache,
            state
        ) = _deltas(
            positions,
            ticks,
            tickMap,
            state,
            pool,
            params,
            constants
        );

        if (cache.earlyReturn)
            return (state, params.claim);

        pool.amountInDelta = cache.pool.amountInDelta;
        pool.amountInDeltaMaxClaimed  = cache.pool.amountInDeltaMaxClaimed;
        pool.amountOutDeltaMaxClaimed = cache.pool.amountOutDeltaMaxClaimed;

        // save claim tick
        ticks[params.claim] = cache.claimTick;
        if (params.claim != (params.zeroForOne ? params.lower : params.upper))
            ticks[params.zeroForOne ? params.lower : params.upper] = cache.finalTick;
        
        // update pool liquidity
        if (state.latestTick == params.claim
            && params.claim != (params.zeroForOne ? params.lower : params.upper)
        ) pool.liquidity -= params.amount;
        
        if (params.amount > 0) {
            if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
                // only remove once if final tick of position
                cache.removeLower = false;
                cache.removeUpper = false;
            } else {
                params.zeroForOne ? cache.removeUpper = true 
                                  : cache.removeLower = true;
            }
            Ticks.remove(
                ticks,
                tickMap,
                constants,
                params.zeroForOne ? params.lower : params.claim,
                params.zeroForOne ? params.claim : params.upper,
                params.amount,
                params.zeroForOne,
                cache.removeLower,
                cache.removeUpper
            );
            // update position liquidity
            cache.position.liquidity -= uint128(params.amount);
            // update global liquidity
            state.liquidityGlobal -= params.amount;
        }

        (
            cache,
            params
        ) = _checkpoint(state, pool, params, constants, cache);

        // clear out old position
        if (params.zeroForOne ? params.claim != params.upper 
                              : params.claim != params.lower) {
            /// @dev - this also clears out position end claims
            if (params.zeroForOne ? params.claim == params.lower 
                                  : params.claim == params.upper) {
                // subtract remaining position liquidity out from global
                state.liquidityGlobal -= cache.position.liquidity;
            }
            delete positions[params.owner][params.lower][params.upper];
        }
        // force collection to the user
        // store cached position in memory
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = 0;
            cache.position.claimPriceLast = 0;
        }
        params.zeroForOne
            ? positions[params.owner][params.lower][params.claim] = cache.position
            : positions[params.owner][params.claim][params.upper] = cache.position;
        
        emit Burn(
            params.to,
            params.lower,
            params.upper,
            params.claim,
            params.zeroForOne,
            params.amount,
            cache.position.amountIn,
            cache.finalDeltas.amountOutDelta,
            cache.position.amountOut - cache.finalDeltas.amountOutDelta,
            uint128(cache.amountInFilledMax),
            uint128(cache.amountOutUnfilledMax),
            cache.finalDeltas.amountInDeltaMax,
            cache.finalDeltas.amountOutDeltaMax,
            cache.position.claimPriceLast
        );
        // return cached position in memory and transfer out
        return (state, params.claim);
    }

    function snapshot(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        ICoverPoolStructs.Position memory
    ) {
        ICoverPoolStructs.UpdatePositionCache memory cache;
        (
            cache,
            state
        ) = _deltas(
            positions,
            ticks,
            tickMap,
            state,
            pool,
            params,
            constants
        );

        if (cache.earlyReturn) {
            if (params.amount > 0)
                cache.position.amountOut += uint128(
                    params.zeroForOne
                        ? constants.curve.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                        : constants.curve.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
                );
            return cache.position;
        }

        if (params.amount > 0) {
            cache.position.liquidity -= uint128(params.amount);
        }
        // checkpoint claimPriceLast
        (
            cache,
            params
        ) = _checkpoint(state, pool, params, constants, cache);
        
        // clear position values if empty
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = 0;
            cache.position.claimPriceLast = 0;
        }    
        return cache.position;
    }

    function _convert(
        uint128 liquidity,
        uint128 percent
    ) internal pure returns (
        uint128
    ) {
        // convert percentage to liquidity amount
        if (percent > 1e38) require (false, 'InvalidBurnPercentage()');
        if (liquidity == 0 && percent > 0) require (false, 'NotEnoughPositionLiquidity()');
        return uint128(uint256(liquidity) * uint256(percent) / 1e38);
    }

    function _deltas(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal view returns (
        ICoverPoolStructs.UpdatePositionCache memory,
        ICoverPoolStructs.GlobalState memory
    ) {
        ICoverPoolStructs.UpdatePositionCache memory cache = ICoverPoolStructs.UpdatePositionCache({
            position: positions[params.owner][params.lower][params.upper],
            pool: pool,
            priceLower: constants.curve.getPriceAtTick(params.lower, constants),
            priceClaim: constants.curve.getPriceAtTick(params.claim, constants),
            priceUpper: constants.curve.getPriceAtTick(params.upper, constants),
            priceSpread: constants.curve.getPriceAtTick(params.zeroForOne ? params.claim - constants.tickSpread 
                                                                          : params.claim + constants.tickSpread,
                                                        constants),
            amountInFilledMax: 0,
            amountOutUnfilledMax: 0,
            claimTick: ticks[params.claim],
            finalTick: ticks[params.zeroForOne ? params.lower : params.upper],
            earlyReturn: false,
            removeLower: true,
            removeUpper: true,
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            finalDeltas: ICoverPoolStructs.Deltas(0,0,0,0)
        });

        params.amount = _convert(cache.position.liquidity, params.amount);

        // check claim is valid
        cache = Claims.validate(
            positions,
            tickMap,
            state,
            cache.pool,
            params,
            cache,
            constants
        );
        if (cache.earlyReturn) {
            return (cache, state);
        }
        if (params.amount > 0)
            _size(
                ICoverPoolStructs.SizeParams(
                    cache.priceLower,
                    cache.priceUpper,
                    cache.position.liquidity - params.amount,
                    params.zeroForOne,
                    state.latestTick,
                    uint24((params.upper - params.lower) / constants.tickSpread)
                ),
                constants
            );
        // get deltas from claim tick
        cache = Claims.getDeltas(cache, params);
        /// @dev - section 1 => position start - previous auction
        cache = Claims.section1(cache, params, constants);
        /// @dev - section 2 => position start -> claim tick
        cache = Claims.section2(cache, params, constants.curve);
        // check if auction in progress 
        if (params.claim == state.latestTick 
            && params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            /// @dev - section 3 => claim tick - unfilled section
            cache = Claims.section3(cache, params, cache.pool, constants.curve);
            /// @dev - section 4 => claim tick - filled section
            cache = Claims.section4(cache, params, cache.pool, constants.curve);
        }
        /// @dev - section 5 => claim tick -> position end
        cache = Claims.section5(cache, params, constants.curve);
        // adjust position amounts based on deltas
        cache = Claims.applyDeltas(state, cache, params);

        return (cache, state);
    }

    function _size(
        ICoverPoolStructs.SizeParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure  
    {
        // early return if 100% of position burned
        if (params.liquidityAmount == 0 || params.auctionCount == 0) return;
        // set minAmountPerAuction based on token decimals
        uint256 minAmountPerAuction; bool denomTokenIn;
        if (params.latestTick > 0) {
            if (constants.minAmountLowerPriced) {
                // token1 is the lower priced token
                denomTokenIn = !params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token1Decimals);
            } else {
                // token0 is the higher priced token
                denomTokenIn = params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token0Decimals);
            }
        } else {
            if (constants.minAmountLowerPriced) {
                // token0 is the lower priced token
                denomTokenIn = params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token0Decimals);
            } else {
                // token1 is the higher priced token
                denomTokenIn = !params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token1Decimals);
            }
        }
        if (params.zeroForOne) {
            //calculate amount in the position currently
            uint128 amount = uint128(constants.curve.getDx(
                params.liquidityAmount,
                params.priceLower,
                params.priceUpper,
                false
            ));
            if (denomTokenIn) {
                if (amount / params.auctionCount < minAmountPerAuction)
                    require (false, 'PositionAuctionAmountTooSmall()');
            } else {
                // denominate in incoming token
                uint256 priceAverage = (params.priceUpper + params.priceLower) / 2;
                uint256 convertedAmount = amount * priceAverage / Q96 
                                                 * priceAverage / Q96; // convert by squaring price
                if (convertedAmount / params.auctionCount < minAmountPerAuction) 
                    require (false, 'PositionAuctionAmountTooSmall()');
            }
        } else {
            uint128 amount = uint128(constants.curve.getDy(
                params.liquidityAmount,
                params.priceLower,
                params.priceUpper,
                false
            ));
            if (denomTokenIn) {
                // denominate in token1
                // calculate amount in position currently
                if (amount / params.auctionCount < minAmountPerAuction) 
                    require (false, 'PositionAuctionAmountTooSmall()');
            } else {
                // denominate in token0
                uint256 priceAverage = (params.priceUpper + params.priceLower) / 2;
                uint256 convertedAmount = amount * Q96 / priceAverage 
                                                 * Q96 / priceAverage; // convert by squaring price
                if (convertedAmount / params.auctionCount < minAmountPerAuction) 
                    require (false, 'PositionAuctionAmountTooSmall()');
            }
        }
    }

    function _checkpoint(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants,
        ICoverPoolStructs.UpdatePositionCache memory cache
    ) internal pure returns (
        ICoverPoolStructs.UpdatePositionCache memory,
        ICoverPoolStructs.UpdateParams memory
    ) {
        // update claimPriceLast
        cache.priceClaim = constants.curve.getPriceAtTick(params.claim, constants);
        cache.position.claimPriceLast = (params.claim == state.latestTick)
            ? pool.price
            : cache.priceClaim;
        /// @dev - if tick 0% filled, set CPL to latestTick
        if (pool.price == cache.priceSpread) cache.position.claimPriceLast = cache.priceClaim;
        /// @dev - if tick 100% filled, set CPL to next tick to unlock
        if (pool.price == cache.priceClaim && params.claim == state.latestTick){
            cache.position.claimPriceLast = cache.priceSpread;
            // set claim tick to claim + tickSpread
            params.claim = params.zeroForOne ? params.claim - constants.tickSpread
                                             : params.claim + constants.tickSpread;
        }
        return (cache, params);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';

library TickMap {
    function set(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
        bool exists
    )    
    {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, constants);

        // check if bit is already set
        uint256 word = tickMap.ticks[wordIndex] | 1 << (tickIndex & 0xFF);
        if (word == tickMap.ticks[wordIndex]) {
            return true;
        }

        tickMap.ticks[wordIndex]     = word; 
        tickMap.words[blockIndex]   |= 1 << (wordIndex & 0xFF); // same as modulus 255
        tickMap.blocks              |= 1 << blockIndex;
        return false;
    }

    function unset(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, constants);

        tickMap.ticks[wordIndex] &= ~(1 << (tickIndex & 0xFF));
        if (tickMap.ticks[wordIndex] == 0) {
            tickMap.words[blockIndex] &= ~(1 << (wordIndex & 0xFF));
            if (tickMap.words[blockIndex] == 0) {
                tickMap.blocks &= ~(1 << blockIndex);
            }
        }
    }

    function previous(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        int24 previousTick
    ) {
        unchecked {
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, constants);

            uint256 word = tickMap.ticks[wordIndex] & ((1 << (tickIndex & 0xFF)) - 1);
            if (word == 0) {
                uint256 block_ = tickMap.words[blockIndex] & ((1 << (wordIndex & 0xFF)) - 1);
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ((1 << blockIndex) - 1);
                    // assert(blockMap != 0);
                    // if blockMap == 0 return type(int24).min() or MIN_TICK

                    blockIndex = _msb(blockMap);
                    block_ = tickMap.words[blockIndex];
                }
                wordIndex = (blockIndex << 8) | _msb(block_);
                word = tickMap.ticks[wordIndex];
            }
            previousTick = _tick((wordIndex << 8) | _msb(word), constants);
        }
    }

    function next(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        int24 nextTick
    ) {
        unchecked {
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, constants);
            uint256 word = tickMap.ticks[wordIndex] & ~((1 << ((tickIndex & 0xFF) + 1)) - 1);
            if (word == 0) {
                uint256 block_ = tickMap.words[blockIndex] & ~((1 << ((wordIndex & 0xFF) + 1)) - 1);
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ~((1 << blockIndex + 1) - 1);
                    // assert(blockMap != 0);
                    //if blockMap == 0 return type(int24).max()

                    blockIndex = _lsb(blockMap);
                    block_ = tickMap.words[blockIndex];
                }
                wordIndex = (blockIndex << 8) | _lsb(block_);
                word = tickMap.ticks[wordIndex];
            }
            nextTick = _tick((wordIndex << 8) | _lsb(word), constants);
        }
    }

    function getIndices(
        int24 tick,
        ICoverPoolStructs.Immutables memory constants
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        )
    {
        unchecked {
            if (tick > constants.curve.maxTick(constants.tickSpread)) require (false, 'TickIndexOverflow()');
            if (tick < constants.curve.minTick(constants.tickSpread)) require (false, 'TickIndexUnderflow()');
            if (tick % constants.tickSpread != 0) require (false, 'TickIndexInvalid()');
            tickIndex = uint256(int256((tick - constants.curve.minTick(constants.tickSpread))) / constants.tickSpread);
            wordIndex = tickIndex >> 8;   // 2^8 ticks per word
            blockIndex = tickIndex >> 16; // 2^8 words per block
            if (blockIndex > 255) require (false, 'BlockIndexOverflow()');
        }
    }

    function _tick (
        uint256 tickIndex,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(constants.curve.maxTick(constants.tickSpread) * 2)) require (false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * int256(constants.tickSpread) + constants.curve.minTick(constants.tickSpread));
        }
    }

    function _msb(
        uint256 x
    ) internal pure returns (
        uint8 r
    ) {
        unchecked {
            assert(x > 0);
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    function _lsb(
        uint256 x
    ) internal pure returns (
        uint8 r
    ) {
        unchecked {
            assert(x > 0); // if x is 0 return 0
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
    
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../utils/CoverPoolErrors.sol';
import './math/FullPrecisionMath.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/modules/sources/ITwapSource.sol';
import './TickMap.sol';

/// @notice Tick management library for ranged liquidity.
library Ticks {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    event Initialize(
        int24 minTick,
        int24 maxTick,
        int24 latestTick,
        uint32 genesisTime,
        uint32 auctionStart,
        uint160 pool0Price,
        uint160 pool1Price
    );

    function quote(
        bool zeroForOne,
        uint160 priceLimit,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.SwapCache memory cache,
        ICoverPoolStructs.Immutables memory constants
    ) external pure returns (ICoverPoolStructs.SwapCache memory) {
        if ((zeroForOne ? priceLimit >= cache.price 
                        : priceLimit <= cache.price) 
            || cache.liquidity == 0 
            || cache.input == 0
        )
            return cache;
        uint256 nextPrice = state.latestPrice;
        // determine input boost from tick auction
        cache.auctionBoost = ((cache.auctionDepth <= constants.auctionLength) ? cache.auctionDepth
                                                                              : constants.auctionLength
                             ) * 1e14 / constants.auctionLength * uint16(constants.tickSpread);
        cache.inputBoosted = cache.input * (1e18 + cache.auctionBoost) / 1e18;
        if (zeroForOne) {
            // trade token 0 (x) for token 1 (y)
            // price decreases
            if (priceLimit > nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDx = constants.curve.getDx(cache.liquidity, nextPrice, cache.price, false);
            // check if all input is used
            if (cache.inputBoosted <= maxDx) {
                // calculate price after swap
                uint256 newPrice = constants.curve.getNewPrice(cache.price, cache.liquidity, cache.inputBoosted, zeroForOne);
                cache.output += constants.curve.getDy(cache.liquidity, newPrice, cache.price, false);
                cache.price = newPrice;
                cache.input = 0;
                cache.amountInDelta = cache.amountIn;
            } else if (maxDx > 0) {
                cache.output += constants.curve.getDy(cache.liquidity, nextPrice, cache.price, false);
                cache.price = nextPrice;
                cache.input -= maxDx * (1e18 - cache.auctionBoost) / 1e18; /// @dev - convert back to input amount
                cache.amountInDelta = cache.amountIn - cache.input;
            }
        } else {
            // price increases
            if (priceLimit < nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDy = constants.curve.getDy(cache.liquidity, cache.price, nextPrice, false);
            if (cache.inputBoosted <= maxDy) {
                // calculate price after swap
                uint256 newPrice = constants.curve.getNewPrice(cache.price, cache.liquidity, cache.inputBoosted, zeroForOne);
                cache.output += constants.curve.getDx(cache.liquidity, cache.price, newPrice, false);
                cache.price = newPrice;
                cache.input = 0;
                cache.amountInDelta = cache.amountIn;
            } else if (maxDy > 0) {
                cache.output += constants.curve.getDx(cache.liquidity, cache.price, nextPrice, false);
                cache.price = nextPrice;
                cache.input -= maxDy * (1e18 - cache.auctionBoost) / 1e18; 
                cache.amountInDelta = cache.amountIn - cache.input;
            }
        }
        return (cache);
    }

    function initialize(
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.PoolState storage pool0,
        ICoverPoolStructs.PoolState storage pool1,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants 
    ) external returns (ICoverPoolStructs.GlobalState memory) {
        if (state.unlocked == 0) {
            (state.unlocked, state.latestTick) = constants.source.initialize(constants);
            if (state.unlocked == 1) {
                // initialize state
                state.latestTick = (state.latestTick / int24(constants.tickSpread)) * int24(constants.tickSpread);
                state.latestPrice = constants.curve.getPriceAtTick(state.latestTick, constants);
                state.auctionStart = uint32(block.timestamp - constants.genesisTime);
                state.accumEpoch = 1;

                // initialize ticks
                TickMap.set(constants.curve.minTick(constants.tickSpread), tickMap, constants);
                TickMap.set(constants.curve.maxTick(constants.tickSpread), tickMap, constants);
                TickMap.set(state.latestTick, tickMap, constants);

                // initialize price
                pool0.price = constants.curve.getPriceAtTick(state.latestTick - constants.tickSpread, constants);
                pool1.price = constants.curve.getPriceAtTick(state.latestTick + constants.tickSpread, constants);
            
                emit Initialize(
                    constants.curve.minTick(constants.tickSpread),
                    constants.curve.maxTick(constants.tickSpread),
                    state.latestTick,
                    constants.genesisTime,
                    state.auctionStart,
                    pool0.price,
                    pool1.price
                );
            }
        }
        return state;
    }

    function insert(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants,
        int24 lower,
        int24 upper,
        uint128 amount,
        bool isPool0
    ) external {
        /// @dev - validation of ticks is in Positions.validate
        if (amount > uint128(type(int128).max)) require (false, 'LiquidityOverflow()');
        if ((uint128(type(int128).max) - state.liquidityGlobal) < amount)
            require (false, 'LiquidityOverflow()');

        // load ticks into memory to reduce reads/writes
        ICoverPoolStructs.Tick memory tickLower = ticks[lower];
        ICoverPoolStructs.Tick memory tickUpper = ticks[upper];

        // sets bit in map
        TickMap.set(lower, tickMap, constants);

        // updates liquidity values
        if (isPool0) {
                tickLower.liquidityDelta -= int128(amount);
        } else {
                tickLower.liquidityDelta += int128(amount);
        }

        TickMap.set(upper, tickMap, constants);

        if (isPool0) {
                tickUpper.liquidityDelta += int128(amount);
        } else {
            tickUpper.liquidityDelta -= int128(amount);
        }
        ticks[lower] = tickLower;
        ticks[upper] = tickUpper;
    }

    function remove(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants,
        int24 lower,
        int24 upper,
        uint128 amount,
        bool isPool0,
        bool removeLower,
        bool removeUpper
    ) external {
        {
            ICoverPoolStructs.Tick memory tickLower = ticks[lower];
            if (removeLower) {
                if (isPool0) {
                    tickLower.liquidityDelta += int128(amount);
                } else {
                    tickLower.liquidityDelta -= int128(amount);
                }
                ticks[lower] = tickLower;
            }
            if (lower != constants.curve.minTick(constants.tickSpread) && _empty(tickLower)) {
                TickMap.unset(lower, tickMap, constants);
            }
        }
        {
            ICoverPoolStructs.Tick memory tickUpper = ticks[upper];
            if (removeUpper) {
                if (isPool0) {
                    tickUpper.liquidityDelta -= int128(amount);
                } else {
                    tickUpper.liquidityDelta += int128(amount);
                }
                ticks[upper] = tickUpper;
            }
            if (upper != constants.curve.maxTick(constants.tickSpread) && _empty(tickUpper)) {
                TickMap.unset(upper, tickMap, constants);
            }
        }
    }

    function _empty(
        ICoverPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.amountInDeltaMaxStashed > 0 || tick.amountOutDeltaMaxStashed > 0) {
            return false;
        } else if (tick.amountInDeltaMaxMinus > 0 || tick.amountOutDeltaMaxMinus > 0){
            return false;
        } else if (tick.deltas.amountInDeltaMax > 0 || tick.deltas.amountOutDeltaMax > 0) {
            return false;
        } else if (tick.liquidityDelta != 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library String {
    bytes16 private constant alphabet = "0123456789abcdef";

    function from(bytes32 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function from(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function from(uint256 value) internal pure returns(string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), alphabet))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function from(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", from(abs(value))));
    }

    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

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

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract CoverPoolErrors {
    error Locked();
    error OwnerOnly();
    error InvalidToken();
    error InvalidPosition();
    error InvalidSwapFee();
    error InvalidTokenDecimals();
    error InvalidTickSpread();
    error LiquidityOverflow();
    error Token0Missing();
    error Token1Missing();
    error InvalidTick();
    error FactoryOnly();
    error LowerNotEvenTick();
    error UpperNotOddTick();
    error MaxTickLiquidity();
    error CollectToZeroAddress();
    error Overflow();
    error NotEnoughOutputLiquidity();
    error WaitUntilEnoughObservations();
}

abstract contract CoverTicksErrors {
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOrder();
    error WrongTickUpperOrder();
    error WrongTickClaimedAt();
}

abstract contract CoverMiscErrors {
    // to be removed before production
    error NotImplementedYet();
}

abstract contract CoverPositionErrors {
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
}

abstract contract CoverPoolFactoryErrors {
    error OwnerOnly();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
    error VolatilityTierNotSupported();
    error InvalidTickSpread();
    error TwapSourceNotFound();
    error CurveMathNotFound();
    error TickSpreadNotMultipleOfTickSpacing();
    error TickSpreadNotAtLeastDoubleTickSpread();
}

abstract contract CoverTransferErrors {
    error TransferFailed(address from, address dest);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../utils/CoverPoolErrors.sol';

abstract contract SafeTransfers is CoverTransferErrors {
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function _transferIn(address token, uint256 amount) internal virtual returns (uint256) {
        if (token == address(0)) {
            if (msg.value < amount) revert TransferFailed(msg.sender, address(this));
            return amount;
        }
        if (amount == 0) return 0;
        IERC20 erc20Token = IERC20(token);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transferFrom(msg.sender, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(msg.sender, address(this));

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function _transferOut(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        if (token == address(0)) {
            if (address(this).balance < amount) revert TransferFailed(address(this), to);
            payable(to).transfer(amount);
            return;
        }
        if (amount == 0) return;
        IERC20 erc20Token = IERC20(token);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(address(this), msg.sender);
    }
}