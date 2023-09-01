/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// File: contracts/Asset/interfaces/IAssetSettings.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IAssetSettings {

    struct param {
        address referPool;
        uint256 epochTime;
    }
    function eventOut() external view returns (address);
    function RecordEvent() external view returns (address);

    function lpDeployer() external view returns (address);
    function poolStatus(address asset,address pool) external view returns(uint8);

    function isNextEpoch(address asset,uint256 beginTime) external view returns(uint256);

    function setPoolStatus(address asset,address pool,uint8 poolStatus_) external;
    function setAssetParam(address asset,address pool) external;
    function getOutEpoch(address asset) external view returns(uint32);
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
        uint256 _liquidityMoveRatio;
    }

    struct poolParam {
        uint256 _priceShockRatio;
        uint256 _priceEffectiveTime;
    }

    function eventOut() external view returns (address);
    function getOraclePriceV2(address poolAddress) external view returns (uint256 ,uint80 ); 
    function getPrice(address poolAddress,address assetAddress,uint256 increasePosition,uint8 direction) external view returns (uint256 priceFuture,bool canAction); 
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
        // uint256 lastBlockTime
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

// File: contracts/Asset/AssetSettings.sol

pragma solidity 0.8.1;
pragma abicoder v2;

contract AssetSettings is IAssetSettings,Ownable {

    using SafeMath for uint256;

    address public _eventOut;
    address public _recordEvent;
    address public _lpDeployer;
    address public _factory;
    uint256 public _defaultEpochTime;
    mapping(address =>mapping(address =>uint8)) public _poolStatus;
    mapping(address => param) public _assetParam;

    modifier onlyFactory() {
        require(_factory == msg.sender || owner() == msg.sender,"only factory or Owner can set");
        _;
    }

    function setEventOut(address eventOut_) public onlyOwner {
        _eventOut = eventOut_;
    }

    function setRecordEventOut(address reocrdEvent_) public onlyOwner {
        _recordEvent = reocrdEvent_;
    }

    function setFactory(address factory_) public onlyOwner {
        _factory = factory_;
        bytes memory data = abi.encode(factory_);
        eventOut(1,data);
    }

    function setDefaultEpochTime(uint256 epochTime_) public onlyOwner {
        _defaultEpochTime = epochTime_;
        bytes memory data = abi.encode(epochTime_);
        eventOut(3,data);        
    }

    function setLpDeployer(address lpDeployer_) public onlyOwner {
        _lpDeployer = lpDeployer_;
        bytes memory data = abi.encode(_lpDeployer);
        eventOut(2,data);
    }
    function setAssetParam(address asset,address pool) external override onlyFactory {
        _assetParam[asset] = param(pool,_defaultEpochTime);
        bytes memory data = abi.encode(asset,pool,_defaultEpochTime);
        eventOut(10001,data);
    }

    function setPoolStatus(address asset,address pool,uint8 poolStatus_) external override onlyFactory {
        _poolStatus[asset][pool] = poolStatus_;
        bytes memory data = abi.encode(asset,pool,poolStatus_);
        eventOut(10000,data);
    }

    function eventOut() external override view returns (address) {
        return _eventOut;
    }

    function RecordEvent() external override view returns (address) {
        return _recordEvent;
    }
    
    function lpDeployer() external override view returns (address) {
        return _lpDeployer;
    }

    function poolStatus(address asset,address pool) external override view returns(uint8) {
        return _poolStatus[asset][pool];
    }
    function getOutEpoch(address asset) external override view returns(uint32) {
        uint32 _currentEpoch = IAsset(asset)._currentEpoch();
        address pool = _assetParam[asset].referPool;
        address poolSetting = IPool(pool)._setting();
        (uint256 priceDiffRatio,uint256 priceThreshold) = IPoolSettings(poolSetting).getPriceDiffRatio(pool,asset);
        if (priceDiffRatio < priceThreshold.div(2)) {
            return _currentEpoch + 1;
        } else if (priceDiffRatio < priceThreshold) {
            return _currentEpoch + 2;
        } else {
            return _currentEpoch + 3;
        }
    }

    function isNextEpoch(address asset,uint256 beginTime) external override view returns(uint256) {
        param memory assetParam = _assetParam[asset];
        return block.timestamp.sub(beginTime).div(assetParam.epochTime);
    }

    function eventOut(uint32 _type,bytes memory _value) internal {
        IEventOut(_eventOut).eventOut(_type,_value);
    }
}