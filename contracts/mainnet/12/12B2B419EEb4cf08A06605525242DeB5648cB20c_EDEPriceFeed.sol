// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IEDEPriceFeed.sol";

contract EDEPriceFeed is IEDEPriceFeed, Ownable {
    using SafeMath for uint256;
    bytes constant prefix = "\x19Ethereum Signed Message:\n32";

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant PRICE_VARIANCE_PRECISION = 10000;
    uint256 public constant BITMASK_32 = ~uint256(0) >> (256 - 32);

    //parameters for sign update
    uint256 public updateTimeTolerance = 15;
    mapping(address => bool) public isUpdater;
    mapping(address => uint256) private signUpdaterCode;
    mapping(address => uint256) private updateTime;

    //setting for token
    address[] public tokens;
    uint256[] public tokenPrecisions;
    mapping(address => uint256) public prices;
    mapping(address => uint256) public priceIndexLoc;


    //setting for spread
    mapping(address => uint256) public priceSpreadLong1Percent;
    mapping(address => uint256) public priceSpreadShort1Percent;
    mapping(address => uint256) public priceSpreadUpdateTime;


    //Counting for roud
    using Counters for Counters.Counter;
    Counters.Counter private _batchRoundId;
    mapping(address => Counters.Counter) private _tokenRoundID;

    //events
    event PriceUpdatedBatch(address token, uint256 ajustedAmount, uint256 batchRoundId);
    event PriceUpdatedSingle(address token, uint256 ajustedAmount, uint256 batchRoundId);

    event SpreadUpdatedLongSingle(address token, uint256 ajustedAmount);
    event SpreadUpdatedShortSingle(address token, uint256 ajustedAmount);

    modifier onlyUpdater() {
        require(isUpdater[msg.sender] || msg.sender == owner(), "FastPriceFeed: forbidden");
        _;
    }

    //settings for updater
    function setUpdater(address _account, bool _isActive) external onlyOwner {
        isUpdater[_account] = _isActive;
    }
    function setSignPrefixCode(address _updater, uint256 _setCode) external onlyOwner {
        signUpdaterCode[_updater] = _setCode;
    }

    //paras. for trade
    function setTimeTolerance(uint256 _tol) external onlyOwner {
        updateTimeTolerance = _tol;
    }
    function setBitTokens( address[] memory _tokens, uint256[] memory _tokenPrecisions) external onlyOwner {
        require(_tokens.length == _tokenPrecisions.length, "FastPriceFeed: invalid lengths");
        tokens = _tokens;
        tokenPrecisions = _tokenPrecisions;
        for(uint8 i = 0; i < _tokens.length; i++){
            priceIndexLoc[_tokens[i]] = i;
        }
    }

    //UPDATE functions for updater
    function setPriceSpreadFactor(address _token, uint256 _longPSF, uint256 _shortPSF, uint256 _timestamp) external override onlyUpdater {
        _setPriceSpreadFactor(_token, _longPSF, _shortPSF, _timestamp);
    }

    function setPricesWithBits(uint256[] memory _priceBits, uint256 _timestamp) external override onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);
    }

    function setPricesWithBitsSingle(address _token, uint256 _priceBits, uint256 _timestamp) external override onlyUpdater {
        _setPricesWithBitsSingle(_token, _priceBits, _timestamp);
    }

    function setPriceSingle(address _token, uint256 _price, uint256 _timestamp) external override onlyUpdater {
        _setPricesSingle(_token, _price, _timestamp);
    }

    function setPricesWithBitsVerify(uint256[] memory _priceBits, uint256 _timestamp) external override onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);
    }

    function setPricesWithBitsSingleVerify(address _token, uint256 _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBitsSingle(_token, _priceBits, _timestamp);
    }

    function setPriceSingleVerify(address _updater, address _token, uint256 _price, uint8 _priceType, uint256 _timestamp, bytes memory _updaterSignedMsg) external override returns (bool) {
        require(_priceType < 2, "unsupported price type");
        require(VerifySingle(_updater, _token, _price, _priceType, _timestamp, _updaterSignedMsg));

        if (_priceType == 0){
            _setPricesSingle(_token, _price, _timestamp);
        }
        else{
            _setPricesWithBitsSingle(_token, _price, _timestamp);
        }
        
        return true;
    }

    function setPriceBitsVerify(address _updater, uint256[] memory _priceBits, uint256 _timestamp, bytes memory _updaterSignedMsg) external override returns (bool) {
        require(VerifyBits(_updater, _priceBits, _timestamp, _updaterSignedMsg));
        _setPricesWithBits(_priceBits, _timestamp);
        return true;
    }

    function updateTokenInfo(address _updater, address _token, uint256[] memory _paras, uint256 _timestamp, bytes memory _updaterSignedMsg) external override returns (bool) {
        require(_paras.length == 3, "invalid parameters");
        require(VerifyFull(_updater, _token, _paras, _timestamp, _updaterSignedMsg));
        _setPricesWithBitsSingle(_token, _paras[0], _timestamp);
        _setPriceSpreadFactor(_token, _paras[1], _paras[2], _timestamp);
        return true;
    }



    //functions internal
    function _setPriceSpreadFactor(address _token, uint256 _longPSF, uint256 _shortPSF, uint256 _timestamp) internal {
        priceSpreadLong1Percent[_token] = _longPSF;
        priceSpreadShort1Percent[_token] = _shortPSF;
        priceSpreadUpdateTime[_token] = _timestamp;
    }

    function _setPricesWithBits(uint256[] memory _priceBits, uint256 _timestamp) private {
        uint256 roundId = _batchRoundId.current();
        _batchRoundId.increment();

        uint256 bitsMaxLength = 8;
        for (uint256 i = 0; i < _priceBits.length; i++) {
            uint256 priceBits = _priceBits[i];

            for (uint256 j = 0; j < bitsMaxLength; j++) {
                uint256 tokenIndex = i * bitsMaxLength + j;
                if (tokenIndex >= tokens.length) {
                    return;
                }

                uint256 startBit = 32 * j;
                uint256 price = (priceBits >> startBit) & BITMASK_32;
                address token = tokens[tokenIndex];
                require(_timestamp >= updateTime[token], "data out of time");
                updateTime[token] = _timestamp;
                uint256 tokenPrecision = tokenPrecisions[tokenIndex];
                uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(
                    tokenPrecision
                );
                prices[token] = adjustedPrice;
                emit PriceUpdatedBatch(token, adjustedPrice, roundId);
            }
        }
    }

    function _setPricesWithBitsSingle(address _token, uint256 _priceBits, uint256 _timestamp) private {
        uint256 price = (_priceBits >> 0) & BITMASK_32;
        uint256 tokenPrecision = tokenPrecisions[priceIndexLoc[_token]];
        uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(tokenPrecision);
        _setPricesSingle(_token, adjustedPrice, _timestamp);
    }

    function _setPricesSingle(address _token, uint256 _price, uint256 _timestamp) private {
        uint256 roundId = _tokenRoundID[_token].current();
        _tokenRoundID[_token].increment();
        require(_timestamp >= updateTime[_token], "data out of time");
        prices[_token] = _price;
        updateTime[_token] = _timestamp;
        emit PriceUpdatedSingle(_token, _price, roundId);
    }


    function updateWithSig(uint256[] memory _priceBits, uint256 _priceTimestamp,  address _updater, bytes memory _updaterSignedMsg) external onlyUpdater {
        require(VerifyBits(_updater, _priceBits, _priceTimestamp, _updaterSignedMsg), "Verification Failed");
        _setPricesWithBits(_priceBits, _priceTimestamp);
    }



    //public read
    function getPrice(address _token) public view override returns (uint256, uint256) {
        return (prices[_token], updateTime[_token]);
    }

    function getPriceSpreadFactoe(address _token) public view override returns (uint256, uint256, uint256) {
        return(priceSpreadLong1Percent[_token],
                priceSpreadShort1Percent[_token],
                priceSpreadUpdateTime[_token]);
    }

    function VerifyFull(address _updater, address _token, uint256[] memory _priceBits, uint256 _priceTimestamp, bytes memory _updaterSignedMsg) public view returns (bool) {
        if (updateTimeTolerance > 0)
            require(_priceTimestamp <= block.timestamp && block.timestamp.sub(_priceTimestamp) < updateTimeTolerance, "time tollarance reached.");
        bytes memory content = abi.encodePacked(signUpdaterCode[_updater], _updater, _token, _priceTimestamp);
        for(uint8 i = 0; i < _priceBits.length; i++){
            content =  abi.encodePacked(content, _priceBits[i]);//, "."
        }
        bytes32 _calHash = keccak256(content);
        bytes32 ethSignedHash = keccak256(abi.encodePacked(prefix, _calHash));
        return isUpdater[recoverSigner(ethSignedHash, _updaterSignedMsg)];
    }

    function VerifyBits(address _updater, uint256[] memory _priceBits, uint256 _priceTimestamp, bytes memory _updaterSignedMsg) public view returns (bool) {
        if (updateTimeTolerance > 0)
            require(_priceTimestamp <= block.timestamp && block.timestamp.sub(_priceTimestamp) < updateTimeTolerance, "time tollarance reached.");
        bytes memory content = abi.encodePacked(signUpdaterCode[_updater], _updater, _priceTimestamp);
        for(uint8 i = 0; i < _priceBits.length; i++){
            content =  abi.encodePacked(content, _priceBits[i]);//, "."
        }
        bytes32 _calHash = keccak256(content);
        bytes32 ethSignedHash = keccak256(abi.encodePacked(prefix, _calHash));
        return isUpdater[recoverSigner(ethSignedHash, _updaterSignedMsg)];
    }


    function VerifySingle(address _updater, address _token, uint256 _price, uint8 _priceType, uint256 _priceTimestamp, bytes memory _updaterSignedMsg) public view returns (bool) {
        if (updateTimeTolerance > 0)
            require(_priceTimestamp <= block.timestamp && block.timestamp.sub(_priceTimestamp) < updateTimeTolerance, "time tollarance reached.");
        bytes memory content = abi.encodePacked(signUpdaterCode[_updater], _updater, _priceTimestamp, _token, _price, _priceType);
        bytes32 _calHash = keccak256(content);
        bytes32 ethSignedHash = keccak256(abi.encodePacked(prefix, _calHash));
        return isUpdater[recoverSigner(ethSignedHash, _updaterSignedMsg)];
    }

    //code for verify
    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEDEPriceFeed {

    //public read
    function getPrice(address _token) external view returns (uint256, uint256);
    function getPriceSpreadFactoe(address _token) external view returns (uint256, uint256, uint256);

    function setPriceSingleVerify(address _updater, address _token, uint256 _price, uint8 _priceType, uint256 _timestamp, bytes memory _updaterSignedMsg) external returns (bool);
    function updateTokenInfo(address _updater, address _token, uint256[] memory _paras, uint256 _timestamp, bytes memory _updaterSignedMsg) external returns (bool);
    function setPriceBitsVerify(address _updater, uint256[] memory _priceBits, uint256 _timestamp, bytes memory _updaterSignedMsg) external returns (bool);

    function setPriceSpreadFactor(address _token, uint256 _longPSF, uint256 _shortPSF, uint256 _timestamp) external;

    function setPricesWithBits(uint256[] memory _priceBits, uint256 _timestamp) external;

    function setPricesWithBitsSingle(address _token, uint256 _priceBits, uint256 _timestamp) external;

    function setPriceSingle(address _token, uint256 _price, uint256 _timestamp) external;
    function setPricesWithBitsVerify(uint256[] memory _priceBits, uint256 _timestamp) external;
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