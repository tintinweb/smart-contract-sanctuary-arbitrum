// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {LiquidityConfigurations} from "joe-v2/libraries/math/LiquidityConfigurations.sol";
import {PackedUint128Math} from "joe-v2/libraries/math/PackedUint128Math.sol";
import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {SafeCast} from "joe-v2/libraries/math/SafeCast.sol";

import {ILimitOrderManager} from "./interfaces/ILimitOrderManager.sol";

/**
 * @title Limit Order Manager
 * @author Trader Joe
 * @notice This contracts allows users to place limit orders using the Liquidity Book protocol.
 * It allows to create orders for any Liquidity Book pair V2.1.
 *
 * The flow of the Limit Order Manager is the following:
 * - Users create orders for a specific pair, type (bid or ask), price (bin id) and amount
 *  (in token Y for bid orders and token X for ask orders) which will be added to the liquidity book pair.
 * - Users can cancel orders, which will remove the liquidity from the liquidity book pair according to the order amount
 * and send the token amounts back to the user (the amounts depend on the bin composition).
 * - Users can execute orders, which will remove the liquidity from the order and send the token to the
 * Limit Order Manager contract.
 * - Users can claim their executed orders, which will send a portion of the token received from the execution
 * to the user (the share depends on the total executed amount of the orders).
 *
 * Users can place orders using the `placeOrder` function by specifying the following parameters:
 * - `tokenX`: the token X of the liquidity book pair
 * - `tokenY`: the token Y of the liquidity book pair
 * - `binStep`: the bin step of the liquidity book pair
 * - `orderType`: the order type (bid or ask)
 * - `binId`: the bin id of the order, which is the price of the order
 * - `amount`: the amount of token to be used for the order, in token Y for bid orders and token X for ask orders
 * Orders can't be placed in the active bin id. Bid orders need to be placed in a bin id lower than the active id,
 * while ask orders need to be placed in a bin id greater than the active bin id.
 *
 * Users can cancel orders using the `cancelOrder` function by specifying the same parameters as for `placeOrder` but
 * without the `amount` parameter.
 * If the order is already executed, it can't be cancelled, and user will need to claim the filled amount.
 * If the user is trying to cancel an order that is inside the active bin id, he may receive a partially filled order,
 * according to the active bin composition.
 *
 * Users can claim orders using the `claimOrder` function by specifying the same parameters as for `placeOrder` but
 * without the `amount` parameter.
 * If the order is not already executed, but that it can be executed, it will be executed first and then claimed.
 * If the order isn't executable, it can't be claimed and the transaction will revert.
 * If the order is already executed, the user will receive the filled amount.
 *
 * Users can execute orders using the `executeOrder` function by specifying the same parameters as for `placeOrder` but
 * without the `amount` parameter.
 * If the order can't be executed or if it is already executed, the transaction will revert.
 */
