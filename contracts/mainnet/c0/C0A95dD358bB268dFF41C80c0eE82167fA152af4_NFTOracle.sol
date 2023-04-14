// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/INFTOracle.sol";
import "../interfaces/IGNft.sol";

contract NFTOracle is INFTOracle, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 private constant DECIMAL_PRECISION = 10**18;

    /* ========== STATE VARIABLES ========== */
    // key is nft contract address
    mapping(address => NFTPriceFeed) public nftPriceFeed;
    address[] public nftPriceFeedKeys;

    // Maximum deviation allowed between two consecutive oracle prices.
    uint256 public maxPriceDeviation; // 20% 18-digit precision.

    // Maximum allowed deviation between two consecutive oracle prices within a certain time frame
    // 18-bit precision.
    uint256 public maxPriceDeviationWithTime; // 10%
    uint256 public timeIntervalWithPrice; // 30 minutes
    uint256 public minUpdateTime; // 10 minutes

    uint256 public twapInterval;

    address public keeper;

    mapping(address => uint256) public twapPrices;
    mapping(address => bool) public nftPaused;

    /* ========== INITIALIZER ========== */

    function initialize(
        uint256 _maxPriceDeviation,
        uint256 _maxPriceDeviationWithTime,
        uint256 _timeIntervalWithPrice,
        uint256 _minUpdateTime,
        uint256 _twapInterval
    ) external initializer {
        __Ownable_init();

        maxPriceDeviation = _maxPriceDeviation;
        maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
        timeIntervalWithPrice = _timeIntervalWithPrice;
        minUpdateTime = _minUpdateTime;
        twapInterval = _twapInterval;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "NFTOracle: caller is not the owner or keeper");
        _;
    }

    modifier onlyExistedKey(address _nftContract) {
        require(nftPriceFeed[_nftContract].registered == true, "NFTOracle: key not existed");
        _;
    }

    modifier whenNotPaused(address _nftContract) {
        require(!nftPaused[_nftContract], "NFTOracle: nft price feed paused");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "NFTOracle: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function addAssets(
        address[] calldata _nftContracts
    ) external
    onlyOwner
    {
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            _addAsset(_nftContracts[i]);
        }
    }

    function addAsset(
        address _nftContract
    ) external
    onlyOwner
    {
        _addAsset(_nftContract);
    }

    function removeAsset(
        address _nftContract
    ) external
    onlyOwner
    onlyExistedKey(_nftContract)
    {
        delete nftPriceFeed[_nftContract];

        uint256 length = nftPriceFeedKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (nftPriceFeedKeys[i] == _nftContract) {
                nftPriceFeedKeys[i] = nftPriceFeedKeys[length - 1];
                nftPriceFeedKeys.pop();
                break;
            }
        }

        emit AssetRemoved(_nftContract);
    }

    function setDataValidityParameters(
        uint256 _maxPriceDeviation,
        uint256 _maxPriceDeviationWithTime,
        uint256 _timeIntervalWithPrice,
        uint256 _minUpdateTime
    ) external onlyOwner {
        maxPriceDeviation = _maxPriceDeviation;
        maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
        timeIntervalWithPrice = _timeIntervalWithPrice;
        minUpdateTime = _minUpdateTime;
    }

    function setPause(address _nftContract, bool isPause) external onlyOwner {
        nftPaused[_nftContract] = isPause;
    }

    function setTwapInterval(uint256 _twapInterval) external onlyOwner {
        twapInterval = _twapInterval;
    }

    function setAssetData(
        address _nftContract,
        uint256 _price
    ) external
    onlyKeeper
    whenNotPaused(_nftContract)
    {
        uint256 _timestamp = block.timestamp;
        _setAssetData(_nftContract, _price, _timestamp);
    }

    function setMultipleAssetData(
        address[] calldata _nftContracts,
        uint256[] calldata _prices
    ) external
    onlyKeeper
    {
        require(_nftContracts.length == _prices.length, "NFTOracle: data length not match");
        uint256 _timestamp = block.timestamp;
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            bool _paused = nftPaused[_nftContracts[i]];
            if (!_paused) {
                _setAssetData(_nftContracts[i], _prices[i], _timestamp);
            }
        }
    }

    /* ========== VIEWS ========== */

    function getUnderlyingPrice(address _gNft) external view override returns (uint256) {
        address _nftContract = IGNft(_gNft).underlying();
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0, "NFTOracle: no price data");

        uint256 twapPrice = twapPrices[_nftContract];
        if (twapPrice == 0) {
            return nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
        } else {
            return twapPrice;
        }
    }

    function getAssetPrice(address _nftContract) external view override returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0, "NFTOracle: no price data");

        uint256 twapPrice = twapPrices[_nftContract];
        if (twapPrice == 0) {
            return nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
        } else {
            return twapPrice;
        }
    }

    function getLatestTimestamp(address _nftContract) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeed[_nftContract].nftPriceData[len - 1].timestamp;
    }

    function getLatestPrice(address _nftContract) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
    }

    function getPreviousPrice(address _nftContract, uint256 _numOfRoundBack) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
        return nftPriceFeed[_nftContract].nftPriceData[len - _numOfRoundBack - 1].price;
    }

    function getPreviousTimestamp(address _nftContract, uint256 _numOfRoundBack) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
        return nftPriceFeed[_nftContract].nftPriceData[len - _numOfRoundBack - 1].timestamp;
    }

    function getPriceFeedLength(address _nftContract) public view returns (uint256) {
        return nftPriceFeed[_nftContract].nftPriceData.length;
    }

    function getLatestRoundId(address _nftContract) external view override returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeed[_nftContract].nftPriceData[len - 1].roundId;
    }

    function isExistedKey(address _nftContract) public view returns (bool) {
        return nftPriceFeed[_nftContract].registered;
    }

    function nftPriceFeedKeysLength() public view returns (uint256) {
        return nftPriceFeedKeys.length;
    }

    function calculateTwapPrice(address _nftContract) public view returns (uint256) {
        require(nftPriceFeed[_nftContract].registered == true, "NFTOracle: key not existed");
        require(twapInterval != 0, "NFTOracle: interval can't be 0");

        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0, "NFTOracle: Not Enough history");
        uint256 round = len - 1;
        NFTPriceData memory priceRecord = nftPriceFeed[_nftContract].nftPriceData[round];

        uint256 latestTimestamp = priceRecord.timestamp;
        uint256 baseTimestamp = block.timestamp - twapInterval;

        // if latest updated timestamp is earlier than target timestamp, return the latest price.
        if (latestTimestamp < baseTimestamp || round == 0) {
            return priceRecord.price;
        }

        // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
        uint256 cumulativeTime = block.timestamp - latestTimestamp;
        uint256 previousTimestamp = latestTimestamp;
        uint256 weightedPrice = priceRecord.price * cumulativeTime;
        while (true) {
            if (round == 0) {
                // if cumulative time less than requested interval, return current twap price
                return weightedPrice / cumulativeTime;
            }

            round = round - 1;
            // get current round timestamp and price
            priceRecord = nftPriceFeed[_nftContract].nftPriceData[round];
            uint256 currentTimestamp = priceRecord.timestamp;
            uint256 price = priceRecord.price;

            // check if current round timestamp is earlier than target timestamp
            if (currentTimestamp <= baseTimestamp) {
                weightedPrice = weightedPrice + (price * (previousTimestamp - baseTimestamp));
                break;
            }

            uint256 timeFraction = previousTimestamp - currentTimestamp;
            weightedPrice = weightedPrice + price * timeFraction;
            cumulativeTime = cumulativeTime + timeFraction;
            previousTimestamp = currentTimestamp;
        }
        return weightedPrice / twapInterval;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addAsset(
        address _nftContract
    ) private {
        require(nftPriceFeed[_nftContract].registered == false, "NFTOracle: key existed");
        nftPriceFeed[_nftContract].registered = true;
        nftPriceFeedKeys.push(_nftContract);
        emit AssetAdded(_nftContract);
    }

    function _setAssetData(
        address _nftContract,
        uint256 _price,
        uint256 _timestamp
    ) private {
        require(nftPriceFeed[_nftContract].registered == true, "NFTOracle: key not existed");
        require(_timestamp > getLatestTimestamp(_nftContract), "NFTOracle: incorrect timestamp");
        require(_price > 0, "NFTOracle: price can not be 0");

        bool dataValidity = _checkValidityOfPrice(_nftContract, _price, _timestamp);
        require(dataValidity, "NFTOracle: invalid price data");

        uint256 len = getPriceFeedLength(_nftContract);
        NFTPriceData memory data = NFTPriceData({
            price: _price,
            timestamp: _timestamp,
            roundId: len
        });
        nftPriceFeed[_nftContract].nftPriceData.push(data);

        uint256 twapPrice = calculateTwapPrice(_nftContract);
        twapPrices[_nftContract] = twapPrice;

        emit SetAssetData(_nftContract, _price, _timestamp, len);
        emit SetAssetTwapPrice(_nftContract, twapPrice, _timestamp);
    }

    function _checkValidityOfPrice(
        address _nftContract,
        uint256 _price,
        uint256 _timestamp
    ) private view returns (bool) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len > 0) {
            uint256 price = nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
            if (_price == price) {
                return true;
            }
            uint256 timestamp = nftPriceFeed[_nftContract].nftPriceData[len - 1].timestamp;
            uint256 percentDeviation;
            if (_price > price) {
                percentDeviation = ((_price - price).mul(DECIMAL_PRECISION)).div(price) ;
            } else {
                percentDeviation = ((price - _price)).mul(DECIMAL_PRECISION).div(price);
            }
            uint256 timeDeviation = _timestamp - timestamp;
            if (percentDeviation > maxPriceDeviation) {
                return false;
            } else if (timeDeviation < minUpdateTime) {
                return false;
            } else if ((percentDeviation > maxPriceDeviationWithTime) && (timeDeviation < timeIntervalWithPrice)) {
                return false;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGNft {
    /* ========== Event ========== */
    event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);
    event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);


    function underlying() external view returns (address);
    function minterOf(uint256 tokenId) external view returns (address);

    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface INFTOracle {
    struct NFTPriceData {
        uint256 price;
        uint256 timestamp;
        uint256 roundId;
    }

    struct NFTPriceFeed {
        bool registered;
        NFTPriceData[] nftPriceData;
    }

    /* ========== Event ========== */

    event KeeperUpdated(address indexed newKeeper);
    event AssetAdded(address indexed asset);
    event AssetRemoved(address indexed asset);

    event SetAssetData(address indexed asset, uint256 price, uint256 timestamp, uint256 roundId);
    event SetAssetTwapPrice(address indexed asset, uint256 price, uint256 timestamp);

    function getAssetPrice(address _nftContract) external view returns (uint256);
    function getLatestRoundId(address _nftContract) external view returns (uint256);
    function getUnderlyingPrice(address _gNft) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library Constant {
    uint256 public constant CLOSE_FACTOR_MIN = 5e16;
    uint256 public constant CLOSE_FACTOR_MAX = 9e17;
    uint256 public constant COLLATERAL_FACTOR_MAX = 9e17;
    uint256 public constant LIQUIDATION_THRESHOLD_MAX = 9e17;
    uint256 public constant LIQUIDATION_BONUS_MAX = 5e17;
    uint256 public constant AUCTION_DURATION_MAX = 7 days;
    uint256 public constant MIN_BID_FINE_MAX = 100 ether;
    uint256 public constant REDEEM_FINE_RATE_MAX = 5e17;
    uint256 public constant REDEEM_THRESHOLD_MAX = 9e17;
    uint256 public constant BORROW_RATE_MULTIPLIER_MAX = 1e19;
    uint256 public constant AUCTION_FEE_RATE_MAX = 5e17;

    enum EcoZone {
        RED,
        ORANGE,
        YELLOW,
        LIGHTGREEN,
        GREEN
    }

    enum EcoScorePreviewOption {
        LOCK,
        CLAIM,
        EXTEND,
        LOCK_MORE
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }

    struct LoanData {
        uint256 loanId;
        LoanState state;
        address borrower;
        address gNft;
        address nftAsset;
        uint256 nftTokenId;
        uint256 borrowAmount;
        uint256 interestIndex;

        uint256 bidStartTimestamp;
        address bidderAddress;
        uint256 bidPrice;
        uint256 bidBorrowAmount;
        uint256 floorPrice;
        uint256 bidCount;
        address firstBidderAddress;
    }

    struct MarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
    }

    struct NftMarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct BorrowInfo {
        uint256 borrow;
        uint256 interestIndex;
    }

    struct AccountSnapshot {
        uint256 gTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
    }

    struct AccrueSnapshot {
        uint256 totalBorrow;
        uint256 totalReserve;
        uint256 accInterestIndex;
    }

    struct AccrueLoanSnapshot {
        uint256 totalBorrow;
        uint256 accInterestIndex;
    }

    struct DistributionInfo {
        uint256 supplySpeed;
        uint256 borrowSpeed;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 accPerShareSupply;
        uint256 accPerShareBorrow;
        uint256 accruedAt;
    }

    struct DistributionAccountInfo {
        uint256 accruedGRV; // Unclaimed GRV rewards amount
        uint256 boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint256 boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint256 accPerShareSupply; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint256 accPerShareBorrow; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint256 apySupplyGRV;
        uint256 apyBorrowGRV;
        uint256 apyAccountSupplyGRV;
        uint256 apyAccountBorrowGRV;
    }

    struct EcoScoreInfo {
        uint256 claimedGrv;
        uint256 ecoDR;
        EcoZone ecoZone;
        uint256 compoundGrv;
        uint256 changedEcoZoneAt;
    }

    struct BoostConstant {
        uint256 boost_max;
        uint256 boost_portion;
        uint256 ecoBoost_portion;
    }

    struct RebateCheckpoint {
        uint256 timestamp;
        uint256 totalScore;
        uint256 adminFeeRate;
        mapping(address => uint256) amount;
    }

    struct RebateClaimInfo {
        uint256 timestamp;
        address[] markets;
        uint256[] amount;
        uint256[] prices;
        uint256 value;
    }

    struct LockInfo {
        uint256 timestamp;
        uint256 amount;
        uint256 expiry;
    }

    struct EcoPolicyInfo {
        uint256 boostMultiple;
        uint256 maxBoostCap;
        uint256 boostBase;
        uint256 redeemFee;
        uint256 claimTax;
        uint256[] pptTax;
    }

    struct EcoZoneStandard {
        uint256 minExpiryOfGreenZone;
        uint256 minExpiryOfLightGreenZone;
        uint256 minDrOfGreenZone;
        uint256 minDrOfLightGreenZone;
        uint256 minDrOfYellowZone;
        uint256 minDrOfOrangeZone;
    }

    struct PPTPhaseInfo {
        uint256 phase1;
        uint256 phase2;
        uint256 phase3;
        uint256 phase4;
    }
}