// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxGlpManager {
    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 mintAmount
    );
    event RemoveLiquidity(
        address account,
        address token,
        uint256 glpAmount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 amountOut
    );

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function GLP_PRECISION() external view returns (uint256);

    function MAX_COOLDOWN_DURATION() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function USDG_DECIMALS() external view returns (uint256);

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function aumAddition() external view returns (uint256);

    function aumDeduction() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function getAumInUsdg(bool maximise) external view returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function getGlobalShortAveragePrice(address _token)
        external
        view
        returns (uint256);

    function getGlobalShortDelta(
        address _token,
        uint256 _price,
        uint256 _size
    ) external view returns (uint256, bool);

    function getPrice(bool _maximise) external view returns (uint256);

    function glp() external view returns (address);

    function gov() external view returns (address);

    function inPrivateMode() external view returns (bool);

    function isHandler(address) external view returns (bool);

    function lastAddedAt(address) external view returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction)
        external;

    function setCooldownDuration(uint256 _cooldownDuration) external;

    function setGov(address _gov) external;

    function setHandler(address _handler, bool _isActive) external;

    function setInPrivateMode(bool _inPrivateMode) external;

    function setShortsTracker(address _shortsTracker) external;

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external;

    function shortsTracker() external view returns (address);

    function shortsTrackerAveragePriceWeight() external view returns (uint256);

    function usdg() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IGmxPositionManager {
    event Callback(address callbackTarget, bool success);
    event CancelDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event CancelIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event CreateDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 index,
        uint256 queueIndex,
        uint256 blockNumber,
        uint256 blockTime
    );
    event CreateIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 queueIndex,
        uint256 blockNumber,
        uint256 blockTime,
        uint256 gasPrice
    );
    event DecreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );
    event ExecuteDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event ExecuteIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event IncreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );
    event SetAdmin(address admin);
    event SetCallbackGasLimit(uint256 callbackGasLimit);
    event SetDelayValues(uint256 minBlockDelayKeeper, uint256 minTimeDelayPublic, uint256 maxTimeDelay);
    event SetDepositFee(uint256 depositFee);
    event SetIncreasePositionBufferBps(uint256 increasePositionBufferBps);
    event SetIsLeverageEnabled(bool isLeverageEnabled);
    event SetMaxGlobalSizes(address[] tokens, uint256[] longSizes, uint256[] shortSizes);
    event SetMinExecutionFee(uint256 minExecutionFee);
    event SetPositionKeeper(address indexed account, bool isActive);
    event SetReferralStorage(address referralStorage);
    event SetRequestKeysStartValues(uint256 increasePositionRequestKeysStart, uint256 decreasePositionRequestKeysStart);
    event WithdrawFees(address token, address receiver, uint256 amount);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function admin() external view returns (address);

    function approve(address _token, address _spender, uint256 _amount) external;

    function callbackGasLimit() external view returns (uint256);

    function cancelDecreasePosition(bytes32 _key, address _executionFeeReceiver) external returns (bool);

    function cancelIncreasePosition(bytes32 _key, address _executionFeeReceiver) external returns (bool);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

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

    function decreasePositionRequestKeys(uint256) external view returns (bytes32);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequests(
        bytes32
    )
        external
        view
        returns (
            address account,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            address receiver,
            uint256 acceptablePrice,
            uint256 minOut,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool withdrawETH,
            address callbackTarget
        );

    function decreasePositionsIndex(address) external view returns (uint256);

    function depositFee() external view returns (uint256);

    function executeDecreasePosition(bytes32 _key, address _executionFeeReceiver) external returns (bool);

    function executeDecreasePositions(uint256 _endIndex, address _executionFeeReceiver) external;

    function executeIncreasePosition(bytes32 _key, address _executionFeeReceiver) external returns (bool);

    function executeIncreasePositions(uint256 _endIndex, address _executionFeeReceiver) external;

    function feeReserves(address) external view returns (uint256);

    function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);

    function getIncreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);

    function getRequestKey(address _account, uint256 _index) external pure returns (bytes32);

    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);

    function gov() external view returns (address);

    function increasePositionBufferBps() external view returns (uint256);

    function increasePositionRequestKeys(uint256) external view returns (bytes32);

    function increasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequests(
        bytes32
    )
        external
        view
        returns (
            address account,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong,
            uint256 acceptablePrice,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool hasCollateralInETH,
            address callbackTarget
        );

    function increasePositionsIndex(address) external view returns (uint256);

    function isLeverageEnabled() external view returns (bool);

    function isPositionKeeper(address) external view returns (bool);

    function maxGlobalLongSizes(address) external view returns (uint256);

    function maxGlobalShortSizes(address) external view returns (uint256);

    function maxTimeDelay() external view returns (uint256);

    function minBlockDelayKeeper() external view returns (uint256);

    function minExecutionFee() external view returns (uint256);

    function minTimeDelayPublic() external view returns (uint256);

    function referralStorage() external view returns (address);

    function router() external view returns (address);

    function sendValue(address _receiver, uint256 _amount) external;

    function setAdmin(address _admin) external;

    function setCallbackGasLimit(uint256 _callbackGasLimit) external;

    function setDelayValues(uint256 _minBlockDelayKeeper, uint256 _minTimeDelayPublic, uint256 _maxTimeDelay) external;

    function setDepositFee(uint256 _depositFee) external;

    function setGov(address _gov) external;

    function setIncreasePositionBufferBps(uint256 _increasePositionBufferBps) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGlobalSizes(address[] memory _tokens, uint256[] memory _longSizes, uint256[] memory _shortSizes) external;

    function setMinExecutionFee(uint256 _minExecutionFee) external;

    function setPositionKeeper(address _account, bool _isActive) external;

    function setReferralStorage(address _referralStorage) external;

    function setRequestKeysStartValues(uint256 _increasePositionRequestKeysStart, uint256 _decreasePositionRequestKeysStart) external;

    function shortsTracker() external view returns (address);

    function vault() external view returns (address);

    function weth() external view returns (address);

    function withdrawFees(address _token, address _receiver) external;

    receive() external payable;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address","name":"_router","type":"address"},{"internalType":"address","name":"_weth","type":"address"},{"internalType":"address","name":"_shortsTracker","type":"address"},{"internalType":"uint256","name":"_depositFee","type":"uint256"},{"internalType":"uint256","name":"_minExecutionFee","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"callbackTarget","type":"address"},{"indexed":false,"internalType":"bool","name":"success","type":"bool"}],"name":"Callback","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address[]","name":"path","type":"address[]"},{"indexed":false,"internalType":"address","name":"indexToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"collateralDelta","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isLong","type":"bool"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minOut","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"executionFee","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockGap","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timeGap","type":"uint256"}],"name":"CancelDecreasePosition","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address[]","name":"path","type":"address[]"},{"indexed":false,"internalType":"address","name":"indexToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"amountIn","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minOut","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isLong","type":"bool"},{"indexed":false,"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"executionFee","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockGap","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timeGap","type":"uint256"}],"name":"CancelIncreasePosition","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address[]","name":"path","type":"address[]"},{"indexed":false,"internalType":"address","name":"indexToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"collateralDelta","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isLong","type":"bool"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minOut","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"executionFee","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"index","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"queueIndex","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockTime","type":"uint256"}],"name":"CreateDecreasePosition","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address[]","name":"path","type":"address[]"},{"indexed":false,"internalType":"address","name":"indexToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"amountIn","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minOut","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isLong","type":"bool"},{"indexed":false,"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"executionFee","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"index","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"queueIndex","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockTime","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasPrice","type":"uint256"}],"name":"CreateIncreasePosition","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"marginFeeBasisPoints","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"referralCode","type":"bytes32"},{"indexed":false,"internalType":"address","name":"referrer","type":"address"}],"name":"DecreasePositionReferral","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address[]","name":"path","type":"address[]"},{"indexed":false,"internalType":"address","name":"indexToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"collateralDelta","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isLong","type":"bool"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minOut","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"executionFee","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockGap","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timeGap","type":"uint256"}],"name":"ExecuteDecreasePosition","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address[]","name":"path","type":"address[]"},{"indexed":false,"internalType":"address","name":"indexToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"amountIn","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minOut","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isLong","type":"bool"},{"indexed":false,"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"executionFee","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockGap","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timeGap","type":"uint256"}],"name":"ExecuteIncreasePosition","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"marginFeeBasisPoints","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"referralCode","type":"bytes32"},{"indexed":false,"internalType":"address","name":"referrer","type":"address"}],"name":"IncreasePositionReferral","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"admin","type":"address"}],"name":"SetAdmin","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"callbackGasLimit","type":"uint256"}],"name":"SetCallbackGasLimit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"minBlockDelayKeeper","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"minTimeDelayPublic","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"maxTimeDelay","type":"uint256"}],"name":"SetDelayValues","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"depositFee","type":"uint256"}],"name":"SetDepositFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"increasePositionBufferBps","type":"uint256"}],"name":"SetIncreasePositionBufferBps","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"isLeverageEnabled","type":"bool"}],"name":"SetIsLeverageEnabled","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address[]","name":"tokens","type":"address[]"},{"indexed":false,"internalType":"uint256[]","name":"longSizes","type":"uint256[]"},{"indexed":false,"internalType":"uint256[]","name":"shortSizes","type":"uint256[]"}],"name":"SetMaxGlobalSizes","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"minExecutionFee","type":"uint256"}],"name":"SetMinExecutionFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"bool","name":"isActive","type":"bool"}],"name":"SetPositionKeeper","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"referralStorage","type":"address"}],"name":"SetReferralStorage","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"increasePositionRequestKeysStart","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"decreasePositionRequestKeysStart","type":"uint256"}],"name":"SetRequestKeysStartValues","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"WithdrawFees","type":"event"},{"inputs":[],"name":"BASIS_POINTS_DIVISOR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_spender","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"callbackGasLimit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_key","type":"bytes32"},{"internalType":"address payable","name":"_executionFeeReceiver","type":"address"}],"name":"cancelDecreasePosition","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_key","type":"bytes32"},{"internalType":"address payable","name":"_executionFeeReceiver","type":"address"}],"name":"cancelIncreasePosition","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_path","type":"address[]"},{"internalType":"address","name":"_indexToken","type":"address"},{"internalType":"uint256","name":"_collateralDelta","type":"uint256"},{"internalType":"uint256","name":"_sizeDelta","type":"uint256"},{"internalType":"bool","name":"_isLong","type":"bool"},{"internalType":"address","name":"_receiver","type":"address"},{"internalType":"uint256","name":"_acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"_minOut","type":"uint256"},{"internalType":"uint256","name":"_executionFee","type":"uint256"},{"internalType":"bool","name":"_withdrawETH","type":"bool"},{"internalType":"address","name":"_callbackTarget","type":"address"}],"name":"createDecreasePosition","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_path","type":"address[]"},{"internalType":"address","name":"_indexToken","type":"address"},{"internalType":"uint256","name":"_amountIn","type":"uint256"},{"internalType":"uint256","name":"_minOut","type":"uint256"},{"internalType":"uint256","name":"_sizeDelta","type":"uint256"},{"internalType":"bool","name":"_isLong","type":"bool"},{"internalType":"uint256","name":"_acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"_executionFee","type":"uint256"},{"internalType":"bytes32","name":"_referralCode","type":"bytes32"},{"internalType":"address","name":"_callbackTarget","type":"address"}],"name":"createIncreasePosition","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_path","type":"address[]"},{"internalType":"address","name":"_indexToken","type":"address"},{"internalType":"uint256","name":"_minOut","type":"uint256"},{"internalType":"uint256","name":"_sizeDelta","type":"uint256"},{"internalType":"bool","name":"_isLong","type":"bool"},{"internalType":"uint256","name":"_acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"_executionFee","type":"uint256"},{"internalType":"bytes32","name":"_referralCode","type":"bytes32"},{"internalType":"address","name":"_callbackTarget","type":"address"}],"name":"createIncreasePositionETH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"decreasePositionRequestKeys","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decreasePositionRequestKeysStart","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"decreasePositionRequests","outputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"uint256","name":"collateralDelta","type":"uint256"},{"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"minOut","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"blockNumber","type":"uint256"},{"internalType":"uint256","name":"blockTime","type":"uint256"},{"internalType":"bool","name":"withdrawETH","type":"bool"},{"internalType":"address","name":"callbackTarget","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"decreasePositionsIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"depositFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_key","type":"bytes32"},{"internalType":"address payable","name":"_executionFeeReceiver","type":"address"}],"name":"executeDecreasePosition","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_endIndex","type":"uint256"},{"internalType":"address payable","name":"_executionFeeReceiver","type":"address"}],"name":"executeDecreasePositions","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_key","type":"bytes32"},{"internalType":"address payable","name":"_executionFeeReceiver","type":"address"}],"name":"executeIncreasePosition","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_endIndex","type":"uint256"},{"internalType":"address payable","name":"_executionFeeReceiver","type":"address"}],"name":"executeIncreasePositions","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"feeReserves","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_key","type":"bytes32"}],"name":"getDecreasePositionRequestPath","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"_key","type":"bytes32"}],"name":"getIncreasePositionRequestPath","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"uint256","name":"_index","type":"uint256"}],"name":"getRequestKey","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"getRequestQueueLengths","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"gov","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"increasePositionBufferBps","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"increasePositionRequestKeys","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"increasePositionRequestKeysStart","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"increasePositionRequests","outputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"minOut","type":"uint256"},{"internalType":"uint256","name":"sizeDelta","type":"uint256"},{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"blockNumber","type":"uint256"},{"internalType":"uint256","name":"blockTime","type":"uint256"},{"internalType":"bool","name":"hasCollateralInETH","type":"bool"},{"internalType":"address","name":"callbackTarget","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"increasePositionsIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isLeverageEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"isPositionKeeper","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"maxGlobalLongSizes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"maxGlobalShortSizes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxTimeDelay","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minBlockDelayKeeper","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minExecutionFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minTimeDelayPublic","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"referralStorage","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"router","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address payable","name":"_receiver","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"sendValue","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_admin","type":"address"}],"name":"setAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_callbackGasLimit","type":"uint256"}],"name":"setCallbackGasLimit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minBlockDelayKeeper","type":"uint256"},{"internalType":"uint256","name":"_minTimeDelayPublic","type":"uint256"},{"internalType":"uint256","name":"_maxTimeDelay","type":"uint256"}],"name":"setDelayValues","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_depositFee","type":"uint256"}],"name":"setDepositFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_gov","type":"address"}],"name":"setGov","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_increasePositionBufferBps","type":"uint256"}],"name":"setIncreasePositionBufferBps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_isLeverageEnabled","type":"bool"}],"name":"setIsLeverageEnabled","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_tokens","type":"address[]"},{"internalType":"uint256[]","name":"_longSizes","type":"uint256[]"},{"internalType":"uint256[]","name":"_shortSizes","type":"uint256[]"}],"name":"setMaxGlobalSizes","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minExecutionFee","type":"uint256"}],"name":"setMinExecutionFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"bool","name":"_isActive","type":"bool"}],"name":"setPositionKeeper","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_referralStorage","type":"address"}],"name":"setReferralStorage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_increasePositionRequestKeysStart","type":"uint256"},{"internalType":"uint256","name":"_decreasePositionRequestKeysStart","type":"uint256"}],"name":"setRequestKeysStartValues","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"shortsTracker","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"vault","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"weth","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_receiver","type":"address"}],"name":"withdrawFees","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IGmxReader {
    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function POSITION_PROPS_LENGTH() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function USDG_DECIMALS() external view returns (uint256);

    function getAmountOut(address _vault, address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256, uint256);

    function getFeeBasisPoints(
        address _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256, uint256);

    function getFees(address _vault, address[] memory _tokens) external view returns (uint256[] memory);

    function getFullVaultTokenInfo(
        address _vault,
        address _weth,
        uint256 _usdgAmount,
        address[] memory _tokens
    ) external view returns (uint256[] memory);

    function getFundingRates(address _vault, address _weth, address[] memory _tokens) external view returns (uint256[] memory);

    function getMaxAmountIn(address _vault, address _tokenIn, address _tokenOut) external view returns (uint256);

    function getPairInfo(address _factory, address[] memory _tokens) external view returns (uint256[] memory);

    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);

    function getPrices(address _priceFeed, address[] memory _tokens) external view returns (uint256[] memory);

    function getStakingInfo(address _account, address[] memory _yieldTrackers) external view returns (uint256[] memory);

    function getTokenBalances(address _account, address[] memory _tokens) external view returns (uint256[] memory);

    function getTokenBalancesWithSupplies(address _account, address[] memory _tokens) external view returns (uint256[] memory);

    function getTokenSupply(address _token, address[] memory _excludedAccounts) external view returns (uint256);

    function getTotalBalance(address _token, address[] memory _accounts) external view returns (uint256);

    function getTotalStaked(address[] memory _yieldTokens) external view returns (uint256[] memory);

    function getVaultTokenInfo(
        address _vault,
        address _weth,
        uint256 _usdgAmount,
        address[] memory _tokens
    ) external view returns (uint256[] memory);

    function getVaultTokenInfoV2(
        address _vault,
        address _weth,
        uint256 _usdgAmount,
        address[] memory _tokens
    ) external view returns (uint256[] memory);

    function getVestingInfo(address _account, address[] memory _vesters) external view returns (uint256[] memory);

    function gov() external view returns (address);

    function hasMaxGlobalShortSizes() external view returns (bool);

    function setConfig(bool _hasMaxGlobalShortSizes) external;

    function setGov(address _gov) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"BASIS_POINTS_DIVISOR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"POSITION_PROPS_LENGTH","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PRICE_PRECISION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"USDG_DECIMALS","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IVault","name":"_vault","type":"address"},{"internalType":"address","name":"_tokenIn","type":"address"},{"internalType":"address","name":"_tokenOut","type":"address"},{"internalType":"uint256","name":"_amountIn","type":"uint256"}],"name":"getAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IVault","name":"_vault","type":"address"},{"internalType":"address","name":"_tokenIn","type":"address"},{"internalType":"address","name":"_tokenOut","type":"address"},{"internalType":"uint256","name":"_amountIn","type":"uint256"}],"name":"getFeeBasisPoints","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getFees","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address","name":"_weth","type":"address"},{"internalType":"uint256","name":"_usdgAmount","type":"uint256"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getFullVaultTokenInfo","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address","name":"_weth","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getFundingRates","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IVault","name":"_vault","type":"address"},{"internalType":"address","name":"_tokenIn","type":"address"},{"internalType":"address","name":"_tokenOut","type":"address"}],"name":"getMaxAmountIn","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_factory","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getPairInfo","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address","name":"_account","type":"address"},{"internalType":"address[]","name":"_collateralTokens","type":"address[]"},{"internalType":"address[]","name":"_indexTokens","type":"address[]"},{"internalType":"bool[]","name":"_isLong","type":"bool[]"}],"name":"getPositions","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IVaultPriceFeed","name":"_priceFeed","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getPrices","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"address[]","name":"_yieldTrackers","type":"address[]"}],"name":"getStakingInfo","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getTokenBalances","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getTokenBalancesWithSupplies","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"_token","type":"address"},{"internalType":"address[]","name":"_excludedAccounts","type":"address[]"}],"name":"getTokenSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"_token","type":"address"},{"internalType":"address[]","name":"_accounts","type":"address[]"}],"name":"getTotalBalance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_yieldTokens","type":"address[]"}],"name":"getTotalStaked","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address","name":"_weth","type":"address"},{"internalType":"uint256","name":"_usdgAmount","type":"uint256"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getVaultTokenInfo","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_vault","type":"address"},{"internalType":"address","name":"_weth","type":"address"},{"internalType":"uint256","name":"_usdgAmount","type":"uint256"},{"internalType":"address[]","name":"_tokens","type":"address[]"}],"name":"getVaultTokenInfoV2","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"address[]","name":"_vesters","type":"address[]"}],"name":"getVestingInfo","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"gov","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"hasMaxGlobalShortSizes","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bool","name":"_hasMaxGlobalShortSizes","type":"bool"}],"name":"setConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_gov","type":"address"}],"name":"setGov","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxVault {
    event BuyUSDG(
        address account,
        address token,
        uint256 tokenAmount,
        uint256 usdgAmount,
        uint256 feeBasisPoints
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DecreaseGuaranteedUsd(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreaseReservedAmount(address token, uint256 amount);
    event DecreaseUsdgAmount(address token, uint256 amount);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event IncreaseReservedAmount(address token, uint256 amount);
    event IncreaseUsdgAmount(address token, uint256 amount);
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event SellUSDG(
        address account,
        address token,
        uint256 usdgAmount,
        uint256 tokenAmount,
        uint256 feeBasisPoints
    );
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );
    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function FUNDING_RATE_PRECISION() external view returns (uint256);

    function MAX_FEE_BASIS_POINTS() external view returns (uint256);

    function MAX_FUNDING_RATE_FACTOR() external view returns (uint256);

    function MAX_LIQUIDATION_FEE_USD() external view returns (uint256);

    function MIN_FUNDING_RATE_INTERVAL() external view returns (uint256);

    function MIN_LEVERAGE() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function USDG_DECIMALS() external view returns (uint256);

    function addRouter(address _router) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function allWhitelistedTokensLength() external view returns (uint256);

    function approvedRouters(address, address) external view returns (bool);

    function bufferAmounts(address) external view returns (uint256);

    function buyUSDG(address _token, address _receiver)
        external
        returns (uint256);

    function clearTokenConfig(address _token) external;

    function cumulativeFundingRates(address) external view returns (uint256);

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function errorController() external view returns (address);

    function errors(uint256) external view returns (string memory);

    function feeReserves(address) external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function fundingRateFactor() external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getGlobalShortDelta(address _token)
        external
        view
        returns (bool, uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getNextGlobalShortAveragePrice(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);

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

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external pure returns (bytes32);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount)
        external
        view
        returns (uint256);

    function getRedemptionCollateral(address _token)
        external
        view
        returns (uint256);

    function getRedemptionCollateralUsd(address _token)
        external
        view
        returns (uint256);

    function getTargetUsdgAmount(address _token)
        external
        view
        returns (uint256);

    function getUtilisation(address _token) external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);

    function globalShortSizes(address) external view returns (uint256);

    function gov() external view returns (address);

    function guaranteedUsd(address) external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function includeAmmPrice() external view returns (bool);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function initialize(
        address _router,
        address _usdg,
        address _priceFeed,
        uint256 _liquidationFeeUsd,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function isInitialized() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function isLiquidator(address) external view returns (bool);

    function isManager(address) external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function lastFundingTimes(address) external view returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function liquidationFeeUsd() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function maxGasPrice() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function maxUsdgAmounts(address) external view returns (uint256);

    function minProfitBasisPoints(address) external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function poolAmounts(address) external view returns (uint256);

    function positions(bytes32)
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            int256 realisedPnl,
            uint256 lastIncreasedTime
        );

    function priceFeed() external view returns (address);

    function removeRouter(address _router) external;

    function reservedAmounts(address) external view returns (uint256);

    function router() external view returns (address);

    function sellUSDG(address _token, address _receiver)
        external
        returns (uint256);

    function setBufferAmount(address _token, uint256 _amount) external;

    function setError(uint256 _errorCode, string memory _error) external;

    function setErrorController(address _errorController) external;

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

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setGov(address _gov) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode)
        external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setManager(address _manager, bool _isManager) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setPriceFeed(address _priceFeed) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function shortableTokens(address) external view returns (bool);

    function stableFundingRateFactor() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function stableTokens(address) external view returns (bool);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function tokenBalances(address) external view returns (uint256);

    function tokenDecimals(address) external view returns (uint256);

    function tokenToUsdMin(address _token, uint256 _tokenAmount)
        external
        view
        returns (uint256);

    function tokenWeights(address) external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function updateCumulativeFundingRate(address _token) external;

    function upgradeVault(
        address _newVault,
        address _token,
        uint256 _amount
    ) external;

    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) external view returns (uint256);

    function usdToTokenMax(address _token, uint256 _usdAmount)
        external
        view
        returns (uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount)
        external
        view
        returns (uint256);

    function usdg() external view returns (address);

    function usdgAmounts(address) external view returns (uint256);

    function useSwapPricing() external view returns (bool);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function whitelistedTokenCount() external view returns (uint256);

    function whitelistedTokens(address) external view returns (bool);

    function withdrawFees(address _token, address _receiver)
        external
        returns (uint256);
}

