pragma solidity =0.8.19;

import {Math} from "@zelt-src/util/Math.sol";

/// @notice two rate storage slots per rate limit
struct RateLimitMidPoint {
    //// -------------------------------------------- ////
    //// ------------------ SLOT 0 ------------------ ////
    //// -------------------------------------------- ////
    /// @notice the rate per second for this contract
    uint128 rateLimitPerSecond;
    /// @notice the cap of the buffer that can be used at once
    uint112 bufferCap;
    //// -------------------------------------------- ////
    //// ------------------ SLOT 1 ------------------ ////
    //// -------------------------------------------- ////
    /// @notice the last time the buffer was used by the contract
    uint32 lastBufferUsedTime;
    /// @notice the buffer at the timestamp of lastBufferUsedTime
    uint112 bufferStored;
    /// @notice the mid point of the buffer
    uint112 midPoint;
}

/// @title abstract contract for putting a rate limit on how fast a contract
/// can perform an action e.g. Minting
/// @author Elliot Friedman
library RateLimitMidpointCommonLibrary {
    /// @notice event emitted when buffer cap is updated
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);

    /// @notice event emitted when rate limit per second is updated
    event RateLimitPerSecondUpdate(
        uint256 oldRateLimitPerSecond,
        uint256 newRateLimitPerSecond
    );

    /// @notice the amount of action available before hitting the rate limit
    /// @dev replenishes at rateLimitPerSecond per second back to midPoint
    /// @param limit pointer to the rate limit object
    function buffer(
        RateLimitMidPoint storage limit
    ) public view returns (uint256) {
        uint256 elapsed;
        unchecked {
            elapsed = uint32(block.timestamp) - limit.lastBufferUsedTime;
        }

        uint256 accrued = uint256(limit.rateLimitPerSecond) * elapsed;
        if (limit.bufferStored < limit.midPoint) {
            return
                Math.min(
                    uint256(limit.bufferStored) + accrued,
                    uint256(limit.midPoint)
                );
        } else if (limit.bufferStored > limit.midPoint) {
            /// past midpoint so subtract accrued off bufferStored back down to midpoint

            /// second part of if statement will not be evaluated if first part is true
            if (
                accrued > limit.bufferStored ||
                limit.bufferStored - accrued < limit.midPoint
            ) {
                /// if accrued is more than buffer stored, subtracting will underflow,
                /// and we are at the midpoint, so return that
                return limit.midPoint;
            } else {
                return limit.bufferStored - accrued;
            }
        } else {
            return limit.bufferStored; /// no change
        }
    }

    /// @notice syncs the buffer to the current time
    /// @dev should be called before any action that
    /// updates buffer cap or rate limit per second
    /// @param limit pointer to the rate limit object
    function sync(RateLimitMidPoint storage limit) internal {
        uint112 newBuffer = uint112(buffer(limit));
        uint32 blockTimestamp = uint32(block.timestamp);

        limit.lastBufferUsedTime = blockTimestamp;
        limit.bufferStored = newBuffer;
    }

    /// @notice set the rate limit per second
    /// @param limit pointer to the rate limit object
    /// @param newRateLimitPerSecond the new rate limit per second
    function setRateLimitPerSecond(
        RateLimitMidPoint storage limit,
        uint128 newRateLimitPerSecond
    ) internal {
        sync(limit);
        uint256 oldRateLimitPerSecond = limit.rateLimitPerSecond;
        limit.rateLimitPerSecond = newRateLimitPerSecond;

        emit RateLimitPerSecondUpdate(
            oldRateLimitPerSecond,
            newRateLimitPerSecond
        );
    }

    /// @notice set the buffer cap, but first sync to accrue all rate limits accrued
    /// @param limit pointer to the rate limit object
    /// @param newBufferCap the new buffer cap to set
    function setBufferCap(
        RateLimitMidPoint storage limit,
        uint112 newBufferCap
    ) internal {
        sync(limit);

        uint256 oldBufferCap = limit.bufferCap;
        limit.bufferCap = newBufferCap;
        limit.midPoint = uint112(newBufferCap / 2);

        /// if buffer stored is gt buffer cap, then we need set buffer stored to buffer cap
        if (limit.bufferStored > newBufferCap) {
            limit.bufferStored = newBufferCap;
        }

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }
}

pragma solidity =0.8.19;

/// @author Elliot Friedman
library Math {
    /// @notice return the smallest of two numbers
    /// @param a first number
    /// @param b second number
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? b : a;
    }
}