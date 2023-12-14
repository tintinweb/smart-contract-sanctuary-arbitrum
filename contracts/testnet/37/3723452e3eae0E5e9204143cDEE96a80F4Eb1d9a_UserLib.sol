// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library Constants {
    /// @notice Scattering protocol
    /// @dev fragment token amount of 1 NFT (with 18 decimals)
    uint256 public constant FLOOR_TOKEN_AMOUNT = 10_000 ether;
    /// @dev The minimum vip level required to use `proxy collection`
    uint8 public constant PROXY_COLLECTION_VIP_THRESHOLD = 3;

    /// @notice Rolling Bucket Constant Conf
    //    uint256 public constant BUCKET_SPAN_1 = 259199 seconds; // BUCKET_SPAN minus 1, used for rounding up
    //    uint256 public constant BUCKET_SPAN = 3 days;
    //    uint256 public constant MAX_LOCKING_BUCKET = 240;
    //    uint256 public constant MAX_LOCKING_PERIOD = 720 days; // MAX LOCKING BUCKET * BUCKET_SPAN

    /// @notice Auction Config
    uint256 public constant FREE_AUCTION_PERIOD = 24 hours;
    uint256 public constant AUCTION_INITIAL_PERIODS = 24 hours;
    uint256 public constant AUCTION_COMPLETE_GRACE_PERIODS = 2 days;
    /// @dev minimum bid per NFT when someone starts aution on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_MINIMUM_BID = 1000 ether;
    /// @dev minimum bid per NFT when someone starts aution on vault
    uint256 public constant AUCTION_ON_VAULT_MINIMUM_BID = 10000 ether;
    /// @dev admin fee charged per NFT when someone starts aution on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_SAFEBOX_COST = 0;
    /// @dev admin fee charged per NFT when owner starts aution on himself safebox
    uint256 public constant AUCTION_COST = 100 ether;

    /// @notice Raffle Config
    uint256 public constant RAFFLE_COST = 500 ether;
    uint256 public constant RAFFLE_COMPLETE_GRACE_PERIODS = 2 days;

    /// @notice Private offer Config
    uint256 public constant PRIVATE_OFFER_DURATION = 24 hours;
    uint256 public constant PRIVATE_OFFER_COMPLETE_GRACE_DURATION = 2 days;
    uint256 public constant PRIVATE_OFFER_COST = 0;
    uint256 public constant OFFER_FEE_RATE_BIPS = 200; // 2%

    uint256 public constant ADD_FREE_NFT_REWARD = 0;

    /// @notice Lock/Unlock config
    uint256 public constant USER_SAFEBOX_QUOTA_REFRESH_DURATION = 1 days;
    uint256 public constant USER_REDEMPTION_WAIVER_REFRESH_DURATION = 1 days;
    uint256 public constant VAULT_REDEMPTION_MAX_LOKING_RATIO = 80;

    /// @notice Activities Fee Rate

    /// @notice Fee rate used to distribute funds that collected from Auctions on expired safeboxes.
    /// these auction would be settled using credit token
    uint256 public constant FREE_AUCTION_FEE_RATE_BIPS = 2000; // 20%
    /// @notice Fee rate settled with credit token
    uint256 public constant CREDIT_FEE_RATE_BIPS = 150; // 2%
    /// @notice Fee rate settled with specified token
    uint256 public constant SPEC_FEE_RATE_BIPS = 300; // 3%
    /// @notice Fee rate settled with all other tokens
    uint256 public constant COMMON_FEE_RATE_BIPS = 500; // 5%

    //    uint256 public constant VIP_LEVEL_COUNT = 8;

    struct AuctionBidOption {
        uint256 extendDurationSecs;
        uint256 minimumRaisePct;
        //        uint256 vipLevel;
    }

    //    function getVipLockingBuckets(uint256 vipLevel) internal pure returns (uint256 buckets) {
    //        require(vipLevel < VIP_LEVEL_COUNT);
    //        assembly {
    //            switch vipLevel
    //            case 1 {
    //                buckets := 1
    //            }
    //            case 2 {
    //                buckets := 5
    //            }
    //            case 3 {
    //                buckets := 20
    //            }
    //            case 4 {
    //                buckets := 60
    //            }
    //            case 5 {
    //                buckets := 120
    //            }
    //            case 6 {
    //                buckets := 180
    //            }
    //            case 7 {
    //                buckets := MAX_LOCKING_BUCKET
    //            }
    //        }
    //    }

    //    function getVipLevel(uint256 totalCredit) internal pure returns (uint8) {
    //        if (totalCredit < 30_000 ether) {
    //            return 0;
    //        } else if (totalCredit < 100_000 ether) {
    //            return 1;
    //        } else if (totalCredit < 300_000 ether) {
    //            return 2;
    //        } else if (totalCredit < 1_000_000 ether) {
    //            return 3;
    //        } else if (totalCredit < 3_000_000 ether) {
    //            return 4;
    //        } else if (totalCredit < 10_000_000 ether) {
    //            return 5;
    //        } else if (totalCredit < 30_000_000 ether) {
    //            return 6;
    //        } else {
    //            return 7;
    //        }
    //    }

    //    function getVipBalanceRequirements(uint256 vipLevel) internal pure returns (uint256 required) {
    //        require(vipLevel < VIP_LEVEL_COUNT);
    //
    //        assembly {
    //            switch vipLevel
    //            case 1 {
    //                required := 30000
    //            }
    //            case 2 {
    //                required := 100000
    //            }
    //            case 3 {
    //                required := 300000
    //            }
    //            case 4 {
    //                required := 1000000
    //            }
    //            case 5 {
    //                required := 3000000
    //            }
    //            case 6 {
    //                required := 10000000
    //            }
    //            case 7 {
    //                required := 30000000
    //            }
    //        }
    //
    //        /// credit token should be scaled with 18 decimals(1 ether == 10**18)
    //        unchecked {
    //            return required * 1 ether;
    //        }
    //    }

    function getBidOption(uint256 idx) internal pure returns (AuctionBidOption memory) {
        require(idx < 4);
        AuctionBidOption[4] memory bidOptions = [
            AuctionBidOption({extendDurationSecs: 5 minutes, minimumRaisePct: 1}),
            AuctionBidOption({extendDurationSecs: 8 hours, minimumRaisePct: 10}),
            AuctionBidOption({extendDurationSecs: 16 hours, minimumRaisePct: 20}),
            AuctionBidOption({extendDurationSecs: 24 hours, minimumRaisePct: 40})
        ];
        return bidOptions[idx];
    }

    //    function raffleDurations(uint256 idx) internal pure returns (uint256 vipLevel, uint256 duration) {
    //        require(idx < 6);
    //
    //        vipLevel = idx;
    //        assembly {
    //            switch idx
    //            case 1 {
    //                duration := 1
    //            }
    //            case 2 {
    //                duration := 2
    //            }
    //            case 3 {
    //                duration := 3
    //            }
    //            case 4 {
    //                duration := 5
    //            }
    //            case 5 {
    //                duration := 7
    //            }
    //        }
    //        unchecked {
    //            duration *= 1 days;
    //        }
    //    }

    //    /// return locking ratio restrictions indicates that the vipLevel can utility infinite lock NFTs at corresponding ratio
    //    function getLockingRatioForInfinite(uint8 vipLevel) internal pure returns (uint256 ratio) {
    //        assembly {
    //            switch vipLevel
    //            case 1 {
    //                ratio := 0
    //            }
    //            case 2 {
    //                ratio := 0
    //            }
    //            case 3 {
    //                ratio := 20
    //            }
    //            case 4 {
    //                ratio := 30
    //            }
    //            case 5 {
    //                ratio := 40
    //            }
    //            case 6 {
    //                ratio := 50
    //            }
    //            case 7 {
    //                ratio := 80
    //            }
    //        }
    //    }

    /// return locking ratio restrictions indicates that the vipLevel can utility safebox to lock NFTs at corresponding ratio
    //    function getLockingRatioForSafebox(uint8 vipLevel) internal pure returns (uint256 ratio) {
    //        assembly {
    //            switch vipLevel
    //            case 1 {
    //                ratio := 15
    //            }
    //            case 2 {
    //                ratio := 25
    //            }
    //            case 3 {
    //                ratio := 35
    //            }
    //            case 4 {
    //                ratio := 45
    //            }
    //            case 5 {
    //                ratio := 55
    //            }
    //            case 6 {
    //                ratio := 65
    //            }
    //            case 7 {
    //                ratio := 75
    //            }
    //        }
    //    }

    //    function getVipRequiredStakingWithDiscount(
    //        uint256 requiredStaking,
    //        uint8 vipLevel
    //    ) internal pure returns (uint256) {
    //        if (vipLevel < 3) {
    //            return requiredStaking;
    //        }
    //        unchecked {
    //            /// the higher vip level, more discount for staking
    //            ///  discount range: 10% - 50%
    //            return (requiredStaking * (100 - (vipLevel - 2) * 10)) / 100;
    //        }
    //    }

    //    function getRequiredStakingForLockRatio(uint256 locked, uint256 totalManaged) internal pure returns (uint256) {
    //        if (totalManaged <= 0) {
    //            return 1200 ether;
    //        }
    //
    //        unchecked {
    //            uint256 lockingRatioPct = (locked * 100) / totalManaged;
    //            if (lockingRatioPct <= 40) {
    //                return 1200 ether;
    //            } else if (lockingRatioPct < 60) {
    //                return 1320 ether + ((lockingRatioPct - 40) >> 1) * 120 ether;
    //            } else if (lockingRatioPct < 70) {
    //                return 2640 ether + ((lockingRatioPct - 60) >> 1) * 240 ether;
    //            } else if (lockingRatioPct < 80) {
    //                return 4080 ether + ((lockingRatioPct - 70) >> 1) * 480 ether;
    //            } else if (lockingRatioPct < 90) {
    //                return 6960 ether + ((lockingRatioPct - 80) >> 1) * 960 ether;
    //            } else if (lockingRatioPct < 100) {
    //                /// 108000 * 2^x
    //                return (108000 ether << ((lockingRatioPct - 90) >> 1)) / 5;
    //            } else {
    //                return 345600 ether;
    //            }
    //        }
    //    }

    //    /// @dev returns (costAfterDiscount, quotaUsedAfter)
    //    function getVipClaimCostWithDiscount(
    //        uint256 cost,
    //        uint8 vipLevel,
    //        uint96 quotaUsed
    //    ) internal pure returns (uint256, uint96) {
    //        uint96 totalQuota = 1 ether;
    //
    //        assembly {
    //            switch vipLevel
    //            case 0 {
    //                totalQuota := mul(0, totalQuota)
    //            }
    //            case 1 {
    //                totalQuota := mul(2000, totalQuota)
    //            }
    //            case 2 {
    //                totalQuota := mul(4000, totalQuota)
    //            }
    //            case 3 {
    //                totalQuota := mul(8000, totalQuota)
    //            }
    //            case 4 {
    //                totalQuota := mul(16000, totalQuota)
    //            }
    //            case 5 {
    //                totalQuota := mul(32000, totalQuota)
    //            }
    //            case 6 {
    //                totalQuota := mul(64000, totalQuota)
    //            }
    //            case 7 {
    //                totalQuota := mul(128000, totalQuota)
    //            }
    //        }
    //
    //        if (totalQuota <= quotaUsed) {
    //            return (cost, quotaUsed);
    //        }
    //
    //        unchecked {
    //            totalQuota -= quotaUsed;
    //            if (cost < totalQuota) {
    //                return (0, uint96(quotaUsed + cost));
    //            } else {
    //                return (cost - totalQuota, totalQuota + quotaUsed);
    //            }
    //        }
    //    }

    //    function getClaimCost(uint256 lockingRatioPct) internal pure returns (uint256) {
    //        if (lockingRatioPct < 40) {
    //            return 0;
    //        } else {
    //            /// 1000 * 2^(0..12)
    //            unchecked {
    //                return 1000 ether * (2 ** ((lockingRatioPct - 40) / 5));
    //            }
    //        }
    //    }

    //    function getVaultAuctionDurationAtLR(uint256 lockingRatio) internal pure returns (uint256) {
    //        if (lockingRatio < 80) return 1 hours;
    //        else if (lockingRatio < 85) return 3 hours;
    //        else if (lockingRatio < 90) return 6 hours;
    //        else if (lockingRatio < 95) return 12 hours;
    //        else return 24 hours;
    //    }

    //    function getSafeboxPeriodQuota(uint8 vipLevel) internal pure returns (uint16 quota) {
    //        assembly {
    //            switch vipLevel
    //            case 0 {
    //                quota := 0
    //            }
    //            case 1 {
    //                quota := 1
    //            }
    //            case 2 {
    //                quota := 2
    //            }
    //            case 3 {
    //                quota := 4
    //            }
    //            case 4 {
    //                quota := 8
    //            }
    //            case 5 {
    //                quota := 16
    //            }
    //            case 6 {
    //                quota := 32
    //            }
    //            case 7 {
    //                quota := 64
    //            }
    //        }
    //    }
    //
    //    function getSafeboxUserQuota(uint8 vipLevel) internal pure returns (uint16 quota) {
    //        assembly {
    //            switch vipLevel
    //            case 0 {
    //                quota := 0
    //            }
    //            case 1 {
    //                quota := 4
    //            }
    //            case 2 {
    //                quota := 8
    //            }
    //            case 3 {
    //                quota := 16
    //            }
    //            case 4 {
    //                quota := 32
    //            }
    //            case 5 {
    //                quota := 64
    //            }
    //            case 6 {
    //                quota := 128
    //            }
    //            case 7 {
    //                quota := 256
    //            }
    //        }
    //    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library Errors {
    /// @notice Safe Box error
    error SafeBoxHasExpire();
    error SafeBoxNotExist();
    error SafeBoxHasNotExpire();
    error SafeBoxAlreadyExist();
    error NoMatchingSafeBoxKey();
    error SafeBoxKeyAlreadyExist();

    /// @notice Auction error
    error AuctionHasNotCompleted();
    error AuctionHasExpire();
    error AuctionBidIsNotHighEnough();
    error AuctionBidTokenMismatch();
    error AuctionSelfBid();
    error AuctionInvalidBidAmount();
    error AuctionNotExist();
    error SafeBoxAuctionWindowHasPassed();

    /// @notice Activity common error
    error NftHasActiveActivities();
    error ActivityHasNotCompleted();
    error ActivityHasExpired();
    error ActivityNotExist();

    /// @notice User account error
    error InsufficientFund();
    error InsufficientCredit();
    //    error InsufficientBalanceForVipLevel();
    error NoPrivilege();

    /// @notice Parameter error
    error InvalidParam();
    error NftCollectionNotSupported();
    error NftCollectionAlreadySupported();
    error ClaimableNftInsufficient();
    error TokenNotSupported();
    error PeriodQuotaExhausted();
    error UserQuotaExhausted();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IFragmentToken {
    error CallerIsNotTrustedContract();

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library CurrencyTransfer {
    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();
    /// @notice Thrown when an NATIVE transfer fails
    error NativeTransferFailed();

    address public constant NATIVE = address(0);

    function safeTransfer(address token, address to, uint256 amount) internal {
        // ref
        // https://docs.soliditylang.org/en/latest/internals/layout_in_memory.html
        // implementation from
        // https://github.com/transmissions11/solmate/blob/v7/src/utils/SafeTransferLib.sol
        // https://github.com/Uniswap/v4-core/blob/main/contracts/types/Currency.sol
        bool success;

        if (token == NATIVE) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let memPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(4, to) // Append the "to" argument.
                mstore(36, amount) // Append the "amount" argument.

                success := and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0, 68, 0, 32)
                )

                mstore(0x60, 0) // Restore the zero slot to zero.
                mstore(0x40, memPointer) // Restore the memPointer.
            }
            if (!success) revert ERC20TransferFailed();
        }
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append and mask the "from" argument.
            mstore(36, to) // Append and mask the "to" argument.
            // Append the "amount" argument. Masking not required as it's a full 32 byte type.
            mstore(68, amount)

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        if (!success) revert ERC20TransferFailed();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../interface/IFragmentToken.sol";

