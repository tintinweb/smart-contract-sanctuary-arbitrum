/**
 *Submitted for verification at Arbiscan on 2023-07-18
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
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

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.


// File contracts/helpers/Owned.sol

pragma solidity 0.8.17;

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function terminate() public onlyOwner {
        selfdestruct(payable(owner));
    }
}


// File contracts/helpers/FiduciaryDuty.sol


pragma solidity 0.8.17;

contract FiduciaryDuty is Owned {

	uint256 public contentPartFee = 0;
    uint256 public recipientFee = 0;
	uint256 public broadcastFee = 0;

    uint256 public broadcastFeedCreationPrice = 0;
    uint256 public mailingFeedCreationPrice = 0;
    // uint256 public threadCreationPrice = 0;

    address payable public beneficiary;

    constructor() {
        beneficiary = payable(msg.sender);
    }

	function setFees(uint256 _contentPartFee, uint256 _recipientFee, uint256 _broadcastFee) public onlyOwner {
        contentPartFee = _contentPartFee;
        recipientFee = _recipientFee;
		broadcastFee = _broadcastFee;
    }

    function setPrices(uint256 _broadcastFeedCreationPrice, uint256 _mailingFeedCreationPrice) public onlyOwner {
        broadcastFeedCreationPrice = _broadcastFeedCreationPrice;
        mailingFeedCreationPrice = _mailingFeedCreationPrice;
        // threadCreationPrice = _threadCreationPrice;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function payForBroadcastFeedCreation() internal virtual {
        if (broadcastFeedCreationPrice > 0) {
            beneficiary.transfer(broadcastFeedCreationPrice);
        }
    }

    function payForMailingFeedCreation() internal virtual {
        if (mailingFeedCreationPrice > 0) {
            beneficiary.transfer(mailingFeedCreationPrice);
        }
    }

	function payOut(uint256 contentParts, uint256 recipients, uint256 broadcasts) internal virtual {
		uint256 totalValue = contentPartFee * contentParts + recipientFee * recipients + broadcastFee * broadcasts;
		if (totalValue > 0) {
			beneficiary.transfer(totalValue);
		}
	}

}


// File contracts/helpers/Terminatable.sol

pragma solidity 0.8.17;

contract Terminatable is Owned {
    uint256 public terminationBlock;
    uint256 public creationBlock;

    constructor() {
        terminationBlock = 0;
        creationBlock = block.number;
    }

    modifier notTerminated() {
        if (terminationBlock != 0 && block.number >= terminationBlock) {
            revert();
        }
        _;
    }

    // intendedly left non-blocked to allow reassignment of termination block
    function gracefullyTerminateAt(uint256 blockNumber) public onlyOwner {
        terminationBlock = blockNumber;
    }
}


// File contracts/interfaces/IYlideMailer.sol

pragma solidity ^0.8.17;

interface IYlideMailer {
	struct SendBulkArgs {
		uint256 feedId;
		uint256 uniqueId;
		uint256[] recipients;
		bytes[] keys;
		bytes content;
	}

	struct AddMailRecipientsArgs {
		uint256 feedId;
		uint256 uniqueId;
		uint256 firstBlockNumber;
		uint16 partsCount;
		uint16 blockCountLock;
		uint256[] recipients;
		bytes[] keys;
	}

	struct SignatureArgs {
		bytes signature;
		uint256 nonce;
		uint256 deadline;
		address sender;
	}

	struct Supplement {
		address contractAddress;
		uint8 contractType;
	}

	function sendBulkMail(
		SendBulkArgs calldata args,
		SignatureArgs calldata signatureArgs,
		Supplement calldata supplement
	) external payable returns (uint256);

	function addMailRecipients(
		AddMailRecipientsArgs calldata args,
		SignatureArgs calldata signatureArgs,
		Supplement calldata supplement
	) external payable returns (uint256);
}


// File contracts/interfaces/IYlideTokenAttachment.sol

pragma solidity ^0.8.17;

interface IYlideTokenAttachment {
	function setYlideMailer(IYlideMailer) external;

	function pause() external;

	function unpause() external;
}


// File contracts/mocks/MockERC20.sol

pragma solidity ^0.8.17;

contract MockERC20 is ERC20 {
	constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

	function mint(uint256 amount) external {
		_mint(msg.sender, amount);
	}
}


// File contracts/mocks/MockERC721.sol

pragma solidity ^0.8.17;

contract MockERC721 is ERC721 {
	constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

	function mint(uint256 tokenId) external {
		_mint(msg.sender, tokenId);
	}
}


// File contracts/interfaces/ISafe.sol

pragma solidity ^0.8.17;

interface ISafe {
	function isOwner(address owner) external view returns (bool);

	function getOwners() external view returns (address[] memory);
}


// File contracts/mocks/MockSafe.sol

pragma solidity ^0.8.17;

contract MockSafe is ISafe {
	mapping(address => bool) public isOwner;
	address[] internal owners;

	constructor() {}

	function setOwners(address[] memory _owners, bool[] memory values) external {
		for (uint256 i = 0; i < _owners.length; i++) {
			isOwner[_owners[i]] = values[i];
			if (values[i]) {
				owners.push(_owners[i]);
			} else {
				for (uint256 j = 0; j < owners.length; j++) {
					if (owners[j] == _owners[i]) {
						owners[j] = owners[owners.length - 1];
						owners.pop();
						break;
					}
				}
			}
		}
	}

	function getOwners() external view returns (address[] memory) {
		return owners;
	}
}


// File contracts/YlideMailerV6.sol

pragma solidity ^0.8.9;

contract YlideMailerV6 is Owned {

    uint256 public version = 6;

    uint256 constant empt0 = 0x00ff000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empt1 = 0x00ffffffff000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empt2 = 0x00ffffffffffffff000000ffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empt3 = 0x00ffffffffffffffffffff000000ffffffffffffffffffffffffffffffffffff;
    uint256 constant empt4 = 0x00ffffffffffffffffffffffffff000000ffffffffffffffffffffffffffffff;
    uint256 constant empt5 = 0x00ffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
    uint256 constant empt6 = 0x00ffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
    uint256 constant empt7 = 0x00ffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
    uint256 constant empt8 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff;
    uint256 constant empt9 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000;

    uint256 constant indx1 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx2 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx3 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx4 = 0x0400000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx5 = 0x0500000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx6 = 0x0600000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx7 = 0x0700000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx8 = 0x0800000000000000000000000000000000000000000000000000000000000000;
    uint256 constant indx9 = 0x0900000000000000000000000000000000000000000000000000000000000000;

    uint256 public contentPartFee = 0;
    uint256 public recipientFee = 0;
    address payable public beneficiary;

    mapping (uint256 => uint256) public recipientToPushIndex;
    mapping (address => uint256) public senderToBroadcastIndex;

    event MailPush(uint256 indexed recipient, address indexed sender, uint256 msgId, uint256 mailList, bytes key);
    event MailContent(uint256 indexed msgId, address indexed sender, uint16 parts, uint16 partIdx, bytes content);
    event MailBroadcast(address indexed sender, uint256 msgId, uint256 mailList);

    constructor() {
        beneficiary = payable(msg.sender);
    }

    function shiftLeft(uint256 a, uint256 n) public pure returns (uint256) {
        return uint256(a * 2 ** n);
    }
    
    function shiftRight(uint256 a, uint256 n) public pure returns (uint256) {
        return uint256(a / 2 ** n);
    }

    function nextIndex(uint256 orig, uint256 val) public pure returns (uint256 result) {
        val = val & 0xffffff; // 3 bytes
        uint8 currIdx = uint8(shiftRight(orig, 248));
        if (currIdx == 9) {
            return (orig & empt0) | shiftLeft(val, 216);
        } else
        if (currIdx == 0) {
            return (orig & empt1) | indx1 | shiftLeft(val, 192);
        } else
        if (currIdx == 1) {
            return (orig & empt2) | indx2 | shiftLeft(val, 168);
        } else
        if (currIdx == 2) {
            return (orig & empt3) | indx3 | shiftLeft(val, 144);
        } else
        if (currIdx == 3) {
            return (orig & empt4) | indx4 | shiftLeft(val, 120);
        } else
        if (currIdx == 4) {
            return (orig & empt5) | indx5 | shiftLeft(val, 96);
        } else
        if (currIdx == 5) {
            return (orig & empt6) | indx6 | shiftLeft(val, 72);
        } else
        if (currIdx == 6) {
            return (orig & empt7) | indx7 | shiftLeft(val, 48);
        } else
        if (currIdx == 7) {
            return (orig & empt8) | indx8 | shiftLeft(val, 24);
        } else
        if (currIdx == 8) {
            return (orig & empt9) | indx9 | val;
        }
    }

    function setFees(uint128 _contentPartFee, uint128 _recipientFee) public onlyOwner {
        contentPartFee = _contentPartFee;
        recipientFee = _recipientFee;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function buildHash(uint256 senderAddress, uint32 uniqueId, uint32 time) public pure returns (uint256 _hash) {
        bytes memory data = bytes.concat(bytes32(senderAddress), bytes4(uniqueId), bytes4(time));
        _hash = uint256(sha256(data));
    }

    // Virtual function for initializing bulk message sending
    function getMsgId(uint256 senderAddress, uint32 uniqueId, uint32 initTime) public pure returns (uint256 msgId) {
        msgId = buildHash(senderAddress, uniqueId, initTime);
    }

    // Send part of the long message
    function sendMultipartMailPart(uint32 uniqueId, uint32 initTime, uint16 parts, uint16 partIdx, bytes calldata content) public {
        if (block.timestamp < initTime) {
            revert();
        }
        if (block.timestamp - initTime >= 600) {
            revert();
        }

        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);

        emit MailContent(msgId, msg.sender, parts, partIdx, content);

        if (contentPartFee > 0) {
            beneficiary.transfer(contentPartFee);
        }
    }

    // Add recipient keys to some message
    function addRecipients(uint32 uniqueId, uint32 initTime, uint256[] calldata recipients, bytes[] calldata keys) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);
        for (uint i = 0; i < recipients.length; i++) {
            uint256 current = recipientToPushIndex[recipients[i]];
            recipientToPushIndex[recipients[i]] = nextIndex(current, block.number / 128);
            emit MailPush(recipients[i], msg.sender, msgId, current, keys[i]);
        }

        if (recipientFee * recipients.length > 0) {
            beneficiary.transfer(uint128(recipientFee * recipients.length));
        }
    }

    function sendSmallMail(uint32 uniqueId, uint256 recipient, bytes calldata key, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);
        uint256 current = recipientToPushIndex[recipient];
        recipientToPushIndex[recipient] = nextIndex(current, block.number / 128);
        emit MailPush(recipient, msg.sender, msgId, current, key);

        if (contentPartFee + recipientFee > 0) {
            beneficiary.transfer(uint128(contentPartFee + recipientFee));
        }
    }

    function sendBulkMail(uint32 uniqueId, uint256[] calldata recipients, bytes[] calldata keys, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);

        for (uint i = 0; i < recipients.length; i++) {
            uint256 current = recipientToPushIndex[recipients[i]];
            recipientToPushIndex[recipients[i]] = nextIndex(current, block.number / 128);
            emit MailPush(recipients[i], msg.sender, msgId, current, keys[i]);
        }

        if (contentPartFee + recipientFee * recipients.length > 0) {
            beneficiary.transfer(uint128(contentPartFee + recipientFee * recipients.length));
        }
    }

    function broadcastMail(uint32 uniqueId, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);
        uint256 current = senderToBroadcastIndex[msg.sender];
        senderToBroadcastIndex[msg.sender] = nextIndex(current, block.number / 128);
        emit MailBroadcast(msg.sender, msgId, current);

        if (contentPartFee > 0) {
            beneficiary.transfer(uint128(contentPartFee));
        }
    }

    function broadcastMailHeader(uint32 uniqueId, uint32 initTime) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);
        uint256 current = senderToBroadcastIndex[msg.sender];
        senderToBroadcastIndex[msg.sender] = nextIndex(current, block.number / 128);
        emit MailBroadcast(msg.sender, msgId, current);
    }
}


// File contracts/YlideMailerV7.sol


pragma solidity ^0.8.9;

contract YlideMailerV7 is Owned {

    uint256 public version = 7;

    uint256 constant empty0 = 0x00ff000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty1 = 0x00ffffffff000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty2 = 0x00ffffffffffffff000000ffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty3 = 0x00ffffffffffffffffffff000000ffffffffffffffffffffffffffffffffffff;
    uint256 constant empty4 = 0x00ffffffffffffffffffffffffff000000ffffffffffffffffffffffffffffff;
    uint256 constant empty5 = 0x00ffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
    uint256 constant empty6 = 0x00ffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
    uint256 constant empty7 = 0x00ffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
    uint256 constant empty8 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff;
    uint256 constant empty9 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000;

    uint256 constant index1 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index2 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index3 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index4 = 0x0400000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index5 = 0x0500000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index6 = 0x0600000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index7 = 0x0700000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index8 = 0x0800000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index9 = 0x0900000000000000000000000000000000000000000000000000000000000000;

    uint256 public contentPartFee = 0;
    uint256 public recipientFee = 0;
    address payable public beneficiary;

    mapping (uint256 => uint256) public recipientToPushIndex;
    mapping (address => uint256) public senderToBroadcastIndex;

    mapping (uint256 => uint256) public recipientMessagesCount;
    mapping (address => uint256) public broadcastMessagesCount;

    event MailPush(uint256 indexed recipient, address indexed sender, uint256 msgId, uint256 mailList, bytes key);
    event MailContent(uint256 indexed msgId, address indexed sender, uint16 parts, uint16 partIdx, bytes content);
    event MailBroadcast(address indexed sender, uint256 msgId, uint256 mailList);

    constructor() {
        beneficiary = payable(msg.sender);
    }

    function shiftLeft(uint256 a, uint256 n) public pure returns (uint256) {
        return uint256(a * 2 ** n);
    }
    
    function shiftRight(uint256 a, uint256 n) public pure returns (uint256) {
        return uint256(a / 2 ** n);
    }

    function nextIndex(uint256 orig, uint256 val) public pure returns (uint256 result) {
        val = val & 0xffffff; // 3 bytes
        uint8 currIdx = uint8(shiftRight(orig, 248));
        if (currIdx == 9) {
            return (orig & empty0) | shiftLeft(val, 216);
        } else
        if (currIdx == 0) {
            return (orig & empty1) | index1 | shiftLeft(val, 192);
        } else
        if (currIdx == 1) {
            return (orig & empty2) | index2 | shiftLeft(val, 168);
        } else
        if (currIdx == 2) {
            return (orig & empty3) | index3 | shiftLeft(val, 144);
        } else
        if (currIdx == 3) {
            return (orig & empty4) | index4 | shiftLeft(val, 120);
        } else
        if (currIdx == 4) {
            return (orig & empty5) | index5 | shiftLeft(val, 96);
        } else
        if (currIdx == 5) {
            return (orig & empty6) | index6 | shiftLeft(val, 72);
        } else
        if (currIdx == 6) {
            return (orig & empty7) | index7 | shiftLeft(val, 48);
        } else
        if (currIdx == 7) {
            return (orig & empty8) | index8 | shiftLeft(val, 24);
        } else
        if (currIdx == 8) {
            return (orig & empty9) | index9 | val;
        }
    }

    function setFees(uint128 _contentPartFee, uint128 _recipientFee) public onlyOwner {
        contentPartFee = _contentPartFee;
        recipientFee = _recipientFee;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function buildHash(uint256 senderAddress, uint32 uniqueId, uint32 time) public pure returns (uint256 _hash) {
        bytes memory data = bytes.concat(bytes32(senderAddress), bytes4(uniqueId), bytes4(time));
        _hash = uint256(sha256(data));
    }

    // Virtual function for initializing bulk message sending
    function getMsgId(uint256 senderAddress, uint32 uniqueId, uint32 initTime) public pure returns (uint256 msgId) {
        msgId = buildHash(senderAddress, uniqueId, initTime);
    }

    // Send part of the long message
    function sendMultipartMailPart(uint32 uniqueId, uint32 initTime, uint16 parts, uint16 partIdx, bytes calldata content) public {
        if (block.timestamp < initTime) {
            revert();
        }
        if (block.timestamp - initTime >= 600) {
            revert();
        }

        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);

        emit MailContent(msgId, msg.sender, parts, partIdx, content);

        if (contentPartFee > 0) {
            beneficiary.transfer(contentPartFee);
        }
    }

    // Add recipient keys to some message
    function addRecipients(uint32 uniqueId, uint32 initTime, uint256[] calldata recipients, bytes[] calldata keys) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);
        for (uint i = 0; i < recipients.length; i++) {
            uint256 current = recipientToPushIndex[recipients[i]];
            recipientToPushIndex[recipients[i]] = nextIndex(current, block.number / 128);
            recipientMessagesCount[recipients[i]] += 1;
            emit MailPush(recipients[i], msg.sender, msgId, current, keys[i]);
        }

        if (recipientFee * recipients.length > 0) {
            beneficiary.transfer(uint128(recipientFee * recipients.length));
        }
    }

    function sendSmallMail(uint32 uniqueId, uint256 recipient, bytes calldata key, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);
        uint256 current = recipientToPushIndex[recipient];
        recipientToPushIndex[recipient] = nextIndex(current, block.number / 128);
        recipientMessagesCount[recipient] += 1;
        emit MailPush(recipient, msg.sender, msgId, current, key);

        if (contentPartFee + recipientFee > 0) {
            beneficiary.transfer(uint128(contentPartFee + recipientFee));
        }
    }

    function sendBulkMail(uint32 uniqueId, uint256[] calldata recipients, bytes[] calldata keys, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);

        for (uint i = 0; i < recipients.length; i++) {
            uint256 current = recipientToPushIndex[recipients[i]];
            recipientToPushIndex[recipients[i]] = nextIndex(current, block.number / 128);
            recipientMessagesCount[recipients[i]] += 1;
            emit MailPush(recipients[i], msg.sender, msgId, current, keys[i]);
        }

        if (contentPartFee + recipientFee * recipients.length > 0) {
            beneficiary.transfer(uint128(contentPartFee + recipientFee * recipients.length));
        }
    }

    function broadcastMail(uint32 uniqueId, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);
        uint256 current = senderToBroadcastIndex[msg.sender];
        senderToBroadcastIndex[msg.sender] = nextIndex(current, block.number / 128);
        broadcastMessagesCount[msg.sender] += 1;
        emit MailBroadcast(msg.sender, msgId, current);

        if (contentPartFee > 0) {
            beneficiary.transfer(uint128(contentPartFee));
        }
    }

    function broadcastMailHeader(uint32 uniqueId, uint32 initTime) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);
        uint256 current = senderToBroadcastIndex[msg.sender];
        senderToBroadcastIndex[msg.sender] = nextIndex(current, block.number / 128);
        broadcastMessagesCount[msg.sender] += 1;
        emit MailBroadcast(msg.sender, msgId, current);
    }
}


// File contracts/helpers/BlockNumberRingBufferIndex.sol


pragma solidity 0.8.17;

contract BlockNumberRingBufferIndex {
    
	uint256 constant empty0 = 0x00ff000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty1 = 0x00ffffffff000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty2 = 0x00ffffffffffffff000000ffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant empty3 = 0x00ffffffffffffffffffff000000ffffffffffffffffffffffffffffffffffff;
    uint256 constant empty4 = 0x00ffffffffffffffffffffffffff000000ffffffffffffffffffffffffffffff;
    uint256 constant empty5 = 0x00ffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
    uint256 constant empty6 = 0x00ffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
    uint256 constant empty7 = 0x00ffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
    uint256 constant empty8 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff;
    uint256 constant empty9 = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000;

    uint256 constant indexF = 0xff00000000000000000000000000000000000000000000000000000000000000;

    uint256 constant index1 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index2 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index3 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index4 = 0x0400000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index5 = 0x0500000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index6 = 0x0600000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index7 = 0x0700000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index8 = 0x0800000000000000000000000000000000000000000000000000000000000000;
    uint256 constant index9 = 0x0900000000000000000000000000000000000000000000000000000000000000;

    uint256 constant shift024 = 0x0000000000000000000000000000000000000000000000000000000001000000;
    uint256 constant shift048 = 0x0000000000000000000000000000000000000000000000000001000000000000;
    uint256 constant shift072 = 0x0000000000000000000000000000000000000000000001000000000000000000;
    uint256 constant shift096 = 0x0000000000000000000000000000000000000001000000000000000000000000;
    uint256 constant shift120 = 0x0000000000000000000000000000000001000000000000000000000000000000;
    uint256 constant shift144 = 0x0000000000000000000000000001000000000000000000000000000000000000;
    uint256 constant shift168 = 0x0000000000000000000001000000000000000000000000000000000000000000;
    uint256 constant shift192 = 0x0000000000000001000000000000000000000000000000000000000000000000;
    uint256 constant shift216 = 0x0000000001000000000000000000000000000000000000000000000000000000;

    function storeBlockNumber(uint256 indexValue, uint256 blockNumber) public pure returns (uint256) {
        blockNumber = blockNumber & 0xffffff; // 3 bytes
        uint256 currIdx = indexValue & indexF;
        if (currIdx == 0) {
            return (indexValue & empty1) | index1 | (blockNumber * shift192);
        } else
        if (currIdx == index1) {
            return (indexValue & empty2) | index2 | (blockNumber * shift168);
        } else
        if (currIdx == index2) {
            return (indexValue & empty3) | index3 | (blockNumber * shift144);
        } else
        if (currIdx == index3) {
            return (indexValue & empty4) | index4 | (blockNumber * shift120);
        } else
        if (currIdx == index4) {
            return (indexValue & empty5) | index5 | (blockNumber * shift096);
        } else
        if (currIdx == index5) {
            return (indexValue & empty6) | index6 | (blockNumber * shift072);
        } else
        if (currIdx == index6) {
            return (indexValue & empty7) | index7 | (blockNumber * shift048);
        } else
        if (currIdx == index7) {
            return (indexValue & empty8) | index8 | (blockNumber * shift024);
        } else
        if (currIdx == index8) {
            return (indexValue & empty9) | index9 | blockNumber;
        } else {
            return (indexValue & empty0) | (blockNumber * shift216);
        }
    }
}


// File contracts/YlideMailerV8.sol

pragma solidity ^0.8.9;




struct BroadcastFeedV8 {
    address owner;
    address payable beneficiary;

    uint256 broadcastFee;

    bool isPublic;
    mapping (address => bool) writers;
    uint256 messagesIndex;
    uint256 messagesCount;
}

// struct MailingThreadV8 {
//     uint256 messagesIndex;
//     uint256 messageCount;

//     mapping (uint256 => bool) recipientParticipationStatus;
// }

struct MailingFeedV8 {
    address owner;
    address payable beneficiary;

    uint256 recipientFee;

    mapping (uint256 => uint256) recipientToMailIndex;
    mapping (uint256 => uint256) recipientMessagesCount;

    // mapping (uint256 => uint256) recipientToThreadJoinEventsIndex;
    // mapping (uint256 => MailingThreadV8) threads;
}

contract YlideMailerV8 is Owned, Terminatable, FiduciaryDuty, BlockNumberRingBufferIndex {

    uint256 constant public version = 8;

    mapping (uint256 => MailingFeedV8) public mailingFeeds;
    mapping (uint256 => BroadcastFeedV8) public broadcastFeeds;

    mapping (uint256 => uint256) public recipientToMailingFeedJoinEventsIndex;

    event MailPush(
        uint256 indexed recipient,
        uint256 indexed feedId,
        address sender,
        uint256 contentId,
        uint256 previousFeedEventsIndex,
        bytes key
    );

    event ContentRecipients(
        uint256 indexed contentId,
        address indexed sender,
        uint256[] recipients
    );

    event BroadcastPush(
        address indexed sender,
        uint256 indexed feedId,
        uint256 contentId,
        uint256 previousFeedEventsIndex
    );
    
    event MessageContent(
        uint256 indexed contentId,
        address indexed sender,
        uint16 parts,
        uint16 partIdx,
        bytes content
    );
    
    event MailingFeedCreated(uint256 indexed feedId, address indexed creator);
    event BroadcastFeedCreated(uint256 indexed feedId, address indexed creator);
    
    event MailingFeedOwnershipTransferred(uint256 indexed feedId, address newOwner);
    event BroadcastFeedOwnershipTransferred(uint256 indexed feedId, address newOwner);

    event MailingFeedBeneficiaryChanged(uint256 indexed feedId, address newBeneficiary);
    event BroadcastFeedBeneficiaryChanged(uint256 indexed feedId, address newBeneficiary);
    
    event BroadcastFeedPublicityChanged(uint256 indexed feedId, bool isPublic);
    event BroadcastFeedWriterChange(uint256 indexed feedId, address indexed writer, bool status);

    // event ThreadCreated(uint256 indexed feedId, uint256 indexed threadId, address indexed creator);
    // event ThreadJoined(uint256 indexed feedId, uint256 indexed threadId, uint256 indexed newParticipant, uint256 previousThreadJoinEventsIndex);

    event MailingFeedJoined(uint256 indexed feedId, uint256 indexed newParticipant, uint256 previousFeedJoinEventsIndex);

    constructor() {
        mailingFeeds[0].owner = msg.sender; // regular mail
        mailingFeeds[0].beneficiary = payable(msg.sender);

        mailingFeeds[1].owner = msg.sender; // otc mail
        mailingFeeds[1].beneficiary = payable(msg.sender);

        mailingFeeds[2].owner = msg.sender; // system messages
        mailingFeeds[2].beneficiary = payable(msg.sender);

        mailingFeeds[3].owner = msg.sender; // system messages
        mailingFeeds[3].beneficiary = payable(msg.sender);

        mailingFeeds[4].owner = msg.sender; // system messages
        mailingFeeds[4].beneficiary = payable(msg.sender);

        mailingFeeds[5].owner = msg.sender; // system messages
        mailingFeeds[5].beneficiary = payable(msg.sender);

        mailingFeeds[6].owner = msg.sender; // system messages
        mailingFeeds[6].beneficiary = payable(msg.sender);

        mailingFeeds[7].owner = msg.sender; // system messages
        mailingFeeds[7].beneficiary = payable(msg.sender);

        mailingFeeds[8].owner = msg.sender; // system messages
        mailingFeeds[8].beneficiary = payable(msg.sender);

        mailingFeeds[9].owner = msg.sender; // system messages
        mailingFeeds[9].beneficiary = payable(msg.sender);

        mailingFeeds[10].owner = msg.sender; // system messages
        mailingFeeds[10].beneficiary = payable(msg.sender);

        broadcastFeeds[0].owner = msg.sender;
        broadcastFeeds[0].beneficiary = payable(msg.sender);
        broadcastFeeds[0].isPublic = false;
        broadcastFeeds[0].writers[msg.sender] = true;

        broadcastFeeds[1].owner = msg.sender;
        broadcastFeeds[1].beneficiary = payable(msg.sender);
        broadcastFeeds[1].isPublic = false;
        broadcastFeeds[1].writers[msg.sender] = true;

        broadcastFeeds[2].owner = msg.sender;
        broadcastFeeds[2].beneficiary = payable(msg.sender);
        broadcastFeeds[2].isPublic = true;
    }

    modifier blockLock(uint256 firstBlockNumber, uint256 blockCountLock) {
        if (block.number < firstBlockNumber) {
            revert('Number less than firstBlockNumber');
        }
        if (block.number - firstBlockNumber >= blockCountLock) {
            revert('Number more than firstBlockNumber + blockCountLock');
        }
        _;
    }

    function setMailingFeedFees(uint256 feedId, uint256 _recipientFee) public {
        if (msg.sender != mailingFeeds[feedId].owner) {
            revert();
        }
        mailingFeeds[feedId].recipientFee = _recipientFee;
    }

    function setBroadcastFeedFees(uint256 feedId, uint256 _broadcastFee) public {
        if (msg.sender != broadcastFeeds[feedId].owner) {
            revert();
        }
        broadcastFeeds[feedId].broadcastFee = _broadcastFee;
    }

    function isBroadcastFeedWriter(uint256 feedId, address addr) public view returns (bool) {
        return broadcastFeeds[feedId].writers[addr];
    }

    function getMailingFeedRecipientIndex(uint256 feedId, uint256 recipient) public view returns (uint256) {
        return mailingFeeds[feedId].recipientToMailIndex[recipient];
    }

    function getMailingFeedRecipientMessagesCount(uint256 feedId, uint256 recipient) public view returns (uint256) {
        return mailingFeeds[feedId].recipientMessagesCount[recipient];
    }

    function payOutMailingFeed(uint256 feedId, uint256 recipients) internal virtual {
		uint256 totalValue = mailingFeeds[feedId].recipientFee * recipients;
		if (totalValue > 0) {
			mailingFeeds[feedId].beneficiary.transfer(totalValue);
		}
	}

    function payOutBroadcastFeed(uint256 feedId, uint256 broadcasts) internal virtual {
        uint256 totalValue = broadcastFeeds[feedId].broadcastFee * broadcasts;
		if (totalValue > 0) {
			broadcastFeeds[feedId].beneficiary.transfer(totalValue);
		}
    }

    receive() external payable {
        // do nothing
    }

    function buildContentId(address senderAddress, uint256 uniqueId, uint256 firstBlockNumber, uint256 partsCount, uint256 blockCountLock) public pure returns (uint256) {
        uint256 _hash = uint256(sha256(bytes.concat(bytes32(uint256(uint160(senderAddress))), bytes32(uniqueId), bytes32(firstBlockNumber))));

        uint256 versionMask = (version & 0xFF) * 0x100000000000000000000000000000000000000000000000000000000000000;
        uint256 blockNumberMask = (firstBlockNumber & 0xFFFFFFFF) * 0x1000000000000000000000000000000000000000000000000000000;
        uint256 partsCountMask = (partsCount & 0xFFFF) * 0x100000000000000000000000000000000000000000000000000;
        uint256 blockCountLockMask = (blockCountLock & 0xFFFF) * 0x10000000000000000000000000000000000000000000000;

        uint256 hashMask = _hash & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        return versionMask | blockNumberMask | partsCountMask | blockCountLockMask | hashMask;
    }

    /* ----------- MAIL PUSHES ----------- */
    /**
     * sendSmallMail - for sending tiny content to 1 recipient
     * sendBulkMail - for sending tiny content to multiple recipients
     * addMailRecipients - for adding recipients to any message (multipart or not)
     */

    function emitMailPush(uint256 feedId, uint256 rec, address sender, uint256 contentId, bytes memory key) internal {
        if (mailingFeeds[feedId].owner == address(0)) {
            revert("Feed does not exist");
        }
        uint256 shrinkedBlock = block.number / 128;
        if (mailingFeeds[feedId].recipientMessagesCount[rec] == 0) {
            uint256 currentMailingFeedJoinEventsIndex = recipientToMailingFeedJoinEventsIndex[rec];
            recipientToMailingFeedJoinEventsIndex[rec] = storeBlockNumber(currentMailingFeedJoinEventsIndex, shrinkedBlock);
            emit MailingFeedJoined(feedId, rec, currentMailingFeedJoinEventsIndex);
        }
        // if (threadId != 0) {
        //     if (mailingFeeds[feedId].threads[threadId].recipientParticipationStatus[rec] == false) {
        //         mailingFeeds[feedId].threads[threadId].recipientParticipationStatus[rec] = true;
        //         uint256 currentThreadJoinEventsIndex = mailingFeeds[feedId].recipientToThreadJoinEventsIndex[rec];
        //         mailingFeeds[feedId].recipientToThreadJoinEventsIndex[rec] = storeBlockNumber(currentThreadJoinEventsIndex, shrinkedBlock);
        //         emit ThreadJoined(feedId, threadId, rec, currentThreadJoinEventsIndex);
        //     }
        // }
        uint256 currentFeed = mailingFeeds[feedId].recipientToMailIndex[rec];
        mailingFeeds[feedId].recipientToMailIndex[rec] = storeBlockNumber(currentFeed, shrinkedBlock);
        // write anything to map - 20k gas. think about it
        mailingFeeds[feedId].recipientMessagesCount[rec] += 1;
        // uint256 currentThread = 0;
        // if (threadId != 0) {
        //     currentThread = mailingFeeds[feedId].threads[threadId].messagesIndex;
        //     mailingFeeds[feedId].threads[threadId].messagesIndex = storeBlockNumber(currentThread, shrinkedBlock);
        // }
        emit MailPush(rec, feedId, sender, contentId, currentFeed, key);
    }

    function sendBulkMail(uint256 feedId, uint256 uniqueId, uint256[] calldata recipients, bytes[] calldata keys, bytes calldata content) public payable notTerminated returns (uint256) {
        uint256 contentId = buildContentId(msg.sender, uniqueId, block.number, 1, 0);

        emit MessageContent(contentId, msg.sender, 1, 0, content);

        for (uint i = 0; i < recipients.length; i++) {
            emitMailPush(feedId, recipients[i], msg.sender, contentId, keys[i]);
        }
        emit ContentRecipients(contentId, msg.sender, recipients);

        payOut(1, recipients.length, 0);
        payOutMailingFeed(feedId, recipients.length);

        return contentId;
    }

    function addMailRecipients(
        uint256 feedId,
        uint256 uniqueId,
        uint256 firstBlockNumber,
        uint16 partsCount,
        uint16 blockCountLock,
        uint256[] calldata recipients,
        bytes[] calldata keys
    ) public payable notTerminated blockLock(firstBlockNumber, blockCountLock) returns (uint256) {
        uint256 contentId = buildContentId(msg.sender, uniqueId, firstBlockNumber, partsCount, blockCountLock);
        for (uint i = 0; i < recipients.length; i++) {
            emitMailPush(feedId, recipients[i], msg.sender, contentId, keys[i]);
        }
        emit ContentRecipients(contentId, msg.sender, recipients);

        payOut(0, recipients.length, 0);
        payOutMailingFeed(feedId, recipients.length);

        return contentId;
    }

    /* ---------------------------------------------- */
    /* ------------- MAIL BROADCASTS ---------------- */
    /**
     * sendBroadcast - for sending broadcast content in one transaction
     * sendBroadcastHeader - for emitting broadcast header after uploading all parts of the content
     */

    function emitBroadcastPush(address sender, uint256 feedId, uint256 contentId) internal {
        uint256 current = broadcastFeeds[feedId].messagesIndex;
        broadcastFeeds[feedId].messagesIndex = storeBlockNumber(current, block.number / 128);
        broadcastFeeds[feedId].messagesCount += 1;
        emit BroadcastPush(sender, feedId, contentId, current);
    }

    function sendBroadcast(bool isPersonal, uint256 feedId, uint256 uniqueId, bytes calldata content) public payable notTerminated returns (uint256) {
        if (!isPersonal && !broadcastFeeds[feedId].isPublic && broadcastFeeds[feedId].writers[msg.sender] != true) {
            revert('You are not allowed to write to this feed');
        }

        uint256 composedFeedId = isPersonal ? uint256(sha256(abi.encodePacked(msg.sender, uint256(1), feedId))) : feedId;

        uint256 contentId = buildContentId(msg.sender, uniqueId, block.number, 1, 0);

        emit MessageContent(contentId, msg.sender, 1, 0, content);
        emitBroadcastPush(msg.sender, composedFeedId, contentId);

        payOut(1, 0, 1);
        if (!isPersonal) {
            payOutBroadcastFeed(feedId, 1);
        }

        return contentId;
    }

    function sendBroadcastHeader(bool isPersonal, uint256 feedId, uint256 uniqueId, uint256 firstBlockNumber, uint16 partsCount, uint16 blockCountLock) public payable notTerminated returns (uint256) {
        if (!isPersonal && !broadcastFeeds[feedId].isPublic && broadcastFeeds[feedId].writers[msg.sender] != true) {
            revert('You are not allowed to write to this feed');
        }

        uint256 composedFeedId = isPersonal ? uint256(sha256(abi.encodePacked(msg.sender, feedId))) : feedId;

        uint256 contentId = buildContentId(msg.sender, uniqueId, firstBlockNumber, partsCount, blockCountLock);

        emitBroadcastPush(msg.sender, composedFeedId, contentId);

        payOut(0, 0, 1);
        if (!isPersonal) {
            payOutBroadcastFeed(feedId, 1);
        }

        return contentId;
    }

    /* ---------------------------------------------- */

    // For sending content part - for broadcast or not
    function sendMessageContentPart(
        uint256 uniqueId,
        uint256 firstBlockNumber,
        uint256 blockCountLock,
        uint16 parts,
        uint16 partIdx,
        bytes calldata content
    ) public payable notTerminated blockLock(firstBlockNumber, blockCountLock) returns (uint256) {
        uint256 contentId = buildContentId(msg.sender, uniqueId, firstBlockNumber, parts, blockCountLock);
        emit MessageContent(contentId, msg.sender, parts, partIdx, content);

        payOut(1, 0, 0);

        return contentId;
    }

    /* ---------------------------------------------- */

    // Feed management:
    function createMailingFeed(uint256 uniqueId) public payable returns (uint256) {
        uint256 feedId = uint256(keccak256(abi.encodePacked(msg.sender, uint256(0), uniqueId)));

        if (mailingFeeds[feedId].owner != address(0)) {
            revert('Feed already exists');
        }
        
        mailingFeeds[feedId].owner = msg.sender;
        mailingFeeds[feedId].beneficiary = payable(msg.sender);

        payForMailingFeedCreation();

        emit MailingFeedCreated(feedId, msg.sender);

        return feedId;
    }

    function transferMailingFeedOwnership(uint256 feedId, address newOwner) public {
        if (mailingFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to transfer ownership of this feed');
        }

        mailingFeeds[feedId].owner = newOwner;
        emit MailingFeedOwnershipTransferred(feedId, newOwner);
    }

    function setMailingFeedBeneficiary(uint256 feedId, address payable newBeneficiary) public {
        if (mailingFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to set beneficiary of this feed');
        }

        mailingFeeds[feedId].beneficiary = newBeneficiary;
        emit MailingFeedBeneficiaryChanged(feedId, newBeneficiary);
    }

    function createBroadcastFeed(uint256 uniqueId, bool isPublic) public payable returns (uint256) {
        uint256 feedId = uint256(keccak256(abi.encodePacked(msg.sender, uint256(0), uniqueId)));

        if (broadcastFeeds[feedId].owner != address(0)) {
            revert('Feed already exists');
        }
        
        broadcastFeeds[feedId].owner = msg.sender;
        broadcastFeeds[feedId].beneficiary = payable(msg.sender);
        broadcastFeeds[feedId].isPublic = isPublic;
        broadcastFeeds[feedId].writers[msg.sender] = true;
        broadcastFeeds[feedId].messagesIndex = 0;
        broadcastFeeds[feedId].messagesCount = 0;

        payForBroadcastFeedCreation();

        emit BroadcastFeedCreated(feedId, msg.sender);

        return feedId;
    }

    function transferBroadcastFeedOwnership(uint256 feedId, address newOwner) public {
        if (broadcastFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to transfer ownership of this feed');
        }

        broadcastFeeds[feedId].owner = newOwner;
        emit BroadcastFeedOwnershipTransferred(feedId, newOwner);
    }

    function setBroadcastFeedBeneficiary(uint256 feedId, address payable newBeneficiary) public {
        if (broadcastFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to set beneficiary of this feed');
        }

        broadcastFeeds[feedId].beneficiary = newBeneficiary;
        emit BroadcastFeedBeneficiaryChanged(feedId, newBeneficiary);
    }

    function changeBroadcastFeedPublicity(uint256 feedId, bool isPublic) public {
        if (broadcastFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to change publicity of this feed');
        }

        broadcastFeeds[feedId].isPublic = isPublic;
        emit BroadcastFeedPublicityChanged(feedId, isPublic);
    }

    function addBroadcastFeedWriter(uint256 feedId, address writer) public {
        if (broadcastFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to add writers to this feed');
        }

        broadcastFeeds[feedId].writers[writer] = true;
        emit BroadcastFeedWriterChange(feedId, writer, true);
    }

    function removeBroadcastFeedWriter(uint256 feedId, address writer) public {
        if (broadcastFeeds[feedId].owner != msg.sender) {
            revert('You are not allowed to remove writers from this feed');
        }

        delete broadcastFeeds[feedId].writers[writer];
        emit BroadcastFeedWriterChange(feedId, writer, false);
    }
}


