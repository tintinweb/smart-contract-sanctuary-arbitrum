// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PerpdexExchange } from "../PerpdexExchange.sol";

contract DebugPerpdexExchange is PerpdexExchange {
    uint256 private constant _RINKEBY_CHAIN_ID = 4;
    uint256 private constant _MUMBAI_CHAIN_ID = 80001;
    uint256 private constant _SHIBUYA_CHAIN_ID = 81;
    // https://v2-docs.zksync.io/dev/zksync-v2/temp-limits.html#temporarily-simulated-by-constant-values
    uint256 private constant _ZKSYNC2_TESTNET_CHAIN_ID = 0;
    uint256 private constant _ARBITRUM_RINKEBY_CHAIN_ID = 421611;
    uint256 private constant _OPTIMISM_KOVAN_CHAIN_ID = 69;
    uint256 private constant _HARDHAT_CHAIN_ID = 31337;

    constructor(address settlementTokenArg) PerpdexExchange(msg.sender, settlementTokenArg, new address[](0)) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            chainId == _RINKEBY_CHAIN_ID ||
                chainId == _MUMBAI_CHAIN_ID ||
                chainId == _SHIBUYA_CHAIN_ID ||
                chainId == _ZKSYNC2_TESTNET_CHAIN_ID ||
                chainId == _ARBITRUM_RINKEBY_CHAIN_ID ||
                chainId == _OPTIMISM_KOVAN_CHAIN_ID ||
                chainId == _HARDHAT_CHAIN_ID,
            "DPE_C: testnet only"
        );
    }

    function setCollateralBalance(address trader, int256 balance) external {
        accountInfos[trader].vaultInfo.collateralBalance = balance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { IPerpdexExchange } from "./interfaces/IPerpdexExchange.sol";
import { IPerpdexMarketMinimum } from "./interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./lib/PerpdexStructs.sol";
import { AccountLibrary } from "./lib/AccountLibrary.sol";
import { MakerLibrary } from "./lib/MakerLibrary.sol";
import { MakerOrderBookLibrary } from "./lib/MakerOrderBookLibrary.sol";
import { TakerLibrary } from "./lib/TakerLibrary.sol";
import { VaultLibrary } from "./lib/VaultLibrary.sol";
import { PerpMath } from "./lib/PerpMath.sol";

contract PerpdexExchange is IPerpdexExchange, ReentrancyGuard, Ownable, Multicall {
    using Address for address;
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;

    // states
    // trader
    mapping(address => PerpdexStructs.AccountInfo) public accountInfos;
    PerpdexStructs.InsuranceFundInfo public insuranceFundInfo;
    PerpdexStructs.ProtocolInfo public protocolInfo;
    // market, isBid, orderId, trader
    mapping(address => mapping(bool => mapping(uint40 => address))) public orderIdToTrader;

    // config
    address public immutable settlementToken;
    uint8 public constant quoteDecimals = 18;
    uint8 public maxMarketsPerAccount = 16;
    uint8 public maxOrdersPerAccount = 40;
    uint24 public imRatio = 10e4;
    uint24 public mmRatio = 5e4;
    uint24 public protocolFeeRatio = 0;
    PerpdexStructs.LiquidationRewardConfig public liquidationRewardConfig =
        PerpdexStructs.LiquidationRewardConfig({ rewardRatio: 20e4, smoothEmaTime: 100 });
    mapping(address => PerpdexStructs.MarketStatus) public marketStatuses;

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    modifier checkMarketOpen(address market) {
        _checkMarketOpen(market);
        _;
    }

    modifier checkMarketClosed(address market) {
        _checkMarketClosed(market);
        _;
    }

    constructor(
        address ownerArg,
        address settlementTokenArg,
        address[] memory initialMarkets
    ) {
        _transferOwnership(ownerArg);
        require(settlementTokenArg == address(0) || settlementTokenArg.isContract(), "PE_C: token address invalid");

        settlementToken = settlementTokenArg;

        for (uint256 i = 0; i < initialMarkets.length; ++i) {
            _setMarketStatus(initialMarkets[i], PerpdexStructs.MarketStatus.Open);
        }
    }

    function deposit(uint256 amount) external payable nonReentrant {
        address trader = _msgSender();
        _settleLimitOrders(trader);

        uint256 compensation = VaultLibrary.compensate(accountInfos[trader], insuranceFundInfo);
        if (compensation != 0) {
            emit CollateralCompensated(trader, compensation);
        }

        if (settlementToken == address(0)) {
            require(amount == 0, "PE_D: amount not zero");
            VaultLibrary.depositEth(accountInfos[trader], msg.value);
            emit Deposited(trader, msg.value);
        } else {
            require(msg.value == 0, "PE_D: msg.value not zero");
            VaultLibrary.deposit(
                accountInfos[trader],
                VaultLibrary.DepositParams({ settlementToken: settlementToken, amount: amount, from: trader })
            );
            emit Deposited(trader, amount);
        }
    }

    function withdraw(uint256 amount) external nonReentrant {
        address payable trader = payable(_msgSender());
        _settleLimitOrders(trader);

        VaultLibrary.withdraw(
            accountInfos[trader],
            VaultLibrary.WithdrawParams({
                settlementToken: settlementToken,
                amount: amount,
                to: trader,
                imRatio: imRatio
            })
        );
        emit Withdrawn(trader, amount);
    }

    function transferProtocolFee(uint256 amount) external onlyOwner nonReentrant {
        address trader = _msgSender();
        _settleLimitOrders(trader);
        VaultLibrary.transferProtocolFee(accountInfos[trader], protocolInfo, amount);
        emit ProtocolFeeTransferred(trader, amount);
    }

    function trade(TradeParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (uint256 oppositeAmount)
    {
        _settleLimitOrders(params.trader);
        TakerLibrary.TradeResponse memory response = _doTrade(params);

        if (response.rawResponse.partialOrderId != 0) {
            address partialTrader =
                orderIdToTrader[params.market][params.isBaseToQuote][response.rawResponse.partialOrderId];
            int256 partialRealizedPnL =
                MakerOrderBookLibrary.processPartialExecution(
                    accountInfos[partialTrader],
                    params.market,
                    params.isBaseToQuote,
                    maxMarketsPerAccount,
                    response.rawResponse
                );

            emit PartiallyExecuted(
                partialTrader,
                params.market,
                params.isBaseToQuote,
                response.rawResponse.basePartial,
                response.rawResponse.quotePartial,
                partialRealizedPnL
            );
        }

        uint256 baseBalancePerShareX96 = IPerpdexMarketMinimum(params.market).baseBalancePerShareX96();
        uint256 shareMarkPriceAfterX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();

        if (response.isLiquidation) {
            emit PositionLiquidated(
                params.trader,
                params.market,
                _msgSender(),
                response.base,
                response.quote,
                response.realizedPnl,
                response.protocolFee,
                baseBalancePerShareX96,
                shareMarkPriceAfterX96,
                response.liquidationPenalty,
                response.liquidationReward,
                response.insuranceFundReward
            );
        } else {
            emit PositionChanged(
                params.trader,
                params.market,
                response.base,
                response.quote,
                response.realizedPnl,
                response.protocolFee,
                baseBalancePerShareX96,
                shareMarkPriceAfterX96
            );
        }

        oppositeAmount = params.isExactInput == params.isBaseToQuote ? response.quote.abs() : response.base.abs();
    }

    function addLiquidity(AddLiquidityParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        )
    {
        address trader = _msgSender();
        _settleLimitOrders(trader);

        MakerLibrary.AddLiquidityResponse memory response =
            MakerLibrary.addLiquidity(
                accountInfos[trader],
                MakerLibrary.AddLiquidityParams({
                    market: params.market,
                    base: params.base,
                    quote: params.quote,
                    minBase: params.minBase,
                    minQuote: params.minQuote,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        PerpdexStructs.MakerInfo storage makerInfo = accountInfos[trader].makerInfos[params.market];
        emit LiquidityAdded(
            trader,
            params.market,
            response.base,
            response.quote,
            response.liquidity,
            makerInfo.cumBaseSharePerLiquidityX96,
            makerInfo.cumQuotePerLiquidityX96
        );

        return (response.base, response.quote, response.liquidity);
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (uint256 base, uint256 quote)
    {
        _settleLimitOrders(params.trader);

        MakerLibrary.RemoveLiquidityResponse memory response =
            MakerLibrary.removeLiquidity(
                accountInfos[params.trader],
                MakerLibrary.RemoveLiquidityParams({
                    market: params.market,
                    liquidity: params.liquidity,
                    minBase: params.minBase,
                    minQuote: params.minQuote,
                    isSelf: params.trader == _msgSender(),
                    mmRatio: mmRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        emit LiquidityRemoved(
            params.trader,
            params.market,
            response.isLiquidation ? _msgSender() : address(0),
            response.base,
            response.quote,
            params.liquidity,
            response.takerBase,
            response.takerQuote,
            response.realizedPnl
        );

        return (response.base, response.quote);
    }

    function createLimitOrder(CreateLimitOrderParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (uint40 orderId)
    {
        address trader = _msgSender();
        _settleLimitOrders(trader);

        orderId = MakerOrderBookLibrary.createLimitOrder(
            accountInfos[trader],
            MakerOrderBookLibrary.CreateLimitOrderParams({
                market: params.market,
                isBid: params.isBid,
                base: params.base,
                priceX96: params.priceX96,
                imRatio: imRatio,
                maxMarketsPerAccount: maxMarketsPerAccount,
                maxOrdersPerAccount: maxOrdersPerAccount
            })
        );
        orderIdToTrader[params.market][params.isBid][orderId] = trader;

        emit LimitOrderCreated(trader, params.market, params.isBid, params.base, params.priceX96, orderId);
    }

    function cancelLimitOrder(CancelLimitOrderParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
    {
        address trader = orderIdToTrader[params.market][params.isBid][params.orderId];
        require(trader != address(0), "PE_CLO: order not exist");
        _settleLimitOrders(trader);

        bool isLiquidation =
            MakerOrderBookLibrary.cancelLimitOrder(
                accountInfos[trader],
                MakerOrderBookLibrary.CancelLimitOrderParams({
                    market: params.market,
                    isBid: params.isBid,
                    orderId: params.orderId,
                    isSelf: trader == _msgSender(),
                    mmRatio: mmRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        emit LimitOrderCanceled(
            trader,
            params.market,
            isLiquidation ? _msgSender() : address(0),
            params.isBid,
            params.orderId
        );
    }

    function closeMarket(address market) external nonReentrant checkMarketClosed(market) {
        address trader = _msgSender();
        _settleLimitOrders(trader);
        AccountLibrary.closeMarket(accountInfos[trader], market);
    }

    function _settleLimitOrders(address trader) internal {
        MakerOrderBookLibrary.settleLimitOrdersAll(accountInfos[trader], maxMarketsPerAccount);
    }

    function setMaxMarketsPerAccount(uint8 value) external onlyOwner nonReentrant {
        maxMarketsPerAccount = value;
        emit MaxMarketsPerAccountChanged(value);
    }

    function setMaxOrdersPerAccount(uint8 value) external onlyOwner nonReentrant {
        maxOrdersPerAccount = value;
        emit MaxOrdersPerAccountChanged(value);
    }

    function setImRatio(uint24 value) external onlyOwner nonReentrant {
        require(value < 1e6, "PE_SIR: too large");
        require(value >= mmRatio, "PE_SIR: smaller than mmRatio");
        imRatio = value;
        emit ImRatioChanged(value);
    }

    function setMmRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= imRatio, "PE_SMR: bigger than imRatio");
        require(value > 0, "PE_SMR: zero");
        mmRatio = value;
        emit MmRatioChanged(value);
    }

    function setLiquidationRewardConfig(PerpdexStructs.LiquidationRewardConfig calldata value)
        external
        onlyOwner
        nonReentrant
    {
        require(value.rewardRatio < 1e6, "PE_SLRC: too large reward ratio");
        require(value.smoothEmaTime > 0, "PE_SLRC: ema time is zero");
        liquidationRewardConfig = value;
        emit LiquidationRewardConfigChanged(value.rewardRatio, value.smoothEmaTime);
    }

    function setProtocolFeeRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= 1e4, "PE_SPFR: too large");
        protocolFeeRatio = value;
        emit ProtocolFeeRatioChanged(value);
    }

    function setMarketStatus(address market, PerpdexStructs.MarketStatus status) external onlyOwner nonReentrant {
        _setMarketStatus(market, status);
    }

    // all raw information can be retrieved through getters (including default getters)

    function getTakerInfo(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory) {
        return accountInfos[trader].takerInfos[market];
    }

    function getMakerInfo(address trader, address market) external view returns (PerpdexStructs.MakerInfo memory) {
        return accountInfos[trader].makerInfos[market];
    }

    function getAccountMarkets(address trader) external view returns (address[] memory) {
        return accountInfos[trader].markets;
    }

    function getLimitOrderInfo(address trader, address market)
        external
        view
        returns (
            uint40 askRoot,
            uint40 bidRoot,
            uint256 totalBaseAsk,
            uint256 totalBaseBid
        )
    {
        PerpdexStructs.LimitOrderInfo storage info = accountInfos[trader].limitOrderInfos[market];
        return (info.ask.root, info.bid.root, info.totalBaseAsk, info.totalBaseBid);
    }

    function getLimitOrderIds(
        address trader,
        address market,
        bool isBid
    ) external view returns (uint40[] memory) {
        return MakerOrderBookLibrary.getLimitOrderIds(accountInfos[trader], market, isBid);
    }

    // dry run

    function previewTrade(PreviewTradeParams calldata params)
        external
        view
        checkMarketOpen(params.market)
        returns (uint256 oppositeAmount)
    {
        address trader = params.trader;
        address caller = params.caller;

        return
            TakerLibrary.previewTrade(
                accountInfos[trader],
                TakerLibrary.PreviewTradeParams({
                    market: params.market,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    amount: params.amount,
                    oppositeAmountBound: params.oppositeAmountBound,
                    mmRatio: mmRatio,
                    protocolFeeRatio: protocolFeeRatio,
                    isSelf: trader == caller
                })
            );
    }

    function maxTrade(MaxTradeParams calldata params) external view returns (uint256 amount) {
        if (marketStatuses[params.market] != PerpdexStructs.MarketStatus.Open) return 0;

        address trader = params.trader;
        address caller = params.caller;

        return
            TakerLibrary.maxTrade({
                accountInfo: accountInfos[trader],
                market: params.market,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                mmRatio: mmRatio,
                protocolFeeRatio: protocolFeeRatio,
                isSelf: trader == caller
            });
    }

    // convenient getters

    function getTakerInfoLazy(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory) {
        return AccountLibrary.getTakerInfo(accountInfos[trader], market);
    }

    function getCollateralBalance(address trader) external view returns (int256) {
        return AccountLibrary.getCollateralBalance(accountInfos[trader]);
    }

    function getTotalAccountValue(address trader) external view returns (int256) {
        return AccountLibrary.getTotalAccountValue(accountInfos[trader]);
    }

    function getPositionShare(address trader, address market) external view returns (int256) {
        return AccountLibrary.getPositionShare(accountInfos[trader], market);
    }

    function getPositionNotional(address trader, address market) external view returns (int256) {
        return AccountLibrary.getPositionNotional(accountInfos[trader], market);
    }

    function getTotalPositionNotional(address trader) external view returns (uint256) {
        return AccountLibrary.getTotalPositionNotional(accountInfos[trader]);
    }

    function getOpenPositionShare(address trader, address market) external view returns (uint256) {
        return AccountLibrary.getOpenPositionShare(accountInfos[trader], market);
    }

    function getOpenPositionNotional(address trader, address market) external view returns (uint256) {
        return AccountLibrary.getOpenPositionNotional(accountInfos[trader], market);
    }

    function getTotalOpenPositionNotional(address trader) external view returns (uint256) {
        return AccountLibrary.getTotalOpenPositionNotional(accountInfos[trader]);
    }

    function hasEnoughMaintenanceMargin(address trader) external view returns (bool) {
        return AccountLibrary.hasEnoughMaintenanceMargin(accountInfos[trader], mmRatio);
    }

    function hasEnoughInitialMargin(address trader) external view returns (bool) {
        return AccountLibrary.hasEnoughInitialMargin(accountInfos[trader], imRatio);
    }

    function isLiquidationFree(address trader) external view returns (bool) {
        return AccountLibrary.isLiquidationFree(accountInfos[trader]);
    }

    function getLimitOrderSummaries(
        address trader,
        address market,
        bool isBid
    ) external view returns (PerpdexStructs.LimitOrderSummary[] memory) {
        return MakerOrderBookLibrary.getLimitOrderSummaries(accountInfos[trader], market, isBid);
    }

    // for avoiding stack too deep error
    function _doTrade(TradeParams calldata params) private returns (TakerLibrary.TradeResponse memory) {
        return
            TakerLibrary.trade(
                accountInfos[params.trader],
                accountInfos[_msgSender()].vaultInfo,
                insuranceFundInfo,
                protocolInfo,
                TakerLibrary.TradeParams({
                    market: params.market,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    amount: params.amount,
                    oppositeAmountBound: params.oppositeAmountBound,
                    mmRatio: mmRatio,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount,
                    protocolFeeRatio: protocolFeeRatio,
                    liquidationRewardConfig: liquidationRewardConfig,
                    isSelf: params.trader == _msgSender()
                })
            );
    }

    function _setMarketStatus(address market, PerpdexStructs.MarketStatus status) private {
        if (marketStatuses[market] == status) return;

        if (status == PerpdexStructs.MarketStatus.Open) {
            require(market.isContract(), "PE_SIMA: market address invalid");
            require(IPerpdexMarketMinimum(market).exchange() == address(this), "PE_SIMA: different exchange");
            require(marketStatuses[market] == PerpdexStructs.MarketStatus.NotAllowed, "PE_SIMA: market closed");
        } else if (status == PerpdexStructs.MarketStatus.Closed) {
            _checkMarketOpen(market);
        } else {
            require(false, "PE_SIMA: invalid status");
        }

        marketStatuses[market] = status;
        emit MarketStatusChanged(market, status);
    }

    // to reduce contract size
    function _checkDeadline(uint256 deadline) private view {
        require(block.timestamp <= deadline, "PE_CD: too late");
    }

    // to reduce contract size
    function _checkMarketOpen(address market) private view {
        require(marketStatuses[market] == PerpdexStructs.MarketStatus.Open, "PE_CMO: market not open");
    }

    // to reduce contract size
    function _checkMarketClosed(address market) private view {
        require(marketStatuses[market] == PerpdexStructs.MarketStatus.Closed, "PE_CMC: market not closed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PerpdexStructs } from "../lib/PerpdexStructs.sol";

interface IPerpdexExchange {
    struct AddLiquidityParams {
        address market;
        uint256 base;
        uint256 quote;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct RemoveLiquidityParams {
        address trader;
        address market;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct TradeParams {
        address trader;
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
    }

    struct PreviewTradeParams {
        address trader;
        address market;
        address caller;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
    }

    struct MaxTradeParams {
        address trader;
        address market;
        address caller;
        bool isBaseToQuote;
        bool isExactInput;
    }

    struct CreateLimitOrderParams {
        address market;
        bool isBid;
        uint256 base;
        uint256 priceX96;
        uint256 deadline;
    }

    struct CancelLimitOrderParams {
        address market;
        bool isBid;
        uint40 orderId;
        uint256 deadline;
    }

    event CollateralCompensated(address indexed trader, uint256 amount);
    event Deposited(address indexed trader, uint256 amount);
    event Withdrawn(address indexed trader, uint256 amount);
    event ProtocolFeeTransferred(address indexed trader, uint256 amount);

    event LiquidityAdded(
        address indexed trader,
        address indexed market,
        uint256 base,
        uint256 quote,
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    );

    event LiquidityRemoved(
        address indexed trader,
        address indexed market,
        address liquidator,
        uint256 base,
        uint256 quote,
        uint256 liquidity,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl
    );

    event PartiallyExecuted(
        address indexed maker,
        address indexed market,
        bool isAsk,
        uint256 basePartial,
        uint256 quotePartial,
        int256 partialRealizedPnL
    );

    event PositionLiquidated(
        address indexed trader,
        address indexed market,
        address indexed liquidator,
        int256 base,
        int256 quote,
        int256 realizedPnl,
        uint256 protocolFee,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96,
        uint256 liquidationPenalty,
        uint256 liquidationReward,
        uint256 insuranceFundReward
    );

    event PositionChanged(
        address indexed trader,
        address indexed market,
        int256 base,
        int256 quote,
        int256 realizedPnl,
        uint256 protocolFee,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96
    );

    event LimitOrderCreated(
        address indexed trader,
        address indexed market,
        bool isBid,
        uint256 base,
        uint256 priceX96,
        uint256 orderId
    );

    event LimitOrderCanceled(
        address indexed trader,
        address indexed market,
        address indexed liquidator,
        bool isBid,
        uint256 orderId
    );

    event MaxMarketsPerAccountChanged(uint8 value);
    event MaxOrdersPerAccountChanged(uint8 value);
    event ImRatioChanged(uint24 value);
    event MmRatioChanged(uint24 value);
    event LiquidationRewardConfigChanged(uint24 rewardRatio, uint16 smoothEmaTime);
    event ProtocolFeeRatioChanged(uint24 value);
    event MarketStatusChanged(address indexed market, PerpdexStructs.MarketStatus status);

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function transferProtocolFee(uint256 amount) external;

    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        );

    function removeLiquidity(RemoveLiquidityParams calldata params) external returns (uint256 base, uint256 quote);

    function createLimitOrder(CreateLimitOrderParams calldata params) external returns (uint40 orderId);

    function cancelLimitOrder(CancelLimitOrderParams calldata params) external;

    function trade(TradeParams calldata params) external returns (uint256 oppositeAmount);

    // setters

    function setMaxMarketsPerAccount(uint8 value) external;

    function setImRatio(uint24 value) external;

    function setMmRatio(uint24 value) external;

    function setLiquidationRewardConfig(PerpdexStructs.LiquidationRewardConfig calldata value) external;

    function setProtocolFeeRatio(uint24 value) external;

    function setMarketStatus(address market, PerpdexStructs.MarketStatus status) external;

    // dry run getters

    function previewTrade(PreviewTradeParams calldata params) external view returns (uint256 oppositeAmount);

    function maxTrade(MaxTradeParams calldata params) external view returns (uint256 amount);

    // default getters

    function accountInfos(address trader)
        external
        view
        returns (PerpdexStructs.VaultInfo memory, uint8 limitOrderCount);

    function insuranceFundInfo() external view returns (uint256 balance, uint256 liquidationRewardBalance);

    function protocolInfo() external view returns (uint256 protocolFee);

    function settlementToken() external view returns (address);

    function quoteDecimals() external view returns (uint8);

    function maxMarketsPerAccount() external view returns (uint8);

    function imRatio() external view returns (uint24);

    function mmRatio() external view returns (uint24);

    function liquidationRewardConfig() external view returns (uint24 rewardRatio, uint16 smoothEmaTime);

    function protocolFeeRatio() external view returns (uint24);

    function marketStatuses(address market) external view returns (PerpdexStructs.MarketStatus status);

    // getters not covered by default getters

    function getTakerInfo(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory);

    function getMakerInfo(address trader, address market) external view returns (PerpdexStructs.MakerInfo memory);

    function getAccountMarkets(address trader) external view returns (address[] memory);

    function getLimitOrderInfo(address trader, address market)
        external
        view
        returns (
            uint40 askRoot,
            uint40 bidRoot,
            uint256 totalBaseAsk,
            uint256 totalBaseBid
        );

    function getLimitOrderIds(
        address trader,
        address market,
        bool isBid
    ) external view returns (uint40[] memory);

    // convenient getters

    function getTotalAccountValue(address trader) external view returns (int256);

    function getPositionShare(address trader, address market) external view returns (int256);

    function getPositionNotional(address trader, address market) external view returns (int256);

    function getTotalPositionNotional(address trader) external view returns (uint256);

    function getOpenPositionShare(address trader, address market) external view returns (uint256);

    function getOpenPositionNotional(address trader, address market) external view returns (uint256);

    function getTotalOpenPositionNotional(address trader) external view returns (uint256);

    function hasEnoughMaintenanceMargin(address trader) external view returns (bool);

    function hasEnoughInitialMargin(address trader) external view returns (bool);

    function isLiquidationFree(address trader) external view returns (bool);

    function getLimitOrderSummaries(
        address trader,
        address market,
        bool isBid
    ) external view returns (PerpdexStructs.LimitOrderSummary[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IPerpdexMarketMinimum {
    struct SwapResponse {
        uint256 oppositeAmount;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 partialOrderId;
    }

    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external returns (SwapResponse memory response);

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(uint256 liquidity) external returns (uint256 baseShare, uint256 quoteBalance);

    function createLimitOrder(
        bool isBid,
        uint256 baseShare,
        uint256 priceX96
    ) external returns (uint40 orderId);

    function cancelLimitOrder(bool isBid, uint40 orderId) external;

    // getters

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256);

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount);

    function exchange() external view returns (address);

    function getShareMarkPriceX96() external view returns (uint256);

    function getLiquidityValue(uint256 liquidity) external view returns (uint256 baseShare, uint256 quoteBalance);

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256);

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256);

    function baseBalancePerShareX96() external view returns (uint256);

    function getLimitOrderInfo(bool isBid, uint40 orderId) external view returns (uint256 base, uint256 priceX96);

    function getLimitOrderExecution(bool isBid, uint40 orderId)
        external
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library PerpdexStructs {
    enum MarketStatus { NotAllowed, Open, Closed }

    struct TakerInfo {
        int256 baseBalanceShare;
        int256 quoteBalance;
    }

    struct MakerInfo {
        uint256 liquidity;
        uint256 cumBaseSharePerLiquidityX96;
        uint256 cumQuotePerLiquidityX96;
    }

    struct LimitOrderInfo {
        RBTreeLibrary.Tree ask;
        RBTreeLibrary.Tree bid;
        uint256 totalBaseAsk;
        uint256 totalBaseBid;
    }

    struct VaultInfo {
        int256 collateralBalance;
    }

    struct AccountInfo {
        // market
        mapping(address => TakerInfo) takerInfos;
        // market
        mapping(address => MakerInfo) makerInfos;
        // market
        mapping(address => LimitOrderInfo) limitOrderInfos;
        VaultInfo vaultInfo;
        address[] markets;
        uint8 limitOrderCount;
    }

    struct InsuranceFundInfo {
        uint256 balance; // for easy calculation
        uint256 liquidationRewardBalance;
    }

    struct ProtocolInfo {
        uint256 protocolFee;
    }

    struct LiquidationRewardConfig {
        uint24 rewardRatio;
        uint16 smoothEmaTime;
    }

    struct LimitOrderSummary {
        uint40 orderId;
        uint256 base;
        uint256 priceX96;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { PerpMath } from "./PerpMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountPreviewLibrary } from "./AccountPreviewLibrary.sol";

// https://help.ftx.com/hc/en-us/articles/360024780511-Complete-Futures-Specs
library AccountLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct CalcMarketResponse {
        int256 baseShare;
        uint256 baseSharePool;
        uint256 baseShareAsk;
        uint256 baseShareBid;
        int256 quoteBalance;
        uint256 quoteBalancePool;
        int256 positionNotional;
        uint256 openPositionShare;
        uint256 openPositionNotional;
        int256 positionValue;
        int256 realizedPnl;
    }

    struct CalcTotalResponse {
        int256 accountValue;
        int256 collateralBalance;
        uint256 totalPositionNotional;
        uint256 totalOpenPositionNotional;
        bool isLiquidationFree;
    }

    function updateMarkets(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount
    ) external {
        bool enabled =
            accountInfo.takerInfos[market].baseBalanceShare != 0 ||
                accountInfo.makerInfos[market].liquidity != 0 ||
                accountInfo.limitOrderInfos[market].ask.root != 0 ||
                accountInfo.limitOrderInfos[market].bid.root != 0;

        _setMarketEnabled(accountInfo, market, maxMarketsPerAccount, enabled);
    }

    function closeMarket(PerpdexStructs.AccountInfo storage accountInfo, address market) external {
        require(_marketExists(accountInfo, market), "AL_CM: market not exist");
        CalcMarketResponse memory response = _calcMarket(accountInfo, market);
        accountInfo.vaultInfo.collateralBalance += response.positionValue + response.realizedPnl;
        _setMarketEnabled(accountInfo, market, 0, false);
    }

    function getTakerInfo(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (PerpdexStructs.TakerInfo memory takerInfo)
    {
        (AccountPreviewLibrary.Execution[] memory executions, , ) =
            AccountPreviewLibrary.getLimitOrderExecutions(accountInfo, market);
        (takerInfo, , , ) = AccountPreviewLibrary.previewSettleLimitOrders(accountInfo, market, executions);
    }

    function getCollateralBalance(PerpdexStructs.AccountInfo storage accountInfo) external view returns (int256) {
        return _calcTotal(accountInfo).collateralBalance;
    }

    function getTotalAccountValue(PerpdexStructs.AccountInfo storage accountInfo) external view returns (int256) {
        return _calcTotal(accountInfo).accountValue;
    }

    function getPositionShare(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (int256)
    {
        return _calcMarket(accountInfo, market).baseShare;
    }

    function getPositionNotional(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (int256)
    {
        return _calcMarket(accountInfo, market).positionNotional;
    }

    function getTotalPositionNotional(PerpdexStructs.AccountInfo storage accountInfo) external view returns (uint256) {
        return _calcTotal(accountInfo).totalPositionNotional;
    }

    function getOpenPositionShare(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (uint256)
    {
        return _calcMarket(accountInfo, market).openPositionShare;
    }

    function getOpenPositionNotional(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (uint256)
    {
        return _calcMarket(accountInfo, market).openPositionNotional;
    }

    function getTotalOpenPositionNotional(PerpdexStructs.AccountInfo storage accountInfo)
        external
        view
        returns (uint256)
    {
        return _calcTotal(accountInfo).totalOpenPositionNotional;
    }

    function hasEnoughMaintenanceMargin(PerpdexStructs.AccountInfo storage accountInfo, uint24 mmRatio)
        external
        view
        returns (bool)
    {
        CalcTotalResponse memory response = _calcTotal(accountInfo);
        return response.accountValue.mul(1e6) >= response.totalPositionNotional.mul(mmRatio).toInt256();
    }

    // always true when hasEnoughMaintenanceMargin is true
    function hasEnoughInitialMargin(PerpdexStructs.AccountInfo storage accountInfo, uint24 imRatio)
        external
        view
        returns (bool)
    {
        CalcTotalResponse memory response = _calcTotal(accountInfo);
        return
            response.accountValue.min(response.collateralBalance).mul(1e6) >=
            response.totalOpenPositionNotional.mul(imRatio).toInt256() ||
            response.isLiquidationFree;
    }

    function isLiquidationFree(PerpdexStructs.AccountInfo storage accountInfo) external view returns (bool) {
        return _calcTotal(accountInfo).isLiquidationFree;
    }

    function _setMarketEnabled(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount,
        bool enabled
    ) private {
        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;

        for (uint256 i = 0; i < length; ++i) {
            if (markets[i] == market) {
                if (!enabled) {
                    markets[i] = markets[length - 1];
                    markets.pop();
                }
                return;
            }
        }

        if (!enabled) return;

        require(length + 1 <= maxMarketsPerAccount, "AL_UP: too many markets");
        markets.push(market);
    }

    function _calcMarket(PerpdexStructs.AccountInfo storage accountInfo, address market)
        private
        view
        returns (CalcMarketResponse memory response)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[market];
        PerpdexStructs.TakerInfo memory takerInfo;
        (AccountPreviewLibrary.Execution[] memory executions, , ) =
            AccountPreviewLibrary.getLimitOrderExecutions(accountInfo, market);

        uint256 totalExecutedBaseAsk;
        uint256 totalExecutedBaseBid;
        (takerInfo, response.realizedPnl, totalExecutedBaseAsk, totalExecutedBaseBid) = AccountPreviewLibrary
            .previewSettleLimitOrders(accountInfo, market, executions);

        response.baseShare = takerInfo.baseBalanceShare;
        response.quoteBalance = takerInfo.quoteBalance;

        uint256 totalOrderBaseAsk;
        uint256 totalOrderBaseBid;
        if (makerInfo.liquidity != 0) {
            (uint256 poolBaseShare, uint256 poolQuoteBalance) =
                IPerpdexMarketMinimum(market).getLiquidityValue(makerInfo.liquidity);
            (int256 deleveragedBaseShare, int256 deleveragedQuoteBalance) =
                IPerpdexMarketMinimum(market).getLiquidityDeleveraged(
                    makerInfo.liquidity,
                    makerInfo.cumBaseSharePerLiquidityX96,
                    makerInfo.cumQuotePerLiquidityX96
                );
            response.baseSharePool = poolBaseShare;
            response.baseShare = response.baseShare.add(deleveragedBaseShare).add(response.baseSharePool.toInt256());
            response.quoteBalancePool = poolQuoteBalance;
            response.quoteBalance = response.quoteBalance.add(deleveragedQuoteBalance).add(
                response.quoteBalancePool.toInt256()
            );
            totalOrderBaseAsk = poolBaseShare;
            totalOrderBaseBid = poolBaseShare;
        }

        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        response.baseShareAsk = limitOrderInfo.totalBaseAsk - totalExecutedBaseAsk;
        response.baseShareBid = limitOrderInfo.totalBaseBid - totalExecutedBaseBid;
        totalOrderBaseAsk += response.baseShareAsk;
        totalOrderBaseBid += response.baseShareBid;
        response.openPositionShare = Math.max(
            (response.baseShare - totalOrderBaseAsk.toInt256()).abs(),
            (response.baseShare + totalOrderBaseBid.toInt256()).abs()
        );

        if (response.openPositionShare != 0) {
            uint256 sharePriceX96 = IPerpdexMarketMinimum(market).getShareMarkPriceX96();
            response.openPositionNotional = Math.mulDiv(response.openPositionShare, sharePriceX96, FixedPoint96.Q96);

            if (response.baseShare != 0) {
                response.positionNotional = response.baseShare.mulDiv(sharePriceX96.toInt256(), FixedPoint96.Q96);
                response.positionValue = response.positionValue.add(response.positionNotional);
            }
        }

        response.positionValue = response.positionValue.add(response.quoteBalance);
    }

    function _calcTotal(PerpdexStructs.AccountInfo storage accountInfo)
        private
        view
        returns (CalcTotalResponse memory response)
    {
        response.collateralBalance = accountInfo.vaultInfo.collateralBalance;
        response.isLiquidationFree = true;
        int256 quoteBalanceWithoutPool;

        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            address market = markets[i];

            CalcMarketResponse memory marketResponse = _calcMarket(accountInfo, market);

            response.accountValue = response.accountValue.add(marketResponse.positionValue);
            response.collateralBalance = response.collateralBalance.add(marketResponse.realizedPnl);
            response.totalPositionNotional = response.totalPositionNotional.add(marketResponse.positionNotional.abs());
            response.totalOpenPositionNotional = response.totalOpenPositionNotional.add(
                marketResponse.openPositionNotional
            );

            response.isLiquidationFree =
                response.isLiquidationFree &&
                marketResponse.baseShare >= marketResponse.baseShareAsk.add(marketResponse.baseSharePool).toInt256() &&
                marketResponse.baseShareBid == 0;
            quoteBalanceWithoutPool = quoteBalanceWithoutPool.add(
                marketResponse.quoteBalance - marketResponse.quoteBalancePool.toInt256()
            );
        }
        response.accountValue = response.accountValue.add(response.collateralBalance);
        response.isLiquidationFree =
            response.isLiquidationFree &&
            quoteBalanceWithoutPool.add(response.collateralBalance) >= 0;
    }

    function _marketExists(PerpdexStructs.AccountInfo storage accountInfo, address market) private view returns (bool) {
        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            if (markets[i] == market) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { TakerLibrary } from "./TakerLibrary.sol";

library MakerLibrary {
    using PerpMath for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct AddLiquidityParams {
        address market;
        uint256 base;
        uint256 quote;
        uint256 minBase;
        uint256 minQuote;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 liquidity;
    }

    struct RemoveLiquidityParams {
        address market;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint24 mmRatio;
        uint8 maxMarketsPerAccount;
        bool isSelf;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        int256 takerBase;
        int256 takerQuote;
        int256 realizedPnl;
        bool isLiquidation;
    }

    function addLiquidity(PerpdexStructs.AccountInfo storage accountInfo, AddLiquidityParams memory params)
        external
        returns (AddLiquidityResponse memory response)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];

        // retrieve before addLiquidity
        (uint256 cumBasePerLiquidityX96, uint256 cumQuotePerLiquidityX96) =
            IPerpdexMarketMinimum(params.market).getCumDeleveragedPerLiquidityX96();

        (response.base, response.quote, response.liquidity) = IPerpdexMarketMinimum(params.market).addLiquidity(
            params.base,
            params.quote
        );

        require(response.base >= params.minBase, "ML_AL: too small output base");
        require(response.quote >= params.minQuote, "ML_AL: too small output quote");

        uint256 liquidityBefore = makerInfo.liquidity;
        makerInfo.liquidity = liquidityBefore.add(response.liquidity);
        {
            makerInfo.cumBaseSharePerLiquidityX96 = _blendCumPerLiquidity(
                liquidityBefore,
                response.liquidity,
                response.base,
                makerInfo.cumBaseSharePerLiquidityX96,
                cumBasePerLiquidityX96
            );
            makerInfo.cumQuotePerLiquidityX96 = _blendCumPerLiquidity(
                liquidityBefore,
                response.liquidity,
                response.quote,
                makerInfo.cumQuotePerLiquidityX96,
                cumQuotePerLiquidityX96
            );
        }

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "ML_AL: not enough im");
    }

    // difficult to calculate without error
    // underestimate the value to maintain the liquidation free condition
    // the error will be a burden to the insurance fund
    // the error is much smaller than the gas fee, so it is impossible to attack
    function _blendCumPerLiquidity(
        uint256 liquidityBefore,
        uint256 addedLiquidity,
        uint256 addedToken,
        uint256 cumBefore,
        uint256 cumAfter
    ) private pure returns (uint256) {
        uint256 liquidityAfter = liquidityBefore.add(addedLiquidity);
        cumAfter = cumAfter.add(Math.mulDiv(addedToken, FixedPoint96.Q96, addedLiquidity));

        return
            Math.mulDiv(cumBefore, liquidityBefore, liquidityAfter).add(
                Math.mulDiv(cumAfter, addedLiquidity, liquidityAfter)
            );
    }

    function removeLiquidity(PerpdexStructs.AccountInfo storage accountInfo, RemoveLiquidityParams memory params)
        external
        returns (RemoveLiquidityResponse memory response)
    {
        response.isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(response.isLiquidation, "ML_RL: enough mm");
        }

        uint256 shareMarkPriceBeforeX96;
        {
            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];
            // retrieve before removeLiquidity
            (response.takerBase, response.takerQuote) = IPerpdexMarketMinimum(params.market).getLiquidityDeleveraged(
                params.liquidity,
                makerInfo.cumBaseSharePerLiquidityX96,
                makerInfo.cumQuotePerLiquidityX96
            );

            shareMarkPriceBeforeX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();
        }

        {
            (response.base, response.quote) = IPerpdexMarketMinimum(params.market).removeLiquidity(params.liquidity);

            require(response.base >= params.minBase, "ML_RL: too small output base");
            require(response.quote >= params.minQuote, "ML_RL: too small output base");

            response.takerBase = response.takerBase.add(response.base.toInt256());
            response.takerQuote = response.takerQuote.add(response.quote.toInt256());

            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];
            makerInfo.liquidity = makerInfo.liquidity.sub(params.liquidity);
        }

        {
            int256 takerQuoteCalculatedAtCurrentPrice =
                -response.takerBase.mulDiv(shareMarkPriceBeforeX96.toInt256(), FixedPoint96.Q96);

            // AccountLibrary.updateMarkets called
            response.realizedPnl = TakerLibrary.addToTakerBalance(
                accountInfo,
                params.market,
                response.takerBase,
                takerQuoteCalculatedAtCurrentPrice,
                response.takerQuote.sub(takerQuoteCalculatedAtCurrentPrice),
                params.maxMarketsPerAccount
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { AccountPreviewLibrary } from "./AccountPreviewLibrary.sol";
import { TakerLibrary } from "./TakerLibrary.sol";
import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library MakerOrderBookLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using RBTreeLibrary for RBTreeLibrary.Tree;

    struct CreateLimitOrderParams {
        address market;
        uint256 base;
        uint256 priceX96;
        bool isBid;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
        uint8 maxOrdersPerAccount;
    }

    struct CancelLimitOrderParams {
        address market;
        uint40 orderId;
        bool isBid;
        uint24 mmRatio;
        bool isSelf;
        uint8 maxMarketsPerAccount;
    }

    function createLimitOrder(PerpdexStructs.AccountInfo storage accountInfo, CreateLimitOrderParams memory params)
        public
        returns (uint40 orderId)
    {
        require(accountInfo.limitOrderCount < params.maxOrdersPerAccount, "MOBL_CLO: max order count");
        orderId = IPerpdexMarketMinimum(params.market).createLimitOrder(params.isBid, params.base, params.priceX96);

        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[params.market];
        uint256 slot = _getSlot(limitOrderInfo);
        if (params.isBid) {
            limitOrderInfo.bid.insert(orderId, makeUserData(params.priceX96), _lessThanBid, _aggregate, slot);
            limitOrderInfo.totalBaseBid += params.base;
        } else {
            limitOrderInfo.ask.insert(orderId, makeUserData(params.priceX96), _lessThanAsk, _aggregate, slot);
            limitOrderInfo.totalBaseAsk += params.base;
        }
        accountInfo.limitOrderCount += 1;

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "MOBL_CLO: not enough im");
    }

    function cancelLimitOrder(PerpdexStructs.AccountInfo storage accountInfo, CancelLimitOrderParams memory params)
        public
        returns (bool isLiquidation)
    {
        isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(isLiquidation, "MOBL_CLO: enough mm");
        }

        (uint256 base, ) = IPerpdexMarketMinimum(params.market).getLimitOrderInfo(params.isBid, params.orderId);
        IPerpdexMarketMinimum(params.market).cancelLimitOrder(params.isBid, params.orderId);

        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[params.market];
        if (params.isBid) {
            limitOrderInfo.totalBaseBid -= base;
            limitOrderInfo.bid.remove(params.orderId, _aggregate, 0);
        } else {
            limitOrderInfo.totalBaseAsk -= base;
            limitOrderInfo.ask.remove(params.orderId, _aggregate, 0);
        }
        accountInfo.limitOrderCount -= 1;

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);
    }

    function makeUserData(uint256 priceX96) internal pure returns (uint128) {
        return priceX96.toUint128();
    }

    function userDataToPriceX96(uint128 userData) internal pure returns (uint128) {
        return userData;
    }

    function _lessThan(
        RBTreeLibrary.Tree storage tree,
        bool isBid,
        uint40 key0,
        uint40 key1
    ) private view returns (bool) {
        uint128 price0 = userDataToPriceX96(tree.nodes[key0].userData);
        uint128 price1 = userDataToPriceX96(tree.nodes[key1].userData);
        if (price0 == price1) {
            return key0 < key1; // time priority
        }
        // price priority
        return isBid ? price0 > price1 : price0 < price1;
    }

    function _lessThanAsk(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        PerpdexStructs.LimitOrderInfo storage info = _getLimitOrderInfoFromSlot(slot);
        return _lessThan(info.ask, false, key0, key1);
    }

    function _lessThanBid(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        PerpdexStructs.LimitOrderInfo storage info = _getLimitOrderInfoFromSlot(slot);
        return _lessThan(info.bid, true, key0, key1);
    }

    function _aggregate(uint40, uint256) private pure returns (bool) {
        return true;
    }

    function _subtreeRemoved(uint40, uint256) private pure {}

    function settleLimitOrdersAll(PerpdexStructs.AccountInfo storage accountInfo, uint8 maxMarketsPerAccount) public {
        address[] storage markets = accountInfo.markets;
        uint256 i = markets.length;
        while (i > 0) {
            --i;
            _settleLimitOrders(accountInfo, markets[i], maxMarketsPerAccount);
        }
    }

    function _settleLimitOrders(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount
    ) private {
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        (
            AccountPreviewLibrary.Execution[] memory executions,
            uint40 executedLastAskOrderId,
            uint40 executedLastBidOrderId
        ) = AccountPreviewLibrary.getLimitOrderExecutions(accountInfo, market);
        uint256 executionLength = executions.length;
        if (executionLength == 0) return;

        {
            uint256 slot = _getSlot(limitOrderInfo);
            if (executedLastAskOrderId != 0) {
                limitOrderInfo.ask.removeLeft(executedLastAskOrderId, _lessThanAsk, _aggregate, _subtreeRemoved, slot);
            }
            if (executedLastBidOrderId != 0) {
                limitOrderInfo.bid.removeLeft(executedLastBidOrderId, _lessThanBid, _aggregate, _subtreeRemoved, slot);
            }
        }

        int256 realizedPnl;
        uint256 totalExecutedBaseAsk;
        uint256 totalExecutedBaseBid;
        (
            accountInfo.takerInfos[market],
            realizedPnl,
            totalExecutedBaseAsk,
            totalExecutedBaseBid
        ) = AccountPreviewLibrary.previewSettleLimitOrders(accountInfo, market, executions);

        limitOrderInfo.totalBaseAsk -= totalExecutedBaseAsk;
        limitOrderInfo.totalBaseBid -= totalExecutedBaseBid;
        accountInfo.limitOrderCount -= executionLength.toUint8();
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(realizedPnl);
        AccountLibrary.updateMarkets(accountInfo, market, maxMarketsPerAccount);
    }

    function processPartialExecution(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBaseToQuote,
        uint8 maxMarketsPerAccount,
        IPerpdexMarketMinimum.SwapResponse memory rawResponse
    ) external returns (int256 realizedPnl) {
        _settleLimitOrders(accountInfo, market, maxMarketsPerAccount);
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        if (isBaseToQuote) {
            limitOrderInfo.totalBaseBid -= rawResponse.basePartial;
        } else {
            limitOrderInfo.totalBaseAsk -= rawResponse.basePartial;
        }
        realizedPnl = TakerLibrary.addToTakerBalance(
            accountInfo,
            market,
            isBaseToQuote ? rawResponse.basePartial.toInt256() : rawResponse.basePartial.neg256(),
            isBaseToQuote ? rawResponse.quotePartial.neg256() : rawResponse.quotePartial.toInt256(),
            0,
            maxMarketsPerAccount
        );
    }

    function getLimitOrderIds(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBid
    ) public view returns (uint40[] memory result) {
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        RBTreeLibrary.Tree storage tree = isBid ? limitOrderInfo.bid : limitOrderInfo.ask;
        uint40[256] memory orderIds;
        uint256 orderCount;
        uint40 key = tree.first();
        while (key != 0) {
            orderIds[orderCount] = key;
            ++orderCount;
            key = tree.next(key);
        }
        result = new uint40[](orderCount);
        for (uint256 i = 0; i < orderCount; ++i) {
            result[i] = orderIds[i];
        }
    }

    function getLimitOrderSummaries(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBid
    ) external view returns (PerpdexStructs.LimitOrderSummary[] memory result) {
        uint40[] memory orderIds = getLimitOrderIds(accountInfo, market, isBid);
        uint256 length = orderIds.length;
        PerpdexStructs.LimitOrderSummary[256] memory summaries;
        uint256 summaryCount;
        uint256 i;
        while (i < length) {
            (uint48 executionId, , ) = IPerpdexMarketMinimum(market).getLimitOrderExecution(isBid, orderIds[i]);
            if (executionId != 0) break;
            ++i;
        }
        while (i < length) {
            summaries[summaryCount].orderId = orderIds[i];
            (summaries[summaryCount].base, summaries[summaryCount].priceX96) = IPerpdexMarketMinimum(market)
                .getLimitOrderInfo(isBid, orderIds[i]);
            ++summaryCount;
            ++i;
        }
        result = new PerpdexStructs.LimitOrderSummary[](summaryCount);
        for (uint256 i = 0; i < summaryCount; ++i) {
            result[i] = summaries[i];
        }
    }

    function _getSlot(PerpdexStructs.LimitOrderInfo storage d) private pure returns (uint256 slot) {
        assembly {
            slot := d.slot
        }
    }

    function _getLimitOrderInfoFromSlot(uint256 slot) private pure returns (PerpdexStructs.LimitOrderInfo storage d) {
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpMath } from "./PerpMath.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { AccountPreviewLibrary } from "./AccountPreviewLibrary.sol";

library TakerLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct TradeParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint24 mmRatio;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
        uint24 protocolFeeRatio;
        bool isSelf;
        PerpdexStructs.LiquidationRewardConfig liquidationRewardConfig;
    }

    struct PreviewTradeParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint24 mmRatio;
        uint24 protocolFeeRatio;
        bool isSelf;
    }

    struct TradeResponse {
        int256 base;
        int256 quote;
        int256 realizedPnl;
        uint256 protocolFee;
        uint256 liquidationPenalty;
        uint256 liquidationReward;
        uint256 insuranceFundReward;
        bool isLiquidation;
        IPerpdexMarketMinimum.SwapResponse rawResponse;
    }

    // to avoid stack too deep
    struct DoSwapParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint8 maxMarketsPerAccount;
        uint24 protocolFeeRatio;
        bool isLiquidation;
    }

    function trade(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.VaultInfo storage liquidatorVaultInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        TradeParams memory params
    ) internal returns (TradeResponse memory response) {
        response.isLiquidation = _validateTrade(accountInfo, params.market, params.isSelf, params.mmRatio, false);

        int256 takerBaseBefore = accountInfo.takerInfos[params.market].baseBalanceShare;

        (response.base, response.quote, response.realizedPnl, response.protocolFee, response.rawResponse) = _doSwap(
            accountInfo,
            protocolInfo,
            DoSwapParams({
                market: params.market,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                amount: params.amount,
                oppositeAmountBound: params.oppositeAmountBound,
                maxMarketsPerAccount: params.maxMarketsPerAccount,
                protocolFeeRatio: params.protocolFeeRatio,
                isLiquidation: response.isLiquidation
            })
        );

        bool isOpen = (takerBaseBefore.add(response.base)).sign() * response.base.sign() > 0;

        if (response.isLiquidation) {
            require(!isOpen, "TL_OP: no open when liquidation");

            (
                response.liquidationPenalty,
                response.liquidationReward,
                response.insuranceFundReward
            ) = processLiquidationReward(
                accountInfo.vaultInfo,
                liquidatorVaultInfo,
                insuranceFundInfo,
                params.mmRatio,
                params.liquidationRewardConfig,
                response.quote.abs()
            );
        }

        if (isOpen) {
            require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "TL_OP: not enough im");
        }
    }

    function addToTakerBalance(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        int256 baseShare,
        int256 quoteBalance,
        int256 quoteFee,
        uint8 maxMarketsPerAccount
    ) internal returns (int256 realizedPnl) {
        (accountInfo.takerInfos[market], realizedPnl) = AccountPreviewLibrary.previewAddToTakerBalance(
            accountInfo.takerInfos[market],
            baseShare,
            quoteBalance,
            quoteFee
        );

        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(realizedPnl);

        AccountLibrary.updateMarkets(accountInfo, market, maxMarketsPerAccount);
    }

    // Even if trade reverts, it may not revert.
    // Attempting to match reverts makes the implementation too complicated
    // ignored checks when liquidation:
    // - initial margin
    // - close only
    // - maker and limit order existence
    function previewTrade(PerpdexStructs.AccountInfo storage accountInfo, PreviewTradeParams memory params)
        internal
        view
        returns (uint256 oppositeAmount)
    {
        bool isLiquidation = _validateTrade(accountInfo, params.market, params.isSelf, params.mmRatio, true);

        oppositeAmount;
        if (params.protocolFeeRatio == 0) {
            oppositeAmount = IPerpdexMarketMinimum(params.market).previewSwap(
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                isLiquidation
            );
        } else {
            (oppositeAmount, ) = previewSwapWithProtocolFee(
                params.market,
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.protocolFeeRatio,
                isLiquidation
            );
        }
        validateSlippage(params.isExactInput, oppositeAmount, params.oppositeAmountBound);
    }

    // ignored checks when liquidation:
    // - initial margin
    // - close only
    // - maker and limit order existence
    function maxTrade(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 mmRatio,
        uint24 protocolFeeRatio,
        bool isSelf
    ) internal view returns (uint256 amount) {
        bool isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, mmRatio);

        if (!isSelf && !isLiquidation) {
            return 0;
        }

        if (protocolFeeRatio == 0) {
            amount = IPerpdexMarketMinimum(market).maxSwap(isBaseToQuote, isExactInput, isLiquidation);
        } else {
            amount = maxSwapWithProtocolFee(market, isBaseToQuote, isExactInput, protocolFeeRatio, isLiquidation);
        }
    }

    function _doSwap(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        DoSwapParams memory params
    )
        private
        returns (
            int256 base,
            int256 quote,
            int256 realizedPnl,
            uint256 protocolFee,
            IPerpdexMarketMinimum.SwapResponse memory rawResponse
        )
    {
        uint256 oppositeAmount;

        if (params.protocolFeeRatio > 0) {
            (oppositeAmount, protocolFee, rawResponse) = swapWithProtocolFee(
                protocolInfo,
                params.market,
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.protocolFeeRatio,
                params.isLiquidation
            );
        } else {
            rawResponse = IPerpdexMarketMinimum(params.market).swap(
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.isLiquidation
            );
            oppositeAmount = rawResponse.oppositeAmount;
        }
        validateSlippage(params.isExactInput, oppositeAmount, params.oppositeAmountBound);

        (base, quote) = swapResponseToBaseQuote(
            params.isBaseToQuote,
            params.isExactInput,
            params.amount,
            oppositeAmount
        );
        realizedPnl = addToTakerBalance(accountInfo, params.market, base, quote, 0, params.maxMarketsPerAccount);
    }

    function swapWithProtocolFee(
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    )
        internal
        returns (
            uint256 oppositeAmount,
            uint256 protocolFee,
            IPerpdexMarketMinimum.SwapResponse memory rawResponse
        )
    {
        if (isExactInput) {
            if (isBaseToQuote) {
                rawResponse = IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
                oppositeAmount = rawResponse.oppositeAmount;
                protocolFee = oppositeAmount.mulRatio(protocolFeeRatio);
                oppositeAmount = oppositeAmount.sub(protocolFee);
            } else {
                protocolFee = amount.mulRatio(protocolFeeRatio);
                rawResponse = IPerpdexMarketMinimum(market).swap(
                    isBaseToQuote,
                    isExactInput,
                    amount.sub(protocolFee),
                    isLiquidation
                );
                oppositeAmount = rawResponse.oppositeAmount;
            }
        } else {
            if (isBaseToQuote) {
                protocolFee = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio)).sub(amount);
                rawResponse = IPerpdexMarketMinimum(market).swap(
                    isBaseToQuote,
                    isExactInput,
                    amount.add(protocolFee),
                    isLiquidation
                );
                oppositeAmount = rawResponse.oppositeAmount;
            } else {
                rawResponse = IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
                uint256 oppositeAmountWithoutFee = rawResponse.oppositeAmount;
                oppositeAmount = oppositeAmountWithoutFee.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
                protocolFee = oppositeAmount.sub(oppositeAmountWithoutFee);
            }
        }

        protocolInfo.protocolFee = protocolInfo.protocolFee.add(protocolFee);
    }

    function processLiquidationReward(
        PerpdexStructs.VaultInfo storage vaultInfo,
        PerpdexStructs.VaultInfo storage liquidatorVaultInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        uint24 mmRatio,
        PerpdexStructs.LiquidationRewardConfig memory liquidationRewardConfig,
        uint256 exchangedQuote
    )
        internal
        returns (
            uint256 penalty,
            uint256 liquidationReward,
            uint256 insuranceFundReward
        )
    {
        penalty = exchangedQuote.mulRatio(mmRatio);
        liquidationReward = penalty.mulRatio(liquidationRewardConfig.rewardRatio);
        insuranceFundReward = penalty.sub(liquidationReward);

        (insuranceFundInfo.liquidationRewardBalance, liquidationReward) = _smoothLiquidationReward(
            insuranceFundInfo.liquidationRewardBalance,
            liquidationReward,
            liquidationRewardConfig.smoothEmaTime
        );

        vaultInfo.collateralBalance = vaultInfo.collateralBalance.sub(penalty.toInt256());
        liquidatorVaultInfo.collateralBalance = liquidatorVaultInfo.collateralBalance.add(liquidationReward.toInt256());
        insuranceFundInfo.balance = insuranceFundInfo.balance.add(insuranceFundReward);
    }

    function _smoothLiquidationReward(
        uint256 rewardBalance,
        uint256 reward,
        uint24 emaTime
    ) private pure returns (uint256 outputRewardBalance, uint256 outputReward) {
        rewardBalance = rewardBalance.add(reward);
        outputReward = rewardBalance.div(emaTime);
        outputRewardBalance = rewardBalance.sub(outputReward);
    }

    function previewSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal view returns (uint256 oppositeAmount, uint256 protocolFee) {
        if (isExactInput) {
            if (isBaseToQuote) {
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount,
                    isLiquidation
                );
                protocolFee = oppositeAmount.mulRatio(protocolFeeRatio);
                oppositeAmount = oppositeAmount.sub(protocolFee);
            } else {
                protocolFee = amount.mulRatio(protocolFeeRatio);
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount.sub(protocolFee),
                    isLiquidation
                );
            }
        } else {
            if (isBaseToQuote) {
                protocolFee = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio)).sub(amount);
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount.add(protocolFee),
                    isLiquidation
                );
            } else {
                uint256 oppositeAmountWithoutFee =
                    IPerpdexMarketMinimum(market).previewSwap(isBaseToQuote, isExactInput, amount, isLiquidation);
                oppositeAmount = oppositeAmountWithoutFee.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
                protocolFee = oppositeAmount.sub(oppositeAmountWithoutFee);
            }
        }
    }

    function maxSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal view returns (uint256 amount) {
        amount = IPerpdexMarketMinimum(market).maxSwap(isBaseToQuote, isExactInput, isLiquidation);

        if (isExactInput) {
            if (isBaseToQuote) {} else {
                amount = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
            }
        } else {
            if (isBaseToQuote) {
                amount = amount.mulRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
            } else {}
        }
    }

    function validateSlippage(
        bool isExactInput,
        uint256 oppositeAmount,
        uint256 oppositeAmountBound
    ) internal pure {
        if (isExactInput) {
            require(oppositeAmount >= oppositeAmountBound, "TL_VS: too small opposite amount");
        } else {
            require(oppositeAmount <= oppositeAmountBound, "TL_VS: too large opposite amount");
        }
    }

    function swapResponseToBaseQuote(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmount
    ) internal pure returns (int256, int256) {
        if (isExactInput) {
            if (isBaseToQuote) {
                return (amount.neg256(), oppositeAmount.toInt256());
            } else {
                return (oppositeAmount.toInt256(), amount.neg256());
            }
        } else {
            if (isBaseToQuote) {
                return (oppositeAmount.neg256(), amount.toInt256());
            } else {
                return (amount.toInt256(), oppositeAmount.neg256());
            }
        }
    }

    function _validateTrade(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isSelf,
        uint24 mmRatio,
        bool ignoreMakerOrderBookExistence
    ) private view returns (bool isLiquidation) {
        isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, mmRatio);

        if (!isSelf) {
            require(isLiquidation, "TL_VT: enough mm");
        }

        if (!ignoreMakerOrderBookExistence && isLiquidation) {
            require(accountInfo.makerInfos[market].liquidity == 0, "TL_VT: no maker when liquidation");
            require(accountInfo.limitOrderInfos[market].ask.root == 0, "TL_VT: no ask when liquidation");
            require(accountInfo.limitOrderInfos[market].bid.root == 0, "TL_VT: no bid when liquidation");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { PerpMath } from "./PerpMath.sol";
import { IERC20Metadata } from "../interfaces/IERC20Metadata.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";

library VaultLibrary {
    using PerpMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct DepositParams {
        address settlementToken;
        uint256 amount;
        address from;
    }

    struct WithdrawParams {
        address settlementToken;
        uint256 amount;
        address payable to;
        uint24 imRatio;
    }

    function compensate(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo
    ) external returns (uint256 compensation) {
        if (accountInfo.markets.length != 0) return 0;
        if (accountInfo.vaultInfo.collateralBalance >= 0) return 0;
        compensation = Math.min((-accountInfo.vaultInfo.collateralBalance).toUint256(), insuranceFundInfo.balance);
        accountInfo.vaultInfo.collateralBalance += compensation.toInt256();
        insuranceFundInfo.balance -= compensation;
    }

    function deposit(PerpdexStructs.AccountInfo storage accountInfo, DepositParams memory params) external {
        require(params.amount > 0, "VL_D: zero amount");
        _transferTokenIn(params.settlementToken, params.from, params.amount);
        uint256 collateralAmount =
            _toCollateralAmount(params.amount, IERC20Metadata(params.settlementToken).decimals());
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(
            collateralAmount.toInt256()
        );
    }

    function depositEth(PerpdexStructs.AccountInfo storage accountInfo, uint256 amount) external {
        require(amount > 0, "VL_DE: zero amount");
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
    }

    function withdraw(PerpdexStructs.AccountInfo storage accountInfo, WithdrawParams memory params) external {
        require(params.amount > 0, "VL_W: zero amount");

        uint256 collateralAmount =
            params.settlementToken == address(0)
                ? params.amount
                : _toCollateralAmount(params.amount, IERC20Metadata(params.settlementToken).decimals());
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.sub(
            collateralAmount.toInt256()
        );

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "VL_W: not enough initial margin");

        if (params.settlementToken == address(0)) {
            params.to.transfer(params.amount);
        } else {
            SafeERC20.safeTransfer(IERC20(params.settlementToken), params.to, params.amount);
        }
    }

    function transferProtocolFee(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        uint256 amount
    ) external {
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
        protocolInfo.protocolFee = protocolInfo.protocolFee.sub(amount);
    }

    function _transferTokenIn(
        address token,
        address from,
        uint256 amount
    ) private {
        // check for deflationary tokens by assuring balances before and after transferring to be the same
        uint256 balanceBefore = IERC20Metadata(token).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
        require(
            (IERC20Metadata(token).balanceOf(address(this)).sub(balanceBefore)) == amount,
            "VL_TTI: inconsistent balance"
        );
    }

    function _toCollateralAmount(uint256 amount, uint8 tokenDecimals) private pure returns (uint256) {
        int256 decimalsDiff = int256(18).sub(uint256(tokenDecimals).toInt256());
        uint256 decimalsDiffAbs = decimalsDiff.abs();
        require(decimalsDiffAbs <= 77, "VL_TCA: too large decimals diff");
        return decimalsDiff >= 0 ? amount.mul(10**decimalsDiffAbs) : amount.div(10**decimalsDiffAbs);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

library PerpMath {
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return Math.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return Math.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return Math.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -SafeCast.toInt256(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function subRatio(uint24 a, uint24 b) internal pure returns (uint24) {
        require(b <= a, "PerpMath: subtraction overflow");
        return a - b;
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, ratio, 1e6);
    }

    function mulRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, ratio, 1e6, Math.Rounding.Up);
    }

    function divRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, 1e6, ratio);
    }

    function divRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, 1e6, ratio, Math.Rounding.Up);
    }

    /// @param denominator cannot be 0 and is checked in Math.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = Math.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : SafeCast.toInt256(unsignedResult);

        return result;
    }

    function sign(int256 value) internal pure returns (int256) {
        return value > 0 ? int256(1) : (value < 0 ? int256(-1) : int256(0));
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

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsRedBlackTreeLibrary {
    struct Node {
        uint40 parent;
        uint40 left;
        uint40 right;
        bool red;
        uint128 userData; // use freely. this is for gas efficiency
    }

    struct Tree {
        uint40 root;
        mapping(uint40 => Node) nodes;
    }

    uint40 private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint40 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            _key = treeMinimum(self, self.root);
        }
    }

    function last(Tree storage self) internal view returns (uint40 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            _key = treeMaximum(self, self.root);
        }
    }

    function next(Tree storage self, uint40 target)
        internal
        view
        returns (uint40 cursor)
    {
        require(target != EMPTY, "RBTL_N: target is empty");
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function prev(Tree storage self, uint40 target)
        internal
        view
        returns (uint40 cursor)
    {
        require(target != EMPTY, "RBTL_P: target is empty");
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function exists(Tree storage self, uint40 key)
        internal
        view
        returns (bool)
    {
        return
            (key != EMPTY) &&
            ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    function isEmpty(uint40 key) internal pure returns (bool) {
        return key == EMPTY;
    }

    function getEmpty() internal pure returns (uint256) {
        return EMPTY;
    }

    function getNode(Tree storage self, uint40 key)
        internal
        view
        returns (
            uint40 _returnKey,
            uint40 _parent,
            uint40 _left,
            uint40 _right,
            bool _red
        )
    {
        require(exists(self, key), "RBTL_GN: key not exist");
        return (
            key,
            self.nodes[key].parent,
            self.nodes[key].left,
            self.nodes[key].right,
            self.nodes[key].red
        );
    }

    function insert(
        Tree storage self,
        uint40 key,
        uint128 userData,
        function(uint40, uint40, uint256) view returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_I: key is empty");
        require(!exists(self, key), "RBTL_I: key already exists");
        uint40 cursor = EMPTY;
        uint40 probe = self.root;
        self.nodes[key] = Node({
            parent: EMPTY,
            left: EMPTY,
            right: EMPTY,
            red: true,
            userData: userData
        });
        while (probe != EMPTY) {
            cursor = probe;
            if (lessThan(key, probe, data)) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key].parent = cursor;
        if (cursor == EMPTY) {
            self.root = key;
        } else if (lessThan(key, cursor, data)) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        aggregateRecursively(self, key, aggregate, data);
        insertFixup(self, key, aggregate, data);
    }

    function remove(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_R: key is empty");
        require(exists(self, key), "RBTL_R: key not exist");
        uint40 probe;
        uint40 cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint40 yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
            aggregateRecursively(self, key, aggregate, data);
        }
        if (doFixup) {
            removeFixup(self, probe, aggregate, data);
        }
        aggregateRecursively(self, yParent, aggregate, data);

        // Fixed a bug that caused the parent of empty nodes to be non-zero.
        // TODO: Fix it the right way.
        if (probe == EMPTY) {
            self.nodes[probe].parent = EMPTY;
        }
    }

    // https://arxiv.org/pdf/1602.02120.pdf
    // changes from original
    // - handle empty
    // - handle parent
    // - change root to black

    // to avoid stack too deep
    struct JoinParams {
        uint40 left;
        uint40 key;
        uint40 right;
        uint8 leftBlackHeight;
        uint8 rightBlackHeight;
        uint256 data;
    }

    // destructive func
    function joinRight(
        Tree storage self,
        JoinParams memory params,
        function(uint40, uint256) returns (bool) aggregate
    ) private returns (uint40, uint8) {
        if (
            !self.nodes[params.left].red &&
            params.leftBlackHeight == params.rightBlackHeight
        ) {
            self.nodes[params.key].red = true;
            self.nodes[params.key].left = params.left;
            self.nodes[params.key].right = params.right;
            aggregate(params.key, params.data);
            return (params.key, params.leftBlackHeight);
        }

        (uint40 t, ) = joinRight(
            self,
            JoinParams({
                left: self.nodes[params.left].right,
                key: params.key,
                right: params.right,
                leftBlackHeight: params.leftBlackHeight -
                    (self.nodes[params.left].red ? 0 : 1),
                rightBlackHeight: params.rightBlackHeight,
                data: params.data
            }),
            aggregate
        );
        self.nodes[params.left].right = t;
        self.nodes[params.left].parent = EMPTY;
        aggregate(params.left, params.data);

        if (
            !self.nodes[params.left].red &&
            self.nodes[t].red &&
            self.nodes[self.nodes[t].right].red
        ) {
            self.nodes[self.nodes[t].right].red = false;
            rotateLeft(self, params.left, aggregate, params.data);
            return (t, params.leftBlackHeight);
            //            return (self.nodes[params.left].parent, tBlackHeight + 1); // TODO: replace with t
        }
        return (params.left, params.leftBlackHeight);
        //        return (params.left, tBlackHeight + (self.nodes[params.left].red ? 0 : 1));
    }

    // destructive func
    function joinLeft(
        Tree storage self,
        JoinParams memory params,
        function(uint40, uint256) returns (bool) aggregate
    ) internal returns (uint40 resultKey) {
        if (
            !self.nodes[params.right].red &&
            params.leftBlackHeight == params.rightBlackHeight
        ) {
            self.nodes[params.key].red = true;
            self.nodes[params.key].left = params.left;
            self.nodes[params.key].right = params.right;
            if (params.left != EMPTY) {
                self.nodes[params.left].parent = params.key;
            }
            if (params.right != EMPTY) {
                self.nodes[params.right].parent = params.key;
            }
            aggregate(params.key, params.data);
            return params.key;
        }

        uint40 t = joinLeft(
            self,
            JoinParams({
                left: params.left,
                key: params.key,
                right: self.nodes[params.right].left,
                leftBlackHeight: params.leftBlackHeight,
                rightBlackHeight: params.rightBlackHeight -
                    (self.nodes[params.right].red ? 0 : 1),
                data: params.data
            }),
            aggregate
        );
        self.nodes[params.right].left = t;
        self.nodes[params.right].parent = EMPTY;
        if (t != EMPTY) {
            self.nodes[t].parent = params.right;
        }
        aggregate(params.right, params.data);

        if (
            !self.nodes[params.right].red &&
            self.nodes[t].red &&
            self.nodes[self.nodes[t].left].red
        ) {
            self.nodes[self.nodes[t].left].red = false;
            rotateRight(self, params.right, aggregate, params.data);
            return t;
        }
        return params.right;
    }

    // destructive func
    function join(
        Tree storage self,
        uint40 left,
        uint40 key,
        uint40 right,
        function(uint40, uint256) returns (bool) aggregate,
        uint8 leftBlackHeight,
        uint8 rightBlackHeight,
        uint256 data
    ) private returns (uint40 t, uint8 tBlackHeight) {
        if (leftBlackHeight > rightBlackHeight) {
            (t, tBlackHeight) = joinRight(
                self,
                JoinParams({
                    left: left,
                    key: key,
                    right: right,
                    leftBlackHeight: leftBlackHeight,
                    rightBlackHeight: rightBlackHeight,
                    data: data
                }),
                aggregate
            );
            tBlackHeight = leftBlackHeight;
            if (self.nodes[t].red && self.nodes[self.nodes[t].right].red) {
                self.nodes[t].red = false;
                tBlackHeight += 1;
            }
        } else if (leftBlackHeight < rightBlackHeight) {
            t = joinLeft(
                self,
                JoinParams({
                    left: left,
                    key: key,
                    right: right,
                    leftBlackHeight: leftBlackHeight,
                    rightBlackHeight: rightBlackHeight,
                    data: data
                }),
                aggregate
            );
            tBlackHeight = rightBlackHeight;
            if (self.nodes[t].red && self.nodes[self.nodes[t].left].red) {
                self.nodes[t].red = false;
                tBlackHeight += 1;
            }
        } else {
            bool red = !self.nodes[left].red && !self.nodes[right].red;
            self.nodes[key].red = red;
            self.nodes[key].left = left;
            self.nodes[key].right = right;
            aggregate(key, data);
            (t, tBlackHeight) = (key, leftBlackHeight + (red ? 0 : 1));
        }
    }

    struct SplitParams {
        uint40 t;
        uint40 key;
        uint8 blackHeight;
        uint256 data;
    }

    // destructive func
    function splitRight(
        Tree storage self,
        SplitParams memory params,
        function(uint40, uint40, uint256) returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        function(uint40, uint256) subtreeRemoved
    ) private returns (uint40 resultKey, uint8 resultBlackHeight) {
        if (params.t == EMPTY) return (EMPTY, params.blackHeight);
        params.blackHeight -= (self.nodes[params.t].red ? 0 : 1);
        if (params.key == params.t) {
            subtreeRemoved(params.t, params.data);
            return (self.nodes[params.t].right, params.blackHeight);
        }
        if (lessThan(params.key, params.t, params.data)) {
            (uint40 r, uint8 rBlackHeight) = splitRight(
                self,
                SplitParams({
                    t: self.nodes[params.t].left,
                    key: params.key,
                    blackHeight: params.blackHeight,
                    data: params.data
                }),
                lessThan,
                aggregate,
                subtreeRemoved
            );
            return
                join(
                    self,
                    r,
                    params.t,
                    self.nodes[params.t].right,
                    aggregate,
                    rBlackHeight,
                    params.blackHeight,
                    params.data
                );
        } else {
            subtreeRemoved(params.t, params.data);
            return
                splitRight(
                    self,
                    SplitParams({
                        t: self.nodes[params.t].right,
                        key: params.key,
                        blackHeight: params.blackHeight,
                        data: params.data
                    }),
                    lessThan,
                    aggregate,
                    subtreeRemoved
                );
        }
    }

    function removeLeft(
        Tree storage self,
        uint40 key,
        function(uint40, uint40, uint256) returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        function(uint40, uint256) subtreeRemoved,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_RL: key is empty");
        require(exists(self, key), "RBTL_RL: key not exist");
        (self.root, ) = splitRight(
            self,
            SplitParams({t: self.root, key: key, blackHeight: 128, data: data}),
            lessThan,
            aggregate,
            subtreeRemoved
        );
        self.nodes[self.root].parent = EMPTY;
        self.nodes[self.root].red = false;
    }

    function aggregateRecursively(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        while (key != EMPTY) {
            if (aggregate(key, data)) return;
            key = self.nodes[key].parent;
        }
    }

    function treeMinimum(Tree storage self, uint40 key)
        private
        view
        returns (uint40)
    {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    function treeMaximum(Tree storage self, uint40 key)
        private
        view
        returns (uint40)
    {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor = self.nodes[key].right;
        uint40 keyParent = self.nodes[key].parent;
        uint40 cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
        aggregate(key, data);
        aggregate(cursor, data);
    }

    function rotateRight(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor = self.nodes[key].left;
        uint40 keyParent = self.nodes[key].parent;
        uint40 cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
        aggregate(key, data);
        aggregate(cursor, data);
    }

    function insertFixup(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint40 keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key, aggregate, data);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(
                        self,
                        self.nodes[keyParent].parent,
                        aggregate,
                        data
                    );
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key, aggregate, data);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(
                        self,
                        self.nodes[keyParent].parent,
                        aggregate,
                        data
                    );
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(
        Tree storage self,
        uint40 a,
        uint40 b
    ) private {
        uint40 bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint40 keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent, aggregate, data);
                    cursor = self.nodes[keyParent].right;
                }
                if (
                    !self.nodes[self.nodes[cursor].left].red &&
                    !self.nodes[self.nodes[cursor].right].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor, aggregate, data);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent, aggregate, data);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent, aggregate, data);
                    cursor = self.nodes[keyParent].left;
                }
                if (
                    !self.nodes[self.nodes[cursor].right].red &&
                    !self.nodes[self.nodes[cursor].left].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor, aggregate, data);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent, aggregate, data);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpMath } from "./PerpMath.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

