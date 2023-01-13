/**
 *Submitted for verification at Arbiscan on 2023-01-13
*/

pragma experimental ABIEncoderV2;

// File: Address.sol

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: BaseStrategyRedux.sol

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function revokeStrategy() external;

    function governance() external view returns (address);

    function management() external view returns (address);

    function guardian() external view returns (address);
}

interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
}

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}

/**
 * @title BaseStrategyRedux
 * @author HeroBorg
 * @notice
 * This is an exact copy of BaseStrategy 0.4.3 from yearn, but i removed `ethToWant()` because we always override it and make it return 0
 * Also, I've removed some require error messages
 * This is a solution until we completely revamp the corestrat
 */

abstract contract BaseStrategyRedux {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public metadataURI;

    bool public doHealthCheck;
    address public healthCheck;

    function apiVersion() public pure returns (string memory) {
        return "0.4.3";
    }

    function name() external view virtual returns (string memory);

    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    uint256 public minReportDelay;

    uint256 public maxReportDelay;

    uint256 public profitFactor;

    uint256 public debtThreshold;

    bool public emergencyExit;

    modifier onlyAuthorized() {
        require(msg.sender == strategist || msg.sender == governance());
        _;
    }

    modifier onlyEmergencyAuthorized() {
        require(
            msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist);
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance());
        _;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
        _;
    }

    modifier onlyVaultManagers() {
        require(msg.sender == vault.management() || msg.sender == governance());
        _;
    }

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        //Already initialized
        require(address(want) == address(0));

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, uint256(-1));
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, uint256(-1));
    }

    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        healthCheck = _healthCheck;
    }

    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        doHealthCheck = _doHealthCheck;
    }

    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    function setRewards(address _rewards) external onlyStrategist {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, uint256(-1));
        emit UpdatedRewards(_rewards);
    }

    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    function setMetadataURI(string calldata _metadataURI)
        external
        onlyAuthorized
    {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    function governance() internal view returns (address) {
        return vault.governance();
    }

    // Removing ethToWant() because we always override it and put it to 0
    //function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    function estimatedTotalAssets() public view virtual returns (uint256);

    function isActive() public view returns (bool) {
        return
            vault.strategies(address(this)).debtRatio > 0 ||
            estimatedTotalAssets() > 0;
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    function liquidateAllPositions()
        internal
        virtual
        returns (uint256 _amountFreed);

    function tendTrigger(uint256 callCostInWei)
        public
        view
        virtual
        returns (bool)
    {
        return false;
    }

    function tend() external onlyKeepers {
        adjustPosition(vault.debtOutstanding());
    }

    /// @notice the only change is that we set callCost to 0. The behaviour is exactly the same as before, since ethToWant always returned 0
    function harvestTrigger(uint256 callCostInWei)
        public
        view
        virtual
        returns (bool)
    {
        //OLD VERSION
        //uint256 callCost = ethToWant(callCostInWei);
        //NEW VERSION
        uint256 callCost = 0;
        StrategyParams memory params = vault.strategies(address(this));

        if (params.activation == 0) return false;

        if (block.timestamp.sub(params.lastReport) < minReportDelay)
            return false;

        if (block.timestamp.sub(params.lastReport) >= maxReportDelay)
            return true;

        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        uint256 total = estimatedTotalAssets();

        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt);

        uint256 credit = vault.creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);

        adjustPosition(debtOutstanding);

        if (doHealthCheck && healthCheck != address(0)) {
            require(
                HealthCheck(healthCheck).check(
                    profit,
                    loss,
                    debtPayment,
                    debtOutstanding,
                    totalDebt
                ),
                "!h"
            );
        } else {
            doHealthCheck = true;
        }

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault));
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        want.safeTransfer(msg.sender, amountFreed);
    }

    function prepareMigration(address _newStrategy) internal virtual;

    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategyRedux(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    function protectedTokens() internal view virtual returns (address[] memory);

    function sweep(address _token) external onlyGovernance {
        require(_token != address(want));
        require(_token != address(vault));

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++)
            require(_token != _protectedTokens[i]);

        IERC20(_token).safeTransfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }
}

