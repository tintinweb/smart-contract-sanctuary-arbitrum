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

// SPDX-License-Identifier: SSPL-1.0
pragma solidity ^0.8.18;

import '../structs/PoolsharkStructs.sol';

interface ITwapSource {
    function initialize(PoolsharkStructs.CoverImmutables memory constants)
        external
        returns (uint8 initializable, int24 startingTick);

    function calculateAverageTick(
        PoolsharkStructs.CoverImmutables memory constants,
        int24 latestTick
    ) external view returns (int24 averageTick);

    function getPool(
        address tokenA,
        address tokenB,
        uint16 feeTier
    ) external view returns (address pool);

    function feeTierTickSpacing(uint16 feeTier)
        external
        view
        returns (int24 tickSpacing);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: SSPL-1.0

pragma solidity 0.8.18;

import '../interfaces/structs/PoolsharkStructs.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

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

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances);

    function totalSupply() external view returns (uint256);

    function isApprovedForAll(address owner, address spender)
        external
        view
        returns (bool);

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

    function withdrawEth(
        address recipient,
        PoolsharkStructs.LimitImmutables memory constants
    ) external;
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

/// @notice LimitPoolManager interface
interface ILimitPoolManager {
    function owner() external view returns (address);

    function feeTo() external view returns (address);

    function feeDeltaConsts(address pool) external view returns (uint16);

    function poolTypes(uint16 poolType)
        external
        view
        returns (address poolImpl, address tokenImpl);

    function feeTiers(uint16 swapFee) external view returns (int16 tickSpacing);
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import '../cover/ITwapSource.sol';

interface PoolsharkStructs {
    /**
     * @custom:struct LimitPoolParams
     */
    struct LimitPoolParams {
        /**
         * @custom:field tokenIn
         * @notice Address for the first token in the pair
         */
        address tokenIn;
        /**
         * @custom:field tokenOut
         * @notice Address for the second token in the pair
         */
        address tokenOut;
        /**
         * @custom:field startPrice
         * @notice Q64.96 formatted sqrt price to start the pool at
         */
        uint160 startPrice;
        /**
         * @custom:field swapFee
         * @notice The base swap fee for the pool; 1000 = 0.1% fee
         */
        uint16 swapFee;
        /**
         * @custom:field poolTypeId
         * @notice The pool type id for which to clone the implementation for
         */
        uint16 poolTypeId;
    }

    /**
     * @custom:struct MintRangeParams
     */
    struct MintRangeParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the minted position
         */
        address to;
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
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;
        /**
         * @custom:field amount0
         * @notice token0 amount to be deposited into the minted position
         */
        uint128 amount0;
        /**
         * @custom:field amount1
         * @notice token1 amount to be deposited into the minted position
         */
        uint128 amount1;
        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    struct BurnRangeParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the burned liquidity
         */
        address to;
        /**
         * @custom:field positionId
         * @notice id of previous position minted
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
    }

    /**
     * @custom:struct MintLimitParams
     */
    struct MintLimitParams {
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
         * @custom:field mintPercent
         * @notice The percent of `amount` below which a LimitPosition will not be minted
         * @notice 1e26 = 1%
         * @notice 5e25 = 0.5%
         */
        uint96 mintPercent;
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
     * @custom:struct BurnLimitParams
     */
    struct BurnLimitParams {
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
         * @notice if `zeroForOne` is true, claim tick progresses from lower => upper
         * @notice if `zeroForOne` is false, claim tick progresses from upper => lower
         */
        int24 claim;
        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order
         */
        bool zeroForOne;
    }