// This is a technical library to avoid circular references between libraries
library AccountPreviewLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using RBTreeLibrary for RBTreeLibrary.Tree;

    struct Execution {
        int256 executedBase;
        int256 executedQuote;
    }

    function getLimitOrderExecutions(PerpdexStructs.AccountInfo storage accountInfo, address market)
        internal
        view
        returns (
            Execution[] memory executions,
            uint40 executedLastAskOrderId,
            uint40 executedLastBidOrderId
        )
    {
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];

        uint40 ask = limitOrderInfo.ask.first();
        uint40 bid = limitOrderInfo.bid.first();
        uint256 executionIdAsk;
        uint256 executedBaseAsk;
        uint256 executedQuoteAsk;
        uint256 executionIdBid;
        uint256 executedBaseBid;
        uint256 executedQuoteBid;
        if (ask != 0) {
            (executionIdAsk, executedBaseAsk, executedQuoteAsk) = IPerpdexMarketMinimum(market).getLimitOrderExecution(
                false,
                ask
            );
            if (executionIdAsk == 0) {
                ask = 0;
            }
        }
        if (bid != 0) {
            (executionIdBid, executedBaseBid, executedQuoteBid) = IPerpdexMarketMinimum(market).getLimitOrderExecution(
                true,
                bid
            );
            if (executionIdBid == 0) {
                bid = 0;
            }
        }

        // Combine the ask and bid and process from the one with the smallest executionId.
        // Ask and bid are already sorted and can be processed like merge sort.
        Execution[256] memory executions2;
        uint256 executionCount;
        while (ask != 0 || bid != 0) {
            if (ask != 0 && (bid == 0 || executionIdAsk < executionIdBid)) {
                executions2[executionCount] = Execution({
                    executedBase: executedBaseAsk.neg256(),
                    executedQuote: executedQuoteAsk.toInt256()
                });
                ++executionCount;

                uint40 nextAsk = limitOrderInfo.ask.next(ask);
                if (nextAsk != 0) {
                    (executionIdAsk, executedBaseAsk, executedQuoteAsk) = IPerpdexMarketMinimum(market)
                        .getLimitOrderExecution(false, nextAsk);
                }
                if (executionIdAsk == 0 || nextAsk == 0) {
                    executedLastAskOrderId = ask;
                    ask = 0;
                } else {
                    ask = nextAsk;
                }
            } else {
                executions2[executionCount] = Execution({
                    executedBase: executedBaseBid.toInt256(),
                    executedQuote: executedQuoteBid.neg256()
                });
                ++executionCount;

                uint40 nextBid = limitOrderInfo.bid.next(bid);
                if (nextBid != 0) {
                    (executionIdBid, executedBaseBid, executedQuoteBid) = IPerpdexMarketMinimum(market)
                        .getLimitOrderExecution(true, nextBid);
                }
                if (executionIdBid == 0 || nextBid == 0) {
                    executedLastBidOrderId = bid;
                    bid = 0;
                } else {
                    bid = nextBid;
                }
            }
        }

        executions = new Execution[](executionCount);
        for (uint256 i = 0; i < executionCount; i++) {
            executions[i] = executions2[i];
        }
    }

    function previewSettleLimitOrders(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        Execution[] memory executions
    )
        internal
        view
        returns (
            PerpdexStructs.TakerInfo memory takerInfo,
            int256 realizedPnl,
            uint256 totalExecutedBaseAsk,
            uint256 totalExecutedBaseBid
        )
    {
        takerInfo = accountInfo.takerInfos[market];

        uint256 length = executions.length;
        for (uint256 i = 0; i < length; ++i) {
            int256 realizedPnl2;
            (takerInfo, realizedPnl2) = previewAddToTakerBalance(
                takerInfo,
                executions[i].executedBase,
                executions[i].executedQuote,
                0
            );
            realizedPnl += realizedPnl2;
            if (executions[i].executedBase >= 0) {
                totalExecutedBaseBid += executions[i].executedBase.abs();
            } else {
                totalExecutedBaseAsk += executions[i].executedBase.abs();
            }
        }
    }

    function previewAddToTakerBalance(
        PerpdexStructs.TakerInfo memory takerInfo,
        int256 baseShare,
        int256 quoteBalance,
        int256 quoteFee
    ) internal pure returns (PerpdexStructs.TakerInfo memory resultTakerInfo, int256 realizedPnl) {
        if (baseShare != 0 || quoteBalance != 0) {
            if (baseShare.sign() * quoteBalance.sign() != -1) {
                // ignore invalid input
                return (takerInfo, 0);
            }
            if (takerInfo.baseBalanceShare.sign() * baseShare.sign() == -1) {
                uint256 baseAbs = baseShare.abs();
                uint256 takerBaseAbs = takerInfo.baseBalanceShare.abs();

                if (baseAbs <= takerBaseAbs) {
                    int256 reducedOpenNotional = takerInfo.quoteBalance.mulDiv(baseAbs.toInt256(), takerBaseAbs);
                    realizedPnl = quoteBalance.add(reducedOpenNotional);
                } else {
                    int256 closedPositionNotional = quoteBalance.mulDiv(takerBaseAbs.toInt256(), baseAbs);
                    realizedPnl = takerInfo.quoteBalance.add(closedPositionNotional);
                }
            }
        }
        realizedPnl = realizedPnl.add(quoteFee);

        int256 newBaseBalanceShare = takerInfo.baseBalanceShare.add(baseShare);
        int256 newQuoteBalance = takerInfo.quoteBalance.add(quoteBalance).add(quoteFee).sub(realizedPnl);
        if (
            !((newBaseBalanceShare == 0 && newQuoteBalance == 0) ||
                newBaseBalanceShare.sign() * newQuoteBalance.sign() == -1)
        ) {
            // never occur. ignore
            return (takerInfo, 0);
        }

        resultTakerInfo.baseBalanceShare = newBaseBalanceShare;
        resultTakerInfo.quoteBalance = newQuoteBalance;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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