contract LimitOrderManager is ReentrancyGuard, ILimitOrderManager {
    using SafeERC20 for IERC20;
    using PackedUint128Math for bytes32;
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    ILBFactory private immutable _factory;

    /**
     * @dev Mapping of order key (pair, order type, bin id) to positions.
     */
    mapping(bytes32 => Positions) private _positions;

    /**
     * @dev Mapping of user address to mapping of order key (pair, order type, bin id) to order.
     */
    mapping(address => mapping(bytes32 => Order)) private _orders;

    /**
     * @notice Constructor of the Limit Order Manager.
     * @param factory The address of the Liquidity Book factory.
     */
    constructor(ILBFactory factory) {
        if (address(factory) == address(0)) revert LimitOrderManager__ZeroAddress();

        _factory = factory;
    }

    /**
     * @notice Returns the name of the Limit Order Manager.
     * @return The name of the Limit Order Manager.
     */
    function name() external pure override returns (string memory) {
        return "Joe Limit Order Manager";
    }

    /**
     * @notice Returns the address of the Liquidity Book factory.
     * @return The address of the Liquidity Book factory.
     */
    function getFactory() external view override returns (ILBFactory) {
        return _factory;
    }

    /**
     * @notice Returns the order of the user for the given parameters.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param user The user address.
     * @return The order of the user for the given parameters.
     */
    function getOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, address user)
        external
        view
        override
        returns (Order memory)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _orders[user][_getOrderKey(lbPair, orderType, binId)];
    }

    /**
     * @notice Returns the last position id for the given parameters.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return The last position id for the given parameters.
     */
    function getLastPositionId(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        override
        returns (uint256)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);
        return _positions[_getOrderKey(lbPair, orderType, binId)].lastId;
    }

    /**
     * @notice Returns the position for the given parameters.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param positionId The position id.
     * @return The position for the given parameters.
     */
    function getPosition(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        uint256 positionId
    ) external view override returns (Position memory) {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);
        return _positions[_getOrderKey(lbPair, orderType, binId)].at[positionId];
    }

    /**
     * @notice Return whether the order is executable or not.
     * Will return false if the order is already executed or if it is not executable.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return Whether the order is executable or not.
     */
    function isOrderExecutable(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        override
        returns (bool)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        // Get the order key
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the positions for the order key to get the last position id
        Positions storage positions = _positions[orderKey];
        uint256 positionId = positions.lastId;

        // Get the position at the last position id
        Position storage position = positions.at[positionId];

        // Return whether the position is executable or not, that is, if the position id is greater than 0,
        // the position is not already withdrawn and the order is executable
        return (positionId > 0 && !position.withdrawn && _isOrderExecutable(lbPair, orderType, binId));
    }

    /**
     * @notice Returns the current amounts of the order for the given parameters.
     * Depending on the current bin id, the amounts might fluctuate.
     * The amount returned will be the value that the user will receive if the order is cancelled.
     * If it's fully converted to the other token, then it's the amount that the user will receive after the order
     * is claimed.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param user The user address.
     * @return amountX The amount of token X.
     * @return amountY The amount of token Y.
     */
    function getCurrentAmounts(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        address user
    ) external view override returns (uint256 amountX, uint256 amountY) {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        Order storage order = _orders[user][orderKey];
        Position storage position = _positions[orderKey].at[order.positionId];

        uint256 orderLiquidity = order.liquidity;

        if (position.withdrawn) {
            uint256 amount = orderLiquidity.mulDivRoundDown(position.amount, position.liquidity);

            return orderType == OrderType.BID ? (amount, uint256(0)) : (uint256(0), amount);
        }

        uint256 totalLiquidity = lbPair.totalSupply(binId);
        if (totalLiquidity == 0) return (0, 0);

        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(binId);

        amountX = orderLiquidity.mulDivRoundDown(binReserveX, totalLiquidity);
        amountY = orderLiquidity.mulDivRoundDown(binReserveY, totalLiquidity);
    }

    /**
     * @notice Place an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param amount The amount of the order.
     * @return orderPositionId The position id of the order.
     */
    function placeOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, uint256 amount)
        external
        override
        nonReentrant
        returns (uint256 orderPositionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        (IERC20 tokenIn, IERC20 tokenOut) = orderType == OrderType.BID ? (tokenY, tokenX) : (tokenX, tokenY);

        return _placeOrder(lbPair, tokenIn, tokenOut, amount, orderType, binId);
    }

    /**
     * @notice Cancel an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function cancelOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        override
        nonReentrant
        returns (uint256 orderPositionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _cancelOrder(lbPair, tokenX, tokenY, orderType, binId);
    }

    /**
     * @notice Claim an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function claimOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        override
        nonReentrant
        returns (uint256 orderPositionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _claimOrder(lbPair, tokenX, tokenY, orderType, binId);
    }

    /**
     * @notice Execute an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return positionId The position id.
     */
    function executeOrders(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        override
        nonReentrant
        returns (uint256 positionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _executeOrders(lbPair, tokenX, tokenY, orderType, binId);
    }

    /**
     * @notice Place multiple orders.
     * @param orders The orders to place.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchPlaceOrders(PlaceOrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            PlaceOrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            (IERC20 tokenIn, IERC20 tokenOut) =
                order.orderType == OrderType.BID ? (order.tokenY, order.tokenX) : (order.tokenX, order.tokenY);

            orderPositionIds[i] = _placeOrder(lbPair, tokenIn, tokenOut, order.amount, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancel multiple orders.
     * @param orders The orders to cancel.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchCancelOrders(OrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            OrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            orderPositionIds[i] = _cancelOrder(lbPair, order.tokenX, order.tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim multiple orders.
     * @param orders The orders to claim.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchClaimOrders(OrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            OrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            orderPositionIds[i] = _claimOrder(lbPair, order.tokenX, order.tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Execute multiple orders.
     * @param orders The orders to execute.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchExecuteOrders(OrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            OrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            orderPositionIds[i] = _executeOrders(lbPair, order.tokenX, order.tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Place multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to place.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchPlaceOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        PlaceOrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            PlaceOrderParamsSamePair calldata order = orders[i];

            (IERC20 tokenIn, IERC20 tokenOut) = order.orderType == OrderType.BID ? (tokenY, tokenX) : (tokenX, tokenY);

            orderPositionIds[i] = _placeOrder(lbPair, tokenIn, tokenOut, order.amount, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancel multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to cancel.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchCancelOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            OrderParamsSamePair calldata order = orders[i];

            orderPositionIds[i] = _cancelOrder(lbPair, tokenX, tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to claim.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchClaimOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            OrderParamsSamePair calldata order = orders[i];

            orderPositionIds[i] = _claimOrder(lbPair, tokenX, tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Execute multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to execute.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchExecuteOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            OrderParamsSamePair calldata order = orders[i];

            orderPositionIds[i] = _executeOrders(lbPair, tokenX, tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Get the liquidity book pair address from the factory.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @return lbPair The liquidity book pair.
     */
    function _getLBPair(IERC20 tokenX, IERC20 tokenY, uint16 binStep) private view returns (ILBPair lbPair) {
        lbPair = _factory.getLBPairInformation(tokenX, tokenY, binStep).LBPair;

        // Check if the liquidity book pair is valid, that is, if the lbPair address is not 0.
        if (address(lbPair) == address(0)) revert LimitOrderManager__InvalidPair();

        // Check if the token X of the liquidity book pair is the same as the token X of the order.
        // We revert here because if the tokens are in the wrong order, then the price of the order will be wrong.
        if (lbPair.getTokenX() != tokenX) revert LimitOrderManager__InvalidTokenOrder();
    }

    /**
     * @dev Return whether the order is valid or not.
     * An order is valid if the order type is bid and the bin id is lower than the active id,
     * or if the order type is ask and the bin id is greater than the active id. This is to prevent adding
     * orders to the active bin and to add liquidity to a bin that can't receive the token sent.
     * @param lbPair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return valid Whether the order is valid or not.
     */
    function _isOrderValid(ILBPair lbPair, OrderType orderType, uint24 binId) private view returns (bool) {
        uint24 activeId = lbPair.getActiveId();
        return ((orderType == OrderType.BID && binId < activeId) || (orderType == OrderType.ASK && binId > activeId));
    }

    /**
     * @dev Return whether the order is executable or not.
     * An order is executable if the bin was crossed, if the order type is bid and the bin id is now lower than
     * to the active id, or if the order type is ask and the bin id is now greater than the active id.
     * This is to only allow executing orders that are fully filled.
     * @param lbPair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return executable Whether the order is executable or not.
     */
    function _isOrderExecutable(ILBPair lbPair, OrderType orderType, uint24 binId) private view returns (bool) {
        uint24 activeId = lbPair.getActiveId();
        return ((orderType == OrderType.BID && binId > activeId) || (orderType == OrderType.ASK && binId < activeId));
    }

    /**
     * @dev Place an order.
     * If the user already have an order with the same parameters and that it's not executed yet, instead of creating a
     * new order, the amount of the previous order is increased by the amount of the new order.
     * If the user already have an order with the same parameters and that it's executed, the order is claimed if
     * it was not claimed yet and a new order is created  overwriting the previous one.
     * @param lbPair The liquidity book pair.
     * @param tokenIn The token in of the order.
     * @param tokenOut The token out of the order.
     * @param amount The amount of the order.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function _placeOrder(
        ILBPair lbPair,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amount,
        OrderType orderType,
        uint24 binId
    ) private returns (uint256 orderPositionId) {
        // Check if the order is valid.
        if (!_isOrderValid(lbPair, orderType, binId)) revert LimitOrderManager__InvalidOrder();

        // Deposit the amount sent by the user to the liquidity book pair.
        (uint256 amountX, uint256 amountY, uint256 liquidity) =
            _depositToLBPair(lbPair, tokenIn, orderType, binId, amount);

        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the position of the order.
        Positions storage positions = _positions[orderKey];

        // Get the last position id and the last position.
        uint256 positionId = positions.lastId;
        Position storage position = positions.at[positionId];

        // If the last position id is 0 or the last position is withdrawn, create a new position.
        if (positionId == 0 || position.withdrawn) {
            ++positionId;
            positions.lastId = positionId;

            position = positions.at[positionId];
        }

        // Update the liquidity of the position.
        position.liquidity += liquidity;

        // Get the current user order.
        Order storage order = _orders[msg.sender][orderKey];

        // Get the position id of the current user order.
        orderPositionId = order.positionId;

        // If the position id of the order is smaller than the current position id, the order needs to be claimed,
        // unless the position id of the order is 0.
        if (orderPositionId < positionId) {
            // If the position id of the order is not 0, claim the order from the position.
            if (orderPositionId != 0) {
                _claimOrderFromPosition(positions.at[orderPositionId], order, tokenOut, orderPositionId, orderKey);
            }

            // Set the position id of the order to the current position id.
            orderPositionId = positionId;
            order.positionId = orderPositionId;
        }

        // Update the order liquidity.
        order.liquidity += liquidity;

        emit OrderPlaced(msg.sender, lbPair, binId, orderType, positionId, liquidity, amountX, amountY);
    }

    /**
     * @dev Claim an order.
     * If the order is not claimable, the function reverts.
     * If the order is not claimable but executable, the order is first executed and then claimed.
     * If the order is claimable, the order is claimed and the user receives the tokens.
     * @param lbPair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function _claimOrder(ILBPair lbPair, IERC20 tokenX, IERC20 tokenY, OrderType orderType, uint24 binId)
        private
        returns (uint256 orderPositionId)
    {
        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the current user order.
        Order storage order = _orders[msg.sender][orderKey];

        // Get the position id of the current user order.
        orderPositionId = order.positionId;

        // If the position id of the order is 0, the order is not claimable, therefore revert.
        if (orderPositionId == 0) revert LimitOrderManager__OrderNotClaimable();

        // Get the position of the order.
        Position storage position = _positions[orderKey].at[orderPositionId];

        // If the position is not withdrawn, try to execute the order.
        if (!position.withdrawn) _executeOrders(lbPair, tokenX, tokenY, orderType, binId);

        // Claim the order from the position, which will transfer the amount of the filled order to the user.
        _claimOrderFromPosition(
            position, order, orderType == OrderType.BID ? tokenX : tokenY, orderPositionId, orderKey
        );
    }

    /**
     * @dev Claim an order from a position.
     * This function does not check if the order is claimable or not, therefore it needs to be called by a function
     * that does the necessary checks.
     * @param position The position of the order.
     * @param order The order.
     * @param token The token of the order.
     * @param positionId The position id of the order.
     * @param orderKey The order key.
     */
    function _claimOrderFromPosition(
        Position storage position,
        Order storage order,
        IERC20 token,
        uint256 positionId,
        bytes32 orderKey
    ) private {
        // Get the order liquidity.
        uint256 orderLiquidity = order.liquidity;

        // Set the order liquidity and position id to 0.
        order.positionId = 0;
        order.liquidity = 0;

        // Calculate the amount of the order.
        uint256 amount = orderLiquidity.mulDivRoundDown(position.amount, position.liquidity);

        // Transfer the amount of the order to the user.
        token.safeTransfer(msg.sender, amount);

        // Get the order key components (liquidity book pair, order type, bin id) from the order key to emit the event.
        (ILBPair lbPair, OrderType orderType, uint24 binId) = _getOrderKeyComponents(orderKey);
        (uint256 amountX, uint256 amountY) = orderType == OrderType.BID ? (amount, uint256(0)) : (uint256(0), amount);

        emit OrderClaimed(msg.sender, lbPair, binId, orderType, positionId, orderLiquidity, amountX, amountY);
    }

    /**
     * @dev Cancel an order.
     * If the order is not placed, the function reverts.
     * If the order is already executed, the function reverts.
     * If the order is placed, the order is cancelled and the liquidity is withdrawn from the liquidity book pair.
     * The liquidity is then transferred back to the user (the amounts depend on the bin composition).
     * @param lbPair The liquidity book pair.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function _cancelOrder(ILBPair lbPair, IERC20 tokenX, IERC20 tokenY, OrderType orderType, uint24 binId)
        private
        returns (uint256 orderPositionId)
    {
        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the current user order.
        Order storage order = _orders[msg.sender][orderKey];

        // Get the position id of the current user order.
        orderPositionId = order.positionId;

        // If the position id of the order is 0, the order is not placed, therefore revert.
        if (orderPositionId == 0) revert LimitOrderManager__OrderNotPlaced();

        // Get the position of the order.
        Position storage position = _positions[orderKey].at[orderPositionId];

        // If the position is withdrawn, the order is already executed, therefore revert.
        if (position.withdrawn) revert LimitOrderManager__OrderAlreadyExecuted();

        // Get the order liquidity.
        uint256 orderLiquidity = order.liquidity;

        // Set the order liquidity and position id to 0.
        order.positionId = 0;
        order.liquidity = 0;

        // Decrease the position liquidity by the order liquidity.
        position.liquidity -= orderLiquidity;

        // Withdraw the liquidity from the liquidity book pair.
        (uint256 amountX, uint256 amountY) =
            _withdrawFromLBPair(lbPair, tokenX, tokenY, binId, orderLiquidity, msg.sender);

        emit OrderCancelled(msg.sender, lbPair, binId, orderType, orderPositionId, orderLiquidity, amountX, amountY);
    }

    /**
     * @dev Execute the orders of a lbPair, order type and bin id.
     * If the bin is not executable, the function reverts.
     * If the bin is executable, the function executes the orders of the bin.
     * @param lbPair The liquidity book pair.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return positionId The position id of the executed orders.
     */
    function _executeOrders(ILBPair lbPair, IERC20 tokenX, IERC20 tokenY, OrderType orderType, uint24 binId)
        private
        returns (uint256 positionId)
    {
        // Check if the bin is executable.
        if (!_isOrderExecutable(lbPair, orderType, binId)) revert LimitOrderManager__OrderNotExecutable();

        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the positions of the order.
        Positions storage positions = _positions[orderKey];

        // Get the last position id of the order.
        positionId = positions.lastId;

        // If the position id is 0, there are no orders to execute, therefore revert.
        if (positionId == 0) revert LimitOrderManager__NoOrdersToExecute();

        // Get the last position of the order.
        Position storage position = _positions[orderKey].at[positionId];

        // If the position is withdrawn, the orders are already executed, therefore revert.
        if (position.withdrawn) revert LimitOrderManager__OrdersAlreadyExecuted();
        position.withdrawn = true;

        // Get the position liquidity.
        uint256 positionLiquidity = position.liquidity;

        // If the position liquidity is 0, there are no orders to execute, therefore revert.
        if (positionLiquidity == 0) revert LimitOrderManager__ZeroPositionLiquidity();

        // Withdraw the liquidity from the liquidity book pair.
        (uint128 amountX, uint128 amountY) =
            _withdrawFromLBPair(lbPair, tokenX, tokenY, binId, positionLiquidity, address(this));

        // If the order type is bid, the withdrawn liquidity is only composed of token X,
        // otherwise the withdrawn liquidity is only composed of token Y.
        position.amount = orderType == OrderType.BID ? amountX : amountY;

        emit OrderExecuted(msg.sender, lbPair, binId, orderType, positionId, positionLiquidity, amountX, amountY);
    }

    /**
     * @dev Deposit liquidity to a liquidity book pair.
     * @param lbPair The liquidity book pair.
     * @param token The token to deposit.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param amount The amount of the token to deposit.
     * @return amountX The amount of token X deposited.
     * @return amountY The amount of token Y deposited.
     * @return liquidity The liquidity deposited.
     */
    function _depositToLBPair(ILBPair lbPair, IERC20 token, OrderType orderType, uint24 binId, uint256 amount)
        private
        returns (uint256 amountX, uint256 amountY, uint256 liquidity)
    {
        // If the amount is 0, revert.
        if (amount == 0) revert LimitOrderManager__ZeroAmount();

        // Get the liquidity configurations, which is just adding liquidity to a single bin.
        bytes32[] memory liquidityConfigurations = new bytes32[](1);

        (uint64 distributionX, uint64 distributionY) =
            orderType == OrderType.BID ? (uint64(0), 1e18) : (1e18, uint64(0));

        liquidityConfigurations[0] = LiquidityConfigurations.encodeParams(distributionX, distributionY, binId);

        // Send the amount of the token to the liquidity book pair.
        token.safeTransferFrom(msg.sender, address(lbPair), amount);

        // Mint the liquidity to the liquidity book pair.
        (bytes32 packedAmountIn, bytes32 packedAmountExcess, uint256[] memory liquidities) =
            lbPair.mint(address(this), liquidityConfigurations, msg.sender);

        // Get the amount of token X and token Y deposited, which is the amount of the token minus the excess
        // as it's sent back to the `msg.sender` directly.
        (amountX, amountY) = packedAmountIn.sub(packedAmountExcess).decode();

        // Get the liquidity deposited.
        liquidity = liquidities[0];
    }

    /**
     * @dev Withdraw liquidity from a liquidity book pair.
     * @param lbPair The liquidity book pair.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binId The bin id of the order, which is the price of the order.
     * @param liquidity The liquidity to withdraw.
     * @param to The address to withdraw the liquidity to.
     * @return amountX The amount of token X withdrawn.
     * @return amountY The amount of token Y withdrawn.
     */
    function _withdrawFromLBPair(
        ILBPair lbPair,
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 binId,
        uint256 liquidity,
        address to
    ) private returns (uint128 amountX, uint128 amountY) {
        // Get the ids and amounts of the liquidity to burn.
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = binId;
        amounts[0] = liquidity;

        // Get the current balance of the token X and token Y.
        uint256 balanceX = tokenX.balanceOf(to);
        uint256 balanceY = tokenY.balanceOf(to);

        // Burn the liquidity from the liquidity book pair, sending the tokens directly to `to` address.
        lbPair.burn(address(this), to, ids, amounts);

        // Get the amount of token X and token Y withdrawn.
        amountX = (tokenX.balanceOf(to) - balanceX).safe128();
        amountY = (tokenY.balanceOf(to) - balanceY).safe128();
    }

    /**
     * @dev Get the order key.
     * The order key is composed of the liquidity book pair, the order type and the bin id, packed as follow:
     * - [255 - 96]: liquidity book pair address.
     * - [95 - 88]: order type (bid or ask)
     * - [87 - 24]: empty bits.
     * - [23 - 0]: bin id.
     * @param pair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return key The order key.
     */
    function _getOrderKey(ILBPair pair, OrderType orderType, uint24 binId) private pure returns (bytes32 key) {
        assembly {
            key := shl(96, pair)
            key := or(key, shl(88, and(orderType, 0xff)))
            key := or(key, and(binId, 0xffffff))
        }
    }

    /**
     * @dev Get the order key components.
     * @param key The order key, packed as follow:
     * - [255 - 96]: liquidity book pair address.
     * - [95 - 88]: order type (bid or ask)
     * - [87 - 24]: empty bits.
     * - [23 - 0]: bin id.
     * @return pair The liquidity book pair.
     * @return orderType The order type (bid or ask).
     * @return binId The bin id of the order, which is the price of the order.
     */
    function _getOrderKeyComponents(bytes32 key)
        private
        pure
        returns (ILBPair pair, OrderType orderType, uint24 binId)
    {
        // Get the order key components from the order key.
        assembly {
            pair := shr(96, key)
            orderType := and(shr(88, key), 0xff)
            binId := and(key, 0xffffff)
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

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {PackedUint128Math} from "./PackedUint128Math.sol";
import {Encoded} from "./Encoded.sol";

/**
 * @title Liquidity Book Liquidity Configurations Library
 * @author Trader Joe
 * @notice This library contains functions to encode and decode the config of a pool and interact with the encoded bytes32.
 */
library LiquidityConfigurations {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Encoded for bytes32;

    error LiquidityConfigurations__InvalidConfig();

    uint256 private constant OFFSET_ID = 0;
    uint256 private constant OFFSET_DISTRIBUTION_Y = 24;
    uint256 private constant OFFSET_DISTRIBUTION_X = 88;

    uint256 private constant PRECISION = 1e18;

    /**
     * @dev Encode the distributionX, distributionY and id into a single bytes32
     * @param distributionX The distribution of the first token
     * @param distributionY The distribution of the second token
     * @param id The id of the pool
     * @return config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     */
    function encodeParams(uint64 distributionX, uint64 distributionY, uint24 id)
        internal
        pure
        returns (bytes32 config)
    {
        config = config.set(distributionX, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_X);
        config = config.set(distributionY, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_Y);
        config = config.set(id, Encoded.MASK_UINT24, OFFSET_ID);
    }

    /**
     * @dev Decode the distributionX, distributionY and id from a single bytes32
     * @param config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     * @return distributionX The distribution of the first token
     * @return distributionY The distribution of the second token
     * @return id The id of the bin to add the liquidity to
     */
    function decodeParams(bytes32 config)
        internal
        pure
        returns (uint64 distributionX, uint64 distributionY, uint24 id)
    {
        distributionX = config.decodeUint64(OFFSET_DISTRIBUTION_X);
        distributionY = config.decodeUint64(OFFSET_DISTRIBUTION_Y);
        id = config.decodeUint24(OFFSET_ID);

        if (uint256(config) > type(uint152).max || distributionX > PRECISION || distributionY > PRECISION) {
            revert LiquidityConfigurations__InvalidConfig();
        }
    }

    /**
     * @dev Get the amounts and id from a config and amountsIn
     * @param config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     * @param amountsIn The amounts to distribute as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return amounts The distributed amounts as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return id The id of the bin to add the liquidity to
     */
    function getAmountsAndId(bytes32 config, bytes32 amountsIn) internal pure returns (bytes32, uint24) {
        (uint64 distributionX, uint64 distributionY, uint24 id) = decodeParams(config);

        (uint128 x1, uint128 x2) = amountsIn.decode();

        assembly {
            x1 := div(mul(x1, distributionX), PRECISION)
            x2 := div(mul(x2, distributionY), PRECISION)
        }

        return (x1.encode(x2), id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Constants} from "../Constants.sol";

/**
 * @title Liquidity Book Packed Uint128 Math Library
 * @author Trader Joe
 * @notice This library contains functions to encode and decode two uint128 into a single bytes32
 * and interact with the encoded bytes32.
 */
library PackedUint128Math {
    error PackedUint128Math__AddOverflow();
    error PackedUint128Math__SubUnderflow();
    error PackedUint128Math__MultiplierTooLarge();

    uint256 private constant OFFSET = 128;
    uint256 private constant MASK_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MASK_128_PLUS_ONE = MASK_128 + 1;

    /**
     * @dev Encodes two uint128 into a single bytes32
     * @param x1 The first uint128
     * @param x2 The second uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     */
    function encode(uint128 x1, uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := or(and(x1, MASK_128), shl(OFFSET, x2))
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first uint128
     * @param x1 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: empty
     */
    function encodeFirst(uint128 x1) internal pure returns (bytes32 z) {
        assembly {
            z := and(x1, MASK_128)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the second uint128
     * @param x2 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: empty
     * [128 - 256[: x2
     */
    function encodeSecond(uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := shl(OFFSET, x2)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first or second uint128
     * @param x The uint128
     * @param first Whether to encode as the first or second uint128
     * @return z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x
     */
    function encode(uint128 x, bool first) internal pure returns (bytes32 z) {
        return first ? encodeFirst(x) : encodeSecond(x);
    }

    /**
     * @dev Decodes a bytes32 into two uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return x1 The first uint128
     * @return x2 The second uint128
     */
    function decode(bytes32 z) internal pure returns (uint128 x1, uint128 x2) {
        assembly {
            x1 := and(z, MASK_128)
            x2 := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x
     * [128 - 256[: any
     * @return x The first uint128
     */
    function decodeX(bytes32 z) internal pure returns (uint128 x) {
        assembly {
            x := and(z, MASK_128)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the second uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: any
     * [128 - 256[: y
     * @return y The second uint128
     */
    function decodeY(bytes32 z) internal pure returns (uint128 y) {
        assembly {
            y := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first or second uint128
     * @param z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x1
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x2
     * @param first Whether to decode as the first or second uint128
     * @return x The decoded uint128
     */
    function decode(bytes32 z, bool first) internal pure returns (uint128 x) {
        return first ? decodeX(z) : decodeY(z);
    }

    /**
     * @dev Adds two encoded bytes32, reverting on overflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := add(x, y)
        }

        if (z < x || uint128(uint256(z)) < uint128(uint256(x))) {
            revert PackedUint128Math__AddOverflow();
        }
    }

    /**
     * @dev Adds an encoded bytes32 and two uint128, reverting on overflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return add(x, encode(y1, y2));
    }

    /**
     * @dev Subtracts two encoded bytes32, reverting on underflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := sub(x, y)
        }

        if (z > x || uint128(uint256(z)) > uint128(uint256(x))) {
            revert PackedUint128Math__SubUnderflow();
        }
    }

    /**
     * @dev Subtracts an encoded bytes32 and two uint128, reverting on underflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return sub(x, encode(y1, y2));
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function lt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 < y1 || x2 < y2;
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function gt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 > y1 || x2 > y2;
    }

    /**
     * @dev Multiplies an encoded bytes32 by a uint128 then divides the result by 10_000, rounding down
     * The result can't overflow as the multiplier needs to be smaller or equal to 10_000
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param multiplier The uint128 to multiply by (must be smaller or equal to 10_000)
     * @return z The product of x and multiplier encoded as follows:
     * [0 - 128[: floor((x1 * multiplier) / 10_000)
     * [128 - 256[: floor((x2 * multiplier) / 10_000)
     */
    function scalarMulDivBasisPointRoundDown(bytes32 x, uint128 multiplier) internal pure returns (bytes32 z) {
        if (multiplier == 0) return 0;

        uint256 BASIS_POINT_MAX = Constants.BASIS_POINT_MAX;
        if (multiplier > BASIS_POINT_MAX) revert PackedUint128Math__MultiplierTooLarge();

        (uint128 x1, uint128 x2) = decode(x);

        assembly {
            x1 := div(mul(x1, multiplier), BASIS_POINT_MAX)
            x2 := div(mul(x2, multiplier), BASIS_POINT_MAX)
        }

        return encode(x1, x2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Uint256x256 Math Library
 * @author Trader Joe
 * @notice Helper contract used for full precision calculations
 */
library Uint256x256Math {
    error Uint256x256Math__MulShiftOverflow();
    error Uint256x256Math__MulDivOverflow();

    /**
     * @notice Calculates floor(x*y/denominator) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x*y/denominator) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDivRoundDown(x, y, denominator);
        if (mulmod(x, y, denominator) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundDown(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Uint256x256Math__MulShiftOverflow();

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundUp(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        result = mulShiftRoundDown(x, y, offset);
        if (mulmod(x, y, 1 << offset) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x << offset / y) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundDown(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x << offset / y) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundUp(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
    }

    /**
     * @notice Helper function to return the result of `x * y` as 2 uint256
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @return prod0 The least significant 256 bits of the product
     * @return prod1 The most significant 256 bits of the product
     */
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /**
     * @notice Helper function to return the result of `x * y / denominator` with full precision
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @param prod0 The least significant 256 bits of the product
     * @param prod1 The most significant 256 bits of the product
     * @return result The result as an uint256
     */
    function _getEndOfDivRoundDown(uint256 x, uint256 y, uint256 denominator, uint256 prod0, uint256 prod1)
        private
        pure
        returns (uint256 result)
    {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Uint256x256Math__MulDivOverflow();

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
                inverse *= 2 - denominator * inverse; // inverse mod 2^8
                inverse *= 2 - denominator * inverse; // inverse mod 2^16
                inverse *= 2 - denominator * inverse; // inverse mod 2^32
                inverse *= 2 - denominator * inverse; // inverse mod 2^64
                inverse *= 2 - denominator * inverse; // inverse mod 2^128
                inverse *= 2 - denominator * inverse; // inverse mod 2^256

                // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
                // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
                // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
                // is no longer required.
                result = prod0 * inverse;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Safe Cast Library
 * @author Trader Joe
 * @notice This library contains functions to safely cast uint256 to different uint types.
 */
library SafeCast {
    error SafeCast__Exceeds248Bits();
    error SafeCast__Exceeds240Bits();
    error SafeCast__Exceeds232Bits();
    error SafeCast__Exceeds224Bits();
    error SafeCast__Exceeds216Bits();
    error SafeCast__Exceeds208Bits();
    error SafeCast__Exceeds200Bits();
    error SafeCast__Exceeds192Bits();
    error SafeCast__Exceeds184Bits();
    error SafeCast__Exceeds176Bits();
    error SafeCast__Exceeds168Bits();
    error SafeCast__Exceeds160Bits();
    error SafeCast__Exceeds152Bits();
    error SafeCast__Exceeds144Bits();
    error SafeCast__Exceeds136Bits();
    error SafeCast__Exceeds128Bits();
    error SafeCast__Exceeds120Bits();
    error SafeCast__Exceeds112Bits();
    error SafeCast__Exceeds104Bits();
    error SafeCast__Exceeds96Bits();
    error SafeCast__Exceeds88Bits();
    error SafeCast__Exceeds80Bits();
    error SafeCast__Exceeds72Bits();
    error SafeCast__Exceeds64Bits();
    error SafeCast__Exceeds56Bits();
    error SafeCast__Exceeds48Bits();
    error SafeCast__Exceeds40Bits();
    error SafeCast__Exceeds32Bits();
    error SafeCast__Exceeds24Bits();
    error SafeCast__Exceeds16Bits();
    error SafeCast__Exceeds8Bits();

    /**
     * @dev Returns x on uint248 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint248
     */
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits();
    }

    /**
     * @dev Returns x on uint240 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint240
     */
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits();
    }

    /**
     * @dev Returns x on uint232 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint232
     */
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits();
    }

    /**
     * @dev Returns x on uint224 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint224
     */
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits();
    }

    /**
     * @dev Returns x on uint216 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint216
     */
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits();
    }

    /**
     * @dev Returns x on uint208 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint208
     */
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits();
    }

    /**
     * @dev Returns x on uint200 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint200
     */
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits();
    }

    /**
     * @dev Returns x on uint192 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint192
     */
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits();
    }

    /**
     * @dev Returns x on uint184 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint184
     */
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits();
    }

    /**
     * @dev Returns x on uint176 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint176
     */
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits();
    }

    /**
     * @dev Returns x on uint168 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint168
     */
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits();
    }

    /**
     * @dev Returns x on uint160 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint160
     */
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits();
    }

    /**
     * @dev Returns x on uint152 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint152
     */
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits();
    }

    /**
     * @dev Returns x on uint144 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint144
     */
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits();
    }

    /**
     * @dev Returns x on uint136 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint136
     */
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits();
    }

    /**
     * @dev Returns x on uint128 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint128
     */
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits();
    }

    /**
     * @dev Returns x on uint120 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint120
     */
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits();
    }

    /**
     * @dev Returns x on uint112 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint112
     */
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits();
    }

    /**
     * @dev Returns x on uint104 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint104
     */
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits();
    }

    /**
     * @dev Returns x on uint96 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint96
     */
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits();
    }

    /**
     * @dev Returns x on uint88 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint88
     */
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits();
    }

    /**
     * @dev Returns x on uint80 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint80
     */
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits();
    }

    /**
     * @dev Returns x on uint72 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint72
     */
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits();
    }

    /**
     * @dev Returns x on uint64 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint64
     */
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits();
    }

    /**
     * @dev Returns x on uint56 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint56
     */
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits();
    }

    /**
     * @dev Returns x on uint48 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint48
     */
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits();
    }

    /**
     * @dev Returns x on uint40 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint40
     */
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits();
    }

    /**
     * @dev Returns x on uint32 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint32
     */
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits();
    }

    /**
     * @dev Returns x on uint24 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint24
     */
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits();
    }

    /**
     * @dev Returns x on uint16 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint16
     */
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits();
    }

    /**
     * @dev Returns x on uint8 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint8
     */
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";

