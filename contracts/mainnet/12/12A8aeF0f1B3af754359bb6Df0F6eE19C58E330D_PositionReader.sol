// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultUtils.sol";
import "../core/interfaces/IVaultPriceFeedV2.sol";
import "../core/interfaces/IBasePositionManager.sol";
import "../core/VaultMSData.sol";

interface IVaultTarget {
    function vaultUtils() external view returns (address);
}

struct DispPosition {
    address account;
    address collateralToken;
    address indexToken;
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 reserveAmount;
    uint256 lastUpdateTime;
    uint256 aveIncreaseTime;

    uint256 entryFundingRateSec;
    int256 entryPremiumRateSec;

    int256 realisedPnl;

    uint256 stopLossRatio;
    uint256 takeProfitRatio;

    bool isLong;

    bytes32 key;
    uint256 delta;
    bool hasProfit;

    int256 accPremiumFee;
    uint256 accFundingFee;
    uint256 accPositionFee;
    uint256 accCollateral;

    int256 pendingPremiumFee;
    uint256 pendingPositionFee;
    uint256 pendingFundingFee;

    uint256 indexTokenMinPrice;
    uint256 indexTokenMaxPrice;
}


struct DispToken {
    address token;

    //tokenBase part
    bool isFundable;
    bool isStable;
    uint256 decimal;
    uint256 weight;         
    uint256 maxUSDAmounts;  // maxUSDAmounts allows setting a max amount of USDX debt for a token
    uint256 balance;        // tokenBalances is used only to determine _transferIn values
    uint256 poolAmount;     // poolAmounts tracks the number of received tokens that can be used for leverage
    uint256 poolSize;
    uint256 reservedAmount; // reservedAmounts tracks the number of tokens reserved for open leverage positions
    uint256 bufferAmount;   // bufferAmounts allows specification of an amount to exclude from swaps
                            // this can be used to ensure a certain amount of liquidity is available for leverage positions
    uint256 guaranteedUsd;  // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions

    //trec part
    uint256 shortSize;
    uint256 shortCollateral;
    uint256 shortAveragePrice;
    uint256 longSize;
    uint256 longCollateral;
    uint256 longAveragePrice;

    //fee part
    uint256 fundingRatePerSec; //borrow fee & token util
    uint256 fundingRatePerHour; //borrow fee & token util
    uint256 accumulativefundingRateSec;

    int256 longRatePerSec;  //according to position
    int256 shortRatePerSec; //according to position
    int256 longRatePerHour;  //according to position
    int256 shortRatePerHour; //according to position

    int256 accumulativeLongRateSec;
    int256 accumulativeShortRateSec;
    uint256 latestUpdateTime;

    //limit part
    uint256 maxShortSize;
    uint256 maxLongSize;
    uint256 maxTradingSize;
    uint256 maxRatio;
    uint256 countMinSize;

    //
    uint256 spreadBasis;
    uint256 maxSpreadBasis;// = 5000000 * PRICE_PRECISION;
    uint256 minSpreadCalUSD;// = 10000 * PRICE_PRECISION;

}

struct GlobalFeeSetting{
    uint256 taxBasisPoints; // 0.5%
    uint256 stableTaxBasisPoints; // 0.2%
    uint256 mintBurnFeeBasisPoints; // 0.3%
    uint256 swapFeeBasisPoints; // 0.3%
    uint256 stableSwapFeeBasisPoints; // 0.04%
    uint256 marginFeeBasisPoints; // 0.1%
    uint256 liquidationFeeUsd;
    uint256 maxLeverage; // 100x
    //Fees related to funding
    uint256 fundingRateFactor;
    uint256 stableFundingRateFactor;
    //trading tax part
    uint256 taxGradient;
    uint256 taxDuration;
    uint256 taxMax;
    //trading profit limitation part
    uint256 maxProfitRatio;
    uint256 premiumBasisPointsPerHour;
    int256 posIndexMaxPointsPerHour;
    int256 negIndexMaxPointsPerHour;
}


