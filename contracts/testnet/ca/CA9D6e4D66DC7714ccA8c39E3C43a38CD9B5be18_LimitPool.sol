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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract LimitPoolFactoryStorage {
    mapping(bytes32 => address) public limitPools;
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

import { Clone } from "../../libraries/solady/Clone.sol";

contract LimitPoolImmutables is Clone {
    function owner() public pure returns (address) {
        return _getArgAddress(0);
    }

    function token0() public pure returns (address) {
        return _getArgAddress(20);
    }

    function token1() public pure returns (address) {
        return _getArgAddress(40);
    }

    function minPrice() public pure returns (uint160) {
        return _getArgUint160(60);
    }

    function maxPrice() public pure returns (uint160) {
        return _getArgUint160(80);
    }

    function tickSpacing() public pure returns (int16) {
        return int16(_getArgUint16(100));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../../interfaces/ILimitPoolStructs.sol';
import '../../interfaces/ILimitPoolFactory.sol';
import '../../utils/LimitPoolErrors.sol';

abstract contract LimitPoolStorage is ILimitPoolStructs, LimitPoolErrors {
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
pragma solidity 0.8.13;

import '../../interfaces/modules/sources/ITwapSource.sol';

interface CurveMathStructs {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract LimitPoolFactoryStructs {
    struct LimitPoolParams {
        address owner;
        address token0;
        address token1;
        uint160 minPrice;
        uint160 maxPrice;
        uint160 startPrice;
        int16   tickSpacing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity 0.8.13;

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

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

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
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @title Callback for swaps
/// @notice Any contract that calls the `swap` function must implement this interface.
interface IPoolsharkSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 either received by (positive) or sent from (negative) the user.
    /// @param amount1Delta The amount of token1 either received by (positive) or sent from (negative) the user.
    function poolsharkSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The address for which to look up the balance for
    /// @return amount of tokens held by the account
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './ILimitPoolStructs.sol';
import '../base/structs/LimitPoolFactoryStructs.sol';

interface ILimitPool is ILimitPoolStructs {
    function initialize(
        uint160 startPrice
    ) external;

    function mint(
        MintParams memory params
    ) external;

    function burn(
        BurnParams memory params
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
        uint256 priceAfter
    );

    function snapshot(
        SnapshotParams memory params
    ) external view returns (
        Position memory
    );

    function fees(
        uint16 syncFee,
        uint16 fillFee,
        bool setFees
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
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
import '../base/storage/LimitPoolFactoryStorage.sol';

abstract contract ILimitPoolFactory is LimitPoolFactoryStorage {
    function createLimitPool(
        bytes32 poolType,
        address tokenIn,
        address tokenOut,
        int16  tickSpacing,
        uint160 startPrice
    ) external virtual returns (address pool);

    function getLimitPool(
        bytes32 poolType,
        address tokenIn,
        address tokenOut,
        int16  tickSpacing
    ) external view virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @notice LimitPoolManager interface
interface ILimitPoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function implementations(
        bytes32 poolType
    ) external view returns (
        address
    );
    function tickSpacings(
        int16 tickSpacing
    ) external view returns (
        bool
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../libraries/math/ConstantProduct.sol';
import './modules/sources/ITwapSource.sol';

interface ILimitPoolStructs {
    struct GlobalState {
        uint8   unlocked;
    }

    struct PoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 liquidityGlobal;
        uint128 protocolFees;
        uint32  swapEpoch;
        uint16 protocolFee;
        int24 tickAtPrice;
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs; /// @dev - ticks to epochs
    }

    struct Tick {
        uint160 priceAt;
        int128 liquidityDelta;
    }

    struct Position {
        uint160 claimPriceLast; // highest price claimed at
        uint128 liquidity; // expected amount to be used not actual
        uint128 amountIn; // token amount already claimed; balance
        uint128 amountOut; // necessary for non-custodial positions
        uint32  epochLast;  // last epoch this position was updated at
    }

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    struct Immutables {
        address owner;
        address factory;
        ConstantProduct.PriceBounds bounds;
        address token0;
        address token1;
        int16 tickSpacing;
    }

    struct MintParams {
        address to;
        address refundTo;
        uint128 amount;
        uint96 mintPercent;
        int24 lower;
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
    }

    struct SwapParams {
        address to;
        uint160 priceLimit;
        uint128  amount;
        bool exactIn;
        bool zeroForOne;
        bytes callbackData;
    }

    struct QuoteParams {
        uint160 priceLimit;
        uint128 amount;
        bool exactIn;
        bool zeroForOne;
    }

    struct SnapshotParams {
        address owner;
        uint128 burnPercent;
        int24 lower;
        int24 upper;
        int24 claim;
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
        PoolState pool;
        PoolState swapPool;
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

    struct BurnCache {
        GlobalState state;
        Position position;
        Immutables constants;
        PoolState pool;
    }

    struct SwapCache {
        GlobalState state;
        Immutables constants;
        PoolState pool;
        uint256 price;
        uint256 liquidity;
        uint256 amountLeft;
        uint256 input;
        uint256 output;
        uint160 crossPrice;
        int24 crossTick;
        bool exactIn;
        bool cross;
    }

    struct UpdateCache {
        PoolState pool;
        Tick claimTick;
        Position position;
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        bool earlyReturn;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './IDyDxMath.sol';
import './ITickMath.sol';

interface ICurveMath is 
    IDyDxMath,
    ITickMath
{}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../../../interfaces/ILimitPoolStructs.sol';
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
pragma solidity 0.8.13;

import '../../../interfaces/ILimitPoolStructs.sol';
import '../../../base/structs/CurveMathStructs.sol';

interface ITickMath {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    function getPriceAtTick(
        int24 tick,
        ILimitPoolStructs.Immutables memory
    ) external pure returns (
        uint160 price
    );

    function getTickAtPrice(
        uint160 price,
        ILimitPoolStructs.Immutables memory
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
pragma solidity 0.8.13;

import '../../ILimitPoolStructs.sol';

interface ITwapSource {
    function initialize(
        ILimitPoolStructs.Immutables memory constants
    ) external returns (
        uint8 initializable,
        int24 startingTick
    );

    function calculateAverageTick(
        ILimitPoolStructs.Immutables memory constants
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
pragma solidity 0.8.13;

import '../interfaces/ILimitPoolStructs.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import './EpochMap.sol';
import './TickMap.sol';
import './utils/String.sol';
import './utils/SafeCast.sol';

library Claims {

    using SafeCast for uint256;

    function validate(
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.UpdateCache memory cache,
        ILimitPoolStructs.Immutables memory constants
    ) internal view returns (
        ILimitPoolStructs.UpdateParams memory,
        ILimitPoolStructs.UpdateCache memory
    ) {
        // validate position liquidity
        if (params.amount > cache.position.liquidity) require (false, 'NotEnoughPositionLiquidity()');
        if (cache.position.liquidity == 0) {
            require(false, 'NoPositionLiquidityFound()');
        }

        // if the position has not been crossed into at all
        else if (cache.position.claimPriceLast == 0 &&
                 (params.zeroForOne ? (params.claim == params.lower &&
                                        EpochMap.get(params.lower, tickMap, constants) <= cache.position.epochLast)
                                    : (params.claim == params.upper &&
                                        EpochMap.get(params.upper, tickMap, constants) <= cache.position.epochLast))
        ) {
            cache.earlyReturn = true;
            return (params, cache);
        }
        
        if (params.claim < params.lower || params.claim > params.upper) require (false, 'InvalidClaimTick()');

        uint32 claimTickEpoch = EpochMap.get(params.claim, tickMap, constants);

        if (params.zeroForOne){
            if (pool.price >= cache.priceClaim) {
                if (pool.price <= cache.priceUpper) {
                    cache.priceClaim = pool.price;
                    params.claim = TickMap.roundBack(pool.tickAtPrice, constants, params.zeroForOne, cache.priceClaim);
                    claimTickEpoch = pool.swapEpoch;
                } else {
                    cache.priceClaim = cache.priceUpper;
                    params.claim = params.upper;
                    cache.claimTick = ticks[params.upper];
                }
                claimTickEpoch = pool.swapEpoch;
            } else if (params.claim % constants.tickSpacing != 0) {
                if (cache.claimTick.priceAt == 0) {
                    require (false, 'WrongTickClaimedAt1()');
                }
                cache.priceClaim = cache.claimTick.priceAt;
            }
        } else {
            if (pool.price <= cache.priceClaim) {
                if (pool.price >= cache.priceLower) {
                    cache.priceClaim = pool.price;
                    params.claim = TickMap.roundBack(pool.tickAtPrice, constants, params.zeroForOne, cache.priceClaim);
                    claimTickEpoch = pool.swapEpoch;
                } else {
                    cache.priceClaim = cache.priceLower;
                    params.claim = params.lower;
                    cache.claimTick = ticks[params.upper];
                }
                claimTickEpoch = pool.swapEpoch;
            } else if (params.claim % constants.tickSpacing != 0) {
                if (cache.claimTick.priceAt == 0) {
                    require (false, 'WrongTickClaimedAt2()');
                }
                cache.priceClaim = cache.claimTick.priceAt;
            }
        }

        // validate claim tick
        if (params.claim == (params.zeroForOne ? params.upper : params.lower)) {
             if (claimTickEpoch <= cache.position.epochLast)
                require (false, 'WrongTickClaimedAt3()');
        } else if (params.amount > 0) {
            /// @dev - partway claim is valid as long as liquidity is not being removed
            int24 claimTickNext = params.zeroForOne
                ? TickMap.next(tickMap, params.claim, constants.tickSpacing, false)
                : TickMap.previous(tickMap, params.claim, constants.tickSpacing, false);
            // if we cleared the final tick of their position, this is the wrong claim tick
            if (params.zeroForOne ? claimTickNext > params.upper
                                  : claimTickNext < params.lower) {
                require (false, 'WrongTickClaimedAt4()');
            }
            // zero fill or partial fill
            /// @dev - if the next tick was crossed after position creation, the claim tick is incorrect
            /// @dev - we can cycle to find the right claim tick for the user
            uint32 claimTickNextAccumEpoch = EpochMap.get(claimTickNext, tickMap, constants);
            ///@dev - next swapEpoch should not be greater
            if (claimTickNextAccumEpoch > cache.position.epochLast) {
                require (false, 'WrongTickClaimedAt5()');
            }
        }
        if (params.claim != params.upper && params.claim != params.lower) {
            // check epochLast on claim tick
            if (claimTickEpoch <= cache.position.epochLast)
                require (false, 'WrongTickClaimedAt6()');
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
        }

        // early return if no update and amount burned is 0
        //TODO: after we've cycled through claim ticks and there are no position updates just revert - DONE
        if (params.zeroForOne ? params.claim == params.lower
                              : params.claim == params.upper) {
            if (params.amount == 0)
                require(false, 'NoPositionUpdates()');
        }

        return (params, cache);
    }

    function getDeltas(
        ILimitPoolStructs.UpdateCache memory cache,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.Immutables memory constants
    ) internal pure returns (
        ILimitPoolStructs.UpdateCache memory
    ) {
        // if half tick priceAt > 0 add amountOut to amountOutClaimed
        // set claimPriceLast if zero
        if (cache.position.claimPriceLast == 0) {
            cache.position.claimPriceLast = params.zeroForOne ? cache.priceLower
                                                              : cache.priceUpper;
        }
        ILimitPoolStructs.GetDeltasLocals memory locals;

        if (params.claim % constants.tickSpacing != 0)
        // this should pass price at the claim tick
            locals.previousFullTick = TickMap.roundBack(params.claim, constants, params.zeroForOne, ConstantProduct.getPriceAtTick(params.claim, constants));
        else
            locals.previousFullTick = params.claim;
        locals.pricePrevious = ConstantProduct.getPriceAtTick(locals.previousFullTick, constants);
        if (params.zeroForOne ? locals.previousFullTick > params.lower
                              : locals.previousFullTick < params.upper) {
            
            // claim amounts up to latest full tick crossed
            cache.position.amountIn += uint128(params.zeroForOne ? ConstantProduct.getDy(cache.position.liquidity, cache.priceLower, locals.pricePrevious, false)
                                                                 : ConstantProduct.getDx(cache.position.liquidity, locals.pricePrevious, cache.priceUpper, false));
            cache.position.claimPriceLast = locals.pricePrevious.toUint160();
        }
        if (params.amount > 0) {
           // if tick hasn't been set back calculate amountIn
            if (params.zeroForOne ? cache.priceClaim > locals.pricePrevious
                                  : cache.priceClaim < locals.pricePrevious) {
                // allow partial tick claim if removing liquidity
                cache.position.amountIn += uint128(params.zeroForOne ? ConstantProduct.getDy(params.amount, locals.pricePrevious, cache.priceClaim, false)
                                                                     : ConstantProduct.getDx(params.amount, cache.priceClaim, locals.pricePrevious, false));
            }
            // use priceClaim if tick hasn't been set back
            // else use claimPriceLast to calculate amountOut
            if (params.claim != (params.zeroForOne ? params.upper : params.lower)) {
                cache.position.amountOut += uint128(params.zeroForOne ? ConstantProduct.getDx(params.amount, cache.priceClaim, cache.priceUpper, false)
                                                                      : ConstantProduct.getDy(params.amount, cache.priceLower, cache.priceClaim, false));
            }
        }
        // take protocol fee if needed
        if (cache.pool.protocolFee > 0 && cache.position.amountIn > 0) {
            uint128 protocolFeeAmount = cache.position.amountIn * cache.pool.protocolFee / 1e6;
            cache.position.amountIn -= protocolFeeAmount;
            cache.pool.protocolFees += protocolFeeAmount;
        }

        return cache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './math/ConstantProduct.sol';
import '../interfaces/ILimitPoolStructs.sol';

library EpochMap {
    function set(
        int24  tick,
        uint256 epoch,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.Immutables memory constants
    ) internal {
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
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.Immutables memory constants
    ) internal {
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
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.Immutables memory constants
    ) internal view returns (
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
        ILimitPoolStructs.Immutables memory constants
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

    function _tick (
        uint256 tickIndex,
        ILimitPoolStructs.Immutables memory constants
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(_round(ConstantProduct.MAX_TICK, constants.tickSpacing) * 2) * 2) 
                require(false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * (constants.tickSpacing / 2) + _round(ConstantProduct.MIN_TICK, constants.tickSpacing / 2));
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './OverflowMath.sol';
import '../../interfaces/ILimitPoolStructs.sol';

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
        return _getDy(liquidity, priceLower, priceUpper, roundUp);
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        return _getDx(liquidity, priceLower, priceUpper, roundUp);
    }

    function _getDy(
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

    function _getDx(
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
            if (priceUpper == currentPrice) {
                liquidity = OverflowMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice == priceLower) {
                liquidity = OverflowMath.mulDiv(
                    dx,
                    OverflowMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                /// @dev - price should either be priceUpper or priceLower
                require (false, 'PriceOutsideBounds()');
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
            token1amount = uint128(_getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(_getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            token0amount = uint128(_getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(_getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
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
        ILimitPoolStructs.Immutables memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        ILimitPoolStructs.Immutables memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(maxTick(tickSpacing), constants);
    }

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure
    {
        if (lower <= minTick(tickSpacing)) require (false, 'LowerTickOutOfBounds()');
        if (upper >= maxTick(tickSpacing)) require (false, 'UpperTickOutOfBounds()');
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
        ILimitPoolStructs.Immutables memory constants
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
        ILimitPoolStructs.Immutables memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price >= constants.bounds.max)
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../interfaces/ILimitPoolStructs.sol';
import '../Positions.sol';
import '../utils/Collect.sol';

library BurnCall {
    event BurnLimit(
        address indexed to,
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityBurned,
        uint128 tokenInClaimed,
        uint128 tokenOutBurned
    );

    function perform(
        ILimitPoolStructs.BurnParams memory params,
        ILimitPoolStructs.BurnCache memory cache,
        ILimitPoolStructs.TickMap storage tickMap,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions
    ) external returns (ILimitPoolStructs.BurnCache memory) {
        if (params.lower >= params.upper) require (false, 'InvalidPositionBounds()');
        if (cache.position.epochLast == 0) require(false, 'PositionNotFound()');
        if (cache.position.claimPriceLast > 0
            || params.claim != (params.zeroForOne ? params.lower : params.upper)
            || cache.position.epochLast < (params.zeroForOne ? EpochMap.get(params.lower, tickMap, cache.constants)
                                                             : EpochMap.get(params.upper, tickMap, cache.constants)))
        {
            // position has been crossed into
            (
                cache.state,
                cache.pool,
                cache.position,
                params.claim
            ) = Positions.update(
                positions,
                ticks,
                tickMap,
                cache.state,
                cache.pool,
                ILimitPoolStructs.UpdateParams(
                    msg.sender,
                    params.to,
                    params.burnPercent,
                    params.lower,
                    params.upper,
                    params.claim,
                    params.zeroForOne
                ),
                cache.constants
            );
        } else {
            // position has not been crossed into
            (cache.pool, cache.position) = Positions.remove(
                positions,
                ticks,
                tickMap,
                cache.pool,
                ILimitPoolStructs.UpdateParams(
                    msg.sender,
                    params.to,
                    params.burnPercent,
                    params.lower,
                    params.upper,
                    params.zeroForOne ? params.lower : params.upper,
                    params.zeroForOne
                ),
                cache.constants
            );
        }
        cache = Collect.burn(
            cache,
            params
        );
        if ((params.zeroForOne ? params.claim != params.upper
                               : params.claim != params.lower))
            params.zeroForOne
                ? positions[msg.sender][params.claim][params.upper] = cache.position
                : positions[msg.sender][params.lower][params.claim] = cache.position;
        return cache;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../interfaces/ILimitPoolStructs.sol';
import '../Positions.sol';
import '../utils/Collect.sol';

library MintCall {
    event MintLimit(
        address indexed to,
        int24 lower,
        int24 upper,
        bool zeroForOne,
        uint32 epochLast,
        uint128 amountIn,
        uint128 amountFilled,
        uint128 liquidityMinted
    );

    function perform(
        ILimitPoolStructs.MintParams memory params,
        ILimitPoolStructs.MintCache memory cache,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState storage pool,
        ILimitPoolStructs.PoolState storage swapPool,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        mapping(int24 => ILimitPoolStructs.Tick) storage swapTicks,
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions
    ) external returns (ILimitPoolStructs.MintCache memory) {
        // bump swapPool in case user is trying to undercut
        // this avoids trimming positions unnecessarily
        if (cache.swapPool.liquidity == 0) {
            (cache, cache.swapPool) = Ticks.unlock(cache, cache.swapPool, swapTicks, tickMap, !params.zeroForOne);
        }

        // resize position if necessary
        (params, cache) = Positions.resize(
            params,
            cache,
            tickMap,
            swapTicks
        );
        // save state for safe reentrancy
        save(cache.swapPool, swapPool);
        // load position given params
        cache.position = positions[params.to][params.lower][params.upper];
        // transfer in token amount
        SafeTransfers.transferIn(
                                 params.zeroForOne ? cache.constants.token0 
                                                   : cache.constants.token1,
                                 params.amount + cache.swapCache.input
                                );
        // if swap output
        if (cache.swapCache.output > 0)
            SafeTransfers.transferOut(
                params.to,
                params.zeroForOne ? cache.constants.token1 
                                  : cache.constants.token0,
                cache.swapCache.output
            );
        // bump to the next tick if there is no liquidity
        if (cache.pool.liquidity == 0) {
            /// @dev - this makes sure to have liquidity unlocked if undercutting
            (cache, cache.pool) = Ticks.unlock(cache, cache.pool, ticks, tickMap, params.zeroForOne);
        }
        // mint position if amount is left
        if (params.amount > 0 && params.lower < params.upper) {
            /// @auditor not sure if the lower >= upper case is possible
            (cache.pool, cache.position) = Positions.add(
                cache,
                ticks,
                tickMap,
                params
            );
            if (params.zeroForOne) {
                uint160 priceLower = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
                if (priceLower <= cache.pool.price) {
                    // save liquidity if active
                    if (cache.pool.liquidity > 0) {
                        cache.pool = Ticks.insertSingle(params, ticks, tickMap, cache, cache.pool, cache.constants);
                    }
                    cache.pool.price = priceLower;
                    cache.pool.tickAtPrice = params.lower;
                    /// @auditor - double check liquidity is set correctly for this in insertSingle
                    cache.pool.liquidity += uint128(cache.liquidityMinted);
                    cache.pool.swapEpoch += 1;
                    cache.position.claimPriceLast = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
                    // set epoch on start tick to signify position being crossed into
                    /// @auditor - this is safe assuming we have swapped at least this far on the other side
                    EpochMap.set(params.lower, cache.pool.swapEpoch, tickMap, cache.constants);
                }
            } else {
                uint160 priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
                if (priceUpper >= cache.pool.price) {
                    if (cache.pool.liquidity > 0) {
                        cache.pool = Ticks.insertSingle(params, ticks, tickMap, cache, cache.pool, cache.constants);
                    }
                    cache.pool.price = priceUpper;
                    cache.pool.tickAtPrice = params.upper;
                    cache.pool.liquidity += uint128(cache.liquidityMinted);
                    cache.pool.swapEpoch += 1;
                    cache.position.claimPriceLast = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
                    // set epoch on start tick to signify position being crossed into
                    /// @auditor - this is safe assuming we have swapped at least this far on the other side
                    EpochMap.set(params.upper, cache.pool.swapEpoch, tickMap, cache.constants);
                }
            }
            // save lp side for safe reentrancy
            save(cache.pool, pool);

            // save position to storage
            positions[params.to][params.lower][params.upper] = cache.position;

            emit MintLimit(
                params.to,
                params.lower,
                params.upper,
                params.zeroForOne,
                cache.position.epochLast,
                uint128(params.amount + cache.swapCache.input),
                uint128(cache.swapCache.output),
                uint128(cache.liquidityMinted)
            );
        }
        return cache;
    }

    function save(
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.PoolState storage poolState
    ) internal {
        poolState.price = pool.price;
        poolState.liquidity = pool.liquidity;
        poolState.liquidityGlobal = pool.liquidityGlobal;
        poolState.swapEpoch = pool.swapEpoch;
        poolState.tickAtPrice = pool.tickAtPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../interfaces/ILimitPoolStructs.sol';
import '../Ticks.sol';

library QuoteCall {
    event Swap(
        address indexed recipient,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOut,
        uint160 price,
        uint128 liquidity,
        int24 tickAtPrice
    );

    function perform(
        ILimitPoolStructs.QuoteParams memory params,
        ILimitPoolStructs.SwapCache memory cache,
        ILimitPoolStructs.TickMap storage tickMap,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks
    ) external view returns (
        uint256,
        uint256,
        uint160
    ) {
        return Ticks.quote(
            ticks,
            tickMap,
            params,
            cache,
            cache.pool
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../interfaces/ILimitPoolStructs.sol';
import '../../interfaces/callbacks/IPoolsharkSwapCallback.sol';
import '../../interfaces/IERC20Minimal.sol';
import '../Positions.sol';
import '../Ticks.sol';
import '../utils/Collect.sol';
import '../utils/SafeTransfers.sol';

library SwapCall {
    event SwapPool0(
        address indexed recipient,
        uint128 amountIn,
        uint128 amountOut,
        uint160 priceLimit,
        uint160 newPrice
    );

    event SwapPool1(
        address indexed recipient,
        uint128 amountIn,
        uint128 amountOut,
        uint160 priceLimit,
        uint160 newPrice
    );

    function perform(
        ILimitPoolStructs.SwapParams memory params,
        ILimitPoolStructs.SwapCache memory cache,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState storage poolState,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks
    ) external returns (
        int256,
        int256
    ) {
        (cache.pool, cache) = Ticks.swap(
            ticks,
            tickMap,
            params,
            cache,
            cache.pool
        );
        save(cache.pool, poolState);
        // transfer output amount
        SafeTransfers.transferOut(
            params.to, 
            params.zeroForOne ? cache.constants.token1
                              : cache.constants.token0,
            cache.output
        );

        // check balance and execute callback
        uint256 balanceStart = balance(params, cache);
        IPoolsharkSwapCallback(msg.sender).poolsharkSwapCallback(
            params.zeroForOne ? -int256(cache.input) : int256(cache.output),
            params.zeroForOne ? int256(cache.output) : -int256(cache.input),
            params.callbackData
        );

        // check balance requirements after callback
        if (balance(params, cache) < balanceStart + cache.input)
            require(false, 'SwapInputAmountTooLow()');

        return (
            params.zeroForOne ? 
                (
                    -int256(cache.input),
                     int256(cache.output)
                )
              : (
                     int256(cache.output),
                    -int256(cache.input)
                )
        );
    }

    function save(
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.PoolState storage poolState
    ) internal {
        poolState.price = pool.price;
        poolState.liquidity = pool.liquidity;
        poolState.liquidityGlobal = pool.liquidityGlobal;
        poolState.swapEpoch = pool.swapEpoch;
        poolState.tickAtPrice = pool.tickAtPrice;
    }

    function balance(
        ILimitPoolStructs.SwapParams memory params,
        ILimitPoolStructs.SwapCache memory cache
    ) private view returns (uint256) {
        (
            bool success,
            bytes memory data
        ) = (params.zeroForOne ? cache.constants.token0
                               : cache.constants.token1)
                               .staticcall(
                                    abi.encodeWithSelector(
                                        IERC20Minimal.balanceOf.selector,
                                        address(this)
                                    )
                                );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import './Ticks.sol';
import '../interfaces/ILimitPoolStructs.sol';
import './math/OverflowMath.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import './Claims.sol';
import './EpochMap.sol';
import './utils/SafeCast.sol';
import './pool/SwapCall.sol';

/// @notice Position management library for ranged liquidity.
library Positions {
    using SafeCast for uint256;

    event BurnLimit(
        address indexed to,
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityBurned,
        uint128 tokenInClaimed,
        uint128 tokenOutBurned
    );

    function resize(
        ILimitPoolStructs.MintParams memory params,
        ILimitPoolStructs.MintCache memory cache,
        ILimitPoolStructs.TickMap storage tickMap,
        mapping(int24 => ILimitPoolStructs.Tick) storage swapTicks
    ) internal returns (
        ILimitPoolStructs.MintParams memory,
        ILimitPoolStructs.MintCache memory
    )
    {
        ConstantProduct.checkTicks(params.lower, params.upper, cache.constants.tickSpacing);

        cache.priceLower = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
        cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);

        // cannot mint empty position
        if (params.amount == 0) require (false, 'PositionAmountZero()');

        cache.mintSize = uint256(params.mintPercent) * uint256(params.amount) / 1e28;
        // calculate L constant
        cache.liquidityMinted = ConstantProduct.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            params.zeroForOne ? cache.priceLower : cache.priceUpper,
            params.zeroForOne ? 0 : uint256(params.amount),
            params.zeroForOne ? uint256(params.amount) : 0
        );

        if (cache.liquidityMinted == 0) require (false, 'PositionLiquidityZero()');
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

        ILimitPoolStructs.SwapCache memory swapCache;
        swapCache.pool = cache.swapPool;
        swapCache.state = cache.state;
        swapCache.constants = cache.constants;

        // sync up pool epochs for position epoch stamping
        if (cache.pool.swapEpoch < cache.swapPool.swapEpoch)
            cache.pool.swapEpoch = cache.swapPool.swapEpoch;
        else if (cache.swapPool.swapEpoch < cache.pool.swapEpoch)
            cache.swapPool.swapEpoch = cache.pool.swapEpoch;

        // only swap if priceLimit is beyond current pool price
        if (params.zeroForOne ? cache.priceLimit < cache.swapPool.price
                              : cache.priceLimit > cache.swapPool.price) {
            // swap and save the pool state
            (cache.swapPool, swapCache) = Ticks.swap(
                swapTicks,
                tickMap,
                ILimitPoolStructs.SwapParams({
                    to: params.to,
                    priceLimit: cache.priceLimit.toUint160(),
                    amount: params.amount,
                    //TODO: handle exactOut
                    exactIn: true,
                    zeroForOne: params.zeroForOne,
                    callbackData: abi.encodePacked(bytes1(0x0))
                }),
                swapCache,
                cache.swapPool
            );
            // subtract from remaining input amount
            params.amount -= uint128(swapCache.input);
        }

        if (params.amount < cache.mintSize) params.amount = 0;
        // move start tick based on amount filled in swap
        if ((params.amount > 0 && swapCache.input > 0) ||
            (params.zeroForOne ? cache.priceLower < cache.swapPool.price
                               : cache.priceUpper > cache.swapPool.price)
        ) {
            // move the tick limit based on pool.tickAtPrice
            if (params.zeroForOne ? cache.priceLower < cache.swapPool.price
                                  : cache.priceUpper > cache.swapPool.price) {
                cache.tickLimit = cache.swapPool.tickAtPrice;
            }
            // round ahead tickLimit to avoid crossing epochs
            cache.tickLimit = TickMap.roundAhead(cache.tickLimit, cache.constants, params.zeroForOne, cache.swapPool.price);
            if (params.zeroForOne) {
                if (cache.priceLower < cache.swapPool.price) {
                    // if rounding goes past limit trim position
                    /// @dev - if swap didn't go to limit user would be 100% filled
                    params.lower = cache.tickLimit;
                    cache.priceLower = ConstantProduct.getPriceAtTick(params.lower, cache.constants);
                }
                if (params.lower == params.upper && params.upper < ConstantProduct.maxTick(cache.constants.tickSpacing)) {
                    params.upper += cache.constants.tickSpacing;
                }
                cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
            } else {
                if (cache.priceUpper > cache.swapPool.price) {
                    // if rounding goes past limit trim position
                    params.upper = cache.tickLimit;
                    cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, cache.constants);
                }
                if (params.upper == params.lower && params.lower > ConstantProduct.minTick(cache.constants.tickSpacing)) {
                    params.lower -= cache.constants.tickSpacing;
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
            cache.pool.swapEpoch += 1;
        }
        // save swapCache
        cache.swapCache = swapCache;

        return (
            params,
            cache
        );
    }

    function add(
        ILimitPoolStructs.MintCache memory cache,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.MintParams memory params
    ) internal returns (
        ILimitPoolStructs.PoolState memory,
        ILimitPoolStructs.Position memory
    ) {
        if (cache.liquidityMinted == 0) return (cache.pool, cache.position);

        if (cache.position.liquidity == 0) {
            cache.position.epochLast = cache.pool.swapEpoch;
        } else {
            // safety check in case we somehow get here
            if (
                params.zeroForOne
                    ? EpochMap.get(params.lower, tickMap, cache.constants)
                            > cache.position.epochLast
                    : EpochMap.get(params.upper, tickMap, cache.constants)
                            > cache.position.epochLast
            ) {
                require (false, string.concat('UpdatePositionFirstAt(', String.from(params.lower), ', ', String.from(params.upper), ')'));
            }
            /// @auditor maybe this shouldn't be a revert but rather just not mint the position?
        }
        
        // add liquidity to ticks
        Ticks.insert(
            ticks,
            tickMap,
            cache,
            params
        );

        // update liquidity global
        cache.pool.liquidityGlobal += uint128(cache.liquidityMinted);

        cache.position.liquidity += uint128(cache.liquidityMinted);

        return (cache.pool, cache.position);
    }

    function remove(
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.Immutables memory constants
    ) internal returns (
        ILimitPoolStructs.PoolState memory,
        ILimitPoolStructs.Position memory
    ) {
        // initialize cache
        ILimitPoolStructs.UpdateCache memory cache;
        cache.position = positions[msg.sender][params.lower][params.upper];
        cache.priceLower = ConstantProduct.getPriceAtTick(params.lower, constants);
        cache.priceUpper = ConstantProduct.getPriceAtTick(params.upper, constants);
        cache.removeLower = true; cache.removeUpper = true;

        // convert percentage to liquidity amount
        params.amount = _convert(cache.position.liquidity, params.amount);

        // early return if no liquidity to remove
        if (params.amount == 0) return (pool, cache.position);
        if (params.amount > cache.position.liquidity) {
            require (false, 'NotEnoughPositionLiquidity()');
        }
        /// @dev - validate position has not been crossed into
        if (params.zeroForOne) {
            if (EpochMap.get(params.lower, tickMap, constants)
                        > cache.position.epochLast) {
                int24 nextTick = TickMap.next(tickMap, params.lower, constants.tickSpacing, false);
                if (pool.price > cache.priceLower ||
                    EpochMap.get(nextTick, tickMap, constants)
                        > cache.position.epochLast) {
                    require (false, 'WrongTickClaimedAt7()');            
                }
                if (pool.price == cache.priceLower) {
                    pool.liquidity -= params.amount;
                }
            }
            // if pool price is further along
            // OR next tick has a greater epoch
        } else {
            if (EpochMap.get(params.upper, tickMap, constants)
                        > cache.position.epochLast) {
                int24 previousTick = TickMap.previous(tickMap, params.upper, constants.tickSpacing, false);
                if (pool.price < cache.priceUpper ||
                    EpochMap.get(previousTick, tickMap, constants)
                        > cache.position.epochLast) {
                    require (false, 'WrongTickClaimedAt8()');            
                }
                if (pool.price == cache.priceUpper) {
                    pool.liquidity -= params.amount;
                }
            }
        }

        Ticks.remove(
            ticks,
            tickMap,
            cache,
            params,
            constants
        );

        // update liquidity global
        pool.liquidityGlobal -= params.amount;

        cache.position.amountOut += uint128(
            params.zeroForOne
                ? ConstantProduct.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                : ConstantProduct.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
        );

        cache.position.liquidity -= uint128(params.amount);
        positions[msg.sender][params.lower][params.upper] = cache.position;

        if (params.amount > 0) {
            emit BurnLimit(
                    params.to,
                    params.lower,
                    params.upper,
                    params.zeroForOne ? params.lower : params.upper,
                    params.zeroForOne,
                    params.amount,
                    0,
                    cache.position.amountOut
            );
        }
        return (pool, cache.position);
    }

    function update(
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.GlobalState memory state,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.Immutables memory constants
    ) internal returns (
        ILimitPoolStructs.GlobalState memory,
        ILimitPoolStructs.PoolState memory,
        ILimitPoolStructs.Position memory,
        int24
    )
    {
        ILimitPoolStructs.UpdateCache memory cache;
        (
            params,
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
            return (state, pool, cache.position, params.claim);

        // update pool liquidity
        if (cache.priceClaim == pool.price && params.amount > 0) {
            // handle pool.price at edge of range
            if (params.zeroForOne ? cache.priceClaim < cache.priceUpper
                                  : cache.priceClaim > cache.priceLower)
                pool.liquidity -= params.amount;
        }


        if (params.amount > 0) {
            if (params.claim == (params.zeroForOne ? params.upper : params.lower)) {
                // only remove once if final tick of position
                cache.removeLower = false;
                cache.removeUpper = false;
            } else {
                params.zeroForOne ? cache.removeUpper = true 
                                  : cache.removeLower = true;
            }
            if (params.zeroForOne) {
                if (params.claim == params.lower && 
                    cache.pool.price < cache.priceLower
                ) {
                    cache.removeLower = true;
                } else if (params.claim % constants.tickSpacing != 0 && 
                    cache.pool.price < cache.priceClaim)
                    cache.removeLower = true;
            } else {
                if (params.claim == params.upper &&
                    cache.pool.price > cache.priceUpper
                )
                    cache.removeUpper = true;
                else if (params.claim % constants.tickSpacing != 0 &&
                            cache.pool.price > cache.priceClaim)
                    cache.removeUpper = true;
            }
            Ticks.remove(
                ticks,
                tickMap,
                cache,
                params,
                constants
            );
            // update position liquidity
            cache.position.liquidity -= uint128(params.amount);
            // update global liquidity
            pool.liquidityGlobal -= params.amount;
        }
        if (params.zeroForOne ? params.claim == params.upper
                              : params.claim == params.lower) {
            pool.liquidityGlobal -= cache.position.liquidity;
            cache.position.liquidity = 0;
        }
        // clear out old position
        if (params.zeroForOne ? params.claim != params.lower 
                              : params.claim != params.upper) {
            
            /// @dev - this also clears out position end claims
            if (params.zeroForOne ? params.claim == params.lower 
                                  : params.claim == params.upper) {
                // subtract remaining position liquidity out from global
                pool.liquidityGlobal -= cache.position.liquidity;
            }
            delete positions[msg.sender][params.lower][params.upper];
        }
        // clear position if empty
        if (cache.position.liquidity == 0) {
            cache.position.epochLast = 0;
            cache.position.claimPriceLast = 0;
        }

        // round back claim tick for storage
        if (params.claim % constants.tickSpacing != 0)
            params.claim = TickMap.roundBack(params.claim, constants, params.zeroForOne, cache.priceClaim);
        
        emit BurnLimit(
            params.to,
            params.lower,
            params.upper,
            params.claim,
            params.zeroForOne,
            params.amount,
            cache.position.amountIn,
            cache.position.amountOut
        );
        // return cached position in memory and transfer out
        return (state, pool, cache.position, params.claim);
    }

    function snapshot(
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.GlobalState memory state,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.Immutables memory constants
    ) external view returns (
        ILimitPoolStructs.Position memory
    ) {
        ILimitPoolStructs.UpdateCache memory cache;
        (
            params,
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
            return (cache.position);

        if (params.amount > 0) {
            cache.position.liquidity -= uint128(params.amount);
        }
        
        // clear position values if empty
        if (cache.position.liquidity == 0) {
            cache.position.epochLast = 0;
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
        if (percent > 1e38) percent = 1e38;
        if (liquidity == 0 && percent > 0) require (false, 'NotEnoughPositionLiquidity()');
        return uint128(uint256(liquidity) * uint256(percent) / 1e38);
    }

    function _deltas(
        mapping(address => mapping(int24 => mapping(int24 => ILimitPoolStructs.Position)))
            storage positions,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.GlobalState memory state,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.Immutables memory constants
    ) internal view returns (
        ILimitPoolStructs.UpdateParams memory,
        ILimitPoolStructs.UpdateCache memory,
        ILimitPoolStructs.GlobalState memory
    ) {
        ILimitPoolStructs.UpdateCache memory cache = ILimitPoolStructs.UpdateCache({
            position: positions[params.owner][params.lower][params.upper],
            pool: pool,
            priceLower: ConstantProduct.getPriceAtTick(params.lower, constants),
            priceClaim: ConstantProduct.getPriceAtTick(params.claim, constants),
            priceUpper: ConstantProduct.getPriceAtTick(params.upper, constants),
            claimTick: ticks[params.claim],
            earlyReturn: false,
            removeLower: false,
            removeUpper: false
        });

        params.amount = _convert(cache.position.liquidity, params.amount);

        // check claim is valid
        (params, cache) = Claims.validate(
            positions,
            ticks,
            tickMap,
            cache.pool,
            params,
            cache,
            constants
        );
        if (cache.earlyReturn) {
            return (params, cache, state);
        }
        // calculate position deltas
        cache = Claims.getDeltas(cache, params, constants);

        return (params, cache, state);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Class with helper read functions for clone with immutable args.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Clone.sol)
/// @author Adapted from clones with immutable args by zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
abstract contract Clone {
    /// @dev Reads an immutable arg with type bytes.
    function _getArgBytes(uint256 argOffset, uint256 length)
        internal
        pure
        returns (bytes memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), length)
            let o := add(add(arg, 0x20), length)
            mstore(o, 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Reads an immutable arg with type address.
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(96, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads a uint256 array stored in the immutable args.
    function _getArgUint256Array(uint256 argOffset, uint256 length)
        internal
        pure
        returns (uint256[] memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            mstore(0x40, add(add(arg, 0x20), shl(5, length))) // Allocate the memory.
        }
    }

    /// @dev Reads a bytes32 array stored in the immutable args.
    function _getArgBytes32Array(uint256 argOffset, uint256 length)
        internal
        pure
        returns (bytes32[] memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            mstore(0x40, add(add(arg, 0x20), shl(5, length))) // Allocate the memory.
        }
    }

    /// @dev Reads an immutable arg with type bytes32.
    function _getArgBytes32(uint256 argOffset) internal pure returns (bytes32 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @dev Reads an immutable arg with type uint256.
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @dev Reads an immutable arg with type uint248.
    function _getArgUint248(uint256 argOffset) internal pure returns (uint248 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(8, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint240.
    function _getArgUint240(uint256 argOffset) internal pure returns (uint240 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(16, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint232.
    function _getArgUint232(uint256 argOffset) internal pure returns (uint232 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(24, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint224.
    function _getArgUint224(uint256 argOffset) internal pure returns (uint224 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0x20, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint216.
    function _getArgUint216(uint256 argOffset) internal pure returns (uint216 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(40, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint208.
    function _getArgUint208(uint256 argOffset) internal pure returns (uint208 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(48, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint200.
    function _getArgUint200(uint256 argOffset) internal pure returns (uint200 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(56, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint192.
    function _getArgUint192(uint256 argOffset) internal pure returns (uint192 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(64, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint184.
    function _getArgUint184(uint256 argOffset) internal pure returns (uint184 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(72, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint176.
    function _getArgUint176(uint256 argOffset) internal pure returns (uint176 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(80, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint168.
    function _getArgUint168(uint256 argOffset) internal pure returns (uint168 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(88, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint160.
    function _getArgUint160(uint256 argOffset) internal pure returns (uint160 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(96, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint152.
    function _getArgUint152(uint256 argOffset) internal pure returns (uint152 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(104, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint144.
    function _getArgUint144(uint256 argOffset) internal pure returns (uint144 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(112, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint136.
    function _getArgUint136(uint256 argOffset) internal pure returns (uint136 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(120, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint128.
    function _getArgUint128(uint256 argOffset) internal pure returns (uint128 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(128, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint120.
    function _getArgUint120(uint256 argOffset) internal pure returns (uint120 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(136, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint112.
    function _getArgUint112(uint256 argOffset) internal pure returns (uint112 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(144, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint104.
    function _getArgUint104(uint256 argOffset) internal pure returns (uint104 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(152, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint96.
    function _getArgUint96(uint256 argOffset) internal pure returns (uint96 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(160, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint88.
    function _getArgUint88(uint256 argOffset) internal pure returns (uint88 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(168, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint80.
    function _getArgUint80(uint256 argOffset) internal pure returns (uint80 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(176, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint72.
    function _getArgUint72(uint256 argOffset) internal pure returns (uint72 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(184, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint64.
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(192, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint56.
    function _getArgUint56(uint256 argOffset) internal pure returns (uint56 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(200, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint48.
    function _getArgUint48(uint256 argOffset) internal pure returns (uint48 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(208, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint40.
    function _getArgUint40(uint256 argOffset) internal pure returns (uint40 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(216, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint32.
    function _getArgUint32(uint256 argOffset) internal pure returns (uint32 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(224, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint24.
    function _getArgUint24(uint256 argOffset) internal pure returns (uint24 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(232, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint16.
    function _getArgUint16(uint256 argOffset) internal pure returns (uint16 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(240, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint8.
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(248, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata.
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        /// @solidity memory-safe-assembly
        assembly {
            offset := sub(calldatasize(), shr(240, calldataload(sub(calldatasize(), 2))))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or the caller.
    error SaltDoesNotStartWithCaller();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a deterministic clone of `implementation`,
    /// using immutable  arguments encoded in `data`, with `salt`.
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(0, sub(data, 0x4c), add(extraLength, 0x6c), salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation, bytes memory data)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Compute and store the bytecode hash.
            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Reverts if `salt` does not start with either the zero address or the caller.
    function checkStartsWithCaller(bytes32 salt) internal view {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                // Store the function selector of `SaltDoesNotStartWithCaller()`.
                mstore(0x00, 0x2f634836)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './math/ConstantProduct.sol';
import '../interfaces/ILimitPool.sol';
import '../interfaces/ILimitPoolStructs.sol';

library TickMap {

    error TickIndexOverflow();
    error TickIndexUnderflow();
    error TickIndexBadSpacing();
    error BlockIndexOverflow();

    function get(
        ILimitPoolStructs.TickMap storage tickMap,
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
        ILimitPoolStructs.TickMap storage tickMap,
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
        ILimitPoolStructs.TickMap storage tickMap,
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
        ILimitPoolStructs.TickMap storage tickMap,
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
        ILimitPoolStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing,
        bool inclusive
    ) internal view returns (
        int24 nextTick
    ) {
        unchecked {
            /// @dev - handles tickAtPrice being past tickSpacing / 2
            if (inclusive && tick % tickSpacing != 0) {
                tick -= 1;
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
        ILimitPoolStructs.Immutables memory constants,
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
        ILimitPoolStructs.Immutables memory constants,
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
        ILimitPoolStructs.Immutables memory constants,
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

import '../interfaces/ILimitPoolStructs.sol';
import '../interfaces/ILimitPoolFactory.sol';
import '../base/structs/LimitPoolFactoryStructs.sol';
import '../interfaces/ILimitPool.sol';
import './math/ConstantProduct.sol';
import './Positions.sol';
import './math/OverflowMath.sol';
import './TickMap.sol';
import './EpochMap.sol';
import './utils/SafeCast.sol';

/// @notice Tick management library
library Ticks {
    error LiquidityOverflow();
    error LiquidityUnderflow();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBounds();

    using SafeCast for uint256;

    event Initialize(
        int24 minTick,
        int24 maxTick,
        uint160 startPrice
    );

    event Swap(
        address indexed recipient,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOut,
        uint160 price,
        uint128 liquidity,
        int24 tickAtPrice
    );

    uint256 internal constant Q96 = 0x1000000000000000000000000;

    function initialize(
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState storage pool0,
        ILimitPoolStructs.PoolState storage pool1,
        ILimitPoolStructs.GlobalState memory state,
        ILimitPoolStructs.Immutables memory constants,
        uint160 startPrice
    ) external returns (
        ILimitPoolStructs.GlobalState memory
    ) {
        // state should only be initialized once
        if (pool0.price > 0) require (false, 'PoolAlreadyInitialized()');

        // initialize epoch
        pool0.swapEpoch = 1;
        pool1.swapEpoch = 1;

        // check price bounds
        if (startPrice < constants.bounds.min || startPrice >= constants.bounds.max) require(false, 'StartPriceInvalid()');

        // initialize ticks
        TickMap.set(tickMap, ConstantProduct.minTick(constants.tickSpacing), constants.tickSpacing);
        TickMap.set(tickMap, ConstantProduct.maxTick(constants.tickSpacing), constants.tickSpacing);

        // initialize price
        pool0.price = startPrice;
        pool1.price = startPrice;

        int24 startTick = ConstantProduct.getTickAtPrice(startPrice, constants);
        pool0.tickAtPrice = startTick;
        pool1.tickAtPrice = startTick;

        // emit event
        emit Initialize(
            ConstantProduct.minTick(constants.tickSpacing),
            ConstantProduct.maxTick(constants.tickSpacing),
            pool0.price
        );

        return state;
    }

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

    function swap(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.SwapParams memory params,
        ILimitPoolStructs.SwapCache memory cache,
        ILimitPoolStructs.PoolState memory pool
    ) internal returns (
            ILimitPoolStructs.PoolState memory,
            ILimitPoolStructs.SwapCache memory
        )
    {
        (cache.crossTick,) = TickMap.roundHalf(pool.tickAtPrice, cache.constants, pool.price);
        cache = ILimitPoolStructs.SwapCache({
            state: cache.state,
            constants: cache.constants,
            pool: cache.pool,
            price: pool.price,
            liquidity: pool.liquidity,
            cross: true,
            crossTick: params.zeroForOne ? TickMap.previous(tickMap, cache.crossTick, cache.constants.tickSpacing, true) 
                                         : TickMap.next(tickMap, cache.crossTick, cache.constants.tickSpacing, true),
            crossPrice: 0,
            input:  0,
            output: 0,
            exactIn: params.exactIn,
            amountLeft: params.amount
        });

        // increment swap epoch
        cache.pool.swapEpoch += 1;
        // grab latest sample and store in cache for _cross
        while (cache.cross) {
            cache.crossPrice = ticks[cache.crossTick].priceAt == 0 ? 
                                    ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants)
                                  : ticks[cache.crossTick].priceAt;
            // handle price being at cross tick
            if (params.zeroForOne && pool.price == cache.crossPrice) {
                cache.crossTick = TickMap.previous(tickMap, pool.tickAtPrice, cache.constants.tickSpacing, false);
                cache.crossPrice = ticks[cache.crossTick].priceAt == 0 ? 
                                    ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants)
                                  : ticks[cache.crossTick].priceAt;

            }
            (pool, cache) = _quoteSingle(pool, cache, params.priceLimit, params.zeroForOne);
            if (cache.cross) {
                (pool, cache) = _cross(
                    ticks,
                    tickMap,
                    pool,
                    cache,
                    params.zeroForOne
                );
            }
        }
        pool.price = cache.price.toUint160();
        pool.liquidity = cache.liquidity.toUint128();

        if (cache.price != cache.crossPrice) {
            pool.tickAtPrice = ConstantProduct.getTickAtPrice(pool.price, cache.constants);
        } else {
            pool.tickAtPrice = cache.crossTick;
        }
        emit Swap(
            params.to,
            params.zeroForOne,
            cache.input,
            cache.output, /// @dev - subgraph will do math to compute fee amount
            pool.price,
            pool.liquidity,
            pool.tickAtPrice
        );
        return (pool, cache);
    }

    function quote(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.QuoteParams memory params,
        ILimitPoolStructs.SwapCache memory cache,
        ILimitPoolStructs.PoolState memory pool
    ) internal view returns (
        uint256,
        uint256,
        uint160
    ) {
        (cache.crossTick,) = TickMap.roundHalf(pool.tickAtPrice, cache.constants, pool.price);
        cache = ILimitPoolStructs.SwapCache({
            state: cache.state,
            constants: cache.constants,
            pool: cache.pool,
            price: pool.price,
            liquidity: pool.liquidity,
            cross: true,
            crossTick: params.zeroForOne ? TickMap.previous(tickMap, cache.crossTick, cache.constants.tickSpacing, true) 
                                         : TickMap.next(tickMap, cache.crossTick, cache.constants.tickSpacing, true),
            crossPrice: 0,
            input:  0,
            output: 0,
            exactIn: params.exactIn,
            amountLeft: params.amount
        });
        while (cache.cross) {
            cache.crossPrice = ticks[cache.crossTick].priceAt == 0 ? 
                                 ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants)
                               : ticks[cache.crossTick].priceAt;
            // handle price being at cross tick
            if (params.zeroForOne && pool.price == cache.crossPrice) {
                cache.crossTick = TickMap.previous(tickMap, pool.tickAtPrice, cache.constants.tickSpacing, false);
                cache.crossPrice = ticks[cache.crossTick].priceAt == 0 ? 
                                    ConstantProduct.getPriceAtTick(cache.crossTick, cache.constants)
                                  : ticks[cache.crossTick].priceAt;
            }
            (pool, cache) = _quoteSingle(pool, cache, params.priceLimit, params.zeroForOne);
            if (cache.cross) {
                (pool, cache) = _pass(
                    ticks,
                    tickMap,
                    pool,
                    cache,
                    params.zeroForOne
                );
            }
        }
        return (
            cache.input,
            cache.output,
            uint160(cache.price)
        );
    }

    function _quoteSingle(
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.SwapCache memory cache,
        uint160 priceLimit,
        bool zeroForOne
    ) internal pure returns (
        ILimitPoolStructs.PoolState memory,
        ILimitPoolStructs.SwapCache memory
    ) {
        if ((zeroForOne ? priceLimit >= cache.price
                        : priceLimit <= cache.price) ||
            (zeroForOne && cache.price == cache.constants.bounds.min) ||
            (!zeroForOne && cache.price == cache.constants.bounds.max) ||
            cache.amountLeft == 0)
        {
            cache.cross = false;
            return (pool, cache);
        }
        uint256 nextPrice = cache.crossPrice;
        uint256 amountOut;
        if (zeroForOne) {
            // Trading token 0 (x) for token 1 (y).
            // price  is decreasing.
            if (nextPrice < priceLimit) {
                nextPrice = priceLimit;
            }
            uint256 amountMax = cache.exactIn ? ConstantProduct.getDx(cache.liquidity, nextPrice, cache.price, true)
                                              : ConstantProduct.getDy(cache.liquidity, nextPrice, cache.price, false);
            if (cache.amountLeft < amountMax) {
                // We can swap within the current range.
                uint256 liquidityPadded = uint256(cache.liquidity) << 96;
                // calculate price after swap
                uint256 newPrice;
                if (cache.exactIn) {
                    newPrice = OverflowMath.mulDivRoundingUp(
                        liquidityPadded,
                        cache.price,
                        liquidityPadded + uint256(cache.price) * uint256(cache.amountLeft)
                    );
                    amountOut = ConstantProduct.getDy(cache.liquidity, newPrice, uint256(cache.price), false);
                    cache.input += cache.amountLeft;
                } else {
                    newPrice = cache.price - 
                        OverflowMath.divRoundingUp(cache.amountLeft << 96, cache.liquidity);
                    amountOut = cache.amountLeft;
                    cache.input += ConstantProduct.getDx(cache.liquidity, newPrice, uint256(cache.price), true);
                }
                cache.amountLeft = 0;
                cache.cross = false;
                cache.price = uint160(newPrice);
            } else {
                if (cache.exactIn) {
                    amountOut = ConstantProduct.getDy(cache.liquidity, nextPrice, cache.price, false);
                    cache.input += amountMax;
                } else {
                    amountOut = amountMax;
                    cache.input += ConstantProduct.getDx(cache.liquidity, nextPrice, cache.price, true);
                }
                cache.amountLeft -= amountMax;
                if (nextPrice == cache.crossPrice) { cache.cross = true; }
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
                uint256 newPrice;
                if (cache.exactIn) {
                    newPrice = cache.price +
                        OverflowMath.mulDiv(cache.amountLeft, Q96, cache.liquidity);
                    amountOut = ConstantProduct.getDx(cache.liquidity, cache.price, newPrice, false);
                    cache.input += cache.amountLeft;
                } else {
                    uint256 liquidityPadded = uint256(cache.liquidity) << 96;
                    newPrice = OverflowMath.mulDivRoundingUp(
                        liquidityPadded, 
                        cache.price,
                        liquidityPadded - uint256(cache.price) * cache.amountLeft
                    );
                    amountOut = cache.amountLeft;
                    cache.input += ConstantProduct.getDy(cache.liquidity, cache.price, newPrice, true);
                }
                cache.amountLeft = 0;
                cache.cross = false;
                cache.price = uint160(newPrice);
            } else {
                if (cache.exactIn) {
                    amountOut = ConstantProduct.getDx(cache.liquidity, cache.price, nextPrice, false);
                    cache.input += amountMax;
                } else {
                    amountOut = amountMax;
                    cache.input += ConstantProduct.getDy(cache.liquidity, cache.price, nextPrice, true);
                }
                cache.amountLeft -= amountMax;
                if (nextPrice == cache.crossPrice) { cache.cross = true; }
                else cache.cross = false;
                cache.price = uint160(nextPrice);
            }
        }
        cache.output += amountOut;
        return (pool, cache);
    }

    function unlock(
        ILimitPoolStructs.MintCache memory cache,
        ILimitPoolStructs.PoolState memory pool,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        bool zeroForOne
    ) internal returns (
        ILimitPoolStructs.MintCache memory,
        ILimitPoolStructs.PoolState memory
    )
    {
        if (pool.liquidity > 0) return (cache, pool);

        (int24 startTick,) = TickMap.roundHalf(pool.tickAtPrice, cache.constants, pool.price);

        if (zeroForOne) {
            pool.tickAtPrice = TickMap.next(tickMap, startTick, cache.constants.tickSpacing, true);
            if (pool.tickAtPrice < ConstantProduct.maxTick(cache.constants.tickSpacing)) {
                EpochMap.set(pool.tickAtPrice, pool.swapEpoch, tickMap, cache.constants);
            }
        } else {
            /// @dev - roundedUp true since liquidity could be equal to the current pool tickAtPrice
            pool.tickAtPrice = TickMap.previous(tickMap, startTick, cache.constants.tickSpacing, true);
            if (pool.tickAtPrice > ConstantProduct.minTick(cache.constants.tickSpacing)) {
                EpochMap.set(pool.tickAtPrice, pool.swapEpoch, tickMap, cache.constants);
            }
        }

        // increment pool liquidity
        pool.liquidity += uint128(ticks[pool.tickAtPrice].liquidityDelta);
        int24 tickToClear = pool.tickAtPrice;
        uint160 tickPriceAt = ticks[pool.tickAtPrice].priceAt;

        if (tickPriceAt == 0) {
            // if full tick crossed
            pool.price = ConstantProduct.getPriceAtTick(pool.tickAtPrice, cache.constants);
        } else {
            // if half tick crossed
            pool.price = tickPriceAt;
            pool.tickAtPrice = ConstantProduct.getTickAtPrice(tickPriceAt, cache.constants);
        }

        // zero out tick
        ticks[tickToClear].liquidityDelta = 0;
        Ticks.clear(ticks, cache.constants, tickMap, tickToClear);

        return (cache, pool);
    }

    function _cross(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.SwapCache memory cache,
        bool zeroForOne
    ) internal returns (
        ILimitPoolStructs.PoolState memory,
        ILimitPoolStructs.SwapCache memory
    ) {
        EpochMap.set(cache.crossTick, cache.pool.swapEpoch, tickMap, cache.constants);
        int128 liquidityDelta = ticks[cache.crossTick].liquidityDelta;

        if (liquidityDelta > 0) cache.liquidity += uint128(liquidityDelta);
        else cache.liquidity -= uint128(-liquidityDelta);
        pool.tickAtPrice = cache.crossTick;

        // zero out liquidityDelta and priceAt
        ticks[cache.crossTick] = ILimitPoolStructs.Tick(0,0);
        clear(ticks, cache.constants, tickMap, cache.crossTick);
        if (zeroForOne) {
            cache.crossTick = TickMap.previous(tickMap, cache.crossTick, cache.constants.tickSpacing, false);
        } else {
            cache.crossTick = TickMap.next(tickMap, cache.crossTick, cache.constants.tickSpacing, false);
        }
        return (pool, cache);
    }

    function _pass(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.SwapCache memory cache,
        bool zeroForOne
    ) internal view returns (
        ILimitPoolStructs.PoolState memory,
        ILimitPoolStructs.SwapCache memory
    ) {
        int128 liquidityDelta = ticks[cache.crossTick].liquidityDelta;
        if (liquidityDelta > 0) cache.liquidity += uint128(liquidityDelta);
        else cache.liquidity -= uint128(-liquidityDelta);
        if (zeroForOne) {
            cache.crossTick = TickMap.previous(tickMap, cache.crossTick, cache.constants.tickSpacing, false);
        } else {
            cache.crossTick = TickMap.next(tickMap, cache.crossTick, cache.constants.tickSpacing, false);
        }
        return (pool, cache);
    }
    
    function insert(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.MintCache memory cache,
        ILimitPoolStructs.MintParams memory params
    ) internal {
        /// @auditor - validation of ticks is in Positions.validate
        if (cache.liquidityMinted > (uint128(type(int128).max) - cache.pool.liquidityGlobal) )
            require (false, 'LiquidityOverflow()');

        int256 liquidityMinted = int256(cache.liquidityMinted);

        // check if adding liquidity necessary
        if (!params.zeroForOne || cache.priceLower > cache.pool.price) {
            // sets bit in map
            TickMap.set(tickMap, params.lower, cache.constants.tickSpacing);
            ILimitPoolStructs.Tick memory tickLower = ticks[params.lower];
            if (params.zeroForOne) {
                tickLower.liquidityDelta += int128(liquidityMinted);
            } else {
                tickLower.liquidityDelta -= int128(liquidityMinted);
            }
            ticks[params.lower] = tickLower;
        }

        if (params.zeroForOne || cache.priceUpper < cache.pool.price) {
            TickMap.set(tickMap, params.upper, cache.constants.tickSpacing);
            ILimitPoolStructs.Tick memory tickUpper = ticks[params.upper];
            if (params.zeroForOne) {
                tickUpper.liquidityDelta -= int128(liquidityMinted);
            } else {
                tickUpper.liquidityDelta += int128(liquidityMinted);
            }
            ticks[params.upper] = tickUpper;
        }
    }

    function insertSingle(
        ILimitPoolStructs.MintParams memory params,
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.MintCache memory cache,
        ILimitPoolStructs.PoolState memory pool,
        ILimitPoolStructs.Immutables memory constants
    ) internal returns (
        ILimitPoolStructs.PoolState memory
    ){
        /// @auditor - would be smart to protect against the case of epochs crossing
        (
            int24 tickToSave,
            uint160 roundedPrice
        ) = TickMap.roundHalf(pool.tickAtPrice, constants, pool.price);

        // update tick to save
        ILimitPoolStructs.Tick memory tick = ticks[tickToSave];
        /// @auditor - tick.priceAt will be zero for tick % tickSpacing == 0
        if (tick.priceAt == 0) {
            if (pool.price != (params.zeroForOne ? cache.priceLower : cache.priceUpper)) {
                TickMap.set(tickMap, tickToSave, constants.tickSpacing);
            }
            EpochMap.set(tickToSave, pool.swapEpoch, tickMap, constants);
        }
        // skip if we are at the nearest full tick
        if(pool.price != roundedPrice) {
            // if empty just save the pool price
            if (tick.priceAt == 0) {
                tick.priceAt = pool.price;
            }
            else {
                // we need to blend the two partial fills into a single tick
                ILimitPoolStructs.InsertSingleLocals memory locals;
                if (params.zeroForOne) {
                    // 0 -> 1 positions price moves up so nextFullTick is greater
                    locals.previousFullTick = tickToSave - constants.tickSpacing / 2;
                    locals.pricePrevious = ConstantProduct.getPriceAtTick(locals.previousFullTick, constants);
                    // calculate amountOut filled across both partial fills
                    locals.amountOutExact = ConstantProduct.getDy(pool.liquidity, locals.pricePrevious, pool.price, false);
                    locals.amountOutExact += ConstantProduct.getDy(uint128(tick.liquidityDelta), locals.pricePrevious, tick.priceAt, false);
                    uint128 combinedLiquidity = pool.liquidity + uint128(tick.liquidityDelta);
                    /// @auditor - the opposing amount calculated is off by 1/100 millionth
                    ///            (i.e. since we're using exactOut we lose precision on exactInput amount)
                    ///            the expected dy to the next tick is either exact or slightly more
                    ///            the expected dx to the next tick is 1/100 millionth less after the blend
                    // advance price past closest full tick using amountOut filled
                    tick.priceAt = ConstantProduct.getNewPrice(uint256(locals.pricePrevious), combinedLiquidity, locals.amountOutExact, false, true).toUint160();
                    // dx to the next tick is less than before the tick blend
                    EpochMap.set(tickToSave, pool.swapEpoch, tickMap, constants);
                } else {
                    // 0 -> 1 positions price moves up so nextFullTick is lesser
                    locals.previousFullTick = tickToSave + constants.tickSpacing / 2;
                    locals.pricePrevious = ConstantProduct.getPriceAtTick(locals.previousFullTick, constants);
                    // calculate amountOut filled across both partial fills
                    locals.amountOutExact = ConstantProduct.getDx(pool.liquidity, pool.price, locals.pricePrevious, false);
                    locals.amountOutExact += ConstantProduct.getDx(uint128(tick.liquidityDelta), tick.priceAt, locals.pricePrevious, false);
                    // add current pool liquidity to partial tick
                    uint128 combinedLiquidity = pool.liquidity + uint128(tick.liquidityDelta);
                    // advance price past closest full tick using amountOut filled
                    tick.priceAt = ConstantProduct.getNewPrice(uint256(locals.pricePrevious), combinedLiquidity, locals.amountOutExact, true, true).toUint160();
                    // mark epoch for second partial fill positions
                    EpochMap.set(tickToSave, pool.swapEpoch, tickMap, constants);
                }
            }
        }
        // invariant => if we save liquidity to tick clear pool liquidity
        if ((tickToSave != (params.zeroForOne ? params.lower : params.upper))) {
            tick.liquidityDelta += int128(pool.liquidity);
            pool.liquidity = 0;
        }
        ticks[tickToSave] = tick;
        return pool;
    }

    function remove(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.TickMap storage tickMap,
        ILimitPoolStructs.UpdateCache memory cache,
        ILimitPoolStructs.UpdateParams memory params,
        ILimitPoolStructs.Immutables memory constants
    ) internal {
        // set ticks based on claim and zeroForOne
        int24 lower = params.zeroForOne ? params.claim : params.lower;
        int24 upper = params.zeroForOne ? params.upper : params.claim;
        {    
            ILimitPoolStructs.Tick memory tickLower = ticks[lower];
            
            if (cache.removeLower) {
                if (params.zeroForOne) {
                    tickLower.liquidityDelta -= int128(params.amount);
                } else {
                    tickLower.liquidityDelta += int128(params.amount);
                }
                ticks[lower] = tickLower;
            }
            clear(ticks, constants, tickMap, lower);
        }
        {
            ILimitPoolStructs.Tick memory tickUpper = ticks[upper];
            if (cache.removeUpper) {
                if (params.zeroForOne) {
                    tickUpper.liquidityDelta += int128(params.amount);
                } else {
                    tickUpper.liquidityDelta -= int128(params.amount);
                }
                ticks[upper] = tickUpper;
            }
            clear(ticks, constants, tickMap, upper);
        }
    }

    function clear(
        mapping(int24 => ILimitPoolStructs.Tick) storage ticks,
        ILimitPoolStructs.Immutables memory constants,
        ILimitPoolStructs.TickMap storage tickMap,
        int24 tickToClear
    ) internal {
        if (_empty(ticks[tickToClear])) {
            if (tickToClear != ConstantProduct.maxTick(constants.tickSpacing) &&
                tickToClear != ConstantProduct.minTick(constants.tickSpacing)) {
                ticks[tickToClear] = ILimitPoolStructs.Tick(0,0);
                TickMap.unset(tickMap, tickToClear, constants.tickSpacing);
            }
        }
    }

    function _empty(
        ILimitPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.liquidityDelta != 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../../interfaces/ILimitPoolStructs.sol';
import '../Positions.sol';
import '../utils/SafeTransfers.sol';

library Collect {
    function burn(
        ILimitPoolStructs.BurnCache memory cache,
        ILimitPoolStructs.BurnParams memory params
    ) internal returns (
        ILimitPoolStructs.BurnCache memory
    )    
    {
        // store amounts for transferOut
        uint128 amountIn  = cache.position.amountIn;
        uint128 amountOut = cache.position.amountOut;

        /// zero out balances and transfer out
        if (amountIn > 0) {
            cache.position.amountIn = 0;
            SafeTransfers.transferOut(params.to, params.zeroForOne ? cache.constants.token1 : cache.constants.token0, amountIn);
        }
        if (amountOut > 0) {
            cache.position.amountOut = 0;
            SafeTransfers.transferOut(params.to, params.zeroForOne ? cache.constants.token0 : cache.constants.token1, amountOut);
        }

        return cache;
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
        require((z = uint128(y)) == y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './interfaces/ILimitPool.sol';
import './interfaces/ILimitPoolManager.sol';
import './base/storage/LimitPoolStorage.sol';
import './base/storage/LimitPoolImmutables.sol';
import './base/structs/LimitPoolFactoryStructs.sol';
import './utils/LimitPoolErrors.sol';
import './libraries/pool/SwapCall.sol';
import './libraries/pool/QuoteCall.sol';
import './libraries/pool/MintCall.sol';
import './libraries/pool/BurnCall.sol';
import './libraries/math/ConstantProduct.sol';
import './libraries/solady/LibClone.sol';
import './external/openzeppelin/security/ReentrancyGuard.sol';


/// @notice Poolshark Cover Pool Implementation
contract LimitPool is
    ILimitPool,
    LimitPoolStorage,
    LimitPoolImmutables,
    LimitPoolFactoryStructs,
    ReentrancyGuard
{

    modifier ownerOnly() {
        _onlyOwner();
        _;
    }

    modifier factoryOnly() {
        _onlyFactory();
        _;
    }

    modifier canoncialOnly() {
        _onlyCanoncialClones();
        _;
    }

    address public immutable original;
    address public immutable factory;

    constructor(
        address factory_
    ) {
        original = address(this);
        factory = factory_;
    }

    function initialize(
        uint160 startPrice
    ) external override 
        nonReentrant
        factoryOnly
        canoncialOnly
    {
        // initialize state
        globalState = Ticks.initialize(
            tickMap,
            pool0,
            pool1,
            globalState,
            immutables(),
            startPrice
        );
    }

    // limitSwap
    function mint(
        MintParams memory params
    ) external override
        nonReentrant
        canoncialOnly
    {
        MintCache memory cache;
        {
            cache.state = globalState;
            cache.constants = immutables();
            cache.pool = params.zeroForOne ? pool0 : pool1;
            cache.swapPool = params.zeroForOne ? pool1 : pool0;
        }
        cache = MintCall.perform(
            params,
            cache,
            tickMap,
            params.zeroForOne ? pool0 : pool1,
            params.zeroForOne ? pool1 : pool0,
            params.zeroForOne ? ticks0 : ticks1,
            params.zeroForOne ? ticks1 : ticks0,
            params.zeroForOne ? positions0 : positions1
        );
        globalState = cache.state;
    }

    function burn(
        BurnParams memory params
    ) external override 
        nonReentrant
        canoncialOnly
    {
        if (params.to == address(0)) revert CollectToZeroAddress();
        BurnCache memory cache = BurnCache({
            state: globalState,
            position: params.zeroForOne ? positions0[msg.sender][params.lower][params.upper]
                                        : positions1[msg.sender][params.lower][params.upper],
            constants: immutables(),
            pool: params.zeroForOne ? pool0 : pool1
        });
        cache = BurnCall.perform(
            params, 
            cache, 
            tickMap,
            params.zeroForOne ? ticks0 : ticks1,
            params.zeroForOne ? positions0 : positions1
        );
        if (params.zeroForOne) {
            pool0 = cache.pool;
        } else {
            pool1 = cache.pool;
        }
        globalState = cache.state;
    }

    function swap(
        SwapParams memory params
    ) public override
        nonReentrant
        canoncialOnly
    returns (
        int256,
        int256
    ) 
    {
        SwapCache memory cache;
        cache.pool = params.zeroForOne ? pool1 : pool0;
        cache.state = globalState;
        cache.constants = immutables();

        return SwapCall.perform(
            params,
            cache,
            tickMap,
            params.zeroForOne ? pool1 : pool0,
            params.zeroForOne ? ticks1 : ticks0
        );
    }

    function quote(
        QuoteParams memory params
    ) external view override canoncialOnly returns (
        uint256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    ) {
        SwapCache memory cache;
        cache.pool = params.zeroForOne ? pool1 : pool0;
        cache.state = globalState;
        cache.constants = immutables();
        return QuoteCall.perform(
            params,
            cache,
            tickMap,
            params.zeroForOne ? ticks1 : ticks0
        );
    }

    function snapshot(
       SnapshotParams memory params 
    ) external view override canoncialOnly returns (
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
            immutables()
        );
    }

    function fees(
        uint16 protocolFee0,
        uint16 protocolFee1,
        bool setFees
    ) external override
        ownerOnly
        nonReentrant
        canoncialOnly 
    returns (
        uint128 token0Fees,
        uint128 token1Fees
    ) {
        if (setFees) {
            if (protocolFee0 > 10000 || protocolFee1 > 10000)
                revert ProtocolFeeCeilingExceeded();
            pool1.protocolFee = protocolFee0;
            pool0.protocolFee = protocolFee1;
        }
        address feeTo = ILimitPoolManager(owner()).feeTo();
        token0Fees = pool1.protocolFees;
        token1Fees = pool0.protocolFees;
        pool0.protocolFees = 0;
        pool1.protocolFees = 0;
        if (token0Fees > 0)
            SafeTransfers.transferOut(feeTo, token0(), token0Fees);
        if (token1Fees > 0)
            SafeTransfers.transferOut(feeTo, token1(), token1Fees);
    }

    function immutables() public view returns (
        Immutables memory
    ) {
        return Immutables(
            owner(),
            factory,
            ConstantProduct.PriceBounds(minPrice(), maxPrice()),
            token0(),
            token1(),
            tickSpacing()
        );
    }

    function priceBounds(int16 tickSpacing) external pure returns (uint160, uint160) {
        return ConstantProduct.priceBounds(tickSpacing);
    }

    function _onlyOwner() private view {
        if (msg.sender != owner()) revert OwnerOnly();
    }

    function _onlyCanoncialClones() private view {
        // compute pool key
        bytes32 key = keccak256(abi.encode(original, token0(), token1(), tickSpacing()));
        
        // computer canonical pool address
        address predictedAddress = LibClone.predictDeterministicAddress(
            original,
            abi.encodePacked(
                owner(),
                token0(),
                token1(),
                minPrice(),
                maxPrice(),
                tickSpacing()
            ),
            key,
            factory
        );
        // only allow delegateCall from canonical clones
        if (address(this) != predictedAddress) require(false, 'NoDelegateCall()');
    }

    function _onlyFactory() private view {
        if (msg.sender != factory) revert FactoryOnly();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract LimitPoolErrors {
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
    error ProtocolFeeCeilingExceeded();
    error Overflow();
    error PoolAlreadyInitialized();
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

abstract contract LimitPoolFactoryErrors {
    error OwnerOnly();
    error InvalidTokenAddress();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
    error TickSpacingNotSupported();
    error PoolTypeNotSupported();
}

abstract contract CoverTransferErrors {
    error TransferFailed(address from, address dest);
}