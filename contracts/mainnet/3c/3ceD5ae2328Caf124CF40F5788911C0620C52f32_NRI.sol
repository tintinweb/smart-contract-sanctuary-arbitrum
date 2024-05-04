// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { UserData } from "../lib/GenStructs.sol";
interface INUI {
    function closePosition(bytes32 _identifier, address _user) external;
    function totalDCAs() external view returns (uint40);
    function userData(uint40 _id) external view returns (UserData memory);
    function updatePositionPerExecution(uint40 _timeToDelete, uint40 _timeToUpdate) external;
    function positionPerExecution(uint40) external view returns (uint40);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;

    function getHour(uint256 _timestamp) private pure returns (uint256) {
        uint256 secs = _timestamp % SECONDS_PER_DAY;
        return secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 _timestamp) private pure returns (uint256) {
        uint256 secs = _timestamp % SECONDS_PER_HOUR;
        return secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 _timestamp) private pure returns (uint256) {
        return _timestamp % SECONDS_PER_MINUTE;
    }

    function subHours(uint256 _timestamp, uint256 _hours) private pure returns (uint256) {
        return _timestamp - _hours * SECONDS_PER_HOUR;
    }

    function subMinutes(uint256 _timestamp, uint256 _minutes) private pure returns (uint256) {
        return _timestamp - _minutes * SECONDS_PER_MINUTE;
    }

