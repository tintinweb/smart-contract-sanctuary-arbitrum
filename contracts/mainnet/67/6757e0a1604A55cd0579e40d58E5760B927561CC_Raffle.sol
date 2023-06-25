//SPDX Identifier: MIT

pragma solidity 0.8.17;

interface IRaffle {
    enum RaffleStatus {
        None,
        Created,
        Open,
        Drawing,
        RandomnessFulfilled,
        Drawn,
        Complete,
        Refundable,
        Cancelled
    }

    enum TokenType {
        ERC721,
        ERC1155,
        ETH,
        ERC20
    }

    /**
     * @param entriesCount The number of entries that can be purchased for the given price.
     * @param price The price of the entries.
     */
    struct PricingOption {
        uint40 entriesCount;
        uint208 price;
    }

    /**
     * @param currentEntryIndex The cumulative number of entries in the raffle.
     * @param participant The address of the participant.
     */
    struct Entry {
        uint40 currentEntryIndex;
        address participant;
    }

    /**
     * @param participant The address of the winner.
     * @param claimed Whether the winner has claimed the prize.
     * @param prizeIndex The index of the prize that was won.
     * @param entryIndex The index of the entry that won.
     */
    struct Winner {
        address participant;
        bool claimed;
        uint8 prizeIndex;
        uint40 entryIndex;
    }

    /**
     * @param winnersCount The number of winners.
     * @param cumulativeWinnersCount The cumulative number of winners in the raffle.
     * @param prizeType The type of the prize.
     * @param prizeTier The tier of the prize.
     * @param prizeAddress The address of the prize.
     * @param prizeId The id of the prize.
     * @param prizeAmount The amount of the prize.
     */
    struct Prize {
        uint40 winnersCount;
        uint40 cumulativeWinnersCount;
        TokenType prizeType;
        uint8 prizeTier;
        address prizeAddress;
        uint256 prizeId;
        uint256 prizeAmount;
    }

    /**
     * @param owner The address of the raffle owner.
     * @param status The status of the raffle.
     * @param isMinimumEntriesFixed Whether the minimum number of entries is fixed.
     * @param cutoffTime The time after which the raffle cannot be entered.
     * @param drawnAt The time at which the raffle was drawn. It is still pending Chainlink to fulfill the randomness request.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the raffle was created.
     * @param claimableFees The amount of fees collected from selling entries.
     * @param pricingOptions The pricing options for the raffle.
     * @param prizes The prizes to be distributed.
     * @param entries The entries that have been sold.
     * @param winners The winners of the raffle.
     */
    struct Raffle {
        address owner;
        RaffleStatus status;
        bool isMinimumEntriesFixed;
        uint40 cutoffTime;
        uint40 drawnAt;
        uint40 minimumEntries;
        uint40 maximumEntriesPerParticipant;
        address feeTokenAddress;
        uint16 protocolFeeBp;
        uint208 claimableFees;
        PricingOption[5] pricingOptions;
        Prize[] prizes;
        Entry[] entries;
        Winner[] winners;
    }

    /**
     * @param amountPaid The amount paid by the participant.
     * @param entriesCount The number of entries purchased by the participant.
     * @param refunded Whether the participant has been refunded.
     */
    struct ParticipantStats {
        uint208 amountPaid;
        uint40 entriesCount;
        bool refunded;
    }

    /**
     * @param raffleId The id of the raffle.
     * @param pricingOptionIndex The index of the selected pricing option.
     */
    struct EntryCalldata {
        uint256 raffleId;
        uint256 pricingOptionIndex;
    }

    /**
     * @param cutoffTime The time at which the raffle will be closed.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param isMinimumEntriesFixed Whether the minimum number of entries is fixed.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the raffle was created.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param prizes The prizes to be distributed.
     * @param pricingOptions The pricing options for the raffle.
     */
    struct CreateRaffleCalldata {
        uint40 cutoffTime;
        bool isMinimumEntriesFixed;
        uint40 minimumEntries;
        uint40 maximumEntriesPerParticipant;
        uint16 protocolFeeBp;
        address feeTokenAddress;
        Prize[] prizes;
        PricingOption[5] pricingOptions;
    }

    struct ClaimPrizesCalldata {
        uint256 raffleId;
        uint256[] winnerIndices;
    }