// File contracts/helpers/Constants.sol


pragma solidity 0.8.17;

uint8 constant CONTRACT_TYPE_NONE = 0;
uint8 constant CONTRACT_TYPE_PAY = 1;
uint8 constant CONTRACT_TYPE_SAFE = 2;


// File contracts/YlideMailerV9.sol

pragma solidity ^0.8.9;





contract YlideMailerV9 is
	IYlideMailer,
	Owned,
	Terminatable,
	FiduciaryDuty,
	BlockNumberRingBufferIndex,
	EIP712
{
	uint256 public constant version = 9;

	mapping(uint256 => MailingFeedV9) public mailingFeeds;
	mapping(uint256 => BroadcastFeedV9) public broadcastFeeds;

	mapping(uint256 => uint256) public recipientToMailingFeedJoinEventsIndex;

	mapping(address => uint256) public nonces;

	mapping(address => bool) public isYlide;
	address payable public extraTreasury;

	struct BroadcastFeedV9 {
		address owner;
		address payable beneficiary;
		uint256 broadcastFee;
		bool isPublic;
		mapping(address => bool) writers;
		uint256 messagesIndex;
		uint256 messagesCount;
	}

	struct MailingFeedV9 {
		address owner;
		address payable beneficiary;
		uint256 recipientFee;
		mapping(uint256 => uint256) recipientToMailIndex;
		mapping(uint256 => uint256) recipientMessagesCount;
	}

	event MailPush(
		uint256 indexed recipient,
		uint256 indexed feedId,
		address sender,
		uint256 contentId,
		uint256 previousFeedEventsIndex,
		bytes key,
		Supplement supplement
	);

	event BroadcastPush(
		address indexed sender,
		uint256 indexed feedId,
		uint256 contentId,
		uint256 extraPayment,
		uint256 previousFeedEventsIndex
	);

	event MessageContent(
		uint256 indexed contentId,
		address indexed sender,
		uint16 parts,
		uint16 partIdx,
		bytes content
	);

	event MailingFeedCreated(uint256 indexed feedId, address indexed creator);
	event BroadcastFeedCreated(uint256 indexed feedId, address indexed creator);

	event MailingFeedOwnershipTransferred(uint256 indexed feedId, address newOwner);
	event BroadcastFeedOwnershipTransferred(uint256 indexed feedId, address newOwner);

	event MailingFeedBeneficiaryChanged(uint256 indexed feedId, address newBeneficiary);
	event BroadcastFeedBeneficiaryChanged(uint256 indexed feedId, address newBeneficiary);

	event BroadcastFeedPublicityChanged(uint256 indexed feedId, bool isPublic);
	event BroadcastFeedWriterChange(uint256 indexed feedId, address indexed writer, bool status);

	event MailingFeedJoined(
		uint256 indexed feedId,
		uint256 indexed newParticipant,
		uint256 previousFeedJoinEventsIndex
	);

	error NumberLessThanFirstBlockNumber();
	error NumberMoreThanFirstBlockNumberPlusBlockCountLock();
	error NotFeedOwner();
	error FeedExists();
	error FeedDoesNotExist();
	error InvalidSignature();
	error SignatureExpired();
	error InvalidNonce();
	error FeedAlreadyExists();
	error FeedNotAllowed();
	error IsNotYlide();

	constructor() EIP712("YlideMailerV9", "9") {
		extraTreasury = payable(msg.sender);

		mailingFeeds[0].owner = msg.sender; // regular mail
		mailingFeeds[0].beneficiary = payable(msg.sender);

		mailingFeeds[1].owner = msg.sender; // otc mail
		mailingFeeds[1].beneficiary = payable(msg.sender);

		mailingFeeds[2].owner = msg.sender; // system messages
		mailingFeeds[2].beneficiary = payable(msg.sender);

		mailingFeeds[3].owner = msg.sender; // system messages
		mailingFeeds[3].beneficiary = payable(msg.sender);

		mailingFeeds[4].owner = msg.sender; // system messages
		mailingFeeds[4].beneficiary = payable(msg.sender);

		mailingFeeds[5].owner = msg.sender; // system messages
		mailingFeeds[5].beneficiary = payable(msg.sender);

		mailingFeeds[6].owner = msg.sender; // system messages
		mailingFeeds[6].beneficiary = payable(msg.sender);

		mailingFeeds[7].owner = msg.sender; // system messages
		mailingFeeds[7].beneficiary = payable(msg.sender);

		mailingFeeds[8].owner = msg.sender; // system messages
		mailingFeeds[8].beneficiary = payable(msg.sender);

		mailingFeeds[9].owner = msg.sender; // system messages
		mailingFeeds[9].beneficiary = payable(msg.sender);

		mailingFeeds[10].owner = msg.sender; // system messages
		mailingFeeds[10].beneficiary = payable(msg.sender);

		broadcastFeeds[0].owner = msg.sender;
		broadcastFeeds[0].beneficiary = payable(msg.sender);
		broadcastFeeds[0].isPublic = false;
		broadcastFeeds[0].writers[msg.sender] = true;

		broadcastFeeds[1].owner = msg.sender;
		broadcastFeeds[1].beneficiary = payable(msg.sender);
		broadcastFeeds[1].isPublic = false;
		broadcastFeeds[1].writers[msg.sender] = true;

		broadcastFeeds[2].owner = msg.sender;
		broadcastFeeds[2].beneficiary = payable(msg.sender);
		broadcastFeeds[2].isPublic = true;
	}

	function validateBlockLock(uint256 firstBlockNumber, uint256 blockCountLock) internal view {
		if (block.number < firstBlockNumber) {
			revert NumberLessThanFirstBlockNumber();
		}
		if (block.number - firstBlockNumber >= blockCountLock) {
			revert NumberMoreThanFirstBlockNumberPlusBlockCountLock();
		}
	}

	function validateFeedOwner(uint256 feedId) internal view {
		if (msg.sender != mailingFeeds[feedId].owner) {
			revert NotFeedOwner();
		}
	}

	function validateBroadCastFeedOwner(uint256 feedId) internal view {
		if (msg.sender != broadcastFeeds[feedId].owner) {
			revert NotFeedOwner();
		}
	}

	function validateAccessToBroadcastFeed(bool isPersonal, bool isGenericFeed, uint256 feedId) internal view {
		if (isPersonal && isGenericFeed) {
			revert FeedNotAllowed();
		}
		if (
			!isPersonal &&
			!isGenericFeed &&
			!broadcastFeeds[feedId].isPublic &&
			broadcastFeeds[feedId].writers[msg.sender] != true
		) {
			revert FeedNotAllowed();
		}
	}

	function validateIsYlide() internal view {
		if (!isYlide[msg.sender]) {
			revert IsNotYlide();
		}
	}

	function concatBytesList(bytes[] memory list) internal pure returns (bytes memory result) {
		for (uint256 i; i < list.length; ) {
			result = bytes.concat(result, list[i]);
			unchecked {
				i++;
			}
		}
	}

	function setExtraTreasury(address payable newExtraTreasury) public onlyOwner {
        if (newExtraTreasury != address(0)) {
            extraTreasury = newExtraTreasury;
        }
    }

	function setIsYlide(
		address[] calldata ylideContracts,
		bool[] calldata values
	) external onlyOwner {
		if (ylideContracts.length != values.length) {
			revert();
		}
		for (uint256 i; i < ylideContracts.length; ) {
			isYlide[ylideContracts[i]] = values[i];
			unchecked {
				i++;
			}
		}
	}

	function setMailingFeedFees(uint256 feedId, uint256 _recipientFee) public {
		validateFeedOwner(feedId);
		mailingFeeds[feedId].recipientFee = _recipientFee;
	}

	function setBroadcastFeedFees(uint256 feedId, uint256 _broadcastFee) public {
		validateBroadCastFeedOwner(feedId);
		broadcastFeeds[feedId].broadcastFee = _broadcastFee;
	}

	function isBroadcastFeedWriter(uint256 feedId, address addr) public view returns (bool) {
		return broadcastFeeds[feedId].writers[addr];
	}

	function getMailingFeedRecipientIndex(
		uint256 feedId,
		uint256 recipient
	) public view returns (uint256) {
		return mailingFeeds[feedId].recipientToMailIndex[recipient];
	}

	function getMailingFeedRecipientMessagesCount(
		uint256 feedId,
		uint256 recipient
	) public view returns (uint256) {
		return mailingFeeds[feedId].recipientMessagesCount[recipient];
	}

	function payOutMailingFeed(uint256 feedId, uint256 recipients) internal virtual {
		uint256 totalValue = mailingFeeds[feedId].recipientFee * recipients;
		if (totalValue > 0) {
			mailingFeeds[feedId].beneficiary.transfer(totalValue);
		}
	}

	function payOutBroadcastFeed(uint256 feedId, uint256 broadcasts) internal virtual {
		uint256 totalValue = broadcastFeeds[feedId].broadcastFee * broadcasts;
		if (totalValue > 0) {
			broadcastFeeds[feedId].beneficiary.transfer(totalValue);
		}
	}

	receive() external payable {
		// do nothing
	}

	function buildContentId(
		address senderAddress,
		uint256 uniqueId,
		uint256 firstBlockNumber,
		uint256 partsCount,
		uint256 blockCountLock
	) public pure returns (uint256) {
		uint256 _hash = uint256(
			sha256(
				bytes.concat(
					bytes32(uint256(uint160(senderAddress))),
					bytes32(uniqueId),
					bytes32(firstBlockNumber)
				)
			)
		);

		uint256 versionMask = (version & 0xFF) *
			0x100000000000000000000000000000000000000000000000000000000000000;
		uint256 blockNumberMask = (firstBlockNumber & 0xFFFFFFFF) *
			0x1000000000000000000000000000000000000000000000000000000;
		uint256 partsCountMask = (partsCount & 0xFFFF) *
			0x100000000000000000000000000000000000000000000000000;
		uint256 blockCountLockMask = (blockCountLock & 0xFFFF) *
			0x10000000000000000000000000000000000000000000000;

		uint256 hashMask = _hash & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

		return versionMask | blockNumberMask | partsCountMask | blockCountLockMask | hashMask;
	}

	/* ----------- MAIL PUSHES ----------- */
	/**
	 * sendSmallMail - for sending tiny content to 1 recipient
	 * sendBulkMail - for sending tiny content to multiple recipients
	 * addMailRecipients - for adding recipients to any message (multipart or not)
	 */

	function emitMailPush(
		uint256 feedId,
		uint256 rec,
		address sender,
		uint256 contentId,
		bytes memory key,
		Supplement memory supplement
	) internal {
		if (mailingFeeds[feedId].owner == address(0)) {
			revert FeedDoesNotExist();
		}
		uint256 shrinkedBlock = block.number / 128;
		if (mailingFeeds[feedId].recipientMessagesCount[rec] == 0) {
			uint256 currentMailingFeedJoinEventsIndex = recipientToMailingFeedJoinEventsIndex[rec];
			recipientToMailingFeedJoinEventsIndex[rec] = storeBlockNumber(
				currentMailingFeedJoinEventsIndex,
				shrinkedBlock
			);
			emit MailingFeedJoined(feedId, rec, currentMailingFeedJoinEventsIndex);
		}
		uint256 currentFeed = mailingFeeds[feedId].recipientToMailIndex[rec];
		mailingFeeds[feedId].recipientToMailIndex[rec] = storeBlockNumber(
			currentFeed,
			shrinkedBlock
		);
		// write anything to map - 20k gas. think about it
		mailingFeeds[feedId].recipientMessagesCount[rec] += 1;
		emit MailPush(rec, feedId, sender, contentId, currentFeed, key, supplement);
	}

	function sendBulkMail(
		SendBulkArgs calldata args
	) external payable notTerminated returns (uint256) {
		return _sendBulkMail(msg.sender, args, Supplement(address(0), CONTRACT_TYPE_NONE));
	}

	function sendBulkMail(
		SendBulkArgs calldata args,
		SignatureArgs calldata signatureArgs,
		Supplement calldata supplement
	) external payable notTerminated returns (uint256) {
		validateIsYlide();
		bytes32 digest = _hashTypedDataV4(
			keccak256(
				abi.encode(
					keccak256(
						"SendBulkMail(uint256 feedId,uint256 uniqueId,uint256 nonce,uint256 deadline,uint256[] recipients,bytes keys,bytes content,address contractAddress,uint8 contractType)"
					),
					args.feedId,
					args.uniqueId,
					signatureArgs.nonce,
					signatureArgs.deadline,
					keccak256(abi.encodePacked(args.recipients)),
					keccak256(abi.encodePacked(concatBytesList(args.keys))),
					keccak256(abi.encodePacked(args.content)),
					supplement.contractAddress,
					supplement.contractType
				)
			)
		);
		address signer = verifySignature(digest, signatureArgs);
		return _sendBulkMail(signer, args, supplement);
	}

	function _sendBulkMail(
		address sender,
		SendBulkArgs calldata args,
		Supplement memory supplement
	) internal returns (uint256) {
		uint256 contentId = buildContentId(sender, args.uniqueId, block.number, 1, 0);

		emit MessageContent(contentId, sender, 1, 0, args.content);

		for (uint i = 0; i < args.recipients.length; i++) {
			emitMailPush(
				args.feedId,
				args.recipients[i],
				sender,
				contentId,
				args.keys[i],
				supplement
			);
		}

		payOut(1, args.recipients.length, 0);
		payOutMailingFeed(args.feedId, args.recipients.length);

		return contentId;
	}

	function addMailRecipients(
		AddMailRecipientsArgs calldata args
	) external payable notTerminated returns (uint256) {
		validateBlockLock(args.firstBlockNumber, args.blockCountLock);
		return _addMailRecipients(msg.sender, args, Supplement(address(0), CONTRACT_TYPE_NONE));
	}

	function addMailRecipients(
		AddMailRecipientsArgs calldata args,
		SignatureArgs calldata signatureArgs,
		Supplement calldata supplement
	) external payable notTerminated returns (uint256) {
		validateIsYlide();
		validateBlockLock(args.firstBlockNumber, args.blockCountLock);
		bytes32 digest = _hashTypedDataV4(
			keccak256(
				abi.encode(
					keccak256(
						"AddMailRecipients(uint256 feedId,uint256 uniqueId,uint256 firstBlockNumber,uint256 nonce,uint256 deadline,uint16 partsCount,uint16 blockCountLock,uint256[] recipients,bytes keys,address contractAddress,uint8 contractType)"
					),
					args.feedId,
					args.uniqueId,
					args.firstBlockNumber,
					signatureArgs.nonce,
					signatureArgs.deadline,
					args.partsCount,
					args.blockCountLock,
					keccak256(abi.encodePacked(args.recipients)),
					keccak256(abi.encodePacked(concatBytesList(args.keys))),
					supplement.contractAddress,
					supplement.contractType
				)
			)
		);
		address signer = verifySignature(digest, signatureArgs);
		return _addMailRecipients(signer, args, supplement);
	}

	function _addMailRecipients(
		address sender,
		AddMailRecipientsArgs memory args,
		Supplement memory supplement
	) internal returns (uint256) {
		uint256 contentId = buildContentId(
			sender,
			args.uniqueId,
			args.firstBlockNumber,
			args.partsCount,
			args.blockCountLock
		);
		for (uint i = 0; i < args.recipients.length; i++) {
			emitMailPush(
				args.feedId,
				args.recipients[i],
				sender,
				contentId,
				args.keys[i],
				supplement
			);
		}

		payOut(0, args.recipients.length, 0);
		payOutMailingFeed(args.feedId, args.recipients.length);

		return contentId;
	}

	function verifySignature(
		bytes32 digest,
		SignatureArgs calldata signatureArgs
	) internal returns (address) {
		address signer = ECDSA.recover(digest, signatureArgs.signature);

		if (signer != signatureArgs.sender) revert InvalidSignature();
		if (signatureArgs.nonce != nonces[signer]++) revert InvalidNonce();
		if (block.timestamp >= signatureArgs.deadline) revert SignatureExpired();

		return signer;
	}

	/* ---------------------------------------------- */
	/* ------------- MAIL BROADCASTS ---------------- */
	/**
	 * sendBroadcast - for sending broadcast content in one transaction
	 * sendBroadcastHeader - for emitting broadcast header after uploading all parts of the content
	 */

	function emitBroadcastPush(address sender, uint256 feedId, uint256 contentId, uint256 extraPayment) internal {
		uint256 current = broadcastFeeds[feedId].messagesIndex;
		broadcastFeeds[feedId].messagesIndex = storeBlockNumber(current, block.number / 128);
		broadcastFeeds[feedId].messagesCount += 1;
		extraTreasury.transfer(extraPayment);
		emit BroadcastPush(sender, feedId, contentId, extraPayment, current);
	}

	function sendBroadcast(
		bool isPersonal,
		bool isGenericFeed,
		uint256 extraPayment,
		uint256 feedId,
		uint256 uniqueId,
		bytes calldata content
	) public payable notTerminated returns (uint256) {
		validateAccessToBroadcastFeed(isPersonal, isGenericFeed, feedId);

		uint256 composedFeedId = isPersonal
			? uint256(sha256(abi.encodePacked(msg.sender, uint256(1), feedId)))
			: isGenericFeed
				? uint256(sha256(abi.encodePacked(address(0x0000000000000000000000000000000000000000), uint256(2), feedId)))
				: feedId;

		uint256 contentId = buildContentId(msg.sender, uniqueId, block.number, 1, 0);

		emit MessageContent(contentId, msg.sender, 1, 0, content);
		emitBroadcastPush(msg.sender, composedFeedId, contentId, extraPayment);

		payOut(1, 0, 1);
		if (!isPersonal) {
			payOutBroadcastFeed(feedId, 1);
		}

		return contentId;
	}

	function sendBroadcastHeader(
		bool isPersonal,
		bool isGenericFeed,
		uint256 extraPayment,
		uint256 feedId,
		uint256 uniqueId,
		uint256 firstBlockNumber,
		uint16 partsCount,
		uint16 blockCountLock
	) public payable notTerminated returns (uint256) {
		validateAccessToBroadcastFeed(isPersonal, isGenericFeed, feedId);

		uint256 composedFeedId = isPersonal
			? uint256(sha256(abi.encodePacked(msg.sender, uint256(1), feedId)))
			: isGenericFeed
				? uint256(sha256(abi.encodePacked(address(0x0000000000000000000000000000000000000000), uint256(2), feedId)))
				: feedId;

		uint256 contentId = buildContentId(
			msg.sender,
			uniqueId,
			firstBlockNumber,
			partsCount,
			blockCountLock
		);

		emitBroadcastPush(msg.sender, composedFeedId, contentId, extraPayment);

		payOut(0, 0, 1);
		if (!isPersonal) {
			payOutBroadcastFeed(feedId, 1);
		}

		return contentId;
	}

	/* ---------------------------------------------- */

	// For sending content part - for broadcast or not
	function sendMessageContentPart(
		uint256 uniqueId,
		uint256 firstBlockNumber,
		uint256 blockCountLock,
		uint16 parts,
		uint16 partIdx,
		bytes calldata content
	) public payable notTerminated returns (uint256) {
		validateBlockLock(firstBlockNumber, blockCountLock);

		uint256 contentId = buildContentId(
			msg.sender,
			uniqueId,
			firstBlockNumber,
			parts,
			blockCountLock
		);
		emit MessageContent(contentId, msg.sender, parts, partIdx, content);

		payOut(1, 0, 0);

		return contentId;
	}

	/* ---------------------------------------------- */

	// Feed management:
	function createMailingFeed(uint256 uniqueId) public payable returns (uint256) {
		uint256 feedId = uint256(sha256(abi.encodePacked(msg.sender, uint256(0), uniqueId)));

		if (mailingFeeds[feedId].owner != address(0)) {
			revert FeedAlreadyExists();
		}

		mailingFeeds[feedId].owner = msg.sender;
		mailingFeeds[feedId].beneficiary = payable(msg.sender);

		payForMailingFeedCreation();

		emit MailingFeedCreated(feedId, msg.sender);

		return feedId;
	}

	function transferMailingFeedOwnership(uint256 feedId, address newOwner) public {
		validateFeedOwner(feedId);

		mailingFeeds[feedId].owner = newOwner;
		emit MailingFeedOwnershipTransferred(feedId, newOwner);
	}

	function setMailingFeedBeneficiary(uint256 feedId, address payable newBeneficiary) public {
		validateFeedOwner(feedId);

		mailingFeeds[feedId].beneficiary = newBeneficiary;
		emit MailingFeedBeneficiaryChanged(feedId, newBeneficiary);
	}

	function createBroadcastFeed(uint256 uniqueId, bool isPublic) public payable returns (uint256) {
		uint256 feedId = uint256(keccak256(abi.encodePacked(msg.sender, uint256(0), uniqueId)));

		if (broadcastFeeds[feedId].owner != address(0)) {
			revert FeedExists();
		}

		broadcastFeeds[feedId].owner = msg.sender;
		broadcastFeeds[feedId].beneficiary = payable(msg.sender);
		broadcastFeeds[feedId].isPublic = isPublic;
		broadcastFeeds[feedId].writers[msg.sender] = true;
		broadcastFeeds[feedId].messagesIndex = 0;
		broadcastFeeds[feedId].messagesCount = 0;

		payForBroadcastFeedCreation();

		emit BroadcastFeedCreated(feedId, msg.sender);

		return feedId;
	}

	function transferBroadcastFeedOwnership(uint256 feedId, address newOwner) public {
		validateBroadCastFeedOwner(feedId);

		broadcastFeeds[feedId].owner = newOwner;
		emit BroadcastFeedOwnershipTransferred(feedId, newOwner);
	}

	function setBroadcastFeedBeneficiary(uint256 feedId, address payable newBeneficiary) public {
		validateBroadCastFeedOwner(feedId);

		broadcastFeeds[feedId].beneficiary = newBeneficiary;
		emit BroadcastFeedBeneficiaryChanged(feedId, newBeneficiary);
	}

	function changeBroadcastFeedPublicity(uint256 feedId, bool isPublic) public {
		validateBroadCastFeedOwner(feedId);

		broadcastFeeds[feedId].isPublic = isPublic;
		emit BroadcastFeedPublicityChanged(feedId, isPublic);
	}

	function addBroadcastFeedWriter(uint256 feedId, address writer) public {
		validateBroadCastFeedOwner(feedId);

		broadcastFeeds[feedId].writers[writer] = true;
		emit BroadcastFeedWriterChange(feedId, writer, true);
	}

	function removeBroadcastFeedWriter(uint256 feedId, address writer) public {
		validateBroadCastFeedOwner(feedId);

		delete broadcastFeeds[feedId].writers[writer];
		emit BroadcastFeedWriterChange(feedId, writer, false);
	}
}


