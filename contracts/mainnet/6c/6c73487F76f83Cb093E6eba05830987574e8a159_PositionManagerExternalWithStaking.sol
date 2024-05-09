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

/// @title Interface for GammaPoolExternal
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for GammaPool implementations that have flash loan functionality
interface IGammaPoolExternal {

    /// @dev External Rebalance Strategy implementation contract for this GammaPool
    function externalRebalanceStrategy() external view returns(address);

    /// @dev External Liquidation Strategy implementation contract for this GammaPool
    function externalLiquidationStrategy() external view returns(address);

    /// @dev Flash loan pool's collateral and/or lp tokens to external address. Rebalanced loan collateral is acceptable in  repayment of flash loan
    /// @param tokenId - unique id identifying loan
    /// @param amounts - collateral amounts being flash loaned
    /// @param lpTokens - amount of CFMM LP tokens being flash loaned
    /// @param to - address that will receive flash loan swaps and potentially rebalance loan's collateral
    /// @param data - optional bytes parameter for custom user defined data
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - updated collateral token amounts backing loan
    function rebalanceExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external returns(uint256 loanLiquidity, uint128[] memory tokensHeld);

    /// @notice The entire pool's collateral is available in the flash loan. Flash loan must result in a net CFMM LP token deposit that repays loan's liquidity debt
    /// @dev Function to liquidate a loan using using a flash loan of collateral tokens from the pool and/or CFMM LP tokens. Seeks full liquidation
    /// @param tokenId - tokenId of loan being liquidated
    /// @param amounts - amount collateral tokens from the pool to flash loan
    /// @param lpTokens - amount of CFMM LP tokens being flash loaned
    /// @param to - address that will receive the collateral tokens and/or lpTokens in flash loan
    /// @param data - optional bytes parameter for custom user defined data
    /// @return loanLiquidity - loan liquidity liquidated (after write down if there's bad debt), flash loan fees added after write down
    /// @return refund - amounts from collateral tokens being refunded to liquidator
    function liquidateExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external returns(uint256 loanLiquidity, uint256[] memory refund);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for factory contract to create more GammaPool contracts.
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev All instantiated GammaPoolFactory contracts must implement this interface
interface IGammaPoolFactory {
    /// @dev Event emitted when a new GammaPool is instantiated
    /// @param pool - address of new pool that is created
    /// @param cfmm - address of CFMM the GammaPool is created for
    /// @param protocolId - id identifier of GammaPool protocol (can be thought of as version)
    /// @param implementation - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    /// @param tokens - ERC20 tokens of CFMM
    /// @param count - number of GammaPools instantiated including this contract
    event PoolCreated(address indexed pool, address indexed cfmm, uint16 indexed protocolId, address implementation, address[] tokens, uint256 count);

    /// @dev Event emitted when a GammaPool fee is updated
    /// @param pool - address of new pool whose fee is updated (zero address is default params)
    /// @param to - receiving address of protocol fees
    /// @param protocolFee - protocol fee share charged from interest rate accruals
    /// @param origFeeShare - protocol fee share charged on origination fees
    /// @param isSet - bool flag, true use fee information, false use GammaSwap default fees
    event FeeUpdate(address indexed pool, address indexed to, uint16 protocolFee, uint16 origFeeShare, bool isSet);

    /// @dev Event emitted when a GammaPool parameters are updated
    /// @param pool - address of GammaPool whose origination fee parameters will be updated
    /// @param origFee - loan opening origination fee in basis points
    /// @param extSwapFee - external swap fee in basis points, max 255 basis points = 2.55%
    /// @param emaMultiplier - multiplier used in EMA calculation of utilization rate
    /// @param minUtilRate1 - minimum utilization rate to calculate dynamic origination fee using exponential model
    /// @param minUtilRate2 - minimum utilization rate to calculate dynamic origination fee using linear model
    /// @param feeDivisor - fee divisor for calculating origination fee, based on 2^(maxUtilRate - minUtilRate1)
    /// @param liquidationFee - liquidation fee to charge during liquidations in basis points (1 - 255 => 0.01% to 2.55%)
    /// @param ltvThreshold - ltv threshold (1 - 255 => 0.1% to 25.5%)
    /// @param minBorrow - minimum liquidity amount that can be borrowed or left unpaid in a loan
    event PoolParamsUpdate(address indexed pool, uint16 origFee, uint8 extSwapFee, uint8 emaMultiplier, uint8 minUtilRate1, uint8 minUtilRate2, uint16 feeDivisor, uint8 liquidationFee, uint8 ltvThreshold, uint72 minBorrow);

    /// @dev Check if protocol is restricted. Which means only owner of GammaPoolFactory is allowed to instantiate GammaPools using this protocol
    /// @param _protocolId - id identifier of GammaPool protocol (can be thought of as version) that is being checked
    /// @return _isRestricted - true if protocol is restricted, false otherwise
    function isProtocolRestricted(uint16 _protocolId) external view returns(bool);

    /// @dev Set a protocol to be restricted or unrestricted. That means only owner of GammaPoolFactory is allowed to instantiate GammaPools using this protocol
    /// @param _protocolId - id identifier of GammaPool protocol (can be thought of as version) that is being restricted
    /// @param _isRestricted - set to true for restricted, set to false for unrestricted
    function setIsProtocolRestricted(uint16 _protocolId, bool _isRestricted) external;

    /// @notice Only owner of GammaPoolFactory can call this function
    /// @dev Add a protocol implementation to GammaPoolFactory contract. Which means GammaPoolFactory can create GammaPools with this implementation (protocol)
    /// @param _implementation - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    function addProtocol(address _implementation) external;

    /// @notice Only owner of GammaPoolFactory can call this function
    /// @dev Update protocol implementation for a protocol.
    /// @param _protocolId - id identifier of GammaPool implementation
    /// @param _newImplementation - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    function updateProtocol(uint16 _protocolId, address _newImplementation) external;

    /// @notice Only owner of GammaPoolFactory can call this function
    /// @dev Locks protocol implementation for upgradable protocols (<10000) so GammaPoolFactory can no longer update the implementation contract for this upgradable protocol
    /// @param _protocolId - id identifier of GammaPool implementation
    function lockProtocol(uint16 _protocolId) external;

    /// @dev Get implementation address that maps to protocolId. This is the actual implementation code that a GammaPool implements for a protocolId
    /// @param _protocolId - id identifier of GammaPool implementation (can be thought of as version)
    /// @return _address - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    function getProtocol(uint16 _protocolId) external view returns (address);

    /// @dev Get beacon address that maps to protocolId. This beacon contract contains the implementation address of the GammaPool proxy
    /// @param _protocolId - id identifier of GammaPool implementation (can be thought of as version)
    /// @return _address - address of beacon of GammaPool proxy contract. Because all GammaPools are created as proxy contracts if there is one
    function getProtocolBeacon(uint16 _protocolId) external view returns (address);

    /// @dev Instantiate a new GammaPool for a CFMM based on an existing implementation (protocolId)
    /// @param _protocolId - id identifier of GammaPool protocol (can be thought of as version)
    /// @param _cfmm - address of CFMM the GammaPool is created for
    /// @param _tokens - addresses of ERC20 tokens in CFMM, used for validation during runtime of function
    /// @param _data - custom struct containing additional information used to verify the `_cfmm`
    /// @return _address - address of new GammaPool proxy contract that was instantiated
    function createPool(uint16 _protocolId, address _cfmm, address[] calldata _tokens, bytes calldata _data) external returns(address);

    /// @dev Mapping of bytes32 salts (key) to GammaPool addresses. The salt is predetermined and used to instantiate a GammaPool with a unique address
    /// @param _salt - the bytes32 key that is unique to the GammaPool and therefore also used as a unique identifier of the GammaPool
    /// @return _address - address of GammaPool that maps to bytes32 salt (key)
    function getPool(bytes32 _salt) external view returns(address);

    /// @dev Mapping of bytes32 salts (key) to GammaPool addresses. The salt is predetermined and used to instantiate a GammaPool with a unique address
    /// @param _pool - address of GammaPool that maps to bytes32 salt (key)
    /// @return _salt - the bytes32 key that is unique to the GammaPool and therefore also used as a unique identifier of the GammaPool
    function getKey(address _pool) external view returns(bytes32);

    /// @return count - number of GammaPools that have been instantiated through this GammaPoolFactory contract
    function allPoolsLength() external view returns (uint256);

    /// @dev Get pool fee parameters used to calculate protocol fees
    /// @param _pool - pool address identifier
    /// @return _to - address receiving fee
    /// @return _protocolFee - protocol fee share charged from interest rate accruals
    /// @return _origFeeShare - protocol fee share charged on origination fees
    /// @return _isSet - bool flag, true use fee information, false use GammaSwap default fees
    function getPoolFee(address _pool) external view returns (address _to, uint256 _protocolFee, uint256 _origFeeShare, bool _isSet);