// NOTE: we do not use it, if you need it, just use the one from yearn
// abstract contract BaseStrategyInitializable is BaseStrategy {
//     bool public isOriginal = true;
//     event Cloned(address indexed clone);

//     constructor(address _vault) public BaseStrategy(_vault) {}

//     function initialize(
//         address _vault,
//         address _strategist,
//         address _rewards,
//         address _keeper
//     ) external virtual {
//         _initialize(_vault, _strategist, _rewards, _keeper);
//     }

//     function clone(address _vault) external returns (address) {
//         require(isOriginal, "!clone");
//         return this.clone(_vault, msg.sender, msg.sender, msg.sender);
//     }

//     function clone(
//         address _vault,
//         address _strategist,
//         address _rewards,
//         address _keeper
//     ) external returns (address newStrategy) {
//         bytes20 addressBytes = bytes20(address(this));

//         assembly {
//             let clone_code := mload(0x40)
//             mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
//             mstore(add(clone_code, 0x14), addressBytes)
//             mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
//             newStrategy := create(0, clone_code, 0x37)
//         }

//         BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

//         emit Cloned(newStrategy);
//     }
// }

// File: StrategyInsurance.sol

// Feel free to change the license, but this is what we use

interface StrategyAPIExt is StrategyAPI {
    function strategist() external view returns (address);

    function insurance() external view returns (address);
}

interface IStrategyInsurance {
    function reportProfit(uint256 _totalDebt, uint256 _profit)
        external
        returns (uint256 _payment, uint256 _compensation);

    function reportLoss(uint256 _totalDebt, uint256 _loss)
        external
        returns (uint256 _compensation);

    function migrateInsurance(address newInsurance) external;
}

/**
 * @title Strategy Generic Insurrance
 * @author Robovault
 * @notice
 *  StrategyInsurance provides an issurrance fund for strategy losses
 *  A portion of all profits are sent to the insurrance fund untill
 *  it reaches its target insurrance percentage. When a loss is realised
 *  by the strategy the inssurance fund will return the funds to the
 *  strategy to fully compensate or soften the loss.
 */
