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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

// Bet types, unknown type means actions not performed yet
enum BetType {
    Unknown,
    Call,
    Fold,
    Raise,
    Check,
    AllIn
}

// Game stage
enum GameStage {
    Uncreated,
    GatheringPlayers,
    Shuffle,
    PreFlopReveal, // in pre-flop, every gets 2 cards, and everyone must provide proofs
    PreFlopBet,
    FlopReveal, // in flop, everyone must provide proofs for community cards
    FlopBet,
    TurnReveal, // need reveal
    TurnBet,
    RiverReveal, // need reveal
    RiverBet,
    PostRound, // waiting to announce winner
    Ended
}

// Card rank
enum Rank {
    Spades,
    Hearts,
    Diamonds,
    Clubs
}

// Board state
struct Board {
    // Current game stage
    GameStage stage;
    // Permanent accounts of all players
    address[] permanentAccounts;
    // Index of the next player to play
    uint8 nextPlayer;
    // Dealer index
    uint8 dealer;
    // Required number of players to play
    uint8 numPlayers;
    // Number of players that has not folded
    uint8 numUnfoldedPlayers;
    // Whether i-th player has folded
    bool[] folded;
    // Whether i-th player has all-in
    bool[] hasAllIn;
    // Whether all players have expressed opinion at least once
    bool allExpressed;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IChipManager.sol";
import "../Types.sol";

// Chip manager for buy-in into specific games.
contract ChipManager is Ownable, IChipManager {
    // Minimum big blind size
    uint256 public immutable MIN_BIG_BLIND_SIZE = 10;
    // Multipliers of buy-in size according to big blind
    uint256 public minBuyInMultiplier = 100;
    uint256 public maxBuyInMultiplier = 500;
    // Maximal number of players in a game
    uint256 public constant MAX_PLAYERS = 6;
    // Mapping from board id to chips
    mapping(uint256 => Chip) chips;
    // Address of game contract
    address gameContract;

    modifier onlyGameContract() {
        require(gameContract == msg.sender, "Caller is not game contract");
        _;
    }

    constructor(uint256 minBuyInMultiplier_, uint256 maxBuyInMultiplier_) {
        setBuyInMultipliers(minBuyInMultiplier_, maxBuyInMultiplier_);
    }

    // Sets buy-in multipliers.
    function setBuyInMultipliers(uint256 min, uint256 max) public onlyOwner {
        require(min < max && min > 0, "invalid buyin multipliers");
        minBuyInMultiplier = min;
        maxBuyInMultiplier = max;
    }

    // Sets game contract.
    function setGameContract(address gameContract_) external onlyOwner {
        gameContract = gameContract_;
    }

    // Sets game settings for `boardId` and specifying the big blind size.
    function setGameSetting(
        uint256 boardId,
        uint256 bigBlindSize,
        uint256 numPlayers
    ) external onlyGameContract {
        require(
            bigBlindSize >= MIN_BIG_BLIND_SIZE,
            "big blind size should be greater than 10"
        );
        chips[boardId].betsEachRound = new uint256[][](13);
        chips[boardId].betTypeEachRound = new BetType[][](13);
        for (uint256 i = 0; i < 13; i++) {
            chips[boardId].betsEachRound[i] = new uint256[](numPlayers);
            chips[boardId].betTypeEachRound[i] = new BetType[](numPlayers);
        }
        chips[boardId].bigBlindSize = bigBlindSize;
    }

    // Registers all `players` in `boardId`.
    function registerPlayers(
        uint256 boardId,
        address[] calldata players
    ) external onlyGameContract {
        require(
            players.length == chips[boardId].betsEachRound[0].length,
            "Invalid number of players"
        );
        chips[boardId].players = players;
    }

    // Bets for small blind and big blind.
    function initialBet(uint256 boardId) external onlyGameContract {
        uint256 bigBlindSize = chips[boardId].bigBlindSize;
        bet(boardId, bigBlindSize / 2, 0, BetType.Raise, GameStage.PreFlopBet);
        bet(boardId, bigBlindSize, 1, BetType.Raise, GameStage.PreFlopBet);
        chips[boardId].someoneHasBet = true;
    }

    // Sets the `buyIn` chips for `boardId`.
    function setBuyIn(
        uint256 boardId,
        uint256 buyIn
    ) external onlyGameContract {
        uint256 bb = chips[boardId].bigBlindSize;
        require(
            buyIn >= bb * minBuyInMultiplier &&
                buyIn <= bb * maxBuyInMultiplier,
            "Invalid buy-in size"
        );
        chips[boardId].bets.push(0);
        chips[boardId].chips.push(buyIn);
    }

    // Checks by `playerIndex` for `boardId` game in `stage`.
    function check(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        require(
            chips[boardId].bets[playerIndex] == chips[boardId].highestBet,
            "Cannot check since your bets is less than other players' bets"
        );
        bet(boardId, 0, playerIndex, BetType.Check, stage);
    }

    // Folds by `playerIndex` for `boardId` game in `stage`.
    function fold(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        bet(boardId, 0, playerIndex, BetType.Fold, stage);
        chips[boardId].foldRecord |= (uint8(1) << playerIndex);
    }

    // Raises `amount` by `playerIndex` for `boardId` game in `stage`.
    // Note: Suppose player A has bet 100 before and want to bet 300 instead, the amount
    //     would be 200.
    function raise(
        uint256 boardId,
        uint256 amount,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        require(
            amount >= getMinRaise(boardId, playerIndex),
            "cannot raise due to invalid amount"
        );
        require(
            chips[boardId].chips[playerIndex] >= amount,
            "cannot raise due to insufficient chips"
        );
        bet(boardId, amount, playerIndex, BetType.Raise, stage);
    }

    // Calls by `playerIndex` for `boardId` game in `stage`.
    function call(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        uint256 amount = chips[boardId].highestBet -
            chips[boardId].bets[playerIndex];
        require(amount > 0, "should check instead of call");
        require(
            chips[boardId].chips[playerIndex] >= amount,
            "cannot call due to insufficient chips"
        );
        bet(boardId, amount, playerIndex, BetType.Call, stage);
    }

    // All in by `playerIndex` for `boardId` game in `stage`.
    function allIn(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        chips[boardId].allInRecord = (chips[boardId].allInRecord |
            (uint8(1) << playerIndex));
        bet(
            boardId,
            chips[boardId].chips[playerIndex],
            playerIndex,
            BetType.AllIn,
            stage
        );
    }

    // Gets the minimal raise amount of `index`-th player in `boardId` game following rules:
    // a) need to match highest bet, i.e., bet (chips[boardId].highestBet - chips[boardId].bets[index])
    // b) at least additionally raise max(bigBlind, chips[boardId].lastRaise - chips[boardId].raiseBeforeLastRaise)
    function getMinRaise(
        uint256 boardId,
        uint8 index
    ) public view returns (uint256) {
        uint256 delta = chips[boardId].lastRaise -
            chips[boardId].raiseBeforeLastRaise;
        uint256 bb = chips[boardId].bigBlindSize;
        return
            (delta >= bb ? delta : bb) +
            chips[boardId].highestBet -
            chips[boardId].bets[index];
    }

    // Bets `amount` and `betType` of `playerIndex` for `boardId` game in `stage`.
    // Note: Suppose player A has bet 100 before and want to bet 300 instead, the amount
    //     would be 200.
    function bet(
        uint256 boardId,
        uint256 amount,
        uint8 playerIndex,
        BetType betType,
        GameStage stage
    ) internal {
        uint256 stageId = uint256(stage);
        chips[boardId].betTypeEachRound[stageId][playerIndex] = betType;
        if (amount != 0) {
            chips[boardId].chips[playerIndex] -= amount;
            uint256 newBetAmount = chips[boardId].bets[playerIndex] + amount;
            chips[boardId].bets[playerIndex] = newBetAmount;
            uint256 highestBet = chips[boardId].highestBet;
            chips[boardId].highestBet = newBetAmount > highestBet
                ? newBetAmount
                : highestBet;
            chips[boardId].potSize += amount;
            chips[boardId].betsEachRound[stageId][playerIndex] += amount;
        }
        if (betType == BetType.Raise) {
            uint256 lastRaise = chips[boardId].lastRaise;
            chips[boardId].raiseBeforeLastRaise = lastRaise;
            chips[boardId].lastRaise = chips[boardId].bets[playerIndex];
        }
        if (betType == BetType.Raise || betType == BetType.AllIn) {
            chips[boardId].someoneHasBet = true;
        }
        emit Bet(
            boardId,
            chips[boardId].players[playerIndex],
            amount,
            betType,
            stage
        );
    }

    // Gets chips[boardId].someoneHasBet.
    function getSomeoneHasBet(uint256 boardId) external view returns (bool) {
        return chips[boardId].someoneHasBet;
    }

    // Checks if every player has the same bet.
    function isEveryoneOnTheSameBet(
        uint256 boardId
    ) external view returns (bool) {
        uint256 highestBet = chips[boardId].highestBet;
        uint8 allInRecord = chips[boardId].allInRecord;
        uint8 foldRecord = chips[boardId].foldRecord;
        for (uint256 i = 0; i < chips[boardId].bets.length; i++) {
            if (
                ((allInRecord >> i) & 1) == 0 &&
                ((foldRecord >> i) & 1) == 0 &&
                chips[boardId].bets[i] != highestBet
            ) {
                return false;
            }
        }
        return true;
    }

    // Sets new round for `boardId`.
    function setNewRound(uint256 boardId) external onlyGameContract {
        chips[boardId].lastRaise = chips[boardId].highestBet;
        chips[boardId].raiseBeforeLastRaise = chips[boardId].highestBet;
        chips[boardId].someoneHasBet = false;
    }

    // Given `bets` and `scores` of each player, this function computes the order of players
    // according to the following rules:
    // 1. all players are sorted according to their scores in descending orders.
    // 2. for players with the same score, they are sorted according to their bets in ascending orders.
    // Assumption: `bets` and `scores` match the order of `chips[boardId].players`.
    // Note: this function makes in-place updates to `bets` and `scores` such that their order matches
    // `indices`. In other words, (indices[i], bets[i], scores[i]) matches for the i-th player.
    function getSettleOrder(
        uint256[] memory bets,
        uint256[] memory scores
    )
        internal
        pure
        returns (
            uint8[] memory indices,
            uint8[] memory groupCount,
            uint256[] memory sortedBets
        )
    {
        uint8 length = uint8(scores.length);
        indices = new uint8[](length);
        groupCount = new uint8[](length);
        uint8 i;
        for (i = 0; i < length; i++) {
            indices[i] = i;
        }
        sort(scores, indices, 0, length, true);
        sortedBets = reorder(bets, indices);
        i = 0;
        uint8 j = 1;
        uint256 curBet;
        uint8 numGroup = 0;
        while (i < length) {
            curBet = sortedBets[i];
            while (j < length) {
                if (scores[j] != scores[i]) {
                    break;
                }
                j++;
            }
            sort(sortedBets, indices, i, j, true);
            groupCount[numGroup] = j - i;
            i = j;
            j++;
            numGroup++;
        }
    }

    // Gets the settlement amount of players with indices between [start, end), assuming these
    // players have the same score. The rules are:
    // 1. For the i-th player, i \in [start, end):
    //    case-I: if bets[i] * (end-i) < potSize:
    //      a) compute totalSidePotForThisRound = getSidePotSingleRound(...)
    //      a) compute partialSidePot = totalSidePotForThisRound / (end-i);
    //      b) gives each player in [i, end) bets[i]+partialSidePot chips
    //      c) deducts each player's (i.e., in [i, end)) bet by bets[i], and update
    //          potSize -= (bets[i]*(end-i) + totalSidePotForThisRound).
    //
    //    case-II: if bets[i] * (end-i) >= potSize:
    //      a) gives each player potSize/(end-i) chips. The i-th player can get additionally
    //          potSize - potSize/(end-i)*(end-i) chips
    //      b) deducts each player's bet by postSize/(end-i)
    //      c) update postSize = 0.
    // 2. If potSize > 0, continue with (i+1)-th player with step2.
    // 3. Return updated potSize.
    // Note: order of `amounts` is the same as `chips[boardId].players`, which is different from
    //      `indices` and `bets` that is sorted by `getSettleOrder`.
    function getSettleAmountSameScore(
        uint256 potSize,
        uint256[] memory bets,
        uint256[] memory amounts,
        uint8[] memory indices,
        uint8 start,
        uint8 end
    ) internal pure returns (uint256) {
        for (uint8 i = start; i < end; i++) {
            uint256 betI = bets[i];
            if (betI * (end - i) <= potSize) {
                uint256 totalSidePotForThisRound = getSidePotSingleRound(
                    bets,
                    betI,
                    end
                );
                increaseSettlementAmount(
                    amounts,
                    betI,
                    totalSidePotForThisRound,
                    indices,
                    i,
                    end
                );
                decreaseRemainingBets(bets, betI, i, end);
                potSize -= (betI * (end - i) + totalSidePotForThisRound);
            } else {
                uint256 remainingAmount = potSize / (end - i);
                increaseSettlementAmount(
                    amounts,
                    remainingAmount,
                    0,
                    indices,
                    i,
                    end
                );
                decreaseRemainingBets(bets, remainingAmount, i, end);
                amounts[i] += (potSize - remainingAmount * (end - i));
                return 0;
            }
        }
        return potSize;
    }

    // Computes parts of the side pot for `getSettleAmountSameScore`. When settle amount for a group of
    // players with the same scores, they will also get chips from players with worse scores. This function
    // helps to compute the amount of these chips as `partialSidePot`. In particular, suppose a player i with better score has `baseBet`.
    // From a player j with worse score, we can get either `baseBet` if he/she has more than `baseBet` bets; or
    // `bets[j]` if he/she has less than `baseBet` bets.
    // Note: `bets` is in-place updated.
    function getSidePotSingleRound(
        uint256[] memory bets,
        uint256 baseBet,
        uint8 start
    ) internal pure returns (uint256) {
        uint8 numPlayers = uint8(bets.length);
        uint256 partialSidePot = 0;
        for (uint8 j = start; j < numPlayers; j++) {
            if (bets[j] > baseBet) {
                partialSidePot += baseBet;
                bets[j] -= baseBet;
            } else {
                partialSidePot += bets[j];
                bets[j] = 0;
            }
        }
        return partialSidePot;
    }

    // Gets the settlement amount of each player, given `bets`, `indices` and `groupCount` from `getSettleOrder`.
    function getSettleAmount(
        uint256 potSize,
        uint256[] memory bets,
        uint8[] memory indices,
        uint8[] memory groupCount
    ) internal pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](bets.length);
        uint8 start = 0;
        uint8 end;
        for (uint8 i = 0; i < groupCount.length; i++) {
            if (groupCount[i] == 0) {
                require(
                    potSize == 0,
                    "Should never happen that group count is zero but potSize is non-zero"
                );
                break;
            }
            end = start + groupCount[i];
            potSize = getSettleAmountSameScore(
                potSize,
                bets,
                amounts,
                indices,
                start,
                end
            );
            if (potSize == 0) {
                break;
            }
            start = end;
        }
        return amounts;
    }

    // Gets the settlement amount of each player in `boardId` game according to `scores` of each player.
    // Note1: `scores` match the order of `chips[boardId].players`
    // Note2: `amount` includes both winning/losses and the remaining buy-ins.
    function settle(
        uint256 boardId,
        uint256[] memory scores
    ) external view returns (uint256[] memory) {
        uint256[] memory bets = chips[boardId].bets;
        (
            uint8[] memory indices,
            uint8[] memory groupCount,
            uint256[] memory sortedBets
        ) = getSettleOrder(bets, scores);
        uint256[] memory amounts = getSettleAmount(
            chips[boardId].potSize,
            sortedBets,
            indices,
            groupCount
        );
        for (uint8 i = 0; i < amounts.length; i++) {
            amounts[i] += chips[boardId].chips[i];
        }
        return amounts;
    }

    // Updates the `amounts` by `increaseAmount` for index i \in [start, end).
    // Note: The order of `amounts` follows `chips[boardId].players` and [start, end) refers to `indices`.
    function increaseSettlementAmount(
        uint256[] memory amounts,
        uint256 increaseAmount,
        uint256 totalSidePotAmount,
        uint8[] memory indices,
        uint8 start,
        uint8 end
    ) internal pure {
        uint256 partialSidePot = totalSidePotAmount / (end - start);
        uint256 totalAmount = increaseAmount + partialSidePot;
        for (uint8 i = start; i < end; i++) {
            amounts[indices[i]] += totalAmount;
        }
        amounts[indices[start]] += (totalSidePotAmount -
            partialSidePot *
            (end - start));
    }

    // Updates the `bets` by `increaseAmount` for index i \in [start, end).
    function decreaseRemainingBets(
        uint256[] memory bets,
        uint256 amount,
        uint8 start,
        uint8 end
    ) internal pure {
        for (uint8 i = start; i < end; i++) {
            bets[i] -= amount;
        }
    }

    // Swaps data[i] and data[j].
    function swapUint256(
        uint256[] memory data,
        uint8 i,
        uint8 j
    ) internal pure {
        uint256 tmp = data[i];
        data[i] = data[j];
        data[j] = tmp;
    }

    // Swaps data[i] and data[j].
    function swapUint8(uint8[] memory data, uint8 i, uint8 j) internal pure {
        uint8 tmp = data[i];
        data[i] = data[j];
        data[j] = tmp;
    }

    // Sorts `data` between [`start`, `end`) index according to `ascending` order;
    // Updates `indices` corresponding to the order of `data`.
    function sort(
        uint256[] memory data,
        uint8[] memory indices,
        uint8 start,
        uint8 end,
        bool ascending
    ) internal pure {
        uint8 largestDataIndex;
        for (uint8 i = start; i < end; i++) {
            largestDataIndex = i;
            for (uint8 j = i + 1; j < end; j++) {
                if (data[j] > data[largestDataIndex]) {
                    largestDataIndex = j;
                }
            }
            if (i != largestDataIndex) {
                swapUint256(data, i, largestDataIndex);
                swapUint8(indices, i, largestDataIndex);
            }
        }
        if (ascending) {
            uint8 i = start;
            uint8 j = end - 1;
            while (i < j) {
                swapUint256(data, i, j);
                swapUint8(indices, i, j);
                i++;
                j--;
            }
        }
    }

    // Reorders `data` according to `indices`.
    function reorder(
        uint256[] memory data,
        uint8[] memory indices
    ) internal pure returns (uint256[] memory) {
        uint256[] memory reorderedData = new uint256[](data.length);
        for (uint8 i = 0; i < data.length; i++) {
            reorderedData[i] = data[indices[i]];
        }
        return reorderedData;
    }

    // Gets the pot size of `boardId` game.
    function getPotSize(uint256 boardId) external view returns (uint256) {
        return chips[boardId].potSize;
    }

    // Gets the chip of `boardId` game.
    function getChip(uint256 boardId) external view returns (Chip memory) {
        return chips[boardId];
    }

    // Gets the chips not bet yet for the `playerIdx`-th player in `boardId` game.
    function getChipSinglePlayer(
        uint256 boardId,
        uint8 playerIdx
    ) external view returns (uint256) {
        return chips[boardId].chips[playerIdx];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../Types.sol";

// Chip State
struct Chip {
    // Addresses of players
    address[] players;
    // Chips not betted yet for each player
    uint256[] chips;
    // Bet Chips from each player
    uint256[] bets;
    // Highest bet over all players (i.e., max(bets[0], ..., bets[numPlayers]))
    uint256 highestBet;
    // Total chips in pot
    uint256 potSize;
    // Bets of each round for each player
    uint256[][] betsEachRound;
    // Amount of last raise in the current betting round
    // Example: Suppose A first raised 100 and then B raised to 200, the lastRaise is 200.
    uint256 lastRaise;
    // Amount of the raise before last raise in the current betting round
    // Example: Suppose A first raised 100 and then B raised to 200, the raiseBeforeLastRaise is 100.
    uint256 raiseBeforeLastRaise;
    // Big blind size
    uint256 bigBlindSize;
    // Bet types of each round for each player
    BetType[][] betTypeEachRound;
    // Whether some players have bet in the current round
    bool someoneHasBet;
    // Encoding of boolean values on whether a player has all in.
    // For example, ((allInRecord >> i) & 1) indicates whether i-th player has all-in.
    uint8 allInRecord;
    // Encoding of boolean values on whether a player has folded.
    // For example, ((foldRecord >> i) & 1) indicates whether i-th player has folded.
    uint8 foldRecord;
}

interface IChipManager {
    // Emits bet event when a player `raise`, `fold`, `call`, or `check`.
    event Bet(
        uint256 boardId,
        address indexed player,
        uint256 indexed amount,
        BetType indexed betType,
        GameStage stage
    );

    // Sets game settings for `boardId` and specifying the big blind size.
    function setGameSetting(
        uint256 boardId,
        uint256 bigBlindSize,
        uint256 numPlayers
    ) external;

    // Sets new round for `boardId`.
    function setNewRound(uint256 boardId) external;

    // Registers all `players` in `boardId`.
    function registerPlayers(
        uint256 boardId,
        address[] calldata players
    ) external;

    // Bets for small blind and big blind.
    function initialBet(uint256 boardId) external;

    // Sets the `buyIn` chips for `boardId`.
    function setBuyIn(uint256 boardId, uint256 buyIn) external;

    // Calls by `playerIndex` for `boardId` game in `stage`.
    function call(uint256 boardId, uint8 playerIndex, GameStage stage) external;

    // Checks by `playerIndex` for `boardId` game in `stage`.
    function check(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external;

    // Raises `amount` by `playerIndex` for `boardId` game in `stage`.
    function raise(
        uint256 boardId,
        uint256 amount,
        uint8 playerIndex,
        GameStage stage
    ) external;

    // Folds by `playerIndex` for `boardId` game in `stage`.
    function fold(uint256 boardId, uint8 playerIndex, GameStage stage) external;

    function allIn(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external;

    // Gets chips[boardId].someoneHasBet.
    function getSomeoneHasBet(uint256 boardId) external view returns (bool);

    // Checks if every player has the same bet.
    function isEveryoneOnTheSameBet(
        uint256 boardId
    ) external view returns (bool);

    // Gets the settlement amount of each player in `boardId` game according to `scores` of each player.
    function settle(
        uint256 boardId,
        uint256[] memory scores
    ) external view returns (uint256[] memory);

    // Gets the pot size of `boardId` game.
    function getPotSize(uint256 boardId) external view returns (uint256);

    // Gets the chip of `boardId` game.
    function getChip(uint256 boardId) external view returns (Chip memory);

    // Gets the chips not bet yet for the `playerIdx`-th player in `boardId` game.
    function getChipSinglePlayer(
        uint256 boardId,
        uint8 playerIdx
    ) external view returns (uint256);
}