// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Version.sol";
import "./interfaces/IFeeCalculator.sol";
import "./common/Errors.sol";

// Playground for volume tracking: https://github.com/vertex-protocol/vertex-evm/commit/b52ea07a6b40ab8b0d8198886bc4ac6e60c61233
contract FeeCalculator is Initializable, IFeeCalculator, Version {
    address private clearinghouse;
    mapping(address => mapping(uint32 => FeeRates)) feeRates;

    function initialize() external initializer {}

    function migrate(address _clearinghouse) external {
        require(clearinghouse == address(0), "already migrated");
        clearinghouse = _clearinghouse;
    }

    function getClearinghouse() external view returns (address) {
        return clearinghouse;
    }

    function recordVolume(bytes32 subaccount, uint128 quoteVolume) external {}

    function getFeeFractionX18(
        bytes32 subaccount,
        uint32 productId,
        bool taker
    ) external view returns (int128) {
        require(productId != 0 && productId <= 6, "invalid productId");
        FeeRates memory userFeeRates = feeRates[
            address(uint160(bytes20(subaccount)))
        ][productId];
        if (userFeeRates.isNonDefault == 0) {
            // use the default fee rates.
            if (productId == 1 || productId == 3 || productId == 5) {
                userFeeRates = FeeRates(0, 300_000_000_000_000, 1);
            } else if (productId == 2 || productId == 4 || productId == 6) {
                userFeeRates = FeeRates(0, 200_000_000_000_000, 1);
            }
        }
        return taker ? userFeeRates.takerRateX18 : userFeeRates.makerRateX18;
    }

    function getInterestFeeFractionX18(
        uint32 /* productId */
    ) external pure returns (int128) {
        return 200_000_000_000_000_000; // 20%
    }

    function getLiquidationFeeFractionX18(
        bytes32, /* subaccount */
        uint32 /* productId */
    ) external pure returns (int128) {
        return 250_000_000_000_000_000; // 25%
    }

    function updateFeeRates(
        address user,
        uint32 productId,
        int64 makerRateX18,
        int64 takerRateX18
    ) external {
        require(msg.sender == clearinghouse, ERR_UNAUTHORIZED);
        feeRates[user][productId] = FeeRates(makerRateX18, takerRateX18, 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./common/Constants.sol";
import "./interfaces/IVersion.sol";

abstract contract Version is IVersion {
    function getVersion() external pure returns (uint64) {
        return VERSION;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./IVersion.sol";

interface IFeeCalculator is IVersion {
    struct FeeRates {
        int64 makerRateX18;
        int64 takerRateX18;
        uint8 isNonDefault; // 1: non-default, 0: default
    }

    function getClearinghouse() external view returns (address);

    function migrate(address _clearinghouse) external;

    function recordVolume(bytes32 subaccount, uint128 quoteVolume) external;

    function getFeeFractionX18(
        bytes32 subaccount,
        uint32 productId,
        bool taker
    ) external view returns (int128);

    function getInterestFeeFractionX18(uint32 productId)
        external
        view
        returns (int128);

    function getLiquidationFeeFractionX18(bytes32 subaccount, uint32 productId)
        external
        view
        returns (int128);

    function updateFeeRates(
        address user,
        uint32 productId,
        int64 makerRateX18,
        int64 takerRateX18
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// Trying to take an action on vertex when
string constant ERR_REQUIRES_DEPOSIT = "RS";

// ERC20 Transfer failed
string constant ERR_TRANSFER_FAILED = "TF";

// Unauthorized
string constant ERR_UNAUTHORIZED = "U";

// Invalid product
string constant ERR_INVALID_PRODUCT = "IP";

// Subaccount health too low
string constant ERR_SUBACCT_HEALTH = "SH";

// Not liquidatable
string constant ERR_NOT_LIQUIDATABLE = "NL";

// Liquidator health too low
string constant ERR_NOT_LIQUIDATABLE_INITIAL = "NLI";

// Liquidatee has positive initial health
string constant ERR_LIQUIDATED_TOO_MUCH = "LTM";

// Trying to liquidate quote, or
string constant ERR_INVALID_LIQUIDATION_PARAMS = "NILP";

// Trying to liquidate perp but the amount is not divisible by sizeIncrement
string constant ERR_INVALID_LIQUIDATION_AMOUNT = "NILA";

// Tried to liquidate too little, too much or signs are different
string constant ERR_NOT_LIQUIDATABLE_AMT = "NLA";

// Tried to liquidate liabilities before perps
string constant ERR_NOT_LIQUIDATABLE_LIABILITIES = "NLL";

// Tried to finalize subaccount that cannot be finalized
string constant ERR_NOT_FINALIZABLE_SUBACCOUNT = "NFS";

// Not enough quote to settle
string constant ERR_CANNOT_SETTLE = "CS";

// Not enough insurance to settle
string constant ERR_NO_INSURANCE = "NI";

// Above reserve ratio
string constant ERR_RESERVE_RATIO = "RR";

// Invalid socialize amount
string constant ERR_INVALID_SOCIALIZE_AMT = "ISA";

// Socializing product with no open interest
string constant ERR_NO_OPEN_INTEREST = "NOI";

// FOK not filled, this isn't rly an error so this is jank
string constant ERR_FOK_NOT_FILLED = "ENF";

// bad product config via weights
string constant ERR_BAD_PRODUCT_CONFIG = "BPC";

// subacct name too long
string constant ERR_LONG_NAME = "LN";

// already registered in health group
string constant ERR_ALREADY_REGISTERED = "AR";

// invalid health group provided
string constant ERR_INVALID_HEALTH_GROUP = "IHG";

// trying to burn more LP than owned
string constant ERR_INSUFFICIENT_LP = "ILP";

// taker order subaccount fails risk or is invalid
string constant ERR_INVALID_TAKER = "IT";

// maker order subaccount fails risk or is invalid
string constant ERR_INVALID_MAKER = "IM";

string constant ERR_INVALID_SIGNATURE = "IS";

string constant ERR_ORDERS_CANNOT_BE_MATCHED = "OCBM";

string constant ERR_INVALID_LP_AMOUNT = "ILA";

string constant ERR_SLIPPAGE_TOO_HIGH = "STH";

string constant ERR_SUBACCOUNT_NOT_FOUND = "SNF";

string constant ERR_INVALID_PRICE = "IPR";

string constant ERR_INVALID_TIME = "ITI";

// states on node and engine are not same
string constant ERR_DSYNC = "DSYNC";

string constant ERR_INVALID_SWAP_PARAMS = "ISP";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @dev Each clearinghouse has a unique quote product
uint32 constant QUOTE_PRODUCT_ID = 0;

/// @dev Fees account
bytes32 constant FEES_ACCOUNT = bytes32(0);

uint128 constant MINIMUM_LIQUIDITY = 10**3;

int128 constant ONE = 10**18;

uint8 constant MAX_DECIMALS = 18;

int128 constant TAKER_SEQUENCER_FEE = 4e17; // $0.40

int128 constant SLOW_MODE_FEE = 1000000; // $1

int128 constant LIQUIDATION_FEE = 1e18; // $1
int128 constant HEALTHCHECK_FEE = 1e18; // $1

uint64 constant VERSION = 14;

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVersion {
    function getVersion() external returns (uint64);
}