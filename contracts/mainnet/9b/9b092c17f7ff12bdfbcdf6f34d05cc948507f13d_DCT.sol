// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./modules/UseAccessControl.sol";
import "./modules/Vester.sol";

interface IRewardPool {
    function distribute() external;
    // reward distributed to multiple chains;
}

contract DCT is ERC20, UseAccessControl {
    uint private _tps = 7 ether;

    uint private _lastMintAt;
    uint private _lastHalved;
    uint constant public HALVING_INTERVAL = 720 days;

    address private _rewardPool;

    uint private _athBalance;

    Vester private _vester;

    uint constant public MAX_SUPPLY = 3111666666 ether;
    bool public isMintingFinished = false;

    address public premineAddress;
    uint public premineAmount;
    uint public startedAt;

    constructor() ERC20("Goat Tech", "GOAT") {}

    function _deploy(
        bytes memory bytecode,
        uint _salt
    )
        internal
        returns(address addr)
    {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    function initDCT(
        address accessControl_,
        address rewardPool_,
        address premineAddress_,
        uint256 premineAmount_,
        address cleanTo_
    )
        external
        initializer
    {
        initUseAccessControl(accessControl_);

        _rewardPool = rewardPool_;
        _vester = Vester(_deploy( type(Vester).creationCode, 0));
        _vester.initVester(accessControl_, address(this), cleanTo_);
        premineAddress = premineAddress_;
        premineAmount = premineAmount_;
        // _mint(premineAddress_, premineAmount_);
    }

    function start()
        external
        onlyOwner
    {
        _mint(premineAddress, premineAmount);
        require(_lastMintAt == 0, "already started");
        startedAt = block.timestamp;
        _lastMintAt = block.timestamp;
        _lastHalved = block.timestamp;
    }

    function updateRewardPool(
        address rewardPool_
    )
        external
        onlyOwner
    {
        _rewardPool = rewardPool_;
    }

    function _beforeTokenTransfer(
        address from_,
        address,
        uint256
    )
        internal
        virtual
        override
    {
        if (msg.sender != address(_vester)) {
           _vester.unlock(from_);
        }
    }

    function tps()
        external
        view
        returns(uint)
    {
        return _tps;
    }

    function pendingA()
        public
        view
        returns(uint)
    {
        if (isMintingFinished || _lastMintAt == 0) {
            return 0;
        }
        uint pastTime = block.timestamp - _lastMintAt;
        return _tps * pastTime;
    }

    function publicMint()
        external
    {
        uint mintingA = pendingA();
        if (mintingA == 0) {
            return;
        }
        if (totalSupply() + mintingA > MAX_SUPPLY) {
            isMintingFinished = true;
            _mint(_rewardPool, MAX_SUPPLY - totalSupply());
            IRewardPool(_rewardPool).distribute();
            _lastMintAt = block.timestamp;
            return;
        }
        _mint(_rewardPool, mintingA);
        IRewardPool(_rewardPool).distribute();
        _lastMintAt = block.timestamp;
        if (block.timestamp - _lastHalved >= HALVING_INTERVAL) {
            _tps = _tps / 2;
            _lastHalved = block.timestamp;
        }
    }

    function lastMintAt()
        external
        view
        returns(uint)
    {
        return _lastMintAt;
    }

    function lastHalved()
        external
        view
        returns(uint)
    {
        return _lastHalved;
    }

    function rewardPool()
        external
        view
        returns(address)
    {
        return _rewardPool;
    }

    function vester()
        external
        view
        returns(address)
    {
        return address(_vester);
    }

    function balanceOf(address account_) public view override returns (uint256) {
        return super.balanceOf(account_) + _vester.getUnlockedA(account_);
    }

    function changeRewardPool(
        address rewardPool_
    )
        external
        onlyAdmin
    {
        _rewardPool = rewardPool_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IProfile {
    struct SProfile{
        address sponsor;
        uint sPercent;
        uint nextSPercent;
        uint updatedAt;
        uint ifs;
        uint bonusBooster;
    }

    function updateSponsor(
        address account_,
        address sponsor_
    )
        external;

    function profileOf(
        address account_
    )
        external
        view
        returns(SProfile memory);

    function getSponsorPart(
        address account_,
        uint amount_
    )
        external
        view
        returns(address sponsor, uint sAmount);

    function setSPercent(
        uint sPercent_
    )
        external;

    function setDefaultSPercentConfig(
        uint sPercent_
    )
        external;

    function setMinSPercentConfig(
        uint sPercent_
    )
        external;

    function updateFsOf(
        address account_,
        uint fs_
    )
        external;

    function updateBoosterOf(
        address account_,
        uint booster_
    )
        external;

    function fsOf(
        address account_
    )
        external
        view
        returns(uint);

    function boosterOf(
        address account_
    )
        external
        view
        returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";

library LLocker {
    struct SLock {
        uint startedAt;
        uint amount;
        uint duration;
    }

    function getLockId(
        address account_,
        address poolOwner_
    )
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encode(account_, poolOwner_));
    }

    function restDuration(
        SLock memory lockData_
    )
        internal
        view
        returns(uint)
    {
        if (lockData_.startedAt > block.timestamp) {
            return lockData_.duration + lockData_.startedAt - block.timestamp;
        }
        uint pastTime = block.timestamp - lockData_.startedAt;
        if (pastTime < lockData_.duration) {
            return lockData_.duration - pastTime;
        } else {
            return 0;
        }
    }

    function prolong(
        SLock storage lockData_,
        uint amount_,
        uint duration_
    )
        internal
    {
        if (lockData_.amount == 0) {
            require(amount_ > 0 && duration_ > 0, "amount_ = 0 or duration_ = 0");
        } else {
            require(amount_ > 0 || duration_ > 0, "amount_ = 0 and duration_ = 0");
        }

        lockData_.amount += amount_;

        uint rd = restDuration(lockData_);
        if (rd == 0) {
            lockData_.duration = duration_;
            lockData_.startedAt = block.timestamp;
            return;
        }

        lockData_.duration += duration_;
    }

    function isUnlocked(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        view
        returns(bool)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        uint elapsedTime = block.timestamp - lockData_.startedAt;
        return elapsedTime >= duration;
    }

    function calDuration(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        pure
        returns(uint)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        return duration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

library LPercentage {
    uint constant public DEMI = 10000;
    uint constant public DEMIE2 = DEMI * DEMI;
    uint constant public DEMIE3 = DEMIE2 * DEMI;

    function validatePercent(
        uint percent_
    )
        internal
        pure
    {
        // 100% == DEMI == 10000
        require(percent_ <= DEMI, "invalid percent");
    }

    function getPercentA(
        uint value,
        uint percent
    )
        internal
        pure
        returns(uint)
    {
        return value * percent / DEMI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Cashier {
    event SetCleanTo(
        address indexed cleanTo
    );

    event Clean(
        uint amount
    );

    uint private _lastestBalance;

    IERC20 private _token;

    address private _cleanTo;

    bool private _isCleanEnabled;

    function _initCashier(
        address token_,
        address cleanTo_
    )
        internal
    {
        _token = IERC20(token_);
        _setCleanTo(cleanTo_);
    }

    function _setCleanTo(
        address cleanTo_
    )
        internal
    {
        _cleanTo = cleanTo_;
        _isCleanEnabled = cleanTo_ != address(this);
        emit SetCleanTo(cleanTo_);
    }

    function _updateBalance()
        internal
    {
        _lastestBalance = _token.balanceOf(address(this));
    }

    function _cashIn()
        internal
        returns(uint)
    {
        uint incBalance = currentBalance() - _lastestBalance;
        _updateBalance();
        return incBalance;
    }

    function _cashOut(
        address to_,
        uint amount_
    )
        internal
    {
        try _token.transfer(to_, amount_) returns (bool success) {
        } catch {
        }
        _updateBalance();
    }

    // todo
    // check all clean calls logic
    // lockers
    // earnings
    // voting
    // distributors
    // vester
    /*
        cleanTo

        eLocker : eP2pDistributor
        dLocker : 0xDEAD

        eEarning : eP2pDistributor
        dEarning : 0xDEAD

        eVoting : eP2pDistributor
        dVoting : 0xDEAD

        distributors: revert all

        eVester : eP2pDistributor
        dVester : 0xDEAD

    */

    function clean()
        public
        virtual
    {
        require(_isCleanEnabled, "unable to clean");
        uint currentBal = currentBalance();
        if (currentBal > _lastestBalance) {
            uint amount = currentBal - _lastestBalance;
            _token.transfer(_cleanTo, amount);
            emit Clean(amount);
        }
        _updateBalance();
    }

    function cleanTo()
        external
        view
        returns(address)
    {
        return _cleanTo;
    }

    function currentBalance()
        public
        view
        returns(uint)
    {
        return _token.balanceOf(address(this));
    }

    function lastestBalance()
        public
        view
        returns(uint)
    {
        return _lastestBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

contract Initializable {
  bool private _isNotInitializable;
  address private _deployerOrigin;

  constructor()
  {
    _deployerOrigin = tx.origin;
  }

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(!_isNotInitializable, "isNotInitializable");
    require(tx.origin == _deployerOrigin || _deployerOrigin == address(0x0), "initializer access denied");
    _;
    _isNotInitializable = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IAccessControl {
    function addAdmins(
        address[] memory accounts_
    )
        external;

    function removeAdmins(
        address[] memory accounts_
    )
        external;

    /*
        view
    */

    function isOwner(
        address account_
    )
        external
        returns(bool);

    function isAdmin(
        address account_
    )
        external
        view
        returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Initializable.sol";

import "./interfaces/IAccessControl.sol";


// interface IBlast {
//   // Note: the full interface for IBlast can be found below
//   function configureClaimableGas() external;
//   function configureGovernor(address governor) external;
// }
// interface IBlastPoints {
//   function configurePointsOperator(address operator) external;
// }

// // https://docs.blast.io/building/guides/gas-fees
// // added constant: BLAST_GOV
// contract BlastClaimableGas {
//   IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
//   // todo
//   // replace gov address
//   address constant private BLAST_GOV = address(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);

//   function initClaimableGas() internal {
//     BLAST.configureClaimableGas();
//     // This sets the contract's governor. This call must come last because after
//     // the governor is set, this contract will lose the ability to configure itself.
//     BLAST.configureGovernor(BLAST_GOV);
//     IBlastPoints(0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800).configurePointsOperator(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);
//   }
// }

// contract UseAccessControl is Initializable, BlastClaimableGas {
contract UseAccessControl is Initializable {
    event ApproveAdmin(
        address indexed account,
        address indexed admin
    );

    event RevokeAdmin(
        address indexed account,
        address indexed admin
    );

    modifier onlyOwner() {
        require(_accessControl.isOwner(msg.sender), "onlyOwner");
        _;
    }

    modifier onlyAdmin() {
        require(_accessControl.isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyApprovedAdmin(
        address account_
    )
    {
        address admin = msg.sender;
        require(_accessControl.isAdmin(admin), "onlyAdmin");
        require(_isApprovedAdmin[account_][admin], "onlyApprovedAdmin");
        _;
    }

    IAccessControl internal _accessControl;

    mapping(address => mapping(address => bool)) private _isApprovedAdmin;

    function initUseAccessControl(
        address accessControl_
    )
        public
        initializer
    {
        _accessControl = IAccessControl(accessControl_);
        // initClaimableGas();
    }

    function approveAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(!_isApprovedAdmin[account][admin_], "onlyNotApprovedAdmin");
        _isApprovedAdmin[account][admin_] = true;
        emit ApproveAdmin(account, admin_);
    }

    function revokeAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        // require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(_isApprovedAdmin[account][admin_], "onlyApprovedAdmin");
        _isApprovedAdmin[account][admin_] = false;
        emit RevokeAdmin(account, admin_);
    }

    function isApprovedAdmin(
        address account_,
        address admin_
    )
        external
        view
        returns(bool)
    {
        return _isApprovedAdmin[account_][admin_];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Cashier.sol";

import "../lib/LLocker.sol";
import "../interfaces/IProfile.sol";

import "./UseAccessControl.sol";

contract Vester is Cashier, UseAccessControl {
    using LLocker for *;

    uint constant public MAX_LOCK_DURATION = 5 * 365 days;

    event UpdateLockData(
        address indexed account,
        LLocker.SLock lockData
    );

    mapping(address => LLocker.SLock) private _lockData;

    function initVester(
        address accessControl_,
        address token_,
        address cleanTo_
    )
        public
        initializer
    {
        _initCashier(token_, cleanTo_);
        initUseAccessControl(accessControl_);
    }

    function calAvarageDuration(
        LLocker.SLock memory lockData_,
        uint addedA_,
        uint duration_
    )
        public
        pure
        returns(uint)
    {
        return (lockData_.amount * lockData_.duration + addedA_ * duration_)
            / (lockData_.amount + addedA_);
    }

    function lock(
        address account_,
        uint duration_,
        uint cliff_
    )
        external
        onlyAdmin
    {
        uint amount = _cashIn();
        unlock(account_);
        LLocker.SLock storage lockData = _lockData[account_];
        if (lockData.amount == 0) {
            lockData.startedAt = block.timestamp + cliff_;
        }
        require(duration_ <= MAX_LOCK_DURATION, "duration too long");
        lockData.duration = calAvarageDuration(lockData, amount, duration_);
        lockData.amount += amount;
        emit UpdateLockData(account_, _lockData[account_]);
    }

    function transferLock(
        address from_,
        address to_,
        uint amount_
    )
        external
        onlyAdmin
    {
        unlock(from_);
        unlock(to_);
        LLocker.SLock storage lockData;
        lockData = _lockData[from_];
        lockData.amount -= amount_;
        uint duration = lockData.duration;
        emit UpdateLockData(from_, lockData);
        lockData = _lockData[to_];
        lockData.startedAt = block.timestamp;
        lockData.duration = calAvarageDuration(lockData, amount_, duration);
        lockData.amount += amount_;
        emit UpdateLockData(to_, lockData);
    }

    function unlock(
        address account_
    )
        public
    {
        LLocker.SLock storage lockData = _lockData[account_];
        if (lockData.amount == 0 || lockData.startedAt > block.timestamp) return;
        uint airdrop = _cashIn();
        (uint restA, uint restDuration) = currentLockData(account_);
        uint toUnlockA = lockData.amount - restA;
        lockData.startedAt = block.timestamp;
        lockData.amount = restA;
        lockData.duration = restDuration;
        uint toTransferA = toUnlockA + airdrop;
        if (toTransferA > 0) {
            _cashOut(account_, toUnlockA + airdrop);
        }
        emit UpdateLockData(account_, _lockData[account_]);
    }

    // function forcedUnlock(
    //     address account_,
    //     uint amount_
    // )
    //     public
    //     onlyAdmin
    // {
    //     unlock(account_);
    //     LLocker.SLock storage lockData = _lockData[account_];
    //     lockData.amount -= amount_;
    //     _cashOut(account_, amount_);
    //     emit UpdateLockData(account_, _lockData[account_]);
    // }

    function currentLockData(
        address account_
    )
        public
        view
        returns(uint restA, uint restDuration)
    {
        LLocker.SLock memory lockData = _lockData[account_];
        restDuration = LLocker.restDuration(lockData);
        restA = restDuration >= lockData.duration
            ? lockData.amount
            : lockData.amount * restDuration / lockData.duration;
    }

    function getUnlockedA(
        address account_
    )
        external
        view
        returns(uint)
    {
        LLocker.SLock memory lockData = _lockData[account_];
        (uint restA,) = currentLockData(account_);
        return lockData.amount - restA;
    }

    function getLockData(
        address account_
    )
        external
        view
        returns(LLocker.SLock memory)
    {
        return _lockData[account_];
    }
}