// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== Orchestrator ========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/Puppet

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {Auth, Authority} from "@solmate/auth/Auth.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import {IRouteFactory} from "./interfaces/IRouteFactory.sol";

import "./Base.sol";

/// @title Orchestrator
/// @author johnnyonline (Puppet Finance) https://github.com/johnnyonline
/// @notice This contract contains the logic and storage for managing routes and puppets
contract Orchestrator is Auth, Base, IOrchestrator {

    using SafeERC20 for IERC20;
    using Address for address payable;

    struct RouteInfo {
        address route;
        bool isRegistered;
        EnumerableSet.AddressSet puppets;
        RouteType routeType;
    }

    struct PuppetInfo {
        mapping(bytes32 => uint256) throttleLimits; // routeType => throttle limit (in seconds)
        mapping(bytes32 => uint256) lastPositionOpenedTimestamp; // routeType => timestamp
        mapping(address => uint256) depositAccount; // collateralToken => balance
        EnumerableMap.AddressToUintMap allowances; // route => allowance percentage
    }

    // settings
    address public routeFactory;
    address private _keeper;

    bool private _paused;

    bytes32 private _referralCode;

    GMXInfo private _gmxInfo;

    // routes info
    mapping(address => bool) public isRoute; // Route => isRoute
    mapping(bytes32 => RouteType) public routeType; // routeTypeKey => RouteType

    mapping(bytes32 => RouteInfo) private _routeInfo; // routeKey => RouteInfo

    address[] private _routes;

    // puppets info
    mapping(address => PuppetInfo) private _puppetInfo;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _authority The Authority contract instance
    /// @param _routeFactory The RouteFactory contract address
    /// @param _keeperAddr The address of the keeper
    /// @param _refCode The GMX referral code
    /// @param _gmx The GMX contract addresses
    constructor(Authority _authority, address _routeFactory, address _keeperAddr, bytes32 _refCode, bytes memory _gmx) Auth(address(0), _authority) {
        routeFactory = _routeFactory;
        _keeper = _keeperAddr;

        (_gmxInfo.gmxRouter, _gmxInfo.gmxVault, _gmxInfo.gmxPositionRouter) = abi.decode(_gmx, (address, address, address));

        _referralCode = _refCode;
    }

    // ============================================================================================
    // Modifiers
    // ============================================================================================

    /// @notice Modifier that ensures the caller is a route
    modifier onlyRoute() {
        if (!isRoute[msg.sender]) revert NotRoute();
        _;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // global

    /// @inheritdoc IOrchestrator
    function keeper() external view returns (address) {
        return _keeper;
    }

    /// @inheritdoc IOrchestrator
    function referralCode() external view returns (bytes32) {
        return _referralCode;
    }

    /// @inheritdoc IOrchestrator
    function routes() external view returns (address[] memory) {
        return _routes;
    }

    /// @inheritdoc IOrchestrator
    function paused() external view returns (bool) {
        return _paused;
    }

    // route

    /// @inheritdoc IOrchestrator
    function getRouteTypeKey(address _collateralToken, address _indexToken, bool _isLong) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_collateralToken, _indexToken, _isLong));
    }

    /// @inheritdoc IOrchestrator
    function getRouteKey(address _trader, bytes32 _routeTypeKey) public view returns (bytes32) {
        address _collateralToken = routeType[_routeTypeKey].collateralToken;
        address _indexToken = routeType[_routeTypeKey].indexToken;
        bool _isLong = routeType[_routeTypeKey].isLong;

        return keccak256(abi.encodePacked(_trader, _collateralToken, _indexToken, _isLong));
    }

    /// @inheritdoc IOrchestrator
    function getRoute(bytes32 _routeKey) external view returns (address) {
        return _routeInfo[_routeKey].route;
    }

    /// @inheritdoc IOrchestrator
    function getRoute(address _trader, address _collateralToken, address _indexToken, bool _isLong) external view returns (address) {
        bytes32 _routeTypeKey = getRouteTypeKey(_collateralToken, _indexToken, _isLong);
        bytes32 _routeKey = getRouteKey(_trader, _routeTypeKey);

        return _routeInfo[_routeKey].route;
    }

    /// @inheritdoc IOrchestrator
    function subscribedPuppets(bytes32 _routeKey) external view returns (address[] memory _puppets) {
        EnumerableSet.AddressSet storage _puppetsSet = _routeInfo[_routeKey].puppets;
        _puppets = new address[](EnumerableSet.length(_puppetsSet));

        for (uint256 i = 0; i < EnumerableSet.length(_puppetsSet); i++) {
            _puppets[i] = EnumerableSet.at(_puppetsSet, i);
        }
    }

    // puppet

    /// @inheritdoc IOrchestrator
    function puppetSubscriptions(address _puppet) external view returns (address[] memory _subscriptions) {
        EnumerableMap.AddressToUintMap storage _allowances = _puppetInfo[_puppet].allowances;

        uint256 _subscriptionCount = EnumerableMap.length(_allowances);
        _subscriptions = new address[](_subscriptionCount);
        for (uint256 i = 0; i < _subscriptionCount; i++) {
            (_subscriptions[i], ) = EnumerableMap.at(_allowances, i);
        }
    }

    /// @inheritdoc IOrchestrator
    function puppetAllowancePercentage(address _puppet, address _route) external view returns (uint256 _allowance) {
        return EnumerableMap.get(_puppetInfo[_puppet].allowances, _route);
    }

    /// @inheritdoc IOrchestrator
    function puppetAccountBalance(address _puppet, address _asset) external view returns (uint256) {
        return _puppetInfo[_puppet].depositAccount[_asset];
    }

    /// @inheritdoc IOrchestrator
    function puppetThrottleLimit(address _puppet, bytes32 _routeType) external view returns (uint256) {
        return _puppetInfo[_puppet].throttleLimits[_routeType];
    }

    /// @inheritdoc IOrchestrator
    function lastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external view returns (uint256) {
        return _puppetInfo[_puppet].lastPositionOpenedTimestamp[_routeType];
    }

    /// @inheritdoc IOrchestrator
    function isBelowThrottleLimit(address _puppet, bytes32 _routeType) external view returns (bool) {
        return (block.timestamp - _puppetInfo[_puppet].lastPositionOpenedTimestamp[_routeType]) >= _puppetInfo[_puppet].throttleLimits[_routeType];
    }

    // gmx

    /// @inheritdoc IOrchestrator
    function gmxRouter() external view returns (address) {
        return _gmxInfo.gmxRouter;
    }

    /// @inheritdoc IOrchestrator
    function gmxPositionRouter() external view returns (address) {
        return _gmxInfo.gmxPositionRouter;
    }

    /// @inheritdoc IOrchestrator
    function gmxVault() external view returns (address) {
        return _gmxInfo.gmxVault;
    }

    // ============================================================================================
    // Trader Function
    // ============================================================================================

    /// @inheritdoc IOrchestrator
    // slither-disable-next-line reentrancy-no-eth
    function registerRoute(address _collateralToken, address _indexToken, bool _isLong) public nonReentrant returns (bytes32 _routeKey) {
        if (_collateralToken == address(0) || _indexToken == address(0)) revert ZeroAddress();

        bytes32 _routeTypeKey = getRouteTypeKey(_collateralToken, _indexToken, _isLong);
        if (!routeType[_routeTypeKey].isRegistered) revert RouteTypeNotRegistered();

        _routeKey = getRouteKey(msg.sender, _routeTypeKey);
        if (_routeInfo[_routeKey].isRegistered) revert RouteAlreadyRegistered();

        address _routeAddr = IRouteFactory(routeFactory).createRoute(address(this), msg.sender, _collateralToken, _indexToken, _isLong);

        RouteType memory _routeType = RouteType({
            collateralToken: _collateralToken,
            indexToken: _indexToken,
            isLong: _isLong,
            isRegistered: true
        });

        RouteInfo storage _route = _routeInfo[_routeKey];

        _route.route = _routeAddr;
        _route.isRegistered = true;
        _route.routeType = _routeType;

        isRoute[_routeAddr] = true;
        _routes.push(_routeAddr);

        emit RegisterRoute(msg.sender, _routeAddr, _routeTypeKey);
    }

    /// @inheritdoc IOrchestrator
    function registerRouteAndRequestPosition(
        IRoute.AdjustPositionParams memory _adjustPositionParams,
        IRoute.SwapParams memory _swapParams,
        uint256 _executionFee,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external payable returns (bytes32 _routeKey, bytes32 _requestKey) {
        _routeKey = registerRoute(_collateralToken, _indexToken, _isLong);
        _requestKey = requestPosition(_adjustPositionParams, _swapParams, getRouteTypeKey(_collateralToken, _indexToken, _isLong), _executionFee, true);
    }

    /// @inheritdoc IOrchestrator
    function requestPosition(
        IRoute.AdjustPositionParams memory _adjustPositionParams,
        IRoute.SwapParams memory _swapParams,
        bytes32 _routeTypeKey,
        uint256 _executionFee,
        bool _isIncrease
    ) public payable nonReentrant returns (bytes32 _requestKey) {
        address _route = _routeInfo[getRouteKey(msg.sender, _routeTypeKey)].route;
        if (_route == address(0)) revert RouteNotRegistered();

        _requestKey = IRoute(_route).requestPosition{ value: msg.value }(
            _adjustPositionParams,
            _swapParams,
            _executionFee,
            _isIncrease
        );

        emit RequestPositionAdjustment(msg.sender, _route, _routeTypeKey, _requestKey);
    }

    /// @inheritdoc IOrchestrator
    function approvePlugin(bytes32 _routeTypeKey) external {
        address _route = _routeInfo[getRouteKey(msg.sender, _routeTypeKey)].route;
        if (_route == address(0)) revert RouteNotRegistered();

        IRoute(_route).approvePlugin();

        emit ApprovePlugin(msg.sender, _routeTypeKey);
    }

    // ============================================================================================
    // Puppet Functions
    // ============================================================================================

    /// @inheritdoc IOrchestrator
    function deposit(uint256 _amount, address _asset, address _puppet) external payable nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (_puppet == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();
        if (msg.value > 0) {
            if (_amount != msg.value) revert InvalidAmount();
            if (_asset != _WETH) revert InvalidAsset();
        }

        _puppetInfo[_puppet].depositAccount[_asset] += _amount;

        if (msg.value > 0) {
            payable(_asset).functionCallWithValue(abi.encodeWithSignature("deposit()"), _amount);
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit Deposit(_amount, _asset, msg.sender, _puppet);
    }

    /// @inheritdoc IOrchestrator
    function withdraw(uint256 _amount, address _asset, address _receiver, bool _isETH) external nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (_receiver == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();
        if (_isETH && _asset != _WETH) revert InvalidAsset();
 
        _puppetInfo[msg.sender].depositAccount[_asset] -= _amount;

        if (_isETH) {
            IWETH(_asset).withdraw(_amount);
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_asset).safeTransfer(_receiver, _amount);
        }

        emit Withdraw(_amount, _asset, _receiver, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function updateRoutesSubscription(address[] memory _traders, uint256[] memory _allowances, bytes32 _routeTypeKey, bool _subscribe) external nonReentrant {
        if (_traders.length != _allowances.length) revert MismatchedInputArrays();

        address _puppet = msg.sender;
        for (uint256 i = 0; i < _traders.length; i++) {
            bytes32 _routeKey = getRouteKey(_traders[i], _routeTypeKey);
            RouteInfo storage _route = _routeInfo[_routeKey];

            if (!_route.isRegistered) revert RouteNotRegistered();
            if (IRoute(_route.route).isWaitingForCallback()) revert RouteWaitingForCallback();

            if (_subscribe) {
                if (_allowances[i] > _BASIS_POINTS_DIVISOR || _allowances[i] == 0) revert InvalidAllowancePercentage();

                EnumerableMap.set(_puppetInfo[_puppet].allowances, _route.route, _allowances[i]);

                if (!EnumerableSet.contains(_route.puppets, _puppet)) {
                    EnumerableSet.add(_route.puppets, _puppet);
                }
            } else {
                EnumerableMap.set(_puppetInfo[_puppet].allowances, _route.route, 0);

                if (EnumerableSet.contains(_route.puppets, _puppet)) {
                    EnumerableSet.remove(_route.puppets, _puppet);
                }
            }
        }

        emit Subscribe(_traders, _allowances, _puppet, _routeTypeKey, _subscribe);
    }

    /// @inheritdoc IOrchestrator
    function setThrottleLimit(uint256 _throttleLimit, bytes32 _routeType) external {
        _puppetInfo[msg.sender].throttleLimits[_routeType] = _throttleLimit;

        emit SetThrottleLimit(msg.sender, _routeType, _throttleLimit);
    }

    // ============================================================================================
    // Route Functions
    // ============================================================================================

    /// @inheritdoc IOrchestrator
    function debitPuppetAccount(uint256 _amount, address _asset, address _puppet) external onlyRoute {
        _puppetInfo[_puppet].depositAccount[_asset] -= _amount;

        emit DebitPuppet(_amount, _asset, _puppet, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function creditPuppetAccount(uint256 _amount, address _asset, address _puppet) external onlyRoute {
        _puppetInfo[_puppet].depositAccount[_asset] += _amount;

        emit CreditPuppet(_amount, _asset, _puppet, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function updateLastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external onlyRoute {
        _puppetInfo[_puppet].lastPositionOpenedTimestamp[_routeType] = block.timestamp;

        emit UpdateOpenTimestamp(_puppet, _routeType, block.timestamp);
    }

    /// @inheritdoc IOrchestrator
    function sendFunds(uint256 _amount, address _asset, address _receiver) external onlyRoute {
        IERC20(_asset).safeTransfer(_receiver, _amount);

        emit Send(_amount, _asset, _receiver, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function emitCallback(bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external onlyRoute {
        emit Callback(msg.sender, _requestKey, _isExecuted, _isIncrease);
    }

    // ============================================================================================
    // Authority Functions
    // ============================================================================================

    // called by keeper

    /// @inheritdoc IOrchestrator
    function decreaseSize(IRoute.AdjustPositionParams memory _adjustPositionParams, uint256 _executionFee, bytes32 _routeKey) external payable requiresAuth nonReentrant returns (bytes32 _requestKey) {
        address _route = _routeInfo[_routeKey].route;
        if (_route == address(0)) revert RouteNotRegistered();

        _requestKey = IRoute(_route).decreaseSize{ value: msg.value }(_adjustPositionParams, _executionFee);

        emit DecreaseSize(_requestKey, _routeKey);
    }

    /// @inheritdoc IOrchestrator
    function liquidate(bytes32 _routeKey) external requiresAuth nonReentrant {
        address _route = _routeInfo[_routeKey].route;
        if (_route == address(0)) revert RouteNotRegistered();

        IRoute(_route).liquidate();

        emit Liquidate(_routeKey);
    }

    // called by owner

    /// @inheritdoc IOrchestrator
    function rescueTokens(uint256 _amount, address _token, address _receiver) external requiresAuth nonReentrant {
        if (_token == address(0)) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }

        emit Rescue(_amount, _token, _receiver);
    }

    /// @inheritdoc IOrchestrator
    function rescueRouteTokens(uint256 _amount, address _token, address _receiver, address _route) external requiresAuth nonReentrant {
        IRoute(_route).rescueTokens(_amount, _token, _receiver);

        emit RouteRescue(_amount, _token, _receiver, _route);
    }

    /// @inheritdoc IOrchestrator
    function freezeRoute(address _route, bool _freeze) external requiresAuth nonReentrant {
        IRoute(_route).freeze(_freeze);

        emit FreezeRoute(_route, _freeze);
    }

    /// @inheritdoc IOrchestrator
    function setRouteType(address _collateral, address _index, bool _isLong) external requiresAuth nonReentrant {
        bytes32 _routeTypeKey = getRouteTypeKey(_collateral, _index, _isLong);
        routeType[_routeTypeKey] = RouteType(_collateral, _index, _isLong, true);

        emit SetRouteType(_routeTypeKey, _collateral, _index, _isLong);
    }

    /// @inheritdoc IOrchestrator
    function setGMXInfo(address _gmxRouter, address _gmxVault, address _gmxPositionRouter) external requiresAuth nonReentrant {
        GMXInfo storage _gmx = _gmxInfo;

        _gmx.gmxRouter = _gmxRouter;
        _gmx.gmxVault = _gmxVault;
        _gmx.gmxPositionRouter = _gmxPositionRouter;

        emit SetGMXUtils(_gmxRouter, _gmxVault, _gmxPositionRouter);
    }

    /// @inheritdoc IOrchestrator
    function setKeeper(address _keeperAddr) external requiresAuth nonReentrant {
        if (_keeperAddr == address(0)) revert ZeroAddress();

        _keeper = _keeperAddr;

        emit Keeper(_keeper);
    }

    /// @inheritdoc IOrchestrator
    function setReferralCode(bytes32 _refCode) external requiresAuth nonReentrant {
        if (_refCode == bytes32(0)) revert ZeroBytes32();

        _referralCode = _refCode;

        emit SetReferralCode(_refCode);
    }

    /// @inheritdoc IOrchestrator
    function setRouteFactory(address _factory) external requiresAuth nonReentrant {
        if (_factory == address(0)) revert ZeroAddress();

        routeFactory = _factory;

        emit SetRouteFactory(_factory);
    }

    /// @inheritdoc IOrchestrator
    function pause(bool _pause) external requiresAuth nonReentrant {
        _paused = _pause;

        emit Pause(_pause);
    }

    // ============================================================================================
    // Receive Function
    // ============================================================================================

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== IRouteFactory =======================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/Puppet

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {Authority} from "@solmate/auth/Auth.sol";

interface IRouteFactory {

    // ============================================================================================
    // External Functions
    // ============================================================================================

    /// @notice The ```createRoute``` is called on Orchestrator.registerRoute
    /// @param _orchestrator The address of the Orchestrator
    /// @param _trader The address of the Trader
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return _route The address of the new Route
    function createRoute(address _orchestrator, address _trader, address _collateralToken, address _indexToken, bool _isLong) external returns (address _route);

    // ============================================================================================
    // Events
    // ============================================================================================

    event RouteCreated(address indexed caller, address indexed route, address indexed orchestrator, address trader, address collateralToken, address indexToken, bool isLong);
}

// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ============================ Base ============================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/Puppet

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {IOrchestrator, IRoute} from "./interfaces/IOrchestrator.sol";

/// @title Base
/// @author johnnyonline (Puppet Finance) https://github.com/johnnyonline
/// @notice An abstract contract that contains common libraries, and constants
abstract contract Base is ReentrancyGuard {

    address internal constant _WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    uint256 internal constant _BASIS_POINTS_DIVISOR = 10000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

interface IWETH {
    
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== IOrchestrator =======================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/Puppet

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IRoute} from "./IRoute.sol";

interface IOrchestrator {

    struct RouteType {
        address collateralToken;
        address indexToken;
        bool isLong;
        bool isRegistered;
    }

    struct GMXInfo {
        address gmxRouter;
        address gmxVault;
        address gmxPositionRouter;
        address gmxReferralRebatesSender;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // global

    /// @notice The ```keeper``` function returns the address of the Keeper
    /// @return address The address of the Keeper
    function keeper() external view returns (address);

    /// @notice The ```referralCode``` function returns the referral code
    /// @return bytes32 The referral code
    function referralCode() external view returns (bytes32);

    /// @notice The ```routes``` function returns all the routes
    /// @return address The address array of all the routes
    function routes() external view returns (address[] memory);

    /// @notice The ```paused``` function returns the paused state
    /// @return bool The paused state
    function paused() external view returns (bool);

    // route

    /// @notice The ```getRouteTypeKey``` function returns RouteType key for a given Route attributes
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return bytes32 The RouteType key
    function getRouteTypeKey(address _collateralToken, address _indexToken, bool _isLong) external pure returns (bytes32);

    /// @notice The ```getRouteKey``` function returns the Route key for a given RouteType key and Trader address
    /// @param _trader The address of the Trader
    /// @param _routeTypeKey The RouteType key
    /// @return bytes32 The Route key
    function getRouteKey(address _trader, bytes32 _routeTypeKey) external view returns (bytes32);

    /// @notice The ```getRoute``` function returns the Route address for a given Route key
    /// @param _routeKey The Route key
    /// @return address The Route address
    function getRoute(bytes32 _routeKey) external view returns (address);

    /// @notice The ```getRoute``` function returns the Route address for a given Route attributes and Trader address
    /// @param _trader The address of the Trader
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return address The Route address
    function getRoute(address _trader, address _collateralToken, address _indexToken, bool _isLong) external view returns (address);

    /// @notice The ```subscribedPuppets``` function returns all the subscribed puppets for a given Route key
    /// @notice Those puppets may not be subscribed to the current Route's position
    /// @param _routeKey The Route key
    /// @return _puppets The address array of all the subscribed puppets
    function subscribedPuppets(bytes32 _routeKey) external view returns (address[] memory _puppets);

    // puppet

    /// @notice The ```puppetSubscriptions``` function returns all the subscriptions for a given Puppet
    /// @param _puppet The address of the Puppet
    /// @return _subscriptions The address array of all the routes that the Puppet is subscribed to
    function puppetSubscriptions(address _puppet) external view returns (address[] memory _subscriptions);

    /// @notice The ```puppetAllowancePercentage``` function returns the allowance percentage for a given Puppet and Route
    /// @param _puppet The address of the Puppet
    /// @param _route The address of the Route
    /// @return _allowance The allowance percentage
    function puppetAllowancePercentage(address _puppet, address _route) external view returns (uint256 _allowance);

    /// @notice The ```puppetAccountBalance``` function returns the account balance for a given Puppet and Asset
    /// @param _puppet The address of the Puppet
    /// @param _asset The address of the Asset
    /// @return uint256 The account balance
    function puppetAccountBalance(address _puppet, address _asset) external view returns (uint256);

    /// @notice The ```puppetThrottleLimit``` function returns the throttle limit for a given Puppet and RouteType
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    /// @return uint256 The throttle limit
    function puppetThrottleLimit(address _puppet, bytes32 _routeType) external view returns (uint256);

    /// @notice The ```lastPositionOpenedTimestamp``` function returns the last position opened timestamp for a given Puppet and RouteType
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    /// @return uint256 The last position opened timestamp
    function lastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external view returns (uint256);

    /// @notice The ```isBelowThrottleLimit``` function returns whether a given Puppet is below the throttle limit for a given RouteType
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    /// @return bool Whether the Puppet is below the throttle limit
    function isBelowThrottleLimit(address _puppet, bytes32 _routeType) external view returns (bool);

    // gmx

    /// @notice The ```gmxInfo``` function returns the GMX Router address
    /// @return address The GMX Router address
    function gmxRouter() external view returns (address);

    /// @notice The ```gmxPositionRouter``` function returns the GMX Position Router address
    /// @return address The GMX Position Router address
    function gmxPositionRouter() external view returns (address);

    /// @notice The ```gmxVault``` function returns the GMX Vault address
    /// @return address The GMX Vault address
    function gmxVault() external view returns (address);

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    // Trader

    /// @notice The ```registerRoute``` function is called by a Trader to register a new Route
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return bytes32 The Route key
    function registerRoute(address _collateralToken, address _indexToken, bool _isLong) external returns (bytes32);

    /// @notice The ```registerRouteAndRequestPosition``` function is called by a Trader to register a new Route and create an Increase Position Request
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    function registerRouteAndRequestPosition(IRoute.AdjustPositionParams memory _adjustPositionParams, IRoute.SwapParams memory _swapParams, uint256 _executionFee, address _collateralToken, address _indexToken, bool _isLong) external payable returns (bytes32 _routeKey, bytes32 _requestKey);

    /// @notice The ```requestPosition``` function creates a new position request
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _routeTypeKey The RouteType key
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    /// @return _requestKey The request key
    function requestPosition(IRoute.AdjustPositionParams memory _adjustPositionParams, IRoute.SwapParams memory _swapParams, bytes32 _routeTypeKey, uint256 _executionFee, bool _isIncrease) external payable returns (bytes32 _requestKey);

    /// @notice The ```approvePlugin``` function is used to approve the GMX plugin in case we change the gmxPositionRouter address
    /// @param _routeTypeKey The RouteType key
    function approvePlugin(bytes32 _routeTypeKey) external;

    // Puppet

    /// @notice The ```deposit``` function is called by a Puppet to deposit funds into his deposit account
    /// @param _amount The amount to deposit
    /// @param _asset The address of the Asset
    /// @param _puppet The address of the recepient
    function deposit(uint256 _amount, address _asset, address _puppet) external payable;

    /// @notice The ```withdraw``` function is called by a Puppet to withdraw funds from his deposit account
    /// @param _amount The amount to withdraw
    /// @param _asset The address of the Asset
    /// @param _receiver The address of the receiver of withdrawn funds
    /// @param _isETH Whether to withdraw ETH or not. Available only for WETH deposits
    function withdraw(uint256 _amount, address _asset, address _receiver, bool _isETH) external;

    /// @notice The ```updateRoutesSubscription``` function is called by a Puppet to update his subscription to a list of Routes
    /// @param _traders The address array of Traders
    /// @param _allowances The corresponding allowance percentage array
    /// @param _routeTypeKey The RouteType key
    /// @param _subscribe Whether to subscribe or unsubscribe
    function updateRoutesSubscription(address[] memory _traders, uint256[] memory _allowances, bytes32 _routeTypeKey, bool _subscribe) external;

    /// @notice The ```setThrottleLimit``` function is called by a Puppet to set his throttle limit for a given RouteType
    /// @param _throttleLimit The throttle limit
    /// @param _routeType The RouteType key
    function setThrottleLimit(uint256 _throttleLimit, bytes32 _routeType) external;

    // Route

    /// @notice The ```debitPuppetAccount``` function is called by a Route to debit a Puppet's account
    /// @param _amount The amount to debit
    /// @param _asset The address of the Asset
    /// @param _puppet The address of the Puppet
    function debitPuppetAccount(uint256 _amount, address _asset, address _puppet) external;

    /// @notice The ```creditPuppetAccount``` function is called by a Route to credit a Puppet's account
    /// @param _amount The amount to credit
    /// @param _asset The address of the Asset
    /// @param _puppet The address of the Puppet
    function creditPuppetAccount(uint256 _amount, address _asset, address _puppet) external;

    /// @notice The ```updateLastPositionOpenedTimestamp``` function is called by a Route to update the last position opened timestamp of a Puppet
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    function updateLastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external;

    /// @notice The ```sendFunds``` function is called by a Route to send funds to a _receiver
    /// @param _amount The amount to send
    /// @param _asset The address of the Asset
    /// @param _receiver The address of the receiver
    function sendFunds(uint256 _amount, address _asset, address _receiver) external;

    /// @notice The ```sendFundsToVault``` function is called by a Route to emit an event on GMX callback
    /// @param _requestKey The request key
    /// @param _isExecuted The boolean indicating if the request is executed
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    function emitCallback(bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external;

    // Authority

    // called by keeper

    /// @notice The ```decreaseSize``` function is called by Puppet keepers to decrease the position size in case there are Puppets to adjust
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _executionFee The total execution fee, paid by the Keeper in ETH
    /// @param _routeKey The Route key
    /// @return _requestKey The request key
    function decreaseSize(IRoute.AdjustPositionParams memory _adjustPositionParams, uint256 _executionFee, bytes32 _routeKey) external payable returns (bytes32 _requestKey);

    /// @notice The ```liquidate``` function is called by Puppet keepers to reset the Route's accounting in case of a liquidation
    /// @param _routeKey The Route key
    function liquidate(bytes32 _routeKey) external;

    // called by owner

    /// @notice The ```rescueTokens``` function is called by the Authority to rescue tokens from this contract
    /// @param _amount The amount to rescue
    /// @param _token The address of the Token
    /// @param _receiver The address of the receiver
    function rescueTokens(uint256 _amount, address _token, address _receiver) external;

    /// @notice The ```rescueRouteTokens``` function is called by the Authority to rescue tokens from a Route
    /// @param _amount The amount to rescue
    /// @param _token The address of the Token
    /// @param _receiver The address of the receiver
    /// @param _route The address of the Route
    function rescueRouteTokens(uint256 _amount, address _token, address _receiver, address _route) external;

    /// @notice The ```freezeRoute``` function is called by the Authority to freeze or unfreeze a Route
    /// @param _route The address of the Route
    /// @param _freeze Whether to freeze or unfreeze
    function freezeRoute(address _route, bool _freeze) external;

    /// @notice The ```setRouteType``` function is called by the Authority to set a new RouteType
    /// @param _collateral The address of the Collateral Token
    /// @param _index The address of the Index Token
    /// @param _isLong The boolean value of the position
    function setRouteType(address _collateral, address _index, bool _isLong) external;

    /// @notice The ```setGMXInfo``` function is called by the Authority to set the GMX contract addresses
    /// @param _gmxRouter The address of the GMX Router
    /// @param _gmxVault The address of the GMX Vault
    /// @param _gmxPositionRouter The address of the GMX Position Router
    function setGMXInfo(address _gmxRouter, address _gmxVault, address _gmxPositionRouter) external;

    /// @notice The ```setKeeper``` function is called by the Authority to set the Keeper address
    /// @param _keeperAddr The address of the new Keeper
    function setKeeper(address _keeperAddr) external;

    /// @notice The ```setReferralCode``` function is called by the Authority to set the referral code
    /// @param _refCode The new referral code
    function setReferralCode(bytes32 _refCode) external;

    /// @notice The ```setRouteFactory``` function is called by the Authority to set the Route Factory address
    /// @param _factory The address of the new Route Factory
    function setRouteFactory(address _factory) external;

    /// @notice The ```setFeeDivisors``` function is called by the Authority to pause all Routes
    /// @param _pause The new pause state
    function pause(bool _pause) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event RegisterRoute(address indexed trader, address indexed route, bytes32 indexed routeTypeKey);
    event RequestPositionAdjustment(address indexed caller, address indexed route, bytes32 indexed requestKey, bytes32 routeTypeKey);
    event ApprovePlugin(address indexed caller, bytes32 indexed routeTypeKey);
    event Deposit(uint256 indexed amount, address indexed asset, address caller, address indexed puppet);
    event Withdraw(uint256 amount, address indexed asset, address indexed receiver, address indexed puppet);
    event Subscribe(address[] traders, uint256[] allowances, address indexed puppet, bytes32 indexed routeTypeKey, bool indexed subscribe);
    event SetThrottleLimit(address indexed puppet, bytes32 indexed routeType, uint256 throttleLimit);
    event DebitPuppet(uint256 amount, address indexed asset, address indexed puppet, address indexed caller);
    event CreditPuppet(uint256 amount, address indexed asset, address indexed puppet, address indexed caller);
    event UpdateOpenTimestamp(address indexed puppet, bytes32 indexed routeType, uint256 timestamp);
    event Send(uint256 amount, address indexed asset, address indexed receiver, address indexed caller);
    event Callback(address indexed route, bytes32 indexed requestKey, bool indexed isExecuted, bool isIncrease);
    event DecreaseSize(bytes32 indexed requestKey, bytes32 indexed routeKey);
    event Liquidate(bytes32 indexed routeKey);
    event SetRouteType(bytes32 routeTypeKey, address collateral, address index, bool isLong);
    event SetGMXUtils(address gmxRouter, address gmxVault, address gmxPositionRouter);
    event Pause(bool paused);
    event SetReferralCode(bytes32 indexed referralCode);
    event SetRouteFactory(address indexed factory);
    event Keeper(address indexed keeper);
    event RouteRescue(uint256 amount, address indexed token, address indexed receiver, address indexed route);
    event Rescue(uint256 amount, address indexed token, address indexed receiver);
    event FreezeRoute(address indexed route, bool indexed freeze);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error NotRoute();
    error RouteTypeNotRegistered();
    error RouteAlreadyRegistered();
    error MismatchedInputArrays();
    error RouteNotRegistered();
    error InvalidAllowancePercentage();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidAmount();
    error InvalidAsset();
    error ZeroBytes32();
    error RouteWaitingForCallback();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// =========================== IRoute ===========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/Puppet

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IPositionRouterCallbackReceiver} from "./IPositionRouterCallbackReceiver.sol";

interface IRoute is IPositionRouterCallbackReceiver {

    struct Route {
        bool isLong;
        address trader;
        address collateralToken;
        address indexToken;
    }

    struct Position {
        uint256 addCollateralRequestsIndex;
        uint256 totalSupply;
        uint256 totalAssets;
        bytes32[] requestKeys;
        address[] puppets;
        mapping(address => uint256) participantShares; // participant => shares
        mapping(address => bool) adjustedPuppets; // puppet => isAdjusted
        mapping(address => uint256) latestAmountIn; // puppet => latestAmountIn
    }

    struct AddCollateralRequest{
        uint256 puppetsAmountIn;
        uint256 traderAmountIn;
        uint256 traderShares;
        uint256 totalSupply;
        uint256 totalAssets;
        uint256[] puppetsShares;
        uint256[] puppetsAmounts;
    }

    struct AdjustPositionParams {
        uint256 collateralDelta;
        uint256 sizeDelta;
        uint256 acceptablePrice;
        uint256 minOut;
    }

    struct SwapParams {
        address[] path;
        uint256 amount;
        uint256 minOut;
    }

    struct GetPuppetAdditionalAmountContext {
        bool isOI;
        uint256 increaseRatio;
        uint256 traderAmountIn;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // Route Info

    /// @notice The ```trader``` function returns the trader address of the current route
    /// @return _trader The trader address
    function trader() external view returns (address _trader);

    // Position Info

    /// @notice The ```puppets``` function returns the puppets that are subscribed to the current position
    /// @return _puppets The address array of puppets
    function puppets() external view returns (address[] memory _puppets);

    /// @notice The ```puppetShares``` function returns the shares of a participant in the current position
    /// @param _participant The participant address
    /// @return _shares The shares of the participant
    function participantShares(address _participant) external view returns (uint256 _shares);

    /// @notice The ```totalSupply``` function returns the latest collateral amount added by a participant to the current position
    /// @param _participant The participant address
    /// @return _amountIn The latest collateral amount added by the participant
    function latestAmountIn(address _participant) external view returns (uint256 _amountIn);

    /// @notice The ```isPuppetAdjusted``` function indicates if a puppet has been adjusted in the current position
    /// @notice Adjusted means that the puppet wasn't able to add collateral to an existing position and so we had to decrease his position size in order to maintain the correct ratio
    /// @param _puppet The puppet address
    /// @return _isAdjusted The boolean indicating if the puppet has been adjusted
    function isPuppetAdjusted(address _puppet) external view returns (bool _isAdjusted);

    // Request Info

    /// @notice The ```puppetsRequestAmounts``` function returns the puppets amounts and shares for a given request
    /// @param _requestKey The request key
    /// @return _puppetsShares The total puppets shares
    /// @return _puppetsAmounts The total puppets amounts 
    function puppetsRequestAmounts(bytes32 _requestKey) external view returns (uint256[] memory _puppetsShares, uint256[] memory _puppetsAmounts);

    /// @notice The ```isWaitingForCallback``` function indicates if the route is waiting for a callback from GMX
    /// @return bool Indicating if the route is waiting for a callback from GMX
    function isWaitingForCallback() external view returns (bool);

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    // Orchestrator

    // called by trader

    /// @notice The ```requestPosition``` function creates a new position request
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    /// @return _requestKey The request key
    function requestPosition(AdjustPositionParams memory _adjustPositionParams, SwapParams memory _swapParams, uint256 _executionFee, bool _isIncrease) external payable returns (bytes32 _requestKey);

    /// @notice The ```approvePlugin``` function is used to approve the GMX plugin in case we change the gmxPositionRouter address
    function approvePlugin() external;

    // called by keeper

    /// @notice The ```decreaseSize``` function is called by Puppet keepers to decrease the position size in case there are Puppets to adjust
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _executionFee The total execution fee, paid by the Keeper in ETH
    /// @return _requestKey The request key
    function decreaseSize(AdjustPositionParams memory _adjustPositionParams, uint256 _executionFee) external payable returns (bytes32 _requestKey);

    /// @notice The ```liquidate``` function is called by Puppet keepers to reset the Route's accounting in case of a liquidation
    function liquidate() external;

    // called by owner

    /// @notice The ```rescueTokens``` is called by the Orchestrator and Authority to rescue tokens
    /// @param _amount The amount to rescue
    /// @param _token The token address
    /// @param _receiver The receiver address
    function rescueTokens(uint256 _amount, address _token, address _receiver) external;

    /// @notice The ```freeze``` function is called by the Orchestrator and Authority to freeze the Route
    /// @param _freeze The boolean indicating if the Route should be frozen or unfrozen 
    function freeze(bool _freeze) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event Liquidate();
    event Callback(bytes32 indexed requestKey, bool indexed isExecuted, bool indexed isIncrease);
    event PluginApproval();
    event IncreaseRequest(bytes32 indexed requestKey, uint256 amountIn, uint256 minOut, uint256 sizeDelta, uint256 acceptablePrice);
    event DecreaseRequest(bytes32 indexed requestKey, uint256 minOut, uint256 collateralDelta, uint256 sizeDelta, uint256 acceptablePrice);
    event Repay(uint256 totalAssets);
    event Reset();
    event Rescue(uint256 amount, address token, address receiver);
    event Freeze(bool indexed freeze);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error NotKeeper();
    error NotTrader();
    error InvalidExecutionFee();
    error InvalidPath();
    error PositionStillAlive();
    error Paused();
    error NotOrchestrator();
    error RouteFrozen();
    error NotCallbackCaller();
    error ZeroAmount();
}

// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

interface IPositionRouterCallbackReceiver {

    /// @notice The ```gmxPositionCallback``` is called on by GMX keepers after a position request is executed
    /// @param positionKey The position key
    /// @param isExecuted The boolean indicating if the position was executed
    /// @param isIncrease The boolean indicating if the position was increased
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}