pragma solidity >=0.7.0 <0.9.0;

interface IGmxVaultReader {
    function getVaultTokenInfoV3(
        address _vault,
        address _positionManager,
        address _weth,
        uint256 _usdgAmount,
        address[] memory _tokens
    ) external view returns (uint256[] memory);

    function getVaultTokenInfoV4(
        address _vault,
        address _positionManager,
        address _weth,
        uint256 _usdgAmount,
        address[] memory _tokens
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "interfaces/IGmxVault.sol";
import "interfaces/IGmxGlpManager.sol";
import "interfaces/IGmxPositionManager.sol";
import "interfaces/IGmxVaultReader.sol";
import "interfaces/IGmxReader.sol";

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;

    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);
}

contract GmxLens {
    uint256 private constant BASIS_POINTS_DIVISOR = 10000;
    uint256 private constant PRICE_PRECISION = 10 ** 30;
    uint256 private constant USDG_DECIMALS = 18;
    uint256 private constant PRECISION = 10 ** 18;

    struct TokenInfo {
        uint256 poolAmount;
        uint256 reservedAmount;
        uint256 availableAmount;
        uint256 usdgAmount;
        uint256 redemptionAmount;
        uint256 weight;
        uint256 bufferAmount;
        uint256 maxUsdgAmount;
        uint256 globalShortSize;
        uint256 maxGlobalShortSize;
        uint256 maxGlobalLongSize;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 guaranteedUsd;
        uint256 maxPrimaryPrice;
        uint256 minPrimaryPrice;
    }

    struct TokenFee {
        address token;
        uint256 fee;
    }

    IGmxGlpManager public immutable manager;
    IGmxVault public immutable vault;
    IGmxVaultReader public immutable vaultReader;
    IGmxPositionManager public immutable positionManager;
    IERC20 public immutable nativeToken;

    IERC20 private immutable glp;
    IERC20 private immutable usdg;

    constructor(
        IGmxGlpManager _manager,
        IGmxVault _vault,
        IGmxVaultReader _vaultReader,
        IGmxPositionManager _positionManager,
        IERC20 _nativeToken
    ) {
        manager = _manager;
        vault = _vault;
        vaultReader = _vaultReader;
        positionManager = _positionManager;
        nativeToken = _nativeToken;
        glp = IERC20(manager.glp());
        usdg = IERC20(manager.usdg());
    }

    function getGlpPrice() public view returns (uint256) {
        return (manager.getAumInUsdg(false) * PRICE_PRECISION) / glp.totalSupply();
    }

    function getTokenInfo(address token) public view returns (TokenInfo memory) {
        address[] memory vaultTokens = new address[](1);
        vaultTokens[0] = token;

        uint256[] memory result = vaultReader.getVaultTokenInfoV4(
            address(vault),
            address(positionManager),
            address(nativeToken),
            1e18,
            vaultTokens
        );
        return
            TokenInfo({
                poolAmount: result[0],
                reservedAmount: result[1],
                availableAmount: result[0] - result[1],
                usdgAmount: result[2],
                redemptionAmount: result[3],
                weight: result[4],
                bufferAmount: result[5],
                maxUsdgAmount: result[6],
                globalShortSize: result[7],
                maxGlobalShortSize: result[8],
                maxGlobalLongSize: result[9],
                minPrice: result[10],
                maxPrice: result[11],
                guaranteedUsd: result[12],
                maxPrimaryPrice: result[13],
                minPrimaryPrice: result[14]
            });
    }

    function getTokenOutFromBurningGlp(address tokenOut, uint256 glpAmount) public view returns (uint256 amount, uint256 feeBasisPoints) {
        uint256 usdgAmount = (glpAmount * getGlpPrice()) / PRECISION;

        feeBasisPoints = _getFeeBasisPoints(
            tokenOut,
            vault.usdgAmounts(tokenOut) - usdgAmount,
            usdgAmount,
            vault.mintBurnFeeBasisPoints(),
            vault.taxBasisPoints(),
            false
        );

        uint256 redemptionAmount = _getRedemptionAmount(tokenOut, usdgAmount);
        amount = _collectSwapFees(redemptionAmount, feeBasisPoints);
    }

    function getMintedGlpFromTokenIn(address tokenIn, uint256 amount) external view returns (uint256) {
        uint256 aumInUsdg = manager.getAumInUsdg(true);
        (uint256 usdgAmount, ) = _simulateBuyUSDG(tokenIn, amount);

        return aumInUsdg == 0 ? usdgAmount : ((usdgAmount * PRICE_PRECISION) / getGlpPrice());
    }

    function getUsdgAmountFromTokenIn(address tokenIn, uint256 tokenAmount) public view returns (uint256 usdgAmount) {
        uint256 price = vault.getMinPrice(tokenIn);
        uint256 rawUsdgAmount = (tokenAmount * price) / PRICE_PRECISION;
        return vault.adjustForDecimals(rawUsdgAmount, tokenIn, address(usdg));
    }

    function _simulateBuyUSDG(address tokenIn, uint256 tokenAmount) private view returns (uint256 amount, uint256 feeBasisPoints) {
        uint256 usdgAmount = getUsdgAmountFromTokenIn(tokenIn, tokenAmount);

        feeBasisPoints = _getFeeBasisPoints(
            tokenIn,
            vault.usdgAmounts(tokenIn),
            usdgAmount,
            vault.mintBurnFeeBasisPoints(),
            vault.taxBasisPoints(),
            true
        );

        uint256 amountAfterFees = _collectSwapFees(tokenAmount, feeBasisPoints);
        uint256 mintAmount = getUsdgAmountFromTokenIn(tokenIn, amountAfterFees);

        amount = vault.adjustForDecimals(mintAmount, tokenIn, address(usdg));
    }

    function _collectSwapFees(uint256 _amount, uint256 _feeBasisPoints) private pure returns (uint256) {
        return (_amount * (BASIS_POINTS_DIVISOR - _feeBasisPoints)) / BASIS_POINTS_DIVISOR;
    }

    function _getFeeBasisPoints(
        address _token,
        uint256 tokenUsdgAmount,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        if (!vault.hasDynamicFees()) {
            return _feeBasisPoints;
        }

        uint256 initialAmount = tokenUsdgAmount;
        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = _getTargetUsdgAmount(_token);
        if (targetAmount == 0) {
            return _feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        if (nextDiff < initialDiff) {
            uint256 rebateBps = (_taxBasisPoints * initialDiff) / targetAmount;
            return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = (_taxBasisPoints * averageDiff) / targetAmount;
        return _feeBasisPoints + taxBps;
    }

    function _getTargetUsdgAmount(address _token) private view returns (uint256) {
        uint256 supply = IERC20(usdg).totalSupply();

        if (supply == 0) {
            return 0;
        }
        uint256 weight = vault.tokenWeights(_token);
        return (weight * supply) / vault.totalTokenWeights();
    }

    function _decreaseUsdgAmount(address _token, uint256 _amount) private view returns (uint256) {
        uint256 value = vault.usdgAmounts(_token);
        if (value <= _amount) {
            return 0;
        }
        return value - _amount;
    }

    function _getRedemptionAmount(address _token, uint256 _usdgAmount) private view returns (uint256) {
        uint256 price = _getMaxPrice(_token);
        uint256 redemptionAmount = (_usdgAmount * PRICE_PRECISION) / price;

        return _adjustForDecimals(redemptionAmount, address(usdg), _token);
    }

    function _adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) private view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == address(usdg) ? USDG_DECIMALS : vault.tokenDecimals(_tokenDiv);
        uint256 decimalsMul = _tokenMul == address(usdg) ? USDG_DECIMALS : vault.tokenDecimals(_tokenMul);

        return (_amount * 10 ** decimalsMul) / 10 ** decimalsDiv;
    }

    function _getMaxPrice(address _token) private view returns (uint256) {
        return IVaultPriceFeed(vault.priceFeed()).getPrice(_token, true, false, true);
    }
}