// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGroupOrderBookk {
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRouter {
    function addPlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVaultUtils.sol";

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IGroupOrderBookk.sol";

contract LeaderSellingOrderBook is ReentrancyGuard, IGroupOrderBookk {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    struct GroupOrder {
        uint256 orderId;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
        uint256 duration;
        uint256 expired;
        uint256 discount;
        uint256 threshold;
        uint256 commission;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyOrder {
        uint256 orderId;
        uint256 times;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
    }

    struct SubOrder {
        uint256 orderId;
        uint256 subOrderId;
        address account;
        address[] path;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuySubOrder {
        uint256 orderId;
        uint256 subOrderId;
        uint256 times;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
    }

    uint256 public listOrdersIndex; // index 1,2,3,4,5 all orders
    mapping(uint256 => GroupOrder) public listOrders; // index 1,2,3,4,5  -> GroupOrder
    mapping(address => mapping(uint256 => uint256)) public bigOrders; // big Trader -> 1,2,3,4,5 -> orderId
    mapping(address => uint256) public groupOrdersIndex; // index 1,2,3,4,5 of big Trader

    mapping(address => mapping(uint256 => uint256)) public listBuyOrders; // trader -> index 1,2,3,4,5 -> orderId
    mapping(address => uint256) public listBuyOrdersIndex; // index 1,2,3,4,5 of trader
    mapping(address => mapping(uint256 => BuyOrder)) public buyOrders; // trader -> orderId -> BuyOrder

    uint256 public listSubOrdersIndex; // index 1,2,3,4,5 all subOrders
    mapping(uint256 => SubOrder) public listSubOrders; // index 1,2,3,4,5  -> SubOrder
    mapping(uint256 => mapping(uint256 => uint256)) public subOrders; // orderId -> index 1,2,3,4,5 -> subOrderId
    mapping(uint256 => uint256) public subOrdersIndex; // index 1,2,3,4,5 all suborders of orderId

    mapping(address => mapping(uint256 => uint256)) public listBuySubOrders; // trader -> index 1,2,3,4,5 -> subOrderId
    mapping(address => uint256) public listBuySubOrdersIndex;
    mapping(address => mapping(uint256 => BuySubOrder)) public buySubOrders; // trader -> subOrderId -> BuyOrder
    mapping(uint256 => uint256) public countBuySubOrders;

    address public gov;
    address public weth;
    address public usdg;
    address public router;
    address public vault;
    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;

    event CreateGroupEvent(
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut,
        uint256 duration,
        uint256 expired,
        uint256 discount,
        uint256 threshold,
        uint256 commission
    );

    event BuyOrderEvent(
        uint256 orderId,
        uint256 buyOrderIndex,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event SubOrderEvent(
        uint256 orderId,
        uint256 subOrderId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event BuySubOrderEvent(
        uint256 orderId,
        uint256 subOrderId,
        uint256 buyOrderId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event Initialize(
        address router,
        address vault,
        address weth,
        address usdg,
        uint256 minExecutionFee,
        uint256 minPurchaseTokenAmountUsd
    );
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateMinPurchaseTokenAmountUsd(uint256 minPurchaseTokenAmountUsd);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        address _usdg,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        require(!isInitialized, "initialized");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        usdg = _usdg;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit Initialize(
            _router,
            _vault,
            _weth,
            _usdg,
            _minExecutionFee,
            _minPurchaseTokenAmountUsd
        );
    }

    receive() external payable {
        require(msg.sender == weth, "sender");
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinPurchaseTokenAmountUsd(
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;
        emit UpdateMinPurchaseTokenAmountUsd(_minPurchaseTokenAmountUsd);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit UpdateGov(_gov);
    }

    function getGroupOrder(
        uint256 offset,
        uint256 _limit
    ) public view returns (GroupOrder[] memory) {
        uint256 from = offset > 0 && offset <= listOrdersIndex
            ? listOrdersIndex - offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        GroupOrder[] memory items = new GroupOrder[](limit);
        for (uint256 i = 0; i < limit; i++) {
            GroupOrder memory item = listOrders[from - i];
            items[i] = item;
        }
        return items;
    }

    function getGroupOrderActive(
        uint256 offset,
        uint256 _limit
    ) public view returns (GroupOrder[] memory) {
        uint256 limit = _limit < listOrdersIndex ? _limit : listOrdersIndex;
        uint256 count = 0;
        GroupOrder[] memory items = new GroupOrder[](limit);
        for (uint256 i = listOrdersIndex; i > 0; i--) {
            GroupOrder memory item = listOrders[i];
            if (item.expired > block.timestamp) {
                count = count.add(1);
                if (count >= offset + limit) {
                    break;
                }
                if (count >= offset) {
                    items[count - offset] = item;
                }
            }
        }
        return items;
    }

    function getGroupOrderOwner(
        address account,
        uint256 offset,
        uint256 _limit
    ) public view returns (GroupOrder[] memory) {
        uint256 limit = _limit < listOrdersIndex ? _limit : listOrdersIndex;
        uint256 count = 0;
        GroupOrder[] memory items = new GroupOrder[](limit);
        for (uint256 i = listOrdersIndex; i > 0; i--) {
            GroupOrder memory item = listOrders[i];
            if (item.account == account) {
                count = count.add(1);
                if (count >= offset + limit) {
                    break;
                }
                if (count >= offset) {
                    items[count - offset] = item;
                }
            }
        }
        return items;
    }

    function getBuyOrderByAddress(
        address account,
        uint256 offset,
        uint256 _limit
    ) public view returns (BuyOrder[] memory, GroupOrder[] memory) {
        uint256 from = offset > 0 && offset <= listBuyOrdersIndex[msg.sender]
            ? listBuyOrdersIndex[msg.sender] - offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        BuyOrder[] memory items = new BuyOrder[](limit);
        GroupOrder[] memory groupItems = new GroupOrder[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 orderId = listBuyOrders[account][from - i];
            BuyOrder memory item = buyOrders[account][orderId];
            items[i] = item;
            GroupOrder memory groupItem = listOrders[orderId];
            groupItems[i] = groupItem;
        }
        return (items, groupItems);
    }

    function getBuySubOrderByAddress(
        address account,
        uint256 offset,
        uint256 _limit
    ) public view returns (BuySubOrder[] memory, GroupOrder[] memory) {
        uint256 from = offset > 0 && offset <= listBuyOrdersIndex[msg.sender]
            ? listBuyOrdersIndex[msg.sender] - offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        BuySubOrder[] memory items = new BuySubOrder[](limit);
        GroupOrder[] memory groupItems = new GroupOrder[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 subOrderId = listBuySubOrders[account][from - i];
            BuySubOrder memory item = buySubOrders[account][subOrderId];
            items[i] = item;
            GroupOrder memory groupItem = listOrders[item.orderId];
            groupItems[i] = groupItem;
        }
        return (items, groupItems);
    }

    function getSubGroupOrder(
        uint256 orderId,
        uint256 offset,
        uint256 _limit
    ) public view returns (SubOrder[] memory) {
        uint256 from = offset > 0 && offset <= subOrdersIndex[orderId]
            ? subOrdersIndex[orderId] - offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        SubOrder[] memory items = new SubOrder[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 subOrderId = subOrders[orderId][from - i];
            SubOrder memory item = listSubOrders[subOrderId];
            items[i] = item;
        }
        return items;
    }

    function getAmountOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 discount
    ) public view returns (uint256, uint256, uint256) {
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        uint256 priceIn = IVault(vault).getMinPrice(_tokenIn);
        uint256 priceOut = IVault(vault).getMinPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = IVault(vault).adjustForDecimals(
            amountOut,
            _tokenIn,
            _tokenOut
        );
        amountOut = amountOut.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.sub(discount)
        );
        return (priceIn, priceOut, amountOut);
    }

    function _wrapAndTransfer(
        uint256 _amountIn,
        address _path0,
        bool _shouldWrap
    ) private {
        if (_shouldWrap) {
            require(_path0 == weth, "weth");
            require(msg.value == _amountIn, "value");
        } else {
            IRouter(router).pluginTransfer(
                _path0,
                msg.sender,
                address(this),
                _amountIn
            );
        }
    }

    function createGroupOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 duration,
        uint256 discount,
        uint256 threshold,
        uint256 commission,
        bool _shouldWrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(_amountIn > 0, "amountIn");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        uint256 expired = duration + block.timestamp;
        uint256 amountOut;
        (, , amountOut) = getAmountOut(_amountIn, _path, 0);

        listOrdersIndex = listOrdersIndex.add(1);
        GroupOrder memory order = GroupOrder(
            listOrdersIndex,
            msg.sender,
            _path,
            _amountIn,
            amountOut,
            duration,
            expired,
            discount,
            threshold,
            commission,
            0,
            0
        );

        groupOrdersIndex[msg.sender] = groupOrdersIndex[msg.sender].add(1);
        bigOrders[msg.sender][groupOrdersIndex[msg.sender]] = listOrdersIndex;
        listOrders[listOrdersIndex] = order;

        emit CreateGroupEvent(
            msg.sender,
            _path,
            _amountIn,
            amountOut,
            duration,
            expired,
            discount,
            threshold,
            commission
        );
    }

    function validatePair(
        address[] memory _path,
        address[] memory _buyPath
    ) public pure {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(
            _buyPath.length == 2 || _buyPath.length == 3,
            "_buyPath.length"
        );
        require(_buyPath[0] != _buyPath[_buyPath.length - 1], "_buyPath");
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        address _buyTokenIn = _buyPath.length == 2 ? _buyPath[0] : _buyPath[1];
        address _buyTokenOut = _buyPath.length == 2 ? _buyPath[1] : _buyPath[2];
        require(_tokenIn == _buyTokenOut, "_buyTokenOut");
        require(_tokenOut == _buyTokenIn, "_buyTokenIn");
    }

    function createSubGroupOrder(
        uint256 orderId,
        address[] memory _path
    ) external payable nonReentrant {
        GroupOrder memory item = listOrders[orderId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        require(item.totalOut < item.amountIn, "soldout");

        _transferInETH();

        listSubOrdersIndex = listSubOrdersIndex.add(1);
        SubOrder memory subOrder = SubOrder(
            orderId,
            listSubOrdersIndex,
            msg.sender,
            _path,
            0,
            0
        );
        listSubOrders[listSubOrdersIndex] = subOrder;
        subOrdersIndex[orderId] = subOrdersIndex[orderId].add(1);
        subOrders[orderId][subOrdersIndex[orderId]] = listSubOrdersIndex;

        BuySubOrder memory buySubOrder = BuySubOrder(
            orderId,
            listSubOrdersIndex,
            1,
            msg.sender,
            _path,
            0,
            0
        );
        listBuySubOrdersIndex[msg.sender] = listBuySubOrdersIndex[msg.sender]
            .add(1);
        listBuySubOrders[msg.sender][
            listBuySubOrdersIndex[msg.sender]
        ] = listSubOrdersIndex;
        buySubOrders[msg.sender][listSubOrdersIndex] = buySubOrder;
        countBuySubOrders[listSubOrdersIndex] = 1;

        emit SubOrderEvent(
            orderId,
            listSubOrdersIndex,
            msg.sender,
            _path,
            0,
            0
        );
    }

    function placeSubGroupOrder(
        uint256 orderId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap,
        uint256 subOrderId
    ) external payable nonReentrant {
        GroupOrder memory item = listOrders[orderId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        SubOrder memory subOrder = listSubOrders[subOrderId];

        uint256 amountOut;
        (, , amountOut) = getAmountOut(_amountIn, _path, item.discount);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");

        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        subOrder.totalOut = subOrder.totalOut.add(amountOut);
        subOrder.totalIn = subOrder.totalIn.add(_amountIn);
        listSubOrders[subOrderId] = subOrder;
 
        item.totalOut = item.totalOut.add(subOrder.totalOut);
        item.totalIn = item.totalIn.add(subOrder.totalIn);
        listOrders[orderId] = item;

        BuySubOrder memory buySubOrder;
        if (buySubOrders[msg.sender][subOrderId].subOrderId > 0) {
            buySubOrder = buySubOrders[msg.sender][subOrderId];
            buySubOrder.amountIn = buySubOrder.amountIn.add(_amountIn);
            buySubOrder.amountOut = buySubOrder.amountOut.add(amountOut);
            buySubOrder.times = buySubOrder.times.add(1);
        } else {
            buySubOrder = BuySubOrder(
                orderId,
                subOrderId,
                1,
                msg.sender,
                _path,
                _amountIn,
                amountOut
            );
            listBuySubOrdersIndex[msg.sender] = listBuySubOrdersIndex[
                msg.sender
            ].add(1);
            listBuySubOrders[msg.sender][
                listBuySubOrdersIndex[msg.sender]
            ] = subOrderId;
            countBuySubOrders[subOrderId] = countBuySubOrders[subOrderId].add(
                1
            );
        }
        buySubOrders[msg.sender][subOrderId] = buySubOrder;

        emit BuySubOrderEvent(
            orderId,
            subOrderId,
            buySubOrder.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function leaderClaimOrder(uint256 orderId) external nonReentrant {
        GroupOrder memory item = listOrders[orderId];
        require(item.account == msg.sender, "owner");
        require(item.expired < block.timestamp, "expired");
        address _orderIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _orderOut = item.path.length == 2 ? item.path[1] : item.path[2];
        if (
            item.totalOut >=
            item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)
        ) {
            uint256 totalIn = item.totalIn;
            if (totalIn > 0) {
                listOrders[orderId].totalIn = 0;
                IERC20(_orderOut).safeTransfer(msg.sender, totalIn);
            }
            if (item.amountIn > item.totalOut) {
                uint256 remain = item.amountIn.sub(item.totalOut);
                listOrders[orderId].totalOut = listOrders[orderId].amountIn;
                IERC20(_orderIn).safeTransfer(msg.sender, remain);
            }
        } else {
            if (item.totalIn > 0 && item.amountIn > item.totalOut) {
                listOrders[orderId].totalIn = 0;
                listOrders[orderId].totalOut = item.amountIn;
                IERC20(_orderIn).safeTransfer(msg.sender, item.amountIn);
            }
        }
    }

    function ownerClaimOrder(uint256 orderId) external nonReentrant {
        GroupOrder memory item = listOrders[orderId];
        require(item.account == msg.sender, "owner");
        require(item.expired < block.timestamp, "expired");
        address _orderIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _orderOut = item.path.length == 2 ? item.path[1] : item.path[2];
        if (
            item.totalOut >=
            item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)
        ) {
            uint256 totalIn = item.totalIn;
            if (totalIn > 0) {
                listOrders[orderId].totalIn = 0;
                IERC20(_orderOut).safeTransfer(msg.sender, totalIn);
            }
            if (item.amountIn > item.totalOut) {
                uint256 remain = item.amountIn.sub(item.totalOut);
                listOrders[orderId].totalOut = listOrders[orderId].amountIn;
                IERC20(_orderIn).safeTransfer(msg.sender, remain);
            }
        } else {
            if (item.totalIn > 0 && item.amountIn > item.totalOut) {
                listOrders[orderId].totalIn = 0;
                listOrders[orderId].totalOut = item.amountIn;
                IERC20(_orderIn).safeTransfer(msg.sender, item.amountIn);
            }
        }
    }

    function getOwnerClaimOrder(
        uint256 orderId
    ) public view returns (address[] memory, uint256, uint256) {
        GroupOrder memory item = listOrders[orderId];
        if (
            item.totalOut >=
            item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)
        ) {
            uint256 remain = item.amountIn > item.totalOut
                ? item.amountIn.sub(item.totalOut)
                : 0;
            return (item.path, remain, item.totalIn);
        } else {
            return (item.path, item.amountIn, 0);
        }
    }

    function claimOrder(uint256 orderId) external nonReentrant {
        GroupOrder memory item = listOrders[orderId];
        require(item.expired < block.timestamp, "expired");
        BuyOrder memory buyOrder = buyOrders[msg.sender][orderId];
        require(buyOrder.orderId > 0, "buy");
        require(buyOrder.account == msg.sender, "buyer");
        require(buyOrder.amountOut > 0, "amountOut");
        if (
            item.totalOut >=
            item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)
        ) {
            address _orderIn = item.path.length == 2
                ? item.path[0]
                : item.path[1];
            buyOrders[msg.sender][orderId].amountOut = 0;
            IERC20(_orderIn).safeTransfer(msg.sender, buyOrder.amountOut);
        } else {
            address _orderOut = item.path.length == 2
                ? item.path[1]
                : item.path[2];
            buyOrders[msg.sender][orderId].amountOut = 0;
            IERC20(_orderOut).safeTransfer(msg.sender, buyOrder.amountIn);
        }
    }

    function getClaimOrder(
        uint256 orderId
    ) public view returns (address[] memory, uint256, uint256) {
        GroupOrder memory item = listOrders[orderId];
        BuyOrder memory buyOrder = buyOrders[msg.sender][orderId];
        if (
            item.totalOut >=
            item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)
        ) {
            return (item.path, buyOrder.amountOut, 0);
        } else {
            return (item.path, 0, buyOrder.amountIn);
        }
    }

    function claimSubOrder(
        uint256 orderId,
        uint256 subOrderId
    ) external nonReentrant {
        GroupOrder memory item = listOrders[orderId];
        require(item.expired < block.timestamp, "expired");
        require(
            item.totalOut >
                item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR),
            "totalIn"
        );

        BuySubOrder memory buySubOrder = buySubOrders[msg.sender][subOrderId];
        require(buySubOrder.subOrderId > 0, "buy");
        require(buySubOrder.account == msg.sender, "buyer");
        require(
            buySubOrders[msg.sender][subOrderId].amountOut > 0,
            "amountOut"
        );

        address _orderIn = item.path.length == 2 ? item.path[0] : item.path[1];
        uint256 amountOut = buySubOrders[msg.sender][subOrderId].amountOut;
        buySubOrders[msg.sender][subOrderId].amountOut = 0;
        IERC20(_orderIn).safeTransfer(msg.sender, amountOut);
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}