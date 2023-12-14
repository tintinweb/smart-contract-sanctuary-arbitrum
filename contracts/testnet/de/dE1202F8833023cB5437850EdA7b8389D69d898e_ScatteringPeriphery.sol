// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

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

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract OwnedUpgradeable {
    error Unauthorized();

    event OwnerUpdated(address indexed user, address indexed newOwner);

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    function __Owned_init() internal {
        owner = msg.sender;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }

    uint256[49] private __gap;
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

import "./interface/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory) {
        bytes[] memory results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            /// @custom:oz-upgrades-unsafe-allow-reachable delegatecall
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (success) {
                results[i] = result;
            } else {
                // Next 4 lines from
                // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/AddressUpgradeable.sol#L229
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert FailedMulticall();
                }
            }

            unchecked {
                ++i;
            }
        }

        return results;
    }

    function extMulticall(CallData[] calldata calls) external virtual override returns (bytes[] memory) {
        return multicall2(calls);
    }

    /// @notice Aggregate calls, ensuring each returns success if required
    /// @param calls An array of CallData structs
    /// @return returnData An array of bytes
    function multicall2(CallData[] calldata calls) internal returns (bytes[] memory) {
        bytes[] memory results = new bytes[](calls.length);
        CallData calldata calli;
        for (uint256 i = 0; i < calls.length; ) {
            calli = calls[i];
            (bool success, bytes memory result) = calli.target.call(calli.callData);
            if (success) {
                results[i] = result;
            } else {
                // Next 4 lines from
                // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/AddressUpgradeable.sol#L229
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert FailedMulticall();
                }
            }

            unchecked {
                ++i;
            }
        }
        return results;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/IScattering.sol";
import "./Constants.sol";
import {TicketRecord, SafeBox} from "./logic/Structs.sol";

