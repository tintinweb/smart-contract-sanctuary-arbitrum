// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Address } from "contracts/utils/Address.sol";
import { CoreOwnable } from "contracts/base/dependencies/CoreOwnable.sol";
import { IPriceOracle } from "contracts/interfaces/IPriceOracle.sol";
import { IUptimeOracle } from "contracts/interfaces/IUptimeOracle.sol";

/**
    @title Aggregate Chained Oracle
    @author defidotmoney
    @notice Returns the average price from one or more sequences of oracle calls,
            with price caching and an optional `UptimeOracle` call.
 */
contract AggregateChainedOracle is IPriceOracle, CoreOwnable {
    using Address for address;

    struct OracleCall {
        // Address of the oracle to call.
        address target;
        // Decimal precision of response. Cannot be greater than 18.
        uint8 decimals;
        // If `true`, the new price is calculated from the answer as `result * answer / 1e18`
        // If `false, the calculation is `result * 1e18 / answer`
        bool isMultiplied;
        // Calldata input passsed to `target` to get the oracle response in a staticcall context.
        bytes inputView;
        // Calldata input passsed to `target` to get the oracle response in a write context.
        // In some cases this might be the same value as `inputView`.
        bytes inputWrite;
    }

    OracleCall[][] private oracleCallPaths;

    IUptimeOracle public uptimeOracle;
    uint256 public storedPrice;

    constructor(address _coreOwner, IUptimeOracle _uptimeOracle) CoreOwnable(_coreOwner) {
        uptimeOracle = _uptimeOracle;
    }

    // --- IPriceOracle required interface ---

    /**
        @notice The current oracle price, normalized to 1e18 precision
        @dev Read-only version used within view methods
     */
    function price() external view returns (uint256) {
        uint256 result = _maybeGetStoredPrice();
        if (result != 0) return result;
        uint256 length = oracleCallPaths.length;
        for (uint256 i = 0; i < length; i++) {
            result += _fetchCallPathResultView(oracleCallPaths[i]);
        }
        return result / length;
    }

    /**
        @notice The current oracle price, normalized to 1e18 precision
        @dev Write version that also stores the price. The stored price is
             returned later if the uptime oracle reports a downtime.
     */
    function price_w() external returns (uint256) {
        uint256 result = _maybeGetStoredPrice();
        if (result != 0) return result;

        uint256 length = oracleCallPaths.length;
        for (uint256 i = 0; i < length; i++) {
            result += _fetchCallPathResultWrite(oracleCallPaths[i]);
        }
        result = result / length;
        storedPrice = result;

        return result;
    }

    // --- external view functions ---

    /**
        @notice Get the current number of oracle call paths
        @return count Number of oracle call paths
     */
    function getCallPathCount() external view returns (uint256 count) {
        return oracleCallPaths.length;
    }

    /**
        @notice Get an array of `OracleCall` tuples that collectively
                form one oracle call path
        @param idx Index of the oracle call path
        @return path Dynamic array of `OracleCall` tuples
     */
    function getCallPath(uint256 idx) external view returns (OracleCall[] memory path) {
        return oracleCallPaths[idx];
    }

    /**
        @notice Fetches the current view response for a single oracle call path
        @param idx Index of the oracle call path to query
        @return response Oracle call path view response
     */
    function getCallPathResult(uint256 idx) external view returns (uint256 response) {
        return _fetchCallPathResultView(oracleCallPaths[idx]);
    }

    // --- unguarded external functions ---

    /**
        @notice Fetches the current write response for a single oracle call path
        @param idx Index of the oracle call path to query
        @return response Oracle call path write response
     */
    function getCallPathResultWrite(uint256 idx) external returns (uint256 response) {
        return _fetchCallPathResultWrite(oracleCallPaths[idx]);
    }

    // --- owner-only guarded external functions ---

    function setUptimeOracle(IUptimeOracle _uptimeOracle) external onlyOwner {
        if (address(_uptimeOracle) != address(0)) {
            require(_uptimeOracle.getUptimeStatus(), "DFM: Bad uptime answer");
        }
        uptimeOracle = _uptimeOracle;
    }

    /**
        @notice Add a new sequence of 1 or more oracle calls
        @dev When querying a price from this contract, each "oracle call path"
             is executed independently. The final returned price is an average
             of the values returned from each path.
        @param path Dynamic array of one or more `OraclePath` structs. The
                    comments in the struct definition explain the layout.
     */
    function addCallPath(OracleCall[] calldata path) external onlyOwner {
        uint256 length = path.length;
        require(length > 0, "DFM: Cannot set empty path");

        oracleCallPaths.push();
        OracleCall[] storage storagePath = oracleCallPaths[oracleCallPaths.length - 1];
        for (uint256 i = 0; i < length; i++) {
            require(path[i].decimals < 19, "DFM: Maximum 18 decimals");
            storagePath.push(path[i]);
        }

        uint256 resultView = _fetchCallPathResultView(path);
        uint256 resultWrite = _fetchCallPathResultWrite(path);
        require(resultView == resultWrite, "DFM: view != write");
    }

    /**
        @notice Remove an oracle call path
        @dev Once a path has been set, the contract cannot ever return to a
             state where there is no set path. If you wish to remove the last
             path you should first add a new path that will replace it.
        @param idx Index of the oracle call path to remove
     */
    function removeCallPath(uint256 idx) external onlyOwner {
        uint256 length = oracleCallPaths.length;
        require(idx < length, "DFM: Invalid path index");
        require(length > 1, "DFM: Cannot remove only path");
        if (idx < length - 1) {
            oracleCallPaths[idx] = oracleCallPaths[length - 1];
        }
        oracleCallPaths.pop();
    }

    // --- internal functions ---

    function _maybeGetStoredPrice() internal view returns (uint256 response) {
        IUptimeOracle oracle = uptimeOracle;
        if (address(oracle) != address(0) && !oracle.getUptimeStatus()) {
            // If uptime oracle is set and currently reports downtime,
            // return the last stored price
            return storedPrice;
        }
        // Otherwise return 0 to indicate that a new price should be queried
        return 0;
    }

    function _fetchCallPathResultView(OracleCall[] memory path) internal view returns (uint256 result) {
        result = 1e18;
        uint256 length = path.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 answer = uint256(bytes32(path[i].target.functionStaticCall(path[i].inputView)));
            require(answer != 0, "DFM: Oracle returned 0");
            answer *= 10 ** (18 - path[i].decimals);
            if (path[i].isMultiplied) result = (result * answer) / 1e18;
            else result = (result * 1e18) / answer;
        }
        return result;
    }

    function _fetchCallPathResultWrite(OracleCall[] memory path) internal returns (uint256 result) {
        result = 1e18;
        uint256 length = path.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 answer = uint256(bytes32(path[i].target.functionCall(path[i].inputWrite)));
            require(answer != 0, "DFM: Oracle returned 0");
            answer *= 10 ** (18 - path[i].decimals);
            if (path[i].isMultiplied) result = (result * answer) / 1e18;
            else result = (result * 1e18) / answer;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

pragma solidity ^0.8.0;

import { IProtocolCore } from "contracts/interfaces/IProtocolCore.sol";

/**
    @title Core Ownable
    @author Prisma Finance (with edits by defidotmoney)
    @notice Contracts inheriting `CoreOwnable` have the same owner as `ProtocolCore`.
            The ownership cannot be independently modified or renounced.
 */
abstract contract CoreOwnable {
    IProtocolCore public immutable CORE_OWNER;

    constructor(address _core) {
        CORE_OWNER = IProtocolCore(_core);
    }

    modifier onlyOwner() {
        require(msg.sender == address(CORE_OWNER.owner()), "DFM: Only owner");
        _;
    }

    modifier onlyBridgeRelay() {
        require(msg.sender == bridgeRelay(), "DFM: Only bridge relay");
        _;
    }

    /**
        @dev Access control modifier for toggle actions where the only the protocol
             owner is allowed to enabled, but both the owner and guardian can disable.
     */
    modifier ownerOrGuardianToggle(bool isEnabled) {
        if (msg.sender != owner()) {
            if (msg.sender == guardian()) {
                require(!isEnabled, "DFM: Guardian can only disable");
            } else {
                revert("DFM Not owner or guardian");
            }
        }
        _;
    }

    function owner() public view returns (address) {
        return address(CORE_OWNER.owner());
    }

    function bridgeRelay() internal view returns (address) {
        return CORE_OWNER.bridgeRelay();
    }

    function feeReceiver() internal view returns (address) {
        return CORE_OWNER.feeReceiver();
    }

    function guardian() internal view returns (address) {
        return CORE_OWNER.guardian();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProtocolCore {
    function owner() external view returns (address);

    function START_TIME() external view returns (uint256);

    function getAddress(bytes32 identifier) external view returns (address);

    function bridgeRelay() external view returns (address);

    function feeReceiver() external view returns (address);

    function guardian() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    @dev Price oracles must implement all functions outlined within this interface
 */
interface IPriceOracle {
    /**
        @notice Returns the current oracle price, normalized to 1e18 precision
        @dev Called by all state-changing market / amm operations with the exception
             of `MainController.close_loan`
     */
    function price_w() external returns (uint256);

    /**
        @notice Returns the current oracle price, normalized to 1e18 precision
        @dev Read-only version used within view methods. Should always return
             the same value as `price_w`
     */
    function price() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    @dev Uptime oracles (related to L2 sequencer uptime) must implement all
         functions outlined within this interface
 */
interface IUptimeOracle {
    function getUptimeStatus() external view returns (bool);
}