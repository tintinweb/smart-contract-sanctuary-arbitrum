/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// File: contracts/Pool/interfaces/IPoolSettings.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IPoolSettings {

    struct param {
        uint256 _rebaseThresholdRatio;
        uint256 _rebaseBlock;
        uint256 _assetLevel;
        uint256 _priceThreshold;
        uint256 _marginRatio;
        uint256 _liqRewardRatio;
        uint256 _closeRatio;
        uint256 _baseLiquidity;
        uint256 _liquidityMoveTime;
        uint256 _liquidityMoveRatio;
    }

    struct poolParam {
        uint256 _priceShockRatio;
        uint256 _priceEffectiveTime;
    }

    function eventOut() external view returns (address);
    function getOraclePriceV2(address poolAddress) external view returns (uint256 ,uint80 ); 
    function getPrice(address poolAddress,address assetAddress,uint256 increasePosition,uint8 direction) external view returns (uint256 priceFuture,bool canAction);    //判断是否爆仓
    function checkliquidation(address poolAddress,address assetAddress,uint256 margin,uint256 transferOut) external view returns (bool isLiquidity);
    function getLiqReward(address poolAddress,address assetAddress,uint256 margin) external view returns(uint256 liqReward);
    function getRebaseFee(address poolAddress,address assetAddress) external returns (int256 rebaseFeeLong,int256 rebaseShort);
    function getCloseFee(address poolAddress,address assetAddress,uint256 position) external view returns (uint256 closeFee);
    function checkOpenPosition(address poolAddress,address assetAddress,uint16 level,uint256 position) external view returns (bool);

    function getPriceDiffRatio(address poolAddress,address assetAddress) external view returns(uint256 diffRatio,uint256 priceThreshold);
    function getLiquidity(address poolAddress,address assetAddress) external view returns (uint256 resultLiquidity);
    function InitPool(address asset,address pool) external;
    function setLegalLevel(address asset,address pool,uint256 level) external;
    function removeLegalLevel(address asset,address pool,uint256 level) external;
}

// File: contracts/Pool/interfaces/IPool.sol

pragma solidity 0.8.1;
interface IPool {
    struct PriceParam {
        address oracle;
        bool reserve;
        address rate;
    }
    struct Position {
        address sender;
        uint256 openPrice;
        uint256 openBlock;
        uint256 margin;
        uint256 size;
        uint8 direction;
        uint16 leverage;
        int256 openRebase;
    }

    struct SizeInfo {
        uint256 totalSizeLong;
        uint256 totalSizeShort;
        uint256 totalPositionLong;
        uint256 totalPositionShort;
    }

    struct RebaseInfo{
        int256  rebaseLongValue;
        int256  rebaseShortValue;
        uint256 lastBlockHeight;
    }

    struct LiquidityInfo {
        uint256 lastLiquidity;
        uint256 lastBlockTime;
    }

    struct PriceInfo {
        uint256 lastPrice;
        uint256 price;
        uint256 lastBlockTime;
    }
    struct OpenParam {
        uint8 direction;
        uint16 leverage;
    }

    function _positions(uint32 positionId)
    external
    view
    returns (
        address sender,
        uint256 openPrice,
        uint256 openBlock,
        uint256 margin,
        uint256 size,
        uint8 direction,
        uint16 leverage,
        int256 openRebase
    );

    function _sizeInfo(address tokenAddress)
    external
    view
    returns (
        uint256 totalSizeLong,
        uint256 totalSizeShort,
        uint256 totalPositionLong,
        uint256 totalPositionShort
    );

    function _rebaseInfo(address tokenAddress)
    external
    view
    returns (
        int256  rebaseLongValue,
        int256  rebaseShortValue,
        uint256 lastBlockHeight
    );

    function _lastLiquidity(address tokenAddress)
    external
    view
    returns (
        uint256 lastLiquidity,
        uint256 lastBlockTime
    );

    function _lastPrice() external
    view
    returns (
        uint256 lastPrice,
        uint256 price,
        uint256 lastBlockTime
    );

