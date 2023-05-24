/**
 *Submitted for verification at Arbiscan on 2023-05-24
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/libraries/Address.sol

// SLI: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

pragma solidity ^0.8.2;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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


// File contracts/libraries/SafeERC20.sol

// SLI: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


// File contracts/utils/Context.sol

// SLI: MIT
pragma solidity ^0.8.2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/erc20/ERC20.sol

// SLI: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.2;


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
contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
        return _decimals;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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


// File contracts/roles/Ownable.sol

// SLI: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.2;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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


// File contracts/SNYToken.sol

// SLI: MIT
pragma solidity 0.8.2;


// SNYToken with Governance.
contract SNYToken is ERC20("Sunny Token", "SNY", 18), Ownable {
    ///  Creates `_amount` token to `_to`. Must only be called by the owner (FarmController).
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}


// File contracts/utils/NeedInitialize.sol

// SLI: MIT
pragma solidity ^0.8.2;

contract NeedInitialize {
    bool public initialized;

    modifier onlyInitializeOnce() {
        require(!initialized, "NeedInitialize: already initialized");
        _;
        initialized = true;
    }
}


// File contracts/SNYRate.sol

// SLI: MIT
pragma solidity 0.8.2;

contract SNYRate is NeedInitialize {
    struct Rate {
        uint256 startTime;
        uint256 rate;
    }

    // reward in seconds
    Rate[] public timeRate;

    function initialize(Rate[] calldata rates) external onlyInitializeOnce {
        require(rates.length > 0, "SNYRate: empty rate");
        require(rates[rates.length - 1].rate == 0, "SNYRate: never end");
        uint256 t = block.timestamp;
        for (uint256 i = 0; i < rates.length; ++i) {
            require(rates[i].startTime > t, "SNYRate: invalid");
            t = rates[i].startTime;
            timeRate.push(rates[i]);
        }
    }

    function calculateReward(uint256 start, uint256 end)
        external
        view
        returns (uint256 reward)
    {
        uint256 len = timeRate.length;
        reward = 0;
        for (uint256 i = 0; i < len; ++i) {
            if (i + 1 < len && start >= timeRate[i + 1].startTime) continue;
            uint256 l = timeRate[i].startTime;
            if (end <= l) break;
            if (l < start) l = start;
            uint256 r = end;
            if (i + 1 < len && timeRate[i + 1].startTime < r) {
                r = timeRate[i + 1].startTime;
            }
            reward = reward + timeRate[i].rate * (r - l);
        }
    }
}


// File contracts/utils/ReentrancyGuard.sol

// SLI: MIT
pragma solidity ^0.8.2;

contract ReentrancyGuard {
    // Locked state of mutex
    bool private locked = false;

    /// @dev Functions with this modifer cannot be reentered. The mutex will be locked
    ///      before function execution and unlocked after.
    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!locked, "REENTRANCY_ILLEGAL");

        // Lock mutex before function call
        locked = true;

        // Perform function call
        _;

        // Unlock mutex after function call
        locked = false;
    }
}


// File contracts/roles/Roles.sol

// SLI: MIT
pragma solidity ^0.8.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


// File contracts/roles/WhitelistAdminRole.sol

// SLI: MIT
pragma solidity ^0.8.2;


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor() {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(
            isWhitelistAdmin(_msgSender()),
            "WhitelistAdminRole: caller does not have the WhitelistAdmin role"
        );
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


// File contracts/roles/WhitelistedRole.sol

// SLI: MIT
pragma solidity ^0.8.2;



/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(
            isWhitelisted(_msgSender()),
            "WhitelistedRole: caller does not have the Whitelisted role"
        );
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}


// File contracts/VotingEscrow.sol

// SLI: MIT
pragma solidity 0.8.2;




contract VotingEscrow is ReentrancyGuard, WhitelistedRole, NeedInitialize {
    using SafeERC20 for IERC20;

    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 lastCheckpoint;
    uint256 totalLocked;
    uint256 nextWeekSupply;

    IERC20 token;

    uint256 public maxTime; // 4 years

    mapping(address => LockedBalance) public userInfo;
    mapping(uint256 => uint256) public historySupply;
    mapping(uint256 => uint256) public unlockSchedule;

    event LockCreated(
        address indexed account,
        uint256 amount,
        uint256 unlockTime
    );

    event AmountIncreased(address indexed account, uint256 increasedAmount);

    event UnlockTimeIncreased(address indexed account, uint256 newUnlockTime);

    event Withdrawn(address indexed account, uint256 amount);

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _token
    ) external onlyInitializeOnce {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        token = IERC20(token);

        lastCheckpoint = _adjustedTime(block.timestamp);

        maxTime = 4 * 365 * 86400;

        token = IERC20(_token);

        _addWhitelistAdmin(msg.sender);
    }

    // return start timestamp of lastest week
    function _adjustedTime(uint256 x) internal pure returns (uint256) {
        return (x / 1 weeks) * 1 weeks;
    }

    function createLock(uint256 _amount, uint256 _unlockTime)
        public
        nonReentrant
    {
        require(
            msg.sender == tx.origin || isWhitelisted(msg.sender),
            "VotingEscrow: sender is contract not in whitelist"
        );
        require(_amount > 0, "VotingEscrow: amount is zero");

        _unlockTime = _adjustedTime(_unlockTime);
        LockedBalance storage user = userInfo[msg.sender];

        require(user.amount == 0, "VotingEscrow: withdraw old tokens first");
        require(
            _unlockTime > block.timestamp,
            "VotingEscrow: unlock time < current timestamp"
        );
        require(
            _unlockTime <= block.timestamp + maxTime,
            "VotingEscrow: exceed maxlock time"
        );

        _checkpoint(_amount, _unlockTime, user.amount, user.unlockTime);

        unlockSchedule[_unlockTime] += _amount;
        user.unlockTime = _unlockTime;
        user.amount = _amount;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit LockCreated(msg.sender, _amount, _unlockTime);
    }

    function increaseAmount(address _account, uint256 _amount)
        external
        nonReentrant
    {
        LockedBalance storage user = userInfo[_account];

        require(_amount > 0, "VotingEscrow: amount is zero");
        require(user.amount > 0, "VotingEscrow: No existing lock found");
        require(
            user.unlockTime > block.timestamp,
            "VotingEscrow: Cannot add to expired lock"
        );

        uint256 newAmount = user.amount + _amount;
        _checkpoint(newAmount, user.unlockTime, user.amount, user.unlockTime);
        unlockSchedule[user.unlockTime] =
            unlockSchedule[user.unlockTime] +
            _amount;
        user.amount = newAmount;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit AmountIncreased(_account, _amount);
    }

    function increaseUnlockTime(uint256 _unlockTime) external nonReentrant {
        _unlockTime = _adjustedTime(_unlockTime);
        LockedBalance storage user = userInfo[msg.sender];

        require(user.amount > 0, "VotingEscrow: No existing lock found");
        require(
            user.unlockTime > block.timestamp,
            "VotingEscrow: Lock expired"
        );
        require(
            _unlockTime > user.unlockTime,
            "VotingEscrow: Can only increase lock duration"
        );
        require(
            _unlockTime <= block.timestamp + maxTime,
            "VotingEscrow: Voting lock cannot exceed max lock time"
        );

        _checkpoint(user.amount, _unlockTime, user.amount, user.unlockTime);
        unlockSchedule[user.unlockTime] =
            unlockSchedule[user.unlockTime] -
            user.amount;
        unlockSchedule[_unlockTime] = unlockSchedule[_unlockTime] + user.amount;
        user.unlockTime = _unlockTime;

        emit UnlockTimeIncreased(msg.sender, _unlockTime);
    }

    function withdraw() external nonReentrant {
        LockedBalance memory user = userInfo[msg.sender];
        require(
            block.timestamp >= user.unlockTime,
            "VotingEscrow: The lock is not expired"
        );

        uint256 amount = user.amount;
        user.unlockTime = 0;
        user.amount = 0;
        userInfo[msg.sender] = user;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function totalSupply() external view returns (uint256 result) {
        uint256 w = lastCheckpoint;
        uint256 currentWeek = _adjustedTime(block.timestamp);
        uint256 newTotalLocked = totalLocked;
        uint256 newNextWeekSupply = nextWeekSupply;
        if (w < currentWeek) {
            w += 1 weeks;
            for (; w < currentWeek; w += 1 weeks) {
                newTotalLocked = newTotalLocked - unlockSchedule[w];
                newNextWeekSupply =
                    newNextWeekSupply -
                    (newTotalLocked * 1 weeks) /
                    maxTime;
            }
            newTotalLocked = newTotalLocked - unlockSchedule[currentWeek];
            result =
                newNextWeekSupply -
                (newTotalLocked * (block.timestamp - currentWeek)) /
                maxTime;
        } else {
            result =
                newNextWeekSupply +
                (newTotalLocked * (currentWeek + 1 weeks - block.timestamp)) /
                maxTime;
        }
    }

    function totalSupplyAtTimestamp(uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return _totalSupplyAtTimestamp(_timestamp);
    }

    function _totalSupplyAtTimestamp(uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 w = _adjustedTime(_timestamp) + 1 weeks;
        uint256 total = 0;
        for (; w <= _timestamp + maxTime; w += 1 weeks) {
            total = total + (unlockSchedule[w] * (w - _timestamp)) / maxTime;
        }
        return total;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return _balanceOfAtTimestamp(_account, block.timestamp);
    }

    function balanceOfAtTimestamp(address _account, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return _balanceOfAtTimestamp(_account, _timestamp);
    }

    function _balanceOfAtTimestamp(address _account, uint256 _timestamp)
        private
        view
        returns (uint256)
    {
        require(
            _timestamp >= block.timestamp,
            "VotingEscrow: Must be current or future time"
        );
        LockedBalance memory user = userInfo[_account];
        if (_timestamp > user.unlockTime) {
            return 0;
        }
        return (user.amount * (user.unlockTime - _timestamp)) / maxTime;
    }

    function checkpoint() external {
        _checkpoint(0, 0, 0, 0);
    }

    function _checkpoint(
        uint256 _newAmount,
        uint256 _newUnlockTime,
        uint256 _oldAmount,
        uint256 _oldUnlockTime
    ) internal {
        // update supply to current week
        uint256 w = lastCheckpoint;
        uint256 currentWeek = _adjustedTime(block.timestamp);
        uint256 newTotalLocked = totalLocked;
        uint256 newNextWeekSupply = nextWeekSupply;
        if (w < currentWeek) {
            w += 1 weeks;
            for (; w <= currentWeek; w += 1 weeks) {
                historySupply[w] = newNextWeekSupply;
                newTotalLocked = newTotalLocked - unlockSchedule[w];
                newNextWeekSupply =
                    newNextWeekSupply -
                    (newTotalLocked * 1 weeks) /
                    maxTime;
            }
            lastCheckpoint = currentWeek;
        }

        // remove old schedule
        uint256 nextWeek = currentWeek + 1 weeks;
        if (_oldAmount > 0 && _oldUnlockTime >= nextWeek) {
            newTotalLocked = newTotalLocked - _oldAmount;
            newNextWeekSupply =
                newNextWeekSupply -
                (_oldAmount * (_oldUnlockTime - nextWeek)) /
                maxTime;
        }

        totalLocked = newTotalLocked + _newAmount;
        nextWeekSupply =
            newNextWeekSupply +
            (_newAmount * (_newUnlockTime - nextWeek) + maxTime - 1) /
            maxTime;
    }
}


// File contracts/FarmController.sol

// SLI: MIT
pragma solidity 0.8.2;






contract FarmController is NeedInitialize, WhitelistedRole {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 workingSupply; // boosted user share.
        uint256 rewardPerShare; // Accumulated reward per share.
        uint256 pendingReward; // reward not claimed
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardTime; // Last block number that CAKEs distribution occurs.
        uint256 totalSupply; // token total supply.
        uint256 workingSupply; // boosted token supply.
        uint256 accRewardPerShare; // Accumulated reward per share.
    }

    SNYToken public sny;
    VotingEscrow public votingEscrow;
    // user_boost_share = min(
    //   user_stake_amount,
    //   k% * user_stake_amount + (1 - k%) * total_stake_amount * (user_locked_share / total_locked_share)
    // )
    uint256 public k;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // treasury address
    address public treasuryAddr;
    // market address
    address public marketAddr;
    // dev address
    address public devAddr;
    // SNY Rate
    address public snyRate;
    // reward claimable
    bool public claimable;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateWorkingSupply(
        address indexed user,
        uint256 indexed pid,
        uint256 workingSupply
    );

    function initialize(
        address _treasuryAddr,
        address _marketAddr,
        address _devAddr,
        address _votingEscrow,
        address _snyRate,
        address _sny, // reward token
        uint256 _startTime,
        address _token // first pool
    ) external onlyInitializeOnce {
        _addWhitelistAdmin(msg.sender);

        snyRate = _snyRate;
        treasuryAddr = _treasuryAddr;
        marketAddr = _marketAddr;
        devAddr = _devAddr;

        sny = SNYToken(_sny);
        votingEscrow = VotingEscrow(_votingEscrow);

        // first farming pool
        poolInfo.push(
            PoolInfo({
                token: IERC20(_token),
                allocPoint: 1000,
                lastRewardTime: _startTime,
                totalSupply: 0,
                workingSupply: 0,
                accRewardPerShare: 0
            })
        );

        totalAllocPoint = 1000;
        k = 33;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 offset)
        external
        view
        returns (PoolInfo[] memory result)
    {
        uint256 n =
            offset + 100 < poolInfo.length ? offset + 100 : poolInfo.length;
        if (n > offset) {
            result = new PoolInfo[](n - offset);
            for (uint256 i = offset; i < n; ++i) {
                result[i - offset] = poolInfo[i];
            }
        }
    }

    // Add a new lp to the pool. Can only be called by the whitelist admin.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint256 _startTime,
        bool _withUpdate
    ) external onlyWhitelistAdmin {
        if (_withUpdate) {
            massUpdatePools();
        }
        if (_startTime < block.timestamp) _startTime = block.timestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardTime: _startTime,
                totalSupply: 0,
                workingSupply: 0,
                accRewardPerShare: 0
            })
        );
    }

    // Update the given pool's reward allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyWhitelistAdmin {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint - prevAllocPoint + _allocPoint;
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        _updatePool(_pid);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        if (pool.totalSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 reward =
            (SNYRate(snyRate).calculateReward(
                pool.lastRewardTime,
                block.timestamp
            ) * pool.allocPoint) / totalAllocPoint;
        // reward allocation
        sny.mint(treasuryAddr, (reward * 15) / 100);
        sny.mint(devAddr, (reward * 15) / 100);
        sny.mint(marketAddr, (reward * 20) / 100);
        reward = (reward * 50) / 100;
        // update prefix sum
        pool.accRewardPerShare =
            pool.accRewardPerShare +
            (reward * (10**pool.token.decimals())) /
            pool.workingSupply;
        pool.lastRewardTime = block.timestamp;
    }

    function _updateUser(uint256 _pid, address _user)
        internal
        returns (uint256 reward)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        reward =
            (user.workingSupply *
                (pool.accRewardPerShare - user.rewardPerShare)) /
            (10**pool.token.decimals());
        reward += user.pendingReward;
        if (claimable) {
            user.pendingReward = 0;
            sny.mint(_user, reward);
        } else {
            user.pendingReward = reward;
        }
        user.rewardPerShare = pool.accRewardPerShare;
    }

    function _checkpoint(uint256 _pid, address _user) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 l = (k * user.amount) / 100;
        uint256 votingTotal = votingEscrow.totalSupply();
        if (votingTotal > 0)
            l +=
                (((pool.totalSupply * votingEscrow.balanceOf(_user)) /
                    votingTotal) * (100 - k)) /
                100;
        if (l > user.amount) l = user.amount;
        pool.workingSupply = pool.workingSupply + l - user.workingSupply;
        user.workingSupply = l;
        emit UpdateWorkingSupply(_user, _pid, l);
    }

    // Deposit tokens to Controller for reward allocation.
    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward)
    {
        _updatePool(_pid);
        reward = _updateUser(_pid, msg.sender);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (_amount > 0) {
            pool.token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount += _amount;
            pool.totalSupply += _amount;
        }
        _checkpoint(_pid, msg.sender);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens from Controller.
    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "FarmController: bad withdraw amount");

        _updatePool(_pid);
        reward = _updateUser(_pid, msg.sender);
        if (_amount > 0) {
            user.amount -= _amount;
            pool.totalSupply -= _amount;
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        _checkpoint(_pid, msg.sender);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // kick someone from boosting if his/her locked share expired
    function kick(uint256 _pid, address _user) external {
        require(
            votingEscrow.balanceOf(_user) == 0,
            "FarmController: user locked balance is not zero"
        );
        UserInfo storage user = userInfo[_pid][_user];
        uint256 oldWorkingSupply = user.workingSupply;
        _updatePool(_pid);
        _updateUser(_pid, _user);
        _checkpoint(_pid, _user);
        require(
            oldWorkingSupply > user.workingSupply,
            "FarmController: user working supply is up-to-date"
        );
    }

    /* ==== admin functions ==== */
    function setAddr(
        address _treasuryAddr,
        address _marketAddr,
        address _devAddr
    ) external onlyWhitelistAdmin {
        treasuryAddr = _treasuryAddr;
        marketAddr = _marketAddr;
        devAddr = _devAddr;
    }

    function setClaimable(bool _claimable) external onlyWhitelistAdmin {
        claimable = _claimable;
    }
}