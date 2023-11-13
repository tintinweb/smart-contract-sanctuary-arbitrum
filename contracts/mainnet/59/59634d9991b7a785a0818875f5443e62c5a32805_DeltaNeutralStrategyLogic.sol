// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPoolAddressesProvider} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPool} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {IVariableDebtToken} from "@aave/aave-v3-core/contracts/interfaces/IVariableDebtToken.sol";
import {IAToken} from "@aave/aave-v3-core/contracts/interfaces/IAToken.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import {IWETH9} from "../../interfaces/external/IWETH9.sol";
import {IV3SwapRouter} from "../../interfaces/external/IV3SwapRouter.sol";
import {IAaveCheckerLogic} from "../../interfaces/checkers/IAaveCheckerLogic.sol";
import {IDeltaNeutralStrategyLogic} from "../../interfaces/ourLogic/IDeltaNeutralStrategyLogic.sol";

import {TransferHelper} from "../../libraries/utils/TransferHelper.sol";
import {BaseContract, Constants} from "../../libraries/BaseContract.sol";

import {DexLogicLib} from "../../libraries/DexLogicLib.sol";
import {AaveLogicLib} from "../../libraries/AaveLogicLib.sol";

/// @title Delta Neutral Strategy Logic for DeFi protocols Uniswap and Aave.
/// @dev Contract to implement delta neutral strategy using Aave and Uniswap V3.
contract DeltaNeutralStrategyLogic is IDeltaNeutralStrategyLogic, BaseContract {
    // =========================
    // Constructor and constants
    // =========================

    IPoolAddressesProvider private immutable aavePoolAddressesProvider;

    IUniswapV3Factory private immutable dexFactory;
    IV3SwapRouter private immutable dexRouter;
    INonfungiblePositionManager internal immutable dexNftPositionManager;

    IWETH9 private immutable wrappedNative;

    uint128 private constant E18 = 1e18;
    uint128 private constant E14 = 1e14;
    uint32 private constant PERIOD = 60;

    /// @notice Initialize immutable variables in the contract.
    /// @param _poolAddressesProvider The Aave pool addresses provider.
    /// @param _dexFactory The Uniswap V3 factory.
    /// @param _dexNftPositionManager The position manager for Uniswap V3 NFTs.
    /// @param _wrappedNative The wrapped native token used for wrapping/unwrapping.
    /// @param _dexRouter The Uniswap V3 router.
    constructor(
        IPoolAddressesProvider _poolAddressesProvider,
        IUniswapV3Factory _dexFactory,
        INonfungiblePositionManager _dexNftPositionManager,
        IWETH9 _wrappedNative,
        IV3SwapRouter _dexRouter
    ) {
        aavePoolAddressesProvider = _poolAddressesProvider;

        dexFactory = _dexFactory;
        dexRouter = _dexRouter;
        dexNftPositionManager = _dexNftPositionManager;

        wrappedNative = _wrappedNative;
    }

    // =========================
    // Storage
    // =========================

    /// @dev Storage position for the DNS, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    bytes32 private immutable DNS_COMMON_STORAGE =
        keccak256("vault.dns.common.storage");

    /// @dev Common storage structure used to check initialization status.
    /// @dev One strategy per one vault.
    struct DeltaNeutralStrategyCommonStorage {
        bool initialized;
    }

    /// @dev Fetches the common storage for the delta neutral strategy.
    /// @dev Uses inline assembly to point to the specific storage slot.
    /// @return s The storage slot for CommonStorage structure.
    function _getCommonStorage()
        internal
        view
        returns (DeltaNeutralStrategyCommonStorage storage s)
    {
        bytes32 pointer = DNS_COMMON_STORAGE;
        assembly ("memory-safe") {
            s.slot := pointer
        }
    }

    /// @dev Fetches the delta neutral strategy storage without initialization check.
    /// @dev Uses inline assembly to point to the specific storage slot.
    /// Be cautious while using this.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return s The storage slot for strategyStorage structure.
    function _getStorageUnsafe(
        bytes32 pointer
    ) internal pure returns (DeltaNeutralStrategyStorage storage s) {
        assembly ("memory-safe") {
            s.slot := pointer
        }
    }

    /// @dev Fetches the delta neutral strategy storage after checking initialization.
    /// @dev Reverts if the strategy is not initialized.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return s The storage slot for DeltaNeutralStrategyStorage structure.
    function _getStorage(
        bytes32 pointer
    ) internal view returns (DeltaNeutralStrategyStorage storage s) {
        s = _getStorageUnsafe(pointer);

        if (!s.initialized) {
            revert DeltaNeutralStrategy_NotInitialized();
        }
    }

    // =========================
    // Initializer
    // =========================

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function initialize(
        uint256 uniswapV3NftId,
        uint256 targetHealthFactor_e18,
        address supplyToken,
        address debtToken,
        bytes32 pointerToAaveChecker,
        bytes32 pointer
    ) external onlyVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorageUnsafe(pointer);

        _checkInitialize(s);
        _validateAaveCheckerPointer(pointerToAaveChecker);

        _setNewTargetHF(targetHealthFactor_e18, pointerToAaveChecker, s);

        _validateTokens(uniswapV3NftId, supplyToken, debtToken);
        s.uniswapV3NftId = uniswapV3NftId;

        IPool aavePool = IPool(aavePoolAddressesProvider.getPool());

        // set storage
        s.supplyTokenAave = IAToken(
            AaveLogicLib.aSupplyTokenAddress(supplyToken, aavePool)
        );
        s.debtTokenAave = IVariableDebtToken(
            AaveLogicLib.aDebtTokenAddress(debtToken, aavePool)
        );
        s.pointerToAaveChecker = pointerToAaveChecker;

        emit DeltaNeutralStrategyInitialize();
    }

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function initializeWithMint(
        InitializeWithMintParams memory p,
        bytes32 pointer
    ) external onlyVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorageUnsafe(pointer);

        _checkInitialize(s);
        _validateAaveCheckerPointer(p.pointerToAaveChecker);

        _setNewTargetHF(p.targetHealthFactor_e18, p.pointerToAaveChecker, s);

        // validate balances for mint
        DexLogicLib.validateTokenBalance(p.supplyToken, p.supplyTokenAmount);
        DexLogicLib.validateTokenBalance(p.debtToken, p.debtTokenAmount);

        IPool aavePool = IPool(aavePoolAddressesProvider.getPool());

        // set storage
        s.supplyTokenAave = IAToken(
            AaveLogicLib.aSupplyTokenAddress(p.supplyToken, aavePool)
        );
        s.debtTokenAave = IVariableDebtToken(
            AaveLogicLib.aDebtTokenAddress(p.debtToken, aavePool)
        );

        s.pointerToAaveChecker = p.pointerToAaveChecker;

        if (p.minTick > p.maxTick) {
            (p.minTick, p.maxTick) = (p.maxTick, p.minTick);
        }

        s.uniswapV3NftId = DexLogicLib.mintNftMEVUnsafe(
            p.supplyTokenAmount,
            p.debtTokenAmount,
            p.minTick,
            p.maxTick,
            p.supplyToken,
            p.debtToken,
            p.poolFee,
            dexNftPositionManager
        );

        emit DeltaNeutralStrategyInitialize();
    }

    // =========================
    // Getters
    // =========================

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function healthFactorsAndNft(
        bytes32 pointer
    )
        external
        view
        returns (uint256 targetHF, uint256 currentHF, uint256 uniswapV3NftId)
    {
        DeltaNeutralStrategyStorage storage s = _getStorageUnsafe(pointer);

        if (!s.initialized) {
            return (0, 0, 0);
        }

        targetHF = s.targetHealthFactor_e18;
        currentHF = AaveLogicLib.getCurrentHF(
            address(this),
            aavePoolAddressesProvider
        );
        uniswapV3NftId = s.uniswapV3NftId;
    }

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function getTotalSupplyTokenBalance(
        bytes32 pointer
    ) external view returns (uint256) {
        DeltaNeutralStrategyStorage storage s = _getStorageUnsafe(pointer);

        if (!s.initialized) {
            return 0;
        }

        uint256 nftId = s.uniswapV3NftId;
        IAToken supplyTokenAave = s.supplyTokenAave;
        address supplyToken = supplyTokenAave.UNDERLYING_ASSET_ADDRESS();
        IVariableDebtToken debtTokenAave = s.debtTokenAave;
        address debtToken = debtTokenAave.UNDERLYING_ASSET_ADDRESS();

        (, , uint24 poolFee, , , ) = DexLogicLib.getNftData(
            nftId,
            dexNftPositionManager
        );

        IUniswapV3Pool dexPool = DexLogicLib.dexPool(
            supplyToken,
            debtToken,
            poolFee,
            dexFactory
        );

        return
            _getTotalSupplyTokenBalance(
                0,
                nftId,
                supplyTokenAave,
                supplyToken,
                debtTokenAave,
                debtToken,
                dexPool
            );
    }

    // =========================
    // Setters
    // =========================

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function setNewTargetHF(
        uint256 newTargetHF,
        bytes32 pointer
    ) external onlyOwnerOrVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorage(pointer);

        _setNewTargetHF(newTargetHF, s.pointerToAaveChecker, s);
    }

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function setNewNftId(
        uint256 newNftId,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external onlyOwnerOrVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorage(pointer);

        IAToken supplyTokenAave = s.supplyTokenAave;
        address supplyToken = s.supplyTokenAave.UNDERLYING_ASSET_ADDRESS();

        _validateTokens(
            newNftId,
            supplyToken,
            s.debtTokenAave.UNDERLYING_ASSET_ADDRESS()
        );
        s.uniswapV3NftId = newNftId;

        _rebalance(supplyTokenAave, supplyToken, deviationThresholdE18, s);
    }

    // =========================
    // Main functions
    // =========================

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function deposit(
        uint256 amountToDeposit,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external onlyVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorage(pointer);

        if (amountToDeposit == 0) {
            revert DeltaNeutralStrategy_DepositZero();
        }

        IAToken supplyTokenAave = s.supplyTokenAave;
        address supplyToken = supplyTokenAave.UNDERLYING_ASSET_ADDRESS();

        DexLogicLib.validateTokenBalance(supplyToken, amountToDeposit);

        _strategyActions(
            amountToDeposit,
            0,
            deviationThresholdE18,
            s.uniswapV3NftId,
            supplyTokenAave,
            supplyToken,
            s
        );
        emit DeltaNeutralStrategyDeposit();
    }

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function depositETH(
        uint256 amountToDeposit,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external onlyVaultItself {
        if (amountToDeposit > address(this).balance) {
            revert DeltaNeutralStrategy_DepositZero();
        }

        DeltaNeutralStrategyStorage storage s = _getStorage(pointer);

        IAToken supplyTokenAave = s.supplyTokenAave;
        address supplyToken = supplyTokenAave.UNDERLYING_ASSET_ADDRESS();

        if (supplyToken != address(wrappedNative)) {
            revert DeltaNeutralStrategy_Token0IsNotWNative();
        }

        wrappedNative.deposit{value: amountToDeposit}();

        _strategyActions(
            amountToDeposit,
            0,
            deviationThresholdE18,
            s.uniswapV3NftId,
            supplyTokenAave,
            supplyToken,
            s
        );
        emit DeltaNeutralStrategyDeposit();
    }

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function withdraw(
        uint256 shareE18,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external onlyVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorage(pointer);

        IAToken supplyTokenAave = s.supplyTokenAave;
        address supplyToken = supplyTokenAave.UNDERLYING_ASSET_ADDRESS();

        _strategyActions(
            0,
            shareE18,
            deviationThresholdE18,
            s.uniswapV3NftId,
            supplyTokenAave,
            supplyToken,
            s
        );
        emit DeltaNeutralStrategyWithdraw();
    }

    /// @inheritdoc IDeltaNeutralStrategyLogic
    function rebalance(
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external onlyVaultItself {
        DeltaNeutralStrategyStorage storage s = _getStorage(pointer);

        IAToken supplyTokenAave = s.supplyTokenAave;
        address supplyToken = s.supplyTokenAave.UNDERLYING_ASSET_ADDRESS();

        _rebalance(supplyTokenAave, supplyToken, deviationThresholdE18, s);
    }

    // =========================
    // Internal functions
    // =========================

    function _rebalance(
        IAToken supplyTokenAave,
        address supplyToken,
        uint256 deviationThresholdE18,
        DeltaNeutralStrategyStorage storage s
    ) internal {
        _strategyActions(
            0,
            0,
            deviationThresholdE18,
            s.uniswapV3NftId,
            supplyTokenAave,
            supplyToken,
            s
        );

        emit DeltaNeutralStrategyRebalance();
    }

    /// @dev Internal function to set a new target health factor.
    /// @param newTargetHF The new target health factor to set.
    /// @param pointerToAaveChecker The pointer to the Aave checker.
    /// @param s Storage reference to the DeltaNeutralStrategyStorage.
    function _setNewTargetHF(
        uint256 newTargetHF,
        bytes32 pointerToAaveChecker,
        DeltaNeutralStrategyStorage storage s
    ) internal {
        (uint256 lowerHFBoundary, uint256 upperHFBoundary) = IAaveCheckerLogic(
            address(this)
        ).getHFBoundaries(pointerToAaveChecker);

        if (newTargetHF <= lowerHFBoundary || newTargetHF >= upperHFBoundary) {
            revert DeltaNeutralStrategy_HealthFactorOutOfRange();
        }

        s.targetHealthFactor_e18 = newTargetHF;
        emit DeltaNeutralStrategyNewHealthFactor(newTargetHF);
    }

    /// @dev Struct to cache data suring function execution.
    struct StrategyActionsCache {
        uint24 poolFee;
        IUniswapV3Pool dexPool;
        uint256 amountToDeposit;
        uint256 nftId;
    }

    /// @dev Handles actions such as supplying and borrowing tokens and depositing to uniswap.
    /// @param amountToDeposit Amount of tokens to deposit.
    /// @param shareE18 Percentage share to withdraw (1e18 represents 100%).
    /// @param deviationThresholdE18 Deviation threshold.
    /// @param nftId ID of the NFT.
    /// @param supplyTokenAave Reference to the Aave supply token.
    /// @param supplyToken Address of the supply token.
    /// @param s Storage reference to the DeltaNeutralStrategyStorage.
    function _strategyActions(
        uint256 amountToDeposit,
        uint256 shareE18,
        uint256 deviationThresholdE18,
        uint256 nftId,
        IAToken supplyTokenAave,
        address supplyToken,
        DeltaNeutralStrategyStorage storage s
    ) internal {
        IVariableDebtToken debtTokenAave = s.debtTokenAave;
        address debtToken = debtTokenAave.UNDERLYING_ASSET_ADDRESS();

        StrategyActionsCache memory aaveActionCache;

        {
            (, , uint24 poolFee, , , ) = DexLogicLib.getNftData(
                nftId,
                dexNftPositionManager
            );
            IUniswapV3Pool dexPool = DexLogicLib.dexPool(
                supplyToken,
                debtToken,
                poolFee,
                dexFactory
            );
            DexLogicLib.MEVCheck(deviationThresholdE18, dexPool, PERIOD);

            aaveActionCache.poolFee = poolFee;
            aaveActionCache.dexPool = dexPool;
            aaveActionCache.amountToDeposit = amountToDeposit;
            aaveActionCache.nftId = nftId;
        }

        uint256 totalToken0Balance = _getTotalSupplyTokenBalance(
            aaveActionCache.amountToDeposit,
            nftId,
            supplyTokenAave,
            supplyToken,
            debtTokenAave,
            debtToken,
            aaveActionCache.dexPool
        );

        if (shareE18 > 0) {
            if (shareE18 > E18) {
                shareE18 = E18;
            }
            unchecked {
                // remainder in supplyToken after withdraw
                totalToken0Balance =
                    (totalToken0Balance * (E18 - shareE18)) /
                    E18;
            }
        }

        // get target amounts for new value
        (
            uint256 amountToSupply,
            uint256 amountToBorrow
        ) = _getAmountToSupplyAndToBorrow(
                aaveActionCache.nftId,
                supplyToken,
                debtToken,
                s.targetHealthFactor_e18,
                s.pointerToAaveChecker,
                aaveActionCache.dexPool,
                totalToken0Balance
            );

        uint256 supplyBalanceBefore = TransferHelper.safeGetBalance(
            supplyToken,
            address(this)
        );
        uint256 debtBalanceBefore = TransferHelper.safeGetBalance(
            debtToken,
            address(this)
        );

        // bring to the target amounts
        _bringToTheAmounts(
            aaveActionCache.amountToDeposit,
            aaveActionCache.nftId,
            supplyTokenAave,
            supplyToken,
            debtTokenAave,
            debtToken,
            aaveActionCache.dexPool,
            amountToSupply,
            amountToBorrow
        );

        uint256 debtBalanceAfter = TransferHelper.safeGetBalance(
            debtToken,
            address(this)
        );

        if (shareE18 > 0) {
            if (debtBalanceAfter > debtBalanceBefore) {
                // convert debt token to supply token
                _convertAssetsToSupplyToken(
                    supplyToken,
                    debtToken,
                    aaveActionCache.poolFee,
                    debtBalanceAfter - debtBalanceBefore
                );
            }
        } else {
            uint256 supplyBalanceAfter = TransferHelper.safeGetBalance(
                supplyToken,
                address(this)
            );

            uint256 supplyAmountToUni;
            uint256 debtAmountToUni;

            if (supplyBalanceBefore >= supplyBalanceAfter) {
                unchecked {
                    supplyAmountToUni =
                        aaveActionCache.amountToDeposit -
                        (supplyBalanceBefore - supplyBalanceAfter);
                }
            } else {
                unchecked {
                    supplyAmountToUni =
                        supplyBalanceAfter -
                        supplyBalanceBefore;
                }
            }
            if (debtBalanceAfter > debtBalanceBefore) {
                unchecked {
                    debtAmountToUni = debtBalanceAfter - debtBalanceBefore;
                }
            }

            if (supplyAmountToUni > 0 || debtAmountToUni > 0) {
                // Deposit to uni
                _depositToUni(
                    aaveActionCache.dexPool,
                    supplyToken,
                    debtToken,
                    aaveActionCache.nftId,
                    aaveActionCache.poolFee,
                    supplyAmountToUni,
                    debtAmountToUni
                );
            }
        }
    }

    /// @dev Adjusts the supply and borrow amounts to reach the desired targets.
    /// @param amountToDeposit Amount of tokens to deposit.
    /// @param nftId ID of the NFT.
    /// @param supplyTokenAave Reference to the Aave supply token.
    /// @param supplyToken Address of the supply token.
    /// @param debtTokenAave Reference to the Aave debt token.
    /// @param debtToken Address of the debt token.
    /// @param dexPool Reference to the Uniswap V3 pool.
    /// @param amountToSupply Desired supply amount.
    /// @param amountToBorrow Desired borrow amount.
    function _bringToTheAmounts(
        uint256 amountToDeposit,
        uint256 nftId,
        IAToken supplyTokenAave,
        address supplyToken,
        IVariableDebtToken debtTokenAave,
        address debtToken,
        IUniswapV3Pool dexPool,
        uint256 amountToSupply,
        uint256 amountToBorrow
    ) internal {
        // checks to increase or decrease
        // our supply and borrow
        uint256 supplyTokenAaveBalance = TransferHelper.safeGetBalance(
            address(supplyTokenAave),
            address(this)
        );

        uint256 debtTokenAaveBalance = TransferHelper.safeGetBalance(
            address(debtTokenAave),
            address(this)
        );

        if (
            amountToSupply >= supplyTokenAaveBalance &&
            amountToBorrow >= debtTokenAaveBalance
        ) {
            // if we need to increase our supply and borrow
            // we increase supply first
            // and then borrow
            if (amountToSupply > 0) {
                _bringingToTargetSupplyAmount(
                    amountToDeposit,
                    nftId,
                    supplyTokenAave,
                    supplyToken,
                    debtToken,
                    dexPool,
                    amountToSupply
                );
            }
            if (amountToBorrow > 0) {
                _bringingToTargetBorrowAmount(
                    amountToDeposit > 0,
                    nftId,
                    supplyToken,
                    debtTokenAave,
                    debtToken,
                    dexPool,
                    amountToBorrow
                );
            }
        } else {
            // if we need to reduce our supply and borrow
            // we reduce borrow first
            // and then supply
            _bringingToTargetBorrowAmount(
                amountToDeposit > 0,
                nftId,
                supplyToken,
                debtTokenAave,
                debtToken,
                dexPool,
                amountToBorrow
            );
            _bringingToTargetSupplyAmount(
                amountToDeposit,
                nftId,
                supplyTokenAave,
                supplyToken,
                debtToken,
                dexPool,
                amountToSupply
            );
        }
    }

    /// @dev Struct to cache data suring function execution.
    struct DataCache {
        uint160 sqrtPriceX96;
        uint24 poolFee;
        int24 tickLower;
        int24 tickUpper;
        uint128 nftLiquidity;
    }

    /// @dev Bringing to the target amount for supplying on Aave.
    /// @param amountToDeposit The amount intended to be deposited.
    /// @param nftId The ID of the NFT.
    /// @param supplyTokenAave Aave's token for supplying.
    /// @param supplyToken The token intended to be supplied.
    /// @param debtToken The token to be swapped to achieve target supply.
    /// @param dexPool The Uniswap V3 pool instance.
    /// @param amountToSupply The target supply amount.
    function _bringingToTargetSupplyAmount(
        uint256 amountToDeposit,
        uint256 nftId,
        IAToken supplyTokenAave,
        address supplyToken,
        address debtToken,
        IUniswapV3Pool dexPool,
        uint256 amountToSupply
    ) internal {
        uint256 supplyTokenAaveBalance = TransferHelper.safeGetBalance(
            address(supplyTokenAave),
            address(this)
        );

        // checks if we need to increase or decrease supply
        if (amountToSupply > supplyTokenAaveBalance) {
            // if we got less supplyToken than we need to supply, we swap debtToken to supplyToken
            // and supply supplyToken to aave
            uint256 deltaToSupply = amountToSupply - supplyTokenAaveBalance;

            DataCache memory dataCache;

            (
                ,
                ,
                dataCache.poolFee,
                dataCache.tickLower,
                dataCache.tickUpper,
                dataCache.nftLiquidity
            ) = DexLogicLib.getNftData(nftId, dexNftPositionManager);

            if (amountToDeposit < deltaToSupply) {
                if (dataCache.nftLiquidity != 0) {
                    uint128 liquidityToWithdraw;
                    uint160 sqrtPriceX96 = DexLogicLib.getCurrentSqrtRatioX96(
                        dexPool
                    );

                    if (supplyToken > debtToken) {
                        liquidityToWithdraw = LiquidityAmounts
                            .getLiquidityForAmount1(
                                sqrtPriceX96,
                                TickMath.getSqrtRatioAtTick(
                                    dataCache.tickLower
                                ),
                                deltaToSupply - amountToDeposit
                            );
                    } else {
                        liquidityToWithdraw = LiquidityAmounts
                            .getLiquidityForAmount0(
                                sqrtPriceX96,
                                TickMath.getSqrtRatioAtTick(
                                    dataCache.tickUpper
                                ),
                                deltaToSupply - amountToDeposit
                            );
                    }

                    if (liquidityToWithdraw > dataCache.nftLiquidity) {
                        liquidityToWithdraw = dataCache.nftLiquidity;
                    }

                    // withdraw uni position for amount of supplyToken that we need
                    (
                        uint256 supplyWithdrawed,
                        uint256 debtWithdrawed
                    ) = DexLogicLib.withdrawPositionMEVUnsafe(
                            nftId,
                            liquidityToWithdraw,
                            dexNftPositionManager
                        );

                    if (supplyToken > debtToken) {
                        (supplyWithdrawed, debtWithdrawed) = (
                            debtWithdrawed,
                            supplyWithdrawed
                        );
                    }
                    unchecked {
                        amountToDeposit += supplyWithdrawed;
                    }

                    if (deltaToSupply > amountToDeposit && debtWithdrawed > 0) {
                        // swap debtToken to supplyToken
                        uint256 amountOut = DexLogicLib.swapExactInputMEVUnsafe(
                            debtToken,
                            supplyToken,
                            dataCache.poolFee,
                            debtWithdrawed,
                            dexRouter
                        );

                        unchecked {
                            amountToDeposit += amountOut;
                        }
                    }
                }
            }

            if (deltaToSupply > amountToDeposit) {
                deltaToSupply = amountToDeposit;
            }

            // supply supplyToken to aave
            AaveLogicLib.supplyAave(
                supplyToken,
                deltaToSupply,
                address(this),
                aavePoolAddressesProvider
            );
        } else {
            // if we got more supply than we need, we withdraw it
            AaveLogicLib.withdrawAave(
                supplyToken,
                supplyTokenAaveBalance - amountToSupply,
                address(this),
                aavePoolAddressesProvider
            );
        }
    }

    /// @dev Bringing to the target borrow amount on Aave.
    /// @param isDeposit Indicator if the operation is a deposit.
    /// @param nftId The ID of the NFT.
    /// @param supplyToken The token intended to be swapped for borrowing.
    /// @param debtTokenAave Aave's debt token.
    /// @param debtToken The token intended to be borrowed.
    /// @param dexPool The Uniswap V3 pool instance.
    /// @param amountToBorrow The target borrow amount.
    function _bringingToTargetBorrowAmount(
        bool isDeposit,
        uint256 nftId,
        address supplyToken,
        IVariableDebtToken debtTokenAave,
        address debtToken,
        IUniswapV3Pool dexPool,
        uint256 amountToBorrow
    ) internal {
        uint256 totalDebt = AaveLogicLib.getTotalDebt(
            address(debtTokenAave),
            address(this)
        );

        // checks if we need to increase or decrease borrow
        if (amountToBorrow > totalDebt) {
            // if we got less borrow than we need, we makes a borrow
            uint256 amount;
            unchecked {
                amount = amountToBorrow - totalDebt;
            }

            AaveLogicLib.borrowAave(
                debtToken,
                amount,
                address(this),
                aavePoolAddressesProvider
            );
        } else {
            // if we got more borrow than we need, swap supplyToken to debtToken
            // and repay aave
            uint256 deltaToRepay;
            unchecked {
                deltaToRepay = totalDebt - amountToBorrow;
            }

            DataCache memory dataCache;

            (
                ,
                ,
                dataCache.poolFee,
                dataCache.tickLower,
                dataCache.tickUpper,
                dataCache.nftLiquidity
            ) = DexLogicLib.getNftData(nftId, dexNftPositionManager);

            uint256 debtTokenBalance;
            if (isDeposit) {
                debtTokenBalance = TransferHelper.safeGetBalance(
                    debtToken,
                    address(this)
                );
            } else {
                debtTokenBalance = 0;
            }

            dataCache.sqrtPriceX96 = DexLogicLib.getCurrentSqrtRatioX96(
                dexPool
            );

            if (debtTokenBalance < deltaToRepay) {
                if (dataCache.nftLiquidity != 0) {
                    uint128 liquidityToWithdraw;

                    if (supplyToken > debtToken) {
                        liquidityToWithdraw = LiquidityAmounts
                            .getLiquidityForAmount0(
                                dataCache.sqrtPriceX96,
                                TickMath.getSqrtRatioAtTick(
                                    dataCache.tickUpper
                                ),
                                deltaToRepay - debtTokenBalance
                            );
                    } else {
                        liquidityToWithdraw = LiquidityAmounts
                            .getLiquidityForAmount1(
                                dataCache.sqrtPriceX96,
                                TickMath.getSqrtRatioAtTick(
                                    dataCache.tickLower
                                ),
                                deltaToRepay - debtTokenBalance
                            );
                    }

                    if (liquidityToWithdraw > dataCache.nftLiquidity) {
                        liquidityToWithdraw = dataCache.nftLiquidity;
                    }

                    // withdraw uni position for amount of supplyToken that we need
                    (
                        uint256 supplyWithdrawed,
                        uint256 debtWithdrawed
                    ) = DexLogicLib.withdrawPositionMEVUnsafe(
                            nftId,
                            liquidityToWithdraw,
                            dexNftPositionManager
                        );

                    if (supplyToken > debtToken) {
                        (supplyWithdrawed, debtWithdrawed) = (
                            debtWithdrawed,
                            supplyWithdrawed
                        );
                    }
                    unchecked {
                        debtTokenBalance += debtWithdrawed;
                    }

                    if (
                        deltaToRepay > debtTokenBalance && supplyWithdrawed > 0
                    ) {
                        // swap supplyToken to debtToken
                        uint256 amountOut = DexLogicLib.swapExactInputMEVUnsafe(
                            supplyToken,
                            debtToken,
                            dataCache.poolFee,
                            supplyWithdrawed,
                            dexRouter
                        );

                        unchecked {
                            debtTokenBalance += amountOut;
                        }
                    }
                }
            }

            if (deltaToRepay > debtTokenBalance) {
                uint256 token1Token0Quote;
                if (debtToken < supplyToken) {
                    token1Token0Quote = DexLogicLib.getAmount0InToken1(
                        dataCache.sqrtPriceX96,
                        deltaToRepay - debtTokenBalance
                    );
                } else {
                    token1Token0Quote = DexLogicLib.getAmount1InToken0(
                        dataCache.sqrtPriceX96,
                        deltaToRepay - debtTokenBalance
                    );
                }

                uint256 supplyTokenBalance = TransferHelper.safeGetBalance(
                    supplyToken,
                    address(this)
                );

                AaveLogicLib.withdrawAave(
                    supplyToken,
                    token1Token0Quote,
                    address(this),
                    aavePoolAddressesProvider
                );

                supplyTokenBalance =
                    TransferHelper.safeGetBalance(supplyToken, address(this)) -
                    supplyTokenBalance;

                // swap supplyToken to debtToken
                DexLogicLib.swapExactInputMEVUnsafe(
                    supplyToken,
                    debtToken,
                    dataCache.poolFee,
                    supplyTokenBalance,
                    dexRouter
                );
            }

            // we need to do "+1" because of aave bug
            unchecked {
                ++deltaToRepay;
            }

            // repay aave
            AaveLogicLib.repayAave(
                debtToken,
                deltaToRepay,
                address(this),
                aavePoolAddressesProvider
            );
        }
    }

    /// @dev Retrieves the total balance of the supply token, including deposits, debts
    /// and uniswap position.
    /// @param amountToDeposit The amount of the token that is intended to be deposited.
    /// @param nftId ID of the NFT in question.
    /// @param supplyTokenAave AAVE's supply token interface.
    /// @param supplyToken The supply token address.
    /// @param debtTokenAave AAVE's debt token interface.
    /// @param debtToken The debt token address.
    /// @param dexPool The decentralized exchange pool interface.
    /// @return Total balance of the supply token.
    function _getTotalSupplyTokenBalance(
        uint256 amountToDeposit,
        uint256 nftId,
        IAToken supplyTokenAave,
        address supplyToken,
        IVariableDebtToken debtTokenAave,
        address debtToken,
        IUniswapV3Pool dexPool
    ) internal view returns (uint256) {
        // gets amount of supplyToken and debtToken in nft
        uint256 amount0;
        uint256 amount1;

        uint256 liquidity = DexLogicLib.getLiquidity(
            nftId,
            dexNftPositionManager
        );
        if (liquidity != 0) {
            (amount0, amount1) = DexLogicLib.tvl(
                nftId,
                dexPool,
                dexNftPositionManager
            );

            // checks if our supplyToken is supplyToken in nft
            if (supplyToken > debtToken) {
                (amount0, amount1) = (amount1, amount0);
            }
        }

        // gets pure amount of supplyToken and debtToken in current aave position
        uint256 pureAmountSupplyToken = TransferHelper.safeGetBalance(
            address(supplyTokenAave),
            address(this)
        ) +
            amount0 +
            amountToDeposit;

        // gets debt amount
        uint256 totalDebt = AaveLogicLib.getTotalDebt(
            address(debtTokenAave),
            address(this)
        );

        uint160 sqrtPriceX96 = DexLogicLib.getCurrentSqrtRatioX96(dexPool);

        uint256 pureAmountDebtTokenInSupplyToken;
        uint256 totalDebtInSupplyToken;
        if (debtToken < supplyToken) {
            pureAmountDebtTokenInSupplyToken = DexLogicLib.getAmount0InToken1(
                sqrtPriceX96,
                amount1
            );

            totalDebtInSupplyToken = DexLogicLib.getAmount0InToken1(
                sqrtPriceX96,
                totalDebt
            );
        } else {
            pureAmountDebtTokenInSupplyToken = DexLogicLib.getAmount1InToken0(
                sqrtPriceX96,
                amount1
            );

            totalDebtInSupplyToken = DexLogicLib.getAmount1InToken0(
                sqrtPriceX96,
                totalDebt
            );
        }

        // returns total supplyToken balance
        return
            pureAmountSupplyToken +
            pureAmountDebtTokenInSupplyToken -
            totalDebtInSupplyToken;
    }

    /// @dev Calculates the amount to be supplied and borrowed.
    /// @param nftId ID of the NFT in question.
    /// @param supplyToken The supply token address.
    /// @param debtToken The debt token address.
    /// @param targetHealthFactor_e18 Target health factor.
    /// @param pointerToAaveChecker A pointer to the AAVE checker.
    /// @param dexPool The decentralized exchange pool interface.
    /// @param inputAmount The input amount.
    /// @return amountToSupply The amount that should be supplied.
    /// @return amountToBorrow The amount that should be borrowed.
    function _getAmountToSupplyAndToBorrow(
        uint256 nftId,
        address supplyToken,
        address debtToken,
        uint256 targetHealthFactor_e18,
        bytes32 pointerToAaveChecker,
        IUniswapV3Pool dexPool,
        uint256 inputAmount
    ) internal view returns (uint256 amountToSupply, uint256 amountToBorrow) {
        // get ticks
        (, , , int24 minTick, int24 maxTick, ) = DexLogicLib.getNftData(
            nftId,
            dexNftPositionManager
        );

        uint160 sqrtPriceX96 = DexLogicLib.getCurrentSqrtRatioX96(dexPool);

        uint256 currentHealthFactorForCalculation_1e18 = _getHFForCalculations(
            targetHealthFactor_e18,
            pointerToAaveChecker
        );

        // get current liquidation threshold
        uint256 currentLiquidationThreshold_1e4 = AaveLogicLib
            .getCurrentLiquidationThreshold(
                supplyToken,
                aavePoolAddressesProvider
            );

        uint256 R_e18 = DexLogicLib.getTargetRE18ForTickRange(
            minTick,
            maxTick,
            dexPool.liquidity(),
            sqrtPriceX96
        );

        amountToSupply =
            (currentHealthFactorForCalculation_1e18 *
                inputAmount *
                (E18 - R_e18)) /
            (currentHealthFactorForCalculation_1e18 *
                (E18 - R_e18) +
                R_e18 *
                currentLiquidationThreshold_1e4 *
                E14);

        uint256 borrowMultiplier = FullMath.mulDiv(
            amountToSupply * E14,
            currentLiquidationThreshold_1e4,
            currentHealthFactorForCalculation_1e18
        );
        // gets amount to borrow
        if (supplyToken < debtToken) {
            amountToBorrow = DexLogicLib.getAmount0InToken1(
                sqrtPriceX96,
                borrowMultiplier
            );
        } else {
            amountToBorrow = DexLogicLib.getAmount1InToken0(
                sqrtPriceX96,
                borrowMultiplier
            );
        }
    }

    /// @dev Retrieves the health factor for calculations.
    /// @dev If the currentHF is out of bounds, the targetHF is used.
    /// @param targetHealthFactor_e18 Target health factor.
    /// @param pointerToAaveChecker A pointer to the AAVE checker.
    /// @return currentHealthFactorForCalculation_1e18 The health factor used for calculations.
    function _getHFForCalculations(
        uint256 targetHealthFactor_e18,
        bytes32 pointerToAaveChecker
    ) internal view returns (uint256 currentHealthFactorForCalculation_1e18) {
        (uint256 lowerHFBoundary, uint256 upperHFBoundary) = IAaveCheckerLogic(
            address(this)
        ).getHFBoundaries(pointerToAaveChecker);

        uint256 currentHealthFactor = AaveLogicLib.getCurrentHF(
            address(this),
            aavePoolAddressesProvider
        );

        if (
            currentHealthFactor < lowerHFBoundary ||
            currentHealthFactor > upperHFBoundary
        ) {
            currentHealthFactorForCalculation_1e18 = targetHealthFactor_e18;
        } else {
            currentHealthFactorForCalculation_1e18 = currentHealthFactor;
        }
    }

    /// @dev Converts assets to the supply token.
    /// @param supplyToken The supply token address.
    /// @param debtToken The debt token address.
    /// @param poolFee The fee associated with the pool.
    /// @param debtTokenBalance The balance of the debt token.
    function _convertAssetsToSupplyToken(
        address supplyToken,
        address debtToken,
        uint24 poolFee,
        uint256 debtTokenBalance
    ) internal {
        DexLogicLib.swapExactInputMEVUnsafe(
            debtToken,
            supplyToken,
            poolFee,
            debtTokenBalance,
            dexRouter
        );
    }

    /// @dev Deposits tokens to Uniswap position.
    /// @param dexPool The decentralized exchange pool interface.
    /// @param supplyToken The supply token address.
    /// @param debtToken The debt token address.
    /// @param nftId ID of the NFT in question.
    /// @param poolFee The fee associated with the pool.
    /// @param supplyTokenAmount Amount of the supply token.
    /// @param debtTokenAmount Amount of the debt token.
    function _depositToUni(
        IUniswapV3Pool dexPool,
        address supplyToken,
        address debtToken,
        uint256 nftId,
        uint24 poolFee,
        uint256 supplyTokenAmount,
        uint256 debtTokenAmount
    ) internal {
        (, , , int24 tickLower, int24 tickUpper, ) = DexLogicLib.getNftData(
            nftId,
            dexNftPositionManager
        );

        if (supplyToken > debtToken) {
            (supplyTokenAmount, debtTokenAmount) = (
                debtTokenAmount,
                supplyTokenAmount
            );
            (supplyToken, debtToken) = (debtToken, supplyToken);
        }

        (supplyTokenAmount, debtTokenAmount) = DexLogicLib
            .swapToTargetRMEVUnsafe(
                tickLower,
                tickUpper,
                supplyTokenAmount,
                debtTokenAmount,
                dexPool,
                supplyToken,
                debtToken,
                poolFee,
                dexRouter
            );

        TransferHelper.safeApprove(
            supplyToken,
            address(dexNftPositionManager),
            supplyTokenAmount
        );
        TransferHelper.safeApprove(
            debtToken,
            address(dexNftPositionManager),
            debtTokenAmount
        );

        DexLogicLib.increaseLiquidityMEVUnsafe(
            nftId,
            supplyTokenAmount,
            debtTokenAmount,
            dexNftPositionManager
        );
    }

    /// @dev Validates that the tokens match with the provided NFT.
    /// @param nftId ID of the NFT in question.
    /// @param supplyToken The supply token address.
    /// @param debtToken The debt token address.
    function _validateTokens(
        uint256 nftId,
        address supplyToken,
        address debtToken
    ) internal view {
        (address token0, address token1, , , , ) = DexLogicLib.getNftData(
            nftId,
            dexNftPositionManager
        );

        if (supplyToken > debtToken) {
            (token0, token1) = (token1, token0);
        }

        if (token0 != supplyToken || token1 != debtToken) {
            revert DeltaNeutralStrategy_InvalidNFTTokens();
        }
    }

    /// @dev Ensures the contract is initialized only once.
    /// @param s Storage reference to the DeltaNeutralStrategyStorage.
    function _checkInitialize(DeltaNeutralStrategyStorage storage s) private {
        DeltaNeutralStrategyCommonStorage storage cs = _getCommonStorage();

        // init block
        if (s.initialized || cs.initialized) {
            revert DeltaNeutralStrategy_AlreadyInitialized();
        }

        s.initialized = true;
        cs.initialized = true;
    }

    /// @dev Validates that the provided AAVE checker pointer has been initialized.
    /// @param aaveCheckerPointer The pointer to the AAVE checker to validate.
    function _validateAaveCheckerPointer(
        bytes32 aaveCheckerPointer
    ) private view {
        (, , , bool initialized) = IAaveCheckerLogic(address(this))
            .getLocalAaveCheckerStorage(aaveCheckerPointer);

        if (!initialized) {
            revert DeltaNeutralStrategy_AaveCheckerNotInitialized();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   */
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   */
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   */
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   */
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   */
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   */
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   */
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   */
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   */
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   */
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   */
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @notice Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   * @return The backed amount
   */
  function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256);

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   */
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   */
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   */
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   */
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   */
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   */
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   */
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   */
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://docs.aave.com/developers/
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://docs.aave.com/developers/
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   */
  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   */
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   */
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   */
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   */
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(
    address asset
  ) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(
    address user
  ) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
   * "dynamic" variable index based on time, current stored index and virtual rate at the current
   * moment (approx. a borrower would get if opening a position). This means that is always used in
   * combination with variable debt supply/balances.
   * If using this function externally, consider that is possible to have an increasing normalized
   * variable debt that is not equivalent to how the variable debt index would be updated in storage
   * (e.g. only updates with non-zero variable debt supply)
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   */
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   */
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   */
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(address token, address to, uint256 amount) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableDebtToken} from './IInitializableDebtToken.sol';

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 */
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
  /**
   * @notice Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return True if the previous balance of the user is 0, false otherwise
   * @return The scaled total debt of the reserve
   */
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool, uint256);

  /**
   * @notice Burns user variable debt
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the debt will be burned
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   * @return The scaled total debt of the reserve
   */
  function burn(address from, uint256 amount, uint256 index) external returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableAToken} from './IInitializableAToken.sol';

