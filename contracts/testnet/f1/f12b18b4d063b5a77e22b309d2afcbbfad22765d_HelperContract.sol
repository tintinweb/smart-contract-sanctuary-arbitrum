/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;
import "@JOJO/contracts/intf/IDealer.sol";
import "@JOJO/contracts/intf/IPerpetual.sol";
import "@JUSDV1/src/Impl/JUSDBank.sol";
import "@JOJO/contracts/lib/Types.sol";
import "../Impl/FundingRateArbitrage.sol";

contract HelperContract {

    IDealer public JOJODealer;
    JUSDBank public jusdBank;
    FundingRateArbitrage public fundingRateArbitrage;

    constructor(address _JOJODealer, address _JUSDBank, address _FundingRateArbitrage) {
        JOJODealer = IDealer(_JOJODealer);
        jusdBank = JUSDBank(_JUSDBank);
        fundingRateArbitrage = FundingRateArbitrage(_FundingRateArbitrage);
    }
    struct CollateralState {
        address collateral;
        uint256 balance;
    }
    struct AccountJUSDState {
        address account;
        uint256 borrowedBalance;
        bool isSafe;
        CollateralState[] collateralState;
    }
    struct AccountPerpState {
        address perp;
        int256 paper;
        int256 credit;
        uint256 liquidatePrice;
    }
    struct AccountState {
        address accountAddress;
        int256 primaryCredit;
        uint256 secondaryCredit;
        uint256 pendingPrimaryWithdraw;
        uint256 pendingSecondaryWithdraw;
        uint256 exposure;
        int256 netValue;
        uint256 initialMargin;
        uint256 maintenanceMargin;
        bool isSafe;
        uint256 executionTimestamp;
        AccountPerpState[] accountPerpState;
    }
    struct PerpState {
        address perp;
        int256 fundingRate;
        uint256 markPrice;
        Types.RiskParams riskParams;
    }

    struct HedgingState {
        uint256 USDCWalletBalance;
        int256 USDCPerpBalance;
        uint256 wstETHWalletBalance;
        uint256 wstETHBankAmount;
        uint256 JUSDBorrowAmount;
        uint256 JUSDPerpBalance;
        int256 PositionPerpAmount;
        int256 PositionCreditAmount;
        uint256 earnUSDCRate;
    }

    function getWalletBalance(address token, address wallet) public view returns(uint256) {
        return IERC20(token).balanceOf(wallet);
    }
    function getPerpaBalance(address wallet, address perpetual) public view returns(HedgingState memory hedgingState) {
       (
            int256 primaryCredit,
            uint256 secondaryCredit,,,
        ) = IDealer(JOJODealer).getCreditOf(wallet);
        hedgingState.USDCPerpBalance = primaryCredit;
        hedgingState.JUSDPerpBalance = secondaryCredit;
        uint256 USDCWalletBalance = IERC20(jusdBank.primaryAsset()).balanceOf(wallet);
        hedgingState.USDCWalletBalance = USDCWalletBalance;
        uint256 wstETHWalletBalance = IERC20(fundingRateArbitrage.Collateral()).balanceOf(wallet);
        hedgingState.wstETHWalletBalance = wstETHWalletBalance;
        uint256 wstETHBankAmount = jusdBank.getDepositBalance(fundingRateArbitrage.Collateral(), wallet);
        hedgingState.wstETHBankAmount = wstETHBankAmount;
        uint256 JUSDBorrowAmount = jusdBank.getBorrowBalance(wallet);
        hedgingState.JUSDBorrowAmount = JUSDBorrowAmount;
        (int256 PositionPerpAmount, int256 PositionCreditAmount) = IPerpetual(perpetual).balanceOf(wallet);
        hedgingState.PositionPerpAmount = PositionPerpAmount;
        hedgingState.PositionCreditAmount = PositionCreditAmount;
        uint256 index = fundingRateArbitrage.getIndex();
        hedgingState.earnUSDCRate = index;
    }
    
    function getAccountsStates(
        address[] calldata accounts
    ) public view returns (AccountState[] memory accountStates) {
        accountStates = new AccountState[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountStates[i].accountAddress = accounts[i];
            {
                (
                int256 primaryCredit,
                uint256 secondaryCredit,
                uint256 pendingPrimaryWithdraw,
                uint256 pendingSecondaryWithdraw,
                uint256 executionTimestamp
                ) = IDealer(JOJODealer).getCreditOf(accounts[i]);
                accountStates[i].primaryCredit = primaryCredit;
                accountStates[i].secondaryCredit = secondaryCredit;
                accountStates[i]
                .pendingPrimaryWithdraw = pendingPrimaryWithdraw;
                accountStates[i]
                .pendingSecondaryWithdraw = pendingSecondaryWithdraw;
                accountStates[i].executionTimestamp = executionTimestamp;
            }
            (
            int256 netValue,
            uint256 exposure,
            uint256 initialMargin,
            uint256 maintenanceMargin
        ) = IDealer(JOJODealer).getTraderRisk(accounts[i]);
            accountStates[i].netValue = netValue;
            accountStates[i].exposure = exposure;
            accountStates[i].initialMargin = initialMargin;
            accountStates[i].maintenanceMargin = maintenanceMargin;
            accountStates[i].isSafe = IDealer(JOJODealer).isSafe(accounts[i]);
            address[] memory perp = IDealer(JOJODealer).getPositions(
                accounts[i]
            );
            accountStates[i].accountPerpState = new AccountPerpState[](perp.length);
            for (uint256 j = 0; j < perp.length; j++) {
                (int256 paper, int256 credit) = IPerpetual(perp[j]).balanceOf(
                    accounts[i]
                );
                accountStates[i].accountPerpState[j].perp = perp[j];
                accountStates[i].accountPerpState[j].paper = paper;
                accountStates[i].accountPerpState[j].credit = credit;
                accountStates[i].accountPerpState[j].liquidatePrice = IDealer(
                    JOJODealer
                ).getLiquidationPrice(accounts[i], perp[j]);
            }
        }
    }
    function getPerpsStates(
        address[] calldata perps
    ) public view returns (PerpState[] memory perpStates) {
        perpStates = new PerpState[](perps.length);
        for (uint256 i = 0; i < perps.length; i++) {
            perpStates[i].perp = perps[i];
            perpStates[i].fundingRate = IDealer(JOJODealer).getFundingRate(
                perps[i]
            );
            perpStates[i].markPrice = IDealer(JOJODealer).getMarkPrice(
                perps[i]
            );
            perpStates[i].riskParams = IDealer(JOJODealer).getRiskParams(
                perps[i]
            );
        }
    }
    function getPerpPaperBalances(
        address perp,
        address[] calldata accounts
    ) public view returns (int256[] memory paperAmount) {
        paperAmount = new int256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            (int256 paper, ) = IPerpetual(perp).balanceOf(accounts[i]);
            paperAmount[i] = paper;
        }
    }
    function getAccountJUSDStates(
        address[] calldata accounts
    ) public view returns (AccountJUSDState[] memory accountJUSDState) {
        accountJUSDState = new AccountJUSDState[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountJUSDState[i].account = accounts[i];
            accountJUSDState[i].borrowedBalance = jusdBank.getBorrowBalance(
                accounts[i]
            );
            accountJUSDState[i].isSafe = jusdBank.isAccountSafe(accounts[i]);
            address[] memory collaterals = jusdBank.getUserCollateralList(
                accounts[i]
            );
            accountJUSDState[i].collateralState = new CollateralState[](collaterals.length);
            for (uint256 j = 0; j < collaterals.length; j++) {
                accountJUSDState[i].collateralState[j].collateral = collaterals[
                j
                ];
                accountJUSDState[i].collateralState[j].balance = jusdBank
                .getDepositBalance(collaterals[j], accounts[i]);
            }
        }
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
*/

pragma solidity 0.8.9;

import "../lib/Types.sol";

interface IDealer {
    /// @notice Deposit fund to get credit for trading
    /// @param primaryAmount is the amount of primary asset you want to deposit.
    /// @param secondaryAmount is the amount of secondary asset you want to deposit.
    /// @param to is the account you want to deposit to.
    function deposit(
        uint256 primaryAmount,
        uint256 secondaryAmount,
        address to
    ) external;

    /// @notice Submit withdrawal request, which can be executed after
    /// the timelock. The main purpose of this function is to avoid the
    /// failure of counterparty caused by withdrawal.
    /// @param from The deducted account.
    /// @param primaryAmount is the amount of primary asset you want to withdraw.
    /// @param secondaryAmount is the amount of secondary asset you want to withdraw.
    function requestWithdraw(
        address from, 
        uint256 primaryAmount, 
        uint256 secondaryAmount
    ) external;

    /// @notice Execute the withdrawal request.
    /// @param from The deducted account.
    /// @param to is the address receiving assets.
    /// @param isInternal Only internal credit transfers will be made,
    /// and ERC20 transfers will not happen.
    /// @param param call "to" with param if not null. 
    function executeWithdraw(
        address from, 
        address to, 
        bool isInternal,
        bytes memory param
    ) external;

    /// @notice Withdraw without waiting.
    /// @param from The deducted account.
    /// @param to is the address receiving assets.
    /// @param primaryAmount is the amount of primary asset you want to withdraw.
    /// @param secondaryAmount is the amount of secondary asset you want to 
    /// @param isInternal Only internal credit transfers will be made,
    /// and ERC20 transfers will not happen.
    /// @param param call "to" with param if not null. 
    function fastWithdraw(
        address from,
        address to,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        bool isInternal,
        bytes memory param
    ) external;

    /// @notice Help perpetual contract parse tradeData and return
    /// the balance changes of each trader.
    /// @dev only perpetual contract can call this function
    /// @param orderSender is the one who submit tradeData.
    /// @param tradeData contains orders, signatures and match info.
    function approveTrade(address orderSender, bytes calldata tradeData)
        external
        returns (
            address[] memory traderList,
            int256[] memory paperChangeList,
            int256[] memory creditChangeList
        );

    /// @notice Check if the trader's margin is enough (>= maintenance margin).
    /// If so, the trader is "safe".
    /// The trader's positions under all markets will be liquidated if he is
    /// not safe.
    function isSafe(address trader) external view returns (bool);

    /// @notice Check if a list of traders are safe.
    /// @dev This function is more gas effective than isSafe, by caching
    /// mark prices.
    function isAllSafe(address[] calldata traderList)
        external
        view
        returns (bool);

    /// @notice Get funding rate of a perpetual market.
    /// Funding rate is a 1e18 based decimal.
    function getFundingRate(address perp) external view returns (int256);

    /// @notice Update multiple funding rate at once.
    /// Can only be called by funding rate keeper.
    function updateFundingRate(
        address[] calldata perpList,
        int256[] calldata rateList
    ) external;

    /// @notice Calculate the paper and credit change of liquidator and
    /// liquidated trader.
    /// @dev Only perpetual contract can call this function.
    /// liqtor is short for liquidator, liqed is short for liquidated trader.
    /// @param liquidator is the one who will take over positions.
    /// @param liquidatedTrader is the one who is being liquidated.
    /// @param requestPaperAmount is the size that the liquidator wants to take.
    /// Positive if the position is long, negative if the position is short.
    function requestLiquidation(
        address executor,
        address liquidator,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        returns (
            int256 liqtorPaperChange,
            int256 liqtorCreditChange,
            int256 liqedPaperChange,
            int256 liqedCreditChange
        );

    /// @notice Transfer all bad debt to insurance account,
    /// including primary and secondary balances.
    function handleBadDebt(address liquidatedTrader) external;

    /// @notice Register the trader's position into dealer.
    /// @dev Only perpetual contract can call this function when
    /// someone's position is opened.
    function openPosition(address trader) external;

    /// @notice Accrual realized pnl and remove the trader's position from dealer.
    /// @dev Only perpetual contract can call this function when
    /// someone's position is closed.
    function realizePnl(address trader, int256 pnl) external;

    /// @notice Register operator.
    /// The operator can sign order on your behalf.
    function setOperator(address operator, bool isValid) external;

    /// @param perp the address of perpetual contract market
    function getRiskParams(address perp)
        external
        view
        returns (Types.RiskParams memory params);

    /// @notice Return all registered perpetual contract market.
    function getAllRegisteredPerps() external view returns (address[] memory);

    /// @notice Return mark price of a perpetual market.
    /// price is a 1e18 based decimal.
    function getMarkPrice(address perp) external view returns (uint256);

    /// @notice Get all open positions of the trader.
    function getPositions(address trader)
        external
        view
        returns (address[] memory);

    /// @notice Return the credit details of the trader.
    /// You cannot use credit as net value or net margin of a trader.
    /// The net value of positions would also be included.
    function getCreditOf(address trader)
        external
        view
        returns (
            int256 primaryCredit,
            uint256 secondaryCredit,
            uint256 pendingPrimaryWithdraw,
            uint256 pendingSecondaryWithdraw,
            uint256 executionTimestamp
        );

    /// @notice Get the risk profile data of a trader.
    /// @return netValue net value of trader including credit amount
    /// @return exposure open position value of the trader across all markets
    /// @return initialMargin Funds required to open a position.
    /// @return maintenanceMargin Funds needed to keep a position open.
    function getTraderRisk(address trader)
        external
        view
        returns (
            int256 netValue,
            uint256 exposure,
            uint256 initialMargin,
            uint256 maintenanceMargin
        );

    /// @notice Get liquidation price of a position
    /// @dev This function is for directional use. The margin of error is typically
    /// within 10 wei.
    /// @return liquidationPrice equals 0 if there is no liquidation price.
    function getLiquidationPrice(address trader, address perp)
        external
        view
        returns (uint256 liquidationPrice);

    /// @notice a view version of requestLiquidation, liquidators can use
    /// this function to check how much you have to pay in advance.
    function getLiquidationCost(
        address perp,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        view
        returns (int256 liqtorPaperChange, int256 liqtorCreditChange);

    /// @notice Get filled paper amount of an order to avoid double matching.
    /// @return filledAmount includes paper amount
    function getOrderFilledAmount(bytes32 orderHash)
        external
        view
        returns (uint256 filledAmount);

    /// @notice check if order sender is valid
    function isOrderSenderValid(address orderSender)
        external
        view
        returns (bool);

    function isFastWithdrawalValid(address fastWithdrawOperator)
        external
        view
        returns (bool);

    /// @notice check if operator is valid
    function isOperatorValid(address client, address operator)
        external
        view
        returns (bool);
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
*/

pragma solidity 0.8.9;

interface IPerpetual {
    /// @notice Return the paper amount and credit amount of a certain trader.
    /// @return paper is positive when the trader holds a long position and
    /// negative when the trader holds a short position.
    /// @return credit is not related to position direction or entry price,
    /// only used to calculate risk ratio and net value.
    function balanceOf(address trader)
        external
        view
        returns (int256 paper, int256 credit);

    /// @notice Match and settle orders.
    /// @dev tradeData will be forwarded to the Dealer contract and waiting
    /// for matching result. Then the Perpetual contract will execute the result.
    function trade(bytes calldata tradeData) external;

    /// @notice Liquidate a position with customized paper amount and price protection.
    /// @dev Because the liquidation is open to public, there is no guarantee that
    /// your request will be executed.
    /// It will not be executed or partially executed if:
    /// 1) someone else submitted a liquidation request before you, or
    /// 2) the trader deposited enough margin in time, or
    /// 3) the mark price moved beyond your price protection.
    /// Your liquidation will be limited to the position size. For example, if the
    /// position remains 10ETH and you're requesting a 15ETH liquidation. Only 10ETH
    /// will be executed. And the other 5ETH request will be cancelled.
    /// @param  liquidatedTrader is the trader you want to liquidate.
    /// @param  requestPaper is the size of position you want to take .
    /// requestPaper is positive when you want to liquidate a long position, negative when short.
    /// @param expectCredit is the amount of credit you want to pay (when liquidating a short position)
    /// or receive (when liquidating a long position)
    /// @return liqtorPaperChange is the final executed change of liquidator's paper amount
    /// @return liqtorCreditChange is the final executed change of liquidator's credit amount
    function liquidate(
        address liquidator,
        address liquidatedTrader,
        int256 requestPaper,
        int256 expectCredit
    ) external returns (int256 liqtorPaperChange, int256 liqtorCreditChange);

    /// @notice Get funding rate of this perpetual market.
    /// Funding rate is a 1e18 based decimal.
    function getFundingRate() external view returns (int256);

    /// @notice Update funding rate, owner only function.
    function updateFundingRate(int256 newFundingRate) external;
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

import "../Interface/IJUSDBank.sol";
import "../Interface/IFlashLoanReceive.sol";
import "./JUSDBankStorage.sol";
import "./JUSDOperation.sol";
import "./JUSDView.sol";
import "./JUSDMulticall.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@JOJO/contracts/intf/IDealer.sol";
import {IPriceChainLink} from "../Interface/IPriceChainLink.sol";

contract JUSDBank is IJUSDBank, JUSDOperation, JUSDView, JUSDMulticall {
    using DecimalMath for uint256;
    using SafeERC20 for IERC20;

    constructor(
        uint256 _maxReservesNum,
        address _insurance,
        address _JUSD,
        address _JOJODealer,
        uint256 _maxPerAccountBorrowAmount,
        uint256 _maxTotalBorrowAmount,
        uint256 _borrowFeeRate,
        address _primaryAsset
    ) {
        maxReservesNum = _maxReservesNum;
        JUSD = _JUSD;
        JOJODealer = _JOJODealer;
        insurance = _insurance;
        maxPerAccountBorrowAmount = _maxPerAccountBorrowAmount;
        maxTotalBorrowAmount = _maxTotalBorrowAmount;
        borrowFeeRate = _borrowFeeRate;
        tRate = JOJOConstant.ONE;
        primaryAsset = _primaryAsset;
        lastUpdateTimestamp = uint32(block.timestamp);
    }

    // --------------------------event-----------------------

    event HandleBadDebt(address indexed liquidatedTrader, uint256 borrowJUSDT0);
    event Deposit(
        address indexed collateral,
        address indexed from,
        address indexed to,
        address operator,
        uint256 amount
    );
    event Borrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        bool isDepositToJOJO
    );
    event Repay(address indexed from, address indexed to, uint256 amount);
    event Withdraw(
        address indexed collateral,
        address indexed from,
        address indexed to,
        uint256 amount,
        bool ifInternal
    );
    event Liquidate(
        address indexed collateral,
        address indexed liquidator,
        address indexed liquidated,
        address operator,
        uint256 collateralAmount,
        uint256 liquidatedAmount,
        uint256 insuranceFee
    );
    event FlashLoan(address indexed collateral, uint256 amount);

    /// @notice to ensure msg.sender is from account or msg.sender is the sub account of from
    /// so that msg.sender can send the transaction
    modifier isValidOperator(address operator, address client) {
        require(
            msg.sender == client || operatorRegistry[client][operator],
            JUSDErrors.CAN_NOT_OPERATE_ACCOUNT
        );
        _;
    }
    modifier isLiquidator(address liquidator) {
        if(isLiquidatorWhitelistOpen){
            require(isLiquidatorWhiteList[liquidator], "liquidator is not in the liquidator white list");
        }
        _;
    }

    function deposit(
        address from,
        address collateral,
        uint256 amount,
        address to
    ) external override nonReentrant isValidOperator(msg.sender, from) {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        DataTypes.UserInfo storage user = userInfo[to];
        //        deposit
        _deposit(reserve, user, amount, collateral, to, from);
    }

    function borrow(
        uint256 amount,
        address to,
        bool isDepositToJOJO
    ) external override nonReentrant nonFlashLoanReentrant{
        //     t0BorrowedAmount = borrowedAmount /  getT0Rate
        DataTypes.UserInfo storage user = userInfo[msg.sender];
        accrueRate();
        _borrow(user, isDepositToJOJO, to, amount, msg.sender);
        require(
            _isAccountSafe(user, tRate),
            JUSDErrors.AFTER_BORROW_ACCOUNT_IS_NOT_SAFE
        );
    }

    function repay(
        uint256 amount,
        address to
    ) external override nonReentrant returns (uint256) {
        DataTypes.UserInfo storage user = userInfo[to];
        accrueRate();
        return _repay(user, msg.sender, to, amount, tRate);
    }

    function withdraw(
        address collateral,
        uint256 amount,
        address to,
        bool isInternal
    ) external override nonReentrant nonFlashLoanReentrant{
        DataTypes.UserInfo storage user = userInfo[msg.sender];
        _withdraw(amount, collateral, to, msg.sender, isInternal);
        uint256 tRate = getTRate();
        require(
            _isAccountSafe(user, tRate),
            JUSDErrors.AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE
        );
    }

    function liquidate(
        address liquidated,
        address collateral,
        address liquidator,
        uint256 amount,
        bytes memory afterOperationParam,
        uint256 expectPrice
    )
        external
        override
        isValidOperator(msg.sender, liquidator)
        nonFlashLoanReentrant
        returns (DataTypes.LiquidateData memory liquidateData)
    {
        accrueRate();
        uint256 JUSDBorrowedT0 = userInfo[liquidated].t0BorrowBalance;
        uint256 primaryLiquidatedAmount = IERC20(primaryAsset).balanceOf(
            address(this)
        );
        uint256 primaryInsuranceAmount = IERC20(primaryAsset).balanceOf(
            insurance
        );
        isValidLiquidator(liquidated, liquidator);

        {
            DataTypes.UserInfo storage liquidatedInfo = userInfo[liquidated];
            require(amount != 0, JUSDErrors.LIQUIDATE_AMOUNT_IS_ZERO);
            if(amount >= liquidatedInfo.depositBalance[collateral]){
                amount = liquidatedInfo.depositBalance[collateral];
            }
        }

        // 1. calculate the liquidate amount
        liquidateData = _calculateLiquidateAmount(
            liquidated,
            collateral,
            amount
        );
        require(
        // condition: actual liquidate price < max buy price,
        // price lower, better
            (liquidateData.insuranceFee + liquidateData.actualLiquidated).decimalDiv(liquidateData.actualCollateral)
                <= expectPrice,
            JUSDErrors.LIQUIDATION_PRICE_PROTECTION
        );
        // 2. after liquidation flashloan operation
        _afterLiquidateOperation(
            afterOperationParam,
            amount,
            collateral,
            liquidated,
            liquidateData
        );

        // 3. price protect
        require(
            JUSDBorrowedT0 - userInfo[liquidated].t0BorrowBalance >=
                liquidateData.actualLiquidatedT0,
            JUSDErrors.REPAY_AMOUNT_NOT_ENOUGH
        );
        require(
            IERC20(primaryAsset).balanceOf(insurance) -
                primaryInsuranceAmount >=
                liquidateData.insuranceFee,
            JUSDErrors.INSURANCE_AMOUNT_NOT_ENOUGH
        );
        require(
            IERC20(primaryAsset).balanceOf(address(this)) -
                primaryLiquidatedAmount >=
                liquidateData.liquidatedRemainUSDC,
            JUSDErrors.LIQUIDATED_AMOUNT_NOT_ENOUGH
        );
        IERC20(primaryAsset).safeTransfer(liquidated, liquidateData.liquidatedRemainUSDC);
        emit Liquidate(
            collateral,
            liquidator,
            liquidated,
            msg.sender,
            liquidateData.actualCollateral,
            liquidateData.actualLiquidated,
            liquidateData.insuranceFee
        );
    }

    function handleDebt(
        address[] calldata liquidatedTraders
    ) external onlyOwner {
        for (uint256 i; i < liquidatedTraders.length; i = i + 1) {
            _handleBadDebt(liquidatedTraders[i]);
        }
    }

    function flashLoan(
        address receiver,
        address collateral,
        uint256 amount,
        address to,
        bytes memory param
    ) external nonFlashLoanReentrant {
        DataTypes.UserInfo storage user = userInfo[msg.sender];
        _withdraw(amount, collateral, receiver, msg.sender, false);
        // repay
        IFlashLoanReceive(receiver).JOJOFlashLoan(
            collateral,
            amount,
            to,
            param
        );
        require(
            _isAccountSafe(user, getTRate()),
            JUSDErrors.AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE
        );
        emit FlashLoan(collateral, amount);
    }

    function refundJUSD(uint256 amount) onlyOwner external {
        IERC20(JUSD).safeTransfer(msg.sender, amount);
    }

    function _deposit(
        DataTypes.ReserveInfo storage reserve,
        DataTypes.UserInfo storage user,
        uint256 amount,
        address collateral,
        address to,
        address from
    ) internal {
        require(reserve.isDepositAllowed, JUSDErrors.RESERVE_NOT_ALLOW_DEPOSIT);
        require(amount != 0, JUSDErrors.DEPOSIT_AMOUNT_IS_ZERO);
        IERC20(collateral).safeTransferFrom(from, address(this), amount);
        _addCollateralIfNotExists(user, collateral);
        user.depositBalance[collateral] += amount;
        reserve.totalDepositAmount += amount;
        require(
            user.depositBalance[collateral] <=
                reserve.maxDepositAmountPerAccount,
            JUSDErrors.EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT
        );
        require(
            reserve.totalDepositAmount <= reserve.maxTotalDepositAmount,
            JUSDErrors.EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL
        );
        emit Deposit(collateral, from, to, msg.sender, amount);
    }

    //    Pass parameter checking, excluding checking legality
    function _borrow(
        DataTypes.UserInfo storage user,
        bool isDepositToJOJO,
        address to,
        uint256 tAmount,
        address from
    ) internal {
        //        tAmount % tRate ？ tAmount / tRate : tAmount / tRate + 1
        uint256 t0Amount = tAmount.decimalRemainder(tRate)
            ? tAmount.decimalDiv(tRate)
            : tAmount.decimalDiv(tRate) + 1;
        user.t0BorrowBalance += t0Amount;
        t0TotalBorrowAmount += t0Amount;
        if (isDepositToJOJO) {
            IERC20(JUSD).approve(address(JOJODealer), tAmount);
            IDealer(JOJODealer).deposit(0, tAmount, to);
        } else {
            IERC20(JUSD).safeTransfer(to, tAmount);
        }
        // Personal account hard cap
        require(
            user.t0BorrowBalance.decimalMul(tRate) <= maxPerAccountBorrowAmount,
            JUSDErrors.EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT
        );
        // Global account hard cap
        require(
            t0TotalBorrowAmount.decimalMul(tRate) <= maxTotalBorrowAmount,
            JUSDErrors.EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL
        );
        emit Borrow(from, to, tAmount, isDepositToJOJO);
    }

    function _repay(
        DataTypes.UserInfo storage user,
        address payer,
        address to,
        uint256 amount,
        uint256 tRate
    ) internal returns (uint256) {
        require(amount != 0, JUSDErrors.REPAY_AMOUNT_IS_ZERO);
        uint256 JUSDBorrowed = user.t0BorrowBalance.decimalMul(tRate);
        uint256 tBorrowAmount;
        uint256 t0Amount;
        if (JUSDBorrowed <= amount) {
            tBorrowAmount = JUSDBorrowed;
            t0Amount = user.t0BorrowBalance;
        } else {
            tBorrowAmount = amount;
            t0Amount = amount.decimalDiv(tRate);
        }
        IERC20(JUSD).safeTransferFrom(payer, address(this), tBorrowAmount);
        user.t0BorrowBalance -= t0Amount;
        t0TotalBorrowAmount -= t0Amount;
        emit Repay(payer, to, tBorrowAmount);
        return tBorrowAmount;
    }

    function _withdraw(
        uint256 amount,
        address collateral,
        address to,
        address from,
        bool isInternal
    ) internal {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        DataTypes.UserInfo storage fromAccount = userInfo[from];
        require(amount != 0, JUSDErrors.WITHDRAW_AMOUNT_IS_ZERO);
        require(
            amount <= fromAccount.depositBalance[collateral],
            JUSDErrors.WITHDRAW_AMOUNT_IS_TOO_BIG
        );

        fromAccount.depositBalance[collateral] -= amount;
        if (isInternal) {
            require(reserve.isDepositAllowed, JUSDErrors.RESERVE_NOT_ALLOW_DEPOSIT);
            DataTypes.UserInfo storage toAccount = userInfo[to];
            _addCollateralIfNotExists(toAccount, collateral);
            toAccount.depositBalance[collateral] += amount;
            require(
                toAccount.depositBalance[collateral] <=
                    reserve.maxDepositAmountPerAccount,
                JUSDErrors.EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT
            );
        } else {
            reserve.totalDepositAmount -= amount;
            IERC20(collateral).safeTransfer(to, amount);
        }
        emit Withdraw(collateral, from, to, amount, isInternal);
        _removeEmptyCollateral(fromAccount, collateral);
    }

    function isValidLiquidator(address liquidated, address liquidator) internal view {
        require(
            liquidator != liquidated,
            JUSDErrors.SELF_LIQUIDATION_NOT_ALLOWED
        );
        if(isLiquidatorWhitelistOpen){
            require(isLiquidatorWhiteList[liquidator], JUSDErrors.LIQUIDATOR_NOT_IN_THE_WHITELIST);
        }
    }

    /// @notice liquidate is divided into three steps,
    // 1. determine whether liquidatedTrader is safe
    // 2. calculate the collateral amount actually liquidated
    // 3. transfer the insurance fee
    function _calculateLiquidateAmount(
        address liquidated,
        address collateral,
        uint256 amount
    ) internal view returns (DataTypes.LiquidateData memory liquidateData) {
        DataTypes.UserInfo storage liquidatedInfo = userInfo[liquidated];
        require(
            _isStartLiquidation(liquidatedInfo, tRate),
            JUSDErrors.ACCOUNT_IS_SAFE
        );
        DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
        uint256 price = IPriceChainLink(reserve.oracle).getAssetPrice();
        uint256 priceOff = price.decimalMul(
            DecimalMath.ONE - reserve.liquidationPriceOff
        );
        uint256 liquidateAmount = amount.decimalMul(priceOff).decimalMul(
            JOJOConstant.ONE - reserve.insuranceFeeRate
        );
        uint256 JUSDBorrowed = liquidatedInfo.t0BorrowBalance.decimalMul(tRate);
        /*
        liquidateAmount <= JUSDBorrowed
        liquidateAmount = amount * priceOff * (1-insuranceFee)
        actualJUSD = actualCollateral * priceOff
        insuranceFee = actualCollateral * priceOff * insuranceFeeRate
        */
        if (liquidateAmount <= JUSDBorrowed) {
            liquidateData.actualCollateral = amount;
            liquidateData.insuranceFee = amount.decimalMul(priceOff).decimalMul(
                reserve.insuranceFeeRate
            );
            liquidateData.actualLiquidatedT0 = liquidateAmount.decimalDiv(
                tRate
            );
            liquidateData.actualLiquidated = liquidateAmount;
        } else {
            //            actualJUSD = actualCollateral * priceOff
            //            = JUSDBorrowed * priceOff / priceOff * (1-insuranceFeeRate)
            //            = JUSDBorrowed / (1-insuranceFeeRate)
            //            insuranceFee = actualJUSD * insuranceFeeRate
            //            = actualCollateral * priceOff * insuranceFeeRate
            //            = JUSDBorrowed * insuranceFeeRate / (1- insuranceFeeRate)
            liquidateData.actualCollateral = JUSDBorrowed
                .decimalDiv(priceOff)
                .decimalDiv(JOJOConstant.ONE - reserve.insuranceFeeRate);
            liquidateData.insuranceFee = JUSDBorrowed
                .decimalMul(reserve.insuranceFeeRate)
                .decimalDiv(JOJOConstant.ONE - reserve.insuranceFeeRate);
            liquidateData.actualLiquidatedT0 = liquidatedInfo.t0BorrowBalance;
            liquidateData.actualLiquidated = JUSDBorrowed;
        }

        liquidateData.liquidatedRemainUSDC = (amount -
            liquidateData.actualCollateral).decimalMul(price);
    }

    function _addCollateralIfNotExists(
        DataTypes.UserInfo storage user,
        address collateral
    ) internal {
        if (!user.hasCollateral[collateral]) {
            user.hasCollateral[collateral] = true;
            user.collateralList.push(collateral);
        }
    }

    function _removeEmptyCollateral(
        DataTypes.UserInfo storage user,
        address collateral
    ) internal {
        if (user.depositBalance[collateral] == 0) {
            user.hasCollateral[collateral] = false;
            address[] storage collaterals = user.collateralList;
            for (uint256 i; i < collaterals.length; i = i + 1) {
                if (collaterals[i] == collateral) {
                    collaterals[i] = collaterals[collaterals.length - 1];
                    collaterals.pop();
                    break;
                }
            }
        }
    }

    function _afterLiquidateOperation(
        bytes memory afterOperationParam,
        uint256 flashloanAmount,
        address collateral,
        address liquidated,
        DataTypes.LiquidateData memory liquidateData
    ) internal {
        (address flashloanAddress, bytes memory param) = abi.decode(
            afterOperationParam,
            (address, bytes)
        );
        _withdraw(
            flashloanAmount,
            collateral,
            flashloanAddress,
            liquidated,
            false
        );
        param = abi.encode(liquidateData, param);
        IFlashLoanReceive(flashloanAddress).JOJOFlashLoan(
            collateral,
            flashloanAmount,
            liquidated,
            param
        );
    }

    /// @notice handle the bad debt
    /// @param liquidatedTrader need to be liquidated
    function _handleBadDebt(address liquidatedTrader) internal {
        DataTypes.UserInfo storage liquidatedTraderInfo = userInfo[
            liquidatedTrader
        ];
        uint256 tRate = getTRate();
        if (
            liquidatedTraderInfo.collateralList.length == 0 &&
            _isStartLiquidation(liquidatedTraderInfo, tRate)
        ) {
            DataTypes.UserInfo storage insuranceInfo = userInfo[insurance];
            uint256 borrowJUSDT0 = liquidatedTraderInfo.t0BorrowBalance;
            insuranceInfo.t0BorrowBalance += borrowJUSDT0;
            liquidatedTraderInfo.t0BorrowBalance = 0;
            emit HandleBadDebt(liquidatedTrader, borrowJUSDT0);
        }
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
*/

pragma solidity 0.8.9;

library Types {
    /// @notice data structure of dealer
    struct State {
        // primary asset, ERC20
        address primaryAsset;
        // secondary asset, ERC20
        address secondaryAsset;
        // credit, gained by deposit assets
        mapping(address => int256) primaryCredit;
        mapping(address => uint256) secondaryCredit;
        // allow fund operators to withdraw
        mapping(address => mapping(address => uint256)) primaryCreditAllowed;
        mapping(address => mapping(address => uint256)) secondaryCreditAllowed;
        // withdrawal request time lock
        uint256 withdrawTimeLock;
        // pending primary asset withdrawal amount
        mapping(address => uint256) pendingPrimaryWithdraw;
        // pending secondary asset withdrawal amount
        mapping(address => uint256) pendingSecondaryWithdraw;
        // withdrawal request executable timestamp
        mapping(address => uint256) withdrawExecutionTimestamp;
        // perpetual contract risk parameters
        mapping(address => Types.RiskParams) perpRiskParams;
        // perpetual contract registry, for view
        address[] registeredPerp;
        // all open positions of a trader
        mapping(address => address[]) openPositions;
        // For offchain pnl calculation, serial number +1 whenever 
        // position is fully closed.
        // trader => perpetual contract address => current serial Num
        mapping(address => mapping(address => uint256)) positionSerialNum;
        // filled amount of orders
        mapping(bytes32 => uint256) orderFilledPaperAmount;
        // valid order sender registry
        mapping(address => bool) validOrderSender;
        // addresses that can make fast withdrawal
        mapping(address => bool) fastWithdrawalWhitelist;
        bool fastWithdrawDisabled;
        // operator registry
        // client => operator => isValid
        mapping(address => mapping(address => bool)) operatorRegistry;
        // insurance account
        address insurance;
        // funding rate keeper, normally an EOA account
        address fundingRateKeeper;
        uint256 maxPositionAmount;
    }

    struct Order {
        // address of perpetual market
        address perp;
        /*
            Signer is trader, the identity of trading behavior,
            whose balance will be changed.
            Normally it should be an EOA account and the 
            order is valid only if the signer signed it.
            If the signer is a smart contract, it has two ways
            to sign the order. The first way is to authorize 
            another EOA address to sign for it through setOperator.
            The other way is to implement IERC1271 for self-verification.
        */
        address signer;
        // positive(negative) if you want to open long(short) position
        int128 paperAmount;
        // negative(positive) if you want to open long(short) position
        int128 creditAmount;
        /*
            ╔═══════════════════╤═════════╗
            ║ info component    │ type    ║
            ╟───────────────────┼─────────╢
            ║ makerFeeRate      │ int64   ║
            ║ takerFeeRate      │ int64   ║
            ║ expiration        │ uint64  ║
            ║ nonce             │ uint64  ║
            ╚═══════════════════╧═════════╝
        */
        bytes32 info;
    }

    // EIP712 component
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address perp,address signer,int128 paperAmount,int128 creditAmount,bytes32 info)"
        );

    /// @notice risk params of a perpetual market
    struct RiskParams {
        /*
            When users withdraw funds, their margin must be equal or
            greater than the exposure * initialMarginRatio.
        */
        uint256 initialMarginRatio;
        /*
            Liquidation will happen when
            netValue < exposure * liquidationThreshold
            The lower liquidationThreshold, the higher leverage.
            This value is also known as "maintenance margin ratio".
            1E18 based decimal.
        */
        uint256 liquidationThreshold;
        /*
            The discount rate for the liquidation.
            markPrice * (1 - liquidationPriceOff) when liquidate long position
            markPrice * (1 + liquidationPriceOff) when liquidate short position
            1e18 based decimal.
        */
        uint256 liquidationPriceOff;
        // The insurance fee rate charged from liquidation. 
        // 1E18 based decimal.
        uint256 insuranceFeeRate;
        // price source of mark price
        address markPriceSource;
        // perpetual market name
        string name;
        // if the market is activited
        bool isRegistered;
    }

    /// @notice Match result obtained by parsing and validating tradeData.
    /// Contains arrays of balance change.
    struct MatchResult {
        address[] traderList;
        int256[] paperChangeList;
        int256[] creditChangeList;
        int256 orderSenderFee;
    }

    uint256 constant ONE = 10**18;
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@JOJO/contracts/intf/IDealer.sol";
import "@JOJO/contracts/intf/IPerpetual.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@JUSDV1/src/Interface/IJUSDBank.sol";
import "@JUSDV1/src/lib/DecimalMath.sol";

pragma solidity 0.8.9;

struct WithdrawalRequest {
    uint256 amount; // EarnUSDC
    address user;
    bool executed;
}

contract FundingRateArbitrage is Ownable {
    address public immutable Collateral;
    address public immutable JusdBank;
    address public immutable JOJODealer;
    address public immutable PerpMarket;
    address public immutable USDC;
    address public immutable JUSD;
    uint256 public maxNetValue;

    WithdrawalRequest[] public WithdrawalRequests;
    mapping(address => uint256) public EarnUSDCBalance;
    mapping(address => uint256) public JUSDOutside;
    uint256 public totalEarnUSDCBalance;

    mapping(address => bool) public adminWhiteList;

    uint256 public depositFeeRate;
    uint256 public withdrawFeeRate;
    uint256 public withdrawSettleFee; // USDC

    using SafeERC20 for IERC20;
    using DecimalMath for uint256;

    event Swap(
        address fromToken,
        address toToken,
        uint256 payAmount,
        uint256 receivedAmount
    );

    // =========================Consturct===================

    constructor(
        address _collateral,
        address _jusdBank,
        address _JOJODealer,
        address _perpMarket,
        address _Operator,
        address _USDC,
        address _JUSD
    ) Ownable() {
        // set params
        Collateral = _collateral;
        JusdBank = _jusdBank;
        JOJODealer = _JOJODealer;
        PerpMarket = _perpMarket;
        USDC = _USDC;
        JUSD = _JUSD;

        // set operator
        IDealer(JOJODealer).setOperator(_Operator, true);

        // approve to JUSDBank & JOJODealer
        IERC20(Collateral).approve(JusdBank, type(uint256).max);
        IERC20(JUSD).approve(JusdBank, type(uint256).max);
        IERC20(JUSD).approve(JOJODealer, type(uint256).max);
        IERC20(USDC).approve(JOJODealer, type(uint256).max);
    }

    modifier onlyAdminWhiteList() {
        require(adminWhiteList[msg.sender], "caller is not in the admin white list");
        _;
    }

    // =========================View========================

    function getNetValue() public view returns (uint256) {
        uint256 JUSDBorrowed =  IJUSDBank(JusdBank).getBorrowBalance(address(this));
        
        uint256 collateralAmount = IJUSDBank(JusdBank).getDepositBalance(
            Collateral,
            address(this)
        );
        uint256 USDCBuffer = IERC20(USDC).balanceOf(address(this));
        uint256 collateralPrice = IJUSDBank(JusdBank).getCollateralPrice(
            Collateral
        );
        (int256 perpNetValue, ,, ) = IDealer(JOJODealer).getTraderRisk(
            address(this)
        );
        return SafeCast.toUint256(perpNetValue) + 
                          collateralAmount.decimalMul(collateralPrice) +
                          USDCBuffer - JUSDBorrowed;
    }

    function getIndex() public view returns (uint256) {
        if(totalEarnUSDCBalance == 0){
            return 1e18;
        } else {
            return DecimalMath.decimalDiv(getNetValue(), totalEarnUSDCBalance);
        }
    }

    // =========================Only Owner Parameter set==================

    function setOperator(address operator, bool isValid) public onlyOwner {
        IDealer(JOJODealer).setOperator(operator, isValid);
    }

    function setMaxNetValue(uint256 newMaxNetValue) public onlyOwner {
        maxNetValue = newMaxNetValue;
    }

    function setDepositFeeRate(uint256 newDepositFeeRate)public onlyOwner {
        depositFeeRate = newDepositFeeRate;
    }

    function setWithdrawFeeRate(uint256 newWithdrawFeeRate)public onlyOwner {
        withdrawFeeRate = newWithdrawFeeRate;
    }

    function setWithdrawSettleFee(uint256 newWithdrawSettleFee)public onlyOwner {
        withdrawSettleFee = newWithdrawSettleFee;
    }

    function setAdminWhiteList(address admin, bool isValid) public onlyOwner {
        adminWhiteList[admin] = isValid;
    }
    
    // ==================== Position changes =============

    // collateral add
    function openPosition(
        uint256 minReceivedCollateral,
        uint256 JUSDRebalanceAmount,
        bytes memory spotTradeParam
    ) public onlyAdminWhiteList {
        uint256 receivedCollateral = _swap(spotTradeParam, true);
        require(receivedCollateral >= minReceivedCollateral, "SWAP SLIPPAGE");
        _depositToJUSDBank(IERC20(Collateral).balanceOf(address(this)));
        rebalanceToPerp(JUSDRebalanceAmount);
        // openPosition
    }

    // collateral remove
    function closePosition(
        uint256 minReceivedUSDC,
        uint256 JUSDRebalanceAmount,
        uint256 collateralAmount,
        bytes memory spotTradeParam
    ) public onlyAdminWhiteList {
        // close position
        rebalanceToJUSDBank(JUSDRebalanceAmount);
        _withdrawFromJUSDBank(collateralAmount);
        uint256 receivedUSDC = _swap(spotTradeParam, false);
        require(receivedUSDC >= minReceivedUSDC, "SWAP SLIPPAGE");
    }

    // Swap without check received
    function _swap(
        bytes memory param,
        bool buyCollteral
    ) private returns (uint256 receivedAmount) {
        address fromToken;
        address toToken;
        if (buyCollteral) {
            fromToken = USDC;
            toToken = Collateral;
        } else {
            fromToken = Collateral;
            toToken = USDC;
        }
        uint256 toTokenReserve = IERC20(toToken).balanceOf(address(this));

        (
            address approveTarget,
            address swapTarget,
            uint256 payAmount,
            bytes memory callData
        ) = abi.decode(param, (address, address, uint256, bytes));

        IERC20(fromToken).safeApprove(approveTarget, payAmount);
        (bool success, ) = swapTarget.call(callData);
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        receivedAmount =
            IERC20(toToken).balanceOf(address(this)) -
            toTokenReserve;
        emit Swap(fromToken, toToken, payAmount, receivedAmount);
    }

    // JUSD

    function rebalanceToPerp(uint256 JUSDAmount) public onlyAdminWhiteList {
        IJUSDBank(JusdBank).borrow(JUSDAmount, address(this), true);
    }

    function rebalanceToJUSDBank(uint256 JUSDRebalanceAmount) public onlyAdminWhiteList {
        IDealer(JOJODealer).fastWithdraw(address(this), address(this), 0, JUSDRebalanceAmount, false, "");
        _repayJUSD(JUSDRebalanceAmount);
    }

    // =============== JUSDBank Operations =================
    // borrow repay withdraw deposit

    function _borrowJUSD(uint256 JUSDAmount) internal {
        IJUSDBank(JusdBank).borrow(JUSDAmount, address(this), true);
    }

    function _repayJUSD(uint256 amount) internal {
        IJUSDBank(JusdBank).repay(amount, address(this));
    }

    function _withdrawFromJUSDBank(uint256 amount) internal {
        IJUSDBank(JusdBank).withdraw(Collateral, amount, address(this), false);
    }

    function _depositToJUSDBank(uint256 amount) internal {
        // deposit to JUSDBank
        IJUSDBank(JusdBank).deposit(
            address(this),
            Collateral,
            amount,
            address(this)
        );
    }

    // =============== JOJODealer Operations ================
    // deposit withdraw USDC

    function depositUSDCToPerp(uint256 primaryAmount) public onlyOwner() {
        IDealer(JOJODealer).deposit(primaryAmount, 0, address(this));
    }

    function fastWithdrawUSDCFromPerp(uint256 primaryAmount) public onlyAdminWhiteList() {
        IDealer(JOJODealer).fastWithdraw(address(this), address(this), primaryAmount, 0, false, "");
    }

    // ========================= LP Functions =======================

    function deposit(uint256 amount) external {
        require(amount != 0, "deposit amount is zero");
        IERC20(USDC).transferFrom(msg.sender, address(this), amount);
        uint256 feeAmount = amount.decimalMul(depositFeeRate);
        if (feeAmount > 0) {
            amount -= feeAmount;
            IERC20(USDC).transfer(owner(), feeAmount);
        }
        // deposit to JOJODealer
        transferOutJUSD(msg.sender, amount);
        uint256 earnUSDCAmount = amount.decimalDiv(getIndex());
        EarnUSDCBalance[msg.sender] += earnUSDCAmount;
        JUSDOutside[msg.sender] += amount;
        totalEarnUSDCBalance += earnUSDCAmount;
        require(getNetValue() <= maxNetValue, "net value exceed limitation");
    }

    // withdraw all remaining balances
    function requestWithdraw(
        uint256 repayJUSDAmount
    ) external returns (uint256 withdrawEarnUSDCAmount) {
        transferInJUSD(msg.sender, repayJUSDAmount);
        require(repayJUSDAmount <= JUSDOutside[msg.sender], "Request Withdraw too big");
        JUSDOutside[msg.sender] -= repayJUSDAmount;
        uint256 index = getIndex();
        uint256 lockedEarnUSDCAmount = JUSDOutside[msg.sender].decimalDiv(index);
        withdrawEarnUSDCAmount = EarnUSDCBalance[msg.sender]-lockedEarnUSDCAmount;
        WithdrawalRequests.push(
            WithdrawalRequest(withdrawEarnUSDCAmount, msg.sender, false)
        );
        require(withdrawEarnUSDCAmount.decimalMul(index) >= withdrawSettleFee, "Withdraw amount is smaller than settleFee");
        EarnUSDCBalance[msg.sender] = lockedEarnUSDCAmount;
        
        return WithdrawalRequests.length - 1;
    }

    function permitWithdrawRequests(
        uint256[] memory requestIDList
    ) external onlyOwner {
        uint256 index = getIndex();
        for (uint256 i; i < requestIDList.length; i++) {
            WithdrawalRequest storage request = WithdrawalRequests[i];
            require(!request.executed);
            uint256 USDCAmount = request.amount.decimalMul(index);
            uint256 feeAmount = (USDCAmount - withdrawSettleFee).decimalMul(withdrawFeeRate) + withdrawSettleFee;
            if (feeAmount > 0) {
                IERC20(USDC).transfer(owner(), feeAmount);
            }
            IERC20(USDC).transfer(request.user, USDCAmount - feeAmount);
            request.executed = true;
            totalEarnUSDCBalance -= request.amount;
        }
    }

    function transferInJUSD(address from, uint256 amount) internal {
        IERC20(JUSD).safeTransferFrom(from, address(this), amount);
    }

    function transferOutJUSD(address to, uint256 amount) internal {
        IDealer(JOJODealer).deposit(0, amount, to);
    }

    
    function burnJUSD(uint256 amount) public onlyOwner {
        IERC20(JUSD).safeTransfer(msg.sender, amount);
    }

}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

import {DataTypes} from "../lib/DataTypes.sol";

/// @notice JUSDBank is a mortgage lending system that supports ERC20 as collateral and issues JUSD
/// JUSD is a self-issued stable coin used to support multi-collateralization protocols

interface IJUSDBank {
    /// @notice deposit function: user deposit their collateral.
    /// @param from: deposit from which account
    /// @param collateral: deposit collateral type.
    /// @param amount: collateral amount
    /// @param to: account that user want to deposit to
    function deposit(
        address from,
        address collateral,
        uint256 amount,
        address to
    ) external;

    /// @notice borrow function: get JUSD based on the amount of user's collaterals.
    /// @param amount: borrow JUSD amount
    /// @param to: is the address receiving JUSD
    /// @param isDepositToJOJO: whether deposit to JOJO account
    function borrow(uint256 amount, address to, bool isDepositToJOJO) external;

    /// @notice withdraw function: user can withdraw their collateral
    /// @param collateral: withdraw collateral type
    /// @param amount: withdraw amount
    /// @param to: is the address receiving asset
    function withdraw(
        address collateral,
        uint256 amount,
        address to,
        bool isInternal
    ) external;

    /// @notice repay function: repay the JUSD in order to avoid account liquidation by liquidators
    /// @param amount: repay JUSD amount
    /// @param to: repay to whom
    function repay(uint256 amount, address to) external returns (uint256);

    /// @notice liquidate function: The price of user mortgage assets fluctuates.
    /// If the value of the mortgage collaterals cannot handle the value of JUSD borrowed, the collaterals may be liquidated
    /// @param liquidatedTrader: is the trader to be liquidated
    /// @param liquidationCollateral: is the liquidated collateral type
    /// @param liquidationAmount: is the collateral amount liqidator want to take
    /// @param expectPrice: expect liquidate amount
    function liquidate(
        address liquidatedTrader,
        address liquidationCollateral,
        address liquidator,
        uint256 liquidationAmount,
        bytes memory param,
        uint256 expectPrice
    ) external returns (DataTypes.LiquidateData memory liquidateData);

    /// @notice insurance account take bad debts on unsecured accounts
    /// @param liquidatedTraders traders who have bad debts
    function handleDebt(address[] calldata liquidatedTraders) external;

    /// @notice withdraw and deposit collaterals in one transaction
    /// @param receiver address who receiver the collateral
    /// @param collateral collateral type
    /// @param amount withdraw amount
    /// @param to: if repay JUSD, repay to whom
    /// @param param user input
    function flashLoan(
        address receiver,
        address collateral,
        uint256 amount,
        address to,
        bytes memory param
    ) external;

    /// @notice get the all collateral list
    function getReservesList() external view returns (address[] memory);

    /// @notice return the max borrow JUSD amount from the deposit amount
    function getDepositMaxMintAmount(
        address user
    ) external view returns (uint256);

    /// @notice return the collateral's max borrow JUSD amount
    function getCollateralMaxMintAmount(
        address collateral,
        uint256 amoount
    ) external view returns (uint256 maxAmount);

    /// @notice return the collateral's max withdraw amount
    function getMaxWithdrawAmount(
        address collateral,
        address user
    ) external view returns (uint256 maxAmount);

    function isAccountSafe(address user) external view returns (bool);

    function getCollateralPrice(
        address collateral
    ) external view returns (uint256);

    function getIfHasCollateral(
        address from,
        address collateral
    ) external view returns (bool);

    function getDepositBalance(
        address collateral,
        address from
    ) external view returns (uint256);

    function getBorrowBalance(address from) external view returns (uint256);

    function getUserCollateralList(
        address from
    ) external view returns (address[] memory);
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

interface IFlashLoanReceive {
    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external;
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from "../lib/DataTypes.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/FlashLoanReentrancyGuard.sol";
import "../lib/JOJOConstant.sol";
import {DecimalMath} from "../lib/DecimalMath.sol";

abstract contract JUSDBankStorage is
    Ownable,
    ReentrancyGuard,
    FlashLoanReentrancyGuard
{
    // reserve token address ==> reserve info
    mapping(address => DataTypes.ReserveInfo) public reserveInfo;
    // reserve token address ==> user info
    mapping(address => DataTypes.UserInfo) public userInfo;
    //client -> operator -> bool
    mapping(address => mapping(address => bool)) public operatorRegistry;
    // reserves amount
    uint256 public reservesNum;
    // max reserves amount
    uint256 public maxReservesNum;
    // max borrow JUSD amount per account
    uint256 public maxPerAccountBorrowAmount;
    // max total borrow JUSD amount
    uint256 public maxTotalBorrowAmount;
    // t0 total borrow JUSD amount
    uint256 public t0TotalBorrowAmount;
    // borrow fee rate
    uint256 public borrowFeeRate;
    // t0Rate
    uint256 public tRate;
    // update timestamp
    uint256 public lastUpdateTimestamp;
    // reserves's list
    address[] public reservesList;
    // insurance account
    address public insurance;
    // JUSD address
    address public JUSD;
    // primary address
    address public primaryAsset;
    address public JOJODealer;
    bool public isLiquidatorWhitelistOpen;
    mapping(address => bool) isLiquidatorWhiteList;

    using DecimalMath for uint256;

    function accrueRate() public {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp == lastUpdateTimestamp) {
            return;
        }
        uint256 timeDifference = block.timestamp - uint256(lastUpdateTimestamp);
        tRate = tRate.decimalMul(timeDifference * borrowFeeRate / JOJOConstant.SECONDS_PER_YEAR + 1e18);
        lastUpdateTimestamp = currentTimestamp;
    }

    function getTRate() view public returns(uint256) {
        uint256 timeDifference = block.timestamp - uint256(lastUpdateTimestamp);
        return
            tRate +
            (borrowFeeRate * timeDifference) /
            JOJOConstant.SECONDS_PER_YEAR;
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

import "./JUSDBankStorage.sol";
import "../utils/JUSDError.sol";
import "../lib/JOJOConstant.sol";
import {DecimalMath} from "../lib/DecimalMath.sol";

/// @notice Owner-only functions
abstract contract JUSDOperation is JUSDBankStorage {
    using DecimalMath for uint256;

    // ========== event ==========
    event UpdateInsurance(address oldInsurance, address newInsurance);
    event UpdateJOJODealer(address oldJOJODealer, address newJOJODealer);
    event SetOperator(
        address indexed client,
        address indexed operator,
        bool isOperator
    );
    event UpdateOracle(address collateral, address newOracle);
    event UpdateBorrowFeeRate(uint256 newBorrowFeeRate);
    event UpdateMaxReservesAmount(
        uint256 maxReservesAmount,
        uint256 newMaxReservesAmount
    );
    event RemoveReserve(address indexed collateral);
    event ReRegisterReserve(address indexed collateral);
    event UpdateReserveRiskParam(
        address indexed collateral,
        uint256 liquidationMortgageRate,
        uint256 liquidationPriceOff,
        uint256 insuranceFeeRate
    );
    event UpdateReserveParam(
        address indexed collateral,
        uint256 initialMortgageRate,
        uint256 maxTotalDepositAmount,
        uint256 maxDepositAmountPerAccount,
        uint256 maxBorrowValue
    );
    event UpdateMaxBorrowAmount(
        uint256 maxPerAccountBorrowAmount,
        uint256 maxTotalBorrowAmount
    );

    /// @notice initial the param of each reserve
    function initReserve(
        address _collateral,
        uint256 _initialMortgageRate,
        uint256 _maxTotalDepositAmount,
        uint256 _maxDepositAmountPerAccount,
        uint256 _maxColBorrowPerAccount,
        uint256 _liquidationMortgageRate,
        uint256 _liquidationPriceOff,
        uint256 _insuranceFeeRate,
        address _oracle
    ) external onlyOwner {
        require(
            JOJOConstant.ONE - _liquidationMortgageRate >
                _liquidationPriceOff +
                    (JOJOConstant.ONE - _liquidationPriceOff).decimalMul(
                        _insuranceFeeRate
                    ),
            JUSDErrors.RESERVE_PARAM_ERROR
        );
        reserveInfo[_collateral].initialMortgageRate = _initialMortgageRate;
        reserveInfo[_collateral].maxTotalDepositAmount = _maxTotalDepositAmount;
        reserveInfo[_collateral]
            .maxDepositAmountPerAccount = _maxDepositAmountPerAccount;
        reserveInfo[_collateral]
            .maxColBorrowPerAccount = _maxColBorrowPerAccount;
        reserveInfo[_collateral]
            .liquidationMortgageRate = _liquidationMortgageRate;
        reserveInfo[_collateral].liquidationPriceOff = _liquidationPriceOff;
        reserveInfo[_collateral].insuranceFeeRate = _insuranceFeeRate;
        reserveInfo[_collateral].isDepositAllowed = true;
        reserveInfo[_collateral].isBorrowAllowed = true;
        reserveInfo[_collateral].oracle = _oracle;
        _addReserve(_collateral);
    }

    function _addReserve(address collateral) private {
        require(
            reservesNum < maxReservesNum,
            JUSDErrors.NO_MORE_RESERVE_ALLOWED
        );
        reservesList.push(collateral);
        reservesNum += 1;
    }

    /// @notice update the max borrow amount of total and per account
    function updateMaxBorrowAmount(
        uint256 _maxBorrowAmountPerAccount,
        uint256 _maxTotalBorrowAmount
    ) external onlyOwner {
        maxTotalBorrowAmount = _maxTotalBorrowAmount;
        maxPerAccountBorrowAmount = _maxBorrowAmountPerAccount;
        emit UpdateMaxBorrowAmount(
            maxPerAccountBorrowAmount,
            maxTotalBorrowAmount
        );
    }

    /// @notice update the insurance account
    function updateInsurance(address newInsurance) external onlyOwner {
        emit UpdateInsurance(insurance, newInsurance);
        insurance = newInsurance;
    }

    /// @notice update JOJODealer address
    function updateJOJODealer(address newJOJODealer) external onlyOwner {
        emit UpdateJOJODealer(JOJODealer, newJOJODealer);
        JOJODealer = newJOJODealer;
    }

    function liquidatorWhitelistOpen() external onlyOwner {
        isLiquidatorWhitelistOpen = true;
    }

    function liquidatorWhitelistClose() external onlyOwner {
        isLiquidatorWhitelistOpen = false;
    }

    function addLiquidator(address liquidator) external onlyOwner {
        isLiquidatorWhiteList[liquidator] = true;
    }

    function removeLiquidator(address liquidator) external onlyOwner {
        isLiquidatorWhiteList[liquidator] = false;
    }

    /// @notice update collateral oracle
    function updateOracle(
        address collateral,
        address newOracle
    ) external onlyOwner {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        reserve.oracle = newOracle;
        emit UpdateOracle(collateral, newOracle);
    }

    function updateMaxReservesAmount(
        uint256 newMaxReservesAmount
    ) external onlyOwner {
        emit UpdateMaxReservesAmount(maxReservesNum, newMaxReservesAmount);
        maxReservesNum = newMaxReservesAmount;
    }

    /// @notice update the borrow fee rate
    // t0Rate and lastUpdateTimestamp will be updated according to the borrow fee rate
    function updateBorrowFeeRate(uint256 _borrowFeeRate) external onlyOwner {
        accrueRate();
        borrowFeeRate = _borrowFeeRate;
        emit UpdateBorrowFeeRate(_borrowFeeRate);
    }

    /// @notice update the reserve risk params
    function updateRiskParam(
        address collateral,
        uint256 _liquidationMortgageRate,
        uint256 _liquidationPriceOff,
        uint256 _insuranceFeeRate
    ) external onlyOwner {
        require(
            JOJOConstant.ONE - _liquidationMortgageRate >
                _liquidationPriceOff +
                    ((JOJOConstant.ONE - _liquidationPriceOff) *
                        _insuranceFeeRate) /
                    JOJOConstant.ONE,
            JUSDErrors.RESERVE_PARAM_ERROR
        );

        require(reserveInfo[collateral].initialMortgageRate < _liquidationMortgageRate, JUSDErrors.RESERVE_PARAM_WRONG);
        reserveInfo[collateral]
            .liquidationMortgageRate = _liquidationMortgageRate;
        reserveInfo[collateral].liquidationPriceOff = _liquidationPriceOff;
        reserveInfo[collateral].insuranceFeeRate = _insuranceFeeRate;
        emit UpdateReserveRiskParam(
            collateral,
            _liquidationMortgageRate,
            _liquidationPriceOff,
            _insuranceFeeRate
        );
    }

    /// @notice update the reserve basic params
    function updateReserveParam(
        address collateral,
        uint256 _initialMortgageRate,
        uint256 _maxTotalDepositAmount,
        uint256 _maxDepositAmountPerAccount,
        uint256 _maxColBorrowPerAccount
    ) external onlyOwner {
        require(_initialMortgageRate < reserveInfo[collateral].liquidationMortgageRate, JUSDErrors.RESERVE_PARAM_WRONG);
        reserveInfo[collateral].initialMortgageRate = _initialMortgageRate;
        reserveInfo[collateral].maxTotalDepositAmount = _maxTotalDepositAmount;
        reserveInfo[collateral]
            .maxDepositAmountPerAccount = _maxDepositAmountPerAccount;
        reserveInfo[collateral]
            .maxColBorrowPerAccount = _maxColBorrowPerAccount;
        emit UpdateReserveParam(
            collateral,
            _initialMortgageRate,
            _maxTotalDepositAmount,
            _maxDepositAmountPerAccount,
            _maxColBorrowPerAccount
        );
    }

    /// @notice remove the reserve, need to modify the market status
    /// which means this reserve is delist
    function delistReserve(address collateral) external onlyOwner {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        reserve.isBorrowAllowed = false;
        reserve.isDepositAllowed = false;
        reserve.isFinalLiquidation = true;
        emit RemoveReserve(collateral);
    }

    /// @notice relist the delist reserve
    function relistReserve(address collateral) external onlyOwner {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        reserve.isBorrowAllowed = true;
        reserve.isDepositAllowed = true;
        reserve.isFinalLiquidation = false;
        emit ReRegisterReserve(collateral);
    }

    /// @notice Update the sub account
    function setOperator(address operator, bool isOperator) external {
        operatorRegistry[msg.sender][operator] = isOperator;
        emit SetOperator(msg.sender, operator, isOperator);
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity ^0.8.9;

import "./JUSDBankStorage.sol";
import {DecimalMath} from "../lib/DecimalMath.sol";
import "../Interface/IJUSDBank.sol";
import {IPriceChainLink} from "../Interface/IPriceChainLink.sol";

abstract contract JUSDView is JUSDBankStorage, IJUSDBank {
    using DecimalMath for uint256;

    function getReservesList() external view returns (address[] memory) {
        return reservesList;
    }

    function getDepositMaxMintAmount(address user) external view returns (uint256) {
        DataTypes.UserInfo storage userInfo = userInfo[user];
        return _maxMintAmount(userInfo);
    }

    function getCollateralMaxMintAmount(
        address collateral,
        uint256 amount
    ) external view returns (uint256 maxAmount) {
        DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
        return _getMintAmount(reserve, amount, reserve.initialMortgageRate);
    }

    function getMaxWithdrawAmount(
        address collateral,
        address user
    ) external view returns (uint256 maxAmount) {
        DataTypes.UserInfo storage userInfo = userInfo[user];
        uint256 JUSDBorrow = userInfo.t0BorrowBalance.decimalMul(getTRate());
        if (JUSDBorrow == 0) {
            return userInfo.depositBalance[collateral];
        }
        uint256 maxMintAmount = _maxWithdrawAmount(userInfo);
        if (maxMintAmount <= JUSDBorrow) {
            maxAmount = 0;
        } else {
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            uint256 remainAmount = (maxMintAmount - JUSDBorrow).decimalDiv(
                reserve.initialMortgageRate.decimalMul(
                    IPriceChainLink(reserve.oracle).getAssetPrice()
                )
            );
            remainAmount >= userInfo.depositBalance[collateral]
                ? maxAmount = userInfo.depositBalance[collateral]
                : maxAmount = remainAmount;
        }
    }

    function isAccountSafe(address user) external view returns (bool) {
        DataTypes.UserInfo storage userInfo = userInfo[user];
        return !_isStartLiquidation(userInfo, getTRate());
    }

    function getCollateralPrice(
        address collateral
    ) external view returns (uint256) {
        return IPriceChainLink(reserveInfo[collateral].oracle).getAssetPrice();
    }

    function getIfHasCollateral(
        address from,
        address collateral
    ) external view returns (bool) {
        return userInfo[from].hasCollateral[collateral];
    }

    function getDepositBalance(
        address collateral,
        address from
    ) external view returns (uint256) {
        return userInfo[from].depositBalance[collateral];
    }

    function getBorrowBalance(address from) external view returns (uint256) {
        return (userInfo[from].t0BorrowBalance * getTRate()) / 1e18;
    }

    function getUserCollateralList(
        address from
    ) external view returns (address[] memory) {
        return userInfo[from].collateralList;
    }

    function _getMintAmount(
        DataTypes.ReserveInfo memory reserve,
        uint256 amount,
        uint256 rate
    ) internal view returns (uint256) {
        uint256 depositAmount = IPriceChainLink(reserve.oracle)
            .getAssetPrice()
            .decimalMul(amount)
            .decimalMul(rate);
        if (depositAmount >= reserve.maxColBorrowPerAccount) {
            depositAmount = reserve.maxColBorrowPerAccount;
        }
        return depositAmount;
    }


    function _isAccountSafe(
        DataTypes.UserInfo storage user,
        uint256 tRate
    ) internal view returns (bool) {
        return
            user.t0BorrowBalance.decimalMul(tRate) <=
            _maxMintAmount(user);
    }

    function _maxMintAmount(
        DataTypes.UserInfo storage user
    ) internal view returns (uint256) {
        address[] memory collaterals = user.collateralList;
        uint256 maxMintAmount;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            address collateral = collaterals[i];
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            if (!reserve.isBorrowAllowed) {
                continue;
            }
            uint256 colMintAmount = _getMintAmount(
                reserve,
                user.depositBalance[collateral],
                reserve.initialMortgageRate
            );
            maxMintAmount += colMintAmount;
        }
        return maxMintAmount;
    }

    function _maxWithdrawAmount(DataTypes.UserInfo storage user) internal view returns (uint256) {
        address[] memory collaterals = user.collateralList;
        uint256 maxMintAmount;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            address collateral = collaterals[i];
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            if (!reserve.isBorrowAllowed) {
                continue;
            }
            maxMintAmount += IPriceChainLink(reserve.oracle).getAssetPrice().decimalMul(user.depositBalance[collateral])
            .decimalMul(reserve.initialMortgageRate);
        }
        return maxMintAmount;
    }

    /// @notice Determine whether the account is safe by liquidationMortgageRate
    // If the collateral delisted. When calculating the boundary conditions for collateral to be liquidated, treat the value of collateral as 0
    // liquidationMaxMintAmount = sum(depositAmount * price * liquidationMortgageRate)
    function _isStartLiquidation(
        DataTypes.UserInfo storage liquidatedTraderInfo,
        uint256 tRate
    ) internal view returns (bool) {
        uint256 JUSDBorrow = (liquidatedTraderInfo.t0BorrowBalance).decimalMul(
            tRate
        );
        uint256 liquidationMaxMintAmount;
        address[] memory collaterals = liquidatedTraderInfo.collateralList;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            address collateral = collaterals[i];
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            if (reserve.isFinalLiquidation) {
                continue;
            }
            liquidationMaxMintAmount += _getMintAmount(
                reserve,
                liquidatedTraderInfo.depositBalance[collateral],
                reserve.liquidationMortgageRate
            );
        }
        return liquidationMaxMintAmount < JUSDBorrow;
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

import {DecimalMath} from "../lib/DecimalMath.sol";
import "./JUSDBank.sol";

/// @notice User's multi-step operation on the JUSDBank like: deposit and borrow
contract JUSDMulticall {
    using DecimalMath for uint256;

    function multiCall(
        bytes[] memory callData
    ) external returns (bytes[] memory returnData) {
        returnData = new bytes[](callData.length);

        for (uint256 i; i < callData.length; i++) {
            (bool success, bytes memory res) = address(this).delegatecall(
                callData[i]
            );
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
            returnData[i] = res;
        }
    }

    // --------------helper-------------------
    function getMulticallData(
        bytes[] memory callData
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("multiCall(bytes[])", callData);
    }

    function getDepositData(
        address from,
        address collateral,
        uint256 amount,
        address to
    ) external pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "deposit(address,address,uint256,address)",
                from,
                collateral,
                amount,
                to
            );
    }

    function getBorrowData(
        uint256 amount,
        address to,
        bool isDepositToJOJO
    ) external pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "borrow(uint256,address,bool)",
                amount,
                to,
                isDepositToJOJO
            );
    }

    function getRepayData(
        uint256 amount,
        address to
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("repay(uint256,address)", amount, to);
    }

    function getSetOperator(
        address operator,
        bool isValid
    ) external pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "setOperator(address,bool)",
                operator,
                isValid
            );
    }

    function getWithdrawData(
        address collateral,
        uint256 amount,
        address to,
        bool isInternal
    ) external pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "withdraw(address,uint256,address,bool)",
                collateral,
                amount,
                to,
                isInternal
            );
    }
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

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

interface IPriceChainLink {
    //    get token address price
    function getAssetPrice() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
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
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
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
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
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
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
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
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
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
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
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
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
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
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
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
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
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
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
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
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
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
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
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
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
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
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
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
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
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
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
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
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
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
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
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
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
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
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
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
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
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
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
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
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
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
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
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
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
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
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
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

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

library DecimalMath {
    uint256 constant ONE = 1e18;

    function decimalMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function decimalDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function decimalRemainder(uint256 a, uint256 b) internal pure returns (bool) {
        if ((a * ONE) % b == 0) {
            return true;
        } else {
            return false;
        }
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.9;

library DataTypes {
    struct ReserveInfo {
        //    the initial mortgage rate of collateral
        //        1e18 based decimal
        uint256 initialMortgageRate;
        //        max total deposit collateral amount
        uint256 maxTotalDepositAmount;
        //        max deposit collateral amount per account
        uint256 maxDepositAmountPerAccount;
        //        the collateral max deposit value, protect from oracle
        uint256 maxColBorrowPerAccount;
        //        oracle address
        address oracle;
        //        total deposit amount
        uint256 totalDepositAmount;
        //        liquidation mortgage rate
        uint256 liquidationMortgageRate;
        /*
            The discount rate for the liquidation.
            price * (1 - liquidationPriceOff)
            1e18 based decimal.
        */
        uint256 liquidationPriceOff;
        //         insurance fee rate
        uint256 insuranceFeeRate;
        /*       
            if the mortgage collateral delisted.
            if isFinalLiquidation = true which means user can not deposit collateral and borrow USDO
        */
        bool isFinalLiquidation;
        //        if allow user deposit collateral
        bool isDepositAllowed;
        //        if allow user borrow USDO
        bool isBorrowAllowed;
    }

    /// @notice user param
    struct UserInfo {
        //        deposit collateral ==> deposit amount
        mapping(address => uint256) depositBalance;
        
        mapping(address => bool) hasCollateral;
        //        t0 borrow USDO amount
        uint256 t0BorrowBalance;
        //        user deposit collateral list
        address[] collateralList;
    }

    struct LiquidateData {
        uint256 actualCollateral;
        uint256 insuranceFee;
        uint256 actualLiquidatedT0;
        uint256 actualLiquidated;
        uint256 liquidatedRemainUSDC;
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

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity ^0.8.9;

abstract contract FlashLoanReentrancyGuard {
    uint256 private constant _CAN_FLASHLOAN = 1;
    uint256 private constant _CAN_NOT_FLASHLOAN = 2;

    uint256 private _status;

    constructor() {
        _status = _CAN_FLASHLOAN;
    }

    modifier nonFlashLoanReentrant() {
        require(_status != _CAN_NOT_FLASHLOAN, "ReentrancyGuard: Withdraw or Borrow or Liquidate flashLoan reentrant call");

        _status = _CAN_NOT_FLASHLOAN;

        _;

        _status = _CAN_FLASHLOAN;
    }
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/
pragma solidity ^0.8.0;

library JOJOConstant {
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    uint256 public constant ONE = 1e18;
}

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1*/

pragma solidity 0.8.9;

library JUSDErrors {
    string constant RESERVE_NOT_ALLOW_DEPOSIT = "RESERVE_NOT_ALLOW_DEPOSIT";
    string constant DEPOSIT_AMOUNT_IS_ZERO = "DEPOSIT_AMOUNT_IS_ZERO";
    string constant REPAY_AMOUNT_IS_ZERO = "REPAY_AMOUNT_IS_ZERO";
    string constant WITHDRAW_AMOUNT_IS_ZERO = "WITHDRAW_AMOUNT_IS_ZERO";
    string constant LIQUIDATE_AMOUNT_IS_ZERO = "LIQUIDATE_AMOUNT_IS_ZERO";
    string constant AFTER_BORROW_ACCOUNT_IS_NOT_SAFE =
        "AFTER_BORROW_ACCOUNT_IS_NOT_SAFE";
    string constant AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE =
        "AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE";
    string constant AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE =
        "AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE";
    string constant EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT =
        "EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT";
    string constant EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL =
        "EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL";
    string constant EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT =
        "EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT";
    string constant EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL =
        "EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL";
    string constant ACCOUNT_IS_SAFE = "ACCOUNT_IS_SAFE";
    string constant WITHDRAW_AMOUNT_IS_TOO_BIG = "WITHDRAW_AMOUNT_IS_TOO_BIG";
    string constant CAN_NOT_OPERATE_ACCOUNT = "CAN_NOT_OPERATE_ACCOUNT";
    string constant SELF_LIQUIDATION_NOT_ALLOWED =
        "SELF_LIQUIDATION_NOT_ALLOWED";
    string constant LIQUIDATION_PRICE_PROTECTION =
        "LIQUIDATION_PRICE_PROTECTION";
    string constant NOT_ALLOWED_TO_EXCHANGE = "NOT_ALLOWED_TO_EXCHANGE";
    string constant NO_MORE_RESERVE_ALLOWED = "NO_MORE_RESERVE_ALLOWED";
    string constant RESERVE_PARAM_ERROR = "RESERVE_PARAM_ERROR";
    string constant REPAY_AMOUNT_NOT_ENOUGH = "REPAY_AMOUNT_NOT_ENOUGH";
    string constant INSURANCE_AMOUNT_NOT_ENOUGH = "INSURANCE_AMOUNT_NOT_ENOUGH";
    string constant LIQUIDATED_AMOUNT_NOT_ENOUGH =
        "LIQUIDATED_AMOUNT_NOT_ENOUGH";

    string constant LIQUIDATOR_NOT_IN_THE_WHITELIST = "LIQUIDATOR_NOT_IN_THE_WHITELIST";
    string constant RESERVE_PARAM_WRONG = "RESERVE_PARAM_WRONG";

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