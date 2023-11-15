//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { Ownable2Step, Ownable } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { MarketPhase, NormalizationFactors } from "./LevrParams.sol";
import { ILevrChainLinkOracle } from "../oracles/ILevrChainLinkOracle.sol";
import { ILevrConfigHandler } from "./interfaces/ILevrConfigHandler.sol";
import { ILevrGameFactory } from "../game-markets/interfaces/ILevrGameFactory.sol";

/// @title LevrConfigHandler - Admin Configurations Handler for the LEVR Protocol.
contract LevrConfigHandler is ILevrConfigHandler, Ownable2Step {
    ///@dev Admin Configuration Handler for the LEVR Protocol.
    uint256 public constant MAX_POSITION_TRANSACTION_FEE = 1e18;

    ILevrChainLinkOracle public chainLinkOracle;
    address public gameFactory;
    address public emissionHandler;
    address public rewardDistributor;
    address public poolVault;
    uint256 public transactionFee;

    uint256 public override borrowFeeTheta;
    uint256 public override positionFee;

    mapping(uint256 gameId => uint256 normalizationFactor) public normalizationFactors;

    event ChainLinkOracleUpdated(address indexed _chainLinkOracle);
    event NormalizationFactorUpdated(uint256 indexed gameId, uint256 indexed _normalizationFactor);
    event BorrowFeeThetaUpdated(uint256 indexed theta);
    event PositionFeeUpdated(uint256 indexed _positionFee);
    event PoolVaultUpdated(address indexed _poolVault);
    event TransactionFeeUpdated(uint256 indexed _transactionFee);

    /// @param _oracle Address of the ChainLink Oracle contract.
    constructor(address _oracle) Ownable(msg.sender) {
        chainLinkOracle = ILevrChainLinkOracle(_oracle);
        positionFee = 1e16;
        transactionFee = 1e16;
    }

    /// @dev Sets the protocol configurations including Game Factory, Emission Handler, and Fee Distributor.
    /// @param _gameFactory Address of the Game Factory contract.
    /// @param _emissionHandler Address of the Emission Handler contract.
    /// @param _feeDistributor Address of the Fee Distributor contract.
    function setConfigs(address _gameFactory, address _emissionHandler, address _feeDistributor) external override onlyOwner {
        if (_gameFactory == address(0) || _emissionHandler == address(0) || _feeDistributor == address(0)) {
            revert LCH_ZERO_ADDRESS();
        }
        gameFactory = _gameFactory;
        emissionHandler = _emissionHandler;
        rewardDistributor = _feeDistributor;
    }

    /// @dev Sets the address of the Pool Vault contract.
    /// @param _poolVault Address of the Pool Vault contract.
    function setPoolVault(address _poolVault) external override onlyOwner {
        if (_poolVault == address(0)) revert LCH_ZERO_ADDRESS();
        poolVault = _poolVault;

        emit PoolVaultUpdated(_poolVault);
    }

    /// @dev Sets the address of the ChainLink Oracle contract.
    /// @param _chainLinkOracle Address of the ChainLink Oracle contract.
    function setChainLinkOracleAddress(address _chainLinkOracle) external override onlyOwner {
        if (_chainLinkOracle == address(0)) revert LCH_ZERO_ADDRESS();
        if (address(chainLinkOracle) == _chainLinkOracle) revert LCH_DUPLICATE_ORACLE_ADDRESS();

        chainLinkOracle = ILevrChainLinkOracle(_chainLinkOracle);

        emit ChainLinkOracleUpdated(_chainLinkOracle);
    }

    /// @dev Sets the borrow fee theta, a global parameter for the borrow fee.
    /// @param theta The new value of the borrow fee theta.
    function setBorrowFeeTheta(uint256 theta) external override onlyOwner {
        borrowFeeTheta = theta;
        emit BorrowFeeThetaUpdated(theta);
        ///!@dev review this
    }

    /**
     * @dev Sets the position fee.
     * @param _positionFee The new position fee to be set.
     */
    function setPositionFee(uint256 _positionFee) external override onlyOwner {
        if (_positionFee == 0 || _positionFee >= MAX_POSITION_TRANSACTION_FEE) revert LCH_INVALID_POSITION_TRANSACTION_FEE();
        positionFee = _positionFee;
        emit PositionFeeUpdated(_positionFee);
    }

    /**
     * @dev Sets the transaction fee.
     * @param _transactionFee The new transaction fee to be set.
     */
    function setTransactionFee(uint256 _transactionFee) external override onlyOwner {
        if (_transactionFee == 0 || _transactionFee >= MAX_POSITION_TRANSACTION_FEE)
            revert LCH_INVALID_POSITION_TRANSACTION_FEE();
        transactionFee = _transactionFee;

        emit TransactionFeeUpdated(_transactionFee);
    }

    function setNormalizationFactor(uint256 gameId, uint256 normalizationFactor) external onlyOwner {
        if (gameId == 0) revert LCH_INVALID_GAME_ID();
        if (normalizationFactor < 1e18) revert LCH_INVALID_NORMALIZATION_FACTOR();

        normalizationFactors[gameId] = normalizationFactor;

        emit NormalizationFactorUpdated(gameId, normalizationFactor);
    }

    function getNormalizationFactor(uint256 gameId) external view override returns (uint256) {
        return normalizationFactors[gameId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum MarketPhase {
    PreMarket,
    LiveMarket,
    PostMarket
}

enum PositionStatus {
    Closed,
    Open,
    Liquidated
}

enum TokenId {
    HOME,
    VISITOR
}

struct EpochStandardPurchases {
    uint128 priceH;
    uint128 priceV;
    uint128 amountH;
    uint128 amountV;
    uint8 epochId;
}

struct StandardPosition {
    uint128 collateralAmount;
    uint128 tokensBought;
    uint128 paidOut;
    TokenId tokenId;
}

struct LevrStandardPosition {
    StandardPosition positionH;
    StandardPosition positionV;
    address user;
}

struct StandardLeveragePosition {
    uint128 entryPrice;
    uint128 exitPrice;
    uint128 liquidationPrice;
    uint128 positionFee;
    uint128 collateralAmount;
    uint128 positionSize;
    uint128 tokensBought;
    uint128 paidOut;
    uint128 positionBoundedLoss;
    uint8 epochId;
    TokenId tokenId;
    PositionStatus positionStatus;
}

struct LevrLeveragePosition {
    address user;
    uint8 leverageRate;
    StandardLeveragePosition positionH;
    StandardLeveragePosition positionV;
}

struct LevrPurchaseTokens {
    uint128 actualAmount;
    uint128 entryPrice;
    uint128 tokensPurchased;
    uint128 positionFee;
    uint128 positionBoundedLoss;
}

struct NormalizationFactors {
    uint128 normalizationFactorH;
    uint128 normalizationFactorV;
}

struct UpdatePositions {
    address[] from;
    uint128[] fromAmounts;
    uint128[] fromBoundedLosses;
    uint128[] toCollaterals;
    address to;
    TokenId tokenId;
    uint8 positionEpoch;
    uint8 positionLeverage;
}

struct Epoch {
    ///@dev Total tokens (Home + Visitor) emitted during this epoch.
    uint128 totalTokensEmitted;
    ///@dev Total number of Home team tokens allocated for this epoch.
    uint128 tokenHEmitted;
    ///@dev Total number of Visitor team tokens allocated for this epoch.
    uint128 tokenVEmitted;
    ///@dev Total tokens (Home + Visitor) sold during this epoch.
    uint128 totalTokenSold;
    ///@dev number of tokens sold for home team
    uint128 tokenHSold;
    ///@dev number of tokens sold for visitor team
    uint128 tokenVSold;
    ///@dev The price per token for the Home team during this epoch.
    uint128 priceH;
    ///@dev The price per token for the Visitor team during this epoch.
    uint128 priceV;
    ///@dev epoch emission started
    bool emissionStarted;
    bool soldOut;
}

///@dev struct for levr fee distribution
struct ContractShare {
    int256 shareDebt;
    address contract_;
    uint16 share;
}

///@dev struct for levr pooled liquidity vault for funding game leveraged positions
struct GameBoundedLoss {
    uint256 gameId;
    ///@dev guard rails for maximum this vault can lose if tokenH wins
    uint128 maxBoundedLossH;
    ///@dev guard rails for maximum this vault can lose if tokenV wins
    uint128 maxBoundedLossV;
    ///@dev total bounded loss for tokenH
    uint128 boundedLossH;
    ///@dev total bounded loss for tokenV
    uint128 boundedLossV;
    ///@dev total used to fund leverage positions for tokenH
    uint128 leverageFundedH;
    ///@dev total used to fund leverage positions for tokenV
    uint128 leverageFundedV;
    // ///@dev total amount of collateral used in taking positions for tokenH
    // uint128 collateralH;
    // ///@dev total amount of collateral used in taking positions for tokenV
    // uint128 collateralV;
    ///@dev actual total amount of funds the vault will lose if tokenH wins
    uint128 potentialPayoutH;
    ///@dev actual total amount of funds the vault will lose if tokenV wins
    uint128 potentialPayoutV;
    ///@dev total amount of borrow fees to be collected for all positions of tokenH in post market phase
    uint128 borrowFeeH;
    ///@dev total amount of borrow fees to be collected for all positions of tokenV in post market phase
    uint128 borrowFeeV;
}

/**
 * @dev Struct representing a LevrOrder,
 * capturing details of a Single trading order.
 */
struct LevrOrder {
    uint256 gameId;
    uint128 currentTokenPrice;
    address from;
    uint128 fromAmount; //number of tokens to buy
    uint128 toCollateral;
    uint8 leverageRate;
    TokenId tokenId;
    uint256 totalFees;
    address to;
    uint256 amountOfTokensNeeded;
    uint8 positionEpoch;
    OrderPermit orderPermit;
    StandardPosition standardPosition;
    StandardLeveragePosition leveragePosition;
}

struct OrderPermit {
    uint256 nonce;
    uint256 deadline;
    bytes signature;
}

// Structure representing details of a single matched order
struct SingleOrder {
    address from;
    uint128 fromAmounts;
    uint128 fromBoundedLosses;
    uint128 toCollaterals;
    uint128 currentTokenPrice;
}

// Token and amount in a permit message.
struct TokenPermissions {
    // Token to transfer.
    IERC20 token;
    // Amount to transfer.
    uint256 amount;
}

// The permit2 message.
struct PermitTransferFrom {
    // Permitted token and amount.
    TokenPermissions permitted;
    // Unique identifier for this permit.
    uint256 nonce;
    // Expiration for this permit.
    uint256 deadline;
}

// Transfer details for permitTransferFrom().
struct SignatureTransferDetails {
    // Recipient of tokens.
    address to;
    // Amount to transfer.
    uint256 requestedAmount;
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { TokenId } from "../utils/LevrParams.sol";

interface ILevrChainLinkOracle {
    function updateOddsH(uint256 _oddsH) external;

    function updateOddsV(uint256 _oddsV) external;

    function updateOdds(uint256 _oddsH, uint256 _oddsV) external;

    function getOdds(uint256 gameId) external view returns (uint256, uint256);

    function setWinningToken(uint256 gameId, TokenId tokenId) external;

    function getWinningToken(uint256 gameId) external view returns (TokenId);

    function getMaxGameTime(uint256 gameId) external view returns (uint48);

    function getStartGameTime(uint256 gameId) external view returns (uint48);
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { NormalizationFactors } from "../LevrParams.sol";
import { ILevrChainLinkOracle } from "../../oracles/ILevrChainLinkOracle.sol";
import { LevrConfigHandlerErrors } from "../errors/LevrConfigHandlerErrors.sol";

interface ILevrConfigHandler is LevrConfigHandlerErrors {
    function positionFee() external view returns (uint256);

    function transactionFee() external view returns (uint256);

    function borrowFeeTheta() external view returns (uint256);

    function gameFactory() external view returns (address);

    function emissionHandler() external view returns (address);

    function rewardDistributor() external view returns (address);

    function poolVault() external view returns (address);

    function setPoolVault(address _poolVault) external;

    function setChainLinkOracleAddress(address chainLinkOracle) external;

    function setConfigs(address gameFactory, address emissionHandler, address rewardDistributor) external;

    function setBorrowFeeTheta(uint256 theta) external;

    function setPositionFee(uint256 positionFee) external;

    function setTransactionFee(uint256 _transactionFee) external;

    function chainLinkOracle() external view returns (ILevrChainLinkOracle);

    function getNormalizationFactor(uint256 gameId) external view returns (uint256);

    function setNormalizationFactor(uint256 gameId, uint256 normalizationFactor) external;
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { MarketPhase } from "../../utils/LevrParams.sol";
import { LevrGameFactoryErrors } from "../errors/LevrGameFactoryErrors.sol";
import { ILevrGame } from "src/game-markets/interfaces/ILevrGame.sol";
import { TokenId } from "src/utils/LevrParams.sol";

interface ILevrGameFactory is LevrGameFactoryErrors {
    //solhint-disable-next-line func-name-mixedcase
    function GAME_ADMIN() external view returns (bytes32);

    function totalGames() external view returns (uint256);

    function gameInstances(uint256) external view returns (address);

    function createGame(uint128 boundedLossH, uint128 boundedLossV, string calldata gameApiEndpoint) external returns (address);

    function setGameImplementation(address _gameImplementation) external;

    function updateConfigHandler(address _configHandler) external;

    function setPooledLiquidityVault(address _pooledLiquidityVault) external;

    function getGameInstance(uint256 gameId) external view returns (address);

    function setTransferAgents(address[] calldata agents) external;

    function removeTransferAgents(address[] calldata agents) external;

    function canTransfer(address agent) external view returns (bool);

    function startGameLiveMarket(uint256 gameId, uint48 startTime, uint48 gameDuration) external;

    function startGamePostMarket(uint256 gameId, uint48 endTime, TokenId winningTokenId) external;

    function pauseGame(uint256 gameId) external;

    function unpauseGame(uint256 gameId) external;

    function updateGameApiEndpoint(uint256 gameId, string calldata gameApiEndpoint) external;

    function batchLiquidate(
        uint256 gameId,
        address[] calldata users,
        uint8 epochId,
        uint8 leverage,
        TokenId tokenId,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface LevrConfigHandlerErrors {
    error LCH_INVALID_POSITION_TRANSACTION_FEE();
    error LCH_INVALID_NORMALIZATION_FACTOR();
    error LCH_ZERO_ADDRESS();
    error LCH_INVALID_GAME_ID();
    error LCH_DUPLICATE_ORACLE_ADDRESS();
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface LevrGameFactoryErrors {
    error LGF_ZERO_ADDRESS();
    error LGF_INVALID_GAME_ID();
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { MarketPhase, LevrLeveragePosition, LevrStandardPosition, TokenId, UpdatePositions } from "../../utils/LevrParams.sol";
import { ILevrEmissionHandler } from "../../utils/interfaces/ILevrEmissionHandler.sol";
import { ILevrConfigHandler } from "../../utils/interfaces/ILevrConfigHandler.sol";
import { LevrGameErrors } from "../errors/LevrGameErrors.sol";

interface ILevrGame is LevrGameErrors {
    event UpdatedMarketPhase(MarketPhase indexed previousMarketPhase, MarketPhase indexed newMarketPhase);
    event LiveMarketStarted(uint48 indexed startTime, uint48 indexed expectedGameTime);
    event PostMarketStarted(uint48 indexed endTime, uint48 indexed actualGameTime, TokenId indexed winningTeamToken);
    event LeveragePositionExited(
        address indexed user,
        uint8 indexed leverageRate,
        uint128 collateralAmount,
        uint128 payout,
        uint128 entryPrice,
        uint128 exitPrice
    );
    event LevrPositionOpened(TokenId indexed tokenId, uint256 indexed collateral, uint128 amountOfTokens);
    event LeveragePositionOpened(
        TokenId indexed tokenId,
        address indexed user,
        uint8 indexed leverageRate,
        uint128 amountOfTokensBought,
        uint128 positionSize
    );
    event LeveragePositionIncreased(
        TokenId indexed tokenId,
        address indexed user,
        uint8 indexed leverageRate,
        uint256 collateral
    );
    event LeveragePositionReduced(uint128 indexed topUpCollateral, uint128 indexed newLeverage);
    event TokensRedeemed(
        address indexed redeemer,
        uint256 gameId,
        uint128 amountOfTokens,
        uint128 totalPayout,
        uint128 totalFees
    );

    function configHandler() external view returns (ILevrConfigHandler);

    function emissionHandler() external view returns (ILevrEmissionHandler);

    function gameId() external view returns (uint256);

    function currentMarketPhase() external returns (MarketPhase);

    function updatePositions(UpdatePositions calldata updatePositions_) external;

    function factory() external view returns (address);

    function openPosition(TokenId tokenId, uint128 collateral, address receiver) external;

    function openLeveragePosition(TokenId tokenId, uint128 collateral, uint8 leverageRate, address receiver) external;

    function reduceLeverage(
        uint8 epochId,
        uint8 currentLeverage,
        TokenId tokenId,
        uint128 topUpCollateral,
        address user
    ) external;

    function redeemTokens(TokenId tokenId) external;

    function calculateBorrowFee(
        uint128 positionSize,
        uint128 positionFee,
        uint128 entryPrice
    ) external view returns (uint256 borrowFee);

    function liquidateLeveragePosition(address user, uint8 epochId, uint8 leverage, TokenId tokenId, address receiver) external;

    function startLiveMarket(uint48 startTime, uint48 gameTime) external;

    function startPostMarket(uint48 endTime, TokenId winningTokenId) external;

    function initialize(address _usdcToken, address _configHandler, uint256 _gameId, string calldata _gameApiEndpoint) external;

    function pause() external;

    function unpause() external;

    function updateApiEndpoint(string calldata _newMetaData) external;

    function getUserLeveragePosition(
        address user,
        uint8 epochId,
        uint8 leverageRate
    ) external view returns (LevrLeveragePosition memory);

    function calculateTopUpCollateral(
        address user,
        uint8 epochId,
        uint8 currentLeverage,
        uint8 newLeverage,
        TokenId tokenId
    ) external view returns (uint128);

    function getUserLeveragePositions(address user) external view returns (LevrLeveragePosition[][] memory allLeveragePositions);

    function getUserStandardBetPosition(address user) external view returns (LevrStandardPosition memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { Epoch, TokenId } from "../LevrParams.sol";
import { LevrEmissionHandlerErrors } from "../errors/LevrEmissionHandlerErrors.sol";

interface ILevrEmissionHandler is LevrEmissionHandlerErrors {
    function startNextEpoch(uint256 gameId, uint256 initalTotalTokens, bool isOptimalProfit, bool maxMintH) external;

    function getCurrentEpoch(uint256 gameId) external view returns (uint8);

    function getEpochDetails(uint256 gameId, uint256 _currentEpoch) external view returns (Epoch memory);

    function updateGameEpoch(uint256 gameId, uint256 currentEpoch, uint128 amountSold, TokenId tokenId) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface LevrGameErrors {
    error LG_PREGAME_TRANSFER_RESTRICTED();
    error LG_INVALID_MARKET_PHASE();
    error LG_PREGAME_SALE_NOT_STARTED();
    error LG_NOT_FACTORY();
    error LG_TOKENS_SOLD_OUT();
    error LG_NOT_WINNING_TOKEN();
    error LG_POSITION_NOT_OPEN();
    error LG_INVALID_SENDER();
    error LG_INVALID_LEVERAGE_RATE();
    error LG_INVALID_COLLATERAL_TOP_UP();
    error LG_FAILED_TO_TAKE_FEE();
    error LG_INVALID_TRANSFER_AGENT();
    error LG_INSUFFICIENT_POSITION_TRANSFER_AMOUNT();
    error LG_CANNOT_LIQUIDATE();
    error LG_ZERO_ADDRESS();
    error LG_INVALID_AMOUNT();
    error LG_TRANSFER_FAILED();
    error LG_INVALID_START_TIME();
    error LG_INVALID_GAME_DURATION();
    error LG_GAME_ALREADY_STARTED();
    error LG_INVALID_END_TIME();
    error LG_GAME_ALREADY_ENDED();
    error LG_NO_REDEEMABLE_TOKENS();
    error LG_CANNOT_CLEAR_FOR_WINNING_TOKEN();
    error LG_INVALID_ARRAY_LENGTH();
    error LG_SIGNATURE_EXPIRED();
    error LG_INVALID_SIGNER();
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface LevrEmissionHandlerErrors {
    error LEH_ZERO_AMOUNT();
    error LEH_EPOCH_NOT_SOLD_OUT();
    error LEH_NOT_GAME_CONTRACT();
}