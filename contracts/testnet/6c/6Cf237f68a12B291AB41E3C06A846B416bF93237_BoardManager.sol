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

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BoardManagerTypes.sol";
import "./IBoardManager.sol";
import "./IPokerEvaluator.sol";
import "./shuffle/IShuffle.sol";
import "./account/IAccountManagement.sol";

// The main game logic contract
contract BoardManager is Ownable, IBoardManager {
    // Maps board id to a single board data
    mapping(uint256 => Board) public boards;

    // Maps board id to the map from player's permanent address to player's game status
    mapping(uint256 => mapping(address => PlayerStatus)) public playerStatuses;

    // ZK shuffle contract
    IShuffle public shuffle;

    // Poker evaluatoras contract
    IPokerEvaluator public pokerEvaluator;

    // Account manager
    IAccountManagement public accountManagement;

    uint256 public immutable MIN_BIG_BLIND_SIZE = 10;
    uint256 public immutable MIN_PLAYERS = 3;

    // The multipliers of buy in size according to bb
    uint256 public minBuyInMultiplier = 100;
    uint256 public maxBuyInMultiplier = 500;

    bool public needPresendGas;

    event EvaluatorSet(address indexed evaluator);
    event ShuffleSet(address indexed shuffle);

    // ====================================================================
    // ========================= Public functions =========================
    // these public functions are intended to be interacted with end users
    // ====================================================================
    constructor(
        address shuffle_,
        address pokerEvaluator_,
        address accountManagement_,
        uint256 minBuyInMultiplier_,
        uint256 maxBuyInMultiplier_,
        bool needPresendGas_
    ) {
        setShuffle(shuffle_);
        setEvaluator(pokerEvaluator_);
        setAccountManagement(accountManagement_);
        setBuyInMultipliers(minBuyInMultiplier_, maxBuyInMultiplier_);
        setNeedPresendGas(needPresendGas_);
    }

    // Checks if it is `msg.sender`'s turn to play which supports `msg.sender` as either ephemeral account
    // or permanent account.
    function ensureYourTurn(uint256 boardId) internal view {
        require(
            boards[boardId].nextPlayer ==
                playerStatuses[boardId][
                    accountManagement.getPermanentAccount(msg.sender)
                ].index,
            "Not your turn"
        );
    }

    // Checks if `boardId` is in the specified game `stage`. (Not using modifiers to reduce contract size)
    function ensureValidStage(GameStage stage, uint256 boardId) internal view {
        require(stage == boards[boardId].stage, "Invalid game stage");
    }

    // Checks if `msg.sender` is in game `boardId` no matter `msg.sender` is permanent account
    // or ephemeral account.
    function ensurePlayerExist(uint256 boardId) internal view {
        require(
            accountManagement.getCurGameId(
                accountManagement.getPermanentAccount(msg.sender)
            ) == boardId,
            "Player is not in a game"
        );
    }

    // Sets shuffle contract.
    function setShuffle(address shuffle_) public onlyOwner {
        require(shuffle_ != address(0), "empty address");
        shuffle = IShuffle(shuffle_);
    }

    // Sets account management contract.
    function setAccountManagement(address accountManagement_) public onlyOwner {
        require(accountManagement_ != address(0), "empty address");
        accountManagement = IAccountManagement(accountManagement_);
    }

    // Sets evaluator contract.
    function setEvaluator(address pokerEvaluator_) public onlyOwner {
        require(pokerEvaluator_ != address(0), "empty address");
        pokerEvaluator = IPokerEvaluator(pokerEvaluator_);
    }

    // Sets buy-in multipliers.
    function setBuyInMultipliers(uint256 min, uint256 max) public onlyOwner {
        require(min < max && min > 0, "invalid buyin multipliers");
        minBuyInMultiplier = min;
        maxBuyInMultiplier = max;
    }

    // Set the gas required to play a round of game,
    function setNeedPresendGas(bool needPresendGas_) public onlyOwner {
        needPresendGas = needPresendGas_;
    }

    // Creates a board when starting a new game. Returns the newly created board id.
    function createBoard(
        uint256 numPlayers,
        uint256 bigBlindSize
    ) external override {
        uint256 boardId = accountManagement.generateGameId();
        require(GameStage.Uncreated == boards[boardId].stage, "game created");
        require(
            numPlayers >= MIN_PLAYERS && bigBlindSize >= MIN_BIG_BLIND_SIZE,
            "required players >= 3 && big blind size >= 10"
        );
        Board memory board;
        board.stage = GameStage.GatheringPlayers;
        // Number of stages = 13
        board.betsEachRound = new uint256[][](13);
        board.betTypeEachRound = new uint256[][](13);
        board.numPlayers = numPlayers;
        board.bigBlindSize = bigBlindSize;
        boards[boardId] = board;
        emit BoardCreated(
            accountManagement.getPermanentAccount(msg.sender),
            boardId
        );
        shuffle.setGameSettings(numPlayers, boardId);
    }

    // Joins the `boardId` board with the public key `pk`, the `ephemeralAccount` that `msg.sender`
    // wants to authorize, and `buyIn` amount of chips.
    // Reverts when a) user has joined; b) board players reach the limit.
    function join(
        uint256[2] calldata pk,
        address ephemeralAccount,
        uint256 buyIn,
        uint256 boardId
    ) public payable {
        ensureValidStage(GameStage.GatheringPlayers, boardId);
        uint256 bb = boards[boardId].bigBlindSize;
        require(
            buyIn >= bb * minBuyInMultiplier &&
                buyIn <= bb * maxBuyInMultiplier,
            "Invalid buy-in size"
        );
        accountManagement.join(msg.sender, boardId, buyIn);
        boards[boardId].permanentAccounts.push(msg.sender);
        accountManagement.authorize(msg.sender, ephemeralAccount);
        // fund the ephemeral account, so players don't have to fund the game account manually
        if (needPresendGas) {
            bool success = payable(ephemeralAccount).send(msg.value);
            require(success, "send ether to ephemeral account failed");
        }
        boards[boardId].handCards.push(new uint256[](0));
        boards[boardId].bets.push(0);
        boards[boardId].playerInPots.push(true);
        boards[boardId].chips.push(buyIn);
        boards[boardId].pks.push(pk);
        Board memory board = boards[boardId];
        uint256 playerCount = board.permanentAccounts.length;
        playerStatuses[boardId][msg.sender] = PlayerStatus({
            index: playerCount - 1,
            notFolded: true // TODO: Should be renamed to notFolded, or use false as default.
        });
        shuffle.register(msg.sender, pk, boardId);
        if (playerCount == board.numPlayers) {
            board.stage = GameStage.Shuffle;
            board.dealer = playerCount - 1;
            board.nextPlayer = 0;
            uint256 sbIndex = 0; // TODO: Support the same group of players to continue play
            uint256 bbIndex = 1;
            board.bets[sbIndex] += board.bigBlindSize / 2;
            board.chips[sbIndex] -= board.bigBlindSize / 2;
            board.bets[bbIndex] += board.bigBlindSize;
            board.chips[bbIndex] -= board.bigBlindSize;
            board.lastRaise = board.bigBlindSize;
            board.raiseBeforeLastRaise = 0;
            board.potSize = (board.bigBlindSize * 3) / 2;
        }
        boards[boardId] = board;
        emit JoinedBoard(msg.sender, boardId);
    }

    function check(uint256 boardId) external override {
        _performBetWithAmount(BetType.Check, 0, boardId);
    }

    function call(uint256 boardId) external {
        _performBetWithAmount(
            BetType.Call,
            amountToCall(
                accountManagement.getPermanentAccount(msg.sender),
                boardId
            ),
            boardId
        );
    }

    function raise(uint256 amount, uint256 boardId) external override {
        _performBetWithAmount(BetType.Raise, amount, boardId);
    }

    // Folds and deals remaining cards so that `msg.sender` could safely leave the game.
    function fold(
        uint256[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta,
        uint256 boardId
    ) external virtual {
        dealComputation(
            cardIdx,
            proof,
            decryptedCard,
            initDelta,
            boardId,
            false
        );
        _performBetWithAmount(BetType.Fold, 0, boardId);
    }

    // Shuffles the deck without submitting the proof.
    function shuffleDeck(
        uint256[52] calldata shuffledX0,
        uint256[52] calldata shuffledX1,
        uint256[2] calldata selector,
        uint256 boardId
    ) external virtual {
        ensurePlayerExist(boardId);
        ensureValidStage(GameStage.Shuffle, boardId);
        ensureYourTurn(boardId);
        address permanentAccount = accountManagement.getPermanentAccount(
            msg.sender
        );
        shuffle.shuffleDeck(
            permanentAccount,
            shuffledX0,
            shuffledX1,
            selector,
            boardId
        );
        emit DeckShuffled(permanentAccount, boardId);
        _moveToTheNextPlayer(boardId);
    }

    // Submits the proof for shuffling the deck.
    function shuffleProof(uint256[8] calldata proof, uint256 boardId) external {
        address permanentAccount = accountManagement.getPermanentAccount(
            msg.sender
        );
        uint256 playerIdx = shuffle.UNREACHABLE_PLAYER_INDEX();
        for (uint256 i = 0; i < boards[boardId].permanentAccounts.length; i++) {
            if (permanentAccount == boards[boardId].permanentAccounts[i]) {
                playerIdx = i;
            }
        }
        require(
            playerIdx != shuffle.UNREACHABLE_PLAYER_INDEX(),
            "Not in the game"
        );
        shuffle.shuffleProof(proof, boardId, playerIdx);
    }

    // Computes the dealing of multiple cards. This is called in both `deal` and `fold`.
    function dealComputation(
        uint256[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta,
        uint256 boardId,
        bool shouldVerifyDeal
    ) internal {
        require(
            cardIdx.length > 0 &&
                proof.length == cardIdx.length &&
                decryptedCard.length == cardIdx.length &&
                initDelta.length == cardIdx.length
        );
        address permanentAccount = accountManagement.getPermanentAccount(
            msg.sender
        );
        for (uint256 i = 0; i < cardIdx.length; ++i) {
            shuffle.deal(
                permanentAccount,
                cardIdx[i],
                playerStatuses[boardId][permanentAccount].index,
                proof[i],
                decryptedCard[i],
                initDelta[i],
                boardId,
                shouldVerifyDeal
            );
        }
        emit BatchDecryptProofProvided(
            permanentAccount,
            cardIdx.length,
            boardId
        );
    }

    // Deals multiple cards.
    //
    // #Note
    //
    // `memory` is used to avoid `CompilerError: Stack too deep`
    function deal(
        uint256[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta,
        uint256 boardId
    ) external virtual {
        ensurePlayerExist(boardId);
        require(isDealRound(boardId), "not deal round");
        // TODO: connect card index with game stage. See `library BoardManagerView`
        // cardIdxMatchesGameStage(cardIdx, boardId);
        ensureYourTurn(boardId);
        bool shouldVerifyDeal = boards[boardId].stage == GameStage.PostRound;
        dealComputation(
            cardIdx,
            proof,
            decryptedCard,
            initDelta,
            boardId,
            shouldVerifyDeal
        );
        _moveToTheNextPlayer(boardId);
    }

    // Gets card values for `boardId` and `playerIdx`.
    function getCardValues(
        uint256 boardId,
        uint256 playerIdx
    ) internal view virtual returns (uint256[] memory) {
        uint256[] memory actualCardValues = new uint256[](7);
        for (uint256 i = 0; i < 2; i++) {
            actualCardValues[i] = shuffle.search(
                boards[boardId].handCards[playerIdx][i],
                boardId
            );
        }
        for (uint256 i = 0; i < 5; i++) {
            actualCardValues[i + 2] = shuffle.search(
                boards[boardId].communityCards[i],
                boardId
            );
        }
        for (uint256 i = 0; i < 7; i++) {
            require(
                actualCardValues[i] != shuffle.INVALID_CARD_INDEX(),
                "invalid card, something is wrong"
            );
        }
        return actualCardValues;
    }

    // Settles the winner.
    // @todo: split the reward when equal hands occur
    function settleWinner(
        uint256 boardId
    )
        public
        override
        returns (address winner, uint256 bestScore, uint256 winnerIndex)
    {
        bestScore = 9999999;
        ensureValidStage(GameStage.Ended, boardId);
        address[] memory players = boards[boardId].permanentAccounts;
        // search deck with card decryto proofs, and send to decrypted cards to algorithm
        // we only send the outstanding players' hands and keep those who have folded private!
        for (uint256 i = 0; i < players.length; ++i) {
            if (!boards[boardId].playerInPots[i]) {
                continue;
            }
            uint256 score = pokerEvaluator.evaluate(getCardValues(boardId, i));
            // Smaller the score, higher the rank
            if (bestScore > score) {
                bestScore = score;
                winner = players[i];
                winnerIndex = i;
            }
        }
        boards[boardId].winner = winner;
        for (uint256 i = 0; i < players.length; ++i) {
            if (!boards[boardId].playerInPots[i]) {
                continue;
            }
            uint256 playerBet = boards[boardId].bets[i];
            accountManagement.settle(
                boards[boardId].permanentAccounts[i],
                boardId,
                winnerIndex == i
                    ? boards[boardId].potSize - playerBet
                    : playerBet,
                winnerIndex == i,
                true,
                true
            );
        }
    }

    // ====================================================================
    // ========================== View functions ==========================
    // ====================================================================
    function isBetRound(uint256 boardId) public view returns (bool) {
        return
            boards[boardId].stage == GameStage.PreFlopBet ||
            boards[boardId].stage == GameStage.FlopBet ||
            boards[boardId].stage == GameStage.TurnBet ||
            boards[boardId].stage == GameStage.RiverBet;
    }

    function isDealRound(uint256 boardId) public view returns (bool) {
        return boards[boardId].stage == GameStage.PreFlopReveal ||
            boards[boardId].stage == GameStage.FlopReveal ||
            boards[boardId].stage == GameStage.TurnReveal ||
            boards[boardId].stage == GameStage.RiverReveal;
    }

    // The amount is the bet player want to add
    function canCall(
        address permanentAccount,
        uint256 amount,
        uint256 boardId
    ) public view override returns (bool) {
        uint256 playerIndex = playerStatuses[boardId][permanentAccount].index;
        return
            isBetRound(boardId) &&
            boards[boardId].nextPlayer == playerIndex &&
            playerStatuses[boardId][permanentAccount].notFolded &&
            amount == amountToCall(permanentAccount, boardId) &&
            amount > 0 &&
            boards[boardId].chips[playerIndex] >= amount;
    }

    function canCheck(
        address permanentAccount,
        uint256 boardId
    ) public view override returns (bool) {
        uint256 playerIndex = playerStatuses[boardId][permanentAccount].index;
        return
            isBetRound(boardId) &&
            boards[boardId].stage != GameStage.PreFlopBet && // cannot check in PreFlop stage
            boards[boardId].nextPlayer == playerIndex &&
            playerStatuses[boardId][permanentAccount].notFolded &&
            !_isAnyoneBetByRound(boards[boardId].stage, boardId);
    }

    function canRaise(
        address permanentAccount,
        uint256 amount,
        uint256 boardId
    ) public view override returns (bool) {
        uint256 playerIndex = playerStatuses[boardId][permanentAccount].index;
        uint256 newAmount = amount + boards[boardId].bets[playerIndex];
        return
            isBetRound(boardId) &&
            boards[boardId].nextPlayer == playerIndex &&
            playerStatuses[boardId][permanentAccount].notFolded &&
            amount >= minRaise(boardId) &&
            boards[boardId].chips[playerIndex] >= amount &&
            newAmount > highestBet(boardId);
    }

    function canFold(
        address permanentAccount,
        uint256 boardId
    ) public view override returns (bool) {
        return
            isBetRound(boardId) &&
            boards[boardId].nextPlayer ==
            playerStatuses[boardId][permanentAccount].index &&
            playerStatuses[boardId][permanentAccount].notFolded;
    }

    function amountToCall(
        address permanentAccount,
        uint256 boardId
    ) public view override returns (uint256) {
        return
            highestBet(boardId) -
            boards[boardId].bets[
                playerStatuses[boardId][permanentAccount].index
            ];
    }

    function highestBet(
        uint256 boardId
    ) public view override returns (uint256 bet) {
        for (uint256 i = 0; i < boards[boardId].bets.length; ++i) {
            if (boards[boardId].bets[i] > bet) {
                bet = boards[boardId].bets[i];
            }
        }
    }

    function minRaise(uint256 boardId) public view returns (uint256) {
        uint256 delta = boards[boardId].lastRaise -
            boards[boardId].raiseBeforeLastRaise;
        uint256 bb = boards[boardId].bigBlindSize;
        return (delta >= bb ? delta : bb) + boards[boardId].lastRaise;
    }

    // Gets board with `boardId`. This is a workaround to provide a getter since
    // we cannot export dynamic mappings.
    function getBoard(uint256 boardId) external view returns (Board memory) {
        return boards[boardId];
    }

    // Gets the player index of `msg.sender`
    function getPlayerIndex(uint256 boardId) public view returns (uint256) {
        address permanentAccount = accountManagement.getPermanentAccount(
            msg.sender
        );
        return playerStatuses[boardId][permanentAccount].index;
    }

    // ====================================================================
    // ========================= Internals functions ======================
    // ====================================================================

    function _moveToTheNextPlayer(uint256 boardId) internal {
        // if all players check or didn't bet (like reveal & join rounds) in this round, move to the next round
        if (
            boards[boardId].nextPlayer == boards[boardId].dealer &&
            !_isAnyoneBetByRound(boards[boardId].stage, boardId)
        ) {
            _moveToTheNextStage(boardId);
            return;
        }

        // if anyone bet in this round and everyone is on the same bet, move to the next stage
        if (
            _isEveryoneOnTheSameBet(boardId) &&
            _isAnyoneBetByRound(boards[boardId].stage, boardId)
        ) {
            _moveToTheNextStage(boardId);
            return;
        }

        // skip the users who have folded
        uint256 nextPlayerIndex = (boards[boardId].nextPlayer + 1) %
            boards[boardId].permanentAccounts.length;
        boards[boardId].nextPlayer = nextPlayerIndex;
        emit NextPlayer(nextPlayerIndex, boardId);
        if (
            !playerStatuses[boardId][
                boards[boardId].permanentAccounts[nextPlayerIndex]
            ].notFolded
        ) {
            _moveToTheNextPlayer(boardId);
            return;
        }
    }

    function _moveToTheNextStage(uint256 boardId) internal {
        // when the status reach the end, there is no way for this game to be replayed
        uint256 nextStage = uint256(boards[boardId].stage) + 1;
        require(nextStage <= uint256(GameStage.Ended), "game already ended");
        // now it's another round
        boards[boardId].stage = GameStage(nextStage);
        boards[boardId].betsEachRound[nextStage] = new uint256[](
            boards[boardId].permanentAccounts.length
        );
        boards[boardId].betTypeEachRound[nextStage] = new uint256[](
            boards[boardId].permanentAccounts.length
        );
        boards[boardId].lastRaise = 0;
        boards[boardId].raiseBeforeLastRaise = 0;
        emit GameStageChanged(GameStage(nextStage), boardId);
        _postRound(boards[boardId].stage, boardId);
    }

    // Do something right after the game stage updated
    function _postRound(GameStage newStage, uint256 boardId) internal {
        uint256 playerCount = boards[boardId].permanentAccounts.length;
        if (newStage == GameStage.PreFlopReveal) {
            // now it's preflop, assign 2 cards to each player
            for (uint256 i = 0; i < playerCount; ++i) {
                uint256[] memory hands = new uint256[](2);
                hands[0] = i * 2;
                hands[1] = i * 2 + 1;
                boards[boardId].handCards[i] = hands;
            }
        } else if (newStage == GameStage.FlopReveal) {
            // now it's flop, assign 3 cards to community deck
            uint256[] memory communityCards = new uint256[](3);
            communityCards[0] = playerCount * 2;
            communityCards[1] = playerCount * 2 + 1;
            communityCards[2] = playerCount * 2 + 2;
            boards[boardId].communityCards = communityCards;
        } else if (newStage == GameStage.TurnReveal) {
            // now it's turn, assign 1 card to community deck
            boards[boardId].communityCards.push(playerCount * 2 + 3);
        } else if (newStage == GameStage.RiverReveal) {
            // now it's river, assign 1 card to community deck
            boards[boardId].communityCards.push(playerCount * 2 + 4);
        } else if (newStage == GameStage.PreFlopBet) {
            // if it's the first betting round, BB and SB have already bet
            uint256 sbIndex = (boards[boardId].dealer + 1) % playerCount;
            uint256 bbIndex = (boards[boardId].dealer + 2) % playerCount;
            boards[boardId].nextPlayer =
                (boards[boardId].dealer + 3) %
                playerCount;
            boards[boardId].betsEachRound[uint256(newStage)][sbIndex] =
                boards[boardId].bigBlindSize /
                2;
            boards[boardId].betsEachRound[uint256(newStage)][bbIndex] = boards[
                boardId
            ].bigBlindSize;
            boards[boardId].lastRaise = boards[boardId].bigBlindSize;
            return;
        } else if (newStage == GameStage.Ended) {
            settleWinner(boardId);
            return;
        }
        boards[boardId].nextPlayer = _firstNonFoldedPlayer(boardId);
    }

    function _performBetWithAmount(
        BetType betType,
        uint256 amount,
        uint256 boardId
    ) internal {
        ensurePlayerExist(boardId);
        require(isBetRound(boardId), "can't bet now");
        ensureYourTurn(boardId);
        address permanentAccount = accountManagement.getPermanentAccount(
            msg.sender
        );
        uint256 playerIndex = playerStatuses[boardId][permanentAccount].index;
        if (betType == BetType.Call) {
            require(canCall(permanentAccount, amount, boardId), "cannot call");
            boards[boardId].chips[playerIndex] -= amount;
            boards[boardId].bets[playerIndex] += amount;
            boards[boardId].potSize += amount;
            boards[boardId].betsEachRound[uint256(boards[boardId].stage)][
                playerIndex
            ] += amount;
            boards[boardId].betTypeEachRound[uint256(boards[boardId].stage)][
                playerIndex
            ] = uint256(BetType.Call);
        } else if (betType == BetType.Raise) {
            require(
                canRaise(permanentAccount, amount, boardId),
                "cannot raise"
            );
            boards[boardId].chips[playerIndex] -= amount;
            boards[boardId].bets[playerIndex] += amount;
            boards[boardId].potSize += amount;
            boards[boardId].betsEachRound[uint256(boards[boardId].stage)][
                playerIndex
            ] += amount;
            boards[boardId].betTypeEachRound[uint256(boards[boardId].stage)][
                playerIndex
            ] = uint256(BetType.Raise);

            // assign the raise record
            boards[boardId].raiseBeforeLastRaise = boards[boardId].lastRaise;
            boards[boardId].lastRaise = amount;
        } else if (betType == BetType.Check) {
            require(canCheck(permanentAccount, boardId), "cannot check");
            boards[boardId].betTypeEachRound[uint256(boards[boardId].stage)][
                playerIndex
            ] = uint256(BetType.Check);
        } else if (betType == BetType.Fold) {
            require(canFold(permanentAccount, boardId), "cannot fold");
            playerStatuses[boardId][permanentAccount].notFolded = false;
            boards[boardId].playerInPots[playerIndex] = false;
            boards[boardId].betTypeEachRound[uint256(boards[boardId].stage)][
                playerIndex
            ] = uint256(BetType.Fold);
            accountManagement.settle(
                permanentAccount,
                boardId,
                boards[boardId].bets[playerIndex],
                false,
                true,
                true
            );
            if (_trySettleWinnerDirectly(boardId)) {
                return;
            }
        }
        // play is done for this round
        emit Bet(
            boards[boardId].permanentAccounts[playerIndex],
            amount,
            uint256(betType),
            uint256(boards[boardId].stage),
            boardId
        );
        _moveToTheNextPlayer(boardId);
    }

    // if there is only one player left, announce winner directly
    function _trySettleWinnerDirectly(
        uint256 boardId
    ) internal returns (bool hasWinner) {
        uint256 stillInPot;
        uint256 winnerIndex;
        for (uint256 i = 0; i < boards[boardId].playerInPots.length; ++i) {
            if (boards[boardId].playerInPots[i]) {
                stillInPot++;
                winnerIndex = i;
            }
        }
        if (stillInPot == 1) {
            address winner = boards[boardId].permanentAccounts[winnerIndex];
            boards[boardId].winner = winner;
            boards[boardId].stage = GameStage.Ended;
            boards[boardId].chips[winnerIndex] += boards[boardId].potSize;
            accountManagement.settle(
                winner,
                boardId,
                boards[boardId].potSize - boards[boardId].bets[winnerIndex],
                true,
                true,
                true
            );
            hasWinner = true;
        }
    }

    function _firstNonFoldedPlayer(
        uint256 boardId
    ) internal view returns (uint256 index) {
        for (uint256 i = 0; i < boards[boardId].permanentAccounts.length; ++i) {
            if (boards[boardId].playerInPots[i]) {
                index = i;
                break;
            }
        }
    }

    // filter out all the folded players
    function _isEveryoneOnTheSameBet(
        uint256 boardId
    ) internal view returns (bool) {
        uint256 firstNonFoldPlayerBet = boards[boardId].bets[
            _firstNonFoldedPlayer(boardId)
        ];
        for (uint256 i = 0; i < boards[boardId].permanentAccounts.length; ++i) {
            if (!boards[boardId].playerInPots[i]) {
                continue;
            }
            if (boards[boardId].bets[i] != firstNonFoldPlayerBet) {
                return false;
            }
        }
        return true;
    }

    function _isAnyoneBetByRound(
        GameStage stage,
        uint256 boardId
    ) internal view returns (bool) {
        uint256[] storage betsInThisStage = boards[boardId].betsEachRound[
            uint256(stage)
        ];
        for (uint256 i = 0; i < betsInThisStage.length; ++i) {
            if (betsInThisStage[i] > 0) {
                return true;
            }
        }
        return false;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // Challenges the proof from `playerIdx` in `boardId` game. `isShuffle` indicates
    // whether challenging shuffle or deal which further specifies `cardIdx` card.
    function challenge(
        uint256 boardId,
        uint256 playerIdx,
        uint256 cardIdx,
        bool isShuffle
    ) external {
        address challenger = accountManagement.getPermanentAccount(msg.sender);
        address challenged = boards[boardId].permanentAccounts[playerIdx];
        if (isShuffle) {
            try shuffle.verifyShuffle(boardId, playerIdx) returns (bool) {
                punish(boardId, challenger, challenged, true);
            } catch (bytes memory) {
                punish(boardId, challenger, challenged, false);
            }
        } else {
            try shuffle.verifyDeal(boardId, playerIdx, cardIdx) {
                punish(boardId, challenger, challenged, true);
            } catch (bytes memory) {
                punish(boardId, challenger, challenged, false);
            }
        }
    }

    // Punishes `challenger` or `challenged` depending on `punishChallenger`.
    function punish(
        uint256 boardId,
        address challenger,
        address challenged,
        bool punishChallenger
    ) internal {
        if (punishChallenger) {
            return;
        } else {
            if (boards[boardId].stage != GameStage.Ended) {
                boards[boardId].stage = GameStage.Ended;
                address[] memory players = boards[boardId].permanentAccounts;
                for (uint256 i = 0; i < players.length; ++i) {
                    accountManagement.settle(
                        boards[boardId].permanentAccounts[i],
                        boardId,
                        0,
                        true,
                        false,
                        true
                    );
                }
            }
            accountManagement.move(challenged, challenger);
            emit Challenged(challenged, challenger, boardId, punishChallenger);
        }
    }

    // @todo, we still need more testing and thinking on this feature:
    // let caller actively quit the game, should be called by players who want to quit in the middle
    // of the game, after which the game will end and other players' bet chips will be returned
    function quit(uint256 boardId) external {
        ensurePlayerExist(boardId);
        uint256 playerIndex = getPlayerIndex(boardId);
        address[] memory players = boards[boardId].permanentAccounts;
        for (uint256 i = 0; i < players.length; ++i) {
            accountManagement.settle(
                boards[boardId].permanentAccounts[i],
                boardId,
                // if it's the quitter, all his chips will not be returned
                playerIndex == i ? boards[boardId].chips[i] + boards[boardId].bets[i]: 0,
                playerIndex != i, 
                false,
                true
            );
        }
        boards[boardId].stage = GameStage.Ended;
    }
}

// TODO: In the next PR, we will require only certain card indices can be dealt in a specific game stage.
// library BoardManagerView {
//     // Gets index of `msg.sender`.
//     function getSenderIndex(uint256 boardId) internal view returns (uint256) {
//         address permanentAccount = accountManagement.getPermanentAccount(
//             msg.sender
//         );
//         for (uint256 i = 0; i < boards[boardId].permanentAccounts.length; i++) {
//             if (permanentAccount == boards[boardId].permanentAccounts[i]) {
//                 return i;
//             }
//         }
//         revert("Player is not in a game");
//     }

//     // Checks if `cardIdx` array is well-formed.
//     function cardIdxMatchesGameStage(
//         uint256[] calldata cardIdx,
//         uint256 numPlayers,
//         GameStage stage,
//         uint256 boardId
//     ) internal view {
//         uint256 curPlayerIdx = getSenderIndex(boardId);
//         if (stage == GameStage.PreFlopReveal) {
//             require(
//                 cardIdx.length == (numPlayers - 1) * 2,
//                 "Invalid length of card index array"
//             );
//             for (uint256 i = 0; i < curPlayerIdx; i++) {
//                 require(cardIdx[2 * i] == i * 2, "Invalid card index");
//                 require(cardIdx[2 * i + 1] == i * 2 + 1, "Invalid card index");
//             }
//             for (uint256 i = curPlayerIdx + 1; i < numPlayers; i++) {
//                 require(cardIdx[2 * (i - 1)] == i * 2, "Invalid card index");
//                 require(
//                     cardIdx[2 * (i - 1) + 1] == i * 2 + 1,
//                     "Invalid card index"
//                 );
//             }
//         } else if (stage == GameStage.FlopReveal) {
//             require(cardIdx.length == 3, "Invalid length of card index array");
//             require(cardIdx[0] == numPlayers * 2, "Invalid card index");
//             require(cardIdx[1] == numPlayers * 2 + 1, "Invalid card index");
//             require(cardIdx[2] == numPlayers * 2 + 2, "Invalid card index");
//         } else if (stage == GameStage.TurnReveal) {
//             require(cardIdx.length == 1, "Invalid length of card index array");
//             require(cardIdx[0] == numPlayers * 2 + 3, "Invalid card index");
//         } else if (stage == GameStage.RiverReveal) {
//             require(cardIdx.length == 1, "Invalid length of card index array");
//             require(cardIdx[0] == numPlayers * 2 + 4, "Invalid card index");
//         } else if (stage == GameStage.PostRound) {
//             require(cardIdx.length == 2, "Invalid length of card index array");
//             require(cardIdx[0] == curPlayerIdx * 2, "Invalid card index");
//             require(cardIdx[1] == curPlayerIdx * 2 + 1, "Invalid card index");
//         }
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

// Bet types, unknown type means actions not performed yet
enum BetType {
    Unknown,
    Call,
    Fold,
    Raise,
    Check
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

// Decoded card info from integers between 0,1,...,51.
// Formally, given an integer v, the Rank is v // 13 and the value is v % 13.
// For example, integer 50 is decoded as:
//      rank: 50 / 13 = 3 (Clubs), value: 50 % 13 = 11 (2,3,4,5,6,7,8,9,10,J,>>Q<<,K,A)
struct CardInfo {
    Rank rank;
    uint256 value;
}

// Board state
struct Board {
    // Current game stage
    GameStage stage;
    // Ephemeral accounts of all players
    address[] permanentAccounts;
    // Chips of each player
    uint256[] chips;
    // Bets from each player
    uint256[] bets;
    // Bets of each round from all players
    uint256[][] betsEachRound;
    uint256[][] betTypeEachRound;
    // Indices of community cards for each player
    uint256[] communityCards;
    // Indices of hand cards for each player
    uint256[][] handCards;
    // Booleans on whether a player is still in pots
    bool[] playerInPots;
    // Index of the next player to playe
    uint256 nextPlayer;
    // Dealer index
    uint256 dealer;
    // Big blind size
    uint256 bigBlindSize;
    // The raise record to calculate next minimal raise amount 
    uint256 lastRaise;
    uint256 raiseBeforeLastRaise;
    // Winner address which is set as address(0) before game ends
    address winner;
    // Required number of players to play
    uint256 numPlayers;
    // Total chips in pot
    uint256 potSize;
    // Public keys of all players
    uint256[][] pks;
}

// Player status in a single board
struct PlayerStatus {
    // Player index
    uint256 index;
    // Boolean on whether the player has folded or not
    bool notFolded;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./BoardManagerTypes.sol";

interface IBoardManager {
    // ========================== Events ==========================
    event BoardCreated(address indexed creator, uint256 indexed boardId);
    event JoinedBoard(address indexed player, uint256 indexed boardId);
    event Bet(
        address indexed player,
        uint256 indexed amount,
        uint256 indexed betType,
        uint256 stage,
        uint256 boardId
    );
    event NextPlayer(uint256 indexed playerIndex, uint256 indexed boardId);
    event GameStageChanged(GameStage indexed stage, uint256 indexed boardId);

    event DeckShuffled(address indexed player, uint256 indexed boardId);
    event DecryptProofProvided(
        address indexed sender,
        uint256 indexed cardIndex,
        uint256 indexed boardId
    );

    event BatchDecryptProofProvided(
        address indexed sender,
        uint256 indexed cardCount,
        uint256 indexed boardId
    );

    event Challenged(
        address indexed challenged,
        address indexed challenger,
        uint256 boardId,
        bool punishChallenger
    );
     

    // ========================== Public ==========================
    // create a board for a new game, reverts when
    // - the current board is not ended yet
    // - parameter checking fails
    function createBoard(
        uint256 numPlayers,
        uint256 bigBlindSize
    ) external;

    // Joins the `boardId` board with the public key `pk`, the `ephemeralAccount` that `msg.sender`
    // wants to authorize, and `buyIn` amount of chips.
    // Reverts when a) user has joined; b) board players reach the limit.
    function join(
        uint256[2] calldata pk,
        address ephemeralAccount,
        uint256 buyIn,
        uint256 boardId
    ) external payable;

    // player call this function to check, reverts when
    // - it's not the player's turn
    // - player is not in the pot anymore
    // - player can't check according to the game logic
    // - game stage mismatch
    function check(uint256 boardId) external;

    // player call this function to raise, reverts when
    // - it's not the player's turn
    // - player is not in the pot anymore
    // - player can't raise according to the game logic
    // - game stage mismatch
    function raise(uint256 amount, uint256 boardId) external;

    // player call this function to call, reverts when
    // - it's not the player's turn
    // - player is not in the pot anymore
    // - player can't call according to the game logic
    // - game stage mismatch
    function call(uint256 boardId) external;

    // player call this function to fold, reverts when
    // - it's not the player's turn
    // - player is not in the pot anymore
    // - player can't fold according to the game logic
    // - game stage mismatch
    function fold(
        uint256[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta,
        uint256 boardId
    ) external;

    // Shuffles the deck without submitting the proof.
    function shuffleDeck(
        uint256[52] calldata shuffledX0,
        uint256[52] calldata shuffledX1,
        uint256[2] calldata selector,
        uint256 boardId
    ) external;

    // Submits the proof for shuffling the deck.
    function shuffleProof(uint256[8] calldata proof, uint256 boardId) external;

    // everyone needs to provide the reveal proof to reveal a specific card of the deck, fails when
    // - user who's not his turn calls this func
    // - user provide for that card twice
    // - proof verification fails
    function deal(
        uint256[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta,
        uint256 boardId
    ) external;

    // call this function the contract will calculate the hands of all players and save the winner
    // also transfers all the bets on the table to the winner
    function settleWinner(uint256 boardId)
        external
        returns (
            address winner,
            uint256 highestScore,
            uint256 winnerIndex
        );

    // ========================== View functions ==========================
    function canCall(
        address player,
        uint256 amount,
        uint256 boardId
    ) external view returns (bool);

    function canRaise(
        address player,
        uint256 amount,
        uint256 boardId
    ) external view returns (bool);

    function canCheck(address player, uint256 boardId)
        external
        view
        returns (bool);

    function canFold(address player, uint256 boardId)
        external
        view
        returns (bool);

    function amountToCall(address player, uint256 boardId)
        external
        view
        returns (uint256);

    function highestBet(uint256 boardId) external view returns (uint256 bet);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

interface IPokerEvaluator {
    // return the point of a hand
    function evaluate(uint256[] calldata cards) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IAccountManagement {
    // Generate a new game id.
    function generateGameId() external returns (uint256);

    // Joins a game with `gameId`, `buyIn`, and `isNewGame` on whether joining a new game or an existing game.
    //
    // # Note
    //
    // We prohibit players to join arbitrary game with `gameId`. We allow registered game contract to specify
    // `gameId` to resolve issues such as player collusion.
    function join(
        address player,
        uint256 gameId,
        uint256 buyIn
    ) external;

    // Settles chips for `player` and `gameId` by adding `amount` if `isPositive` and subtracting `amount` otherwise.
    // Chips are immediately repaid to `chipEquity` if `removeDelay`.
    //
    // # Note
    //
    // We allow registered contracts to settle wins and loses for `player` after each game.
    function settle(
        address player,
        uint256 gameId,
        uint256 amount,
        bool isPositive,
        bool collectVigor,
        bool removeDelay
    ) external;

    // Exchange ratio where `chipEquity` = `ratio` * `token`
    function ratio() external view returns (uint256);

    // ERC20 Token type to swap with `chipEquity`
    function token() external view returns (address);

    // Deposits ERC20 tokens for chips.
    function deposit(uint256 tokenAmount) external payable;

    // Moves all chips from `from` to `to`.
    function move(address from, address to) external;

    // Authorizes `ephemeralAccount` for `permanentAccount` by a registered contract.
    function authorize(address permanentAccount, address ephemeralAccount)
        external;

    // Checks if `permanentAccount` has authorized `ephemeralAccount`.
    function hasAuthorized(address permanentAccount, address ephemeralAccount)
        external
        returns (bool);

    // Gets the largest game id which have been created.
    function getLargestGameId() external view returns (uint256);

    // Gets the current game id of `player`.
    function getCurGameId(address player) external view returns (uint256);

    // Returns the corresponding permanent account by ephemeral account
    function accountMapping(address ephemeral) external view returns (address);

    // Returns `account` if it has not been registered as an ephemeral account;
    // otherwise returns the corresponding permanent account.
    function getPermanentAccount(address account)
        external
        view
        returns (address);

    // Gets the amount of chip equity.
    function getChipEquityAmount(address player) external view returns (uint256);

    // Batch get the chip amounts of players 
    function getChipEquityAmounts(address[] calldata players) external view returns (uint256[] memory chips);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

interface IShuffleEncryptVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[215] memory input
    ) external view;
}

interface IDecryptVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view;
}

// Deck of cards
struct Deck {
    // x0 of 52 cards
    uint256[52] X0;
    // x1 of 52 cards
    uint256[52] X1;
    // 2 selectors for recovering y coordinates
    uint256[2] Selector;
    // proof
    uint256[8] Proof;
    // timestamp when receiving X0, X1, and Selector
    uint256 timestamp;
}

// Cards in dealing assuming at most 9 players.
struct CardDeal {
    uint256[52] X0;
    uint256[52] Y0;
    uint256[10][52] X1;
    uint256[10][52] Y1;
    uint256[8][9][52] proof;
    uint256[9][52] prevPlayerIdx;
    // Record which player has decrypted individual cards
    // Warning: Support at most 256 players
    uint256[52] record;
    // Index of the last player who dealed a card
    uint256[52] curPlayerIdx;
}

// Player information
struct PlayerInfo {
    // Address of each player. Length should match `numPlayer`.
    address[] playerAddr;
    // Public key of each player
    uint256[] playerPk;
    // An aggregated public key for all players
    uint256[2] aggregatedPk;
    // Nonce
    uint256 nonce;
}

// State of the game
enum State {
    Registration,
    ShufflingDeck,
    DealingCard
}

interface IShuffle {
    // A constant indicating the card is not found in the deck
    function INVALID_CARD_INDEX() external view returns (uint256);

    // A constant indicating the player is not found in the deck
    function UNREACHABLE_PLAYER_INDEX() external view returns (uint256);

    // Set the game settings of the game of `gameId`
    function setGameSettings(uint256 numPlayers_, uint256 gameId) external;

    // Registers a player with the `permanentAccount`, public key `pk`, and `gameId`.
    function register(
        address permanentAccount,
        uint256[2] memory pk,
        uint256 gameId
    ) external;

    // Returns the aggregated public key for all players.
    function queryAggregatedPk(uint256 gameId)
        external
        view
        returns (uint256[2] memory);

    // Queries deck.
    function queryDeck(uint256 gameId, uint256 playerIdx)
        external
        view
        returns (Deck memory);

    // Queries the `index`-th card from the deck.
    function queryCardFromDeck(uint256 index, uint256 gameId)
        external
        view
        returns (uint256[4] memory card);

    // Queries the `index`-th card in deal.
    function queryCardInDeal(uint256 index, uint256 gameId)
        external
        view
        returns (uint256[4] memory card);

    // Queries card deal records.
    function queryCardDealRecord(uint256 index, uint256 gameId)
        external
        view
        returns (uint256);

    // Shuffles the deck for `permanentAccount`.
    function shuffleDeck(
        address permanentAccount,
        uint256[52] memory shuffledX0,
        uint256[52] memory shuffledX1,
        uint256[2] memory selector,
        uint256 gameId
    ) external;

    // Updates the shuffle `proof` for `gameId` and `playerIdx`.
    function shuffleProof(
        uint256[8] calldata proof,
        uint256 gameId,
        uint256 playerIdx
    ) external;

    // Deals the `cardIdx`-th card given the zk `proof` of validity and `out` for decrypted card from `curPlayerIdx`.
    //  `initDelta` is used when `curPlayerIdx` is the first one to decrypt `cardIdx`-th card due to the compressed
    //  representation of elliptic curve points.
    function deal(
        address permanentAccount,
        uint256 cardIdx,
        uint256 curPlayerIdx,
        uint256[8] memory proof,
        uint256[2] memory decryptedCard,
        uint256[2] memory initDelta,
        uint256 gameId,
        bool shouldVerifyDeal
    ) external;

    // Searches the value of the `cardIndex`-th card in the `gameId`-th game.
    function search(uint256 cardIndex, uint256 gameId)
        external
        view
        returns (uint256);

    // Verifies proof for the deal for `cardIdx` card from `playerIdx` in `gameId` game.
    // Returns true for succeed, false for invalid request, and revert for not passing verification.
    function verifyDeal(
        uint256 gameId,
        uint256 playerIdx,
        uint256 cardIdx
    ) external view returns (bool);

    // Verifies proof for `gameId` and `playerIdx`.
    // Returns true for succeed, false for invalid request, and revert for not passing verification.
    function verifyShuffle(uint256 gameId, uint256 playerIdx)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}