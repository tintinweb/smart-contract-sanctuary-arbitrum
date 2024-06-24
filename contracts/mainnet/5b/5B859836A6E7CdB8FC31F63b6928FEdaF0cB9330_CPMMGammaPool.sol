// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "../libraries/GammaSwapLibrary.sol";
import "../interfaces/IGammaPool.sol";
import "../interfaces/IGammaPoolFactory.sol";
import "../interfaces/strategies/lending/IBorrowStrategy.sol";
import "../interfaces/strategies/lending/IRepayStrategy.sol";
import "../interfaces/strategies/rebalance/IRebalanceStrategy.sol";
import "../interfaces/strategies/base/ILongStrategy.sol";
import "../interfaces/strategies/base/ILiquidationStrategy.sol";
import "../interfaces/strategies/liquidation/ISingleLiquidationStrategy.sol";
import "../interfaces/strategies/liquidation/IBatchLiquidationStrategy.sol";
import "../interfaces/IPoolViewer.sol";
import "./GammaPoolERC4626.sol";

/// @title Basic GammaPool smart contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used as template for building other GammaPool contract implementations for other CFMMs
abstract contract GammaPool is IGammaPool, GammaPoolERC4626 {

    using LibStorage for LibStorage.Storage;

    error Forbidden();
    error ZeroFeeDivisor();
    error LiquidationFeeGtLTVThreshold();
    error InvalidMinBorrow();

    /// @dev See {IGammaPool-protocolId}
    uint16 immutable public override protocolId;

    /// @dev See {IGammaPool-factory}
    address immutable public override factory;

    /// @dev See {IGammaPool-borrowStrategy}
    address immutable public override borrowStrategy;

    /// @dev See {IGammaPool-repayStrategy}
    address immutable public override repayStrategy;

    /// @dev See {IGammaPool-rebalanceStrategy}
    address immutable public override rebalanceStrategy;

    /// @dev See {IGammaPool-shortStrategy}
    address immutable public override shortStrategy;

    /// @dev See {IGammaPool-singleLiquidationStrategy}
    address immutable public override singleLiquidationStrategy;

    /// @dev See {IGammaPool-batchLiquidationStrategy}
    address immutable public override batchLiquidationStrategy;

    /// @dev See {IGammaPool-viewer}
    address immutable public override viewer;

    /// @dev Initializes the contract by setting `protocolId`, `factory`, `borrowStrategy`, `repayStrategy`, `rebalanceStrategy`,
    /// @dev shortStrategy`, `singleLiquidationStrategy`, `batchLiquidationStrategy`, and `viewer`.
    constructor(uint16 protocolId_, address factory_,  address borrowStrategy_, address repayStrategy_, address rebalanceStrategy_,
        address shortStrategy_, address singleLiquidationStrategy_, address batchLiquidationStrategy_, address viewer_) {
        protocolId = protocolId_;
        factory = factory_;
        borrowStrategy = borrowStrategy_;
        repayStrategy = repayStrategy_;
        rebalanceStrategy = rebalanceStrategy_;
        shortStrategy = shortStrategy_;
        singleLiquidationStrategy = singleLiquidationStrategy_;
        batchLiquidationStrategy = batchLiquidationStrategy_;
        viewer = viewer_;
    }

    /// @dev See {IGammaPool-initialize}
    function initialize(address _cfmm, address[] calldata _tokens, uint8[] calldata _decimals, uint72 _minBorrow, bytes calldata) external virtual override {
        if(msg.sender != factory) revert Forbidden(); // only factory is allowed to initialize
        s.initialize(factory, _cfmm, protocolId, _tokens, _decimals, _minBorrow);
    }

    /// @dev See {IGammaPool-setPoolParams}
    function setPoolParams(uint16 origFee, uint8 extSwapFee, uint8 emaMultiplier, uint8 minUtilRate1, uint8 minUtilRate2, uint16 feeDivisor, uint8 liquidationFee, uint8 ltvThreshold, uint72 minBorrow) external virtual override {
        if(msg.sender != factory) revert Forbidden(); // only factory is allowed to update dynamic fee parameters

        if(feeDivisor == 0) revert ZeroFeeDivisor();
        if(liquidationFee > uint256(ltvThreshold) * 10) revert LiquidationFeeGtLTVThreshold();
        if(minBorrow < 1e3) revert InvalidMinBorrow();

        s.ltvThreshold = ltvThreshold;
        s.liquidationFee = liquidationFee;
        s.origFee = origFee;
        s.extSwapFee = extSwapFee;
        s.emaMultiplier = emaMultiplier;
        s.minUtilRate1 = minUtilRate1;
        s.minUtilRate2 = minUtilRate2;
        s.feeDivisor = feeDivisor;
        s.minBorrow = minBorrow;
    }

    /// @dev See {IGammaPool-cfmm}
    function cfmm() external virtual override view returns(address) {
        return s.cfmm;
    }

    /// @dev See {IGammaPool-tokens}
    function tokens() external virtual override view returns(address[] memory) {
        return s.tokens;
    }

    /// @dev See {IGammaPool-vaultImplementation}
    function vaultImplementation() internal virtual override view returns(address) {
        return shortStrategy;
    }

    /// @dev See {IRateModel-validateParameters}
    function validateParameters(bytes calldata _data) external view returns(bool) {
        return IRateModel(borrowStrategy).validateParameters(_data);
    }

    /// @dev See {IRateModel-rateParamsStore}
    function rateParamsStore() external view returns(address) {
        return s.factory;
    }

    /***** CFMM Data *****/

    /// @dev See {GammaPoolERC4626-_getLatestCFMMReserves}
    function _getLatestCFMMReserves() internal virtual override view returns(uint128[] memory cfmmReserves) {
        return IShortStrategy(shortStrategy)._getLatestCFMMReserves(abi.encode(s.cfmm));
    }

    /// @dev See {GammaPoolERC4626-_getLatestCFMMInvariant}
    function _getLatestCFMMInvariant() internal virtual override view returns(uint256 lastCFMMInvariant) {
        return IShortStrategy(shortStrategy)._getLatestCFMMInvariant(abi.encode(s.cfmm));
    }

    /// @dev See {GammaPoolERC4626-_getLatestCFMMTotalSupply}
    function _getLatestCFMMTotalSupply() internal virtual override view returns(uint256 lastCFMMTotalSupply) {
        return GammaSwapLibrary.totalSupply(s.cfmm);
    }

    /// @dev See {IGammaPool-getLatestCFMMReserves}
    function getLatestCFMMReserves() external virtual override view returns(uint128[] memory cfmmReserves) {
        return _getLatestCFMMReserves();
    }

    /// @dev See {IGammaPool-getCFMMBalances}
    function getLatestCFMMBalances() external virtual override view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        return(_getLatestCFMMReserves(), _getLatestCFMMInvariant(), _getLatestCFMMTotalSupply());
    }

    /// @dev See {IGammaPool.getLastCFMMPrice}.
    function getLastCFMMPrice() external virtual override view returns(uint256) {
        return _getLastCFMMPrice();
    }

    /***** GammaPool Data *****/

    /// @dev See {IGammaPool-getPoolBalances}
    function getPoolBalances() external virtual override view returns(uint128[] memory tokenBalances, uint256 lpTokenBalance, uint256 lpTokenBorrowed,
        uint256 lpTokenBorrowedPlusInterest, uint256 borrowedInvariant, uint256 lpInvariant) {
        return(s.TOKEN_BALANCE, s.LP_TOKEN_BALANCE, s.LP_TOKEN_BORROWED, s.LP_TOKEN_BORROWED_PLUS_INTEREST, s.BORROWED_INVARIANT, s.LP_INVARIANT);
    }

    /// @dev See {IGammaPool-getCFMMBalances}
    function getCFMMBalances() external virtual override view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        return(s.CFMM_RESERVES, s.lastCFMMInvariant, s.lastCFMMTotalSupply);
    }

    /// @dev See {IGammaPool-getRates}
    function getRates() external virtual override view returns(uint256 accFeeIndex, uint256 lastCFMMFeeIndex, uint256 lastBlockNumber) {
        return(s.accFeeIndex, s.lastCFMMFeeIndex, s.LAST_BLOCK_NUMBER);
    }

    /// @dev See {IGammaPool-getPoolData}
    function getPoolData() external virtual override view returns(PoolData memory data) {
        data.poolId = address(this);
        data.protocolId = protocolId;
        data.borrowStrategy = borrowStrategy;
        data.repayStrategy = repayStrategy;
        data.rebalanceStrategy = rebalanceStrategy;
        data.shortStrategy = shortStrategy;
        data.singleLiquidationStrategy = singleLiquidationStrategy;
        data.batchLiquidationStrategy = batchLiquidationStrategy;
        data.cfmm = s.cfmm;
        data.currBlockNumber = uint40(block.number);
        data.LAST_BLOCK_NUMBER = s.LAST_BLOCK_NUMBER;
        data.factory = s.factory;
        data.paramsStore = s.factory;
        data.LP_TOKEN_BALANCE = s.LP_TOKEN_BALANCE;
        data.LP_TOKEN_BORROWED = s.LP_TOKEN_BORROWED;
        data.totalSupply = s.totalSupply;
        data.TOKEN_BALANCE = s.TOKEN_BALANCE;
        data.tokens = s.tokens;
        data.decimals = s.decimals;
        data.LP_TOKEN_BORROWED_PLUS_INTEREST = s.LP_TOKEN_BORROWED_PLUS_INTEREST;
        data.BORROWED_INVARIANT = s.BORROWED_INVARIANT;
        data.LP_INVARIANT = s.LP_INVARIANT;
        data.accFeeIndex = s.accFeeIndex;
        data.ltvThreshold = s.ltvThreshold;
        data.liquidationFee = s.liquidationFee;
        data.origFee = s.origFee;
        data.extSwapFee = s.extSwapFee;
        data.lastCFMMFeeIndex = s.lastCFMMFeeIndex;
        data.lastCFMMInvariant = s.lastCFMMInvariant;
        data.lastCFMMTotalSupply = s.lastCFMMTotalSupply;
        data.CFMM_RESERVES = s.CFMM_RESERVES;
        data.emaUtilRate = s.emaUtilRate;
        data.emaMultiplier = s.emaMultiplier;
        data.minUtilRate1 = s.minUtilRate1;
        data.minUtilRate2 = s.minUtilRate2;
        data.feeDivisor = s.feeDivisor;
        data.minBorrow = s.minBorrow;
    }

    /***** SHORT *****/

    /// @dev See {IGammaPool-depositNoPull}
    function depositNoPull(address to) external virtual override whenNotPaused(5) returns(uint256 shares) {
        return abi.decode(callStrategy(shortStrategy, abi.encodeCall(IShortStrategy._depositNoPull, to)), (uint256));
    }

    /// @dev See {IGammaPool-withdrawNoPull}
    function withdrawNoPull(address to) external virtual override whenNotPaused(6) returns(uint256 assets) {
        return abi.decode(callStrategy(shortStrategy, abi.encodeCall(IShortStrategy._withdrawNoPull, to)), (uint256));
    }

    /// @dev See {IGammaPool-depositReserves}
    function depositReserves(address to, uint256[] calldata amountsDesired, uint256[] calldata amountsMin, bytes calldata data) external virtual override whenNotPaused(7) returns(uint256[] memory reserves, uint256 shares){
        return abi.decode(callStrategy(shortStrategy, abi.encodeCall(IShortStrategy._depositReserves, (to, amountsDesired, amountsMin, data))), (uint256[],uint256));
    }

    /// @dev See {IGammaPool-withdrawReserves}
    function withdrawReserves(address to) external virtual override whenNotPaused(8) returns (uint256[] memory reserves, uint256 assets) {
        return abi.decode(callStrategy(shortStrategy, abi.encodeCall(IShortStrategy._withdrawReserves, to)), (uint256[],uint256));
    }

    /***** LONG *****/

    /// @dev See {IGammaPool-createLoan}
    function createLoan(uint16 refId) external lock virtual override whenNotPaused(9) returns(uint256 tokenId) {
        tokenId = s.createLoan(s.tokens.length, refId);
        emit LoanCreated(msg.sender, tokenId, refId);
    }

    /// @dev See {IGammaPool-loan}
    function loan(uint256 tokenId) external virtual override view returns(LoanData memory _loanData) {
        _loanData = _getLoanData(tokenId);
    }

    /// @dev Get loan and convert to LoanData struct
    /// @param _tokenId - tokenId of loan to convert
    /// @return _loanData - loan data struct (same as Loan + tokenId)
    function _getLoanData(uint256 _tokenId) internal virtual view returns(LoanData memory _loanData) {
        LibStorage.Loan memory _loan = s.loans[_tokenId];
        _loanData.tokenId = _tokenId;
        _loanData.id = _loan.id;
        _loanData.poolId = _loan.poolId;
        _loanData.tokensHeld = _loan.tokensHeld;
        _loanData.initLiquidity = _loan.initLiquidity;
        _loanData.lastLiquidity = _loan.liquidity;
        _loanData.liquidity = _loan.liquidity;
        _loanData.lpTokens = _loan.lpTokens;
        _loanData.rateIndex = _loan.rateIndex;
        _loanData.px = _loan.px;
        _loanData.refAddr = _loan.refAddr;
        _loanData.refFee = _loan.refFee;
        _loanData.refType = _loan.refType;
    }

    /// @dev Get loan and convert to LoanData struct
    /// @param _tokenId - tokenId of loan to convert
    /// @return _loanData - loan data struct (same as Loan + tokenId)
    function getLoanData(uint256 _tokenId) public virtual override view returns(LoanData memory _loanData) {
        _loanData = _getLoanData(_tokenId);
        _loanData.tokens = s.tokens;
        _loanData.decimals = s.decimals;
        _loanData.paramsStore = s.factory;
        _loanData.shortStrategy = shortStrategy;
        _loanData.accFeeIndex = s.accFeeIndex;
        _loanData.LAST_BLOCK_NUMBER = s.LAST_BLOCK_NUMBER;
        _loanData.BORROWED_INVARIANT = s.BORROWED_INVARIANT;
        _loanData.LP_INVARIANT = s.LP_INVARIANT;
        _loanData.LP_TOKEN_BALANCE = s.LP_TOKEN_BALANCE;
        _loanData.lastCFMMInvariant = s.lastCFMMInvariant;
        _loanData.lastCFMMTotalSupply = s.lastCFMMTotalSupply;
        _loanData.ltvThreshold = s.ltvThreshold;
        _loanData.liquidationFee = s.liquidationFee;
        _loanData.lastCFMMFeeIndex = s.lastCFMMFeeIndex;
    }

    /// @dev See {IGammaPool-getLoans}
    function getLoans(uint256 start, uint256 end, bool active) external virtual override view returns(LoanData[] memory _loans) {
        uint256[] storage _tokenIds = s.tokenIds;
        if(start > end || _tokenIds.length == 0) {
            return _loans;
        }
        uint256 lastIdx;
        unchecked {
            lastIdx = _tokenIds.length - 1;
        }
        end = lastIdx < end ? lastIdx : end; // end = min(lastIdx,end) <= min(type(uint256).max-1,end)
        if(start <= end) {
            unchecked {
                _loans = new LoanData[](1 + end - start);
            }
            LoanData memory _loan;
            uint256 k = 0;
            for(uint256 i = start; i <= end;) {
                _loan = _getLoanData(_tokenIds[i]);
                if(!active || _loan.initLiquidity > 0) {
                    _loans[k] = _loan;
                    unchecked {
                        ++k;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
        return _loans;
    }

    /// @dev See {IGammaPool-getLoansById}
    function getLoansById(uint256[] calldata tokenIds, bool active) external virtual override view returns(LoanData[] memory _loans) {
        uint256 _size = tokenIds.length;
        _loans = new LoanData[](_size);
        LoanData memory _loan;
        uint256 k = 0;
        for(uint256 i = 0; i < _size;) {
            _loan = _getLoanData(tokenIds[i]);
            if(_loan.id > 0 && (!active || _loan.initLiquidity > 0)) {
                _loans[k] = _loan;
                unchecked {
                    ++k;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev calculate liquidity invariant from collateral tokens
    /// @param tokensHeld - loan's collateral tokens
    /// @return collateralInvariant - invariant calculated from loan's collateral tokens
    function _calcInvariant(uint128[] memory tokensHeld) internal virtual view returns(uint256);

    /// @dev See {IGammaPool-calcInvariant}
    function calcInvariant(uint128[] memory tokensHeld) external virtual override view returns(uint256) {
        return _calcInvariant(tokensHeld);
    }

    /// @dev See {IGammaPool-getLoanCount}
    function getLoanCount() external virtual override view returns(uint256) {
        return s.tokenIds.length;
    }

    /// @dev See {IGammaPool-increaseCollateral}
    function increaseCollateral(uint256 tokenId, uint256[] calldata ratio) external virtual override whenNotPaused(10) returns(uint128[] memory tokensHeld) {
        return abi.decode(callStrategy(borrowStrategy, abi.encodeCall(IBorrowStrategy._increaseCollateral, (tokenId, ratio))), (uint128[]));
    }

    /// @dev See {IGammaPool-decreaseCollateral}
    function decreaseCollateral(uint256 tokenId, uint128[] memory amounts, address to, uint256[] calldata ratio) external virtual override whenNotPaused(11) returns(uint128[] memory tokensHeld) {
        return abi.decode(callStrategy(borrowStrategy, abi.encodeCall(IBorrowStrategy._decreaseCollateral, (tokenId, amounts, to, ratio))), (uint128[]));
    }

    /// @dev See {IGammaPool-borrowLiquidity}
    function borrowLiquidity(uint256 tokenId, uint256 lpTokens, uint256[] calldata ratio) external virtual override whenNotPaused(12) returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld) {
        return abi.decode(callStrategy(borrowStrategy, abi.encodeCall(IBorrowStrategy._borrowLiquidity, (tokenId, lpTokens, ratio))), (uint256, uint256[], uint128[]));
    }

    /// @dev See {IGammaPool-repayLiquidity}
    function repayLiquidity(uint256 tokenId, uint256 liquidity, uint256 collateralId, address to) external virtual override whenNotPaused(13) returns(uint256 liquidityPaid, uint256[] memory amounts) {
        return abi.decode(callStrategy(repayStrategy, abi.encodeCall(IRepayStrategy._repayLiquidity, (tokenId, liquidity, collateralId, to))), (uint256, uint256[]));
    }

    /// @dev See {IGammaPool-repayLiquiditySetRatio}
    function repayLiquiditySetRatio(uint256 tokenId, uint256 liquidity, uint256[] calldata ratio) external virtual override whenNotPaused(14) returns(uint256 liquidityPaid, uint256[] memory amounts) {
        return abi.decode(callStrategy(repayStrategy, abi.encodeCall(IRepayStrategy._repayLiquiditySetRatio, (tokenId, liquidity, ratio))), (uint256, uint256[]));
    }

    /// @dev See {IGammaPool-repayLiquidityWithLP}
    function repayLiquidityWithLP(uint256 tokenId, uint256 collateralId, address to) external virtual override whenNotPaused(15) returns(uint256 liquidityPaid, uint128[] memory tokensHeld) {
        return abi.decode(callStrategy(repayStrategy, abi.encodeCall(IRepayStrategy._repayLiquidityWithLP, (tokenId, collateralId, to))), (uint256, uint128[]));
    }

    /// @dev See {IGammaPool-rebalanceCollateral}
    function rebalanceCollateral(uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio) external virtual override whenNotPaused(16) returns(uint128[] memory tokensHeld) {
        return abi.decode(callStrategy(rebalanceStrategy, abi.encodeCall(IRebalanceStrategy._rebalanceCollateral, (tokenId, deltas, ratio))), (uint128[]));
    }

    /// @dev See {IGammaPool-updatePool}
    function updatePool(uint256 tokenId) external virtual override whenNotPaused(17) returns(uint256 loanLiquidityDebt, uint256 poolLiquidityDebt) {
        return abi.decode(callStrategy(rebalanceStrategy, abi.encodeCall(IRebalanceStrategy._updatePool, tokenId)), (uint256, uint256));
    }

    /// @dev See {IGammaPool-liquidate}
    function liquidate(uint256 tokenId) external virtual override whenNotPaused(18) returns(uint256 loanLiquidity, uint256 refund) {
        return abi.decode(callStrategy(singleLiquidationStrategy, abi.encodeCall(ISingleLiquidationStrategy._liquidate, tokenId)), (uint256, uint256));
    }

    /// @dev See {IGammaPool-liquidateWithLP}
    function liquidateWithLP(uint256 tokenId) external virtual override whenNotPaused(19) returns(uint256 loanLiquidity, uint256[] memory refund) {
        return abi.decode(callStrategy(singleLiquidationStrategy, abi.encodeCall(ISingleLiquidationStrategy._liquidateWithLP, tokenId)), (uint256, uint256[]));
    }

    /// @dev See {IGammaPool-batchLiquidations}
    function batchLiquidations(uint256[] calldata tokenIds) external virtual override whenNotPaused(20) returns(uint256 totalLoanLiquidity, uint256[] memory refund) {
        return abi.decode(callStrategy(batchLiquidationStrategy, abi.encodeCall(IBatchLiquidationStrategy._batchLiquidations, tokenIds)), (uint256, uint256[]));
    }

    /***** SYNC POOL *****/

    /// @dev See {IGammaPool-sync}
    function sync() external virtual override whenNotPaused(21) {
        callStrategy(shortStrategy, abi.encodeCall(IShortStrategy._sync, ()));
    }

    /// @dev See {IGammaPool-skim}
    function skim(address to) external virtual override lock whenNotPaused(22) {
        address[] memory _tokens = s.tokens; // gas savings
        uint128[] memory _tokenBalances = s.TOKEN_BALANCE;
        for(uint256 i; i < _tokens.length;) {
            skim(_tokens[i], _tokenBalances[i], to); // skim collateral tokens
            unchecked {
                ++i;
            }
        }
        skim(s.cfmm, s.LP_TOKEN_BALANCE, to); // skim cfmm LP tokens
    }

    /// @dev See {ITransfers-clearToken}
    function clearToken(address token, address to, uint256 minAmt) external override virtual lock whenNotPaused(23) {
        // Can't clear CFMM LP tokens or collateral tokens
        if(isCFMMToken(token) || isCollateralToken(token)) revert RestrictedToken();

        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if(tokenBal < minAmt) revert NotEnoughTokens(); // Only clear if past threshold

        // If not CFMM LP token or collateral token send entire amount
        if (tokenBal > 0) GammaSwapLibrary.safeTransfer(token, to, tokenBal);
    }

    /// @dev See {Transfers-isCFMMToken}
    function isCFMMToken(address token) internal virtual override view returns(bool) {
        return token == s.cfmm;
    }

    /// @dev See {Transfers-isCollateralToken}
    function isCollateralToken(address token) internal virtual override view returns(bool) {
        address[] memory _tokens = s.tokens; // gas savings
        for(uint256 i; i < _tokens.length;) {
            if(token == _tokens[i]) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../storage/AppStorage.sol";
import "../interfaces/strategies/events/IGammaPoolERC20Events.sol";

/// @title ERC20 (GS LP) implementation of GammaPool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev The root contract in GammaPool inheritance hierarchy. Inherits AppStorage contract to implement App Storage pattern
abstract contract GammaPoolERC20 is IGammaPoolERC20Events, AppStorage {

    error ERC20Transfer();
    error ERC20Allowance();

    /// @return name - name of the token.
    string public constant name = 'GammaSwap V1';

    /// @return symbol - token symbol
    string public constant symbol = 'GS-V1';

    /// @return decimals - number of decimals used to get the user representation of GS LP token numbers.
    uint8 public constant decimals = 18;

    /// @return totalSupply - amount of GS LP tokens in existence.
    function totalSupply() public virtual view returns (uint256) {
        return s.totalSupply;
    }

    /// @dev Returns the amount of GS LP tokens owned by `account`.
    /// @param account - address whose GS LP token balance is being checked
    /// @return balance - amount of GS LP tokens held by account address
    function balanceOf(address account) external virtual view returns (uint256) {
        return s.balanceOf[account];
    }

    /// @dev Returns the remaining number of GS LP tokens that `spender` will be allowed to spend on behalf of `owner` through a transferFrom function call. Zero by default.
    /// @param owner - address which owns the GS LP tokens spender is being given permission to spend
    /// @param spender - address given permission to spend owner's GS LP tokens
    /// @return allowance - amount of GS LP tokens belonging to owner that spender is allowed to spend, changes with transferFrom or approve function calls
    function allowance(address owner, address spender) external virtual view returns (uint256) {
        return s.allowance[owner][spender];
    }

    /// @dev Moves `amount` of GS LP tokens from `from` to `to`.
    /// @param from - address sending GS LP tokens
    /// @param to - address receiving GS LP tokens
    /// @param amount - amount of GS LP tokens being sent
    function _transfer(address from, address to, uint256 amount) internal virtual {
        uint256 currentBalance = s.balanceOf[from];
        if(currentBalance < amount) revert ERC20Transfer(); // insufficient balance

        unchecked{
            s.balanceOf[from] = currentBalance - amount;
        }
        s.balanceOf[to] = s.balanceOf[to] + amount;
        emit Transfer(from, to, amount);
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's GS LP tokens.
    /// @param spender - address given permission to spend caller's GS LP tokens
    /// @param amount - amount of GS LP tokens spender is given permission to spend
    /// @return bool - true if operation succeeded
    function approve(address spender, uint256 amount) external virtual returns (bool) {
        s.allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @dev Moves `amount` GS LP tokens from the caller's account to `to`.
    /// @param to - address receiving caller's GS LP tokens
    /// @param amount - amount of GS LP tokens caller is sending
    /// @return bool - true if operation succeeded
    function transfer(address to, uint256 amount) external virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Moves `amount` GS LP tokens from `from` to `to` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
    /// @param from - address sending GS LP tokens (not necessarily caller's address)
    /// @param to - address receiving GS LP tokens
    /// @param amount - amount of GS LP tokens being sent
    /// @return bool - true if operation succeeded
    function transferFrom(address from, address to, uint256 amount) external virtual returns (bool) {
        uint256 currentAllowance = s.allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) { // is allowance set to max uint256, then never decrease allowance
            if(currentAllowance < amount) revert ERC20Allowance(); // revert if trying to send more than allowance

            unchecked {
                s.allowance[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "../interfaces/strategies/base/IShortStrategy.sol";
import "../rates/AbstractRateModel.sol";
import "../utils/DelegateCaller.sol";
import "../utils/Pausable.sol";
import "./Refunds.sol";
import "./GammaPoolERC20.sol";

/// @title ERC4626 (GS LP) implementation of GammaPool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Vault implementation of GammaPool, assets are CFMM LP tokens, shares are GS LP tokens
abstract contract GammaPoolERC4626 is GammaPoolERC20, DelegateCaller, Refunds, Pausable {

    error MinShares();

    /// @dev Minimum number of shares issued on first deposit to avoid rounding issues
    uint256 public constant MIN_SHARES = 1e3;

    /// @return address - implementation contract that implements vault logic (e.g. ShortStrategy)
    function vaultImplementation() internal virtual view returns(address);

    /// @return cfmmTotalSupply - latest total supply of LP tokens from CFMM
    function _getLatestCFMMTotalSupply() internal virtual view returns(uint256 cfmmTotalSupply);

    /// @return cfmmInvariant - latest invariant in CFMM
    function _getLatestCFMMInvariant() internal virtual view returns(uint256 cfmmInvariant);

    /// @return cfmmReserves - latest token reserves in the CFMM
    function _getLatestCFMMReserves() internal virtual view returns(uint128[] memory cfmmReserves);

    /// @return lastPrice - latest token reserves in the CFMM
    function _getLastCFMMPrice() internal virtual view returns(uint256 lastPrice);

    // @dev See {Pausable-_pauser}
    function _pauser() internal override virtual view returns(address) {
        return s.factory;
    }

    /// @dev See {Pausable-_functionIds}
    function _functionIds() internal override virtual view returns(uint256) {
        return s.funcIds;
    }

    /// @dev See {Pausable-_setFunctionIds}
    function _setFunctionIds(uint256 _funcIds) internal override virtual {
        s.funcIds = _funcIds;
    }

    /// @return address - CFMM LP token address used for the Vault for accounting, depositing, and withdrawing.
    function asset() external virtual view returns(address) {
        return s.cfmm;
    }

    /// @dev Deposit CFMM LP token and get GS LP token, does a transferFrom according to ERC4626 implementation
    /// @param assets - CFMM LP tokens deposited in exchange for GS LP tokens
    /// @param to - address receiving GS LP tokens
    /// @return shares - quantity of GS LP tokens sent to receiver address (`to`) for CFMM LP tokens
    function deposit(uint256 assets, address to) external virtual whenNotPaused(1) returns (uint256 shares) {
        return abi.decode(callStrategy(vaultImplementation(), abi.encodeCall(IShortStrategy._deposit, (assets, to))), (uint256));
    }

    /// @dev Mint GS LP token in exchange for CFMM LP token deposits, does a transferFrom according to ERC4626 implementation
    /// @param shares - GS LP tokens minted from CFMM LP token deposits
    /// @param to - address receiving GS LP tokens
    /// @return assets - quantity of CFMM LP tokens sent to receiver address (`to`)
    function mint(uint256 shares, address to) external virtual whenNotPaused(2) returns (uint256 assets) {
        return abi.decode(callStrategy(vaultImplementation(), abi.encodeCall(IShortStrategy._mint, (shares, to))), (uint256));
    }

    /// @dev Withdraw CFMM LP token by burning GS LP tokens
    /// @param assets - amount of CFMM LP tokens requested to withdraw in exchange for GS LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address burning its GS LP tokens
    /// @return shares - quantity of GS LP tokens burned
    function withdraw(uint256 assets, address to, address from) external virtual whenNotPaused(3) returns (uint256 shares) {
        return abi.decode(callStrategy(vaultImplementation(), abi.encodeCall(IShortStrategy._withdraw, (assets, to, from))), (uint256));
    }

    /// @dev Redeem GS LP tokens and get CFMM LP token
    /// @param shares - GS LP tokens requested to redeem in exchange for GS LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address redeeming GS LP tokens
    /// @return assets - quantity of CFMM LP tokens sent to receiver address (`to`) for GS LP tokens redeemed
    function redeem(uint256 shares, address to, address from) external virtual whenNotPaused(4) returns (uint256 assets) {
        return abi.decode(callStrategy(vaultImplementation(), abi.encodeCall(IShortStrategy._redeem, (shares, to, from))), (uint256));
    }

    /// @dev Calculates and returns total CFMM LP tokens belonging to liquidity providers using state global variables. It does not update the GammaPool
    /// @return assets - current total CFMM LP tokens (real and virtual) in existence in the GammaPool, including accrued interest
    function totalAssets() public view virtual returns(uint256 assets) {
        (assets,) = _totalAssetsAndSupply();
    }

    /// @dev Get total supply of GS LP tokens, takes into account dilution through protocol revenue
    /// @return supply - total supply of GS LP tokens after taking protocol revenue dilution into account
    function totalSupply() public virtual override view returns(uint256 supply){
        (, supply) = _totalAssetsAndSupply();
    }

    /// @dev Convert CFMM LP tokens to GS LP tokens
    /// @param assets - CFMM LP tokens
    /// @return shares - GS LP tokens quantity that corresponds to assets quantity provided as a parameter (CFMM LP tokens)
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        if(assets == 0) {
            return 0;
        }
        (uint256 _totalAssets, uint256 supply) = _totalAssetsAndSupply();

        if(supply == 0 || _totalAssets == 0) {
            if(assets <= MIN_SHARES) revert MinShares();

            unchecked {
                return assets - MIN_SHARES;
            }
        }
        return (assets * supply) / _totalAssets;
    }

    /// @dev Convert GS LP tokens to GS LP tokens
    /// @param shares - GS LP tokens
    /// @return assets - CFMM LP tokens quantity that corresponds to shares quantity provided as a parameter (GS LP tokens)
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        if(shares == 0) {
            return 0;
        }
        (uint256 assets, uint256 supply) = _totalAssetsAndSupply();
        if(supply == 0) {
            if(shares <= MIN_SHARES) revert MinShares();

            unchecked {
                return shares - MIN_SHARES;
            }
        }
        // totalAssets is total CFMM LP tokens, including accrued interest, calculated using state variables
        return (shares * assets) / supply;
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    /// @param assets - CFMM LP tokens
    /// @return shares - expected GS LP tokens to get from assets (CFMM LP tokens) deposited
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    /// @param shares - GS LP tokens
    /// @return assets - CFMM LP tokens needed to deposit to get the desired shares (GS LP tokens)
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param assets - CFMM LP tokens
    /// @return shares - expected GS LP tokens needed to burn to withdraw desired assets (CFMM LP tokens)
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
    /// @param shares - GS LP tokens
    /// @return assets - expected CFMM LP tokens withdrawn if shares (GS LP tokens) burned
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /// @dev Returns the maximum amount of CFMM LP tokens that can be deposited into the Vault for the receiver, through a deposit call. Ignores address parameter
    /// @return maxAssets - maximum amount of CFMM LP tokens that can be deposited
    function maxDeposit(address) public view virtual returns (uint256) {
        (uint256 assets, uint256 supply) = _totalAssetsAndSupply();
        return assets > 0 || supply == 0 ? type(uint256).max : 0; // no limits on deposits unless pool is a bad state
    }

    /// @dev Returns the maximum amount of the GS LP tokens that can be minted for the receiver, through a mint call. Ignores address parameter
    /// @return maxShares - maximum amount of GS LP tokens that can be minted
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @dev Calculate max CFMM LP tokens available for withdrawal by checking against CFMM LP tokens not borrowed
    /// @param assets - CFMM LP tokens to withdraw
    /// @return maxAssets - maximum CFMM LP tokens available for withdrawal
    function maxAssets(uint256 assets) internal view virtual returns(uint256) {
        uint256 lpTokenBalance = s.LP_TOKEN_BALANCE; // CFMM LP tokens in GammaPool that have not been borrowed
        if(assets < lpTokenBalance){ // limit assets available to withdraw to what has not been borrowed
            return assets;
        }
        return lpTokenBalance;
    }

    /// @dev Returns the maximum amount of CFMM LP tokens that can be withdrawn from the owner balance in the Vault, through a withdraw call.
    /// @param owner - address that owns GS LP tokens
    /// @return maxAssets - maximum amount of CFMM LP tokens that can be withdrawn by owner address
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return maxAssets(convertToAssets(s.balanceOf[owner])); // convert owner GS LP tokens to equivalent CFMM LP tokens and check if available to withdraw
    }

    /// @dev Returns the maximum amount of GS LP tokens that can be redeemed from the owner balance in the Vault, through a redeem call.
    /// @param owner - address that owns GS LP tokens
    /// @return maxShares - maximum amount of GS LP tokens that can be redeemed by owner address
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return convertToShares(maxWithdraw(owner)); // get maximum amount of CFMM LP tokens that can be withdrawn and convert to equivalent GS LP token amount
    }

    /// @dev Calculate and return total CFMM LP tokens belonging to GammaPool liquidity providers using state global variables.
    /// @dev And calculate and return total supply of GS LP tokens taking into account dilution through protocol revenue.
    /// @dev This function does not update the GammaPool
    /// @return assets - current total CFMM LP tokens (real and virtual) in existence in the GammaPool, including accrued interest
    /// @return supply - total supply of GS LP tokens after taking protocol revenue dilution into account
    function _totalAssetsAndSupply() internal view virtual returns (uint256 assets, uint256 supply) {
        IShortStrategy.VaultBalancesParams memory _params;
        _params.factory = s.factory;
        _params.pool = address(this);
        _params.paramsStore = _params.factory;
        _params.BORROWED_INVARIANT = s.BORROWED_INVARIANT;
        _params.latestCfmmInvariant = _getLatestCFMMInvariant();
        _params.latestCfmmTotalSupply = _getLatestCFMMTotalSupply();
        _params.LAST_BLOCK_NUMBER = s.LAST_BLOCK_NUMBER;
        _params.lastCFMMInvariant = s.lastCFMMInvariant;
        _params.lastCFMMTotalSupply = s.lastCFMMTotalSupply;
        _params.lastCFMMFeeIndex = s.lastCFMMFeeIndex;
        _params.totalSupply = s.totalSupply;
        _params.LP_TOKEN_BALANCE = s.LP_TOKEN_BALANCE;
        _params.LP_INVARIANT = s.LP_INVARIANT;

        (assets, supply) = IShortStrategy(vaultImplementation()).totalAssetsAndSupply(_params);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "../interfaces/IGammaPoolExternal.sol";
import "../interfaces/strategies/rebalance/IExternalRebalanceStrategy.sol";
import "../interfaces/strategies/liquidation/IExternalLiquidationStrategy.sol";
import "../utils/DelegateCaller.sol";
import "../utils/Pausable.sol";

/// @title Basic GammaPool smart contract with flash loan functionality
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used as template for building other GammaPool contract implementations with flash loan functionality for other CFMMs
abstract contract GammaPoolExternal is IGammaPoolExternal, DelegateCaller, Pausable {

    /// @dev See {IGammaPool-externalRebalanceStrategy}
    address immutable public override externalRebalanceStrategy;

    /// @dev See {IGammaPool-externalLiquidationStrategy}
    address immutable public override externalLiquidationStrategy;

    /// @dev Initializes the contract by setting `externalRebalanceStrategy`, and `externalLiquidationStrategy`
    constructor(address externalRebalanceStrategy_, address externalLiquidationStrategy_) {
        externalRebalanceStrategy = externalRebalanceStrategy_;
        externalLiquidationStrategy = externalLiquidationStrategy_;
    }

    /// @dev See {IGammaPoolExternal-rebalanceExternally}
    function rebalanceExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external override virtual whenNotPaused(24) returns(uint256 loanLiquidity, uint128[] memory tokensHeld) {
        return abi.decode(callStrategy(externalRebalanceStrategy, abi.encodeCall(IExternalRebalanceStrategy._rebalanceExternally, (tokenId, amounts, lpTokens, to, data))), (uint256, uint128[]));
    }

    /// @dev See {IGammaPoolExternal-liquidateExternally}
    function liquidateExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external override virtual whenNotPaused(25) returns(uint256 loanLiquidity, uint256[] memory refund) {
        return abi.decode(callStrategy(externalLiquidationStrategy, abi.encodeCall(IExternalLiquidationStrategy._liquidateExternally, (tokenId, amounts, lpTokens, to, data))), (uint256, uint256[]));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRefunds.sol";
import "../libraries/GammaSwapLibrary.sol";

/// @title Contract used to handle token transfers by the GammaPool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Abstract contract meant to be inherited by the GammaPool abstract contract to handle token transfers and clearing
abstract contract Refunds is IRefunds {

    error RestrictedToken();
    error NotEnoughTokens();

    /// @dev Remove excess quantities of ERC20 token
    /// @param token - address of ERC20 token that will be transferred
    /// @param balance - quantity of ERC20 token to be expected to remain in GammaPool, excess will be withdrawn
    /// @param to - destination address where ERC20 token will be sent to
    function skim(address token, uint256 balance, address to) internal virtual {
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        if(newBalance > balance) {
            uint256 excessBalance;
            unchecked {
                excessBalance = newBalance - balance;
            }
            GammaSwapLibrary.safeTransfer(token, to, excessBalance);
        }
    }

    /// @dev See {ITransfers-clearToken}
    function clearToken(address token, address to, uint256 minAmt) external override virtual {
        // Can't clear CFMM LP tokens or collateral tokens
        if(isCFMMToken(token) || isCollateralToken(token)) revert RestrictedToken();

        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if(tokenBal < minAmt) revert NotEnoughTokens(); // Only clear if past threshold

        // If not CFMM LP token or collateral token send entire amount
        if (tokenBal > 0) GammaSwapLibrary.safeTransfer(token, to, tokenBal);
    }

    /// @dev Check if ERC20 token is LP token of the CFMM the GammaPool is made for
    /// @param token - address of ERC20 token that will be checked
    /// @return bool - true if it is LP token of the CFMM the GammaPool is made for, false otherwise
    function isCFMMToken(address token) internal virtual view returns(bool);

    /// @dev Check if ERC20 token is a collateral token of the GammaPool
    /// @param token - address of ERC20 token that will be checked
    /// @return bool - true if it is a collateral token of the GammaPool, false otherwise
    function isCollateralToken(address token) internal virtual view returns(bool);
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

/// @title Interface for Pausable contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev All instantiated Pausable contracts must implement this interface so that they can pause individual functions
interface IPausable {

    error ForbiddenPauser();
    error Paused(uint8 _functionId);
    error NotPaused(uint8 _functionId);

    /// @dev Emitted when the pause is triggered by `account`.
    event Pause(address account, uint8 _functionId);

    /// @dev Emitted when the unpause is triggered by `account`.
    event Unpause(address account, uint8 _functionId);

    /// @dev Get uint256 number containing all function id bits at their current state
    /// @return functionIds - uint256 number containing all turned on (paused) function ids
    function functionIds() external view returns(uint256);

    /// @dev Pause a GammaPool's function identified by a `_functionId`
    /// @param _functionId - id of function in GammaPool we want to pause
    /// @return isPaused - true if function identified by `_functionId` is paused
    function isPaused(uint8 _functionId) external view returns (bool);

    /// @dev Pause a GammaPool's function identified by a `_functionId`
    /// @param _functionId - id of function in GammaPool we want to pause
    /// @return _functionIds - uint256 number containing all turned on (paused) function ids
    function pause(uint8 _functionId) external returns (uint256);

    /// @dev Unpause a GammaPool's function identified by a `_functionId`
    /// @param _functionId - id of function in GammaPool we want to unpause
    /// @return _functionIds - uint256 number containing all turned on (paused) function ids
    function unpause(uint8 _functionId) external returns (uint256);
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

    /// @dev Returns same information as getLatestPoolData plus symbol and name of tokens of pool
    /// @param pool - address of pool to get pool data for
    /// @return data - struct containing all relevant global state variables and descriptive information of GammaPool. Used to avoid making multiple calls
    function getLatestPoolDataWithMetaData(address pool) external view returns(IGammaPool.PoolData memory data);

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

/// @title Interface for Loan Observer Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for Loan Observer Store implementations
interface ILoanObserverStore {

    /// @dev Get external collateral reference for a new position being opened
    /// @param refId - address of GammaPool we're setting an external reference for
    /// @param refAddr - address asking collateral reference for (if not permissioned, it should revert. Normally a PositionManager)
    /// @param refFee - discount on origination fee to be applied to loans using collateral reference address
    /// @param refType - discount on origination fee to be applied to loans using collateral reference address
    /// @param active - discount on origination fee to be applied to loans using collateral reference address
    /// @param restricted - discount on origination fee to be applied to loans using collateral reference address
    function setLoanObserver(uint256 refId, address refAddr, uint16 refFee, uint8 refType, bool active, bool restricted) external;

    /// @dev Allow users to create loans in pool that will be observed by observer with reference id `refId`
    /// @param refId - reference id of observer
    /// @param pool - address of GammaPool we are requesting information for
    function setPoolObserved(uint256 refId, address pool) external;

    /// @dev Prohibit users to create loans in pool that will be observed by observer with reference id `refId`
    /// @param refId - reference id of observer
    /// @param pool - address of GammaPool we are requesting information for
    function unsetPoolObserved(uint256 refId, address pool) external;

    /// @dev Check if a pool can use observer
    /// @param refId - reference id of observer
    /// @param pool - address of GammaPool we are requesting information for
    /// @return observed - if true observer can observe loans from pool
    function isPoolObserved(uint256 refId, address pool) external view returns(bool);

    /// @dev Allow a user address to open loans that can be observed by observer
    /// @param refId - reference id of observer
    /// @param user - address that can open loans that use observer
    /// @param isAllowed - if true observer can observe loans created by user
    function allowToBeObserved(uint256 refId, address user, bool isAllowed) external;

    /// @dev Check if a user can open loans that are observed by observer
    /// @param refId - reference id of observer
    /// @param user - address that can open loans that use observer
    /// @return allowed - if true observer can observe loans created by user
    function isAllowedToBeObserved(uint256 refId, address user) external view returns(bool);

    /// @dev Get observer identified with reference id `refId`
    /// @param refId - reference id of information containing collateral reference
    /// @return refAddr - address of ICollateralManager contract. Provides external collateral information
    /// @return refFee - discount for loan associated with this reference id
    /// @return refType - discount for loan associated with this reference id
    /// @return active - discount on origination fee to be applied to loans using collateral reference address
    /// @return restricted - discount on origination fee to be applied to loans using collateral reference address
    function getLoanObserver(uint256 refId) external view returns(address, uint16, uint8, bool, bool);

    /// @dev Get observer for a new loan being opened if the observer exists, the pool is registered with the observer,
    /// @dev and the user is allowed to create loans observed by observer identified by `refId`
    /// @param refId - reference id of information containing collateral reference
    /// @param pool - address asking collateral reference for (if not permissioned, it should revert. Normally a PositionManager)
    /// @param user - address asking collateral reference for
    /// @return refAddr - address of ICollateralManager contract. Provides external collateral information
    /// @return refFee - discount for loan associated with this reference id
    /// @return refType - discount for loan associated with this reference id
    function getPoolObserverByUser(uint16 refId, address pool, address user) external view returns(address, uint16, uint8);
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

import "../events/ILiquidationStrategyEvents.sol";

/// @title Interface for Liquidation Strategy contracts
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Parent interface of every Liquidation strategy
interface ILiquidationStrategy is ILiquidationStrategyEvents {
    /// @return minimum liquidation fee charged during liquidation of a loan
    function liquidationFee() external view returns(uint256);

    /// @dev Check if can liquidate loan based on liquidity debt and collateral
    /// @param liquidity - liquidity debt of loan
    /// @param collateral - liquidity invariant calculated from collateral tokens (`tokensHeld`)
    /// @return canLiquidate - true if loan can be liquidated, false otherwise
    function canLiquidate(uint256 liquidity, uint256 collateral) external view returns(bool);
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
pragma solidity >=0.8.0;

import "../base/ILongStrategy.sol";

/// @title Interface for Repay Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that repay liquidity loans
interface IRepayStrategy is ILongStrategy {

    /// @dev Repay liquidity debt of loan identified by tokenId, using CFMM LP token
    /// @param tokenId - unique id identifying loan
    /// @param collateralId - index of collateral token to rebalance to + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @return liquidityPaid - liquidity amount that has been repaid
    /// @return tokensHeld - remaining token amounts collateralizing loan
    function _repayLiquidityWithLP(uint256 tokenId, uint256 collateralId, address to) external returns(uint256 liquidityPaid, uint128[] memory tokensHeld);

    /// @dev Repay liquidity debt of loan identified by tokenId, debt is repaid using available collateral in loan
    /// @param tokenId - unique id identifying loan
    /// @param liquidity - liquidity debt being repaid, capped at actual liquidity owed. Can't repay more than you owe
    /// @param collateralId - index of collateral token to rebalance to + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @return liquidityPaid - liquidity amount that has been repaid
    /// @return amounts - collateral amounts consumed in repaying liquidity debt
    function _repayLiquidity(uint256 tokenId, uint256 liquidity, uint256 collateralId, address to) external returns(uint256 liquidityPaid, uint256[] memory amounts);

    /// @dev Repay liquidity debt of loan identified by tokenId, debt is repaid using available collateral in loan
    /// @param tokenId - unique id identifying loan
    /// @param liquidity - liquidity debt being repaid, capped at actual liquidity owed. Can't repay more than you owe
    /// @param ratio - weights of collateral after repaying liquidity
    /// @return liquidityPaid - liquidity amount that has been repaid
    /// @return amounts - collateral amounts consumed in repaying liquidity debt
    function _repayLiquiditySetRatio(uint256 tokenId, uint256 liquidity, uint256[] calldata ratio) external returns(uint256 liquidityPaid, uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILiquidationStrategy.sol";

/// @title Interface for Batch Liquidation Strategy contracts
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Defines function to liquidate loans in batch
interface IBatchLiquidationStrategy is ILiquidationStrategy {
    /// @dev Function to liquidate multiple loans in batch.
    /// @param tokenIds - list of tokenIds of loans to liquidate
    /// @return totalLoanLiquidity - total loan liquidity liquidated (after write down)
    /// @return refund - amounts from collateral tokens being refunded to liquidator
    function _batchLiquidations(uint256[] calldata tokenIds) external returns(uint256 totalLoanLiquidity, uint128[] memory refund);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILiquidationStrategy.sol";
import "../events/IExternalStrategyEvents.sol";

/// @title Interface for External Liquidation Strategy contracts
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used to liquidate loans using a flash loan. Purpose of flash loan is for external swaps/rebalance of loan collateral
interface IExternalLiquidationStrategy is ILiquidationStrategy, IExternalStrategyEvents {
    /// @notice The entire pool's collateral is available in the flash loan. Flash loan must result in a net CFMM LP token deposit that repays loan's liquidity debt
    /// @dev Function to liquidate a loan using using a flash loan of collateral tokens from the pool and/or CFMM LP tokens. Seeks full liquidation
    /// @param tokenId - tokenId of loan being liquidated
    /// @param amounts - amount collateral tokens from the pool to flash loan
    /// @param lpTokens - amount of CFMM LP tokens being flash loaned
    /// @param to - address that will receive the collateral tokens and/or lpTokens in flash loan
    /// @param data - optional bytes parameter for custom user defined data
    /// @return loanLiquidity - loan liquidity liquidated (after write down if there's bad debt), flash loan fees added after write down
    /// @return refund - amounts from collateral tokens being refunded to liquidator
    function _liquidateExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external returns(uint256 loanLiquidity, uint128[] memory refund);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILiquidationStrategy.sol";

/// @title Interface for Liquidation Strategy contract used in all strategies
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in liquidation strategie sthat liquidate individual loans using its own collateral, or externa CFMM LP deposits
interface ISingleLiquidationStrategy is ILiquidationStrategy {
    /// @notice When calling this function and adding additional collateral it is assumed that you have sent the collateral first
    /// @dev Function to liquidate a loan using its own collateral or depositing additional tokens. Seeks full liquidation
    /// @param tokenId - tokenId of loan being liquidated
    /// @return loanLiquidity - loan liquidity liquidated (after write down)
    /// @return refund - amount of CFMM LP tokens being refunded to liquidator
    function _liquidate(uint256 tokenId) external returns(uint256 loanLiquidity, uint256 refund);

    /// @dev Function to liquidate a loan using external LP tokens. Allows partial liquidation
    /// @param tokenId - tokenId of loan being liquidated
    /// @return loanLiquidity - loan liquidity liquidated (after write down)
    /// @return refund - amounts from collateral tokens being refunded to liquidator
    function _liquidateWithLP(uint256 tokenId) external returns(uint256 loanLiquidity, uint128[] memory refund);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILongStrategy.sol";
import "../events/IExternalStrategyEvents.sol";

/// @title Interface for External Rebalance Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used to rebalance loan's collateral using a flash loan.
interface IExternalRebalanceStrategy is ILongStrategy, IExternalStrategyEvents {
    /// @dev Flash loan pool's collateral and/or lp tokens to external address. Rebalanced loan collateral is acceptable in  repayment of flash loan
    /// @param tokenId - unique id identifying loan
    /// @param amounts - collateral amounts being flash loaned
    /// @param lpTokens - amount of CFMM LP tokens being flash loaned
    /// @param to - address that will receive flash loan swaps and potentially rebalance loan's collateral
    /// @param data - optional bytes parameter for custom user defined data
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _rebalanceExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external returns(uint256 loanLiquidity, uint128[] memory tokensHeld);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILongStrategy.sol";

/// @title Interface for Rebalance Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that rebalance collateral from liquidity loans
interface IRebalanceStrategy is ILongStrategy {

    /// @dev Rebalance collateral amounts of loan identified by tokenId by purchasing or selling some of the collateral
    /// @param tokenId - unique id identifying loan
    /// @param deltas - collateral amounts being bought or sold (>0 buy, <0 sell), index matches tokensHeld[] index. Only n-1 tokens can be traded
    /// @param ratio - weights of collateral after borrowing liquidity
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _rebalanceCollateral(uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Update pool liquidity debt and loan liquidity debt
    /// @param tokenId - (optional) unique id identifying loan
    /// @return loanLiquidityDebt - updated liquidity debt amount of loan
    /// @return poolLiquidityDebt - updated liquidity debt amount of pool
    function _updatePool(uint256 tokenId) external returns(uint256 loanLiquidityDebt, uint256 poolLiquidityDebt);

    /// @dev Calculate quantities to trade to rebalance collateral to desired `ratio`
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @param ratio - desired ratio of collateral
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function calcDeltasForRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to be able to close the `liquidity` amount
    /// @param tokensHeld - tokens held as collateral for liquidity to pay
    /// @param reserves - reserve token quantities in CFMM
    /// @param liquidity - amount of liquidity to pay
    /// @param collateralId - index of tokensHeld array to rebalance to (e.g. the collateral of the chosen index will be completely used up in repayment)
    /// @return deltas - amounts of collateral to trade to be able to repay `liquidity`
    function calcDeltasToClose(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256 collateralId) external view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to rebalance collateral so that after withdrawing `amounts` we achieve desired `ratio`
    /// @param amounts - amounts that will be withdrawn from collateral
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @param ratio - desired ratio of collateral after withdrawing `amounts`
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function calcDeltasForWithdrawal(uint128[] memory amounts, uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external view returns(int256[] memory deltas);
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

    /// @dev Returns the square root of `a`.
    /// @param a number to square root
    /// @return z square root of a
    function sqrt(uint256 a) internal pure returns (uint256 z) {
        if (a == 0) return 0;

        assembly {
            z := 181 // Should be 1, but this saves a multiplication later.

            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, a))
            r := or(shl(6, lt(0xffffffffffffffffff, shr(r, a))), r)
            r := or(shl(5, lt(0xffffffffff, shr(r, a))), r)
            r := or(shl(4, lt(0xffffff, shr(r, a))), r)
            z := shl(shr(1, r), z)

            // Doesn't overflow since y < 2**136 after above.
            z := shr(18, mul(z, add(shr(r, a), 65536))) // A mul() saved from z = 181.

            // Given worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))

            // If x+1 is a perfect square, the Babylonian method cycles between floor(sqrt(x)) and ceil(sqrt(x)).
            // We always return floor. Source https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(a, z), z))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../interfaces/observer/ILoanObserverStore.sol";
import "../interfaces/IGammaPoolFactory.sol";

/// @title Library containing global storage variables for GammaPools according to App Storage pattern
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Structs are packed to minimize storage size
library LibStorage {

    /// @dev Loan struct used to track relevant liquidity loan information
    struct Loan {
        /// @dev Loan counter, used to generate unique tokenId which indentifies the loan in the GammaPool
        uint256 id;

        // 1x256 bits
        /// @dev GammaPool address loan belongs to
        address poolId; // 160 bits
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

        /// @dev reference address holding additional collateral information for the loan
        address refAddr;
        /// @dev reference fee, typically used for loans using a collateral reference addresses
        uint16 refFee;
        /// @dev reference type, typically used for loans using a collateral reference addresses
        uint8 refType;
    }

    /// @dev Storage struct used to track GammaPool's state variables
    /// @notice `LP_TOKEN_TOTAL = LP_TOKEN_BALANCE + LP_TOKEN_BORROWED_PLUS_INTEREST` and `TOTAL_INVARIANT = BORROWED_INVARIANT + LP_INVARIANT`
    struct Storage {
        // 1x256 bits
        /// @dev factory - address of factory contract that instantiated this GammaPool
        address factory; // 160 bits
        /// @dev Protocol id of the implementation contract for this GammaPool
        uint16 protocolId; // 16 bits
        /// @dev unlocked - flag used in mutex implementation (1 = unlocked, 0 = locked). Initialized at 1
        uint8 unlocked; // 8 bits
        /// @dev EMA of utilization rate
        uint32 emaUtilRate; // 32 bits, 6 decimal number
        /// @dev Multiplier of EMA used to calculate emaUtilRate
        uint8 emaMultiplier; // 8 bits, 1 decimals (0 = 0%, 1 = 0.1%, max 255 = 25.5%)
        /// @dev Minimum utilization rate at which point we start using the dynamic fee
        uint8 minUtilRate1; // 8 bits, 0 decimals (0 = 0%, 100 = 100%), default is 85. If set to 100, dynamic orig fee is disabled
        /// @dev Minimum utilization rate at which point we start using the dynamic fee
        uint8 minUtilRate2; // 8 bits, 0 decimals (0 = 0%, 100 = 100%), default is 65. If set to 100, dynamic orig fee is disabled
        /// @dev Dynamic origination fee divisor, to cap at 99% use 16384 = 2^(99-85)
        uint16 feeDivisor; // 16 bits, 0 decimals, max is 5 digit integer 65535, formula is 2^(maxUtilRate - minUtilRate1)

        // 3x256 bits, LP Tokens
        /// @dev Quantity of CFMM's LP tokens deposited in GammaPool by liquidity providers
        uint256 LP_TOKEN_BALANCE;
        /// @dev Quantity of CFMM's LP tokens that have been borrowed by liquidity borrowers excluding accrued interest (principal)
        uint256 LP_TOKEN_BORROWED;
        /// @dev Quantity of CFMM's LP tokens that have been borrowed by liquidity borrowers including accrued interest
        uint256 LP_TOKEN_BORROWED_PLUS_INTEREST;

        // 1x256 bits, Invariants
        /// @dev Quantity of CFMM's liquidity invariant that has been borrowed including accrued interest, maps to LP_TOKEN_BORROWED_PLUS_INTEREST
        uint128 BORROWED_INVARIANT; // 128 bits
        /// @dev Quantity of CFMM's liquidity invariant held in GammaPool as LP tokens, maps to LP_TOKEN_BALANCE
        uint128 LP_INVARIANT; // 128 bits

        // 3x256 bits, Rates & CFMM
        /// @dev cfmm - address of CFMM this GammaPool is for
        address cfmm; // 160 bits
        /// @dev GammaPool's ever increasing interest rate index, tracks interest accrued through CFMM and liquidity loans, max 120.8% million
        uint80 accFeeIndex; // 80 bits
        /// @dev GammaPool's Margin threshold (1 - 255 => 0.1% to 25.5%) LTV = 1 - ltvThreshold
        uint8 ltvThreshold; // 8 bits
        /// @dev GammaPool's liquidation fee in basis points (1 - 255 => 0.01% to 2.55%)
        uint8 liquidationFee; // 8 bits
        /// @dev External swap fee in basis points, max 255 basis points = 2.55%
        uint8 extSwapFee; // 8 bits
        /// @dev Loan opening origination fee in basis points
        uint16 origFee; // 16 bits
        /// @dev LAST_BLOCK_NUMBER - last block an update to the GammaPool's global storage variables happened
        uint40 LAST_BLOCK_NUMBER; // 40 bits
        /// @dev Percent accrual in CFMM invariant since last update in a different block, max 1,844.67%
        uint64 lastCFMMFeeIndex; // 64 bits
        /// @dev Total liquidity invariant amount in CFMM (from GammaPool and others), read in last update to GammaPool's storage variables
        uint128 lastCFMMInvariant; // 128 bits
        /// @dev Total LP token supply from CFMM (belonging to GammaPool and others), read in last update to GammaPool's storage variables
        uint256 lastCFMMTotalSupply;

        /// @dev The ID of the next loan that will be minted. Initialized at 1
        uint256 nextId;

        /// @dev Function IDs so that we can pause individual functions
        uint256 funcIds;

        // ERC20 fields
        /// @dev Total supply of GammaPool's own ERC20 token representing the liquidity of depositors to the CFMM through the GammaPool
        uint256 totalSupply;
        /// @dev Balance of GammaPool's ERC20 token, this is used to keep track of the balances of different addresses as defined in the ERC20 standard
        mapping(address => uint256) balanceOf;
        /// @dev Spending allowance of GammaPool's ERC20 token, this is used to keep track of the spending allowance of different addresses as defined in the ERC20 standard
        mapping(address => mapping(address => uint256)) allowance;

        /// @dev Mapping of all loans issued by the GammaPool, the key is the tokenId (unique identifier) of the loan
        mapping(uint256 => Loan) loans;

        /// @dev Minimum liquidity that can be borrowed or remain for a loan
        uint72 minBorrow;

        // tokens and balances
        /// @dev ERC20 tokens of CFMM
        address[] tokens;
        /// @dev Decimals of tokens in CFMM, indices match tokens[] array
        uint8[] decimals;
        /// @dev Amounts of ERC20 tokens from the CFMM held as collateral in the GammaPool. Equals to the sum of all tokensHeld[] quantities in all loans
        uint128[] TOKEN_BALANCE;
        /// @dev Amounts of ERC20 tokens from the CFMM held in the CFMM as reserve quantities. Used to log prices quoted by the CFMM during updates to the GammaPool
        uint128[] CFMM_RESERVES;
        /// @dev List of all tokenIds created in GammaPool
        uint256[] tokenIds;

        // Custom parameters
        /// @dev Custom fields
        mapping(uint256 => bytes32) fields;
        /// @dev Custom object (e.g. struct)
        bytes obj;
    }

    error Initialized();

    /// @dev Initializes global storage variables of GammaPool, must be called right after instantiating GammaPool
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param _factory - address of factory that created this GammaPool
    /// @param _cfmm - address of CFMM this GammaPool is for
    /// @param _protocolId - protocol id of the implementation contract for this GammaPool
    /// @param _tokens - tokens of CFMM this GammaPool is for
    /// @param _decimals -decimals of the tokens of the CFMM the GammaPool is for, indices must match tokens array
    /// @param _minBorrow - minimum amount of liquidity that can be borrowed or left unpaid in a loan
    function initialize(Storage storage self, address _factory, address _cfmm, uint16 _protocolId, address[] calldata _tokens, uint8[] calldata _decimals, uint72 _minBorrow) internal {
        if(self.factory != address(0)) revert Initialized();// cannot initialize twice

        self.factory = _factory;
        self.protocolId = _protocolId;
        self.cfmm = _cfmm;
        self.tokens = _tokens;
        self.decimals = _decimals;
        self.minBorrow =_minBorrow;

        self.lastCFMMFeeIndex = 1e18;
        self.accFeeIndex = 1e18; // initialized as 1 with 18 decimal places
        self.LAST_BLOCK_NUMBER = uint40(block.number); // first block update number is block at initialization

        self.nextId = 1; // loan counter starts at 1
        self.unlocked = 1; // mutex initialized as unlocked

        self.ltvThreshold = 5; // 50 basis points
        self.liquidationFee = 25; // 25 basis points
        self.origFee = 2;
        self.extSwapFee = 10;

        self.emaMultiplier = 10; // ema smoothing factor is 10/1000 = 1%
        self.minUtilRate1 = 92; // min util rate 1 is 92%
        self.minUtilRate2 = 80; // min util rate 2 is 80%
        self.feeDivisor = 2048; // 25% orig fee at 99% util rate

        self.TOKEN_BALANCE = new uint128[](_tokens.length);
        self.CFMM_RESERVES = new uint128[](_tokens.length);
    }

    /// @dev Creates an empty loan struct in the GammaPool and initializes it to start tracking borrowed liquidity
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param _tokenCount - number of tokens in the CFMM the loan is for
    /// @param refId - reference id of CollateralManager set up in CollateralReferenceStore (e.g. GammaPoolFactory)
    /// @return _tokenId - unique tokenId used to get and update loan
    function createLoan(Storage storage self, uint256 _tokenCount, uint16 refId) internal returns(uint256 _tokenId) {
        // get loan counter for GammaPool and increase it by 1 for the next loan
        uint256 id = self.nextId++;

        // create unique tokenId to identify loan across all GammaPools. _tokenId is hash of GammaPool address, sender address, and loan counter
        _tokenId = uint256(keccak256(abi.encode(msg.sender, address(this), id)));

        address refAddr;
        uint16 refFee;
        uint8 refType;
        if(refId > 0 ) {
            (refAddr, refFee, refType) = ILoanObserverStore(self.factory).getPoolObserverByUser(refId, address(this), msg.sender);
        }

        // instantiate Loan struct and store it mapped to _tokenId
        self.loans[_tokenId] = Loan({
            id: id, // loan counter
            poolId: address(this), // GammaPool address loan belongs to
            rateIndex: self.accFeeIndex, // initialized as current interest rate index
            initLiquidity: 0,
            liquidity: 0,
            lpTokens: 0,
            tokensHeld: new uint128[](_tokenCount),
            px: 0,
            refAddr: refAddr,
            refFee: refFee,
            refType: refType
        });

        self.tokenIds.push(_tokenId);
    }

    /// @dev Get custom field as uint256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of uint256 field
    /// @return field - value of custom field from storage as uint256
    function getUint256(Storage storage self, uint256 idx) internal view returns(uint256) {
        return uint256(self.fields[idx]);
    }

    /// @dev Set custom field as uint256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of uint256 field
    /// @param val - value of custom field to store in storage as uint256
    function setUint256(Storage storage self, uint256 idx, uint256 val) internal {
        self.fields[idx] = bytes32(val);
    }

    /// @dev Get custom field as int256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of int256 field
    /// @return field - value of custom field from storage as int256
    function getInt256(Storage storage self, uint256 idx) internal view returns(int256) {
        return int256(uint256(self.fields[idx]));
    }

    /// @dev Set custom field as int256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of int256 field
    /// @param val - value of custom field to store in storage as int256
    function setInt256(Storage storage self, uint256 idx, int256 val) internal {
        self.fields[idx] = bytes32(uint256(val));
    }

    /// @dev Get custom field as bytes32
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of bytes32 field
    /// @return field - value of custom field from storage as bytes32
    function getBytes32(Storage storage self, uint256 idx) internal view returns(bytes32) {
        return self.fields[idx];
    }

    /// @dev Set custom field as bytes32
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of bytes32 field
    /// @param val - value of custom field to store in storage as bytes32
    function setBytes32(Storage storage self, uint256 idx, bytes32 val) internal {
        self.fields[idx] = val;
    }

    /// @dev Get custom field as address
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of address field
    /// @return field - value of custom field from storage as address
    function getAddress(Storage storage self, uint256 idx) internal view returns(address) {
        return address(uint160(uint256(self.fields[idx])));
    }

    /// @dev Set custom field as address
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of address field
    /// @param val - value of custom field to store in storage as address
    function setAddress(Storage storage self, uint256 idx, address val) internal {
        self.fields[idx] = bytes32(uint256(uint160(val)));
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../libraries/LibStorage.sol";

/// @title Contract that implements App Storage pattern in GammaPool contracts
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice This pattern is based on Nick Mudge's App Storage implementation (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
/// @dev This contract has to be inherited as the root contract in an inheritance hierarchy
abstract contract AppStorage {

    /// @notice Global storage variables of GammaPool according to App Storage pattern
    /// @dev No other state variable should be defined before this state variable
    LibStorage.Storage internal s;

    error Locked();

    /// @dev Mutex implementation to prevent a contract from calling itself, directly or indirectly.
    modifier lock() {
        _lock();
        _;
        _unlock();
    }

    function _lock() internal {
        if(s.unlocked != 1) revert Locked();
        s.unlocked = 0;
    }

    function _unlock() internal {
        s.unlocked = 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

/// @title Abstract DelegateCaller contract.
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Parent contract to contracts that perform delegate calls. All delegate call logic handled here
abstract contract DelegateCaller {

    /// @dev Implement contract logic via delegate calls of implementation contracts
    /// @param strategy - address of implementation contract
    /// @param data - bytes containing function call and parameters at implementation (`strategy`) contract
    /// @return result - returned data from delegate function call
    function callStrategy(address strategy, bytes memory data) internal virtual returns(bytes memory result) {
        bool success;
        (success, result) = strategy.delegatecall(data);
        if (!success) {
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }
        return result;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../interfaces/IPausable.sol";

/// @title Abstract Pausable contract.
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Abstract implementation of IPausable interface.
/// @dev Pauses individual functions in inherited contract through bit manipulation of a 256 bit number
/// @dev The 256 bit number means there are at most 255 functions that can be paused by turning on the respective bit index that identifies that function
/// @dev If the zeroth bit is turned on, then all pausable functions are paused
abstract contract Pausable is IPausable {

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused(uint8 _functionId) {
        _requireNotPaused(_functionId);
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused. The contract must be paused.
    modifier whenPaused(uint8 _functionId) {
        _requirePaused(_functionId);
        _;
    }

    /// @dev address allowed to pause functions
    function _pauser() internal virtual view returns(address);

    /// @dev 256 bit number whose indices represent the ids of pausable functions
    function _functionIds() internal virtual view returns(uint256);

    /// @dev Update 256 bit number whose indices represent the ids of pausable functions
    function _setFunctionIds(uint256 _funcIds) internal virtual;

    /// @dev See {IPausable-functionIds}
    function functionIds() external override virtual view returns(uint256) {
        return _functionIds();
    }

    // @dev Throws if the contract is paused.
    function _requireNotPaused(uint8 _functionId) internal view virtual {
        if(isPaused(_functionId)) revert Paused(_functionId);
    }

    /// @dev Throws if the contract is not paused.
    function _requirePaused(uint8 _functionId) internal view virtual {
        if(!isPaused(_functionId)) revert NotPaused(_functionId);
    }

    /// @dev See {IPausable-isPaused}
    function isPaused(uint8 _functionId) public override virtual view returns (bool) {
        uint256 funcIds = _functionIds();
        uint256 mask = uint256(1) << _functionId;
        return funcIds == 1 || (funcIds & mask) != 0;
    }

    /// @dev See {IPausable-pause}
    function pause(uint8 _functionId) external override virtual returns (uint256) {
        if(msg.sender != _pauser()) revert ForbiddenPauser();

        uint256 mask = uint256(1) << _functionId;
        uint256 funcIds = _functionIds() | mask;

        _setFunctionIds(funcIds);

        emit Pause(msg.sender, _functionId);

        return funcIds;
    }

    /// @dev See {IPausable-unpause}
    function unpause(uint8 _functionId) external override virtual returns (uint256) {
        if(msg.sender != _pauser()) revert ForbiddenPauser();

        uint256 mask = ~(uint256(1) << _functionId);
        uint256 funcIds = _functionIds() & mask;

        _setFunctionIds(funcIds);

        emit Unpause(msg.sender, _functionId);

        return funcIds;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/base/GammaPool.sol";
import "@gammaswap/v1-core/contracts/base/GammaPoolExternal.sol";
import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "@gammaswap/v1-core/contracts/libraries/GammaSwapLibrary.sol";
import "@gammaswap/v1-core/contracts/libraries/GSMath.sol";

/// @title GammaPool implementation for Constant Product Market Maker
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev This implementation is specifically for validating UniswapV2Pair and clone contracts
contract CPMMGammaPool is GammaPool, GammaPoolExternal {

    error NotContract();
    error BadProtocol();
    error InvalidTokensLength();

    using LibStorage for LibStorage.Storage;

    /// @return cfmmFactory - factory contract that created CFMM
    address immutable public cfmmFactory;

    /// @return cfmmInitCodeHash - init code hash of CFMM
    bytes32 immutable public cfmmInitCodeHash;

    /// @dev Initializes the contract by setting `protocolId`, `factory`, `borrowStrategy`, `repayStrategy`,
    /// @dev `shortStrategy`, `liquidationStrategy`, `batchLiquidationStrategy`, `cfmmFactory`, and `cfmmInitCodeHash`.
    constructor(uint16 _protocolId, address _factory, address _borrowStrategy, address _repayStrategy,
        address _shortStrategy, address _liquidationStrategy, address _batchLiquidationStrategy, address _viewer,
        address _externalRebalanceStrategy, address _externalLiquidationStrategy, address _cfmmFactory, bytes32 _cfmmInitCodeHash)
        GammaPool(_protocolId, _factory, _borrowStrategy, _repayStrategy, _borrowStrategy, _shortStrategy,
        _liquidationStrategy, _batchLiquidationStrategy, _viewer)
        GammaPoolExternal(_externalRebalanceStrategy, _externalLiquidationStrategy) {
        cfmmFactory = _cfmmFactory;
        cfmmInitCodeHash = _cfmmInitCodeHash;
    }

    /// @dev See {IGammaPool-createLoan}
    function createLoan(uint16 refId) external lock virtual override whenNotPaused(9) returns(uint256 tokenId) {
        tokenId = s.createLoan(2, refId); // only 2 token pair
        emit LoanCreated(msg.sender, tokenId, refId);
    }

    /// @dev See {GammaPoolERC4626._calcInvariant}.
    function _calcInvariant(uint128[] memory tokensHeld) internal virtual override view returns(uint256) {
        return GSMath.sqrt(uint256(tokensHeld[0]) * tokensHeld[1]);
    }

    /// @dev See {GammaPoolERC4626._getLastCFMMPrice}.
    function _getLastCFMMPrice() internal virtual override view returns(uint256) {
        uint128[] memory _reserves = _getLatestCFMMReserves();
        if(_reserves[0] == 0) {
            return 0;
        }
        return _reserves[1] * (10 ** s.decimals[0]) / _reserves[0];
    }

    /// @dev See {IGammaPool-validateCFMM}
    function validateCFMM(address[] calldata _tokens, address _cfmm, bytes calldata) external virtual override view returns(address[] memory _tokensOrdered) {
        if(!GammaSwapLibrary.isContract(_cfmm)) revert NotContract(); // Not a smart contract (hence not a CFMM) or not instantiated yet
        if(_tokens.length != 2) revert InvalidTokensLength();

        // Order tokens to match order of tokens in CFMM
        _tokensOrdered = new address[](2);
        (_tokensOrdered[0], _tokensOrdered[1]) = _tokens[0] < _tokens[1] ? (_tokens[0], _tokens[1]) : (_tokens[1], _tokens[0]);

        // Verify CFMM was created by CFMM's factory contract
        if(_cfmm != AddressCalculator.calcAddress(cfmmFactory,keccak256(abi.encodePacked(_tokensOrdered[0], _tokensOrdered[1])),cfmmInitCodeHash)) {
            revert BadProtocol();
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