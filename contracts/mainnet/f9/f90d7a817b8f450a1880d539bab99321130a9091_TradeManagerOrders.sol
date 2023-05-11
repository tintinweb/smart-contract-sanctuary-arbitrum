// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./TradeManager.sol";
import "./TradeSignature.sol";
import "../interfaces/ITradeManagerOrders.sol";

/**
 * @title TradeManagerOrders
 * @notice Exposes Functions to open, alter and close positions via signed orders.
 * @dev This contract is called by the Unlimited backend. This allows for an order book.
 */
contract TradeManagerOrders is ITradeManagerOrders, TradeSignature, TradeManager {
    using SafeERC20 for IERC20;

    mapping(bytes32 => TradeId) public sigHashToTradeId;

    /**
     * @notice Constructs the TradeManager contract.
     * @param controller_ The address of the controller.
     * @param userManager_ The address of the user manager.
     */
    constructor(IController controller_, IUserManager userManager_)
        TradeManager(controller_, userManager_)
        TradeSignature()
    {}

    /**
     * @notice Opens a position with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function openPositionViaSignature(
        OpenPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) returns (uint256) {
        _updateContracts(updateData_);
        _processSignature(order_, maker_, signature_);
        _verifyConstraints(
            order_.params.tradePair, order_.constraints, order_.params.isShort ? UsePrice.MIN : UsePrice.MAX
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        uint256 positionId = _openPosition(order_.params, maker_);

        sigHashToTradeId[keccak256(signature_)] = TradeId(order_.params.tradePair, uint96(positionId));

        emit OpenedPositionViaSignature(order_.params.tradePair, positionId, signature_);

        return positionId;
    }

    /**
     * @notice Closes a position with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function closePositionViaSignature(
        ClosePositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) {
        _updateContracts(updateData_);
        _processSignature(order_, maker_, signature_);

        _verifyConstraints(
            order_.params.tradePair,
            order_.constraints,
            ITradePair(order_.params.tradePair).positionIsShort(order_.params.positionId) ? UsePrice.MAX : UsePrice.MIN
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        // make for all orders
        _closePosition(_injectPositionIdToCloseOrder(order_).params, maker_);

        emit ClosedPositionViaSignature(order_.params.tradePair, order_.params.positionId, signature_);
    }

    /**
     * @notice Partially closes a position with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function partiallyClosePositionViaSignature(
        PartiallyClosePositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) {
        _updateContracts(updateData_);
        _processSignature(order_, maker_, signature_);

        // Verify Constraints
        _verifyConstraints(
            order_.params.tradePair,
            order_.constraints,
            ITradePair(order_.params.tradePair).positionIsShort(order_.params.positionId) ? UsePrice.MAX : UsePrice.MIN
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        _partiallyClosePosition(_injectPositionIdToPartiallyCloseOrder(order_).params, maker_);

        emit PartiallyClosedPositionViaSignature(order_.params.tradePair, order_.params.positionId, signature_);
    }

    /**
     * @notice Extends a position with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function extendPositionViaSignature(
        ExtendPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) {
        _updateContracts(updateData_);
        _processSignatureExtendPosition(order_, maker_, signature_);

        // Verify Constraints
        _verifyConstraints(
            order_.params.tradePair,
            order_.constraints,
            ITradePair(order_.params.tradePair).positionIsShort(order_.params.positionId) ? UsePrice.MIN : UsePrice.MAX
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        _extendPosition(_injectPositionIdToExtendOrder(order_).params, maker_);

        emit ExtendedPositionViaSignature(order_.params.tradePair, order_.params.positionId, signature_);
    }

    /**
     * @notice Partially extends a position to leverage with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function extendPositionToLeverageViaSignature(
        ExtendPositionToLeverageOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) {
        _updateContracts(updateData_);
        _processSignatureExtendPositionToLeverage(order_, maker_, signature_);

        // Verify Constraints
        _verifyConstraints(
            order_.params.tradePair,
            order_.constraints,
            ITradePair(order_.params.tradePair).positionIsShort(order_.params.positionId) ? UsePrice.MIN : UsePrice.MAX
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        _extendPositionToLeverage(_injectPositionIdToExtendToLeverageOrder(order_).params, maker_);

        emit ExtendedPositionToLeverageViaSignature(order_.params.tradePair, order_.params.positionId, signature_);
    }

    /**
     * @notice Adds margin to a position with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function addMarginToPositionViaSignature(
        AddMarginToPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) {
        _updateContracts(updateData_);
        _processSignatureAddMarginToPosition(order_, maker_, signature_);

        // Verify Constraints
        _verifyConstraints(
            order_.params.tradePair,
            order_.constraints,
            ITradePair(order_.params.tradePair).positionIsShort(order_.params.positionId) ? UsePrice.MAX : UsePrice.MIN
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        _addMarginToPosition(_injectPositionIdToAddMarginOrder(order_).params, maker_);

        emit AddedMarginToPositionViaSignature(order_.params.tradePair, order_.params.positionId, signature_);
    }

    /**
     * @notice Removes margin from a position with a signature
     * @param order_ Order struct
     * @param maker_ address of the maker
     * @param signature_ signature of order_ by maker_
     */
    function removeMarginFromPositionViaSignature(
        RemoveMarginFromPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) {
        _updateContracts(updateData_);
        _processSignatureRemoveMarginFromPosition(order_, maker_, signature_);

        // Verify Constraints
        _verifyConstraints(
            order_.params.tradePair,
            order_.constraints,
            ITradePair(order_.params.tradePair).positionIsShort(order_.params.positionId) ? UsePrice.MAX : UsePrice.MIN
        );

        _transferOrderReward(order_.params.tradePair, maker_, msg.sender);

        _removeMarginFromPosition(_injectPositionIdToRemoveMarginOrder(order_).params, maker_);

        emit RemovedMarginFromPositionViaSignature(order_.params.tradePair, order_.params.positionId, signature_);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash
     * @dev Retrieves the positionId from sigHashToPositionId via the order's signatureHash.
     * @param order_ Close Position Order
     * @return newOrder with positionId injected
     */
    function _injectPositionIdToCloseOrder(ClosePositionOrder calldata order_)
        internal
        view
        returns (ClosePositionOrder memory newOrder)
    {
        newOrder = order_;
        if (newOrder.params.positionId == type(uint256).max) {
            require(
                newOrder.signatureHash > 0,
                "TradeManagerOrders::_injectPositionIdToCloseOrder: Modify order requires either a position id or a signature hash"
            );

            TradeId memory tradeId = sigHashToTradeId[newOrder.signatureHash];

            require(
                tradeId.tradePair == newOrder.params.tradePair,
                "TradeManagerOrders::_injectPositionIdToCloseOrder: Wrong trade pair"
            );

            newOrder.params.positionId = tradeId.positionId;
        }
    }

    /**
     * @notice Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash
     * @dev Retrieves the positionId from sigHashToPositionId via the order's signatureHash.
     * @param order_ Partially Close Position Order
     * @return newOrder with positionId injected
     */
    function _injectPositionIdToPartiallyCloseOrder(PartiallyClosePositionOrder calldata order_)
        internal
        view
        returns (PartiallyClosePositionOrder memory newOrder)
    {
        newOrder = order_;
        if (newOrder.params.positionId == type(uint256).max) {
            require(
                newOrder.signatureHash > 0,
                "TradeManagerOrders::_injectPositionIdToPartiallyCloseOrder: Modify order requires either a position id or a signature hash"
            );

            TradeId memory tradeId = sigHashToTradeId[newOrder.signatureHash];

            require(
                tradeId.tradePair == newOrder.params.tradePair,
                "TradeManagerOrders::_injectPositionIdToPartiallyCloseOrder: Wrong trade pair"
            );

            newOrder.params.positionId = tradeId.positionId;
        }
    }

    /**
     * @notice Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash
     * @dev Retrieves the positionId from sigHashToPositionId via the order's signatureHash.
     * @param order_ Extend Position Order
     * @return newOrder with positionId injected
     */
    function _injectPositionIdToExtendOrder(ExtendPositionOrder calldata order_)
        internal
        view
        returns (ExtendPositionOrder memory newOrder)
    {
        newOrder = order_;
        if (newOrder.params.positionId == type(uint256).max) {
            require(
                newOrder.signatureHash > 0,
                "TradeManagerOrders::_injectPositionIdToExtendOrder: Modify order requires either a position id or a signature hash"
            );

            TradeId memory tradeId = sigHashToTradeId[newOrder.signatureHash];

            require(
                tradeId.tradePair == newOrder.params.tradePair,
                "TradeManagerOrders::_injectPositionIdToExtendOrder: Wrong trade pair"
            );

            newOrder.params.positionId = tradeId.positionId;
        }
    }

    /**
     * @notice Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash
     * @dev Retrieves the positionId from sigHashToPositionId via the order's signatureHash.
     * @param order_ Extend Position To Leverage Order
     * @return newOrder with positionId injected
     */
    function _injectPositionIdToExtendToLeverageOrder(ExtendPositionToLeverageOrder calldata order_)
        internal
        view
        returns (ExtendPositionToLeverageOrder memory newOrder)
    {
        newOrder = order_;
        if (newOrder.params.positionId == type(uint256).max) {
            require(
                newOrder.signatureHash > 0,
                "TradeManagerOrders::_injectPositionIdToExtendToLeverageOrder: Modify order requires either a position id or a signature hash"
            );

            TradeId memory tradeId = sigHashToTradeId[newOrder.signatureHash];

            require(
                tradeId.tradePair == newOrder.params.tradePair,
                "TradeManagerOrders::_injectPositionIdToExtendToLeverageOrder: Wrong trade pair"
            );

            newOrder.params.positionId = tradeId.positionId;
        }
    }

    /**
     * @notice Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash
     * @dev Retrieves the positionId from sigHashToPositionId via the order's signatureHash.
     * @param order_ Add Margin Order
     * @return newOrder with positionId injected
     */
    function _injectPositionIdToAddMarginOrder(AddMarginToPositionOrder calldata order_)
        internal
        view
        returns (AddMarginToPositionOrder memory newOrder)
    {
        newOrder = order_;
        if (newOrder.params.positionId == type(uint256).max) {
            require(
                newOrder.signatureHash > 0,
                "TradeManagerOrders::_injectPositionIdToAddMarginOrder: Modify order requires either a position id or a signature hash"
            );

            TradeId memory tradeId = sigHashToTradeId[newOrder.signatureHash];

            require(
                tradeId.tradePair == newOrder.params.tradePair,
                "TradeManagerOrders::_injectPositionIdToAddMarginOrder: Wrong trade pair"
            );

            newOrder.params.positionId = tradeId.positionId;
        }
    }

    /**
     * @notice Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash
     * @dev Retrieves the positionId from sigHashToPositionId via the order's signatureHash.
     * @param order_ Remove Margin Order
     * @return newOrder with positionId injected
     */
    function _injectPositionIdToRemoveMarginOrder(RemoveMarginFromPositionOrder calldata order_)
        internal
        view
        returns (RemoveMarginFromPositionOrder memory newOrder)
    {
        newOrder = order_;
        if (newOrder.params.positionId == type(uint256).max) {
            require(
                newOrder.signatureHash > 0,
                "TradeManagerOrders::_injectPositionIdToRemoveMarginOrder: Modify order requires either a position id or a signature hash"
            );

            TradeId memory tradeId = sigHashToTradeId[newOrder.signatureHash];

            require(
                tradeId.tradePair == newOrder.params.tradePair,
                "TradeManagerOrders::_injectPositionIdToRemoveMarginOrder: Wrong trade pair"
            );

            newOrder.params.positionId = tradeId.positionId;
        }
    }

    /**
     * @notice transfers the order reward from maker to executor
     * @param tradePair_ address of the trade pair (collateral is read from tradePair)
     * @param from_ address of the maker
     * @param to_ address of the executor
     */
    function _transferOrderReward(address tradePair_, address from_, address to_) internal {
        IERC20 collateral = ITradePair(tradePair_).collateral();
        uint256 orderReward = controller.orderRewardOfCollateral(address(collateral));
        if (orderReward > 0) {
            collateral.safeTransferFrom(from_, to_, orderReward);
        }

        emit OrderRewardTransfered(address(collateral), from_, to_, orderReward);
    }

    /* ========== RESCTRICTION FUNCTIONS ========== */

    function _verifyOrderExecutor() internal view {
        require(
            controller.isOrderExecutor(msg.sender),
            "TradeManagerOrders::_verifyOrderExecutor: Sender is not order executor"
        );
    }

    /* =========== MODIFIER =========== */

    modifier onlyOrderExecutor() {
        _verifyOrderExecutor();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITradeManager.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUpdatable.sol";
import "../interfaces/IUserManager.sol";

/**
 * @notice Indicates if the min or max price should be used. Depends on LONG or SHORT and buy or sell.
 * @custom:value MIN (0) indicates that the min price should be used
 * @custom:value MAX (1) indicates that the max price should be used
 */
enum UsePrice {
    MIN,
    MAX
}

/**
 * @title TradeManager
 * @notice Facilitates trading on trading pairs.
 */
contract TradeManager is ITradeManager {
    using SafeERC20 for IERC20;
    /* ========== STATE VARIABLES ========== */

    IController public immutable controller;
    IUserManager public immutable userManager;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the TradeManager contract.
     * @param controller_ The address of the controller.
     * @param userManager_ The address of the user manager.
     */
    constructor(IController controller_, IUserManager userManager_) {
        require(address(controller_) != address(0), "TradeManager::constructor: controller is 0 address");

        controller = controller_;
        userManager = userManager_;
    }

    /* ========== TRADING FUNCTIONS ========== */

    /**
     * @notice Opens a position for a trading pair.
     * @param params_ The parameters for opening a position.
     * @param maker_ Maker of the position
     */
    function _openPosition(OpenPositionParams memory params_, address maker_) internal returns (uint256) {
        ITradePair(params_.tradePair).collateral().safeTransferFrom(maker_, address(params_.tradePair), params_.margin);

        userManager.setUserReferrer(maker_, params_.referrer);

        uint256 id = ITradePair(params_.tradePair).openPosition(
            maker_, params_.margin, params_.leverage, params_.isShort, params_.whitelabelAddress
        );

        emit PositionOpened(params_.tradePair, id);

        return id;
    }

    /**
     * @notice Closes a position for a trading pair.
     *
     * @param params_ The parameters for closing the position.
     * @param maker_ Maker of the position
     */
    function _closePosition(ClosePositionParams memory params_, address maker_) internal {
        ITradePair(params_.tradePair).closePosition(maker_, params_.positionId);
        emit PositionClosed(params_.tradePair, params_.positionId);
    }

    /**
     * @notice Partially closes a position on a trade pair.
     * @param params_ The parameters for partially closing the position.
     * @param maker_ Maker of the position
     */
    function _partiallyClosePosition(PartiallyClosePositionParams memory params_, address maker_) internal {
        ITradePair(params_.tradePair).partiallyClosePosition(maker_, params_.positionId, params_.proportion);
        emit PositionPartiallyClosed(params_.tradePair, params_.positionId, params_.proportion);
    }

    /**
     * @notice Removes margin from a position
     * @param params_ The parameters for removing margin from the position.
     * @param maker_ Maker of the position
     */
    function _removeMarginFromPosition(RemoveMarginFromPositionParams memory params_, address maker_) internal {
        ITradePair(params_.tradePair).removeMarginFromPosition(maker_, params_.positionId, params_.removedMargin);

        emit MarginRemovedFromPosition(params_.tradePair, params_.positionId, params_.removedMargin);
    }

    /**
     * @notice Adds margin to a position
     * @param params_ The parameters for adding margin to the position.
     * @param maker_ Maker of the position
     */
    function _addMarginToPosition(AddMarginToPositionParams memory params_, address maker_) internal {
        // Transfer Collateral to TradePair
        ITradePair(params_.tradePair).collateral().safeTransferFrom(
            maker_, address(params_.tradePair), params_.addedMargin
        );

        ITradePair(params_.tradePair).addMarginToPosition(maker_, params_.positionId, params_.addedMargin);

        emit MarginAddedToPosition(params_.tradePair, params_.positionId, params_.addedMargin);
    }

    /**
     * @notice Extends position with margin and loan.
     * @param params_ The parameters for extending the position.
     * @param maker_ Maker of the position
     */
    function _extendPosition(ExtendPositionParams memory params_, address maker_) internal {
        // Transfer Collateral to TradePair
        ITradePair(params_.tradePair).collateral().safeTransferFrom(
            maker_, address(params_.tradePair), params_.addedMargin
        );

        ITradePair(params_.tradePair).extendPosition(
            maker_, params_.positionId, params_.addedMargin, params_.addedLeverage
        );

        emit PositionExtended(params_.tradePair, params_.positionId, params_.addedMargin, params_.addedLeverage);
    }

    /**
     * @notice Extends position with loan to target leverage.
     * @param params_ The parameters for extending the position to target leverage.
     * @param maker_ Maker of the position
     */
    function _extendPositionToLeverage(ExtendPositionToLeverageParams memory params_, address maker_) internal {
        ITradePair(params_.tradePair).extendPositionToLeverage(maker_, params_.positionId, params_.targetLeverage);

        emit PositionExtendedToLeverage(params_.tradePair, params_.positionId, params_.targetLeverage);
    }

    /* ========== LIQUIDATIONS ========== */

    /**
     * @notice Liquidates position
     * @param tradePair_ address of the trade pair
     * @param positionId_ position id
     * @param updateData_ Data to update state before the execution of the function
     */
    function liquidatePosition(address tradePair_, uint256 positionId_, UpdateData[] calldata updateData_)
        public
        onlyActiveTradePair(tradePair_)
    {
        _updateContracts(updateData_);
        ITradePair(tradePair_).liquidatePosition(msg.sender, positionId_);
        emit PositionLiquidated(tradePair_, positionId_);
    }

    /**
     * @notice Try to liquidate a position, return false if call reverts
     * @param tradePair_ address of the trade pair
     * @param positionId_ position id
     */
    function _tryLiquidatePosition(address tradePair_, uint256 positionId_, address maker_)
        internal
        onlyActiveTradePair(tradePair_)
        returns (bool)
    {
        try ITradePair(tradePair_).liquidatePosition(maker_, positionId_) {
            emit PositionLiquidated(tradePair_, positionId_);
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice Trys to liquidates all given positions
     * @param tradePairs addresses of the trade pairs
     * @param positionIds position ids
     * @param allowRevert if true, reverts if any call reverts
     * @return didLiquidate bool[][] results of the individual liquidation calls
     * @dev Requirements
     *
     * - `tradePairs` and `positionIds` must have the same length
     */
    function batchLiquidatePositions(
        address[] calldata tradePairs,
        uint256[][] calldata positionIds,
        bool allowRevert,
        UpdateData[] calldata updateData_
    ) external returns (bool[][] memory didLiquidate) {
        require(tradePairs.length == positionIds.length, "TradeManager::batchLiquidatePositions: invalid input");
        _updateContracts(updateData_);

        didLiquidate = new bool[][](tradePairs.length);

        for (uint256 i; i < tradePairs.length; ++i) {
            didLiquidate[i] =
                _batchLiquidatePositionsOfTradePair(tradePairs[i], positionIds[i], allowRevert, msg.sender);
        }
    }

    /**
     * @notice Trys to liquidates given positions of a trade pair
     * @param tradePair address of the trade pair
     * @param positionIds position ids
     * @param allowRevert if true, reverts if any call reverts
     * @return didLiquidate bool[] results of the individual liquidation calls
     */
    function _batchLiquidatePositionsOfTradePair(
        address tradePair,
        uint256[] calldata positionIds,
        bool allowRevert,
        address maker_
    ) internal returns (bool[] memory didLiquidate) {
        didLiquidate = new bool[](positionIds.length);

        for (uint256 i; i < positionIds.length; ++i) {
            if (_tryLiquidatePosition(tradePair, positionIds[i], maker_)) {
                didLiquidate[i] = true;
            } else {
                if (allowRevert) {
                    didLiquidate[i] = false;
                } else {
                    revert("TradeManager::_batchLiquidatePositionsOfTradePair: liquidation failed");
                }
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the details of a position
     * @dev returns PositionDetails struct
     * @param tradePair_ address of the trade pair
     * @param positionId_ id of the position
     */
    function detailsOfPosition(address tradePair_, uint256 positionId_)
        external
        view
        returns (PositionDetails memory)
    {
        return ITradePair(tradePair_).detailsOfPosition(positionId_);
    }

    /**
     * @notice Indicates if a position is liquidatable
     * @param tradePair_ address of the trade pair
     * @param positionId_ id of the position
     */
    function positionIsLiquidatable(address tradePair_, uint256 positionId_) public view returns (bool) {
        return ITradePair(tradePair_).positionIsLiquidatable(positionId_);
    }

    /**
     * @notice Indicates if the positions are liquidatable
     * @param tradePairs_ addresses of the trade pairs
     * @param positionIds_ ids of the positions
     * @return canLiquidate array of bools indicating if the positions are liquidatable
     * @dev Requirements:
     *
     * - tradePairs_ and positionIds_ must have the same length
     */
    function canLiquidatePositions(address[] calldata tradePairs_, uint256[][] calldata positionIds_)
        external
        view
        returns (bool[][] memory canLiquidate)
    {
        require(
            tradePairs_.length == positionIds_.length,
            "TradeManager::canLiquidatePositions: TradePair and PositionId arrays must be of same length"
        );
        canLiquidate = new bool[][](tradePairs_.length);
        for (uint256 i; i < tradePairs_.length; ++i) {
            // for positionId in positionIds_
            canLiquidate[i] = _canLiquidatePositionsAtTradePair(tradePairs_[i], positionIds_[i]);
        }
    }

    /**
     * @notice Indicates if the positions are liquidatable at a given price. Used for external liquidation simulation.
     * @param tradePairs_ addresses of the trade pairs
     * @param positionIds_ ids of the positions
     * @param prices_ price to check if positions are liquidatable at
     * @return canLiquidate array of bools indicating if the positions are liquidatable
     * @dev Requirements:
     *
     * - tradePairs_ and positionIds_ must have the same length
     */
    function canLiquidatePositionsAtPrices(
        address[] calldata tradePairs_,
        uint256[][] calldata positionIds_,
        int256[] calldata prices_
    ) external view returns (bool[][] memory canLiquidate) {
        require(
            tradePairs_.length == positionIds_.length,
            "TradeManager::canLiquidatePositions: tradePairs_ and positionIds_ arrays must be of same length"
        );
        require(
            tradePairs_.length == prices_.length,
            "TradeManager::canLiquidatePositions: tradePairs_ and prices_ arrays must be of same length"
        );
        canLiquidate = new bool[][](tradePairs_.length);
        for (uint256 i; i < tradePairs_.length; ++i) {
            // for positionId in positionIds_
            canLiquidate[i] = _canLiquidatePositionsAtPriceAtTradePair(tradePairs_[i], positionIds_[i], prices_[i]);
        }
    }

    /**
     * @notice Indicates if the positions are liquidatable at a given price.
     * @param tradePair_ address of the trade pair
     * @param positionIds_ ids of the positions
     * @return canLiquidate array of bools indicating if the positions are liquidatable
     */
    function _canLiquidatePositionsAtPriceAtTradePair(
        address tradePair_,
        uint256[] calldata positionIds_,
        int256 price_
    ) internal view returns (bool[] memory) {
        bool[] memory canLiquidate = new bool[](positionIds_.length);
        for (uint256 i; i < positionIds_.length; ++i) {
            canLiquidate[i] = ITradePair(tradePair_).positionIsLiquidatableAtPrice(positionIds_[i], price_);
        }
        return canLiquidate;
    }
    /**
     * @notice Indicates if the positions are liquidatable
     * @param tradePair_ address of the trade pair
     * @param positionIds_ ids of the positions
     * @return canLiquidate array of bools indicating if the positions are liquidatable
     */

    function _canLiquidatePositionsAtTradePair(address tradePair_, uint256[] calldata positionIds_)
        internal
        view
        returns (bool[] memory)
    {
        bool[] memory canLiquidate = new bool[](positionIds_.length);
        for (uint256 i; i < positionIds_.length; ++i) {
            canLiquidate[i] = positionIsLiquidatable(tradePair_, positionIds_[i]);
        }
        return canLiquidate;
    }

    /**
     * @notice Returns the current funding fee rates of a trade pair
     * @param tradePair_ address of the trade pair
     * @return longFundingFeeRate long funding fee rate
     * @return shortFundingFeeRate short funding fee rate
     */
    function getCurrentFundingFeeRates(address tradePair_)
        external
        view
        returns (int256 longFundingFeeRate, int256 shortFundingFeeRate)
    {
        return ITradePair(tradePair_).getCurrentFundingFeeRates();
    }

    /**
     * @notice Returns the total volume limit of a trade pair. Total Volume Limit is the maximum amount of volume for
     * each trade side.
     * @param tradePair_ address of the trade pair
     * @return totalVolumeLimit
     */
    function totalVolumeLimitOfTradePair(address tradePair_) external view returns (uint256) {
        return ITradePair(tradePair_).totalVolumeLimit();
    }

    /**
     * @dev Checks if constraints_ are satisfied. If not, reverts.
     * When the transaction staid in the mempool for a long time, the price may change.
     *
     * - Price is in price range
     * - Deadline is not exceeded
     */
    function _verifyConstraints(address tradePair_, Constraints calldata constraints_, UsePrice usePrice_)
        internal
        view
    {
        // Verify Deadline
        require(constraints_.deadline > block.timestamp, "TradeManager::_verifyConstraints: Deadline passed");

        // Verify Price
        {
            int256 markPrice;

            if (usePrice_ == UsePrice.MIN) {
                (markPrice,) = ITradePair(tradePair_).getCurrentPrices();
            } else {
                (, markPrice) = ITradePair(tradePair_).getCurrentPrices();
            }

            require(
                constraints_.minPrice <= markPrice && markPrice <= constraints_.maxPrice,
                "TradeManager::_verifyConstraints: Price out of bounds"
            );
        }
    }

    /**
     * @dev Updates all updatdable contracts. Reverts if one update operation is invalid or not successfull.
     */
    function _updateContracts(UpdateData[] calldata updateData_) internal {
        for (uint256 i; i < updateData_.length; ++i) {
            require(
                controller.isUpdatable(updateData_[i].updatableContract),
                "TradeManager::_updateContracts: Contract not updatable"
            );

            IUpdatable(updateData_[i].updatableContract).update(updateData_[i].data);
        }
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Checks if trading pair is active.
     * @param tradePair_ address of the trade pair
     */
    modifier onlyActiveTradePair(address tradePair_) {
        controller.checkTradePairActive(tradePair_);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../interfaces/ITradeManager.sol";
import "../interfaces/ITradeSignature.sol";

/**
 * @title TradeSignature
 * @notice This contract is used to verify signatures for trade orders
 * @dev This contract is based on the EIP712 standard
 */
contract TradeSignature is EIP712, ITradeSignature {
    bytes32 public constant OPEN_POSITION_ORDER_TYPEHASH = keccak256(
        "OpenPositionOrder(OpenPositionParams params,Constraints constraints,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)OpenPositionParams(address tradePair,uint256 margin,uint256 leverage,bool isShort,address referrer,address whitelabelAddress)"
    );

    bytes32 public constant OPEN_POSITION_PARAMS_TYPEHASH = keccak256(
        "OpenPositionParams(address tradePair,uint256 margin,uint256 leverage,bool isShort,address referrer,address whitelabelAddress)"
    );

    bytes32 public constant CLOSE_POSITION_ORDER_TYPEHASH = keccak256(
        "ClosePositionOrder(ClosePositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)ClosePositionParams(address tradePair,uint256 positionId)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)"
    );

    bytes32 public constant CLOSE_POSITION_PARAMS_TYPEHASH =
        keccak256("ClosePositionParams(address tradePair,uint256 positionId)");

    bytes32 public constant PARTIALLY_CLOSE_POSITION_ORDER_TYPEHASH = keccak256(
        "PartiallyClosePositionOrder(PartiallyClosePositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)PartiallyClosePositionParams(address tradePair,uint256 positionId,uint256 proportion)"
    );

    bytes32 public constant PARTIALLY_CLOSE_POSITION_PARAMS_TYPEHASH =
        keccak256("PartiallyClosePositionParams(address tradePair,uint256 positionId,uint256 proportion)");

    bytes32 public constant EXTEND_POSITION_ORDER_TYPEHASH = keccak256(
        "ExtendPositionOrder(ExtendPositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)ExtendPositionParams(address tradePair,uint256 positionId,uint256 addedMargin,uint256 addedLeverage)"
    );

    bytes32 public constant EXTEND_POSITION_PARAMS_TYPEHASH = keccak256(
        "ExtendPositionParams(address tradePair,uint256 positionId,uint256 addedMargin,uint256 addedLeverage)"
    );

    bytes32 public constant EXTEND_POSITION_TO_LEVERAGE_ORDER_TYPEHASH = keccak256(
        "ExtendPositionToLeverageOrder(ExtendPositionToLeverageParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)ExtendPositionToLeverageParams(address tradePair,uint256 positionId,uint256 targetLeverage)"
    );

    bytes32 public constant EXTEND_POSITION_TO_LEVERAGE_PARAMS_TYPEHASH =
        keccak256("ExtendPositionToLeverageParams(address tradePair,uint256 positionId,uint256 targetLeverage)");

    bytes32 public constant REMOVE_MARGIN_FROM_POSITION_ORDER_TYPEHASH = keccak256(
        "RemoveMarginFromPositionOrder(RemoveMarginFromPositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)RemoveMarginFromPositionParams(address tradePair,uint256 positionId,uint256 removedMargin)"
    );

    bytes32 public constant REMOVE_MARGIN_FROM_POSITION_PARAMS_TYPEHASH =
        keccak256("RemoveMarginFromPositionParams(address tradePair,uint256 positionId,uint256 removedMargin)");

    bytes32 public constant ADD_MARGIN_TO_POSITION_ORDER_TYPEHASH = keccak256(
        "AddMarginToPositionOrder(AddMarginToPositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)AddMarginToPositionParams(address tradePair,uint256 positionId,uint256 addedMargin)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)"
    );

    bytes32 public constant ADD_MARGIN_TO_POSITION_PARAMS_TYPEHASH =
        keccak256("AddMarginToPositionParams(address tradePair,uint256 positionId,uint256 addedMargin)");

    bytes32 public constant CONSTRAINTS_TYPEHASH =
        keccak256("Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)");

    mapping(bytes => bool) public isProcessedSignature;

    /**
     * @notice Constructs the TradeSignature Contract
     * @dev Constructs the EIP712 Contract
     */
    constructor() EIP712("UnlimitedLeverage", "1") {}

    /* =================== INTERNAL SIGNATURE FUNCTIONS ================== */

    function _processSignature(
        OpenPositionOrder calldata openPositionOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hash(openPositionOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    function _processSignature(
        ClosePositionOrder calldata closePositionOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hash(closePositionOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    function _processSignature(
        PartiallyClosePositionOrder calldata partiallyClosePositionOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hashPartiallyClosePositionOrder(partiallyClosePositionOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    function _processSignatureExtendPosition(
        ExtendPositionOrder calldata extendPositionOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hashExtendPositionOrder(extendPositionOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    function _processSignatureExtendPositionToLeverage(
        ExtendPositionToLeverageOrder calldata extendPositionToLeverageOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hashExtendPositionToLeverageOrder(extendPositionToLeverageOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    function _processSignatureRemoveMarginFromPosition(
        RemoveMarginFromPositionOrder calldata removeMarginFromPositionOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hashRemoveMarginFromPositionOrder(removeMarginFromPositionOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    function _processSignatureAddMarginToPosition(
        AddMarginToPositionOrder calldata addMarginToPositionOrder_,
        address signer_,
        bytes calldata signature_
    ) internal {
        _onlyNonProcessedSignature(signature_);
        _verifySignature(hashAddMarginToPositionOrder(addMarginToPositionOrder_), signer_, signature_);
        _registerProcessedSignature(signature_);
    }

    /* =================== INTERNAL FUNCTIONS ================== */

    function _verifySignature(bytes32 hash_, address signer_, bytes calldata signature_) private view {
        require(
            SignatureChecker.isValidSignatureNow(signer_, hash_, signature_),
            "TradeSignature::_verifySignature: Signature is not valid"
        );
    }

    function _registerProcessedSignature(bytes calldata signature_) private {
        isProcessedSignature[signature_] = true;
    }

    function _onlyNonProcessedSignature(bytes calldata signature_) private view {
        require(
            !isProcessedSignature[signature_], "TradeSignature::_onlyNonProcessedSignature: Signature already processed"
        );
    }

    /* =========== PUBLIC HASH FUNCTIONS =========== */

    function hash(OpenPositionOrder calldata openPositionOrder) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    OPEN_POSITION_ORDER_TYPEHASH,
                    hash(openPositionOrder.params),
                    hash(openPositionOrder.constraints),
                    openPositionOrder.salt
                )
            )
        );
    }

    function hash(OpenPositionParams calldata openPositionParams) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                OPEN_POSITION_PARAMS_TYPEHASH,
                openPositionParams.tradePair,
                openPositionParams.margin,
                openPositionParams.leverage,
                openPositionParams.isShort,
                openPositionParams.referrer,
                openPositionParams.whitelabelAddress
            )
        );
    }

    function hash(ClosePositionOrder calldata closePositionOrder) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    CLOSE_POSITION_ORDER_TYPEHASH,
                    hash(closePositionOrder.params),
                    hash(closePositionOrder.constraints),
                    closePositionOrder.signatureHash,
                    closePositionOrder.salt
                )
            )
        );
    }

    function hash(ClosePositionParams calldata closePositionParams) public pure returns (bytes32) {
        return keccak256(
            abi.encode(CLOSE_POSITION_PARAMS_TYPEHASH, closePositionParams.tradePair, closePositionParams.positionId)
        );
    }

    function hashPartiallyClosePositionOrder(PartiallyClosePositionOrder calldata partiallyClosePositionOrder)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PARTIALLY_CLOSE_POSITION_ORDER_TYPEHASH,
                    hashPartiallyClosePositionParams(partiallyClosePositionOrder.params),
                    hash(partiallyClosePositionOrder.constraints),
                    partiallyClosePositionOrder.signatureHash,
                    partiallyClosePositionOrder.salt
                )
            )
        );
    }

    function hashPartiallyClosePositionParams(PartiallyClosePositionParams calldata partiallyClosePositionParams)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                PARTIALLY_CLOSE_POSITION_PARAMS_TYPEHASH,
                partiallyClosePositionParams.tradePair,
                partiallyClosePositionParams.positionId,
                partiallyClosePositionParams.proportion
            )
        );
    }

    function hashExtendPositionOrder(ExtendPositionOrder calldata extendPositionOrder) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EXTEND_POSITION_ORDER_TYPEHASH,
                    hashExtendPositionParams(extendPositionOrder.params),
                    hash(extendPositionOrder.constraints),
                    extendPositionOrder.signatureHash,
                    extendPositionOrder.salt
                )
            )
        );
    }

    function hashExtendPositionParams(ExtendPositionParams calldata extendPositionParams)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                EXTEND_POSITION_PARAMS_TYPEHASH,
                extendPositionParams.tradePair,
                extendPositionParams.positionId,
                extendPositionParams.addedMargin,
                extendPositionParams.addedLeverage
            )
        );
    }

    function hashExtendPositionToLeverageOrder(ExtendPositionToLeverageOrder calldata extendPositionToLeverageOrder)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EXTEND_POSITION_TO_LEVERAGE_ORDER_TYPEHASH,
                    hashExtendPositionToLeverageParams(extendPositionToLeverageOrder.params),
                    hash(extendPositionToLeverageOrder.constraints),
                    extendPositionToLeverageOrder.signatureHash,
                    extendPositionToLeverageOrder.salt
                )
            )
        );
    }

    function hashExtendPositionToLeverageParams(ExtendPositionToLeverageParams calldata extendPositionToLeverageParams)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                EXTEND_POSITION_TO_LEVERAGE_PARAMS_TYPEHASH,
                extendPositionToLeverageParams.tradePair,
                extendPositionToLeverageParams.positionId,
                extendPositionToLeverageParams.targetLeverage
            )
        );
    }

    function hashAddMarginToPositionOrder(AddMarginToPositionOrder calldata addMarginToPositionOrder)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ADD_MARGIN_TO_POSITION_ORDER_TYPEHASH,
                    hashAddMarginToPositionParams(addMarginToPositionOrder.params),
                    hash(addMarginToPositionOrder.constraints),
                    addMarginToPositionOrder.signatureHash,
                    addMarginToPositionOrder.salt
                )
            )
        );
    }

    function hashAddMarginToPositionParams(AddMarginToPositionParams calldata addMarginToPositionParams)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                ADD_MARGIN_TO_POSITION_PARAMS_TYPEHASH,
                addMarginToPositionParams.tradePair,
                addMarginToPositionParams.positionId,
                addMarginToPositionParams.addedMargin
            )
        );
    }

    function hashRemoveMarginFromPositionOrder(RemoveMarginFromPositionOrder calldata removeMarginFromPositionOrder)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    REMOVE_MARGIN_FROM_POSITION_ORDER_TYPEHASH,
                    hashRemoveMarginFromPositionParams(removeMarginFromPositionOrder.params),
                    hash(removeMarginFromPositionOrder.constraints),
                    removeMarginFromPositionOrder.signatureHash,
                    removeMarginFromPositionOrder.salt
                )
            )
        );
    }

    function hashRemoveMarginFromPositionParams(RemoveMarginFromPositionParams calldata removeMarginFromPositionParams)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                REMOVE_MARGIN_FROM_POSITION_PARAMS_TYPEHASH,
                removeMarginFromPositionParams.tradePair,
                removeMarginFromPositionParams.positionId,
                removeMarginFromPositionParams.removedMargin
            )
        );
    }

    function hash(Constraints calldata constraints) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(CONSTRAINTS_TYPEHASH, constraints.deadline, constraints.minPrice, constraints.maxPrice)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/ITradeManager.sol";
