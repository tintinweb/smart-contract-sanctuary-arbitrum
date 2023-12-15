// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20ModuleKit} from "@rhinestone/modulekit/integrations/ERC20Actions.sol";
import {ExecutorBase} from "@rhinestone/modulekit/ExecutorBase.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PerpFeesModule} from "@perpie/modules/perps/SimplePerpFeesModule.sol";
import {IPositionRouter, IOrderBook, IVault} from "./Interfaces.sol";
import {FeesManager} from "@perpie/FeesManager.sol";
import {IExecutorManager} from "@rhinestone/modulekit/IExecutor.sol";
import {Ownable} from "@oz/access/Ownable.sol";

contract GMXV1FeesModule is PerpFeesModule, Ownable {
    // ====== Variables ====== //
    IPositionRouter internal gmxPositionRouter;
    IOrderBook internal gmxOrderbook;
    IVault internal gmxVault;

    function setGmxPositionRouter(
        IPositionRouter positionRouter
    ) public onlyOwner {
        gmxPositionRouter = positionRouter;
    }

    function setGmxOrderbook(IOrderBook orderBook) public onlyOwner {
        gmxOrderbook = orderBook;
    }

    function setGmxVault(IVault vault) public onlyOwner {
        gmxVault = vault;
    }

    bytes32 internal constant PERPIE_GMX_REFERRAL_CODE =
        0x7065727069650000000000000000000000000000000000000000000000000000;

    constructor(
        FeesManager _feesManager,
        IPositionRouter _gmxPositionRouter,
        IOrderBook _gmxOrderbook,
        IVault vault
    ) PerpFeesModule(_feesManager, "GMXV1") {
        gmxPositionRouter = _gmxPositionRouter;
        gmxOrderbook = _gmxOrderbook;
        gmxVault = vault;
    }

    // ====== Overrides ====== //
    function _getPrice(
        address token,
        bool isLong,
        uint256 /**sizeDelta */
    ) internal view override returns (uint256 price) {
        // This is the logic from GMX contract
        price = isLong
            ? gmxVault.getMinPrice(token)
            : gmxVault.getMaxPrice(token);
    }

    function _usdToToken(
        address token,
        uint256 usdAmount,
        uint256 price
    ) internal view override returns (uint256 tokenAmount) {
        tokenAmount = gmxVault.usdToToken(token, usdAmount, price);
    }

    // ====== Methods ====== //
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 /**_referralCode */,
        address _callbackTarget
    ) external payable {
        _transferMessageValue(msg.sender);
        uint256 fee;
        uint256 feeBps;
        (_sizeDelta, _amountIn, fee, feeBps) = _chargeFee(
            msg.sender,
            _path[0],
            _isLong,
            _sizeDelta,
            _amountIn
        );

        _minOut = _deductFeeBps(_minOut, feeBps);

        _execute(
            address(gmxPositionRouter),
            abi.encodeCall(
                IPositionRouter.createIncreasePosition,
                (
                    _path,
                    _indexToken,
                    _amountIn,
                    _minOut,
                    _sizeDelta,
                    _isLong,
                    _acceptablePrice,
                    _executionFee,
                    PERPIE_GMX_REFERRAL_CODE,
                    _callbackTarget
                )
            ),
            msg.value
        );
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 /**_referralCode */,
        address _callbackTarget
    ) external payable {
        // We just need it for the values
        _transferMessageValue(msg.sender);

        uint256 amountIn = msg.value - _executionFee;
        uint256 fee;
        uint256 feeBps;

        (_sizeDelta, amountIn, fee, feeBps) = _chargeFee(
            msg.sender,
            _path[0],
            _isLong,
            _sizeDelta,
            amountIn,
            true
        );

        _minOut = _deductFeeBps(_minOut, feeBps);

        _execute(
            address(gmxPositionRouter),
            abi.encodeCall(
                IPositionRouter.createIncreasePositionETH,
                (
                    _path,
                    _indexToken,
                    _minOut,
                    _sizeDelta,
                    _isLong,
                    _acceptablePrice,
                    _executionFee,
                    PERPIE_GMX_REFERRAL_CODE,
                    _callbackTarget
                )
            ),
            amountIn + _executionFee
        );
    }

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
    ) external payable {
        // We just need it for the values
        _transferMessageValue(msg.sender);

        uint256 feeBps;
        {
            (_sizeDelta, _amountIn, , feeBps) = _chargeFee(
                msg.sender,
                _path[0],
                _isLong,
                _sizeDelta,
                _amountIn,
                _shouldWrap
            );
        }
        _minOut = _deductFeeBps(_minOut, feeBps);

        _execute(
            address(gmxOrderbook),
            abi.encodeCall(
                IOrderBook.createIncreaseOrder,
                (
                    _path,
                    _amountIn,
                    _indexToken,
                    _minOut,
                    _sizeDelta,
                    _collateralToken,
                    _isLong,
                    _triggerPrice,
                    _triggerAboveThreshold,
                    _executionFee,
                    _shouldWrap
                )
            ),
            _shouldWrap ? _amountIn + _executionFee : msg.value
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import "forge-std/interfaces/IERC20.sol";
import "../IExecutor.sol";
import "./interfaces/IWETH.sol";

library ERC20ModuleKit {
    address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function approveAction(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
        pure
        returns (ExecutorAction memory action)
    {
        action = ExecutorAction({
            to: payable(address(token)),
            value: 0,
            data: abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        });
    }

    function transferAction(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
        pure
        returns (ExecutorAction memory action)
    {
        action = ExecutorAction({
            to: payable(address(token)),
            value: 0,
            data: abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        });
    }

    function transferFromAction(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    )
        internal
        pure
        returns (ExecutorAction memory action)
    {
        action = ExecutorAction({
            to: payable(address(token)),
            value: 0,
            data: abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        });
    }

    function depositWethAction(uint256 amount)
        internal
        pure
        returns (ExecutorAction memory action)
    {
        action = ExecutorAction({
            to: payable(address(WETH_ADDR)),
            value: amount,
            data: abi.encodeWithSelector(IWETH.deposit.selector)
        });
    }

    function withdrawWethAction(uint256 amount)
        internal
        pure
        returns (ExecutorAction memory action)
    {
        action = ExecutorAction({
            to: payable(address(WETH_ADDR)),
            value: 0,
            data: abi.encodeWithSelector(IWETH.withdraw.selector, amount)
        });
    }

    function getBalance(address token, address account) internal view returns (uint256 balance) {
        if (token == ETH_ADDR) {
            balance = account.balance;
        } else {
            balance = IERC20(token).balanceOf(account);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IExecutor.sol";

abstract contract ExecutorBase is IExecutorBase {
    function name() external view virtual returns (string memory name);

    function version() external view virtual returns (string memory version);

    function metadataProvider()
        external
        view
        virtual
        returns (uint256 providerType, bytes memory location);

    function requiresRootAccess() external view virtual returns (bool requiresRootAccess);

    function supportsInterface(bytes4 interfaceID) external view virtual override returns (bool) {
        return interfaceID == IExecutorBase.name.selector
            || interfaceID == IExecutorBase.version.selector
            || interfaceID == IExecutorBase.metadataProvider.selector
            || interfaceID == IExecutorBase.requiresRootAccess.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {FeesManager} from "@src/FeesManager.sol";
import {ERC20ModuleKit} from "@rhinestone/modulekit/integrations/ERC20Actions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ExecutorBase} from "@rhinestone/modulekit/ExecutorBase.sol";
import {IExecutorManager, ExecutorAction, ModuleExecLib} from "@rhinestone/modulekit/IExecutor.sol";
import {IExecFromModule, Enum} from "@perpie/modules/IExecFromModule.sol";

abstract contract PerpFeesModule {
    // ======= Libs ======= //
    FeesManager immutable FEES_MANAGER;
    string public PROTOCOL_NAME;

    // ======= Events ======= //
    event PerpFeeCharged(
        string indexed protocol,
        uint256 indexed amountUsd,
        uint256 indexed amountTokens,
        address token,
        address account
    );

    // ======= Errors ======= //
    error FeeExceedsAmountIn(uint256 fee, uint256 amountIn);
    error FailedToTransferNativeToken(bytes err);

    // ======= Constructor ======= //
    constructor(FeesManager feesManager, string memory protocolName) {
        FEES_MANAGER = feesManager;
        PROTOCOL_NAME = protocolName;
    }

    // ====== Abstract ====== //
    function _getPrice(
        address token,
        bool isLong,
        uint256 sizeDelta
    ) internal view virtual returns (uint256 price);

    function _usdToToken(
        address token,
        uint256 usdAmount,
        uint256 price
    ) internal view virtual returns (uint256 tokenAmount);

    // ====== Internal ====== //
    function _execute(
        address to,
        bytes memory data,
        uint256 value
    ) internal returns (bool success) {
        success = _execute(msg.sender, to, data, value);
    }

    function _execute(
        address account,
        address to,
        bytes memory data,
        uint256 value
    ) internal returns (bool success) {
        success = _execute(account, to, data, value, true);
    }

    function _execute(
        address account,
        address to,
        bytes memory data,
        uint256 value,
        bool requireSuccess
    ) internal returns (bool success) {
        success = IExecFromModule(account).execTransactionFromModule(
            to,
            value,
            data,
            Enum.Operation.Call
        );

        require(!requireSuccess || success, "Module Execution Failed");
    }

    function _chargeFee(
        address account,
        address tokenIn,
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 amountIn
    )
        internal
        returns (
            uint256 sizeUsdAfterFees,
            uint256 amountInAfterFee,
            uint256 fee,
            uint256 feeBps
        )
    {
        (sizeUsdAfterFees, amountInAfterFee, fee, feeBps) = _chargeFee(
            account,
            tokenIn,
            isLong,
            sizeDeltaUsd,
            amountIn,
            false
        );
    }

    function _chargeFee(
        address account,
        address tokenIn,
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 amountIn,
        bool isNativeCollateral // We allow this overload incase some protocol identifies native token via a diff address
    )
        internal
        returns (
            uint256 sizeUsdAfterFees,
            uint256 amountInAfterFee,
            uint256 fee,
            uint256 feeBps
        )
    {
        feeBps = FEES_MANAGER.feesBps();
        fee = _calculateFee(sizeDeltaUsd, feeBps);

        sizeUsdAfterFees = sizeDeltaUsd - fee;
        uint256 tokenFee = _usdToToken(
            tokenIn,
            fee,
            _getPrice(tokenIn, isLong, sizeUsdAfterFees)
        );

        if (tokenFee >= amountIn) {
            revert FeeExceedsAmountIn(tokenFee, amountIn);
        }

        amountInAfterFee = amountIn - tokenFee;

        if (isNativeCollateral || _isTokenNative(tokenIn)) {
            _chargeNativeFee(account, tokenFee);
        } else {
            _chargeTokenFee(account, tokenIn, tokenFee);
        }

        emit PerpFeeCharged(PROTOCOL_NAME, fee, tokenFee, tokenIn, account);
    }

    function _chargeNativeFee(address account, uint256 amount) private {
        _execute(account, address(FEES_MANAGER), hex"00", amount, true);
    }

    function _chargeTokenFee(
        address account,
        address token,
        uint256 amount
    ) private {
        _execute(
            account,
            token,
            abi.encodeCall(IERC20.transfer, (address(FEES_MANAGER), amount)),
            0,
            true
        );
    }

    function _transferMessageValue(address account) internal {
        (bool success, bytes memory res) = account.call{value: msg.value}("");

        if (!success) {
            revert FailedToTransferNativeToken(res);
        }
    }

    function _deductFeeBps(
        uint256 amount,
        uint256 feeBps
    ) public pure returns (uint256 newAmount) {
        newAmount = amount - _calculateFee(amount, feeBps);
    }

    function _calculateFee(
        uint256 amount,
        uint256 feeBps
    ) public pure returns (uint256 fee) {
        fee = (amount * feeBps) / 10000;
    }

    function _isTokenNative(address token) public pure returns (bool isNative) {
        isNative = token == address(0) || token == ERC20ModuleKit.ETH_ADDR;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPositionRouter {
    function minExecutionFee() external view returns (uint256);

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequestKeys(
        uint256 index
    ) external view returns (bytes32);

    function decreasePositionRequestKeys(
        uint256 index
    ) external view returns (bytes32);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function getRequestQueueLengths()
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function getIncreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function getDecreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

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

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);
}

interface IOrderBook {
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

    function minExecutionFee() external view returns (uint256);

    function minPurchaseTokenAmountUsd() external view returns (uint256);
}

interface IVaultUtils {
    function updateCumulativeFundingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);

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

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

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

    function getBuyUsdgFeeBasisPoints(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getSellUsdgFeeBasisPoints(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);
}

interface IVault {
    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) external view returns (uint256);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;

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

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

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

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

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

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

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

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

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

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@oz/access/Ownable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {Initializable} from "@oz/proxy/utils/Initializable.sol";

contract FeesManager is Ownable, Initializable {
    // ====== States ======
    uint256 public feesBps = 5;

    // ====== Constructor ======
    function initialize(address owner) external initializer {
        _transferOwnership(owner);
    }

    // ====== Methods ====== //
    function withdraw(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    function setFeeBps(uint256 newBps) external onlyOwner {
        feesBps = newBps;
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import { IERC165 } from "forge-std/interfaces/IERC165.sol";

/**
 *  Structs that are compatible with Safe{Core} Protocol Specs.
 *  https://github.com/safe-global/safe-core-protocol/blob/main/contracts/DataTypes.sol
 */
struct ExecutorAction {
    address payable to;
    uint256 value;
    bytes data;
}

struct ExecutorTransaction {
    ExecutorAction[] actions;
    uint256 nonce;
    bytes32 metadataHash;
}

struct ExecutorRootAccess {
    ExecutorAction action;
    uint256 nonce;
    bytes32 metadataHash;
}

/**
 * @title IExecutorBase - An interface that a Safe executor should implement
 * @notice Interface is an extention of Safe{Core} Protocol Specs.
 */
interface IExecutorBase is IERC165 {
    /**
     * @notice A funtion that returns name of the executor
     * @return name string name of the executor
     */
    function name() external view returns (string memory name);

    /**
     * @notice A funtion that returns version of the executor
     * @return version string version of the executor
     */
    function version() external view returns (string memory version);

    /**
     * @notice A funtion that returns version of the executor.
     *         TODO: Define types of metadata provider and possible values of location in each of the cases.
     * @return providerType uint256 Type of metadata provider
     * @return location bytes
     */
    function metadataProvider()
        external
        view
        returns (uint256 providerType, bytes memory location);

    /**
     * @notice A function that indicates if the executor requires root access to a Safe.
     * @return requiresRootAccess True if root access is required, false otherwise.
     */
    function requiresRootAccess() external view returns (bool requiresRootAccess);
}

interface IModuleManager {
    function executeTransaction(ExecutorTransaction calldata transaction)
        external
        returns (bytes[] memory data);
}

interface IExecutorManager {
    function executeTransaction(
        address account,
        ExecutorTransaction calldata transaction
    )
        external
        returns (bytes[] memory data);
}

library ModuleExecLib {
    function exec(
        IExecutorManager manager,
        address account,
        ExecutorAction memory action
    )
        internal
    {
        ExecutorAction[] memory actions = new ExecutorAction[](1);
        actions[0] = action;

        ExecutorTransaction memory transaction =
            ExecutorTransaction({ actions: actions, nonce: 0, metadataHash: "" });

        manager.executeTransaction(account, transaction);
    }

    function exec(
        IExecutorManager manager,
        address account,
        ExecutorAction[] memory actions
    )
        internal
    {
        ExecutorTransaction memory transaction =
            ExecutorTransaction({ actions: actions, nonce: 0, metadataHash: "" });

        manager.executeTransaction(account, transaction);
    }

    function exec(
        IExecutorManager manager,
        address account,
        address target,
        bytes memory callData
    )
        internal
    {
        ExecutorAction memory action =
            ExecutorAction({ to: payable(target), value: 0, data: callData });
        exec(manager, account, action);
    }
}

interface ICondition {
    function checkCondition(
        address account,
        address executor,
        bytes calldata boundries,
        bytes calldata subParams
    )
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

pragma solidity ^0.8.10;

import "forge-std/interfaces/IERC20.sol";

abstract contract IWETH {
    function allowance(address, address) public view virtual returns (uint256);

    function balanceOf(address) public view virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IExecFromModule {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) external payable returns (bool success);

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external payable returns (bool success);
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
pragma solidity >=0.6.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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