    struct SwapParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the swap token output
         */
        address to;
        /**
         * @custom:field priceLimit
         * @notice The Q64.96 formatted sqrt price to stop swapping at
         * @notice zeroForOne (i.e. token0 => token1 swap) moves price lower
         * @notice !zeroForOne (i.e. token1 => token0 swap) moves price higher
         */
        uint160 priceLimit;
        /**
         * @custom:field amount
         * @notice The maximum tokenIn to be spent (exactIn)
         * @notice OR tokenOut amount to be received (!exactIn)
         */
        uint128 amount;
        /**
         * @custom:field exactIn
         * @notice True if `amount` is in tokenIn; False if `amount` is in tokenOut
         */
        bool exactIn;
        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 => token1
         * @notice False if swapping token1 => token0
         */
        bool zeroForOne;
        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    struct QuoteParams {
        /**
         * @custom:field priceLimit
         * @notice The Q64.96 formatted sqrt price to stop swapping at
         * @notice zeroForOne (i.e. token0 => token1 swap) moves price lower
         * @notice !zeroForOne (i.e. token1 => token0 swap) moves price higher
         */
        uint160 priceLimit;
        /**
         * @custom:field amount
         * @notice The maximum tokenIn to be spent (exactIn)
         * @notice OR tokenOut amount to be received (!exactIn)
         */
        uint128 amount;
        /**
         * @custom:field exactIn
         * @notice True if `amount` is in tokenIn; False if `amount` is in tokenOut
         */
        bool exactIn;
        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 => token1
         * @notice False if swapping token1 => token0
         */
        bool zeroForOne;
    }

    struct SnapshotLimitParams {
        /**
         * @custom:field owner
         * @notice The owner address of the Limit Position
         */
        address owner;
        /**
         * @custom:field burnPercent
         * @notice The % of liquidity to burn
         * @notice 1e38 = 100%
         */
        uint128 burnPercent;
        /**
         * @custom:field positionId
         * @notice The position id for the LimitPosition
         */
        uint32 positionId;
        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from lower => upper
         * @notice if `zeroForOne` is false, claim tick progresses from upper => lower
         */
        int24 claim;
        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 => token1
         * @notice False if swapping token1 => token0
         */
        bool zeroForOne;
    }

    struct FeesParams {
        /**
         * @custom:field protocolSwapFee0
         * @notice The protocol fee taken on all token0 fees
         * @notice 1e4 = 100%
         */
        uint16 protocolSwapFee0;
        /**
         * @custom:field protocolSwapFee1
         * @notice The protocol fee taken on all token1 fees
         * @notice 1e4 = 100%
         */
        uint16 protocolSwapFee1;
        /**
         * @custom:field protocolFillFee0
         * @notice The protocol fee taken on all token0 LimitPosition fills
         * @notice 1e2 = 1%
         */
        uint16 protocolFillFee0;
        /**
         * @custom:field protocolFillFee1
         * @notice The protocol fee taken on all token1 LimitPosition fills
         * @notice 1e2 = 1%
         */
        uint16 protocolFillFee1;
        /**
         * @custom:field setFeesFlags
         * @notice The flags for which protocol fees will be set
         * @notice - PROTOCOL_SWAP_FEE_0 = 2**0;
         * @notice - PROTOCOL_SWAP_FEE_1 = 2**1;
         * @notice - PROTOCOL_FILL_FEE_0 = 2**2;
         * @notice - PROTOCOL_FILL_FEE_1 = 2**3;
         */
        uint8 setFeesFlags;
    }

    struct GlobalState {
        RangePoolState pool;
        LimitPoolState pool0;
        LimitPoolState pool1;
        uint128 liquidityGlobal;
        uint32 positionIdNext;
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
        SampleState samples;
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        uint160 secondsPerLiquidityAccum;
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        int56 tickSecondsAccum;
        int24 tickAtPrice;
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
        uint32 blockTimestamp;
        int56 tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct SampleState {
        uint16 index;
        uint16 count;
        uint16 countMax;
    }

    struct StakeRangeParams {
        address to;
        address pool;
        uint32 positionId;
    }

    struct UnstakeRangeParams {
        address to;
        address pool;
        uint32 positionId;
    }

    struct StakeFinParams {
        address to;
        uint128 amount;
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
        int16 minPositionWidth;
        int16 tickSpread;
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
        uint256 blocks; /// @dev - sets of words
        mapping(uint256 => uint256) words; /// @dev - blocks to words
        mapping(uint256 => uint256) ticks; /// @dev - words to ticks
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
        int56 tickSecondsAccum;
        int56 tickSecondsAccumBase;
        int24 crossTick;
        uint8 crossStatus;
        bool limitActive;
        bool exactIn;
        bool cross;
    }

