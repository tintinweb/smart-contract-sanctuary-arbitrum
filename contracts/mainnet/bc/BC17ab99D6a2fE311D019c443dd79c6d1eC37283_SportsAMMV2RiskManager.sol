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
pragma solidity ^0.8.20;

interface ISportsAMMV2Manager {
    function isWhitelistedAddress(address _address) external view returns (bool);

    function transformCollateral(uint value, address collateral) external view returns (uint);

    function reverseTransformCollateral(uint value, address collateral) external view returns (uint);

    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../utils/proxy/ProxyReentrancyGuard.sol";
import "../utils/proxy/ProxyOwned.sol";
import "../utils/proxy/ProxyPausable.sol";

import "../interfaces/ISportsAMMV2Manager.sol";

/// @title Sports AMM V2 Risk Manager contract
/// @author vladan
contract SportsAMMV2RiskManager is Initializable, ProxyOwned, ProxyPausable, ProxyReentrancyGuard {
    /* ========== CONST VARIABLES ========== */

    uint public constant MIN_SPORT_NUMBER = 9000;
    uint public constant MIN_TYPE_NUMBER = 10000;
    uint public constant DEFAULT_DYNAMIC_LIQUIDITY_CUTOFF_DIVIDER = 2e18;
    uint private constant ONE = 1e18;

    /* ========== STATE VARIABLES ========== */

    ISportsAMMV2Manager public manager;
    uint public defaultCap;
    mapping(uint => uint) public capPerSport;
    mapping(uint => mapping(uint => uint)) public capPerSportAndType;
    mapping(bytes32 => mapping(uint => mapping(uint => mapping(uint => mapping(int => uint))))) public capPerMarket;

    uint public defaultRiskMultiplier;
    mapping(uint => uint) public riskMultiplierPerSport;
    mapping(bytes32 => mapping(uint => mapping(uint => mapping(uint => mapping(int => uint)))))
        public riskMultiplierPerMarket;

    uint public maxCap;
    uint public maxRiskMultiplier;

    mapping(uint => uint) public dynamicLiquidityCutoffTimePerSport;
    mapping(uint => uint) public dynamicLiquidityCutoffDividerPerSport;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _manager,
        uint _defaultCap,
        uint _defaultRiskMultiplier,
        uint _maxCap,
        uint _maxRiskMultiplier
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        defaultCap = _defaultCap;
        defaultRiskMultiplier = _defaultRiskMultiplier;
        maxCap = _maxCap;
        maxRiskMultiplier = _maxRiskMultiplier;
        manager = ISportsAMMV2Manager(_manager);
    }

    /* ========== EXTERNAL READ FUNCTIONS ========== */

    /// @notice calculate which cap needs to be applied to the given game
    /// @param _gameId to get cap for
    /// @param _sportId to get cap for
    /// @param _typeId to get cap for
    /// @param _playerId to get cap for
    /// @param _maturity used for dynamic liquidity check
    /// @param _line used for dynamic liquidity check
    /// @return cap cap to use
    function calculateCapToBeUsed(
        bytes32 _gameId,
        uint16 _sportId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _maturity
    ) external view returns (uint cap) {
        return _calculateCapToBeUsed(_gameId, _sportId, _typeId, _playerId, _line, _maturity);
    }

    /// @notice returns if game is in to much of a risk
    /// @param _totalSpent total spent on game
    /// @param _gameId for which is calculation done
    /// @param _sportId for which is calculation done
    /// @param _typeId for which is calculation done
    /// @param _playerId for which is calculation done
    /// @param _line for which is calculation done
    /// @param _maturity used for dynamic liquidity check
    /// @return _isNotRisky true/false
    function isTotalSpendingLessThanTotalRisk(
        uint _totalSpent,
        bytes32 _gameId,
        uint16 _sportId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _maturity
    ) external view returns (bool _isNotRisky) {
        uint capToBeUsed = _calculateCapToBeUsed(_gameId, _sportId, _typeId, _playerId, _line, _maturity);
        uint riskMultiplier = _calculateRiskMultiplier(_gameId, _sportId, _typeId, _playerId, _line);
        return _totalSpent <= capToBeUsed * riskMultiplier;
    }

