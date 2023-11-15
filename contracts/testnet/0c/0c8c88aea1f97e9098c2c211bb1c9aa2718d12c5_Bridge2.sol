/**
 *Submitted for verification at Arbiscan.io on 2023-11-14
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/Signature.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Agent {
  string source;
  bytes32 connectionId;
}

struct Signature {
  uint256 r;
  uint256 s;
  uint8 v;
}

bytes32 constant EIP712_DOMAIN_SEPARATOR = keccak256(
  "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

bytes32 constant AGENT_TYPEHASH = keccak256("Agent(string source,bytes32 connectionId)");

address constant VERIFYING_CONTRACT = address(0);

function hash(Agent memory agent) pure returns (bytes32) {
  return keccak256(abi.encode(AGENT_TYPEHASH, keccak256(bytes(agent.source)), agent.connectionId));
}

function makeDomainSeparator() view returns (bytes32) {
  return
    keccak256(
      abi.encode(
        EIP712_DOMAIN_SEPARATOR,
        keccak256(bytes("Exchange")),
        keccak256(bytes("1")),
        block.chainid,
        VERIFYING_CONTRACT
      )
    );
}

function recoverSigner(
  bytes32 dataHash,
  Signature memory sig,
  bytes32 domainSeparator
) pure returns (address) {
  bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, dataHash));
  address signerRecovered = ecrecover(digest, sig.v, bytes32(sig.r), bytes32(sig.s));
  require(signerRecovered != address(0), "Invalid signature, recovered the zero address");

  return signerRecovered;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;





/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}


// File @arbitrum/nitro-contracts/src/precompiles/[email protected]

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );

    error InvalidBlockNumber(uint256 requested, uint256 current);
}


// File contracts/Bridge2.sol


/*
    This bridge contract runs on Arbitrum, operating alongside the Hyperliquid L1.
    The only asset for now is USDC, though the logic extends to any other ERC20 token on Arbitrum.
    The L1 runs tendermint consensus, with validator set updates happening at the end of each epoch.
    Epoch duration TBD, but likely somewhere between 1 day and 1 week.
    "Bridge2" is to distinguish from the legacy Bridge contract.

    Validators:
      Each validator has a hot (in memory) and cold wallet.
      Automated withdrawals and validator set updates are approved by 2/3 of the validator power,
      signed by hot wallets.
      For additional security, withdrawals and validator set updates are pending for a dispute period.
      During this period, any locker may lock the bridge (preventing further withdrawals or updates).
      To unlock the bridge, a quorum of cold wallet signatures is required.

    Validator set updates:
      The active validators sign a hash of the new validator set and powers on the L1.
      This contract checks those signatures, and updates the hash of the active validator set.
      The active validators' L1 stake is still locked for at least one more epoch (unbonding period),
      and the new validators will slash the old ones' stake if they do not properly generate the validator set update signatures.
      The validator set change is pending for a period of time for the lockers to dispute the change.

    Withdrawals:
      The validators sign withdrawals on the L1, which the user sends to this contract in requestWithdrawal()
      This contract checks the signatures, and then creates a pending withdrawal which can be disputed for a period of time.
      After the dispute period has elapsed (measured in both time and blocks), a second transaction can be sent to finalize the withdrawal and release the USDC.

    Deposits:
      The validators on the L1 listen for and sign DepositEvent events emitted by this contract,
      crediting the L1 with the equivalent USDC. No additional work needs to be done on this contract.

    Signatures:
      For withdrawals and validator set updates, the signatures are sent to the bridge contract
      in the same order as the active validator set, i.e. signing validators should be a subsequence
      of active validators.

    Lockers:
      These addresses are approved by the validators to lock the contract if submitted signatures do not match
      the locker's view of the L1. Once locked, only a quorum of cold wallet validator signatures can unlock the bridge.
      This dispute period is used for both withdrawals and validator set updates.
      L1 operation will automatically register all validator hot addresses as lockers.
      Adding a locker requires hot wallet quorum, and removing requires cold wallet quorum.

    Finalizers:
      These addresses are approved by the validators to finalize withdrawals and validator set updates.
      While not strictly necessary due to the locking mechanism, this adds an additional layer of security without sacrificing functionality.
      Even if locking transactions are censored (which should be economically infeasible), this still requires attackers to control a finalizer private key.
      L1 operation will eventually register all validator hot addresses as finalizers,
      though there may be an intermediate phase where finalizers are a subset of trusted validators.
      Adding a finalizer requires hot wallet quorum, and removing requires cold wallet quorum.

    Unlocking:
      When the bridge is unlocked, a new validator set is atomically set and finalized.
      This is safe because the unlocking message is signed by a quorum of validator cold wallets.

    The L1 will ensure the following, though neither is required by the smart contract:
      1. The order of active validators are ordered in decreasing order of power.
      2. The validators are unique.

    On epoch changes, the L1 will ensure that new signatures are generated for unclaimed withdrawals
    for any validators that have changed.

    This bridge contract assumes there will be 20-30 validators on the L1, so signature sets fit in a single tx.
*/

