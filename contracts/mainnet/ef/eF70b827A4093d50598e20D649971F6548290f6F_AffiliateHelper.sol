// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../libraries/Math.sol";
import "../libraries/SafeCast.sol";

/// @title Specific tools for Affiliate rewards calc
library AffiliateHelper {
    using SafeCast for uint256;

    struct Contribution {
        uint128[2] payouts;
        uint128 totalNetBets;
    }
    // affiliate -> conditionId -> Contribution
    struct Contributions {
        mapping(address => mapping(uint256 => Contribution)) map;
    }
    // affiliate -> conditionIds
    struct ContributedConditionIds {
        mapping(address => uint256[]) map;
    }
    // conditionId -> total contribution to profit of beneficial affiliates for each outcome
    struct AffiliatedProfits {
        mapping(uint256 => uint128[2]) map;
    }

    /**
     * @notice Clear information about contribution to profit of beneficial affiliates for
     *         outcome `outId` of condition `conditionId`.
     */
    function delAffiliatedProfitOutcome(
        AffiliatedProfits storage _affiliatedProfits,
        uint256 conditionId,
        uint256 outId
    ) public {
        delete _affiliatedProfits.map[conditionId][outId];
    }

    /**
     * @notice Clear information about contribution to profit of beneficial affiliates
     *         for each outcome of condition `conditionId`.
     */
    function delAffiliatedProfit(
        AffiliatedProfits storage _affiliatedProfits,
        uint256 conditionId
    ) public {
        delete _affiliatedProfits.map[conditionId];
    }

    /**
     * @notice Add information about the bet made from an affiliate.
     * @param  affiliate address indicated as an affiliate when placing bet
     * @param  conditionId the match or condition ID
     * @param  betAmount amount of tokens is bet from the affiliate
     * @param  payout possible bet winnings
     * @param  outcomeIndex index of predicted outcome
     */
    function updateContribution(
        Contributions storage _contributions,
        ContributedConditionIds storage _contributedConditionIds,
        AffiliatedProfits storage _affiliatedProfits,
        address affiliate,
        uint256 conditionId,
        uint128 betAmount,
        uint128 payout,
        uint256 outcomeIndex
    ) public {
        Contribution storage contribution = _contributions.map[affiliate][
            conditionId
        ];
        Contribution memory contribution_ = contribution;

        if (contribution_.totalNetBets == 0)
            _contributedConditionIds.map[affiliate].push(conditionId);

        uint128[2] storage affiliateProfits = _affiliatedProfits.map[
            conditionId
        ];
        uint256 oldProfit;
        uint256 newProfit;
        for (uint256 i = 0; i < 2; i++) {
            oldProfit = Math.diffOrZero(
                contribution_.totalNetBets,
                contribution_.payouts[i]
            );
            newProfit = Math.diffOrZero(
                contribution_.totalNetBets + betAmount,
                contribution_.payouts[i] + (i == outcomeIndex ? payout : 0)
            );

            if (newProfit > oldProfit)
                affiliateProfits[i] += (newProfit - oldProfit).toUint128();
            else if (newProfit < oldProfit)
                affiliateProfits[i] -= (oldProfit - newProfit).toUint128();
        }
        contribution.totalNetBets += betAmount;
        contribution.payouts[outcomeIndex] += payout;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Common math tools
library Math {
    /**
     * @notice Get non-negative difference of `minuend` and `subtracted`.
     * @return `minuend - subtracted`if it is non-negative or 0
     */
    function diffOrZero(uint256 minuend, uint256 subtracted)
        internal
        pure
        returns (uint256)
    {
        return minuend > subtracted ? minuend - subtracted : 0;
    }

    /**
     * @notice Get max of `a` and `b`.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice Get min of `a` and `b`.
     */
    function min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library SafeCast {
    enum Type {
        BYTES32,
        INT128,
        UINT64,
        UINT128
    }
    error SafeCastError(Type to);

    function toBytes32(string calldata value) internal pure returns (bytes32) {
        bytes memory value_ = bytes(value);
        if (value_.length > 32) revert SafeCastError(Type.BYTES32);
        return bytes32(value_);
    }

    function toInt128(uint128 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max))
            revert SafeCastError(Type.INT128);
        return int128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert SafeCastError(Type.UINT64);
        return uint64(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert SafeCastError(Type.UINT128);
        return uint128(value);
    }
}