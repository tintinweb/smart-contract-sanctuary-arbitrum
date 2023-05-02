// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/tokens/ISTEADY.sol";
import "../interfaces/tokens/IesSTEADY.sol";
import "../interfaces/tokens/ITokenManager.sol";
import "../interfaces/tokens/IesSTEADYUsage.sol";

/*
 * esSTEADY is Steadefi's escrowed governance token obtainable by converting STEADY to it
 * It's non-transferable, except from/to whitelisted addresses
 * It can be converted back to STEADY through a vesting process
 * This contract is made to receive esSTEADY deposits from users in order to allocate them to Usages (plugins) contracts
 */

contract TokenManager is Ownable, ReentrancyGuard, ITokenManager, Pausable {
  using Address for address;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  ISTEADY public immutable STEADY; // STEADY token to convert to/from
  IesSTEADY public immutable esSTEADY; // esSTEADY token to convert to/from

  // Redeeming min/max settings
  uint256 public minRedeemRatio = 5e17; // 1:0.5
  uint256 public maxRedeemRatio = 1e18; // 1:1
  uint256 public minRedeemDuration = 15 days; // 1296000s
  uint256 public maxRedeemDuration = 90 days; // 7776000s

  /* ========== STRUCTS ========== */

  struct EsSTEADYBalance {
    uint256 allocatedAmount; // Amount of esSTEADY allocated to a Usage
    uint256 redeemingAmount; // Total amount of esSTEADY currently being redeemed
  }

  struct RedeemInfo {
    uint256 STEADYAmount; // STEADY amount to receive when vesting has ended
    uint256 esSTEADYAmount; // esSTEADY amount to redeem
    uint256 endTime;
  }

  /* ========== CONSTANTS ========== */

  uint256 public constant MAX_DEALLOCATION_FEE = 2e16; // 2%
  uint256 public constant MAX_FIXED_RATIO = 1e18; // 100%
  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== MAPPINGS ========== */

  mapping(address => mapping(address => uint256)) public usageApprovals; // Usage approvals to allocate esSTEADY
  mapping(address => mapping(address => uint256)) public override usageAllocations; // Active esSTEADY allocations to usages
  mapping(address => EsSTEADYBalance) public esSTEADYBalances; // User's esSTEADY balances
  mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances
  mapping(address => uint256) public usagesDeallocationFee; // Fee paid when deallocating esSTEADY

  /* ========== EVENTS ========== */

  event ApproveUsage(address indexed userAddress, address indexed usageAddress, uint256 amount);
  event Convert(address indexed from, address to, uint256 amount);
  event UpdateRedeemSettings(uint256 minRedeemRatio, uint256 maxRedeemRatio, uint256 minRedeemDuration, uint256 maxRedeemDuration);
  event UpdateDeallocationFee(address indexed usageAddress, uint256 fee);
  event Redeem(address indexed userAddress, uint256 esSTEADYAmount, uint256 STEADYAmount, uint256 duration);
  event FinalizeRedeem(address indexed userAddress, uint256 esSTEADYAmount, uint256 STEADYAmount);
  event CancelRedeem(address indexed userAddress, uint256 esSTEADYAmount);
  event Allocate(address indexed userAddress, address indexed usageAddress, uint256 amount);
  event Deallocate(address indexed userAddress, address indexed usageAddress, uint256 amount, uint256 fee);

  /* ========== MODIFIERS ========== */

  /**
   * Check if a redeem entry exists
   * @param _userAddress address of redeemer
   * @param _redeemIndex index to check
   */
  modifier validateRedeem(address _userAddress, uint256 _redeemIndex) {
    require(_redeemIndex < userRedeems[_userAddress].length, "validateRedeem: redeem entry does not exist");
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  /**
   * @param _STEADY address of STEADY token
   * @param _esSTEADY address of esSTEADY token
   */
  constructor(ISTEADY _STEADY, IesSTEADY _esSTEADY) {
    require(address(_STEADY) != address(0), "Invalid 0 address");
    require(address(_esSTEADY) != address(0), "Invalid 0 address");

    STEADY = _STEADY;
    esSTEADY = _esSTEADY;

    _pause(); // Pause redemption at the start
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * Returns user's esSTEADY balances
   * @param _userAddress user address
   * @return allocatedAmount amount of esSTEADY allocated to a plugin in 1e18
   * @return redeemingAmount amount of esSTEADY being redeemed in 1e18
   */
  function getEsSTEADYBalance(address _userAddress) external view returns (uint256 allocatedAmount, uint256 redeemingAmount) {
    EsSTEADYBalance storage balance = esSTEADYBalances[_userAddress];
    return (balance.allocatedAmount, balance.redeemingAmount);
  }

  /**
   * Returns redeemable STEADY for "amount" of esSTEADY vested for "duration" seconds
   * @param _amount amount of esSTEADY being redeemed in 1e18
   * @param _duration duration of redemption
   * @return amount amount of STEADY to receive after redemption is completed in 1e18
   */
  function getSTEADYByVestingDuration(uint256 _amount, uint256 _duration) public view returns (uint256) {
    if (_duration < minRedeemDuration) {
      return 0;
    }

    // capped to maxRedeemDuration
    if (_duration > maxRedeemDuration) {
      return _amount * (maxRedeemRatio) / (SAFE_MULTIPLIER);
    }

    uint256 ratio = minRedeemRatio + (
      (_duration - (minRedeemDuration)) * (maxRedeemRatio - (minRedeemRatio))
      / (maxRedeemDuration - (minRedeemDuration))
    );

    return _amount * (ratio)/ (SAFE_MULTIPLIER);
  }

  /**
   * Returns quantity of "userAddress" pending redeems
   * @param _userAddress user address
   * @return pendingRedeems amount of esSTEADY allocated to a plugin in 1e18
   */
  function getUserRedeemsLength(address _userAddress) external view returns (uint256) {
    return userRedeems[_userAddress].length;
  }

  /**
   * Returns "userAddress" info for a pending redeem identified by "redeemIndex"
   * @param _userAddress address of redeemer
   * @param _redeemIndex index to check
   * @return STEADYAmount amount of STEADY in redemption
   * @return esSTEADYAmount amount of esSTEADY redeemable in this redemption
   * @return endTime timestamp when redemption is fully complete
   */
  function getUserRedeem(address _userAddress, uint256 _redeemIndex)
    external view validateRedeem(_userAddress, _redeemIndex)
    returns (uint256 STEADYAmount, uint256 esSTEADYAmount, uint256 endTime)
  {
    RedeemInfo storage _redeem = userRedeems[_userAddress][_redeemIndex];
    return (_redeem.STEADYAmount, _redeem.esSTEADYAmount, _redeem.endTime);
  }

  /**
   * Returns approved esSTEADY to allocate from "userAddress" to "usageAddress"
   * @param _userAddress address of user
   * @param _usageAddress address of plugin
   * @return amount amount of esSTEADY approved to plugin in 1e18
   */
  function getUsageApproval(address _userAddress, address _usageAddress) external view returns (uint256) {
    return usageApprovals[_userAddress][_usageAddress];
  }

  /**
   * Returns allocated esSTEADY from "userAddress" to "usageAddress"
   * @param _userAddress address of user
   * @param _usageAddress address of plugin
   * @return amount amount of esSTEADY allocated to plugin in 1e18
   */
  function getUsageAllocation(address _userAddress, address _usageAddress) external view returns (uint256) {
    return usageAllocations[_userAddress][_usageAddress];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * Convert STEADY to esSTEADY
   * @param _amount amount of STEADY to convert in 1e18
   */
  function convert(uint256 _amount) external nonReentrant {
    _convert(_amount, msg.sender);
  }

  /**
   * Convert STEADY to esSTEADY to "to" address
   * @param _amount amount of STEADY to convert in 1e18
   * @param _to address to convert to
   */
  function convertTo(uint256 _amount, address _to) external override nonReentrant {
    require(address(msg.sender).isContract(), "convertTo: not allowed");

    _convert(_amount, _to);
  }

  /**
   * Approves "usage" address to get allocations up to "amount" of esSTEADY from msg.sender
   * @param _usage address of usage plugin
   * @param _amount amount of esSTEADY to approve in 1e18
   */
  function approveUsage(IesSTEADYUsage _usage, uint256 _amount) external nonReentrant {
    require(address(_usage) != address(0), "approveUsage: approve to the zero address");

    usageApprovals[msg.sender][address(_usage)] = _amount;
    emit ApproveUsage(msg.sender, address(_usage), _amount);
  }

  /**
   * Initiates redeem process (esSTEADY to STEADY)
   * @param _esSTEADYAmount amount of esSTEADY to redeem
   * @param _duration selected timestamp of redemption completion
   */
  function redeem(uint256 _esSTEADYAmount, uint256 _duration) external nonReentrant whenNotPaused {
    require(_esSTEADYAmount > 0, "redeem: amount cannot be null");
    require(_duration >= minRedeemDuration, "redeem: duration too low");
    require(_duration <= maxRedeemDuration, "redeem: duration too high");

    IERC20(address(esSTEADY)).safeTransferFrom(msg.sender, address(this), _esSTEADYAmount);
    EsSTEADYBalance storage balance = esSTEADYBalances[msg.sender];

    // get corresponding STEADY amount
    uint256 STEADYAmount = getSTEADYByVestingDuration(_esSTEADYAmount, _duration);
    emit Redeem(msg.sender, _esSTEADYAmount, STEADYAmount, _duration);

    // if redeeming is not immediate, go through vesting process
    if (_duration > 0) {
      // add to SBT total
      balance.redeemingAmount = balance.redeemingAmount + (_esSTEADYAmount);

      // add redeeming entry
      userRedeems[msg.sender].push(RedeemInfo(STEADYAmount, _esSTEADYAmount, _currentBlockTimestamp() + (_duration)));
    } else {
      // immediately redeem for STEADY
      _finalizeRedeem(msg.sender, _esSTEADYAmount, STEADYAmount);
    }
  }

  /**
   * Finalizes redeem process when vesting duration has been reached
   * @param _redeemIndex redemption index
   * Can only be called by the redeem entry owner
   */
  function finalizeRedeem(uint256 _redeemIndex) external nonReentrant validateRedeem(msg.sender, _redeemIndex) {
    EsSTEADYBalance storage balance = esSTEADYBalances[msg.sender];
    RedeemInfo storage _redeem = userRedeems[msg.sender][_redeemIndex];
    require(_currentBlockTimestamp() >= _redeem.endTime, "finalizeRedeem: vesting duration has not ended yet");

    // remove from SBT total
    balance.redeemingAmount = balance.redeemingAmount - (_redeem.esSTEADYAmount);
    _finalizeRedeem(msg.sender, _redeem.esSTEADYAmount, _redeem.STEADYAmount);

    // remove redeem entry
    _deleteRedeemEntry(_redeemIndex);
  }

  /**
   * Cancels an ongoing redeem entry
   * @param _redeemIndex redemption index
   * Can only be called by its owner
   */
  function cancelRedeem(uint256 _redeemIndex) external nonReentrant validateRedeem(msg.sender, _redeemIndex) {
    EsSTEADYBalance storage balance = esSTEADYBalances[msg.sender];
    RedeemInfo storage _redeem = userRedeems[msg.sender][_redeemIndex];

    // make redeeming esSTEADY available again
    balance.redeemingAmount = balance.redeemingAmount - (_redeem.esSTEADYAmount);
    IERC20(address(esSTEADY)).safeTransfer(msg.sender, _redeem.esSTEADYAmount);

    emit CancelRedeem(msg.sender, _redeem.esSTEADYAmount);

    // remove redeem entry
    _deleteRedeemEntry(_redeemIndex);
  }

  /**
   * Allocates caller's "amount" of available esSTEADY to "usageAddress" contract
   * args specific to usage contract must be passed into "usageData"
   * @param _usageAddress address of plugin
   * @param _amount amount of esSTEADY in 1e18
   * @param _usageData for extra data params for specific plugins
   */
  function allocate(address _usageAddress, uint256 _amount, bytes calldata _usageData) external nonReentrant {
    _allocate(msg.sender, _usageAddress, _amount);

    // allocates esSTEADY to usageContract
    IesSTEADYUsage(_usageAddress).allocate(msg.sender, _amount, _usageData);
  }

  /**
   * Allocates "amount" of available esSTEADY from "userAddress" to caller (ie usage contract)
   * @param _userAddress address of user
   * @param _amount amount of esSTEADY in 1e18
   * Caller must have an allocation approval for the required esSTEADY from "userAddress"
   */
  function allocateFromUsage(address _userAddress, uint256 _amount) external override nonReentrant {
    _allocate(_userAddress, msg.sender, _amount);
  }

  /**
   * Deallocates caller's "amount" of available esSTEADY from "usageAddress" contract
   * args specific to usage contract must be passed into "usageData"
   * @param _usageAddress address of plugin
   * @param _amount amount of esSTEADY in 1e18
   * @param _usageData for extra data params for specific plugins
   */
  function deallocate(address _usageAddress, uint256 _amount, bytes calldata _usageData) external nonReentrant {
    _deallocate(msg.sender, _usageAddress, _amount);

    // deallocate esSTEADY into usageContract
    IesSTEADYUsage(_usageAddress).deallocate(msg.sender, _amount, _usageData);
  }

  /**
   * Deallocates "amount" of allocated esSTEADY belonging to "userAddress" from caller (ie usage contract)
   * Caller can only deallocate esSTEADY from itself
   * @param _userAddress address of user
   * @param _amount amount of esSTEADY in 1e18
   */
  function deallocateFromUsage(address _userAddress, uint256 _amount) external override nonReentrant {
    _deallocate(_userAddress, msg.sender, _amount);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
   * Convert caller's "amount" of STEADY into esSTEADY to "to"
   * @param _amount amount of STEADY in 1e18
   * @param _to address to send esSTEADY to
   */
  function _convert(uint256 _amount, address _to) internal {
    require(_amount != 0, "convert: amount cannot be null");

    IERC20(address(STEADY)).safeTransferFrom(msg.sender, address(this), _amount);

    // mint new esSTEADY
    esSTEADY.mint(_to, _amount);

    emit Convert(msg.sender, _to, _amount);

  }

  /**
   * Finalizes the redeeming process for "userAddress" by transferring him "STEADYAmount" and removing "esSTEADYAmount" from supply
   * Any vesting check should be ran before calling this
   * STEADY excess is automatically burnt
   * @param _userAddress address of user finalizing redemption
   * @param _esSTEADYAmount amount of esSTEADY to remove in 1e18
   * @param _STEADYAmount amount of STEADY to transfer in 1e18
   */
  function _finalizeRedeem(address _userAddress, uint256 _esSTEADYAmount, uint256 _STEADYAmount) internal {
    uint256 STEADYExcess = _esSTEADYAmount - (_STEADYAmount);

    // sends due STEADY tokens
    IERC20(address(STEADY)).safeTransfer(_userAddress, _STEADYAmount);

    // burns STEADY excess if any
    STEADY.burn(STEADYExcess);
    esSTEADY.burn(_esSTEADYAmount);

    emit FinalizeRedeem(_userAddress, _esSTEADYAmount, _STEADYAmount);
  }

  /**
   * Allocates "userAddress" user's "amount" of available esSTEADY to "usageAddress" contract
   * @param _userAddress address of user
   * @param _usageAddress address of plugin
   * @param _amount amount of esSTEADY in 1e18
   */
  function _allocate(address _userAddress, address _usageAddress, uint256 _amount) internal {
    require(_amount > 0, "allocate: amount cannot be null");

    EsSTEADYBalance storage balance = esSTEADYBalances[_userAddress];

    // approval checks if allocation request amount has been approved by userAddress to be allocated to this usageAddress
    uint256 approvedEsSTEADY = usageApprovals[_userAddress][_usageAddress];
    require(approvedEsSTEADY >= _amount, "allocate: non authorized amount");

    // remove allocated amount from usage's approved amount
    usageApprovals[_userAddress][_usageAddress] = approvedEsSTEADY - (_amount);

    // update usage's allocatedAmount for userAddress
    usageAllocations[_userAddress][_usageAddress] = usageAllocations[_userAddress][_usageAddress] + (_amount);

    // adjust user's esSTEADY balances
    balance.allocatedAmount = balance.allocatedAmount + (_amount);
    IERC20(address(esSTEADY)).safeTransferFrom(_userAddress, address(this), _amount);

    emit Allocate(_userAddress, _usageAddress, _amount);
  }

  /**
   * Deallocates "amount" of available esSTEADY to "usageAddress" contract
   * @param _userAddress address of user
   * @param _usageAddress address of plugin
   * @param _amount amount of esSTEADY in 1e18
   */
  function _deallocate(address _userAddress, address _usageAddress, uint256 _amount) internal {
    require(_amount > 0, "deallocate: amount cannot be null");

    // check if there is enough allocated esSTEADY to this usage to deallocate
    uint256 allocatedAmount = usageAllocations[_userAddress][_usageAddress];
    require(allocatedAmount >= _amount, "deallocate: non authorized _amount");

    // remove deallocated amount from usage's allocation
    usageAllocations[_userAddress][_usageAddress] = allocatedAmount - (_amount);

    uint256 deallocationFeeAmount = _amount * (usagesDeallocationFee[_usageAddress]) / SAFE_MULTIPLIER;

    // adjust user's esSTEADY balances
    EsSTEADYBalance storage balance = esSTEADYBalances[_userAddress];
    balance.allocatedAmount = balance.allocatedAmount - (_amount);
    IERC20(address(esSTEADY)).safeTransfer(_userAddress, _amount - (deallocationFeeAmount));
    // burn corresponding STEADY and esSTEADY
    STEADY.burn(deallocationFeeAmount);
    esSTEADY.burn(deallocationFeeAmount);

    emit Deallocate(_userAddress, _usageAddress, _amount, deallocationFeeAmount);
  }

  /**
   * Deletes redemption entry
   * @param _index index of redemption
   */
  function _deleteRedeemEntry(uint256 _index) internal {
    userRedeems[msg.sender][_index] = userRedeems[msg.sender][userRedeems[msg.sender].length - 1];
    userRedeems[msg.sender].pop();
  }

  /**
   * Utility function to get the current block timestamp
   * @return timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    /* solhint-disable not-rely-on-time */
    return block.timestamp;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
   * Updates all redeem ratios and durations
   * @param _minRedeemRatio min redemption ratio in 1e18
   * @param _maxRedeemRatio max redemption ratio in 1e18
   * @param _minRedeemDuration min redemption duration in timestamp
   * @param _maxRedeemDuration max redemption duration in timestamp
   */
  function updateRedeemSettings(
    uint256 _minRedeemRatio,
    uint256 _maxRedeemRatio,
    uint256 _minRedeemDuration,
    uint256 _maxRedeemDuration
  ) external onlyOwner {
    require(_minRedeemRatio <= _maxRedeemRatio, "updateRedeemSettings: wrong ratio values");
    require(_minRedeemDuration < _maxRedeemDuration, "updateRedeemSettings: wrong duration values");
    require(_maxRedeemRatio <= MAX_FIXED_RATIO, "updateRedeemSettings: wrong ratio values"); // should never exceed 100%

    minRedeemRatio = _minRedeemRatio;
    maxRedeemRatio = _maxRedeemRatio;
    minRedeemDuration = _minRedeemDuration;
    maxRedeemDuration = _maxRedeemDuration;

    emit UpdateRedeemSettings(_minRedeemRatio, _maxRedeemRatio, _minRedeemDuration, _maxRedeemDuration);
  }

  /**
   * Updates fee paid by users when deallocating from "usageAddress"
   * @param _usageAddress address of plugin
   * @param _fee deallocation fee in 1e18
   */
  function updateDeallocationFee(address _usageAddress, uint256 _fee) external onlyOwner {
    require(_fee <= MAX_DEALLOCATION_FEE, "updateDeallocationFee: too high");

    usagesDeallocationFee[_usageAddress] = _fee;

    emit UpdateDeallocationFee(_usageAddress, _fee);
  }

  /**
   * Pause contract not allowing for redemption
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * Unpause contract allowing for redemption
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenManager {
  function usageAllocations(address userAddress, address usageAddress) external view returns (uint256 allocation);
  function allocateFromUsage(address userAddress, uint256 amount) external;
  function deallocateFromUsage(address userAddress, uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IesSTEADYUsage {
  function allocate(address userAddress, uint256 amount, bytes calldata data) external;
  function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IesSTEADY is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISTEADY is IERC20 {
  function burn(uint256 amount) external;
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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