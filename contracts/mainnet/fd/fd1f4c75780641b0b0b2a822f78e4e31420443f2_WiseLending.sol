// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author René Hochmuth
 * @author Christoph Krpoun
 * @author Vitally Marinchenko
 */

import "./PoolManager.sol";

/**
 * @dev WISE lending is an automated lending platform on which users can collateralize
 * their assets and borrow tokens against them.
 *
 * Users need to pay borrow rates for debt tokens, which are reflected in a borrow APY for
 * each asset type (pool). This borrow rate is variable over time and determined through the
 * utilization of the pool. The bounding curve is a family of different bonding curves adjusted
 * automatically by LASA (Lending Automated Scaling Algorithm). For more information, see:
 * [https://wisesoft.gitbook.io/wise/wise-lending-protocol/lasa-ai]
 *
 * In addition to normal deposit, withdraw, borrow, and payback functions, there are other
 * interacting modes:
 *
 * - Solely deposit and withdraw allows the user to keep their funds private, enabling
 *    them to withdraw even when the pools are borrowed empty.
 *
 * - Aave pools  allow for maximal capital efficiency by earning aave supply APY for not
 *   borrowed funds.
 *
 * - Special curve pools nside beefy farms can be used as collateral, opening up new usage
 *   possibilities for these asset types.
 *
 * - Users can pay back their borrow with lending shares of the same asset type, making it
 *   easier to manage their positions.
 *
 * - Users save their collaterals and borrows inside a position NFT, making it possible
 *   to trade their whole positions or use them in second-layer contracts
 *   (e.g., spot trading with PTP NFT trading platforms).
 */

