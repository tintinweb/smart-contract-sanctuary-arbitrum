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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISportsAMMV2ResultManager.sol";

interface ISportsAMMV2 {
    struct CombinedPosition {
        uint16 typeId;
        uint8 position;
        int24 line;
    }

    struct TradeData {
        bytes32 gameId;
        uint16 sportId;
        uint16 typeId;
        uint maturity;
        uint8 status;
        int24 line;
        uint16 playerId;
        uint[] odds;
        bytes32[] merkleProof;
        uint8 position;
        CombinedPosition[][] combinedPositions;
    }

    function defaultCollateral() external view returns (IERC20);

    function resultManager() external view returns (ISportsAMMV2ResultManager);

    function minBuyInAmount() external view returns (uint);

    function maxTicketSize() external view returns (uint);

    function maxSupportedAmount() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function safeBoxFee() external view returns (uint);

    function resolveTicket(
        address _ticketOwner,
        bool _hasUserWon,
        bool _cancelled,
        uint _buyInAmount,
        address _ticketCreator
    ) external;

    function exerciseTicket(address _ticket) external;

    function getTicketsPerGame(uint _index, uint _pageSize, bytes32 _gameId) external view returns (address[] memory);

    function numOfTicketsPerGame(bytes32 _gameId) external view returns (uint);

    function getActiveTicketsPerUser(uint _index, uint _pageSize, address _user) external view returns (address[] memory);

    function numOfActiveTicketsPerUser(address _user) external view returns (uint);

    function getResolvedTicketsPerUser(uint _index, uint _pageSize, address _user) external view returns (address[] memory);

    function numOfResolvedTicketsPerUser(address _user) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISportsAMMV2.sol";

interface ISportsAMMV2ResultManager {
    enum MarketPositionStatus {
        Open,
        Cancelled,
        Winning,
        Losing
    }

    function isMarketResolved(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        ISportsAMMV2.CombinedPosition[] memory combinedPositions
    ) external view returns (bool isResolved);

    function getMarketPositionStatus(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _position,
        ISportsAMMV2.CombinedPosition[] memory _combinedPositions
    ) external view returns (MarketPositionStatus status);

    function isWinningMarketPosition(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _position,
        ISportsAMMV2.CombinedPosition[] memory _combinedPositions
    ) external view returns (bool isWinning);

    function isCancelledMarketPosition(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _position,
        ISportsAMMV2.CombinedPosition[] memory _combinedPositions
    ) external view returns (bool isCancelled);