    /// @notice returns all data (caps) for given sports
    /// @param _sportIds sport ids
    /// @return capsPerSport caps per sport
    /// @return capsPerSportH caps per type Handicap
    /// @return capsPerSportT caps per type Total
    function getAllDataForSports(
        uint[] memory _sportIds
    ) external view returns (uint[] memory capsPerSport, uint[] memory capsPerSportH, uint[] memory capsPerSportT) {
        capsPerSport = new uint[](_sportIds.length);
        capsPerSportH = new uint[](_sportIds.length);
        capsPerSportT = new uint[](_sportIds.length);

        for (uint i = 0; i < _sportIds.length; i++) {
            capsPerSport[i] = capPerSport[_sportIds[i]];
            capsPerSportH[i] = capPerSportAndType[_sportIds[i]][MIN_TYPE_NUMBER + 1];
            capsPerSportT[i] = capPerSportAndType[_sportIds[i]][MIN_TYPE_NUMBER + 2];
        }
    }

    /* ========== INTERNALS ========== */

    function _calculateRiskMultiplier(
        bytes32 _gameId,
        uint16 _sportId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line
    ) internal view returns (uint marketRisk) {
        marketRisk = riskMultiplierPerMarket[_gameId][_sportId][_typeId][_playerId][_line];

        if (marketRisk == 0) {
            uint riskPerSport = riskMultiplierPerSport[_sportId];
            marketRisk = riskPerSport > 0 ? riskPerSport : defaultRiskMultiplier;
        }
    }

    function _calculateCapToBeUsed(
        bytes32 _gameId,
        uint16 _sportId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _maturity
    ) internal view returns (uint cap) {
        if (_maturity > block.timestamp) {
            cap = capPerMarket[_gameId][_sportId][_typeId][_playerId][_line];
            if (cap == 0) {
                uint sportCap = capPerSport[_sportId];
                sportCap = sportCap > 0 ? sportCap : defaultCap;
                cap = sportCap;

                if (_typeId > 0) {
                    uint typeCap = capPerSportAndType[_sportId][_typeId];
                    cap = typeCap > 0 ? typeCap : sportCap / 2;
                }
            }

            uint dynamicLiquidityCutoffTime = dynamicLiquidityCutoffTimePerSport[_sportId];
            if (dynamicLiquidityCutoffTime > 0) {
                uint timeToStart = _maturity - block.timestamp;
                uint cutOffLiquidity = (cap * ONE) /
                    (
                        dynamicLiquidityCutoffDividerPerSport[_sportId] > 0
                            ? dynamicLiquidityCutoffDividerPerSport[_sportId]
                            : DEFAULT_DYNAMIC_LIQUIDITY_CUTOFF_DIVIDER
                    );
                if (timeToStart >= dynamicLiquidityCutoffTime) {
                    cap = cutOffLiquidity;
                } else {
                    uint remainingFromCutOff = cap - cutOffLiquidity;
                    cap =
                        cutOffLiquidity +
                        (((dynamicLiquidityCutoffTime - timeToStart) * remainingFromCutOff) / dynamicLiquidityCutoffTime);
                }
            }
        }
    }

    /* ========== SETTERS ========== */

    /// @notice Setting the Cap default value
    /// @param _defaultCap default cap
    function setDefaultCap(uint _defaultCap) external onlyOwner {
        require(_defaultCap <= maxCap, "Invalid cap");
        defaultCap = _defaultCap;
        emit SetDefaultCap(_defaultCap);
    }

    /// @notice Setting the Cap per Sport
    /// @param _sportId The ID used for sport
    /// @param _capPerSport The cap amount used for the Sport ID
    function setCapPerSport(uint _sportId, uint _capPerSport) external onlyOwner {
        _setCapPerSport(_sportId, _capPerSport);
    }

    /// @notice Setting the Cap per Sport and Type
    /// @param _sportId The ID used for sport
    /// @param _typeId The ID used for type
    /// @param _capPerType The cap amount used for the Sport ID and Type ID
    function setCapPerSportAndType(uint _sportId, uint _typeId, uint _capPerType) external onlyOwner {
        _setCapPerSportAndType(_sportId, _typeId, _capPerType);
    }

