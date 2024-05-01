// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IConfigBuilder} from "./interfaces/IConfigBuilder.sol";
import {ICurrencyMetadata} from "./interfaces/ICurrencyMetadata.sol";
import {IHomechainOmnichainMessenger} from "./interfaces/IHomechainOmnichainMessenger.sol";
import {IIndex} from "./interfaces/IIndex.sol";
import {IOrderBook, OrderLib} from "./interfaces/IOrderBook.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IHomeEscrow} from "./escrow/interfaces/IHomeEscrow.sol";

import {BitSet} from "./libraries/BitSet.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {RebalancingLib} from "./libraries/RebalancingLib.sol";
import {Currency, CurrencyLib} from "./libraries/CurrencyLib.sol";

import {DepositCallbackLib} from "./libraries/DepositCallbackLib.sol";
import {OmnichainMessenger} from "./OmnichainMessenger.sol";

import {IPhutureOnDepositCallback} from "./interfaces/IPhutureOnDepositCallback.sol";

/// @title HomechainOmnichainMessenger
/// @notice Contract for handling cross-chain messaging and Index interactions on the Рomechain
contract HomechainOmnichainMessenger is IHomechainOmnichainMessenger, OmnichainMessenger, IPhutureOnDepositCallback {
    using FixedPointMathLib for *;
    using BitSet for uint256[];
    using CurrencyLib for Currency;

    /// @dev Struct for storing variables used during the broadcastOrders function
    struct BroadcastOrdersVars {
        uint256 remoteChainIndex;
        uint256 b;
        uint16 eid;
    }

    /// @dev Constant value representing the index of the home chain
    uint256 internal constant HOMECHAIN_INDEX = 0;

    /// @dev Constant value representing the size of gas options
    uint256 internal constant GAS_OPTIONS_SIZE = 34;

    /// @dev Constant value representing the size of airdrop options
    uint256 internal constant AIRDROP_OPTIONS_SIZE = 66;

    /// @dev Hash of the LayerZero configuration
    bytes32 internal layerZeroConfigHash;

    /// @dev Address of the ConfigBuilder contract
    IConfigBuilder internal builder;

    /// @dev Address of the Index contract
    address internal index;

    /// @notice Event emitted when the LayerZero configuration is set
    /// @param config The LayerZero configuration
    event SetLZConfig(LzConfig config);

    /// @notice Thrown when invalid options are provided
    error InvalidOptions();

    /// @notice Thrown when invalid batches are provided
    error InvalidBatches();

    /// @notice Thrown when the configuration hash does not match
    error ConfigHash();

    /// @notice Thrown when a refund fails
    error RefundFailed();

    /// @notice Thrown when invalid ranges are provided
    error InvalidRanges();

    constructor(
        address owner,
        address _stargateComposer,
        address payable _endpoint,
        uint16 _eid,
        address _sgETH,
        NativeInfo memory _nativeInfo
    ) OmnichainMessenger(owner, _stargateComposer, _endpoint, _eid, _sgETH, _nativeInfo) {
        LzConfig memory config;
        layerZeroConfigHash = keccak256(abi.encode(config));
    }

    /// @notice Configures the contract with the necessary addresses
    ///
    /// @param _index The address of the Index contract
    /// @param _orderBook The address of the OrderBook contract
    /// @param _builder The address of the ConfigBuilder contract
    function configure(address _index, address _orderBook, address _builder) external onlyOwner {
        index = _index;
        builder = IConfigBuilder(_builder);
        orderBook = IOrderBook(_orderBook);
    }

    /// @notice Deposits funds into the Index contract
    ///
    /// @param currency The input currency to deposit with
    /// @param amount The amount to deposit with the input currency
    /// @param params The deposit parameters – passed to the Index contract
    ///
    /// @return shares The number of shares minted
    function deposit(Currency currency, uint256 amount, IIndex.DepositParams calldata params)
        external
        payable
        returns (uint256 shares)
    {
        bytes memory cbData = abi.encode(currency, currency.isNative() ? msg.value : amount, msg.sender, hex"", hex"");
        return IIndex(index).deposit(params, address(this), cbData);
    }

    /// @notice Deposits funds into the Index contract with a permit
    ///
    /// @param currency The input currency to deposit with
    /// @param amount The amount to deposit with the input currency
    /// @param params The deposit parameters – passed to the Index contract
    /// @param permitData Encoded permit call (encoded with signature) or "0x" if no permit is required
    ///
    /// @return shares The number of shares minted
    function depositWithPermit(
        Currency currency,
        uint256 amount,
        IIndex.DepositParams calldata params,
        bytes calldata permitData
    ) external payable returns (uint256 shares) {
        bytes memory cbData =
            abi.encode(currency, currency.isNative() ? msg.value : amount, msg.sender, permitData, hex"");
        return IIndex(index).deposit(params, address(this), cbData);
    }

    /// @notice Deposits funds into the Index contract, trades, and provides a permit
    ///
    /// @param currency The input currency to deposit with
    /// @param amount The amount to deposit with the input currency
    /// @param params The deposit parameters – passed to the Index contract
    /// @param permitData Encoded permit call (encoded with signature) or "0x" if no permit is required
    /// @param tradeData Encoded trade data, consists of trade target and call data for the trade
    ///
    /// @return shares The number of shares minted
    function depositAndTradeWithPermit(
        Currency currency,
        uint256 amount,
        IIndex.DepositParams calldata params,
        bytes calldata permitData,
        bytes calldata tradeData
    ) external payable returns (uint256 shares) {
        bytes memory cbData =
            abi.encode(currency, currency.isNative() ? msg.value : amount, msg.sender, permitData, tradeData);
        return IIndex(index).deposit(params, address(this), cbData);
    }

    /// @notice Callback function for handling deposits
    ///
    /// @param reserve The reserve currency
    /// @param cbData The callback data for the deposit
    function phutureOnDepositCallbackV1(Currency reserve, bytes calldata cbData) external {
        if (msg.sender != index) revert Forbidden();
        DepositCallbackLib.deposit(reserve, cbData);
    }

    /// @notice Redeems shares from the Index contract and sends the proceeds
    ///
    /// @param params The redemption parameters
    /// @param sendParams The send parameters for cross-chain transfers
    function redeem(IIndex.RedemptionParams calldata params, SendParams calldata sendParams) external payable {
        if (keccak256(abi.encode(sendParams.config)) != layerZeroConfigHash) revert ConfigHash();
        if (sendParams.batches.length != sendParams.config.eIds.length()) revert InvalidBatches();

        uint256 balanceBefore = address(this).balance - msg.value;

        (address escrow, bool deployed) = escrowDeployer.escrowOf(msg.sender);

        if (!deployed) escrowDeployer.deploy(msg.sender);

        IIndex.RedemptionInfo memory info = IIndex(index).redeem(params, msg.sender, escrow);
        uint256 tradesIndex = _selectTrades(info.accountReserveSharesRedeemed, sendParams.ranges);

        IHomeEscrow(escrow).tradeAndWithdraw(sendParams.trades[tradesIndex], sendParams.escrowParams);

        if (info.accountKRedeemed != 0) {
            if (tradesIndex == sendParams.ranges.length - 1) {
                _sendSnapshotTransfer(info.accountKRedeemed, sendParams.config, sendParams.zroPaymentAddress);
            } else {
                _sendSnapshotTransferAndTrades(info.accountKRedeemed, tradesIndex, sendParams);
            }
        }

        uint256 refundAmount = address(this).balance - balanceBefore;
        if (refundAmount != 0) _refund(msg.sender, refundAmount);
    }

    /// @notice Retries a redemption
    ///
    /// @param homeTrades The trades to execute on the home chain
    /// @param escrowParams The parameters for the Home Escrow contract
    /// @param retries The retry parameters for each remote chain
    /// @param refundAddress The address to refund any excess funds
    /// @param zroPaymentAddress The address to pay for LayerZero fees
    function retryRedeem(
        IHomeEscrow.TradeParams[] calldata homeTrades,
        IHomeEscrow.Params calldata escrowParams,
        Retry[] calldata retries,
        address payable refundAddress,
        address zroPaymentAddress
    ) external payable {
        (address escrow,) = escrowDeployer.escrowOf(msg.sender);
        IHomeEscrow(escrow).tradeAndWithdraw(homeTrades, escrowParams);

        uint256 balanceBefore = address(this).balance - msg.value;

        for (uint256 i; i < retries.length; ++i) {
            Retry calldata retry = retries[i];
            bytes memory path = _getPathOrRevert(retry.eid);

            for (uint256 j; j < retry.callbacks.length; ++j) {
                _validateOptions(retry.options[j], minGasAmountForChain[retry.eid]);

                _lzSend(
                    retry.eid,
                    path,
                    abi.encode(TRADE_SNAPSHOT, msg.sender, retry.callbacks[j]),
                    payable(address(this)),
                    zroPaymentAddress,
                    retry.options[j]
                );
            }
        }

        uint256 refundAmount = address(this).balance - balanceBefore;
        if (refundAmount != 0) _refund(refundAddress, refundAmount);
    }

    /// @notice Sets the LayerZero configuration
    ///
    /// @param config The LayerZero configuration
    function setLayerZeroConfig(LzConfig calldata config) external onlyOwner {
        layerZeroConfigHash = keccak256(abi.encode(config));
        emit SetLZConfig(config);
    }

    /// @notice Updates the registered currencies
    ///
    /// @param result The result containing the updated currencies
    function currenciesUpdated(IVault.RegisterCurrenciesResult calldata result) external onlyOwner {
        builder.currenciesUpdated(_fillCurrenciesMetadata(result));
    }

    /// @notice Finishes the vault rebalancing process
    ///
    /// @param orderBookParams The order book parameters for finishing order execution
    /// @param params The parameters for ending the rebalancing phase
    /// @param sgParams The Stargate parameters for distributing orders
    /// @param lzParams The LayerZero parameters for distributing orders
    function finishVaultRebalancing(
        IOrderBook.FinishOrderExecutionParams calldata orderBookParams,
        IVault.EndRebalancingParams calldata params,
        SgParams[] calldata sgParams,
        LzParams calldata lzParams,
        address payable
    ) external payable onlyOwner {
        // gather pending orders from order book and distribute them across the chains using Stargate
        _distributeOrders(orderBook.finishOrderExecution(orderBookParams), sgParams, lzParams);

        // notify the ConfigBuilder contract that the rebalancing phase has finished on local Vault
        builder.chainRebalancingFinished(block.chainid, IVault(index).finishRebalancingPhase(params));
    }

    /// @notice Broadcasts orders to remote chains
    ///
    /// @param chainIds The chain IDs of the remote chains
    /// @param chainIdSet The set of chain IDs to broadcast to
    /// @param homechainOrders The orders for the home chain
    /// @param ordersHashes The hashes of the orders for each remote chain
    /// @param withdrawals The currency withdrawals for each chain
    /// @param lzData The LayerZero data for broadcasting orders
    function broadcastOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders calldata homechainOrders,
        bytes32[] calldata ordersHashes,
        IVault.CurrencyWithdrawal[] calldata withdrawals,
        bytes calldata lzData
    ) external payable override {
        if (msg.sender != address(builder)) revert Forbidden();

        {
            IVault(index).startRebalancingPhase(withdrawals[HOMECHAIN_INDEX]);

            OrderLib.Order[] memory orders = homechainOrders.orders;
            if (chainIdSet.size() != 1) _injectLocalBuyCurrency(orders);
            orderBook.setOrders(homechainOrders.incomingOrders, orders);
        }

        BroadcastOrdersVars memory vars;
        LzParams memory lzParams = abi.decode(lzData, (LzParams));

        uint256 w = chainIdSet[0];
        for (vars.b = BitSet.find(w, 0); BitSet.hasNext(w, vars.b);) {
            if (vars.b != HOMECHAIN_INDEX) {
                vars.eid = eIds[chainIds[vars.b]];

                _lzSend(
                    vars.eid,
                    _getPathOrRevert(vars.eid),
                    abi.encode(
                        START_REBALANCING, ordersHashes[vars.remoteChainIndex], withdrawals[vars.remoteChainIndex + 1]
                    ),
                    payable(address(this)),
                    lzParams.zroPaymentAddress,
                    lzParams.options[vars.remoteChainIndex]
                );

                unchecked {
                    ++vars.remoteChainIndex;
                }
            }

            unchecked {
                vars.b = BitSet.find(w, vars.b + 1);
            }
        }
    }

    /// @notice Broadcasts reserve orders to remote chains
    ///
    /// @param chainIds The chain IDs of the remote chains
    /// @param chainIdSet The set of chain IDs to broadcast to
    /// @param chainOrders The orders for each chain
    /// @param lzParams The LayerZero parameters for broadcasting orders
    function broadcastReserveOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders[] calldata chainOrders,
        bytes calldata lzParams
    ) external payable override {
        if (msg.sender != address(builder)) revert Forbidden();

        {
            IVault.CurrencyWithdrawal memory withdrawal;
            IVault(index).startRebalancingPhase(withdrawal);

            OrderLib.Order[] memory orders = chainOrders[HOMECHAIN_INDEX].orders;
            if (chainIdSet.size() != 1) _injectLocalBuyCurrency(orders);
            orderBook.setOrders(chainOrders[HOMECHAIN_INDEX].incomingOrders, orders);
        }

        BroadcastOrdersVars memory vars;
        LzParams memory lzParamsDecoded = abi.decode(lzParams, (LzParams));

        uint256 w = chainIdSet[0];
        for (vars.b = BitSet.find(w, 0); BitSet.hasNext(w, vars.b);) {
            if (vars.b != HOMECHAIN_INDEX) {
                vars.eid = eIds[chainIds[vars.b]];

                _lzSend(
                    vars.eid,
                    _getPathOrRevert(vars.eid),
                    abi.encode(START_RESERVE_REBALANCING, chainOrders[vars.remoteChainIndex + 1].incomingOrders),
                    payable(address(this)),
                    lzParamsDecoded.zroPaymentAddress,
                    lzParamsDecoded.options[vars.remoteChainIndex]
                );

                unchecked {
                    ++vars.remoteChainIndex;
                }
            }

            unchecked {
                vars.b = BitSet.find(w, vars.b + 1);
            }
        }
    }

    /// @dev Handles received messages from LayerZero
    ///
    /// @param message The received message
    function _lzReceive(bytes calldata message) internal override {
        uint8 packetType = uint8(uint256(bytes32(message[:32])));

        if (packetType == FINISH_REBALANCING) {
            (, HashedResult memory result) = abi.decode(message, (uint8, HashedResult));
            builder.chainRebalancingFinished(result.chainId, result.hash);
        } else if (packetType == REGISTER_CURRENCY) {
            (, ICurrencyMetadata.RegisteredMetadata memory result) =
                abi.decode(message, (uint8, ICurrencyMetadata.RegisteredMetadata));
            builder.currenciesUpdated(result);
        } else if (packetType == REMOVE_DUST_ORDERS) {
            (, uint256 incomingOrders) = abi.decode(message, (uint8, uint256));
            orderBook.removeDustOrders(incomingOrders);
        }
    }

    /// @dev Sends snapshot transfers to remote chains
    ///
    /// @param kRedeemed The amount of shares redeemed
    /// @param config The LayerZero configuration
    /// @param zroPaymentAddress The address to pay for LayerZero fees with ZRO
    function _sendSnapshotTransfer(uint256 kRedeemed, LzConfig calldata config, address zroPaymentAddress) internal {
        for (uint256 i; i < config.eIds.length(); ++i) {
            uint16 eid = config.eIds.at(i);

            bytes memory message = abi.encode(TRANSFER_SNAPSHOT, msg.sender, kRedeemed);
            bytes memory options = _gasOptions(config.minGas[i]);

            _lzSend(eid, _getPathOrRevert(eid), message, payable(address(this)), zroPaymentAddress, options);
        }
    }

    /// @dev Sends snapshot transfers and trades to remote chains
    ///
    /// @param kRedeemed The amount of K redeemed
    /// @param dataIndex The index of the data to send
    /// @param sendParams The send parameters for cross-chain transfers
    function _sendSnapshotTransferAndTrades(uint256 kRedeemed, uint256 dataIndex, SendParams calldata sendParams)
        internal
    {
        for (uint256 i; i < sendParams.batches.length; ++i) {
            bytes memory path = _getPathOrRevert(sendParams.config.eIds.at(i));

            uint256 length = sendParams.batches[i].data[dataIndex].callbacks.length;
            for (uint256 j; j < length; ++j) {
                _lzSend(
                    sendParams.config.eIds.at(i),
                    path,
                    j == 0
                        ? abi.encode(
                            TRANSFER_AND_TRADE_SNAPSHOT,
                            msg.sender,
                            kRedeemed,
                            sendParams.batches[i].data[dataIndex].callbacks[j]
                        )
                        : abi.encode(TRADE_SNAPSHOT, msg.sender, sendParams.batches[i].data[dataIndex].callbacks[j]),
                    payable(address(this)),
                    sendParams.zroPaymentAddress,
                    _airdropOptions(
                        sendParams.config.minGas[i] + sendParams.batches[i].data[dataIndex].additionalGas[j],
                        j == length - 1 ? sendParams.batches[i].data[dataIndex].airdropAmount : 0,
                        sendParams.batches[i].escrow
                    )
                );
            }
        }
    }

    /// @dev Refunds excess funds to the recipient
    ///
    /// @param recipient The address to refund the funds to
    /// @param amount The amount to refund
    function _refund(address recipient, uint256 amount) internal {
        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert RefundFailed();
    }

    /// @dev version 1 LayerZero options
    ///
    /// @param gas The gas amount
    ///
    /// @return The encoded gas options
    function _gasOptions(uint256 gas) internal pure returns (bytes memory) {
        return abi.encodePacked(uint16(1), gas);
    }

    /// @dev version 2 LayerZero options
    ///
    /// @param gas The gas amount
    /// @param dstNative The amount of native token to airdrop
    /// @param dstAddress The address to airdrop the native token to
    ///
    /// @return The encoded airdrop options
    function _airdropOptions(uint256 gas, uint256 dstNative, address dstAddress) internal pure returns (bytes memory) {
        return abi.encodePacked(uint16(2), gas, dstNative, dstAddress);
    }

    /// @dev Validates the provided options
    ///
    /// @param options The options to validate
    /// @param minGasAmountForChain The minimum gas amount required for the chain
    function _validateOptions(bytes memory options, uint256 minGasAmountForChain) internal pure {
        if (!(options.length == GAS_OPTIONS_SIZE || options.length > AIRDROP_OPTIONS_SIZE)) revert InvalidOptions();

        uint16 txType;
        uint256 extraGas;
        assembly {
            txType := mload(add(options, 2))
            extraGas := mload(add(options, GAS_OPTIONS_SIZE))
        }

        if (!(txType == 1 || txType == 2)) revert InvalidOptions();
        if (minGasAmountForChain > extraGas) revert InvalidOptions();
    }

    /// @dev Selects the appropriate trades based on the redeemed shares
    ///
    /// @param accountReserveSharesRedeemed The amount of reserve shares redeemed by the account
    /// @param ranges The ranges to select the trades from
    ///
    /// @return The index of the selected trades
    function _selectTrades(uint256 accountReserveSharesRedeemed, Range[] calldata ranges)
        internal
        pure
        returns (uint256)
    {
        uint256 last = ranges.length - 1;
        for (uint256 i; i < last; ++i) {
            if (ranges[i].start > ranges[i].end) revert InvalidRanges();
            if (i > 0 && ranges[i].start <= ranges[i - 1].end) revert InvalidRanges();

            if (accountReserveSharesRedeemed >= ranges[i].start && accountReserveSharesRedeemed <= ranges[i].end) {
                return i;
            }
        }
        return last;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IIndex} from "./IIndex.sol";