/**
 * @title Limit Order Manager Interface
 * @author Trader Joe
 * @notice Interface to interact with the Limit Order Manager contract
 */
interface ILimitOrderManager {
    error LimitOrderManager__ZeroAddress();
    error LimitOrderManager__ZeroAmount();
    error LimitOrderManager__ZeroPositionLiquidity();
    error LimitOrderManager__InvalidPair();
    error LimitOrderManager__InvalidOrder();
    error LimitOrderManager__InvalidBatchLength();
    error LimitOrderManager__InvalidTokenOrder();
    error LimitOrderManager__OrderAlreadyExecuted();
    error LimitOrderManager__OrderNotClaimable();
    error LimitOrderManager__OrderNotPlaced();
    error LimitOrderManager__OrdersAlreadyExecuted();
    error LimitOrderManager__OrderNotExecutable();
    error LimitOrderManager__NoOrdersToExecute();

    /**
     * @dev Order type,
     * BID: buy tokenX with tokenY
     * ASK: sell tokenX for tokenY
     */
    enum OrderType {
        BID,
        ASK
    }

    /**
     * @dev Order structure:
     * - positionId: The position id of the order, used to identify to which position the order belongs
     * - liquidity: The amount of liquidity in the order
     */
    struct Order {
        uint256 positionId;
        uint256 liquidity;
    }