    enum CrossStatus {
        RANGE,
        LIMIT,
        BOTH
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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import '../../interfaces/IPositionERC1155.sol';
import '../../interfaces/structs/PoolsharkStructs.sol';
import '../../interfaces/limit/ILimitPoolManager.sol';
import '../utils/SafeTransfers.sol';

library FeesCall {
    // protocol fee ceilings
    uint16 public constant MAX_PROTOCOL_SWAP_FEE = 1e4; // max protocol swap fee of 100%
    uint16 public constant MAX_PROTOCOL_FILL_FEE = 1e2; // max protocol fill fee of 1%

    // protocol fee flags
    uint8 internal constant PROTOCOL_SWAP_FEE_0 = 2**0;
    uint8 internal constant PROTOCOL_SWAP_FEE_1 = 2**1;
    uint8 internal constant PROTOCOL_FILL_FEE_0 = 2**2;
    uint8 internal constant PROTOCOL_FILL_FEE_1 = 2**3;

    // eth address for safe withdrawal
    address public constant ethAddress = address(0);

    function perform(
        PoolsharkStructs.GlobalState storage globalState,
        PoolsharkStructs.FeesParams memory params,
        PoolsharkStructs.LimitImmutables memory constants
    ) external returns (uint128 token0Fees, uint128 token1Fees) {
        // swap fee token0
        if ((params.setFeesFlags & PROTOCOL_SWAP_FEE_0) > 0) {
            if (params.protocolSwapFee0 > MAX_PROTOCOL_SWAP_FEE)
                require(false, 'ProtocolSwapFeeCeilingExceeded()');
            globalState.pool.protocolSwapFee0 = params.protocolSwapFee0;
        }
        // swap fee token1
        if ((params.setFeesFlags & PROTOCOL_SWAP_FEE_1) > 0) {
            if (params.protocolSwapFee1 > MAX_PROTOCOL_SWAP_FEE)
                require(false, 'ProtocolSwapFeeCeilingExceeded()');
            globalState.pool.protocolSwapFee1 = params.protocolSwapFee1;
        }
        // fill fee token0
        if ((params.setFeesFlags & PROTOCOL_FILL_FEE_0) > 0) {
            if (params.protocolFillFee0 > MAX_PROTOCOL_FILL_FEE)
                require(false, 'ProtocolFillFeeCeilingExceeded()');
            globalState.pool1.protocolFillFee = params.protocolFillFee0;
        }
        // fill fee token1
        if ((params.setFeesFlags & PROTOCOL_FILL_FEE_1) > 0) {
            if (params.protocolFillFee1 > MAX_PROTOCOL_FILL_FEE)
                require(false, 'ProtocolFillFeeCeilingExceeded()');
            globalState.pool0.protocolFillFee = params.protocolFillFee1;
        }
        address feeTo = ILimitPoolManager(constants.owner).feeTo();

        // token0 fees stored on pool1 for swaps and fills
        token0Fees = globalState.pool1.protocolFees;
        // token1 fees stored on pool0 for swaps and fills
        token1Fees = globalState.pool0.protocolFees;
        globalState.pool0.protocolFees = 0;
        globalState.pool1.protocolFees = 0;

        if (token0Fees > 0)
            SafeTransfers.transferOut(feeTo, constants.token0, token0Fees);
        if (token1Fees > 0)
            SafeTransfers.transferOut(feeTo, constants.token1, token1Fees);

        // withdraw errantly received ETH from pool
        if (address(this).balance > 0) {
            // send eth balance to feeTo
            SafeTransfers.transferOut(feeTo, ethAddress, address(this).balance);
        }

        // withdraw errantly received ETH from pool token
        if (address(constants.poolToken).balance > 0) {
            // send eth balance to feeTo
            IPositionERC1155(constants.poolToken).withdrawEth(feeTo, constants);
        }

        return (token0Fees, token1Fees);
    }
}

//SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

library SafeTransfers {
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
        bool success;
        if (amount == 0) return;
        if (token == address(0)) {
            (success, ) = to.call{value: amount}('');
            if (!success) require(false, 'SafeTransfers::EthTransferFailed()');
            return;
        }
        IERC20 erc20Token = IERC20(token);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transfer(to, amount);

        success = false;
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
        if (!success)
            require(false, 'TransferFailed(address(this), msg.sender');
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
    function transferInto(
        address token,
        address sender,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            require(false, 'SafeTransfers::CannotTransferInEth()');
        }
        IERC20 erc20Token = IERC20(token);

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
        if (!success)
            require(false, 'TransferFailed(msg.sender, address(this)');
    }
}