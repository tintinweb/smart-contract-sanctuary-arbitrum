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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../access/DAOAccessControlled.sol";
import "../../interfaces/user/IUser.sol";
import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/tokens/ILoot8Token.sol";
import "../../interfaces/misc/IDispatcher.sol";
import "../../interfaces/collectibles/ICollectible.sol";
import "../../interfaces/factories/IPassportFactory.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Dispatcher is IDispatcher,Initializable, DAOAccessControlled {
    
    using Counters for Counters.Counter;

    // Unique IDs for new reservations
    Counters.Counter private reservationIds;

    // Unique IDs for new offers
    Counters.Counter private offerContractsIds;

    // Time after which a new reservation expires(Seconds)
    uint256 public reservationsExpiry; 
    address public loot8Token;
    address public daoWallet;
    address public priceCalculator;
    address public userContract;
    address public passportFactory;

    // Earliest non-expired reservation, for gas optimization
    uint256 earliestNonExpiredIndex;

    // List of all offers
    address[] public allOffers;

    // Offer/Event wise context for each offer/event
    mapping(address => OfferContext) public offerContext;

    // Mapping ReservationID => Reservation Details
    mapping(uint256 => Reservation) public reservations;

    function initialize(
        address _authority,
        address _loot8Token,
        address _daoWallet,
        address _priceCalculator,
        uint256 _reservationsExpiry,
        address _userContract,
        address _passportFactory
    ) public initializer {

        DAOAccessControlled._setAuthority(_authority);
        loot8Token = _loot8Token;
        daoWallet = _daoWallet;
        priceCalculator = _priceCalculator;
        reservationsExpiry = _reservationsExpiry;

        // Start ids with 1 as 0 is for existence check
        offerContractsIds.increment();
        reservationIds.increment();
        earliestNonExpiredIndex = reservationIds.current();
        userContract = _userContract;
        passportFactory = _passportFactory;
    }

    function addOfferWithContext(address _offer, uint256 _maxPurchase, uint256 _expiry, bool _transferable) external {
        
        require(msg.sender == address(_offer), 'UNAUTHORIZED');

        OfferContext storage oc = offerContext[_offer];
        oc.id = offerContractsIds.current();
        oc.expiry = _expiry;
        oc.transferable = _transferable;
        oc.totalPurchases = 0;
        oc.activeReservationsCount = 0;
        oc.maxPurchase = _maxPurchase;

        allOffers.push(_offer);

        offerContractsIds.increment();
    }

    /**
     * @notice Called to create a reservation when a patron places an order using their mobile app
     * @param _offer address Address of the offer contract for which a reservation needs to be made
     * @param _patron address
     * @param _cashPayment bool True if cash will be used as mode of payment
     * @return newReservationId Unique Reservation Id for the newly created reservation
    */
    function addReservation(
        address _offer,
        address _patron, 
        bool _cashPayment
    ) external onlyForwarder
    returns(uint256 newReservationId) {

        uint256 _patronRecentReservation = offerContext[_offer].patronRecentReservation[_patron];

        require(
            reservations[_patronRecentReservation].fulfilled ||
            reservations[_patronRecentReservation].cancelled || 
            reservations[_patronRecentReservation].expiry <= block.timestamp, 'PATRON HAS AN ACTIVE RESERVATION');

        require(ICollectible(_offer).getCollectibleData().isActive, "OFFER IS NOT ACTIVE");
        this.updateActiveReservationsCount();
        
        require((offerContext[_offer].maxPurchase == 0 || (offerContext[_offer].totalPurchases + offerContext[_offer].activeReservationsCount) < offerContext[_offer].maxPurchase), 'MAX PURCHASE EXCEEDED');
        
        offerContext[_offer].activeReservationsCount++;

        uint256 _expiry = block.timestamp + reservationsExpiry;

        newReservationId = reservationIds.current();

        uint256[20] memory __gap;
        // Create reservation
        reservations[newReservationId] = Reservation({
            id: newReservationId,
            patron: _patron,
            expiry: _expiry,
            offer: _offer,
            offerId: 0,
            cashPayment: _cashPayment,
            data: "",
            cancelled: false,
            fulfilled: false,
            __gap: __gap
        });

        offerContext[_offer].patronRecentReservation[_patron] = newReservationId;

        offerContext[_offer].reservations.push(newReservationId);

        reservationIds.increment();

        address _entity = ICollectible(_offer).getCollectibleData().entity;

        emit ReservationAdded(_entity, _offer, _patron, newReservationId, _expiry, _cashPayment);
    }

    /**
     * @notice Called by bartender or patron to cancel a reservation
     * @param _reservationId uint256
    */
    function cancelReservation(uint256 _reservationId) external {
        
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');

        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectible(_offer).getCollectibleData().entity;
        require(
            IEntity(_entity).getBartenderDetails(_msgSender()).isActive || 
            _msgSender() == reservations[_reservationId].patron, "UNAUTHORIZED"
        );

        reservations[_reservationId].cancelled = true;
        offerContext[_offer].activeReservationsCount--;
        
        // TODO: Burn collectible if minted
        emit ReservationCancelled(_entity, _offer, _reservationId);
    }

    /**
     * @notice Mints an NFT for a reservation and sets the offer Id in Reservation details
     * @param _reservationId uint256
     * @param _data bytes Meta data for the reservation
     * @return offerId uint256 Token Id for newly minted NFT
    */
    function reservationAddTxnInfoMint(uint256 _reservationId, bytes memory _data) external returns(uint256 offerId) {
        require(_msgSender() == address(this) || isTrustedForwarder(msg.sender), "UNAUTHORIZED");
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');

        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectible(_offer).getCollectibleData().entity;
        offerId = ICollectible(_offer).mint(reservations[_reservationId].patron, offerContext[_offer].expiry, offerContext[_offer].transferable);
        emit TokenMintedForReservation(_entity, _offer, _reservationId, offerId);
        
        reservations[_reservationId].offerId = offerId;
        reservations[_reservationId].data = _data;
    }

    function getReservationDetails(uint256 _reservationId) public view returns(Reservation memory){
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        return reservations[_reservationId];
    }

    function getPatronRecentReservationForOffer(address _patron, address _offer) public view returns(uint256) {
        return offerContext[_offer].patronRecentReservation[_patron];
    }

    /**
     * @notice Maintenance function to cancel expired reservations and update active reservation counts
    */
    function updateActiveReservationsCount() public {
        uint256 earliestIdx = 0;

        if (earliestNonExpiredIndex == 0) earliestNonExpiredIndex = 1;
        for (uint256 i = earliestNonExpiredIndex; i < reservationIds.current(); i++) {
            Reservation storage reservation = reservations[i];
            
            if (reservation.offerId == 0) { // we cannot cancel reservations if offer token minted
                if (reservation.expiry <= block.timestamp && !reservation.cancelled) {
                    reservation.cancelled = true;
                    if(offerContext[reservation.offer].activeReservationsCount > 0) {
                        offerContext[reservation.offer].activeReservationsCount--;
                    }
                }
                else if (earliestIdx == 0) {
                    earliestIdx = i;
                }
            }
            
            if ((reservation.cancelled || reservation.fulfilled || reservation.expiry <= block.timestamp) && earliestIdx == i-1) {
                earliestIdx = i;
            }
        }

        if (earliestIdx > 0) {
            earliestNonExpiredIndex = earliestIdx;
        }
    }

    function dispatch (
        uint256 _reservationId,
        bytes memory _data
    ) public {

        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        require(!reservations[_reservationId].fulfilled, "DISPATCHED RESERVATION");
        require(!reservations[_reservationId].cancelled, "CANCELLED RESERVATION");

        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectible(_offer).getCollectibleData().entity;

        require(offerContext[_offer].id != 0, "No Such Offer");
        require(IEntity(_entity).getBartenderDetails(_msgSender()).isActive, "UNAUTHORIZED");

        address patron = reservations[_reservationId].patron;
        
        require(offerContext[_offer].patronRecentReservation[patron] == _reservationId, 'RESERVATION NOT RECENT OR ACTIVE');
        require(!reservations[_reservationId].cancelled, 'CANCELLED RESERVATION');
        require(reservations[_reservationId].expiry > block.timestamp, 'RESERVATION EXPIRED');

        uint256 _offerId;

        // Mint NFT if not already minted
        if(reservations[_reservationId].offerId == 0) {
            _offerId = this.reservationAddTxnInfoMint(_reservationId, _data);
        }

        // Fulfill the reservation
        _fulFillReservation(_reservationId);

        emit OrderDispatched(_entity, _offer, _reservationId, _offerId);
    }

    /**
     * @notice Allows the administrator to change expiry for reservations
     * @param _newExpiry uint256 New expiry timestamp
    */
    function setReservationExpiry(uint256 _newExpiry) external onlyGovernor {
        reservationsExpiry = _newExpiry;

        emit ReservationsExpirySet(_newExpiry);
    }

    /**
     * @notice Allows the administrator to change user contract for registrations
     * @param _newUserContract address
    */
    function setUserContract(address _newUserContract) external onlyGovernor {
        userContract = _newUserContract;

        emit UserContractSet(_newUserContract);
    }

    /**
     * @notice Allows the administrator to change passport factory contract for passports minting
     * @param _newPassportFactory address Address of the new passport factory contract
    */
    function setPassportFactory(address _newPassportFactory) external onlyGovernor {
        passportFactory = _newPassportFactory;

        emit PassportFactorySet(_newPassportFactory);
    }

    /**
     * @notice Called to complete a reservation when order is dispatched
     * @param _reservationId uint256
    */
    function _fulFillReservation(uint256 _reservationId) internal {
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        reservations[_reservationId].fulfilled = true;

        address offer = reservations[_reservationId].offer;
        offerContext[offer].activeReservationsCount--;
        offerContext[offer].totalPurchases++;

        uint256 _offerId = reservations[_reservationId].offerId;
        ICollectible(offer).setRedemption(_offerId);

        uint256 rewards = ICollectible(offer).getCollectibleData().rewards;

        _mintRewards(_reservationId, rewards);

        _creditRewardsToPassport(_reservationId, rewards);

        address _entity = ICollectible(offer).getCollectibleData().entity;

        emit ReservationFulfilled(_entity, offer, reservations[_reservationId].patron, _reservationId, _offerId);
    }
    
    function _getOfferPassport(address _offer) internal returns(address) {
        
        address[] memory _collectibles = ICollectible(_offer).getAllLinkedCollectibles();

        for(uint256 i = 0; i < _collectibles.length; i++) {
            if(
                ICollectible(_collectibles[i]).collectibleType() == 
                ICollectible.CollectibleType.PASSPORT
            ) {
                return _collectibles[i];
            }
        }

        return address(0);

    }

    function _mintRewards(uint256 _reservationId, uint256 _rewards) internal {
        address offer = reservations[_reservationId].offer;
        address entity = ICollectible(offer).getCollectibleData().entity;

        ILoot8Token(loot8Token).mint(reservations[_reservationId].patron, _rewards);
        ILoot8Token(loot8Token).mint(daoWallet, _rewards);
        ILoot8Token(loot8Token).mint(entity, _rewards);
    }

    function _creditRewardsToPassport(uint256 _reservationId, uint256 _rewards) internal {
        address _passport = _getOfferPassport(reservations[_reservationId].offer);
        if(_passport != address(0)) {
            ICollectible(_passport).creditRewards(reservations[_reservationId].patron, _rewards);
        }
    }

    function registerUser(
        string memory _name,
        string memory _avatarURI,
        string memory _dataURI,
        uint256 _defaultPassportsExpiry, 
        bool _defaultPassportsTransferable
    ) external onlyForwarder returns (uint256 userId) {
        
        userId = IUser(userContract).register(_name, _msgSender(), _avatarURI, _dataURI);

        // Mint all available passports to the user
        _mintAvailablePassports(_msgSender(), _defaultPassportsExpiry, _defaultPassportsTransferable);
    }   

    function mintAvailablePassports(address _patron, uint256 _expiry, bool _transferable) external onlyForwarder {        
        _mintAvailablePassports(_patron, _expiry, _transferable);
    }

    function _mintAvailablePassports(address _patron, uint256 _expiry, bool _transferable) internal {
        
        address[] memory allPassports = IPassportFactory(passportFactory).getAllPassports();

        for(uint256 i = 0; i < allPassports.length; i++) {

            (string[] memory points, uint256 radius) = ICollectible(allPassports[i]).getLocationDetails();

            bool isActive = ICollectible(allPassports[i]).getCollectibleData().isActive;
          
            if(points.length == 0 && radius == 0 && isActive) {
                uint256 balance = ICollectible(allPassports[i]).balanceOf(_patron);
                if(balance == 0) {
                    ICollectible(allPassports[i]).mint(_patron, _expiry, _transferable);
                }
            }
        }
    }

    function mintLinkedCollectiblesForHolders(address _collectible, uint256 _expiry, bool _transferable) external onlyForwarder {
        
        require(ICollectible(_collectible).getCollectibleData().isActive, "Collectible is retired");

        IUser.UserAttributes[] memory allUsers = IUser(userContract).getAllUsers(false);

        for(uint256 i=0; i < allUsers.length; i++) {
            this.mintLinked(_collectible, allUsers[i].wallet, _expiry, _transferable);
        }
    }

    /**
     * @notice Mints collectibles linked to a collectible
     * @notice Minting conditions:
     * @notice The patron should have a non-zero balance of the collectible
     * @notice The linked collectible should be active
     * @notice The linked collectible should have the mintWithLinked boolean flag set to true for itself
     * @notice The patron should have a zero balance for the linked collectible
     * @param _collectible uint256 Collectible for which linked collectibles are to be minted
     * @param _patron uint256 Mint to the same patron to which the collectible was minted
     * @param _expiry uint256 Inherit expiry from the collectible itself or pass custom
     * @param _transferable uint256 Inherit transfer characteristics from the collectible itself or pass custom
    */
    function mintLinked( address _collectible, address _patron, uint256 _expiry, bool _transferable) public virtual override {

        require(
            _msgSender() == address(this) || 
            _msgSender() == _collectible || 
            isTrustedForwarder(msg.sender), "UNAUTHORIZED"
        );
        
        // Check if collectible is active
        require(ICollectible(_collectible).getCollectibleData().isActive, "Collectible is retired");
        
        address[] memory linkedCollectibles = ICollectible(_collectible).getAllLinkedCollectibles();

        for(uint256 i=0; i < linkedCollectibles.length; i++) {
            ICollectible linkedCollectibe = ICollectible(linkedCollectibles[i]);
            if(
                ICollectible(_collectible).balanceOf(_patron) > 0 &&
                linkedCollectibe.getCollectibleData().isActive &&
                linkedCollectibe.getCollectibleData().mintWithLinked &&
                linkedCollectibe.balanceOf(_patron) == 0
            ) {
                linkedCollectibe.mint(_patron, _expiry, _transferable);
            }
        }
    }

    function getAllOffers() public view returns(address[] memory) {
        return allOffers;
    }

    function getNonExpiredIndex() public view returns(uint256) {
        return earliestNonExpiredIndex;
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

    struct Authorities {
        address governor;
        address policy;
        address admin;
        address forwarder;
        address dispatcher;
    }

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
    event CollectibleAdded(address _entity, address _collectible);

    event CollectibleWhitelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);
    event CollectibleDelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);

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

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;

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

     function updateEntityDataURI(
        string memory _dataURI
    ) external;

    function addCollectibleToEntity(address _collectible) external;

    function addEntityAdmin(address _entAdmin) external;

    function addBartender(address _bartender) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function whitelistCollectible(address _source, uint256 _chainId) external;

    function delistCollectible(address _source, uint256 _chainId) external;

    function getEntityData() external view returns(EntityData memory);

    function getAllEntityAdmins() external view returns(address[] memory);

    function getAllBartenders() external view returns(address[] memory);

    function getAllCollectibles() external view returns(address[] memory);
    
    function getAllWhitelistedCollectibles() external view returns(ContractDetails[] memory);

    function getLocationDetails() external view returns(string[] memory, uint256);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface ICollectible is ILocationBased {

    event CollectibleMinted (
        uint256 _collectibleId,
        address indexed _patron,
        uint256 _expiry,
        bool _transferable,
        string _tokenURI
    );

    event CollectibleToggled(uint256 _collectibleId, bool _status);

    event CollectiblesLinked(address _collectible1, address _collectible2);

    event CollectiblesDelinked(address _collectible1, address _collectible2);

    event CreditRewardsToCollectible(uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event BurnRewardsFromCollectible(uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event RetiredCollectible(address _collectible);

    event Visited(uint256 _collectibleId);

    event FriendVisited(uint256 _collectibleId);

    event DataURIUpdated(address _collectible, string _oldDataURI, string _newDataURI);

    event SentNFT(address indexed _patron, uint16 _destinationChainId, uint256 _collectibleId);

    event ReceivedNFT(address indexed _patron, uint16 _srcChainId, uint256 _collectibleId);

    event MintWithLinkedToggled(bool _mintWithLinked);

    enum CollectibleType {
        PASSPORT,
        OFFER,
        DIGITALCOLLECTIBLE,
        BADGE,
        EVENT
    }

    struct CollectibleData {
        // The Data URI where details for collectible will be stored in a JSON file
        string dataURI;
        string name;
        string symbol;

        // Rewards that this collectible is eligible for
        uint256 rewards;

        // A collectible may optionally be linked to an entity
        // If its not then this will be address(0)
        address entity;
        bool isActive; // Flag to indicate if this collectible is active or expired

        // Flag that checks if a collectible should be minted when a collectible which it is linked to is minted
        // Eg: Offers/Events that should be airdropped along with passport for them
        // If true for a linked collectible, mintLinked can be called by the
        // dispatcher contract to mint collectibles linked to it
        bool mintWithLinked;
    }

    struct CollectibleDetails {
        uint256 id;
        uint256 mintTime; // timestamp
        uint256 expiry; // timestamp
        bool isActive;
        bool transferable;
        int256 rewardBalance; // used for passports only
        uint256 visits; // // used for passports only
        uint256 friendVisits; // used for passports only
        // A flag indicating whether the collectible was redeemed
        // This can be useful in scenarios such as cancellation of orders
        // where the the NFT minted to patron is supposed to be burnt/demarcated
        // in some way when the payment is reversed to patron
        bool redeemed;
    }

    function mint (
        address _patron,
        uint256 _expiry,
        bool _transferable
    ) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    // Activates/deactivates the collectible
    function toggle(uint256 _collectibleId) external returns(bool _status);

    function retire() external;

    function creditRewards(address _patron, uint256 _amount) external;

    function debitRewards(address _patron, uint256 _amount) external;

    // function addVisit(uint256 _collectibleId) external;

    // function addFriendsVisit(uint256 _collectibleId) external;

    function toggleMintWithLinked() external;

    function isRetired(address _patron) external view returns(bool);

    function getPatronNFT(address _patron) external view returns(uint256);

    function getNFTDetails(uint256 _nftId) external view returns(CollectibleDetails memory);

    function linkCollectible(address _collectible) external;
    
    function delinkCollectible(address _collectible) external;
    
    function ownerOf(uint256 tokenId) external view returns(address);

    function setRedemption(uint256 _offerId) external;

    function getCollectibleData() external view returns(CollectibleData memory);

    function getAllLinkedCollectibles() external view returns (address[] memory);

    function collectibleType() external returns(CollectibleType);

    function getLocationDetails() external view returns(string[] memory, uint256);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPassportFactory {

    /*************** EVENTS ***************/
    event CreatedPassport(address _entity, address _passport);
    event CurrentCreationCodeUpdated(address _entity, bytes _creationCode);
    event CurrentParamsUpdated(address _entity, bytes _params);
    
    struct PassportCreationConfig {
        bytes creationCode;
        bytes params;
        // Storage Gap
        bytes[40] __gap;
    }

    function createPassport(address _entity) external  returns (address _passport);

    function isDAOPassport(address _passport) external view returns(bool);

    function getPassportsForEntity(address _entity) external view returns(address[] memory);

    function setCurrentCreationCodeForEntity(address _entity, bytes memory _creationCode) external;

    function setCurrentParamsForEntity(address _entity, bytes memory _params) external;

    function getCurrentCreationConfigForEntity(address _entity) external view returns(PassportCreationConfig memory);

    function getAllPassports() external view returns(address[] memory);
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

interface IDispatcher {

    event OrderDispatched(address indexed _entity, address indexed _offer, uint256 indexed _reservationId, uint256 _offerId);
    event ReservationAdded(address indexed _entity, address indexed _offer, address indexed _patron, uint256 _newReservationId, uint256 _expiry, bool  _cashPayment);
    event ReservationFulfilled(address _entity, address indexed _offer, address indexed _patron, uint256 indexed _reservationId, uint256 _offerId);
    event ReservationCancelled(address _entity, address indexed _offer, uint256 indexed _reservationId);
    event ReservationsExpirySet(uint256 _newExpiry);
    event TokenMintedForReservation(address indexed _entity, address indexed _offer, uint256 indexed _reservationId, uint256 _offerId);
    event UserContractSet(address _newUserContract);
    event PassportFactorySet(address _newPassportFactory);

    struct OfferContext {
        uint256 id;
        uint256 expiry;
        bool transferable;
        uint256 totalPurchases;
        uint256 activeReservationsCount;
        uint256 maxPurchase;
        uint256[] reservations;
        mapping(address => uint256) patronRecentReservation;

        // Storage Gap
        uint256[20] __gap;
    }

    struct Reservation {
        uint256 id;
        address patron;
        uint256 expiry;
        address offer;
        uint256 offerId; // Offer NFT Token Id if NFT was minted for this reservation
        bool cashPayment; // Flag indicating if the reservation will be paid for in cash or online
        bool cancelled;
        bool fulfilled; // Flag to indicate if the order was fulfilled
        bytes data;

        // Storage Gap
        uint256[20] __gap;
    }

    function addOfferWithContext(address _offer, uint256 _maxPurchase, uint256 _expiry, bool _transferable) external;

    function addReservation(
        address _offer,
        address _patron, 
        bool _cashPayment
    ) external returns(uint256 newReservationId);

    function cancelReservation(uint256 _reservationId) external;

    function reservationAddTxnInfoMint(uint256 _reservationId, bytes memory _data) external returns(uint256 offerId);

    function getReservationDetails(uint256 _reservationId) external view returns(Reservation memory);

    function getPatronRecentReservationForOffer(address _patron, address _offer) external view returns(uint256);

    function updateActiveReservationsCount() external;

    function setReservationExpiry(uint256 _newExpiry) external;

    function dispatch (
        uint256 _reservationId,
        bytes memory _data
    ) external;

    function registerUser(
        string memory _name,
        string memory _avatarURI,
        string memory _dataURI, 
        uint256 _defaultPassportsExpiry, 
        bool _defaultPassportsTransferable
    ) external returns (uint256 userId);

    function mintAvailablePassports(address _patron, uint256 _expiry, bool _transferable) external;

    function mintLinkedCollectiblesForHolders(address _collectible, uint256 _expiry, bool _transferable) external; 

    function mintLinked( address _collectible, address _patron, uint256 _expiry, bool _transferable) external;

    function getAllOffers() external view returns(address[] memory);

    function priceCalculator() external view returns(address);
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILoot8Token {
    function mint(address account_, uint256 amount_) external;
    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IUser {

    /* ========== EVENTS ========== */
    event UserCreated(address indexed _walletAddress, uint256 indexed _userId, string _name);

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

        // Storage Gap
        uint256[20] __gap;
    }

    function register(string memory _name, address walletAddress, string memory _avatarURI, string memory _dataURI) external returns (uint256);

    function changeName(string memory _name) external;
    
    function getAllUsers(bool _includeBanned) external view returns(UserAttributes[] memory _users);

    function getBannedUsers() external view returns(UserAttributes[] memory _users);
}