    /// @dev Set pool fee parameters used to calculate protocol fees
    /// @param _pool - id identifier of GammaPool protocol (can be thought of as version)
    /// @param _to - address receiving fee
    /// @param _protocolFee - protocol fee share charged from interest rate accruals
    /// @param _origFeeShare - protocol fee share charged on origination fees
    /// @param _isSet - bool flag, true use fee information, false use GammaSwap default fees
    function setPoolFee(address _pool, address _to, uint16 _protocolFee, uint16 _origFeeShare, bool _isSet) external;

    /// @dev Call admin function in GammaPool contract
    /// @param _pool - address of GammaPool whose admin function will be called
    /// @param _data - custom struct containing information to execute in pool contract
    function execute(address _pool, bytes calldata _data) external;

    /// @dev Pause a GammaPool's function identified by a `_functionId`
    /// @param _pool - address of GammaPool whose functions we will pause
    /// @param _functionId - id of function in GammaPool we want to pause
    /// @return _functionIds - uint256 number containing all turned on (paused) function ids
    function pausePoolFunction(address _pool, uint8 _functionId) external returns(uint256 _functionIds) ;

    /// @dev Unpause a GammaPool's function identified by a `_functionId`
    /// @param _pool - address of GammaPool whose functions we will unpause
    /// @param _functionId - id of function in GammaPool we want to unpause
    /// @return _functionIds - uint256 number containing all turned on (paused) function ids
    function unpausePoolFunction(address _pool, uint8 _functionId) external returns(uint256 _functionIds) ;

    /// @return fee - protocol fee charged by GammaPool to liquidity borrowers in terms of basis points
    function fee() external view returns(uint16);

    /// @return origFeeShare - protocol fee share charged on origination fees
    function origFeeShare() external view returns(uint16);

    /// @return feeTo - address that receives protocol fees
    function feeTo() external view returns(address);

    /// @return feeToSetter - address that has the power to set protocol fees
    function feeToSetter() external view returns(address);

    /// @return feeTo - address that receives protocol fees
    /// @return fee - protocol fee charged by GammaPool to liquidity borrowers in terms of basis points
    /// @return origFeeShare - protocol fee share charged on origination fees
    function feeInfo() external view returns(address,uint256,uint256);

    /// @dev Get list of pools from start index to end index. If it goes over index it returns up to the max size of allPools array
    /// @param start - start index of pools to search
    /// @param end - end index of pools to search
    /// @return _pools - all pools requested
    function getPools(uint256 start, uint256 end) external view returns(address[] memory _pools);

    /// @dev See {IGammaPoolFactory-setFee}
    function setFee(uint16 _fee) external;

    /// @dev See {IGammaPoolFactory-setFeeTo}
    function setFeeTo(address _feeTo) external;

    /// @dev See {IGammaPoolFactory-setOrigFeeShare}
    function setOrigFeeShare(uint16 _origFeeShare) external;

    /// @dev See {IGammaPoolFactory-setFeeToSetter}
    function setFeeToSetter(address _feeToSetter) external;

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

/// @title Interface for Refunds abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used to clear tokens from a contract
interface IRefunds {
    /// @dev Withdraw ERC20 tokens from contract
    /// @param token - address of ERC20 token that will be withdrawn
    /// @param to - destination address where withdrawn quantity will be sent to
    /// @param minAmt - threshold balance before token can be withdrawn
    function clearToken(address token, address to, uint256 minAmt) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title ISendTokensCallback interface to handle callbacks to send tokens
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Used by periphery contracts to transfer token amounts requested by a GammaPool
/// @dev Verifies sender is GammaPool by hashing SendTokensCallbackData contents into msg.sender
interface ISendTokensCallback {

    /// @dev Struct received in sendTokensCallback (`data`) used to identify caller as GammaPool
    struct SendTokensCallbackData {
        /// @dev sender of tokens
        address payer;

        /// @dev address of CFMM that will be used to identify GammaPool
        address cfmm;

        /// @dev protocolId that will be used to identify GammaPool
        uint16 protocolId;
    }

    /// @dev Transfer token `amounts` after verifying identity of caller using `data` is a GammaPool
    /// @param tokens - address of ERC20 tokens that will be transferred
    /// @param amounts - token amounts to be transferred
    /// @param payee - receiver of token `amounts`
    /// @param data - struct used to verify the function caller
    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external;
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

import "../interfaces/IGammaPoolFactory.sol";

/// @title Library used calculate the deterministic addresses used to instantiate GammaPools
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev These algorithms are based on EIP-1014 (https://eips.ethereum.org/EIPS/eip-1014)
library AddressCalculator {

    /// @dev calculate salt used to create deterministic address, the salt is also used as unique key identifier for the GammaPool
    /// @param cfmm - address of CFMM the GammaPool is for
    /// @param protocolId - protocol id of instance address the GammaPool will use (version of GammaPool for this CFMM)
    /// @return key - key/salt used as unique identifier of GammaPool
    function getGammaPoolKey(address cfmm, uint16 protocolId) internal pure returns(bytes32) {
        return keccak256(abi.encode(cfmm, protocolId)); // key is hash of CFMM address and protocolId
    }

    /// @dev calculate deterministic address to instantiate GammaPool minimal beacon proxy or minimal proxy contract
    /// @param factory - address of factory that will instantiate GammaPool proxy contract
    /// @param protocolId - protocol id of instance address the GammaPool will use (version of this GammaPool)
    /// @param key - salt used in address generation to assure its uniqueness
    /// @return _address - address of GammaPool that maps to protocolId and key
    function calcAddress(address factory, uint16 protocolId, bytes32 key) internal view returns (address) {
        if (protocolId < 10000) {
            return predictDeterministicAddress(IGammaPoolFactory(factory).getProtocolBeacon(protocolId), protocolId, key, factory);
        } else {
            return predictDeterministicAddress2(IGammaPoolFactory(factory).getProtocol(protocolId), key, factory);
        }
    }

    /// @dev calculate a deterministic address based on init code hash
    /// @param factory - address of factory that instantiated or will instantiate this contract
    /// @param salt - salt used in address generation to assure its uniqueness
    /// @param initCodeHash - init code hash of template contract which will be used to instantiate contract with deterministic address
    /// @return _address - address of contract that maps to salt and init code hash that is created by factory contract
    function calcAddress(address factory, bytes32 salt, bytes32 initCodeHash) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(hex"ff",factory,salt,initCodeHash)))));
    }

    /// @dev Compute bytecode of a minimal beacon proxy contract, excluding bytecode metadata hash
    /// @param beacon - address of beacon of minimal beacon proxy
    /// @param protocolId - id of protocol
    /// @param factory - address of factory that instantiated or will instantiate this contract
    /// @return bytecode - the calculated bytecode for minimal beacon proxy contract
    function calcMinimalBeaconProxyBytecode(
        address beacon,
        uint16 protocolId,
        address factory
    ) internal pure returns(bytes memory) {
        return abi.encodePacked(
            hex"608060405234801561001057600080fd5b5073",
            beacon,
            hex"7f",
            hex"a3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50",
            hex"5560",
            protocolId < 256 ? hex"6c" : hex"6d",
            hex"806100566000396000f3fe",
            hex"608060408190526334b1f0a960e21b8152",
            protocolId < 256 ? hex"60" : hex"61",
            protocolId < 256 ? abi.encodePacked(uint8(protocolId)) : abi.encodePacked(protocolId),
            hex"60845260208160248173",
            factory,
            hex"5afa60",
            protocolId < 256 ? hex"3a" : hex"3b",
            hex"573d6000fd5b5060805160003681823780813683855af491503d81823e81801560",
            protocolId < 256 ? hex"5b" : hex"5c",
            hex"573d82f35b3d82fdfea164736f6c6343000815000a"
        );
    }

    /// @dev Computes the address of a minimal beacon proxy contract
    /// @param protocolId - id of protocol
    /// @param salt - salt used in address generation to assure its uniqueness
    /// @param factory - address of factory that instantiated or will instantiate this contract
    /// @return predicted - the calculated address
    function predictDeterministicAddress(
        address beacon,
        uint16 protocolId,
        bytes32 salt,
        address factory
    ) internal pure returns (address) {
        bytes memory bytecode = calcMinimalBeaconProxyBytecode(beacon, protocolId, factory);

        // Compute the hash of the initialization code.
        bytes32 bytecodeHash = keccak256(bytecode);

        // Compute the final CREATE2 address
        bytes32 data = keccak256(abi.encodePacked(bytes1(0xff), factory, salt, bytecodeHash));
        return address(uint160(uint256(data)));
    }

    /// @dev Computes the address of a minimal proxy contract
    /// @param implementation - address of implementation contract of this minimal proxy contract
    /// @param salt - salt used in address generation to assure its uniqueness
    /// @param factory - address of factory that instantiated or will instantiate this contract
    /// @return predicted - the calculated address
    function predictDeterministicAddress2(
        address implementation,
        bytes32 salt,
        address factory
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), factory)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }
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

