// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

/**************************************************************************************************************
    This is an administrative contract for entities(brands, establishments or partners)
    in the DAO eco-system. The contract is spinned up by the DAO Governor using the Entity Factory.
    An Entity Admin is set up on each contract to perform managerial tasks for the entity.
**************************************************************************************************************/
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../access/DAOAccessControlled.sol";
import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/user/IUser.sol";
import "../../interfaces/access/IDAOAuthority.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Entity is IEntity, Initializable, DAOAccessControlled {

    using Counters for Counters.Counter;

    // Unique Ids for Operator
    Counters.Counter private operatorIds;  

    // Details for the entity
    EntityData public entityData;

    // Area where the entity is located
    Area public area;

    // Contract for registered users
    address public userContract;
    
    // List of all admins for this entity
    address[] public entityAdmins;

    // List of all bartenders for this entity
    address[] public bartenders;

    // Blacklisted patrons
    mapping( address => BlacklistDetails ) public blacklist;

    // Entity Admin Address => Entity Admin Details
    mapping( address => Operator ) public entityAdminDetails;

    // Bartender Address => Bartender Details
    mapping( address => Operator ) public bartenderDetails;
    
    function initialize(
        Area memory _area,
        string memory _name,
        string memory _dataURI,
        address _walletAddress,
        address _authority,
        address _userContract
    ) public initializer {

        DAOAccessControlled._setAuthority(_authority);
        userContract = _userContract;
        area = _area;
        entityData.name = _name;
        entityData.dataURI = _dataURI;
        entityData.walletAddress = _walletAddress;
        entityData.isActive = true;

        operatorIds.increment(); // Start from 1 as 0 is used for existence check
    }

    /**
     * @notice Allows the DAO administration to enable/disable an entity.
     * @notice When an entity is disabled all collections for the given entity are also retired.
     * @notice Enabling the same entity back again will need configuration of new Collectibles.
     * @return _status boolean Status after toggling
    */
    function toggleEntity() external onlyGovernor returns(bool _status) {

        // Activates/deactivates the entity
        entityData.isActive = !entityData.isActive;

        // Poll status to pass as return value
        _status = entityData.isActive;

        // Emit an entity toggling event with relevant details
        emit EntityToggled(address(this), _status);
    }

    /**
     * @notice Allows DAO Operator to modify the data for an entity
     * @notice Entity area, wallet address and ipfs location can be modified
     * @param _area Area Address of the entity
     * @param _name string Name of the entity
     * @param _dataURI string DataURI for the entity
     * @param _walletAddress address Wallet address for the entity
    */
    function updateEntity(
        Area memory _area,
        string memory _name,
        string memory _dataURI,
        address _walletAddress
    ) external onlyGovernor {

        area = _area;
        entityData.name = _name;
        entityData.dataURI = _dataURI;
        entityData.walletAddress = _walletAddress;

        // Emit an event for entity updation with the relevant details
        emit EntityUpdated(address(this), _area, _dataURI, _walletAddress);
    }

    /**
     * @notice Allows Entity Admin to modify the dataURI for an entity
     * @param _dataURI string DataURI for the entity
    */
    function updateDataURI(string memory _dataURI) external onlyEntityAdmin(address(this)) {
        string memory olddataURI = entityData.dataURI;
        entityData.dataURI = _dataURI;
        emit EntityDataURIUpdated(olddataURI, entityData.dataURI);
    }

    /**
     * @notice Grants entity admin role for an entity to a given wallet address
     * @param _entAdmin address wallet address of the entity admin
    */
    function addEntityAdmin(address _entAdmin) external onlyGovernor {

        // Admin cannot be zero address
        require(_entAdmin != address(0), "ZERO ADDRESS");

        // _entAdmin should be a valid user of the application
        require(IUser(userContract).isValidPermittedUser(_entAdmin), "INVALID OR BANNED USER");

        // Check if address already an entity admin
        require(entityAdminDetails[_entAdmin].id == 0, "ADDRESS ALREADY ADMIN FOR ENTITY");

        // Add entity admin to list of admins
        entityAdmins.push(_entAdmin);

        // Set details for the entity admin
        uint256[5] memory __gap;
        entityAdminDetails[_entAdmin] = Operator({
            id: operatorIds.current(),
            isActive: true,
            __gap: __gap
        });

        // Add entity to users admin lists
        IUser(userContract).addEntityToOperatorsList(_entAdmin, address(this), true);

        // Increment the Id for next admin addition
        operatorIds.increment();

        // Emit event to signal grant of entity admin role to an address
        emit EntityAdminGranted(address(this), _entAdmin);
    }

    /**
     * @notice Grants bartender role for an entity to a given wallet address
     * @param _bartender address Wallet address of the bartender
    */
    function addBartender(address _bartender) external onlyEntityAdmin(address(this)) {
        
        // Bartender cannot be zero address
        require(_bartender != address(0), "ZERO ADDRESS");

        // _bartender should be a valid user of the application
        require(IUser(userContract).isValidPermittedUser(_bartender), "INVALID OR BANNED USER");

        // Check if address already a bartender
        require(bartenderDetails[_bartender].id == 0, "ADDRESS ALREADY BARTENDER FOR ENTITY");

        // Add bartender to list of bartenders
        bartenders.push(_bartender);

        // Set details for the bartender
        // Data Loc for admin details: dataURI, "/admins/" , adminId
        uint256[5] memory __gap;
        bartenderDetails[_bartender] = Operator({
            id: operatorIds.current(),
            isActive: true,
            __gap: __gap
        });

        // Add entity to users admin lists
        IUser(userContract).addEntityToOperatorsList(_bartender, address(this), false);

        // Increment the Id for next admin addition
        operatorIds.increment();

        // Emit event to signal grant of bartender role to an address
        emit BartenderGranted(address(this), _bartender);
    }

    function toggleEntityAdmin(address _entAdmin) external onlyGovernor returns(bool _status) {

        require(entityAdminDetails[_entAdmin].id != 0, "No such entity admin for this entity");
    
        entityAdminDetails[_entAdmin].isActive = !entityAdminDetails[_entAdmin].isActive;

        // Poll status to pass as return value
        _status = entityAdminDetails[_entAdmin].isActive;

        if(_status) {
            // Add entity to users admin lists
            IUser(userContract).addEntityToOperatorsList(_entAdmin, address(this), true);
        } else {
            // Remove entity from users admin lists
            IUser(userContract).removeEntityFromOperatorsList(_entAdmin, address(this), true);
        }

        // Emit event to signal toggling of entity admin role
        emit EntityAdminToggled(address(this), _entAdmin, _status);
    }

    function toggleBartender(address _bartender) external onlyEntityAdmin(address(this)) returns(bool _status) {
        
        require(bartenderDetails[_bartender].id != 0, "No such bartender for this entity");

        bartenderDetails[_bartender].isActive = !bartenderDetails[_bartender].isActive;

        // Poll status to pass as return value
        _status = bartenderDetails[_bartender].isActive;

        if(_status) {
            // Add entity to users admin lists
            IUser(userContract).addEntityToOperatorsList(_bartender, address(this), false);
        } else {
            // Remove entity from users admin lists
            IUser(userContract).removeEntityFromOperatorsList(_bartender, address(this), false);
        }

        // Emit event to signal toggling of bartender role
        emit BartenderToggled(address(this), _bartender, _status);
    }

    function addPatronToBlacklist(address _patron, uint256 _end) external onlyEntityAdmin(address(this)) {
        uint256[5] memory __gap;
        blacklist[_patron] = BlacklistDetails({
            end: _end,
            __gap: __gap
        });
    }

    function removePatronFromBlacklist(address _patron) external onlyEntityAdmin(address(this)) {
        require(blacklist[_patron].end > 0, "Patron not blacklisted");
        blacklist[_patron].end = 0;
    }

    function getEntityData() public view returns(EntityData memory) {
        return entityData;
    }

    function getEntityAdminDetails(address _entAdmin) public view returns(Operator memory) {
        return entityAdminDetails[_entAdmin];
    }

    function getBartenderDetails(address _bartender) public view returns(Operator memory) {
        return bartenderDetails[_bartender];
    }

    function getAllEntityAdmins(bool _onlyActive) public view returns(address[] memory _entAdmins) {
        if(_onlyActive) {

            uint count;
            for (uint256 i = 0; i < entityAdmins.length; i++) {
                if (entityAdminDetails[entityAdmins[i]].isActive) {
                    count++;
                }
            }
            
            _entAdmins = new address[](count);
            uint256 _idx;
            for(uint256 i=0; i < entityAdmins.length; i++) {
                if(entityAdminDetails[entityAdmins[i]].isActive) {
                    _entAdmins[_idx] = entityAdmins[i];
                    _idx++;
                }
            }
        } else {
            _entAdmins = entityAdmins;
        }
    }

    function getAllBartenders(bool _onlyActive) public view returns(address[] memory _bartenders) {
        if(_onlyActive) {

            uint count;
            for (uint256 i = 0; i < bartenders.length; i++) {
                if (bartenderDetails[bartenders[i]].isActive) {
                    count++;
                }
            }
            
            _bartenders = new address[](count);
            uint256 _idx;
            for(uint256 i=0; i < bartenders.length; i++) {
                if(bartenderDetails[bartenders[i]].isActive) {
                    _bartenders[_idx] = bartenders[i];
                    _idx++;
                }
            }
        } else {
            _bartenders = bartenders;
        }
    }

    function getLocationDetails() external view returns(string[] memory, uint256) {
        return (area.points, area.radius);
    }

    /**
     * @notice Allows the administrator to change user contract for Entity Operation
     * @param _newUserContract address
    */
    function setUserContract(address _newUserContract) external onlyGovernor {
        userContract = _newUserContract;

        emit UserContractSet(_newUserContract);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../admin/Entity.sol";
import "../access/DAOAccessControlled.sol";
import "../../interfaces/admin/IEntityRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EntityRegistry is IEntityRegistry, Initializable, DAOAccessControlled {

    // List of all entities
    address[] public allEntities;

    // Used to check for existence of an entity in the DAO eco-system
    mapping(address => bool) public entityExists;

    function initialize(address _authority) public initializer {

        DAOAccessControlled._setAuthority(_authority);
        
    }

    function pushEntityAddress(address _entity) external onlyGovernor  {
        require(entityExists[_entity]==false,"Entity already exists");
        allEntities.push(_entity);
        entityExists[_entity] =  true;
        emit CreatedEntity(_entity);
    }

    function removeEntityAddress(address _entity) external onlyGovernor  {
        require(entityExists[_entity] == true, "INVALID ENTITY");

        for(uint256 i = 0; i < allEntities.length; i++) {
            if (allEntities[i] == _entity) {
                if(i < allEntities.length-1) {
                    allEntities[i] = allEntities[allEntities.length-1];
                }
                allEntities.pop();
                break;
            }
        }
        entityExists[_entity] = false;        
    }

    function isDAOEntity(address _entity) public view returns(bool) {
        return entityExists[_entity];
    }

    function getAllEntities(bool _onlyActive) public view returns(address[] memory _entities) {

        address[] memory _ents = allEntities;

        uint256 count;
        for (uint256 i = 0; i < _ents.length; i++) {
            if (!_onlyActive || IEntity(_ents[i]).getEntityData().isActive) {
                count++;
            }
        }
        
        _entities = new address[](count);
        uint256 _idx;
        for(uint256 i=0; i < _ents.length; i++) {
            if(!_onlyActive || IEntity(_ents[i]).getEntityData().isActive) {
                _entities[_idx] = _ents[i];
                _idx++;
            }
        }
    }

    function testUpgrade() public pure returns(uint256) {
        return 0;
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

interface IEntityRegistry {

    /* ========== EVENTS ========== */
    event CreatedEntity(address _entity);

    function pushEntityAddress(address _entity) external;

    function removeEntityAddress(address _entity) external;

    function isDAOEntity(address _entity) external view returns(bool);

    function getAllEntities(bool _onlyActive) external view returns(address[] memory);

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

    struct UserAttributes {
        uint256 id;
        string name;
        address wallet;
        string avatarURI;
        string dataURI;
        address[] adminAt; // List of entities where user is an Admin
        address[] bartenderAt; // List of entities where user is a bartender

        // Storage Gap
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

}