struct SafeBox {
    /// Either matching a key OR Constants.SAFEBOX_KEY_NOTATION meaning temporarily
    /// held by a bidder in auction.
    uint64 keyId;
    /// The timestamp that the safe box expires.
    uint32 expiryTs;
    /// The owner of the safebox. It maybe outdated due to expiry
    address owner;
}

struct PrivateOffer {
    /// private offer end time
    //    uint96 endTime;
    /// which token used to accpet the offer
    address token;
    /// price of the offer
    uint96 price;
    address owner;
    /// who should receive the offer
    address buyer;
    uint64 activityId;
}

struct AuctionInfo {
    /// The end time for the auction.
    uint96 endTime;
    /// Bid token address.
    address bidTokenAddress;
    /// Minimum Bid.
    uint96 minimumBid;
    /// The person who trigger the auction at the beginning.
    address triggerAddress;
    uint96 lastBidAmount;
    address lastBidder;
    /// Whether the auction is triggered by the NFT owner itself？
    bool isSelfTriggered;
    uint64 activityId;
    uint32 feeRateBips;
}

struct TicketRecord {
    /// who buy the tickets
    address buyer;
    /// Start index of tickets
    /// [startIdx, endIdx)
    uint48 startIdx;
    /// End index of tickets
    uint48 endIdx;
}

