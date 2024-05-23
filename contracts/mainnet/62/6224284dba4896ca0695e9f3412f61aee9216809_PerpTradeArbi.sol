// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Commands} from "src/libraries/Commands.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PerpTradeStorage} from "src/PerpTrade/PerpTradeStorage.sol";
import {IAccount} from "src/q/interfaces/IAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGmxOrderBook} from "src/protocols/gmx/interfaces/IGmxOrderBook.sol";
import {IGmxReader} from "src/protocols/gmx/interfaces/IGmxReader.sol";
import {IGmxVault} from "src/protocols/gmx/interfaces/IGmxVault.sol";
import {ICapOrders} from "src/protocols/cap/interfaces/ICapOrders.sol";
import {IMarketStore} from "src/protocols/cap/interfaces/IMarketStore.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {IGmxPositionRouter} from "src/interfaces/external/gmx/IGmxPositionRouter.sol";
import {IEndpoint as IVertexEndpoint} from "src/protocols/vertex/interfaces/IEndpoint.sol";

contract PerpTradeArbi is PerpTradeStorage {
    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) PerpTradeStorage(_operator) {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice execute the type of trade
    /// @dev can only be called by `Q` or `Vault`
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the ddex
    /// @param isOpen bool to check if the trade is an increase or a decrease trade
    function execute(uint256 command, bytes calldata data, bool isOpen, address stvId) external payable onlyQorVault {
        if (command == Commands.CAP) {
            _cap(data, isOpen, stvId);
        } else if (command == Commands.GMX) {
            _gmx(data, isOpen, stvId);
        } else if (command == Commands.HYPERLIQUID) {
            _hyperliquid(data, stvId);
        } else if (command == Commands.VERTEX) {
            _vertex(data, isOpen, stvId);
        } else if (command == Commands.CROSS_CHAIN) {
            _crossChain(data);
        } else if (command == Commands.MODIFY_ORDER) {
            _modifyOrder(data, isOpen);
        } else if (command == Commands.CLAIM_REWARDS) {
            _claimRewards(data);
        } else {
            revert Errors.CommandMisMatch();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _cap(bytes memory data, bool isOpen, address account) internal {
        // decode the data
        (,, ICapOrders.Order memory order, uint256 tpPrice, uint256 slPrice) =
            abi.decode(data, (address, uint96, ICapOrders.Order, uint256, uint256));

        if (account == address(0)) revert Errors.ZeroAddress();
        order.asset = IOperator(operator).getAddress("DEFAULTSTABLECOIN");

        // calculate the approval amount and approve the token
        if (isOpen) {
            address capFundStore = IOperator(operator).getAddress("CAPFUNDSTORE");
            address capMarketStore = IOperator(operator).getAddress("CAPMARKETSTORE");
            uint256 BPS_DIVIDER = 10000;
            bytes memory tokenApprovalData =
                abi.encodeWithSignature("approve(address,uint256)", capFundStore, order.margin);
            IAccount(account).execute(order.asset, tokenApprovalData, 0);

            IMarketStore.Market memory market = IMarketStore(capMarketStore).get(order.market);
            uint256 maxLeverage = market.maxLeverage;
            uint256 size = order.size;
            uint256 margin = order.margin;
            uint256 leverage = (size * 1e18) / margin;
            uint256 fee = (size * market.fee) / BPS_DIVIDER;
            order.margin = margin - fee;
            if (leverage >= maxLeverage * 1e18) {
                order.size = order.margin * maxLeverage;
            }
        }
        // Make the execute from account
        bytes memory tradeData = abi.encodeCall(ICapOrders.submitOrder, (order, tpPrice, slPrice));
        address capOrders = IOperator(operator).getAddress("CAPORDERS");
        IAccount(account).execute(capOrders, tradeData, 0);

        emit CapExecute(account, order, tpPrice, slPrice);
    }

    function _gmx(bytes calldata data, bool isOpen, address account) internal {
        address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        address gmxRouter = IOperator(operator).getAddress("GMXROUTER");
        address gmxOrderBook = IOperator(operator).getAddress("GMXORDERBOOK");
        address gmxPositionRouter = IOperator(operator).getAddress("GMXPOSITIONROUTER");
        uint256 fee = IGmxPositionRouter(gmxPositionRouter).minExecutionFee();

        if (isOpen) {
            GmxOpenOrderParams memory params;
            params = abi.decode(data, (GmxOpenOrderParams));
            if (account == address(0)) revert Errors.ZeroAddress();
            if (params.triggerPrice < 1) revert Errors.ZeroAmount();
            if (params.leverage < 1) revert Errors.ZeroAmount();

            uint96 balance = uint96(IERC20(depositToken).balanceOf(account));
            if (params.amount > balance) params.amount = balance;
            {
                bytes memory tokenApprovalData =
                    abi.encodeWithSignature("approve(address,uint256)", gmxRouter, params.amount);
                IAccount(account).execute(depositToken, tokenApprovalData, 0);
            }

            if (params.needApproval) {
                bytes memory pluginApprovalData;
                pluginApprovalData = abi.encodeWithSignature("approvePlugin(address)", gmxOrderBook);
                IAccount(account).execute(gmxRouter, pluginApprovalData, 0);
                pluginApprovalData = abi.encodeWithSignature("approvePlugin(address)", gmxPositionRouter);
                IAccount(account).execute(gmxRouter, pluginApprovalData, 0);
            }

            if (params.isLimit) {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createIncreaseOrder(address[],uint256,address,uint256,uint256,address,bool,uint256,bool,uint256,bool)",
                    getGmxPath(false, params.tradeDirection, depositToken, params.tradeToken),
                    params.amount,
                    params.tradeToken,
                    0,
                    uint256(params.leverage * params.amount) * 1e18,
                    params.tradeDirection ? params.tradeToken : depositToken,
                    params.tradeDirection,
                    uint256(params.triggerPrice) * 1e22,
                    !params.tradeDirection,
                    fee,
                    false
                );
                IAccount(account).execute{value: fee}(gmxOrderBook, tradeData, fee);
            } else {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createIncreasePosition(address[],address,uint256,uint256,uint256,bool,uint256,uint256,bytes32,address)",
                    getGmxPath(false, params.tradeDirection, depositToken, params.tradeToken), // path in case theres a swap
                    params.tradeToken, // the asset for which the position needs to be opened
                    params.amount, // the collateral amount
                    0, // the min amount of tradeToken in case of long and usdc in case of short for swap
                    uint256(params.leverage * params.amount) * 1e18, // size including the leverage to open a position, in 1e30 units
                    params.tradeDirection, // direction of the execute, true - long, false - short
                    uint256(params.triggerPrice) * 1e22, // the price at which the manager wants to open a position, in 1e30 units
                    fee, // min execution fee, `Gmx.PositionRouter.minExecutionFee()`
                    params.referralCode, // referral code
                    address(0) // an optional callback contract, this contract will be called on request execution or cancellation
                );
                IAccount(account).execute{value: fee}(gmxPositionRouter, tradeData, fee);
            }
            emit GmxOpenOrderExecute(
                account,
                params.amount,
                params.leverage,
                params.tradeToken,
                params.tradeDirection,
                params.isLimit,
                params.triggerPrice,
                params.needApproval,
                params.referralCode
            );
        } else {
            GmxCloseOrderParams memory params;
            params = abi.decode(data, (GmxCloseOrderParams));
            if (account == address(0)) revert Errors.ZeroAddress();
            if (params.triggerPrice < 1) revert Errors.ZeroAmount();

            if (params.isLimit) {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createDecreaseOrder(address,uint256,address,uint256,bool,uint256,bool)",
                    params.tradeToken, // the asset used for the position
                    params.sizeDelta, // size of the position, in 1e30 units
                    params.tradeDirection ? params.tradeToken : depositToken, // if long, then collateral is baseToken, if short then collateral usdc
                    params.collateralDelta, // the amount of collateral to withdraw
                    params.tradeDirection, // the direction of the exisiting position
                    uint256(params.triggerPrice) * 1e22, // the price at which the manager wants to close the position, in 1e30 units
                    // depends on whether its a take profit order or a stop loss order
                    // if tp, tradeDirection ? true : false
                    // if sl, tradeDirection ? false: true
                    params.triggerAboveThreshold
                );
                IAccount(account).execute{value: fee + 1}(gmxOrderBook, tradeData, fee + 1);
            } else {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createDecreasePosition(address[],address,uint256,uint256,bool,address,uint256,uint256,uint256,bool,address)",
                    getGmxPath(true, params.tradeDirection, depositToken, params.tradeToken), // path in case theres a swap
                    params.tradeToken, // the asset for which the position was opened
                    params.collateralDelta, // the amount of collateral to withdraw
                    params.sizeDelta, // the total size which has to be closed, in 1e30 units
                    params.tradeDirection, // the direction of the exisiting position
                    account, // address of the receiver after closing the position
                    uint256(params.triggerPrice) * 1e22, // the price at which the manager wants to close the position, in 1e30 units
                    0, // min output token amount
                    fee + 1, // min execution fee = `Gmx.PositionRouter.minExecutionFee() + 1`
                    false, // _withdrawETH, true if the amount recieved should be in ETH
                    address(0) // an optional callback contract, this contract will be called on request execution or cancellation
                );
                IAccount(account).execute{value: fee + 1}(gmxPositionRouter, tradeData, fee + 1);
            }
            emit GmxCloseOrderExecute(
                account,
                params.collateralDelta,
                params.tradeToken,
                params.sizeDelta,
                params.tradeDirection,
                params.isLimit,
                params.triggerPrice,
                params.triggerAboveThreshold
            );
        }
    }

    function _hyperliquid(bytes calldata data, address account) internal {
        (, uint256 amount, address generatedEOA) = abi.decode(data, (address, uint256, address));
        if (generatedEOA == address(0)) revert Errors.ZeroAddress();

        address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", generatedEOA, amount);

        IAccount(account).execute(depositToken, transferData, 0);

        (bool success,) = generatedEOA.call{value: msg.value}("");
        require(success, "Transfer failed.");

        emit HyperliquidDeposit(account, generatedEOA, amount);
    }

    function _vertex(bytes calldata data, bool isDeposit, address account) internal {
        (, uint96 amount, uint32 productId, uint64 nonce, string memory referralCode) =
            abi.decode(data, (address, uint96, uint32, uint64, string));
        address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        address vertexEndpoint = IOperator(operator).getAddress("VERTEXENDPOINT");

        if (isDeposit) {
            address admin = IOperator(operator).getAddress("ADMIN");
            bytes12 subAccountName = bytes12("default");
            bytes32 subAccount = bytes32(abi.encodePacked(account, subAccountName));

            bytes memory approvalData = abi.encodeWithSignature("approve(address,uint256)", vertexEndpoint, amount);
            IAccount(account).execute(depositToken, approvalData, 0);

            int128 VERTEX_SLOW_MODE_FEE = 1000000; // $1
            amount -= uint96(uint256(int256(VERTEX_SLOW_MODE_FEE)));

            bytes memory depositData = abi.encodeWithSignature(
                "depositCollateralWithReferral(bytes12,uint32,uint128,string)",
                subAccountName,
                productId,
                amount,
                referralCode
            );
            IAccount(account).execute(vertexEndpoint, depositData, 0);

            // takes 1 USDC fee to link signer on contract level
            if (IVertexEndpoint(vertexEndpoint).getLinkedSigner(subAccount) != admin) {
                bytes32 signer = bytes32(uint256(uint160(admin)) << 96);
                IVertexEndpoint.LinkSigner memory linkSigner = IVertexEndpoint.LinkSigner(subAccount, signer, nonce);
                bytes memory linkData = abi.encodeWithSignature(
                    "submitSlowModeTransaction(bytes)",
                    abi.encodePacked(IVertexEndpoint.TransactionType.LinkSigner, abi.encode(linkSigner))
                );
                IAccount(account).execute(vertexEndpoint, linkData, 0);
            }

        } else {
            // 1$ withdrawal fee
            bytes memory approvalData = abi.encodeWithSignature("approve(address,uint256)", vertexEndpoint, 1e6);
            IAccount(account).execute(depositToken, approvalData, 0);

            IVertexEndpoint.WithdrawCollateral memory withdrawCollateral = IVertexEndpoint.WithdrawCollateral(
                bytes32(uint256(uint160(account)) << 96), // sender
                productId, // productId
                uint128(amount), //  amount
                nonce // nonce
            );

            bytes memory withdrawData = abi.encodeWithSignature(
                "submitSlowModeTransaction(bytes)",
                abi.encodePacked(IVertexEndpoint.TransactionType.WithdrawCollateral, abi.encode(withdrawCollateral))
            );
            IAccount(account).execute(vertexEndpoint, withdrawData, 0);
        }
    }

    function _crossChain(bytes calldata data) internal {
        bytes memory lifiData;
        address account;
        address token;
        uint256 amount;

        (account, token, amount, lifiData) = abi.decode(data, (address, address, uint256, bytes));

        if (account == address(0)) revert Errors.ZeroAddress();
        if (token == address(0)) revert Errors.ZeroAddress();
        if (amount < 1) revert Errors.ZeroAmount();
        if (lifiData.length == 0) revert Errors.ExchangeDataMismatch();

        address crossChainRouter = IOperator(operator).getAddress("CROSSCHAINROUTER");
        bytes memory tokenApprovalData = abi.encodeWithSignature("approve(address,uint256)", crossChainRouter, amount);
        IAccount(account).execute(token, tokenApprovalData, 0);
        IAccount(account).execute{value: msg.value}(crossChainRouter, lifiData, msg.value);
        emit CrossChainExecute(account, token, amount, lifiData);
    }

    function _modifyOrder(bytes calldata data, bool isCancel) internal {
        (address account,, uint256 command, Order orderType, bytes memory orderData) =
            abi.decode(data, (address, uint256, uint256, Order, bytes));
        address adapter;
        address tradeToken; // purchase token (path[pat.lenfth - 1] while createIncreseOrder)
        uint256 executionFeeRefund;
        uint256 purchaseTokenAmount;
        address[] memory tradeTokens;
        uint256[] memory purchaseTokenAmounts;
        bytes memory actionData;

        if (isCancel) {
            uint256 orderId;
            uint256[] memory increaseOrders;
            uint256[] memory decreaseOrders;
            if (command == Commands.CAP) {
                if (orderType == Order.CANCEL_MULTIPLE) {
                    (increaseOrders) = abi.decode(orderData, (uint256[]));
                    actionData = abi.encodeWithSignature("cancelOrders(uint256[])", increaseOrders);
                    emit CapCancelMultipleOrdersExecute(account, increaseOrders);
                } else {
                    (orderId) = abi.decode(orderData, (uint256));
                    actionData = abi.encodeWithSignature("cancelOrder(uint256)", orderId);
                    emit CapCancelOrderExecute(account, orderId);
                }
                adapter = IOperator(operator).getAddress("CAPORDERS");
            } else if (command == Commands.GMX) {
                adapter = IOperator(operator).getAddress("GMXORDERBOOK");
                (orderId) = abi.decode(orderData, (uint256));
                if (orderType == Order.CANCEL_INCREASE) {
                    tradeTokens = new address[](1);
                    purchaseTokenAmounts = new uint256[](1);
                    actionData = abi.encodeWithSignature("cancelIncreaseOrder(uint256)", orderId);
                    (tradeToken, purchaseTokenAmount,,,,,,, executionFeeRefund) =
                        IGmxOrderBook(adapter).getIncreaseOrder(account, orderId);
                    tradeTokens[0] = tradeToken;
                    purchaseTokenAmounts[0] = purchaseTokenAmount;
                    emit GmxCancelOrderExecute(account, orderId);
                } else if (orderType == Order.CANCEL_DECREASE) {
                    (,,,,,,, executionFeeRefund) = IGmxOrderBook(adapter).getDecreaseOrder(account, orderId);
                    actionData = abi.encodeWithSignature("cancelDecreaseOrder(uint256)", orderId);
                    emit GmxCancelOrderExecute(account, orderId);
                } else if (orderType == Order.CANCEL_MULTIPLE) {
                    (increaseOrders, decreaseOrders) = abi.decode(orderData, (uint256[], uint256[]));
                    tradeTokens = new address[](increaseOrders.length);
                    purchaseTokenAmounts = new uint256[](increaseOrders.length);
                    actionData = abi.encodeWithSignature(
                        "cancelMultiple(uint256[],uint256[],uint256[])",
                        new uint256[](0), // swapOrderIndexes,
                        increaseOrders,
                        decreaseOrders
                    );
                    {
                        address account = account;
                        uint256 _executionFeeRefund;
                        for (uint256 i = 0; i < decreaseOrders.length;) {
                            (,,,,,,, _executionFeeRefund) =
                                IGmxOrderBook(adapter).getDecreaseOrder(account, decreaseOrders[i]);
                            executionFeeRefund += _executionFeeRefund;
                            unchecked {
                                ++i;
                            }
                        }
                        for (uint256 i = 0; i < increaseOrders.length;) {
                            (tradeToken, purchaseTokenAmount,,,,,,, _executionFeeRefund) =
                                IGmxOrderBook(adapter).getIncreaseOrder(account, increaseOrders[i]);
                            tradeTokens[i] = tradeToken;
                            purchaseTokenAmounts[i] = purchaseTokenAmount;
                            executionFeeRefund += _executionFeeRefund;
                            unchecked {
                                ++i;
                            }
                        }
                    }
                    emit GmxCancelMultipleOrdersExecute(account, increaseOrders, decreaseOrders);
                }
            } else {
                revert Errors.CommandMisMatch();
            }
        } else {
            if (command == Commands.CAP) {
                address act = account;
                (uint256 cancelOrderId, bytes memory capOrderData) = abi.decode(orderData, (uint256, bytes));
                bytes memory cancelOrderData = abi.encodeWithSignature("cancelOrder(uint256)", cancelOrderId);
                address capOrders = IOperator(operator).getAddress("CAPORDERS");
                IAccount(account).execute(capOrders, cancelOrderData, 0);
                if (orderType == Order.UPDATE_INCREASE) {
                    _cap(capOrderData, true, act);
                } else if (orderType == Order.UPDATE_DECREASE) {
                    _cap(capOrderData, false, act);
                } else {
                    revert Errors.CommandMisMatch();
                }
                emit CapCancelOrderExecute(account, cancelOrderId);
            } else if (command == Commands.GMX) {
                uint256 orderIndex;
                uint256 collateralDelta;
                uint256 sizeDelta;
                uint256 triggerPrice;
                bool triggerAboveThreshold;
                if (orderType == Order.UPDATE_INCREASE) {
                    (orderIndex, sizeDelta, triggerPrice, triggerAboveThreshold) =
                        abi.decode(orderData, (uint256, uint256, uint256, bool));
                    actionData = abi.encodeWithSignature(
                        "updateIncreaseOrder(uint256,uint256,uint256,bool)",
                        orderIndex,
                        sizeDelta,
                        triggerPrice,
                        triggerAboveThreshold
                    );
                } else if (orderType == Order.UPDATE_DECREASE) {
                    (orderIndex, collateralDelta, sizeDelta, triggerPrice, triggerAboveThreshold) =
                        abi.decode(orderData, (uint256, uint256, uint256, uint256, bool));
                    actionData = abi.encodeWithSignature(
                        "updateDecreaseOrder(uint256,uint256,uint256,uint256,bool)",
                        orderIndex,
                        collateralDelta,
                        sizeDelta,
                        triggerPrice,
                        triggerAboveThreshold
                    );
                }
                adapter = IOperator(operator).getAddress("GMXORDERBOOK");
                emit GmxModifyOrderExecute(
                    account, orderType, orderIndex, collateralDelta, sizeDelta, triggerPrice, triggerAboveThreshold
                );
            } else {
                revert Errors.CommandMisMatch();
            }
        }
        // TODO check on updateIncrease order too
        if (actionData.length > 0) IAccount(account).execute(adapter, actionData, 0);
        if (executionFeeRefund > 0) {
            address admin = IOperator(operator).getAddress("ADMIN");
            IAccount(account).execute(admin, "", executionFeeRefund);
        }
        for (uint256 i = 0; i < tradeTokens.length;) {
            _swap(tradeTokens[i], purchaseTokenAmounts[i], account);
            unchecked {
                ++i;
            }
        }
    }

    function _claimRewards(bytes calldata data) internal {
        (address account, uint256 command, bytes memory rewardData) = abi.decode(data, (address, uint256, bytes));
        address treasury = IOperator(operator).getAddress("REWARDSTREASURY");
        address token;
        uint256 rewardAmount;

        if (command == Commands.CAP) {
            token = IOperator(operator).getAddress("ARBTOKEN");
            address capRewards = IOperator(operator).getAddress("CAPREWARDS");
            rewardAmount = IERC20(token).balanceOf(account);
            if (rewardData.length > 0) IAccount(account).execute(capRewards, rewardData, 0);
            rewardAmount = IERC20(token).balanceOf(account) - rewardAmount;
        } else if (command == Commands.GMX) {
            token = IOperator(operator).getAddress("WRAPPEDTOKEN");
            rewardAmount = IERC20(token).balanceOf(account);
        } else if (command == Commands.VERTEX) {
            uint32 epoch;
            uint256 amount;
            uint256 totalAmount;
            bytes32[] memory proof;
            (token, epoch, amount, totalAmount, proof) =
                abi.decode(rewardData, (address, uint32, uint256, uint256, bytes32[]));

            address VRTX = IOperator(operator).getAddress("VRTXTOKEN");
            address ARB = IOperator(operator).getAddress("ARBTOKEN");
            if ((token == VRTX || token == ARB) == false) revert Errors.WrongRewardClaimToken();

            address rewards = IOperator(operator).getAddress("VERTEXVRTXREWARD");
            if (token == ARB) rewards = IOperator(operator).getAddress("VERTEXARBREWARD");

            bytes memory claimData =
                abi.encodeWithSignature("claim(uint32,uint256,uint256,bytes32[])", epoch, amount, totalAmount, proof);
            IAccount(account).execute(rewards, claimData, 0);
            rewardAmount = IERC20(token).balanceOf(account);
        } else {
            revert Errors.CommandMisMatch();
        }

        if (rewardAmount > 0) {
            IAccount(account).execute(
                token, abi.encodeWithSignature("transfer(address,uint256)", treasury, rewardAmount), 0
            );
        }
    }

    function _swap(address tradeToken, uint256 purchaseTokenAmount, address account) internal {
        address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        address gmxReader = IOperator(operator).getAddress("GMXREADER");
        address gmxVault = IOperator(operator).getAddress("GMXVAULT");
        address gmxRouter = IOperator(operator).getAddress("GMXROUTER");

        if (tradeToken != depositToken && purchaseTokenAmount > 0) {
            // TODO discuss what to do on cancelMultiple increase orders?? loop or use multi execute ??
            address[] memory path = new address[](2);
            path[0] = tradeToken;
            path[1] = depositToken;

            // TODO check maxAmount In logic ??
            (uint256 minOut,) =
                IGmxReader(gmxReader).getAmountOut(IGmxVault(gmxVault), path[0], path[1], purchaseTokenAmount);

            // TODO revert if minOut == 0
            uint256 ethToSend;
            bytes memory swapData;

            if (tradeToken == IOperator(operator).getAddress("WRAPPEDTOKEN")) {
                ethToSend = purchaseTokenAmount;
                swapData = abi.encodeWithSignature(
                    "swapETHToTokens(address[],uint256,address)",
                    path,
                    minOut,
                    account //  receiver
                );
            } else {
                bytes memory tokenApprovalData =
                    abi.encodeWithSignature("approve(address,uint256)", gmxRouter, purchaseTokenAmount);
                IAccount(account).execute(tradeToken, tokenApprovalData, 0);
                swapData = abi.encodeWithSignature(
                    "swap(address[],uint256,uint256,address)",
                    path,
                    purchaseTokenAmount, // amountIn
                    minOut,
                    account //  receiver
                );
            }
            IAccount(account).execute(gmxRouter, swapData, ethToSend);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title Commands similar to UniversalRouter
/// @notice Command Flags used to decode commands
/// @notice https://github.com/Uniswap/universal-router/blob/main/contracts/libraries/Commands.sol
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // Command Types. Maximum supported command at this moment is 0x3f.

    // Command Types where value >= 0x00, for Perpetuals
    uint256 constant GMX = 0x00;
    uint256 constant PERP = 0x01;
    uint256 constant CAP = 0x02;
    uint256 constant KWENTA = 0x03;
    uint256 constant VERTEX = 0x04;
    uint256 constant HYPERLIQUID = 0x05;
    // COMMAND_PLACEHOLDER = 0x0;
    // Future perpetual protocols can be added below

    // Command Types where value >= 0x10, for Spot
    uint256 constant UNI = 0x10;
    uint256 constant SUSHI = 0x11;
    uint256 constant ONE_INCH = 0x12;
    uint256 constant TRADER_JOE = 0x13;
    uint256 constant PANCAKE = 0x14;
    // COMMAND_PLACEHOLDER = 0x15;
    // Future spot protocols can be added below

    // Future financial services like options can be added with a value >= 0x20

    // Command Types where value >= 0x30, for trade functions
    uint256 constant CROSS_CHAIN = 0x30;
    uint256 constant MODIFY_ORDER = 0x31;
    uint256 constant CLAIM_REWARDS = 0x32;
    // COMMAND_PLACEHOLDER = 0x3d;
    // Future functions to interact with protocols can be added below
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();
    error AboveMaxDistributeIndex();
    error BelowMinStvDepositAmount();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
    error WrongRewardClaimToken();

    // Subscriptions
    error NotASubscriber();
    error AlreadySubscribed();
    error MoreThanLimit();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {ICapOrders} from "src/protocols/cap/interfaces/ICapOrders.sol";
import {IAccount as IKwentaAccount} from "src/protocols/kwenta/interfaces/IAccount.sol";

contract PerpTradeStorage {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    enum Order {
        UPDATE_INCREASE,
        UPDATE_DECREASE,
        CANCEL_INCREASE,
        CANCEL_DECREASE,
        CANCEL_MULTIPLE
    }

    struct GmxOpenOrderParams {
        address account;
        uint96 amount;
        uint32 leverage;
        address tradeToken;
        bool tradeDirection;
        bool isLimit;
        int256 triggerPrice;
        bool needApproval;
        bytes32 referralCode;
    }

    struct GmxCloseOrderParams {
        address account;
        uint96 collateralDelta;
        address tradeToken;
        uint256 sizeDelta;
        bool tradeDirection;
        bool isLimit;
        int256 triggerPrice;
        bool triggerAboveThreshold;
    }

    address public operator;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event InitPerpTrade(address indexed operator);
    event CapExecute(address indexed account, ICapOrders.Order order, uint256 tpPrice, uint256 slPrice);
    event GmxOpenOrderExecute(
        address indexed account,
        uint96 amount,
        uint32 leverage,
        address indexed tradeToken,
        bool tradeDirection,
        bool isLimit,
        int256 triggerPrice,
        bool needApproval,
        bytes32 indexed referralCode
    );
    event GmxCloseOrderExecute(
        address indexed account,
        uint96 collateralDelta,
        address indexed tradeToken,
        uint256 sizeDelta,
        bool tradeDirection,
        bool isLimit,
        int256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CrossChainExecute(address indexed account, address indexed token, uint256 amount, bytes lifiData);
    event KwentaExecute(
        address indexed account,
        uint96 amount,
        address kwentaAccount,
        bytes exchangeData,
        IKwentaAccount.Command[] commands,
        bytes[] bytesParams
    );
    event KwentaModifyOrder(address indexed account, uint256 command, bytes orderData);
    event CapCancelOrderExecute(address indexed account, uint256 orderId);
    event GmxCancelOrderExecute(address indexed account, uint256 orderId);
    event CapCancelMultipleOrdersExecute(address indexed account, uint256[] orderIds);
    event GmxCancelMultipleOrdersExecute(address indexed account, uint256[] increaseOrders, uint256[] decreaseOrders);
    event GmxModifyOrderExecute(
        address indexed account,
        Order orderType,
        uint256 orderIndex,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event HyperliquidDeposit(address indexed account, address  generatedEOA, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) {
        operator = _operator;
        emit InitPerpTrade(_operator);
    }

    modifier onlyOwner() {
        address owner = IOperator(operator).getAddress("OWNER");
        if (msg.sender != owner) revert Errors.NotOwner();
        _;
    }

    modifier onlyQorVault() {
        address q = IOperator(operator).getAddress("Q");
        address vault = IOperator(operator).getAddress("VAULT");
        if ((msg.sender != q) && (msg.sender != vault)) revert Errors.NoAccess();
        _;
    }

    function getGmxPath(bool _isClose, bool _tradeDirection, address _depositToken, address _tradeToken)
        internal
        pure
        returns (address[] memory _path)
    {
        if (!_tradeDirection) {
            // for short, the collateral is in stable coin,
            // so the path only needs depositToken since there's no swap
            _path = new address[](1);
            _path[0] = _depositToken;
        } else {
            // for long, the collateral is in the tradeToken,
            // we swap from usdc to tradeToken when opening and vice versa
            _path = new address[](2);
            _path[0] = _isClose ? _tradeToken : _depositToken;
            _path[1] = _isClose ? _depositToken : _tradeToken;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAccount {
    function execute(address adapter, bytes calldata data, uint256 ethToSend)
        external
        payable
        returns (bytes memory returnData);
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

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxOrderBook {
    function getSwapOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(address, uint256, address payable) external;
    function executeDecreaseOrder(address, uint256, address payable) external;
    function executeIncreaseOrder(address, uint256, address payable) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function increaseOrdersIndex(address) external view returns (uint256);
    function decreaseOrdersIndex(address) external view returns (uint256);

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) external view returns (uint256, bool);

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function updateSwapOrder(uint256 _orderIndex, uint256 _minOut, uint256 _triggerRatio, bool _triggerAboveThreshold)
        external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGmxVault} from "./IGmxVault.sol";

interface IGmxReader {
    function getAmountOut(IGmxVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn)
        external
        view
        returns (uint256, uint256);
    function getMaxAmountIn(IGmxVault _vault, address _tokenIn, address _tokenOut) external view returns (uint256);
    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IGmxVaultUtils.sol";

interface IGmxVault {
    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IGmxVaultUtils _vaultUtils) external;

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

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor)
        external;

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

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

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

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (bool, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICapOrders {
    struct Order {
        uint256 orderId; // incremental order id
        address user; // user that submitted the order
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this order was submitted on
        uint256 margin; // Collateral tied to this order. In wei
        uint256 size; // Order size (margin * leverage). In wei
        uint256 price; // The order's price if its a trigger or protected order
        uint256 fee; // Fee amount paid. In wei
        bool isLong; // Wether the order is a buy or sell order
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        bool isReduceOnly; // Wether the order is reduce-only
        uint256 timestamp; // block.timestamp at which the order was submitted
        uint256 expiry; // block.timestamp at which the order expires
        uint256 cancelOrderId; // orderId to cancel when this order executes
    }

    function submitOrder(Order memory params, uint256 tpPrice, uint256 slPrice) external payable;
    function cancelOrder(uint256 orderId) external;
    function cancelOrders(uint256[] calldata orderIds) external;
}

interface IMarketStore {
    struct Market {
        string name; // Market's full name, e.g. Bitcoin / U.S. Dollar
        string category; // crypto, fx, commodities, or indices
        address chainlinkFeed; // Price feed contract address
        uint256 maxLeverage; // No decimals
        uint256 maxDeviation; // In bps, max price difference from oracle to chainlink price
        uint256 fee; // In bps. 10 = 0.1%
        uint256 liqThreshold; // In bps
        uint256 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 minOrderAge; // Min order age before is can be executed. In seconds
        uint256 pythMaxAge; // Max Pyth submitted price age, in seconds
        bytes32 pythFeed; // Pyth price feed id
        bool allowChainlinkExecution; // Allow anyone to execute orders with chainlink
        bool isReduceOnly; // accepts only reduce only orders
    }

    function get(string calldata market) external view returns (Market memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getMaxDistributeIndex() external view returns (uint256);
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setPlugin(address plugin, bool isPlugin) external;
    function setPlugins(address[] calldata plugins, bool[] calldata isPlugin) external;
    function setTraderAccount(address trader, address account) external;
    function getAllSubscribers(address manager) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
    function setSubscribe(address manager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribe(address manager, address subscriber) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

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

    function minExecutionFee() external view returns (uint256);

    function setPositionKeeper(address _account, bool _isActive) external;

    function getRequestKey(address _account, uint256 _index) external pure returns (bytes32);

    function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequestKeys(uint256 index) external view returns (bytes32);

    function decreasePositionRequestKeys(uint256 index) external view returns (bytes32);

    function increasePositionRequests(bytes32 key) external view returns (IncreasePositionRequest memory);

    function dereasePositionRequests(bytes32 key) external view returns (DecreasePositionRequest memory);

    function increasePositionsIndex(address account) external view returns (uint256);

    function decreasePositionsIndex(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IEndpoint {
    // events that we parse transactions into
    enum TransactionType {
        LiquidateSubaccount, // 0
        DepositCollateral, // 1
        WithdrawCollateral, // 2
        SpotTick,
        UpdatePrice,
        SettlePnl,
        MatchOrders,
        DepositInsurance,
        ExecuteSlowMode,
        MintLp,
        BurnLp,
        SwapAMM,
        MatchOrderAMM,
        DumpFees,
        ClaimSequencerFees,
        PerpTick,
        ManualAssert,
        Rebate,
        UpdateProduct,
        LinkSigner, // 19
        UpdateFeeRates
    }

    struct UpdateProduct {
        address engine;
        bytes tx;
    }

    /// requires signature from sender
    enum LiquidationMode {
        SPREAD,
        SPOT,
        PERP
    }

    struct LiquidateSubaccount {
        bytes32 sender;
        bytes32 liquidatee;
        uint8 mode;
        uint32 healthGroup;
        int128 amount;
        uint64 nonce;
    }

    struct SignedLiquidateSubaccount {
        LiquidateSubaccount tx;
        bytes signature;
    }

    struct DepositCollateral {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
    }

    struct SignedDepositCollateral {
        DepositCollateral tx;
        bytes signature;
    }

    struct WithdrawCollateral {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
        uint64 nonce;
    }

    struct SignedWithdrawCollateral {
        WithdrawCollateral tx;
        bytes signature;
    }

    struct MintLp {
        bytes32 sender;
        uint32 productId;
        uint128 amountBase;
        uint128 quoteAmountLow;
        uint128 quoteAmountHigh;
        uint64 nonce;
    }

    struct SignedMintLp {
        MintLp tx;
        bytes signature;
    }

    struct BurnLp {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
        uint64 nonce;
    }

    struct SignedBurnLp {
        BurnLp tx;
        bytes signature;
    }

    struct LinkSigner {
        bytes32 sender;
        bytes32 signer;
        uint64 nonce;
    }

    struct SignedLinkSigner {
        LinkSigner tx;
        bytes signature;
    }

    /// callable by endpoint; no signature verifications needed
    struct PerpTick {
        uint128 time;
        int128[] avgPriceDiffs;
    }

    struct SpotTick {
        uint128 time;
    }

    struct ManualAssert {
        int128[] openInterests;
        int128[] totalDeposits;
        int128[] totalBorrows;
    }

    struct Rebate {
        bytes32[] subaccounts;
        int128[] amounts;
    }

    struct UpdateFeeRates {
        address user;
        uint32 productId;
        // the absolute value of fee rates can't be larger than 100%,
        // so their X18 values are in the range [-1e18, 1e18], which
        // can be stored by using int64.
        int64 makerRateX18;
        int64 takerRateX18;
    }

    struct ClaimSequencerFees {
        bytes32 subaccount;
    }

    struct UpdatePrice {
        uint32 productId;
        int128 priceX18;
    }

    struct SettlePnl {
        bytes32[] subaccounts;
        uint256[] productIds;
    }

    /// matching
    struct Order {
        bytes32 sender;
        int128 priceX18;
        int128 amount;
        uint64 expiration;
        uint64 nonce;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    struct MatchOrders {
        uint32 productId;
        bool amm; // whether taker order should hit AMM first (deprecated)
        SignedOrder taker;
        SignedOrder maker;
    }

    struct MatchOrdersWithSigner {
        MatchOrders matchOrders;
        address takerLinkedSigner;
        address makerLinkedSigner;
    }

    // just swap against AMM -- theres no maker order
    struct MatchOrderAMM {
        uint32 productId;
        int128 baseDelta;
        int128 quoteDelta;
        SignedOrder taker;
    }

    struct SwapAMM {
        bytes32 sender;
        uint32 productId;
        int128 amount;
        int128 priceX18;
    }

    struct DepositInsurance {
        uint128 amount;
    }

    struct SignedDepositInsurance {
        DepositInsurance tx;
        bytes signature;
    }

    struct SlowModeTx {
        uint64 executableAt;
        address sender;
        bytes tx;
    }

    struct SlowModeConfig {
        uint64 timeout;
        uint64 txCount;
        uint64 txUpTo;
    }

    struct Prices {
        int128 spotPriceX18;
        int128 perpPriceX18;
    }

    function depositCollateral(bytes12 subaccountName, uint32 productId, uint128 amount) external;

    function setBook(uint32 productId, address book) external;

    function submitTransactionsChecked(uint64 idx, bytes[] calldata transactions) external;

    function submitSlowModeTransaction(bytes calldata transaction) external;

    function getPriceX18(uint32 productId) external view returns (int128);

    function getPricesX18(uint32 healthGroup) external view returns (Prices memory);

    function getTime() external view returns (uint128);

    function getNonce(address sender) external view returns (uint64);

    function getNumSubaccounts() external view returns (uint64);

    function getSubaccountId(bytes32 subaccount) external view returns (uint64);

    function getSubaccountById(uint64 subaccountId) external view returns (bytes32);

    function getLinkedSigner(bytes32 subaccount) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IEvents} from "./IEvents.sol";
import {IFactory} from "./IFactory.sol";
import {IFuturesMarketManager} from "src/protocols/kwenta/interfaces/synthetix/IFuturesMarketManager.sol";
import {IPerpsV2MarketConsolidated} from "src/protocols/kwenta/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {ISettings} from "./ISettings.sol";
import {ISystemStatus} from "src/protocols/kwenta/interfaces/synthetix/ISystemStatus.sol";

/// @title Kwenta Smart Margin Account Implementation Interface
/// @author JaredBorders ([email protected]), JChiaramonte7 ([email protected])
interface IAccount {
    /*///////////////////////////////////////////////////////////////
                                Types
    ///////////////////////////////////////////////////////////////*/

    /// @notice Command Flags used to decode commands to execute
    /// @dev under the hood ACCOUNT_MODIFY_MARGIN = 0, ACCOUNT_WITHDRAW_ETH = 1
    enum Command {
        ACCOUNT_MODIFY_MARGIN, // 0
        ACCOUNT_WITHDRAW_ETH, // 1
        PERPS_V2_MODIFY_MARGIN, // 2
        PERPS_V2_WITHDRAW_ALL_MARGIN, // 3
        PERPS_V2_SUBMIT_ATOMIC_ORDER, // 4
        PERPS_V2_SUBMIT_DELAYED_ORDER, // 5
        PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER, // 6
        PERPS_V2_CLOSE_POSITION, // 7
        PERPS_V2_SUBMIT_CLOSE_DELAYED_ORDER, // 8
        PERPS_V2_SUBMIT_CLOSE_OFFCHAIN_DELAYED_ORDER, // 9
        PERPS_V2_CANCEL_DELAYED_ORDER, // 10
        PERPS_V2_CANCEL_OFFCHAIN_DELAYED_ORDER, // 11
        GELATO_PLACE_CONDITIONAL_ORDER, // 12
        GELATO_CANCEL_CONDITIONAL_ORDER // 13

    }

    /// @notice denotes conditional order types for code clarity
    /// @dev under the hood LIMIT = 0, STOP = 1
    enum ConditionalOrderTypes {
        LIMIT,
        STOP
    }

    /// @notice denotes conditional order cancelled reasons for code clarity
    /// @dev under the hood CONDITIONAL_ORDER_CANCELLED_BY_USER = 0, CONDITIONAL_ORDER_CANCELLED_NOT_REDUCE_ONLY = 1
    enum ConditionalOrderCancelledReason {
        CONDITIONAL_ORDER_CANCELLED_BY_USER,
        CONDITIONAL_ORDER_CANCELLED_NOT_REDUCE_ONLY
    }

    /// marketKey: Synthetix PerpsV2 Market id/key
    /// marginDelta: amount of margin to deposit or withdraw; positive indicates deposit, negative withdraw
    /// sizeDelta: denoted in market currency (i.e. ETH, BTC, etc), size of Synthetix PerpsV2 position
    /// targetPrice: limit or stop price target needing to be met to submit Synthetix PerpsV2 order
    /// gelatoTaskId: unqiue taskId from gelato necessary for cancelling conditional orders
    /// conditionalOrderType: conditional order type to determine conditional order fill logic
    /// desiredFillPrice: desired price to fill Synthetix PerpsV2 order at execution time
    /// reduceOnly: if true, only allows position's absolute size to decrease
    struct ConditionalOrder {
        bytes32 marketKey;
        int256 marginDelta;
        int256 sizeDelta;
        uint256 targetPrice;
        bytes32 gelatoTaskId;
        ConditionalOrderTypes conditionalOrderType;
        uint256 desiredFillPrice;
        bool reduceOnly;
    }
    /// @dev see example below elucidating targtPrice vs desiredFillPrice:
    /// 1. targetPrice met (ex: targetPrice = X)
    /// 2. account submits delayed order to Synthetix PerpsV2 with desiredFillPrice = Y
    /// 3. keeper executes Synthetix PerpsV2 order after delay period
    /// 4. if current market price defined by Synthetix PerpsV2
    ///    after delay period satisfies desiredFillPrice order is filled

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when commands length does not equal inputs length
    error LengthMismatch();

    /// @notice thrown when Command given is not valid
    error InvalidCommandType(uint256 commandType);

    /// @notice thrown when conditional order type given is not valid due to zero sizeDelta
    error ZeroSizeDelta();

    /// @notice exceeds useable margin
    /// @param available: amount of useable margin asset
    /// @param required: amount of margin asset required
    error InsufficientFreeMargin(uint256 available, uint256 required);

    /// @notice call to transfer ETH on withdrawal fails
    error EthWithdrawalFailed();

    /// @notice base price from the oracle was invalid
    /// @dev Rate can be invalid either due to:
    ///     1. Returned as invalid from ExchangeRates - due to being stale or flagged by oracle
    ///     2. Out of deviation bounds w.r.t. to previously stored rate
    ///     3. if there is no valid stored rate, w.r.t. to previous 3 oracle rates
    ///     4. Price is zero
    error InvalidPrice();

    /// @notice thrown when account execution has been disabled in the settings contract
    error AccountExecutionDisabled();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the version of the Account
    function VERSION() external view returns (bytes32);

    /// @return returns the amount of margin locked for future events (i.e. conditional orders)
    function committedMargin() external view returns (uint256);

    /// @return returns current conditional order id
    function conditionalOrderId() external view returns (uint256);

    /// @notice get delayed order data from Synthetix PerpsV2
    /// @dev call reverts if _marketKey is invalid
    /// @param _marketKey: key for Synthetix PerpsV2 Market
    /// @return delayed order struct defining delayed order (will return empty struct if no delayed order exists)
    function getDelayedOrder(bytes32 _marketKey) external returns (IPerpsV2MarketConsolidated.DelayedOrder memory);

    /// @notice checker() is the Resolver for Gelato
    /// (see https://docs.gelato.network/developer-services/automate/guides/custom-logic-triggers/smart-contract-resolvers)
    /// @notice signal to a keeper that a conditional order is valid/invalid for execution
    /// @dev call reverts if conditional order Id does not map to a valid conditional order;
    /// ConditionalOrder.marketKey would be invalid
    /// @param _conditionalOrderId: key for an active conditional order
    /// @return canExec boolean that signals to keeper a conditional order can be executed by Gelato
    /// @return execPayload calldata for executing a conditional order
    function checker(uint256 _conditionalOrderId) external view returns (bool canExec, bytes memory execPayload);

    /// @notice the current withdrawable or usable balance
    /// @return free margin amount
    function freeMargin() external view returns (uint256);

    /// @notice get up-to-date position data from Synthetix PerpsV2
    /// @param _marketKey: key for Synthetix PerpsV2 Market
    /// @return position struct defining current position
    function getPosition(bytes32 _marketKey) external returns (IPerpsV2MarketConsolidated.Position memory);

    /// @notice conditional order id mapped to conditional order
    /// @param _conditionalOrderId: id of conditional order
    /// @return conditional order
    function getConditionalOrder(uint256 _conditionalOrderId) external view returns (ConditionalOrder memory);

    /*//////////////////////////////////////////////////////////////
                                MUTATIVE
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the initial owner of the account
    /// @dev only called once by the factory on account creation
    /// @param _owner: address of the owner
    function setInitialOwnership(address _owner) external;

    /// @notice executes commands along with provided inputs
    /// @param _commands: array of commands, each represented as an enum
    /// @param _inputs: array of byte strings containing abi encoded inputs for each command
    function execute(Command[] calldata _commands, bytes[] calldata _inputs) external payable;

    /// @notice execute a gelato queued conditional order
    /// @notice only keepers can trigger this function
    /// @dev currently only supports conditional order submission via PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER COMMAND
    /// @param _conditionalOrderId: key for an active conditional order
    function executeConditionalOrder(uint256 _conditionalOrderId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external view;
    function validateDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external view;
    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (uint256);
    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);
    function getFundingFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount)
        external
        view
        returns (uint256);
    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IAccount} from "./IAccount.sol";

/// @title Interface for contract that emits all events emitted by the Smart Margin Accounts
/// @author JaredBorders ([email protected])
interface IEvents {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a non-account contract attempts to call a restricted function
    error OnlyAccounts();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the address of the factory contract
    function factory() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted after a successful withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of marginAsset to withdraw from account
    function emitDeposit(address user, uint256 amount) external;

    event Deposit(address indexed user, address indexed account, uint256 amount);

    /// @notice emitted after a successful withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of marginAsset to withdraw from account
    function emitWithdraw(address user, uint256 amount) external;

    event Withdraw(address indexed user, address indexed account, uint256 amount);

    /// @notice emitted after a successful ETH withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of ETH to withdraw from account
    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(address indexed user, address indexed account, uint256 amount);

    /// @notice emitted when a conditional order is placed
    /// @param conditionalOrderId: id of conditional order
    /// @param gelatoTaskId: id of gelato task
    /// @param marketKey: Synthetix PerpsV2 market key
    /// @param marginDelta: margin change
    /// @param sizeDelta: size change
    /// @param targetPrice: targeted fill price
    /// @param conditionalOrderType: expected conditional order type enum where 0 = LIMIT, 1 = STOP, etc..
    /// @param desiredFillPrice: desired price to fill Synthetix PerpsV2 order at execution time
    /// @param reduceOnly: if true, only allows position's absolute size to decrease
    function emitConditionalOrderPlaced(
        uint256 conditionalOrderId,
        bytes32 gelatoTaskId,
        bytes32 marketKey,
        int256 marginDelta,
        int256 sizeDelta,
        uint256 targetPrice,
        IAccount.ConditionalOrderTypes conditionalOrderType,
        uint256 desiredFillPrice,
        bool reduceOnly
    ) external;

    event ConditionalOrderPlaced(
        address indexed account,
        uint256 indexed conditionalOrderId,
        bytes32 indexed gelatoTaskId,
        bytes32 marketKey,
        int256 marginDelta,
        int256 sizeDelta,
        uint256 targetPrice,
        IAccount.ConditionalOrderTypes conditionalOrderType,
        uint256 desiredFillPrice,
        bool reduceOnly
    );

    /// @notice emitted when a conditional order is cancelled
    /// @param conditionalOrderId: id of conditional order
    /// @param gelatoTaskId: id of gelato task
    /// @param reason: reason for cancellation
    function emitConditionalOrderCancelled(
        uint256 conditionalOrderId,
        bytes32 gelatoTaskId,
        IAccount.ConditionalOrderCancelledReason reason
    ) external;

    event ConditionalOrderCancelled(
        address indexed account,
        uint256 indexed conditionalOrderId,
        bytes32 indexed gelatoTaskId,
        IAccount.ConditionalOrderCancelledReason reason
    );

    /// @notice emitted when a conditional order is filled
    /// @param conditionalOrderId: id of conditional order
    /// @param gelatoTaskId: id of gelato task
    /// @param fillPrice: price the conditional order was executed at
    /// @param keeperFee: fees paid to the executor
    function emitConditionalOrderFilled(
        uint256 conditionalOrderId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 keeperFee
    ) external;

    event ConditionalOrderFilled(
        address indexed account,
        uint256 indexed conditionalOrderId,
        bytes32 indexed gelatoTaskId,
        uint256 fillPrice,
        uint256 keeperFee
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Kwenta Factory Interface
/// @author JaredBorders ([email protected])
interface IFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when new account is created
    /// @param creator: account creator (address that called newAccount())
    /// @param account: address of account that was created (will be address of proxy)
    /// @param version: version of account created
    event NewAccount(address indexed creator, address indexed account, bytes32 version);

    /// @notice emitted when implementation is upgraded
    /// @param implementation: address of new implementation
    event AccountImplementationUpgraded(address implementation);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when factory cannot set account owner to the msg.sender
    /// @param data: data returned from failed low-level call
    error FailedToSetAcountOwner(bytes data);

    /// @notice thrown when Account creation fails due to no version being set
    /// @param data: data returned from failed low-level call
    error AccountFailedToFetchVersion(bytes data);

    /// @notice thrown when factory is not upgradable
    error CannotUpgrade();

    /// @notice thrown when account is unrecognized by factory
    error AccountDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @return canUpgrade: bool to determine if system can be upgraded
    function canUpgrade() external view returns (bool);

    /// @return logic: account logic address
    function implementation() external view returns (address);

    /// @param _account: address of account
    /// @return whether or not account exists
    function accounts(address _account) external view returns (bool);

    /// @param _account: address of account
    /// @return owner of account
    function getAccountOwner(address _account) external view returns (address);

    /// @param _owner: address of owner
    /// @return array of accounts owned by _owner
    function getAccountsOwnedBy(address _owner) external view returns (address[] memory);

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @notice update owner to account(s) mapping
    /// @dev does *NOT* check new owner != old owner
    /// @param _newOwner: new owner of account
    /// @param _oldOwner: old owner of account
    function updateAccountOwnership(address _newOwner, address _oldOwner) external;

    /*//////////////////////////////////////////////////////////////
                           ACCOUNT DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice create unique account proxy for function caller
    /// @return accountAddress address of account created
    function newAccount() external returns (address payable accountAddress);

    /*//////////////////////////////////////////////////////////////
                             UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    /// @notice upgrade implementation of account which all account proxies currently point to
    /// @dev this *will* impact all existing accounts
    /// @dev future accounts will also point to this new implementation (until
    /// upgradeAccountImplementation() is called again with a newer implementation)
    /// @dev *DANGER* this function does not check the new implementation for validity,
    /// thus, a bad upgrade could result in severe consequences.
    /// @param _implementation: address of new implementation
    function upgradeAccountImplementation(address _implementation) external;

    /// @notice remove upgradability from factory
    /// @dev cannot be undone
    function removeUpgradability() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IFuturesMarketManager {
    function marketForKey(bytes32 marketKey) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IPerpsV2MarketConsolidated {
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    struct DelayedOrder {
        bool isOffchain;
        int128 sizeDelta;
        uint128 desiredFillPrice;
        uint128 targetRoundId;
        uint128 commitDeposit;
        uint128 keeperDeposit;
        uint256 executableAtTime;
        uint256 intentionTime;
        bytes32 trackingCode;
    }

    function marketKey() external view returns (bytes32 key);

    function positions(address account) external view returns (Position memory);

    function delayedOrders(address account) external view returns (DelayedOrder memory);

    function assetPrice() external view returns (uint256 price, bool invalid);

    function transferMargin(int256 marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPositionWithTracking(int256 sizeDelta, uint256 desiredFillPrice, bytes32 trackingCode) external;

    function closePositionWithTracking(uint256 desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseOffchainDelayedOrderWithTracking(uint256 desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseDelayedOrderWithTracking(
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitDelayedOrderWithTracking(
        int256 sizeDelta,
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitOffchainDelayedOrderWithTracking(int256 sizeDelta, uint256 desiredFillPrice, bytes32 trackingCode)
        external;

    function cancelDelayedOrder(address account) external;

    function cancelOffchainDelayedOrder(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Kwenta Smart Margin Account Settings Interface
/// @author JaredBorders ([email protected])
interface ISettings {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when account execution is enabled or disabled
    /// @param enabled: true if account execution is enabled, false if disabled
    event AccountExecutionEnabledSet(bool enabled);

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice checks if account execution is enabled or disabled
    /// @return enabled: true if account execution is enabled, false if disabled
    function accountExecutionEnabled() external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice enables or disables account execution
    /// @param _enabled: true if account execution is enabled, false if disabled
    function setAccountExecutionEnabled(bool _enabled) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface ISystemStatus {
    function requireFuturesMarketActive(bytes32 marketKey) external view;
}