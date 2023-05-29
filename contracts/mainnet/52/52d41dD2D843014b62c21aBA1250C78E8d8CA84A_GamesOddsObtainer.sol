// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-4.4.1/utils/Strings.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// interface
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/ITherundownConsumerVerifier.sol";
import "../../interfaces/ITherundownConsumer.sol";
import "../../interfaces/IGamesOddsObtainer.sol";

/// @title Contract, which works on odds obtain
/// @author gruja
contract GamesOddsObtainer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */
    uint public constant MIN_TAG_NUMBER = 9000;
    uint public constant TAG_NUMBER_SPREAD = 10001;
    uint public constant TAG_NUMBER_TOTAL = 10002;
    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;

    /* ========== CONSUMER STATE VARIABLES ========== */

    ITherundownConsumer public consumer;
    ITherundownConsumerVerifier public verifier;
    ISportPositionalMarketManager public sportsManager;

    // game properties
    mapping(bytes32 => IGamesOddsObtainer.GameOdds) public gameOdds;
    mapping(bytes32 => IGamesOddsObtainer.GameOdds) public backupOdds;
    mapping(address => bool) public invalidOdds;
    mapping(bytes32 => uint) public oddsLastPulledForGame;
    mapping(address => bytes32) public gameIdPerChildMarket;
    mapping(uint => bool) public doesSportSupportSpreadAndTotal;

    // market props
    mapping(address => mapping(uint => address)) public mainMarketChildMarketIndex;
    mapping(address => uint) public numberOfChildMarkets;
    mapping(address => mapping(int16 => address)) public mainMarketSpreadChildMarket;
    mapping(address => mapping(uint24 => address)) public mainMarketTotalChildMarket;
    mapping(address => address) public childMarketMainMarket;
    mapping(address => int16) public childMarketSread;
    mapping(address => uint24) public childMarketTotal;
    mapping(address => address) public currentActiveTotalChildMarket;
    mapping(address => address) public currentActiveSpreadChildMarket;
    mapping(address => bool) public isSpreadChildMarket;
    mapping(address => bool) public childMarketCreated;
    mapping(address => bool) public normalizedOddsForMarketFulfilled;
    mapping(address => uint[]) public normalizedOddsForMarket;
    address public oddsReceiver;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _consumer,
        address _verifier,
        address _sportsManager,
        uint[] memory _supportedSportIds
    ) external initializer {
        setOwner(_owner);
        consumer = ITherundownConsumer(_consumer);
        verifier = ITherundownConsumerVerifier(_verifier);
        sportsManager = ISportPositionalMarketManager(_sportsManager);

        for (uint i; i < _supportedSportIds.length; i++) {
            doesSportSupportSpreadAndTotal[_supportedSportIds[i]] = true;
        }
    }

    /* ========== OBTAINER MAIN FUNCTIONS ========== */

    /// @notice main function for odds obtaining
    /// @param requestId chainlnink request ID
    /// @param _game game odds struct see @ IGamesOddsObtainer.GameOdds
    function obtainOdds(
        bytes32 requestId,
        IGamesOddsObtainer.GameOdds memory _game,
        uint _sportId
    ) external canUpdateOdds {
        if (_areOddsValid(_game)) {
            uint[] memory currentNormalizedOdd = getNormalizedOdds(_game.gameId);
            IGamesOddsObtainer.GameOdds memory currentOddsBeforeSave = gameOdds[_game.gameId];
            gameOdds[_game.gameId] = _game;
            oddsLastPulledForGame[_game.gameId] = block.timestamp;

            address _main = consumer.marketPerGameId(_game.gameId);
            _setNormalizedOdds(_main, _game.gameId, true);
            if (doesSportSupportSpreadAndTotal[_sportId]) {
                _obtainTotalAndSpreadOdds(_game, _main);
            }

            // if was paused and paused by invalid odds unpause
            if (sportsManager.isMarketPaused(_main)) {
                if (invalidOdds[_main] || consumer.isPausedByCanceledStatus(_main)) {
                    invalidOdds[_main] = false;
                    consumer.setPausedByCanceledStatus(_main, false);
                    if (
                        !verifier.areOddsArrayInThreshold(
                            _sportId,
                            currentNormalizedOdd,
                            normalizedOddsForMarket[_main],
                            consumer.isSportTwoPositionsSport(_sportId)
                        )
                    ) {
                        backupOdds[_game.gameId] = currentOddsBeforeSave;
                        emit OddsCircuitBreaker(_main, _game.gameId);
                    } else {
                        _pauseOrUnpauseMarkets(_game, _main, false, true);
                    }
                }
            } else if (
                //if market is not paused but odd are not in threshold, pause parket
                !sportsManager.isMarketPaused(_main) &&
                !verifier.areOddsArrayInThreshold(
                    _sportId,
                    currentNormalizedOdd,
                    normalizedOddsForMarket[_main],
                    consumer.isSportTwoPositionsSport(_sportId)
                )
            ) {
                _pauseOrUnpauseMarkets(_game, _main, true, true);
                backupOdds[_game.gameId] = currentOddsBeforeSave;
                emit OddsCircuitBreaker(_main, _game.gameId);
            }
            emit GameOddsAdded(requestId, _game.gameId, _game, normalizedOddsForMarket[_main]);
        } else {
            address _main = consumer.marketPerGameId(_game.gameId);
            if (!sportsManager.isMarketPaused(_main)) {
                invalidOdds[_main] = true;
                _pauseOrUnpauseMarkets(_game, _main, true, true);
            }

            emit InvalidOddsForMarket(requestId, _main, _game.gameId, _game);
        }
    }

    /// @notice set first odds on creation
    /// @param _gameId game id
    /// @param _homeOdds home odds for a game
    /// @param _awayOdds away odds for a game
    /// @param _drawOdds draw odds for a game
    function setFirstOdds(
        bytes32 _gameId,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external onlyConsumer {
        gameOdds[_gameId] = IGamesOddsObtainer.GameOdds(_gameId, _homeOdds, _awayOdds, _drawOdds, 0, 0, 0, 0, 0, 0, 0, 0);
        oddsLastPulledForGame[_gameId] = block.timestamp;
    }

    /// @notice set first odds on creation market
    /// @param _gameId game id
    /// @param _market market
    function setFirstNormalizedOdds(bytes32 _gameId, address _market) external onlyConsumer {
        _setNormalizedOdds(_market, _gameId, true);
    }

    /// @notice set backup odds to be main odds
    /// @param _gameId game id which is using backup odds
    function setBackupOddsAsMainOddsForGame(bytes32 _gameId) external onlyConsumer {
        gameOdds[_gameId] = backupOdds[_gameId];
        address _main = consumer.marketPerGameId(_gameId);
        _setNormalizedOdds(_main, _gameId, true);
        emit GameOddsAdded(
            _gameId, // // no req. from CL (manual cancel) so just put gameID
            _gameId,
            gameOdds[_gameId],
            normalizedOddsForMarket[_main]
        );
    }

    /// @notice pause/unpause all child markets
    /// @param _main parent market for which we are pause/unpause child markets
    /// @param _flag pause -> true, unpause -> false
    function pauseUnpauseChildMarkets(address _main, bool _flag) external onlyConsumer {
        // number of childs more then 0
        for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
            consumer.pauseOrUnpauseMarket(mainMarketChildMarketIndex[_main][i], _flag);
        }
    }

    /// @notice pause/unpause current active child markets
    /// @param _gameId game id for spread and totals checking
    /// @param _main parent market for which we are pause/unpause child markets
    /// @param _flag pause -> true, unpause -> false
    function pauseUnpauseCurrentActiveChildMarket(
        bytes32 _gameId,
        address _main,
        bool _flag
    ) external onlyConsumer {
        _pauseOrUnpauseMarkets(gameOdds[_gameId], _main, _flag, true);
    }

    function setChildMarketGameId(bytes32 gameId, address market) external onlyManager {
        consumer.setGameIdPerChildMarket(gameId, market);
    }

    /// @notice resolve all child markets
    /// @param _main parent market for which we are resolving
    /// @param _outcome poitions thet is winning (homw, away, cancel)
    /// @param _homeScore points that home team score
    /// @param _awayScore points that away team score
    function resolveChildMarkets(
        address _main,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external onlyConsumer {
        for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
            address child = mainMarketChildMarketIndex[_main][i];
            if (_outcome == CANCELLED) {
                sportsManager.resolveMarket(child, _outcome);
            } else if (isSpreadChildMarket[child]) {
                _resolveMarketSpread(child, uint16(_homeScore), uint16(_awayScore));
            } else {
                _resolveMarketTotal(child, uint24(_homeScore), uint24(_awayScore));
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _gameId game id for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOdds(bytes32 _gameId) public view returns (uint[] memory) {
        address market = consumer.marketPerGameId(_gameId);
        return
            normalizedOddsForMarketFulfilled[market]
                ? normalizedOddsForMarket[market]
                : getNormalizedOddsFromGameOddsStruct(_gameId);
    }

    /// @notice view function which returns normalized odds (spread or total) up to 100 (Example: 55-45)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedChildOdds(address _market) public view returns (uint[] memory) {
        return
            normalizedOddsForMarketFulfilled[_market]
                ? normalizedOddsForMarket[_market]
                : getNormalizedChildOddsFromGameOddsStruct(_market);
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-50)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedOddsForMarket(address _market) public view returns (uint[] memory) {
        return getNormalizedChildOdds(_market);
    }

    /// @param _gameId game id for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOddsFromGameOddsStruct(bytes32 _gameId) public view returns (uint[] memory) {
        int[] memory odds = new int[](3);
        odds[0] = gameOdds[_gameId].homeOdds;
        odds[1] = gameOdds[_gameId].awayOdds;
        odds[2] = gameOdds[_gameId].drawOdds;
        return verifier.calculateAndNormalizeOdds(odds);
    }

    /// @notice view function which returns normalized odds (spread or total) up to 100 (Example: 55-45)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedChildOddsFromGameOddsStruct(address _market) public view returns (uint[] memory) {
        bytes32 gameId = gameIdPerChildMarket[_market];
        int[] memory odds = new int[](2);
        odds[0] = isSpreadChildMarket[_market] ? gameOdds[gameId].spreadHomeOdds : gameOdds[gameId].totalOverOdds;
        odds[1] = isSpreadChildMarket[_market] ? gameOdds[gameId].spreadAwayOdds : gameOdds[gameId].totalUnderOdds;
        return verifier.calculateAndNormalizeOdds(odds);
    }

    /// @notice function which retrievers all markert addresses for given parent market
    /// @param _parent parent market
    /// @return address[] child addresses
    function getAllChildMarketsFromParent(address _parent) external view returns (address[] memory) {
        address[] memory allMarkets = new address[](numberOfChildMarkets[_parent]);
        for (uint i = 0; i < numberOfChildMarkets[_parent]; i++) {
            allMarkets[i] = mainMarketChildMarketIndex[_parent][i];
        }
        return allMarkets;
    }

    /// @notice function which retrievers all markert addresses for given parent market
    /// @param _parent parent market
    /// @return totalsMarket totals child address
    /// @return spreadsMarket spread child address
    function getActiveChildMarketsFromParent(address _parent)
        external
        view
        returns (address totalsMarket, address spreadsMarket)
    {
        totalsMarket = currentActiveTotalChildMarket[_parent];
        spreadsMarket = currentActiveSpreadChildMarket[_parent];
    }

    /// @notice are odds valid or not
    /// @param _gameId game id for which game is looking
    /// @param _useBackup see if looking at backupOdds
    /// @return bool true/false (valid or not)
    function areOddsValid(bytes32 _gameId, bool _useBackup) external view returns (bool) {
        return _useBackup ? _areOddsValid(backupOdds[_gameId]) : _areOddsValid(gameOdds[_gameId]);
    }

    /// @notice view function which returns odds
    /// @param _gameId game id
    /// @return spreadHome points difference between home and away
    /// @return spreadAway  points difference between home and away
    /// @return totalOver  points total in a game over limit
    /// @return totalUnder  points total in game under limit
    function getLinesForGame(bytes32 _gameId)
        public
        view
        returns (
            int16,
            int16,
            uint24,
            uint24
        )
    {
        return (
            gameOdds[_gameId].spreadHome,
            gameOdds[_gameId].spreadAway,
            gameOdds[_gameId].totalOver,
            gameOdds[_gameId].totalUnder
        );
    }

    /// @notice view function which returns odds
    /// @param _gameId game id
    /// @return homeOdds moneyline odd in a two decimal places
    /// @return awayOdds moneyline odd in a two decimal places
    /// @return drawOdds moneyline odd in a two decimal places
    /// @return spreadHomeOdds moneyline odd in a two decimal places
    /// @return spreadAwayOdds moneyline odd in a two decimal places
    /// @return totalOverOdds moneyline odd in a two decimal places
    /// @return totalUnderOdds moneyline odd in a two decimal places
    function getOddsForGame(bytes32 _gameId)
        public
        view
        returns (
            int24,
            int24,
            int24,
            int24,
            int24,
            int24,
            int24
        )
    {
        return (
            gameOdds[_gameId].homeOdds,
            gameOdds[_gameId].awayOdds,
            gameOdds[_gameId].drawOdds,
            gameOdds[_gameId].spreadHomeOdds,
            gameOdds[_gameId].spreadAwayOdds,
            gameOdds[_gameId].totalOverOdds,
            gameOdds[_gameId].totalUnderOdds
        );
    }

    /* ========== INTERNALS ========== */

    function _areOddsValid(IGamesOddsObtainer.GameOdds memory _game) internal view returns (bool) {
        return
            verifier.areOddsValid(
                consumer.isSportTwoPositionsSport(consumer.sportsIdPerGame(_game.gameId)),
                _game.homeOdds,
                _game.awayOdds,
                _game.drawOdds
            );
    }

    function _obtainTotalAndSpreadOdds(IGamesOddsObtainer.GameOdds memory _game, address _main) internal {
        if (_areTotalOddsValid(_game)) {
            _obtainSpreadTotal(_game, _main, false);
            emit GamedOddsAddedChild(
                _game.gameId,
                currentActiveTotalChildMarket[_main],
                _game,
                getNormalizedChildOdds(currentActiveTotalChildMarket[_main]),
                TAG_NUMBER_TOTAL
            );
        } else {
            _pauseTotalSpreadMarkets(_game, false);
        }
        if (_areSpreadOddsValid(_game)) {
            _obtainSpreadTotal(_game, _main, true);
            emit GamedOddsAddedChild(
                _game.gameId,
                currentActiveSpreadChildMarket[_main],
                _game,
                getNormalizedChildOdds(currentActiveSpreadChildMarket[_main]),
                TAG_NUMBER_SPREAD
            );
        } else {
            _pauseTotalSpreadMarkets(_game, true);
        }
    }

    function _areTotalOddsValid(IGamesOddsObtainer.GameOdds memory _game) internal view returns (bool) {
        return verifier.areTotalOddsValid(_game.totalOver, _game.totalOverOdds, _game.totalUnder, _game.totalUnderOdds);
    }

    function _areSpreadOddsValid(IGamesOddsObtainer.GameOdds memory _game) internal view returns (bool) {
        return verifier.areSpreadOddsValid(_game.spreadHome, _game.spreadHomeOdds, _game.spreadAway, _game.spreadAwayOdds);
    }

    function _obtainSpreadTotal(
        IGamesOddsObtainer.GameOdds memory _game,
        address _main,
        bool _isSpread
    ) internal {
        bool isNewMarket = numberOfChildMarkets[_main] == 0;

        address currentActiveChildMarket = _isSpread
            ? currentActiveSpreadChildMarket[_main]
            : currentActiveTotalChildMarket[_main];

        address currentMarket = _isSpread
            ? mainMarketSpreadChildMarket[_main][_game.spreadHome]
            : mainMarketTotalChildMarket[_main][_game.totalOver];

        if (isNewMarket || currentMarket == address(0)) {
            address newMarket = _createMarketSpreadTotalMarket(
                _game.gameId,
                _main,
                _isSpread,
                _game.spreadHome,
                _game.totalOver
            );

            _setCurrentChildMarkets(_main, newMarket, _isSpread);

            if (currentActiveChildMarket != address(0)) {
                consumer.pauseOrUnpauseMarket(currentActiveChildMarket, true);
            }
            _setNormalizedOdds(newMarket, _game.gameId, false);
        } else if (currentMarket != currentActiveChildMarket) {
            consumer.pauseOrUnpauseMarket(currentMarket, false);
            consumer.pauseOrUnpauseMarket(currentActiveChildMarket, true);
            _setCurrentChildMarkets(_main, currentMarket, _isSpread);
            _setNormalizedOdds(currentMarket, _game.gameId, false);
        } else {
            consumer.pauseOrUnpauseMarket(currentActiveChildMarket, false);
            _setNormalizedOdds(currentActiveChildMarket, _game.gameId, false);
        }
    }

    function _setNormalizedOdds(
        address _market,
        bytes32 _gameId,
        bool _isParent
    ) internal {
        normalizedOddsForMarket[_market] = _isParent
            ? getNormalizedOddsFromGameOddsStruct(_gameId)
            : getNormalizedChildOddsFromGameOddsStruct(_market);
        normalizedOddsForMarketFulfilled[_market] = true;
    }

    function _createMarketSpreadTotalMarket(
        bytes32 _gameId,
        address _mainMarket,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) internal returns (address _childMarket) {
        // create
        uint[] memory tags = _calculateTags(consumer.sportsIdPerGame(_gameId), _isSpread);
        sportsManager.createMarket(
            _gameId,
            _append(_gameId, _isSpread, _spreadHome, _totalOver), // gameLabel
            consumer.getGameCreatedById(_gameId).startTime, //maturity
            0, //initialMint
            2, // always two positions for spread/total
            tags, //tags
            true, // is child
            _mainMarket
        );

        _childMarket = sportsManager.getActiveMarketAddress(sportsManager.numActiveMarkets() - 1);

        // adding child markets
        _setChildMarkets(_gameId, _mainMarket, _childMarket, _isSpread, _spreadHome, _totalOver, tags[1]);
    }

    function _calculateTags(uint _sportsId, bool _isSpread) internal pure returns (uint[] memory) {
        uint[] memory result = new uint[](2);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        result[1] = _isSpread ? TAG_NUMBER_SPREAD : TAG_NUMBER_TOTAL;
        return result;
    }

    function _append(
        bytes32 _gameId,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) internal view returns (string memory) {
        string memory teamVsTeam = string(
            abi.encodePacked(
                consumer.getGameCreatedById(_gameId).homeTeam,
                " vs ",
                consumer.getGameCreatedById(_gameId).awayTeam
            )
        );
        if (_isSpread) {
            return string(abi.encodePacked(teamVsTeam, "(", _parseSpread(_spreadHome), ")"));
        } else {
            return string(abi.encodePacked(teamVsTeam, " - ", Strings.toString(_totalOver)));
        }
    }

    function _parseSpread(int16 _spreadHome) internal pure returns (string memory) {
        return
            _spreadHome > 0
                ? Strings.toString(uint16(_spreadHome))
                : string(abi.encodePacked("-", Strings.toString(uint16(_spreadHome * (-1)))));
    }

    function _pauseOrUnpauseMarkets(
        IGamesOddsObtainer.GameOdds memory _game,
        address _main,
        bool _flag,
        bool _unpauseMain
    ) internal {
        if (_unpauseMain) {
            consumer.pauseOrUnpauseMarket(_main, _flag);
        }

        if (numberOfChildMarkets[_main] > 0) {
            if (_flag) {
                for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
                    consumer.pauseOrUnpauseMarket(mainMarketChildMarketIndex[_main][i], _flag);
                }
            } else {
                if (_areTotalOddsValid(_game)) {
                    address totalChildMarket = mainMarketTotalChildMarket[_main][_game.totalOver];
                    if (totalChildMarket == address(0)) {
                        address newMarket = _createMarketSpreadTotalMarket(
                            _game.gameId,
                            _main,
                            false,
                            _game.spreadHome,
                            _game.totalOver
                        );
                        _setCurrentChildMarkets(_main, newMarket, false);
                    } else {
                        consumer.pauseOrUnpauseMarket(totalChildMarket, _flag);
                        _setCurrentChildMarkets(_main, totalChildMarket, false);
                    }
                }
                if (_areSpreadOddsValid(_game)) {
                    address spreadChildMarket = mainMarketSpreadChildMarket[_main][_game.spreadHome];
                    if (spreadChildMarket == address(0)) {
                        address newMarket = _createMarketSpreadTotalMarket(
                            _game.gameId,
                            _main,
                            true,
                            _game.spreadHome,
                            _game.totalOver
                        );
                        _setCurrentChildMarkets(_main, newMarket, true);
                    } else {
                        consumer.pauseOrUnpauseMarket(spreadChildMarket, _flag);
                        _setCurrentChildMarkets(_main, spreadChildMarket, true);
                    }
                }
            }
        }
    }

    function _pauseTotalSpreadMarkets(IGamesOddsObtainer.GameOdds memory _game, bool _isSpread) internal {
        address _main = consumer.marketPerGameId(_game.gameId);
        // in number of childs more then 0
        if (numberOfChildMarkets[_main] > 0) {
            for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
                address _child = mainMarketChildMarketIndex[_main][i];
                if (isSpreadChildMarket[_child] == _isSpread) {
                    consumer.pauseOrUnpauseMarket(_child, true);
                }
            }
        }
    }

    function _setCurrentChildMarkets(
        address _main,
        address _child,
        bool _isSpread
    ) internal {
        if (_isSpread) {
            currentActiveSpreadChildMarket[_main] = _child;
        } else {
            currentActiveTotalChildMarket[_main] = _child;
        }
    }

    function _setChildMarkets(
        bytes32 _gameId,
        address _main,
        address _child,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver,
        uint _type
    ) internal {
        consumer.setGameIdPerChildMarket(_gameId, _child);
        gameIdPerChildMarket[_child] = _gameId;
        childMarketCreated[_child] = true;
        // adding child markets
        childMarketMainMarket[_child] = _main;
        mainMarketChildMarketIndex[_main][numberOfChildMarkets[_main]] = _child;
        numberOfChildMarkets[_main] = numberOfChildMarkets[_main] + 1;
        if (_isSpread) {
            mainMarketSpreadChildMarket[_main][_spreadHome] = _child;
            childMarketSread[_child] = _spreadHome;
            currentActiveSpreadChildMarket[_main] = _child;
            isSpreadChildMarket[_child] = true;
            emit CreateChildSpreadSportsMarket(_main, _child, _gameId, _spreadHome, getNormalizedChildOdds(_child), _type);
        } else {
            mainMarketTotalChildMarket[_main][_totalOver] = _child;
            childMarketTotal[_child] = _totalOver;
            currentActiveTotalChildMarket[_main] = _child;
            emit CreateChildTotalSportsMarket(_main, _child, _gameId, _totalOver, getNormalizedChildOdds(_child), _type);
        }
    }

    function _resolveMarketTotal(
        address _child,
        uint24 _homeScore,
        uint24 _awayScore
    ) internal {
        uint24 totalLine = childMarketTotal[_child];

        uint outcome = (_homeScore + _awayScore) * 100 > totalLine ? HOME_WIN : (_homeScore + _awayScore) * 100 < totalLine
            ? AWAY_WIN
            : CANCELLED;

        sportsManager.resolveMarket(_child, outcome);
        emit ResolveChildMarket(_child, outcome, childMarketMainMarket[_child], _homeScore, _awayScore);
    }

    function _resolveMarketSpread(
        address _child,
        uint16 _homeScore,
        uint16 _awayScore
    ) internal {
        int16 homeScoreWithSpread = int16(_homeScore) * 100 + childMarketSread[_child];
        int16 newAwayScore = int16(_awayScore) * 100;

        uint outcome = homeScoreWithSpread > newAwayScore ? HOME_WIN : homeScoreWithSpread < newAwayScore
            ? AWAY_WIN
            : CANCELLED;
        sportsManager.resolveMarket(_child, outcome);
        emit ResolveChildMarket(_child, outcome, childMarketMainMarket[_child], uint24(_homeScore), uint24(_awayScore));
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets consumer, verifier, manager address
    /// @param _consumer consumer address
    /// @param _verifier verifier address
    /// @param _sportsManager sport manager address
    function setContracts(
        address _consumer,
        address _verifier,
        address _sportsManager,
        address _receiver
    ) external onlyOwner {
        consumer = ITherundownConsumer(_consumer);
        verifier = ITherundownConsumerVerifier(_verifier);
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        oddsReceiver = _receiver;

        emit NewContractAddresses(_consumer, _verifier, _sportsManager, _receiver);
    }

    /// @notice sets if sport is suported or not (delete from supported sport)
    /// @param _sportId sport id which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedSportForTotalAndSpread(uint _sportId, bool _isSupported) external onlyOwner {
        doesSportSupportSpreadAndTotal[_sportId] = _isSupported;
        emit SupportedSportForTotalAndSpreadAdded(_sportId, _isSupported);
    }

    /* ========== MODIFIERS ========== */

    modifier canUpdateOdds() {
        require(msg.sender == address(consumer) || msg.sender == oddsReceiver, "Invalid sender");
        _;
    }

    modifier onlyConsumer() {
        require(msg.sender == address(consumer), "Only consumer");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == address(sportsManager), "Only manager");
        _;
    }

    /* ========== EVENTS ========== */

    event GameOddsAdded(bytes32 _requestId, bytes32 _id, IGamesOddsObtainer.GameOdds _game, uint[] _normalizedOdds);
    event GamedOddsAddedChild(
        bytes32 _id,
        address _market,
        IGamesOddsObtainer.GameOdds _game,
        uint[] _normalizedChildOdds,
        uint _type
    );
    event InvalidOddsForMarket(bytes32 _requestId, address _marketAddress, bytes32 _id, IGamesOddsObtainer.GameOdds _game);
    event OddsCircuitBreaker(address _marketAddress, bytes32 _id);
    event NewContractAddresses(address _consumer, address _verifier, address _sportsManager, address _receiver);
    event CreateChildSpreadSportsMarket(
        address _main,
        address _child,
        bytes32 _id,
        int16 _spread,
        uint[] _normalizedOdds,
        uint _type
    );
    event CreateChildTotalSportsMarket(
        address _main,
        address _child,
        bytes32 _id,
        uint24 _total,
        uint[] _normalizedOdds,
        uint _type
    );
    event SupportedSportForTotalAndSpreadAdded(uint _sportId, bool _isSupported);
    event ResolveChildMarket(address _child, uint _outcome, address _main, uint24 _homeScore, uint24 _awayScore);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISportPositionalMarket.sol";