import {IVault} from "./IVault.sol";
import {ICurrencyMetadata} from "./ICurrencyMetadata.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

interface IConfigBuilder {
    struct Anatomy {
        uint256[] chainIdSet;
        uint256[][] currencyIdSets;
    }

    struct SharedConfig {
        uint256 AUMDilutionPerSecond;
        bool useCustomAUMFee;
        address metadata;
    }

    struct FeeConfig {
        uint16 BPs;
        bool useCustomCallback;
    }

    struct Config {
        SharedConfig shared;
        FeeConfig depositFee;
        FeeConfig redemptionFee;
    }

    struct StartReserveRebalancingParams {
        Anatomy anatomy;
        uint256[] chainIds;
        Currency[][] currencies;
    }

    struct StartRebalancingParams {
        Anatomy anatomy;
        Anatomy newAnatomy;
        uint256[] chainIds;
        Currency[][] currencies;
        uint256[] newWeights;
        uint256[] orderCounts; // count of orders for current anatomy chains
        bytes payload;
    }

    function startRebalancing(StartRebalancingParams calldata params, bytes calldata data) external payable;

    function startReserveRebalancing(StartReserveRebalancingParams calldata params, bytes calldata data)
        external
        payable;

    function finishRebalancing(IVault.RebalancingResult[] calldata results, IConfigBuilder.Config calldata config)
        external
        returns (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption);

    function chainRebalancingFinished(uint256 chainId, bytes32 resultHash) external;

    function currenciesUpdated(ICurrencyMetadata.RegisteredMetadata calldata result) external;

    function registerChain(uint256 chainId) external;

    function setMessenger(address _messenger) external;

    function setConfig(IConfigBuilder.Config memory _config)
        external
        returns (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption);

    function configs(Config calldata _config)
        external
        view
        returns (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption);

    function configHash() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

interface ICurrencyMetadata {
    struct RegisteredMetadata {
        uint256 chainId;
        CurrencyMetadata[] metadata;
        bytes32 currenciesHash;
    }

    struct CurrencyMetadata {
        string name;
        string symbol;
        uint8 decimals;
        Currency currency;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IOmnichainMessenger} from "./IOmnichainMessenger.sol";
import {IVault} from "./IVault.sol";
import {IHomeEscrow} from "../escrow/interfaces/IHomeEscrow.sol";

import {u16x15} from "../utils/u16x15.sol";
import {RebalancingLib} from "../libraries/RebalancingLib.sol";

interface IHomechainOmnichainMessenger is IOmnichainMessenger {
    struct LzConfig {
        u16x15 eIds;
        uint256[] minGas;
    }

