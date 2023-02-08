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

pragma solidity =0.8.4;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ICreditManager } from "../credit/interfaces/ICreditManager.sol";
import { IDepositor } from "../depositors/interfaces/IDepositor.sol";

contract CreditRewardTracker {
    using Address for address;

    address public owner;
    address public pendingOwner;
    uint256 public lastInteractedAt;
    uint256 public duration;

    address[] public managers;
    address[] public depositors;

    mapping(address => bool) private governors;

    error NotAuthorized();
    event NewGovernor(address indexed _sender, address _governor);
    event RemoveGovernor(address indexed _sender, address _governor);
    event Succeed(address _sender, address _target, uint256 _claimed, uint256 _timestamp);
    event Failed(address _sender, address _target, uint256 _timestamp);

    modifier onlyOwner() {
        if (owner != msg.sender) revert NotAuthorized();
        _;
    }

    modifier onlyGovernors() {
        if (!isGovernor(msg.sender)) revert NotAuthorized();
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "CreditRewardTracker: _distributer cannot be 0x0");

        owner = _owner;

        governors[_owner] = true;
        duration = 10 minutes;
    }

    /// @notice Set pending owner
    /// @param _owner owner address
    function setPendingOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "CreditRewardTracker: _owner cannot be 0x0");
        pendingOwner = _owner;
    }

    /// @notice Accept owner
    function acceptOwner() external onlyOwner {
        owner = pendingOwner;

        pendingOwner = address(0);
    }

    /// @notice Add new governor
    /// @param _newGovernor governor address
    function addGovernor(address _newGovernor) public onlyOwner {
        require(_newGovernor != address(0), "CreditRewardTracker: _newGovernor cannot be 0x0");
        require(!isGovernor(_newGovernor), "CreditRewardTracker: _newGovernor is already governor");

        governors[_newGovernor] = true;

        emit NewGovernor(msg.sender, _newGovernor);
    }

    function addGovernors(address[] calldata _newGovernors) external onlyOwner {
        for (uint256 i = 0; i < _newGovernors.length; i++) {
            addGovernor(_newGovernors[i]);
        }
    }

    /// @notice Remove governor
    /// @param _governor governor address
    function removeGovernor(address _governor) external onlyOwner {
        require(_governor != address(0), "CreditRewardTracker: _governor cannot be 0x0");
        require(isGovernor(_governor), "CreditRewardTracker: _governor is not a governor");

        governors[_governor] = false;

        emit RemoveGovernor(msg.sender, _governor);
    }

    function isGovernor(address _governor) public view returns (bool) {
        return governors[_governor];
    }

    function addManager(address _manager) public onlyOwner {
        require(_manager != address(0), "CreditRewardTracker: _manager cannot be 0x0");

        for (uint256 i = 0; i < managers.length; i++) {
            require(managers[i] != _manager, "CreditRewardTracker: Duplicate manager");
        }

        managers.push(_manager);
    }

    function removeManager(uint256 _index) public onlyOwner {
        require(_index < managers.length, "CreditRewardTracker: Index out of range");

        managers[_index] = managers[managers.length - 1];

        managers.pop();
    }

    function addDepositor(address _depositor) public onlyOwner {
        require(_depositor != address(0), "CreditRewardTracker: _depositor cannot be 0x0");

        for (uint256 i = 0; i < depositors.length; i++) {
            require(depositors[i] != _depositor, "CreditRewardTracker: Duplicate depositor");
        }

        depositors.push(_depositor);
    }

    function removeDepositor(uint256 _index) public onlyOwner {
        require(_index < depositors.length, "CreditRewardTracker: Index out of range");

        depositors[_index] = depositors[depositors.length - 1];

        depositors.pop();
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function execute() external onlyGovernors {
        require(block.timestamp - lastInteractedAt >= duration, "CreditRewardTracker: Incorrect duration");

        lastInteractedAt = block.timestamp;

        for (uint256 i = 0; i < depositors.length; i++) {
            try IDepositor(depositors[i]).harvest() returns (uint256 claimed) {
                emit Succeed(msg.sender, depositors[i], claimed, lastInteractedAt);
            } catch {
                emit Failed(msg.sender, managers[i], lastInteractedAt);
            }
        }

        for (uint256 i = 0; i < managers.length; i++) {
            try ICreditManager(managers[i]).harvest() returns (uint256 claimed) {
                emit Succeed(msg.sender, managers[i], claimed, lastInteractedAt);
            } catch {
                emit Failed(msg.sender, managers[i], lastInteractedAt);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditManager {
    function vault() external view returns (address);

    function borrow(address _recipient, uint256 _borrowedAmount) external;

    function repay(address _recipient, uint256 _borrowedAmount) external;

    function claim(address _recipient) external returns (uint256 claimed);

    function balanceOf(address _recipient) external view returns (uint256);

    function harvest() external returns (uint256);

    event Borrow(address _recipient, uint256 _borrowedAmount, uint256 _totalShares, uint256 _shares);
    event Repay(address _recipient, uint256 _borrowedAmount, uint256 _totalShares, uint256 _shares);
    event Harvest(uint256 _claimed, uint256 _accRewardPerShare);
    event Claim(address _recipient, uint256 _claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IDepositor {
    function mint(address _token, uint256 _amountIn) external payable returns (address, uint256);

    function withdraw(
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut
    ) external payable returns (uint256);

    function harvest() external returns (uint256);

    event Mint(address _token, uint256 _amountIn, uint256 _amountOut);
    event Withdraw(address _token, uint256 _amountIn, uint256 _amountOut);
    event Harvest(address _rewardToken, uint256 _rewards, uint256 _fees);
}