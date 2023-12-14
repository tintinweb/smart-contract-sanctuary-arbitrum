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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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

pragma solidity ^0.8.17;

uint64 constant DAILY_EPOCH_DURATION = 1 days;
uint64 constant DAILY_EPOCH_OFFSET = 0 hours;

uint64 constant HOURLY_EPOCH_DURATION = 1 hours;
uint64 constant NO_OFFSET = 0 hours;

uint256 constant ACTION_LOCK = 101;

uint256 constant ACTION_ADVENTURER_HOMAGE = 1001;
uint256 constant ACTION_ADVENTURER_BATTLE_V3 = 1002;
uint256 constant ACTION_ADVENTURER_COLLECT_EPOCH_REWARDS = 1003;
uint256 constant ACTION_ADVENTURER_VOID_CRAFTING = 1004;
uint256 constant ACTION_ADVENTURER_REALM_CRAFTING = 1005;
uint256 constant ACTION_ADVENTURER_ANIMA_REGENERATION = 1006;
uint256 constant ACTION_ADVENTURER_BATTLE_V3_OPPONENT = 1007;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM = 2001;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM = 2002;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM_SHARD = 2011;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM_SHARD = 2012;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL_SHARD = 2021;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL_SHARD = 2022;

uint256 constant ACTION_ARMORY_STAKE_LAB = 2031;
uint256 constant ACTION_ARMORY_UNSTAKE_LAB = 2032;

uint256 constant ACTION_ARMORY_STAKE_COLLECTIBLE = 2041;
uint256 constant ACTION_ARMORY_UNSTAKE_COLLECTIBLE = 2042;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL = 2051;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL = 2052;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Unauthorized(address _tokenAddr, uint256 _tokenId);
error EntityLocked(address _tokenAddr, uint256 _tokenId, uint _lockedUntil);
error MinEpochsTooLow(uint256 _minEpochs);
error InsufficientEpochSpan(
  uint256 _minEpochs,
  uint256 _epochs,
  address _tokenAddr,
  uint256 _tokenId
);
error DuplicateActionAttempt(address _tokenAddr, uint256 _tokenId);

