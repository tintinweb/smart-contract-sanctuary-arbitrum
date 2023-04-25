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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.2;

interface IVaultPriceFeed {
    function getPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256);

    function getPrimaryPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256);

    function setPriceFeedConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        uint256 _spreadBasisPoints,
        bool _isStrictStable
    ) external;
}

pragma solidity ^0.8.2;

interface IChainlinkFlags {
    function getFlag(address) external view returns (bool);
}

pragma solidity ^0.8.2;

interface IPriceFeed {
    function description() external view returns (string memory);

    function aggregator() external view returns (address);

    function latestAnswer() external view returns (int256);

    function latestRound() external view returns (uint80);

    function getRoundData(
        uint80 roundId
    ) external view returns (uint80, int256, uint256, uint256, uint80);
}

pragma solidity ^0.8.2;

import "../interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "../oracle/interfaces/IChainlinkFlags.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultPriceFeed is IVaultPriceFeed, Ownable {
    using SafeMath for uint256;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

    mapping(address => address) public priceFeeds;
    mapping(address => uint256) public priceDecimals;
    mapping(address => uint256) public spreadBasisPoints;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping(address => bool) public strictStableTokens;

    mapping(address => uint256) public adjustmentBasisPoints;
    mapping(address => bool) public isAdjustmentAdditive;
    mapping(address => uint256) public lastAdjustmentTimings;

    address public chainlinkFlags;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    address public secondaryPriceFeed;
    uint256 public spreadThresholdBasisPoints = 30;

    // Identifier of the Sequencer offline flag on the Flags contract
    address private constant FLAG_ARBITRUM_SEQ_OFFLINE =
        address(
            bytes20(
                bytes32(
                    uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) -
                        1
                )
            )
        );

    /* OWNABLE Functions */
    function setChainlinkFlags(address _chainlinkFlags) external onlyOwner {
        chainlinkFlags = _chainlinkFlags;
    }

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external onlyOwner {
        require(
            lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) <
                block.timestamp,
            "VaultPriceFeed: adjustment frequency exceeded"
        );
        require(
            _adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS,
            "invalid _adjustmentBps"
        );
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }

    function setSpreadBasisPoints(
        address _token,
        uint256 _spreadBasisPoints
    ) external onlyOwner {
        require(
            _spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS,
            "VaultPriceFeed: invalid _spreadBasisPoints"
        );
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }

    function setSpreadThresholdBasisPoints(
        uint256 _spreadThresholdBasisPoints
    ) external onlyOwner {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external onlyOwner {
        require(
            _priceSampleSpace > 0,
            "VaultPriceFeed: invalid _priceSampleSpace"
        );
        priceSampleSpace = _priceSampleSpace;
    }

    function setPriceFeedConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        uint256 _spreadBasisPoints,
        bool _isStrictStable
    ) external override onlyOwner {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        spreadBasisPoints[_token] = _spreadBasisPoints;
        strictStableTokens[_token] = _isStrictStable;
    }

    function setMaxStrictPriceDeviation(
        uint256 _maxStrictPriceDeviation
    ) external onlyOwner {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }

    /* END OWNABLE Functions */

    function getPrice(
        address _token,
        bool _maximise
    ) external view override returns (uint256) {
        uint256 price = getRawPrice(_token, _maximise);
        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(
                    BASIS_POINTS_DIVISOR
                );
            } else {
                price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(
                    BASIS_POINTS_DIVISOR
                );
            }
        }
        return price;
    }

    function getLatestChainlinkPrice(
        address _token
    ) public view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(
            priceFeedAddress != address(0),
            "VaultPriceFeed: invalid price feed"
        );

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        int256 price = priceFeed.latestAnswer();
        require(price > 0, "VaultPriceFeed: invalid price");

        return uint256(price);
    }

    function getPrimaryPrice(
        address _token,
        bool _maximise
    ) public view override returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(
            priceFeedAddress != address(0),
            "VaultPriceFeed: invalid price feed"
        );

        if (chainlinkFlags != address(0)) {
            bool isRaised = IChainlinkFlags(chainlinkFlags).getFlag(
                FLAG_ARBITRUM_SEQ_OFFLINE
            );
            if (isRaised) {
                // If flag is raised we shouldn't perform any critical operations
                revert("Chainlink feeds are not being updated");
            }
        }

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        uint256 price = 0;
        uint80 roundId = priceFeed.latestRound();

        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) {
                break;
            }
            uint256 p;

            if (i == 0) {
                int256 _p = priceFeed.latestAnswer();
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            } else {
                (, int256 _p, , , ) = priceFeed.getRoundData(roundId - i);
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            }

            if (price == 0) {
                price = p;
                continue;
            }

            if (_maximise && p > price) {
                price = p;
                continue;
            }

            if (!_maximise && p < price) {
                price = p;
            }
        }

        require(price > 0, "VaultPriceFeed: could not fetch price");
        // normalise price precision
        uint256 _priceDecimals = priceDecimals[_token];
        return price.mul(PRICE_PRECISION).div(10 ** _priceDecimals);
    }

    function getRawPrice(
        address _token,
        bool _maximise
    ) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD
                ? price.sub(ONE_USD)
                : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return
                price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(
                    BASIS_POINTS_DIVISOR
                );
        }

        return
            price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(
                BASIS_POINTS_DIVISOR
            );
    }
}