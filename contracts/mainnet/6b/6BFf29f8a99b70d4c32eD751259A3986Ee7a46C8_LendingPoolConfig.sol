// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPoolConfig is Ownable {
  /* ========== STATE VARIABLES ========== */

  // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
  uint256 public baseRate;
  // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
  uint256 public multiplier;
  // Multiplier after hitting a specified utilization point (kink2) in 1e18
  uint256 public jumpMultiplier;
  // Utilization point at which the interest rate is fixed in 1e18
  uint256 public kink1;
  // Utilization point at which the jump multiplier is applied in 1e18
  uint256 public kink2;

  /* ========== MAPPINGS ========== */

  // Mapping of approved keepers
  mapping(address => bool) public keepers;

  /* ========== EVENTS ========== */

  event UpdateInterestRateModel(
    uint256 baseRate,
    uint256 multiplier,
    uint256 jumpMultiplier,
    uint256 kink1,
    uint256 kink2
  );
  event UpdateKeeper(address _keeper, bool _status);

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant SECONDS_PER_YEAR = 365 days;

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved addresses for keepers
  */
  modifier onlyKeeper() {
    require(keepers[msg.sender], "Keeper not approved");
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _baseRate // Base interest rate when utilization rate is 0 in 1e18
    * @param _multiplier // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    * @param _jumpMultiplier // Multiplier after hitting a specified utilization point (kink2) in 1e18
    * @param _kink1 // Utilization point at which the interest rate is fixed in 1e18
    * @param _kink2 // Utilization point at which the jump multiplier is applied in 1e18
  */
  constructor(
    uint256 _baseRate,
    uint256 _multiplier,
    uint256 _jumpMultiplier,
    uint256 _kink1,
    uint256 _kink2
  ) {
      keepers[msg.sender] = true;
      updateInterestRateModel(_baseRate, _multiplier, _jumpMultiplier, _kink1, _kink2);
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Return the interest rate (APR) based on the utilization rate
    * @param _debt Total borrowed amount
    * @param _floating Total available liquidity
    * @return rate Current interest rate in annual percentage return in 1e18
  */
  function interestRateAPR(uint256 _debt, uint256 _floating) external view returns (uint256) {
    return _calculateInterestRate(_debt, _floating);
  }

  /**
    * Return the interest rate based on the utilization rate, per second
    * @param _debt Total borrowed amount
    * @param _floating Total available liquidity
    * @return ratePerSecond Current interest rate per second in 1e18
  */
  function interestRatePerSecond(uint256 _debt, uint256 _floating) external view returns (uint256) {
    return _calculateInterestRate(_debt, _floating) / SECONDS_PER_YEAR;
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Return the interest rate based on the utilization rate
    * @param _debt Total borrowed amount
    * @param _floating Total available liquidity
    * @return rate Current interest rate in 1e18
  */
  function _calculateInterestRate(uint256 _debt, uint256 _floating) internal view returns (uint256) {
    if (_debt == 0 && _floating == 0) return 0;

    uint256 total = _debt + _floating;
    uint256 utilizationRate = _debt * SAFE_MULTIPLIER / total;

    // If utilization above kink2, return a higher interest rate
    // (base + rate + excess utilization above kink 2 * jumpMultiplier)
    if (utilizationRate > kink2) {
      return baseRate + (kink1 * multiplier / SAFE_MULTIPLIER)
                      + ((utilizationRate - kink2) * jumpMultiplier / SAFE_MULTIPLIER);
    }

    // If utilization between kink1 and kink2, rates are flat
    if (kink1 < utilizationRate && utilizationRate <= kink2) {
      return baseRate + (kink1 * multiplier / SAFE_MULTIPLIER);
    }

    // If utilization below kink1, calculate borrow rate for slope up to kink 1
    return baseRate + (utilizationRate * multiplier / SAFE_MULTIPLIER);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
    * Updates lending pool interest rate model variables, callable only by owner
    @param _baseRate // Base interest rate when utilization rate is 0 in 1e18
    @param _multiplier // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    @param _jumpMultiplier // Multiplier after hitting a specified utilization point (kink2) in 1e18
    @param _kink1 // Utilization point at which the interest rate is fixed in 1e18
    @param _kink2 // Utilization point at which the jump multiplier is applied in 1e18
  */
  function updateInterestRateModel(
    uint256 _baseRate,
    uint256 _multiplier,
    uint256 _jumpMultiplier,
    uint256 _kink1,
    uint256 _kink2
  ) public onlyKeeper {
    baseRate = _baseRate;
    multiplier = _multiplier;
    jumpMultiplier = _jumpMultiplier;
    kink1 = _kink1;
    kink2 = _kink2;

    emit UpdateInterestRateModel(baseRate, multiplier, jumpMultiplier, kink1, kink2);
  }

  /**
    * Approve or revoke address to be a keeper for this vault
    * @param _keeper Keeper address
    * @param _approval Boolean to approve keeper or not
  */
  function updateKeeper(address _keeper, bool _approval) external onlyOwner {
    require(_keeper != address(0), "Invalid address");
    keepers[_keeper] = _approval;

    emit UpdateKeeper(_keeper, _approval);
  }
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