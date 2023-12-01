// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./ChainedSpeedMarket.sol";

contract ChainedSpeedMarketMastercopy is ChainedSpeedMarket {
    constructor() {
        // Freeze mastercopy on deployment so it can never be initialized with real arguments
        initialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// internal
import "../interfaces/IChainedSpeedMarketsAMM.sol";

import "./SpeedMarket.sol";

contract ChainedSpeedMarket {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _chainedMarketsAMM;
        address _user;
        bytes32 _asset;
        uint64 _timeFrame;
        uint64 _initialStrikeTime;
        uint64 _strikeTime;
        int64 _initialStrikePrice;
        SpeedMarket.Direction[] _directions;
        uint _buyinAmount;
        uint _safeBoxImpact;
        uint _payoutMultiplier;
    }

    address public user;
    bytes32 public asset;
    uint64 public timeFrame;
    uint64 public initialStrikeTime;
    uint64 public strikeTime;
    int64 public initialStrikePrice;
    int64[] public strikePrices;
    SpeedMarket.Direction[] public directions;
    uint public buyinAmount;
    uint public safeBoxImpact;
    uint public payoutMultiplier;

    bool public resolved;
    int64[] public finalPrices;
    bool public isUserWinner;

    uint256 public createdAt;

    IChainedSpeedMarketsAMM public chainedMarketsAMM;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(InitParams calldata params) external {
        require(!initialized, "Chained market already initialized");
        initialized = true;
        chainedMarketsAMM = IChainedSpeedMarketsAMM(params._chainedMarketsAMM);
        user = params._user;
        asset = params._asset;
        timeFrame = params._timeFrame;
        initialStrikeTime = params._initialStrikeTime;
        strikeTime = params._strikeTime;
        initialStrikePrice = params._initialStrikePrice;
        directions = params._directions;
        buyinAmount = params._buyinAmount;
        safeBoxImpact = params._safeBoxImpact;
        payoutMultiplier = params._payoutMultiplier;
        chainedMarketsAMM.sUSD().approve(params._chainedMarketsAMM, type(uint256).max);
        createdAt = block.timestamp;
    }

    function resolve(int64[] calldata _finalPrices, bool _isManually) external onlyAMM {
        require(!resolved, "already resolved");
        require(block.timestamp > initialStrikeTime + (timeFrame * (_finalPrices.length - 1)), "not ready to be resolved");
        require(_finalPrices.length <= directions.length, "more prices than directions");

        finalPrices = _finalPrices;

        for (uint i = 0; i < _finalPrices.length; i++) {
            strikePrices.push(i == 0 ? initialStrikePrice : _finalPrices[i - 1]); // previous final price is current strike price
            bool userWonDirection = (_finalPrices[i] < strikePrices[i] && directions[i] == SpeedMarket.Direction.Down) ||
                (_finalPrices[i] > strikePrices[i] && directions[i] == SpeedMarket.Direction.Up);

            // user lost stop checking rest of directions
            if (!userWonDirection) {
                resolved = true;
                break;
            }
            // when last final price for last direction user won
            if (i == directions.length - 1) {
                require(!_isManually, "Can not resolve manually");
                isUserWinner = true;
                resolved = true;
            }
        }

        require(resolved, "Not ready to resolve");

        if (isUserWinner) {
            chainedMarketsAMM.sUSD().safeTransfer(user, chainedMarketsAMM.sUSD().balanceOf(address(this)));
        } else {
            chainedMarketsAMM.sUSD().safeTransfer(
                address(chainedMarketsAMM),
                chainedMarketsAMM.sUSD().balanceOf(address(this))
            );
        }

        emit Resolved(finalPrices, isUserWinner);
    }

    /// @notice numOfDirections returns number of directions (speed markets in chain)
    /// @return uint8
    function numOfDirections() external view returns (uint8) {
        return uint8(directions.length);
    }

    /// @notice numOfPrices returns number of strike/finales
    /// @return uint
    function numOfPrices() external view returns (uint) {
        return finalPrices.length;
    }

    modifier onlyAMM() {
        require(msg.sender == address(chainedMarketsAMM), "only the AMM may perform these methods");
        _;
    }

    event Resolved(int64[] finalPrices, bool userIsWinner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity >=0.5.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../SpeedMarkets/SpeedMarket.sol";
import "../SpeedMarkets/ChainedSpeedMarket.sol";

interface IChainedSpeedMarketsAMM {
    function sUSD() external view returns (IERC20Upgradeable);

    function minChainedMarkets() external view returns (uint);

    function maxChainedMarkets() external view returns (uint);

    function minTimeFrame() external view returns (uint64);

    function maxTimeFrame() external view returns (uint64);

    function minBuyinAmount() external view returns (uint);

    function maxBuyinAmount() external view returns (uint);

    function maxProfitPerIndividualMarket() external view returns (uint);

    function payoutMultiplier() external view returns (uint);

    function maxRisk() external view returns (uint);

    function currentRisk() external view returns (uint);

    function getLengths(address user) external view returns (uint[4] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/ISpeedMarketsAMM.sol";

contract SpeedMarket {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _speedMarketsAMM;
        address _user;
        bytes32 _asset;
        uint64 _strikeTime;
        int64 _strikePrice;
        Direction _direction;
        uint _buyinAmount;
        uint _safeBoxImpact;
        uint _lpFee;
    }

    enum Direction {
        Up,
        Down
    }

    address public user;
    bytes32 public asset;
    uint64 public strikeTime;
    int64 public strikePrice;
    Direction public direction;
    uint public buyinAmount;

    bool public resolved;
    int64 public finalPrice;
    Direction public result;

    ISpeedMarketsAMM public speedMarketsAMM;

    uint public safeBoxImpact;
    uint public lpFee;

    uint256 public createdAt;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(InitParams calldata params) external {
        require(!initialized, "Speed market already initialized");
        initialized = true;
        speedMarketsAMM = ISpeedMarketsAMM(params._speedMarketsAMM);
        user = params._user;
        asset = params._asset;
        strikeTime = params._strikeTime;
        strikePrice = params._strikePrice;
        direction = params._direction;
        buyinAmount = params._buyinAmount;
        safeBoxImpact = params._safeBoxImpact;
        lpFee = params._lpFee;
        speedMarketsAMM.sUSD().approve(params._speedMarketsAMM, type(uint256).max);
        createdAt = block.timestamp;
    }

    function resolve(int64 _finalPrice) external onlyAMM {
        require(!resolved, "already resolved");
        require(block.timestamp > strikeTime, "not ready to be resolved");
        resolved = true;
        finalPrice = _finalPrice;

        if (finalPrice < strikePrice) {
            result = Direction.Down;
        } else if (finalPrice > strikePrice) {
            result = Direction.Up;
        } else {
            result = direction == Direction.Up ? Direction.Down : Direction.Up;
        }

        if (direction == result) {
            speedMarketsAMM.sUSD().safeTransfer(user, speedMarketsAMM.sUSD().balanceOf(address(this)));
        } else {
            speedMarketsAMM.sUSD().safeTransfer(address(speedMarketsAMM), speedMarketsAMM.sUSD().balanceOf(address(this)));
        }

        emit Resolved(finalPrice, result, direction == result);
    }

    function isUserWinner() external view returns (bool) {
        return resolved && (direction == result);
    }

    modifier onlyAMM() {
        require(msg.sender == address(speedMarketsAMM), "only the AMM may perform these methods");
        _;
    }

    event Resolved(int64 finalPrice, Direction result, bool userIsWinner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.5.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../SpeedMarkets/SpeedMarket.sol";

interface ISpeedMarketsAMM {
    struct Params {
        bool supportedAsset;
        bytes32 pythId;
        uint safeBoxImpact;
        uint64 maximumPriceDelay;
    }

    function sUSD() external view returns (IERC20Upgradeable);

    function supportedAsset(bytes32 _asset) external view returns (bool);

    function assetToPythId(bytes32 _asset) external view returns (bytes32);

    function minBuyinAmount() external view returns (uint);

    function maxBuyinAmount() external view returns (uint);

    function minimalTimeToMaturity() external view returns (uint);

    function maximalTimeToMaturity() external view returns (uint);

    function maximumPriceDelay() external view returns (uint64);

    function maximumPriceDelayForResolving() external view returns (uint64);

    function timeThresholdsForFees(uint _index) external view returns (uint);

    function lpFees(uint _index) external view returns (uint);

    function lpFee() external view returns (uint);

    function maxSkewImpact() external view returns (uint);

    function safeBoxImpact() external view returns (uint);

    function marketHasCreatedAtAttribute(address _market) external view returns (bool);

    function marketHasFeeAttribute(address _market) external view returns (bool);

    function maxRiskPerAsset(bytes32 _asset) external view returns (uint);

    function currentRiskPerAsset(bytes32 _asset) external view returns (uint);

    function maxRiskPerAssetAndDirection(bytes32 _asset, SpeedMarket.Direction _direction) external view returns (uint);

    function currentRiskPerAssetAndDirection(bytes32 _asset, SpeedMarket.Direction _direction) external view returns (uint);

    function whitelistedAddresses(address _wallet) external view returns (bool);

    function getLengths(address _user) external view returns (uint[5] memory);

    function getParams(bytes32 _asset) external view returns (Params memory);
}