    /**
     * @dev Positions structure:
     * - lastId: The last position id
     * - at: The positions, indexed by position id
     * We use a mapping instead of an array as we need to be able to query the last position id
     * to know if a position exists or not, which would be impossible with an array.
     */
    struct Positions {
        uint256 lastId;
        mapping(uint256 => Position) at;
    }

    /**
     * @dev Position structure:
     * - liquidity: The amount of liquidity in the position, it is the sum of the liquidity of all orders
     * - amount: The amount of token after the execution of the position, once the orders are executed
     * - withdrawn: Whether the position has been withdrawn or not
     */
    struct Position {
        uint256 liquidity;
        uint128 amount;
        bool withdrawn;
    }

    /**
     * @dev Place order params structure, used to place multiple orders in a single transaction.
     */
    struct PlaceOrderParams {
        IERC20 tokenX;
        IERC20 tokenY;
        uint16 binStep;
        OrderType orderType;
        uint24 binId;
        uint256 amount;
    }

    /**
     * @dev Order params structure, used to cancel, claim and execute multiple orders in a single transaction.
     */
    struct OrderParams {
        IERC20 tokenX;
        IERC20 tokenY;
        uint16 binStep;
        OrderType orderType;
        uint24 binId;
    }

    /**
     * @dev Place order params structure for the same LB pair, used to place multiple orders in a single transaction
     * for the same LB pair
     */
    struct PlaceOrderParamsSamePair {
        OrderType orderType;
        uint24 binId;
        uint256 amount;
    }

