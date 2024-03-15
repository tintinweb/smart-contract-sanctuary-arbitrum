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

// Inheritance
import "./Ticket.sol";

contract TicketMastercopy is Ticket {
    constructor() {
        // Freeze mastercopy on deployment so it can never be initialized with real arguments
        initialized = true;
    }
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