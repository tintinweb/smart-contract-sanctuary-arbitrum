// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library Errors {
    error CallerNotAdmin();
    error CallerNotOwner();
    error ZeroAmountNotValid();
    error ZeroAddressNotValid();
    error InvalidTokenFeePercentage();
    error InvalidTgePercentage();
    error InvalidGalaxyPoolProportion();
    error InvalidEarlyAccessProportion();
    error InvalidTime();
    error InvalidSigner();
    error InvalidClaimableAmount();
    error NotInWhaleList();
    error NotInInvestorList();
    error NotEnoughAllowance();
    error NotFunded();
    error AlreadyClaimTotalAmount();
    error TimeOutToBuyIDOToken();

    error ExceedMaxPurchaseAmountForUser();
    error ExceedPoolPurchaseAmountForUser();
    error ExceedTotalRaiseAmount();
    error ExceedMaxPurchaseAmountForKYCUser();
    error ExceedMaxPurchaseAmountForNonKYCUser();
    error ExceedMaxPurchaseAmountForEarlyAccess();

    error NotAllowedToClaimIDOToken();
    error NotAllowedToClaimTokenFee();
    error NotAllowedToDoAfterTGEDate();
    error NotAllowedToClaimParticipationFee();
    error NotAllowedToWithdrawPurchasedAmount();
    error NotAllowedToFundAfterTGEDate();
    error NotAllowedToAllowInvestorToClaim();
    error NotAllowedToClaimPurchaseToken();
    error NotAllowedToTransferBeforeTGEDate();
    error NotAllowedToTransferBeforeLockupTime();
    error NotAllowedToTransferBeforeCommunityClose();
    error NotAllowedToDoAfterEmergencyCancelled();
    error NotAllowedToCancelAfterLockupTime();
    error NotAllowedToExceedTotalRaiseAmount();
    error NotAllowedToFundBeforeCommunityTime();

    error GalaxyParticipationFeePercentageNotInRange();
    error CrowdFundingParticipationFeePercentageNotInRange();

    error NotAllowedToAdjustTGEDateExceedsAttempts();

    error MaxPurchaseForKYCUserNotValid();

    error PoolIsAlreadyFunded();

    error NotAllowedToAdjustTGEDateTooFar();

    error AlreadyPrivateFunded();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Errors} from "../helpers/Errors.sol";

library PoolLogic {
    /// @dev Percentage denominator
    uint16 public constant PERCENTAGE_DENOMINATOR = 10000;

    enum PoolType {
        GALAXY_POOL,
        EARLY_ACCESS,
        NORMAL_ACCESS
    }

    /**
     * @dev Calculate fee when investor buy token
     * @param _purchaseAmount Purchase amount of investor
     * @param _participationFeePercentage Fee percentage when buying token
     * @return Return amount of fee when investor buy token
     */
    function calculateParticipantFee(
        uint _purchaseAmount,
        uint _participationFeePercentage
    ) external pure returns (uint) {
        if (_participationFeePercentage == 0) return 0;
        return
            (_purchaseAmount * _participationFeePercentage) /
            PERCENTAGE_DENOMINATOR;
    }

    /**
     * @dev Check whether or not an amount greater than 0
     * @param _amount An amount
     */
    function validAmount(uint _amount) public pure {
        if (_amount == 0) {
            revert Errors.ZeroAmountNotValid();
        }
    }

    /**
     * @dev Check whether or not an address is zero address
     * @param _address An address
     */
    function validAddress(address _address) public pure {
        if (_address == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
    }

    /**
     * @dev verify information of pool
     * @param addrs Array of address includes:
     * - address of IDO token,
     * - address of purchase token
     * @param uints Array of pool information includes:
     * - max purchase amount for KYC user,
     * - max purchase amount for Not KYC user,
     * - token fee percentage,
     * - galaxy participation fee percentage,
     * - crowdfunding participation fee percentage,
     * - galaxy pool proportion,
     * - early access proportion,
     * - total raise amount,
     * - whale open time,
     * - whale duration,
     * - community duration,
     * - rate of IDO token (based on README formula),
     * - decimal of IDO token (based on README formula, is different from decimals in contract of IDO token),
     * - TGE date,
     * - TGE percentage,
     * - vesting cliff,
     * - vesting frequency,
     * - number of vesting release
     */
    function verifyPoolInfo(
        address[2] memory addrs,
        uint[19] memory uints
    ) external pure {
        validAddress(addrs[1]); // purchaseToken

        // tokenFeePercentage
        if (uints[2] > PERCENTAGE_DENOMINATOR) {
            revert Errors.InvalidTokenFeePercentage();
        }

        // galaxyPoolProportion
        validAmount(uints[5]);
        if (uints[5] >= PERCENTAGE_DENOMINATOR) {
            revert Errors.InvalidGalaxyPoolProportion();
        }

        // earlyAccessProportion
        if (uints[6] >= PERCENTAGE_DENOMINATOR) {
            revert Errors.InvalidEarlyAccessProportion();
        }

        if (uints[8]+uints[9]+uints[10] > uints[13]) {
            revert Errors.InvalidTime();
        }

        // totalRaiseAmount
        validAmount(uints[7]);
    }
}