// File contracts/YlidePayV1.sol

pragma solidity ^0.8.17;






contract YlidePayV1 is IYlideTokenAttachment, Owned, Pausable {
	using SafeERC20 for IERC20;

	struct TransferInfo {
		uint256 amountOrTokenId;
		address recipient;
		address token;
		TokenType tokenType;
	}

	enum TokenType {
		ERC20,
		ERC721
	}

	event TokenAttachment(
		uint256 indexed contentId,
		uint256 amountOrTokenId,
		address indexed recipient,
		address indexed sender,
		address token,
		TokenType tokenType
	);

	error InvalidSender();

	uint256 public constant version = 1;

	IYlideMailer public ylideMailer;

	constructor(IYlideMailer _ylideMailer) Owned() Pausable() {
		ylideMailer = _ylideMailer;
	}

	function setYlideMailer(IYlideMailer _ylideMailer) external onlyOwner {
		ylideMailer = _ylideMailer;
	}

	function _safeTransferFrom(TransferInfo calldata transferInfo, uint256 contentId) internal {
		if (transferInfo.tokenType == TokenType.ERC20) {
			IERC20(transferInfo.token).safeTransferFrom(
				msg.sender,
				transferInfo.recipient,
				transferInfo.amountOrTokenId
			);
		} else if (transferInfo.tokenType == TokenType.ERC721) {
			IERC721(transferInfo.token).safeTransferFrom(
				msg.sender,
				transferInfo.recipient,
				transferInfo.amountOrTokenId
			);
		}
		emit TokenAttachment(
			contentId,
			transferInfo.amountOrTokenId,
			transferInfo.recipient,
			msg.sender,
			transferInfo.token,
			transferInfo.tokenType
		);
	}

	function _handleTokenAttachment(
		TransferInfo[] calldata transferInfos,
		uint256 contentId
	) internal {
		for (uint256 i; i < transferInfos.length; ) {
			if (transferInfos[i].recipient != address(0)) {
				_safeTransferFrom(transferInfos[i], contentId);
			}
			unchecked {
				i++;
			}
		}
	}

	function sendBulkMailWithToken(
		IYlideMailer.SendBulkArgs calldata args,
		IYlideMailer.SignatureArgs memory signatureArgs,
		TransferInfo[] calldata transferInfos
	) external payable whenNotPaused returns (uint256) {
		if (signatureArgs.sender != msg.sender) revert InvalidSender();
		uint256 contentId = ylideMailer.sendBulkMail{value: msg.value}(
			args,
			signatureArgs,
			IYlideMailer.Supplement(address(this), CONTRACT_TYPE_PAY)
		);
		_handleTokenAttachment(transferInfos, contentId);
		return contentId;
	}

	function addMailRecipientsWithToken(
		IYlideMailer.AddMailRecipientsArgs calldata args,
		IYlideMailer.SignatureArgs memory signatureArgs,
		TransferInfo[] calldata transferInfos
	) external payable whenNotPaused returns (uint256) {
		if (signatureArgs.sender != msg.sender) revert InvalidSender();
		uint256 contentId = ylideMailer.addMailRecipients{value: msg.value}(
			args,
			signatureArgs,
			IYlideMailer.Supplement(address(this), CONTRACT_TYPE_PAY)
		);
		_handleTokenAttachment(transferInfos, contentId);
		return contentId;
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}


// File contracts/YlideRegistryV4.sol

pragma solidity ^0.8.9;

struct RegistryEntryV4 {
   uint256 publicKey;
   uint128 block;
   uint64 timestamp;
   uint64 keyVersion;
}

contract YlideRegistryV4 is Owned {
    address public bonucer;

    uint256 public version = 4;

    event KeyAttached(address indexed addr, uint256 publicKey, uint64 keyVersion);
    
    mapping(address => RegistryEntryV4) public addressToPublicKey;

    YlideRegistryV4 previousContract;

    uint256 public newcomerBonus = 0;
    uint256 public referrerBonus = 0;

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    constructor(address payable previousContractAddress) {
        previousContract = YlideRegistryV4(previousContractAddress);
        bonucer = msg.sender;
    }

    function getPublicKey(address addr) view public returns (RegistryEntryV4 memory entry, uint contractVersion, address contractAddress) {
        contractVersion = version;
        contractAddress = address(this);
        entry = addressToPublicKey[addr];
        if (entry.keyVersion == 0 && address(previousContract) != address(0x0)) {
            return previousContract.getPublicKey(addr);
        }
    }

    function attachPublicKey(uint256 publicKey, uint64 keyVersion) public {
        require(keyVersion != 0, 'Key version must be above zero');
        addressToPublicKey[msg.sender] = RegistryEntryV4(publicKey, uint128(block.number), uint64(block.timestamp), keyVersion);

        emit KeyAttached(msg.sender, publicKey, keyVersion);
    }

    modifier onlyBonucer() {
        if (msg.sender != bonucer) {
            revert();
        }
        _;
    }

    function changeBonucer(address newBonucer) public onlyOwner {
        if (newBonucer != address(0)) {
            bonucer = newBonucer;
        }
    }

    function setBonuses(uint256 _newcomerBonus, uint256 _referrerBonus) public onlyOwner {
        newcomerBonus = _newcomerBonus;
        referrerBonus = _referrerBonus;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            string memory buffer = new string(10);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, 10))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function iToHex(bytes32 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(64);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 32; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function verifyMessage(bytes32 publicKey, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n64";
        bytes memory _msg = iToHex(publicKey);
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _msg));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    receive() external payable {
        // do nothing
    }

    function attachPublicKeyByAdmin(uint8 _v, bytes32 _r, bytes32 _s, address payable addr, uint256 publicKey, uint64 keyVersion, address payable referrer, bool payBonus) external payable onlyBonucer {
        require(keyVersion != 0, 'Key version must be above zero');
        require(verifyMessage(bytes32(publicKey), _v, _r, _s) == addr, 'Signature does not match the user''s address');
        require(referrer == address(0x0) || addressToPublicKey[referrer].keyVersion != 0, 'Referrer must be registered');
        require(addr != address(0x0) && addressToPublicKey[addr].keyVersion == 0, 'Only new user key can be assigned by admin');

        addressToPublicKey[addr] = RegistryEntryV4(publicKey, uint128(block.number), uint64(block.timestamp), keyVersion);

        emit KeyAttached(addr, publicKey, keyVersion);

        if (payBonus && newcomerBonus != 0) {
            addr.transfer(newcomerBonus);
        }
        if (referrer != address(0x0) && referrerBonus != 0) {
            referrer.transfer(referrerBonus);
        }
    }
}