/**
 * @title IAToken
 * @author Aave
 * @notice Defines the basic interface for an AToken.
 */
interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The scaled amount being transferred
   * @param index The next liquidity index of the reserve
   */
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @notice Mints `amount` aTokens to `user`
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted aTokens
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @dev In some instances, the mint event could be emitted from a burn transaction
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the aTokens will be burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The next liquidity index of the reserve
   */
  function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) external;

  /**
   * @notice Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   */
  function transferOnLiquidation(address from, address to, uint256 value) external;

  /**
   * @notice Transfers the underlying asset to `target`.
   * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the underlying
   * @param amount The amount getting transferred
   */
  function transferUnderlyingTo(address target, uint256 amount) external;

  /**
   * @notice Handles the underlying received by the aToken after the transfer has been completed.
   * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
   * transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
   * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
   * @param user The user executing the repayment
   * @param onBehalfOf The address of the user who will get his debt reduced/removed
   * @param amount The amount getting repaid
   */
  function handleRepayment(address user, address onBehalfOf, uint256 amount) external;

  /**
   * @notice Allow passing a signed message to approve spending
   * @dev implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
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
   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
   * @return Address of the Aave treasury
   */
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the nonce for owner.
   * @param owner The address of the owner
   * @return The nonce of the owner
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// source: https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/IV3SwapRouter.sol
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Aave Checker Logic
/// @notice Provides methods to check and manage health factors using Aave.
interface IAaveCheckerLogic {
    // =========================
    // Storage
    // =========================

