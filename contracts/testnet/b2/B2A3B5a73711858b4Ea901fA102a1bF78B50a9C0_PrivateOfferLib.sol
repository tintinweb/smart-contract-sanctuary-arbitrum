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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedMulticall();

    struct CallData {
        address target;
        bytes callData;
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Allow trusted caller to call specified addresses through the Contract
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param calls The encoded function data and target for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via calls
    function extMulticall(CallData[] calldata calls) external returns (bytes[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "./IMulticall.sol";

interface IScattering is IERC721Receiver, IMulticall {
    /// Admin Operations

    /// @notice Add new collection for Scattering Protocol
    function supportNewCollection(address _originalNFT, address fragmentToken) external;

    /// @notice Add new token which will be used as settlement token in Scattering Protocol
    /// @param addOrRemove `true` means add token, `false` means remove token
    function supportNewToken(address _tokenAddress, bool addOrRemove) external;

    /// @notice set proxy collection config
    /// Note. the `tokenId`s of the proxy collection and underlying collection must be correspond one by one
    /// eg. Paraspace Derivative Token BAYC(nBAYC) -> BAYC
    function setCollectionProxy(address proxyCollection, address underlyingCollection) external;

    /// @notice withdraw platform fee accumulated.
    /// Note. withdraw from `address(this)`'s account.
    function withdrawPlatformFee(address token, uint256 amount) external;

    //    /// @notice Deposit and lock credit token on behalf of receiver
    //    /// user can not withdraw these tokens until `unlockCredit` is called.
    //    function addAndLockCredit(address receiver, uint256 amount) external;
    //
    //    /// @notice Unlock user credit token to allow withdraw
    //    /// used to release investors' funds as time goes
    //    /// Note. locked credit can be used to operate safeboxes(lock/unlock...)
    //    function unlockCredit(address receiver, uint256 amount) external;

    /// User Operations

    /// @notice User deposits token to the Floor Contract
    /// @param onBehalfOf deposit token into `onBehalfOf`'s account.(note. the tokens of msg.sender will be transfered)
    function addTokens(address onBehalfOf, address token, uint256 amount) external payable;

    /// @notice User removes token from Floor Contract
    /// @param receiver who will receive the funds.(note. the token of msg.sender will be transfered)
    function removeTokens(address token, uint256 amount, address receiver) external;

    /// @notice Lock specified `nftIds` into Scattering Safeboxes and receive corresponding Fragment Tokens of the `collection`
    /// @param onBehalfOf who will receive the safebox and fragment tokens.(note. the NFTs of the msg.sender will be transfered)
    function lockNFTs(
        address collection,
        uint256[] memory nftIds,
        //        uint256 expiryTs,
        //        uint256 vipLevel,
        //        uint256 maxCredit,
        address onBehalfOf /* returns (uint256)*/
    ) external;

    /// @notice Extend the exist safeboxes with longer lock duration with more credit token staked
    function extendKeys(
        address collection,
        uint256[] memory nftIds,
        //        uint256 expiryTs,
        //        uint256 vipLevel,
        //        uint256 maxCredit
        uint256 newRentalDays /*returns (uint256)*/
    ) external payable;

    /// @notice Unlock specified `nftIds` which had been locked previously
    ///         sender's wallet should have enough Fragment Tokens of the `collection` which will be burned to redeem the NFTs
    /// @param receiver who will receive the NFTs.
    ///                 note. - The safeboxes of the msg.sender will be removed.
    ///                       - The Fragment Tokens of the msg.sender will be burned.
    function unlockNFTs(address collection, /* uint256 expiryTs, */ uint256[] memory nftIds, address receiver) external;

    /// @notice Fragment specified `nftIds` into Floor Vault and receive Fragment Tokens without any locking
    ///         after fragmented, any one has enough Fragment Tokens can redeem there `nftIds`
    /// @param onBehalfOf who will receive the fragment tokens.(note. the NFTs of the msg.sender will be transfered)
    function fragmentNFTs(address collection, uint256[] memory nftIds, address onBehalfOf) external;

    /// @notice Kick expired safeboxes to the vault
    function tidyExpiredNFTs(address collection, uint256[] memory nftIds) external;

    /// @notice Randomly claim `claimCnt` NFTs from Floor Vault
    ///         sender's wallet should have enough Fragment Tokens of the `collection` which will be burned to redeem the NFTs
    /// @param receiver who will receive the NFTs.
    ///                 note. - the msg.sender will pay the redemption cost.
    ///                       - The Fragment Tokens of the msg.sender will be burned.
    function claimRandomNFT(
        address collection,
        uint256 claimCnt,
        //        uint256 maxCredit,
        address receiver /*returns (uint256)*/
    ) external;

    /// @notice Start auctions on specified `nftIds` with an initial bid price(`bidAmount`)
    ///         This kind of auctions will be settled with Floor Credit Token
    /// @param bidAmount initial bid price
    function initAuctionOnExpiredSafeBoxes(
        address collection,
        uint256[] memory nftIds,
        address bidToken,
        uint256 bidAmount
    ) external;

    /// @notice Start auctions on specified `nftIds` index in the vault with an initial bid price(`bidAmount`)
    ///         This kind of auctions will be settled with Fragment Token of the collection
    /// @param bidAmount initial bid price 每个nft的最低出价
    function initAuctionOnVault(
        address collection,
        uint256[] memory vaultIdx,
        address bidToken,
        uint96 bidAmount
    ) external;

    /// @notice Owner starts auctions on his locked Safeboxes
    /// @param token which token should be used to settle auctions(bid, settle) 结算token
    /// @param minimumBid minimum bid price when someone place a bid on the auction 最低出价
    function ownerInitAuctions(
        address collection,
        uint256[] memory nftIds,
        //        uint256 maxExpiry,
        address token,
        uint256 minimumBid
    ) external;

    //    /// @notice Place a bid on specified `nftId`'s action
    //    /// @param bidAmount bid price
    //    /// @param bidOptionIdx which option used to extend auction expiry and bid price
    //    function placeBidOnAuction(address collection, uint256 nftId, uint256 bidAmount, uint256 bidOptionIdx) external;

    /// @notice Place a bid on specified `nftId`'s action
    /// @param token which token should be transfered to the Scattering for bidding. `0x0` means ETH(native)
    /// @param amountToTransfer how many `token` should to transfered
    function placeBidOnAuction(
        address collection,
        uint256 nftId,
        uint256 bidAmount,
        uint256 bidOptionIdx,
        address token,
        uint256 amountToTransfer
    ) external payable;

    /// @notice Settle auctions of `nftIds`
    function settleAuctions(address collection, uint256[] memory nftIds) external;

    struct RaffleInitParam {
        address collection;
        uint256[] nftIds;
        /// @notice which token used to buy and settle raffle
        address ticketToken;
        /// @notice price per ticket
        uint96 ticketPrice;
        /// @notice max tickets amount can be sold
        uint32 maxTickets;
        /// @notice durationIdx used to get how long does raffles last
        uint256 duration;
        //        /// @notice the largest epxiry of nfts, we need this to clear locking records
        //        uint256 maxExpiry;
    }

    /// @notice Owner start raffles on locked `nftIds`
    function ownerInitRaffles(RaffleInitParam memory param) external;

    //    /// @notice Buy `nftId`'s raffle tickets
    //    /// @param ticketCnt how many tickets should be bought in this operation
    //    function buyRaffleTickets(address collectionId, uint256 nftId, uint256 ticketCnt) external;

    /// @notice Buy `nftId`'s raffle tickets
    /// @param token which token should be transfered to the Scattering for buying. `0x0` means ETH(native)
    /// @param amountToTransfer how many `token` should to transfered
    function buyRaffleTickets(
        address collectionId,
        uint256 nftId,
        uint256 ticketCnt,
        address token,
        uint256 amountToTransfer
    ) external payable;

    /// @notice Settle raffles of `nftIds`
    function settleRaffles(address collectionId, uint256[] memory nftIds) external;

    struct PrivateOfferInitParam {
        address collection;
        uint256[] nftIds;
        //        /// @notice the largest epxiry of nfts, we need this to clear locking records
        //        uint256 maxExpiry;
        /// @notice who will receive the otc offers
        address receiver;
        /// @notice which token used to settle offers
        address token;
        /// @notice price of the offers
        uint96 price;
    }

    /// @notice Owner start private offers(otc) on locked `nftIds`
    function ownerInitPrivateOffers(PrivateOfferInitParam memory param) external;

    /// @notice Owner or Receiver cancel the private offers of `nftIds`
    function cancelPrivateOffers(address collectionId, uint256[] memory nftIds) external;

    //    /// @notice Receiver accept the private offers of `nftIds`
    //    function buyerAcceptPrivateOffers(address collectionId, uint256[] memory nftIds) external;

    /// @notice Receiver accept the private offers of `nftIds`
    /// @param token which token should be transfered to the Scattering for buying. `0x0` means ETH(native)
    /// @param amountToTransfer how many `token` should to transfered
    function buyerAcceptPrivateOffers(
        address collectionId,
        uint256[] memory nftIds,
        address token,
        uint256 amountToTransfer
    ) external payable;

    //    /// @notice Clear expired or mismatching safeboxes of `nftIds` in user account
    //    /// @param onBehalfOf whose account will be recalculated
    //    function removeExpiredKeyAndRestoreCredit(
    //        address collection,
    //        uint256[] memory nftIds,
    //        address onBehalfOf /*returns (uint256)*/
    //    ) external;

    //    /// @notice Update user's staking credit status by iterating all active collections in user account
    //    /// @param onBehalfOf whose account will be recalculated
    //    /// @return availableCredit how many credit available to use after this opeartion
    //    function recalculateAvailableCredit(address onBehalfOf) external returns (uint256 availableCredit);

    /// Util operations

    /// @notice Called by external contracts to access granular pool state
    /// @param slot Key of slot to sload
    /// @return value The value of the slot as bytes32
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Called by external contracts to access granular pool state
    /// @param slot Key of slot to start sloading from
    /// @param nSlots Number of slots to load into return value
    /// @return value The value of the sload-ed slots concatenated as dynamic bytes
    function extsload(bytes32 slot, uint256 nSlots) external view returns (bytes memory value);

    function creditToken() external view returns (address);
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

library ERC721Transfer {
    /// @notice Thrown when an ERC721 transfer fails
    error ERC721TransferFailed();

    function safeTransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x42842e0e00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append and mask the "from" argument.
            mstore(36, to) // Append and mask the "to" argument.
            // Append the "tokenId" argument. Masking not required as it's a full 32 byte type.
            mstore(68, tokenId)

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), collection, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        if (!success) revert ERC721TransferFailed();
    }

    function safeBatchTransferFrom(address collection, address from, address to, uint256[] memory tokenIds) internal {
        unchecked {
            uint256 len = tokenIds.length;
            for (uint256 i; i < len; ++i) {
                safeTransferFrom(collection, from, to, tokenIds[i]);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
//import "../library/RollingBuckets.sol";
import "../library/ERC721Transfer.sol";

import "../Errors.sol";
import "../Constants.sol";
import "./User.sol";
import "./Helper.sol";
import {SafeBox, CollectionState, AuctionInfo, UserFloorAccount, LockParam, PaymentParam} from "./Structs.sol";
import {SafeBoxLib} from "./SafeBox.sol";

import "../interface/IScattering.sol";

library CollectionLib {
    using SafeBoxLib for SafeBox;
    using SafeCast for uint256;
    //    using RollingBuckets for mapping(uint256 => uint256);
    //    using UserLib for CollectionAccount;
    using UserLib for UserFloorAccount;

    event LockNft(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        //        uint256 safeBoxExpiryTs,
        //        uint256 minMaintCredit,
        uint256 rentalDays,
        address proxyCollection
    );
    event ExtendKey(
        address indexed operator,
        address indexed collection,
        uint256[] tokenIds,
        //        uint256[] safeBoxKeys,
        //        uint256 safeBoxExpiryTs,
        //        uint256 minMaintCredit
        uint256 rentalDays
    );
    event UnlockNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        address proxyCollection
    );
    event RemoveExpiredKey(
        address indexed operator,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys
    );
    event ExpiredNftToVault(address indexed operator, address indexed collection, uint256[] tokenIds);
    event FragmentNft(
        address indexed operator,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds
    );
    event ClaimRandomNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds
        //        uint256 creditCost
    );

    function fragmentNFTs(
        CollectionState storage collectionState,
        address collection,
        uint256[] memory nftIds,
        address onBehalfOf
    ) public {
        uint256 nftLen = nftIds.length;
        unchecked {
            for (uint256 i; i < nftLen; ++i) {
                collectionState.freeTokenIds.push(nftIds[i]);
            }
        }
        collectionState.fragmentToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftLen);
        ERC721Transfer.safeBatchTransferFrom(collection, msg.sender, address(this), nftIds);

        emit FragmentNft(msg.sender, onBehalfOf, collection, nftIds);
    }

    struct LockInfo {
        //        bool isInfinite;
        //        uint256 currentBucket;
        //        uint256 newExpiryBucket;
        uint256 totalManaged;
        //        uint256 newRequireLockCredit;
        //        uint64 infiniteCnt;
    }

    function lockNfts(
        CollectionState storage collection,
        //        UserFloorAccount storage userAccount,
        LockParam memory param,
        address onBehalfOf
    ) public {
        if (onBehalfOf == address(this)) revert Errors.InvalidParam();
        /// proxy collection only enabled when infinity lock
        // if (param.collection != param.proxyCollection && param.expiryTs != 0) revert Errors.InvalidParam();
        if (param.collection != param.proxyCollection) revert Errors.InvalidParam();

        //        uint8 vipLevel = uint8(param.vipLevel);
        //        uint256 totalCredit = account.ensureVipCredit(vipLevel, param.creditToken);
        //        // Helper.ensureMaxLocking(collection, vipLevel, param.expiryTs, param.nftIds.length, false);
        //        {
        //            uint8 maxVipLevel = Constants.getVipLevel(totalCredit);
        //            uint256 newLocked = param.nftIds.length;
        //            Helper.ensureProxyVipLevel(maxVipLevel, param.collection != param.proxyCollection);
        //            Helper.checkAndUpdateSafeboxPeriodQuota(account, maxVipLevel, newLocked.toUint16());
        //            Helper.checkSafeboxUserQuota(account, vipLevel, newLocked);
        //        }

        //        /// cache value to avoid multi-reads
        //        uint256 minMaintCredit = account.minMaintCredit;
        uint256[] memory nftIds = param.nftIds;
        uint256[] memory newKeys;
        {
            //            CollectionAccount storage userCollectionAccount = userAccount.getOrAddCollection(param.collection);

            // (totalCreditCost, newKeys) = _lockNfts(collection, userCollectionAccount, nftIds, param.expiryTs, vipLevel);
            newKeys = _lockNfts(collection, onBehalfOf, nftIds, param.rentalDays);
            //            // compute max credit for locking cost
            //            uint96 totalLockingCredit = userCollectionAccount.totalLockingCredit;
            //            {
            //                uint256 creditBuffer;
            //                unchecked {
            //                    creditBuffer = totalCredit - totalLockingCredit;
            //                }
            //                if (totalCreditCost > creditBuffer || totalCreditCost > param.maxCreditCost) {
            //                    revert Errors.InsufficientCredit();
            //                }
            //            }

            //            totalLockingCredit += totalCreditCost.toUint96();
            //            userCollectionAccount.totalLockingCredit = totalLockingCredit;
            //
            //            if (totalLockingCredit > minMaintCredit) {
            //                account.minMaintCredit = totalLockingCredit;
            //                minMaintCredit = totalLockingCredit;
            //            }
        }

        //        account.updateVipKeyCount(vipLevel, int256(nftIds.length));
        /// mint for `onBehalfOf`, transfer from msg.sender
        collection.fragmentToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
        // todo The transfer will fail if it is not the owner, so there is no need to verify that the NFT belongs to this owner
        ERC721Transfer.safeBatchTransferFrom(param.proxyCollection, msg.sender, address(this), nftIds);

        emit LockNft(
            msg.sender,
            onBehalfOf,
            param.collection,
            nftIds,
            newKeys,
            //            param.expiryTs,
            //            minMaintCredit,
            param.rentalDays,
            param.proxyCollection
        );
    }

    function _lockNfts(
        CollectionState storage collectionState,
        //        CollectionAccount storage account,
        address onBehalfOf,
        uint256[] memory nftIds,
        //        uint256 expiryTs, // treat 0 as infinite lock.
        //        uint8 vipLevel,
        uint256 rentalDays
    ) private returns (/*uint256, */ uint256[] memory) {
        //        LockInfo memory info = LockInfo({
        //            isInfinite: expiryTs == 0,
        //            currentBucket: Helper.counterStamp(block.timestamp),
        //            newExpiryBucket: Helper.counterStamp(expiryTs),
        //            totalManaged: collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length
        //            newRequireLockCredit: 0
        //            infiniteCnt: collectionState.infiniteCnt
        //        });
        //        if (info.isInfinite) {
        //            /// if it is infinite lock, we need load all buckets to calculate the staking cost
        //            info.newExpiryBucket = Helper.counterStamp(block.timestamp + Constants.MAX_LOCKING_PERIOD);
        //        }
        //
        //        uint256[] memory buckets = Helper.prepareBucketUpdate(
        //            collectionState,
        //            info.currentBucket,
        //            info.newExpiryBucket
        //        );
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length; ) {
            //            uint256 lockedCredit = 0;
            //            uint256 lockedCredit = updateCountersAndGetSafeboxCredit(buckets, info, vipLevel);

            //            if (info.isInfinite) ++info.infiniteCnt;

            //            SafeBoxKey memory key = SafeBoxKey({
            //                keyId: Helper.generateNextKeyId(collectionState)
            //                lockingCredit: lockedCredit.toUint96(),
            //                vipLevel: vipLevel
            //                lockingCredit: 0,
            //                vipLevel: 0
            //            });

            //            account.addSafeboxKey(nftIds[idx], key);

            uint64 keyId = Helper.generateNextKeyId(collectionState);
            uint256 expiryTs = block.timestamp + rentalDays;
            addSafeBox(
                collectionState,
                nftIds[idx],
                SafeBox({keyId: keyId, expiryTs: uint32(expiryTs), owner: onBehalfOf})
            );

            // keys[idx] = SafeBoxLib.encodeSafeBoxKey(key);
            keys[idx] = uint256(keyId);

            //            info.newRequireLockCredit += lockedCredit;
            unchecked {
                //                ++info.totalManaged;
                ++idx;
            }
        }

        //        if (info.isInfinite) {
        //            collectionState.infiniteCnt = info.infiniteCnt;
        //        } else {
        //            collectionState.countingBuckets.batchSet(info.currentBucket, buckets);
        //            if (info.newExpiryBucket > collectionState.lastUpdatedBucket) {
        //                collectionState.lastUpdatedBucket = uint64(info.newExpiryBucket);
        //            }
        //        }

        return (/*info.newRequireLockCredit, */ keys);
    }

    function unlockNfts(
        CollectionState storage collection,
        //        UserFloorAccount storage userAccount,
        //        UserFloorAccount storage userAccount,
        address proxyCollection,
        address collectionId,
        uint256[] memory nftIds,
        //        uint256 maxExpiryTs,
        address receiver
    ) public {
        // accounts[collection]=>collectionAccount
        //        CollectionAccount storage userCollectionAccount = userAccount.getByKey(collectionId);
        // SafeBoxKey[] memory releasedKeys = _unlockNfts(collection, /* maxExpiryTs, */ nftIds, userCollectionAccount);
        // SafeBoxKey[] memory releasedKeys = _unlockNfts(collection, nftIds);
        _unlockNfts(collection, nftIds);
        //        for (uint256 i = 0; i < releasedKeys.length; ) {
        //            userAccount.updateVipKeyCount(releasedKeys[i].vipLevel, -1);
        //            unchecked {
        //                ++i;
        //            }
        //        }

        /// @dev if the receiver is the contract self, then unlock the safeboxes and dump the NFTs to the vault
        if (receiver == address(this)) {
            uint256 nftLen = nftIds.length;
            for (uint256 i; i < nftLen; ) {
                collection.freeTokenIds.push(nftIds[i]);
                unchecked {
                    ++i;
                }
            }
            emit FragmentNft(msg.sender, msg.sender, collectionId, nftIds);
        } else {
            collection.fragmentToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
            ERC721Transfer.safeBatchTransferFrom(proxyCollection, address(this), receiver, nftIds);
        }

        emit UnlockNft(msg.sender, receiver, collectionId, nftIds, proxyCollection);
    }

    function _unlockNfts(
        CollectionState storage collectionState,
        //        uint256 maxExpiryTs,
        uint256[] memory nftIds //        returns ( //            //        CollectionAccount storage userCollectionAccount //            SafeBox[] memory //        )
    ) private {
        // if (maxExpiryTs > 0 && maxExpiryTs < block.timestamp) revert Errors.SafeBoxHasExpire();
        //        SafeBox[] memory expiredKeys = new SafeBox[](nftIds.length);
        //        uint256 currentBucketTime = Helper.counterStamp(block.timestamp);
        //        uint256 creditToRelease = 0;
        //        uint256[] memory buckets;

        /// if maxExpiryTs == 0, it means all nftIds in this batch being locked infinitely that we don't need to update countingBuckets
        //        if (maxExpiryTs > 0) {
        //            uint256 maxExpiryBucketTime = Math.min(Helper.counterStamp(maxExpiryTs), collectionState.lastUpdatedBucket);
        //            buckets = collectionState.countingBuckets.batchGet(currentBucketTime, maxExpiryBucketTime);
        //        }

        for (uint256 i; i < nftIds.length; ) {
            uint256 nftId = nftIds[i];

            if (Helper.hasActiveActivities(collectionState, nftId)) revert Errors.NftHasActiveActivities();

            // SafeBox storage safeBox = Helper.useSafeBoxAndKey(collectionState, msg.sender, nftId);
            Helper.useSafeBoxAndKey(collectionState, msg.sender, nftId);

            //            creditToRelease += safeBoxKey.lockingCredit;
            //            if (safeBox.isInfiniteSafeBox()) {
            //                --collectionState.infiniteCnt;
            //            } else {
            //                uint256 limit = Helper.counterStamp(safeBox.expiryTs) - currentBucketTime;
            //                if (limit > buckets.length) revert();
            //                for (uint256 idx; idx < limit; ) {
            //                    --buckets[idx];
            //                    unchecked {
            //                        ++idx;
            //                    }
            //                }
            //            }

            //            expiredKeys[i] = safeBox;

            removeSafeBox(collectionState, nftId);
            //            userCollectionAccount.removeSafeboxKey(nftId);

            unchecked {
                ++i;
            }
        }

        //        userCollectionAccount.totalLockingCredit -= creditToRelease.toUint96();
        //        if (buckets.length > 0) {
        //            collectionState.countingBuckets.batchSet(currentBucketTime, buckets);
        //        }

        //        return expiredKeys;
    }

    function extendLockingForKeys(
        CollectionState storage collection,
        //        UserFloorAccount storage userAccount,
        LockParam memory param,
        address onBehalfOf
    ) public /*returns (uint256 totalCreditCost)*/ {
        //        uint8 newVipLevel = uint8(param.vipLevel);
        //       uint256 totalCredit = userAccount.ensureVipCredit(newVipLevel, param.creditToken);
        //Helper.ensureMaxLocking(collection, newVipLevel, param.expiryTs, param.nftIds.length, true);

        //        uint256 minMaintCredit = userAccount.minMaintCredit;
        //        uint256[] memory safeBoxKeys;
        {
            //            CollectionAccount storage collectionAccount = userAccount.getOrAddCollection(param.collection);

            // extend lock duration
            //            int256[] memory vipLevelDiffs;
            //            (safeBoxKeys) = _extendLockingForKeys(
            _extendLockingForKeys(
                collection,
                //                collectionAccount,
                param.nftIds,
                //                param.expiryTs,
                //                uint8(newVipLevel),
                param.rentalDays,
                onBehalfOf
            );

            //            // compute max credit for locking cost
            //            uint96 totalLockingCredit = collectionAccount.totalLockingCredit;
            //            {
            //                uint256 creditBuffer;
            //                unchecked {
            //                    creditBuffer = totalCredit - totalLockingCredit;
            //                }
            //                if (totalCreditCost > creditBuffer || totalCreditCost > param.maxCreditCost) {
            //                    revert Errors.InsufficientCredit();
            //                }
            //            }

            //            // update user vip key counts
            //            for (uint256 vipLevel = 0; vipLevel < vipLevelDiffs.length; ) {
            //                userAccount.updateVipKeyCount(uint8(vipLevel), vipLevelDiffs[vipLevel]);
            //                unchecked {
            //                    ++vipLevel;
            //                }
            //            }

            //            totalLockingCredit += totalCreditCost.toUint96();
            //            collectionAccount.totalLockingCredit = totalLockingCredit;
            //            if (totalLockingCredit > minMaintCredit) {
            //                userAccount.minMaintCredit = totalLockingCredit;
            //                minMaintCredit = totalLockingCredit;
            //            }
        }

        //        emit ExtendKey(msg.sender, param.collection, param.nftIds, safeBoxKeys, param.expiryTs, minMaintCredit);
        emit ExtendKey(msg.sender, param.collection, param.nftIds, param.rentalDays);
    }

    function _extendLockingForKeys(
        CollectionState storage collectionState,
        //        CollectionAccount storage userCollectionAccount,
        uint256[] memory nftIds,
        //        uint256 newExpiryTs, // expiryTs of 0 is infinite.
        //        uint8 newVipLevel,
        uint256 newRentalDays,
        address onBehalfOf
    ) private returns (/*int256[] memory, uint256, */ uint256[] memory) {
        //        LockInfo memory info = LockInfo({
        //            isInfinite: newExpiryTs == 0,
        //            currentBucket: Helper.counterStamp(block.timestamp),
        //            newExpiryBucket: Helper.counterStamp(newExpiryTs),
        //            totalManaged: collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length,
        //            newRequireLockCredit: 0
        //            infiniteCnt: collectionState.infiniteCnt
        //        });
        //        if (info.isInfinite) {
        //            info.newExpiryBucket = Helper.counterStamp(block.timestamp + Constants.MAX_LOCKING_PERIOD);
        //        }
        //
        //        uint256[] memory buckets = Helper.prepareBucketUpdate(
        //            collectionState,
        //            info.currentBucket,
        //            info.newExpiryBucket
        //        );
        //        int256[] memory vipLevelDiffs = new int256[](Constants.VIP_LEVEL_COUNT);
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length; ) {
            if (Helper.hasActiveActivities(collectionState, nftIds[idx])) revert Errors.NftHasActiveActivities();

            SafeBox storage safeBox = Helper.useSafeBoxAndKey(collectionState, onBehalfOf, nftIds[idx]);

            //            {
            //                uint256 extendOffset = Helper.counterStamp(safeBox.expiryTs) - info.currentBucket;
            //                unchecked {
            //                    for (uint256 i; i < extendOffset; ++i) {
            //                        if (buckets[i] == 0) revert Errors.InvalidParam();
            //                        --buckets[i];
            //                    }
            //                }
            //            }

            //            uint256 safeboxQuote = updateCountersAndGetSafeboxCredit(buckets, info, newVipLevel);
            //
            //            if (safeboxQuote > safeBoxKey.lockingCredit) {
            //                info.newRequireLockCredit += (safeboxQuote - safeBoxKey.lockingCredit);
            //                safeBoxKey.lockingCredit = safeboxQuote.toUint96();
            //            }

            //            uint8 oldVipLevel = safeBoxKey.vipLevel;
            //            if (newVipLevel > oldVipLevel) {
            //                safeBoxKey.vipLevel = newVipLevel;
            //                --vipLevelDiffs[oldVipLevel];
            //                ++vipLevelDiffs[newVipLevel];
            //            }

            //            if (info.isInfinite) {
            //                safeBox.expiryTs = 0;
            //                ++info.infiniteCnt;
            //            } else {
            uint256 newExpiryTs = safeBox.expiryTs + newRentalDays;
            safeBox.expiryTs = uint32(newExpiryTs);
            //            }

            //keys[idx] = SafeBoxLib.encodeSafeBoxKey(safeBoxKey);
            keys[idx] = safeBox.keyId;

            unchecked {
                ++idx;
            }
        }

        //        if (info.isInfinite) {
        //            collectionState.infiniteCnt = info.infiniteCnt;
        //        } else {
        //            collectionState.countingBuckets.batchSet(info.currentBucket, buckets);
        //            if (info.newExpiryBucket > collectionState.lastUpdatedBucket) {
        //                collectionState.lastUpdatedBucket = uint64(info.newExpiryBucket);
        //            }
        //        }
        return (/*vipLevelDiffs, info.newRequireLockCredit,*/ keys);
    }

    //    function updateCountersAndGetSafeboxCredit(
    //        uint256[] memory counters,
    //        LockInfo memory lockInfo,
    //        uint8 vipLevel
    //    ) private pure returns (uint256 result) {
    //        unchecked {
    //            uint256 infiniteCnt = lockInfo.infiniteCnt;
    //            uint256 totalManaged = lockInfo.totalManaged;
    //
    //            uint256 counterOffsetEnd = (counters.length + 1) * 0x20;
    //            uint256 tmpCount;
    //            if (lockInfo.isInfinite) {
    //                for (uint256 i = 0x20; i < counterOffsetEnd; i += 0x20) {
    //                    assembly {
    //                        tmpCount := mload(add(counters, i))
    //                    }
    //                    result += Constants.getRequiredStakingForLockRatio(infiniteCnt + tmpCount, totalManaged);
    //                }
    //            } else {
    //                for (uint256 i = 0x20; i < counterOffsetEnd; i += 0x20) {
    //                    assembly {
    //                        tmpCount := mload(add(counters, i))
    //                    }
    //                    result += Constants.getRequiredStakingForLockRatio(infiniteCnt + tmpCount, totalManaged);
    //                    assembly {
    //                        /// increase counters[i]
    //                        mstore(add(counters, i), add(tmpCount, 1))
    //                    }
    //                }
    //                result = Constants.getVipRequiredStakingWithDiscount(result, vipLevel);
    //            }
    //        }
    //    }

    //    function removeExpiredKeysAndRestoreCredits(
    //        CollectionState storage collectionState,
    //        UserFloorAccount storage userAccount,
    //        address collectionId,
    //        uint256[] memory nftIds,
    //        address onBehalfOf
    //    ) public /*returns (uint256 releasedCredit) */ {
    //        CollectionAccount storage collectionAccount = userAccount.getByKey(collectionId);
    //
    //        uint256 removedCnt;
    //        uint256[] memory removedIds = new uint256[](nftIds.length);
    //        uint256[] memory removedKeys = new uint256[](nftIds.length);
    //        for (uint256 i = 0; i < nftIds.length; ) {
    //            uint256 nftId = nftIds[i];
    //            SafeBoxKey memory safeBoxKey = collectionAccount.getByKey(nftId);
    //            SafeBox memory safeBox = collectionState.safeBoxes[nftId];
    //
    //            if (safeBoxKey.keyId == 0) {
    //                revert Errors.InvalidParam();
    //            }
    //
    //            if (safeBox._isSafeBoxExpired() || !safeBox._isKeyMatchingSafeBox(safeBoxKey)) {
    //                removedIds[removedCnt] = nftId;
    //                removedKeys[removedCnt] = SafeBoxLib.encodeSafeBoxKey(safeBoxKey);
    //
    //                unchecked {
    //                    ++removedCnt;
    //                    //                    releasedCredit += safeBoxKey.lockingCredit;
    //                }
    //
    //                // userAccount.updateVipKeyCount(safeBoxKey.vipLevel, -1);
    //                collectionAccount.removeSafeboxKey(nftId);
    //            }
    //
    //            unchecked {
    //                ++i;
    //            }
    //        }
    //
    //        //        if (releasedCredit > 0) {
    //        //            collectionAccount.totalLockingCredit -= releasedCredit.toUint96();
    //        //        }
    //
    //        emit RemoveExpiredKey(msg.sender, onBehalfOf, collectionId, removedIds, removedKeys);
    //    }

    function tidyExpiredNFTs(CollectionState storage collection, uint256[] memory nftIds, address collectionId) public {
        uint256 nftLen = nftIds.length;

        for (uint256 i; i < nftLen; ) {
            uint256 nftId = nftIds[i];
            SafeBox storage safeBox = Helper.useSafeBox(collection, nftId);
            if (!safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasNotExpire();
            // todo If auctions are enabled in the future, this line of code should be retained
            // if (!Helper.isAuctionPeriodOver(safeBox)) revert Errors.AuctionHasNotCompleted();

            /// remove expired safeBox, and dump it to vault
            removeSafeBox(collection, nftId);
            collection.freeTokenIds.push(nftId);

            unchecked {
                ++i;
            }
        }

        emit ExpiredNftToVault(msg.sender, collectionId, nftIds);
    }

    function claimRandomNFT(
        CollectionState storage collection,
        //        UserFloorAccount storage userAccount,
        address creditToken,
        address collectionId,
        uint256 claimCnt,
        //        uint256 maxCreditCost,
        address receiver
    ) public /*returns (uint256 totalCreditCost)*/ {
        creditToken;
        if (claimCnt == 0 || collection.freeTokenIds.length < claimCnt) revert Errors.ClaimableNftInsufficient();

        uint256 freeAmount = collection.freeTokenIds.length;
        uint256 totalManaged = collection.activeSafeBoxCnt + freeAmount;

        // todo Should this function limit the number of redemptions each time?
        /// when locking ratio greater than xx%, stop random redemption
        //        if (
        //            Helper.calculateLockingRatioRaw(freeAmount - claimCnt, totalManaged - claimCnt) >=
        //            Constants.VAULT_REDEMPTION_MAX_LOKING_RATIO
        //        ) {
        //            revert Errors.ClaimableNftInsufficient();
        //        }

        uint256[] memory selectedTokenIds = new uint256[](claimCnt);

        while (claimCnt > 0) {
            //            totalCreditCost += Constants.getClaimCost(Helper.calculateLockingRatioRaw(freeAmount, totalManaged));

            /// just compute a deterministic random number
            uint256 chosenNftIdx = uint256(
                // keccak256(abi.encodePacked(block.timestamp, block.prevrandao, totalManaged))
                keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), totalManaged))
            ) % collection.freeTokenIds.length;

            unchecked {
                --claimCnt;
                --totalManaged;
                --freeAmount;
            }

            selectedTokenIds[claimCnt] = collection.freeTokenIds[chosenNftIdx];

            collection.freeTokenIds[chosenNftIdx] = collection.freeTokenIds[collection.freeTokenIds.length - 1];
            collection.freeTokenIds.pop();
        }

        //        {
        //            /// calculate cost with waiver quota
        //            uint8 vipLevel = Constants.getVipLevel(userAccount.tokenBalance(creditToken));
        //            uint96 waiverUsed = Helper.updateUserCreditWaiver(userAccount);
        //            (totalCreditCost, userAccount.creditWaiverUsed) = Constants.getVipClaimCostWithDiscount(
        //                totalCreditCost,
        //                vipLevel,
        //                waiverUsed
        //            );
        //        }

        //        if (totalCreditCost > maxCreditCost) {
        //            revert Errors.InsufficientCredit();
        //        }

        // userAccount.transferToken(userAccounts[address(this)], creditToken, totalCreditCost, true);
        collection.fragmentToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * selectedTokenIds.length);
        ERC721Transfer.safeBatchTransferFrom(collectionId, address(this), receiver, selectedTokenIds);

        emit ClaimRandomNft(msg.sender, receiver, collectionId, selectedTokenIds);
    }

    //    function getLockingBuckets(
    //        CollectionState storage collection,
    //        uint256 startTimestamp,
    //        uint256 endTimestamp
    //    ) public view returns (uint256[] memory) {
    //        return
    //            Helper.prepareBucketUpdate(
    //                collection,
    //                Helper.counterStamp(startTimestamp),
    //                Math.min(collection.lastUpdatedBucket, Helper.counterStamp(endTimestamp))
    //            );
    //    }

    function addSafeBox(CollectionState storage collectionState, uint256 nftId, SafeBox memory safeBox) internal {
        if (collectionState.safeBoxes[nftId].keyId > 0) revert Errors.SafeBoxAlreadyExist();
        collectionState.safeBoxes[nftId] = safeBox;
        ++collectionState.activeSafeBoxCnt;
    }

    function removeSafeBox(CollectionState storage collectionState, uint256 nftId) internal {
        delete collectionState.safeBoxes[nftId];
        --collectionState.activeSafeBoxCnt;
    }

    function transferSafeBox(CollectionState storage collectionState, SafeBox storage safeBox, address to) internal {
        // Shh - currently unused
        collectionState.keyIdNft;
        //address from=safeBox.owner;
        safeBox.owner = to;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../Constants.sol";
import "../Errors.sol";
import "./SafeBox.sol";
import "./User.sol";
import {SafeBox, CollectionState, AuctionInfo, PrivateOffer} from "./Structs.sol";

//import "../library/RollingBuckets.sol";

library Helper {
    using SafeBoxLib for SafeBox;

    //    using UserLib for CollectionAccount;

    //    using RollingBuckets for mapping(uint256 => uint256);

    //    function counterStamp(uint256 timestamp) internal pure returns (uint96) {
    //        unchecked {
    //            return uint96((timestamp + Constants.BUCKET_SPAN_1) / Constants.BUCKET_SPAN);
    //        }
    //    }

    //    function checkAndUpdateSafeboxPeriodQuota(
    //        UserFloorAccount storage account,
    //        uint8 vipLevel,
    //        uint16 newLocked
    //    ) internal {
    //        uint16 used = updateUserSafeboxQuota(account);
    //        uint16 totalQuota = Constants.getSafeboxPeriodQuota(vipLevel);
    //
    //        uint16 nextUsed = used + newLocked;
    //        if (nextUsed > totalQuota) revert Errors.PeriodQuotaExhausted();
    //
    //        account.safeboxQuotaUsed = nextUsed;
    //    }

    //    function checkSafeboxUserQuota(UserFloorAccount storage account, uint8 vipLevel, uint256 newLocked) internal view {
    //        uint256 totalQuota = Constants.getSafeboxUserQuota(vipLevel);
    //        if (totalQuota < newLocked) {
    //            revert Errors.UserQuotaExhausted();
    //        } else {
    //            unchecked {
    //                totalQuota -= newLocked;
    //            }
    //        }

    //        (, uint256[] memory keyCnts) = UserLib.getMinLevelAndVipKeyCounts(account.vipInfo);
    //        for (uint256 i; i < Constants.VIP_LEVEL_COUNT; ) {
    //            if (totalQuota >= keyCnts[i]) {
    //                totalQuota -= keyCnts[i];
    //            } else {
    //                revert Errors.UserQuotaExhausted();
    //            }
    //            unchecked {
    //                ++i;
    //            }
    //        }
    //    }

    //    function ensureProxyVipLevel(uint8 vipLevel, bool proxy) internal pure {
    //        if (proxy && vipLevel < Constants.PROXY_COLLECTION_VIP_THRESHOLD) {
    //            revert Errors.InvalidParam();
    //        }
    //    }

    //    function ensureMaxLocking(
    //        CollectionState storage collection,
    //        uint8 vipLevel,
    //        uint256 requireExpiryTs,
    //        uint256 requireLockCnt,
    //        bool extend
    //    ) internal view {
    //        /// vip level 0 can not use safebox utilities.
    //        //        if (vipLevel >= Constants.VIP_LEVEL_COUNT || vipLevel == 0) {
    //        //            revert Errors.InvalidParam();
    //        //        }
    //
    //        uint256 lockingRatio = calculateLockingRatio(collection, requireLockCnt);
    //        uint256 restrictRatio;
    //        if (extend) {
    //            /// try to extend exist safebox
    //            /// only restrict infinity locking, normal safebox with expiry should be skipped
    //            restrictRatio = requireExpiryTs == 0 ? Constants.getLockingRatioForInfinite(vipLevel) : 100;
    //        } else {
    //            /// try to lock(create new safebox)
    //            /// restrict maximum locking ratio to use safebox
    //            restrictRatio = Constants.getLockingRatioForSafebox(vipLevel);
    //            if (requireExpiryTs == 0) {
    //                uint256 extraRatio = Constants.getLockingRatioForInfinite(vipLevel);
    //                if (restrictRatio > extraRatio) restrictRatio = extraRatio;
    //            }
    //        }
    //
    //        if (lockingRatio > restrictRatio) revert Errors.InvalidParam();
    //
    //        /// only check when it is not infinite lock
    //        if (requireExpiryTs > 0) {
    //            //            uint256 deltaBucket;
    //            //            unchecked {
    //            //                deltaBucket = counterStamp(requireExpiryTs) - counterStamp(block.timestamp);
    //            //            }
    //            //            if (deltaBucket == 0 || deltaBucket > Constants.getVipLockingBuckets(vipLevel)) {
    //            //                revert Errors.InvalidParam();
    //            //            }
    //        }
    //    }

    // todo Check if the safeBox is still within the validity period and verify if the owner is consistent
    function useSafeBoxAndKey(
        CollectionState storage collection,
        address userAccount,
        uint256 nftId
    ) internal view returns (SafeBox storage safeBox /*, SafeBoxKey storage key*/) {
        safeBox = collection.safeBoxes[nftId];
        if (safeBox.keyId == 0) revert Errors.SafeBoxNotExist();
        if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();
        if (safeBox.owner != userAccount) {
            revert Errors.NoMatchingSafeBoxKey();
        }
        //        key = userAccount.getByKey(nftId);
        //        if (!safeBox.isKeyMatchingSafeBox(key)) revert Errors.NoMatchingSafeBoxKey();
    }

    function useSafeBox(
        CollectionState storage collection,
        uint256 nftId
    ) internal view returns (SafeBox storage safeBox) {
        safeBox = collection.safeBoxes[nftId];
        if (safeBox.keyId == 0) revert Errors.SafeBoxNotExist();
    }

    function generateNextKeyId(CollectionState storage collectionState) internal returns (uint64 nextKeyId) {
        nextKeyId = collectionState.nextKeyId;
        ++collectionState.nextKeyId;
    }

    function generateNextActivityId(CollectionState storage collection) internal returns (uint64 nextActivityId) {
        nextActivityId = collection.nextActivityId;
        ++collection.nextActivityId;
    }

    function isAuctionPeriodOver(SafeBox storage safeBox) internal view returns (bool) {
        return safeBox.expiryTs + Constants.FREE_AUCTION_PERIOD < block.timestamp;
    }

    function hasActiveActivities(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return
            hasActiveAuction(collection, nftId) ||
            hasActiveRaffle(collection, nftId) ||
            hasActivePrivateOffer(collection, nftId) ||
            hasActiveListOffer(collection, nftId);
    }

    function hasActiveAuction(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activeAuctions[nftId].endTime >= block.timestamp;
    }

    function hasActiveRaffle(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        // todo For the raffle, an end time needs to be set
        return collection.activeRaffles[nftId].endTime >= block.timestamp;
    }

    function hasActivePrivateOffer(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        // todo Do not need to set an end time for the order, first check the validity period of the SafeBox, and then verify if it is active
        // return collection.activePrivateOffers[nftId].endTime >= block.timestamp;
        return
            collection.safeBoxes[nftId].expiryTs >= block.timestamp &&
            collection.activePrivateOffers[nftId].owner != address(0);
    }

    function hasActiveListOffer(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        PrivateOffer storage offer = collection.activePrivateOffers[nftId];
        return offer.activityId > 0 && offer.buyer == address(0) && !useSafeBox(collection, nftId).isSafeBoxExpired();
    }

    function getTokenFeeRateBips(
        address creditToken,
        address fragmentToken,
        address settleToken
    ) internal pure returns (uint256) {
        uint256 feeRateBips = Constants.COMMON_FEE_RATE_BIPS;
        if (settleToken == creditToken) {
            feeRateBips = Constants.CREDIT_FEE_RATE_BIPS;
        } else if (settleToken == fragmentToken) {
            feeRateBips = Constants.SPEC_FEE_RATE_BIPS;
        }

        return feeRateBips;
    }

    function calculateActivityFee(
        uint256 settleAmount,
        uint256 feeRateBips
    ) internal pure returns (uint256 afterFee, uint256 fee) {
        fee = (settleAmount * feeRateBips) / 10000;
        unchecked {
            afterFee = settleAmount - fee;
        }
    }

    //    function prepareBucketUpdate(
    //        CollectionState storage collection,
    //        uint256 startBucket,
    //        uint256 endBucket
    //    ) internal view returns (uint256[] memory buckets) {
    //        uint256 validEnd = collection.lastUpdatedBucket;
    //        uint256 padding;
    //        if (endBucket < validEnd) {
    //            validEnd = endBucket;
    //        } else {
    //            unchecked {
    //                padding = endBucket - validEnd;
    //            }
    //        }
    //
    //        if (startBucket < validEnd) {
    //            if (padding == 0) {
    //                buckets = collection.countingBuckets.batchGet(startBucket, validEnd);
    //            } else {
    //                uint256 validLen;
    //                unchecked {
    //                    validLen = validEnd - startBucket;
    //                }
    //                buckets = new uint256[](validLen + padding);
    //                uint256[] memory tmp = collection.countingBuckets.batchGet(startBucket, validEnd);
    //                for (uint256 i; i < validLen; ) {
    //                    buckets[i] = tmp[i];
    //                    unchecked {
    //                        ++i;
    //                    }
    //                }
    //            }
    //        } else {
    //            buckets = new uint256[](endBucket - startBucket);
    //        }
    //    }
    //
    //    function getActiveSafeBoxes(
    //        CollectionState storage collectionState,
    //        uint256 timestamp
    //    ) internal view returns (uint256) {
    //        uint256 bucketStamp = counterStamp(timestamp);
    //        if (collectionState.lastUpdatedBucket < bucketStamp) {
    //            return 0;
    //        }
    //        return collectionState.countingBuckets.get(bucketStamp);
    //    }

    function calculateLockingRatio(
        CollectionState storage collection,
        uint256 newLocked
    ) internal view returns (uint256) {
        uint256 freeAmount = collection.freeTokenIds.length;
        uint256 totalManaged = newLocked + collection.activeSafeBoxCnt + freeAmount;
        return calculateLockingRatioRaw(freeAmount, totalManaged);
    }

    function calculateLockingRatioRaw(uint256 freeAmount, uint256 totalManaged) internal pure returns (uint256) {
        if (totalManaged == 0) {
            return 0;
        } else {
            unchecked {
                return (100 - (freeAmount * 100) / totalManaged);
            }
        }
    }

    //    function updateUserCreditWaiver(UserFloorAccount storage account) internal returns (uint96) {
    //        if (block.timestamp - account.lastWaiverPeriodTs <= Constants.USER_REDEMPTION_WAIVER_REFRESH_DURATION) {
    //            return account.creditWaiverUsed;
    //        } else {
    //            unchecked {
    //                account.lastWaiverPeriodTs = uint32(
    //                    (block.timestamp / Constants.USER_REDEMPTION_WAIVER_REFRESH_DURATION) *
    //                        Constants.USER_REDEMPTION_WAIVER_REFRESH_DURATION
    //                );
    //            }
    //            account.creditWaiverUsed = 0;
    //            return 0;
    //        }
    //    }
    //
    //    function updateUserSafeboxQuota(UserFloorAccount storage account) internal returns (uint16) {
    //        if (block.timestamp - account.lastQuotaPeriodTs <= Constants.USER_SAFEBOX_QUOTA_REFRESH_DURATION) {
    //            return account.safeboxQuotaUsed;
    //        } else {
    //            unchecked {
    //                account.lastQuotaPeriodTs = uint32(
    //                    (block.timestamp / Constants.USER_SAFEBOX_QUOTA_REFRESH_DURATION) *
    //                        Constants.USER_SAFEBOX_QUOTA_REFRESH_DURATION
    //                );
    //            }
    //            account.safeboxQuotaUsed = 0;
    //            return 0;
    //        }
    //    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import "../Errors.sol";
import "../interface/IScattering.sol";
//import "../library/RollingBuckets.sol";
import {SafeBox, CollectionState, PrivateOffer} from "./Structs.sol";
import {SafeBoxLib} from "./SafeBox.sol";
import "./User.sol";
import "./Helper.sol";
import "./Collection.sol";

library PrivateOfferLib {
    using SafeBoxLib for SafeBox;
    //    using RollingBuckets for mapping(uint256 => uint256);
    using UserLib for UserFloorAccount;
    //    using UserLib for CollectionAccount;
    using Helper for CollectionState;
    using CollectionLib for CollectionState;

    // todo: event should be moved to Interface as far as Solidity 0.8.22 ready.
    // https://github.com/ethereum/solidity/pull/14274
    // https://github.com/ethereum/solidity/issues/14430
    event PrivateOfferStarted(
        address indexed seller,
        address indexed buyer,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        address settleToken,
        uint96 price,
        //        uint256 offerEndTime,
        //        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event PrivateOfferCanceled(
        address indexed operator,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds
    );

    event PrivateOfferAccepted(
        address indexed buyer,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint256[] safeBoxKeyIds
    );

    struct PrivateOfferSettlement {
        //        SafeBoxKey safeBoxKey;
        uint256 keyId;
        uint256 nftId;
        address token;
        uint128 collectedFund;
        address seller;
        address buyer;
    }

    function ownerInitPrivateOffers(
        CollectionState storage collection,
        //        mapping(address => UserFloorAccount) storage userAccounts,
        address creditToken,
        IScattering.PrivateOfferInitParam memory param
    ) public {
        creditToken;
        if (param.receiver == msg.sender) revert Errors.InvalidParam();
        /// if receiver is none, means list and anyone can buy it
        if (param.receiver == address(0)) {
            return startListOffer(collection, /*userAccounts,*/ param);
        }

        PrivateOffer memory offerTemplate = PrivateOffer({
            activityId: 0,
            token: param.token,
            price: param.price,
            owner: msg.sender,
            buyer: param.receiver
        });

        uint64[] memory offerActivityIds /*, uint96 offerEndTime, uint192 safeBoxExpiryTs*/ = _ownerInitPrivateOffers(
            collection,
            //            userAccount.getByKey(param.collection),
            param.nftIds,
            offerTemplate
        );

        emit PrivateOfferStarted(
            msg.sender,
            param.receiver,
            param.collection,
            offerActivityIds,
            param.nftIds,
            param.token,
            param.price,
            //            offerEndTime,
            //            safeBoxExpiryTs,
            0
        );
    }

    function _ownerInitPrivateOffers(
        CollectionState storage collection,
        //        CollectionAccount storage userAccount,
        uint256[] memory nftIds,
        PrivateOffer memory offerTemplate
    ) private returns (uint64[] memory offerActivityIds /*, uint96 offerEndTime, uint32 safeBoxExpiryTs*/) {
        //        offerEndTime = uint96(block.timestamp + Constants.PRIVATE_OFFER_DURATION);
        //        safeBoxExpiryTs = uint32(offerEndTime + Constants.PRIVATE_OFFER_COMPLETE_GRACE_DURATION);
        //        uint256 nowBucketCnt = Helper.counterStamp(block.timestamp);

        //        uint256[] memory toUpdateBucket;
        //        if (param.maxExpiry > 0) {
        //            toUpdateBucket = collection.countingBuckets.batchGet(
        //                nowBucketCnt,
        //                Math.min(collection.lastUpdatedBucket, Helper.counterStamp(param.maxExpiry))
        //            );
        //        }

        uint256 nftLen = nftIds.length;
        offerActivityIds = new uint64[](nftLen);
        //        uint256 firstIdx = Helper.counterStamp(safeBoxExpiryTs) - nowBucketCnt;
        for (uint256 i; i < nftLen; ) {
            uint256 nftId = nftIds[i];
            if (collection.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            /// dummy check
            collection.useSafeBoxAndKey(msg.sender, nftId);

            //            if (safeBox.isInfiniteSafeBox()) {
            //                --collection.infiniteCnt;
            //            } else {
            //                uint256 oldExpiryTs = safeBox.expiryTs;
            //                if (oldExpiryTs < safeBoxExpiryTs) {
            //                    revert Errors.InvalidParam();
            //                }
            //                uint256 lastIdx = Helper.counterStamp(oldExpiryTs) - nowBucketCnt;
            //                if (firstIdx > lastIdx || lastIdx > toUpdateBucket.length) revert Errors.InvalidParam();
            //                for (uint256 k = firstIdx; k < lastIdx; ) {
            //                    --toUpdateBucket[k];
            //                    unchecked {
            //                        ++k;
            //                    }
            //                }
            //            }

            //            safeBox.expiryTs = safeBoxExpiryTs;
            //            offerActivityIds[i] = collection.generateNextActivityId();
            offerTemplate.activityId = collection.generateNextActivityId();
            collection.activePrivateOffers[nftId] = offerTemplate;
            offerActivityIds[i] = offerTemplate.activityId;
            //            collection.activePrivateOffers[nftId] = PrivateOffer({
            //                //                endTime: safeBox.expiryTs,
            //                owner: msg.sender,
            //                buyer: param.receiver,
            //                token: param.token,
            //                price: param.price,
            //                activityId: offerActivityIds[i]
            //            });

            unchecked {
                ++i;
            }
        }
        //        if (toUpdateBucket.length > 0) {
        //            collection.countingBuckets.batchSet(nowBucketCnt, toUpdateBucket);
        //        }
    }

    function startListOffer(
        CollectionState storage collection,
        //        mapping(address => UserFloorAccount) storage userAccounts,
        IScattering.PrivateOfferInitParam memory param
    ) internal {
        //        if (feeConf.safeboxFee.receipt == address(0)) revert Errors.TokenNotSupported();

        PrivateOffer memory template = PrivateOffer({
            activityId: 0,
            token: param.token,
            price: param.price,
            owner: msg.sender,
            buyer: address(0)
        });
        //        CollectionAccount storage ownerCollection = userAccounts[msg.sender].getByKey(param.collection);

        uint64[] memory activityIds = new uint64[](param.nftIds.length);
        for (uint256 i; i < param.nftIds.length; ) {
            uint256 nftId = param.nftIds[i];
            if (collection.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            /// dummy check
            collection.useSafeBoxAndKey(msg.sender, nftId);

            template.activityId = Helper.generateNextActivityId(collection);
            collection.activePrivateOffers[nftId] = template;

            activityIds[i] = template.activityId;
            unchecked {
                ++i;
            }
        }

        emit PrivateOfferStarted(
            msg.sender,
            address(0), // buyer no restrictions
            param.collection,
            activityIds,
            param.nftIds,
            param.token,
            param.price,
            0
        );
    }

    function removePrivateOffers(
        CollectionState storage collection,
        address collectionId,
        uint256[] memory nftIds
    ) public {
        uint64[] memory offerActivityIds = new uint64[](nftIds.length);
        for (uint256 i; i < nftIds.length; ) {
            uint256 nftId = nftIds[i];
            PrivateOffer storage offer = collection.activePrivateOffers[nftId];
            if (offer.owner != msg.sender && offer.buyer != msg.sender) revert Errors.NoPrivilege();

            offerActivityIds[i] = offer.activityId;
            delete collection.activePrivateOffers[nftId];

            unchecked {
                ++i;
            }
        }

        emit PrivateOfferCanceled(msg.sender, collectionId, offerActivityIds, nftIds);
    }

    function buyerAcceptPrivateOffers(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address collectionId,
        uint256[] memory nftIds,
        address creditToken
    ) public {
        (PrivateOfferSettlement[] memory settlements, uint64[] memory activityIds) = _buyerAcceptPrivateOffers(
            collection,
            nftIds
        );

        uint256 totalCost;
        uint256[] memory safeBoxKeyIds = new uint256[](settlements.length);
        uint256 settlementLen = settlements.length;
        for (uint256 i; i < settlementLen; ) {
            PrivateOfferSettlement memory settlement = settlements[i];

            //            UserFloorAccount storage buyerAccount = userAccounts[settlement.buyer];
            //            CollectionAccount storage buyerCollectionAccount = buyerAccount.getByKey(collectionId);

            //            buyerCollectionAccount.addSafeboxKey(settlement.nftId, settlement.safeBoxKey);

            //            UserFloorAccount storage sellerAccount = userAccounts[settlement.seller];
            //            CollectionAccount storage sellerCollectionAccount = sellerAccount.getByKey(collectionId);
            //            sellerCollectionAccount.removeSafeboxKey(settlement.nftId);
            if (settlement.collectedFund > 0) {
                totalCost += settlement.collectedFund;
            }

            safeBoxKeyIds[i] = settlement.keyId;

            unchecked {
                ++i;
            }
        }

        if (totalCost > 0 && settlementLen > 0) {
            // @notice todo The 'settlement.token' must ensure that all settlement tokens are the same when the user creates them, so it cannot be too personalized.
            PrivateOfferSettlement memory settlement = settlements[0];
            UserFloorAccount storage buyerAccount = userAccounts[settlement.buyer];
            UserFloorAccount storage sellerAccount = userAccounts[settlement.seller];
            address settleToken = settlement.token;
            uint256 protocolFee = (totalCost * Constants.OFFER_FEE_RATE_BIPS) / 10_000;
            uint256 priceWithoutFee;
            unchecked {
                priceWithoutFee = totalCost - protocolFee;
            }
            // @notice todo Future support for royalty NFTs, paying attention to the receiving token and taxes.
            buyerAccount.transferToken(
                userAccounts[address(this)],
                settleToken,
                protocolFee,
                settleToken == creditToken
            );
            buyerAccount.transferToken(sellerAccount, settleToken, priceWithoutFee, settleToken == creditToken);
        }
        emit PrivateOfferAccepted(msg.sender, collectionId, activityIds, nftIds, safeBoxKeyIds);
    }

    function _buyerAcceptPrivateOffers(
        CollectionState storage collection,
        uint256[] memory nftIds
    ) private returns (PrivateOfferSettlement[] memory settlements, uint64[] memory offerActivityIds) {
        uint256 nftLen = nftIds.length;
        settlements = new PrivateOfferSettlement[](nftLen);
        offerActivityIds = new uint64[](nftLen);
        for (uint256 i; i < nftLen; ) {
            uint256 nftId = nftIds[i];
            // todo Use 'buyer' to distinguish between public and private offer.
            if (!Helper.hasActiveListOffer(collection, nftId) && !Helper.hasActivePrivateOffer(collection, nftId)) {
                revert Errors.ActivityNotExist();
            }
            PrivateOffer storage offer = collection.activePrivateOffers[nftId];
            //if (offer.endTime <= block.timestamp) revert Errors.ActivityHasExpired();
            // todo when buyer!=zero addr, buyer must == msg.sender
            if (offer.buyer != address(0) && offer.buyer != msg.sender) revert Errors.NoPrivilege();
            if (offer.owner == msg.sender) revert Errors.NoPrivilege();

            SafeBox storage safeBox = collection.useSafeBox(nftId);
            /// this revert couldn't happen but just leaving it (we have checked offer'EndTime before)
            if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

            // safeBox.owner = msg.sender;
            collection.transferSafeBox(safeBox, msg.sender);

            settlements[i] = PrivateOfferSettlement({
                keyId: safeBox.keyId,
                nftId: nftId,
                seller: offer.owner,
                buyer: msg.sender,
                token: offer.token,
                collectedFund: offer.price
            });
            offerActivityIds[i] = offer.activityId;

            delete collection.activePrivateOffers[nftId];

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SafeBox} from "./Structs.sol";

library SafeBoxLib {
    uint64 public constant SAFEBOX_KEY_NOTATION = type(uint64).max;

    //    function isInfiniteSafeBox(SafeBox storage safeBox) internal view returns (bool) {
    //        return safeBox.expiryTs == 0;
    //    }

    function isSafeBoxExpired(SafeBox storage safeBox) internal view returns (bool) {
        return safeBox.expiryTs != 0 && safeBox.expiryTs < block.timestamp;
    }

    function _isSafeBoxExpired(SafeBox memory safeBox) internal view returns (bool) {
        return safeBox.expiryTs != 0 && safeBox.expiryTs < block.timestamp;
    }

    //    function isKeyMatchingSafeBox(SafeBox storage safeBox, SafeBoxKey storage safeBoxKey) internal view returns (bool) {
    //        return safeBox.keyId == safeBoxKey.keyId;
    //    }

    //    function _isKeyMatchingSafeBox(SafeBox memory safeBox, SafeBoxKey memory safeBoxKey) internal pure returns (bool) {
    //        return safeBox.keyId == safeBoxKey.keyId;
    //    }

    //    function encodeSafeBoxKey(SafeBoxKey memory key) internal pure returns (uint256) {
    //                uint256 val = key.lockingCredit;
    //                val |= (uint256(key.keyId) << 96);
    //                val |= (uint256(key.vipLevel) << 160);
    //                return val;
    //    }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
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