    /// @notice Setting the Cap per spec. markets
    /// @param _gameIds game Ids to set cap for
    /// @param _sportIds sport Ids to set cap for
    /// @param _typeIds type Ids to set cap for
    /// @param _playerIds player Ids to set cap for
    /// @param _lines lines to set cap for
    /// @param _capPerMarket The cap amount used for the specific markets
    function setCapPerMarket(
        bytes32[] memory _gameIds,
        uint16[] memory _sportIds,
        uint16[] memory _typeIds,
        uint16[] memory _playerIds,
        int24[] memory _lines,
        uint _capPerMarket
    ) external {
        require(msg.sender == owner || manager.isWhitelistedAddress(msg.sender), "Invalid sender");
        require(_capPerMarket <= maxCap, "Invalid cap");
        for (uint i; i < _gameIds.length; i++) {
            capPerMarket[_gameIds[i]][_sportIds[i]][_typeIds[i]][_playerIds[i]][_lines[i]] = _capPerMarket;
            emit SetCapPerMarket(_gameIds[i], _sportIds[i], _typeIds[i], _playerIds[i], _lines[i], _capPerMarket);
        }
    }

    /// @notice Setting the Cap per Sport and Cap per Sport and Type (batch)
    /// @param _sportIds sport Ids to set cap for
    /// @param _capsPerSport the cap amounts used for the Sport IDs
    /// @param _sportIdsForTypes sport Ids to set type cap for
    /// @param _typeIds type Ids to set cap for
    /// @param _capsPerSportAndType the cap amounts used for the Sport IDs and Type IDs
    function setCaps(
        uint[] memory _sportIds,
        uint[] memory _capsPerSport,
        uint[] memory _sportIdsForTypes,
        uint[] memory _typeIds,
        uint[] memory _capsPerSportAndType
    ) external onlyOwner {
        for (uint i; i < _sportIds.length; i++) {
            _setCapPerSport(_sportIds[i], _capsPerSport[i]);
        }
        for (uint i; i < _sportIdsForTypes.length; i++) {
            _setCapPerSportAndType(_sportIdsForTypes[i], _typeIds[i], _capsPerSportAndType[i]);
        }
    }

    /// @notice Setting default risk multiplier
    /// @param _defaultRiskMultiplier default risk multiplier
    function setDefaultRiskMultiplier(uint _defaultRiskMultiplier) external onlyOwner {
        require(_defaultRiskMultiplier <= maxRiskMultiplier, "Invalid multiplier");
        defaultRiskMultiplier = _defaultRiskMultiplier;
        emit SetDefaultRiskMultiplier(_defaultRiskMultiplier);
    }

    /// @notice Setting the risk multiplier per Sport
    /// @param _sportId The ID used for sport
    /// @param _riskMultiplier The risk multiplier amount used for the Sport ID
    function setRiskMultiplierPerSport(uint _sportId, uint _riskMultiplier) external onlyOwner {
        require(_sportId > MIN_SPORT_NUMBER, "Invalid ID for sport");
        require(_riskMultiplier <= maxRiskMultiplier, "Invalid multiplier");
        riskMultiplierPerSport[_sportId] = _riskMultiplier;
        emit SetRiskMultiplierPerSport(_sportId, _riskMultiplier);
    }

    /// @notice Setting the risk multiplier per spec. markets
    /// @param _gameIds game Ids to set risk multiplier for
    /// @param _sportIds sport Ids to set risk multiplier for
    /// @param _typeIds type Ids to set risk multiplier for
    /// @param _playerIds player Ids to set risk multiplier for
    /// @param _lines lines to set risk multiplier for
    /// @param _riskMultiplierPerMarket The risk multiplier amount used for the specific markets
    function setRiskMultiplierPerMarket(
        bytes32[] memory _gameIds,
        uint16[] memory _sportIds,
        uint16[] memory _typeIds,
        uint16[] memory _playerIds,
        int24[] memory _lines,
        uint _riskMultiplierPerMarket
    ) external {
        require(msg.sender == owner || manager.isWhitelistedAddress(msg.sender), "Invalid sender");
        require(_riskMultiplierPerMarket <= maxRiskMultiplier, "Invalid multiplier");
        for (uint i; i < _gameIds.length; i++) {
            riskMultiplierPerMarket[_gameIds[i]][_sportIds[i]][_typeIds[i]][_playerIds[i]][
                _lines[i]
            ] = _riskMultiplierPerMarket;
            emit SetRiskMultiplierPerMarket(
                _gameIds[i],
                _sportIds[i],
                _typeIds[i],
                _playerIds[i],
                _lines[i],
                _riskMultiplierPerMarket
            );
        }
    }