interface ISportPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function marketCreationEnabled() external view returns (bool);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isDoubleChanceMarket(address candidate) external view returns (bool);

    function isDoubleChanceSupported() external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getActiveMarketAddress(uint _index) external view returns (address);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function isMarketPaused(address _market) external view returns (bool);

    function expiryDuration() external view returns (uint);

    function isWhitelistedAddress(address _address) external view returns (bool);

    function getOddsObtainer() external view returns (address obtainer);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags,
        bool isChild,
        address parentMarket
    ) external returns (ISportPositionalMarket);

    function setMarketPaused(address _market, bool _paused) external;

    function updateDatesForMarket(address _market, uint256 _newStartTime) external;

    function resolveMarket(address market, uint outcome) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITherundownConsumerVerifier {
    // view functions
    function isInvalidNames(string memory _teamA, string memory _teamB) external view returns (bool);

    function areTeamsEqual(string memory _teamA, string memory _teamB) external view returns (bool);

    function isSupportedMarketType(string memory _market) external view returns (bool);

    function areOddsArrayInThreshold(
        uint _sportId,
        uint[] memory _currentOddsArray,
        uint[] memory _newOddsArray,
        bool _isTwoPositionalSport
    ) external view returns (bool);

    function areOddsValid(
        bool _isTwoPositionalSport,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external view returns (bool);

    function areSpreadOddsValid(
        int16 spreadHome,
        int24 spreadHomeOdds,
        int16 spreadAway,
        int24 spreadAwayOdds
    ) external view returns (bool);

    function areTotalOddsValid(
        uint24 totalOver,
        int24 totalOverOdds,
        uint24 totalUnder,
        int24 totalUnderOdds
    ) external view returns (bool);

    function isValidOutcomeForGame(bool _isTwoPositionalSport, uint _outcome) external view returns (bool);

    function isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) external view returns (bool);

    function calculateAndNormalizeOdds(int[] memory _americanOdds) external view returns (uint[] memory);

    function getBookmakerIdsBySportId(uint256 _sportId) external view returns (uint256[] memory);

    function getStringIDsFromBytesArrayIDs(bytes32[] memory _ids) external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITherundownConsumer {
    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    // view functions
    function supportedSport(uint _sportId) external view returns (bool);

    function getNormalizedOdds(bytes32 _gameId) external view returns (uint[] memory);

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function getNormalizedChildOdds(address _market) external view returns (uint[] memory);

    function getNormalizedOddsForTwoPosition(bytes32 _gameId) external view returns (uint[] memory);

    function getGamesPerDatePerSport(uint _sportId, uint _date) external view returns (bytes32[] memory);

    function getGamePropsForOdds(address _market)
        external
        view
        returns (
            uint,
            uint,
            bytes32
        );

    function gameIdPerMarket(address _market) external view returns (bytes32);

    function getGameCreatedById(bytes32 _gameId) external view returns (GameCreate memory);

    function isChildMarket(address _market) external view returns (bool);

    function gameFulfilledCreated(bytes32 _gameId) external view returns (bool);

    // write functions
    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportsId,
        uint _date
    ) external;

    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportsId
    ) external;

    function fulfillGamesOdds(bytes32 _requestId, bytes[] memory _games) external;

    function setPausedByCanceledStatus(address _market, bool _flag) external;

    function setGameIdPerChildMarket(bytes32 _gameId, address _child) external;

    function pauseOrUnpauseMarket(address _market, bool _pause) external;

    function setChildMarkets(
        bytes32 _gameId,
        address _main,
        address _child,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) external;

    function resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _usebackupOdds
    ) external;

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24
        );

    function sportsIdPerGame(bytes32 _gameId) external view returns (uint);

    function getGameStartTime(bytes32 _gameId) external view returns (uint256);

    function marketPerGameId(bytes32 _gameId) external view returns (address);

    function marketResolved(address _market) external view returns (bool);

    function marketCanceled(address _market) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function isPausedByCanceledStatus(address _market) external view returns (bool);

    function isSportOnADate(uint _date, uint _sportId) external view returns (bool);

    function isSportTwoPositionsSport(uint _sportsId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGamesOddsObtainer {
    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        int16 spreadHome;
        int24 spreadHomeOdds;
        int16 spreadAway;
        int24 spreadAwayOdds;
        uint24 totalOver;
        int24 totalOverOdds;
        uint24 totalUnder;
        int24 totalUnderOdds;
    }

    // view

    function getActiveChildMarketsFromParent(address _parent) external view returns (address, address);

    function getSpreadTotalsChildMarketsFromParent(address _parent)
        external
        view
        returns (
            uint numOfSpreadMarkets,
            address[] memory spreadMarkets,
            uint numOfTotalsMarkets,
            address[] memory totalMarkets
        );

    function areOddsValid(bytes32 _gameId, bool _useBackup) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function getNormalizedOdds(bytes32 _gameId) external view returns (uint[] memory);

    function getNormalizedChildOdds(address _market) external view returns (uint[] memory);

    function getOddsForGames(bytes32[] memory _gameIds) external view returns (int24[] memory odds);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function mainMarketSpreadChildMarket(address _main, int16 _spread) external view returns (address);

    function mainMarketTotalChildMarket(address _main, uint24 _total) external view returns (address);

    function childMarketMainMarket(address _market) external view returns (address);

    function currentActiveTotalChildMarket(address _main) external view returns (address);

    function currentActiveSpreadChildMarket(address _main) external view returns (address);

    function isSpreadChildMarket(address _child) external view returns (bool);

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24,
            int24,
            int24,
            int24,
            int24
        );

    function getLinesForGame(bytes32 _gameId)
        external
        view
        returns (
            int16,
            int16,
            uint24,
            uint24
        );

    // executable

    function obtainOdds(
        bytes32 requestId,
        GameOdds memory _game,
        uint _sportId
    ) external;

    function setFirstOdds(
        bytes32 _gameId,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external;

    function setFirstNormalizedOdds(bytes32 _gameId, address _market) external;

    function setBackupOddsAsMainOddsForGame(bytes32 _gameId) external;

    function pauseUnpauseChildMarkets(address _main, bool _flag) external;

    function pauseUnpauseCurrentActiveChildMarket(
        bytes32 _gameId,
        address _main,
        bool _flag
    ) external;

    function resolveChildMarkets(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external;

    function setChildMarketGameId(bytes32 gameId, address market) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Cancelled,
        Home,
        Away,
        Draw
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function initialMint() external view returns (uint);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function isChild() external view returns (bool);

    function tags(uint idx) external view returns (uint);

    function getTags() external view returns (uint tag1, uint tag2);

    function getParentMarketPositions() external view returns (IPosition position1, IPosition position2);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function isDoubleChance() external view returns (bool);

    function parentMarket() external view returns (ISportPositionalMarket);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function updateDates(uint256 _maturity, uint256 _expiry) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}