// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Math } from '../../lib/openzeppelin-contracts/contracts/utils/math/Math.sol';
import { IERC20 } from '../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

import { Constants } from '../utils/Constants.sol';
import { ReentrancyGuard } from '../utils/ReentrancyGuard.sol';
import { ISwapFeeModule, SwapFeeModuleData } from '../swap-fee-modules/interfaces/ISwapFeeModule.sol';
import { ISovereignPool } from './interfaces/ISovereignPool.sol';
import { ISovereignPoolSwapCallback } from './interfaces/ISovereignPoolSwapCallback.sol';
import { IVerifierModule } from './interfaces/IVerifierModule.sol';
import { ALMLiquidityQuoteInput, ALMLiquidityQuote } from '../ALM/structs/SovereignALMStructs.sol';
import { ISovereignVaultMinimal } from './interfaces/ISovereignVaultMinimal.sol';
import { ISovereignALM } from '../ALM/interfaces/ISovereignALM.sol';
import { ISovereignOracle } from '../oracles/interfaces/ISovereignOracle.sol';
import { SovereignPoolConstructorArgs, SwapCache, SovereignPoolSwapParams } from './structs/SovereignPoolStructs.sol';
import { IFlashBorrower } from './interfaces/IFlashBorrower.sol';

/**
    @notice Valantis Sovereign Pool
    @dev Sovereign Pools contain the following Modules:
        - Swap Fee Module (Optional): Calculates swap fees.
        - Algorithmic Liquidity Module (ALM): Contains any kind of DEX logic.
        - Oracle Module (Optional): Can checkpoint swap data in order to
            build time-weighted price and/or volatility estimates.
        - Verifier Module (Optional): Manages custom access conditions for swaps, deposits and withdrawals.
        - Sovereign Vault (Optional): Allows LPs to store the funds in this contract instead of the pool.
            This allows for easier interoperability with other protocols and multi-token pool support.
            If not specified, the pool itself will hold the LPs' reserves.
 */
