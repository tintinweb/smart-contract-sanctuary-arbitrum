pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";

contract JumpRateInterestModel is Ownable, IInterestRateModel {
    uint256 constant PRECISION = 1e10;
    /// @notice default rate on anycase
    uint256 public baseRate;
    /// @notice the rate of increase interest rate by utilization (scaled by 1e10)
    uint256 public baseMultiplierPerInterval;
    /// @notice the multiplier after hitting a specified point
    uint256 public jumpMultiplierPerInterval;
    /// @notice the utilization point at which jump multipler is applied (scaled by 1e10)
    uint256 public kink;

    constructor(
        uint256 _baseRate,
        uint256 _baseMultiplierPerInterval,
        uint256 _jumpMultiplierPerInterval,
        uint256 _kink
    ) {
        _setParams(_baseRate, _baseMultiplierPerInterval, _jumpMultiplierPerInterval, _kink);
    }

    function getBorrowRatePerInterval(uint256 _totalCash, uint256 _reserved) external view returns (uint256) {
        uint256 util = _reserved * PRECISION / _totalCash;
        if (util < kink) {
            return baseRate + baseMultiplierPerInterval * util / PRECISION;
        }
        uint256 normalRate = baseRate + baseMultiplierPerInterval * kink / PRECISION;
        uint256 exessRate = (util - kink) * jumpMultiplierPerInterval / PRECISION;
        return normalRate + exessRate;
    }

    function update(
        uint256 _baseRate,
        uint256 _baseMultiplierPerInterval,
        uint256 _jumpMultiplierPerInterval,
        uint256 _kink
    ) external onlyOwner {
        _setParams(_baseRate, _baseMultiplierPerInterval, _jumpMultiplierPerInterval, _kink);
    }

    function _setParams(
        uint256 _baseRate,
        uint256 _baseMultiplierPerInterval,
        uint256 _jumpMultiplierPerInterval,
        uint256 _kink
    ) internal {
        baseRate = _baseRate;
        baseMultiplierPerInterval = _baseMultiplierPerInterval;
        jumpMultiplierPerInterval = _jumpMultiplierPerInterval;
        kink = _kink;

        emit NewParams(_baseRate, _baseMultiplierPerInterval, _jumpMultiplierPerInterval, _kink);
    }

    event NewParams(
        uint256 baseRate, uint256 baseMultiplierPerInterval, uint256 jumpMultiplierPerInterval, uint256 kink
    );
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

pragma solidity >= 0.8.0;

interface IInterestRateModel {
    /// @notice calculate interest rate per accrual interval
    /// @param _cash The total pooled amount
    /// @param _utilization The total amount of token reserved as collteral
    /// @return borrow rate per interval, scaled by Constants.PRECISION (1e10)
    function getBorrowRatePerInterval(uint256 _cash, uint256 _utilization) external view returns (uint256);
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