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

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IDiscounter } from "../interfaces/IDiscounter.sol";

/** @notice Computes net present value of future yield based on a fixed discount rate.

    Owner role sets projected daily yield rate, and max days of that
    projection which can be sold.
*/
contract Discounter is IDiscounter, Ownable {
    uint256 public immutable rate;
    uint256 public immutable decimals;
    uint256 public daily;
    uint256 public maxDays;

    uint256 public immutable discountPeriod;

    uint256 public constant RATE_PRECISION = 1_000_000;
    uint256 public constant MAX_DAYS_LIMIT = 8 * 360; // 8 years

    // Limits the number of discount periods for computations. Limiting that
    // ratio to 96 keeps gas spending within a reasonable range.
    uint256 public constant DISCOUNT_PERIODS_LIMIT = 96;

    event Daily(uint256 daily);
    event MaxDays(uint256 maxDays);

    /// @notice Create a Discounter
    /// @param daily_ Projected daily yield rate per token.
    /// @param rate_ Daily discount rate, as fraction of `RATE_PRECISION`.
    /// @param decimals_ Decimals for the daily yield rate projection.
    constructor(uint256 daily_,
                uint256 rate_,
                uint256 maxDays_,
                uint256 decimals_,
                uint256 discountPeriod_) {

        require(discountPeriod_ >= 1 days, "DS: discount period too small");
        require(discountPeriod_ % 1 days == 0, "DS: must be factor of days");

        daily = daily_;
        decimals = decimals_;
        rate = rate_;

        discountPeriod = discountPeriod_;

        setMaxDays(maxDays_);
    }

    /// @notice Set the projected daily yield rate.
    /// @param daily_ New projected daily yield rate.
    function setDaily(uint256 daily_) external onlyOwner {
        daily = daily_;

        emit Daily(daily);
    }

    /// @notice Set the max days of projected future yield to sell.
    /// @param maxDays_ New max days of projected future yield to sell.
    function setMaxDays(uint256 maxDays_) public onlyOwner {
        require(maxDays_ <= MAX_DAYS_LIMIT, "DS: max days limit");
        require(maxDays_ / (discountPeriod / 1 days) <= DISCOUNT_PERIODS_LIMIT, "DS: discount periods limit");

        maxDays = maxDays_;

        emit MaxDays(maxDays);
    }

    /// @notice Compute the net present value of stream of future yield.
    /// @param generator Amount of yield generating tokens.
    /// @param yield Amount of future yield to be locked.
    function discounted(uint256 generator, uint256 yield) external override view returns (uint256) {
        uint256 top = RATE_PRECISION - rate;
        uint256 sum = 0;
        uint256 npv = 0;
        for (uint256 i = 1; i < maxDays && sum < yield; i += (discountPeriod / 1 days)) {
            uint256 nominal_ = (generator * daily * (discountPeriod / 1 days)) / (10**decimals);
            if (nominal_ + sum > yield) {
                nominal_ = yield - sum;
            }
            uint256 pv_ = (nominal_ * top) / RATE_PRECISION;
            sum += nominal_;
            npv += pv_;
            top = (top * (RATE_PRECISION - rate)) / RATE_PRECISION;
        }
        return npv;
    }


    /// @notice Compute value of nominal payment shifted forward some days, relative to a starting amount of NPV.
    /// @param numSeconds Number of seconds in the future to delay that nominal payment.
    /// @param npv Starting NPV of the nominal payment we will receive.
    /// @return NPV of that nominal payment after the delay.
    function shiftForward(uint256 numSeconds, uint256 npv) external override view returns (uint256) {
        uint256 numPeriods = numSeconds / discountPeriod;
        uint256 acc = npv * 1e9;
        for (uint256 i = 0; i < numPeriods; i++) {
            acc = acc * RATE_PRECISION / (RATE_PRECISION - rate);
        }
        return acc / 1e9;
    }

    /// @notice Compute value of nominal payment shifted backward some days, relative to a starting amount of NPV.
    /// @param numSeconds Number of seconds in the future to delay that nominal payment.
    /// @param npv Starting NPV of the nominal payment we will receive.
    /// @return NPV of that nominal payment after the delay.
    function shiftBackward(uint256 numSeconds, uint256 npv) external override view returns (uint256) {
        uint256 numPeriods = numSeconds / discountPeriod;
        uint256 acc = npv * 1e9;
        for (uint256 i = 0; i < numPeriods; i++) {
            acc = acc * (RATE_PRECISION - rate) / RATE_PRECISION;
        }
        return acc / 1e9;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDiscounter {
    function discountPeriod() external view returns (uint256);

    function setDaily(uint256 daily) external;
    function setMaxDays(uint256 maxDays) external;

    function discounted(uint256 generator, uint256 yield) external view returns (uint256);
    function shiftForward(uint256 numSeconds, uint256 npv) external view returns (uint256);
    function shiftBackward(uint256 numSeconds, uint256 npv) external view returns (uint256);
}