    /// @notice Setting the risk multiplier per Sport (batch)
    /// @param _sportIds sport Ids to set risk multiplier for
    /// @param _riskMultiplierPerSport the risk multiplier amounts used for the Sport IDs
    function setRiskMultipliers(uint[] memory _sportIds, uint[] memory _riskMultiplierPerSport) external onlyOwner {
        for (uint i; i < _sportIds.length; i++) {
            require(_sportIds[i] > MIN_SPORT_NUMBER, "Invalid ID for sport");
            require(_riskMultiplierPerSport[i] <= maxRiskMultiplier, "Invalid multiplier");
            riskMultiplierPerSport[_sportIds[i]] = _riskMultiplierPerSport[i];
            emit SetRiskMultiplierPerSport(_sportIds[i], _riskMultiplierPerSport[i]);
        }
    }

    /// @notice Setting the max cap and max risk per game
    /// @param _maxCap max cap
    /// @param _maxRisk max risk multiplier
    function setMaxCapAndRisk(uint _maxCap, uint _maxRisk) external onlyOwner {
        require(_maxCap > defaultCap && _maxRisk > defaultRiskMultiplier, "Invalid input");
        maxCap = _maxCap;
        maxRiskMultiplier = _maxRisk;
        emit SetMaxCapAndRisk(_maxCap, _maxRisk);
    }

    function _setCapPerSport(uint _sportId, uint _capPerSport) internal {
        require(_sportId > MIN_SPORT_NUMBER, "Invalid ID for sport");
        require(_capPerSport <= maxCap, "Invalid cap");
        capPerSport[_sportId] = _capPerSport;
        emit SetCapPerSport(_sportId, _capPerSport);
    }

    function _setCapPerSportAndType(uint _sportId, uint _typeId, uint _capPerType) internal {
        uint currentCapPerSport = capPerSport[_sportId] > 0 ? capPerSport[_sportId] : defaultCap;
        require(_capPerType <= currentCapPerSport, "Invalid cap");
        require(_sportId > MIN_SPORT_NUMBER, "Invalid ID for sport");
        require(_typeId > MIN_TYPE_NUMBER, "Invalid ID for type");
        capPerSportAndType[_sportId][_typeId] = _capPerType;
        emit SetCapPerSportAndType(_sportId, _typeId, _capPerType);
    }

    /// @notice Setting the dynamic liquidity params
    /// @param _sportId The ID used for sport
    /// @param _dynamicLiquidityCutoffTime when to start increasing the liquidity linearly, if 0 assume 100% liquidity all the time since game creation
    /// @param _dynamicLiquidityCutoffDivider e.g. if 2 it means liquidity up until cut off time is 50%, then increases linearly. if 0 use default
    function setDynamicLiquidityParamsPerSport(
        uint _sportId,
        uint _dynamicLiquidityCutoffTime,
        uint _dynamicLiquidityCutoffDivider
    ) external onlyOwner {
        require(_sportId > MIN_SPORT_NUMBER, "Invalid ID for sport");
        dynamicLiquidityCutoffTimePerSport[_sportId] = _dynamicLiquidityCutoffTime;
        dynamicLiquidityCutoffDividerPerSport[_sportId] = _dynamicLiquidityCutoffDivider;
        emit SetDynamicLiquidityParams(_sportId, _dynamicLiquidityCutoffTime, _dynamicLiquidityCutoffDivider);
    }

    /// @notice Setting the Sports Manager contract address
    /// @param _manager Address of Sports Manager contract
    function setSportsManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid address");
        manager = ISportsAMMV2Manager(_manager);
        emit SetSportsManager(_manager);
    }

    /* ========== EVENTS ========== */

    event SetDefaultCap(uint cap);
    event SetCapPerSport(uint sportId, uint cap);
    event SetCapPerSportAndType(uint sportId, uint typeId, uint cap);
    event SetCapPerMarket(bytes32 gameId, uint16 sportId, uint16 typeId, uint16 playerId, int24 line, uint cap);

    event SetDefaultRiskMultiplier(uint riskMultiplier);
    event SetRiskMultiplierPerSport(uint sportId, uint riskMultiplier);
    event SetRiskMultiplierPerMarket(
        bytes32 gameId,
        uint16 sportId,
        uint16 typeId,
        uint16 playerId,
        int24 line,
        uint riskMultiplier
    );
    event SetMaxCapAndRisk(uint maxCap, uint maxRisk);

    event SetDynamicLiquidityParams(uint sportId, uint dynamicLiquidityCutoffTime, uint dynamicLiquidityCutoffDivider);
    event SetSportsManager(address manager);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    modifier onlyOwner() {
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
pragma solidity ^0.8.20;

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

    modifier notPaused() {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}