contract WiseLending is PoolManager {

    /**
     * @dev Standard receive functions forwarding
     * directly send ETH to the master address.
     */
    receive()
        external
        payable
    {
        if (msg.sender == WETH_ADDRESS) {
            return;
        }

        _sendValue(
            master,
            msg.value
        );
    }

    /**
     * @dev Checks if position is healthy
     * after all state changes are done.
     */
    modifier healthStateCheck(
        uint256 _nftId
    ) {
        _;

        _healthStateCheck(
            _nftId
        );
    }

    function _healthStateCheck(
        uint256 _nftId
    )
        private
    {
        _checkHealthState(
            _nftId,
            powerFarmCheck
        );

        if (powerFarmCheck == true) {
            powerFarmCheck = false;
        }
    }

    /**
     * @dev Runs the LASA algorithm known as
     * Lending Automated Scaling Algorithm
     * and updates pool data based on token
     */
    modifier syncPool(
        address _poolToken
    ) {
        _syncPoolBeforeCodeExecution(
            _poolToken
        );

        (
            uint256 lendSharePrice,
            uint256 borrowSharePrice
        ) = _getSharePrice(
            _poolToken
        );

        _;

        _syncPoolAfterCodeExecution(
            _poolToken,
            lendSharePrice,
            borrowSharePrice
        );
    }

    constructor(
        address _master,
        address _wiseOracleHubAddress,
        address _nftContract
    )
        WiseLendingDeclaration(
            _master,
            _wiseOracleHubAddress,
            _nftContract
        )
    {}

    function _emitFundsSolelyWithdrawn(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        private
    {
        emit FundsSolelyWithdrawn(
            _caller,
            _nftId,
            _poolToken,
            _amount,
            block.timestamp
        );
    }

    function _emitFundsSolelyDeposited(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        private
    {
        emit FundsSolelyDeposited(
            _caller,
            _nftId,
            _poolToken,
            _amount,
            block.timestamp
        );
    }

    /**
     * @dev Fetches share price of lending shares.
     */
    function _getSharePrice(
        address _poolToken
    )
        private
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 borrowSharePrice = borrowPoolData[_poolToken].pseudoTotalBorrowAmount
            * PRECISION_FACTOR_E18
            / borrowPoolData[_poolToken].totalBorrowShares;

        _validateParameter(
            PRECISION_FACTOR_E18,
            borrowSharePrice
        );

        return (
            lendingPoolData[_poolToken].pseudoTotalPool
                * PRECISION_FACTOR_E18
                / lendingPoolData[_poolToken].totalDepositShares,
            borrowSharePrice
        );
    }

    function _checkHealthState(
        uint256 _nftId,
        bool _powerFarm
    )
        internal
        view
    {
        WISE_SECURITY.checkHealthState(
            _nftId,
            _powerFarm
        );
    }

    /**
     * @dev Compares share prices before and after
     * execution. If borrow share price increased
     * or lending share price decreased, revert.
     */
    function _compareSharePrices(
        address _poolToken,
        uint256 _lendSharePriceBefore,
        uint256 _borrowSharePriceBefore
    )
        private
        view
    {
        (
            uint256 lendSharePriceAfter,
            uint256 borrowSharePriceAfter
        ) = _getSharePrice(
            _poolToken
        );

        uint256 currentSharePriceMax = _getCurrentSharePriceMax(
            _poolToken
        );

        _validateParameter(
            _lendSharePriceBefore,
            lendSharePriceAfter
        );

        _validateParameter(
            lendSharePriceAfter,
            currentSharePriceMax
        );

        _validateParameter(
            _borrowSharePriceBefore,
            currentSharePriceMax
        );

        _validateParameter(
            borrowSharePriceAfter,
            _borrowSharePriceBefore
        );
    }

    /**
    * @dev Since pool inception share price
    * increase for both lending and borrow shares
    * is capped at 500% apr max in between a transaction.
    */
    function _getCurrentSharePriceMax(
        address _poolToken
    )
        private
        view
        returns (uint256)
    {
        uint256 timeDifference = block.timestamp
            - timestampsPoolData[_poolToken].initialTimeStamp;

        return timeDifference
            * RESTRICTION_FACTOR
            + PRECISION_FACTOR_E18;
    }

    /**
     * @dev First part of pool sync updating pseudo
     * amounts. Is skipped when powerFarms or aaveHub
     * is calling the function.
     */
    function _syncPoolBeforeCodeExecution(
        address _poolToken
    )
        private
    {
        _checkReentrancy();

        _preparePool(
            _poolToken
        );

        if (_aboveThreshold(_poolToken) == false) {
            return;
        }

        _scalingAlgorithm(
            _poolToken
        );
    }

    /**
     * @dev Second part of pool sync updating
     * the borrow pool rate and share price.
     */
    function _syncPoolAfterCodeExecution(
        address _poolToken,
        uint256 _lendSharePriceBefore,
        uint256 _borrowSharePriceBefore
    )
        private
    {
        _newBorrowRate(
            _poolToken
        );

        _compareSharePrices(
            _poolToken,
            _lendSharePriceBefore,
            _borrowSharePriceBefore
        );
    }

    /**
     * @dev Enables _poolToken to be used as a collateral.
     */
    function collateralizeDeposit(
        uint256 _nftId,
        address _poolToken
    )
        external
        syncPool(_poolToken)
    {
        WISE_SECURITY.checksCollateralizeDeposit(
            _nftId,
            msg.sender,
            _poolToken
        );

        userLendingData[_nftId][_poolToken].unCollateralized = false;
    }

    /**
     * @dev Disables _poolToken to be used as a collateral.
     */
    function unCollateralizeDeposit(
        uint256 _nftId,
        address _poolToken
    )
        external
        syncPool(_poolToken)
    {
        _checkOwnerPosition(
            _nftId,
            msg.sender
        );

        (
            address[] memory lendTokens,
            address[] memory borrowTokens
        ) = _prepareAssociatedTokens(
            _nftId,
            _poolToken,
            ZERO_ADDRESS
        );

        userLendingData[_nftId][_poolToken].unCollateralized = true;

        WISE_SECURITY.checkUncollateralizedDeposit(
            _nftId,
            _poolToken
        );

        _curveSecurityChecks(
            lendTokens,
            borrowTokens
        );
    }

    // --------------- Deposit Functions -------------

    /**
     * @dev Allows to supply funds using ETH.
     * Without converting to WETH, use ETH directly.
     */
    function depositExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        return _depositExactAmountETH(
            _nftId
        );
    }

    function _depositExactAmountETH(
        uint256 _nftId
    )
        private
        returns (uint256)
    {
        uint256 shareAmount = _handleDeposit(
            msg.sender,
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        _wrapETH(
            msg.value
        );

        return shareAmount;
    }

    /**
     * @dev Allows to supply funds using ETH.
     * Without converting to WETH, use ETH directly,
     * also mints position to avoid extra transaction.
     */
    function depositExactAmountETHMint()
        external
        payable
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        return _depositExactAmountETH(
            _reservePosition()
        );
    }

    /**
     * @dev Allows to supply _poolToken and user
     * can decide if _poolToken should be collateralized,
     * also mints position to avoid extra transaction.
     */
    function depositExactAmountMint(
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256)
    {
        return depositExactAmount(
            _reservePosition(),
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Allows to supply _poolToken and user
     * can decide if _poolToken should be collateralized.
     */
    function depositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        public
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 shareAmount = _handleDeposit(
            msg.sender,
            _nftId,
            _poolToken,
            _amount
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            _amount
        );

        return shareAmount;
    }

    /**
     * @dev Allows to supply funds using ETH in solely mode,
     * which does not earn APY, but keeps the funds private.
     * Other users are restricted from borrowing these funds,
     * owner can always withdraw even if all funds are borrowed.
     * Also mints position to avoid extra transaction.
     */
    function solelyDepositETHMint()
        external
        payable
    {
        solelyDepositETH(
            _reservePosition()
        );
    }

    /**
     * @dev Allows to supply funds using ETH in solely mode,
     * which does not earn APY, but keeps the funds private.
     * Other users are restricted from borrowing these funds,
     * owner can always withdraw even if all funds are borrowed.
     */
    function solelyDepositETH(
        uint256 _nftId
    )
        public
        payable
        syncPool(WETH_ADDRESS)
    {
        _handleSolelyDeposit(
            msg.sender,
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        _wrapETH(
            msg.value
        );

        _emitFundsSolelyDeposited(
            msg.sender,
            _nftId,
            WETH_ADDRESS,
            msg.value
        );
    }

    /**
     * @dev Core function combining
     * supply logic with security
     * checks for solely deposit.
     */
    function _handleSolelyDeposit(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        private
    {
        _checkDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _increaseMappingValue(
            pureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );

        _increaseTotalBareToken(
            _poolToken,
            _amount
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendTokenData
        );
    }

    /**
     * @dev Allows to supply funds using ERC20 in solely mode,
     * which does not earn APY, but keeps the funds private.
     * Other users are restricted from borrowing these funds,
     * owner can always withdraw even if all funds are borrowed.
     * Also mints position to avoid extra transaction.
     */
    function solelyDepositMint(
        address _poolToken,
        uint256 _amount
    )
        external
    {
        solelyDeposit(
            _reservePosition(),
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Allows to supply funds using ERC20 in solely mode,
     * which does not earn APY, but keeps the funds private.
     * Other users are restricted from borrowing these funds,
     * owner can always withdraw even if all funds are borrowed.
     */
    function solelyDeposit(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        public
        syncPool(_poolToken)
    {
        _handleSolelyDeposit(
            msg.sender,
            _nftId,
            _poolToken,
            _amount
        );

        _emitFundsSolelyDeposited(
            msg.sender,
            _nftId,
            _poolToken,
            _amount
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            _amount
        );
    }

    // --------------- Withdraw Functions -------------

    /**
     * @dev Allows to withdraw publicly
     * deposited ETH funds using exact amount.
     */
    function withdrawExactAmountETH(
        uint256 _nftId,
        uint256 _amount
    )
        external
        syncPool(WETH_ADDRESS)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 withdrawShares = _handleWithdrawAmount(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: WETH_ADDRESS,
                _amount: _amount,
                _onBehalf: false
            }
        );

        _validateNonZero(
            withdrawShares
        );

        _unwrapETH(
            _amount
        );

        _sendValue(
            msg.sender,
            _amount
        );

        return withdrawShares;
    }

    /**
     * @dev Allows to withdraw publicly
     * deposited ETH funds using exact shares.
     */
    function withdrawExactSharesETH(
        uint256 _nftId,
        uint256 _shares
    )
        external
        syncPool(WETH_ADDRESS)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 withdrawAmount = _handleWithdrawShares(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: WETH_ADDRESS,
                _shares: _shares,
                _onBehalf: false
            }
        );

        _validateNonZero(
            withdrawAmount
        );

        _unwrapETH(
            withdrawAmount
        );

        _sendValue(
            msg.sender,
            withdrawAmount
        );

        return withdrawAmount;
    }

    /**
     * @dev Allows to withdraw publicly
     * deposited ERC20 funds using exact amount.
     */
    function withdrawExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _withdrawAmount
    )
        external
        syncPool(_poolToken)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 withdrawShares = _handleWithdrawAmount(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _amount: _withdrawAmount,
                _onBehalf: false
            }
        );

        _validateNonZero(
            withdrawShares
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _withdrawAmount
        );

        return withdrawShares;
    }

    /**
     * @dev Allows to withdraw privately
     * deposited ETH funds using input amount.
     */
    function solelyWithdrawETH(
        uint256 _nftId,
        uint256 _withdrawAmount
    )
        external
        syncPool(WETH_ADDRESS)
        healthStateCheck(_nftId)
    {
        _handleSolelyWithdraw(
            msg.sender,
            _nftId,
            WETH_ADDRESS,
            _withdrawAmount
        );

        _unwrapETH(
            _withdrawAmount
        );

        _sendValue(
            msg.sender,
            _withdrawAmount
        );
    }

    /**
     * @dev Allows to withdraw privately
     * deposited ERC20 funds using input amount.
     */
    function solelyWithdraw(
        uint256 _nftId,
        address _poolToken,
        uint256 _withdrawAmount
    )
        external
        syncPool(_poolToken)
        healthStateCheck(_nftId)
    {
        _handleSolelyWithdraw(
            msg.sender,
            _nftId,
            _poolToken,
            _withdrawAmount
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _withdrawAmount
        );
    }

    /**
     * @dev Core function combining
     * withdraw logic for solely
     * withdraw with security checks.
     */
    function _coreSolelyWithdraw(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        private
    {
        (
            address[] memory lendTokens,
            address[] memory borrowTokens
        ) = _prepareAssociatedTokens(
            _nftId,
            _poolToken,
            ZERO_ADDRESS
        );

        powerFarmCheck = WISE_SECURITY.checksSolelyWithdraw(
            _nftId,
            _caller,
            _poolToken
        );

        _decreasePositionMappingValue(
            pureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );

        _decreaseTotalBareToken(
            _poolToken,
            _amount
        );

        _removeEmptyLendingData(
            _nftId,
            _poolToken
        );

        _curveSecurityChecks(
            lendTokens,
            borrowTokens
        );
    }

    /**
     * @dev Allows to withdraw privately
     * deposited ERC20 on behalf of owner.
     * Requires approval by _nftId owner.
     */
    function withdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _withdrawAmount
    )
        external
        onlyAaveHub
        syncPool(_poolToken)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 withdrawShares = calculateLendingShares(
            {
                _poolToken: _poolToken,
                _amount: _withdrawAmount,
                _maxSharePrice: true
            }
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _amount: _withdrawAmount,
                _shares: withdrawShares,
                _onBehalf: true
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _withdrawAmount
        );

        return withdrawShares;
    }

    /**
     * @dev Allows to withdraw ERC20
     * funds using shares as input value
     */
    function withdrawExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        syncPool(_poolToken)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 withdrawAmount = _handleWithdrawShares(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _shares: _shares,
                _onBehalf: false
            }
        );

        _validateNonZero(
            withdrawAmount
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            withdrawAmount
        );

        return withdrawAmount;
    }

    /**
     * @dev Withdraws ERC20 funds on behalf
     * of _nftId owner, requires approval.
     */
    function withdrawOnBehalfExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        onlyAaveHub
        syncPool(_poolToken)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 withdrawAmount = _handleWithdrawShares(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _shares: _shares,
                _onBehalf: true
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            withdrawAmount
        );

        return withdrawAmount;
    }

    // --------------- Borrow Functions -------------

    /**
     * @dev Allows to borrow ETH funds
     * Requires user to have collateral.
     */
    function borrowExactAmountETH(
        uint256 _nftId,
        uint256 _amount
    )
        external
        syncPool(WETH_ADDRESS)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        _checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 shares = _handleBorrowExactAmount({
            _nftId: _nftId,
            _poolToken: WETH_ADDRESS,
            _amount: _amount,
            _onBehalf: false
        });

        _validateNonZero(
            shares
        );

        _unwrapETH(
            _amount
        );

        _sendValue(
            msg.sender,
            _amount
        );

        return shares;
    }

    /**
     * @dev Allows to borrow ERC20 funds
     * Requires user to have collateral.
     */
    function borrowExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        _checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 shares = _handleBorrowExactAmount({
            _nftId: _nftId,
            _poolToken: _poolToken,
            _amount: _amount,
            _onBehalf: false
        });

        _validateNonZero(
            shares
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _amount
        );

        return shares;
    }

    /**
     * @dev Allows to borrow ERC20 funds
     * on behalf of _nftId owner, if approved.
     */
    function borrowOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        onlyAaveHub
        syncPool(_poolToken)
        healthStateCheck(_nftId)
        returns (uint256)
    {
        uint256 shares = _handleBorrowExactAmount({
            _nftId: _nftId,
            _poolToken: _poolToken,
            _amount: _amount,
            _onBehalf: true
        });

        _safeTransfer(
            _poolToken,
            msg.sender,
            _amount
        );

        return shares;
    }

    // --------------- Payback Functions ------------

    /**
     * @dev Ability to payback ETH loans
     * by providing exact payback amount.
     */
    function paybackExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        uint256 maxBorrowShares = userBorrowShares[_nftId][WETH_ADDRESS];

        _validateNonZero(
            maxBorrowShares
        );

        uint256 maxPaybackAmount = paybackAmount(
            WETH_ADDRESS,
            maxBorrowShares
        );

        uint256 paybackShares = calculateBorrowShares(
            {
                _poolToken: WETH_ADDRESS,
                _amount: msg.value,
                _maxSharePrice: false
            }
        );

        _validateNonZero(
            paybackShares
        );

        uint256 refundAmount;
        uint256 requiredAmount = msg.value;

        if (msg.value > maxPaybackAmount) {

            unchecked {
                refundAmount = msg.value
                    - maxPaybackAmount;
            }

            requiredAmount = requiredAmount
                - refundAmount;

            paybackShares = maxBorrowShares;
        }

        _handlePayback(
            msg.sender,
            _nftId,
            WETH_ADDRESS,
            requiredAmount,
            paybackShares
        );

        _wrapETH(
            requiredAmount
        );

        if (refundAmount > 0) {
            _sendValue(
                msg.sender,
                refundAmount
            );
        }

        return paybackShares;
    }

    /**
     * @dev Ability to payback ERC20 loans
     * by providing exact payback amount.
     */
    function paybackExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 paybackShares = calculateBorrowShares(
            {
                _poolToken: _poolToken,
                _amount: _amount,
                _maxSharePrice: false
            }
        );

        _validateNonZero(
            paybackShares
        );

        _handlePayback(
            msg.sender,
            _nftId,
            _poolToken,
            _amount,
            paybackShares
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            _amount
        );

        return paybackShares;
    }

    /**
     * @dev Ability to payback ERC20 loans
     * by providing exact payback shares.
     */
    function paybackExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 repaymentAmount = paybackAmount(
            _poolToken,
            _shares
        );

        _validateNonZero(
            repaymentAmount
        );

        _handlePayback(
            msg.sender,
            _nftId,
            _poolToken,
            repaymentAmount,
            _shares
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            repaymentAmount
        );

        return repaymentAmount;
    }

    // --------------- Liquidation Functions ------------

    /**
     * @dev Function to liquidate a postion which reaches
     * a debt ratio greater than 100%. The liquidator can choose
     * token to payback and receive. (Both can differ!). The
     * amount is in shares of the payback token. The liquidator
     * gets an incentive which is calculated inside the liquidation
     * logic.
     */
    function liquidatePartiallyFromTokens(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _paybackToken,
        address _receiveToken,
        uint256 _shareAmountToPay
    )
        external
        syncPool(_paybackToken)
        syncPool(_receiveToken)
        returns (uint256)
    {
        CoreLiquidationStruct memory data;

        data.nftId = _nftId;
        data.nftIdLiquidator = _nftIdLiquidator;

        data.caller = msg.sender;

        data.tokenToPayback = _paybackToken;
        data.tokenToRecieve = _receiveToken;
        data.shareAmountToPay = _shareAmountToPay;

        data.maxFeeETH = WISE_SECURITY.maxFeeETH();
        data.baseRewardLiquidation = WISE_SECURITY.baseRewardLiquidation();

        (
            data.lendTokens,
            data.borrowTokens
        ) = _prepareAssociatedTokens(
            _nftId,
            _receiveToken,
            _paybackToken
        );

        data.paybackAmount = paybackAmount(
            _paybackToken,
            _shareAmountToPay
        );

        _checkPositionLocked(
            _nftId,
            msg.sender
        );

        _checkLiquidatorNft(
            _nftId,
            _nftIdLiquidator
        );

        WISE_SECURITY.checksLiquidation(
            _nftId,
            _paybackToken,
            _shareAmountToPay
        );

        return _coreLiquidation(
            data
        );
    }

    /**
     * @dev Wrapper function for liqudaiton flow
     */
    function coreLiquidationIsolationPools(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _caller,
        address _paybackToken,
        address _receiveToken,
        uint256 _paybackAmount,
        uint256 _shareAmountToPay
    )
        external
        syncPool(_paybackToken)
        syncPool(_receiveToken)
        returns (uint256)
    {
        CoreLiquidationStruct memory data;

        data.nftId = _nftId;
        data.nftIdLiquidator = _nftIdLiquidator;

        data.caller = _caller;

        data.paybackAmount = _paybackAmount;
        data.tokenToPayback = _paybackToken;
        data.tokenToRecieve = _receiveToken;
        data.shareAmountToPay = _shareAmountToPay;

        data.maxFeeETH = WISE_SECURITY.maxFeeFarmETH();
        data.baseRewardLiquidation = WISE_SECURITY.baseRewardLiquidationFarm();

        _validateIsolationPoolLiquidation(
            msg.sender,
            data.nftId,
            data.nftIdLiquidator
        );

        (
            data.lendTokens,
            data.borrowTokens
        ) = _prepareAssociatedTokens(
            data.nftId,
            data.tokenToRecieve,
            data.tokenToPayback
        );

        return _coreLiquidation(
            data
        );
    }

    /**
     * @dev Allows to sync pool manually
     * so that the pool is up to date.
     */
    function syncManually(
        address _poolToken
    )
        external
        syncPool(_poolToken)
    {
        address[] memory tokens = new address[](1);
        tokens[0] = _poolToken;

        _curveSecurityChecks(
            new address[](0),
            tokens
        );
    }

    /**
     * @dev Registers position _nftId
     * for isolation pool functionality
     */
    function setRegistrationIsolationPool(
        uint256 _nftId,
        bool _registerState
    )
        external
    {
        _onlyIsolationPool(
            msg.sender
        );

        _validateZero(
            WISE_SECURITY.overallETHCollateralsBare(_nftId)
        );

        _validateZero(
            WISE_SECURITY.overallETHBorrowBare(_nftId)
        );

        positionLocked[_nftId] = _registerState;
    }

    /**
    * @dev External wrapper for
    * {_corePayback} logic callable
    * by feeMananger.
    */
    function corePaybackFeeManager(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external
        onlyFeeManager
        syncPool(_poolToken)
    {
        _corePayback(
            _nftId,
            _poolToken,
            _amount,
            _shares
        );
    }

    /**
     * @dev Internal function combining payback
     * logic and emit of an event.
     */
    function _handlePayback(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        private
    {
        _corePayback(
            _nftId,
            _poolToken,
            _amount,
            _shares
        );

        emit FundsReturned(
            _caller,
            _poolToken,
            _nftId,
            _amount,
            _shares,
            block.timestamp
        );
    }

    function _handleWithdrawAmount(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        bool _onBehalf
    )
        private
        returns (uint256 withdrawShares)
    {
        withdrawShares = _preparationsWithdraw(
            _nftId,
            msg.sender,
            _poolToken,
            _amount
        );

        _coreWithdrawToken(
            {
                _caller: _caller,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _amount: _amount,
                _shares: withdrawShares,
                _onBehalf: _onBehalf
            }
        );
    }

    function _handleSolelyWithdraw(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        private
    {
        _checkOwnerPosition(
            _nftId,
            _caller
        );

        _coreSolelyWithdraw(
            _caller,
            _nftId,
            _poolToken,
            _amount
        );

        _emitFundsSolelyWithdrawn(
            _caller,
            _nftId,
            _poolToken,
            _amount
        );
    }

    function _handleWithdrawShares(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _shares,
        bool _onBehalf
    )
        private
        returns (uint256)
    {
        if (_onBehalf == false) {
            _checkOwnerPosition(
                _nftId,
                _caller
            );
        }

        uint256 withdrawAmount = _cashoutAmount(
            _poolToken,
            _shares
        );

        _coreWithdrawToken(
            {
                _caller: _caller,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _amount: withdrawAmount,
                _shares: _shares,
                _onBehalf: _onBehalf
            }
        );

        return withdrawAmount;
    }

    function _handleBorrowExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        bool _onBehalf
    )
        private
        returns (uint256)
    {
        uint256 shares = calculateBorrowShares(
            {
                _poolToken: _poolToken,
                _amount: _amount,
                _maxSharePrice: true
            }
        );

        _coreBorrowTokens(
            {
                _caller: msg.sender,
                _nftId: _nftId,
                _poolToken: _poolToken,
                _amount: _amount,
                _shares: shares,
                _onBehalf: _onBehalf
            }
        );

        return shares;
    }

    /**
     * @dev Internal helper function for reservating a
     * position NFT id.
     */
    function _reservePosition()
        private
        returns (uint256)
    {
        return POSITION_NFT.reservePositionForUser(
            msg.sender
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./WiseCore.sol";
import "./Babylonian.sol";

abstract contract PoolManager is WiseCore {

    using Babylonian for uint256;

    struct CreatePool {
        bool allowBorrow;
        address poolToken;
        uint256 poolMulFactor;
        uint256 poolCollFactor;
        uint256 maxDepositAmount;
    }

    struct CurvePoolSettings {
        CurveSwapStructData curveSecuritySwapsData;
        CurveSwapStructToken curveSecuritySwapsToken;
    }

    function setParamsLASA(
        address _poolToken,
        uint256 _poolMulFactor,
        uint256 _upperBoundMaxRate,
        uint256 _lowerBoundMaxRate,
        bool _steppingDirection,
        bool _isFinal
    )
        external
        onlyMaster
    {
        if (parametersLocked[_poolToken] == true) {
            revert InvalidAction();
        }

        parametersLocked[_poolToken] = _isFinal;

        AlgorithmEntry storage algoData = algorithmData[
            _poolToken
        ];

        algoData.increasePole = _steppingDirection;

        _validateParameter(
            _upperBoundMaxRate,
            UPPER_BOUND_MAX_RATE
        );

        _validateParameter(
            _lowerBoundMaxRate,
            LOWER_BOUND_MAX_RATE
        );

        _validateParameter(
            _lowerBoundMaxRate,
            _upperBoundMaxRate
        );

        uint256 staticMinPole = _getPoleValue(
            _poolMulFactor,
            _upperBoundMaxRate
        );

        uint256 staticMaxPole = _getPoleValue(
            _poolMulFactor,
            _lowerBoundMaxRate
        );

        uint256 staticDeltaPole = _getDeltaPole(
            staticMaxPole,
            staticMinPole
        );

        uint256 startValuePole = _getStartValue(
            staticMaxPole,
            staticMinPole
        );

        _validateParameter(
            _poolMulFactor,
            PRECISION_FACTOR_E18
        );

        borrowRatesData[_poolToken] = BorrowRatesEntry(
            startValuePole,
            staticDeltaPole,
            staticMinPole,
            staticMaxPole,
            _poolMulFactor
        );

        algoData.bestPole = startValuePole;
        algoData.maxValue = lendingPoolData[_poolToken].totalDepositShares;
    }

    function setPoolParameters(
        address _poolToken,
        uint256 _collateralFactor,
        uint256 _maximumDeposit
    )
        external
        onlyMaster
    {
        if (_maximumDeposit > 0) {
            maxDepositValueToken[_poolToken] = _maximumDeposit;
        }

        if (_collateralFactor > 0) {
            lendingPoolData[_poolToken].collateralFactor = _collateralFactor;
        }

        _validateParameter(
            _collateralFactor,
            PRECISION_FACTOR_E18
        );
    }

    /**
     * @dev Allow to verify isolation pool.
     */
    function setVerifiedIsolationPool(
        address _isolationPool,
        bool _state
    )
        external
        onlyMaster
    {
        verifiedIsolationPool[_isolationPool] = _state;
    }

    function createPool(
        CreatePool calldata _params
    )
        external
        onlyMaster
    {
        _createPool(
            _params
        );
    }

    function createCurvePool(
        CreatePool calldata _params,
        CurvePoolSettings calldata _settings
    )
        external
        onlyMaster
    {
        _createPool(
            _params
        );

        WISE_SECURITY.prepareCurvePools(
            _params.poolToken,
            _settings.curveSecuritySwapsData,
            _settings.curveSecuritySwapsToken
        );
    }

    function _createPool(
        CreatePool calldata _params
    )
        private
    {
        _validateParameter(
            timestampsPoolData[_params.poolToken].timeStamp,
            0
        );

        if (_params.poolToken == ZERO_ADDRESS) {
            revert InvalidAddress();
        }

        _validateParameter(
            _params.poolMulFactor,
            PRECISION_FACTOR_E18
        );

        _validateParameter(
            _params.poolCollFactor,
            MAX_COLLATERAL_FACTOR
        );

        // Calculating lower bound for the pole
        uint256 staticMinPole = _getPoleValue(
            _params.poolMulFactor,
            UPPER_BOUND_MAX_RATE
        );

        // Calculating upper bound for the pole
        uint256 staticMaxPole = _getPoleValue(
            _params.poolMulFactor,
            LOWER_BOUND_MAX_RATE
        );

        // Calculating fraction for algorithm step
        uint256 staticDeltaPole = _getDeltaPole(
            staticMaxPole,
            staticMinPole
        );

        maxDepositValueToken[_params.poolToken] = _params.maxDepositAmount;

        globalPoolData[_params.poolToken] = GlobalPoolEntry({
            totalPool: 0,
            utilization: 0,
            totalBareToken: 0,
            poolFee: 20 * PRECISION_FACTOR_E16
        });

        // Setting start value as mean of min and max value
        uint256 startValuePole = _getStartValue(
            staticMaxPole,
            staticMinPole
        );

        // Rates Pool Data
        borrowRatesData[_params.poolToken] = BorrowRatesEntry(
            startValuePole,
            staticDeltaPole,
            staticMinPole,
            staticMaxPole,
            _params.poolMulFactor
        );

        // Borrow Pool Data
        borrowPoolData[_params.poolToken] = BorrowPoolEntry({
            allowBorrow: _params.allowBorrow,
            pseudoTotalBorrowAmount: GHOST_AMOUNT,
            totalBorrowShares: GHOST_AMOUNT,
            borrowRate: 0
        });

        // Algorithm Pool Data
        algorithmData[_params.poolToken] = AlgorithmEntry({
            bestPole: startValuePole,
            maxValue: 0,
            previousValue: 0,
            increasePole: false
        });

        // Lending Pool Data
        lendingPoolData[_params.poolToken] = LendingPoolEntry({
            pseudoTotalPool: GHOST_AMOUNT,
            totalDepositShares: GHOST_AMOUNT,
            collateralFactor: _params.poolCollFactor
        });

        // Timestamp Pool Data
        timestampsPoolData[_params.poolToken] = TimestampsPoolEntry({
            timeStamp: block.timestamp,
            timeStampScaling: block.timestamp,
            initialTimeStamp: block.timestamp
        });

        FEE_MANAGER.addPoolTokenAddress(
            _params.poolToken
        );

        uint256 fetchBalance = _getBalance(
            _params.poolToken
        );

        if (fetchBalance > 0) {
            _safeTransfer(
                _params.poolToken,
                master,
                fetchBalance
            );
        }
    }

    function _getPoleValue(
        uint256 _poolMulFactor,
        uint256 _poleBoundRate
    )
        private
        pure
        returns (uint256)
    {
        return PRECISION_FACTOR_E18 / 2
            + (PRECISION_FACTOR_E36 / 4
                + _poolMulFactor
                    * PRECISION_FACTOR_E36
                    / _poleBoundRate
            ).sqrt();
    }

    function _getDeltaPole(
        uint256 _maxPole,
        uint256 _minPole
    )
        private
        pure
        returns (uint256)
    {
        return (_maxPole - _minPole) / NORMALISATION_FACTOR;
    }

    function _getStartValue(
        uint256 _maxPole,
        uint256 _minPole
    )
        private
        pure
        returns (uint256)
    {
        return (_maxPole + _minPole) / 2;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./MainHelper.sol";
import "./TransferHub/TransferHelper.sol";

abstract contract WiseCore is MainHelper, TransferHelper {

    /**
     * @dev Wrapper function combining pool
     * preparations for borrow and collaterals.
     * Bypassed when called by powerFarms.
     */
    function _prepareAssociatedTokens(
        uint256 _nftId,
        address _poolTokenLend,
        address _poolTokenBorrow
    )
        internal
        returns (
            address[] memory,
            address[] memory
        )
    {
        return (
            _preparationTokens(
                positionLendTokenData,
                _nftId,
                _poolTokenLend
            ),
            _preparationTokens(
                positionBorrowTokenData,
                _nftId,
                _poolTokenBorrow
            )
        );
    }

    /**
     * @dev Core function combining withdraw
     * logic and security checks.
     */
    function _coreWithdrawToken(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares,
        bool _onBehalf
    )
        internal
    {
        (
            address[] memory lendTokens,
            address[] memory borrowTokens
        ) = _prepareAssociatedTokens(
            _nftId,
            _poolToken,
            ZERO_ADDRESS
        );

        powerFarmCheck = WISE_SECURITY.checksWithdraw(
            _nftId,
            _caller,
            _poolToken
        );

        _coreWithdrawBare(
            _nftId,
            _poolToken,
            _amount,
            _shares
        );

        if (_onBehalf == true) {
            emit FundsWithdrawnOnBehalf(
                _caller,
                _nftId,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            );
        } else {
            emit FundsWithdrawn(
                _caller,
                _nftId,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            );
        }

        _curveSecurityChecks(
            lendTokens,
            borrowTokens
        );
    }

    /**
     * @dev Internal function combining deposit
     * logic, security checks and event emit.
     */
    function _handleDeposit(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        uint256 shareAmount = calculateLendingShares(
            {
                _poolToken: _poolToken,
                _amount: _amount,
                _maxSharePrice: false
            }
        );

        _validateNonZero(
            shareAmount
        );

        _checkDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _increasePositionLendingDeposit(
            _nftId,
            _poolToken,
            shareAmount
        );

        _updatePoolStorage(
            _poolToken,
            _amount,
            shareAmount,
            _increaseTotalPool,
            _increasePseudoTotalPool,
            _increaseTotalDepositShares
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendTokenData
        );

        emit FundsDeposited(
            _caller,
            _nftId,
            _poolToken,
            _amount,
            shareAmount,
            block.timestamp
        );

        return shareAmount;
    }

    /**
     * @dev External wrapper for
     * {_checkPositionLocked}.
     */

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view
    {
        _checkPositionLocked(
            _nftId,
            _caller
        );
    }

    /**
     * @dev Checks if a postion is locked
     * for powerFarms. Get skipped when
     * aaveHub or a powerFarm itself is
     * the {msg.sender}.
     */

    function _checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        internal
        view
    {
        if (_byPassCase(_caller) == true) {
            return;
        }

        if (positionLocked[_nftId] == false) {
            return;
        }

        revert PositionLocked();
    }

    /**
     * @dev External wrapper for
     * {_checkDeposit}.
     */
    function checkDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        _checkDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Internal function including
     * security checks for deposit logic.
     */
    function _checkDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        internal
        view
    {
        _checkPositionLocked(
            _nftId,
            _caller
        );

        WISE_SECURITY.checkPoolCondition(
            _poolToken
        );

        WISE_SECURITY.checkMinDepositValue(
            _poolToken,
            _amount
        );

        if (WISE_ORACLE.chainLinkIsDead(_poolToken) == true) {
            revert DeadOracle();
        }

        _checkMaxDepositValue(
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Internal function checking
     * if the deposit amount for the
     * pool token is reached.
     */
    function _checkMaxDepositValue(
        address _poolToken,
        uint256 _amount
    )
        private
        view
    {
        bool state = maxDepositValueToken[_poolToken]
            < globalPoolData[_poolToken].totalBareToken
            + lendingPoolData[_poolToken].pseudoTotalPool
            + _amount;

        if (state == true) {
            revert InvalidAction();
        }
    }

    /**
     * @dev Low level core function combining
     * pure withdraw math (without security
     * checks).
     */
    function _coreWithdrawBare(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        private
    {
        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _decreaseTotalPool,
            _decreasePseudoTotalPool,
            _decreaseTotalDepositShares
        );

        _decreaseLendingShares(
            _nftId,
            _poolToken,
            _shares
        );

        _removeEmptyLendingData(
            _nftId,
            _poolToken
        );
    }

    /**
     * @dev Core function combining borrow
     * logic with security checks.
     */
    function _coreBorrowTokens(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares,
        bool _onBehalf
    )
        internal
    {
        (
            address[] memory lendTokens,
            address[] memory borrowTokens
        ) = _prepareAssociatedTokens(
            _nftId,
            ZERO_ADDRESS,
            _poolToken
        );

        powerFarmCheck = WISE_SECURITY.checksBorrow(
            _nftId,
            _caller,
            _poolToken
        );

        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _increasePseudoTotalBorrowAmount,
            _decreaseTotalPool,
            _increaseTotalBorrowShares
        );

        _increaseMappingValue(
            userBorrowShares,
            _nftId,
            _poolToken,
            _shares
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionBorrow,
            positionBorrowTokenData
        );

        if (_onBehalf == true) {
            emit FundsBorrowedOnBehalf(
                _caller,
                _nftId,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            );
        } else {
            emit FundsBorrowed(
                _caller,
                _nftId,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            );
        }

        _curveSecurityChecks(
            lendTokens,
            borrowTokens
        );
    }

    /**
     * @dev Internal math function for liquidation logic
     * caluclating amount to withdraw from pure
     * collateral for liquidation.
     */
    function _withdrawPureCollateralLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _percentLiquidation
    )
        private
        returns (uint256 transferAmount)
    {
        uint256 product = _percentLiquidation
            * pureCollateralAmount[_nftId][_poolToken];

        transferAmount = product % PRECISION_FACTOR_E18 == 0
            ? product / PRECISION_FACTOR_E18
            : product / PRECISION_FACTOR_E18 + 1;

        _decreasePositionMappingValue(
            pureCollateralAmount,
            _nftId,
            _poolToken,
            transferAmount
        );

        _decreaseTotalBareToken(
            _poolToken,
            transferAmount
        );
    }

    /**
     * @dev Internal math function for liquidation logic
     * which checks if pool has enough token to pay out
     * liquidator. If not, liquidator get corresponding
     * shares for later withdraw.
     */
    function _withdrawOrAllocateSharesLiquidation(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _poolToken,
        uint256 _percentWishCollateral
    )
        private
        returns (uint256)
    {
        uint256 product = _percentWishCollateral
            * userLendingData[_nftId][_poolToken].shares;

        uint256 cashoutShares = product % PRECISION_FACTOR_E18 == 0
            ? product / PRECISION_FACTOR_E18
            : product / PRECISION_FACTOR_E18 + 1;

        uint256 withdrawAmount = _cashoutAmount(
            _poolToken,
            cashoutShares
        );

        uint256 totalPoolToken = globalPoolData[_poolToken].totalPool;

        if (withdrawAmount <= totalPoolToken) {

            _coreWithdrawBare(
                _nftId,
                _poolToken,
                withdrawAmount,
                cashoutShares
            );

            return withdrawAmount;
        }

        uint256 totalPoolInShares = calculateLendingShares(
            {
                _poolToken: _poolToken,
                _amount: totalPoolToken,
                _maxSharePrice: false
            }
        );

        uint256 shareDifference = cashoutShares
            - totalPoolInShares;

        _coreWithdrawBare(
            _nftId,
            _poolToken,
            totalPoolToken,
            totalPoolInShares
        );

        _decreaseLendingShares(
            _nftId,
            _poolToken,
            shareDifference
        );

        _increasePositionLendingDeposit(
            _nftIdLiquidator,
            _poolToken,
            shareDifference
        );

        _addPositionTokenData(
            _nftIdLiquidator,
            _poolToken,
            hashMapPositionLending,
            positionLendTokenData
        );

        _removeEmptyLendingData(
            _nftId,
            _poolToken
        );

        return totalPoolToken;
    }

    /**
     * @dev Internal math function combining functionallity
     * of {_withdrawPureCollateralLiquidation} and
     * {_withdrawOrAllocateSharesLiquidation}.
     */
    function _calculateReceiveAmount(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _receiveTokens,
        uint256 _removePercentage
    )
        private
        returns (uint256)
    {
        uint256 receiveAmount = _withdrawPureCollateralLiquidation(
            _nftId,
            _receiveTokens,
            _removePercentage
        );

        if (userLendingData[_nftId][_receiveTokens].unCollateralized == true) {
            return receiveAmount;
        }

        return _withdrawOrAllocateSharesLiquidation(
            _nftId,
            _nftIdLiquidator,
            _receiveTokens,
            _removePercentage
        ) + receiveAmount;
    }

    /**
     * @dev Core liquidation function for
     * security checks and liquidation math.
     */
    function _coreLiquidation(
        CoreLiquidationStruct memory _data
    )
        internal
        returns (uint256 receiveAmount)
    {
        _validateNonZero(
            _data.paybackAmount
        );

        uint256 collateralPercentage = WISE_SECURITY.calculateWishPercentage(
            _data.nftId,
            _data.tokenToRecieve,
            WISE_ORACLE.getTokensInETH(
                _data.tokenToPayback,
                _data.paybackAmount
            ),
            _data.maxFeeETH,
            _data.baseRewardLiquidation
        );

        _validateParameter(
            collateralPercentage,
            PRECISION_FACTOR_E18
        );

        _corePayback(
            _data.nftId,
            _data.tokenToPayback,
            _data.paybackAmount,
            _data.shareAmountToPay
        );

        receiveAmount = _calculateReceiveAmount(
            _data.nftId,
            _data.nftIdLiquidator,
            _data.tokenToRecieve,
            collateralPercentage
        );

        WISE_SECURITY.checkBadDebtLiquidation(
            _data.nftId
        );

        _curveSecurityChecks(
            _data.lendTokens,
            _data.borrowTokens
        );

        _safeTransferFrom(
            _data.tokenToPayback,
            _data.caller,
            address(this),
            _data.paybackAmount
        );

        _safeTransfer(
            _data.tokenToRecieve,
            _data.caller,
            receiveAmount
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

library Babylonian {

    function sqrt(
        uint256 x
    )
        internal
        pure
        returns (uint256)
    {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + (x / r)) >> 1;
        r = (r + (x / r)) >> 1;
        r = (r + (x / r)) >> 1;
        r = (r + (x / r)) >> 1;
        r = (r + (x / r)) >> 1;
        r = (r + (x / r)) >> 1;
        r = (r + (x / r)) >> 1;

        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./WiseLowLevelHelper.sol";

abstract contract MainHelper is WiseLowLevelHelper {

    /**
     * @dev Helper function to convert {_amount}
     * of a certain pool with {_poolToken}
     * into lending shares. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function calculateLendingShares(
        address _poolToken,
        uint256 _amount,
        bool _maxSharePrice
    )
        public
        view
        returns (uint256)
    {
        return _calculateShares(
            lendingPoolData[_poolToken].totalDepositShares * _amount,
            lendingPoolData[_poolToken].pseudoTotalPool,
            _maxSharePrice
        );
    }

    function _calculateShares(
        uint256 _product,
        uint256 _pseudo,
        bool _maxSharePrice
    )
        private
        pure
        returns (uint256)
    {
        return _maxSharePrice == true
            ? _product % _pseudo == 0
                ? _product / _pseudo
                : _product / _pseudo + 1
            : _product / _pseudo;
    }

    /**
     * @dev Helper function to convert {_amount}
     * of a certain pool with {_poolToken}
     * into borrow shares. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function calculateBorrowShares(
        address _poolToken,
        uint256 _amount,
        bool _maxSharePrice
    )
        public
        view
        returns (uint256)
    {
        return _calculateShares(
            borrowPoolData[_poolToken].totalBorrowShares * _amount,
            borrowPoolData[_poolToken].pseudoTotalBorrowAmount,
            _maxSharePrice
        );
    }

    /**
     * @dev Helper function to convert {_shares}
     * of a certain pool with {_poolToken}
     * into lending token. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function cashoutAmount(
        address _poolToken,
        uint256 _shares
    )
        external
        view
        returns (uint256)
    {
        return _cashoutAmount(
            _poolToken,
            _shares
        );
    }

    function _cashoutAmount(
        address _poolToken,
        uint256 _shares
    )
        internal
        view
        returns (uint256)
    {
        return _shares
            * lendingPoolData[_poolToken].pseudoTotalPool
            / lendingPoolData[_poolToken].totalDepositShares;
    }

    /**
     * @dev Helper function to convert {_shares}
     * of a certain pool with {_poolToken}
     * into borrow token. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function paybackAmount(
        address _poolToken,
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        uint256 product = _shares
            * borrowPoolData[_poolToken].pseudoTotalBorrowAmount;

        uint256 totalBorrowShares = borrowPoolData[_poolToken].totalBorrowShares;

        return product % totalBorrowShares == 0
            ? product / totalBorrowShares
            : product / totalBorrowShares + 1;
    }

    /**
     * @dev Internal helper combining one
     * security check with lending share
     * calculation for withdraw.
     */
    function _preparationsWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        _checkOwnerPosition(
            _nftId,
            _caller
        );

        return calculateLendingShares(
            {
                _poolToken: _poolToken,
                _amount: _amount,
                _maxSharePrice: true
            }
        );
    }

    /**
     * @dev Internal helper calculating {_poolToken}
     * utilization. Includes math underflow check.
     */
    function _getValueUtilization(
        address _poolToken
    )
        private
        view
        returns (uint256)
    {
        uint256 totalPool = globalPoolData[_poolToken].totalPool;
        uint256 pseudoPool = lendingPoolData[_poolToken].pseudoTotalPool;

        if (totalPool >= pseudoPool) {
            return 0;
        }

        return PRECISION_FACTOR_E18 - (PRECISION_FACTOR_E18
            * totalPool
            / pseudoPool
        );
    }

    /**
     * @dev Internal helper function setting new pool
     * utilization by calling {_getValueUtilization}.
     */
    function _updateUtilization(
        address _poolToken
    )
        private
    {
        globalPoolData[_poolToken].utilization = _getValueUtilization(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function checking if
     * cleanup gathered new token to save into
     * pool variables.
     */
    function _checkCleanUp(
        uint256 _amountContract,
        uint256 _totalPool,
        uint256 _bareAmount
    )
        private
        pure
        returns (bool)
    {
        return _bareAmount + _totalPool >= _amountContract;
    }

    /**
     * @dev Wrapper for isolation pool check.
     */
    function _onlyIsolationPool(
        address _poolAddress
    )
        internal
        view
    {
        if (verifiedIsolationPool[_poolAddress] == false) {
            revert InvalidAction();
        }
    }

    /**
     * @dev Internal helper function checking if
     * user inputs are safe.
     */
    function _validateIsolationPoolLiquidation(
        address _caller,
        uint256 _nftId,
        uint256 _nftIdLiquidator
    )
        internal
        view
    {
        _onlyIsolationPool(
            _caller
        );

        if (positionLocked[_nftId] == false) {
            revert NotPowerFarm();
        }

        _checkLiquidatorNft(
            _nftId,
            _nftIdLiquidator
        );

        if (POSITION_NFT.getOwner(_nftId) != _caller) {
            revert InvalidCaller();
        }
    }

    function _checkLiquidatorNft(
        uint256 _nftId,
        uint256 _nftIdLiquidator
    )
        internal
        view
    {
        if (positionLocked[_nftIdLiquidator] == true) {
            revert LiquidatorIsInPowerFarm();
        }

        if (_nftIdLiquidator == _nftId) {
            revert InvalidLiquidator();
        }
    }

    function _getBalance(
        address _tokenAddress
    )
        internal
        view
        returns (uint256)
    {
        return IERC20(_tokenAddress).balanceOf(
            address(this)
        );
    }

    /**
     * @dev Internal helper function checking if falsely
     * sent token are inside the contract for the pool with
     * {_poolToken}. If this is the case it adds those token
     * to the pool by increasing pseudo and total amount.
     * In context of aToken from aave pools it gathers the
     * rebase amount from supply APY of aave pools.
     */
    function _cleanUp(
        address _poolToken
    )
        internal
    {
        _validateNonZero(
            lendingPoolData[_poolToken].totalDepositShares
        );

        uint256 amountContract = _getBalance(
            _poolToken
        );

        uint256 totalPool = globalPoolData[_poolToken].totalPool;
        uint256 bareToken = globalPoolData[_poolToken].totalBareToken;

        if (_checkCleanUp(amountContract, totalPool, bareToken)) {
            return;
        }

        unchecked {

            uint256 difference = amountContract - (
                totalPool + bareToken
            );

            uint256 allowedDifference = _getAllowedDifference(
                _poolToken
            );

            if (difference > allowedDifference) {

                _increaseTotalAndPseudoTotalPool(
                    _poolToken,
                    allowedDifference
                );

                return;
            }

            _increaseTotalAndPseudoTotalPool(
                _poolToken,
                difference
            );
        }
    }

    /**
     * @dev Internal helper function calculating
     * allowed increase of pseudoTotalPool to
     * contain shareprice increase reasoanbly.
    */
    function _getAllowedDifference(
        address _poolToken
    )
        private
        view
        returns (uint256)
    {
        uint256 timeDifference = block.timestamp
            - timestampsPoolData[_poolToken].timeStamp;

        return timeDifference
            * lendingPoolData[_poolToken].pseudoTotalPool
            * PRECISION_FACTOR_E18
            / PRECISION_FACTOR_YEAR;
    }

    /**
     * @dev Internal helper function for
     * updating pools and calling {_cleanUp}.
     * Also includes re-entrancy guard for
     * curve pools security checks.
     */
    function _preparePool(
        address _poolToken
    )
        internal
    {
        _cleanUp(
            _poolToken
        );

        _updatePseudoTotalAmounts(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function for
     * updating all lending tokens of a
     * position.
     */
    function _preparationTokens(
        mapping(uint256 => address[]) storage _userTokenData,
        uint256 _nftId,
        address _poolToken
    )
        internal
        returns (address[] memory)
    {
        address[] memory tokens = _userTokenData[
            _nftId
        ];

        _prepareTokens(
            _poolToken,
            tokens
        );

        return tokens;
    }

    /**
     * @dev Internal helper function for
     * updating pseudo amounts of a pool
     * inside {tokens} array and sets new
     * borrow rates.
     */
    function _prepareTokens(
        address _poolToken,
        address[] memory _tokens
    )
        private
    {
        address currentAddress;

        uint256 i;
        uint256 l = _tokens.length;

        while (i < l) {

            currentAddress = _tokens[i];

            unchecked {
                ++i;
            }

            if (currentAddress == _poolToken) {
                continue;
            }

            _preparePool(
                currentAddress
            );

            _newBorrowRate(
                currentAddress
            );
        }
    }

    /**
     * @dev Internal helper function for iterating
     * over all tokens which may contain curvePools.
     */
    function _curveSecurityChecks(
        address[] memory _lendTokens,
        address[] memory _borrowTokens
    )
        internal
    {
        _whileLoopCurveSecurity(
            _lendTokens
        );

        _whileLoopCurveSecurity(
            _borrowTokens
        );
    }

    /**
     * @dev Internal helper function for executing while loops
     * iterating over all tokens which may contain curvePools.
     */
    function _whileLoopCurveSecurity(
        address[] memory _tokens
    )
        private
    {
        uint256 i;
        uint256 l = _tokens.length;

        while (i < l) {

            WISE_SECURITY.curveSecurityCheck(
                _tokens[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Internal helper function
     * updating pseudo amounts and
     * printing fee shares for the
     * feeManager proportional to the
     * fee percentage of the pool.
     */
    function _updatePseudoTotalAmounts(
        address _poolToken
    )
        private
    {
        uint256 currentTime = block.timestamp;

        uint256 bareIncrease = borrowPoolData[_poolToken].borrowRate
            * (currentTime - timestampsPoolData[_poolToken].timeStamp)
            * borrowPoolData[_poolToken].pseudoTotalBorrowAmount
            + bufferIncrease[_poolToken];

        if (bareIncrease < PRECISION_FACTOR_YEAR) {
            bufferIncrease[_poolToken] = bareIncrease;

            _setTimeStamp(
                _poolToken,
                currentTime
            );

            return;
        }

        delete bufferIncrease[_poolToken];

        uint256 amountInterest = bareIncrease
            / PRECISION_FACTOR_YEAR;

        uint256 feeAmount = amountInterest
            * globalPoolData[_poolToken].poolFee
            / PRECISION_FACTOR_E18;

        _increasePseudoTotalBorrowAmount(
            _poolToken,
            amountInterest
        );

        _increasePseudoTotalPool(
            _poolToken,
            amountInterest
        );

        if (feeAmount == 0) {
            _setTimeStamp(
                _poolToken,
                currentTime
            );
            return;
        }

        uint256 feeShares = feeAmount
            * lendingPoolData[_poolToken].totalDepositShares
            / (lendingPoolData[_poolToken].pseudoTotalPool - feeAmount);

        if (feeShares == 0) {
            _setTimeStamp(
                _poolToken,
                currentTime
            );
            return;
        }

        _increasePositionLendingDeposit(
            FEE_MANAGER_NFT,
            _poolToken,
            feeShares
        );

        _increaseTotalDepositShares(
            _poolToken,
            feeShares
        );

        _setTimeStamp(
            _poolToken,
            currentTime
        );
    }

    /**
     * @dev Internal increas function for
     * lending shares of a postion {_nftId}
     * and {_poolToken}.
     */
    function _increasePositionLendingDeposit(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        internal
    {
        userLendingData[_nftId][_poolToken].shares += _shares;
    }

    /**
     * @dev Internal decrease function for
     * lending shares of a postion {_nftId}
     * and {_poolToken}.
     */
    function _decreaseLendingShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        internal
    {
        userLendingData[_nftId][_poolToken].shares -= _shares;
    }

    /**
     * @dev Internal helper function adding a new
     * {_poolToken} token to {userTokenData} if needed.
     * Check is done by using hash maps.
     */
    function _addPositionTokenData(
        uint256 _nftId,
        address _poolToken,
        mapping(bytes32 => bool) storage hashMap,
        mapping(uint256 => address[]) storage userTokenData
    )
        internal
    {
        bytes32 hashData = _getHash(
            _nftId,
            _poolToken
        );

        if (hashMap[hashData] == true) {
            return;
        }

        hashMap[hashData] = true;

        if (userTokenData[_nftId].length > MAX_TOTAL_TOKEN_NUMBER) {
            revert TooManyTokens();
        }

        userTokenData[_nftId].push(
            _poolToken
        );
    }

    /**
     * @dev Internal helper calculating
     * a hash out of {_nftId} and {_poolToken}
     * using keccak256.
     */
    function _getHash(
        uint256 _nftId,
        address _poolToken
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _nftId,
                _poolToken
            )
        );
    }

    /**
     * @dev Internal helper function deleting an
     * entry in {_deleteLastPositionData}.
     */
    function _removePositionData(
        uint256 _nftId,
        address _poolToken,
        function(uint256) view returns (uint256) _getPositionTokenLength,
        function(uint256, uint256) view returns (address) _getPositionTokenByIndex,
        function(uint256, address) internal _deleteLastPositionData,
        bool isLending
    )
        private
    {
        uint256 length = _getPositionTokenLength(
            _nftId
        );

        if (length == 1) {
            _deleteLastPositionData(
                _nftId,
                _poolToken
            );

            return;
        }

        uint8 i;
        uint256 endPosition = length - 1;

        while (i < length) {

            if (i == endPosition) {
                _deleteLastPositionData(
                    _nftId,
                    _poolToken
                );

                break;
            }

            if (_getPositionTokenByIndex(_nftId, i) != _poolToken) {
                unchecked {
                    ++i;
                }
                continue;
            }

            address poolToken = _getPositionTokenByIndex(
                _nftId,
                endPosition
            );

            isLending == true
                ? positionLendTokenData[_nftId][i] = poolToken
                : positionBorrowTokenData[_nftId][i] = poolToken;

            _deleteLastPositionData(
                _nftId,
                _poolToken
            );

            break;
        }
    }

    /**
     * @dev Internal helper deleting last entry
     * of postion lending data.
     */
    function _deleteLastPositionLendingData(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        positionLendTokenData[_nftId].pop();
        hashMapPositionLending[
            _getHash(
                _nftId,
                _poolToken
            )
        ] = false;
    }

    /**
     * @dev Core function combining payback
     * logic with security checks.
     */
    function _corePayback(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _increaseTotalPool,
            _decreasePseudoTotalBorrowAmount,
            _decreaseTotalBorrowShares
        );

        _decreasePositionMappingValue(
            userBorrowShares,
            _nftId,
            _poolToken,
            _shares
        );

        if (userBorrowShares[_nftId][_poolToken] > 0) {
            return;
        }

        _removePositionData({
            _nftId: _nftId,
            _poolToken: _poolToken,
            _getPositionTokenLength: getPositionBorrowTokenLength,
            _getPositionTokenByIndex: getPositionBorrowTokenByIndex,
            _deleteLastPositionData: _deleteLastPositionBorrowData,
            isLending: false
        });
    }

    /**
     * @dev Internal helper deleting last entry
     * of postion borrow data.
     */
    function _deleteLastPositionBorrowData(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        positionBorrowTokenData[_nftId].pop();
        hashMapPositionBorrow[
            _getHash(
                _nftId,
                _poolToken
            )
        ] = false;
    }

    /**
     * @dev Internal helper function calculating
     * returning if a {_poolToken} of a {_nftId}
     * is uncollateralized.
     */
    function isUncollateralized(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (bool)
    {
        return userLendingData[_nftId][_poolToken].unCollateralized;
    }

    /**
     * @dev Internal helper function
     * checking if {_nftId} as no
     * {_poolToken} left.
     */
    function _checkLendingDataEmpty(
        uint256 _nftId,
        address _poolToken
    )
        private
        view
        returns (bool)
    {
        return userLendingData[_nftId][_poolToken].shares == 0
            && pureCollateralAmount[_nftId][_poolToken] == 0;
    }

    /**
     * @dev Internal helper function
     * calculating new borrow rates
     * for {_poolToken}. Uses smooth
     * functions of the form
     * f(x) = a * x /(p(p-x)) with
     * p > 1E18 the {pole} and
     * a the {mulFactor}.
     */
    function _calculateNewBorrowRate(
        address _poolToken
    )
        internal
    {
        uint256 pole = borrowRatesData[_poolToken].pole;
        uint256 utilization = globalPoolData[_poolToken].utilization;

        uint256 baseDivider = pole
            * (pole - utilization);

        borrowPoolData[_poolToken].borrowRate =
            borrowRatesData[_poolToken].multiplicativeFactor
                * PRECISION_FACTOR_E18
                * utilization
                / baseDivider;
    }

    /**
     * @dev Internal helper function
     * updating utilization of the pool
     * with {_poolToken}, calculating the
     * new borrow rate and running LASA if
     * the time intervall of three hours has
     * passed.
     */
    function _newBorrowRate(
        address _poolToken
    )
        internal
    {
        _updateUtilization(
            _poolToken
        );

        _calculateNewBorrowRate(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function
     * checking if time interval for
     * next LASA call has passed.
     */
    function _aboveThreshold(
        address _poolToken
    )
        internal
        view
        returns (bool)
    {
        return block.timestamp - timestampsPoolData[_poolToken].timeStampScaling >= THREE_HOURS;
    }

    /**
     * @dev function that tries to maximise totalDepositShares of the pool.
     * Reacting to negative and positive feedback by changing the resonance
     * factor of the pool. Method similar to one parameter monte-carlo methods
     */
    function _scalingAlgorithm(
        address _poolToken
    )
        internal
    {
        uint256 totalShares = lendingPoolData[_poolToken].totalDepositShares;

        if (algorithmData[_poolToken].maxValue <= totalShares) {

            _newMaxPoolShares(
                _poolToken,
                totalShares
            );

            _saveUp(
                _poolToken,
                totalShares
            );

            return;
        }

        _resonanceOutcome(_poolToken, totalShares) == true
            ? _resetResonanceFactor(_poolToken, totalShares)
            : _updateResonanceFactor(_poolToken, totalShares);

        _saveUp(
            _poolToken,
            totalShares
        );
    }

    /**
     * @dev Sets the new max value in shares
     * and saves the corresponding resonance factor.
     */
    function _newMaxPoolShares(
        address _poolToken,
        uint256 _shareValue
    )
        private
    {
        _setMaxValue(
            _poolToken,
            _shareValue
        );

        _setBestPole(
            _poolToken,
            borrowRatesData[_poolToken].pole
        );
    }

    /**
     * @dev Internal function setting {previousValue}
     * and {timestampScaling} for LASA of pool with
     * {_poolToken}.
     */
    function _saveUp(
        address _poolToken,
        uint256 _shareValue
    )
        private
    {
        algorithmData[_poolToken].previousValue = _shareValue;

        _setTimeStampScaling(
            _poolToken,
            block.timestamp
        );
    }

    /**
     * @dev Returns bool to determine if resonance
     * factor needs to be reset to last best value.
     */
    function _resonanceOutcome(
        address _poolToken,
        uint256 _shareValue
    )
        private
        view
        returns (bool)
    {
        return _shareValue < THRESHOLD_RESET_RESONANCE_FACTOR
            * algorithmData[_poolToken].maxValue
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Resets resonance factor to old best value when system
     * evolves into too bad state and sets current totalDepositShares
     * amount to new maxPoolShares to exclude eternal loops and that
     * unorganic peaks do not set maxPoolShares forever.
     */
    function _resetResonanceFactor(
        address _poolToken,
        uint256 _shareValue
    )
        private
    {
        _setPole(
            _poolToken,
            algorithmData[_poolToken].bestPole
        );

        _setMaxValue(
            _poolToken,
            _shareValue
        );

        _revertDirectionState(
            _poolToken
        );
    }

    /**
     * @dev Reverts the flag for stepping direction from LASA.
     */
    function _revertDirectionState(
        address _poolToken
    )
        private
    {
        _setIncreasePole(
            _poolToken,
            !algorithmData[_poolToken].increasePole
        );
    }

    /**
     * @dev Function combining all possible stepping scenarios.
     * Depending how share values has changed compared to last time.
     */
    function _updateResonanceFactor(
        address _poolToken,
        uint256 _shareValues
    )
        private
    {
        _shareValues < THRESHOLD_SWITCH_DIRECTION
            * algorithmData[_poolToken].previousValue
            / PRECISION_FACTOR_E18
            ? _reversedResonanceFactor(_poolToken)
            : _changingResonanceFactor(_poolToken);
    }

    /**
     * @dev Does a revert stepping and swaps stepping state in opposite flag.
     */
    function _reversedResonanceFactor(
        address _poolToken
    )
        private
    {
        algorithmData[_poolToken].increasePole
            ? _decreaseResonanceFactor(_poolToken)
            : _increaseResonanceFactor(_poolToken);

        _revertDirectionState(
            _poolToken
        );
    }

    /**
     * @dev Increasing or decresing resonance factor depending on flag value.
     */
    function _changingResonanceFactor(
        address _poolToken
    )
        private
    {
        algorithmData[_poolToken].increasePole
            ? _increaseResonanceFactor(_poolToken)
            : _decreaseResonanceFactor(_poolToken);
    }

    /**
     * @dev stepping function increasing the resonance factor
     * depending on the time past in the last time interval.
     * Checks if current resonance factor is bigger than max value.
     * If this is the case sets current value to maximal value
     */
    function _increaseResonanceFactor(
        address _poolToken
    )
        private
    {
        BorrowRatesEntry memory borrowData = borrowRatesData[
            _poolToken
        ];

        uint256 delta = borrowData.deltaPole
            * (block.timestamp - timestampsPoolData[_poolToken].timeStampScaling);

        uint256 sum = delta
            + borrowData.pole;

        uint256 setValue = sum > borrowData.maxPole
            ? borrowData.maxPole
            : sum;

        _setPole(
            _poolToken,
            setValue
        );
    }

    /**
     * @dev Stepping function decresing the resonance factor
     * depending on the time past in the last time interval.
     * Checks if current resonance factor undergoes the min value,
     * if this is the case sets current value to minimal value.
     */
    function _decreaseResonanceFactor(
        address _poolToken
    )
        private
    {
        uint256 minValue = borrowRatesData[_poolToken].minPole;

        uint256 delta = borrowRatesData[_poolToken].deltaPole
            * (block.timestamp - timestampsPoolData[_poolToken].timeStampScaling);

        uint256 sub = borrowRatesData[_poolToken].pole > delta
            ? borrowRatesData[_poolToken].pole - delta
            : 0;

        uint256 setValue = sub < minValue
            ? minValue
            : sub;

        _setPole(
            _poolToken,
            setValue
        );
    }

    /**
     * @dev Internal helper function for removing token address
     * from lending data array if all shares are removed. When
     * feeManager (nftId = 0) is calling this function is skipped
     * to save gas for continues fee accounting.
     */
    function _removeEmptyLendingData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        if (_nftId == 0) {
            return;
        }

        if (_checkLendingDataEmpty(_nftId, _poolToken) == false) {
            return;
        }

        _removePositionData({
            _nftId: _nftId,
            _poolToken: _poolToken,
            _getPositionTokenLength: getPositionLendingTokenLength,
            _getPositionTokenByIndex: getPositionLendingTokenByIndex,
            _deleteLastPositionData: _deleteLastPositionLendingData,
            isLending: true
        });
    }

    /**
     * @dev Internal helper function grouping several function
     * calls into one function for refactoring and code size
     * reduction.
     */
    function _updatePoolStorage(
        address _poolToken,
        uint256 _amount,
        uint256 _shares,
        function(address, uint256) functionAmountA,
        function(address, uint256) functionAmountB,
        function(address, uint256) functionSharesA
    )
        internal
    {
        functionAmountA(
            _poolToken,
            _amount
        );

        functionAmountB(
            _poolToken,
            _amount
        );

        functionSharesA(
            _poolToken,
            _shares
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./CallOptionalReturn.sol";

contract TransferHelper is CallOptionalReturn {

    /**
     * @dev
     * Allows to execute safe transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute safe transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./WiseLendingDeclaration.sol";

abstract contract WiseLowLevelHelper is WiseLendingDeclaration {

    modifier onlyFeeManager() {
        _onlyFeeManager();
        _;
    }

    function _onlyFeeManager()
        private
        view
    {
        if (msg.sender == address(FEE_MANAGER)) {
            return;
        }

        revert InvalidCaller();
    }

    function _validateParameter(
        uint256 _parameterValue,
        uint256 _parameterLimit
    )
        internal
        pure
    {
        if (_parameterValue > _parameterLimit) {
            revert InvalidAction();
        }
    }

    // --- Basic Public Views Functions ----

    function getTotalPool(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return globalPoolData[_poolToken].totalPool;
    }

    function getPseudoTotalPool(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return lendingPoolData[_poolToken].pseudoTotalPool;
    }

    function getTotalBareToken(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return globalPoolData[_poolToken].totalBareToken;
    }

    function getPseudoTotalBorrowAmount(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return borrowPoolData[_poolToken].pseudoTotalBorrowAmount;
    }

    function getTotalDepositShares(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return lendingPoolData[_poolToken].totalDepositShares;
    }

    function getTotalBorrowShares(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return borrowPoolData[_poolToken].totalBorrowShares;
    }

    function getPositionLendingShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return userLendingData[_nftId][_poolToken].shares;
    }

    function getPositionBorrowShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return userBorrowShares[_nftId][_poolToken];
    }

    function getPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return pureCollateralAmount[_nftId][_poolToken];
    }

    // --- Basic Internal Get Functions ----

    function getTimeStamp(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return timestampsPoolData[_poolToken].timeStamp;
    }

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        public
        view
        returns (address)
    {
        return positionLendTokenData[_nftId][_index];
    }

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        public
        view
        returns (uint256)
    {
        return positionLendTokenData[_nftId].length;
    }

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        public
        view
        returns (address)
    {
        return positionBorrowTokenData[_nftId][_index];
    }

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        public
        view
        returns (uint256)
    {
        return positionBorrowTokenData[_nftId].length;
    }

    // --- Basic Internal Set Functions ----

    function _setMaxValue(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        algorithmData[_poolToken].maxValue = _value;
    }

    function _setBestPole(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        algorithmData[_poolToken].bestPole = _value;
    }

    function _setIncreasePole(
        address _poolToken,
        bool _state
    )
        internal
    {
        algorithmData[_poolToken].increasePole = _state;
    }

    function _setPole(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        borrowRatesData[_poolToken].pole = _value;
    }

    function _increaseTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalPool += _amount;
    }

    function _decreaseTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalPool -= _amount;
    }

    function _increaseTotalDepositShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].totalDepositShares += _amount;
    }

    function _decreaseTotalDepositShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].totalDepositShares -= _amount;
    }

    function _increasePseudoTotalBorrowAmount(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].pseudoTotalBorrowAmount += _amount;
    }

    function _decreasePseudoTotalBorrowAmount(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].pseudoTotalBorrowAmount -= _amount;
    }

    function _increaseTotalBorrowShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].totalBorrowShares += _amount;
    }

    function _decreaseTotalBorrowShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].totalBorrowShares -= _amount;
    }

    function _increasePseudoTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].pseudoTotalPool += _amount;
    }

    function _decreasePseudoTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].pseudoTotalPool -= _amount;
    }

    function _setTimeStamp(
        address _poolToken,
        uint256 _time
    )
        internal
    {
        timestampsPoolData[_poolToken].timeStamp = _time;
    }

    function _setTimeStampScaling(
        address _poolToken,
        uint256 _time
    )
        internal
    {
        timestampsPoolData[_poolToken].timeStampScaling = _time;
    }

    function _increaseTotalBareToken(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalBareToken += _amount;
    }

    function _decreaseTotalBareToken(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalBareToken -= _amount;
    }

    function _checkReentrancy()
        internal
        view
    {
        if (sendingProgress == true) {
            revert InvalidAction();
        }

        if (_sendingProgressAaveHub() == true) {
            revert InvalidAction();
        }
    }

    function _sendingProgressAaveHub()
        private
        view
        returns (bool)
    {
        return IAaveHubLite(AAVE_HUB_ADDRESS).sendingProgressAaveHub();
    }

    function _decreasePositionMappingValue(
        mapping(uint256 => mapping(address => uint256)) storage userMapping,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        userMapping[_nftId][_poolToken] -= _amount;
    }

    function _increaseMappingValue(
        mapping(uint256 => mapping(address => uint256)) storage userMapping,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        userMapping[_nftId][_poolToken] += _amount;
    }

    function _byPassCase(
        address _sender
    )
        internal
        view
        returns (bool)
    {
        if (verifiedIsolationPool[_sender] == true) {
            return true;
        }

        return false;
    }

    function _increaseTotalAndPseudoTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        _increasePseudoTotalPool(
            _poolToken,
            _amount
        );

        _increaseTotalPool(
            _poolToken,
            _amount
        );
    }

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external
        onlyFeeManager
    {
        globalPoolData[_poolToken].poolFee = _newFee;
    }

    function _checkOwnerPosition(
        uint256 _nftId,
        address _msgSender
    )
        internal
        view
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            _msgSender
        );
    }

    function _validateNonZero(
        uint256 _value
    )
        internal
        pure
    {
        if (_value == 0) {
            revert ValueIsZero();
        }
    }

    function _validateZero(
        uint256 _value
    )
        internal
        pure
    {
        if (_value > 0) {
            revert ValueNotZero();
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "../InterfaceHub/IERC20.sol";

contract CallOptionalReturn {

    /**
     * @dev Helper function to do low-level call
     */
    function _callOptionalReturn(
        address token,
        bytes memory data
    )
        internal
        returns (bool call)
    {
        (
            bool success,
            bytes memory returndata
        ) = token.call(
            data
        );

        bool results = returndata.length == 0 || abi.decode(
            returndata,
            (bool)
        );

        if (success == false) {
            revert();
        }

        call = success
            && results
            && token.code.length > 0;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./OwnableMaster.sol";

import "./InterfaceHub/IAaveHubLite.sol";
import "./InterfaceHub/IPositionNFTs.sol";
import "./InterfaceHub/IWiseSecurity.sol";
import "./InterfaceHub/IWiseOracleHub.sol";
import "./InterfaceHub/IFeeManagerLight.sol";

import "./TransferHub/WrapperHelper.sol";
import "./TransferHub/SendValueHelper.sol";

error DeadOracle();
error NotPowerFarm();
error InvalidAction();
error InvalidCaller();
error PositionLocked();
error LiquidatorIsInPowerFarm();
error PositionHasCollateral();
error PositionHasBorrow();
error InvalidAddress();
error InvalidLiquidator();
error ValueIsZero();
error ValueNotZero();
error TooManyTokens();

contract WiseLendingDeclaration is
    OwnableMaster,
    WrapperHelper,
    SendValueHelper
{
    event FundsDeposited(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsSolelyDeposited(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawnOnBehalf(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsSolelyWithdrawn(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed borrower,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowedOnBehalf(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed sender,
        address indexed token,
        uint256 indexed nftId,
        uint256 totalPayment,
        uint256 totalPaymentShares,
        uint256 timestamp
    );

    constructor(
        address _master,
        address _wiseOracleHub,
        address _nftContract
    )
        OwnableMaster(
            _master
        )
        WrapperHelper(
            IWiseOracleHub(
                _wiseOracleHub
            ).WETH_ADDRESS()
        )
    {
        if (_wiseOracleHub == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_nftContract == ZERO_ADDRESS) {
            revert NoValue();
        }

        WISE_ORACLE = IWiseOracleHub(
            _wiseOracleHub
        );

        WETH_ADDRESS = WISE_ORACLE.WETH_ADDRESS();

        POSITION_NFT = IPositionNFTs(
            _nftContract
        );

        FEE_MANAGER_NFT = POSITION_NFT.FEE_MANAGER_NFT();
    }

    function setSecurity(
        address _wiseSecurity
    )
        external
        onlyMaster
    {
        if (address(WISE_SECURITY) > ZERO_ADDRESS) {
            revert InvalidAction();
        }

        WISE_SECURITY = IWiseSecurity(
            _wiseSecurity
        );

        FEE_MANAGER = IFeeManagerLight(
            WISE_SECURITY.FEE_MANAGER()
        );

        AAVE_HUB_ADDRESS = WISE_SECURITY.AAVE_HUB();
    }

    // AaveHub address
    address internal AAVE_HUB_ADDRESS;

    // Wrapped ETH address
    address public immutable WETH_ADDRESS;

    // Nft id for feeManager
    uint256 immutable FEE_MANAGER_NFT;

    // WiseSecurity interface
    IWiseSecurity public WISE_SECURITY;

    // FeeManager interface
    IFeeManagerLight internal FEE_MANAGER;

    // NFT contract interface for positions
    IPositionNFTs public immutable POSITION_NFT;

    // OraceHub interface
    IWiseOracleHub public immutable WISE_ORACLE;

    // check if it is a powerfarm
    bool internal powerFarmCheck;

    uint256 internal constant GHOST_AMOUNT = 1E3;

    // Structs ------------------------------------------

    struct LendingEntry {
        bool unCollateralized;
        uint256 shares;
    }

    struct BorrowRatesEntry {
        uint256 pole;
        uint256 deltaPole;
        uint256 minPole;
        uint256 maxPole;
        uint256 multiplicativeFactor;
    }

    struct AlgorithmEntry {
        bool increasePole;
        uint256 bestPole;
        uint256 maxValue;
        uint256 previousValue;
    }

    struct GlobalPoolEntry {
        uint256 totalPool;
        uint256 utilization;
        uint256 totalBareToken;
        uint256 poolFee;
    }

    struct LendingPoolEntry {
        uint256 pseudoTotalPool;
        uint256 totalDepositShares;
        uint256 collateralFactor;
    }

    struct BorrowPoolEntry {
        bool allowBorrow;
        uint256 pseudoTotalBorrowAmount;
        uint256 totalBorrowShares;
        uint256 borrowRate;
    }

    struct TimestampsPoolEntry {
        uint256 timeStamp;
        uint256 timeStampScaling;
        uint256 initialTimeStamp;
    }

    struct CoreLiquidationStruct {
        uint256 nftId;
        uint256 nftIdLiquidator;
        address caller;
        address tokenToPayback;
        address tokenToRecieve;
        uint256 paybackAmount;
        uint256 shareAmountToPay;
        uint256 maxFeeETH;
        uint256 baseRewardLiquidation;
        address[] lendTokens;
        address[] borrowTokens;
    }

    modifier onlyAaveHub() {
        _onlyAaveHub();
        _;
    }

    function _onlyAaveHub()
        private
        view
    {
        if (msg.sender != AAVE_HUB_ADDRESS) {
            revert InvalidCaller();
        }
    }

    // Position mappings ------------------------------------------
    mapping(address => uint256) internal bufferIncrease;
    mapping(address => uint256) public maxDepositValueToken;

    mapping(uint256 => address[]) public positionLendTokenData;
    mapping(uint256 => address[]) public positionBorrowTokenData;

    mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
    mapping(uint256 => mapping(address => uint256)) public pureCollateralAmount;
    mapping(uint256 => mapping(address => LendingEntry)) public userLendingData;

    // Struct mappings -------------------------------------
    mapping(address => BorrowRatesEntry) public borrowRatesData;
    mapping(address => AlgorithmEntry) public algorithmData;
    mapping(address => GlobalPoolEntry) public globalPoolData;
    mapping(address => LendingPoolEntry) public lendingPoolData;
    mapping(address => BorrowPoolEntry) public borrowPoolData;
    mapping(address => TimestampsPoolEntry) public timestampsPoolData;

    // Bool mappings -------------------------------------
    mapping(uint256 => bool) public positionLocked;
    mapping(address => bool) internal parametersLocked;
    mapping(address => bool) public verifiedIsolationPool;

    // Hash mappings -------------------------------------
    mapping(bytes32 => bool) internal hashMapPositionBorrow;
    mapping(bytes32 => bool) internal hashMapPositionLending;

    // PRECISION FACTORS ------------------------------------
    uint256 internal constant PRECISION_FACTOR_E16 = 1E16;
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;
    uint256 internal constant PRECISION_FACTOR_E36 = PRECISION_FACTOR_E18 * PRECISION_FACTOR_E18;

    // TIME CONSTANTS --------------------------------------
    uint256 internal constant ONE_YEAR = 52 weeks;
    uint256 internal constant THREE_HOURS = 3 hours;
    uint256 internal constant PRECISION_FACTOR_YEAR = PRECISION_FACTOR_E18 * ONE_YEAR;

    // Two months in seconds:
    // Norming change in pole value that it steps from min to max value
    // within two month (if nothing changes)
    uint256 internal constant NORMALISATION_FACTOR = 4838400;

    // Default boundary values for pool creation.
    uint256 internal constant LOWER_BOUND_MAX_RATE = 100 * PRECISION_FACTOR_E16;
    uint256 internal constant UPPER_BOUND_MAX_RATE = 300 * PRECISION_FACTOR_E16;

    // LASA CONSTANTS -------------------------
    uint256 internal constant THRESHOLD_SWITCH_DIRECTION = 90 * PRECISION_FACTOR_E16;
    uint256 internal constant THRESHOLD_RESET_RESONANCE_FACTOR = 75 * PRECISION_FACTOR_E16;

    // MORE THRESHHOLD VALUES

    uint256 internal constant MAX_COLLATERAL_FACTOR = 85 * PRECISION_FACTOR_E16;
    uint256 internal constant MAX_TOTAL_TOKEN_NUMBER = 8;

    // APR RESTRICTIONS
    uint256 internal constant RESTRICTION_FACTOR = 10
        * PRECISION_FACTOR_E36
        / PRECISION_FACTOR_YEAR;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event  Deposit(
        address indexed dst,
        uint wad
    );

    event  Withdrawal(
        address indexed src,
        uint wad
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

error NoValue();
error NotMaster();
error NotProposed();

contract OwnableMaster {

    address public master;
    address public proposedMaster;

    address internal constant ZERO_ADDRESS = address(0x0);

    modifier onlyProposed() {
        _onlyProposed();
        _;
    }

    function _onlyMaster()
        private
        view
    {
        if (msg.sender == master) {
            return;
        }

        revert NotMaster();
    }

    modifier onlyMaster() {
        _onlyMaster();
        _;
    }

    function _onlyProposed()
        private
        view
    {
        if (msg.sender == proposedMaster) {
            return;
        }

        revert NotProposed();
    }

    constructor(
        address _master
    ) {
        if (_master == ZERO_ADDRESS) {
            revert NoValue();
        }
        master = _master;
    }

    /**
     * @dev Allows to propose next master.
     * Must be claimed by proposer.
     */
    function proposeOwner(
        address _proposedOwner
    )
        external
        onlyMaster
    {
        if (_proposedOwner == ZERO_ADDRESS) {
            revert NoValue();
        }

        proposedMaster = _proposedOwner;
    }

    /**
     * @dev Allows to claim master role.
     * Must be called by proposer.
     */
    function claimOwnership()
        external
        onlyProposed
    {
        master = proposedMaster;
    }

    /**
     * @dev Removes master role.
     * No ability to be in control.
     */
    function renounceOwnership()
        external
        onlyMaster
    {
        master = ZERO_ADDRESS;
        proposedMaster = ZERO_ADDRESS;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IAaveHubLite {

    function sendingProgressAaveHub()
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function getOwner(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function totalSupply()
        external
        view
        returns (uint256);

    function reserved(
        address _owner
    )
        external
        view
        returns (uint256);

    function reservePosition()
        external;

    function mintPosition()
        external
        returns (uint256);

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256);

    function walletOfOwner(
        address _owner
    )
        external
        view
        returns (uint256[] memory);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);

    function reservePositionForUser(
        address _user
    )
        external
        returns (uint256);

    function getApproved(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function approve(
        address _to,
        uint256 _nftId
    )
        external;

    function isOwner(
        uint256 _nftId,
        address _caller
    )
        external
        view
        returns (bool);

    function FEE_MANAGER_NFT()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

struct CurveSwapStructToken {
    uint256 curvePoolTokenIndexFrom;
    uint256 curvePoolTokenIndexTo;
    uint256 curveMetaPoolTokenIndexFrom;
    uint256 curveMetaPoolTokenIndexTo;
}

struct CurveSwapStructData {
    address curvePool;
    address curveMetaPool;
    bytes swapBytesPool;
    bytes swapBytesMeta;
}

interface IWiseSecurity {

    function checkMinDepositValue(
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function overallETHBorrow(
        uint256 _nftId
    )
        external
        view
        returns (uint256 buffer);

    function overallETHCollateralsBoth(
        uint256 _nftId
    )
        external
        view
        returns (uint256 weighted, uint256 unweightedamount);

    function checkHealthState(
        uint256 _nftId,
        bool _isPowerFarm
    )
        external
        view;

    function checkPoolCondition(
        address _token
    )
        external
        view;

    function overallETHBorrowHeartbeat(
        uint256 _nftId
    )
        external
        view
        returns (uint256 buffer);

    function checkBadDebtLiquidation(
        uint256 _nftId
    )
        external;

    function checksLiquidation(
        uint256 _nftIdLiquidate,
        address _tokenToPayback,
        uint256 _shareAmountToPay
    )
        external
        view;

    function getPositionLendingAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getBorrowRate(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getPositionBorrowAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function overallUSDCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function overallETHCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function FEE_MANAGER()
        external
        view
        returns (address);

    function AAVE_HUB()
        external
        view
        returns (address);

    function curveSecurityCheck(
        address _poolAddress
    )
        external;

    function prepareCurvePools(
        address _poolToken,
        CurveSwapStructData calldata _curveSwapStructData,
        CurveSwapStructToken calldata _curveSwapStructToken
    )
        external;

    function overallETHBorrowBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken
    )
        external
        view
        returns (bool);

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken
    )
        external
        view
        returns (bool);

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken
    )
        external
        view
        returns (bool);

    function checkOwnerPosition(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checksCollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolAddress
    )
        external
        view;

    function calculateWishPercentage(
        uint256 _nftId,
        address _receiveToken,
        uint256 _paybackETH,
        uint256 _maxFeeETH,
        uint256 _baseRewardLiquidation
    )
        external
        view
        returns (uint256);

    function checkUncollateralizedDeposit(
        uint256 _nftIdCaller,
        address _poolToken
    )
        external
        view;

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function maxFeeETH()
        external
        view
        returns (uint256);

    function maxFeeFarmETH()
        external
        view
        returns (uint256);

    function baseRewardLiquidation()
        external
        view
        returns (uint256);

    function baseRewardLiquidationFarm()
        external
        view
        returns (uint256);

    function checksRegister(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function getLendingRate(
        address _poolToken
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IWiseOracleHub {

    function getTokensPriceFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensPriceInUSD(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256);

    function latestResolver(
        address _tokenAddress
    )
        external
        view
        returns (uint256);

    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensFromETH(
        address _tokenAddress,
        uint256 _ethValue
    )
        external
        view
        returns (uint256);

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function getTokensInETH(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256);

    function chainLinkIsDead(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    function decimalsUSD()
        external
        pure
        returns (uint8);

    function addOracle(
        address _tokenAddress,
        address _priceFeedAddress,
        address[] calldata _underlyingFeedTokens
    )
        external;

    function recalibrate(
        address _tokenAddress
    )
        external;

    function WETH_ADDRESS()
        external
        view
        returns (address);

    function priceFeed(
        address _tokenAddress
    )
        external
        view
        returns (address);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IFeeManagerLight {
    function addPoolTokenAddress(
        address _poolToken
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "../InterfaceHub/IWETH.sol";

contract WrapperHelper {

    IWETH internal immutable WETH;

    constructor(
        address _wethAddress
    )
    {
        WETH = IWETH(
            _wethAddress
        );
    }

    /**
     * @dev Wrapper for wrapping
     * ETH call.
     */
    function _wrapETH(
        uint256 _value
    )
        internal
    {
        WETH.deposit{
            value: _value
        }();
    }

    /**
     * @dev Wrapper for unwrapping
     * ETH call.
     */
    function _unwrapETH(
        uint256 _value
    )
        internal
    {
        WETH.withdraw(
            _value
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

error AmountTooSmall();
error SendValueFailed();

contract SendValueHelper {

    bool public sendingProgress;

    function _sendValue(
        address _recipient,
        uint256 _amount
    )
        internal
    {
        if (address(this).balance < _amount) {
            revert AmountTooSmall();
        }

        sendingProgress = true;

        (
            bool success
            ,
        ) = payable(_recipient).call{
            value: _amount
        }("");

        sendingProgress = false;

        if (success == false) {
            revert SendValueFailed();
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./IERC20.sol";

interface IWETH is IERC20 {

    function deposit()
        external
        payable;

    function withdraw(
        uint256
    )
        external;
}