    /**
     * @param exists Whether the request exists.
     * @param raffleId The id of the raffle.
     * @param randomWord The random words returned by Chainlink VRF.
     *                   If randomWord == 0, then the request is still pending.
     */
    struct RandomnessRequest {
        bool exists;
        uint248 randomWord;
        uint256 raffleId;
    }

    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);
    event EntryRefunded(uint256 raffleId, address buyer, uint208 amount);
    event EntrySold(uint256 raffleId, address buyer, uint40 entriesCount, uint208 price);
    event FeesClaimed(uint256 raffleId, uint256 amount);
    event PrizesClaimed(uint256 raffleId, uint256[] winnerIndex);
    event ProtocolFeeBpUpdated(uint16 protocolFeeBp);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RaffleStatusUpdated(uint256 raffleId, RaffleStatus status);
    event RandomnessRequested(uint256 raffleId, uint256 requestId);

    error AlreadyRefunded();
    error CutoffTimeNotReached();
    error CutoffTimeReached();
    error DrawExpirationTimeNotReached();
    error InsufficientNativeTokensSupplied();
    error InvalidCaller();
    error InvalidCurrency();
    error InvalidCutoffTime();
    error InvalidIndex();
    error InvalidPricingOption();
    error InvalidPrize();
    error InvalidPrizesCount();
    error InvalidProtocolFeeBp();
    error InvalidProtocolFeeRecipient();
    error InvalidStatus();
    error InvalidWinnersCount();
    error MaximumEntriesPerParticipantReached();
    error MaximumEntriesReached();
    error PrizeAlreadyClaimed();
    error RandomnessRequestAlreadyExists();
    error RandomnessRequestDoesNotExist();

    /**
     * @notice Creates a new raffle.
     * @param params The parameters of the raffle.
     * @return raffleId The id of the newly created raffle.
     */
    function createRaffle(CreateRaffleCalldata calldata params) external returns (uint256 raffleId);

    /**
     * @notice Deposits prizes for a raffle.
     * @param raffleId The id of the raffle.
     */
    function depositPrizes(uint256 raffleId) external payable;

    /**
     * @notice Enters a raffle or multiple raffles.
     * @param entries The entries to be made.
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable;

    /**
     * @notice Select the winners for a raffle based on the random words returned by Chainlink.
     * @param requestId The request id returned by Chainlink.
     */
    function selectWinners(uint256 requestId) external;

    /**
     * @notice Claims the prizes for a winner. A winner can claim multiple prizes
     *         from multiple raffles in a single transaction.
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external;

    /**
     * @notice Claims the fees collected for a raffle.
     * @param raffleId The id of the raffle.
     */
    function claimFees(uint256 raffleId) external;

    /**
     * @notice Cancels a raffle beyond cut-off time without meeting minimum entries.
     * @param raffleId The id of the raffle.
     */
    function cancel(uint256 raffleId) external;

    /**
     * @notice Cancels a raffle after randomness request if the randomness request
     *         does not arrive after a certain amount of time.
     *         Only callable by contract owner.
     * @param raffleId The id of the raffle.
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external;

    /**
     * @notice Withdraws the prizes for a raffle after it has been marked as refundable.
     * @param raffleId The id of the raffle.
     */
    function withdrawPrizes(uint256 raffleId) external;

    /**
     * @notice Claims the refund for a cancelled raffle.
     * @param raffleIds The ids of the raffles.
     */
    function claimRefund(uint256[] calldata raffleIds) external;

    /**
     * @notice Claims the protocol fees collected for a raffle.
     * @param currency The currency of the fees to be claimed.
     */
    function claimProtocolFees(address currency) external;

    /**
     * @notice Sets the protocol fee in basis points. Only callable by contract owner.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    function setProtocolFeeBp(uint16 protocolFeeBp) external;

    /**
     * @notice Sets the protocol fee recipient. Only callable by contract owner.
     * @param protocolFeeRecipient The protocol fee recipient.
     */
    function setProtocolFeeRecipient(address protocolFeeRecipient) external;

    /**
     * @notice This function allows the owner to update currency statuses.
     * @param currencies Currency addresses (address(0) for ETH)
     * @param isAllowed Whether the currencies should be allowed for trading
     * @dev Only callable by owner.
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external;

    /**
     * @notice Toggle the contract's paused status. Only callable by contract owner.
     */
    function togglePaused() external;

    /**
     * @notice Gets the winners for a raffle.
     * @param raffleId The id of the raffle.
     * @return winners The winners of the raffle.
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory);

    /**
     * @notice Gets the pricing options for a raffle.
     * @param raffleId The id of the raffle.
     * @return pricingOptions The pricing options for the raffle.
     */
    function getPricingOptions(uint256 raffleId) external view returns (PricingOption[5] memory);

    /**
     * @notice Gets the prizes for a raffle.
     * @param raffleId The id of the raffle.
     * @return prizes The prizes to be distributed.
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory);

    /**
     * @notice Gets the entries for a raffle.
     * @param raffleId The id of the raffle.
     * @return entries The entries entered for the raffle.
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory);
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/WinningEntrySearchLogic.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity 0.8.17;

/**
 * @title WinningEntrySearchLogic
 * @notice This contract contains the logic to search for a winning entry.
 * @author LooksRare protocol team (👀,💎)
 */
