// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "../IRegCenter.sol";

interface IOwnable {

    struct Admin{
        address addr;
        uint8 state;
    }

    event SetNewOwner(address indexed owner);

    // #################
    // ##    Write    ##
    // #################

    function init(address owner, address regCenter) external;

    function setNewOwner(address acct) external;

    // ##############
    // ##   Read   ##
    // ##############

    function getOwner() external view returns (address);

    function getRegCenter() external view returns (address);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
    event Transfer(address indexed from, address indexed to, uint256 indexed value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./access/IOwnable.sol";

import "../lib/UsersRepo.sol";
import "../lib/DocsRepo.sol";

import "./ERC20/IERC20.sol";
import "./Oracles/IPriceConsumer2.sol";

interface IRegCenter is IERC20, IPriceConsumer2{

    enum TypeOfDoc{
        ZeroPoint,
        ROCKeeper,      // 1
        RODKeeper,      // 2
        BMMKeeper,      // 3
        ROMKeeper,      // 4
        GMMKeeper,      // 5
        ROAKeeper,      // 6
        ROOKeeper,      // 7
        ROPKeeper,      // 8
        SHAKeeper,      // 9
        LOOKeeper,      // 10
        ROC,            // 11
        ROD,            // 12
        MeetingMinutes, // 13
        ROM,            // 14
        ROA,            // 15
        ROO,            // 16
        ROP,            // 17
        ROS,            // 18
        LOO,            // 19
        GeneralKeeper,  // 20
        IA,             // 21
        SHA,            // 22 
        AntiDilution,   // 23
        LockUp,         // 24
        Alongs,         // 25
        Options         // 26
    }

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetPlatformRule(bytes32 indexed snOfRule);

    event SetPriceFeed(uint indexed seq, address indexed priceFeed);

    event TransferOwnership(address indexed newOwner);

    event TurnOverCenterKey(address indexed newKeeper);

    // ==== Points ====

    event MintPoints(uint256 indexed to, uint256 indexed amt);

    event TransferPoints(uint256 indexed from, uint256 indexed to, uint256 indexed amt);

    event LockPoints(bytes32 indexed headSn, bytes32 indexed hashLock);

    event LockConsideration(bytes32 indexed headSn, address indexed counterLocker, bytes payload, bytes32 indexed hashLock);

    event PickupPoints(bytes32 indexed headSn);

    event PickupConsideration(bytes32 indexed headSn);

    event WithdrawPoints(bytes32 indexed headSn);

    // ==== Docs ====
    
    event SetTemplate(uint256 indexed typeOfDoc, uint256 indexed version, address indexed body);

    event TransferIPR(uint indexed typeOfDoc, uint indexed version, uint indexed transferee);

    event CreateDoc(bytes32 indexed snOfDoc, address indexed body);

    // ##################
    // ##    Write     ##
    // ##################

    // ==== Opts Setting ====

    function setPlatformRule(bytes32 snOfRule) external;
    
    function setPriceFeed(uint seq, address feed_ ) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function handoverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mint(uint256 to, uint amt) external;

    function burn(uint amt) external;

    function mintAndLockPoints(uint to, uint amt, uint expireDate, bytes32 hashLock) external;

    // ==== Points Trade ====

    function lockPoints(uint to, uint amt, uint expireDate, bytes32 hashLock) external;

    function lockConsideration(uint to, uint amt, uint expireDate, address counterLocker, bytes memory payload, bytes32 hashLock) external;

    function pickupPoints(bytes32 hashLock, string memory hashKey) external;

    function withdrawPoints(bytes32 hashLock) external;

    function getDepositAmt(address from) external view returns(uint);

    function getLocker(bytes32 hashLock) external view 
        returns (LockersRepo.Locker memory locker);

    function getLocksList() external view 
        returns (bytes32[] memory);

    // ==== User ====

    function regUser() external;

    function setBackupKey(address bKey) external;

    function upgradeBackupToPrime() external;

    function setRoyaltyRule(bytes32 snOfRoyalty) external;

    // ==== Doc ====

    function setTemplate(uint typeOfDoc, address body, uint author) external;

    function createDoc(bytes32 snOfDoc, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc memory doc);

    // ==== Comp ====

    // function createComp(address dk) external;

    // #################
    // ##   Read      ##
    // #################

    // ==== Options ====

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    function getPlatformRule() external returns(UsersRepo.Rule memory);

    // ==== Users ====

    function isKey(address key) external view returns (bool);

    function counterOfUsers() external view returns(uint40);

    function getUser() external view returns (UsersRepo.User memory);

    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory);

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40);

    function getMyUserNo() external returns (uint40);

    // ==== Docs ====

