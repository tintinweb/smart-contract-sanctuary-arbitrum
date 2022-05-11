// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../libs/TimeoutChecker.sol";
import "./BaseWrapper.sol";

contract ChainlinkWrapper is BaseWrapper, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;

	event OracleAdded(address indexed _token, address _priceAggregator, address _indexAggregator);

	struct SavedChainlinkResponse {
		uint256 price;
		uint256 index;
		uint256 lastUpdate;
	}

	struct OracleResponse {
		uint80 roundId;
		uint256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	struct Aggregators {
		AggregatorV3Interface price;
		AggregatorV3Interface index;
	}

	uint256 constant TIMEOUT = 4 hours;

	address public flagSEQOffline;
	FlagsInterface public flagsContract;

	mapping(address => Aggregators) public aggregators;
	mapping(address => SavedChainlinkResponse) public savedResponses;
	mapping(address => SavedChainlinkResponse) public lastSavedResponses;

	function setUp(address _flagSEQ, address _flagContract)
		external
		notNull(_flagSEQ)
		notNull(_flagContract)
		initializer
	{
		__Ownable_init();
		flagSEQOffline = _flagSEQ;
		flagsContract = FlagsInterface(_flagContract);
	}

	function setFlagSEQ(address _newFlagSEQ) external onlyOwner notNull(_newFlagSEQ) {
		flagSEQOffline = _newFlagSEQ;
	}

	function setFlagContract(address _flagsContract) external onlyOwner notNull(_flagsContract) {
		require(_flagsContract != address(0), INVALID_ADDRESS);
		flagsContract = FlagsInterface(_flagsContract);
	}

	function addOracle(
		address _token,
		address _priceAggregator,
		address _indexAggregator
	) external onlyOwner isContract(_priceAggregator) isNullableOrContract(_indexAggregator) {
		aggregators[_token] = Aggregators(
			AggregatorV3Interface(_priceAggregator),
			AggregatorV3Interface(_indexAggregator)
		);

		(OracleResponse memory currentResponse, ) = _getResponses(_token, false);

		(OracleResponse memory currentResponseIndex, ) = _getResponses(_token, true);

		if (_isBadOracleResponse(currentResponse)) {
			revert ResponseFromOracleIsInvalid(_token, _priceAggregator);
		}

		if (_isBadOracleResponse(currentResponseIndex)) {
			revert ResponseFromOracleIsInvalid(_token, _indexAggregator);
		}

		SavedChainlinkResponse storage response = savedResponses[_token];

		response.price = currentResponse.answer;
		response.index = currentResponseIndex.answer;
		response.lastUpdate = currentResponse.timestamp;

		lastSavedResponses[_token] = response;

		emit OracleAdded(_token, _priceAggregator, _indexAggregator);
	}

	function removeOracle(address _token) external onlyOwner {
		delete aggregators[_token];
	}

	function retriveSavedResponses(address _token) external override returns (SavedResponse memory savedResponse) {
		fetchPrice(_token);

		SavedChainlinkResponse memory current = savedResponses[_token];
		SavedChainlinkResponse memory last = lastSavedResponses[_token];

		savedResponse.currentPrice = _sanitizePrice(current.price, current.index);
		savedResponse.lastPrice = _sanitizePrice(last.price, last.index);
		savedResponse.lastUpdate = current.lastUpdate;
	}

	function fetchPrice(address _token) public override {
		(OracleResponse memory currentResponse, OracleResponse memory previousResponse) = _getResponses(_token, false);

		(OracleResponse memory currentResponseIndex, OracleResponse memory previousResponseIndex) = _getResponses(
			_token,
			true
		);

		SavedChainlinkResponse storage response = savedResponses[_token];
		SavedChainlinkResponse storage lastResponse = lastSavedResponses[_token];

		if (!_isOracleBroken(currentResponse, previousResponse)) {
			if (!TimeoutChecker.isTimeout(currentResponse.timestamp, TIMEOUT)) {
				response.price = currentResponse.answer;
				response.lastUpdate = currentResponse.timestamp;
			}

			lastResponse.price = previousResponse.answer;
			lastResponse.lastUpdate = previousResponse.timestamp;
		}

		if (!_isOracleBroken(currentResponseIndex, previousResponseIndex)) {
			response.index = currentResponseIndex.answer;
			lastResponse.index = previousResponseIndex.answer;
		}
	}

	function getCurrentPrice(address _token) external view override returns (uint256) {
		SavedChainlinkResponse memory responses = savedResponses[_token];
		return _sanitizePrice(responses.price, responses.index);
	}

	function getLastPrice(address _token) external view override returns (uint256) {
		SavedChainlinkResponse memory responses = lastSavedResponses[_token];
		return _sanitizePrice(responses.price, responses.index);
	}

	function getExternalPrice(address _token) external view override returns (uint256) {
		(OracleResponse memory currentResponse, ) = _getResponses(_token, false);
		(OracleResponse memory currentResponseIndex, ) = _getResponses(_token, true);

		return _sanitizePrice(currentResponse.answer, currentResponseIndex.answer);
	}

	function _sanitizePrice(uint256 price, uint256 index) internal pure returns (uint256) {
		return price.mul(index).div(1e18);
	}

	function _getResponses(address _token, bool _isIndex)
		internal
		view
		returns (OracleResponse memory currentResponse, OracleResponse memory lastResponse)
	{
		Aggregators memory tokenAggregators = aggregators[_token];

		if (address(tokenAggregators.price) == address(0)) {
			revert TokenIsNotRegistered(_token);
		}

		AggregatorV3Interface oracle = _isIndex ? tokenAggregators.index : tokenAggregators.price;

		if (address(oracle) == address(0) && _isIndex) {
			currentResponse = OracleResponse(1, 1 ether, block.timestamp, true, 18);
			lastResponse = currentResponse;
		} else {
			currentResponse = _getCurrentChainlinkResponse(oracle);
			lastResponse = _getPrevChainlinkResponse(oracle, currentResponse.roundId, currentResponse.decimals);
		}

		return (currentResponse, lastResponse);
	}

	function _getCurrentChainlinkResponse(AggregatorV3Interface _oracle)
		internal
		view
		returns (OracleResponse memory oracleResponse)
	{
		if (flagsContract.getFlag(flagSEQOffline)) {
			return oracleResponse;
		}

		try _oracle.decimals() returns (uint8 decimals) {
			oracleResponse.decimals = decimals;
		} catch {
			return oracleResponse;
		}

		try _oracle.latestRoundData() returns (
			uint80 roundId,
			int256 answer,
			uint256, /* startedAt */
			uint256 timestamp,
			uint80 /* answeredInRound */
		) {
			oracleResponse.roundId = roundId;
			oracleResponse.answer = scalePriceByDigits(uint256(answer), oracleResponse.decimals);
			oracleResponse.timestamp = timestamp;
			oracleResponse.success = true;
			return oracleResponse;
		} catch {
			return oracleResponse;
		}
	}

	function _getPrevChainlinkResponse(
		AggregatorV3Interface _priceAggregator,
		uint80 _currentRoundId,
		uint8 _currentDecimals
	) internal view returns (OracleResponse memory prevOracleResponse) {
		if (_currentRoundId == 0) {
			return prevOracleResponse;
		}

		unchecked {
			try _priceAggregator.getRoundData(_currentRoundId - 1) returns (
				uint80 roundId,
				int256 answer,
				uint256, /* startedAt */
				uint256 timestamp,
				uint80 /* answeredInRound */
			) {
				prevOracleResponse.roundId = roundId;
				prevOracleResponse.answer = scalePriceByDigits(uint256(answer), _currentDecimals);
				prevOracleResponse.timestamp = timestamp;
				prevOracleResponse.decimals = _currentDecimals;
				prevOracleResponse.success = true;
				return prevOracleResponse;
			} catch {
				return prevOracleResponse;
			}
		}
	}

	function _isOracleBroken(OracleResponse memory _response, OracleResponse memory _lastResponse)
		internal
		view
		returns (bool)
	{
		return (_isBadOracleResponse(_response) || _isBadOracleResponse(_lastResponse));
	}

	function _isBadOracleResponse(OracleResponse memory _response) internal view returns (bool) {
		if (!_response.success) {
			return true;
		}
		if (_response.roundId == 0) {
			return true;
		}
		if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {
			return true;
		}
		if (_response.answer <= 0) {
			return true;
		}

		return false;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

library TimeoutChecker {
	function isTimeout(uint256 timestamp, uint256 timeout) internal view returns (bool) {
		if (block.timestamp < timestamp) return true;
		return block.timestamp - timestamp > timeout;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;
import "../interfaces/IOracleWrapper.sol";

abstract contract BaseWrapper is IOracleWrapper {
	uint256 public constant TARGET_DIGITS = 18;
	string internal constant INVALID_ADDRESS = "Invalid Address";

	modifier notNull(address _address) {
		require(_address != address(0), INVALID_ADDRESS);
		_;
	}

	modifier isNullableOrContract(address _address) {
		if (_address != address(0)) {
			uint256 size;
			assembly {
				size := extcodesize(_address)
			}

			require(size > 0, "Address is not a contract");
		}

		_;
	}

	modifier isContract(address _address) {
		require(_address != address(0), INVALID_ADDRESS);

		uint256 size;
		assembly {
			size := extcodesize(_address)
		}

		require(size > 0, "Address is not a contract");
		_;
	}

	function scalePriceByDigits(uint256 _price, uint256 _answerDigits) internal pure returns (uint256) {
		return
			_answerDigits < TARGET_DIGITS
				? _price * (10**(TARGET_DIGITS - _answerDigits))
				: _price / (10**(_answerDigits - TARGET_DIGITS));
	}
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

interface IOracleWrapper {
	struct SavedResponse {
		uint256 currentPrice;
		uint256 lastPrice;
		uint256 lastUpdate;
	}

	error TokenIsNotRegistered(address _token);
	error ResponseFromOracleIsInvalid(address _token, address _oracle);

	/// @notice fetchPrice update the contract's storage price of a specific token.
	/// @dev This is mainly accessible for testing when you add a new oracle. retriveSavedResponses is also fetching the price
	/// @param _token the token you want to update.
	function fetchPrice(address _token) external;

	/// @notice retriveSavedResponses gets external oracles price and update the storage value.
	/// @dev Sad typo.
	/// @param _token the token you want to price. Needs to be supported by the wrapper.
	/// @return currentResponse The current price, the last price and the last update.
	function retriveSavedResponses(address _token) external returns (SavedResponse memory currentResponse);

	/// @notice getLastPrice gets the last price saved in the contract's storage
	/// @param _token the token you want to price. Needs to be supported by the wrapper
	/// @return the price in 1e18 format
	function getLastPrice(address _token) external view returns (uint256);

	/// @notice getCurrentPrice gets the current price saved in the contract's storage
	/// @param _token the token you want to price. Needs to be supported by the wrapper
	/// @return the price in 1e18 format
	function getCurrentPrice(address _token) external view returns (uint256);

	/// @notice getExternalPrice gets the price from the external oracle directly
	/// @dev This is for the front-end and have no secruity. So do not use it as information source in a smart contract
	/// @param _token the token you want to price. Needs to be supported by the wrapper
	/// @return the price in 1e18 format
	function getExternalPrice(address _token) external view returns (uint256);
}