contract WinningEntrySearchLogic {
    /**
     * @param currentEntryIndex The current entry index.
     * @param winningEntry The winning entry.
     * @param winningEntriesBitmap The bitmap of winning entries.
     */
    function _incrementWinningEntryUntilThereIsNotADuplicate(
        uint256 currentEntryIndex,
        uint256 winningEntry,
        uint256[] memory winningEntriesBitmap
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 bucket = winningEntry >> 8;
        uint256 mask = 1 << (winningEntry & 0xff);
        while (winningEntriesBitmap[bucket] & mask != 0) {
            if (winningEntry == currentEntryIndex) {
                bucket = 0;
                winningEntry = 0;
            } else {
                winningEntry += 1;
                if (winningEntry % 256 == 0) {
                    unchecked {
                        bucket += 1;
                    }
                }
            }

            mask = 1 << (winningEntry & 0xff);
        }

        winningEntriesBitmap[bucket] |= mask;

        return (winningEntry, winningEntriesBitmap);
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/Math.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/


pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/Arrays.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity 0.8.17;


/**
 * @dev Collection of functions related to array types.
 *      Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Arrays.sol
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                unchecked {
                    low = mid + 1;
                }
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            unchecked {
                return low - 1;
            }
        } else {
            return low;
        }
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/VRFConsumerBaseV2.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

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
//File： fs://f7f5061f15494403ad5efe4eba4e9268/VRFCoordinatorV2Interface.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

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
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

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
//File： fs://f7f5061f15494403ad5efe4eba4e9268/Pausable.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

/**
 * @title Pausable
 * @notice This contract makes it possible to pause the contract.
 *         It is adjusted from OpenZeppelin.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    error IsPaused();
    error NotPaused();

    bool private _paused;

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
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert IsPaused();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert NotPaused();
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
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/IReentrancyGuard.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

/**
 * @title IReentrancyGuard
 * @author LooksRare protocol team (👀,💎)
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/IOwnableTwoSteps.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

/**
 * @title IOwnableTwoSteps
 * @author LooksRare protocol team (👀,💎)
 */
interface IOwnableTwoSteps {
    /**
     * @notice This enum keeps track of the ownership status.
     * @param NoOngoingTransfer The default status when the owner is set
     * @param TransferInProgress The status when a transfer to a new owner is initialized
     * @param RenouncementInProgress The status when a transfer to address(0) is initialized
     */
    enum Status {
        NoOngoingTransfer,
        TransferInProgress,
        RenouncementInProgress
    }

    /**
     * @notice This is returned when there is no transfer of ownership in progress.
     */
    error NoOngoingTransferInProgress();

    /**
     * @notice This is returned when the caller is not the owner.
     */
    error NotOwner();

    /**
     * @notice This is returned when there is no renouncement in progress but
     *         the owner tries to validate the ownership renouncement.
     */
    error RenouncementNotInProgress();

    /**
     * @notice This is returned when the transfer is already in progress but the owner tries
     *         initiate a new ownership transfer.
     */
    error TransferAlreadyInProgress();

    /**
     * @notice This is returned when there is no ownership transfer in progress but the
     *         ownership change tries to be approved.
     */
    error TransferNotInProgress();

    /**
     * @notice This is returned when the ownership transfer is attempted to be validated by the
     *         a caller that is not the potential owner.
     */
    error WrongPotentialOwner();

    /**
     * @notice This is emitted if the ownership transfer is cancelled.
     */
    event CancelOwnershipTransfer();

    /**
     * @notice This is emitted if the ownership renouncement is initiated.
     */
    event InitiateOwnershipRenouncement();

    /**
     * @notice This is emitted if the ownership transfer is initiated.
     * @param previousOwner Previous/current owner
     * @param potentialOwner Potential/future owner
     */
    event InitiateOwnershipTransfer(address previousOwner, address potentialOwner);

    /**
     * @notice This is emitted when there is a new owner.
     */
    event NewOwner(address newOwner);
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/IERC1155.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/LowLevelERC1155Transfer.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

// Interfaces


// Errors



/**
 * @title LowLevelERC1155Transfer
 * @notice This contract contains low-level calls to transfer ERC1155 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC1155Transfer {
    /**
     * @notice Execute ERC1155 safeTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     * @param amount Amount to transfer
     */
    function _executeERC1155SafeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ERC1155SafeTransferFromFail();
        }
    }

    /**
     * @notice Execute ERC1155 safeBatchTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenIds Array of tokenIds to transfer
     * @param amounts Array of amounts to transfer
     */
    function _executeERC1155SafeBatchTransferFrom(
        address collection,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(
            abi.encodeCall(IERC1155.safeBatchTransferFrom, (from, to, tokenIds, amounts, ""))
        );

        if (!status) {
            revert ERC1155SafeBatchTransferFromFail();
        }
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/IERC721.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/LowLevelERC721Transfer.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

// Interfaces


// Errors



/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC721Transfer {
    /**
     * @notice Execute ERC721 transferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     */
    function _executeERC721TransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ERC721TransferFromFail();
        }
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/GenericErrors.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the call recipient is not a contract.
 */
error NotAContract();
//File： fs://f7f5061f15494403ad5efe4eba4e9268/LowLevelErrors.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the ETH transfer fails.
 */
error ETHTransferFail();

/**
 * @notice It is emitted if the ERC20 approval fails.
 */
error ERC20ApprovalFail();

/**
 * @notice It is emitted if the ERC20 transfer fails.
 */
error ERC20TransferFail();

/**
 * @notice It is emitted if the ERC20 transferFrom fails.
 */
error ERC20TransferFromFail();

/**
 * @notice It is emitted if the ERC721 transferFrom fails.
 */
error ERC721TransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeTransferFrom fails.
 */
error ERC1155SafeTransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeBatchTransferFrom fails.
 */
error ERC1155SafeBatchTransferFromFail();
//File： fs://f7f5061f15494403ad5efe4eba4e9268/IERC20.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/LowLevelERC20Transfer.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

// Interfaces


// Errors



/**
 * @title LowLevelERC20Transfer
 * @notice This contract contains low-level calls to transfer ERC20 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC20Transfer {
    /**
     * @notice Execute ERC20 transferFrom
     * @param currency Currency address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20TransferFrom(address currency, address from, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transferFrom, (from, to, amount)));

        if (!status) {
            revert ERC20TransferFromFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFromFail();
            }
        }
    }

    /**
     * @notice Execute ERC20 (direct) transfer
     * @param currency Currency address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20DirectTransfer(address currency, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transfer, (to, amount)));

        if (!status) {
            revert ERC20TransferFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFail();
            }
        }
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/IWETH.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256 wad) external;
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/LowLevelWETH.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

// Interfaces


/**
 * @title LowLevelWETH
 * @notice This contract contains a function to transfer ETH with an option to wrap to WETH.
 *         If the ETH transfer fails within a gas limit, the amount in ETH is wrapped to WETH and then transferred.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelWETH {
    /**
     * @notice It transfers ETH to a recipient with a specified gas limit.
     *         If the original transfers fails, it wraps to WETH and transfers the WETH to recipient.
     * @param _WETH WETH address
     * @param _to Recipient address
     * @param _amount Amount to transfer
     * @param _gasLimit Gas limit to perform the ETH transfer
     */
    function _transferETHAndWrapIfFailWithGasLimit(
        address _WETH,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal {
        bool status;

        assembly {
            status := call(_gasLimit, _to, _amount, 0, 0, 0, 0)
        }

        if (!status) {
            IWETH(_WETH).deposit{value: _amount}();
            IWETH(_WETH).transfer(_to, _amount);
        }
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/OwnableTwoSteps.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

// Interfaces


/**
 * @title OwnableTwoSteps
 * @notice This contract offers transfer of ownership in two steps with potential owner
 *         having to confirm the transaction to become the owner.
 *         Renouncement of the ownership is also a two-step process since the next potential owner is the address(0).
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract OwnableTwoSteps is IOwnableTwoSteps {
    /**
     * @notice Address of the current owner.
     */
    address public owner;

    /**
     * @notice Address of the potential owner.
     */
    address public potentialOwner;

    /**
     * @notice Ownership status.
     */
    Status public ownershipStatus;

    /**
     * @notice Modifier to wrap functions for contracts that inherit this contract.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _owner The contract's owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit NewOwner(_owner);
    }

    /**
     * @notice This function is used to cancel the ownership transfer.
     * @dev This function can be used for both cancelling a transfer to a new owner and
     *      cancelling the renouncement of the ownership.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        Status _ownershipStatus = ownershipStatus;
        if (_ownershipStatus == Status.NoOngoingTransfer) {
            revert NoOngoingTransferInProgress();
        }

        if (_ownershipStatus == Status.TransferInProgress) {
            delete potentialOwner;
        }

        delete ownershipStatus;

        emit CancelOwnershipTransfer();
    }

    /**
     * @notice This function is used to confirm the ownership renouncement.
     */
    function confirmOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.RenouncementInProgress) {
            revert RenouncementNotInProgress();
        }

        delete owner;
        delete ownershipStatus;

        emit NewOwner(address(0));
    }

    /**
     * @notice This function is used to confirm the ownership transfer.
     * @dev This function can only be called by the current potential owner.
     */
    function confirmOwnershipTransfer() external {
        if (ownershipStatus != Status.TransferInProgress) {
            revert TransferNotInProgress();
        }

        if (msg.sender != potentialOwner) {
            revert WrongPotentialOwner();
        }

        owner = msg.sender;
        delete ownershipStatus;
        delete potentialOwner;

        emit NewOwner(msg.sender);
    }

    /**
     * @notice This function is used to initiate the transfer of ownership to a new owner.
     * @param newPotentialOwner New potential owner address
     */
    function initiateOwnershipTransfer(address newPotentialOwner) external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.TransferInProgress;
        potentialOwner = newPotentialOwner;

        /**
         * @dev This function can only be called by the owner, so msg.sender is the owner.
         *      We don't have to SLOAD the owner again.
         */
        emit InitiateOwnershipTransfer(msg.sender, newPotentialOwner);
    }

    /**
     * @notice This function is used to initiate the ownership renouncement.
     */
    function initiateOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.RenouncementInProgress;

        emit InitiateOwnershipRenouncement();
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/PackableReentrancyGuard.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity ^0.8.17;

// Interfaces


/**
 * @title PackableReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 *         The only difference between this contract and ReentrancyGuard
 *         is that _status is uint8 instead of uint256 so that it can be
 *         packed with other contracts' storage variables.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract PackableReentrancyGuard is IReentrancyGuard {
    uint8 private _status;

    /**
     * @notice Modifier to wrap functions to prevent reentrancy calls.
     */
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrancyFail();
        }

        _status = 2;
        _;
        _status = 1;
    }

    constructor() {
        _status = 1;
    }
}
//File： fs://f7f5061f15494403ad5efe4eba4e9268/Raffle.sol
/*
  
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/Raffle/?utm=code
*/