// File contracts/YlideRegistryV5.sol

pragma solidity ^0.8.9;

struct RegistryEntryV5 {
   uint256 publicKey;
   uint128 block;
   uint64 timestamp;
   uint64 keyVersion;
}

contract YlideRegistryV5 is Owned {
    uint256 public version = 5;

    event KeyAttached(address indexed addr, uint256 publicKey, uint64 keyVersion);
    
    mapping(address => RegistryEntryV5) public addressToPublicKey;
    mapping(address => bool) public bonucers;

    YlideRegistryV5 previousContract;

    uint256 public newcomerBonus = 0;
    uint256 public referrerBonus = 0;

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    constructor(address payable previousContractAddress) {
        previousContract = YlideRegistryV5(previousContractAddress);
        bonucers[msg.sender] = true;
    }

    function getPublicKey(address addr) view public returns (RegistryEntryV5 memory entry, uint contractVersion, address contractAddress) {
        contractVersion = version;
        contractAddress = address(this);
        entry = addressToPublicKey[addr];
        if (entry.keyVersion == 0 && address(previousContract) != address(0x0)) {
            return previousContract.getPublicKey(addr);
        }
    }

    function attachPublicKey(uint256 publicKey, uint64 keyVersion) public {
        require(keyVersion != 0, 'Key version must be above zero');
        addressToPublicKey[msg.sender] = RegistryEntryV5(publicKey, uint128(block.number), uint64(block.timestamp), keyVersion);

        emit KeyAttached(msg.sender, publicKey, keyVersion);
    }

    modifier onlyBonucer() {
        if (bonucers[msg.sender] != true) {
            revert();
        }
        _;
    }

    function setBonucer(address newBonucer, bool val) public onlyOwner {
        if (newBonucer != address(0)) {
            bonucers[newBonucer] = val;
        }
    }

    function setBonuses(uint256 _newcomerBonus, uint256 _referrerBonus) public onlyOwner {
        newcomerBonus = _newcomerBonus;
        referrerBonus = _referrerBonus;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            string memory buffer = new string(10);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, 10))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function iToHex(bytes32 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(64);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 32; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function verifyMessage(bytes32 publicKey, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n64";
        bytes memory _msg = iToHex(publicKey);
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _msg));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    receive() external payable {
        // do nothing
    }

    function attachPublicKeyByAdmin(uint8 _v, bytes32 _r, bytes32 _s, address payable addr, uint256 publicKey, uint64 keyVersion, address payable referrer, bool payBonus) external payable onlyBonucer {
        require(keyVersion != 0, 'Key version must be above zero');
        require(verifyMessage(bytes32(publicKey), _v, _r, _s) == addr, 'Signature does not match the user''s address');
        require(referrer == address(0x0) || addressToPublicKey[referrer].keyVersion != 0, 'Referrer must be registered');
        require(addr != address(0x0) && addressToPublicKey[addr].keyVersion == 0, 'Only new user key can be assigned by admin');

        addressToPublicKey[addr] = RegistryEntryV5(publicKey, uint128(block.number), uint64(block.timestamp), keyVersion);

        emit KeyAttached(addr, publicKey, keyVersion);

        if (payBonus && newcomerBonus != 0) {
            addr.transfer(newcomerBonus);
        }
        if (referrer != address(0x0) && referrerBonus != 0) {
            referrer.transfer(referrerBonus);
        }
    }
}