    /**
     * @dev Order params structure for the same LB pair, used to cancel, claim and execute multiple orders in a single
     * transaction for the same LB pair
     */
    struct OrderParamsSamePair {
        OrderType orderType;
        uint24 binId;
    }

    event OrderPlaced(
        address indexed user,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event OrderCancelled(
        address indexed user,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event OrderClaimed(
        address indexed user,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event OrderExecuted(
        address indexed sender,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    function name() external pure returns (string memory);

    function getFactory() external view returns (ILBFactory);

    function getOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, address user)
        external
        view
        returns (Order memory);

    function getLastPositionId(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        returns (uint256);

    function getPosition(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        uint256 positionId
    ) external view returns (Position memory);

    function isOrderExecutable(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        returns (bool);

    function getCurrentAmounts(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        address user
    ) external view returns (uint256 amountX, uint256 amountY);

    function placeOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, uint256 amount)
        external
        returns (uint256 orderPositionId);

    function cancelOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        returns (uint256 orderPositionId);

    function claimOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        returns (uint256 orderPositionId);

    function executeOrders(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        returns (uint256 positionId);

    function batchPlaceOrders(PlaceOrderParams[] calldata orders) external returns (uint256[] memory positionIds);

    function batchCancelOrders(OrderParams[] calldata orders) external returns (uint256[] memory positionIds);

    function batchClaimOrders(OrderParams[] calldata orders) external returns (uint256[] memory positionIds);

    function batchExecuteOrders(OrderParams[] calldata orders) external returns (uint256[] memory positionIds);

    function batchPlaceOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        PlaceOrderParamsSamePair[] calldata orders
    ) external returns (uint256[] memory positionIds);

    function batchCancelOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external returns (uint256[] memory positionIds);

    function batchClaimOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external returns (uint256[] memory positionIds);

    function batchExecuteOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external returns (uint256[] memory positionIds);
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

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Encoded Library
 * @author Trader Joe
 * @notice Helper contract used for decoding bytes32 sample
 */
library Encoded {
    uint256 internal constant MASK_UINT1 = 0x1;
    uint256 internal constant MASK_UINT8 = 0xff;
    uint256 internal constant MASK_UINT12 = 0xfff;
    uint256 internal constant MASK_UINT14 = 0x3fff;
    uint256 internal constant MASK_UINT16 = 0xffff;
    uint256 internal constant MASK_UINT20 = 0xfffff;
    uint256 internal constant MASK_UINT24 = 0xffffff;
    uint256 internal constant MASK_UINT40 = 0xffffffffff;
    uint256 internal constant MASK_UINT64 = 0xffffffffffffffff;
    uint256 internal constant MASK_UINT128 = 0xffffffffffffffffffffffffffffffff;

    /**
     * @notice Internal function to set a value in an encoded bytes32 using a mask and offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param value The value to encode
     * @param mask The mask
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function set(bytes32 encoded, uint256 value, uint256 mask, uint256 offset)
        internal
        pure
        returns (bytes32 newEncoded)
    {
        assembly {
            newEncoded := and(encoded, not(shl(offset, mask)))
            newEncoded := or(newEncoded, shl(offset, and(value, mask)))
        }
    }

    /**
     * @notice Internal function to set a bool in an encoded bytes32 using an offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param boolean The bool to encode
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function setBool(bytes32 encoded, bool boolean, uint256 offset) internal pure returns (bytes32 newEncoded) {
        return set(encoded, boolean ? 1 : 0, MASK_UINT1, offset);
    }

    /**
     * @notice Internal function to decode a bytes32 sample using a mask and offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param mask The mask
     * @param offset The offset
     * @return value The decoded value
     */
    function decode(bytes32 encoded, uint256 mask, uint256 offset) internal pure returns (uint256 value) {
        assembly {
            value := and(shr(offset, encoded), mask)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a bool using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return boolean The decoded value as a bool
     */
    function decodeBool(bytes32 encoded, uint256 offset) internal pure returns (bool boolean) {
        assembly {
            boolean := and(shr(offset, encoded), MASK_UINT1)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint8 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint8(bytes32 encoded, uint256 offset) internal pure returns (uint8 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT8)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint12 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint12 is not supported
     */
    function decodeUint12(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT12)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint14 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint14 is not supported
     */
    function decodeUint14(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT14)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint16 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint16(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT16)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint20 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint24, since uint20 is not supported
     */
    function decodeUint20(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT20)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint24 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint24(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT24)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint40 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint40(bytes32 encoded, uint256 offset) internal pure returns (uint40 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT40)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint64 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint64(bytes32 encoded, uint256 offset) internal pure returns (uint64 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT64)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint128 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint128(bytes32 encoded, uint256 offset) internal pure returns (uint128 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT128)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Constants Library
 * @author Trader Joe
 * @notice Set of constants for Liquidity Book contracts
 */
library Constants {
    uint8 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant SQUARED_PRECISION = PRECISION * PRECISION;

    uint256 internal constant MAX_FEE = 0.1e18; // 10%
    uint256 internal constant MAX_PROTOCOL_SHARE = 2_500; // 25% of the fee

    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("LBPair.onFlashLoan");
}