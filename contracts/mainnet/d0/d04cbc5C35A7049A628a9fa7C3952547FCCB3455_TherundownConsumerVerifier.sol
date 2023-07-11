// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// interface
import "../../interfaces/ITherundownConsumer.sol";
import "../../interfaces/IGamesOddsObtainer.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";

/// @title Verifier of data which are coming from CL and stored into TherundownConsumer.sol
/// @author gruja
contract TherundownConsumerVerifier is Initializable, ProxyOwned, ProxyPausable {
    uint private constant ONE_PERCENT = 1e16;
    uint private constant ONE = 1e18;
    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;
    uint public constant RESULT_DRAW = 3;

    ITherundownConsumer public consumer;
    mapping(bytes32 => bool) public invalidName;
    mapping(bytes32 => bool) public supportedMarketType;
    uint public defaultOddsThreshold;
    mapping(uint => uint) public oddsThresholdForSport;

    uint256[] public defaultBookmakerIds;
    mapping(uint256 => uint256[]) public sportIdToBookmakerIds;
    IGamesOddsObtainer public obtainer;
    ISportPositionalMarketManager public sportsManager;
    mapping(address => bool) public whitelistedAddresses;

    uint public minOddsForCheckingThresholdDefault;
    mapping(uint => uint) public minOddsForCheckingThresholdPerSport;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _consumer,
        string[] memory _invalidNames,
        string[] memory _supportedMarketTypes,
        uint _defaultOddsThreshold
    ) external initializer {
        setOwner(_owner);
        consumer = ITherundownConsumer(_consumer);
        _setInvalidNames(_invalidNames, true);
        _setSupportedMarketTypes(_supportedMarketTypes, true);
        defaultOddsThreshold = _defaultOddsThreshold;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice view function which returns names of teams/fighters are invalid
    /// @param _teamA team A in string (Example: Liverpool)
    /// @param _teamB team B in string (Example: Arsenal)
    /// @return bool is names invalid (true -> invalid, false -> valid)
    function isInvalidNames(string memory _teamA, string memory _teamB) external view returns (bool) {
        return
            keccak256(abi.encodePacked(_teamA)) == keccak256(abi.encodePacked(_teamB)) ||
            invalidName[keccak256(abi.encodePacked(_teamA))] ||
            invalidName[keccak256(abi.encodePacked(_teamB))];
    }

    /// @notice view function which returns if names are the same
    /// @param _teamA team A in string (Example: Liverpool)
    /// @param _teamB team B in string (Example: Arsenal)
    /// @return bool is names are the same
    function areTeamsEqual(string memory _teamA, string memory _teamB) external pure returns (bool) {
        return keccak256(abi.encodePacked(_teamA)) == keccak256(abi.encodePacked(_teamB));
    }

    /// @notice view function which returns if market type is supported, checks are done in a wrapper contract
    /// @param _market type of market (create or resolve)
    /// @return bool supported or not
    function isSupportedMarketType(string memory _market) external view returns (bool) {
        return supportedMarketType[keccak256(abi.encodePacked(_market))];
    }

    /// @notice view function which returns if odds are inside of the threshold
    /// @param _sportId sport id for which we get threshold
    /// @param _currentOddsArray current odds on a contract as array
    /// @param _newOddsArray new odds on a contract as array
    /// @param _isTwoPositionalSport is sport two positional
    /// @return bool true if odds are less then threshold false if above
    function areOddsArrayInThreshold(
        uint _sportId,
        uint[] memory _currentOddsArray,
        uint[] memory _newOddsArray,
        bool _isTwoPositionalSport
    ) external view returns (bool) {
        return
            areOddsInThreshold(_sportId, _currentOddsArray[0], _newOddsArray[0]) &&
            areOddsInThreshold(_sportId, _currentOddsArray[1], _newOddsArray[1]) &&
            (_isTwoPositionalSport || areOddsInThreshold(_sportId, _currentOddsArray[2], _newOddsArray[2]));
    }

    /// @notice view function which returns if odds are inside of the threshold
    /// @param _sportId sport id for which we get threshold
    /// @param _currentOdds current single odds on a contract
    /// @param _newOdds new single odds on a contract
    /// @return bool true if odds are less then threshold false if above
    function areOddsInThreshold(
        uint _sportId,
        uint _currentOdds,
        uint _newOdds
    ) public view returns (bool) {
        uint threshold = oddsThresholdForSport[_sportId] == 0 ? defaultOddsThreshold : oddsThresholdForSport[_sportId];
        uint minOdds = minOddsForCheckingThresholdPerSport[_sportId] == 0
            ? minOddsForCheckingThresholdDefault
            : minOddsForCheckingThresholdPerSport[_sportId];

        // Check if both _currentOdds and _newOdds are below X% (example 10%) if minOdds is set
        if (minOdds > 0 && _currentOdds < minOdds * ONE_PERCENT && _newOdds < minOdds * ONE_PERCENT) {
            return true;
        }

        // new odds appear or it is equal
        if (_currentOdds == 0 || _currentOdds == _newOdds) {
            return true;
        }

        // if current odds is GT new one
        if (_newOdds > _currentOdds) {
            return !(((ONE * _newOdds) / _currentOdds) > (ONE + (threshold * ONE_PERCENT)));
        }
        return !(ONE - ((_newOdds * ONE) / _currentOdds) > (threshold * ONE_PERCENT));
    }

    /// @notice view function which if odds are valid or not
    /// @param _isTwoPositionalSport if two positional sport dont look at draw odds
    /// @param _homeOdds odd for home win
    /// @param _awayOdds odd for away win
    /// @param _drawOdds odd for draw win
    /// @return bool true - valid, fasle - invalid
    function areOddsValid(
        bool _isTwoPositionalSport,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external view returns (bool) {
        return _areOddsValid(_isTwoPositionalSport, _homeOdds, _awayOdds, _drawOdds);
    }

    function areSpreadOddsValid(
        int16 spreadHome,
        int24 spreadHomeOdds,
        int16 spreadAway,
        int24 spreadAwayOdds
    ) external view returns (bool) {
        return
            spreadHome == spreadAway * -1 &&
            spreadHome != 0 &&
            spreadAway != 0 &&
            spreadHomeOdds != 0 &&
            spreadAwayOdds != 0;
    }

    function areTotalOddsValid(
        uint24 totalOver,
        int24 totalOverOdds,
        uint24 totalUnder,
        int24 totalUnderOdds
    ) external pure returns (bool) {
        return totalOver == totalUnder && totalOver > 0 && totalUnder > 0 && totalOverOdds != 0 && totalUnderOdds != 0;
    }

    /// @notice view function which returns if outcome of a game is valid
    /// @param _isTwoPositionalSport if two positional sport  draw now vallid
    /// @param _outcome home - 1, away - 2, draw - 3 (if not two positional), and cancel - 0 are valid outomes
    /// @return bool true - valid, fasle - invalid
    function isValidOutcomeForGame(bool _isTwoPositionalSport, uint _outcome) external view returns (bool) {
        return _isValidOutcomeForGame(_isTwoPositionalSport, _outcome);
    }

    /// @notice view function which returns if outcome is good with a score
    /// @param _outcome home - 1, away - 2, draw - 3 (if not two positional), and cancel - 0 are valid outomes
    /// @param _homeScore home team has scored in points
    /// @param _awayScore away team has scored in points
    /// @return bool true - valid, fasle - invalid
    function isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) external pure returns (bool) {
        return _isValidOutcomeWithResult(_outcome, _homeScore, _awayScore);
    }

    /// @notice calculate normalized odds based on american odds
    /// @param _americanOdds american odds in array of 3 [home,away,draw]
    /// @return uint[] array of normalized odds
    function calculateAndNormalizeOdds(int[] memory _americanOdds) external pure returns (uint[] memory) {
        return _calculateAndNormalizeOdds(_americanOdds);
    }

    /// @notice view function which returns odds in a batch of games
    /// @param _gameIds game ids for which games is looking
    /// @return odds odds array
    function getOddsForGames(bytes32[] memory _gameIds) public view returns (int24[] memory odds) {
        odds = new int24[](3 * _gameIds.length);
        for (uint i = 0; i < _gameIds.length; i++) {
            (int24 home, int24 away, int24 draw, , , , ) = obtainer.getOddsForGame(_gameIds[i]);
            odds[i * 3 + 0] = home; // 0 3 6 ...
            odds[i * 3 + 1] = away; // 1 4 7 ...
            odds[i * 3 + 2] = draw; // 2 5 8 ...
        }
    }

    /// @notice view function which returns all spread and total properties
    /// @param _gameIds game ids for which games is looking
    function getAllPropertiesForGivenGames(bytes32[] memory _gameIds)
        external
        view
        returns (
            int24[] memory oddsMain,
            int16[] memory linesSpread,
            uint24[] memory linesTotal,
            int24[] memory oddsSpreadTotals
        )
    {
        return (
            getOddsForGames(_gameIds),
            getSpreadLinesForGames(_gameIds),
            getTotalLinesForGames(_gameIds),
            getSpreadTotalsOddsForGames(_gameIds)
        );
    }

    /// @notice view function which returns odds in a batch of games
    /// @param _gameIds game ids for which games is looking
    /// @return lines odds array
    function getSpreadLinesForGames(bytes32[] memory _gameIds) public view returns (int16[] memory lines) {
        lines = new int16[](2 * _gameIds.length);
        for (uint i = 0; i < _gameIds.length; i++) {
            (int16 spreadHome, int16 spreadAway, , ) = obtainer.getLinesForGame(_gameIds[i]);
            lines[i * 2 + 0] = spreadHome; // 0 2 4 ...
            lines[i * 2 + 1] = spreadAway; // 1 3 5 ...
        }
    }

    /// @notice view function which returns odds in a batch of games
    /// @param _gameIds game ids for which games is looking
    /// @return lines odds array
    function getTotalLinesForGames(bytes32[] memory _gameIds) public view returns (uint24[] memory lines) {
        lines = new uint24[](2 * _gameIds.length);
        for (uint i = 0; i < _gameIds.length; i++) {
            (, , uint24 totalOver, uint24 totalUnder) = obtainer.getLinesForGame(_gameIds[i]);
            lines[i * 2 + 0] = totalOver; // 0 2 4 ...
            lines[i * 2 + 1] = totalUnder; // 1 3 5 ...
        }
    }

    /// @notice view function which returns odds in a batch of games
    /// @param _gameIds game ids for which games is looking
    /// @return odds odds array
    function getSpreadTotalsOddsForGames(bytes32[] memory _gameIds) public view returns (int24[] memory odds) {
        odds = new int24[](4 * _gameIds.length);
        for (uint i = 0; i < _gameIds.length; i++) {
            (, , , int24 spreadHomeOdds, int24 spreadAwayOdds, int24 totalOverOdds, int24 totalUnderOdds) = obtainer
                .getOddsForGame(_gameIds[i]);
            odds[i * 4 + 0] = spreadHomeOdds; // 0 4 8 ...
            odds[i * 4 + 1] = spreadAwayOdds; // 1 5 9 ...
            odds[i * 4 + 2] = totalOverOdds; // 2 6 10 ...
            odds[i * 4 + 3] = totalUnderOdds; // 2 7 11 ...
        }
    }

    /* ========== INTERNALS ========== */

    function _calculateAndNormalizeOdds(int[] memory _americanOdds) internal pure returns (uint[] memory) {
        uint[] memory normalizedOdds = new uint[](_americanOdds.length);
        uint totalOdds;
        for (uint i = 0; i < _americanOdds.length; i++) {
            uint calculationOdds;
            if (_americanOdds[i] == 0) {
                normalizedOdds[i] = 0;
            } else if (_americanOdds[i] > 0) {
                calculationOdds = uint(_americanOdds[i]);
                normalizedOdds[i] = ((10000 * 1e18) / (calculationOdds + 10000)) * 100;
            } else if (_americanOdds[i] < 0) {
                calculationOdds = uint(-_americanOdds[i]);
                normalizedOdds[i] = ((calculationOdds * 1e18) / (calculationOdds + 10000)) * 100;
            }
            totalOdds += normalizedOdds[i];
        }
        for (uint i = 0; i < normalizedOdds.length; i++) {
            if (totalOdds == 0) {
                normalizedOdds[i] = 0;
            } else {
                normalizedOdds[i] = (1e18 * normalizedOdds[i]) / totalOdds;
            }
        }
        return normalizedOdds;
    }

    function _areOddsValid(
        bool _isTwoPositionalSport,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) internal pure returns (bool) {
        if (_isTwoPositionalSport) {
            return _awayOdds != 0 && _homeOdds != 0;
        } else {
            return _awayOdds != 0 && _homeOdds != 0 && _drawOdds != 0;
        }
    }

    function _isValidOutcomeForGame(bool _isTwoPositionalSport, uint _outcome) internal pure returns (bool) {
        if (_isTwoPositionalSport) {
            return _outcome == HOME_WIN || _outcome == AWAY_WIN || _outcome == CANCELLED;
        }
        return _outcome == HOME_WIN || _outcome == AWAY_WIN || _outcome == RESULT_DRAW || _outcome == CANCELLED;
    }

    function _isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) internal pure returns (bool) {
        if (_outcome == CANCELLED) {
            return _awayScore == CANCELLED && _homeScore == CANCELLED;
        } else if (_outcome == HOME_WIN) {
            return _homeScore > _awayScore;
        } else if (_outcome == AWAY_WIN) {
            return _homeScore < _awayScore;
        } else {
            return _homeScore == _awayScore;
        }
    }

    function _setInvalidNames(string[] memory _invalidNames, bool _isInvalid) internal {
        for (uint256 index = 0; index < _invalidNames.length; index++) {
            // only if current flag is different, if same skip it
            if (invalidName[keccak256(abi.encodePacked(_invalidNames[index]))] != _isInvalid) {
                invalidName[keccak256(abi.encodePacked(_invalidNames[index]))] = _isInvalid;
                emit SetInvalidName(keccak256(abi.encodePacked(_invalidNames[index])), _isInvalid);
            }
        }
    }

    function _setSupportedMarketTypes(string[] memory _supportedMarketTypes, bool _isSupported) internal {
        for (uint256 index = 0; index < _supportedMarketTypes.length; index++) {
            // only if current flag is different, if same skip it
            if (supportedMarketType[keccak256(abi.encodePacked(_supportedMarketTypes[index]))] != _isSupported) {
                supportedMarketType[keccak256(abi.encodePacked(_supportedMarketTypes[index]))] = _isSupported;
                emit SetSupportedMarketType(keccak256(abi.encodePacked(_supportedMarketTypes[index])), _isSupported);
            }
        }
    }

    /// @notice view function which returns all props needed for game
    /// @param _sportId sportid
    /// @param _date date for sport
    /// @return _isSportOnADate have sport on date true/false
    /// @return _twoPositional is two positional sport true/false
    /// @return _gameIds game Ids for that date/sport
    function getSportProperties(uint _sportId, uint _date)
        external
        view
        returns (
            bool _isSportOnADate,
            bool _twoPositional,
            bytes32[] memory _gameIds
        )
    {
        return (
            consumer.isSportOnADate(_date, _sportId),
            consumer.isSportTwoPositionsSport(_sportId),
            consumer.getGamesPerDatePerSport(_sportId, _date)
        );
    }

    /// @notice view function which returns all props needed for game
    /// @param _gameIds game id on contract
    /// @return _market address
    /// @return _marketResolved resolved true/false
    /// @return _marketCanceled canceled true/false
    /// @return _invalidOdds invalid odds true/false
    /// @return _isPausedByCanceledStatus is game paused by cancel status true/false
    /// @return _isMarketPaused is market paused
    function getGameProperties(bytes32 _gameIds)
        external
        view
        returns (
            address _market,
            bool _marketResolved,
            bool _marketCanceled,
            bool _invalidOdds,
            bool _isPausedByCanceledStatus,
            bool _isMarketPaused
        )
    {
        address marketAddress = consumer.marketPerGameId(_gameIds);
        return (
            marketAddress,
            consumer.marketResolved(marketAddress),
            consumer.marketCanceled(marketAddress),
            obtainer.invalidOdds(marketAddress),
            consumer.isPausedByCanceledStatus(marketAddress),
            marketAddress != address(0) ? sportsManager.isMarketPaused(marketAddress) : false
        );
    }

    function getAllGameProperties(bytes32[] memory _gameIds)
        external
        view
        returns (
            address[] memory _markets,
            bool[] memory _marketResolved,
            bool[] memory _marketCanceled,
            bool[] memory _invalidOdds,
            bool[] memory _isPausedByCanceledStatus,
            bool[] memory _isMarketPaused,
            uint[] memory _startTime
        )
    {
        uint256 arrayLength = _gameIds.length;
        _markets = new address[](arrayLength);
        _marketResolved = new bool[](arrayLength);
        _marketCanceled = new bool[](arrayLength);
        _invalidOdds = new bool[](arrayLength);
        _isPausedByCanceledStatus = new bool[](arrayLength);
        _isMarketPaused = new bool[](arrayLength);
        _startTime = new uint[](arrayLength);

        for (uint256 i = 0; i < arrayLength; i++) {
            address marketAddress = consumer.marketPerGameId(_gameIds[i]);
            _markets[i] = marketAddress;
            _marketResolved[i] = consumer.marketResolved(marketAddress);
            _marketCanceled[i] = consumer.marketCanceled(marketAddress);
            _invalidOdds[i] = obtainer.invalidOdds(marketAddress);
            _isPausedByCanceledStatus[i] = consumer.isPausedByCanceledStatus(marketAddress);
            _isMarketPaused[i] = marketAddress != address(0) ? sportsManager.isMarketPaused(marketAddress) : false;
            _startTime[i] = consumer.getGameStartTime(_gameIds[i]);
        }

        return (
            _markets,
            _marketResolved,
            _marketCanceled,
            _invalidOdds,
            _isPausedByCanceledStatus,
            _isMarketPaused,
            _startTime
        );
    }

    function areInvalidOdds(bytes32 _gameIds) external view returns (bool _invalidOdds) {
        return obtainer.invalidOdds(consumer.marketPerGameId(_gameIds));
    }

    /// @notice getting bookmaker by sports id
    /// @param _sportId id of a sport for fetching
    function getBookmakerIdsBySportId(uint256 _sportId) external view returns (uint256[] memory) {
        return sportIdToBookmakerIds[_sportId].length > 0 ? sportIdToBookmakerIds[_sportId] : defaultBookmakerIds;
    }

    /// @notice return string array from bytes32 array
    /// @param _ids bytes32 array of game ids
    function getStringIDsFromBytesArrayIDs(bytes32[] memory _ids) external view returns (string[] memory _gameIds) {
        if (_ids.length > 0) {
            _gameIds = new string[](_ids.length);
        }
        for (uint i = 0; i < _ids.length; i++) {
            _gameIds[i] = string(abi.encodePacked(_ids[i]));
        }
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets consumer address
    /// @param _consumer consumer address
    function setConsumerAddress(address _consumer) external onlyOwner {
        require(_consumer != address(0), "Invalid address");
        consumer = ITherundownConsumer(_consumer);
        emit NewConsumerAddress(_consumer);
    }

    /// @notice sets manager address
    /// @param _manager address
    function setSportsManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid address");
        sportsManager = ISportPositionalMarketManager(_manager);
        emit NewSportsManagerAddress(_manager);
    }

    /// @notice sets invalid names
    /// @param _invalidNames invalid names as array of strings
    /// @param _isInvalid true/false (invalid or not)
    function setInvalidNames(string[] memory _invalidNames, bool _isInvalid) external onlyOwner {
        require(_invalidNames.length > 0, "Invalid input");
        _setInvalidNames(_invalidNames, _isInvalid);
    }

    /// @notice sets supported market types
    /// @param _supportedMarketTypes supported types as array of strings
    /// @param _isSupported true/false (invalid or not)
    function setSupportedMarketTypes(string[] memory _supportedMarketTypes, bool _isSupported) external onlyOwner {
        require(_supportedMarketTypes.length > 0, "Invalid input");
        _setSupportedMarketTypes(_supportedMarketTypes, _isSupported);
    }

    /// @notice setting default odds threshold
    /// @param _defaultOddsThreshold default odds threshold
    function setDefaultOddsThreshold(uint _defaultOddsThreshold) external onlyOwner {
        require(_defaultOddsThreshold > 0, "Must be more then ZERO");
        defaultOddsThreshold = _defaultOddsThreshold;
        emit NewDefaultOddsThreshold(_defaultOddsThreshold);
    }

    /// @notice setting custom odds threshold for sport
    /// @param _sportId sport id
    /// @param _oddsThresholdForSport custom odds threshold which will be by sport
    function setCustomOddsThresholdForSport(uint _sportId, uint _oddsThresholdForSport) external onlyOwner {
        require(defaultOddsThreshold != _oddsThresholdForSport, "Same value as default value");
        require(_oddsThresholdForSport > 0, "Must be more then ZERO");
        require(consumer.supportedSport(_sportId), "SportId is not supported");
        require(oddsThresholdForSport[_sportId] != _oddsThresholdForSport, "Same value as before");
        oddsThresholdForSport[_sportId] = _oddsThresholdForSport;
        emit NewCustomOddsThresholdForSport(_sportId, _oddsThresholdForSport);
    }

    /// @notice setting default bookmakers
    /// @param _defaultBookmakerIds array of bookmaker ids
    function setDefaultBookmakerIds(uint256[] memory _defaultBookmakerIds) external onlyOwner {
        defaultBookmakerIds = _defaultBookmakerIds;
        emit NewDefaultBookmakerIds(_defaultBookmakerIds);
    }

    /// @notice setting bookmaker by sports id
    /// @param _sportId id of a sport
    /// @param _bookmakerIds array of bookmakers
    function setBookmakerIdsBySportId(uint256 _sportId, uint256[] memory _bookmakerIds) external {
        require(
            msg.sender == owner || whitelistedAddresses[msg.sender],
            "Only owner or whitelisted address may perform this action"
        );
        require(consumer.supportedSport(_sportId), "SportId is not supported");
        sportIdToBookmakerIds[_sportId] = _bookmakerIds;
        emit NewBookmakerIdsBySportId(_sportId, _bookmakerIds);
    }

    /// @notice sets obtainer
    /// @param _obtainer obtainer address
    function setObtainer(address _obtainer) external onlyOwner {
        obtainer = IGamesOddsObtainer(_obtainer);
        emit NewObtainerAddress(_obtainer);
    }

    /// @notice setWhitelistedAddresses enables whitelist addresses of given array
    /// @param _whitelistedAddresses array of whitelisted addresses
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function setWhitelistedAddresses(address[] calldata _whitelistedAddresses, bool _flag) external onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < _whitelistedAddresses.length; index++) {
            // only if current flag is different, if same skip it
            if (whitelistedAddresses[_whitelistedAddresses[index]] != _flag) {
                whitelistedAddresses[_whitelistedAddresses[index]] = _flag;
                emit AddedIntoWhitelist(_whitelistedAddresses[index], _flag);
            }
        }
    }

    /// @notice setting min percentage for checking threshold
    /// @param _minOddsForCheckingThresholdDefault min percentage which threshold for odds are checked
    function setMinOddsForCheckingThresholdDefault(uint _minOddsForCheckingThresholdDefault) external onlyOwner {
        minOddsForCheckingThresholdDefault = _minOddsForCheckingThresholdDefault;
        emit NewMinOddsForCheckingThresholdDefault(_minOddsForCheckingThresholdDefault);
    }

    /// @notice setting custom min odds checking for threshold
    /// @param _sportId sport id
    /// @param _minOddsForCheckingThresholdPerSport custom custom min odds checking for threshold
    function setMinOddsForCheckingThresholdPerSport(uint _sportId, uint _minOddsForCheckingThresholdPerSport)
        external
        onlyOwner
    {
        minOddsForCheckingThresholdPerSport[_sportId] = _minOddsForCheckingThresholdPerSport;
        emit NewMinOddsForCheckingThresholdPerSport(_sportId, _minOddsForCheckingThresholdPerSport);
    }

    /* ========== EVENTS ========== */
    event NewConsumerAddress(address _consumer);
    event SetInvalidName(bytes32 _invalidName, bool _isInvalid);
    event SetSupportedMarketType(bytes32 _supportedMarketType, bool _isSupported);
    event NewDefaultOddsThreshold(uint _defaultOddsThreshold);
    event NewCustomOddsThresholdForSport(uint _sportId, uint _oddsThresholdForSport);
    event NewBookmakerIdsBySportId(uint256 _sportId, uint256[] _ids);
    event NewDefaultBookmakerIds(uint256[] _ids);
    event NewObtainerAddress(address _obtainer);
    event NewSportsManagerAddress(address _manager);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event NewMinOddsForCheckingThresholdDefault(uint _minOddsChecking);
    event NewMinOddsForCheckingThresholdPerSport(uint256 _sportId, uint _minOddsChecking);
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