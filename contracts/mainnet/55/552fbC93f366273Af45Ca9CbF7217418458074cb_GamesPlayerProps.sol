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
import "../../interfaces/IGamesPlayerProps.sol";

/// @title Contract, which works on player props
/// @author gruja
contract GamesPlayerProps is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */
    uint public constant MIN_TAG_NUMBER = 9000;
    uint public constant TAG_NUMBER_PLAYERS = 10010;
    uint public constant TAG_NUMBER_PLAYER_PROPS = 11000;
    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;
    uint public constant CANCELLED_STATUS = 255;

    /* ========== CONSUMER STATE VARIABLES ========== */

    ITherundownConsumer public consumer;
    ITherundownConsumerVerifier public verifier;
    ISportPositionalMarketManager public sportsManager;
    address public playerPropsReceiver;

    // game properties
    mapping(bytes32 => mapping(bytes32 => mapping(uint8 => IGamesPlayerProps.PlayerProps))) public playerProp;
    mapping(uint => bool) public doesSportSupportPlayerProps;
    mapping(address => bytes32) public gameIdPerChildMarket;
    mapping(address => bytes32) public playerIdPerChildMarket;
    mapping(address => uint8) public optionIdPerChildMarket;

    // market props
    mapping(address => mapping(uint => address)) public mainMarketChildMarketIndex;
    mapping(address => bool) public mainMarketPausedPlayerProps;
    mapping(address => uint) public numberOfChildMarkets;
    mapping(address => mapping(bytes32 => mapping(uint8 => mapping(uint => address))))
        public mainMarketChildMarketPerPlayerAndOptionIndex;
    mapping(address => mapping(bytes32 => mapping(uint8 => uint))) public numberOfChildMarketsPerPlayerAndOption;
    mapping(address => mapping(bytes32 => mapping(uint8 => mapping(uint16 => address))))
        public mainMarketPlayerOptionLineChildMarket;
    mapping(address => address) public childMarketMainMarket;
    mapping(address => mapping(bytes32 => mapping(uint8 => address))) public currentActiveChildMarketPerPlayerAndOption;
    mapping(address => uint[]) public normalizedOddsForMarket;
    mapping(address => bool) public normalizedOddsForMarketFulfilled;
    mapping(address => bool) public childMarketCreated;
    mapping(address => uint16) public childMarketLine;
    mapping(bytes32 => mapping(bytes32 => mapping(uint8 => bool))) public invalidOddsForPlayerProps;
    mapping(bytes32 => mapping(bytes32 => mapping(uint8 => bool))) public createFulfilledForPlayerProps;
    mapping(bytes32 => mapping(bytes32 => mapping(uint8 => bool))) public resolveFulfilledForPlayerProps;
    mapping(address => bool) public pausedByInvalidOddsOnMain;
    mapping(address => bool) public pausedByCircuitBreakerOnMain;
    mapping(address => bool) public playerPropsAddedForMain;

    mapping(bytes32 => bytes32[]) public playersInAGame;
    mapping(bytes32 => mapping(bytes32 => bool)) public playersInAGameFulfilled;
    mapping(bytes32 => mapping(bytes32 => uint8[])) public allOptionsPerPlayer;
    mapping(bytes32 => mapping(bytes32 => mapping(uint8 => IGamesPlayerProps.PlayerPropsResolver)))
        public resolvedPlayerProps;
    mapping(address => bool) public childMarketResolved;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _consumer,
        address _verifier,
        address _sportsManager,
        address _playerPropsReceiver,
        uint[] memory _supportedSportIds
    ) external initializer {
        setOwner(_owner);
        consumer = ITherundownConsumer(_consumer);
        verifier = ITherundownConsumerVerifier(_verifier);
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        playerPropsReceiver = _playerPropsReceiver;

        for (uint i; i < _supportedSportIds.length; i++) {
            doesSportSupportPlayerProps[_supportedSportIds[i]] = true;
        }
    }

    /* ========== PLAYER PROPS MAIN FUNCTIONS ========== */

    /// @notice main function for player props
    /// @param _player player props struct see @ IGamesPlayerProps.PlayerProps
    /// @param _sportId sport id
    function obtainPlayerProps(IGamesPlayerProps.PlayerProps memory _player, uint _sportId) external canExecute {
        address _main = consumer.marketPerGameId(_player.gameId);
        // if main is created and not paused and also sport support player props
        if (_main != address(0) && doesSportSupportPlayerProps[_sportId]) {
            if (_areOddsAndLinesValidForPlayer(_player)) {
                if (
                    invalidOddsForPlayerProps[_player.gameId][_player.playerId][_player.option] ||
                    pausedByInvalidOddsOnMain[_main] ||
                    pausedByCircuitBreakerOnMain[_main]
                ) {
                    invalidOddsForPlayerProps[_player.gameId][_player.playerId][_player.option] = false;
                    pausedByInvalidOddsOnMain[_main] = false;
                    pausedByCircuitBreakerOnMain[_main] = false;
                }
                playerProp[_player.gameId][_player.playerId][_player.option] = _player;
                address playerPropsMarket = _obtainPlayerProps(_player, _main);
                mainMarketPausedPlayerProps[_main] = false;
                playerPropsAddedForMain[_main] = true;

                if (!playersInAGameFulfilled[_player.gameId][_player.playerId]) {
                    playersInAGameFulfilled[_player.gameId][_player.playerId] = true;
                    playersInAGame[_player.gameId].push(_player.playerId);
                }

                if (!createFulfilledForPlayerProps[_player.gameId][_player.playerId][_player.option]) {
                    createFulfilledForPlayerProps[_player.gameId][_player.playerId][_player.option] = true;
                    allOptionsPerPlayer[_player.gameId][_player.playerId].push(_player.option);
                }

                emit PlayerPropsAdded(
                    _player.gameId,
                    _player.playerId,
                    _player.option,
                    normalizedOddsForMarket[playerPropsMarket]
                );
            } else {
                invalidOddsForPlayerProps[_player.gameId][_player.playerId][_player.option] = true;
                _pauseMarketsForPlayerPropsForOption(_player, true);

                emit InvalidOddsForMarket(_main, _player.gameId, _player.playerId, _player.option);
            }
        }
    }

    /// @notice resolve playerProp
    /// @param _result object for resolve
    function resolvePlayerProps(IGamesPlayerProps.PlayerPropsResolver memory _result) external canExecute {
        // get main market
        address _main = consumer.marketPerGameId(_result.gameId);
        //number of childs per option
        uint numberOfChildsPerOptions = numberOfChildMarketsPerPlayerAndOption[_main][_result.playerId][_result.option];
        // if it is resolved skip it
        if (!resolveFulfilledForPlayerProps[_result.gameId][_result.playerId][_result.option]) {
            // resolve
            for (uint j = 0; j < numberOfChildsPerOptions; j++) {
                address child = mainMarketChildMarketPerPlayerAndOptionIndex[_main][_result.playerId][_result.option][j];
                if (!childMarketResolved[child]) {
                    if (invalidOddsForPlayerProps[_result.gameId][_result.playerId][_result.option]) {
                        consumer.pauseOrUnpauseMarket(child, false);
                    }
                    if (_result.statusId == CANCELLED_STATUS) {
                        _resolveMarket(child, uint16(CANCELLED), CANCELLED);
                    } else {
                        _resolveMarketForPlayer(child, _result.score);
                    }
                    childMarketResolved[child] = true;
                }
            }
            resolvedPlayerProps[_result.gameId][_result.playerId][_result.option] = _result;
            resolveFulfilledForPlayerProps[_result.gameId][_result.playerId][_result.option] = true;
        }
    }

    /// @notice cancel playerProp
    /// @param _market market for cancelation
    function cancelMarketFromManager(address _market) external onlyManager {
        address parent = childMarketMainMarket[_market];
        bytes32 gameId = gameIdPerChildMarket[_market];
        bytes32 playerId = playerIdPerChildMarket[_market];
        uint8 option = optionIdPerChildMarket[_market];
        uint numberOfChildsPerOptions = numberOfChildMarketsPerPlayerAndOption[parent][playerId][option];
        if (!childMarketResolved[_market]) {
            _resolveMarket(_market, uint16(CANCELLED), CANCELLED);
            if (numberOfChildsPerOptions < 2) {
                resolveFulfilledForPlayerProps[gameId][playerId][option] = true;
            } else {
                bool flagResolved = true;
                for (uint j = 0; j < numberOfChildsPerOptions; j++) {
                    address child = mainMarketChildMarketPerPlayerAndOptionIndex[parent][playerId][option][j];
                    if (!childMarketResolved[child] && child != _market) {
                        flagResolved = false;
                        break;
                    }
                }
                if (flagResolved) {
                    resolveFulfilledForPlayerProps[gameId][playerId][option] = true;
                }
            }
            childMarketResolved[_market] = true;
        }
    }

    /// @notice pause/unpause all markets for game
    /// @param _main parent market for which we are pause/unpause child markets
    /// @param _flag pause -> true, unpause -> false
    /// @param _invalidOddsMain are paused by invalid odds on main
    /// @param _circuitBreakerOnMain are paused by circuit breaker on main
    function pauseAllPlayerPropsMarketForMain(
        address _main,
        bool _flag,
        bool _invalidOddsMain,
        bool _circuitBreakerOnMain
    ) external onlyConsumer {
        if (playerPropsAddedForMain[_main]) {
            mainMarketPausedPlayerProps[_main] = _flag;
            pausedByInvalidOddsOnMain[_main] = _invalidOddsMain;
            pausedByCircuitBreakerOnMain[_main] = _circuitBreakerOnMain;
            _pauseAllPlayerPropsMarket(_main, _flag);
        }
    }

    /// @notice pause/unpause current active child markets
    /// @param _main parent market for which we are pause/unpause child markets
    function cancelPlayerPropsMarketForMain(address _main) external onlyConsumer {
        _cancelPlayerPropsMarket(_main);
    }

    /* ========== INTERNALS ========== */

    function _areOddsAndLinesValidForPlayer(IGamesPlayerProps.PlayerProps memory _player) internal view returns (bool) {
        return verifier.areOddsAndLinesValidForPlayer(_player.line, _player.overOdds, _player.underOdds);
    }

    function _obtainPlayerProps(IGamesPlayerProps.PlayerProps memory _player, address _main) internal returns (address) {
        bool isNewMarket = numberOfChildMarkets[_main] == 0;
        address currentActiveChildMarket = currentActiveChildMarketPerPlayerAndOption[_main][_player.playerId][
            _player.option
        ];
        address currentMarket = mainMarketPlayerOptionLineChildMarket[_main][_player.playerId][_player.option][_player.line];

        if (isNewMarket || currentMarket == address(0)) {
            address newMarket = _createMarketForPlayerProps(_player, _main);

            currentActiveChildMarketPerPlayerAndOption[_main][_player.playerId][_player.option] = newMarket;

            if (currentActiveChildMarket != address(0)) {
                consumer.pauseOrUnpauseMarket(currentActiveChildMarket, true);
            }
            _setNormalizedOdds(newMarket, _player.gameId, _player.playerId, _player.option);
            return newMarket;
        } else if (currentMarket != currentActiveChildMarket) {
            consumer.pauseOrUnpauseMarket(currentMarket, false);
            consumer.pauseOrUnpauseMarket(currentActiveChildMarket, true);
            currentActiveChildMarketPerPlayerAndOption[_main][_player.playerId][_player.option] = currentMarket;
            _setNormalizedOdds(currentMarket, _player.gameId, _player.playerId, _player.option);
            return currentMarket;
        } else {
            consumer.pauseOrUnpauseMarket(currentActiveChildMarket, false);
            _setNormalizedOdds(currentActiveChildMarket, _player.gameId, _player.playerId, _player.option);
            return currentActiveChildMarket;
        }
    }

    function _pauseMarketsForPlayerPropsForOption(IGamesPlayerProps.PlayerProps memory _player, bool _flag)
        internal
        returns (bool)
    {
        // get main market
        address _main = consumer.marketPerGameId(_player.gameId);
        //number of childs per option
        uint numberOfChildsPerOptions = numberOfChildMarketsPerPlayerAndOption[_main][_player.playerId][_player.option];
        // pause all per option
        for (uint j = 0; j < numberOfChildsPerOptions; j++) {
            address child = mainMarketChildMarketPerPlayerAndOptionIndex[_main][_player.playerId][_player.option][j];
            _pauseOrUnpauseMarket(child, _flag);
        }
    }

    function _pauseAllPlayerPropsMarket(address _main, bool _flag) internal {
        for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
            consumer.pauseOrUnpauseMarket(mainMarketChildMarketIndex[_main][i], _flag);
        }
    }

    function _cancelPlayerPropsMarket(address _main) internal {
        for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
            sportsManager.resolveMarket(mainMarketChildMarketIndex[_main][i], CANCELLED);
        }
    }

    function _pauseOrUnpauseMarket(address _market, bool _pause) internal {
        consumer.pauseOrUnpauseMarket(_market, _pause);
    }

    function _setNormalizedOdds(
        address _market,
        bytes32 _gameId,
        bytes32 _playerId,
        uint8 _option
    ) internal {
        normalizedOddsForMarket[_market] = _getNormalizedOddsForPlayerProps(_gameId, _playerId, _option);
        normalizedOddsForMarketFulfilled[_market] = true;
    }

    function _createMarketForPlayerProps(IGamesPlayerProps.PlayerProps memory _player, address _mainMarket)
        internal
        returns (address _playerMarket)
    {
        // create
        uint[] memory tags = _calculateTags(consumer.sportsIdPerGame(_player.gameId), _player.option);
        sportsManager.createMarket(
            _player.gameId,
            _append(_player), // gameLabel
            consumer.getGameCreatedById(_player.gameId).startTime, //maturity
            0, //initialMint
            2, // always two positions for player props
            tags, //tags
            true, // is child
            _mainMarket
        );

        _playerMarket = sportsManager.getActiveMarketAddress(sportsManager.numActiveMarkets() - 1);

        // adding child markets
        _setChildMarkets(
            _player.gameId,
            _mainMarket,
            _playerMarket,
            _player.line,
            _player.playerId,
            _player.playerName,
            _player.option,
            tags[2]
        );
    }

    function _append(IGamesPlayerProps.PlayerProps memory _player) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _player.playerName,
                    " - ",
                    Strings.toString(_player.option),
                    " - ",
                    Strings.toString(_player.line)
                )
            );
    }

    function _calculateTags(uint _sportsId, uint8 _option) internal pure returns (uint[] memory) {
        uint[] memory result = new uint[](3);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        result[1] = TAG_NUMBER_PLAYERS;
        result[2] = TAG_NUMBER_PLAYER_PROPS + _option;
        return result;
    }

    function _setChildMarkets(
        bytes32 _gameId,
        address _main,
        address _child,
        uint16 _line,
        bytes32 _playerId,
        string memory _playerName,
        uint8 _option,
        uint _type
    ) internal {
        consumer.setGameIdPerChildMarket(_gameId, _child);
        gameIdPerChildMarket[_child] = _gameId;
        playerIdPerChildMarket[_child] = _playerId;
        optionIdPerChildMarket[_child] = _option;
        childMarketCreated[_child] = true;
        childMarketMainMarket[_child] = _main;
        mainMarketChildMarketIndex[_main][numberOfChildMarkets[_main]] = _child;
        numberOfChildMarkets[_main] += 1;
        mainMarketPlayerOptionLineChildMarket[_main][_playerId][_option][_line] = _child;
        childMarketLine[_child] = _line;
        currentActiveChildMarketPerPlayerAndOption[_main][_playerId][_option] = _child;
        mainMarketChildMarketPerPlayerAndOptionIndex[_main][_playerId][_option][
            numberOfChildMarketsPerPlayerAndOption[_main][_playerId][_option]
        ] = _child;
        numberOfChildMarketsPerPlayerAndOption[_main][_playerId][_option] += 1;
        emit CreatePlayerPropsMarket(
            _main,
            _child,
            _gameId,
            _playerId,
            _playerName,
            _line,
            _option,
            _getNormalizedChildOdds(_child),
            _type
        );
    }

    function _resolveMarketForPlayer(address _child, uint16 _score) internal {
        uint16 line = childMarketLine[_child];

        uint outcome = _score * 100 > line ? HOME_WIN : _score * 100 < line ? AWAY_WIN : CANCELLED;

        _resolveMarket(_child, _score, outcome);
    }

    function _resolveMarket(
        address _child,
        uint16 _score,
        uint _outcome
    ) internal {
        sportsManager.resolveMarket(_child, _outcome);
        emit ResolveChildMarket(_child, _outcome, childMarketMainMarket[_child], _score);
    }

    function _getNormalizedOddsForPlayerProps(
        bytes32 _gameId,
        bytes32 _playerId,
        uint8 _option
    ) internal view returns (uint[] memory) {
        int[] memory odds = new int[](2);
        odds[0] = playerProp[_gameId][_playerId][_option].overOdds;
        odds[1] = playerProp[_gameId][_playerId][_option].underOdds;
        return verifier.calculateAndNormalizeOdds(odds);
    }

    function _getNormalizedChildOddsFromGameOddsStruct(address _market) internal view returns (uint[] memory) {
        return
            _getNormalizedOddsForPlayerProps(
                gameIdPerChildMarket[_market],
                playerIdPerChildMarket[_market],
                optionIdPerChildMarket[_market]
            );
    }

    function _getNormalizedChildOdds(address _market) internal view returns (uint[] memory) {
        return
            normalizedOddsForMarketFulfilled[_market]
                ? normalizedOddsForMarket[_market]
                : _getNormalizedChildOddsFromGameOddsStruct(_market);
    }

    function _getAllChildMarketsForParentPlayerOption(
        address _parent,
        bytes32 _player,
        uint8 _option
    ) internal view returns (address[] memory _children) {
        uint num = numberOfChildMarketsPerPlayerAndOption[_parent][_player][_option];
        _children = new address[](num);

        for (uint j = 0; j < num; j++) {
            address child = mainMarketChildMarketPerPlayerAndOptionIndex[_parent][_player][_option][j];
            _children[j] = child;
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice view function which returns props data for given child market
    /// @param _market market
    function getPlayerPropsDataForMarket(address _market)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            uint8
        )
    {
        return (
            childMarketMainMarket[_market],
            gameIdPerChildMarket[_market],
            playerIdPerChildMarket[_market],
            optionIdPerChildMarket[_market]
        );
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-50)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory) {
        return _getNormalizedChildOdds(_market);
    }

    function getPlayerPropForOption(
        bytes32 _gameId,
        bytes32 _playerId,
        uint8 _option
    )
        external
        view
        returns (
            uint16,
            int24,
            int24,
            bool
        )
    {
        IGamesPlayerProps.PlayerProps memory currentProp = playerProp[_gameId][_playerId][_option];
        return (
            currentProp.line,
            currentProp.overOdds,
            currentProp.underOdds,
            invalidOddsForPlayerProps[_gameId][_playerId][_option]
        );
    }

    function getAllOptionsWithPlayersForGameId(bytes32 _gameId)
        external
        view
        returns (
            bytes32[] memory _playerIds,
            uint8[] memory _options,
            bool[] memory _isResolved,
            bool[] memory _hasMintsOnChildren
        )
    {
        // get main market
        address _main = consumer.marketPerGameId(_gameId);

        uint256 totalCombinations = 0;

        for (uint256 i = 0; i < playersInAGame[_gameId].length; i++) {
            bytes32 playerId = playersInAGame[_gameId][i];
            totalCombinations += allOptionsPerPlayer[_gameId][playerId].length;
        }

        _playerIds = new bytes32[](totalCombinations);
        _options = new uint8[](totalCombinations);
        _isResolved = new bool[](totalCombinations);
        _hasMintsOnChildren = new bool[](totalCombinations);

        uint256 index = 0;
        for (uint256 i = 0; i < playersInAGame[_gameId].length; i++) {
            bytes32 playerId = playersInAGame[_gameId][i];
            uint8[] memory playerOptions = allOptionsPerPlayer[_gameId][playerId];

            for (uint256 j = 0; j < playerOptions.length; j++) {
                uint8 optionId = playerOptions[j];

                if (createFulfilledForPlayerProps[_gameId][playerId][optionId]) {
                    _playerIds[index] = playerId;
                    _options[index] = optionId;
                    _isResolved[index] = resolveFulfilledForPlayerProps[_gameId][playerId][optionId];
                    address[] memory _childArraysPerOption = _getAllChildMarketsForParentPlayerOption(
                        _main,
                        playerId,
                        optionId
                    );

                    (bool[] memory _hasAnyMintsArray, , ) = sportsManager.queryMintsAndMaturityStatusForPlayerProps(
                        _childArraysPerOption
                    );

                    _hasMintsOnChildren[index] = false;
                    for (uint256 m = 0; m < _childArraysPerOption.length; m++) {
                        if (_hasAnyMintsArray[m]) {
                            _hasMintsOnChildren[index] = true;
                            break;
                        }
                    }

                    index++;
                }
            }
        }
    }

    function getAllChildMarketsForParents(address[] memory _parents) external view returns (address[] memory _children) {
        uint totalChildren = 0;
        for (uint i = 0; i < _parents.length; i++) {
            totalChildren += numberOfChildMarkets[_parents[i]];
        }

        _children = new address[](totalChildren);
        uint index = 0;

        for (uint i = 0; i < _parents.length; i++) {
            uint num = numberOfChildMarkets[_parents[i]];
            for (uint j = 0; j < num; j++) {
                address child = mainMarketChildMarketIndex[_parents[i]][j];
                _children[index] = child;
                index++;
            }
        }
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets consumer, verifier, manager address
    /// @param _consumer consumer address
    /// @param _verifier verifier address
    /// @param _sportsManager sport manager address
    /// @param _playerPropsReceiver receiver
    function setContracts(
        address _consumer,
        address _verifier,
        address _sportsManager,
        address _playerPropsReceiver
    ) external onlyOwner {
        consumer = ITherundownConsumer(_consumer);
        verifier = ITherundownConsumerVerifier(_verifier);
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        playerPropsReceiver = _playerPropsReceiver;

        emit NewContractAddresses(_consumer, _verifier, _sportsManager, _playerPropsReceiver);
    }

    /// @notice sets if sport is suported or not (delete from supported sport)
    /// @param _sportId sport id which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedSportForPlayerPropsAdded(uint _sportId, bool _isSupported) external onlyOwner {
        doesSportSupportPlayerProps[_sportId] = _isSupported;
        emit SupportedSportForPlayerPropsAdded(_sportId, _isSupported);
    }

    /* ========== MODIFIERS ========== */

    modifier canExecute() {
        require(msg.sender == playerPropsReceiver, "Invalid sender");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == address(sportsManager), "Only manager");
        _;
    }

    modifier onlyConsumer() {
        require(msg.sender == address(consumer), "Only consumer");
        _;
    }

    /* ========== EVENTS ========== */
    event PlayerPropsAdded(bytes32 _gameId, bytes32 _playerId, uint8 _option, uint[] _normalizedOdds);
    event NewContractAddresses(address _consumer, address _verifier, address _sportsManager, address _receiver);
    event SupportedSportForPlayerPropsAdded(uint _sportId, bool _isSupported);
    event CreatePlayerPropsMarket(
        address _main,
        address _child,
        bytes32 _gameId,
        bytes32 _playerId,
        string _playerName,
        uint16 _line,
        uint8 _option,
        uint[] _normalizedOdds,
        uint _type
    );
    event ResolveChildMarket(address _child, uint _outcome, address _main, uint16 _score);
    event InvalidOddsForMarket(address _main, bytes32 _gameId, bytes32 _playerId, uint8 option);
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

    function queryMintsAndMaturityStatusForPlayerProps(address[] memory _playerPropsMarkets)
        external
        view
        returns (
            bool[] memory _hasAnyMintsArray,
            bool[] memory _isMaturedArray,
            bool[] memory _isResolvedArray
        );
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

    function areOddsAndLinesValidForPlayer(
        uint16 _line,
        int24 _overOdds,
        int24 _underOdds
    ) external pure returns (bool);

    function isValidOutcomeForGame(bool _isTwoPositionalSport, uint _outcome) external view returns (bool);

    function isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) external view returns (bool);

    function calculateAndNormalizeOdds(int[] memory _americanOdds) external view returns (uint[] memory);

    function getBookmakerIdsBySportId(uint256 _sportId) external view returns (uint256[] memory);

    function getBookmakerIdsBySportIdForPlayerProps(uint256 _sportId) external view returns (uint256[] memory);

    function getStringIDsFromBytesArrayIDs(bytes32[] memory _ids) external view returns (string[] memory);

    function convertUintToString(uint8[] memory _options) external view returns (string[] memory);
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

    function gameOnADate(bytes32 _gameId) external view returns (uint);

    function isGameResolvedOrCanceled(bytes32 _gameId) external view returns (bool);

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

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

    function pauseOrUnpauseMarketForPlayerProps(
        address _market,
        bool _pause,
        bool _invalidOdds,
        bool _circuitBreakerMain
    ) external;

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

