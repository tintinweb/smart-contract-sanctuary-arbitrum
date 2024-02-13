// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interface/IArbSys.sol";

library Constants {
    /// @notice Scattering protocol
    /// @dev fragment token amount of 1 NFT (with 18 decimals)
    uint256 public constant FLOOR_TOKEN_AMOUNT = 10_000 ether;

    /// @notice If set to true, this will suspend the functions fragmentNFTs, initAuctionOnVault,
    /// initAuctionOnExpiredSafeBoxes, ownerInitAuctions, and ownerInitRaffles.
    /// (tidyExpiredNFTs->isAuctionPeriodOver)
    bool public constant FUNCTION_DISABLED = true;

    /// @notice Auction Config
    uint256 public constant FREE_AUCTION_PERIOD = 24 hours;
    uint256 public constant AUCTION_INITIAL_PERIODS = 24 hours;
    uint256 public constant AUCTION_COMPLETE_GRACE_PERIODS = 2 days;
    /// @dev minimum bid per NFT when someone starts auction on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_MINIMUM_BID = 1000 ether;
    /// @dev minimum bid per NFT when someone starts auction on vault
    uint256 public constant AUCTION_ON_VAULT_MINIMUM_BID = 10000 ether;
    /// @dev admin fee charged per NFT when someone starts auction on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_SAFEBOX_COST = 0;
    /// @dev admin fee charged per NFT when owner starts auction on himself safebox
    uint256 public constant AUCTION_COST = 100 ether;

    /// @notice Raffle Config
    uint256 public constant RAFFLE_COST = 500 ether;
    uint256 public constant RAFFLE_COMPLETE_GRACE_PERIODS = 2 days;

    /// @notice Private offer Config
    uint256 public constant PRIVATE_OFFER_DURATION = 24 hours;
    uint256 public constant PRIVATE_OFFER_COMPLETE_GRACE_DURATION = 2 days;
    uint256 public constant PRIVATE_OFFER_COST = 0;

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

    // @notice The fee rate charged to the seller when accepting offer
    uint256 public constant OFFER_FEE_RATE_BIPS = 200; // 2%
    /// @notice Fee rate for redemption from safeBox
    uint256 public constant SAFE_BOX_FEE_RATE_BIPS = 500; // 5%
    /// @notice Fee rate for redemption from common pool
    uint256 public constant COMMON_POOL_FEE_RATE_BIPS = 200; // 2%
    /// @notice Discount rate for extend period of safebox
    uint256 public constant EXTEND_DISCOUNT_RATE_BIPS = 200; // 2%

    /// @notice Collection Config

    /// @notice The number of free trial days for safeBox
    uint256 public constant TRIAL_DAYS = 3; // 3 days

    /// @notice Arbitrum Config

    // https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbSys.sol#L10
    // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/ChainSpecificUtil.sol
    uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;
    uint256 private constant ARB_SEPOLIA_TESTNET_CHAIN_ID = 421614;
    IArbSys private constant ARBSYS = IArbSys(address(100));

    struct AuctionBidOption {
        uint256 extendDurationSecs;
        uint256 minimumRaisePct;
    }

    function getBidOption() internal pure returns (AuctionBidOption memory) {
        return AuctionBidOption({extendDurationSecs: 1 hours, minimumRaisePct: 10});
    }

    function raffleDurations() internal pure returns (uint256 duration) {
        return 2 days;
    }

    /**
     * @notice Calculate the final discounted price for NFT renewal
     * @param _discountRate The discount rate based on the number of tickets purchased (e.g., 0.05 for a 5% discount)
     * @param _days The number of days for the renewal
     * @return The discounted price ratio (based on 1_0000 to represent the full price, e.g., 9500 represents a 5% discount)
     */
    function _calculateDiscount(uint256 _discountRate, uint256 _days) internal pure returns (uint256) {
        // No discount is applied for a one-day renewal, returning the full price ratio
        if (_days == 1) {
            return 1_0000;
        }

        // For renewals exceeding 15 days, the discount is calculated based on a maximum of 15 days
        if (_days > 15) {
            return (1_0000 - 15 * _discountRate);
        } else {
            // Calculate the discount based on the number of renewal days
            return (1_0000 - _days * _discountRate);
        }
    }

    /**
     * @notice Returns the blockhash for the given blockNumber.
     * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockHash to get the blockhash.
     * @notice Otherwise, it uses the blockhash opcode.
     * @notice Note that the blockhash opcode will return the L2 blockhash on Optimism.
     */
    function _getBlockHash(uint256 blockNumber) internal view returns (bytes32) {
        uint256 chainid = block.chainid;
        if (_isArbitrumChainId(chainid)) {
            return ARBSYS.arbBlockHash(blockNumber);
        }

        return blockhash(blockNumber);
    }

    /**
     * @notice Returns the block number of the current block.
     * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockNumber to get the block number.
     * @notice Otherwise, it uses the block.number opcode.
     * @notice Note that the block.number opcode will return the L2 block number on Optimism.
     */
    function _getBlockNumber() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (_isArbitrumChainId(chainid)) {
            return ARBSYS.arbBlockNumber();
        }

        return block.number;
    }

    /**
     * @notice Return true if and only if the provided chain ID is an Arbitrum chain ID.
     */
    function _isArbitrumChainId(uint256 chainId) internal pure returns (bool) {
        return
            chainId == ARB_MAINNET_CHAIN_ID ||
            chainId == ARB_GOERLI_TESTNET_CHAIN_ID ||
            chainId == ARB_SEPOLIA_TESTNET_CHAIN_ID;
    }
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
    error NoPrivilege();

    /// @notice Parameter error
    error InvalidParam();
    error NftCollectionNotSupported();
    error NftCollectionAlreadySupported();
    error ClaimableNftInsufficient();
    error TokenNotSupported();
    error AmountTooSmall(uint256 minAmount, uint256 throwAmount);

    error DisabledFunction();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title IArbSys
 * @dev Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as uint256
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 blockNumber) external view returns (bytes32);
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

    /// User Operations

    /// @notice User deposits token to the Scattering Contract
    /// @param onBehalfOf deposit token into `onBehalfOf`'s account.(note. the tokens of msg.sender will be transferred)
    function addTokens(address onBehalfOf, address token, uint256 amount) external payable;

    /// @notice User removes token from Scattering Contract
    /// @param receiver who will receive the funds.(note. the token of msg.sender will be transferred)
    function removeTokens(address token, uint256 amount, address receiver) external;

    /// @notice Lock specified `nftIds` into Scattering Safeboxes and receive corresponding Fragment Tokens of the `collection`
    /// @param onBehalfOf who will receive the safebox and fragment tokens.(note. the NFTs of the msg.sender will be transferred)
    function lockNFTs(address collection, uint256[] memory nftIds, address onBehalfOf) external;

    /// @notice Extend the exist safeboxes with longer lock duration with more credit token staked
    function extendKeys(address collection, uint256[] memory nftIds, uint256 newRentalDays) external payable;

    /// @notice Unlock specified `nftIds` which had been locked previously
    ///         sender's wallet should have enough Fragment Tokens of the `collection` which will be burned to redeem the NFTs
    /// @param receiver who will receive the NFTs.
    ///                 note. - The safeboxes of the msg.sender will be removed.
    ///                       - The Fragment Tokens of the msg.sender will be burned.
    function unlockNFTs(address collection, uint256[] memory nftIds, address receiver) external;

    /// @notice Fragment specified `nftIds` into Scattering Vault and receive Fragment Tokens without any locking
    ///         after fragmented, any one has enough Fragment Tokens can redeem there `nftIds`
    /// @param onBehalfOf who will receive the fragment tokens.(note. the NFTs of the msg.sender will be transferred)
    function fragmentNFTs(address collection, uint256[] memory nftIds, address onBehalfOf) external;

    /// @notice Kick expired safeboxes to the vault
    function tidyExpiredNFTs(address collection, uint256[] memory nftIds) external;

    /// @notice Randomly claim `claimCnt` NFTs from Scattering Vault
    ///         sender's wallet should have enough Fragment Tokens of the `collection` which will be burned to redeem the NFTs
    /// @param receiver who will receive the NFTs.
    ///                 note. - the msg.sender will pay the redemption cost.
    ///                       - The Fragment Tokens of the msg.sender will be burned.
    function claimRandomNFT(address collection, uint256 claimCnt, address receiver) external;

    /// @notice Start auctions on specified `nftIds` with an initial bid price(`bidAmount`)
    ///         This kind of auctions will be settled with Scattering Credit Token
    /// @param bidAmount initial bid price
    function initAuctionOnExpiredSafeBoxes(
        address collection,
        uint256[] memory nftIds,
        address bidToken,
        uint256 bidAmount
    ) external;

    /// @notice Start auctions on specified `nftIds` index in the vault with an initial bid price(`bidAmount`)
    ///         This kind of auctions will be settled with Fragment Token of the collection
    /// @param bidAmount initial bid price
    function initAuctionOnVault(
        address collection,
        uint256[] memory vaultIdx,
        address bidToken,
        uint96 bidAmount
    ) external;

    /// @notice Owner starts auctions on his locked Safeboxes
    /// @param token which token should be used to settle auctions(bid, settle)
    /// @param minimumBid minimum bid price when someone place a bid on the auction
    function ownerInitAuctions(address collection, uint256[] memory nftIds, address token, uint256 minimumBid) external;

    //    /// @notice Place a bid on specified `nftId`'s action
    //    /// @param bidAmount bid price
    //    /// @param bidOptionIdx which option used to extend auction expiry and bid price
    //    function placeBidOnAuction(address collection, uint256 nftId, uint256 bidAmount, uint256 bidOptionIdx) external;

    /// @notice Place a bid on specified `nftId`'s action
    /// @param token which token should be transferred to the Scattering for bidding. `0x0` means ETH(native)
    /// @param amountToTransfer how many `token` should to transferred
    function placeBidOnAuction(
        address collection,
        uint256 nftId,
        uint256 bidAmount,
        // uint256 bidOptionIdx,
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
    }

    /// @notice Owner start raffles on locked `nftIds`
    function ownerInitRaffles(RaffleInitParam memory param) external;

    /// @notice Buy `nftId`'s raffle tickets
    /// @param token which token should be transferred to the Scattering for buying. `0x0` means ETH(native)
    /// @param amountToTransfer how many `token` should to transferred
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
    /// @param token which token should be transferred to the Scattering for buying. `0x0` means ETH(native)
    /// @param amountToTransfer how many `token` should to transferred
    function buyerAcceptPrivateOffers(
        address collectionId,
        uint256[] memory nftIds,
        address token,
        uint256 amountToTransfer
    ) external payable;

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

    //    function creditToken() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IScatteringEvent {
    event NewCollectionSupported(address indexed collection, address indexed fragmentToken);
    event OfferTokenUpdated(address indexed collection, address indexed offerToken);
    event PaymentParamUpdated(address indexed paymentToken, uint256 indexed paymentAmount);
    event UpdateTokenSupported(address indexed token, bool addOrRemove);
    event ProxyCollectionChanged(address indexed proxyCollection, address indexed underlyingCollection);

    //    /// @notice `sender` deposit `token` into Scattering on behalf of `receiver`. `receiver`'s account will be updated.
    //    event DepositToken(address indexed sender, address indexed receiver, address indexed token, uint256 amount);
    //    /// @notice `sender` withdraw `token` from Scattering and transfer it to `receiver`.
    //    event WithdrawToken(address indexed sender, address indexed receiver, address indexed token, uint256 amount);

    /// @notice Lock NFTs
    /// @param sender who send the tx and pay the NFTs
    /// @param onBehalfOf who will hold the safeboxes and receive the Fragment Tokens
    /// @param collection contract addr of the collection
    /// @param tokenIds nft ids to lock
    /// @param safeBoxKeys compacted safe box keys with same order of `tokenIds`
    /// for each key, its format is: [167-160:vipLevel][159-96:keyId][95-0:lockedCredit]
    event LockNft(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 rentalDays,
        address proxyCollection
    );

    /// @notice Extend keys
    /// @param operator who extend the keys
    /// @param collection contract addr of the collection
    /// @param tokenIds nft ids to lock
    event ExtendKey(address indexed operator, address indexed collection, uint256[] tokenIds, uint256 rentalDays);

    /// @notice Unlock NFTs
    /// @param operator who hold the safeboxes that will be unlocked
    /// @param receiver who will receive the NFTs
    event UnlockNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        address proxyCollection
    );

    /// @notice Kick expired safeboxes to the vault
    event ExpiredNftToVault(address indexed operator, address indexed collection, uint256[] tokenIds);

    /// @notice Fragment NFTs to free pool
    /// @param operator who will pay the NFTs
    /// @param onBehalfOf who will receive the Fragment Tokens
    event FragmentNft(
        address indexed operator,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds
    );

    /// @notice Claim random NFTs from free pool
    /// @param operator who will pay the redemption cost
    /// @param receiver who will receive the NFTs
    event ClaimRandomNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds
    );

    event AuctionStarted(
        address indexed trigger,
        address indexed collection,
        uint64[] activityIds,
        uint256[] tokenIds,
        address settleToken,
        uint256 minimumBid,
        uint256 feeRateBips,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs,
        bool selfTriggered,
        uint256 adminFee
    );

    event NewTopBidOnAuction(
        address indexed bidder,
        address indexed collection,
        uint64 activityId,
        uint256 tokenId,
        uint256 bidAmount,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs
    );

    event AuctionEnded(
        address indexed winner,
        address indexed collection,
        uint64 activityId,
        uint256 tokenId,
        uint256 safeBoxKeyId,
        uint256 collectedFunds
    );

    event RaffleStarted(
        address indexed owner,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint48 maxTickets,
        address settleToken,
        uint96 ticketPrice,
        uint256 feeRateBips,
        uint48 raffleEndTime,
        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event RaffleTicketsSold(
        address indexed buyer,
        address indexed collection,
        uint64 activityId,
        uint256 nftId,
        uint256 ticketsSold,
        uint256 cost
    );

    event RaffleSettled(
        address indexed winner,
        address indexed collection,
        uint64 activityId,
        uint256 nftId,
        uint256 safeBoxKeyId,
        uint256 collectedFunds
    );

    event PrivateOfferStarted(
        address indexed seller,
        address indexed buyer,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        address settleToken,
        uint96 price,
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library Array {
    /// @notice Compress `data` to [Length]:{[BytesLength][val...]}
    /// eg. [0, 255, 256] will be convert to bytes series: 0x03 0x00 0x01 0xFF 0x02 0x00 0x01
    /// 0x03 means there are 3 numbers
    /// 0x00 means first number is 0
    /// 0x01 means next number(255) has 1 byte to store the real value
    /// 0xFF equals 255
    /// 256 need 2 bytes(0x02) to store, and its value represented in hex is 0x0100
    function encodeUints(uint256[] memory data) internal pure returns (bytes memory res) {
        uint256 dataLen = data.length;

        require(dataLen <= type(uint8).max);

        unchecked {
            uint256 totalBytes;
            for (uint256 i; i < dataLen; ++i) {
                uint256 val = data[i];
                while (val > 0) {
                    val >>= 8;
                    ++totalBytes;
                }
            }

            res = new bytes(dataLen + totalBytes + 1);
            assembly {
                /// skip res's length, store data length
                mstore8(add(res, 0x20), dataLen)
            }

            /// start from the second element idx
            uint256 resIdx = 0x21;
            for (uint256 i; i < dataLen; ++i) {
                uint256 val = data[i];

                uint256 byteLen;
                while (val > 0) {
                    val >>= 8;
                    ++byteLen;
                }

                assembly {
                    /// store bytes length of the `i`th element
                    mstore8(add(res, resIdx), byteLen)
                }
                ++resIdx;

                val = data[i];
                for (uint256 j; j < byteLen; ++j) {
                    assembly {
                        mstore8(add(res, resIdx), val)
                    }
                    val >>= 8;
                    ++resIdx;
                }
            }
        }
    }

    function decodeUints(bytes memory data) internal pure returns (uint256[] memory res) {
        uint256 dataLen = data.length;
        require(dataLen > 0);

        res = new uint256[](uint8(data[0]));
        uint256 k;

        unchecked {
            for (uint256 i = 1; i < dataLen; ++i) {
                uint256 byteLen = uint8(data[i]);
                /// if byteLen is zero, it means current element is zero, no need to update `res`, just increment `k`
                if (byteLen > 0) {
                    uint256 tmp;
                    /// combine next `byteLen` bytes to `tmp`
                    for (uint256 j; j < byteLen; ++j) {
                        /// skip `byteLen`
                        ++i;

                        tmp |= ((uint256(uint8(data[i]))) << (j * 8));
                    }
                    res[k] = tmp;
                }

                ++k;
            }
        }
    }

    function slice(uint256[] memory data, uint256 start, uint256 length) internal pure returns (uint256[] memory res) {
        require(start + length <= data.length);

        res = new uint256[](length);

        unchecked {
            start *= 0x20;
            length *= 0x20;
        }

        for (uint256 i = 0x20; i <= length; ) {
            assembly {
                mstore(add(res, i), mload(add(data, add(i, start))))
            }

            unchecked {
                i += 0x20;
            }
        }
    }
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

import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import {SafeBox, CollectionState, AuctionInfo, AuctionType} from "./Structs.sol";
import "./User.sol";
import "./Collection.sol";
import "./Helper.sol";
import "../Errors.sol";
import "../Constants.sol";
import "../interface/IScattering.sol";
import {SafeBoxLib} from "./SafeBox.sol";

library AuctionLib {
    using SafeCast for uint256;
    using CollectionLib for CollectionState;
    using SafeBoxLib for SafeBox;
    using UserLib for UserFloorAccount;
    using Helper for CollectionState;

    event AuctionStarted(
        address indexed trigger,
        address indexed collection,
        uint64[] activityIds,
        uint256[] tokenIds,
        AuctionType typ,
        address settleToken,
        uint256 minimumBid,
        uint256 feeRateBips,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event NewTopBidOnAuction(
        address indexed bidder,
        address indexed collection,
        uint64 activityId,
        uint256 tokenId,
        uint256 bidAmount,
        uint256 auctionEndTime,
        uint256 safeBoxExpiryTs
    );

    event AuctionEnded(
        address indexed winner,
        address indexed collection,
        uint64 activityId,
        uint256 tokenId,
        uint256 safeBoxKeyId,
        uint256 collectedFunds
    );

    function ownerInitAuctions(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        //address creditToken,
        address collectionId,
        uint256[] memory nftIds,
        address token,
        uint256 minimumBid
    ) public {
        UserFloorAccount storage userAccount = userAccounts[msg.sender];
        uint256 adminFee = Constants.AUCTION_COST * nftIds.length;
        /// transfer fee to contract account
        userAccount.transferToken(userAccounts[address(this)], address(collection.fragmentToken), adminFee, true);

        AuctionInfo memory auctionTemplate;
        auctionTemplate.endTime = uint96(block.timestamp + Constants.AUCTION_INITIAL_PERIODS);
        auctionTemplate.bidTokenAddress = token;
        auctionTemplate.minimumBid = minimumBid.toUint96();
        auctionTemplate.triggerAddress = msg.sender;
        auctionTemplate.feeRateBips = uint32(getAuctionFeeRate());
        auctionTemplate.lastBidAmount = 0;
        auctionTemplate.lastBidder = address(0);
        auctionTemplate.typ = AuctionType.Owned;

        (uint64[] memory activityIds, uint192 newExpiryTs) = _ownerInitAuctions(collection, nftIds, auctionTemplate);

        emit AuctionStarted(
            msg.sender,
            collectionId,
            activityIds,
            nftIds,
            auctionTemplate.typ,
            token,
            minimumBid,
            auctionTemplate.feeRateBips,
            auctionTemplate.endTime,
            newExpiryTs,
            adminFee
        );
    }

    function _ownerInitAuctions(
        CollectionState storage collectionState,
        uint256[] memory nftIds,
        AuctionInfo memory auctionTemplate
    ) private returns (uint64[] memory activityIds, uint32 newExpiryTs) {
        newExpiryTs = uint32(auctionTemplate.endTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS);

        activityIds = new uint64[](nftIds.length);
        for (uint256 i = 0; i < nftIds.length; ) {
            if (collectionState.hasActiveActivities(nftIds[i])) revert Errors.NftHasActiveActivities();

            SafeBox storage safeBox = collectionState.useSafeBoxAndKey(msg.sender, nftIds[i]);

            safeBox.expiryTs = newExpiryTs;

            activityIds[i] = collectionState.generateNextActivityId();

            auctionTemplate.activityId = activityIds[i];
            collectionState.activeAuctions[nftIds[i]] = auctionTemplate;

            unchecked {
                ++i;
            }
        }
    }

    function initAuctionOnExpiredSafeBoxes(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        // address creditToken,
        address collectionId,
        uint256[] memory nftIds,
        address bidToken,
        uint256 bidAmount
    ) public {
        if (bidAmount < Constants.AUCTION_ON_EXPIRED_MINIMUM_BID) revert Errors.InvalidParam();

        AuctionInfo memory auctionTemplate;
        auctionTemplate.endTime = uint96(block.timestamp + Constants.AUCTION_INITIAL_PERIODS);
        auctionTemplate.bidTokenAddress = bidToken;
        auctionTemplate.minimumBid = bidAmount.toUint96();
        auctionTemplate.triggerAddress = msg.sender;
        auctionTemplate.feeRateBips = uint32(getAuctionFeeRate());
        auctionTemplate.lastBidAmount = bidAmount.toUint96();
        auctionTemplate.lastBidder = msg.sender;
        auctionTemplate.typ = AuctionType.Expired;

        (uint64[] memory activityIds, uint192 newExpiry) = _initAuctionOnExpiredSafeBoxes(
            collection,
            nftIds,
            auctionTemplate
        );

        uint256 adminFee = Constants.AUCTION_ON_EXPIRED_SAFEBOX_COST * nftIds.length;
        {
            userAccounts[msg.sender].transferToken(
                userAccounts[address(this)],
                bidToken,
                bidAmount * nftIds.length,
                false
            );
            if (adminFee > 0) {
                userAccounts[msg.sender].transferToken(
                    userAccounts[address(this)],
                    address(collection.fragmentToken),
                    adminFee,
                    true
                );
            }
        }

        emit AuctionStarted(
            msg.sender,
            collectionId,
            activityIds,
            nftIds,
            auctionTemplate.typ,
            bidToken,
            bidAmount,
            auctionTemplate.feeRateBips,
            auctionTemplate.endTime,
            newExpiry,
            // false,
            adminFee
        );
    }

    function _initAuctionOnExpiredSafeBoxes(
        CollectionState storage collectionState,
        uint256[] memory nftIds,
        AuctionInfo memory auctionTemplate
    ) private returns (uint64[] memory activityIds, uint32 newExpiry) {
        newExpiry = uint32(auctionTemplate.endTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS);

        activityIds = new uint64[](nftIds.length);
        for (uint256 idx; idx < nftIds.length; ) {
            uint256 nftId = nftIds[idx];
            if (collectionState.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            SafeBox storage safeBox = collectionState.useSafeBox(nftId);
            if (!safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasNotExpire();
            if (Helper.isAuctionPeriodOver(safeBox)) revert Errors.SafeBoxAuctionWindowHasPassed();

            activityIds[idx] = collectionState.generateNextActivityId();
            auctionTemplate.activityId = activityIds[idx];
            collectionState.activeAuctions[nftId] = auctionTemplate;

            /// @del We keep the owner of safebox unchanged, and it will be used to distribute auction funds
            /// todo Temporarily transfer the key to the contract
            safeBox.expiryTs = newExpiry;
            // safeBox.keyId = SafeBoxLib.SAFEBOX_KEY_NOTATION;
            collectionState.transferSafeBox(safeBox, address(this));

            unchecked {
                ++idx;
            }
        }
    }

    function initAuctionOnVault(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        //        address creditToken,
        address collectionId,
        uint256[] memory vaultIdx,
        address bidToken,
        uint96 bidAmount
    ) public {
        if (vaultIdx.length != 1) revert Errors.InvalidParam();
        if (bidAmount < Constants.AUCTION_ON_VAULT_MINIMUM_BID) revert Errors.InvalidParam();

        AuctionInfo memory auctionTemplate;
        auctionTemplate.endTime = uint96(block.timestamp + Constants.AUCTION_INITIAL_PERIODS);
        auctionTemplate.bidTokenAddress = bidToken;
        auctionTemplate.minimumBid = bidAmount;
        auctionTemplate.triggerAddress = msg.sender;
        auctionTemplate.feeRateBips = 0;
        auctionTemplate.lastBidAmount = bidAmount;
        auctionTemplate.lastBidder = msg.sender;
        auctionTemplate.typ = AuctionType.Vault;

        SafeBox memory safeboxTemplate = SafeBox({
            keyId: Helper.generateNextKeyId(collection),
            expiryTs: uint32(auctionTemplate.endTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS),
            owner: address(this)
        });

        uint256[] memory nftIds = new uint256[](vaultIdx.length);
        uint64[] memory activityIds = new uint64[](vaultIdx.length);

        /// vaultIdx keeps asc order
        for (uint256 i = vaultIdx.length; i > 0; ) {
            unchecked {
                --i;
            }

            if (vaultIdx[i] >= collection.freeTokenIds.length) revert Errors.InvalidParam();
            uint256 nftId = collection.freeTokenIds[vaultIdx[i]];
            nftIds[i] = nftId;

            collection.addSafeBox(nftId, safeboxTemplate);

            auctionTemplate.activityId = collection.generateNextActivityId();
            collection.activeAuctions[nftId] = auctionTemplate;
            activityIds[i] = auctionTemplate.activityId;

            collection.freeTokenIds[vaultIdx[i]] = collection.freeTokenIds[collection.freeTokenIds.length - 1];
            collection.freeTokenIds.pop();
        }

        userAccounts[msg.sender].transferToken(
            userAccounts[address(this)],
            auctionTemplate.bidTokenAddress,
            bidAmount * nftIds.length,
            false
        );

        emit AuctionStarted(
            msg.sender,
            collectionId,
            activityIds,
            nftIds,
            auctionTemplate.typ,
            auctionTemplate.bidTokenAddress,
            bidAmount,
            auctionTemplate.feeRateBips,
            auctionTemplate.endTime,
            safeboxTemplate.expiryTs,
            0
        );
    }

    struct BidParam {
        uint256 nftId;
        uint96 bidAmount;
        address bidder;
        uint256 extendDuration;
        uint256 minIncrPct;
    }

    function placeBidOnAuction(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        // address creditToken,
        address collectionId,
        uint256 nftId,
        uint256 bidAmount /*,
        uint256 bidOptionIdx*/
    ) public {
        uint256 prevBidAmount;
        address prevBidder;
        {
            Constants.AuctionBidOption memory bidOption = Constants.getBidOption();

            (prevBidAmount, prevBidder) = _placeBidOnAuction(
                collection,
                BidParam(
                    nftId,
                    bidAmount.toUint96(),
                    msg.sender,
                    bidOption.extendDurationSecs,
                    bidOption.minimumRaisePct
                )
            );
        }

        AuctionInfo memory auction = collection.activeAuctions[nftId];

        address bidToken = auction.bidTokenAddress;
        userAccounts[msg.sender].transferToken(
            userAccounts[address(this)],
            bidToken,
            bidAmount,
            // bidToken == creditToken
            false
        );

        if (prevBidAmount > 0) {
            /// refund previous bid
            /// contract account no need to check credit requirements
            userAccounts[address(this)].transferToken(userAccounts[prevBidder], bidToken, prevBidAmount, false);
            userAccounts[prevBidder].withdraw(prevBidder, bidToken, prevBidAmount, false);
        }

        SafeBox memory safebox = collection.safeBoxes[nftId];
        emit NewTopBidOnAuction(
            msg.sender,
            collectionId,
            auction.activityId,
            nftId,
            bidAmount,
            auction.endTime,
            safebox.expiryTs
        );
    }

    function _placeBidOnAuction(
        CollectionState storage collectionState,
        BidParam memory param
    ) private returns (uint128 prevBidAmount, address prevBidder) {
        AuctionInfo storage auctionInfo = collectionState.activeAuctions[param.nftId];

        SafeBox storage safeBox = collectionState.useSafeBox(param.nftId);
        uint256 endTime = auctionInfo.endTime;
        {
            (prevBidAmount, prevBidder) = (auctionInfo.lastBidAmount, auctionInfo.lastBidder);
            // param check
            if (endTime == 0) revert Errors.AuctionNotExist();
            if (endTime <= block.timestamp) revert Errors.AuctionHasExpire();
            if (prevBidAmount >= param.bidAmount || auctionInfo.minimumBid > param.bidAmount) {
                revert Errors.AuctionBidIsNotHighEnough();
            }
            if (prevBidder == param.bidder) revert Errors.AuctionSelfBid();
            // owner starts auction, can not bid by himself
            if (auctionInfo.typ == AuctionType.Owned && param.bidder == safeBox.owner) revert Errors.AuctionSelfBid();

            if (prevBidAmount > 0 && !isValidNewBid(param.bidAmount, prevBidAmount, param.minIncrPct)) {
                revert Errors.AuctionInvalidBidAmount();
            }
        }

        /// Changing safebox key id which means the corresponding safebox key doesn't hold the safebox now
        // safeBox.keyId = SafeBoxLib.SAFEBOX_KEY_NOTATION;

        uint256 newAuctionEndTime = block.timestamp + param.extendDuration;
        if (newAuctionEndTime > endTime) {
            uint256 newSafeBoxExpiryTs = newAuctionEndTime + Constants.AUCTION_COMPLETE_GRACE_PERIODS;

            safeBox.expiryTs = uint32(newSafeBoxExpiryTs);
            auctionInfo.endTime = uint96(newAuctionEndTime);
        }

        auctionInfo.lastBidAmount = param.bidAmount;
        auctionInfo.lastBidder = param.bidder;
    }

    function settleAuctions(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address collectionId,
        uint256[] memory nftIds
    ) public {
        for (uint256 i; i < nftIds.length; ) {
            uint256 nftId = nftIds[i];
            SafeBox storage safeBox = Helper.useSafeBox(collection, nftId);

            if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

            AuctionInfo memory auctionInfo = collection.activeAuctions[nftId];
            if (auctionInfo.endTime == 0) revert Errors.AuctionNotExist();
            if (auctionInfo.endTime > block.timestamp) revert Errors.AuctionHasNotCompleted();
            /// none bid on the action, can not be settled
            if (auctionInfo.lastBidder == address(0)) revert Errors.AuctionHasNotCompleted();

            (uint256 earning, ) = Helper.calculateActivityFee(auctionInfo.lastBidAmount, auctionInfo.feeRateBips);
            /// contract account no need to check credit requirements
            /// transfer earnings to old safebox owner
            if (safeBox.owner != address(this)) {
                userAccounts[address(this)].transferToken(
                    userAccounts[safeBox.owner],
                    auctionInfo.bidTokenAddress,
                    earning,
                    false
                );
                userAccounts[safeBox.owner].withdraw(safeBox.owner, auctionInfo.bidTokenAddress, earning, false);
            }

            /// transfer safebox
            address winner = auctionInfo.lastBidder;
            collection.transferSafeBox(safeBox, winner);

            delete collection.activeAuctions[nftId];

            emit AuctionEnded(
                winner,
                collectionId,
                auctionInfo.activityId,
                nftId,
                safeBox.keyId,
                auctionInfo.lastBidAmount
            );

            unchecked {
                ++i;
            }
        }
    }

    function isValidNewBid(uint256 newBid, uint256 previousBid, uint256 minRaisePct) private pure returns (bool) {
        uint256 minIncrement = (previousBid * minRaisePct) / 100;
        if (minIncrement < 1) {
            minIncrement = 1;
        }

        if (newBid < previousBid + minIncrement) {
            return false;
        }
        // think: always thought this should be previousBid....
        uint256 newIncrementAmount = newBid / 100;
        if (newIncrementAmount < 1) {
            newIncrementAmount = 1;
        }
        return newBid % newIncrementAmount == 0;
    }

    function getAuctionFeeRate() private pure returns (uint256) {
        return Constants.FREE_AUCTION_FEE_RATE_BIPS;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "../library/ERC721Transfer.sol";

import "../Errors.sol";
import "../Constants.sol";
import "./User.sol";
import "./Helper.sol";
import {SafeBox, CollectionState, AuctionInfo, UserFloorAccount, LockParam} from "./Structs.sol";
import {SafeBoxLib} from "./SafeBox.sol";

import "../interface/IScattering.sol";

library CollectionLib {
    using SafeBoxLib for SafeBox;
    using SafeCast for uint256;
    using UserLib for UserFloorAccount;

    event LockNft(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 rentalDays,
        address proxyCollection
    );
    event ExtendKey(address indexed operator, address indexed collection, uint256[] tokenIds, uint256 rentalDays);
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

        uint256[] memory nftIds = param.nftIds;
        uint256[] memory newKeys;
        {
            newKeys = _lockNfts(collection, onBehalfOf, nftIds, param.rentalDays);
        }

        /// mint for `onBehalfOf`, transfer from msg.sender
        collection.fragmentToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
        /// @notice The transfer will fail if it is not the owner, so there is no need to verify that the NFT belongs to this owner
        ERC721Transfer.safeBatchTransferFrom(param.proxyCollection, msg.sender, address(this), nftIds);

        emit LockNft(
            msg.sender,
            onBehalfOf,
            param.collection,
            nftIds,
            newKeys,
            param.rentalDays,
            param.proxyCollection
        );
    }

    function _lockNfts(
        CollectionState storage collectionState,
        //        CollectionAccount storage account,
        address onBehalfOf,
        uint256[] memory nftIds,
        uint256 rentalDays
    ) private returns (uint256[] memory) {
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length; ) {
            uint64 keyId = Helper.generateNextKeyId(collectionState);
            uint256 expiryTs = block.timestamp + rentalDays * 1 days;
            addSafeBox(
                collectionState,
                nftIds[idx],
                SafeBox({keyId: keyId, expiryTs: uint32(expiryTs), owner: onBehalfOf})
            );

            delete collectionState.activePrivateOffers[nftIds[idx]];
            // keys[idx] = SafeBoxLib.encodeSafeBoxKey(key);
            keys[idx] = uint256(keyId);

            unchecked {
                ++idx;
            }
        }

        return keys;
    }

    function unlockNfts(
        CollectionState storage collection,
        //        UserFloorAccount storage userAccount,
        //        UserFloorAccount storage userAccount,
        address proxyCollection,
        address collectionId,
        uint256[] memory nftIds,
        address receiver
    ) public {
        _unlockNfts(collection, nftIds);

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

    function _unlockNfts(CollectionState storage collectionState, uint256[] memory nftIds) private {
        for (uint256 i; i < nftIds.length; ) {
            uint256 nftId = nftIds[i];

            if (Helper.hasActiveActivities(collectionState, nftId)) revert Errors.NftHasActiveActivities();

            // SafeBox storage safeBox = Helper.useSafeBoxAndKey(collectionState, msg.sender, nftId);
            Helper.useSafeBoxAndKey(collectionState, msg.sender, nftId);

            removeSafeBox(collectionState, nftId);

            unchecked {
                ++i;
            }
        }
    }

    function extendLockingForKeys(
        CollectionState storage collection,
        //        UserFloorAccount storage userAccount,
        LockParam memory param,
        address onBehalfOf
    ) public {
        {
            _extendLockingForKeys(collection, param.nftIds, param.rentalDays, onBehalfOf);
        }

        emit ExtendKey(msg.sender, param.collection, param.nftIds, param.rentalDays);
    }

    function _extendLockingForKeys(
        CollectionState storage collectionState,
        //        CollectionAccount storage userCollectionAccount,
        uint256[] memory nftIds,
        uint256 newRentalDays,
        address onBehalfOf
    ) private returns (uint256[] memory) {
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length; ) {
            if (
                Helper.hasActiveActivities(collectionState, nftIds[idx]) &&
                /// listing safebox can be extended
                (!Helper.hasActivePrivateOffer(collectionState, nftIds[idx]) &&
                    !Helper.hasActiveListOffer(collectionState, nftIds[idx]))
            ) revert Errors.NftHasActiveActivities();

            SafeBox storage safeBox = Helper.useSafeBoxAndKey(collectionState, onBehalfOf, nftIds[idx]);

            uint256 newExpiryTs = safeBox.expiryTs + newRentalDays * 1 days;
            safeBox.expiryTs = uint32(newExpiryTs);

            //keys[idx] = SafeBoxLib.encodeSafeBoxKey(safeBoxKey);
            keys[idx] = safeBox.keyId;

            unchecked {
                ++idx;
            }
        }

        return keys;
    }

    function tidyExpiredNFTs(CollectionState storage collection, uint256[] memory nftIds, address collectionId) public {
        uint256 nftLen = nftIds.length;

        for (uint256 i; i < nftLen; ) {
            uint256 nftId = nftIds[i];
            SafeBox storage safeBox = Helper.useSafeBox(collection, nftId);
            if (!safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasNotExpire();
            // todo If auctions are enabled in the future, this next line of code should be retained
            if (!Constants.FUNCTION_DISABLED) {
                if (!Helper.isAuctionPeriodOver(safeBox)) revert Errors.AuctionHasNotCompleted();
            }

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
        //address creditToken,
        address collectionId,
        uint256 claimCnt,
        address receiver
    ) public {
        //creditToken;
        if (claimCnt == 0 || collection.freeTokenIds.length < claimCnt) revert Errors.ClaimableNftInsufficient();

        uint256 freeAmount = collection.freeTokenIds.length;
        uint256 totalManaged = collection.activeSafeBoxCnt + freeAmount;

        uint256[] memory selectedTokenIds = new uint256[](claimCnt);
        uint256 currentBlockNumber = Constants._getBlockNumber();
        while (claimCnt > 0) {
            /// just compute a deterministic random number
            uint256 chosenNftIdx = uint256(
                // https://docs.arbitrum.io/for-devs/concepts/differences-between-arbitrum-ethereum/solidity-support
                // keccak256(abi.encodePacked(block.timestamp, block.prevrandao, totalManaged))
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        currentBlockNumber,
                        Constants._getBlockHash(currentBlockNumber - 1),
                        totalManaged
                    )
                )
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

        // userAccount.transferToken(userAccounts[address(this)], creditToken, totalCreditCost, true);
        collection.fragmentToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * selectedTokenIds.length);
        ERC721Transfer.safeBatchTransferFrom(collectionId, address(this), receiver, selectedTokenIds);

        emit ClaimRandomNft(msg.sender, receiver, collectionId, selectedTokenIds);
    }

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

library Helper {
    using SafeBoxLib for SafeBox;

    // @notice Check if the safeBox is still within the validity period and verify if the owner is consistent
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
        PrivateOffer storage offer = collection.activePrivateOffers[nftId];
        return offer.activityId > 0 && offer.buyer != address(0) && !useSafeBox(collection, nftId).isSafeBoxExpired();
    }

    function hasActiveListOffer(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        PrivateOffer storage offer = collection.activePrivateOffers[nftId];
        return offer.activityId > 0 && offer.buyer == address(0) && !useSafeBox(collection, nftId).isSafeBoxExpired();
    }

    //    function getTokenFeeRateBips(
    //        address creditToken,
    //        address fragmentToken,
    //        address settleToken
    //    ) internal pure returns (uint256) {
    //        uint256 feeRateBips = Constants.COMMON_FEE_RATE_BIPS;
    //        if (settleToken == creditToken) {
    //            feeRateBips = Constants.CREDIT_FEE_RATE_BIPS;
    //        } else if (settleToken == fragmentToken) {
    //            feeRateBips = Constants.SPEC_FEE_RATE_BIPS;
    //        }
    //
    //        return feeRateBips;
    //    }

    function getTokenFeeRateBips() internal pure returns (uint256) {
        return Constants.COMMON_FEE_RATE_BIPS;
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import "../Errors.sol";
import "../interface/IScattering.sol";
import {SafeBox, CollectionState, PrivateOffer} from "./Structs.sol";
import {SafeBoxLib} from "./SafeBox.sol";
import "./User.sol";
import "./Helper.sol";
import "./Collection.sol";

library PrivateOfferLib {
    using SafeBoxLib for SafeBox;
    using UserLib for UserFloorAccount;
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
        uint256 keyId;
        uint256 nftId;
        address token;
        uint128 collectedFund;
        address seller;
        address buyer;
    }

    function ownerInitPrivateOffers(
        CollectionState storage collection,
        // mapping(address => UserFloorAccount) storage userAccounts,
        // address creditToken,
        IScattering.PrivateOfferInitParam memory param
    ) public {
        // creditToken;
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

        uint64[] memory offerActivityIds = _ownerInitPrivateOffers(
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
            0
        );
    }

    function _ownerInitPrivateOffers(
        CollectionState storage collection,
        uint256[] memory nftIds,
        PrivateOffer memory offerTemplate
    ) private returns (uint64[] memory offerActivityIds) {
        uint256 nftLen = nftIds.length;
        offerActivityIds = new uint64[](nftLen);

        for (uint256 i; i < nftLen; ) {
            uint256 nftId = nftIds[i];
            if (collection.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            /// dummy check
            collection.useSafeBoxAndKey(msg.sender, nftId);

            offerTemplate.activityId = collection.generateNextActivityId();
            collection.activePrivateOffers[nftId] = offerTemplate;
            offerActivityIds[i] = offerTemplate.activityId;

            unchecked {
                ++i;
            }
        }
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

            /// check owner and safe box time valid and key id exist
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
        uint256[] memory nftIds /*,
        address creditToken*/
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
            buyerAccount.transferToken(userAccounts[address(this)], settleToken, protocolFee, false);
            {
                buyerAccount.transferToken(sellerAccount, settleToken, priceWithoutFee, false);
                sellerAccount.withdraw(settlement.seller, settleToken, priceWithoutFee, false);
            }
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
            if (offer.owner != safeBox.owner) revert Errors.ActivityHasExpired();

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

import {SafeBox, CollectionState, RaffleInfo, TicketRecord} from "./Structs.sol";
import "./User.sol";
import "./Collection.sol";
import "./Helper.sol";
import "../Errors.sol";
import "../library/Array.sol";

library RaffleLib {
    using CollectionLib for CollectionState;
    using SafeBoxLib for SafeBox;
    using UserLib for UserFloorAccount;
    using Helper for CollectionState;

    event RaffleStarted(
        address indexed owner,
        address indexed collection,
        uint64[] activityIds,
        uint256[] nftIds,
        uint48 maxTickets,
        address settleToken,
        uint96 ticketPrice,
        uint256 feeRateBips,
        uint48 raffleEndTime,
        uint256 safeBoxExpiryTs,
        uint256 adminFee
    );

    event RaffleTicketsSold(
        address indexed buyer,
        address indexed collection,
        uint64 activityId,
        uint256 nftId,
        uint256 ticketsSold,
        uint256 cost
    );

    event RaffleSettled(
        address indexed winner,
        address indexed collection,
        uint64 activityId,
        uint256 nftId,
        uint256 safeBoxKeyId,
        uint256 collectedFunds
    );

    function ownerInitRaffles(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        IScattering.RaffleInitParam memory param /*,
        address creditToken*/
    ) public {
        UserFloorAccount storage userAccount = userAccounts[msg.sender];

        {
            if (uint256(param.maxTickets) * param.ticketPrice > type(uint96).max) revert Errors.InvalidParam();

            // todo Duration of the raffle activity
            param.duration = Constants.raffleDurations();
        }

        uint256 adminFee = Constants.RAFFLE_COST * param.nftIds.length;
        userAccount.transferToken(userAccounts[address(this)], address(collection.fragmentToken), adminFee, true);

        uint256 feeRateBips = Helper.getTokenFeeRateBips();
        (uint64[] memory raffleActivityIds, uint48 raffleEndTime, uint192 safeBoxExpiryTs) = _ownerInitRaffles(
            collection,
            param,
            uint32(feeRateBips)
        );

        emit RaffleStarted(
            msg.sender,
            param.collection,
            raffleActivityIds,
            param.nftIds,
            param.maxTickets,
            param.ticketToken,
            param.ticketPrice,
            feeRateBips,
            raffleEndTime,
            safeBoxExpiryTs,
            adminFee
        );
    }

    function _ownerInitRaffles(
        CollectionState storage collection,
        IScattering.RaffleInitParam memory param,
        uint32 feeRateBips
    ) private returns (uint64[] memory raffleActivityIds, uint48 raffleEndTime, uint32 safeBoxExpiryTs) {
        raffleEndTime = uint48(block.timestamp + param.duration);
        safeBoxExpiryTs = uint32(raffleEndTime + Constants.RAFFLE_COMPLETE_GRACE_PERIODS);

        raffleActivityIds = new uint64[](param.nftIds.length);
        for (uint256 i; i < param.nftIds.length; ) {
            uint256 nftId = param.nftIds[i];

            if (collection.hasActiveActivities(nftId)) revert Errors.NftHasActiveActivities();

            SafeBox storage safeBox = collection.useSafeBoxAndKey(msg.sender, nftId);

            safeBox.expiryTs = safeBoxExpiryTs;
            raffleActivityIds[i] = collection.generateNextActivityId();

            RaffleInfo storage newRaffle = collection.activeRaffles[nftId];
            newRaffle.endTime = raffleEndTime;
            newRaffle.token = param.ticketToken;
            newRaffle.ticketPrice = param.ticketPrice;
            newRaffle.maxTickets = param.maxTickets;
            newRaffle.owner = msg.sender;
            newRaffle.activityId = raffleActivityIds[i];
            newRaffle.feeRateBips = feeRateBips;

            unchecked {
                ++i;
            }
        }
    }

    function buyRaffleTickets(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage accounts,
        // address creditToken,
        address collectionId,
        uint256 nftId,
        uint256 ticketCnt
    ) public {
        RaffleInfo storage raffle = collection.activeRaffles[nftId];
        if (raffle.owner == address(0) || raffle.owner == msg.sender) revert Errors.NoPrivilege();
        if (raffle.endTime < block.timestamp) revert Errors.ActivityHasExpired();
        if (raffle.maxTickets < raffle.ticketSold + ticketCnt) revert Errors.InvalidParam();

        //        SafeBox storage safeBox = collection.useSafeBox(nftId);
        //        safeBox.keyId = SafeBoxLib.SAFEBOX_KEY_NOTATION;

        // buyer buy tickets idx in [startIdx, endIdx)
        raffle.tickets.push(
            TicketRecord({
                buyer: msg.sender,
                startIdx: uint48(raffle.ticketSold),
                endIdx: uint48(raffle.ticketSold + ticketCnt)
            })
        );

        uint256 cost = raffle.ticketPrice * ticketCnt;
        raffle.ticketSold += uint48(ticketCnt);
        raffle.collectedFund += uint96(cost);

        address token = raffle.token;
        accounts[msg.sender].transferToken(accounts[address(this)], token, cost, /* token == creditToken*/ false);

        emit RaffleTicketsSold(msg.sender, collectionId, raffle.activityId, nftId, ticketCnt, cost);
    }

    function prepareSettleRaffles(
        CollectionState storage collection,
        uint256[] calldata nftIds
    ) public returns (bytes memory compactedNftIds, uint256 nftLen) {
        nftLen = nftIds.length;
        uint256[] memory tmpNftIds = new uint256[](nftLen);
        uint256 cnt;
        for (uint256 i; i < nftLen; ++i) {
            uint256 nftId = nftIds[i];
            RaffleInfo storage raffle = collection.activeRaffles[nftId];

            if (raffle.endTime >= block.timestamp) revert Errors.ActivityHasNotCompleted();
            if (raffle.isSettling) revert Errors.InvalidParam();

            if (raffle.ticketSold == 0) {
                continue;
            }

            SafeBox storage safeBox = collection.useSafeBox(nftId);
            // raffle must be settled before safebox expired
            // otherwise it maybe conflict with auction
            if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

            tmpNftIds[cnt] = nftId;
            raffle.isSettling = true;

            unchecked {
                ++cnt;
            }
        }

        /// only allow up to 8 raffles can be settled
        if (cnt > 8) revert Errors.InvalidParam();

        if (cnt == nftLen) {
            // the first line of the code has already made the same assignment
            // nftIdsLen = tmpNftIds.length;
            compactedNftIds = Array.encodeUints(tmpNftIds);
        } else {
            nftLen = cnt;
            compactedNftIds = Array.encodeUints(Array.slice(tmpNftIds, 0, cnt));
        }
    }

    function settleRaffles(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address collectionId,
        bytes memory compactedNftIds,
        uint256[] memory randoms
    ) public {
        uint256[] memory nftIds = Array.decodeUints(compactedNftIds);
        for (uint256 i; i < nftIds.length; ) {
            uint256 nftId = nftIds[i];
            RaffleInfo storage raffle = collection.activeRaffles[nftId];

            TicketRecord memory winTicket = getWinTicket(raffle.tickets, uint48(randoms[i] % raffle.ticketSold));

            /// we don't check whether the safebox is exist, it had done in the `prepareSettleRaffles`
            SafeBox storage safeBox = collection.safeBoxes[nftId];
            collection.transferSafeBox(safeBox, winTicket.buyer);

            (uint256 earning, ) = Helper.calculateActivityFee(raffle.collectedFund, raffle.feeRateBips);
            /// contract account no need to check credit requirements
            userAccounts[address(this)].transferToken(userAccounts[raffle.owner], raffle.token, earning, false);
            userAccounts[raffle.owner].withdraw(raffle.owner, raffle.token, earning, false);

            emit RaffleSettled(
                winTicket.buyer,
                collectionId,
                raffle.activityId,
                nftId,
                safeBox.keyId,
                raffle.collectedFund
            );

            delete collection.activeRaffles[nftId];

            unchecked {
                ++i;
            }
        }
    }

    function getWinTicket(
        TicketRecord[] storage tickets,
        uint48 idx
    ) private view returns (TicketRecord memory ticket) {
        uint256 low;
        uint256 high = tickets.length;

        unchecked {
            while (low <= high) {
                // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
                // because Math.average rounds down (it does integer division with truncation).
                uint256 mid = Math.average(low, high);

                ticket = tickets[mid];
                if (ticket.startIdx <= idx && idx < ticket.endIdx) {
                    return ticket;
                }

                if (ticket.startIdx < idx) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
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
    /// which token used to accept the offer
    address token;
    /// price of the offer
    uint96 price;
    address owner;
    /// who should receive the offer
    address buyer;
    uint64 activityId;
}

enum AuctionType {
    Owned,
    Expired,
    Vault
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
    uint64 activityId;
    uint32 feeRateBips;
    AuctionType typ;
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
    /// The address of the Scattering Token corresponding to the NFTs.
    IFragmentToken fragmentToken;
    address keyIdNft;
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
    // @notice will be stored in the slot from right to left in sequence
    /// Active Safe Box Count.
    uint64 activeSafeBoxCnt;
    /// Next Key Id. This should start from 1, we treat key id `SafeboxLib.SAFEBOX_KEY_NOTATION` as temporarily
    /// being used for activities(auction/raffle).
    uint64 nextKeyId;
    /// Next Activity Id. This should start from 1
    uint64 nextActivityId;
    address offerToken;
}

struct UserFloorAccount {
    mapping(address => uint256) tokenAmounts;
}

/// Internal Structure
struct LockParam {
    address proxyCollection;
    address collection;
    uint256[] nftIds;
    uint256 rentalDays;
}

struct FeeParam {
    uint256 safeBoxCommission;
    uint256 commonPoolCommission;
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

    function tokenBalance(UserFloorAccount storage account, address token) internal view returns (uint256) {
        return account.tokenAmounts[token];
    }

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {VRFCoordinatorV2Interface} from "node_modules/@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "node_modules/@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "./interface/IScattering.sol";
import "./interface/IScatteringEvent.sol";
import "./interface/IFragmentToken.sol";

import "./logic/User.sol";
import "./logic/Collection.sol";
import "./logic/Auction.sol";
import "./logic/Raffle.sol";
import "./logic/PrivateOffer.sol";
import {CollectionState, SafeBox, AuctionInfo, RaffleInfo, PrivateOffer, UserFloorAccount} from "./logic/Structs.sol";
import "./Multicall.sol";
import "./Errors.sol";
import "./library/CurrencyTransfer.sol";

/// @custom:oz-upgrades-unsafe-allow constructor external-library-linking state-variable-immutable
contract Scattering is
    IScattering,
    IScatteringEvent,
    Multicall,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    VRFConsumerBaseV2
{
    using CollectionLib for CollectionState;
    using AuctionLib for CollectionState;
    using RaffleLib for CollectionState;
    using PrivateOfferLib for CollectionState;
    using UserLib for UserFloorAccount;

    struct RandomRequestInfo {
        uint96 typ;
        address collection;
        bytes data;
    }

    /// Information related to Chainlink VRF Randomness Oracle.

    /// The keyhash, which is network dependent.
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 internal immutable keyHash;
    /// Subscription Id, need to get from the Chainlink UI.
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint64 internal immutable subId;
    /// Chainlink VRF Coordinator.
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    /// A mapping from VRF request Id to raffle.
    mapping(uint256 => RandomRequestInfo) internal randomnessRequestToReceiver;

    /// A mapping from collection address to `CollectionState`.
    mapping(address => CollectionState) internal collectionStates;

    /// A mapping from user address to the `UserFloorAccount`s.
    mapping(address => UserFloorAccount) internal userFloorAccounts;

    /// A mapping of supported ERC-20 token.
    mapping(address => bool) internal supportedTokens;

    /// A mapping from Proxy Collection(wrapped) to underlying Collection.
    /// eg. Paraspace Derivative Token BAYC(nBAYC) -> BAYC
    /// Note. we only use proxy collection to transfer NFTs,
    ///       all other operations should use underlying Collection.(State, Log, CollectionAccount)
    ///       proxy collection has not `CollectionState`, but use underlying collection's state.
    ///       proxy collection only is used to lock infinitely.
    ///       `fragmentNFTs` and `claimRandomNFT` don't support proxy collection
    mapping(address => address) internal collectionProxy;

    uint32 internal trialDays; // trial period in days
    uint32 internal commonPoolCommission; //  the uint32 type can easily represent the number 10000
    uint32 internal safeBoxCommission; //  the uint32 type can easily represent the number 10000
    address internal paymentToken; //  Extend the validity period payment token. If it is native, use address(0)
    uint256 internal paymentAmount; // The payment amount for each additional day of extending the safebox's validity period

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(bytes32 _keyHash, uint64 _subId, address _vrfCoordinator) payable VRFConsumerBaseV2(_vrfCoordinator) {
        keyHash = _keyHash;
        subId = _subId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);

        _disableInitializers();
    }

    /// required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @dev just declare this as payable to reduce gas and bytecode
    function initialize(address _admin, address _monitor, uint32 _trialDays) external payable initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MONITOR_ROLE, _monitor);
        trialDays = _trialDays;
    }

    function setTrialDays(uint32 _trialDays) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_trialDays > 30) {
            revert Errors.InvalidParam();
        }
        trialDays = _trialDays;
    }

    // @notice set the payment token and the payment amount for extending the expiry of the nft
    function setPaymentParam(address _paymentToken, uint256 _paymentAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paymentAmount == 0) {
            revert Errors.InvalidParam();
        }
        paymentToken = _paymentToken;
        paymentAmount = _paymentAmount;
        emit PaymentParamUpdated(paymentToken, paymentAmount);
    }

    function setCommonPoolCommission(uint32 _commonPoolCommission) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_commonPoolCommission > 10_000) {
            revert Errors.InvalidParam();
        }
        commonPoolCommission = _commonPoolCommission;
    }

    function setSafeBoxCommission(uint32 _safeBoxCommission) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_safeBoxCommission > 10_000) {
            revert Errors.InvalidParam();
        }
        safeBoxCommission = _safeBoxCommission;
    }

    function pause() external onlyRole(MONITOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function supportNewCollection(address _originalNFT, address _fragmentToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        CollectionState storage collection = collectionStates[_originalNFT];
        if (collection.nextKeyId > 0) revert Errors.NftCollectionAlreadySupported();

        collection.nextKeyId = 1;
        collection.nextActivityId = 1;
        collection.fragmentToken = IFragmentToken(_fragmentToken);

        emit NewCollectionSupported(_originalNFT, _fragmentToken);
    }

    function setNewOfferToken(address _originalNFT, address _offerToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        CollectionState storage collectionState = _useCollectionState(_originalNFT);
        collectionState.offerToken = _offerToken;
        emit OfferTokenUpdated(_originalNFT, _offerToken);
    }

    // @notice supported tokens can be used for offer, auction, and raffle
    function supportNewToken(address _token, bool addOrRemove) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (supportedTokens[_token] == addOrRemove) {
            return;
        } else {
            /// true - add
            /// false - remove
            supportedTokens[_token] = addOrRemove;
            emit UpdateTokenSupported(_token, addOrRemove);
        }
    }

    function setCollectionProxy(address proxyCollection, address underlying) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (collectionProxy[proxyCollection] == underlying) {
            return;
        } else {
            collectionProxy[proxyCollection] = underlying;
            emit ProxyCollectionChanged(proxyCollection, underlying);
        }
    }

    function withdrawPlatformFee(address token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        /// track platform fee with account, only can withdraw fee accumulated during tx.
        /// no need to check credit token balance for the account.
        UserFloorAccount storage userFloorAccount = userFloorAccounts[address(this)];
        userFloorAccount.withdraw(msg.sender, token, amount, false);
    }

    function addTokens(address onBehalfOf, address token, uint256 amount) public payable whenNotPaused {
        _addSupportTokens(onBehalfOf, token, amount);
    }

    // @notice only supported tokens can be transferred in
    function _addSupportTokens(address onBehalfOf, address token, uint256 amount) internal {
        _mustSupportedToken(token);
        _addTokensInternal(onBehalfOf, token, amount);
    }

    // @notice there is no restriction here on whether the token is a supported token
    function _addTokensInternal(address onBehalfOf, address token, uint256 amount) internal {
        UserFloorAccount storage userFloorAccount = userFloorAccounts[onBehalfOf];
        userFloorAccount.deposit(onBehalfOf, token, amount, false);
    }

    function removeTokens(address token, uint256 amount, address receiver) external whenNotPaused {
        UserFloorAccount storage userFloorAccount = userFloorAccounts[msg.sender];
        userFloorAccount.withdraw(receiver, token, amount, false);
    }

    /**
     * @notice Lock specified `nftIds` into Scattering Safeboxes and receive corresponding Fragment Tokens of the `collection`
     * @param onBehalfOf who will receive the safebox and fragment tokens.(note. the NFTs of the msg.sender will be transferred)
     */
    function lockNFTs(
        address collection,
        uint256[] memory nftIds,
        address onBehalfOf
    ) external nonReentrant whenNotPaused {
        _mustValidNftIds(nftIds);

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        collectionState.lockNfts(
            LockParam({proxyCollection: collection, collection: underlying, nftIds: nftIds, rentalDays: trialDays}),
            onBehalfOf
        );
    }

    function unlockNFTs(
        address collection,
        uint256[] memory nftIds,
        address receiver
    ) external nonReentrant whenNotPaused {
        _mustValidNftIds(nftIds);
        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        // Pay the commission to the platform; verify safeBoxCommission and nftLengths(_mustValidNftIds already valid) is greater than zero
        if (safeBoxCommission > 0) {
            uint256 totalCommission = (Constants.FLOOR_TOKEN_AMOUNT * nftIds.length * safeBoxCommission) / 10_000;
            _addTokensInternal(address(this), address(collectionState.fragmentToken), totalCommission);
        }

        collectionState.unlockNfts(collection, underlying, nftIds, receiver);
    }

    function extendKeys(
        address collection,
        uint256[] memory nftIds,
        uint256 newRentalDays
    ) external payable nonReentrant whenNotPaused {
        _mustValidNftIds(nftIds);
        _mustValidRentalDays(newRentalDays);

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        // verify paymentAmount and nftLengths(_mustValidNftIds already valid) is greater than zero
        if (paymentAmount == 0) {
            revert Errors.InvalidParam();
        }
        uint256 totalPayoutAmount = (paymentAmount *
            newRentalDays *
            nftIds.length *
            Constants._calculateDiscount(Constants.EXTEND_DISCOUNT_RATE_BIPS, newRentalDays)) / 10_000;
        _addTokensInternal(address(this), paymentToken, totalPayoutAmount);

        collectionState.extendLockingForKeys(
            //            userFloorAccounts[msg.sender],
            LockParam({proxyCollection: collection, collection: underlying, nftIds: nftIds, rentalDays: newRentalDays}),
            msg.sender // todo This can be extended here to support renewing keys for other users.
        );
    }

    function tidyExpiredNFTs(address collection, uint256[] memory nftIds) external whenNotPaused {
        _mustValidNftIds(nftIds);
        /// expired safeBoxes must not be collection
        CollectionState storage collectionState = _useCollectionState(collection);
        collectionState.tidyExpiredNFTs(nftIds, collection);
    }

    function fragmentNFTs(
        address collection,
        uint256[] memory nftIds,
        address onBehalfOf
    ) external nonReentrant whenNotPaused {
        if (Constants.FUNCTION_DISABLED) {
            _disabledFunction();
        }
        _mustValidNftIds(nftIds);
        CollectionState storage collectionState = _useCollectionState(collection);

        collectionState.fragmentNFTs(collection, nftIds, onBehalfOf);
    }

    function claimRandomNFT(
        address collection,
        uint256 claimCnt,
        address receiver
    ) external nonReentrant whenNotPaused {
        if (receiver == address(this)) {
            revert Errors.InvalidParam();
        }
        CollectionState storage collectionState = _useCollectionState(collection);
        // verify paymentAmount and claimCnt is greater than zero
        if (commonPoolCommission > 0 && claimCnt > 0) {
            uint256 totalCommission = (Constants.FLOOR_TOKEN_AMOUNT * claimCnt * commonPoolCommission) / 10_000;
            _addTokensInternal(address(this), address(collectionState.fragmentToken), totalCommission);
        }
        collectionState.claimRandomNFT(collection, claimCnt, receiver);
    }

    function initAuctionOnVault(
        address collection,
        uint256[] memory vaultIdx,
        address bidToken,
        uint96 bidAmount
    ) external nonReentrant whenNotPaused {
        if (Constants.FUNCTION_DISABLED) {
            _disabledFunction();
        }
        _mustValidNftIds(vaultIdx);
        _mustValidTransferAmount(bidToken, bidAmount);
        _mustSupportedToken(bidToken);

        CollectionState storage collectionState = _useCollectionState(collection);
        collectionState.initAuctionOnVault(userFloorAccounts, collection, vaultIdx, bidToken, bidAmount);
    }

    function initAuctionOnExpiredSafeBoxes(
        address collection,
        uint256[] memory nftIds,
        address bidToken,
        uint256 bidAmount
    ) external nonReentrant whenNotPaused {
        if (Constants.FUNCTION_DISABLED) {
            _disabledFunction();
        }
        _mustValidNftIds(nftIds);
        _mustValidTransferAmount(bidToken, bidAmount);
        _mustSupportedToken(bidToken);

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        collectionState.initAuctionOnExpiredSafeBoxes(userFloorAccounts, underlying, nftIds, bidToken, bidAmount);
    }

    function ownerInitAuctions(
        address collection,
        uint256[] memory nftIds,
        address token,
        uint256 minimumBid
    ) external nonReentrant whenNotPaused {
        if (Constants.FUNCTION_DISABLED) {
            _disabledFunction();
        }
        _mustValidNftIds(nftIds);
        _mustValidTransferAmount(token, minimumBid);
        _mustSupportedToken(token);

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        collectionState.ownerInitAuctions(userFloorAccounts, /* creditToken,*/ underlying, nftIds, token, minimumBid);
    }

    function placeBidOnAuction(
        address collection,
        uint256 nftId,
        uint256 bidAmount,
        address token,
        uint256 amountToTransfer
    ) external payable nonReentrant whenNotPaused {
        _addSupportTokens(msg.sender, token, amountToTransfer);

        /// we don't check whether msg.value is equal to bidAmount, as we utility all currency balance of user account,
        /// it will be reverted if there is no enough balance to pay the required bid.
        _placeBidOnAuction(collection, nftId, bidAmount /*, bidOptionIdx*/);
    }

    function _placeBidOnAuction(address collection, uint256 nftId, uint256 bidAmount) internal {
        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        collectionState.placeBidOnAuction(userFloorAccounts, underlying, nftId, bidAmount);
    }

    function settleAuctions(address collection, uint256[] memory nftIds) external nonReentrant whenNotPaused {
        _mustValidNftIds(nftIds);
        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collection);
        collectionState.settleAuctions(userFloorAccounts, underlying, nftIds);
    }

    function ownerInitRaffles(RaffleInitParam memory param) external nonReentrant whenNotPaused {
        if (Constants.FUNCTION_DISABLED) {
            _disabledFunction();
        }
        _mustValidNftIds(param.nftIds);
        _mustValidTransferAmount(param.ticketToken, param.ticketPrice);
        _mustSupportedToken(param.ticketToken);

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(param.collection);
        param.collection = underlying;

        collectionState.ownerInitRaffles(userFloorAccounts, param /*, creditToken*/);
    }

    function buyRaffleTickets(
        address collectionId,
        uint256 nftId,
        uint256 ticketCnt,
        address token,
        uint256 amountToTransfer
    ) external payable nonReentrant whenNotPaused {
        _addSupportTokens(msg.sender, token, amountToTransfer);
        _buyRaffleTicketsInternal(collectionId, nftId, ticketCnt);
    }

    function _buyRaffleTicketsInternal(address collectionId, uint256 nftId, uint256 ticketCnt) internal {
        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collectionId);

        collectionState.buyRaffleTickets(userFloorAccounts, /* creditToken,*/ underlying, nftId, ticketCnt);
    }

    function settleRaffles(address collectionId, uint256[] memory nftIds) external nonReentrant whenNotPaused {
        _mustValidNftIds(nftIds);
        if (nftIds.length > 8) revert Errors.InvalidParam();
        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collectionId);

        (bytes memory toSettleNftIds, uint256 len) = collectionState.prepareSettleRaffles(nftIds);
        if (len > 0) {
            uint256 requestId = COORDINATOR.requestRandomWords(keyHash, subId, 3, 800_000, uint32(len));
            randomnessRequestToReceiver[requestId] = RandomRequestInfo({
                typ: 1,
                collection: underlying,
                data: toSettleNftIds
            });
        }
    }

    function _completeSettleRaffles(address collectionId, bytes memory data, uint256[] memory randoms) private {
        CollectionState storage collection = collectionStates[collectionId];
        collection.settleRaffles(userFloorAccounts, collectionId, data, randoms);
    }

    function ownerInitPrivateOffers(PrivateOfferInitParam memory param) external nonReentrant whenNotPaused {
        _mustValidNftIds(param.nftIds);
        _mustValidTransferAmount(param.token, param.price);
        // a comparison is made below, so next line can be removed
        //  _mustSupportedToken(param.token);
        if (param.receiver != address(0)) {
            _disabledFunction();
        }

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(param.collection);
        if (collectionState.offerToken != param.token) {
            revert Errors.TokenNotSupported();
        }
        param.collection = underlying;
        collectionState.ownerInitPrivateOffers(/*userFloorAccounts,  creditToken,*/ param);
    }

    function cancelPrivateOffers(address collectionId, uint256[] memory nftIds) external whenNotPaused {
        _mustValidNftIds(nftIds);
        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collectionId);
        collectionState.removePrivateOffers(underlying, nftIds);
    }

    function buyerAcceptPrivateOffers(
        address collectionId,
        uint256[] memory nftIds,
        address token,
        uint256 amountToTransfer
    ) external payable nonReentrant whenNotPaused {
        _mustValidNftIds(nftIds);
        _addSupportTokens(msg.sender, token, amountToTransfer);

        (CollectionState storage collectionState, address underlying) = _useUnderlyingCollectionState(collectionId);
        collectionState.buyerAcceptPrivateOffers(userFloorAccounts, underlying, nftIds /*, creditToken*/);
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _useUnderlyingCollectionState(
        address collectionId
    ) private view returns (CollectionState storage, address) {
        address underlying = collectionProxy[collectionId];
        if (underlying == address(0)) {
            underlying = collectionId;
        }

        return (_useCollectionState(underlying), underlying);
    }

    function _useCollectionState(address collectionId) private view returns (CollectionState storage) {
        CollectionState storage collection = collectionStates[collectionId];
        if (collection.nextKeyId == 0) revert Errors.NftCollectionNotSupported();
        return collection;
    }

    function _disabledFunction() private pure {
        revert Errors.DisabledFunction();
    }

    function _mustSupportedToken(address token) private view {
        if (!supportedTokens[token]) revert Errors.TokenNotSupported();
    }

    // @notice the minimum amount for transfer is 0.0001 token;
    // if the decimal places are less than 4, the minimum transfer amount is 1 token
    function _mustValidTransferAmount(address token, uint256 amount) private view {
        uint8 decimals;
        if (token == CurrencyTransfer.NATIVE) {
            decimals = 18;
        } else {
            decimals = IERC20Metadata(token).decimals();
        }
        uint256 minAmount = 10 ** (decimals > 3 ? 4 : 0);
        if (amount < minAmount) {
            revert Errors.AmountTooSmall(minAmount, amount);
        }
    }

    function _mustValidNftIds(uint256[] memory nftIds) private pure {
        if (nftIds.length == 0) revert Errors.InvalidParam();

        /// nftIds should be ordered and there should be no duplicate elements.
        for (uint256 i = 1; i < nftIds.length; ) {
            unchecked {
                if (nftIds[i] <= nftIds[i - 1]) {
                    revert Errors.InvalidParam();
                }
                ++i;
            }
        }
    }

    // @notice ensure that the maximum value does not exceed uint32 to prevent data overflow; setting it to uint24 should be sufficient
    function _mustValidRentalDays(uint256 rentalDays) private pure {
        if (rentalDays == 0 || rentalDays > type(uint24).max) revert Errors.InvalidParam();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        RandomRequestInfo storage info = randomnessRequestToReceiver[requestId];

        _completeSettleRaffles(info.collection, info.data, randomWords);

        delete randomnessRequestToReceiver[requestId];
    }

    function extsload(bytes32 slot) external view returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := sload(slot)
        }
    }

    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes memory) {
        bytes memory value = new bytes(nSlots << 5);

        /// @solidity memory-safe-assembly
        assembly {
            for {
                let i := 0
            } lt(i, nSlots) {
                i := add(i, 1)
            } {
                mstore(add(value, shl(5, add(i, 1))), sload(add(startSlot, i)))
            }
        }

        return value;
    }

    receive() external payable {
        _addSupportTokens(msg.sender, CurrencyTransfer.NATIVE, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        AccessControlStorage storage $ = _getAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/AccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControlEnumerable} from "lib/openzeppelin-contracts/contracts/access/extensions/IAccessControlEnumerable.sol";
import {AccessControlUpgradeable} from "../AccessControlUpgradeable.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControlEnumerable
    struct AccessControlEnumerableStorage {
        mapping(bytes32 role => EnumerableSet.AddressSet) _roleMembers;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlEnumerable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlEnumerableStorageLocation = 0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000;

    function _getAccessControlEnumerableStorage() private pure returns (AccessControlEnumerableStorage storage $) {
        assembly {
            $.slot := AccessControlEnumerableStorageLocation
        }
    }

    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        return $._roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual returns (uint256) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        return $._roleMembers[role].length();
    }

    /**
     * @dev Overload {AccessControl-_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        bool granted = super._grantRole(role, account);
        if (granted) {
            $._roleMembers[role].add(account);
        }
        return granted;
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        bool revoked = super._revokeRole(role, account);
        if (revoked) {
            $._roleMembers[role].remove(account);
        }
        return revoked;
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/IAccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "../IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}