    function subSeconds(uint256 _timestamp, uint256 _seconds) private pure returns (uint256) {
        return _timestamp - _seconds;
    }
    /**
     * @notice  Generate midnight timestamp (Sunday MM DD, YYYY 00:00:00).
     * @param   _timestamp  block timestamp.
     * @return  uint256  midnight timestamp.
     */
    function getMidnightTimestamp(uint256 _timestamp) internal pure returns (uint256) {
        uint256 midnightTimestap = subHours(_timestamp, getHour(_timestamp));
        midnightTimestap = subMinutes(midnightTimestap, getMinute(_timestamp));
        return subSeconds(midnightTimestap, getSecond(_timestamp));

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../extensions/IERC20Metadata.sol";
import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct UserData {
    bool toBeClosed;
    bytes32 identifier;
    address owner;
    address receiver;
    address srcToken;
    address dstToken;
    uint8 tau;
    uint40 exeRequired; //0 = Unlimited
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}
struct UserDetail {
    address receiver;
    uint8 tau;
    uint40 nextExecution;
    uint40 lastExecution;
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}
struct UserDca {
    bool toBeClosed;
    bytes32 identifier;
    address srcToken;
    address dstToken;
    uint16 code;
    uint40 dateCreation; //sec
    uint40 exeRequired;
    uint40 exePerformed;
}
struct ExeData {
    uint8 errCount;
    uint16 code;
    uint40 dateCreation; //sec
    uint40 nextExecution; //sec
    uint40 lastExecution; //sec
    uint40 exePerformed;
    uint256 fundTransferred;
}
struct ResolverData {
    bool toBeClosed;
    bool allowOk;
    bool balanceOk;
    address owner;
    address receiver;
    address srcToken;
    address dstToken;
    uint8 srcDecimals;
    uint8 dstDecimals;
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}
struct StoredData {
    uint256 timestamp;
    uint256 tokenValue; //USD (precision 6 dec)
    uint256 tokenAmount;
}
struct QueueData {
    bytes32 identifier;
    address owner;
    address receiver;
    address srcToken;
    address dstToken;
    uint8 tau;
    uint40 exeRequired; //0 = Unlimited
    uint40 dateCreation; //sec **
    uint40 nextExecution; //sec **
    uint256 srcAmount;
    uint256 limitOrderBuy; //USD (precision 6 dec)
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { UserData, ExeData, ResolverData } from "./lib/GenStructs.sol";
import { ERC20 } from "./lib/ERC20.sol";
import { SafeERC20 } from "./utils/SafeERC20.sol";
import { INUI } from "./interfaces/INUI.sol";
import { DateTime } from "./lib/DateTime.sol";

error NotAuthorized();
error ExecutionNotRequired();
error EmergencyPause();

/**
 * @author  Nebula Labs for Neon Protocol.
 * @title   Resolver interface for automatic execution.
 */
contract NRI {
    using SafeERC20 for ERC20;

    ExeData[] private dcaExeData;
    mapping (bytes32 => uint40) private dcaPosition;
    mapping (uint40 => uint40) private positionToChange;
    mapping (uint40 => bool) private changeRequired;
    bool public resolverRunning;
    bool public operative;
    uint40 public maxDcaExecutable;

    uint24 constant private TIME_BASE = 1 days;
    uint8 constant private ERROR_LIMIT = 2;
    address immutable public NUI;
    address immutable public RESOLVER;
    address immutable public ADMIN;

    event PositionCompleted(address owner, bytes32 identifier);
    event PositionClosedByError(address owner, bytes32 identifier);
    event PositionClosedByQueue(address owner, bytes32 identifier);

    modifier onlyResolver(){
        if(msg.sender != RESOLVER) revert NotAuthorized();
        _;
    }
    modifier onlyNUI(){
        require(msg.sender == NUI, "Not Authorized");
        _;
    }
    modifier onlyAdmin(){
        require(msg.sender == ADMIN, "Not Authorized");
        _;
    }
    modifier protocolOperative(){
        if(!operative) revert EmergencyPause();
        _;
    }

    constructor(address _NUI, address _resolver){
        NUI = _NUI;
        RESOLVER = _resolver;
        ADMIN = msg.sender;
        operative = true;
        maxDcaExecutable = type(uint40).max;
    }

    /* WRITE METHODS*/
    /**
     * @notice  Pause execution for safety, user can still create or delete DCAs.
     * @dev     Only Admin.
     */
    function emergencyPause() external onlyAdmin {
        operative = !operative;
    }
    /**
     * @notice  Initialize number of executable DCAs.
     * @dev     Only Admin.
     */
    function initMaxDcaExecutable() external onlyAdmin {
        maxDcaExecutable = type(uint40).max;
    }
    /**
     * @notice  Update next execution date with "skipExecution".
     * @dev     Only NUI.
     * @param   _identifier  position identifier.
     * @param   _tau  frequency of execution.
     */
    function updateExecutionDate(bytes32 _identifier, uint8 _tau) external onlyNUI {
        uint40 position = dcaPosition[_identifier];
        dcaExeData[position].nextExecution += (_tau * TIME_BASE);
    }
    /**
     * @notice  Create execution position with "createDCA" & "manageQueue".
     * @dev     Only NUI.
     * @param   _identifier  position identifier.
     * @param   _nextExecution  next execution time.
     */
    function createPosition(bytes32 _identifier, uint40 _nextExecution) external onlyNUI {
        dcaPosition[_identifier] = INUI(NUI).totalDCAs();
        _setExeData(0, 0, uint40(block.timestamp), _nextExecution, 0, 0, 0);
    }
    /**
     * @notice  Close execution position with "_closeDca".
     * @dev     Only NUI.
     * @param   _identifier  position identifier.
     * @param   _identifierLast  last position identifier.
     */
    function closePosition(bytes32 _identifier, bytes32 _identifierLast) external onlyNUI {
        if(_identifier != _identifierLast){
            dcaExeData[dcaPosition[_identifier]] = dcaExeData[dcaPosition[_identifierLast]];
            dcaPosition[_identifierLast] = dcaPosition[_identifier];
        }
        dcaPosition[_identifier] = 0;
        dcaExeData.pop();
    }
    /**
     * @notice  Prepares the static database for execution.
     * @dev     Only Resover & No Pause.
     */
    function snapsExecution() external onlyResolver protocolOperative {
        resolverRunning = true;
    }
    /**
     * @notice  Start execution, sending the funds to the resolver.
     * @dev     Only Resover & No Pause.
     * @param   _id  array position.
     */
    function executionStart(uint40[] memory _id) external onlyResolver protocolOperative {
        UserData memory userInfo;
        uint40 length = uint40(_id.length);
        uint256 initBalance;
        if(!resolverRunning) resolverRunning = true;
        for(uint40 i; i < length; ++i){
            if(block.timestamp < dcaExeData[_id[i]].nextExecution) revert ExecutionNotRequired();
            if(changeRequired[_id[i]]) changeRequired[_id[i]] = false;
            if(dcaExeData[_id[i]].fundTransferred == 0){
                userInfo = INUI(NUI).userData(_id[i]); 
                if(!userInfo.toBeClosed){
                    //Manage feeOnTrasfer token            
                    initBalance = ERC20(userInfo.srcToken).balanceOf(RESOLVER);
                    ERC20(userInfo.srcToken).safeTransferFrom(userInfo.owner, RESOLVER, userInfo.srcAmount);
                    dcaExeData[_id[i]].fundTransferred = ERC20(userInfo.srcToken).balanceOf(RESOLVER) - initBalance;
                }
            }
        }
    }
    /**
     * @notice  Data update after swap execution.
     * @dev     Only Resover & No Pause.
     * @param   _id  array position.
     * @param   _code  result of execution.
     */
    function updatePositions(uint40[] memory _id, uint16[] memory _code) external onlyResolver protocolOperative {
        UserData memory userInfo;
        uint40 length = uint40(_id.length);
        for(uint40 i; i < length; ++i){
            if(block.timestamp < dcaExeData[_id[i]].nextExecution) revert ExecutionNotRequired();
            userInfo = INUI(NUI).userData(_id[i]); 
            dcaExeData[_id[i]].lastExecution = dcaExeData[_id[i]].nextExecution;
            dcaExeData[_id[i]].nextExecution = _generateNextExecution(dcaExeData[_id[i]].nextExecution, userInfo.tau);
            dcaExeData[_id[i]].code = _code[i];
            if(_code[i] == 200){
                dcaExeData[_id[i]].errCount = 0;
                unchecked {
                    ++dcaExeData[_id[i]].exePerformed;
                }
            }else{
                unchecked {
                    ++dcaExeData[_id[i]].errCount;
                }
                if(_code[i] != 999 && dcaExeData[_id[i]].fundTransferred != 0){
                    ERC20(userInfo.srcToken).safeTransferFrom(RESOLVER, userInfo.owner, dcaExeData[_id[i]].fundTransferred);
                }
            }
            dcaExeData[_id[i]].fundTransferred = 0;
            INUI(NUI).updatePositionPerExecution(dcaExeData[_id[i]].lastExecution, dcaExeData[_id[i]].nextExecution);
        }
    }
    /**
     * @notice  Closes the positions to be closed and adjusts the location.
     * @dev     Only Resover & No Pause.
     * @param   _id  array position.
     * @param   _maxDca  number of maximum DCAs that can be executed at the next execution.
     */
    function executionCompletion(uint40[] memory _id, uint40 _maxDca) external onlyResolver protocolOperative {
        UserData memory userInfo;
        bool close;
        uint40 length = uint40(_id.length);
        uint40 id;
        if(_maxDca != 0) maxDcaExecutable = _maxDca;
        for(uint40 i; i < length; ++i){
            id = _adjustPositionAfterDelete(changeRequired[_id[i]], _id[i], positionToChange[_id[i]]);
            userInfo = INUI(NUI).userData(id);
            if(dcaExeData[id].errCount >= ERROR_LIMIT){
                close = true;
                emit PositionClosedByError(userInfo.owner, userInfo.identifier);
            }else if(userInfo.exeRequired > 0 && dcaExeData[id].exePerformed >= userInfo.exeRequired){
                close = true;
                emit PositionCompleted(userInfo.owner, userInfo.identifier);
            }else if(userInfo.toBeClosed){
                close = true;
                emit PositionClosedByQueue(userInfo.owner, userInfo.identifier);
            }
            if(close){
                close = false;
                INUI(NUI).updatePositionPerExecution(dcaExeData[id].nextExecution, 0);
                INUI(NUI).closePosition(userInfo.identifier, userInfo.owner);
                positionToChange[INUI(NUI).totalDCAs()] = id;
                changeRequired[INUI(NUI).totalDCAs()] = true;
            }
        }
        if(resolverRunning) resolverRunning = false;
    }
    /* VIEW METHODS*/
    function positionDetail(bytes32 _identifier) external view onlyNUI returns (ExeData memory){
        return dcaExeData[dcaPosition[_identifier]];
    }
    /**
     * @notice  Retrieve number of executable positions.
     * @return  uint40  number of DCAs that must be executed.
     */
    function amountExecutablePositions() external view onlyResolver returns (uint40){
        uint40 totalpositions = INUI(NUI).totalDCAs();
        uint40 executablePositions;
        for(uint40 i; i < totalpositions; ++i){
            if(block.timestamp >= dcaExeData[i].nextExecution){
                unchecked {
                    ++executablePositions;
                }
            }
        }
        return executablePositions;
    }
    /**
     * @notice  Retrieve position of executable DCAs.
     * @param   _amountExecutablePositions  total executable DCAs.
     * @return  uint40[]  position of DCAs that must be executed.
     */
    function executableIds(uint40 _amountExecutablePositions) external view onlyResolver returns (uint40[] memory){
        uint40 totalpositions = INUI(NUI).totalDCAs();
        uint40[] memory ids = new uint40[](_amountExecutablePositions);
        uint40 idx;
        for(uint40 i; i < totalpositions; ++i){
            if(block.timestamp >= dcaExeData[i].nextExecution){
                ids[idx] = i;
                unchecked {
                    ++idx;
                }
            }
        }
        return ids;
    }
    /**
     * @notice  Execution data for the resolver.
     * @param   _id  Array of DCAs ids (position).
     * @return  ResolverData[]  resolver data.
     */
    function executionsDetail(uint40[] memory _id) external view onlyResolver returns (ResolverData[] memory){
        uint40 length = uint40(_id.length);
        UserData memory userInfo;
        ResolverData[] memory resultData = new ResolverData[](length);
        for(uint40 i; i < length; ++i){
            userInfo = INUI(NUI).userData(_id[i]);
            resultData[i] = ResolverData(
                userInfo.toBeClosed,
                ERC20(userInfo.srcToken).allowance(userInfo.owner, address(this)) >= userInfo.srcAmount,
                ERC20(userInfo.srcToken).balanceOf(userInfo.owner) >= userInfo.srcAmount,
                userInfo.owner,
                userInfo.receiver,
                userInfo.srcToken,
                userInfo.dstToken,
                ERC20(userInfo.srcToken).decimals(),
                ERC20(userInfo.dstToken).decimals(),
                userInfo.srcAmount,
                userInfo.limitOrderBuy
            );
        }
        return resultData;
    }
    /**
     * @notice  Amount trasferred to the resolver in the currect execution.
     * @param   _id  DCA position.
     * @return  uint256  trasferred amount.
     */
    function amountTransfered(uint40 _id) external view onlyResolver returns (uint256){
        return dcaExeData[_id].fundTransferred;
    }
    /* PRIVATE METHODS*/
    function _setExeData(
        uint8 _errCount,
        uint16 _code,
        uint40 _dateCreation,
        uint40 _nextExecution,
        uint40 _lastExecution,
        uint40 _exePerformed,
        uint256 _fundTransferred
    ) private {
        dcaExeData.push(ExeData(
            _errCount,
            _code,
            _dateCreation,
            _nextExecution,
            _lastExecution,
            _exePerformed,
            _fundTransferred
        ));
    }
    /**
     * @dev     Manage deviation if _baseExecution is 1 day late on execution, time will be adjusted current + frequency.
     *          And check execution capacity.
     */
    function _generateNextExecution(uint40 _baseExecution, uint8 _tau) private view returns (uint40){
        uint40 timestamp = uint40(DateTime.getMidnightTimestamp(block.timestamp));
        uint40 nextExecution = (timestamp - _baseExecution) >= TIME_BASE ? timestamp : _baseExecution;
        nextExecution += (_tau * TIME_BASE);
        if(INUI(NUI).positionPerExecution(nextExecution) + 1 > maxDcaExecutable){// +1 day
            nextExecution += TIME_BASE;
            if(INUI(NUI).positionPerExecution(nextExecution) + 1 > maxDcaExecutable){// +2 days
                nextExecution += TIME_BASE;
                if(INUI(NUI).positionPerExecution(nextExecution) + 1 > maxDcaExecutable){// 1 week
                    nextExecution += (5 * TIME_BASE);
                    if(INUI(NUI).positionPerExecution(nextExecution) + 1 > maxDcaExecutable){// +2 weeks
                        nextExecution += (7 * TIME_BASE);
                        if(INUI(NUI).positionPerExecution(nextExecution) + 1 > maxDcaExecutable){// +1 month
                            nextExecution += (14 * TIME_BASE);
                        }
                    }
                }
            }
        }
        return nextExecution;
    }
    function _adjustPositionAfterDelete(bool _isRequired, uint40 currentPosition, uint40 newPosition) private pure returns (uint40){
        return _isRequired ? newPosition : currentPosition;
    }

}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "./Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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