struct RaffleInfo {
    /// raffle end time
    uint48 endTime;
    /// max tickets amount the raffle can sell
    uint48 maxTickets;
    /// which token used to buy the raffle tickets
    address token;
    /// price per ticket
    uint96 ticketPrice;
    /// total funds collected by selling tickets
    uint96 collectedFund;
    uint64 activityId;
    address owner;
    /// total sold tickets amount
    uint48 ticketSold;
    uint32 feeRateBips;
    /// whether the raffle is being settling
    bool isSettling;
    /// tickets sold records
    TicketRecord[] tickets;
}

struct CollectionState {
    /// The address of the Scattering Token cooresponding to the NFTs.
    IFragmentToken fragmentToken;
    address keyIdNft;
    /// Records the active safe box in each time bucket.
    //    mapping(uint256 => uint256) countingBuckets;
    /// Stores all of the NFTs that has been fragmented but *without* locked up limit.
    uint256[] freeTokenIds;
    /// Huge map for all the `SafeBox`es in one collection.
    mapping(uint256 => SafeBox) safeBoxes;
    /// Stores all the ongoing auctions: nftId => `AuctionInfo`.
    mapping(uint256 => AuctionInfo) activeAuctions;
    /// Stores all the ongoing raffles: nftId => `RaffleInfo`.
    mapping(uint256 => RaffleInfo) activeRaffles;
    /// Stores all the ongoing private offers: nftId => `PrivateOffer`.
    mapping(uint256 => PrivateOffer) activePrivateOffers;
    // todo will be stored in the slot from right to left in sequence
    /// Active Safe Box Count.
    uint64 activeSafeBoxCnt;
    /// The last bucket time the `countingBuckets` is updated.
    //    uint64 lastUpdatedBucket;
    /// Next Key Id. This should start from 1, we treat key id `SafeboxLib.SAFEBOX_KEY_NOTATION` as temporarily
    /// being used for activities(auction/raffle).
    uint64 nextKeyId;
    /// The number of infinite lock count.
    //    uint64 infiniteCnt;
    /// Next Activity Id. This should start from 1
    uint64 nextActivityId;
    //    uint32 lastVaultAuctionPeriodTs;
}