contract PositionReader {
    using SafeMath for uint256;
    address public nativeToken;

    constructor(
        address _nativeToken
    ) {
        nativeToken = _nativeToken;
    }

    function getUserPositions(address _vault, address _account) external view returns (DispPosition[] memory){
        bytes32[] memory _keys = IVault(_vault).getUserKeys(_account, 0, 20);
        
        DispPosition[] memory _dps = new DispPosition[](_keys.length);

        IVaultUtils  vaultUtils = IVaultUtils(IVaultTarget(_vault).vaultUtils());
        for(uint256 i = 0; i < _keys.length; i++){
            VaultMSData.Position memory position = IVault(_vault).getPositionStructByKey(_keys[i]);
            VaultMSData.TradingFee memory tFee = IVault(_vault).getTradingFee(position.indexToken);
            VaultMSData.TradingFee memory tFundFee = IVault(_vault).getTradingFee(position.collateralToken);
            
            (bool _hasProfit, uint256 delta) = vaultUtils.getDelta(position.indexToken, position.size, position.averagePrice, position.isLong, position.aveIncreaseTime, position.collateral);
            _dps[i].account = position.account;
            _dps[i].collateralToken = position.collateralToken;
            _dps[i].indexToken = position.indexToken;
            _dps[i].size = position.size;
            _dps[i].collateral = position.collateral;
            _dps[i].averagePrice = position.averagePrice;
            _dps[i].reserveAmount = position.reserveAmount;
            _dps[i].lastUpdateTime = position.lastUpdateTime;
            _dps[i].aveIncreaseTime = position.aveIncreaseTime;
            _dps[i].entryFundingRateSec = position.entryFundingRateSec;
            _dps[i].entryPremiumRateSec = position.entryPremiumRateSec;
            _dps[i].realisedPnl = position.realisedPnl;
            _dps[i].stopLossRatio = position.stopLossRatio;
            _dps[i].takeProfitRatio = position.takeProfitRatio;
            _dps[i].isLong = position.isLong;
            _dps[i].key = _keys[i];
            _dps[i].hasProfit = _hasProfit;
            _dps[i].delta = delta;

            _dps[i].accPremiumFee = position.accPremiumFee;
            _dps[i].accFundingFee = position.accFundingFee;
            _dps[i].accPositionFee = position.accPositionFee;
            _dps[i].accCollateral = position.accCollateral;

            _dps[i].pendingPremiumFee = vaultUtils.getPremiumFee(position, tFee);
            _dps[i].pendingPositionFee = vaultUtils.getPositionFee(position, position.size, tFee);
            _dps[i].pendingFundingFee = vaultUtils.getFundingFee(position, tFundFee);

            _dps[i].indexTokenMinPrice = IVault(_vault).getMinPrice(position.indexToken);
            _dps[i].indexTokenMaxPrice = IVault(_vault).getMaxPrice(position.indexToken);
        }
        return _dps;
    }


    function getTokenInfo(address _vault, address[] memory _fundTokens) external view returns (DispToken[] memory) {
        IVaultUtils  vaultUtils = IVaultUtils(IVaultTarget(_vault).vaultUtils());
        DispToken[] memory _dispT = new DispToken[](_fundTokens.length);
        IVault vault = IVault(_vault);
        for(uint256 i = 0; i < _dispT.length; i++){
            if (_fundTokens[i] == address(0))
                _fundTokens[i] = nativeToken;

            VaultMSData.TokenBase memory _tBase = vault.getTokenBase(_fundTokens[i]);
            VaultMSData.TradingRec memory _tRec = vault.getTradingRec(_fundTokens[i]);
            VaultMSData.TradingFee memory _tFee = vault.getTradingFee(_fundTokens[i]);

            _dispT[i].token = _fundTokens[i];
            _dispT[i].isFundable = _tBase.isFundable;
            _dispT[i].isStable = _tBase.isStable;
            _dispT[i].decimal = _tBase.decimal;
            _dispT[i].weight = _tBase.weight;  
            _dispT[i].maxUSDAmounts = _tBase.maxUSDAmounts;  
            _dispT[i].balance = _tBase.balance;        
            _dispT[i].poolAmount = _tBase.poolAmount;

            _dispT[i].reservedAmount = _tBase.reservedAmount; 
            _dispT[i].bufferAmount = _tBase.bufferAmount;   
            _dispT[i].guaranteedUsd = IVault(_vault).guaranteedUsd(_fundTokens[i]);  

            _dispT[i].poolSize = vault.tokenToUsdMin(_fundTokens[i], _tBase.poolAmount);
            _dispT[i].poolSize = _dispT[i].poolSize > _dispT[i].guaranteedUsd ? 
                        _dispT[i].poolSize.sub(_dispT[i].guaranteedUsd) : 0;

            //trading rec
            _dispT[i].shortSize = _tRec.shortSize;  
            _dispT[i].shortCollateral = _tRec.shortCollateral;  
            _dispT[i].shortAveragePrice = _tRec.shortAveragePrice;  
            _dispT[i].longSize = _tRec.longSize;  
            _dispT[i].longCollateral = _tRec.longCollateral;  
            _dispT[i].longAveragePrice = _tRec.longAveragePrice;

            //fee part
            _dispT[i].fundingRatePerSec = _tFee.fundingRatePerSec;  
            _dispT[i].fundingRatePerHour = _tFee.fundingRatePerSec.mul(3600).div(10000);  
            _dispT[i].accumulativefundingRateSec = _tFee.accumulativefundingRateSec; 
             
            _dispT[i].longRatePerSec = _tFee.longRatePerSec;  
            _dispT[i].longRatePerHour = _tFee.longRatePerSec * 3600 / 10000;  

            _dispT[i].shortRatePerSec = _tFee.shortRatePerSec;  
            _dispT[i].shortRatePerHour = _tFee.shortRatePerSec * 3600 / 10000;  

            _dispT[i].accumulativeLongRateSec = _tFee.accumulativeLongRateSec;  
            _dispT[i].accumulativeShortRateSec = _tFee.accumulativeShortRateSec;  
            _dispT[i].latestUpdateTime = _tFee.latestUpdateTime;  

            // VaultMSData.TradingTax memory _tTax = vaultUtils.getTradingTax(_fundTokens[i]);
            VaultMSData.TradingLimit memory _tLim = vaultUtils.getTradingLimit(_fundTokens[i]);
            _dispT[i].maxShortSize = _tLim.maxShortSize;  
            _dispT[i].maxLongSize = _tLim.maxLongSize;  
            _dispT[i].maxTradingSize = _tLim.maxTradingSize;  
            _dispT[i].maxRatio = _tLim.maxRatio;  
            _dispT[i].countMinSize = _tLim.countMinSize;

            _dispT[i].spreadBasis = vaultUtils.spreadBasis(_fundTokens[i]);
            _dispT[i].maxSpreadBasis = vaultUtils.maxSpreadBasis(_fundTokens[i]);
            _dispT[i].minSpreadCalUSD = vaultUtils.minSpreadCalUSD(_fundTokens[i]);
        }
        return _dispT;
    }

    function getGlobalFeeInfo(address _vault) external view returns (GlobalFeeSetting memory){//Fees related to swap
        GlobalFeeSetting memory gFS;
        IVaultUtils  vaultUtils = IVaultUtils(IVaultTarget(_vault).vaultUtils());
        gFS.taxBasisPoints = vaultUtils.taxBasisPoints();

        gFS.stableTaxBasisPoints = vaultUtils.stableTaxBasisPoints();
        gFS.mintBurnFeeBasisPoints = vaultUtils.mintBurnFeeBasisPoints();
        gFS.swapFeeBasisPoints = vaultUtils.swapFeeBasisPoints();
        gFS.stableSwapFeeBasisPoints = vaultUtils.stableSwapFeeBasisPoints();

        gFS.marginFeeBasisPoints = vaultUtils.marginFeeBasisPoints();
        gFS.liquidationFeeUsd = vaultUtils.liquidationFeeUsd();
        gFS.maxLeverage = vaultUtils.maxLeverage();
        gFS.fundingRateFactor = vaultUtils.fundingRateFactor();
        gFS.stableFundingRateFactor = vaultUtils.stableFundingRateFactor();
        gFS.taxDuration = vaultUtils.taxDuration();
        gFS.taxMax = vaultUtils.taxMax();
        gFS.taxGradient = gFS.taxDuration > 0 ? gFS.taxMax.div(gFS.taxDuration) : 0;


        gFS.maxProfitRatio = vaultUtils.maxProfitRatio();
        gFS.premiumBasisPointsPerHour = vaultUtils.premiumBasisPointsPerHour();
        gFS.posIndexMaxPointsPerHour = vaultUtils.posIndexMaxPointsPerHour();
        gFS.negIndexMaxPointsPerHour = vaultUtils.negIndexMaxPointsPerHour();
        return gFS;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../DID/interfaces/IESBT.sol";
import "../VaultMSData.sol";

interface IVault {
    function isSwapEnabled() external view returns (bool);
    
    function priceFeed() external view returns (address);
    function usdx() external view returns (address);
    function totalTokenWeights() external view returns (uint256);
    function usdxSupply() external view returns (uint256);
    function usdxAmounts(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function baseMode() external view returns (uint8);

    function approvedRouters(address _router) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);
    function feeSold (address _token)  external view returns (uint256);
    function feeReservesUSD() external view returns (uint256);
    function feeReservesDiscountedUSD() external view returns (uint256);
    function feeReservesRecord(uint256 _day) external view returns (uint256);
    function feeClaimedUSD() external view returns (uint256);
    // function keyOwner(bytes32 _key) external view returns (address);
    // function shortSizes(address _token) external view returns (uint256);
    // function shortCollateral(address _token) external view returns (uint256);
    // function shortAveragePrices(address _token) external view returns (uint256);
    // function longSizes(address _token) external view returns (uint256);
    // function longCollateral(address _token) external view returns (uint256);
    // function longAveragePrices(address _token) external view returns (uint256);
    function globalShortSize( ) external view returns (uint256);
    function globalLongSize( ) external view returns (uint256);


    //---------------------------------------- owner FUNCTIONS --------------------------------------------------
    function setESBT(address _eSBT) external;
    function setVaultStorage(address _vaultStorage) external;
    function setVaultUtils(address _vaultUtils) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setPriceFeed(address _priceFeed) external;
    function setRouter(address _router, bool _status) external;
    function setUsdxAmount(address _token, uint256 _amount, bool _increase) external;
    function setTokenConfig(address _token, uint256 _tokenDecimals, uint256 _tokenWeight, uint256 _maxUSDAmount,
        bool _isStable,  bool _isFundingToken, bool _isTradingToken ) external;
    function clearTokenConfig(address _token) external;
    function updateRate(address _token) external;

    //-------------------------------------------------- FUNCTIONS FOR MANAGER --------------------------------------------------
    function buyUSDX(address _token, address _receiver) external returns (uint256);
    function sellUSDX(address _token, address _receiver, uint256 _usdxAmount) external returns (uint256);
    function claimFeeToken(address _token) external returns (uint256);
    function claimFeeReserves( ) external returns (uint256) ;


    //---------------------------------------- TRADING FUNCTIONS --------------------------------------------------
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;


    //-------------------------------------------------- PUBLIC FUNCTIONS --------------------------------------------------
    function directPoolDeposit(address _token) external;
    function tradingTokenList() external view returns (address[] memory);
    function fundingTokenList() external view returns (address[] memory);
    function claimableFeeReserves( )  external view returns (uint256);
    // function whitelistedTokenCount() external view returns (uint256);
    //fee functions
    // function tokenBalances(address _token) external view returns (uint256);
    // function lastFundingTimes(address _token) external view returns (uint256);
    // function setInManagerMode(bool _inManagerMode) external;
    // function setBufferAmount(address _token, uint256 _amount) external;
    // function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdxAmount) external view returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
    // function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, int256, uint256, uint256, bool, uint256);
    // function getPositionByKey(bytes32 _key) external view returns (uint256, uint256, uint256, int256, uint256, uint256, bool, uint256);
    // function getNextFundingRate(address _token) external view returns (uint256);
    function isFundingToken(address _token) external view returns(bool);
    function isTradingToken(address _token) external view returns(bool);
    function tokenDecimals(address _token) external view returns (uint256);
    function getPositionStructByKey(bytes32 _key) external view returns (VaultMSData.Position memory);
    function getPositionStruct(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (VaultMSData.Position memory);
    function getTokenBase(address _token) external view returns (VaultMSData.TokenBase memory);
    function getTradingFee(address _token) external view returns (VaultMSData.TradingFee memory);
    function getTradingRec(address _token) external view returns (VaultMSData.TradingRec memory);
    function getUserKeys(address _account, uint256 _start, uint256 _end) external view returns (bytes32[] memory);
    function getKeys(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

    // function fundingRateFactor() external view returns (uint256);
    // function stableFundingRateFactor() external view returns (uint256);
    // function cumulativeFundingRates(address _token) external view returns (uint256);
    // // function getFeeBasisPoints(address _token, uint256 _usdxDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);


    // function allWhitelistedTokensLength() external view returns (uint256);
    // function allWhitelistedTokens(uint256) external view returns (address);
    // function whitelistedTokens(address _token) external view returns (bool);
    // function stableTokens(address _token) external view returns (bool);
    // function shortableTokens(address _token) external view returns (bool);
    
    // function globalShortSizes(address _token) external view returns (uint256);
    // function globalShortAveragePrices(address _token) external view returns (uint256);
    // function maxGlobalShortSizes(address _token) external view returns (uint256);
    // function tokenDecimals(address _token) external view returns (uint256);
    // function tokenWeights(address _token) external view returns (uint256);
    // function guaranteedUsd(address _token) external view returns (uint256);
    // function poolAmounts(address _token) external view returns (uint256);
    // function bufferAmounts(address _token) external view returns (uint256);
    // function reservedAmounts(address _token) external view returns (uint256);
    // function maxUSDAmounts(address _token) external view returns (uint256);



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../VaultMSData.sol";

interface IVaultUtils {

    // function validateTokens(uint256 _baseMode, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    
    function setLiquidator(address _liquidator, bool _isActive) external;

    function validateRatioDelta(bytes32 _key, uint256 _lossRatio, uint256 _profitRatio) external view returns (bool);   

    function validateIncreasePosition(address _collateralToken, address _indexToken, uint256 _size, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(VaultMSData.Position memory _position, uint256 _sizeDelta, uint256 _collateralDelta) external view;
    // function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function validateLiquidation(bytes32 _key, bool _raise) external view returns (uint256, uint256, int256);
    function getImpactedPrice(address _token, uint256 _sizeDelta, uint256 _price, bool _isLong) external view returns (uint256);

    function getReserveDelta(address _collateralToken, uint256 _sizeUSD, uint256 _colUSD, uint256 _takeProfitRatio) external view returns (uint256);
    function getInitialPosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong, uint256 _price) external view returns (VaultMSData.Position memory);
    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime, uint256 _colSize) external view returns (bool, uint256);
    function updateRate(address _token) external view returns (VaultMSData.TradingFee memory);
    function getPremiumFee(VaultMSData.Position memory _position, VaultMSData.TradingFee memory _tradingFee) external view returns (int256);
    // function getPremiumFee(address _indexToken, bool _isLong, uint256 _size, int256 _entryPremiumRate) external view returns (int256);
    function getLiqPrice(bytes32 _posKey) external view returns (int256);
    function getPositionFee(VaultMSData.Position memory _position, uint256 _sizeDelta, VaultMSData.TradingFee memory _tradingFee) external view returns (uint256);
    function getFundingFee(VaultMSData.Position memory _position, VaultMSData.TradingFee memory _tradingFee) external view returns (uint256);
    function getBuyUsdxFeeBasisPoints(address _token, uint256 _usdxAmount) external view returns (uint256);
    function getSellUsdxFeeBasisPoints(address _token, uint256 _usdxAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdxAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdxDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
    function getPositionKey(address _account,address _collateralToken, address _indexToken, bool _isLong, uint256 _keyID) external view returns (bytes32);

    function getLatestFundingRatePerSec(address _token) external view returns (uint256);
    function getLatestLSRate(address _token) external view returns (int256, int256);

    // function addPosition(bytes32 _key,address _account, address _collateralToken, address _indexToken, bool _isLong) external;
    // function removePosition(bytes32 _key) external;
    // function getDiscountedFee(address _account, uint256 _origFee, address _token) external view returns (uint256);
    // function getSwapDiscountedFee(address _user, uint256 _origFee, address _token) external view returns (uint256);
    // function uploadFeeRecord(address _user, uint256 _feeOrig, uint256 _feeDiscounted, address _token) external;

    function MAX_FEE_BASIS_POINTS() external view returns (uint256);
    function MAX_LIQUIDATION_FEE_USD() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);
    function maxLeverage() external view returns (uint256);
    function setMaxLeverage(uint256 _maxLeverage) external;

    function errors(uint256) external view returns (string memory);

    function spreadBasis(address) external view returns (uint256);
    function maxSpreadBasis(address) external view returns (uint256);
    function minSpreadCalUSD(address) external view returns (uint256);
    function premiumBasisPointsPerHour() external view returns (uint256);
    function negIndexMaxPointsPerHour() external view returns (int256);
    function posIndexMaxPointsPerHour() external view returns (int256);

    function maxGlobalShortSizes(address) external view returns (uint256);
    function maxGlobalLongSizes(address) external view returns (uint256);

    // function getNextAveragePrice(bytes32 _key, address _indexToken, uint256 _size, uint256 _averagePrice,
        // bool _isLong, uint256 _nextPrice, uint256 _sizeDelta, uint256 _lastIncreasedTime ) external view returns (uint256);
    // function getNextAveragePrice(bytes32 _key, bool _isLong, uint256 _price,uint256 _sizeDelta) external view returns (uint256);           
    function getNextIncreaseTime(uint256 _prev, uint256 _prev_size,uint256 _sizeDelta) external view returns (uint256);          
    // function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool, uint256);
    function calculateTax(uint256 _profit, uint256 _aveIncreaseTime) external view returns(uint256);    
    function getPositionNextAveragePrice(uint256 _size, uint256 _averagePrice, uint256 _nextPrice, uint256 _sizeDelta, bool _isIncrease) external pure returns (uint256);

    function getNextAveragePrice(uint256 _size, uint256 _averagePrice,  uint256 _nextPrice, uint256 _sizeDelta, bool _isIncrease) external pure returns (uint256);
    // function getDecreaseNextAveragePrice(uint256 _size, uint256 _averagePrice,  uint256 _nextPrice, uint256 _sizeDelta ) external pure returns (uint256);
    // function getPositionNextAveragePrice(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _nextPrice, uint256 _sizeDelta, uint256 _lastIncreasedTime) external pure returns (uint256);
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
    
    function getTradingTax(address _token) external view returns (VaultMSData.TradingTax memory);
    function getTradingLimit(address _token) external view returns (VaultMSData.TradingLimit memory);
    function tokenUtilization(address _token) external view returns (uint256);
    function getTargetUsdxAmount(address _token) external view returns (uint256);
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function inPrivateLiquidationMode() external view returns (bool);
    function validLiq(address _account) external view;
    function setOnlyRouterSwap(bool _onlyRS) external;
    function onlyRouterSwap() external view returns (bool);


    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function maxProfitRatio() external view returns (uint256);

    function taxDuration() external view returns (uint256);
    function taxMax() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVaultPriceFeedV2 {
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
    function getPrice(address _token, bool _maximise,bool,bool) external view returns (uint256);
    function getOrigPrice(address _token) external view returns (uint256);
    
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256, bool);
    function setTokenChainlink( address _token, address _chainlinkContract) external;
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;

    function priceVariancePer1Million(address _token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBasePositionManager {
    function maxGlobalLongSizes(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";

library VaultMSData {
    // bytes32 public constant opeProtectIdx = keccak256("opeProtectIdx");
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableValues for EnumerableSet.UintSet;

    uint256 constant COM_RATE_PRECISION = 10**4; //for common rate(leverage, etc.) and hourly rate
    uint256 constant HOUR_RATE_PRECISION = 10**6; //for common rate(leverage, etc.) and hourly rate
    uint256 constant PRC_RATE_PRECISION = 10**10;   //for precise rate  secondly rate
    uint256 constant PRICE_PRECISION = 10**30;

    struct Position {
        address account;
        address collateralToken;
        address indexToken;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 reserveAmount;
        uint256 lastUpdateTime;
        uint256 aveIncreaseTime;


        uint256 entryFundingRateSec;
        int256 entryPremiumRateSec;

        int256 realisedPnl;

        uint256 stopLossRatio;
        uint256 takeProfitRatio;

        bool isLong;

        int256 accPremiumFee;
        uint256 accFundingFee;
        uint256 accPositionFee;
        uint256 accCollateral;
    }


    struct TokenBase {
        //Setable parts
        bool isFundable;
        bool isStable;
        uint256 decimal;
        uint256 weight;  //tokenWeights allows customisation of index composition
        uint256 maxUSDAmounts;  // maxUSDAmounts allows setting a max amount of USDX debt for a token

        //Record only
        uint256 balance;        // tokenBalances is used only to determine _transferIn values
        uint256 poolAmount;     // poolAmounts tracks the number of received tokens that can be used for leverage
                                // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
        uint256 reservedAmount; // reservedAmounts tracks the number of tokens reserved for open leverage positions
        uint256 bufferAmount;   // bufferAmounts allows specification of an amount to exclude from swaps
                                // this can be used to ensure a certain amount of liquidity is available for leverage positions
    }


    struct TradingFee {
        uint256 fundingRatePerSec; //borrow fee & token util

        uint256 accumulativefundingRateSec;

        int256 longRatePerSec;  //according to position
        int256 shortRatePerSec; //according to position
        int256 accumulativeLongRateSec;
        int256 accumulativeShortRateSec;

        uint256 latestUpdateTime;
        // uint256 lastFundingTimes;     // lastFundingTimes tracks the last time funding was updated for a token
        // uint256 cumulativeFundingRates;// cumulativeFundingRates tracks the funding rates based on utilization
        // uint256 cumulativeLongFundingRates;
        // uint256 cumulativeShortFundingRates;
    }

    struct TradingTax {
        uint256 taxMax;
        uint256 taxDuration;
        uint256 k;
    }

    struct TradingLimit {
        uint256 maxShortSize;
        uint256 maxLongSize;
        uint256 maxTradingSize;

        uint256 maxRatio;
        uint256 countMinSize;
        //Price Impact
    }


    struct TradingRec {
        uint256 shortSize;
        uint256 shortCollateral;
        uint256 shortAveragePrice;
        uint256 longSize;
        uint256 longCollateral;
        uint256 longAveragePrice;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IESBT {
    // function updateIncreaseLogForAccount(address _account, address _collateralToken, 
            // uint256 _collateralSize,uint256 _positionSize, bool /*_isLong*/ ) external returns (bool);

    function scorePara(uint256 _paraId) external view returns (uint256);
    function createTime(address _account) external view returns (uint256);
    // function tradingKey(address _account, bytes32 key) external view returns (bytes32);
    function nickName(address _account) external view returns (string memory);


    function getReferralForAccount(address _account) external view returns (address[] memory , address[] memory);
    function userSizeSum(address _account) external view returns (uint256);
    // function updateFeeDiscount(address _account, uint256 _discount, uint256 _rebate) external;
    function updateFee(address _account, uint256 _origFee) external returns (uint256);
    // function calFeeDiscount(address _account, uint256 _amount) external view returns (uint256);

    function getESBTAddMpUintetRoles(address _mpaddress, bytes32 _key) external view returns (uint256[] memory);
    function updateClaimVal(address _account) external ;
    function userClaimable(address _account) external view returns (uint256, uint256);

    // function updateScoreForAccount(address _account, uint256 _USDamount, uint16 _opeType) external;
    function updateScoreForAccount(address _account, address /*_vault*/, uint256 _amount, uint256 _reasonCode) external;
    function updateTradingScoreForAccount(address _account, address _vault, uint256 _amount, uint256 _refCode) external;
    function updateSwapScoreForAccount(address _account, address _vault, uint256 _amount) external;
    function updateAddLiqScoreForAccount(address _account, address _vault, uint256 _amount, uint256 _refCode) external;
    // function updateStakeEDEScoreForAccount(address _account, uint256 _amount) external ;
    function getScore(address _account) external view returns (uint256);
    function getRefCode(address _account) external view returns (string memory);
    function accountToDisReb(address _account) external view returns (uint256, uint256);
    function rank(address _account) external view returns (uint256);
    function addressToTokenID(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function valuesAt(EnumerableSet.Bytes32Set storage set, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }


    function valuesAt(EnumerableSet.UintSet storage set, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        uint256 max = set.length();
        if (end > max) { end = max; }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }
}