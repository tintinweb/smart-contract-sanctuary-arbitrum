/**
 *Submitted for verification at Arbiscan.io on 2024-06-15
*/

// File: contracts/DataTypes.sol


pragma solidity ^0.8.0;

library DataTypes {
    struct ManagersStorage {
        address owner;
        address pendingOwner;
        mapping(address => bool) operators;
    }

    struct UsersStorage {
        mapping(address => uint256) balances;
    }

    enum State {
        OPEN,
        CLOSED,
        SETTLED,
        FINALIZED
    }

    struct Outcome {
        uint256 totalBetAmount;
        mapping(address => uint256) playerBets;
        address[] players;
    }

    struct Game {
        State state;
        uint8 totalOutcome;
        uint256 bettingDeadline;
        mapping(uint8 => Outcome) outcomes;
        uint8 result;
    }

    struct GamesStorage {
        mapping(bytes32 => Game) games;
        uint256 unCollectedFee;
        uint256 platformFeeRate;
    }
}

// File: contracts/GameLib.sol


pragma solidity ^0.8.19;


library GameLib {
    bytes32 internal constant GAMES_STORAGE_POSITION =
        keccak256("com.xoilabs.games_v2.storage");

    function gamesStorage()
        internal
        pure
        returns (DataTypes.GamesStorage storage gss)
    {
        bytes32 position = GAMES_STORAGE_POSITION;
        assembly {
            gss.slot := position
        }
    }

    function getBettingDeadline(
        DataTypes.Game storage game
    ) internal view returns (uint256) {
        return game.bettingDeadline == 0 ? 10 ** 11 : game.bettingDeadline;
    }

    function isGameOpen(
        DataTypes.Game storage game
    ) internal view returns (bool) {
        return
            game.state == DataTypes.State.OPEN &&
            getBettingDeadline(game) > block.timestamp;
    }

    function isGameSettled(
        DataTypes.Game storage game
    ) internal view returns (bool) {
        return game.state == DataTypes.State.SETTLED;
    }

    function isGameFinalized(
        DataTypes.Game storage game
    ) internal view returns (bool) {
        return game.state == DataTypes.State.FINALIZED;
    }

    function changeState(
        DataTypes.Game storage game,
        DataTypes.State newState
    ) internal {
        enforceNotGameFinalized(game);
        game.state = newState;
    }

    function getTotalOutcome(
        DataTypes.Game storage game
    ) internal view returns (uint8) {
        return game.totalOutcome > 0 ? game.totalOutcome : 3;
    }

    function totalBetForGame(
        DataTypes.Game storage game
    ) internal view returns (uint256 total) {
        uint8 totalOutcome = getTotalOutcome(game);
        for (uint8 i = 0; i < totalOutcome; i++) {
            total += game.outcomes[i].totalBetAmount;
        }
    }

    function enforceGameClosed(DataTypes.Game storage game) internal view {
        require(!isGameOpen(game), "Betting is open for this game");
    }

    function enforceGameOpen(DataTypes.Game storage game) internal view {
        require(isGameOpen(game), "Betting is closed for this game");
    }

    function enforceGameSettled(DataTypes.Game storage game) internal view {
        require(isGameSettled(game), "Game is not settled yet");
    }

    function enforceNotGameFinalized(
        DataTypes.Game storage game
    ) internal view {
        require(!isGameFinalized(game), "Game is finalized yet");
    }

    function setResult(DataTypes.Game storage game, uint8 result) internal {
        enforceGameClosed(game);
        game.result = result;
        changeState(game, DataTypes.State.SETTLED);
    }

    function setBettingDeadline(
        DataTypes.Game storage game,
        uint256 bettingDeadline
    ) internal {
        game.bettingDeadline = bettingDeadline;
    }

    function setTotalOutcome(
        DataTypes.Game storage game,
        uint8 totalOutcome
    ) internal {
        game.totalOutcome = totalOutcome;
    }

    function placeBet(
        DataTypes.Game storage game,
        uint8 result,
        uint256 amount
    ) internal {
        require(amount > 0, "Bet amount must be greater than zero");
        require(getTotalOutcome(game) >= result, "Outcome invalid");

        enforceGameOpen(game);

        game.outcomes[result].totalBetAmount += amount;
        game.outcomes[result].playerBets[msg.sender] += amount;

        if (!_isPlayerAlreadyBetting(game, result)) {
            game.outcomes[result].players.push(msg.sender);
        }
    }

    function _isPlayerAlreadyBetting(
        DataTypes.Game storage game,
        uint8 result
    ) internal view returns (bool) {
        for (uint256 i = 0; i < game.outcomes[result].players.length; i++) {
            if (game.outcomes[result].players[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/UserLib.sol


pragma solidity ^0.8.0;


library UserLib {
    bytes32 internal constant USERS_STORAGE_POSITION =
        keccak256("com.xoilabs.users.storage");

    function usersStorage()
        internal
        pure
        returns (DataTypes.UsersStorage storage uss)
    {
        bytes32 position = USERS_STORAGE_POSITION;
        assembly {
            uss.slot := position
        }
    }

    function getUserBalance(address user) internal view returns (uint256) {
        DataTypes.UsersStorage storage uss = usersStorage();
        return uss.balances[user];
    }

    event UserBalanceUpdate(
        address user,
        uint256 currentBalance,
        uint256 newBalance
    );

    function adjustUserBalance(
        address user,
        uint256 amount,
        bool increase
    ) internal {
        DataTypes.UsersStorage storage uss = usersStorage();
        uint256 currentBalance = uss.balances[user];

        if (increase) {
            uss.balances[user] += uint256(amount);
        } else {
            require(uss.balances[user] >= amount, "Insufficient balance");
            uss.balances[user] -= amount;
        }

        emit UserBalanceUpdate(user, currentBalance, uss.balances[user]);
    }
}

// File: contracts/AdminLib.sol


pragma solidity ^0.8.0;


library AdminLib {
    bytes32 internal constant MANAGERS_STORAGE_POSITION =
        keccak256("com.xoilabs.managers.storage");

    function managersStorage()
        internal
        pure
        returns (DataTypes.ManagersStorage storage uss)
    {
        bytes32 position = MANAGERS_STORAGE_POSITION;
        assembly {
            uss.slot := position
        }
    }

    function onwer() internal view returns (address) {
        DataTypes.ManagersStorage storage ms = managersStorage();
        return ms.owner;
    }

    function isOperator(address _addr) internal view returns (bool) {
        DataTypes.ManagersStorage storage ms = managersStorage();
        return ms.operators[_addr];
    }

    function addOperator(address operator) internal {
        DataTypes.ManagersStorage storage ms = managersStorage();
        ms.operators[operator] = true;
    }

    function removeOperator(address operator) internal {
        DataTypes.ManagersStorage storage ms = managersStorage();
        ms.operators[operator] = false;
    }
}

// File: contracts/GameLogicV1.sol


pragma solidity ^0.8.0;





contract GameLogicV1 {
    using GameLib for DataTypes.Game;

    event BetPlaced(
        address indexed user,
        bytes32 indexed gameId,
        uint8 result,
        uint256 amount
    );

    event GameBettingDeadlineUpdated(
        bytes32 indexed gameId,
        uint256 bettingDeadline
    );
    event GameClosed(bytes32 indexed gameId);
    event GameResultSet(bytes32 indexed gameId, uint8 result);
    event GameFinalized(bytes32 indexed gameId);

    modifier onlyOwner() {
        require(
            AdminLib.onwer() == msg.sender,
            "Only owner can call this function"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            AdminLib.isOperator(msg.sender),
            "Only operator can call this function"
        );
        _;
    }

    function platformFeeRate() public view returns (uint256) {
        return GameLib.gamesStorage().platformFeeRate;
    }

    function setPlatformFee(uint256 _newFee) public onlyOwner {
        GameLib.gamesStorage().platformFeeRate = _newFee;
    }

    function addOperator(address operator) external onlyOwner {
        AdminLib.addOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        AdminLib.removeOperator(operator);
    }

    function userBalance(address user) external view returns (uint256) {
        return UserLib.getUserBalance(user);
    }

    function deposit() external payable {
        UserLib.adjustUserBalance(msg.sender, msg.value, true);
    }

    function withdraw(uint256 amount) external {
        UserLib.adjustUserBalance(msg.sender, amount, false);
        payable(msg.sender).transfer(amount);
    }

    function placeBet(
        string memory gameIdStr,
        uint8 result,
        uint256 amount
    ) external {
        bytes32 gameId = stringToBytes32(gameIdStr);
        UserLib.adjustUserBalance(msg.sender, amount, false);
        DataTypes.Game storage game = GameLib.gamesStorage().games[gameId];
        game.placeBet(result, amount);
        emit BetPlaced(msg.sender, gameId, result, amount);
    }

    function setTotalOutcome(
        string memory gameIdStr,
        uint8 totalOutcome
    ) external onlyOperator {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.Game storage game = GameLib.gamesStorage().games[gameId];
        game.setTotalOutcome(totalOutcome);
    }

    function setBettingDeadline(
        string memory gameIdStr,
        uint256 bettingDeadline
    ) external onlyOperator {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.Game storage game = GameLib.gamesStorage().games[gameId];
        game.changeState(DataTypes.State.OPEN);
        game.setBettingDeadline(bettingDeadline);
        emit GameBettingDeadlineUpdated(gameId, bettingDeadline);
    }

    function foreCloseGame(string memory gameIdStr) external onlyOperator {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.Game storage game = GameLib.gamesStorage().games[gameId];
        game.changeState(DataTypes.State.CLOSED);
        emit GameClosed(gameId);
    }

    function setResult(
        string memory gameIdStr,
        uint8 result
    ) external onlyOperator {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.Game storage game = GameLib.gamesStorage().games[gameId];
        game.setResult(result);
        emit GameResultSet(gameId, result);
    }

    function getGameDetails(
        string memory gameIdStr
    )
        external
        view
        returns (
            uint8 totalOutcome,
            DataTypes.State state,
            uint256 bettingDeadline,
            uint8 result,
            uint256[] memory betAmounts
        )
    {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.GamesStorage storage gss = GameLib.gamesStorage();
        DataTypes.Game storage game = gss.games[gameId];
        uint8 gameTotalOutcome = game.getTotalOutcome();

        uint256[] memory betAmountsArray = new uint256[](gameTotalOutcome);
        for (uint8 i = 0; i < gameTotalOutcome; i++) {
            betAmountsArray[i] = game.outcomes[i].totalBetAmount;
        }

        return (
            game.getTotalOutcome(),
            game.state,
            game.getBettingDeadline(),
            game.result,
            betAmountsArray
        );
    }

    function finalizeGame(string memory gameIdStr) external onlyOperator {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.GamesStorage storage gss = GameLib.gamesStorage();

        DataTypes.Game storage game = gss.games[gameId];
        game.enforceGameSettled();

        uint8 result = game.result;
        uint256 totalBetAmount = game.totalBetForGame();
        uint256 totalBetAmountOnWinOutcome = game
            .outcomes[result]
            .totalBetAmount;

        uint256 gameFee;

        if (totalBetAmountOnWinOutcome > 0) {
            for (uint256 i = 0; i < game.outcomes[result].players.length; i++) {
                address player = game.outcomes[result].players[i];

                uint256 winnings = (game.outcomes[result].playerBets[player] *
                    totalBetAmount) / totalBetAmountOnWinOutcome;

                uint256 fee = (winnings * platformFeeRate()) / 1000;

                gameFee += fee;

                uint256 afterFee = winnings - fee;

                UserLib.adjustUserBalance(player, afterFee, true);
            }
        } else {
            gameFee += totalBetAmount;
        }

        gss.unCollectedFee = gameFee;

        game.changeState(DataTypes.State.FINALIZED);
        emit GameFinalized(gameId);
    }

    function getUserBetsForGame(
        string memory gameIdStr,
        address user
    ) external view returns (uint256[] memory bets, uint256 winningAmount) {
        bytes32 gameId = stringToBytes32(gameIdStr);
        DataTypes.GamesStorage storage gss = GameLib.gamesStorage();
        DataTypes.Game storage game = gss.games[gameId];

        uint8 gameTotalOutcome = game.getTotalOutcome();

        uint256[] memory userBets = new uint256[](gameTotalOutcome);
        for (uint8 i = 0; i < gameTotalOutcome; i++) {
            userBets[i] = game.outcomes[i].playerBets[user];
        }

        uint256 userBetOnWinningOutcome = game.outcomes[game.result].playerBets[
            user
        ];
        uint256 totalBetAmount = game.totalBetForGame();
        uint256 totalBetAmountOnWinOutcome = game
            .outcomes[game.result]
            .totalBetAmount;

        if (
            game.state == DataTypes.State.SETTLED &&
            totalBetAmountOnWinOutcome > 0
        ) {
            winningAmount =
                (userBetOnWinningOutcome * totalBetAmount) /
                totalBetAmountOnWinOutcome;
        } else {
            winningAmount = 0;
        }

        return (userBets, winningAmount);
    }

    function stringToBytes32(
        string memory source
    ) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}