pragma solidity ^0.8.9;







struct ValidatorSet {
  uint64 epoch;
  address[] validators;
  uint64[] powers;
}

struct ValidatorSetUpdateRequest {
  uint64 epoch;
  address[] hotAddresses;
  address[] coldAddresses;
  uint64[] powers;
}

struct PendingValidatorSetUpdate {
  uint64 epoch;
  uint64 totalValidatorPower;
  uint64 updateTime;
  uint64 updateBlockNumber;
  uint64 nValidators;
  bytes32 hotValidatorSetHash;
  bytes32 coldValidatorSetHash;
}

struct Withdrawal {
  address user;
  address destination;
  uint64 usdc;
  uint64 nonce;
  uint64 requestedTime;
  uint64 requestedBlockNumber;
  bytes32 message;
}

struct WithdrawalRequest {
  address user;
  address destination;
  uint64 usd;
  uint64 nonce;
  Signature[] signatures;
}

struct DepositWithPermit {
  address user;
  uint64 amount;
  uint64 deadline;
  Signature signature;
}

contract Bridge2 is Pausable, ReentrancyGuard {
  using SafeERC20 for ERC20Permit;
  ERC20Permit public usdcToken;

  bytes32 public hotValidatorSetHash;
  bytes32 public coldValidatorSetHash;
  PendingValidatorSetUpdate public pendingValidatorSetUpdate;

  mapping(bytes32 => bool) public usedMessages;
  mapping(address => bool) public lockers;
  mapping(address => bool) public lockerVotes;
  address[] public lockersVotingLock;
  uint64 public lockerThreshold;

  mapping(address => bool) public finalizers;
  uint64 public epoch;
  uint64 public totalValidatorPower;
  uint64 public disputePeriodSeconds;
  // Need higher resolution than seconds for Arbitrum.
  uint64 public blockDurationMillis;

  // Expose this for convenience because we only store the hash.
  // The uniqueness of the validators is enforced on the L1 side.
  // However, no functionality breaks even if addresses are repeated.
  uint64 public nValidators;

  mapping(bytes32 => Withdrawal) public requestedWithdrawals;
  mapping(bytes32 => bool) public finalizedWithdrawals;
  mapping(bytes32 => bool) public withdrawalsInvalidated;

  bytes32 immutable domainSeparator;

  // These events wrap structs because of a quirk of rust client code which parses them.
  event Deposit(address indexed user, uint64 usdc);

  event RequestedWithdrawal(
    address indexed user,
    address destination,
    uint64 usdc,
    uint64 nonce,
    bytes32 message,
    uint64 requestedTime
  );

  event FinalizedWithdrawal(
    address indexed user,
    address destination,
    uint64 usdc,
    uint64 nonce,
    bytes32 message
  );

  event RequestedValidatorSetUpdate(
    uint64 epoch,
    bytes32 hotValidatorSetHash,
    bytes32 coldValidatorSetHash,
    uint64 updateTime
  );

  event FinalizedValidatorSetUpdate(
    uint64 epoch,
    bytes32 hotValidatorSetHash,
    bytes32 coldValidatorSetHash
  );

  event FailedWithdrawal(bytes32 message, uint32 errorCode);
  event ModifiedLocker(address indexed locker, bool isLocker);
  event DepositWithPermitInsufficientAmount(address user, uint64 amount);
  event ModifiedFinalizer(address indexed finalizer, bool isFinalizer);
  event ChangedDisputePeriodSeconds(uint64 newDisputePeriodSeconds);
  event ChangedBlockDurationMillis(uint64 newBlockDurationMillis);
  event ChangedLockerThreshold(uint64 newLockerThreshold);
  event InvalidatedWithdrawal(Withdrawal withdrawal);

  // We could have the deployer initialize separately so that all function args in this file can be calldata.
  // However, calldata does not seem cheaper than memory on Arbitrum, so not a big deal for now.
  constructor(
    address[] memory hotAddresses,
    address[] memory coldAddresses,
    uint64[] memory powers,
    address usdcAddress,
    uint64 _disputePeriodSeconds,
    uint64 _blockDurationMillis,
    uint64 _lockerThreshold
  ) {
    domainSeparator = makeDomainSeparator();
    totalValidatorPower = checkNewValidatorPowers(powers);

    require(
      hotAddresses.length == coldAddresses.length,
      "Hot and cold validator sets length mismatch"
    );
    nValidators = uint64(hotAddresses.length);

    ValidatorSet memory hotValidatorSet;
    hotValidatorSet = ValidatorSet({ epoch: 0, validators: hotAddresses, powers: powers });
    bytes32 newHotValidatorSetHash = makeValidatorSetHash(hotValidatorSet);
    hotValidatorSetHash = newHotValidatorSetHash;

    ValidatorSet memory coldValidatorSet;
    coldValidatorSet = ValidatorSet({ epoch: 0, validators: coldAddresses, powers: powers });
    bytes32 newColdValidatorSetHash = makeValidatorSetHash(coldValidatorSet);
    coldValidatorSetHash = newColdValidatorSetHash;

    usdcToken = ERC20Permit(usdcAddress);
    disputePeriodSeconds = _disputePeriodSeconds;
    blockDurationMillis = _blockDurationMillis;
    lockerThreshold = _lockerThreshold;
    addLockersAndFinalizers(hotAddresses);

    emit RequestedValidatorSetUpdate(
      0,
      hotValidatorSetHash,
      coldValidatorSetHash,
      uint64(block.timestamp)
    );

    pendingValidatorSetUpdate = PendingValidatorSetUpdate({
      epoch: 0,
      totalValidatorPower: totalValidatorPower,
      updateTime: 0,
      updateBlockNumber: getCurBlockNumber(),
      hotValidatorSetHash: hotValidatorSetHash,
      coldValidatorSetHash: coldValidatorSetHash,
      nValidators: nValidators
    });

    emit FinalizedValidatorSetUpdate(0, hotValidatorSetHash, coldValidatorSetHash);
  }

  function addLockersAndFinalizers(address[] memory addresses) private {
    uint64 end = uint64(addresses.length);
    for (uint64 idx; idx < end; idx++) {
      address _address = addresses[idx];
      lockers[_address] = true;
      finalizers[_address] = true;
    }
  }

  // A utility function to make a checkpoint of the validator set supplied.
  // The checkpoint is the hash of all the validators, the powers and the epoch.
  function makeValidatorSetHash(ValidatorSet memory validatorSet) private pure returns (bytes32) {
    require(
      validatorSet.validators.length == validatorSet.powers.length,
      "Malformed validator set"
    );

    bytes32 checkpoint = keccak256(
      abi.encode(validatorSet.validators, validatorSet.powers, validatorSet.epoch)
    );
    return checkpoint;
  }

  // An external function anyone can call to withdraw usdc from the bridge by providing valid signatures
  // from the active L1 validators.
  function requestWithdrawal(
    address user,
    address destination,
    uint64 usdc,
    uint64 nonce,
    ValidatorSet calldata hotValidatorSet,
    Signature[] memory signatures
  ) internal whenNotPaused returns (uint32, bytes32) {
    // NOTE: this is a temporary workaround because EIP-191 signatures do not match between rust client and solidity.
    // For now we do not care about the overhead with EIP-712 because Arbitrum gas is cheap.
    bytes32 data = keccak256(abi.encode("requestWithdrawal", user, destination, usdc, nonce));
    bytes32 message = makeMessage(data);
    checkValidWithdrawal(message);
    Withdrawal memory withdrawal = Withdrawal({
      user: user,
      destination: destination,
      usdc: usdc,
      nonce: nonce,
      requestedTime: uint64(block.timestamp),
      requestedBlockNumber: getCurBlockNumber(),
      message: message
    });
    if (requestedWithdrawals[message].requestedTime != 0) {
      return (0, message);
    }
    checkValidatorSignatures(message, hotValidatorSet, signatures, hotValidatorSetHash);
    requestedWithdrawals[message] = withdrawal;
    emit RequestedWithdrawal(
      withdrawal.user,
      withdrawal.destination,
      withdrawal.usdc,
      withdrawal.nonce,
      withdrawal.message,
      withdrawal.requestedTime
    );
    return (type(uint32).max, 0);
  }

  function batchedRequestWithdrawals(
    WithdrawalRequest[] memory withdrawalRequests,
    ValidatorSet calldata hotValidatorSet
  ) external nonReentrant whenNotPaused {
    uint64 end = uint64(withdrawalRequests.length);
    for (uint64 idx; idx < end; idx++) {
      WithdrawalRequest memory withdrawalRequest = withdrawalRequests[idx];
      (uint32 errorCode, bytes32 message) = requestWithdrawal(
        withdrawalRequest.user,
        withdrawalRequest.destination,
        withdrawalRequest.usd,
        withdrawalRequest.nonce,
        hotValidatorSet,
        withdrawalRequest.signatures
      );
      if (errorCode != type(uint32).max) {
        emit FailedWithdrawal(message, errorCode);
      }
    }
  }

  function finalizeWithdrawal(bytes32 message) internal returns (uint32) {
    checkValidWithdrawal(message);

    if (finalizedWithdrawals[message]) {
      return 1;
    }

    Withdrawal memory withdrawal = requestedWithdrawals[message];
    if (withdrawal.user == address(0)) {
      return 2;
    }

    uint32 errorCode = checkDisputePeriod(
      withdrawal.requestedTime,
      withdrawal.requestedBlockNumber
    );

    if (errorCode != type(uint32).max) {
      return errorCode;
    }

    finalizedWithdrawals[message] = true;
    usdcToken.safeTransfer(withdrawal.destination, withdrawal.usdc);
    emit FinalizedWithdrawal(
      withdrawal.user,
      withdrawal.destination,
      withdrawal.usdc,
      withdrawal.nonce,
      withdrawal.message
    );
    return type(uint32).max;
  }

  function batchedFinalizeWithdrawals(
    bytes32[] calldata messages
  ) external nonReentrant whenNotPaused {
    checkFinalizer(msg.sender);
    uint64 end = uint64(messages.length);
    for (uint64 idx; idx < end; idx++) {
      uint32 errorCode = finalizeWithdrawal(messages[idx]);
      if (errorCode != type(uint32).max) {
        emit FailedWithdrawal(messages[idx], errorCode);
      }
    }
  }

  function checkValidWithdrawal(bytes32 message) private view {
    require(!withdrawalsInvalidated[message], "Withdrawal has been invalidated.");
  }

  function getCurBlockNumber() private view returns (uint64) {
    if (block.chainid == 1337) {
      return uint64(block.number);
    } else {
      return uint64(ArbSys(address(100)).arbBlockNumber());
    }
  }

  function checkDisputePeriod(uint64 time, uint64 blockNumber) private view returns (uint32) {
    bool enoughTimePassed = block.timestamp > time + disputePeriodSeconds;
    if (!enoughTimePassed) {
      return 3;
    }

    uint64 curBlockNumber = getCurBlockNumber();

    bool enoughBlocksPassed = (curBlockNumber - blockNumber) * blockDurationMillis >
      1000 * disputePeriodSeconds;
    if (!enoughBlocksPassed) {
      return 4;
    }

    return type(uint32).max;
  }

  // Utility function that verifies the signatures supplied and checks that the validators have reached quorum.
  function checkValidatorSignatures(
    bytes32 message,
    ValidatorSet memory activeValidatorSet, // Active set of all L1 validators
    Signature[] memory signatures,
    bytes32 validatorSetHash
  ) private view {
    require(
      makeValidatorSetHash(activeValidatorSet) == validatorSetHash,
      "Supplied active validators and powers do not match the active checkpoint"
    );

    uint64 nSignatures = uint64(signatures.length);
    require(nSignatures > 0, "Signers empty");
    uint64 cumulativePower;
    uint64 signatureIdx;
    uint64 end = uint64(activeValidatorSet.validators.length);

    for (uint64 activeValidatorSetIdx; activeValidatorSetIdx < end; activeValidatorSetIdx++) {
      address signer = recoverSigner(message, signatures[signatureIdx], domainSeparator);
      if (signer == activeValidatorSet.validators[activeValidatorSetIdx]) {
        uint64 power = activeValidatorSet.powers[activeValidatorSetIdx];
        cumulativePower += power;

        if (3 * cumulativePower > 2 * totalValidatorPower) {
          break;
        }

        signatureIdx += 1;
        if (signatureIdx >= nSignatures) {
          break;
        }
      }
    }

    require(
      3 * cumulativePower > 2 * totalValidatorPower,
      "Submitted validator set signatures do not have enough power"
    );
  }

  function checkMessageNotUsed(bytes32 message) private {
    require(!usedMessages[message], "message already used");
    usedMessages[message] = true;
  }

  // This function updates the validator set by checking that the active validators have signed
  // off on the new validator set
  function updateValidatorSet(
    ValidatorSetUpdateRequest memory newValidatorSet,
    ValidatorSet memory activeHotValidatorSet,
    Signature[] memory signatures
  ) external whenNotPaused {
    require(
      makeValidatorSetHash(activeHotValidatorSet) == hotValidatorSetHash,
      "Supplied active validators and powers do not match checkpoint"
    );

    bytes32 data = keccak256(
      abi.encode(
        "updateValidatorSet",
        newValidatorSet.epoch,
        newValidatorSet.hotAddresses,
        newValidatorSet.coldAddresses,
        newValidatorSet.powers
      )
    );
    bytes32 message = makeMessage(data);

    updateValidatorSetInner(newValidatorSet, activeHotValidatorSet, signatures, message, false);
  }

  function updateValidatorSetInner(
    ValidatorSetUpdateRequest memory newValidatorSet,
    ValidatorSet memory activeValidatorSet,
    Signature[] memory signatures,
    bytes32 message,
    bool useColdValidatorSet
  ) private {
    require(
      newValidatorSet.hotAddresses.length == newValidatorSet.coldAddresses.length,
      "New hot and cold validator sets length mismatch"
    );

    require(
      newValidatorSet.hotAddresses.length == newValidatorSet.powers.length,
      "New validator set and powers length mismatch"
    );

    require(
      newValidatorSet.epoch > activeValidatorSet.epoch,
      "New validator set epoch must be greater than the active epoch"
    );

    uint64 newTotalValidatorPower = checkNewValidatorPowers(newValidatorSet.powers);

    bytes32 validatorSetHash;
    if (useColdValidatorSet) {
      validatorSetHash = coldValidatorSetHash;
    } else {
      validatorSetHash = hotValidatorSetHash;
    }

    checkValidatorSignatures(message, activeValidatorSet, signatures, validatorSetHash);

    ValidatorSet memory newHotValidatorSet;
    newHotValidatorSet = ValidatorSet({
      epoch: newValidatorSet.epoch,
      validators: newValidatorSet.hotAddresses,
      powers: newValidatorSet.powers
    });
    bytes32 newHotValidatorSetHash = makeValidatorSetHash(newHotValidatorSet);

    ValidatorSet memory newColdValidatorSet;
    newColdValidatorSet = ValidatorSet({
      epoch: newValidatorSet.epoch,
      validators: newValidatorSet.coldAddresses,
      powers: newValidatorSet.powers
    });
    bytes32 newColdValidatorSetHash = makeValidatorSetHash(newColdValidatorSet);

    uint64 updateTime = uint64(block.timestamp);
    pendingValidatorSetUpdate = PendingValidatorSetUpdate({
      epoch: newValidatorSet.epoch,
      totalValidatorPower: newTotalValidatorPower,
      updateTime: updateTime,
      updateBlockNumber: getCurBlockNumber(),
      hotValidatorSetHash: newHotValidatorSetHash,
      coldValidatorSetHash: newColdValidatorSetHash,
      nValidators: uint64(newHotValidatorSet.validators.length)
    });

    emit RequestedValidatorSetUpdate(
      newValidatorSet.epoch,
      newHotValidatorSetHash,
      newColdValidatorSetHash,
      updateTime
    );
  }

  function finalizeValidatorSetUpdate() external nonReentrant whenNotPaused {
    checkFinalizer(msg.sender);

    require(
      pendingValidatorSetUpdate.updateTime != 0,
      "Pending validator set update already finalized"
    );

    uint32 errorCode = checkDisputePeriod(
      pendingValidatorSetUpdate.updateTime,
      pendingValidatorSetUpdate.updateBlockNumber
    );
    require(errorCode == type(uint32).max, "Still in dispute period");

    finalizeValidatorSetUpdateInner();
  }

  function finalizeValidatorSetUpdateInner() private {
    hotValidatorSetHash = pendingValidatorSetUpdate.hotValidatorSetHash;
    coldValidatorSetHash = pendingValidatorSetUpdate.coldValidatorSetHash;
    epoch = pendingValidatorSetUpdate.epoch;
    totalValidatorPower = pendingValidatorSetUpdate.totalValidatorPower;
    nValidators = pendingValidatorSetUpdate.nValidators;
    pendingValidatorSetUpdate.updateTime = 0;

    emit FinalizedValidatorSetUpdate(
      epoch,
      pendingValidatorSetUpdate.hotValidatorSetHash,
      pendingValidatorSetUpdate.coldValidatorSetHash
    );
  }

  function makeMessage(bytes32 data) private view returns (bytes32) {
    Agent memory agent = Agent("a", keccak256(abi.encode(address(this), data)));
    return hash(agent);
  }

  function modifyLocker(
    address locker,
    bool _isLocker,
    uint64 nonce,
    ValidatorSet calldata activeValidatorSet,
    Signature[] memory signatures
  ) external {
    bytes32 data = keccak256(abi.encode("modifyLocker", locker, _isLocker, nonce));
    bytes32 message = makeMessage(data);

    bytes32 validatorSetHash;
    if (_isLocker) {
      validatorSetHash = hotValidatorSetHash;
    } else {
      validatorSetHash = coldValidatorSetHash;
    }

    checkMessageNotUsed(message);
    checkValidatorSignatures(message, activeValidatorSet, signatures, validatorSetHash);
    if (lockers[locker] && !_isLocker && !paused()) {
      removeLockerVote(locker);
    }
    lockers[locker] = _isLocker;
    emit ModifiedLocker(locker, _isLocker);
  }

  function modifyFinalizer(
    address finalizer,
    bool _isFinalizer,
    uint64 nonce,
    ValidatorSet calldata activeValidatorSet,
    Signature[] memory signatures
  ) external {
    bytes32 data = keccak256(abi.encode("modifyFinalizer", finalizer, _isFinalizer, nonce));
    bytes32 message = makeMessage(data);

    bytes32 validatorSetHash;
    if (_isFinalizer) {
      validatorSetHash = hotValidatorSetHash;
    } else {
      validatorSetHash = coldValidatorSetHash;
    }

    checkMessageNotUsed(message);
    checkValidatorSignatures(message, activeValidatorSet, signatures, validatorSetHash);
    finalizers[finalizer] = _isFinalizer;
    emit ModifiedFinalizer(finalizer, _isFinalizer);
  }

  function checkFinalizer(address finalizer) private view {
    require(finalizers[finalizer], "Sender is not a finalizer");
  }

  // This function checks that the total power of the new validator set is greater than zero.
  function checkNewValidatorPowers(uint64[] memory powers) private pure returns (uint64) {
    uint64 cumulativePower;
    for (uint64 i; i < powers.length; i++) {
      cumulativePower += powers[i];
    }

    require(cumulativePower > 0, "Submitted validator powers must be greater than zero");
    return cumulativePower;
  }

  function changeDisputePeriodSeconds(
    uint64 newDisputePeriodSeconds,
    uint64 nonce,
    ValidatorSet memory activeColdValidatorSet,
    Signature[] memory signatures
  ) external {
    bytes32 data = keccak256(
      abi.encode("changeDisputePeriodSeconds", newDisputePeriodSeconds, nonce)
    );
    bytes32 message = makeMessage(data);
    checkMessageNotUsed(message);
    checkValidatorSignatures(message, activeColdValidatorSet, signatures, coldValidatorSetHash);

    disputePeriodSeconds = newDisputePeriodSeconds;
    emit ChangedDisputePeriodSeconds(newDisputePeriodSeconds);
  }

  function invalidateWithdrawals(
    bytes32[] memory messages,
    uint64 nonce,
    ValidatorSet memory activeColdValidatorSet,
    Signature[] memory signatures
  ) external {
    bytes32 data = keccak256(abi.encode("invalidateWithdrawals", messages, nonce));
    bytes32 message = makeMessage(data);

    checkMessageNotUsed(message);
    checkValidatorSignatures(message, activeColdValidatorSet, signatures, coldValidatorSetHash);

    uint64 end = uint64(messages.length);
    for (uint64 idx; idx < end; idx++) {
      withdrawalsInvalidated[messages[idx]] = true;
      emit InvalidatedWithdrawal(requestedWithdrawals[messages[idx]]);
    }
  }

  function changeBlockDurationMillis(
    uint64 newBlockDurationMillis,
    uint64 nonce,
    ValidatorSet memory activeColdValidatorSet,
    Signature[] memory signatures
  ) external {
    bytes32 data = keccak256(
      abi.encode("changeBlockDurationMillis", newBlockDurationMillis, nonce)
    );
    bytes32 message = makeMessage(data);

    checkMessageNotUsed(message);
    checkValidatorSignatures(message, activeColdValidatorSet, signatures, coldValidatorSetHash);

    blockDurationMillis = newBlockDurationMillis;
    emit ChangedBlockDurationMillis(newBlockDurationMillis);
  }

  function changeLockerThreshold(
    uint64 newLockerThreshold,
    uint64 nonce,
    ValidatorSet memory activeColdValidatorSet,
    Signature[] memory signatures
  ) external {
    bytes32 data = keccak256(abi.encode("changeLockerThreshold", newLockerThreshold, nonce));
    bytes32 message = makeMessage(data);

    checkMessageNotUsed(message);
    checkValidatorSignatures(message, activeColdValidatorSet, signatures, coldValidatorSetHash);

    lockerThreshold = newLockerThreshold;
    if (uint64(lockersVotingLock.length) >= lockerThreshold && !paused()) {
      _pause();
    }
    emit ChangedLockerThreshold(newLockerThreshold);
  }

  function voteEmergencyLock() external {
    require(lockers[msg.sender], "Sender is not authorized to lock smart contract");
    bool currentVote = lockerVotes[msg.sender];
    require(!currentVote, "Locker already voted for emergency lock");
    lockerVotes[msg.sender] = true;
    lockersVotingLock.push(msg.sender);
    if (uint64(lockersVotingLock.length) >= lockerThreshold && !paused()) {
      _pause();
    }
  }

  function unvoteEmergencyLock() external whenNotPaused {
    require(lockers[msg.sender], "Sender is not authorized to lock smart contract");
    bool currentVote = lockerVotes[msg.sender];
    require(currentVote, "Locker is not currently voting for emergency lock");
    removeLockerVote(msg.sender);
  }

  function removeLockerVote(address locker) private whenNotPaused {
    require(lockers[locker], "Sender is not authorized to lock smart contract");
    lockerVotes[locker] = false;
    uint64 length = uint64(lockersVotingLock.length);
    for (uint64 i = 0; i < length; i++) {
      if (lockersVotingLock[i] == msg.sender) {
        lockersVotingLock[i] = lockersVotingLock[length - 1];
        lockersVotingLock.pop();
        break;
      }
    }
  }

  function emergencyUnlock(
    ValidatorSetUpdateRequest memory newValidatorSet,
    ValidatorSet calldata activeColdValidatorSet,
    Signature[] calldata signatures,
    uint64 nonce
  ) external whenPaused {
    bytes32 data = keccak256(
      abi.encode(
        "unlock",
        newValidatorSet.epoch,
        newValidatorSet.hotAddresses,
        newValidatorSet.coldAddresses,
        newValidatorSet.powers,
        nonce
      )
    );
    bytes32 message = makeMessage(data);

    checkMessageNotUsed(message);
    updateValidatorSetInner(newValidatorSet, activeColdValidatorSet, signatures, message, true);
    finalizeValidatorSetUpdateInner();
    uint64 length = uint64(lockersVotingLock.length);
    for (uint64 i = 0; i < length; i++) {
      lockerVotes[lockersVotingLock[i]] = false;
    }
    delete lockersVotingLock;
    _unpause();
  }

  function depositWithPermit(
    address user,
    uint64 amount,
    uint64 deadline,
    Signature memory signature
  ) private {
    uint256 userBalance = usdcToken.balanceOf(user);
    if (userBalance < uint256(amount)) {
      emit DepositWithPermitInsufficientAmount(user, amount);
      return;
    }

    address spender = address(this);
    usdcToken.permit(
      user,
      spender,
      amount,
      deadline,
      signature.v,
      bytes32(signature.r),
      bytes32(signature.s)
    );
    usdcToken.safeTransferFrom(user, spender, amount);
  }

  function batchedDepositWithPermit(
    DepositWithPermit[] memory deposits
  ) external nonReentrant whenNotPaused {
    uint64 end = uint64(deposits.length);
    for (uint64 idx; idx < end; idx++) {
      depositWithPermit(
        deposits[idx].user,
        deposits[idx].amount,
        deposits[idx].deadline,
        deposits[idx].signature
      );
    }
  }
}