    /// @dev Storage structure for the Aave Checker
    struct AaveCheckerStorage {
        uint128 lowerHFBoundary;
        uint128 upperHFBoundary;
        address user;
        bool initialized;
    }

    // =========================
    // Events
    // =========================

    /// @notice Emitted when the Aave checker is initialized
    event AaveCheckerInitialized();

    /// @notice Emitted when new health factor boundaries are set
    /// @param lowerHFBoundary The new lower health factor boundary
    /// @param upperHFBoundary The new upper health factor boundary
    event AaveCheckerSetNewHF(uint128 lowerHFBoundary, uint128 upperHFBoundary);

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when trying to initialize an already initialized checker
    error AaveChecker_AlreadyInitialized();

    /// @notice Thrown when provided health factors are incorrect
    error AaveChecker_IncorrectHealthFators();

    /// @notice Thrown when trying to access uninitialized checker
    error AaveChecker_NotInitialized();

    // =========================
    // Initializer
    // =========================

    /// @notice Initializes the Aave checker with given health factor boundaries and user address
    /// @param lowerHFBoundary The lower boundary for the health factor
    /// @param upperHFBoundary The upper boundary for the health factor
    /// @param user The user whose health factor is being checked
    /// @param pointer A bytes32 pointer value for storage location
    function aaveCheckerInitialize(
        uint128 lowerHFBoundary,
        uint128 upperHFBoundary,
        address user,
        bytes32 pointer
    ) external;

