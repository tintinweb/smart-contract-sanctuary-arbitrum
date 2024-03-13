// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "../libraries/GammaSwapLibrary.sol";
import "../interfaces/IPoolViewer.sol";
import "../interfaces/IGammaPool.sol";
import "../interfaces/observer/ICollateralManager.sol";
import "../interfaces/strategies/base/ILongStrategy.sol";
import "../interfaces/strategies/base/IShortStrategy.sol";
import "../interfaces/strategies/lending/IBorrowStrategy.sol";
import "../rates/AbstractRateModel.sol";
import "../libraries/GSMath.sol";

/// @title Implementation of Viewer Contract for GammaPool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used make complex view function calls from GammaPool's storage data (e.g. updated loan and pool debt)
contract PoolViewer is IPoolViewer {

    /// @inheritdoc IPoolViewer
    function getLoans(address pool, uint256 start, uint256 end, bool active) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        _loans = IGammaPool(pool).getLoans(start, end, active);
        return _getUpdatedLoans(pool, _loans);
    }

    /// @inheritdoc IPoolViewer
    function getLoansById(address pool, uint256[] calldata tokenIds, bool active) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        _loans = IGammaPool(pool).getLoansById(tokenIds, active);
        return _getUpdatedLoans(pool, _loans);
    }

    /// @dev Get interest rate changes per source, utilization rate, and borrowing and supply APR charged to users
    /// @param pool - address of GammaPool loans in `_loans` array belongs to
    /// @param _loans - list of LoanData structs containing loan information to update
    /// @return updatedLoans - updated accFeeIndex of pool loan belongs to
    function _getUpdatedLoans(address pool, IGammaPool.LoanData[] memory _loans) internal virtual view returns(IGammaPool.LoanData[] memory) {
        address[] memory _tokens = IGammaPool(pool).tokens();
        (string[] memory _symbols, string[] memory _names, uint8[] memory _decimals) = getTokensMetaData(_tokens);
        IGammaPool.RateData memory data = _getLastFeeIndex(pool);
        uint256 _size = _loans.length;
        IGammaPool.LoanData memory _loan;
        for(uint256 i = 0; i < _size;) {
            _loan = _loans[i];
            if(_loan.id == 0) {
                break;
            }
            _loan.tokens = _tokens;
            _loan.symbols = _symbols;
            _loan.names = _names;
            _loan.decimals = _decimals;
            _loan.liquidity = _updateLiquidity(_loan.liquidity, _loan.rateIndex, data.accFeeIndex);
            address refAddr = _loan.refType == 3 ? _loan.refAddr : address(0);
            _loan.collateral = _collateral(pool, _loan.tokenId, _loan.tokensHeld, refAddr);
            _loan.shortStrategy = data.shortStrategy;
            _loan.paramsStore = data.paramsStore;
            _loan.ltvThreshold = data.ltvThreshold;
            _loan.liquidationFee = data.liquidationFee;
            _loan.canLiquidate = _canLiquidate(_loan.liquidity, _loan.collateral, _loan.ltvThreshold);
            unchecked {
                ++i;
            }
        }
        return _loans;
    }

    /// @dev check if collateral is below loan-to-value threshold
    function _canLiquidate(uint256 liquidity, uint256 collateral, uint256 ltvThreshold) internal virtual view returns(bool) {
        return collateral * (10000 - ltvThreshold * 10) / 1e4 < liquidity;
    }

    /// @inheritdoc IPoolViewer
    function loan(address pool, uint256 tokenId) external virtual override view returns(IGammaPool.LoanData memory _loanData) {
        _loanData = IGammaPool(pool).getLoanData(tokenId);
        if(_loanData.id == 0) {
            return _loanData;
        }
        _loanData.accFeeIndex = _getLoanLastFeeIndex(_loanData);
        _loanData.liquidity = _updateLiquidity(_loanData.liquidity, _loanData.rateIndex, _loanData.accFeeIndex);
        address refAddr = _loanData.refType == 3 ? _loanData.refAddr : address(0);
        _loanData.collateral = _collateral(pool, tokenId, _loanData.tokensHeld, refAddr);
        _loanData.canLiquidate = _canLiquidate(_loanData.liquidity, _loanData.collateral, _loanData.ltvThreshold);
        (_loanData.symbols, _loanData.names, _loanData.decimals) = getTokensMetaData(_loanData.tokens);
        return _loanData;
    }

    /// @inheritdoc IPoolViewer
    function canLiquidate(address pool, uint256 tokenId) external virtual override view returns(bool) {
        IGammaPool.LoanData memory _loanData = IGammaPool(pool).getLoanData(tokenId);
        if(_loanData.liquidity == 0) {
            return false;
        }
        uint256 liquidity = _updateLiquidity(_loanData.liquidity, _loanData.rateIndex, _getLoanLastFeeIndex(_loanData));
        address refAddr = _loanData.refType == 3 ? _loanData.refAddr : address(0);
        uint256 collateral = _collateral(pool, tokenId, _loanData.tokensHeld, refAddr);
        return _canLiquidate(liquidity, collateral, _loanData.ltvThreshold);
    }

    /// @dev Get interest rate changes per source, utilization rate, and borrowing and supply APR charged to users
    /// @param _loanData - struct containing necessary loan information to calculate accFeeIndex
    /// @return accFeeIndex - updated accFeeIndex of pool loan belongs to
    function _getLoanLastFeeIndex(IGammaPool.LoanData memory _loanData) internal virtual view returns(uint256 accFeeIndex) {
        uint256 lastCFMMInvariant;
        uint256 lastCFMMTotalSupply;
        if(_loanData.poolId == address(0)) {
            return 1e18;
        }
        (, lastCFMMInvariant, lastCFMMTotalSupply) = IGammaPool(_loanData.poolId).getLatestCFMMBalances();
        if(lastCFMMTotalSupply == 0) {
            return 1e18;
        }

        // using lastFeeIndex to hold spread
        (uint256 borrowRate,,uint256 maxCFMMFeeLeverage,uint256 lastFeeIndex) = AbstractRateModel(_loanData.shortStrategy).calcBorrowRate(_loanData.LP_INVARIANT,
            _loanData.BORROWED_INVARIANT, _loanData.paramsStore, _loanData.poolId);

        (lastFeeIndex,) = IShortStrategy(_loanData.shortStrategy).getLastFees(borrowRate, _loanData.BORROWED_INVARIANT,
            lastCFMMInvariant, lastCFMMTotalSupply, _loanData.lastCFMMInvariant, _loanData.lastCFMMTotalSupply,
            _loanData.LAST_BLOCK_NUMBER, _loanData.lastCFMMFeeIndex, maxCFMMFeeLeverage, lastFeeIndex);

        accFeeIndex = _loanData.accFeeIndex * lastFeeIndex / 1e18;
    }

    /// @dev Get collateral in terms of liquidity invariant units for loan identified by `tokenId`
    /// @param pool - address of GammaPool loan belongs to
    /// @param tokenId - unique id of loan, used to look up loan in GammaPool
    /// @param tokensHeld - tokens held in GammaPool as collateral for loan
    /// @param refAddr - address of contract holding additional collateral for loan
    /// @return collateral - collateral of loan in terms of liquidity invariant units;
    function _collateral(address pool, uint256 tokenId, uint128[] memory tokensHeld, address refAddr) internal virtual view returns(uint256 collateral) {
        collateral = IGammaPool(pool).calcInvariant(tokensHeld);
        if(refAddr != address(0)) {
            collateral += ICollateralManager(refAddr).getCollateral(pool, tokenId);
        }
    }

    /// @inheritdoc IPoolViewer
    function calcDynamicOriginationFee(address pool, uint256 liquidity) external virtual override view returns(uint256 origFee) {
        IGammaPool.RateData memory data = _getLastFeeIndex(pool);

        if(liquidity >= data.LP_INVARIANT) {
            return 10000;
        }

        uint256 utilRate = _calcUtilizationRate(data.LP_INVARIANT - liquidity, data.BORROWED_INVARIANT + liquidity) / 1e16;// convert utilizationRate to integer
        uint256 emaUtilRate = data.emaUtilRate / 1e4; // convert ema to integer

        origFee = IBorrowStrategy(IGammaPool(pool).borrowStrategy()).calcDynamicOriginationFee(data.origFee, utilRate, emaUtilRate, data.minUtilRate1, data.minUtilRate2, data.feeDivisor);
    }

    /// @dev Calculate utilization rate from borrowed invariant and invariant from LP tokens in GammaPool
    /// @param lpInvariant - liquidity invariant from LP tokens deposited in GammaPool
    /// @param borrowedInvariant - liquidity invariant units borrowed from GammaPool
    /// @return utilizationRate - utilization rate based on `borrowedInvariant` and `lpInvariant`
    function _calcUtilizationRate(uint256 lpInvariant, uint256 borrowedInvariant) internal view returns(uint256) {
        uint256 totalInvariant = borrowedInvariant + lpInvariant;
        if(totalInvariant == 0) {
            return 0;
        }
        return borrowedInvariant * 1e18 / totalInvariant;
    }

    /// @dev Get interest rate changes per source, utilization rate, and borrowing and supply APR charged to users
    /// @param pool - struct containing necessary loan information to calculate accFeeIndex
    /// @param data - struct containing updated fee index information from pool
    function _getLastFeeIndex(address pool) internal virtual view returns(IGammaPool.RateData memory data) {
        IGammaPool.PoolData memory params = IGammaPool(pool).getPoolData();

        uint256 lastCFMMInvariant;
        uint256 lastCFMMTotalSupply;
        (, lastCFMMInvariant, lastCFMMTotalSupply) = IGammaPool(pool).getLatestCFMMBalances();
        if(lastCFMMTotalSupply > 0) {
            uint256 maxCFMMFeeLeverage;
            uint256 spread;
            (data.borrowRate,data.utilizationRate,maxCFMMFeeLeverage,spread) = AbstractRateModel(params.shortStrategy).calcBorrowRate(params.LP_INVARIANT,
                params.BORROWED_INVARIANT, params.paramsStore, pool);

            (data.lastFeeIndex,data.lastCFMMFeeIndex) = IShortStrategy(params.shortStrategy)
                .getLastFees(data.borrowRate, params.BORROWED_INVARIANT, lastCFMMInvariant, lastCFMMTotalSupply,
                params.lastCFMMInvariant, params.lastCFMMTotalSupply, params.LAST_BLOCK_NUMBER, params.lastCFMMFeeIndex,
                maxCFMMFeeLeverage, spread);

            data.supplyRate = data.borrowRate * data.utilizationRate / 1e18;

            (,, data.BORROWED_INVARIANT) = IShortStrategy(params.shortStrategy).getLatestBalances(data.lastFeeIndex,
                params.BORROWED_INVARIANT, params.LP_TOKEN_BALANCE, lastCFMMInvariant, lastCFMMTotalSupply);

            data.LP_INVARIANT = uint128(params.LP_TOKEN_BALANCE * lastCFMMInvariant / lastCFMMTotalSupply);

            data.utilizationRate = _calcUtilizationRate(data.LP_INVARIANT, data.BORROWED_INVARIANT);
            data.emaUtilRate = uint40(IShortStrategy(params.shortStrategy).calcUtilRateEma(data.utilizationRate, params.emaUtilRate,
                GSMath.max(block.number - params.LAST_BLOCK_NUMBER, params.emaMultiplier)));
        } else {
            data.lastFeeIndex = 1e18;
        }

        data.origFee = params.origFee;
        data.feeDivisor = params.feeDivisor;
        data.minUtilRate1 = params.minUtilRate1;
        data.minUtilRate2 = params.minUtilRate2;
        data.ltvThreshold = params.ltvThreshold;
        data.liquidationFee = params.liquidationFee;
        data.shortStrategy = params.shortStrategy;
        data.paramsStore = params.paramsStore;

        data.accFeeIndex = params.accFeeIndex * data.lastFeeIndex / 1e18;
        data.lastBlockNumber = params.LAST_BLOCK_NUMBER;
        data.currBlockNumber = block.number;
    }

    /// @inheritdoc IPoolViewer
    function getLatestRates(address pool) external virtual override view returns(IGammaPool.RateData memory data) {
        data = _getLastFeeIndex(pool);
        data.lastPrice = IGammaPool(pool).getLastCFMMPrice();
    }

    /// @inheritdoc IPoolViewer
    function getLatestPoolData(address pool) external virtual override view returns(IGammaPool.PoolData memory data) {
        data = getPoolData(pool);
        uint256 lastCFMMInvariant;
        uint256 lastCFMMTotalSupply;
        (data.CFMM_RESERVES, lastCFMMInvariant, lastCFMMTotalSupply) = IGammaPool(pool).getLatestCFMMBalances();
        if(lastCFMMTotalSupply == 0) {
            return data;
        }

        uint256 lastCFMMFeeIndex; // holding maxCFMMFeeLeverage temporarily
        uint256 borrowedInvariant; // holding spread temporarily
        (data.borrowRate, data.utilizationRate, lastCFMMFeeIndex, borrowedInvariant) = AbstractRateModel(data.shortStrategy).calcBorrowRate(data.LP_INVARIANT,
            data.BORROWED_INVARIANT, data.paramsStore, pool);

        (data.lastFeeIndex,lastCFMMFeeIndex) = IShortStrategy(data.shortStrategy)
        .getLastFees(data.borrowRate, data.BORROWED_INVARIANT, lastCFMMInvariant, lastCFMMTotalSupply,
            data.lastCFMMInvariant, data.lastCFMMTotalSupply, data.LAST_BLOCK_NUMBER, data.lastCFMMFeeIndex,
            lastCFMMFeeIndex, borrowedInvariant);

        data.supplyRate = data.borrowRate * data.utilizationRate / 1e18;

        data.lastCFMMFeeIndex = uint64(lastCFMMFeeIndex);
        (,data.LP_TOKEN_BORROWED_PLUS_INTEREST, borrowedInvariant) = IShortStrategy(data.shortStrategy)
        .getLatestBalances(data.lastFeeIndex, data.BORROWED_INVARIANT, data.LP_TOKEN_BALANCE,
            lastCFMMInvariant, lastCFMMTotalSupply);

        data.BORROWED_INVARIANT = uint128(borrowedInvariant);
        data.LP_INVARIANT = uint128(data.LP_TOKEN_BALANCE * lastCFMMInvariant / lastCFMMTotalSupply);
        data.accFeeIndex = uint80(data.accFeeIndex * data.lastFeeIndex / 1e18);

        data.utilizationRate = _calcUtilizationRate(data.LP_INVARIANT, data.BORROWED_INVARIANT);
        data.emaUtilRate = uint40(IShortStrategy(data.shortStrategy).calcUtilRateEma(data.utilizationRate, data.emaUtilRate,
            GSMath.max(block.number - data.LAST_BLOCK_NUMBER, data.emaMultiplier)));

        data.lastPrice = IGammaPool(pool).getLastCFMMPrice();
        data.lastCFMMInvariant = uint128(lastCFMMInvariant);
        data.lastCFMMTotalSupply = lastCFMMTotalSupply;
    }

    /// @inheritdoc IPoolViewer
    function getPoolData(address pool) public virtual override view returns(IGammaPool.PoolData memory data) {
        data = IGammaPool(pool).getPoolData();
        (data.symbols, data.names,) = getTokensMetaData(data.tokens);
    }

    /// @inheritdoc IPoolViewer
    function getTokensMetaData(address[] memory _tokens) public virtual override view returns(string[] memory _symbols,
        string[] memory _names, uint8[] memory _decimals) {
        _symbols = new string[](_tokens.length);
        _names = new string[](_tokens.length);
        _decimals = new uint8[](_tokens.length);
        for(uint256 i = 0; i < _tokens.length;) {
            _symbols[i] = GammaSwapLibrary.symbol(_tokens[i]);
            _names[i] = GammaSwapLibrary.name(_tokens[i]);
            _decimals[i] = GammaSwapLibrary.decimals(_tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Update liquidity to current debt level
    /// @param liquidity - loan's liquidity debt
    /// @param rateIndex - accFeeIndex in last update of loan's liquidity debt
    /// @param accFeeIndex - current accFeeIndex
    /// @return updatedLiquidity - liquidity debt updated to current time
    function _updateLiquidity(uint256 liquidity, uint256 rateIndex, uint256 accFeeIndex) internal virtual view returns(uint128) {
        return rateIndex == 0 ? 0 : uint128(liquidity * accFeeIndex / rateIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IGammaPoolEvents.sol";
import "./IProtocol.sol";
import "./strategies/events/IGammaPoolERC20Events.sol";
import "./rates/IRateModel.sol";

/// @title Interface for GammaPool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for GammaPool implementations
interface IGammaPool is IProtocol, IGammaPoolEvents, IGammaPoolERC20Events, IRateModel {
    /// @dev Struct containing Loan data plus tokenId
    struct LoanData {
        /// @dev Loan counter, used to generate unique tokenId which indentifies the loan in the GammaPool
        uint256 id;

        /// @dev Loan tokenId
        uint256 tokenId;

        // 1x256 bits
        /// @dev GammaPool address loan belongs to
        address poolId; // 160 bits
        /// @dev Index of GammaPool interest rate at time loan is created/updated, max 7.9% trillion
        uint96 rateIndex; // 96 bits

        // 1x256 bits
        /// @dev Initial loan debt in liquidity invariant units. Only increase when more liquidity is borrowed, decreases when liquidity is paid
        uint128 initLiquidity; // 128 bits
        /// @dev Loan debt in liquidity invariant units in last update
        uint128 lastLiquidity; // 128 bits
        /// @dev Loan debt in liquidity invariant units, increases with every update according to how many blocks have passed
        uint128 liquidity; // 128 bits
        /// @dev Collateral in terms of liquidity invariant units, increases with every update according to how many blocks have passed
        uint256 collateral;

        /// @dev Initial loan debt in terms of LP tokens at time liquidity was borrowed, updates along with initLiquidity
        uint256 lpTokens;
        /// @dev Reserve tokens held as collateral for the liquidity debt, indices match GammaPool's tokens[] array indices
        uint128[] tokensHeld; // array of 128 bit numbers

        /// @dev reference address of contract holding additional collateral for loan (e.g. CollateralManager)
        address refAddr;
        /// @dev reference fee of contract holding additional collateral for loan (e.g. CollateralManager)
        uint16 refFee;
        /// @dev reference type of contract holding additional collateral for loan (e.g. CollateralManager)
        uint8 refType;

        /// @dev price at which loan was opened
        uint256 px;
        /// @dev if true loan can be liquidated
        bool canLiquidate;

        /// @dev names of ERC20 tokens of CFMM
        uint256 accFeeIndex;
        /// @dev Percent accrual in CFMM invariant since last update
        uint256 lastCFMMFeeIndex;
        /// @dev names of ERC20 tokens of CFMM
        uint256 LAST_BLOCK_NUMBER;

        /// @dev ERC20 tokens of CFMM
        address[] tokens;
        /// @dev decimals of ERC20 tokens of CFMM
        uint8[] decimals;
        /// @dev symbols of ERC20 tokens of CFMM
        string[] symbols;
        /// @dev names of ERC20 tokens of CFMM
        string[] names;

        /// @dev interest rate model parameter store
        address paramsStore;
        /// @dev address of short strategy
        address shortStrategy;

        /// @dev borrowed liquidity invariant of the pool
        uint256 BORROWED_INVARIANT;
        /// @dev Quantity of CFMM's liquidity invariant held in GammaPool as LP tokens
        uint256 LP_INVARIANT;
        /// @dev balance of CFMM LP tokens in the pool
        uint256 LP_TOKEN_BALANCE;
        /// @dev last CFMM liquidity invariant
        uint256 lastCFMMInvariant;
        /// @dev last CFMM total supply of LP tokens
        uint256 lastCFMMTotalSupply;
        /// @dev LTV liquidation threshold
        uint256 ltvThreshold;
        /// @dev Liquidation fee
        uint256 liquidationFee;
    }

    /// @dev Struct returned in getLatestRates function. Contains all relevant global state variables
    struct RateData {
        /// @dev GammaPool's ever increasing interest rate index, tracks interest accrued through CFMM and liquidity loans, max 7.9% trillion
        uint256 accFeeIndex;
        /// @dev Percent accrual in CFMM invariant since last update
        uint256 lastCFMMFeeIndex;
        /// @dev Percent accrual in CFMM invariant and GammaPool interest since last update
        uint256 lastFeeIndex;
        /// @dev Borrow APR of LP tokens in GammaPool
        uint256 borrowRate;
        /// @dev Utilization rate of GammaPool
        uint256 utilizationRate;
        /// @dev last block an update to the GammaPool's global storage variables happened
        uint256 lastBlockNumber;
        /// @dev Current block number when requesting pool data
        uint256 currBlockNumber;
        /// @dev Last Price in CFMM
        uint256 lastPrice;
        /// @dev Supply APR of LP tokens in GammaPool
        uint256 supplyRate;
        /// @dev names of ERC20 tokens of CFMM
        uint256 BORROWED_INVARIANT;
        /// @dev Quantity of CFMM's liquidity invariant held in GammaPool as LP tokens
        uint256 LP_INVARIANT;
        /// @dev EMA of utilization Rate
        uint256 emaUtilRate;
        /// @dev Minimum Utilization Rate 1
        uint256 minUtilRate1;
        /// @dev Minimum Utilization Rate 2
        uint256 minUtilRate2;
        /// @dev Dynamic origination fee divisor
        uint256 feeDivisor;
        /// @dev Loan opening origination fee in basis points
        uint256 origFee; // 16 bits
        /// @dev LTV liquidation threshold
        uint256 ltvThreshold;
        /// @dev Liquidation fee
        uint256 liquidationFee;
        /// @dev Short Strategy implementation address
        address shortStrategy;
        /// @dev Interest Rate Parameters Store contract
        address paramsStore;
    }

    /// @dev Struct returned in getPoolData function. Contains all relevant global state variables
    struct PoolData {
        /// @dev GammaPool address
        address poolId;
        /// @dev Protocol id of the implementation contract for this GammaPool
        uint16 protocolId;
        /// @dev Borrow Strategy implementation contract for this GammaPool
        address borrowStrategy;
        /// @dev Repay Strategy implementation contract for this GammaPool
        address repayStrategy;
        /// @dev Rebalance Strategy implementation contract for this GammaPool
        address rebalanceStrategy;
        /// @dev Short Strategy implementation contract for this GammaPool
        address shortStrategy;
        /// @dev Single Liquidation Strategy implementation contract for this GammaPool
        address singleLiquidationStrategy;
        /// @dev Batch Liquidation Strategy implementation contract for this GammaPool
        address batchLiquidationStrategy;

        /// @dev factory - address of factory contract that instantiated this GammaPool
        address factory;
        /// @dev paramsStore - interest rate model parameters store contract
        address paramsStore;

        // LP Tokens
        /// @dev Quantity of CFMM's LP tokens deposited in GammaPool by liquidity providers
        uint256 LP_TOKEN_BALANCE;// LP Tokens in GS, LP_TOKEN_TOTAL = LP_TOKEN_BALANCE + LP_TOKEN_BORROWED_PLUS_INTEREST
        /// @dev Quantity of CFMM's LP tokens that have been borrowed by liquidity borrowers excluding accrued interest (principal)
        uint256 LP_TOKEN_BORROWED;//LP Tokens that have been borrowed (Principal)
        /// @dev Quantity of CFMM's LP tokens that have been borrowed by liquidity borrowers including accrued interest
        uint256 LP_TOKEN_BORROWED_PLUS_INTEREST;//LP Tokens that have been borrowed (principal) plus interest in LP Tokens

        // Invariants
        /// @dev Quantity of CFMM's liquidity invariant that has been borrowed including accrued interest, maps to LP_TOKEN_BORROWED_PLUS_INTEREST
        uint128 BORROWED_INVARIANT;
        /// @dev Quantity of CFMM's liquidity invariant held in GammaPool as LP tokens, maps to LP_TOKEN_BALANCE
        uint128 LP_INVARIANT;//Invariant from LP Tokens, TOTAL_INVARIANT = BORROWED_INVARIANT + LP_INVARIANT

        // Rates
        /// @dev cfmm - address of CFMM this GammaPool is for
        address cfmm;
        /// @dev GammaPool's ever increasing interest rate index, tracks interest accrued through CFMM and liquidity loans, max 30.9% billion
        uint80 accFeeIndex;
        /// @dev External swap fee in basis points, max 255 basis points = 2.55%
        uint8 extSwapFee; // 8 bits
        /// @dev Loan opening origination fee in basis points
        uint16 origFee; // 16 bits
        /// @dev LAST_BLOCK_NUMBER - last block an update to the GammaPool's global storage variables happened
        uint40 LAST_BLOCK_NUMBER;
        /// @dev Percent accrual in CFMM invariant since last update
        uint64 lastCFMMFeeIndex; // 64 bits
        /// @dev Total liquidity invariant amount in CFMM (from GammaPool and others), read in last update to GammaPool's storage variables
        uint128 lastCFMMInvariant;
        /// @dev Total LP token supply from CFMM (belonging to GammaPool and others), read in last update to GammaPool's storage variables
        uint256 lastCFMMTotalSupply;

        // ERC20 fields
        /// @dev Total supply of GammaPool's own ERC20 token representing the liquidity of depositors to the CFMM through the GammaPool
        uint256 totalSupply;

        // tokens and balances
        /// @dev ERC20 tokens of CFMM
        address[] tokens;
        /// @dev symbols of ERC20 tokens of CFMM
        string[] symbols;
        /// @dev names of ERC20 tokens of CFMM
        string[] names;
        /// @dev Decimals of CFMM tokens, indices match tokens[] array
        uint8[] decimals;
        /// @dev Amounts of ERC20 tokens from the CFMM held as collateral in the GammaPool. Equals to the sum of all tokensHeld[] quantities in all loans
        uint128[] TOKEN_BALANCE;
        /// @dev Amounts of ERC20 tokens from the CFMM held in the CFMM as reserve quantities. Used to log prices in the CFMM during updates to the GammaPool
        uint128[] CFMM_RESERVES; //keeps track of price of CFMM at time of update

        /// @dev Last Price in CFMM
        uint256 lastPrice;
        /// @dev Percent accrual in CFMM invariant and GammaPool interest since last update
        uint256 lastFeeIndex;
        /// @dev Borrow rate of LP tokens in GammaPool
        uint256 borrowRate;
        /// @dev Utilization rate of GammaPool
        uint256 utilizationRate;
        /// @dev Current block number when requesting pool data
        uint40 currBlockNumber;
        /// @dev LTV liquidation threshold
        uint8 ltvThreshold;
        /// @dev Liquidation fee
        uint8 liquidationFee;
        /// @dev Supply APR of LP tokens in GammaPool
        uint256 supplyRate;
        /// @dev EMA of utilization Rate
        uint40 emaUtilRate;
        /// @dev Multiplier of EMA Utilization Rate
        uint8 emaMultiplier;
        /// @dev Minimum Utilization Rate 1
        uint8 minUtilRate1;
        /// @dev Minimum Utilization Rate 2
        uint8 minUtilRate2;
        /// @dev Dynamic origination fee divisor
        uint16 feeDivisor;
        /// @dev Minimum liquidity amount that can be borrowed
        uint72 minBorrow;
    }

    /// @dev cfmm - address of CFMM this GammaPool is for
    function cfmm() external view returns(address);

    /// @dev ERC20 tokens of CFMM
    function tokens() external view returns(address[] memory);

    /// @dev address of factory contract that instantiated this GammaPool
    function factory() external view returns(address);

    /// @dev viewer contract to implement complex view functions for data in this GammaPool
    function viewer() external view returns(address);

    /// @dev Borrow Strategy implementation contract for this GammaPool
    function borrowStrategy() external view returns(address);

    /// @dev Repay Strategy implementation contract for this GammaPool
    function repayStrategy() external view returns(address);

    /// @dev Rebalance Strategy implementation contract for this GammaPool
    function rebalanceStrategy() external view returns(address);

    /// @dev Short Strategy implementation contract for this GammaPool
    function shortStrategy() external view returns(address);

    /// @dev Single Loan Liquidation Strategy implementation contract for this GammaPool
    function singleLiquidationStrategy() external view returns(address);

    /// @dev Batch Liquidations Strategy implementation contract for this GammaPool
    function batchLiquidationStrategy() external view returns(address);

    /// @dev Set parameters to calculate origination fee, liquidation fee, and ltv threshold
    /// @param origFee - loan opening origination fee in basis points
    /// @param extSwapFee - external swap fee in basis points, max 255 basis points = 2.55%
    /// @param emaMultiplier - multiplier used in EMA calculation of utilization rate
    /// @param minUtilRate1 - minimum utilization rate to calculate dynamic origination fee in exponential model
    /// @param minUtilRate2 - minimum utilization rate to calculate dynamic origination fee in linear model
    /// @param feeDivisor - fee divisor for calculating origination fee, based on 2^(maxUtilRate - minUtilRate1)
    /// @param liquidationFee - liquidation fee to charge during liquidations in basis points (1 - 255 => 0.01% to 2.55%)
    /// @param ltvThreshold - ltv threshold (1 - 255 => 0.1% to 25.5%)
    /// @param minBorrow - minimum liquidity amount that can be borrowed or left unpaid in a loan
    function setPoolParams(uint16 origFee, uint8 extSwapFee, uint8 emaMultiplier, uint8 minUtilRate1, uint8 minUtilRate2, uint16 feeDivisor, uint8 liquidationFee, uint8 ltvThreshold, uint72 minBorrow) external;

    /// @dev Balances in the GammaPool of collateral tokens, CFMM LP tokens, and invariant amounts at last update
    /// @return tokenBalances - balances of collateral tokens in GammaPool
    /// @return lpTokenBalance - CFMM LP token balance of GammaPool
    /// @return lpTokenBorrowed - CFMM LP token principal amounts borrowed from GammaPool
    /// @return lpTokenBorrowedPlusInterest - CFMM LP token amounts borrowed from GammaPool including accrued interest
    /// @return borrowedInvariant - invariant amount borrowed from GammaPool including accrued interest, maps to lpTokenBorrowedPlusInterest
    /// @return lpInvariant - invariant of CFMM LP tokens in GammaPool not borrowed, maps to lpTokenBalance
    function getPoolBalances() external view returns(uint128[] memory tokenBalances, uint256 lpTokenBalance, uint256 lpTokenBorrowed,
        uint256 lpTokenBorrowedPlusInterest, uint256 borrowedInvariant, uint256 lpInvariant);

    /// @dev Balances in CFMM at last update of GammaPool
    /// @return cfmmReserves - total reserve tokens in CFMM last time GammaPool was updated
    /// @return cfmmInvariant - total liquidity invariant of CFMM last time GammaPool was updated
    /// @return cfmmTotalSupply - total CFMM LP tokens in existence last time GammaPool was updated
    function getCFMMBalances() external view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply);

    /// @dev Interest rate information in GammaPool at last update
    /// @return accFeeIndex - total accrued interest in GammaPool at last update
    /// @return lastCFMMFeeIndex - total accrued CFMM fee since last update
    /// @return lastBlockNumber - last block GammaPool was updated
    function getRates() external view returns(uint256 accFeeIndex, uint256 lastCFMMFeeIndex, uint256 lastBlockNumber);

    /// @return data - struct containing all relevant global state variables and descriptive information of GammaPool. Used to avoid making multiple calls
    function getPoolData() external view returns(PoolData memory data);

    // Short Gamma

    /// @dev Deposit CFMM LP token and get GS LP token, without doing a transferFrom transaction. Must have sent CFMM LP token first
    /// @param to - address of receiver of GS LP token
    /// @return shares - quantity of GS LP tokens received for CFMM LP tokens
    function depositNoPull(address to) external returns(uint256 shares);

    /// @dev Withdraw CFMM LP token, by burning GS LP token, without doing a transferFrom transaction. Must have sent GS LP token first
    /// @param to - address of receiver of CFMM LP tokens
    /// @return assets - quantity of CFMM LP tokens received for GS LP tokens
    function withdrawNoPull(address to) external returns(uint256 assets);

    /// @dev Withdraw reserve token quantities of CFMM (instead of CFMM LP tokens), by burning GS LP token
    /// @param to - address of receiver of reserve token quantities
    /// @return reserves - quantity of reserve tokens withdrawn from CFMM and sent to receiver
    /// @return assets - quantity of CFMM LP tokens representing reserve tokens withdrawn
    function withdrawReserves(address to) external returns (uint256[] memory reserves, uint256 assets);

    /// @dev Deposit reserve token quantities to CFMM (instead of CFMM LP tokens) to get CFMM LP tokens, store them in GammaPool and receive GS LP tokens
    /// @param to - address of receiver of GS LP tokens
    /// @param amountsDesired - desired amounts of reserve tokens to deposit
    /// @param amountsMin - minimum amounts of reserve tokens to deposit
    /// @param data - information identifying request to deposit
    /// @return reserves - quantity of actual reserve tokens deposited in CFMM
    /// @return shares - quantity of GS LP tokens received for reserve tokens deposited
    function depositReserves(address to, uint256[] calldata amountsDesired, uint256[] calldata amountsMin, bytes calldata data) external returns(uint256[] memory reserves, uint256 shares);

    /// @return cfmmReserves - latest token reserves in the CFMM
    function getLatestCFMMReserves() external view returns(uint128[] memory cfmmReserves);

    /// @return cfmmReserves - latest token reserves in the CFMM
    /// @return cfmmInvariant - latest total invariant in the CFMM
    /// @return cfmmTotalSupply - latest total supply of LP tokens in CFMM
    function getLatestCFMMBalances() external view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply);

    /// @return lastPrice - calculates and gets current price at CFMM
    function getLastCFMMPrice() external view returns(uint256);

    // Long Gamma

    /// @dev Create a new Loan struct
    /// @param refId - Reference id of post transaction activities attached to this loan
    /// @return tokenId - unique id of loan struct created
    function createLoan(uint16 refId) external returns(uint256 tokenId);

    /// @dev Get loan from storage and convert to LoanData struct
    /// @param _tokenId - tokenId of loan to convert
    /// @return _loanData - loan data struct (same as Loan + tokenId)
    function getLoanData(uint256 _tokenId) external view returns(LoanData memory _loanData);

    /// @dev Get loan with its most updated information
    /// @param _tokenId - unique id of loan, used to look up loan in GammaPool
    /// @return _loanData - loan data struct (same as Loan + tokenId)
    function loan(uint256 _tokenId) external view returns(LoanData memory _loanData);

    /// @dev Get list of loans and their corresponding tokenIds created in GammaPool. Capped at s.tokenIds.length.
    /// @param start - index from where to start getting tokenIds from array
    /// @param end - end index of array wishing to get tokenIds. If end > s.tokenIds.length, end is s.tokenIds.length
    /// @param active - if true, return loans that have an outstanding liquidity debt
    /// @return _loans - list of loans created in GammaPool
    function getLoans(uint256 start, uint256 end, bool active) external view returns(LoanData[] memory _loans);

    /// @dev calculate liquidity invariant from collateral tokens
    /// @param tokensHeld - loan's collateral tokens
    /// @return collateralInvariant - invariant calculated from loan's collateral tokens
    function calcInvariant(uint128[] memory tokensHeld) external view returns(uint256);

    /// @dev Get list of loans mapped to tokenIds in array `tokenIds`
    /// @param tokenIds - list of loan tokenIds
    /// @param active - if true, return loans that have an outstanding liquidity debt
    /// @return _loans - list of loans created in GammaPool
    function getLoansById(uint256[] calldata tokenIds, bool active) external view returns(LoanData[] memory _loans);

    /// @return loanCount - total number of loans opened
    function getLoanCount() external view returns(uint256);

    /// @dev Deposit more collateral in loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param ratio - ratio to rebalance collateral after increasing collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function increaseCollateral(uint256 tokenId, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Withdraw collateral from loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param amounts - amounts of collateral tokens requested to withdraw
    /// @param to - destination address of receiver of collateral withdrawn
    /// @param ratio - ratio to rebalance collateral after withdrawing collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function decreaseCollateral(uint256 tokenId, uint128[] memory amounts, address to, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Borrow liquidity from the CFMM and add it to the debt and collateral of loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param lpTokens - quantity of CFMM LP tokens requested to short
    /// @param ratio - ratio to rebalance collateral after borrowing
    /// @return liquidityBorrowed - liquidity amount that has been borrowed
    /// @return amounts - reserves quantities withdrawn from CFMM that correspond to the LP tokens shorted, now used as collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function borrowLiquidity(uint256 tokenId, uint256 lpTokens, uint256[] calldata ratio) external returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld);

    /// @dev Repay liquidity debt of loan identified by tokenId, debt is repaid using available collateral in loan
    /// @param tokenId - unique id identifying loan
    /// @param liquidity - liquidity debt being repaid, capped at actual liquidity owed. Can't repay more than you owe
    /// @param collateralId - index of collateral token + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @return liquidityPaid - liquidity amount that has been repaid
    /// @return amounts - collateral amounts consumed in repaying liquidity debt
    function repayLiquidity(uint256 tokenId, uint256 liquidity, uint256 collateralId, address to) external returns(uint256 liquidityPaid, uint256[] memory amounts);

    /// @dev Repay liquidity debt of loan identified by tokenId, debt is repaid using available collateral in loan
    /// @param tokenId - unique id identifying loan
    /// @param liquidity - liquidity debt being repaid, capped at actual liquidity owed. Can't repay more than you owe
    /// @param ratio - weights of collateral after repaying liquidity
    /// @return liquidityPaid - liquidity amount that has been repaid
    /// @return amounts - collateral amounts consumed in repaying liquidity debt
    function repayLiquiditySetRatio(uint256 tokenId, uint256 liquidity, uint256[] calldata ratio) external returns(uint256 liquidityPaid, uint256[] memory amounts);

    /// @dev Repay liquidity debt of loan identified by tokenId, using CFMM LP token
    /// @param tokenId - unique id identifying loan
    /// @param collateralId - index of collateral token to rebalance to + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @return liquidityPaid - liquidity amount that has been repaid
    /// @return tokensHeld - remaining token amounts collateralizing loan
    function repayLiquidityWithLP(uint256 tokenId, uint256 collateralId, address to) external returns(uint256 liquidityPaid, uint128[] memory tokensHeld);

    /// @dev Rebalance collateral amounts of loan identified by tokenId by purchasing or selling some of the collateral
    /// @param tokenId - unique id identifying loan
    /// @param deltas - collateral amounts being bought or sold (>0 buy, <0 sell), index matches tokensHeld[] index. Only n-1 tokens can be traded
    /// @param ratio - ratio to rebalance collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function rebalanceCollateral(uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Update pool liquidity debt and optinally also loan liquidity debt
    /// @param tokenId - (optional) unique ids identifying loan, pass zero to ignore this parameter
    /// @return loanLiquidityDebt - updated liquidity debt amount of loan
    /// @return poolLiquidityDebt - updated liquidity debt amount of pool
    function updatePool(uint256 tokenId) external returns(uint256 loanLiquidityDebt, uint256 poolLiquidityDebt);

    /// @notice When calling this function and adding additional collateral it is assumed that you have sent the collateral first
    /// @dev Function to liquidate a loan using its own collateral or depositing additional tokens. Seeks full liquidation
    /// @param tokenId - tokenId of loan being liquidated
    /// @return loanLiquidity - loan liquidity liquidated (after write down)
    /// @return refund - amount of CFMM LP tokens being refunded to liquidator
    function liquidate(uint256 tokenId) external returns(uint256 loanLiquidity, uint256 refund);

    /// @dev Function to liquidate a loan using external LP tokens. Allows partial liquidation
    /// @param tokenId - tokenId of loan being liquidated
    /// @return loanLiquidity - loan liquidity liquidated (after write down)
    /// @return refund - amounts from collateral tokens being refunded to liquidator
    function liquidateWithLP(uint256 tokenId) external returns(uint256 loanLiquidity, uint256[] memory refund);

    /// @dev Function to liquidate multiple loans in batch.
    /// @param tokenIds - list of tokenIds of loans to liquidate
    /// @return totalLoanLiquidity - total loan liquidity liquidated (after write down)
    /// @return refund - amounts from collateral tokens being refunded to liquidator
    function batchLiquidations(uint256[] calldata tokenIds) external returns(uint256 totalLoanLiquidity, uint256[] memory refund);

    // Sync functions

    /// @dev Skim excess collateral tokens or CFMM LP tokens from GammaPool and send them to receiver (`to`) address
    /// @param to - address receiving excess tokens
    function skim(address to) external;

    /// @dev Synchronize LP_TOKEN_BALANCE with actual CFMM LP tokens deposited in GammaPool
    function sync() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./strategies/events/ILiquidationStrategyEvents.sol";
import "./strategies/events/IShortStrategyEvents.sol";
import "./strategies/events/IExternalStrategyEvents.sol";

/// @title GammaPool Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by all GammaPool implementations (contains all strategy events)
interface IGammaPoolEvents is IShortStrategyEvents, ILiquidationStrategyEvents, IExternalStrategyEvents {
    /// @dev Event emitted when a Loan is created
    /// @param caller - address that created the loan
    /// @param tokenId - unique id that identifies the loan in question
    /// @param refId - Reference id of post transaction activities attached to this loan
    event LoanCreated(address indexed caller, uint256 tokenId, uint16 refId);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IGammaPool.sol";

/// @title Interface for Viewer Contract for GammaPool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Viewer makes complex view function calls from GammaPool's storage data (e.g. updated loan and pool debt)
interface IPoolViewer {

    /// @dev Check if can liquidate loan identified by `tokenId`
    /// @param pool - address of pool loans belong to
    /// @param tokenId - unique id of loan, used to look up loan in GammaPool
    /// @return canLiquidate - true if loan can be liquidated, false otherwise
    function canLiquidate(address pool, uint256 tokenId) external view returns(bool);

    /// @dev Get latest rate information from GammaPool
    /// @param pool - address of pool to request latest rates for
    /// @return data - RateData struct containing latest rate information
    function getLatestRates(address pool) external view returns(IGammaPool.RateData memory data);

    /// @dev Get list of loans and their corresponding tokenIds created in GammaPool. Capped at s.tokenIds.length.
    /// @param pool - address of pool loans belong to
    /// @param start - index from where to start getting tokenIds from array
    /// @param end - end index of array wishing to get tokenIds. If end > s.tokenIds.length, end is s.tokenIds.length
    /// @param active - if true, return loans that have an outstanding liquidity debt
    /// @return _loans - list of loans created in GammaPool
    function getLoans(address pool, uint256 start, uint256 end, bool active) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @dev Get list of loans mapped to tokenIds in array `tokenIds`
    /// @param pool - address of pool loans belong to
    /// @param tokenIds - list of loan tokenIds
    /// @param active - if true, return loans that have an outstanding liquidity debt
    /// @return _loans - list of loans created in GammaPool
    function getLoansById(address pool, uint256[] calldata tokenIds, bool active) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @dev Get loan with its most updated information
    /// @param pool - address of pool loan belongs to
    /// @param tokenId - unique id of loan, used to look up loan in GammaPool
    /// @return loanData - loan data struct (same as Loan + tokenId)
    function loan(address pool, uint256 tokenId) external view returns(IGammaPool.LoanData memory loanData);

    /// @dev Returns pool storage data updated to their latest values
    /// @notice Difference with getPoolData() is this struct is what PoolData would return if an update of the GammaPool were to occur at the current block
    /// @param pool - address of pool to get pool data for
    /// @return data - struct containing all relevant global state variables and descriptive information of GammaPool. Used to avoid making multiple calls
    function getLatestPoolData(address pool) external view returns(IGammaPool.PoolData memory data);

    /// @dev Calculate origination fee that will be charged if borrowing liquidity amount
    /// @param pool - address of GammaPool to calculate origination fee for
    /// @param liquidity - liquidity to borrow
    /// @return origFee - calculated origination fee, without any discounts
    function calcDynamicOriginationFee(address pool, uint256 liquidity) external view returns(uint256 origFee);

    /// @dev Return pool storage data
    /// @param pool - address of pool to get pool data for
    /// @return data - struct containing all relevant global state variables and descriptive information of GammaPool. Used to avoid making multiple calls
    function getPoolData(address pool) external view returns(IGammaPool.PoolData memory data);

    /// @dev Get CFMM tokens meta data
    /// @param _tokens - array of token address of ERC20 tokens of CFMM
    /// @return _symbols - array of symbols of ERC20 tokens of CFMM
    /// @return _names - array of names of ERC20 tokens of CFMM
    /// @return _decimals - array of decimals of ERC20 tokens of CFMM
    function getTokensMetaData(address[] memory _tokens) external view returns(string[] memory _symbols, string[] memory _names, uint8[] memory _decimals);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for Protocol
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used to add protocols and initialize them in GammaPoolFactory
interface IProtocol {
    /// @dev Protocol id of the implementation contract for this GammaPool
    function protocolId() external view returns(uint16);

    /// @dev Check GammaPool for CFMM and tokens can be created with this implementation
    /// @param _tokens - assumed tokens of CFMM, validate function should check CFMM is indeed for these tokens
    /// @param _cfmm - address of CFMM GammaPool will be for
    /// @param _data - custom struct containing additional information used to verify the `_cfmm`
    /// @return _tokensOrdered - tokens ordered to match the same order as in CFMM
    function validateCFMM(address[] calldata _tokens, address _cfmm, bytes calldata _data) external view returns(address[] memory _tokensOrdered);

    /// @dev Function to initialize state variables GammaPool, called usually from GammaPoolFactory contract right after GammaPool instantiation
    /// @param _cfmm - address of CFMM GammaPool is for
    /// @param _tokens - ERC20 tokens of CFMM
    /// @param _decimals - decimals of CFMM tokens, indices must match _tokens[] array
    /// @param _data - custom struct containing additional information used to verify the `_cfmm`
    /// @param _minBorrow - minimum amount of liquidity that can be borrowed or left unpaid in a loan
    function initialize(address _cfmm, address[] calldata _tokens, uint8[] calldata _decimals, uint72 _minBorrow, bytes calldata _data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./ILoanObserver.sol";

/// @title Interface for CollateralManager
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for CollateralManager. External contract that can hold collateral for loan and liquidate debt with its collateral
/// @notice GammaSwap team will create CollateralManagers that may have hooks available for other developers to extend functionality of GammaPool
interface ICollateralManager is ILoanObserver {

    /// @dev Get collateral of loan identified by tokenId
    /// @param gammaPool - address of pool loan identified by tokenId belongs to
    /// @param tokenId - unique identifier of loan in GammaPool
    /// @return collateral - loan collateral held outside of GammaPool for loan identified by `tokenId`
    function getCollateral(address gammaPool, uint256 tokenId) external view returns(uint256 collateral);

    /// @notice Should require authentication that msg.sender is GammaPool of tokenId and GammaPool is registered
    /// @dev Liquidate loan debt of loan identified by tokenId
    /// @param cfmm - address of the CFMM GammaPool is for
    /// @param protocolId - protocol id of the implementation contract for this GammaPool
    /// @param tokenId - unique identifier of loan in GammaPool
    /// @param amount - liquidity amount to liquidate
    /// @param to - address of liquidator
    /// @return collateral - loan collateral held outside of GammaPool (Only significant when the loan tracks collateral)
    function liquidateCollateral(address cfmm, uint16 protocolId, uint256 tokenId, uint256 amount, address to) external returns(uint256 collateral);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for LoanObserver
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for LoanObserver. External contract that can hold collateral for loan or implement after loan update hook
/// @notice GammaSwap team will create LoanObservers that will either work as Collateral Managers or hooks to update code
interface ILoanObserver {

    struct LoanObserved {
        /// @dev Loan counter, used to generate unique tokenId which indentifies the loan in the GammaPool
        uint256 id;

        // 1x256 bits
        /// @dev Index of GammaPool interest rate at time loan is created/updated, max 7.9% trillion
        uint96 rateIndex; // 96 bits

        // 1x256 bits
        /// @dev Initial loan debt in liquidity invariant units. Only increase when more liquidity is borrowed, decreases when liquidity is paid
        uint128 initLiquidity; // 128 bits
        /// @dev Loan debt in liquidity invariant units, increases with every update according to how many blocks have passed
        uint128 liquidity; // 128 bits

        /// @dev Initial loan debt in terms of LP tokens at time liquidity was borrowed, updates along with initLiquidity
        uint256 lpTokens;
        /// @dev Reserve tokens held as collateral for the liquidity debt, indices match GammaPool's tokens[] array indices
        uint128[] tokensHeld; // array of 128 bit numbers

        /// @dev price at which loan was opened
        uint256 px;
    }

    /// @dev Unique identifier of observer
    function refId() external view returns(uint16);

    /// @dev Observer type (2 = does not track collateral and onLoanUpdate returns zero, 3 = tracks collateral and onLoanUpdate returns collateral held outside of GammaPool)
    function refType() external view returns(uint16);

    /// @dev Validate observer can work with GammaPool
    /// @param gammaPool - address of GammaPool observer contract will observe
    /// @return validated - true if observer can work with `gammaPool`, false otherwise
    function validate(address gammaPool) external view returns(bool);

    /// @notice Used to identify requests from GammaPool
    /// @dev Factory contract of GammaPool observer will receive updates from
    function factory() external view returns(address);

    /// @notice Should require authentication that msg.sender is GammaPool of tokenId and GammaPool is registered
    /// @dev Update observer when a loan update occurs
    /// @dev If an observer does not hold collateral for loan it should return 0
    /// @param cfmm - address of the CFMM GammaPool is for
    /// @param protocolId - protocol id of the implementation contract for this GammaPool
    /// @param tokenId - unique identifier of loan in GammaPool
    /// @param data - data passed by gammaPool (e.g. LoanObserved)
    /// @return collateral - loan collateral held outside of GammaPool (Only significant when the loan tracks collateral)
    function onLoanUpdate(address cfmm, uint16 protocolId, uint256 tokenId, bytes memory data) external returns(uint256 collateral);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface of Interest Rate Model Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface of contract that saves and retrieves interest rate model parameters
interface IRateModel {
    /// @dev Function to validate interest rate model parameters
    /// @param _data - bytes parameters containing interest rate model parameters
    /// @return validation - true if parameters passed validation
    function validateParameters(bytes calldata _data) external view returns(bool);

    /// @dev Gets address of contract containing parameters for interest rate model
    /// @return address - address of smart contract that stores interest rate parameters
    function rateParamsStore() external view returns(address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../events/ILongStrategyEvents.sol";

/// @title Interface for Long Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that borrow and repay liquidity loans
interface ILongStrategy is ILongStrategyEvents {
    /// @return loan to value threshold over which a loan is eligible for liquidation
    function ltvThreshold() external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../events/IShortStrategyEvents.sol";

/// @title Interface for Short Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that deposit and withdraw liquidity from CFMM for liquidity providers
interface IShortStrategy is IShortStrategyEvents {

    /// @dev Parameters used to calculate the GS LP tokens and CFMM LP tokens in the GammaPool after protocol fees and accrued interest
    struct VaultBalancesParams {
        /// @dev address of factory contract of GammaPool
        address factory;
        /// @dev address of GammaPool
        address pool;
        /// @dev address of contract holding rate parameters for pool
        address paramsStore;
        /// @dev storage number of borrowed liquidity invariant in GammaPool
        uint256 BORROWED_INVARIANT;
        /// @dev current liquidity invariant in CFMM
        uint256 latestCfmmInvariant;
        /// @dev current total supply of CFMM LP tokens in existence
        uint256 latestCfmmTotalSupply;
        /// @dev last block number GammaPool was updated
        uint256 LAST_BLOCK_NUMBER;
        /// @dev CFMM liquidity invariant at time of last update of GammaPool
        uint256 lastCFMMInvariant;
        /// @dev CFMM LP Token supply at time of last update of GammaPool
        uint256 lastCFMMTotalSupply;
        /// @dev CFMM Fee Index at time of last update of GammaPool
        uint256 lastCFMMFeeIndex;
        /// @dev current total supply of GS LP tokens
        uint256 totalSupply;
        /// @dev current LP Tokens in GammaPool counted at time of last update
        uint256 LP_TOKEN_BALANCE;
        /// @dev liquidity invariant of LP tokens in GammaPool at time of last update
        uint256 LP_INVARIANT;
    }


    /// @dev Deposit CFMM LP tokens and get GS LP tokens, without doing a transferFrom transaction. Must have sent CFMM LP tokens first
    /// @param to - address of receiver of GS LP token
    /// @return shares - quantity of GS LP tokens received for CFMM LP tokens
    function _depositNoPull(address to) external returns(uint256 shares);

    /// @dev Withdraw CFMM LP tokens, by burning GS LP tokens, without doing a transferFrom transaction. Must have sent GS LP tokens first
    /// @param to - address of receiver of CFMM LP tokens
    /// @return assets - quantity of CFMM LP tokens received for GS LP tokens
    function _withdrawNoPull(address to) external returns(uint256 assets);

    /// @dev Withdraw reserve token quantities of CFMM (instead of CFMM LP tokens), by burning GS LP tokens
    /// @param to - address of receiver of reserve token quantities
    /// @return reserves - quantity of reserve tokens withdrawn from CFMM and sent to receiver
    /// @return assets - quantity of CFMM LP tokens representing reserve tokens withdrawn
    function _withdrawReserves(address to) external returns(uint256[] memory reserves, uint256 assets);

    /// @dev Deposit reserve token quantities to CFMM (instead of CFMM LP tokens) to get CFMM LP tokens, store them in GammaPool and receive GS LP tokens
    /// @param to - address of receiver of GS LP tokens
    /// @param amountsDesired - desired amounts of reserve tokens to deposit
    /// @param amountsMin - minimum amounts of reserve tokens to deposit
    /// @param data - information identifying request to deposit
    /// @return reserves - quantity of actual reserve tokens deposited in CFMM
    /// @return shares - quantity of GS LP tokens received for reserve tokens deposited
    function _depositReserves(address to, uint256[] calldata amountsDesired, uint256[] calldata amountsMin, bytes calldata data) external returns(uint256[] memory reserves, uint256 shares);

    /// @dev Get latest reserves in the CFMM, which can be used for pricing
    /// @param cfmmData - bytes data for calculating CFMM reserves
    /// @return cfmmReserves - reserves in the CFMM
    function _getLatestCFMMReserves(bytes memory cfmmData) external view returns(uint128[] memory cfmmReserves);

    /// @dev Get latest invariant from CFMM
    /// @param cfmmData - bytes data for calculating CFMM invariant
    /// @return cfmmInvariant - reserves in the CFMM
    function _getLatestCFMMInvariant(bytes memory cfmmData) external view returns(uint256 cfmmInvariant);

    /// @dev Calculate current total CFMM LP tokens (real and virtual) in existence in the GammaPool, including accrued interest
    /// @param borrowedInvariant - invariant amount borrowed in GammaPool including accrued interest calculated in last update to GammaPool
    /// @param lpBalance - amount of LP tokens deposited in GammaPool
    /// @param lastCFMMInvariant - invariant amount in CFMM
    /// @param lastCFMMTotalSupply - total supply in CFMM
    /// @param lastFeeIndex - last fees charged by GammaPool since last update
    /// @return totalAssets - total CFMM LP tokens in existence in the pool (real and virtual) including accrued interest
    function totalAssets(uint256 borrowedInvariant, uint256 lpBalance, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply, uint256 lastFeeIndex) external view returns(uint256);

    /// @dev Calculate current total GS LP tokens in the GammaPool after dilution from protocol fees
    /// @param factory - address of factory contract that created GammaPool
    /// @param pool - address of pool to get interest rate calculations for
    /// @param lastCFMMFeeIndex - accrued CFMM Fees in storage
    /// @param lastFeeIndex - last fees charged by GammaPool since last update
    /// @param utilizationRate - current utilization rate of GammaPool
    /// @param supply - actual GS LP total supply available in the pool
    /// @return totalSupply - total GS LP tokens in the pool including accrued interest
    function totalSupply(address factory, address pool, uint256 lastCFMMFeeIndex, uint256 lastFeeIndex, uint256 utilizationRate, uint256 supply) external view returns (uint256);

    /// @dev Calculate fees charged by GammaPool since last update to liquidity loans and current borrow rate
    /// @param borrowRate - current borrow rate of GammaPool
    /// @param borrowedInvariant - invariant amount borrowed in GammaPool including accrued interest calculated in last update to GammaPool
    /// @param lastCFMMInvariant - current invariant amount of CFMM in GammaPool
    /// @param lastCFMMTotalSupply - current total supply of CFMM LP shares in GammaPool
    /// @param prevCFMMInvariant - invariant amount in CFMM in last update to GammaPool
    /// @param prevCFMMTotalSupply - total supply in CFMM in last update to GammaPool
    /// @param lastBlockNum - last block GammaPool was updated
    /// @param lastCFMMFeeIndex - last fees accrued by CFMM since last update
    /// @param maxCFMMFeeLeverage - max leverage of CFMM yield
    /// @param spread - spread to add to cfmmFeeIndex
    /// @return lastFeeIndex - last fees charged by GammaPool since last update
    /// @return updLastCFMMFeeIndex - updated fees accrued by CFMM till current block
    function getLastFees(uint256 borrowRate, uint256 borrowedInvariant, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply,
        uint256 prevCFMMInvariant, uint256 prevCFMMTotalSupply, uint256 lastBlockNum, uint256 lastCFMMFeeIndex,
        uint256 maxCFMMFeeLeverage, uint256 spread) external view returns(uint256 lastFeeIndex, uint256 updLastCFMMFeeIndex);

    /// @dev Calculate current total GS LP tokens after protocol fees and total CFMM LP tokens (real and virtual) in
    /// @dev existence in the GammaPool after accrued interest. The total assets and supply numbers returned by this
    /// @dev function are used in the ERC4626 implementation of the GammaPool
    /// @param vaultBalanceParams - parameters from GammaPool to calculate current total GS LP Tokens and CFMM LP Tokens after fees and interest
    /// @return assets - total CFMM LP tokens in existence in the pool (real and virtual) including accrued interest
    /// @return supply - total GS LP tokens in the pool including accrued interest
    function totalAssetsAndSupply(VaultBalancesParams memory vaultBalanceParams) external view returns(uint256 assets, uint256 supply);

    /// @dev Calculate balances updated by fees charged since last update
    /// @param lastFeeIndex - last fees charged by GammaPool since last update
    /// @param borrowedInvariant - invariant amount borrowed in GammaPool including accrued interest calculated in last update to GammaPool
    /// @param lpBalance - amount of LP tokens deposited in GammaPool
    /// @param lastCFMMInvariant - invariant amount in CFMM
    /// @param lastCFMMTotalSupply - total supply in CFMM
    /// @return lastLPBalance - last fees accrued by CFMM since last update
    /// @return lastBorrowedLPBalance - last fees charged by GammaPool since last update
    /// @return lastBorrowedInvariant - current borrow rate of GammaPool
    function getLatestBalances(uint256 lastFeeIndex, uint256 borrowedInvariant, uint256 lpBalance, uint256 lastCFMMInvariant,
        uint256 lastCFMMTotalSupply) external view returns(uint256 lastLPBalance, uint256 lastBorrowedLPBalance, uint256 lastBorrowedInvariant);

    /// @dev Update pool invariant, LP tokens borrowed plus interest, interest rate index, and last block update
    /// @param utilizationRate - interest accrued to loans in GammaPool
    /// @param emaUtilRateLast - interest accrued to loans in GammaPool
    /// @param emaMultiplier - interest accrued to loans in GammaPool
    /// @return emaUtilRate - interest accrued to loans in GammaPool
    function calcUtilRateEma(uint256 utilizationRate, uint256 emaUtilRateLast, uint256 emaMultiplier) external view returns(uint256 emaUtilRate);

    /// @dev Synchronize LP_TOKEN_BALANCE with actual CFMM LP tokens deposited in GammaPool
    function _sync() external;

    /***** ERC4626 Functions *****/

    /// @dev Deposit CFMM LP tokens and get GS LP tokens, does a transferFrom according to ERC4626 implementation
    /// @param assets - CFMM LP tokens deposited in exchange for GS LP tokens
    /// @param to - address receiving GS LP tokens
    /// @return shares - quantity of GS LP tokens sent to receiver address (`to`) for CFMM LP tokens
    function _deposit(uint256 assets, address to) external returns (uint256 shares);

    /// @dev Mint GS LP token in exchange for CFMM LP token deposits, does a transferFrom according to ERC4626 implementation
    /// @param shares - GS LP tokens minted from CFMM LP token deposits
    /// @param to - address receiving GS LP tokens
    /// @return assets - quantity of CFMM LP tokens sent to receiver address (`to`)
    function _mint(uint256 shares, address to) external returns (uint256 assets);

    /// @dev Withdraw CFMM LP token by burning GS LP tokens
    /// @param assets - amount of CFMM LP tokens requested to withdraw in exchange for GS LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address burning its GS LP tokens
    /// @return shares - quantity of GS LP tokens burned
    function _withdraw(uint256 assets, address to, address from) external returns (uint256 shares);

    /// @dev Redeem GS LP tokens and get CFMM LP token
    /// @param shares - GS LP tokens requested to redeem in exchange for GS LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address redeeming GS LP tokens
    /// @return assets - quantity of CFMM LP tokens sent to receiver address (`to`) for GS LP tokens redeemed
    function _redeem(uint256 shares, address to, address from) external returns (uint256 assets);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IStrategyEvents.sol";

/// @title External Strategy Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by external strategy (flash loans) implementations
interface IExternalStrategyEvents is IStrategyEvents {
    /// @dev Event emitted when a flash loan is made. Purpose of flash loan is for external swaps/rebalance of loan collateral
    /// @param tokenId - unique id that identifies the loan in question
    /// @param amounts - amounts of tokens held as collateral in pool that were swapped
    /// @param lpTokens - LP tokens swapped externally
    /// @param liquidity - total liquidity externally swapped in flash loan (amounts + lpTokens)
    /// @param txType - transaction type. Possible values come from enum TX_TYPE
    event ExternalSwap(uint256 indexed tokenId, uint128[] amounts, uint256 lpTokens, uint128 liquidity, TX_TYPE indexed txType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title GammaPool ERC20 Events
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events that should be emitted by all strategy implementations (root of all strategy events interfaces)
interface IGammaPoolERC20Events {
    /// @dev Emitted when `amount` GS LP tokens are moved from account `from` to account `to`.
    /// @param from - address sending GS LP tokens
    /// @param to - address receiving GS LP tokens
    /// @param amount - amount of GS LP tokens being sent
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to approve function. `amount` is the new allowance.
    /// @param owner - address which owns the GS LP tokens spender is being given permission to spend
    /// @param spender - address given permission to spend owner's GS LP tokens
    /// @param amount - amount of GS LP tokens spender is given permission to spend
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./ILongStrategyEvents.sol";

/// @title Liquidation Strategy Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by all liquidation strategy implementations
interface ILiquidationStrategyEvents is ILongStrategyEvents {
    /// @dev Event emitted when liquidating through _liquidate or _liquidateWithLP functions
    /// @param tokenId - id identifier of loan being liquidated
    /// @param collateral - collateral of loan being liquidated
    /// @param liquidity - liquidity debt being repaid
    /// @param writeDownAmt - amount of liquidity invariant being written down
    /// @param fee - liquidation fee paid to liquidator in liquidity invariant units
    /// @param txType - type of liquidation. Possible values come from enum TX_TYPE
    event Liquidation(uint256 indexed tokenId, uint128 collateral, uint128 liquidity, uint128 writeDownAmt, uint128 fee, TX_TYPE txType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IStrategyEvents.sol";

/// @title Long Strategy Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by all long strategy implementations
interface ILongStrategyEvents is IStrategyEvents {
    /// @dev Event emitted when a Loan is updated
    /// @param tokenId - unique id that identifies the loan in question
    /// @param tokensHeld - amounts of tokens held as collateral against the loan
    /// @param liquidity - liquidity invariant that was borrowed including accrued interest
    /// @param initLiquidity - initial liquidity borrowed excluding interest (principal)
    /// @param lpTokens - LP tokens borrowed excluding interest (principal)
    /// @param rateIndex - interest rate index of GammaPool at time loan is updated
    /// @param txType - transaction type. Possible values come from enum TX_TYPE
    event LoanUpdated(uint256 indexed tokenId, uint128[] tokensHeld, uint128 liquidity, uint128 initLiquidity, uint256 lpTokens, uint96 rateIndex, TX_TYPE indexed txType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IStrategyEvents.sol";

/// @title Short Strategy Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by all short strategy implementations
interface IShortStrategyEvents is IStrategyEvents {
    /// @dev Event emitted when a deposit of CFMM LP tokens in exchange of GS LP tokens happens (e.g. _deposit, _mint, _depositReserves, _depositNoPull)
    /// @param caller - address calling the function to deposit CFMM LP tokens
    /// @param to - address receiving GS LP tokens
    /// @param assets - amount CFMM LP tokens deposited
    /// @param shares - amount GS LP tokens minted
    event Deposit(address indexed caller, address indexed to, uint256 assets, uint256 shares);

    /// @dev Event emitted when a withdrawal of CFMM LP tokens happens (e.g. _withdraw, _redeem, _withdrawReserves, _withdrawNoPull)
    /// @param caller - address calling the function to withdraw CFMM LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address redeeming/burning GS LP tokens
    /// @param assets - amount of CFMM LP tokens withdrawn
    /// @param shares - amount of GS LP tokens redeemed
    event Withdraw(address indexed caller, address indexed to, address indexed from, uint256 assets, uint256 shares);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Strategy Events interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events that should be emitted by all strategy implementations (root of all strategy events interfaces)
interface IStrategyEvents {
    enum TX_TYPE {
        DEPOSIT_LIQUIDITY,      // 0
        WITHDRAW_LIQUIDITY,     // 1
        DEPOSIT_RESERVES,       // 2
        WITHDRAW_RESERVES,      // 3
        INCREASE_COLLATERAL,    // 4
        DECREASE_COLLATERAL,    // 5
        REBALANCE_COLLATERAL,   // 6
        BORROW_LIQUIDITY,       // 7
        REPAY_LIQUIDITY,        // 8
        REPAY_LIQUIDITY_SET_RATIO,// 9
        REPAY_LIQUIDITY_WITH_LP,// 10
        LIQUIDATE,              // 11
        LIQUIDATE_WITH_LP,      // 12
        BATCH_LIQUIDATION,      // 13
        SYNC,                   // 14
        EXTERNAL_REBALANCE,     // 15
        EXTERNAL_LIQUIDATION,   // 16
        UPDATE_POOL }           // 17

    /// @dev Event emitted when the Pool's global state variables is updated
    /// @param lpTokenBalance - quantity of CFMM LP tokens deposited in the pool
    /// @param lpTokenBorrowed - quantity of CFMM LP tokens that have been borrowed from the pool (principal)
    /// @param lastBlockNumber - last block the Pool's where updated
    /// @param accFeeIndex - interest of total accrued interest in the GammaPool until current update
    /// @param lpTokenBorrowedPlusInterest - quantity of CFMM LP tokens that have been borrowed from the pool including interest
    /// @param lpInvariant - lpTokenBalance as invariant units
    /// @param borrowedInvariant - lpTokenBorrowedPlusInterest as invariant units
    /// @param cfmmReserves - reserves in CFMM. Used to track price
    /// @param txType - transaction type. Possible values come from enum TX_TYPE
    event PoolUpdated(uint256 lpTokenBalance, uint256 lpTokenBorrowed, uint40 lastBlockNumber, uint80 accFeeIndex,
        uint256 lpTokenBorrowedPlusInterest, uint128 lpInvariant, uint128 borrowedInvariant, uint128[] cfmmReserves, TX_TYPE indexed txType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILongStrategy.sol";

/// @title Interface for Borrow Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that borrow liquidity
interface IBorrowStrategy is ILongStrategy {
    /// @dev Calculate and return dynamic origination fee in basis points
    /// @param baseOrigFee - base origination fee charge
    /// @param utilRate - current utilization rate of GammaPool
    /// @param lowUtilRate - low utilization rate threshold, used as a lower bound for the utilization rate
    /// @param minUtilRate1 - minimum utilization rate after which origination fee will start increasing exponentially
    /// @param minUtilRate2 - minimum utilization rate after which origination fee will start increasing linearly
    /// @param feeDivisor - fee divisor of formula for dynamic origination fee
    /// @return origFee - origination fee that will be applied to loan
    function calcDynamicOriginationFee(uint256 baseOrigFee, uint256 utilRate, uint256 lowUtilRate, uint256 minUtilRate1, uint256 minUtilRate2, uint256 feeDivisor) external view returns(uint256 origFee);

    /// @dev Deposit more collateral in loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param ratio - ratio to rebalance collateral after increasing collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _increaseCollateral(uint256 tokenId, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Withdraw collateral from loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param amounts - amounts of collateral tokens requested to withdraw
    /// @param to - destination address of receiver of collateral withdrawn
    /// @param ratio - ratio to rebalance collateral after withdrawing collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _decreaseCollateral(uint256 tokenId, uint128[] memory amounts, address to, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Borrow liquidity from the CFMM and add it to the debt and collateral of loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param lpTokens - amount of CFMM LP tokens requested to short
    /// @param ratio - weights of collateral after borrowing liquidity
    /// @return liquidityBorrowed - liquidity amount that has been borrowed
    /// @return amounts - reserves quantities withdrawn from CFMM that correspond to the LP tokens shorted, now used as collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _borrowLiquidity(uint256 tokenId, uint256 lpTokens, uint256[] calldata ratio) external returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Library used to perform common ERC20 transactions
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library performs approvals, transfers and views ERC20 state fields
library GammaSwapLibrary {

    error ST_Fail();
    error STF_Fail();
    error SA_Fail();
    error STE_Fail();

    /// @dev Check the ERC20 balance of an address
    /// @param _token - address of ERC20 token we're checking the balance of
    /// @param _address - Ethereum address we're checking for balance of ERC20 token
    /// @return balanceOf - amount of _token held in _address
    function balanceOf(address _token, address _address) internal view returns (uint256) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeCall(IERC20.balanceOf, _address));

        require(success && data.length >= 32);

        return abi.decode(data, (uint256));
    }

    /// @dev Get how much of an ERC20 token is in existence (minted)
    /// @param _token - address of ERC20 token we're checking the total minted amount of
    /// @return totalSupply - total amount of _token that is in existence (minted and not burned)
    function totalSupply(address _token) internal view returns (uint256) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeCall(IERC20.totalSupply,()));

        require(success && data.length >= 32);

        return abi.decode(data, (uint256));
    }

    /// @dev Get decimals of ERC20 token
    /// @param _token - address of ERC20 token we are getting the decimal information from
    /// @return decimals - decimals of ERC20 token
    function decimals(address _token) internal view returns (uint8) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()")); // requesting via ERC20 decimals implementation

        require(success && data.length >= 1);

        return abi.decode(data, (uint8));
    }

    /// @dev Get symbol of ERC20 token
    /// @param _token - address of ERC20 token we are getting the symbol information from
    /// @return symbol - symbol of ERC20 token
    function symbol(address _token) internal view returns (string memory) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("symbol()")); // requesting via ERC20 symbol implementation

        require(success && data.length >= 1);

        return abi.decode(data, (string));
    }

    /// @dev Get name of ERC20 token
    /// @param _token - address of ERC20 token we are getting the name information from
    /// @return name - name of ERC20 token
    function name(address _token) internal view returns (string memory) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("name()")); // requesting via ERC20 name implementation

        require(success && data.length >= 1);

        return abi.decode(data, (string));
    }

    /// @dev Safe transfer any ERC20 token, only used internally
    /// @param _token - address of ERC20 token that will be transferred
    /// @param _to - destination address where ERC20 token will be sent to
    /// @param _amount - quantity of ERC20 token to be transferred
    function safeTransfer(address _token, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.transfer, (_to, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert ST_Fail();
    }

    /// @dev Moves `amount` of ERC20 token `_token` from `_from` to `_to` using the allowance mechanism. `_amount` is then deducted from the caller's allowance.
    /// @param _token - address of ERC20 token that will be transferred
    /// @param _from - address sending _token (not necessarily caller's address)
    /// @param _to - address receiving _token
    /// @param _amount - amount of _token being sent
    function safeTransferFrom(address _token, address _from, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.transferFrom, (_from, _to, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert STF_Fail();
    }

    /// @dev Safe approve any ERC20 token to be spent by another address (`_spender`), only used internally
    /// @param _token - address of ERC20 token that will be approved
    /// @param _spender - address that will be granted approval to spend msg.sender tokens
    /// @param _amount - quantity of ERC20 token that `_spender` will be approved to spend
    function safeApprove(address _token, address _spender, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.approve, (_spender, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert SA_Fail();
    }

    /// @dev Safe transfer any ERC20 token, only used internally
    /// @param _to - destination address where ETH will be sent to
    /// @param _amount - quantity of ERC20 token to be transferred
    function safeTransferETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");

        if(!success) revert STE_Fail();
    }

    /// @dev Check if `account` is a smart contract's address and it has been instantiated (has code)
    /// @param account - Ethereum address to check if it's a smart contract address
    /// @return bool - true if it is a smart contract address
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function convertUint128ToUint256Array(uint128[] memory arr) internal pure returns(uint256[] memory res) {
        res = new uint256[](arr.length);
        for(uint256 i = 0; i < arr.length;) {
            res[i] = uint256(arr[i]);
            unchecked {
                ++i;
            }
        }
    }

    function convertUint128ToRatio(uint128[] memory arr) internal pure returns(uint256[] memory res) {
        res = new uint256[](arr.length);
        for(uint256 i = 0; i < arr.length;) {
            res[i] = uint256(arr[i]) * 1000;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Math Library
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library for performing various math operations
library GSMath {
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // Babylonian Method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        unchecked {
            if (y > 3) {
                z = y;
                uint256 x = y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (y / x + x) / 2;
                }
            } else if (y != 0) {
                z = 1;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../interfaces/rates/IRateModel.sol";

/// @title Abstract contract to calculate the utilization rate of the GammaPool.
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice All rate models inherit this contract since all rate models depend on utilization rate
/// @dev All strategies inherit a rate model in its base and therefore all strategies inherit this contract.
abstract contract AbstractRateModel is IRateModel {
    /// @notice Calculates the utilization rate of the pool. How much borrowed out of how much liquidity is in the AMM through GammaSwap
    /// @dev The utilization rate always has 18 decimal places, even if the reserve tokens do not. Everything is adjusted to 18 decimal points
    /// @param lpInvariant - invariant amount available to be borrowed from LP tokens deposited in GammaSwap
    /// @param borrowedInvariant - invariant amount borrowed from GammaSwap
    /// @return utilizationRate - borrowedInvariant / (lpInvariant + borrowedInvairant)
    function calcUtilizationRate(uint256 lpInvariant, uint256 borrowedInvariant) internal virtual view returns(uint256) {
        uint256 totalInvariant = lpInvariant + borrowedInvariant; // total invariant belonging to liquidity depositors in GammaSwap
        if(totalInvariant == 0) // avoid division by zero
            return 0;

        return borrowedInvariant * 1e18 / totalInvariant; // utilization rate will always have 18 decimals
    }

    /// @notice Calculates the borrow rate according to an implementation formula
    /// @dev The borrow rate is expected to always have 18 decimal places
    /// @param lpInvariant - invariant amount available to be borrowed from LP tokens deposited in GammaSwap
    /// @param borrowedInvariant - invariant amount borrowed from GammaSwap
    /// @param paramsStore - address of rate params store, to get overriding parameter values
    /// @param pool - address of pool asking for rate calculation
    /// @return borrowRate - rate that will be charged to liquidity borrowers
    /// @return utilizationRate - utilization rate used to calculate the borrow rate
    /// @return maxCFMMFeeLeverage - maxLeverage number with 3 decimals. E.g. 5000 = 5
    /// @return spread - additional fee to add to cfmmFeeIndex to create spread
    function calcBorrowRate(uint256 lpInvariant, uint256 borrowedInvariant, address paramsStore, address pool) public virtual view returns(uint256, uint256, uint256, uint256);

    /// @dev See {IRateModel-rateParamsStore}
    function rateParamsStore() public override virtual view returns(address) {
        return _rateParamsStore();
    }

    /// @dev Return contract holding rate parameters
    function _rateParamsStore() internal virtual view returns(address);
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