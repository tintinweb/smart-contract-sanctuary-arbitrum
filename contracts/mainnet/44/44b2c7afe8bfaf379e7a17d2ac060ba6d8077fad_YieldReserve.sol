/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.3;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        _transferOwnership(addr);
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }

    function _transferOwnership (address addr) internal virtual {
        address oldValue = _owner;
        _owner = addr;
        emit OnOwnershipTransferred(oldValue, _owner);
    }
}

/**
 * @title Represents a controllable resource.
 */
contract CustomControllable is CustomOwnable {
    address public controllerAddress;

    event OnControllerChanged (address prevAddress, address newAddress);

    /**
     * @notice Throws if the sender is not the controller
     */
    modifier onlyController() {
        require(msg.sender == controllerAddress, "Unauthorized controller");
        _;
    }

    /**
     * @notice Makes sure the sender is either the owner of the contract or the controller
     */
    modifier onlyOwnerOrController() {
        require(msg.sender == controllerAddress || msg.sender == _owner, "Only owner or controller");
        _;
    }

    /**
     * @notice Sets the controller
     * @dev This function can be called by the owner only
     * @param controllerAddr The address of the controller
     */
    function setController (address controllerAddr) public onlyOwner {
        // Checks
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != _owner, "Owner cannot be the Controller");
        require(controllerAddr != controllerAddress, "Controller already set");

        emit OnControllerChanged(controllerAddress, controllerAddr);

        // State changes
        controllerAddress = controllerAddr;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public override onlyOwner {
        require(addr != controllerAddress, "Cannot transfer to controller");
        _transferOwnership(addr);
    }

    function _initController (address ownerAddr, address controllerAddr) internal {
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != ownerAddr, "Owner cannot be the Controller");
        controllerAddress = controllerAddr;
        _transferOwnership(ownerAddr);
    }
}

/**
 * @notice Defines the interface for whitelisting addresses.
 */
interface IAddressWhitelist {
    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external;

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external;

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns 1 if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view returns (bool);

    /**
     * This event is triggered when a new address is whitelisted.
     * @param addr The address that was whitelisted
     */
    event OnAddressEnabled(address addr);

    /**
     * This event is triggered when an address is disabled.
     * @param addr The address that was disabled
     */
    event OnAddressDisabled(address addr);
}

/**
 * @title This contract allows you to manage configuration settings of all crosschain providers supported by the platform.
 */
contract CrosschainProviderConfigManager is CustomControllable {
    // Defines the settings of each route
    struct ConfigSetting {
        address routerAddress;
        bytes routingInfo;
    }

    // The settings of each crosschain, cross-provider route
    mapping (bytes32 => ConfigSetting) private _routingData;

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the vault
     * @param controllerAddr The controller of the vault
     */
    constructor (address ownerAddr, address controllerAddr) {
        _initController(ownerAddr, controllerAddr);
    }

    /**
     * @notice Sets the configuration of the provider specified.
     * @dev This function can be called by the contract owner only.
     * @param key The routing key
     * @param routerAddress The router address for the source token specified.
     * @param routingInfo The provider configuration
     */
    function setRoute (bytes32 key, address routerAddress, bytes memory routingInfo) public onlyOwnerOrController {
        require(key != bytes32(0), "Key required");
        require(routerAddress != address(0), "Router address required");
        require(routingInfo.length > 0, "Routing info required");

        _routingData[key] = ConfigSetting(routerAddress, routingInfo);
    }

    /**
     * @notice Builds the routing key based on the parameters specified.
     * @param tokenAddr The hash of the token address
     * @param provider The hash of the crosschain provider. It could be Anyswap, LayerZero, etc.
     * @param foreignNetwork The hash of the foreign network or chain. It could be Avalanche, Fantom, etc.
     * @return Returns a key
     */
    function buildKey (address tokenAddr, bytes32 provider, bytes32 foreignNetwork) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(provider, foreignNetwork, tokenAddr));
    }

    /**
     * @notice Gets the routing configuration of the provider specified.
     * @param key The routing key of the provider
     * @return routerAddress The router address for the key specified
     * @return routingInfo The routing settings for the key specified
     */
    function getRoute (bytes32 key) public view returns (address routerAddress, bytes memory routingInfo) {
        routerAddress = _routingData[key].routerAddress;
        routingInfo = _routingData[key].routingInfo;
    }
}

/**
 * @title Contract for whitelisting addresses
 */