struct UserFloorAccount {
    //    /// @notice it should be maximum of the `totalLockingCredit` across all collections
    //    uint96 minMaintCredit;
    /// @notice used to iterate collection accounts
    //    /// packed with `minMaintCredit` to reduce storage slot access
    //    address firstCollection;
    //    /// @notice user vip level related info
    //    /// 0 - 239 bits: store SafeBoxKey Count per vip level, per level using 24 bits
    //    /// 240 - 247 bits: store minMaintVipLevel
    //    /// 248 - 255 bits: remaining
    //    uint256 vipInfo;
    //    /// @notice Locked Credit amount which cannot be withdrawn and will be released as time goes.
    //    uint256 lockedCredit;
    //    mapping(address => CollectionAccount) accounts;
    mapping(address => uint256) tokenAmounts;
    //    uint32 lastQuotaPeriodTs;
    //    uint16 safeboxQuotaUsed;
    //    uint32 lastWaiverPeriodTs;
    //    uint96 creditWaiverUsed;
}

struct SafeBoxKey {
    //    /// locked credit amount of this safebox
    //    uint96 lockingCredit;
    // corresponding key id of the safebox
    uint64 keyId;
    //    /// which vip level the safebox locked
    //    uint8 vipLevel;
}

//struct CollectionAccount {
//    mapping(uint256 => SafeBoxKey) keys;
//    //    /// total locking credit of all `keys` in this collection
//    //    uint96 totalLockingCredit;
//    /// track next collection as linked list
//    address next;
//}

