// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

pragma solidity 0.8.11;

interface IRewardRouter {
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function signalTransfer(address _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IStakedGlp {
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IVault {
    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function whitelistedTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function stableTokens(address) external view returns (bool);

    function poolAmounts(address) external view returns (uint256);

    function globalShortSizes(address) external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);

    function guaranteedUsd(address) external view returns (uint256);

    function reservedAmounts(address) external view returns (uint256);

    function cumulativeFundingRates(address) external view returns (uint256);

    function getFundingFee(address _token, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function lastFundingTimes(address) external view returns (uint256);

    function updateCumulativeFundingRate(address _token) external;

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);

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
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function gov() external view returns (address);

    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function setUsdgAmount(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IGmxHelper {
    function getTokenAums(address[] memory _tokens, bool _maximise) external view returns (uint256[] memory);

    function getTokenAumsPerAmount(uint256 _fsGlpAmount, bool _maximise) external view returns (uint256, uint256);

    function getPrice(address _token, bool _maximise) external view returns (uint256);

    function totalValue(address _account) external view returns (uint256);

    function getLastFundingTime() external view returns (uint256);

    function getCumulativeFundingRates(address _token) external view returns (uint256);

    function getFundingFee(address _account, address _indexToken) external view returns (uint256);

    function getLongValue(uint256 _glpAmount) external view returns (uint256);

    function getLongValueInUsdg(uint256 _glpAmount) external view returns (uint256);

    function getShortValue(address _account, address _indexToken) external view returns (uint256);

    function getMintBurnFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        bool _increment
    ) external view returns (uint256);

    function getGlpTotalSupply() external view returns (uint256);

    function getAumInUsdg(bool _maximise) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getPosition(
        address _account,
        address _indexToken
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function getFundingFeeWithRate(
        address _account,
        address _indexToken,
        uint256 _fundingRate
    ) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _avgPrice) external view returns (bool, uint256);

    function getAvailableShortSize(address _indexToken) external view returns (uint256);

    function getAvailableGlpAmountIn(address _token) external view returns (uint256);

    function validateMaxGlobalShortSize(address _indexToken, uint256 _sizeDelta) external view returns (bool);

    function getAum(bool _maximise) external view returns (uint256);

    function adjustDecimalsToUsdg(uint256 _amount, address _token) external view returns (uint256);

    function adjustDecimalsFromUsdg(uint256 _amount, address _token) external view returns (uint256);

    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);

    function getFundingInterval() external view returns (uint256);

    function getMinExecutionFee() external view returns (uint256);

    function usdg() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IStrategyVault {
    function totalAssets() external view returns (uint256);

    function feeReserves() external view returns (uint256);

    function handleBuy(uint256 _amount) external payable returns (uint256);

    function handleSell(uint256 _amount, address _recipient) external payable;

    function harvest() external;

    function confirm() external;

    function confirmCallback() external;

    function totalValue() external view returns (uint256);

    function executePositions(bytes4[] calldata _selectors, bytes[] calldata _params) external payable;

    function confirmAndDealGlp(bytes4 _selector, bytes calldata _param) external;

    function executeDecreasePositions(bytes[] calldata _params) external payable;

    function executeIncreasePositions(bytes[] calldata _params) external payable;

    function buyNeuGlp(uint256 _amountIn) external returns (uint256);

    function sellNeuGlp(uint256 _glpAmount, address _recipient) external returns (uint256);

    function settle(uint256 _amount, address _recipient) external;
    
    function exited() external view returns(bool);

    function usdToTokenMax(address _token, uint256 _usdAmount, bool _isCeil) external returns (uint256);

    function decreaseShortPositionsWithCallback(
        uint256 _wbtcCollateralDelta,
        uint256 _wbtcSizeDelta,
        uint256 _wethCollateralDelta,
        uint256 _wethSizeDelta,
        bool _shouldRepayWbtc,
        bool _shouldRepayWeth,
        address _recipient,
        address _callbackTarget
    ) external payable returns(bytes32, bytes32);

    function increaseShortPositionsWithCallback(
        uint256 _wbtcAmountIn,
        uint256 _wbtcSizeDelta,
        uint256 _wethAmountIn,
        uint256 _wethSizeDelta,
        address _callbackTarget
    ) external payable returns (bytes32, bytes32);

    function instantRepayFundingFee(address _indexToken, address _callbackTarget) external payable;

    function buyGlp(uint256 _amount) external returns (uint256);

    function sellGlp(uint256 _amount, address _recipient) external returns (uint256);

    function transferFailedAmount(uint256 _wantAmount, uint256 _glpAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "Governable: invalid address");
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IRewardTracker} from "./interfaces/IRewardTracker.sol";
import { IStrategyVault } from "./interfaces/IStrategyVault.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IMintable } from "./interfaces/IMintable.sol";
import { Governable } from "./libraries/Governable.sol";
import { IGmxHelper } from "./interfaces/IGmxHelper.sol";
import { IVault } from "./interfaces/gmx/IVault.sol";
import { IStakedGlp } from "./interfaces/gmx/IStakedGlp.sol";
import { IRewardRouter } from "./interfaces/gmx/IRewardRouter.sol";

struct InitialConfig {
    address fsGlp;
    address nGlp;
    address fnGlp;
    address snGlp;
    address gmxVault;
    address stakedGlp;
    address glpRewardRouter;
    address glpManager;

    address strategyVault;
    address gmxHelper;

    address want;
    address wbtc;
    address weth;
}


contract RouterV2 is Governable, Pausable, ReentrancyGuard {
    struct PendingStatus {
        address recipient;
        bool isProgress;
        uint256 totalValueBefore; // 30 decimals
        uint256 totalSupplyBefore; // 18 decimals
        bool fisrtCallbackExecuted;
        bool withdrawGlp;
        uint256 longValueBefore;
        uint256 wbtcCollateralBefore;
        uint256 wethCollateralBefore;
    }

    struct PositionParams {
        uint256 size;
        uint256 collateral;
        uint256 avgPrice;
    }

    struct ProfitParams {
        bool hasProfit;
        uint256 pnl;
    }

    uint256 constant MINIMUM_WITHDRAWL = 1e16;
    uint256 constant MAX_BPS = 10_000;
    uint256 constant PRICE_PRECISON = 1e30;

    address public immutable fsGlp;
    address public immutable snGlp;
    address public immutable fnGlp;
    address public immutable nGlp;
    address public immutable gmxVault;
    address public immutable stakedGlp;
    address public immutable glpRewardRouter;

    address public immutable want;
    address public immutable wbtc;
    address public immutable weth;

    address public immutable strategyVault;
    address public gmxHelper;

    // callback
    address public executionCallbackTarget;
    address public repayCallbackTarget;

    // GMX fee
    uint256 public marginFeeBasisPoints = 10;

    uint256 public targetLeverage = 80_000;
    uint256 public timeBuffer = 3540;

    uint256 public cumulativeMintAmount;
    uint256 public cumulativeBurnAmount;

    bytes32 public curWbtcRequestKey;
    bytes32 public curWethRequestKey;

    bool public isExecutionFailed;
    bool public isDepositOpen = true;

    mapping(address => uint256) public shortBuffers;

    PendingStatus public pendingStatus;

    event InstantDeposit(address account, uint256 amount);
    event InstantDepositGlp(address account, uint256 amount);
    event InstantWithdraw(address account, uint256 amount);
    event FirstCallback(address recipient, bool isIncrease);
    event SecondCallback(address recipient, bool isIncrease);
    event ExecutionFailed(address recipient, bool fisrtCallbackExecuted, bool isIncrease, bool isRepay);
    event SetCallbackTargets(address executionCallbackTarget, address repayCallbackTarget);
    event SetTargetLeverage(uint256 taregtLeverage);
    event SetMarginFeeBasisPoints(uint256 bps);
    event SetShortBuffers(uint256 wbtcBuffer, uint256 wethBuffer);
    event SetGmxHelper(address helper);
    event MintedShare(uint256 share);
    event RedeemedAmount(uint256 wantAmount, uint256 fsGlpAmount, bool withdrawGlp);
    event SetTimeBuffer(uint256 buffer);
    event SetIsDepositOpen(bool open);

    modifier initialValidate() {
        _initialValidate();
        _;
    }

    constructor(InitialConfig memory _config) {
        fsGlp = _config.fsGlp;
        snGlp = _config.snGlp;
        fnGlp = _config.fnGlp;
        nGlp = _config.nGlp;
        gmxVault = _config.gmxVault;
        glpRewardRouter = _config.glpRewardRouter;
        stakedGlp = _config.stakedGlp;

        want = _config.want;

        wbtc = _config.wbtc;
        weth = _config.weth;

        strategyVault = _config.strategyVault;
        gmxHelper = _config.gmxHelper;

        IERC20(want).approve(_config.glpManager, type(uint256).max);
        IERC20(want).approve(strategyVault, type(uint256).max);
        IStakedGlp(stakedGlp).approve(strategyVault, type(uint256).max);
    }

    /**
     * @notice
     *  deposit `_amount` of `want` and issue `snGlp` as a share
     *  This function should not be executed while a deposit or withdrawal is in progress
     * @param _amount the quantity of tokens to deposit
     */
    function instantDeposit(uint256 _amount) external payable whenNotPaused initialValidate nonReentrant {
        _isDepositOpen();

        uint256 minExecutionFee = IGmxHelper(gmxHelper).getMinExecutionFee();
        require(msg.value >= minExecutionFee * 2, "not enough execution fee");

        _validatePositionQueue();

        IStrategyVault(strategyVault).harvest();

        _checkLastFundingTime();
        _setPendingStatus(true);

        (uint256 glpAmountIn, uint256 wbtcAmountIn, uint256 wethAmountIn) = getDepositParams(_amount);
        require(glpAmountIn > 0);

        IERC20(want).transferFrom(msg.sender, strategyVault, _amount);

        uint256 amountOut = IStrategyVault(strategyVault).buyGlp(glpAmountIn);

        _mintNeutraGlp(0x0);

        // calculate the sizeDelta based on the amountOut
        // to ensure the exact amount of fsGlp received is considered
        (uint256 wbtcSizeDelta, uint256 wethSizeDelta) = IGmxHelper(gmxHelper).getTokenAumsPerAmount(amountOut, false);

        _validateMaxGlobalShortSize(wbtcSizeDelta, wethSizeDelta);

        (bytes32 wbtcRequestKey, bytes32 wethRequestkey) = IStrategyVault(strategyVault).increaseShortPositionsWithCallback{value: minExecutionFee * 2}(
            wbtcAmountIn,
            wbtcSizeDelta,
            wethAmountIn,
            wethSizeDelta,
            executionCallbackTarget
        );

        curWbtcRequestKey = wbtcRequestKey;
        curWethRequestKey = wethRequestkey;

        payable(msg.sender).transfer(address(this).balance);

        emit InstantDeposit(msg.sender, _amount);
    }

    /**
     * @notice
     *  deposit `_amount` of `glp` and issue `snGlp` as a share
     *  This function should not be executed while a deposit or withdrawal is in progress
     * @param _amount the quantity of tokens to deposit
     */
    function instantDepositGlp(uint256 _amount) external payable whenNotPaused initialValidate nonReentrant {
        _isDepositOpen();

        uint256 minExecutionFee = IGmxHelper(gmxHelper).getMinExecutionFee();
        require(msg.value >= minExecutionFee * 2, "not enough execution fee");

        _validatePositionQueue();

        IStrategyVault(strategyVault).harvest();

        _checkLastFundingTime();
        _setPendingStatus(true);

        IStakedGlp(stakedGlp).transferFrom(msg.sender, address(this), _amount);

        uint256 valueInUsdg = IGmxHelper(gmxHelper).getLongValueInUsdg(_amount);
        uint256 redemptionAmount = IGmxHelper(gmxHelper).getRedemptionAmount(want, valueInUsdg);
        require(redemptionAmount > 0);
        
        (, uint256 wbtcAmountIn, uint256 wethAmountIn) = getDepositParams(redemptionAmount);

        uint256 unstakeGlpAmount = _amount * (wbtcAmountIn + wethAmountIn) / redemptionAmount;
        
        IStakedGlp(stakedGlp).transfer(strategyVault, unstakeGlpAmount);

        uint256 amountOut = IStrategyVault(strategyVault).sellGlp(unstakeGlpAmount, address(this));

        uint256 wbtcAmountInAfterFee = amountOut * wbtcAmountIn / (wbtcAmountIn + wethAmountIn);
        uint256 wethAmountInAfterFee = amountOut - wbtcAmountInAfterFee;

        (uint256 wbtcSizeDelta, uint256 wethSizeDelta) = IGmxHelper(gmxHelper).getTokenAumsPerAmount(_amount - unstakeGlpAmount, false);

        _validateMaxGlobalShortSize(wbtcSizeDelta, wethSizeDelta);

        IStakedGlp(stakedGlp).transfer(strategyVault, _amount - unstakeGlpAmount);

        _mintNeutraGlp(0x0);

        (bytes32 wbtcRequestKey, bytes32 wethRequestkey) = IStrategyVault(strategyVault).increaseShortPositionsWithCallback{value: minExecutionFee * 2}(
            wbtcAmountInAfterFee,
            wbtcSizeDelta,
            wethAmountInAfterFee,
            wethSizeDelta,
            executionCallbackTarget
        );

        curWbtcRequestKey = wbtcRequestKey;
        curWethRequestKey = wethRequestkey;

        payable(msg.sender).transfer(address(this).balance);

        emit InstantDepositGlp(msg.sender, _amount);
    }

    /**
     * @notice
     *  burn `_amount` of share and redeem `token`
     *  This function should not be executed while a deposit or withdrawal is in progress
     * @param _amount the quantity of snGlp to redeem for `tokens`
     * @param _isStaked determines whether input is `snGlp` or `nGlp`
     * @param _withdrawGlp determines wheter output is `fsGlp` or `want`
     */
    function instantWithdraw(uint256 _amount, bool _isStaked, bool _withdrawGlp) external payable whenNotPaused initialValidate nonReentrant {
        uint256 minExecutionFee = IGmxHelper(gmxHelper).getMinExecutionFee();
        require(msg.value >= minExecutionFee * 4, "not enough execution fee");
        require(_amount >= MINIMUM_WITHDRAWL, "insufficient _amount");

        _validatePositionQueue();

        // should harvest first in order to withdraw managementFee before withdraw action
        IStrategyVault(strategyVault).harvest();

        _checkLastFundingTime();
        _setPendingStatus(false);

        if (_isStaked) {
            IRewardTracker(snGlp).unstakeForAccount(msg.sender, fnGlp, _amount, msg.sender);
            IRewardTracker(fnGlp).unstakeForAccount(msg.sender, nGlp, _amount, address(this));
        } else {
            IERC20(nGlp).transferFrom(msg.sender, address(this), _amount);
        }

        (uint256 wbtcSizeDelta, uint256 wbtcCollateralDelta, bool shouldRepayWbtc) = getWithdrawParams(_amount, pendingStatus.totalSupplyBefore, wbtc);
        (uint256 wethSizeDelta, uint256 wethCollateralDelta, bool shouldRepayWeth) = getWithdrawParams(_amount, pendingStatus.totalSupplyBefore, weth);

        uint256 totalBalance = IERC20(fsGlp).balanceOf(strategyVault);
        uint256 unstakeGlpAmount = totalBalance * _amount / pendingStatus.totalSupplyBefore;

        if (_withdrawGlp) {
            // _validateMaxGlpAmountIn(wbtcCollateralDelta + wethCollateralDelta);
            IStakedGlp(stakedGlp).transferFrom(strategyVault, address(this), unstakeGlpAmount);

            pendingStatus.withdrawGlp = true;
        } else {
            IStrategyVault(strategyVault).sellGlp(unstakeGlpAmount, address(this));
        }

        _burnNeutraGlp();

        if (shouldRepayWbtc) {
            IStrategyVault(strategyVault).instantRepayFundingFee{value: minExecutionFee}(wbtc, repayCallbackTarget);
        }

        if (shouldRepayWeth) {
            IStrategyVault(strategyVault).instantRepayFundingFee{value: minExecutionFee}(weth, repayCallbackTarget);
        }

        (bytes32 wbtcRequestKey, bytes32 wethRequestkey) = IStrategyVault(strategyVault).decreaseShortPositionsWithCallback{value: minExecutionFee * 2}(
            wbtcCollateralDelta, 
            wbtcSizeDelta, 
            wethCollateralDelta, 
            wethSizeDelta,
            shouldRepayWbtc,
            shouldRepayWeth, 
            address(this), 
            executionCallbackTarget
        );

        curWbtcRequestKey = wbtcRequestKey;
        curWethRequestKey = wethRequestkey;

        payable(msg.sender).transfer(address(this).balance);

        emit InstantWithdraw(msg.sender, _amount);
    }

    /**
     * @notice
     *  deposit/withdraw function only requests for creating positions
     *  actual positions are executed by the keeper of GMX
     *  two positions are always executed (BTC, ETH)
     *  this function is executed when the first asset of a position is successfully executed
     * @param _isIncrease determines whether it is an `increase` or `decrease` position
     * @param _requestKey a unique 256-bit hash by concatenating and hashing account and index from GMX
     */
    function firstCallback(bool _isIncrease, bytes32 _requestKey) public {
        require(msg.sender == executionCallbackTarget, "invalid msg.sender");
        
        if (_isIncrease) {
            _mintNeutraGlp(_requestKey);
        } else {
            _burnNeutraGlp();
        }

        pendingStatus.fisrtCallbackExecuted = true;
        emit FirstCallback(pendingStatus.recipient, _isIncrease);
    }

    /**
     * @notice
     *  deposit/withdraw function only requests for creating positions
     *  actual positions are executed by the keeper of GMX
     *  two positions are always executed (BTC, ETH)
     *  this function is executed when the second asset of a position is successfully executed
     * @param _isIncrease determines whether it is an `increase` or `decrease` position
     * @param _requestKey a unique 256-bit hash by concatenating and hashing account and index from GMX
     */
    function secondCallback(bool _isIncrease, bytes32 _requestKey) public {
        require(msg.sender == executionCallbackTarget, "invalid msg.sender");
        IStrategyVault _vault = IStrategyVault(strategyVault);

        _vault.confirmCallback();

        address recipient = pendingStatus.recipient;

        if (_isIncrease) {
            _mintNeutraGlp(_requestKey);

            IRewardTracker(fnGlp).stakeForAccount(address(this), recipient, nGlp, cumulativeMintAmount);
            IRewardTracker(snGlp).stakeForAccount(recipient, recipient, fnGlp, cumulativeMintAmount);

            emit MintedShare(cumulativeMintAmount);
            cumulativeMintAmount = 0;
        } else {
            uint256 remainingAmount = IERC20(nGlp).balanceOf(address(this));
            IMintable(nGlp).burn(address(this), remainingAmount);

            uint256 balance = IERC20(want).balanceOf(address(this));

            // To minimize the risk of failure, we'll be withdrawing for both GLP and DAI. 
            // Additionally, this action should significantly reduce fees
            if(pendingStatus.withdrawGlp) {
                // IRewardRouter(glpRewardRouter).mintAndStakeGlp(want, balance, 0, 0);
                IERC20(want).transfer(recipient, balance);

                uint256 fsGlpAmount = IERC20(fsGlp).balanceOf(address(this));
                IStakedGlp(stakedGlp).transfer(recipient, fsGlpAmount);

                emit RedeemedAmount(balance, fsGlpAmount, true);
                pendingStatus.withdrawGlp = false;
            } else {
                IERC20(want).transfer(recipient, balance);

                emit RedeemedAmount(balance, 0, false);
            }
            
            cumulativeBurnAmount = 0;
        }

        _clearPendingStatus(_isIncrease);

        emit SecondCallback(recipient, _isIncrease);
    }

    function getDepositParams(uint256 _amount) public view returns (uint256, uint256, uint256) {
        uint256 glpAmountIn; // want decimals
        uint256 wbtcAmountIn; // want decimals
        uint256 wethAmountIn; // want decimals

        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        uint256 totalAum = _gmxHelper.getAum(false);

        address[] memory tokens = new address[](2);
        tokens[0] = wbtc;
        tokens[1] = weth;
        uint256[] memory aums = _gmxHelper.getTokenAums(tokens, false);

        uint256 wbtcRatio = (aums[0] * MAX_BPS) / totalAum;
        uint256 wethRatio = (aums[1] * MAX_BPS) / totalAum;


        glpAmountIn = _amount * targetLeverage / (wbtcRatio + wethRatio + targetLeverage);

        uint256 remainingAmount = _amount - glpAmountIn;
        wbtcAmountIn = remainingAmount * wbtcRatio / (wbtcRatio + wethRatio);
        wethAmountIn = remainingAmount - wbtcAmountIn;
        
        return (glpAmountIn, wbtcAmountIn, wethAmountIn);
    }

    function getWithdrawParams(uint256 _amount, uint256 _totalSupply, address _indexToken) public view returns (uint256, uint256, bool) {        
        PositionParams memory positionParam = getPositionParams(strategyVault, _indexToken);
        ProfitParams memory profitParam = getProfitParams(_indexToken, positionParam.size, positionParam.avgPrice);

        uint256 sizeDelta = positionParam.size * _amount / _totalSupply;

        // compare sum of positionFee and fudningFee with the value of usdOut
        // to determine the fees will be deducted from position.collateral or usdOut
        uint256 usdOut = profitParam.hasProfit ? sizeDelta * profitParam.pnl / positionParam.size : 0;
        uint256 positionFee = sizeDelta * marginFeeBasisPoints / MAX_BPS;
        uint256 fundingFee = IGmxHelper(gmxHelper).getFundingFee(strategyVault, _indexToken);

        uint256 collateralDelta;
        bool shouldRepay;
        if(!profitParam.hasProfit) {
            collateralDelta = (positionParam.collateral - profitParam.pnl) * _amount / _totalSupply;
            shouldRepay = fundingFee + positionFee > usdOut + collateralDelta;
            return (sizeDelta, collateralDelta, shouldRepay);
        }

        collateralDelta = positionParam.collateral * _amount / _totalSupply;
        shouldRepay = fundingFee + positionFee > usdOut + collateralDelta;
        return (sizeDelta, collateralDelta, shouldRepay);
    }

    function getPositionParams(address _account, address _indexToken) public view returns (PositionParams memory) {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        (uint256 size, uint256 collateral, uint256 avgPrice,,,,,) = _gmxHelper.getPosition(_account, _indexToken);
        return PositionParams(size, collateral, avgPrice);
    }

    function getProfitParams(address _indexToken, uint256 _size, uint256 _avgPrice) public view returns (ProfitParams memory) {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        (bool hasProfit, uint256 pnl) = _gmxHelper.getDelta(_indexToken, _size, _avgPrice);
        return ProfitParams(hasProfit, pnl);    
    }

    function _mintNeutraGlp(bytes32 _key) internal {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);

        uint256 increasedValue;
        uint256 mintAmount;

        if(_key == 0x0) {
            uint256 currentValue = _gmxHelper.getLongValue(IERC20(fsGlp).balanceOf(strategyVault));
            increasedValue = currentValue - pendingStatus.longValueBefore;

            uint256 totalValueBefore = pendingStatus.totalValueBefore;

            mintAmount = totalValueBefore == 0 ?
                increasedValue * IERC20(nGlp).decimals() / PRICE_PRECISON : 
                increasedValue * pendingStatus.totalSupplyBefore / totalValueBefore;

            IMintable(nGlp).mint(address(this), mintAmount);
            cumulativeMintAmount = mintAmount;
            return;
        }

        if (_key == curWbtcRequestKey) {
            (,uint256 collateral,,,,,,) = _gmxHelper.getPosition(strategyVault, wbtc);
            increasedValue = collateral - pendingStatus.wbtcCollateralBefore;
            
            uint256 totalValueBefore = pendingStatus.totalValueBefore;

            mintAmount = totalValueBefore == 0 ?
                increasedValue * IERC20(nGlp).decimals() / PRICE_PRECISON : 
                increasedValue * pendingStatus.totalSupplyBefore / totalValueBefore;

            IMintable(nGlp).mint(address(this), mintAmount);
            cumulativeMintAmount += mintAmount;
            return;
        }

        if (_key == curWethRequestKey) {
            (,uint256 collateral,,,,,,) = _gmxHelper.getPosition(strategyVault, weth);
            increasedValue = collateral - pendingStatus.wethCollateralBefore;

            uint256 totalValueBefore = pendingStatus.totalValueBefore;

            mintAmount = totalValueBefore == 0 ?
                increasedValue * IERC20(nGlp).decimals() / PRICE_PRECISON : 
                increasedValue * pendingStatus.totalSupplyBefore / totalValueBefore;

            IMintable(nGlp).mint(address(this), mintAmount);
            cumulativeMintAmount += mintAmount;
            return;
        } 
    }

    function _burnNeutraGlp() internal {
        uint256 totalValue = IStrategyVault(strategyVault).totalValue();
        uint256 totalValueBefore = pendingStatus.totalValueBefore;
        uint256 decreasedValue = totalValueBefore < totalValue ? 0 : totalValueBefore - totalValue;
        
        if (decreasedValue == 0) {
            return;
        }

        uint256 burnAmount = decreasedValue * pendingStatus.totalSupplyBefore / totalValueBefore;
        uint256 nGlpBalance = IERC20(nGlp).balanceOf(address(this));
        if (nGlpBalance <= burnAmount - cumulativeBurnAmount) {
            IMintable(nGlp).burn(address(this), nGlpBalance);
            cumulativeBurnAmount += nGlpBalance;
        } else {
            IMintable(nGlp).burn(address(this), burnAmount - cumulativeBurnAmount);
            cumulativeBurnAmount = burnAmount;
        }
    }

    function _checkLastFundingTime() internal {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        uint256 lastFundingTime = _gmxHelper.getLastFundingTime();
        uint256 fundingInterval = _gmxHelper.getFundingInterval();
        if (lastFundingTime + fundingInterval <= block.timestamp) {
            IVault(gmxVault).updateCumulativeFundingRate(want);
        }
    }

    function _validateMaxGlobalShortSize(uint256 _wbtcSizeDelta, uint256 _wethSizeDelta) internal view {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);

        uint256 wbtcAvailableSize = _gmxHelper.getAvailableShortSize(wbtc);
        require(wbtcAvailableSize > _wbtcSizeDelta + shortBuffers[wbtc], "OI limit exceeded");

        uint256 wethAvailableSize = _gmxHelper.getAvailableShortSize(weth);
        require(wethAvailableSize > _wethSizeDelta + shortBuffers[weth], "OI limit exceeded");
    }

    function _validateMaxGlpAmountIn(uint256 _collateralDelta) internal view {
        uint256 amount = usdToTokenMax(want, _collateralDelta, true);
        uint256 usdgAmount = IGmxHelper(gmxHelper).adjustDecimalsToUsdg(amount, want);
        uint256 availableUsdgAmount = IGmxHelper(gmxHelper).getAvailableGlpAmountIn(want);
        require(availableUsdgAmount > usdgAmount, "max usdgAmount exceeded");
    }

    // GMX keeper keeps track of queue of pending increase and decrease orders. 
    // for each order type it executes at most N orders per transaction. 
    // meaning if there are more than N increase orders to execute and your order is N + 1
    // then it will be executed after first N decrease orders
    // if both queues are empty (or increase queue is empty)
    // increase positions should be always executed first
    function _validatePositionQueue() internal view {
        (
            uint256 increasePositionRequestKeysStart, 
            uint256 increasePositionRequestKeysLength,,
        ) = IGmxHelper(gmxHelper).getRequestQueueLengths();

        require(increasePositionRequestKeysStart >= increasePositionRequestKeysLength, "queue is not empty");
    }

    function _setPendingStatus(bool _isIncrease) internal {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        pendingStatus.isProgress = true;
        pendingStatus.recipient = msg.sender;
        pendingStatus.totalValueBefore = IStrategyVault(strategyVault).totalValue();
        pendingStatus.totalSupplyBefore = IERC20(nGlp).totalSupply();

        if (_isIncrease) {
            pendingStatus.longValueBefore = _gmxHelper.getLongValue(IERC20(fsGlp).balanceOf(strategyVault));
            (,uint256 wbtcCollateral,,,,,,) = _gmxHelper.getPosition(strategyVault, wbtc);
            (,uint256 wethCollateral,,,,,,) = _gmxHelper.getPosition(strategyVault, weth);
            pendingStatus.wbtcCollateralBefore = wbtcCollateral;
            pendingStatus.wethCollateralBefore = wethCollateral;
        }
    }

    function _clearPendingStatus(bool _isIncrease) internal {
        pendingStatus.isProgress = false;
        pendingStatus.recipient = address(0);
        pendingStatus.fisrtCallbackExecuted = false;
        pendingStatus.totalValueBefore = 0;
        pendingStatus.totalSupplyBefore = 0;

        if (_isIncrease) {
            pendingStatus.longValueBefore = 0;
            pendingStatus.wbtcCollateralBefore = 0;
            pendingStatus.wethCollateralBefore = 0;
        }
    }

    function _initialValidate() internal view {
        require(!pendingStatus.isProgress, "in the middle of progress");
        require(block.timestamp % 3600 <= timeBuffer, "try a bit later");
    }

    function _isDepositOpen() internal view {
        require(isDepositOpen, "closed");
    }

    function failCallback(bool _isIncrease) external {
        require(msg.sender == executionCallbackTarget || msg.sender == repayCallbackTarget, "invalid msg.sender");

        isExecutionFailed = true;

        bool isRepay;
        if (msg.sender == repayCallbackTarget) {
            isRepay = true;
        }

        emit ExecutionFailed(pendingStatus.recipient, pendingStatus.fisrtCallbackExecuted, _isIncrease, isRepay);
    }

    function handleFailure(uint256 _wantAmount, uint256 _glpAmount) external onlyGov {
        require(isExecutionFailed, "execution not failed");

        if (_wantAmount > 0) {
            uint256 balance = IERC20(want).balanceOf(strategyVault);
            uint256 feeReserves = IStrategyVault(strategyVault).feeReserves();
            require(_wantAmount <= balance - feeReserves, "exceeded transferableAmouont"); 

            IERC20(want).transferFrom(strategyVault, pendingStatus.recipient, _wantAmount);
        }

        if (_glpAmount > 0) {
            IStakedGlp(stakedGlp).transferFrom(strategyVault, pendingStatus.recipient, _glpAmount);
        }

        bool isIncrease;
        if (cumulativeBurnAmount == 0) {
            isIncrease = true;
        }

        _clearPendingStatus(isIncrease);

        isExecutionFailed = false;
    }

    function setCallbackTargets(address _executionCallbackTarget, address _repayCallbackTarget) external onlyGov {
        require( _executionCallbackTarget != address(0) && _repayCallbackTarget != address(0));
        executionCallbackTarget = _executionCallbackTarget;
        repayCallbackTarget = _repayCallbackTarget;
        emit SetCallbackTargets(_executionCallbackTarget, _repayCallbackTarget);
    }

    function setTargetLeverage(uint256 _lev) external onlyGov {
        targetLeverage = _lev;
        emit SetTargetLeverage(_lev);
    }

    function setMarginFeeBasisPoints(uint256 _bps) external onlyGov {
        marginFeeBasisPoints = _bps;
        emit SetMarginFeeBasisPoints(_bps);
    }

    function setShortBuffers(uint256 _wbtcBuffer, uint256 _wethBuffer) external onlyGov {
        shortBuffers[wbtc] = _wbtcBuffer; // 30 decimals
        shortBuffers[weth] = _wethBuffer; // 30 decimals
        emit SetShortBuffers(_wbtcBuffer, _wethBuffer);
    }

    function setGmxHelper(address _helper) external onlyGov {
        require(_helper != address(0), "invalid address");
        gmxHelper = _helper;
        emit SetGmxHelper(_helper);
    }

    function setTimeBuffer(uint256 _buffer) external onlyGov {
        require(_buffer >= 3640, "buffer too low");
        timeBuffer = _buffer;
        emit SetTimeBuffer(_buffer);
    }

    function setIsDepositOpen(bool _open) external onlyGov {
        isDepositOpen = _open;
        emit SetIsDepositOpen(_open);
    }

    function pause() external onlyGov {
        _pause();
    }

    function unpause() external onlyGov {
        _unpause();
    }

    function usdToTokenMax(address _token, uint256 _usdAmount, bool _isCeil) public view returns(uint256) {
        if (_usdAmount == 0) { return 0; }
        uint256 price = IGmxHelper(gmxHelper).getPrice(_token, false);
        uint256 decimals = IERC20(_token).decimals();
        return _isCeil ? ceilDiv(_usdAmount * (10 ** decimals), price) : _usdAmount * (10 ** decimals) / price;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

}