    function counterOfTypes() external view returns(uint32);

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32 seq);

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64 seq);

    function docExist(address body) external view returns(bool);

    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40);

    function getAuthorByBody(address body) external view returns(uint40);

    function getHeadByBody(address body) external view returns (DocsRepo.Head memory );
    
    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc);

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc);

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag);

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory);

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IPriceConsumer2 {

    /**
     * Network: Arbitrum One
     * ETH/USD (Base_0): 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
     * GBP/USD (quote_1): 0x9C4424Fd84C6661F97D8d6b3fc3C1aAc2BeDd137
     * EUR/USD (quote_2): 0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84
     * JPY/USD (quote_3): 0x3dD6e51CB9caE717d5a8778CF79A04029f9cFDF8
     * KRW/USD (quote_4): 0x85bb02E0Ae286600d1c68Bb6Ce22Cc998d411916
     * CNY/USD (quote_5): 0xcC3370Bde6AFE51e1205a5038947b9836371eCCb
     * AUD/USD (quote_6): 0x9854e9a850e7C354c1de177eA953a6b1fba8Fc22
     * CAD/USD (quote_7): 0xf6DA27749484843c4F02f5Ad1378ceE723dD61d4
     * CHF/USD (quote_8): 0xe32AccC8c4eC03F6E75bd3621BfC9Fbb234E1FC3
     * ARS/USD (quote_9): 0x0000000000000000000000000000000000000000
     * PHP/USD (quote_10): 0xfF82AAF635645fD0bcc7b619C3F28004cDb58574
     * NZD/USD (quote_11): 0x0000000000000000000000000000000000000000
     * SGD/USD (quote_12): 0xF0d38324d1F86a176aC727A4b0c43c9F9d9c5EB1
     * NGN/USD (quote_13): 0x0000000000000000000000000000000000000000
     * ZAR/USD (quote_14): 0x0000000000000000000000000000000000000000
     * RUB/USD (quote_15): 0x0000000000000000000000000000000000000000
     * INR/USD (quote_16): 0x0000000000000000000000000000000000000000
     * BRL/USD (quote_17): 0x04b7384473A2aDF1903E3a98aCAc5D62ba8C2702
     */

    function getPriceFeed(uint seq) external view returns (address);

    function decimals(address quote) external view returns (uint8);

    function getCentPriceInWei(uint seq) external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

import "./IPriceConsumer2.sol";

contract PriceConsumer2 is IPriceConsumer2{

    mapping(address => AggregatorV3Interface) private _priceFeeds;
    
    address[20] private _currencies = [
        Denominations.USD, Denominations.GBP, Denominations.EUR, Denominations.JPY, Denominations.KRW, Denominations.CNY,
        Denominations.AUD, Denominations.CAD, Denominations.CHF, Denominations.ARS, Denominations.PHP, Denominations.NZD,
        Denominations.SGD, Denominations.NGN, Denominations.ZAR, Denominations.RUB, Denominations.INR, Denominations.BRL,
        Denominations.ETH, Denominations.BTC
    ];

    /**
     * Network: Arbitrum One
     * ETH/USD (Base_0): 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
     * GBP/USD (quote_1): 0x9C4424Fd84C6661F97D8d6b3fc3C1aAc2BeDd137
     * EUR/USD (quote_2): 0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84
     * JPY/USD (quote_3): 0x3dD6e51CB9caE717d5a8778CF79A04029f9cFDF8
     * KRW/USD (quote_4): 0x85bb02E0Ae286600d1c68Bb6Ce22Cc998d411916
     * CNY/USD (quote_5): 0xcC3370Bde6AFE51e1205a5038947b9836371eCCb
     * AUD/USD (quote_6): 0x9854e9a850e7C354c1de177eA953a6b1fba8Fc22
     * CAD/USD (quote_7): 0xf6DA27749484843c4F02f5Ad1378ceE723dD61d4
     * CHF/USD (quote_8): 0xe32AccC8c4eC03F6E75bd3621BfC9Fbb234E1FC3
     * ARS/USD (quote_9): 0x0000000000000000000000000000000000000000
     * PHP/USD (quote_10): 0xfF82AAF635645fD0bcc7b619C3F28004cDb58574
     * NZD/USD (quote_11): 0x0000000000000000000000000000000000000000
     * SGD/USD (quote_12): 0xF0d38324d1F86a176aC727A4b0c43c9F9d9c5EB1
     * NGN/USD (quote_13): 0x0000000000000000000000000000000000000000
     * ZAR/USD (quote_14): 0x0000000000000000000000000000000000000000
     * RUB/USD (quote_15): 0x0000000000000000000000000000000000000000
     * INR/USD (quote_16): 0x0000000000000000000000000000000000000000
     * BRL/USD (quote_17): 0x04b7384473A2aDF1903E3a98aCAc5D62ba8C2702
     */

    constructor(){
        _priceFeeds[_currencies[0]] = AggregatorV3Interface(
            0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        );
        _priceFeeds[_currencies[1]] = AggregatorV3Interface(
            0x9C4424Fd84C6661F97D8d6b3fc3C1aAc2BeDd137
        );
        _priceFeeds[_currencies[2]] = AggregatorV3Interface(
            0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84
        );
        _priceFeeds[_currencies[3]] = AggregatorV3Interface(
            0x3dD6e51CB9caE717d5a8778CF79A04029f9cFDF8
        );
        _priceFeeds[_currencies[4]] = AggregatorV3Interface(
            0x85bb02E0Ae286600d1c68Bb6Ce22Cc998d411916
        );
        _priceFeeds[_currencies[5]] = AggregatorV3Interface(
            0xcC3370Bde6AFE51e1205a5038947b9836371eCCb
        );
        _priceFeeds[_currencies[6]] = AggregatorV3Interface(
            0x9854e9a850e7C354c1de177eA953a6b1fba8Fc22
        );
        _priceFeeds[_currencies[7]] = AggregatorV3Interface(
            0xf6DA27749484843c4F02f5Ad1378ceE723dD61d4
        );
        _priceFeeds[_currencies[8]] = AggregatorV3Interface(
            0xe32AccC8c4eC03F6E75bd3621BfC9Fbb234E1FC3
        );
        _priceFeeds[_currencies[10]] = AggregatorV3Interface(
            0xfF82AAF635645fD0bcc7b619C3F28004cDb58574
        );
        _priceFeeds[_currencies[12]] = AggregatorV3Interface(
            0xF0d38324d1F86a176aC727A4b0c43c9F9d9c5EB1
        );
        _priceFeeds[_currencies[17]] = AggregatorV3Interface(
            0x04b7384473A2aDF1903E3a98aCAc5D62ba8C2702
        );
    }

    function _setPriceFeed(uint seq, address _feed) internal {
        _priceFeeds[_currencies[seq]] = AggregatorV3Interface(_feed);
    }

    function getPriceFeed(uint seq) external view returns (address) {
        return address(_priceFeeds[_currencies[seq]]);
    }

    function decimals(address quote) public view returns (uint8) {
        return _priceFeeds[quote].decimals();
    }

    function getCentPriceInWei(uint seq) public view returns (uint) {

        (int base, uint8 dec) = _getLatestPrice(0);

        if (seq == 0) {
            
            return 10 ** uint(16 + dec) / uint(base);

        } else if (seq <= 17){

            (int quote, uint8 quoteDec) = _getLatestPrice(seq);
            quote = _scalePrice(quote, quoteDec, dec);

            return 10 ** uint(16 + dec) * uint(quote) / uint(base);

        } else revert("seqOfCurrency overflow");
    }

    function _getLatestPrice(uint seq) private view 
        returns(int price, uint8 dec) 
    {
        require(address(_priceFeeds[_currencies[seq]]) > address(0),
            "No Available PriceFeed");

        (
            /*uint80 roundID*/,
            price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = _priceFeeds[_currencies[seq]].latestRoundData();

        dec = _priceFeeds[_currencies[seq]].decimals();        
    }

    function _scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) private pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint(_priceDecimals - _decimals));
        }
        return _price;
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";
import "./ERC20/ERC20.sol";
import "./Oracles/PriceConsumer2.sol";

