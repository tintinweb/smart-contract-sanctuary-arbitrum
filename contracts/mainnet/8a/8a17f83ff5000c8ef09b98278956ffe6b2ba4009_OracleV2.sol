// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from "@oz/access/Ownable.sol";
// import { OraclePyth } from "./OraclePyth.sol";
import { IBattleState, BattleKey } from "./interfaces/battle/IBattleState.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { ICOracle } from "./interfaces/ICOracle.sol";

/// @title Oracle
/// @notice Retrieves underlying asset prices used for settling options.
contract OracleV2 is Ownable, IOracle {
    mapping(string symbol => address oraclePyth) private _externalOracleOf;
    mapping(address => mapping(uint256 => uint256)) public fixPrices;
    uint256 public MAX_PRICE_DELAY = 1 hours;

    event MaxPriceDelayChanged(uint256 oldValue, uint256 newValue);
    event ExternalOracleSet(string[] symbol, address[] oracle);

    /// @notice Defines the underlying asset symbol and oracle address for a pool. Only called by the owner.
    /// @param symbols The asset symbol for which to retrieve a price feed
    /// @param oracles_ The external oracle address
    function setExternalOracle(string[] calldata symbols, address[] calldata oracles_) external onlyOwner {
        require(symbols.length == oracles_.length, "symbols not match oracles");
        for (uint256 i = 0; i < symbols.length; i++) {
            require(oracles_[i] != address(0), "Zero Address");
            _externalOracleOf[symbols[i]] = oracles_[i];
        }
        emit ExternalOracleSet(symbols, oracles_);
    }

    function setFixPrice(string memory symbol, uint256 ts, uint256 price) external onlyOwner {
        require(_externalOracleOf[symbol] != address(0), "not support symbol");
        fixPrices[_externalOracleOf[symbol]][ts] = price;
    }

    function setMaxPriceDelay(uint256 delay) external onlyOwner {
        require(MAX_PRICE_DELAY != delay, "same value");
        emit MaxPriceDelayChanged(MAX_PRICE_DELAY, delay);
        MAX_PRICE_DELAY = delay;
    }

    /// @notice Gets and computes price from external oracles
    /// @param cOracleAddr the contract address for a chainlink price feed
    /// @param ts Timestamp for the asset price
    /// @return price The retrieved price
    function getPriceByExternal(address cOracleAddr, uint256 ts) external view override returns (uint256 price, uint256 actualTs) {
        require(block.timestamp >= ts, "price not exist");
        require(cOracleAddr != address(0), "Zero Address");
        // If the price remains unreported or inaccessible an hour post expiry, the closest available price will be fixed based on the external oracle
        // data.
        BattleKey memory key = IBattleState(msg.sender).battleKey();
        uint256 cPrice = ICOracle(cOracleAddr).priceOf(key.underlying, ts);
        if (block.timestamp - ts > MAX_PRICE_DELAY && cPrice == 0) {
            require(fixPrices[cOracleAddr][ts] != 0, "setting price");
            price = fixPrices[cOracleAddr][ts];
            actualTs = ts;
        } else {
            price = cPrice;
            actualTs = ts;
        }
    }

    function getCOracle(string memory symbol) public view override returns (address) {
        address cOracle = _externalOracleOf[symbol];
        require(cOracle != address(0), "not exist");
        return cOracle;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

pragma solidity ^0.8.0;

import "core/types/common.sol";

interface IBattleState {
    /// @notice Retrieves position info for a given position key
    /// @param pk positon key
    /// @param info Information about the position
    function positions(bytes32 pk) external view returns (PositionInfo memory info);

    /// @notice The result of battle.
    /// @return result check different battle result type in enums.sol
    function battleOutcome() external view returns (Outcome);

    /// @notice Returns the BattleKey that uniquely identifies a battle
    function battleKey() external view returns (BattleKey memory key);

    /// @notice Get Manager address in this battle
    function manager() external view returns (address);

    /// @notice BaseInfo includes current sqrtPriceX96, current tick
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, bool unlocked);

    function spearAndShield() external view returns (address, address);

    function startAndEndTS() external view returns (uint256, uint256);

    function spearBalanceOf(address account) external view returns (uint256 amount);

    function shieldBalanceOf(address account) external view returns (uint256 amount);

    function spear() external view returns (address);

    function shield() external view returns (address);

    function getInsideLast(int24 tickLower, int24 tickUpper) external view returns (GrowthX128 memory);

    function fee() external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Get price from external oracle
/// @notice Retrieves underlying asset prices used for settling options.
interface IOracle {
    function getPriceByExternal(address cOracleAddr, uint256 ts) external view returns (uint256 price_, uint256 actualTs);

    function getCOracle(string memory symbol) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICOracle {
    function priceOf(string memory symbol, uint256 ts) external view returns (uint256 price_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LiquidityType, Outcome, TradeType } from "core/types/enums.sol";

struct BattleKey {
    /// @dev The address of the token used as collateral in the battle, eg: usdt/usdc
    address collateral;
    /// @dev The underlying asset symbol, such as btc, eth, etc
    string underlying;
    /// @dev end time of the battle
    uint256 expiries;
    /// @dev strike price of the options within the pool
    uint256 strikeValue;
}

struct Fee {
    /// @dev The fee ratio taken on every trade
    uint256 transactionFee;
    /// @dev The portion of transaction fee that goes to the protocol
    uint256 protocolFee;
    /// @dev The exercise fee paid by those who call exercise()
    uint256 exerciseFee;
}

struct GrowthX128 {
    /// @dev The all-time growth in transaction fee, per unit of liquidity, in collateral token
    uint256 fee;
    /// @dev The all-time growth in the received collateral inputs, per unit of liquidity, as options premium
    uint256 collateralIn;
    /// @dev The all-time growth in Spear token outputs per unit of liquidity
    uint256 spearOut;
    /// @dev The all-time growth in Shield token outputs per unit of liquidity
    uint256 shieldOut;
}

/// @notice tracking the GrowthX128 amounts owed to a position
struct Owed {
    /// @dev The amount of transaction fee owed to the position as of the last computation
    uint128 fee;
    /// @dev The collateral inputs owed to the position as of the last computation
    uint128 collateralIn;
    /// @dev The Spear token outputs owed to the position as of the last computation
    uint128 spearOut;
    /// @dev The Shield token outputs owed to the position as of the last computation
    uint128 shieldOut;
}

struct TickInfo {
    /// @dev The total amount of liquidity that the pool uses either at tickLower or tickUpper
    uint128 liquidityGross;
    /// @dev The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    int128 liquidityNet;
    /// @dev The GrowthX128 info recorded on the other side of the tick from the current tick
    GrowthX128 outside;
    /// @dev Whether the tick is initialized
    bool initialized;
}

struct PositionInfo {
    /// @dev The amount of usable liquidity
    uint128 liquidity;
    /// @dev The GrowthX128 info per unit of liquidity inside the a position's bound as of the last action
    GrowthX128 insideLast;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum LiquidityType {
    COLLATERAL,
    SPEAR,
    SHIELD
}

enum Outcome {
    ONGOING, // battle is ongoing
    SPEAR_WIN, // calls expire in-the-money
    SHIELD_WIN // puts expire in-the-money

}

enum TradeType {
    BUY_SPEAR,
    BUY_SHIELD
}