pragma solidity 0.8.17;













// ....................................................................................................
// .......................................,,,,,,.......................................................
// ....................................,;+??????*;;:..................,,,,,,,,.........................
// ..................................,+?????????????*;,............:;*????????*;,......................
// ................................,+??????????????*???+,.......:+*??????????????*:....................
// ..............................:+?????????*????????*???+:,.,;*???????????????????*,..................
// ............................,*???????????%%%%%%%%%%??*???*???????????????????????*,.................
// ..........................,;???????????%%??????????%%%?*????????????????????????*?;.................
// .........................:???????????%%???????????????%%???????*?????????????*?**?*.................
// ........................:%%%???????%%?*??????????????**?%?**???%%%%%%%%%%%%%%??????,,,,.............
// ......................,*SSSSS?????%?*??????????*??????%??%%??????????????***???????????*;:..........
// .....................:%S%%%%SS??????????????*??%%%%%%%?????%%%%??*????????????????????????+,........
// ....................:SS%%%%%%#?*????????????%%%????**???????*??%%%?*??%%%%%%%?????????%%%%%:........
// ....................+S?%%%%%%S%*?????????*?%%?**??%%%%%%%%%%%??*?%??%%??????????%%%%%?????%?+,......
// ..................,;%%%%%%%%%%S*???????*??%?*??%%%???????????%%%??S%????%%%%%%???????%%%%????*,.....
// .................;?S#%%%%?SS%%S*???????%%%?*?%%??*??****????????%%%?%%%?????????*++++*?%%%%%??:.....
// ...............,*%?S%%%%%%S%%SS*????%%%????%%??*????%SSS##S***?????%???*????*;,,:::;:,,:+???%S+.....
// ..............,*?*?S%%%%%%#SSS?????%???*?%%???????%@@@@@@##S:.,:+????????+:,..:%@@@%@#*,..:*???+....
// ..............+????S%%%%%%S%???????????%%??*???+:+#@@@@@[email protected]@#:...,;????+,....;@@@@@%@@@#+...:???:...
// .............:?????S%%%%%%S*????%%%%%%%??????+,.,#[email protected]@@;[email protected]@@%.....+%*,.....,[email protected]@@@@?;*#@@+...,+?,...
// .............*?????S%%%%%%S*????%**???**???+,[email protected]#@@@S..,#@@@;....;*.......+%[email protected]@@%...;@@#,....;:...
// ............;??????S%%%%%%S?????%%???????+,....,#@@@@@#:.,#@@@%....;,[email protected]@@@@*....#@@+....,;...
// ...........,???????S%%%%%%S????????%%%%:,......:@@@@@@@S*%@@@@#,..,;.......,#@@@@@[email protected]@%....:;...
// ...........;???????%S%%%%%SS*??????**???:......:@@@@@@@@@@@@@@@+..::.......,@@@@@@#;,.;@@@#,..,+,...
// ..........,?????????S%%%%%%S?????????????*:....,#@@@@@@@@@@@@@@?.,+:.......,@@@@@@@@#[email protected]@@@@:.;+,....
// ..........;????????*S%%%%%%SS*?????????????*:[email protected]@@@@@@@@@@@@@S+?%*::,....,#@@@@@@@@@@@@@@?*%;.....
// ..........*????????*SS%S#S?%S??????????%?**??*;,*@@@@@@@@@@@@#S%???%???**+;:[email protected]@@@@@@@##S%?????:.....
// .........:?????????*%#S%%S%%%S???*??????%%%??????####@@@@#S%?***?%%?????????%%%%??????*****?*:......
// .........*?????????*%#?*%S%%%S?*?%%%%%%%%?%%%%%%%%???????****??%%%????????????????????????%;........
// ........:?????????*%#?**S%?%%%S%%%?????%%%%%????????%%%%%%%%%%%?????????????%%%%%%%%%%%%%%+.........
// ........*??????????#%*?*%SSSS%S#???????????%%%%%??***???????????????????????*??*??*?????*%+:........
// .......:?????????*%#?????%%%S%%S%??????????????%%%%%???***??????????????????????????**??%%%%+.......
// .......*??????????#%*???***S%%%%#????S#S%%?????????%%%%%%?????*?????????????????**???%%%%????.......
// ......:?????????*SS*???????SSSS%SS??SS%S#%%%%???????????%%%%%%%%?????????????????%%%%%???????.......
// ......+????????*?#????????????%S%SSSS%%%SS?%%%%%%?????????????%%%%%%%%%%%%%%%%%%%%?????????%+.......
// ......*?????????#S??????????*?S%%%SS%%%%%S%????%%%%%?????????????????????????????????????%%+,.......
// ......*???????*%#SS?????????*%%%%%%%%%%%%%#???????%%%%%%%?????????????????????????????%%?+:.........
// ......*????????SS%SS?*?????*%%%%%%%%%%%%%%SS???????????%%%%%%%??????????????????%%%%%%%%*...........
// .....;S%???????#%%%SS?*???*%#%%%%%%%%%%%%%%#%%?????????????%%%%%%%%%%%%%%%%%%%%%%%%??????,..........
// ...,?SSS%*???*SS%%%%S#?*?*%#%#%%%%%%%%%%%%%S?%%%%????????????????????????????????????????,..........
// ...?S%%%S?*???S%%%%%%S#?*?#?*%SS%%%%%%%%%%%S?*??%%%%???????????????????????????????????%?...........
// .,?S%%%%SS%?*%S%%%%%%%SS?S%*?*?SS%%%%%%%%%%S????*??%%%%%%%????????????????????????????%%:...........
// .*#%%%%%%%SS%S%%%%%%%%%S#S??????%S#S%%%%?%SS???????*?????%%%%%%%%%%%%%%%%%??????????%%*:............
// ;S%%%%%%%%%S#S%%%%%%%%%S#????????*?SSSSSSS#??????????????*?????????%%%%%%%%%%%%%S%??+,..............
// %S%%%%%%%%%SS%%%%%%%%%%S%*????????**%%%%%##????????????????????????*******??????+,..................
// S%%%%%%%%%SS%%%%%%%%%%S#%%?????**???****?SS%*??????????????????????????????**+:,....................
// %%%%%%%%S#S%%%%%%%%%%%S???%%%%%%?????????SSS*??????????????????***??+;;;::,.........................
// %%%%%%%S#S%%%%%%%%%%%SS?***??????%%%%%%%%SSS?????????????????????%?:................................
// %%%%%%SSS%%%%%%%%%%%S#SS%????*****???????%SS%%%%%%%%%%%%%%%%%??%%+,.................................
// %%%%%%%%%%%%%%%%%%%%SS%SSSSSS%%????******%SS?************?***?%*:...................................
// %%%%%%%%%%%%%%%%%%%%#S%%%%%%SSSSSSS%%%???%SS%???????????????%S#+....................................
// %%%%%%%%%%%%%%%%%%%S#%%%%%%%%%%%%%SSSSSSSS#%#SSSSSSSSSSSSSSSS%S%,...................................
// %%%%%%%%%%%%%%%%%%%#S%%%%%%%%%%%%%%%%%S####%#%%%%%%%%%%%%%%%%%%S+...................................
// %%%%%%%%%%%%%%%%%%S#%%%%%%%%%%%%%%%%%%#S%[email protected]%#S%%%%%%%%%%%%%%%%%S%,..................................
// %%%%%%%%%%%%%%%%%%#S%%%%%%%%%%%%%%%%%SS%#S#%SS%%%%%%%%%%%%%%%%%%S*..................................
// %%%%%%%%%%%%%%%%%S#S%%%%%%%%%%%%%%%%%SSSS##S%#%%%%%%%%%%%%%%%%%%%S:.................................
// %%%%%%%%%%%%%%%%%SS%%%%%%%%%%%%%%%%%%%#####%%#%%%%%%%%%%%%%%%%%%%S*.................................
// %%%%%%%%%%%%%%%%%#S%%%%%%%%%%%%%%%%%%%S#S%%?S#%%%%%%%%%%%%%%%%%%%SS,................................
// %%%%%%%%%%%%%%%%S#S%%%%%%%%%%%%%%%%%%%%S#SS##S%%%%%%%%%%%%%%%%%%%%S;................................
// %%%%%%%%%%%%%%%%SS%%%%%%%%%%%%%%%%%%%%%%SS##S%%%%%%%%%%%%%%%%%%%%%S?................................
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SSS%%%%%%%%%%%%%%%%%%%%%S%,...............................
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#SS%%%%%%%%%%%%%%%%%%%%%%S:...............................
// ...................... [Calling the blockchain to get provably fair results] .......................

