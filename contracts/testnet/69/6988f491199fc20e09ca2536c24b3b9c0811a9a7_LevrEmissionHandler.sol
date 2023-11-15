//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { Ownable2Step, Ownable } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { SafeCast } from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import { ILevrConfigHandler } from "./interfaces/ILevrConfigHandler.sol";
import { ILevrEmissionHandler } from "./interfaces/ILevrEmissionHandler.sol";
import { ILevrChainLinkOracle } from "../oracles/ILevrChainLinkOracle.sol";
import { ILevrGameFactory } from "../game-markets/interfaces/ILevrGameFactory.sol";
import { Epoch, TokenId } from "./LevrParams.sol";
import { OptimalEmissionMath, NonOptimalEmissionMath } from "../libraries/EmissionMath.sol";
import { LevrMath } from "../libraries/LevrMath.sol";

/// @title LevrEmissionHandler - Manages the emission (sale) of game tokens.
contract LevrEmissionHandler is ILevrEmissionHandler, Ownable2Step {
    ILevrConfigHandler public immutable configHandler;
    ILevrChainLinkOracle public immutable chainLinkOracle;

    mapping(uint256 gameId => mapping(uint256 currentEpoch => Epoch)) public gameEpochs;
    mapping(uint256 gameId => uint8 currentGameEpoch) public currentGameEpochs;

    event EpochStarted(
        uint256 indexed epoch,
        uint256 indexed priceH,
        uint256 indexed priceV,
        uint256 gameId,
        uint256 amountHTokens,
        uint256 amountVTokens
    );
    event EmissionStatusUpdated(uint8 indexed status);

    /// @param _configHandler Address of the Levr Config Handler contract.
    constructor(address _configHandler) Ownable(msg.sender) {
        configHandler = ILevrConfigHandler(_configHandler);
        chainLinkOracle = configHandler.chainLinkOracle();
    }

    /**
     * @dev Starts the next game token emission epoch.
     * @param gameId The ID of the game.
     * @param initialTotalTokens The initial total number of tokens for the epoch.
     * @param isOptimalProfit Whether the emission aims for optimal profit.
     * @param maxMintH Whether the emission aims to maximize the number of H tokens.
     */
    function startNextEpoch(
        uint256 gameId,
        uint256 initialTotalTokens,
        bool isOptimalProfit,
        bool maxMintH
    ) external override onlyOwner {
        if (initialTotalTokens == 0) revert LEH_ZERO_AMOUNT();
        uint8 currentEpoch = currentGameEpochs[gameId];

        Epoch memory prevEpoch = gameEpochs[gameId][currentEpoch];
        if ((prevEpoch.totalTokensEmitted != prevEpoch.totalTokenSold)) revert LEH_EPOCH_NOT_SOLD_OUT();

        (uint256 hOdds, uint256 vOdds) = chainLinkOracle.getOdds(gameId);

        uint256 nFactor = configHandler.getNormalizationFactor(gameId);

        uint256 priceH = LevrMath.calculateTokenPrice(nFactor, hOdds);
        uint256 priceV = LevrMath.calculateTokenPrice(nFactor, vOdds);

        (uint256 _amountTokensH, uint256 _amountTokensV) = isOptimalProfit
            ? OptimalEmissionMath.computeOptimalNumberOfTokens(initialTotalTokens, priceH, priceV)
            : NonOptimalEmissionMath.computeNumberOfTokens(initialTotalTokens, priceH, priceV, maxMintH);

        uint8 nextEpoch = ++currentEpoch;
        uint256 gameId_ = gameId;
        uint256 initialTotalTokens_ = initialTotalTokens;
        currentGameEpochs[gameId_] = nextEpoch;

        gameEpochs[gameId_][nextEpoch] = Epoch({
            totalTokensEmitted: SafeCast.toUint128(initialTotalTokens_),
            tokenHEmitted: SafeCast.toUint128(_amountTokensH),
            tokenVEmitted: SafeCast.toUint128(_amountTokensV),
            totalTokenSold: 0,
            tokenHSold: 0,
            tokenVSold: 0,
            priceH: SafeCast.toUint128(priceH),
            priceV: SafeCast.toUint128(priceV),
            emissionStarted: true,
            soldOut: false
        });

        emit EpochStarted(currentEpoch, priceH, priceV, gameId_, _amountTokensH, _amountTokensV);
    }

    // @dev Updates the current game epoch with emission details.
    /// @param gameId The ID of the game.
    /// @param currentEpoch The current epoch being updated.
    /// @param amountSold The amount of tokens sold.
    /// @param tokenId The token ID.
    function updateGameEpoch(uint256 gameId, uint256 currentEpoch, uint128 amountSold, TokenId tokenId) external override {
        ILevrGameFactory gameFactory = ILevrGameFactory(configHandler.gameFactory());
        address gameAddress = gameFactory.getGameInstance(gameId);

        if (msg.sender != gameAddress) revert LEH_NOT_GAME_CONTRACT();

        Epoch storage epoch = gameEpochs[gameId][currentEpoch];

        tokenId == TokenId.HOME ? epoch.tokenHSold += amountSold : epoch.tokenVSold += amountSold;

        epoch.totalTokenSold += SafeCast.toUint128(amountSold);

        if (epoch.totalTokensEmitted == epoch.totalTokenSold) epoch.soldOut = true;
    }

    function getEpochDetails(uint256 gameId, uint256 _currentEpoch) public view override returns (Epoch memory) {
        return gameEpochs[gameId][_currentEpoch];
    }

    function getCurrentEpoch(uint256 gameId) public view override returns (uint8) {
        return currentGameEpochs[gameId];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
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

pragma solidity ^0.8.21;

import { EmissionMathErrors } from "./errors/EmissionMathErrors.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

library OptimalEmissionMath {
    using Math for uint256;

    int256 public constant PRECISION = 1e18;

    /**
     * @notice validates the optimal number of tokens emitted in an epoch does not result in protocol loss.
     * @param nH the number of home tokens emitted
     * @param nV the number of away tokens emitted
     * @param pH the price of the home token in current epoch
     * @param pV the price of the away token in current epoch
     * @return true if the invariant holds and vice-versa
     */
    function validateNumberOfTokens(uint256 nH, uint256 nV, uint256 pH, uint256 pV) internal pure returns (bool) {
        uint256 hPart = nH.mulDiv(pH, uint256(PRECISION));

        uint256 vPart = nV.mulDiv(pV, uint256(PRECISION));

        uint256 addVH = hPart + vPart;

        bool eq1 = addVH >= nV;
        bool eq2 = addVH >= nH;

        return eq1 && eq2;
    }

    /**
     * @dev calculates an optimal ratio of the number of home team tokens and away team tokens to emit.
     * @param pH the price of the home team token
     * @param pV the price of the away team token
     * @return nHOnV - the optimal emission ratio
     */
    function calculatenHnV(uint256 pH, uint256 pV) public pure returns (int256 nHOnV) {
        if (pH == 0 || pV == 0) revert EmissionMathErrors.EM_ZERO_TOKEN_PRICE();

        int256 half = 5e17;
        int256 one = 1e18;
        int256 two = 2e18;

        //split numerator to sections: let alpha = (pH + pV), let beta = one + ( two(pH * pV) / 1e36 )
        // let numerator = alpha - beta
        int256 alpha = int256(pH + pV);
        int256 beta = one + ((two * int256(pH * pV)) / int256(1e36));
        int256 numerator = alpha - beta;
        //denominator = (pH * pH) / 1e18 - pH
        int256 denominator = (int256(pH * pH) / 1e18) - int256(pH);

        nHOnV = (half * ((numerator * PRECISION) / denominator)) / PRECISION;
    }

    /**
     * @notice calculates the optimal number of home and away tokens to mint per epoch given the total number of tokens to mint.
     * @param totalTokens the total number of tokens to emit in epoch
     * @param pH the price of home team token
     * @param pV the price of away team token
     * @return nH and nV - number of home tokens and away tokens respectively to mint.
     */
    function computeOptimalNumberOfTokens(
        uint256 totalTokens,
        uint256 pH,
        uint256 pV
    ) public pure returns (uint256 nH, uint256 nV) {
        int256 nHOnV = calculatenHnV(pH, pV);

        nV = uint256((int256(totalTokens) * PRECISION) / (nHOnV + PRECISION));

        ///@dev to avoid trailing decimals.
        nV = nV / uint256(PRECISION);
        nV = nV * uint256(PRECISION);

        ///@dev calculating nH.
        nH = totalTokens - nV;

        bool validRatio = validateNumberOfTokens(nH, nV, pH, pV);

        if (!validRatio) revert EmissionMathErrors.EM_INVALID_TOKEN_AMOUNTS();
        /**
         * -----------------------
         *     nHOnV = nH/nV
         *     totalTokens = nH + nV
         *     nH = nHOnV * nV
         *     totalTokens = nHOnV * nV + nV
         *     1e6 = 5/4*nv + nv
         *     1e6 = 2.25nV
         *     nv = 444,444.44444
         *     nH = 1e6 - nV => 555,555.55556
         */
    }
}

library NonOptimalEmissionMath {
    using Math for uint256;

    int256 internal constant PRECISION = 1e18;

    /**
     * @notice calculates the upper and lower bounds within which nH/nV must exists.
     * @param pV the price of the away token
     * @param pH the price of the home token
     * @return upperBound and lowerBound - the levels within which nH/nV must exists.
     */
    function calculateBounds(uint256 pV, uint256 pH) internal pure returns (int256 upperBound, int256 lowerBound) {
        if (pV == 0 || pH == 0) revert EmissionMathErrors.EM_ZERO_TOKEN_PRICE();

        upperBound = (int256(pV) * PRECISION) / (PRECISION - int256(pH));
        lowerBound = ((PRECISION - int256(pV)) * PRECISION) / int256(pH);
    }

    function calculateNVBounds(
        uint256 total,
        uint256 pV,
        uint256 pH
    ) public pure returns (uint256 lowestValue, uint256 highestValue) {
        (int256 upperBound, int256 lowerBound) = calculateBounds(pV, pH);

        ///@dev calculating nV.
        lowestValue = uint256((int256(total) * PRECISION) / (upperBound + PRECISION)); // lowest value Nv can be with 18 decimals for precision
        highestValue = uint256((int256(total) * PRECISION) / (lowerBound + PRECISION)); // highest value Nv can be with 18 decimals for precision

        return (lowestValue, highestValue);
    }

    function calculateNRatio(uint256 totalTokens, uint256 pV, uint256 pH, bool maxMintH) internal pure returns (uint256 nV) {
        (uint256 lowestnV, uint256 highestnV) = calculateNVBounds(totalTokens, pV, pH);
        nV = maxMintH ? lowestnV : highestnV;
    }

    function computeNumberOfTokens(
        uint256 totalTokens,
        uint256 pV,
        uint256 pH,
        bool maxMintH
    ) public pure returns (uint256 nH, uint256 nV) {
        nV = calculateNRatio(totalTokens, pV, pH, maxMintH);
        nH = totalTokens - nV;
        return (nH, nV);
    }
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { LevrMathErrors } from "./errors/LevrMathErrors.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { Epoch, LevrStandardPosition, TokenId, LevrLeveragePosition, StandardLeveragePosition } from "../utils/LevrParams.sol";

/**
 * @title LevrMath Library
 * @notice A library for mathematical calculations used in Levr Protocol.
 * @dev This library provides functions for calculating prices, bounded losses, liquidation prices,
 * and trader payouts.
 */
library LevrMath {
    using Math for uint256;
    using Math for uint128;

    uint256 public constant PRECISION = 1e18;

    function roundNumber(uint256 input) private pure returns (uint256) {
        // Divide by 1e16 to shift the decimal point in the number
        uint256 quotient = input / 1e16;
        // Get the remainder
        uint256 remainder = input % 1e16;
        // Check if remainder is >= 0.5. If it is, round up,
        if (remainder >= 5e15) {
            quotient++;
        }

        // Shift the decimal back to the original position by multiplying by 1e16
        return quotient * 1e16;
    }

    /**
     * @dev Calculates the token price based on the nFactor and odds.
     * @param nFactor The nFactor used in the calculation.
     * @param odd The odds used in the calculation.
     * @return The calculated token price.
     */
    function calculateTokenPrice(uint256 nFactor, uint256 odd) internal pure returns (uint256) {
        if (nFactor == 0) revert LevrMathErrors.LM_ZERO_N_FACTOR();
        if (odd == 0) revert LevrMathErrors.LM_ZERO_ODDS();

        return roundNumber(nFactor.mulDiv(PRECISION, odd));
    }

    /**
     * @dev Calculates the bounded loss for a leveraged position.
     * @param collateral The collateral amount.
     * @param leverageFactor The leverage factor.
     * @param price The token price.
     * @return The calculated bounded loss.
     */
    function calculateBoundedLoss(uint256 collateral, uint256 leverageFactor, uint256 price) internal pure returns (uint256) {
        uint256 numerator = collateral * leverageFactor;

        return numerator.mulDiv(PRECISION, price);
    }

    /**
     * @dev Calculates the liquidation price for a leveraged position.
     * @param tokenPrice The current token price.
     * @param leverageFactor The leverage factor.
     * @return The calculated liquidation price.
     */
    function calculateLiquidationPrice(uint128 tokenPrice, uint8 leverageFactor) internal pure returns (uint256) {
        uint256 firstPart = PRECISION.mulDiv(1, leverageFactor);

        uint256 subPart = PRECISION - firstPart;

        return tokenPrice.mulDiv(subPart, PRECISION);
    }

    /**
     * @dev Calculates the trader's payout for a leveraged position.
     * @return traderPayout The calculated trader's payout.
     */
    function calculateTraderPayout(
        uint128 entryPrice,
        uint128 currentTokenPrice,
        uint128 collateralAmount,
        uint128 positionSize
    ) internal pure returns (int128 traderPayout, uint128 platformPayout) {
        int128 priceDelta = int128(currentTokenPrice) - int128(entryPrice);

        int128 accruedValue = (int128(positionSize) * priceDelta) / int128(entryPrice);

        traderPayout = int128(collateralAmount) + accruedValue;

        platformPayout = positionSize - collateralAmount;

        if (traderPayout < 0) {
            ///@dev shit must have hit the fan
            revert LevrMathErrors.LM_INVALID_PAYOUT();
        }
    }
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

interface LevrEmissionHandlerErrors {
    error LEH_ZERO_AMOUNT();
    error LEH_EPOCH_NOT_SOLD_OUT();
    error LEH_NOT_GAME_CONTRACT();
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

interface EmissionMathErrors {
    error EM_ZERO_TOKEN_PRICE();
    error EM_INVALID_TOKEN_AMOUNTS();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface LevrMathErrors {
    error LM_ZERO_N_FACTOR();
    error LM_ZERO_ODDS();
    error LM_INVALID_PAYOUT();
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