contract AddressWhitelist is IAddressWhitelist, CustomOwnable {
    mapping (address => bool) internal whitelistedAddresses;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) {
        _transferOwnership(ownerAddr);
    }

    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external override onlyOwner {
        require(!whitelistedAddresses[addr], "Already enabled");
        whitelistedAddresses[addr] = true;
        emit OnAddressEnabled(addr);
    }

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external override onlyOwner {
        require(whitelistedAddresses[addr], "Already disabled");
        whitelistedAddresses[addr] = false;
        emit OnAddressDisabled(addr);
    }

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns true if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view override returns (bool) {
        return whitelistedAddresses[addr];
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    /**
    * Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * This event is triggered when a given amount of tokens is sent to an address.
     * @param from The address of the sender
     * @param to The address of the receiver
     * @param value The amount transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * This event is triggered when a given address is approved to spend a specific amount of tokens
     * on behalf of the sender.
     * @param owner The owner of the token
     * @param spender The spender
     * @param value The amount to transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

/**
 * @title Represents a crosschain provider.
 */
abstract contract BaseProvider is CustomControllable {
    CrosschainProviderConfigManager public configManager;
    AddressWhitelist internal _whitelist;
    
    event OnCrosschainTransfer (address routerAddress, uint256 destinationChainId, address fromAddress, address toAddress, uint256 amount);

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the vault
     * @param controllerAddr The controller of the vault
     * @param newConfigManager The config manager
     * @param newWhitelist The whitelist
     */
    constructor (address ownerAddr, address controllerAddr, CrosschainProviderConfigManager newConfigManager, AddressWhitelist newWhitelist) {
        configManager = newConfigManager;
        _whitelist = newWhitelist;
        _initController(ownerAddr, controllerAddr);
    }

    /**
     * @notice This modifier throws if the sender is not whitelisted, or if the whitelist is not set.
     */
    modifier onlyIfWhitelistedSender () {
        require(address(_whitelist) != address(0), "Whitelist not set");
        require(_whitelist.isWhitelistedAddress(msg.sender), "Sender not whitelisted");
        _;
    }

    /**
     * @notice Approves the router to spend the amount of tokens specified
     * @param tokenInterface The interface of the ERC20
     * @param routerAddr The address of the router
     * @param spenderAmount The spender amount granted to the router
     */
    function approveRouter (IERC20 tokenInterface, address routerAddr, uint256 spenderAmount) public onlyController {
        require(tokenInterface.approve(routerAddr, spenderAmount), "Approval failed");
    }

    /**
     * @notice Revokes allowance on the router address specified specified
     * @param tokenInterface The interface of the ERC20
     * @param routerAddr The address of the router
     */
    function revokeRouter (IERC20 tokenInterface, address routerAddr) public onlyController {
        require(tokenInterface.approve(routerAddr, 0), "Revoke failed");
    }

    /**
     * @notice Executes a crosschain transfer.
     * @param underlyingTokenInterface The interface of the ERC20
     * @param destinationAddr The destination address
     * @param transferAmount The transfer amount
     * @param foreignNetwork The hash of the remote network/chain
     */
    function executeTransfer (IERC20 underlyingTokenInterface, address destinationAddr, uint256 transferAmount, bytes32 foreignNetwork) public virtual;

    /**
     * @notice Gets the hash of the provider
     * @return The hash of the provider
     */
    function getProviderHash() public pure virtual returns (bytes32);
}

/**
 * @notice This library provides stateless, general purpose functions.
 */
library Utils {
    // The code hash of any EOA
    bytes32 constant internal EOA_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = EOA_HASH;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
    }

    /**
     * @notice Gets the code hash of the address specified
     * @param addr The address to evaluate
     * @return Returns a hash
     */
    function getCodeHash (address addr) internal view returns (bytes32) {
        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return codeHash;
    }
}

interface IDeployable {
    function deployCapital (uint256 deploymentAmount, bytes32 foreignNetwork) external;
    function claim (uint256 dailyInterestAmount) external;
}

/**
 * @title Represents a yield reserve.
 */