contract StrategyInsurance {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    StrategyAPIExt public strategy;
    IERC20 want;
    uint256 constant BPS_MAX = 10000;
    uint256 public lossSum = 0;

    event InsurancePayment(
        uint256 indexed strategyDebt,
        uint256 indexed harvestProfit,
        uint256 indexed wantPayment
    );
    event InsurancePayout(uint256 indexed wantPayout);

    // Bips - Proportion of totalDebt the inssurance fund is targeting to grow
    uint256 public targetFundSize = 50; // 0.5% default

    // Rate of the profits that go to insurrance while it's below target
    uint256 public profitTakeRate = 1000; // 10% default

    // The maximum compensation rate the insurrance fund will return funds to the strategy
    // proportional to the TotalDebt of the strategy
    uint256 public maximumCompenstionRate = 5; // 5 bips per harvest default

    function _onlyAuthorized() internal {
        require(
            msg.sender == strategy.strategist() || msg.sender == governance()
        );
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyStrategy() internal {
        require(msg.sender == address(strategy));
    }

    constructor(address _strategy) public {
        strategy = StrategyAPIExt(_strategy);
        want = IERC20(strategy.want());
    }

    function setTargetFundSize(uint256 _targetFundSize) external {
        _onlyAuthorized();
        require(_targetFundSize < 500); // Must be less than 5%
        targetFundSize = _targetFundSize;
    }

    function setProfitTakeRate(uint256 _profitTakeRate) external {
        _onlyAuthorized();
        require(_profitTakeRate < 4000); // Must be less than 40%
        profitTakeRate = _profitTakeRate;
    }

    function setmaximumCompenstionRate(uint256 _maximumCompenstionRate)
        external
    {
        _onlyAuthorized();
        require(_maximumCompenstionRate < 50); // Must be less than 0.5%
        maximumCompenstionRate = _maximumCompenstionRate;
    }

    /**
     * @notice
     *  Strategy reports profits to the insurrance find and informs the strategy
     *  of how much want is requested for insurrance.
     * @param _totalDebt Debt the strategy has with the vault.
     * @param _profit The profit the strategy is reporting this harvest
     * @return _payment amount requested for insurrance
     * @return _compensation amount paid out in latent insurance
     */
    function reportProfit(uint256 _totalDebt, uint256 _profit)
        external
        returns (uint256 _payment, uint256 _compensation)
    {
        _onlyStrategy();

        // if there has been a loss that is yet to be paid fully compensated, continue
        // to compensate
        if (lossSum > _profit) {
            lossSum = lossSum.sub(_profit);
            _compensation = compensate(_totalDebt);
            return (0, _compensation);
        }

        // no pending losses to pay out
        lossSum = 0;

        // Has the insurrance hit the insurrance target
        uint256 balance = want.balanceOf(address(this));
        uint256 targetBalance = _totalDebt.mul(targetFundSize).div(BPS_MAX);
        if (balance >= targetBalance) {
            return (0, 0);
        }

        _payment = _profit.mul(profitTakeRate).div(BPS_MAX);
        emit InsurancePayment(_totalDebt, _profit, _payment);
    }

    /**
     * @notice
     *  Strategy reports loss. The insurrance fund will decide weather or not to
     *  send want back to the strategy to soften the loss
     * @param _totalDebt Debt the strategy has with the vault.
     * @param _loss The loss realised by the this harvest
     * @return _compensation amount sent back to the strategy.
     */
    function reportLoss(uint256 _totalDebt, uint256 _loss)
        external
        returns (uint256 _compensation)
    {
        _onlyStrategy();

        lossSum = lossSum.add(_loss);
        _compensation = compensate(_totalDebt);
    }

    /**
     * @notice
     *  Processes insurance payouot
     * @param _totalDebt Debt the strategy has with the vault.
     * @return _compensation amount sent back to the strategy.
     */
    function compensate(uint256 _totalDebt)
        internal
        returns (uint256 _compensation)
    {
        uint256 balance = want.balanceOf(address(this));

        // Reserves are empties, we cannot compensate
        if (balance == 0) {
            lossSum = 0;
            return 0;
        }

        // Calculat what the payout will be
        uint256 maxComp = maximumCompenstionRate.mul(_totalDebt).div(BPS_MAX);
        _compensation = Math.min(Math.min(balance, lossSum), maxComp);

        if (_compensation > 0) {
            SafeERC20.safeTransfer(want, address(strategy), _compensation);
            emit InsurancePayout(_compensation);
        }
        lossSum = lossSum.sub(_compensation);
    }

    function governance() public view returns (address) {
        return VaultAPI(strategy.vault()).governance();
    }

    /**
     * @notice
     *  Sends balance to gov for the purpose of migrating to a new strategy at the
     *  disgression of governance.
     */
    function withdraw() external {
        _onlyGovernance();
        SafeERC20.safeTransfer(
            want,
            governance(),
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     *  Sets the lossSum. Adds some flexibility with payouts to cover edge-case
     *  scenarios
     */
    function setLossSum(uint256 newLossSum) external {
        _onlyGovernance();
        lossSum = newLossSum;
    }

    /**
     * @notice
     *  called by the strategy when updating the insurance contract
     */
    function migrateInsurance(address newInsurance) external {
        _onlyStrategy();
        SafeERC20.safeTransfer(
            want,
            newInsurance,
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     * Called by goverannace when updating the strategy
     */
    function migrateStrategy(address newStrategy) external {
        _onlyGovernance();
        SafeERC20.safeTransfer(
            want,
            StrategyAPIExt(newStrategy).insurance(),
            want.balanceOf(address(this))
        );
    }
}