    // =========================
    // Main functions
    // =========================

    /// @notice Checks if the health factor is within set boundaries
    /// @param pointer A bytes32 pointer value for storage location
    /// @return A boolean indicating if the health factor is within boundaries
    function checkHF(bytes32 pointer) external view returns (bool);

    // =========================
    // Setters
    // =========================

    /// @notice Sets the boundaries for the health factor
    /// @param lowerHFBoundary The lower boundary for the health factor
    /// @param upperHFBoundary The upper boundary for the health factor
    /// @param pointer A bytes32 pointer value for storage location
    function setHFBoundaries(
        uint128 lowerHFBoundary,
        uint128 upperHFBoundary,
        bytes32 pointer
    ) external;

    // =========================
    // Getters
    // =========================

    /// @notice Retrieves the health factor boundaries
    /// @param pointer A bytes32 pointer value for storage location
    /// @return lowerHFBoundary The current lower boundary for the health factor
    /// @return upperHFBoundary The current upper boundary for the health factor
    function getHFBoundaries(
        bytes32 pointer
    ) external view returns (uint256 lowerHFBoundary, uint256 upperHFBoundary);

    /// @notice Retrieves the details of a specific local Aave checker storage
    /// @param pointer The pointer to the specific local Aave checker storage
    /// @return lowerHFBoundary The lower boundary for the health factor
    /// @return upperHFBoundary The upper boundary for the health factor
    /// @return user The address of the user related to this checker
    /// @return initialized A boolean indicating if this checker has been initialized
    function getLocalAaveCheckerStorage(
        bytes32 pointer
    )
        external
        view
        returns (
            uint256 lowerHFBoundary,
            uint256 upperHFBoundary,
            address user,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAToken} from "@aave/aave-v3-core/contracts/interfaces/IAToken.sol";
import {IVariableDebtToken} from "@aave/aave-v3-core/contracts/interfaces/IVariableDebtToken.sol";

/// @title IDeltaNeutralStrategyLogic - DeltaNeutralStrategyLogic interface
interface IDeltaNeutralStrategyLogic {
    // =========================
    // Storage
    // =========================

    /// @dev Struct defining the delta neutral strategy storage elements.
    struct DeltaNeutralStrategyStorage {
        uint256 uniswapV3NftId;
        IAToken supplyTokenAave;
        IVariableDebtToken debtTokenAave;
        uint256 targetHealthFactor_e18;
        bytes32 pointerToAaveChecker;
        bool initialized;
    }

    // =========================
    // Events
    // =========================

    /// @notice Emits when a deposit is made in the strategy.
    event DeltaNeutralStrategyDeposit();

    /// @notice Emits when a withdrawal is made from the strategy.
    event DeltaNeutralStrategyWithdraw();

    /// @notice Emits when the strategy is rebalanced.
    event DeltaNeutralStrategyRebalance();

    /// @notice Emits when the strategy is initialized.
    event DeltaNeutralStrategyInitialize();

    /// @notice Emits when a new health factor is set.
    event DeltaNeutralStrategyNewHealthFactor(uint256 newTargetHealthFactor);

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when trying to initialize an already initialized strategy.
    error DeltaNeutralStrategy_AlreadyInitialized();

    /// @notice Thrown when accessing an uninitialized strategy.
    error DeltaNeutralStrategy_NotInitialized();

    /// @notice Thrown when the Aave checker is not initialized.
    error DeltaNeutralStrategy_AaveCheckerNotInitialized();

    /// @notice Thrown when health factor is out of bounds.
    error DeltaNeutralStrategy_HealthFactorOutOfRange();

    /// @notice Thrown when token0 is not wNative.
    error DeltaNeutralStrategy_Token0IsNotWNative();

    /// @notice Thrown when trying to deposit zero.
    error DeltaNeutralStrategy_DepositZero();

    /// @notice Thrown when NFT tokens are not supply and debt tokens.
    error DeltaNeutralStrategy_InvalidNFTTokens();

    // =========================
    // Initializer
    // =========================

    /// @notice Initializes the delta neutral strategy.
    /// @dev Only callable by the owner or the vault itself.
    /// @param uniswapV3NftId The id of the UniswapV3 position.
    /// @param targetHealthFactor_e18 The target health factor to maintain.
    /// @param supplyTokenAave The Aave supply token address.
    /// @param debtTokenAave The Aave debt token address.
    /// @param pointerToAaveChecker The pointer to the Aave checker storage.
    /// @param pointer Pointer to the strategy's storage location.
    function initialize(
        uint256 uniswapV3NftId,
        uint256 targetHealthFactor_e18,
        address supplyTokenAave,
        address debtTokenAave,
        bytes32 pointerToAaveChecker,
        bytes32 pointer
    ) external;

    /// @notice Struct for `initializeWithMint` method
    struct InitializeWithMintParams {
        // The target health factor to maintain
        uint256 targetHealthFactor_e18;
        // The lower tick for uniswap position tick range
        int24 minTick;
        // The upper tick for uniswap position tick range
        int24 maxTick;
        // The fee tier uniswap pool
        uint24 poolFee;
        // The amount of supply token to deposit to new uniswap position
        uint256 supplyTokenAmount;
        // The amount of debt token to deposit to new uniswap position
        uint256 debtTokenAmount;
        // The supply token
        address supplyToken;
        // The debt token
        address debtToken;
        // The pointer to the Aave checker storage
        bytes32 pointerToAaveChecker;
    }

    /// @notice Initializes the delta neutral strategy and mints an dex NFT.
    /// @dev Only callable by the owner or the vault itself.
    /// @param p The parameters required for initialization with mint.
    /// @param pointer Pointer to the strategy's storage location.
    function initializeWithMint(
        InitializeWithMintParams memory p,
        bytes32 pointer
    ) external;

    // =========================
    // Getters
    // =========================

    /// @notice Fetches the health factors for the strategy.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return targetHF The target health factor set for the strategy.
    /// @return currentHF The current health factor of the strategy.
    /// @return uniswapV3NftId The id of the UniswapV3 position which involved to DNS.
    function healthFactorsAndNft(
        bytes32 pointer
    )
        external
        view
        returns (uint256 targetHF, uint256 currentHF, uint256 uniswapV3NftId);

    /// @notice Fetches the total supply token balance.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return The total balance of the supply token.
    function getTotalSupplyTokenBalance(
        bytes32 pointer
    ) external view returns (uint256);

    // =========================
    // Setters
    // =========================

    /// @notice Set a new target health factor.
    /// @param newTargetHF The new target health factor.
    /// @param pointer Pointer to the strategy's storage location.
    function setNewTargetHF(uint256 newTargetHF, bytes32 pointer) external;