contract ScatteringGetter {
    ///  @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IScattering public immutable _scattering;

    uint256 public constant COLLECTION_STATES_SLOT = 101;
    uint256 public constant USER_ACCOUNTS_SLOT = 102;
    uint256 public constant SUPPORTED_TOKENS_SLOT = 103;
    uint256 public constant COLLECTION_PROXY_SLOT = 104;

    uint256 public constant MASK_32 = (1 << 32) - 1;
    uint256 public constant MASK_48 = (1 << 48) - 1;
    uint256 public constant MASK_64 = (1 << 64) - 1;
    uint256 public constant MASK_96 = (1 << 96) - 1;
    uint256 public constant MASK_128 = (1 << 128) - 1;
    uint256 public constant MASK_160 = (1 << 160) - 1;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address scattering) {
        _scattering = IScattering(scattering);
    }

    function supportedToken(address token) public view returns (bool) {
        uint256 val = uint256(_scattering.extsload(keccak256(abi.encode(token, SUPPORTED_TOKENS_SLOT))));

        return val != 0;
    }

    function collectionProxy(address proxy) public view returns (address) {
        address underlying = address(
            uint160(uint256(_scattering.extsload(keccak256(abi.encode(proxy, COLLECTION_PROXY_SLOT)))))
        );
        return underlying;
    }

    function fragmentTokenOf(address collection) public view returns (address token) {
        bytes32 val = _scattering.extsload(keccak256(abi.encode(collection, COLLECTION_STATES_SLOT)));
        assembly {
            token := val
        }
    }

    function collectionInfo(
        address collection
    )
        public
        view
        returns (
            address fragmentToken,
            address keyIdNft,
            uint256 freeNftLength,
            uint64 activeSafeBoxCnt,
            uint64 nextKeyId,
            uint64 nextActivityId
        )
    {
        // bytes32 to type bytes memory
        bytes memory val = _scattering.extsload(keccak256(abi.encode(collection, COLLECTION_STATES_SLOT)), 8);

        assembly {
            fragmentToken := mload(add(val, 0x20))
            keyIdNft := mload(add(val, mul(2, 0x20)))
            freeNftLength := mload(add(val, mul(3, 0x20)))

            let cntVal := mload(add(val, mul(8, 0x20)))
            activeSafeBoxCnt := and(cntVal, MASK_64)
            nextKeyId := and(shr(64, cntVal), MASK_64)
            nextActivityId := and(shr(128, cntVal), MASK_64)
        }
    }

    function getFreeNftIds(
        address collection,
        uint256 startIdx,
        uint256 size
    ) public view returns (uint256[] memory nftIds) {
        bytes32 collectionSlot = keccak256(abi.encode(collection, COLLECTION_STATES_SLOT));
        bytes32 nftIdsSlot = bytes32(uint256(collectionSlot) + 2);
        uint256 freeNftLength = uint256(_scattering.extsload(nftIdsSlot));

        if (startIdx >= freeNftLength || size == 0) {
            return nftIds;
        }

        uint256 maxLen = freeNftLength - startIdx;
        if (size < maxLen) {
            maxLen = size;
        }

        bytes memory arrVal = _scattering.extsload(
            bytes32(uint256(keccak256(abi.encode(nftIdsSlot))) + startIdx),
            maxLen
        );

        nftIds = new uint256[](maxLen);
        assembly {
            for {
                let i := 0x20
                let end := mul(add(1, maxLen), 0x20)
            } lt(i, end) {
                i := add(i, 0x20)
            } {
                mstore(add(nftIds, i), mload(add(arrVal, i)))
            }
        }
    }

    function getSafeBox(address collection, uint256 nftId) public view returns (SafeBox memory safeBox) {
        bytes32 collectionSlot = keccak256(abi.encode(underlyingCollection(collection), COLLECTION_STATES_SLOT));
        bytes32 safeBoxMapSlot = bytes32(uint256(collectionSlot) + 3);

        uint256 val = uint256(_scattering.extsload(keccak256(abi.encode(nftId, safeBoxMapSlot))));

        safeBox.keyId = uint64(val & MASK_64);
        safeBox.expiryTs = uint32(val >> 64);
        safeBox.owner = address(uint160(val >> 96));
    }

    function getAuction(
        address collection,
        uint256 nftId
    )
        public
        view
        returns (
            uint96 endTime,
            address bidTokenAddress,
            uint128 minimumBid,
            uint128 lastBidAmount,
            address lastBidder,
            address triggerAddress,
            bool isSelfTriggered,
            uint64 activityId,
            uint32 feeRateBips
        )
    {
        bytes32 collectionSlot = keccak256(abi.encode(underlyingCollection(collection), COLLECTION_STATES_SLOT));
        bytes32 auctionMapSlot = bytes32(uint256(collectionSlot) + 4);

        bytes memory val = _scattering.extsload(keccak256(abi.encode(nftId, auctionMapSlot)), 4);

        assembly {
            let slotVal := mload(add(val, 0x20))
            endTime := and(slotVal, MASK_96)
            bidTokenAddress := shr(96, slotVal)

            slotVal := mload(add(val, 0x40))
            minimumBid := and(slotVal, MASK_96)
            triggerAddress := shr(96, slotVal)

            slotVal := mload(add(val, 0x60))
            lastBidAmount := and(slotVal, MASK_96)
            lastBidder := shr(96, slotVal)

            slotVal := mload(add(val, 0x80))
            isSelfTriggered := and(slotVal, 0xFF)
            activityId := and(shr(8, slotVal), MASK_64)
            feeRateBips := and(shr(72, slotVal), MASK_32)
        }
    }

    function getRaffle(
        address collection,
        uint256 nftId
    )
        public
        view
        returns (
            uint48 endTime,
            uint48 maxTickets,
            address token,
            uint96 ticketPrice,
            uint96 collectedFund,
            uint64 activityId,
            address owner,
            uint48 ticketSold,
            uint32 feeRateBips,
            bool isSettling,
            uint256 ticketsArrLen
        )
    {
        bytes32 raffleMapSlot = bytes32(uint256(keccak256(abi.encode(underlyingCollection(collection), COLLECTION_STATES_SLOT))) + 5);

        bytes memory val = _scattering.extsload(keccak256(abi.encode(nftId, raffleMapSlot)), 4);

        assembly {
            let slotVal := mload(add(val, 0x20))
            endTime := and(slotVal, MASK_48)
            maxTickets := and(shr(48, slotVal), MASK_48)
            token := and(shr(96, slotVal), MASK_160)

            slotVal := mload(add(val, 0x40))
            ticketPrice := and(slotVal, MASK_96)
            collectedFund := and(shr(96, slotVal), MASK_96)
            activityId := and(shr(192, slotVal), MASK_64)

            slotVal := mload(add(val, 0x60))
            owner := and(slotVal, MASK_160)
            ticketSold := and(shr(160, slotVal), MASK_48)
            feeRateBips := and(shr(208, slotVal), MASK_32)
            isSettling := and(shr(240, slotVal), 0xFF)

            ticketsArrLen := mload(add(val, 0x80))
        }
    }

    function getRaffleTicketRecords(
        address collection,
        uint256 nftId,
        uint256 startIdx,
        uint256 size
    ) public view returns (TicketRecord[] memory tickets) {
        bytes32 collectionSlot = keccak256(abi.encode(underlyingCollection(collection), COLLECTION_STATES_SLOT));
        bytes32 raffleMapSlot = bytes32(uint256(collectionSlot) + 5);
        bytes32 ticketRecordsSlot = bytes32(uint256(keccak256(abi.encode(nftId, raffleMapSlot))) + 3);
        uint256 totalRecordsLen = uint256(_scattering.extsload(ticketRecordsSlot));

        if (startIdx >= totalRecordsLen || size == 0) {
            return tickets;
        }

        uint256 maxLen = totalRecordsLen - startIdx;
        if (size < maxLen) {
            maxLen = size;
        }

        bytes memory arrVal = _scattering.extsload(
            bytes32(uint256(keccak256(abi.encode(ticketRecordsSlot))) + startIdx),
            maxLen
        );

        tickets = new TicketRecord[](maxLen);
        for (uint256 i; i < maxLen; ++i) {
            uint256 element;
            assembly {
                element := mload(add(arrVal, mul(add(i, 1), 0x20)))
            }
            tickets[i].buyer = address(uint160(element & MASK_160));
            tickets[i].startIdx = uint48((element >> 160) & MASK_48);
            tickets[i].endIdx = uint48((element >> 208) & MASK_48);
        }
    }

    function getPrivateOffer(
        address collection,
        uint256 nftId
    ) public view returns (address token, uint96 price, address owner, address buyer, uint64 activityId) {
        bytes32 collectionSlot = keccak256(abi.encode(underlyingCollection(collection), COLLECTION_STATES_SLOT));
        bytes32 offerMapSlot = bytes32(uint256(collectionSlot) + 6);

        bytes memory val = _scattering.extsload(keccak256(abi.encode(nftId, offerMapSlot)), 3);

        assembly {
            let slotVal := mload(add(val, 0x20))
            token := and(slotVal, MASK_160)
            price := and(shr(160, slotVal), MASK_96)

            slotVal := mload(add(val, 0x40))
            owner := and(slotVal, MASK_160)

            slotVal := mload(add(val, 0x60))
            buyer := and(slotVal, MASK_160)
            activityId := and(shr(160, slotVal), MASK_64)
        }
    }

    function tokenBalance(address user, address token) public view returns (uint256) {
        bytes32 userSlot = keccak256(abi.encode(user, USER_ACCOUNTS_SLOT));
        bytes32 tokenMapSlot = bytes32(uint256(userSlot));

        bytes32 balance = _scattering.extsload(keccak256(abi.encode(token, tokenMapSlot)));

        return uint256(balance);
    }

    function underlyingCollection(address collection) private view returns (address) {
        address underlying = collectionProxy(collection);
        if (underlying == address(0)) {
            return collection;
        }
        return underlying;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

import {IScattering} from "./interface/IScattering.sol";
import {OwnedUpgradeable} from "./library/OwnedUpgradeable.sol";
import {CurrencyTransfer} from "./library/CurrencyTransfer.sol";
import {ERC721Transfer} from "./library/ERC721Transfer.sol";
import {TicketRecord, SafeBox} from "./logic/Structs.sol";
import "./logic/SafeBox.sol";
import "./Errors.sol";
import "./Constants.sol";
import {ScatteringGetter} from "./ScatteringGetter.sol";
import "./Multicall.sol";
import "./interface/IWETH9.sol";

contract ScatteringPeriphery is ScatteringGetter, OwnedUpgradeable, UUPSUpgradeable, IERC721Receiver, Multicall {
    error NotRouterOrWETH9();
    error InsufficientWETH9();

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable uniswapRouter;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable WETH9;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _scattering, address uniswapV3Router, address _WETH9) ScatteringGetter(_scattering) {
        uniswapRouter = uniswapV3Router;
        WETH9 = _WETH9;
    }

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Owned_init();
        __UUPSUpgradeable_init();
    }

    function fragmentAndSell(
        address collection,
        uint256[] calldata tokenIds,
        bool unwrapWETH,
        ISwapRouter.ExactInputParams memory swapParam
    ) external returns (uint256 swapOut) {
        uint256 fragmentTokenAmount = tokenIds.length * Constants.FLOOR_TOKEN_AMOUNT;

        address fragmentToken = fragmentTokenOf(collection);

        /// approve all
        approveAllERC721(collection, address(_scattering));
        approveAllERC20(fragmentToken, uniswapRouter, fragmentTokenAmount);

        /// transfer tokens into this
        ERC721Transfer.safeBatchTransferFrom(collection, msg.sender, address(this), tokenIds);

        /// fragment
        _scattering.fragmentNFTs(collection, tokenIds, address(this));

        swapOut = ISwapRouter(uniswapRouter).exactInput(swapParam);

        if (unwrapWETH) {
            unwrapWETH9(swapOut, msg.sender);
        }
    }

    function buyAndClaimExpired(
        address collection,
        uint256[] calldata tokenIds,
        uint256 claimCnt,
        address swapTokenIn,
        ISwapRouter.ExactOutputParams memory swapParam
    ) external payable returns (uint256 tokenCost) {
        _scattering.tidyExpiredNFTs(collection, tokenIds);
        return buyAndClaimVault(collection, claimCnt, swapTokenIn, swapParam);
    }

    function buyAndClaimVault(
        address collection,
        uint256 claimCnt,
        address swapTokenIn,
        ISwapRouter.ExactOutputParams memory swapParam
    ) public payable returns (uint256 tokenCost) {
        uint256 fragmentTokenAmount = claimCnt * Constants.FLOOR_TOKEN_AMOUNT;

        address fragmentToken = fragmentTokenOf(collection);

        approveAllERC20(fragmentToken, address(_scattering), fragmentTokenAmount);

        tokenCost = swapExactOutput(msg.sender, swapTokenIn, swapParam);

        _scattering.claimRandomNFT(collection, claimCnt, /* 0, */ msg.sender);
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        if (balanceWETH9 < amountMinimum) {
            revert InsufficientWETH9();
        }

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            CurrencyTransfer.safeTransfer(CurrencyTransfer.NATIVE, recipient, balanceWETH9);
        }
    }

    function swapExactOutput(
        address payer,
        address tokenIn,
        ISwapRouter.ExactOutputParams memory param
    ) internal returns (uint256 amountIn) {
        if (tokenIn == WETH9 && address(this).balance >= param.amountInMaximum) {
            amountIn = ISwapRouter(uniswapRouter).exactOutput{value: param.amountInMaximum}(param);
            IPeripheryPayments(uniswapRouter).refundETH();
            if (address(this).balance > 0) {
                CurrencyTransfer.safeTransfer(CurrencyTransfer.NATIVE, payer, address(this).balance);
            }
        } else {
            approveAllERC20(tokenIn, uniswapRouter, param.amountInMaximum);
            CurrencyTransfer.safeTransferFrom(tokenIn, payer, address(this), param.amountInMaximum);
            amountIn = ISwapRouter(uniswapRouter).exactOutput(param);

            if (param.amountInMaximum > amountIn) {
                CurrencyTransfer.safeTransfer(tokenIn, payer, param.amountInMaximum - amountIn);
            }
        }
    }

    function approveAllERC20(address token, address spender, uint256 desireAmount) private {
        if (desireAmount == 0) {
            return;
        }
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < desireAmount) {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function approveAllERC721(address collection, address spender) private {
        bool approved = IERC721(collection).isApprovedForAll(address(this), spender);
        if (!approved) {
            IERC721(collection).setApprovalForAll(spender, true);
        }
    }

    function onERC721Received(
        address,
        /*operator*/ address,
        /*from*/ uint256,
        /*tokenId*/ bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {
        if (msg.sender != uniswapRouter && msg.sender != WETH9) revert NotRouterOrWETH9();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}