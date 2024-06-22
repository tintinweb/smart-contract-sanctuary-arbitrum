// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Utils/EpochConfigurable.sol";
import "../ERC20/IGlobalTokenMetrics.sol";
import "../Productivity/IProductivity.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Productivity/IAverageProductivityCalculator.sol";
import "../Resource/IResource.sol";
import "../Resource/ResourceConstants.sol";
import "./IAnimaStakingRewardsCalculator.sol";

struct SingleEpochResult {
  uint totalSupply;
  uint totalStaked;
  int effectiveTotalStaked;
  uint averageCirculatingSupply;
  int effectiveSupply;
  uint stakedPercentage;
  uint burnRatio;
  uint totalMints;
  uint totalBurns;
  uint stakerAprs;
  uint realmerAprs;
  uint rewardsPool;
}

struct MultiEpochResult {
  uint[] totalSupply;
  uint[] totalStaked;
  int[] effectiveTotalStaked;
  uint[] averageCirculatingSupply;
  int[] effectiveSupply;
  uint[] stakedPercentage;
  uint[] burnRatio;
  uint[] totalBurns;
  uint[] totalMints;
  uint[] stakerAprs;
  uint[] realmerAprs;
  uint[] rewardsPool;
}

struct SingleEpochRealmResult {
  uint realmId;
  uint currentStaked;
  uint boost;
  uint averageStaked;
  uint averageGains;
  uint stakerApr;
  uint stakingCapacity;
  uint[] dailyGains;
}