contract SovereignPool is ISovereignPool, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /************************************************
     *  ENUMS
     ***********************************************/

    /**
        @notice Verifier access types. 
     */
    enum AccessType {
        SWAP,
        DEPOSIT,
        WITHDRAW
    }

    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error SovereignPool__ALMAlreadySet();
    error SovereignPool__excessiveToken0AbsErrorTolerance();
    error SovereignPool__excessiveToken1AbsErrorTolerance();
    error SovereignPool__onlyALM();
    error SovereignPool__onlyGauge();
    error SovereignPool__onlyPoolManager();
    error SovereignPool__onlyProtocolFactory();
    error SovereignPool__sameTokenNotAllowed();
    error SovereignPool__ZeroAddress();
    error SovereignPool__depositLiquidity_depositDisabled();
    error SovereignPool__depositLiquidity_excessiveToken0ErrorOnTransfer();
    error SovereignPool__depositLiquidity_excessiveToken1ErrorOnTransfer();
    error SovereignPool__depositLiquidity_incorrectTokenAmount();
    error SovereignPool__depositLiquidity_insufficientToken0Amount();
    error SovereignPool__depositLiquidity_insufficientToken1Amount();
    error SovereignPool__depositLiquidity_zeroTotalDepositAmount();
    error SovereignPool__getReserves_invalidReservesLength();
    error SovereignPool__setGauge_gaugeAlreadySet();
    error SovereignPool__setGauge_invalidAddress();
    error SovereignPool__setPoolManagerFeeBips_excessivePoolManagerFee();
    error SovereignPool__setSovereignOracle_oracleDisabled();
    error SovereignPool__setSovereignOracle_sovereignOracleAlreadySet();
    error SovereignPool__swap_excessiveSwapFee();
    error SovereignPool__swap_expired();
    error SovereignPool__swap_invalidLiquidityQuote();
    error SovereignPool__swap_invalidPoolTokenOut();
    error SovereignPool__swap_invalidRecipient();
    error SovereignPool__swap_insufficientAmountIn();
    error SovereignPool__swap_invalidSwapTokenOut();
    error SovereignPool__swap_zeroAmountInOrOut();
    error SovereignPool__setSwapFeeModule_timelock();
    error SovereignPool__withdrawLiquidity_withdrawDisabled();
    error SovereignPool__withdrawLiquidity_insufficientReserve0();
    error SovereignPool__withdrawLiquidity_insufficientReserve1();
    error SovereignPool__withdrawLiquidity_invalidRecipient();
    error SovereignPool___claimPoolManagerFees_invalidFeeReceived();
    error SovereignPool___claimPoolManagerFees_invalidProtocolFee();
    error SovereignPool___handleTokenInOnSwap_excessiveTokenInErrorOnTransfer();
    error SovereignPool___handleTokenInOnSwap_invalidTokenInAmount();
    error SovereignPool___verifyPermission_onlyPermissionedAccess(address sender, uint8 accessType);

    /************************************************
     *  CONSTANTS
     ***********************************************/

    /**
        @notice Maximum swap fee is 50% of input amount. 
        @dev See docs for a more detailed explanation about how swap fees are applied.
     */
    uint256 private constant _MAX_SWAP_FEE_BIPS = 10_000;

    /**
        @notice Factor of one or 100% representation in Basis points
     */
    uint256 private constant _FACTOR_ONE = 10_000;

    /**
        @notice `poolManager` can collect up to 50% of swap fees.
     */
    uint256 private constant _MAX_POOL_MANAGER_FEE_BIPS = 5_000;

    /**
        @notice Maximum allowed error tolerance on rebase token transfers.
        @dev    See:  https://github.com/lidofinance/lido-dao/issues/442.
     */
    uint256 private constant _MAX_ABS_ERROR_TOLERANCE = 10;

    /**
        @dev ERC-3156 onFlashLoan callback return data on success. 
     */
    bytes32 private constant _CALLBACK_SUCCESS = keccak256('ERC3156FlashBorrower.onFlashLoan');

    /************************************************
     *  IMMUTABLES
     ***********************************************/

    /**
        @notice Address of Sovereign Vault (Optional), where token reserves will be kept.
        @dev If set as this pool's address, it will work as a typical two token pool.
             Otherwise it can be set as any external vault or singleton. 
        @dev When sovereignVault is not this pool's address:
             - Reserves cannot be kept in the pool, hence `depositLiquidity` and `flashLoan` are disabled.
             - During swaps, input token must be transferred to `sovereignVault`.
             - During swaps, input token can only be token0 or token1.
               But if `sovereignVault != address(this)`, output token can be any other token.
     */
    address public immutable sovereignVault;

    /**
        @notice Address of Protocol Factory. 
     */
    address public immutable protocolFactory;

    /**
        @notice Default pool swap fee in basis-points (bips).
        @dev Can be overriden by whitelisting a Swap Fee Module.
        @dev See docs for a more detailed explanation about how swap fees are applied.
     */
    uint256 public immutable defaultSwapFeeBips;

    /**
        @notice Verifier Module (Optional).
        @dev Verifies custom authentication conditions on deposits, withdrawals and swaps. 
     */
    IVerifierModule private immutable _verifierModule;

    /**
        @notice Tokens supported by this pool.
        @dev These are not necessarily the only tokens
             available to trade against this pool:

             If `sovereignVault` == address(this):
               In this case only `_token0` and `_token1` can be exchanged.
             If `sovereignVault` != address(this):
               In this case `_token0` and `token1` can be the input token for a swap,
               but any other token can be quoted as the output token (given by calling `getTokens`).
     */
    IERC20 private immutable _token0;
    IERC20 private immutable _token1;

    /**
        @notice True if token0 is a rebase token. 
     */
    bool public immutable isToken0Rebase;

    /**
        @notice True if token1 is a rebase token. 
     */
    bool public immutable isToken1Rebase;

    /**
        @notice Maximum absolute error allowed on token0 transfers.
        @dev Only relevant if token0 is a rebase token.
             See: https://github.com/lidofinance/lido-dao/issues/442.
     */
    uint256 public immutable token0AbsErrorTolerance;

    /**
        @notice Maximum absolute error allowed on token1 transfers.
        @dev Only relevant if token1 is a rebase token.
             See: https://github.com/lidofinance/lido-dao/issues/442.
     */
    uint256 public immutable token1AbsErrorTolerance;

    /************************************************
     *  STORAGE
     ***********************************************/

    /**
        @notice Address of Sovereign ALM position bound to this pool.
        @dev Settable by `poolManager` only once. 
     */
    address public alm;

    /**
        @notice Address of Gauge bound to this pool. 
        @dev Settable by `protocolFactory` only once.
     */
    address public gauge;

    /**
        @notice Address of Pool Manager.
        @dev Can optionally set modules and parameters in this pool. 
     */
    address public poolManager;

    /**
        @notice Fraction of swap fees that go into `poolManager`, in bips.
        @dev Remaining fraction goes to LPs.
     */
    uint256 public poolManagerFeeBips;

    /**
        @notice Total token0 and token1 fees accrued by `poolManager`. 
     */
    uint256 public feePoolManager0;
    uint256 public feePoolManager1;

    /**
        @notice token0 and token1 fees donated to Gauges by `poolManager`.
     */
    uint256 public feeProtocol0;
    uint256 public feeProtocol1;

    /**
        @notice Block timestamp at or after which Swap Fee Module can be updated by `poolManager`.
        @dev This is meant to function as a time-lock to prevent `poolManager` from front-run user swaps,
             which could rapidly increase swap fees at arbitrary block times. 
     */
    uint256 public swapFeeModuleUpdateTimestamp;

    /**
        @notice token0 and token1 LP reserves.
     */
    uint256 private _reserve0;
    uint256 private _reserve1;

    /**
        @notice Sovereign Oracle Module (Optional).
        @dev Can accumulate swap data checkpoints and act as an on-chain price or volatility oracle.
     */
    ISovereignOracle private _sovereignOracleModule;

    /**
        @notice Swap Fee Module (Optional).
        @dev Defines custom logic to compute swap fees.
        @dev If not specified, a constant `defaultSwapFeeBips` will be used.
        @dev See docs for a more detailed explanation about how swap fees are applied.
     */
    ISwapFeeModule private _swapFeeModule;

    /************************************************
     *  MODIFIERS
     ***********************************************/

    modifier onlyALM() {
        _onlyALM();
        _;
    }

    modifier onlyProtocolFactory() {
        _onlyProtocolFactory();
        _;
    }

    modifier onlyPoolManager() {
        _onlyPoolManager();
        _;
    }

    modifier onlyGauge() {
        _onlyGauge();
        _;
    }

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor(SovereignPoolConstructorArgs memory args) {
        if (args.token0 == args.token1) {
            revert SovereignPool__sameTokenNotAllowed();
        }

        if (args.token0 == address(0) || args.token1 == address(0)) {
            revert SovereignPool__ZeroAddress();
        }

        sovereignVault = args.sovereignVault == address(0) ? address(this) : args.sovereignVault;

        _verifierModule = IVerifierModule(args.verifierModule);

        _token0 = IERC20(args.token0);
        _token1 = IERC20(args.token1);

        protocolFactory = args.protocolFactory;

        poolManager = args.poolManager;

        isToken0Rebase = args.isToken0Rebase;
        isToken1Rebase = args.isToken1Rebase;

        // Irrelevant in case of non-rebase tokens
        if (args.token0AbsErrorTolerance > _MAX_ABS_ERROR_TOLERANCE) {
            revert SovereignPool__excessiveToken0AbsErrorTolerance();
        }

        if (args.token1AbsErrorTolerance > _MAX_ABS_ERROR_TOLERANCE) {
            revert SovereignPool__excessiveToken1AbsErrorTolerance();
        }

        token0AbsErrorTolerance = args.token0AbsErrorTolerance;
        token1AbsErrorTolerance = args.token1AbsErrorTolerance;

        defaultSwapFeeBips = args.defaultSwapFeeBips <= _MAX_SWAP_FEE_BIPS
            ? args.defaultSwapFeeBips
            : _MAX_SWAP_FEE_BIPS;

        // Initialize timestamp at which Swap Fee Module can be set
        swapFeeModuleUpdateTimestamp = block.timestamp;
    }

    /************************************************
     *  VIEW FUNCTIONS
     ***********************************************/

    /**
        @notice Returns array of tokens available to be swapped against this Sovereign Pool (as tokenOut).
        @dev In case `sovereignVault == address(this)`, only token0 and token1 are available.
             Otherwise, the pool queries `sovereignVault` to retrieve them.
     */
    function getTokens() external view override returns (address[] memory tokens) {
        if (sovereignVault == address(this)) {
            // In this case only token0 and token1 can be swapped
            tokens = new address[](2);

            tokens[0] = address(_token0);
            tokens[1] = address(_token1);
        } else {
            // Data validation should be performed by either caller or `sovereignVault`
            tokens = ISovereignVaultMinimal(sovereignVault).getTokensForPool(address(this));
        }
    }

    /**
        @notice Returns `token0` and `token1` reserves, respectively.
        @dev Reserves are measured differently in case of rebase tokens.
             WARNING: With rebase tokens, balances (hence reserves) can be easily manipulated.
             External contracts MUST be aware and take the right precautions.
        @dev In case `sovereignVault` is not the pool, reserves are queried from `sovereignVault`.
        @dev This function only queries reserves for `token0` and `token1`.
             In case `sovereignVault` supports other tokens, reserves should be queried from it directly.
        @dev This is exposed for convenience. The pool makes no assumptions regarding the way an
             external `sovereignVault` updates reserves internally.
     */
    function getReserves() public view override returns (uint256, uint256) {
        if (sovereignVault == address(this)) {
            return (_getReservesForToken(true), _getReservesForToken(false));
        } else {
            address[] memory tokens = new address[](2);
            tokens[0] = address(_token0);
            tokens[1] = address(_token1);

            uint256[] memory reserves = ISovereignVaultMinimal(sovereignVault).getReservesForPool(
                address(this),
                tokens
            );

            // Only token0 and token1 reserves should be returned
            if (reserves.length != 2) {
                revert SovereignPool__getReserves_invalidReservesLength();
            }

            return (reserves[0], reserves[1]);
        }
    }

    /**
        @notice Returns pool manager fee in amount of token0 and token1.
     */
    function getPoolManagerFees() public view override returns (uint256, uint256) {
        return (feePoolManager0, feePoolManager1);
    }

    /**
        @notice Returns True if this pool contains at least one rebase token. 
     */
    function isRebaseTokenPool() external view override returns (bool) {
        return isToken0Rebase || isToken1Rebase;
    }

    /**
        @notice Returns the address of token0.
     */
    function token0() external view override returns (address) {
        return address(_token0);
    }

    /**
        @notice Returns the address of token1.
     */
    function token1() external view override returns (address) {
        return address(_token1);
    }

    /**
        @notice Returns address of Oracle module in this pool. 
     */
    function sovereignOracleModule() external view override returns (address) {
        return address(_sovereignOracleModule);
    }

    /**
        @notice Returns the address of the swapFeeModule in this pool.
     */
    function swapFeeModule() external view override returns (address) {
        return address(_swapFeeModule);
    }

    /**
        @notice Returns the address of the verifier module in this pool.
     */
    function verifierModule() external view override returns (address) {
        return address(_verifierModule);
    }

    /**
        @notice Exposes the status of reentrancy lock.
        @dev ALMs and other external smart contracts can use it for reentrancy protection. 
             Mainly useful for read-only reentrancy protection.
     */
    function isLocked() external view override returns (bool) {
        return _status == _ENTERED;
    }

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Sets address of `poolManager`.
        @dev Settable by `poolManager`.
        @param _manager Address of new pool manager. 
     */
    function setPoolManager(address _manager) external override onlyPoolManager nonReentrant {
        poolManager = _manager;

        if (_manager == address(0)) {
            poolManagerFeeBips = 0;
            // It will be assumed pool is not going to contribute anything to protocol fees.
            _claimPoolManagerFees(0, 0, msg.sender);
            emit PoolManagerFeeSet(0);
        }

        emit PoolManagerSet(_manager);
    }

    /**
        @notice Set fee in BIPS for `poolManager`.
        @dev Must not be greater than MAX_POOL_MANAGER_FEE_BIPS.
        @dev Settable by `poolManager`.
        @param _poolManagerFeeBips fee to set in BIPS.
     */
    function setPoolManagerFeeBips(uint256 _poolManagerFeeBips) external override onlyPoolManager nonReentrant {
        if (_poolManagerFeeBips > _MAX_POOL_MANAGER_FEE_BIPS) {
            revert SovereignPool__setPoolManagerFeeBips_excessivePoolManagerFee();
        }

        poolManagerFeeBips = _poolManagerFeeBips;

        emit PoolManagerFeeSet(_poolManagerFeeBips);
    }

    /**
        @notice Set Sovereign Oracle Module in this pool.
        @dev Can only be set once by `poolManager`.
        @param sovereignOracle Address of Sovereign Oracle Module instance. 
     */
    function setSovereignOracle(address sovereignOracle) external override onlyPoolManager nonReentrant {
        if (sovereignOracle == address(0)) {
            revert SovereignPool__ZeroAddress();
        }

        if (address(sovereignVault) != address(this)) revert SovereignPool__setSovereignOracle_oracleDisabled();

        if (address(_sovereignOracleModule) != address(0)) {
            revert SovereignPool__setSovereignOracle_sovereignOracleAlreadySet();
        }

        _sovereignOracleModule = ISovereignOracle(sovereignOracle);

        emit SovereignOracleSet(sovereignOracle);
    }

    /**
        @notice Set Gauge in this pool.
        @dev Can only be set once by `protocolFactory`. 
        @param _gauge Address of Gauge instance.
     */
    function setGauge(address _gauge) external override onlyProtocolFactory nonReentrant {
        if (gauge != address(0)) {
            revert SovereignPool__setGauge_gaugeAlreadySet();
        }

        if (_gauge == address(0)) {
            revert SovereignPool__setGauge_invalidAddress();
        }

        gauge = _gauge;

        emit GaugeSet(_gauge);
    }

    /**
        @notice Set Swap Fee Module for this pool.
        @dev Only callable by `poolManager`.
        @dev If set as address(0), a constant default swap fee will be applied.
        @dev It contains a 3 days timelock, to prevent `poolManager` from front-running
             swaps by rapidly increasing swap fees too frequently.
        @param swapFeeModule_ Address of Swap Fee Module to whitelist.
     */
    function setSwapFeeModule(address swapFeeModule_) external override onlyPoolManager nonReentrant {
        // Swap Fee Module cannot be updated too frequently (at most once every 3 days)
        if (block.timestamp < swapFeeModuleUpdateTimestamp) {
            revert SovereignPool__setSwapFeeModule_timelock();
        }

        _swapFeeModule = ISwapFeeModule(swapFeeModule_);
        // Update timestamp at which the next Swap Fee Module update can occur
        swapFeeModuleUpdateTimestamp = block.timestamp + 3 days;

        emit SwapFeeModuleSet(swapFeeModule_);
    }

    /**
        @notice Set ALM for this pool.
        @dev Only callable by `poolManager`.
        @dev Can only be called once.
        @param _alm Address of ALM to whitelist. 
     */
    function setALM(address _alm) external override onlyPoolManager nonReentrant {
        if (_alm == address(0)) {
            revert SovereignPool__ZeroAddress();
        }

        if (alm != address(0)) {
            revert SovereignPool__ALMAlreadySet();
        }

        alm = _alm;

        emit ALMSet(_alm);
    }

    function flashLoan(
        bool _isTokenZero,
        IFlashBorrower _receiver,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant {
        // We disable flash-loans,
        // since reserves are not meant to be stored in the pool
        if (sovereignVault != address(this)) revert ValantisPool__flashLoan_flashLoanDisabled();

        IERC20 flashToken = _isTokenZero ? _token0 : _token1;
        bool isRebaseFlashToken = _isTokenZero ? isToken0Rebase : isToken1Rebase;

        // Flash-loans for rebase tokens are disabled.
        // Easy to manipulate token reserves would significantly
        // increase the attack surface for contracts that rely on this pool
        if (isRebaseFlashToken) {
            revert ValantisPool__flashLoan_rebaseTokenNotAllowed();
        }

        uint256 poolPreBalance = flashToken.balanceOf(address(this));

        flashToken.safeTransfer(address(_receiver), _amount);
        if (_receiver.onFlashLoan(msg.sender, address(flashToken), _amount, _data) != _CALLBACK_SUCCESS) {
            revert ValantisPool__flashloan_callbackFailed();
        }
        flashToken.safeTransferFrom(address(_receiver), address(this), _amount);

        if (flashToken.balanceOf(address(this)) != poolPreBalance) {
            revert ValantisPool__flashLoan_flashLoanNotRepaid();
        }

        emit Flashloan(msg.sender, address(_receiver), _amount, address(flashToken));
    }

    /**
        @notice Claim share of fees accrued by this pool
                And optionally share some with the protocol.
        @dev Only callable by `poolManager`.
        @param _feeProtocol0Bips Amount of `token0` fees to be shared with protocol.
        @param _feeProtocol1Bips Amount of `token1` fees to be shared with protocol.
     */
    function claimPoolManagerFees(
        uint256 _feeProtocol0Bips,
        uint256 _feeProtocol1Bips
    )
        external
        override
        nonReentrant
        onlyPoolManager
        returns (uint256 feePoolManager0Received, uint256 feePoolManager1Received)
    {
        (feePoolManager0Received, feePoolManager1Received) = _claimPoolManagerFees(
            _feeProtocol0Bips,
            _feeProtocol1Bips,
            msg.sender
        );
    }

    /**
        @notice Claim accrued protocol fees, if any.
        @dev Only callable by `gauge`. 
     */
    function claimProtocolFees() external override nonReentrant onlyGauge returns (uint256, uint256) {
        uint256 feeProtocol0Cache = feeProtocol0;
        uint256 feeProtocol1Cache = feeProtocol1;

        if (feeProtocol0Cache > 0) {
            feeProtocol0 = 0;
            _token0.safeTransfer(msg.sender, feeProtocol0Cache);
        }

        if (feeProtocol1Cache > 0) {
            feeProtocol1 = 0;
            _token1.safeTransfer(msg.sender, feeProtocol1Cache);
        }

        return (feeProtocol0Cache, feeProtocol1Cache);
    }

    /**
        @notice Swap against the ALM Position in this pool.
        @param _swapParams Struct containing all params.
               * isSwapCallback If this swap should claim funds using a callback.
               * isZeroToOne Direction of the swap.
               * amountIn Input amount to swap.
               * amountOutMin Minimum output token amount required.
               * deadline Block timestamp after which the swap is no longer valid.
               * recipient Recipient address for output token.
               * swapTokenOut Address of output token.
                 If `sovereignVault != address(this)` it can be other tokens apart from token0 or token1.
               * swapContext Struct containing ALM's external, Verifier's and Swap Callback's context data.
        @return amountInUsed Amount of input token filled by this swap.
        @return amountOut Amount of output token provided by this swap.
     */
    function swap(
        SovereignPoolSwapParams calldata _swapParams
    ) external override nonReentrant returns (uint256 amountInUsed, uint256 amountOut) {
        if (block.timestamp > _swapParams.deadline) {
            revert SovereignPool__swap_expired();
        }

        // Cannot swap zero input token amount
        if (_swapParams.amountIn == 0) {
            revert SovereignPool__swap_insufficientAmountIn();
        }

        if (_swapParams.recipient == address(0)) {
            revert SovereignPool__swap_invalidRecipient();
        }

        SwapCache memory swapCache = SwapCache({
            swapFeeModule: _swapFeeModule,
            tokenInPool: _swapParams.isZeroToOne ? _token0 : _token1,
            tokenOutPool: _swapParams.isZeroToOne ? _token1 : _token0,
            amountInWithoutFee: 0
        });

        if (_swapParams.swapTokenOut == address(0) || _swapParams.swapTokenOut == address(swapCache.tokenInPool)) {
            revert SovereignPool__swap_invalidSwapTokenOut();
        }

        // If reserves are kept in the pool, only token0 <-> token1 swaps are allowed
        if (sovereignVault == address(this) && _swapParams.swapTokenOut != address(swapCache.tokenOutPool)) {
            revert SovereignPool__swap_invalidPoolTokenOut();
        }

        bytes memory verifierData;
        if (address(_verifierModule) != address(0)) {
            // Query Verifier Module to authenticate the swap
            verifierData = _verifyPermission(
                msg.sender,
                _swapParams.swapContext.verifierContext,
                uint8(AccessType.SWAP)
            );
        }

        // Calculate swap fee in bips

        SwapFeeModuleData memory swapFeeModuleData;

        if (address(swapCache.swapFeeModule) != address(0)) {
            swapFeeModuleData = swapCache.swapFeeModule.getSwapFeeInBips(
                address(swapCache.tokenInPool),
                address(swapCache.tokenOutPool),
                _swapParams.amountIn,
                msg.sender,
                _swapParams.swapContext.swapFeeModuleContext
            );
            if (swapFeeModuleData.feeInBips > _MAX_SWAP_FEE_BIPS) {
                revert SovereignPool__swap_excessiveSwapFee();
            }
        } else {
            swapFeeModuleData = SwapFeeModuleData({ feeInBips: defaultSwapFeeBips, internalContext: new bytes(0) });
        }

        // Since we do not yet know how much of `amountIn` will be filled,
        // this quantity is calculated in such a way that `msg.sender`
        // will be charged `feeInBips` of whatever the amount of tokenIn filled
        // ends up being (see docs for more details)
        swapCache.amountInWithoutFee = Math.mulDiv(
            _swapParams.amountIn,
            _MAX_SWAP_FEE_BIPS,
            _MAX_SWAP_FEE_BIPS + swapFeeModuleData.feeInBips
        );

        ALMLiquidityQuote memory liquidityQuote = ISovereignALM(alm).getLiquidityQuote(
            ALMLiquidityQuoteInput({
                isZeroToOne: _swapParams.isZeroToOne,
                amountInMinusFee: swapCache.amountInWithoutFee,
                feeInBips: swapFeeModuleData.feeInBips,
                sender: msg.sender,
                recipient: _swapParams.recipient,
                tokenOutSwap: _swapParams.swapTokenOut
            }),
            _swapParams.swapContext.externalContext,
            verifierData
        );

        amountOut = liquidityQuote.amountOut;

        if (
            !_checkLiquidityQuote(
                _swapParams.isZeroToOne,
                swapCache.amountInWithoutFee,
                liquidityQuote.amountInFilled,
                amountOut,
                _swapParams.amountOutMin
            )
        ) {
            revert SovereignPool__swap_invalidLiquidityQuote();
        }

        // If amountOut or amountInFilled is 0, we do not transfer any input token
        if (amountOut == 0 || liquidityQuote.amountInFilled == 0) {
            revert SovereignPool__swap_zeroAmountInOrOut();
        }

        // Calculate the actual swap fee to be charged in input token (`effectiveFee`),
        // now that we know the tokenIn amount filled
        uint256 effectiveFee;
        if (liquidityQuote.amountInFilled != swapCache.amountInWithoutFee) {
            effectiveFee = Math.mulDiv(
                liquidityQuote.amountInFilled,
                swapFeeModuleData.feeInBips,
                _MAX_SWAP_FEE_BIPS,
                Math.Rounding.Up
            );

            amountInUsed = liquidityQuote.amountInFilled + effectiveFee;
        } else {
            // Using above formula in case amountInWithoutFee == amountInFilled introduces rounding errors
            effectiveFee = _swapParams.amountIn - swapCache.amountInWithoutFee;
            amountInUsed = _swapParams.amountIn;
        }

        _handleTokenInTransfersOnSwap(
            _swapParams.isZeroToOne,
            _swapParams.isSwapCallback,
            swapCache.tokenInPool,
            amountInUsed,
            effectiveFee,
            _swapParams.swapContext.swapCallbackContext
        );

        // Update internal state and oracle module.
        // In case of rebase tokens, `amountInUsed` and `amountOut` might not match
        // the exact balance deltas due to rounding errors.
        _updatePoolStateOnSwap(_swapParams.isZeroToOne, amountInUsed, amountOut, effectiveFee);

        if (
            address(_sovereignOracleModule) != address(0) &&
            _swapParams.swapTokenOut == address(swapCache.tokenOutPool) &&
            amountInUsed > 0
        ) {
            _sovereignOracleModule.writeOracleUpdate(_swapParams.isZeroToOne, amountInUsed, effectiveFee, amountOut);
        }

        // Transfer `amountOut to recipient
        _handleTokenOutTransferOnSwap(IERC20(_swapParams.swapTokenOut), _swapParams.recipient, amountOut);

        // Update state for Swap fee module,
        // only performed if internalContext is non-empty
        if (
            address(swapCache.swapFeeModule) != address(0) &&
            keccak256(swapFeeModuleData.internalContext) != keccak256(new bytes(0))
        ) {
            swapCache.swapFeeModule.callbackOnSwapEnd(effectiveFee, amountInUsed, amountOut, swapFeeModuleData);
        }

        // Perform post-swap callback to liquidity module if necessary
        if (liquidityQuote.isCallbackOnSwap) {
            ISovereignALM(alm).onSwapCallback(_swapParams.isZeroToOne, amountInUsed, amountOut);
        }

        emit Swap(msg.sender, _swapParams.isZeroToOne, amountInUsed, effectiveFee, amountOut);
    }

    /**
        @notice Deposit liquidity into an ALM Position.
        @dev Only callable by its respective active ALM Position.
        @param _amount0 Amount of token0 to deposit.
        @param _amount1 Amount of token1 to deposit. 
        @param _verificationContext Bytes containing verification data required in case of permissioned pool.
        @param _depositData Bytes encoded data for deposit callback.
        @return amount0Deposited Amount of token0 deposited.
        @return amount1Deposited Amount of token1 deposited.
     */
    function depositLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        bytes calldata _verificationContext,
        bytes calldata _depositData
    ) external override onlyALM nonReentrant returns (uint256 amount0Deposited, uint256 amount1Deposited) {
        // We disable deposits,
        // since reserves are not meant to be stored in the pool
        if (sovereignVault != address(this)) revert SovereignPool__depositLiquidity_depositDisabled();

        // At least one token amount must be positive
        if (_amount0 | _amount1 == 0) {
            revert SovereignPool__depositLiquidity_zeroTotalDepositAmount();
        }

        if (address(_verifierModule) != address(0)) {
            _verifyPermission(_sender, _verificationContext, uint8(AccessType.DEPOSIT));
        }

        uint256 token0PreBalance = _token0.balanceOf(address(this));
        uint256 token1PreBalance = _token1.balanceOf(address(this));

        ISovereignALM(msg.sender).onDepositLiquidityCallback(_amount0, _amount1, _depositData);

        amount0Deposited = _token0.balanceOf(address(this)) - token0PreBalance;
        amount1Deposited = _token1.balanceOf(address(this)) - token1PreBalance;

        // Post-deposit checks for token0
        // _amount0 == 0 is interpreted as not depositing token0
        if (_amount0 != 0) {
            if (isToken0Rebase) {
                uint256 amount0AbsDiff = amount0Deposited < _amount0
                    ? _amount0 - amount0Deposited
                    : amount0Deposited - _amount0;

                if (amount0AbsDiff > token0AbsErrorTolerance) {
                    revert SovereignPool__depositLiquidity_excessiveToken0ErrorOnTransfer();
                }
            } else {
                if (amount0Deposited != _amount0) revert SovereignPool__depositLiquidity_insufficientToken0Amount();

                _reserve0 += amount0Deposited;
            }
        } else if (amount0Deposited > 0) {
            revert SovereignPool__depositLiquidity_incorrectTokenAmount();
        }

        // Post-deposit checks for token1
        // _amount1 == 0 is interpreted as not depositing token1
        if (_amount1 != 0) {
            if (isToken1Rebase) {
                uint256 amount1AbsDiff = amount1Deposited < _amount1
                    ? _amount1 - amount1Deposited
                    : amount1Deposited - _amount1;

                if (amount1AbsDiff > token1AbsErrorTolerance) {
                    revert SovereignPool__depositLiquidity_excessiveToken1ErrorOnTransfer();
                }
            } else {
                if (amount1Deposited != _amount1) revert SovereignPool__depositLiquidity_insufficientToken1Amount();

                _reserve1 += amount1Deposited;
            }
        } else if (amount1Deposited > 0) {
            revert SovereignPool__depositLiquidity_incorrectTokenAmount();
        }

        emit DepositLiquidity(amount0Deposited, amount1Deposited);
    }

    /**
        @notice Withdraw liquidity from this pool to an ALM Position.
        @dev Only callable by ALM Position.
        @param _amount0 Amount of token0 reserves to withdraw.
        @param _amount1 Amount of token1 reserves to withdraw.
        @param _recipient Address of recipient.
        @param _verificationContext Bytes containing verfication data required in case of permissioned pool.
     */
    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        address _recipient,
        bytes calldata _verificationContext
    ) external override nonReentrant onlyALM {
        if (_recipient == address(0)) {
            revert SovereignPool__withdrawLiquidity_invalidRecipient();
        }

        // We disable withdrawals,
        // since reserves are not meant to be stored in the pool
        if (sovereignVault != address(this)) revert SovereignPool__withdrawLiquidity_withdrawDisabled();

        if (address(_verifierModule) != address(0)) {
            _verifyPermission(_sender, _verificationContext, uint8(AccessType.WITHDRAW));
        }

        if (_amount0 > _getReservesForToken(true)) {
            revert SovereignPool__withdrawLiquidity_insufficientReserve0();
        }

        if (_amount1 > _getReservesForToken(false)) {
            revert SovereignPool__withdrawLiquidity_insufficientReserve1();
        }

        // Already checked above
        unchecked {
            if (!isToken0Rebase) _reserve0 -= _amount0;

            if (!isToken1Rebase) _reserve1 -= _amount1;
        }

        if (_amount0 > 0) {
            _token0.safeTransfer(_recipient, _amount0);
        }

        if (_amount1 > 0) {
            _token1.safeTransfer(_recipient, _amount1);
        }

        emit WithdrawLiquidity(_recipient, _amount0, _amount1);
    }

    /************************************************
     *  PRIVATE FUNCTIONS
     ***********************************************/

    function _claimPoolManagerFees(
        uint256 _feeProtocol0Bips,
        uint256 _feeProtocol1Bips,
        address _recipient
    ) private returns (uint256 feePoolManager0Received, uint256 feePoolManager1Received) {
        if (_feeProtocol0Bips > _FACTOR_ONE || _feeProtocol1Bips > _FACTOR_ONE) {
            revert SovereignPool___claimPoolManagerFees_invalidProtocolFee();
        }

        (feePoolManager0Received, feePoolManager1Received) = getPoolManagerFees();

        // Attempt to claim pool manager fees from `sovereignVault`
        // This is necessary since in this case reserves are not kept in this pool
        if (sovereignVault != address(this)) {
            uint256 token0PreBalance = _token0.balanceOf(address(this));
            uint256 token1PreBalance = _token1.balanceOf(address(this));

            ISovereignVaultMinimal(sovereignVault).claimPoolManagerFees(
                feePoolManager0Received,
                feePoolManager1Received
            );

            uint256 fee0ReceivedCache = _token0.balanceOf(address(this)) - token0PreBalance;
            uint256 fee1ReceivedCache = _token1.balanceOf(address(this)) - token1PreBalance;

            // Cannot transfer in excess, otherwise it would be possible to manipulate this pool's
            // fair share of earned swap fees
            if (fee0ReceivedCache > feePoolManager0Received || fee1ReceivedCache > feePoolManager1Received) {
                revert SovereignPool___claimPoolManagerFees_invalidFeeReceived();
            }

            feePoolManager0Received = fee0ReceivedCache;
            feePoolManager1Received = fee1ReceivedCache;
        }

        uint256 protocolFee0 = Math.mulDiv(_feeProtocol0Bips, feePoolManager0Received, _FACTOR_ONE);
        uint256 protocolFee1 = Math.mulDiv(_feeProtocol1Bips, feePoolManager1Received, _FACTOR_ONE);

        feeProtocol0 += protocolFee0;
        feeProtocol1 += protocolFee1;

        feePoolManager0 = 0;
        feePoolManager1 = 0;

        feePoolManager0Received -= protocolFee0;
        feePoolManager1Received -= protocolFee1;

        if (feePoolManager0Received > 0) {
            _token0.safeTransfer(_recipient, feePoolManager0Received);
        }

        if (feePoolManager1Received > 0) {
            _token1.safeTransfer(_recipient, feePoolManager1Received);
        }

        emit PoolManagerFeesClaimed(feePoolManager0Received, feePoolManager1Received);
    }

    function _verifyPermission(
        address sender,
        bytes calldata verificationContext,
        uint8 accessType
    ) private returns (bytes memory verifierData) {
        bool success;

        (success, verifierData) = _verifierModule.verify(sender, verificationContext, accessType);

        if (!success) {
            revert SovereignPool___verifyPermission_onlyPermissionedAccess(sender, accessType);
        }
    }

    function _handleTokenInTransfersOnSwap(
        bool isZeroToOne,
        bool isSwapCallback,
        IERC20 token,
        uint256 amountInUsed,
        uint256 effectiveFee,
        bytes calldata _swapCallbackContext
    ) private {
        uint256 preBalance = token.balanceOf(sovereignVault);

        if (isSwapCallback) {
            ISovereignPoolSwapCallback(msg.sender).sovereignPoolSwapCallback(
                address(token),
                amountInUsed,
                _swapCallbackContext
            );
        } else {
            token.safeTransferFrom(msg.sender, sovereignVault, amountInUsed);
        }

        uint256 amountInReceived = token.balanceOf(sovereignVault) - preBalance;

        bool isTokenInRebase = isZeroToOne ? isToken0Rebase : isToken1Rebase;

        if (isTokenInRebase) {
            uint256 tokenInAbsDiff = amountInUsed > amountInReceived
                ? amountInUsed - amountInReceived
                : amountInReceived - amountInUsed;

            uint256 tokenInAbsErrorTolerance = isZeroToOne ? token0AbsErrorTolerance : token1AbsErrorTolerance;
            if (tokenInAbsDiff > tokenInAbsErrorTolerance)
                revert SovereignPool___handleTokenInOnSwap_excessiveTokenInErrorOnTransfer();
        } else {
            if (amountInReceived != amountInUsed) revert SovereignPool___handleTokenInOnSwap_invalidTokenInAmount();
        }

        if (isTokenInRebase && sovereignVault == address(this) && poolManager != address(0)) {
            // We transfer manager fee to `poolManager`
            uint256 poolManagerFee = Math.mulDiv(effectiveFee, poolManagerFeeBips, _FACTOR_ONE);
            if (poolManagerFee > 0) {
                token.safeTransfer(poolManager, poolManagerFee);
            }
        }
    }

    function _handleTokenOutTransferOnSwap(IERC20 swapTokenOut, address recipient, uint256 amountOut) private {
        if (sovereignVault == address(this)) {
            // In this case, tokenOut should be transferred from this pool to `recipient`
            swapTokenOut.safeTransfer(recipient, amountOut);
        } else {
            // If `sovereignVault` is not this pool,
            // ALM must have already approved this pool to send `amountOut` to `recipient`
            swapTokenOut.safeTransferFrom(sovereignVault, recipient, amountOut);
        }
    }

    function _updatePoolStateOnSwap(
        bool isZeroToOne,
        uint256 amountInUsed,
        uint256 amountOut,
        uint256 effectiveFee
    ) private {
        if (isZeroToOne) {
            if (!isToken0Rebase) {
                uint256 poolManagerFee = Math.mulDiv(effectiveFee, poolManagerFeeBips, _FACTOR_ONE);

                if (sovereignVault == address(this)) _reserve0 += (amountInUsed - poolManagerFee);
                if (poolManagerFee > 0) feePoolManager0 += poolManagerFee;
            }

            if (sovereignVault == address(this) && !isToken1Rebase) {
                _reserve1 -= amountOut;
            }
        } else {
            if (sovereignVault == address(this) && !isToken0Rebase) {
                _reserve0 -= amountOut;
            }

            if (!isToken1Rebase) {
                uint256 poolManagerFee = Math.mulDiv(effectiveFee, poolManagerFeeBips, _FACTOR_ONE);

                if (sovereignVault == address(this)) _reserve1 += (amountInUsed - poolManagerFee);
                if (poolManagerFee > 0) feePoolManager1 += poolManagerFee;
            }
        }
    }

    function _onlyALM() private view {
        if (msg.sender != alm) {
            revert SovereignPool__onlyALM();
        }
    }

    function _onlyProtocolFactory() private view {
        if (msg.sender != protocolFactory) {
            revert SovereignPool__onlyProtocolFactory();
        }
    }

    function _onlyPoolManager() private view {
        if (msg.sender != poolManager) {
            revert SovereignPool__onlyPoolManager();
        }
    }

    function _onlyGauge() private view {
        if (msg.sender != gauge) {
            revert SovereignPool__onlyGauge();
        }
    }

    function _getReservesForToken(bool isToken0) private view returns (uint256 reserve) {
        if (isToken0) {
            if (isToken0Rebase) {
                reserve = _token0.balanceOf(address(this));
            } else {
                reserve = _reserve0;
            }
        } else {
            if (isToken1Rebase) {
                reserve = _token1.balanceOf(address(this));
            } else {
                reserve = _reserve1;
            }
        }
    }

    function _checkLiquidityQuote(
        bool isZeroToOne,
        uint256 amountInWithoutFee,
        uint256 amountInFilled,
        uint256 amountOut,
        uint256 amountOutMin
    ) private view returns (bool) {
        // We only compare against pool reserves if they are meant to be stored in it
        if (sovereignVault == address(this)) {
            if (amountOut > _getReservesForToken(!isZeroToOne)) {
                return false;
            }
        }

        if (amountOut < amountOutMin) {
            return false;
        }

        if (amountInFilled > amountInWithoutFee) {
            return false;
        }

        return true;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Constants {
    uint256 public constant Q128 = 1 << 128;

    uint256 public constant Q64 = 1 << 64;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @notice Adapted from:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.3/contracts/security/ReentrancyGuard.sol
    @dev Uses internal variables and functions
         so that child contracts can be explicit about view-function reentrancy risk.
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
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    uint256 internal _status;

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

    function _nonReentrantBefore() internal {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @notice Struct returned by the swapFeeModule during the getSwapFeeInBips call.
    * feeInBips: The swap fee in bips.
    * internalContext: Arbitrary bytes context data.
 */
struct SwapFeeModuleData {
    uint256 feeInBips;
    bytes internalContext;
}

interface ISwapFeeModuleMinimal {
    /**
        @notice Returns the swap fee in bips for both Universal & Sovereign Pools.
        @param _tokenIn The address of the token that the user wants to swap.
        @param _tokenOut The address of the token that the user wants to receive.
        @param _amountIn The amount of tokenIn being swapped.
        @param _user The address of the user.
        @param _swapFeeModuleContext Arbitrary bytes data which can be sent to the swap fee module.
        @return swapFeeModuleData A struct containing the swap fee in bips, and internal context data.
     */
    function getSwapFeeInBips(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _user,
        bytes memory _swapFeeModuleContext
    ) external returns (SwapFeeModuleData memory swapFeeModuleData);
}

interface ISwapFeeModule is ISwapFeeModuleMinimal {
    /**
        @notice Callback function called by the pool after the swap has finished. ( Universal Pools )
        @param _effectiveFee The effective fee charged for the swap.
        @param _spotPriceTick The spot price tick after the swap.
        @param _amountInUsed The amount of tokenIn used for the swap.
        @param _amountOut The amount of the tokenOut transferred to the user.
        @param _swapFeeModuleData The context data returned by getSwapFeeInBips.
     */
    function callbackOnSwapEnd(
        uint256 _effectiveFee,
        int24 _spotPriceTick,
        uint256 _amountInUsed,
        uint256 _amountOut,
        SwapFeeModuleData memory _swapFeeModuleData
    ) external;

    /**
        @notice Callback function called by the pool after the swap has finished. ( Sovereign Pools )
        @param _effectiveFee The effective fee charged for the swap.
        @param _amountInUsed The amount of tokenIn used for the swap.
        @param _amountOut The amount of the tokenOut transferred to the user.
        @param _swapFeeModuleData The context data returned by getSwapFeeInBips.
     */
    function callbackOnSwapEnd(
        uint256 _effectiveFee,
        uint256 _amountInUsed,
        uint256 _amountOut,
        SwapFeeModuleData memory _swapFeeModuleData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IValantisPool } from '../interfaces/IValantisPool.sol';
import { PoolLocks } from '../structs/ReentrancyGuardStructs.sol';
import { SovereignPoolSwapContextData, SovereignPoolSwapParams } from '../structs/SovereignPoolStructs.sol';

interface ISovereignPool is IValantisPool {
    event SwapFeeModuleSet(address swapFeeModule);
    event ALMSet(address alm);
    event GaugeSet(address gauge);
    event PoolManagerSet(address poolManager);
    event PoolManagerFeeSet(uint256 poolManagerFeeBips);
    event SovereignOracleSet(address sovereignOracle);
    event PoolManagerFeesClaimed(uint256 amount0, uint256 amount1);
    event DepositLiquidity(uint256 amount0, uint256 amount1);
    event WithdrawLiquidity(address indexed recipient, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, bool isZeroToOne, uint256 amountIn, uint256 fee, uint256 amountOut);

    function getTokens() external view returns (address[] memory tokens);

    function sovereignVault() external view returns (address);

    function protocolFactory() external view returns (address);

    function gauge() external view returns (address);

    function poolManager() external view returns (address);

    function sovereignOracleModule() external view returns (address);

    function swapFeeModule() external view returns (address);

    function verifierModule() external view returns (address);

    function isLocked() external view returns (bool);

    function isRebaseTokenPool() external view returns (bool);

    function poolManagerFeeBips() external view returns (uint256);

    function defaultSwapFeeBips() external view returns (uint256);

    function swapFeeModuleUpdateTimestamp() external view returns (uint256);

    function alm() external view returns (address);

    function getPoolManagerFees() external view returns (uint256 poolManagerFee0, uint256 poolManagerFee1);

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);

    function setPoolManager(address _manager) external;

    function setGauge(address _gauge) external;

    function setPoolManagerFeeBips(uint256 _poolManagerFeeBips) external;

    function setSovereignOracle(address sovereignOracle) external;

    function setSwapFeeModule(address _swapFeeModule) external;

    function setALM(address _alm) external;

    function swap(SovereignPoolSwapParams calldata _swapParams) external returns (uint256, uint256);

    function depositLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        bytes calldata _verificationContext,
        bytes calldata _depositData
    ) external returns (uint256 amount0Deposited, uint256 amount1Deposited);

    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        address _recipient,
        bytes calldata _verificationContext
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISovereignPoolSwapCallback {
    /**
        @notice Function called by Sovereign Pool during a swap, to transfer the funds.
        @dev This function is only called if isSwapCallback is set to true in swapParams.
        @param _tokenIn The address of the token that the user wants to swap.
        @param _amountInUsed The amount of the tokenIn used for the swap.
        @param _swapCallbackContext Arbitrary bytes data which can be sent to the swap callback.
     */
    function sovereignPoolSwapCallback(
        address _tokenIn,
        uint256 _amountInUsed,
        bytes calldata _swapCallbackContext
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVerifierModule {
    /**
        @notice Used to verify user access to important pool functions.
        @param _user The address of the user.
        @param _verificationContext Arbitrary bytes data which can be sent to the verifier module.
        @param accessType The type of function being called, can be - SWAP(0), DEPOSIT(1), or WITHDRAW(2).
        @return success True if the user is verified, false otherwise.
        @return returnData Additional data which can be passed along to the LM in case of a swap.
     */
    function verify(
        address _user,
        bytes calldata _verificationContext,
        uint8 accessType
    ) external returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct ALMLiquidityQuoteInput {
    bool isZeroToOne;
    uint256 amountInMinusFee;
    uint256 feeInBips;
    address sender;
    address recipient;
    address tokenOutSwap;
}

struct ALMLiquidityQuote {
    bool isCallbackOnSwap;
    uint256 amountOut;
    uint256 amountInFilled;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @title Minimal interface for Sovereign Pool's custom vault.
    @dev Sovereign Pools can choose to store their token0 and token1
         reserves in this contract.
         Sovereign Vault allows LPs to define where funds should be stored
         on deposits, withdrawals and swaps. Examples:
         - A custom LP vault which can provide liquidity to multiple pools on request.
         - A singleton contract.
         - Any external protocol that provides liquidity to incoming swaps on request.
         Moreover, it supports any number of tokens.
    @dev This is meant to be a minimal interface, containing only the functions
         required for Sovereign Pools to interact with.
 */
interface ISovereignVaultMinimal {
    /**
        @notice Returns array of tokens which can be swapped against for a given Sovereign Pool.
        @param _pool Sovereign Pool to query tokens for.
     */
    function getTokensForPool(address _pool) external view returns (address[] memory);

    /**
        @notice Returns reserve amounts available for a given Sovereign Pool.
        @param _pool Sovereign Pool to query token reserves for.
        @param _tokens Token addresses to query reserves for.
        @dev The full array of available tokens can be retrieved by calling `getTokensForPool` beforehand.
     */
    function getReservesForPool(address _pool, address[] calldata _tokens) external view returns (uint256[] memory);

    /**
        @notice Allows pool to attempt to claim due amount of `poolManager` fees.
        @dev Only callable by a Sovereign Pool. 
        @dev This is required, since on every swap, input token amounts are transferred
             from user into `sovereignVault`, to save on gas. Hence manager fees
             can only be claimed via this separate call.
        @param _feePoolManager0 Amount of token0 due to `poolManager`.
        @param _feePoolManager1 Amount of token1 due to `poolManager`.
     */
    function claimPoolManagerFees(uint256 _feePoolManager0, uint256 _feePoolManager1) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ALMLiquidityQuoteInput, ALMLiquidityQuote } from '../structs/SovereignALMStructs.sol';

/**
    @title Sovereign ALM interface
    @notice All ALMs bound to a Sovereign Pool must implement it.
 */
interface ISovereignALM {
    /** 
        @notice Called by the Sovereign pool to request a liquidity quote from the ALM.
        @param _almLiquidityQuoteInput Contains fundamental data about the swap.
        @param _externalContext Data received by the pool from the user.
        @param _verifierData Verification data received by the pool from the verifier module
        @return almLiquidityQuote Liquidity quote containing tokenIn and tokenOut amounts filled.
    */
    function getLiquidityQuote(
        ALMLiquidityQuoteInput memory _almLiquidityQuoteInput,
        bytes calldata _externalContext,
        bytes calldata _verifierData
    ) external returns (ALMLiquidityQuote memory);

    /**
        @notice Callback function for `depositLiquidity` .
        @param _amount0 Amount of token0 being deposited.
        @param _amount1 Amount of token1 being deposited.
        @param _data Context data passed by the ALM, while calling `depositLiquidity`.
    */
    function onDepositLiquidityCallback(uint256 _amount0, uint256 _amount1, bytes memory _data) external;

    /**
        @notice Callback to ALM after swap into liquidity pool.
        @dev Only callable by pool.
        @param _isZeroToOne Direction of swap.
        @param _amountIn Amount of tokenIn in swap.
        @param _amountOut Amount of tokenOut in swap. 
     */
    function onSwapCallback(bool _isZeroToOne, uint256 _amountIn, uint256 _amountOut) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISovereignOracle {
    /**
        @notice Returns the address of the pool associated with the oracle.
        @return pool The address of the pool.
     */
    function pool() external view returns (address);

    /**
        @notice Writes an update to the oracle after a swap in the Sovereign Pool.
        @param isZeroToOne True if the swap is from token0 to token1, false otherwise.
        @param amountInMinusFee The amount of the tokenIn used minus fees.
        @param fee The fee amount.
        @param amountOut The amount of the tokenOut transferred to the user.
     */
    function writeOracleUpdate(bool isZeroToOne, uint256 amountInMinusFee, uint256 fee, uint256 amountOut) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from '../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import { ISwapFeeModule } from '../../swap-fee-modules/interfaces/ISwapFeeModule.sol';

struct SovereignPoolConstructorArgs {
    address token0;
    address token1;
    address protocolFactory;
    address poolManager;
    address sovereignVault;
    address verifierModule;
    bool isToken0Rebase;
    bool isToken1Rebase;
    uint256 token0AbsErrorTolerance;
    uint256 token1AbsErrorTolerance;
    uint256 defaultSwapFeeBips;
}

struct SovereignPoolSwapContextData {
    bytes externalContext;
    bytes verifierContext;
    bytes swapCallbackContext;
    bytes swapFeeModuleContext;
}

struct SwapCache {
    ISwapFeeModule swapFeeModule;
    IERC20 tokenInPool;
    IERC20 tokenOutPool;
    uint256 amountInWithoutFee;
}

struct SovereignPoolSwapParams {
    bool isSwapCallback;
    bool isZeroToOne;
    uint256 amountIn;
    uint256 amountOutMin;
    uint256 deadline;
    address recipient;
    address swapTokenOut;
    SovereignPoolSwapContextData swapContext;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFlashBorrower {
    /**
        @dev Receive a flash loan.
        @param initiator The initiator of the loan.
        @param token The loan currency.
        @param amount The amount of tokens lent.
        @param data Arbitrary data structure, intended to contain user-defined parameters.
        @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32);
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
pragma solidity 0.8.19;

import { IFlashBorrower } from './IFlashBorrower.sol';

interface IValantisPool {
    /************************************************
     *  EVENTS
     ***********************************************/

    event Flashloan(address indexed initiator, address indexed receiver, uint256 amount, address token);

    /************************************************
     *  ERRORS
     ***********************************************/

    error ValantisPool__flashloan_callbackFailed();
    error ValantisPool__flashLoan_flashLoanDisabled();
    error ValantisPool__flashLoan_flashLoanNotRepaid();
    error ValantisPool__flashLoan_rebaseTokenNotAllowed();

    /************************************************
     *  VIEW FUNCTIONS
     ***********************************************/

    /**
        @notice Address of ERC20 token0 of the pool.
     */
    function token0() external view returns (address);

    /**
        @notice Address of ERC20 token1 of the pool.
     */
    function token1() external view returns (address);

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Claim share of protocol fees accrued by this pool.
        @dev Can only be claimed by `gauge` of the pool. 
     */
    function claimProtocolFees() external returns (uint256, uint256);

    /**
        @notice Claim share of fees accrued by this pool
                And optionally share some with the protocol.
        @dev Only callable by `poolManager`.
        @param _feeProtocol0Bips Percent of `token0` fees to be shared with protocol.
        @param _feeProtocol1Bips Percent of `token1` fees to be shared with protocol.
     */
    function claimPoolManagerFees(
        uint256 _feeProtocol0Bips,
        uint256 _feeProtocol1Bips
    ) external returns (uint256 feePoolManager0Received, uint256 feePoolManager1Received);

    /**
        @notice Sets the gauge contract address for the pool.
        @dev Only callable by `protocolFactory`.
        @dev Once a gauge is set it cannot be changed again.
        @param _gauge address of the gauge.
     */
    function setGauge(address _gauge) external;

    /**
        @notice Allows anyone to flash loan any amount of tokens from the pool.
        @param _isTokenZero True if token0 is being flash loaned, False otherwise.
        @param _receiver Address of the flash loan receiver.
        @param _amount Amount of tokens to be flash loaned.
        @param _data Bytes encoded data for flash loan callback.
     */
    function flashLoan(bool _isTokenZero, IFlashBorrower _receiver, uint256 _amount, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum Lock {
    WITHDRAWAL,
    DEPOSIT,
    SWAP,
    SPOT_PRICE_TICK
}

struct PoolLocks {
    /**
        @notice Locks all functions that require any withdrawal of funds from the pool
                This involves the following functions -
                * withdrawLiquidity
                * claimProtocolFees
                * claimPoolManagerFees
     */
    uint8 withdrawals;
    /**
        @notice Only locks the deposit function
    */
    uint8 deposit;
    /**
        @notice Only locks the swap function
    */
    uint8 swap;
    /**
        @notice Only locks the spotPriceTick function
    */
    uint8 spotPriceTick;
}