/// Internal Structure
struct LockParam {
    address proxyCollection;
    address collection;
    uint256[] nftIds;
    //    uint256 expiryTs;
    //    uint256 vipLevel;
    //    uint256 maxCreditCost;
    //    address creditToken;
    uint256 rentalDays;
}

struct FeeParam {
    uint256 safeBoxCommission;
    uint256 commonPoolCommission;
}

struct PaymentParam {
    address paymentToken; // 付款token，如果是eth，写成 address(0)
    uint256 paymentAmount; // 付款数量
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import "../Constants.sol";
import "../Errors.sol";
import "../library/CurrencyTransfer.sol";
import {UserFloorAccount} from "./Structs.sol";

library UserLib {
    using SafeCast for uint256;

    /// @notice `sender` deposit `token` into Scattering on behalf of `receiver`. `receiver`'s account will be updated.
    event DepositToken(address indexed sender, address indexed receiver, address indexed token, uint256 amount);
    /// @notice `sender` withdraw `token` from Scattering and transfer it to `receiver`.
    event WithdrawToken(address indexed sender, address indexed receiver, address indexed token, uint256 amount);
    //    /// @notice update the account maintain credit on behalfOf `onBehalfOf`
    //    event UpdateMaintainCredit(address indexed onBehalfOf, uint256 minMaintCredit);

    address internal constant LIST_GUARD = address(1);

    function deposit(
        UserFloorAccount storage account,
        address onBehalfOf,
        address token,
        uint256 amount,
        bool isLockCredit
    ) public {
        depositToken(account, token, amount);
        isLockCredit;

        if (token == CurrencyTransfer.NATIVE) {
            if (amount != msg.value) {
                revert Errors.InsufficientFund();
            }
        } else {
            CurrencyTransfer.safeTransferFrom(token, msg.sender, address(this), amount);
        }
        emit DepositToken(msg.sender, onBehalfOf, token, amount);
    }

    function withdraw(
        UserFloorAccount storage account,
        address receiver,
        address token,
        uint256 amount,
        bool isCredit
    ) public {
        withdrawToken(account, token, amount, isCredit);
        CurrencyTransfer.safeTransfer(token, receiver, amount);
        emit WithdrawToken(msg.sender, receiver, token, amount);
    }

    //    function ensureVipCredit(
    //        UserFloorAccount storage account,
    //        uint8 requireVipLevel,
    //        address creditToken
    //    ) internal view returns (uint256) {
    //        uint256 totalCredit = tokenBalance(account, creditToken);
    //        //        if (Constants.getVipBalanceRequirements(requireVipLevel) > totalCredit) {
    //        //            revert Errors.InsufficientBalanceForVipLevel();
    //        //        }
    //        return totalCredit;
    //    }

    //    function getMinMaintVipLevel(UserFloorAccount storage account) internal view returns (uint8) {
    //        unchecked {
    //            return uint8(account.vipInfo >> 240);
    //        }
    //    }

    //    function getMinLevelAndVipKeyCounts(
    //        uint256 vipInfo
    //    ) internal pure returns (uint8 minLevel, uint256[] memory counts) {
    //        unchecked {
    //            counts = new uint256[](Constants.VIP_LEVEL_COUNT);
    //            minLevel = uint8(vipInfo >> 240);
    //            for (uint256 i; i < Constants.VIP_LEVEL_COUNT; ++i) {
    //                counts[i] = (vipInfo >> (i * 24)) & 0xFFFFFF;
    //            }
    //        }
    //    }

    //    function storeMinLevelAndVipKeyCounts(
    //        UserFloorAccount storage account,
    //        uint8 minMaintVipLevel,
    //        uint256[] memory keyCounts
    //    ) internal {
    //        unchecked {
    //            uint256 _data = (uint256(minMaintVipLevel) << 240);
    //            for (uint256 i; i < Constants.VIP_LEVEL_COUNT; ++i) {
    //                _data |= ((keyCounts[i] & 0xFFFFFF) << (i * 24));
    //            }
    //            account.vipInfo = _data;
    //        }
    //    }

    //    function getOrAddCollection(
    //        UserFloorAccount storage user,
    //        address collection
    //    ) internal returns (CollectionAccount storage) {
    //        CollectionAccount storage entry = user.accounts[collection];
    //        if (entry.next == address(0)) {
    //            if (user.firstCollection == address(0)) {
    //                user.firstCollection = collection;
    //                entry.next = LIST_GUARD;
    //            } else {
    //                entry.next = user.firstCollection;
    //                user.firstCollection = collection;
    //            }
    //        }
    //        return entry;
    //    }

    //    function removeCollection(UserFloorAccount storage userAccount, address collection, address prev) internal {
    //        CollectionAccount storage cur = userAccount.accounts[collection];
    //        if (cur.next == address(0)) revert Errors.InvalidParam();
    //
    //        if (collection == userAccount.firstCollection) {
    //            if (cur.next == LIST_GUARD) {
    //                userAccount.firstCollection = address(0);
    //            } else {
    //                userAccount.firstCollection = cur.next;
    //            }
    //        } else {
    //            CollectionAccount storage prevAccount = userAccount.accounts[prev];
    //            if (prevAccount.next != collection) revert Errors.InvalidParam();
    //            prevAccount.next = cur.next;
    //        }
    //
    //        delete userAccount.accounts[collection];
    //    }

    //    function getByKey(
    //        UserFloorAccount storage userAccount,
    //        address collection
    //    ) internal view returns (CollectionAccount storage) {
    //        return userAccount.accounts[collection];
    //    }
    //    function addSafeboxKey(CollectionAccount storage account, uint256 nftId, SafeBoxKey memory key) internal {
    //        if (account.keys[nftId].keyId > 0) {
    //            revert Errors.SafeBoxKeyAlreadyExist();
    //        }
    //
    //        account.keys[nftId] = key;
    //    }
    //
    //    function removeSafeboxKey(CollectionAccount storage account, uint256 nftId) internal {
    //        delete account.keys[nftId];
    //    }
    //
    //    function getByKey(CollectionAccount storage account, uint256 nftId) internal view returns (SafeBoxKey storage) {
    //        return account.keys[nftId];
    //    }

    function tokenBalance(UserFloorAccount storage account, address token) internal view returns (uint256) {
        return account.tokenAmounts[token];
    }

    //    function lockCredit(UserFloorAccount storage account, uint256 amount) internal {
    //        unchecked {
    //            account.lockedCredit += amount;
    //        }
    //    }
    //
    //    function unlockCredit(UserFloorAccount storage account, uint256 amount) internal {
    //        unchecked {
    //            account.lockedCredit -= amount;
    //        }
    //    }

    function depositToken(UserFloorAccount storage account, address token, uint256 amount) internal {
        account.tokenAmounts[token] += amount;
    }

    function withdrawToken(
        UserFloorAccount storage account,
        address token,
        uint256 amount,
        bool isCreditToken
    ) internal {
        uint256 balance = account.tokenAmounts[token];
        if (balance < amount) {
            revert Errors.InsufficientCredit();
        }

        // todo nothing to do
        if (isCreditToken) {
            uint256 availableBuf;
            unchecked {
                availableBuf = balance - amount;
            }

            account.tokenAmounts[token] = availableBuf;
        } else {
            unchecked {
                account.tokenAmounts[token] = balance - amount;
            }
        }
    }

    function transferToken(
        UserFloorAccount storage from,
        UserFloorAccount storage to,
        address token,
        uint256 amount,
        bool isCreditToken
    ) internal {
        withdrawToken(from, token, amount, isCreditToken);
        depositToken(to, token, amount);
    }

    //    function updateVipKeyCount(UserFloorAccount storage account, uint8 vipLevel, int256 diff) internal {
    //        if (vipLevel > 0 && diff != 0) {
    //            (uint8 minMaintVipLevel, uint256[] memory keyCounts) = getMinLevelAndVipKeyCounts(account.vipInfo);
    //
    //            if (diff < 0) {
    //                keyCounts[vipLevel] -= uint256(-diff);
    //                if (vipLevel == minMaintVipLevel && keyCounts[vipLevel] == 0) {
    //                    uint8 newVipLevel = vipLevel;
    //                    do {
    //                        unchecked {
    //                            --newVipLevel;
    //                        }
    //                    } while (newVipLevel > 0 && keyCounts[newVipLevel] == 0);
    //
    //                    minMaintVipLevel = newVipLevel;
    //                }
    //            } else {
    //                keyCounts[vipLevel] += uint256(diff);
    //                if (vipLevel > minMaintVipLevel) {
    //                    minMaintVipLevel = vipLevel;
    //                }
    //            }
    //            storeMinLevelAndVipKeyCounts(account, minMaintVipLevel, keyCounts);
    //        }
    //    }

    //    function recalculateMinMaintCredit(
    //        UserFloorAccount storage account,
    //        address onBehalfOf
    //    ) public returns (uint256 maxLocking) {
    //        address prev = account.firstCollection;
    //        for (address collection = account.firstCollection; collection != LIST_GUARD && collection != address(0); ) {
    //            (uint256 locking, address next) = (
    //                getByKey(account, collection).totalLockingCredit,
    //                getByKey(account, collection).next
    //            );
    //            if (locking == 0) {
    //                removeCollection(account, collection, prev);
    //                collection = next;
    //            } else {
    //                if (locking > maxLocking) {
    //                    maxLocking = locking;
    //                }
    //                prev = collection;
    //                collection = next;
    //            }
    //        }
    //
    //        account.minMaintCredit = uint96(maxLocking);
    //
    //        emit UpdateMaintainCredit(onBehalfOf, maxLocking);
    //    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}