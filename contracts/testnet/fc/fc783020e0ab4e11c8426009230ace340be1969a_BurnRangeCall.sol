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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract LimitPoolFactoryStorage {
    mapping(bytes32 => address) public pools;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../structs/PoolsharkStructs.sol';

interface ITwapSource {
    function initialize(
        PoolsharkStructs.CoverImmutables memory constants
    ) external returns (
        uint8 initializable,
        int24 startingTick
    );

    function calculateAverageTick(
        PoolsharkStructs.CoverImmutables memory constants,
        int24 latestTick
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../interfaces/structs/PoolsharkStructs.sol';

interface IPool is PoolsharkStructs {
    function immutables() external view returns (LimitImmutables memory);
    
    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        QuoteParams memory params
    ) external view returns (
        int256 inAmount,
        int256 outAmount,
        uint160 priceAfter
    );

    function fees(
        FeesParams memory params
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function sample(
        uint32[] memory secondsAgo
    ) external view returns (
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    );

    function snapshotRange(
        uint32 positionId
    ) external view returns(
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    );

    function snapshotLimit(
        SnapshotLimitParams memory params
    ) external view returns(
        uint128 amountIn,
        uint128 amountOut
    );

    function globalState() external view returns (
        RangePoolState memory pool,
        LimitPoolState memory pool0,
        LimitPoolState memory pool1,
        uint128 liquidityGlobal,
        uint32 epoch,
        uint8 unlocked
    );

    function samples(uint256) external view returns (
        uint32,
        int56,
        uint160
    );

    function ticks(int24) external view returns (
        RangeTick memory,
        LimitTick memory
    );

    function positions(uint32) external view returns (
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        uint128 liquidity,
        int24 lower,
        int24 upper
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '../interfaces/structs/PoolsharkStructs.sol';
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPositionERC1155 is IERC165, PoolsharkStructs {
    event TransferSingle(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed account,
        address indexed sender,
        bool approve
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (
        uint256[] memory batchBalances
    );

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        PoolsharkStructs.LimitImmutables memory constants
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 amount,
        PoolsharkStructs.LimitImmutables memory constants
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/LimitPoolStructs.sol';

interface ILimitPool is LimitPoolStructs {
    function initialize(
        uint160 startPrice
    ) external;

    function mintLimit(
        MintLimitParams memory params
    ) external;

    function burnLimit(
        BurnLimitParams memory params
    ) external;

    function snapshotLimit(
        SnapshotLimitParams memory params
    ) external view returns(
        uint128,
        uint128
    );

    function fees(
        FeesParams memory params
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function immutables(
    ) external view returns(
        LimitImmutables memory
    );

    function priceBounds(
        int16 tickSpacing
    ) external pure returns (
        uint160 minPrice,
        uint160 maxPrice
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../structs/PoolsharkStructs.sol';
import '../../base/storage/LimitPoolFactoryStorage.sol';

abstract contract ILimitPoolFactory is LimitPoolFactoryStorage, PoolsharkStructs {
    function createLimitPool(
        LimitPoolParams memory params
    ) external virtual returns (
        address pool,
        address poolToken
    );

    function getLimitPool(
        address tokenIn,
        address tokenOut,
        uint16  swapFee,
        uint8   poolTypeId
    ) external view virtual returns (
        address pool,
        address poolToken
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/RangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is RangePoolStructs {
    function mintRange(
        MintRangeParams memory mintParams
    ) external;

    function burnRange(
        BurnRangeParams memory burnParams
    ) external;

    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        QuoteParams memory params
    ) external view returns (
        uint256 inAmount,
        uint256 outAmount,
        uint160 priceAfter
    );

    function snapshotRange(
        uint32 positionId
    ) external view returns(
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    );

    function sample(
        uint32[] memory secondsAgo
    ) external view returns(
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    );

    function increaseSampleCount(
        uint16 newSampleCountMax
    ) external;
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

interface IRangePoolFactory {
    function createRangePool(
        address fromToken,
        address destToken,
        uint16 fee,
        uint160 startPrice
    ) external returns (address book);

    function getRangePool(
        address fromToken,
        address destToken,
        uint256 fee
    ) external view returns (address);

    function owner() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/RangePoolStructs.sol';

interface IRangePoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function protocolFees(address pool) external view returns (uint16);
    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';

interface LimitPoolStructs is PoolsharkStructs {

    struct LimitPosition {
        uint128 liquidity; // expected amount to be used not actual
        uint32 epochLast;  // epoch when this position was created at
        int24 lower;       // lower price tick of position range
        int24 upper;       // upper price tick of position range
        bool crossedInto;  // whether the position was crossed into already
    }

    struct MintLimitCache {
        GlobalState state;
        LimitPosition position;
        LimitImmutables constants;
        LimitPoolState pool;
        SwapCache swapCache;
        uint256 liquidityMinted;
        uint256 mintSize;
        uint256 priceLimit;
        int256 amountIn;
        uint256 amountOut;
        uint256 priceLower;
        uint256 priceUpper;
        int24 tickLimit;
    }

    struct BurnLimitCache {
        GlobalState state;
        LimitPoolState pool;
        LimitTick claimTick;
        LimitPosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint128 liquidityBurned;
        uint128 amountIn;
        uint128 amountOut;
        int24 claim;
        bool removeLower;
        bool removeUpper;
    }

    struct InsertSingleLocals {
        int24 previousFullTick;
        int24 nextFullTick;
        uint256 priceNext;
        uint256 pricePrevious;
        uint256 amountInExact;
        uint256 amountOutExact;
        uint256 amountToCross;
    }

    struct GetDeltasLocals {
        int24 previousFullTick;
        uint256 pricePrevious;
        uint256 priceNext;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../cover/ITwapSource.sol';

interface PoolsharkStructs {
    struct GlobalState {
        RangePoolState pool;
        LimitPoolState pool0;
        LimitPoolState pool1;
        uint128 liquidityGlobal;
        uint32  positionIdNext;
        uint32 epoch;
        uint8 unlocked;
    }

    struct LimitPoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 protocolFees;
        uint16 protocolFillFee;
        int24 tickAtPrice;
    }

    struct RangePoolState {
        SampleState  samples;
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        uint160 secondsPerLiquidityAccum;
        uint160 price;               /// @dev Starting price current
        uint128 liquidity;           /// @dev Liquidity currently active
        int56   tickSecondsAccum;
        int24   tickAtPrice;
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
    }

    struct Tick {
        RangeTick range;
        LimitTick limit;
    }

    struct LimitTick {
        uint160 priceAt;
        int128 liquidityDelta;
        uint128 liquidityAbsolute;
    }

    struct RangeTick {
        uint200 feeGrowthOutside0;
        uint200 feeGrowthOutside1;
        uint160 secondsPerLiquidityAccumOutside;
        int56 tickSecondsAccumOutside;
        int128 liquidityDelta;
        uint128 liquidityAbsolute;
    }

    struct Sample {
        uint32  blockTimestamp;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct SampleState {
        uint16  index;
        uint16  count;
        uint16  countMax;
    }

    struct LimitPoolParams {
        address tokenIn;
        address tokenOut;
        uint160 startPrice;
        uint16  swapFee;
        uint8   poolTypeId;
    }

    struct SwapParams {
        address to;
        uint160 priceLimit;
        uint128  amount;
        bool exactIn;
        bool zeroForOne;
        bytes callbackData;
    }

    struct MintLimitParams {
        address to;
        uint128 amount;
        uint96 mintPercent;
        uint32 positionId;
        int24 lower;
        int24 upper;
        bool zeroForOne;
        bytes callbackData;
    }

    struct BurnLimitParams {
        address to;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
    }

    struct MintRangeParams {
        address to;
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 amount0;
        uint128 amount1;
        bytes callbackData;
    }

    struct BurnRangeParams {
        address to;
        uint32 positionId;
        uint128 burnPercent;
    }

    struct QuoteParams {
        uint160 priceLimit;
        uint128 amount;
        bool exactIn;
        bool zeroForOne;
    }

    struct FeesParams {
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
        uint16 protocolFillFee0;
        uint16 protocolFillFee1;
        uint8 setFeesFlags;
    }

    struct SnapshotLimitParams {
        address owner;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
    }

    /**
     * @custom:struct MintCoverParams
     */
    struct MintCoverParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the minted position
         */
        address to;

        /**
         * @custom:field amount
         * @notice Token amount to be deposited into the minted position
         */
        uint128 amount;

        /**
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;

        /**
         * @custom:field lower
         * @notice The lower price tick for the position range
         */
        int24 lower;

        /**
         * @custom:field upper
         * @notice The upper price tick for the position range
         */
        int24 upper;

        /**
         * @custom:field zeroForOne
         * @notice True if depositing token0, the first token address in lexographical order
         * @notice False if depositing token1, the second token address in lexographical order 
         */
        bool zeroForOne;

        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    /**
     * @custom:struct BurnCoverParams
     */
    struct BurnCoverParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the collected position amounts
         */
        address to;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;

        /**
         * @custom:field sync
         * @notice True will sync the pool latestTick
         * @notice False will skip syncing latestTick 
         */
        bool sync;
    }

    /**
     * @custom:struct SnapshotCoverParams
     */
    struct SnapshotCoverParams {
        /**
         * @custom:field to
         * @notice Address of the position owner
         */
        address owner;

        /**
         * @custom:field positionId
         * @notice id of position
         */
        uint32 positionId;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;
    }

    struct QuoteResults {
        address pool;
        int256 amountIn;
        int256 amountOut;
        uint160 priceAfter;
    }
    
    struct LimitImmutables {
        address owner;
        address poolImpl;
        address factory;
        PriceBounds bounds;
        address token0;
        address token1;
        address poolToken;
        uint32 genesisTime;
        int16 tickSpacing;
        uint16 swapFee;
    }

    struct CoverImmutables {
        ITwapSource source;
        PriceBounds bounds;
        address owner;
        address token0;
        address token1;
        address poolImpl;
        address poolToken;
        address inputPool;
        uint128 minAmountPerAuction;
        uint32 genesisTime;
        int16  minPositionWidth;
        int16  tickSpread;
        uint16 twapLength;
        uint16 auctionLength;
        uint16 sampleInterval;
        uint8 token0Decimals;
        uint8 token1Decimals;
        bool minAmountLowerPriced;
    }

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs0; /// @dev - ticks to epochs
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs1; /// @dev - ticks to epochs
    }

    struct SwapCache {
        GlobalState state;
        LimitImmutables constants;
        uint256 price;
        uint256 liquidity;
        uint256 amountLeft;
        uint256 input;
        uint256 output;
        uint160 crossPrice;
        uint160 averagePrice;
        uint160 secondsPerLiquidityAccum;
        uint128 feeAmount;
        int56   tickSecondsAccum;
        int56   tickSecondsAccumBase;
        int24   crossTick;
        uint8   crossStatus;
        bool    limitActive;
        bool    exactIn;
        bool    cross;
    }  

    enum CrossStatus {
        RANGE,
        LIMIT,
        BOTH
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';

interface RangePoolStructs is PoolsharkStructs {

    struct RangePosition {
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 liquidity;
        int24 lower;
        int24 upper;
    }

    struct CompoundRangeParams {
        uint160 priceLower;
        uint160 priceUpper;
        uint128 amount0;
        uint128 amount1;
        uint32 positionId;
    }

    struct SampleParams {
        uint16 sampleIndex;
        uint16 sampleLength;
        uint32 time;
        uint32[] secondsAgo;
        int24 tick;
        uint128 liquidity;
        PoolsharkStructs.LimitImmutables constants;
    }

    struct UpdateParams {
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 burnPercent;
    }

    struct MintRangeCache {
        GlobalState state;
        RangePosition position;
        PoolsharkStructs.LimitImmutables constants;
        address owner;
        uint256 liquidityMinted;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
    }

    struct BurnRangeCache {
        GlobalState state;
        RangePosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint256 liquidityBurned;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
    }

    struct RangePositionCache {
        uint256 liquidityAmount;
        uint256 rangeFeeGrowth0;
        uint256 rangeFeeGrowth1;
        uint128 amountFees0;
        uint128 amountFees1;
        uint128 feesBurned0;
        uint128 feesBurned1;
    }

    struct SnapshotRangeCache {
        RangePosition position;
        SampleState samples;
        PoolsharkStructs.LimitImmutables constants;
        uint160 price;
        uint160 secondsPerLiquidityAccum;
        uint160 secondsPerLiquidityAccumLower;
        uint160 secondsPerLiquidityAccumUpper;
        uint128 liquidity;
        uint128 amount0;
        uint128 amount1;
        int56   tickSecondsAccum;
        int56   tickSecondsAccumLower;
        int56   tickSecondsAccumUpper;
        uint32  secondsOutsideLower;
        uint32  secondsOutsideUpper;
        uint32  blockTimestamp;
        int24   tick;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../../interfaces/structs/LimitPoolStructs.sol';
import './EpochMap.sol';
import '../TickMap.sol';
import '../utils/String.sol';
import '../utils/SafeCast.sol';

library Claims {

    using SafeCast for uint256;

    function validate(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.BurnLimitParams memory params,
        LimitPoolStructs.BurnLimitCache memory cache
    ) internal view returns (
        PoolsharkStructs.BurnLimitParams memory,
        LimitPoolStructs.BurnLimitCache memory
    ) {
        // validate position liquidity
        if (cache.liquidityBurned > cache.position.liquidity) require (false, 'NotEnoughPositionLiquidity()');
        if (cache.position.liquidity == 0) {
            require(false, 'NoPositionLiquidityFound()');
        }
        
        if (params.claim < cache.position.lower ||
                params.claim > cache.position.upper)
            require (false, 'InvalidClaimTick()');

        uint32 claimTickEpoch = EpochMap.get(params.claim, params.zeroForOne, tickMap, cache.constants);

        if (params.zeroForOne){
            if (cache.pool.price >= cache.priceClaim) {
                if (cache.pool.price <= cache.priceUpper) {
                    cache.priceClaim = cache.pool.price;
                    params.claim = TickMap.roundBack(cache.pool.tickAtPrice, cache.constants, params.zeroForOne, cache.priceClaim);
                    claimTickEpoch = cache.state.epoch;
                } else {
                    cache.priceClaim = cache.priceUpper;
                    params.claim = cache.position.upper;
                    cache.claimTick = ticks[cache.position.upper].limit;
                }
                claimTickEpoch = cache.state.epoch;
            } else if (params.claim % cache.constants.tickSpacing != 0) {
                if (cache.claimTick.priceAt == 0) {
                    require (false, 'WrongTickClaimedAt1()');
                }
                cache.priceClaim = cache.claimTick.priceAt;
            }
        } else {
            if (cache.pool.price <= cache.priceClaim) {
                if (cache.pool.price >= cache.priceLower) {
                    cache.priceClaim = cache.pool.price;
                    params.claim = TickMap.roundBack(cache.pool.tickAtPrice, cache.constants, params.zeroForOne, cache.priceClaim);
                    claimTickEpoch = cache.state.epoch;
                } else {
                    cache.priceClaim = cache.priceLower;
                    params.claim = cache.position.lower;
                    cache.claimTick = ticks[cache.position.upper].limit;

                }
                claimTickEpoch = cache.state.epoch;
            } else if (params.claim % cache.constants.tickSpacing != 0) {
                if (cache.claimTick.priceAt == 0) {
                    require (false, 'WrongTickClaimedAt2()');
                }
                cache.priceClaim = cache.claimTick.priceAt;
            }
        }

        // validate claim tick
        if (params.claim == (params.zeroForOne ? cache.position.upper : cache.position.lower)) {
            // set params.amount to 0 for event emitted at end
            cache.liquidityBurned = 0;
             if (claimTickEpoch <= cache.position.epochLast)
                require (false, 'WrongTickClaimedAt3()');
        } else if (cache.liquidityBurned > 0) {
            /// @dev - partway claim is valid as long as liquidity is not being removed

            // if we cleared the final tick of their position, this is the wrong claim tick
            if (params.zeroForOne) {
                uint32 endTickEpoch = EpochMap.get(cache.position.upper, params.zeroForOne, tickMap, cache.constants);
                if (endTickEpoch > cache.position.epochLast) {
                    params.claim = cache.position.upper;
                    cache.priceClaim = cache.priceUpper;
                    cache.claimTick = ticks[cache.position.upper].limit;
                    cache.liquidityBurned = cache.position.liquidity;
                } else {
                    int24 claimTickNext = TickMap.next(tickMap, params.claim, cache.constants.tickSpacing, false);
                    uint32 claimTickNextEpoch = EpochMap.get(claimTickNext, params.zeroForOne, tickMap, cache.constants);
                    ///@dev - next swapEpoch should not be greater
                    if (claimTickNextEpoch > cache.position.epochLast) {
                        require (false, 'WrongTickClaimedAt5()');
                    }
                }
            } else {
                uint32 endTickEpoch = EpochMap.get(cache.position.lower, params.zeroForOne, tickMap, cache.constants);
                if (endTickEpoch > cache.position.epochLast) {
                    params.claim = cache.position.lower;
                    cache.priceClaim = cache.priceLower;
                    cache.claimTick = ticks[cache.position.lower].limit;
                    cache.liquidityBurned = cache.position.liquidity;
                } else {
                    int24 claimTickNext = TickMap.previous(tickMap, params.claim, cache.constants.tickSpacing, false);
                    uint32 claimTickNextEpoch = EpochMap.get(claimTickNext, params.zeroForOne, tickMap, cache.constants);
                    ///@dev - next swapEpoch should not be greater
                    if (claimTickNextEpoch > cache.position.epochLast) {
                        require (false, 'WrongTickClaimedAt5()');
                    }
                }
            }
        }
        /// @dev - start tick does not overwrite position and final tick clears position
        if (params.claim != cache.position.upper && params.claim != cache.position.lower) {
            // check epochLast on claim tick
            if (claimTickEpoch <= cache.position.epochLast)
                require (false, 'WrongTickClaimedAt7()');
        }

        return (params, cache);
    }

    function getDeltas(
        PoolsharkStructs.BurnLimitParams memory params,
        LimitPoolStructs.BurnLimitCache memory cache,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (
        LimitPoolStructs.BurnLimitCache memory
    ) {
        // if half tick priceAt > 0 add amountOut to amountOutClaimed
        // set claimPriceLast if zero
        if (!cache.position.crossedInto) {
            cache.position.crossedInto = true;
        }
        LimitPoolStructs.GetDeltasLocals memory locals;

        if (params.claim % constants.tickSpacing != 0)
        // this should pass price at the claim tick
            locals.previousFullTick = TickMap.roundBack(params.claim, constants, params.zeroForOne, ConstantProduct.getPriceAtTick(params.claim, constants));
        else
            locals.previousFullTick = params.claim;
        locals.pricePrevious = ConstantProduct.getPriceAtTick(locals.previousFullTick, constants);
        if (params.zeroForOne ? locals.previousFullTick > cache.position.lower
                              : locals.previousFullTick < cache.position.upper) {
            
            // claim amounts up to latest full tick crossed
            cache.amountIn += uint128(params.zeroForOne ? ConstantProduct.getDy(cache.position.liquidity, cache.priceLower, locals.pricePrevious, false)
                                                                 : ConstantProduct.getDx(cache.position.liquidity, locals.pricePrevious, cache.priceUpper, false));
        }
        if (cache.liquidityBurned > 0) {
           // if tick hasn't been set back calculate amountIn
            if (params.zeroForOne ? cache.priceClaim > locals.pricePrevious
                                  : cache.priceClaim < locals.pricePrevious) {
                // allow partial tick claim if removing liquidity
                cache.amountIn += uint128(params.zeroForOne ? ConstantProduct.getDy(cache.liquidityBurned, locals.pricePrevious, cache.priceClaim, false)
                                                            : ConstantProduct.getDx(cache.liquidityBurned, cache.priceClaim, locals.pricePrevious, false));
            }
            // use priceClaim if tick hasn't been set back
            // else use claimPriceLast to calculate amountOut
            if (params.claim != (params.zeroForOne ? cache.position.upper : cache.position.lower)) {
                cache.amountOut += uint128(params.zeroForOne ? ConstantProduct.getDx(cache.liquidityBurned, cache.priceClaim, cache.priceUpper, false)
                                                             : ConstantProduct.getDy(cache.liquidityBurned, cache.priceLower, cache.priceClaim, false));
            }
        }
        // take protocol fee if needed
        if (cache.pool.protocolFillFee > 0 && cache.amountIn > 0) {
            uint128 protocolFeeAmount = OverflowMath.mulDiv(cache.amountIn, cache.pool.protocolFillFee, 1e4).toUint128();
            cache.amountIn -= protocolFeeAmount;
            cache.pool.protocolFees += protocolFeeAmount;
        }
        return cache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../math/ConstantProduct.sol';
import '../../interfaces/structs/LimitPoolStructs.sol';

library EpochMap {
    event SyncLimitTick(
        uint32 epoch,
        int24 tick,
        bool zeroForOne
    );

    function set(
        int24  tick,
        bool zeroForOne,
        uint256 epoch,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);
        // assert epoch isn't bigger than max uint32
        uint256 epochValue = zeroForOne ? tickMap.epochs0[volumeIndex][blockIndex][wordIndex]
                                        : tickMap.epochs1[volumeIndex][blockIndex][wordIndex];
        // clear previous value
        epochValue &=  ~(((1 << 9) - 1) << ((tickIndex & 0x7) * 32));
        // add new value to word
        epochValue |= epoch << ((tickIndex & 0x7) * 32);
        // store word in map
        zeroForOne ? tickMap.epochs0[volumeIndex][blockIndex][wordIndex] = epochValue
                   : tickMap.epochs1[volumeIndex][blockIndex][wordIndex] = epochValue;

        emit SyncLimitTick(uint32(epoch), tick, zeroForOne);
    }

    function get(
        int24 tick,
        bool zeroForOne,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal view returns (
        uint32 epoch
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);

        uint256 epochValue = zeroForOne ? tickMap.epochs0[volumeIndex][blockIndex][wordIndex]
                                        : tickMap.epochs1[volumeIndex][blockIndex][wordIndex];
        // right shift so first 8 bits are epoch value
        epochValue >>= ((tickIndex & 0x7) * 32);
        // clear other bits
        epochValue &= ((1 << 32) - 1);
        return uint32(epochValue);
    }

    function getIndices(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        )
    {
        unchecked {
            if (tick > ConstantProduct.maxTick(constants.tickSpacing)) require (false, 'TickIndexOverflow()');
            if (tick < ConstantProduct.minTick(constants.tickSpacing)) require (false, 'TickIndexUnderflow()');
            if (tick % (constants.tickSpacing / 2) != 0) {
                require (false, 'TickIndexInvalid()');
            } 
            tickIndex = uint256(int256((_round(tick, constants.tickSpacing / 2) 
                                        - _round(ConstantProduct.MIN_TICK, constants.tickSpacing / 2)) 
                                        / (constants.tickSpacing / 2)));
            wordIndex = tickIndex >> 3;        // 2^3 epochs per word
            blockIndex = tickIndex >> 11;      // 2^8 words per block
            volumeIndex = tickIndex >> 19;     // 2^8 blocks per volume
            if (blockIndex > 2046) require (false, 'BlockIndexOverflow()');
        }
    }

    function _round(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (
        int24 roundedTick
    ) {
        return tick / tickSpacing * tickSpacing;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './LimitTicks.sol';
import '../../interfaces/IPositionERC1155.sol';
import '../../interfaces/structs/RangePoolStructs.sol';
import '../../interfaces/structs/LimitPoolStructs.sol';
import '../math/OverflowMath.sol';
import './Claims.sol';
import './EpochMap.sol';
import '../utils/SafeCast.sol';
import '../Ticks.sol';

/// @notice Position management library for ranged liquidity.
/// @notice Position management library for ranged liquidity.
library LimitPositions {
    using SafeCast for uint256;

    event BurnLimit(
        address indexed to,
        uint32 positionId,
        int24 lower,
        int24 upper,
        int24 oldClaim,
        int24 newClaim,
        bool zeroForOne,
        uint128 liquidityBurned,
        uint128 tokenInClaimed,
        uint128 tokenOutBurned
    );

    function resize(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        PoolsharkStructs.MintLimitParams memory params,
        LimitPoolStructs.MintLimitCache memory cache
    ) external returns (
        PoolsharkStructs.MintLimitParams memory,
        LimitPoolStructs.MintLimitCache memory
    )
    {
        ConstantProduct.checkTicks(params.lower, params.upper, cache.constants.tickSpacing);

        cache.priceLower = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
        cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
        cache.mintSize = uint256(params.mintPercent) * uint256(params.amount) / 1e28;

        // calculate L constant
        cache.liquidityMinted = ConstantProduct.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            params.zeroForOne ? cache.priceLower : cache.priceUpper,
            params.zeroForOne ? 0 : uint256(params.amount),
            params.zeroForOne ? uint256(params.amount) : 0
        );

        if (cache.liquidityMinted == 0) require (false, 'NoLiquidityBeingAdded()');
        // calculate price limit by using half of input
        {
            cache.priceLimit = params.zeroForOne ? ConstantProduct.getNewPrice(cache.priceUpper, cache.liquidityMinted, params.amount / 2, true, true)
                                                 : ConstantProduct.getNewPrice(cache.priceLower, cache.liquidityMinted, params.amount / 2, false, true);
            if (cache.priceLimit == 0) require (false, 'PriceLimitZero()');
            // get tick at price
            cache.tickLimit = ConstantProduct.getTickAtPrice(cache.priceLimit.toUint160(), cache.constants);
            // round to nearest tick spacing
            cache.priceLimit = ConstantProduct.getPriceAtTick(cache.tickLimit, cache.constants);
        }

        PoolsharkStructs.SwapCache memory swapCache;
        swapCache.state = cache.state;
        swapCache.constants = cache.constants;
        swapCache.price = cache.state.pool.price;

        // swap zero if no liquidity near market price
        if (cache.state.pool.liquidity == 0 && 
            (params.zeroForOne ? swapCache.price > cache.priceLower
                               : swapCache.price < cache.priceUpper)) {
            swapCache = Ticks.swap(
                ticks,
                samples,
                rangeTickMap,
                limitTickMap,
                PoolsharkStructs.SwapParams({
                    to: params.to,
                    priceLimit: (params.zeroForOne ? cache.priceLower 
                                                   : cache.priceUpper).toUint160(),
                    amount: 0,
                    //TODO: handle exactOut
                    exactIn: true,
                    zeroForOne: params.zeroForOne,
                    callbackData: abi.encodePacked(bytes1(0x0))
                }),
                swapCache
            );
        }

        // only swap if priceLimit is beyond current pool price
        if (params.zeroForOne ? cache.priceLimit < swapCache.price
                              : cache.priceLimit > swapCache.price) {
            // swap and save the pool state
            swapCache = Ticks.swap(
                ticks,
                samples,
                rangeTickMap,
                limitTickMap,
                PoolsharkStructs.SwapParams({
                    to: params.to,
                    priceLimit: cache.priceLimit.toUint160(),
                    amount: params.amount,
                    //TODO: handle exactOut
                    exactIn: true,
                    zeroForOne: params.zeroForOne,
                    callbackData: abi.encodePacked(bytes1(0x0))
                }),
                swapCache
            );
            // subtract from remaining input amount
            params.amount -= uint128(swapCache.input);

        }
        // save to cache
        cache.swapCache = swapCache;
        cache.state = swapCache.state;

        if (params.amount < cache.mintSize) params.amount = 0;
        // move start tick based on amount filled in swap
        if ((params.amount > 0 && swapCache.input > 0) ||
            (params.zeroForOne ? cache.priceLower < swapCache.price
                               : cache.priceUpper > swapCache.price)
        ) {
            // move the tick limit based on pool.tickAtPrice
            if (params.zeroForOne ? cache.priceLower < swapCache.price
                                  : cache.priceUpper > swapCache.price) {
                cache.tickLimit = swapCache.state.pool.tickAtPrice;
            }
            // round ahead tickLimit to avoid crossing epochs
            cache.tickLimit = TickMap.roundAhead(cache.tickLimit, cache.constants, params.zeroForOne, swapCache.price);
            if (params.zeroForOne) {
                if (cache.priceLower < swapCache.price) {
                    // if rounding goes past limit trim position
                    /// @dev - if swap didn't go to limit user would be 100% filled
                    params.lower = cache.tickLimit;
                    cache.priceLower = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
                }
                if (params.lower >= params.upper && 
                    params.lower < ConstantProduct.maxTick(cache.constants.tickSpacing) - cache.constants.tickSpacing
                ) {
                    params.upper = params.lower + cache.constants.tickSpacing;
                }
                cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
            } else {
                if (cache.priceUpper > swapCache.price) {
                    // if rounding goes past limit trim position
                    params.upper = cache.tickLimit;
                    cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
                }
                if (params.upper <= params.lower && 
                    params.lower > ConstantProduct.minTick(cache.constants.tickSpacing) + cache.constants.tickSpacing
                ) {
                    params.lower = params.upper - cache.constants.tickSpacing;
                }
                cache.priceLower = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
            }
            if (params.amount > 0 && params.lower < params.upper)
                cache.liquidityMinted = ConstantProduct.getLiquidityForAmounts(
                    cache.priceLower,
                    cache.priceUpper,
                    params.zeroForOne ? cache.priceLower : cache.priceUpper,
                    params.zeroForOne ? 0 : uint256(params.amount),
                    params.zeroForOne ? uint256(params.amount) : 0
                );
            else
                /// @auditor unnecessary since params.amount is 0
                cache.liquidityMinted = 0;
            cache.state.epoch += 1;
        }

        /// @dev - for safety
        if (params.lower >= params.upper) {
            // zero out amount transferred in
            params.amount = 0;
        }

        return (
            params,
            cache
        );
    }

    function add(
        LimitPoolStructs.MintLimitCache memory cache,
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.MintLimitParams memory params
    ) internal returns (
        PoolsharkStructs.LimitPoolState memory,
        LimitPoolStructs.LimitPosition memory
    ) {
        if (cache.liquidityMinted == 0) return (cache.pool, cache.position);

        if (cache.position.liquidity == 0) {
            cache.position.epochLast = cache.state.epoch;
            cache.state.epoch += 1; // increment for future swaps
            IPositionERC1155(cache.constants.poolToken).mint(
                params.to,
                params.positionId,
                1,
                cache.constants
            );
        } else {
            // safety check in case we somehow get here
            if (
                params.zeroForOne
                    ? EpochMap.get(params.lower, params.zeroForOne, tickMap, cache.constants)
                            > cache.position.epochLast
                    : EpochMap.get(params.upper, params.zeroForOne, tickMap, cache.constants)
                            > cache.position.epochLast
            ) {
                require (false, 'PositionAlreadyEntered()');
            }
            /// @auditor maybe this shouldn't be a revert but rather just not mint the position?
        }
        
        // add liquidity to ticks
        LimitTicks.insert(
            ticks,
            tickMap,
            cache,
            params
        );

        // update liquidity global
        cache.state.liquidityGlobal += uint128(cache.liquidityMinted);

        cache.position.liquidity += uint128(cache.liquidityMinted);

        return (cache.pool, cache.position);
    }

    function update(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        LimitPoolStructs.BurnLimitCache memory cache,
        PoolsharkStructs.BurnLimitParams memory params
    ) internal returns (
        PoolsharkStructs.BurnLimitParams memory,
        LimitPoolStructs.BurnLimitCache memory
    )
    {
        (
            params,
            cache
        ) = _deltas(
            ticks,
            tickMap,
            params,
            cache
        );

        // update pool liquidity
        if (cache.priceClaim == cache.pool.price && cache.liquidityBurned > 0) {
            // handle pool.price at edge of range
            if (params.zeroForOne ? cache.priceClaim < cache.priceUpper
                                  : cache.priceClaim > cache.priceLower)
                cache.pool.liquidity -= cache.liquidityBurned;
        }

        if (cache.liquidityBurned > 0) {
            if (params.claim == (params.zeroForOne ? cache.position.upper : cache.position.lower)) {
                // if claim is final tick no liquidity to remove
                cache.removeLower = false;
                cache.removeUpper = false;
            } else {
                // else remove liquidity from final tick
                params.zeroForOne ? cache.removeUpper = true 
                                  : cache.removeLower = true;
                if (params.zeroForOne) {

                    if (params.claim == cache.position.lower && 
                        cache.pool.price < cache.priceLower
                    ) {
                        // full tick price was touched
                        cache.removeLower = true;
                    } else if (params.claim % cache.constants.tickSpacing != 0 && 
                                    cache.pool.price < cache.priceClaim)
                        // half tick was created
                        cache.removeLower = true;
                } else {
                    if (params.claim == cache.position.upper &&
                        cache.pool.price > cache.priceUpper
                    )
                        // full tick price was touched
                        cache.removeUpper = true;
                    else if (params.claim % cache.constants.tickSpacing != 0 &&
                                    cache.pool.price > cache.priceClaim)
                        // half tick was created
                        cache.removeUpper = true;
                }
            }
            LimitTicks.remove(
                ticks,
                tickMap,
                params,
                cache,
                cache.constants
            );
            // update position liquidity
            cache.position.liquidity -= uint128(cache.liquidityBurned);
            // update global liquidity
            cache.state.liquidityGlobal -= cache.liquidityBurned;
        }
        if (params.zeroForOne ? params.claim == cache.position.upper
                              : params.claim == cache.position.lower) {
            cache.state.liquidityGlobal -= cache.position.liquidity;
            cache.position.liquidity = 0;
        }
        // clear out old position
        if (params.zeroForOne ? params.claim != cache.position.lower 
                              : params.claim != cache.position.upper) {
            /// @dev - this also clears out position end claims
            if (params.zeroForOne ? params.claim == cache.position.lower 
                                  : params.claim == cache.position.upper) {
                // subtract remaining position liquidity out from global
                cache.state.liquidityGlobal -= cache.position.liquidity;
            }
        }
        // clear position if empty
        if (cache.position.liquidity == 0) {
            cache.position.epochLast = 0;
            cache.position.crossedInto = false;
        }

        // round back claim tick for storage
        if (params.claim % cache.constants.tickSpacing != 0) {
            cache.claim = params.claim;
            params.claim = TickMap.roundBack(params.claim, cache.constants, params.zeroForOne, cache.priceClaim);
        }
        
        emit BurnLimit(
            params.to,
            params.positionId,
            cache.position.lower,
            cache.position.upper,
            cache.claim,
            params.claim,
            params.zeroForOne,
            cache.liquidityBurned,
            cache.amountIn,
            cache.amountOut
        );

        // save pool to state in memory
        if (params.zeroForOne) cache.state.pool0 = cache.pool;
        else cache.state.pool1 = cache.pool;

        return (params, cache);
    }

    function snapshot(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        LimitPoolStructs.BurnLimitCache memory cache,
        PoolsharkStructs.BurnLimitParams memory params
    ) internal view returns (
        uint128 amountIn,
        uint128 amountOut
    ) {
        (
            params,
            cache
        ) = _deltas(
            ticks,
            tickMap,
            params,
            cache
        );

        return (cache.amountIn, cache.amountOut);
    }

    function _deltas(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.BurnLimitParams memory params,
        LimitPoolStructs.BurnLimitCache memory cache
    ) internal view returns (
        PoolsharkStructs.BurnLimitParams memory,
        LimitPoolStructs.BurnLimitCache memory
    ) {
        cache = LimitPoolStructs.BurnLimitCache({
            state: cache.state,
            pool: params.zeroForOne ? cache.state.pool0 : cache.state.pool1,
            claimTick: ticks[params.claim].limit,
            position: cache.position,
            constants: cache.constants,
            priceLower: ConstantProduct.getPriceAtTick(cache.position.lower, cache.constants),
            priceClaim: ticks[params.claim].limit.priceAt == 0 ? ConstantProduct.getPriceAtTick(params.claim, cache.constants)
                                                               : ticks[params.claim].limit.priceAt,
            priceUpper: ConstantProduct.getPriceAtTick(cache.position.upper, cache.constants),
            liquidityBurned: _convert(cache.position.liquidity, params.burnPercent),
            amountIn: 0,
            amountOut: 0,
            claim: params.claim,
            removeLower: false,
            removeUpper: false
        });

        // check claim is valid
        (params, cache) = Claims.validate(
            ticks,
            tickMap,
            params,
            cache
        );

        // calculate position deltas
        cache = Claims.getDeltas(params, cache, cache.constants);

        return (params, cache);
    }

    function _convert(
        uint128 liquidity,
        uint128 percent
    ) internal pure returns (
        uint128
    ) {
        // convert percentage to liquidity amount
        if (percent > 1e38) percent = 1e38;
        if (liquidity == 0 && percent > 0) require (false, 'PositionNotFound()');
        return uint128(uint256(liquidity) * uint256(percent) / 1e38);
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../interfaces/structs/LimitPoolStructs.sol';
import '../../interfaces/limit/ILimitPoolFactory.sol';
import '../../interfaces/limit/ILimitPool.sol';
import '../math/ConstantProduct.sol';
import './LimitPositions.sol';
import '../math/OverflowMath.sol';
import '../TickMap.sol';
import './EpochMap.sol';
import '../Samples.sol';
import '../utils/SafeCast.sol';

/// @notice Tick management library for limit pools
library LimitTicks {
    error LiquidityOverflow();
    error LiquidityUnderflow();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBounds();

    using SafeCast for uint256;

    uint256 internal constant Q96 = 0x1000000000000000000000000;

    event SyncLimitLiquidity(
        uint128 liquidityAdded,
        int24 tick,
        bool zeroForOne
    );

    function validate(
        int24 lower,
        int24 upper,
        int24 tickSpacing
    ) internal pure {
        if (lower % tickSpacing != 0) require(false, 'InvalidLowerTick()');
        if (lower <= ConstantProduct.MIN_TICK) require(false, 'InvalidLowerTick()');
        if (upper % tickSpacing != 0) require(false, 'InvalidUpperTick()');
        if (upper >= ConstantProduct.MAX_TICK) require(false, 'InvalidUpperTick()');
        if (lower >= upper) require(false, 'InvalidPositionBounds()');
    }

    function insert(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        LimitPoolStructs.MintLimitCache memory cache,
        PoolsharkStructs.MintLimitParams memory params
    ) internal {
        /// @dev - validation of ticks is in Positions.validate
        if (cache.liquidityMinted == 0)
            require(false, 'NoLiquidityBeingAdded()');
        if (cache.state.liquidityGlobal + cache.liquidityMinted > uint128(type(int128).max))
            require(false, 'LiquidityOverflow()');

        int256 liquidityMinted = int256(cache.liquidityMinted);

        // check if adding liquidity necessary
        if (!params.zeroForOne || cache.priceLower > cache.pool.price) {
            // sets bit in map
            if(!TickMap.set(tickMap, params.lower, cache.constants.tickSpacing)){
                // inherit epoch 
                int24 tickAhead;
                if (params.zeroForOne) {
                    tickAhead  = TickMap.next(tickMap, params.lower, cache.constants.tickSpacing, false);
                } else {
                    tickAhead  = TickMap.previous(tickMap, params.lower, cache.constants.tickSpacing, false);
                }
                uint32 epochAhead = EpochMap.get(tickAhead, params.zeroForOne, tickMap, cache.constants);
                EpochMap.set(params.lower, params.zeroForOne, epochAhead, tickMap, cache.constants);
            }
            PoolsharkStructs.LimitTick memory tickLower = ticks[params.lower].limit;
            if (params.zeroForOne) {
                tickLower.liquidityDelta += int128(liquidityMinted);
            } else {
                tickLower.liquidityDelta -= int128(liquidityMinted);
            }
            tickLower.liquidityAbsolute += cache.liquidityMinted.toUint128();
            ticks[params.lower].limit = tickLower;
        } else {
            /// @dev - i.e. if zeroForOne && cache.priceLower <= cache.pool.price
            cache.state.epoch += 1;
            // mark epoch on undercut tick
            EpochMap.set(params.lower, params.zeroForOne, cache.state.epoch, tickMap, cache.constants);
        }

        if (params.zeroForOne || cache.priceUpper < cache.pool.price) {
            if(!TickMap.set(tickMap, params.upper, cache.constants.tickSpacing)) {
                int24 tickAhead;
                if (params.zeroForOne) {
                    tickAhead  = TickMap.next(tickMap, params.upper, cache.constants.tickSpacing, false);
                } else {
                    tickAhead  = TickMap.previous(tickMap, params.upper, cache.constants.tickSpacing, false);
                }
                uint32 epochAhead = EpochMap.get(tickAhead, params.zeroForOne, tickMap, cache.constants);
                EpochMap.set(params.upper, params.zeroForOne, epochAhead, tickMap, cache.constants);
            }
            PoolsharkStructs.LimitTick memory tickUpper = ticks[params.upper].limit;
            if (params.zeroForOne) {
                tickUpper.liquidityDelta -= int128(liquidityMinted);
            } else {
                tickUpper.liquidityDelta += int128(liquidityMinted);
            }
            tickUpper.liquidityAbsolute += cache.liquidityMinted.toUint128();
            ticks[params.upper].limit = tickUpper;
        } else {
            /// @dev - i.e. if !zeroForOne && cache.priceUpper >= cache.pool.price
            cache.state.epoch += 1;
            // mark epoch on undercut tick
            EpochMap.set(params.upper, params.zeroForOne, cache.state.epoch, tickMap, cache.constants);
        }
    }

    function insertSingle(
        PoolsharkStructs.MintLimitParams memory params,
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        LimitPoolStructs.MintLimitCache memory cache,
        PoolsharkStructs.LimitPoolState memory pool,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal returns (
        PoolsharkStructs.LimitPoolState memory
    ){
        /// @auditor - would be smart to protect against the case of epochs crossing
        (
            int24 tickToSave,
            uint160 roundedPrice
        ) = TickMap.roundHalf(pool.tickAtPrice, constants, pool.price);
        // update tick to save
        LimitPoolStructs.LimitTick memory tick = ticks[tickToSave].limit;
        /// @auditor - tick.priceAt will be zero for tick % tickSpacing == 0
        if (tick.priceAt == 0) {
            if (pool.price != (params.zeroForOne ? cache.priceLower : cache.priceUpper)) {
                TickMap.set(tickMap, tickToSave, constants.tickSpacing);
            }
            EpochMap.set(tickToSave, params.zeroForOne, cache.state.epoch, tickMap, constants);
        }
        // skip if we are at the nearest full tick
        if(pool.price != roundedPrice) {
            // if empty just save the pool price
            if (tick.priceAt == 0) {
                tick.priceAt = pool.price;
            }
            else {
                // we need to blend the two partial fills into a single tick
                LimitPoolStructs.InsertSingleLocals memory locals;
                if (params.zeroForOne) {
                    // 0 -> 1 positions price moves up so nextFullTick is greater
                    locals.previousFullTick = tickToSave - constants.tickSpacing / 2;
                    locals.pricePrevious = ConstantProduct.getPriceAtTick(locals.previousFullTick, constants);
                    // calculate amountOut filled across both partial fills
                    locals.amountOutExact = ConstantProduct.getDy(pool.liquidity, locals.pricePrevious, pool.price, false);
                    locals.amountOutExact += ConstantProduct.getDy(uint128(tick.liquidityDelta), locals.pricePrevious, tick.priceAt, false);
                    // add current pool liquidity to partial tick
                    uint128 combinedLiquidity = pool.liquidity + uint128(tick.liquidityDelta);
                    // advance price based on combined fill
                    tick.priceAt = ConstantProduct.getNewPrice(uint256(locals.pricePrevious), combinedLiquidity, locals.amountOutExact, false, true).toUint160();
                    // dx to the next tick is less than before the tick blend
                    EpochMap.set(tickToSave, params.zeroForOne, cache.state.epoch, tickMap, constants);
                } else {
                    // 0 -> 1 positions price moves up so nextFullTick is lesser
                    locals.previousFullTick = tickToSave + constants.tickSpacing / 2;
                    locals.pricePrevious = ConstantProduct.getPriceAtTick(locals.previousFullTick, constants);
                    // calculate amountOut filled across both partial fills
                    locals.amountOutExact = ConstantProduct.getDx(pool.liquidity, pool.price, locals.pricePrevious, false);
                    locals.amountOutExact += ConstantProduct.getDx(uint128(tick.liquidityDelta), tick.priceAt, locals.pricePrevious, false);
                    // add current pool liquidity to partial tick
                    uint128 combinedLiquidity = pool.liquidity + uint128(tick.liquidityDelta);
                    // advance price based on combined fill
                    tick.priceAt = ConstantProduct.getNewPrice(uint256(locals.pricePrevious), combinedLiquidity, locals.amountOutExact, true, true).toUint160();
                    // mark epoch for second partial fill positions
                    EpochMap.set(tickToSave, params.zeroForOne, cache.state.epoch, tickMap, constants);
                }
            }
        }
        // invariant => if we save liquidity to tick clear pool liquidity
        if ((tickToSave != (params.zeroForOne ? params.lower : params.upper))) {
            tick.liquidityDelta += int128(pool.liquidity);
            tick.liquidityAbsolute += pool.liquidity;
            emit SyncLimitLiquidity(pool.liquidity, tickToSave, params.zeroForOne);
            pool.liquidity = 0;
        }
        ticks[tickToSave].limit = tick;
        return pool;
    }

    function remove(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.BurnLimitParams memory params,
        LimitPoolStructs.BurnLimitCache memory cache,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal {
        // set ticks based on claim and zeroForOne
        int24 lower = params.zeroForOne ? params.claim : cache.position.lower;
        int24 upper = params.zeroForOne ? cache.position.upper : params.claim;
        {    
            PoolsharkStructs.LimitTick memory tickLower = ticks[lower].limit;
            
            if (cache.removeLower) {
                if (params.zeroForOne) {
                    tickLower.liquidityDelta -= int128(cache.liquidityBurned);
                } else {
                    tickLower.liquidityDelta += int128(cache.liquidityBurned);
                }
                tickLower.liquidityAbsolute -= cache.liquidityBurned;
                ticks[lower].limit = tickLower;
                clear(ticks, constants, tickMap, lower);
            }
        }
        {
            PoolsharkStructs.LimitTick memory tickUpper = ticks[upper].limit;
            if (cache.removeUpper) {
                if (params.zeroForOne) {
                    tickUpper.liquidityDelta += int128(cache.liquidityBurned);
                } else {
                    tickUpper.liquidityDelta -= int128(cache.liquidityBurned);
                }
                tickUpper.liquidityAbsolute -= cache.liquidityBurned;
                ticks[upper].limit = tickUpper;
                clear(ticks, constants, tickMap, upper);
            }
        }
    }

     function unlock(
        LimitPoolStructs.MintLimitCache memory cache,
        PoolsharkStructs.LimitPoolState memory pool,
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        bool zeroForOne
    ) internal returns (
        LimitPoolStructs.MintLimitCache memory,
        PoolsharkStructs.LimitPoolState memory
    )
    {
        if (pool.liquidity > 0) return (cache, pool);

        (int24 startTick,) = TickMap.roundHalf(pool.tickAtPrice, cache.constants, pool.price);

        if (zeroForOne) {
            pool.tickAtPrice = TickMap.next(tickMap, startTick, cache.constants.tickSpacing, true);
            if (pool.tickAtPrice < ConstantProduct.maxTick(cache.constants.tickSpacing)) {
                EpochMap.set(pool.tickAtPrice, zeroForOne, cache.state.epoch, tickMap, cache.constants);
            }
        } else {
            /// @dev - roundedUp true since liquidity could be equal to the current pool tickAtPrice
            pool.tickAtPrice = TickMap.previous(tickMap, startTick, cache.constants.tickSpacing, true);
            if (pool.tickAtPrice > ConstantProduct.minTick(cache.constants.tickSpacing)) {
                EpochMap.set(pool.tickAtPrice, zeroForOne, cache.state.epoch, tickMap, cache.constants);
            }
        }

        // increment pool liquidity
        pool.liquidity += uint128(ticks[pool.tickAtPrice].limit.liquidityDelta);
        int24 tickToClear = pool.tickAtPrice;
        uint160 tickPriceAt = ticks[pool.tickAtPrice].limit.priceAt;

        if (tickPriceAt == 0) {
            // if full tick crossed
            pool.price = ConstantProduct.getPriceAtTick(pool.tickAtPrice, cache.constants);
        } else {
            // if half tick crossed
            pool.price = tickPriceAt;
            pool.tickAtPrice = ConstantProduct.getTickAtPrice(tickPriceAt, cache.constants);
        }

        // zero out tick
        ticks[tickToClear].limit = PoolsharkStructs.LimitTick(0,0,0);
        clear(ticks, cache.constants, tickMap, tickToClear);

        return (cache, pool);
    }

    function clear(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.LimitImmutables memory constants,
        PoolsharkStructs.TickMap storage tickMap,
        int24 tickToClear
    ) internal {
        if (_empty(ticks[tickToClear])) {
            if (tickToClear != ConstantProduct.maxTick(constants.tickSpacing) &&
                tickToClear != ConstantProduct.minTick(constants.tickSpacing)) {
                ticks[tickToClear].limit = PoolsharkStructs.LimitTick(0,0,0);
                TickMap.unset(tickMap, tickToClear, constants.tickSpacing);
            }
        }
    }

    function _empty(
        LimitPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.limit.liquidityAbsolute != 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './OverflowMath.sol';
import '../../interfaces/structs/LimitPoolStructs.sol';
import '../../interfaces/structs/PoolsharkStructs.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library ConstantProduct {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    /////////////////////////////////////////////////////////////
    ///////////////////////// DYDX MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (liquidity == 0) return 0;
            if (roundUp) {
                dy = OverflowMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = OverflowMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
            }
        }
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (liquidity == 0) return 0;
            if (roundUp) {
                dx = OverflowMath.divRoundingUp(
                        OverflowMath.mulDivRoundingUp(
                            liquidity << 96, 
                            priceUpper - priceLower,
                            priceUpper
                        ),
                        priceLower
                );
            } else {
                dx = OverflowMath.mulDiv(
                        liquidity << 96,
                        priceUpper - priceLower,
                        priceUpper
                ) / priceLower;
            }
        }
    }

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) internal pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper <= currentPrice) {
                liquidity = OverflowMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice <= priceLower) {
                liquidity = OverflowMath.mulDiv(
                    dx,
                    OverflowMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                uint256 liquidity0 = OverflowMath.mulDiv(
                    dx,
                    OverflowMath.mulDiv(priceUpper, currentPrice, Q96),
                    priceUpper - currentPrice
                );
                uint256 liquidity1 = OverflowMath.mulDiv(dy, Q96, currentPrice - priceLower);
                liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            }
        }
    }

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 liquidityAmount,
        bool roundUp
    ) internal pure returns (uint128 token0amount, uint128 token1amount) {
        if (priceUpper <= currentPrice) {
            token1amount = uint128(getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            token0amount = uint128(getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
        if (token0amount > uint128(type(int128).max)) require(false, 'AmountsOutOfBounds()');
        if (token1amount > uint128(type(int128).max)) require(false, 'AmountsOutOfBounds()');
    }

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 amount,
        bool zeroForOne,
        bool exactIn
    ) internal pure returns (
        uint256 newPrice
    ) {
        if (exactIn) {
            if (zeroForOne) {
                uint256 liquidityPadded = liquidity << 96;
                newPrice = OverflowMath.mulDivRoundingUp(
                        liquidityPadded,
                        price,
                        liquidityPadded + price * amount
                    );
            } else {
                newPrice = price + (amount << 96) / liquidity;
            }
        } else {
            if (zeroForOne) {
                newPrice = price - 
                        OverflowMath.divRoundingUp(amount << 96, liquidity);
            } else {
                uint256 liquidityPadded = uint256(liquidity) << 96;
                newPrice = OverflowMath.mulDivRoundingUp(
                        liquidityPadded, 
                        price,
                        liquidityPadded - uint256(price) * amount
                );
            }
        }
    }

    function getPrice(
        uint256 sqrtPrice
    ) internal pure returns (uint256 price) {
        if (sqrtPrice >= 2 ** 48)
            price = OverflowMath.mulDiv(sqrtPrice, sqrtPrice, 2 ** 96);
        else
            price = sqrtPrice;
    }

    /////////////////////////////////////////////////////////////
    ///////////////////////// TICK MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    int24 internal constant MIN_TICK = -887272;   /// @dev - tick for price of 2^-128
    int24 internal constant MAX_TICK = -MIN_TICK; /// @dev - tick for price of 2^128

    function minTick(
        int16 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        return MIN_TICK / tickSpacing * tickSpacing;
    }

    function maxTick(
        int16 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        return MAX_TICK / tickSpacing * tickSpacing;
    }

    function priceBounds(
        int16 tickSpacing
    ) internal pure returns (
        uint160,
        uint160
    ) {
        return (minPrice(tickSpacing), maxPrice(tickSpacing));
    }

    function minPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        PoolsharkStructs.LimitImmutables  memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        PoolsharkStructs.LimitImmutables  memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(maxTick(tickSpacing), constants);
    }

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure
    {
        if (lower < minTick(tickSpacing)) require (false, 'LowerTickOutOfBounds()');
        if (upper > maxTick(tickSpacing)) require (false, 'UpperTickOutOfBounds()');
        if (lower % tickSpacing != 0) require (false, 'LowerTickOutsideTickSpacing()');
        if (upper % tickSpacing != 0) require (false, 'UpperTickOutsideTickSpacing()');
        if (lower >= upper) require (false, 'LowerUpperTickOrderInvalid()');
    }

    function checkPrice(
        uint160 price,
        PriceBounds memory bounds
    ) internal pure {
        if (price < bounds.min || price >= bounds.max) require (false, 'PriceOutOfBounds()');
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return price Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getPriceAtTick(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (
        uint160 price
    ) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(maxTick(constants.tickSpacing)))) require (false, 'TickOutOfBounds()');
        unchecked {
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
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtPrice of the output price is always consistent.
            price = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @param price The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function getTickAtPrice(
        uint160 price,
        PoolsharkStructs.LimitImmutables  memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price > constants.bounds.max)
            require (false, 'PriceOutOfBounds()');
        uint256 ratio = uint256(price) << 32;

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

        tick = tickLow == tickHi ? tickLow : getPriceAtTick(tickHi, constants) <= price
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library OverflowMath {

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function mulDiv(
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
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                if (result >= type(uint256).max) require (false, 'MaxUintExceeded()');
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../Samples.sol';
import '../../utils/SafeCast.sol';
import "../../math/OverflowMath.sol";
import '../../../interfaces/structs/PoolsharkStructs.sol';
import "../../../interfaces/structs/RangePoolStructs.sol";

/// @notice Math library that facilitates fee handling.
library FeeMath {
    using SafeCast for uint256;

    uint256 internal constant FEE_DELTA_CONST = 0;
    //TODO: change FEE_DELTA_CONST before launch
    // uint256 internal constant FEE_DELTA_CONST = 5000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    struct CalculateLocals {
        uint256 price;
        uint256 minPrice;
        uint256 lastPrice;
        uint256 swapFee;
        uint256 feeAmount;
        uint256 protocolFee;
        uint256 protocolFeesAccrued;
        uint256 amountRange;
        bool feeDirection;
    }

    function calculate(
        PoolsharkStructs.SwapCache memory cache,
        uint256 amountIn,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (
        PoolsharkStructs.SwapCache memory
    )
    {
        CalculateLocals memory locals;
        if (cache.state.pool.liquidity != 0) {
            // calculate dynamic fee
            {
                locals.minPrice = ConstantProduct.getPrice(cache.constants.bounds.min);
                // square prices to take delta
                locals.price = ConstantProduct.getPrice(cache.price);
                locals.lastPrice = ConstantProduct.getPrice(cache.averagePrice);
                if (locals.price < locals.minPrice)
                    locals.price = locals.minPrice;
                if (locals.lastPrice < locals.minPrice)
                    locals.lastPrice = locals.minPrice;
                // delta is % modifier on the swapFee
                uint256 delta = OverflowMath.mulDiv(
                        FEE_DELTA_CONST / uint16(cache.constants.tickSpacing), // higher FEE_DELTA_CONST means
                        (                                                      // more aggressive dynamic fee
                            locals.price > locals.lastPrice
                                ? locals.price - locals.lastPrice
                                : locals.lastPrice - locals.price
                        ) * 1_000_000,
                        locals.lastPrice 
                );
                // max fee increase at 5x
                if (delta > 4_000_000) delta = 4_000_000;
                // true means increased fee for zeroForOne = true
                locals.feeDirection = locals.price < locals.lastPrice;
                // adjust fee based on direction
                if (zeroForOne == locals.feeDirection) {
                    // if swapping away from twap price, increase fee
                    locals.swapFee = cache.constants.swapFee + OverflowMath.mulDiv(delta,cache.constants.swapFee, 1e6);
                } else if (delta < 1e6) {
                    // if swapping towards twap price, decrease fee
                    locals.swapFee = cache.constants.swapFee - OverflowMath.mulDiv(delta,cache.constants.swapFee, 1e6);
                } else {
                    // if swapping towards twap price and delta > 100%, set fee to zero
                    locals.swapFee = 0;
                }
                // console.log('price movement', locals.lastPrice, locals.price);
                // console.log('swap fee adjustment',cache.constants.swapFee + delta * cache.constants.swapFee / 1e6);
            }
            if (cache.exactIn) {
                // calculate output from range liquidity
                locals.amountRange = OverflowMath.mulDiv(amountOut, cache.state.pool.liquidity, cache.liquidity);
                // take enough fees to cover fee growth
                locals.feeAmount = OverflowMath.mulDivRoundingUp(locals.amountRange, locals.swapFee, 1e6);
                amountOut -= locals.feeAmount;
            } else {
                // calculate input from range liquidity
                locals.amountRange = OverflowMath.mulDiv(amountIn, cache.state.pool.liquidity, cache.liquidity);
                // take enough fees to cover fee growth
                locals.feeAmount = OverflowMath.mulDivRoundingUp(locals.amountRange, locals.swapFee, 1e6);
                amountIn += locals.feeAmount;
            }
            // add to total fees paid for swap
            cache.feeAmount += locals.feeAmount.toUint128();
            // load protocol fee from cache
            // zeroForOne && exactIn   = fee on token1
            // zeroForOne && !exactIn  = fee on token0
            // !zeroForOne && !exactIn = fee on token1
            // !zeroForOne && exactIn  = fee on token0
            locals.protocolFee = (zeroForOne == cache.exactIn) ? cache.state.pool.protocolSwapFee1 
                                                               : cache.state.pool.protocolSwapFee0;
            // calculate fee
            locals.protocolFeesAccrued = OverflowMath.mulDiv(locals.feeAmount, locals.protocolFee, 1e4);
            // fees for this swap step
            locals.feeAmount -= locals.protocolFeesAccrued;
            // save fee growth and protocol fees
            if (zeroForOne == cache.exactIn) {
                cache.state.pool0.protocolFees += uint128(locals.protocolFeesAccrued);
                cache.state.pool.feeGrowthGlobal1 += uint200(OverflowMath.mulDiv(locals.feeAmount, Q128, cache.state.pool.liquidity));
            } else {
                cache.state.pool1.protocolFees += uint128(locals.protocolFeesAccrued);
                cache.state.pool.feeGrowthGlobal0 += uint200(OverflowMath.mulDiv(locals.feeAmount, Q128, cache.state.pool.liquidity));
            }
        }
        cache.input  += amountIn;
        cache.output += amountOut;

        return cache;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../../interfaces/structs/RangePoolStructs.sol';
import '../../utils/Collect.sol';
import '../../utils/PositionTokens.sol';
import '../RangePositions.sol';

library BurnRangeCall {
    using SafeCast for int128;

    event BurnRange(
        address indexed recipient,
        int24 lower,
        int24 upper,
        uint256 indexed tokenId,
        uint128 liquidityBurned,
        uint128 amount0,
        uint128 amount1
    );

    function perform(
        mapping(uint256 => RangePoolStructs.RangePosition)
            storage positions,
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.GlobalState storage globalState,
        RangePoolStructs.BurnRangeCache memory cache,
        RangePoolStructs.BurnRangeParams memory params
    ) external {
        // check for invalid receiver
        if (params.to == address(0))
            require(false, 'CollectToZeroAddress()');
        
        // initialize cache
        cache.state = globalState;
        cache.position = positions[params.positionId];

        // check positionId owner
        if (PositionTokens.balanceOf(cache.constants, msg.sender, params.positionId) == 0)
            require(false, 'PositionNotFound()');
        if (params.burnPercent > 1e38) params.burnPercent = 1e38;
        ( 
            cache.position,
            cache.amount0,
            cache.amount1
        ) = RangePositions.update(
                ticks,
                cache.position,
                cache.state,
                cache.constants,
                RangePoolStructs.UpdateParams(
                    cache.position.lower,
                    cache.position.upper,
                    params.positionId,
                    params.burnPercent
                )
        );
        cache = RangePositions.remove(
            ticks,
            samples,
            tickMap,
            params,
            cache
        );
        // only compound if burnPercent is zero
        if (params.burnPercent == 0)
            if (cache.amount0 > 0 || cache.amount1 > 0) {
                (
                    cache.position,
                    cache.state,
                    cache.amount0,
                    cache.amount1
                ) = RangePositions.compound(
                    ticks,
                    tickMap,
                    samples,
                    cache.state,
                    cache.constants,
                    cache.position,
                    RangePoolStructs.CompoundRangeParams(
                        cache.priceLower,
                        cache.priceUpper,
                        cache.amount0.toUint128(),
                        cache.amount1.toUint128(),
                        params.positionId
                    )
                );
            }
        // save changes to storage
        save(positions, globalState, cache, params.positionId);

        // transfer amounts to user
        if (cache.amount0 > 0 || cache.amount1 > 0)
            Collect.range(
                cache.constants,
                params.to,
                cache.amount0,
                cache.amount1
            );
    }

    function save(
        mapping(uint256 => RangePoolStructs.RangePosition)
            storage positions,
        PoolsharkStructs.GlobalState storage globalState,
        RangePoolStructs.BurnRangeCache memory cache,
        uint32 positionId
    ) internal {
        positions[positionId] = cache.position;
        globalState.pool = cache.state.pool;
        globalState.liquidityGlobal = cache.state.liquidityGlobal;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../interfaces/IPool.sol';
import '../../interfaces/IPositionERC1155.sol';
import '../../interfaces/structs/RangePoolStructs.sol';
import '../math/ConstantProduct.sol';
import './math/FeeMath.sol';
import '../math/OverflowMath.sol';
import '../utils/SafeCast.sol';
import './RangeTicks.sol';
import '../Samples.sol';

/// @notice Position management library for ranged liquidity.
library RangePositions {
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using SafeCast for int128;

    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
    error LiquidityOverflow();
    error WrongTickClaimedAt();
    error NoLiquidityBeingAdded();
    error PositionNotUpdated();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBoundsOrder();
    error NotImplementedYet();

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    event BurnRange(
        address indexed recipient,
        uint256 indexed positionId,
        uint128 liquidityBurned,
        int128 amount0,
        int128 amount1
    );

    event CompoundRange(
        uint32 indexed positionId,
        uint128 liquidityCompounded
    );

    function validate(
        RangePoolStructs.MintRangeParams memory params,
        RangePoolStructs.MintRangeCache memory cache
    ) internal pure returns (
        RangePoolStructs.MintRangeParams memory,
        RangePoolStructs.MintRangeCache memory
    ) {
        RangeTicks.validate(cache.position.lower, cache.position.upper, cache.constants.tickSpacing);

        cache.liquidityMinted = ConstantProduct.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            cache.state.pool.price,
            params.amount1,
            params.amount0
        );
        if (cache.liquidityMinted == 0) require(false, 'NoLiquidityBeingAdded()');
        (params.amount0, params.amount1) = ConstantProduct.getAmountsForLiquidity(
            cache.priceLower,
            cache.priceUpper,
            cache.state.pool.price,
            cache.liquidityMinted,
            true
        );
        if (cache.liquidityMinted > uint128(type(int128).max)) require(false, 'LiquidityOverflow()');

        return (params, cache);
    }

    function add(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.MintRangeCache memory cache,
        RangePoolStructs.MintRangeParams memory params
    ) internal returns (
        RangePoolStructs.MintRangeCache memory
    ) {
        if (params.amount0 == 0 && params.amount1 == 0) return cache;

        cache.state = RangeTicks.insert(
            ticks,
            samples,
            tickMap,
            cache.state,
            cache.constants,
            cache.position.lower,
            cache.position.upper,
            cache.liquidityMinted.toUint128()
        );
        (
            cache.position.feeGrowthInside0Last,
            cache.position.feeGrowthInside1Last
        ) = rangeFeeGrowth(
            ticks[cache.position.lower].range,
            ticks[cache.position.upper].range,
            cache.state,
            cache.position.lower,
            cache.position.upper
        );
        if (cache.position.liquidity == 0) {
            IPositionERC1155(cache.constants.poolToken).mint(
                params.to,
                params.positionId,
                1,
                cache.constants
            );
        }
        cache.position.liquidity += uint128(cache.liquidityMinted);
        return cache;
    }

    function remove(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.BurnRangeParams memory params,
        RangePoolStructs.BurnRangeCache memory cache
    ) internal returns (
        RangePoolStructs.BurnRangeCache memory
    ) {
        cache.priceLower = ConstantProduct.getPriceAtTick(cache.position.lower, cache.constants);
        cache.priceUpper = ConstantProduct.getPriceAtTick(cache.position.upper, cache.constants);
        cache.liquidityBurned = uint256(params.burnPercent) * cache.position.liquidity / 1e38;
        if (cache.liquidityBurned  == 0) {
            return cache;
        }
        if (cache.liquidityBurned > cache.position.liquidity) require(false, 'NotEnoughPositionLiquidity()');
        {
            uint128 amount0Removed; uint128 amount1Removed;
            (amount0Removed, amount1Removed) = ConstantProduct.getAmountsForLiquidity(
                cache.priceLower,
                cache.priceUpper,
                cache.state.pool.price,
                cache.liquidityBurned ,
                false
            );
            cache.amount0 += amount0Removed.toInt128();
            cache.amount1 += amount1Removed.toInt128();
            cache.position.liquidity -= cache.liquidityBurned.toUint128();
        }
        cache.state = RangeTicks.remove(
            ticks,
            samples,
            tickMap,
            cache.state,
            cache.constants,
            cache.position.lower,
            cache.position.upper,
            uint128(cache.liquidityBurned)
        );
        emit BurnRange(
            params.to,
            params.positionId,
            uint128(cache.liquidityBurned),
            cache.amount0,
            cache.amount1
        );
        if (cache.position.liquidity == 0) {
            cache.position.feeGrowthInside0Last = 0;
            cache.position.feeGrowthInside1Last = 0;
            cache.position.lower = 0;
            cache.position.upper = 0;
        }
        return cache;
    }

    function compound(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        RangePoolStructs.RangePosition memory position,
        RangePoolStructs.CompoundRangeParams memory params
    ) internal returns (
        RangePoolStructs.RangePosition memory,
        PoolsharkStructs.GlobalState memory,
        int128,
        int128
    ) {
        // price tells you the ratio so you need to swap into the correct ratio and add liquidity
        uint256 liquidityAmount = ConstantProduct.getLiquidityForAmounts(
            params.priceLower,
            params.priceUpper,
            state.pool.price,
            params.amount1,
            params.amount0
        );
        if (liquidityAmount > 0) {
            state = RangeTicks.insert(
                ticks,
                samples,
                tickMap,
                state,
                constants,
                position.lower,
                position.upper,
                uint128(liquidityAmount)
            );
            uint256 amount0; uint256 amount1;
            (amount0, amount1) = ConstantProduct.getAmountsForLiquidity(
                params.priceLower,
                params.priceUpper,
                state.pool.price,
                liquidityAmount,
                true
            );
            params.amount0 -= (amount0 <= params.amount0) ? uint128(amount0) : params.amount0;
            params.amount1 -= (amount1 <= params.amount1) ? uint128(amount1) : params.amount1;
            position.liquidity += uint128(liquidityAmount);
        }
        emit CompoundRange(
            params.positionId,
            uint128(liquidityAmount)
        );
        return (position, state, params.amount0.toInt128(), params.amount1.toInt128());
    }

    function update(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.RangePosition memory position,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        RangePoolStructs.UpdateParams memory params
    ) internal returns (
        RangePoolStructs.RangePosition memory,
        int128,
        int128
    ) {
        RangePoolStructs.RangePositionCache memory cache;
        /// @dev - only true if burn call
        if (params.burnPercent > 0) {
            cache.liquidityAmount = uint256(params.burnPercent) * position.liquidity / 1e38;
            if (position.liquidity == cache.liquidityAmount)
                IPositionERC1155(constants.poolToken).burn(msg.sender, params.positionId, 1, constants);
        }

        (uint256 rangeFeeGrowth0, uint256 rangeFeeGrowth1) = rangeFeeGrowth(
            ticks[position.lower].range,
            ticks[position.upper].range,
            state,
            position.lower,
            position.upper
        );

        int128 amount0Fees = OverflowMath.mulDiv(
            rangeFeeGrowth0 - position.feeGrowthInside0Last,
            uint256(position.liquidity),
            Q128
        ).toInt256().toInt128();

        int128 amount1Fees = OverflowMath.mulDiv(
            rangeFeeGrowth1 - position.feeGrowthInside1Last,
            position.liquidity,
            Q128
        ).toInt256().toInt128();

        position.feeGrowthInside0Last = rangeFeeGrowth0;
        position.feeGrowthInside1Last = rangeFeeGrowth1;

        return (position, amount0Fees, amount1Fees);
    }

    function rangeFeeGrowth(
        PoolsharkStructs.RangeTick memory lowerTick,
        PoolsharkStructs.RangeTick memory upperTick,
        PoolsharkStructs.GlobalState memory state,
        int24 lower,
        int24 upper
    ) internal pure returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1) {

        uint256 feeGrowthGlobal0 = state.pool.feeGrowthGlobal0;
        uint256 feeGrowthGlobal1 = state.pool.feeGrowthGlobal1;

        uint256 feeGrowthBelow0;
        uint256 feeGrowthBelow1;
        if (state.pool.tickAtPrice >= lower) {
            feeGrowthBelow0 = lowerTick.feeGrowthOutside0;
            feeGrowthBelow1 = lowerTick.feeGrowthOutside1;
        } else {
            feeGrowthBelow0 = feeGrowthGlobal0 - lowerTick.feeGrowthOutside0;
            feeGrowthBelow1 = feeGrowthGlobal1 - lowerTick.feeGrowthOutside1;
        }

        uint256 feeGrowthAbove0;
        uint256 feeGrowthAbove1;
        if (state.pool.tickAtPrice < upper) {
            feeGrowthAbove0 = upperTick.feeGrowthOutside0;
            feeGrowthAbove1 = upperTick.feeGrowthOutside1;
        } else {
            feeGrowthAbove0 = feeGrowthGlobal0 - upperTick.feeGrowthOutside0;
            feeGrowthAbove1 = feeGrowthGlobal1 - upperTick.feeGrowthOutside1;
        }
        feeGrowthInside0 = feeGrowthGlobal0 - feeGrowthBelow0 - feeGrowthAbove0;
        feeGrowthInside1 = feeGrowthGlobal1 - feeGrowthBelow1 - feeGrowthAbove1;
    }

    function snapshot(
        mapping(uint256 => RangePoolStructs.RangePosition)
            storage positions,
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint32 positionId
    ) internal view returns (
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    ) {
        RangePoolStructs.SnapshotRangeCache memory cache;
        cache.position = positions[positionId];

        // early return if position empty
        if (cache.position.liquidity == 0)
            return (0,0,0,0);

        cache.price = state.pool.price;
        cache.liquidity = state.pool.liquidity;
        cache.samples = state.pool.samples;

        // grab lower tick
        PoolsharkStructs.RangeTick memory tickLower = ticks[cache.position.lower].range;
        
        // grab upper tick
        PoolsharkStructs.RangeTick memory tickUpper = ticks[cache.position.upper].range;

        cache.tickSecondsAccumLower =  tickLower.tickSecondsAccumOutside;
        cache.secondsPerLiquidityAccumLower = tickLower.secondsPerLiquidityAccumOutside;

        // if both have never been crossed into return 0
        cache.tickSecondsAccumUpper = tickUpper.tickSecondsAccumOutside;
        cache.secondsPerLiquidityAccumUpper = tickUpper.secondsPerLiquidityAccumOutside;
        cache.constants = constants;

        (uint256 rangeFeeGrowth0, uint256 rangeFeeGrowth1) = rangeFeeGrowth(
            tickLower,
            tickUpper,
            state,
            cache.position.lower,
            cache.position.upper
        );

        // calcuate fees earned
        cache.amount0 += uint128(
            OverflowMath.mulDiv(
                rangeFeeGrowth0 - cache.position.feeGrowthInside0Last,
                cache.position.liquidity,
                Q128
            )
        );
        cache.amount1 += uint128(
            OverflowMath.mulDiv(
                rangeFeeGrowth1 - cache.position.feeGrowthInside1Last,
                cache.position.liquidity,
                Q128
            )
        );

        cache.tick = state.pool.tickAtPrice;
        if (cache.position.lower >= cache.tick) {
            return (
                cache.tickSecondsAccumLower - cache.tickSecondsAccumUpper,
                cache.secondsPerLiquidityAccumLower - cache.secondsPerLiquidityAccumUpper,
                cache.amount0,
                cache.amount1
            );
        } else if (cache.position.upper >= cache.tick) {
            cache.blockTimestamp = uint32(block.timestamp);
            (
                cache.tickSecondsAccum,
                cache.secondsPerLiquidityAccum
            ) = Samples.getSingle(
                IPool(address(this)), 
                RangePoolStructs.SampleParams(
                    cache.samples.index,
                    cache.samples.count,
                    uint32(block.timestamp),
                    new uint32[](2),
                    cache.tick,
                    cache.liquidity,
                    cache.constants
                ),
                0
            );
            return (
                cache.tickSecondsAccum 
                  - cache.tickSecondsAccumLower 
                  - cache.tickSecondsAccumUpper,
                cache.secondsPerLiquidityAccum
                  - cache.secondsPerLiquidityAccumLower
                  - cache.secondsPerLiquidityAccumUpper,
                cache.amount0,
                cache.amount1
            );
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../interfaces/structs/PoolsharkStructs.sol';
import '../../interfaces/structs/RangePoolStructs.sol';
import '../../interfaces/range/IRangePoolFactory.sol';
import '../../interfaces/range/IRangePool.sol';
import './math/FeeMath.sol';
import './RangePositions.sol';
import '../math/OverflowMath.sol';
import '../math/ConstantProduct.sol';
import '../TickMap.sol';
import '../Samples.sol';

/// @notice Tick management library for range pools
library RangeTicks {
    error LiquidityOverflow();
    error LiquidityUnderflow();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBounds();

    event Initialize(
        uint160 startPrice,
        int24 tickAtPrice,
        int24 minTick,
        int24 maxTick
    );

    event SyncRangeTick(
        uint200 feeGrowthOutside0,
        uint200 feeGrowthOutside1,
        int24 tick
    );

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function validate(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure {
        if (lower % tickSpacing != 0) require(false, 'InvalidLowerTick()');
        if (lower < ConstantProduct.minTick(tickSpacing)) require(false, 'InvalidLowerTick()');
        if (upper % tickSpacing != 0) require(false, 'InvalidUpperTick()');
        if (upper > ConstantProduct.maxTick(tickSpacing)) require(false, 'InvalidUpperTick()');
        if (lower >= upper) require(false, 'InvalidPositionBounds()');
    }

    function insert(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        int24 lower,
        int24 upper,
        uint128 amount
    ) internal returns (PoolsharkStructs.GlobalState memory) {
        validate(lower, upper, constants.tickSpacing);

        // check for amount to overflow liquidity delta & global
        if (amount == 0)
            require(false, 'NoLiquidityBeingAdded()');
        if (state.liquidityGlobal + amount > uint128(type(int128).max))
            require(false, 'LiquidityOverflow()');

        // get tick at price
        int24 tickAtPrice = state.pool.tickAtPrice;

        if(TickMap.set(tickMap, lower, constants.tickSpacing)) {
            ticks[lower].range.liquidityDelta += int128(amount);
            ticks[lower].range.liquidityAbsolute += amount;
        } else {
            if (lower <= tickAtPrice) {
                (
                    int56 tickSecondsAccum,
                    uint160 secondsPerLiquidityAccum
                ) = Samples.getSingle(
                        IPool(address(this)), 
                        RangePoolStructs.SampleParams(
                            state.pool.samples.index,
                            state.pool.samples.count,
                            uint32(block.timestamp),
                            new uint32[](2),
                            state.pool.tickAtPrice,
                            state.pool.liquidity,
                            constants
                        ),
                        0
                );
                ticks[lower].range = PoolsharkStructs.RangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    secondsPerLiquidityAccum,
                    tickSecondsAccum,
                    int128(amount),             // liquidityDelta
                    amount                      // liquidityAbsolute
                );
                emit SyncRangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    lower
                );
            } else {
                ticks[lower].range.liquidityDelta = int128(amount);
                ticks[lower].range.liquidityAbsolute += amount;
            }
        }
        if(TickMap.set(tickMap, upper, constants.tickSpacing)) {
            ticks[upper].range.liquidityDelta -= int128(amount);
            ticks[upper].range.liquidityAbsolute += amount;
        } else {
            if (upper <= tickAtPrice) {

                (
                    int56 tickSecondsAccum,
                    uint160 secondsPerLiquidityAccum
                ) = Samples.getSingle(
                        IPool(address(this)), 
                        RangePoolStructs.SampleParams(
                            state.pool.samples.index,
                            state.pool.samples.count,
                            uint32(block.timestamp),
                            new uint32[](2),
                            state.pool.tickAtPrice,
                            state.pool.liquidity,
                            constants
                        ),
                        0
                );
                ticks[upper].range = PoolsharkStructs.RangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    secondsPerLiquidityAccum,
                    tickSecondsAccum,
                    -int128(amount),
                    amount
                );
                emit SyncRangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    upper
                );
            } else {
                ticks[upper].range.liquidityDelta = -int128(amount);
                ticks[upper].range.liquidityAbsolute = amount;
            }
        }
        if (tickAtPrice >= lower && tickAtPrice < upper) {
            // write an oracle entry
            (state.pool.samples.index, state.pool.samples.count) = Samples.save(
                samples,
                state.pool.samples,
                state.pool.liquidity,
                state.pool.tickAtPrice
            );
            // update pool liquidity
            state.pool.liquidity += amount;
        }
        // update global liquidity
        state.liquidityGlobal += amount;

        return state;
    }

    function remove(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants, 
        int24 lower,
        int24 upper,
        uint128 amount
    ) internal returns (PoolsharkStructs.GlobalState memory) {
        validate(lower, upper, constants.tickSpacing);
        //check for amount to overflow liquidity delta & global
        if (amount == 0) return state;
        if (amount > uint128(type(int128).max)) require(false, 'LiquidityUnderflow()');
        if (amount > state.liquidityGlobal) require(false, 'LiquidityUnderflow()');

        // get pool tick at price
        int24 tickAtPrice = state.pool.tickAtPrice;

        // update lower liquidity values
        PoolsharkStructs.RangeTick memory tickLower = ticks[lower].range;
        unchecked {
            tickLower.liquidityDelta -= int128(amount);
            tickLower.liquidityAbsolute -= amount;
        }
        ticks[lower].range = tickLower;
        // try to clear tick if possible
        clear(ticks, constants, tickMap, lower);

        // update upper liquidity values
        PoolsharkStructs.RangeTick memory tickUpper = ticks[upper].range;
        unchecked {
            tickUpper.liquidityDelta += int128(amount);
            tickUpper.liquidityAbsolute -= amount;
        }
        ticks[upper].range = tickUpper;
        // try to clear tick if possible
        clear(ticks, constants, tickMap, upper);

        if (tickAtPrice >= lower && tickAtPrice < upper) {
            // write an oracle entry
            (state.pool.samples.index, state.pool.samples.count) = Samples.save(
                samples,
                state.pool.samples,
                state.pool.liquidity,
                tickAtPrice
            );
            state.pool.liquidity -= amount;  
        }
        state.liquidityGlobal -= amount;

        return state;
    }

    function clear(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.LimitImmutables memory constants,
        PoolsharkStructs.TickMap storage tickMap,
        int24 tickToClear
    ) internal {
        if (_empty(ticks[tickToClear])) {
            if (tickToClear != ConstantProduct.maxTick(constants.tickSpacing) &&
                    tickToClear != ConstantProduct.minTick(constants.tickSpacing)) {
                ticks[tickToClear].range = PoolsharkStructs.RangeTick(0,0,0,0,0,0);
                TickMap.unset(tickMap, tickToClear, constants.tickSpacing);
            }
        }
    }

    function _empty(
        LimitPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.range.liquidityAbsolute != 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './math/ConstantProduct.sol';
import './utils/SafeCast.sol';
import '../interfaces/IPool.sol';
import '../interfaces/range/IRangePool.sol';
import '../interfaces/structs/RangePoolStructs.sol';

library Samples {
    using SafeCast for uint256;

    uint8 internal constant TIME_DELTA_MAX = 6;

    error InvalidSampleLength();
    error SampleArrayUninitialized();
    error SampleLengthNotAvailable();

    event SampleRecorded(
        int56 tickSecondsAccum,
        uint160 secondsPerLiquidityAccum
    );

    event SampleCountIncreased(
        uint16 newSampleCountMax
    );

    function initialize(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.RangePoolState memory state
    ) internal returns (
        PoolsharkStructs.RangePoolState memory
    )
    {
        samples[0] = PoolsharkStructs.Sample({
            blockTimestamp: uint32(block.timestamp),
            tickSecondsAccum: 0,
            secondsPerLiquidityAccum: 0
        });

        state.samples.count = 1;
        state.samples.countMax = 5;

        return state;
        /// @dev - TWAP length of 5 is safer for oracle manipulation
    }

    function save(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.SampleState memory sampleState,
        uint128 startLiquidity, /// @dev - liquidity from start of block
        int24  tick
    ) internal returns (
        uint16 sampleIndexNew,
        uint16 sampleLengthNew
    ) {
        // grab the latest sample
        RangePoolStructs.Sample memory newSample = samples[sampleState.index];

        // early return if timestamp has not advanced 2 seconds
        if (newSample.blockTimestamp + 2 > uint32(block.timestamp))
            return (sampleState.index, sampleState.count);

        if (sampleState.countMax > sampleState.count
            && sampleState.index == (sampleState.count - 1)) {
            // increase sampleLengthNew if old size exceeded
            sampleLengthNew = sampleState.count + 1;
        } else {
            sampleLengthNew = sampleState.count;
        }
        sampleIndexNew = (sampleState.index + 1) % sampleLengthNew;
        samples[sampleIndexNew] = _build(newSample, uint32(block.timestamp), tick, startLiquidity);

        emit SampleRecorded(
            samples[sampleIndexNew].tickSecondsAccum,
            samples[sampleIndexNew].secondsPerLiquidityAccum
        );
    }

    function expand(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.RangePoolState storage pool,
        uint16 newSampleCountMax
    ) internal {
        if (newSampleCountMax <= pool.samples.countMax) return ;
        for (uint16 i = pool.samples.countMax; i < newSampleCountMax; i++) {
            samples[i].blockTimestamp = 1;
        }
        pool.samples.countMax = newSampleCountMax;
        emit SampleCountIncreased(newSampleCountMax);
    }

    function get(
        address pool,
        RangePoolStructs.SampleParams memory params
    ) internal view returns (
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    ) {
        if (params.sampleLength == 0) require(false, 'InvalidSampleLength()');
        if (params.secondsAgo.length == 0) require(false, 'SecondsAgoArrayEmpty()');
        uint256 size = params.secondsAgo.length > 1 ? params.secondsAgo.length : 2;
        uint32[] memory secondsAgo = new uint32[](size);
        if (params.secondsAgo.length == 1) {
            secondsAgo = new uint32[](2);
            secondsAgo[0] = params.secondsAgo[0];
            secondsAgo[1] = params.secondsAgo[0] + 2;
        }
        else secondsAgo = params.secondsAgo;

        if (secondsAgo[0] == secondsAgo[secondsAgo.length - 1]) require(false, 'SecondsAgoArrayValuesEqual()');

        tickSecondsAccum = new int56[](secondsAgo.length);
        secondsPerLiquidityAccum = new uint160[](secondsAgo.length);

        for (uint256 i = 0; i < secondsAgo.length; i++) {
            (
                tickSecondsAccum[i],
                secondsPerLiquidityAccum[i]
            ) = getSingle(
                IPool(pool),
                params,
                secondsAgo[i]
            );
        }
        if (secondsAgo[secondsAgo.length - 1] > secondsAgo[0]) {
            averageTick = int24((tickSecondsAccum[0] - tickSecondsAccum[secondsAgo.length - 1]) 
                                / int32(secondsAgo[secondsAgo.length - 1] - secondsAgo[0]));
            averagePrice = ConstantProduct.getPriceAtTick(averageTick, params.constants);
            averageLiquidity = uint128((secondsPerLiquidityAccum[0] - secondsPerLiquidityAccum[secondsAgo.length - 1]) 
                                    * (secondsAgo[secondsAgo.length - 1] - secondsAgo[0]));
        } else {
            averageTick = int24((tickSecondsAccum[secondsAgo.length - 1] - tickSecondsAccum[0]) 
                                / int32(secondsAgo[0] - secondsAgo[secondsAgo.length - 1]));
            averagePrice = ConstantProduct.getPriceAtTick(averageTick, params.constants);
            averageLiquidity = uint128((secondsPerLiquidityAccum[secondsAgo.length - 1] - secondsPerLiquidityAccum[0]) 
                                    * (secondsAgo[0] - secondsAgo[secondsAgo.length - 1]));
        }
    }

    function _poolSample(
        IPool pool,
        uint256 sampleIndex
    ) internal view returns (
        RangePoolStructs.Sample memory
    ) {
        (
            uint32 blockTimestamp,
            int56 tickSecondsAccum,
            uint160 liquidityPerSecondsAccum
        ) = pool.samples(sampleIndex);

        return PoolsharkStructs.Sample(
            blockTimestamp,
            tickSecondsAccum,
            liquidityPerSecondsAccum
        );
    }

    function getSingle(
        IPool pool,
        RangePoolStructs.SampleParams memory params,
        uint32 secondsAgo
    ) internal view returns (
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum
    ) {
        RangePoolStructs.Sample memory latest = _poolSample(pool, params.sampleIndex);

        if (secondsAgo == 0) {
            // if 2 seconds have elapsed build new sample
            if (latest.blockTimestamp + 2 <= uint32(block.timestamp)) {
                latest = _build(
                    latest,
                    uint32(block.timestamp),
                    params.tick,
                    params.liquidity
                );
            } 
            return (
                latest.tickSecondsAccum,
                latest.secondsPerLiquidityAccum
            );
        }

        uint32 targetTime = uint32(block.timestamp) - secondsAgo;

        // should be getting samples
        (
            RangePoolStructs.Sample memory firstSample,
            RangePoolStructs.Sample memory secondSample
        ) = _getAdjacentSamples(
                pool,
                latest,
                params,
                targetTime
        );

        if (targetTime == firstSample.blockTimestamp) {
            // first sample
            return (
                firstSample.tickSecondsAccum,
                firstSample.secondsPerLiquidityAccum
            );
        } else if (targetTime == secondSample.blockTimestamp) {
            // second sample
            return (
                secondSample.tickSecondsAccum,
                secondSample.secondsPerLiquidityAccum
            );
        } else {
            // average two samples
            int32 sampleTimeDelta = int32(secondSample.blockTimestamp - firstSample.blockTimestamp);
            int56 targetDelta = int56(int32(targetTime - firstSample.blockTimestamp));
            return (
                firstSample.tickSecondsAccum +
                    ((secondSample.tickSecondsAccum - firstSample.tickSecondsAccum) 
                    / sampleTimeDelta)
                    * targetDelta,
                firstSample.secondsPerLiquidityAccum +
                    uint160(
                        (uint256(
                            secondSample.secondsPerLiquidityAccum - firstSample.secondsPerLiquidityAccum
                        ) 
                        * uint256(uint56(targetDelta))) 
                        / uint32(sampleTimeDelta)
                    )
            );
        }
    }

    function getLatest(
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint256 liquidity
    ) internal view returns (
        uint160 latestPrice,
        uint160 secondsPerLiquidityAccum,
        int56 tickSecondsAccum
    ) {
        uint32 timeDelta = timeElapsed(constants);
        (
            tickSecondsAccum,
            secondsPerLiquidityAccum
        ) = getSingle(
                IPool(address(this)), 
                RangePoolStructs.SampleParams(
                    state.pool.samples.index,
                    state.pool.samples.count,
                    uint32(block.timestamp),
                    new uint32[](2),
                    state.pool.tickAtPrice,
                    liquidity.toUint128(),
                    constants
                ),
                0
        );
        // grab older sample for dynamic fee calculation
        (
            int56 tickSecondsAccumBase,
        ) = Samples.getSingle(
                IPool(address(this)), 
                RangePoolStructs.SampleParams(
                    state.pool.samples.index,
                    state.pool.samples.count,
                    uint32(block.timestamp),
                    new uint32[](2),
                    state.pool.tickAtPrice,
                    liquidity.toUint128(),
                    constants
                ),
                timeDelta
        );

        latestPrice = calculateLatestPrice(
            tickSecondsAccum,
            tickSecondsAccumBase,
            timeDelta,
            TIME_DELTA_MAX,
            constants
        );
    }

    function calculateLatestPrice(
        int56 tickSecondsAccum,
        int56 tickSecondsAccumBase,
        uint32 timeDelta,
        uint32 timeDeltaMax,
        PoolsharkStructs.LimitImmutables memory constants
    ) private pure returns (
        uint160 averagePrice
    ) {
        int56 tickSecondsAccumDiff = tickSecondsAccum - tickSecondsAccumBase;
        int24 averageTick;
        if (timeDelta == timeDeltaMax) {
            averageTick = int24(tickSecondsAccumDiff / int32(timeDelta));
        } else {
            averageTick = int24(tickSecondsAccum / int32(timeDelta));
        }
        averagePrice = ConstantProduct.getPriceAtTick(averageTick, constants);
    }


    function timeElapsed(
        PoolsharkStructs.LimitImmutables memory constants
    ) private view returns (
        uint32
    )    
    {
        return  uint32(block.timestamp) - constants.genesisTime >= TIME_DELTA_MAX
                    ? TIME_DELTA_MAX
                    : uint32(block.timestamp - constants.genesisTime);
    }

    function _lte(
        uint32 timeA,
        uint32 timeB
    ) private view returns (bool) {
        uint32 currentTime = uint32(block.timestamp);
        if (timeA <= currentTime && timeB <= currentTime) return timeA <= timeB;

        uint256 timeAOverflow = timeA;
        uint256 timeBOverflow = timeB;

        if (timeA <= currentTime) {
            timeAOverflow = timeA + 2**32;
        }
        if (timeB <= currentTime) {
            timeBOverflow = timeB + 2**32;
        }

        return timeAOverflow <= timeBOverflow;
    }

    function _build(
        RangePoolStructs.Sample memory newSample,
        uint32  blockTimestamp,
        int24   tick,
        uint128 liquidity
    ) internal pure returns (
         RangePoolStructs.Sample memory
    ) {
        int56 timeDelta = int56(uint56(blockTimestamp - newSample.blockTimestamp));

        return
            PoolsharkStructs.Sample({
                blockTimestamp: blockTimestamp,
                tickSecondsAccum: newSample.tickSecondsAccum + int56(tick) * int32(timeDelta),
                secondsPerLiquidityAccum: newSample.secondsPerLiquidityAccum +
                    ((uint160(uint56(timeDelta)) << 128) / (liquidity > 0 ? liquidity : 1))
            });
    }

    function _binarySearch(
        IPool pool,
        uint32 targetTime,
        uint16 sampleIndex,
        uint16 sampleLength
    ) private view returns (
        RangePoolStructs.Sample memory firstSample,
        RangePoolStructs.Sample memory secondSample
    ) {
        uint256 oldIndex = (sampleIndex + 1) % sampleLength;
        uint256 newIndex = oldIndex + sampleLength - 1;             
        uint256 index;
        while (true) {
            // start in the middle
            index = (oldIndex + newIndex) / 2;

            // get the first sample
            firstSample = _poolSample(pool, index % sampleLength);

            // if sample is uninitialized
            if (firstSample.blockTimestamp == 0) {
                // skip this index and continue
                oldIndex = index + 1;
                continue;
            }
            // else grab second sample
            secondSample = _poolSample(pool, (index + 1) % sampleLength);

            // check if target time within first and second sample
            bool targetAfterFirst   = _lte(firstSample.blockTimestamp, targetTime);
            bool targetBeforeSecond = _lte(targetTime, secondSample.blockTimestamp);
            if (targetAfterFirst && targetBeforeSecond) break;
            if (!targetAfterFirst) newIndex = index - 1;
            else oldIndex = index + 1;
        }
    }

    function _getAdjacentSamples(
        IPool pool,
        RangePoolStructs.Sample memory firstSample,
        RangePoolStructs.SampleParams memory params,
        uint32 targetTime
    ) private view returns (
        RangePoolStructs.Sample memory,
        RangePoolStructs.Sample memory
    ) {
        if (_lte(firstSample.blockTimestamp, targetTime)) {
            if (firstSample.blockTimestamp == targetTime) {
                return (firstSample, PoolsharkStructs.Sample(0,0,0));
            } else {
                return (firstSample, _build(firstSample, targetTime, params.tick, params.liquidity));
            }
        }
        firstSample = _poolSample(pool, (params.sampleIndex + 1) % params.sampleLength);
        if (firstSample.blockTimestamp == 0) {
            firstSample = _poolSample(pool, 0);
        }
        if(!_lte(firstSample.blockTimestamp, targetTime)) require(false, 'SampleLengthNotAvailable()');

        return _binarySearch(
            pool,
            targetTime,
            params.sampleIndex,
            params.sampleLength
        );
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './math/ConstantProduct.sol';
import '../interfaces/structs/PoolsharkStructs.sol';

library TickMap {

    error TickIndexOverflow();
    error TickIndexUnderflow();
    error TickIndexBadSpacing();
    error BlockIndexOverflow();

    function get(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int24 tickSpacing
    ) internal view returns (
        bool exists
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
        ) = getIndices(tick, tickSpacing);

        // check if bit is already set
        uint256 word = tickMap.ticks[wordIndex] | 1 << (tickIndex & 0xFF);
        if (word == tickMap.ticks[wordIndex]) {
            return true;
        }
        return false;
    }

    function set(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int24 tickSpacing
    ) internal returns (
        bool exists
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, tickSpacing);

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
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing
    ) internal {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, tickSpacing);

        tickMap.ticks[wordIndex] &= ~(1 << (tickIndex & 0xFF));
        if (tickMap.ticks[wordIndex] == 0) {
            tickMap.words[blockIndex] &= ~(1 << (wordIndex & 0xFF));
            if (tickMap.words[blockIndex] == 0) {
                tickMap.blocks &= ~(1 << blockIndex);
            }
        }
    }

    function previous(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing,
        bool inclusive
    ) internal view returns (
        int24 previousTick
    ) {
        unchecked {
            // rounds up to ensure relative position
            if (tick % (tickSpacing / 2) != 0 || inclusive) {
                if (tick < (ConstantProduct.maxTick(tickSpacing) - tickSpacing / 2)) {
                    /// @dev - ensures we cross when tick >= 0
                    if (tick >= 0) {
                        tick += tickSpacing / 2;
                    } else if (inclusive && tick % (tickSpacing / 2) == 0) {
                    /// @dev - ensures we cross when tick == tickAtPrice
                        tick += tickSpacing / 2;
                    }
                }
            }
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, tickSpacing);

            uint256 word = tickMap.ticks[wordIndex] & ((1 << (tickIndex & 0xFF)) - 1);
            if (word == 0) {
                uint256 block_ = tickMap.words[blockIndex] & ((1 << (wordIndex & 0xFF)) - 1);
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ((1 << blockIndex) - 1);
                    if (blockMap == 0) return tick;

                    blockIndex = _msb(blockMap);
                    block_ = tickMap.words[blockIndex];
                }
                wordIndex = (blockIndex << 8) | _msb(block_);
                word = tickMap.ticks[wordIndex];
            }
            previousTick = _tick((wordIndex << 8) | _msb(word), tickSpacing);
        }
    }

    function next(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing,
        bool inclusive
    ) internal view returns (
        int24 nextTick
    ) {
        unchecked {
            /// @dev - handles tickAtPrice being past tickSpacing / 2
            if (inclusive && tick % tickSpacing != 0) {
                // e.g. tick is 5 we subtract 1 to look ahead at 5
                if (tick > 0 && (tick % tickSpacing <= (tickSpacing / 2)))
                    tick -= 1;
                // e.g. tick is -5 we subtract 1 to look ahead at -5
                else if (tick < 0 && (tick % tickSpacing <= -(tickSpacing / 2)))
                    tick -= 1;
                // e.g. tick = 7 and tickSpacing = 10 we sub 5 to look ahead at 5
                // e.g. tick = -2 and tickSpacing = 10 we sub 5 to look ahead at -5
                else
                    tick -= tickSpacing / 2;
            }
            /// @dev - handles negative ticks rounding up
            if (tick % (tickSpacing / 2) != 0) {
                if (tick < 0)
                    if (tick > (ConstantProduct.minTick(tickSpacing) + tickSpacing / 2))
                        tick -= tickSpacing / 2;
            }
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, tickSpacing);
            uint256 word;
            if ((tickIndex & 0xFF) != 255) {
                word = tickMap.ticks[wordIndex] & ~((1 << ((tickIndex & 0xFF) + 1)) - 1);
            }
            if (word == 0) {
                uint256 block_;
                if ((blockIndex & 0xFF) != 255) {
                    block_ = tickMap.words[blockIndex] & ~((1 << ((wordIndex & 0xFF) + 1)) - 1);
                }
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ~((1 << blockIndex + 1) - 1);
                    if (blockMap == 0) return tick;
                    blockIndex = _lsb(blockMap);
                    block_ = tickMap.words[blockIndex];
                }
                wordIndex = (blockIndex << 8) | _lsb(block_);
                word = tickMap.ticks[wordIndex];
            }
            nextTick = _tick((wordIndex << 8) | _lsb(word), tickSpacing);
        }
    }

    function getIndices(
        int24 tick,
        int24 tickSpacing
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        )
    {
        unchecked {
            if (tick > ConstantProduct.MAX_TICK) require(false, ' TickIndexOverflow()');
            if (tick < ConstantProduct.MIN_TICK) require(false, 'TickIndexUnderflow()');
            if (tick % (tickSpacing / 2) != 0) tick = round(tick, tickSpacing / 2);
            tickIndex = uint256(int256((round(tick, tickSpacing / 2) 
                                        - round(ConstantProduct.MIN_TICK, tickSpacing / 2)) 
                                        / (tickSpacing / 2)));
            wordIndex = tickIndex >> 8;   // 2^8 ticks per word
            blockIndex = tickIndex >> 16; // 2^8 words per block
            if (blockIndex > 255) require(false, 'BlockIndexOverflow()');
        }
    }



    function _tick (
        uint256 tickIndex,
        int24 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(round(ConstantProduct.MAX_TICK, tickSpacing) * 2) * 2) 
                require(false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * (tickSpacing / 2) + round(ConstantProduct.MIN_TICK, tickSpacing / 2));
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

    function round(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (
        int24 roundedTick
    ) {
        return tick / tickSpacing * tickSpacing;
    }

    function roundHalf(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants,
        uint256 price
    ) internal pure returns (
        int24 roundedTick,
        uint160 roundedTickPrice
    ) {
        //pool.tickAtPrice -99.5
        //pool.tickAtPrice -100
        //-105
        //-95
        roundedTick = tick / constants.tickSpacing * constants.tickSpacing;
        roundedTickPrice = ConstantProduct.getPriceAtTick(roundedTick, constants);
        if (price == roundedTickPrice)
            return (roundedTick, roundedTickPrice);
        if (roundedTick > 0) {
            roundedTick += constants.tickSpacing / 2;
        } else if (roundedTick < 0) {
            if (roundedTickPrice < price)
                roundedTick += constants.tickSpacing / 2;
            else
                roundedTick -= constants.tickSpacing / 2;
        } else {
            if (price > roundedTickPrice) {
                roundedTick += constants.tickSpacing / 2;
            } else if (price < roundedTickPrice) {
                roundedTick -= constants.tickSpacing / 2;
            }
        }
    }

    function roundAhead(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants,
        bool zeroForOne,
        uint256 price
    ) internal pure returns (
        int24 roundedTick
    ) {
        roundedTick = tick / constants.tickSpacing * constants.tickSpacing;
        uint160 roundedTickPrice = ConstantProduct.getPriceAtTick(roundedTick, constants);
        if (price == roundedTickPrice)
            return roundedTick;
        if (zeroForOne) {
            // round up if positive
            if (roundedTick > 0 || (roundedTick == 0 && tick >= 0))
                roundedTick += constants.tickSpacing;
            else if (tick % constants.tickSpacing == 0) {
                // handle price at -99.5 and tickAtPrice == -100
                if (tick < 0 && roundedTickPrice < price) {
                    roundedTick += constants.tickSpacing;
                }
            }
        } else {
            // round down if negative
            if (roundedTick < 0 || (roundedTick == 0 && tick < 0))
            /// @dev - strictly less due to TickMath always rounding to lesser values
                roundedTick -= constants.tickSpacing;
        }
    }

    function roundBack(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants,
        bool zeroForOne,
        uint256 price
    ) internal pure returns (
        int24 roundedTick
    ) {
        roundedTick = tick / constants.tickSpacing * constants.tickSpacing;
        uint160 roundedTickPrice = ConstantProduct.getPriceAtTick(roundedTick, constants);
        if (price == roundedTickPrice)
            return roundedTick;
        if (zeroForOne) {
            // round down if negative
            if (roundedTick < 0 || (roundedTick == 0 && tick < 0))
                roundedTick -= constants.tickSpacing;
        } else {
            // round up if positive
            if (roundedTick > 0 || (roundedTick == 0 && tick >= 0))
                roundedTick += constants.tickSpacing;
            else if (tick % constants.tickSpacing == 0) {
                // handle price at -99.5 and tickAtPrice == -100
                if (tick < 0 && roundedTickPrice < price) {
                    roundedTick += constants.tickSpacing;
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../interfaces/structs/PoolsharkStructs.sol';
import './range/math/FeeMath.sol';
import './math/OverflowMath.sol';
import './math/ConstantProduct.sol';
import './TickMap.sol';
import './utils/SafeCast.sol';
import './range/math/FeeMath.sol';
import './Samples.sol';
import './limit/EpochMap.sol';
import './limit/LimitTicks.sol';

library Ticks {

    using SafeCast for uint256;

    // cross flags
    uint8 internal constant RANGE_TICK = 2**0;
    uint8 internal constant LIMIT_TICK = 2**1;
    uint8 internal constant LIMIT_POOL = 2**2;

    // for Q64.96 numbers
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    event Initialize(
        int24 minTick,
        int24 maxTick,
        uint160 startPrice,
        int24 startTick
    );

    event Swap(
        address indexed recipient,
        uint256 amountIn,
        uint256 amountOut,
        uint200 feeGrowthGlobal0,
        uint200 feeGrowthGlobal1,
        uint160 price,
        uint128 liquidity,
        uint128 feeAmount,
        int24 tickAtPrice,
        bool indexed zeroForOne,
        bool indexed exactIn
    );

    event SyncRangeTick(
        uint200 feeGrowthOutside0,
        uint200 feeGrowthOutside1,
        int24 tick
    );

    function initialize(
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint160 startPrice
    ) external returns (
        PoolsharkStructs.GlobalState memory  
    )
    {
        // state should only be initialized once
        if (state.pool0.price > 0) require (false, 'PoolAlreadyInitialized()');

        // initialize state
        state.epoch = 1;
        state.positionIdNext = 1;

        // check price bounds
        if (startPrice < constants.bounds.min || startPrice >= constants.bounds.max) require(false, 'StartPriceInvalid()');

        // initialize range ticks
        TickMap.set(rangeTickMap, ConstantProduct.minTick(constants.tickSpacing), constants.tickSpacing);
        TickMap.set(rangeTickMap, ConstantProduct.maxTick(constants.tickSpacing), constants.tickSpacing);
        
        // initialize limit ticks
        TickMap.set(limitTickMap, ConstantProduct.minTick(constants.tickSpacing), constants.tickSpacing);
        TickMap.set(limitTickMap, ConstantProduct.maxTick(constants.tickSpacing), constants.tickSpacing);

        // initialize price
        state.pool.price = startPrice;
        state.pool0.price = startPrice;
        state.pool1.price = startPrice;

        int24 startTick = ConstantProduct.getTickAtPrice(startPrice, constants);
        state.pool.tickAtPrice = startTick;
        state.pool0.tickAtPrice = startTick;
        state.pool1.tickAtPrice = startTick;

        // intialize samples
        state.pool = Samples.initialize(samples, state.pool);

        // emit event
        emit Initialize(
            ConstantProduct.minTick(constants.tickSpacing),
            ConstantProduct.maxTick(constants.tickSpacing),
            state.pool0.price,
            state.pool0.tickAtPrice
        );

        return state;
    }
    
    function swap(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        PoolsharkStructs.SwapParams memory params,
        PoolsharkStructs.SwapCache memory cache
    ) external returns (
        PoolsharkStructs.SwapCache memory
    )
    {
        cache.price = cache.state.pool.price;
        cache.crossTick = cache.state.pool.tickAtPrice;

        // set initial cross state
        cache = _iterate(ticks, rangeTickMap, limitTickMap, cache, params.zeroForOne, true);

        uint128 startLiquidity = cache.liquidity.toUint128();

        // grab sample for accumulators
        cache = PoolsharkStructs.SwapCache({
            state: cache.state,
            constants: cache.constants,
            price: cache.price,
            liquidity: cache.liquidity,
            amountLeft: params.amount,
            input:  0,
            output: 0,
            crossPrice: cache.crossPrice,
            secondsPerLiquidityAccum: 0,
            feeAmount: 0,
            tickSecondsAccum: 0,
            tickSecondsAccumBase: 0,
            crossTick: cache.crossTick,
            crossStatus: cache.crossStatus,
            limitActive: cache.limitActive,
            exactIn: params.exactIn,
            cross: true,
            averagePrice: 0
        });
        // grab latest price and sample
        (
            cache.averagePrice,
            cache.secondsPerLiquidityAccum,
            cache.tickSecondsAccum
         ) = Samples.getLatest(cache.state, cache.constants, cache.liquidity);

        // grab latest sample and store in cache for _cross
        while (cache.cross) {
            // handle price being at cross tick
            cache = _quoteSingle(cache, params.priceLimit, params.zeroForOne);
            if (cache.cross) {
                cache = _cross(
                    ticks,
                    rangeTickMap,
                    limitTickMap,
                    cache,
                    params
                );
            }
        }
        /// @dev - write oracle entry after start of block
        (
            cache.state.pool.samples.index,
            cache.state.pool.samples.count
        ) = Samples.save(
            samples,
            cache.state.pool.samples,
            startLiquidity,
            cache.state.pool.tickAtPrice
        );
        // pool liquidity should be updated along the way
        cache.state.pool.price = cache.price.toUint160();

        if (cache.price != cache.crossPrice) {
            cache.state.pool.tickAtPrice = ConstantProduct.getTickAtPrice(cache.price.toUint160(), cache.constants);
        } else {
            cache.state.pool.tickAtPrice = cache.crossTick;
        }
        if (cache.limitActive) {
            if (params.zeroForOne) {
                cache.state.pool1.price = cache.state.pool.price;
                cache.state.pool1.tickAtPrice = cache.state.pool.tickAtPrice;
            } else {
                cache.state.pool0.price = cache.state.pool.price;
                cache.state.pool0.tickAtPrice = cache.state.pool.tickAtPrice;
            }
        }
        emit Swap(
            params.to,
            cache.input,
            cache.output,
            cache.state.pool.feeGrowthGlobal0,
            cache.state.pool.feeGrowthGlobal1,
            cache.price.toUint160(),
            cache.liquidity.toUint128(),
            cache.feeAmount,
            cache.state.pool.tickAtPrice,
            params.zeroForOne,
            params.exactIn
        );
        return cache;
    }

    function quote(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        PoolsharkStructs.QuoteParams memory params,
        PoolsharkStructs.SwapCache memory cache
    ) internal view returns (
        uint256,
        uint256,
        uint160
    ) {
        // start with range price
        cache.price = cache.state.pool.price;
        cache.crossTick = cache.state.pool.tickAtPrice;

        cache = _iterate(ticks, rangeTickMap, limitTickMap, cache, params.zeroForOne, true);
        
        // set crossTick/crossPrice based on the best between limit and range
        // grab sample for accumulators
        cache = PoolsharkStructs.SwapCache({
            state: cache.state,
            constants: cache.constants,
            price: cache.price,
            liquidity: cache.liquidity,
            amountLeft: params.amount,
            input:  0,
            output: 0,
            crossPrice: cache.crossPrice,
            secondsPerLiquidityAccum: 0,
            feeAmount: 0,
            tickSecondsAccum: 0,
            tickSecondsAccumBase: 0,
            crossTick: cache.crossTick,
            crossStatus: cache.crossStatus,
            limitActive: cache.limitActive,
            exactIn: params.exactIn,
            cross: true,
            averagePrice: 0
        });
        // grab latest price and sample
        (
            cache.averagePrice,
            cache.secondsPerLiquidityAccum,
            cache.tickSecondsAccum
         ) = Samples.getLatest(cache.state, cache.constants, cache.liquidity);
        while (cache.cross) {
            cache = _quoteSingle(cache, params.priceLimit, params.zeroForOne);
            if (cache.cross) {
                cache = _pass(
                    ticks,
                    rangeTickMap,
                    limitTickMap,
                    cache,
                    params
                );
            }
        }
        return (
            cache.input,
            cache.output,
            cache.price.toUint160()
        );
    }

    function _quoteSingle(
        PoolsharkStructs.SwapCache memory cache,
        uint160 priceLimit,
        bool zeroForOne
    ) internal pure returns (
        PoolsharkStructs.SwapCache memory
    ) {
        if ((zeroForOne ? priceLimit >= cache.price
                        : priceLimit <= cache.price) ||
            (zeroForOne && cache.price == cache.constants.bounds.min) ||
            (!zeroForOne && cache.price == cache.constants.bounds.max) ||
            (cache.amountLeft == 0 && cache.liquidity > 0))
        {
            cache.cross = false;
            return cache;
        }
        uint256 nextPrice = cache.crossPrice;
         uint256 amountIn; uint256 amountOut;
        if (zeroForOne) {
            // Trading token 0 (x) for token 1 (y).
            // price  is decreasing.
            if (nextPrice < priceLimit) {
                nextPrice = priceLimit;
            }
            uint256 amountMax = cache.exactIn ? ConstantProduct.getDx(cache.liquidity, nextPrice, cache.price, true)
                                              : ConstantProduct.getDy(cache.liquidity, nextPrice, cache.price, false);
            if (cache.amountLeft < amountMax) {
                // calculate price after swap
                uint256 newPrice = ConstantProduct.getNewPrice(
                    cache.price,
                    cache.liquidity,
                    cache.amountLeft,
                    zeroForOne,
                    cache.exactIn
                );
                if (cache.exactIn) {
                    amountIn = cache.amountLeft;
                    amountOut = ConstantProduct.getDy(cache.liquidity, newPrice, uint256(cache.price), false);
                } else {
                    amountIn = ConstantProduct.getDx(cache.liquidity, newPrice, uint256(cache.price), true);
                    amountOut = cache.amountLeft;
                }
                cache.amountLeft = 0;
                cache.cross = false;
                cache.price = uint160(newPrice);
            } else {
                if (cache.exactIn) {
                    amountIn = amountMax;
                    amountOut = ConstantProduct.getDy(cache.liquidity, nextPrice, cache.price, false);

                } else {
                    amountIn = ConstantProduct.getDx(cache.liquidity, nextPrice, cache.price, true);
                    amountOut = amountMax;
                }
                cache.amountLeft -= amountMax;
                if (nextPrice == cache.crossPrice) cache.cross = true;
                else cache.cross = false;
                cache.price = uint160(nextPrice);
            }
        } else {
            // Price is increasing.
            if (nextPrice > priceLimit) {
                nextPrice = priceLimit;
            }
            uint256 amountMax = cache.exactIn ? ConstantProduct.getDy(cache.liquidity, uint256(cache.price), nextPrice, true)
                                              : ConstantProduct.getDx(cache.liquidity, uint256(cache.price), nextPrice, false);
            if (cache.amountLeft < amountMax) {
                uint256 newPrice = ConstantProduct.getNewPrice(
                    cache.price,
                    cache.liquidity,
                    cache.amountLeft,
                    zeroForOne,
                    cache.exactIn
                );
                if (cache.exactIn) {
                    amountIn = cache.amountLeft;
                    amountOut = ConstantProduct.getDx(cache.liquidity, cache.price, newPrice, false);
                } else {
                    amountIn = ConstantProduct.getDy(cache.liquidity, cache.price, newPrice, true);
                    amountOut = cache.amountLeft;
                }
                cache.amountLeft = 0;
                cache.cross = false;
                cache.price = uint160(newPrice);
            } else {
                if (cache.exactIn) {
                    amountIn = amountMax;
                    amountOut = ConstantProduct.getDx(cache.liquidity, cache.price, nextPrice, false);
                } else {
                    amountIn = ConstantProduct.getDy(cache.liquidity, cache.price, nextPrice, true);
                    amountOut = amountMax;
                }
                cache.amountLeft -= amountMax;
                if (nextPrice == cache.crossPrice) cache.cross = true;
                else cache.cross = false;
                cache.price = uint160(nextPrice);
            }
        }
        cache = FeeMath.calculate(cache, amountIn, amountOut, zeroForOne);
        return cache;
    }

    function _cross(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        PoolsharkStructs.SwapCache memory cache,
        PoolsharkStructs.SwapParams memory params
    ) internal returns (
        PoolsharkStructs.SwapCache memory
    ) {

        // crossing range ticks
        if ((cache.crossStatus & RANGE_TICK) > 0) {
            if (!params.zeroForOne || (cache.amountLeft > 0 && params.priceLimit < cache.crossPrice)) {
                PoolsharkStructs.RangeTick memory crossTick = ticks[cache.crossTick].range;
                crossTick.feeGrowthOutside0       = cache.state.pool.feeGrowthGlobal0 - crossTick.feeGrowthOutside0;
                crossTick.feeGrowthOutside1       = cache.state.pool.feeGrowthGlobal1 - crossTick.feeGrowthOutside1;
                crossTick.tickSecondsAccumOutside = cache.tickSecondsAccum - crossTick.tickSecondsAccumOutside;
                crossTick.secondsPerLiquidityAccumOutside = cache.secondsPerLiquidityAccum - crossTick.secondsPerLiquidityAccumOutside;
                ticks[cache.crossTick].range = crossTick;
                int128 liquidityDelta = crossTick.liquidityDelta;
                emit SyncRangeTick(
                    crossTick.feeGrowthOutside0,
                    crossTick.feeGrowthOutside1,
                    cache.crossTick
                );
                if (params.zeroForOne) {
                    unchecked {
                        if (liquidityDelta >= 0){
                            cache.state.pool.liquidity -= uint128(liquidityDelta);
                        } else {
                            cache.state.pool.liquidity += uint128(-liquidityDelta); 
                        }
                    }
                } else {
                    unchecked {
                        if (liquidityDelta >= 0) {
                            cache.state.pool.liquidity += uint128(liquidityDelta);
                        } else {
                            cache.state.pool.liquidity -= uint128(-liquidityDelta);
                        }
                    }
                }
            } else {
                // if zeroForOne && amountLeft == 0 skip crossing the tick
                /// @dev - this is so users can safely add liquidity with lower or upper at the pool price 
                cache.cross = false;
            }
            /// @dev - price and tickAtPrice updated at end of loop
        }
        // crossing limit tick
        if ((cache.crossStatus & LIMIT_TICK) > 0) {
            // cross limit tick
            EpochMap.set(cache.crossTick, !params.zeroForOne, cache.state.epoch, limitTickMap, cache.constants);
            int128 liquidityDelta = ticks[cache.crossTick].limit.liquidityDelta;

            if (liquidityDelta >= 0) {
                cache.liquidity += uint128(liquidityDelta);
                if (params.zeroForOne) cache.state.pool1.liquidity += uint128(liquidityDelta);
                else cache.state.pool0.liquidity += uint128(liquidityDelta);
            }
            else {
                cache.liquidity -= uint128(-liquidityDelta);
                if (params.zeroForOne) cache.state.pool1.liquidity -= uint128(-liquidityDelta);
                else cache.state.pool0.liquidity -= uint128(-liquidityDelta);
            }
            // zero out liquidityDelta and priceAt
            ticks[cache.crossTick].limit = PoolsharkStructs.LimitTick(0,0,0);
            LimitTicks.clear(ticks, cache.constants, limitTickMap, cache.crossTick);
            /// @dev - price and tickAtPrice updated at end of loop
        }
        if ((cache.crossStatus & LIMIT_POOL) > 0) {
            // add limit pool
            uint128 liquidityDelta = params.zeroForOne ? cache.state.pool1.liquidity
                                                    : cache.state.pool0.liquidity;

            if (liquidityDelta > 0) cache.liquidity += liquidityDelta;
        }
        if (cache.cross)
            cache = _iterate(ticks, rangeTickMap, limitTickMap, cache, params.zeroForOne, false);

        return cache;
    }

    function _pass(
        mapping(int24 => LimitPoolStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        PoolsharkStructs.SwapCache memory cache,
        PoolsharkStructs.QuoteParams memory params
    ) internal view returns (
        PoolsharkStructs.SwapCache memory
    ) {
        if ((cache.crossStatus & RANGE_TICK) > 0) {
            if (!params.zeroForOne || cache.amountLeft > 0) {
                int128 liquidityDelta = ticks[cache.crossTick].range.liquidityDelta;
                if (params.zeroForOne) {
                    unchecked {
                        if (liquidityDelta >= 0){
                            cache.state.pool.liquidity -= uint128(liquidityDelta);
                        } else {
                            cache.state.pool.liquidity += uint128(-liquidityDelta);
                        }
                    }
                } else {
                    unchecked {
                        if (liquidityDelta >= 0) {
                            cache.state.pool.liquidity += uint128(liquidityDelta);
                        } else {
                            cache.state.pool.liquidity -= uint128(-liquidityDelta);
                        }
                    }
                }
            } else {
                cache.cross = false;
            }
        }
        if ((cache.crossStatus & LIMIT_TICK) > 0) {
            // cross limit tick
            int128 liquidityDelta = ticks[cache.crossTick].limit.liquidityDelta;

            if (liquidityDelta > 0) {
                cache.liquidity += uint128(liquidityDelta);
                if (params.zeroForOne) cache.state.pool1.liquidity += uint128(liquidityDelta);
                else cache.state.pool0.liquidity += uint128(liquidityDelta);
            } 
            else {
                cache.liquidity -= uint128(-liquidityDelta);
                if (params.zeroForOne) {
                    cache.state.pool1.liquidity -= uint128(-liquidityDelta);
                } else {
                    cache.state.pool0.liquidity -= uint128(-liquidityDelta);
                }
            }
        }
        if ((cache.crossStatus & LIMIT_POOL) > 0) {
            // add limit pool
            uint128 liquidityDelta = params.zeroForOne ? cache.state.pool1.liquidity
                                                    : cache.state.pool0.liquidity;

            if (liquidityDelta > 0) {
                cache.liquidity += liquidityDelta;
            }
        }

        if (cache.cross)
            cache = _iterate(ticks, rangeTickMap, limitTickMap, cache, params.zeroForOne, false);

        return cache;
    }

    function _iterate(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage rangeTickMap,
        PoolsharkStructs.TickMap storage limitTickMap,
        PoolsharkStructs.SwapCache memory cache,
        bool zeroForOne,
        bool inclusive
    ) internal view returns (
        PoolsharkStructs.SwapCache memory 
    )    
    {
        if (zeroForOne) {
            if (cache.price > cache.state.pool1.price) {
                // load range pool
                cache.limitActive = false;
                cache.liquidity = cache.state.pool.liquidity;
                (cache.crossTick,) = TickMap.roundHalf(cache.crossTick, cache.constants, cache.price);
                // next range tick vs. limit pool price
                cache.crossTick = TickMap.previous(rangeTickMap, cache.crossTick, cache.constants.tickSpacing, inclusive);
                cache.crossPrice = ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants);
                if (cache.state.pool1.price >= cache.crossPrice) {
                    // cross into limit pool
                    cache.crossStatus = LIMIT_POOL;
                    if (cache.state.pool1.price == cache.crossPrice)
                        // also cross range tick
                        cache.crossStatus |= RANGE_TICK;
                    else {
                        cache.crossTick = cache.state.pool1.tickAtPrice;
                        cache.crossPrice = cache.state.pool1.price;
                    }
                }
                else {
                    // cross only range tick
                    cache.crossStatus = RANGE_TICK;
                }
            } else {
                // load range and limit pools
                cache.limitActive = true;
                cache.liquidity = cache.state.pool.liquidity + cache.state.pool1.liquidity;
                (cache.crossTick,) = TickMap.roundHalf(cache.crossTick, cache.constants, cache.price);
                int24 rangeTickAhead; int24 limitTickAhead;
                if (cache.crossStatus == LIMIT_POOL &&
                        cache.crossTick % cache.constants.tickSpacing != 0 &&
                        TickMap.get(limitTickMap, cache.crossTick, cache.constants.tickSpacing))
                {
                    limitTickAhead = cache.crossTick;
                    rangeTickAhead = cache.crossTick - cache.constants.tickSpacing / 2;
                } else {
                    rangeTickAhead = TickMap.previous(rangeTickMap, cache.crossTick, cache.constants.tickSpacing, inclusive);
                    limitTickAhead = TickMap.previous(limitTickMap, cache.crossTick, cache.constants.tickSpacing, inclusive);
                }
                // next range tick vs. next limit tick
                
                if (rangeTickAhead >= limitTickAhead) {
                    cache.crossTick = rangeTickAhead;
                    // cross range tick
                    cache.crossStatus = RANGE_TICK;
                    if (rangeTickAhead == limitTickAhead)
                        // also cross limit tick
                        cache.crossStatus |= LIMIT_TICK;
                    cache.crossPrice = ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants);
                } else {
                    // only cross limit tick
                    cache.crossTick = limitTickAhead;
                    cache.crossStatus = LIMIT_TICK;
                    cache.crossPrice = ticks[cache.crossTick].limit.priceAt == 0 ? ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants)
                                                                                 : ticks[cache.crossTick].limit.priceAt;
                }
            }
        } else {
            if (cache.price < cache.state.pool0.price) {
                // load range pool
                cache.limitActive = false;
                cache.liquidity = cache.state.pool.liquidity;
                (cache.crossTick,) = TickMap.roundHalf(cache.crossTick, cache.constants, cache.price);
                // next range tick vs. limit pool price
                cache.crossTick = TickMap.next(rangeTickMap, cache.crossTick, cache.constants.tickSpacing, inclusive);
                cache.crossPrice = ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants);
                if (cache.state.pool0.price <= cache.crossPrice) {
                    // cross into limit pool
                    cache.crossStatus = LIMIT_POOL;
                    if (cache.state.pool0.price == cache.crossPrice)
                        // also cross range tick
                        cache.crossStatus |= RANGE_TICK;
                    else {
                        cache.crossTick = cache.state.pool0.tickAtPrice;
                        cache.crossPrice = cache.state.pool0.price;
                    }
                }
                else {
                    // cross only range tick
                    cache.crossStatus = RANGE_TICK;
                }
            } else {
                // load range and limit pools
                cache.limitActive = true;
                cache.liquidity = cache.state.pool.liquidity + cache.state.pool0.liquidity;
                (cache.crossTick,) = TickMap.roundHalf(cache.crossTick, cache.constants, cache.price);
                // next range tick vs. next limit tick
                int24 rangeTickAhead; int24 limitTickAhead;
                if (cache.crossStatus == LIMIT_POOL &&
                        cache.crossTick % cache.constants.tickSpacing != 0 &&
                        TickMap.get(limitTickMap, cache.crossTick, cache.constants.tickSpacing))
                {
                    limitTickAhead = cache.crossTick;
                    rangeTickAhead = cache.crossTick + cache.constants.tickSpacing / 2;
                } else {
                    rangeTickAhead = TickMap.next(rangeTickMap, cache.crossTick, cache.constants.tickSpacing, inclusive);
                    limitTickAhead = TickMap.next(limitTickMap, cache.crossTick, cache.constants.tickSpacing, inclusive);
                }
                if (rangeTickAhead <= limitTickAhead) {
                    cache.crossTick = rangeTickAhead;
                    // cross range tick
                    cache.crossStatus |= RANGE_TICK;
                    if (rangeTickAhead == limitTickAhead)
                        // also cross limit tick
                        cache.crossStatus |= LIMIT_TICK;
                    cache.crossPrice = ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants);
                } else {
                    // only cross limit tick
                    cache.crossTick = limitTickAhead;
                    cache.crossStatus |= LIMIT_TICK;
                    cache.crossPrice = ticks[cache.crossTick].limit.priceAt == 0 ? ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants)
                                                                                 : ticks[cache.crossTick].limit.priceAt;
                }
            }
        }
        return cache;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../interfaces/structs/LimitPoolStructs.sol';
import '../limit/LimitPositions.sol';
import '../utils/SafeTransfers.sol';

library Collect {
    using SafeCast for int128;

    event CollectRange0(
        uint128 amount0
    );

    event CollectRange1(
        uint128 amount1
    );

    function range(
        PoolsharkStructs.LimitImmutables memory constants,
        address recipient,
        int128 amount0,
        int128 amount1
    ) internal {
        /// @dev - negative balances will revert
        if (amount0 > 0) {
            /// @dev - cast to ensure user doesn't owe the pool balance
            SafeTransfers.transferOut(recipient, constants.token0, amount0.toUint128());
            emit CollectRange0(amount0.toUint128());
        }
        if (amount1 > 0) {
            /// @dev - cast to ensure user doesn't owe the pool balance
            SafeTransfers.transferOut(recipient, constants.token1, amount1.toUint128());
            emit CollectRange1(amount1.toUint128());
        } 
    }

    function burnLimit(
        LimitPoolStructs.BurnLimitCache memory cache,
        PoolsharkStructs.BurnLimitParams memory params
    ) internal returns (
        LimitPoolStructs.BurnLimitCache memory
    )    
    {
        uint128 amount0 = params.zeroForOne ? cache.amountOut : cache.amountIn;
        uint128 amount1 = params.zeroForOne ? cache.amountIn : cache.amountOut;

        /// zero out balances and transfer out
        if (amount0 > 0) {
            cache.amountIn = 0;
            SafeTransfers.transferOut(params.to, cache.constants.token0, amount0);
        }
        if (amount1 > 0) {
            cache.amountOut = 0;
            SafeTransfers.transferOut(params.to, cache.constants.token1, amount1);
        }
        return cache;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "../math/OverflowMath.sol";
import '../../interfaces/IPositionERC1155.sol';
import "../../interfaces/range/IRangePoolFactory.sol";
import "../../interfaces/structs/RangePoolStructs.sol";

/// @notice Token library for ERC-1155 calls.
library PositionTokens {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function balanceOf(
        PoolsharkStructs.LimitImmutables memory constants,
        address owner,
        uint32 positionId
    ) internal view returns (
        uint256
    )
    {
        return IPositionERC1155(constants.poolToken).balanceOf(owner, positionId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        if((z = uint128(y)) != y) require(false, 'Uint256ToUint128:Overflow()');
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(int128 y) internal pure returns (uint128 z) {
        if(y < 0) require(false, 'Int128ToUint128:Underflow()');
        z = uint128(y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        if((z = uint160(y)) != y) require(false, 'Uint256ToUint160:Overflow()');
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        if((z = uint32(y)) != y) require(false, 'Uint256ToUint32:Overflow()');
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        if ((z = int128(y)) != y) require(false, 'Int256ToInt128:Overflow()');
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(uint128 y) internal pure returns (int128 z) {
        if(y > uint128(type(int128).max)) require(false, 'Uint128ToInt128:Overflow()');
        z = int128(y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        if(y > uint256(type(int256).max)) require(false, 'Uint256ToInt256:Overflow()');
        z = int256(y);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint256(int256 y) internal pure returns (uint256 z) {
        if(y < 0) require(false, 'Int256ToUint256:Underflow()');
        z = uint256(y);
    }

    /// @notice Cast a uint256 to a uint8, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint8(uint256 y) internal pure returns (uint8 z) {
        if((z = uint8(y)) != y) require(false, 'Uint256ToUint8:Overflow()');
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

library SafeTransfers {
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
    function transferIn(address token, uint256 amount) internal returns (uint256) {
        if (token == address(0)) {
            if (msg.value < amount) require(false, 'TransferFailed(msg.sender, address(this)');
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
        if (!success) require(false, 'TransferFailed(msg.sender, address(this)');

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
    function transferOut(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            if (address(this).balance < amount) require(false, 'TransferFailed(address(this), to');
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
        if (!success) require(false, 'TransferFailed(address(this), msg.sender');
    }

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
    function transferInto(address token, address sender, uint256 amount) internal returns (uint256) {
        if (token == address(0)) {
            if (msg.value < amount) require(false, 'TransferFailed(msg.sender, address(this)');
            return amount;
        }
        IERC20 erc20Token = IERC20(token);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        /// @dev - msg.sender here is the pool
        erc20Token.transferFrom(sender, msg.sender, amount);

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
        if (!success) require(false, 'TransferFailed(msg.sender, address(this)');

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
        for (uint i = 0; i < data.length;) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
            unchecked {
                ++i;
            }
        }
        return string(str);
    }
}