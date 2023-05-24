/**
 *Submitted for verification at Arbiscan on 2023-05-24
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
 * @title Represents an ERC-20
 */
 abstract contract ERC20 is Initializable, IERC20 {
    // Basic ERC-20 data
    uint256 internal _totalSupply;

    // The balance of each owner
    mapping(address => uint256) internal _balances;

    // The allowance set by each owner
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyIfInitialized {
        require(_getInitializedVersion() != type(uint8).max, "Contract was not initialized yet");
        _;
    }

    /**
    * @notice Transfers a given amount tokens to the address specified.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return Returns true in case of success.
    */
    function transfer(address to, uint256 value) external override onlyIfInitialized returns (bool) {
        require (_executeErc20Transfer(msg.sender, to, value), "Failed to execute ERC20 transfer");
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @dev Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return Returns true in case of success.
     */
    function transferFrom(address from, address to, uint256 value) external override onlyIfInitialized returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Amount exceeds allowance");

        require (_executeErc20Transfer(from, to, value), "Failed to execute transferFrom");

        require(_approveSpender(from, msg.sender, currentAllowance - value), "ERC20: Approval failed");

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return Returns true in case of success.
     */
    function approve(address spender, uint256 value) external override onlyIfInitialized returns (bool) {
        require(_approveSpender(msg.sender, spender, value), "ERC20: Approval failed");
        return true;
    }

    /**
     * Gets the total supply of tokens
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) external view override returns (uint256) {
        return _balances[addr];
    }

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _initErc20 (uint256 initialTotalSupply) internal onlyInitializing {
        _totalSupply = initialTotalSupply;
    }

    /**
    * @notice Transfers a given amount tokens to the address specified.
    * @param from The address of the sender.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return Returns true in case of success.
    */
    function _executeErc20Transfer (address from, address to, uint256 value) private returns (bool) {
        // Checks
        require(to != address(0), "non-zero address required");
        require(from != address(0), "non-zero sender required");
        require(value > 0, "Amount cannot be zero");
        require(_balances[from] >= value, "Amount exceeds sender balance");

        // State changes
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;

        // Emit the event per ERC-20
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param ownerAddr The address of the owner.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return Returns true in case of success.
     */
    function _approveSpender(address ownerAddr, address spender, uint256 value) private returns (bool) {
        require(spender != address(0), "non-zero spender required");
        require(ownerAddr != address(0), "non-zero owner required");

        // State changes
        _allowances[ownerAddr][spender] = value;

        // Emit the event
        emit Approval(ownerAddr, spender, value);

        return true;
    }
}

interface IMintable {
    function mint (address addr, uint256 amount) external;
    function burn (address addr, uint256 amount) external;
    function canMint (uint256 amount) external view returns (bool);
}

/**
 * @notice Represents an ERC20 that can be minted and/or burnt by multiple parties.
 */
abstract contract Mintable is ERC20, CustomOwnable, IMintable {
    /**
     * @notice The maximum circulating supply of tokens
     */
    uint256 public maxSupply;

    // Keeps track of the authorized minters
    mapping (address => bool) internal _authorizedMinters;

    // Keeps track of the authorized burners
    mapping (address => bool) internal _authorizedBurners;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * This event is triggered whenever an address is added as a valid minter.
     * @param addr The address that became a valid minter
     */
    event OnMinterGranted(address addr);

    /**
     * This event is triggered when a minter is revoked.
     * @param addr The address that was revoked
     */
    event OnMinterRevoked(address addr);

    /**
     * This event is triggered whenever an address is added as a valid burner.
     * @param addr The address that became a valid burner
     */
    event OnBurnerGranted(address addr);

    /**
     * This event is triggered when a burner is revoked.
     * @param addr The address that was revoked
     */
    event OnBurnerRevoked(address addr);

    /**
     * This event is triggered when the maximum limit for minting tokens is updated.
     * @param prevValue The previous limit
     * @param newValue The new limit
     */
    event OnMaxSupplyChanged(uint256 prevValue, uint256 newValue);

    /**
     * @notice Throws if the sender is not a valid minter
     */
    modifier onlyMinter() {
        require(_authorizedMinters[msg.sender], "Unauthorized minter");
        _;
    }

    /**
     * @notice Throws if the sender is not a valid burner
     */
    modifier onlyBurner() {
        require(_authorizedBurners[msg.sender], "Unauthorized burner");
        _;
    }

    /**
     * @notice Grants the right to issue new tokens to the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function grantMinter (address addr) external onlyIfInitialized onlyOwner {
        require(!_authorizedMinters[addr], "Address authorized already");
        _authorizedMinters[addr] = true;
        emit OnMinterGranted(addr);
    }

    /**
     * @notice Revokes the right to issue new tokens from the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function revokeMinter (address addr) external onlyIfInitialized onlyOwner {
        require(_authorizedMinters[addr], "Address was never authorized");
        _authorizedMinters[addr] = false;
        emit OnMinterRevoked(addr);
    }

    /**
     * @notice Grants the right to burn tokens to the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function grantBurner (address addr) external onlyIfInitialized onlyOwner {
        require(!_authorizedBurners[addr], "Address authorized already");
        _authorizedBurners[addr] = true;
        emit OnBurnerGranted(addr);
    }

    /**
     * @notice Revokes the right to burn tokens from the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function revokeBurner (address addr) external onlyIfInitialized onlyOwner {
        require(_authorizedBurners[addr], "Address was never authorized");
        _authorizedBurners[addr] = false;
        emit OnBurnerRevoked(addr);
    }

    /**
     * @notice Issues a given number of tokens to the address specified.
     * @dev This function throws if the sender is not a whitelisted minter.
     * @param addr The destination address
     * @param amount The number of tokens
     */
    function mint (address addr, uint256 amount) external override onlyIfInitialized onlyMinter {
        require(addr != address(0) && addr != address(this), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(canMint(amount), "Max token supply exceeded");

        _totalSupply += amount;
        _balances[addr] += amount;
        emit Transfer(address(0), addr, amount);
    }

    /**
     * @notice Burns a given number of tokens from the address specified.
     * @dev This function throws if the sender is not a whitelisted minter. In this context, minters and burners have the same privileges.
     * @param addr The destination address
     * @param amount The number of tokens
     */
    function burn (address addr, uint256 amount) external override onlyIfInitialized onlyBurner {
        require(addr != address(0) && addr != address(this), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(_totalSupply > 0, "No token supply");

        uint256 accountBalance = _balances[addr];
        require(accountBalance >= amount, "Burn amount exceeds balance");

        _balances[addr] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(addr, address(0), amount);
    }

    /**
     * @notice Indicates if we can issue/mint the number of tokens specified.
     * @param amount The number of tokens to issue/mint
     */
    function canMint (uint256 amount) public view override returns (bool) {
        return (maxSupply == 0) || (_totalSupply + amount <= maxSupply);
    }

    function _initMintable (address newOwner, uint256 initialTotalSupply) internal onlyInitializing {
        _initErc20(initialTotalSupply);
        _transferOwnership(newOwner);
    }
}

interface IReceiptToken is IERC20, IMintable {
    function changeMaxSupply (uint256 newValue) external;
}

/**
 * @title Represents a receipt token. The token is fully compliant with the ERC20 interface.
 * @dev The token can be minted or burnt by whitelisted addresses only. Only the owner is allowed to enable/disable addresses.
 */
contract ReceiptToken is Mintable, IReceiptToken {
    uint8 private constant TOKEN_DECIMALS = 6;
    string private constant TOKEN_SYMBOL = "USDF";
    string private constant TOKEN_NAME = "Fractal Protocol Vault Token";

    // Slots consumed: 8
    uint256[50 - 8] private __gap;

    constructor () {
        _disableInitializers();
    }

    function initialize (address newOwner, uint256 initialMaxSupply) external initializer {
        _initReceiptToken(newOwner, initialMaxSupply);
    }

    /**
     * @notice Updates the maximum limit for minting tokens.
     * @param newValue The new limit
     */
    function changeMaxSupply (uint256 newValue) external override onlyIfInitialized onlyOwner {
        require(newValue == 0 || newValue > _totalSupply, "Invalid max supply");
        emit OnMaxSupplyChanged(maxSupply, newValue);
        maxSupply = newValue;
    }

    /**
     * @notice Gets the decimals of the token.
     * @return Returns the decimals precision of the token.
     */
    function decimals() external override pure returns (uint8) {
        return TOKEN_DECIMALS;
    }

    /**
     * @notice Gets the symbol of the token.
     * @return Returns a string containing the token symbol.
     */
    function symbol () external override pure returns (string memory) {
        return TOKEN_SYMBOL;
    }

    /**
     * @notice Gets the descriptive name of the token.
     * @return Returns the name of the token.
     */
    function name () external override pure returns (string memory) {
        return TOKEN_NAME;
    }

    function _initReceiptToken (address newOwner, uint256 initialMaxSupply) internal onlyInitializing {
        maxSupply = initialMaxSupply;
        _initMintable(newOwner, 0);
    }
}