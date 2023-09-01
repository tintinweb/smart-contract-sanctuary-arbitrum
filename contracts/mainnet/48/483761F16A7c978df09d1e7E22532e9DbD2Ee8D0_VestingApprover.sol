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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ITransferApprover {
    function checkTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ITransferApprover.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/**
 * @title VestingApprover
 */
contract VestingApprover is ITransferApprover, Ownable {
    IERC20Metadata public sweepr;

    // Structure for the vesting schedule
    struct VestingSchedule {
        // beneficiary address
        address beneficiary;
        // Cliff time when vesting begins
        uint256 startTime;
        // The amount of time for linear vesting
        uint256 vestingTime;
        // The number of tokens that are controlled by the vesting schedule
        uint256 vestingAmount;
    }

    // Vesting Schedules
    mapping(address => VestingSchedule) public vestingSchedules;
    // Beneficiary Addresses
    address[] public beneficiaries;

    uint256 internal constant PRECISION = 1e10;

    /* ========== EVENTS ========== */
    event ScheduleAdded(
        address indexed beneficiary,
        uint256 startTime,
        uint256 vestingtime,
        uint256 vestingAmount
    );
    event ScheduleRemoved(address indexed beneficiary);
    event Whitelisted(address indexed account);
    event UnWhitelisted(address indexed account);
    event StateSet(bool state);

    /* ========== Errors ========== */
    error NotSweepr();
    error ZeroAddressDetected();
    error ZeroAmountDetected();

    /* ========== MODIFIERS ========== */
    modifier onlySweepr() {
        if (msg.sender != address(sweepr)) revert NotSweepr();
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(address sweeprAddress) {
        sweepr = IERC20Metadata(sweeprAddress);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary
     * @param _beneficiary address of the beneficiary
     * @param _startTime start time of the vesting period
     * @param _vestingTime amount of time in seconds for linear vesting
     * @param _vestingAmount amount of tokens that are controlled by the vesting schedule
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _startTime,
        uint256 _vestingTime,
        uint256 _vestingAmount
    ) external onlyOwner {
        if (_beneficiary == address(0)) revert ZeroAddressDetected();
        if (_startTime == 0 || _vestingTime == 0 || _vestingAmount == 0)
            revert ZeroAmountDetected();

        vestingSchedules[_beneficiary] = VestingSchedule(
            _beneficiary,
            _startTime,
            _vestingTime,
            _vestingAmount
        );

        beneficiaries.push(_beneficiary);
        emit ScheduleAdded(
            _beneficiary,
            _startTime,
            _vestingTime,
            _vestingAmount
        );
    }

    /**
     * @notice Remove vesting schedule
     * @param itemIndex index to remove
     */
    function removeSchedule(uint256 itemIndex) external onlyOwner {
        address beneficiary = beneficiaries[itemIndex];
        delete vestingSchedules[beneficiary];

        beneficiaries[itemIndex] = beneficiaries[beneficiaries.length - 1];
        beneficiaries.pop();

        emit ScheduleRemoved(beneficiary);
    }

    /**
     * @notice Returns token transferability
     * @param from sender address
     * @param to beneficiary address
     * @param amount transfer amount
     * @return (bool) true - allowance, false - denial
     */
    function checkTransfer(
        address from,
        address to,
        uint256 amount
    ) external view onlySweepr returns (bool) {
        // allow minting & burning & tansfers from sender not in vesting list
        if (
            from == address(0) ||
            to == address(0) ||
            from != vestingSchedules[from].beneficiary
        ) return true;

        uint256 senderBalance = sweepr.balanceOf(from);
        if (senderBalance < amount) return false;

        uint256 lockedAmount = getLockedAmount(from);
        if (senderBalance - amount < lockedAmount) return false;

        return true;
    }

    /**
     * @dev Computes the locked amount of tokens for a vesting schedule.
     * @return the locked amount of tokens
     */
    function _computeLockedAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;

        // If the current time is before the cliff, locked amount = vesting amount.
        if (currentTime < vestingSchedule.startTime) {
            return vestingSchedule.vestingAmount;
        } else if (
            currentTime >=
            vestingSchedule.startTime + vestingSchedule.vestingTime
        ) {
            // If the current time is after the vesting period, all tokens are transferaable,
            return 0;
        } else {
            // Compute the amount of tokens that are locked.
            uint256 lockedAmount = vestingSchedule.vestingAmount *
                (PRECISION -
                    ((currentTime - vestingSchedule.startTime) * PRECISION) /
                    vestingSchedule.vestingTime);
            return lockedAmount / PRECISION;
        }
    }

    /**
     * @dev Returns the number of vesting schedules
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() external view returns (uint256) {
        return beneficiaries.length;
    }

    /**
     * @notice Get the locked amount of tokens for beneficiary
     * @return the locked amount
     */
    function getLockedAmount(address beneficiary)
        public
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[beneficiary];
        return _computeLockedAmount(vestingSchedule);
    }
}