interface IActionPermit {
  // Reverts if no permissions or action was already taken in the last _minEpochs
  function checkAndMarkActionComplete(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external;

  function checkAndMarkActionCompleteMany(
    address _sender,
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external;

  // Marks action complete even if already completed
  function forceMarkActionComplete(address _tokenAddr, uint256 _tokenId, uint256 _action) external;

  // Reverts if no permissions
  function checkPermissions(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof,
    uint256 _action
  ) external view;

  function checkOwner(
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof
  ) external view returns (address);

  function checkPermissionsMany(
    address _sender,
    address[] calldata _tokenAddr,
    uint256[] calldata _tokenId,
    bytes32[][] calldata _proofs,
    uint256 _action
  ) external view;

  function checkPermissionsMany(
    address _sender,
    address _tokenAddr,
    uint256[] calldata _tokenId,
    bytes32[][] calldata _proofs,
    uint256 _action
  ) external view;

  function checkOwnerBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs
  ) external view returns (address[] memory);

  // Reverts if action already taken this epoch
  function checkIfEnoughEpochsElapsed(
    address _tokenAddr,
    uint256 _tokenId,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external view;

  function checkIfEnoughEpochsElapsedBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external view;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../Productivity/IProductivity.sol";
import "../Productivity/IProductionCapacity.sol";
import "../lib/FloatingPointConstants.sol";
import "../Manager/ManagerModifier.sol";
import "../Action/Actions.sol";
import "../Action/IActionPermit.sol";
import "../Staker/IStructureStaker.sol";
import "../Realm/IRealm.sol";
import "./ICollectible.sol";

struct CollectibleConfig {
  bool enabled;
  uint productivityCost;
  uint productivityAmountProductivityCap;
  uint baseTokenCost;
  uint tokenCostProductivityCap;
  uint[] geos;
}

contract CollectibleProducerWithProductivity is Pausable, ManagerModifier {
  IProductivity public PRODUCTIVITY;
  IProductionCapacity public PRODUCTION_CAPACITY;
  IActionPermit public ACTION_PERMIT;
  IStructureStaker public immutable STRUCTURE_STAKER;
  IRealm public immutable REALM;
  ICollectible public immutable COLLECTIBLE;
  address public REACTOR;
  ERC20Burnable public TOKEN;

  event Produced(
    uint256 realmId,
    uint256 collectibleId,
    uint256 quantity,
    uint256 tokenCost,
    int256 productivityDelta,
    uint256 spentCapacity
  );

  error InvalidRealmIdOrder(uint realmId);
  error DisabledCollectible(uint realmId, uint collectible);
  error UnsupportedCollectible(uint realmId, uint collectible);
  error ProductionCapacityExceeded(uint realmId, uint collectible, uint amount, uint maxAmount);

  // Collectible id => config
  mapping(uint => CollectibleConfig) public COLLECTIBLE_CONFIGS;
  // Geo => collectible id => can produce (true/false)
  mapping(uint => mapping(uint => bool)) public GEO_SUPPORTED_COLLECTIBLES;

  constructor(
    address _manager,
    address _productivityStorage,
    address _actionPermit,
    address _structureStaker,
    address _realm,
    address _reactor,
    address _token,
    address _collectible,
    address _productionCapacity
  ) ManagerModifier(_manager) {
    PRODUCTIVITY = IProductivity(_productivityStorage);
    ACTION_PERMIT = IActionPermit(_actionPermit);
    STRUCTURE_STAKER = IStructureStaker(_structureStaker);
    REALM = IRealm(_realm);
    REACTOR = _reactor;
    TOKEN = ERC20Burnable(_token);
    COLLECTIBLE = ICollectible(_collectible);
    PRODUCTION_CAPACITY = IProductionCapacity(_productionCapacity);
  }

  function collect(
    uint256[] calldata _realmIds,
    uint256[] calldata _collectibleIds,
    uint256[] calldata _quantities,
    bytes32[][] calldata proofs
  ) external whenNotPaused {
    require(_realmIds.length == _collectibleIds.length && _realmIds.length == _quantities.length);

    ACTION_PERMIT.checkPermissionsMany(
      msg.sender,
      address(REALM),
      _realmIds,
      proofs,
      ACTION_REALM_COLLECT_COLLECTIBLES
    );

    int[] memory productivities = PRODUCTIVITY.currentProductivityBatch(_realmIds);
    uint[] memory capacities = PRODUCTION_CAPACITY.productionCapacityBatch(_realmIds);

    uint totalCost = 0;

    uint singularCost;
    int lastRealmId = -1;
    for (uint i = 0; i < _realmIds.length; i++) {
      // require realm ids to be in strict ascending order to make sure there are no duplicates
      if (lastRealmId > int(_realmIds[i])) {
        revert InvalidRealmIdOrder(_realmIds[i]);
      }
      lastRealmId = int(_realmIds[i]);

      (singularCost, productivities[i], capacities[i]) = _produce(
        _realmIds[i],
        _collectibleIds[i],
        _quantities[i],
        productivities[i],
        capacities[i]
      );
      totalCost += singularCost;
    }

    TOKEN.burnFrom(msg.sender, totalCost);
    COLLECTIBLE.mintBatchFor(msg.sender, _collectibleIds, _quantities);
    PRODUCTIVITY.changeBatch(_realmIds, productivities, true);
    PRODUCTION_CAPACITY.spendProductionCapacityBatch(_realmIds, capacities);
  }

  function collectionCostsAndMaxAmounts(
    uint256[] calldata _realmIds,
    uint256[][] calldata _collectibleIds
  ) external returns (uint[][] memory costs, uint[][] memory maxAmounts, uint[] memory capacities) {
    require(_realmIds.length == _collectibleIds.length);

    int[] memory productivities = PRODUCTIVITY.currentProductivityBatch(_realmIds);
    capacities = PRODUCTION_CAPACITY.productionCapacityBatch(_realmIds);
    bool hasReactor;
    costs = new uint[][](_realmIds.length);
    maxAmounts = new uint[][](_realmIds.length);
    for (uint i = 0; i < _realmIds.length; i++) {
      hasReactor = STRUCTURE_STAKER.hasStaked(_realmIds[i], REACTOR, 0);
      costs[i] = new uint[](_collectibleIds[i].length);
      maxAmounts[i] = new uint[](_collectibleIds[i].length);
      for (uint j = 0; j < _collectibleIds[i].length; j++) {
        CollectibleConfig storage cfg = COLLECTIBLE_CONFIGS[_collectibleIds[i][j]];
        costs[i][j] = _calculateCost(capacities[i], productivities[i], cfg);
        maxAmounts[i][j] = _calculateCost(capacities[i], productivities[i], cfg);
        if (hasReactor) {
          maxAmounts[i][j] *= 2;
        }
      }
    }
  }

  function _produce(
    uint _realmId,
    uint _collectibleId,
    uint _amount,
    int _productivity,
    uint _capacity
  ) internal returns (uint totalCost, int productivityDelta, uint spentCapacity) {
    CollectibleConfig storage config = COLLECTIBLE_CONFIGS[_collectibleId];
    if (!config.enabled) {
      revert DisabledCollectible(_realmId, _collectibleId);
    }
    if (_amount == 0) {
      return (totalCost, productivityDelta, spentCapacity);
    }

    _verifyProduction(_realmId, _collectibleId);

    uint singleCollectibleTokenCost = _calculateCost(_capacity, _productivity, config);
    uint maxAmount = _calculateAmount(_capacity, _productivity, config);

    bool hasReactor = STRUCTURE_STAKER.hasStaked(_realmId, REACTOR, 0);
    if (hasReactor) {
      maxAmount *= 2;
    }

    if (_amount > maxAmount) {
      revert ProductionCapacityExceeded(_realmId, _collectibleId, _amount, maxAmount);
    }

    totalCost = singleCollectibleTokenCost * _amount;
    productivityDelta = (-1) * int(config.productivityCost * _amount);
    if (hasReactor) {
      productivityDelta /= 2;
    }
    spentCapacity = ((_capacity * _amount) / maxAmount);
    emit Produced(_realmId, _collectibleId, _amount, totalCost, productivityDelta, spentCapacity);
  }

  function _verifyProduction(uint _realmId, uint _collectibleId) internal view {
    for (uint i = 0; i < 3; i++) {
      uint feature = REALM.realmFeatures(_realmId, 0);
      if (GEO_SUPPORTED_COLLECTIBLES[feature][_collectibleId]) {
        return;
      }
    }
    revert UnsupportedCollectible(_realmId, _collectibleId);
  }

  function _calculateAmount(
    uint _productionCapacity,
    int _productivity,
    CollectibleConfig storage collectibleConfig
  ) internal view returns (uint amount) {
    if (_productivity <= 0 || _productionCapacity == 0) {
      return 0;
    }

    uint adjustedProductivity = (uint(_productivity) * ONE_HUNDRED) / _productionCapacity;
    uint cappedAdjustedProductivity = adjustedProductivity >
      collectibleConfig.productivityAmountProductivityCap
      ? collectibleConfig.productivityAmountProductivityCap
      : adjustedProductivity;
    // Above soft cap adjustment
    if (adjustedProductivity > collectibleConfig.productivityAmountProductivityCap) {
      uint coefficient = ONE_HUNDRED +
        ((ONE_HUNDRED *
          (adjustedProductivity - collectibleConfig.productivityAmountProductivityCap)) /
          adjustedProductivity);
      cappedAdjustedProductivity = (cappedAdjustedProductivity * coefficient) / ONE_HUNDRED;
    }

    return
      (cappedAdjustedProductivity * uint(_productionCapacity)) /
      (collectibleConfig.productivityCost * ONE_HUNDRED);
  }

  function _calculateCost(
    uint _productionCapacity,
    int _productivity,
    CollectibleConfig storage collectibleConfig
  ) internal view returns (uint) {
    if (_productivity <= 0 || _productionCapacity == 0) {
      return collectibleConfig.baseTokenCost;
    }

    uint adjustedProductivity = (uint(_productivity) * ONE_HUNDRED) / _productionCapacity;
    // Costs are constant below cap
    if (adjustedProductivity < collectibleConfig.tokenCostProductivityCap) {
      return collectibleConfig.baseTokenCost;
    }
    return
      (collectibleConfig.baseTokenCost * adjustedProductivity) /
      collectibleConfig.tokenCostProductivityCap;
  }

  function updateCollectibleConfigs(
    uint[] calldata _collectibleIds,
    CollectibleConfig[] calldata _configs
  ) external onlyAdmin {
    require(_collectibleIds.length == _configs.length);

    for (uint i = 0; i < _collectibleIds.length; i++) {
      uint collectibleId = _collectibleIds[i];
      CollectibleConfig storage existingConfig = COLLECTIBLE_CONFIGS[collectibleId];

      // Disable current geos
      for (uint j = 0; j < existingConfig.geos.length; j++) {
        GEO_SUPPORTED_COLLECTIBLES[existingConfig.geos[j]][collectibleId] = false;
      }
      COLLECTIBLE_CONFIGS[_collectibleIds[i]] = _configs[i];

      // Enable geos from new config
      for (uint j = 0; j < _configs[i].geos.length; j++) {
        GEO_SUPPORTED_COLLECTIBLES[_configs[i].geos[j]][collectibleId] = true;
      }
    }
  }

  function updatePermit(address _permit) external onlyAdmin {
    ACTION_PERMIT = IActionPermit(_permit);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICollectible {
  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _ids,
    uint256 _amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;

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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IProductionCapacity {
  function productionCapacity(uint _realmId) external view returns (uint);

  function productionCapacityBatch(
    uint[] calldata _realmIds
  ) external view returns (uint[] memory result);

  function spendProductionCapacity(uint _realmId, uint _spentCapacity) external;

  function spendProductionCapacityBatch(
    uint[] calldata _realmIds,
    uint[] calldata _spentCapacity
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IProductivity {
  // All time Productivity
  function currentProductivity(uint256 _realmId) external returns (int);

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) external returns (int[] memory result);

  function previousEpochsProductivityTotals(
    uint _realmId
  ) external view returns (int total, int gains, int spending);

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds
  ) external view returns (int[] memory total, int[] memory gains, int[] memory spending);

  function change(uint256 _realmId, int _delta, bool _includeInTotals) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external;

  function changeBatch(uint256[] calldata _tokenIds, int _delta, bool _includeInTotals) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 _realmId) external view returns (address owner);

  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function isApprovedForAll(
    address owner,
    address operator
  ) external returns (bool);

  function realmFeatures(
    uint256 realmId,
    uint256 index
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStructureStaker {
  function stakeFor(
    address _staker,
    uint256 _realmId,
    address _addr,
    uint256 _structureId
  ) external;

  function unstakeFor(
    address _staker,
    uint256 _realmId,
    address _addr,
    uint256 _structureId
  ) external;

  function stakeBatchFor(
    address _staker,
    uint256[] calldata _realmIds,
    address[] calldata _addrs,
    uint256[] calldata _structureIds
  ) external;

  function unstakeBatchFor(
    address _staker,
    uint256[] calldata _realmIds,
    address[] calldata _addrs,
    uint256[] calldata _structureIds
  ) external;

  function getStaker(
    uint256 _realmId,
    address _addr,
    uint256 _structureId
  ) external;

  function hasStaked(
    uint256 _realmId,
    address _addr,
    uint256 _count
  ) external returns (bool);
}