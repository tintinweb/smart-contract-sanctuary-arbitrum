// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibOrderBook.sol";
import "../interfaces/IReferralManager.sol";
import "../interfaces/ILiquidityCallback.sol";
import "./Types.sol";
import "./Admin.sol";

contract OrderBook is Storage, Admin, ReentrancyGuardUpgradeable {
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibOrder for LibOrder.OrderList;
    using LibOrder for bytes32[3];
    using LibOrder for PositionOrder;
    using LibOrder for LiquidityOrder;
    using LibOrder for WithdrawalOrder;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // do not forget to update LibOrderBook if this line updates
    event NewPositionOrder(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline // 1e0. 0 if market order. > 0 if limit order
    );
    // do not forget to update LibOrderBook if this line updates
    event NewLiquidityOrder(
        address indexed account,
        uint64 indexed orderId,
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    );
    event NewWithdrawalOrder(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit
    );
    event NewRebalanceOrder(
        address indexed rebalancer,
        uint64 indexed orderId,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData
    );
    event FillOrder(uint64 orderId, OrderType orderType, bytes32[3] orderData);
    // do not forget to update LibOrderBook if this line updates
    event CancelOrder(uint64 orderId, OrderType orderType, bytes32[3] orderData);
    // do not forget to update LibOrderBook if this line updates
    event NewPositionOrderExtra(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0. 0 if market order. > 0 if limit order
        PositionOrderExtra extra
    );

    function initialize(address pool, address mlp, address weth, address nativeUnwrapper) external initializer {
        __SafeOwnable_init();

        _storage.pool = ILiquidityPool(pool);
        _storage.mlp = IERC20Upgradeable(mlp);
        _storage.weth = IWETH(weth);
        _storage.nativeUnwrapper = INativeUnwrapper(nativeUnwrapper);
        _storage.maintainer = owner();
    }

    function getOrderCount() external view returns (uint256) {
        return _storage.orders.length();
    }

    /**
     * @notice Get an Order by orderId.
     */
    function getOrder(uint64 orderId) external view returns (bytes32[3] memory, bool) {
        return (_storage.orders.get(orderId), _storage.orders.contains(orderId));
    }

    function getOrders(
        uint256 begin,
        uint256 end
    ) external view returns (bytes32[3][] memory orderArray, uint256 totalCount) {
        totalCount = _storage.orders.length();
        if (begin >= end || begin >= totalCount) {
            return (orderArray, totalCount);
        }
        end = end <= totalCount ? end : totalCount;
        uint256 size = end - begin;
        orderArray = new bytes32[3][](size);
        for (uint256 i = 0; i < size; i++) {
            orderArray[i] = _storage.orders.at(i + begin);
        }
    }

    /**
     * @notice Open/close position. called by Trader.
     *
     *         Market order will expire after marketOrderTimeout seconds.
     *         Limit/Trigger order will expire after deadline.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  collateralAmount   deposit collateral before open; or withdraw collateral after close. decimals = erc20.decimals.
     * @param  size               position size. decimals = 18.
     * @param  price              limit price. decimals = 18.
     * @param  profitTokenId      specify the profitable asset.id when closing a position and making a profit.
     *                            take no effect when opening a position or loss.
     * @param  flags              a bitset of LibOrder.POSITION_*.
     *                            POSITION_OPEN                     this flag means openPosition; otherwise closePosition
     *                            POSITION_MARKET_ORDER             this flag means ignore limitPrice
     *                            POSITION_WITHDRAW_ALL_IF_EMPTY    this flag means auto withdraw all collateral if position.size == 0
     *                            POSITION_TRIGGER_ORDER            this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
     *                            POSITION_TPSL_STRATEGY            for open-position-order, this flag auto place take-profit and stop-loss orders when open-position-order fills.
     *                                                              for close-position-order, this flag means ignore limitPrice and profitTokenId, and use extra.tpPrice, extra.slPrice, extra.tpslProfitTokenId instead.
     * @param  deadline           a unix timestamp after which the limit/trigger order MUST NOT be filled. fill 0 for market order.
     * @param  referralCode       set referral code of the trading account.
     * @param  extra              more strategy like tp/sl.
     */
    function placePositionOrder3(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode,
        PositionOrderExtra memory extra
    ) public payable nonReentrant {
        address msgSender = _msgSender();
        address accountOwner = subAccountId.getSubAccountOwner();
        if (_storage.aggregators[msgSender]) {
            // we trust aggregator
        } else {
            // otherwise only account owner can place order
            require(accountOwner == msgSender, "SND"); // SeNDer is not authorized
        }
        if (referralCode != bytes32(0) && _storage.referralManager != address(0)) {
            IReferralManager(_storage.referralManager).setReferrerCodeFor(accountOwner, referralCode);
        }
        LibOrderBook.placePositionOrder(
            _storage,
            _blockTimestamp(),
            subAccountId,
            collateralAmount,
            size,
            price,
            profitTokenId,
            flags,
            deadline,
            extra
        );
    }

    /**
     * @notice Add/remove liquidity. called by Liquidity Provider.
     *
     *         Can be filled after liquidityLockPeriod seconds.
     * @param  assetId   asset.id that added/removed to.
     * @param  rawAmount asset token amount. decimals = erc20.decimals. note: when adding liquidity, rawAmount is
     *                   the amount of asset token; when removing liquidity, rawAmount is the amount of mlp token.
     * @param  isAdding  true for add liquidity, false for remove liquidity.
     */
    function placeLiquidityOrder(
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    ) external payable nonReentrant {
        address account = _msgSender();
        LibOrderBook.placeLiquidityOrder(_storage, _blockTimestamp(), account, assetId, rawAmount, isAdding);
    }

    /**
     * @notice Withdraw collateral/profit. called by Trader.
     *
     *         This order will expire after marketOrderTimeout seconds.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  rawAmount          collateral or profit asset amount. decimals = erc20.decimals.
     * @param  profitTokenId      specify the profitable asset.id.
     * @param  isProfit           true for withdraw profit. false for withdraw collateral.
     */
    function placeWithdrawalOrder(
        bytes32 subAccountId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit
    ) external nonReentrant {
        address trader = subAccountId.getSubAccountOwner();
        require(trader == _msgSender(), "SND"); // SeNDer is not authorized
        require(rawAmount != 0, "A=0"); // Amount Is Zero

        uint64 orderId = _storage.nextOrderId++;
        bytes32[3] memory data = LibOrder.encodeWithdrawalOrder(
            orderId,
            subAccountId,
            rawAmount,
            profitTokenId,
            isProfit,
            _blockTimestamp()
        );
        _storage.orders.add(orderId, data);

        emit NewWithdrawalOrder(subAccountId, orderId, rawAmount, profitTokenId, isProfit);
    }

    /**
     * @notice Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *         msg.sender must implement IMuxRebalancerCallback.
     * @param  tokenId0      asset.id to be swapped out of the pool.
     * @param  tokenId1      asset.id to be swapped into the pool.
     * @param  rawAmount0    token 0 amount. decimals = erc20.decimals.
     * @param  maxRawAmount1 max token 1 that rebalancer is willing to pay. decimals = erc20.decimals.
     * @param  userData      any user defined data.
     */
    function placeRebalanceOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) external onlyRebalancer nonReentrant {
        require(rawAmount0 != 0, "A=0"); // Amount Is Zero
        address rebalancer = _msgSender();
        uint64 orderId = _storage.nextOrderId++;
        bytes32[3] memory data = LibOrder.encodeRebalanceOrder(
            orderId,
            rebalancer,
            tokenId0,
            tokenId1,
            rawAmount0,
            maxRawAmount1,
            userData
        );
        _storage.orders.add(orderId, data);
        emit NewRebalanceOrder(rebalancer, orderId, tokenId0, tokenId1, rawAmount0, maxRawAmount1, userData);
    }

    /**
     * @dev   Open/close a position. called by Broker.
     *
     * @param orderId           order id.
     * @param collateralPrice   collateral price. decimals = 18.
     * @param assetPrice        asset price. decimals = 18.
     * @param profitAssetPrice  profit asset price. decimals = 18.
     */
    function fillPositionOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyBroker whenPositionOrderEnabled nonReentrant {
        require(_storage.orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _storage.orders.get(orderId);
        _storage.orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.PositionOrder, "TYP"); // order TYPe mismatch

        PositionOrder memory order = orderData.decodePositionOrder();
        require(_blockTimestamp() <= _positionOrderDeadline(order), "EXP"); // EXPired
        uint96 tradingPrice;
        if (order.isOpenPosition()) {
            tradingPrice = LibOrderBook.fillOpenPositionOrder(
                _storage,
                _blockTimestamp(),
                orderId,
                collateralPrice,
                assetPrice,
                order
            );
        } else {
            tradingPrice = LibOrderBook.fillClosePositionOrder(
                _storage,
                _blockTimestamp(),
                orderId,
                collateralPrice,
                assetPrice,
                profitAssetPrice,
                order
            );
        }
        // price check
        if (!order.isMarketOrder()) {
            // open,long      0,0   0,1   1,1   1,0
            // limitOrder     <=    >=    <=    >=
            // triggerOrder   >=    <=    >=    <=
            bool isLess = (order.subAccountId.isLong() == order.isOpenPosition());
            if (order.isTriggerOrder()) {
                isLess = !isLess;
            }
            if (isLess) {
                require(tradingPrice <= order.price, "LMT"); // LiMiTed by limitPrice
            } else {
                require(tradingPrice >= order.price, "LMT"); // LiMiTed by limitPrice
            }
        }

        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @dev   Add/remove liquidity. called by Broker.
     *
     *        Check _getLiquidityFeeRate in Liquidity.sol on how to calculate liquidity fee.
     * @param orderId           order id.
     * @param assetPrice        token price that added/removed to. decimals = 18.
     * @param mlpPrice          mlp price. decimals = 18.
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset). decimals = 18.
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains. decimals = 18.
     */
    function fillLiquidityOrder(
        uint64 orderId,
        uint96 assetPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external onlyBroker whenLiquidityOrderEnabled nonReentrant {
        require(_storage.orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _storage.orders.get(orderId);
        _storage.orders.remove(orderId);
        LiquidityOrder memory order = LibOrder.decodeLiquidityOrder(orderData);
        if (_storage.callbackWhitelist[order.account]) {
            bool isValid;
            try
                ILiquidityCallback(order.account).beforeFillLiquidityOrder{ gas: _callbackGasLimit() }(
                    order,
                    assetPrice,
                    mlpPrice,
                    currentAssetValue,
                    targetAssetValue
                )
            returns (bool _isValid) {
                isValid = _isValid;
            } catch {
                isValid = false;
            }
            if (!isValid) {
                _cancelLiquidityOrder(order);
                emit CancelOrder(orderId, LibOrder.getOrderType(orderData), orderData);
                return;
            }
        }
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.LiquidityOrder, "TYP"); // order TYPe mismatch
        uint256 mlpAmount;
        if (order.rawAmount != 0) {
            mlpAmount = LibOrderBook.fillLiquidityOrder(
                _storage,
                _blockTimestamp(),
                assetPrice,
                mlpPrice,
                currentAssetValue,
                targetAssetValue,
                orderData
            );
        } else {
            require(_storage.callbackWhitelist[order.account], "NCB");
            mlpAmount = 0;
        }
        if (_storage.callbackWhitelist[order.account]) {
            ILiquidityCallback(order.account).afterFillLiquidityOrder{ gas: _callbackGasLimit() }(
                order,
                mlpAmount,
                assetPrice,
                mlpPrice,
                currentAssetValue,
                targetAssetValue
            );
        }
        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @dev   Withdraw collateral/profit. called by Broker.
     *
     * @param orderId           order id.
     * @param collateralPrice   collateral price. decimals = 18.
     * @param assetPrice        asset price. decimals = 18.
     * @param profitAssetPrice  profit asset price. decimals = 18.
     */
    function fillWithdrawalOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyBroker nonReentrant {
        require(_storage.orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _storage.orders.get(orderId);
        _storage.orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.WithdrawalOrder, "TYP"); // order TYPe mismatch

        WithdrawalOrder memory order = orderData.decodeWithdrawalOrder();
        require(_blockTimestamp() <= order.placeOrderTime + _storage.marketOrderTimeout, "EXP"); // EXPired
        if (order.isProfit) {
            _storage.pool.withdrawProfit(
                order.subAccountId,
                order.rawAmount,
                order.profitTokenId,
                collateralPrice,
                assetPrice,
                profitAssetPrice
            );
        } else {
            _storage.pool.withdrawCollateral(order.subAccountId, order.rawAmount, collateralPrice, assetPrice);
        }

        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @dev   Rebalance. called by Broker.
     *
     * @param orderId  order id.
     * @param price0   price of token 0. decimals = 18.
     * @param price1   price of token 1. decimals = 18.
     */
    function fillRebalanceOrder(
        uint64 orderId,
        uint96 price0,
        uint96 price1
    ) external onlyBroker whenLiquidityOrderEnabled nonReentrant {
        require(_storage.orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _storage.orders.get(orderId);
        _storage.orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.RebalanceOrder, "TYP"); // order TYPe mismatch

        RebalanceOrder memory order = orderData.decodeRebalanceOrder();
        _storage.pool.rebalance(
            order.rebalancer,
            order.tokenId0,
            order.tokenId1,
            order.rawAmount0,
            order.maxRawAmount1,
            order.userData,
            price0,
            price1
        );

        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @notice Cancel an Order by orderId.
     */
    function cancelOrder(uint64 orderId) external nonReentrant {
        require(_storage.orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _storage.orders.get(orderId);
        _storage.orders.remove(orderId);
        address account = orderData.getOrderOwner();
        OrderType orderType = LibOrder.getOrderType(orderData);
        if (orderType == OrderType.PositionOrder) {
            PositionOrder memory order = orderData.decodePositionOrder();
            if (_storage.brokers[_msgSender()]) {
                require(_blockTimestamp() > _positionOrderDeadline(order), "EXP"); // not EXPired yet
            } else {
                require(_msgSender() == account, "SND"); // SeNDer is not authorized
            }
            if (order.isOpenPosition() && order.collateral > 0) {
                address collateralAddress = _storage.pool.getAssetAddress(
                    order.subAccountId.getSubAccountCollateralId()
                );
                LibOrderBook._transferOut(_storage, collateralAddress, account, order.collateral);
            }
            // tp/sl strategy
            delete _storage.positionOrderExtras[orderId];
            _storage.activatedTpslOrders[order.subAccountId].remove(uint256(orderId));
        } else if (orderType == OrderType.LiquidityOrder) {
            require(_msgSender() == account, "SND"); // SeNDer is not authorized
            LiquidityOrder memory order = orderData.decodeLiquidityOrder();
            _cancelLiquidityOrder(order);
        } else if (orderType == OrderType.WithdrawalOrder) {
            if (_storage.brokers[_msgSender()]) {
                WithdrawalOrder memory order = orderData.decodeWithdrawalOrder();
                uint256 deadline = order.placeOrderTime + _storage.marketOrderTimeout;
                require(_blockTimestamp() > deadline, "EXP"); // not EXPired yet
            } else {
                require(_msgSender() == account, "SND"); // SeNDer is not authorized
            }
        } else if (orderType == OrderType.RebalanceOrder) {
            require(_msgSender() == account, "SND"); // SeNDer is not authorized
        } else {
            revert();
        }
        emit CancelOrder(orderId, LibOrder.getOrderType(orderData), orderData);
    }

    function _cancelLiquidityOrder(LiquidityOrder memory order) internal {
        if (order.isAdding) {
            address collateralAddress = _storage.pool.getAssetAddress(order.assetId);
            LibOrderBook._transferOut(_storage, collateralAddress, order.account, order.rawAmount);
        } else {
            _storage.mlp.safeTransfer(order.account, order.rawAmount);
        }
        if (_storage.callbackWhitelist[order.account]) {
            try
                ILiquidityCallback(order.account).afterCancelLiquidityOrder{ gas: _callbackGasLimit() }(order)
            {} catch {}
        }
    }

    /**
     * @notice Trader can withdraw all collateral only when position = 0.
     */
    function withdrawAllCollateral(bytes32 subAccountId) external {
        require(subAccountId.getSubAccountOwner() == _msgSender(), "SND"); // SeNDer is not authorized
        _storage.pool.withdrawAllCollateral(subAccountId);
    }

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _getFundingRate in Liquidity.sol on how to calculate funding rate.
     * @param  stableUtilization    Stable coin utilization in all chains. decimals = 5.
     * @param  unstableTokenIds     All unstable Asset id(s) MUST be passed in order. ex: 1, 2, 5, 6, ...
     * @param  unstableUtilizations Unstable Asset utilizations in all chains decimals = 5.
     * @param  unstablePrices       Unstable Asset prices decimals = 18.
     */
    function updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices // 1e18
    ) external onlyBroker {
        _storage.pool.updateFundingState(stableUtilization, unstableTokenIds, unstableUtilizations, unstablePrices);
    }

    /**
     * @notice Deposit collateral into a subAccount.
     *
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  collateralAmount   collateral amount. decimals = erc20.decimals.
     */
    function depositCollateral(bytes32 subAccountId, uint256 collateralAmount) external payable {
        LibSubAccount.DecodedSubAccountId memory account = subAccountId.decodeSubAccountId();
        require(account.account == _msgSender(), "SND"); // SeNDer is not authorized
        require(collateralAmount != 0, "C=0"); // Collateral Is Zero
        address collateralAddress = _storage.pool.getAssetAddress(account.collateralId);
        LibOrderBook._transferIn(_storage, _msgSender(), collateralAddress, address(_storage.pool), collateralAmount);
        _storage.pool.depositCollateral(subAccountId, collateralAmount);
    }

    function liquidate(
        bytes32 subAccountId,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyBroker {
        _storage.pool.liquidate(subAccountId, profitAssetId, collateralPrice, assetPrice, profitAssetPrice);
        // auto withdraw
        (uint96 collateral, , , , ) = _storage.pool.getSubAccount(subAccountId);
        if (collateral > 0) {
            _storage.pool.withdrawAllCollateral(subAccountId);
        }
        // cancel activated tp/sl orders
        LibOrderBook.cancelActivatedTpslOrders(_storage, subAccountId);
    }

    function redeemMuxToken(uint8 tokenId, uint96 muxTokenAmount) external {
        address trader = _msgSender();
        LibOrderBook.redeemMuxToken(_storage, trader, tokenId, muxTokenAmount);
    }

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate() external onlyBroker returns (uint256 rawAmount) {
        return _storage.pool.claimBrokerGasRebate(msg.sender);
    }

    function _callbackGasLimit() internal view returns (uint256) {
        return _storage.callbackGasLimit == 0 ? gasleft() : _storage.callbackGasLimit;
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _positionOrderDeadline(PositionOrder memory order) internal view returns (uint32) {
        if (order.isMarketOrder()) {
            return order.placeOrderTime + _storage.marketOrderTimeout;
        } else {
            return order.placeOrderTime + LibMath.min32(uint32(order.expire10s) * 10, _storage.maxLimitOrderTimeout);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";

/**
 * SubAccountId
 *         96             88        80       72        0
 * +---------+--------------+---------+--------+--------+
 * | Account | collateralId | assetId | isLong | unused |
 * +---------+--------------+---------+--------+--------+
 */
library LibSubAccount {
    bytes32 constant SUB_ACCOUNT_ID_FORBIDDEN_BITS = bytes32(uint256(0xffffffffffffffffff));

    function getSubAccountOwner(bytes32 subAccountId) internal pure returns (address account) {
        account = address(uint160(uint256(subAccountId) >> 96));
    }

    function getSubAccountCollateralId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 88);
    }

    function getSubAccountAssetId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 80);
    }

    function isLong(bytes32 subAccountId) internal pure returns (bool) {
        return uint8((uint256(subAccountId) >> 72)) > 0;
    }

    struct DecodedSubAccountId {
        address account;
        uint8 collateralId;
        uint8 assetId;
        bool isLong;
    }

    function decodeSubAccountId(bytes32 subAccountId) internal pure returns (DecodedSubAccountId memory decoded) {
        require((subAccountId & SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        decoded.account = address(uint160(uint256(subAccountId) >> 96));
        decoded.collateralId = uint8(uint256(subAccountId) >> 88);
        decoded.assetId = uint8(uint256(subAccountId) >> 80);
        decoded.isLong = uint8((uint256(subAccountId) >> 72)) > 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

library LibMath {
    function min(uint96 a, uint96 b) internal pure returns (uint96) {
        return a <= b ? a : b;
    }

    function min32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a <= b ? a : b;
    }

    function max32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a >= b ? a : b;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e18;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e5;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * 1e18) / b;
    }

    function safeUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "O32"); // uint32 Overflow
        return uint32(n);
    }

    function safeUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "O96"); // uint96 Overflow
        return uint96(n);
    }

    function safeUint128(uint256 n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "O12"); // uint128 Overflow
        return uint128(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../interfaces/IReferralManager.sol";
import "../orderbook/Types.sol";
import "../orderbook/Storage.sol";

library LibOrderBook {
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibOrder for LibOrder.OrderList;
    using LibOrder for bytes32[3];
    using LibOrder for PositionOrder;
    using LibOrder for LiquidityOrder;
    using LibOrder for WithdrawalOrder;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using LibMath for uint256;

    // do not forget to update OrderBook if this line updates
    event CancelOrder(uint64 orderId, OrderType orderType, bytes32[3] orderData);
    // do not forget to update OrderBook if this line updates
    event NewLiquidityOrder(
        address indexed account,
        uint64 indexed orderId,
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    );
    // do not forget to update OrderBook if this line updates
    event NewPositionOrder(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline // 1e0. 0 if market order. > 0 if limit order
    );
    // do not forget to update OrderBook if this line updates
    event NewPositionOrderExtra(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0. 0 if market order. > 0 if limit order
        PositionOrderExtra extra
    );

    function _transferIn(
        OrderBookStorage storage _storage,
        address trader,
        address tokenAddress,
        address recipient,
        uint256 rawAmount
    ) internal {
        if (tokenAddress == address(_storage.weth)) {
            require(msg.value > 0 && msg.value == rawAmount, "VAL"); // transaction VALue SHOULD equal to rawAmount
            _storage.weth.deposit{ value: rawAmount }();
            if (recipient != address(this)) {
                _storage.weth.transfer(recipient, rawAmount);
            }
        } else {
            require(msg.value == 0, "VAL"); // transaction VALue SHOULD be 0
            IERC20Upgradeable(tokenAddress).safeTransferFrom(trader, recipient, rawAmount);
        }
    }

    function _transferOut(
        OrderBookStorage storage _storage,
        address tokenAddress,
        address recipient,
        uint256 rawAmount
    ) internal {
        if (tokenAddress == address(_storage.weth)) {
            _storage.weth.transfer(address(_storage.nativeUnwrapper), rawAmount);
            INativeUnwrapper(_storage.nativeUnwrapper).unwrap(payable(recipient), rawAmount);
        } else {
            IERC20Upgradeable(tokenAddress).safeTransfer(recipient, rawAmount);
        }
    }

    function placeLiquidityOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        address account,
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    ) external {
        // require(rawAmount != 0, "A=0"); // Amount Is Zero
        if (rawAmount != 0) {
            if (isAdding) {
                address collateralAddress = _storage.pool.getAssetAddress(assetId);
                _transferIn(_storage, account, collateralAddress, address(this), rawAmount);
            } else {
                _storage.mlp.safeTransferFrom(account, address(this), rawAmount);
            }
        } else {
            require(_storage.callbackWhitelist[account], "NCB");
        }
        uint64 orderId = _storage.nextOrderId++;
        bytes32[3] memory data = LibOrder.encodeLiquidityOrder(
            orderId,
            account,
            assetId,
            rawAmount,
            isAdding,
            blockTimestamp
        );
        _storage.orders.add(orderId, data);

        emit NewLiquidityOrder(account, orderId, assetId, rawAmount, isAdding);
    }

    function fillLiquidityOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        uint96 assetPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue,
        bytes32[3] memory orderData
    ) external returns (uint256 outAmount) {
        LiquidityOrder memory order = orderData.decodeLiquidityOrder();
        require(blockTimestamp >= order.placeOrderTime + _storage.liquidityLockPeriod, "LCK"); // mlp token is LoCKed
        uint96 rawAmount = order.rawAmount;
        if (order.isAdding) {
            IERC20Upgradeable collateral = IERC20Upgradeable(_storage.pool.getAssetAddress(order.assetId));
            collateral.safeTransfer(address(_storage.pool), rawAmount);
            outAmount = _storage.pool.addLiquidity(
                order.account,
                order.assetId,
                rawAmount,
                assetPrice,
                mlpPrice,
                currentAssetValue,
                targetAssetValue
            );
        } else {
            _storage.mlp.safeTransfer(address(_storage.pool), rawAmount);
            outAmount = _storage.pool.removeLiquidity(
                order.account,
                rawAmount,
                order.assetId,
                assetPrice,
                mlpPrice,
                currentAssetValue,
                targetAssetValue
            );
        }
    }

    function redeemMuxToken(
        OrderBookStorage storage _storage,
        address trader,
        uint8 tokenId,
        uint96 muxTokenAmount
    ) external {
        Asset memory asset = _storage.pool.getAssetInfo(tokenId);
        _transferIn(_storage, trader, asset.muxTokenAddress, address(_storage.pool), muxTokenAmount);
        _storage.pool.redeemMuxToken(trader, tokenId, muxTokenAmount);
    }

    function cancelActivatedTpslOrders(OrderBookStorage storage _storage, bytes32 subAccountId) public {
        EnumerableSetUpgradeable.UintSet storage orderIds = _storage.activatedTpslOrders[subAccountId];
        uint256 length = orderIds.length();
        for (uint256 i = 0; i < length; i++) {
            uint64 orderId = uint64(orderIds.at(i));
            require(_storage.orders.contains(orderId), "OID"); // can not find this OrderID
            bytes32[3] memory orderData = _storage.orders.get(orderId);
            _storage.orders.remove(orderId);

            OrderType orderType = LibOrder.getOrderType(orderData);
            require(orderType == OrderType.PositionOrder, "TYP"); // order TYPe mismatch

            PositionOrder memory order = orderData.decodePositionOrder();
            require(!order.isOpenPosition() && order.collateral == 0, "CLS"); // should be CLoSe position order and no withdraw

            delete _storage.positionOrderExtras[orderId]; // tp/sl strategy

            emit CancelOrder(orderId, orderType, orderData);
        }

        delete _storage.activatedTpslOrders[subAccountId]; // tp/sl strategy
    }

    function placePositionOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        PositionOrderExtra memory extra
    ) external {
        require(size != 0, "S=0"); // order Size Is Zero
        if ((flags & LibOrder.POSITION_MARKET_ORDER) != 0) {
            require(price == 0, "P!0"); // market order does not need a limit Price
            require(deadline == 0, "D!0"); // market order does not need a deadline
        } else {
            require(deadline > blockTimestamp, "D<0"); // Deadline is earlier than now
        }
        if (profitTokenId > 0) {
            // note: profitTokenId == 0 is also valid, this only partially protects the function from misuse
            require((flags & LibOrder.POSITION_OPEN) == 0, "T!0"); // opening position does not need a profit Token id
        }
        if ((flags & LibOrder.POSITION_OPEN) != 0) {
            _placeOpenPositionOrder(
                _storage,
                blockTimestamp,
                subAccountId,
                collateralAmount,
                size,
                price,
                flags,
                deadline,
                extra
            );
        } else {
            _placeClosePositionOrder(
                _storage,
                blockTimestamp,
                subAccountId,
                collateralAmount,
                size,
                price,
                profitTokenId,
                flags,
                deadline,
                extra
            );
        }
    }

    function _placeOpenPositionOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 flags,
        uint32 deadline, // 1e0
        PositionOrderExtra memory extra
    ) private {
        // add order
        uint64 orderId = _placePositionOrder(
            _storage,
            blockTimestamp,
            deadline,
            PositionOrder({
                id: 0, // ignored
                subAccountId: subAccountId,
                collateral: collateralAmount,
                size: size,
                price: price,
                profitTokenId: 0, // open-position-order does not have a profitTokenId
                flags: flags,
                placeOrderTime: 0, // ignored
                expire10s: 0 // ignored
            })
        );
        // fetch collateral
        if (collateralAmount > 0) {
            address accountOwner = subAccountId.getSubAccountOwner();
            uint8 collateralId = subAccountId.getSubAccountCollateralId();
            address collateralAddress = _storage.pool.getAssetAddress(collateralId);
            _transferIn(_storage, accountOwner, collateralAddress, address(this), collateralAmount);
        }
        if ((flags & LibOrder.POSITION_TPSL_STRATEGY) != 0) {
            // tp/sl strategy
            require((extra.tpPrice > 0 || extra.slPrice > 0), "TPSL"); // TP/SL strategy need tpPrice and/or slPrice
            require(extra.tpslDeadline > blockTimestamp, "D<0"); // Deadline is earlier than now
            require((extra.tpslDeadline - blockTimestamp) / 10 <= type(uint24).max, "DTL"); // Deadline is Too Large
            _storage.positionOrderExtras[orderId] = extra;
            emit NewPositionOrderExtra(
                subAccountId,
                orderId,
                collateralAmount,
                size,
                price,
                0 /* profitTokenId */,
                flags,
                deadline,
                extra
            );
        }
    }

    function _placeClosePositionOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        PositionOrderExtra memory extra
    ) private {
        if ((flags & LibOrder.POSITION_TPSL_STRATEGY) != 0) {
            // tp/sl strategy
            require(price == 0, "P!0"); // use extra.tpPrice and extra.slPrice instead
            require(collateralAmount == 0, "C!0"); // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
            require(profitTokenId == 0, "T!0"); // use extra.tpProfitTokenId instead
            require((flags & LibOrder.POSITION_MARKET_ORDER) == 0, "MKT"); // tp/sl strategy does not support MarKeT order
            require(extra.tpPrice > 0 && extra.slPrice > 0, "TPSL"); // tp/sl strategy need tpPrice and slPrice. otherwise use POSITION_TRIGGER_ORDER instead
            require(extra.tpslDeadline > blockTimestamp, "D<0"); // Deadline is earlier than now
            require((extra.tpslDeadline - blockTimestamp) / 10 <= type(uint24).max, "DTL"); // Deadline is Too Large
            _placeTpslOrdersWhenClose(_storage, blockTimestamp, subAccountId, size, extra);
        } else {
            // normal close-position-order
            if (flags & LibOrder.POSITION_SHOULD_REACH_MIN_PROFIT != 0) {
                // POSITION_MUST_PROFIT is only available if asset.minProfitTime > 0
                uint8 assetId = subAccountId.getSubAccountAssetId();
                Asset memory asset = _storage.pool.getAssetInfo(assetId);
                require(asset.minProfitTime > 0, "MPT"); // asset MinProfitTime is 0
            }
            _placePositionOrder(
                _storage,
                blockTimestamp,
                deadline,
                PositionOrder({
                    id: 0, // ignored
                    subAccountId: subAccountId,
                    collateral: collateralAmount,
                    size: size,
                    price: price,
                    profitTokenId: profitTokenId,
                    flags: flags,
                    placeOrderTime: 0, // ignored
                    expire10s: 0 // ignored
                })
            );
        }
    }

    function _placePositionOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        uint32 deadline, // 1e0. NOTE: deadline should be 0 for market order; > _blockTimestamp() for limit/trigger order
        PositionOrder memory order // NOTE: id, placeOrderTime, expire10s will be ignored
    ) private returns (uint64 newOrderId) {
        uint32 expire10s;
        if (deadline > 0) {
            expire10s = (deadline - blockTimestamp) / 10;
            require(expire10s <= type(uint24).max, "DTL"); // Deadline is Too Large
        }
        newOrderId = _storage.nextOrderId++;
        bytes32[3] memory newOrderData = LibOrder.encodePositionOrder(
            newOrderId,
            order.subAccountId,
            order.collateral,
            order.size,
            order.price,
            order.profitTokenId,
            order.flags,
            blockTimestamp,
            uint24(expire10s)
        );
        _storage.orders.add(newOrderId, newOrderData);
        emit NewPositionOrder(
            order.subAccountId,
            newOrderId,
            order.collateral,
            order.size,
            order.price,
            order.profitTokenId,
            order.flags,
            deadline
        );
    }

    function fillOpenPositionOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        PositionOrder memory order
    ) external returns (uint96 tradingPrice) {
        // auto deposit
        uint96 collateralAmount = order.collateral;
        if (collateralAmount > 0) {
            IERC20Upgradeable collateral = IERC20Upgradeable(
                _storage.pool.getAssetAddress(order.subAccountId.getSubAccountCollateralId())
            );
            collateral.safeTransfer(address(_storage.pool), collateralAmount);
            _storage.pool.depositCollateral(order.subAccountId, collateralAmount);
        }
        // open
        tradingPrice = _storage.pool.openPosition(order.subAccountId, order.size, collateralPrice, assetPrice);
        // tp/sl strategy
        if (order.isTpslStrategy()) {
            PositionOrderExtra memory extra = _storage.positionOrderExtras[orderId];
            delete _storage.positionOrderExtras[orderId];
            _placeTpslOrdersWhenOpen(_storage, blockTimestamp, order, extra);
        }
    }

    function fillClosePositionOrder(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice, // only used when !isLong
        PositionOrder memory order
    ) external returns (uint96 tradingPrice) {
        // check min profit
        SubAccount memory oldSubAccount;
        if (order.shouldReachMinProfit()) {
            (
                oldSubAccount.collateral,
                oldSubAccount.size,
                oldSubAccount.lastIncreasedTime,
                oldSubAccount.entryPrice,
                oldSubAccount.entryFunding
            ) = _storage.pool.getSubAccount(order.subAccountId);
        }
        // close
        tradingPrice = _storage.pool.closePosition(
            order.subAccountId,
            order.size,
            order.profitTokenId,
            collateralPrice,
            assetPrice,
            profitAssetPrice
        );
        // check min profit
        if (order.shouldReachMinProfit()) {
            require(_hasPassMinProfit(_storage, order, blockTimestamp, oldSubAccount, tradingPrice), "PFT"); // order must have ProFiT
        }
        // auto withdraw
        uint96 collateralAmount = order.collateral;
        if (collateralAmount > 0) {
            _storage.pool.withdrawCollateral(order.subAccountId, collateralAmount, collateralPrice, assetPrice);
        }
        // tp/sl strategy
        _storage.activatedTpslOrders[order.subAccountId].remove(uint256(orderId));
        // is the position completely closed
        (uint96 collateral, uint96 size, , , ) = _storage.pool.getSubAccount(order.subAccountId);
        if (size == 0) {
            // auto withdraw
            if (order.isWithdrawIfEmpty() && collateral > 0) {
                _storage.pool.withdrawAllCollateral(order.subAccountId);
            }

            // cancel activated tp/sl orders
            cancelActivatedTpslOrders(_storage, order.subAccountId);
        }
    }

    function _placeTpslOrdersWhenOpen(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        PositionOrder memory order,
        PositionOrderExtra memory extra
    ) private {
        if (extra.tpPrice > 0) {
            uint8 flags = LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY;
            uint8 assetId = order.subAccountId.getSubAccountAssetId();
            Asset memory asset = _storage.pool.getAssetInfo(assetId);
            if (asset.minProfitTime > 0) {
                flags |= LibOrder.POSITION_SHOULD_REACH_MIN_PROFIT;
            }
            uint64 orderId = _placePositionOrder(
                _storage,
                blockTimestamp,
                extra.tpslDeadline,
                PositionOrder({
                    id: 0, // ignored
                    subAccountId: order.subAccountId,
                    collateral: 0, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                    size: order.size,
                    price: extra.tpPrice,
                    profitTokenId: extra.tpslProfitTokenId,
                    flags: flags,
                    placeOrderTime: 0, // ignored
                    expire10s: 0 // ignored
                })
            );
            _storage.activatedTpslOrders[order.subAccountId].add(uint256(orderId));
        }
        if (extra.slPrice > 0) {
            uint64 orderId = _placePositionOrder(
                _storage,
                blockTimestamp,
                extra.tpslDeadline,
                PositionOrder({
                    id: 0, // ignored
                    subAccountId: order.subAccountId,
                    collateral: 0, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                    size: order.size,
                    price: extra.slPrice,
                    profitTokenId: extra.tpslProfitTokenId,
                    flags: LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY | LibOrder.POSITION_TRIGGER_ORDER,
                    placeOrderTime: 0, // ignored
                    expire10s: 0 // ignored
                })
            );
            _storage.activatedTpslOrders[order.subAccountId].add(uint256(orderId));
        }
    }

    function _placeTpslOrdersWhenClose(
        OrderBookStorage storage _storage,
        uint32 blockTimestamp,
        bytes32 subAccountId,
        uint96 size, // 1e18
        PositionOrderExtra memory extra
    ) private {
        if (extra.tpPrice > 0) {
            uint8 flags = LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY;
            uint8 assetId = subAccountId.getSubAccountAssetId();
            Asset memory asset = _storage.pool.getAssetInfo(assetId);
            if (asset.minProfitTime > 0) {
                flags |= LibOrder.POSITION_SHOULD_REACH_MIN_PROFIT;
            }
            uint64 orderId = _placePositionOrder(
                _storage,
                blockTimestamp,
                extra.tpslDeadline,
                PositionOrder({
                    id: 0, // ignored
                    subAccountId: subAccountId,
                    collateral: 0, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                    size: size,
                    price: extra.tpPrice,
                    profitTokenId: extra.tpslProfitTokenId,
                    flags: flags,
                    placeOrderTime: 0, // ignored
                    expire10s: 0 // ignored
                })
            );
            _storage.activatedTpslOrders[subAccountId].add(uint256(orderId));
        }
        if (extra.slPrice > 0) {
            uint64 orderId = _placePositionOrder(
                _storage,
                blockTimestamp,
                extra.tpslDeadline,
                PositionOrder({
                    id: 0, // ignored
                    subAccountId: subAccountId,
                    collateral: 0, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                    size: size,
                    price: extra.slPrice,
                    profitTokenId: extra.tpslProfitTokenId,
                    flags: LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY | LibOrder.POSITION_TRIGGER_ORDER,
                    placeOrderTime: 0, // ignored
                    expire10s: 0 // ignored
                })
            );
            _storage.activatedTpslOrders[subAccountId].add(uint256(orderId));
        }
    }

    function _hasPassMinProfit(
        OrderBookStorage storage _storage,
        PositionOrder memory order,
        uint32 blockTimestamp,
        SubAccount memory oldSubAccount,
        uint96 tradingPrice
    ) private view returns (bool) {
        if (oldSubAccount.size == 0) {
            return true;
        }
        LibSubAccount.DecodedSubAccountId memory decoded = order.subAccountId.decodeSubAccountId();
        require(tradingPrice > 0, "P=0"); // Price Is Zero
        bool hasProfit = decoded.isLong
            ? tradingPrice > oldSubAccount.entryPrice
            : tradingPrice < oldSubAccount.entryPrice;
        if (!hasProfit) {
            return true;
        }
        Asset memory asset = _storage.pool.getAssetInfo(decoded.assetId);
        if (blockTimestamp >= oldSubAccount.lastIncreasedTime + asset.minProfitTime) {
            return true;
        }
        uint96 priceDelta = tradingPrice >= oldSubAccount.entryPrice
            ? tradingPrice - oldSubAccount.entryPrice
            : oldSubAccount.entryPrice - tradingPrice;
        if (priceDelta >= uint256(oldSubAccount.entryPrice).rmul(asset.minProfitRate).safeUint96()) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IReferralManager {
    struct TierSetting {
        uint8 tier;
        uint64 stakeThreshold;
        uint64 discountRate;
        uint64 rebateRate;
    }

    event RegisterReferralCode(address referralCodeOwner, bytes32 referralCode);
    event SetReferralCode(address trader, bytes32 referralCode);
    event SetHandler(address handler, bool enable);
    event SetTiers(TierSetting[] newTierSettings);
    event SetMaintainer(address previousMaintainer, address newMaintainer);
    event SetRebateRecipient(bytes32 referralCode, address referralCodeOwner, address rebateRecipient);
    event TransferReferralCode(bytes32 referralCode, address previousOwner, address newOwner);

    function isHandler(address handler) external view returns (bool);

    function rebateRecipients(bytes32 referralCode) external view returns (address);

    // management methods
    function setHandler(address handler, bool enable) external;

    function setTiers(TierSetting[] memory newTierSettings) external;

    // methods only available on primary network
    function isValidReferralCode(bytes32 referralCode) external view returns (bool);

    function registerReferralCode(bytes32 referralCode, address rebateRecipient) external;

    function setRebateRecipient(bytes32 referralCode, address rebateRecipient) external;

    function transferReferralCode(bytes32 referralCode, address newOwner) external;

    // methods available on secondary network
    function getReferralCodeOf(address trader) external view returns (bytes32, uint256);

    function setReferrerCode(bytes32 referralCode) external;

    function setReferrerCodeFor(address trader, bytes32 referralCode) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../orderbook/Types.sol";

interface ILiquidityCallback {
    function beforeFillLiquidityOrder(
        LiquidityOrder calldata order,
        uint96 assetPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external returns (bool);

    function afterFillLiquidityOrder(
        LiquidityOrder calldata order,
        uint256 outAmount,
        uint96 assetPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external;

    function afterCancelLiquidityOrder(LiquidityOrder calldata order) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/INativeUnwrapper.sol";
import "../libraries/LibOrder.sol";

enum OrderType {
    None, // 0
    PositionOrder, // 1
    LiquidityOrder, // 2
    WithdrawalOrder, // 3
    RebalanceOrder // 4
}

struct OrderBookStorage {
    mapping(address => bool) brokers;
    ILiquidityPool pool;
    uint64 nextOrderId;
    LibOrder.OrderList orders;
    IERC20Upgradeable mlp;
    IWETH weth;
    uint32 liquidityLockPeriod; // 1e0
    INativeUnwrapper nativeUnwrapper;
    mapping(address => bool) rebalancers;
    bool isPositionOrderPaused;
    bool isLiquidityOrderPaused;
    uint32 marketOrderTimeout;
    uint32 maxLimitOrderTimeout;
    address maintainer;
    address referralManager;
    mapping(uint64 => PositionOrderExtra) positionOrderExtras; // more strategy params for a position order
    mapping(bytes32 => EnumerableSetUpgradeable.UintSet) activatedTpslOrders;
    mapping(address => bool) aggregators; // aggregator can placeOrder for a user
    uint256 callbackGasLimit;
    mapping(address => bool) callbackWhitelist;
}

//                                  160        152       144         120        96   72   64               8        0
// +----------------------------------------------------------------------------------+--------------------+--------+
// |              subAccountId 184 (already shifted by 72bits)                        |     orderId 64     | type 8 |
// +----------------------------------+----------+---------+-----------+---------+---------+---------------+--------+
// |              size 96             | profit 8 | flags 8 | unused 24 | exp 24  | time 32 |      enumIndex 64      |
// +----------------------------------+----------+---------+-----------+---------+---------+---------------+--------+
// |             price 96             |                    collateral 96                   |        unused 64       |
// +----------------------------------+----------------------------------------------------+------------------------+
struct PositionOrder {
    uint64 id;
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 collateral; // erc20.decimals
    uint96 size; // 1e18
    uint96 price; // 1e18
    uint8 profitTokenId;
    uint8 flags;
    uint32 placeOrderTime; // 1e0
    uint24 expire10s; // 10 seconds. deadline = placeOrderTime + expire * 10
}

struct PositionOrderExtra {
    // tp/sl strategy
    uint96 tpPrice; // take-profit price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
    uint96 slPrice; // stop-loss price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
    uint8 tpslProfitTokenId; // only valid when flags.POSITION_TPSL_STRATEGY.
    uint32 tpslDeadline; // only valid when flags.POSITION_TPSL_STRATEGY.
}

//                                  160       152       144          96          72    64              8        0
// +------------------------------------------------------------------+-----------+--------------------+--------+
// |                        account 160                               | unused 24 |     orderId 64     | type 8 |
// +----------------------------------+---------+---------+-----------+-----------+-----+--------------+--------+
// |             amount 96            | asset 8 | flags 8 | unused 48 |     time 32     |      enumIndex 64     |
// +----------------------------------+---------+---------+-----------+-----------------+-----------------------+
// |                                                 unused 256                                                 |
// +------------------------------------------------------------------------------------------------------------+
struct LiquidityOrder {
    uint64 id;
    address account;
    uint96 rawAmount; // erc20.decimals
    uint8 assetId;
    bool isAdding;
    uint32 placeOrderTime; // 1e0
}

//                                  160        152       144          96   72       64               8        0
// +------------------------------------------------------------------------+------------------------+--------+
// |              subAccountId 184 (already shifted by 72bits)              |       orderId 64       | type 8 |
// +----------------------------------+----------+---------+-----------+----+--------+---------------+--------+
// |             amount 96            | profit 8 | flags 8 | unused 48 |   time 32   |      enumIndex 64      |
// +----------------------------------+----------+---------+-----------+-------------+------------------------+
// |                                                unused 256                                                |
// +----------------------------------------------------------------------------------------------------------+
struct WithdrawalOrder {
    uint64 id;
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 rawAmount; // erc20.decimals
    uint8 profitTokenId;
    bool isProfit;
    uint32 placeOrderTime; // 1e0
}

//                                          160       96      88      80        72    64                 8        0
// +---------------------------------------------------+-------+-------+----------+----------------------+--------+
// |                  rebalancer 160                   | id0 8 | id1 8 | unused 8 |      orderId 64      | type 8 |
// +------------------------------------------+--------+-------+-------+----------+----+-----------------+--------+
// |                amount0 96                |                amount1 96              |       enumIndex 64       |
// +------------------------------------------+----------------------------------------+--------------------------+
// |                                                 userData 256                                                 |
// +--------------------------------------------------------------------------------------------------------------+
struct RebalanceOrder {
    uint64 id;
    address rebalancer;
    uint8 tokenId0;
    uint8 tokenId1;
    uint96 rawAmount0; // erc20.decimals
    uint96 maxRawAmount1; // erc20.decimals
    bytes32 userData;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./Storage.sol";

contract Admin is Storage {
    event AddBroker(address indexed newBroker);
    event RemoveBroker(address indexed broker);
    event AddRebalancer(address indexed newRebalancer);
    event RemoveRebalancer(address indexed rebalancer);
    event SetLiquidityLockPeriod(uint32 oldLockPeriod, uint32 newLockPeriod);
    event SetOrderTimeout(uint32 marketOrderTimeout, uint32 maxLimitOrderTimeout);
    event PausePositionOrder(bool isPaused);
    event PauseLiquidityOrder(bool isPaused);
    event SetMaintainer(address indexed newMaintainer);
    event SetReferralManager(address newReferralManager);
    event SetAggregator(address indexed aggregatorAddress, bool isEnable);

    modifier onlyBroker() {
        require(_storage.brokers[_msgSender()], "BKR"); // only BroKeR
        _;
    }

    modifier onlyRebalancer() {
        require(_storage.rebalancers[_msgSender()], "BAL"); // only reBALancer
        _;
    }

    modifier onlyMaintainer() {
        require(_msgSender() == _storage.maintainer || _msgSender() == owner(), "S!M"); // Sender is Not MaiNTainer
        _;
    }

    function addBroker(address newBroker) external onlyMaintainer {
        require(!_storage.brokers[newBroker], "CHG"); // not CHanGed
        _storage.brokers[newBroker] = true;
        emit AddBroker(newBroker);
    }

    function removeBroker(address broker) external onlyMaintainer {
        _removeBroker(broker);
    }

    function renounceBroker() external {
        _removeBroker(msg.sender);
    }

    function addRebalancer(address newRebalancer) external onlyOwner {
        require(!_storage.rebalancers[newRebalancer], "CHG"); // not CHanGed
        _storage.rebalancers[newRebalancer] = true;
        emit AddRebalancer(newRebalancer);
    }

    function removeRebalancer(address rebalancer) external onlyOwner {
        _removeRebalancer(rebalancer);
    }

    function renounceRebalancer() external {
        _removeRebalancer(msg.sender);
    }

    function setLiquidityLockPeriod(uint32 newLiquidityLockPeriod) external onlyOwner {
        require(newLiquidityLockPeriod <= 86400 * 30, "LCK"); // LoCK time is too large
        require(_storage.liquidityLockPeriod != newLiquidityLockPeriod, "CHG"); // setting is not CHanGed
        emit SetLiquidityLockPeriod(_storage.liquidityLockPeriod, newLiquidityLockPeriod);
        _storage.liquidityLockPeriod = newLiquidityLockPeriod;
    }

    function setOrderTimeout(uint32 marketOrderTimeout_, uint32 maxLimitOrderTimeout_) external onlyOwner {
        require(marketOrderTimeout_ != 0, "T=0"); // Timeout Is Zero
        require(marketOrderTimeout_ / 10 <= type(uint24).max, "T>M"); // Timeout is Larger than Max
        require(maxLimitOrderTimeout_ != 0, "T=0"); // Timeout Is Zero
        require(maxLimitOrderTimeout_ / 10 <= type(uint24).max, "T>M"); // Timeout is Larger than Max
        require(
            _storage.marketOrderTimeout != marketOrderTimeout_ ||
                _storage.maxLimitOrderTimeout != maxLimitOrderTimeout_,
            "CHG"
        ); // setting is not CHanGed
        _storage.marketOrderTimeout = marketOrderTimeout_;
        _storage.maxLimitOrderTimeout = maxLimitOrderTimeout_;
        emit SetOrderTimeout(marketOrderTimeout_, maxLimitOrderTimeout_);
    }

    function pause(bool isPositionOrderPaused_, bool isLiquidityOrderPaused_) external onlyMaintainer {
        if (_storage.isPositionOrderPaused != isPositionOrderPaused_) {
            _storage.isPositionOrderPaused = isPositionOrderPaused_;
            emit PausePositionOrder(isPositionOrderPaused_);
        }
        if (_storage.isLiquidityOrderPaused != isLiquidityOrderPaused_) {
            _storage.isLiquidityOrderPaused = isLiquidityOrderPaused_;
            emit PauseLiquidityOrder(isLiquidityOrderPaused_);
        }
    }

    function setMaintainer(address newMaintainer) external onlyOwner {
        require(_storage.maintainer != newMaintainer, "CHG"); // not CHanGed
        _storage.maintainer = newMaintainer;
        emit SetMaintainer(newMaintainer);
    }

    function setReferralManager(address newReferralManager) external onlyOwner {
        require(newReferralManager != address(0), "ZAD");
        _storage.referralManager = newReferralManager;
        emit SetReferralManager(newReferralManager);
    }

    function setAggregator(address aggregatorAddress, bool isEnable) external onlyOwner {
        require(aggregatorAddress != address(0), "ZAD");
        _storage.aggregators[aggregatorAddress] = isEnable;
        emit SetAggregator(aggregatorAddress, isEnable);
    }

    function setCallbackGasLimit(uint256 gasLimit) external onlyOwner {
        _storage.callbackGasLimit = gasLimit;
    }

    function setCallbackWhitelist(address caller, bool enable) external onlyOwner {
        _storage.callbackWhitelist[caller] = enable;
    }

    function _removeBroker(address broker) internal {
        require(_storage.brokers[broker], "CHG"); // not CHanGed
        _storage.brokers[broker] = false;
        emit RemoveBroker(broker);
    }

    function _removeRebalancer(address rebalancer) internal {
        require(_storage.rebalancers[rebalancer], "CHG"); // not CHanGed
        _storage.rebalancers[rebalancer] = false;
        emit RemoveRebalancer(rebalancer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

struct LiquidityPoolStorage {
    // slot
    address orderBook;
    // slot
    address mlp;
    // slot
    address _reserved6; // was liquidityManager
    // slot
    address weth;
    // slot
    uint128 _reserved1;
    uint32 shortFundingBaseRate8H; // 1e5
    uint32 shortFundingLimitRate8H; // 1e5
    uint32 fundingInterval; // 1e0
    uint32 lastFundingTime; // 1e0
    // slot
    uint32 _reserved2;
    // slot
    Asset[] assets;
    // slot
    mapping(bytes32 => SubAccount) accounts;
    // slot
    mapping(address => bytes32) _reserved3;
    // slot
    address _reserved4;
    uint96 _reserved5;
    // slot
    uint96 mlpPriceLowerBound; // safeguard against mlp price attacks
    uint96 mlpPriceUpperBound; // safeguard against mlp price attacks
    uint32 liquidityBaseFeeRate; // 1e5
    uint32 liquidityDynamicFeeRate; // 1e5
    // slot
    address nativeUnwrapper;
    // a sequence number that changes when LiquidityPoolStorage updated. this helps to keep track the state of LiquidityPool.
    uint32 sequence; // 1e0. note: will be 0 after 0xffffffff
    uint32 strictStableDeviation; // 1e5. strictStable price is 1.0 if in this damping range
    uint32 brokerTransactions; // transaction count for broker gas rebates
    // slot
    address vault;
    uint96 brokerGasRebate; // the number of native tokens for broker gas rebates per transaction
    // slot
    address maintainer;
    // slot
    mapping(address => bool) liquidityManager;
    bytes32[50] _gap;
}

struct Asset {
    // slot
    // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
    // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
    // different chains are the same.
    // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
    // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
    bytes32 symbol;
    // slot
    address tokenAddress; // erc20.address
    uint8 id;
    uint8 decimals; // erc20.decimals
    uint56 flags; // a bitset of ASSET_*
    uint24 _flagsPadding;
    // slot
    uint32 initialMarginRate; // 1e5
    uint32 maintenanceMarginRate; // 1e5
    uint32 minProfitRate; // 1e5
    uint32 minProfitTime; // 1e0
    uint32 positionFeeRate; // 1e5
    // note: 96 bits remaining
    // slot
    address referenceOracle;
    uint32 referenceDeviation; // 1e5
    uint8 referenceOracleType;
    uint32 halfSpread; // 1e5
    // note: 24 bits remaining
    // slot
    uint96 credit;
    uint128 _reserved2;
    // slot
    uint96 collectedFee;
    uint32 liquidationFeeRate; // 1e5
    uint96 spotLiquidity;
    // note: 32 bits remaining
    // slot
    uint96 maxLongPositionSize;
    uint96 totalLongPosition;
    // note: 64 bits remaining
    // slot
    uint96 averageLongPrice;
    uint96 maxShortPositionSize;
    // note: 64 bits remaining
    // slot
    uint96 totalShortPosition;
    uint96 averageShortPrice;
    // note: 64 bits remaining
    // slot, less used
    address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
    uint32 spotWeight; // 1e0
    uint32 longFundingBaseRate8H; // 1e5
    uint32 longFundingLimitRate8H; // 1e5
    // slot
    uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
    uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
}

uint32 constant FUNDING_PERIOD = 3600 * 8;

uint56 constant ASSET_IS_STABLE = 0x00000000000001; // is a usdt, usdc, ...
uint56 constant ASSET_CAN_ADD_REMOVE_LIQUIDITY = 0x00000000000002; // can call addLiquidity and removeLiquidity with this token
uint56 constant ASSET_IS_TRADABLE = 0x00000000000100; // allowed to be assetId
uint56 constant ASSET_IS_OPENABLE = 0x00000000010000; // can open position
uint56 constant ASSET_IS_SHORTABLE = 0x00000001000000; // allow shorting this asset
uint56 constant ASSET_USE_STABLE_TOKEN_FOR_PROFIT = 0x00000100000000; // take profit will get stable coin
uint56 constant ASSET_IS_ENABLED = 0x00010000000000; // allowed to be assetId and collateralId
uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

struct SubAccount {
    // slot
    uint96 collateral;
    uint96 size;
    uint32 lastIncreasedTime;
    // slot
    uint96 entryPrice;
    uint128 entryFunding; // entry longCumulativeFundingRate for long position. entry shortCumulativeFunding for short position
}

enum ReferenceOracleType {
    None,
    Chainlink
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../components/SafeOwnableUpgradeable.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/INativeUnwrapper.sol";
import "../libraries/LibOrder.sol";

contract Storage is Initializable, SafeOwnableUpgradeable {
    bool private _reserved1; // this variable shares the same slot as SafeOwnableUpgradeable._pendingOwner
    OrderBookStorage internal _storage;
    bytes32[38] _gap;

    modifier whenPositionOrderEnabled() {
        require(!_storage.isPositionOrderPaused, "POP"); // Position Order Paused
        _;
    }

    modifier whenLiquidityOrderEnabled() {
        require(!_storage.isLiquidityOrderPaused, "LOP"); // Liquidity Order Paused
        _;
    }

    function brokers(address broker) external view returns (bool) {
        return _storage.brokers[broker];
    }

    function nextOrderId() external view returns (uint64) {
        return _storage.nextOrderId;
    }

    // 1e0
    function liquidityLockPeriod() external view returns (uint32) {
        return _storage.liquidityLockPeriod;
    }

    function rebalancers(address rebalancer) external view returns (bool) {
        return _storage.rebalancers[rebalancer];
    }

    function isPositionOrderPaused() external view returns (bool) {
        return _storage.isPositionOrderPaused;
    }

    function isLiquidityOrderPaused() external view returns (bool) {
        return _storage.isLiquidityOrderPaused;
    }

    function marketOrderTimeout() external view returns (uint32) {
        return _storage.marketOrderTimeout;
    }

    function maxLimitOrderTimeout() external view returns (uint32) {
        return _storage.maxLimitOrderTimeout;
    }

    function maintainer() external view returns (address) {
        return _storage.maintainer;
    }

    function referralManager() external view returns (address) {
        return _storage.referralManager;
    }

    function positionOrderExtras(uint64 orderId) external view returns (PositionOrderExtra memory) {
        return _storage.positionOrderExtras[orderId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSetUpgradeable {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";

interface ILiquidityPool {
    /////////////////////////////////////////////////////////////////////////////////
    //                                 getters

    function getAssetInfo(uint8 assetId) external view returns (Asset memory);

    function getAllAssetInfo() external view returns (Asset[] memory);

    function getAssetAddress(uint8 assetId) external view returns (address);

    function getLiquidityPoolStorage()
        external
        view
        returns (
            // [0] shortFundingBaseRate8H
            // [1] shortFundingLimitRate8H
            // [2] lastFundingTime
            // [3] fundingInterval
            // [4] liquidityBaseFeeRate
            // [5] liquidityDynamicFeeRate
            // [6] sequence. note: will be 0 after 0xffffffff
            // [7] strictStableDeviation
            uint32[8] memory u32s,
            // [0] mlpPriceLowerBound
            // [1] mlpPriceUpperBound
            uint96[2] memory u96s
        );

    function getSubAccount(
        bytes32 subAccountId
    )
        external
        view
        returns (uint96 collateral, uint96 size, uint32 lastIncreasedTime, uint96 entryPrice, uint128 entryFunding);

    /////////////////////////////////////////////////////////////////////////////////
    //                             for Trader / Broker

    function withdrawAllCollateral(bytes32 subAccountId) external;

    /////////////////////////////////////////////////////////////////////////////////
    //                                 only Broker

    function depositCollateral(
        bytes32 subAccountId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external;

    function withdrawCollateral(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external;

    function withdrawProfit(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external;

    /**
     * @dev   Add liquidity.
     *
     * @param trader            liquidity provider address.
     * @param tokenId           asset.id that added.
     * @param rawAmount         asset token amount. decimals = erc20.decimals.
     * @param tokenPrice        token price. decimals = 18.
     * @param mlpPrice          mlp price.  decimals = 18.
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset).
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains.
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external returns (uint96 mlpAmount);

    /**
     * @dev   Remove liquidity.
     *
     * @param trader            liquidity provider address.
     * @param mlpAmount         mlp amount. decimals = 18.
     * @param tokenId           asset.id that removed to.
     * @param tokenPrice        token price. decimals = 18.
     * @param mlpPrice          mlp price. decimals = 18.
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset). decimals = 18.
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains. decimals = 18.
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount, // NOTE: OrderBook SHOULD transfer mlpAmount mlp to LiquidityPool
        uint8 tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external returns (uint256 rawAmount);

    /**
     * @notice Open a position.
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           position size. decimals = 18.
     * @param  collateralPrice  price of subAccount.collateral.
     * @param  assetPrice       price of subAccount.asset.
     */
    function openPosition(
        bytes32 subAccountId,
        uint96 amount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external returns (uint96);

    /**
     * @notice Close a position.
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           position size. decimals = 18.
     * @param  profitAssetId    for long position (unless asset.useStable is true), ignore this argument;
     *                          for short position, the profit asset should be one of the stable coin.
     * @param  collateralPrice  price of subAccount.collateral. decimals = 18.
     * @param  assetPrice       price of subAccount.asset. decimals = 18.
     * @param  profitAssetPrice price of profitAssetId. ignore this argument if profitAssetId is ignored. decimals = 18.
     */
    function closePosition(
        bytes32 subAccountId,
        uint96 amount,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external returns (uint96 tradingPrice);

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _getFundingRate in Liquidity.sol on how to calculate funding rate.
     * @param  stableUtilization    Stable coin utilization in all chains. decimals = 5.
     * @param  unstableTokenIds     All unstable Asset id(s) MUST be passed in order. ex: 1, 2, 5, 6, ...
     * @param  unstableUtilizations Unstable Asset utilizations in all chains. decimals = 5.
     * @param  unstablePrices       Unstable Asset prices.
     */
    function updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices
    ) external;

    function liquidate(
        bytes32 subAccountId,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external returns (uint96);

    /**
     * @notice Redeem mux token into original tokens.
     *
     *         Only strict stable coins and un-stable coins are supported.
     */
    function redeemMuxToken(
        address trader,
        uint8 tokenId,
        uint96 muxTokenAmount // NOTE: OrderBook SHOULD transfer muxTokenAmount to LiquidityPool
    ) external;

    /**
     * @dev  Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *       rebalancer must implement IMuxRebalancerCallback.
     */
    function rebalance(
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData,
        uint96 price0,
        uint96 price1
    ) external;

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate(address receiver) external returns (uint256 rawAmount);

    /////////////////////////////////////////////////////////////////////////////////
    //                            only LiquidityManager

    function transferLiquidityOut(uint8[] memory assetIds, uint256[] memory amounts) external;

    function transferLiquidityIn(uint8[] memory assetIds, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface INativeUnwrapper {
    function unwrap(address payable to, uint256 rawAmount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../orderbook/Types.sol";
import "./LibSubAccount.sol";

library LibOrder {
    // position order flags
    uint8 constant POSITION_OPEN = 0x80; // this flag means openPosition; otherwise closePosition
    uint8 constant POSITION_MARKET_ORDER = 0x40; // this flag means ignore limitPrice
    uint8 constant POSITION_WITHDRAW_ALL_IF_EMPTY = 0x20; // this flag means auto withdraw all collateral if position.size == 0
    uint8 constant POSITION_TRIGGER_ORDER = 0x10; // this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
    uint8 constant POSITION_TPSL_STRATEGY = 0x08; // for open-position-order, this flag auto place take-profit and stop-loss orders when open-position-order fills.
    //                                               for close-position-order, this flag means ignore limitPrice and profitTokenId, and use extra.tpPrice, extra.slPrice, extra.tpslProfitTokenId instead.
    uint8 constant POSITION_SHOULD_REACH_MIN_PROFIT = 0x04; // this flag is used to ensure that either the minProfitTime is met or the minProfitRate ratio is reached when close a position. only available when minProfitTime > 0.

    // order data[1] SHOULD reserve lower 64bits for enumIndex
    bytes32 constant ENUM_INDEX_BITS = bytes32(uint256(0xffffffffffffffff));

    struct OrderList {
        uint64[] _orderIds;
        mapping(uint64 => bytes32[3]) _orders;
    }

    function add(OrderList storage list, uint64 orderId, bytes32[3] memory order) internal {
        require(!contains(list, orderId), "DUP"); // already seen this orderId
        list._orderIds.push(orderId);
        // The value is stored at length-1, but we add 1 to all indexes
        // and use 0 as a sentinel value
        uint256 enumIndex = list._orderIds.length;
        require(enumIndex <= type(uint64).max, "O64"); // Overflow uint64
        // order data[1] SHOULD reserve lower 64bits for enumIndex
        require((order[1] & ENUM_INDEX_BITS) == 0, "O1F"); // bad Order[1] Field
        order[1] = bytes32(uint256(order[1]) | uint256(enumIndex));
        list._orders[orderId] = order;
    }

    function remove(OrderList storage list, uint64 orderId) internal {
        bytes32[3] storage orderToRemove = list._orders[orderId];
        uint64 enumIndexToRemove = uint64(uint256(orderToRemove[1]));
        require(enumIndexToRemove != 0, "OID"); // orderId is not found
        // swap and pop
        uint256 indexToRemove = enumIndexToRemove - 1;
        uint256 lastIndex = list._orderIds.length - 1;
        if (lastIndex != indexToRemove) {
            uint64 lastOrderId = list._orderIds[lastIndex];
            // move the last orderId
            list._orderIds[indexToRemove] = lastOrderId;
            // replace enumIndex
            bytes32[3] storage lastOrder = list._orders[lastOrderId];
            lastOrder[1] = (lastOrder[1] & (~ENUM_INDEX_BITS)) | bytes32(uint256(enumIndexToRemove));
        }
        list._orderIds.pop();
        delete list._orders[orderId];
    }

    function contains(OrderList storage list, uint64 orderId) internal view returns (bool) {
        bytes32[3] storage order = list._orders[orderId];
        // order data[1] always contains enumIndex
        return order[1] != bytes32(0);
    }

    function length(OrderList storage list) internal view returns (uint256) {
        return list._orderIds.length;
    }

    function at(OrderList storage list, uint256 index) internal view returns (bytes32[3] memory order) {
        require(index < list._orderIds.length, "IDX"); // InDex overflow
        uint64 orderId = list._orderIds[index];
        order = list._orders[orderId];
    }

    function get(OrderList storage list, uint64 orderId) internal view returns (bytes32[3] memory) {
        return list._orders[orderId];
    }

    function getOrderType(bytes32[3] memory orderData) internal pure returns (OrderType) {
        return OrderType(uint8(uint256(orderData[0])));
    }

    function getOrderOwner(bytes32[3] memory orderData) internal pure returns (address) {
        return address(bytes20(orderData[0]));
    }

    // check Types.PositionOrder for schema
    function encodePositionOrder(
        uint64 orderId,
        bytes32 subAccountId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 placeOrderTime,
        uint24 expire10s
    ) internal pure returns (bytes32[3] memory data) {
        require((subAccountId & LibSubAccount.SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        data[0] = subAccountId | bytes32(uint256(orderId) << 8) | bytes32(uint256(OrderType.PositionOrder));
        data[1] = bytes32(
            (uint256(size) << 160) |
                (uint256(profitTokenId) << 152) |
                (uint256(flags) << 144) |
                (uint256(expire10s) << 96) |
                (uint256(placeOrderTime) << 64)
        );
        data[2] = bytes32((uint256(price) << 160) | (uint256(collateral) << 64));
    }

    // check Types.PositionOrder for schema
    function decodePositionOrder(bytes32[3] memory data) internal pure returns (PositionOrder memory order) {
        order.subAccountId = bytes32(bytes23(data[0]));
        order.collateral = uint96(bytes12(data[2] << 96));
        order.size = uint96(bytes12(data[1]));
        order.flags = uint8(bytes1(data[1] << 104));
        order.price = uint96(bytes12(data[2]));
        order.profitTokenId = uint8(bytes1(data[1] << 96));
        order.expire10s = uint24(bytes3(data[1] << 136));
        order.placeOrderTime = uint32(bytes4(data[1] << 160));
    }

    // check Types.LiquidityOrder for schema
    function encodeLiquidityOrder(
        uint64 orderId,
        address account,
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding,
        uint32 placeOrderTime
    ) internal pure returns (bytes32[3] memory data) {
        uint8 flags = isAdding ? 1 : 0;
        data[0] = bytes32(
            (uint256(uint160(account)) << 96) | (uint256(orderId) << 8) | uint256(OrderType.LiquidityOrder)
        );
        data[1] = bytes32(
            (uint256(rawAmount) << 160) |
                (uint256(assetId) << 152) |
                (uint256(flags) << 144) |
                (uint256(placeOrderTime) << 64)
        );
    }

    // check Types.LiquidityOrder for schema
    function decodeLiquidityOrder(bytes32[3] memory data) internal pure returns (LiquidityOrder memory order) {
        order.id = uint64(bytes8(data[0] << 184));
        order.account = address(bytes20(data[0]));
        order.rawAmount = uint96(bytes12(data[1]));
        order.assetId = uint8(bytes1(data[1] << 96));
        uint8 flags = uint8(bytes1(data[1] << 104));
        order.isAdding = flags > 0;
        order.placeOrderTime = uint32(bytes4(data[1] << 160));
    }

    // check Types.WithdrawalOrder for schema
    function encodeWithdrawalOrder(
        uint64 orderId,
        bytes32 subAccountId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit,
        uint32 placeOrderTime
    ) internal pure returns (bytes32[3] memory data) {
        require((subAccountId & LibSubAccount.SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        uint8 flags = isProfit ? 1 : 0;
        data[0] = subAccountId | bytes32(uint256(orderId) << 8) | bytes32(uint256(OrderType.WithdrawalOrder));
        data[1] = bytes32(
            (uint256(rawAmount) << 160) |
                (uint256(profitTokenId) << 152) |
                (uint256(flags) << 144) |
                (uint256(placeOrderTime) << 64)
        );
    }

    // check Types.WithdrawalOrder for schema
    function decodeWithdrawalOrder(bytes32[3] memory data) internal pure returns (WithdrawalOrder memory order) {
        order.subAccountId = bytes32(bytes23(data[0]));
        order.rawAmount = uint96(bytes12(data[1]));
        order.profitTokenId = uint8(bytes1(data[1] << 96));
        uint8 flags = uint8(bytes1(data[1] << 104));
        order.isProfit = flags > 0;
        order.placeOrderTime = uint32(bytes4(data[1] << 160));
    }

    // check Types.RebalanceOrder for schema
    function encodeRebalanceOrder(
        uint64 orderId,
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) internal pure returns (bytes32[3] memory data) {
        data[0] = bytes32(
            (uint256(uint160(rebalancer)) << 96) |
                (uint256(tokenId0) << 88) |
                (uint256(tokenId1) << 80) |
                (uint256(orderId) << 8) |
                uint256(OrderType.RebalanceOrder)
        );
        data[1] = bytes32((uint256(rawAmount0) << 160) | (uint256(maxRawAmount1) << 64));
        data[2] = userData;
    }

    // check Types.RebalanceOrder for schema
    function decodeRebalanceOrder(bytes32[3] memory data) internal pure returns (RebalanceOrder memory order) {
        order.rebalancer = address(bytes20(data[0]));
        order.tokenId0 = uint8(bytes1(data[0] << 160));
        order.tokenId1 = uint8(bytes1(data[0] << 168));
        order.rawAmount0 = uint96(bytes12(data[1]));
        order.maxRawAmount1 = uint96(bytes12(data[1] << 96));
        order.userData = data[2];
    }

    function isOpenPosition(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_OPEN) != 0;
    }

    function isMarketOrder(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_MARKET_ORDER) != 0;
    }

    function isWithdrawIfEmpty(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_WITHDRAW_ALL_IF_EMPTY) != 0;
    }

    function isTriggerOrder(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_TRIGGER_ORDER) != 0;
    }

    function isTpslStrategy(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_TPSL_STRATEGY) != 0;
    }

    function shouldReachMinProfit(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_SHOULD_REACH_MIN_PROFIT) != 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SafeOwnableUpgradeable is OwnableUpgradeable {
    address internal _pendingOwner;

    event PrepareToTransferOwnership(address indexed pendingOwner);

    function __SafeOwnable_init() internal onlyInitializing {
        __Ownable_init();
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "O=0"); // Owner Is Zero
        require(newOwner != owner(), "O=O"); // Owner is the same as the old Owner
        _pendingOwner = newOwner;
        emit PrepareToTransferOwnership(_pendingOwner);
    }

    function takeOwnership() public virtual {
        require(_msgSender() == _pendingOwner, "SND"); // SeNDer is not authorized
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    function renounceOwnership() public virtual override onlyOwner {
        _pendingOwner = address(0);
        _transferOwnership(address(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}