    /// @notice Updates the NFT ID used by the strategy.
    /// @param newNftId The new NFT ID to set for the strategy.
    /// @param deviationThresholdE18 The allowable deviation before rebalancing.
    /// @param pointer Pointer to the strategy's storage location.
    function setNewNftId(
        uint256 newNftId,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external;

    // =========================
    // Main functions
    // =========================

    /// @notice Deposits tokens to startegy.
    /// @param amountToDeposit The amount of tokens to deposit.
    /// @param deviationThresholdE18 The allowable deviation before rebalancing.
    /// @param pointer Pointer to the strategy's storage location.
    function deposit(
        uint256 amountToDeposit,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external;

    /// @notice Deposits Native currency (converted to Wrapped) to startegy.
    /// @param amountToDeposit The amount of Native currency to deposit.
    /// @param deviationThresholdE18 The allowable deviation before rebalancing.
    /// @param pointer Pointer to the strategy's storage location.
    function depositETH(
        uint256 amountToDeposit,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external;

    /// @notice Withdraws a percentage share from the leveraged Uniswap position.
    /// @param shareE18 Share to withdraw (in %, 1e18 = 100%).
    /// @param deviationThresholdE18 Deviation threshold for the operation.
    /// @param pointer Pointer to the desired storage.
    function withdraw(
        uint256 shareE18,
        uint256 deviationThresholdE18,
        bytes32 pointer
    ) external;

    /// @notice Rebalance leverage uniswap to target health factor.
    /// @param deviationThresholdE18 Deviation threshold for the operation.
    /// @param pointer Pointer to the desired storage.
    function rebalance(uint256 deviationThresholdE18, bytes32 pointer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TransferHelper
/// @notice A helper library for safe transfers, approvals, and balance checks.
/// @dev Provides safe functions for ERC20 token and native currency transfers.
library TransferHelper {
    // =========================
    // Event
    // =========================

    /// @notice Emits when a transfer is successfully executed.
    /// @param token The address of the token (address(0) for native currency).
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param value The number of tokens (or native currency) transferred.
    event TransferHelperTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when `safeTransferFrom` fails.
    error TransferHelper_SafeTransferFromError();

    /// @notice Thrown when `safeTransfer` fails.
    error TransferHelper_SafeTransferError();

    /// @notice Thrown when `safeApprove` fails.
    error TransferHelper_SafeApproveError();

    /// @notice Thrown when `safeGetBalance` fails.
    error TransferHelper_SafeGetBalanceError();

    /// @notice Thrown when `safeTransferNative` fails.
    error TransferHelper_SafeTransferNativeError();

    // =========================
    // Functions
    // =========================

    /// @notice Executes a safe transfer from one address to another.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (
            !_makeCall(
                token,
                abi.encodeCall(IERC20.transferFrom, (from, to, value))
            )
        ) {
            revert TransferHelper_SafeTransferFromError();
        }

        emit TransferHelperTransfer(token, from, to, value);
    }

    /// @notice Executes a safe transfer.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransfer(address token, address to, uint256 value) internal {
        if (!_makeCall(token, abi.encodeCall(IERC20.transfer, (to, value)))) {
            revert TransferHelper_SafeTransferError();
        }

        emit TransferHelperTransfer(token, address(this), to, value);
    }

    /// @notice Executes a safe approval.
    /// @dev Uses low-level calls to handle cases where allowance is not zero
    /// and tokens which are not supports approve with non-zero allowance.
    /// @param token Address of the ERC20 token to approve.
    /// @param spender Address of the account that gets the approval.
    /// @param value Amount to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            IERC20.approve,
            (spender, value)
        );

        if (!_makeCall(token, approvalCall)) {
            if (
                !_makeCall(
                    token,
                    abi.encodeCall(IERC20.approve, (spender, 0))
                ) || !_makeCall(token, approvalCall)
            ) {
                revert TransferHelper_SafeApproveError();
            }
        }
    }

    /// @notice Retrieves the balance of an account safely.
    /// @dev Uses low-level staticcall to ensure proper error handling.
    /// @param token Address of the ERC20 token.
    /// @param account Address of the account to fetch balance for.
    /// @return The balance of the account.
    function safeGetBalance(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length == 0) {
            revert TransferHelper_SafeGetBalanceError();
        }
        return abi.decode(data, (uint256));
    }

    /// @notice Executes a safe transfer of native currency (e.g., ETH).
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            revert TransferHelper_SafeTransferNativeError();
        }

        emit TransferHelperTransfer(address(0), address(this), to, value);
    }

    // =========================
    // Private function
    // =========================

    /// @dev Helper function to make a low-level call for token methods.
    /// @dev Ensures correct return value and decodes it.
    ///
    /// @param token Address to make the call on.
    /// @param data Calldata for the low-level call.
    /// @return True if the call succeeded, false otherwise.
    function _makeCall(
        address token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = token.call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlLib} from "./AccessControlLib.sol";
import {Constants} from "./Constants.sol";