contract RegCenter is IRegCenter, ERC20("ComBooxPoints", "CBP"), PriceConsumer2 {
    using DocsRepo for DocsRepo.Repo;
    using DocsRepo for DocsRepo.Head;
    using UsersRepo for UsersRepo.Repo;
    using UsersRepo for uint256;
    
    UsersRepo.Repo private _users;
    DocsRepo.Repo private _docs;
    mapping(address => uint256) private _coffers;
    
    constructor(address keeper) {
        _users.users[0].primeKey.pubKey = msg.sender;
        _users.users[0].backupKey.pubKey = keeper;
        // _users.regUser(msg.sender);
        // _users.regUser(keeper);
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function setPlatformRule(bytes32 snOfRule) external {
        _users.setPlatformRule(snOfRule, msg.sender);
        emit SetPlatformRule(snOfRule);
    }

    function setPriceFeed(uint seq, address feed_ ) external {
        require(msg.sender == _users.getBookeeper(), "RC: not bookeeper");
        _setPriceFeed(seq, feed_);
        emit SetPriceFeed(seq, feed_);
    }

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external {
        _users.transferOwnership(newOwner, msg.sender);
        emit TransferOwnership(newOwner);
    }

    function handoverCenterKey(address newKeeper) external {
        _users.handoverCenterKey(newKeeper, msg.sender);
        emit TurnOverCenterKey(newKeeper);
    }

    // ##################
    // ##  Mint & Lock ##
    // ##################

    function mint(uint256 to, uint amt) external {

        require(msg.sender == _users.getOwner(), 
            "RC.mintPoints: not owner");

        require(to > 0, "RC.mintPoints: zero to");
        
        _mint(_users.users[to].primeKey.pubKey, amt);
    }

    function burn(uint amt) external {
        require(msg.sender == _users.getOwner(), 
            "RC.burnPoints: not owner");

        _burn(msg.sender, amt);
    }

    function mintAndLockPoints(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        bytes32 hashLock
    ) external {   
        LockersRepo.Head memory head = 
            _users.mintAndLockPoints(
                to, 
                amtOfGLee, 
                expireDate, 
                hashLock, 
                msg.sender
            );

        _mint(address(this), amtOfGLee * 10 ** 9);
        _coffers[msg.sender] += amtOfGLee * 10 ** 9;

        emit LockPoints( LockersRepo.codifyHead(head), hashLock);
    }

    function lockPoints(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        bytes32 hashLock
    ) external {

        LockersRepo.Head memory head = 
            _users.lockPoints(
                to, 
                amtOfGLee, 
                expireDate, 
                hashLock, 
                msg.sender
            );
        _lockPointsInCoffer(msg.sender, amtOfGLee * 10 ** 9);
        emit LockPoints(LockersRepo.codifyHead(head), hashLock);
    }

    function _lockPointsInCoffer(address caller, uint value) private {
        _transfer(caller, address(this), value);
        _coffers[caller] += value;
    }

    function lockConsideration(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        address counterLocker, 
        bytes calldata payload, 
        bytes32 hashLock
    ) external {

        LockersRepo.Head memory head =
            _users.lockConsideration(
                to, 
                amtOfGLee, 
                expireDate, 
                counterLocker, 
                payload, 
                hashLock, 
                msg.sender
            );
            
        _lockPointsInCoffer(msg.sender, amtOfGLee * 10 ** 9);
        emit LockConsideration(LockersRepo.codifyHead(head), counterLocker, payload, hashLock);
    }

    function pickupPoints(bytes32 hashLock, string memory hashKey) external
    {
        LockersRepo.Head memory head = 
            _users.pickupPoints(hashLock, hashKey, msg.sender);

        if (head.value > 0) {
            emit PickupPoints(LockersRepo.codifyHead(head));

            _pickupPointsFromCoffer(
                _users.users[head.from].primeKey.pubKey, 
                _users.users[head.to].primeKey.pubKey, 
                head.value * 10 ** 9
            );
        }
    }

    function _pickupPointsFromCoffer(address from, address to, uint amt) private {
        require(_coffers[from] >= amt, 
            "RC.pickupPointsFromCoffer: insufficient balance");
        _coffers[from] -= amt;
        _transfer(address(this), to, amt);
    }

    function withdrawPoints(bytes32 hashLock) external
    {
        LockersRepo.Head memory head = 
            _users.withdrawDeposit(hashLock, msg.sender);

        if (head.value > 0) {
            _withdrawPoints(
                _users.users[head.from].primeKey.pubKey, 
                head.value * 10 ** 9
            );
            emit WithdrawPoints(LockersRepo.codifyHead(head));
        }
    }

    function _withdrawPoints(address from, uint amt) private {
        require(_coffers[from] >= amt, 
            "RC.withdrawPoints: insufficient balance");
        _coffers[from] -= amt;
        _transfer(address(this), from, amt);
    }

    function getDepositAmt(address from) external view returns(uint) {
        return _coffers[from];
    }

    function getLocker(bytes32 hashLock) external
        view returns (LockersRepo.Locker memory locker)
    {
        locker = _users.getLocker(hashLock);
    }

    function getLocksList() external 
        view returns (bytes32[] memory)
    {
        return _users.getLocksList();
    }

    // ################
    // ##    Users   ##
    // ################

    function regUser() external {
        UsersRepo.User memory user = _users.regUser(msg.sender);
        if (user.primeKey.gift > 0) {
            _mint(user.primeKey.pubKey, uint(user.primeKey.gift) * 10 ** 9);
        }
    }

    function setBackupKey(address bKey) external {
        _users.setBackupKey(bKey, msg.sender);
    }

    function upgradeBackupToPrime() external {
        _users.upgradeBackupToPrime(msg.sender);
    }

    function setRoyaltyRule(bytes32 snOfRoyalty) external {
        _users.setRoyaltyRule(snOfRoyalty, msg.sender);
    }

    // ###############
    // ##    Docs   ##
    // ###############

    function setTemplate(uint typeOfDoc, address body, uint author) external {
        require(msg.sender == getBookeeper(), 
            "RC.setTemplate: not bookeeper");
        
        DocsRepo.Head memory head = 
            _docs.setTemplate(typeOfDoc, body, author, _users.getUserNo(msg.sender));

        emit SetTemplate(head.typeOfDoc, head.version, body);
    }

    function transferIPR(uint typeOfDoc, uint version, uint transferee) external {
        _docs.transferIPR(typeOfDoc, version, transferee, _users.getUserNo(msg.sender));

        emit TransferIPR(typeOfDoc, version, transferee);
    }

    function createDoc(
        bytes32 snOfDoc,
        address primeKeyOfOwner
    ) public returns(DocsRepo.Doc memory doc)
    {
        doc = _docs.createDoc(snOfDoc, msg.sender);
        IOwnable(doc.body).init(primeKeyOfOwner, address(this));
        
        emit CreateDoc(doc.head.codifyHead(), doc.body);
    }

    // ==== Platform ====

    function getOwner() public view returns (address) {
        return _users.getOwner();
    }

    function getBookeeper() public view returns (address) {
        return _users.getBookeeper();
    }

    function getPlatformRule() external view returns(UsersRepo.Rule memory) {
        return _users.getPlatformRule();
    }

    // ==== Users ====

    function isKey(address key) external view returns (bool) {
        return _users.isKey(key);
    }

    function counterOfUsers() external view returns(uint40) {
        return _users.counterOfUsers();
    }

    function getUser() external view returns (UsersRepo.User memory)
    {
        return _users.getUser(msg.sender);
    }

    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory) {
        return _users.getRoyaltyRule(author);
    }

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40) {

        uint40 target = _users.getUserNo(targetAddr);

        if (msg.sender != targetAddr && author > 0) {

            require(_docs.docExist(msg.sender), 
                "RC.getUserNo: msgSender not registered ");
            
            UsersRepo.Key memory rr = _users.getRoyaltyRule(author);
            address authorAddr = _users.users[author].primeKey.pubKey; 

            _chargeFee(targetAddr, fee, authorAddr, rr);

        }

        return target;
    }

    function _chargeFee(
        address targetAddr, 
        uint fee, 
        address authorAddr,
        UsersRepo.Key memory rr    
    ) private {

        UsersRepo.User storage t = _users.users[_users.getUserNo(targetAddr)];
        address ownerAddr = _users.getOwner();

        UsersRepo.Rule memory pr = _users.getPlatformRule();
        
        uint floorPrice = uint(pr.floor) * 10 ** 9;

        require(fee >= floorPrice, "RC.chargeFee: lower than floor");

        uint offAmt = uint(t.primeKey.coupon) * uint(rr.discount) * fee / 10000 + uint(rr.coupon) * 10 ** 9;
        
        fee = (offAmt < (fee - floorPrice))
            ? (fee - offAmt)
            : floorPrice;

        uint giftAmt = uint(rr.gift) * 10 ** 9;

        if (ownerAddr == authorAddr || pr.rate == 2000) {
            if (fee > giftAmt)
                _transfer(t.primeKey.pubKey, authorAddr, fee - giftAmt);
        } else {
            _transfer(t.primeKey.pubKey, ownerAddr, fee * (2000 - pr.rate) / 10000);
            
            uint balaceAmt = fee * (8000 + pr.rate) / 10000;
            if ( balaceAmt > giftAmt)
                _transfer(t.primeKey.pubKey, authorAddr, balaceAmt - giftAmt);
        }

        t.primeKey.coupon++;
    }

    function getMyUserNo() external view returns(uint40) {
        return _users.getUserNo(msg.sender);
    }

    // ==== Docs ====

    function counterOfTypes() external view returns(uint32) {
        return _docs.counterOfTypes();
    }

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32) {
        return _docs.counterOfVersions(uint32(typeOfDoc));
    }

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64) {
        return _docs.counterOfDocs(uint32(typeOfDoc), uint32(version));
    }

    function docExist(address body) public view returns(bool) {
        return _docs.docExist(body);
    }

    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40) {
        return _docs.getAuthor(typeOfDoc, version);
    }

    function getAuthorByBody(address body) external view returns(uint40) {
        return _docs.getAuthorByBody(body);
    }

    function getHeadByBody(address body) public view returns (DocsRepo.Head memory ) {
        return _docs.getHeadByBody(body);
    }

    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(snOfDoc);
    }

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc) {
        if (_users.counterOfUsers() >= acct) { 
            doc.body = _users.users[acct].primeKey.pubKey;
            if (_docs.docExist(doc.body)) doc.head = _docs.heads[doc.body];
            else doc.body = address(0);
        }
    }

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag) {
        flag = _docs.verifyDoc(snOfDoc);
    }

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getVersionsList(uint32(typeOfDoc));
    }

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(snOfDoc);
    } 

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

