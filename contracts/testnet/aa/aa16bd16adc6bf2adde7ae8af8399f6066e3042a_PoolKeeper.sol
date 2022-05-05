// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/ILeveragedPool.sol";
import "../interfaces/IPoolCommitter.sol";
import "../interfaces/IPoolToken.sol";
import "../interfaces/IPoolKeeper.sol";
import "../interfaces/IInvariantCheck.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/ITwoStepGovernance.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/PoolSwapLibrary.sol";
import "../interfaces/IOracleWrapper.sol";

/// @title The pool contract itself
contract LeveragedPool is ILeveragedPool, Initializable, IPausable, ITwoStepGovernance {
    using SafeERC20 for IERC20;
    // #### Globals

    // Each balance is the amount of settlement tokens in the pair
    uint256 public override shortBalance;
    uint256 public override longBalance;
    uint256 public constant LONG_INDEX = 0;
    uint256 public constant SHORT_INDEX = 1;

    address public override governance;
    address public invariantCheck;
    uint32 public override frontRunningInterval;
    uint32 public override updateInterval;
    bytes16 public fee;

    bytes16 public override leverageAmount;
    address public override provisionalGovernance;
    bool public override paused;
    bool public override governanceTransferInProgress;
    address public keeper;
    // When feeAddress changes, all prior fees are assigned to the new address
    address public feeAddress;
    address public secondaryFeeAddress;
    uint256 public secondaryFeeSplitPercent; // Split to secondary fee address as a percentage.
    // Amount of fees assigned to either feeAddress (primaryFees), or secondaryFeeAddress (secondaryFees)
    uint256 public override primaryFees;
    uint256 public override secondaryFees;
    address public override settlementToken;
    address public override poolCommitter;
    address public override oracleWrapper;
    address public override settlementEthOracle;
    address[2] public tokens;
    uint256 public override lastPriceTimestamp; // The last time the pool was upkept

    string public override poolName;

    // #### Modifiers

    modifier onlyKeeper() {
        require(msg.sender == keeper, "msg.sender not keeper");
        _;
    }

    modifier onlyKeeperRewards() {
        require(msg.sender == IPoolKeeper(keeper).keeperRewards(), "msg.sender not keeperRewards");
        _;
    }

    modifier onlyPoolCommitter() {
        require(msg.sender == poolCommitter, "msg.sender not poolCommitter");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "msg.sender not governance");
        _;
    }

    modifier onlyInvariantCheckContract() {
        require(msg.sender == invariantCheck, "msg.sender not invariantCheck");
        _;
    }

    modifier onlyUnpaused() {
        require(!paused, "Pool is paused");
        _;
    }

    // #### Functions

    function initialize(ILeveragedPool.Initialization calldata initialization) external override initializer {
        require(initialization._feeAddress != address(0), "Fee address cannot be 0 address");
        require(initialization._settlementToken != address(0), "Settlement token cannot be 0 address");
        require(initialization._oracleWrapper != address(0), "Oracle wrapper cannot be 0 address");
        require(initialization._settlementEthOracle != address(0), "Keeper oracle cannot be 0 address");
        require(initialization._owner != address(0), "Owner cannot be 0 address");
        require(initialization._keeper != address(0), "Keeper cannot be 0 address");
        require(initialization._longToken != address(0), "Long token cannot be 0 address");
        require(initialization._shortToken != address(0), "Short token cannot be 0 address");
        require(initialization._poolCommitter != address(0), "PoolCommitter cannot be 0 address");
        require(initialization._invariantCheck != address(0), "InvariantCheck cannot be 0 address");
        require(initialization._fee < PoolSwapLibrary.WAD_PRECISION, "Fee >= 100%");
        require(initialization._secondaryFeeSplitPercent <= 100, "Secondary fee split cannot exceed 100%");
        require(initialization._updateInterval != 0, "Update interval cannot be 0");

        // set the owner of the pool. This is governance when deployed from the factory
        governance = initialization._owner;

        // Setup variables
        keeper = initialization._keeper;
        oracleWrapper = initialization._oracleWrapper;
        settlementEthOracle = initialization._settlementEthOracle;
        settlementToken = initialization._settlementToken;
        invariantCheck = initialization._invariantCheck;
        frontRunningInterval = initialization._frontRunningInterval;
        updateInterval = initialization._updateInterval;
        fee = PoolSwapLibrary.convertUIntToDecimal(initialization._fee);
        leverageAmount = PoolSwapLibrary.convertUIntToDecimal(initialization._leverageAmount);
        feeAddress = initialization._feeAddress;
        secondaryFeeAddress = initialization._secondaryFeeAddress;
        secondaryFeeSplitPercent = initialization._secondaryFeeSplitPercent;
        lastPriceTimestamp = block.timestamp;
        poolName = initialization._poolName;
        tokens[LONG_INDEX] = initialization._longToken;
        tokens[SHORT_INDEX] = initialization._shortToken;
        poolCommitter = initialization._poolCommitter;
        emit PoolInitialized(
            initialization._longToken,
            initialization._shortToken,
            initialization._settlementToken,
            initialization._poolName
        );
    }

    /**
     * @notice Execute a price change
     * @param _oldPrice Previous price of the underlying asset
     * @param _newPrice New price of the underlying asset
     * @dev Throws if at least one update interval has not elapsed since last price update
     * @dev This is the entry point to upkeep a market
     * @dev Only callable by the associated `PoolKeeper` contract
     * @dev Only callable if the market is *not* paused
     */
    function poolUpkeep(int256 _oldPrice, int256 _newPrice) external override onlyKeeper onlyUnpaused {
        require(intervalPassed(), "Update interval hasn't passed");
        // perform price change and update pool balances
        executePriceChange(_oldPrice, _newPrice);
        (
            uint256 longMintAmount,
            uint256 shortMintAmount,
            uint256 newLongBalance,
            uint256 newShortBalance,
            uint256 newLastPriceTimestamp
        ) = IPoolCommitter(poolCommitter).executeCommitments(
                lastPriceTimestamp,
                updateInterval,
                longBalance,
                shortBalance
            );
        lastPriceTimestamp = newLastPriceTimestamp;
        longBalance = newLongBalance;
        shortBalance = newShortBalance;
        if (longMintAmount > 0) {
            IPoolToken(tokens[LONG_INDEX]).mint(address(this), longMintAmount);
        }
        if (shortMintAmount > 0) {
            IPoolToken(tokens[SHORT_INDEX]).mint(address(this), shortMintAmount);
        }
    }

    /**
     * @notice Pay keeper some amount in the settlement token for the perpetual pools market
     * @param to Address of the pool keeper to pay
     * @param amount Amount to pay the pool keeper
     * @return Whether the keeper is going to be paid; false if the amount exceeds the balances of the
     *         long and short pool, and true if the keeper can successfully be paid out
     * @dev Only callable by the associated `PoolKeeper` contract
     * @dev Only callable when the market is *not* paused
     */
    function payKeeperFromBalances(address to, uint256 amount)
        external
        override
        onlyKeeperRewards
        onlyUnpaused
        returns (bool)
    {
        uint256 _shortBalance = shortBalance;
        uint256 _longBalance = longBalance;

        // If the rewards are greater than the balances of the pool, the keeper does not get paid
        if (amount > _shortBalance + _longBalance) {
            return false;
        }

        (uint256 shortBalanceAfterRewards, uint256 longBalanceAfterRewards) = PoolSwapLibrary.getBalancesAfterFees(
            amount,
            _shortBalance,
            _longBalance
        );

        shortBalance = shortBalanceAfterRewards;
        longBalance = longBalanceAfterRewards;

        // Pay keeper
        IERC20(settlementToken).safeTransfer(to, amount);

        return true;
    }

    /**
     * @notice Transfer settlement tokens from pool to user
     * @param to Address of account to transfer to
     * @param amount Amount of settlement tokens being transferred
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     */
    function settlementTokenTransfer(address to, uint256 amount) external override onlyPoolCommitter onlyUnpaused {
        IERC20(settlementToken).safeTransfer(to, amount);
    }

    /**
     * @notice Transfer pool tokens from pool to user
     * @param isLongToken True if transferring long pool token; False if transferring short pool token
     * @param to Address of account to transfer to
     * @param amount Amount of pool tokens being transferred
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     */
    function poolTokenTransfer(
        bool isLongToken,
        address to,
        uint256 amount
    ) external override onlyPoolCommitter onlyUnpaused {
        if (isLongToken) {
            IERC20(tokens[LONG_INDEX]).safeTransfer(to, amount);
        } else {
            IERC20(tokens[SHORT_INDEX]).safeTransfer(to, amount);
        }
    }

    /**
     * @notice Transfer tokens from user to account
     * @param from The account that's transferring settlement tokens
     * @param to Address of account to transfer to
     * @param amount Amount of settlement tokens being transferred
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     */
    function settlementTokenTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external override onlyPoolCommitter onlyUnpaused {
        IERC20(settlementToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @notice Execute the price change once the interval period ticks over, updating the long & short
     *         balances based on the change of the feed (upwards or downwards) and paying fees
     * @param _oldPrice Old price from the oracle
     * @param _newPrice New price from the oracle
     * @dev Can only be called by poolUpkeep
     * @dev Only callable when the market is *not* paused
     * @dev Emits `PoolRebalance` if execution succeeds
     * @dev Emits `PriceChangeError` if execution does not take place
     */
    function executePriceChange(int256 _oldPrice, int256 _newPrice) internal {
        // prevent a division by 0 in computing the price change
        // prevent negative pricing
        if (_oldPrice <= 0 || _newPrice <= 0) {
            emit PriceChangeError(_oldPrice, _newPrice);
        } else {
            uint256 _shortBalance = shortBalance;
            uint256 _longBalance = longBalance;
            PoolSwapLibrary.PriceChangeData memory priceChangeData = PoolSwapLibrary.PriceChangeData(
                _oldPrice,
                _newPrice,
                _longBalance,
                _shortBalance,
                leverageAmount,
                fee
            );
            (
                uint256 newLongBalance,
                uint256 newShortBalance,
                uint256 longFeeAmount,
                uint256 shortFeeAmount
            ) = PoolSwapLibrary.calculatePriceChange(priceChangeData);

            unchecked {
                emit PoolRebalance(
                    int256(newShortBalance) - int256(_shortBalance),
                    int256(newLongBalance) - int256(_longBalance),
                    shortFeeAmount,
                    longFeeAmount
                );
            }
            // Update pool balances
            longBalance = newLongBalance;
            shortBalance = newShortBalance;
            // Pay the fee
            feeTransfer(longFeeAmount + shortFeeAmount);
        }
    }

    /**
     * @notice Transfer primary fees to the primary fee address
     * @dev Calls ERC20.safeTransfer on the settlement token
     * @dev Emits a PrimaryFeesPaid event
     */
    function claimPrimaryFees() external override {
        uint256 tempPrimaryFees = primaryFees;
        primaryFees = 0;
        IERC20(settlementToken).safeTransfer(feeAddress, tempPrimaryFees);
        emit PrimaryFeesPaid(feeAddress, tempPrimaryFees);
    }

    /**
     * @notice Transfer secondary fees to the secondary fee address
     * @dev Calls ERC20.safeTransfer on the settlement token
     * @dev Emits a SecondaryFeesPaid event
     */
    function claimSecondaryFees() external override {
        uint256 tempSecondaryFees = secondaryFees;
        secondaryFees = 0;
        IERC20(settlementToken).safeTransfer(secondaryFeeAddress, tempSecondaryFees);
        emit SecondaryFeesPaid(secondaryFeeAddress, tempSecondaryFees);
    }

    /**
     * @notice Increment fee amounts. Allows primary or secondary fees to be claimed with either `claimPrimaryFees` or `claimSecondaryFees` respectively.
     *         If the DAO is the fee deployer, secondary fee address should be address(0) and all fees go to DAO.
     * @param totalFeeAmount total amount of fees paid
     */
    function feeTransfer(uint256 totalFeeAmount) internal {
        if (secondaryFeeAddress == address(0)) {
            // IERC20(settlementToken).safeTransfer(feeAddress, totalFeeAmount);
            unchecked {
                // Overflow would require more than settlement's entire total supply
                primaryFees += totalFeeAmount;
            }
        } else {
            uint256 secondaryFee = PoolSwapLibrary.mulFraction(totalFeeAmount, secondaryFeeSplitPercent, 100);
            uint256 remainder;
            unchecked {
                // secondaryFee is calculated as totalFeeAmount * secondaryFeeSplitPercent / 100
                // secondaryFeeSplitPercent <= 100 and therefore secondaryFee <= totalFeeAmount - The following line can not underflow
                remainder = totalFeeAmount - secondaryFee;
            }
            IERC20 _settlementToken = IERC20(settlementToken);
            unchecked {
                // Overflow would require more than settlement's entire total supply
                secondaryFees += secondaryFee;
                primaryFees += remainder;
            }
            if (secondaryFee != 0) {
                _settlementToken.safeTransfer(secondaryFeeAddress, secondaryFee);
            }
            if (remainder != 0) {
                _settlementToken.safeTransfer(feeAddress, remainder);
            }
        }
    }

    /**
     * @notice Sets the long and short balances of the pools
     * @param _longBalance New balance of the long pool
     * @param _shortBalance New balance of the short pool
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     * @dev Emits a `PoolBalancesChanged` event on success
     */
    function setNewPoolBalances(uint256 _longBalance, uint256 _shortBalance)
        external
        override
        onlyPoolCommitter
        onlyUnpaused
    {
        longBalance = _longBalance;
        shortBalance = _shortBalance;
        emit PoolBalancesChanged(_longBalance, _shortBalance);
    }

    /**
     * @notice Burn tokens by a user
     * @dev Can only be called by & used by the pool committer
     * @param tokenType LONG_INDEX (0) or SHORT_INDEX (1) for either burning the long or short  token respectively
     * @param amount Amount of tokens to burn
     * @param burner Address of user/burner
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     */
    function burnTokens(
        uint256 tokenType,
        uint256 amount,
        address burner
    ) external override onlyPoolCommitter onlyUnpaused {
        IPoolToken(tokens[tokenType]).burn(burner, amount);
    }

    /**
     * @notice Indicates whether the price was last updated more than `updateInterval` seconds ago
     * @return Whether the price was last updated more than `updateInterval` seconds ago
     * @dev Unchecked
     */
    function intervalPassed() public view override returns (bool) {
        unchecked {
            return block.timestamp >= lastPriceTimestamp + updateInterval;
        }
    }

    /**
     * @notice Updates the fee address of the pool
     * @param account New address of the fee address/receiver
     * @dev Only callable by governance
     * @dev Only callable when the market is *not* paused
     * @dev Emits `FeeAddressUpdated` event on success
     */
    function updateFeeAddress(address account) external override onlyGov onlyUnpaused {
        require(account != address(0), "Account cannot be 0 address");
        address oldFeeAddress = feeAddress;
        feeAddress = account;
        emit FeeAddressUpdated(oldFeeAddress, account);
    }

    /**
     * @notice Updates the secondary fee address of the pool
     * @param account New address of the fee address/receiver
     */
    function updateSecondaryFeeAddress(address account) external override {
        address _oldSecondaryFeeAddress = secondaryFeeAddress;
        require(msg.sender == _oldSecondaryFeeAddress);
        secondaryFeeAddress = account;
        emit SecondaryFeeAddressUpdated(_oldSecondaryFeeAddress, account);
    }

    /**
     * @notice Updates the keeper contract of the pool
     * @param _keeper New address of the keeper contract
     */
    function setKeeper(address _keeper) external override onlyGov {
        require(_keeper != address(0), "Keeper address cannot be 0 address");
        address oldKeeper = keeper;
        keeper = _keeper;
        emit KeeperAddressChanged(oldKeeper, _keeper);
    }

    /**
     * @notice Starts to transfer governance of the pool. The new governance
     *          address must call `claimGovernance` in order for this to take
     *          effect. Until this occurs, the existing governance address
     *          remains in control of the pool.
     * @param _governance New address of the governance of the pool
     * @dev First step of the two-step governance transfer process
     * @dev Sets the governance transfer flag to true
     * @dev See `claimGovernance`
     */
    function transferGovernance(address _governance) external override onlyGov {
        require(_governance != governance, "New governance address cannot be same as old governance address");
        require(_governance != address(0), "Governance address cannot be 0 address");
        provisionalGovernance = _governance;
        governanceTransferInProgress = true;
        emit ProvisionalGovernanceChanged(_governance);
    }

    /**
     * @notice Completes transfer of governance by actually changing permissions
     *          over the pool.
     * @dev Second and final step of the two-step governance transfer process
     * @dev See `transferGovernance`
     * @dev Sets the governance transfer flag to false
     * @dev After a successful call to this function, the actual governance
     *      address and the provisional governance address MUST be equal.
     */
    function claimGovernance() external override {
        require(governanceTransferInProgress, "No governance change active");
        address _provisionalGovernance = provisionalGovernance;
        require(msg.sender == _provisionalGovernance, "Not provisional governor");
        address oldGovernance = governance; /* for later event emission */
        governance = _provisionalGovernance;
        governanceTransferInProgress = false;
        emit GovernanceAddressChanged(oldGovernance, _provisionalGovernance);
    }

    /**
     * @return _latestPrice The oracle price
     * @return _data The oracleWrapper's metadata. Implementations can choose what data to return here
     * @return _lastPriceTimestamp The timestamp of the last upkeep
     * @return _updateInterval The update frequency for this pool
     * @dev To save gas so PoolKeeper does not have to make three external calls
     */
    function getUpkeepInformation()
        external
        view
        override
        returns (
            int256,
            bytes memory,
            uint256,
            uint256
        )
    {
        (int256 _latestPrice, bytes memory _data) = IOracleWrapper(oracleWrapper).getPriceAndMetadata();
        return (_latestPrice, _data, lastPriceTimestamp, updateInterval);
    }

    /**
     * @return The price of the pool's feed oracle
     */
    function getOraclePrice() external view override returns (int256) {
        return IOracleWrapper(oracleWrapper).getPrice();
    }

    /**
     * @return Addresses of the pool tokens for this pool (long and short,
     *          respectively)
     */
    function poolTokens() external view override returns (address[2] memory) {
        return tokens;
    }

    /**
     * @return Quantities of pool tokens for this pool (short and long,
     *          respectively)
     */
    function balances() external view override returns (uint256, uint256) {
        return (shortBalance, longBalance);
    }

    /**
     * @notice Withdraws all available settlement asset from the pool
     * @dev Pool must be paused
     * @dev ERC20 transfer
     * @dev Only callable by governance
     */
    function withdrawSettlement() external onlyGov {
        require(paused, "Pool is live");
        IERC20 settlementERC = IERC20(settlementToken);
        uint256 balance = settlementERC.balanceOf(address(this));
        IERC20(settlementToken).safeTransfer(msg.sender, balance);
        emit SettlementWithdrawn(msg.sender, balance);
    }

    /**
     * @notice Pauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function pause() external override onlyInvariantCheckContract {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function unpause() external override onlyGov {
        paused = false;
        emit Unpaused();
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IPoolCommitter.sol";
import "../interfaces/ILeveragedPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IAutoClaim.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/IInvariantCheck.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/PoolSwapLibrary.sol";
import "../libraries/CalldataLogic.sol";

/// @title This contract is responsible for handling commitment logic
contract PoolCommitter is IPoolCommitter, IPausable, Initializable {
    // #### Globals
    uint128 public constant LONG_INDEX = 0;
    uint128 public constant SHORT_INDEX = 1;

    // 15 was chosen because it will definitely fit in a block on Arbitrum which can be tricky to ascertain definitive computation cap without trial and error, while it is also a reasonable number of upkeeps to get executed in one transaction
    uint8 public constant MAX_ITERATIONS = 15;
    IAutoClaim public autoClaim;
    uint128 public override updateIntervalId = 1;
    // The amount that is extracted from each mint and burn, being left in the pool. Given as the decimal * 10 ^ 18. For example, 60% fee is 0.6 * 10 ^ 18
    // Fees can be 0.
    bytes16 public mintingFee;
    bytes16 public burningFee;
    // The amount that the `mintingFee` will change each update interval, based on `updateMintingFee`, given as a decimal * 10 ^ 18 (same format as `_mintingFee`)
    bytes16 public changeInterval;

    // Index 0 is the LONG token, index 1 is the SHORT token.
    // Fetched from the LeveragedPool when leveragedPool is set
    address[2] public tokens;

    mapping(uint256 => Prices) public priceHistory; // updateIntervalId => tokenPrice
    mapping(uint256 => bytes16) public burnFeeHistory; // updateIntervalId => burn fee. We need to store this historically because people can claim at any time after the update interval, but we want them to pay the fee from the update interval in which they committed.
    mapping(address => Balance) public userAggregateBalance;

    // The total amount of settlement that has been committed to mints that are not yet executed
    uint256 public override pendingMintSettlementAmount;
    // The total amount of short pool tokens that have been burnt that are not yet executed on
    uint256 public override pendingShortBurnPoolTokens;
    // The total amount of long pool tokens that have been burnt that are not yet executed on
    uint256 public override pendingLongBurnPoolTokens;
    // Update interval ID => TotalCommitment
    mapping(uint256 => TotalCommitment) public totalPoolCommitments;
    // Address => Update interval ID => UserCommitment
    mapping(address => mapping(uint256 => UserCommitment)) public userCommitments;
    // The last interval ID for which a given user's balance was updated
    mapping(address => uint256) public lastUpdatedIntervalId;
    // An array for all update intervals in which a user committed
    mapping(address => uint256[]) public unAggregatedCommitments;
    // Used to create a dynamic array that is used to copy the new unAggregatedCommitments array into the mapping after updating balance
    uint256[] private storageArrayPlaceHolder;

    address public factory;
    address public governance;
    address public feeController;
    address public leveragedPool;
    address public invariantCheck;
    bool public override paused;

    modifier onlyFeeController() {
        require(msg.sender == feeController, "msg.sender not fee controller");
        _;
    }

    modifier onlyUnpaused() {
        require(!paused, "Pool is paused");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "msg.sender not governance");
        _;
    }

    /**
     * @notice Asserts that the caller is the associated `PoolFactory` contract
     */
    modifier onlyFactory() {
        require(msg.sender == factory, "Committer: not factory");
        _;
    }

    /**
     * @notice Asserts that the caller is the associated `LeveragedPool` contract
     */
    modifier onlyPool() {
        require(msg.sender == leveragedPool, "msg.sender not leveragedPool");
        _;
    }

    modifier onlyInvariantCheckContract() {
        require(msg.sender == invariantCheck, "msg.sender not invariantCheck");
        _;
    }

    modifier onlyAutoClaimOrCommitter(address user) {
        require(msg.sender == user || msg.sender == address(autoClaim), "msg.sender not committer or AutoClaim");
        _;
    }

    /**
     * @notice Initialises the contract
     * @param _factory Address of the associated `PoolFactory` contract
     * @param _autoClaim Address of the associated `AutoClaim` contract
     * @param _factoryOwner Address of the owner of the `PoolFactory`
     * @param _invariantCheck Address of the `InvariantCheck` contract
     * @param _mintingFee The percentage that is taken from each mint, given as a decimal * 10 ^ 18
     * @param _burningFee The percentage that is taken from each burn, given as a decimal * 10 ^ 18
     * @param _changeInterval The amount that the `mintingFee` will change each update interval, based on `updateMintingFee`, given as a decimal * 10 ^ 18 (same format as `_mintingFee`)
     * @dev Throws if factory contract address is null
     * @dev Throws if autoClaim contract address is null
     * @dev Throws if autoclaim contract address is null
     * @dev Only callable by the associated initializer address
     * @dev Throws if minting fee is over 100%
     * @dev Throws if burning fee is over 100%
     * @dev Emits a `ChangeIntervalSet` event on success
     */
    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 _mintingFee,
        uint256 _burningFee,
        uint256 _changeInterval
    ) external override initializer {
        require(_factory != address(0), "Factory cannot be null");
        require(_autoClaim != address(0), "AutoClaim address cannot be null");
        require(_feeController != address(0), "fee controller cannot be null");
        require(_invariantCheck != address(0), "invariantCheck cannot be null");
        updateIntervalId = 1;
        factory = _factory;
        invariantCheck = _invariantCheck;
        mintingFee = PoolSwapLibrary.convertUIntToDecimal(_mintingFee);
        burningFee = PoolSwapLibrary.convertUIntToDecimal(_burningFee);
        require(mintingFee < PoolSwapLibrary.MAX_MINTING_FEE, "Minting fee >= 100%");
        require(burningFee < PoolSwapLibrary.MAX_BURNING_FEE, "Burning fee >= 10%");
        changeInterval = PoolSwapLibrary.convertUIntToDecimal(_changeInterval);
        feeController = _feeController;
        autoClaim = IAutoClaim(_autoClaim);
        governance = _factoryOwner;
    }

    /**
     * @notice Apply commitment data to storage
     * @param pool The LeveragedPool of this PoolCommitter instance
     * @param commitType The type of commitment being made
     * @param amount The amount of tokens being committed
     * @param fromAggregateBalance If minting, burning, or rebalancing into a delta neutral position,
     *                             will tokens be taken from user's aggregate balance?
     * @param userCommit The appropriate update interval's commitment data for the user
     * @param totalCommit The appropriate update interval's commitment data for the entire pool
     */
    function applyCommitment(
        ILeveragedPool pool,
        CommitType commitType,
        uint256 amount,
        bool fromAggregateBalance,
        UserCommitment storage userCommit,
        TotalCommitment storage totalCommit
    ) private {
        Balance memory balance = userAggregateBalance[msg.sender];
        uint256 feeAmount;

        if (commitType == CommitType.LongMint || commitType == CommitType.ShortMint) {
            // We want to deduct the amount of settlement tokens that will be recorded under the commit by the minting fee
            // and then add it to the correct side of the pool
            feeAmount =
                PoolSwapLibrary.convertDecimalToUInt(PoolSwapLibrary.multiplyDecimalByUInt(mintingFee, amount)) /
                PoolSwapLibrary.WAD_PRECISION;
            amount = amount - feeAmount;
            pendingMintSettlementAmount += amount;
        }

        if (commitType == CommitType.LongMint) {
            (uint256 shortBalance, uint256 longBalance) = pool.balances();
            userCommit.longMintSettlement += amount;
            totalCommit.longMintSettlement += amount;
            // Add the fee to long side. This has been taken from the commit amount.
            pool.setNewPoolBalances(longBalance + feeAmount, shortBalance);
            // If we are minting from balance, this would already have thrown in `commit` if we are minting more than entitled too
        } else if (commitType == CommitType.LongBurn) {
            pendingLongBurnPoolTokens += amount;
            userCommit.longBurnPoolTokens += amount;
            totalCommit.longBurnPoolTokens += amount;
            // long burning: pull in long pool tokens from committer
            if (fromAggregateBalance) {
                // Burning from user's aggregate balance
                require(amount <= balance.longTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].longTokens -= amount;
                userCommit.balanceLongBurnPoolTokens += amount;
                // Burn from leveragedPool, because that is the official owner of the tokens before they are claimed
                pool.burnTokens(LONG_INDEX, amount, leveragedPool);
            } else {
                // Burning from user's wallet
                pool.burnTokens(LONG_INDEX, amount, msg.sender);
            }
        } else if (commitType == CommitType.ShortMint) {
            (uint256 shortBalance, uint256 longBalance) = pool.balances();
            userCommit.shortMintSettlement += amount;
            totalCommit.shortMintSettlement += amount;
            // Add the fee to short side. This has been taken from the commit amount.
            pool.setNewPoolBalances(longBalance, shortBalance + feeAmount);
            // If we are minting from balance, this would already have thrown in `commit` if we are minting more than entitled too
        } else if (commitType == CommitType.ShortBurn) {
            pendingShortBurnPoolTokens += amount;
            userCommit.shortBurnPoolTokens += amount;
            totalCommit.shortBurnPoolTokens += amount;
            if (fromAggregateBalance) {
                // Burning from user's aggregate balance
                require(amount <= balance.shortTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].shortTokens -= amount;
                userCommit.balanceShortBurnPoolTokens += amount;
                // Burn from leveragedPool, because that is the official owner of the tokens before they are claimed
                pool.burnTokens(SHORT_INDEX, amount, leveragedPool);
            } else {
                // Burning from user's wallet
                pool.burnTokens(SHORT_INDEX, amount, msg.sender);
            }
        } else if (commitType == CommitType.LongBurnShortMint) {
            pendingLongBurnPoolTokens += amount;
            userCommit.longBurnShortMintPoolTokens += amount;
            totalCommit.longBurnShortMintPoolTokens += amount;
            if (fromAggregateBalance) {
                require(amount <= balance.longTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].longTokens -= amount;
                userCommit.balanceLongBurnMintPoolTokens += amount;
                pool.burnTokens(LONG_INDEX, amount, leveragedPool);
            } else {
                pool.burnTokens(LONG_INDEX, amount, msg.sender);
            }
        } else if (commitType == CommitType.ShortBurnLongMint) {
            pendingShortBurnPoolTokens += amount;
            userCommit.shortBurnLongMintPoolTokens += amount;
            totalCommit.shortBurnLongMintPoolTokens += amount;
            if (fromAggregateBalance) {
                require(amount <= balance.shortTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].shortTokens -= amount;
                userCommit.balanceShortBurnMintPoolTokens += amount;
                pool.burnTokens(SHORT_INDEX, amount, leveragedPool);
            } else {
                pool.burnTokens(SHORT_INDEX, amount, msg.sender);
            }
        }
    }

    /**
     * @notice Commit to minting/burning long/short tokens after the next price change
     * @param args Arguments for the commit function packed into one bytes32
     *  _______________________________________________________________________________________
     * |   104 bits  |     8 bits    |        8 bits        |    8 bits    |      128 bits     |
     * |  0-padding  |  payForClaim  | fromAggregateBalance |  commitType  |  shortenedAmount  |
     *  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
     * @dev Arguments can be encoded with `L2Encoder.encodeCommitParams`
     * @dev bool payForClaim: True if user wants to pay for the commit to be claimed
     * @dev bool fromAggregateBalance: If minting, burning, or rebalancing into a delta neutral position,
     *                                 will tokens be taken from user's aggregate balance?
     * @dev CommitType commitType: Type of commit you're doing (Long vs Short, Mint vs Burn)
     * @dev uint128 shortenedAmount: Amount of settlement tokens you want to commit to minting; OR amount of pool
     *                               tokens you want to burn. Expanded to uint256 at decode time
     * @dev Emits a `CreateCommit` event on success
     */
    function commit(bytes32 args) external payable override {
        (uint256 amount, CommitType commitType, bool fromAggregateBalance, bool payForClaim) = CalldataLogic
            .decodeCommitParams(args);
        require(amount > 0, "Amount must not be zero");
        updateAggregateBalance(msg.sender);
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256 updateInterval = pool.updateInterval();
        uint256 lastPriceTimestamp = pool.lastPriceTimestamp();
        uint256 frontRunningInterval = pool.frontRunningInterval();

        uint256 appropriateUpdateIntervalId = PoolSwapLibrary.appropriateUpdateIntervalId(
            block.timestamp,
            lastPriceTimestamp,
            frontRunningInterval,
            updateInterval,
            updateIntervalId
        );
        TotalCommitment storage totalCommit = totalPoolCommitments[appropriateUpdateIntervalId];
        UserCommitment storage userCommit = userCommitments[msg.sender][appropriateUpdateIntervalId];

        if (userCommit.updateIntervalId == 0) {
            userCommit.updateIntervalId = appropriateUpdateIntervalId;
        }
        if (totalCommit.updateIntervalId == 0) {
            totalCommit.updateIntervalId = appropriateUpdateIntervalId;
        }

        uint256 length = unAggregatedCommitments[msg.sender].length;
        if (length == 0 || unAggregatedCommitments[msg.sender][length - 1] < appropriateUpdateIntervalId) {
            // Push to the array if the most recent commitment was done in a prior update interval
            unAggregatedCommitments[msg.sender].push(appropriateUpdateIntervalId);
        }

        /*
         * Below, we want to follow the "Checks, Effects, Interactions" pattern.
         * `applyCommitment` adheres to the pattern, so we must put our effects before this, and interactions after.
         * Hence, we do the storage change if `fromAggregateBalance == true` before calling `applyCommitment`, and do the interaction if `fromAggregateBalance == false` after.
         * Lastly, we call `AutoClaim::makePaidClaimRequest`, which is an external interaction (albeit with a protocol contract).
         */
        if ((commitType == CommitType.LongMint || commitType == CommitType.ShortMint) && fromAggregateBalance) {
            // Want to take away from their balance's settlement tokens
            require(amount <= userAggregateBalance[msg.sender].settlementTokens, "Insufficient settlement tokens");
            userAggregateBalance[msg.sender].settlementTokens -= amount;
        }

        applyCommitment(pool, commitType, amount, fromAggregateBalance, userCommit, totalCommit);

        if (commitType == CommitType.LongMint || (commitType == CommitType.ShortMint && !fromAggregateBalance)) {
            // minting: pull in the settlement token from the committer
            // Do not need to transfer if minting using aggregate balance tokens, since the leveraged pool already owns these tokens.
            pool.settlementTokenTransferFrom(msg.sender, leveragedPool, amount);
        }

        if (payForClaim) {
            require(msg.value != 0, "Must pay for claim");
            autoClaim.makePaidClaimRequest{value: msg.value}(msg.sender);
        } else {
            require(msg.value == 0, "msg.value must be zero");
        }

        emit CreateCommit(
            msg.sender,
            amount,
            commitType,
            appropriateUpdateIntervalId,
            fromAggregateBalance,
            payForClaim,
            mintingFee
        );
    }

    /**
     * @notice Claim user's balance. This can be done either by the user themself or by somebody else on their behalf.
     * @param user Address of the user to claim against
     * @dev Updates aggregate user balances
     * @dev Emits a `Claim` event on success
     */
    function claim(address user) external override onlyAutoClaimOrCommitter(user) {
        updateAggregateBalance(user);
        Balance memory balance = userAggregateBalance[user];
        ILeveragedPool pool = ILeveragedPool(leveragedPool);

        /* update bookkeeping *before* external calls! */
        delete userAggregateBalance[user];
        emit Claim(user);

        if (msg.sender == user && autoClaim.checkUserClaim(user, address(this))) {
            // If the committer is claiming for themself and they have a valid pending claim, clear it.
            autoClaim.withdrawUserClaimRequest(user);
        }

        if (balance.settlementTokens > 0) {
            pool.settlementTokenTransfer(user, balance.settlementTokens);
        }
        if (balance.longTokens > 0) {
            pool.poolTokenTransfer(true, user, balance.longTokens);
        }
        if (balance.shortTokens > 0) {
            pool.poolTokenTransfer(false, user, balance.shortTokens);
        }
    }

    /**
     * @notice Retrieves minting fee from each mint being left in the pool
     * @return Minting fee
     */
    function getMintingFee() public view returns (uint256) {
        return PoolSwapLibrary.convertDecimalToUInt(mintingFee);
    }

    /**
     * @notice Retrieves burning fee from each burn being left in the pool
     * @return Burning fee
     */
    function getBurningFee() public view returns (uint256) {
        return PoolSwapLibrary.convertDecimalToUInt(burningFee);
    }

    /**
     * @notice Executes every commitment specified in the list
     * @param _commits Array of `TotalCommitment`s
     * @param longTotalSupply The current running total supply of long pool tokens
     * @param shortTotalSupply The current running total supply of short pool tokens
     * @param longBalance The amount of settlement tokens in the long side of the pool
     * @param shortBalance The amount of settlement tokens in the short side of the pool
     * @return newLongTotalSupply The total supply of long pool tokens as a result of minting
     * @return newShortTotalSupply The total supply of short pool tokens as a result of minting
     * @return newLongBalance The amount of settlement tokens in the long side of the pool as a result of minting and burning
     * @return newShortBalance The amount of settlement tokens in the short side of the pool as a result of minting and burning
     */
    function executeGivenCommitments(
        TotalCommitment memory _commits,
        uint256 longTotalSupply,
        uint256 shortTotalSupply,
        uint256 longBalance,
        uint256 shortBalance
    )
        internal
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        pendingMintSettlementAmount =
            pendingMintSettlementAmount -
            totalPoolCommitments[_commits.updateIntervalId].longMintSettlement -
            totalPoolCommitments[_commits.updateIntervalId].shortMintSettlement;

        BalancesAndSupplies memory balancesAndSupplies = BalancesAndSupplies({
            newShortBalance: _commits.shortMintSettlement + shortBalance,
            newLongBalance: _commits.longMintSettlement + longBalance,
            longMintPoolTokens: 0,
            shortMintPoolTokens: 0,
            longBurnInstantMintSettlement: 0,
            shortBurnInstantMintSettlement: 0,
            totalLongBurnPoolTokens: _commits.longBurnPoolTokens + _commits.longBurnShortMintPoolTokens,
            totalShortBurnPoolTokens: _commits.shortBurnPoolTokens + _commits.shortBurnLongMintPoolTokens
        });

        // Update price before values change
        priceHistory[_commits.updateIntervalId] = Prices({
            longPrice: PoolSwapLibrary.getPrice(longBalance, longTotalSupply + pendingLongBurnPoolTokens),
            shortPrice: PoolSwapLibrary.getPrice(shortBalance, shortTotalSupply + pendingShortBurnPoolTokens)
        });

        // Amount of collateral tokens that are generated from the long burn into instant mints
        balancesAndSupplies.longBurnInstantMintSettlement = PoolSwapLibrary.getWithdrawAmountOnBurn(
            longTotalSupply,
            _commits.longBurnShortMintPoolTokens,
            longBalance,
            pendingLongBurnPoolTokens
        );
        balancesAndSupplies.newShortBalance += balancesAndSupplies.longBurnInstantMintSettlement;
        // Amount of collateral tokens that are generated from the short burn into instant mints
        balancesAndSupplies.shortBurnInstantMintSettlement = PoolSwapLibrary.getWithdrawAmountOnBurn(
            shortTotalSupply,
            _commits.shortBurnLongMintPoolTokens,
            shortBalance,
            pendingShortBurnPoolTokens
        );
        balancesAndSupplies.newLongBalance += balancesAndSupplies.shortBurnInstantMintSettlement;

        // Long Mints
        balancesAndSupplies.longMintPoolTokens = PoolSwapLibrary.getMintAmount(
            longTotalSupply, // long token total supply,
            _commits.longMintSettlement + balancesAndSupplies.shortBurnInstantMintSettlement, // Add the settlement tokens that will be generated from burning shorts for instant long mint
            longBalance, // total quote tokens in the long pool
            pendingLongBurnPoolTokens // total pool tokens commited to be burned
        );

        // Long Burns
        balancesAndSupplies.newLongBalance -= PoolSwapLibrary.getWithdrawAmountOnBurn(
            longTotalSupply,
            balancesAndSupplies.totalLongBurnPoolTokens,
            longBalance,
            pendingLongBurnPoolTokens
        );

        // Short Mints
        balancesAndSupplies.shortMintPoolTokens = PoolSwapLibrary.getMintAmount(
            shortTotalSupply, // short token total supply
            _commits.shortMintSettlement + balancesAndSupplies.longBurnInstantMintSettlement, // Add the settlement tokens that will be generated from burning longs for instant short mint
            shortBalance,
            pendingShortBurnPoolTokens
        );

        // Short Burns
        balancesAndSupplies.newShortBalance -= PoolSwapLibrary.getWithdrawAmountOnBurn(
            shortTotalSupply,
            balancesAndSupplies.totalShortBurnPoolTokens,
            shortBalance,
            pendingShortBurnPoolTokens
        );

        pendingLongBurnPoolTokens -= balancesAndSupplies.totalLongBurnPoolTokens;
        pendingShortBurnPoolTokens -= balancesAndSupplies.totalShortBurnPoolTokens;

        return (
            longTotalSupply + balancesAndSupplies.longMintPoolTokens,
            shortTotalSupply + balancesAndSupplies.shortMintPoolTokens,
            balancesAndSupplies.newLongBalance,
            balancesAndSupplies.newShortBalance
        );
    }

    /**
     * @notice Executes all commitments currently queued for the associated `LeveragedPool`
     * @dev Only callable by the associated `LeveragedPool` contract
     * @dev Emits an `ExecutedCommitsForInterval` event for each update interval processed
     * @param lastPriceTimestamp The timestamp when the last price update happened
     * @param updateInterval The number of seconds that must occur between upkeeps
     * @param longBalance The amount of settlement tokens in the long side of the pool
     * @param shortBalance The amount of settlement tokens in the short side of the pool
     * @return longTotalSupplyChange The amount of long pool tokens that have been added to the supply, passed back to LeveragedPool to mint them.
     * @return shortTotalSupplyChange The amount of short pool tokens that have been added to the supply, passed back to LeveragedPool to mint them.
     * @return newLongBalance The updated longBalance
     * @return newShortBalance The updated longBalance
     * @return lastPriceTimestamp The correct price timestamp for LeveragedPool to set. This is in case not all update intervals get upkept, we can track the time of the most recent upkept one.
     */
    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        override
        onlyPool
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint8 counter = 1;

        /*
         * (old)
         * updateIntervalId
         * |
         * |    updateIntervalId
         * |    |
         * |    |    counter
         * |    |    |
         * |    |    |              (end)
         * |    |    |              |
         * V    V    V              V
         * +----+----+----+~~~~+----+
         * |    |    |    |....|    |
         * +----+----+----+~~~~+----+
         *
         * Iterate over the sequence of possible update periods from the most
         * recent (i.e., the value of `updateIntervalId` as at the entry point
         * of this function) until the end of the queue.
         *
         * At each iteration, execute all of the (total) commitments for the
         * pool for that period and then remove them from the queue.
         *
         * In reality, this should never iterate more than once, since more than one update interval
         * should never be passed without the previous one being upkept.
         */

        CommitmentExecutionTracking memory executionTracking = CommitmentExecutionTracking({
            longTotalSupply: IERC20(tokens[LONG_INDEX]).totalSupply(),
            shortTotalSupply: IERC20(tokens[SHORT_INDEX]).totalSupply(),
            longTotalSupplyBefore: 0,
            shortTotalSupplyBefore: 0,
            _updateIntervalId: 0
        });

        executionTracking.longTotalSupplyBefore = executionTracking.longTotalSupply;
        executionTracking.shortTotalSupplyBefore = executionTracking.shortTotalSupply;

        while (counter <= MAX_ITERATIONS) {
            if (block.timestamp >= lastPriceTimestamp + updateInterval * counter) {
                // Another update interval has passed, so we have to do the nextIntervalCommit as well
                executionTracking._updateIntervalId = updateIntervalId;
                burnFeeHistory[executionTracking._updateIntervalId] = burningFee;
                (
                    executionTracking.longTotalSupply,
                    executionTracking.shortTotalSupply,
                    longBalance,
                    shortBalance
                ) = executeGivenCommitments(
                    totalPoolCommitments[executionTracking._updateIntervalId],
                    executionTracking.longTotalSupply,
                    executionTracking.shortTotalSupply,
                    longBalance,
                    shortBalance
                );
                emit ExecutedCommitsForInterval(executionTracking._updateIntervalId, burningFee);
                delete totalPoolCommitments[executionTracking._updateIntervalId];

                // counter overflowing would require an unrealistic number of update intervals
                unchecked {
                    updateIntervalId += 1;
                }
            } else {
                break;
            }
            // counter overflowing would require an unrealistic number of update intervals to be updated
            // This wouldn't fit in a block, anyway.
            unchecked {
                counter += 1;
            }
        }

        updateMintingFee(
            PoolSwapLibrary.getPrice(longBalance, executionTracking.longTotalSupply),
            PoolSwapLibrary.getPrice(shortBalance, executionTracking.shortTotalSupply)
        );

        // Subtract counter by 1 to accurately reflect how many update intervals were executed
        if (block.timestamp >= lastPriceTimestamp + updateInterval * (counter - 1)) {
            // check if finished
            // shift lastPriceTimestamp so next time the executeCommitments() will continue where it left off
            lastPriceTimestamp = lastPriceTimestamp + updateInterval * (counter - 1);
        } else {
            // Set to current time if finished every update interval
            lastPriceTimestamp = block.timestamp;
        }
        return (
            executionTracking.longTotalSupply - executionTracking.longTotalSupplyBefore,
            executionTracking.shortTotalSupply - executionTracking.shortTotalSupplyBefore,
            longBalance,
            shortBalance,
            lastPriceTimestamp
        );
    }

    function updateMintingFee(bytes16 longTokenPrice, bytes16 shortTokenPrice) private {
        bytes16 multiple = PoolSwapLibrary.multiplyBytes(longTokenPrice, shortTokenPrice);
        if (PoolSwapLibrary.compareDecimals(PoolSwapLibrary.ONE, multiple) == -1) {
            // longTokenPrice * shortTokenPrice > 1
            if (PoolSwapLibrary.compareDecimals(mintingFee, changeInterval) == -1) {
                // mintingFee < changeInterval. Prevent underflow by setting mintingFee to lowest possible value (0)
                mintingFee = 0;
            } else {
                mintingFee = PoolSwapLibrary.subtractBytes(mintingFee, changeInterval);
            }
        } else {
            // longTokenPrice * shortTokenPrice <= 1
            mintingFee = PoolSwapLibrary.addBytes(mintingFee, changeInterval);

            if (PoolSwapLibrary.compareDecimals(mintingFee, PoolSwapLibrary.MAX_MINTING_FEE) == 1) {
                // mintingFee is greater than 1 (100%).
                // We want to cap this at a theoretical max of 100%
                mintingFee = PoolSwapLibrary.MAX_MINTING_FEE;
            }
        }
    }

    /**
     * @notice Updates the aggregate balance based on the result of application
     *          of the provided (user) commitment
     * @param _commit Commitment to apply
     * @return _newLongTokens Quantity of long pool tokens post-application
     * @return _newShortTokens Quantity of short pool tokens post-application
     * @return _longBurnFee Quantity of settlement tokens taken as a fee from long burns
     * @return _shortBurnFee Quantity of settlement tokens taken as a fee from short burns
     * @return _newSettlementTokens Quantity of settlement tokens post
     *                                  application
     * @dev Wraps two (pure) library functions from `PoolSwapLibrary`
     */
    function getBalanceSingleCommitment(UserCommitment memory _commit)
        internal
        view
        returns (
            uint256 _newLongTokens,
            uint256 _newShortTokens,
            uint256 _longBurnFee,
            uint256 _shortBurnFee,
            uint256 _newSettlementTokens
        )
    {
        PoolSwapLibrary.UpdateData memory updateData = PoolSwapLibrary.UpdateData({
            longPrice: priceHistory[_commit.updateIntervalId].longPrice,
            shortPrice: priceHistory[_commit.updateIntervalId].shortPrice,
            currentUpdateIntervalId: updateIntervalId,
            updateIntervalId: _commit.updateIntervalId,
            longMintSettlement: _commit.longMintSettlement,
            longBurnPoolTokens: _commit.longBurnPoolTokens,
            shortMintSettlement: _commit.shortMintSettlement,
            shortBurnPoolTokens: _commit.shortBurnPoolTokens,
            longBurnShortMintPoolTokens: _commit.longBurnShortMintPoolTokens,
            shortBurnLongMintPoolTokens: _commit.shortBurnLongMintPoolTokens,
            burnFee: burnFeeHistory[_commit.updateIntervalId]
        });

        (_newLongTokens, _newShortTokens, _longBurnFee, _shortBurnFee, _newSettlementTokens) = PoolSwapLibrary
            .getUpdatedAggregateBalance(updateData);
    }

    /**
     * @notice Add the result of a user's most recent commit to their aggregated balance
     * @param user Address of the given user
     * @dev Updates the `userAggregateBalance` mapping by applying `BalanceUpdate`s derived from iteration over the entirety of unaggregated commitments associated with the given user
     * @dev Emits an `AggregateBalanceUpdated` event upon successful termination
     */
    function updateAggregateBalance(address user) public override {
        Balance storage balance = userAggregateBalance[user];

        BalanceUpdate memory update = BalanceUpdate({
            _updateIntervalId: updateIntervalId,
            _newLongTokensSum: 0,
            _newShortTokensSum: 0,
            _newSettlementTokensSum: 0,
            _longBurnFee: 0,
            _shortBurnFee: 0,
            _maxIterations: 0
        });

        uint256[] memory currentIntervalIds = unAggregatedCommitments[user];
        uint256 unAggregatedLength = currentIntervalIds.length;

        update._maxIterations = unAggregatedLength < MAX_ITERATIONS ? uint8(unAggregatedLength) : MAX_ITERATIONS; // casting to uint8 is safe because we know it is less than MAX_ITERATIONS, a uint8

        // Iterate from the most recent up until the current update interval
        for (uint256 i = 0; i < update._maxIterations; i++) {
            uint256 id = currentIntervalIds[i];
            if (id == 0) {
                continue;
            }
            UserCommitment memory commitment = userCommitments[user][id];

            if (commitment.updateIntervalId < updateIntervalId) {
                (
                    uint256 _newLongTokens,
                    uint256 _newShortTokens,
                    uint256 _longBurnFee,
                    uint256 _shortBurnFee,
                    uint256 _newSettlementTokens
                ) = getBalanceSingleCommitment(commitment);
                update._newLongTokensSum += _newLongTokens;
                update._newShortTokensSum += _newShortTokens;
                update._newSettlementTokensSum += _newSettlementTokens;
                update._longBurnFee += _longBurnFee;
                update._shortBurnFee += _shortBurnFee;
                delete userCommitments[user][id];
                uint256[] storage commitmentIds = unAggregatedCommitments[user];
                if (unAggregatedLength > MAX_ITERATIONS && i < commitmentIds.length - 1 && commitmentIds.length > 1) {
                    // We only enter this branch if our iterations are capped (i.e. we do not delete the array after the loop)
                    // Order doesn't actually matter in this array, so we can just put the last element into this index
                    commitmentIds[i] = commitmentIds[commitmentIds.length - 1];
                    commitmentIds.pop();
                } else {
                    commitmentIds.pop();
                }
            } else {
                // Clear them now that they have been accounted for in the balance
                userCommitments[user][id].balanceLongBurnPoolTokens = 0;
                userCommitments[user][id].balanceShortBurnPoolTokens = 0;
                userCommitments[user][id].balanceLongBurnMintPoolTokens = 0;
                userCommitments[user][id].balanceShortBurnMintPoolTokens = 0;
                // This commitment wasn't ready to be completely added to the balance, so copy it over into the new ID array
                if (unAggregatedLength <= MAX_ITERATIONS) {
                    storageArrayPlaceHolder.push(currentIntervalIds[i]);
                }
            }
        }

        if (unAggregatedLength <= MAX_ITERATIONS) {
            // We got through all update intervals, so we can replace all unaggregated update interval IDs
            delete unAggregatedCommitments[user];
            unAggregatedCommitments[user] = storageArrayPlaceHolder;
            delete storageArrayPlaceHolder;
        }

        // Add new tokens minted, and remove the ones that were burnt from this balance
        balance.longTokens += update._newLongTokensSum;
        balance.shortTokens += update._newShortTokensSum;
        balance.settlementTokens += update._newSettlementTokensSum;

        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (uint256 shortBalance, uint256 longBalance) = pool.balances();
        pool.setNewPoolBalances(longBalance + update._longBurnFee, shortBalance + update._shortBurnFee);

        emit AggregateBalanceUpdated(user);
    }

    /**
     * @return which update interval ID a commit would be placed into if made now
     * @dev Calls PoolSwapLibrary::appropriateUpdateIntervalId
     */
    function getAppropriateUpdateIntervalId() external view override returns (uint128) {
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        return
            uint128(
                PoolSwapLibrary.appropriateUpdateIntervalId(
                    block.timestamp,
                    pool.lastPriceTimestamp(),
                    pool.frontRunningInterval(),
                    pool.updateInterval(),
                    updateIntervalId
                )
            );
    }

    /**
     * @notice A copy of `updateAggregateBalance` that returns the aggregated balance without updating it
     * @param user Address of the given user
     * @return Associated `Balance` for the given user after aggregation
     */
    function getAggregateBalance(address user) external view override returns (Balance memory) {
        Balance memory _balance = userAggregateBalance[user];

        BalanceUpdate memory update = BalanceUpdate({
            _updateIntervalId: updateIntervalId,
            _newLongTokensSum: 0,
            _newShortTokensSum: 0,
            _newSettlementTokensSum: 0,
            _longBurnFee: 0,
            _shortBurnFee: 0,
            _maxIterations: 0
        });

        uint256[] memory currentIntervalIds = unAggregatedCommitments[user];
        uint256 unAggregatedLength = currentIntervalIds.length;

        update._maxIterations = unAggregatedLength < MAX_ITERATIONS ? uint8(unAggregatedLength) : MAX_ITERATIONS; // casting to uint8 is safe because we know it is less than MAX_ITERATIONS, a uint8

        // Iterate from the most recent up until the current update interval
        for (uint256 i = 0; i < update._maxIterations; i++) {
            uint256 id = currentIntervalIds[i];
            if (id == 0) {
                continue;
            }
            UserCommitment memory commitment = userCommitments[user][id];

            /* If the update interval of commitment has not yet passed, we still
            want to deduct burns from the balance from a user's balance.
            Therefore, this should happen outside of the if block below.*/
            if (commitment.updateIntervalId < updateIntervalId) {
                (
                    uint256 _newLongTokens,
                    uint256 _newShortTokens,
                    ,
                    ,
                    uint256 _newSettlementTokens
                ) = getBalanceSingleCommitment(commitment);
                update._newLongTokensSum += _newLongTokens;
                update._newShortTokensSum += _newShortTokens;
                update._newSettlementTokensSum += _newSettlementTokens;
            }
        }

        // Add new tokens minted, and remove the ones that were burnt from this balance
        _balance.longTokens += update._newLongTokensSum;
        _balance.shortTokens += update._newShortTokensSum;
        _balance.settlementTokens += update._newSettlementTokensSum;

        return _balance;
    }

    /**
     * @notice Sets the settlement token address and the address of the associated `LeveragedPool` contract to the provided values
     * @param _leveragedPool Address of the pool to use
     * @dev Only callable by the associated `PoolFactory` contract
     * @dev Throws if either address are null
     * @dev Emits a `SettlementAndPoolChanged` event on success
     */
    function setPool(address _leveragedPool) external override onlyFactory {
        require(_leveragedPool != address(0), "Leveraged pool address cannot be 0 address");

        leveragedPool = _leveragedPool;
        tokens = ILeveragedPool(leveragedPool).poolTokens();
    }

    /**
     * @notice Sets the burning fee to be applied to future burn commitments indefinitely
     * @param _burningFee The new burning fee
     * @dev Converts `_burningFee` to a `bytes16` to be compatible with arithmetic library
     * @dev Emits a `BurningFeeSet` event on success
     */
    function setBurningFee(uint256 _burningFee) external override onlyFeeController {
        burningFee = PoolSwapLibrary.convertUIntToDecimal(_burningFee);
        require(burningFee < PoolSwapLibrary.MAX_BURNING_FEE, "Burning fee >= 10%");
        emit BurningFeeSet(_burningFee);
    }

    /**
     * @notice Sets the minting fee to be applied to future burn commitments indefinitely
     * @param _mintingFee The new minting fee
     * @dev Converts `_mintingFee` to a `bytes16` to be compatible with arithmetic library
     * @dev Emits a `MintingFeeSet` event on success
     */
    function setMintingFee(uint256 _mintingFee) external override onlyFeeController {
        mintingFee = PoolSwapLibrary.convertUIntToDecimal(_mintingFee);
        require(mintingFee < PoolSwapLibrary.MAX_MINTING_FEE, "Minting fee >= 100%");
        emit MintingFeeSet(_mintingFee);
    }

    /**
     * @notice Sets the change interval used to update the minting fee every update interval
     * @param _changeInterval The new change interval
     * @dev Converts `_changeInterval` to a `bytes16` to be compatible with arithmetic library TODO UPDATE
     * @dev Emits a `ChangeIntervalSet` event on success
     */
    function setChangeInterval(uint256 _changeInterval) external override onlyFeeController {
        changeInterval = PoolSwapLibrary.convertUIntToDecimal(_changeInterval);
        emit ChangeIntervalSet(_changeInterval);
    }

    function setFeeController(address _feeController) external override {
        require(msg.sender == governance || msg.sender == feeController, "Cannot set feeController");
        feeController = _feeController;
        emit FeeControllerSet(_feeController);
    }

    /**
     * @notice Pauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function pause() external override onlyInvariantCheckContract {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function unpause() external override onlyGov {
        paused = false;
        emit Unpaused();
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IPoolFactory.sol";
import "../interfaces/ILeveragedPool.sol";
import "../interfaces/IPoolCommitter.sol";
import "../interfaces/IERC20DecimalsWrapper.sol";
import "../interfaces/IAutoClaim.sol";
import "../interfaces/ITwoStepGovernance.sol";
import "./LeveragedPool.sol";
import "./PoolToken.sol";
import "./PoolKeeper.sol";
import "./PoolCommitter.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title The pool factory contract
contract PoolFactory is IPoolFactory, ITwoStepGovernance {
    // #### Globals
    address public immutable pairTokenBaseAddress;
    address public immutable poolBaseAddress;
    IPoolKeeper public poolKeeper;
    address public immutable poolCommitterBaseAddress;

    address public autoClaim;
    address public invariantCheck;

    // Contract address which has governance permissions
    address public override governance;
    bool public override governanceTransferInProgress;
    address public override provisionalGovernance;
    // Default fee, annualised; Fee value as a decimal multiplied by 10^18. For example, 50% is represented as 0.5 * 10^18
    uint256 public fee;
    // Percent of fees that go to secondary fee address if applicable.
    uint256 public secondaryFeeSplitPercent = 10;

    // This is required because we must pass along *some* value for decimal
    // precision to the base pool tokens as we use the Cloneable pattern
    uint8 constant DEFAULT_NUM_DECIMALS = 18;
    uint8 constant MAX_DECIMALS = DEFAULT_NUM_DECIMALS;
    // Considering leap year thus using 365.2425 days per year
    uint32 constant DAYS_PER_LEAP_YEAR = 365.2425 days;
    // Contract address to receive protocol fees
    address public feeReceiver;

    /**
     * @notice Format: Pool counter => pool address
     */
    mapping(uint256 => address) public override pools;
    uint256 public override numPools;

    /**
     * @notice Format: Pool address => validity
     */
    mapping(address => bool) public override isValidPool;

    /**
     * @notice Format: PoolCommitter address => validity
     */
    mapping(address => bool) public override isValidPoolCommitter;

    // #### Modifiers
    modifier onlyGov() {
        require(msg.sender == governance, "msg.sender not governance");
        _;
    }

    // #### Functions
    constructor(address _feeReceiver, address _governance) {
        require(_feeReceiver != address(0), "Address cannot be null");
        require(_governance != address(0), "Address cannot be null");
        governance = _governance;

        // Deploy base contracts
        PoolToken pairTokenBase = new PoolToken(DEFAULT_NUM_DECIMALS);
        pairTokenBaseAddress = address(pairTokenBase);
        LeveragedPool poolBase = new LeveragedPool();
        poolBaseAddress = address(poolBase);
        PoolCommitter poolCommitterBase = new PoolCommitter();
        poolCommitterBaseAddress = address(poolCommitterBase);

        feeReceiver = _feeReceiver;

        /* initialise base PoolToken template (with dummy values) */
        pairTokenBase.initialize(address(poolBase), "base", "BASE", 8);

        /* initialise base LeveragedPool template (with dummy values) */
        ILeveragedPool.Initialization memory dummyInitialization = ILeveragedPool.Initialization({
            _owner: address(this),
            _keeper: address(this),
            _oracleWrapper: address(this),
            _settlementEthOracle: address(this),
            _longToken: address(pairTokenBase),
            _shortToken: address(pairTokenBase),
            _poolCommitter: address(poolCommitterBase),
            _invariantCheck: address(this),
            _poolName: "base",
            _frontRunningInterval: 0,
            _updateInterval: 1,
            _fee: 0,
            _leverageAmount: 1,
            _feeAddress: address(this),
            _secondaryFeeAddress: address(this),
            _settlementToken: address(this),
            _secondaryFeeSplitPercent: 0
        });
        poolBase.initialize(dummyInitialization);
        /* initialise base PoolCommitter template (with dummy values) */
        poolCommitterBase.initialize(address(this), address(this), address(this), governance, governance, 0, 0, 0);
    }

    /**
     * @notice Deploy a leveraged pool and its committer/pool tokens with given parameters
     * @notice Rebasing tokens are not supported and will break functionality
     * @param deploymentParameters Deployment parameters of the market. Some may be reconfigurable.
     * @return Address of the created pool
     * @dev Throws if pool keeper is null
     * @dev Throws if deployer does not own the oracle wrapper
     * @dev Throws if leverage amount is invalid
     * @dev Throws if decimal precision is too high (i.e., greater than `MAX_DECIMALS`)
     * @dev The IOracleWrapper declares a `deployer` variable, this is used here to confirm that the pool which uses said oracle wrapper is indeed
     *      the intended address. This is to prevent a griefing attack in which someone uses the same oracle wrapper with the same parameters *before* the genuine deployer.
     */
    function deployPool(PoolDeployment calldata deploymentParameters) external override returns (address) {
        address _poolKeeper = address(poolKeeper);
        require(_poolKeeper != address(0), "PoolKeeper not set");
        require(autoClaim != address(0), "AutoClaim not set");
        require(invariantCheck != address(0), "InvariantCheck not set");
        require(
            IOracleWrapper(deploymentParameters.oracleWrapper).deployer() == msg.sender,
            "Deployer must be oracle wrapper owner"
        );
        require(deploymentParameters.leverageAmount != 0, "Leveraged amount cannot equal 0");
        require(
            IERC20DecimalsWrapper(deploymentParameters.settlementToken).decimals() <= MAX_DECIMALS,
            "Decimal precision too high"
        );

        bytes32 uniquePoolHash = keccak256(
            abi.encode(
                deploymentParameters.frontRunningInterval,
                deploymentParameters.updateInterval,
                deploymentParameters.leverageAmount,
                deploymentParameters.settlementToken,
                deploymentParameters.oracleWrapper
            )
        );

        PoolCommitter poolCommitter = PoolCommitter(
            Clones.cloneDeterministic(poolCommitterBaseAddress, uniquePoolHash)
        );

        address poolCommitterAddress = address(poolCommitter);
        poolCommitter.initialize(
            address(this),
            autoClaim,
            governance,
            deploymentParameters.feeController,
            invariantCheck,
            deploymentParameters.mintingFee,
            deploymentParameters.burningFee,
            deploymentParameters.changeInterval
        );

        LeveragedPool pool = LeveragedPool(Clones.cloneDeterministic(poolBaseAddress, uniquePoolHash));
        address _pool = address(pool);
        emit DeployPool(_pool, address(poolCommitter), deploymentParameters.poolName);

        string memory leverage = Strings.toString(deploymentParameters.leverageAmount);

        ILeveragedPool.Initialization memory initialization = ILeveragedPool.Initialization({
            _owner: governance, // governance is the owner of pools -- if this changes, `onlyGov` breaks
            _keeper: _poolKeeper,
            _oracleWrapper: deploymentParameters.oracleWrapper,
            _settlementEthOracle: deploymentParameters.settlementEthOracle,
            _longToken: deployPairToken(_pool, leverage, deploymentParameters, "L-"),
            _shortToken: deployPairToken(_pool, leverage, deploymentParameters, "S-"),
            _poolCommitter: poolCommitterAddress,
            _invariantCheck: invariantCheck,
            _poolName: string(abi.encodePacked(leverage, "-", deploymentParameters.poolName)),
            _frontRunningInterval: deploymentParameters.frontRunningInterval,
            _updateInterval: deploymentParameters.updateInterval,
            _fee: (fee * deploymentParameters.updateInterval) / (DAYS_PER_LEAP_YEAR),
            _leverageAmount: deploymentParameters.leverageAmount,
            _feeAddress: feeReceiver,
            _secondaryFeeAddress: msg.sender,
            _settlementToken: deploymentParameters.settlementToken,
            _secondaryFeeSplitPercent: secondaryFeeSplitPercent
        });

        // approve the settlement token on the pool committer to finalise linking
        // this also stores the pool address in the committer
        // finalise pool setup
        pool.initialize(initialization);
        IPoolCommitter(poolCommitterAddress).setPool(_pool);
        emit DeployCommitter(
            poolCommitterAddress,
            deploymentParameters.settlementToken,
            _pool,
            deploymentParameters.changeInterval,
            deploymentParameters.feeController
        );

        poolKeeper.newPool(_pool);
        pools[numPools] = _pool;
        // numPools overflowing would require an unrealistic number of markets
        unchecked {
            numPools++;
        }
        isValidPool[_pool] = true;
        isValidPoolCommitter[address(poolCommitter)] = true;
        return _pool;
    }

    /**
     * @notice Deploy a contract for pool tokens
     * @param pool The pool address, owner of the Pool Token
     * @param leverage Amount of leverage for pool
     * @param deploymentParameters Deployment parameters for parent function
     * @param direction Long or short token, L- or S-
     * @return Address of the pool token
     */
    function deployPairToken(
        address pool,
        string memory leverage,
        PoolDeployment memory deploymentParameters,
        string memory direction
    ) internal returns (address) {
        string memory poolNameAndSymbol = string(abi.encodePacked(leverage, direction, deploymentParameters.poolName));
        uint8 settlementDecimals = IERC20DecimalsWrapper(deploymentParameters.settlementToken).decimals();
        bytes32 uniqueTokenHash = keccak256(
            abi.encode(
                deploymentParameters.leverageAmount,
                deploymentParameters.settlementToken,
                deploymentParameters.oracleWrapper,
                direction
            )
        );

        PoolToken pairToken = PoolToken(Clones.cloneDeterministic(pairTokenBaseAddress, uniqueTokenHash));
        pairToken.initialize(pool, poolNameAndSymbol, poolNameAndSymbol, settlementDecimals);
        return address(pairToken);
    }

    /**
     * @notice Sets the address of the associated `PoolKeeper` contract
     * @param _poolKeeper Address of the `PoolKeeper`
     * @dev Throws if provided address is null
     * @dev Only callable by the owner
     * @dev Emits a `PoolKeeperChanged` event on success
     */
    function setPoolKeeper(address _poolKeeper) external override onlyGov {
        require(_poolKeeper != address(0), "address cannot be null");
        poolKeeper = IPoolKeeper(_poolKeeper);
        emit PoolKeeperChanged(_poolKeeper);
    }

    /**
     * @notice Sets the address of the associated `AutoClaim` contract
     * @param _autoClaim Address of the `AutoClaim`
     * @dev Throws if provided address is null
     * @dev Only callable by the owner
     */
    function setAutoClaim(address _autoClaim) external override onlyGov {
        require(_autoClaim != address(0), "address cannot be null");
        autoClaim = _autoClaim;
        emit AutoClaimChanged(_autoClaim);
    }

    /**
     * @notice Sets the address of the associated `InvariantCheck` contract
     * @param _invariantCheck Address of the `InvariantCheck`
     * @dev Throws if provided address is null
     * @dev Only callable by the owner
     */
    function setInvariantCheck(address _invariantCheck) external override onlyGov {
        require(_invariantCheck != address(0), "address cannot be null");
        invariantCheck = _invariantCheck;
        emit InvariantCheckChanged(_invariantCheck);
    }

    /**
     * @notice Sets the primary fee receiver of deployed Leveraged pools.
     * @param _feeReceiver address of fee receiver
     * @dev Only callable by the owner of this contract
     * @dev This fuction does not change anything for already deployed pools, only pools deployed after the change
     * @dev Emits a `FeeReceiverChanged` event on success
     */
    function setFeeReceiver(address _feeReceiver) external override onlyGov {
        require(_feeReceiver != address(0), "address cannot be null");
        feeReceiver = _feeReceiver;
        emit FeeReceiverChanged(_feeReceiver);
    }

    /**
     * @notice Sets the proportion of fees to be split to the nominated secondary fees recipient
     * @param newFeePercent Proportion of fees to split
     * @dev Only callable by the owner of this contract
     * @dev Throws if `newFeePercent` exceeds 100
     * @dev Emits a `SecondaryFeeSplitChanged` event on success
     */
    function setSecondaryFeeSplitPercent(uint256 newFeePercent) external override onlyGov {
        require(newFeePercent <= 100, "Secondary fee split cannot exceed 100%");
        secondaryFeeSplitPercent = newFeePercent;
        emit SecondaryFeeSplitChanged(newFeePercent);
    }

    /**
     * @notice Set the yearly fee amount. The max yearly fee is 10%
     * @dev This is a percentage in WAD; multiplied by 10^18 e.g. 5% is 0.05 * 10^18
     * @param _fee The fee amount as a percentage
     * @dev Throws if fee is greater than 10%
     * @dev Emits a `FeeChanged` event on success
     */
    function setFee(uint256 _fee) external override onlyGov {
        require(_fee <= 0.1e18, "Fee cannot be > 10%");
        fee = _fee;
        emit FeeChanged(_fee);
    }

    /**
     * @notice Starts to transfer governance of the pool. The new governance
     *          address must call `claimGovernance` in order for this to take
     *          effect. Until this occurs, the existing governance address
     *          remains in control of the pool.
     * @param _governance New address of the governance of the pool
     * @dev First step of the two-step governance transfer process
     * @dev Sets the governance transfer flag to true
     * @dev See `claimGovernance`
     */
    function transferGovernance(address _governance) external override onlyGov {
        require(_governance != governance, "New governance address cannot be same as old governance address");
        require(_governance != address(0), "Governance address cannot be 0 address");
        provisionalGovernance = _governance;
        governanceTransferInProgress = true;
        emit ProvisionalGovernanceChanged(_governance);
    }

    /**
     * @notice Completes transfer of governance by actually changing permissions
     *          over the pool.
     * @dev Second and final step of the two-step governance transfer process
     * @dev See `transferGovernance`
     * @dev Sets the governance transfer flag to false
     * @dev After a successful call to this function, the actual governance
     *      address and the provisional governance address MUST be equal.
     */
    function claimGovernance() external override {
        require(governanceTransferInProgress, "No governance change active");
        address _provisionalGovernance = provisionalGovernance;
        require(msg.sender == _provisionalGovernance, "Not provisional governor");
        address oldGovernance = governance; /* for later event emission */
        governance = _provisionalGovernance;
        governanceTransferInProgress = false;
        emit GovernanceAddressChanged(oldGovernance, _provisionalGovernance);
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IPoolKeeper.sol";
import "../interfaces/IOracleWrapper.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/ILeveragedPool.sol";
import "../interfaces/IERC20DecimalsWrapper.sol";
import "../interfaces/IKeeperRewards.sol";

import "../libraries/CalldataLogic.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

/// @title The manager contract for multiple markets and the pools in them
/// @dev Currently, this contract estimates the best keeper rewards in a way that is best suited for Ethereum L1.
/// @dev It assumes an approximate block time of 13 seconds, and an Ethereum-like gas system.
/// @dev This code was also written with Arbitrum deployment in mind, meaning there exists no `block.basefee`, and no arbitrum gas price oracle.
/// @dev It has another large drawback in that it is not possible to calculate the cost of the current transaction Arbitrum, given that the cost is largely determined by L1 calldata cost.
/// @dev Because of this, the reward calculation is an rough "good enough" estimation.
contract PoolKeeper is IPoolKeeper, Ownable {
    // #### Global variables
    /**
     * @notice Format: Pool address => last executionPrice
     */
    mapping(address => int256) public executionPrice;

    IPoolFactory public immutable factory;
    // The KeeperRewards contract permissioned to pay out pool upkeep rewards
    address public override keeperRewards;

    uint256 public gasPrice = 10 gwei;

    /**
     * @notice Ensures that the caller is the associated `PoolFactory` contract
     */
    modifier onlyFactory() {
        require(msg.sender == address(factory), "Caller not factory");
        _;
    }

    // #### Functions
    constructor(address _factory) {
        require(_factory != address(0), "Factory cannot be 0 address");
        factory = IPoolFactory(_factory);
    }

    /**
     * @notice When a pool is created, this function is called by the factory to initiate price trackings
     * @param _poolAddress The address of the newly-created pools
     * @dev Only callable by the associated `PoolFactory` contract
     */
    function newPool(address _poolAddress) external override onlyFactory {
        IOracleWrapper(ILeveragedPool(_poolAddress).oracleWrapper()).poll();
        int256 firstPrice = ILeveragedPool(_poolAddress).getOraclePrice();
        require(firstPrice > 0, "First price is non-positive");
        emit PoolAdded(_poolAddress, firstPrice);
        executionPrice[_poolAddress] = firstPrice;
    }

    /**
     * @notice Check if upkeep is required
     * @param _pool The address of the pool to upkeep
     * @return Whether or not upkeep is needed for this single pool
     */
    function isUpkeepRequiredSinglePool(address _pool) public view override returns (bool) {
        if (!factory.isValidPool(_pool)) {
            return false;
        }

        // The update interval has passed
        return ILeveragedPool(_pool).intervalPassed();
    }

    /**
     * @notice Checks multiple pools if any of them need updating
     * @param _pools Array of pools to check
     * @return Whether or not at least one pool needs upkeeping
     * @dev Iterates over the provided array of pool addresses
     */
    function checkUpkeepMultiplePools(address[] calldata _pools) external view override returns (bool) {
        uint256 poolsLength = _pools.length;
        for (uint256 i = 0; i < poolsLength; i++) {
            if (isUpkeepRequiredSinglePool(_pools[i])) {
                // One has been found that requires upkeeping
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Called by keepers to perform an update on a single pool
     * @param _pool Address of the pool to be upkept
     * @dev Tracks gas usage via `gasleft` accounting and uses this to inform
     *          keeper payment
     * @dev Catches any failure of the underlying `pool.poolUpkeep` call
     * @dev Emits a `KeeperPaid` event if the underlying call to `pool.payKeeperFromBalances` succeeds
     * @dev Emits a `KeeperPaymentError` event otherwise
     */
    function performUpkeepSinglePool(address _pool) public override {
        uint256 startGas = gasleft();

        // validate the pool, check that the interval time has passed
        if (!isUpkeepRequiredSinglePool(_pool)) {
            return;
        }

        /* update SMA oracle, does nothing for spot oracles */
        IOracleWrapper poolOracleWrapper = IOracleWrapper(ILeveragedPool(_pool).oracleWrapper());

        try poolOracleWrapper.poll() {} catch Error(string memory reason) {
            emit PoolUpkeepError(_pool, reason);
        }

        (
            int256 latestPrice,
            bytes memory data,
            uint256 savedPreviousUpdatedTimestamp,
            uint256 updateInterval
        ) = ILeveragedPool(_pool).getUpkeepInformation();

        // Start a new round
        // Get price in WAD format
        int256 lastExecutionPrice = executionPrice[_pool];

        /* This allows us to still batch multiple calls to
         * executePriceChange, even if some are invalid
         * without reverting the entire transaction */
        try ILeveragedPool(_pool).poolUpkeep(lastExecutionPrice, latestPrice) {
            executionPrice[_pool] = latestPrice;
            // If poolUpkeep is successful, refund the keeper for their gas costs
            emit UpkeepSuccessful(_pool, data, lastExecutionPrice, latestPrice);
        } catch Error(string memory reason) {
            // If poolUpkeep fails for any other reason, emit event
            emit PoolUpkeepError(_pool, reason);
        }

        uint256 gasSpent = startGas - gasleft();
        uint256 reward;
        // Emit events depending on whether or not the reward was actually paid
        if (
            IKeeperRewards(keeperRewards).payKeeper(
                msg.sender,
                _pool,
                gasPrice,
                gasSpent,
                savedPreviousUpdatedTimestamp,
                updateInterval
            ) > 0
        ) {
            emit KeeperPaid(_pool, msg.sender, reward);
        } else {
            emit KeeperPaymentError(_pool, msg.sender, reward);
        }
    }

    /**
     * @notice Called by keepers to perform an update on multiple pools
     * @param pools Addresses of each pool to upkeep
     * @dev Iterates over the provided array
     * @dev Essentially wraps calls to `performUpkeepSinglePool`
     */
    function performUpkeepMultiplePools(address[] calldata pools) external override {
        uint256 poolsLength = pools.length;
        for (uint256 i = 0; i < poolsLength; i++) {
            performUpkeepSinglePool(pools[i]);
        }
    }

    /**
     * @notice Changes the KeeperRewards contract, used for calculating and executing rewards for calls to upkeep functions
     * @param _keeperRewards The new KeeperRewards contract
     * @dev Only callable by the contract owner
     * @dev emits KeeperRewardsSet when the addresss is successfuly changed
     */
    function setKeeperRewards(address _keeperRewards) external override onlyOwner {
        require(_keeperRewards != address(0), "KeeperRewards cannot be 0 address");
        address oldKeeperRewards = keeperRewards;
        keeperRewards = _keeperRewards;
        emit KeeperRewardsSet(oldKeeperRewards, _keeperRewards);
    }

    /**
     * @notice Called by keepers to perform an update on multiple pools
     * @param pools A tightly packed bytes array of LeveragedPool addresses to be upkept
     *  __________________________________________________
     * |   20 bytes       20 bytes       20 bytes     ... |
     * | pool address | pool address | pool address | ... |
     *  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
     * @dev Arguments can be encoded with `L2Encoder.encodeAddressArray`
     * @dev Will revert if the bytes array is a correct length (some multiple of 20 bytes)
     */
    function performUpkeepMultiplePoolsPacked(bytes calldata pools) external override {
        require(pools.length % CalldataLogic.ADDRESS_LENGTH == 0, "Data must only include addresses");
        uint256 numPools = pools.length / CalldataLogic.ADDRESS_LENGTH;
        uint256 offset;
        assembly {
            offset := pools.offset
        }
        for (uint256 i = 0; i < numPools; ) {
            performUpkeepSinglePool(CalldataLogic.getAddressAtOffset(offset));
            unchecked {
                offset += CalldataLogic.ADDRESS_LENGTH;
                ++i;
            }
        }
    }

    /**
     * @notice Sets the gas price to be used in compensating keepers for successful upkeep
     * @param _price Price (in ETH) per unit gas
     * @dev Only callable by the owner
     * @dev This function is only necessary due to the L2 deployment of Pools -- in reality, it should be `BASEFEE`
     * @dev Emits a `GasPriceChanged` event on success
     */
    function setGasPrice(uint256 _price) external override onlyOwner {
        gasPrice = _price;
        emit GasPriceChanged(_price);
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../vendors/ERC20_Cloneable.sol";
import "../interfaces/IPoolToken.sol";

/// @title The pool token; used for ownership/shares of the underlying tokens of the long/short pool
/// @dev ERC_20_Cloneable contains onlyOwner code implemented for use with the cloneable setup
contract PoolToken is ERC20_Cloneable, IPoolToken {
    // #### Functions
    constructor(uint8 _decimals) ERC20_Cloneable("BASE_TOKEN", "BASE", _decimals) {}

    /**
     * @notice Mints pool tokens
     * @param account Account to mint pool tokens to
     * @param amount Pool tokens to mint
     */
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /**
     * @notice Burns pool tokens
     * @param account Account to burn pool tokens from
     * @param amount Pool tokens to burn
     */
    function burn(address account, uint256 amount) external override onlyOwner {
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

interface IAutoClaim {
    /**
     * @notice Creates a notification when an auto-claim is requested
     * @param user The user who made a request
     * @param poolCommitter The PoolCommitter instance in which the commit was made
     * @param updateIntervalId The update interval ID that the corresponding commitment was allocated for
     * @param reward The reward for the auto-claim
     */
    event PaidClaimRequest(
        address indexed user,
        address indexed poolCommitter,
        uint256 indexed updateIntervalId,
        uint256 reward
    );

    /**
     * @notice Creates a notification when an auto-claim request is updated. i.e. When another commit is added and reward is incremented.
     * @param user The user whose request got updated
     * @param poolCommitter The PoolCommitter instance in which the commits were made
     * @param newReward The new total reward for the auto-claim
     */
    event PaidClaimRequestUpdate(address indexed user, address indexed poolCommitter, uint256 indexed newReward);

    /**
     * @notice Creates a notification when an auto-claim request is executed
     * @param user The user whose request got executed
     * @param poolCommitter The PoolCommitter instance in which the original commit was made
     * @param reward The reward for the auto-claim
     */
    event PaidRequestExecution(address indexed user, address indexed poolCommitter, uint256 indexed reward);

    /**
     * @notice Creates a notification when an auto-claim request is withdrawn
     * @param user The user whose request got withdrawn
     * @param poolCommitter The PoolCommitter instance in which the original commit was made
     */
    event RequestWithdrawn(address indexed user, address indexed poolCommitter);

    struct ClaimRequest {
        uint128 updateIntervalId; // The update interval during which a user requested a claim.
        uint256 reward; // The amount of ETH in wei that was given by the user to pay for upkeep
    }

    /**
     * @notice Pay for your commit to be claimed. This means that a willing participant can claim on `user`'s behalf when the current update interval ends.
     * @dev Only callable by this contract's associated PoolCommitter instance. This prevents griefing. Consider a permissionless function, where a user can claim that somebody else wants to auto claim when they do not.
     * @param user The user who wants to autoclaim.
     */
    function makePaidClaimRequest(address user) external payable;

    /**
     * @notice Claim on the behalf of a user who has requests to have their commit automatically claimed by a keeper.
     * @param user The user who requested an autoclaim.
     * @param poolCommitterAddress The PoolCommitter address within which the user's claim will be executed
     */
    function paidClaim(address user, address poolCommitterAddress) external;

    function multiPaidClaimMultiplePoolCommitters(bytes memory args1, bytes memory args2) external;

    /**
     * @notice Call `paidClaim` for multiple users, in a single PoolCommitter.
     * @param args Arguments for the function packed into a bytes array. Generated with L2Encoder.encode
     * -------------------------------------------------------------------------------------------------------------------------
     * |          20 bytes          |          20 bytes         |          20 bytes          |          20 bytes         | ... |
     * |      0th user address      |     1st user address      |      3rd user address      |      4th user address     | ... |
     * -------------------------------------------------------------------------------------------------------------------------
     * @param poolCommitterAddress The PoolCommitter address within which you would like to claim for the respective user
     * @dev poolCommitterAddress should be the PoolCommitter where the all supplied user addresses requested an auto claim
     */
    function multiPaidClaimSinglePoolCommitter(bytes calldata args, address poolCommitterAddress) external;

    /**
     * @notice If a user's claim request never gets executed (due to not high enough of a reward), or they change their minds, enable them to withdraw their request.
     * @param poolCommitter The PoolCommitter for which the user's commit claim is to be withdrawn.
     */
    function withdrawClaimRequest(address poolCommitter) external;

    /**
     * @notice When the user claims themself through poolCommitter, you want the user to be able to withdraw their request through the poolCommitter as msg.sender
     * @param user The user who will have their claim request withdrawn.
     */
    function withdrawUserClaimRequest(address user) external;

    /**
     * @notice Check the validity of a user's claim request for a given pool committer.
     * @return true if the claim request can be executed.
     * @param user The user whose claim request will be checked.
     * @param poolCommitter The pool committer in which to look for a user's claim request.
     */
    function checkUserClaim(address user, address poolCommitter) external view returns (bool);

    /**
     * @return true if the given claim request can be executed.
     * @dev A claim request can be executed only if one exists and is from an update interval that has passed.
     * @param request The ClaimRequest object to be checked.
     * @param currentUpdateIntervalId The current update interval. Used to compare to the update interval of the ClaimRequest.
     */
    function checkClaim(ClaimRequest memory request, uint256 currentUpdateIntervalId) external pure returns (bool);
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The decimals interface for extending the ERC20 interface
interface IERC20DecimalsWrapper {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The contract factory for the keeper and pool contracts. Utilizes minimal clones to keep gas costs low
interface IInvariantCheck {
    event InvariantsHold();
    event InvariantsFail(string message);

    /**
     * @notice Checks all invariants, and pauses all contracts if
     *         any invariant does not hold.
     */
    function checkInvariants(address pool) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

interface IKeeperRewards {
    /**
     * @notice Creates a notification of a failed pool update
     * @param pool The pool that failed to update
     * @param reason The reason for the error
     */
    event PoolUpkeepError(address indexed pool, string reason);

    function payKeeper(
        address _keeper,
        address _pool,
        uint256 _gasPrice,
        uint256 _gasSpent,
        uint256 _savedPreviousUpdatedTimestamp,
        uint256 _updateInterval
    ) external returns (uint256);
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The pool controller contract interface
interface ILeveragedPool {
    // Initialisation parameters for new market
    struct Initialization {
        address _owner; // Owner of the contract
        address _keeper; // The address of the PoolKeeper contract
        address _oracleWrapper; // The oracle wrapper for the derivative price feed
        address _settlementEthOracle; // The oracle wrapper for the SettlementToken/ETH price feed
        address _longToken; // Address of the long pool token
        address _shortToken; // Address of the short pool token
        address _poolCommitter; // Address of the PoolCommitter contract
        address _invariantCheck; // Address of the InvariantCheck contract
        string _poolName; // The pool identification name
        uint32 _frontRunningInterval; // The minimum number of seconds that must elapse before a commit is forced to wait until the next interval
        uint32 _updateInterval; // The minimum number of seconds that must elapse before a commit can be executed
        uint16 _leverageAmount; // The amount of exposure to price movements for the pool
        uint256 _fee; // The fund movement fee. This amount is extracted from the deposited asset with every update and sent to the fee address. Given as the decimal * 10 ^ 18. For example, 60% fee is 0.6 * 10 ^ 18
        address _feeAddress; // The address that the fund movement fee is sent to
        address _secondaryFeeAddress; // The address of fee recieved by third party deployers
        address _settlementToken; //  The digital asset that the pool accepts. Must have a decimals() function
        uint256 _secondaryFeeSplitPercent; // Percent of fees that go to secondary fee address if it exists
    }

    // #### Events
    /**
     * @notice Creates a notification when the pool is setup and ready for use
     * @param longToken The address of the LONG pair token
     * @param shortToken The address of the SHORT pair token
     * @param settlementToken The address of the digital asset that the pool accepts
     * @param poolName The identification name of the pool
     */
    event PoolInitialized(
        address indexed longToken,
        address indexed shortToken,
        address settlementToken,
        string poolName
    );

    /**
     * @notice Creates a notification when the pool is rebalanced
     * @param shortBalanceChange The change of funds in the short side
     * @param longBalanceChange The change of funds in the long side
     * @param shortFeeAmount Proportional fee taken from short side
     * @param longFeeAmount Proportional fee taken from long side
     */
    event PoolRebalance(
        int256 shortBalanceChange,
        int256 longBalanceChange,
        uint256 shortFeeAmount,
        uint256 longFeeAmount
    );

    /**
     * @notice Creates a notification when the pool's price execution fails
     * @param startPrice Price prior to price change execution
     * @param endPrice Price during price change execution
     */
    event PriceChangeError(int256 indexed startPrice, int256 indexed endPrice);

    /**
     * @notice Represents change in fee receiver's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event FeeAddressUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Represents change in secondary fee receiver's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event SecondaryFeeAddressUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Represents change in keeper's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event KeeperAddressChanged(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Indicates a payment of fees to the secondary fee address
     * @param secondaryFeeAddress The address that got fees paid to it
     * @param amount Amount of settlement token paid
     */
    event SecondaryFeesPaid(address indexed secondaryFeeAddress, uint256 amount);

    /**
     * @notice Indicates a payment of fees to the primary fee address
     * @param feeAddress The address that got fees paid to it
     * @param amount Amount of settlement token paid
     */
    event PrimaryFeesPaid(address indexed feeAddress, uint256 amount);

    /**
     * @notice Indicates settlement assets have been withdrawn from the system
     * @param to Receipient
     * @param quantity Quantity of settlement tokens withdrawn
     */
    event SettlementWithdrawn(address indexed to, uint256 indexed quantity);

    /**
     * @notice Indicates that the balance of pool tokens on issue for the pool
     *          changed
     * @param long New quantity of long pool tokens
     * @param short New quantity of short pool tokens
     */
    event PoolBalancesChanged(uint256 indexed long, uint256 indexed short);

    function leverageAmount() external view returns (bytes16);

    function poolCommitter() external view returns (address);

    function settlementToken() external view returns (address);

    function primaryFees() external view returns (uint256);

    function secondaryFees() external view returns (uint256);

    function oracleWrapper() external view returns (address);

    function lastPriceTimestamp() external view returns (uint256);

    function poolName() external view returns (string calldata);

    function updateInterval() external view returns (uint32);

    function shortBalance() external view returns (uint256);

    function longBalance() external view returns (uint256);

    function frontRunningInterval() external view returns (uint32);

    function poolTokens() external view returns (address[2] memory);

    function settlementEthOracle() external view returns (address);

    // #### Functions
    /**
     * @notice Configures the pool on deployment. The pools are EIP 1167 clones.
     * @dev This should only be able to be run once to prevent abuse of the pool. Use of Openzeppelin Initializable or similar is recommended
     * @param initialization The struct Initialization containing initialization data
     */
    function initialize(Initialization calldata initialization) external;

    function poolUpkeep(int256 _oldPrice, int256 _newPrice) external;

    function settlementTokenTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function payKeeperFromBalances(address to, uint256 amount) external returns (bool);

    function settlementTokenTransfer(address to, uint256 amount) external;

    function claimPrimaryFees() external;

    function claimSecondaryFees() external;

    /**
     * @notice Transfer pool tokens from pool to user
     * @param isLongToken True if transferring long pool token; False if transferring short pool token
     * @param to Address of account to transfer to
     * @param amount Amount of pool tokens being transferred
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     */
    function poolTokenTransfer(
        bool isLongToken,
        address to,
        uint256 amount
    ) external;

    function setNewPoolBalances(uint256 _longBalance, uint256 _shortBalance) external;

    /**
     * @return _latestPrice The oracle price
     * @return _data The oracleWrapper's metadata. Implementations can choose what data to return here
     * @return _lastPriceTimestamp The timestamp of the last upkeep
     * @return _updateInterval The update frequency for this pool
     * @dev To save gas so PoolKeeper does not have to make three external calls
     */
    function getUpkeepInformation()
        external
        view
        returns (
            int256 _latestPrice,
            bytes memory _data,
            uint256 _lastPriceTimestamp,
            uint256 _updateInterval
        );

    function getOraclePrice() external view returns (int256);

    function intervalPassed() external view returns (bool);

    function balances() external view returns (uint256 _shortBalance, uint256 _longBalance);

    function setKeeper(address _keeper) external;

    function updateFeeAddress(address account) external;

    function updateSecondaryFeeAddress(address account) external;

    function burnTokens(
        uint256 tokenType,
        uint256 amount,
        address burner
    ) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The oracle wrapper contract interface
interface IOracleWrapper {
    function oracle() external view returns (address);

    function decimals() external view returns (uint8);

    function deployer() external view returns (address);

    // #### Functions

    /**
     * @notice Returns the current price for the asset in question
     * @return The latest price
     */
    function getPrice() external view returns (int256);

    /**
     * @return _price The latest round data price
     * @return _data The metadata. Implementations can choose what data to return here
     */
    function getPriceAndMetadata() external view returns (int256 _price, bytes memory _data);

    /**
     * @notice Converts from a WAD to normal value
     * @return Converted non-WAD value
     */
    function fromWad(int256 wad) external view returns (int256);

    /**
     * @notice Updates the underlying oracle state and returns the new price
     * @dev Spot oracles must implement but it will be a no-op
     */
    function poll() external returns (int256);
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The pausable contract
interface IPausable {
    /**
     * @notice Pauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function pause() external;

    /**
     * @notice Unpauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function unpause() external;

    /**
     * @return true if paused
     */
    function paused() external returns (bool);

    event Paused();
    event Unpaused();
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The interface for the contract that handles pool commitments
interface IPoolCommitter {
    /// Type of commit
    enum CommitType {
        ShortMint, // Mint short tokens
        ShortBurn, // Burn short tokens
        LongMint, // Mint long tokens
        LongBurn, // Burn long tokens
        LongBurnShortMint, // Burn Long tokens, then instantly mint in same upkeep
        ShortBurnLongMint // Burn Short tokens, then instantly mint in same upkeep
    }

    // Pool balances and supplies
    struct BalancesAndSupplies {
        uint256 newShortBalance;
        uint256 newLongBalance;
        uint256 longMintPoolTokens;
        uint256 shortMintPoolTokens;
        uint256 longBurnInstantMintSettlement;
        uint256 shortBurnInstantMintSettlement;
        uint256 totalLongBurnPoolTokens;
        uint256 totalShortBurnPoolTokens;
    }

    // User aggregate balance
    struct Balance {
        uint256 longTokens;
        uint256 shortTokens;
        uint256 settlementTokens;
    }

    // Token Prices
    struct Prices {
        bytes16 longPrice;
        bytes16 shortPrice;
    }

    // Commit information
    struct Commit {
        uint256 amount;
        CommitType commitType;
        uint40 created;
        address owner;
    }

    // Commit information
    struct TotalCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 updateIntervalId;
    }

    // User updated aggregate balance
    struct BalanceUpdate {
        uint256 _updateIntervalId;
        uint256 _newLongTokensSum;
        uint256 _newShortTokensSum;
        uint256 _newSettlementTokensSum;
        uint256 _longBurnFee;
        uint256 _shortBurnFee;
        uint8 _maxIterations;
    }

    // Track how much of a user's commitments are being done from their aggregate balance
    struct UserCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 balanceLongBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 balanceShortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 balanceShortBurnMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 balanceLongBurnMintPoolTokens;
        uint256 updateIntervalId;
    }

    // Track the relevant data when executing a range of update interval's commitments (stack too deep)
    struct CommitmentExecutionTracking {
        uint256 longTotalSupply;
        uint256 shortTotalSupply;
        uint256 longTotalSupplyBefore;
        uint256 shortTotalSupplyBefore;
        uint256 _updateIntervalId;
    }

    /**
     * @notice Creates a notification when a commit is created
     * @param user The user making the commitment
     * @param amount Amount of the commit
     * @param commitType Type of the commit (Short v Long, Mint v Burn)
     * @param appropriateUpdateIntervalId Id of update interval where this commit can be executed as part of upkeep
     * @param fromAggregateBalance whether or not to commit from aggregate (unclaimed) balance
     * @param payForClaim whether or not to request this commit be claimed automatically
     * @param mintingFee Minting fee at time of commit creation
     */
    event CreateCommit(
        address indexed user,
        uint256 indexed amount,
        CommitType indexed commitType,
        uint256 appropriateUpdateIntervalId,
        bool fromAggregateBalance,
        bool payForClaim,
        bytes16 mintingFee
    );

    /**
     * @notice Creates a notification when a user's aggregate balance is updated
     */
    event AggregateBalanceUpdated(address indexed user);

    /**
     * @notice Creates a notification when commits for a given update interval are executed
     * @param updateIntervalId Unique identifier for the relevant update interval
     * @param burningFee Burning fee at the time of commit execution
     */
    event ExecutedCommitsForInterval(uint256 indexed updateIntervalId, bytes16 burningFee);

    /**
     * @notice Creates a notification when a claim is made, depositing pool tokens in user's wallet
     */
    event Claim(address indexed user);

    /*
     * @notice Creates a notification when the burningFee is updated
     */
    event BurningFeeSet(uint256 indexed _burningFee);

    /**
     * @notice Creates a notification when the mintingFee is updated
     */
    event MintingFeeSet(uint256 indexed _mintingFee);

    /**
     * @notice Creates a notification when the changeInterval is updated
     */
    event ChangeIntervalSet(uint256 indexed _changeInterval);

    /**
     * @notice Creates a notification when the feeController is updated
     */
    event FeeControllerSet(address indexed _feeController);

    // #### Functions

    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 mintingFee,
        uint256 burningFee,
        uint256 _changeInterval
    ) external;

    function commit(bytes32 args) external payable;

    function updateIntervalId() external view returns (uint128);

    function pendingMintSettlementAmount() external view returns (uint256);

    function pendingShortBurnPoolTokens() external view returns (uint256);

    function pendingLongBurnPoolTokens() external view returns (uint256);

    function claim(address user) external;

    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateAggregateBalance(address user) external;

    function getAggregateBalance(address user) external view returns (Balance memory _balance);

    function getAppropriateUpdateIntervalId() external view returns (uint128);

    function setPool(address _leveragedPool) external;

    function setBurningFee(uint256 _burningFee) external;

    function setMintingFee(uint256 _mintingFee) external;

    function setChangeInterval(uint256 _changeInterval) external;

    function setFeeController(address _feeController) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The contract factory for the keeper and pool contracts. Utilizes minimal clones to keep gas costs low
interface IPoolFactory {
    struct PoolDeployment {
        string poolName; // The name to identify a pool by
        uint32 frontRunningInterval; // The minimum number of seconds that must elapse before a commit can be executed. Must be smaller than or equal to the update interval to prevent deadlock
        uint32 updateInterval; // The minimum number of seconds that must elapse before a price change
        uint16 leverageAmount; // The amount of exposure to price movements for the pool
        address settlementToken; // The digital asset that the pool accepts
        address oracleWrapper; // The IOracleWrapper implementation for fetching price feed data
        address settlementEthOracle; // The oracle to fetch the price of Ether in terms of the settlement token
        address feeController;
        // The fee taken for each mint and burn. Fee value as a decimal multiplied by 10^18. For example, 50% is represented as 0.5 * 10^18
        uint256 mintingFee; // The fee amount for mints
        uint256 changeInterval; // The interval at which the mintingFee in a market either increases or decreases, as per the logic in `PoolCommitter::updateMintingFee`
        uint256 burningFee; // The fee amount for burns
    }

    // #### Events
    /**
     * @notice Creates a notification when a pool is deployed
     * @param pool Address of the new pool
     * @param ticker Ticker of the new pool
     */
    event DeployPool(address indexed pool, address poolCommitter, string ticker);

    /**
     * @notice Indicates that the InvariantCheck contract has changed
     * @param invariantCheck New InvariantCheck contract
     */
    event InvariantCheckChanged(address indexed invariantCheck);

    /**
     * @notice Creates a notification when a PoolCommitter is deployed
     * @param poolCommitterAddress Address of new PoolCommitter
     * @param settlementToken Address of new settlementToken
     * @param pool Address of the pool associated with this PoolCommitter
     * @param changeInterval The amount that the `mintingFee` will change each update interval, based on `updateMintingFee`, given as a decimal * 10 ^ 18 (same format as `_mintingFee`)
     * @param feeController The address that has control over fee parameters
     */
    event DeployCommitter(
        address poolCommitterAddress,
        address settlementToken,
        address pool,
        uint256 changeInterval,
        address feeController
    );

    /**
     * @notice Creates a notification when the pool keeper changes
     * @param _poolKeeper Address of the new pool keeper
     */
    event PoolKeeperChanged(address _poolKeeper);

    /**
     * @notice Indicates that the maximum allowed leverage has changed
     * @param leverage New maximum allowed leverage value
     */
    event MaxLeverageChanged(uint256 indexed leverage);

    /**
     * @notice Indicates that the receipient of fees has changed
     * @param receiver Address of the new receipient of fees
     */
    event FeeReceiverChanged(address indexed receiver);

    /**
     * @notice Indicates that the receipient of fees has changed
     * @param fee Address of the new receipient of fees
     */
    event SecondaryFeeSplitChanged(uint256 indexed fee);

    /**
     * @notice Indicates that the trading fee has changed
     * @param fee New trading fee
     */
    event FeeChanged(uint256 indexed fee);

    /**
     * @notice Indicates that the AutoClaim contract has changed
     * @param autoClaim New AutoClaim contract
     */
    event AutoClaimChanged(address indexed autoClaim);

    /**
     * @notice Indicates that the minting and burning fees have changed
     * @param mint Minting fee
     * @param burn Burning fee
     */
    event MintAndBurnFeesChanged(uint256 indexed mint, uint256 indexed burn);

    // #### Getters for Globals
    function pools(uint256 id) external view returns (address);

    function numPools() external view returns (uint256);

    function isValidPool(address _pool) external view returns (bool);

    function isValidPoolCommitter(address _poolCommitter) external view returns (bool);

    // #### Functions
    function deployPool(PoolDeployment calldata deploymentParameters) external returns (address);

    function setPoolKeeper(address _poolKeeper) external;

    function setAutoClaim(address _autoClaim) external;

    function setInvariantCheck(address _invariantCheck) external;

    function setFeeReceiver(address _feeReceiver) external;

    function setFee(uint256 _fee) external;

    function setSecondaryFeeSplitPercent(uint256 newFeePercent) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The manager contract interface for multiple markets and the pools in them
interface IPoolKeeper {
    // #### Events
    /**
     * @notice Creates a notification when a pool is created
     * @param poolAddress The pool address of the newly created pool
     * @param firstPrice The price of the market oracle when the pool was created
     */
    event PoolAdded(address indexed poolAddress, int256 indexed firstPrice);

    /**
     * @notice Creates a notification when a call to LeveragedPool:poolUpkeep is successful
     * @param pool The pool address being upkept
     * @param data Extra data about the price fetch. This could be roundID in the case of Chainlink Oracles
     * @param startPrice The previous price of the pool
     * @param endPrice The new price of the pool
     */
    event UpkeepSuccessful(address indexed pool, bytes data, int256 indexed startPrice, int256 indexed endPrice);

    /**
     * @notice Creates a notification when a keeper is paid for doing upkeep for a pool
     * @param _pool Address of pool being upkept
     * @param keeper Keeper to be rewarded for upkeeping
     * @param reward Keeper's reward (in settlement tokens)
     */
    event KeeperPaid(address indexed _pool, address indexed keeper, uint256 reward);

    /**
     * @notice Creates a notification when a keeper's payment for upkeeping a pool failed
     * @param _pool Address of pool being upkept
     * @param keeper Keeper to be rewarded for upkeeping
     * @param expectedReward Keeper's expected reward (in settlement tokens); not actually transferred
     */
    event KeeperPaymentError(address indexed _pool, address indexed keeper, uint256 expectedReward);

    /**
     * @notice Creates a notification of a failed pool update
     * @param pool The pool that failed to update
     * @param reason The reason for the error
     */
    event PoolUpkeepError(address indexed pool, string reason);

    /**
     * @notice Indicates that the factory address has changed
     * @param factory Address of the new factory
     */
    event FactoryChanged(address indexed factory);

    /**
     * @notice Indicates that the KeeperRewards contract has
     * @param oldKeeperRewards The previous KeeperRewards contract
     * @param newKeeperRewards The new KeeperRewards contract
     */
    event KeeperRewardsSet(address indexed oldKeeperRewards, address indexed newKeeperRewards);

    /**
     * @notice Indicates that the gas price for keeper rewards changed
     * @param price New gas price
     */
    event GasPriceChanged(uint256 indexed price);

    // #### Variables

    function keeperRewards() external returns (address);

    // #### Functions
    function newPool(address _poolAddress) external;

    function isUpkeepRequiredSinglePool(address pool) external view returns (bool);

    function checkUpkeepMultiplePools(address[] calldata pools) external view returns (bool);

    function performUpkeepSinglePool(address pool) external;

    function performUpkeepMultiplePools(address[] calldata pools) external;

    function setKeeperRewards(address _keeperRewards) external;

    function setGasPrice(uint256 _price) external;

    function performUpkeepMultiplePoolsPacked(bytes calldata pools) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title Interface for the pool tokens
interface IPoolToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

interface ITwoStepGovernance {
    /**
     * @notice Represents proposed change in governance address
     * @param newAddress Proposed address
     */
    event ProvisionalGovernanceChanged(address indexed newAddress);

    /**
     * @notice Represents change in governance address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event GovernanceAddressChanged(address indexed oldAddress, address indexed newAddress);

    function governance() external returns (address);

    function provisionalGovernance() external returns (address);

    function governanceTransferInProgress() external returns (bool);

    function transferGovernance(address _governance) external;

    function claimGovernance() external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IPoolCommitter.sol";

/// @title CalldataLogic library
/// @notice Library to decode calldata, used to optimize calldata size in PerpetualPools for L2 transaction cost reduction
library CalldataLogic {
    /*
     * Calldata when parameter is a tightly packed bite array looks like this:
     * -----------------------------------------------------------------------------------------------------
     * | function signature | offset of byte array | length of byte array |           bytes array           |
     * |      4 bytes       |       32 bytes       |       32 bytes       |  20 * number_of_addresses bytes |
     * -----------------------------------------------------------------------------------------------------
     *
     * If there are two bytes arrays, then it looks like
     * ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     * | function signature | offset of 1st byte array | offset of 2nd byte array | length of 1st byte array |        1st bytes array          | length of 2nd byte array |        2nd bytes array          |
     * |      4 bytes       |        32 bytes          |        32 bytes          |         32 bytes         |  20 * number_of_addresses bytes |         32 bytes         |  20 * number_of_addresses bytes |
     * ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     * and so on...
     * Note that the offset indicates where the length is indicated, and the actual array itself starts 32 bytes after that
     */
    uint16 internal constant SLOT_LENGTH = 32;
    uint16 internal constant FUNCTION_SIGNATURE_LENGTH = 4;
    uint16 internal constant SINGLE_ARRAY_START_OFFSET = FUNCTION_SIGNATURE_LENGTH + SLOT_LENGTH * 2;
    uint16 internal constant DOUBLE_ARRAY_START_OFFSET = FUNCTION_SIGNATURE_LENGTH + SLOT_LENGTH * 3;
    // Length of address = 20
    uint16 internal constant ADDRESS_LENGTH = 20;

    function getAddressAtOffset(uint256 offset) internal pure returns (address) {
        bytes20 addressAtOffset;
        assembly {
            addressAtOffset := calldataload(offset)
        }
        return (address(addressAtOffset));
    }

    /**
     * @notice decodes compressed commit params to standard params
     * @param args The packed commit args
     * @return The amount of settlement or pool tokens to commit
     * @return The CommitType
     * @return Whether to make the commitment from user's aggregate balance
     * @return Whether to pay for an autoclaim or not
     */
    function decodeCommitParams(bytes32 args)
        internal
        pure
        returns (
            uint256,
            IPoolCommitter.CommitType,
            bool,
            bool
        )
    {
        uint256 amount;
        IPoolCommitter.CommitType commitType;
        bool fromAggregateBalance;
        bool payForClaim;

        assembly {
            amount := and(args, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            commitType := and(shr(128, args), 0xFF)
            fromAggregateBalance := and(shr(136, args), 0xFF)
            payForClaim := and(shr(144, args), 0xFF)
        }
        return (amount, commitType, fromAggregateBalance, payForClaim);
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "abdk-libraries-solidity/ABDKMathQuad.sol";

/// @title Library for various useful (mostly) mathematical functions
library PoolSwapLibrary {
    /// ABDKMathQuad-formatted representation of the number one
    bytes16 public constant ONE = 0x3fff0000000000000000000000000000;

    /// Maximum number of decimal places supported by this contract
    /// (ABDKMathQuad defines this but it's private)
    uint256 public constant MAX_DECIMALS = 18;

    /// Maximum precision supportable via wad arithmetic (for this contract)
    uint256 public constant WAD_PRECISION = 10**18;

    // Set max minting fee to 100%. This is a ABDKQuad representation of 1 * 10 ** 18
    bytes16 public constant MAX_MINTING_FEE = 0x403abc16d674ec800000000000000000;

    // Set max burning fee to 10%. This is a ABDKQuad representation of 0.1 * 10 ** 18
    bytes16 public constant MAX_BURNING_FEE = 0x40376345785d8a000000000000000000;

    /// Information required to update a given user's aggregated balance
    struct UpdateData {
        bytes16 longPrice;
        bytes16 shortPrice;
        uint256 currentUpdateIntervalId;
        uint256 updateIntervalId;
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        bytes16 burnFee;
    }

    /// Information required to perform a price change (of the underlying asset)
    struct PriceChangeData {
        int256 oldPrice;
        int256 newPrice;
        uint256 longBalance;
        uint256 shortBalance;
        bytes16 leverageAmount;
        bytes16 fee;
    }

    /**
     * @notice Calculates the ratio between two numbers
     * @dev Rounds any overflow towards 0. If either parameter is zero, the ratio is 0
     * @param _numerator The "parts per" side of the equation. If this is zero, the ratio is zero
     * @param _denominator The "per part" side of the equation. If this is zero, the ratio is zero
     * @return the ratio, as an ABDKMathQuad number (IEEE 754 quadruple precision floating point)
     */
    function getRatio(uint256 _numerator, uint256 _denominator) public pure returns (bytes16) {
        // Catch the divide by zero error.
        if (_denominator == 0) {
            return 0;
        }
        return ABDKMathQuad.div(ABDKMathQuad.fromUInt(_numerator), ABDKMathQuad.fromUInt(_denominator));
    }

    /**
     * @notice Multiplies two numbers
     * @param x The number to be multiplied by `y`
     * @param y The number to be multiplied by `x`
     */
    function multiplyBytes(bytes16 x, bytes16 y) external pure returns (bytes16) {
        return ABDKMathQuad.mul(x, y);
    }

    /**
     * @notice Performs a subtraction on two bytes16 numbers
     * @param x The number to be subtracted by `y`
     * @param y The number to subtract from `x`
     */
    function subtractBytes(bytes16 x, bytes16 y) external pure returns (bytes16) {
        return ABDKMathQuad.sub(x, y);
    }

    /**
     * @notice Performs an addition on two bytes16 numbers
     * @param x The number to be added with `y`
     * @param y The number to be added with `x`
     */
    function addBytes(bytes16 x, bytes16 y) external pure returns (bytes16) {
        return ABDKMathQuad.add(x, y);
    }

    /**
     * @notice Gets the short and long balances after the keeper rewards have been paid out
     *         Keeper rewards are paid proportionally to the short and long pool
     * @dev Assumes shortBalance + longBalance >= reward
     * @param reward Amount of keeper reward
     * @param shortBalance Short balance of the pool
     * @param longBalance Long balance of the pool
     * @return shortBalanceAfterFees Short balance of the pool after the keeper reward has been paid
     * @return longBalanceAfterFees Long balance of the pool after the keeper reward has been paid
     */
    function getBalancesAfterFees(
        uint256 reward,
        uint256 shortBalance,
        uint256 longBalance
    ) external pure returns (uint256, uint256) {
        bytes16 ratioShort = getRatio(shortBalance, shortBalance + longBalance);

        uint256 shortFees = convertDecimalToUInt(multiplyDecimalByUInt(ratioShort, reward));

        uint256 shortBalanceAfterFees = shortBalance - shortFees;
        uint256 longBalanceAfterFees = longBalance - (reward - shortFees);

        // Return shortBalance and longBalance after rewards are paid out
        return (shortBalanceAfterFees, longBalanceAfterFees);
    }

    /**
     * @notice Compares two decimal numbers
     * @param x The first number to compare
     * @param y The second number to compare
     * @return -1 if x < y, 0 if x = y, or 1 if x > y
     */
    function compareDecimals(bytes16 x, bytes16 y) public pure returns (int8) {
        return ABDKMathQuad.cmp(x, y);
    }

    /**
     * @notice Converts an integer value to a compatible decimal value
     * @param amount The amount to convert
     * @return The amount as a IEEE754 quadruple precision number
     */
    function convertUIntToDecimal(uint256 amount) external pure returns (bytes16) {
        return ABDKMathQuad.fromUInt(amount);
    }

    /**
     * @notice Converts a raw decimal value to a more readable uint256 value
     * @param ratio The value to convert
     * @return The converted value
     */
    function convertDecimalToUInt(bytes16 ratio) public pure returns (uint256) {
        return ABDKMathQuad.toUInt(ratio);
    }

    /**
     * @notice Multiplies a decimal and an unsigned integer
     * @param a The first term
     * @param b The second term
     * @return The product of a*b as a decimal
     */
    function multiplyDecimalByUInt(bytes16 a, uint256 b) public pure returns (bytes16) {
        return ABDKMathQuad.mul(a, ABDKMathQuad.fromUInt(b));
    }

    /**
     * @notice Divides two unsigned integers
     * @param a The dividend
     * @param b The divisor
     * @return The quotient
     */
    function divUInt(uint256 a, uint256 b) private pure returns (bytes16) {
        return ABDKMathQuad.div(ABDKMathQuad.fromUInt(a), ABDKMathQuad.fromUInt(b));
    }

    /**
     * @notice Divides two integers
     * @param a The dividend
     * @param b The divisor
     * @return The quotient
     */
    function divInt(int256 a, int256 b) public pure returns (bytes16) {
        return ABDKMathQuad.div(ABDKMathQuad.fromInt(a), ABDKMathQuad.fromInt(b));
    }

    /**
     * @notice Multiply an integer by a fraction
     * @notice number * numerator / denominator
     * @param number The number with which the fraction calculated from `numerator` and `denominator` will be multiplied
     * @param numerator The numerator of the fraction being multipled with `number`
     * @param denominator The denominator of the fraction being multipled with `number`
     * @return The result of multiplying number with numerator/denominator, as an integer
     */
    function mulFraction(
        uint256 number,
        uint256 numerator,
        uint256 denominator
    ) public pure returns (uint256) {
        if (denominator == 0) {
            return 0;
        }
        bytes16 multiplyResult = ABDKMathQuad.mul(ABDKMathQuad.fromUInt(number), ABDKMathQuad.fromUInt(numerator));
        bytes16 result = ABDKMathQuad.div(multiplyResult, ABDKMathQuad.fromUInt(denominator));
        return convertDecimalToUInt(result);
    }

    /**
     * @notice Calculates the loss multiplier to apply to the losing pool. Includes the power leverage
     * @param ratio The ratio of new price to old price
     * @param direction The direction of the change. -1 if it's decreased, 0 if it hasn't changed, and 1 if it's increased
     * @param leverage The amount of leverage to apply
     * @return The multiplier
     */
    function getLossMultiplier(
        bytes16 ratio,
        int8 direction,
        bytes16 leverage
    ) public pure returns (bytes16) {
        // If decreased:  2 ^ (leverage * log2[(1 * new/old) + [(0 * 1) / new/old]])
        //              = 2 ^ (leverage * log2[(new/old)])
        // If increased:  2 ^ (leverage * log2[(0 * new/old) + [(1 * 1) / new/old]])
        //              = 2 ^ (leverage * log2([1 / new/old]))
        //              = 2 ^ (leverage * log2([old/new]))
        return
            ABDKMathQuad.pow_2(
                ABDKMathQuad.mul(leverage, ABDKMathQuad.log_2(direction < 0 ? ratio : ABDKMathQuad.div(ONE, ratio)))
            );
    }

    /**
     * @notice Calculates the amount to take from the losing pool
     * @param lossMultiplier The multiplier to use
     * @param balance The balance of the losing pool
     */
    function getLossAmount(bytes16 lossMultiplier, uint256 balance) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.sub(ONE, lossMultiplier), ABDKMathQuad.fromUInt(balance))
            );
    }

    /**
     * @notice Calculates the effect of a price change. This involves calculating how many funds to transfer from the losing pool to the other.
     * @dev This function should be called by the LeveragedPool.
     * @param priceChange The struct containing necessary data to calculate price change
     * @return Resulting long balance
     * @return Resulting short balance
     * @return Resulting fees taken from long balance
     * @return Resulting fees taken from short balance
     */
    function calculatePriceChange(PriceChangeData calldata priceChange)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 shortBalance = priceChange.shortBalance;
        uint256 longBalance = priceChange.longBalance;
        bytes16 leverageAmount = priceChange.leverageAmount;
        int256 oldPrice = priceChange.oldPrice;
        int256 newPrice = priceChange.newPrice;
        bytes16 fee = priceChange.fee;

        // Calculate fees from long and short sides
        uint256 longFeeAmount = convertDecimalToUInt(multiplyDecimalByUInt(fee, longBalance)) /
            PoolSwapLibrary.WAD_PRECISION;
        uint256 shortFeeAmount = convertDecimalToUInt(multiplyDecimalByUInt(fee, shortBalance)) /
            PoolSwapLibrary.WAD_PRECISION;

        shortBalance = shortBalance - shortFeeAmount;
        longBalance = longBalance - longFeeAmount;

        // Use the ratio to determine if the price increased or decreased and therefore which direction
        // the funds should be transferred towards.

        bytes16 ratio = divInt(newPrice, oldPrice);
        int8 direction = compareDecimals(ratio, PoolSwapLibrary.ONE);
        // Take into account the leverage
        bytes16 lossMultiplier = getLossMultiplier(ratio, direction, leverageAmount);

        if (direction >= 0 && shortBalance > 0) {
            // Move funds from short to long pair
            uint256 lossAmount = getLossAmount(lossMultiplier, shortBalance);
            shortBalance = shortBalance - lossAmount;
            longBalance = longBalance + lossAmount;
        } else if (direction < 0 && longBalance > 0) {
            // Move funds from long to short pair
            uint256 lossAmount = getLossAmount(lossMultiplier, longBalance);
            shortBalance = shortBalance + lossAmount;
            longBalance = longBalance - lossAmount;
        }

        return (longBalance, shortBalance, longFeeAmount, shortFeeAmount);
    }

    /**
     * @notice Returns true if the given timestamp is BEFORE the frontRunningInterval starts
     * @param subjectTime The timestamp for which you want to calculate if it was beforeFrontRunningInterval
     * @param lastPriceTimestamp The timestamp of the last price update
     * @param updateInterval The interval between price updates
     * @param frontRunningInterval The window of time before a price update in which users can have their commit executed from
     */
    function isBeforeFrontRunningInterval(
        uint256 subjectTime,
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 frontRunningInterval
    ) public pure returns (bool) {
        return lastPriceTimestamp + updateInterval - frontRunningInterval > subjectTime;
    }

    /**
     * @notice Calculates the update interval ID that a commitment should be placed in.
     * @param timestamp Current block.timestamp
     * @param lastPriceTimestamp The timestamp of the last price update
     * @param frontRunningInterval The frontrunning interval of a pool - The amount of time before an update interval that you must commit to get included in that update
     * @param updateInterval The frequency of a pool's updates
     * @param currentUpdateIntervalId The current update interval's ID
     * @dev Note that the timestamp parameter is required to be >= lastPriceTimestamp
     * @return The update interval ID in which a commit being made at time timestamp should be included
     */
    function appropriateUpdateIntervalId(
        uint256 timestamp,
        uint256 lastPriceTimestamp,
        uint256 frontRunningInterval,
        uint256 updateInterval,
        uint256 currentUpdateIntervalId
    ) external pure returns (uint256) {
        require(lastPriceTimestamp <= timestamp, "timestamp in the past");
        if (frontRunningInterval <= updateInterval) {
            // This is the "simple" case where we either want the current update interval or the next one
            if (isBeforeFrontRunningInterval(timestamp, lastPriceTimestamp, updateInterval, frontRunningInterval)) {
                // We are before the frontRunning interval
                return currentUpdateIntervalId;
            } else {
                // Floor of `timePassed / updateInterval` to get the number of intervals passed
                uint256 updateIntervalsPassed = (timestamp - lastPriceTimestamp) / updateInterval;
                // If 1 update interval has passed, we want to check if we are within the frontrunning interval of currentUpdateIntervalId + 1
                uint256 frontRunningIntervalStart = lastPriceTimestamp +
                    ((updateIntervalsPassed + 1) * updateInterval) -
                    frontRunningInterval;
                if (timestamp >= frontRunningIntervalStart) {
                    // add an extra update interval because the frontrunning interval has passed
                    return currentUpdateIntervalId + updateIntervalsPassed + 1;
                } else {
                    return currentUpdateIntervalId + updateIntervalsPassed;
                }
            }
        } else {
            // frontRunningInterval > updateInterval
            // This is the generalised case, where it could be any number of update intervals in the future
            // Minimum time is the earliest we could possible execute this commitment (i.e. the current time plus frontrunning interval)
            uint256 minimumTime = timestamp + frontRunningInterval;
            // Number of update intervals that would have had to have passed.
            uint256 updateIntervals = (minimumTime - lastPriceTimestamp) / updateInterval;

            return currentUpdateIntervalId + updateIntervals;
        }
    }

    /**
     * @notice Gets the number of settlement tokens to be withdrawn based on a pool token burn amount
     * @dev Calculates as `balance * amountIn / (tokenSupply + shadowBalance)
     * @param tokenSupply Total supply of pool tokens
     * @param amountIn Commitment amount of pool tokens going into the pool
     * @param balance Balance of the pool (no. of underlying settlement tokens in pool)
     * @param pendingBurnPoolTokens Amount of pool tokens being burnt during this update interval
     * @return Number of settlement tokens to be withdrawn on a burn
     */
    function getWithdrawAmountOnBurn(
        uint256 tokenSupply,
        uint256 amountIn,
        uint256 balance,
        uint256 pendingBurnPoolTokens
    ) external pure returns (uint256) {
        // Catch the divide by zero error, or return 0 if amountIn is 0
        if ((balance == 0) || (tokenSupply + pendingBurnPoolTokens == 0) || (amountIn == 0)) {
            return amountIn;
        }
        return (balance * amountIn) / (tokenSupply + pendingBurnPoolTokens);
    }

    /**
     * @notice Gets the number of pool tokens to be minted based on existing tokens
     * @dev Calculated as (tokenSupply + shadowBalance) * amountIn / balance
     * @param tokenSupply Total supply of pool tokens
     * @param amountIn Commitment amount of settlement tokens going into the pool
     * @param balance Balance of the pool (no. of underlying settlement tokens in pool)
     * @param pendingBurnPoolTokens Amount of pool tokens being burnt during this update interval
     * @return Number of pool tokens to be minted
     */
    function getMintAmount(
        uint256 tokenSupply,
        uint256 amountIn,
        uint256 balance,
        uint256 pendingBurnPoolTokens
    ) external pure returns (uint256) {
        // Catch the divide by zero error, or return 0 if amountIn is 0
        if (balance == 0 || tokenSupply + pendingBurnPoolTokens == 0 || amountIn == 0) {
            return amountIn;
        }

        return ((tokenSupply + pendingBurnPoolTokens) * amountIn) / balance;
    }

    /**
     * @notice Get the Settlement/PoolToken price, in ABDK IEE754 precision
     * @dev Divide the side balance by the pool token's total supply
     * @param sideBalance no. of underlying settlement tokens on that side of the pool
     * @param tokenSupply Total supply of pool tokens
     */
    function getPrice(uint256 sideBalance, uint256 tokenSupply) external pure returns (bytes16) {
        if (tokenSupply == 0) {
            return ONE;
        }
        return ABDKMathQuad.div(ABDKMathQuad.fromUInt(sideBalance), ABDKMathQuad.fromUInt(tokenSupply));
    }

    /**
     * @notice Calculates the number of pool tokens to mint, given some settlement token amount and a price
     * @param price Price of a pool token
     * @param amount Amount of settlement tokens being used to mint
     * @return Quantity of pool tokens to mint
     * @dev Throws if price is zero
     * @dev `getMint()`
     */
    function getMint(bytes16 price, uint256 amount) public pure returns (uint256) {
        require(price != 0, "price == 0");
        return ABDKMathQuad.toUInt(ABDKMathQuad.div(ABDKMathQuad.fromUInt(amount), price));
    }

    /**
     * @notice Calculate the number of settlement tokens to burn, based on a price and an amount of pool tokens
     * @param price Price of a pool token
     * @param amount Amount of pool tokens being used to burn
     * @return Quantity of settlement tokens to return to the user after `amount` pool tokens are burnt.
     * @dev amount * price, where amount is in PoolToken and price is in USD/PoolToken
     * @dev Throws if price is zero
     * @dev `getBurn()`
     */
    function getBurn(bytes16 price, uint256 amount) public pure returns (uint256) {
        require(price != 0, "price == 0");
        return ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(amount), price));
    }

    /**
     * @notice Calculate the number of pool tokens to mint, given some settlement token amount, a price, and a burn amount from other side for instant mint
     * @param price The price of a pool token
     * @param oppositePrice The price of the opposite side's pool token
     * @param amount The amount of settlement tokens being used to mint
     * @param amountBurnedInstantMint The amount of pool tokens that were burnt from the opposite side for an instant mint in this side
     * @return Quantity of pool tokens to mint
     * @dev Throws if price is zero
     */
    function getMintWithBurns(
        bytes16 price,
        bytes16 oppositePrice,
        uint256 amount,
        uint256 amountBurnedInstantMint
    ) public pure returns (uint256) {
        require(price != 0, "price == 0");
        if (amountBurnedInstantMint > 0) {
            // Calculate amount of settlement tokens generated from the burn.
            amount += getBurn(oppositePrice, amountBurnedInstantMint);
        }
        return getMint(price, amount);
    }

    /**
     * @notice Converts from a WAD to normal value
     * @param _wadValue wad number
     * @param _decimals Quantity of decimal places to support
     * @return Converted (non-WAD) value
     */
    function fromWad(uint256 _wadValue, uint256 _decimals) external pure returns (uint256) {
        uint256 scaler = 10**(MAX_DECIMALS - _decimals);
        return _wadValue / scaler;
    }

    /**
     * @notice Calculate the change in a user's balance based on recent commit(s)
     * @param data Information needed for updating the balance including prices and recent commit amounts
     * @return _newLongTokens Quantity of additional long tokens the user would receive
     * @return _newShortTokens Quantity of additional short tokens the user would receive
     * @return _longBurnFee Quantity of settlement tokens taken as a fee from long burns
     * @return _shortBurnFee Quantity of settlement tokens taken as a fee from short burns
     * @return _newSettlementTokens Quantity of additional settlement tokens the user would receive
     */
    function getUpdatedAggregateBalance(UpdateData calldata data)
        external
        pure
        returns (
            uint256 _newLongTokens,
            uint256 _newShortTokens,
            uint256 _longBurnFee,
            uint256 _shortBurnFee,
            uint256 _newSettlementTokens
        )
    {
        if (data.updateIntervalId >= data.currentUpdateIntervalId) {
            // Update interval has not passed: No change
            return (0, 0, 0, 0, 0);
        }
        uint256 longBurnResult; // The amount of settlement tokens to withdraw based on long token burn
        uint256 shortBurnResult; // The amount of settlement tokens to withdraw based on short token burn
        if (data.longMintSettlement > 0 || data.shortBurnLongMintPoolTokens > 0) {
            _newLongTokens = getMintWithBurns(
                data.longPrice,
                data.shortPrice,
                data.longMintSettlement,
                data.shortBurnLongMintPoolTokens
            );
        }

        if (data.longBurnPoolTokens > 0) {
            // Calculate the amount of settlement tokens earned from burning long tokens
            longBurnResult = getBurn(data.longPrice, data.longBurnPoolTokens);
            // Calculate the fee
            _longBurnFee = convertDecimalToUInt(multiplyDecimalByUInt(data.burnFee, longBurnResult)) / WAD_PRECISION;
            // Subtract the fee from settlement token amount
            longBurnResult -= _longBurnFee;
        }

        if (data.shortMintSettlement > 0 || data.longBurnShortMintPoolTokens > 0) {
            _newShortTokens = getMintWithBurns(
                data.shortPrice,
                data.longPrice,
                data.shortMintSettlement,
                data.longBurnShortMintPoolTokens
            );
        }

        if (data.shortBurnPoolTokens > 0) {
            // Calculate the amount of settlement tokens earned from burning short tokens
            shortBurnResult = getBurn(data.shortPrice, data.shortBurnPoolTokens);
            // Calculate the fee
            _shortBurnFee = convertDecimalToUInt(multiplyDecimalByUInt(data.burnFee, shortBurnResult)) / WAD_PRECISION;
            // Subtract the fee from settlement token amount
            shortBurnResult -= _shortBurnFee;
        }

        _newSettlementTokens = shortBurnResult + longBurnResult;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Minimal Clones compatible implementation of the {IERC20} interface.
 * @dev Based Openzeppelin 3.4 ERC20 contract
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20_Cloneable is ERC20, Initializable {
    uint8 _decimals;
    string private _name;
    string private _symbol;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender not owner");
        _;
    }

    /**
     * @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function initialize(
        address _pool,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external initializer {
        owner = _pool;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Transfer ownership. Implemented to help with initializable
     */
    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "Owner: setting to 0 address");
        owner = _owner;
    }
}