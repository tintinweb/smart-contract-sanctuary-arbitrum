// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// interface
import "../../interfaces/IGamesPlayerProps.sol";
import "../../interfaces/ITherundownConsumer.sol";

/// @title Recieve player props
/// @author gruja
contract GamesPlayerPropsReceiver is Initializable, ProxyOwned, ProxyPausable {
    IGamesPlayerProps public playerProps;
    ITherundownConsumer public consumer;

    mapping(address => bool) public whitelistedAddresses;
    mapping(uint => mapping(uint8 => bool)) public isValidOptionPerSport;
    mapping(uint => uint[]) public optionsPerSport;

    address public wrapperAddress;

    /// @notice public initialize proxy method
    /// @param _owner future owner of a contract
    function initialize(
        address _owner,
        address _consumer,
        address _playerProps,
        address[] memory _whitelistAddresses
    ) public initializer {
        setOwner(_owner);
        consumer = ITherundownConsumer(_consumer);
        playerProps = IGamesPlayerProps(_playerProps);

        for (uint i; i < _whitelistAddresses.length; i++) {
            whitelistedAddresses[_whitelistAddresses[i]] = true;
        }
    }

    /* ========== PLAYER PROPS R. MAIN FUNCTIONS ========== */

    /// @notice receive player props and create markets
    /// @param _gameIds for which gameids market is created (Boston vs Miami etc.)
    /// @param _playerIds for which playerids market is created (12345, 678910 etc.)
    /// @param _options for which options market is created (points, assists, etc.)
    /// @param _names for which player names market is created (Jimmy Buttler etc.)
    /// @param _lines number of points assists per option
    /// @param _linesOdds odds for lines
    function fulfillPlayerProps(
        bytes32[] memory _gameIds,
        bytes32[] memory _playerIds,
        uint8[] memory _options,
        string[] memory _names,
        uint16[] memory _lines,
        int24[] memory _linesOdds
    ) external isAddressWhitelisted {
        for (uint i = 0; i < _gameIds.length; i++) {
            uint sportId = consumer.sportsIdPerGame(_gameIds[i]);
            if (isValidOptionPerSport[sportId][_options[i]]) {
                IGamesPlayerProps.PlayerProps memory player = _castToPlayerProps(
                    i,
                    _gameIds[i],
                    _playerIds[i],
                    _options[i],
                    _names[i],
                    _lines[i],
                    _linesOdds
                );
                // game needs to be fulfilled and market needed to be created
                if (consumer.gameFulfilledCreated(_gameIds[i]) && consumer.marketPerGameId(_gameIds[i]) != address(0)) {
                    playerProps.obtainPlayerProps(player, sportId);
                }
            }
        }
    }

    /// @notice receive player props odds from CL Node
    /// @param _playerProps bytes array for IGamesPlayerProps.PlayerProps
    function fulfillPlayerPropsCL(bytes[] memory _playerProps) external onlyWrapper {
        for (uint i = 0; i < _playerProps.length; i++) {
            IGamesPlayerProps.PlayerProps memory player = abi.decode(_playerProps[i], (IGamesPlayerProps.PlayerProps));
            uint sportId = consumer.sportsIdPerGame(player.gameId);
            // game needs to be fulfilled and market needed to be created and valid option per sport
            if (
                consumer.gameFulfilledCreated(player.gameId) &&
                consumer.marketPerGameId(player.gameId) != address(0) &&
                isValidOptionPerSport[sportId][player.option]
            ) {
                playerProps.obtainPlayerProps(player, sportId);
            }
        }
    }

    /// @notice receive resolve properties for markets
    /// @param _gameIds for which gameids market is resolving (Boston vs Miami etc.)
    /// @param _playerIds for which playerids market is resolving (12345, 678910 etc.)
    /// @param _options options (assists, points etc.)
    /// @param _scores number of points assists etc. which player had
    /// @param _statuses resolved statuses
    function fulfillResultOfPlayerProps(
        bytes32[] memory _gameIds,
        bytes32[] memory _playerIds,
        uint8[] memory _options,
        uint16[] memory _scores,
        uint8[] memory _statuses
    ) external isAddressWhitelisted {
        for (uint i = 0; i < _gameIds.length; i++) {
            if (playerProps.createFulfilledForPlayerProps(_gameIds[i], _playerIds[i], _options[i])) {
                IGamesPlayerProps.PlayerPropsResolver memory playerResult = _castToPlayerPropsResolver(
                    _gameIds[i],
                    _playerIds[i],
                    _options[i],
                    _scores[i],
                    _statuses[i]
                );
                // game needs to be resolved or canceled
                if (consumer.isGameResolvedOrCanceled(_gameIds[i])) {
                    playerProps.resolvePlayerProps(playerResult);
                }
            }
        }
    }

    /// @notice fulfill all data necessary to resolve player props markets with CL node
    /// @param _playerProps array player Props
    function fulfillPlayerPropsCLResolved(bytes[] memory _playerProps) external onlyWrapper {
        for (uint i = 0; i < _playerProps.length; i++) {
            IGamesPlayerProps.PlayerPropsResolver memory playerResult = abi.decode(
                _playerProps[i],
                (IGamesPlayerProps.PlayerPropsResolver)
            );
            if (playerProps.createFulfilledForPlayerProps(playerResult.gameId, playerResult.playerId, playerResult.option)) {
                // game needs to be resolved or canceled
                if (consumer.isGameResolvedOrCanceled(playerResult.gameId)) {
                    playerProps.resolvePlayerProps(playerResult);
                }
            }
        }
    }

    /* ========== VIEWS ========== */

    function getOptionsPerSport(uint _sportsId) public view returns (uint[] memory) {
        return optionsPerSport[_sportsId];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _castToPlayerProps(
        uint index,
        bytes32 _gameId,
        bytes32 _playerId,
        uint8 _option,
        string memory _name,
        uint16 _line,
        int24[] memory _linesOdds
    ) internal returns (IGamesPlayerProps.PlayerProps memory) {
        return
            IGamesPlayerProps.PlayerProps(
                _gameId,
                _playerId,
                _option,
                _name,
                _line,
                _linesOdds[index * 2],
                _linesOdds[index * 2 + 1]
            );
    }

    function _castToPlayerPropsResolver(
        bytes32 _gameId,
        bytes32 _playerId,
        uint8 _option,
        uint16 _score,
        uint8 _statusId
    ) internal returns (IGamesPlayerProps.PlayerPropsResolver memory) {
        return IGamesPlayerProps.PlayerPropsResolver(_gameId, _playerId, _option, _score, _statusId);
    }

    /* ========== OWNER MANAGEMENT FUNCTIONS ========== */

    /// @notice Sets valid/invalid options per sport
    /// @param _sportId Sport id
    /// @param _options Option ids
    /// @param _flag Invalid/valid flag
    function setValidOptionsPerSport(
        uint _sportId,
        uint8[] memory _options,
        bool _flag
    ) external onlyOwner {
        require(consumer.supportedSport(_sportId), "SportId is not supported");
        for (uint index = 0; index < _options.length; index++) {
            // Only if current flag is different, if same, skip it
            if (isValidOptionPerSport[_sportId][_options[index]] != _flag) {
                // Update the option validity flag
                isValidOptionPerSport[_sportId][_options[index]] = _flag;

                // Update the options array
                if (_flag) {
                    optionsPerSport[_sportId].push(_options[index]);
                } else {
                    // Find and remove the option from the array
                    uint[] storage optionsArray = optionsPerSport[_sportId];
                    for (uint i = 0; i < optionsArray.length; i++) {
                        if (optionsArray[i] == _options[index]) {
                            // Swap with the last element and remove
                            optionsArray[i] = optionsArray[optionsArray.length - 1];
                            optionsArray.pop();
                            break;
                        }
                    }
                }

                // Emit the event
                emit IsValidOptionPerSport(_sportId, _options[index], _flag);
            }
        }
    }

    /// @notice sets the consumer contract address, which only owner can execute
    /// @param _consumer address of a consumer contract
    function setConsumerAddress(address _consumer) external onlyOwner {
        require(_consumer != address(0), "Invalid address");
        consumer = ITherundownConsumer(_consumer);
        emit NewConsumerAddress(_consumer);
    }

    /// @notice sets the wrepper address
    /// @param _wrapper address of a wrapper contract
    function setWrapperAddress(address _wrapper) external onlyOwner {
        require(_wrapper != address(0), "Invalid address");
        wrapperAddress = _wrapper;
        emit NewWrapperAddress(_wrapper);
    }

    /// @notice sets the PlayerProps contract address, which only owner can execute
    /// @param _playerProps address of a player props contract
    function setPlayerPropsAddress(address _playerProps) external onlyOwner {
        require(_playerProps != address(0), "Invalid address");
        playerProps = IGamesPlayerProps(_playerProps);
        emit NewPlayerPropsAddress(_playerProps);
    }

    /// @notice adding/removing whitelist address depending on a flag
    /// @param _whitelistAddresses addresses that needed to be whitelisted/ ore removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address[] memory _whitelistAddresses, bool _flag) external onlyOwner {
        require(_whitelistAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < _whitelistAddresses.length; index++) {
            require(_whitelistAddresses[index] != address(0), "Can't be zero address");
            // only if current flag is different, if same skip it
            if (whitelistedAddresses[_whitelistAddresses[index]] != _flag) {
                whitelistedAddresses[_whitelistAddresses[index]] = _flag;
                emit AddedIntoWhitelist(_whitelistAddresses[index], _flag);
            }
        }
    }

    /* ========== MODIFIERS ========== */

    modifier isAddressWhitelisted() {
        require(whitelistedAddresses[msg.sender], "Whitelisted address");
        _;
    }

    modifier onlyWrapper() {
        require(msg.sender == wrapperAddress, "Invalid wrapper");
        _;
    }

    /* ========== EVENTS ========== */

    event NewWrapperAddress(address _wrapper);
    event NewPlayerPropsAddress(address _playerProps);
    event NewConsumerAddress(address _consumer);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event IsValidOptionPerSport(uint _sport, uint8 _option, bool _flag);
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