import "../interfaces/ITradeSignature.sol";

interface ITradeManagerOrders is ITradeManager, ITradeSignature {
    /* ========== EVENTS ========== */

    event OpenedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);

    event ClosedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);

    event PartiallyClosedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);

    event ExtendedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);

    event ExtendedPositionToLeverageViaSignature(
        address indexed tradePair, uint256 indexed id, bytes indexed signature
    );

    event AddedMarginToPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);

    event RemovedMarginFromPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);

    event OrderRewardTransfered(
        address indexed collateral, address indexed from, address indexed to, uint256 orderReward
    );

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    function openPositionViaSignature(
        OpenPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external returns (uint256 positionId);

    function closePositionViaSignature(
        ClosePositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external;

    function partiallyClosePositionViaSignature(
        PartiallyClosePositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external;

    function removeMarginFromPositionViaSignature(
        RemoveMarginFromPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external;

    function addMarginToPositionViaSignature(
        AddMarginToPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external;

    function extendPositionViaSignature(
        ExtendPositionOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external;

    function extendPositionToLeverageViaSignature(
        ExtendPositionToLeverageOrder calldata order_,
        UpdateData[] calldata updateData_,
        address maker_,
        bytes calldata signature_
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IController {
    /* ========== EVENTS ========== */

    event TradePairAdded(address indexed tradePair);

    event LiquidityPoolAdded(address indexed liquidityPool);

    event LiquidityPoolAdapterAdded(address indexed liquidityPoolAdapter);

    event PriceFeedAdded(address indexed priceFeed);

    event UpdatableAdded(address indexed updatable);

    event TradePairRemoved(address indexed tradePair);

    event LiquidityPoolRemoved(address indexed liquidityPool);

    event LiquidityPoolAdapterRemoved(address indexed liquidityPoolAdapter);

    event PriceFeedRemoved(address indexed priceFeed);

    event UpdatableRemoved(address indexed updatable);

    event SignerAdded(address indexed signer);

    event SignerRemoved(address indexed signer);

    event OrderExecutorAdded(address indexed orderExecutor);

    event OrderExecutorRemoved(address indexed orderExecutor);

    event SetOrderRewardOfCollateral(address indexed collateral_, uint256 reward_);

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Is trade pair registered
    function isTradePair(address tradePair) external view returns (bool);

    /// @notice Is liquidity pool registered
    function isLiquidityPool(address liquidityPool) external view returns (bool);

    /// @notice Is liquidity pool adapter registered
    function isLiquidityPoolAdapter(address liquidityPoolAdapter) external view returns (bool);

    /// @notice Is price fee adapter registered
    function isPriceFeed(address priceFeed) external view returns (bool);

    /// @notice Is contract updatable
    function isUpdatable(address contractAddress) external view returns (bool);

    /// @notice Is Signer registered
    function isSigner(address signer) external view returns (bool);

    /// @notice Is order executor registered
    function isOrderExecutor(address orderExecutor) external view returns (bool);

    /// @notice Reverts if trade pair inactive
    function checkTradePairActive(address tradePair) external view;

    /// @notice Returns order reward for collateral token
    function orderRewardOfCollateral(address collateral) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Adds the trade pair to the registry
     */
    function addTradePair(address tradePair) external;

    /**
     * @notice Adds the liquidity pool to the registry
     */
    function addLiquidityPool(address liquidityPool) external;

    /**
     * @notice Adds the liquidity pool adapter to the registry
     */
    function addLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Adds the price feed to the registry
     */
    function addPriceFeed(address priceFeed) external;

    /**
     * @notice Adds updatable contract to the registry
     */
    function addUpdatable(address) external;

    /**
     * @notice Adds signer to the registry
     */
    function addSigner(address) external;

    /**
     * @notice Adds order executor to the registry
     */
    function addOrderExecutor(address) external;

    /**
     * @notice Removes the trade pair from the registry
     */
    function removeTradePair(address tradePair) external;

    /**
     * @notice Removes the liquidity pool from the registry
     */
    function removeLiquidityPool(address liquidityPool) external;

    /**
     * @notice Removes the liquidity pool adapter from the registry
     */
    function removeLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Removes the price feed from the registry
     */
    function removePriceFeed(address priceFeed) external;

    /**
     * @notice Removes updatable from the registry
     */
    function removeUpdatable(address) external;

    /**
     * @notice Removes signer from the registry
     */
    function removeSigner(address) external;

    /**
     * @notice Removes order executor from the registry
     */
    function removeOrderExecutor(address) external;

    /**
     * @notice Sets order reward for collateral token
     */
    function setOrderRewardOfCollateral(address, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IController.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Parameters for opening a position
 * @custom:member tradePair The trade pair to open the position on
 * @custom:member margin The amount of margin to use for the position
 * @custom:member leverage The leverage to open the position with
 * @custom:member isShort Whether the position is a short position
 * @custom:member referrer The address of the referrer or zero
 * @custom:member whitelabelAddress The address of the whitelabel or zero
 */
struct OpenPositionParams {
    address tradePair;
    uint256 margin;
    uint256 leverage;
    bool isShort;
    address referrer;
    address whitelabelAddress;
}

/**
 * @notice Parameters for closing a position
 * @custom:member tradePair The trade pair to close the position on
 * @custom:member positionId The id of the position to close
 */
struct ClosePositionParams {
    address tradePair;
    uint256 positionId;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member proportion the proportion of the position to close
 * @custom:member leaveLeverageFactor the leaveLeverage / takeProfit factor
 */
struct PartiallyClosePositionParams {
    address tradePair;
    uint256 positionId;
    uint256 proportion;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member removedMargin The amount of margin to remove
 */
struct RemoveMarginFromPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 removedMargin;
}

/**
 * @notice Parameters for adding margin to a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 */
struct AddMarginToPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
}

/**
 * @notice Parameters for extending a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 * @custom:member addedLeverage The leverage used on the addedMargin
 */
struct ExtendPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
    uint256 addedLeverage;
}

/**
 * @notice Parameters for extending a position to a target leverage
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member targetLeverage the target leverage to close to
 */
struct ExtendPositionToLeverageParams {
    address tradePair;
    uint256 positionId;
    uint256 targetLeverage;
}

/**
 * @notice Constraints to constraint the opening, alteration or closing of a position
 * @custom:member deadline The deadline for the transaction
 * @custom:member minPrice a minimum price for the transaction
 * @custom:member maxPrice a maximum price for the transaction
 */
struct Constraints {
    uint256 deadline;
    int256 minPrice;
    int256 maxPrice;
}

/**
 * @notice Parameters for opening a position
 * @custom:member params The parameters for opening a position
 * @custom:member constraints The constraints for opening a position
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct OpenPositionOrder {
    OpenPositionParams params;
    Constraints constraints;
    uint256 salt;
}

/**
 * @notice Parameters for closing a position
 * @custom:member params The parameters for closing a position
 * @custom:member constraints The constraints for closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ClosePositionOrder {
    ClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member params The parameters for partially closing a position
 * @custom:member constraints The constraints for partially closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct PartiallyClosePositionOrder {
    PartiallyClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position
 * @custom:member params The parameters for extending a position
 * @custom:member constraints The constraints for extending a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionOrder {
    ExtendPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position to leverage
 * @custom:member params The parameters for extending a position to leverage
 * @custom:member constraints The constraints for extending a position to leverage
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionToLeverageOrder {
    ExtendPositionToLeverageParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters foradding margin to a position
 * @custom:member params The parameters foradding margin to a position
 * @custom:member constraints The constraints foradding margin to a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct AddMarginToPositionOrder {
    AddMarginToPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member params The parameters for removing margin from a position
 * @custom:member constraints The constraints for removing margin from a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct RemoveMarginFromPositionOrder {
    RemoveMarginFromPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice UpdateData for updatable contracts like the UnlimitedPriceFeed
 * @custom:member updatableContract The address of the updatable contract
 * @custom:member data The data to update the contract with
 */
struct UpdateData {
    address updatableContract;
    bytes data;
}

/**
 * @notice Struct to store tradePair and positionId together.
 * @custom:member tradePair the address of the tradePair
 * @custom:member positionId the positionId of the position
 */
struct TradeId {
    address tradePair;
    uint96 positionId;
}

interface ITradeManager {
    /* ========== EVENTS ========== */

    event PositionOpened(address indexed tradePair, uint256 indexed id);

    event PositionClosed(address indexed tradePair, uint256 indexed id);

    event PositionPartiallyClosed(address indexed tradePair, uint256 indexed id, uint256 proportion);

    event PositionLiquidated(address indexed tradePair, uint256 indexed id);

    event PositionExtended(address indexed tradePair, uint256 indexed id, uint256 addedMargin, uint256 addedLeverage);

    event PositionExtendedToLeverage(address indexed tradePair, uint256 indexed id, uint256 targetLeverage);

    event MarginAddedToPosition(address indexed tradePair, uint256 indexed id, uint256 addedMargin);

    event MarginRemovedFromPosition(address indexed tradePair, uint256 indexed id, uint256 removedMargin);

    /* ========== CORE FUNCTIONS - LIQUIDATIONS ========== */

    function liquidatePosition(address tradePair, uint256 positionId, UpdateData[] calldata updateData) external;

    function batchLiquidatePositions(
        address[] calldata tradePairs,
        uint256[][] calldata positionIds,
        bool allowRevert,
        UpdateData[] calldata updateData
    ) external returns (bool[][] memory didLiquidate);

    /* =========== VIEW FUNCTIONS ========== */

    function detailsOfPosition(address tradePair, uint256 positionId) external view returns (PositionDetails memory);

    function positionIsLiquidatable(address tradePair, uint256 positionId) external view returns (bool);

    function canLiquidatePositions(address[] calldata tradePairs, uint256[][] calldata positionIds)
        external
        view
        returns (bool[][] memory canLiquidate);

    function canLiquidatePositionsAtPrices(
        address[] calldata tradePairs_,
        uint256[][] calldata positionIds_,
        int256[] calldata prices_
    ) external view returns (bool[][] memory canLiquidate);

    function getCurrentFundingFeeRates(address tradePair) external view returns (int256, int256);

    function totalVolumeLimitOfTradePair(address tradePair_) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IFeeManager.sol";
import "./ILiquidityPoolAdapter.sol";
import "./IPriceFeedAdapter.sol";
import "./ITradeManager.sol";
import "./IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Struct with details of a position, returned by the detailsOfPosition function
 * @custom:member id the position id
 * @custom:member margin the margin of the position
 * @custom:member volume the entry volume of the position
 * @custom:member size the size of the position
 * @custom:member leverage the size of the position
 * @custom:member isShort bool if the position is short
 * @custom:member entryPrice The entry price of the position
 * @custom:member markPrice The (current) mark price of the position
 * @custom:member bankruptcyPrice the bankruptcy price of the position
 * @custom:member equity the current net equity of the position
 * @custom:member PnL the current net PnL of the position
 * @custom:member totalFeeAmount the totalFeeAmount of the position
 * @custom:member currentVolume the current volume of the position
 */
struct PositionDetails {
    uint256 id;
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    uint256 leverage;
    bool isShort;
    int256 entryPrice;
    int256 liquidationPrice;
    int256 currentBorrowFeeAmount;
    int256 currentFundingFeeAmount;
}

/**
 * @notice Struct with a minimum and maximum price
 * @custom:member minPrice the minimum price
 * @custom:member maxPrice the maximum price
 */
struct PricePair {
    int256 minPrice;
    int256 maxPrice;
}

interface ITradePair {
    /* ========== ENUMS ========== */

    enum PositionAlterationType {
        partiallyClose,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== EVENTS ========== */

    event OpenedPosition(address maker, uint256 id, uint256 margin, uint256 volume, uint256 size, bool isShort);

    event ClosedPosition(uint256 id, int256 closePrice);

    event LiquidatedPosition(uint256 indexed id, address indexed liquidator);

    event AlteredPosition(
        PositionAlterationType alterationType, uint256 id, uint256 netMargin, uint256 volume, uint256 size
    );

    event UpdatedFeesOfPosition(uint256 id, int256 totalFeeAmount, uint256 lastNetMargin);

    event DepositedOpenFees(address user, uint256 amount, uint256 positionId);

    event DepositedCloseFees(address user, uint256 amount, uint256 positionId);

    event FeeOvercollected(int256 amount);

    event PayedOutCollateral(address maker, uint256 amount, uint256 positionId);

    event LiquidityGapWarning(uint256 amount);

    event RealizedPnL(
        address indexed maker,
        uint256 indexed positionId,
        int256 realizedPnL,
        int256 realizedBorrowFeeAmount,
        int256 realizedFundingFeeAmount
    );

    event UpdatedFeeIntegrals(int256 borrowFeeIntegral, int256 longFundingFeeIntegral, int256 shortFundingFeeIntegral);

    event SetTotalVolumeLimit(uint256 totalVolumeLimit);

    event DepositedBorrowFees(uint256 amount);

    event RegisteredProtocolPnL(int256 protocolPnL, uint256 payout);

    event SetBorrowFeeRate(int256 borrowFeeRate);

    event SetMaxFundingFeeRate(int256 maxFundingFeeRate);

    event SetMaxExcessRatio(int256 maxExcessRatio);

    event SetLiquidatorReward(uint256 liquidatorReward);

    event SetMinLeverage(uint128 minLeverage);

    event SetMaxLeverage(uint128 maxLeverage);

    event SetMinMargin(uint256 minMargin);

    event SetVolumeLimit(uint256 volumeLimit);

    event SetFeeBufferFactor(int256 feeBufferFactor);

    event SetTotalAssetAmountLimit(uint256 totalAssetAmountLimit);

    event SetPriceFeedAdapter(address priceFeedAdapter);

    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function collateral() external view returns (IERC20);

    function detailsOfPosition(uint256 positionId) external view returns (PositionDetails memory);

    function priceFeedAdapter() external view returns (IPriceFeedAdapter);

    function liquidityPoolAdapter() external view returns (ILiquidityPoolAdapter);

    function userManager() external view returns (IUserManager);

    function feeManager() external view returns (IFeeManager);

    function tradeManager() external view returns (ITradeManager);

    function positionIsLiquidatable(uint256 positionId) external view returns (bool);

    function positionIsLiquidatableAtPrice(uint256 positionId, int256 price) external view returns (bool);

    function getCurrentFundingFeeRates() external view returns (int256, int256);

    function getCurrentPrices() external view returns (int256, int256);

    function positionIsShort(uint256) external view returns (bool);

    function collateralToPriceMultiplier() external view returns (uint256);

    /* ========== GENERATED VIEW FUNCTIONS ========== */

    function feeIntegral() external view returns (int256, int256, int256, int256, int256, int256, uint256);

    function liquidatorReward() external view returns (uint256);

    function maxLeverage() external view returns (uint128);

    function minLeverage() external view returns (uint128);

    function minMargin() external view returns (uint256);

    function volumeLimit() external view returns (uint256);

    function totalVolumeLimit() external view returns (uint256);

    function positionStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function overcollectedFees() external view returns (int256);

    function feeBuffer() external view returns (int256, int256);

    function positionIdToWhiteLabel(uint256) external view returns (address);

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    function openPosition(address maker, uint256 margin, uint256 leverage, bool isShort, address whitelabelAddress)
        external
        returns (uint256 positionId);

    function closePosition(address maker, uint256 positionId) external;

    function addMarginToPosition(address maker, uint256 positionId, uint256 margin) external;

    function removeMarginFromPosition(address maker, uint256 positionId, uint256 removedMargin) external;

    function partiallyClosePosition(address maker, uint256 positionId, uint256 proportion) external;

    function extendPosition(address maker, uint256 positionId, uint256 addedMargin, uint256 addedLeverage) external;

    function extendPositionToLeverage(address maker, uint256 positionId, uint256 targetLeverage) external;

    function liquidatePosition(address liquidator, uint256 positionId) external;

    /* ========== CORE FUNCTIONS - FEES ========== */

    function syncPositionFees() external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(
        string memory name,
        IERC20Metadata collateral,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) external;

    function setBorrowFeeRate(int256 borrowFeeRate) external;

    function setMaxFundingFeeRate(int256 fee) external;

    function setMaxExcessRatio(int256 maxExcessRatio) external;

    function setLiquidatorReward(uint256 liquidatorReward) external;

    function setMinLeverage(uint128 minLeverage) external;

    function setMaxLeverage(uint128 maxLeverage) external;

    function setMinMargin(uint256 minMargin) external;

    function setVolumeLimit(uint256 volumeLimit) external;

    function setFeeBufferFactor(int256 feeBufferAmount) external;

    function setTotalVolumeLimit(uint256 totalVolumeLimit) external;

    function setPriceFeedAdapter(IPriceFeedAdapter priceFeedAdapter) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IUpdatable
 */
interface IUpdatable {
    /* ========== CORE FUNCTIONS ========== */
    function update(bytes calldata data) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/// @notice Enum for the different fee tiers
enum Tier {
    ZERO,
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX
}

interface IUserManager {
    /* ========== EVENTS ========== */

    event FeeSizeUpdated(uint256 indexed feeIndex, uint256 feeSize);

    event FeeVolumeUpdated(uint256 indexed feeIndex, uint256 feeVolume);

    event UserVolumeAdded(address indexed user, address indexed tradePair, uint256 volume);

    event UserManualTierUpdated(address indexed user, Tier tier, uint256 validUntil);

    event UserReferrerAdded(address indexed user, address referrer);

    /* =========== CORE FUNCTIONS =========== */

    function addUserVolume(address user, uint40 volume) external;

    function setUserReferrer(address user, address referrer) external;

    function setUserManualTier(address user, Tier tier, uint32 validUntil) external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes) external;

    function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes) external;

    /* ========== VIEW FUNCTIONS ========== */

    function getUserFee(address user) external view returns (uint256);

    function getUserReferrer(address user) external view returns (address referrer);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/ITradeManager.sol";

interface ITradeSignature {
    function hash(OpenPositionOrder calldata openPositionOrder) external view returns (bytes32);

    function hash(ClosePositionOrder calldata closePositionOrder) external view returns (bytes32);

    function hash(ClosePositionParams calldata closePositionParams) external view returns (bytes32);

    function hashPartiallyClosePositionOrder(PartiallyClosePositionOrder calldata partiallyClosePositionOrder)
        external
        view
        returns (bytes32);

    function hashPartiallyClosePositionParams(PartiallyClosePositionParams calldata partiallyClosePositionParams)
        external
        view
        returns (bytes32);

    function hashExtendPositionOrder(ExtendPositionOrder calldata extendPositionOrder)
        external
        view
        returns (bytes32);

    function hashExtendPositionParams(ExtendPositionParams calldata extendPositionParams)
        external
        view
        returns (bytes32);

    function hashExtendPositionToLeverageOrder(ExtendPositionToLeverageOrder calldata extendPositionToLeverageOrder)
        external
        view
        returns (bytes32);

    function hashExtendPositionToLeverageParams(ExtendPositionToLeverageParams calldata extendPositionToLeverageParams)
        external
        view
        returns (bytes32);

    function hashAddMarginToPositionOrder(AddMarginToPositionOrder calldata addMarginToPositionOrder)
        external
        view
        returns (bytes32);

    function hashAddMarginToPositionParams(AddMarginToPositionParams calldata addMarginToPositionParams)
        external
        view
        returns (bytes32);

    function hashRemoveMarginFromPositionOrder(RemoveMarginFromPositionOrder calldata removeMarginFromPositionOrder)
        external
        view
        returns (bytes32);

    function hashRemoveMarginFromPositionParams(RemoveMarginFromPositionParams calldata removeMarginFromPositionParams)
        external
        view
        returns (bytes32);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFeeManager {
    /* ========== EVENTS ============ */

    event ReferrerFeesPaid(address indexed referrer, address indexed asset, uint256 amount, address user);

    event WhiteLabelFeesPaid(address indexed whitelabel, address indexed asset, uint256 amount, address user);

    event UpdatedReferralFee(uint256 newReferrerFee);

    event UpdatedStakersFeeAddress(address stakersFeeAddress);

    event UpdatedDevFeeAddress(address devFeeAddress);

    event UpdatedInsuranceFundFeeAddress(address insuranceFundFeeAddress);

    event SetWhitelabelFee(address indexed whitelabelAddress, uint256 feeSize);

    event SetCustomReferralFee(address indexed referrer, uint256 feeSize);

    event SpreadFees(
        address asset,
        uint256 stakersFeeAmount,
        uint256 devFeeAmount,
        uint256 insuranceFundFeeAmount,
        uint256 liquidityPoolFeeAmount,
        address user
    );

    /* ========== CORE FUNCTIONS ========== */

    function depositOpenFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositCloseFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositBorrowFees(address asset, uint256 amount) external;

    /* ========== VIEW FUNCTIONS ========== */

    function calculateUserOpenFeeAmount(address user, uint256 amount) external view returns (uint256);

    function calculateUserOpenFeeAmount(address user, uint256 amount, uint256 leverage)
        external
        view
        returns (uint256);

    function calculateUserExtendToLeverageFeeAmount(
        address user,
        uint256 margin,
        uint256 volume,
        uint256 targetLeverage
    ) external view returns (uint256);

    function calculateUserCloseFeeAmount(address user, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct LiquidityPoolConfig {
    address poolAddress;
    uint96 percentage;
}

interface ILiquidityPoolAdapter {
    /* ========== EVENTS ========== */

    event PayedOutLoss(address indexed tradePair, uint256 loss);

    event DepositedProfit(address indexed tradePair, uint256 profit);

    event UpdatedMaxPayoutProportion(uint256 maxPayoutProportion);

    event UpdatedLiquidityPools(LiquidityPoolConfig[] liquidityPools);

    /* ========== CORE FUNCTIONS ========== */

    function requestLossPayout(uint256 profit) external returns (uint256);

    function depositProfit(uint256 profit) external;

    function depositFees(uint256 fee) external;

    /* ========== VIEW FUNCTIONS ========== */

    function availableLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPriceFeedAggregator.sol";

/**
 * @title IPriceFeedAdapter
 * @notice Provides a way to convert an asset amount to a collateral amount and vice versa
 * Needs two PriceFeedAggregators: One for asset and one for collateral
 */
interface IPriceFeedAdapter {
    function name() external view returns (string memory);

    /* ============ DECIMALS ============ */

    function collateralDecimals() external view returns (uint256);

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256);

    function assetToCollateralMin(uint256 assetAmount) external view returns (uint256);

    function assetToCollateralMax(uint256 assetAmount) external view returns (uint256);

    /* ============ USD Conversion ============ */

    function assetToUsdMin(uint256 assetAmount) external view returns (uint256);

    function assetToUsdMax(uint256 assetAmount) external view returns (uint256);

    function collateralToUsdMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToUsdMax(uint256 collateralAmount) external view returns (uint256);

    /* ============ PRICE ============ */

    function markPriceMin() external view returns (int256);

    function markPriceMax() external view returns (int256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 * Strings of arbitrary length can be optimized if they are short enough by
 * the addition of a storage variable used as fallback.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IPriceFeed.sol";

/**
 * @title IPriceFeedAggregator
 * @notice Aggreates two or more price feeds into min and max prices
 */
interface IPriceFeedAggregator {
    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function minPrice() external view returns (int256);

    function maxPrice() external view returns (int256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addPriceFeed(IPriceFeed) external;

    function removePriceFeed(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IPriceFeed
 * @notice Gets the last and previous price of an asset from a price feed
 * @dev The price must be returned with 8 decimals, following the USD convention
 */
interface IPriceFeed {
    /* ========== VIEW FUNCTIONS ========== */

    function price() external view returns (int256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}