/// @title Two Step Ownership Contract implementation
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Transfers ownership of contract to another address using a two step method
contract TwoStepOwnable {
    /// @dev Event emitted when ownership of GammaPoolFactory contract is transferred to a new address
    /// @param previousOwner - previous address that owned factory contract
    /// @param newOwner - new address that owns factory contract
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Event emitted when change of ownership of GammaPoolFactory contract is started
    /// @param currentOwner - current address that owns factory contract
    /// @param newOwner - new address that will own factory contract
    event OwnershipTransferStarted(address indexed currentOwner, address indexed newOwner);

    /// @dev Owner of contract
    address public owner;

    /// @dev Pending owner to implement transfer of ownership in two steps
    address public pendingOwner;

    /// @dev Initialize `owner` of smart contract
    constructor(address _owner) {
        owner = _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        require(owner == msg.sender, "Forbidden");
    }

    /// @dev Starts ownership transfer to new account. Replaces the pending transfer if there is one. Can only be called by the current owner.
    /// @param newOwner - new address that will have the owner privileges over the factory contract
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "ZeroAddress");// not allow to transfer ownership to zero address (renounce ownership forever)
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice The new owner accepts the ownership transfer.
    /// @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
    function acceptOwnership() external virtual {
        address newOwner = msg.sender;
        require(pendingOwner == newOwner, "NotNewOwner");
        address oldOwner = owner;
        owner = newOwner;
        delete pendingOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract GammaPoolERC721 is Context, ERC165, IERC721, IERC721Metadata  {

    using Address for address;
    using Strings for uint256;

    error ERC721Forbidden();
    error ERC721ApproveOwner();
    error ERC721ZeroAddress();
    error ERC721InvalidTokenID();
    error ERC721TransferToNonReceiver();
    error ERC721MintToZeroAddress();
    error ERC721TokenExists();
    error ERC721TransferFromWrongOwner();
    error ERC721TransferToZeroAddress();
    error ERC721ApproveToCaller();

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Revert ERC721 transaction if msg.sender is not authorized perform ERC721 transaction
     */
    function isForbidden(uint256 tokenId) internal virtual view {
        if(!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert ERC721Forbidden();
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        isForbidden(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        isForbidden(tokenId);

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = GammaPoolERC721.ownerOf(tokenId);

        if(to == owner) {
            revert ERC721ApproveOwner();
        }

        if(_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ERC721Forbidden();
        }

        _approve(to, tokenId);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if(owner == address(0)) {
            revert ERC721ZeroAddress();
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if(owner == address(0)) {
            revert ERC721InvalidTokenID();
        }
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if(!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ERC721TransferToNonReceiver();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = GammaPoolERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if(!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert ERC721TransferToNonReceiver();
        }
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if(to == address(0)) {
            revert ERC721MintToZeroAddress();
        }
        if(_exists(tokenId)) {
            revert ERC721TokenExists();
        }

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = GammaPoolERC721.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if(GammaPoolERC721.ownerOf(tokenId) != from) {
            revert ERC721TransferFromWrongOwner();
        }
        if(to == address(0)) {
            revert ERC721TransferToZeroAddress();
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(GammaPoolERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if(owner == operator) {
            revert ERC721ApproveToCaller();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if(!_exists(tokenId)) {
            revert ERC721InvalidTokenID();
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    //revert("ERC721: transfer to non ERC721Receiver implementer");
                    revert ERC721TransferToNonReceiver();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "../interfaces/ILoanStore.sol";
import "./GammaPoolERC721.sol";

/// @title GammaPoolQueryableLoans
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Makes ERC721 loans queryable by PositionManager
abstract contract GammaPoolQueryableLoans is GammaPoolERC721 {

    /// @dev Database where it will store loan information. dataStore has to know this address though to accept messages
    address public dataStore;

    /// @dev Mint tokenId of loan as ERC721 NFT and store in mappings so that it can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function mintQueryableLoan(address pool, uint256 tokenId, address owner) internal virtual {
        _safeMint(owner, tokenId);
        if(dataStore != address(0)) {
            ILoanStore(dataStore).addLoanToOwner(pool, tokenId, owner);
        }
    }

    /// @dev See {GammaPoolERC721-_transfer}.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);
        if(dataStore != address(0)) {
            ILoanStore(dataStore).transferLoan(from, to, tokenId);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@gammaswap/v1-core/contracts/libraries/GammaSwapLibrary.sol";
import "../interfaces/ITransfers.sol";
import "../interfaces/external/IWETH.sol";

/// @title Transfers abstract contract implementation of ITransfers
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Clears tokens and Ether from PositionManager and simplifies token transfer functions
/// @dev PositionManager is not supposed to hold any tokens or Ether
abstract contract Transfers is ITransfers {

    error NotWETH();
    error NotEnoughWETH();
    error NotEnoughTokens();
    error NotGammaPool();

    /// @dev See {ITransfers-WETH}
    address public immutable override WETH;

    /// @dev Initialize the contract by setting `WETH`
    constructor(address _WETH) {
        WETH = _WETH;
    }

    /// @dev Do not accept any Ether unless it comes from Wrapped Ether (WETH) contract
    receive() external payable {
        if(msg.sender != WETH) {
          revert NotWETH();
        }
    }

    /// @dev See {ITransfers-unwrapWETH}
    function unwrapWETH(uint256 minAmt, address to) public payable override {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));
        if(wethBal < minAmt) {
            revert NotEnoughWETH();
        }

        if (wethBal > 0) {
            IWETH(WETH).withdraw(wethBal);
            GammaSwapLibrary.safeTransferETH(to, wethBal);
        }
    }

    /// @dev See {ITransfers-refundETH}
    function refundETH() external payable override {
        if (address(this).balance > 0) GammaSwapLibrary.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @dev See {ITransfers-clearToken}
    function clearToken(address token, address to, uint256 minAmt) public virtual override {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if(tokenBal < minAmt) {
            revert NotEnoughTokens();
        }

        if (tokenBal > 0) GammaSwapLibrary.safeTransfer(token, to, tokenBal);
    }

    /// @dev Used to abstract token transfer functions into one function call
    /// @param token - ERC20 token to transfer
    /// @param sender - address sending the token
    /// @param to - recipient of token `amount` from sender
    /// @param amount - quantity of `token` that will be sent to recipient `to`
    function send(address token, address sender, address to, uint256 amount) internal {
        if (token == WETH && address(this).balance >= amount) {
            IWETH(WETH).deposit{value: amount}(); // wrap only what is needed
            GammaSwapLibrary.safeTransfer(WETH, to, amount);
        } else if (sender == address(this)) {
            // send with tokens already in the contract
            GammaSwapLibrary.safeTransfer(token, to, amount);
        } else {
            // pull transfer
            GammaSwapLibrary.safeTransferFrom(token, sender, to, amount);
        }
    }

    /// @dev Used to transfer multiple tokens in one function call
    /// @param tokens - ERC20 tokens to transfer
    /// @param sender - address sending the token
    /// @param to - recipient of token `amount` from sender
    /// @param amounts - quantity of `token` that will be sent to recipient `to`
    function sendTokens(address[] memory tokens, address sender, address to, uint256[] calldata amounts) internal {
        uint256 len = tokens.length;
        for (uint256 i; i < len;) {
            if (amounts[i] > 0 ) send(tokens[i], sender, to, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Retrieves GammaPool address using cfmm address and protocolId
    /// @param cfmm - address of CFMM of GammaPool whose address we want to calculate
    /// @param protocolId - identifier of GammaPool implementation for the `cfmm`
    /// @return pool - address of GammaPool
    function getGammaPoolAddress(address cfmm, uint16 protocolId) internal virtual view returns(address);

    /// @dev See {ISendTokensCallback-sendTokensCallback}.
    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external virtual override {
        SendTokensCallbackData memory decoded = abi.decode(data, (SendTokensCallbackData));

        // Revert if msg.sender is not GammaPool for CFMM and protocolId
        if(msg.sender != getGammaPoolAddress(decoded.cfmm, decoded.protocolId)) {
            revert NotGammaPool();
        }

        // Transfer tokens from decoded.payer to payee
        sendTokens(tokens, decoded.payer, payee, amounts);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Wrapped Ether interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Used to interact with Wrapped Ether contract
/// @dev Only defines functions we
interface IWETH is IERC20 {
    /// @dev Emitted when Ether is deposited into Wrapped Ether contract to issue Wrapped Ether
    /// @param to - receiver of wrapped ether
    /// @param amount - amount of wrapped ether issued to receiver
    event Deposit(address indexed to, uint amount);

    /// @dev Emitted when Ether is withdrawn from Wrapped Ether contract by burning Wrapped Ether
    /// @param from - receiver of ether
    /// @param amount - amount of ether sent to `from`
    event Withdrawal(address indexed from, uint amount);

    /// @dev Deposit ether to issue Wrapped Ether
    function deposit() external payable;

    /// @dev Withdraw ether by burning Wrapped Ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./IPositionManager.sol";

/// @title Interface for extending PositionManager with auto stake/unstake capability
/// @author Simon Mall
/// @dev This should be used along with IPositionManager to define a contract
interface IAutoStakable {
  /// @dev error to emit when trying to use staking router and router is not set
  error StakingRouterNotSet();

  /// @dev Set staking router contract address
  /// @dev Requires admin permission
  /// @param _stakingRouter Staking Router contract address
  function setStakingRouter(address _stakingRouter) external;

  /// @dev Deposit reserve tokens into a GammaPool and stake GS LP tokens
  /// @dev See more {IPositionManager-depositReserves}
  /// @param params - struct containing parameters to identify a GammaPool to deposit reserve tokens to
  /// @param esToken - address of escrow token of staking contract
  /// @return reserves - reserve tokens deposited into GammaPool
  /// @return shares - GS LP token shares minted for depositing
  function depositReservesAndStake(IPositionManager.DepositReservesParams calldata params, address esToken) external returns(uint256[] memory reserves, uint256 shares);

  /// @dev Unstake GS LP tokens from staking router and withdraw reserve tokens from a GammaPool
  /// @dev See more {IPositionManager-withdrawReserves}
  /// @param params - struct containing parameters to identify a GammaPool to withdraw reserve tokens from
  /// @param esToken - address of escrow token of staking contract
  /// @return reserves - reserve tokens withdrawn from GammaPool
  /// @return assets - CFMM LP token shares equivalent of reserves withdrawn from GammaPool
  function withdrawReservesAndUnstake(IPositionManager.WithdrawReservesParams calldata params, address esToken) external returns (uint256[] memory reserves, uint256 assets);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Interface for Loan Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface to interact with contract that stores all loans on chain, if enabled in PositionManager
interface ILoanStore {

    /// @dev Struct to store identifiable information about loan to perform queries in PositionManager
    struct LoanInfo {
        /// @dev Address of pool loan belongs to
        address pool;
        /// @dev Add loan to mappings by user
        uint256 byOwnerAndPoolIdx;
        /// @dev Add loan to mappings by user
        uint256 byOwnerIdx;
    }

    /// @dev Add loan to mappings by user so that they can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function addLoanToOwner(address pool, uint256 tokenId, address owner) external;

    /// @dev Transfer loan identified by `tokenId` from address `from` to another address `to`
    /// @param from - address transferring loan
    /// @param to - address receiving loan
    /// @param tokenId - unique identifier of loan
    function transferLoan(address from, address to, uint256 tokenId) external;

    /// @param _source - address supplying loan information
    function setSource(address _source) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolEvents.sol";
import "./ITransfers.sol";

/// @title Interface for PositionManager
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Defines external functions and events emitted by PositionManager
/// @dev Interface also defines all GammaPool events through inheritance of IGammaPoolEvents
interface IPositionManager is IGammaPoolEvents, ITransfers {
    /// @dev Emitted when depositing CFMM LP tokens as liquidity in a pool
    /// @param pool - address of pool minting GS LP tokens
    /// @param shares - minted quantity of pool's GS LP tokens
    event DepositNoPull(address indexed pool, uint256 shares);

    /// @dev Emitted when withdrawing CFMM LP tokens previously provided as liquidity from a pool
    /// @param pool - address of pool redeeming GS LP tokens for CFMM LP tokens
    /// @param assets - quantity of CFMM LP tokens withdrawn from pool
    event WithdrawNoPull(address indexed pool, uint256 assets);

    /// @dev Emitted when depositing reserve tokens as liquidity in a pool
    /// @param pool - address of pool redeeming GS LP tokens for CFMM LP tokens
    /// @param reserves - quantity of reserve tokens deposited in pool
    /// @param shares - minted quantity of pool's GS LP tokens representing the reserves deposit
    event DepositReserve(address indexed pool, uint256[] reserves, uint256 shares);

    /// @dev Emitted when withdrawing reserve tokens previously provided as liquidity from a pool
    /// @param pool - address of pool redeeming GS LP tokens for CFMM LP tokens
    /// @param reserves - quantity of reserve tokens withdrawn from pool
    /// @param assets - reserve tokens withdrawn from pool in terms of CFMM LP tokens
    event WithdrawReserve(address indexed pool, uint256[] reserves, uint256 assets);

    /// @dev Emitted when new loan in a pool is created. PositionManager owns new loan, owner owns new NFT that manages loan
    /// @param pool - address of pool where loan will be created
    /// @param owner - address of owner of newly minted NFT that manages newly created loan
    /// @param tokenId - unique id that identifies new loan in GammaPool
    /// @param refId - Reference id of post transaction activities attached to this loan
    event CreateLoan(address indexed pool, address indexed owner, uint256 tokenId, uint16 refId);

    /// @dev Emitted when increasing a loan's collateral amounts
    /// @param pool - address of pool collateral amounts are deposited to
    /// @param tokenId - id identifying loan in pool
    /// @param tokensHeld - new loan collateral amounts
    /// @param amounts - collateral amounts being deposited
    event IncreaseCollateral(address indexed pool, uint256 tokenId, uint128[] tokensHeld, uint256[] amounts);

    /// @dev Emitted when decreasing a loan's collateral amounts
    /// @param pool - address of pool collateral amounts are withdrawn from
    /// @param tokenId - id identifying loan in pool
    /// @param tokensHeld - new loan collateral amounts
    /// @param amounts - amounts of reserve tokens withdraws from loan
    event DecreaseCollateral(address indexed pool, uint256 tokenId, uint128[] tokensHeld, uint128[] amounts);

    /// @dev Emitted when re-balancing a loan's collateral amounts (swapping one collateral token for another)
    /// @param pool - loan's pool address
    /// @param tokenId - id identifying loan in pool
    /// @param tokensHeld - new loan collateral amounts
    event RebalanceCollateral(address indexed pool, uint256 tokenId, uint128[] tokensHeld);

    /// @dev Emitted when borrowing liquidity from a pool
    /// @param pool - address of pool whose liquidity was borrowed
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityBorrowed - liquidity borrowed in invariant terms
    /// @param amounts - liquidity borrowed in terms of reserve token amounts
    event BorrowLiquidity(address indexed pool, uint256 tokenId, uint256 liquidityBorrowed, uint256[] amounts);

    /// @dev Emitted when repaying liquidity debt from a pool
    /// @param pool - address of pool whose liquidity debt was paid
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityPaid - liquidity repaid in invariant terms
    /// @param amounts - liquidity repaid in terms of reserve token amounts
    event RepayLiquidity(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint256[] amounts);

    /// @dev Emitted when repaying liquidity debt from a pool
    /// @param pool - address of pool whose liquidity debt was paid
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityPaid - liquidity repaid in invariant terms
    /// @param amounts - liquidity repaid in terms of reserve token amounts
    event RepayLiquiditySetRatio(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint256[] amounts);

    /// @dev Emitted when repaying liquidity debt from a pool
    /// @param pool - address of pool whose liquidity debt was paid
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityPaid - liquidity repaid in invariant terms
    /// @param tokensHeld - new loan collateral amounts
    /// @param lpTokens - CFMM LP tokens used to repay liquidity debt
    event RepayLiquidityWithLP(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint128[] tokensHeld, uint256 lpTokens);

    event LoanUpdate(uint256 indexed tokenId, address indexed poolId, address indexed owner, uint128[] tokensHeld,
        uint256 liquidity, uint256 lpTokens, uint256 initLiquidity, uint128[] cfmmReserves);

    /// @dev Struct parameters for `depositNoPull` and `withdrawNoPull` functions. Depositing/Withdrawing CFMM LP tokens
    struct DepositWithdrawParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of GS LP tokens when depositing or of CFMM LP tokens when withdrawing
        address to;
        /// @dev CFMM LP tokens requesting to deposit or withdraw
        uint256 lpTokens;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
    }

    /// @dev Struct parameters for `depositReserves` function. Depositing reserve tokens
    struct DepositReservesParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of GS LP tokens when depositing
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens caller desires to deposit
        uint256[] amountsDesired;
        /// @dev minimum amounts of reserve tokens expected to have been deposited. Slippage protection
        uint256[] amountsMin;
    }

    /// @dev Struct parameters for `withdrawReserves` function. Withdrawing reserve tokens
    struct WithdrawReservesParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing
        address to;
        /// @dev amount of GS LP tokens that will be burned in the withdrawal
        uint256 amount;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn. Slippage protection
        uint256[] amountsMin;
    }

    /// @dev Struct parameters for `borrowLiquidity` function. Borrowing liquidity
    struct BorrowLiquidityParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan to which liquidity borrowed will be credited to
        uint256 tokenId;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens`. Slippage protection
        uint256[] minBorrowed;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `repayLiquidity` function. Repaying liquidity
    struct RepayLiquidityParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose liquidity debt will be paid
        uint256 tokenId;
        /// @dev liquidity debt to pay
        uint256 liquidity;
        /// @dev if true re-balance collateral to `ratio`
        bool isRatio;
        /// @dev If re-balancing to a desired ratio set this to the ratio you'd like, otherwise leave as an empty array
        uint256[] ratio;
        /// @dev collateralId - index of collateral token + 1
        uint256 collateralId;
        /// @dev to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint256[] minRepaid;
    }

    /// @dev Struct parameters for `repayLiquidityWithLP` function. Repaying liquidity with CFMM LP tokens
    struct RepayLiquidityWithLPParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose liquidity debt will be paid
        uint256 tokenId;
        /// @dev if using LP tokens to repay liquidity set this to > 0
        uint256 lpTokens;
        /// @dev collateralId - index of collateral token + 1
        uint256 collateralId;
        /// @dev to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `increaseCollateral` and `decreaseCollateral` function.
    struct AddCollateralParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint256[] amounts;
        /// @dev ratio - ratio of loan collateral to be maintained after increasing collateral
        uint256[] ratio;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `increaseCollateral` and `decreaseCollateral` function.
    struct RemoveCollateralParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint128[] amounts;
        /// @dev ratio - ratio of loan collateral to be maintained after decreasing collateral
        uint256[] ratio;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `rebalanceCollateral` function.
    struct RebalanceCollateralParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        int256[] deltas;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `borrowAndRebalance` function.
    struct CreateLoanBorrowAndRebalanceParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev owner of NFT created by PositionManager. Owns loan through PositionManager
        address to;
        /// @dev reference id of loan observer to track loan
        uint16 refId;
        /// @dev amounts of requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint256[] amounts;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens`. Slippage protection
        uint256[] minBorrowed;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
    }

    /// @dev Struct parameters for `createLoanBorrowAndRebalance` function.
    struct BorrowAndRebalanceParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan
        uint256[] amounts;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev amounts of reserve tokens requesting to withdraw from a loan's collateral
        uint128[] withdraw;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens` (borrowing). Slippage protection
        uint256[] minBorrowed;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        uint128[] minCollateral;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
    }

    /// @return factory - factory contract that creates all GammaPools this PositionManager interacts with
    function factory() external view returns (address);

    // Short Gamma

    /// @dev Deposit CFMM LP tokens into a GammaPool and receive GS LP tokens
    /// @param params - struct containing parameters to identify a GammaPool to deposit CFMM LP tokens for GS LP tokens
    /// @return shares - GS LP token shares minted for depositing
    function depositNoPull(DepositWithdrawParams calldata params) external returns(uint256 shares);

    /// @dev Redeem GS LP tokens for CFMM LP tokens
    /// @param params - struct containing parameters to identify a GammaPool to redeem GS LP tokens for CFMM LP tokens
    /// @return assets - CFMM LP tokens received for GS LP tokens
    function withdrawNoPull(DepositWithdrawParams calldata params) external returns(uint256 assets);

    /// @dev Deposit reserve tokens into a GammaPool to receive GS LP tokens
    /// @param params - struct containing parameters to identify a GammaPool to deposit reserve tokens to
    /// @return reserves - reserve tokens deposited into GammaPool
    /// @return shares - GS LP token shares minted for depositing
    function depositReserves(DepositReservesParams calldata params) external returns (uint256[] memory reserves, uint256 shares);

    /// @dev Withdraw reserve tokens from a GammaPool
    /// @param params - struct containing parameters to identify a GammaPool to withdraw reserve tokens from
    /// @return reserves - reserve tokens withdrawn from GammaPool
    /// @return assets - CFMM LP token shares equivalent of reserves withdrawn from GammaPool
    function withdrawReserves(WithdrawReservesParams calldata params) external returns (uint256[] memory reserves, uint256 assets);

    // Long Gamma

    /// @notice Create a loan in GammaPool and turn it into an NFT issued to address `to`
    /// @dev Loans created here are actually owned by PositionManager and wrapped as an NFT issued to address `to`. But whoever holds NFT controls loan
    /// @param protocolId - protocolId (version) of GammaPool where loan will be created (used with `cfmm` to calculate GammaPool address)
    /// @param cfmm - address of CFMM, GammaPool is for (used with `protocolId` to calculate GammaPool address)
    /// @param to - recipient of NFT token that will be created
    /// @param refId - reference Id of loan observer to track loan lifecycle
    /// @param deadline - timestamp after which transaction expires. Can't be executed anymore. Removes stale transactions
    /// @return tokenId - tokenId of newly created loan
    function createLoan(uint16 protocolId, address cfmm, address to, uint16 refId, uint256 deadline) external returns(uint256 tokenId);

    /// @dev Borrow liquidity from GammaPool, can be used with a newly created loan or a loan already holding some liquidity debt
    /// @param params - struct containing params to identify a GammaPool and borrow liquidity from it
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    /// @return tokensHeld - new loan collateral token amounts
    function borrowLiquidity(BorrowLiquidityParams calldata params) external returns (uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld);

    /// @dev Repay liquidity debt from GammaPool
    /// @param params - struct containing params to identify a GammaPool and loan to pay its liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function repayLiquidity(RepayLiquidityParams calldata params) external returns (uint256 liquidityPaid, uint256[] memory amounts);

    /// @dev Repay liquidity debt from GammaPool using CFMM LP tokens
    /// @param params - struct containing params to identify a GammaPool and loan to pay its liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return tokensHeld - reserve tokens used to pay liquidity debt
    function repayLiquidityWithLP(RepayLiquidityWithLPParams calldata params) external returns (uint256 liquidityPaid, uint128[] memory tokensHeld);

    /// @dev Increase loan collateral by depositing more reserve tokens
    /// @param params - struct containing params to identify a GammaPool and loan to add collateral to
    /// @return tokensHeld - new loan collateral token amounts
    function increaseCollateral(AddCollateralParams calldata params) external returns(uint128[] memory tokensHeld);

    /// @dev Decrease loan collateral by withdrawing reserve tokens
    /// @param params - struct containing params to identify a GammaPool and loan to remove collateral from
    /// @return tokensHeld - new loan collateral token amounts
    function decreaseCollateral(RemoveCollateralParams calldata params) external returns(uint128[] memory tokensHeld);

    /// @dev Re-balance loan collateral tokens by swapping one for another
    /// @param params - struct containing params to identify a GammaPool and loan to re-balance its collateral
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external returns(uint128[] memory tokensHeld);

    /// @notice Aggregate create loan, increase collateral, borrow collateral, and re-balance collateral into one transaction
    /// @dev Only create loan must be performed, the other transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokenId - tokenId of newly created loan
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams calldata params) external returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);

    /// @notice Aggregate increase collateral, borrow collateral, re-balance collateral, and decrease collateral into one transaction
    /// @dev All transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function borrowAndRebalance(BorrowAndRebalanceParams calldata params) external returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPositionManager.sol";

/// @title Interface for PositionManagerExternal
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Defines external functions and events emitted by PositionManagerExternal
/// @dev Interface also defines all GammaPool events through inheritance of IGammaPool and IGammaPoolEvents
interface IPositionManagerExternal is IPositionManager {

    /// @dev Emitted when re-balancing a loan's collateral amounts (swapping one collateral token for another) using an external contract
    /// @param pool - loan's pool address
    /// @param tokenId - id identifying loan in pool
    /// @param loanLiquidity - liquidity borrowed in invariant terms
    /// @param tokensHeld - new loan collateral amounts
    event RebalanceCollateralExternally(address indexed pool, uint256 tokenId, uint256 loanLiquidity, uint128[] tokensHeld);

    /// @dev Struct parameters for `rebalanceCollateralExternally` function.
    struct RebalanceCollateralExternallyParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev amounts of reserve tokens to send to the rebalancer contract
        uint128[] amounts;
        /// @dev CFMM LP tokens requesting to borrow during external rebalancing. Must be returned at function call end
        uint256 lpTokens;
        /// @dev address of contract that will rebalance collateral. This address must return collateral back to GammaPool
        address rebalancer;
        /// @dev data - optional bytes parameter to pass data to the rebalancer contract with rebalancing instructions
        bytes data;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `createLoanBorrowAndRebalanceExternally` function.
    struct CreateLoanBorrowAndRebalanceExternallyParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev owner of NFT created by PositionManager. Owns loan through PositionManager
        address to;
        /// @dev reference id of loan observer to track loan
        uint16 refId;
        /// @dev amounts of requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint256[] amounts;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev address of contract that will rebalance collateral. This address must return collateral back to GammaPool
        address rebalancer;
        /// @dev data - optional bytes parameter to pass data to the rebalancer contract with rebalancing instructions
        bytes data;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens`. Slippage protection
        uint256[] minBorrowed;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
    }

    /// @dev Struct parameters for `rebalanceExternallyAndRepayLiquidity` function.
    struct RebalanceExternallyAndRepayLiquidityParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose liquidity debt will be paid
        uint256 tokenId;
        /// @dev liquidity debt to pay
        uint256 liquidity;
        /// @dev amounts to send to rebalancer contract to rebalance for liquidity repayment
        uint128[] amounts;
        /// @dev address of contract that will rebalance collateral. This address must return collateral back to GammaPool
        address rebalancer;
        /// @dev data - optional bytes parameter to pass data to the rebalancer contract with instructions to rebalancer
        bytes data;
        /// @dev collateralId - index of collateral token + 1 that remaining collateral after repayment will be converted to
        uint256 collateralId;
        /// @dev to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to withdraw from a loan's collateral
        uint128[] withdraw;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint256[] minRepaid;
    }

    /// @dev Struct parameters for `borrowAndRebalanceExternally` function.
    struct BorrowAndRebalanceExternallyParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev address of contract that will rebalance collateral. This address must return collateral back to GammaPool
        address rebalancer;
        /// @dev data - optional bytes parameter to pass data to the rebalancer contract
        bytes data;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan
        uint256[] amounts;
        /// @dev amounts of reserve tokens requesting to withdraw from a loan's collateral
        uint128[] withdraw;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens` (borrowing). Slippage protection
        uint256[] minBorrowed;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        uint128[] minCollateral;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
    }

    /// @dev Re-balance loan collateral tokens by swapping one for another using an external source
    /// @param params - struct containing params to identify a GammaPool and loan with information to re-balance its collateral
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateralExternally(RebalanceCollateralExternallyParams calldata params) external returns(uint256 loanLiquidity, uint128[] memory tokensHeld);

    /// @notice Aggregate create loan, increase collateral, borrow collateral, and re-balance collateral externally into one transaction
    /// @dev Only create loan must be performed, the other transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokenId - tokenId of newly created loan
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function createLoanBorrowAndRebalanceExternally(CreateLoanBorrowAndRebalanceExternallyParams calldata params) external returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);

    /// @dev Repay liquidity debt from GammaPool rebalancing collateral externally to pay the debt in the proper ratio
    /// @param params - struct containing params to identify a GammaPool and loan to pay its liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function rebalanceExternallyAndRepayLiquidity(RebalanceExternallyAndRepayLiquidityParams calldata params) external returns (uint256 liquidityPaid, uint256[] memory amounts);

    /// @notice Aggregate increase collateral, borrow collateral, re-balance collateral externally, and decrease collateral into one transaction
    /// @dev All transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function borrowAndRebalanceExternally(BorrowAndRebalanceExternallyParams calldata params) external returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title IPriceStore interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface of PriceStore contract that will store price information for historical price queries
interface IPriceStore {

    /// @dev Struct to store identifiable information about loan to perform queries in PositionManager
    struct PriceInfo {
        /// @dev Timestamp of datapoint
        uint32 timestamp;
        /// @dev block number of datapoint
        uint32 blockNumber;
        /// @dev Utilization rate of GammaPool
        uint16 utilRate;
        /// @dev Yield in CFMM since last update (cfmmRate = 1 + yield), 281k with 9 decimals at uint48
        uint16 borrowRate;
        /// @dev YIeld of GammaPool since last update (feeIndex = (1 + borrowRate) * (1 + cfmmRate)
        uint64 accFeeIndex;
        /// @dev Add loan to mappings by user
        uint96 lastPrice; // 340 billion billion is uint128, 79 billion is uint96, 309 million is uint88, 1.2 million is uint80
    }

    /// @dev Set address that will supply the PriceStore with price information about a GammaPool
    /// @notice This is the address that can call the addPriceInfo() function to store price information
    /// @param _source - Address that calls addPrice() function to store price information
    function setSource(address _source) external;

    /// @dev Add price information from GammaPool. This calls the GammaPool with address `pool` to get the latest price information from it
    /// @notice Price information is added at frequency set by frequency state variable.
    /// @param pool - Address of GammaPoool to retrieve and store price information for in a price series array for it.
    function addPriceInfo(address pool) external;

    /// @dev Set the maximum length to store information for the price series of a GammaPool
    /// @notice If array of price series grows past _maxLen, values older than _maxLen spots back will be deleted with every update
    /// @param _maxLen - the maximum length of the price series array to hold information
    function setMaxLen(uint256 _maxLen) external;

    /// @dev Set the frequency at which to store information in seconds.
    /// @notice If set to zero the frequency is 1 hour in seconds (3600 seconds).
    /// @param _frequency - frequency to store information in seconds (e.g. 1 hour - 3600 seconds)
    function setFrequency(uint256 _frequency) external;

    /// @dev Get length of price series array of GammaPool with address `_pool`
    /// @param _pool - address of GammaPool to retrieve information for
    /// @return size - size of price series array of `_pool`
    function size(address _pool) external view returns(uint256);

    /// @dev Get price information at index of PriceInfo array of GammaPool with address `pool`
    /// @param pool - address of the GammaPool to get price information from
    /// @param index - index of price series array to retrieve information from
    /// @return data - PriceInfo struct containing price information at `index` of price series array of `pool`
    function getPriceAt(address pool, uint256 index) external view returns(PriceInfo memory data);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title Interface for Staking Router contract
/// @author Simon Mall
/// @dev Interface for staking router contract that deposits and withdraws from GammaSwap staking pools
interface IStakingPoolRouter {
  /// @dev Stake GS_LP tokens on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _esToken Escrow token address
  /// @param _amount Amount of GS_LP tokens to stake
  function stakeLpForAccount(address _account, address _gsPool, address _esToken, uint256 _amount) external;

  /// @dev Stake loan on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _loanId NFT loan id
  function stakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external;

  /// @dev Unstake GS_LP tokens on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _esToken Escrow token address
  /// @param _amount Amount of GS_LP tokens to unstake
  function unstakeLpForAccount(address _account, address _gsPool, address _esToken, uint256 _amount) external;

  /// @dev Unstake loan on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _loanId NFT loan id
  function unstakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IRefunds.sol";
import "@gammaswap/v1-core/contracts/interfaces/periphery/ISendTokensCallback.sol";

/// @title Interface for Transfers abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface used to send tokens and clear tokens and Ether from a contract
interface ITransfers is ISendTokensCallback, IRefunds {

    /// @return WETH - address of Wrapped Ethereum contract
    function WETH() external view returns (address);

    /// @dev Refund ETH balance to caller
    function refundETH() external payable;

    /// @dev Unwrap Wrapped ETH in contract and send ETH to recipient `to`
    /// @param minAmt - threshold balance of WETH which must be crossed before ETH can be refunded
    /// @param to - destination address where ETH will be sent to
    function unwrapWETH(uint256 minAmt, address to) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@gammaswap/v1-core/contracts/utils/TwoStepOwnable.sol";
import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";

import "./interfaces/IPositionManager.sol";
import "./interfaces/IPriceStore.sol";
import "./base/Transfers.sol";
import "./base/GammaPoolERC721.sol";
import "./base/GammaPoolQueryableLoans.sol";

/// @title PositionManager, concrete implementation of IPositionManager
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Periphery contract used to aggregate function calls to a GammaPool and give NFT (ERC721) functionality to loans
/// @notice Loans created through PositionManager become NFTs and can only be managed through PositionManager
/// @dev PositionManager is owner of loan and user is owner of NFT that represents loan in a GammaPool
contract PositionManager is Initializable, UUPSUpgradeable, TwoStepOwnable, IPositionManager, Transfers, GammaPoolQueryableLoans {

    error Forbidden();
    error Expired();
    error AmountsMin(uint8 id);

    string constant private _name = "PositionManager";
    string constant private _symbol = "PM-V1";

    /// @dev See {IPositionManager-factory}.
    address public immutable override factory;

    address public priceStore;

    /// @dev Initializes the contract by setting `factory`, `WETH`.
    constructor(address _factory, address _WETH) TwoStepOwnable(msg.sender) Transfers(_WETH) {
        factory = _factory;
    }

    function initialize(address _dataStore, address _priceStore) public initializer {
        owner = msg.sender;
        dataStore = _dataStore;
        priceStore = _priceStore;
    }

    modifier isAuthorizedForToken(uint256 tokenId) {
        checkAuthorization(tokenId);
        _;
    }

    modifier isExpired(uint256 deadline) {
        checkDeadline(deadline);
        _;
    }

    /// @dev Revert if msg.sender is not owner of loan or does not have permission to manage loan by checking NFT that represents loan
    /// @param tokenId - id that identifies loan
    function checkAuthorization(uint256 tokenId) internal view {
        if(!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Forbidden();
        }
    }

    /// @dev Revert if transaction already expired
    /// @param deadline - timestamp after which transaction is considered expired
    function checkDeadline(uint256 deadline) internal view {
        if(deadline < block.timestamp) {
            revert Expired();
        }
    }

    /// @dev See {IERC721Metadata-name}.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @dev Clear data store contract from PositionManager. PM will no longer update dataStore if cleared
    function removeDataStore() external virtual onlyOwner {
        dataStore = address(0);
    }

    /// @dev Clear price store contract from PositionManager. PM will no longer update priceStore if cleared
    function removePriceStore() external virtual onlyOwner {
        priceStore = address(0);
    }

    /// @dev See {ITransfers-getGammaPoolAddress}.
    function getGammaPoolAddress(address cfmm, uint16 protocolId) internal virtual override view returns(address) {
        return AddressCalculator.calcAddress(factory, protocolId, AddressCalculator.getGammaPoolKey(cfmm, protocolId));
    }

    // **** Short Gamma **** //

    /// @dev See {IPositionManager-depositNoPull}.
    function depositNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens); // send lp tokens to pool
        shares = IGammaPool(gammaPool).depositNoPull(params.to);
        emit DepositNoPull(gammaPool, shares);
    }

    /// @dev See {IPositionManager-withdrawNoPull}.
    function withdrawNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 assets) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(gammaPool, msg.sender, gammaPool, params.lpTokens); // send gs tokens to pool
        assets = IGammaPool(gammaPool).withdrawNoPull(params.to);
        emit WithdrawNoPull(gammaPool, assets);
    }

    /// @dev See {IPositionManager-depositReserves}.
    function depositReserves(DepositReservesParams calldata params) external virtual override isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(params.to, params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocolId: params.protocolId, payer: msg.sender})));
        emit DepositReserve(gammaPool, reserves, shares);
    }

    /// @dev See {IPositionManager-withdrawReserves}.
    function withdrawReserves(WithdrawReservesParams calldata params) external virtual override isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(gammaPool, msg.sender, gammaPool, params.amount); // send gs tokens to pool
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        checkMinReserves(reserves, params.amountsMin);
        emit WithdrawReserve(gammaPool, reserves, assets);
    }

    // **** LONG GAMMA **** //

    function logPrice(address gammaPool) external virtual {
        if(IGammaPoolFactory(factory).getKey(gammaPool) > 0) {
            _logPrice(gammaPool);
        }
    }

    function _logPrice(address gammaPool) internal virtual {
        if(priceStore != address(0)) {
            IPriceStore(priceStore).addPriceInfo(gammaPool);
        }
    }

    /// @notice Slippage protection for uint256[] array. If amounts < amountsMin, less was obtained than expected
    /// @dev Used to check quantities of tokens not used as collateral
    /// @param amounts - array containing uint256 amounts received from GammaPool
    /// @param amountsMin - minimum amounts acceptable to be received from uint256 before reverting transaction
    function checkMinReserves(uint256[] memory amounts, uint256[] memory amountsMin) internal virtual pure {
        uint256 len = amounts.length;
        uint256 len2 = amountsMin.length;
        if(len!=len2) return;
        for (uint256 i; i < len;) {
            if(amounts[i] < amountsMin[i]) {
                revert AmountsMin(1);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Slippage protection for uint128[] array. If amounts < amountsMin, less was obtained than expected
    /// @dev Used to check quantities of tokens used as collateral
    /// @param amounts - array containing uint128 amounts received from GammaPool
    /// @param amountsMin - minimum amounts acceptable to be received from uint128 before reverting transaction
    function checkMinCollateral(uint128[] memory amounts, uint128[] memory amountsMin) internal virtual pure {
        uint256 len = amounts.length;
        uint256 len2 = amountsMin.length;
        if(len!=len2) return;
        for (uint256 i; i < len;) {
            if(amounts[i] < amountsMin[i]) {
                revert AmountsMin(2);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Create a loan in GammaPool and turn it into an NFT issued to address `to`
    /// @dev Loans created here are actually owned by PositionManager and wrapped as an NFT issued to address `to`
    /// @param gammaPool - address of GammaPool we are creating gammaloan for
    /// @param to - recipient of NFT token
    /// @param refId - reference Id of loan observer
    /// @return tokenId - tokenId from creation of loan
    function createLoan(address gammaPool, address to, uint16 refId) internal virtual returns(uint256 tokenId) {
        tokenId = IGammaPool(gammaPool).createLoan(refId);
        mintQueryableLoan(gammaPool, tokenId, to);
        emit CreateLoan(gammaPool, to, tokenId, refId);
    }

    /// @dev Increase loan collateral by depositing more reserve tokens
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param amounts - amounts of reserve tokens sent to gammaPool
    /// @param ratio - ratio of loan collateral to be maintained after increasing collateral
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return tokensHeld - new loan collateral token amounts
    function increaseCollateral(address gammaPool, uint256 tokenId, uint256[] calldata amounts, uint256[] memory ratio, uint128[] memory minCollateral) internal virtual returns(uint128[] memory tokensHeld) {
        sendTokens(IGammaPool(gammaPool).tokens(), msg.sender, gammaPool, amounts);
        tokensHeld = IGammaPool(gammaPool).increaseCollateral(tokenId, ratio);
        checkMinCollateral(tokensHeld, minCollateral);
        emit IncreaseCollateral(gammaPool, tokenId, tokensHeld, amounts);
    }

    /// @dev Decrease loan collateral by withdrawing reserve tokens
    /// @param gammaPool - address of GammaPool of the loan
    /// @param to - address of recipient of amounts withdrawn from GammaPool
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param amounts - amounts of reserve tokens requesting to withdraw from loan
    /// @param ratio - ratio of loan collateral to be maintained after decreasing collateral
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return tokensHeld - new loan collateral token amounts
    function decreaseCollateral(address gammaPool, address to, uint256 tokenId, uint128[] memory amounts, uint256[] memory ratio, uint128[] memory minCollateral) internal virtual returns(uint128[] memory tokensHeld) {
        tokensHeld = IGammaPool(gammaPool).decreaseCollateral(tokenId, amounts, to, ratio);
        checkMinCollateral(tokensHeld, minCollateral);
        emit DecreaseCollateral(gammaPool, tokenId, tokensHeld, amounts);
    }

    /// @dev Re-balance loan collateral tokens by swapping one for another
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param deltas - amount to swap of one token at index for another (>0 buy, <0 sell). Must have at least one index field be 0
    /// @param ratio - ratio to rebalance collateral
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateral(address gammaPool, uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio, uint128[] memory minCollateral) internal virtual returns(uint128[] memory tokensHeld) {
        tokensHeld = IGammaPool(gammaPool).rebalanceCollateral(tokenId, deltas, ratio);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RebalanceCollateral(gammaPool, tokenId, tokensHeld);
    }

    /// @dev Borrow liquidity from GammaPool, can be used with a newly created loan or a loan already holding some liquidity debt
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param lpTokens - amount of CFMM LP tokens to short (borrow liquidity)
    /// @param ratio - ratio to rebalance collateral after borrowing
    /// @param minBorrowed - minimum expected amounts of reserve tokens to receive as collateral for `lpTokens` short. Used for slippage control
    /// @param maxBorrowed - max borrowed liquidity
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for shorting `lpTokens`
    /// @return tokensHeld - new loan collateral token amounts
    function borrowLiquidity(address gammaPool, uint256 tokenId, uint256 lpTokens, uint256[] memory ratio, uint256[] calldata minBorrowed, uint256 maxBorrowed, uint128[] memory minCollateral) internal virtual returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld) {
        (liquidityBorrowed, amounts, tokensHeld) = IGammaPool(gammaPool).borrowLiquidity(tokenId, lpTokens, ratio);
        require(liquidityBorrowed <= maxBorrowed, "MAX_BORROWED");
        checkMinReserves(amounts, minBorrowed);
        checkMinCollateral(tokensHeld, minCollateral);
        emit BorrowLiquidity(gammaPool, tokenId, liquidityBorrowed, amounts);
    }

    /// @dev Repay liquidity debt from GammaPool
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param liquidity - desired liquidity to pay
    /// @param collateralId - index of collateral token + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @param minRepaid - minimum amount of expected collateral to have used as payment. Used for slippage control
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function repayLiquidity(address gammaPool, uint256 tokenId, uint256 liquidity, uint256 collateralId, address to, uint256[] calldata minRepaid) internal virtual returns (uint256 liquidityPaid, uint256[] memory amounts) {
        (liquidityPaid, amounts) = IGammaPool(gammaPool).repayLiquidity(tokenId, liquidity, collateralId, to);
        checkMinReserves(amounts, minRepaid);
        emit RepayLiquidity(gammaPool, tokenId, liquidityPaid, amounts);
    }

    /// @dev Repay liquidity debt from GammaPool
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param liquidity - desired liquidity to pay
    /// @param ratio - weights of collateral after repaying liquidity
    /// @param minRepaid - minimum amount of expected collateral to have used as payment. Used for slippage control
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function repayLiquiditySetRatio(address gammaPool, uint256 tokenId, uint256 liquidity, uint256[] calldata ratio, uint256[] calldata minRepaid) internal virtual returns (uint256 liquidityPaid, uint256[] memory amounts) {
        (liquidityPaid, amounts) = IGammaPool(gammaPool).repayLiquiditySetRatio(tokenId, liquidity, ratio);
        checkMinReserves(amounts, minRepaid);
        emit RepayLiquiditySetRatio(gammaPool, tokenId, liquidityPaid, amounts);
    }

    /// @dev Repay liquidity debt from GammaPool with LP Tokens
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param collateralId - index of collateral token + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @param minCollateral - minimum collateral amounts in loan after repayment
    /// @param lpTokens - CFMM LP tokens used to repay liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return tokensHeld - reserve tokens used to pay liquidity debt
    function repayLiquidityWithLP(address gammaPool, uint256 tokenId, uint256 collateralId, address to, uint128[] memory minCollateral, uint256 lpTokens) internal virtual returns (uint256 liquidityPaid, uint128[] memory tokensHeld) {
        (liquidityPaid, tokensHeld) = IGammaPool(gammaPool).repayLiquidityWithLP(tokenId, collateralId, to);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RepayLiquidityWithLP(gammaPool, tokenId, liquidityPaid, tokensHeld, lpTokens);
    }

    // Individual Function Calls

    /// @dev See {IPositionManager-createLoan}.
    function createLoan(uint16 protocolId, address cfmm, address to, uint16 refId, uint256 deadline) external virtual override isExpired(deadline) returns(uint256 tokenId) {
        address gammaPool = getGammaPoolAddress(cfmm, protocolId);
        tokenId = createLoan(gammaPool, to, refId);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-borrowLiquidity}.
    function borrowLiquidity(BorrowLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens, params.ratio, params.minBorrowed, params.maxBorrowed, params.minCollateral);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-repayLiquidity}.
    function repayLiquidity(RepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.isRatio) {
            (liquidityPaid, amounts) = repayLiquiditySetRatio(gammaPool, params.tokenId, params.liquidity, params.ratio, params.minRepaid);
        } else {
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, params.collateralId, params.to, params.minRepaid);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-repayLiquidityWithLP}.
    function repayLiquidityWithLP(RepayLiquidityWithLPParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens);
        (liquidityPaid, tokensHeld) = repayLiquidityWithLP(gammaPool, params.tokenId, params.collateralId, params.to, params.minCollateral, params.lpTokens);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-increaseCollateral}.
    function increaseCollateral(AddCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts, params.ratio, params.minCollateral);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-decreaseCollateral}.
    function decreaseCollateral(RemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld){
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.amounts, params.ratio, params.minCollateral);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-rebalanceCollateral}.
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = rebalanceCollateral(gammaPool, params.tokenId, params.deltas, params.ratio, params.minCollateral);
        _logPrice(gammaPool);
    }

    // Multi Function Calls

    /// @dev See {IPositionManager-createLoanBorrowAndRebalance}.
    function createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokenId = createLoan(gammaPool, params.to, params.refId);
        tokensHeld = increaseCollateral(gammaPool, tokenId, params.amounts, new uint256[](0), new uint128[](0));
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, tokenId, params.lpTokens, params.ratio, params.minBorrowed, params.maxBorrowed, params.minCollateral);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-borrowAndRebalance}.
    function borrowAndRebalance(BorrowAndRebalanceParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        bool isWithdrawCollateral = params.withdraw.length != 0;
        if(params.amounts.length != 0) {
            tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts,
                params.lpTokens != 0 || isWithdrawCollateral ? new uint256[](0) : params.ratio,
                params.lpTokens != 0 || isWithdrawCollateral ? new uint128[](0) : params.minCollateral);
        }
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens,
                isWithdrawCollateral ? new uint256[](0) : params.ratio, params.minBorrowed, params.maxBorrowed,
                isWithdrawCollateral ? new uint128[](0) : params.minCollateral);
        }
        if(isWithdrawCollateral) {
            tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw, params.ratio, params.minCollateral);
        }
        _logPrice(gammaPool);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolExternal.sol";

import "./interfaces/IPositionManagerExternal.sol";
import "./PositionManagerWithStaking.sol";

/// @title PositionManagerExternalWithStaking, concrete implementation of IPositionManagerExternal
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Inherits PositionManager functionality from PositionManagerWithStaking and defines functionality to rebalance
/// @notice loan collateral using external contracts by calling GammaPool::rebalanceExternally()
contract PositionManagerExternalWithStaking is PositionManagerWithStaking, IPositionManagerExternal {

    /// @dev Constructs the PositionManagerWithStaking contract.
    /// @param _factory Address of the contract factory.
    /// @param _WETH Address of the Wrapped Ether (WETH) contract.
    constructor(address _factory, address _WETH) PositionManagerWithStaking(_factory, _WETH) {}

    /// @dev Flash loan pool's collateral and/or lp tokens to external address. Rebalanced loan collateral is acceptable
    /// @dev in  repayment of flash loan. Function can be used for other purposes besides rebalancing collateral.
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - unique id identifying loan
    /// @param amounts - collateral amounts being flash loaned
    /// @param lpTokens - amount of CFMM LP tokens being flash loaned
    /// @param to - address that will receive flash loan swaps and potentially rebalance loan's collateral
    /// @param data - optional bytes parameter for custom user defined data
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - updated collateral token amounts backing loan
    function rebalanceCollateralExternally(address gammaPool, uint256 tokenId, uint128[] memory amounts, uint256 lpTokens, address to, bytes calldata data, uint128[] memory minCollateral) internal virtual returns(uint256 loanLiquidity, uint128[] memory tokensHeld) {
        (loanLiquidity, tokensHeld) = IGammaPoolExternal(gammaPool).rebalanceExternally(tokenId, amounts, lpTokens, to, data);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RebalanceCollateralExternally(gammaPool, tokenId, loanLiquidity, tokensHeld);
    }

    /// @dev See {IPositionManagerExternal-rebalanceCollateralExternally}.
    function rebalanceCollateralExternally(RebalanceCollateralExternallyParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint256 loanLiquidity, uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (loanLiquidity,tokensHeld) = rebalanceCollateralExternally(gammaPool, params.tokenId, params.amounts, params.lpTokens, params.rebalancer, params.data, params.minCollateral);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManagerExternal-createLoanBorrowAndRebalanceExternally}.
    function createLoanBorrowAndRebalanceExternally(CreateLoanBorrowAndRebalanceExternallyParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokenId = createLoan(gammaPool, params.to, params.refId);
        tokensHeld = increaseCollateral(gammaPool, tokenId, params.amounts, new uint256[](0), new uint128[](0));
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, tokenId, params.lpTokens, new uint256[](0), params.minBorrowed, params.maxBorrowed, new uint128[](0));
        }
        if(params.rebalancer != address(0)) {
            (,tokensHeld) = rebalanceCollateralExternally(gammaPool, tokenId, tokensHeld, 0, params.rebalancer, params.data, params.minCollateral);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManagerExternal-rebalanceExternallyAndRepayLiquidity}.
    function rebalanceExternallyAndRepayLiquidity(RebalanceExternallyAndRepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.rebalancer != address(0)) {
            rebalanceCollateralExternally(gammaPool, params.tokenId, params.amounts, 0, params.rebalancer, params.data, params.minCollateral);
        }
        if(params.withdraw.length > 0) {
            // if partial repay
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, 0, address(0), params.minRepaid);
            decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw, new uint256[](0), new uint128[](0));
        } else {
            // if full repay
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, params.collateralId, params.to, params.minRepaid);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManagerExternal-borrowAndRebalanceExternally}.
    function borrowAndRebalanceExternally(BorrowAndRebalanceExternallyParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        bool isWithdrawCollateral = params.withdraw.length != 0;
        if(params.amounts.length != 0) {
            tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts, new uint256[](0), new uint128[](0));
        }
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens, new uint256[](0), params.minBorrowed, params.maxBorrowed, new uint128[](0));
        }
        if(params.rebalancer != address(0) && tokensHeld.length != 0) {
            (,tokensHeld) = rebalanceCollateralExternally(gammaPool, params.tokenId, tokensHeld, 0, params.rebalancer, params.data, params.minCollateral);
        }
        if(isWithdrawCollateral) {
            tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw, new uint256[](0), new uint128[](0));
        }
        _logPrice(gammaPool);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./interfaces/IStakingPoolRouter.sol";
import "./interfaces/IAutoStakable.sol";
import "./PositionManager.sol";

/// @title PositionManagerWithStaking
/// @author Simon Mall
/// @dev Extension of PositionManager that adds staking and unstaking functionality for automated operations.
contract PositionManagerWithStaking is PositionManager, IAutoStakable {
    IStakingPoolRouter stakingRouter;

    /// @dev Constructs the PositionManagerWithStaking contract.
    /// @param _factory Address of the contract factory.
    /// @param _WETH Address of the Wrapped Ether (WETH) contract.
    constructor(address _factory, address _WETH) PositionManager(_factory, _WETH) {}

    /// @dev See {IAutoStakable-setStakingRouter}
    function setStakingRouter(address _stakingRouter) external onlyOwner {
        stakingRouter = IStakingPoolRouter(_stakingRouter);
    }

    /// @dev See {IAutoStakable-depositReservesAndStake}.
    function depositReservesAndStake(DepositReservesParams calldata params, address esToken) external isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        if(address(stakingRouter) == address(0) && esToken != address(0)) revert StakingRouterNotSet();

        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        address receiver = esToken != address(0) ? address(stakingRouter) : params.to;
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(receiver, params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocolId: params.protocolId, payer: msg.sender})));

        if(esToken != address(0)) {
            stakingRouter.stakeLpForAccount(params.to, gammaPool, esToken, shares);
        }

        emit DepositReserve(gammaPool, reserves, shares);
    }

    /// @dev See {IAutoStakable-withdrawReservesAndUnstake}.
    function withdrawReservesAndUnstake(WithdrawReservesParams calldata params, address esToken) external isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address user = msg.sender;

        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);

        if(esToken != address(0)) {
            if(address(stakingRouter) == address(0)) revert StakingRouterNotSet();

            stakingRouter.unstakeLpForAccount(user, gammaPool, esToken, params.amount);
        }

        send(gammaPool, msg.sender, gammaPool, params.amount);
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        checkMinReserves(reserves, params.amountsMin);
        emit WithdrawReserve(gammaPool, reserves, assets);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
 * ```
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}