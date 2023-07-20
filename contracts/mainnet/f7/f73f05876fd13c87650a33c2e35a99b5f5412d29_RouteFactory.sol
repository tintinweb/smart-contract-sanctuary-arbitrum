// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ====================== RouteFactory ==========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IRouteFactory} from "./interfaces/IRouteFactory.sol";

import {Route} from "./Route.sol";

/// @title RouteFactory
/// @author johnnyonline (Puppet Finance) https://github.com/johnnyonline
/// @notice This contract is used by the Orchestrator to create new Routes
contract RouteFactory is IRouteFactory {

    /// @inheritdoc IRouteFactory
    function createRoute(address _orchestrator, address _trader, address _collateralToken, address _indexToken, bool _isLong) external returns (address _route) {
        _route = address(new Route(_orchestrator, _trader, _collateralToken, _indexToken, _isLong));

        emit RouteCreated(msg.sender, _route, _orchestrator, _trader, _collateralToken, _indexToken, _isLong);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== IRouteFactory =======================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================= Route ==============================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IGMXRouter} from "./interfaces/IGMXRouter.sol";
import {IGMXPositionRouter} from "./interfaces/IGMXPositionRouter.sol";
import {IGMXVault} from "./interfaces/IGMXVault.sol";
import {IPositionRouterCallbackReceiver} from "./interfaces/IPositionRouterCallbackReceiver.sol";

import {IRoute} from "./interfaces/IRoute.sol";

import "./Base.sol";

/// @title Route
/// @author johnnyonline (Puppet Finance) https://github.com/johnnyonline
/// @notice This contract acts as a container account for a specific trading route, called by the Orchestrator and owned by a Trader
contract Route is Base, IPositionRouterCallbackReceiver, IRoute {

    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public waitForKeeperAdjustment;
    bool public frozen;

    bool private _isPositionOpen;
    bool private _enableKeeperAdjustment;

    uint256 public positionIndex;
    uint256 public targetLeverage;

    uint256 private immutable _collateralTokenDecimals;

    uint256 private constant _PRECISION = 1e18;

    bytes32 private immutable _routeTypeKey;

    mapping(bytes32 => bool) public keeperRequests; // requestKey => isKeeperRequest

    mapping(bytes32 => uint256) public requestKeyToAddCollateralRequestsIndex; // requestKey => addCollateralRequestsIndex
    mapping(uint256 => AddCollateralRequest) public addCollateralRequests; // addCollateralIndex => AddCollateralRequest
    mapping(uint256 => Position) public positions; // positionIndex => Position

    IOrchestrator public immutable orchestrator;

    Route public route;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _orchestrator The address of the ```Orchestrator``` contract
    /// @param _trader The address of the trader
    /// @param _collateralToken The address of the collateral token
    /// @param _indexToken The address of the index token
    /// @param _isLong Whether the route is long or short
    constructor(address _orchestrator, address _trader, address _collateralToken, address _indexToken, bool _isLong) {
        orchestrator = IOrchestrator(_orchestrator);

        route.trader = _trader;
        route.collateralToken = _collateralToken;
        route.indexToken = _indexToken;
        route.isLong = _isLong;

        _collateralTokenDecimals = 10 ** IERC20(_collateralToken).decimals();

        _routeTypeKey = orchestrator.getRouteTypeKey(_collateralToken, _indexToken, _isLong);

        IGMXRouter(orchestrator.gmxRouter()).approvePlugin(orchestrator.gmxPositionRouter());
    }

    // ============================================================================================
    // Modifiers
    // ============================================================================================

    /// @notice Modifier that ensures the caller is the orchestrator
    modifier onlyOrchestrator() {
        if (msg.sender != address(orchestrator)) revert NotOrchestrator();
        _;
    }

    /// @notice Modifier that ensures the Route is not frozen and the orchestrator is not paused
    modifier notFrozen() {
        if (orchestrator.paused()) revert Paused();
        if (frozen) revert RouteFrozen();
        _;
    }

    /// @notice Modifier that ensures the Route waits for a keeper adjustment, when one is pending
    modifier waitForAdjustment() {
        if (waitForKeeperAdjustment) revert WaitingForKeeperAdjustment();
        _;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // Route Info

    /// @inheritdoc IRoute
    function trader() external view returns (address) {
        return route.trader;
    }

    /// @inheritdoc IRoute
    function collateralToken() external view returns (address) {
        return route.collateralToken;
    }

    /// @inheritdoc IRoute
    function indexToken() external view returns (address) {
        return route.indexToken;
    }

    /// @inheritdoc IRoute
    function isLong() external view returns (bool) {
        return route.isLong;
    }

    /// @inheritdoc IRoute
    function routeKey() external view returns (bytes32) {
        return orchestrator.getRouteKey(route.trader, _routeTypeKey);
    }

    // Position Info

    /// @inheritdoc IRoute
    function puppets() external view returns (address[] memory) {
        return positions[positionIndex].puppets;
    }

    /// @inheritdoc IRoute
    function participantShares(address _participant) external view returns (uint256 _shares) {
        Position storage _position = positions[positionIndex];

        if (_participant == route.trader) return _position.traderShares;

        for (uint256 i = 0; i < _position.puppets.length; i++) {
            if (_position.puppets[i] == _participant) {
                return _position.puppetsShares[i];
            }
        }
    }

    /// @inheritdoc IRoute
    function lastAmountIn(address _participant) external view returns (uint256 _amount) {
        Position storage _position = positions[positionIndex];

        if (_participant == route.trader) return _position.lastTraderAmountIn;

        for (uint256 i = 0; i < _position.puppets.length; i++) {
            if (_position.puppets[i] == _participant) {
                return _position.lastPuppetsAmountsIn[i];
            }
        }
    }

    /// @inheritdoc IRoute
    function isPositionOpen() external view returns (bool) {
        return _isPositionOpen;
    }

    /// @inheritdoc IRoute
    function isAdjustmentEnabled() external view returns (bool) {
        return _enableKeeperAdjustment;
    }

    /// @inheritdoc IRoute
    function requiredAdjustmentSize() external view returns (uint256) {
        (uint256 _size, uint256 _collateral) = _getPositionAmounts();
 
        return targetLeverage != 0 ? _size - (_collateral * targetLeverage / _BASIS_POINTS_DIVISOR) : 0;
    }

    // Request Info

    /// @inheritdoc IRoute
    function puppetsRequestAmounts(
        bytes32 _requestKey
    ) external view returns (uint256[] memory _puppetsShares, uint256[] memory _puppetsAmounts) {
        uint256 _index = requestKeyToAddCollateralRequestsIndex[_requestKey];
        _puppetsShares = addCollateralRequests[_index].puppetsShares;
        _puppetsAmounts = addCollateralRequests[_index].puppetsAmounts;
    }

    /// @inheritdoc IRoute
    function isWaitingForCallback() external view returns (bool) {
        bytes32[] memory _requests = positions[positionIndex].requestKeys;
        IGMXPositionRouter _positionRouter = IGMXPositionRouter(orchestrator.gmxPositionRouter());
        for (uint256 _i = 0; _i < _requests.length; _i++) {
            address[] memory _increasePath = _positionRouter.getIncreasePositionRequestPath(_requests[_i]);
            address[] memory _decreasePath = _positionRouter.getDecreasePositionRequestPath(_requests[_i]);
            if (_increasePath.length > 0 || _decreasePath.length > 0) {
                return true;
            }
        }

        return false;
    }

    // ============================================================================================
    // Orchestrator Functions
    // ============================================================================================

    // called by trader

    /// @inheritdoc IRoute
    // slither-disable-next-line reentrancy-eth
    function requestPosition(
        AdjustPositionParams memory _adjustPositionParams,
        SwapParams memory _swapParams,
        uint256 _executionFee,
        bool _isIncrease
    ) external payable onlyOrchestrator notFrozen waitForAdjustment nonReentrant returns (bytes32 _requestKey) {

        _repayBalance(bytes32(0), msg.value, true, false);

        if (_isIncrease) {
            (
                uint256 _puppetsAmountIn,
                uint256 _traderAmountIn,
                uint256 _traderShares,
                uint256 _totalSupply
            ) = _getAssets(_swapParams, _executionFee);

            _setTargetLeverage(_adjustPositionParams.sizeDelta, _traderAmountIn, _traderShares, _totalSupply);
            _requestKey = _requestIncreasePosition(_adjustPositionParams, _puppetsAmountIn + _traderAmountIn, _executionFee);
        } else {
            _requestKey = _requestDecreasePosition(_adjustPositionParams, _executionFee);
        }
    }

    /// @inheritdoc IRoute
    function approvePlugin() external onlyOrchestrator notFrozen waitForAdjustment nonReentrant {
        IGMXRouter(orchestrator.gmxRouter()).approvePlugin(orchestrator.gmxPositionRouter());

        emit PluginApproval();
    }

    // called by keeper

    /// @inheritdoc IRoute
    function decreaseSize(
        AdjustPositionParams memory _adjustPositionParams,
        uint256 _executionFee
    ) external payable onlyOrchestrator nonReentrant returns (bytes32 _requestKey) {
        if (!waitForKeeperAdjustment) revert NotWaitingForKeeperAdjustment();
        if (!_enableKeeperAdjustment) revert KeeperAdjustmentDisabled();

        _enableKeeperAdjustment = false;

        _requestKey = _requestDecreasePosition(_adjustPositionParams, _executionFee);

        keeperRequests[_requestKey] = true;
    }

    /// @inheritdoc IRoute
    function liquidate() external onlyOrchestrator nonReentrant {
        if (_isOpenInterest()) revert PositionStillAlive();
        if (!_isPositionOpen) revert PositionNotOpen();

        _repayBalance(bytes32(0), 0, true, false);

        emit Liquidate();
    }

    // called by owner

    /// @inheritdoc IRoute
    function rescueTokenFunds(uint256 _amount, address _token, address _receiver) external onlyOrchestrator {
        if (_token == address(0)) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }

        emit RescueTokenFunds(_amount, _token, _receiver);
    }

    /// @inheritdoc IRoute
    function freeze(bool _freeze) external onlyOrchestrator {
        frozen = _freeze;

        emit Freeze(_freeze);
    }

    // ============================================================================================
    // Callback Function
    // ============================================================================================

    /// @inheritdoc IPositionRouterCallbackReceiver
    function gmxPositionCallback(bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external nonReentrant {
        if (msg.sender != orchestrator.gmxPositionRouter()) revert NotCallbackCaller();

        if (_isExecuted && _isIncrease) _allocateShares(_requestKey);

        _repayBalance(_requestKey, 0, _isExecuted, keeperRequests[_requestKey]);

        orchestrator.emitExecutionCallback(_requestKey, _isExecuted, _isIncrease);

        emit Callback(_requestKey, _isExecuted, _isIncrease);
    }

    // ============================================================================================
    // Internal Mutated Functions
    // ============================================================================================

    /// @notice The ```_getAssets``` function is used to get the assets of the Trader and Puppets and update the request accounting
    /// @dev This function is called by ```requestPosition```
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _executionFee The execution fee paid by the Trader, in ETH
    /// @return _puppetsAmountIn The amount of collateral the Puppets will add to the position
    /// @return _traderAmountIn The amount of collateral the Trader will add to the position
    /// @return _traderShares The amount of shares the Trader will receive
    /// @return _totalSupply The total amount of shares for the request
    // slither-disable-next-line reentrancy-eth
    function _getAssets(
        SwapParams memory _swapParams,
        uint256 _executionFee
    ) internal returns (uint256 _puppetsAmountIn, uint256 _traderAmountIn, uint256 _traderShares, uint256 _totalSupply) {
        if (_swapParams.amount > 0) {
            // 1. get trader assets and allocate request shares. pull funds too, if needed
            _traderAmountIn = _getTraderAssets(_swapParams, _executionFee);

            _traderShares = _convertToShares(0, 0, _traderAmountIn);

            uint256 _totalAssets = _traderAmountIn;
            _totalSupply = _traderShares;

            // 2. get puppets assets and allocate request shares
            (bytes memory _puppetsRequestData, bool _isAdjustmentRequired) = _getPuppetsAssetsAndAllocateRequestShares(_totalSupply, _totalAssets);

            uint256[] memory _puppetsShares;
            uint256[] memory _puppetsAmounts;
            (
                _puppetsAmountIn,
                _totalSupply,
                _totalAssets,
                _puppetsShares,
                _puppetsAmounts
            ) = abi.decode(_puppetsRequestData, (uint256, uint256, uint256, uint256[], uint256[]));

            // 3. store request data
            AddCollateralRequest memory _request = AddCollateralRequest({
                isAdjustmentRequired: _isAdjustmentRequired,
                puppetsAmountIn: _puppetsAmountIn,
                traderAmountIn: _traderAmountIn,
                traderShares: _traderShares,
                totalSupply: _totalSupply,
                totalAssets: _totalAssets,
                puppetsShares: _puppetsShares,
                puppetsAmounts: _puppetsAmounts
            });

            uint256 _positionIndex = positionIndex;
            addCollateralRequests[positions[_positionIndex].addCollateralRequestsIndex] = _request;
            positions[_positionIndex].addCollateralRequestsIndex += 1;

            // 4. pull funds from Orchestrator
            orchestrator.transferRouteFunds(_puppetsAmountIn, route.collateralToken, address(this));

            return (_puppetsAmountIn, _traderAmountIn, _traderShares, _totalSupply);
        }
    }

    /// @notice The ```_getTraderAssets``` function is used to get the assets of the Trader
    /// @dev This function is called by ```_getAssets```
    /// @param _swapParams The swap data of the Trader, enables the Trader to add collateral with a non-collateral token
    /// @param _executionFee The execution fee paid by the Trader, in ETH
    /// @return _traderAmountIn The total amount of collateral the Trader is requesting to add to the position
    function _getTraderAssets(SwapParams memory _swapParams, uint256 _executionFee) internal returns (uint256 _traderAmountIn) {
        if (msg.value - _executionFee > 0) {
            if (msg.value - _executionFee != _swapParams.amount) revert InvalidExecutionFee();
            if (_swapParams.path[0] != _WETH) revert InvalidPath();

            payable(_WETH).functionCallWithValue(abi.encodeWithSignature("deposit()"), _swapParams.amount);
        } else {
            if (msg.value != _executionFee) revert InvalidExecutionFee();

            // slither-disable-next-line arbitrary-send-erc20
            IERC20(_swapParams.path[0]).safeTransferFrom(route.trader, address(this), _swapParams.amount);
        }

        if (_swapParams.path[0] == route.collateralToken) {
            _traderAmountIn = _swapParams.amount;
        } else {
            address _toToken = _swapParams.path[_swapParams.path.length - 1];
            if (_toToken != route.collateralToken) revert InvalidPath();

            address _router = orchestrator.gmxRouter();
            _approve(_router, _swapParams.path[0], _swapParams.amount);

            uint256 _before = IERC20(_toToken).balanceOf(address(this));
            IGMXRouter(_router).swap(_swapParams.path, _swapParams.amount, _swapParams.minOut, address(this));
            _traderAmountIn = IERC20(_toToken).balanceOf(address(this)) - _before;
        }
    }

    /// @notice The ```_getPuppetsAssetsAndAllocateRequestShares``` function is used to get the assets of the Puppets and allocate request shares
    /// @dev This function is called by ```_getAssets```
    /// @param _totalSupply The current total supply of shares in the request
    /// @param _totalAssets The current total assets in the request
    /// @return _puppetsRequestData The request data of the Puppets, encoded as bytes
    /// @return _isAdjustmentRequired A boolean indicating whether an adjusted has to be made if the request is executed
    // slither-disable-next-line reentrancy-no-eth
    function _getPuppetsAssetsAndAllocateRequestShares(
        uint256 _totalSupply,
        uint256 _totalAssets
    ) internal returns (bytes memory _puppetsRequestData, bool _isAdjustmentRequired) {
        bool _isOI = _isOpenInterest();
        uint256 _traderAmountIn = _totalAssets;
        // uint256 _increaseRatio = _isOI ? _traderAmountIn * _PRECISION / positions[positionIndex].latestAmountIn[route.trader] : 0;
        uint256 _increaseRatio = _isOI ? _traderAmountIn * _PRECISION / positions[positionIndex].lastTraderAmountIn : 0;

        uint256 _puppetsAmountIn = 0;
        address[] memory _puppets = _getRelevantPuppets(_isOI);
        uint256[] memory _puppetsShares = new uint256[](_puppets.length);
        uint256[] memory _puppetsAmounts = new uint256[](_puppets.length);

        GetPuppetAdditionalAmountContext memory _context = GetPuppetAdditionalAmountContext({
            isOI: _isOI,
            increaseRatio: _increaseRatio,
            traderAmountIn: _traderAmountIn
        });

        for (uint256 i = 0; i < _puppets.length; i++) {
            PuppetRequestInfo memory _puppetRequestInfo = _getPuppetAmounts(
                _context,
                _totalSupply,
                _totalAssets,
                i,
                _puppets[i]
            );

            if (_puppetRequestInfo.isAdjustmentRequired) _isAdjustmentRequired = true;

            if (_puppetRequestInfo.additionalAmount > 0) {
                orchestrator.debitPuppetAccount(_puppetRequestInfo.additionalAmount, route.collateralToken, _puppets[i]);

                _puppetsAmountIn += _puppetRequestInfo.additionalAmount;

                _totalSupply += _puppetRequestInfo.additionalShares;
                _totalAssets += _puppetRequestInfo.additionalAmount;
            }

            _puppetsShares[i] = _puppetRequestInfo.additionalShares;
            _puppetsAmounts[i] = _puppetRequestInfo.additionalAmount;
        }

        _puppetsRequestData = abi.encode(
            _puppetsAmountIn,
            _totalSupply,
            _totalAssets,
            _puppetsShares,
            _puppetsAmounts
        );
    }

    /// @notice The ```_getRelevantPuppets``` function is used to get the relevant Puppets for the request and update the Position's Puppets, if needed
    /// @dev This function is called by ```_getPuppetsAssetsAndAllocateRequestShares```
    /// @param _isOI A boolean indicating if the request is adding to an already opened position
    /// @return _puppets The relevant Puppets for the request
    function _getRelevantPuppets(bool _isOI) internal returns (address[] memory _puppets) {
        Position storage _position = positions[positionIndex];
        if (_isOI) {
            _puppets = _position.puppets;
        } else {
            _puppets = orchestrator.subscribedPuppets(orchestrator.getRouteKey(route.trader, _routeTypeKey));
            _position.lastPuppetsAmountsIn = new uint256[](_puppets.length);
            _position.puppetsShares = new uint256[](_puppets.length);
            _position.puppets = _puppets;
        }
    }

    /// @notice The ```_getPuppetAmounts``` function is used to get the additional amount and shares for a Puppet
    /// @dev This function is called by ```_getPuppetsAssetsAndAllocateRequestShares```
    /// @param _context The context of the request
    /// @param _totalSupply The current total supply of shares in the request
    /// @param _totalAssets The current total assets in the request
    /// @param _puppetIndex The index of the Puppet in the Position's Puppets array
    /// @param _puppet The Puppet address
    /// @return _puppetRequestInfo A struct containing the additional amount, additional shares and a boolean indicating if the Puppet needs to be adjusted
    function _getPuppetAmounts(
        GetPuppetAdditionalAmountContext memory _context,
        uint256 _totalSupply,
        uint256 _totalAssets,
        uint256 _puppetIndex,
        address _puppet
    ) internal returns (PuppetRequestInfo memory _puppetRequestInfo) {
        Position storage _position = positions[positionIndex];

        uint256 _allowancePercentage = orchestrator.puppetAllowancePercentage(_puppet, address(this));
        uint256 _allowanceAmount = (orchestrator.puppetAccountBalance(_puppet, route.collateralToken) * _allowancePercentage) / _BASIS_POINTS_DIVISOR;

        if (_context.isOI) {
            uint256 _requiredAdditionalCollateral = _position.lastPuppetsAmountsIn[_puppetIndex] * _context.increaseRatio / _PRECISION;
            if (_requiredAdditionalCollateral != 0) {
                if (_requiredAdditionalCollateral > _allowanceAmount) {
                    waitForKeeperAdjustment = true;
                    _puppetRequestInfo.isAdjustmentRequired = true;
                    if(_allowanceAmount == 0) return _puppetRequestInfo;
                    _puppetRequestInfo.additionalAmount = _allowanceAmount;
                } else {
                    _puppetRequestInfo.additionalAmount = _requiredAdditionalCollateral;
                }
                _puppetRequestInfo.additionalShares = _convertToShares(_totalAssets, _totalSupply, _puppetRequestInfo.additionalAmount);
            }
        } else {
            if (_allowanceAmount > 0 && orchestrator.isBelowThrottleLimit(_puppet, _routeTypeKey)) {
                _puppetRequestInfo.additionalAmount = _allowanceAmount > _context.traderAmountIn ? _context.traderAmountIn : _allowanceAmount;
                _puppetRequestInfo.additionalShares = _convertToShares(_totalAssets, _totalSupply, _puppetRequestInfo.additionalAmount);
                orchestrator.updateLastPositionOpenedTimestamp(_puppet, _routeTypeKey);
            }
        }
    }

    /// @notice The ```_requestIncreasePosition``` function is used to create a request to increase the position size and/or collateral
    /// @dev This function is called by ```requestPosition```
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _amountIn The total amount of collateral to increase the position by
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @return _requestKey The request key of the request
    function _requestIncreasePosition(
        AdjustPositionParams memory _adjustPositionParams,
        uint256 _amountIn,
        uint256 _executionFee
    ) internal returns (bytes32 _requestKey) {
        address[] memory _path = new address[](1);
        _path[0] = route.collateralToken;

        _approve(orchestrator.gmxRouter(), _path[0], _amountIn);

        // slither-disable-next-line arbitrary-send-eth
        _requestKey = IGMXPositionRouter(orchestrator.gmxPositionRouter()).createIncreasePosition{ value: _executionFee } (
            _path,
            route.indexToken,
            _amountIn,
            _adjustPositionParams.minOut,
            _adjustPositionParams.sizeDelta,
            route.isLong,
            _adjustPositionParams.acceptablePrice,
            _executionFee,
            orchestrator.referralCode(),
            address(this)
        );

        positions[positionIndex].requestKeys.push(_requestKey);

        if (_amountIn > 0) requestKeyToAddCollateralRequestsIndex[_requestKey] = positions[positionIndex].addCollateralRequestsIndex - 1;

        emit IncreaseRequest(
            _requestKey,
            _amountIn,
            _adjustPositionParams.minOut,
            _adjustPositionParams.sizeDelta,
            _adjustPositionParams.acceptablePrice
        );
    }

    /// @notice The ```_requestDecreasePosition``` function is used to create a request to decrease the position size and/or collateral
    /// @dev This function is called by ```requestPosition```
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _executionFee The total execution fee, paid by the Trader in ETH
    /// @return _requestKey The request key of the request
    function _requestDecreasePosition(
        AdjustPositionParams memory _adjustPositionParams,
        uint256 _executionFee
    ) internal returns (bytes32 _requestKey) {
        if (msg.value != _executionFee) revert InvalidExecutionFee();

        address[] memory _path = new address[](1);
        _path[0] = route.collateralToken;

        // slither-disable-next-line arbitrary-send-eth
        _requestKey = IGMXPositionRouter(orchestrator.gmxPositionRouter()).createDecreasePosition{ value: _executionFee } (
            _path,
            route.indexToken,
            _adjustPositionParams.collateralDelta,
            _adjustPositionParams.sizeDelta,
            route.isLong,
            address(this), // _receiver
            _adjustPositionParams.acceptablePrice,
            _adjustPositionParams.minOut,
            _executionFee,
            false, // _withdrawETH
            address(this)
        );

        positions[positionIndex].requestKeys.push(_requestKey);

        emit DecreaseRequest(
            _requestKey,
            _adjustPositionParams.minOut,
            _adjustPositionParams.collateralDelta,
            _adjustPositionParams.sizeDelta,
            _adjustPositionParams.acceptablePrice
        );
    }

    /// @notice The ```_setTargetLeverage``` function is used to set the target leverage the trader is aiming for when adding collateral to an existing position
    /// @param _sizeIncrease The USD amount of size to increase the position by. With 1e30 precision
    /// @param _traderCollateralIncrease The amount of collateral the trader is adding to the position
    /// @param _traderSharesIncrease The amount of shares the trader will get once the request is executed
    /// @param _totalSupplyIncrease The total shares amount of the request
    function _setTargetLeverage(
        uint256 _sizeIncrease,
        uint256 _traderCollateralIncrease,
        uint256 _traderSharesIncrease,
        uint256 _totalSupplyIncrease
    ) internal {
        if (waitForKeeperAdjustment) {
            (uint256 _positionSize, uint256 _positionCollateral) = _getPositionAmounts();

            Position storage _position = positions[positionIndex];
            Route memory _route = route;

            uint256 _positionTotalSupply = _position.totalSupply;
            uint256 _traderPositionShares = _position.traderShares;
            uint256 _traderPositionSize = _convertToAssets(_positionSize, _positionTotalSupply, _traderPositionShares);
            uint256 _traderPositionCollateral = _convertToAssets(_positionCollateral, _positionTotalSupply, _traderPositionShares);

            uint256 _traderSizeIncrease;
            if (_sizeIncrease == 0) {
                _traderSizeIncrease = 0;
            } else {
                _traderSizeIncrease = _convertToAssets(_sizeIncrease, _totalSupplyIncrease, _traderSharesIncrease);
            }

            _traderCollateralIncrease = orchestrator.getPrice(_route.collateralToken) * _traderCollateralIncrease / _collateralTokenDecimals;

            uint256 _currentLeverage = _traderPositionSize * _BASIS_POINTS_DIVISOR / _traderPositionCollateral;
            uint256 _targetLeverage = (_traderPositionSize + _traderSizeIncrease) * _BASIS_POINTS_DIVISOR / (_traderPositionCollateral + _traderCollateralIncrease);

            if (_targetLeverage >= _currentLeverage) {
                waitForKeeperAdjustment = false;
            } else {
                targetLeverage = _targetLeverage;
            }
        }
    }

    /// @notice The ```_allocateShares``` function is used to update the position accounting with the request data
    /// @dev This function is called by ```gmxPositionCallback```
    /// @param _requestKey The request key of the request
    function _allocateShares(bytes32 _requestKey) internal {
        AddCollateralRequest memory _request = addCollateralRequests[requestKeyToAddCollateralRequestsIndex[_requestKey]];
        uint256 _traderAmountIn = _request.traderAmountIn;
        if (_traderAmountIn > 0) {
            Position storage _position = positions[positionIndex];
            uint256 _totalSupply = _position.totalSupply;
            uint256 _totalAssets = _position.totalAssets;
            address[] memory _puppets = _position.puppets;
            for (uint256 i = 0; i < _puppets.length; i++) {
                uint256 _puppetAmountIn = _request.puppetsAmounts[i];
                if (_puppetAmountIn > 0) {
                    uint256 _newPuppetShares = _convertToShares(_totalAssets, _totalSupply, _puppetAmountIn);

                    _position.puppetsShares[i] += _newPuppetShares;

                    _position.lastPuppetsAmountsIn[i] = _puppetAmountIn;

                    _totalSupply = _totalSupply + _newPuppetShares;
                    _totalAssets = _totalAssets + _puppetAmountIn;
                }
            }

            _isPositionOpen = true;

            uint256 _newTraderShares = _convertToShares(_totalAssets, _totalSupply, _traderAmountIn);

            _position.traderShares += _newTraderShares;

            _position.lastTraderAmountIn = _traderAmountIn;

            _totalSupply = _totalSupply + _newTraderShares;
            _totalAssets = _totalAssets + _traderAmountIn;

            _position.totalSupply = _totalSupply;
            _position.totalAssets = _totalAssets;

            orchestrator.emitSharesIncrease(_position.puppetsShares, _position.traderShares, _totalSupply);
        }
    }

    /// @notice The ```_repayBalance``` function is used to repay the balance of the Route
    /// @dev This function is called by ```requestPosition```, ```liquidate``` and ```gmxPositionCallback```
    /// @param _requestKey The request key of the request, expected to be `bytes32(0)` if called on a successful request
    /// @param _traderAmountIn The amount ETH paid by the trader before this function is called
    /// @param _isExecuted A boolean indicating whether the request was executed
    /// @param _isKeeperRequest A boolean indicating whether the request was made by a keeper
    function _repayBalance(bytes32 _requestKey, uint256 _traderAmountIn, bool _isExecuted, bool _isKeeperRequest) internal {
        AddCollateralRequest memory _request = addCollateralRequests[requestKeyToAddCollateralRequestsIndex[_requestKey]];
        Position storage _position = positions[positionIndex];
        Route memory _route = route;

        if (!_isOpenInterest() && _isPositionOpen) {
            _resetRoute();
        }

        _setAdjustmentFlags(_request.isAdjustmentRequired, _isExecuted, _isKeeperRequest);

        uint256 _totalAssets = IERC20(_route.collateralToken).balanceOf(address(this));
        if (_totalAssets > 0) {
            uint256 _puppetsAssets = 0;
            uint256 _totalSupply = 0;
            uint256 _balance = _totalAssets;
            address[] memory _puppets = _position.puppets;
            for (uint256 i = 0; i < _puppets.length; i++) {
                uint256 _shares;
                address _puppet = _puppets[i];
                if (!_isExecuted) {
                    if (i == 0) _totalSupply = _request.totalSupply;
                    _shares = _request.puppetsShares[i];
                } else {
                    if (i == 0) _totalSupply = _position.totalSupply;
                    _shares = _position.puppetsShares[i];
                }

                if (_shares > 0) {
                    uint256 _assets = _convertToAssets(_balance, _totalSupply, _shares);

                    orchestrator.creditPuppetAccount(_assets, _route.collateralToken, _puppet);

                    _totalSupply -= _shares;
                    _balance -= _assets;

                    _puppetsAssets += _assets;
                }
            }

            uint256 _traderShares = _isExecuted ? _position.traderShares : _request.traderShares;
            uint256 _traderAssets = _convertToAssets(_balance, _totalSupply, _traderShares);

            IERC20(_route.collateralToken).safeTransfer(address(orchestrator), _puppetsAssets);
            IERC20(_route.collateralToken).safeTransfer(_route.trader, _traderAssets);
        }

        uint256 _ethBalance = address(this).balance;
        if ((_ethBalance - _traderAmountIn) > 0) {
            address _executionFeeReceiver = _isKeeperRequest ? orchestrator.keeper() : _route.trader;
            payable(_executionFeeReceiver).sendValue(_ethBalance - _traderAmountIn);
        }

        emit Repay(_totalAssets);
    }

    /// @notice The ```_setAdjustmentFlags``` function sets the adjustment flags, used by the Keeper to determine whether to adjust the position
    /// @dev This function is called by ```_repayBalance```
    /// @param _isAdjustmentRequired A boolean indicating whether the adjustment is required
    /// @param _isExecuted A boolean indicating whether the request was executed
    /// @param _isKeeperRequest A boolean indicating whether the request was made by a keeper
    function _setAdjustmentFlags(bool _isAdjustmentRequired, bool _isExecuted, bool _isKeeperRequest) internal {
        if ((!_isExecuted && _isAdjustmentRequired) || (_isExecuted && _isKeeperRequest)) {
            waitForKeeperAdjustment = false;
            targetLeverage = 0;
        } else if ((_isExecuted && _isAdjustmentRequired) || (!_isExecuted && _isKeeperRequest)) {
            _enableKeeperAdjustment = true;
        }
    }

    /// @notice The ```_resetRoute``` function is used to increment the position index, which is used to track the current position
    /// @dev This function is called by ```_repayBalance```, only if there's no open interest
    function _resetRoute() internal {
        _isPositionOpen = false;
        positionIndex += 1;

        emit Reset();
    }

    /// @notice The ```_approve``` function is used to approve a spender to spend a token
    /// @dev This function is called by ```_getTraderAssets``` and ```_requestIncreasePosition```
    /// @param _spender The address of the spender
    /// @param _token The address of the token
    /// @param _amount The amount of the token to approve
    function _approve(address _spender, address _token, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    // ============================================================================================
    // Internal View Functions
    // ============================================================================================

    /// @notice The ```_isOpenInterest``` function is used to indicate whether the Route has open interest
    /// @dev This function is called by ```liquidate```, ```_getPuppetsAssetsAndAllocateRequestShares``` and ```_repayBalance```
    /// @return bool A boolean indicating whether the Route has open interest
    function _isOpenInterest() internal view returns (bool) {
        Route memory _route = route;

        (uint256 _size, uint256 _collateral,,,,,,) = IGMXVault(orchestrator.gmxVault()).getPosition(
            address(this),
            _route.collateralToken,
            _route.indexToken,
            _route.isLong
        );

        return _size > 0 && _collateral > 0;
    }

    /// @notice The ```_getPositionAmounts``` function is used to get the current position's size and collateral
    /// @dev This function is called by ```_setTargetLeverage``` and ```requiredAdjustmentSize```
    /// @return _size The current position's size
    /// @return _collateral The current position's collateral 
    function _getPositionAmounts() internal view returns (uint256 _size, uint256 _collateral) {
        Route memory _route = route;

        (_size, _collateral,,,,,,) = IGMXVault(orchestrator.gmxVault()).getPosition(
            address(this),
            _route.collateralToken,
            _route.indexToken,
            _route.isLong
        );
    }

    /// @notice The ```_convertToShares``` function is used to convert an amount of assets to shares, given the total assets and total supply
    /// @param _totalAssets The total assets
    /// @param _totalSupply The total supply
    /// @param _assets The amount of assets to convert
    /// @return _shares The amount of shares
    function _convertToShares(uint256 _totalAssets, uint256 _totalSupply, uint256 _assets) internal pure returns (uint256 _shares) {
        if (_assets == 0) revert ZeroAmount();

        if (_totalAssets == 0) {
            _shares = _assets;
        } else {
            _shares = (_assets * _totalSupply) / _totalAssets;
        }

        if (_shares == 0) revert ZeroAmount();
    }

    /// @notice The ```_convertToAssets``` function is used to convert an amount of shares to assets, given the total assets and total supply
    /// @param _totalAssets The total assets
    /// @param _totalSupply The total supply
    /// @param _shares The amount of shares to convert
    /// @return _assets The amount of assets
    function _convertToAssets(uint256 _totalAssets, uint256 _totalSupply, uint256 _shares) internal pure returns (uint256 _assets) {
        if (_shares == 0) revert ZeroAmount();

        if (_totalSupply == 0) {
            _assets = _shares;
        } else {
            _assets = (_shares * _totalAssets) / _totalSupply;
        }

        if (_assets == 0) revert ZeroAmount();
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGMXRouter {

    function approvePlugin(address _plugin) external;

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    // require(_path[_path.length - 1] == weth
    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGMXPositionRouter {

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function executeIncreasePositions(
        uint256 _endIndex,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _endIndex,
        address payable _executionFeeReceiver
    ) external;

    function getRequestKey(
        address _account,
        uint256 _index
    ) external pure returns (bytes32);

    function getIncreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);

    function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGMXVault {

    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);

    function getPositionKey(address _account, address _collateralToken, address _indexToken, bool _isLong) external pure returns (bytes32);

    // returns:
    // 0: position.size
    // 1: position.collateral
    // 2: position.averagePrice
    // 3: position.entryFundingRate
    // 4: position.reserveAmount
    // 5: realisedPnl
    // 6: position.realisedPnl >= 0
    // 7: position.lastIncreasedTime
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ============== IPositionRouterCallbackReceiver ===============
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IPositionRouterCallbackReceiver {

    /// @notice The ```gmxPositionCallback``` is called on by GMX keepers after a position request is executed
    /// @param positionKey The position key
    /// @param isExecuted The boolean indicating if the position was executed
    /// @param isIncrease The boolean indicating if the position was increased
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// =========================== IRoute ===========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

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
        uint256 lastTraderAmountIn;
        uint256 traderShares;
        uint256 totalSupply;
        uint256 totalAssets;
        bytes32[] requestKeys;
        address[] puppets;
        uint256[] puppetsShares;
        uint256[] lastPuppetsAmountsIn;
    }

    struct AddCollateralRequest{
        bool isAdjustmentRequired;
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

    struct PuppetRequestInfo {
        bool isAdjustmentRequired;
        uint256 additionalAmount;
        uint256 additionalShares;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // Route Info

    /// @notice The ```trader``` function returns the trader address of the current route
    /// @return _trader The trader address
    function trader() external view returns (address _trader);

    /// @notice The ```collateralToken``` function returns the collateral token address of the current route
    /// @return _collateralToken The collateral token address
    function collateralToken() external view returns (address _collateralToken);

    /// @notice The ```indexToken``` function returns the index token address of the current route
    /// @return _indexToken The index token address
    function indexToken() external view returns (address _indexToken);

    /// @notice The ```isLong``` function returns the direction of the current route
    /// @return _isLong The direction of the current route
    function isLong() external view returns (bool _isLong);

    /// @notice The ```routeKey``` function returns the route key of the current route
    /// @return _routeKey The route key 
    function routeKey() external view returns (bytes32 _routeKey);

    // Position Info

    /// @notice The ```puppets``` function returns the puppets that are subscribed to the current position
    /// @return _puppets The address array of puppets
    function puppets() external view returns (address[] memory _puppets);

    /// @notice The ```participantShares``` function returns the shares of a participant in the current position
    /// @param _participant The participant address
    /// @return _shares The shares of the participant
    function participantShares(address _participant) external view returns (uint256 _shares);

    /// @notice The ```lastAmountIn``` function returns the latest collateral amount added by a participant to the current position
    /// @param _participant The participant address
    /// @return _amount The latest collateral amount added by the participant
    function lastAmountIn(address _participant) external view returns (uint256 _amount);

    /// @notice The ```isPositionOpen``` function indicates whether the Route's position should be open or closed
    /// @return _open Indicating whether the Route's position should be open or closed 
    function isPositionOpen() external view returns (bool _open);

    /// @notice The ```isAdjustmentEnabled``` function indicates if the route is enabled for keeper adjustment
    /// @return _enabled Indicating if the route is enabled for keeper adjustment
    function isAdjustmentEnabled() external view returns (bool _enabled);

    /// @notice The ```requiredAdjustmentSize``` function returns the required adjustment size for the route
    /// @notice If Puppets cannot pay the required amount when Trader adds collateral to an existing position, we need to decrease their size so the position's size/collateral ratio is as expected
    /// @notice This function is called by the Keeper when `targetLeverage` is set 
    /**
     @dev Returns the required adjustment size, USD denominated, with 30 decimals of precision, ready to be used by the Keeper.

     We get the required adjustment size by calculating the difference between the current position size and the target position size:
      - requiredAdjustmentSize = currentPositionSize - targetPositionSize
      -
      - targetPositionSize:
       - the position size needed to maintain the targetLeverage, with the actual collateral amount that was added by all participants (i.e. current collateral in position)
       - (targetPositionSize = currentCollateral * targetLeverage)
      -
      - currentPositionSize:
       - the position size that maintains the targetLeverage if all participants were to add the required collateral amount
       - (it's expected from Trader to input a `sizeDelta` that assumes all Puppets are adding the required amount of collateral)
    */
    /// @return _size The required adjustment size, USD denominated, with 30 decimals of precision
    function requiredAdjustmentSize() external view returns (uint256 _size);

    // Request Info

    /// @notice The ```puppetsRequestAmounts``` function returns the puppets amounts and shares for a given request
    /// @param _requestKey The request key
    /// @return _puppetsShares The total puppets shares
    /// @return _puppetsAmounts The total puppets amounts 
    function puppetsRequestAmounts(bytes32 _requestKey) external view returns (uint256[] memory _puppetsShares, uint256[] memory _puppetsAmounts);

    /// @notice The ```isWaitingForCallback``` function indicates if the route is waiting for a callback from GMX
    /// @return _waitingForCallback A boolean Indicating if the route is waiting for a callback from GMX
    function isWaitingForCallback() external view returns (bool _waitingForCallback);

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
    function rescueTokenFunds(uint256 _amount, address _token, address _receiver) external;

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
    event RescueTokenFunds(uint256 amount, address token, address receiver);
    event Freeze(bool indexed freeze);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error WaitingForKeeperAdjustment();
    error NotKeeper();
    error NotTrader();
    error InvalidExecutionFee();
    error InvalidPath();
    error PositionStillAlive();
    error PositionNotOpen();
    error Paused();
    error NotOrchestrator();
    error RouteFrozen();
    error NotCallbackCaller();
    error NotWaitingForKeeperAdjustment();
    error ZeroAmount();
    error KeeperAdjustmentDisabled();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ============================ Base ============================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

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

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IWETH {
    
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================== IOrchestrator =======================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

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
        address vaultPriceFeed;
        address router;
        address vault;
        address positionRouter;
        bool priceFeedMaximise;
        bool priceFeedIncludeAmmPrice;
    }

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // global

    /// @notice The ```keeper``` function returns the address of the Keeper
    /// @return _keeper The address of the Keeper
    function keeper() external view returns (address _keeper);

    /// @notice The ```referralCode``` function returns the referral code
    /// @return _referralCode The referral code
    function referralCode() external view returns (bytes32 _referralCode);

    /// @notice The ```routes``` function returns all the routes
    /// @return _routes The address array of all the routes
    function routes() external view returns (address[] memory _routes);

    /// @notice The ```paused``` function returns the paused state
    /// @return _paused The paused state
    function paused() external view returns (bool _paused);

    // route

    /// @notice The ```getRouteTypeKey``` function returns RouteType key for a given Route attributes
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return _routeTypeKey The RouteType key
    function getRouteTypeKey(address _collateralToken, address _indexToken, bool _isLong) external pure returns (bytes32 _routeTypeKey);

    /// @notice The ```getRouteKey``` function returns the Route key for a given RouteType key and Trader address
    /// @param _trader The address of the Trader
    /// @param _routeTypeKey The RouteType key
    /// @return _routeKey The Route key
    function getRouteKey(address _trader, bytes32 _routeTypeKey) external view returns (bytes32 _routeKey);

    /// @notice The ```getPositionKey``` function returns the Position key for a given Route, similar to what is stored in GMX
    /// @param _route The Route address
    /// @return _positionKey The Position key
    function getPositionKey(IRoute _route) external view returns (bytes32 _positionKey);

    /// @notice The ```subscribedPuppets``` function returns all the subscribed puppets for a given Route key
    /// @notice Those puppets may not be subscribed to the current Route's position
    /// @param _routeKey The Route key
    /// @return _puppets The address array of all the subscribed puppets
    function subscribedPuppets(bytes32 _routeKey) external view returns (address[] memory _puppets);

    /// @notice The ```getRoute``` function returns the Route address for a given Route key
    /// @param _routeKey The Route key
    /// @return _route The Route address
    function getRoute(bytes32 _routeKey) external view returns (address _route);

    /// @notice The ```getRoute``` function returns the Route address for a given Route attributes and Trader address
    /// @param _trader The address of the Trader
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return _route The Route address
    function getRoute(address _trader, address _collateralToken, address _indexToken, bool _isLong) external view returns (address _route);

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
    /// @return _balance The account balance
    function puppetAccountBalance(address _puppet, address _asset) external view returns (uint256 _balance);

    /// @notice The ```puppetThrottleLimit``` function returns the throttle limit for a given Puppet and RouteType
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    /// @return _balance The throttle limit
    function puppetThrottleLimit(address _puppet, bytes32 _routeType) external view returns (uint256 _balance);

    /// @notice The ```lastPositionOpenedTimestamp``` function returns the last position opened timestamp for a given Puppet and RouteType
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    /// @return _lastPositionOpenedTimestamp The last position opened timestamp
    function lastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external view returns (uint256 _lastPositionOpenedTimestamp);

    /// @notice The ```isBelowThrottleLimit``` function returns whether a given Puppet is below the throttle limit for a given RouteType
    /// @param _puppet The address of the Puppet
    /// @param _routeType The RouteType key
    /// @return _isBelowThrottleLimit Whether the Puppet is below the throttle limit
    function isBelowThrottleLimit(address _puppet, bytes32 _routeType) external view returns (bool _isBelowThrottleLimit);

    // gmx

    /// @notice The ```getPrice``` function returns the price for a given Token from the GMX vaultPriceFeed
    /// @notice prices are USD denominated with 30 decimals
    /// @param _token The address of the Token
    /// @return _price The price
    function getPrice(address _token) external view returns (uint256 _price);

    /// @notice The ```gmxVaultPriceFeed``` function returns the GMX vaultPriceFeed address
    /// @return _gmxVaultPriceFeed The GMX vaultPriceFeed address
    function gmxVaultPriceFeed() external view returns (address _gmxVaultPriceFeed);

    /// @notice The ```gmxInfo``` function returns the GMX Router address
    /// @return _router The GMX Router address
    function gmxRouter() external view returns (address _router);

    /// @notice The ```gmxPositionRouter``` function returns the GMX Position Router address
    /// @return _positionRouter The GMX Position Router address
    function gmxPositionRouter() external view returns (address _positionRouter);

    /// @notice The ```gmxVault``` function returns the GMX Vault address
    /// @return _vault The GMX Vault address
    function gmxVault() external view returns (address _vault);

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    // Trader

    /// @notice The ```createRoute``` function is called by a Trader to create a new Route
    /// @param _collateralToken The address of the Collateral Token
    /// @param _indexToken The address of the Index Token
    /// @param _isLong The boolean value of the position
    /// @return bytes32 The Route key
    function createRoute(address _collateralToken, address _indexToken, bool _isLong) external returns (bytes32);

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

    /// @notice The ```subscribeRoute``` function is called by a Puppet to update his subscription to a Route
    /// @param _allowance The allowance percentage
    /// @param _trader The address of the Trader
    /// @param _routeTypeKey The RouteType key
    /// @param _subscribe Whether to subscribe or unsubscribe
    function subscribeRoute(uint256 _allowance, address _trader, bytes32 _routeTypeKey, bool _subscribe) external;

    /// @notice The ```batchSubscribeRoute``` function is called by a Puppet to update his subscription to a list of Routes
    /// @param _allowances The allowance percentage array
    /// @param _traders The address array of Traders
    /// @param _routeTypeKeys The RouteType key array
    /// @param _subscribe Whether to subscribe or unsubscribe
    function batchSubscribeRoute(uint256[] memory _allowances, address[] memory _traders, bytes32[] memory _routeTypeKeys, bool[] memory _subscribe) external;

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

    /// @notice The ```transferRouteFunds``` function is called by a Route to send funds to a _receiver
    /// @param _amount The amount to send
    /// @param _asset The address of the Asset
    /// @param _receiver The address of the receiver
    function transferRouteFunds(uint256 _amount, address _asset, address _receiver) external;

    /// @notice The ```emitExecutionCallback``` function is called by a Route to emit an event on a GMX position execution callback
    /// @param _requestKey The request key
    /// @param _isExecuted The boolean indicating if the request is executed
    /// @param _isIncrease The boolean indicating if the request is an increase or decrease request
    function emitExecutionCallback(bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external;

    /// @notice The ```emitSharesIncrease``` function is called by a Route to emit an event on a successful add collateral request
    /// @param _puppetsShares The array of Puppets shares, corresponding to the Route's subscribed Puppets, as stored in the Route Position struct
    /// @param _traderShares The Trader's shares, as stored in the Route Position struct
    /// @param _totalSupply The total supply of the Route's shares
    function emitSharesIncrease(uint256[] memory _puppetsShares, uint256 _traderShares, uint256 _totalSupply) external;

    // Authority

    // called by keeper

    /// @notice The ```adjustTargetLeverage``` function is called by a keeper to adjust mirrored position to target leverage to match trader leverage
    /// @param _adjustPositionParams The adjusment params for the position
    /// @param _executionFee The total execution fee, paid by the Keeper in ETH
    /// @param _routeKey The Route key
    /// @return _requestKey The request key
    function adjustTargetLeverage(IRoute.AdjustPositionParams memory _adjustPositionParams, uint256 _executionFee, bytes32 _routeKey) external payable returns (bytes32 _requestKey);

    /// @notice The ```liquidatePosition``` function is called by Puppet keepers to reset the Route's accounting in case of a liquidation
    /// @param _routeKey The Route key
    function liquidatePosition(bytes32 _routeKey) external;

    // called by owner

    /// @notice The ```rescueTokens``` function is called by the Authority to rescue tokens from this contract
    /// @param _amount The amount to rescue
    /// @param _token The address of the Token
    /// @param _receiver The address of the receiver
    function rescueTokens(uint256 _amount, address _token, address _receiver) external;

    /// @notice The ```rescueRouteFunds``` function is called by the Authority to rescue tokens from a Route
    /// @param _amount The amount to rescue
    /// @param _token The address of the Token
    /// @param _receiver The address of the receiver
    /// @param _route The address of the Route
    function rescueRouteFunds(uint256 _amount, address _token, address _receiver, address _route) external;

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
    /// @param _vaultPriceFeed The address of the GMX Vault Price Feed
    /// @param _gmxRouter The address of the GMX Router
    /// @param _gmxVault The address of the GMX Vault
    /// @param _gmxPositionRouter The address of the GMX Position Router
    /// @param _priceFeedMaximise The boolean for the GMX Vault Price Feed `maximise` parameter
    /// @param _priceFeedIncludeAmmPrice The boolean for the GMX Vault Price Feed `includeAmmPrice` parameter
    function setGMXInfo(address _vaultPriceFeed, address _gmxRouter, address _gmxVault, address _gmxPositionRouter, bool _priceFeedMaximise, bool _priceFeedIncludeAmmPrice) external;

    /// @notice The ```setKeeper``` function is called by the Authority to set the Keeper address
    /// @param _keeperAddr The address of the new Keeper
    function setKeeper(address _keeperAddr) external;

    /// @notice The ```setReferralCode``` function is called by the Authority to set the referral code
    /// @param _refCode The new referral code
    function setReferralCode(bytes32 _refCode) external;

    /// @notice The ```setRouteFactory``` function is called by the Authority to set the Route Factory address
    /// @param _factory The address of the new Route Factory
    function setRouteFactory(address _factory) external;

    /// @notice The ```pause``` function is called by the Authority to pause all Routes
    /// @param _pause The new pause state
    function pause(bool _pause) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    event CreateRoute(address indexed trader, address indexed route, bytes32 indexed routeTypeKey);
    event SetRouteType(bytes32 routeTypeKey, address collateral, address index, bool isLong);

    event ApprovePlugin(address indexed caller, bytes32 indexed routeTypeKey);
    event SubscribeRoute(uint256 allowance, address indexed trader, address indexed puppet, bytes32 routeTypeKey, bool indexed subscribe);
    event SetThrottleLimit(address indexed puppet, bytes32 indexed routeType, uint256 throttleLimit);

    event UpdateOpenTimestamp(address indexed puppet, bytes32 indexed routeType, uint256 timestamp);
    
    event Deposit(uint256 indexed amount, address indexed asset, address caller, address indexed puppet);
    event Withdraw(uint256 amount, address indexed asset, address indexed receiver, address indexed puppet);

    event RequestPosition(address[] puppets, address indexed caller, bytes32 indexed routeTypeKey, bytes32 indexed positionKey);
    event ExecutePosition(address indexed route, bytes32 indexed requestKey, bool indexed isExecuted, bool isIncrease);
    event SharesIncrease(uint256[] puppetsShares, uint256 traderShares, uint256 totalSupply, bytes32 indexed positionKey);
    event AdjustTargetLeverage(bytes32 indexed requestKey, bytes32 indexed routeKey, bytes32 indexed positionKey);
    event LiquidatePosition(bytes32 indexed routeKey, bytes32 indexed positionKey);

    event DebitPuppet(uint256 amount, address indexed asset, address indexed puppet, address indexed caller);
    event CreditPuppet(uint256 amount, address indexed asset, address indexed puppet, address indexed caller);

    event TransferRouteFunds(uint256 amount, address indexed asset, address indexed receiver, address indexed caller);
    event SetGMXUtils(address vaultPriceFeed, address router, address vault, address positionRouter);
    event SetGMXUtils(address vaultPriceFeed, address router, address vault, address positionRouter, bool priceFeedMaximise, bool priceFeedIncludeAmmPrice);
    event Pause(bool paused);
    event SetReferralCode(bytes32 indexed referralCode);
    event SetRouteFactory(address indexed factory);
    event SetKeeper(address indexed keeper);
    event RescueRouteFunds(uint256 amount, address indexed token, address indexed receiver, address indexed route);
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