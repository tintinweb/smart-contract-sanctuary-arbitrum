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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @notice Events emitted by the LimitPoolFactory contract
abstract contract LimitPoolFactoryEvents {
    /// @notice Event emitted when a LimitPool is created
    event PoolCreated(
        address pool,
        address token,
        address indexed token0,
        address indexed token1,
        uint16 indexed swapFee,
        int16 tickSpacing,
        uint16 poolTypeId
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

abstract contract LimitPoolFactoryStorage {
    mapping(bytes32 => address) public pools; ///@dev - map for limit pool lookup by key
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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
    function cloneDeterministic(
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
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
                or(
                    shl(0x48, extraLength),
                    0x593da1005b363d3d373d3d3d3d610000806062363936013d73
                )
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(
                    shl(0x78, add(extraLength, 0x62)),
                    0x6100003d81600a3d39f336602c57343d527f
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(
                0,
                sub(data, 0x4c),
                add(extraLength, 0x6c),
                salt
            )

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
                or(
                    shl(0x48, extraLength),
                    0x593da1005b363d3d373d3d3d3d610000806062363936013d73
                )
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(
                    shl(0x78, add(extraLength, 0x62)),
                    0x6100003d81600a3d39f336602c57343d527f
                )
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
    function predictDeterministicAddress(
        bytes32 hash,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
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

// SPDX-License-Identifier: MIT

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

    function totalSupply(uint256 id) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../structs/LimitPoolStructs.sol';

interface ILimitPool is LimitPoolStructs {
    function initialize(uint160 startPrice) external;

    function mintLimit(MintLimitParams memory params)
        external
        returns (int256, int256);

    function burnLimit(BurnLimitParams memory params)
        external
        returns (int256, int256);

    function fees(FeesParams memory params)
        external
        returns (uint128 token0Fees, uint128 token1Fees);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import '../structs/PoolsharkStructs.sol';
import '../../base/storage/LimitPoolFactoryStorage.sol';

abstract contract ILimitPoolFactory is
    LimitPoolFactoryStorage,
    PoolsharkStructs
{
    function createLimitPool(LimitPoolParams memory params)
        external
        virtual
        returns (address pool, address poolToken);

    function getLimitPool(
        address tokenIn,
        address tokenOut,
        uint16 swapFee,
        uint16 poolTypeId
    ) external view virtual returns (address pool, address poolToken);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @notice LimitPoolManager interface
interface ILimitPoolManager {
    function owner() external view returns (address);

    function feeTo() external view returns (address);

    function feeDeltaConst() external view returns (uint16);

    function poolTypes(uint16 poolType)
        external
        view
        returns (address poolImpl, address tokenImpl);

    function feeTiers(uint16 swapFee) external view returns (int16 tickSpacing);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../structs/LimitPoolStructs.sol';

interface ILimitPoolView is LimitPoolStructs {
    function snapshotLimit(SnapshotLimitParams memory params)
        external
        view
        returns (uint128, uint128);

    function immutables() external view returns (LimitImmutables memory);

    function priceBounds(int16 tickSpacing)
        external
        pure
        returns (uint160 minPrice, uint160 maxPrice);

    function sample(uint32[] memory secondsAgo)
        external
        view
        returns (
            int56[] memory tickSecondsAccum,
            uint160[] memory secondsPerLiquidityAccum,
            uint160 averagePrice,
            uint128 averageLiquidity,
            int24 averageTick
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../structs/RangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is RangePoolStructs {
    function mintRange(MintRangeParams memory mintParams)
        external
        returns (int256, int256);

    function burnRange(BurnRangeParams memory burnParams)
        external
        returns (int256, int256);

    function swap(SwapParams memory params)
        external
        returns (int256 amount0, int256 amount1);

    function quote(QuoteParams memory params)
        external
        view
        returns (
            uint256 inAmount,
            uint256 outAmount,
            uint160 priceAfter
        );

    function snapshotRange(uint32 positionId)
        external
        view
        returns (
            int56 tickSecondsAccum,
            uint160 secondsPerLiquidityAccum,
            uint128 feesOwed0,
            uint128 feesOwed1
        );

    function sample(uint32[] memory secondsAgo)
        external
        view
        returns (
            int56[] memory tickSecondsAccum,
            uint160[] memory secondsPerLiquidityAccum,
            uint160 averagePrice,
            uint128 averageLiquidity,
            int24 averageTick
        );

    function positions(uint256 positionId)
        external
        view
        returns (
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 liquidity,
            int24 lower,
            int24 upper
        );

    function increaseSampleCount(uint16 newSampleCountMax) external;

    function ticks(int24)
        external
        view
        returns (RangeTick memory, LimitTick memory);

    function samples(uint256)
        external
        view
        returns (
            uint32,
            int56,
            uint160
        );
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.18;

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

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../structs/RangePoolStructs.sol';

interface IRangePoolManager {
    function owner() external view returns (address);

    function feeTo() external view returns (address);

    function protocolFees(address pool) external view returns (uint16);

    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import './PoolsharkStructs.sol';

interface LimitPoolStructs is PoolsharkStructs {
    struct LimitPosition {
        uint128 liquidity; // expected amount to be used not actual
        uint32 epochLast; // epoch when this position was created at
        int24 lower; // lower price tick of position range
        int24 upper; // upper price tick of position range
        bool crossedInto; // whether the position was crossed into already
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
        bool search;
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

    struct SearchLocals {
        int24[] ticksFound;
        int24 searchTick;
        int24 searchTickAhead;
        uint16 searchIdx;
        uint16 startIdx;
        uint16 endIdx;
        uint16 ticksIncluded;
        uint32 claimTickEpoch;
        uint32 claimTickAheadEpoch;
    }

    struct TickMapLocals {
        uint256 word;
        uint256 tickIndex;
        uint256 wordIndex;
        uint256 blockIndex;
    }
}

// SPDX-License-Identifier: GPLv3
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
        mapping(uint256 => uint256) words; /// @dev - sets to words
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

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.18;

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
        int128 feesAccrued0;
        int128 feesAccrued1;
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
        int56 tickSecondsAccum;
        int56 tickSecondsAccumLower;
        int56 tickSecondsAccumUpper;
        uint32 secondsOutsideLower;
        uint32 secondsOutsideUpper;
        uint32 blockTimestamp;
        int24 tick;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

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
                dy = OverflowMath.mulDivRoundingUp(
                    liquidity,
                    priceUpper - priceLower,
                    Q96
                );
            } else {
                dy = OverflowMath.mulDiv(
                    liquidity,
                    priceUpper - priceLower,
                    Q96
                );
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
                dx =
                    OverflowMath.mulDiv(
                        liquidity << 96,
                        priceUpper - priceLower,
                        priceUpper
                    ) /
                    priceLower;
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
                liquidity = OverflowMath.mulDiv(
                    dy,
                    Q96,
                    priceUpper - priceLower
                );
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
                uint256 liquidity1 = OverflowMath.mulDiv(
                    dy,
                    Q96,
                    currentPrice - priceLower
                );
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
            token1amount = uint128(
                getDy(liquidityAmount, priceLower, priceUpper, roundUp)
            );
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(
                getDx(liquidityAmount, priceLower, priceUpper, roundUp)
            );
        } else {
            token0amount = uint128(
                getDx(liquidityAmount, currentPrice, priceUpper, roundUp)
            );
            token1amount = uint128(
                getDy(liquidityAmount, priceLower, currentPrice, roundUp)
            );
        }
        if (token0amount > uint128(type(int128).max))
            require(false, 'AmountsOutOfBounds()');
        if (token1amount > uint128(type(int128).max))
            require(false, 'AmountsOutOfBounds()');
    }

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 amount,
        bool zeroForOne,
        bool exactIn
    ) internal pure returns (uint256 newPrice) {
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
                newPrice =
                    price -
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

    function getPrice(uint256 sqrtPrice) internal pure returns (uint256 price) {
        if (sqrtPrice >= 2**48)
            price = OverflowMath.mulDiv(sqrtPrice, sqrtPrice, 2**96);
        else price = sqrtPrice;
    }

    /////////////////////////////////////////////////////////////
    ///////////////////////// TICK MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    int24 internal constant MIN_TICK = -887272; /// @dev - tick for price of 2^-128
    int24 internal constant MAX_TICK = -MIN_TICK; /// @dev - tick for price of 2^128

    function minTick(int16 tickSpacing) internal pure returns (int24 tick) {
        return (MIN_TICK / tickSpacing) * tickSpacing;
    }

    function maxTick(int16 tickSpacing) internal pure returns (int24 tick) {
        return (MAX_TICK / tickSpacing) * tickSpacing;
    }

    function priceBounds(int16 tickSpacing)
        internal
        pure
        returns (uint160, uint160)
    {
        return (minPrice(tickSpacing), maxPrice(tickSpacing));
    }

    function minPrice(int16 tickSpacing) internal pure returns (uint160 price) {
        PoolsharkStructs.LimitImmutables memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(int16 tickSpacing) internal pure returns (uint160 price) {
        PoolsharkStructs.LimitImmutables memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(maxTick(tickSpacing), constants);
    }

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure {
        if (lower < minTick(tickSpacing))
            require(false, 'LowerTickOutOfBounds()');
        if (upper > maxTick(tickSpacing))
            require(false, 'UpperTickOutOfBounds()');
        if (lower % tickSpacing != 0)
            require(false, 'LowerTickOutsideTickSpacing()');
        if (upper % tickSpacing != 0)
            require(false, 'UpperTickOutsideTickSpacing()');
        if (lower >= upper) require(false, 'LowerUpperTickOrderInvalid()');
    }

    function checkPrice(uint160 price, PriceBounds memory bounds)
        internal
        pure
    {
        if (price < bounds.min || price >= bounds.max)
            require(false, 'PriceOutOfBounds()');
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return price Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getPriceAtTick(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (uint160 price) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        if (absTick > uint256(uint24(maxTick(constants.tickSpacing))))
            require(false, 'TickOutOfBounds()');
        unchecked {
            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

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
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price > constants.bounds.max)
            require(false, 'PriceOutOfBounds()');
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

        int24 tickLow = int24(
            (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
        );
        int24 tickHi = int24(
            (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
        );

        tick = tickLow == tickHi
            ? tickLow
            : getPriceAtTick(tickHi, constants) <= price
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library OverflowMath {
    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 z)
    {
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
                if (result >= type(uint256).max)
                    require(false, 'MaxUintExceeded()');
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library Bytes {
    bytes16 private constant alphabet = '0123456789abcdef';

    function from(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.18;

import './Bytes.sol';
import './String.sol';
import '../math/OverflowMath.sol';
import '../../interfaces/IPositionERC1155.sol';
import '../../interfaces/range/IRangePoolFactory.sol';
import '../../interfaces/structs/RangePoolStructs.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// @notice Token library for ERC-1155 calls.
library PositionTokens {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function balanceOf(
        PoolsharkStructs.LimitImmutables memory constants,
        address owner,
        uint32 positionId
    ) internal view returns (uint256) {
        return
            IPositionERC1155(constants.poolToken).balanceOf(owner, positionId);
    }

    function name(address token0, address token1)
        internal
        view
        returns (bytes32 result)
    {
        string memory nameString = string.concat(
            'Poolshark ',
            ERC20(token0).symbol(),
            '-',
            ERC20(token1).symbol()
        );

        result = Bytes.from(nameString);
    }

    function symbol(address token0, address token1)
        internal
        view
        returns (bytes32 result)
    {
        string memory symbolString = string.concat(
            'PSHARK-',
            ERC20(token0).symbol(),
            '-',
            ERC20(token1).symbol()
        );

        result = Bytes.from(symbolString);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        if ((z = uint128(y)) != y)
            require(false, 'Uint256ToUint128:Overflow()');
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(int128 y) internal pure returns (uint128 z) {
        if (y < 0) require(false, 'Int128ToUint128:Underflow()');
        z = uint128(y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        if ((z = uint160(y)) != y)
            require(false, 'Uint256ToUint160:Overflow()');
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        if ((z = uint32(y)) != y) require(false, 'Uint256ToUint32:Overflow()');
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
        if (y > uint128(type(int128).max))
            require(false, 'Uint128ToInt128:Overflow()');
        z = int128(y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        if (y > uint256(type(int256).max))
            require(false, 'Uint256ToInt256:Overflow()');
        z = int256(y);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint256(int256 y) internal pure returns (uint256 z) {
        if (y < 0) require(false, 'Int256ToUint256:Underflow()');
        z = uint256(y);
    }

    /// @notice Cast a uint256 to a uint16, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint16(uint256 y) internal pure returns (uint16 z) {
        if ((z = uint16(y)) != y) require(false, 'Uint256ToUint16:Overflow()');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library String {
    bytes16 private constant alphabet = '0123456789abcdef';

    function from(bytes32 value) internal pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function from(address account) internal pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function from(uint256 value) internal pure returns (string memory) {
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
        return string(abi.encodePacked(value < 0 ? '-' : '', from(abs(value))));
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < data.length; ) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
            unchecked {
                ++i;
            }
        }
        return string(str);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import './interfaces/range/IRangePool.sol';
import './interfaces/limit/ILimitPool.sol';
import './interfaces/limit/ILimitPoolView.sol';
import './interfaces/structs/LimitPoolStructs.sol';
import './interfaces/structs/RangePoolStructs.sol';
import './interfaces/limit/ILimitPoolFactory.sol';
import './interfaces/limit/ILimitPoolManager.sol';
import './base/events/LimitPoolFactoryEvents.sol';
import './external/solady/LibClone.sol';
import './libraries/utils/SafeCast.sol';
import './libraries/utils/PositionTokens.sol';
import './libraries/math/ConstantProduct.sol';

/**
 * @notice Limit Pool Factory
 * @author Poolshark
 * @author @alphak3y
 */
contract LimitPoolFactory is
    ILimitPoolFactory,
    LimitPoolStructs,
    RangePoolStructs,
    LimitPoolFactoryEvents
{
    using LibClone for address;
    using SafeCast for uint256;

    /// @notice The original address of the deployed contract
    address public immutable original;
    /// @notice The owner address for all LimitPool contracts
    address public immutable owner;

    constructor(address owner_) {
        owner = owner_;
        original = address(this);
    }

    /// @notice This modifier ensures against delegate calls
    modifier originalOnly() {
        _onlyOriginal();
        _;
    }

    /// @notice Creates a new LimitPool for the selected poolTypeId
    /// @param params the params for which to create the pool with
    /// @dev See PoolsharkStructs.sol for struct data
    function createLimitPool(LimitPoolParams memory params)
        public
        override
        originalOnly
        returns (address pool, address poolToken)
    {
        // validate token pair
        if (
            params.tokenIn == params.tokenOut ||
            params.tokenIn == address(0) ||
            params.tokenOut == address(0)
        ) {
            require(false, 'InvalidTokenAddress()');
        }

        // sort tokens by address
        LimitImmutables memory constants;
        (constants.token0, constants.token1) = params.tokenIn < params.tokenOut
            ? (params.tokenIn, params.tokenOut)
            : (params.tokenOut, params.tokenIn);

        // check if tick spacing supported
        constants.swapFee = params.swapFee;
        constants.tickSpacing = ILimitPoolManager(owner).feeTiers(
            params.swapFee
        );
        if (constants.tickSpacing == 0) require(false, 'FeeTierNotSupported()');

        // check if pool type supported
        (address poolImpl, address tokenImpl) = ILimitPoolManager(owner)
            .poolTypes(params.poolTypeId);
        if (poolImpl == address(0) || tokenImpl == address(0))
            require(false, 'PoolTypeNotSupported()');

        // generate key for pool
        bytes32 key = keccak256(
            abi.encode(
                poolImpl,
                constants.token0,
                constants.token1,
                constants.swapFee
            )
        );

        // check if pool already exists
        if (pools[key] != address(0)) require(false, 'PoolAlreadyExists()');

        // set immutables
        constants.owner = owner;
        constants.factory = original;
        constants.genesisTime = block.timestamp.toUint32();
        (constants.bounds.min, constants.bounds.max) = ILimitPoolView(poolImpl)
            .priceBounds(constants.tickSpacing);

        // take that ERC1155 contract address and pass that into pool
        // launch pool token
        constants.poolToken = tokenImpl.cloneDeterministic({
            salt: key,
            data: abi.encodePacked(
                PositionTokens.name(constants.token0, constants.token1),
                PositionTokens.symbol(constants.token0, constants.token1)
            )
        });

        // launch pool
        pool = poolImpl.cloneDeterministic({
            salt: key,
            data: abi.encodePacked(
                constants.owner,
                constants.token0,
                constants.token1,
                constants.poolToken,
                constants.bounds.min,
                constants.bounds.max,
                constants.genesisTime,
                constants.tickSpacing,
                constants.swapFee
            )
        });

        // initialize pool storage
        ILimitPool(pool).initialize(params.startPrice);

        // save pool in mapping
        pools[key] = pool;

        emit PoolCreated(
            pool,
            constants.poolToken,
            constants.token0,
            constants.token1,
            constants.swapFee,
            constants.tickSpacing,
            params.poolTypeId
        );

        return (pool, constants.poolToken);
    }

    /// @notice Gets a new LimitPool for the selected poolTypeId
    /// @param tokenIn the first token in the pair
    /// @param tokenOut the second token in the pair
    /// @param swapFee the swap fee for the pool
    /// @param poolTypeId the poolTypeId for the pool
    function getLimitPool(
        address tokenIn,
        address tokenOut,
        uint16 swapFee,
        uint16 poolTypeId
    ) public view override returns (address pool, address poolToken) {
        // set lexographical token address ordering
        address token0 = tokenIn < tokenOut ? tokenIn : tokenOut;
        address token1 = tokenIn < tokenOut ? tokenOut : tokenIn;

        // check if tick spacing supported
        int16 tickSpacing = ILimitPoolManager(owner).feeTiers(swapFee);
        if (tickSpacing == 0) require(false, 'FeeTierNotSupported()');

        // check if pool type supported
        (address poolImpl, address tokenImpl) = ILimitPoolManager(owner)
            .poolTypes(poolTypeId);
        if (poolImpl == address(0) || tokenImpl == address(0))
            require(false, 'PoolTypeNotSupported()');

        // generate key for pool
        bytes32 key = keccak256(abi.encode(poolImpl, token0, token1, swapFee));

        pool = pools[key];

        poolToken = LibClone.predictDeterministicAddress(
            tokenImpl,
            abi.encodePacked(
                PositionTokens.name(token0, token1),
                PositionTokens.symbol(token0, token1)
            ),
            key,
            address(this)
        );

        return (pool, poolToken);
    }

    function _onlyOriginal() private view {
        if (address(this) != original) require(false, 'OriginalOnly()');
    }
}