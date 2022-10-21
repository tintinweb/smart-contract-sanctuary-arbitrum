/**
 *Submitted for verification at Arbiscan on 2022-10-15
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title TelegramRussianRoulette
 * @dev Store funds for Russian Roulette and distribute the winnings as games finish.
 */
contract TelegramRussianRoulette {

    address public bot;
    address public feeWallet;

    IERC20 public immutable bettingToken;

    uint256 public immutable minimumBet;

    // The amount to take as a fee, in basis points.
    uint256 public immutable feeBps;

    // Map Telegram chat IDs to their games.
    mapping(int64 => Game) public games;

    // The Telegram chat IDs for each active game. Mainly used to
    // abort all active games in the event of a catastrophe.
    int64[] public activeTgGroups;

    // Stores the amount each player has bet for a game.
    event Bet(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);

    // Stores the amount each player wins for a game.
    event Win(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);

    // Stores the amount the loser lost.
    event Loss(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);

    // Stores the amount collected by the protocol.
    event Fee(int64 tgChatId, uint256 amount);

    constructor(address _bettingToken, uint256 _minimumBet, uint256 _feeBps, address _feeWallet) {
        bot = msg.sender;
        feeWallet = _feeWallet;
        feeBps = _feeBps;
        bettingToken = IERC20(_bettingToken);
        minimumBet = _minimumBet;
    }

    modifier onlyBot() {
        require(msg.sender == bot, "Not bot");
        _;
    }

    struct Game {
        uint256 revolverSize;
        uint256 minBet;

        // This is a SHA-256 hash of the random number generated by the bot.
        bytes32 hashedBulletChamberIndex;

        address[] players;
        uint256[] bets;

        bool inProgress;
        uint16 loser;
    }

    /**
     * @dev Check if there is a game in progress for a Telegram group.
     * @param _tgChatId Telegram group to check
     * @return true if there is a game in progress, otherwise false
     */
    function isGameInProgress(int64 _tgChatId) public view returns (bool) {
        return games[_tgChatId].inProgress;
    }

    /**
     * @dev Remove a Telegram chat ID from the array.
     * @param _tgChatId Telegram chat ID to remove
     */
    function removeTgId(int64 _tgChatId) internal {
        for (uint256 i = 0; i < activeTgGroups.length; i++) {
            if (activeTgGroups[i] == _tgChatId) {
                activeTgGroups[i] = activeTgGroups[activeTgGroups.length - 1];
                activeTgGroups.pop();
            }
        }
    }

    /**
     * @dev Create a new game. Transfer funds into escrow.
     * @param _tgChatId Telegram group of this game
     * @param _revolverSize number of chambers in the revolver
     * @param _minBet minimum bet to play
     * @param _hashedBulletChamberIndex which chamber the bullet is in
     * @param _players participating players
     * @param _bets each player's bet
     * @return The updated list of bets.
     */
    function newGame(
        int64 _tgChatId,
        uint256 _revolverSize,
        uint256 _minBet,
        bytes32 _hashedBulletChamberIndex,
        address[] memory _players,
        uint256[] memory _bets) public onlyBot returns (uint256[] memory) {
        require(_revolverSize >= 2, "Revolver size too small");
        require(_players.length <= _revolverSize, "Too many players for this revolver");
        require(_minBet >= minimumBet, "Minimum bet too small");
        require(_players.length == _bets.length, "Players/bets length mismatch");
        require(_players.length > 1, "Not enough players");
        require(!isGameInProgress(_tgChatId), "There is already a game in progress");

        // The bets will be capped so you can only lose what other
        // players bet. The updated bets will be returned to the
        // caller.
        //
        // O(N) by doing a prepass to sum all the bets in the
        // array. Use the sum to modify one bet at a time. Replace
        // each bet with its updated value.
        uint256 betTotal = 0;
        for (uint16 i = 0; i < _bets.length; i++) {
            require(_bets[i] >= _minBet, "Bet is smaller than the minimum");
            betTotal += _bets[i];
        }
        for (uint16 i = 0; i < _bets.length; i++) {
            betTotal -= _bets[i];
            if (_bets[i] > betTotal) {
                _bets[i] = betTotal;
            }
            betTotal += _bets[i];

            require(bettingToken.allowance(_players[i], address(this)) >= _bets[i], "Not enough allowance");
            bool isSent = bettingToken.transferFrom(_players[i], address(this), _bets[i]);
            require(isSent, "Funds transfer failed");

            emit Bet(_tgChatId, _players[i], i, _bets[i]);
        }

        Game memory g;
        g.revolverSize = _revolverSize;
        g.minBet = _minBet;
        g.hashedBulletChamberIndex = _hashedBulletChamberIndex;
        g.players = _players;
        g.bets = _bets;
        g.inProgress = true;

        games[_tgChatId] = g;
        activeTgGroups.push(_tgChatId);

        return _bets;
    }

    /**
     * @dev Declare a loser of the game and pay out the winnings.
     * @param _tgChatId Telegram group of this game
     * @param _loser index of the loser
     *
     * There is also a string array that will be passed in by the bot
     * containing labeled strings, for historical/auditing purposes:
     *
     * beta: The randomly generated number in hex.
     *
     * salt: The salt to append to beta for hashing, in hex.
     *
     * publickey: The VRF public key in hex.
     *
     * proof: The generated proof in hex.
     *
     * alpha: The input message to the VRF.
     */
    function endGame(
        int64 _tgChatId,
        uint16 _loser,
        string[] calldata) public onlyBot {
        require(_loser != type(uint16).max, "Loser index shouldn't be the sentinel value");
        require(isGameInProgress(_tgChatId), "No game in progress for this Telegram chat ID");

        Game storage g = games[_tgChatId];

        require(_loser < g.players.length, "Loser index out of range");
        require(g.players.length > 1, "Not enough players");

        g.loser = _loser;
        g.inProgress = false;
        removeTgId(_tgChatId);

        // Parallel arrays
        address[] memory winners = new address[](g.players.length - 1);
        uint256[] memory winnings = new uint256[](g.players.length - 1);
        uint16[] memory winnersPlayerIndex = new uint16[](g.players.length - 1);

        // The total bets of the winners.
        uint256 winningBetTotal = 0;

        // Filter out the loser and calc the total winning bets.
        uint16 numWinners = 0;
        for (uint16 i = 0; i < g.players.length; i++) {
            if (i != _loser) {
                winners[numWinners] = g.players[i];
                winnersPlayerIndex[numWinners] = i;
                winningBetTotal += g.bets[i];
                numWinners++;
            }
        }

        uint256 totalPaidWinnings = 0;

        // The share left for the contract. This is an approximate
        // value. The real value will be whatever is leftover after
        // each winner is paid their share.
        require(feeBps < 10_1000, "Fee must be < 100%");
        uint256 approxContractShare = g.bets[_loser] * feeBps / 10_000;

        uint256 totalWinnings = g.bets[_loser] - approxContractShare;

        bool isSent;
        for (uint16 i = 0; i < winners.length; i++) {
            winnings[i] = totalWinnings * g.bets[winnersPlayerIndex[i]] / winningBetTotal;

            isSent = bettingToken.transfer(winners[i], g.bets[winnersPlayerIndex[i]]);
            require(isSent, "Funds transfer failed");

            isSent = bettingToken.transfer(winners[i], winnings[i]);
            require(isSent, "Funds transfer failed");

            emit Win(_tgChatId, winners[i], winnersPlayerIndex[i], winnings[i]);

            totalPaidWinnings += winnings[i];
        }

        uint256 realContractShare = g.bets[_loser] - totalPaidWinnings;
        isSent = bettingToken.transfer(feeWallet, realContractShare);
        require(isSent, "Fee transfer failed");
        emit Fee(_tgChatId, realContractShare);

        require((totalPaidWinnings + realContractShare) == g.bets[_loser], "Calculated winnings do not add up");
    }

    /**
     * @dev Abort a game and refund the bets. Use in emergencies
     *      e.g. bot crash.
     * @param _tgChatId Telegram group of this game
     */
    function abortGame(int64 _tgChatId) public onlyBot {
        require(isGameInProgress(_tgChatId), "No game in progress for this Telegram chat ID");
        Game storage g = games[_tgChatId];

        for (uint16 i = 0; i < g.players.length; i++) {
            bool isSent = bettingToken.transfer(g.players[i], g.bets[i]);
            require(isSent, "Funds transfer failed");
        }

        g.inProgress = false;
        removeTgId(_tgChatId);
    }

    /**
     * @dev Abort all in progress games.
     */
    function abortAllGames() public onlyBot {
        // abortGame modifies activeTgGroups with each call, so
        // iterate over a copy
        int64[] memory _activeTgGroups = activeTgGroups;
        for (uint256 i = 0; i < _activeTgGroups.length; i++) {
            abortGame(_activeTgGroups[i]);
        }
    }

    /**
     * @dev Kill myself and return all funds.
     */
    function failsafe() public onlyBot {
        abortAllGames();
        selfdestruct(payable(address(0)));
    }
}