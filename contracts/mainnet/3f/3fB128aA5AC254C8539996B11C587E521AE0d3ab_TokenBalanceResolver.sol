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

pragma solidity ^0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

// Import ERC20 interface
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract StringDecoder { 

    function _bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes32 _temp;
        uint256 count;
        for (uint256 i; i < 32; i++) {
            _temp = _bytes32[i];
            if (_temp != bytes32(0)) {
                count += 1;
            }
        }
        bytes memory bytesArray = new bytes(count);
        for (uint256 i; i < count; i++) {
            bytesArray[i] = (_bytes32[i]);
        }
        return (string(bytesArray));
    }

    function _decodeStringNormal(bytes memory data) public pure returns(string memory) {
        return abi.decode(data, (string));
    }

    function _decodeStringLib(bytes memory data) public pure returns(string memory) {
        return _bytes32ToString(abi.decode(data, (bytes32)));
    }
}

contract TokenBalanceResolver is StringDecoder {
    struct TokenBalance {
        uint256 balance;
        bool success;
    }

    struct UserTokenBalances {
        address user;
        TokenBalance[] balances;
    }

    struct TokenInfo {
        bool isToken;
        string name;
        string symbol;
        uint256 decimals;
    }

    address private constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalances(address user, address[] memory tokenAddresses) public returns (UserTokenBalances memory) {
        return UserTokenBalances(user, _getBalances(user, tokenAddresses));
    }

    function getBalancesForMultipleUsers(address[] memory users, address[] memory tokenAddresses) public returns (UserTokenBalances[] memory) {
        UserTokenBalances[] memory allUserBalances = new UserTokenBalances[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            allUserBalances[i].user = users[i];
            allUserBalances[i].balances = _getBalances(users[i], tokenAddresses);
        }

        return allUserBalances;
    }

    function getTokenInfo(address token) public returns (TokenInfo memory) {
        if (Address.isContract(token)) {
            (bool successName, bytes memory nameData) = token.call(abi.encodeWithSignature("name()"));
            (bool successSymbol, bytes memory symbolData) = token.call(abi.encodeWithSignature("symbol()"));
            (bool successDecimals, bytes memory decimalsData) = token.call(abi.encodeWithSignature("decimals()"));

            if (successName && successSymbol && successDecimals) {
                (bool nameDecode, string memory name)= decodeString(nameData);
                (bool symbolDecode, string memory symbol) = decodeString(symbolData);
                uint256 decimals = abi.decode(decimalsData, (uint256));

                return TokenInfo(true && nameDecode && symbolDecode, name, symbol, decimals);
            }
        }
        return TokenInfo(false, "", "", 0);
    }

    function getMultipleTokenInfo(address[] memory tokens) public returns (TokenInfo[] memory) {
        TokenInfo[] memory tokenInfos = new TokenInfo[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            tokenInfos[i] = getTokenInfo(tokens[i]);
        }

        return tokenInfos;
    }

    function _getBalances(address user, address[] memory tokenAddresses) private returns (TokenBalance[] memory) {
        TokenBalance[] memory balances = new TokenBalance[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == ETHER_ADDRESS) {
                balances[i].balance = user.balance;
                balances[i].success = true;
            } else {
                if(Address.isContract(tokenAddresses[i])) {
                    bytes memory callData = abi.encodeWithSelector(IERC20(tokenAddresses[i]).balanceOf.selector, user);
                    (bool success, bytes memory result) = tokenAddresses[i].call(callData);

                    if (success) {
                        balances[i].balance = abi.decode(result, (uint256));
                        balances[i].success = true;
                    }
                }
            }
        }

        return balances;
    }

    function decodeString(bytes memory data) public returns(bool status, string memory) {
        (bool success, bytes memory stringData) = address(this).call(abi.encodeWithSelector(StringDecoder._decodeStringNormal.selector, data));

        if (success) {
            return (true, abi.decode(stringData, (string)));
        } else {
            (success, stringData) = address(this).call(abi.encodeWithSelector(StringDecoder._decodeStringLib.selector, data));
            if (success) {
                return (true, abi.decode(stringData, (string)));
            } else {
                return (false, "");
            }
        }
    }
}