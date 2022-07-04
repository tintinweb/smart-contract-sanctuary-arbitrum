// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IAllowanceTarget.sol";

contract AllowanceTarget is IAllowanceTarget {
    using Address for address;

    uint256 private constant TIME_LOCK_DURATION = 1 days;

    address public spender;
    address public newSpender;
    uint256 public timelockExpirationTime;

    modifier onlySpender() {
        require(spender == msg.sender, "AllowanceTarget: not the spender");
        _;
    }

    constructor(address _spender) public {
        require(_spender != address(0), "AllowanceTarget: _spender should not be 0");

        // Set spender
        spender = _spender;
    }

    function setSpenderWithTimelock(address _newSpender) external override onlySpender {
        require(_newSpender.isContract(), "AllowanceTarget: new spender not a contract");
        require(newSpender == address(0) && timelockExpirationTime == 0, "AllowanceTarget: SetSpender in progress");

        timelockExpirationTime = block.timestamp + TIME_LOCK_DURATION;
        newSpender = _newSpender;
    }

    function completeSetSpender() external override {
        require(timelockExpirationTime != 0, "AllowanceTarget: no pending SetSpender");
        require(block.timestamp >= timelockExpirationTime, "AllowanceTarget: time lock not expired yet");

        // Set new spender
        spender = newSpender;
        // Reset
        timelockExpirationTime = 0;
        newSpender = address(0);
    }

    function teardown() external override onlySpender {
        selfdestruct(payable(spender));
    }

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(address payable target, bytes calldata callData) external override onlySpender returns (bytes memory resultData) {
        bool success;
        (success, resultData) = target.call(callData);
        if (!success) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.7.0;

interface IAllowanceTarget {
    function setSpenderWithTimelock(address _newSpender) external;

    function completeSetSpender() external;

    function executeCall(address payable _target, bytes calldata _callData) external returns (bytes memory resultData);

    function teardown() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ISpender.sol";
import "./interfaces/IAllowanceTarget.sol";

/**
 * @dev Spender contract
 */
contract Spender is ISpender {
    using SafeMath for uint256;

    // Constants do not have storage slot.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    uint256 private constant TIME_LOCK_DURATION = 1 days;

    // Below are the variables which consume storage slots.
    bool public timelockActivated;
    uint64 public numPendingAuthorized;
    address public operator;

    address public allowanceTarget;
    address public pendingOperator;

    uint256 public contractDeployedTime;
    uint256 public timelockExpirationTime;

    mapping(address => bool) public consumeGasERC20Tokens;
    mapping(uint256 => address) public pendingAuthorized;

    mapping(address => bool) private authorized;
    mapping(address => bool) private tokenBlacklist;

    // System events
    event TimeLockActivated(uint256 activatedTimeStamp);
    // Operator events
    event SetPendingOperator(address pendingOperator);
    event TransferOwnership(address newOperator);
    event SetAllowanceTarget(address allowanceTarget);
    event SetNewSpender(address newSpender);
    event SetConsumeGasERC20Token(address token);
    event TearDownAllowanceTarget(uint256 tearDownTimeStamp);
    event BlackListToken(address token, bool isBlacklisted);
    event AuthorizeSpender(address spender, bool isAuthorized);

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "Spender: not the operator");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Spender: not authorized");
        _;
    }

    function setNewOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "Spender: operator can not be zero address");
        pendingOperator = _newOperator;

        emit SetPendingOperator(_newOperator);
    }

    function acceptAsOperator() external {
        require(pendingOperator == msg.sender, "Spender: only nominated one can accept as new operator");
        operator = pendingOperator;
        pendingOperator = address(0);

        emit TransferOwnership(operator);
    }

    /************************************************************
     *                    Timelock management                    *
     *************************************************************/
    /// @dev Everyone can activate timelock after the contract has been deployed for more than 1 day.
    function activateTimelock() external {
        bool canActivate = block.timestamp.sub(contractDeployedTime) > 1 days;
        require(canActivate && !timelockActivated, "Spender: can not activate timelock yet or has been activated");
        timelockActivated = true;

        emit TimeLockActivated(block.timestamp);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(address _operator, address[] memory _consumeGasERC20Tokens) {
        require(_operator != address(0), "Spender: _operator should not be 0");

        // Set operator
        operator = _operator;
        timelockActivated = false;
        contractDeployedTime = block.timestamp;

        for (uint256 i = 0; i < _consumeGasERC20Tokens.length; i++) {
            consumeGasERC20Tokens[_consumeGasERC20Tokens[i]] = true;
        }
    }

    function setAllowanceTarget(address _allowanceTarget) external onlyOperator {
        require(allowanceTarget == address(0), "Spender: can not reset allowance target");

        // Set allowanceTarget
        allowanceTarget = _allowanceTarget;

        emit SetAllowanceTarget(_allowanceTarget);
    }

    /************************************************************
     *          AllowanceTarget interaction functions            *
     *************************************************************/
    function setNewSpender(address _newSpender) external onlyOperator {
        IAllowanceTarget(allowanceTarget).setSpenderWithTimelock(_newSpender);

        emit SetNewSpender(_newSpender);
    }

    function teardownAllowanceTarget() external onlyOperator {
        IAllowanceTarget(allowanceTarget).teardown();

        emit TearDownAllowanceTarget(block.timestamp);
    }

    /************************************************************
     *           Whitelist and blacklist functions               *
     *************************************************************/
    function isBlacklisted(address _tokenAddr) external view returns (bool) {
        return tokenBlacklist[_tokenAddr];
    }

    function blacklist(address[] calldata _tokenAddrs, bool[] calldata _isBlacklisted) external onlyOperator {
        require(_tokenAddrs.length == _isBlacklisted.length, "Spender: length mismatch");
        for (uint256 i = 0; i < _tokenAddrs.length; i++) {
            tokenBlacklist[_tokenAddrs[i]] = _isBlacklisted[i];

            emit BlackListToken(_tokenAddrs[i], _isBlacklisted[i]);
        }
    }

    function isAuthorized(address _caller) external view returns (bool) {
        return authorized[_caller];
    }

    function authorize(address[] calldata _pendingAuthorized) external onlyOperator {
        require(_pendingAuthorized.length > 0, "Spender: authorize list is empty");
        require(numPendingAuthorized == 0 && timelockExpirationTime == 0, "Spender: an authorize current in progress");

        if (timelockActivated) {
            numPendingAuthorized = uint64(_pendingAuthorized.length);
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                pendingAuthorized[i] = _pendingAuthorized[i];
            }
            timelockExpirationTime = block.timestamp + TIME_LOCK_DURATION;
        } else {
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                authorized[_pendingAuthorized[i]] = true;

                emit AuthorizeSpender(_pendingAuthorized[i], true);
            }
        }
    }

    function completeAuthorize() external {
        require(timelockExpirationTime != 0, "Spender: no pending authorize");
        require(block.timestamp >= timelockExpirationTime, "Spender: time lock not expired yet");

        for (uint256 i = 0; i < numPendingAuthorized; i++) {
            authorized[pendingAuthorized[i]] = true;
            emit AuthorizeSpender(pendingAuthorized[i], true);
            delete pendingAuthorized[i];
        }
        timelockExpirationTime = 0;
        numPendingAuthorized = 0;
    }

    function deauthorize(address[] calldata _deauthorized) external onlyOperator {
        for (uint256 i = 0; i < _deauthorized.length; i++) {
            authorized[_deauthorized[i]] = false;

            emit AuthorizeSpender(_deauthorized[i], false);
        }
    }

    function setConsumeGasERC20Tokens(address[] memory _consumeGasERC20Tokens) external onlyOperator {
        for (uint256 i = 0; i < _consumeGasERC20Tokens.length; i++) {
            consumeGasERC20Tokens[_consumeGasERC20Tokens[i]] = true;

            emit SetConsumeGasERC20Token(_consumeGasERC20Tokens[i]);
        }
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    /// @dev Spend tokens on user's behalf. Only an authority can call this.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _amount Amount to spend.
    function spendFromUser(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external override onlyAuthorized {
        _transferTokenFromUserTo(_user, _tokenAddr, msg.sender, _amount);
    }

    /// @dev Spend tokens on user's behalf. Only an authority can call this.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _recipient The receiver of the token.
    /// @param _amount Amount to spend.
    function spendFromUserTo(
        address _user,
        address _tokenAddr,
        address _recipient,
        uint256 _amount
    ) external override onlyAuthorized {
        _transferTokenFromUserTo(_user, _tokenAddr, _recipient, _amount);
    }

    function _transferTokenFromUserTo(
        address _user,
        address _tokenAddr,
        address _recipient,
        uint256 _amount
    ) internal {
        require(!tokenBlacklist[_tokenAddr], "Spender: token is blacklisted");

        if (_tokenAddr == ETH_ADDRESS || _tokenAddr == ZERO_ADDRESS) {
            return;
        }
        // Fix gas stipend for non standard ERC20 transfer in case token contract's SafeMath violation is triggered
        // and all gas are consumed.
        uint256 gasStipend = consumeGasERC20Tokens[_tokenAddr] ? 80000 : gasleft();
        uint256 balanceBefore = IERC20(_tokenAddr).balanceOf(_recipient);

        (bool callSucceed, bytes memory returndata) = address(allowanceTarget).call{ gas: gasStipend }(
            abi.encodeWithSelector(
                IAllowanceTarget.executeCall.selector,
                _tokenAddr,
                abi.encodeWithSelector(IERC20.transferFrom.selector, _user, _recipient, _amount)
            )
        );
        require(callSucceed, "Spender: ERC20 transferFrom failed");

        bytes memory decodedReturnData = abi.decode(returndata, (bytes));
        if (decodedReturnData.length > 0) {
            // Return data is optional
            // Tokens like ZRX returns false on failed transfer
            require(abi.decode(decodedReturnData, (bool)), "Spender: ERC20 transferFrom failed");
        }

        // Check balance
        uint256 balanceAfter = IERC20(_tokenAddr).balanceOf(_recipient);
        require(balanceAfter.sub(balanceBefore) == _amount, "Spender: ERC20 transferFrom amount mismatch");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity >=0.7.0;

interface ISpender {
    function spendFromUser(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external;

    function spendFromUserTo(
        address _user,
        address _tokenAddr,
        address _receiverAddr,
        uint256 _amount
    ) external;
}

pragma solidity 0.7.6;

import "./interfaces/IHasBlackListERC20Token.sol";
import "./interfaces/ISpender.sol";

contract SpenderSimulation {
    ISpender public immutable spender;

    mapping(address => bool) public hasBlackListERC20Tokens;

    modifier checkBlackList(address _tokenAddr, address _user) {
        if (hasBlackListERC20Tokens[_tokenAddr]) {
            IHasBlackListERC20Token hasBlackListERC20Token = IHasBlackListERC20Token(_tokenAddr);
            require(!hasBlackListERC20Token.isBlackListed(_user), "SpenderSimulation: user in token's blacklist");
        }
        _;
    }

    /************************************************************
     *                       Constructor                         *
     *************************************************************/
    constructor(ISpender _spender, address[] memory _hasBlackListERC20Tokens) {
        spender = _spender;

        for (uint256 i = 0; i < _hasBlackListERC20Tokens.length; i++) {
            hasBlackListERC20Tokens[_hasBlackListERC20Tokens[i]] = true;
        }
    }

    /************************************************************
     *                    Helper functions                       *
     *************************************************************/
    /// @dev Spend tokens on user's behalf but reverts if succeed.
    /// This is only intended to be run off-chain to check if the transfer will succeed.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _amount Amount to spend.
    function simulate(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external checkBlackList(_tokenAddr, _user) {
        spender.spendFromUser(_user, _tokenAddr, _amount);

        // All checks passed: revert with success reason string
        revert("SpenderSimulation: transfer simulation success");
    }
}

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHasBlackListERC20Token is IERC20 {
    function isBlackListed(address user) external returns (bool);

    function addBlackList(address user) external;

    function removeBlackList(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TreasuryVester {
    using SafeMath for uint256;

    address public lon;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address _lon,
        address _recipient,
        uint256 _vestingAmount,
        uint256 _vestingBegin,
        uint256 _vestingCliff,
        uint256 _vestingEnd
    ) {
        require(_vestingAmount > 0, "vesting amount is zero");
        require(_vestingBegin >= block.timestamp, "vesting begin too early");
        require(_vestingCliff >= _vestingBegin, "cliff is too early");
        require(_vestingEnd > _vestingCliff, "end is too early");

        lon = _lon;
        recipient = _recipient;

        vestingAmount = _vestingAmount;
        vestingBegin = _vestingBegin;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address _recipient) external {
        require(msg.sender == recipient, "unauthorized");
        recipient = _recipient;
    }

    function vested() public view returns (uint256) {
        if (block.timestamp < vestingCliff) {
            return 0;
        }

        if (block.timestamp >= vestingEnd) {
            return IERC20(lon).balanceOf(address(this));
        } else {
            return vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd.sub(vestingBegin));
        }
    }

    function claim() external {
        require(block.timestamp >= vestingCliff, "not time yet");
        uint256 amount = vested();

        if (amount > 0) {
            lastUpdate = block.timestamp;
            IERC20(lon).transfer(recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./TreasuryVester.sol";

contract TreasuryVesterFactory {
    IERC20 public lon;

    event VesterCreated(address indexed vester, address indexed recipient, uint256 vestingAmount);

    constructor(IERC20 _lon) {
        lon = _lon;
    }

    function createVester(
        address recipient,
        uint256 vestingAmount,
        uint256 vestingBegin,
        uint256 vestingCliff,
        uint256 vestingEnd
    ) external returns (address) {
        require(vestingAmount > 0, "vesting amount is zero");

        address vester = address(new TreasuryVester(address(lon), recipient, vestingAmount, vestingBegin, vestingCliff, vestingEnd));

        lon.transferFrom(msg.sender, vester, vestingAmount);

        emit VesterCreated(vester, recipient, vestingAmount);

        return vester;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev No return value on approve, transfer, transferFrom. (USDT)
 */
contract MockNoReturnERC20 {
    using SafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public totalSupply;

    string public name = "MockNoReturnERC20";
    string public symbol = "MNRT";
    uint8 public decimals = 18;

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public {
        _approve(msg.sender, spender, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public {
        _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Burn a portion of tokens while transferring. (STA)
 */
contract MockDeflationaryERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public override totalSupply;

    string public name = "MockDeflationaryERC20";
    string public symbol = "MDT";
    uint8 public decimals = 18;

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 amountToBurn = amount.mul(1).div(100);
        uint256 amountToTransfer = amount.sub(amountToBurn);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountToTransfer);
        _balances[address(0)] = _balances[address(0)].add(amountToBurn);

        emit Transfer(sender, recipient, amountToTransfer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IEmergency.sol";
import "./interfaces/IEIP2612.sol";
import "./interfaces/IStakingRewards.sol";
import "./Ownable.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, IEmergency {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    address public emergencyRecipient;

    constructor(
        address _emergencyRecipient,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    ) {
        require(_rewardsDuration > 0, "rewards duration is 0");

        emergencyRecipient = _emergencyRecipient;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IEIP2612(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function emergencyWithdraw(IERC20 token) external override {
        require(address(token) != address(rewardsToken) && address(token) != address(stakingToken), "forbidden token");

        token.transfer(emergencyRecipient, token.balanceOf(address(this)));
    }

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEmergency {
    function emergencyWithdraw(IERC20 token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEIP2612 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract Ownable {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        owner = _owner;
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");
        emit OwnerChanged(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnerChanged(owner, address(0));
        owner = address(0);
    }

    function nominateNewOwner(address newOwner) external onlyOwner {
        nominatedOwner = newOwner;
        emit OwnerNominated(newOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "not rewards distribution");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/ILon.sol";
import "./Ownable.sol";

contract RewardDistributor is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    uint256 private constant MAX_UINT = 2**256 - 1;
    address public immutable LON_TOKEN_ADDR;

    // Below are the variables which consume storage slots.
    uint32 public buybackInterval;
    uint8 public miningFactor;
    uint8 public numStrategyAddr;
    uint8 public numExchangeAddr;

    mapping(address => bool) public isOperator;
    address public treasury;
    address public lonStaking;
    address public miningTreasury;
    address public feeTokenRecipient;

    mapping(uint256 => address) public strategyAddrs;
    mapping(uint256 => address) public exchangeAddrs;
    mapping(address => FeeToken) public feeTokens;

    /* Struct and event declaration */
    struct FeeToken {
        uint8 exchangeIndex;
        uint8 LFactor; // Percentage of fee token reserved for feeTokenRecipient
        uint8 RFactor; // Percentage of buyback-ed lon token for treasury
        uint32 lastTimeBuyback;
        bool enable;
        uint256 minBuy;
        uint256 maxBuy;
        address[] path;
    }

    // Owner events

    event SetOperator(address operator, bool enable);
    event SetMiningFactor(uint8 miningFactor);
    event SetTreasury(address treasury);
    event SetLonStaking(address lonStaking);
    event SetMiningTreasury(address miningTreasury);
    event SetFeeTokenRecipient(address feeTokenRecipient);
    // Operator events
    event SetBuybackInterval(uint256 interval);
    event SetStrategy(uint256 index, address strategy);
    event SetExchange(uint256 index, address exchange);
    event EnableFeeToken(address feeToken, bool enable);
    event SetFeeToken(address feeToken, uint256 exchangeIndex, address[] path, uint256 LFactor, uint256 RFactor, uint256 minBuy, uint256 maxBuy);
    event SetFeeTokenFailure(address feeToken, string reason, bytes lowLevelData);

    event BuyBack(address feeToken, uint256 feeTokenAmount, uint256 swappedLonAmount, uint256 LFactor, uint256 RFactor, uint256 minBuy, uint256 maxBuy);
    event BuyBackFailure(address feeToken, uint256 feeTokenAmount, string reason, bytes lowLevelData);
    event DistributeLon(uint256 treasuryAmount, uint256 lonStakingAmount);
    event MintLon(uint256 mintedAmount);
    event Recovered(address token, uint256 amount);

    /************************************************************
     *                      Access control                       *
     *************************************************************/
    modifier only_Operator_or_Owner() {
        require(_isAuthorized(msg.sender), "only operator or owner can call");
        _;
    }

    modifier only_Owner_or_Operator_or_Self() {
        if (msg.sender != address(this)) {
            require(_isAuthorized(msg.sender), "only operator or owner can call");
        }
        _;
    }

    modifier only_EOA() {
        require((msg.sender == tx.origin), "only EOA can call");
        _;
    }

    modifier only_EOA_or_Self() {
        if (msg.sender != address(this)) {
            require((msg.sender == tx.origin), "only EOA can call");
        }
        _;
    }

    /************************************************************
     *                       Constructor                         *
     *************************************************************/
    constructor(
        address _LON_TOKEN_ADDR,
        address _owner,
        address _operator,
        uint32 _buyBackInterval,
        uint8 _miningFactor,
        address _treasury,
        address _lonStaking,
        address _miningTreasury,
        address _feeTokenRecipient
    ) Ownable(_owner) {
        LON_TOKEN_ADDR = _LON_TOKEN_ADDR;

        isOperator[_operator] = true;

        buybackInterval = _buyBackInterval;

        require(_miningFactor <= 100, "incorrect mining factor");
        miningFactor = _miningFactor;

        require(Address.isContract(_lonStaking), "Lon staking is not a contract");
        treasury = _treasury;
        lonStaking = _lonStaking;
        miningTreasury = _miningTreasury;
        feeTokenRecipient = _feeTokenRecipient;
    }

    /************************************************************
     *                     Getter functions                      *
     *************************************************************/
    function getFeeTokenPath(address _feeTokenAddr) public view returns (address[] memory path) {
        return feeTokens[_feeTokenAddr].path;
    }

    /************************************************************
     *             Management functions for Owner                *
     *************************************************************/
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setOperator(address _operator, bool _enable) external onlyOwner {
        isOperator[_operator] = _enable;

        emit SetOperator(_operator, _enable);
    }

    function setMiningFactor(uint8 _miningFactor) external onlyOwner {
        require(_miningFactor <= 100, "incorrect mining factor");

        miningFactor = _miningFactor;
        emit SetMiningFactor(_miningFactor);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function setLonStaking(address _lonStaking) external onlyOwner {
        require(Address.isContract(_lonStaking), "Lon staking is not a contract");

        lonStaking = _lonStaking;
        emit SetLonStaking(_lonStaking);
    }

    function setMiningTreasury(address _miningTreasury) external onlyOwner {
        miningTreasury = _miningTreasury;
        emit SetMiningTreasury(_miningTreasury);
    }

    function setFeeTokenRecipient(address _feeTokenRecipient) external onlyOwner {
        feeTokenRecipient = _feeTokenRecipient;
        emit SetFeeTokenRecipient(_feeTokenRecipient);
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external only_Operator_or_Owner {
        IERC20(_tokenAddress).safeTransfer(owner, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function setBuybackInterval(uint32 _buyBackInterval) external only_Operator_or_Owner {
        require(_buyBackInterval >= 3600, "invalid buyback interval");

        buybackInterval = _buyBackInterval;
        emit SetBuybackInterval(_buyBackInterval);
    }

    function setStrategyAddrs(uint256[] calldata _indexes, address[] calldata _strategyAddrs) external only_Operator_or_Owner {
        require(_indexes.length == _strategyAddrs.length, "input not the same length");

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(Address.isContract(_strategyAddrs[i]), "strategy is not a contract");
            require(_indexes[i] <= numStrategyAddr, "index out of bound");

            strategyAddrs[_indexes[i]] = _strategyAddrs[i];
            if (_indexes[i] == numStrategyAddr) numStrategyAddr++;
            emit SetStrategy(_indexes[i], _strategyAddrs[i]);
        }
    }

    function setExchangeAddrs(uint256[] calldata _indexes, address[] calldata _exchangeAddrs) external only_Operator_or_Owner {
        require(_indexes.length == _exchangeAddrs.length, "input not the same length");

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(Address.isContract(_exchangeAddrs[i]), "exchange is not a contract");
            require(_indexes[i] <= numExchangeAddr, "index out of bound");

            exchangeAddrs[_indexes[i]] = _exchangeAddrs[i];
            if (_indexes[i] == numExchangeAddr) numExchangeAddr++;
            emit SetExchange(_indexes[i], _exchangeAddrs[i]);
        }
    }

    function setFeeToken(
        address _feeTokenAddr,
        uint8 _exchangeIndex,
        address[] calldata _path,
        uint8 _LFactor,
        uint8 _RFactor,
        bool _enable,
        uint256 _minBuy,
        uint256 _maxBuy
    ) external only_Owner_or_Operator_or_Self {
        // Validate fee token inputs
        require(Address.isContract(_feeTokenAddr), "fee token is not a contract");
        require(Address.isContract(exchangeAddrs[_exchangeIndex]), "exchange is not a contract");
        require(_path.length >= 2, "invalid swap path");
        require(_path[_path.length - 1] == LON_TOKEN_ADDR, "output token must be LON");
        require(_LFactor <= 100, "incorrect LFactor");
        require(_RFactor <= 100, "incorrect RFactor");
        require(_minBuy <= _maxBuy, "incorrect minBuy and maxBuy");

        FeeToken storage feeToken = feeTokens[_feeTokenAddr];
        feeToken.exchangeIndex = _exchangeIndex;
        feeToken.path = _path;
        feeToken.LFactor = _LFactor;
        feeToken.RFactor = _RFactor;
        if (feeToken.enable != _enable) {
            feeToken.enable = _enable;
            emit EnableFeeToken(_feeTokenAddr, _enable);
        }
        feeToken.minBuy = _minBuy;
        feeToken.maxBuy = _maxBuy;
        emit SetFeeToken(_feeTokenAddr, _exchangeIndex, _path, _LFactor, _RFactor, _minBuy, _maxBuy);
    }

    function setFeeTokens(
        address[] memory _feeTokenAddr,
        uint8[] memory _exchangeIndex,
        address[][] memory _path,
        uint8[] memory _LFactor,
        uint8[] memory _RFactor,
        bool[] memory _enable,
        uint256[] memory _minBuy,
        uint256[] memory _maxBuy
    ) external only_Operator_or_Owner {
        uint256 inputLength = _feeTokenAddr.length;
        require(
            (_exchangeIndex.length == inputLength) &&
                (_path.length == inputLength) &&
                (_LFactor.length == inputLength) &&
                (_RFactor.length == inputLength) &&
                (_enable.length == inputLength) &&
                (_minBuy.length == inputLength) &&
                (_maxBuy.length == inputLength),
            "input not the same length"
        );

        for (uint256 i = 0; i < inputLength; i++) {
            try this.setFeeToken(_feeTokenAddr[i], _exchangeIndex[i], _path[i], _LFactor[i], _RFactor[i], _enable[i], _minBuy[i], _maxBuy[i]) {
                continue;
            } catch Error(string memory reason) {
                emit SetFeeTokenFailure(_feeTokenAddr[i], reason, bytes(""));
            } catch (bytes memory lowLevelData) {
                emit SetFeeTokenFailure(_feeTokenAddr[i], "", lowLevelData);
            }
        }
    }

    function enableFeeToken(address _feeTokenAddr, bool _enable) external only_Operator_or_Owner {
        FeeToken storage feeToken = feeTokens[_feeTokenAddr];
        if (feeToken.enable != _enable) {
            feeToken.enable = _enable;
            emit EnableFeeToken(_feeTokenAddr, _enable);
        }
    }

    function enableFeeTokens(address[] calldata _feeTokenAddr, bool[] calldata _enable) external only_Operator_or_Owner {
        require(_feeTokenAddr.length == _enable.length, "input not the same length");

        for (uint256 i = 0; i < _feeTokenAddr.length; i++) {
            FeeToken storage feeToken = feeTokens[_feeTokenAddr[i]];
            if (feeToken.enable != _enable[i]) {
                feeToken.enable = _enable[i];
                emit EnableFeeToken(_feeTokenAddr[i], _enable[i]);
            }
        }
    }

    function _isAuthorized(address _account) internal view returns (bool) {
        if ((isOperator[_account]) || (_account == owner)) return true;
        else return false;
    }

    function _validate(FeeToken memory _feeToken, uint256 _amount) internal view returns (uint256 amountFeeTokenToSwap, uint256 amountFeeTokenToTransfer) {
        require(_amount > 0, "zero fee token amount");
        if (!_isAuthorized(msg.sender)) {
            require(_feeToken.enable, "fee token is not enabled");
        }

        amountFeeTokenToTransfer = _amount.mul(_feeToken.LFactor).div(100);
        amountFeeTokenToSwap = _amount.sub(amountFeeTokenToTransfer);

        if (amountFeeTokenToSwap > 0) {
            require(amountFeeTokenToSwap >= _feeToken.minBuy, "amount less than min buy");
            require(amountFeeTokenToSwap <= _feeToken.maxBuy, "amount greater than max buy");
            require(block.timestamp > uint256(_feeToken.lastTimeBuyback).add(uint256(buybackInterval)), "already a buyback recently");
        }
    }

    function _transferFeeToken(
        address _feeTokenAddr,
        address _transferTo,
        uint256 _totalFeeTokenAmount
    ) internal {
        address strategyAddr;
        uint256 balanceInStrategy;
        uint256 amountToTransferFrom;
        uint256 cumulatedAmount;
        for (uint256 i = 0; i < numStrategyAddr; i++) {
            strategyAddr = strategyAddrs[i];
            balanceInStrategy = IERC20(_feeTokenAddr).balanceOf(strategyAddr);
            if (cumulatedAmount.add(balanceInStrategy) > _totalFeeTokenAmount) {
                amountToTransferFrom = _totalFeeTokenAmount.sub(cumulatedAmount);
            } else {
                amountToTransferFrom = balanceInStrategy;
            }
            if (amountToTransferFrom == 0) continue;
            IERC20(_feeTokenAddr).safeTransferFrom(strategyAddr, _transferTo, amountToTransferFrom);

            cumulatedAmount = cumulatedAmount.add(amountToTransferFrom);
            if (cumulatedAmount == _totalFeeTokenAmount) break;
        }
        require(cumulatedAmount == _totalFeeTokenAmount, "insufficient amount of fee tokens");
    }

    function _swap(
        address _feeTokenAddr,
        address _exchangeAddr,
        address[] memory _path,
        uint256 _amountFeeTokenToSwap,
        uint256 _minLonAmount
    ) internal returns (uint256 swappedLonAmount) {
        // Approve exchange contract
        IERC20(_feeTokenAddr).safeApprove(_exchangeAddr, MAX_UINT);

        // Swap fee token for Lon
        IUniswapRouterV2 router = IUniswapRouterV2(_exchangeAddr);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            _amountFeeTokenToSwap,
            _minLonAmount, // Minimum amount of Lon expected to receive
            _path,
            address(this),
            block.timestamp + 60
        );
        swappedLonAmount = amounts[_path.length - 1];

        // Clear allowance for exchange contract
        IERC20(_feeTokenAddr).safeApprove(_exchangeAddr, 0);
    }

    function _distributeLon(FeeToken memory _feeToken, uint256 swappedLonAmount) internal {
        // To Treasury
        uint256 treasuryAmount = swappedLonAmount.mul(_feeToken.RFactor).div(100);
        if (treasuryAmount > 0) {
            IERC20(LON_TOKEN_ADDR).safeTransfer(treasury, treasuryAmount);
        }

        // To LonStaking
        uint256 lonStakingAmount = swappedLonAmount.sub(treasuryAmount);
        if (lonStakingAmount > 0) {
            IERC20(LON_TOKEN_ADDR).safeTransfer(lonStaking, lonStakingAmount);
        }

        emit DistributeLon(treasuryAmount, lonStakingAmount);
    }

    function _mintLon(uint256 swappedLonAmount) internal {
        // Mint Lon for MiningTreasury
        uint256 mintedAmount = swappedLonAmount.mul(uint256(miningFactor)).div(100);
        if (mintedAmount > 0) {
            ILon(LON_TOKEN_ADDR).mint(miningTreasury, mintedAmount);
            emit MintLon(mintedAmount);
        }
    }

    function _buyback(
        address _feeTokenAddr,
        FeeToken storage _feeToken,
        address _exchangeAddr,
        uint256 _amountFeeTokenToSwap,
        uint256 _minLonAmount
    ) internal {
        if (_amountFeeTokenToSwap > 0) {
            uint256 swappedLonAmount = _swap(_feeTokenAddr, _exchangeAddr, _feeToken.path, _amountFeeTokenToSwap, _minLonAmount);

            // Update fee token data
            _feeToken.lastTimeBuyback = uint32(block.timestamp);

            emit BuyBack(_feeTokenAddr, _amountFeeTokenToSwap, swappedLonAmount, _feeToken.LFactor, _feeToken.RFactor, _feeToken.minBuy, _feeToken.maxBuy);

            _distributeLon(_feeToken, swappedLonAmount);
            _mintLon(swappedLonAmount);
        }
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    function buyback(
        address _feeTokenAddr,
        uint256 _amount,
        uint256 _minLonAmount
    ) external whenNotPaused only_EOA_or_Self {
        FeeToken storage feeToken = feeTokens[_feeTokenAddr];

        // Distribute LON directly without swap
        if (_feeTokenAddr == LON_TOKEN_ADDR) {
            require(feeToken.enable, "fee token is not enabled");
            require(_amount >= feeToken.minBuy, "amount less than min buy");
            uint256 _lonToTreasury = _amount.mul(feeToken.RFactor).div(100);
            uint256 _lonToStaking = _amount.sub(_lonToTreasury);
            _transferFeeToken(LON_TOKEN_ADDR, treasury, _lonToTreasury);
            _transferFeeToken(LON_TOKEN_ADDR, lonStaking, _lonToStaking);
            emit DistributeLon(_lonToTreasury, _lonToStaking);
            _mintLon(_amount);

            // Update lastTimeBuyback
            feeToken.lastTimeBuyback = uint32(block.timestamp);
            return;
        }

        // Validate fee token data and input amount
        (uint256 amountFeeTokenToSwap, uint256 amountFeeTokenToTransfer) = _validate(feeToken, _amount);

        if (amountFeeTokenToSwap == 0) {
            // No need to swap, transfer feeToken directly
            _transferFeeToken(_feeTokenAddr, feeTokenRecipient, amountFeeTokenToTransfer);
        } else {
            // Transfer fee token from strategy contracts to distributor
            _transferFeeToken(_feeTokenAddr, address(this), _amount);

            // Buyback
            _buyback(_feeTokenAddr, feeToken, exchangeAddrs[feeToken.exchangeIndex], amountFeeTokenToSwap, _minLonAmount);

            // Transfer fee token from distributor to feeTokenRecipient
            if (amountFeeTokenToTransfer > 0) {
                IERC20(_feeTokenAddr).safeTransfer(feeTokenRecipient, amountFeeTokenToTransfer);
            }
        }
    }

    function batchBuyback(
        address[] calldata _feeTokenAddr,
        uint256[] calldata _amount,
        uint256[] calldata _minLonAmount
    ) external whenNotPaused only_EOA {
        uint256 inputLength = _feeTokenAddr.length;
        require((_amount.length == inputLength) && (_minLonAmount.length == inputLength), "input not the same length");

        for (uint256 i = 0; i < inputLength; i++) {
            try this.buyback(_feeTokenAddr[i], _amount[i], _minLonAmount[i]) {
                continue;
            } catch Error(string memory reason) {
                emit BuyBackFailure(_feeTokenAddr[i], _amount[i], reason, bytes(""));
            } catch (bytes memory lowLevelData) {
                emit BuyBackFailure(_feeTokenAddr[i], _amount[i], "", lowLevelData);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IUniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IEmergency.sol";
import "./IEIP2612.sol";

interface ILon is IEmergency, IEIP2612 {
    function cap() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/* Modified from SushiBar contract: https://etherscan.io/address/0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272#code */
/* Added with AAVE StakedToken's cooldown feature: https://etherscan.io/address/0x74a7a4e7566a2f523986e500ce35b20d343f6741#code */

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/ILon.sol";
import "./upgradeable/ERC20ForUpgradeable.sol";
import "./upgradeable/OwnableForUpgradeable.sol";

contract LONStaking is ERC20ForUpgradeable, OwnableForUpgradeable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ILon;
    using SafeERC20 for IERC20;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    uint256 private constant BPS_MAX = 10000;

    ILon public lonToken;
    bytes32 public DOMAIN_SEPARATOR;
    uint256 public BPS_RAGE_EXIT_PENALTY;
    uint256 public COOLDOWN_SECONDS;
    uint256 public COOLDOWN_IN_DAYS;
    mapping(address => uint256) public nonces; // For EIP-2612 permit()
    mapping(address => uint256) public stakersCooldowns;

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount, uint256 share);
    event Cooldown(address indexed user);
    event Redeem(address indexed user, uint256 share, uint256 redeemAmount, uint256 penaltyAmount);
    event Recovered(address token, uint256 amount);
    event SetCooldownAndRageExitParam(uint256 coolDownInDays, uint256 bpsRageExitPenalty);

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        ILon _lonToken,
        address _owner,
        uint256 _COOLDOWN_IN_DAYS,
        uint256 _BPS_RAGE_EXIT_PENALTY
    ) external {
        lonToken = _lonToken;

        _initializeOwnable(_owner);
        _initializeERC20("Wrapped Tokenlon", "xLON");

        require(_COOLDOWN_IN_DAYS >= 1, "COOLDOWN_IN_DAYS less than 1 day");
        require(_BPS_RAGE_EXIT_PENALTY <= BPS_MAX, "BPS_RAGE_EXIT_PENALTY larger than BPS_MAX");
        COOLDOWN_IN_DAYS = _COOLDOWN_IN_DAYS;
        COOLDOWN_SECONDS = _COOLDOWN_IN_DAYS * 86400;
        BPS_RAGE_EXIT_PENALTY = _BPS_RAGE_EXIT_PENALTY;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setCooldownAndRageExitParam(uint256 _COOLDOWN_IN_DAYS, uint256 _BPS_RAGE_EXIT_PENALTY) public onlyOwner {
        require(_COOLDOWN_IN_DAYS >= 1, "COOLDOWN_IN_DAYS less than 1 day");
        require(_BPS_RAGE_EXIT_PENALTY <= BPS_MAX, "BPS_RAGE_EXIT_PENALTY larger than BPS_MAX");

        COOLDOWN_IN_DAYS = _COOLDOWN_IN_DAYS;
        COOLDOWN_SECONDS = _COOLDOWN_IN_DAYS * 86400;
        BPS_RAGE_EXIT_PENALTY = _BPS_RAGE_EXIT_PENALTY;
        emit SetCooldownAndRageExitParam(_COOLDOWN_IN_DAYS, _BPS_RAGE_EXIT_PENALTY);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(lonToken), "cannot withdraw lon token");
        IERC20(_tokenAddress).safeTransfer(owner, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /* ========== VIEWS ========== */

    function cooldownRemainSeconds(address _account) external view returns (uint256) {
        uint256 cooldownTimestamp = stakersCooldowns[_account];
        if ((cooldownTimestamp == 0) || (cooldownTimestamp.add(COOLDOWN_SECONDS) <= block.timestamp)) return 0;

        return cooldownTimestamp.add(COOLDOWN_SECONDS).sub(block.timestamp);
    }

    function previewRageExit(address _account) external view returns (uint256 receiveAmount, uint256 penaltyAmount) {
        uint256 cooldownEndTimestamp = stakersCooldowns[_account].add(COOLDOWN_SECONDS);
        uint256 totalLon = lonToken.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        uint256 share = balanceOf(_account);
        uint256 userTotalAmount = share.mul(totalLon).div(totalShares);

        if (block.timestamp > cooldownEndTimestamp) {
            // Normal redeem if cooldown period already passed
            receiveAmount = userTotalAmount;
            penaltyAmount = 0;
        } else {
            uint256 timeDiffInDays = Math.min(COOLDOWN_IN_DAYS, (cooldownEndTimestamp.sub(block.timestamp)).div(86400).add(1));
            // Penalty share = share * (number_of_days_to_cooldown_end / number_of_days_in_cooldown) * (BPS_RAGE_EXIT_PENALTY / BPS_MAX)
            uint256 penaltyShare = share.mul(timeDiffInDays).mul(BPS_RAGE_EXIT_PENALTY).div(BPS_MAX).div(COOLDOWN_IN_DAYS);
            receiveAmount = share.sub(penaltyShare).mul(totalLon).div(totalShares);
            penaltyAmount = userTotalAmount.sub(receiveAmount);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _getNextCooldownTimestamp(
        uint256 _fromCooldownTimestamp,
        uint256 _amountToReceive,
        address _toAddress,
        uint256 _toBalance
    ) internal returns (uint256) {
        uint256 toCooldownTimestamp = stakersCooldowns[_toAddress];
        if (toCooldownTimestamp == 0) {
            return 0;
        }

        uint256 fromCooldownTimestamp;
        // If sent from user who has not unstake, set fromCooldownTimestamp to current block timestamp,
        // i.e., pretend the user just unstake now.
        // This is to prevent user from bypassing cooldown by transferring to an already unstaked account.
        if (_fromCooldownTimestamp == 0) {
            fromCooldownTimestamp = block.timestamp;
        } else {
            fromCooldownTimestamp = _fromCooldownTimestamp;
        }

        // If `to` account has greater timestamp, i.e., `to` has to wait longer, the timestamp remains the same.
        if (fromCooldownTimestamp <= toCooldownTimestamp) {
            return toCooldownTimestamp;
        } else {
            // Otherwise, count in `from` account's timestamp to derive `to` account's new timestamp.

            // If the period between `from` and `to` account is greater than COOLDOWN_SECONDS,
            // reduce the period to COOLDOWN_SECONDS.
            // This is to prevent user from bypassing cooldown by early unstake with `to` account
            // and enjoy free cooldown bonus while waiting for `from` account to unstake.
            if (fromCooldownTimestamp.sub(toCooldownTimestamp) > COOLDOWN_SECONDS) {
                toCooldownTimestamp = fromCooldownTimestamp.sub(COOLDOWN_SECONDS);
            }

            toCooldownTimestamp = (_amountToReceive.mul(fromCooldownTimestamp).add(_toBalance.mul(toCooldownTimestamp))).div(_amountToReceive.add(_toBalance));
            return toCooldownTimestamp;
        }
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override whenNotPaused {
        uint256 balanceOfFrom = balanceOf(_from);
        uint256 balanceOfTo = balanceOf(_to);
        uint256 previousSenderCooldown = stakersCooldowns[_from];
        if (_from != _to) {
            stakersCooldowns[_to] = _getNextCooldownTimestamp(previousSenderCooldown, _amount, _to, balanceOfTo);
            // if cooldown was set and whole balance of sender was transferred - clear cooldown
            if (balanceOfFrom == _amount && previousSenderCooldown != 0) {
                stakersCooldowns[_from] = 0;
            }
        }

        super._transfer(_from, _to, _amount);
    }

    // EIP-2612 permit standard
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_owner != address(0), "owner is zero address");
        require(block.timestamp <= _deadline || _deadline == 0, "permit expired");

        bytes32 digest = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _deadline)))
        );

        require(_owner == ecrecover(digest, _v, _r, _s), "invalid signature");
        _approve(_owner, _spender, _value);
    }

    function _stake(address _account, uint256 _amount) internal {
        require(_amount > 0, "cannot stake 0 amount");

        // Mint xLON according to current share and Lon amount
        uint256 totalLon = lonToken.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        uint256 share;
        if (totalShares == 0 || totalLon == 0) {
            share = _amount;
        } else {
            share = _amount.mul(totalShares).div(totalLon);
        }
        // Update staker's Cooldown timestamp
        stakersCooldowns[_account] = _getNextCooldownTimestamp(block.timestamp, share, _account, balanceOf(_account));

        _mint(_account, share);
        emit Staked(_account, _amount, share);
    }

    function stake(uint256 _amount) public nonReentrant whenNotPaused {
        _stake(msg.sender, _amount);
        lonToken.transferFrom(msg.sender, address(this), _amount);
    }

    function stakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant whenNotPaused {
        _stake(msg.sender, _amount);
        // Use permit to allow LONStaking contract to transferFrom user
        lonToken.permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        lonToken.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake() public {
        require(balanceOf(msg.sender) > 0, "no share to unstake");
        require(stakersCooldowns[msg.sender] == 0, "already unstake");

        stakersCooldowns[msg.sender] = block.timestamp;
        emit Cooldown(msg.sender);
    }

    function _redeem(uint256 _share, uint256 _penalty) internal {
        require(_share != 0, "cannot redeem 0 share");

        uint256 totalLon = lonToken.balanceOf(address(this));
        uint256 totalShares = totalSupply();

        uint256 userTotalAmount = _share.add(_penalty).mul(totalLon).div(totalShares);
        uint256 redeemAmount = _share.mul(totalLon).div(totalShares);
        uint256 penaltyAmount = userTotalAmount.sub(redeemAmount);
        _burn(msg.sender, _share.add(_penalty));
        if (balanceOf(msg.sender) == 0) {
            stakersCooldowns[msg.sender] = 0;
        }

        lonToken.transfer(msg.sender, redeemAmount);

        emit Redeem(msg.sender, _share, redeemAmount, penaltyAmount);
    }

    function redeem(uint256 _share) public nonReentrant {
        uint256 cooldownStartTimestamp = stakersCooldowns[msg.sender];
        require(cooldownStartTimestamp > 0, "not yet unstake");

        require(block.timestamp > cooldownStartTimestamp.add(COOLDOWN_SECONDS), "Still in cooldown");

        _redeem(_share, 0);
    }

    function rageExit() public nonReentrant {
        uint256 cooldownStartTimestamp = stakersCooldowns[msg.sender];
        require(cooldownStartTimestamp > 0, "not yet unstake");

        uint256 cooldownEndTimestamp = cooldownStartTimestamp.add(COOLDOWN_SECONDS);
        uint256 share = balanceOf(msg.sender);
        if (block.timestamp > cooldownEndTimestamp) {
            // Normal redeem if cooldown period already passed
            _redeem(share, 0);
        } else {
            uint256 timeDiffInDays = Math.min(COOLDOWN_IN_DAYS, (cooldownEndTimestamp.sub(block.timestamp)).div(86400).add(1));
            // Penalty = share * (number_of_days_to_cooldown_end / number_of_days_in_cooldown) * (BPS_RAGE_EXIT_PENALTY / BPS_MAX)
            uint256 penalty = share.mul(timeDiffInDays).mul(BPS_RAGE_EXIT_PENALTY).div(BPS_MAX).div(COOLDOWN_IN_DAYS);
            _redeem(share.sub(penalty), penalty);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

/* Copied and modifier from openzepplin ERC20 contract to replace constructor with initialize function*/

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20ForUpgradeable is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function _initializeERC20(string memory name_, string memory symbol_) internal {
        require(
            (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(""))) &&
                (keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(""))),
            "ERC20 already initialized"
        );

        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract OwnableForUpgradeable {
    address public owner;
    address public nominatedOwner;

    function _initializeOwnable(address _owner) internal {
        require(owner == address(0), "Ownable already initialized");

        owner = _owner;
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");
        emit OwnerChanged(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnerChanged(owner, address(0));
        owner = address(0);
    }

    function nominateNewOwner(address newOwner) external onlyOwner {
        nominatedOwner = newOwner;
        emit OwnerNominated(newOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
}

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWETH is ERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad);
        _burn(msg.sender, wad);
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Return false instead of reverting when transfer allownace or balance is not enough. (ZRX)
 */
contract MockNoRevertERC20 is ERC20 {
    constructor() ERC20("MockNoRevertERC20", "MNRVT") {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (balanceOf(msg.sender) < amount) {
            return false;
        }
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (balanceOf(msg.sender) < amount || allowance(sender, msg.sender) < amount) {
            return false;
        }
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance(sender, msg.sender) - amount);
        return true;
    }
}

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ILon.sol";
import "./Ownable.sol";

contract Lon is ERC20, ILon, Ownable {
    using SafeMath for uint256;

    uint256 public constant override cap = 200_000_000e18; // CAP is 200,000,000 LON

    bytes32 public immutable override DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    address public emergencyRecipient;

    address public minter;

    mapping(address => uint256) public override nonces;

    constructor(address _owner, address _emergencyRecipient) ERC20("Tokenlon", "LON") Ownable(_owner) {
        minter = _owner;
        emergencyRecipient = _emergencyRecipient;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "not minter");
        _;
    }

    // implement the eip-2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0), "zero address");
        require(block.timestamp <= deadline || deadline == 0, "permit is expired");

        bytes32 digest = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)))
        );

        require(owner == ecrecover(digest, v, r, s), "invalid signature");
        _approve(owner, spender, value);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function emergencyWithdraw(IERC20 token) external override {
        token.transfer(emergencyRecipient, token.balanceOf(address(this)));
    }

    function setMinter(address newMinter) external onlyOwner {
        emit MinterChanged(minter, newMinter);
        minter = newMinter;
    }

    function mint(address to, uint256 amount) external override onlyMinter {
        require(to != address(0), "zero address");
        require(totalSupply().add(amount) <= cap, "cap exceeded");

        _mint(to, amount);
    }

    event MinterChanged(address minter, address newMinter);
}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IRFQ.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IERC1271Wallet.sol";
import "./utils/RFQLibEIP712.sol";
import "./utils/BaseLibEIP712.sol";
import "./utils/SignatureValidator.sol";

contract RFQ is IRFQ, ReentrancyGuard, SignatureValidator, BaseLibEIP712 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Constants do not have storage slot.
    string public constant version = "5.2.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    string public constant SOURCE = "RFQ v1";
    uint256 private constant BPS_MAX = 10000;
    address public immutable userProxy;
    IPermanentStorage public immutable permStorage;
    IWETH public immutable weth;

    // Below are the variables which consume storage slots.
    address public operator;
    ISpender public spender;

    struct GroupedVars {
        bytes32 orderHash;
        bytes32 transactionHash;
    }

    // Operator events
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);

    event FillOrder(
        string source,
        bytes32 indexed transactionHash,
        bytes32 indexed orderHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint16 feeFactor
    );

    receive() external payable {}

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "RFQ: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "RFQ: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "RFQ: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _operator,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth
    ) {
        operator = _operator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/
    /**
     * @dev set new Spender
     */
    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "RFQ: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{ value: balance }();

            emit DepositETH(balance);
        }
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    function fill(
        RFQLibEIP712.Order calldata _order,
        bytes calldata _mmSignature,
        bytes calldata _userSignature
    ) external payable override nonReentrant onlyUserProxy returns (uint256) {
        // check the order deadline and fee factor
        require(_order.deadline >= block.timestamp, "RFQ: expired order");
        require(_order.feeFactor < BPS_MAX, "RFQ: invalid fee factor");

        GroupedVars memory vars;

        // Validate signatures
        vars.orderHash = RFQLibEIP712._getOrderHash(_order);
        require(isValidSignature(_order.makerAddr, getEIP712Hash(vars.orderHash), bytes(""), _mmSignature), "RFQ: invalid MM signature");
        vars.transactionHash = RFQLibEIP712._getTransactionHash(_order);
        require(isValidSignature(_order.takerAddr, getEIP712Hash(vars.transactionHash), bytes(""), _userSignature), "RFQ: invalid user signature");

        // Set transaction as seen, PermanentStorage would throw error if transaction already seen.
        permStorage.setRFQTransactionSeen(vars.transactionHash);

        // Deposit to WETH if taker asset is ETH, else transfer from user
        if (address(weth) == _order.takerAssetAddr) {
            require(msg.value == _order.takerAssetAmount, "RFQ: insufficient ETH");
            weth.deposit{ value: msg.value }();
        } else {
            spender.spendFromUser(_order.takerAddr, _order.takerAssetAddr, _order.takerAssetAmount);
        }
        // Transfer from maker
        spender.spendFromUser(_order.makerAddr, _order.makerAssetAddr, _order.makerAssetAmount);

        // settle token/ETH to user
        return _settle(_order, vars);
    }

    // settle
    function _settle(RFQLibEIP712.Order memory _order, GroupedVars memory _vars) internal returns (uint256) {
        // Transfer taker asset to maker
        IERC20(_order.takerAssetAddr).safeTransfer(_order.makerAddr, _order.takerAssetAmount);

        // Transfer maker asset to taker, sub fee
        uint256 settleAmount = _order.makerAssetAmount;
        if (_order.feeFactor > 0) {
            // settleAmount = settleAmount * (10000 - feeFactor) / 10000
            settleAmount = settleAmount.mul((BPS_MAX).sub(_order.feeFactor)).div(BPS_MAX);
        }

        // Transfer token/Eth to receiver
        if (_order.makerAssetAddr == address(weth)) {
            weth.withdraw(settleAmount);
            payable(_order.receiverAddr).transfer(settleAmount);
        } else {
            IERC20(_order.makerAssetAddr).safeTransfer(_order.receiverAddr, settleAmount);
        }

        emit FillOrder(
            SOURCE,
            _vars.transactionHash,
            _vars.orderHash,
            _order.takerAddr,
            _order.takerAssetAddr,
            _order.takerAssetAmount,
            _order.makerAddr,
            _order.makerAssetAddr,
            _order.makerAssetAmount,
            _order.receiverAddr,
            settleAmount,
            uint16(_order.feeFactor)
        );

        return settleAmount;
    }
}

pragma solidity >=0.7.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

pragma solidity >=0.7.0;
pragma abicoder v2;

import "./ISetAllowance.sol";
import "../utils/RFQLibEIP712.sol";

interface IRFQ is ISetAllowance {
    function fill(
        RFQLibEIP712.Order memory _order,
        bytes memory _mmSignature,
        bytes memory _userSignature
    ) external payable returns (uint256);
}

pragma solidity >=0.7.0;

interface IPermanentStorage {
    function wethAddr() external view returns (address);

    function getCurvePoolInfo(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr
    )
        external
        view
        returns (
            int128 takerAssetIndex,
            int128 makerAssetIndex,
            uint16 swapMethod,
            bool supportGetDx
        );

    function setCurvePoolInfo(
        address _makerAddr,
        address[] calldata _underlyingCoins,
        address[] calldata _coins,
        bool _supportGetDx
    ) external;

    function isTransactionSeen(bytes32 _transactionHash) external view returns (bool); // Kept for backward compatability. Should be removed from AMM 5.2.1 upward

    function isAMMTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isRFQTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isLimitOrderTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isLimitOrderAllowFillSeen(bytes32 _allowFillHash) external view returns (bool);

    function isRelayerValid(address _relayer) external view returns (bool);

    function setTransactionSeen(bytes32 _transactionHash) external; // Kept for backward compatability. Should be removed from AMM 5.2.1 upward

    function setAMMTransactionSeen(bytes32 _transactionHash) external;

    function setRFQTransactionSeen(bytes32 _transactionHash) external;

    function setLimitOrderTransactionSeen(bytes32 _transactionHash) external;

    function setLimitOrderAllowFillSeen(bytes32 _allowFillHash) external;

    function setRelayersValid(address[] memory _relayers, bool[] memory _isValids) external;
}

pragma solidity >=0.7.0;

interface IERC1271Wallet {
    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided data
     * @dev MUST return the correct magic value if the signature provided is valid for the provided data
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _data       Arbitrary length data signed on the behalf of address(this)
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     *
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4 magicValue);

    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided hash
     * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _hash       keccak256 hash that was signed
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library RFQLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    struct Order {
        address takerAddr;
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address receiverAddr;
        uint256 salt;
        uint256 deadline;
        uint256 feeFactor;
    }

    bytes32 public constant ORDER_TYPEHASH = 0xad84a47ecda74707b63cf430860b59806332525ed81c01c6e3ec66983c35646a;

    /*
        keccak256(
            abi.encodePacked(
                "Order(",
                "address takerAddr,",
                "address makerAddr,",
                "address takerAssetAddr,",
                "address makerAssetAddr,",
                "uint256 takerAssetAmount,",
                "uint256 makerAssetAmount,",
                "uint256 salt,",
                "uint256 deadline,",
                "uint256 feeFactor",
                ")"
            )
        );
        */

    function _getOrderHash(Order memory _order) internal pure returns (bytes32 orderHash) {
        orderHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                _order.takerAddr,
                _order.makerAddr,
                _order.takerAssetAddr,
                _order.makerAssetAddr,
                _order.takerAssetAmount,
                _order.makerAssetAmount,
                _order.salt,
                _order.deadline,
                _order.feeFactor
            )
        );
    }

    bytes32 public constant FILL_WITH_PERMIT_TYPEHASH = 0x4ea663383968865a4516f51bec2c29addd1e7cecce5583296a44cc8d568cad09;

    /*
        keccak256(
            abi.encodePacked(
                "fillWithPermit(",
                "address makerAddr,",
                "address takerAssetAddr,",
                "address makerAssetAddr,",
                "uint256 takerAssetAmount,",
                "uint256 makerAssetAmount,",
                "address takerAddr,",
                "address receiverAddr,",
                "uint256 salt,",
                "uint256 deadline,",
                "uint256 feeFactor",
                ")"
            )
        );
        */

    function _getTransactionHash(Order memory _order) internal pure returns (bytes32 transactionHash) {
        transactionHash = keccak256(
            abi.encode(
                FILL_WITH_PERMIT_TYPEHASH,
                _order.makerAddr,
                _order.takerAssetAddr,
                _order.makerAssetAddr,
                _order.takerAssetAmount,
                _order.makerAssetAmount,
                _order.takerAddr,
                _order.receiverAddr,
                _order.salt,
                _order.deadline,
                _order.feeFactor
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract BaseLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                getChainID(),
                address(this)
            )
        );

    /**
     * @dev Return `chainId`
     */
    function getChainID() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_SEPARATOR, structHash));
    }
}

pragma solidity 0.7.6;

import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";

interface IWallet {
    /// @dev Verifies that a signature is valid.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return isValid Validity of order signature.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bool isValid);
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator {
    using LibBytes for bytes;

    /***********************************|
  |             Variables             |
  |__________________________________*/

    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

    // keccak256("isValidWalletSignature(bytes32,address,bytes)")
    bytes4 internal constant ERC1271_FALLBACK_MAGICVALUE_BYTES32 = 0xb0671381;

    // Allowed signature types.
    enum SignatureType {
        Illegal, // 0x00, default value
        Invalid, // 0x01
        EIP712, // 0x02
        EthSign, // 0x03
        WalletBytes, // 0x04  standard 1271 wallet type
        WalletBytes32, // 0x05  standard 1271 wallet type
        Wallet, // 0x06  0x wallet type for signature compatibility
        NSignatureTypes // 0x07, number of signature types. Always leave at end.
    }

    /***********************************|
  |        Signature Functions        |
  |__________________________________*/

    /**
     * @dev Verifies that a hash has been signed by the given signer.
     * @param _signerAddress  Address that should have signed the given hash.
     * @param _hash           Hash of the EIP-712 encoded data
     * @param _data           Full EIP-712 data structure that was hashed and signed
     * @param _sig            Proof that the hash has been signed by signer.
     *      For non wallet signatures, _sig is expected to be an array tightly encoded as
     *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
     * @return isValid True if the address recovered from the provided signature matches the input signer address.
     */
    function isValidSignature(
        address _signerAddress,
        bytes32 _hash,
        bytes memory _data,
        bytes memory _sig
    ) public view returns (bool isValid) {
        require(_sig.length > 0, "SignatureValidator#isValidSignature: length greater than 0 required");

        require(_signerAddress != address(0x0), "SignatureValidator#isValidSignature: invalid signer");

        // Pop last byte off of signature byte array.
        uint8 signatureTypeRaw = uint8(_sig.popLastByte());

        // Ensure signature is supported
        require(signatureTypeRaw < uint8(SignatureType.NSignatureTypes), "SignatureValidator#isValidSignature: unsupported signature");

        // Extract signature type
        SignatureType signatureType = SignatureType(signatureTypeRaw);

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            revert("SignatureValidator#isValidSignature: illegal signature");

            // Signature using EIP712
        } else if (signatureType == SignatureType.EIP712) {
            require(_sig.length == 97, "SignatureValidator#isValidSignature: length 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(_hash, v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signed using web3.eth_sign() or Ethers wallet.signMessage()
        } else if (signatureType == SignatureType.EthSign) {
            require(_sig.length == 97, "SignatureValidator#isValidSignature: length 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signature verified by wallet contract with data validation.
        } else if (signatureType == SignatureType.WalletBytes) {
            isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
            return isValid;

            // Signature verified by wallet contract without data validation.
        } else if (signatureType == SignatureType.WalletBytes32) {
            isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
            return isValid;
        } else if (signatureType == SignatureType.Wallet) {
            isValid = isValidWalletSignature(_hash, _signerAddress, _sig);
            return isValid;
        }

        // Anything else is illegal (We do not return false because
        // the signature may actually be valid, just not in a format
        // that we currently support. In this case returning false
        // may lead the caller to incorrectly believe that the
        // signature was invalid.)
        revert("SignatureValidator#isValidSignature: unsupported signature");
    }

    /// @dev Verifies signature using logic defined by Wallet contract.
    /// @param hash Any 32 byte hash.
    /// @param walletAddress Address that should have signed the given hash
    ///                      and defines its own signature verification method.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if signature is valid for given wallet..
    function isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes memory _calldata = abi.encodeWithSelector(IWallet(walletAddress).isValidSignature.selector, hash, signature);
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(walletAddress)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(_calldata, 32)
            let success := staticcall(
                gas(), // forward all gas
                walletAddress, // address of Wallet contract
                cdStart, // pointer to start of input
                mload(_calldata), // length of input
                cdStart, // write output over input
                32 // output size is 32 bytes
            )

            if iszero(eq(returndatasize(), 32)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                // Signature is valid if call did not revert and returned true
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }
}

pragma solidity >=0.7.0;

interface ISetAllowance {
    function setAllowance(address[] memory tokenList, address spender) external;

    function closeAllowance(address[] memory tokenList, address spender) external;
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/

pragma solidity ^0.7.6;

library LibBytes {
    using LibBytes for bytes;

    /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

    /**
     * @dev Pops the last byte off of a byte array by modifying its length.
     * @param b Byte array that will be modified.
     * @return result The byte that was popped off.
     */
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "LibBytes#popLastByte: greater than zero length required");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "LibBytes#readAddress greater or equal to 20 length required"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

    /**
     * @dev Reads a bytes32 value from a position in a byte array.
     * @param b Byte array containing a bytes32 value.
     * @param index Index in byte array of bytes32 value.
     * @return result bytes32 value from byte array.
     */
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "LibBytes#readBytes32 greater or equal to 32 length required");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "LibBytes#readBytes4 greater or equal to 4 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "LibBytes#readBytes2 greater or equal to 2 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/ILimitOrder.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IWeth.sol";
import "./utils/BaseLibEIP712.sol";
import "./utils/LibConstant.sol";
import "./utils/LibUniswapV2.sol";
import "./utils/LibUniswapV3.sol";
import "./utils/LibOrderStorage.sol";
import "./utils/LimitOrderLibEIP712.sol";
import "./utils/SignatureValidator.sol";

contract LimitOrder is ILimitOrder, BaseLibEIP712, SignatureValidator, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public constant version = "1.0.0";
    IPermanentStorage public immutable permStorage;
    address public immutable userProxy;
    IWETH public immutable weth;

    // AMM
    address public immutable uniswapV3RouterAddress;
    address public immutable sushiswapRouterAddress;

    // Below are the variables which consume storage slots.
    address public operator;
    address public coordinator;
    ISpender public spender;
    address public feeCollector;

    // Factors
    uint16 public makerFeeFactor = 0;
    uint16 public takerFeeFactor = 0;
    uint16 public profitFeeFactor = 0;
    uint16 public profitCapFactor = LibConstant.BPS_MAX;

    constructor(
        address _operator,
        address _coordinator,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth,
        address _uniswapV3RouterAddress,
        address _sushiswapRouterAddress,
        address _feeCollector
    ) {
        operator = _operator;
        coordinator = _coordinator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
        uniswapV3RouterAddress = _uniswapV3RouterAddress;
        sushiswapRouterAddress = _sushiswapRouterAddress;
        feeCollector = _feeCollector;
    }

    receive() external payable {}

    modifier onlyOperator() {
        require(operator == msg.sender, "LimitOrder: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "LimitOrder: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "LimitOrder: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "LimitOrder: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    function upgradeCoordinator(address _newCoordinator) external onlyOperator {
        require(_newCoordinator != address(0), "LimitOrder: coordinator can not be zero address");
        coordinator = _newCoordinator;

        emit UpgradeCoordinator(_newCoordinator);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) external onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, LibConstant.MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) external onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{ value: balance }();

            emit DepositETH(balance);
        }
    }

    function setFactors(
        uint16 _makerFeeFactor,
        uint16 _takerFeeFactor,
        uint16 _profitFeeFactor,
        uint16 _profitCapFactor
    ) external onlyOperator {
        require(_makerFeeFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid maker fee factor");
        require(_takerFeeFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid taker fee factor");
        require(_profitFeeFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid profit fee factor");
        require(_profitCapFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid profit cap factor");

        makerFeeFactor = _makerFeeFactor;
        takerFeeFactor = _takerFeeFactor;
        profitFeeFactor = _profitFeeFactor;
        profitCapFactor = _profitCapFactor;

        emit FactorsUpdated(_makerFeeFactor, _takerFeeFactor, _profitFeeFactor, _profitCapFactor);
    }

    /**
     * @dev set fee collector
     */
    function setFeeCollector(address _newFeeCollector) external onlyOperator {
        require(_newFeeCollector != address(0), "LimitOrder: fee collector can not be zero address");
        feeCollector = _newFeeCollector;

        emit SetFeeCollector(_newFeeCollector);
    }

    /**
     * Fill limit order by trader
     */
    function fillLimitOrderByTrader(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        TraderParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external override onlyUserProxy nonReentrant returns (uint256, uint256) {
        bytes32 orderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(_order));

        _validateOrder(_order, orderHash, _orderMakerSig);
        bytes32 allowFillHash = _validateFillPermission(orderHash, _params.takerTokenAmount, _params.taker, _crdParams);
        _validateOrderTaker(_order, _params.taker);

        {
            LimitOrderLibEIP712.Fill memory fill = LimitOrderLibEIP712.Fill({
                orderHash: orderHash,
                taker: _params.taker,
                recipient: _params.recipient,
                takerTokenAmount: _params.takerTokenAmount,
                takerSalt: _params.salt,
                expiry: _params.expiry
            });
            _validateTraderFill(fill, _params.takerSig);
        }

        (uint256 makerTokenAmount, uint256 takerTokenAmount, uint256 remainingAmount) = _quoteOrder(_order, orderHash, _params.takerTokenAmount);

        uint256 makerTokenOut = _settleForTrader(
            TraderSettlement({
                orderHash: orderHash,
                allowFillHash: allowFillHash,
                trader: _params.taker,
                recipient: _params.recipient,
                maker: _order.maker,
                taker: _order.taker,
                makerToken: _order.makerToken,
                takerToken: _order.takerToken,
                makerTokenAmount: makerTokenAmount,
                takerTokenAmount: takerTokenAmount,
                remainingAmount: remainingAmount
            })
        );

        _recordOrderFilled(orderHash, takerTokenAmount);

        return (takerTokenAmount, makerTokenOut);
    }

    function _validateTraderFill(LimitOrderLibEIP712.Fill memory _fill, bytes memory _fillTakerSig) internal {
        require(_fill.expiry > uint64(block.timestamp), "LimitOrder: Fill request is expired");

        bytes32 fillHash = getEIP712Hash(LimitOrderLibEIP712._getFillStructHash(_fill));
        require(isValidSignature(_fill.taker, fillHash, bytes(""), _fillTakerSig), "LimitOrder: Fill is not signed by taker");

        // Set fill seen to avoid replay attack.
        // PermanentStorage would throw error if fill is already seen.
        permStorage.setLimitOrderTransactionSeen(fillHash);
    }

    function _validateFillPermission(
        bytes32 _orderHash,
        uint256 _fillAmount,
        address _executor,
        CoordinatorParams memory _crdParams
    ) internal returns (bytes32) {
        require(_crdParams.expiry > uint64(block.timestamp), "LimitOrder: Fill permission is expired");

        bytes32 allowFillHash = getEIP712Hash(
            LimitOrderLibEIP712._getAllowFillStructHash(
                LimitOrderLibEIP712.AllowFill({
                    orderHash: _orderHash,
                    executor: _executor,
                    fillAmount: _fillAmount,
                    salt: _crdParams.salt,
                    expiry: _crdParams.expiry
                })
            )
        );
        require(isValidSignature(coordinator, allowFillHash, bytes(""), _crdParams.sig), "LimitOrder: AllowFill is not signed by coordinator");

        // Set allow fill seen to avoid replay attack
        // PermanentStorage would throw error if allow fill is already seen.
        permStorage.setLimitOrderAllowFillSeen(allowFillHash);

        return allowFillHash;
    }

    struct TraderSettlement {
        bytes32 orderHash;
        bytes32 allowFillHash;
        address trader;
        address recipient;
        address maker;
        address taker;
        IERC20 makerToken;
        IERC20 takerToken;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        uint256 remainingAmount;
    }

    function _settleForTrader(TraderSettlement memory _settlement) internal returns (uint256) {
        // Calculate maker fee (maker receives taker token so fee is charged in taker token)
        uint256 takerTokenFee = _mulFactor(_settlement.takerTokenAmount, makerFeeFactor);
        uint256 takerTokenForMaker = _settlement.takerTokenAmount.sub(takerTokenFee);

        // Calculate taker fee (taker receives maker token so fee is charged in maker token)
        uint256 makerTokenFee = _mulFactor(_settlement.makerTokenAmount, takerFeeFactor);
        uint256 makerTokenForTrader = _settlement.makerTokenAmount.sub(makerTokenFee);

        // trader -> maker
        spender.spendFromUserTo(_settlement.trader, address(_settlement.takerToken), _settlement.maker, takerTokenForMaker);

        // maker -> recipient
        spender.spendFromUserTo(_settlement.maker, address(_settlement.makerToken), _settlement.recipient, makerTokenForTrader);

        // Collect maker fee (charged in taker token)
        if (takerTokenFee > 0) {
            spender.spendFromUserTo(_settlement.trader, address(_settlement.takerToken), feeCollector, takerTokenFee);
        }
        // Collect taker fee (charged in maker token)
        if (makerTokenFee > 0) {
            spender.spendFromUserTo(_settlement.maker, address(_settlement.makerToken), feeCollector, makerTokenFee);
        }

        // bypass stack too deep error
        _emitLimitOrderFilledByTrader(
            LimitOrderFilledByTraderParams({
                orderHash: _settlement.orderHash,
                maker: _settlement.maker,
                taker: _settlement.trader,
                allowFillHash: _settlement.allowFillHash,
                recipient: _settlement.recipient,
                makerToken: address(_settlement.makerToken),
                takerToken: address(_settlement.takerToken),
                makerTokenFilledAmount: _settlement.makerTokenAmount,
                takerTokenFilledAmount: _settlement.takerTokenAmount,
                remainingAmount: _settlement.remainingAmount,
                makerTokenFee: makerTokenFee,
                takerTokenFee: takerTokenFee
            })
        );

        return makerTokenForTrader;
    }

    /**
     * Fill limit order by protocol
     */
    function fillLimitOrderByProtocol(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        ProtocolParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external override onlyUserProxy nonReentrant returns (uint256) {
        bytes32 orderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(_order));

        _validateOrder(_order, orderHash, _orderMakerSig);
        bytes32 allowFillHash = _validateFillPermission(orderHash, _params.takerTokenAmount, tx.origin, _crdParams);

        address protocolAddress = _getProtocolAddress(_params.protocol);
        _validateOrderTaker(_order, protocolAddress);

        (uint256 makerTokenAmount, uint256 takerTokenAmount, uint256 remainingAmount) = _quoteOrder(_order, orderHash, _params.takerTokenAmount);

        uint256 takerTokenProfit = _settleForProtocol(
            ProtocolSettlement({
                orderHash: orderHash,
                allowFillHash: allowFillHash,
                protocolAddress: protocolAddress,
                protocol: _params.protocol,
                data: _params.data,
                relayer: tx.origin,
                profitRecipient: _params.profitRecipient,
                maker: _order.maker,
                taker: _order.taker,
                makerToken: _order.makerToken,
                takerToken: _order.takerToken,
                makerTokenAmount: makerTokenAmount,
                takerTokenAmount: takerTokenAmount,
                remainingAmount: remainingAmount,
                protocolOutMinimum: _params.protocolOutMinimum,
                expiry: _params.expiry
            })
        );

        _recordOrderFilled(orderHash, takerTokenAmount);

        return takerTokenProfit;
    }

    function _getProtocolAddress(Protocol protocol) internal view returns (address) {
        if (protocol == Protocol.UniswapV3) {
            return uniswapV3RouterAddress;
        }
        if (protocol == Protocol.Sushiswap) {
            return sushiswapRouterAddress;
        }
        revert("LimitOrder: Unknown protocol");
    }

    struct ProtocolSettlement {
        bytes32 orderHash;
        bytes32 allowFillHash;
        address protocolAddress;
        Protocol protocol;
        bytes data;
        address relayer;
        address profitRecipient;
        address maker;
        address taker;
        IERC20 makerToken;
        IERC20 takerToken;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        uint256 remainingAmount;
        uint256 protocolOutMinimum;
        uint64 expiry;
    }

    function _settleForProtocol(ProtocolSettlement memory _settlement) internal returns (uint256) {
        // Collect maker token from maker in order to swap through protocol
        spender.spendFromUserTo(_settlement.maker, address(_settlement.makerToken), address(this), _settlement.makerTokenAmount);

        uint256 takerTokenOut = _swapByProtocol(_settlement);

        require(takerTokenOut >= _settlement.takerTokenAmount, "LimitOrder: Insufficient token amount out from protocol");

        uint256 takerTokenExtra = takerTokenOut.sub(_settlement.takerTokenAmount);

        // Cap taker token profit
        uint256 takerTokenProfitCap = _mulFactor(_settlement.takerTokenAmount, profitCapFactor);
        uint256 takerTokenProfit = takerTokenExtra > takerTokenProfitCap ? takerTokenProfitCap : takerTokenExtra;

        // Calculate taker token profit for relayer
        uint256 takerTokenProfitFee = _mulFactor(takerTokenProfit, profitFeeFactor);
        uint256 takerTokenProfitForRelayer = takerTokenProfit.sub(takerTokenProfitFee);

        // Distribute taker token profit to profit recipient assigned by relayer
        _settlement.takerToken.safeTransfer(_settlement.profitRecipient, takerTokenProfitForRelayer);
        if (takerTokenProfitFee > 0) {
            _settlement.takerToken.safeTransfer(feeCollector, takerTokenProfitFee);
        }

        // Calculate maker fee (maker receives taker token so fee is charged in taker token)
        uint256 takerTokenFee = _mulFactor(_settlement.takerTokenAmount, makerFeeFactor);
        uint256 takerTokenForMaker = _settlement.takerTokenAmount.sub(takerTokenFee);

        // Calculate taker token profit back to maker
        uint256 takerTokenProfitBackToMaker = takerTokenExtra > takerTokenProfit ? takerTokenExtra.sub(takerTokenProfit) : 0;

        // Distribute taker token to maker
        _settlement.takerToken.safeTransfer(_settlement.maker, takerTokenForMaker.add(takerTokenProfitBackToMaker));
        if (takerTokenFee > 0) {
            _settlement.takerToken.safeTransfer(feeCollector, takerTokenFee);
        }

        // Bypass stack too deep error
        _emitLimitOrderFilledByProtocol(
            LimitOrderFilledByProtocolParams({
                orderHash: _settlement.orderHash,
                maker: _settlement.maker,
                taker: _settlement.protocolAddress,
                allowFillHash: _settlement.allowFillHash,
                relayer: _settlement.relayer,
                profitRecipient: _settlement.profitRecipient,
                makerToken: address(_settlement.makerToken),
                takerToken: address(_settlement.takerToken),
                makerTokenFilledAmount: _settlement.makerTokenAmount,
                takerTokenFilledAmount: _settlement.takerTokenAmount,
                remainingAmount: _settlement.remainingAmount,
                makerTokenFee: 0,
                takerTokenFee: takerTokenFee,
                takerTokenProfit: takerTokenProfit,
                takerTokenProfitFee: takerTokenProfitFee,
                takerTokenProfitBackToMaker: takerTokenProfitBackToMaker
            })
        );

        return takerTokenProfitForRelayer;
    }

    function _swapByProtocol(ProtocolSettlement memory _settlement) internal returns (uint256 amountOut) {
        _settlement.makerToken.safeApprove(_settlement.protocolAddress, _settlement.makerTokenAmount);

        // UniswapV3
        if (_settlement.protocol == Protocol.UniswapV3) {
            amountOut = LibUniswapV3.exactInput(
                _settlement.protocolAddress,
                LibUniswapV3.ExactInputParams({
                    tokenIn: address(_settlement.makerToken),
                    tokenOut: address(_settlement.takerToken),
                    path: _settlement.data,
                    recipient: address(this),
                    deadline: _settlement.expiry,
                    amountIn: _settlement.makerTokenAmount,
                    amountOutMinimum: _settlement.protocolOutMinimum
                })
            );
        } else {
            // Sushiswap
            address[] memory path = abi.decode(_settlement.data, (address[]));
            amountOut = LibUniswapV2.swapExactTokensForTokens(
                _settlement.protocolAddress,
                LibUniswapV2.SwapExactTokensForTokensParams({
                    tokenIn: address(_settlement.makerToken),
                    tokenInAmount: _settlement.makerTokenAmount,
                    tokenOut: address(_settlement.takerToken),
                    tokenOutAmountMin: _settlement.protocolOutMinimum,
                    path: path,
                    to: address(this),
                    deadline: _settlement.expiry
                })
            );
        }

        _settlement.makerToken.safeApprove(_settlement.protocolAddress, 0);
    }

    /**
     * Cancel limit order
     */
    function cancelLimitOrder(LimitOrderLibEIP712.Order calldata _order, bytes calldata _cancelOrderMakerSig) external override onlyUserProxy nonReentrant {
        require(_order.expiry > uint64(block.timestamp), "LimitOrder: Order is expired");
        bytes32 orderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(_order));
        bool isCancelled = LibOrderStorage.getStorage().orderHashToCancelled[orderHash];
        require(!isCancelled, "LimitOrder: Order is cancelled already");
        {
            LimitOrderLibEIP712.Order memory cancelledOrder = _order;
            cancelledOrder.takerTokenAmount = 0;

            bytes32 cancelledOrderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(cancelledOrder));
            require(isValidSignature(_order.maker, cancelledOrderHash, bytes(""), _cancelOrderMakerSig), "LimitOrder: Cancel request is not signed by maker");
        }

        // Set cancelled state to storage
        LibOrderStorage.getStorage().orderHashToCancelled[orderHash] = true;
        emit OrderCancelled(orderHash, _order.maker);
    }

    /* order utils */

    function _validateOrder(
        LimitOrderLibEIP712.Order memory _order,
        bytes32 _orderHash,
        bytes memory _orderMakerSig
    ) internal view {
        require(_order.expiry > uint64(block.timestamp), "LimitOrder: Order is expired");
        bool isCancelled = LibOrderStorage.getStorage().orderHashToCancelled[_orderHash];
        require(!isCancelled, "LimitOrder: Order is cancelled");

        require(isValidSignature(_order.maker, _orderHash, bytes(""), _orderMakerSig), "LimitOrder: Order is not signed by maker");
    }

    function _validateOrderTaker(LimitOrderLibEIP712.Order memory _order, address _taker) internal pure {
        if (_order.taker != address(0)) {
            require(_order.taker == _taker, "LimitOrder: Order cannot be filled by this taker");
        }
    }

    function _quoteOrder(
        LimitOrderLibEIP712.Order memory _order,
        bytes32 _orderHash,
        uint256 _takerTokenAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 takerTokenFilledAmount = LibOrderStorage.getStorage().orderHashToTakerTokenFilledAmount[_orderHash];

        require(takerTokenFilledAmount < _order.takerTokenAmount, "LimitOrder: Order is filled");

        uint256 takerTokenFillableAmount = _order.takerTokenAmount.sub(takerTokenFilledAmount);
        uint256 takerTokenQuota = Math.min(_takerTokenAmount, takerTokenFillableAmount);
        uint256 makerTokenQuota = takerTokenQuota.mul(_order.makerTokenAmount).div(_order.takerTokenAmount);
        uint256 remainingAfterFill = takerTokenFillableAmount.sub(takerTokenQuota);

        return (makerTokenQuota, takerTokenQuota, remainingAfterFill);
    }

    function _recordOrderFilled(bytes32 _orderHash, uint256 _takerTokenAmount) internal {
        LibOrderStorage.Storage storage stor = LibOrderStorage.getStorage();
        uint256 takerTokenFilledAmount = stor.orderHashToTakerTokenFilledAmount[_orderHash];
        stor.orderHashToTakerTokenFilledAmount[_orderHash] = takerTokenFilledAmount.add(_takerTokenAmount);
    }

    /* math utils */

    function _mulFactor(uint256 amount, uint256 factor) internal returns (uint256) {
        return amount.mul(factor).div(LibConstant.BPS_MAX);
    }

    /* event utils */

    struct LimitOrderFilledByTraderParams {
        bytes32 orderHash;
        address maker;
        address taker;
        bytes32 allowFillHash;
        address recipient;
        address makerToken;
        address takerToken;
        uint256 makerTokenFilledAmount;
        uint256 takerTokenFilledAmount;
        uint256 remainingAmount;
        uint256 makerTokenFee;
        uint256 takerTokenFee;
    }

    function _emitLimitOrderFilledByTrader(LimitOrderFilledByTraderParams memory _params) internal {
        emit LimitOrderFilledByTrader(
            _params.orderHash,
            _params.maker,
            _params.taker,
            _params.allowFillHash,
            _params.recipient,
            FillReceipt({
                makerToken: _params.makerToken,
                takerToken: _params.takerToken,
                makerTokenFilledAmount: _params.makerTokenFilledAmount,
                takerTokenFilledAmount: _params.takerTokenFilledAmount,
                remainingAmount: _params.remainingAmount,
                makerTokenFee: _params.makerTokenFee,
                takerTokenFee: _params.takerTokenFee
            })
        );
    }

    struct LimitOrderFilledByProtocolParams {
        bytes32 orderHash;
        address maker;
        address taker;
        bytes32 allowFillHash;
        address relayer;
        address profitRecipient;
        address makerToken;
        address takerToken;
        uint256 makerTokenFilledAmount;
        uint256 takerTokenFilledAmount;
        uint256 remainingAmount;
        uint256 makerTokenFee;
        uint256 takerTokenFee;
        uint256 takerTokenProfit;
        uint256 takerTokenProfitFee;
        uint256 takerTokenProfitBackToMaker;
    }

    function _emitLimitOrderFilledByProtocol(LimitOrderFilledByProtocolParams memory _params) internal {
        emit LimitOrderFilledByProtocol(
            _params.orderHash,
            _params.maker,
            _params.taker,
            _params.allowFillHash,
            _params.relayer,
            _params.profitRecipient,
            FillReceipt({
                makerToken: _params.makerToken,
                takerToken: _params.takerToken,
                makerTokenFilledAmount: _params.makerTokenFilledAmount,
                takerTokenFilledAmount: _params.takerTokenFilledAmount,
                remainingAmount: _params.remainingAmount,
                makerTokenFee: _params.makerTokenFee,
                takerTokenFee: _params.takerTokenFee
            }),
            _params.takerTokenProfit,
            _params.takerTokenProfitFee,
            _params.takerTokenProfitBackToMaker
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../utils/LimitOrderLibEIP712.sol";

interface ILimitOrder {
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event UpgradeCoordinator(address newCoordinator);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);
    event FactorsUpdated(uint16 makerFeeFactor, uint16 takerFeeFactor, uint16 profitFeeFactor, uint16 profitCapFactor);
    event SetFeeCollector(address newFeeCollector);
    event LimitOrderFilledByTrader(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        bytes32 allowFillHash,
        address recipient,
        FillReceipt fillReceipt
    );
    event LimitOrderFilledByProtocol(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        bytes32 allowFillHash,
        address relayer,
        address profitRecipient,
        FillReceipt fillReceipt,
        uint256 takerTokenProfit,
        uint256 takerTokenProfitFee,
        uint256 takerTokenProfitBackToMaker
    );
    event OrderCancelled(bytes32 orderHash, address maker);

    struct FillReceipt {
        address makerToken;
        address takerToken;
        uint256 makerTokenFilledAmount;
        uint256 takerTokenFilledAmount;
        uint256 remainingAmount;
        uint256 makerTokenFee;
        uint256 takerTokenFee;
    }

    struct CoordinatorParams {
        bytes sig;
        uint256 salt;
        uint64 expiry;
    }

    struct TraderParams {
        address taker;
        address recipient;
        uint256 takerTokenAmount;
        uint256 salt;
        uint64 expiry;
        bytes takerSig;
    }

    /**
     * Fill limit order by trader
     */
    function fillLimitOrderByTrader(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        TraderParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external returns (uint256, uint256);

    enum Protocol {
        UniswapV3,
        Sushiswap
    }

    struct ProtocolParams {
        Protocol protocol;
        bytes data;
        address profitRecipient;
        uint256 takerTokenAmount;
        uint256 protocolOutMinimum;
        uint64 expiry;
    }

    /**
     * Fill limit order by protocol
     */
    function fillLimitOrderByProtocol(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        ProtocolParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external returns (uint256);

    /**
     * Cancel limit order
     */
    function cancelLimitOrder(LimitOrderLibEIP712.Order calldata _order, bytes calldata _cancelMakerSig) external;
}

pragma solidity ^0.7.6;

library LibConstant {
    int256 internal constant MAX_INT = 2**255 - 1;
    uint256 internal constant MAX_UINT = 2**256 - 1;
    uint16 internal constant BPS_MAX = 10000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IUniswapRouterV2.sol";

library LibUniswapV2 {
    struct SwapExactTokensForTokensParams {
        address tokenIn;
        uint256 tokenInAmount;
        address tokenOut;
        uint256 tokenOutAmountMin;
        address[] path;
        address to;
        uint256 deadline;
    }

    function swapExactTokensForTokens(address _uniswapV2Router, SwapExactTokensForTokensParams memory _params) internal returns (uint256 amount) {
        _validatePath(_params.path, _params.tokenIn, _params.tokenOut);

        uint256[] memory amounts = IUniswapRouterV2(_uniswapV2Router).swapExactTokensForTokens(
            _params.tokenInAmount,
            _params.tokenOutAmountMin,
            _params.path,
            _params.to,
            _params.deadline
        );

        return amounts[amounts.length - 1];
    }

    function _validatePath(
        address[] memory _path,
        address _tokenIn,
        address _tokenOut
    ) internal {
        require(_path.length >= 2, "UniswapV2: Path length must be at least two");
        require(_path[0] == _tokenIn, "UniswapV2: First element of path must match token in");
        require(_path[_path.length - 1] == _tokenOut, "UniswapV2: Last element of path must match token out");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import { ISwapRouter } from "../interfaces/IUniswapV3SwapRouter.sol";

import { Path } from "./UniswapV3PathLib.sol";

library LibUniswapV3 {
    using Path for bytes;

    enum SwapType {
        None,
        ExactInputSingle,
        ExactInput
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(address _uniswapV3Router, ExactInputSingleParams memory _params) internal returns (uint256 amount) {
        return
            ISwapRouter(_uniswapV3Router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _params.tokenIn,
                    tokenOut: _params.tokenOut,
                    fee: _params.fee,
                    recipient: _params.recipient,
                    deadline: _params.deadline,
                    amountIn: _params.amountIn,
                    amountOutMinimum: _params.amountOutMinimum,
                    sqrtPriceLimitX96: 0
                })
            );
    }

    struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(address _uniswapV3Router, ExactInputParams memory _params) internal returns (uint256 amount) {
        _validatePath(_params.path, _params.tokenIn, _params.tokenOut);
        return
            ISwapRouter(_uniswapV3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: _params.path,
                    recipient: _params.recipient,
                    deadline: _params.deadline,
                    amountIn: _params.amountIn,
                    amountOutMinimum: _params.amountOutMinimum
                })
            );
    }

    function _validatePath(
        bytes memory _path,
        address _tokenIn,
        address _tokenOut
    ) internal {
        (address tokenA, address tokenB, ) = _path.decodeFirstPool();

        if (_path.hasMultiplePools()) {
            _path = _path.skipToken();
            while (_path.hasMultiplePools()) {
                _path = _path.skipToken();
            }
            (, tokenB, ) = _path.decodeFirstPool();
        }

        require(tokenA == _tokenIn, "UniswapV3: first element of path must match token in");
        require(tokenB == _tokenOut, "UniswapV3: last element of path must match token out");
    }
}

pragma solidity ^0.7.6;

library LibOrderStorage {
    bytes32 private constant STORAGE_SLOT = 0x341a85fd45142738553ca9f88acd66d751d05662e7332a1dd940f22830435fb4;
    /// @dev Storage bucket for this feature.
    struct Storage {
        // How much taker token has been filled in order.
        mapping(bytes32 => uint256) orderHashToTakerTokenFilledAmount;
        // Whether order is cancelled or not.
        mapping(bytes32 => bool) orderHashToCancelled;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("limitorder.order.storage")) - 1));

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := STORAGE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ILimitOrder.sol";

library LimitOrderLibEIP712 {
    struct Order {
        IERC20 makerToken;
        IERC20 takerToken;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        address maker;
        address taker;
        uint256 salt;
        uint64 expiry;
    }

    /*
        keccak256(
            abi.encodePacked(
                "Order(",
                "address makerToken,",
                "address takerToken,",
                "uint256 makerTokenAmount,",
                "uint256 takerTokenAmount,",
                "address maker,",
                "address taker,",
                "uint256 salt,",
                "uint64 expiry",
                ")"
            )
        );
    */
    uint256 private constant ORDER_TYPEHASH = 0x025174f0ee45736f4e018e96c368bd4baf3dce8d278860936559209f568c8ecb;

    function _getOrderStructHash(Order memory _order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    address(_order.makerToken),
                    address(_order.takerToken),
                    _order.makerTokenAmount,
                    _order.takerTokenAmount,
                    _order.maker,
                    _order.taker,
                    _order.salt,
                    _order.expiry
                )
            );
    }

    struct Fill {
        bytes32 orderHash; // EIP712 hash
        address taker;
        address recipient;
        uint256 takerTokenAmount;
        uint256 takerSalt;
        uint64 expiry;
    }

    /*
        keccak256(
            abi.encodePacked(
                "Fill(",
                "bytes32 orderHash,",
                "address taker,",
                "address recipient,",
                "uint256 takerTokenAmount,",
                "uint256 takerSalt,",
                "uint64 expiry",
                ")"
            )
        );
    */
    uint256 private constant FILL_TYPEHASH = 0x4ef294060cea2f973f7fe2a6d78624328586118efb1c4d640855aac3ba70e9c9;

    function _getFillStructHash(Fill memory _fill) internal pure returns (bytes32) {
        return keccak256(abi.encode(FILL_TYPEHASH, _fill.orderHash, _fill.taker, _fill.recipient, _fill.takerTokenAmount, _fill.takerSalt, _fill.expiry));
    }

    struct AllowFill {
        bytes32 orderHash; // EIP712 hash
        address executor;
        uint256 fillAmount;
        uint256 salt;
        uint64 expiry;
    }

    /*
        keccak256(abi.encodePacked("AllowFill(", "bytes32 orderHash,", "address executor,", "uint256 fillAmount,", "uint256 salt,", "uint64 expiry", ")"));
    */
    uint256 private constant ALLOW_FILL_TYPEHASH = 0xa471a3189b88889758f25ee2ce05f58964c40b03edc9cc9066079fd2b547f074;

    function _getAllowFillStructHash(AllowFill memory _allowFill) internal pure returns (bytes32) {
        return keccak256(abi.encode(ALLOW_FILL_TYPEHASH, _allowFill.orderHash, _allowFill.executor, _allowFill.fillAmount, _allowFill.salt, _allowFill.expiry));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AMMWrapper.sol";
import "./interfaces/IBalancerV2Vault.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./utils/AMMLibEIP712.sol";
import "./utils/LibBytes.sol";
import "./utils/LibConstant.sol";
import "./utils/LibUniswapV3.sol";

contract AMMWrapperWithPath is AMMWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using LibBytes for bytes;

    // Constants do not have storage slot.
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    event Swapped(TxMetaData, AMMLibEIP712.Order order);

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _operator,
        uint256 _subsidyFactor,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth
    ) AMMWrapper(_operator, _subsidyFactor, _userProxy, _spender, _permStorage, _weth) {}

    /************************************************************
     *                   External functions                      *
     *************************************************************/

    function trade(
        AMMLibEIP712.Order calldata _order,
        uint256 _feeFactor,
        bytes calldata _sig,
        bytes calldata _makerSpecificData,
        address[] calldata _path
    ) external payable nonReentrant onlyUserProxy returns (uint256) {
        require(_order.deadline >= block.timestamp, "AMMWrapper: expired order");
        TxMetaData memory txMetaData;
        InternalTxData memory internalTxData;

        // These variables are copied straight from function parameters and
        // used to bypass stack too deep error.
        txMetaData.subsidyFactor = uint16(subsidyFactor);
        txMetaData.feeFactor = uint16(_feeFactor);
        internalTxData.makerSpecificData = _makerSpecificData;
        internalTxData.path = _path;
        if (!permStorage.isRelayerValid(tx.origin)) {
            txMetaData.feeFactor = (txMetaData.subsidyFactor > txMetaData.feeFactor) ? txMetaData.subsidyFactor : txMetaData.feeFactor;
            txMetaData.subsidyFactor = 0;
        }

        // Assign trade vairables
        internalTxData.fromEth = (_order.takerAssetAddr == ZERO_ADDRESS || _order.takerAssetAddr == ETH_ADDRESS);
        internalTxData.toEth = (_order.makerAssetAddr == ZERO_ADDRESS || _order.makerAssetAddr == ETH_ADDRESS);
        if (_isCurve(_order.makerAddr)) {
            // PermanetStorage can recognize `ETH_ADDRESS` but not `ZERO_ADDRESS`.
            // Convert it to `ETH_ADDRESS` as passed in `_order.takerAssetAddr` or `_order.makerAssetAddr` might be `ZERO_ADDRESS`.
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? ETH_ADDRESS : _order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? ETH_ADDRESS : _order.makerAssetAddr;
        } else {
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? address(weth) : _order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? address(weth) : _order.makerAssetAddr;
        }

        txMetaData.transactionHash = _verify(_order, _sig);

        _prepare(_order, internalTxData);

        // minAmount = makerAssetAmount * (10000 - subsidyFactor) / 10000
        uint256 _minAmount = _order.makerAssetAmount.mul((BPS_MAX.sub(txMetaData.subsidyFactor))).div(BPS_MAX);
        (txMetaData.source, txMetaData.receivedAmount) = _swapWithPath(_order, internalTxData, _minAmount);

        // Settle
        txMetaData.settleAmount = _settle(_order, txMetaData, internalTxData);

        emit Swapped(txMetaData, _order);

        return txMetaData.settleAmount;
    }

    /**
     * @dev internal function of `trade`.
     * Used to tell if maker is Curve.
     */
    function _isCurve(address _makerAddr) internal pure override returns (bool) {
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || _makerAddr == UNISWAP_V3_ROUTER_ADDRESS || _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            return false;
        }
        return true;
    }

    /**
     * @dev internal function of `trade`.
     * It executes the swap on chosen AMM.
     */
    function _swapWithPath(
        AMMLibEIP712.Order memory _order,
        InternalTxData memory _internalTxData,
        uint256 _minAmount
    )
        internal
        approveTakerAsset(_internalTxData.takerAssetInternalAddr, _order.makerAddr, _order.takerAssetAmount)
        returns (string memory source, uint256 receivedAmount)
    {
        if (_order.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || _order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            source = (_order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) ? "SushiSwap" : "Uniswap V2";
            // Sushiswap shares the same interface as Uniswap's
            receivedAmount = _tradeUniswapV2TokenToToken(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr,
                _order.takerAssetAmount,
                _minAmount,
                _order.deadline,
                _internalTxData.path
            );
        } else if (_order.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            source = "Uniswap V3";
            receivedAmount = _tradeUniswapV3TokenToToken(
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr,
                _order.deadline,
                _order.takerAssetAmount,
                _minAmount,
                _internalTxData.makerSpecificData
            );
        } else {
            // Try to match maker with Curve pool list
            CurveData memory curveData;
            (curveData.fromTokenCurveIndex, curveData.toTokenCurveIndex, curveData.swapMethod, ) = permStorage.getCurvePoolInfo(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr
            );

            require(curveData.swapMethod != 0, "AMMWrapper: swap method not registered");
            if (curveData.fromTokenCurveIndex > 0 && curveData.toTokenCurveIndex > 0) {
                source = "Curve";
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                curveData.fromTokenCurveIndex = curveData.fromTokenCurveIndex - 1;
                curveData.toTokenCurveIndex = curveData.toTokenCurveIndex - 1;
                // Curve does not return amount swapped so we need to record balance change instead.
                uint256 balanceBeforeTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                _tradeCurveTokenToToken(
                    _order.makerAddr,
                    curveData.fromTokenCurveIndex,
                    curveData.toTokenCurveIndex,
                    _order.takerAssetAmount,
                    _minAmount,
                    curveData.swapMethod
                );
                uint256 balanceAfterTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                receivedAmount = balanceAfterTrade.sub(balanceBeforeTrade);
            } else {
                revert("AMMWrapper: unsupported makerAddr");
            }
        }
    }

    /* Uniswap V2 */

    function _tradeUniswapV2TokenToToken(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _deadline,
        address[] memory _path
    ) internal returns (uint256) {
        IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
        if (_path.length == 0) {
            _path = new address[](2);
            _path[0] = _takerAssetAddr;
            _path[1] = _makerAssetAddr;
        } else {
            _validateAMMPath(_path, _takerAssetAddr, _makerAssetAddr);
        }
        uint256[] memory amounts = router.swapExactTokensForTokens(_takerAssetAmount, _makerAssetAmount, _path, address(this), _deadline);
        return amounts[amounts.length - 1];
    }

    function _validateAMMPath(
        address[] memory _path,
        address _takerAssetAddr,
        address _makerAssetAddr
    ) internal {
        require(_path.length >= 2, "AMMWrapper: path length must be at least two");
        require(_path[0] == _takerAssetAddr, "AMMWrapper: first element of path must match taker asset");
        require(_path[_path.length - 1] == _makerAssetAddr, "AMMWrapper: last element of path must match maker asset");
    }

    /* Uniswap V3 */

    function _tradeUniswapV3TokenToToken(
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _deadline,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        bytes memory _makerSpecificData
    ) internal returns (uint256 amountOut) {
        LibUniswapV3.SwapType swapType = LibUniswapV3.SwapType(uint256(_makerSpecificData.readBytes32(0)));

        // exactInputSingle
        if (swapType == LibUniswapV3.SwapType.ExactInputSingle) {
            (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
            return
                LibUniswapV3.exactInputSingle(
                    UNISWAP_V3_ROUTER_ADDRESS,
                    LibUniswapV3.ExactInputSingleParams({
                        tokenIn: _takerAssetAddr,
                        tokenOut: _makerAssetAddr,
                        fee: poolFee,
                        recipient: address(this),
                        deadline: _deadline,
                        amountIn: _takerAssetAmount,
                        amountOutMinimum: _makerAssetAmount
                    })
                );
        }

        // exactInput
        if (swapType == LibUniswapV3.SwapType.ExactInput) {
            (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
            return
                LibUniswapV3.exactInput(
                    UNISWAP_V3_ROUTER_ADDRESS,
                    LibUniswapV3.ExactInputParams({
                        tokenIn: _takerAssetAddr,
                        tokenOut: _makerAssetAddr,
                        path: path,
                        recipient: address(this),
                        deadline: _deadline,
                        amountIn: _takerAssetAmount,
                        amountOutMinimum: _makerAssetAmount
                    })
                );
        }

        revert("AMMWrapper: unsupported UniswapV3 swap type");
    }
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/ICurveFi.sol";
import "./interfaces/IAMMWrapper.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IPermanentStorage.sol";
import "./utils/AMMLibEIP712.sol";
import "./utils/BaseLibEIP712.sol";
import "./utils/SignatureValidator.sol";

contract AMMWrapper is IAMMWrapper, ReentrancyGuard, BaseLibEIP712, SignatureValidator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    string public constant version = "5.2.0";
    uint256 internal constant MAX_UINT = 2**256 - 1;
    uint256 internal constant BPS_MAX = 10000;
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO_ADDRESS = address(0);
    address public immutable userProxy;
    IWETH public immutable weth;
    IPermanentStorage public immutable permStorage;
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    // Below are the variables which consume storage slots.
    address public operator;
    uint256 public subsidyFactor;
    ISpender public spender;

    /* Struct and event declaration */
    // Group the local variables together to prevent
    // Compiler error: Stack too deep, try removing local variables.
    struct TxMetaData {
        string source;
        bytes32 transactionHash;
        uint256 settleAmount;
        uint256 receivedAmount;
        uint16 feeFactor;
        uint16 subsidyFactor;
    }

    struct InternalTxData {
        bool fromEth;
        bool toEth;
        address takerAssetInternalAddr;
        address makerAssetInternalAddr;
        address[] path;
        bytes makerSpecificData;
    }

    struct CurveData {
        int128 fromTokenCurveIndex;
        int128 toTokenCurveIndex;
        uint16 swapMethod;
    }

    // Operator events
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event SetSubsidyFactor(uint256 newSubisdyFactor);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);

    event Swapped(
        string source,
        bytes32 indexed transactionHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint256 receivedAmount,
        uint16 feeFactor,
        uint16 subsidyFactor
    );

    receive() external payable {}

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "AMMWrapper: not the operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "AMMWrapper: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "AMMWrapper: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    /************************************************************
     *                 Internal function modifier                *
     *************************************************************/
    modifier approveTakerAsset(
        address _takerAssetInternalAddr,
        address _makerAddr,
        uint256 _takerAssetAmount
    ) {
        bool isTakerAssetETH = _isInternalAssetETH(_takerAssetInternalAddr);
        if (!isTakerAssetETH) IERC20(_takerAssetInternalAddr).safeApprove(_makerAddr, _takerAssetAmount);

        _;

        if (!isTakerAssetETH) IERC20(_takerAssetInternalAddr).safeApprove(_makerAddr, 0);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _operator,
        uint256 _subsidyFactor,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth
    ) {
        operator = _operator;
        subsidyFactor = _subsidyFactor;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/
    /**
     * @dev set new Spender
     */
    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "AMMWrapper: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    function setSubsidyFactor(uint256 _subsidyFactor) external onlyOperator {
        subsidyFactor = _subsidyFactor;

        emit SetSubsidyFactor(_subsidyFactor);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{ value: balance }();

            emit DepositETH(balance);
        }
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    function trade(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _feeFactor,
        address _userAddr,
        address payable _receiverAddr,
        uint256 _salt,
        uint256 _deadline,
        bytes calldata _sig
    ) external payable override nonReentrant onlyUserProxy returns (uint256) {
        AMMLibEIP712.Order memory order = AMMLibEIP712.Order(
            _makerAddr,
            _takerAssetAddr,
            _makerAssetAddr,
            _takerAssetAmount,
            _makerAssetAmount,
            _userAddr,
            _receiverAddr,
            _salt,
            _deadline
        );
        require(order.deadline >= block.timestamp, "AMMWrapper: expired order");
        TxMetaData memory txMetaData;
        InternalTxData memory internalTxData;

        // These variables are copied straight from function parameters and
        // used to bypass stack too deep error.
        txMetaData.subsidyFactor = uint16(subsidyFactor);
        txMetaData.feeFactor = uint16(_feeFactor);
        if (!permStorage.isRelayerValid(tx.origin)) {
            txMetaData.feeFactor = (txMetaData.subsidyFactor > txMetaData.feeFactor) ? txMetaData.subsidyFactor : txMetaData.feeFactor;
            txMetaData.subsidyFactor = 0;
        }

        // Assign trade vairables
        internalTxData.fromEth = (order.takerAssetAddr == ZERO_ADDRESS || order.takerAssetAddr == ETH_ADDRESS);
        internalTxData.toEth = (order.makerAssetAddr == ZERO_ADDRESS || order.makerAssetAddr == ETH_ADDRESS);
        if (_isCurve(order.makerAddr)) {
            // PermanetStorage can recognize `ETH_ADDRESS` but not `ZERO_ADDRESS`.
            // Convert it to `ETH_ADDRESS` as passed in `order.takerAssetAddr` or `order.makerAssetAddr` might be `ZERO_ADDRESS`.
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? ETH_ADDRESS : order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? ETH_ADDRESS : order.makerAssetAddr;
        } else {
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? address(weth) : order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? address(weth) : order.makerAssetAddr;
        }

        txMetaData.transactionHash = _verify(order, _sig);

        _prepare(order, internalTxData);

        // minAmount = makerAssetAmount * (10000 - subsidyFactor) / 10000
        uint256 _minAmount = order.makerAssetAmount.mul((BPS_MAX.sub(txMetaData.subsidyFactor))).div(BPS_MAX);
        (txMetaData.source, txMetaData.receivedAmount) = _swap(order, internalTxData, _minAmount);

        // Settle
        txMetaData.settleAmount = _settle(order, txMetaData, internalTxData);

        emit Swapped(
            txMetaData.source,
            txMetaData.transactionHash,
            order.userAddr,
            order.takerAssetAddr,
            order.takerAssetAmount,
            order.makerAddr,
            order.makerAssetAddr,
            order.makerAssetAmount,
            order.receiverAddr,
            txMetaData.settleAmount,
            txMetaData.receivedAmount,
            txMetaData.feeFactor,
            txMetaData.subsidyFactor
        );

        return txMetaData.settleAmount;
    }

    /**
     * @dev internal function of `trade`.
     * Used to tell if maker is Curve.
     */
    function _isCurve(address _makerAddr) internal pure virtual returns (bool) {
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || _makerAddr == SUSHISWAP_ROUTER_ADDRESS) return false;
        else return true;
    }

    /**
     * @dev internal function of `trade`.
     * Used to tell if internal asset is ETH.
     */
    function _isInternalAssetETH(address _internalAssetAddr) internal pure returns (bool) {
        if (_internalAssetAddr == ETH_ADDRESS || _internalAssetAddr == ZERO_ADDRESS) return true;
        else return false;
    }

    /**
     * @dev internal function of `trade`.
     * Get this contract's eth balance or token balance.
     */
    function _getSelfBalance(address _makerAssetInternalAddr) internal view returns (uint256) {
        if (_isInternalAssetETH(_makerAssetInternalAddr)) {
            return address(this).balance;
        } else {
            return IERC20(_makerAssetInternalAddr).balanceOf(address(this));
        }
    }

    /**
     * @dev internal function of `trade`.
     * It verifies user signature and store tx hash to prevent replay attack.
     */
    function _verify(AMMLibEIP712.Order memory _order, bytes calldata _sig) internal returns (bytes32 transactionHash) {
        // Verify user signature
        transactionHash = AMMLibEIP712._getOrderHash(_order);
        bytes32 EIP712SignDigest = getEIP712Hash(transactionHash);
        require(isValidSignature(_order.userAddr, EIP712SignDigest, bytes(""), _sig), "AMMWrapper: invalid user signature");
        // Set transaction as seen, PermanentStorage would throw error if transaction already seen.
        permStorage.setAMMTransactionSeen(transactionHash);
    }

    /**
     * @dev internal function of `trade`.
     * It executes the swap on chosen AMM.
     */
    function _prepare(AMMLibEIP712.Order memory _order, InternalTxData memory _internalTxData) internal {
        // Transfer asset from user and deposit to weth if needed
        if (_internalTxData.fromEth) {
            require(msg.value > 0, "AMMWrapper: msg.value is zero");
            require(_order.takerAssetAmount == msg.value, "AMMWrapper: msg.value doesn't match");
            // Deposit ETH to WETH if internal asset is WETH instead of ETH
            if (!_isInternalAssetETH(_internalTxData.takerAssetInternalAddr)) {
                weth.deposit{ value: msg.value }();
            }
        } else {
            // other ERC20 tokens
            spender.spendFromUser(_order.userAddr, _order.takerAssetAddr, _order.takerAssetAmount);
        }
    }

    /**
     * @dev internal function of `trade`.
     * It executes the swap on chosen AMM.
     */
    function _swap(
        AMMLibEIP712.Order memory _order,
        InternalTxData memory _internalTxData,
        uint256 _minAmount
    )
        internal
        approveTakerAsset(_internalTxData.takerAssetInternalAddr, _order.makerAddr, _order.takerAssetAmount)
        returns (string memory source, uint256 receivedAmount)
    {
        if (_order.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || _order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            source = (_order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) ? "SushiSwap" : "Uniswap V2";
            // Sushiswap shares the same interface as Uniswap's
            receivedAmount = _tradeUniswapV2TokenToToken(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr,
                _order.takerAssetAmount,
                _minAmount,
                _order.deadline
            );
        } else {
            // Try to match maker with Curve pool list
            CurveData memory curveData;
            (curveData.fromTokenCurveIndex, curveData.toTokenCurveIndex, curveData.swapMethod, ) = permStorage.getCurvePoolInfo(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr
            );
            require(curveData.swapMethod != 0, "AMMWrapper: swap method not registered");
            if (curveData.fromTokenCurveIndex > 0 && curveData.toTokenCurveIndex > 0) {
                source = "Curve";
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                curveData.fromTokenCurveIndex = curveData.fromTokenCurveIndex - 1;
                curveData.toTokenCurveIndex = curveData.toTokenCurveIndex - 1;
                // Curve does not return amount swapped so we need to record balance change instead.
                uint256 balanceBeforeTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                _tradeCurveTokenToToken(
                    _order.makerAddr,
                    curveData.fromTokenCurveIndex,
                    curveData.toTokenCurveIndex,
                    _order.takerAssetAmount,
                    _minAmount,
                    curveData.swapMethod
                );
                uint256 balanceAfterTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                receivedAmount = balanceAfterTrade.sub(balanceBeforeTrade);
            } else {
                revert("AMMWrapper: unsupported makerAddr");
            }
        }
    }

    /**
     * @dev internal function of `trade`.
     * It collects fee from the trade or compensates the trade based on the actual amount swapped.
     */
    function _settle(
        AMMLibEIP712.Order memory _order,
        TxMetaData memory _txMetaData,
        InternalTxData memory _internalTxData
    ) internal returns (uint256 settleAmount) {
        // Convert var type from uint16 to uint256
        uint256 _feeFactor = _txMetaData.feeFactor;
        uint256 _subsidyFactor = _txMetaData.subsidyFactor;

        if (_txMetaData.receivedAmount == _order.makerAssetAmount) {
            settleAmount = _txMetaData.receivedAmount;
        } else if (_txMetaData.receivedAmount > _order.makerAssetAmount) {
            // shouldCollectFee = ((receivedAmount - makerAssetAmount) / receivedAmount) > (feeFactor / 10000)
            bool shouldCollectFee = _txMetaData.receivedAmount.sub(_order.makerAssetAmount).mul(BPS_MAX) > _feeFactor.mul(_txMetaData.receivedAmount);
            if (shouldCollectFee) {
                // settleAmount = receivedAmount * (1 - feeFactor) / 10000
                settleAmount = _txMetaData.receivedAmount.mul(BPS_MAX.sub(_feeFactor)).div(BPS_MAX);
            } else {
                settleAmount = _order.makerAssetAmount;
            }
        } else {
            require(_subsidyFactor > 0, "AMMWrapper: this trade will not be subsidized");

            // If fee factor is smaller than subsidy factor, choose fee factor as actual subsidy factor
            // since we should subsidize less if we charge less.
            uint256 actualSubsidyFactor = (_subsidyFactor < _feeFactor) ? _subsidyFactor : _feeFactor;

            // inSubsidyRange = ((makerAssetAmount - receivedAmount) / receivedAmount) > (actualSubsidyFactor / 10000)
            bool inSubsidyRange = _order.makerAssetAmount.sub(_txMetaData.receivedAmount).mul(BPS_MAX) <= actualSubsidyFactor.mul(_txMetaData.receivedAmount);
            require(inSubsidyRange, "AMMWrapper: amount difference larger than subsidy amount");

            uint256 selfBalance = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
            bool hasEnoughToSubsidize = selfBalance >= _order.makerAssetAmount;
            if (!hasEnoughToSubsidize && _isInternalAssetETH(_internalTxData.makerAssetInternalAddr)) {
                // We treat ETH and WETH the same so we have to convert WETH to ETH if ETH balance is not enough.
                uint256 amountShort = _order.makerAssetAmount.sub(selfBalance);
                if (amountShort <= weth.balanceOf(address(this))) {
                    // Withdraw the amount short from WETH
                    weth.withdraw(amountShort);
                    // Now we have enough
                    hasEnoughToSubsidize = true;
                }
            }
            require(hasEnoughToSubsidize, "AMMWrapper: not enough savings to subsidize");

            settleAmount = _order.makerAssetAmount;
        }

        // Transfer token/ETH to receiver
        if (_internalTxData.toEth) {
            // Withdraw from WETH if internal maker asset is WETH
            if (!_isInternalAssetETH(_internalTxData.makerAssetInternalAddr)) {
                weth.withdraw(settleAmount);
            }
            _order.receiverAddr.transfer(settleAmount);
        } else {
            // other ERC20 tokens
            IERC20(_order.makerAssetAddr).safeTransfer(_order.receiverAddr, settleAmount);
        }
    }

    function _tradeCurveTokenToToken(
        address _makerAddr,
        int128 i,
        int128 j,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint16 _swapMethod
    ) internal {
        ICurveFi curve = ICurveFi(_makerAddr);
        if (_swapMethod == 1) {
            curve.exchange{ value: msg.value }(i, j, _takerAssetAmount, _makerAssetAmount);
        } else if (_swapMethod == 2) {
            curve.exchange_underlying{ value: msg.value }(i, j, _takerAssetAmount, _makerAssetAmount);
        }
    }

    function _tradeUniswapV2TokenToToken(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _deadline
    ) internal returns (uint256) {
        IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
        address[] memory path = new address[](2);
        path[0] = _takerAssetAddr;
        path[1] = _makerAssetAddr;
        uint256[] memory amounts = router.swapExactTokensForTokens(_takerAssetAmount, _makerAssetAmount, path, address(this), _deadline);
        return amounts[1];
    }
}

pragma solidity >=0.7.0;
pragma abicoder v2;

/// @dev Minimal Balancer V2 Vault interface
///      for documentation refer to https://github.com/balancer-labs/balancer-core-v2/blob/master/contracts/vault/interfaces/IVault.sol
interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library AMMLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    struct Order {
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address userAddr;
        address payable receiverAddr;
        uint256 salt;
        uint256 deadline;
    }

    bytes32 public constant TRADE_WITH_PERMIT_TYPEHASH = 0x213bb100dae8406fe07494ce25c2bfdb417aafdf4a6df7355a70d2d48823c418;

    /*
        keccak256(
            abi.encodePacked(
                "tradeWithPermit(",
                "address makerAddr,",
                "address takerAssetAddr,",
                "address makerAssetAddr,",
                "uint256 takerAssetAmount,",
                "uint256 makerAssetAmount,",
                "address userAddr,",
                "address receiverAddr,",
                "uint256 salt,",
                "uint256 deadline",
                ")"
            )
        );
        */

    function _getOrderHash(Order memory _order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TRADE_WITH_PERMIT_TYPEHASH,
                    _order.makerAddr,
                    _order.takerAssetAddr,
                    _order.makerAssetAddr,
                    _order.takerAssetAmount,
                    _order.makerAssetAmount,
                    _order.userAddr,
                    _order.receiverAddr,
                    _order.salt,
                    _order.deadline
                )
            );
    }
}

pragma solidity >=0.7.0;

interface ICurveFi {
    function get_virtual_price() external returns (uint256 out);

    function add_liquidity(uint256[2] calldata amounts, uint256 deadline) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function get_dx(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256 out);

    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256 out);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 out);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external payable;

    function remove_liquidity(
        uint256 _amount,
        uint256 deadline,
        uint256[2] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 deadline) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function commit_new_parameters(
        int128 amplification,
        int128 new_fee,
        int128 new_admin_fee
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function coins(int128 arg0) external returns (address out);

    function underlying_coins(int128 arg0) external returns (address out);

    function balances(int128 arg0) external returns (uint256 out);

    function A() external returns (int128 out);

    function fee() external returns (int128 out);

    function admin_fee() external returns (int128 out);

    function owner() external returns (address out);

    function admin_actions_deadline() external returns (uint256 out);

    function transfer_ownership_deadline() external returns (uint256 out);

    function future_A() external returns (int128 out);

    function future_fee() external returns (int128 out);

    function future_admin_fee() external returns (int128 out);

    function future_owner() external returns (address out);
}

pragma solidity >=0.7.0;

import "./ISetAllowance.sol";

interface IAMMWrapper is ISetAllowance {
    function trade(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _feeFactor,
        address _spender,
        address payable _receiver,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _sig
    ) external payable returns (uint256);
}

pragma solidity 0.7.6;
pragma abicoder v2;

import "../LibBytes.sol";
import "./LibOrder.sol";

contract LibDecoder {
    using LibBytes for bytes;

    function decodeFillOrder(bytes memory data)
        internal
        pure
        returns (
            LibOrder.Order memory order,
            uint256 takerFillAmount,
            bytes memory mmSignature
        )
    {
        require(data.length > 800, "LibDecoder: LENGTH_LESS_800");

        // compare method_id
        // 0x64a3bc15 is fillOrKillOrder's method id.
        require(data.readBytes4(0) == 0x64a3bc15, "LibDecoder: WRONG_METHOD_ID");

        bytes memory dataSlice;
        assembly {
            dataSlice := add(data, 4)
        }
        return abi.decode(dataSlice, (LibOrder.Order, uint256, bytes));
    }

    function decodeMmSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s);
    }

    function decodeUserSignatureWithoutSign(bytes memory signature) internal pure returns (address receiver) {
        require(signature.length == 85 || signature.length == 86, "LibDecoder: LENGTH_85_REQUIRED");
        receiver = signature.readAddress(65);

        return receiver;
    }

    function decodeUserSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s,
            address receiver
        )
    {
        receiver = decodeUserSignatureWithoutSign(signature);

        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s, receiver);
    }

    function decodeERC20Asset(bytes memory assetData) internal pure returns (address) {
        require(assetData.length == 36, "LibDecoder: LENGTH_36_REQUIRED");

        return assetData.readAddress(16);
    }
}

pragma solidity 0.7.6;

import "./LibEIP712.sol";

contract LibOrder is LibEIP712 {
    // Hash for the EIP712 Order Schema
    bytes32 internal constant EIP712_ORDER_SCHEMA_HASH =
        keccak256(
            abi.encodePacked(
                "Order(",
                "address makerAddress,",
                "address takerAddress,",
                "address feeRecipientAddress,",
                "address senderAddress,",
                "uint256 makerAssetAmount,",
                "uint256 takerAssetAmount,",
                "uint256 makerFee,",
                "uint256 takerFee,",
                "uint256 expirationTimeSeconds,",
                "uint256 salt,",
                "bytes makerAssetData,",
                "bytes takerAssetData",
                ")"
            )
        );

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's state is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID, // Default value
        INVALID_MAKER_ASSET_AMOUNT, // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT, // Order does not have a valid taker asset amount
        FILLABLE, // Order is fillable
        EXPIRED, // Order has already expired
        FULLY_FILLED, // Order is fully filled
        CANCELLED // Order has been cancelled
    }

    // solhint-disable max-line-length
    struct Order {
        address makerAddress; // Address that created the order.
        address takerAddress; // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress; // Address that will recieve fees when order is filled.
        address senderAddress; // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount; // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount; // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee; // Amount of ZRX paid to feeRecipient by maker when order is filled. If set to 0, no transfer of ZRX from maker to feeRecipient will be attempted.
        uint256 takerFee; // Amount of ZRX paid to feeRecipient by taker when order is filled. If set to 0, no transfer of ZRX from taker to feeRecipient will be attempted.
        uint256 expirationTimeSeconds; // Timestamp in seconds at which order expires.
        uint256 salt; // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData; // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The last byte references the id of this proxy.
        bytes takerAssetData; // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The last byte references the id of this proxy.
    }
    // solhint-enable max-line-length

    struct OrderInfo {
        uint8 orderStatus; // Status that describes order's validity and fillability.
        bytes32 orderHash; // EIP712 hash of the order (see LibOrder.getOrderHash).
        uint256 orderTakerAssetFilledAmount; // Amount of order that has already been filled.
    }

    /// @dev Calculates Keccak-256 hash of the order.
    /// @param order The order structure.
    /// @return orderHash Keccak-256 EIP712 hash of the order.
    function getOrderHash(Order memory order) internal view returns (bytes32 orderHash) {
        orderHash = hashEIP712Message(hashOrder(order));
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order.
    /// @param order The order structure.
    /// @return result EIP712 hash of the order.
    function hashOrder(Order memory order) internal pure returns (bytes32 result) {
        bytes32 schemaHash = EIP712_ORDER_SCHEMA_HASH;
        bytes32 makerAssetDataHash = keccak256(order.makerAssetData);
        bytes32 takerAssetDataHash = keccak256(order.takerAssetData);

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ORDER_SCHEMA_HASH,
        //     bytes32(order.makerAddress),
        //     bytes32(order.takerAddress),
        //     bytes32(order.feeRecipientAddress),
        //     bytes32(order.senderAddress),
        //     order.makerAssetAmount,
        //     order.takerAssetAmount,
        //     order.makerFee,
        //     order.takerFee,
        //     order.expirationTimeSeconds,
        //     order.salt,
        //     keccak256(order.makerAssetData),
        //     keccak256(order.takerAssetData)
        // ));

        assembly {
            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)

            // Backup
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)

            // Hash in place
            mstore(pos1, schemaHash)
            mstore(pos2, makerAssetDataHash)
            mstore(pos3, takerAssetDataHash)
            result := keccak256(pos1, 416)

            // Restore
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
        }
        return result;
    }
}

pragma solidity 0.7.6;

contract LibEIP712 {
    // EIP191 header for EIP712 prefix
    string internal constant EIP191_HEADER = "\x19\x01";

    // EIP712 Domain Name value
    string internal constant EIP712_DOMAIN_NAME = "0x Protocol";

    // EIP712 Domain Version value
    string internal constant EIP712_DOMAIN_VERSION = "2";

    // Hash of the EIP712 Domain Separator Schema
    bytes32 internal constant EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        keccak256(abi.encodePacked("EIP712Domain(", "string name,", "string version,", "address verifyingContract", ")"));

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    constructor() public {
        EIP712_DOMAIN_HASH = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                bytes12(0),
                address(this)
            )
        );
    }

    /// @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to this EIP712 Domain.
    function hashEIP712Message(bytes32 hashStruct) internal view returns (bytes32 result) {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IPMM.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IERC1271Wallet.sol";
import "./interfaces/IZeroExchange.sol";
import "./utils/pmm/LibOrder.sol";
import "./utils/pmm/LibDecoder.sol";
import "./utils/pmm/LibEncoder.sol";

contract PMM is ReentrancyGuard, IPMM, LibOrder, LibDecoder, LibEncoder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Constants do not have storage slot.
    string public constant version = "5.0.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    string public constant SOURCE = "0x v2";
    uint256 private constant BPS_MAX = 10000;
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    address public immutable userProxy;
    ISpender public immutable spender;
    IPermanentStorage public immutable permStorage;
    IZeroExchange public immutable zeroExchange;
    address public immutable zxERC20Proxy;

    // Below are the variables which consume storage slots.
    address public operator;

    struct TradeInfo {
        address user;
        address receiver;
        uint16 feeFactor;
        address makerAssetAddr;
        address takerAssetAddr;
        bytes32 transactionHash;
        bytes32 orderHash;
    }

    // events
    event FillOrder(
        string source,
        bytes32 indexed transactionHash,
        bytes32 indexed orderHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint16 feeFactor
    );

    receive() external payable {}

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "PMM: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "PMM: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "AMMWrapper: operator can not be zero address");
        operator = _newOperator;
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _operator,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IZeroExchange _zeroExchange,
        address _zxERC20Proxy
    ) public {
        operator = _operator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        zeroExchange = _zeroExchange;
        zxERC20Proxy = _zxERC20Proxy;
        // This constant follows ZX_EXCHANGE address
        EIP712_DOMAIN_HASH = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                bytes12(0),
                address(_zeroExchange)
            )
        );
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/
    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);
        }
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    function fill(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    ) public payable override onlyUserProxy nonReentrant returns (uint256) {
        // decode & assert
        (LibOrder.Order memory order, TradeInfo memory tradeInfo) = _assertTransaction(userSalt, data, userSignature);

        // Deposit to WETH if taker asset is ETH, else transfer from user
        IWETH weth = IWETH(permStorage.wethAddr());
        if (address(weth) == tradeInfo.takerAssetAddr) {
            require(msg.value == order.takerAssetAmount, "PMM: insufficient ETH");
            weth.deposit{ value: msg.value }();
        } else {
            spender.spendFromUser(tradeInfo.user, tradeInfo.takerAssetAddr, order.takerAssetAmount);
        }

        IERC20(tradeInfo.takerAssetAddr).safeIncreaseAllowance(zxERC20Proxy, order.takerAssetAmount);

        // send tx to 0x
        zeroExchange.executeTransaction(userSalt, address(this), data, "");

        // settle token/ETH to user
        uint256 settleAmount = _settle(weth, tradeInfo.receiver, tradeInfo.makerAssetAddr, order.makerAssetAmount, tradeInfo.feeFactor);
        IERC20(tradeInfo.takerAssetAddr).safeApprove(zxERC20Proxy, 0);

        emit FillOrder(
            SOURCE,
            tradeInfo.transactionHash,
            tradeInfo.orderHash,
            tradeInfo.user,
            tradeInfo.takerAssetAddr,
            order.takerAssetAmount,
            order.makerAddress,
            tradeInfo.makerAssetAddr,
            order.makerAssetAmount,
            tradeInfo.receiver,
            settleAmount,
            tradeInfo.feeFactor
        );
        return settleAmount;
    }

    /**
     * @dev internal function of `fill`.
     * It decodes and validates transaction data.
     */
    function _assertTransaction(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    ) internal view returns (LibOrder.Order memory order, TradeInfo memory tradeInfo) {
        // decode fillOrder data
        uint256 takerFillAmount;
        bytes memory mmSignature;
        (order, takerFillAmount, mmSignature) = decodeFillOrder(data);

        require(order.takerAddress == address(this), "PMM: incorrect taker");
        require(order.takerAssetAmount == takerFillAmount, "PMM: incorrect fill amount");

        // generate transactionHash
        tradeInfo.transactionHash = encodeTransactionHash(userSalt, address(this), data);

        tradeInfo.orderHash = getOrderHash(order);
        tradeInfo.feeFactor = uint16(order.salt);
        tradeInfo.receiver = decodeUserSignatureWithoutSign(userSignature);
        tradeInfo.user = _ecrecoverAddress(tradeInfo.transactionHash, userSignature);

        if (tradeInfo.user != order.feeRecipientAddress) {
            require(order.feeRecipientAddress.isContract(), "PMM: invalid contract address");
            // isValidSignature() should return magic value: bytes4(keccak256("isValidSignature(bytes32,bytes)"))
            require(
                ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(order.feeRecipientAddress).isValidSignature(tradeInfo.transactionHash, userSignature),
                "PMM: invalid ERC1271 signer"
            );
            tradeInfo.user = order.feeRecipientAddress;
        }

        require(tradeInfo.feeFactor < 10000, "PMM: invalid fee factor");

        require(tradeInfo.receiver != address(0), "PMM: invalid receiver");

        // decode asset
        // just support ERC20
        tradeInfo.makerAssetAddr = decodeERC20Asset(order.makerAssetData);
        tradeInfo.takerAssetAddr = decodeERC20Asset(order.takerAssetData);
        return (order, tradeInfo);
    }

    // settle
    function _settle(
        IWETH weth,
        address receiver,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        uint16 feeFactor
    ) internal returns (uint256) {
        uint256 settleAmount = makerAssetAmount;
        if (feeFactor > 0) {
            // settleAmount = settleAmount * (10000 - feeFactor) / 10000
            settleAmount = settleAmount.mul((BPS_MAX).sub(feeFactor)).div(BPS_MAX);
        }

        if (makerAssetAddr == address(weth)) {
            weth.withdraw(settleAmount);
            payable(receiver).transfer(settleAmount);
        } else {
            IERC20(makerAssetAddr).safeTransfer(receiver, settleAmount);
        }

        return settleAmount;
    }

    function _ecrecoverAddress(bytes32 transactionHash, bytes memory signature) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s, address receiver) = decodeUserSignature(signature);
        return ecrecover(keccak256(abi.encodePacked(transactionHash, receiver)), v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ISetAllowance.sol";

interface IPMM is ISetAllowance {
    function fill(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    ) external payable returns (uint256);
}

pragma solidity >=0.7.0;

interface IZeroExchange {
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes calldata data,
        bytes calldata signature
    ) external;
}