contract AnimaStakingInfo is EpochConfigurable {
  IGlobalTokenMetrics public GLOBAL_TOKEN_METRICS;
  IAnimaStakingRewardsCalculator public ANIMA_STAKING_REWARDS_CALCULATOR;
  IAverageProductivityCalculator public AVERAGE_PRODUCTIVITY;
  IAnimaStakingRewardsStorage public ANIMA_STAKING_REWARDS_STORAGE;
  IResource public RESOURCE;
  IERC20 public TOKEN;

  uint public constant AVERAGE_EPOCHS = 30;
  uint public constant YEAR = 365;

  constructor(
    address _manager,
    address _globalTokenMetrics,
    address _animaStakingRewardsCalculator,
    address _averageProductivity,
    address _animaStakingRewardsStorage,
    address _resource,
    address _token
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    GLOBAL_TOKEN_METRICS = IGlobalTokenMetrics(_globalTokenMetrics);
    ANIMA_STAKING_REWARDS_CALCULATOR = IAnimaStakingRewardsCalculator(
      _animaStakingRewardsCalculator
    );
    AVERAGE_PRODUCTIVITY = IAverageProductivityCalculator(_averageProductivity);
    ANIMA_STAKING_REWARDS_STORAGE = IAnimaStakingRewardsStorage(
      _animaStakingRewardsStorage
    );
    RESOURCE = IResource(_resource);
    TOKEN = IERC20(_token);
  }

  function rawValues(
    uint _startEpoch,
    uint _endEpoch
  ) public view returns (HistoryData memory result) {
    return GLOBAL_TOKEN_METRICS.historyMetrics(_startEpoch, _endEpoch);
  }

  function currentEpochBaseInfo()
    public
    view
    returns (SingleEpochResult memory result)
  {
    result.totalSupply = TOKEN.totalSupply();
    (
      result.totalStaked,
      result.effectiveTotalStaked,
      result.averageCirculatingSupply,
      result.effectiveSupply,
      result.stakedPercentage
    ) = GLOBAL_TOKEN_METRICS.currentStakedRatioView(AVERAGE_EPOCHS);

    (, result.totalBurns, result.totalMints) = GLOBAL_TOKEN_METRICS
      .currentBurnRatio(AVERAGE_EPOCHS);

    (
      result.stakerAprs,
      result.realmerAprs,
      result.burnRatio,
      result.rewardsPool
    ) = ANIMA_STAKING_REWARDS_CALCULATOR.currentBaseRewards();

    result.stakerAprs = _toApr(result.stakerAprs);
    result.realmerAprs = _toApr(result.realmerAprs);
  }

  function epochBaseInfoBatch(
    uint _startEpoch,
    uint _endEpoch
  ) public view returns (MultiEpochResult memory result) {
    result.totalSupply = GLOBAL_TOKEN_METRICS.epochCirculatingBatch(
      _startEpoch,
      _endEpoch
    );
    (
      result.totalStaked,
      result.effectiveTotalStaked,
      result.averageCirculatingSupply,
      result.effectiveSupply,
      result.stakedPercentage
    ) = GLOBAL_TOKEN_METRICS.stakedRatioAtEpochBatch(
      _startEpoch,
      _endEpoch,
      AVERAGE_EPOCHS
    );

    (, result.totalBurns, result.totalMints) = GLOBAL_TOKEN_METRICS
      .burnRatiosAtEpochBatch(_startEpoch, _endEpoch, AVERAGE_EPOCHS);
    (
      result.stakerAprs,
      result.realmerAprs,
      result.rewardsPool,
      result.burnRatio
    ) = ANIMA_STAKING_REWARDS_CALCULATOR.baseRewardsAtEpochBatch(
      _startEpoch,
      _endEpoch
    );

    for (uint i = 0; i < result.stakerAprs.length; i++) {
      result.stakerAprs[i] = _toApr(result.stakerAprs[i]);
      result.realmerAprs[i] = _toApr(result.realmerAprs[i]);
    }
  }

  function currentRealmInfo(
    uint _realmId,
    uint _additionalAnimaToStake
  ) public view returns (SingleEpochRealmResult memory result) {
    uint epoch = currentEpoch();
    uint startEpoch = epoch - AVERAGE_EPOCHS;
    result.realmId = _realmId;
    result.dailyGains = AVERAGE_PRODUCTIVITY.realmProductivityGainsBatch(
      startEpoch,
      epoch + 1,
      _realmId
    );
    result.averageGains = AVERAGE_PRODUCTIVITY
      .currentAverageRealmProductivityGains(_realmId, AVERAGE_EPOCHS);

    (
      result.boost,
      result.stakerApr,
      result.averageStaked
    ) = ANIMA_STAKING_REWARDS_CALCULATOR.estimateChamberRewards(
      _additionalAnimaToStake,
      _realmId
    );

    result.stakerApr = _toApr(result.stakerApr);
    result.stakingCapacity = RESOURCE.data(_realmId, resources.ANIMA_CAPACITY);
    (result.currentStaked, ) = ANIMA_STAKING_REWARDS_STORAGE
      .stakedAmountWithDeltas(_realmId, 0, 0);
  }

  function currentBatchRealmsInfo(
    uint[] memory _realmIds,
    uint _additionalAnimaToStake
  ) public view returns (SingleEpochRealmResult[] memory result) {
    result = new SingleEpochRealmResult[](_realmIds.length);
    for (uint i = 0; i < _realmIds.length; i++) {
      result[i] = currentRealmInfo(_realmIds[i], _additionalAnimaToStake);
    }
  }

  function _toApr(uint _rewards) internal pure returns (uint) {
    return (ONE_HUNDRED * _rewards * YEAR) / (1 ether * AVERAGE_EPOCHS);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IAnimaStakingRewardsStorage.sol";

interface IAnimaStakingRewardsCalculator {
  function MAX_REWARDS_PERIOD() external view returns (uint256);

  function currentBaseRewards()
    external
    view
    returns (
      uint stakerRewards,
      uint realmerRewards,
      uint burnRatio,
      uint rewardsPool
    );

  function baseRewardsAtEpochBatch(
    uint startEpoch,
    uint endEpoch
  )
    external
    view
    returns (
      uint[] memory stakerRewards,
      uint[] memory realmerRewards,
      uint[] memory burnRatios,
      uint[] memory rewardPools
    );

  function estimateChamberRewards(
    uint _additionalAnima,
    uint _realmId
  ) external view returns (uint boost, uint rewards, uint stakedAverage);

  function estimateChamberRewardsBatch(
    uint _additionalAnima,
    uint[] calldata _realmId
  )
    external
    view
    returns (
      uint[] memory bonuses,
      uint[] memory rewards,
      uint[] memory stakedAverage
    );

  function calculateRewardsView(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    view
    returns (
      uint256 stakerRewards,
      uint256 realmerRewards,
      uint256 vestedStake
    );

  function calculateRewards(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    returns (
      uint256 stakerRewards,
      uint256 realmerRewards,
      uint256 vestedStake
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

struct ChamberRewardsStorage {
  uint32 realmId;
  uint32 mintedAt;
  uint32 stakedAt;
  uint32 chamberStakedIndex;
  uint32 lastRealmerCollectedAt;
  uint32 lastStakerCollectedAt;
}

struct RealmRewardsStorage {
  uint32 lastCapacityAdjustedAt;
  uint lastCapacityUsed;
}

error ChamberAlreadyStaked(uint _realmId, uint _chamberId);
error ChamberNotStaked(uint _realmId, uint _chamberId);

interface IAnimaStakingRewardsStorage {
  function realmChamberIds(uint _realmId) external view returns (uint[] memory);

  function loadChamberInfo(
    uint256 _chamberId
  ) external view returns (ChamberRewardsStorage memory);

  function loadRealmInfo(
    uint256 _realmId
  ) external view returns (RealmRewardsStorage memory);

  function updateStakingRewards(
    uint256 _chamberId,
    bool _updateStakerTimestamp,
    bool _updateRealmerTimestamp,
    uint256 _lastUsedCapacity
  ) external;

  function stakedAmountWithDeltas(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint current, int[] memory deltas);

  function checkStaked(
    uint256 _chamberId
  ) external view returns (bool, uint256);

  function registerChamberStaked(uint256 _chamberId, uint256 _realmId) external;

  function registerChamberCompound(
    uint256 _chamberId,
    uint _rewardsAmount
  ) external;

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IGloballyStakedTokenCalculator {
  function currentGloballyStakedAverage(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageView(
    uint _epoch,
    uint _epochSpan,
    bool _includeCurrent
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function stakedAmountsBatch(
    uint _epochStart,
    uint _epochEnd
  )
    external
    view
    returns (address[] memory stakingAddresses, uint[][] memory stakedAmounts);

  function circulatingSupplyBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory circulatingSupplies);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGloballyStakedTokenCalculator.sol";
import "../Manager/ManagerModifier.sol";
import "../ERC20/ITokenMinter.sol";
import "../ERC20/ITokenSpender.sol";
import "../Utils/EpochConfigurable.sol";
import "../Utils/Totals.sol";

struct HistoryData {
  uint[] epochs;
  uint[] mints;
  uint[] burns;
  uint[] supply;
  uint[] totalStaked;
  address[] stakingAddresses;
  uint[][] stakedPerAddress;
}

interface IGlobalTokenMetrics {
  function historyMetrics(
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (HistoryData memory result);

  function epochCirculatingBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory);

  function currentAverageInCirculation(uint _epochSpan) external returns (uint);

  function currentAverageInCirculationView(
    uint _epochSpan
  ) external view returns (uint);

  function averageInCirculation(
    uint _epoch,
    uint _epochSpan
  ) external view returns (uint);

  function averageInCirculationBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  ) external view returns (uint[] memory result);

  function currentStakedRatio(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function currentStakedRatioView(
    uint _epochSpan
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function stakedRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function stakedRatioAtEpochBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function currentBurnRatio(
    uint _epochSpan
  ) external view returns (uint burnRatio, uint totalBurns, uint totalMints);

  function burnRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  ) external view returns (uint burnRatio, uint totalBurns, uint totalMints);

  function burnRatiosAtEpochBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory ratios,
      uint[] memory totalBurns,
      uint[] memory totalMints
    );

  function tokenMints(
    uint epochStart,
    uint epochEnd
  ) external view returns (uint[] memory);

  function tokenBurns(
    uint epochStart,
    uint epochEnd
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant MINTER_ADVENTURER_BUCKET = 1;
uint constant MINTER_REALM_BUCKET = 2;
uint constant MINTER_STAKER_BUCKET = 3;

interface ITokenMinter is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function mint(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant SPENDER_ADVENTURER_BUCKET = 1;
uint constant SPENDER_REALM_BUCKET = 2;

interface ITokenSpender is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function spend(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Productivity/IProductivity.sol";
import "../Utils/EpochConfigurable.sol";

interface IAverageProductivityCalculator {
  function currentRealmProductivityGains(
    uint _realmId
  ) external view returns (uint);

  function realmProductivityGains(
    uint _epoch,
    uint _realmId
  ) external view returns (uint);

  function realmProductivityGainsBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _realmId
  ) external view returns (uint[] memory result);

  function currentAverageRealmProductivityGains(
    uint _realmId,
    uint _epochSpan
  ) external view returns (uint);

  function averageRealmProductivityGains(
    uint _epoch,
    uint _realmId,
    uint _epochSpan
  ) external view returns (uint);

  function averageRealmProductivityGainsBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _realmId,
    uint _epochSpan
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

interface IProductivity is IEpochConfigurable {
  // All time Productivity
  function currentProductivity(uint256 _realmId) external view returns (uint);

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) external view returns (uint[] memory result);

  function previousEpochsProductivityTotals(
    uint _realmId,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint gains, uint losses);

  function epochsProductivityTotals(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint gains, uint losses);

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function epochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function change(uint256 _realmId, int _delta, bool _includeInTotals) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int _delta,
    bool _includeInTotals
  ) external;

  function increase(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external;

  function decrease(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IResource {
  function data(
    uint256 _realmId,
    uint256 _resourceId
  ) external view returns (uint256);

  function add(uint256 _realmId, uint256 _resourceId, uint256 _amount) external;

  function remove(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library resources {
  // Season 1 resources
  uint256 public constant MINERAL_DEPOSIT = 0;
  uint256 public constant LAND_ABUNDANCE = 1;
  uint256 public constant AQUATIC_RESOURCES = 2;
  uint256 public constant ANCIENT_ARTIFACTS = 3;

  // Staking capacities
  uint256 public constant ANIMA_CAPACITY = 100;

  uint256 public constant PARTICLE_CAPACITY = 110;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EpochConfigurable is Pausable, ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ArrayUtils.sol";

library Totals {
  /*
   * @dev Calculate the total value of an array of uints
   * @param _values An array of uints
   * @return sum The total value of the array
   */

  function calculateTotal(uint[] memory _values) internal pure returns (uint) {
    return calculateSubTotal(_values, 0, _values.length);
  }

  function calculateSubTotal(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint sum) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      sum += _values[i];
    }
  }

  function calculateTotalWithNonZeroCount(
    uint[] memory _values
  ) internal pure returns (uint total, uint nonZeroCount) {
    return calculateSubTotalWithNonZeroCount(_values, 0, _values.length);
  }

  function calculateSubTotalWithNonZeroCount(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint total, uint nonZeroCount) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      if (_values[i] > 0) {
        total += _values[i];
        nonZeroCount++;
      }
    }
  }

  /*
   * @dev Calculate the total value of an the current state and an array of gains, but only if the value is greater than 0 at any given point of time
   * @param _values An array of uints
   * @return sum The total value of the array
   */
  function calculateTotalBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint sum) {
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      sum += uint(currentValue);
    }
  }

  function calculateTotalBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
  }

  function calculateAverageBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
    sum = sum / _gains.length;
  }

  function calculateEachDayValueBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint[] memory values) {
    values = new uint[](_deltas.length);
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }

  function calculateEachDayValueBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint[] memory values) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    values = new uint[](_gains.length);
    uint signedCurrent = currentValue;
    for (uint i = _gains.length; i > 0; i--) {
      signedCurrent += _losses[i - 1];
      signedCurrent -= _gains[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }
}