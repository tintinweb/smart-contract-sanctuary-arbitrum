// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Keys
/// @dev Keys for values in the DataStore
library Keys {

    // DataStore.uintValues

    /// @dev key for management fee (DataStore.uintValues)
    bytes32 public constant MANAGEMENT_FEE = keccak256(abi.encode("MANAGEMENT_FEE"));
    /// @dev key for withdrawal fee (DataStore.uintValues)
    bytes32 public constant WITHDRAWAL_FEE = keccak256(abi.encode("WITHDRAWAL_FEE"));
    /// @dev key for performance fee (DataStore.uintValues)
    bytes32 public constant PERFORMANCE_FEE = keccak256(abi.encode("PERFORMANCE_FEE"));

    // DataStore.intValues

    // DataStore.addressValues

    /// @dev key for sending received fees
    bytes32 public constant PLATFORM_FEES_RECIPIENT = keccak256(abi.encode("PLATFORM_FEES_RECIPIENT"));
    /// @dev key for subscribing to multiple Routes
    bytes32 public constant MULTI_SUBSCRIBER = keccak256(abi.encode("MULTI_SUBSCRIBER"));
    /// @dev key for the address of the keeper
    bytes32 public constant KEEPER = keccak256(abi.encode("KEEPER"));
    /// @dev key for the address of the Score Gauge
    bytes32 public constant SCORE_GAUGE = keccak256(abi.encode("SCORE_GAUGE"));
    /// @dev key for the address of the Route Factory
    bytes32 public constant ROUTE_FACTORY = keccak256(abi.encode("ROUTE_FACTORY"));
    /// @dev key for the address of the Route Setter
    bytes32 public constant ROUTE_SETTER = keccak256(abi.encode("ROUTE_SETTER"));
    /// @dev key for the address of the Orchestrator
    bytes32 public constant ORCHESTRATOR = keccak256(abi.encode("ORCHESTRATOR"));

    // DataStore.boolValues

    /// @dev key for pause status
    bytes32 public constant PAUSED = keccak256(abi.encode("PAUSED"));

    // DataStore.stringValues

    // DataStore.bytes32Values

    /// @dev key for the referral code
    bytes32 public constant REFERRAL_CODE = keccak256(abi.encode("REFERRAL_CODE"));

    // DataStore.addressArrayValues

    /// @dev key for the array of routes
    bytes32 public constant ROUTES = keccak256(abi.encode("ROUTES"));


    // -------------------------------------------------------------------------------------------

    // global

    function routeTypeKey(address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) public pure returns (bytes32) {
        return keccak256(abi.encode(_collateralToken, _indexToken, _isLong, _data));
    }

    function routeTypeCollateralTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN", _routeTypeKey));
    }

    function routeTypeIndexTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("INDEX_TOKEN", _routeTypeKey));
    }

    function routeTypeIsLongKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_LONG", _routeTypeKey));
    }

    function routeTypeDataKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("DATA", _routeTypeKey));
    }

    function platformAccountKey(address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PLATFORM_ACCOUNT", _asset));
    }

    function isRouteTypeRegisteredKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_TYPE_REGISTERED", _routeTypeKey));
    }

    function isCollateralTokenKey(address _token) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_COLLATERAL_TOKEN", _token));
    }

    function collateralTokenDecimalsKey(address _collateralToken) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN_DECIMALS", _collateralToken));
    }

    // route

    function routeCollateralTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_COLLATERAL_TOKEN", _route));
    }

    function routeIndexTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_INDEX_TOKEN", _route));
    }

    function routeIsLongKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_IS_LONG", _route));
    }

    function routeTraderKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_TRADER", _route));
    }

    function routeDataKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_DATA", _route));
    }

    function routeRouteTypeKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ROUTE_TYPE", _route));
    }

    function routeAddressKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ADDRESS", _routeKey));
    }

    function routePuppetsKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_PUPPETS", _routeKey));
    }

    function targetLeverageKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TARGET_LEVERAGE", _routeKey));
    }

    function isKeeperRequestsKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("KEEPER_REQUESTS", _routeKey, _requestKey));
    }

    function isRouteRegisteredKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_REGISTERED", _routeKey));
    }

    function isWaitingForKeeperAdjustmentKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_WAITING_FOR_KEEPER_ADJUSTMENT", _routeKey));
    }

    function isKeeperAdjustmentEnabledKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_KEEPER_ADJUSTMENT_ENABLED", _routeKey));
    }

    function isPositionOpenKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_POSITION_OPEN", _routeKey));
    }

    // route position

    function positionIndexKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_INDEX", _routeKey));
    }

    function positionPuppetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS", _positionIndex, _routeKey));
    }

    function positionTraderSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TRADER_SHARES", _positionIndex, _routeKey));
    }

    function positionPuppetsSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS_SHARES", _positionIndex, _routeKey));
    }

    function positionLastTraderAmountInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_TRADER_AMOUNT_IN", _positionIndex, _routeKey));
    }

    function positionLastPuppetsAmountsInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_PUPPETS_AMOUNTS_IN", _positionIndex, _routeKey));
    }

    function positionTotalSupplyKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_SUPPLY", _positionIndex, _routeKey));
    }

    function positionTotalAssetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_ASSETS", _positionIndex, _routeKey));
    }

    function cumulativeVolumeGeneratedKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("CUMULATIVE_VOLUME_GENERATED", _routeKey));
    }

    function puppetsPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPETS_PNL", _routeKey));
    }

    function traderPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TRADER_PNL", _routeKey));
    }

    // route request

    function requestKeyToAddCollateralRequestsIndexKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEY_TO_ADD_COLLATERAL_REQUESTS_INDEX", _routeKey, _requestKey));
    }

    function addCollateralRequestsIndexKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUESTS_INDEX", _positionIndex, _routeKey));
    }

    function addCollateralRequestPuppetsSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNTS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestIsAdjustmentRequiredKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_IS_ADJUSTMENT_REQUIRED", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalSupplyKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_SUPPLY", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalAssetsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_ASSETS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function pendingSizeDeltaKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PENDING_SIZE_DELTA", _routeKey, _requestKey));
    }

    function requestKeysKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEYS", _positionIndex, _routeKey));
    }

    // puppet

    function puppetAllowancesKey(address _puppet) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_ALLOWANCES", _puppet));
    }

    function puppetSubscriptionExpiryKey(address _puppet, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_SUBSCRIPTION_EXPIRY", _puppet, _routeKey));
    }

    function puppetDepositAccountKey(address _puppet, address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_DEPOSIT_ACCOUNT", _puppet, _asset));
    }

    function puppetThrottleLimitKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_THROTTLE_LIMIT", _puppet, _routeTypeKey));
    }

    function puppetLastPositionOpenedTimestampKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_LAST_POSITION_OPENED_TIMESTAMP", _puppet, _routeTypeKey));
    }
}