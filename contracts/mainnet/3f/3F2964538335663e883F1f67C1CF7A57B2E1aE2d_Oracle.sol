// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title A LayerZero example sending a cross chain message from a source chain to a destination chain to increment a counter
interface IPriceFeed {
    /**
     * @notice Configures role manager address
     * This function can only be accessed by the account with role DEFAULT_ADMIN_ROLE.
     * @param roleManagerAddress - address of the roleManager contract.
     **/
    function setRoleManager(address roleManagerAddress) external;

    /**
     * @notice Configures the prices of assets
     * This function can only be accessed by the account with role SET_ORACLE_METHOD.
     * @param _symbols - list of pool ids of the assets
     * @param _prices - prices of the asset
     **/
    function setPrices(
        bytes32[] memory _symbols,
        uint256[] memory _prices
    ) external;

    /**
     * @notice Configures the prices of assets
     * This function can only be accessed by the account with role SET_ORACLE_METHOD.
     * @param _symbol - pool id of the asset
     * @param _price - price of the asset
     **/
    function setPrice(bytes32 _symbol, uint256 _price) external;

    /**
     * @notice Returns price of assets
     * @param _symbols - list of the asset's pool id
     **/
    function getPrices(
        bytes32[] memory _symbols
    ) external view returns (uint256[] memory results);

