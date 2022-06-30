// SPDX-License-Identifier:SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./IOracleWrapper.sol";

interface IOracleVerificationV1 {
	enum Status {
		PrimaryOracleWorking,
		SecondaryOracleWorking,
		BothUntrusted
	}

	struct RequestVerification {
		uint256 lastGoodPrice;
		IOracleWrapper.SavedResponse primaryResponse;
		IOracleWrapper.SavedResponse secondaryResponse;
	}

	function verify(RequestVerification memory request) external view returns (uint256);
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./BaseWrapper.sol";

import { IOracleVerificationV1 as Verificator } from "../interfaces/IOracleVerificationV1.sol";
import "../libs/TimeoutChecker.sol";
import "../libs/AddressCalls.sol";

/*
Classic Oracles, no fancy logic, just fetch the price and we are done.
*/
contract CustomOracleWrapper is BaseWrapper, OwnableUpgradeable {
	event OracleAdded(address indexed _token, address _externalOracle);

	struct OracleResponse {
		uint256 currentPrice;
		uint256 lastPrice;
		uint256 lastUpdate;
		bool success;
	}

	struct CustomOracle {
		address contractAddress;
		uint8 decimals;
		bytes callCurrentPrice;
		bytes callLastPrice;
		bytes callLastUpdate;
		bytes callDecimals;
	}

	uint256 public constant TIMEOUT = 4 hours;

	mapping(address => CustomOracle) public oracles;
	mapping(address => SavedResponse) public savedResponses;

	function setUp() external initializer {
		__Ownable_init();
	}

	function addOracle(
		address _token,
		address _externalOracle,
		uint8 _decimals,
		bytes memory _callCurrentPrice,
		bytes memory _callLastPrice,
		bytes memory _callLastUpdate,
		bytes memory _callDecimals
	) external onlyOwner isContract(_externalOracle) {
		require(_decimals != 0, "Invalid Decimals");

		oracles[_token] = CustomOracle(
			_externalOracle,
			_decimals,
			_callCurrentPrice,
			_callLastPrice,
			_callLastUpdate,
			_callDecimals
		);

		OracleResponse memory response = _getResponses(_token);

		if (_isBadOracleResponse(response)) {
			revert ResponseFromOracleIsInvalid(_token, _externalOracle);
		}

		savedResponses[_token].currentPrice = response.currentPrice;
		savedResponses[_token].lastPrice = response.lastPrice;
		savedResponses[_token].lastUpdate = response.lastUpdate;

		emit OracleAdded(_token, _externalOracle);
	}

	function removeOracle(address _token) external onlyOwner {
		delete oracles[_token];
		delete savedResponses[_token];
	}

	function retriveSavedResponses(address _token) external override returns (SavedResponse memory savedResponse) {
		fetchPrice(_token);
		return savedResponses[_token];
	}

	function fetchPrice(address _token) public override {
		OracleResponse memory oracleResponse = _getResponses(_token);
		SavedResponse storage responses = savedResponses[_token];

		if (!_isBadOracleResponse(oracleResponse) && !TimeoutChecker.isTimeout(oracleResponse.lastUpdate, TIMEOUT)) {
			responses.currentPrice = oracleResponse.currentPrice;
			responses.lastPrice = oracleResponse.lastPrice;
			responses.lastUpdate = oracleResponse.lastUpdate;
		}
	}

	function getLastPrice(address _token) external view override returns (uint256) {
		return savedResponses[_token].lastPrice;
	}

	function getCurrentPrice(address _token) external view override returns (uint256) {
		return savedResponses[_token].currentPrice;
	}

	function getExternalPrice(address _token) external view override returns (uint256) {
		OracleResponse memory oracleResponse = _getResponses(_token);
		return oracleResponse.currentPrice;
	}

	function _getResponses(address _token) internal view returns (OracleResponse memory response) {
		CustomOracle memory oracle = oracles[_token];
		if (oracle.contractAddress == address(0)) {
			revert TokenIsNotRegistered(_token);
		}

		uint8 decimals = _getDecimals(oracle);
		uint256 lastUpdate = _getLastUpdate(oracle);

		uint256 currentPrice = _getPrice(oracle.contractAddress, oracle.callCurrentPrice);
		uint256 lastPrice = _getPrice(oracle.contractAddress, oracle.callLastPrice);

		response.lastUpdate = lastUpdate;
		response.currentPrice = scalePriceByDigits(currentPrice, decimals);
		response.lastPrice = scalePriceByDigits(lastPrice, decimals);
		response.success = currentPrice != 0;

		return response;
	}

	function _getDecimals(CustomOracle memory _oracle) internal view returns (uint8) {
		(uint8 response, bool success) = AddressCalls.callReturnsUint8(_oracle.contractAddress, _oracle.callDecimals);

		return success ? response : _oracle.decimals;
	}

	function _getPrice(address _contractAddress, bytes memory _callData) internal view returns (uint256) {
		(uint256 response, bool success) = AddressCalls.callReturnsUint256(_contractAddress, _callData);

		return success ? response : 0;
	}

	function _getLastUpdate(CustomOracle memory _oracle) internal view returns (uint256) {
		(uint256 response, bool success) = AddressCalls.callReturnsUint256(
			_oracle.contractAddress,
			_oracle.callLastUpdate
		);

		return success ? response : block.timestamp;
	}

	function _isBadOracleResponse(OracleResponse memory _response) internal view returns (bool) {
		if (!_response.success) {
			return true;
		}
		if (_response.lastUpdate == 0 || _response.lastUpdate > block.timestamp) {
			return true;
		}
		if (_response.currentPrice <= 0 || _response.lastPrice <= 0) {
			return true;
		}

		return false;
	}
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

library AddressCalls {
	function callReturnsUint8(address _contract, bytes memory _callData) internal view returns (uint8, bool) {
		if (keccak256(_callData) == keccak256("")) return (0, false);

		(bool success, bytes memory response) = call(_contract, _callData);

		if (success) {
			return (abi.decode(response, (uint8)), true);
		}

		return (0, false);
	}

	function callReturnsUint256(address _contract, bytes memory _callData) internal view returns (uint256, bool) {
		if (keccak256(_callData) == keccak256("")) return (0, false);

		(bool success, bytes memory response) = call(_contract, _callData);

		if (success) {
			return (abi.decode(response, (uint256)), true);
		}

		return (0, false);
	}

	function callReturnsBytes32(address _contract, bytes memory _callData) internal view returns (bytes32, bool) {
		if (keccak256(_callData) == keccak256("")) return ("", false);

		(bool success, bytes memory response) = call(_contract, _callData);

		if (success) {
			return (abi.decode(response, (bytes32)), true);
		}

		return ("", false);
	}

	function call(address _contract, bytes memory _callData)
		internal
		view
		returns (bool success, bytes memory response)
	{
		if (keccak256(_callData) == keccak256("")) return (false, response);

		if (_contract == address(0)) {
			return (false, response);
		}

		return _contract.staticcall(_callData);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "lib/chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./interfaces/IPriceFeedV2.sol";
import { IOracleVerificationV1 as Verificator } from "./interfaces/IOracleVerificationV1.sol";
import "./interfaces/IOracleWrapper.sol";

contract PriceFeedV2 is IPriceFeedV2, OwnableUpgradeable {
	Verificator public verificator;

	mapping(address => bool) public accesses;
	mapping(address => uint256) public lastGoodPrice;
	mapping(address => Oracle) public oracles;

	modifier hasAccess() {
		require(accesses[msg.sender] || owner() == msg.sender, "Invalid access");
		_;
	}

	function setUp(address _verificator) external initializer {
		require(_verificator != address(0), "Invalid Verificator");

		__Ownable_init();
		verificator = Verificator(_verificator);
	}

	function setAccessTo(address _addr, bool _hasAccess) external onlyOwner {
		accesses[_addr] = _hasAccess;
		emit AccessChanged(_addr, _hasAccess);
	}

	function changeVerificator(address _verificator) external onlyOwner {
		require(_verificator != address(0), "Invalid Verificator");
		verificator = Verificator(_verificator);

		emit OracleVerificationChanged(_verificator);
	}

	function addOracle(
		address _token,
		address _primaryOracle,
		address _secondaryOracle
	) external override hasAccess {
		require(_primaryOracle != address(0), "Invalid Primary Oracle");

		Oracle storage oracle = oracles[_token];
		oracle.primaryWrapper = _primaryOracle;
		oracle.secondaryWrapper = _secondaryOracle;
		uint256 price = _getValidPrice(_token, _primaryOracle, _secondaryOracle);

		if (price == 0) revert("Oracle down");

		lastGoodPrice[_token] = price;

		emit OracleAdded(_token, _primaryOracle, _secondaryOracle);
	}

	function removeOracle(address _token) external hasAccess {
		delete oracles[_token];
		emit OracleRemoved(_token);
	}

	function fetchPrice(address _token) external override returns (uint256) {
		Oracle memory oracle = oracles[_token];
		require(oracle.primaryWrapper != address(0), "Oracle not found");

		uint256 goodPrice = _getValidPrice(_token, oracle.primaryWrapper, oracle.secondaryWrapper);
		lastGoodPrice[_token] = goodPrice;

		emit TokenPriceUpdated(_token, goodPrice);
		return goodPrice;
	}

	function getExternalPrice(address _token) external view override returns (uint256) {
		Oracle memory oracle = oracles[_token];
		require(oracle.primaryWrapper != address(0), "Oracle not found");
		return IOracleWrapper(oracle.primaryWrapper).getExternalPrice(_token);
	}

	function _getValidPrice(
		address _token,
		address primary,
		address secondary
	) internal returns (uint256) {
		IOracleWrapper.SavedResponse memory primaryResponse = IOracleWrapper(primary).retriveSavedResponses(_token);

		IOracleWrapper.SavedResponse memory secondaryResponse = secondary == address(0)
			? IOracleWrapper.SavedResponse(0, 0, 0)
			: IOracleWrapper(secondary).retriveSavedResponses(_token);

		return
			verificator.verify(
				Verificator.RequestVerification(lastGoodPrice[_token], primaryResponse, secondaryResponse)
			);
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface IPriceFeedV2 {
	event OracleAdded(address indexed _token, address _primaryWrappedOracle, address _secondaryWrappedOracle);
	event OracleRemoved(address indexed _token);
	event AccessChanged(address indexed _token, bool _hasAccess);
	event OracleVerificationChanged(address indexed _newVerificator);
	event TokenPriceUpdated(address indexed _token, uint256 _price);

	struct Oracle {
		address primaryWrapper;
		address secondaryWrapper;
	}

	/// @notice fetchPrice gets external oracles price and update the storage value.
	/// @param _token the token you want to price. Needs to be supported by the wrapper.
	/// @return Return the correct price in 1e18 based on the verifaction contract.
	function fetchPrice(address _token) external returns (uint256);

	/// @notice register oracles for a new token
	/// @param _primaryOracle the main oracle we want to fetch the price from.
	/// @param _secondaryOracle the fallback oracle if the main is having any issue @Nullable.
	function addOracle(
		address _token,
		address _primaryOracle,
		address _secondaryOracle
	) external;

	/// @notice getExternalPrice gets external oracles price and update the storage value.
	/// @param _token the token you want to price. Needs to be supported by the wrapper.
	/// @return The current price reflected on the external oracle in 1e18 format.
	function getExternalPrice(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

contract MockERC20 is ERC20Upgradeable {
	uint8 private DECIMALS;

	function setUp(
		string memory _name,
		string memory _symbol,
		uint8 _decimals
	) external initializer {
		__ERC20_init(_name, _symbol);
		DECIMALS = _decimals;
	}

	function mint(address account, uint256 amount) public {
		_mint(account, amount);
	}

	function burn(address account, uint256 amount) public {
		_burn(account, amount);
	}

	function transferInternal(
		address from,
		address to,
		uint256 value
	) public {
		_transfer(from, to, value);
	}

	function approveInternal(
		address owner,
		address spender,
		uint256 value
	) public {
		_approve(owner, spender, value);
	}

	function decimals() public view override returns (uint8) {
		if (DECIMALS == 0) return 18;
		return DECIMALS;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../interfaces/IPriceOracleV1.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract PriceOracleV1 is IPriceOracleV1, OwnableUpgradeable {
	string public ORACLE_NAME;

	uint256 public currentPrice;
	uint256 public lastPrice;
	uint256 public lastUpdate;
	uint8 public decimals;

	mapping(address => bool) private trusted;

	modifier isTrusted() {
		if (!trusted[msg.sender]) revert AddressNotTrusted();
		_;
	}

	modifier checkNonZeroAddress(address _addr) {
		if (_addr == address(0)) revert ZeroAddress();
		_;
	}

	function setUp(string memory _oracleName, uint8 _decimals) external initializer {
		__Ownable_init();

		ORACLE_NAME = _oracleName;
		decimals = _decimals;
	}

	function setDecimals(uint8 _decimals) external onlyOwner {
		decimals = _decimals;
	}

	function registerTrustedNode(address _node) external checkNonZeroAddress(_node) onlyOwner {
		trusted[_node] = true;
	}

	function unregisterTrustedNode(address _node) external checkNonZeroAddress(_node) onlyOwner {
		trusted[_node] = false;
	}

	function IsTrustedNode(address _node) external view returns (bool) {
		return trusted[_node];
	}

	function update(uint256 newPrice) external isTrusted {
		lastPrice = currentPrice;
		currentPrice = newPrice;
		lastUpdate = block.timestamp;
	}

	function getPriceData()
		external
		view
		returns (
			uint256 _currentPrice,
			uint256 _lastPrice,
			uint256 _lastUpdate
		)
	{
		return (currentPrice, lastPrice, lastUpdate);
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

/**
 * @dev Oracle contract for fetching a certain token price
 * Centralization issue still exists when adopting this contract for global uses
 * For special uses of supporting built-in protocols only
 */
interface IPriceOracleV1 {
	error AddressNotTrusted();
	error ZeroAddress();

	function setDecimals(uint8 _decimals) external;

	/**
	 * @dev register address as a trusted Node
	 * Trusted node has permission to update price data
	 */
	function registerTrustedNode(address _node) external;

	/**
	 * @dev remove address from tursted list
	 */
	function unregisterTrustedNode(address _node) external;

	/**
	 * @dev update price data
	 * This function is supposed to be called by trusted node only
	 */
	function update(uint256 newPrice) external;

	/**
	 * @dev returns current price data including price, round & time of last update
	 */
	function getPriceData()
		external
		view
		returns (
			uint256 _currentPrice,
			uint256 _lastPrice,
			uint256 _lastUpdate
		);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./interfaces/IOracleVerificationV1.sol";
import "./libs/TimeoutChecker.sol";

import "lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";

contract OracleVerificationV1 is IOracleVerificationV1 {
	using SafeMathUpgradeable for uint256;

	uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%
	uint256 public constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%
	uint256 public constant TIMEOUT = 4 hours;

	function verify(RequestVerification memory request) external view override returns (uint256 value) {
		bool isPrimaryOracleBroken = _isRequestBroken(request.primaryResponse);
		bool isSecondaryOracleBroken = _isRequestBroken(request.secondaryResponse);

		bool oraclesSamePrice = _bothOraclesSimilarPrice(
			request.primaryResponse.currentPrice,
			request.secondaryResponse.currentPrice
		);

		if (!isPrimaryOracleBroken) {
			// If Oracle price has changed by > 50% between two consecutive rounds
			if (_oraclePriceChangeAboveMax(request.primaryResponse.currentPrice, request.primaryResponse.lastPrice)) {
				if (isSecondaryOracleBroken) return request.lastGoodPrice;

				return oraclesSamePrice ? request.primaryResponse.currentPrice : request.secondaryResponse.currentPrice;
			}

			return request.primaryResponse.currentPrice;
		} else if (!isSecondaryOracleBroken) {
			if (
				_oraclePriceChangeAboveMax(request.secondaryResponse.currentPrice, request.secondaryResponse.lastPrice)
			) {
				return request.lastGoodPrice;
			}

			return request.secondaryResponse.currentPrice;
		}

		return request.lastGoodPrice;
	}

	function _isRequestBroken(IOracleWrapper.SavedResponse memory response) internal view returns (bool) {
		bool isTimeout = TimeoutChecker.isTimeout(response.lastUpdate, TIMEOUT);
		return isTimeout || response.currentPrice == 0 || response.lastPrice == 0;
	}

	function _oraclePriceChangeAboveMax(uint256 _currentResponse, uint256 _prevResponse)
		internal
		pure
		returns (bool)
	{
		uint256 minPrice = _min(_currentResponse, _prevResponse);
		uint256 maxPrice = _max(_currentResponse, _prevResponse);

		/*
		 * Use the larger price as the denominator:
		 * - If price decreased, the percentage deviation is in relation to the the previous price.
		 * - If price increased, the percentage deviation is in relation to the current price.
		 */
		uint256 percentDeviation = maxPrice.sub(minPrice).mul(1e18).div(maxPrice);

		// Return true if price has more than doubled, or more than halved.
		return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
	}

	function _bothOraclesSimilarPrice(uint256 _primaryOraclePrice, uint256 _secondaryOraclePrice)
		internal
		pure
		returns (bool)
	{
		if (_secondaryOraclePrice == 0 || _primaryOraclePrice == 0) return false;

		// Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the reference for the calculation.
		uint256 minPrice = _min(_primaryOraclePrice, _secondaryOraclePrice);
		uint256 maxPrice = _max(_primaryOraclePrice, _secondaryOraclePrice);

		uint256 percentPriceDifference = maxPrice.sub(minPrice).mul(1e18).div(minPrice);

		/*
		 * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
		 * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
		 */
		return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
	}

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}
}