library DocsRepo {
    
    struct Head {
        uint32 typeOfDoc;
        uint32 version;
        uint64 seqOfDoc;
        uint40 author;
        uint40 creator;
        uint48 createDate;
    }
 
    struct Body {
        uint64 seq;
        address addr;
    }

    struct Doc {
        Head head;
        address body;
    }

    struct Repo {
        // typeOfDoc => version => seqOfDoc => Body
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Body))) bodies;
        mapping(address => Head) heads;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head.typeOfDoc = uint32(_sn >> 224);
        head.version = uint32(_sn >> 192);
        head.seqOfDoc = uint64(_sn >> 128);
        head.author = uint40(_sn >> 88);
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDoc,
                            head.version,
                            head.seqOfDoc,
                            head.author,
                            head.creator,
                            head.createDate);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function setTemplate(
        Repo storage repo,
        uint typeOfDoc, 
        address body,
        uint author,
        uint caller
    ) public returns (Head memory head) {
        head.typeOfDoc = uint32(typeOfDoc);
        head.author = uint40(author);
        head.creator = uint40(caller);

        require(body != address(0), "DR.setTemplate: zero address");
        require(head.typeOfDoc > 0, "DR.setTemplate: zero typeOfDoc");
        if (head.typeOfDoc > counterOfTypes(repo))
            head.typeOfDoc = _increaseCounterOfTypes(repo);

        require(head.author > 0, "DR.setTemplate: zero author");
        require(head.creator > 0, "DR.setTemplate: zero creator");

        head.version = _increaseCounterOfVersions(repo, head.typeOfDoc);
        head.createDate = uint48(block.timestamp);

        repo.bodies[head.typeOfDoc][head.version][0].addr = body;
        repo.heads[body] = head;
    }

    function createDoc(
        Repo storage repo, 
        bytes32 snOfDoc,
        address creator
    ) public returns (Doc memory doc)
    {
        doc.head = snParser(snOfDoc);
        doc.head.creator = uint40(uint160(creator));

        require(doc.head.typeOfDoc > 0, "DR.createDoc: zero typeOfDoc");
        require(doc.head.version > 0, "DR.createDoc: zero version");
        // require(doc.head.creator > 0, "DR.createDoc: zero creator");

        address temp = repo.bodies[doc.head.typeOfDoc][doc.head.version][0].addr;
        require(temp != address(0), "DR.createDoc: template not ready");

        doc.head.author = repo.heads[temp].author;
        doc.head.seqOfDoc = _increaseCounterOfDocs(repo, doc.head.typeOfDoc, doc.head.version);            
        doc.head.createDate = uint48(block.timestamp);

        doc.body = _createClone(temp);

        repo.bodies[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc].addr = doc.body;
        repo.heads[doc.body] = doc.head;

    }

    function transferIPR(
        Repo storage repo,
        uint typeOfDoc,
        uint version,
        uint transferee,
        uint caller 
    ) public {
        require (caller == getAuthor(repo, typeOfDoc, version),
            "DR.transferIPR: not author");
        repo.heads[repo.bodies[typeOfDoc][version][0].addr].author = uint40(transferee);
    }

    function _increaseCounterOfTypes(Repo storage repo) 
        private returns(uint32) 
    {
        repo.bodies[0][0][0].seq++;
        return uint32(repo.bodies[0][0][0].seq);
    }

    function _increaseCounterOfVersions(
        Repo storage repo, 
        uint256 typeOfDoc
    ) private returns(uint32) {
        repo.bodies[typeOfDoc][0][0].seq++;
        return uint32(repo.bodies[typeOfDoc][0][0].seq);
    }

    function _increaseCounterOfDocs(
        Repo storage repo, 
        uint256 typeOfDoc, 
        uint256 version
    ) private returns(uint64) {
        repo.bodies[typeOfDoc][version][0].seq++;
        return repo.bodies[typeOfDoc][version][0].seq;
    }

    // ==== CloneFactory ====

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly


    function _createClone(address temp) private returns (address result) {
        bytes20 tempBytes = bytes20(temp);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), tempBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function _isClone(address temp, address query)
        private view returns (bool result)
    {
        bytes20 tempBytes = bytes20(temp);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), tempBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }

    //##################
    //##   read I/O   ##
    //##################


    function counterOfTypes(Repo storage repo) public view returns(uint32) {
        return uint32(repo.bodies[0][0][0].seq);
    }

    function counterOfVersions(Repo storage repo, uint typeOfDoc) public view returns(uint32) {
        return uint32(repo.bodies[uint32(typeOfDoc)][0][0].seq);
    }

    function counterOfDocs(Repo storage repo, uint typeOfDoc, uint version) public view returns(uint64) {
        return repo.bodies[uint32(typeOfDoc)][uint32(version)][0].seq;
    }

    function getAuthor(
        Repo storage repo,
        uint typeOfDoc,
        uint version
    ) public view returns(uint40) {
        address temp = repo.bodies[typeOfDoc][version][0].addr;
        require(temp != address(0), "getAuthor: temp not exist");

        return repo.heads[temp].author;
    }

    function getAuthorByBody(
        Repo storage repo,
        address body
    ) public view returns(uint40) {
        Head memory head = getHeadByBody(repo, body);
        return getAuthor(repo, head.typeOfDoc, head.version);
    }

    function docExist(Repo storage repo, address body) public view returns(bool) {
        Head memory head = repo.heads[body];
        if (   body == address(0) 
            || head.typeOfDoc == 0 
            || head.version == 0 
            || head.seqOfDoc == 0
        ) return false;
   
        return repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr == body;
    }

    function getHeadByBody(
        Repo storage repo,
        address body
    ) public view returns (Head memory ) {
        return repo.heads[body];
    }


    function getDoc(
        Repo storage repo,
        bytes32 snOfDoc
    ) public view returns(Doc memory doc) {
        doc.head = snParser(snOfDoc);

        doc.body = repo.bodies[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc].addr;
        doc.head = repo.heads[doc.body];
    }

    function getVersionsList(
        Repo storage repo,
        uint typeOfDoc
    ) public view returns(Doc[] memory)
    {
        uint32 len = counterOfVersions(repo, typeOfDoc);
        Doc[] memory out = new Doc[](len);

        while (len > 0) {
            Head memory head;
            head.typeOfDoc = uint32(typeOfDoc);
            head.version = len;

            out[len - 1] = getDoc(repo, codifyHead(head));
            len--;
        }

        return out;
    }

    function getDocsList(
        Repo storage repo,
        bytes32 snOfDoc
    ) public view returns(Doc[] memory) {
        Head memory head = snParser(snOfDoc);
                
        uint64 len = counterOfDocs(repo, head.typeOfDoc, head.version);
        Doc[] memory out = new Doc[](len);

        while (len > 0) {
            head.seqOfDoc = len;
            out[len - 1] = getDoc(repo, codifyHead(head));
            len--;
        }

        return out;
    }

    function verifyDoc(
        Repo storage repo, 
        bytes32 snOfDoc
    ) public view returns(bool) {
        Head memory head = snParser(snOfDoc);

        address temp = repo.bodies[head.typeOfDoc][head.version][0].addr;
        address target = repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr;

        return _isClone(temp, target);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.8;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            delete set._values[lastIndex];
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    //======== Bytes32Set ========

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        public
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        public
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    //======== AddressSet ========

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        public
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    //======== UintSet ========

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) public returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        public
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set)
        public
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library LockersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Head {
        uint40 from;
        uint40 to;
        uint48 expireDate;
        uint128 value;
    }
    struct Body {
        address counterLocker;
        bytes payload;
    }
    struct Locker {
        Head head;
        Body body;
    }

    struct Repo {
        // hashLock => locker
        mapping (bytes32 => Locker) lockers;
        EnumerableSet.Bytes32Set snList;
    }

    //#################
    //##    Write    ##
    //#################

    function headSnParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            from: uint40(_sn >> 216),
            to: uint40(_sn >> 176),
            expireDate: uint48(_sn >> 128),
            value: uint128(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 headSn) {
        bytes memory _sn = abi.encodePacked(
                            head.from,
                            head.to,
                            head.expireDate,
                            head.value);
        assembly {
            headSn := mload(add(_sn, 0x20))
        }
    }

    function lockPoints(
        Repo storage repo,
        Head memory head,
        bytes32 hashLock
    ) public {
        Body memory body;
        lockConsideration(repo, head, body, hashLock);        
    }

    function lockConsideration(
        Repo storage repo,
        Head memory head,
        Body memory body,
        bytes32 hashLock
    ) public {       
        if (repo.snList.add(hashLock)) {            
            Locker storage locker = repo.lockers[hashLock];      
            locker.head = head;
            locker.body = body;
        } else revert ("LR.lockConsideration: occupied");
    }

    function pickupPoints(
        Repo storage repo,
        bytes32 hashLock,
        string memory hashKey,
        uint caller
    ) public returns(Head memory head) {
        
        bytes memory key = bytes(hashKey);

        require(hashLock == keccak256(key),
            "LR.pickupPoints: wrong key");

        Locker storage locker = repo.lockers[hashLock];

        require(block.timestamp < locker.head.expireDate, 
            "LR.pickupPoints: locker expired");

        bool flag = true;

        if (locker.body.counterLocker != address(0)) {
            require(locker.head.to == caller, 
                "LR.pickupPoints: wrong caller");

            uint len = key.length;
            bytes memory zero = new bytes(32 - (len % 32));

            bytes memory payload = abi.encodePacked(locker.body.payload, len, key, zero);
            (flag, ) = locker.body.counterLocker.call(payload);
        }

        if (flag) {
            head = locker.head;
            delete repo.lockers[hashLock];
            repo.snList.remove(hashLock);
        }
    }

    function withdrawDeposit(
        Repo storage repo,
        bytes32 hashLock,
        uint256 caller
    ) public returns(Head memory head) {

        Locker memory locker = repo.lockers[hashLock];

        require(block.timestamp >= locker.head.expireDate, 
            "LR.withdrawDeposit: locker not expired");

        require(locker.head.from == caller, 
            "LR.withdrawDeposit: wrong caller");

        if (repo.snList.remove(hashLock)) {
            head = locker.head;
            delete repo.lockers[hashLock];
        } else revert ("LR.withdrawDeposit: locker not exist");
    }

    //#################
    //##    Read     ##
    //#################

    function getHeadOfLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Head memory head) {
        return repo.lockers[hashLock].head;
    }

    function getLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Locker memory) {
        return repo.lockers[hashLock];
    }

    function getSnList(
        Repo storage repo
    ) public view returns (bytes32[] memory ) {
        return repo.snList.values();
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./LockersRepo.sol";

library UsersRepo {
    using LockersRepo for LockersRepo.Repo;

    struct Key {
        address pubKey;
        uint16 discount;
        uint40 gift; 
        uint40 coupon;
    }

    struct User {
        Key primeKey;
        Key backupKey;
    }

    struct Rule {
        uint40 eoaRewards;
        uint40 coaRewards;
        uint40 floor;
        uint16 rate;
        uint16 para;
    }

    struct Repo {
        // userNo => User
        mapping(uint256 => User) users;
        // key => userNo
        mapping(address => uint) userNo;
        LockersRepo.Repo lockers;       
    }

    // platformRule: Rule({
    //     eoaRewards: users[0].primeKey.gift,
    //     coaRewards: users[0].backupKey.gift,
    //     floor: users[0].backupKey.coupon,
    //     rate: users[0].primeKey.discount,
    //     para: users[0].backupKey.discount
    // });

    // counterOfUers: users[0].primeKey.coupon;
    
    // owner: users[0].primeKey.pubKey;
    // bookeeper: users[0].backupKey.pubKey;

    // ####################
    // ##    Modifier    ##
    // ####################

    modifier onlyOwner(Repo storage repo, address msgSender) {
        require(msgSender == getOwner(repo), 
            "UR.mf.OO: not owner");
        _;
    }

    modifier onlyKeeper(Repo storage repo, address msgSender) {
        require(msgSender == getBookeeper(repo), 
            "UR.mf.OK: not bookeeper");
        _;
    }

    modifier onlyPrimeKey(Repo storage repo, address msgSender) {
        require(msgSender == repo.users[getUserNo(repo, msgSender)].primeKey.pubKey, 
            "UR.mf.OPK: not primeKey");
        _;
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function ruleParser(bytes32 sn) public pure 
        returns(Rule memory rule) 
    {
        uint _sn = uint(sn);

        rule = Rule({
            eoaRewards: uint40(_sn >> 216),
            coaRewards: uint40(_sn >> 176),
            floor: uint40(_sn >> 136),
            rate: uint16(_sn >> 120),
            para: uint16(_sn >> 96)
        });
    }

    function setPlatformRule(Repo storage repo, bytes32 snOfRule, address msgSender) 
        public onlyOwner(repo, msgSender) 
    {

        Rule memory rule = ruleParser(snOfRule);

        User storage opt = repo.users[0];

        opt.primeKey.discount = rule.rate;
        opt.primeKey.gift = rule.eoaRewards;

        opt.backupKey.discount = rule.para;
        opt.backupKey.gift = rule.coaRewards;
        opt.backupKey.coupon = rule.floor;
    }

    function getPlatformRule(Repo storage repo) public view 
        returns (Rule memory rule) 
    {
        User storage opt = repo.users[0];

        rule = Rule({
            eoaRewards: opt.primeKey.gift,
            coaRewards: opt.backupKey.gift,
            floor: opt.backupKey.coupon,
            rate: opt.primeKey.discount,
            para: opt.backupKey.discount
        });
    }

    function transferOwnership(Repo storage repo, address newOwner, address msgSender) 
        public onlyOwner(repo, msgSender)
    {
        repo.users[0].primeKey.pubKey = newOwner;
    }

    function handoverCenterKey(Repo storage repo, address newKeeper, address msgSender) 
        public onlyKeeper(repo, msgSender) 
    {
        repo.users[0].backupKey.pubKey = newKeeper;
    }

    // ==== Author Setting ====

    function infoParser(bytes32 info) public pure returns(Key memory)
    {
        uint _info = uint(info);

        Key memory out = Key({
            pubKey: address(0),
            discount: uint16(_info >> 80),
            gift: uint40(_info >> 40),
            coupon: uint40(_info)
        });

        return out;
    }

    function setRoyaltyRule(
        Repo storage repo,
        bytes32 snOfRoyalty,
        address msgSender
    ) public onlyPrimeKey(repo, msgSender) {

        Key memory rule = infoParser(snOfRoyalty);

        uint author = getUserNo(repo, msgSender);
        User storage a = repo.users[author];

        a.backupKey.discount = rule.discount;
        a.backupKey.gift = rule.gift;
        a.backupKey.coupon = rule.coupon;

    }

    function getRoyaltyRule(Repo storage repo, uint author)
        public view returns (Key memory) 
    {
        require (author > 0, 'zero author');

        Key memory rule = repo.users[author].backupKey;
        delete rule.pubKey;

        return rule;
    }

    // ##################
    // ##    Points    ##
    // ##################

    function mintAndLockPoints(Repo storage repo, uint to, uint amt, uint expireDate, bytes32 hashLock, address msgSender) 
        public onlyOwner(repo, msgSender) returns (LockersRepo.Head memory head)
    {
        head = _prepareLockerHead(repo, to, amt, expireDate, msgSender);
        repo.lockers.lockPoints(head, hashLock);
    }

    function _prepareLockerHead(
        Repo storage repo, 
        uint to, 
        uint amt, 
        uint expireDate, 
        address msgSender
    ) private view returns (LockersRepo.Head memory head) {
        uint40 caller = getUserNo(repo, msgSender);

        require((amt >> 128) == 0, 
            "UR.prepareLockerHead: amt overflow");

        head = LockersRepo.Head({
            from: caller,
            to: uint40(to),
            expireDate: uint48(expireDate),
            value: uint128(amt)
        });
    }

    function lockPoints(Repo storage repo, uint to, uint amt, uint expireDate, bytes32 hashLock, address msgSender) 
        public onlyPrimeKey(repo, msgSender) returns (LockersRepo.Head memory head)
    {
        head = _prepareLockerHead(repo, to, amt, expireDate, msgSender);
        repo.lockers.lockPoints(head, hashLock);
    }

    function lockConsideration(
        Repo storage repo, 
        uint to, 
        uint amt, 
        uint expireDate, 
        address counterLocker, 
        bytes calldata payload, 
        bytes32 hashLock, 
        address msgSender
    ) public onlyPrimeKey(repo, msgSender) returns (LockersRepo.Head memory head) {
        head = _prepareLockerHead(repo, to, amt, expireDate, msgSender);
        LockersRepo.Body memory body = LockersRepo.Body({
            counterLocker: counterLocker,
            payload: payload 
        });
        repo.lockers.lockConsideration(head, body, hashLock);
    }

    function pickupPoints(
        Repo storage repo, 
        bytes32 hashLock, 
        string memory hashKey,
        address msgSender
    ) public returns (LockersRepo.Head memory head) 
    {
        uint caller = getUserNo(repo, msgSender);
        head = repo.lockers.pickupPoints(hashLock, hashKey, caller);
    }

    function withdrawDeposit(
        Repo storage repo, 
        bytes32 hashLock, 
        address msgSender
    ) public onlyPrimeKey(repo, msgSender) returns (LockersRepo.Head memory head) {
        uint caller = getUserNo(repo, msgSender);
        head = repo.lockers.withdrawDeposit(hashLock, caller);
    }

    function getLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (LockersRepo.Locker memory locker) 
    {
        locker = repo.lockers.getLocker(hashLock);
    }

    function getLocksList(
        Repo storage repo
    ) public view returns (bytes32[] memory) 
    {
        return repo.lockers.getSnList();
    }

    // ##########################
    // ##    User & Members    ##
    // ##########################

    // ==== reg user ====

    function _increaseCounterOfUsers(Repo storage repo) private returns (uint40) {
        repo.users[0].primeKey.coupon++;
        return repo.users[0].primeKey.coupon;
    }

    function regUser(Repo storage repo, address msgSender) public 
        returns (User memory )
    {

        require(!isKey(repo, msgSender), "UserRepo.RegUser: used key");

        uint seqOfUser = _increaseCounterOfUsers(repo);

        repo.userNo[msgSender] = seqOfUser;

        User memory user;

        user.primeKey.pubKey = msgSender;

        Rule memory rule = getPlatformRule(repo);

        if (_isContract(msgSender)) {
            user.primeKey.discount = 1;
            user.primeKey.gift = rule.coaRewards;
        } else user.primeKey.gift = rule.eoaRewards;

        repo.users[seqOfUser] = user;

        return user;
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function setBackupKey(Repo storage repo, address bKey, address msgSender) 
        public onlyPrimeKey(repo, msgSender)
    {
        require (!isKey(repo, bKey), "UR.SBK: used key");

        uint caller = getUserNo(repo, msgSender);

        User storage user = repo.users[caller];

        require(user.backupKey.pubKey == address(0), 
            "UR.SBK: already set backupKey");
        
        user.backupKey.pubKey = bKey;

        repo.userNo[bKey] = caller;
    }

    function upgradeBackupToPrime(
        Repo storage repo,
        address msgSender
    ) public {
        User storage user = repo.users[getUserNo(repo, msgSender)];
        (user.primeKey.pubKey, user.backupKey.pubKey) =
            (user.backupKey.pubKey, user.primeKey.pubKey);
    }


    // ##############
    // ## Read I/O ##
    // ##############

    // ==== options ====

    function counterOfUsers(Repo storage repo) public view returns (uint40) {
        return repo.users[0].primeKey.coupon;
    }

    function getOwner(Repo storage repo) public view returns (address) {
        return repo.users[0].primeKey.pubKey;
    }

    function getBookeeper(Repo storage repo) public view returns (address) {
        return repo.users[0].backupKey.pubKey;
    }

    // ==== register ====

    function isKey(Repo storage repo, address key) public view returns (bool) {
        return repo.userNo[key] > 0;
    }

    function getUser(Repo storage repo, address msgSender) 
        public view returns (User memory)
    {
        return repo.users[getUserNo(repo, msgSender)];
    }

    function getUserNo(Repo storage repo, address msgSender) 
        public view returns(uint40) 
    {
        uint40 user = uint40(repo.userNo[msgSender]);

        if (user > 0) return user;
        else revert ("UR.getUserNo: not registered");
    }
}