    struct Batches {
        address escrow;
        RemoteData[] data;
    }

    struct RemoteData {
        bytes[] callbacks;
        uint256[] additionalGas;
        uint256 airdropAmount;
    }

    struct SendParams {
        LzConfig config;
        Range[] ranges;
        IHomeEscrow.TradeParams[][] trades;
        Batches[] batches;
        address zroPaymentAddress;
        bytes packedRecipient;
        IHomeEscrow.Params escrowParams;
    }

    struct Range {
        uint256 start;
        uint256 end;
    }

    struct Retry {
        uint16 eid;
        bytes[] options;
        bytes[] callbacks;
    }

    function configure(address index, address orderBook, address builder) external;

    function setLayerZeroConfig(LzConfig calldata config) external;

    function currenciesUpdated(IVault.RegisterCurrenciesResult calldata result) external;

    function broadcastOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders calldata homeChainOrders,
        bytes32[] calldata chainOrdersHash,
        IVault.CurrencyWithdrawal[] calldata withdrawals,
        bytes calldata lzParams
    ) external payable;

    function broadcastReserveOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders[] calldata chainOrders,
        bytes calldata lzParams
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVault} from "./IVault.sol";

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IIndex is IVault {
    struct IndexState {
        uint128 totalSupply;
        uint96 fees;
        uint32 lastAUMAccrualTimestamp;
        uint96 reserve;
    }

    struct Config {
        uint256 latestSnapshot; // needed to get the latest k value
        uint256 AUMDilutionPerSecond;
        bool useCustomAUMFee;
        address staticPriceOracle;
        address metadata;
    }

    struct FeeConfig {
        uint16 BPs;
        bool useCustomCallback;
    }

    struct DepositConfig {
        Config shared;
        FeeConfig fee;
    }

    struct RedemptionConfig {
        Config shared;
        FeeConfig fee;
        address forwarder;
        a160u96[] homeCurrencies; // Reserve currency + Vault's currencies
    }

    struct DepositParams {
        DepositConfig config;
        address recipient;
        bytes payload;
    }

    struct RedemptionParams {
        RedemptionConfig config;
        address owner;
        uint128 shares;
        bytes payload;
    }

    struct RedemptionInfo {
        uint256 reserveValuation;
        uint256 totalValuation;
        uint256 totalReserveShares;
        uint128 totalSupplyAfterAUMAccrual;
        uint256 totalKBeforeRedeem;
        uint256 accountBalanceSharesBeforeRedeem;
        uint96 accountReserveRedeemed;
        uint256 accountReserveSharesRedeemed;
        uint256 accountKRedeemed;
        uint256 reservePriceInQ128;
    }

    error IndexConfigHash();
    error IndexConfigMismatch();
    error IndexInitialConfig();
    error PermitDeadlineExpired();
    error InvalidSigner();
    error ZeroAddressTransfer();
    error InvalidSender();
    error ZeroDeposit();

    function deposit(DepositParams calldata params, address cbTarget, bytes calldata cbData)
        external
        payable
        returns (uint256 shares);

    function redeem(RedemptionParams calldata params, address forwardedSender, address recipient)
        external
        returns (RedemptionInfo memory redeemed);

    function startIndexRebalancing() external;

    function setConfig(
        Config calldata _prevConfig,
        DepositConfig calldata _depositConfig,
        RedemptionConfig calldata _redemptionConfig
    ) external;

    function setFeePool(address feePool) external;

    function accrueFee(address recipient) external;

    function reserve() external view returns (Currency);
    function reserveBalance() external view returns (uint96);
    function kSelf() external view returns (uint256);
    function fees() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";
import {OrderLib} from "../libraries/OrderLib.sol";

/// @title IOrderBook interface
interface IOrderBook {
    struct TradeParams {
        address target;
        bytes data;
    }

    struct BoughtOrder {
        // Bought amount of local buy currency, sell amount on the remote
        uint256 amount;
        // Buy currency on the remote
        Currency buyCurrency;
    }

    struct PendingOrder {
        uint256 chainId;
        Currency currency;
        uint256 totalBought;
        BoughtOrder[] orders;
    }

    struct FinishOrderExecutionParams {
        OrderLib.OrderId[] orderIds;
        uint256[] idIndices;
        uint256[] pendingOrderCounts;
    }

    struct ExecuteOrderParams {
        OrderLib.OrderId orderId;
        uint96 sell;
        TradeParams tradeParams;
        bytes payload;
    }

    event OrderFilled(bytes32 indexed id, uint256 sold, uint256 bought);

    function receiveIncomingOrders(OrderLib.Order[] calldata orders, Currency currency, uint256 amount) external;
    function removeDustOrders(uint256 _incomingOrders) external;

    function setOrders(uint256 _incomingOrders, OrderLib.Order[] calldata orders) external;

    /// @notice Execute the given local order
    /// @param params Execute order data
    function executeOrder(ExecuteOrderParams calldata params) external;

    function finishOrderExecution(FinishOrderExecutionParams calldata params)
        external
        returns (PendingOrder[] memory pendingOrders);

    function updateFundManager(address fundManager, bool isAllowed) external;

    function setMessenger(address messenger) external;

    function setPriceOracle(address priceOracle) external;

    function setMaxSlippageInBP(uint16 maxSlippageInBP) external;

    function orderOf(OrderLib.OrderId calldata orderIdParams) external view returns (uint96 amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IVault {
    struct CurrencyWithdrawal {
        uint256[] currencyIndexSet;
        uint96[] amounts;
    }

    struct SnapshotAnatomy {
        a160u96[] currencies;
        uint256[] currencyIndexSet;
    }

    struct EndRebalancingParams {
        a160u96[] anatomyCurrencies;
        SnapshotAnatomy newAnatomy;
        CurrencyWithdrawal withdrawals;
        uint256 lastKBalance;
        Currency[] currencies;
    }

    struct RebalancingResult {
        uint256 chainId;
        uint256 snapshot;
        uint256[] currencyIdSet;
        a160u96[] currencies;
    }

    struct RegisterCurrenciesResult {
        Currency[] currencies;
        bytes32 currenciesHash;
    }

    function setOrderBook(address _orderBook) external;
    function setMessenger(address _messenger) external;

    function startRebalancingPhase(CurrencyWithdrawal calldata withdrawals) external;

    function finishRebalancingPhase(EndRebalancingParams calldata params) external returns (bytes32);
    function transferLatestSnapshot(address recipient, uint256 kAmountWads) external returns (uint256);
    function withdraw(uint256 snapshot, uint256 kAmount, address recipient) external;
    function registerCurrencies(Currency[] calldata currencies) external returns (RegisterCurrenciesResult memory);

    function donate(Currency currency, bytes memory data) external;
    function consume(Currency currency, uint96 amount, address target, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../../libraries/CurrencyLib.sol";
import {IEscrow} from "./IEscrow.sol";

/// @title IHomeEscrow
/// @dev Interface for the HomeEscrow contract, which extends the functionality of the IEscrow interface
///      The HomeEscrow contract enables trading and withdrawal of funds based on specified parameters
interface IHomeEscrow is IEscrow {
    /// @dev Struct representing the parameters for the tradeAndWithdraw function
    struct Params {
        Currency outputCurrency;
        address recipient;
    }

    /// @notice Executes a series of trades based on the provided trade parameters and withdraws the resulting funds
    ///
    /// @param trades An array of TradeParams structs representing the trades to be executed
    /// @param params The Params struct specifying the output currency and recipient for the withdrawn funds
    function tradeAndWithdraw(TradeParams[] calldata trades, Params calldata params) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title BitSet
/// @notice A library for managing bitsets
library BitSet {
    uint256 private constant WORD_SHIFT = 8;

    /// @notice Checks if the next bit is set in the given word starting from the given bit position
    ///
    /// @param word The word to check
    /// @param bit The bit position
    ///
    /// @return r True if the next bit is set, false otherwise
    function hasNext(uint256 word, uint256 bit) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := and(shr(bit, word), 1)
        }
    }

    /// @notice Finds the position of the next set bit in the given word starting from the given bit position
    ///
    /// @dev This function uses a lookup table approach to find the position of the next set bit.
    ///      It first shifts the word right by the given bit position and then checks the lower 3 bits
    ///      of the resulting word to determine the position of the next set bit.
    ///      If no set bit is found, it returns 256 to indicate that there are no more set bits.
    ///
    /// @param word The word to search
    /// @param b The starting bit position
    ///
    /// @return nb The position of the next set bit
    function find(uint256 word, uint256 b) internal pure returns (uint256 nb) {
        assembly ("memory-safe") {
            let w := shr(b, word)
            switch w
            case 0 {
                // no more bits
                nb := 256
            }
            default {
                // 0b000 = 0
                // 0b001 = 1
                // 0b010 = 2
                // 0b011 = 3
                // 0b100 = 4
                // 0b101 = 5
                // 0b110 = 6
                // 0b111 = 7
                switch and(w, 7)
                case 0 { nb := add(lsb(w), b) }
                case 2 { nb := add(b, 1) }
                case 4 { nb := add(b, 2) }
                case 6 { nb := add(b, 1) }
                default { nb := b }
            }

            function lsb(x) -> r {
                if iszero(x) { revert(0, 0) }
                r := 255
                switch gt(and(x, 0xffffffffffffffffffffffffffffffff), 0)
                case 1 { r := sub(r, 128) }
                case 0 { x := shr(128, x) }

                switch gt(and(x, 0xffffffffffffffff), 0)
                case 1 { r := sub(r, 64) }
                case 0 { x := shr(64, x) }

                switch gt(and(x, 0xffffffff), 0)
                case 1 { r := sub(r, 32) }
                case 0 { x := shr(32, x) }

                switch gt(and(x, 0xffff), 0)
                case 1 { r := sub(r, 16) }
                case 0 { x := shr(16, x) }

                switch gt(and(x, 0xff), 0)
                case 1 { r := sub(r, 8) }
                case 0 { x := shr(8, x) }

                switch gt(and(x, 0xf), 0)
                case 1 { r := sub(r, 4) }
                case 0 { x := shr(4, x) }

                switch gt(and(x, 0x3), 0)
                case 1 { r := sub(r, 2) }
                case 0 { x := shr(2, x) }

                switch gt(and(x, 0x1), 0)
                case 1 { r := sub(r, 1) }
            }
        }
    }

    /// @notice Computes the value at the given word index and bit position
    ///
    /// @param wordIndex The index of the word
    /// @param bit The bit position within the word
    ///
    /// @return r The computed value
    function valueAt(uint256 wordIndex, uint256 bit) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := or(shl(8, wordIndex), bit)
        }
    }

    /// @notice Creates a new bitset with the given maximum size
    ///
    /// @param maxSize The maximum size of the bitset
    ///
    /// @return bitset The created bitset
    function create(uint256 maxSize) internal pure returns (uint256[] memory bitset) {
        bitset = new uint256[](_capacity(maxSize));
    }

    /// @notice Checks if the given value is contained in the bitset
    ///
    /// @param bitset The bitset to check
    /// @param value The value to search for
    ///
    /// @return _contains True if the value is contained in the bitset, false otherwise
    function contains(uint256[] memory bitset, uint256 value) internal pure returns (bool _contains) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        if (wordIndex < bitset.length) {
            _contains = (bitset[wordIndex] & (1 << bit)) != 0;
        }
    }

    /// @notice Adds the given value to the bitset
    ///
    /// @param bitset The bitset to modify
    /// @param value The value to add
    ///
    /// @return The modified bitset
    function add(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] |= (1 << bit);
        return bitset;
    }

    /// @notice Adds all elements from bitset b to bitset a
    ///
    /// @param a The destination bitset
    /// @param b The source bitset
    ///
    /// @return c The resulting bitset
    function addAll(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory c) {
        (uint256 min, uint256 max) = a.length < b.length ? (a.length, b.length) : (b.length, a.length);
        c = new uint256[](max);
        uint256 i;
        for (; i < min; ++i) {
            c[i] = a[i] | b[i];
        }
        // copy leftover elements from a
        for (; i < a.length; ++i) {
            c[i] = a[i];
        }
        // copy leftover elements from b
        for (; i < b.length; ++i) {
            c[i] = b[i];
        }
    }

    /// @notice Removes the given value from the bitset
    ///
    /// @param bitset The bitset to modify
    /// @param value The value to remove
    ///
    /// @return The modified bitset
    function remove(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] &= ~(1 << bit);
        return bitset;
    }