    function getResultsPerMarket(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId
    ) external view returns (int24[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../utils/proxy/ProxyOwned.sol";
import "../utils/proxy/ProxyPausable.sol";
import "../interfaces/ISportsAMMV2.sol";
import "../interfaces/ISportsAMMV2ResultManager.sol";
import "./Ticket.sol";

contract SportsAMMV2Data is Initializable, ProxyOwned, ProxyPausable {
    ISportsAMMV2 public sportsAMM;

    struct SportsAMMParameters {
        uint minBuyInAmount;
        uint maxTicketSize;
        uint maxSupportedAmount;
        uint maxSupportedOdds;
        uint safeBoxFee;
    }

    struct MarketData {
        bytes32 gameId;
        uint16 sportId;
        uint16 typeId;
        uint maturity;
        int24 line;
        uint16 playerId;
        uint8 position;
        uint odd;
        ISportsAMMV2.CombinedPosition[] combinedPositions;
    }

    struct MarketResult {
        ISportsAMMV2ResultManager.MarketPositionStatus status;
        int24[] results;
    }

    struct TicketData {
        address id;
        MarketData[] marketsData;
        MarketResult[] marketsResult;
        address ticketOwner;
        address ticketCreator;
        uint buyInAmount;
        uint buyInAmountAfterFees;
        uint totalQuote;
        uint numOfMarkets;
        uint expiry;
        uint createdAt;
        bool resolved;
        bool paused;
        bool cancelled;
        bool isLost;
        bool isUserTheWinner;
        bool isExercisable;
    }

    function initialize(address _owner, address _sportsAMM) external initializer {
        setOwner(_owner);
        sportsAMM = ISportsAMMV2(_sportsAMM);
    }

    function getSportsAMMParameters() external view returns (SportsAMMParameters memory) {
        return
            SportsAMMParameters(
                sportsAMM.minBuyInAmount(),
                sportsAMM.maxTicketSize(),
                sportsAMM.maxSupportedAmount(),
                sportsAMM.maxSupportedOdds(),
                sportsAMM.safeBoxFee()
            );
    }

    /// @notice return all ticket data for an array of tickets
    function getTicketsData(address[] calldata ticketsArray) external view returns (TicketData[] memory) {
        return _getTicketsData(ticketsArray);
    }

    /// @notice return all active ticket data for user
    function getActiveTicketsDataPerUser(address user) external view returns (TicketData[] memory) {
        address[] memory ticketsArray = sportsAMM.getActiveTicketsPerUser(
            0,
            sportsAMM.numOfActiveTicketsPerUser(user),
            user
        );
        return _getTicketsData(ticketsArray);
    }

    /// @notice return all resolved ticket data for user
    function getResolvedTicketsDataPerUser(address user) external view returns (TicketData[] memory) {
        address[] memory ticketsArray = sportsAMM.getResolvedTicketsPerUser(
            0,
            sportsAMM.numOfResolvedTicketsPerUser(user),
            user
        );
        return _getTicketsData(ticketsArray);
    }

    /// @notice return all ticket data for game
    function getTicketsDataPerGame(bytes32 gameId) external view returns (TicketData[] memory) {
        address[] memory ticketsArray = sportsAMM.getTicketsPerGame(0, sportsAMM.numOfTicketsPerGame(gameId), gameId);
        return _getTicketsData(ticketsArray);
    }

    function _getTicketsData(address[] memory ticketsArray) internal view returns (TicketData[] memory) {
        TicketData[] memory tickets = new TicketData[](ticketsArray.length);
        for (uint i = 0; i < ticketsArray.length; i++) {
            Ticket ticket = Ticket(ticketsArray[i]);
            MarketData[] memory marketsData = new MarketData[](ticket.numOfMarkets());
            MarketResult[] memory marketsResult = new MarketResult[](ticket.numOfMarkets());
            for (uint j = 0; j < ticket.numOfMarkets(); j++) {
                marketsData[j] = _getMarketData(ticket, j);
                marketsResult[j] = _getMarketResult(ticket, j);
            }

            tickets[i] = TicketData(
                ticketsArray[i],
                marketsData,
                marketsResult,
                ticket.ticketOwner(),
                ticket.ticketCreator(),
                ticket.buyInAmount(),
                ticket.buyInAmountAfterFees(),
                ticket.totalQuote(),
                ticket.numOfMarkets(),
                ticket.expiry(),
                ticket.createdAt(),
                ticket.resolved(),
                ticket.paused(),
                ticket.cancelled(),
                ticket.isTicketLost(),
                ticket.isUserTheWinner(),
                ticket.isTicketExercisable()
            );
        }
        return tickets;
    }

    function _getMarketData(Ticket ticket, uint marketIndex) internal view returns (MarketData memory) {
        (
            bytes32 gameId,
            uint16 sportId,
            uint16 typeId,
            uint maturity,
            ,
            int24 line,
            uint16 playerId,
            uint8 position,
            uint odd
        ) = ticket.markets(marketIndex);
        ISportsAMMV2.CombinedPosition[] memory combinedPositions = ticket.getCombinedPositions(marketIndex);

        return MarketData(gameId, sportId, typeId, maturity, line, playerId, position, odd, combinedPositions);
    }

    function _getMarketResult(Ticket ticket, uint marketIndex) internal view returns (MarketResult memory) {
        (bytes32 gameId, , uint16 typeId, , , int24 line, uint16 playerId, uint8 position, ) = ticket.markets(marketIndex);
        ISportsAMMV2.CombinedPosition[] memory combinedPositions = ticket.getCombinedPositions(marketIndex);

        ISportsAMMV2ResultManager.MarketPositionStatus status = sportsAMM.resultManager().getMarketPositionStatus(
            gameId,
            typeId,
            playerId,
            line,
            position,
            combinedPositions
        );

        int24[] memory results = sportsAMM.resultManager().getResultsPerMarket(gameId, typeId, playerId);

        return MarketResult(status, results);
    }

    function setSportsAMM(ISportsAMMV2 _sportsAMM) external onlyOwner {
        sportsAMM = _sportsAMM;
        emit SportAMMChanged(address(_sportsAMM));
    }

    event SportAMMChanged(address sportsAMM);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// internal
import "../utils/OwnedWithInit.sol";
import "../interfaces/ISportsAMMV2.sol";

contract Ticket is OwnedWithInit {
    uint private constant ONE = 1e18;

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }

    struct MarketData {
        bytes32 gameId;
        uint16 sportId;
        uint16 typeId;
        uint maturity;
        uint8 status;
        int24 line;
        uint16 playerId;
        uint8 position;
        uint odd;
        ISportsAMMV2.CombinedPosition[] combinedPositions;
    }

    ISportsAMMV2 public sportsAMM;
    address public ticketOwner;
    address public ticketCreator;

    uint public buyInAmount;
    uint public buyInAmountAfterFees;
    uint public totalQuote;
    uint public numOfMarkets;
    uint public expiry;
    uint public createdAt;

    bool public resolved;
    bool public paused;
    bool public initialized;
    bool public cancelled;

    mapping(uint => MarketData) public markets;

    /* ========== CONSTRUCTOR ========== */

    /// @notice initialize the ticket contract
    /// @param _markets data with all market info needed for ticket
    /// @param _buyInAmount ticket buy-in amount
    /// @param _buyInAmountAfterFees ticket buy-in amount without fees
    /// @param _totalQuote total ticket quote
    /// @param _sportsAMM address of Sports AMM contact
    /// @param _ticketOwner owner of the ticket
    /// @param _ticketCreator creator of the ticket
    /// @param _expiry ticket expiry timestamp
    function initialize(
        MarketData[] calldata _markets,
        uint _buyInAmount,
        uint _buyInAmountAfterFees,
        uint _totalQuote,
        address _sportsAMM,
        address _ticketOwner,
        address _ticketCreator,
        uint _expiry
    ) external {
        require(!initialized, "Ticket already initialized");
        initialized = true;
        initOwner(msg.sender);
        sportsAMM = ISportsAMMV2(_sportsAMM);
        numOfMarkets = _markets.length;
        for (uint i = 0; i < numOfMarkets; i++) {
            markets[i] = _markets[i];
        }
        buyInAmount = _buyInAmount;
        buyInAmountAfterFees = _buyInAmountAfterFees;
        totalQuote = _totalQuote;
        ticketOwner = _ticketOwner;
        ticketCreator = _ticketCreator;
        expiry = _expiry;
        createdAt = block.timestamp;
    }

    /* ========== EXTERNAL READ FUNCTIONS ========== */

    /// @notice checks if the user lost the ticket
    /// @return isTicketLost true/false
    function isTicketLost() public view returns (bool) {
        for (uint i = 0; i < numOfMarkets; i++) {
            bool isMarketResolved = sportsAMM.resultManager().isMarketResolved(
                markets[i].gameId,
                markets[i].typeId,
                markets[i].playerId,
                markets[i].line,
                markets[i].combinedPositions
            );
            bool isWinningMarketPosition = sportsAMM.resultManager().isWinningMarketPosition(
                markets[i].gameId,
                markets[i].typeId,
                markets[i].playerId,
                markets[i].line,
                markets[i].position,
                markets[i].combinedPositions
            );
            if (isMarketResolved && !isWinningMarketPosition) {
                return true;
            }
        }
        return false;
    }

    /// @notice checks are all markets of the ticket resolved
    /// @return areAllMarketsResolved true/false
    function areAllMarketsResolved() public view returns (bool) {
        for (uint i = 0; i < numOfMarkets; i++) {
            if (
                !sportsAMM.resultManager().isMarketResolved(
                    markets[i].gameId,
                    markets[i].typeId,
                    markets[i].playerId,
                    markets[i].line,
                    markets[i].combinedPositions
                )
            ) {
                return false;
            }
        }
        return true;
    }

    /// @notice checks if the user won the ticket
    /// @return hasUserWon true/false
    function isUserTheWinner() external view returns (bool hasUserWon) {
        if (areAllMarketsResolved()) {
            hasUserWon = !isTicketLost();
        }
    }

    /// @notice checks if the ticket ready to be exercised
    /// @return isExercisable true/false
    function isTicketExercisable() public view returns (bool isExercisable) {
        isExercisable = !resolved && (areAllMarketsResolved() || isTicketLost());
    }

    /// @notice gets current phase of the ticket
    /// @return phase ticket phase
    function phase() public view returns (Phase) {
        return resolved ? ((expiry < block.timestamp) ? Phase.Expiry : Phase.Maturity) : Phase.Trading;
    }

    /// @notice gets combined positions of the game
    /// @return combinedPositions game combined positions
    function getCombinedPositions(
        uint _marketIndex
    ) public view returns (ISportsAMMV2.CombinedPosition[] memory combinedPositions) {
        return markets[_marketIndex].combinedPositions;
    }

    /* ========== EXTERNAL WRITE FUNCTIONS ========== */

    /// @notice exercise ticket
    function exercise() external onlyAMM {
        require(!paused, "Market paused");
        bool isExercisable = isTicketExercisable();
        require(isExercisable, "Ticket not exercisable yet");

        uint payoutWithFees = sportsAMM.defaultCollateral().balanceOf(address(this));
        uint payout = payoutWithFees - (buyInAmount - buyInAmountAfterFees);
        bool isCancelled = false;

        if (isTicketLost()) {
            if (payoutWithFees > 0) {
                sportsAMM.defaultCollateral().transfer(address(sportsAMM), payoutWithFees);
            }
        } else {
            uint finalPayout = payout;
            isCancelled = true;
            for (uint i = 0; i < numOfMarkets; i++) {
                bool isCancelledMarketPosition = sportsAMM.resultManager().isCancelledMarketPosition(
                    markets[i].gameId,
                    markets[i].typeId,
                    markets[i].playerId,
                    markets[i].line,
                    markets[i].position,
                    markets[i].combinedPositions
                );
                if (isCancelledMarketPosition) {
                    finalPayout = (finalPayout * markets[i].odd) / ONE;
                } else {
                    isCancelled = false;
                }
            }
            sportsAMM.defaultCollateral().transfer(address(ticketOwner), isCancelled ? buyInAmount : finalPayout);

            uint balance = sportsAMM.defaultCollateral().balanceOf(address(this));
            if (balance != 0) {
                sportsAMM.defaultCollateral().transfer(
                    address(sportsAMM),
                    sportsAMM.defaultCollateral().balanceOf(address(this))
                );
            }
        }

        _resolve(!isTicketLost(), isCancelled);
    }

    /// @notice expire ticket
    function expire(address payable beneficiary) external onlyAMM {
        require(phase() == Phase.Expiry, "Ticket expired");
        require(!resolved, "Can't expire resolved parlay.");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    /// @notice withdraw collateral from the ticket
    function withdrawCollateral(address recipient) external onlyAMM {
        sportsAMM.defaultCollateral().transfer(recipient, sportsAMM.defaultCollateral().balanceOf(address(this)));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _resolve(bool _hasUserWon, bool _cancelled) internal {
        resolved = true;
        cancelled = _cancelled;
        sportsAMM.resolveTicket(ticketOwner, _hasUserWon, _cancelled, buyInAmount, ticketCreator);
        emit Resolved(_hasUserWon, _cancelled);
    }

    function _selfDestruct(address payable beneficiary) internal {
        uint balance = sportsAMM.defaultCollateral().balanceOf(address(this));
        if (balance != 0) {
            sportsAMM.defaultCollateral().transfer(beneficiary, balance);
        }
    }

    /* ========== SETTERS ========== */

    function setPaused(bool _paused) external onlyAMM {
        require(paused != _paused, "State not changed");
        paused = _paused;
        emit PauseUpdated(_paused);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAMM() {
        require(msg.sender == address(sportsAMM), "Only the AMM may perform these methods");
        _;
    }

    /* ========== EVENTS ========== */

    event Resolved(bool isUserTheWinner, bool cancelled);
    event Expired(address beneficiary);
    event PauseUpdated(bool paused);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract OwnedWithInit {
    address public owner;
    address public nominatedOwner;

    constructor() {}

    function initOwner(address _owner) internal {
        require(owner == address(0), "Init can only be called when owner is 0");
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