// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./interface/IBaseVesta.sol";

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
@title BaseVesta
@notice Inherited by most of our contracts. It has a permission system & reentrency protection inside it.
@dev Binary Roles Recommended Slots
0x01  |  0x10
0x02  |  0x20
0x04  |  0x40
0x08  |  0x80

Don't use other slots unless you are familiar with bitewise operations
*/

abstract contract BaseVesta is IBaseVesta, OwnableUpgradeable {
	address internal constant RESERVED_ETH_ADDRESS = address(0);
	uint256 internal constant MAX_UINT256 = type(uint256).max;

	address internal SELF;
	bool private reentrencyStatus;

	mapping(address => bytes1) internal permissions;

	uint256[49] private __gap;

	modifier onlyContract(address _address) {
		if (_address.code.length == 0) revert InvalidContract();
		_;
	}

	modifier onlyContracts(address _address, address _address2) {
		if (_address.code.length == 0 || _address2.code.length == 0) {
			revert InvalidContract();
		}
		_;
	}

	modifier onlyValidAddress(address _address) {
		if (_address == address(0)) {
			revert InvalidAddress();
		}

		_;
	}

	modifier nonReentrant() {
		if (reentrencyStatus) revert NonReentrancy();
		reentrencyStatus = true;
		_;
		reentrencyStatus = false;
	}

	modifier hasPermission(bytes1 access) {
		if (permissions[msg.sender] & access == 0) revert InvalidPermission();
		_;
	}

	modifier hasPermissionOrOwner(bytes1 access) {
		if (permissions[msg.sender] & access == 0 && msg.sender != owner()) {
			revert InvalidPermission();
		}

		_;
	}

	modifier notZero(uint256 _amount) {
		if (_amount == 0) revert NumberIsZero();
		_;
	}

	function __BASE_VESTA_INIT() internal onlyInitializing {
		SELF = address(this);
		__Ownable_init();
	}

	function setPermission(address _address, bytes1 _permission)
		external
		override
		onlyOwner
	{
		_setPermission(_address, _permission);
	}

	function _clearPermission(address _address) internal virtual {
		_setPermission(_address, 0x00);
	}

	function _setPermission(address _address, bytes1 _permission) internal virtual {
		permissions[_address] = _permission;
		emit PermissionChanged(_address, _permission);
	}

	function getPermissionLevel(address _address)
		external
		view
		override
		returns (bytes1)
	{
		return permissions[_address];
	}

	function hasPermissionLevel(address _address, bytes1 accessLevel)
		public
		view
		override
		returns (bool)
	{
		return permissions[_address] & accessLevel != 0;
	}

	/** 
	@notice _sanitizeMsgValueWithParam is for multi-token payable function.
	@dev msg.value should be set to zero if the token used isn't a native token.
		address(0) is reserved for Native Chain Token.
		if fails, it will reverts with SanitizeMsgValueFailed(address _token, uint256 _paramValue, uint256 _msgValue).
	@return sanitizeValue which is the sanitize value you should use in your code.
	*/
	function _sanitizeMsgValueWithParam(address _token, uint256 _paramValue)
		internal
		view
		returns (uint256)
	{
		if (RESERVED_ETH_ADDRESS == _token) {
			return msg.value;
		} else if (msg.value == 0) {
			return _paramValue;
		}

		revert SanitizeMsgValueFailed(_token, _paramValue, msg.value);
	}

	function isContract(address _address) internal view returns (bool) {
		return _address.code.length > 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBaseVesta {
	error NonReentrancy();
	error InvalidPermission();
	error InvalidAddress();
	error CannotBeNativeChainToken();
	error InvalidContract();
	error NumberIsZero();
	error SanitizeMsgValueFailed(
		address _token,
		uint256 _paramValue,
		uint256 _msgValue
	);

	event PermissionChanged(address indexed _address, bytes1 newPermission);

	/** 
	@notice setPermission to an address so they have access to specific functions.
	@dev can add multiple permission by using | between them
	@param _address the address that will receive the permissions
	@param _permission the bytes permission(s)
	*/
	function setPermission(address _address, bytes1 _permission) external;

	/** 
	@notice get the permission level on an address
	@param _address the address you want to check the permission on
	@return accessLevel the bytes code of the address permission
	*/
	function getPermissionLevel(address _address) external view returns (bytes1);

	/** 
	@notice Verify if an address has specific permissions
	@param _address the address you want to check
	@param _accessLevel the access level you want to verify on
	@return hasAccess return true if the address has access
	*/
	function hasPermissionLevel(address _address, bytes1 _accessLevel)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { IVestaDexTrader } from "./interface/IVestaDexTrader.sol";
import "./model/TradingModel.sol";
import "./interface/dex/curve/ICurvePool.sol";

import "./interface/ITrader.sol";
import { IERC20, TokenTransferrer } from "./lib/token/TokenTransferrer.sol";
import "./BaseVesta.sol";

/**
	Selectors (bytes16(keccak256("TRADER_FILE_NAME")))
	UniswapV3Trader: 0x0fa74b3ade106cd68a66c0ef6dfe2154
	CurveTrader: 0x79402703bca5d67f15c4e7e9841e7231
	UniswapV2Trader: 0x7eb272ca6b6d9e128a5589927962ba6d
	GMXTrader: 0xdc7e0e193e9fe90a4a7fbe7a768857c8
 */
contract VestaDexTrader is IVestaDexTrader, TokenTransferrer, BaseVesta {
	mapping(address => bool) internal registeredTrader;
	mapping(bytes16 => address) internal tradersAddress;

	function setUp() external initializer {
		__BASE_VESTA_INIT();
	}

	function registerTrader(bytes16 _selector, address _trader) external onlyOwner {
		registeredTrader[_trader] = true;
		tradersAddress[_selector] = _trader;

		emit TraderRegistered(_trader, _selector);
	}

	function removeTrader(bytes16 _selector, address _trader) external onlyOwner {
		delete registeredTrader[_trader];
		delete tradersAddress[_selector];

		emit TraderRemoved(_trader);
	}

	function exchange(
		address _receiver,
		address _firstTokenIn,
		uint256 _firstAmountIn,
		ManualExchange[] calldata _requests
	)
		external
		override
		onlyValidAddress(_receiver)
		returns (uint256[] memory swapDatas_)
	{
		uint256 length = _requests.length;

		if (length == 0) revert EmptyRequest();

		swapDatas_ = new uint256[](length);

		_performTokenTransferFrom(_firstTokenIn, msg.sender, SELF, _firstAmountIn);

		ManualExchange memory currentManualExchange;
		uint256 nextIn = _firstAmountIn;
		address trader;

		for (uint256 i = 0; i < length; ++i) {
			currentManualExchange = _requests[i];
			trader = tradersAddress[currentManualExchange.traderSelector];

			if (trader == address(0)) {
				revert InvalidTraderSelector();
			}

			_tryPerformMaxApprove(currentManualExchange.tokenInOut[0], trader);

			nextIn = ITrader(trader).exchange(
				i == length - 1 ? _receiver : SELF,
				_getFulfilledSwapRequest(
					currentManualExchange.traderSelector,
					currentManualExchange.data,
					nextIn
				)
			);

			swapDatas_[i] = nextIn;
		}

		emit SwapExecuted(
			msg.sender,
			_receiver,
			[_firstTokenIn, _requests[length - 1].tokenInOut[1]],
			[_firstAmountIn, swapDatas_[length - 1]]
		);

		return swapDatas_;
	}

	function _getFulfilledSwapRequest(
		bytes16 _traderSelector,
		bytes memory _encodedData,
		uint256 _amountIn
	) internal pure returns (bytes memory) {
		//UniswapV3Trader
		if (_traderSelector == 0x0fa74b3ade106cd68a66c0ef6dfe2154) {
			//Setting UniswapV3SwapRequest::expectedAmountIn
			assembly {
				mstore(add(_encodedData, 0x80), _amountIn)
			}

			return _encodedData;
		}
		//Cruve
		else if (_traderSelector == 0x79402703bca5d67f15c4e7e9841e7231) {
			//Setting CurveSwapRequest::expectedAmountIn
			assembly {
				mstore(add(_encodedData, 0x80), _amountIn)
			}

			return _encodedData;
		} else {
			//Setting GenericSwapRequest::expectedAmountIn
			assembly {
				mstore(add(_encodedData, 0x60), _amountIn)
			}

			return _encodedData;
		}
	}

	function getAmountIn(uint256 _amountOut, ManualExchange[] calldata _requests)
		external
		view
		override
		returns (uint256 amountIn_)
	{
		uint256 length = _requests.length;

		ManualExchange memory path;
		address trader;

		uint256 lastAmountOut = _amountOut;
		while (length > 0) {
			length--;

			path = _requests[length];
			trader = tradersAddress[path.traderSelector];

			lastAmountOut = ITrader(trader).getAmountIn(
				_getFulfilledGetAmountInOut(path.traderSelector, path.data, lastAmountOut)
			);
		}

		return lastAmountOut;
	}

	function getAmountOut(uint256 _amountIn, ManualExchange[] calldata _requests)
		external
		view
		override
		returns (uint256 amountOut_)
	{
		uint256 length = _requests.length;

		ManualExchange memory path;
		address trader;

		uint256 lastAmountIn = _amountIn;
		for (uint256 i = 0; i < length; ++i) {
			path = _requests[i];
			trader = tradersAddress[path.traderSelector];

			lastAmountIn = ITrader(trader).getAmountOut(
				_getFulfilledGetAmountInOut(path.traderSelector, path.data, lastAmountIn)
			);
		}

		return lastAmountIn;
	}

	function _getFulfilledGetAmountInOut(
		bytes16 _traderSelector,
		bytes memory _encodedData,
		uint256 _amount
	) internal pure returns (bytes memory) {
		if (_traderSelector == 0x0fa74b3ade106cd68a66c0ef6dfe2154) {
			UniswapV3SwapRequest memory request = abi.decode(
				_encodedData,
				(UniswapV3SwapRequest)
			);

			return
				abi.encode(
					UniswapV3RequestExactInOutParams(
						request.path,
						request.tokenIn,
						_amount,
						request.usingHop
					)
				);
		} else if (_traderSelector == 0x79402703bca5d67f15c4e7e9841e7231) {
			CurveSwapRequest memory request = abi.decode(_encodedData, (CurveSwapRequest));

			return
				abi.encode(
					CurveRequestExactInOutParams(
						request.pool,
						request.coins,
						_amount,
						request.slippage
					)
				);
		} else {
			GenericSwapRequest memory request = abi.decode(
				_encodedData,
				(GenericSwapRequest)
			);

			return abi.encode(GenericRequestExactInOutParams(request.path, _amount));
		}
	}

	function isRegisteredTrader(address _trader)
		external
		view
		override
		returns (bool)
	{
		return registeredTrader[_trader];
	}

	function getTraderAddressWithSelector(bytes16 _selector)
		external
		view
		override
		returns (address)
	{
		return tradersAddress[_selector];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ManualExchange } from "../model/TradingModel.sol";

interface IVestaDexTrader {
	error InvalidTraderSelector();
	error TraderFailed(address trader, bytes returnedCallData);
	error FailedToReceiveExactAmountOut(uint256 minimumAmount, uint256 receivedAmount);
	error TraderFailedMaxAmountInExceeded(
		uint256 maximumAmountIn,
		uint256 requestedAmountIn
	);
	error RoutingNotFound();
	error EmptyRequest();

	event TraderRegistered(address indexed trader, bytes16 selector);
	event TraderRemoved(address indexed trader);
	event RouteUpdated(address indexed tokenIn, address indexed tokenOut);
	event SwapExecuted(
		address indexed executor,
		address indexed receiver,
		address[2] tokenInOut,
		uint256[2] amountInOut
	);

	/**
	 * exchange uses Vesta's traders but with your own routing.
	 * @param _receiver the wallet that will receives the output token
	 * @param _firstTokenIn the token that will be swapped
	 * @param _firstAmountIn the amount of Token In you will send
	 * @param _requests Your custom routing
	 * @return swapDatas_ elements are the amountOut from each swaps
	 *
	 * @dev this function only uses expectedAmountIn
	 */
	function exchange(
		address _receiver,
		address _firstTokenIn,
		uint256 _firstAmountIn,
		ManualExchange[] calldata _requests
	) external returns (uint256[] memory swapDatas_);

	function getAmountIn(uint256 _amountOut, ManualExchange[] calldata _requests)
		external
		returns (uint256 amountIn_);

	function getAmountOut(uint256 _amountIn, ManualExchange[] calldata _requests)
		external
		returns (uint256 amountOut_);

	/**
	 * isRegisteredTrader check if a contract is a Trader
	 * @param _trader address of the trader
	 * @return registered_ is true if the trader is registered
	 */
	function isRegisteredTrader(address _trader) external view returns (bool);

	/**
	 * getTraderAddressWithSelector get Trader address with selector
	 * @param _selector Trader's selector
	 * @return address_ Trader's address
	 */
	function getTraderAddressWithSelector(bytes16 _selector)
		external
		view
		returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @param traderSelector the Selector of the Dex you want to use. If not sure, you can find them in VestaDexTrader.sol
 * @param tokenInOut the token0 is the one that will be swapped, the token1 is the one that will be returned
 * @param data the encoded structure for the exchange function of a ITrader.
 * @dev {data}'s structure should have 0 for expectedAmountIn and expectedAmountOut
 */
struct ManualExchange {
	bytes16 traderSelector;
	address[2] tokenInOut;
	bytes data;
}

/**
 * @param path
 * 	SingleHop: abi.encode(adress tokenOut, uint24 poolFee);
 * 	MultiHop-ExactAmountIn: abi.encode(adress tokenIn, uint24 fee, adress tokenOutIn, uint24 fee, adress tokenOut);
 * @param tokenIn the token that will be swapped
 * @param expectedAmountIn the expected amount In that will be swapped
 * @param expectedAmountOut the expected amount Out that will be returned
 * @param amountInMaximum the maximum tokenIn that can be used
 * @param usingHop does it use a hop (multi-path)
 *
 * @dev you can only use one of the expectedAmount, not both.
 * @dev amountInMaximum can be zero
 */
struct UniswapV3SwapRequest {
	bytes path;
	address tokenIn;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
	uint256 amountInMaximum;
	bool usingHop;
}

/**
 * @param pool the curve's pool address
 * @param coins coins0 is the token that goes in, coins1 is the token that goes out
 * @param expectedAmountIn the expect amount in that will be used
 * @param expectedAmountOut the expect amount out that the user will receives
 * @param slippage allowed slippage in BPS percentage
 * @dev {_slippage} is only used for curve and it is an addition to the expected amountIn that the system calculates.
		If the system expects amountIn to be 100 to have the exact amountOut, the total of amountIn WILL BE 110.
		You'll need it on major price impacts trading.
 *
 * @dev you can only use one of the expectedAmount, not both.
 * @dev slippage should only used by other contracts. Otherwise, do the formula off-chain and set it to zero.
 */
struct CurveSwapRequest {
	address pool;
	uint8[2] coins;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
	uint16 slippage;
}

/**
 * @param path uses the token address to create the path [TokenIn, TokenOut]
 * @param expectedAmountIn the expect amount in that will be used
 * @param expectedAmountOut the expect amount out that the user will receives
 *
 * @dev Path length should be 2 or 3. Otherwise, you are using it wrong!
 * @dev you can only use one of the expectedAmount, not both.
 */
struct GenericSwapRequest {
	address[] path;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
}

/**
 * @param pool the curve's pool address
 * @param coins coins0 is the token that goes in, coins1 is the token that goes out
 * @param amount the amount wanted
 * @param slippage allowed slippage in BPS percentage
 * @dev {_slippage} is only used for curve and it is an addition to the expected amountIn that the system calculates.
		If the system expects amountIn to be 100 to have the exact amountOut, the total of amountIn WILL BE 110.
		You'll need it on major price impacts trading.
 */
struct CurveRequestExactInOutParams {
	address pool;
	uint8[2] coins;
	uint256 amount;
	uint16 slippage;
}

/**
 * @param path uses the token address to create the path
 * @param amount the wanted amount
 */
struct GenericRequestExactInOutParams {
	address[] path;
	uint256 amount;
}

/**
 * @param path
 * 	SingleHop: abi.encode(adress tokenOut, uint24 poolFee);
 * 	MultiHop-ExactAmountIn: abi.encode(adress tokenIn, uint24 fee, adress tokenOutIn, uint24 fee, adress tokenOut);
 * @param tokenIn the token that will be swapped
 * @param amount the amount wanted
 * @param usingHop does it use a hop (multi-path)
 */
struct UniswapV3RequestExactInOutParams {
	bytes path;
	address tokenIn;
	uint256 amount;
	bool usingHop;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICurvePool {
	function coins(uint256 arg) external view returns (address);

	function get_dy_underlying(
		int128 i,
		int128 j,
		uint256 dx
	) external view returns (uint256);

	function calc_withdraw_one_coin(uint256 _burn, int128 i)
		external
		view
		returns (uint256);

	function exchange(
		int128 i,
		int128 j,
		uint256 _dx,
		uint256 _min_dy,
		address _receiver
	) external returns (uint256);

	function exchange_underlying(
		int128 i,
		int128 j,
		uint256 _dx,
		uint256 _min_dy,
		address _receiver
	) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITrader {
	error InvalidRequestEncoding();
	error AmountInAndOutAreZeroOrSameValue();

	/**
	 * exchange Execute a swap request
	 * @param receiver the wallet that will receives the outcome token
	 * @param _request the encoded request
	 */
	function exchange(address receiver, bytes memory _request)
		external
		returns (uint256 swapResponse_);

	/**
	 * getAmountIn get what your need for almost-exact amount in.
	 * @dev depending of the trader, some aren't exact but higher depending of the slippage
	 * @param _request the encoded request of InOutParams
	 */
	function getAmountIn(bytes memory _request) external view returns (uint256);

	/**
	 * getAmountOut get what your need for exact amount out.
	 * @param _request the encoded request of InOutParams
	 */
	function getAmountOut(bytes memory _request) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TokenTransferrerConstants.sol";
import { TokenTransferrerErrors } from "./TokenTransferrerErrors.sol";
import "../../interface/token/IERC20.sol";

/**
 * @title TokenTransferrer
 * @custom:source https://github.com/ProjectOpenSea/seaport
 * @dev Modified version of Seaport.
 */
abstract contract TokenTransferrer is TokenTransferrerErrors {
	function _performTokenTransfer(
		address token,
		address to,
		uint256 amount
	) internal {
		if (token == address(0)) {
			(bool success, ) = to.call{ value: amount }(new bytes(0));

			if (!success) revert ErrorTransferETH(address(this), token, amount);

			return;
		}

		address from = address(this);

		// Utilize assembly to perform an optimized ERC20 token transfer.
		assembly {
			// The free memory pointer memory slot will be used when populating
			// call data for the transfer; read the value and restore it later.
			let memPointer := mload(FreeMemoryPointerSlot)

			// Write call data into memory, starting with function selector.
			mstore(ERC20_transfer_sig_ptr, ERC20_transfer_signature)
			mstore(ERC20_transfer_to_ptr, to)
			mstore(ERC20_transfer_amount_ptr, amount)

			// Make call & copy up to 32 bytes of return data to scratch space.
			// Scratch space does not need to be cleared ahead of time, as the
			// subsequent check will ensure that either at least a full word of
			// return data is received (in which case it will be overwritten) or
			// that no data is received (in which case scratch space will be
			// ignored) on a successful call to the given token.
			let callStatus := call(
				gas(),
				token,
				0,
				ERC20_transfer_sig_ptr,
				ERC20_transfer_length,
				0,
				OneWord
			)

			// Determine whether transfer was successful using status & result.
			let success := and(
				// Set success to whether the call reverted, if not check it
				// either returned exactly 1 (can't just be non-zero data), or
				// had no return data.
				or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
				callStatus
			)

			// Handle cases where either the transfer failed or no data was
			// returned. Group these, as most transfers will succeed with data.
			// Equivalent to `or(iszero(success), iszero(returndatasize()))`
			// but after it's inverted for JUMPI this expression is cheaper.
			if iszero(and(success, iszero(iszero(returndatasize())))) {
				// If the token has no code or the transfer failed: Equivalent
				// to `or(iszero(success), iszero(extcodesize(token)))` but
				// after it's inverted for JUMPI this expression is cheaper.
				if iszero(and(iszero(iszero(extcodesize(token))), success)) {
					// If the transfer failed:
					if iszero(success) {
						// If it was due to a revert:
						if iszero(callStatus) {
							// If it returned a message, bubble it up as long as
							// sufficient gas remains to do so:
							if returndatasize() {
								// Ensure that sufficient gas is available to
								// copy returndata while expanding memory where
								// necessary. Start by computing the word size
								// of returndata and allocated memory. Round up
								// to the nearest full word.
								let returnDataWords := div(
									add(returndatasize(), AlmostOneWord),
									OneWord
								)

								// Note: use the free memory pointer in place of
								// msize() to work around a Yul warning that
								// prevents accessing msize directly when the IR
								// pipeline is activated.
								let msizeWords := div(memPointer, OneWord)

								// Next, compute the cost of the returndatacopy.
								let cost := mul(CostPerWord, returnDataWords)

								// Then, compute cost of new memory allocation.
								if gt(returnDataWords, msizeWords) {
									cost := add(
										cost,
										add(
											mul(sub(returnDataWords, msizeWords), CostPerWord),
											div(
												sub(
													mul(returnDataWords, returnDataWords),
													mul(msizeWords, msizeWords)
												),
												MemoryExpansionCoefficient
											)
										)
									)
								}

								// Finally, add a small constant and compare to
								// gas remaining; bubble up the revert data if
								// enough gas is still available.
								if lt(add(cost, ExtraGasBuffer), gas()) {
									// Copy returndata to memory; overwrite
									// existing memory.
									returndatacopy(0, 0, returndatasize())

									// Revert, specifying memory region with
									// copied returndata.
									revert(0, returndatasize())
								}
							}

							// Otherwise revert with a generic error message.
							mstore(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_signature
							)
							mstore(TokenTransferGenericFailure_error_token_ptr, token)
							mstore(TokenTransferGenericFailure_error_from_ptr, from)
							mstore(TokenTransferGenericFailure_error_to_ptr, to)
							mstore(TokenTransferGenericFailure_error_id_ptr, 0)
							mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
							revert(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_length
							)
						}

						// Otherwise revert with a message about the token
						// returning false or non-compliant return values.
						mstore(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_signature
						)
						mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
						mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
						mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
						mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
						revert(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_length
						)
					}

					// Otherwise, revert with error about token not having code:
					mstore(NoContract_error_sig_ptr, NoContract_error_signature)
					mstore(NoContract_error_token_ptr, token)
					revert(NoContract_error_sig_ptr, NoContract_error_length)
				}

				// Otherwise, the token just returned no data despite the call
				// having succeeded; no need to optimize for this as it's not
				// technically ERC20 compliant.
			}

			// Restore the original free memory pointer.
			mstore(FreeMemoryPointerSlot, memPointer)

			// Restore the zero slot to zero.
			mstore(ZeroSlot, 0)
		}
	}

	function _performTokenTransferFrom(
		address token,
		address from,
		address to,
		uint256 amount
	) internal {
		if (token == address(0)) return;

		// Utilize assembly to perform an optimized ERC20 token transfer.
		assembly {
			// The free memory pointer memory slot will be used when populating
			// call data for the transfer; read the value and restore it later.
			let memPointer := mload(FreeMemoryPointerSlot)

			// Write call data into memory, starting with function selector.
			mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
			mstore(ERC20_transferFrom_from_ptr, from)
			mstore(ERC20_transferFrom_to_ptr, to)
			mstore(ERC20_transferFrom_amount_ptr, amount)

			// Make call & copy up to 32 bytes of return data to scratch space.
			// Scratch space does not need to be cleared ahead of time, as the
			// subsequent check will ensure that either at least a full word of
			// return data is received (in which case it will be overwritten) or
			// that no data is received (in which case scratch space will be
			// ignored) on a successful call to the given token.
			let callStatus := call(
				gas(),
				token,
				0,
				ERC20_transferFrom_sig_ptr,
				ERC20_transferFrom_length,
				0,
				OneWord
			)

			// Determine whether transfer was successful using status & result.
			let success := and(
				// Set success to whether the call reverted, if not check it
				// either returned exactly 1 (can't just be non-zero data), or
				// had no return data.
				or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
				callStatus
			)

			// Handle cases where either the transfer failed or no data was
			// returned. Group these, as most transfers will succeed with data.
			// Equivalent to `or(iszero(success), iszero(returndatasize()))`
			// but after it's inverted for JUMPI this expression is cheaper.
			if iszero(and(success, iszero(iszero(returndatasize())))) {
				// If the token has no code or the transfer failed: Equivalent
				// to `or(iszero(success), iszero(extcodesize(token)))` but
				// after it's inverted for JUMPI this expression is cheaper.
				if iszero(and(iszero(iszero(extcodesize(token))), success)) {
					// If the transfer failed:
					if iszero(success) {
						// If it was due to a revert:
						if iszero(callStatus) {
							// If it returned a message, bubble it up as long as
							// sufficient gas remains to do so:
							if returndatasize() {
								// Ensure that sufficient gas is available to
								// copy returndata while expanding memory where
								// necessary. Start by computing the word size
								// of returndata and allocated memory. Round up
								// to the nearest full word.
								let returnDataWords := div(
									add(returndatasize(), AlmostOneWord),
									OneWord
								)

								// Note: use the free memory pointer in place of
								// msize() to work around a Yul warning that
								// prevents accessing msize directly when the IR
								// pipeline is activated.
								let msizeWords := div(memPointer, OneWord)

								// Next, compute the cost of the returndatacopy.
								let cost := mul(CostPerWord, returnDataWords)

								// Then, compute cost of new memory allocation.
								if gt(returnDataWords, msizeWords) {
									cost := add(
										cost,
										add(
											mul(sub(returnDataWords, msizeWords), CostPerWord),
											div(
												sub(
													mul(returnDataWords, returnDataWords),
													mul(msizeWords, msizeWords)
												),
												MemoryExpansionCoefficient
											)
										)
									)
								}

								// Finally, add a small constant and compare to
								// gas remaining; bubble up the revert data if
								// enough gas is still available.
								if lt(add(cost, ExtraGasBuffer), gas()) {
									// Copy returndata to memory; overwrite
									// existing memory.
									returndatacopy(0, 0, returndatasize())

									// Revert, specifying memory region with
									// copied returndata.
									revert(0, returndatasize())
								}
							}

							// Otherwise revert with a generic error message.
							mstore(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_signature
							)
							mstore(TokenTransferGenericFailure_error_token_ptr, token)
							mstore(TokenTransferGenericFailure_error_from_ptr, from)
							mstore(TokenTransferGenericFailure_error_to_ptr, to)
							mstore(TokenTransferGenericFailure_error_id_ptr, 0)
							mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
							revert(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_length
							)
						}

						// Otherwise revert with a message about the token
						// returning false or non-compliant return values.
						mstore(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_signature
						)
						mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
						mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
						mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
						mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
						revert(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_length
						)
					}

					// Otherwise, revert with error about token not having code:
					mstore(NoContract_error_sig_ptr, NoContract_error_signature)
					mstore(NoContract_error_token_ptr, token)
					revert(NoContract_error_sig_ptr, NoContract_error_length)
				}

				// Otherwise, the token just returned no data despite the call
				// having succeeded; no need to optimize for this as it's not
				// technically ERC20 compliant.
			}

			// Restore the original free memory pointer.
			mstore(FreeMemoryPointerSlot, memPointer)

			// Restore the zero slot to zero.
			mstore(ZeroSlot, 0)
		}
	}

	/**
		@notice SanitizeAmount allows to convert an 1e18 value to the token decimals
		@dev only supports 18 and lower
		@param token The contract address of the token
		@param value The value you want to sanitize
	*/
	function _sanitizeValue(address token, uint256 value)
		internal
		view
		returns (uint256)
	{
		if (token == address(0) || value == 0) return value;

		uint8 decimals = IERC20(token).decimals();

		if (decimals < 18) {
			return value / (10**(18 - decimals));
		}

		return value;
	}

	function _tryPerformMaxApprove(address token, address to) internal {
		if (IERC20(token).allowance(address(this), to) == type(uint256).max) {
			return;
		}

		require(IERC20(token).approve(to, type(uint256).max), "Approve Failed");
	}

	function _performApprove(
		address token,
		address to,
		uint256 value
	) internal {
		require(IERC20(token).approve(to, value), "Approve Failed");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature = (
	0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("transfer(address,uint256)")
uint256 constant ERC20_transfer_signature = (
	0xa9059cbb00000000000000000000000000000000000000000000000000000000
);

uint256 constant ERC20_transfer_sig_ptr = 0x0;
uint256 constant ERC20_transfer_to_ptr = 0x04;
uint256 constant ERC20_transfer_amount_ptr = 0x24;
uint256 constant ERC20_transfer_length = 0x44; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature = (
	0x5f15d67200000000000000000000000000000000000000000000000000000000
);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature = (
	0xf486bc8700000000000000000000000000000000000000000000000000000000
);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
	0x9889192300000000000000000000000000000000000000000000000000000000
);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
	error ErrorTransferETH(address caller, address to, uint256 value);

	/**
	 * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
	 *      transfer reverts.
	 *
	 * @param token      The token for which the transfer was attempted.
	 * @param from       The source of the attempted transfer.
	 * @param to         The recipient of the attempted transfer.
	 * @param identifier The identifier for the attempted transfer.
	 * @param amount     The amount for the attempted transfer.
	 */
	error TokenTransferGenericFailure(
		address token,
		address from,
		address to,
		uint256 identifier,
		uint256 amount
	);

	/**
	 * @dev Revert with an error when an ERC20 token transfer returns a falsey
	 *      value.
	 *
	 * @param token      The token for which the ERC20 transfer was attempted.
	 * @param from       The source of the attempted ERC20 transfer.
	 * @param to         The recipient of the attempted ERC20 transfer.
	 * @param amount     The amount for the attempted ERC20 transfer.
	 */
	error BadReturnValueFromERC20OnTransfer(
		address token,
		address from,
		address to,
		uint256 amount
	);

	/**
	 * @dev Revert with an error when an account being called as an assumed
	 *      contract does not have code and returns no data.
	 *
	 * @param account The account that should contain code.
	 */
	error NoContract(address account);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
	function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../../BaseTrader.sol";

import { ISwapRouter } from "../../../interface/dex/uniswap/ISwapRouter.sol";
import { TokenTransferrer } from "../../../lib/token/TokenTransferrer.sol";

import { UniswapV3SwapRequest, UniswapV3RequestExactInOutParams as RequestExactInOutParams } from "../../../model/TradingModel.sol";
import "../../../model/UniswapV3Model.sol";

import { IQuoter } from "lib/uniswap-v3-periphery/contracts/interfaces/IQuoter.sol";
import { IUniswapV3Factory } from "lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { UniswapV3QuoterLibrary } from "../../../vendor/dhedge/UniswapV3QuoterLibrary.sol";

contract UniswapV3Trader is TokenTransferrer, BaseTrader {
	using UniswapV3QuoterLibrary for IUniswapV3Factory;
	error InvalidPathEncoding();

	ISwapRouter public router;
	IQuoter public quoter;
	IUniswapV3Factory public v3Factory;

	function setUp(
		address _router,
		address _quoter,
		address _v3Factory
	) external initializer onlyContracts(_router, _quoter) onlyContract(_v3Factory) {
		__BASE_VESTA_INIT();
		router = ISwapRouter(_router);
		quoter = IQuoter(_quoter);
		v3Factory = IUniswapV3Factory(_v3Factory);
	}

	function setRouter(address _router) external onlyOwner {
		router = ISwapRouter(_router);
	}

	function setQuoter(address _quoter) external onlyOwner {
		quoter = IQuoter(_quoter);
	}

	function setV3Factory(address _v3Factory) external onlyOwner {
		v3Factory = IUniswapV3Factory(_v3Factory);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		onlyValidAddress(_receiver)
		returns (uint256 swapResponse_)
	{
		UniswapV3SwapRequest memory request = _safeDecodeSwapRequest(_request);
		bytes memory path = request.path;

		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		if (!request.usingHop) {
			(address tokenOut, uint24 poolFee) = _safeDecodeSingleHopPath(path);

			return
				(request.expectedAmountIn != 0)
					? _swapExactInputSingleHop(
						_receiver,
						request.tokenIn,
						tokenOut,
						poolFee,
						request.expectedAmountIn
					)
					: _swapExactOutputSingleHop(
						_receiver,
						request.tokenIn,
						tokenOut,
						poolFee,
						request.expectedAmountOut,
						request.amountInMaximum
					);
		} else {
			bytes memory correctedPath = sanitizeMultiHopForUniswap(
				path,
				request.expectedAmountIn != 0
			);

			return
				(request.expectedAmountIn != 0)
					? _swapExactInputMultiHop(
						correctedPath,
						_receiver,
						request.tokenIn,
						request.expectedAmountIn
					)
					: _swapExactOutputMultiHop(
						correctedPath,
						_receiver,
						request.tokenIn,
						request.expectedAmountOut,
						request.amountInMaximum
					);
		}
	}

	function _swapExactInputSingleHop(
		address _receiver,
		address _tokenIn,
		address _tokenOut,
		uint24 _poolFee,
		uint256 _amountIn
	) internal returns (uint256 amountOut_) {
		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactInputSingleParams memory params = ExactInputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: _poolFee,
			recipient: _receiver,
			deadline: block.timestamp,
			amountIn: _amountIn,
			amountOutMinimum: 0,
			sqrtPriceLimitX96: 0
		});

		amountOut_ = router.exactInputSingle(params);

		return amountOut_;
	}

	function _swapExactOutputSingleHop(
		address _receiver,
		address _tokenIn,
		address _tokenOut,
		uint24 _poolFee,
		uint256 _amountOut,
		uint256 _amountInMaximum
	) internal returns (uint256 amountIn_) {
		if (_amountInMaximum == 0) {
			_amountInMaximum = quoter.quoteExactOutputSingle(
				_tokenIn,
				_tokenOut,
				_poolFee,
				_amountOut,
				0
			);
		}

		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountInMaximum);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactOutputSingleParams memory params = ExactOutputSingleParams({
			tokenIn: _tokenIn,
			tokenOut: _tokenOut,
			fee: _poolFee,
			recipient: _receiver,
			deadline: block.timestamp,
			amountOut: _amountOut,
			amountInMaximum: _amountInMaximum,
			sqrtPriceLimitX96: 0
		});

		amountIn_ = router.exactOutputSingle(params);

		if (amountIn_ < _amountInMaximum) {
			_performTokenTransfer(_tokenIn, msg.sender, _amountInMaximum - amountIn_);
		}

		return amountIn_;
	}

	function _swapExactInputMultiHop(
		bytes memory _path,
		address _receiver,
		address _tokenIn,
		uint256 _amountIn
	) internal returns (uint256 amountOut_) {
		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactInputParams memory params = ExactInputParams({
			path: _path,
			recipient: _receiver,
			deadline: block.timestamp,
			amountIn: _amountIn,
			amountOutMinimum: 0
		});

		return router.exactInput(params);
	}

	function _swapExactOutputMultiHop(
		bytes memory _path,
		address _receiver,
		address _tokenIn,
		uint256 _amountOut,
		uint256 _amountInMaximum
	) internal returns (uint256 amountIn_) {
		if (_amountInMaximum == 0) {
			_amountInMaximum = quoter.quoteExactOutput(_path, _amountOut);
		}

		_performTokenTransferFrom(_tokenIn, msg.sender, address(this), _amountInMaximum);
		_tryPerformMaxApprove(_tokenIn, address(router));

		ExactOutputParams memory params = ExactOutputParams({
			path: _path,
			recipient: _receiver,
			deadline: block.timestamp,
			amountOut: _amountOut,
			amountInMaximum: _amountInMaximum
		});

		amountIn_ = router.exactOutput(params);

		if (amountIn_ < _amountInMaximum) {
			_performTokenTransfer(_tokenIn, msg.sender, _amountInMaximum - amountIn_);
		}

		return amountIn_;
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestInOutParams(_request);

		return (
			_getAmountIn(params.tokenIn, params.amount, params.path, params.usingHop)
		);
	}

	function _getAmountIn(
		address _tokenIn,
		uint256 _amountOut,
		bytes memory _path,
		bool _usingHop
	) internal view returns (uint256) {
		uint256 cachedOut = _amountOut;
		if (_usingHop) {
			(
				address tokenIn,
				uint24 feeA,
				address tokenOutIn,
				uint24 feeB,
				address tokenOut
			) = _safeDecodeMultiHopPath(_path);

			return
				_getEstimateSwap(
					tokenOutIn,
					tokenIn,
					feeB,
					_getEstimateSwap(tokenOut, tokenOutIn, feeA, cachedOut, false),
					false
				);
		} else {
			(address tokenOut, uint24 fee) = _safeDecodeSingleHopPath(_path);
			return _getEstimateSwap(tokenOut, _tokenIn, fee, cachedOut, false);
		}
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestInOutParams(_request);

		return (
			_getAmountOut(params.tokenIn, params.amount, params.path, params.usingHop)
		);
	}

	function _getAmountOut(
		address _tokenIn,
		uint256 _amountIn,
		bytes memory _path,
		bool _usingHop
	) internal view returns (uint256) {
		uint256 cachedIn = _amountIn;
		if (_usingHop) {
			(
				address tokenIn,
				uint24 feeA,
				address tokenOutIn,
				uint24 feeB,
				address tokenOut
			) = _safeDecodeMultiHopPath(_path);

			return
				_getEstimateSwap(
					tokenOutIn,
					tokenOut,
					feeB,
					_getEstimateSwap(tokenIn, tokenOutIn, feeA, cachedIn, true),
					true
				);
		} else {
			(address tokenOut, uint24 fee) = _safeDecodeSingleHopPath(_path);
			return _getEstimateSwap(_tokenIn, tokenOut, fee, cachedIn, true);
		}
	}

	function _getEstimateSwap(
		address _tokenIn,
		address _tokenOut,
		uint24 _fee,
		uint256 _amount,
		bool _maximum
	) internal view virtual returns (uint256) {
		if (v3Factory.getPool(_tokenIn, _tokenOut, _fee) == address(0)) return 0;

		return
			_maximum
				? v3Factory.estimateMaxSwapUniswapV3(_tokenIn, _tokenOut, _amount, _fee)
				: v3Factory.estimateMinSwapUniswapV3(_tokenIn, _tokenOut, _amount, _fee);
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (UniswapV3SwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (
			UniswapV3SwapRequest memory request_
		) {
			return request_;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (UniswapV3SwapRequest memory)
	{
		return abi.decode(_request, (UniswapV3SwapRequest));
	}

	function _safeDecodeSingleHopPath(bytes memory _path)
		internal
		view
		returns (address tokenOut_, uint24 fee_)
	{
		try this.decodeSingleHopPath(_path) returns (address tokenOut, uint24 fee) {
			return (tokenOut, fee);
		} catch {
			revert InvalidPathEncoding();
		}
	}

	function decodeSingleHopPath(bytes memory _path)
		external
		pure
		returns (address tokenOut_, uint24 fee_)
	{
		return abi.decode(_path, (address, uint24));
	}

	function _safeDecodeMultiHopPath(bytes memory _path)
		internal
		view
		returns (
			address tokenIn_,
			uint24 feeA_,
			address tokenOutIn_,
			uint24 feeB_,
			address tokenOut_
		)
	{
		try this.decodeMultiHopPath(_path) returns (
			address tokenIn,
			uint24 feeA,
			address tokenOutIn,
			uint24 feeB,
			address tokenOut
		) {
			return (tokenIn, feeA, tokenOutIn, feeB, tokenOut);
		} catch {
			revert InvalidPathEncoding();
		}
	}

	function decodeMultiHopPath(bytes memory _path)
		external
		pure
		returns (
			address tokenIn_,
			uint24 feeA_,
			address tokenOutIn_,
			uint24 feeB_,
			address tokenOut_
		)
	{
		return abi.decode(_path, (address, uint24, address, uint24, address));
	}

	function sanitizeMultiHopForUniswap(bytes memory _path, bool _withAmountIn)
		public
		view
		returns (bytes memory correctedPath_)
	{
		(
			address tokenIn,
			uint24 feeA,
			address tokenOutIn,
			uint24 feeB,
			address tokenOut
		) = _safeDecodeMultiHopPath(_path);

		return
			(_withAmountIn)
				? abi.encodePacked(tokenIn, feeA, tokenOutIn, feeB, tokenOut)
				: abi.encodePacked(tokenOut, feeB, tokenOutIn, feeA, tokenIn);
	}

	function _safeDecodeRequestInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeRequestInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeRequestInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function generateSwapRequest(
		address _tokenMiddle,
		address _tokenOut,
		uint24 _poolFeeA,
		uint24 _poolFeeB,
		address _tokenIn,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut,
		uint256 _amountInMaximum,
		bool _usingHop
	) external pure returns (bytes memory) {
		bytes memory path = _usingHop
			? abi.encode(_tokenIn, _poolFeeA, _tokenMiddle, _poolFeeB, _tokenOut)
			: abi.encode(_tokenOut, _poolFeeA);

		return
			abi.encode(
				UniswapV3SwapRequest(
					path,
					_tokenIn,
					_expectedAmountIn,
					_expectedAmountOut,
					_amountInMaximum,
					_usingHop
				)
			);
	}

	function generateExpectInOutRequest(
		address _tokenMiddle,
		address _tokenOut,
		uint24 _poolFeeA,
		uint24 _poolFeeB,
		address _tokenIn,
		uint256 _amount,
		bool _usingHop
	) external pure returns (bytes memory) {
		bytes memory path = _usingHop
			? abi.encode(_tokenIn, _poolFeeA, _tokenMiddle, _poolFeeB, _tokenOut)
			: abi.encode(_tokenOut, _poolFeeA);

		return abi.encode(RequestExactInOutParams(path, _tokenIn, _amount, _usingHop));
	}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../BaseVesta.sol";
import "../lib/token/TokenTransferrer.sol";
import "../interface/ITrader.sol";

abstract contract BaseTrader is ITrader, BaseVesta, TokenTransferrer {
	uint16 public constant EXACT_AMOUNT_IN_CORRECTION = 3; //0.003
	uint128 public constant CORRECTION_DENOMINATOR = 100_000;

	function _validExpectingAmount(uint256 _in, uint256 _out) internal pure {
		if (_in == _out || (_in == 0 && _out == 0)) {
			revert AmountInAndOutAreZeroOrSameValue();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../../model/UniswapV3Model.sol";

interface ISwapRouter {
	function exactInputSingle(ExactInputSingleParams calldata params)
		external
		payable
		returns (uint256 amountOut);

	function exactInput(ExactInputParams calldata params)
		external
		payable
		returns (uint256 amountOut);

	function exactOutputSingle(ExactOutputSingleParams calldata params)
		external
		returns (uint256 amountIn);

	function exactOutput(ExactOutputParams calldata params)
		external
		returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @custom:doc Uniswap V3's Doc
 */

struct ExactInputSingleParams {
	address tokenIn;
	address tokenOut;
	uint24 fee;
	address recipient;
	uint256 deadline;
	uint256 amountIn;
	uint256 amountOutMinimum;
	uint160 sqrtPriceLimitX96;
}

struct ExactOutputSingleParams {
	address tokenIn;
	address tokenOut;
	uint24 fee;
	address recipient;
	uint256 deadline;
	uint256 amountOut;
	uint256 amountInMaximum;
	uint160 sqrtPriceLimitX96;
}

struct ExactInputParams {
	bytes path;
	address recipient;
	uint256 deadline;
	uint256 amountIn;
	uint256 amountOutMinimum;
}

struct ExactOutputParams {
	bytes path;
	address recipient;
	uint256 deadline;
	uint256 amountOut;
	uint256 amountInMaximum;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./libraries/LowGasSafeMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Tick.sol";
import "./libraries/TickBitmap.sol";
import "./libraries/FullMath.sol";
import "./libraries/SwapMath.sol";

import "lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";

// from https://github.com/sandrones/V3-Quoter/blob/master/contracts/UniswapV3Quoter.sol
library UniswapV3QuoterLibrary {
	using LowGasSafeMath for int256;
	using SafeCast for uint256;
	using Tick for mapping(int24 => Tick.Info);

	struct PoolState {
		// the current price
		uint160 sqrtPriceX96;
		// the current tick
		int24 tick;
		// the tick spacing
		int24 tickSpacing;
		// the pool's fee
		uint24 fee;
		// the pool's liquidity
		uint128 liquidity;
		// whether the pool is locked
		bool unlocked;
	}

	// accumulated protocol fees in token0/token1 units
	struct ProtocolFees {
		uint128 token0;
		uint128 token1;
	}

	// the top level state of the swap, the results of which are recorded in storage at the end
	struct SwapState {
		// the amount remaining to be swapped in/out of the input/output asset
		int256 amountSpecifiedRemaining;
		// the amount already swapped out/in of the output/input asset
		int256 amountCalculated;
		// current sqrt(price)
		uint160 sqrtPriceX96;
		// the tick associated with the current price
		int24 tick;
		// the current liquidity in range
		uint128 liquidity;
		uint256 iteration;
	}

	struct StepComputations {
		// the price at the beginning of the step
		uint160 sqrtPriceStartX96;
		// the next tick to swap to from the current tick in the swap direction
		int24 tickNext;
		// whether tickNext is initialized or not
		bool initialized;
		// sqrt(price) for the next tick (1/0)
		uint160 sqrtPriceNextX96;
		// how much is being swapped in in this step
		uint256 amountIn;
		// how much is being swapped out
		uint256 amountOut;
		// how much fee is being paid in
		uint256 feeAmount;
	}

	struct InitialState {
		address poolAddress;
		PoolState poolState;
		uint256 feeGrowthGlobal0X128;
		uint256 feeGrowthGlobal1X128;
	}

	struct NextTickPassage {
		int24 tick;
		int24 tickSpacing;
	}

	function fetchState(address _pool)
		internal
		view
		returns (PoolState memory poolState)
	{
		IUniswapV3Pool pool = IUniswapV3Pool(_pool);
		(uint160 sqrtPriceX96, int24 tick, , , , , bool unlocked) = pool.slot0(); // external call
		uint128 liquidity = pool.liquidity(); // external call
		int24 tickSpacing = IUniswapV3PoolImmutables(_pool).tickSpacing(); // external call
		uint24 fee = IUniswapV3PoolImmutables(_pool).fee(); // external call
		poolState = PoolState(sqrtPriceX96, tick, tickSpacing, fee, liquidity, unlocked);
	}

	function setInitialState(PoolState memory initialPoolState, int256 amountSpecified)
		internal
		pure
		returns (
			SwapState memory state,
			uint128 liquidity,
			uint160 sqrtPriceX96
		)
	{
		liquidity = initialPoolState.liquidity;

		sqrtPriceX96 = initialPoolState.sqrtPriceX96;

		state = SwapState({
			amountSpecifiedRemaining: amountSpecified,
			amountCalculated: 0,
			sqrtPriceX96: initialPoolState.sqrtPriceX96,
			tick: initialPoolState.tick,
			liquidity: 0, // to be modified after initialization
			iteration: 0
		});
	}

	function getNextTickAndPrice(
		int24 tickSpacing,
		int24 currentTick,
		IUniswapV3Pool pool,
		bool zeroForOne
	)
		internal
		view
		returns (
			int24 tickNext,
			bool initialized,
			uint160 sqrtPriceNextX96
		)
	{
		int24 compressed = currentTick / tickSpacing;
		if (!zeroForOne) compressed++;
		if (currentTick < 0 && currentTick % tickSpacing != 0) compressed--; // round towards negative infinity

		uint256 selfResult = pool.tickBitmap(int16(compressed >> 8)); // external call

		(tickNext, initialized) = TickBitmap.nextInitializedTickWithinOneWord(
			selfResult,
			currentTick,
			tickSpacing,
			zeroForOne
		);

		if (tickNext < TickMath.MIN_TICK) {
			tickNext = TickMath.MIN_TICK;
		} else if (tickNext > TickMath.MAX_TICK) {
			tickNext = TickMath.MAX_TICK;
		}
		sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(tickNext);
	}

	function processSwapWithinTick(
		IUniswapV3Pool pool,
		PoolState memory initialPoolState,
		SwapState memory state,
		uint160 firstSqrtPriceX96,
		uint128 firstLiquidity,
		uint160 sqrtPriceLimitX96,
		bool zeroForOne,
		bool exactAmount
	)
		internal
		view
		returns (
			uint160 sqrtPriceNextX96,
			uint160 finalSqrtPriceX96,
			uint128 finalLiquidity
		)
	{
		StepComputations memory step;

		step.sqrtPriceStartX96 = firstSqrtPriceX96;

		(step.tickNext, step.initialized, sqrtPriceNextX96) = getNextTickAndPrice(
			initialPoolState.tickSpacing,
			state.tick,
			pool,
			zeroForOne
		);

		(finalSqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
			.computeSwapStep(
				firstSqrtPriceX96,
				(
					zeroForOne
						? sqrtPriceNextX96 < sqrtPriceLimitX96
						: sqrtPriceNextX96 > sqrtPriceLimitX96
				)
					? sqrtPriceLimitX96
					: sqrtPriceNextX96,
				firstLiquidity,
				state.amountSpecifiedRemaining,
				initialPoolState.fee,
				zeroForOne
			);

		if (exactAmount) {
			state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
			state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
		} else {
			state.amountSpecifiedRemaining += step.amountOut.toInt256();
			state.amountCalculated = state.amountCalculated.add(
				(step.amountIn + step.feeAmount).toInt256()
			);
		}

		if (finalSqrtPriceX96 == sqrtPriceNextX96) {
			if (step.initialized) {
				(, int128 liquidityNet, , , , , , ) = pool.ticks(step.tickNext);
				if (zeroForOne) liquidityNet = -liquidityNet;
				finalLiquidity = LiquidityMath.addDelta(firstLiquidity, liquidityNet);
			}
			state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
		} else if (finalSqrtPriceX96 != step.sqrtPriceStartX96) {
			// recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
			state.tick = TickMath.getTickAtSqrtRatio(finalSqrtPriceX96);
		}
	}

	function returnedAmount(
		SwapState memory state,
		int256 amountSpecified,
		bool zeroForOne
	) internal pure returns (int256 amount0, int256 amount1) {
		if (amountSpecified > 0) {
			(amount0, amount1) = zeroForOne
				? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
				: (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
		} else {
			(amount0, amount1) = zeroForOne
				? (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining)
				: (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated);
		}
	}

	function quoteSwap(
		address poolAddress,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bool zeroForOne
	) internal view returns (int256 amount0, int256 amount1) {
		bool exactAmount = amountSpecified > 0;

		PoolState memory initialPoolState = fetchState(poolAddress);

		if (
			!(
				zeroForOne
					? sqrtPriceLimitX96 < initialPoolState.sqrtPriceX96 &&
						sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
					: sqrtPriceLimitX96 > initialPoolState.sqrtPriceX96 &&
						sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO
			)
		) {
			// SPL
			return (0, 0);
		}

		(
			SwapState memory state,
			uint128 liquidity,
			uint160 sqrtPriceX96
		) = setInitialState(initialPoolState, amountSpecified);

		uint160 sqrtPriceNextX96;
		while (
			state.amountSpecifiedRemaining != 0 &&
			sqrtPriceX96 != sqrtPriceLimitX96 &&
			liquidity > 0
		) {
			(sqrtPriceNextX96, sqrtPriceX96, liquidity) = processSwapWithinTick(
				IUniswapV3Pool(poolAddress),
				initialPoolState,
				state,
				sqrtPriceX96,
				liquidity,
				sqrtPriceLimitX96,
				zeroForOne,
				exactAmount
			);
			state.iteration++;
		}

		(amount0, amount1) = returnedAmount(state, amountSpecified, zeroForOne);
	}

	function _estimateOutputSingle(
		address _fromToken,
		address _toToken,
		uint256 _amount,
		address _pool
	) internal view returns (uint256 amountOut) {
		bool zeroForOne = _fromToken > _toToken;
		// todo: price limit?
		(int256 amount0, int256 amount1) = quoteSwap(
			_pool,
			int256(_amount),
			zeroForOne ? (TickMath.MIN_SQRT_RATIO + 1) : (TickMath.MAX_SQRT_RATIO - 1),
			zeroForOne
		);
		if (zeroForOne) amountOut = amount1 > 0 ? uint256(amount1) : uint256(-amount1);
		else amountOut = amount0 > 0 ? uint256(amount0) : uint256(-amount0);
	}

	function _estimateInputSingle(
		address _fromToken,
		address _toToken,
		uint256 _amount,
		address _pool
	) internal view returns (uint256 amountOut) {
		bool zeroForOne = _fromToken < _toToken;
		// todo: price limit?
		(int256 amount0, int256 amount1) = quoteSwap(
			_pool,
			-int256(_amount),
			zeroForOne ? (TickMath.MIN_SQRT_RATIO + 1) : (TickMath.MAX_SQRT_RATIO - 1),
			zeroForOne
		);
		if (zeroForOne) amountOut = amount0 > 0 ? uint256(amount0) : uint256(-amount0);
		else amountOut = amount1 > 0 ? uint256(amount1) : uint256(-amount1);
	}

	function estimateMaxSwapUniswapV3(
		IUniswapV3Factory _factory,
		address _fromToken,
		address _toToken,
		uint256 _amount,
		uint24 _poolFee
	) internal view returns (uint256) {
		address pool = _factory.getPool(_fromToken, _toToken, _poolFee);

		return _estimateOutputSingle(_toToken, _fromToken, _amount, pool);
	}

	function estimateMinSwapUniswapV3(
		IUniswapV3Factory _factory,
		address _fromToken,
		address _toToken,
		uint256 _amount,
		uint24 _poolFee
	) internal view returns (uint256) {
		address pool = _factory.getPool(_fromToken, _toToken, _poolFee);

		return _estimateInputSingle(_toToken, _fromToken, _amount, pool);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
	/// @notice Returns x + y, reverts if sum overflows uint256
	/// @param x The augend
	/// @param y The addend
	/// @return z The sum of x and y
	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		// solhint-disable-next-line reason-string
		require((z = x + y) >= x);
	}

	/// @notice Returns x - y, reverts if underflows
	/// @param x The minuend
	/// @param y The subtrahend
	/// @return z The difference of x and y
	function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		// solhint-disable-next-line reason-string
		require((z = x - y) <= x);
	}

	/// @notice Returns x * y, reverts if overflows
	/// @param x The multiplicand
	/// @param y The multiplier
	/// @return z The product of x and y
	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		// solhint-disable-next-line reason-string
		require(x == 0 || (z = x * y) / x == y);
	}

	/// @notice Returns x + y, reverts if overflows or underflows
	/// @param x The augend
	/// @param y The addend
	/// @return z The sum of x and y
	function add(int256 x, int256 y) internal pure returns (int256 z) {
		// solhint-disable-next-line reason-string
		require((z = x + y) >= x == (y >= 0));
	}

	/// @notice Returns x - y, reverts if overflows or underflows
	/// @param x The minuend
	/// @param y The subtrahend
	/// @return z The difference of x and y
	function sub(int256 x, int256 y) internal pure returns (int256 z) {
		// solhint-disable-next-line reason-string
		require((z = x - y) <= x == (y >= 0));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
	/// @notice Cast a uint256 to a uint160, revert on overflow
	/// @param y The uint256 to be downcasted
	/// @return z The downcasted integer, now type uint160
	function toUint160(uint256 y) internal pure returns (uint160 z) {
		// solhint-disable-next-line reason-string
		require((z = uint160(y)) == y);
	}

	/// @notice Cast a int256 to a int128, revert on overflow or underflow
	/// @param y The int256 to be downcasted
	/// @return z The downcasted integer, now type int128
	function toInt128(int256 y) internal pure returns (int128 z) {
		// solhint-disable-next-line reason-string
		require((z = int128(y)) == y);
	}

	/// @notice Cast a uint256 to a int256, revert on overflow
	/// @param y The uint256 to be casted
	/// @return z The casted integer, now type int256
	function toInt256(uint256 y) internal pure returns (int256 z) {
		// solhint-disable-next-line reason-string
		require(y < 2**255);
		z = int256(y);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./LowGasSafeMath.sol";
import "./SafeCast.sol";

import "./TickMath.sol";
import "./LiquidityMath.sol";

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations

/// Ithil to modify it, since it does not have access to storage arrays
library Tick {
	using LowGasSafeMath for int256;
	using SafeCast for int256;

	// info stored for each initialized individual tick
	struct Info {
		// the total position liquidity that references this tick
		uint128 liquidityGross;
		// amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
		int128 liquidityNet;
		// fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
		// only has relative meaning, not absolute — the value depends on when the tick is initialized
		uint256 feeGrowthOutside0X128;
		uint256 feeGrowthOutside1X128;
		// the cumulative tick value on the other side of the tick
		int56 tickCumulativeOutside;
		// the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
		// only has relative meaning, not absolute — the value depends on when the tick is initialized
		uint160 secondsPerLiquidityOutsideX128;
		// the seconds spent on the other side of the tick (relative to the current tick)
		// only has relative meaning, not absolute — the value depends on when the tick is initialized
		uint32 secondsOutside;
		// true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
		// these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
		bool initialized;
	}

	/// @notice Derives max liquidity per tick from given tick spacing
	/// @dev Executed within the pool constructor
	/// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
	///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
	/// @return The max liquidity per tick
	function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing)
		internal
		pure
		returns (uint128)
	{
		int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
		int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
		uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
		return type(uint128).max / numTicks;
	}

	/// @notice Retrieves fee growth data
	/// Ithil: only use it with lower = self[tickLower] and upper = self[tickUpper]
	/// @param lower The info of the lower tick boundary of the position
	/// @param upper The info of the upper tick boundary of the position
	/// @param tickLower The lower tick boundary of the position
	/// @param tickUpper The upper tick boundary of the position
	/// @param tickCurrent The current tick
	/// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
	/// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
	/// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
	/// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
	function getFeeGrowthInside(
		Tick.Info memory lower,
		Tick.Info memory upper,
		int24 tickLower,
		int24 tickUpper,
		int24 tickCurrent,
		uint256 feeGrowthGlobal0X128,
		uint256 feeGrowthGlobal1X128
	)
		internal
		pure
		returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
	{
		// calculate fee growth below
		uint256 feeGrowthBelow0X128;
		uint256 feeGrowthBelow1X128;
		if (tickCurrent >= tickLower) {
			feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
			feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
		} else {
			feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
			feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
		}

		// calculate fee growth above
		uint256 feeGrowthAbove0X128;
		uint256 feeGrowthAbove1X128;
		if (tickCurrent < tickUpper) {
			feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
			feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
		} else {
			feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
			feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
		}

		feeGrowthInside0X128 =
			feeGrowthGlobal0X128 -
			feeGrowthBelow0X128 -
			feeGrowthAbove0X128;
		feeGrowthInside1X128 =
			feeGrowthGlobal1X128 -
			feeGrowthBelow1X128 -
			feeGrowthAbove1X128;
	}

	/// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
	/// Ithil: always use with info = self[tick]
	/// @param info The info tick that will be updated
	/// @param tick The tick that will be updated
	/// @param tickCurrent The current tick
	/// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
	/// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
	/// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
	/// @param secondsPerLiquidityCumulativeX128 The all-time seconds per max(1, liquidity) of the pool
	/// @param tickCumulative The tick * time elapsed since the pool was first initialized
	/// @param time The current block timestamp cast to a uint32
	/// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
	/// @param maxLiquidity The maximum liquidity allocation for a single tick
	/// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
	function update(
		Tick.Info memory info,
		int24 tick,
		int24 tickCurrent,
		int128 liquidityDelta,
		uint256 feeGrowthGlobal0X128,
		uint256 feeGrowthGlobal1X128,
		uint160 secondsPerLiquidityCumulativeX128,
		int56 tickCumulative,
		uint32 time,
		bool upper,
		uint128 maxLiquidity
	) internal pure returns (bool flipped) {
		uint128 liquidityGrossBefore = info.liquidityGross;
		uint128 liquidityGrossAfter = LiquidityMath.addDelta(
			liquidityGrossBefore,
			liquidityDelta
		);

		require(liquidityGrossAfter <= maxLiquidity, "LO");

		flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

		if (liquidityGrossBefore == 0) {
			// by convention, we assume that all growth before a tick was initialized happened _below_ the tick
			if (tick <= tickCurrent) {
				info.feeGrowthOutside0X128 = feeGrowthGlobal0X128;
				info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
				info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
				info.tickCumulativeOutside = tickCumulative;
				info.secondsOutside = time;
			}
			info.initialized = true;
		}

		info.liquidityGross = liquidityGrossAfter;

		// when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
		info.liquidityNet = upper
			? int256(info.liquidityNet).sub(liquidityDelta).toInt128()
			: int256(info.liquidityNet).add(liquidityDelta).toInt128();
	}

	/// @notice Transitions to next tick as needed by price movement
	/// @param info The result of the mapping containing all tick information for initialized ticks
	/// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
	/// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
	/// @param secondsPerLiquidityCumulativeX128 The current seconds per liquidity
	/// @param tickCumulative The tick * time elapsed since the pool was first initialized
	/// @param time The current block.timestamp
	/// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
	function cross(
		Tick.Info memory info,
		uint256 feeGrowthGlobal0X128,
		uint256 feeGrowthGlobal1X128,
		uint160 secondsPerLiquidityCumulativeX128,
		int56 tickCumulative,
		uint32 time
	) internal pure returns (int128 liquidityNet) {
		info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
		info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
		info.secondsPerLiquidityOutsideX128 =
			secondsPerLiquidityCumulativeX128 -
			info.secondsPerLiquidityOutsideX128;
		info.tickCumulativeOutside = tickCumulative - info.tickCumulativeOutside;
		info.secondsOutside = time - info.secondsOutside;
		liquidityNet = info.liquidityNet;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BitMath.sol";

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
	/// @notice Computes the position in the mapping where the initialized bit for a tick lives
	/// @param tick The tick for which to compute the position
	/// @return wordPos The key in the mapping containing the word in which the bit is stored
	/// @return bitPos The bit position in the word where the flag is stored
	/// @dev simply divides @param tick by 256 with remainder: tick = wordPos * 256 + bitPos
	function position(int24 tick) internal pure returns (int16 wordPos, uint8 bitPos) {
		wordPos = int16(tick >> 8);
		bitPos = uint8(int8(tick % 256));
	}

	/// Written by Ithil
	function computeWordPos(
		int24 tick,
		int24 tickSpacing,
		bool lte
	) internal pure returns (int16 wordPos) {
		int24 compressed = tick / tickSpacing;
		if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

		(wordPos, ) = lte ? position(compressed) : position(compressed + 1);
	}

	/// @notice Flips the initialized state for a given tick from false to true, or vice versa
	/// @param selfResult The result of the mapping in which to flip the tick (Ithil modified)
	/// @param tick The tick to flip
	/// @param tickSpacing The spacing between usable ticks
	function flipTick(
		uint256 selfResult,
		int24 tick,
		int24 tickSpacing
	) internal pure {
		// solhint-disable-next-line reason-string
		require(tick % tickSpacing == 0); // ensure that the tick is spaced
		(, uint8 bitPos) = position(tick / tickSpacing);
		uint256 mask = 1 << bitPos;
		selfResult ^= mask;
	}

	/// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
	/// to the left (less than or equal to) or right (greater than) of the given tick
	/// @param selfResult The result of the mapping in which to compute the next initialized tick (Ithil modified)
	/// @param tick The starting tick
	/// @param tickSpacing The spacing between usable ticks
	/// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
	/// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
	/// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
	function nextInitializedTickWithinOneWord(
		uint256 selfResult,
		int24 tick,
		int24 tickSpacing,
		bool lte
	) internal pure returns (int24 next, bool initialized) {
		int24 compressed = tick / tickSpacing;
		if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

		if (lte) {
			(, uint8 bitPos) = position(compressed);
			// all the 1s at or to the right of the current bitPos
			uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
			uint256 masked = selfResult & mask;

			// if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
			initialized = masked != 0;
			// overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
			next = initialized
				? (compressed -
					int24(uint24(bitPos) - uint24(BitMath.mostSignificantBit(masked)))) *
					tickSpacing
				: (compressed - int24(uint24(bitPos))) * tickSpacing;
		} else {
			// start from the word of the next tick, since the current tick state doesn't matter
			(, uint8 bitPos) = position(compressed + 1);
			// all the 1s at or to the left of the bitPos
			uint256 mask = ~((1 << bitPos) - 1);
			uint256 masked = selfResult & mask;

			// if there are no initialized ticks to the left of the current tick, return leftmost in the word
			initialized = masked != 0;
			// overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
			next = initialized
				? (compressed +
					1 +
					int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
				: (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
	/// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		// 512-bit multiply [prod1 prod0] = a * b
		// Compute the product mod 2**256 and mod 2**256 - 1
		// then use the Chinese Remainder Theorem to reconstruct
		// the 512 bit result. The result is stored in two 256
		// variables such that product = prod1 * 2**256 + prod0
		uint256 prod0; // Least significant 256 bits of the product
		uint256 prod1; // Most significant 256 bits of the product
		assembly {
			let mm := mulmod(a, b, not(0))
			prod0 := mul(a, b)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}

		// Handle non-overflow cases, 256 by 256 division
		if (prod1 == 0) {
			// solhint-disable-next-line reason-string
			require(denominator > 0);
			assembly {
				result := div(prod0, denominator)
			}
			return result;
		}

		// Make sure the result is less than 2**256.
		// Also prevents denominator == 0
		// solhint-disable-next-line reason-string
		require(denominator > prod1);

		///////////////////////////////////////////////
		// 512 by 256 division.
		///////////////////////////////////////////////

		// Make division exact by subtracting the remainder from [prod1 prod0]
		// Compute remainder using mulmod
		uint256 remainder;
		assembly {
			remainder := mulmod(a, b, denominator)
		}
		// Subtract 256 bit number from 512 bit number
		assembly {
			prod1 := sub(prod1, gt(remainder, prod0))
			prod0 := sub(prod0, remainder)
		}

		// Factor powers of two out of denominator
		// Compute largest power of two divisor of denominator.
		// Always >= 1.
		uint256 twos = (type(uint256).max - denominator + 1) & denominator;
		// Divide denominator by power of two
		assembly {
			denominator := div(denominator, twos)
		}

		// Divide [prod1 prod0] by the factors of two
		assembly {
			prod0 := div(prod0, twos)
		}
		// Shift in bits from prod1 into prod0. For this we need
		// to flip `twos` such that it is 2**256 / twos.
		// If twos is zero, then it becomes one
		assembly {
			twos := add(div(sub(0, twos), twos), 1)
		}
		prod0 |= prod1 * twos;

		// Invert denominator mod 2**256
		// Now that denominator is an odd number, it has an inverse
		// modulo 2**256 such that denominator * inv = 1 mod 2**256.
		// Compute the inverse by starting with a seed that is correct
		// correct for four bits. That is, denominator * inv = 1 mod 2**4
		uint256 inv = (3 * denominator) ^ 2;
		// Now use Newton-Raphson iteration to improve the precision.
		// Thanks to Hensel's lifting lemma, this also works in modular
		// arithmetic, doubling the correct bits in each step.
		inv *= 2 - denominator * inv; // inverse mod 2**8
		inv *= 2 - denominator * inv; // inverse mod 2**16
		inv *= 2 - denominator * inv; // inverse mod 2**32
		inv *= 2 - denominator * inv; // inverse mod 2**64
		inv *= 2 - denominator * inv; // inverse mod 2**128
		inv *= 2 - denominator * inv; // inverse mod 2**256

		// Because the division is now exact we can divide by multiplying
		// with the modular inverse of denominator. This will give us the
		// correct result modulo 2**256. Since the precoditions guarantee
		// that the outcome is less than 2**256, this is the final result.
		// We don't need to compute the high bits of the result and prod1
		// is no longer required.
		result = prod0 * inv;
		return result;
	}

	/// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	function mulDivRoundingUp(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		result = mulDiv(a, b, denominator);
		if (mulmod(a, b, denominator) > 0) {
			// solhint-disable-next-line reason-string
			require(result < type(uint256).max);
			result++;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./FullMath.sol";
import "./SqrtPriceMath.sol";

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
	/// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
	/// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
	/// @param sqrtRatioCurrentX96 The current sqrt price of the pool
	/// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
	/// @param liquidity The usable liquidity
	/// @param amountRemaining How much input or output amount is remaining to be swapped in/out
	/// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
	/// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
	/// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
	/// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
	/// @return feeAmount The amount of input that will be taken as a fee
	function computeSwapStep(
		uint160 sqrtRatioCurrentX96,
		uint160 sqrtRatioTargetX96,
		uint128 liquidity,
		int256 amountRemaining,
		uint24 feePips,
		bool zeroForOne
	)
		internal
		pure
		returns (
			uint160 sqrtRatioNextX96,
			uint256 amountIn,
			uint256 amountOut,
			uint256 feeAmount
		)
	{
		require(zeroForOne == sqrtRatioCurrentX96 >= sqrtRatioTargetX96, "SPD");
		bool exactIn = amountRemaining >= 0;

		if (exactIn) {
			uint256 amountRemainingLessFee = FullMath.mulDiv(
				uint256(amountRemaining),
				1e6 - feePips,
				1e6
			);
			amountIn = zeroForOne
				? SqrtPriceMath.getAmount0Delta(
					sqrtRatioTargetX96,
					sqrtRatioCurrentX96,
					liquidity,
					true
				)
				: SqrtPriceMath.getAmount1Delta(
					sqrtRatioCurrentX96,
					sqrtRatioTargetX96,
					liquidity,
					true
				);
			if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
			else
				sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
					sqrtRatioCurrentX96,
					liquidity,
					amountRemainingLessFee,
					zeroForOne
				);
		} else {
			amountOut = zeroForOne
				? SqrtPriceMath.getAmount1Delta(
					sqrtRatioTargetX96,
					sqrtRatioCurrentX96,
					liquidity,
					false
				)
				: SqrtPriceMath.getAmount0Delta(
					sqrtRatioCurrentX96,
					sqrtRatioTargetX96,
					liquidity,
					false
				);

			if (uint256(-amountRemaining) >= amountOut)
				sqrtRatioNextX96 = sqrtRatioTargetX96;
			else
				sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
					sqrtRatioCurrentX96,
					liquidity,
					uint256(-amountRemaining),
					zeroForOne
				);
		}

		bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

		// get the input/output amounts
		if (zeroForOne) {
			amountIn = max && exactIn
				? amountIn
				: SqrtPriceMath.getAmount0Delta(
					sqrtRatioNextX96,
					sqrtRatioCurrentX96,
					liquidity,
					true
				);
			amountOut = max && !exactIn
				? amountOut
				: SqrtPriceMath.getAmount1Delta(
					sqrtRatioNextX96,
					sqrtRatioCurrentX96,
					liquidity,
					false
				);
		} else {
			amountIn = max && exactIn
				? amountIn
				: SqrtPriceMath.getAmount1Delta(
					sqrtRatioCurrentX96,
					sqrtRatioNextX96,
					liquidity,
					true
				);
			amountOut = max && !exactIn
				? amountOut
				: SqrtPriceMath.getAmount0Delta(
					sqrtRatioCurrentX96,
					sqrtRatioNextX96,
					liquidity,
					false
				);
		}

		// cap the output amount to not exceed the remaining output amount
		if (!exactIn && amountOut > uint256(-amountRemaining)) {
			amountOut = uint256(-amountRemaining);
		}

		if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
			// we didn't reach the target, so take the remainder of the maximum input as fee
			feeAmount = uint256(amountRemaining) - amountIn;
		} else {
			feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
		}
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
	/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
	int24 internal constant MIN_TICK = -887272;
	/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
	int24 internal constant MAX_TICK = -MIN_TICK;

	/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
	uint160 internal constant MAX_SQRT_RATIO =
		1461446703485210103287273052203988822378723970342;

	/// @notice Calculates sqrt(1.0001^tick) * 2^96
	/// @dev Throws if |tick| > max tick
	/// @param tick The input tick for the above formula
	/// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
	/// at the given tick
	function getSqrtRatioAtTick(int24 tick)
		internal
		pure
		returns (uint160 sqrtPriceX96)
	{
		uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
		require(absTick <= uint256(int256(MAX_TICK)), "T");

		uint256 ratio = absTick & 0x1 != 0
			? 0xfffcb933bd6fad37aa2d162d1a594001
			: 0x100000000000000000000000000000000;
		if (absTick & 0x2 != 0)
			ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
		if (absTick & 0x4 != 0)
			ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
		if (absTick & 0x8 != 0)
			ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
		if (absTick & 0x10 != 0)
			ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
		if (absTick & 0x20 != 0)
			ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
		if (absTick & 0x40 != 0)
			ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
		if (absTick & 0x80 != 0)
			ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
		if (absTick & 0x100 != 0)
			ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
		if (absTick & 0x200 != 0)
			ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
		if (absTick & 0x400 != 0)
			ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
		if (absTick & 0x800 != 0)
			ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
		if (absTick & 0x1000 != 0)
			ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
		if (absTick & 0x2000 != 0)
			ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
		if (absTick & 0x4000 != 0)
			ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
		if (absTick & 0x8000 != 0)
			ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
		if (absTick & 0x10000 != 0)
			ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
		if (absTick & 0x20000 != 0)
			ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
		if (absTick & 0x40000 != 0)
			ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
		if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

		if (tick > 0) ratio = type(uint256).max / ratio;

		// this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
		// we then downcast because we know the result always fits within 160 bits due to our tick input constraint
		// we round up in the division so getTickAtSqrtRatio of the output price is always consistent
		sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
	}

	/// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
	/// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
	/// ever return.
	/// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
	/// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
	function getTickAtSqrtRatio(uint160 sqrtPriceX96)
		internal
		pure
		returns (int24 tick)
	{
		// second inequality must be < because the price can never reach the price at the max tick
		require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
		uint256 ratio = uint256(sqrtPriceX96) << 32;

		uint256 r = ratio;
		uint256 msb = 0;

		assembly {
			let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(5, gt(r, 0xFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(4, gt(r, 0xFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(3, gt(r, 0xFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(2, gt(r, 0xF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(1, gt(r, 0x3))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := gt(r, 0x1)
			msb := or(msb, f)
		}

		if (msb >= 128) r = ratio >> (msb - 127);
		else r = ratio << (127 - msb);

		// solhint-disable-next-line var-name-mixedcase
		int256 log_2 = (int256(msb) - 128) << 64;

		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(63, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(62, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(61, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(60, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(59, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(58, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(57, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(56, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(55, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(54, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(53, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(52, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(51, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(50, f))
		}

		// solhint-disable-next-line var-name-mixedcase
		int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

		int24 tickLow = int24(
			(log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
		);
		int24 tickHi = int24(
			(log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
		);

		tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
			? tickHi
			: tickLow;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Math library for liquidity
library LiquidityMath {
	/// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
	/// @param x The liquidity before change
	/// @param y The delta by which liquidity should be changed
	/// @return z The liquidity delta
	function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
		if (y < 0) {
			require((z = x - uint128(-y)) < x, "LS");
		} else {
			require((z = x + uint128(y)) >= x, "LA");
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
	/// @notice Returns the index of the most significant bit of the number,
	///     where the least significant bit is at index 0 and the most significant bit is at index 255
	/// @dev The function satisfies the property:
	///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
	/// @param x the value for which to compute the most significant bit, must be greater than 0
	/// @return r the index of the most significant bit
	function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
		// solhint-disable-next-line reason-string
		require(x > 0);

		if (x >= 0x100000000000000000000000000000000) {
			x >>= 128;
			r += 128;
		}
		if (x >= 0x10000000000000000) {
			x >>= 64;
			r += 64;
		}
		if (x >= 0x100000000) {
			x >>= 32;
			r += 32;
		}
		if (x >= 0x10000) {
			x >>= 16;
			r += 16;
		}
		if (x >= 0x100) {
			x >>= 8;
			r += 8;
		}
		if (x >= 0x10) {
			x >>= 4;
			r += 4;
		}
		if (x >= 0x4) {
			x >>= 2;
			r += 2;
		}
		if (x >= 0x2) r += 1;
	}

	/// @notice Returns the index of the least significant bit of the number,
	///     where the least significant bit is at index 0 and the most significant bit is at index 255
	/// @dev The function satisfies the property:
	///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
	/// @param x the value for which to compute the least significant bit, must be greater than 0
	/// @return r the index of the least significant bit
	function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
		// solhint-disable-next-line reason-string
		require(x > 0);

		r = 255;
		if (x & type(uint128).max > 0) {
			r -= 128;
		} else {
			x >>= 128;
		}
		if (x & type(uint64).max > 0) {
			r -= 64;
		} else {
			x >>= 64;
		}
		if (x & type(uint32).max > 0) {
			r -= 32;
		} else {
			x >>= 32;
		}
		if (x & type(uint16).max > 0) {
			r -= 16;
		} else {
			x >>= 16;
		}
		if (x & type(uint8).max > 0) {
			r -= 8;
		} else {
			x >>= 8;
		}
		if (x & 0xf > 0) {
			r -= 4;
		} else {
			x >>= 4;
		}
		if (x & 0x3 > 0) {
			r -= 2;
		} else {
			x >>= 2;
		}
		if (x & 0x1 > 0) r -= 1;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./LowGasSafeMath.sol";
import "./SafeCast.sol";

import "./FullMath.sol";
import "./UnsafeMath.sol";
import "./FixedPoint96.sol";
import "./BitMath.sol";

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
	using LowGasSafeMath for uint256;
	using SafeCast for uint256;

	/// @notice Gets the next sqrt price given a delta of token0
	/// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
	/// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
	/// price less in order to not send too much output.
	/// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
	/// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
	/// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
	/// @param liquidity The amount of usable liquidity
	/// @param amount How much of token0 to add or remove from virtual reserves
	/// @param add Whether to add or remove the amount of token0
	/// @return The price after adding or removing amount, depending on add
	function getNextSqrtPriceFromAmount0RoundingUp(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amount,
		bool add
	) internal pure returns (uint160) {
		// we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
		if (amount == 0) return sqrtPX96;
		uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

		bool overflow = false;
		if (numerator1 != 0 && sqrtPX96 != 0)
			overflow =
				uint256(BitMath.mostSignificantBit(numerator1)) +
					uint256(BitMath.mostSignificantBit(sqrtPX96)) >=
				254;

		if (add) {
			uint256 product;
			if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
				product = overflow
					? FullMath.mulDivRoundingUp(amount, sqrtPX96, uint256(liquidity))
					: product;
				numerator1 = overflow ? FixedPoint96.Q96 : numerator1;
				uint256 denominator = numerator1 + product;
				if (denominator >= numerator1) {
					// always fits in 160 bits
					return
						uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
				}
			}

			return
				uint160(
					UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount))
				);
		} else {
			uint256 product;
			// if the product overflows, we know the denominator underflows
			// in addition, we must check that the denominator does not underflow
			// solhint-disable-next-line reason-string
			require(
				(product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product
			);
			product = overflow
				? FullMath.mulDivRoundingUp(amount, sqrtPX96, uint256(liquidity))
				: product;
			numerator1 = overflow ? FixedPoint96.Q96 : numerator1;
			uint256 denominator = numerator1 - product;
			return
				FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
		}
	}

	/// @notice Gets the next sqrt price given a delta of token1
	/// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
	/// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
	/// price less in order to not send too much output.
	/// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
	/// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
	/// @param liquidity The amount of usable liquidity
	/// @param amount How much of token1 to add, or remove, from virtual reserves
	/// @param add Whether to add, or remove, the amount of token1
	/// @return The price after adding or removing `amount`
	function getNextSqrtPriceFromAmount1RoundingDown(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amount,
		bool add
	) internal pure returns (uint160) {
		// if we're adding (subtracting), rounding down requires rounding the quotient down (up)
		// in both cases, avoid a mulDiv for most inputs
		if (add) {
			uint256 quotient = (
				amount <= type(uint160).max
					? (amount << FixedPoint96.RESOLUTION) / liquidity
					: FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
			);

			return uint256(sqrtPX96).add(quotient).toUint160();
		} else {
			uint256 quotient = (
				amount <= type(uint160).max
					? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
					: FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
			);

			// solhint-disable-next-line reason-string
			require(sqrtPX96 > quotient);
			// always fits 160 bits
			return uint160(sqrtPX96 - quotient);
		}
	}

	/// @notice Gets the next sqrt price given an input amount of token0 or token1
	/// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
	/// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
	/// @param liquidity The amount of usable liquidity
	/// @param amountIn How much of token0, or token1, is being swapped in
	/// @param zeroForOne Whether the amount in is token0 or token1
	/// @return sqrtQX96 The price after adding the input amount to token0 or token1
	function getNextSqrtPriceFromInput(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amountIn,
		bool zeroForOne
	) internal pure returns (uint160 sqrtQX96) {
		// solhint-disable-next-line reason-string
		require(sqrtPX96 > 0);
		// solhint-disable-next-line reason-string
		require(liquidity > 0);

		// round to make sure that we don't pass the target price
		return
			zeroForOne
				? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
				: getNextSqrtPriceFromAmount1RoundingDown(
					sqrtPX96,
					liquidity,
					amountIn,
					true
				);
	}

	/// @notice Gets the next sqrt price given an output amount of token0 or token1
	/// @dev Throws if price or liquidity are 0 or the next price is out of bounds
	/// @param sqrtPX96 The starting price before accounting for the output amount
	/// @param liquidity The amount of usable liquidity
	/// @param amountOut How much of token0, or token1, is being swapped out
	/// @param zeroForOne Whether the amount out is token0 or token1
	/// @return sqrtQX96 The price after removing the output amount of token0 or token1
	function getNextSqrtPriceFromOutput(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amountOut,
		bool zeroForOne
	) internal pure returns (uint160 sqrtQX96) {
		// solhint-disable-next-line reason-string
		require(sqrtPX96 > 0);
		// solhint-disable-next-line reason-string
		require(liquidity > 0);

		// round to make sure that we pass the target price
		return
			zeroForOne
				? getNextSqrtPriceFromAmount1RoundingDown(
					sqrtPX96,
					liquidity,
					amountOut,
					false
				)
				: getNextSqrtPriceFromAmount0RoundingUp(
					sqrtPX96,
					liquidity,
					amountOut,
					false
				);
	}

	/// @notice Gets the amount0 delta between two prices
	/// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
	/// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param liquidity The amount of usable liquidity
	/// @param roundUp Whether to round the amount up or down
	/// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
	function getAmount0Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity,
		bool roundUp
	) internal pure returns (uint256 amount0) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
		uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;
		// solhint-disable-next-line reason-string
		require(sqrtRatioAX96 > 0);

		bool overflow = false;
		if (numerator1 != 0 && numerator2 != 0)
			overflow =
				uint256(BitMath.mostSignificantBit(numerator1)) +
					uint256(BitMath.mostSignificantBit(numerator2)) >=
				254;

		if (overflow) {
			return
				roundUp
					? FullMath.mulDivRoundingUp(
						FullMath.mulDivRoundingUp(uint256(liquidity), numerator2, sqrtRatioBX96),
						FixedPoint96.Q96,
						sqrtRatioAX96
					)
					: FullMath.mulDiv(
						FullMath.mulDiv(uint256(liquidity), numerator2, sqrtRatioBX96),
						FixedPoint96.Q96,
						sqrtRatioAX96
					);
		} else {
			return
				roundUp
					? UnsafeMath.divRoundingUp(
						FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
						sqrtRatioAX96
					)
					: FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
		}
	}

	/// @notice Gets the amount1 delta between two prices
	/// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param liquidity The amount of usable liquidity
	/// @param roundUp Whether to round the amount up, or down
	/// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
	function getAmount1Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity,
		bool roundUp
	) internal pure returns (uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		return
			roundUp
				? FullMath.mulDivRoundingUp(
					liquidity,
					sqrtRatioBX96 - sqrtRatioAX96,
					FixedPoint96.Q96
				)
				: FullMath.mulDiv(
					liquidity,
					sqrtRatioBX96 - sqrtRatioAX96,
					FixedPoint96.Q96
				);
	}

	/// @notice Helper that gets signed token0 delta
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param liquidity The change in liquidity for which to compute the amount0 delta
	/// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
	function getAmount0Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		int128 liquidity
	) internal pure returns (int256 amount0) {
		return
			liquidity < 0
				? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false)
					.toInt256()
				: getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true)
					.toInt256();
	}

	/// @notice Helper that gets signed token1 delta
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param liquidity The change in liquidity for which to compute the amount1 delta
	/// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
	function getAmount1Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		int128 liquidity
	) internal pure returns (int256 amount1) {
		return
			liquidity < 0
				? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false)
					.toInt256()
				: getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true)
					.toInt256();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
	/// @notice Returns ceil(x / y)
	/// @dev division by 0 has unspecified behavior, and must be checked externally
	/// @param x The dividend
	/// @param y The divisor
	/// @return z The quotient, ceil(x / y)
	function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly {
			z := add(div(x, y), gt(mod(x, y), 0))
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
	uint8 internal constant RESOLUTION = 96;
	uint256 internal constant Q96 = 0x1000000000000000000000000; // 2^96
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../../BaseTrader.sol";

import { ITrader } from "../../../interface/ITrader.sol";
import { IRouter02 } from "../../../interface/dex/uniswap/IRouter02.sol";

import { GenericSwapRequest, GenericRequestExactInOutParams as RequestExactInOutParams } from "../../../model/TradingModel.sol";

import { TokenTransferrer } from "../../../lib/token/TokenTransferrer.sol";
import { PathHelper } from "../../../lib/PathHelper.sol";

contract UniswapV2Trader is BaseTrader {
	using PathHelper for address[];

	IRouter02 public router;

	function setUp(address _router) external onlyContract(_router) initializer {
		__BASE_VESTA_INIT();

		router = IRouter02(_router);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		returns (uint256 swapResponse_)
	{
		GenericSwapRequest memory request = _safeDecodeSwapRequest(_request);

		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		return
			(request.expectedAmountIn != 0)
				? _swapExactInput(_receiver, request.path, request.expectedAmountIn)
				: _swapExactOutput(_receiver, request.path, request.expectedAmountOut);
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (GenericSwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (
			GenericSwapRequest memory request_
		) {
			return request_;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (GenericSwapRequest memory)
	{
		return abi.decode(_request, (GenericSwapRequest));
	}

	function _swapExactInput(
		address _receiver,
		address[] memory _path,
		uint256 _amountIn
	) internal returns (uint256 amountOut_) {
		address tokenIn = _path[0];

		_performTokenTransferFrom(tokenIn, msg.sender, address(this), _amountIn);
		_tryPerformMaxApprove(tokenIn, address(router));

		uint256[] memory values = router.swapExactTokensForTokens(
			_amountIn,
			0,
			_path,
			_receiver,
			block.timestamp
		);

		return values[values.length - 1];
	}

	function _swapExactOutput(
		address _receiver,
		address[] memory _path,
		uint256 _amountOut
	) internal returns (uint256 amountIn_) {
		address tokenIn = _path[0];
		uint256 amountInMax = router.getAmountsIn(_amountOut, _path)[0];

		_performTokenTransferFrom(tokenIn, msg.sender, address(this), amountInMax);
		_tryPerformMaxApprove(tokenIn, address(router));

		amountIn_ = router.swapTokensForExactTokens(
			_amountOut,
			amountInMax,
			_path,
			_receiver,
			block.timestamp
		)[0];

		if (amountIn_ < amountInMax) {
			_performTokenTransfer(tokenIn, msg.sender, amountInMax - amountIn_);
		}

		return amountIn_;
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		return router.getAmountsIn(params.amount, params.path)[0];
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		uint256[] memory values = router.getAmountsOut(params.amount, params.path);
		return values[values.length - 1];
	}

	function _safeDecodeRequestExactInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeRequestExactInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeRequestExactInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function generateSwapRequest(
		address[] calldata _path,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut
	) external pure returns (bytes memory) {
		return
			abi.encode(GenericSwapRequest(_path, _expectedAmountIn, _expectedAmountOut));
	}

	function generateExpectInOutRequest(address[] calldata _path, uint256 _amount)
		external
		pure
		returns (bytes memory)
	{
		return abi.encode(RequestExactInOutParams(_path, _amount));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRouter02 {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

library PathHelper {
	function tokenIn(address[] memory _path) internal pure returns (address) {
		return _path[0];
	}

	function tokenOut(address[] memory _path) internal pure returns (address) {
		return _path[_path.length - 1];
	}

	function isSinglePath(address[] memory _path) internal pure returns (bool) {
		return _path.length == 2;
	}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../BaseTrader.sol";

import { ITrader } from "../../interface/ITrader.sol";
import { IVault } from "../../interface/dex/gmx/IVault.sol";
import { IVaultUtils } from "../../interface/dex/gmx/IVaultUtils.sol";
import { IGlpRewardRouter } from "../../interface/dex/gmx/IGlpRewardRouter.sol";
import { IGLPManager } from "../../interface/dex/gmx/IGLPManager.sol";
import { IERC20 } from "../../interface/token/IERC20.sol";

import { GenericSwapRequest, GenericRequestExactInOutParams as RequestExactInOutParams } from "../../model/TradingModel.sol";

import { TokenTransferrer } from "../../lib/token/TokenTransferrer.sol";
import { PathHelper } from "../../lib/PathHelper.sol";

import { PathHelper } from "../../lib/PathHelper.sol";
import { FullMath } from "../../lib/FullMath.sol";

contract GMXTrader is BaseTrader {
	using PathHelper for address[];

	error InvalidRoutPathLenght();

	uint256 public constant BASIS_POINTS_DIVISOR = 10_000;
	uint256 public constant PRICE_PRECISION = 10**30;

	IVault public vault;
	IVaultUtils public vaultUtils;
	address public usdg;

	address public sGLP;
	IGlpRewardRouter public glpRewardRouter;
	IGLPManager public glpManager;

	function setUp(
		address _vault,
		address _vaultUtils,
		address _usdg,
		address _sGLP,
		address _glpRewardRouter,
		address _glpManager
	)
		external
		initializer
		onlyContracts(_vault, _vaultUtils)
		onlyContracts(_usdg, _sGLP)
		onlyContracts(_glpRewardRouter, _glpManager)
	{
		__BASE_VESTA_INIT();

		vault = IVault(_vault);
		vaultUtils = IVaultUtils(_vaultUtils);
		usdg = _usdg;
		sGLP = _sGLP;
		glpRewardRouter = IGlpRewardRouter(_glpRewardRouter);
		glpManager = IGLPManager(_glpManager);
	}

	function setGLP(address _sGLP) external onlyOwner {
		sGLP = _sGLP;
	}

	function setGLPRewardRouter(address _glpRewardRouter) external onlyOwner {
		glpRewardRouter = IGlpRewardRouter(_glpRewardRouter);
	}

	function setGLPManager(address _glpManager) external onlyOwner {
		glpManager = IGLPManager(_glpManager);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		returns (uint256)
	{
		GenericSwapRequest memory request = _safeDecodeSwapRequest(_request);
		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		address[] memory path = request.path;
		uint256 amountIn = request.expectedAmountIn;

		if (amountIn == 0) {
			amountIn = this.getAmountIn(
				abi.encode(RequestExactInOutParams(path, request.expectedAmountOut))
			);
		}

		return _swap(request.path, amountIn, _receiver);
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (GenericSwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (
			GenericSwapRequest memory request_
		) {
			return request_;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (GenericSwapRequest memory)
	{
		return abi.decode(_request, (GenericSwapRequest));
	}

	function _swap(
		address[] memory _path,
		uint256 _amountIn,
		address _receiver
	) internal returns (uint256) {
		if (_path.length < 2 || _path.length > 3) revert InvalidRoutPathLenght();

		if (_path[0] == sGLP || _path[1] == sGLP) {
			return _swapGLP(_path, _amountIn, _receiver);
		}

		_performTokenTransferFrom(_path[0], msg.sender, address(vault), _amountIn);

		if (_path.length == 2) {
			return _vaultSwap(_path[0], _path[1], _receiver);
		} else {
			uint256 midOut = _vaultSwap(_path[0], _path[1], address(this));
			_performTokenTransfer(_path[1], address(vault), midOut);
			return _vaultSwap(_path[1], _path[2], _receiver);
		}
	}

	function _swapGLP(
		address[] memory _path,
		uint256 _amountIn,
		address _receiver
	) internal returns (uint256 amountOut_) {
		address tokenIn = _path[0];

		_performTokenTransferFrom(tokenIn, msg.sender, address(this), _amountIn);

		if (tokenIn == sGLP) {
			return glpRewardRouter.unstakeAndRedeemGlp(_path[1], _amountIn, 0, _receiver);
		} else {
			_performApprove(tokenIn, address(glpManager), _amountIn);
			amountOut_ = glpRewardRouter.mintAndStakeGlp(tokenIn, _amountIn, 0, 0);
			_performTokenTransfer(sGLP, _receiver, amountOut_);

			return amountOut_;
		}
	}

	function _vaultSwap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) internal returns (uint256 amountOut_) {
		if (_tokenOut == usdg) {
			amountOut_ = IVault(vault).buyUSDG(_tokenIn, _receiver);
		} else if (_tokenIn == usdg) {
			amountOut_ = IVault(vault).sellUSDG(_tokenOut, _receiver);
		} else {
			amountOut_ = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
		}

		return amountOut_;
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256 amountIn_)
	{
		RequestExactInOutParams memory request = _safeDecodeRequestExactInOutParams(
			_request
		);

		address[] memory path = request.path;

		if (path[0] == sGLP || path[1] == sGLP) {
			amountIn_ = _getAmountInGLP(path, request.amount);
		} else if (path.isSinglePath()) {
			amountIn_ = _getAmountIn(path[1], path[0], request.amount);
		} else {
			amountIn_ = _getAmountIn(path[2], path[1], request.amount);
			amountIn_ = _getAmountIn(path[1], path[0], amountIn_);
		}

		amountIn_ += FullMath.mulDiv(
			amountIn_,
			EXACT_AMOUNT_IN_CORRECTION,
			CORRECTION_DENOMINATOR
		);

		return amountIn_;
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256 _amountOut)
	{
		RequestExactInOutParams memory request = _safeDecodeRequestExactInOutParams(
			_request
		);

		address[] memory path = request.path;

		if (path[0] == sGLP || path[1] == sGLP) {
			return _getAmountOutGLP(path, request.amount);
		}

		if (path.isSinglePath()) {
			_amountOut = _getAmountOut(path[0], path[1], request.amount);
		} else {
			_amountOut = _getAmountOut(path[0], path[1], request.amount);
			_amountOut = _getAmountOut(path[1], path[2], _amountOut);
		}

		return _amountOut;
	}

	function _safeDecodeRequestExactInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeRequestExactInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeRequestExactInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function _getAmountInGLP(address[] memory _path, uint256 _amount)
		internal
		view
		returns (uint256 amountIn_)
	{
		bool firstIsGLP = _path[0] == sGLP;
		address nonGLPToken = firstIsGLP ? _path[1] : _path[0];

		if (firstIsGLP) {
			return _getMintGLP(nonGLPToken, _amount, true);
		} else {
			return _getRedeemGLP(nonGLPToken, _amount, false);
		}
	}

	function _getAmountOutGLP(address[] memory _path, uint256 _amount)
		internal
		view
		returns (uint256 amountIn_)
	{
		bool firstIsGLP = _path[0] == sGLP;
		address nonGLPToken = firstIsGLP ? _path[1] : _path[0];

		if (firstIsGLP) {
			return _getRedeemGLP(nonGLPToken, _amount, true);
		} else {
			return _getMintGLP(nonGLPToken, _amount, false);
		}
	}

	function _getMintGLP(
		address _tokenOut,
		uint256 _amount,
		bool _maximise
	) internal view returns (uint256 amountIn_) {
		uint256 aumInUsdg = glpManager.getAumInUsdg(_maximise);
		uint256 glpSupply = IERC20(glpManager.glp()).totalSupply();

		uint256 usdgAmount = _getBuyUSDG(_tokenOut, _amount, !_maximise);

		return
			aumInUsdg == 0
				? usdgAmount
				: FullMath.mulDiv(usdgAmount, glpSupply, aumInUsdg);
	}

	function _getBuyUSDG(
		address _token,
		uint256 _tokenAmount,
		bool _maximise
	) internal view returns (uint256) {
		uint256 price = _getTokenPrice(_token, _maximise);

		uint256 usdgAmount = vault.adjustForDecimals(
			FullMath.mulDiv(_tokenAmount, price, PRICE_PRECISION),
			_token,
			usdg
		);

		uint256 feeBasisPoints = _maximise
			? vaultUtils.getBuyUsdgFeeBasisPoints(_token, usdgAmount)
			: vaultUtils.getSellUsdgFeeBasisPoints(_token, usdgAmount);

		uint256 amountAfterFees = _maximise
			? _getAmountAfterFees(_tokenAmount, feeBasisPoints)
			: FullMath.mulDiv(
				_tokenAmount,
				(BASIS_POINTS_DIVISOR + feeBasisPoints),
				BASIS_POINTS_DIVISOR
			);

		return
			vault.adjustForDecimals(
				FullMath.mulDiv(amountAfterFees, price, PRICE_PRECISION),
				_token,
				usdg
			);
	}

	function _getRedeemGLP(
		address _tokenOut,
		uint256 _amount,
		bool _maximise
	) internal view returns (uint256 amountOut_) {
		uint256 aumInUsdg = glpManager.getAumInUsdg(_maximise);
		uint256 glpSupply = IERC20(glpManager.glp()).totalSupply();
		return
			_getSellUSDG(
				_tokenOut,
				FullMath.mulDiv(_amount, aumInUsdg, glpSupply),
				!_maximise
			);
	}

	function _getSellUSDG(
		address _token,
		uint256 _usdgAmount,
		bool _maximise
	) internal view returns (uint256) {
		uint256 price = _getTokenPrice(_token, _maximise);

		uint256 redemptionAmount = vault.adjustForDecimals(
			FullMath.mulDiv(_usdgAmount, PRICE_PRECISION, price),
			usdg,
			_token
		);

		uint256 feeBasisPoints = _maximise
			? vaultUtils.getBuyUsdgFeeBasisPoints(_token, _usdgAmount)
			: vaultUtils.getSellUsdgFeeBasisPoints(_token, _usdgAmount);

		return
			_maximise
				? FullMath.mulDiv(
					redemptionAmount,
					(BASIS_POINTS_DIVISOR + feeBasisPoints),
					BASIS_POINTS_DIVISOR
				)
				: _getAmountAfterFees(redemptionAmount, feeBasisPoints);
	}

	function _getAmountIn(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount
	) internal view returns (uint256 amountIn_) {
		uint256 priceIn = _getTokenPrice(_tokenIn, true);
		uint256 priceOut = _getTokenPrice(_tokenOut, false);

		amountIn_ = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, priceOut),
			_tokenIn,
			_tokenOut
		);

		uint256 usdgAmount = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, PRICE_PRECISION),
			_tokenIn,
			usdg
		);

		uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(
			_tokenOut,
			_tokenIn,
			usdgAmount
		);

		return
			FullMath.mulDiv(
				amountIn_,
				(BASIS_POINTS_DIVISOR + feeBasisPoints),
				BASIS_POINTS_DIVISOR
			);
	}

	function _getAmountOut(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount
	) internal view returns (uint256 amountOut_) {
		uint256 priceIn = _getTokenPrice(_tokenIn, false);
		uint256 priceOut = _getTokenPrice(_tokenOut, true);

		amountOut_ = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, priceOut),
			_tokenIn,
			_tokenOut
		);

		uint256 usdgAmount = vault.adjustForDecimals(
			FullMath.mulDiv(_amount, priceIn, PRICE_PRECISION),
			_tokenIn,
			usdg
		);

		uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(
			_tokenIn,
			_tokenOut,
			usdgAmount
		);

		return _getAmountAfterFees(amountOut_, feeBasisPoints);
	}

	function _getTokenPrice(address _token, bool _maximise)
		internal
		view
		returns (uint256 price_)
	{
		if (_token == sGLP) {
			price_ = (glpManager.getAum(_maximise) /
				IERC20(glpManager.glp()).totalSupply());
		} else if (_maximise) {
			price_ = vault.getMaxPrice(_token);
		} else {
			price_ = vault.getMinPrice(_token);
		}

		return price_;
	}

	function _getAmountAfterFees(uint256 _amount, uint256 _feeBasisPoints)
		private
		pure
		returns (uint256)
	{
		return
			FullMath.mulDiv(
				_amount,
				(BASIS_POINTS_DIVISOR - _feeBasisPoints),
				BASIS_POINTS_DIVISOR
			);
	}

	function generateSwapRequest(
		address[] calldata _path,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut
	) external pure returns (bytes memory) {
		return
			abi.encode(GenericSwapRequest(_path, _expectedAmountIn, _expectedAmountOut));
	}

	function generateExpectInOutRequest(address[] calldata _path, uint256 _amount)
		external
		pure
		returns (bytes memory)
	{
		return abi.encode(RequestExactInOutParams(_path, _amount));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVault {
	function buyUSDG(address _token, address _receiver) external returns (uint256);

	function sellUSDG(address _token, address _receiver) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function adjustForDecimals(
		uint256 _amount,
		address _tokenDiv,
		address _tokenMul
	) external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function taxBasisPoints() external view returns (uint256);

	function stableTokens(address) external view returns (bool);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function hasDynamicFees() external view returns (bool);

	function usdgAmounts(address _token) external view returns (uint256);

	function getTargetUsdgAmount(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultUtils {
	function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		external
		view
		returns (uint256);

	function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		external
		view
		returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdgDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdgAmount
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGlpRewardRouter {
	function unstakeAndRedeemGlp(
		address _tokenOut,
		uint256 _glpAmount,
		uint256 _minOut,
		address _receiver
	) external returns (uint256);

	function mintAndStakeGlp(
		address _token,
		uint256 _amount,
		uint256 _minUsdg,
		uint256 _minGlp
	) external returns (uint256);
}

pragma solidity >=0.8.0;

interface IGLPManager {
	function getAum(bool maximise) external view returns (uint256);

	function getAumInUsdg(bool maximise) external view returns (uint256);

	function glp() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
	/// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = a * b
			// Compute the product mod 2**256 and mod 2**256 - 1
			// then use the Chinese Remainder Theorem to reconstruct
			// the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2**256 + prod0
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(a, b, not(0))
				prod0 := mul(a, b)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division
			if (prod1 == 0) {
				require(denominator > 0);
				assembly {
					result := div(prod0, denominator)
				}
				return result;
			}

			// Make sure the result is less than 2**256.
			// Also prevents denominator == 0
			require(denominator > prod1);

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0]
			// Compute remainder using mulmod
			uint256 remainder;
			assembly {
				remainder := mulmod(a, b, denominator)
			}
			// Subtract 256 bit number from 512 bit number
			assembly {
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator
			// Compute largest power of two divisor of denominator.
			// Always >= 1.
			uint256 twos = (type(uint256).max - denominator + 1) & denominator;
			// Divide denominator by power of two
			assembly {
				denominator := div(denominator, twos)
			}

			// Divide [prod1 prod0] by the factors of two
			assembly {
				prod0 := div(prod0, twos)
			}
			// Shift in bits from prod1 into prod0. For this we need
			// to flip `twos` such that it is 2**256 / twos.
			// If twos is zero, then it becomes one
			assembly {
				twos := add(div(sub(0, twos), twos), 1)
			}
			prod0 |= prod1 * twos;

			// Invert denominator mod 2**256
			// Now that denominator is an odd number, it has an inverse
			// modulo 2**256 such that denominator * inv = 1 mod 2**256.
			// Compute the inverse by starting with a seed that is correct
			// correct for four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inv = (3 * denominator) ^ 2;
			// Now use Newton-Raphson iteration to improve the precision.
			// Thanks to Hensel's lifting lemma, this also works in modular
			// arithmetic, doubling the correct bits in each step.
			inv *= 2 - denominator * inv; // inverse mod 2**8
			inv *= 2 - denominator * inv; // inverse mod 2**16
			inv *= 2 - denominator * inv; // inverse mod 2**32
			inv *= 2 - denominator * inv; // inverse mod 2**64
			inv *= 2 - denominator * inv; // inverse mod 2**128
			inv *= 2 - denominator * inv; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying
			// with the modular inverse of denominator. This will give us the
			// correct result modulo 2**256. Since the precoditions guarantee
			// that the outcome is less than 2**256, this is the final result.
			// We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inv;
			return result;
		}
	}

	/// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	function mulDivRoundingUp(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		result = mulDiv(a, b, denominator);
		unchecked {
			if (mulmod(a, b, denominator) > 0) {
				require(result < type(uint256).max);
				result++;
			}
		}
	}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { BaseTrader } from "../BaseTrader.sol";
import { ICurvePool } from "../../interface/dex/curve/ICurvePool.sol";

import { CurveSwapRequest, CurveRequestExactInOutParams as RequestExactInOutParams } from "../../model/TradingModel.sol";
import { PoolConfig } from "../../model/CurveModel.sol";

import { FullMath } from "../../lib/FullMath.sol";
import { IERC20 } from "../../interface/token/IERC20.sol";

contract CurveTrader is BaseTrader {
	error ExchangeReturnedRevert();
	error GetDyReturnedRevert();
	error PoolNotRegistered();
	error InvalidCoinsSize();

	event PoolRegistered(address indexed pool);
	event PoolUnRegistered(address indexed pool);

	uint256 public constant PRECISION = 1e27;
	uint128 public constant BPS_DEMOMINATOR = 10_000;
	uint8 public constant TARGET_DECIMALS = 18;

	mapping(address => PoolConfig) internal curvePools;

	modifier onlyRegistered(address _pool) {
		if (curvePools[_pool].tokens.length == 0) {
			revert PoolNotRegistered();
		}
		_;
	}

	function setUp() external initializer {
		__BASE_VESTA_INIT();
	}

	function registerPool(
		address _pool,
		uint8 _totalCoins,
		string calldata _get_dy_signature,
		string calldata _exchange_signature
	) external onlyOwner onlyContract(_pool) {
		if (_totalCoins < 2) revert InvalidCoinsSize();

		address[] memory tokens = new address[](_totalCoins);
		address token;

		for (uint256 i = 0; i < _totalCoins; ++i) {
			token = ICurvePool(_pool).coins(i);
			tokens[i] = token;

			_performApprove(token, _pool, MAX_UINT256);
		}

		curvePools[_pool] = PoolConfig({
			tokens: tokens,
			get_dy_signature: _get_dy_signature,
			exchange_signature: _exchange_signature
		});

		emit PoolRegistered(_pool);
	}

	function unregisterPool(address _pool) external onlyOwner onlyRegistered(_pool) {
		delete curvePools[_pool];
		emit PoolUnRegistered(_pool);
	}

	function exchange(address _receiver, bytes memory _request)
		external
		override
		returns (uint256 swapResponse_)
	{
		CurveSwapRequest memory request = _safeDecodeSwapRequest(_request);

		_validExpectingAmount(request.expectedAmountIn, request.expectedAmountOut);

		if (!isPoolRegistered(request.pool)) {
			revert PoolNotRegistered();
		}

		PoolConfig memory curve = curvePools[request.pool];
		address pool = request.pool;
		int128 i = int128(int8(request.coins[0]));
		int128 j = int128(int8(request.coins[1]));
		address tokenOut = curve.tokens[uint128(j)];

		if (request.expectedAmountIn == 0) {
			uint256 amountIn = _getExpectAmountIn(
				pool,
				curve.get_dy_signature,
				i,
				j,
				request.expectedAmountOut
			);

			request.expectedAmountIn =
				amountIn +
				FullMath.mulDiv(amountIn, request.slippage, BPS_DEMOMINATOR);
		} else {
			request.expectedAmountOut = _get_dy(
				pool,
				curve.get_dy_signature,
				i,
				j,
				request.expectedAmountIn
			);
		}

		_performTokenTransferFrom(
			curve.tokens[uint128(i)],
			msg.sender,
			address(this),
			request.expectedAmountIn
		);

		uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

		(bool success, ) = pool.call{ value: 0 }(
			abi.encodeWithSignature(
				curve.exchange_signature,
				i,
				j,
				request.expectedAmountIn,
				request.expectedAmountOut,
				false
			)
		);

		if (!success) revert ExchangeReturnedRevert();

		uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));
		uint256 result = balanceAfter - balanceBefore;

		_performTokenTransfer(curve.tokens[uint128(j)], _receiver, result);

		return result;
	}

	function _safeDecodeSwapRequest(bytes memory _request)
		internal
		view
		returns (CurveSwapRequest memory)
	{
		try this.decodeSwapRequest(_request) returns (CurveSwapRequest memory params) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeSwapRequest(bytes memory _request)
		external
		pure
		returns (CurveSwapRequest memory)
	{
		return abi.decode(_request, (CurveSwapRequest));
	}

	function getAmountIn(bytes memory _request)
		external
		view
		override
		returns (uint256 amountIn_)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		PoolConfig memory curve = curvePools[params.pool];

		amountIn_ = _getExpectAmountIn(
			params.pool,
			curve.get_dy_signature,
			int128(int8(params.coins[0])),
			int128(int8(params.coins[1])),
			params.amount
		);

		amountIn_ += FullMath.mulDiv(amountIn_, params.slippage, BPS_DEMOMINATOR);

		return amountIn_;
	}

	function _getExpectAmountIn(
		address _pool,
		string memory _get_dy_signature,
		int128 _coinA,
		int128 _coinB,
		uint256 _expectOut
	) internal view returns (uint256 amountIn_) {
		uint256 estimationIn = _get_dy(
			_pool,
			_get_dy_signature,
			_coinB,
			_coinA,
			_expectOut
		);
		uint256 estimationOut = _get_dy(
			_pool,
			_get_dy_signature,
			_coinA,
			_coinB,
			estimationIn
		);

		uint256 rate = FullMath.mulDiv(estimationIn, PRECISION, estimationOut);
		amountIn_ = FullMath.mulDiv(rate, _expectOut, PRECISION);
		amountIn_ += FullMath.mulDiv(
			amountIn_,
			EXACT_AMOUNT_IN_CORRECTION,
			CORRECTION_DENOMINATOR
		);

		return amountIn_;
	}

	function getAmountOut(bytes memory _request)
		external
		view
		override
		returns (uint256)
	{
		RequestExactInOutParams memory params = _safeDecodeRequestExactInOutParams(
			_request
		);

		address pool = params.pool;

		return
			_get_dy(
				pool,
				curvePools[pool].get_dy_signature,
				int128(int8(params.coins[0])),
				int128(int8(params.coins[1])),
				params.amount
			);
	}

	function _get_dy(
		address _pool,
		string memory _signature,
		int128 i,
		int128 j,
		uint256 dx
	) internal view returns (uint256) {
		bool success;
		bytes memory data;

		(success, data) = _pool.staticcall(
			abi.encodeWithSignature(_signature, i, j, dx)
		);

		if (!success) {
			revert GetDyReturnedRevert();
		}

		return abi.decode(data, (uint256));
	}

	function _safeDecodeRequestExactInOutParams(bytes memory _request)
		internal
		view
		returns (RequestExactInOutParams memory)
	{
		try this.decodeDecodeRequestExactInOutParams(_request) returns (
			RequestExactInOutParams memory params
		) {
			return params;
		} catch {
			revert InvalidRequestEncoding();
		}
	}

	function decodeDecodeRequestExactInOutParams(bytes memory _request)
		external
		pure
		returns (RequestExactInOutParams memory)
	{
		return abi.decode(_request, (RequestExactInOutParams));
	}

	function getPoolConfigOf(address _pool) external view returns (PoolConfig memory) {
		return curvePools[_pool];
	}

	function isPoolRegistered(address _pool) public view returns (bool) {
		return curvePools[_pool].tokens.length != 0;
	}

	function generateSwapRequest(
		address _pool,
		uint8[2] calldata _coins,
		uint256 _expectedAmountIn,
		uint256 _expectedAmountOut,
		uint16 _slippage
	) external pure returns (bytes memory) {
		return
			abi.encode(
				CurveSwapRequest(
					_pool,
					_coins,
					_expectedAmountIn,
					_expectedAmountOut,
					_slippage
				)
			);
	}

	function generateExpectInOutRequest(
		address _pool,
		uint8[2] calldata _coins,
		uint256 _amount,
		uint16 _slippage
	) external pure returns (bytes memory) {
		return abi.encode(RequestExactInOutParams(_pool, _coins, _amount, _slippage));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @param tokens should have the same array of coins from the curve pool
 * @param uint8 holds the decimals of each tokens
 * @param underlying is the curve pool uses underlying
 */
struct PoolConfig {
	address[] tokens;
	string get_dy_signature;
	string exchange_signature;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
	function deposit() external payable;

	function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IVault } from "../../interface/dex/gmx/IVault.sol";
import { IVaultUtils } from "../../interface/dex/gmx/IVaultUtils.sol";

/**
 * Deployed by Vesta because we needed this little helper
 * There's no ownership attach to it.
 *
 * We didn't modify the core logic whatsoever, we just removed the functions that we do not need
 *
 * Ref: https://github.com/gmx-io/gmx-contracts/blob/master/contracts/core/VaultUtils.sol
 * Commit Id: 1a901D0
 */
contract VaultUtils is IVaultUtils {
	IVault public vault;

	uint256 public constant BASIS_POINTS_DIVISOR = 10000;
	uint256 public constant FUNDING_RATE_PRECISION = 1000000;

	constructor(address _vault) {
		require(_vault != address(0), "Invalid Vault Address");
		vault = IVault(_vault);
	}

	function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		public
		view
		override
		returns (uint256)
	{
		return
			getFeeBasisPoints(
				_token,
				_usdgAmount,
				vault.mintBurnFeeBasisPoints(),
				vault.taxBasisPoints(),
				true
			);
	}

	function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount)
		public
		view
		override
		returns (uint256)
	{
		return
			getFeeBasisPoints(
				_token,
				_usdgAmount,
				vault.mintBurnFeeBasisPoints(),
				vault.taxBasisPoints(),
				false
			);
	}

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdgAmount
	) public view override returns (uint256) {
		bool isStableSwap = vault.stableTokens(_tokenIn) &&
			vault.stableTokens(_tokenOut);

		uint256 baseBps = isStableSwap
			? vault.stableSwapFeeBasisPoints()
			: vault.swapFeeBasisPoints();
		uint256 taxBps = isStableSwap
			? vault.stableTaxBasisPoints()
			: vault.taxBasisPoints();
		uint256 feesBasisPoints0 = getFeeBasisPoints(
			_tokenIn,
			_usdgAmount,
			baseBps,
			taxBps,
			true
		);
		uint256 feesBasisPoints1 = getFeeBasisPoints(
			_tokenOut,
			_usdgAmount,
			baseBps,
			taxBps,
			false
		);
		// use the higher of the two fee basis points
		return feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
	}

	// cases to consider
	// 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
	// 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
	// 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
	// 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
	// 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
	// 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
	// 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
	// 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
	function getFeeBasisPoints(
		address _token,
		uint256 _usdgDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) public view override returns (uint256) {
		if (!vault.hasDynamicFees()) {
			return _feeBasisPoints;
		}

		uint256 initialAmount = vault.usdgAmounts(_token);
		uint256 nextAmount = initialAmount + _usdgDelta;
		if (!_increment) {
			nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
		}

		uint256 targetAmount = vault.getTargetUsdgAmount(_token);
		if (targetAmount == 0) {
			return _feeBasisPoints;
		}

		uint256 initialDiff = initialAmount > targetAmount
			? initialAmount - targetAmount
			: targetAmount - initialAmount;
		uint256 nextDiff = nextAmount > targetAmount
			? nextAmount - targetAmount
			: targetAmount - nextAmount;

		// action improves relative asset balance
		if (nextDiff < initialDiff) {
			uint256 rebateBps = (_taxBasisPoints * initialDiff) / targetAmount;
			return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints - rebateBps;
		}

		uint256 averageDiff = (initialDiff + nextDiff) / 2;
		if (averageDiff > targetAmount) {
			averageDiff = targetAmount;
		}
		uint256 taxBps = (_taxBasisPoints * averageDiff) / targetAmount;
		return _feeBasisPoints + taxBps;
	}
}