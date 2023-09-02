/**
 *Submitted for verification at Arbiscan.io on 2023-09-02
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
abstract contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred(address previousOwner, address newOwner);

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
    function transferOwnership(address addr) external virtual onlyOwner {
        _transferOwnership(addr);
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner() external virtual view returns (address) {
        return _owner;
    }

    function _transferOwnership(address addr) internal virtual {
        require(addr != address(0) && addr != _owner, "Invalid owner address");

        address oldValue = _owner;
        _owner = addr;
        emit OnOwnershipTransferred(oldValue, _owner);
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

interface IDeployable {
    function deployCapital (uint256 deploymentAmount, bytes32 foreignNetwork) external;
    function claim (uint256 dailyInterestAmount) external;
}

interface IProgressiveLiability is IERC20 {
    function mint(address addr, uint256 amount) external;
    function burn(address addr, uint256 amount) external;
    function changeMaxSupply(uint256 newValue) external;

    /**
     * @notice This event is triggered when the maximum limit for minting tokens is updated.
     * @param prevValue The previous limit
     * @param newValue The new limit
     */
    event OnMaxSupplyChanged(uint256 prevValue, uint256 newValue);
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

library DateUtils {
    // The number of seconds per day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    // The number of seconds per hour
    uint256 internal constant SECONDS_PER_HOUR = 60 * 60;

    // The number of seconds per minute
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    // The offset from 01/01/1970
    int256 internal constant OFFSET19700101 = 2440588;

    /**
     * @notice Gets the year of the timestamp specified.
     * @param timestamp The timestamp
     * @return year The year
     */
    function getYear (uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    /**
     * @notice Gets the timestamp of the date specified.
     * @param year The year
     * @param month The month
     * @param day The day
     * @param hour The hour
     * @param minute The minute
     * @param second The seconds
     * @return timestamp The timestamp
     */
    function timestampFromDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }

    /**
     * @notice Gets the number of days elapsed between the two timestamps specified.
     * @param fromTimestamp The source date
     * @param toTimestamp The target date
     * @return Returns the difference, in days
     */
    function diffDays (uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256) {
        require(fromTimestamp <= toTimestamp, "Invalid order for timestamps");
        return (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    /**
     * @notice Calculate year/month/day from the number of days since 1970/01/01 using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and adding the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param _days The year
     * @return year The year
     * @return month The month
     * @return day The day
     */
    function _daysToDate (uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);

        int256 x = __days + 68569 + OFFSET19700101;
        int256 n = 4 * x / 146097;
        x = x - (146097 * n + 3) / 4;
        int256 _year = 4000 * (x + 1) / 1461001;
        x = x - 1461 * _year / 4 + 31;
        int256 _month = 80 * x / 2447;
        int256 _day = x - 2447 * _month / 80;
        x = _month / 11;
        _month = _month + 2 - 12 * x;
        _year = 100 * (n - 49) + _year + x;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /**
     * @notice Calculates the number of days from 1970/01/01 to year/month/day using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and subtracting the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param year The year
     * @param month The month
     * @param day The day
     * @return _days Returns the number of days
     */
    function _daysFromDate (uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970, "Error");
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint256(__days);
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }    

    function _isLeapYear (uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
}

/**
 * @title Represents a vault.
 */
contract Vault is Initializable, CustomControllable, ReentrancyGuard {
    // The decimals multiplier of the receipt token
    uint256 private constant USDF_DECIMAL_MULTIPLIER = uint256(10) ** uint256(6);

    // The maximum fluctuation of the token price is 1%
    uint256 private constant MAX_PRICE_FLUCTUATION = uint256(1);

    // Represents a record (snapshot) at a given point in time.
    struct Record {
        uint256 apr;
        uint256 tokenPrice;
        uint256 totalDeposited;
        uint256 dailyInterest;
    }

    // The timestamp that defines the start of the current year, per contract deployment. This is the unix epoch of January 1st since the contract deployment.
    uint256 internal _startOfYearTimestamp;

    /**
     * @notice The current period. It is the zero-based day of the year, ranging from [0..364]
     * @dev Day zero represents January 1st (first day of the year) whereas day 364 represents December 31st (last day of the day)
     */
    uint256 public currentPeriod;

    /**
     * @notice The minimum amount you can deposit in the vault.
     */
    uint256 public minDepositAmount;

    /**
     * @notice The flat fee to apply to vault withdrawals.
     */
    uint256 public flatFeePercent;

    // The decimals multiplier of the underlying ERC20
    uint256 private _decimalsMultiplier;

    /**
     * @notice The percentage of capital that needs to be invested. It ranges from [1..99]
     * @dev The investment percent is set to 90% by default
     */
    uint8 public investmentPercent;

    /**
     * @notice The address of the yield reserve
     */
    address public yieldReserveAddress;

    /**
     * @notice The address that collects the applicable fees
     */
    address public feesAddress;

    /**
     * @notice The interface of the underlying token
     */
    IERC20 public underlyingTokenInterface;

    // The receipt token.
    IProgressiveLiability private _receiptToken;

    // The snapshots history
    mapping (uint256 => Record) private _records;

    /// @notice The timestamp of the last token price update.
    uint256 public priceChangedOn;

    // |--------------------------------------------------------------------------------|
    // | Tightly-packed storage layout for future upgrades                              |
    // |--------------------------------------------------------------------------------|
    // | Slot | Variable name            | Bytes | Data type | File                     |
    // |------|--------------------------|-------|-----------|--------------------------|
    // |   #0 | _initialized             |     1 | uint8     | Initializable.sol        |
    // |   #0 | _initializing            |     1 | bool      | Initializable.sol        |
    // |   #0 | _owner                   |    20 | address   | CustomOwnable.sol        |
    // |   #1 | controllerAddress        |    20 | address   | CustomOwnable.sol        |
    // |   #2 | _status                  |    32 | uint256   | ReentrancyGuard.sol      |
    // |   #3 | _startOfYearTimestamp    |    32 | uint256   | Vault.sol                |
    // |   #4 | currentPeriod            |    32 | uint256   | Vault.sol                |
    // |   #5 | minDepositAmount         |    32 | uint256   | Vault.sol                |
    // |   #6 | flatFeePercent           |    32 | uint256   | Vault.sol                |
    // |   #7 | _decimalsMultiplier      |    32 | uint256   | Vault.sol                |
    // |   #8 | investmentPercent        |     1 | uint8     | Vault.sol                |
    // |   #8 | yieldReserveAddress      |    20 | address   | Vault.sol                |
    // |   #9 | feesAddress              |    20 | address   | Vault.sol                |
    // |  #10 | underlyingTokenInterface |    32 | interface | Vault.sol                |
    // |  #11 | _receiptToken            |    32 | interface | Vault.sol                |
    // |  #12 | _records                 |    32 | mapping   | Vault.sol                |
    // |  #13 | priceChangedOn           |    32 | uint256   | Vault.sol                |
    // |--------------------------------------------------------------------------------|

    // Space reserved for future upgrades
    uint256[50 - 14] private __gap;


    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * @notice This event is fired when the vault receives a deposit.
     * @param tokenAddress Specifies the token address
     * @param fromAddress Specifies the address of the sender
     * @param depositAmount Specifies the deposit amount in USDC or the ERC20 handled by this contract
     * @param receiptTokensAmount Specifies the amount of receipt tokens issued to the user
     */
    event OnVaultDeposit (address tokenAddress, address fromAddress, uint256 depositAmount, uint256 receiptTokensAmount);

    /**
     * @notice This event is fired when a user withdraws funds from the vault.
     * @param tokenAddress Specifies the token address
     * @param toAddress Specifies the address of the recipient
     * @param erc20Amount Specifies the amount in USDC or the ERC20 handled by this contract
     * @param receiptTokensAmount Specifies the amount of receipt tokens withdrawn by the user
     * @param fee Specifies the withdrawal fee
     */
    event OnVaultWithdrawal (address tokenAddress, address toAddress, uint256 erc20Amount, uint256 receiptTokensAmount, uint256 fee);

    event OnTokenPriceChanged (uint256 prevTokenPrice, uint256 newTokenPrice);
    event OnFlatWithdrawalFeeChanged (uint256 prevValue, uint256 newValue);
    event OnYieldReserveAddressChanged (address prevAddress, address newAddress);
    event OnFeesAddressChanged (address prevAddress, address newAddress);
    event OnInvestmentPercentChanged (uint8 prevValue, uint8 newValue);
    event OnCapitalLocked (uint256 amountLocked);
    event OnInterestClaimed (uint256 interestAmount);
    event OnAprChanged (uint256 prevApr, uint256 newApr);
    event OnEmergencyWithdraw (uint256 withdrawalAmount);
    event OnCompute ();

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    constructor() {
        _disableInitializers();
    }

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    modifier onlyIfInitialized {
        require(_getInitializedVersion() != type(uint8).max, "Contract was not initialized yet");
        _;
    }

    // ---------------------------------------
    // Functions
    // ---------------------------------------
    function initialize(
        address ownerAddr, 
        address controllerAddr, 
        address receiptTokenInterface, 
        address eip20Interface, 
        uint256 initialApr, 
        uint256 initialTokenPrice, 
        uint256 initialMinDepositAmount,
        uint256 flatFeePerc,
        address feesAddr
    ) external initializer {
        _initVault(ownerAddr, controllerAddr, IProgressiveLiability(receiptTokenInterface), IERC20(eip20Interface), initialApr, initialTokenPrice, initialMinDepositAmount, flatFeePerc, feesAddr);
    }

    /// @notice Initializes version 2 of this smart contract
    function initializeV2() external reinitializer(uint8(2)) {
        priceChangedOn = 0;
    }
    
    /**
     * @notice Sets the address of the yield reserve
     * @dev This function can be called by the owner or the controller.
     * @param addr The address of the yield reserve
     */
    function setYieldReserveAddress(address addr) external onlyIfInitialized onlyOwnerOrController {
        require(addr != address(0) && addr != address(this), "Invalid address");
        require(Utils.isContract(addr), "The address must be a contract");

        emit OnYieldReserveAddressChanged(yieldReserveAddress, addr);
        yieldReserveAddress = addr;
    }

    /**
     * @notice Sets the minimum amount for deposits.
     * @dev This function can be called by the owner or the controller.
     * @param minAmount The minimum deposit amount
     */
    function setMinDepositAmount(uint256 minAmount) external onlyIfInitialized onlyOwnerOrController {
        // Checks
        require(minAmount > 0, "Invalid minimum deposit amount");

        // State changes
        minDepositAmount = minAmount;
    }

    /**
     * @notice Sets a new flat fee for withdrawals.
     * @dev The new fee is allowed to be zero (aka: no fees).
     * @param newFeeWithMultiplier The new fee, which is expressed per decimals precision of the underlying token (say USDC for example)
     */
    function setFlatWithdrawalFee(uint256 newFeeWithMultiplier) external onlyIfInitialized onlyOwnerOrController {
        // Example for USDC (6 decimal places):
        // Say the fee is: 0.03%
        // Thus the fee amount is: 0.03 * _decimalsMultiplier = 30000 = 0.03 * (10 to the power of 6)
        emit OnFlatWithdrawalFeeChanged(flatFeePercent, newFeeWithMultiplier);

        flatFeePercent = newFeeWithMultiplier;
    }

    /**
     * @notice Sets the address for collecting fees.
     * @param addr The address
     */
    function setFeeAddress(address addr) external onlyIfInitialized onlyOwnerOrController {
        require(addr != address(0) && addr != feesAddress, "Invalid address for fees");

        emit OnFeesAddressChanged(feesAddress, addr);
        feesAddress = addr;
    }

    /**
     * @notice Sets the total amount deposited in the Vault
     * @dev This function can be called during a migration only. It is guaranteed to fail otherwise.
     * @param newAmount The total amount deposited in the old Vault
     */
    function setTotalDepositedAmount(uint256 newAmount) external onlyIfInitialized onlyOwner {
        require(newAmount > 0, "Non-zero amount required");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance == 0, "Deposits already available");

        // State changes
        _records[currentPeriod].totalDeposited = newAmount;
    }

    /**
     * @notice Deposits funds in the vault. The caller gets the respective amount of receipt tokens in exchange for their deposit.
     * @dev The number of receipt tokens is calculated based on the current token price.
     * @param depositAmount Specifies the deposit amount
     */
    function deposit(uint256 depositAmount) external onlyIfInitialized nonReentrant {
        // Make sure the deposit amount falls within the expected range
        require(depositAmount >= minDepositAmount, "Minimum deposit amount not met");

        // Make sure the sender can cover the deposit (aka: has enough USDC/ERC20 on their wallet)
        require(underlyingTokenInterface.balanceOf(msg.sender) >= depositAmount, "Insufficient funds");

        // Make sure the user approved this contract to spend the amount specified
        require(underlyingTokenInterface.allowance(msg.sender, address(this)) >= depositAmount, "Insufficient allowance");

        // Refresh the current timelime, if needed
        _compute();

        // Determine how many tokens can be issued/minted to the destination address
        uint256 numberOfReceiptTokens = depositAmount * USDF_DECIMAL_MULTIPLIER / _records[currentPeriod].tokenPrice;

        _records[currentPeriod].totalDeposited += depositAmount;

        // Get the current balance of this contract in USDC (or whatever the ERC20 is, which defined at deployment time)
        uint256 balanceBeforeTransfer = underlyingTokenInterface.balanceOf(address(this));

        // Make sure the ERC20 transfer succeeded
        require(underlyingTokenInterface.transferFrom(msg.sender, address(this), depositAmount), "Token transfer failed");

        // The new balance of this contract, after the transfer
        uint256 newBalance = underlyingTokenInterface.balanceOf(address(this));

        // At the very least, the new balance should be the previous balance + the deposit.
        require(newBalance == balanceBeforeTransfer + depositAmount, "Balance verification failed");

        // Issue/mint the respective number of tokens. Users get a receipt token in exchange for their deposit in USDC/ERC20.
        _receiptToken.mint(msg.sender, numberOfReceiptTokens);

        // Emit a new "deposit" event
        emit OnVaultDeposit(address(underlyingTokenInterface), msg.sender, depositAmount, numberOfReceiptTokens);
    }

    /**
     * @notice Withdraws a specific amount of tokens from the Vault.
     * @param receiptTokenAmount The number of tokens to withdraw from the vault
     */
    function withdraw(uint256 receiptTokenAmount) external onlyIfInitialized nonReentrant {
        // Checks
        require(receiptTokenAmount > 0, "Invalid withdrawal amount");

        // Make sure the sender has enough receipt tokens to burn
        require(_receiptToken.balanceOf(msg.sender) >= receiptTokenAmount, "Insufficient balance of tokens");

        // Refresh the current timelime, if needed
        _compute();

        // The amount of USDC you get in exchange, at the current token price
        uint256 withdrawalAmount = toErc20Amount(receiptTokenAmount);
        require(withdrawalAmount <= _records[currentPeriod].totalDeposited, "Invalid withdrawal amount");

        uint256 maxWithdrawalAmount = _records[currentPeriod].totalDeposited * (uint256(100) - uint256(investmentPercent)) / uint256(100);
        require(withdrawalAmount <= maxWithdrawalAmount, "Max withdrawal amount exceeded");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance >= withdrawalAmount, "Insufficient funds in the buffer");

        // Notice that the fee is applied in the underlying currency instead of receipt tokens.
        // The amount applicable to the fee
        uint256 feeAmount = (flatFeePercent > 0) ? withdrawalAmount * flatFeePercent / uint256(100) / _decimalsMultiplier : 0;
        require(feeAmount < withdrawalAmount, "Invalid fee");

        // The amount to send to the destination address (recipient), after applying the fee
        uint256 withdrawalAmountAfterFees = withdrawalAmount - feeAmount;

        // Update the record per amount withdrawn, with no applicable fees.
        // A common mistake would be update the metric below with fees included. DONT DO THAT.
        _records[currentPeriod].totalDeposited -= withdrawalAmount;

        // Burn the number of receipt tokens specified
        _receiptToken.burn(msg.sender, receiptTokenAmount);

        // Transfer the respective amount of underlying tokens to the sender (after applying the fee)
        require(underlyingTokenInterface.transfer(msg.sender, withdrawalAmountAfterFees), "Token transfer failed");

        if (feeAmount > 0) {
            // Transfer the applicable fee, if any
            require(underlyingTokenInterface.transfer(feesAddress, feeAmount), "Fee transfer failed");
        }

        // Emit a new "withdrawal" event
        emit OnVaultWithdrawal(address(underlyingTokenInterface), msg.sender, withdrawalAmount, receiptTokenAmount, feeAmount);
    }

    /**
     * @notice Runs an emergency withdrawal. Sends the whole balance to the address specified.
     * @dev This function can be called by the owner only.
     * @param destinationAddr The destination address
     */
    function emergencyWithdraw(address destinationAddr) external onlyIfInitialized nonReentrant onlyOwner {
        require(destinationAddr != address(0) && destinationAddr != address(this), "Invalid address");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance > 0, "The vault has no funds");

        // Transfer all funds to the address specified
        require(underlyingTokenInterface.transfer(destinationAddr, currentBalance), "Token transfer failed");

        emit OnEmergencyWithdraw(currentBalance);
    }

    /**
     * @notice Updates the APR
     * @dev The APR must be expressed with 2 decimal places. Example: 5% = 500 whereas 5.75% = 575
     * @param newApr The new APR, expressed with 2 decimal places.
     */
    function changeApr(uint256 newApr) external onlyIfInitialized onlyOwner {
        require(newApr > 0, "Invalid APR");

        _compute();

        emit OnAprChanged(_records[currentPeriod].apr, newApr);
        _records[currentPeriod].apr = newApr;
    }

    /**
     * @notice Sets the token price, arbitrarily.
     * @param newTokenPrice The new price of the receipt token
     */
    function setTokenPrice(uint256 newTokenPrice) external onlyIfInitialized onlyOwner {
        require(newTokenPrice > 0, "Invalid token price");

        // The price can be changed every 24 hours only.
        require(block.timestamp - priceChangedOn > 24 hours, "Price locked for 24 hours");

        _compute();

        // The price cannot fluctuate more than 1% with respect to the last applicable value
        uint256 currentPrice = _records[currentPeriod].tokenPrice;
        uint256 maxFluctuation = currentPrice * MAX_PRICE_FLUCTUATION / uint256(100);
        require(newTokenPrice <= currentPrice + maxFluctuation && newTokenPrice >= currentPrice - maxFluctuation, "Price change too drastic");

        _records[currentPeriod].tokenPrice = newTokenPrice;
        priceChangedOn = block.timestamp;

        emit OnTokenPriceChanged(currentPrice, newTokenPrice);
    }

    /**
     * @notice Sets the investment percent.
     * @param newPercent The new investment percent
     */
    function setInvestmentPercent(uint8 newPercent) external onlyIfInitialized onlyOwnerOrController {
        require(newPercent > 0 && newPercent < 100, "Invalid investment percent");

        emit OnInvestmentPercentChanged(investmentPercent, newPercent);
        investmentPercent = newPercent;
    }

    /**
     * @notice Computes the metrics (token price, daily interest) for the current day of year
     */
    function compute() external onlyIfInitialized nonReentrant {
        _compute();
    }

    /**
     * @notice Moves the deployable capital from the vault to the yield reserve.
     * @dev This function should fail if it would cause the vault to be left with <10% of deposited amount
     */
    function lockCapital() external onlyIfInitialized nonReentrant onlyOwnerOrController {
        _compute();

        // Get the maximum amount of capital that can be deployed at this point in time
        uint256 maxDeployableAmount = getDeployableCapital();
        require(maxDeployableAmount > 0, "No capital to deploy");

        require(underlyingTokenInterface.transfer(yieldReserveAddress, maxDeployableAmount), "Transfer failed");
        emit OnCapitalLocked(maxDeployableAmount);
    }

    /**
     * @notice Claims the daily interest promised per APR.
     */
    function claimDailyInterest() external onlyIfInitialized nonReentrant onlyOwnerOrController {
        _compute();

        // Get the daily interest that need to be claimed at this point in time
        uint256 dailyInterestAmount = getDailyInterest();

        uint256 balanceBefore = underlyingTokenInterface.balanceOf(address(this));

        IDeployable(yieldReserveAddress).claim(dailyInterestAmount);

        uint256 balanceAfter = underlyingTokenInterface.balanceOf(address(this));

        require(balanceAfter >= balanceBefore + dailyInterestAmount, "Balance verification failed");

        emit OnInterestClaimed(dailyInterestAmount);
    }

    /**
     * @notice Gets the period of the current unix epoch.
     * @dev The period is the zero-based day of the current year. It is the number of days that elapsed since January 1st of the current year.
     * @return Returns a number between [0..364]
     */
    function getPeriodOfCurrentEpoch() external view returns (uint256) {
        return DateUtils.diffDays(_startOfYearTimestamp, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function getSnapshot(uint256 i) external view returns (uint256 apr, uint256 tokenPrice, uint256 totalDeposited, uint256 dailyInterest) {
        apr = _records[i].apr;
        tokenPrice = _records[i].tokenPrice;
        totalDeposited = _records[i].totalDeposited;
        dailyInterest = _records[i].dailyInterest;
    }

    /**
     * @notice Gets the total amount deposited in the vault.
     * @dev This value increases when people deposits funds in the vault. Likewise, it decreases when people withdraw from the vault.
     * @return The total amount deposited in the vault.
     */
    function getTotalDeposited() external view returns (uint256) {
        return _records[currentPeriod].totalDeposited;
    }

    /**
     * @notice Gets the daily interest
     * @return The daily interest
     */
    function getDailyInterest() public view returns (uint256) {
        return _records[currentPeriod].dailyInterest;
    }

    /**
     * @notice Gets the current token price
     * @return The price of the token
     */
    function getTokenPrice() external view returns (uint256) {
        return _records[currentPeriod].tokenPrice;
    }

    /**
     * @notice Gets the maximum amount of USDC/ERC20 you can withdraw from the vault
     * @return The maximum withdrawal amount
     */
    function getMaxWithdrawalAmount() external view returns (uint256) {
        return _records[currentPeriod].totalDeposited * (uint256(100) - uint256(investmentPercent)) / uint256(100);
    }

    /**
     * @notice Gets the amount of capital that can be deployed.
     * @dev This is the amount of capital that will be moved from the Vault to the Yield Reserve.
     * @return The amount of deployable capital
     */
    function getDeployableCapital() public view returns (uint256) {
        // X% of the total deposits should remain in the vault. This is the target vault balance.
        //
        // For example:
        // ------------
        // If the total deposits are 800k USDC and the investment percent is set to 90%
        // then the vault should keep the remaining 10% as a buffer for withdrawals.
        // In this example the vault should keep 80k USDC, which is the 10% of 800k USDC.
        uint256 shouldRemainInVault = _records[currentPeriod].totalDeposited * (uint256(100) - uint256(investmentPercent)) / uint256(100);

        // The current balance at the Vault
        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));

        // Return the amount of deployable capital
        return (currentBalance > shouldRemainInVault) ? currentBalance - shouldRemainInVault : 0;
    }

    /**
     * @notice Returns the amount of USDC you would get by burning the number of receipt tokens specified, at the current price.
     * @return The amount of USDC you get in exchange, at the current token price
     */
    function toErc20Amount(uint256 receiptTokenAmount) public view returns (uint256) {
        return receiptTokenAmount * _records[currentPeriod].tokenPrice / USDF_DECIMAL_MULTIPLIER;
    }

    function _initVault(
        address ownerAddr, 
        address controllerAddr, 
        IProgressiveLiability receiptTokenInterface, 
        IERC20 eip20Interface, 
        uint256 initialApr, 
        uint256 initialTokenPrice, 
        uint256 initialMinDepositAmount,
        uint256 flatFeePerc,
        address feesAddr
    ) internal onlyInitializing {
        // Checks
        require(initialMinDepositAmount > 0, "Invalid min deposit amount");
        require(feesAddr != address(0), "Invalid address for fees");

        // State changes
        _initController(ownerAddr, controllerAddr);
        underlyingTokenInterface = eip20Interface;
        _receiptToken = receiptTokenInterface;
        minDepositAmount = initialMinDepositAmount;
        _decimalsMultiplier = uint256(10) ** uint256(eip20Interface.decimals());

        uint256 currentTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time

        // Get the current year
        uint256 currentYear = DateUtils.getYear(currentTimestamp);

        // Set the timestamp of January 1st of the current year (the year starts at this unix epoch)
        _startOfYearTimestamp = DateUtils.timestampFromDateTime(currentYear, 1, 1, 0, 0, 0);

        // Create the first record
        currentPeriod = DateUtils.diffDays(_startOfYearTimestamp, currentTimestamp);
        
        // The APR must be expressed with 2 decimal places. Example: 5% = 500 whereas 5.75% = 575
        _records[currentPeriod] = Record(initialApr, initialTokenPrice, 0, 0);

        flatFeePercent = flatFeePerc;
        feesAddress = feesAddr;
        investmentPercent = 90;
    }

    function _compute() private {
        uint256 currentTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time

        uint256 newPeriod = DateUtils.diffDays(_startOfYearTimestamp, currentTimestamp);
        if (newPeriod <= currentPeriod) return;

        uint256 x = 0;

        for (uint256 i = currentPeriod + 1; i <= newPeriod; i++) {
            x++;
            _records[i].apr = _records[i - 1].apr;
            _records[i].totalDeposited = _records[i - 1].totalDeposited;

            uint256 diff = _records[i - 1].apr * USDF_DECIMAL_MULTIPLIER * uint256(100) / uint256(36500);
            _records[i].tokenPrice = _records[i - 1].tokenPrice + (diff / uint256(10000));
            _records[i].dailyInterest = _records[i - 1].totalDeposited * uint256(_records[i - 1].apr) / uint256(3650000);
            if (x >= 30) break;
        }

        currentPeriod += x;
        emit OnCompute();
    }
}