    function openPosition(
        bytes calldata openParam,
        uint256 position
    ) external returns (uint32);

    function addMargin(
        uint32 positionId,
        uint256 margin
    ) external;

    function closePosition(
        uint32 positionId
    ) external returns (uint256 transferOut,uint256 fee,int256 fundingFee);

    function liquidate(
        uint32 positionId
    ) external returns (uint256 liqReward,uint256 fee,int256 fundingFee);

    function exit(
        uint32 positionId
    ) external returns (uint256 liqReward,uint256 fee,int256 fundingFee);

    function getPriceParam() external view returns (PriceParam memory) ;
    function _setting() external view returns (address);

}

// File: contracts/Asset/interfaces/IAsset.sol

pragma solidity 0.8.1;
interface IAsset {
    struct Position {
        address poolAddress;
        uint32 positionId;
        address userAddress;
    }

    struct AmountIn{
        uint256 amount;
        uint32 payType;
        address payerAddress;
    }
    struct RemoveInfo {
        address owner;
        address receipt;
        uint256 lpAmount;
        uint32  outEpoch;
        uint32  epoch;
    }
    struct EpochInfo {
        uint256 lpAmount;
        uint256 tokenAmount;
        uint256 beginTime;
    }

    function addLiquidity(address receipt,AmountIn calldata amountIn) external;
    function removeLiquidity(uint32 removeIndex) external;
    function openPosition(address poolAddress,AmountIn calldata amountIn,bytes calldata openParam) external returns (uint32);
    function addMargin(uint32 positionId,AmountIn calldata amountIn) external;
    function closePosition(uint32 positionId,address receipt) external;
    function liquidity(uint32 positionId,address receipt) external;
    function exitPosition(uint32 positionId,address receipt) external;

    function _liquidityPool() external view returns(uint256);
    function _precisionDiff() external view returns(uint256);
    function _currentEpoch() external view returns(uint32);

    function applyRemove(address receipt,AmountIn calldata amountIn) external;
    function cancleApplyRemove(uint32 removeIndex) external;

}

// File: contracts/interfaces/IPrice.sol

pragma solidity 0.8.1;
interface IPrice {
    function getPrice(address oracleAddress,bool reserve) external view  returns (uint256 price);
}

// File: contracts/interfaces/IPriceV2.sol

pragma solidity 0.8.1;
interface IPriceV2 {
    function getPrice(address oracleAddress,bool reserve) external view  returns (uint256 price);
    function getPriceWithTime(address oracleAddress,bool reserve) external view returns(uint256,uint80,uint256);
    function getPriceWithRoundId(address oracleAddress,bool reserve,uint80 roundId_) external view returns(uint256,uint80,uint256);
}

// File: contracts/interfaces/IEventOut.sol

pragma solidity 0.8.1;

interface IEventOut {
    event OutEvent(
        address indexed sender,
        uint32 itype,
        bytes bvalue
    );

    function eventOut(uint32 _type,bytes memory _value) external ;
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/libraries/ArbBlockNumber.sol

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);
}

library ArbBlockNumber {
    function getArbBlockNumber() internal view returns (uint256) {
        // return block.number;
        return ArbSys(address(100)).arbBlockNumber();
    }
}

// File: contracts/libraries/BasicMaths.sol

pragma solidity 0.8.1;

