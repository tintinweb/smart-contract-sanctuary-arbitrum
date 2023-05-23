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

import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

/** @notice YieldData keeps track of historical average yields on a periodic
    basis. It uses this data to return the overall average yield for a range
    of time in the `yieldPerTokenPerSlock` method. This method is O(N) on the
    number of epochs recorded. Therefore, to prevent excessive gas costs, the
    interval should be set such that N does not exceed around a thousand. An
    interval of 10 days will stay below this limit for a few decades. Keep in
    mind, though, that a larger interval reduces accuracy.

    Owner role can set the writer role up to one time.
*/
contract YieldData is Ownable {
    struct Epoch {
        uint256 tokens;
        uint256 yield;
        uint256 yieldPerToken;
        uint128 blockTimestamp;
        uint128 epochSeconds;
    }

    uint256 public constant PRECISION_FACTOR = 10**18;

    /** @notice Writer role is permitted to write new data points. This
        role can only be assigned once, and it is expected to be set to
        a YieldSlice contract, which writes data in a deterministic
        fashion.
     */
    address public writer;

    uint128 public immutable interval;

    Epoch[] public epochs;
    uint128 public epochIndex;

    event SetWriter(address indexed who);

    /// @notice Create a YieldData.
    /// @param interval_ Minimum size in seconds of each epoch.
    constructor(uint128 interval_) {
        interval = interval_;
        writer = address(0);
    }

    /// @notice Set the writer.
    /// @param writer_ The new writer.
    function setWriter(address writer_) external onlyOwner {
        require(writer_ != address(0), "YD: zero address");
        require(writer == address(0), "YD: only set once");
        writer = writer_;

        emit SetWriter(writer);
    }

    /// @notice Check if data is empty.
    /// @return True if the data is empty.
    function isEmpty() external view returns (bool) {
        return epochs.length == 0;
    }

    /// @notice Get the current epoch.
    /// @return The current epoch.
    function current() external view returns (Epoch memory) {
        return epochs[epochIndex];
    }

    function _record(uint256 tokens, uint256 yield) internal view returns
        (Epoch memory epochPush, Epoch memory epochSet) {

        if (epochs.length == 0) {
            epochPush = Epoch({
                blockTimestamp: uint128(block.timestamp),
                epochSeconds: 0,
                tokens: tokens,
                yield: yield,
                yieldPerToken: 0 });
        } else {
            Epoch memory c = epochs[epochIndex];

            uint128 epochSeconds = uint128(block.timestamp) - c.blockTimestamp - c.epochSeconds;
            uint256 delta = (yield - c.yield);

            c.yieldPerToken += c.tokens == 0 ? 0 : delta * PRECISION_FACTOR / c.tokens;
            c.epochSeconds += epochSeconds;

            if (c.epochSeconds >= interval) {
                epochPush = Epoch({
                    blockTimestamp: uint128(block.timestamp),
                    epochSeconds: 0,
                    tokens: tokens,
                    yield: yield,
                    yieldPerToken: 0 });
            } else {
                c.tokens = tokens;
            }

            c.yield = yield;
            epochSet = c;
        }
    }

    /// @notice Record new data.
    /// @param tokens Amount of generating tokens for this data point.
    /// @param yield Amount of yield generated for this data point. Cumulative and monotonically increasing.
    function record(uint256 tokens, uint256 yield) external {
        require(msg.sender == writer, "YD: only writer");

        (Epoch memory epochPush, Epoch memory epochSet) = _record(tokens, yield);

        if (epochSet.blockTimestamp != 0) {
            epochs[epochIndex] = epochSet;
        }
        if (epochPush.blockTimestamp != 0) {
            epochs.push(epochPush);
            epochIndex = uint128(epochs.length) - 1;
        }
    }

    function _find(uint128 blockTimestamp) internal view returns (uint256 result) {
        require(epochs.length > 0, "YD: no epochs");

        result = epochIndex;
        if (blockTimestamp >= epochs[epochIndex].blockTimestamp) return epochIndex;
        if (blockTimestamp <= epochs[0].blockTimestamp) return 0;

        uint256 i = epochs.length / 2;
        uint256 start = 0;
        uint256 end = epochs.length;
        while (true) {
            uint128 bn = epochs[i].blockTimestamp;
            if (blockTimestamp >= bn &&
                (i + 1 > epochIndex || blockTimestamp < epochs[i + 1].blockTimestamp)) {
                return i;
            }

            if (blockTimestamp > bn) {
                start = i + 1;
            } else {
                end = i;
            }
            i = (start + end) / 2;
        }
    }

    /// @notice Compute the yield per token per second for a time range. The first and final epoch in the time range are prorated, and therefore the resulting value is an approximation.
    /// @param start Timestamp indicating the start of the time range.
    /// @param end Timestmap indicating the end of the time range.
    /// @param tokens Optional, the amount of tokens locked. Can be 0.
    /// @param yield Optional, the amount of cumulative yield. Can be 0.
    /// @return Amount of yield per `PRECISION_FACTOR` amount of tokens per second.
    function yieldPerTokenPerSecond(uint128 start, uint128 end, uint256 tokens, uint256 yield) external view returns (uint256) {
        if (start == end) return 0;
        if (start == uint128(block.timestamp)) return 0;

        require(start < end, "YD: start must precede end");
        require(start < uint128(block.timestamp), "YD: start must be in the past");
        require(end <= uint128(block.timestamp), "YD: end must be in the past or current");

        uint256 index = _find(start);
        uint256 yieldPerToken;
        uint256 numSeconds;

        Epoch memory epochPush;
        Epoch memory epochSet;
        if (yield != 0) (epochPush, epochSet) = _record(tokens, yield);
        uint128 maxIndex = epochPush.blockTimestamp == 0 ? epochIndex : epochIndex + 1;

        while (true) {
            if (index > maxIndex) break;
            Epoch memory epoch;
            if (epochSet.blockTimestamp != 0 && index == epochIndex) {
                epoch = epochSet;
            } else {
                epoch = epochs[index];
            }

            ++index;

            uint256 epochSeconds = epoch.epochSeconds;
            if (epochSeconds == 0) break;

            if (start > epoch.blockTimestamp) {
                epochSeconds -= start - epoch.blockTimestamp;
            }
            if (end < epoch.blockTimestamp + epoch.epochSeconds) {
                epochSeconds -= epoch.blockTimestamp + epoch.epochSeconds - end;
            }

            uint256 incr = (epochSeconds * epoch.yieldPerToken) / epoch.epochSeconds;

            yieldPerToken += incr;
            numSeconds += epochSeconds;

            if (end < epoch.blockTimestamp + epoch.epochSeconds) break;
        }

        if (numSeconds == 0) return 0;

        return yieldPerToken / numSeconds;
    }
}