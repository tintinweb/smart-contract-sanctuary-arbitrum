// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IFactorScale } from '../interfaces/IFactorScale.sol';

interface IWrapperVault {
    function redeemRewards(address user) external returns (uint256[] memory);
}

contract MultipleClaimRewardsAdapter {
    error VaultNotActive();

    event ClaimRewards(address vault, address user, uint256[] results);

    address private immutable scale;

    constructor(address _scale) {
        scale = _scale;
    }

    function claimMultipleRewards(address[] calldata vaults, address user) external {
        for (uint i = 0; i < vaults.length; i++) {
            if (!IFactorScale(scale).isVaultActive(vaults[i])) revert VaultNotActive();
            uint256[] memory results = IWrapperVault(vaults[i]).redeemRewards(user);
            emit ClaimRewards(vaults[i], user, results);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/VeBalanceLib.sol";

interface IFactorScale {

    event AddVault(uint64 indexed chainId, address indexed vault);

    event RemoveVault(uint64 indexed chainId, address indexed vault);

    event Vote(address indexed user, address indexed vault, uint64 weight, VeBalance vote);

    event VaultVoteChange(address indexed vault, VeBalance vote);

    event SetFctrPerSec(uint256 newFctrPerSec);

    event BroadcastResults(
        uint64 indexed chainId,
        uint128 indexed wTime,
        uint128 totalFctrPerSec
    );

    function applyVaultSlopeChanges(address vault) external;

    function getWeekData(uint128 wTime, address[] calldata vaults)
        external
        view
        returns (
            bool isEpochFinalized,
            uint128 totalVotes,
            uint128[] memory vaultVotes
        );

    function getVaultTotalVoteAt(address vault, uint128 wTime) external view returns (uint128);

    function finalizeEpoch() external;

    function getBroadcastResultFee(uint64 chainId) external view returns (uint256);

    function broadcastResults(uint64 chainId) external payable;

    function isVaultActive(address vault) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @notice This library is a modified version of Pendle's VeBalanceLib.sol:
 * https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts/LiquidityMining
 * /libraries/VeBalanceLib.sol
 *
 */

struct VeBalance {
    uint128 bias;
    uint128 slope;
}

struct LockedPosition {
    uint128 amount;
    uint128 expiry;
}

library VeBalanceLib {
    error VEZeroSlope(uint128 bias, uint128 slope);
    error VEOverflowSlope(uint256 slope);

    uint128 internal constant MAX_LOCK_TIME = 104 weeks;
    uint256 internal constant USER_VOTE_MAX_WEIGHT = 10 ** 18;

    function add(VeBalance memory a, VeBalance memory b) internal pure returns (VeBalance memory res) {
        res.bias = a.bias + b.bias;
        res.slope = a.slope + b.slope;
    }

    function sub(VeBalance memory a, VeBalance memory b) internal pure returns (VeBalance memory res) {
        res.bias = a.bias - b.bias;
        res.slope = a.slope - b.slope;
    }

    function sub(VeBalance memory a, uint128 slope, uint128 expiry) internal pure returns (VeBalance memory res) {
        res.slope = a.slope - slope;
        res.bias = a.bias - slope * expiry;
    }

    function isExpired(VeBalance memory a) internal view returns (bool) {
        return a.slope * uint128(block.timestamp) >= a.bias;
    }

    function getCurrentValue(VeBalance memory a) internal view returns (uint128) {
        if (isExpired(a)) return 0;
        return getValueAt(a, uint128(block.timestamp));
    }

    function getValueAt(VeBalance memory a, uint128 t) internal pure returns (uint128) {
        if (a.slope * t > a.bias) {
            return 0;
        }
        return a.bias - a.slope * t;
    }

    function getExpiry(VeBalance memory a) internal pure returns (uint128) {
        if (a.slope == 0) revert VEZeroSlope(a.bias, a.slope);
        return a.bias / a.slope;
    }

    function convertToVeBalance(LockedPosition memory position) internal pure returns (VeBalance memory res) {
        res.slope = position.amount / MAX_LOCK_TIME;
        res.bias = res.slope * position.expiry;
    }

    function convertToVeBalance(
        LockedPosition memory position,
        uint256 weight
    ) internal pure returns (VeBalance memory res) {
        uint256 slope = (position.amount * weight) / MAX_LOCK_TIME / USER_VOTE_MAX_WEIGHT;
        if (slope > type(uint128).max) revert VEOverflowSlope(slope);
        res.slope = uint128(slope);
        res.bias = res.slope * position.expiry;
    }

    function convertToVeBalance(uint128 amount, uint128 expiry) internal pure returns (uint128, uint128) {
        VeBalance memory balance = convertToVeBalance(LockedPosition(amount, expiry));
        return (balance.bias, balance.slope);
    }
}