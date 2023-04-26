// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/IVaultPriceFeed.sol";
import "../access/BaseAccess.sol";
import {Constants} from "../constants/Constants.sol";

contract PriceManager is IPriceManager, BaseAccess, Constants {
    address public RUSD;
    IVaultPriceFeed public vaultPriceFeed;
    mapping(address => bool) public isInitialized;

    mapping(address => bool) public override isForex;
    mapping(address => uint256) public override maxLeverage; //  50 * 10000 50x
    mapping(address => uint256) public override tokenDecimals;

    event SetRUSD(address rUSD);
    event SetVaultPriceFeed(address indexed vaultPriceFeed);

    constructor(address _rUSD, address _vaultPriceFeed) {
        require(Address.isContract(_rUSD), "Invalid RUSD address");
        RUSD = _rUSD;
        emit SetRUSD(_rUSD);

        if (_vaultPriceFeed != address(0)) {
            vaultPriceFeed = IVaultPriceFeed(vaultPriceFeed);
            emit SetVaultPriceFeed(_vaultPriceFeed);
        }
    }

    //Config functions
    function setVaultPriceFeed(address _vaultPriceFeed) external onlyOwner {
        vaultPriceFeed = IVaultPriceFeed(_vaultPriceFeed);
        emit SetVaultPriceFeed(_vaultPriceFeed);
    }

    function setTokenConfig(address _token, uint256 _tokenDecimals, uint256 _maxLeverage, bool _isForex) external onlyOwner {
        require(Address.isContract(_token), "Token invalid");
        require(!isInitialized[_token], "Already initialized");
        tokenDecimals[_token] = _tokenDecimals;
        require(_maxLeverage > MIN_LEVERAGE, "MaxLeverage should be greater than MinLeverage");
        maxLeverage[_token] = _maxLeverage;
        isForex[_token] = _isForex;
        _getLastPrice(_token);
        isInitialized[_token] = true;
    }
    //End config functions

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view override returns (uint256) {
        (bool hasProfit, uint256 delta) = _getDelta(_indexToken, _size, _averagePrice, _isLong, _nextPrice);
        uint256 nextSize = _size + _sizeDelta;
        uint256 divisor;

        if (_isLong) {
            divisor = hasProfit ? nextSize + delta : nextSize - delta;
        } else {
            divisor = hasProfit ? nextSize - delta : nextSize + delta;
        }

        return (_nextPrice * nextSize) / divisor;
    }

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view override returns (uint256) {
        uint256 tokenPrice = _getLastPrice(_token);
        require(tokenPrice > 0, "Invalid token price while converting fromTokenToUSD");
        return _fromTokenToUSD(_token, _tokenAmount, tokenPrice);
    }

    function fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view override returns (uint256) {
        return _fromTokenToUSD(_token, _tokenAmount, _tokenPrice);
    } 

    function _fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _tokenPrice) internal view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }

        uint256 decimals = tokenDecimals[_token];
        require(decimals > 0, "Invalid decimals while converting fromTokenToUSD");
        return (_tokenAmount * _tokenPrice) / (10 ** decimals);
    }

    function fromUSDToToken(address _token, uint256 _usdAmount) external view override returns (uint256) {
        uint256 tokenPrice = _getLastPrice(_token);
        require(tokenPrice > 0, "Invalid token price while converting fromUSDToToken");
        return _fromUSDToToken(_token, _usdAmount, tokenPrice);
    }

    function fromUSDToToken(address _token, uint256 _usdAmount, uint256 _tokenPrice) external view override returns (uint256) {
        return _fromUSDToToken(_token, _usdAmount, _tokenPrice);
    }

    function _fromUSDToToken(address _token, uint256 _usdAmount, uint256 _tokenPrice) internal view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }

        uint256 decimals = tokenDecimals[_token];
        require(decimals > 0, "Invalid decimals while converting fromUSDToToken");
        return (_usdAmount * (10 ** decimals)) / _tokenPrice;
    }

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _indexPrice
    ) external view override returns (bool, uint256) {
        return _getDelta(_indexToken, _size, _averagePrice, _isLong, _indexPrice);
    }

    function _getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _indexPrice
    ) internal view returns (bool, uint256) {
        require(_averagePrice > 0, "Average price should be greater than zero");
        uint256 price = _indexPrice == 0 ? _getLastPrice(_indexToken) : _indexPrice;
        require(price > 0, "Invalid price, must not be ZERO");
        uint256 priceDelta = _averagePrice >= price ? _averagePrice - price : price - _averagePrice;
        uint256 delta = (_size * priceDelta) / _averagePrice;
        bool hasProfit = _isLong ? price >= _averagePrice : _averagePrice >= price;

        return (hasProfit, delta);
    }

    function getLastPrice(address _token) external view override returns (uint256) {
        return _token == RUSD ? PRICE_PRECISION : _getLastPrice(_token);
    }

    function _getLastPrice(address _token) internal view returns(uint256) {
        _verifyVaultPriceFeedIntialized();
        (uint256 lastPrice, , ) = IVaultPriceFeed(vaultPriceFeed).getLastPrice(_token);
        return lastPrice;
    }

    function getLatestSynchronizedPrice(address _token) external view override returns (uint256, uint256, bool) {
        _verifyVaultPriceFeedIntialized();
        return IVaultPriceFeed(vaultPriceFeed).getLastPrice(_token);
    }

    function getLatestSynchronizedPrices(address[] memory _tokens) public view override returns (uint256[] memory, bool) {
        _verifyVaultPriceFeedIntialized();
        return IVaultPriceFeed(vaultPriceFeed).getLastPrices(_tokens);
    }

    function setLatestPrice(address _token, uint256 _latestPrice) limitAccess external {
        if (address(vaultPriceFeed) != address(0)) {
            try IVaultPriceFeed(vaultPriceFeed).setLatestPrice(_token, _latestPrice) {}
            catch {}
        }
    }

    function setLatestPrices(address[] memory _tokens, uint256[] memory _prices) external {
        require(_tokens.length > 0, "Invalid params length, must not zero"); //Invalid params length, 0
        require(_tokens.length == _prices.length, "IVLPRL");

        for (uint256 i = 0; i < _tokens.length; i++) {
            try IVaultPriceFeed(vaultPriceFeed).setLatestPrice(_tokens[i], _prices[i]) {}
            catch {}
        }
    }

    function _verifyVaultPriceFeedIntialized() internal view {
        require(address(vaultPriceFeed) != address(0), "VaultPriceFeed not initialized");
    }

    //These function for test, will remove after deploying on main net
    function setInitializedForDev(address _token, bool _isInitialized) external onlyOwner {
       isInitialized[_token] = _isInitialized;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IPriceManager {
    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _indexPrice
    ) external view returns (bool, uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getLatestSynchronizedPrice(address _token) external view returns (uint256, uint256, bool);

    function getLatestSynchronizedPrices(address[] memory _tokens) external view returns (uint256[] memory, bool);

    function setLatestPrice(address _token, uint256 _latestPrice) external;

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function isForex(address _token) external view returns (bool);

    function maxLeverage(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IVaultPriceFeed {
    function setTokenConfig(address _token, address _priceFeed, uint256 _priceDecimals) external;

    function getLastPrice(address _token) external view returns (uint256, uint256, bool);

    function getLastPrices(address[] memory _tokens) external view returns(uint256[] memory, bool);

    function setLatestPrice(address _token, uint256 _latestPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseAccess is Ownable {
    mapping(address => bool) public hasAccess;

    event GrantAccess(address indexed account, bool hasAccess);

    modifier limitAccess {
        require(hasAccess[tx.origin] == true || hasAccess[msg.sender], "BaseAccess: Forbidden");
        _;
    }

    function grantAccess(address _account, bool _hasAccess) onlyOwner external {
        hasAccess[_account] = _hasAccess;
        emit GrantAccess(_account, _hasAccess);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./BaseConstants.sol";

contract Constants is BaseConstants {
    address public constant ZERO_ADDRESS = address(0);

    uint8 public constant ORDER_FILLED = 1;

    uint8 public constant ORDER_NOT_FILLED = 0;

    uint8 public constant STAKING_PID_FOR_CHARGE_FEE = 1;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;

    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_DELTA_TIME = 24 hours;
    uint256 public constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 public constant MAX_FEE_REWARD_BASIS_POINTS = BASIS_POINTS_DIVISOR; // 100%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_STAKING_FEE = 10000; // 10%
    uint256 public constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 public constant MAX_VESTING_DURATION = 700 days;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    //Position constants
    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;

    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;

    function checkSlippage(
        bool isLong,
        uint256 expectedMarketPrice,
        uint256 slippageBasisPoints,
        uint256 actualMarketPrice
    ) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <=
                    (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR,
                "Long position: Check slippage exceeded"
            );
        } else {
            require(
                (expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
                    actualMarketPrice,
                "Short position: Check slippage exceeded"
            );
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

pragma solidity ^0.8.12;

contract BaseConstants {
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals

    uint256 public constant DEFAULT_ROLP_PRICE = 100000; //1 USDC

    uint256 public constant ROLP_DECIMALS = 18;
}