/// @title BaseContract
/// @notice A base contract that provides common access control features.
/// @dev This contract integrates with AccessControlLib to provide role-based access
/// control and ownership checks. Contracts inheriting from this can use its modifiers
/// for common access restrictions.
contract BaseContract {
    // =========================
    // Error
    // =========================

    /// @notice Thrown when an account is not authorized to perform a specific action.
    error UnauthorizedAccount(address account);

    // =========================
    // Modifiers
    // =========================

    /// @dev Modifier that checks if an account has a specific `role`
    /// or is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if the conditions are not met.
    modifier onlyRoleOrOwner(bytes32 role) {
        _checkRole(role, msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwner() {
        _checkOnlyOwner(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyVaultItself() {
        _checkOnlyVaultItself(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner
    /// or the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwnerOrVaultItself() {
        _checkOnlyOwnerOrVaultItself(msg.sender);

        _;
    }

    // =========================
    // Internal function
    // =========================

    /// @dev Checks if the given `account` possesses the specified `role` or is the owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    function _checkRole(bytes32 role, address account) internal view virtual {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (
            !((msg.sender == AccessControlLib.getOwner()) ||
                _hasRole(s, role, account))
        ) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyVaultItself(address account) internal view virtual {
        if (account != address(this)) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwnerOrVaultItself(
        address account
    ) internal view virtual {
        if (account == address(this)) {
            return;
        }

        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwner(address account) internal view virtual {
        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    /// @param s The storage reference for roles from AccessControlLib.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    /// @return True if the account possesses the role, false otherwise.
    function _hasRole(
        AccessControlLib.RolesStorage storage s,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return s.roles[role][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import {IV3SwapRouter} from "../interfaces/external/IV3SwapRouter.sol";
import {PositionValueMod} from "../libraries/utils/PositionValueMod.sol";

import {TransferHelper} from "../libraries/utils/TransferHelper.sol";

/// @title DexLogicLib
/// @notice Library for executing trades and managing positions on Uniswap V3.
library DexLogicLib {
    // =========================
    // Constants
    // =========================

    uint256 private constant E18 = 1e18;
    uint256 private constant E6 = 1e6;

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when MEV check detects a deviation of price too high.
    error MEVCheck_DeviationOfPriceTooHigh();

    /// @notice Thrown when zero number of tokens are attempted to be added.
    error DexLogicLib_ZeroNumberOfTokensCannotBeAdded();

    /// @notice Thrown when there are not enough token balances on the vault.LiquidityAmounts
    error DexLogicLib_NotEnoughTokenBalances();

    // =========================
    // Main library logic
    // =========================

    /// @dev Get the current square root price of a Uniswap V3 pool
    /// @param _dexPool Address of the Uniswap V3 pool
    /// @return sqrtPriceX96 Square root price of the pool
    function getCurrentSqrtRatioX96(
        IUniswapV3Pool _dexPool
    ) internal view returns (uint160 sqrtPriceX96) {
        // to call the method slot0 without caring which dex the pool belongs we call without the interface
        (, bytes memory data) = address(_dexPool).staticcall(
            // 0x3850c7bd - selector of "slot0()"
            abi.encodeWithSelector(0x3850c7bd)
        );
        (sqrtPriceX96, , , , , , ) = abi.decode(
            data,
            (uint160, int24, uint16, uint16, uint16, uint256, bool)
        );
    }

    /// @dev Retrieve the liquidity of a given NFT position
    /// @param nftId The ID of the NFT position
    /// @param dexNftPositionManager The address of the NonfungiblePositionManager contract
    /// @return Liquidity of the given NFT position
    function getLiquidity(
        uint256 nftId,
        INonfungiblePositionManager dexNftPositionManager
    ) internal view returns (uint128) {
        (, , , , , , , uint128 liquidity, , , , ) = dexNftPositionManager
            .positions(nftId);
        return liquidity;
    }

    /// @notice Calculates the amount of token0 in terms of token1 based on the square root of the price.
    /// @param sqrtPriceX96 The square root of the price, represented as a X96 fixed point number.
    /// @param amount0 The amount of token0.
    /// @return The equivalent amount of token0 in terms of token1.
    function getAmount0InToken1(
        uint160 sqrtPriceX96,
        uint256 amount0
    ) internal pure returns (uint256) {
        uint256 priceX128 = FullMath.mulDiv(
            sqrtPriceX96,
            sqrtPriceX96,
            1 << 64
        );

        return FullMath.mulDiv(priceX128, uint128(amount0), 1 << 128);
    }

    /// @dev Calculates the amount of token1 in terms of token0 based on the square root of the price.
    /// @param sqrtPriceX96 The square root of the price, represented as a X96 fixed point number.
    /// @param amount1 The amount of token1.
    /// @return The equivalent amount of token1 in terms of token0.
    function getAmount1InToken0(
        uint160 sqrtPriceX96,
        uint256 amount1
    ) internal pure returns (uint256) {
        uint256 priceX128 = FullMath.mulDiv(
            sqrtPriceX96,
            sqrtPriceX96,
            1 << 64
        );

        return FullMath.mulDiv(1 << 128, uint128(amount1), priceX128);
    }

    /// @notice Gets the correlation of token0 to token1.
    /// @param amount0 The amount of token0.
    /// @param amount1 The amount of token1.
    /// @param sqrtPriceX96 The square root of the current spot price.
    /// @return res The correlation value between token0 and token1,
    /// represented as an E18 fixed point number.
    ///
    /// @dev res = px / (px + y) * 10^18
    /// where:
    ///  x - amount0
    ///  y - amount1
    ///  p - current spot price
    function getRE18(
        uint256 amount0,
        uint256 amount1,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 res) {
        uint256 amount0InToken1 = getAmount0InToken1(sqrtPriceX96, amount0);

        uint256 denominator;
        unchecked {
            denominator = amount0InToken1 + amount1;
        }

        // get the correlation of token0 to token1
        res = FullMath.mulDiv(amount0InToken1, E18, denominator);
    }

    /// @dev Gets the correlation of of token0 to token1 in the current tickRange
    /// by totalPoolLiquidity.
    /// @param minTick The minimum tick of the range.
    /// @param maxTick The maximum tick of the range.
    /// @param totalPoolLiquidity The total liquidity in the pool.
    /// @param sqrtPriceX96 The square root of the current spot price.
    /// @return res The correlation value between token0 and token1 within the specified tick range,
    /// represented as an E18 fixed point number.
    ///
    /// @dev res = px / (px + y) * 10^18
    /// where:
    ///  x - amount0 for total pool liquidity
    ///  y - amount1 for total pool liquidity
    ///  p - current spot price
    function getTargetRE18ForTickRange(
        int24 minTick,
        int24 maxTick,
        uint128 totalPoolLiquidity,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 res) {
        if (totalPoolLiquidity < 1e18) {
            totalPoolLiquidity = 1e18;
        }

        // get the amount of token0 and token1 unified amount of liquidity
        (
            uint256 amount0ForLiquidity,
            uint256 amount1ForLiquidity
        ) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                (TickMath.getSqrtRatioAtTick(minTick)),
                (TickMath.getSqrtRatioAtTick(maxTick)),
                totalPoolLiquidity
            );

        uint256 amount0ForLiquidityInToken1 = getAmount0InToken1(
            sqrtPriceX96,
            amount0ForLiquidity
        );

        uint256 denominator;
        unchecked {
            denominator = amount0ForLiquidityInToken1 + amount1ForLiquidity;
        }

        // get the correlation of token0 to token1
        res = FullMath.mulDiv(amount0ForLiquidityInToken1, E18, denominator);
    }

    /// @dev Fetches position data for a specific NFT ID from the
    /// Uniswap V3 Nonfungible Position Manager.
    /// @param nftId The ID of the NFT.
    /// @param dexNftPositionManager The Nonfungible Position Manager interface.
    /// @return token0 The address of the token0 of the position.
    /// @return token1 The address of the token1 of the position.
    /// @return poolFee The fee tier of the pool in which the position resides.
    /// @return tickLower The lower tick of the position's range.
    /// @return tickUpper The upper tick of the position's range.
    /// @return liquidity The liquidity of the position.
    function getNftData(
        uint256 nftId,
        INonfungiblePositionManager dexNftPositionManager
    )
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        )
    {
        (
            ,
            ,
            token0,
            token1,
            poolFee,
            tickLower,
            tickUpper,
            liquidity,
            ,
            ,
            ,

        ) = dexNftPositionManager.positions(nftId);
    }

    /// @dev Fetches the Uniswap V3 pool for the specified tokens and fee tier.
    /// @param token0 The address of token0.
    /// @param token1 The address of token1.
    /// @param poolFee The fee tier for which to fetch the pool.
    /// @param dexFactory The Uniswap V3 Factory interface.
    /// @return The address of the Uniswap V3 pool for the specified tokens and fee tier.
    function dexPool(
        address token0,
        address token1,
        uint24 poolFee,
        IUniswapV3Factory dexFactory
    ) internal view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(dexFactory.getPool(token0, token1, poolFee));
    }

    /// @dev Checks for potential MEV attacks by comparing the spot price to the oracle price
    /// @param deviationThresholdE18 The maximum allowed deviation between spot and oracle prices
    /// @param _dexPool Address of the Uniswap V3 pool
    /// @param period Period for which the time-weighted average price (TWAP) is calculated
    function MEVCheck(
        uint256 deviationThresholdE18,
        IUniswapV3Pool _dexPool,
        uint32 period
    ) internal view {
        uint160 sqrtPriceX96 = getCurrentSqrtRatioX96(_dexPool);
        uint256 spotPrice = getAmount0InToken1(sqrtPriceX96, E18);

        (int24 timeWeightedAverageTick, ) = OracleLibrary.consult(
            address(_dexPool),
            period
        );

        uint256 oraclePrice = getAmount0InToken1(
            TickMath.getSqrtRatioAtTick(timeWeightedAverageTick),
            E18
        );

        uint256 delta;
        unchecked {
            uint256 proportion = (spotPrice * E18) / oraclePrice;

            delta = proportion > E18 ? proportion - E18 : E18 - proportion;
        }

        if (delta > deviationThresholdE18) {
            revert MEVCheck_DeviationOfPriceTooHigh();
        }
    }

    /// @dev Withdraws a position from the Uniswap V3 Nonfungible Position Manager.
    /// @dev This function decreases the liquidity of a position and collects any fees.
    /// @param nftId The ID of the NFT representing the position to be withdrawn.
    /// @param liquidity The amount of liquidity to be withdrawn.
    /// @param dexNftPositionManager The Nonfungible Position Manager from which the position is withdrawn.
    /// @return amount0 The amount of token0 collected as fees.
    /// @return amount1 The amount of token1 collected as fees.
    function withdrawPositionMEVUnsafe(
        uint256 nftId,
        uint128 liquidity,
        INonfungiblePositionManager dexNftPositionManager
    ) internal returns (uint256, uint256) {
        dexNftPositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: nftId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        // collect all fees
        return collectFees(nftId, dexNftPositionManager);
    }

    /// @dev Collects accumulated fees for a specific position from the Uniswap
    /// V3 Nonfungible Position Manager.
    /// @param nftId The ID of the NFT representing the position for which fees are collected.
    /// @param dexNftPositionManager The Nonfungible Position Manager from which fees are collected.
    /// @return amount0 The amount of token0 collected as fees.
    /// @return amount1 The amount of token1 collected as fees.
    function collectFees(
        uint256 nftId,
        INonfungiblePositionManager dexNftPositionManager
    ) internal returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = dexNftPositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: nftId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    /// @dev Swaps assets in the Uniswap V3 pool to reach a target correlation between the assets.
    /// @param tickUpper The upper tick of the range in which the liquidity is added.
    /// @param tickLower The lower tick of the range in which the liquidity is added.
    /// @param token0Amount The amount of token0.
    /// @param token1Amount The amount of token1.
    /// @param _dexPool The Uniswap V3 pool used for the swap.
    /// @param token0 The address of token0.
    /// @param token1 The address of token1.
    /// @param poolFee The pool fee rate.
    /// @param dexRouter The Uniswap V3 router to conduct the swap.
    /// @return The amounts of token0 and token1 after the swap.
    function swapToTargetRMEVUnsafe(
        int24 tickUpper,
        int24 tickLower,
        uint256 token0Amount,
        uint256 token1Amount,
        IUniswapV3Pool _dexPool,
        address token0,
        address token1,
        uint24 poolFee,
        IV3SwapRouter dexRouter
    ) internal returns (uint256, uint256) {
        uint160 sqrtPriceX96 = getCurrentSqrtRatioX96(_dexPool);
        uint256 targetRE18 = getTargetRE18ForTickRange(
            tickLower,
            tickUpper,
            _dexPool.liquidity(),
            sqrtPriceX96
        );

        uint256 amount1Target = token1AmountAfterSwapForTargetRE18(
            sqrtPriceX96,
            token0Amount,
            token1Amount,
            targetRE18,
            poolFee
        );

        (token0Amount, token1Amount) = swapAssetsMEVUnsafe(
            token0Amount,
            token1Amount,
            amount1Target,
            targetRE18,
            token0,
            token1,
            poolFee,
            dexRouter
        );

        return (token0Amount, token1Amount);
    }

    /// @dev Calculates the amount of token1 required to achieve a target rate after a swap.
    /// @param sqrtPriceX96 The current square root price of the pool.
    /// @param amount0 The amount of token0.
    /// @param amount1 The amount of token1.
    /// @param targetRE18 The target rate.
    /// @param poolFeeE6 The pool fee rate.
    /// @return The target amount of token1.
    ///
    /// @dev y1 = (R1 - Rtg) / (R1 - Rtg * poolFee / feeMax) * (y0 +  p * x0 * (F1 - poolFee) / feeMax)
    /// where:
    ///  y1 - target amount token1
    ///  R1 - 1e14
    ///  Rtg - target rate (from getTargetRE18ForTickRange)
    ///  feeMax - 1e6
    ///  y0 - initial amount token1
    ///  x0 - initial amount token0
    ///  p - current pool price
    ///
    /// source: https://www.desmos.com/calculator/c3a9zuij81
    function token1AmountAfterSwapForTargetRE18(
        uint160 sqrtPriceX96,
        uint256 amount0,
        uint256 amount1,
        uint256 targetRE18,
        uint24 poolFeeE6
    ) internal pure returns (uint256) {
        uint256 px0 = getAmount0InToken1(sqrtPriceX96, amount0);

        uint256 oneMinusRtgE18 = E18 - targetRE18;
        uint256 oneMinusRtgFee = E18 - (targetRE18 * poolFeeE6) / E6;

        uint256 firstMultiplier = (oneMinusRtgE18 * E18) / oneMinusRtgFee;
        uint256 secondMultiplier = ((E6 - poolFeeE6) * px0) / E6 + amount1;

        return (firstMultiplier * secondMultiplier) / E18;
    }

    /// @dev Calculates the amount of token0 required to achieve a target rate after a swap.
    /// @param sqrtPriceX96 The current square root price of the pool.
    /// @param amount1 The amount of token1.
    /// @param targetRE18 The target rate.
    /// @return The target amount of token0.
    ///
    /// @dev x1 = Rtg / (R1 - Rtg) * (y1 / p)
    /// where:
    ///  y1 - target amount token1
    ///  R1 - 1e14
    ///  Rtg - target rate (from getTargetRE18ForTickRange)
    ///  p - current pool price
    ///
    /// source: https://www.desmos.com/calculator/c3a9zuij81
    function token0AmountAfterSwapForTargetRE18(
        uint160 sqrtPriceX96,
        uint256 amount1,
        uint256 targetRE18
    ) internal pure returns (uint256) {
        uint256 py1 = getAmount1InToken0(sqrtPriceX96, amount1);

        uint256 oneMinusRtgE18 = E18 - targetRE18;

        uint256 multiplier = FullMath.mulDiv(targetRE18, E18, oneMinusRtgE18);

        return (multiplier * py1) / E18;
    }

    /// @dev Swap tokens in a given direction, ensuring the resulting balance matches the target.
    /// @dev This function might revert if the swap cannot be executed.
    /// @param amount0 Amount of token0.
    /// @param amount1 Amount of token1.
    /// @param amount1Target The target amount for token1.
    /// @param targetR The target correlation.
    /// @param token0 Address of token0.
    /// @param token1 Address of token1.
    /// @param poolFee The pool's fee rate.
    /// @param dexRouter The router to facilitate the swap.
    /// @return The new balances of token0 and token1.
    function swapAssetsMEVUnsafe(
        uint256 amount0,
        uint256 amount1,
        uint256 amount1Target,
        uint256 targetR,
        address token0,
        address token1,
        uint24 poolFee,
        IV3SwapRouter dexRouter
    ) internal returns (uint256, uint256) {
        // swap tokens
        if (amount1 > amount1Target) {
            uint256 amountForSwap;
            unchecked {
                amountForSwap = amount1 - amount1Target;
            }

            uint256 amountOut = swapExactInputMEVUnsafe(
                token1,
                token0,
                poolFee,
                amountForSwap,
                dexRouter
            );
            unchecked {
                // update balances
                return (amount0 + amountOut, amount1Target);
            }
        } else if (amount1Target > amount1) {
            if (targetR == 0) {
                // if token0 is not needed at all
                uint256 amountOut = swapExactInputMEVUnsafe(
                    token0,
                    token1,
                    poolFee,
                    amount0,
                    dexRouter
                );
                unchecked {
                    // update balances
                    return (0, amount1 + amountOut);
                }
            } else {
                uint256 amountForSwap;
                unchecked {
                    amountForSwap = amount1Target - amount1;
                }

                // Since we don't know the exact number of tokens to be given in the SwapExactOutput method,
                // we do approve for the entire transferred balance of token0
                TransferHelper.safeApprove(token0, address(dexRouter), amount0);

                uint256 amountIn = swapExactOutputMEVUnsafe(
                    token0,
                    token1,
                    poolFee,
                    amountForSwap,
                    dexRouter
                );

                unchecked {
                    // update balances
                    // underflow is impossible, the check was during the swap
                    return (amount0 - amountIn, amount1Target);
                }
            }
        } else {
            return (amount0, amount1);
        }
    }

    /// @dev Swap an exact input amount for as much output as possible.
    /// @dev This function might revert if the swap cannot be executed.
    /// @param tokenIn The token to be provided.
    /// @param tokenOut The token to be received.
    /// @param poolFee The pool's fee rate.
    /// @param amountForSwap Amount of `tokenIn` to be swapped.
    /// @param dexRouter The router to facilitate the swap.
    /// @return The amount of `tokenOut` received.
    function swapExactInputMEVUnsafe(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountForSwap,
        IV3SwapRouter dexRouter
    ) internal returns (uint256) {
        TransferHelper.safeApprove(tokenIn, address(dexRouter), amountForSwap);

        return
            dexRouter.exactInputSingle(
                IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: poolFee,
                    recipient: address(this),
                    amountIn: amountForSwap,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
    }

    /// @dev Swap as input as needed to receive the exact output amount.
    /// @dev This function might revert if the swap cannot be executed.
    /// @param tokenIn The token to be provided.
    /// @param tokenOut The token to be received.
    /// @param poolFee The pool's fee rate.
    /// @param amountForSwap Amount of `tokenOut` to be received.
    /// @param dexRouter The router to facilitate the swap.
    /// @return The amount of `tokenIn` spent.
    function swapExactOutputMEVUnsafe(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountForSwap,
        IV3SwapRouter dexRouter
    ) internal returns (uint256) {
        return
            dexRouter.exactOutputSingle(
                IV3SwapRouter.ExactOutputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: poolFee,
                    recipient: address(this),
                    amountOut: amountForSwap,
                    amountInMaximum: type(uint256).max,
                    sqrtPriceLimitX96: 0
                })
            );
    }

    /// @dev Mints a new NFT.
    /// @dev This function might revert if the minting cannot be executed.
    /// @param token0Amount Amount of token0.
    /// @param token1Amount Amount of token1.
    /// @param tickLower The lower end of the tick range.
    /// @param tickUpper The upper end of the tick range.
    /// @param token0 Address of token0.
    /// @param token1 Address of token1.
    /// @param poolFee The pool's fee rate.
    /// @param dexNftPositionManager The position manager to facilitate minting.
    /// @return The ID of the minted NFT.
    function mintNftMEVUnsafe(
        uint256 token0Amount,
        uint256 token1Amount,
        int24 tickLower,
        int24 tickUpper,
        address token0,
        address token1,
        uint24 poolFee,
        INonfungiblePositionManager dexNftPositionManager
    ) internal returns (uint256) {
        // if nothing is added to the new token, then revert,
        // since the nft will not be created anyway
        if (token0Amount == 0 && token1Amount == 0) {
            revert DexLogicLib_ZeroNumberOfTokensCannotBeAdded();
        }

        if (token0 > token1) {
            (token0, token1) = ((token1, token0));
            (token0Amount, token1Amount) = ((token1Amount, token0Amount));
        }

        TransferHelper.safeApprove(
            token0,
            address(dexNftPositionManager),
            token0Amount
        );
        TransferHelper.safeApprove(
            token1,
            address(dexNftPositionManager),
            token1Amount
        );

        INonfungiblePositionManager.MintParams memory mintParams;
        mintParams.token0 = token0;
        mintParams.token1 = token1;
        mintParams.fee = poolFee;
        mintParams.tickLower = tickLower;
        mintParams.tickUpper = tickUpper;
        mintParams.amount0Desired = token0Amount;
        mintParams.amount1Desired = token1Amount;
        mintParams.recipient = address(this);
        mintParams.deadline = block.timestamp;

        (uint256 nftId, , , ) = dexNftPositionManager.mint(mintParams);
        return (nftId);
    }

    /// @dev Increases the liquidity of a specific NFT position.
    /// @dev This function might revert if the operation cannot be executed.
    /// @param nftId The ID of the NFT position.
    /// @param token0Amount Amount of token0.
    /// @param token1Amount Amount of token1.
    /// @param dexNftPositionManager The position manager to facilitate liquidity increase.
    function increaseLiquidityMEVUnsafe(
        uint256 nftId,
        uint256 token0Amount,
        uint256 token1Amount,
        INonfungiblePositionManager dexNftPositionManager
    ) internal {
        if (token0Amount == 0 && token1Amount == 0) {
            return;
        }

        dexNftPositionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: nftId,
                amount0Desired: token0Amount,
                amount1Desired: token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
    }

    /// @dev Validates that the vault has enough balance of a token.
    /// @dev This function might revert if the balance is insufficient.
    /// @param token The token's address.
    /// @param tokenAmount The required amount.
    function validateTokenBalance(
        address token,
        uint256 tokenAmount
    ) internal view {
        uint256 tokenBalance = TransferHelper.safeGetBalance(
            token,
            address(this)
        );

        if (tokenAmount > tokenBalance) {
            revert DexLogicLib_NotEnoughTokenBalances();
        }
    }

    /// @dev Retrieves the fees accrued to a specific NFT position.
    /// @dev This function uses PositionValueMod.fees internally.
    /// @param nftId The ID of the NFT position.
    /// @param _dexPool The relevant Uniswap V3 pool.
    /// @param dexNftPositionManager The position manager to query fees.
    /// @return The fees of token0 and token1.
    function fees(
        uint256 nftId,
        IUniswapV3Pool _dexPool,
        INonfungiblePositionManager dexNftPositionManager
    ) internal view returns (uint256, uint256) {
        (uint256 amount0, uint256 amount1) = PositionValueMod.fees(
            dexNftPositionManager,
            nftId,
            _dexPool
        );
        return (amount0, amount1);
    }

    /// @dev Calculates the total value locked in a specific NFT position.
    /// @dev This function uses PositionValueMod.total internally.
    /// @param nftId The ID of the NFT position.
    /// @param _dexPool The relevant Uniswap V3 pool.
    /// @param dexNftPositionManager The position manager to calculate TVL.
    /// @return The amounts of token0 and token1.
    function tvl(
        uint256 nftId,
        IUniswapV3Pool _dexPool,
        INonfungiblePositionManager dexNftPositionManager
    ) internal view returns (uint256, uint256) {
        uint160 sqrtPriceX96 = DexLogicLib.getCurrentSqrtRatioX96(_dexPool);

        (uint256 amount0, uint256 amount1) = PositionValueMod.total(
            dexNftPositionManager,
            nftId,
            sqrtPriceX96,
            _dexPool
        );
        return (amount0, amount1);
    }

    /// @notice Retrieves the principal amounts for a specific NFT position.
    /// @dev This function uses PositionValueMod.principal internally.
    /// @param nftId The ID of the NFT position.
    /// @param _dexPool The relevant Uniswap V3 pool.
    /// @param dexNftPositionManager The position manager to retrieve principal amounts.
    /// @return The principal amounts of token0 and token1.
    function principal(
        uint256 nftId,
        IUniswapV3Pool _dexPool,
        INonfungiblePositionManager dexNftPositionManager
    ) internal view returns (uint256, uint256) {
        uint160 sqrtPriceX96 = DexLogicLib.getCurrentSqrtRatioX96(_dexPool);

        (uint256 amount0, uint256 amount1) = PositionValueMod.principal(
            dexNftPositionManager,
            nftId,
            sqrtPriceX96
        );
        return (amount0, amount1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPool} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {IVariableDebtToken} from "@aave/aave-v3-core/contracts/interfaces/IVariableDebtToken.sol";
import {IAToken} from "@aave/aave-v3-core/contracts/interfaces/IAToken.sol";
import {IPoolDataProvider} from "@aave/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {IPoolAddressesProvider} from "@aave/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

import {TransferHelper} from "../libraries/utils/TransferHelper.sol";
import {IV3SwapRouter} from "../interfaces/external/IV3SwapRouter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AaveLogicLib
library AaveLogicLib {
    // =========================
    // Constants
    // =========================

    uint16 private constant REFFERAL_CODE = 0;
    uint256 private constant INTEREST_RATE_MODEL = 2;

    // =========================
    // Events
    // =========================

    /// @notice Emits when tokens are borrowed from Aave.
    /// @param token The token that was borrowed.
    /// @param amount The amount of tokens borrowed.
    event AaveBorrow(address token, uint256 amount);

    /// @notice Emits when tokens are supplied to Aave.
    /// @param token The token that was supplied.
    /// @param amount The amount of tokens supplied.
    event AaveSupply(address token, uint256 amount);

    /// @notice Emits when a loan is repaid to Aave.
    /// @param token The token that was repaid.
    /// @param amount The amount of tokens repaid.
    event AaveRepay(address token, uint256 amount);

    /// @notice Emits when tokens are withdrawn from Aave.
    /// @param token The token that was withdrawn.
    /// @param amount The amount of tokens withdrawn.
    event AaveWithdraw(address token, uint256 amount);

    /// @notice Emits when an emergency repayment is made using Aave's flash loan mechanism.
    /// @param supplyToken The token used to repay the debt.
    /// @param debtToken The token that was in debt.
    event AaveEmergencyRepay(address supplyToken, address debtToken);

    /// @notice Emits when a Aave's flash loan is executed.
    event AaveFlashLoan();

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when the initiator of the flashLoan Aave operation
    /// is not valid or authorized.
    error AaveLogicLib_InitiatorNotValid();

    // =========================
    // Main Functions
    // =========================

    /// @dev Borrows a specified `amount` of a `token` using Aave.
    /// @param token The address of the token to be borrowed.
    /// @param amount The amount of the token to be borrowed.
    /// @param user The address of the user borrowing the token.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    function borrowAave(
        address token,
        uint256 amount,
        address user,
        IPoolAddressesProvider poolAddressesProvider
    ) internal {
        IPool pool = IPool(poolAddressesProvider.getPool());
        pool.borrow(token, amount, INTEREST_RATE_MODEL, 0, user);

        emit AaveBorrow(token, amount);
    }

    /// @dev Supplies a specified `amount` of a `token` to Aave.
    /// @param token The address of the token to be supplied.
    /// @param amount The amount of the token to be supplied.
    /// @param user The address of the user supplying the token.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    function supplyAave(
        address token,
        uint256 amount,
        address user,
        IPoolAddressesProvider poolAddressesProvider
    ) internal {
        IPool pool = IPool(poolAddressesProvider.getPool());
        TransferHelper.safeApprove(token, address(pool), amount);

        pool.supply(token, amount, user, 0);

        emit AaveSupply(token, amount);
    }

    /// @dev Repays a borrowed `amount` of a `token` using Aave.
    /// @param token The address of the token to be repaid.
    /// @param amount The amount of the token to be repaid.
    /// @param user The address of the user repaying the token.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    function repayAave(
        address token,
        uint256 amount,
        address user,
        IPoolAddressesProvider poolAddressesProvider
    ) internal {
        uint256 balance = TransferHelper.safeGetBalance(token, user);
        if (balance < amount) {
            amount = balance;
        }

        IPool pool = IPool(poolAddressesProvider.getPool());
        TransferHelper.safeApprove(token, address(pool), amount);

        pool.repay(token, amount, INTEREST_RATE_MODEL, user);

        emit AaveRepay(token, amount);
    }

    /// @dev Withdraws a specified `amount` of a `token` from Aave.
    /// @param token The address of the token to be withdrawn.
    /// @param amount The amount of the token to be withdrawn.
    /// @param user The address of the user withdrawing the token.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    function withdrawAave(
        address token,
        uint256 amount,
        address user,
        IPoolAddressesProvider poolAddressesProvider
    ) internal {
        IPool pool = IPool(poolAddressesProvider.getPool());
        pool.withdraw(token, amount, user);

        emit AaveWithdraw(token, amount);
    }

    /// @dev Executes an emergency repayment on Aave using a flash loan.
    /// @param supplyToken The address of the supply token.
    /// @param debtToken The address of the debt token.
    /// @param onBehalfOf The address on whose behalf the operation is being executed.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    /// @param poolFee The fee tier in the uniswapV3 pool.
    function emergencyRepayAave(
        address supplyToken,
        address debtToken,
        address onBehalfOf,
        IPoolAddressesProvider poolAddressesProvider,
        uint24 poolFee
    ) internal {
        IPool pool = IPool(poolAddressesProvider.getPool());

        address aDebtToken = aDebtTokenAddress(debtToken, pool);
        bytes memory params = abi.encode(supplyToken, onBehalfOf, poolFee);

        uint256 remainingSupply = IERC20(supplyToken).balanceOf(address(this));

        pool.flashLoanSimple(
            address(this),
            debtToken,
            getTotalDebt(aDebtToken, onBehalfOf),
            params,
            REFFERAL_CODE
        );

        // return remaining supply amount back to aave
        remainingSupply =
            IERC20(supplyToken).balanceOf(address(this)) -
            remainingSupply;

        if (remainingSupply > 0) {
            IERC20(supplyToken).approve(address(pool), remainingSupply);
            pool.supply(supplyToken, remainingSupply, onBehalfOf, 0);
        }

        emit AaveEmergencyRepay(supplyToken, debtToken);
    }

    /// @dev Callback function for Aave flash loan.
    /// @param asset The address of the asset involved in the flash loan.
    /// @param amount The amount involved in the flash loan.
    /// @param premium The premium to be paid for the flash loan.
    /// @param initiator The address that initiated the flash loan.
    /// @param params Additional parameters related to the flash loan.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    /// @param uniswapRouter The Uniswap router for token swaps.
    /// @return A boolean indicating if the operation was successful.
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params,
        IPoolAddressesProvider poolAddressesProvider,
        IV3SwapRouter uniswapRouter
    ) internal returns (bool) {
        if (initiator != address(this)) {
            revert AaveLogicLib_InitiatorNotValid();
        }

        IPool pool = IPool(poolAddressesProvider.getPool());

        // call must be from the pool contract
        if (msg.sender != address(pool)) {
            revert AaveLogicLib_InitiatorNotValid();
        }

        (address supplyToken, address onBehalfOf, uint24 poolFee) = abi.decode(
            params,
            (address, address, uint24)
        );

        // repay borrowed amount to aave position
        IERC20(asset).approve(address(pool), type(uint256).max);
        pool.repay(asset, amount, 2, onBehalfOf);

        if (onBehalfOf != address(this)) {
            address aSupplyToken = aSupplyTokenAddress(supplyToken, pool);
            uint256 supplyAmount = IAToken(aSupplyToken).balanceOf(onBehalfOf);
            IAToken(aSupplyToken).transferFrom(
                onBehalfOf,
                address(this),
                supplyAmount
            );
        }

        // withdraw max suplyAmount from aave position
        pool.withdraw(supplyToken, type(uint256).max, address(this));

        uint256 amountOwing = amount + premium;
        // cache for avoiding stack too deep error
        address _asset = asset;

        // swap withdrawed supplyToken for debtToken for repay loaned amount
        IERC20(supplyToken).approve(address(uniswapRouter), type(uint256).max);
        uniswapRouter.exactOutputSingle(
            IV3SwapRouter.ExactOutputSingleParams({
                tokenIn: supplyToken,
                tokenOut: _asset,
                fee: poolFee,
                recipient: address(this),
                amountOut: amountOwing,
                amountInMaximum: type(uint256).max,
                sqrtPriceLimitX96: 0
            })
        );
        IERC20(asset).approve(address(pool), amountOwing);

        emit AaveFlashLoan();
        return true;
    }

    // =========================
    // View Functions
    // =========================

    /// @dev Retrieves the amount of `supplyToken` supplied by a user to Aave.
    /// @param supplyToken The address of the supply token.
    /// @param user The address of the user.
    /// @return The amount supplied by the user.
    function getSupplyAmount(
        address supplyToken,
        address user
    ) internal view returns (uint256) {
        return IAToken(supplyToken).balanceOf(user);
    }

    /// @dev Retrieves the total debt of a user in a `debtToken`.
    /// @param debtToken The address of the debt token.
    /// @param user The address of the user.
    /// @return The total debt of the user in the specified token.
    function getTotalDebt(
        address debtToken,
        address user
    ) internal view returns (uint256) {
        return IERC20(debtToken).balanceOf(user);
    }

    /// @dev Retrieves the current health factor of a user in Aave.
    /// @param user The address of the user.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    /// @return currentHF The current health factor of the user.
    function getCurrentHF(
        address user,
        IPoolAddressesProvider poolAddressesProvider
    ) internal view returns (uint256 currentHF) {
        (, , , , , currentHF) = IPool(poolAddressesProvider.getPool())
            .getUserAccountData(user);
    }

    /// @dev Retrieves the current liquidation threshold for a `token` in Aave.
    /// @param token The address of the token.
    /// @param poolAddressesProvider The provider of pool addresses for Aave.
    /// @return currentLiquidationThreshold_1e4 The current liquidation threshold for the token.
    function getCurrentLiquidationThreshold(
        address token,
        IPoolAddressesProvider poolAddressesProvider
    ) internal view returns (uint256 currentLiquidationThreshold_1e4) {
        IPoolDataProvider poolDataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );
        (, , currentLiquidationThreshold_1e4, , , , , , , ) = poolDataProvider
            .getReserveConfigurationData(token);
    }

    /// @dev Retrieves the Aave debt token address for a specific `asset`.
    /// @param asset The address of the asset.
    /// @param pool The Aave pool instance.
    /// @return The address of the Aave debt token for the asset.
    function aDebtTokenAddress(
        address asset,
        IPool pool
    ) internal view returns (address) {
        return pool.getReserveData(asset).variableDebtTokenAddress;
    }

    /// @dev Retrieves the Aave supply token address for a specific `asset`.
    /// @param asset The address of the asset.
    /// @param pool The Aave pool instance.
    /// @return The address of the Aave supply token for the asset.
    function aSupplyTokenAddress(
        address asset,
        IPool pool
    ) internal view returns (address) {
        return pool.getReserveData(asset).aTokenAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   */
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   */
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62: siloed borrowing enabled
    //bit 63: flashloaning enabled
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IScaledBalanceToken
 * @author Aave
 * @notice Defines the basic interface for a scaled-balance token.
 */
interface IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted tokens
   * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
   * @param index The next liquidity index of the reserve
   */
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @dev Emitted after the burn action
   * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
   * @param from The address from which the tokens will be burned
   * @param target The address that will receive the underlying, if any
   * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
   * @param index The next liquidity index of the reserve
   */
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @notice Returns the scaled balance of the user.
   * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
   * at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   */
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled total supply
   */
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
   * @return The scaled total supply
   */
  function scaledTotalSupply() external view returns (uint256);

  /**
   * @notice Returns last index interest was accrued to the user's balance
   * @param user The address of the user
   * @return The last index interest was accrued to the user's balance, expressed in ray
   */
  function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableDebtToken
 * @author Aave
 * @notice Interface for the initialize function common between debt tokens
 */
interface IInitializableDebtToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param incentivesController The address of the incentives controller for this aToken
   * @param debtTokenDecimals The decimals of the debt token
   * @param debtTokenName The name of the debt token
   * @param debtTokenSymbol The symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the debt token.
   * @param pool The pool contract that is initializing this contract
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableAToken
 * @author Aave
 * @notice Interface for the initialize function on AToken
 */
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals The decimals of the underlying
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the aToken
   * @param pool The pool contract that is initializing this contract
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xa598dd2fba360510c5a8f02f44423a4468e902df5857dbce3ca162a43a3a31ff;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AccessControlLib
/// @notice A library for managing access controls with roles and ownership.
/// @dev Provides the structures and functions needed to manage roles and determine ownership.
library AccessControlLib {
    // =========================
    // Errors
    // =========================

    /// @notice Thrown when attempting to initialize an already initialized vault.
    error AccessControlLib_AlreadyInitialized();

    // =========================
    // Storage
    // =========================

    /// @dev Storage position for the access control struct, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    bytes32 constant ROLES_STORAGE_POSITION = keccak256("vault.roles.storage");

    /// @notice Struct to store roles and ownership details.
    struct RolesStorage {
        // Role-based access mapping
        mapping(bytes32 role => mapping(address account => bool)) roles;
        // Address that created the entity
        address creator;
        // Identifier for the vault
        uint16 vaultId;
        // Flag to decide if cross chain logic is not allowed
        bool crossChainLogicInactive;
        // Owner address
        address owner;
        // Flag to decide if `owner` or `creator` is used
        bool useOwner;
    }

    // =========================
    // Main library logic
    // =========================

    /// @dev Retrieve the storage location for roles.
    /// @return s Reference to the roles storage struct in the storage.
    function rolesStorage() internal pure returns (RolesStorage storage s) {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly ("memory-safe") {
            s.slot := position
        }
    }

    /// @dev Fetch the owner of the vault.
    /// @dev Determines whether to use the `creator` or the `owner` based on the `useOwner` flag.
    /// @return Address of the owner.
    function getOwner() internal view returns (address) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (s.useOwner) {
            return s.owner;
        } else {
            return s.creator;
        }
    }

    /// @dev Returns the address of the creator of the vault and its ID.
    /// @return The creator's address and the vault ID.
    function getCreatorAndId() internal view returns (address, uint16) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        return (s.creator, s.vaultId);
    }

    /// @dev Initializes the `creator` and `vaultId` for a new vault.
    /// @dev Should only be used once. Reverts if already set.
    /// @param creator Address of the vault creator.
    /// @param vaultId Identifier for the vault.
    function initializeCreatorAndId(address creator, uint16 vaultId) internal {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        // check if vault never existed before
        if (s.vaultId != 0) {
            revert AccessControlLib_AlreadyInitialized();
        }

        s.creator = creator;
        s.vaultId = vaultId;
    }

    /// @dev Fetches cross chain logic flag.
    /// @return True if cross chain logic is active.
    function crossChainLogicIsActive() internal view returns (bool) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        return !s.crossChainLogicInactive;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Constants
/// @dev These constants can be imported and used by other contracts for consistency.
library Constants {
    /// @dev A keccak256 hash representing the executor role.
    bytes32 internal constant EXECUTOR_ROLE =
        keccak256("DITTO_WORKFLOW_EXECUTOR_ROLE");

    /// @dev A constant representing the native token in any network.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = IUniswapV3Pool(pool)
            .observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
            secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool).observations(
            (observationIndex + 1) % observationCardinality
        );

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        unchecked {
            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - int56(uint56(prevTickCumulative))) / int56(uint56(delta)));
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}

// source: https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PositionValue.sol
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {FixedPoint128} from "@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {LiquidityAmounts, FullMath} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

/// @title Returns information about the token value held in a Uniswap V3 NFT
library PositionValueMod {
    /// @notice Returns the total amounts of token0 and token1, i.e. the sum of fees and principal
    /// that a given nonfungible position manager token is worth
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total value
    /// @param sqrtRatioX96 The square root price X96 for which to calculate the principal amounts
    /// @return amount0 The total amount of token0 including principal and fees
    /// @return amount1 The total amount of token1 including principal and fees
    function total(
        INonfungiblePositionManager positionManager,
        uint256 tokenId,
        uint160 sqrtRatioX96,
        IUniswapV3Pool pool
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (uint256 amount0Principal, uint256 amount1Principal) = principal(
            positionManager,
            tokenId,
            sqrtRatioX96
        );
        (uint256 amount0Fee, uint256 amount1Fee) = fees(
            positionManager,
            tokenId,
            pool
        );

        unchecked {
            return (
                amount0Principal + amount0Fee,
                amount1Principal + amount1Fee
            );
        }
    }

    /// @notice Calculates the principal (currently acting as liquidity) owed to the token owner in the event
    /// that the position is burned
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total principal owed
    /// @param sqrtRatioX96 The square root price X96 for which to calculate the principal amounts
    /// @return amount0 The principal amount of token0
    /// @return amount1 The principal amount of token1
    function principal(
        INonfungiblePositionManager positionManager,
        uint256 tokenId,
        uint160 sqrtRatioX96
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = positionManager.positions(tokenId);

        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    struct FeeParams {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 positionFeeGrowthInside0LastX128;
        uint256 positionFeeGrowthInside1LastX128;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    /// @notice Calculates the total fees owed to the token owner
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total fees owed
    /// @return amount0 The amount of fees owed in token0
    /// @return amount1 The amount of fees owed in token1
    function fees(
        INonfungiblePositionManager positionManager,
        uint256 tokenId,
        IUniswapV3Pool pool
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 positionFeeGrowthInside0LastX128,
            uint256 positionFeeGrowthInside1LastX128,
            uint256 tokensOwed0,
            uint256 tokensOwed1
        ) = positionManager.positions(tokenId);

        return
            _fees(
                FeeParams({
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidity: liquidity,
                    positionFeeGrowthInside0LastX128: positionFeeGrowthInside0LastX128,
                    positionFeeGrowthInside1LastX128: positionFeeGrowthInside1LastX128,
                    tokensOwed0: tokensOwed0,
                    tokensOwed1: tokensOwed1
                }),
                pool
            );
    }

    function _fees(
        FeeParams memory feeParams,
        IUniswapV3Pool pool
    ) private view returns (uint256 amount0, uint256 amount1) {
        (
            uint256 poolFeeGrowthInside0LastX128,
            uint256 poolFeeGrowthInside1LastX128
        ) = _getFeeGrowthInside(pool, feeParams.tickLower, feeParams.tickUpper);

        unchecked {
            amount0 =
                FullMath.mulDiv(
                    poolFeeGrowthInside0LastX128 -
                        feeParams.positionFeeGrowthInside0LastX128,
                    feeParams.liquidity,
                    FixedPoint128.Q128
                ) +
                feeParams.tokensOwed0;
            amount1 =
                FullMath.mulDiv(
                    poolFeeGrowthInside1LastX128 -
                        feeParams.positionFeeGrowthInside1LastX128,
                    feeParams.liquidity,
                    FixedPoint128.Q128
                ) +
                feeParams.tokensOwed1;
        }
    }

    function _getFeeGrowthInside(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper
    )
        private
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        // to call the method slot0 without caring which dex the pool belongs we call without the interface
        (, bytes memory data) = address(pool).staticcall(
            // 0x3850c7bd - selector of "slot0()"
            abi.encodeWithSelector(0x3850c7bd)
        );
        (, int24 tickCurrent, , , , , ) = abi.decode(
            data,
            (uint160, int24, uint16, uint16, uint16, uint256, bool)
        );
        (
            ,
            ,
            uint256 lowerFeeGrowthOutside0X128,
            uint256 lowerFeeGrowthOutside1X128,
            ,
            ,
            ,

        ) = pool.ticks(tickLower);
        (
            ,
            ,
            uint256 upperFeeGrowthOutside0X128,
            uint256 upperFeeGrowthOutside1X128,
            ,
            ,
            ,

        ) = pool.ticks(tickUpper);

        if (tickCurrent < tickLower) {
            unchecked {
                feeGrowthInside0X128 =
                    lowerFeeGrowthOutside0X128 -
                    upperFeeGrowthOutside0X128;
                feeGrowthInside1X128 =
                    lowerFeeGrowthOutside1X128 -
                    upperFeeGrowthOutside1X128;
            }
        } else if (tickCurrent < tickUpper) {
            uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
            uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
            unchecked {
                feeGrowthInside0X128 =
                    feeGrowthGlobal0X128 -
                    lowerFeeGrowthOutside0X128 -
                    upperFeeGrowthOutside0X128;
                feeGrowthInside1X128 =
                    feeGrowthGlobal1X128 -
                    lowerFeeGrowthOutside1X128 -
                    upperFeeGrowthOutside1X128;
            }
        } else {
            unchecked {
                feeGrowthInside0X128 =
                    upperFeeGrowthOutside0X128 -
                    lowerFeeGrowthOutside0X128;
                feeGrowthInside1X128 =
                    upperFeeGrowthOutside1X128 -
                    lowerFeeGrowthOutside1X128;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IPoolDataProvider
 * @author Aave
 * @notice Defines the basic interface of a PoolDataProvider
 */
interface IPoolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  /**
   * @notice Returns the address for the PoolAddressesProvider contract.
   * @return The address for the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the list of the existing reserves in the pool.
   * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
   * @return The list of reserves, pairs of symbols and addresses
   */
  function getAllReservesTokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the list of the existing ATokens in the pool.
   * @return The list of ATokens, pairs of symbols and addresses
   */
  function getAllATokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the configuration data of the reserve
   * @dev Not returning borrow and supply caps for compatibility, nor pause flag
   * @param asset The address of the underlying asset of the reserve
   * @return decimals The number of decimals of the reserve
   * @return ltv The ltv of the reserve
   * @return liquidationThreshold The liquidationThreshold of the reserve
   * @return liquidationBonus The liquidationBonus of the reserve
   * @return reserveFactor The reserveFactor of the reserve
   * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
   * @return borrowingEnabled True if borrowing is enabled, false otherwise
   * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
   * @return isActive True if it is active, false otherwise
   * @return isFrozen True if it is frozen, false otherwise
   */
  function getReserveConfigurationData(
    address asset
  )
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  /**
   * @notice Returns the efficiency mode category of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The eMode id of the reserve
   */
  function getReserveEModeCategory(address asset) external view returns (uint256);

  /**
   * @notice Returns the caps parameters of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return borrowCap The borrow cap of the reserve
   * @return supplyCap The supply cap of the reserve
   */
  function getReserveCaps(
    address asset
  ) external view returns (uint256 borrowCap, uint256 supplyCap);

  /**
   * @notice Returns if the pool is paused
   * @param asset The address of the underlying asset of the reserve
   * @return isPaused True if the pool is paused, false otherwise
   */
  function getPaused(address asset) external view returns (bool isPaused);

  /**
   * @notice Returns the siloed borrowing flag
   * @param asset The address of the underlying asset of the reserve
   * @return True if the asset is siloed for borrowing
   */
  function getSiloedBorrowing(address asset) external view returns (bool);

  /**
   * @notice Returns the protocol fee on the liquidation bonus
   * @param asset The address of the underlying asset of the reserve
   * @return The protocol fee on liquidation
   */
  function getLiquidationProtocolFee(address asset) external view returns (uint256);

  /**
   * @notice Returns the unbacked mint cap of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The unbacked mint cap of the reserve
   */
  function getUnbackedMintCap(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The debt ceiling of the reserve
   */
  function getDebtCeiling(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling decimals
   * @return The debt ceiling decimals
   */
  function getDebtCeilingDecimals() external pure returns (uint256);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   */
  function getReserveData(
    address asset
  )
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   */
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   */
  function getTotalDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the user data in a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @return currentATokenBalance The current AToken balance of the user
   * @return currentStableDebt The current stable debt of the user
   * @return currentVariableDebt The current variable debt of the user
   * @return principalStableDebt The principal stable debt of the user
   * @return scaledVariableDebt The scaled variable debt of the user
   * @return stableBorrowRate The stable borrow rate of the user
   * @return liquidityRate The liquidity rate of the reserve
   * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
   * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
   *         otherwise
   */
  function getUserReserveData(
    address asset,
    address user
  )
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  /**
   * @notice Returns the token addresses of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return aTokenAddress The AToken address of the reserve
   * @return stableDebtTokenAddress The StableDebtToken address of the reserve
   * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
   */
  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  /**
   * @notice Returns the address of the Interest Rate strategy
   * @param asset The address of the underlying asset of the reserve
   * @return irStrategyAddress The address of the Interest Rate strategy
   */
  function getInterestRateStrategyAddress(
    address asset
  ) external view returns (address irStrategyAddress);

  /**
   * @notice Returns whether the reserve has FlashLoans enabled or disabled
   * @param asset The address of the underlying asset of the reserve
   * @return True if FlashLoans are enabled, false otherwise
   */
  function getFlashLoanEnabled(address asset) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 * @dev It only contains one single function, needed as a hook on aToken and debtToken transfers.
 */
interface IAaveIncentivesController {
  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   */
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
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