/**
 * @title Raffle
 * @notice This contract allows anyone to permissionlessly host raffles on LooksRare.
 * @author LooksRare protocol team (👀,💎)
 */
contract Raffle is
    IRaffle,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps,
    PackableReentrancyGuard,
    Pausable,
    WinningEntrySearchLogic
{
    using Arrays for uint256[];

    address public immutable WETH;

    uint256 public constant ONE_DAY = 86_400 seconds;
    uint256 public constant ONE_WEEK = 604_800 seconds;

    /**
     * @notice 100% in basis points.
     */
    uint256 public constant ONE_HUNDRED_PERCENT_BP = 10_000;

    /**
     * @notice The number of raffles created.
     */
    uint256 public rafflesCount;

    /**
     * @notice The raffles created.
     * @dev The key is the raffle ID.
     */
    mapping(uint256 => Raffle) public raffles;

    /**
     * @notice The participants stats of the raffles.
     * @dev The key is the raffle ID and the nested key is the participant address.
     */
    mapping(uint256 => mapping(address => ParticipantStats)) public rafflesParticipantsStats;

    /**
     * @notice It checks whether the currency is allowed.
     */
    mapping(address => bool) public isCurrencyAllowed;

    /**
     * @notice The maximum number of prizes per raffle.
     *         Each individual ERC-721 counts as one prize.
     *         Each ETH/ERC-20/ERC-1155 with winnersCount > 1 counts as one prize.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE = 20;

    /**
     * @notice The maximum number of winners per raffle.
     */
    uint40 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE = 110;

    /**
     * @notice A Chainlink node should wait for 3 confirmations before responding.
     */
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 public immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;

    /**
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint16 public constant MAXIMUM_PROTOCOL_FEE_BP = 2_500;

    /**
     * @notice The protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee in basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice The claimable fees of the protocol fee recipient.
     * @dev The key is the currency address.
     */
    mapping(address => uint256) public protocolFeeRecipientClaimableFees;

    /**
     * @notice The number of pricing options per raffle.
     */
    uint256 public constant PRICING_OPTIONS_PER_RAFFLE = 5;

    /**
     * @param _weth The WETH address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     */
    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint16 _protocolFeeBp
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        WETH = _weth;
        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
    }

    /**
     * @inheritdoc IRaffle
     * @dev This function can still be called when the contract is paused because the raffle creator
     *      would not be able to deposit prizes and open the raffle anyway. The restriction to disallow
     *      raffles creation when the contract is paused will be enforced in the frontend.
     */
    function createRaffle(CreateRaffleCalldata calldata params) external returns (uint256 raffleId) {
        uint40 cutoffTime = params.cutoffTime;
        if (_unsafeAdd(block.timestamp, ONE_DAY) > cutoffTime || cutoffTime > _unsafeAdd(block.timestamp, ONE_WEEK)) {
            revert InvalidCutoffTime();
        }

        uint16 agreedProtocolFeeBp = params.protocolFeeBp;
        if (agreedProtocolFeeBp != protocolFeeBp) {
            revert InvalidProtocolFeeBp();
        }

        address feeTokenAddress = params.feeTokenAddress;
        if (feeTokenAddress != address(0)) {
            if (!isCurrencyAllowed[feeTokenAddress]) {
                revert InvalidCurrency();
            }
        }

        unchecked {
            raffleId = ++rafflesCount;
        }

        uint256 prizesCount = params.prizes.length;
        if (prizesCount == 0 || prizesCount > MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE) {
            revert InvalidPrizesCount();
        }

        Raffle storage raffle = raffles[raffleId];
        uint40 cumulativeWinnersCount;
        uint8 currentPrizeTier;
        for (uint256 i; i < prizesCount; ) {
            Prize memory prize = params.prizes[i];
            if (prize.prizeTier < currentPrizeTier) {
                revert InvalidPrize();
            }
            _validatePrize(prize);

            cumulativeWinnersCount += prize.winnersCount;
            prize.cumulativeWinnersCount = cumulativeWinnersCount;
            currentPrizeTier = prize.prizeTier;
            raffle.prizes.push(prize);

            unchecked {
                ++i;
            }
        }

        uint40 minimumEntries = params.minimumEntries;
        if (cumulativeWinnersCount > minimumEntries || cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE) {
            revert InvalidWinnersCount();
        }

        _validateAndSetPricingOptions(raffleId, params.pricingOptions);

        raffle.owner = msg.sender;
        raffle.isMinimumEntriesFixed = params.isMinimumEntriesFixed;
        raffle.cutoffTime = cutoffTime;
        raffle.minimumEntries = minimumEntries;
        raffle.maximumEntriesPerParticipant = params.maximumEntriesPerParticipant;
        raffle.protocolFeeBp = agreedProtocolFeeBp;
        raffle.feeTokenAddress = feeTokenAddress;
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Created);
    }

    /**
     * @inheritdoc IRaffle
     */
    function depositPrizes(uint256 raffleId) external payable nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        _validateRaffleStatus(raffle, RaffleStatus.Created);
        _validateCaller(raffle.owner);

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 expectedEthValue;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = prizes[i];
            TokenType prizeType = prize.prizeType;
            if (prizeType == TokenType.ERC721) {
                _executeERC721TransferFrom(prize.prizeAddress, msg.sender, address(this), prize.prizeId);
            } else if (prizeType == TokenType.ERC20) {
                _executeERC20TransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeAmount * prize.winnersCount
                );
            } else if (prizeType == TokenType.ETH) {
                expectedEthValue += (prize.prizeAmount * prize.winnersCount);
            } else {
                _executeERC1155SafeTransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeId,
                    prize.prizeAmount * prize.winnersCount
                );
            }
            unchecked {
                ++i;
            }
        }

        _validateExpectedEthValueOrRefund(expectedEthValue);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Open);
    }

    /**
     * @dev This function is required in order for the contract to receive ERC-1155 tokens.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IRaffle
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable nonReentrant whenNotPaused {
        uint256 entriesCount = entries.length;
        uint208 expectedEthValue;
        for (uint256 i; i < entriesCount; ) {
            EntryCalldata calldata entry = entries[i];

            if (entry.pricingOptionIndex >= PRICING_OPTIONS_PER_RAFFLE) {
                revert InvalidIndex();
            }

            uint256 raffleId = entry.raffleId;
            Raffle storage raffle = raffles[raffleId];

            _validateRaffleStatus(raffle, RaffleStatus.Open);

            if (block.timestamp >= raffle.cutoffTime) {
                revert CutoffTimeReached();
            }

            PricingOption memory pricingOption = raffle.pricingOptions[entry.pricingOptionIndex];

            uint40 newParticipantEntriesCount = rafflesParticipantsStats[raffleId][msg.sender].entriesCount +
                pricingOption.entriesCount;
            if (newParticipantEntriesCount > raffle.maximumEntriesPerParticipant) {
                revert MaximumEntriesPerParticipantReached();
            }
            rafflesParticipantsStats[raffleId][msg.sender].entriesCount = newParticipantEntriesCount;

            uint208 price = pricingOption.price;

            if (raffle.feeTokenAddress == address(0)) {
                expectedEthValue += price;
            } else {
                _executeERC20TransferFrom(raffle.feeTokenAddress, msg.sender, address(this), price);
            }

            uint40 currentEntryIndex;
            uint256 raffleEntriesCount = raffle.entries.length;
            if (raffleEntriesCount == 0) {
                currentEntryIndex = uint40(_unsafeSubtract(pricingOption.entriesCount, 1));
            } else {
                currentEntryIndex =
                    raffle.entries[_unsafeSubtract(raffleEntriesCount, 1)].currentEntryIndex +
                    pricingOption.entriesCount;
            }

            if (raffle.isMinimumEntriesFixed) {
                if (currentEntryIndex >= raffle.minimumEntries) {
                    revert MaximumEntriesReached();
                }
            }

            raffle.entries.push(Entry({currentEntryIndex: currentEntryIndex, participant: msg.sender}));
            raffle.claimableFees += price;

            rafflesParticipantsStats[raffleId][msg.sender].amountPaid += price;

            emit EntrySold(raffleId, msg.sender, pricingOption.entriesCount, price);

            if (currentEntryIndex >= _unsafeSubtract(raffle.minimumEntries, 1)) {
                _drawWinners(raffleId, raffle);
            }

            unchecked {
                ++i;
            }
        }

        _validateExpectedEthValueOrRefund(expectedEthValue);
    }

    /**
     * @param _requestId The ID of the request
     * @param _randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (randomnessRequests[_requestId].exists) {
            uint256 raffleId = randomnessRequests[_requestId].raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status == RaffleStatus.Drawing) {
                _setRaffleStatus(raffle, raffleId, RaffleStatus.RandomnessFulfilled);
                // We ignore the most significant byte to pack the random word with `exists`
                randomnessRequests[_requestId].randomWord = uint248(_randomWords[0]);
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function selectWinners(uint256 requestId) external {
        RandomnessRequest memory randomnessRequest = randomnessRequests[requestId];
        if (!randomnessRequest.exists) {
            revert RandomnessRequestDoesNotExist();
        }

        uint256 raffleId = randomnessRequest.raffleId;
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.RandomnessFulfilled);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawn);

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 winnersCount = prizes[prizesCount - 1].cumulativeWinnersCount;

        Entry[] memory entries = raffle.entries;
        uint256 entriesCount = entries.length;
        uint256 currentEntryIndex = uint256(entries[entriesCount - 1].currentEntryIndex);

        uint256[] memory winningEntriesBitmap = new uint256[]((currentEntryIndex >> 8) + 1);

        uint256[] memory currentEntryIndexArray = new uint256[](entriesCount);
        for (uint256 i; i < entriesCount; ) {
            currentEntryIndexArray[i] = entries[i].currentEntryIndex;
            unchecked {
                ++i;
            }
        }

        uint256[] memory cumulativeWinnersCountArray = new uint256[](prizesCount);
        for (uint256 i; i < prizesCount; ) {
            cumulativeWinnersCountArray[i] = prizes[i].cumulativeWinnersCount;
            unchecked {
                ++i;
            }
        }

        uint256 randomWord = randomnessRequest.randomWord;

        for (uint256 i; i < winnersCount; ) {
            uint256 winningEntry = randomWord % (currentEntryIndex + 1);
            (winningEntry, winningEntriesBitmap) = _incrementWinningEntryUntilThereIsNotADuplicate(
                currentEntryIndex,
                winningEntry,
                winningEntriesBitmap
            );

            raffle.winners.push(
                Winner({
                    participant: entries[currentEntryIndexArray.findUpperBound(winningEntry)].participant,
                    claimed: false,
                    prizeIndex: uint8(cumulativeWinnersCountArray.findUpperBound(_unsafeAdd(i, 1))),
                    entryIndex: uint40(winningEntry)
                })
            );

            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external nonReentrant whenNotPaused {
        uint256 claimsCount = claimPrizesCalldata.length;
        for (uint256 i; i < claimsCount; ) {
            _claimPrizesPerRaffle(claimPrizesCalldata[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimProtocolFees(address currency) external onlyOwner {
        uint256 claimableFees = protocolFeeRecipientClaimableFees[currency];
        protocolFeeRecipientClaimableFees[currency] = 0;
        _transferFungibleTokens(currency, protocolFeeRecipient, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimFees(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.Drawn);

        address raffleOwner = raffle.owner;
        if (msg.sender != raffleOwner) {
            _validateCaller(owner);
        }

        uint208 claimableFees = raffle.claimableFees;
        uint208 protocolFees = (claimableFees * uint208(raffle.protocolFeeBp)) / uint208(ONE_HUNDRED_PERCENT_BP);
        unchecked {
            claimableFees -= protocolFees;
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Complete);

        raffle.claimableFees = 0;

        address feeTokenAddress = raffle.feeTokenAddress;
        _transferFungibleTokens(feeTokenAddress, raffleOwner, claimableFees);

        if (protocolFees != 0) {
            protocolFeeRecipientClaimableFees[feeTokenAddress] += protocolFees;
        }

        emit FeesClaimed(raffleId, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancel(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        bool isOpen = raffle.status == RaffleStatus.Open;

        if (isOpen) {
            if (raffle.cutoffTime > block.timestamp) {
                revert CutoffTimeNotReached();
            }
        } else {
            _validateRaffleStatus(raffle, RaffleStatus.Created);
        }

        _setRaffleStatus(raffle, raffleId, isOpen ? RaffleStatus.Refundable : RaffleStatus.Cancelled);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external onlyOwner nonReentrant {
        Raffle storage raffle = raffles[raffleId];

        _validateRaffleStatus(raffle, RaffleStatus.Drawing);

        if (block.timestamp < raffle.drawnAt + ONE_DAY) {
            revert DrawExpirationTimeNotReached();
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Refundable);
    }

    /**
     * @inheritdoc IRaffle
     */
    function withdrawPrizes(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.Refundable);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Cancelled);

        uint256 prizesCount = raffle.prizes.length;
        address raffleOwner = raffle.owner;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = raffle.prizes[i];
            _transferPrize({prize: prize, recipient: raffleOwner, multiplier: uint256(prize.winnersCount)});

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function claimRefund(uint256[] calldata raffleIds) external nonReentrant whenNotPaused {
        uint256 count = raffleIds.length;

        for (uint256 i; i < count; ) {
            uint256 raffleId = raffleIds[i];
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status < RaffleStatus.Refundable) {
                revert InvalidStatus();
            }

            ParticipantStats storage stats = rafflesParticipantsStats[raffleId][msg.sender];

            if (stats.refunded) {
                revert AlreadyRefunded();
            }

            stats.refunded = true;

            uint208 amountPaid = stats.amountPaid;
            _transferFungibleTokens(raffle.feeTokenAddress, msg.sender, amountPaid);

            emit EntryRefunded(raffleId, msg.sender, amountPaid);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IRaffle
     */
    function setProtocolFeeBp(uint16 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IRaffle
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external onlyOwner {
        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = isAllowed;
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IRaffle
     */
    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IRaffle
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory winners) {
        winners = raffles[raffleId].winners;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory prizes) {
        prizes = raffles[raffleId].prizes;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory entries) {
        entries = raffles[raffleId].entries;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getPricingOptions(uint256 raffleId)
        external
        view
        returns (PricingOption[PRICING_OPTIONS_PER_RAFFLE] memory pricingOptions)
    {
        pricingOptions = raffles[raffleId].pricingOptions;
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _setProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidProtocolFeeRecipient();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _setProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidProtocolFeeBp();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param raffleId The ID of the raffle.
     * @param pricingOptions The pricing options for the raffle.
     */
    function _validateAndSetPricingOptions(
        uint256 raffleId,
        PricingOption[PRICING_OPTIONS_PER_RAFFLE] calldata pricingOptions
    ) private {
        for (uint256 i; i < PRICING_OPTIONS_PER_RAFFLE; ) {
            PricingOption memory pricingOption = pricingOptions[i];

            uint40 entriesCount = pricingOption.entriesCount;
            uint208 price = pricingOption.price;

            if (i == 0) {
                if (entriesCount != 1 || price == 0) {
                    revert InvalidPricingOption();
                }
            } else {
                PricingOption memory lastPricingOption = pricingOptions[_unsafeSubtract(i, 1)];
                uint208 lastPrice = lastPricingOption.price;
                uint40 lastEntriesCount = lastPricingOption.entriesCount;

                if (
                    price % entriesCount != 0 ||
                    entriesCount <= lastEntriesCount ||
                    price <= lastPrice ||
                    price / entriesCount > lastPrice / lastEntriesCount
                ) {
                    revert InvalidPricingOption();
                }
            }

            raffles[raffleId].pricingOptions[i] = pricingOption;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param prize The prize.
     */
    function _validatePrize(Prize memory prize) private view {
        if (prize.prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1 || prize.winnersCount != 1) {
                revert InvalidPrize();
            }
        } else {
            if (prize.prizeType == TokenType.ERC20) {
                if (!isCurrencyAllowed[prize.prizeAddress]) {
                    revert InvalidCurrency();
                }
            }

            if (prize.prizeAmount == 0 || prize.winnersCount == 0) {
                revert InvalidPrize();
            }
        }
    }

    /**
     * @param prize The prize to transfer.
     * @param recipient The recipient of the prize.
     * @param multiplier The multiplier to apply to the prize amount.
     */
    function _transferPrize(
        Prize storage prize,
        address recipient,
        uint256 multiplier
    ) private {
        TokenType prizeType = prize.prizeType;
        address prizeAddress = prize.prizeAddress;
        if (prizeType == TokenType.ERC721) {
            _executeERC721TransferFrom(prizeAddress, address(this), recipient, prize.prizeId);
        } else if (prizeType == TokenType.ERC1155) {
            _executeERC1155SafeTransferFrom(
                prizeAddress,
                address(this),
                recipient,
                prize.prizeId,
                prize.prizeAmount * multiplier
            );
        } else {
            _transferFungibleTokens(prizeAddress, recipient, prize.prizeAmount * multiplier);
        }
    }

    /**
     * @param currency The currency to transfer.
     * @param recipient The recipient of the currency.
     * @param amount The amount of currency to transfer.
     */
    function _transferFungibleTokens(
        address currency,
        address recipient,
        uint256 amount
    ) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, recipient, amount, gasleft());
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function _claimPrizesPerRaffle(ClaimPrizesCalldata calldata claimPrizesCalldata) private {
        uint256 raffleId = claimPrizesCalldata.raffleId;
        Raffle storage raffle = raffles[raffleId];
        RaffleStatus status = raffle.status;
        if (status != RaffleStatus.Drawn) {
            _validateRaffleStatus(raffle, RaffleStatus.Complete);
        }

        Winner[] storage winners = raffle.winners;
        uint256[] calldata winnerIndices = claimPrizesCalldata.winnerIndices;
        uint256 winnersCount = winners.length;
        uint256 claimsCount = winnerIndices.length;
        for (uint256 i; i < claimsCount; ) {
            uint256 winnerIndex = winnerIndices[i];

            if (winnerIndex >= winnersCount) {
                revert InvalidIndex();
            }

            Winner storage winner = winners[winnerIndex];
            if (winner.claimed) {
                revert PrizeAlreadyClaimed();
            }
            _validateCaller(winner.participant);
            winner.claimed = true;

            Prize storage prize = raffle.prizes[winner.prizeIndex];
            _transferPrize({prize: prize, recipient: msg.sender, multiplier: 1});

            unchecked {
                ++i;
            }
        }

        emit PrizesClaimed(raffleId, winnerIndices);
    }

    /**
     * @param raffleId The ID of the raffle to draw winners for.
     * @param raffle The raffle to draw winners for.
     */
    function _drawWinners(uint256 raffleId, Raffle storage raffle) private {
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawing);
        raffle.drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            uint32(500_000),
            uint32(1)
        );

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].raffleId = raffleId;

        emit RandomnessRequested(raffleId, requestId);
    }

    /**
     * @param raffle The raffle to check the status of.
     * @param status The expected status of the raffle
     */
    function _validateRaffleStatus(Raffle storage raffle, RaffleStatus status) private view {
        if (raffle.status != status) {
            revert InvalidStatus();
        }
    }

    /**
     * @param caller The expected caller.
     */
    function _validateCaller(address caller) private view {
        if (msg.sender != caller) {
            revert InvalidCaller();
        }
    }

    /**
     * @param expectedEthValue The expected ETH value to be sent by the caller.
     */
    function _validateExpectedEthValueOrRefund(uint256 expectedEthValue) private {
        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        } else if (msg.value > expectedEthValue) {
            _transferETHAndWrapIfFailWithGasLimit(
                WETH,
                msg.sender,
                _unsafeSubtract(msg.value, expectedEthValue),
                gasleft()
            );
        }
    }

    /**
     * @param raffle The raffle to set the status of.
     * @param raffleId The ID of the raffle to set the status of.
     * @param status The status to set.
     */
    function _setRaffleStatus(
        Raffle storage raffle,
        uint256 raffleId,
        RaffleStatus status
    ) private {
        raffle.status = status;
        emit RaffleStatusUpdated(raffleId, status);
    }

    function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _unsafeSubtract(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }
}