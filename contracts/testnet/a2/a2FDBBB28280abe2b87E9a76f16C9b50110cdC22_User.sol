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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Abstract contract that implements access check functions
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/access/IDAOAuthority.sol";

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract DAOAccessControlled is Context {
    
    /* ========== EVENTS ========== */

    event AuthorityUpdated(address indexed authority);

    /* ========== STATE VARIABLES ========== */

    IDAOAuthority public authority;    
    uint256[5] __gap; // storage gap

    /* ========== Initializer ========== */

    function _setAuthority(address _authority) internal {        
        authority = IDAOAuthority(_authority);
        emit AuthorityUpdated(_authority);        
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthority() {
        require(address(authority) == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyGovernor() {
        require(authority.getAuthorities().governor == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyPolicy() {
        require(authority.getAuthorities().policy == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyAdmin() {
        require(authority.getAuthorities().admin == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyEntityAdmin(address _entity) {
        require(
            IEntity(_entity).getEntityAdminDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyBartender(address _entity) {
        require(
            IEntity(_entity).getBartenderDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyDispatcher() {
        require(authority.getAuthorities().dispatcher == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyCollectionManager() {
        require(authority.getAuthorities().collectionManager == _msgSender(), "UNAUTHORIZED");
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(address _newAuthority) external onlyGovernor {
       _setAuthority(_newAuthority);
    }

    /* ========= ERC2771 ============ */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return address(authority) != address(0) && forwarder == authority.getAuthorities().forwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    modifier onlyForwarder() {
        // this modifier must check msg.sender directly (not through _msgSender()!)
        require(isTrustedForwarder(msg.sender), "UNAUTHORIZED");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    uint16 internal constant MIN_NAME_LENGTH = 3;
    uint16 internal constant MAX_NAME_LENGTH = 35;
    uint16 internal constant MAX_STATUS_LENGTH = 70;
    uint16 internal constant MAX_URI_LENGTH = 6000;
}

// SPDX-License-Identifier: MIT

// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol

pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

/***************************************************************************************************
// This contract defines a User of the DAO eco-system
// The users can be different people who interact with the dao contracts through their
// respective end-user applications(Eg: A patron, bar-tender, bar-admin, etc.)
// Once the user registers on the app, it should create a profile for the user on the blockchain
// using this contract
***************************************************************************************************/
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "../libraries/Constants.sol";
import "../libraries/StringUtils.sol";
import "../access/DAOAccessControlled.sol";

import "../../interfaces/user/IUser.sol";
import "../../interfaces/user/ILoot8SignatureVerification.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract User is IUser, Initializable, DAOAccessControlled {
    using Counters for Counters.Counter;

    // An incremental unique Id that identifies a user
    Counters.Counter private userIds;

    // A list of all registered users
    address[] public allUsers;

    // Protocol-wide banlist
    mapping(address => bool) public bannedUsers;

    // User wallet address => User Attributes
    // This maps unique user Ids to users details
    mapping(address => UserAttributes) public userAttributes;

    struct LinkedExternalAccounts {
        address account;
        bytes signature;
        uint nonce;
    }

    // Mapping Users Loot8 wallet address => Linked external wallet addresses
    mapping(address => LinkedExternalAccounts[]) public linkedExternalAccounts;

    string public linkMessage;

    address public verifier;

    // Backend that can set or unset users verification state
    address public thirdPartyVerificationAuthority;
    // storing 3rd party profile urls
    mapping(address => string[]) public thirdPartyProfileUrls;

    function initialize(address _authority) public initializer {
        DAOAccessControlled._setAuthority(_authority); 
        userIds.increment(); // Start from 1 as id == 0 is a check for existence
    }

    function initializer2(address _verifier) public reinitializer(2) {
        verifier = _verifier;
        linkMessage = 'Link this Account to Loot8';
    }

    function initializer3(address _thirdPartyVerificationAuthority) public reinitializer(3) {
        thirdPartyVerificationAuthority = _thirdPartyVerificationAuthority;
    }

    /**
     * @notice              Registers the caller as a new user. Only application calls must be accepted.
     * @param   _name       User name
     * @param   _walletAddress  User avatar URI
     * @param   _avatarURI    Data URI for the user's avatar
     * @param   _dataURI    Data URI for the user
     * @return  _           User ID
     */
    function register(
        string memory _name,
        address _walletAddress,
        string memory _avatarURI,
        string memory _dataURI
    ) external onlyDispatcher returns (uint256) {
        return _createUser(_name, _walletAddress, _avatarURI, _dataURI);
    }

    function deregister() external {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT USER");
        uint256 userCount = allUsers.length;
        address lastUser = allUsers[userCount - 1];
        for(uint256 i = 0; i < userCount; i++) {
            address user = allUsers[i];
            if(user == _msgSender()) {
                if(i < userCount-1) {
                    allUsers[i] = lastUser;
                }
                allUsers.pop();
                delete userAttributes[_msgSender()];
                delete linkedExternalAccounts[_msgSender()];
                break;
            }
        }

        uint256 thirdPartyProfileCount = thirdPartyProfileUrls[_msgSender()].length;

        if (thirdPartyProfileCount > 0) {
            for(uint256 i = 0; i < thirdPartyProfileCount; i++) {
                thirdPartyProfileUrls[_msgSender()].pop();
            }
            emit ThirdPartyProfileUrlUpdated(_msgSender());
        }

        emit UserRemoved(_msgSender());
    }

    /**
     * @notice Allows a user to set their display name
     * @param _name string Name
    */
    function changeName(string memory _name) external {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT");
        uint256 len = StringUtils.strlen(_name);
        require(len >= Constants.MIN_NAME_LENGTH && len <= Constants.MAX_NAME_LENGTH, "Name length out of range");
        
        userAttributes[_msgSender()].name = _name;
        emit NameChanged(_msgSender(), _name);
    }

    /**
     * @notice Update AvatarURI from mobile app.
     * @param _avatarURI string AvatarURI
    */
    function setAvatarURI(string memory _avatarURI) external onlyForwarder {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT");

        userAttributes[_msgSender()].avatarURI = _avatarURI;
        emit AvatarURIChanged(_msgSender(), _avatarURI);
    }

    /**
     * @notice Update DataURI from mobile app.
     * @param _dataURI string Data URI
    */
    function setDataURI(string memory _dataURI) external onlyForwarder {
        require(userAttributes[_msgSender()].id != 0, "NON EXISTENT");

        userAttributes[_msgSender()].dataURI = _dataURI;
        emit DataURIChanged(_msgSender(), _dataURI);
    }

    /**
     * @notice          Puts a user on ban list
     * @param   _user   A user to ban
     */
    function ban(address _user) external onlyPolicy {
        require(!bannedUsers[_user], "Already banned");
   
        bannedUsers[_user] = true;
        emit Banned(_user);
    }

    /**
     * @notice          Lifts user ban
     * @param   _user   A user to lift the ban
     */
    function liftBan(address _user) external onlyPolicy {
        require(bannedUsers[_user], "Not banned");
        
        bannedUsers[_user] = false;        
        emit BanLifted(_user);
    }

    function getAllUsers(bool _includeBanned) public view returns(UserAttributes[] memory _users) {
        if (_includeBanned) {
            _users = new UserAttributes[](allUsers.length);
            for (uint256 i = 0; i < allUsers.length; i++) {
                _users[i] = userAttributes[allUsers[i]];
            }
        } else {
            uint256 count;
            for (uint256 i = 0; i < allUsers.length; i++) {
                if (!bannedUsers[allUsers[i]]) {
                    count++;
                }
            }

            _users = new UserAttributes[](count);
            uint256 idx;
            for (uint256 i = 0; i < allUsers.length; i++) {
                if (!bannedUsers[allUsers[i]] ) {
                    _users[idx] = userAttributes[allUsers[i]];
                    idx++;
                }
            }
       }
    }

    /**
     * @notice      Returns a list of banned users
     */
    function getBannedUsers() external view returns(UserAttributes[] memory _users) {
        uint256 count;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (bannedUsers[allUsers[i]]) {
                count++;
            }
        }

        _users = new UserAttributes[](count);
        uint256 idx;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (bannedUsers[allUsers[i]] ) {
                _users[idx] = userAttributes[allUsers[i]];
                idx++;
            }
        }  
    }

    /**
     * @notice Checks is an address is a registered user 
     * @notice of the application and not banned
     * @param _user address Wallet address of the user
     * @return bool true if valid user false if invalid
    */
    function isValidPermittedUser(address _user) public view returns(bool) {
        
        if(userAttributes[_user].id > 0 && !bannedUsers[_user]) {
            return true;
        }

        return false;
    }

    /**
     * @notice Adds entity to lists for holding positions held
     * @notice by user at different entities
     * @param _user address Wallet address of the user
     * @param _entity address Entity contract address
     * @param _admin bool Entity added to admin list if true else to bartender list
    */
    function addEntityToOperatorsList(address _user, address _entity, bool _admin) external {
        
        require(_msgSender() == _entity, "UNAUTHORIZED");
        
        (bool isOperator,) = isUserOperatorAt(_user, _entity, _admin);

        if(isOperator) {
            return;
        } else if(_admin) {
            userAttributes[_user].adminAt.push(_entity);
        } else {
            userAttributes[_user].bartenderAt.push(_entity);
        }
        
    }

    /**
     * @notice Removes entity from lists for holding positions held
     * @notice by user at different entities
     * @param _user address Wallet address of the user
     * @param _entity address Entity contract address
     * @param _admin bool Entity removed from admin list if true else from bartender list
    */
    function removeEntityFromOperatorsList(address _user, address _entity, bool _admin) external {
        
        require(_msgSender() == _entity, "UNAUTHORIZED");

        (bool isOperator, uint256 index) = isUserOperatorAt(_user, _entity, _admin);

        if(!isOperator) {
            return;
        } else if(_admin) {
            userAttributes[_user].adminAt[index] = userAttributes[_user].adminAt[userAttributes[_user].adminAt.length - 1];
            userAttributes[_user].adminAt.pop();
        } else {
            userAttributes[_user].bartenderAt[index] = userAttributes[_user].bartenderAt[userAttributes[_user].bartenderAt.length - 1];
            userAttributes[_user].bartenderAt.pop();
        }
        
    }

    /**
     * @notice Checks if a user is an operator at a specific entity
     * @param _user address Wallet address of the user
     * @param _entity address Entity contract address
     * @param _admin bool Checks admin list if true else bartender list
     * @return (bool, uint256) Tuple representing if user is operator and index of entity in list
    */
    function isUserOperatorAt(address _user, address _entity, bool _admin) public view returns(bool, uint256) {
        
        address[] memory operatorList;

        if(_admin) {
            operatorList = userAttributes[_user].adminAt;
        } else {
            operatorList = userAttributes[_user].bartenderAt;
        }

        for(uint256 i = 0; i < operatorList.length; i++) {
            if(operatorList[i] == _entity) {
                return(true, i);
            }
        }

        return(false, 0);

    }   

    /**
     * @notice Creates a user with the given name, avatar and wallet Address
     * @notice Newly created users are added to a list and stored in this contracts storage
     * @notice A mapping maps each user ID to their details
     * @notice The application can use the list and mapping to get relevant details about the user
     * @param _name string Name of the user
     * @param _walletAddress address Wallet address of the user
     * @param _avatarURI string Avatar URI of the user
     * @param _dataURI string Data URI of the user
     * @return userId_ User ID for newly created user
    */
    function _createUser(
        string memory _name,
        address _walletAddress,
        string memory _avatarURI,
        string memory _dataURI
    ) internal returns (uint256 userId_) {
        require(_walletAddress != address(0), "Wallet address needed");
        require(userAttributes[_walletAddress].id == 0, "User already exists");
        uint256 len = StringUtils.strlen(_name);
        uint256[20] memory __gap;
        require(len >= Constants.MIN_NAME_LENGTH && len <= Constants.MAX_NAME_LENGTH, "Name length out of range");
        require(StringUtils.strlen(_avatarURI) <= Constants.MAX_URI_LENGTH, "Avatar URI too long");
        require(StringUtils.strlen(_dataURI) <= Constants.MAX_URI_LENGTH, "Data URI too long");

        // Assign a unique ID to the new user to be created
        userId_ = userIds.current();

        address[] memory _initList;
        // Set details for the user and add them to the mapping
        userAttributes[_walletAddress] = UserAttributes({
            id: userId_,
            name: _name,
            wallet: _walletAddress,
            avatarURI: _avatarURI,
            dataURI: _dataURI,
            adminAt: _initList,
            bartenderAt: _initList,
            __gap: __gap
        });

        // Add the new user to list of users
        allUsers.push(_walletAddress);

        // Increment ID for next user
        userIds.increment();

        // Emit an event for user creation with details
        emit UserCreated(_walletAddress, userId_, _name);
    }

    function linkExternalAccount(address _account, bytes memory _signature) external {
        
        address user = _msgSender();
        require(isValidPermittedUser(user), "UNAUTHORIZED");
        require(!isLinkedAccount(user, _account), "ACCOUNT IS ALREADY LINKED");
    
        ILoot8SignatureVerification verifierContract = ILoot8SignatureVerification(verifier);

        uint256 nonce = verifierContract.getSignerCurrentNonce(_account);

        require(verifierContract.verifyAndUpdateNonce(
            _account,
            user,
            linkMessage,
            _signature
        ), "INVALID SIGNATURE");

        linkedExternalAccounts[user].push(LinkedExternalAccounts({
            account: _account,
            signature: _signature,
            nonce: nonce
        }));

        emit LinkedExternalAccountForUser(user, _account);
    }

    function delinkExternalAccount(address _account) external {
        
        address user = _msgSender();
        require(isValidPermittedUser(user), "UNAUTHORIZED");
        
        for(uint256 i = 0; i < linkedExternalAccounts[user].length; i++) {
            if(linkedExternalAccounts[user][i].account == _account) {
                if(i < linkedExternalAccounts[user].length) {
                    linkedExternalAccounts[user][i] = linkedExternalAccounts[user][linkedExternalAccounts[user].length - 1];
                }
                linkedExternalAccounts[user].pop();
                emit DeLinkedExternalAccountForUser(user, _account);
                break;
            }
        }
    }

    function isLinkedAccount(address _user, address _account) public view returns(bool) {

        for(uint256 i = 0; i < linkedExternalAccounts[_user].length; i++) {
            if(linkedExternalAccounts[_user][i].account == _account) {
                return true;
            }
        }

        return false;
    }

    function getLinkedAccountForUser(address _user) public view returns(LinkedExternalAccounts[] memory linkedAccounts) {
        linkedAccounts = new LinkedExternalAccounts[](linkedExternalAccounts[_user].length);
        for(uint256 i = 0; i < linkedExternalAccounts[_user].length; i++) {
            linkedAccounts[i] = linkedExternalAccounts[_user][i];
        }
    }

    // method does not cater for string sanity or duplication checks
    // this must be done by our "trusted" caller
    function linkUserThirdPartyProfileUrls(
        address _user,
        string[] memory _thirdPartyProfileURLs
    ) public {
        require(_msgSender() == thirdPartyVerificationAuthority, "UNAUTHORIZED");

        for (uint256 i = 0; i < _thirdPartyProfileURLs.length; i++) {
            thirdPartyProfileUrls[_user].push(_thirdPartyProfileURLs[i]);
        }

        emit ThirdPartyProfileUrlUpdated(_user);
    }

    function unlinkUserThirdPartyProfileUrls(
        address _user,
        string[] memory _linksToRemove
    ) public {
        require(_msgSender() == thirdPartyVerificationAuthority, "UNAUTHORIZED");

        uint256 linksToRemoveCount = _linksToRemove.length;
        uint256 existingLinksCount = thirdPartyProfileUrls[_user].length;

        for (uint256 l = 0; l < linksToRemoveCount; l++) {
            for (uint256 e = 0; e < existingLinksCount; e++) {
                if (keccak256(abi.encodePacked(_linksToRemove[l])) == keccak256(abi.encodePacked(thirdPartyProfileUrls[_user][e]))) {
                    if (e < existingLinksCount - 1) {
                        uint256 lastElement = thirdPartyProfileUrls[_user].length - 1;
                        thirdPartyProfileUrls[_user][e] = thirdPartyProfileUrls[_user][lastElement];
                    }
                    thirdPartyProfileUrls[_user].pop();
                    existingLinksCount = thirdPartyProfileUrls[_user].length;
                }
            }
        }


        emit ThirdPartyProfileUrlUpdated(_user);
    }

    function getThirdPartyVerifiedProfileUrlCount(address _user) public view returns (uint256) {
        return thirdPartyProfileUrls[_user].length;
    }

    function getThirdPartyVerifiedProfileUrl(address _user, uint256 idx) public view returns (string memory) {
        return thirdPartyProfileUrls[_user][idx];
    }

    function setThirdPartyVerificationStatusAuthority(address _thirdPartyVerificationAuthority) public onlyGovernor {
        thirdPartyVerificationAuthority = _thirdPartyVerificationAuthority;
    }

    function getUserAdminList(address _user, bool _admin) public view returns(address[] memory _entities) {
        return _admin ? userAttributes[_user].adminAt : userAttributes[_user].bartenderAt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address _newGovernor);
    event ChangedPolicy(address _newPolicy);
    event ChangedAdmin(address _newAdmin);
    event ChangedForwarder(address _newForwarder);
    event ChangedDispatcher(address _newDispatcher);
    event ChangedCollectionHelper(address _newCollectionHelper);
    event ChangedCollectionManager(address _newCollectionManager);
    event ChangedTokenPriceCalculator(address _newTokenPriceCalculator);

    struct Authorities {
        address governor;
        address policy;
        address admin;
        address forwarder;
        address dispatcher;
        address collectionManager;
        address tokenPriceCalculator;
    }

    function collectionHelper() external view returns(address);
    function getAuthorities() external view returns(Authorities memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntity is ILocationBased {

    /* ========== EVENTS ========== */
    event EntityToggled(address _entity, bool _status);
    event EntityUpdated(address _entity, Area _area, string _dataURI, address _walletAddress);
        
    event EntityDataURIUpdated(string _oldDataURI,  string _newDataURI);    

    event EntityAdminGranted(address _entity, address _entAdmin);
    event BartenderGranted(address _entity, address _bartender);
    event EntityAdminToggled(address _entity, address _entAdmin, bool _status);
    event BartenderToggled(address _entity, address _bartender, bool _status);

    event CollectionWhitelisted(address indexed _entity, address indexed _collection, uint256 indexed _chainId);
    event CollectionDelisted(address indexed _entity, address indexed _collection, uint256 indexed _chainId);

    event UserContractSet(address _newUserContract);
    
    struct Operator {
        uint256 id;
        bool isActive;

        // Storage Gap
        uint256[5] __gap;
    }

    struct BlacklistDetails {
        // Timestamp after which the patron should be removed from blacklist
        uint256 end;

        // Storage Gap
        uint256[5] __gap;
    }

    struct EntityData {

        // Entity wallet address
        address walletAddress;
        
        // Flag to indicate whether entity is active or not
        bool isActive;

        // Data URI where file containing entity details resides
        string dataURI;

        // name of the entity
        string name;

        // Storage Gap
        uint256[20] __gap;

    }

    function toggleEntity() external returns(bool _status);

    function updateEntity(
        Area memory _area,
        string memory _name,
        string memory _dataURI,
        address _walletAddress
    ) external;

     function updateDataURI(
        string memory _dataURI
    ) external;
    

    function addEntityAdmin(address _entAdmin) external;

    function addBartender(address _bartender) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function getEntityData() external view returns(EntityData memory);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function getAllEntityAdmins(bool _onlyActive) external view returns(address[] memory);

    function getAllBartenders(bool _onlyActive) external view returns(address[] memory);
    
    function getLocationDetails() external view returns(string[] memory, uint256);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILocationBased {

    struct Area {
        // Area Co-ordinates.
        // For circular area, points[] length = 1 and radius > 0
        // For arbitrary area, points[] length > 1 and radius = 0
        // For arbitrary areas UI should connect the points with a
        // straight line in the same sequence as specified in the points array
        string[] points; // Each element in this array should be specified in "lat,long" format
        uint256 radius; // Unit: Meters. 2 decimals(5000 = 50 meters)
    }    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILoot8SignatureVerification {

    function getSignerCurrentNonce(address _signer) external view returns(uint256);

    function verify(
        address _account, 
        address _loot8Account,
        string memory _message,
        bytes memory _signature
    ) external view returns (bool);

    function verifyAndUpdateNonce(
        address _account, 
        address _loot8Account,
        string memory _message,
        bytes memory _signature
    ) external returns (bool);
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IUser {

    /* ========== EVENTS ========== */
    event UserCreated(address indexed _walletAddress, uint256 indexed _userId, string _name);
    event UserRemoved(address indexed _walletAddress);

    event NameChanged(address indexed _user, string _name);
    event AvatarURIChanged(address indexed _user, string _avatarURI);
    event DataURIChanged(address indexed _user, string _dataURI);

    event Banned(address indexed _user);
    event BanLifted(address indexed _user);

    event LinkedExternalAccountForUser(address _user, address _account);
    event DeLinkedExternalAccountForUser(address _user, address _account);

    event ThirdPartyProfileUrlUpdated(address _user);

    struct UserAttributes {
        uint256 id;
        string name;
        address wallet;
        string avatarURI;
        string dataURI;
        address[] adminAt; // List of entities where user is an Admin
        address[] bartenderAt; // List of entities where user is a bartender
        uint256[20] __gap;
    }

    function register(string memory _name, address walletAddress, string memory _avatarURI, string memory _dataURI) external returns (uint256);

    function deregister() external;

    function changeName(string memory _name) external;
    
    function getAllUsers(bool _includeBanned) external view returns(UserAttributes[] memory _users);

    function getBannedUsers() external view returns(UserAttributes[] memory _users);

    function isValidPermittedUser(address _user) external view returns(bool);

    function addEntityToOperatorsList(address _user, address _entity, bool _admin) external;

    function removeEntityFromOperatorsList(address _user, address _entity, bool _admin) external;

    function isUserOperatorAt(address _user, address _entity, bool _admin) external view returns(bool, uint256);

    function linkExternalAccount(address _account, bytes memory _signature) external;

    function delinkExternalAccount(address _account) external;

    function isLinkedAccount(address _user, address _account) external view returns(bool);

}