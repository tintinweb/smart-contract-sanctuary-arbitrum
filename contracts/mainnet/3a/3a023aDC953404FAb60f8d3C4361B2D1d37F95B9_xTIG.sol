// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
pragma solidity ^0.8.0;

interface IExtraRewards {
    function claim() external;
    function pending(address _user, address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernanceStaking {
    function stake(uint256 _amount, uint256 _duration) external;
    function unstake(uint256 _amount) external;
    function claim() external;
    function distribute(address _token, uint256 _amount) external;
    function whitelistReward(address _rewardToken) external;
    function pending(address _user, address _token) external view returns (uint256);
    function userStaked(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IxTIG is IERC20 {
    function vestingPeriod() external view returns (uint256);
    function earlyUnlockPenalty() external view returns (uint256);
    function epochFeesGenerated(uint256 _epoch) external view returns (uint256);
    function epochAllocation(uint256 _epoch) external view returns (uint256);
    function epochAllocationClaimed(uint256 _epoch) external view returns (uint256);
    function feesGenerated(uint256 _epoch, address _trader) external view returns (uint256);
    function tigAssetValue(address _tigAsset) external view returns (uint256);
    function createVest() external;
    function claimTig() external;
    function earlyClaimTig() external;
    function claimFees() external;
    function addFees(address _trader, address _tigAsset, uint256 _fees) external;
    function addTigRewards(uint256 _epoch, uint256 _amount) external;
    function setTigAssetValue(address _tigAsset, uint256 _value) external;
    function setTrading(address _address) external;
    function setExtraRewards(address _address) external;
    function setVestingPeriod(uint256 _time) external;
    function setEarlyUnlockPenalty(uint256 _percent) external;
    function whitelistReward(address _rewardToken) external;
    function recoverTig(uint256 _amount) external;
    function contractPending(address _token) external view returns (uint256);
    function extraRewardsPending(address _token) external view returns (uint256);
    function pending(address _user, address _token) external view returns (uint256);
    function pendingTig(address _user) external view returns (uint256);
    function pendingEarlyTig(address _user) external view returns (uint256);
    function upcomingXTig(address _user) external view returns (uint256);
    function stakedTigBalance() external view returns (uint256);
    function userRewardBatches(address _user) external view returns (RewardBatch[] memory);
    function unclaimedAllocation(uint256 _epoch) external view returns (uint256);
    function currentEpoch() external view returns (uint256);

    struct RewardBatch {
        uint256 amount;
        uint256 unlockTime;
    }

    event TigRewardsAdded(address indexed sender, uint256 amount);
    event TigVested(address indexed account, uint256 amount);
    event TigClaimed(address indexed user, uint256 amount);
    event EarlyTigClaimed(address indexed user, uint256 amount, uint256 penalty);
    event TokenWhitelisted(address token);
    event TokenUnwhitelisted(address token);
    event RewardClaimed(address indexed user, uint256 reward);
    event VestingPeriodUpdated(uint256 time);
    event EarlyUnlockPenaltyUpdated(uint256 percent);
    event TradingUpdated(address indexed trading);
    event SetExtraRewards(address indexed extraRewards);
    event FeesAdded(address indexed _trader, address indexed _tigAsset, uint256 _amount, uint256 indexed _value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMappingBool {
    // Iterable mapping from address to bool;
    struct Map {
        address[] keys;
        mapping(address => bool) values;
        mapping(address => uint) indexOf;
    }

    function get(Map storage map, address key) internal view returns (bool) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key) internal {
        if (!map.values[key]) {
            map.values[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (map.values[key]) {
            delete map.values[key];

            uint index = map.indexOf[key];
            address lastKey = map.keys[map.keys.length - 1];

            map.indexOf[lastKey] = index;
            delete map.indexOf[key];

            map.keys[index] = lastKey;
            map.keys.pop();
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./utils/IterableMappingBool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IxTIG.sol";
import "./interfaces/IGovernanceStaking.sol";
import "./interfaces/IExtraRewards.sol";

contract xTIG is IxTIG, ERC20, Ownable {

    using IterableMappingBool for IterableMappingBool.Map;

    uint256 public constant DIVISION_CONSTANT = 1e10;
    uint256 public constant EPOCH_PERIOD = 1 weeks;

    IERC20 public immutable tig;
    IGovernanceStaking public immutable staking;
    address public immutable treasury;
    address public trading;
    IExtraRewards public extraRewards;

    uint256 public vestingPeriod = 30 days;
    uint256 public earlyUnlockPenalty = 5e9;
    mapping(address => uint256) public accRewardsPerToken;
    mapping(address => mapping(address => uint256)) public userPaid; // user => token => amount
    IterableMappingBool.Map private rewardTokens;

    mapping(uint256 => uint256) public epochFeesGenerated;
    mapping(uint256 => uint256) public epochAllocation;
    mapping(uint256 => uint256) public epochAllocationClaimed;
    mapping(uint256 => mapping(address => uint256)) public feesGenerated; // 7d epoch => trader => fees
    mapping(address => uint256) public tigAssetValue;
    mapping(address => RewardBatch[]) public userRewards;

    /**
     * @dev Throws if called by any account that is not minter.
     */
    modifier onlyTrading() {
        require(msg.sender == trading, "!Trading");
        _;
    }

    constructor(string memory name_, string memory symbol_, IERC20 _tig, IGovernanceStaking _staking, address _treasury) ERC20(name_, symbol_) {
        tig = _tig;
        staking = _staking;
        treasury = _treasury;
        tig.approve(address(_staking), type(uint256).max);
    }

    function createVest() external {
        uint256 _epoch = block.timestamp / EPOCH_PERIOD - 1;
        require(epochFeesGenerated[_epoch] != 0, "No fees generated");
        uint256 _amount = epochAllocation[_epoch] * feesGenerated[_epoch][msg.sender] / epochFeesGenerated[_epoch];
        require(_amount != 0, "No fees generated by trader");
        _claim(msg.sender);
        delete feesGenerated[_epoch][msg.sender];
        epochAllocationClaimed[_epoch] += _amount;
        userRewards[msg.sender].push(RewardBatch(_amount, block.timestamp + vestingPeriod));
        _mint(msg.sender, _amount);
        _updateUserPaid(msg.sender);
        emit TigVested(msg.sender, _amount);
    }

    function claimTig() external {
        _claim(msg.sender);
        RewardBatch[] storage rewardsStorage = userRewards[msg.sender];
        RewardBatch[] memory rewards = rewardsStorage;
        delete userRewards[msg.sender];
        uint256 _length = rewards.length;
        uint256 _amount;
        for (uint256 i=0; i<_length; i++) {
            RewardBatch memory reward = rewards[i];
            if (block.timestamp >= reward.unlockTime) {
                _amount = _amount + reward.amount;
            } else {
                rewardsStorage.push(reward);
            }
        }
        require(_amount != 0, "No TIG to claim");
        _burn(msg.sender, _amount);
        staking.unstake(_amount);
        _updateUserPaid(msg.sender);
        tig.transfer(msg.sender, _amount);
        emit TigClaimed(msg.sender, _amount);
    }

    function earlyClaimTig() external {
        RewardBatch[] memory rewards = userRewards[msg.sender];
        uint256 _length = rewards.length;
        require(_length != 0, "No TIG to claim");
        _claim(msg.sender);
        delete userRewards[msg.sender];
        uint256 _unstakeAmount;
        uint256 _userAmount;
        for (uint256 i=0; i<_length; i++) {
            RewardBatch memory reward = rewards[i];
            if (block.timestamp >= reward.unlockTime) {
                _userAmount += reward.amount;
                _unstakeAmount += reward.amount;
            } else {
                _userAmount += reward.amount*(DIVISION_CONSTANT-earlyUnlockPenalty)/DIVISION_CONSTANT;
                _unstakeAmount += reward.amount;
            }
        }
        _burn(msg.sender, _unstakeAmount);
        staking.unstake(_unstakeAmount);
        uint256 _amountForTreasury = _unstakeAmount-_userAmount;
        _updateUserPaid(msg.sender);
        tig.transfer(treasury, _amountForTreasury);
        tig.transfer(msg.sender, _userAmount);
        emit EarlyTigClaimed(msg.sender, _userAmount, _amountForTreasury);
    }

    function claimFees() external {
        _claim(msg.sender);
    }

    function addFees(address _trader, address _tigAsset, uint256 _fees) external onlyTrading {
        uint256 _value = _fees * tigAssetValue[_tigAsset] / 1e18;
        feesGenerated[block.timestamp / EPOCH_PERIOD][_trader] += _value;
        epochFeesGenerated[block.timestamp / EPOCH_PERIOD] += _value;
        emit FeesAdded(_trader, _tigAsset, _fees, _value);
    }

    function addTigRewards(uint256 _epoch, uint256 _amount) external onlyOwner {
        require(_epoch >= block.timestamp / EPOCH_PERIOD, "No past epochs");
        tig.transferFrom(msg.sender, address(this), _amount);
        epochAllocation[_epoch] += _amount;
        _distribute();
        staking.stake(_amount, 0);
        emit TigRewardsAdded(msg.sender, _amount);
    }

    function setTigAssetValue(address _tigAsset, uint256 _value) external onlyOwner {
        tigAssetValue[_tigAsset] = _value;
    }

    function setTrading(address _address) external onlyOwner {
        trading = _address;
        emit TradingUpdated(_address);
    }

    function setExtraRewards(address _address) external onlyOwner {
        extraRewards = IExtraRewards(_address);
        emit SetExtraRewards(_address);
    }

    function setVestingPeriod(uint256 _time) external onlyOwner {
        vestingPeriod = _time;
        emit VestingPeriodUpdated(_time);
    }

    function setEarlyUnlockPenalty(uint256 _percent) external onlyOwner {
        require(_percent <= DIVISION_CONSTANT, "Bad percent");
        earlyUnlockPenalty = _percent;
        emit EarlyUnlockPenaltyUpdated(_percent);
    }

    function whitelistReward(address _rewardToken) external onlyOwner {
        require(!rewardTokens.get(_rewardToken), "Already whitelisted");
        rewardTokens.set(_rewardToken);
        emit TokenWhitelisted(_rewardToken);
    }

    function unwhitelistReward(address _rewardToken) external onlyOwner {
        require(rewardTokens.get(_rewardToken), "Not whitelisted");
        rewardTokens.remove(_rewardToken);
        emit TokenUnwhitelisted(_rewardToken);
    }


    function recoverTig(uint256 _epoch) external onlyOwner {
        require(_epoch < block.timestamp / EPOCH_PERIOD - 1, "Unconcluded epoch");
        uint256 _amount = epochAllocation[_epoch] - epochAllocationClaimed[_epoch];
        _distribute();
        staking.unstake(_amount);
        tig.transfer(treasury, _amount);
    }

    function contractPending(address _token) public view returns (uint256) {
        return staking.pending(address(this), _token);
    }

    function extraRewardsPending(address _token) public view returns (uint256) {
        if (address(extraRewards) == address(0)) return 0;
        return extraRewards.pending(address(this), _token);
    }

    function pending(address _user, address _token) public view returns (uint256) {
        if (stakedTigBalance() == 0 || totalSupply() == 0) return 0;
        return balanceOf(_user) * (accRewardsPerToken[_token] + (contractPending(_token)*1e18/stakedTigBalance()) + (extraRewardsPending(_token)*1e18/totalSupply())) / 1e18 - userPaid[_user][_token];
    }

    function pendingTig(address _user) public view returns (uint256) {
        RewardBatch[] memory rewards = userRewards[_user];
        uint256 _length = rewards.length;
        uint256 _amount;
        for (uint256 i=0; i<_length; i++) {
            RewardBatch memory reward = rewards[i];
            if (block.timestamp >= reward.unlockTime) {
                _amount = _amount + reward.amount;
            } else {
                break;
            }
        }   
        return _amount;     
    }

    function pendingEarlyTig(address _user) public view returns (uint256) {
        RewardBatch[] memory rewards = userRewards[_user];
        uint256 _length = rewards.length;
        uint256 _amount;
        for (uint256 i=0; i<_length; i++) {
            RewardBatch memory reward = rewards[i];
            if (block.timestamp >= reward.unlockTime) {
                _amount += reward.amount;
            } else {
                _amount += reward.amount*(DIVISION_CONSTANT-earlyUnlockPenalty)/DIVISION_CONSTANT;
            }
        }
        return _amount;  
    }

    function upcomingXTig(address _user) external view returns (uint256) {
        uint256 _epoch = block.timestamp / EPOCH_PERIOD;
        if (epochFeesGenerated[_epoch] == 0) return 0;
        return epochAllocation[_epoch] * feesGenerated[_epoch][_user] / epochFeesGenerated[_epoch];
    }

    function stakedTigBalance() public view returns (uint256) {
        return staking.userStaked(address(this));
    }

    function userRewardBatches(address _user) external view returns (RewardBatch[] memory) {
        return userRewards[_user];
    }

    function unclaimedAllocation(uint256 _epoch) external view returns (uint256) {
        return epochAllocation[_epoch] - epochAllocationClaimed[_epoch];
    }

    function currentEpoch() external view returns (uint256) {
        return block.timestamp / EPOCH_PERIOD;
    }

    function _claim(address _user) internal {
        _distribute();
        address[] memory _tokens = rewardTokens.keys;
        uint256 _len = _tokens.length;
        for (uint256 i=0; i<_len; i++) {
            address _token = _tokens[i];
            uint256 _pending = pending(_user, _token);
            if (_pending != 0) {
                userPaid[_user][_token] += _pending;
                IERC20(_token).transfer(_user, _pending);
                emit RewardClaimed(_user, _pending);
            }
        }
    }

    function _distribute() internal {
        uint256 _length = rewardTokens.size();
        uint256[] memory _balancesBefore = new uint256[](_length);
        for (uint256 i=0; i<_length; i++) {
            address _token = rewardTokens.getKeyAtIndex(i);
            _balancesBefore[i] = IERC20(_token).balanceOf(address(this));
        }
        if (address(extraRewards) != address(0)) {
            extraRewards.claim();
        }
        staking.claim();
        for (uint256 i=0; i<_length; i++) {
            address _token = rewardTokens.getKeyAtIndex(i);
            uint256 _amount = IERC20(_token).balanceOf(address(this)) - _balancesBefore[i];
            if (stakedTigBalance() == 0 || totalSupply() == 0) {
                IERC20(_token).transfer(treasury, _amount);
                continue;
            }
            uint256 _amountPerStakedTig = _amount*1e18/stakedTigBalance();
            uint256 _amountPerxTig = _amount*1e18/totalSupply();
            accRewardsPerToken[_token] += _amountPerStakedTig;
            IERC20(_token).transfer(treasury, (_amountPerxTig-_amountPerStakedTig)*(stakedTigBalance()-totalSupply())/1e18);
        }
    }

    function _updateUserPaid(address _user) internal {
        address[] memory _tokens = rewardTokens.keys;
        uint256 _len = _tokens.length;
        for (uint256 i=0; i<_len; i++) {
            address _token = _tokens[i];
            userPaid[_user][_token] = balanceOf(_user) * accRewardsPerToken[_token] / 1e18;
        }
    }

    function _transfer(address, address, uint256) internal override {
        revert("xTIG: No transfer");
    }
}