contract YieldReserve is Initializable, CustomControllable, IDeployable {
    struct ProviderData {
        BaseProvider providerContractInterface;
        address recipientAddress;
    }

    mapping (bytes32 => uint256) internal _deployedCapital;

    // The list of crosschain providers supported by the yield reserve
    mapping (bytes32 => ProviderData) private _providers;

    /**
     * @notice The address of the Vault
     */
    address public vaultAddress;

    /**
     * @notice The interface of the underlying token
     */
    IERC20 public tokenInterface;

    // The whitelisted addresses that can withdraw funds from the yield reserve
    IAddressWhitelist private _whitelistInterface;

    // The reentrancy guard for capital locks
    uint8 private _reentrancyMutexForCapital;

    // The reentrancy guard for transfers
    uint8 private _reentrancyMutexForTransfers;

    // Slots consumed: 7
    uint256[50 - 7] private __gap;

    /**
     * @notice This event is fired when a deployment of capital takes place.
     * @param toAddress Specifies the address of the remote contract (foreign vault)
     * @param throughAddress Specifies the address of the bridge
     * @param amount Specifies the amount that was deployed
     * @param targetNetwork Specifies the target network
     */
    event OnCapitalDeployed (address toAddress, address throughAddress, uint256 amount, bytes32 targetNetwork);
    event OnVaultAddressChanged (address prevAddress, address newAddress);
    event OnVaultTransfer (uint256 amount);
    event OnTransferToMultipleAddresses ();

    constructor () {
        _disableInitializers();
    }

    /**
     * @notice Throws if the sender is not the vault
     */
    modifier vaultOnly() {
        require(vaultAddress != address(0) && msg.sender == vaultAddress, "Unauthorized caller");
        _;
    }

    /**
     * @notice Throws if there is a capital lock in progress
     */
    modifier ifNotReentrantCapitalLock() {
        require(_reentrancyMutexForCapital == 0, "Reentrant capital lock rejected");
        _;
    }

    /**
     * @notice Throws if there is a token transfer in progress
     */
    modifier ifNotTransferringFunds() {
        require(_reentrancyMutexForTransfers == 0, "Transfer in progress");
        _;
    }

    modifier onlyIfInitialized {
        require(_getInitializedVersion() != type(uint8).max, "Contract was not initialized yet");
        _;
    }

    function initialize (address ownerAddr, address controllerAddr, address eip20Interface, address whitelistInterface) external initializer {
        _initYieldReserve(ownerAddr, controllerAddr, IERC20(eip20Interface), IAddressWhitelist(whitelistInterface));
    }

    /**
     * @notice Sets the address of the vault
     * @dev This function can be called by the owner or the controller.
     * @param addr The address of the vault
     */
    function setVaultAddress (address addr) external onlyIfInitialized onlyOwnerOrController {
        require(addr != address(0) && addr != address(this), "Invalid vault address");
        require(Utils.isContract(addr), "The address must be a contract");

        emit OnVaultAddressChanged(vaultAddress, addr);
        vaultAddress = addr;
    }

    function setProvider (bytes32 foreignNetwork, BaseProvider xChainProvider, address recipientAddress) external onlyIfInitialized onlyOwnerOrController {
        _providers[foreignNetwork] = ProviderData(xChainProvider, recipientAddress);
    }

    /**
     * @notice Transfers an arbitrary amount of funds to the vault.
     * @param amount The transfer amount
     */
    function transferToVault (uint256 amount) external onlyIfInitialized onlyOwnerOrController ifNotReentrantCapitalLock ifNotTransferringFunds {
        require(amount > 0, "Amount required");
        require(vaultAddress != address(0), "Invalid vault address");
        require(tokenInterface.transfer(vaultAddress, amount), "Transfer to vault failed");
        emit OnVaultTransfer(amount);
    }

    /**
     * @notice Transfers funds to the list of addresses specified.
     * @dev Throws if the destination address is not whitelisted. This function can be called by the owner or controller only.
     * @param addresses The list of addresses
     * @param amounts The corresponding amount of each address
     */
    function transferToMultipleAddresses (address[] memory addresses, uint256[] memory amounts) external onlyIfInitialized onlyOwnerOrController ifNotTransferringFunds {
        // Checks
        require(addresses.length > 0, "Addresses list required");
        require(amounts.length > 0, "Amounts required");
        require(addresses.length == amounts.length, "Invalid length for pairs");
        require(addresses.length < 11, "Max addresses limit reached");

        // Wake up the reentrancy guard
        _reentrancyMutexForTransfers = 1;

        uint256 maxTransferAmount = tokenInterface.balanceOf(address(this));
        require(maxTransferAmount > 0, "Insufficient balance");

        uint256 total = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && addresses[i] != address(this), "Invalid address for transfer");
            require(_whitelistInterface.isWhitelistedAddress(addresses[i]), "Address not whitelisted");
            total += amounts[i];
        }

        require(total <= maxTransferAmount, "Maximum transfer amount exceeded");

        // State changes
        for (uint256 i = 0; i < addresses.length; i++) {
            require(tokenInterface.transfer(addresses[i], amounts[i]), "Transfer failed");
        }

        emit OnTransferToMultipleAddresses();

        // Reset the reentrancy guard
        _reentrancyMutexForTransfers = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Deploys capital to an EOA
     * @param targetAddr The destination address
     * @param deploymentAmount The amount of capital to deploy
     */
    function deployCapitalToEoa (address targetAddr, uint256 deploymentAmount) external onlyIfInitialized onlyOwnerOrController ifNotReentrantCapitalLock {
        require(deploymentAmount > 0, "Deployment amount required");
        require(targetAddr != address(0), "Target address required");

        // Wake up the reentrancy guard
        _reentrancyMutexForCapital = 1;

        // The amount of capital deployed to a given hash. In this case, the hash is an EOA
        bytes32 targetHash = keccak256(abi.encodePacked(targetAddr));
        _deployedCapital[targetHash] += deploymentAmount;

        // Make sure the address is whitelisted
        require(_whitelistInterface.isWhitelistedAddress(targetAddr), "Address not whitelisted");

        // Transfer funds to the EOA specified
        require(tokenInterface.transfer(targetAddr, deploymentAmount), "Xchain EOA transfer failed");

        emit OnCapitalDeployed(targetAddr, address(0), deploymentAmount, bytes32(0));

        // Reset the reentrancy guard
        _reentrancyMutexForCapital = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Deploys capital to another smart contract through a cross-chain bridge
     * @param deploymentAmount The amount of capital to deploy
     * @param foreignNetwork The target network
     */
    function deployCapital (uint256 deploymentAmount, bytes32 foreignNetwork) external override onlyIfInitialized onlyOwnerOrController ifNotReentrantCapitalLock {
        require(deploymentAmount > 0, "Deployment amount required");

        // Wake up the reentrancy guard
        _reentrancyMutexForCapital = 1;

        // The amount of capital deployed to a given hash. In this case, the hash is a network
        _deployedCapital[foreignNetwork] += deploymentAmount;

        address recipientAddress = _providers[foreignNetwork].recipientAddress;
        address providerAddress = address(_providers[foreignNetwork].providerContractInterface);
        
        require(tokenInterface.transfer(providerAddress, deploymentAmount), "Provider transfer failed");

        // Run the crosschain transfer through the provider specified
        _providers[foreignNetwork].providerContractInterface.executeTransfer(tokenInterface, recipientAddress, deploymentAmount, foreignNetwork);

        emit OnCapitalDeployed(recipientAddress, providerAddress, deploymentAmount, foreignNetwork);

        // Reset the reentrancy guard
        _reentrancyMutexForCapital = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Adjusts the amount of capital harvested in a foreign network or by a foreign hash.
     * @param foreignHash The hash of the foreign party
     * @param amountHarvested The amount of capital harvested in the foreign network
     * @param isNegative Indicates if the amount is positive or negative
     */
    function adjustDeployedCapital (bytes32 foreignHash, uint256 amountHarvested, bool isNegative) external onlyIfInitialized onlyOwnerOrController ifNotReentrantCapitalLock {
        if (isNegative) {
            require(amountHarvested <= _deployedCapital[foreignHash], "Harvest amount out of bounds");
            _deployedCapital[foreignHash] -= amountHarvested;
        }
        else {
            _deployedCapital[foreignHash] += amountHarvested;
        }
    }

    /**
     * @notice Claims a specific amount from the yield reserve and sends the funds back to the Vault.
     * @param dailyInterestAmount The amount to claim
     */
    function claim (uint256 dailyInterestAmount) external override onlyIfInitialized vaultOnly {
        require(dailyInterestAmount > 0, "Amount required");

        uint256 currentBalance = tokenInterface.balanceOf(address(this));
        require(currentBalance >= dailyInterestAmount, "Insufficient funds");

        require(tokenInterface.transfer(msg.sender, dailyInterestAmount), "Token transfer failed");
    }

    /**
     * @notice Gets the amount of capital deployed to a given network or EOA.
     * @param foreignHash The hash of the foreign party
     * @return Returns the amount of capital
     */
    function deployedCapital (bytes32 foreignHash) external view returns (uint256) {
        return _deployedCapital[foreignHash];
    }

    function _initYieldReserve (address ownerAddr, address controllerAddr, IERC20 eip20Interface, IAddressWhitelist whitelistInterface) internal onlyInitializing {
        tokenInterface = eip20Interface;
        _whitelistInterface = whitelistInterface;
        _initController(ownerAddr, controllerAddr);
    }
}