    /**
     * @notice Returns price of an asset
     * @param _symbol - pool id of the asset
     **/
    function getPrice(bytes32 _symbol) external view returns (uint256 result);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRoleManager {
    /**
     * @notice Sets new adminRole for a role
     * This function can be called by the account having adminRole for the `role`
     * @param role - particular role 
     * @param adminRole - new role to be assigned as admin
     **/
    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external;

    /**
     * @notice Checks role for an account
     * Reverts if the account doesnt have permission of the role
     * @param role - role of contract.
     * @param account - address of user.
     **/
    function checkRole(bytes32 role, address account) external view ;

     /**
     * @notice Returns bytes32 value of the public variable DEFAULT_ADMIN_ROLE
     **/
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_POOL_METHOD
     **/
    function SET_POOL_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_CORE_METHOD
     **/
    function SET_CORE_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_ADAPTER_METHOD
     **/
    function SET_ADAPTER_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_ROUTE_METHOD
     **/
    function SET_ROUTE_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_LIQUIDATION_METHOD
     **/
    function SET_LIQUIDATION_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_FEEPROVIDER_METHOD
     **/
    function SET_FEEPROVIDER_METHOD() external view returns (bytes32);

     /**
     * @notice Returns bytes32 value of the public variable SET_ORACLE_METHOD
     **/
    function SET_ORACLE_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_CE_TOKEN_METHOD
     **/
    function SET_CE_TOKEN_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SET_CONTROLLER_METHOD
     **/
    function SET_CONTROLLER_METHOD() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable INIT_POOL
     **/
    function INIT_POOL() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable POOL_STATUS
     **/
    function POOL_STATUS() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable PROTOCOL_PAUSE
     **/
    function PROTOCOL_PAUSE() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable MINT_BURN_CE_DEBT_TOKEN
     **/
    function MINT_BURN_CE_DEBT_TOKEN() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable SWAP
     **/
    function SWAP() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable POOL
     **/
    function POOL() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable CORE
     **/
    function CORE() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable LIQUIDATION_MANAGER
     **/
    function LIQUIDATION_MANAGER() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable FEE_PROVIDER
     **/
    function FEE_PROVIDER() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable ADAPTER
     **/
    function ADAPTER() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable ROUTE
     **/
    function ROUTE() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable CONTROLLER
     **/
    function CONTROLLER() external view returns (bytes32);




}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IPriceFeed.sol";

string constant TAG = "Oracle";

interface IERC20 {
    function decimals() external view returns (uint8);
}

/**
* @title Oracle contract
* @notice Used to get real time price of an asset
**/
contract Oracle is Initializable, ContextUpgradeable {
    uint8 public constant ROOT_DECIMALS = 18;
    uint256 public GRACE_PERIOD_TIME;
    address public roleManager;
    address public priceFeed;
    address public sequencerUptimeFeed;

    mapping(bytes32 => address) public aggregator;
    mapping(bytes32 => bool) public fetchFromPriceFeed;
    mapping(bytes32 => uint256) public maxValue;
    mapping(bytes32 => uint256) public minValue;
    mapping(bytes32 => uint256) public heartBeatValue;

    error ChainlinkMalfunction(string contractTAG, bytes32 symbol);
    error RoundNotComplete(string contractTAG, bytes32 symbol);
    error StaleData(string contractTAG, bytes32 symbol);
    error PriceOutDated(string contractTAG, bytes32 symbol);
    error PoolNotExist(string contractTAG, bytes32 symbol);
    error PriceNotValid(string contractTAG, bytes32 symbol);
    error ArrayLengthMismatched(string contractTAG);
    error SequencerDown(string contractTAG);
    error GracePeriodNotOver(string contractTAG);
    
    /**
     * @dev Modifier that checks if caller has a specific role.
     **/
    modifier onlyRole(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initilize the contract.
     * @param roleManagerAddress - Address of the roleManager contract.
     **/
    function initialize(address roleManagerAddress) public initializer {
        roleManager = roleManagerAddress;
    }

    /**
     * @notice Configures role manager address
     * This function can only be accessed by the account with role DEFAULT_ADMIN_ROLE.
     * @param roleManagerAddress - address of the roleManager contract.
     **/
    function setRoleManager(
        address roleManagerAddress
    ) external onlyRole(IRoleManager(roleManager).DEFAULT_ADMIN_ROLE()) {
        roleManager = roleManagerAddress;
    }

    /**
     * @notice Configures aggregator address for a asset `_id` managed by Chainlink
     * This function can only be accessed by the account with role SET_ORACLE_METHOD.
     * @param _id - pool id of the asset
     * @param _aggregator - address of the aggregator
     **/
    function setAggregator(
        bytes32 _id,
        address _aggregator
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        aggregator[_id] = _aggregator;
    }

    /**
     * @notice Configures price feed contract
     * This function can only be accessed by the account with role SET_ORACLE_METHOD.
     * @param _priceFeed - address of the price feed
     **/
    function setPriceFeed(
        address _priceFeed
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        priceFeed = _priceFeed;
    }

    /**
     * @notice Configures assets which value is to be fetched from priceFeed
     * This function can only be accessed by the account with role SET_ORACLE_METHOD.
     * @param _ids - list of assets
     * @param _status - on and off flag for extracting price from priceFeed
     **/
    function setAssetForPriceFeed(
        bytes32[] memory _ids,
        bool[] memory _status
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        for (uint256 i; i < _ids.length; i++) {
            fetchFromPriceFeed[_ids[i]] = _status[i];
        }
    }

    /**
     * @notice Configures min max value to check against the oracle price
     * @param _id - pool id of the asset
     * @param _maxValue - accepted max value of asset
     * @param _minValue - accepted min value of asset
     **/
    function setMinMax(
        bytes32[] memory _id,
        uint256[] memory _maxValue,
        uint256[] memory _minValue
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        if(_id.length != _maxValue.length || _id.length != _minValue.length )
            revert ArrayLengthMismatched(TAG);
        for (uint256 i; i < _id.length; i++) {
            maxValue[_id[i]] = _maxValue[i];
            minValue[_id[i]] = _minValue[i];
        }
    }

    /**
     * @notice Configures heart beat value to check against the oracle price
     * @param _id - pool id of the asset
     * @param _heartBeatValue - accepted max delay time of asset
     **/
    function setHeartBeat(
        bytes32[] memory _id,
        uint256[] memory _heartBeatValue
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        if(_id.length != _heartBeatValue.length)
            revert ArrayLengthMismatched(TAG);
        for (uint256 i; i < _id.length; i++) {
            heartBeatValue[_id[i]] = _heartBeatValue[i];
        }
    }

    /**
    * @notice Configures the grace period
    * This function can only be accessed by the account with role SET_ORACLE_METHOD.
    * @param  _gracePeriodTime - grace period
    **/
    function setGracePeriodTime(
        uint256 _gracePeriodTime
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        GRACE_PERIOD_TIME =  _gracePeriodTime;
    }

    /**
    * @notice Configures the sequencer uptime feed proxy address of L2 network
    * This function can only be accessed by the account with role SET_ORACLE_METHOD.
    * @param _upTimeFeed - address of the uptimeFeed
    **/
    function setSequencerUptimeFeed(
        address _upTimeFeed
    ) external onlyRole(IRoleManager(roleManager).SET_ORACLE_METHOD()) {
        sequencerUptimeFeed = _upTimeFeed;
    }

    /**
    * @notice Returns price of assets
    * @param _symbols - list of the asset's pool id
    **/
     function getPrices(
        bytes32[] memory _symbols
    ) external view returns (uint256[] memory results) {
        results = new uint256[](_symbols.length);
        uint256 price;
        for (uint256 i; i < _symbols.length; i++) {
            if (fetchFromPriceFeed[_symbols[i]]) {
                price = getPriceFromPriceFeed(_symbols[i]);
            } else {
                price = getPriceFromChainlink(_symbols[i]);
            }
           
           if(priceCheck(_symbols[i],price))
                revert PriceNotValid(TAG, _symbols[i]); 
            results[i] = price;
        }
    }

    /**
    * @notice Returns price of an asset
    * @param _symbol - pool id of the asset
    **/
    function getSinglePrice(
        bytes32 _symbol
    ) external view returns (uint256 result) {
        if (fetchFromPriceFeed[_symbol]) {
                result = getPriceFromPriceFeed(_symbol);
            } else {
                result = getPriceFromChainlink(_symbol);
            }
        if(priceCheck(_symbol,result))
            revert PriceNotValid(TAG, _symbol);  
    }
    
    
     /**
    * @notice Returns bool after checking the min max and zero condition
    * @param _symbol - pool id of the asset
    * @param _price - price return by the chainlink
    **/
    function priceCheck(
        bytes32 _symbol,
        uint256 _price
    ) public view returns (bool status) {
        
        if(_price == 0 || _price <= minValue[_symbol] || _price >= maxValue[_symbol] ) {
            return true;
        }
    }

    /**
    * @notice Returns price of the asset fetched from chainlink aggregator
    * @param _symbol - pool id of the asset
    **/
    function getPriceFromChainlink(
        bytes32 _symbol
    ) public view returns (uint256) {
        // prettier-ignore
         (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = 
        AggregatorV3Interface(
            sequencerUptimeFeed
        ).latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown(TAG);
        }

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver(TAG);
        }

        (
            uint80 roundID,
            int256 basePrice,
            /*uint256 startedAt*/,
            uint256 timeStamp,
            uint80 answeredInRound
        ) =
         AggregatorV3Interface(
            aggregator[_symbol]
        ).latestRoundData();

        if(basePrice <= 0)
            revert ChainlinkMalfunction(TAG, _symbol);

        if(timeStamp == 0)
            revert RoundNotComplete(TAG, _symbol);
        
        if (timeStamp < block.timestamp - heartBeatValue[_symbol])
            revert PriceOutDated(TAG, _symbol);

        if(answeredInRound < roundID)
            revert StaleData(TAG, _symbol);

        uint8 quoteDecimals = AggregatorV3Interface(aggregator[_symbol])
            .decimals();
        uint256 quotePrice = _scalePrice(
            uint256(basePrice),
            quoteDecimals,
            ROOT_DECIMALS
        );

        return quotePrice;
    }

     /**
    * @notice Returns price of the asset fetched from price feed maintained
    * @param _symbol - pool id of the asset
    **/
    function getPriceFromPriceFeed(
        bytes32 _symbol
    ) public view returns (uint256 price) {
        price = IPriceFeed(priceFeed).getPrice(_symbol);

    }

    function _scalePrice(
        uint256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (uint256) {
        if (_priceDecimals < _decimals) {
            return _price * uint256(10 ** (_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / uint256(10 ** (_priceDecimals - _decimals));
        }
        return _price;
    }
}