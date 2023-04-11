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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";

contract ContextUpgradeable is Initializable {
	function __Context_init() internal onlyInitializing {}

	function __Context_init_unchained() internal onlyInitializing {}

	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

		bool isTopLevelCall = !initializing;
		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/// @dev Returns true if and only if the function is running in the constructor
	function isConstructor() private view returns (bool) {
		// extcodesize checks the size of the code stored in an address, and
		// address returns the current address. Since the code is still not
		// deployed when running a constructor, any checks on its code size will
		// yield zero, making it an effective way to detect if a contract is
		// under construction or not.
		uint256 cs;
		//solium-disable-next-line
		assembly {
			cs := extcodesize(address())
		}
		return cs == 0;
	}

	modifier onlyInitializing() {
		require(initializing, "Initializable: contract is not initializing");
		_;
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";

contract OwnableUpgradeable is Initializable, ContextUpgradeable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function __Ownable_init() internal onlyInitializing {
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal onlyInitializing {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);

	function latestTimestamp() external view returns (uint256);

	function latestRound() external view returns (uint256);

	function getAnswer(uint256 roundId) external view returns (int256);

	function getTimestamp(uint256 roundId) external view returns (uint256);

	event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

	event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBaseOracle {
	function latestAnswer() external view returns (uint256 price);

	function latestAnswerInEth() external view returns (uint256 price);

	function update() external;

	function canUpdate() external view returns (bool);

	function consult() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.12;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface IChainlinkAggregator is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../dependencies/openzeppelin/upgradeability/Initializable.sol";
import "../../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import "../../interfaces/IChainlinkAggregator.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../interfaces/IBaseOracle.sol";

contract ChainlinkV3Adapter is IBaseOracle, AggregatorV3Interface, OwnableUpgradeable {
	AggregatorV3Interface public ethChainlinkFeed;
	AggregatorV3Interface public tokenChainlinkFeed;
	address public token;

	uint256 public ethLatestTimestamp;
	uint256 public tokenLatestTimestamp;

	function initialize(address _token, address _ethChainlinkFeed, address _tokenChainlinkFeed) external initializer {
		require(_token != address(0), "token is 0 address");
		require(_ethChainlinkFeed != address(0), "ethChainlinkFeed is 0 address");
		require(_tokenChainlinkFeed != address(0), "tokenChainlinkFeed is 0 address");
		ethChainlinkFeed = AggregatorV3Interface(_ethChainlinkFeed);
		tokenChainlinkFeed = AggregatorV3Interface(_tokenChainlinkFeed);
		token = _token;
		__Ownable_init();
	}

	function latestAnswer() public view returns (uint256 price) {
		(, int256 answer, , , ) = tokenChainlinkFeed.latestRoundData();
		require(answer > 0, "Price must be positive");
		price = uint256(answer);
	}

	function latestAnswerInEth() public view returns (uint256 price) {
		(, int256 tokenAnswer, , , ) = tokenChainlinkFeed.latestRoundData();
		(, int256 ethAnswer, , , ) = ethChainlinkFeed.latestRoundData();
		require(tokenAnswer > 0 && ethAnswer > 0, "Price must be positive");
		price = (uint256(tokenAnswer) * (10 ** 8)) / uint256(ethAnswer);
	}

	function update() public {
		(, , , ethLatestTimestamp, ) = ethChainlinkFeed.latestRoundData();
		(, , , tokenLatestTimestamp, ) = tokenChainlinkFeed.latestRoundData();
	}

	function canUpdate() public view returns (bool) {
		return false;
	}

	function consult() public view returns (uint256 price) {
		return latestAnswer();
	}

	function version() external view returns (uint256) {
		return tokenChainlinkFeed.version();
	}

	function decimals() external view returns (uint8) {
		return tokenChainlinkFeed.decimals();
	}

	function description() external view returns (string memory) {
		return tokenChainlinkFeed.description();
	}

	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		return tokenChainlinkFeed.getRoundData(_roundId);
	}

	function latestRoundData()
		public
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		return tokenChainlinkFeed.latestRoundData();
	}
}