interface IGamesPlayerProps {
    struct PlayerProps {
        bytes32 gameId;
        bytes32 playerId;
        uint8 option;
        string playerName;
        uint16 line;
        int24 overOdds;
        int24 underOdds;
    }

    struct PlayerPropsResolver {
        bytes32 gameId;
        bytes32 playerId;
        uint8 option;
        uint16 score;
        uint8 statusId;
    }

    function obtainPlayerProps(PlayerProps memory _player, uint _sportId) external;

    function resolvePlayerProps(PlayerPropsResolver memory _result) external;

    function cancelMarketFromManager(address _market) external;

    function pauseAllPlayerPropsMarketForMain(
        address _main,
        bool _flag,
        bool _invalidOddsOnMain,
        bool _circuitBreakerMain
    ) external;

    function createFulfilledForPlayerProps(
        bytes32 gameId,
        bytes32 playerId,
        uint8 option
    ) external view returns (bool);

    function cancelPlayerPropsMarketForMain(address _main) external;

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function doesSportSupportPlayerProps(uint _sportId) external view returns (bool);

    function pausedByInvalidOddsOnMain(address _main) external view returns (bool);

    function pausedByCircuitBreakerOnMain(address _main) external view returns (bool);

    function getAllOptionsWithPlayersForGameId(bytes32 _gameId)
        external
        view
        returns (
            bytes32[] memory _playerIds,
            uint8[] memory _options,
            bool[] memory _isResolved,
            address[][] memory _childMarketsPerOption
        );

    function getPlayerPropsDataForMarket(address _market)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            uint8
        );

    function getPlayerPropForOption(
        bytes32 gameId,
        bytes32 playerId,
        uint8 option
    )
        external
        view
        returns (
            uint16,
            int24,
            int24,
            bool
        );

    function fulfillPlayerPropsCLResolved(bytes[] memory _playerProps) external;
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

    function getTagsLength() external view returns (uint tagsLength);

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