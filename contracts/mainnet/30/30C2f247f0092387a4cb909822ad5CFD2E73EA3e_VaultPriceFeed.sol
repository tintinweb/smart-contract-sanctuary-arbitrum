// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "../tokens/interfaces/IMintable.sol";
import "./interfaces/IVaultPriceFeed.sol";

interface IServerPriceFeed {
    function getPrice(address _token) external view returns (uint256, uint256);
}

interface PythStructs {
    struct Price {
        int64 price;// Price
        uint64 conf;// Confidence interval around the price
        int32 expo;// Price exponent
        uint publishTime;// Unix timestamp describing when the price was published
    }
}

interface IPyth {
    function queryPriceFeed(bytes32 id) external view returns (PythStructs.Price memory price);
    function priceFeedExists(bytes32 id) external view returns (bool exists);
    function getValidTimePeriod() external view returns(uint validTimePeriod);
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);
    function updatePriceFeedsIfNecessary(bytes[] memory updateData,bytes32[] memory priceIds,uint64[] memory publishTimes) payable external;
    function updatePriceFeeds(bytes[]memory updateData) payable external;
}


contract VaultPriceFeed is IVaultPriceFeed, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MIN_PRICE_THRES = 10 ** 20;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_PRICE_VARIANCE_PER_1M = 1000;
    uint256 public constant PRICE_VARIANCE_PRECISION = 10000;

    uint256 public priceSafetyTimeGap = 60;//seconds
    uint256 public stopTradingPriceGap = 0; 

    IPyth public pyth;
    IServerPriceFeed public serverOracle;

    //token config.
    EnumerableSet.AddressSet tokens;
    mapping(address => bytes32) public override tokenPythKEY;
    mapping(address => uint256) public spreadBasisPoints;
    mapping(address => uint256) public override adjustmentBasisPoints;
    mapping(address => bool) public override isAdjustmentAdditive;


    event UpdatePriceFeedsIfNecessary(bytes[] updateData, bytes32[] priceIds,uint64[] publishTimes);
    event UpdatePriceFeeds(bytes[]  updateData);
    //----- owner setting
    function setServerOracle(address _pyth, address _serverOra) external onlyOwner{
        pyth = IPyth(_pyth);
        serverOracle = IServerPriceFeed(_serverOra);
    }
    function setTokenCfgList(address[] memory _tokenList, bytes32[] memory _key) external onlyOwner {
        for(uint8 i = 0; i < _tokenList.length; i++) {
            require(_key[i] !=  bytes32(0) && pyth.priceFeedExists(_key[i]), "key not exist in pyth");
            if (!tokens.contains(_tokenList[i])){
                tokens.add(_tokenList[i]);
            }
            tokenPythKEY[_tokenList[i]] = _key[i];
        }
    }
    function deleteToken(address[] memory _tokenList)external onlyOwner {
        for(uint8 i = 0; i < _tokenList.length; i++) {
            if (tokens.contains(_tokenList[i])){
                tokens.remove(_tokenList[i]);
            }
        }
    }
    function setGap(uint256 _priceSafetyTimeGap, uint256 _stopTradingPriceGap) external onlyOwner {
        priceSafetyTimeGap = _priceSafetyTimeGap;
        stopTradingPriceGap = _stopTradingPriceGap;
    }
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyOwner {
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
    }
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyOwner {
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }
    //----- end of owner setting


    //----- interface for pyth update 
    function updatePriceFeedsIfNecessary(bytes[] memory updateData, bytes32[] memory priceIds, uint64[] memory publishTimes) payable override external {
        pyth.updatePriceFeedsIfNecessary{value:msg.value}(updateData,priceIds,publishTimes );
        emit UpdatePriceFeedsIfNecessary(updateData, priceIds,publishTimes);
    }
    function updatePriceFeedsIfNecessaryTokens(bytes[] memory updateData, address[] memory _tokens, uint64[] memory publishTimes) payable override external {
        bytes32[] memory priceIds = new bytes32[](_tokens.length);
        for(uint8 i = 0; i < _tokens.length; i++){
            require(isSupportToken(_tokens[i]), "not supported token");
            priceIds[i] = tokenPythKEY[_tokens[i]];
        }
        pyth.updatePriceFeedsIfNecessary{value:msg.value}(updateData,priceIds,publishTimes );
        emit UpdatePriceFeedsIfNecessary(updateData, priceIds, publishTimes);
    }
    function updatePriceFeedsIfNecessaryTokensSt(bytes[] memory updateData, address[] memory _tokens ) payable override external {
        bytes32[] memory priceIds = new bytes32[](_tokens.length);
        uint64[] memory publishTimes = new uint64[](_tokens.length);
        for(uint8 i = 0; i < _tokens.length; i++){
            require(isSupportToken(_tokens[i]), "not supported token");
            priceIds[i] = tokenPythKEY[_tokens[i]];
            publishTimes[i] = uint64(block.timestamp);
        }
        pyth.updatePriceFeedsIfNecessary{value:msg.value}(updateData,priceIds,publishTimes );
        emit UpdatePriceFeedsIfNecessary(updateData, priceIds, publishTimes);
    }
    function updatePriceFeeds(bytes[] memory updateData) payable override external{
        pyth.updatePriceFeeds{value:msg.value}(updateData);
        emit UpdatePriceFeeds(updateData);
    }


    //----- public view 
    function isSupportToken(address _token) public view returns (bool){
        return tokens.contains(_token);
    }
    function priceTime(address _token) external view override returns (uint256){
        (, , uint256 pyUpdatedTime) = getPythPrice(_token);
        return pyUpdatedTime;
    }
    //----- END of public view 


    function _getCombPrice(address _token, bool _maximise, bool _addAdjust) internal view returns (uint256, uint256){
        // uint256 cur_timestamp = block.timestamp;
        (uint256 pricePy, bool statePy, uint256 pyUpdatedTime) = getPythPrice(_token);
        require(statePy, "[Oracle] price failed.");
        if (stopTradingPriceGap > 0){//do verify
            (uint256 pricePr, bool statePr, ) = getPrimaryPrice(_token);
            require(statePr, "[Oracle] p-oracle failed");
            uint256 price_gap = pricePr > pricePy ? pricePr.sub(pricePy) : pricePy.sub(pricePr);
            price_gap = price_gap.mul(PRICE_VARIANCE_PRECISION).div(pricePy);
            require(price_gap < stopTradingPriceGap, "[Oracle] System hault as large price variance.");
        }
        pricePy = _addBasisSpread(_token, pricePy, _maximise, _addAdjust);
        require(pricePy > 0, "[Oracle] ORACLE FAILS");
        return (pricePy, pyUpdatedTime);    
    }

    function _addBasisSpread(address _token, uint256 _price, bool _max, bool _addAdjust)internal view returns (uint256){
        if (_addAdjust && adjustmentBasisPoints[_token] > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                _price = _price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            } else {
                _price = _price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            }
        }
        if (spreadBasisPoints[_token] > 0){
            if (_max){
                _price = _price.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            }
            else{
                _price = _price.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            }         
        }
        return _price;
    }

    //public read
    function getPrice(address _token, bool _maximise, bool , bool _adjust) public override view returns (uint256) {
        require(isSupportToken(_token), "Unsupported token");
        (uint256 price, uint256 updatedTime) = _getCombPrice(_token, _maximise, _adjust);
        require(block.timestamp.sub(updatedTime) < priceSafetyTimeGap, "[Oracle] price out of time.");
        require(price > 10, "[Oracle] invalid price");
        return price;
    }
    function getPriceUnsafe(address _token, bool _maximise, bool, bool _adjust) public override view returns (uint256) {
        require(isSupportToken(_token), "Unsupported token");
        (uint256 price, ) = _getCombPrice(_token, _maximise, _adjust);
        require(price > 10, "[Oracle] invalid price");
        return price;
    }
    function priceVariancePer1Million(address ) external pure override returns (uint256){
        return 0;
    }
    function getPriceSpreadImpactFactor(address ) external pure override returns (uint256, uint256){
        return (0,0);
    }
    function getConvertedPyth(address _token) public view returns(uint256, uint256, int256){
        PythStructs.Price memory _pyPrice = pyth.getPriceUnsafe(tokenPythKEY[_token]) ;
        uint256 it_price = uint256(int256(_pyPrice.price));
        uint256 upd_time = uint256(_pyPrice.publishTime);
        int256 _expo= int256(_pyPrice.expo);
        return(it_price,upd_time,_expo);
    }

    function getPythPrice(address _token) public view returns(uint256, bool, uint256){
        uint256 price = 0;
        bool read_state = false;
        if (address(pyth) == address(0)) {
            return (price, read_state, 0);
        }
        if (tokenPythKEY[_token] == bytes32(0)) {
            return (price, read_state, 1);
        }

        uint256 upd_time = 5;
        try pyth.getPriceUnsafe(tokenPythKEY[_token]) returns (PythStructs.Price memory _pyPrice ) {
            uint256 it_price = uint256(int256(_pyPrice.price));
            if (it_price < 1) {
                return (0, read_state, 2);
            }
            upd_time = uint256(_pyPrice.publishTime);
            if (upd_time < 1600000000) {
                return (0, read_state, 3);
            }
            int256 _expo= int256(_pyPrice.expo);
            if (_expo >= 0) {
                return (0, read_state, 4);
            }
            
            price = uint256(it_price).mul(PRICE_PRECISION).div(10 ** uint256(-_expo));
            if (price < MIN_PRICE_THRES) {
                return (0, read_state, 5);
            }
            else{
                read_state = true;
            }
        } catch {
            upd_time = 6;
        }    
        return (price, read_state, upd_time);
    }

    function getPrimaryPrice(address _token) public view override returns (uint256, bool, uint256) {
        require(isSupportToken(_token), "Unsupported token");
        uint256 price;
        uint256 upd_time;
        (price, upd_time) = serverOracle.getPrice(_token);
        if (price < 1) {
            return (0, false, 2);
        }
        uint256 time_interval = uint256(block.timestamp).sub(upd_time);
        if (time_interval > priceSafetyTimeGap) {
            return (0, false, 3);
        }
        return (price, true, upd_time);
    }

    
    function tokenToUsdUnsafe(address _token, uint256 _tokenAmount, bool _max) public view override returns (uint256) {
        require(isSupportToken(_token), "Unsupported token");
        if (_tokenAmount == 0)  return 0;
        uint256 decimals = IMintable(_token).decimals();
        require(decimals > 0, "invalid decimal"); 
        uint256 price = getPriceUnsafe(_token, _max, true, true);
        return _tokenAmount.mul(price).div(10**decimals);
    }

    function usdToTokenUnsafe( address _token, uint256 _usdAmount, bool _max ) public view override returns (uint256) {
        require(isSupportToken(_token), "Unsupported token");
        if (_usdAmount == 0)  return 0;
        uint256 decimals = IMintable(_token).decimals();
        require(decimals > 0, "invalid decimal");
        uint256 price = getPriceUnsafe(_token, _max, true, true);
        return _usdAmount.mul(10**decimals).div(price);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVaultPriceFeed {   
    function getPrimaryPrice(address _token) external view  returns (uint256, bool, uint256);
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function tokenPythKEY(address _token) external view returns (bytes32);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function getPrice(address _token, bool _maximise,bool,bool) external view returns (uint256);
    function getPriceUnsafe(address _token, bool _maximise, bool, bool _adjust) external view returns (uint256);
    function priceTime(address _token) external view returns (uint256);
    function priceVariancePer1Million(address _token) external view returns (uint256); //100 for 1%
    function getPriceSpreadImpactFactor(address _token) external view returns (uint256, uint256); 
    function tokenToUsdUnsafe(address _token, uint256 _tokenAmount, bool _max) external view returns (uint256);
    function usdToTokenUnsafe( address _token, uint256 _usdAmount, bool _max ) external view returns (uint256);

    function updatePriceFeedsIfNecessary(bytes[] memory updateData, bytes32[] memory priceIds, uint64[] memory publishTimes) payable external;
    function updatePriceFeedsIfNecessaryTokens(bytes[] memory updateData, address[] memory _tokens, uint64[] memory publishTimes) payable external;
    function updatePriceFeeds(bytes[] memory updateData) payable external;
    function updatePriceFeedsIfNecessaryTokensSt(bytes[] memory updateData, address[] memory _tokens) payable external;

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