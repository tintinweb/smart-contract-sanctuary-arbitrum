// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
pragma solidity 0.8.17;

error IsNotWstETH();

contract ArbitroveBase {
	// address public contractOwner;
	address constant wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
	// address public wstETH = 0x69C735ce75B3Dec7c1Cdf21306628A6eb1b81346;
	address public wstETH_;

	modifier onlyWstETH(address _asset) {
		if (wstETH != _asset) {
			revert IsNotWstETH();
		}
		_;
	}

	function _isWstETH(address _asset) internal pure {
		if (wstETH != _asset) {
			revert IsNotWstETH();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract BaseMath {
	uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract CheckContract {
	function checkContract(address _account) internal view {
		require(_account != address(0), "Account cannot be zero address");

		uint256 size;
		assembly {
			size := extcodesize(_account)
		}
		require(size > 0, "Account code size cannot be zero");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library YouMath {

	uint256 internal constant DECIMAL_PRECISION = 1 ether;

	/* Precision for Nominal ICR (independent of price). Rationale for the value:
	 *
	 * - Making it “too high” could lead to overflows.
	 * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
	 *
	 * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
	 * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
	 *
	 */
	uint256 internal constant NICR_PRECISION = 1e20;

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

	/*
	 * Multiply two decimal numbers and use normal rounding rules:
	 * -round product up if 19'th mantissa digit >= 5
	 * -round product down if 19'th mantissa digit < 5
	 *
	 * Used only inside the exponentiation, _decPow().
	 */
	function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
		uint256 prod_xy = x * y;

		decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
	}

	/*
	 * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
	 *
	 * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
	 *
	 * Called by two functions that represent time in units of minutes:
	 * 1) TroveManager._calcDecayedBaseRate
	 * 2) CommunityIssuance._getCumulativeIssuanceFraction
	 *
	 * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
	 * "minutes in 1000 years": 60 * 24 * 365 * 1000
	 *
	 * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
	 * negligibly different from just passing the cap, since:
	 *
	 * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
	 * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
	 */
	function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
		if (_minutes > 525600000) {
			_minutes = 525600000;
		} // cap to avoid overflow

		if (_minutes == 0) {
			return DECIMAL_PRECISION;
		}

		uint256 y = DECIMAL_PRECISION;
		uint256 x = _base;
		uint256 n = _minutes;

		// Exponentiation-by-squaring
		while (n > 1) {
			if (n % 2 == 0) {
				x = decMul(x, x);
				n = n / 2;
			} else {
				// if (n % 2 != 0)
				y = decMul(x, y);
				x = decMul(x, x);
				n = (n - 1) / 2;
			}
		}

		return decMul(x, y);
	}

	function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a - _b : _b - _a;
	}

	function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
		if (_debt > 0) {
			return _coll * NICR_PRECISION / _debt;
		}
		// Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return 2**256 - 1;
		}
	}

	function _computeCR(
		uint256 _coll,
		uint256 _debt,
		uint256 _price
	) internal pure returns (uint256) {
		if (_debt > 0) {
			uint256 newCollRatio = _coll * _price / _debt;

			return newCollRatio;
		}
		// Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return type(uint256).max;
		}
	}
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity 0.8.17;

interface IPriceFeed {
	struct ChainlinkResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
		uint8 originalDecimals;
	}

	struct TellorResponse {
		bool ifRetrieve;
		uint256 value;
		uint256 timestamp;
		bool success;
	}

	struct RegisterOracle {
		AggregatorV3Interface chainLinkOracle;
		bool isRegistered;
		bytes32 tellorId;
	}

	enum Status {
		chainlinkWorking,
		usingTellorChainlinkUntrusted,
		bothOraclesUntrusted,
		usingTellorChainlinkFrozen,
		usingChainlinkTellorUntrusted
	}

	// --- Events ---
	event PriceFeedStatusChanged(Status newStatus);
	event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
	event LastGoodIndexUpdated(address indexed token, uint256 _lastGoodIndex);
	event RegisteredNewOracle(address token, address chainLinkAggregator, bytes32 tellorId);

	// --- Function ---
	function addOracle(address _token, address _chainlinkOracle, bytes32 _tellorId) external;

	function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITellorCaller {
	function getTellorCurrentValue(
		bytes32 _queryId
	) external view returns (bool, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "./Interfaces/IPriceFeed.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/BaseMath.sol";
import "./Dependencies/YouMath.sol";
import "./Interfaces/ITellorCaller.sol";
import "./Dependencies/ArbitroveBase.sol";

contract PriceFeed is OwnableUpgradeable, CheckContract, BaseMath, IPriceFeed, ArbitroveBase {

	string public constant NAME = "PriceFeed";
	address public constant FLAG_ARBITRUM_SEQ_OFFLINE =
		0xa438451D6458044c3c8CD2f6f31c91ac882A6d91;

	FlagsInterface public chainlinkFlags;
	AggregatorV3Interface public sequencerUptimeFeed;
	ITellorCaller public tellorCaller;

	// Use to convert a price answer to an 18-digit precision uint
	uint256 public constant TARGET_DIGITS = 8;
	uint256 public constant TELLOR_DIGITS = 18;

	uint256 public constant TIMEOUT = 20 hours;

	uint256 private constant GRACE_PERIOD_TIME = 3600;

	// Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
	uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%
	uint256 public constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%

	bool public isInitialized;

	address public adminContract;

	AggregatorV3Interface public chainLinkETHUsdOracle;

	IPriceFeed.Status public status;
	mapping(address => RegisterOracle) public registeredOracles;
	mapping(address => uint256) public lastGoodPrice;

	event SetAdminContract(address _admin);

	// constructor() {
	// 	_disableInitializers();
	// }

	modifier isController() {
		require(msg.sender == owner() || msg.sender == adminContract, "Invalid Permission");
		_;
	}

	function setAddresses(
		address _sequencerUptimeFeed,
		address _adminContract,
		address _tellorCaller,
		address _chainLinkETHUsdOracle,
		address _wstEthAddress
	) external initializer {
		require(!isInitialized);
		checkContract(_sequencerUptimeFeed);
		checkContract(_adminContract);
		checkContract(_tellorCaller);
		checkContract(_chainLinkETHUsdOracle);
		checkContract(_wstEthAddress);
		isInitialized = true;

		__Ownable_init();

		//wstETH = _wstEthAddress;
		adminContract = _adminContract;
		sequencerUptimeFeed = AggregatorV3Interface(_sequencerUptimeFeed);
		chainLinkETHUsdOracle = AggregatorV3Interface(_chainLinkETHUsdOracle);
		tellorCaller = ITellorCaller(_tellorCaller);
		status = Status.chainlinkWorking;
	}

	function setAdminContract(address _admin) external onlyOwner {
		require(_admin != address(0));
		adminContract = _admin;
		emit SetAdminContract(_admin);
	}

	function addOracle(
		address _token,
		address _chainlinkOracle,
		bytes32 _tellorId
	) external override isController {
		AggregatorV3Interface priceOracle = AggregatorV3Interface(_chainlinkOracle);

		registeredOracles[_token] = RegisterOracle(priceOracle, true, _tellorId);

		(
			ChainlinkResponse memory chainlinkResponse,
			ChainlinkResponse memory prevChainlinkResponse,
			ChainlinkResponse memory chainLinkETHUsdResponse,
			ChainlinkResponse memory prevChainlinkEthUsdResponse
		) = _getChainlinkResponses(priceOracle);

		require(
			!_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) &&
				!_chainlinkIsFrozen(chainlinkResponse) &&
				!_chainlinkIsBroken(chainLinkETHUsdResponse, prevChainlinkEthUsdResponse) &&
				!_chainlinkIsFrozen(chainLinkETHUsdResponse),
			"PriceFeed: Chainlink must be working and current"
		);

		_storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);

		emit RegisteredNewOracle(_token, _chainlinkOracle, _tellorId);
	}

	function fetchPrice(address _token) external override onlyWstETH(_token) returns (uint256) {
		RegisterOracle storage oracle = registeredOracles[_token];
		require(oracle.isRegistered, "Oracle is not registered!");

		(
			ChainlinkResponse memory chainlinkResponse,
			ChainlinkResponse memory prevChainlinkResponse,
			ChainlinkResponse memory chainLinkETHUsdResponse,
			ChainlinkResponse memory prevChainlinkEthUsdResponse
		) = _getChainlinkResponses(oracle.chainLinkOracle);

		TellorResponse memory tellorResponse = _getCurrentTellorResponse(oracle.tellorId);

		uint256 lastTokenGoodPrice = lastGoodPrice[_token];
		bool tellorIsBroken = _tellorIsBroken(tellorResponse);
		bool tellorIsFrozen = _tellorIsFrozen(tellorResponse);
		bool chainlinkIsBroken = _chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) || _chainlinkIsBroken(chainLinkETHUsdResponse, prevChainlinkEthUsdResponse);
		bool chainlinkIsFrozen = _chainlinkIsFrozen(chainlinkResponse) || _chainlinkIsFrozen(chainLinkETHUsdResponse);

		// --- CASE 1: System fetched last price from Chainlink  ---
		if (status == Status.chainlinkWorking) {
			// If Chainlink is broken, try Tellor
			if (chainlinkIsBroken) {
				// If Tellor is broken then both oracles are untrusted, so return the last good price
				if (tellorIsBroken) {
					_changeStatus(Status.bothOraclesUntrusted);
					return lastTokenGoodPrice;
				}
				
				_changeStatus(Status.usingTellorChainlinkUntrusted);
				/*
				 * If Tellor is only frozen but otherwise returning valid data, return the last good price.
				 * Tellor may need to be tipped to return current data.
				 */
				if (tellorIsFrozen) {
					return lastTokenGoodPrice;
				}

				// If Chainlink is broken and Tellor is working, switch to Tellor and return current Tellor price
				return _storeTellorPrice(_token, tellorResponse);
			}

			// If Chainlink is frozen, try Tellor
			if (chainlinkIsFrozen) {
				// If Tellor is broken too, remember Tellor broke, and return last good price
				if (tellorIsBroken) {
					_changeStatus(Status.usingChainlinkTellorUntrusted);
					return lastTokenGoodPrice;
				}

				// If Tellor is frozen or working, remember Chainlink froze, and switch to Tellor
				_changeStatus(Status.usingTellorChainlinkFrozen);

				if (tellorIsFrozen) {
					return lastTokenGoodPrice;
				}

				// If Tellor is working, use it
				return _storeTellorPrice(_token, tellorResponse);
			}

			// If Chainlink price has changed by > 50% between two consecutive rounds, compare it to Tellor's price
			if (
				_chainlinkPriceChangeAboveMax(
					chainlinkResponse,
					prevChainlinkResponse,
					chainLinkETHUsdResponse,
					prevChainlinkEthUsdResponse
				)
			) {
				// If Tellor is broken, both oracles are untrusted, and return last good price
				if (tellorIsBroken) {
					_changeStatus(Status.bothOraclesUntrusted);
					return lastTokenGoodPrice;
				}

				// If Tellor is frozen, switch to Tellor and return last good price
				if (tellorIsFrozen) {
					_changeStatus(Status.usingTellorChainlinkUntrusted);
					return lastTokenGoodPrice;
				}

				/*
				 * If Tellor is live and both oracles have a similar price, conclude that Chainlink's large price deviation between
				 * two consecutive rounds was likely a legitmate market price movement, and so continue using Chainlink
				 */
				if (
					_bothOraclesSimilarPrice(chainlinkResponse, tellorResponse, chainLinkETHUsdResponse)
				) {
					return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
				}

				// If Tellor is live but the oracles differ too much in price, conclude that Chainlink's initial price deviation was
				// an oracle failure. Switch to Tellor, and use Tellor price
				_changeStatus(Status.usingTellorChainlinkUntrusted);
				return _storeTellorPrice(_token, tellorResponse);
			}

			// If Chainlink is working and Tellor is broken, remember Tellor is broken
			if (tellorIsBroken) {
				_changeStatus(Status.usingChainlinkTellorUntrusted);
			}

			// If Chainlink is working, return Chainlink current price (no status change)
			return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
		}

		// --- CASE 2: The system fetched last price from Tellor ---
		if (status == Status.usingTellorChainlinkUntrusted) {
			// If both Tellor and Chainlink are live, unbroken, and reporting similar prices, switch back to Chainlink
			if (
				_bothOraclesLiveAndUnbrokenAndSimilarPrice(
					chainlinkResponse,
					prevChainlinkResponse,
					tellorResponse,
					chainLinkETHUsdResponse,
					prevChainlinkEthUsdResponse
				)
			) {
				_changeStatus(Status.chainlinkWorking);
				return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
			}

			if (tellorIsBroken) {
				_changeStatus(Status.bothOraclesUntrusted);
				return lastTokenGoodPrice;
			}

			/*
			* If Tellor is only frozen or broken but otherwise returning valid data, just return the last good price.
			* Tellor may need to be tipped to return current data.
			*/
			if (tellorIsFrozen) {
				_changeStatus(Status.bothOraclesUntrusted);
				return lastTokenGoodPrice;
			}

			// Otherwise, use Tellor price
			return _storeTellorPrice(_token, tellorResponse);
		}

		// --- CASE 3: Both oracles were untrusted at the last price fetch ---
		if (status == Status.bothOraclesUntrusted) {
			/*
			 * If both oracles are now live, unbroken and similar price, we assume that they are reporting
			 * accurately, and so we switch back to Chainlink.
			 */
			if (
				_bothOraclesLiveAndUnbrokenAndSimilarPrice(
					chainlinkResponse,
					prevChainlinkResponse,
					tellorResponse,
					chainLinkETHUsdResponse,
					prevChainlinkEthUsdResponse
				)
			) {
				_changeStatus(Status.chainlinkWorking);
				return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
			}

			// Otherwise, return the last good price - both oracles are still untrusted (no status change)
			return lastTokenGoodPrice;
		}

		// --- CASE 4: Using Tellor, and Chainlink is frozen ---
		if (status == Status.usingTellorChainlinkFrozen) {
			if (chainlinkIsBroken) {
				// If both Oracles are broken, return last good price
				if (tellorIsBroken) {
					_changeStatus(Status.bothOraclesUntrusted);
					return lastTokenGoodPrice;
				}

				// If Chainlink is broken, remember it and switch to using Tellor
				_changeStatus(Status.usingTellorChainlinkUntrusted);

				if (tellorIsFrozen) {
					return lastTokenGoodPrice;
				}

				// If Tellor is working, return Tellor current price
				return _storeTellorPrice(_token, tellorResponse);
			}

			if (chainlinkIsFrozen) {
				// if Chainlink is frozen and Tellor is broken, remember Tellor broke, and return last good price
				if (tellorIsBroken) {
					_changeStatus(Status.usingChainlinkTellorUntrusted);
					return lastTokenGoodPrice;
				}

				// If both are frozen, just use lastGoodPrice
				if (tellorIsFrozen) {
					_changeStatus(Status.bothOraclesUntrusted);
					return lastTokenGoodPrice;
				}

				_changeStatus(Status.usingTellorChainlinkFrozen);

				// if Chainlink is frozen and Tellor is working, keep using Tellor (no status change)
				return _storeTellorPrice(_token, tellorResponse);
			}

			// if Chainlink is live and Tellor is broken or frozen, remember Tellor broke, and return Chainlink price
			if (tellorIsBroken) {
				_changeStatus(Status.usingChainlinkTellorUntrusted);
				return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
			}

			if (tellorIsFrozen) {
				_changeStatus(Status.chainlinkWorking);
				return lastTokenGoodPrice;
			}

			// If Chainlink is live and Tellor is working, compare prices. Switch to Chainlink
			// if prices are within 5%, and return Chainlink price.
			if (
				_bothOraclesSimilarPrice(chainlinkResponse, tellorResponse, chainLinkETHUsdResponse)
			) {
				_changeStatus(Status.chainlinkWorking);
				return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
			}

			// Otherwise if Chainlink is live but price not within 5% of Tellor, distrust Chainlink, and return Tellor price
			_changeStatus(Status.usingTellorChainlinkUntrusted);
			return _storeTellorPrice(_token, tellorResponse);
		}

		// --- CASE 5: Using Chainlink, Tellor is untrusted ---
		if (status == Status.usingChainlinkTellorUntrusted) {
			// If Chainlink breaks, now both oracles are untrusted
			if (chainlinkIsBroken) {
				_changeStatus(Status.bothOraclesUntrusted);
				return lastTokenGoodPrice;
			}

			// If Chainlink is frozen, return last good price (no status change)
			if (chainlinkIsFrozen) {
				if (!tellorIsFrozen && !tellorIsBroken) {
					_changeStatus(Status.usingTellorChainlinkFrozen);
					return lastTokenGoodPrice;
				}

				_changeStatus(Status.bothOraclesUntrusted);
				return lastTokenGoodPrice;
			}

			// If Chainlink and Tellor are both live, unbroken and similar price, switch back to chainlinkWorking and return Chainlink price
			if (
				_bothOraclesLiveAndUnbrokenAndSimilarPrice(
					chainlinkResponse,
					prevChainlinkResponse,
					tellorResponse,
					chainLinkETHUsdResponse,
					prevChainlinkEthUsdResponse
				)
			) {
				_changeStatus(Status.chainlinkWorking);
				return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
			}

			// If Chainlink is live but deviated >50% from it's previous price and Tellor is still untrusted, switch
			// to bothOraclesUntrusted and return last good price
			if (
				_chainlinkPriceChangeAboveMax(
					chainlinkResponse,
					prevChainlinkResponse,
					chainLinkETHUsdResponse,
					prevChainlinkEthUsdResponse
				)
			) {
				_changeStatus(Status.bothOraclesUntrusted);
				return lastTokenGoodPrice;
			}

			// Otherwise if Chainlink is live and deviated <50% from it's previous price and Tellor is still untrusted,
			// return Chainlink price (no status change)
			return _storeChainlinkPrice(_token, chainlinkResponse, chainLinkETHUsdResponse);
		}

		return lastTokenGoodPrice;
	}

	function _getCurrentTellorResponse(
		bytes32 _queryId
	) internal view returns (TellorResponse memory tellorResponse) {
		if (_queryId == bytes32(0)) {
			return (tellorResponse);
		}

		try tellorCaller.getTellorCurrentValue(_queryId) returns (
			bool ifRetrieve,
			uint256 value,
			uint256 _timestampRetrieved
		) {
			tellorResponse.ifRetrieve = ifRetrieve;
			tellorResponse.value = value;
			tellorResponse.timestamp = _timestampRetrieved;
			tellorResponse.success = true;

			return (tellorResponse);
		} catch {
			// If call to Tellor reverts, return a zero response with success = false
			return (tellorResponse);
		}
	}

	function _tellorIsBroken(TellorResponse memory _response) internal view returns (bool) {
		// Check for response call reverted
		if (!_response.success) {
			return true;
		}
		// Check for an invalid timeStamp that is 0, or in the future
		if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {
			return true;
		}
		// Check for zero price
		if (_response.value == 0) {
			return true;
		}

		return false;
	}

	function _tellorIsFrozen(
		TellorResponse memory _tellorResponse
	) internal view returns (bool) {
		return block.timestamp - _tellorResponse.timestamp > TIMEOUT;
	}

	function _bothOraclesLiveAndUnbrokenAndSimilarPrice(
		ChainlinkResponse memory _chainlinkResponse,
		ChainlinkResponse memory _prevChainlinkResponse,
		TellorResponse memory _tellorResponse,
		ChainlinkResponse memory _chainlinkEthUsdResponse,
		ChainlinkResponse memory _prevChainlinkEthUsdResponse
	) internal view returns (bool) {
		// Return false if either oracle is broken or frozen
		if (
			_tellorIsBroken(_tellorResponse) ||
			_tellorIsFrozen(_tellorResponse) ||
			_chainlinkIsBroken(_chainlinkResponse, _prevChainlinkResponse) ||
			_chainlinkIsFrozen(_chainlinkResponse) ||
			_chainlinkIsBroken(_chainlinkEthUsdResponse, _prevChainlinkEthUsdResponse) ||
			_chainlinkIsFrozen(_chainlinkEthUsdResponse)
		) {
			return false;
		}

		return
			_bothOraclesSimilarPrice(_chainlinkResponse, _tellorResponse, _chainlinkEthUsdResponse);
	}

	function _bothOraclesSimilarPrice(
		ChainlinkResponse memory _chainlinkResponse,
		TellorResponse memory _tellorResponse,
		ChainlinkResponse memory _chainlinkEthUsdResponse
	) internal pure returns (bool) {
		uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
			_wstEthPrice(_chainlinkResponse, _chainlinkEthUsdResponse),
			_chainlinkEthUsdResponse.decimals
		);
		uint256 scaledTellorPrice = _scaleTellorPriceByDigits(_tellorResponse.value);

		// Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the reference for the calculation.
		uint256 minPrice = YouMath._min(scaledTellorPrice, scaledChainlinkPrice);
		uint256 maxPrice = YouMath._max(scaledTellorPrice, scaledChainlinkPrice);
		uint256 percentPriceDifference = (maxPrice - minPrice) * DECIMAL_PRECISION / minPrice;

		/*
		 * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
		 * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
		 */
		return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
	}

	function _scaleTellorPriceByDigits(uint256 _price) internal pure returns (uint256) {
		return _price / 10 ** (TELLOR_DIGITS - TARGET_DIGITS);
	}

	function _getChainlinkResponses(
		AggregatorV3Interface _chainLinkOracle
	)
		internal
		view
		returns (
			ChainlinkResponse memory currentChainlink,
			ChainlinkResponse memory prevChainLink,
			ChainlinkResponse memory currentChainlinkEthUsd,
			ChainlinkResponse memory prevChainLinkEthUsd
		)
	{
		currentChainlink = _getCurrentChainlinkResponse(_chainLinkOracle, false, 0);
		prevChainLink = _getPrevChainlinkResponse(
			_chainLinkOracle,
			currentChainlink.roundId,
			currentChainlink.originalDecimals,
			false, 0
		);
		currentChainlinkEthUsd = _getCurrentChainlinkResponse(chainLinkETHUsdOracle, true, 8);
		prevChainLinkEthUsd = _getPrevChainlinkResponse(
			chainLinkETHUsdOracle,
			currentChainlinkEthUsd.roundId,
			currentChainlinkEthUsd.originalDecimals,
			true,
			8
		);
	}

	function _chainlinkIsBroken(
		ChainlinkResponse memory _currentResponse,
		ChainlinkResponse memory _prevResponse
	) internal view returns (bool) {
		return _badChainlinkResponse(_currentResponse) || _badChainlinkResponse(_prevResponse);
	}

	function _badChainlinkResponse(
		ChainlinkResponse memory _response
	) internal view returns (bool) {
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

	function _chainlinkIsFrozen(
		ChainlinkResponse memory _response
	) internal view returns (bool) {
		return block.timestamp - _response.timestamp > TIMEOUT;
	}

	function _chainlinkPriceChangeAboveMax(
		ChainlinkResponse memory _currentResponse,
		ChainlinkResponse memory _prevResponse,
		ChainlinkResponse memory _currentETHUsdResponse,
		ChainlinkResponse memory _prevETHUsdResponse
	) internal pure returns (bool) {
		uint256 currentScaledPrice = _scaleChainlinkPriceByDigits(
			_wstEthPrice(_currentResponse, _currentETHUsdResponse),
			_currentETHUsdResponse.decimals
		);
		uint256 prevScaledPrice = _scaleChainlinkPriceByDigits(
			_wstEthPrice(_prevResponse, _prevETHUsdResponse),
			_prevETHUsdResponse.decimals
		);

		uint256 minPrice = YouMath._min(currentScaledPrice, prevScaledPrice);
		uint256 maxPrice = YouMath._max(currentScaledPrice, prevScaledPrice);

		/*
		 * Use the larger price as the denominator:
		 * - If price decreased, the percentage deviation is in relation to the the previous price.
		 * - If price increased, the percentage deviation is in relation to the current price.
		 */
		uint256 percentDeviation = (maxPrice - minPrice) * DECIMAL_PRECISION / maxPrice;

		// Return true if price has more than doubled, or more than halved.
		return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
	}

	function _scaleChainlinkPriceByDigits(
		uint256 _price,
		uint256 _answerDigits
	) internal pure returns (uint256) {
		uint256 price;
		if (_answerDigits >= TARGET_DIGITS) {
			// Scale the returned price value down to You's target precision
			price = _price / 10 ** (_answerDigits - TARGET_DIGITS);
		} else if (_answerDigits < TARGET_DIGITS) {
			// Scale the returned price value up to You's target precision
			price = _price * 10 ** (TARGET_DIGITS - _answerDigits);
		}
		return price;
	}

	function _changeStatus(Status _status) internal {
		status = _status;
		emit PriceFeedStatusChanged(_status);
	}

	function _storeTellorPrice(
		address _token,
		TellorResponse memory _tellorResponse
	) internal returns (uint256) {
		uint256 scaledTellorPrice = _scaleTellorPriceByDigits(_tellorResponse.value);
		_storePrice(_token, scaledTellorPrice);

		return scaledTellorPrice;
	}

	function _storeChainlinkPrice(
		address _token,
		ChainlinkResponse memory _chainlinkResponse,
		ChainlinkResponse memory _chainlinkEthUsdResponse
	) internal returns (uint256) {
		uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
			_wstEthPrice(_chainlinkResponse, _chainlinkEthUsdResponse),
			_chainlinkEthUsdResponse.decimals
		);

		_storePrice(_token, scaledChainlinkPrice);
		return scaledChainlinkPrice;
	}

	function _storePrice(address _token, uint256 _currentPrice) internal {
		lastGoodPrice[_token] = _currentPrice;
		emit LastGoodPriceUpdated(_token, _currentPrice);
	}

	// --- Oracle response wrapper functions ---

	function _getCurrentChainlinkResponse(
		AggregatorV3Interface _priceAggregator,
		bool reverse,
		uint8 targetDecimals
	) public view returns (ChainlinkResponse memory chainlinkResponse) {
		// prettier-ignore
		(
				/*uint80 roundID*/,
				int256 answer,
				uint256 startedAt,
				/*uint256 updatedAt*/,
				/*uint80 answeredInRound*/
		) = sequencerUptimeFeed.latestRoundData();

		// Answer == 0: Sequencer is up
		// Answer == 1: Sequencer is down
		bool isSequencerUp = answer == 0;
		if (!isSequencerUp) {
			return chainlinkResponse;
		}

		// Make sure the grace period has passed after the
		// sequencer is back up.
		uint256 timeSinceUp = block.timestamp - startedAt;
		if (timeSinceUp <= GRACE_PERIOD_TIME) {
			return chainlinkResponse;
		}

		if (reverse) {
			try _priceAggregator.decimals() returns (uint8 decimals) {
				chainlinkResponse.decimals = decimals;
			} catch {
				return chainlinkResponse;
			}

			try _priceAggregator.latestRoundData() returns (
				uint80 roundId,
				int256 data,
				uint256 /* startedAt */,
				uint256 timestamp,
				uint80 /* answeredInRound */
			) {
				chainlinkResponse.roundId = roundId;
				chainlinkResponse.answer = int256(int256((10 ** chainlinkResponse.decimals) * (10 ** chainlinkResponse.decimals)) / data / int256(10 ** (chainlinkResponse.decimals - targetDecimals)));
				chainlinkResponse.originalDecimals = chainlinkResponse.decimals;
				chainlinkResponse.decimals = targetDecimals;
				chainlinkResponse.timestamp = timestamp;
				chainlinkResponse.success = true;
				return chainlinkResponse;
			} catch {
				return chainlinkResponse;
			}
		}
		try _priceAggregator.decimals() returns (uint8 decimals) {
			chainlinkResponse.decimals = decimals;
		} catch {
			return chainlinkResponse;
		}

		try _priceAggregator.latestRoundData() returns (
			uint80 roundId,
			int256 data,
			uint256 /* startedAt */,
			uint256 timestamp,
			uint80 /* answeredInRound */
		) {
			chainlinkResponse.roundId = roundId;
			chainlinkResponse.originalDecimals = chainlinkResponse.decimals;
			chainlinkResponse.answer = data;
			chainlinkResponse.timestamp = timestamp;
			chainlinkResponse.success = true;
			return chainlinkResponse;
		} catch {
			return chainlinkResponse;
		}
	}

	function _getPrevChainlinkResponse(
		AggregatorV3Interface _priceAggregator,
		uint80 _currentRoundId,
		uint8 _currentDecimals,
		bool reverse,
		uint8 targetDecimals
	) public view returns (ChainlinkResponse memory prevChainlinkResponse) {
		if (_currentRoundId == 0) {
			return prevChainlinkResponse;
		}

		if (reverse) {
			unchecked {
				try _priceAggregator.getRoundData(_currentRoundId - 1) returns (
					uint80 roundId,
					int256 answer,
					uint256 /* startedAt */,
					uint256 timestamp,
					uint80 /* answeredInRound */
				) {
					prevChainlinkResponse.roundId = roundId;
					prevChainlinkResponse.answer = int256(int256((10 ** _currentDecimals) * (10 ** _currentDecimals)) / answer / int256(10 ** (_currentDecimals - targetDecimals)));
					prevChainlinkResponse.timestamp = timestamp;
					prevChainlinkResponse.decimals = targetDecimals;
					prevChainlinkResponse.success = true;
					return prevChainlinkResponse;
				} catch {
					return prevChainlinkResponse;
				}
			}
		}

		unchecked {
			try _priceAggregator.getRoundData(_currentRoundId - 1) returns (
				uint80 roundId,
				int256 answer,
				uint256 /* startedAt */,
				uint256 timestamp,
				uint80 /* answeredInRound */
			) {
				prevChainlinkResponse.roundId = roundId;
				prevChainlinkResponse.answer = answer;
				prevChainlinkResponse.timestamp = timestamp;
				prevChainlinkResponse.decimals = _currentDecimals;
				prevChainlinkResponse.success = true;
				return prevChainlinkResponse;
			} catch {
				return prevChainlinkResponse;
			}
		}
	}

	function _wstEthPrice(
		ChainlinkResponse memory _chainLinkWstEthEthResponse,
		ChainlinkResponse memory _chainlinkEthUsdResponse
	) internal pure returns (uint256) {
		return
			(uint256(_chainLinkWstEthEthResponse.answer) *
				uint256(_chainlinkEthUsdResponse.answer)) /
			10 ** (_chainLinkWstEthEthResponse.decimals);
	}
}