// File contracts/YlideRegistryV6.sol

pragma solidity ^0.8.9;



struct RegistryEntryV6 {
    uint256 previousEventsIndex;
    uint256 publicKey;
    uint64 block;
    uint64 timestamp;
    uint32 keyVersion;
    uint32 registrar;
}

contract YlideRegistryV6 is Owned, Terminatable, BlockNumberRingBufferIndex {
    uint256 public version = 6;

    event KeyAttached(address indexed addr, uint256 publicKey, uint32 keyVersion, uint32 registrar, uint256 previousEventsIndex);
    
    mapping(address => RegistryEntryV6) public addressToPublicKey;
    mapping(address => bool) public bonucers;

    uint256 public newcomerBonus = 0;
    uint256 public referrerBonus = 0;

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    constructor() {
        bonucers[msg.sender] = true;
    }

    function getPublicKey(address addr) view public returns (RegistryEntryV6 memory entry) {
        entry = addressToPublicKey[addr];
    }

    modifier onlyBonucer() {
        if (bonucers[msg.sender] != true) {
            revert();
        }
        _;
    }

    function setBonucer(address newBonucer, bool val) public onlyOwner notTerminated {
        if (newBonucer != address(0)) {
            bonucers[newBonucer] = val;
        }
    }

    function setBonuses(uint256 _newcomerBonus, uint256 _referrerBonus) public onlyOwner notTerminated {
        newcomerBonus = _newcomerBonus;
        referrerBonus = _referrerBonus;
    }

    function uint256ToHex(bytes32 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(64);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 32; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function uint32ToHex(bytes4 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(8);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 4; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function uint64ToHex(bytes8 buffer) public pure returns (bytes memory) {
        bytes memory converted = new bytes(16);
        bytes memory _base = "0123456789abcdef";

        for (uint8 i = 0; i < 8; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return converted;
    }

    function verifyMessage(bytes32 publicKey, uint8 _v, bytes32 _r, bytes32 _s, uint32 registrar, uint64 timestampLock) public view returns (address) {
        if (timestampLock > block.timestamp) {
            revert('Timestamp lock is in future');
        }
        if (block.timestamp - timestampLock > 5 * 60) {
            revert('Timestamp lock is too old');
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n330";
        // (121 + 2) + (14 + 64 + 1) + (13 + 8 + 1) + (12 + 64 + 1) + (13 + 16 + 0)
        bytes memory _msg = abi.encodePacked(
            "I authorize Ylide Faucet to publish my public key on my behalf to eliminate gas costs on my transaction for five minutes.\n\n", 
            "Public key: 0x", uint256ToHex(publicKey), "\n",
            "Registrar: 0x", uint32ToHex(bytes4(registrar)), "\n",
            "Chain ID: 0x", uint256ToHex(bytes32(block.chainid)), "\n",
            "Timestamp: 0x", uint64ToHex(bytes8(timestampLock))
        );
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _msg));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    receive() external payable {
        // do nothing
    }

    function internalKeyAttach(address addr, uint256 publicKey, uint32 keyVersion, uint32 registrar) internal {
        uint256 index = 0;
        if (addressToPublicKey[addr].keyVersion != 0) {
            index = storeBlockNumber(addressToPublicKey[addr].previousEventsIndex, addressToPublicKey[addr].block / 128);
        }

        addressToPublicKey[addr] = RegistryEntryV6(index, publicKey, uint64(block.number), uint64(block.timestamp), keyVersion, registrar);
        emit KeyAttached(addr, publicKey, keyVersion, registrar, index);
    }

    function attachPublicKey(uint256 publicKey, uint32 keyVersion, uint32 registrar) public notTerminated {
        require(keyVersion != 0, 'Key version must be above zero');

        internalKeyAttach(msg.sender, publicKey, keyVersion, registrar);
    }

    function attachPublicKeyByAdmin(uint8 _v, bytes32 _r, bytes32 _s, address payable addr, uint256 publicKey, uint32 keyVersion, uint32 registrar, uint64 timestampLock, address payable referrer, bool payBonus) external payable onlyBonucer notTerminated {
        require(keyVersion != 0, 'Key version must be above zero');
        require(verifyMessage(bytes32(publicKey), _v, _r, _s, registrar, timestampLock) == addr, 'Signature does not match the user''s address');
        require(referrer == address(0x0) || addressToPublicKey[referrer].keyVersion != 0, 'Referrer must be registered');
        require(addr != address(0x0) && addressToPublicKey[addr].keyVersion == 0, 'Only new user key can be assigned by admin');

        internalKeyAttach(addr, publicKey, keyVersion, registrar);

        if (payBonus && newcomerBonus != 0) {
            addr.transfer(newcomerBonus);
        }
        if (referrer != address(0x0) && referrerBonus != 0) {
            referrer.transfer(referrerBonus);
        }
    }
}


// File contracts/YlideSafe1.sol

pragma solidity ^0.8.17;



contract YlideSafeV1 is Owned, Pausable {
	uint256 public constant version = 1;

	IYlideMailer public ylideMailer;

	struct SafeArgs {
		address safeSender;
		address[] safeRecipients;
	}

	error InvalidSender();
	error InvalidArguments();

	event YlideMailerChanged(address indexed ylideMailer);
	event SafeMails(
		uint256 indexed contentId,
		address indexed safeSender,
		address[] safeRecipients
	);

	constructor(IYlideMailer _ylideMailer) Owned() Pausable() {
		ylideMailer = _ylideMailer;
	}

	function setYlideMailer(IYlideMailer _ylideMailer) external onlyOwner {
		ylideMailer = _ylideMailer;
		emit YlideMailerChanged(address(_ylideMailer));
	}

	function sendBulkMail(
		IYlideMailer.SendBulkArgs calldata args,
		IYlideMailer.SignatureArgs calldata signatureArgs,
		SafeArgs calldata safeArgs
	) external payable whenNotPaused returns (uint256) {
		_validate(args.recipients, signatureArgs.sender, safeArgs);

		uint256 contentId = ylideMailer.sendBulkMail{value: msg.value}(
			args,
			signatureArgs,
			IYlideMailer.Supplement(address(this), CONTRACT_TYPE_SAFE)
		);

		emit SafeMails(contentId, safeArgs.safeSender, safeArgs.safeRecipients);

		return contentId;
	}

	function addMailRecipients(
		IYlideMailer.AddMailRecipientsArgs calldata args,
		IYlideMailer.SignatureArgs calldata signatureArgs,
		SafeArgs calldata safeArgs
	) external payable whenNotPaused returns (uint256) {
		_validate(args.recipients, signatureArgs.sender, safeArgs);

		uint256 contentId = ylideMailer.addMailRecipients{value: msg.value}(
			args,
			signatureArgs,
			IYlideMailer.Supplement(address(this), CONTRACT_TYPE_SAFE)
		);

		emit SafeMails(contentId, safeArgs.safeSender, safeArgs.safeRecipients);

		return contentId;
	}

	function _validate(
		uint256[] calldata recipients,
		address sender,
		SafeArgs calldata safeArgs
	) internal view {
		if (sender != msg.sender) revert InvalidSender();
		if (recipients.length != safeArgs.safeRecipients.length) revert InvalidArguments();
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}


// File contracts/YlideRegistryV3.sol

pragma solidity ^0.8.9;

struct RegistryEntry {
   uint256 publicKey;
   uint128 block;
   uint64 timestamp;
   uint64 keyVersion;
}

contract YlideRegistryV3 {

    uint256 public version = 3;

    event KeyAttached(address indexed addr, uint256 publicKey, uint64 keyVersion);
    
    mapping(address => RegistryEntry) public addressToPublicKey;

    YlideRegistryV3 previousContract;

    constructor(address previousContractAddress) {
        previousContract = YlideRegistryV3(previousContractAddress);
    }

    function getPublicKey(address addr) view public returns (RegistryEntry memory entry, uint contractVersion, address contractAddress) {
        contractVersion = version;
        contractAddress = address(this);
        entry = addressToPublicKey[addr];
        if (entry.keyVersion == 0 && address(previousContract) != address(0x0)) {
            return previousContract.getPublicKey(addr);
        }
    }

    function attachPublicKey(uint256 publicKey, uint64 keyVersion) public {
        addressToPublicKey[msg.sender] = RegistryEntry(publicKey, uint128(block.number), uint64(block.timestamp), keyVersion);

        emit KeyAttached(msg.sender, publicKey, keyVersion);
    }
}