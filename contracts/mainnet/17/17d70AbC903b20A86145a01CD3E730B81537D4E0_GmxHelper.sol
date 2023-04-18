// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import {IERC20} from "./interfaces/IERC20.sol";
import {IVault as IGmxVault} from "./interfaces/gmx/IVault.sol";
import {IRewardTracker} from "./interfaces/gmx/IRewardTracker.sol";
import {IGlpManager} from "./interfaces/gmx/IGlpManager.sol";
import {IPositionRouter} from "./interfaces/gmx/IPositionRouter.sol";
import {IBot} from "./interfaces/IBot.sol";

struct GmxConfig {
    address vault;
    address glp;
    address fsGlp;
    address glpManager;
    address positionRouter;
    address usdg;
}

contract GmxHelper {
    address public gov;

    // deposit token
    address public want;
    address public wbtc;
    address public weth;

    // GMX contracts
    address public gmxVault;
    address public glp;
    address public fsGlp;
    address public glpManager;
    address public positionRouter;
    address public usdg;
    //
    uint256 public constant BASE_LEVERAGE = 10000; // 1x

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    function _onlyGov() internal view {
        require(msg.sender == gov, "GMXStrategy: Not Authorized");
    }

    constructor(GmxConfig memory _config, address _want, address _wbtc, address _weth) {
        gmxVault = _config.vault;
        glp = _config.glp;
        fsGlp = _config.fsGlp;
        glpManager = _config.glpManager;
        positionRouter = _config.positionRouter;

        want = _want;
        wbtc = _wbtc;
        weth = _weth;
    }

    function getAumInUsdg(bool _maximise) public view returns (uint256) {
        return IGlpManager(glpManager).getAumInUsdg(_maximise);
    }

    function getGlpTotalSupply() public view returns (uint256) {
        return IERC20(glp).totalSupply();
    }

    function getConfig(address _vault) public view returns (uint256[] memory) {
        uint256[] memory config = new uint256[](15);
        config[0] = IGlpManager(glpManager).getAum(true);
        config[1] = IGlpManager(glpManager).getAum(false);

        address[] memory tokens = new address[](2);
        tokens[0] = wbtc;
        tokens[1] = weth;
        uint256[] memory aums = getTokenAums(tokens, false);

        config[2] = aums[0];
        config[3] = aums[1];

        (uint256 wbtcSize, uint256 wbtcCollateral, uint256 wbtcAvgPrice, , , , , ) = getPosition(_vault, wbtc);
        (uint256 wethSize, uint256 wethCollateral, uint256 wethAvgPrice, , , , , ) = getPosition(_vault, weth);

        config[4] = IERC20(glp).totalSupply();
        config[5] = IERC20(fsGlp).balanceOf(_vault);
        config[6] = wbtcSize;
        config[7] = wbtcCollateral;
        config[8] = wbtcAvgPrice;
        config[9] = wethSize;
        config[10] = wethCollateral;
        config[11] = wethAvgPrice;
        config[12] = getPrice(wbtc, false);
        config[13] = getPrice(weth, false);

        return config;
    }

    function getTokenAums(address[] memory _tokens, bool _maximise) public view returns (uint256[] memory) {
        uint256[] memory aums = new uint256[](_tokens.length);
        IGmxVault _gmxVault = IGmxVault(gmxVault);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 aum;

            if (!_gmxVault.whitelistedTokens(token)) {
                aums[i] = 0;
                continue;
            }

            // ignore stable token
            if (_gmxVault.stableTokens(token)) {
                aums[i] = 0;
                continue;
            }

            uint256 price = _maximise ? _gmxVault.getMaxPrice(token) : _gmxVault.getMinPrice(token);
            uint256 poolAmount = _gmxVault.poolAmounts(token);
            uint256 decimals = _gmxVault.tokenDecimals(token);
            uint256 reservedAmount = _gmxVault.reservedAmounts(token);

            aum = aum + _gmxVault.guaranteedUsd(token);
            aum = aum + (((poolAmount - reservedAmount) * price) / (10 ** decimals));
            aums[i] = aum;
        }
        return aums;
    }

    /// @notice calculate aums of each wbtc and weth depending on '_fsGlpAmount'
    function getTokenAumsPerAmount(uint256 _fsGlpAmount, bool _maximise) public view returns (uint256, uint256) {
        address[] memory tokens = new address[](2);
        tokens[0] = wbtc;
        tokens[1] = weth;
        uint256[] memory aums = getTokenAums(tokens, _maximise);
        uint256 totalSupply = IERC20(glp).totalSupply();

        uint256 wbtcAum = (aums[0] * _fsGlpAmount) / totalSupply;
        uint256 wethAum = (aums[1] * _fsGlpAmount) / totalSupply;
        return (wbtcAum, wethAum);
    }

    function getPrice(address _token, bool _maximise) public view returns (uint256) {
        return _maximise ? IGmxVault(gmxVault).getMaxPrice(_token) : IGmxVault(gmxVault).getMinPrice(_token);
    }

    function getPosition(
        address _account,
        address _indexToken
    ) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256) {
        return IGmxVault(gmxVault).getPosition(_account, want, _indexToken, false);
    }

    function getFundingFee(address _account, address _indexToken) public view returns (uint256) {
        (uint256 size, , , uint256 entryFundingRate, , , , ) = getPosition(_account, _indexToken);
        return IGmxVault(gmxVault).getFundingFee(want, size, entryFundingRate);
    }

    function getFundingFeeWithRate(
        address _account,
        address _indexToken,
        uint256 _fundingRate
    ) public view returns (uint256) {
        (uint256 size, , , , , , , ) = getPosition(_account, _indexToken);
        return IGmxVault(gmxVault).getFundingFee(want, size, _fundingRate);
    }

    function getLastFundingTime() public view returns (uint256) {
        return IGmxVault(gmxVault).lastFundingTimes(want);
    }

    function getCumulativeFundingRates(address _token) public view returns (uint256) {
        return IGmxVault(gmxVault).cumulativeFundingRates(_token);
    }

    function getLongValue(uint256 _glpAmount) public view returns (uint256) {
        uint256 totalSupply = IERC20(glp).totalSupply();
        uint256 aum = IGlpManager(glpManager).getAum(false);
        return (aum * _glpAmount) / totalSupply;
    }

    function getShortValue(address _account, address _indexToken) public view returns (uint256) {
        IGmxVault _gmxVault = IGmxVault(gmxVault);
        (uint256 size, uint256 collateral, uint256 avgPrice, , , , , ) = getPosition(_account, _indexToken);
        if (size == 0) {
            return 0;
        }
        (bool hasProfit, uint256 pnl) = _gmxVault.getDelta(_indexToken, size, avgPrice, false, 0);
        return hasProfit ? collateral + pnl : collateral - pnl;
    }

    function getMintBurnFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        bool _increment
    ) public view returns (uint256) {
        IGmxVault _gmxVault = IGmxVault(gmxVault);
        uint256 feeBasisPoints = _gmxVault.mintBurnFeeBasisPoints();
        uint256 taxBasisPoints = _gmxVault.taxBasisPoints();
        return IGmxVault(gmxVault).getFeeBasisPoints(_token, _usdgDelta, feeBasisPoints, taxBasisPoints, _increment);
    }

    function totalValue(address _account) public view returns (uint256) {
        uint256 longValue = getLongValue(IERC20(fsGlp).balanceOf(_account));
        uint256 wbtcShortValue = getShortValue(_account, wbtc);
        uint256 wethShortValue = getShortValue(_account, weth);

        return (longValue + wbtcShortValue + wethShortValue);
    }

    function getDelta(address _indexToken, uint256 _size, uint256 _avgPrice) public view returns (bool, uint256) {
        IGmxVault _gmxVault = IGmxVault(gmxVault);
        (bool hasProfit, uint256 pnl) = _gmxVault.getDelta(_indexToken, _size, _avgPrice, false, 0);
        return (hasProfit, pnl);
    }

    function getRedemptionAmount(address _token, uint256 _usdgAmount) public view returns (uint256) {
        return IGmxVault(gmxVault).getRedemptionAmount(_token, _usdgAmount);
    }

    function validateMaxGlobalShortSize(address _indexToken, uint256 _sizeDelta) public view returns (bool) {
        if (_sizeDelta == 0) {
            return true;
        }
        uint256 maxGlobalShortSize = IPositionRouter(positionRouter).maxGlobalShortSizes(_indexToken);
        uint256 globalShortSize = IGmxVault(gmxVault).globalShortSizes(_indexToken);
        return maxGlobalShortSize > (globalShortSize + _sizeDelta);
    }

    function getLeverage(
        address tokenIn,
        uint256 amountIn,
        uint256 sizeDelta,
        bool isLong
    ) public view returns (uint256) {
        IGmxVault _gmxVault = IGmxVault(gmxVault);
        uint256 decimals = _gmxVault.tokenDecimals(tokenIn);

        uint256 price = getPrice(tokenIn, isLong);
        uint256 amountInUsd = (price * amountIn) / (10 ** decimals);
        uint256 leverage = (sizeDelta * BASE_LEVERAGE / amountInUsd);
        return leverage;
    }

    function getSizeDeltaOfBot(
        address bot,
        address tokenIn,
        uint256 amountIn,
        uint256 sizeDelta,
        bool isLong,
        bool isIncrease
    ) public view returns (uint256[] memory) {
        (, uint256 fixedMargin,uint256 positionLimit , , , ) = IBot(bot).getUser();

        address tokenPlay = IBot(bot).getTokenPlay();

        uint256[] memory rets = new uint256[](4);

        IGmxVault _gmxVault = IGmxVault(gmxVault);

        uint256 price = getPriceBySide(tokenIn, isLong, isIncrease);

        uint256 tokenPlayPrice = getPrice(tokenPlay, isLong);

        uint256 leverage = this.getLeverage(tokenIn, amountIn, sizeDelta, isLong);

        rets[0] = leverage;
        rets[1] = fixedMargin;
        rets[2] = positionLimit;
        rets[3] = (fixedMargin * tokenPlayPrice * leverage / BASE_LEVERAGE) / (10 ** _gmxVault.tokenDecimals(tokenPlay)); // sizeDelta

        return rets;
    }

    function getPriceBySide(address token, bool isLong, bool isIncrease) public view returns (uint256 price) {
        if (isIncrease) {
            return isLong ? getPrice(token, true) : getPrice(token, false);
        } else {
            return isLong ? getPrice(token, false) : getPrice(token, true);
        }
    }

    function _validatePositionLimit(
        address _bot,
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _pendingSize,
        bool _isLong
    ) private view {
        (uint256 size, , , , , , , ) = IGmxVault(gmxVault).getPosition(_account, _collateralToken, _indexToken, _isLong);
        (, , uint256 positionLimit, , , ) = IBot(_bot).getUser();
        require(size + _pendingSize <= positionLimit, "Position limit size");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IGlpManager {
    function aumAddition() external view returns (uint256);

    function aumDedection() external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function cooldownDuration() external view returns (uint256);

    function lastAddedAt(address) external view returns (uint256);

    function getAumInUsdg(bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IPositionRouter {
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
    ) external payable;

    function increasePositionRequestKeysStart() external view returns (uint256);
    function decreasePositionRequestKeysStart() external view returns (uint256);
    function maxGlobalShortSizes(address _indexToken) external view returns (uint256);
    function minExecutionFee() external view returns (uint256);
    function setPositionKeeper(address keeper, bool isActive) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRewardTracker {
    function claimable(address _account) external view returns (uint256);
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

    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

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

    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);

    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool, uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IBot {
    function initialize(
        address _tokenPlay,
        address _positionRouter,
        address _vault,
        address _router,
        address _botFactory,
        address _userAddress,
        uint256 _fixedMargin,
        uint256 _positionLimit,
        uint256 _takeProfit,
        uint256 _stopLoss
    ) external;

    function botFactoryCollectToken(uint256 _index) external;

    function getIncreasePositionRequests(uint256 _count) external returns (
        address,
        address,
        bytes32,
        address,
        uint256,
        uint256,
        bool,
        bool
    );

    function getUser() external view returns (
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function getTokenPlay() external view returns (address);
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