pragma solidity 0.7.6;

import "./LibEIP712.sol";

contract LibEncoder is LibEIP712 {
    // Hash for the EIP712 ZeroEx Transaction Schema
    bytes32 internal constant EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH =
        keccak256(abi.encodePacked("ZeroExTransaction(", "uint256 salt,", "address signerAddress,", "bytes data", ")"));

    function encodeTransactionHash(
        uint256 salt,
        address signerAddress,
        bytes memory data
    ) internal view returns (bytes32 result) {
        bytes32 schemaHash = EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH;
        bytes32 dataHash = keccak256(data);

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH,
        //     salt,
        //     bytes32(signerAddress),
        //     keccak256(data)
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, schemaHash) // hash of schema
            mstore(add(memPtr, 32), salt) // salt
            mstore(add(memPtr, 64), and(signerAddress, 0xffffffffffffffffffffffffffffffffffffffff)) // signerAddress
            mstore(add(memPtr, 96), dataHash) // hash of data

            // Compute hash
            result := keccak256(memPtr, 128)
        }
        result = hashEIP712Message(result);
        return result;
    }
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/ISetAllowance.sol";
import "../../interfaces/IERC1271Wallet.sol";

contract MockERC1271Wallet is ISetAllowance, IERC1271Wallet {
    using SafeERC20 for IERC20;
    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;
    uint256 private constant MAX_UINT = 2**256 - 1;
    address public operator;

    modifier onlyOperator() {
        require(operator == msg.sender, "MockERC1271Wallet: not the operator");
        _;
    }

    constructor(address _operator) {
        operator = _operator;
    }

    function setAllowance(address[] memory _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] memory _tokenList, address _spender) external override onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);
        }
    }

    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view override returns (bytes4 magicValue) {
        return ERC1271_MAGICVALUE;
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view override returns (bytes4 magicValue) {
        return ERC1271_MAGICVALUE_BYTES32;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./interfaces/IPermanentStorage.sol";
import "./utils/PSStorage.sol";

contract PermanentStorage is IPermanentStorage {
    // Constants do not have storage slot.
    bytes32 public constant curveTokenIndexStorageId = 0xf4c750cdce673f6c35898d215e519b86e3846b1f0532fb48b84fe9d80f6de2fc; // keccak256("curveTokenIndex")
    bytes32 public constant transactionSeenStorageId = 0x695d523b8578c6379a2121164fd8de334b9c5b6b36dff5408bd4051a6b1704d0; // keccak256("transactionSeen")
    bytes32 public constant relayerValidStorageId = 0x2c97779b4deaf24e9d46e02ec2699240a957d92782b51165b93878b09dd66f61; // keccak256("relayerValid")
    bytes32 public constant allowFillSeenStorageId = 0x808188d002c47900fbb4e871d29754afff429009f6684806712612d807395dd8; // keccak256("allowFillSeen")

    // New supported Curve pools
    address public constant CURVE_renBTC_POOL = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address public constant CURVE_sBTC_POOL = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address public constant CURVE_hBTC_POOL = 0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F;
    address public constant CURVE_sETH_POOL = 0xc5424B857f758E906013F3555Dad202e4bdB4567;

    // Curve coins
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant renBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address private constant wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address private constant hBTC = 0x0316EB71485b0Ab14103307bf65a021042c6d380;
    address private constant sETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;

    // Below are the variables which consume storage slots.
    address public operator;
    string public version; // Current version of the contract
    mapping(bytes32 => mapping(address => bool)) private permission;

    // Operator events
    event TransferOwnership(address newOperator);
    event SetPermission(bytes32 storageId, address role, bool enabled);
    event UpgradeAMMWrapper(address newAMMWrapper);
    event UpgradePMM(address newPMM);
    event UpgradeRFQ(address newRFQ);
    event UpgradeLimitOrder(address newLimitOrder);
    event UpgradeWETH(address newWETH);
    event SetCurvePoolInfo(address makerAddr, address[] underlyingCoins, address[] coins, bool supportGetD);
    event SetRelayerValid(address relayer, bool valid);

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "PermanentStorage: not the operator");
        _;
    }

    modifier validRole(bool _enabled, address _role) {
        if (_enabled) {
            require(
                (_role == operator) || (_role == ammWrapperAddr()) || (_role == pmmAddr()) || (_role == rfqAddr()) || (_role == limitOrderAddr()),
                "PermanentStorage: not a valid role"
            );
        }
        _;
    }

    modifier isPermitted(bytes32 _storageId, address _role) {
        require(permission[_storageId][_role], "PermanentStorage: has no permission");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "PermanentStorage: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    /// @dev Set permission for entity to write certain storage.
    function setPermission(
        bytes32 _storageId,
        address _role,
        bool _enabled
    ) external onlyOperator validRole(_enabled, _role) {
        permission[_storageId][_role] = _enabled;

        emit SetPermission(_storageId, _role, _enabled);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize(address _operator) external {
        require(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("")), "PermanentStorage: not upgrading from empty");
        require(_operator != address(0), "PermanentStorage: operator can not be zero address");
        operator = _operator;

        // Upgrade version
        version = "5.3.0";
    }

    /************************************************************
     *                     Getter functions                      *
     *************************************************************/
    function hasPermission(bytes32 _storageId, address _role) external view returns (bool) {
        return permission[_storageId][_role];
    }

    function ammWrapperAddr() public view returns (address) {
        return PSStorage.getStorage().ammWrapperAddr;
    }

    function pmmAddr() public view returns (address) {
        return PSStorage.getStorage().pmmAddr;
    }

    function rfqAddr() public view returns (address) {
        return PSStorage.getStorage().rfqAddr;
    }

    function limitOrderAddr() public view returns (address) {
        return PSStorage.getStorage().limitOrderAddr;
    }

    function wethAddr() external view override returns (address) {
        return PSStorage.getStorage().wethAddr;
    }

    function getCurvePoolInfo(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr
    )
        external
        view
        override
        returns (
            int128 takerAssetIndex,
            int128 makerAssetIndex,
            uint16 swapMethod,
            bool supportGetDx
        )
    {
        // underlying_coins
        int128 i = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_takerAssetAddr];
        int128 j = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_makerAssetAddr];
        supportGetDx = AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr];

        swapMethod = 0;
        if (i != 0 && j != 0) {
            // in underlying_coins list
            takerAssetIndex = i;
            makerAssetIndex = j;
            // exchange_underlying
            swapMethod = 2;
        } else {
            // in coins list
            int128 iWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_takerAssetAddr];
            int128 jWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_makerAssetAddr];
            if (iWrapped != 0 && jWrapped != 0) {
                takerAssetIndex = iWrapped;
                makerAssetIndex = jWrapped;
                // exchange
                swapMethod = 1;
            } else {
                revert("PermanentStorage: invalid pair");
            }
        }
        return (takerAssetIndex, makerAssetIndex, swapMethod, supportGetDx);
    }

    /* 
    NOTE: `isTransactionSeen` is replaced by `isAMMTransactionSeen`. It is kept for backward compatability.
    It should be removed from AMM 5.2.1 upward.
    */
    function isTransactionSeen(bytes32 _transactionHash) external view override returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isAMMTransactionSeen(bytes32 _transactionHash) external view override returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRFQTransactionSeen(bytes32 _transactionHash) external view override returns (bool) {
        return RFQStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isLimitOrderTransactionSeen(bytes32 _transactionHash) external view override returns (bool) {
        return LimitOrderStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isLimitOrderAllowFillSeen(bytes32 _allowFillHash) external view override returns (bool) {
        return LimitOrderStorage.getStorage().allowFillSeen[_allowFillHash];
    }

    function isRelayerValid(address _relayer) external view override returns (bool) {
        return AMMWrapperStorage.getStorage().relayerValid[_relayer];
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/
    /// @dev Update AMMWrapper contract address.
    function upgradeAMMWrapper(address _newAMMWrapper) external onlyOperator {
        PSStorage.getStorage().ammWrapperAddr = _newAMMWrapper;

        emit UpgradeAMMWrapper(_newAMMWrapper);
    }

    /// @dev Update PMM contract address.
    function upgradePMM(address _newPMM) external onlyOperator {
        PSStorage.getStorage().pmmAddr = _newPMM;

        emit UpgradePMM(_newPMM);
    }

    /// @dev Update RFQ contract address.
    function upgradeRFQ(address _newRFQ) external onlyOperator {
        PSStorage.getStorage().rfqAddr = _newRFQ;

        emit UpgradeRFQ(_newRFQ);
    }

    /// @dev Update Limit Order contract address.
    function upgradeLimitOrder(address _newLimitOrder) external onlyOperator {
        PSStorage.getStorage().limitOrderAddr = _newLimitOrder;

        emit UpgradeLimitOrder(_newLimitOrder);
    }

    /// @dev Update WETH contract address.
    function upgradeWETH(address _newWETH) external onlyOperator {
        PSStorage.getStorage().wethAddr = _newWETH;

        emit UpgradeWETH(_newWETH);
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    function setCurvePoolInfo(
        address _makerAddr,
        address[] calldata _underlyingCoins,
        address[] calldata _coins,
        bool _supportGetDx
    ) external override isPermitted(curveTokenIndexStorageId, msg.sender) {
        int128 underlyingCoinsLength = int128(_underlyingCoins.length);
        for (int128 i = 0; i < underlyingCoinsLength; i++) {
            address assetAddr = _underlyingCoins[uint256(i)];
            // underlying coins for original DAI, USDC, TUSD
            AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][assetAddr] = i + 1; // Start the index from 1
        }

        int128 coinsLength = int128(_coins.length);
        for (int128 i = 0; i < coinsLength; i++) {
            address assetAddr = _coins[uint256(i)];
            // wrapped coins for cDAI, cUSDC, yDAI, yUSDC, yTUSD, yBUSD
            AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][assetAddr] = i + 1; // Start the index from 1
        }

        AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr] = _supportGetDx;
        emit SetCurvePoolInfo(_makerAddr, _underlyingCoins, _coins, _supportGetDx);
    }

    /* 
    NOTE: `setTransactionSeen` is replaced by `setAMMTransactionSeen`. It is kept for backward compatability.
    It should be removed from AMM 5.2.1 upward.
    */
    function setTransactionSeen(bytes32 _transactionHash) external override isPermitted(transactionSeenStorageId, msg.sender) {
        require(!AMMWrapperStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setAMMTransactionSeen(bytes32 _transactionHash) external override isPermitted(transactionSeenStorageId, msg.sender) {
        require(!AMMWrapperStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRFQTransactionSeen(bytes32 _transactionHash) external override isPermitted(transactionSeenStorageId, msg.sender) {
        require(!RFQStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        RFQStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setLimitOrderTransactionSeen(bytes32 _transactionHash) external override isPermitted(transactionSeenStorageId, msg.sender) {
        require(!LimitOrderStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        LimitOrderStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setLimitOrderAllowFillSeen(bytes32 _allowFillHash) external override isPermitted(allowFillSeenStorageId, msg.sender) {
        require(!LimitOrderStorage.getStorage().allowFillSeen[_allowFillHash], "PermanentStorage: allow fill seen before");
        LimitOrderStorage.getStorage().allowFillSeen[_allowFillHash] = true;
    }

    function setRelayersValid(address[] calldata _relayers, bool[] calldata _isValids) external override isPermitted(relayerValidStorageId, msg.sender) {
        require(_relayers.length == _isValids.length, "PermanentStorage: inputs length mismatch");
        for (uint256 i = 0; i < _relayers.length; i++) {
            AMMWrapperStorage.getStorage().relayerValid[_relayers[i]] = _isValids[i];
            emit SetRelayerValid(_relayers[i], _isValids[i]);
        }
    }
}

pragma solidity ^0.7.6;

library PSStorage {
    bytes32 private constant STORAGE_SLOT = 0x92dd52b981a2dd69af37d8a3febca29ed6a974aede38ae66e4ef773173aba471;

    struct Storage {
        address ammWrapperAddr;
        address pmmAddr;
        address wethAddr;
        address rfqAddr;
        address limitOrderAddr;
        address l2DepositAddr;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.storage.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := slot
        }
    }
}

library AMMWrapperStorage {
    bytes32 private constant STORAGE_SLOT = 0xd38d862c9fa97c2fa857a46e08022d272a3579c114ca4f335f1e5fcb692c045e;

    struct Storage {
        mapping(bytes32 => bool) transactionSeen;
        // curve pool => underlying token address => underlying token index
        mapping(address => mapping(address => int128)) curveTokenIndexes;
        mapping(address => bool) relayerValid;
        // 5.1.0 appended storage
        // curve pool => wrapped token address => wrapped token index
        mapping(address => mapping(address => int128)) curveWrappedTokenIndexes;
        mapping(address => bool) curveSupportGetDx;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.ammwrapper.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := slot
        }
    }
}

library RFQStorage {
    bytes32 private constant STORAGE_SLOT = 0x9174e76494cfb023ddc1eb0effb6c12e107165382bbd0ecfddbc38ea108bbe52;

    struct Storage {
        mapping(bytes32 => bool) transactionSeen;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.rfq.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := slot
        }
    }
}

library LimitOrderStorage {
    bytes32 private constant STORAGE_SLOT = 0xb1b5d1092eed9d9f9f6bdd5bf9fe04f7537770f37e1d84ac8960cc3acb80615c;

    struct Storage {
        mapping(bytes32 => bool) transactionSeen;
        mapping(bytes32 => bool) allowFillSeen;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.limitorder.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := slot
        }
    }
}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/ICurveFi.sol";
import "./interfaces/ICurveFiV2.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IUniswapV3Quoter.sol";
import "./interfaces/IBalancerV2Vault.sol";
import "./utils/LibBytes.sol";

/// This contract is designed to be called off-chain.
/// At T1, 4 requests would be made in order to get quote, which is for Uniswap v2, v3, Sushiswap and others.
/// For those source without path design, we can find best out amount in this contract.
/// For Uniswap and Sushiswap, best path would be calculated off-chain, we only verify out amount in this contract.

contract AMMQuoter {
    using SafeMath for uint256;
    using LibBytes for bytes;

    /* Constants */
    string public constant version = "5.2.0";
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant UNISWAP_V3_QUOTER_ADDRESS = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant BALANCER_V2_VAULT_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public immutable weth;
    IPermanentStorage public immutable permStorage;

    struct GroupedVars {
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address[] path;
    }

    event CurveTokenAdded(address indexed makerAddress, address indexed assetAddress, int128 index);

    constructor(IPermanentStorage _permStorage, address _weth) {
        permStorage = _permStorage;
        weth = _weth;
    }

    function isETH(address assetAddress) public pure returns (bool) {
        return (assetAddress == ZERO_ADDRESS || assetAddress == ETH_ADDRESS);
    }

    function _balancerFund() private view returns (IBalancerV2Vault.FundManagement memory) {
        return
            IBalancerV2Vault.FundManagement({ sender: address(this), fromInternalBalance: false, recipient: payable(address(this)), toInternalBalance: false });
    }

    function getMakerOutAmountWithPath(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        address[] calldata _path,
        bytes memory _makerSpecificData
    ) public returns (uint256) {
        GroupedVars memory vars;
        vars.makerAddr = _makerAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.takerAssetAmount = _takerAssetAmount;
        vars.path = _path;
        if (vars.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || vars.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(vars.makerAddr);
            uint256[] memory amounts = router.getAmountsOut(vars.takerAssetAmount, vars.path);
            return amounts[amounts.length - 1];
        } else if (vars.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            IUniswapV3Quoter quoter = IUniswapV3Quoter(UNISWAP_V3_QUOTER_ADDRESS);
            // swapType:
            // 1: exactInputSingle, 2: exactInput, 3: exactOuputSingle, 4: exactOutput
            uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));
            if (swapType == 1) {
                address v3TakerInternalAsset = isETH(vars.takerAssetAddr) ? weth : vars.takerAssetAddr;
                address v3MakerInternalAsset = isETH(vars.makerAssetAddr) ? weth : vars.makerAssetAddr;
                (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
                return quoter.quoteExactInputSingle(v3TakerInternalAsset, v3MakerInternalAsset, poolFee, vars.takerAssetAmount, 0);
            } else if (swapType == 2) {
                (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
                return quoter.quoteExactInput(path, vars.takerAssetAmount);
            }
            revert("AMMQuoter: Invalid UniswapV3 swap type");
        } else if (vars.makerAddr == BALANCER_V2_VAULT_ADDRESS) {
            IBalancerV2Vault vault = IBalancerV2Vault(BALANCER_V2_VAULT_ADDRESS);
            IBalancerV2Vault.FundManagement memory swapFund = _balancerFund();
            IBalancerV2Vault.BatchSwapStep[] memory swapSteps = abi.decode(_makerSpecificData, (IBalancerV2Vault.BatchSwapStep[]));

            int256[] memory amounts = vault.queryBatchSwap(IBalancerV2Vault.SwapKind.GIVEN_IN, swapSteps, _path, swapFund);
            int256 amountOutFromPool = amounts[_path.length - 1] * -1;
            if (amountOutFromPool <= 0) {
                revert("AMMQuoter: wrong amount from balancer pool");
            }
            return uint256(amountOutFromPool);
        }

        // Try to match maker with Curve pool list
        address curveTakerIntenalAsset = isETH(vars.takerAssetAddr) ? ETH_ADDRESS : vars.takerAssetAddr;
        address curveMakerIntenalAsset = isETH(vars.makerAssetAddr) ? ETH_ADDRESS : vars.makerAssetAddr;
        (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, ) = permStorage.getCurvePoolInfo(
            vars.makerAddr,
            curveTakerIntenalAsset,
            curveMakerIntenalAsset
        );
        require(fromTokenCurveIndex > 0 && toTokenCurveIndex > 0 && swapMethod != 0, "AMMQuoter: Unsupported makerAddr");

        uint8 curveVersion = uint8(uint256(_makerSpecificData.readBytes32(0)));
        return _getCurveMakerOutAmount(vars, curveVersion, fromTokenCurveIndex, toTokenCurveIndex, swapMethod);
    }

    function getMakerOutAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    ) public view returns (uint256) {
        uint256 makerAssetAmount;
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
            address[] memory path = new address[](2);
            if (isETH(_takerAssetAddr)) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (isETH(_makerAssetAddr)) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsOut(_takerAssetAmount, path);
            makerAssetAmount = amounts[1];
        } else {
            address curveTakerIntenalAsset = isETH(_takerAssetAddr) ? ETH_ADDRESS : _takerAssetAddr;
            address curveMakerIntenalAsset = isETH(_makerAssetAddr) ? ETH_ADDRESS : _makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, ) = permStorage.getCurvePoolInfo(
                _makerAddr,
                curveTakerIntenalAsset,
                curveMakerIntenalAsset
            );
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(_makerAddr);
                if (swapMethod == 1) {
                    makerAssetAmount = curve.get_dy(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
                } else if (swapMethod == 2) {
                    makerAssetAmount = curve.get_dy_underlying(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return makerAssetAmount;
    }

    /// @dev This function is designed for finding best out amount among AMM makers other than Uniswap and Sushiswap
    function getBestOutAmount(
        address[] calldata _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    ) external view returns (address bestMaker, uint256 bestAmount) {
        bestAmount = 0;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 makerAssetAmount = getMakerOutAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _takerAssetAmount);
            if (makerAssetAmount > bestAmount) {
                bestAmount = makerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function _getCurveMakerOutAmount(
        GroupedVars memory _vars,
        uint8 _curveVersion,
        int128 _fromTokenCurveIndex,
        int128 _toTokenCurveIndex,
        uint16 _swapMethod
    ) private view returns (uint256) {
        // Substract index by 1 because indices stored in `permStorage` starts from 1
        _fromTokenCurveIndex = _fromTokenCurveIndex - 1;
        _toTokenCurveIndex = _toTokenCurveIndex - 1;
        if (_curveVersion == 1) {
            ICurveFi curve = ICurveFi(_vars.makerAddr);
            if (_swapMethod == 1) {
                return curve.get_dy(_fromTokenCurveIndex, _toTokenCurveIndex, _vars.takerAssetAmount).sub(1);
            } else if (_swapMethod == 2) {
                return curve.get_dy_underlying(_fromTokenCurveIndex, _toTokenCurveIndex, _vars.takerAssetAmount).sub(1);
            }
        } else if (_curveVersion == 2) {
            require(_swapMethod == 1, "AMMQuoter: Curve v2 no underlying");
            ICurveFiV2 curve = ICurveFiV2(_vars.makerAddr);
            return curve.get_dy(uint256(_fromTokenCurveIndex), uint256(_toTokenCurveIndex), _vars.takerAssetAmount).sub(1);
        }
        revert("AMMQuoter: Invalid Curve version");
    }

    function getTakerInAmountWithPath(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount,
        address[] calldata _path,
        bytes memory _makerSpecificData
    ) public returns (uint256) {
        GroupedVars memory vars;
        vars.makerAddr = _makerAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.makerAssetAmount = _makerAssetAmount;
        vars.path = _path;
        if (vars.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || vars.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(vars.makerAddr);
            uint256[] memory amounts = router.getAmountsIn(vars.makerAssetAmount, _path);
            return amounts[0];
        } else if (vars.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            IUniswapV3Quoter quoter = IUniswapV3Quoter(UNISWAP_V3_QUOTER_ADDRESS);
            // swapType:
            // 1: exactInputSingle, 2: exactInput, 3: exactOuputSingle, 4: exactOutput
            uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));
            if (swapType == 3) {
                address v3TakerInternalAsset = isETH(vars.takerAssetAddr) ? weth : vars.takerAssetAddr;
                address v3MakerInternalAsset = isETH(vars.makerAssetAddr) ? weth : vars.makerAssetAddr;
                (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
                return quoter.quoteExactOutputSingle(v3TakerInternalAsset, v3MakerInternalAsset, poolFee, vars.makerAssetAmount, 0);
            } else if (swapType == 4) {
                (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
                return quoter.quoteExactOutput(path, vars.makerAssetAmount);
            }
            revert("AMMQuoter: Invalid UniswapV3 swap type");
        } else if (vars.makerAddr == BALANCER_V2_VAULT_ADDRESS) {
            IBalancerV2Vault vault = IBalancerV2Vault(BALANCER_V2_VAULT_ADDRESS);
            IBalancerV2Vault.FundManagement memory swapFund = _balancerFund();
            IBalancerV2Vault.BatchSwapStep[] memory swapSteps = abi.decode(_makerSpecificData, (IBalancerV2Vault.BatchSwapStep[]));

            int256[] memory amounts = vault.queryBatchSwap(IBalancerV2Vault.SwapKind.GIVEN_OUT, swapSteps, _path, swapFund);
            int256 amountInFromPool = amounts[0];
            if (amountInFromPool <= 0) {
                revert("AMMQuoter: wrong amount from balancer pool");
            }
            return uint256(amountInFromPool);
        }

        // Try to match maker with Curve pool list
        address curveTakerIntenalAsset = isETH(vars.takerAssetAddr) ? ETH_ADDRESS : vars.takerAssetAddr;
        address curveMakerIntenalAsset = isETH(vars.makerAssetAddr) ? ETH_ADDRESS : vars.makerAssetAddr;
        (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, bool supportGetDx) = permStorage.getCurvePoolInfo(
            vars.makerAddr,
            curveTakerIntenalAsset,
            curveMakerIntenalAsset
        );
        require(fromTokenCurveIndex > 0 && toTokenCurveIndex > 0 && swapMethod != 0, "AMMQuoter: Unsupported makerAddr");

        // Get Curve version to adopt correct interface
        uint8 curveVersion = uint8(uint256(_makerSpecificData.readBytes32(0)));
        return _getCurveTakerInAmount(vars, curveVersion, fromTokenCurveIndex, toTokenCurveIndex, swapMethod, supportGetDx);
    }

    function getTakerInAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    ) public view returns (uint256) {
        uint256 takerAssetAmount;
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS || _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
            address[] memory path = new address[](2);
            if (isETH(_takerAssetAddr)) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (isETH(_makerAssetAddr)) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsIn(_makerAssetAmount, path);
            takerAssetAmount = amounts[0];
        } else {
            address curveTakerIntenalAsset = isETH(_takerAssetAddr) ? ETH_ADDRESS : _takerAssetAddr;
            address curveMakerIntenalAsset = isETH(_makerAssetAddr) ? ETH_ADDRESS : _makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, bool supportGetDx) = permStorage.getCurvePoolInfo(
                _makerAddr,
                curveTakerIntenalAsset,
                curveMakerIntenalAsset
            );
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(_makerAddr);
                if (supportGetDx) {
                    if (swapMethod == 1) {
                        takerAssetAmount = curve.get_dx(fromTokenCurveIndex, toTokenCurveIndex, _makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dx_underlying(fromTokenCurveIndex, toTokenCurveIndex, _makerAssetAmount);
                    }
                } else {
                    if (swapMethod == 1) {
                        // does not support get_dx_underlying, try to get an estimated rate here
                        takerAssetAmount = curve.get_dy(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dy_underlying(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
                    }
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return takerAssetAmount;
    }

    /// @dev This function is designed for finding best in amount among AMM makers other than Uniswap and Sushiswap
    function getBestInAmount(
        address[] calldata _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    ) external view returns (address bestMaker, uint256 bestAmount) {
        bestAmount = 2**256 - 1;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 takerAssetAmount = getTakerInAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _makerAssetAmount);
            if (takerAssetAmount < bestAmount) {
                bestAmount = takerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function _getCurveTakerInAmount(
        GroupedVars memory _vars,
        uint8 _curveVersion,
        int128 _fromTokenCurveIndex,
        int128 _toTokenCurveIndex,
        uint16 _swapMethod,
        bool _supportGetDx
    ) private view returns (uint256) {
        // Substract index by 1 because indices stored in `permStorage` starts from 1
        _fromTokenCurveIndex = _fromTokenCurveIndex - 1;
        _toTokenCurveIndex = _toTokenCurveIndex - 1;
        if (_curveVersion == 1) {
            ICurveFi curve = ICurveFi(_vars.makerAddr);
            if (_supportGetDx) {
                if (_swapMethod == 1) {
                    return curve.get_dx(_fromTokenCurveIndex, _toTokenCurveIndex, _vars.makerAssetAmount);
                } else if (_swapMethod == 2) {
                    return curve.get_dx_underlying(_fromTokenCurveIndex, _toTokenCurveIndex, _vars.makerAssetAmount);
                }
                revert("AMMQuoter: Invalid curve swap method");
            } else {
                if (_swapMethod == 1) {
                    // does not support get_dx_underlying, try to get an estimated rate here
                    return curve.get_dy(_toTokenCurveIndex, _fromTokenCurveIndex, _vars.makerAssetAmount);
                } else if (_swapMethod == 2) {
                    return curve.get_dy_underlying(_toTokenCurveIndex, _fromTokenCurveIndex, _vars.makerAssetAmount);
                }
                revert("AMMQuoter: Invalid curve swap method");
            }
        } else if (_curveVersion == 2) {
            require(_swapMethod == 1, "AMMQuoter: Curve v2 no underlying");
            ICurveFiV2 curve = ICurveFiV2(_vars.makerAddr);
            // Not supporting get_dx, try to get estimated rate
            return curve.get_dy(uint256(_fromTokenCurveIndex), uint256(_toTokenCurveIndex), _vars.makerAssetAmount);
        }
        revert("AMMQuoter: Invalid Curve version");
    }
}

pragma solidity >=0.7.0;

interface ICurveFiV2 {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256 out);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;
}

pragma solidity >=0.7.0;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IUniswapV3Quoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IWeth.sol";
import "./utils/pmm/LibDecoder.sol";
import "./Ownable.sol";

interface IIMBTC {
    function burn(uint256 amount, bytes calldata data) external;
}

interface IWBTC {
    function burn(uint256 value) external;
}

contract MarketMakerProxy is Ownable, LibDecoder {
    using SafeERC20 for IERC20;

    string public constant version = "5.0.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    address public SIGNER;
    address public operator;

    // auto withdraw weth to eth
    address public WETH_ADDR;
    address public withdrawer;
    mapping(address => bool) public isWithdrawWhitelist;

    modifier onlyWithdrawer() {
        require(msg.sender == withdrawer, "MarketMakerProxy: only contract withdrawer");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "MarketMakerProxy: only contract operator");
        _;
    }

    constructor() Ownable(msg.sender) {
        operator = msg.sender;
    }

    receive() external payable {}

    // Manage
    function setSigner(address _signer) public onlyOperator {
        SIGNER = _signer;
    }

    function setConfig(address _weth) public onlyOperator {
        WETH_ADDR = _weth;
    }

    function setWithdrawer(address _withdrawer) public onlyOperator {
        withdrawer = _withdrawer;
    }

    function setOperator(address _newOperator) public onlyOwner {
        operator = _newOperator;
    }

    function setAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint256 i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            IERC20(token).safeApprove(spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint256 i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            IERC20(token).safeApprove(spender, 0);
        }
    }

    function registerWithdrawWhitelist(address _addr, bool _add) public onlyOperator {
        isWithdrawWhitelist[_addr] = _add;
    }

    function withdraw(
        address token,
        address payable to,
        uint256 amount
    ) public onlyWithdrawer {
        require(isWithdrawWhitelist[to], "MarketMakerProxy: not in withdraw whitelist");
        if (token == WETH_ADDR) {
            IWETH(WETH_ADDR).withdraw(amount);
            to.transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function withdrawETH(address payable to, uint256 amount) public onlyWithdrawer {
        require(isWithdrawWhitelist[to], "MarketMakerProxy: not in withdraw whitelist");
        to.transfer(amount);
    }

    function isValidSignature(bytes32 orderHash, bytes memory signature) public view returns (bytes32) {
        require(SIGNER == _ecrecoverAddress(orderHash, signature), "MarketMakerProxy: invalid signature");
        return keccak256("isValidWalletSignature(bytes32,address,bytes)");
    }

    function _ecrecoverAddress(bytes32 orderHash, bytes memory signature) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = decodeMmSignature(signature);
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(orderHash), v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";

import "./Proxy.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./upgrade_proxy/TransparentUpgradeableProxy.sol";

contract xLON is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}

pragma solidity 0.7.6;

import "./upgrade_proxy/TransparentUpgradeableProxy.sol";

contract Tokenlon is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) public payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./upgrade_proxy/TransparentUpgradeableProxy.sol";

contract ProxyPermanentStorage is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IEmergency.sol";
import "./Ownable.sol";
import "./utils/MerkleProof.sol";

contract MerkleRedeem is Ownable, ReentrancyGuard, IEmergency {
    using SafeMath for uint256;

    struct Claim {
        uint256 period;
        uint256 balance;
        bytes32[] proof;
    }

    IERC20 public rewardsToken;
    address public emergencyRecipient;

    // Recorded periods
    mapping(uint256 => bytes32) public periodMerkleRoots;
    mapping(uint256 => mapping(address => bool)) public claimed;

    /*==== PUBLIC FUNCTIONS =====*/
    constructor(
        address _owner,
        IERC20 _rewardsToken,
        address _emergencyRecipient
    ) Ownable(_owner) {
        emergencyRecipient = _emergencyRecipient;
        rewardsToken = _rewardsToken;
    }

    function claimPeriod(
        address recipient,
        uint256 period,
        uint256 balance,
        bytes32[] memory proof
    ) external nonReentrant {
        require(!claimed[period][recipient]);
        require(verifyClaim(recipient, period, balance, proof), "incorrect merkle proof");

        claimed[period][recipient] = true;
        _disburse(recipient, balance);
    }

    function verifyClaim(
        address recipient,
        uint256 period,
        uint256 balance,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(recipient, balance));
        return MerkleProof.verify(proof, periodMerkleRoots[period], leaf);
    }

    function claimPeriods(address recipient, Claim[] memory claims) external nonReentrant {
        uint256 totalBalance = 0;
        Claim memory claim;

        for (uint256 i = 0; i < claims.length; i++) {
            claim = claims[i];

            require(!claimed[claim.period][recipient]);
            require(verifyClaim(recipient, claim.period, claim.balance, claim.proof), "incorrect merkle proof");

            totalBalance = totalBalance.add(claim.balance);
            claimed[claim.period][recipient] = true;
        }

        _disburse(recipient, totalBalance);
    }

    function claimStatus(
        address recipient,
        uint256 begin,
        uint256 end
    ) external view returns (bool[] memory) {
        uint256 size = 1 + end - begin;
        bool[] memory arr = new bool[](size);
        for (uint256 i = 0; i < size; i++) {
            arr[i] = claimed[begin + i][recipient];
        }
        return arr;
    }

    function merkleRoots(uint256 begin, uint256 end) external view returns (bytes32[] memory) {
        uint256 size = 1 + end - begin;
        bytes32[] memory arr = new bytes32[](size);
        for (uint256 i = 0; i < size; i++) {
            arr[i] = periodMerkleRoots[begin + i];
        }
        return arr;
    }

    function emergencyWithdraw(IERC20 token) external override {
        require(token != rewardsToken, "forbidden token");

        token.transfer(emergencyRecipient, token.balanceOf(address(this)));
    }

    function seedAllocations(
        uint256 period,
        bytes32 merkleRoot,
        uint256 totalAllocation
    ) external onlyOwner {
        require(periodMerkleRoots[period] == bytes32(0), "already seed");

        periodMerkleRoots[period] = merkleRoot;
        require(rewardsToken.transferFrom(msg.sender, address(this), totalAllocation), "transfer failed");
    }

    function _disburse(address recipient, uint256 balance) private {
        if (balance > 0) {
            rewardsToken.transfer(recipient, balance);
            emit Claimed(recipient, balance);
        }
    }

    /*==== EVENTS ====*/
    event Claimed(address indexed recipient, uint256 balance);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}