library BasicMaths {
    /**
     * @dev Returns the abs of substraction of two unsigned integers
     *
     * _Available since v3.4._
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    /**
     * @dev Returns a - b if a > b, else return 0
     *
     * _Available since v3.4._
     */
    function sub2Zero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    /**
     * @dev if isSub then Returns a - b, else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            return SafeMath.sub(a, b);
        }
    }

    /**
     * @dev if isSub then Returns sub2Zero(a, b), else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub2Zero(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            if (a > b) {
                return a - b;
            } else {
                return 0;
            }
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1 ) / 2;
        uint256 y = x;
        while(z < y){
            y = z;
            z = ( x / z + z ) / 2;
        }
        return y;
    }

    function pow(uint256 x) internal pure returns (uint256) {
        return SafeMath.mul(x, x);
    }

    function diff2(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a >= b) {
            return (true, a - b);
        } else {
            return (false, b - a);
        }
    }

}

// File: contracts/libraries/Price.sol

pragma solidity 0.8.1;


library Price {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;

    uint256 private constant E18 = 1e18;

    function lsTokenPrice(uint256 totalSupply, uint256 liquidityPool)
        internal
        pure
        returns (uint256)
    {
        if (totalSupply == 0 || liquidityPool == 0) {
            return E18;
        }

        return liquidityPool.mul(E18) / totalSupply;
    }

    function lsTokenByPoolToken(
        uint256 totalSupply,
        uint256 liquidityPool,
        uint256 poolToken
    ) internal pure returns (uint256) {
        return poolToken.mul(E18) / lsTokenPrice(totalSupply, liquidityPool);
    }

    function poolTokenByLsTokenWithDebt(
        uint256 totalSupply,
        uint256 bondsLeft,
        uint256 liquidityPool,
        uint256 lsToken
    ) internal pure returns (uint256) {
        require(liquidityPool > bondsLeft, "debt scale over pool assets");
        return lsToken.mul(lsTokenPrice(totalSupply, liquidityPool.sub(bondsLeft))) / E18;
    }

    function calLsAvgPrice(
        uint256 lsAvgPrice,
        uint256 lsTotalSupply,
        uint256 amount,
        uint256 lsTokenAmount
    ) internal pure returns (uint256) {
        return lsAvgPrice.mul(lsTotalSupply).add(amount.mul(E18)) / lsTotalSupply.add(lsTokenAmount);
    }

    function divPrice(uint256 value, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return value.mul(E18) / price;
    }

    function mulPrice(uint256 size, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return size.mul(price) / E18;
    }

    function calFundingFee(uint256 rebaseSize, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return mulPrice(rebaseSize.div(E18), price);
    }

    function calDeviationPrice(uint256 deviation, uint256 price, uint8 direction)
        internal
        pure
        returns (uint256)
    {
        if (direction == 1) {
            return price.add(price.mul(deviation) / E18);
        }

        return price.sub(price.mul(deviation) / E18);
    }

    function calRepay(int256 debtChange)
        internal
        pure
        returns (uint256)
    {
        return debtChange < 0 ? uint256(-debtChange): 0;
    }
}

// File: contracts/Pool/PoolSetting.sol

pragma solidity 0.8.1;

contract PoolSettings is IPoolSettings,Ownable {
    using SafeMath for uint256;

    address public _factory;
    address public _eventOut;
    param public _defaultParam;
    poolParam public _defaultPoolParam;

    mapping(address =>mapping(address =>param)) public _poolAssetParam;
    mapping(address =>mapping(address =>mapping(uint256=>bool))) public _legalLevel;
    mapping(address => poolParam) public _poolParam;

    modifier onlyFactory() {
        require(_factory == msg.sender || owner() == msg.sender,"only factory or Owner can set");
        _;
    }

    function setEventOut(address eventOut_) public onlyOwner {
        _eventOut = eventOut_;
    }

    function setFactory(address factory_) public onlyOwner {
        _factory = factory_;
        bytes memory data = abi.encode(factory_);
        eventOut(1,data);
    }

    function setDefaultParam(param memory defaultParam_) public onlyOwner {
        _defaultParam = defaultParam_;
        bytes memory data = abi.encode(address(0),address(0),_defaultParam._rebaseThresholdRatio,
        _defaultParam._rebaseBlock,_defaultParam._assetLevel,_defaultParam._priceThreshold,_defaultParam._marginRatio,_defaultParam._liqRewardRatio,_defaultParam._closeRatio,_defaultParam._baseLiquidity,_defaultParam._liquidityMoveTime,_defaultParam._liquidityMoveRatio);
        eventOut(10,data);
    }

    function setDefaultPoolParam(poolParam memory defaultPoolParam_) public onlyOwner {
        _defaultPoolParam = defaultPoolParam_;
        bytes memory data = abi.encode(address(0),_defaultPoolParam._priceShockRatio,_defaultPoolParam._priceEffectiveTime);
        eventOut(11,data);

    }

    function InitPool(address asset,address pool) external override onlyFactory {
        _poolAssetParam[asset][pool] = _defaultParam;
        _poolParam[pool] = _defaultPoolParam;

        bytes memory data = abi.encode(asset,pool,_defaultParam._rebaseThresholdRatio,
        _defaultParam._rebaseBlock,_defaultParam._assetLevel,_defaultParam._priceThreshold,_defaultParam._marginRatio,_defaultParam._liqRewardRatio,_defaultParam._closeRatio,_defaultParam._baseLiquidity,_defaultParam._liquidityMoveTime,_defaultParam._liquidityMoveRatio);
        eventOut(10,data);
        data = abi.encode(pool,_defaultPoolParam._priceShockRatio,_defaultPoolParam._priceEffectiveTime);
        eventOut(11,data);
    }

    function setPoolAssetParam(address asset,address pool,param memory poolParam_) public onlyOwner {
        _poolAssetParam[asset][pool] = poolParam_;
        bytes memory data = abi.encode(asset,pool,poolParam_._rebaseThresholdRatio,
        poolParam_._rebaseBlock,poolParam_._assetLevel,poolParam_._priceThreshold,poolParam_._marginRatio,poolParam_._liqRewardRatio,poolParam_._closeRatio,poolParam_._baseLiquidity,poolParam_._liquidityMoveTime,poolParam_._liquidityMoveRatio);
        eventOut(10,data);
    }

    function setPoolParam(address pool,poolParam memory defaultPoolParam_) public onlyOwner {
        _poolParam[pool] = defaultPoolParam_;
        bytes memory data = abi.encode(pool,defaultPoolParam_._priceShockRatio,defaultPoolParam_._priceEffectiveTime);
        eventOut(11,data);
    }

    function setLegalLevel(address asset,address pool,uint256 level) external override onlyFactory {
        _legalLevel[asset][pool][level] = true;
        bytes memory data = abi.encode(asset,pool,level,true);
        eventOut(100,data);
    }

    function removeLegalLevel(address asset,address pool,uint256 level) external override onlyFactory {
        _legalLevel[asset][pool][level] = false;
        bytes memory data = abi.encode(asset,pool,level,false);
        eventOut(100,data);
    }

    function eventOut() external override view returns (address) {
        return _eventOut;
    }

    function getPriceOffset(uint256 price,uint256 lastPrice,address poolAddress,uint256 lastBlockTime) internal view returns(uint256) {
        uint256 priceDiff = price > lastPrice ? price.sub(lastPrice):lastPrice.sub(price);
        priceDiff = priceDiff.mul(block.timestamp.sub(lastBlockTime)).div(_poolParam[poolAddress]._priceEffectiveTime);
        if (price > lastPrice) {
            return lastPrice.add(priceDiff);
        }
        return lastPrice.sub(priceDiff);
    }
    function getPrePrice(uint256 price,uint80 roundId,address poolAddress,uint256 lastPrice) internal view returns(uint256,uint80) {
        IPool.PriceParam memory pp = IPool(poolAddress).getPriceParam();
        (uint256 prePrice,uint80 preRoundId,) = IPriceV2(pp.rate).getPriceWithRoundId(pp.oracle,pp.reserve,roundId - 1);

        if ((price > lastPrice) && (price > prePrice)) {
            return (prePrice,preRoundId);
        }

        if ((price < lastPrice) && (price < prePrice)) {
            return (prePrice,preRoundId);
        }

        return (price,roundId);

    }
    function getOraclePriceV2(address poolAddress) external override view returns (uint256 ,uint80 ) {
        IPool.PriceParam memory pp = IPool(poolAddress).getPriceParam();
        (uint256 price,uint80 roundID,) = IPriceV2(pp.rate).getPriceWithTime(pp.oracle,pp.reserve);
        (,uint256 lastPrice,uint256 lastBlockTime) = IPool(poolAddress)._lastPrice();

        if (lastBlockTime == 0) {
            return (price,roundID);
        }
        if (block.timestamp.sub(lastBlockTime) < _poolParam[poolAddress]._priceEffectiveTime) {//300是否需要定制一下？
            return (getPriceOffset(price,lastPrice,poolAddress,lastBlockTime),roundID);
        } 
        return getPrePrice(price,roundID,poolAddress,lastPrice);
    }

    function getLiquidity(address poolAddress,address assetAddress) external override view returns (uint256 resultLiquidity) {
        uint256 assetLiquidity = IAsset(assetAddress)._liquidityPool().mul(IAsset(assetAddress)._precisionDiff());
        (uint256 lastLiquidity,uint256 lastBlockTime) = IPool(poolAddress)._lastLiquidity(assetAddress);
        if (block.timestamp == lastBlockTime) {
            return lastLiquidity;
        }

        if (lastBlockTime == 0) {
            return assetLiquidity;
        }
        
        uint256 priceDiffRatio = getPriceDiffRatioInternal(poolAddress,assetAddress);
        if (priceDiffRatio == 0) {
            return assetLiquidity;
        } else {
            uint256 moveRatio = _poolAssetParam[assetAddress][poolAddress]._liquidityMoveRatio.mul(_poolAssetParam[assetAddress][poolAddress]._priceThreshold);
            moveRatio = moveRatio.mul(block.timestamp.sub(lastBlockTime));
            moveRatio = moveRatio.div(_poolAssetParam[assetAddress][poolAddress]._liquidityMoveTime);
            moveRatio = moveRatio.div(priceDiffRatio);

            uint256 tempLiquidity = lastLiquidity > _poolAssetParam[assetAddress][poolAddress]._baseLiquidity ? lastLiquidity : _poolAssetParam[assetAddress][poolAddress]._baseLiquidity;
            tempLiquidity = tempLiquidity.mul(moveRatio).div(1e4);

            if ((tempLiquidity > lastLiquidity) && (assetLiquidity <= lastLiquidity)) {
                resultLiquidity = assetLiquidity;
            } else {
                resultLiquidity = assetLiquidity > lastLiquidity ? tempLiquidity.add(lastLiquidity):lastLiquidity.sub(tempLiquidity);
            }

        }

        if ((resultLiquidity > assetLiquidity && resultLiquidity > lastLiquidity) || (resultLiquidity < assetLiquidity && resultLiquidity < lastLiquidity)) {
            resultLiquidity = assetLiquidity;
        }
        return resultLiquidity;
    }

    function getPriceDiffRatioInternal(address poolAddress,address assetAddress) internal view returns(uint256) {
        (,uint256 priceOracle,) = IPool(poolAddress)._lastPrice();
        if (priceOracle == 0) {
            return 0;
        }
        uint256 priceFuture = getPrice_(poolAddress,assetAddress,0,1);
        uint256 priceDiff = priceFuture > priceOracle ? priceFuture.sub(priceOracle) : priceOracle.sub(priceFuture);
        return priceDiff.mul(1e4).div(priceOracle);
    }

    function getOraclePrice(address poolAddress) internal view returns (uint256) {
        IPool.PriceParam memory pp = IPool(poolAddress).getPriceParam();
        return IPrice(pp.rate).getPrice(pp.oracle,pp.reserve);
    }
    function priceChoose(address poolAddress,address assetAddress,uint256 priceFuture,uint8 direction) internal view returns (uint256 price,bool canAction) {
        (uint256 pricePre,uint256 priceOracle,) = IPool(poolAddress)._lastPrice();
        if (pricePre == 0) {
            return (priceFuture,true);
        }
        uint256 priceShock = priceOracle.mul(_poolAssetParam[assetAddress][poolAddress]._priceThreshold).div(1e4);
        uint256 priceShockX = priceShock.mul(_poolParam[poolAddress]._priceShockRatio).div(1e4);
        canAction = true;
        if (priceFuture > priceOracle) {
            if (priceFuture > priceOracle.add(priceShockX) && direction == 3) {
                canAction = false;
            }

            if (priceFuture > priceOracle.add(priceShock) && direction == 1) {
                canAction = false;
            }
        } else {
            if (priceFuture < priceOracle.sub(priceShockX) && direction == 4) {
                canAction = false;
            }

            if (priceFuture < priceOracle.sub(priceShock) && direction == 2) {
                canAction = false;
            }
        }
        uint256 priceStandard;
         IPool.PriceParam memory pp = IPool(poolAddress).getPriceParam();
        (uint256 pc,,) = IPriceV2(pp.rate).getPriceWithTime(pp.oracle,pp.reserve);

        if (priceOracle < pc) {
            if  (direction == 1 || direction == 4) {
                price = priceFuture > pc?priceFuture:pc;
            } else {
                priceStandard = priceOracle.mul(_poolAssetParam[assetAddress][poolAddress]._priceThreshold);
                priceOracle = priceOracle.mul(1e4);
                priceStandard = priceStandard.add(priceOracle);
                priceStandard = priceStandard.div(1e4);
                price = priceFuture < priceStandard?priceFuture:priceStandard;
            }
        } else {
            if (direction == 2 || direction == 3) {
                price = priceFuture < pc?priceFuture:pc;
            } else {
                priceStandard = priceOracle.mul(_poolAssetParam[assetAddress][poolAddress]._priceThreshold);
                priceOracle = priceOracle.mul(1e4);
                priceStandard = priceOracle.sub(priceStandard);
                priceStandard = priceStandard.div(1e4);
                price = priceFuture > priceStandard?priceFuture:priceStandard;
            }
        }
        return  (price,canAction);

    }

    function getPrice_(address poolAddress,address assetAddress,uint256 increasePosition,uint8 direction) internal view returns (uint256 priceFuture) {
        require(_poolAssetParam[assetAddress][poolAddress]._assetLevel != 0,"error 1");
        (uint256 liquidity,) = IPool(poolAddress)._lastLiquidity(assetAddress);
        liquidity = liquidity.mul(_poolAssetParam[assetAddress][poolAddress]._assetLevel);
        require(liquidity != 0,"error 2");

        (,,uint256 positionLong,uint256 positionShort) = IPool(poolAddress)._sizeInfo(assetAddress);
        if (direction == 1) {
            positionLong = positionLong.add(increasePosition);
        }
        else if (direction == 2) {
            positionShort = positionShort.add(increasePosition);
        } else if (direction == 3) {
            positionLong = positionLong.sub(increasePosition);
        } else {
            positionShort = positionShort.sub(increasePosition);
        }
        (,uint256 priceOracle,) = IPool(poolAddress)._lastPrice();
        uint256 VY = liquidity.div(2).add(positionLong).mul(priceOracle).div(1e18);
        uint256 VX = liquidity.div(2).add(positionShort);

        return VY.mul(1e18).div(VX,"VX");

    }

    function getPriceDiffRatio(address poolAddress,address assetAddress) external override view returns(uint256 diffRatio,uint256 priceThreshold) {
        return (getPriceDiffRatioInternal(poolAddress,assetAddress),_poolAssetParam[assetAddress][poolAddress]._priceThreshold);
    }

    function getFuttPrice(address poolAddress,address assetAddress,uint256 increasePosition,uint8 direction) public view returns(uint256) {
        return getPrice_(poolAddress,assetAddress,increasePosition,direction);
    }

    function getChoosePrice(address poolAddress,address assetAddress,uint256 futurePrice,uint8 direction) public view returns(uint256,bool) {
        return priceChoose(poolAddress,assetAddress,futurePrice,direction);
    }

    function getPrice(address poolAddress,address assetAddress,uint256 increasePosition,uint8 direction) external view override returns (uint256 priceFuture,bool canAction) {
        priceFuture = getPrice_(poolAddress,assetAddress,increasePosition,direction);
        return priceChoose(poolAddress,assetAddress,priceFuture,direction);
    }   
    function checkliquidation(address poolAddress,address assetAddress,uint256 margin,uint256 transferOut) external override view returns (bool isLiquidity) {
        uint256 marginRatio = _poolAssetParam[assetAddress][poolAddress]._marginRatio;
        return margin.mul(marginRatio).div(1e4) > transferOut;
    }
    function getRebaseSize(address poolAddress,address assetAddress) internal view returns(uint256 rebaseSize) {
        (uint256 sizeLong,uint256 sizeShort,,) = IPool(poolAddress)._sizeInfo(assetAddress);
        uint256 _liquidityPool = IAsset(assetAddress)._liquidityPool();
        uint256 currentPrice = getPrice_(poolAddress,assetAddress,0,1);
        uint256 rebaseDiff = sizeLong > sizeShort ? sizeLong.sub(sizeShort) : sizeShort.sub(sizeLong);
        if (Price.mulPrice(rebaseDiff,currentPrice) < _liquidityPool.mul(_poolAssetParam[assetAddress][poolAddress]._rebaseThresholdRatio).div(1e4)) {
            return 0;
        }

        rebaseSize = rebaseDiff.sub(
            Price
                .divPrice(
                    _liquidityPool.mul(_poolAssetParam[assetAddress][poolAddress]._rebaseThresholdRatio).div(1e4),
                    currentPrice
                )
        );
    }

    function getRebaseFee(address poolAddress,address assetAddress) external view override returns (int256 rebaseFeeLong,int256 rebaseFeeShort) {
        (uint256 sizeLong,uint256 sizeShort,,) = IPool(poolAddress)._sizeInfo(assetAddress);
        uint256 rebaseSize = getRebaseSize(poolAddress,assetAddress);
        if (rebaseSize == 0) {
            return (0,0);
        }
        (,,uint256 lastBlockHeight) = IPool(poolAddress)._rebaseInfo(assetAddress);

        if (sizeLong > sizeShort) {
            rebaseFeeLong = (int256)(rebaseSize.mul(ArbBlockNumber.getArbBlockNumber().sub(lastBlockHeight,"blockHeight")).mul(1e18).div(_poolAssetParam[assetAddress][poolAddress]._rebaseBlock,"rebaseBlock").div(sizeLong,"sizeLong"));
            rebaseFeeShort = -rebaseFeeLong;
        } else {
            rebaseFeeShort = (int256)(rebaseSize.mul(ArbBlockNumber.getArbBlockNumber().sub(lastBlockHeight,"blockHeight")).mul(1e18).div(_poolAssetParam[assetAddress][poolAddress]._rebaseBlock,"rebaseBlock").div(sizeShort,"sizeShort"));
            rebaseFeeLong = -rebaseFeeShort;
        }
    }

    function getCloseFee(address poolAddress,address assetAddress,uint256 position) external override view returns (uint256 closeFee) {
        return position.mul(_poolAssetParam[assetAddress][poolAddress]._closeRatio).div(1e4);
    }

    function getLiqReward(address poolAddress,address assetAddress,uint256 margin) external override view returns(uint256 liqReward) {
        return margin.mul(_poolAssetParam[assetAddress][poolAddress]._liqRewardRatio).div(1e4);
    }

    function checkOpenPosition(address poolAddress,address assetAddress,uint16 level,uint256 position) external override view returns (bool) {
        return _legalLevel[assetAddress][poolAddress][level] && position > 0;
    }

    function eventOut(uint32 _type,bytes memory _value) internal {
        IEventOut(_eventOut).eventOut(_type,_value);
    }


}