    /// @notice Computes the size (number of set bits) of the bitset
    ///
    /// @param bitset The bitset to compute the size of
    ///
    /// @return count The number of set bits in the bitset
    function size(uint256[] memory bitset) internal pure returns (uint256 count) {
        for (uint256 i; i < bitset.length; ++i) {
            count += _countSetBits(bitset[i]);
        }
    }

    /// @dev Computes the word index and bit position for the given value
    ///
    /// @param value The value to compute the offsets for
    ///
    /// @return wordIndex The index of the word containing the value
    /// @return bit The bit position within the word
    function _bitOffset(uint256 value) private pure returns (uint256 wordIndex, uint8 bit) {
        assembly ("memory-safe") {
            wordIndex := shr(8, value)
            // mask bits that don't fit the first wordIndex's bits
            // n % 2^i = n & (2^i - 1)
            bit := and(value, 255)
        }
    }

    /// @dev Computes the number of words required to store the given maximum size
    ///
    /// @param maxSize The maximum size of the bitset
    ///
    /// @return words The number of words required
    function _capacity(uint256 maxSize) private pure returns (uint256 words) {
        // round up
        words = (maxSize + type(uint8).max) >> WORD_SHIFT;
    }

    /// @dev Counts the number of set bits in the given word using Brian Kernighan's algorithm
    ///
    /// @param x The word to count the set bits of
    ///
    /// @return count The number of set bits in the word
    function _countSetBits(uint256 x) private pure returns (uint256 count) {
        // Brian Kernighan's Algorithm
        // This algorithm counts the number of set bits in a word by repeatedly
        // clearing the least significant set bit until the word becomes zero.
        while (x != 0) {
            unchecked {
                // cannot overflow, x > 0
                x = x & (x - 1);
                ++count;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Currency} from "./CurrencyLib.sol";
import {BitSet} from "./BitSet.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OrderLib} from "./OrderLib.sol";
import {PriceLib} from "../price-oracles/libraries/PriceLib.sol";
import {StackLib} from "./StackLib.sol";

import {IVault} from "../interfaces/IVault.sol";
import {IConfigBuilder} from "../interfaces/IConfigBuilder.sol";

/// @title RebalancingLib
/// @notice Library for managing order creation during rebalancing
library RebalancingLib {
    using SafeCastLib for *;
    using BitSet for *;
    using FixedPointMathLib for *;
    using PriceLib for *;
    using StackLib for StackLib.Node;

    /// @dev Represents the orders for a specific chain
    struct ChainOrders {
        OrderLib.Order[] orders;
        uint128 incomingOrders;
    }

    /// @dev Represents the valuation information for the assets
    struct ValuationInfo {
        uint96[] balances;
        uint256[] prices;
        uint256 totalValuation;
    }

    /// @dev Represents the result of the rebalancing process
    struct RebalancingResult {
        ChainOrders[] chainOrders;
        IVault.CurrencyWithdrawal[] withdrawals;
        uint256[] chainIdSet;
        uint256[] counters;
    }

    struct RebalancingVars {
        StackLib.Node sellDeltas;
        StackLib.Node buyDeltas;
        uint256 targetInBase;
        uint256 currentInBase;
        uint256 i;
        uint256 j;
        uint256 priorChainIndex;
        uint256 activeChainIndex;
        uint256 currencyIndex;
        uint256 orderIndex;
        uint256 weightIndex;
        bytes32 chainsHash;
        bytes32 currenciesHash;
        uint256[] counters;
        bool priorChain;
        bool activeChain;
        bool priorAsset;
    }

    struct ReserveRebalancingVars {
        uint256 orderCount;
        uint96 utilized;
        uint256 i;
        uint256 j;
        uint256 lastIndex;
        uint256 orderIndex;
        uint256 weightIndex;
        bytes32 chainsHash;
    }

    uint256 internal constant MAX_WEIGHT = type(uint16).max;

    /// @notice Thrown when the currencies hash does not match the expected value
    /// @param chainId The chainId that the hash is associated with
    error CurrenciesHashMismatch(uint256 chainId);

    /// @notice Thrown when the total weight of the rebalancing weights is not equal to MAX_WEIGHT
    error TotalWeight();

    /// @notice Thrown when there are unutilized weights in the rebalancing weights
    error UnutilizedWeights();

    /// @notice Thrown when the chains hash does not match the expected value
    error ChainsHashMismatch();

    /// @notice Previews the rebalancing orders based on the given parameters
    ///
    /// @param currenciesHashOf The mapping of chain IDs to their currencies hash
    /// @param valuationInfo The valuation information for the assets
    /// @param params The start rebalancing parameters
    /// @param chainsHash The expected hash of the chain IDs
    ///
    /// @return result The rebalancing result containing the chain orders, withdrawals, and counters
    function previewRebalancingOrders(
        mapping(uint256 => bytes32) storage currenciesHashOf,
        ValuationInfo memory valuationInfo,
        IConfigBuilder.StartRebalancingParams calldata params,
        bytes32 chainsHash
    ) internal view returns (RebalancingResult memory result) {
        result.chainIdSet = params.anatomy.chainIdSet.addAll(params.newAnatomy.chainIdSet);
        result.chainOrders = new ChainOrders[](result.chainIdSet.size());
        result.withdrawals = new IVault.CurrencyWithdrawal[](result.chainOrders.length);

        result.counters = new uint256[](result.chainOrders.length);

        RebalancingVars memory vars;
        for (; vars.i < params.chainIds.length;) {
            vars.chainsHash = keccak256(abi.encode(vars.chainsHash, params.chainIds[vars.i]));

            vars.priorChain = params.anatomy.chainIdSet.contains(vars.i);
            vars.activeChain = params.newAnatomy.chainIdSet.contains(vars.i);
            if (vars.activeChain || vars.priorChain) {
                if (vars.priorChain) {
                    result.chainOrders[vars.orderIndex].orders =
                        new OrderLib.Order[](params.orderCounts[vars.orderIndex]);
                    result.withdrawals[vars.orderIndex] = IVault.CurrencyWithdrawal(
                        BitSet.create(params.currencies[vars.orderIndex].length),
                        new uint96[](params.anatomy.currencyIdSets[vars.priorChainIndex].size())
                    );
                }

                IVault.CurrencyWithdrawal memory withdrawal = result.withdrawals[vars.orderIndex];

                vars.currenciesHash = bytes32(0);
                Currency[] calldata currencies = params.currencies[vars.orderIndex];
                for (vars.j = 0; vars.j < currencies.length;) {
                    vars.currenciesHash = keccak256(abi.encode(vars.currenciesHash, currencies[vars.j]));
                    vars.priorAsset =
                        vars.priorChain && params.anatomy.currencyIdSets[vars.priorChainIndex].contains(vars.j);

                    vars.targetInBase = vars.activeChain
                        && params.newAnatomy.currencyIdSets[vars.activeChainIndex].contains(vars.j)
                        ? valuationInfo.totalValuation.mulDivUp(params.newWeights[vars.weightIndex++], MAX_WEIGHT)
                        : 0;

                    vars.currentInBase = vars.priorAsset
                        ? valuationInfo.balances[vars.currencyIndex].convertToBaseUp(
                            valuationInfo.prices[vars.currencyIndex]
                        )
                        : 0;

                    if (vars.currentInBase < vars.targetInBase) {
                        uint256 delta = vars.targetInBase - vars.currentInBase;
                        vars.buyDeltas =
                            vars.buyDeltas.push(delta, vars.orderIndex, currencies[vars.j], params.chainIds[vars.i]);
                    } else if (vars.currentInBase > vars.targetInBase) {
                        // result will never exceed type(uint96).max.
                        uint96 assets = uint96(
                            valuationInfo.balances[vars.currencyIndex].mulDivDown(
                                vars.currentInBase - vars.targetInBase, vars.currentInBase
                            )
                        );

                        if (assets != 0) {
                            vars.sellDeltas = vars.sellDeltas.push(
                                vars.currentInBase - vars.targetInBase,
                                assets,
                                vars.orderIndex,
                                currencies[vars.j],
                                valuationInfo.prices[vars.currencyIndex]
                            );

                            withdrawal.amounts[withdrawal.currencyIndexSet.size()] = assets;
                            withdrawal.currencyIndexSet.add(vars.j);
                        }
                    }

                    unchecked {
                        if (vars.priorAsset) ++vars.currencyIndex;
                        ++vars.j;
                    }
                }

                if (vars.currenciesHash != currenciesHashOf[vars.i]) {
                    revert CurrenciesHashMismatch(params.chainIds[vars.i]);
                }

                (vars.sellDeltas, vars.buyDeltas) =
                    _createOrders(result.chainOrders, vars.sellDeltas, vars.buyDeltas, result.counters);

                unchecked {
                    if (vars.priorChain) ++vars.priorChainIndex;
                    if (vars.activeChain) ++vars.activeChainIndex;
                    ++vars.orderIndex;
                }
            }

            unchecked {
                ++vars.i;
            }
        }

        if (params.newWeights.length != vars.weightIndex) revert UnutilizedWeights();
        if (vars.chainsHash != chainsHash) revert ChainsHashMismatch();
    }

    /// @notice Previews the reserve rebalancing orders based on the given parameters
    ///
    /// @param currenciesHashOf The mapping of chain IDs to their currencies hash
    /// @param weights The array of weights for the reserve assets
    /// @param params The start reserve rebalancing parameters
    /// @param reserveAmount The total amount of reserve assets
    /// @param reserve The reserve currency
    /// @param chainsHash The expected hash of the chain IDs
    ///
    /// @return orders The array of chain orders for the reserve rebalancing
    function previewReserveRebalancingOrders(
        mapping(uint256 => bytes32) storage currenciesHashOf,
        uint256[] memory weights,
        IConfigBuilder.StartReserveRebalancingParams calldata params,
        uint96 reserveAmount,
        Currency reserve,
        bytes32 chainsHash
    ) internal view returns (ChainOrders[] memory orders) {
        orders = new ChainOrders[](params.anatomy.chainIdSet.size());

        ReserveRebalancingVars memory vars;
        vars.orderCount = weights.length;
        vars.lastIndex = vars.orderCount - 1;

        orders[0].orders = new OrderLib.Order[](vars.orderCount);

        for (; vars.i < params.chainIds.length; ++vars.i) {
            vars.chainsHash = keccak256(abi.encode(vars.chainsHash, params.chainIds[vars.i]));

            if (!params.anatomy.chainIdSet.contains(vars.i)) continue;

            bytes32 currenciesHash;
            Currency[] calldata currencies = params.currencies[vars.orderIndex];
            for (vars.j = 0; vars.j < currencies.length; ++vars.j) {
                currenciesHash = keccak256(abi.encode(currenciesHash, currencies[vars.j]));

                if (params.anatomy.currencyIdSets[vars.orderIndex].contains(vars.j)) {
                    uint96 orderSellAmount = vars.weightIndex == vars.lastIndex
                        ? reserveAmount - vars.utilized
                        : reserveAmount.mulDivDown(weights[vars.weightIndex], MAX_WEIGHT).safeCastTo96();
                    orders[0].orders[vars.weightIndex] = OrderLib.Order(
                        orderSellAmount,
                        OrderLib.OrderId(reserve, currencies[vars.j], currencies[vars.j], params.chainIds[vars.i])
                    );

                    unchecked {
                        if (vars.orderIndex != 0 && orderSellAmount != 0) {
                            ++orders[vars.orderIndex].incomingOrders;
                        }
                        vars.utilized += orderSellAmount;
                        ++vars.weightIndex;
                    }
                }
            }

            if (currenciesHash != currenciesHashOf[vars.i]) revert CurrenciesHashMismatch(params.chainIds[vars.i]);

            unchecked {
                ++vars.orderIndex;
            }
        }

        if (vars.chainsHash != chainsHash) revert ChainsHashMismatch();
    }

    /// @notice Checks if the total weight is equal to the maximum weight
    ///
    /// @dev This function reverts if the sum of the weights is not equal to MAX_WEIGHT
    ///
    /// @param weights The array of weights to check
    function checkTotalWeight(uint256[] calldata weights) internal pure {
        uint256 total;
        for (uint256 i; i < weights.length; ++i) {
            total += weights[i];
        }
        if (total != MAX_WEIGHT) revert TotalWeight();
    }

    /// @dev Creates the rebalancing orders by matching sell and buy deltas
    ///
    /// @param orders The array of chain orders to populate
    /// @param sellDeltas The stack of sell deltas
    /// @param buyDeltas The stack of buy deltas
    /// @param counters The array of order counters for each chain
    ///
    /// @return The updated sell and buy delta stacks after creating the orders
    function _createOrders(
        ChainOrders[] memory orders,
        StackLib.Node memory sellDeltas,
        StackLib.Node memory buyDeltas,
        uint256[] memory counters
    ) internal pure returns (StackLib.Node memory, StackLib.Node memory) {
        // while one of lists is not empty
        while (sellDeltas.notEmpty() && buyDeltas.notEmpty()) {
            // get first nodes from both lists
            StackLib.Data memory sell = sellDeltas.peek();
            StackLib.Data memory buy = buyDeltas.peek();

            uint256 fill = Math.min(sell.delta, buy.delta);
            sell.delta -= fill;
            buy.delta -= fill;

            uint256 sellAmount = Math.min(fill.convertToAssetsUp(sell.data), sell.availableAssets);
            sell.availableAssets -= sellAmount;

            orders[sell.orderIndex].orders[counters[sell.orderIndex]++] = OrderLib.Order(
                sellAmount.safeCastTo96(), OrderLib.OrderId(sell.currency, buy.currency, buy.currency, buy.data)
            );

            // increment "fence" counter
            if (buy.orderIndex != sell.orderIndex && sellAmount != 0) {
                ++orders[buy.orderIndex].incomingOrders;
            }

            // remove nodes with zero delta. Notice, both deltas can be set to zero.
            if (sell.delta == 0) {
                sellDeltas = sellDeltas.pop();
            }
            if (buy.delta == 0) {
                buyDeltas = buyDeltas.pop();
            }
        }

        return (sellDeltas, buyDeltas);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

type Currency is address;

using {eq as ==, neq as !=} for Currency global;

function eq(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function neq(Currency currency, Currency other) pure returns (bool) {
    return !eq(currency, other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
/// @author Modified from Uniswap (https://github.com/Uniswap/v4-core/blob/main/src/types/Currency.sol)
library CurrencyLib {
    using SafeERC20 for IERC20;
    using CurrencyLib for Currency;

    /// @dev Currency wrapper for native currency
    Currency public constant NATIVE = Currency.wrap(address(0));

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice Thrown when deposit amount exceeds current balance
    error AmountExceedsBalance();

    /// @notice Transfers currency
    ///
    /// @param currency Currency to transfer
    /// @param to Address of recipient
    /// @param amount Currency amount ot transfer
    function transfer(Currency currency, address to, uint256 amount) internal {
        if (amount == 0) return;
        // implementation from
        // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

        bool success;
        if (currency.isNative()) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, freeMemoryPointer, 68, 0, 32)
                    )
            }

            if (!success) revert ERC20TransferFailed();
        }
    }

    /// @notice Approves currency
    ///
    /// @param currency Currency to approve
    /// @param spender Address of spender
    /// @param amount Currency amount to approve
    function approve(Currency currency, address spender, uint256 amount) internal {
        if (isNative(currency)) return;
        IERC20(Currency.unwrap(currency)).forceApprove(spender, amount);
    }

    /// @notice Returns the balance of a given currency for a specific account
    ///
    /// @param currency The currency to check
    /// @param account The address of the account
    ///
    /// @return The balance of the specified currency for the given account
    function balanceOf(Currency currency, address account) internal view returns (uint256) {
        return currency.isNative() ? account.balance : IERC20(Currency.unwrap(currency)).balanceOf(account);
    }

    /// @notice Returns the balance of a given currency for this contract
    ///
    /// @param currency The currency to check
    ///
    /// @return The balance of the specified currency for this contract
    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        return currency.isNative() ? address(this).balance : IERC20(Currency.unwrap(currency)).balanceOf(address(this));
    }

    /// @notice Checks if the specified currency is the native currency
    ///
    /// @param currency The currency to check
    ///
    /// @return `true` if the specified currency is the native currency, `false` otherwise
    function isNative(Currency currency) internal pure returns (bool) {
        return currency == NATIVE;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Currency, CurrencyLib} from "./CurrencyLib.sol";

interface IDAIPermit {
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

/// @title DepositCallbackLib
/// @notice Library for handling deposit callbacks
library DepositCallbackLib {
    using SafeERC20 for IERC20;
    using CurrencyLib for Currency;

    /// @dev Struct representing a trade
    struct Trade {
        address target;
        address allowanceTarget;
        bytes data;
    }

    /// @notice Thrown when an invalid permit data is provided
    error InvalidPermit();

    /// @notice Thrown when a permit operation fails
    error PermitFailed();

    /// @notice Thrown when a trade operation fails
    error TradeFailed();

    /// @notice Thrown when an invalid trade data is provided
    /// @dev Deposit callback must output the reserve currency,
    ///      if input currency is already the reserve currency callback should not contain trade data
    error InvalidTrade();

    /// @notice Performs a deposit operation based on the provided callback data
    ///
    /// @dev Decodes the callback data and handles permit and trade operations if applicable
    ///
    /// @param reserve The reserve currency for the deposit
    /// @param cbData The encoded callback data containing currency, amount, sender, permitData, and tradeData
    function deposit(Currency reserve, bytes calldata cbData) internal {
        (Currency currency, uint256 amount, address sender, bytes memory permitData, bytes memory tradeData) =
            abi.decode(cbData, (Currency, uint256, address, bytes, bytes));

        if (permitData.length != 0) {
            // Extracting the first 4 bytes for the selector
            bytes4 selector;

            /// @solidity memory-safe-assembly
            assembly {
                // Add 32 bytes for the length field in bytes type
                selector := mload(add(permitData, 32))
            }

            if (!(selector == IERC20Permit.permit.selector || selector == IDAIPermit.permit.selector)) {
                revert InvalidPermit();
            }

            (bool success, bytes memory returnData) = Currency.unwrap(currency).call(permitData);

            if (!success) {
                if (returnData.length == 0) revert PermitFailed();

                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        }

        if (tradeData.length != 0) {
            if (currency == reserve) revert InvalidTrade();

            Trade memory trade = abi.decode(tradeData, (Trade));

            uint256 reserveBefore = reserve.balanceOfSelf();

            {
                bool isNative = currency.isNative();
                if (!isNative) {
                    IERC20(Currency.unwrap(currency)).safeTransferFrom(sender, address(this), amount);
                }

                currency.approve(trade.allowanceTarget, amount);

                (bool success, bytes memory returnData) = trade.target.call{value: isNative ? amount : 0}(trade.data);

                if (!success) {
                    if (returnData.length == 0) revert TradeFailed();

                    assembly {
                        revert(add(returnData, 32), mload(returnData))
                    }
                }

                currency.approve(trade.allowanceTarget, 0);
            }

            reserve.transfer(msg.sender, reserve.balanceOfSelf() - reserveBefore);
        } else {
            IERC20(Currency.unwrap(reserve)).safeTransferFrom(sender, msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ICurrencyMetadata} from "./interfaces/ICurrencyMetadata.sol";
import {IOmnichainMessenger} from "./interfaces/IOmnichainMessenger.sol";
import {IOrderBook} from "./interfaces/IOrderBook.sol";
import {IPhutureOnConsumeCallback} from "./interfaces/IPhutureOnConsumeCallback.sol";
import {IStargateReceiver} from "./interfaces/stargate/IStargateReceiver.sol";
import {IStargateRouter} from "./interfaces/stargate/IStargateRouter.sol";
import {IStargateFactory} from "./interfaces/stargate/IStargateFactory.sol";
import {IStargatePool} from "./interfaces/stargate/IStargatePool.sol";
import {IEscrowDeployer} from "./escrow/interfaces/IEscrowDeployer.sol";

import {IVault} from "./interfaces/IVault.sol";

import {Currency, CurrencyLib} from "./libraries/CurrencyLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OrderLib} from "./libraries/OrderLib.sol";
import {SSTORE2} from "sstore2/SSTORE2.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {BlockingApp} from "./BlockingApp.sol";

/// @title OmnichainMessenger
/// @notice Base contract for cross-chain messaging and order distribution
abstract contract OmnichainMessenger is
    BlockingApp,
    IStargateReceiver,
    IOmnichainMessenger,
    IPhutureOnConsumeCallback
{
    using CurrencyLib for Currency;
    using FixedPointMathLib for *;
    using SafeCastLib for *;

    /// @dev Struct representing the native currency information
    struct NativeInfo {
        string name;
        string symbol;
        uint8 decimals;
    }

    /// @dev Struct for holding variables used in the `_distributeOrders` function
    struct DistrubuteOrdersVars {
        IStargateFactory factory;
        uint256 lzOptionsIndex;
        uint256 length;
        bytes path;
    }

    /// @dev update currencies hash on home chain
    uint8 internal constant REGISTER_CURRENCY = 0;
    /// @dev if reserve changed we only send redeemedK, recipient and owner to each remote chain
    uint8 internal constant TRANSFER_SNAPSHOT = 1;
    /// @dev once snapshot is transferred to user trading module,
    /// trade batches are sent to each remote chain to swap tokens and send them to home
    uint8 internal constant TRADE_SNAPSHOT = 2;
    /// @dev in the best-case scenario, we send both bodies in one message
    uint8 internal constant TRANSFER_AND_TRADE_SNAPSHOT = 3;
    /// @dev do vault withdrawals, place local orders & increment incoming orders counter by N
    uint8 internal constant START_REBALANCING = 4;
    /// @dev increment incoming orders counter by N
    uint8 internal constant START_RESERVE_REBALANCING = 5;
    /// @dev append builder with remote chain state
    uint8 internal constant FINISH_REBALANCING = 6;
    /// @dev remove dust orders which can't be sent via Stargate
    uint8 internal constant REMOVE_DUST_ORDERS = 7;

    /// @dev Native currency information
    NativeInfo internal nativeInfo;

    /// @dev Address of the Stargate composer contract
    address internal immutable stargateComposer;

    /// @dev Address of the sgETH contract
    address internal immutable sgETH;

    /// @dev Pointer to the bridging info data stored using SSTORE2
    address internal bridgingInfoDataPointer;

    /// @dev Home chain endpoint ID
    uint16 internal immutable homeEid;

    /// @dev Address of the OrderBook contract
    IOrderBook internal orderBook;

    /// @dev Address of the EscrowDeployer contract
    IEscrowDeployer internal escrowDeployer;

    /// @dev Mapping of chain IDs to order hashes
    mapping(uint256 chainid => bytes32 orderHash) internal ordersHashOf;

    /// @notice Event emitted when outgoing orders are distributed
    /// @param orders The bought orders
    /// @param totalBought The total amount bought
    event OutgoingOrders(IOrderBook.BoughtOrder[] orders, uint256 totalBought);

    /// @notice Event emitted when the orders hash for a chain is cleared
    /// @param chainId The ID of the chain
    event OrdersHashClear(uint256 chainId);

    /// @notice Thrown when bridging currency is not found for a destination chain
    /// @param dstChainId The destination chain ID
    error BridgingCurrencyNotFound(uint256 dstChainId);

    /// @notice Thrown when the caller is not allowed to perform the action
    error Forbidden();

    /// @notice Thrown when a query fails
    error QueryFailed();

    /// @notice Thrown when the order hash doesn't match the expected value
    error OrderHashMismatch();

    /// @notice Thrown when trying to set EscrowDeployer with invalid messenger
    error Invalid();

    /// @notice Thrown when trying to set EscrowDeployer after it has been set
    error Set();

    constructor(
        address owner,
        address _stargateComposer,
        address payable _endpoint,
        uint16 _homeEid,
        address _sgETH,
        NativeInfo memory _nativeInfo
    ) BlockingApp(owner, _endpoint) {
        stargateComposer = _stargateComposer;
        homeEid = _homeEid;
        sgETH = _sgETH;

        nativeInfo = _nativeInfo;
    }

    /// @notice Callback function for handling consume currency from Vault
    /// @param data The data passed from the Vault
    function phutureOnConsumeCallbackV1(bytes calldata data) external {}

    /// @notice Sets the address of the EscrowDeployer contract
    /// @param _escrowDeployer The address of the EscrowDeployer contract
    function setEscrowDeployer(address _escrowDeployer) external onlyOwner {
        // prevents setting new EscrowDeployer to protect users' access to escrow
        if (address(escrowDeployer) != address(0)) revert Set();
        if (IEscrowDeployer(_escrowDeployer).messenger() != address(this)) revert Invalid();

        escrowDeployer = IEscrowDeployer(_escrowDeployer);
    }

    /// @notice Sets the address of the OrderBook contract
    /// @param _orderBook The address of the OrderBook contract
    function setOrderBook(address _orderBook) external onlyOwner {
        orderBook = IOrderBook(_orderBook);
    }

    /// @notice Sets the bridging info data
    /// @param _infos The array of BridgingInfo structs
    function setBridgingInfo(BridgingInfo[] calldata _infos) external onlyOwner {
        bridgingInfoDataPointer = SSTORE2.write(abi.encode(_infos));
    }

    /// @notice Withdraws the specified amount of currency to the given address
    ///
    /// @param currency The currency to withdraw
    /// @param to The recipient address
    /// @param amount The amount to withdraw
    function withdrawCurrency(Currency currency, address to, uint256 amount) external onlyOwner {
        currency.transfer(to, amount);
    }

    /// @notice Receives tokens from Stargate
    ///
    /// @param srcEid The source endpoint ID
    /// @param srcAddress The source address
    /// @param token The address of the token received
    /// @param amountLD The amount received in local decimals
    /// @param payload Additional data passed with the transfer
    function sgReceive(
        uint16 srcEid,
        bytes calldata srcAddress,
        uint256,
        address token,
        uint256 amountLD,
        bytes calldata payload
    ) external {
        if (!(msg.sender == stargateComposer || msg.sender == allowedCaller)) revert Forbidden();
        if (keccak256(abi.encodePacked(srcAddress, address(this))) != keccak256(trustedRemotes[srcEid])) return;

        Currency currency = token == sgETH ? CurrencyLib.NATIVE : Currency.wrap(token);

        (bytes32 ordersHash, uint256 chainId) = abi.decode(payload, (bytes32, uint256));
        ordersHashOf[chainId] = keccak256(abi.encode(ordersHash, currency, amountLD));

        currency.transfer(address(orderBook), amountLD);
    }

    /// @notice Pushes the incoming orders to the OrderBook contract
    ///
    /// @param srcChainId The source chain ID
    /// @param boughtOrders The array of bought orders
    /// @param boughtOrdersTotalAmount The total amount of bought orders
    /// @param currency The currency of the bought orders
    /// @param receivedAmount The amount received from Stargate
    function pushIncomingOrders(
        uint256 srcChainId,
        IOrderBook.BoughtOrder[] calldata boughtOrders,
        uint256 boughtOrdersTotalAmount,
        Currency currency,
        uint256 receivedAmount
    ) external {
        if (
            keccak256(
                abi.encode(keccak256(abi.encode(boughtOrders, boughtOrdersTotalAmount)), currency, receivedAmount)
            ) != ordersHashOf[srcChainId]
        ) revert OrderHashMismatch();

        delete ordersHashOf[srcChainId];
        emit OrdersHashClear(srcChainId);

        OrderLib.Order[] memory orders = new OrderLib.Order[](boughtOrders.length);
        uint256 lastIndex = boughtOrders.length - 1;
        uint256 utilized;
        for (uint256 i; i <= lastIndex; i++) {
            uint96 sellAmount = i == lastIndex
                ? (receivedAmount - utilized).safeCastTo96()
                : boughtOrders[i].amount.mulDivDown(receivedAmount, boughtOrdersTotalAmount).safeCastTo96();

            orders[i] = OrderLib.Order({
                sellAmount: sellAmount,
                idParams: OrderLib.OrderId({
                    sellCurrency: currency,
                    localBuyCurrency: boughtOrders[i].buyCurrency,
                    finalDestinationBuyCurrency: boughtOrders[i].buyCurrency,
                    finalDestinationChainId: block.chainid
                })
            });

            unchecked {
                utilized += sellAmount;
            }
        }

        orderBook.receiveIncomingOrders(orders, currency, receivedAmount);
    }

    /// @dev Distributes the pending orders to remote chains using Stargate
    /// @param pendingOrders The array of pending orders
    /// @param sgParams The array of Stargate parameters
    /// @param lzParams The LayerZero parameters
    function _distributeOrders(
        IOrderBook.PendingOrder[] memory pendingOrders,
        SgParams[] calldata sgParams,
        LzParams calldata lzParams
    ) internal {
        DistrubuteOrdersVars memory vars;
        vars.factory = IStargateFactory(IStargateRouter(stargateComposer).factory());

        vars.length = pendingOrders.length;
        for (uint256 i; i < vars.length; ++i) {
            IOrderBook.PendingOrder memory pendingOrder = pendingOrders[i];

            uint16 dstEid = eIds[pendingOrder.chainId];

            vars.path = _getPathOrRevert(dstEid);

            PoolIds memory sgPoolIds = poolIds[pendingOrder.chainId];
            if (pendingOrder.totalBought >= IStargatePool(vars.factory.getPool(sgPoolIds.src)).convertRate()) {
                SgParams calldata sgParam = sgParams[i - vars.lzOptionsIndex];

                emit OutgoingOrders(pendingOrder.orders, pendingOrder.totalBought);
                bytes memory payload =
                    abi.encode(keccak256(abi.encode(pendingOrder.orders, pendingOrder.totalBought)), block.chainid);

                bytes memory to = bytes.concat(bytes20(vars.path));
                (uint256 sgMessageFee,) =
                    IStargateRouter(stargateComposer).quoteLayerZeroFee(dstEid, 1, to, payload, sgParam.lzTxObj);

                if (pendingOrder.currency.isNative()) sgMessageFee += pendingOrder.totalBought;

                pendingOrder.currency.approve(stargateComposer, pendingOrder.totalBought);

                IStargateRouter(stargateComposer).swap{value: sgMessageFee}(
                    dstEid,
                    sgPoolIds.src,
                    sgPoolIds.dst,
                    payable(address(this)),
                    pendingOrder.totalBought,
                    sgParam.minAmountLD,
                    sgParam.lzTxObj,
                    to,
                    payload
                );

                pendingOrder.currency.approve(stargateComposer, 0);
            } else {
                _lzSend(
                    dstEid,
                    vars.path,
                    abi.encode(REMOVE_DUST_ORDERS, pendingOrder.orders.length),
                    payable(address(this)),
                    lzParams.zroPaymentAddress,
                    lzParams.options[vars.lzOptionsIndex++]
                );
            }
        }
    }

    /// @dev Injects the local buy currency into the orders based on the bridging info
    ///
    /// @param orders The array of orders
    function _injectLocalBuyCurrency(OrderLib.Order[] memory orders) internal view {
        BridgingInfo[] memory bridgingInfo = abi.decode(SSTORE2.read(bridgingInfoDataPointer), (BridgingInfo[]));
        for (uint256 i; i < orders.length; ++i) {
            uint256 finalDestinationChainId = orders[i].idParams.finalDestinationChainId;
            if (finalDestinationChainId != block.chainid) {
                bool bridgingCurrencyFound;
                for (uint256 j; j < bridgingInfo.length; ++j) {
                    if (finalDestinationChainId == bridgingInfo[j].finalDstChainId) {
                        bridgingCurrencyFound = true;
                        orders[i].idParams.localBuyCurrency = bridgingInfo[j].localCurrency;
                        break;
                    }
                }

                if (!bridgingCurrencyFound) revert BridgingCurrencyNotFound(finalDestinationChainId);
            }
        }
    }

    /// @dev Fills the metadata for registered currencies
    ///
    /// @param info The RegisterCurrenciesResult from the Vault contract
    ///
    /// @return result The filled RegisteredMetadata struct
    function _fillCurrenciesMetadata(IVault.RegisterCurrenciesResult calldata info)
        internal
        view
        returns (ICurrencyMetadata.RegisteredMetadata memory result)
    {
        result.currenciesHash = info.currenciesHash;
        result.chainId = block.chainid;
        result.metadata = new ICurrencyMetadata.CurrencyMetadata[](info.currencies.length);
        for (uint256 i; i < info.currencies.length; ++i) {
            Currency currency = info.currencies[i];
            if (currency.isNative()) {
                NativeInfo memory _info = nativeInfo;
                result.metadata[i] =
                    ICurrencyMetadata.CurrencyMetadata(_info.name, _info.symbol, _info.decimals, currency);
            } else {
                result.metadata[i] = ICurrencyMetadata.CurrencyMetadata(
                    _queryStringOrBytes32(Currency.unwrap(currency), IERC20Metadata.name.selector),
                    _queryStringOrBytes32(Currency.unwrap(currency), IERC20Metadata.symbol.selector),
                    IERC20Metadata(Currency.unwrap(currency)).decimals(),
                    currency
                );
            }
        }
    }

    /// @dev Queries a string or bytes32 value from a target contract
    ///
    /// @param target The address of the target contract
    /// @param selector The function selector to call
    ///
    /// @return s The queried string value
    function _queryStringOrBytes32(address target, bytes4 selector) internal view returns (string memory s) {
        (bool success, bytes memory returndata) = target.staticcall(abi.encodeWithSelector(selector));
        if (!success) revert QueryFailed();

        if (returndata.length != 32) return abi.decode(returndata, (string));

        s = string(returndata);

        // Find last non-zero byte
        uint256 length = 32;
        for (; length != 0; length--) {
            if (returndata[length - 1] != 0) break;
        }

        // Shorten length of string
        assembly {
            mstore(s, length)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

interface IPhutureOnDepositCallback {
    function phutureOnDepositCallbackV1(Currency reserve, bytes calldata) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IOrderBook} from "./IOrderBook.sol";
import {IVault} from "./IVault.sol";
import {IStargateRouter} from "./stargate/IStargateRouter.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

interface IOmnichainMessenger {
    struct BridgingInfo {
        uint256 finalDstChainId;
        Currency localCurrency;
    }

    struct HashedResult {
        uint256 chainId;
        bytes32 hash;
    }

    struct LzParams {
        bytes[] options;
        address zroPaymentAddress;
    }

    struct SgParams {
        IStargateRouter.lzTxObj lzTxObj;
        uint256 minAmountLD;
    }

    function withdrawCurrency(Currency currency, address to, uint256 amount) external;

    function setOrderBook(address orderBook) external;
    function setEscrowDeployer(address escrowDeployer) external;

    function setBridgingInfo(BridgingInfo[] calldata _infos) external;

    function pushIncomingOrders(
        uint256 srcChainId,
        IOrderBook.BoughtOrder[] memory boughtOrders,
        uint256 boughtOrdersTotalAmount,
        Currency currency,
        uint256 receivedAmount
    ) external;

    function finishVaultRebalancing(
        IOrderBook.FinishOrderExecutionParams calldata orderBookParams,
        IVault.EndRebalancingParams calldata params,
        SgParams[] calldata sgParams,
        LzParams calldata lzParams,
        address payable refundAddress
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

type u16x15 is uint256;

using {length, at} for u16x15 global;

function at(u16x15 packed, uint256 index) pure returns (uint16 value) {
    assembly ("memory-safe") {
        value := shr(mul(index, 16), packed)
    }
}

function length(u16x15 packed) pure returns (uint256 value) {
    assembly ("memory-safe") {
        value := shr(240, packed)
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

type a160u96 is uint256;

using {addr, unpack, unpackRaw, currency, value, eq as ==, neq as !=} for a160u96 global;

error AddressMismatch(address, address);

function neq(a160u96 a, a160u96 b) pure returns (bool) {
    return !eq(a, b);
}

function eq(a160u96 a, a160u96 b) pure returns (bool) {
    return a160u96.unwrap(a) == a160u96.unwrap(b);
}

function currency(a160u96 packed) pure returns (Currency) {
    return Currency.wrap(addr(packed));
}

function addr(a160u96 packed) pure returns (address) {
    return address(uint160(a160u96.unwrap(packed)));
}

function value(a160u96 packed) pure returns (uint96) {
    return uint96(a160u96.unwrap(packed) >> 160);
}

function unpack(a160u96 packed) pure returns (Currency _curr, uint96 _value) {
    uint256 raw = a160u96.unwrap(packed);
    _curr = Currency.wrap(address(uint160(raw)));
    _value = uint96(raw >> 160);
}

function unpackRaw(a160u96 packed) pure returns (address _addr, uint96 _value) {
    uint256 raw = a160u96.unwrap(packed);
    _addr = address(uint160(raw));
    _value = uint96(raw >> 160);
}

library A160U96Factory {
    function create(address _addr, uint96 _value) internal pure returns (a160u96) {
        return a160u96.wrap((uint256(_value) << 160) | uint256(uint160(_addr)));
    }

    function create(Currency _currency, uint96 _value) internal pure returns (a160u96) {
        return create(Currency.unwrap(_currency), _value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

/// @title OrderLib
/// @notice Library for managing orders
library OrderLib {
    struct OrderId {
        // Sell currency of order
        Currency sellCurrency;
        // Local buy currency of order
        Currency localBuyCurrency;
        // Final destination buy currency of order
        Currency finalDestinationBuyCurrency;
        // Final destination chainId of order
        uint256 finalDestinationChainId;
    }

    struct Order {
        // Sell amount of order
        uint96 sellAmount;
        // Id params of order
        OrderId idParams;
    }

    struct OrderRegistry {
        // Sell amount of given order
        mapping(bytes32 => uint96) orderOf;
        // Hash of registry state
        bytes32 ordersHash;
    }

    /// @notice Emitted when a new order is created
    event NewOrder(
        uint256 sellAmount,
        Currency indexed sellCurrency,
        Currency localBuyCurrency,
        Currency indexed finalDestinationBuyCurrency,
        uint256 finalDestinationChainId
    );

    /// @notice Thrown when there's a mismatch in order hashes
    error OrderHashMismatch();

    /// @notice Thrown when an order is not filled
    /// @param id The id of the order that was not filled
    error OrderNotFilled(bytes32 id);

    /// @notice Sets multiple orders in the registry
    ///
    /// @param self The order registry where orders are stored
    /// @param orders An array of orders to set in the registry
    function set(OrderRegistry storage self, Order[] calldata orders) internal {
        bytes32 newHash = self.ordersHash;
        for (uint256 i; i < orders.length; ++i) {
            if (orders[i].sellAmount == 0) continue;

            OrderId calldata params = orders[i].idParams;
            // don't need to create order for the same currency within a single chain, as it's already in the final destination
            if (params.sellCurrency != params.localBuyCurrency || params.finalDestinationChainId != block.chainid) {
                bytes32 idKey = id(params);
                newHash = keccak256(abi.encode(newHash, idKey));
                self.orderOf[idKey] += orders[i].sellAmount;

                emit NewOrder(
                    orders[i].sellAmount,
                    params.sellCurrency,
                    params.localBuyCurrency,
                    params.finalDestinationBuyCurrency,
                    params.finalDestinationChainId
                );
            }
        }
        self.ordersHash = newHash;
    }

    /// @notice Fills a specific order from the registry
    ///
    /// @param self The order registry
    /// @param orderId The id params of the order to fill
    /// @param sell The sell amount of the order
    function fill(OrderRegistry storage self, OrderId calldata orderId, uint96 sell) internal {
        self.orderOf[id(orderId)] -= sell;
    }

    /// @notice Resets the orders in the registry
    ///
    /// @param self The order registry to reset
    ///
    /// @param orderIds An array of order id parameters to reset
    function reset(OrderRegistry storage self, OrderId[] calldata orderIds) internal {
        bytes32 ordersHash;
        for (uint256 i; i < orderIds.length; ++i) {
            bytes32 idKey = id(orderIds[i]);
            ordersHash = keccak256(abi.encode(ordersHash, idKey));

            if (self.orderOf[idKey] != 0) revert OrderNotFilled(idKey);
        }

        if (ordersHash != self.ordersHash) revert OrderHashMismatch();

        self.ordersHash = bytes32(0);
    }

    /// @notice Retrieves the sell amount of a specific order
    /// @param self The order registry
    ///
    /// @param orderId The id parameters of the order to retrieve
    ///
    /// @return The sell amount of the specified order
    function get(OrderRegistry storage self, OrderId calldata orderId) internal view returns (uint96) {
        return self.orderOf[id(orderId)];
    }

    /// @dev Generates a unique id for an order based on its parameters
    ///
    /// @param self The order id parameters
    ///
    /// @return A unique bytes32 id for the order
    function id(OrderId calldata self) internal pure returns (bytes32) {
        return keccak256(abi.encode(self));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {a160u96} from "../../utils/a160u96.sol";
import {Currency} from "../../libraries/CurrencyLib.sol";

/// @title IEscrow
/// @dev Interface for the Escrow contract
interface IEscrow {
    struct TradeParams {
        a160u96 target;
        address allowanceTarget;
        Currency currency;
        bytes data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title PriceLib
/// @notice A library for handling fixed-point arithmetic for prices
library PriceLib {
    using FixedPointMathLib for uint256;

    /// @dev 2**128
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
    uint16 internal constant PRICE_ORACLE_DECIMALS = 18;
    uint256 internal constant DECIMALS_MULTIPLIER = 10 ** PRICE_ORACLE_DECIMALS;

    /// @notice Converts (down) an amount in base units to an amount in asset units based on a fixed-price value
    /// @param base The amount to convert in base units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in asset units
    function convertToAssetsDown(uint256 base, uint256 price) internal pure returns (uint256) {
        return base.mulDivDown(price, Q128);
    }

    /// @notice Converts (up) an amount in base units to an amount in asset units based on a fixed-price value
    /// @param base The amount to convert in base units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in asset units
    function convertToAssetsUp(uint256 base, uint256 price) internal pure returns (uint256) {
        return base.mulDivUp(price, Q128);
    }

    /// @notice Converts (down) an amount in asset units to an amount in base units based on a fixed-price value
    /// @param assets The amount to convert in asset units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in base units
    function convertToBaseDown(uint256 assets, uint256 price) internal pure returns (uint256) {
        return assets.mulDivDown(Q128, price);
    }

    /// @notice Converts (up) an amount in asset units to an amount in base units based on a fixed-price value
    /// @param assets The amount to convert in asset units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in base units
    function convertToBaseUp(uint256 assets, uint256 price) internal pure returns (uint256) {
        return assets.mulDivUp(Q128, price);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

/// @title StackLib
/// @notice A library for managing a stack data
library StackLib {
    /// @dev Represents the data held in each stack node
    struct Data {
        // Index of order
        uint256 orderIndex;
        // Currency of order
        Currency currency;
        // Amount of order
        uint256 delta;
        // `price` for sell, `chainId` for buy
        uint256 data;
        // Available asset for sell data, 0 for buy data
        uint256 availableAssets;
    }

    /// @dev Represents a node in the stack
    struct Node {
        // Pointer to the next node
        uint256 next;
        // Value of the node
        Data value;
    }

    /// @notice Pushes a new sell order onto the stack
    ///
    /// @param head The current head of the stack
    /// @param delta The delta value of the order
    /// @param availableAssets The number of assets available for selling
    /// @param orderIndex The index of the order
    /// @param currency The currency used in the order
    /// @param price The price of the assets in the order
    ///
    /// @return newNode The new node created with the given data
    function push(
        Node memory head,
        uint256 delta,
        uint256 availableAssets,
        uint256 orderIndex,
        Currency currency,
        uint256 price
    ) internal pure returns (Node memory newNode) {
        newNode.value = Data(orderIndex, currency, delta, price, availableAssets);

        assembly {
            // Store the address of the current head in the new node's 'next'
            mstore(newNode, head)
        }
    }

    /// @notice Pushes a new buy order onto the stack
    ///
    /// @param head The current head of the stack
    /// @param delta The delta value of the order
    /// @param orderIndex The index of the order
    /// @param currency The currency used in the order
    /// @param chainId The chain ID associated with the buy order
    ///
    /// @return newNode The new node created with the given data
    function push(Node memory head, uint256 delta, uint256 orderIndex, Currency currency, uint256 chainId)
        internal
        pure
        returns (Node memory newNode)
    {
        newNode.value = Data(orderIndex, currency, delta, chainId, 0);

        assembly {
            // Store the address of the current head in the new node's 'next'
            mstore(newNode, head)
        }
    }

    /// @notice Pops the top value from the stack
    ///
    /// @param head The current head of the stack
    ///
    /// @return nextNode The next node in the stack after popping
    function pop(Node memory head) internal pure returns (Node memory nextNode) {
        assembly {
            // Load the address of the next node (which head points to)
            nextNode := mload(head)
        }
    }

    /// @notice Checks if the stack is not empty
    ///
    /// @param head The head of the stack to check
    ///
    /// @return `true` if the stack is not empty, `false` otherwise
    function notEmpty(Node memory head) internal pure returns (bool) {
        return head.next != 0 || head.value.delta != 0;
    }

    /// @notice Retrieves the value of the top node of the stack
    ///
    /// @param head The head of the stack
    ///
    /// @return The data value of the top node of the stack
    function peek(Node memory head) internal pure returns (Data memory) {
        return head.value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IPhutureOnConsumeCallback {
    function phutureOnConsumeCallbackV1(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargateReceiver {
    function sgReceive(
        uint16 _eid,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall; // extra gas, if calling smart contract,
        uint256 dstNativeAmount; // amount of dust dropped in destination wallet
        bytes dstNativeAddr; // destination wallet for dust
    }

    function swap(
        uint16 _dstEid,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstEid,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargateFactory {
    function getPool(uint256 poolId) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargatePool {
    function convertRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/// @title IEscrowDeployer
/// @dev Interface for the EscrowDeployer contract, which manages the deployment and tracking of Escrow contracts
interface IEscrowDeployer {
    /// @notice Deploys a new Escrow contract for the specified user
    ///
    /// @param user The address of the user for whom the Escrow contract is deployed
    ///
    /// @return escrow The address of the newly deployed Escrow contract
    function deploy(address user) external returns (address escrow);

    /// @notice Retrieves the address and deployment status of the Escrow contract associated with the given owner
    ///
    /// @param owner The address of the owner for whom to retrieve the Escrow contract information
    ///
    /// @return escrow The address of the Escrow contract associated with the owner
    /// @return deployed A boolean indicating whether the Escrow contract has been deployed for the owner
    function escrowOf(address owner) external view returns (address escrow, bool deployed);

    /// @notice Retrieves the address of the Messenger contract associated with the EscrowDeployer
    ///
    /// @return The address of the Messenger contract
    function messenger() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IBlockingApp} from "./interfaces/IBlockingApp.sol";
import {ILayerZeroEndpoint} from "layerzero/interfaces/ILayerZeroEndpoint.sol";

import {Owned} from "solmate/auth/Owned.sol";

/// @title BlockingApp
/// @notice Abstract contract for a LayerZero blocking queue UA
abstract contract BlockingApp is IBlockingApp, Owned {
    /// @notice The LayerZero Endpoint contract
    ILayerZeroEndpoint public immutable lzEndpoint;

    /// @notice Address whos allowed to call `lzReceive` method
    /// @dev this slot is used for stateOverrides during gas estimation
    address internal allowedCaller;

    /// @notice Mapping of remote chainIDs to their respective LayerZero Endpoint IDs
    mapping(uint256 => uint16) public eIds;

    /// @notice Mapping of LayerZero Endpoint IDs to their trusted remote paths
    mapping(uint16 => bytes) public trustedRemotes;

    /// @notice Mapping of remote chainIDs to their respective Stargate Pool IDs
    mapping(uint256 => PoolIds) public poolIds;

    /// @notice Mapping of LayerZero Endpoint IDs to the minimum gas amount required for the chain
    mapping(uint16 => uint256) public minGasAmountForChain;

    /// @notice Event emitted when a trusted remote is set
    ///
    /// @param remoteEid LayerZero Endpoint ID on the remote chain
    /// @param path Trusted path to the remote chain (abi-encoded remote address and local address)
    /// @param poolIds The Stargate Oool IDs associated with the trusted remote
    event TrustedRemoteSet(uint16 remoteEid, bytes path, PoolIds poolIds);

    /// @notice Thrown when the caller is not the LayerZero endpoint
    error OnlyEndpoint();

    /// @notice Thrown if ZRO payments are not supported
    error ZRONotSupported();

    /// @notice Thrown when a trusted remote path is not found for the given LayerZero Endpoint ID
    /// @param eid LayerZero Endpoint ID for which the path was not found
    error PathNotFound(uint16 eid);

    constructor(address owner, address _endpoint) Owned(owner) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    receive() external payable {}

    /// @notice Sets the configuration for specified LayerZero Endpoint ID
    ///
    /// @param version Configuration version
    /// @param eid LayerZero Endpoint ID
    /// @param configType Configuration type
    /// @param config Configuration data
    function setConfig(uint16 version, uint16 eid, uint256 configType, bytes calldata config)
        external
        override
        onlyOwner
    {
        lzEndpoint.setConfig(version, eid, configType, config);
    }

    /// @notice Sets the send version for the LayerZero endpoint
    ///
    /// @param version The send version to set
    function setSendVersion(uint16 version) external override onlyOwner {
        lzEndpoint.setSendVersion(version);
    }

    /// @notice Sets the receive version for the LayerZero endpoint
    ///
    /// @param version The receive version to set
    function setReceiveVersion(uint16 version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(version);
    }

    /// @notice Forces the resumption of message receiving for the specified source LayerZero Endpoint and address
    ///
    /// @param srcEid The source LayerZero Endpoint ID
    /// @param srcAddress The source address
    function forceResumeReceive(uint16 srcEid, bytes calldata srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(srcEid, srcAddress);
    }

    /// @notice Sets the trusted remote for the specified remote chain ID
    ///
    /// @param remoteChainId The remote chain ID
    /// @param remoteEid The remote LayerZero Endpoint ID
    /// @param minGasAmount The minimum gas amount required for the remote chain
    /// @param path The trusted remote path (abi.encodePacked(remoteAddress, localAddress))
    /// @param _poolIds The pool IDs associated with the trusted remote
    function setTrustedRemote(
        uint256 remoteChainId,
        uint16 remoteEid,
        uint256 minGasAmount,
        bytes calldata path,
        PoolIds calldata _poolIds
    ) external onlyOwner {
        eIds[remoteChainId] = remoteEid;
        poolIds[remoteChainId] = _poolIds;
        trustedRemotes[remoteEid] = path;
        minGasAmountForChain[remoteEid] = minGasAmount;
        emit TrustedRemoteSet(remoteEid, path, _poolIds);
    }

    /// @notice Receives messages from the LayerZero
    ///
    /// @param srcEid The source LayerZero Endpoint ID
    /// @param srcAddress The source address
    /// @param message The received message
    function lzReceive(uint16 srcEid, bytes calldata srcAddress, uint64, bytes calldata message) external override {
        if (!(msg.sender == address(lzEndpoint) || msg.sender == allowedCaller)) revert OnlyEndpoint();
        if (keccak256(srcAddress) != keccak256(trustedRemotes[srcEid])) return;

        _lzReceive(message);
    }

    /// @notice Retrieves the configuration for the specified LayerZero Endpoint ID and configuration type
    ///
    /// @param version The configuration version
    /// @param eid The LayerZero Endpoint ID
    /// @param configType The configuration type
    ///
    /// @return The configuration data
    function getConfig(uint16 version, uint16 eid, address, uint256 configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(version, eid, address(this), configType);
    }

    /// @dev Sends a message through the LayerZero endpoint
    ///
    /// @param dstEid The destination LayerZero Endpoint ID
    /// @param path The trusted remote path
    /// @param message The message to send
    /// @param refundAddress The address to receive refunds
    /// @param zroPaymentAddress The address for ZRO payments
    /// @param options Additional options for the message
    function _lzSend(
        uint16 dstEid,
        bytes memory path,
        bytes memory message,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory options
    ) internal {
        if (zroPaymentAddress != address(0)) revert ZRONotSupported();

        // solhint-disable-next-line check-send-result
        lzEndpoint.send{value: address(this).balance}(dstEid, path, message, refundAddress, address(0), options);
    }

    /// @dev Processes messages from the LayerZero endpoint
    ///
    /// @param message The received message
    function _lzReceive(bytes calldata message) internal virtual;

    /// @dev Retrieves the trusted remote path for the specified LayerZero Endpoint ID,
    ///      or reverts if not found
    ///
    /// @param eid The LayerZero Endpoint ID
    ///
    /// @return path The trusted remote path
    function _getPathOrRevert(uint16 eid) internal view returns (bytes memory path) {
        path = trustedRemotes[eid];
        if (path.length == 0) revert PathNotFound(eid);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ILayerZeroReceiver} from "layerzero/interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "layerzero/interfaces/ILayerZeroUserApplicationConfig.sol";

interface IBlockingApp is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    struct PoolIds {
        uint128 src;
        uint128 dst;
    }

    function setConfig(uint16 version, uint16 eid, uint256 configType, bytes calldata config) external;

    function setSendVersion(uint16 version) external;

    function setReceiveVersion(uint16 version) external;

    function setTrustedRemote(
        uint256 remoteChainId,
        uint16 remoteEid,
        uint256 minGasAmount,
        bytes calldata path,
        PoolIds calldata poolIds
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}