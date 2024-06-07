// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library RebateCalculator {

    uint256 constant UONE = 1e18;

    // Calculate currentRate and tierRebate by linear interpolation
    function calculateTierRebate(
        uint256 startFee,
        uint256 startRate,
        uint256 endFee,
        uint256 endRate,
        uint256 fee
    ) internal pure returns (uint256 currentRate, uint256 tierRebate)
    {
        require(fee >= startFee && fee < endFee, "wrong tier");
        currentRate = (fee - startFee) * (endRate - startRate) / (endFee - startFee) + startRate;
        tierRebate = (currentRate + startRate) / 2 * (fee - startFee) / UONE;
    }

    // Fee Ranges and Rates:
    // Fee range >= 10000: rate = 40%
    // Fee range >= 6000 and < 10000: rate = [32%, 40%]
    // Fee range >= 4000 and < 6000: rate = [28%, 32%]
    // Fee range >= 2000 and < 4000: rate = [24%, 28%]
    // Fee range >= 1000 and < 2000: rate = [20%, 24%]
    // Fee range >= 10 and < 1000: rate = 20%
    function calculateTotalRebate(uint256 fee)
    internal pure returns (uint256 currentRate, uint256 totalRebate)
    {
        uint256 tierRebate;
        if (fee >= 10000e18) {
            currentRate = 40e16;
            totalRebate = (fee - 10000e18) * currentRate / UONE + 2980e18;
        } else if (fee >= 6000e18) {
            (currentRate, tierRebate) = calculateTierRebate(6000e18, 32e16, 10000e18, 40e16, fee);
            totalRebate = tierRebate + 1540e18;
        } else if (fee >= 4000e18) {
            (currentRate, tierRebate) = calculateTierRebate(4000e18, 28e16, 6000e18, 32e16, fee);
            totalRebate = tierRebate + 940e18;
        } else if (fee >= 2000e18) {
            (currentRate, tierRebate) = calculateTierRebate(2000e18, 24e16, 4000e18, 28e16, fee);
            totalRebate = tierRebate + 420e18;
        } else if (fee >= 1000e18) {
            (currentRate, tierRebate) = calculateTierRebate(1000e18, 20e16, 2000e18, 24e16, fee);
            totalRebate = tierRebate + 200e18;
        } else if (fee >= 10e18) {
            currentRate = 20e16;
            totalRebate = fee * currentRate / UONE;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "../utils/SafeERC20.sol";
import "../utils/SafeMath.sol";
import "./RebateCalculator.sol";
import "./RebateStorage.sol";

contract RebateImplementation is RebateStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for int256;

    event NewUpdater(address updater);

    event NewApprover(address approver);

    event TraderRegistered(
        address indexed trader,
        address indexed broker,
        uint256 timestamp
    );

    event BrokerRegistered(
        address indexed broker,
        address indexed recruiter,
        uint256 timestamp
    );

    event RecruiterRegistered(
        address indexed recruiter,
        uint256 timestamp
    );

    event ClaimRebate(address indexed account, uint256 amount);

    uint256 constant UONE = 1e18;

    uint256 constant BROKER_RATE = 1e18;

    uint256 constant RECRUITER_RATE = 0;

    address public immutable tokenB0;

    address public immutable protocolFeeManager;

    constructor (address tokenB0_, address protocolFeeManager_) {
        tokenB0 = tokenB0_;
        protocolFeeManager = protocolFeeManager_;
    }

    function setUpdater(address newUpdater) external _onlyAdmin_ {
        require(
            newUpdater != updater,
            'RebateImplementation: already current updater'
        );
        updater = newUpdater;
        emit NewUpdater(newUpdater);
    }

    function setApprover(address newApprover) external _onlyAdmin_ {
        require(
            newApprover != approver,
            'RebateImplementation: already current approver'
        );
        approver = newApprover;
        emit NewApprover(newApprover);
    }

    function registerTrader(string calldata brokerCode) external {
        address account = msg.sender;
        bytes32 brokerId = keccak256(abi.encodePacked(brokerCode));
        address brokerAddress = brokerAddresses[brokerId];

        require(
            brokerAddress != address(0),
            'RebateImplementation: referral not exist'
        );
        require(
            traderReferral[account] == address(0),
            'RebateImplementation: can not reset'
        );

        traderReferral[account] = brokerAddress;
        emit TraderRegistered(account, brokerAddress, block.timestamp);
    }

    function registerBroker(
        string calldata brokerCode,
        string calldata recruiterCode
    ) external {
        address account = msg.sender;
        bytes32 brokerId = keccak256(abi.encodePacked(brokerCode));
        bytes32 recruiterId = keccak256(abi.encodePacked(recruiterCode));
        address recruiter = recruiterAddresses[recruiterId];
        require(
            brokerAddresses[brokerId] == address(0),
            'RebateImplementation: code not available'
        );
        require(
            brokerIds[account] == bytes32(0),
            'RebateImplementation: can not reset'
        );
        require(
            recruiter != address(0),
            'RebateImplementation: referral not exist'
        );

        brokerAddresses[brokerId] = account;
        brokerIds[account] = brokerId;
        brokerInfos[account] = BrokerInfo({
            code: brokerCode,
            id: brokerId,
            referral: recruiter
        });

        emit BrokerRegistered(account, recruiter, block.timestamp);
    }

    function registerRecruiter(
        address recruiter,
        string calldata recruiterCode
    ) external {
        require(msg.sender == approver, 'RebateImplementation: only approver');
        bytes32 recruiterId = keccak256(abi.encodePacked(recruiterCode));
        require(
            recruiterAddresses[recruiterId] == address(0),
            'RebateImplementation: code not available'
        );
        require(
            recruiterIds[recruiter] == bytes32(0),
            'RebateImplementation: can not reset'
        );

        recruiterAddresses[recruiterId] = recruiter;
        recruiterIds[recruiter] = recruiterId;
        recruiterInfos[recruiter] = RecruiterInfo({
            code: recruiterCode,
            id: recruiterId
        });

        emit RecruiterRegistered(recruiter, block.timestamp);
    }

    struct BrokerTradingFee {
        address broker;
        uint256 tradingFee;
    }

    function updateFees(BrokerTradingFee[] calldata brokerTradingFees, uint256 timestamp) external {
        require(msg.sender == updater, 'RebateImplementation: only updater');
        require(timestamp > updatedTimestamp, 'RebateImplementation: duplicate update');

        uint256 unclaimed;
        for (uint256 i = 0; i < brokerTradingFees.length; i++) {
            address broker = brokerTradingFees[i].broker;
            uint256 tradingFee = brokerTradingFees[i].tradingFee;
            address recruiter = brokerInfos[broker].referral;

            uint256 fee = brokerFees[broker].itou();
            (, uint256 totalRebateBefore) = RebateCalculator.calculateTotalRebate(fee);
            (, uint256 totalRebateAfter) = RebateCalculator.calculateTotalRebate(fee + tradingFee);
            uint256 rebate = totalRebateAfter - totalRebateBefore;

            unclaimed += rebate;
            brokerFees[broker] += tradingFee.utoi();
            recruiterUnClaimed[recruiter] += rebate * RECRUITER_RATE / UONE;
        }

        totalUnclaimed += unclaimed;
        updatedTimestamp = timestamp;
    }

    function claimBrokerRebate() external _reentryLock_ {
        uint256 fee = brokerFees[msg.sender].itou();
        uint256 claimed = brokerClaimed[msg.sender];
        (, uint256 totalRebate) = RebateCalculator.calculateTotalRebate(fee);
        uint256 totalBrokerRebate = totalRebate * BROKER_RATE / UONE;
        require(totalBrokerRebate > claimed, 'RebateImplementation: nothing to claim');
        uint256 unclaimed = totalBrokerRebate - claimed;

        totalUnclaimed -= unclaimed;
        brokerClaimed[msg.sender] = totalBrokerRebate;

        uint256 amount = unclaimed.rescale(18, IERC20(tokenB0).decimals());
        IProtocolFeeManager(protocolFeeManager).distributeReferralFees(msg.sender, amount);

        emit ClaimRebate(msg.sender, amount);
    }

    function claimRecruiterRebate() external _reentryLock_ {
        uint256 unclaimed = recruiterUnClaimed[msg.sender];
        require(unclaimed > 0, 'RebateImplementation: nothing to claim');

        totalUnclaimed -= unclaimed;
        recruiterClaimed[msg.sender] += unclaimed;
        recruiterUnClaimed[msg.sender] = 0;

        uint256 amount = unclaimed.rescale(18, IERC20(tokenB0).decimals());
        IProtocolFeeManager(protocolFeeManager).distributeReferralFees(msg.sender, amount);

        emit ClaimRebate(msg.sender, amount);
    }

    function setTotalUnclaimed(uint256 totalUnclaimed_) external {
        require(msg.sender == updater, "RebateImplementation: only updater");
        totalUnclaimed = totalUnclaimed_;
    }

    // HELPERS
    function getBrokerRebate(address broker)
    external view returns (uint256 currentBrokerRate, uint256 totalBrokerRebate)
    {
        uint256 fee = brokerFees[broker].itou();
        (uint256 currentRate, uint256 totalRebate) = RebateCalculator.calculateTotalRebate(fee);
        currentBrokerRate = currentRate * BROKER_RATE / UONE;
        totalBrokerRebate = totalRebate * BROKER_RATE / UONE;
    }

    function getRecruiterRebate(address recruiter)
    external view returns (uint256 totalRecruiterRebate)
    {
        return recruiterClaimed[recruiter] + recruiterUnClaimed[recruiter];
    }

}

interface IProtocolFeeManager {
    function distributeReferralFees(address recepient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract RebateStorage is Admin {
    address public implementation;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, "Router: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    mapping(bytes32 => address) public brokerAddresses;

    mapping(address => bytes32) public brokerIds;

    mapping(address => BrokerInfo) public brokerInfos;

    mapping(bytes32 => address) public recruiterAddresses;

    mapping(address => bytes32) public recruiterIds;

    mapping(address => RecruiterInfo) public recruiterInfos;

    // trader => broker
    mapping(address => address) public traderReferral;

    // broker => recruiter
    mapping(address => address) public brokerReferral;

    // for recruiter approve
    address public approver;

    address public updater;

    mapping(address => int256) public brokerFees;

    mapping(address => int256) public recruiterFees;

    mapping(address => uint256) public brokerClaimed;

    mapping(address => uint256) public recruiterClaimed;

    uint256 public updatedTimestamp;

    uint256 public totalUnclaimed;

    struct BrokerInfo {
        string code;
        bytes32 id;
        address referral;
    }

    struct RecruiterInfo {
        string code;
        bytes32 id;
    }

    mapping (address => uint256) public recruiterUnClaimed;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

abstract contract Admin {

    error OnlyAdmin();

    event NewAdmin(address newAdmin);

    address public admin;

    modifier _onlyAdmin_() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    /**
     * @notice Set a new admin for the contract.
     * @dev This function allows the current admin to assign a new admin address without performing any explicit verification.
     *      It's the current admin's responsibility to ensure that the 'newAdmin' address is correct and secure.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "./Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    error UtoIOverflow(uint256);
    error IToUOverflow(int256);
    error AbsOverflow(int256);

    uint256 constant IMAX = 2**255 - 1;
    int256  constant IMIN = -2**255;

    function utoi(uint256 a) internal pure returns (int256) {
        if (a > IMAX) {
            revert UtoIOverflow(a);
        }
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            revert IToUOverflow(a);
        }
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        if (a == IMIN) {
            revert AbsOverflow(a);
        }
        return a >= 0 ? a : -a;
    }

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a + uint256(b);
        } else {
            return a - uint256(-b);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // @notice Rescale a uint256 value from a base of 10^decimals1 to 10^decimals2
    function rescale(uint256 value, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? value : value * 10**decimals2 / 10**decimals1;
    }

    // @notice Rescale value with rounding down
    function rescaleDown(uint256 value, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return rescale(value, decimals1, decimals2);
    }

    // @notice Rescale value with rounding up
    function rescaleUp(uint256 value, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        uint256 rescaled = rescale(value, decimals1, decimals2);
        if (rescale(rescaled, decimals2, decimals1) != value) {
            rescaled += 1;
        }
        return rescaled;
    }

    function rescale(int256 value, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        return decimals1 == decimals2 ? value : value * int256(10**decimals2) / int256(10**decimals1);
    }

    function rescaleDown(int256 value, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        int256 rescaled = rescale(value, decimals1, decimals2);
        if (value < 0 && rescale(rescaled, decimals2, decimals1) != value) {
            rescaled -= 1;
        }
        return rescaled;
    }

    function rescaleUp(int256 value, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        int256 rescaled = rescale(value, decimals1, decimals2);
        if (value > 0 && rescale(rescaled, decimals2, decimals1) != value) {
            rescaled += 1;
        }
        return rescaled;
    }

    // @notice Calculate a + b with overflow allowed
    function addUnchecked(int256 a, int256 b) internal pure returns (int256 c) {
        unchecked { c = a + b; }
    }

    // @notice Calculate a - b with overflow allowed
    function minusUnchecked(int256 a, int256 b) internal pure returns (int256 c) {
        unchecked { c = a - b; }
    }

}