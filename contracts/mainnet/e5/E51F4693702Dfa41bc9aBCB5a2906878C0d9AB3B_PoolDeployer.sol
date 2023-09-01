/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// File: contracts/Pool/interfaces/IPoolDeployer.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
interface IPoolDeployer {
    function deployPool(address oracleAddress,bool reserve,address rateAddress,address settingAddress) external  returns (address poolAddress);
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

// File: contracts/Pool/interfaces/IPoolSettings.sol
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
        uint256 _liquidityMoveRatio;//速率上限
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

// File: contracts/libraries/ArbBlockNumber.sol

pragma solidity >=0.5.0;
// pragma experimental ABIEncoderV2;

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

// File: contracts/Pool/Pool.sol

pragma solidity 0.8.1;

pragma abicoder v2;

contract Pool is IPool {
    using SafeMath for uint256;

    address public override _setting;

    PriceParam public _priceParam;

    mapping(uint32 => Position) public override _positions;
    mapping(address => RebaseInfo) public override _rebaseInfo;
    mapping(address => SizeInfo) public override _sizeInfo;

    mapping(address=>LiquidityInfo)public override _lastLiquidity;

    PriceInfo public override _lastPrice;
    uint32 public _positionIndex;

    constructor(address oracleAddress,bool reserve,address rateAddress,address settingAddress) {
        _priceParam.oracle = oracleAddress;
        _priceParam.reserve = reserve;
        _priceParam.rate = rateAddress;
        _setting = settingAddress;
    }

    modifier updateOracle() {
        updateOraclePrice();
        updateLiquidity(msg.sender);
        _;
        updatePriceTime();
    }

    function getPriceParam() external view override returns (PriceParam memory) {
        return _priceParam;
    }

    function updateSize(address user,uint256 size,uint256 value,uint8 direction) internal {
        SizeInfo memory senderSize = _sizeInfo[user];
        if (direction == 1) {
            senderSize.totalSizeLong = senderSize.totalSizeLong.add(size);
            senderSize.totalPositionLong = senderSize.totalPositionLong.add(value);
        } else if (direction == 2){
            senderSize.totalSizeShort = senderSize.totalSizeShort.add(size);
            senderSize.totalPositionShort = senderSize.totalPositionShort.add(value);
        } else if (direction == 3) {
            senderSize.totalSizeLong = senderSize.totalSizeLong.sub(size);
            senderSize.totalPositionLong = senderSize.totalPositionLong.sub(value);
        } else if (direction == 4){
            senderSize.totalSizeShort = senderSize.totalSizeShort.sub(size);
            senderSize.totalPositionShort = senderSize.totalPositionShort.sub(value);
        }
        _sizeInfo[user] = senderSize;
        bytes memory data = abi.encode(user,senderSize.totalSizeLong,senderSize.totalPositionLong,senderSize.totalSizeShort,senderSize.totalPositionShort);
        eventOut(1,data);
    }

    function rebase(address userAddress) internal {
        RebaseInfo memory rebaseInfo = _rebaseInfo[userAddress];

        if (ArbBlockNumber.getArbBlockNumber() == rebaseInfo.lastBlockHeight) {
            return ;
        }
        SizeInfo memory sizeInfo = _sizeInfo[userAddress];
        bytes memory data;
        if ((sizeInfo.totalSizeLong == 0) && (sizeInfo.totalSizeShort == 0)) {
            rebaseInfo.lastBlockHeight = ArbBlockNumber.getArbBlockNumber();
            _rebaseInfo[userAddress] = rebaseInfo;
            data = abi.encode(userAddress,rebaseInfo.rebaseLongValue,rebaseInfo.rebaseShortValue,rebaseInfo.lastBlockHeight);
            eventOut(2,data);
            return ;
        }

        int256 rebaseLongFee;
        int256 rebaseShortFee;

        (rebaseLongFee,rebaseShortFee) = IPoolSettings(_setting).getRebaseFee(address(this),userAddress);
        rebaseInfo.rebaseLongValue = rebaseInfo.rebaseLongValue + rebaseLongFee;
        rebaseInfo.rebaseShortValue = rebaseInfo.rebaseShortValue+ rebaseShortFee;
        rebaseInfo.lastBlockHeight = ArbBlockNumber.getArbBlockNumber();

        _rebaseInfo[userAddress] = rebaseInfo;
        data = abi.encode(userAddress,rebaseInfo.rebaseLongValue,rebaseInfo.rebaseShortValue,rebaseInfo.lastBlockHeight);
        eventOut(2,data);
    }

    function updateOraclePrice() internal {
        _lastPrice.lastPrice = _lastPrice.price;
        (_lastPrice.price,) = IPoolSettings(_setting).getOraclePriceV2(address(this));
    }

    function updateLiquidity(address user) internal {
        uint256 liquidity = IPoolSettings(_setting).getLiquidity(address(this),user);
        _lastLiquidity[user] = LiquidityInfo(liquidity,block.timestamp);
        bytes memory data = abi.encode(user,liquidity,block.timestamp);
        eventOut(9,data);
    }

    function updatePriceTime() internal {
        _lastPrice.lastBlockTime = block.timestamp;
        bytes memory data = abi.encode(_lastPrice.lastPrice,_lastPrice.price,_lastPrice.lastBlockTime);
        eventOut(8,data);
    }

    function openPosition(
        bytes calldata openParam,
        uint256 position
    ) external override updateOracle returns (uint32) {
        OpenParam memory param;
        (param.direction,param.leverage) = abi.decode(openParam,(uint8,uint16));
        require(
            param.direction == 1 || param.direction == 2,
            "Direction Only Can Be 1 Or 2"
        );
        require(IPoolSettings(_setting).checkOpenPosition(address(this),msg.sender,param.leverage,position),"unsupported leverage");

        rebase(msg.sender);
        uint256 value = position.mul(param.leverage);
        (uint256 price,bool canAction) = IPoolSettings(_setting).getPrice(address(this),msg.sender,value,param.direction);
        require(canAction,"action is not support for now");
        uint256 size = Price.divPrice(value, price);
        _positionIndex++;

        _positions[_positionIndex] = Position(
            msg.sender,
            price,
            ArbBlockNumber.getArbBlockNumber(),
            position,
            size,
            param.direction,
            param.leverage,
            param.direction == 1?_rebaseInfo[msg.sender].rebaseLongValue:_rebaseInfo[msg.sender].rebaseShortValue
        );

        updateSize(msg.sender,size,value,param.direction);
        bytes memory data = abi.encode(_positionIndex,msg.sender,price,ArbBlockNumber.getArbBlockNumber(),position,size,param.direction,param.leverage,_positions[_positionIndex].openRebase);
        eventOut(3,data);
        return _positionIndex;
    }

    function addMargin(
        uint32 positionId,
        uint256 margin
    ) external override updateOracle {
        rebase(msg.sender);
        Position memory p = _positions[positionId];
        require(p.sender == msg.sender,"only sender can add margin");
        _positions[positionId].margin = p.margin.add(margin);
        bytes memory data = abi.encode(positionId,margin);
        eventOut(7,data);
    }

    function testUpdate(address asset) public {
        updateOraclePrice();
        updateLiquidity(asset);
        rebase(asset);
        updatePriceTime();
    }
    function testPositionOut(address asset,uint32 positionId) public view returns (uint256 price,uint256 transferOut,uint256 serviceFee,int256 fundingFee) {
        Position memory p = _positions[positionId];
        (uint256 closePrice,bool canAction) = IPoolSettings(_setting).getPrice(address(this),asset,Price.mulPrice(p.size,p.openPrice),p.direction + 2);
        require(canAction,"action is not support for now");
        price = closePrice;
        int256 rabaseRatio = p.direction == 1?
                _rebaseInfo[asset].rebaseLongValue - p.openRebase:
                _rebaseInfo[asset].rebaseShortValue- p.openRebase;
        int256 pnl = int256(Price.mulPrice(p.size,price)) - int256(Price.mulPrice(p.size,p.openPrice));
        if (p.direction == 2) {
            pnl = -pnl;
        }

        fundingFee = int256(Price.mulPrice(p.size,price))*rabaseRatio/1e18;
        serviceFee = IPoolSettings(_setting).getCloseFee(address(this),asset,Price.mulPrice(p.size,price));
        pnl = pnl - fundingFee - (int256)(serviceFee) + (int256)(p.margin);
        transferOut = pnl > 0 ? (uint256)(pnl):0;
    }

    function calPositionOut(uint32 positionId,bool withPNL) internal returns (uint256 transferOut,uint256 serviceFee,int256 fundingFee,bool canAction) {
        Position memory p = _positions[positionId];
        uint256 price = 0;
        (price, canAction) = IPoolSettings(_setting).getPrice(address(this),msg.sender,Price.mulPrice(p.size,p.openPrice),p.direction + 2);

        int256 rabaseRatio = p.direction == 1?
                _rebaseInfo[msg.sender].rebaseLongValue - p.openRebase:
                _rebaseInfo[msg.sender].rebaseShortValue- p.openRebase;
        int256 pnl = int256(Price.mulPrice(p.size,price)) - int256(Price.mulPrice(p.size,p.openPrice));
        if (p.direction == 2) {
            pnl = -pnl;
        }

        if (withPNL == false) {
            pnl = 0;
        }

        fundingFee = int256(Price.mulPrice(p.size,price))*rabaseRatio/1e18;
        serviceFee = IPoolSettings(_setting).getCloseFee(address(this),msg.sender,Price.mulPrice(p.size,price));
        bytes memory data = abi.encode(positionId,pnl,serviceFee,fundingFee,p.margin,price);

        pnl = pnl - fundingFee - (int256)(serviceFee) + (int256)(p.margin);
        transferOut = pnl > 0 ? (uint256)(pnl):0;

        eventOut(6,data);
    }

    function closePosition(
        uint32 positionId
    ) external override updateOracle returns (uint256 transferOut,uint256 fee,int256 fundingFee){
        rebase(msg.sender);
        Position memory p = _positions[positionId];
        require(p.sender == msg.sender,"only sender can add margin");
        bool canAction = true;
     
        (transferOut,fee,fundingFee,canAction) = calPositionOut(positionId,true);
        require(!IPoolSettings(_setting).checkliquidation(address(this),p.sender,p.margin,transferOut),"The position has been worn out");
        require(canAction,"Too much price slippage");

        updateSize(msg.sender,p.size,Price.mulPrice(p.size,p.openPrice),p.direction + 2);
        bytes memory data = abi.encode(positionId,transferOut);
        eventOut(5,data);
        delete _positions[positionId];
        return (transferOut,fee,fundingFee);
    }

    function liquidate(
        uint32 positionId
    ) external override updateOracle returns (uint256 liqReward,uint256 fee,int256 fundingFee){
        rebase(msg.sender);
        Position memory p = _positions[positionId];
        require(p.sender == msg.sender,"only sender can liquidate");
        uint256 transferOut;
        (transferOut,fee,fundingFee,) = calPositionOut(positionId,true);
        require(IPoolSettings(_setting).checkliquidation(address(this),p.sender,p.margin,transferOut),"The position has not been worn out");
        liqReward = IPoolSettings(_setting).getLiqReward(address(this),p.sender,p.margin);
        updateSize(msg.sender,p.size,Price.mulPrice(p.size,p.openPrice),p.direction + 2);
        delete _positions[positionId];
        bytes memory data = abi.encode(positionId,liqReward);
        eventOut(4,data);
        return (liqReward,fee,fundingFee);
    }

    function exit(uint32 positionId) external override updateOracle returns (uint256 transferOut,uint256 fee,int256 fundingFee){
        Position memory p = _positions[positionId];
        require(p.sender == msg.sender,"only sender can add exit");
        (transferOut,fee,fundingFee,) = calPositionOut(positionId,false);
        updateSize(msg.sender,p.size,Price.mulPrice(p.size,p.openPrice),p.direction + 2);
        delete _positions[positionId];
        bytes memory data = abi.encode(positionId,transferOut);
        eventOut(5,data);
        return (transferOut,fee,fundingFee);
    }

    function eventOut(uint32 _type,bytes memory _value) internal {
        IEventOut(IPoolSettings(_setting).eventOut()).eventOut(_type,_value);
    }
}

// File: contracts/Pool/PoolDeployer.sol

pragma solidity 0.8.1;

contract PoolDeployer is IPoolDeployer {
    function deployPool(address oracleAddress,bool reserve,address rateAddress,address settingAddress) external override  returns (address poolAddress) {
        poolAddress = address(new Pool(oracleAddress,reserve,rateAddress,settingAddress));
    }
}